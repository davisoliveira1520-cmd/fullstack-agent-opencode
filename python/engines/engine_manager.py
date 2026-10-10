"""Engine Manager: conexão inteligente e colaboração entre os motores.

Cenários:
- 1 motor            -> solo autônomo;
- 2 motores          -> peer review (rascunho + revisão);
- 3 motores          -> pipeline (propostas paralelas + síntese orquestrada);
- falha em qualquer etapa -> isolamento temporário + fallback para os motores restantes.
"""

from __future__ import annotations

import asyncio
import logging
import os
import re
import time
import uuid
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional

from .config import EngineSettings
from .engines import (
    ClaudeCodeEngine,
    CodexEngine,
    Engine,
    EngineError,
    OpenCodeEngine,
)

log = logging.getLogger("jarvis.engines")


def _score(text: str) -> int:
    """Heurística simples de votação/rank quando a síntese está indisponível."""
    return len(text) + len(re.findall(r"```", text)) * 40 + len(set(text.split())) * 2


@dataclass
class Step:
    engine: str
    role: str
    ok: bool
    output: str = ""
    error: str = ""

    def as_dict(self) -> dict:
        if self.ok:
            return {"engine": self.engine, "role": self.role, "ok": True, "chars": len(self.output)}
        return {"engine": self.engine, "role": self.role, "ok": False, "error": self.error}


@dataclass
class EngineResult:
    task_id: str = ""
    prompt: str = ""
    scenario: str = ""
    engines_active: List[str] = field(default_factory=list)
    engines_used: List[str] = field(default_factory=list)
    steps: List[Step] = field(default_factory=list)
    final_output: str = ""
    degraded: bool = False
    latency_ms: int = 0
    errors: List[str] = field(default_factory=list)

    def as_dict(self) -> dict:
        return {
            "task_id": self.task_id,
            "scenario": self.scenario,
            "engines_active": self.engines_active,
            "engines_used": self.engines_used,
            "degraded": self.degraded,
            "latency_ms": self.latency_ms,
            "errors": self.errors,
            "steps": [s.as_dict() for s in self.steps],
            "final_output": self.final_output,
        }

    def render(self) -> str:
        lines = [
            f"Cenário: {self.scenario}",
            f"Motores ativos: {', '.join(self.engines_active)}",
        ]
        if self.degraded:
            lines.append("ATENÇÃO: execução degradada (fallback usado).")
        for s in self.steps:
            if s.ok:
                lines.append(f"  - {s.engine} [{s.role}] OK ({len(s.output)} caracteres)")
            else:
                lines.append(f"  - {s.engine} [{s.role}] FALHOU: {s.error}")
        if self.errors:
            lines.append("Erros: " + "; ".join(self.errors))
        return "\n".join(lines)


class NoEngineAvailableError(RuntimeError):
    pass


class EngineManager:
    def __init__(
        self,
        settings: Optional[EngineSettings] = None,
        engines: Optional[List[Engine]] = None,
        repo_root: Optional[Path] = None,
    ) -> None:
        self.settings = settings or EngineSettings.from_env()
        self.repo_root = Path(repo_root) if repo_root else None
        self.engines: List[Engine] = engines if engines is not None else self._default_engines()
        self._detected_at: Optional[float] = None

    def _default_engines(self) -> List[Engine]:
        s = self.settings
        return [
            OpenCodeEngine(s, cli_path=s.cli_paths.get("opencode"), model=s.model_opencode),
            ClaudeCodeEngine(
                s,
                cli_path=s.cli_paths.get("claude"),
                api_key=os.environ.get("ANTHROPIC_API_KEY"),
                model=s.model_claude,
            ),
            CodexEngine(
                s,
                cli_path=s.cli_paths.get("codex"),
                api_key=os.environ.get("OPENAI_API_KEY"),
                model=s.model_codex,
            ),
        ]

    def engine(self, name: str) -> Engine:
        for e in self.engines:
            if e.name == name:
                return e
        raise KeyError(name)

    def detect(self) -> Dict[str, bool]:
        self.recover()
        for e in self.engines:
            e.check(self.repo_root)
        self._detected_at = time.time()
        return {e.name: e.available for e in self.engines}

    def active_engines(self) -> List[str]:
        return [e.name for e in self.engines if e.available and not e.is_isolated_now()]

    def recover(self) -> None:
        now = time.monotonic()
        for e in self.engines:
            if e.isolated and now >= e.isolated_until:
                e.isolated = False
                e.failures = 0
                log.info("motor %s saiu do cooldown e será re-testado", e.name)

    async def execute(self, prompt: str, detect: bool = True) -> EngineResult:
        if detect or self._detected_at is None:
            self.detect()
        else:
            self.recover()
        for e in self.engines:
            if not e.isolated:
                e.failures = 0
        t0 = time.perf_counter()
        active = self.active_engines()
        if not active:
            detail = "; ".join(f"{e.name}: {e.last_check_reason}" for e in self.engines)
            raise NoEngineAvailableError(f"nenhum motor disponível ({detail})")

        scenario = "solo" if len(active) == 1 else "peer" if len(active) == 2 else "pipeline"
        result = await self._run_scenario(scenario, prompt, active)
        result.task_id = uuid.uuid4().hex[:12]
        result.prompt = prompt
        result.engines_active = active
        result.latency_ms = int((time.perf_counter() - t0) * 1000)
        return result

    async def _run_scenario(self, scenario: str, prompt: str, active: List[str]) -> EngineResult:
        if scenario == "solo":
            return await self._solo(prompt, active)
        if scenario == "peer":
            return await self._peer(prompt, active)
        return await self._pipeline(prompt, active)

    def _note_failure(self, engine: Engine) -> None:
        if engine.failures >= self.settings.max_failures_before_isolate:
            engine.isolated = True
            engine.isolated_until = time.monotonic() + self.settings.recovery_seconds
            log.warning(
                "ISOLANDO motor %s por %ss (falhas atingidas)",
                engine.name,
                self.settings.recovery_seconds,
            )

    async def _guarded(self, engine: Engine, role: str, coro) -> Step:
        try:
            out = await coro
            return Step(engine=engine.name, role=role, ok=True, output=out)
        except EngineError as exc:
            engine.failures += 1
            self._note_failure(engine)
            log.warning("motor %s falhou em [%s]: %s", engine.name, role, exc)
            return Step(engine=engine.name, role=role, ok=False, error=str(exc))
        except Exception as exc:  # noqa: BLE001
            engine.failures += 1
            self._note_failure(engine)
            log.exception("motor %s quebrou em [%s]", engine.name, role)
            return Step(engine=engine.name, role=role, ok=False, error=f"{type(exc).__name__}: {exc}")

    async def _solo(self, prompt: str, active: List[str]) -> EngineResult:
        eng = self.engine(active[0])
        step = await self._guarded(eng, "solo", eng.run(prompt))
        if not step.ok:
            raise NoEngineAvailableError(f"o único motor ativo ({eng.name}) falhou: {step.error}")
        return EngineResult(scenario="solo", engines_used=[eng.name], steps=[step], final_output=step.output)

    async def _peer(self, prompt: str, active: List[str]) -> EngineResult:
        author = self.engine(active[0])
        reviewer = self.engine(active[1])
        used: List[str] = []
        degraded = False

        draft = await self._guarded(author, "draft", author.run(prompt))
        used.append(author.name)
        if not draft.ok:
            log.warning("rascunho falhou; promovendo %s a autor", reviewer.name)
            draft = await self._guarded(reviewer, "draft (fallback)", reviewer.run(prompt))
            used.append(reviewer.name)
            degraded = True
            if not draft.ok:
                return EngineResult(
                    scenario="peer (degradado)",
                    engines_used=used,
                    steps=[draft],
                    final_output="",
                    degraded=True,
                    errors=[f"nenhum motor conseguiu gerar (último: {draft.error})"],
                )

        review_prompt = (
            f"{prompt}\n\nAtue como REVISOR (peer review). Revise, otimize e corrija falhas "
            f"do rascunho abaixo e devolva o resultado final pronto.\n\n--- RASCUNHO ---\n{draft.output}"
        )
        review = await self._guarded(reviewer, "review", reviewer.run(review_prompt))
        used.append(reviewer.name)

        if review.ok:
            final_output, steps, errors = review.output, [draft, review], []
        else:
            degraded = True
            final_output, steps, errors = draft.output, [draft, review], [review.error]
        return EngineResult(
            scenario="peer",
            engines_used=used,
            steps=steps,
            final_output=final_output,
            degraded=degraded,
            errors=errors,
        )

    async def _pipeline(self, prompt: str, active: List[str]) -> EngineResult:
        orch_name = self.settings.orchestrator if self.settings.orchestrator in active else active[0]
        orch = self.engine(orch_name)
        proposers = [self.engine(n) for n in active if n != orch_name]

        coros = [
            self._guarded(
                e,
                "propose",
                e.run(
                    f"{prompt}\n\nProponha a melhor abordagem ou o melhor código possível, "
                    f"completo e pronto para uso."
                ),
            )
            for e in proposers
        ]
        proposals = await asyncio.gather(*coros)
        steps: List[Step] = list(proposals)
        good = [p for p in proposals if p.ok]

        if not good:
            return await self._degrade_solo(prompt, orch, steps)

        docs = "\n\n".join(f"=== proposta de {p.engine} ===\n{p.output}" for p in good)
        synthesis_prompt = (
            f"{prompt}\n\nVocê é o ORQUESTRADOR. Abaixo estão propostas independentes de outros "
            f"motores. Compare-as, cruze as melhores partes, corrija inconsistências e entregue "
            f"o resultado final único e perfeito.\n\n{docs}"
        )
        syn = await self._guarded(orch, "synthesize", orch.run(synthesis_prompt))
        steps.append(syn)
        if syn.ok:
            used = [orch_name] + [p.engine for p in good]
            return EngineResult(
                scenario="pipeline",
                engines_used=used,
                steps=steps,
                final_output=syn.output,
                errors=[p.error for p in proposals if not p.ok],
            )

        log.warning("síntese orquestrada falhou; usando votação heurística entre propostas")
        picked = max(good, key=lambda p: _score(p.output))
        return EngineResult(
            scenario="pipeline (fallback voto)",
            engines_used=[p.engine for p in good],
            steps=steps,
            final_output=picked.output,
            degraded=True,
            errors=[syn.error] + [p.error for p in proposals if not p.ok],
        )

    async def _degrade_solo(self, prompt: str, preferred: Engine, prior: List[Step]) -> EngineResult:
        eng: Optional[Engine] = preferred if (preferred.available and not preferred.is_isolated_now()) else None
        if eng is None:
            for e in self.engines:
                if e.available and not e.is_isolated_now():
                    eng = e
                    break
        if eng is None:
            return EngineResult(
                scenario="degraded-solo",
                steps=prior,
                final_output="",
                degraded=True,
                errors=["nenhum motor restante disponível"],
            )
        step = await self._guarded(eng, "solo (degradado)", eng.run(prompt))
        return EngineResult(
            scenario="degraded-solo",
            engines_used=[eng.name],
            steps=prior + [step],
            final_output=step.output if step.ok else "",
            degraded=True,
            errors=[] if step.ok else [step.error],
        )