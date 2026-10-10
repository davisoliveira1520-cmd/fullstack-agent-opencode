"""Testes do Engine Manager usando motores falsos (sem CLI/API reais).

Rode (a partir da raiz do repositório):
    python -m unittest discover -s python/tests -t python
"""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from engines import EngineSettings  # noqa: E402
from engines.engine_manager import EngineManager, NoEngineAvailableError  # noqa: E402
from engines.engines import Engine, EngineError  # noqa: E402


class FakeEngine(Engine):
    """Motor controlável: responde texto, falha ou some conforme o teste."""

    def __init__(self, name, available=True, respond="ok", settings=None):
        super().__init__(settings or EngineSettings())
        self.name = name
        self._available = available
        self._respond = respond
        self.calls = []

    def check(self, root=None):
        self.available = self._available
        self.mode = "cli" if self._available else None
        self.executable = f"fake-{self.name}" if self._available else None
        self.last_check_reason = "fake" if self._available else "fake indisponível"
        return self._available

    async def run(self, prompt):
        if not self._available:
            raise EngineError(self.name, "fake indisponível")
        if isinstance(self._respond, BaseException):
            raise self._respond
        if callable(self._respond):
            return self._respond(prompt)
        self.calls.append(prompt)
        return f"{self.name}: {self._respond}"


def make_manager(*engines, settings=None):
    return EngineManager(settings=settings or EngineSettings(), engines=list(engines), repo_root=Path("."))


class DetectTests(unittest.IsolatedAsyncioTestCase):
    async def test_active_count_matches_availability(self):
        engines = [
            FakeEngine("opencode", available=True),
            FakeEngine("claude", available=True),
            FakeEngine("codex", available=False),
        ]
        mgr = make_manager(*engines)
        status = mgr.detect()
        self.assertEqual(status, {"opencode": True, "claude": True, "codex": False})
        self.assertEqual(mgr.active_engines(), ["opencode", "claude"])

    async def test_no_engines_raises(self):
        mgr = make_manager(FakeEngine("opencode", available=False))
        with self.assertRaises(NoEngineAvailableError):
            await mgr.execute("teste")

    async def test_solo_failure_raises(self):
        mgr = make_manager(FakeEngine("codex", available=False))
        with self.assertRaises(NoEngineAvailableError):
            await mgr.execute("tarefa")


class SoloTests(unittest.IsolatedAsyncioTestCase):
    async def test_solo_single_engine(self):
        mgr = make_manager(FakeEngine("codex", respond="resposta única"))
        result = await mgr.execute("tarefa")
        self.assertEqual(result.scenario, "solo")
        self.assertEqual(result.final_output, "codex: resposta única")
        self.assertEqual(result.engines_used, ["codex"])


class PeerTests(unittest.IsolatedAsyncioTestCase):
    async def test_draft_then_review(self):
        author = FakeEngine("opencode", respond="rascunho do autor")
        reviewer = FakeEngine("claude", respond="versão revisada")
        result = await make_manager(author, reviewer).execute("criar app de tarefas")
        self.assertEqual(result.scenario, "peer")
        self.assertFalse(result.degraded)
        self.assertEqual(result.final_output, "claude: versão revisada")
        roles = {s.role for s in result.steps}
        self.assertEqual(roles, {"draft", "review"})

    async def test_review_fails_falls_back_to_draft(self):
        author = FakeEngine("opencode", respond="rascunho ok")
        reviewer = FakeEngine("claude", respond=EngineError("claude", "revisor caiu"))
        result = await make_manager(author, reviewer).execute("criar app de tarefas")
        self.assertEqual(result.scenario, "peer")
        self.assertTrue(result.degraded)
        self.assertEqual(result.final_output, "opencode: rascunho ok")
        self.assertTrue(any(not s.ok and s.role == "review" for s in result.steps))

    async def test_draft_fails_promotes_reviewer(self):
        author = FakeEngine("opencode", respond=EngineError("opencode", "autor caiu"))
        reviewer = FakeEngine("claude", respond="rascunho pelo revisor")
        result = await make_manager(author, reviewer).execute("criar app de tarefas")
        self.assertTrue(result.degraded)
        self.assertEqual(result.final_output, "claude: rascunho pelo revisor")
        self.assertTrue(any(s.role == "draft (fallback)" and s.ok for s in result.steps))


class PipelineTests(unittest.IsolatedAsyncioTestCase):
    async def test_three_engines_synthesis(self):
        orch = FakeEngine("opencode", respond="SÍNTESE final do orquestrador")
        claude = FakeEngine("claude", respond="proposta do claude")
        codex = FakeEngine("codex", respond="proposta do codex")
        result = await make_manager(orch, claude, codex).execute("criar um site")
        self.assertEqual(result.scenario, "pipeline")
        self.assertFalse(result.degraded)
        self.assertIn("SÍNTESE", result.final_output)
        roles = {s.role for s in result.steps}
        self.assertEqual(roles, {"propose", "synthesize"})

    async def test_synthesis_fails_uses_vote(self):
        short = "código curto."
        long_text = (
            "resposta final muito mais completa e detalhada, cobrindo todos os pontos da questão, "
            "com exemplos e explicações extensas para garantir a melhor entrega possível ao usuário "
            "final do sistema completo."
        )
        orch = FakeEngine("opencode", respond=EngineError("opencode", "orquestrador caiu"))
        claude = FakeEngine("claude", respond=short)
        codex = FakeEngine("codex", respond=long_text)
        settings = EngineSettings(max_failures_before_isolate=10)
        result = await make_manager(orch, claude, codex, settings=settings).execute("criar um site")
        self.assertTrue(result.degraded)
        self.assertIn("fallback voto", result.scenario)
        self.assertEqual(result.final_output, f"codex: {long_text}")

    async def test_proposer_fails_is_isolated(self):
        settings = EngineSettings(max_failures_before_isolate=1, recovery_seconds=3600)
        orch = FakeEngine("opencode", respond="síntese boa", settings=settings)
        claude = FakeEngine("claude", respond=EngineError("claude", "claude caiu"), settings=settings)
        codex = FakeEngine("codex", respond="proposta boa", settings=settings)
        mgr = make_manager(orch, claude, codex, settings=settings)
        result = await mgr.execute("criar um site")
        self.assertEqual(result.scenario, "pipeline")
        self.assertTrue(any(not s.ok and s.engine == "claude" and s.role == "propose" for s in result.steps))
        self.assertTrue(claude.isolated)
        self.assertNotIn("claude", mgr.active_engines())

    async def test_pipeline_no_proposals_degrades_to_solo(self):
        settings = EngineSettings(max_failures_before_isolate=10)
        orch = FakeEngine("opencode", respond="solo de emergência", settings=settings)
        claude = FakeEngine("claude", respond=EngineError("claude", "caiu"), settings=settings)
        codex = FakeEngine("codex", respond=EngineError("codex", "caiu"), settings=settings)
        result = await make_manager(orch, claude, codex, settings=settings).execute("criar um site")
        self.assertEqual(result.scenario, "degraded-solo")
        self.assertTrue(result.degraded)
        self.assertEqual(result.final_output, "opencode: solo de emergência")


class FallbackTests(unittest.IsolatedAsyncioTestCase):
    async def test_recovery_re_enables_isolated_engine(self):
        settings = EngineSettings(max_failures_before_isolate=1, recovery_seconds=0)
        orch = FakeEngine("opencode", respond="síntese", settings=settings)
        claude = FakeEngine("claude", respond=EngineError("claude", "caiu"), settings=settings)
        codex = FakeEngine("codex", respond="proposta", settings=settings)
        mgr = make_manager(orch, claude, codex, settings=settings)
        await mgr.execute("criar um site")
        self.assertTrue(claude.isolated)
        mgr.detect()
        self.assertIn("claude", mgr.active_engines())


if __name__ == "__main__":
    unittest.main()