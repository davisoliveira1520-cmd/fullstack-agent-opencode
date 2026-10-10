"""Adaptadores dos 3 motores de execução do Jarvis.

Cada motor sabe se detectar (CLI instalada ou credencial de API válida),
executar no modo selecionado e reportar falhas. Apenas stdlib.
"""

from __future__ import annotations

import asyncio
import json
import os
import shutil
import subprocess
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Dict, List, Optional

from .config import API_CLAUDE, API_OPENAI, EngineSettings


class EngineError(Exception):
    def __init__(self, engine: str, message: str, cause: Optional[BaseException] = None) -> None:
        super().__init__(f"[{engine}] {message}")
        self.engine = engine
        self.cause = cause


class Engine:
    """Base comum: detecção (CLI/API), execução e contagem de falhas."""

    name: str = "?"
    cli_name: str = "?"
    api_env_key: str = ""
    api_url: Optional[str] = None
    supports_api: bool = True

    def __init__(
        self,
        settings: EngineSettings,
        cli_path: Optional[str] = None,
        api_key: Optional[str] = None,
        model: Optional[str] = None,
    ) -> None:
        self.settings = settings
        self.cli_path = cli_path
        self.api_key = api_key
        self.model = model
        self.mode: Optional[str] = None
        self.available = False
        self.executable: Optional[str] = None
        self.last_check_reason = ""
        self.failures = 0
        self.isolated = False
        self.isolated_until = 0.0

    def bundled_candidates(self, root: Path) -> List[Path]:
        return []

    def _find_cli(self, root: Path) -> Optional[str]:
        if self.cli_path and Path(self.cli_path).is_file():
            return self.cli_path
        for cand in self.bundled_candidates(root):
            if cand.is_file():
                return str(cand)
        return shutil.which(self.cli_name)

    def check(self, root: Optional[Path] = None) -> bool:
        root = Path(root) if root else Path(__file__).resolve().parents[2]
        self.executable = self._find_cli(root)
        if self.settings.use_cli_first and self.executable:
            self.mode, self.available = "cli", True
            self.last_check_reason = f"CLI: {self.executable}"
            return True
        if self.supports_api and self.api_key:
            self.mode, self.available = "api", True
            self.last_check_reason = f"API via {self.api_env_key}"
            return True
        self.mode, self.available = None, False
        if self.executable:
            self.last_check_reason = "CLI presente, mas use_cli_first=False e sem credencial"
        elif self.supports_api and self.api_key:
            self.last_check_reason = "use_cli_first=False e sem CLI"
        else:
            self.last_check_reason = "sem CLI no PATH e sem chave de API"
        return False

    def is_isolated_now(self) -> bool:
        return self.isolated and time.monotonic() < self.isolated_until

    async def run(self, prompt: str) -> str:
        if self.is_isolated_now():
            raise EngineError(self.name, "motor isolado (cooldown ativo)")
        if self.mode == "cli":
            return await self._run_cli(prompt)
        if self.mode == "api":
            return await self._call_api(prompt)
        raise EngineError(self.name, "motor sem modo ativo; rode check()")

    def build_cli_args(self, prompt: str) -> List[str]:
        raise NotImplementedError

    async def _run_cli(self, prompt: str) -> str:
        if not self.executable:
            raise EngineError(self.name, "CLI não encontrada")
        args = [self.executable] + self.build_cli_args(prompt)
        kwargs: dict = {}
        if os.name == "nt":
            kwargs["creationflags"] = subprocess.CREATE_NO_WINDOW
        proc = await asyncio.create_subprocess_exec(
            *args,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            **kwargs,
        )
        try:
            out, err = await asyncio.wait_for(proc.communicate(), self.settings.timeout_cli)
        except asyncio.TimeoutError:
            proc.kill()
            raise EngineError(self.name, f"timeout de {self.settings.timeout_cli}s na CLI")
        if proc.returncode != 0:
            msg = (err or out).decode("utf-8", errors="replace").strip()[-400:]
            raise EngineError(self.name, f"CLI saiu com código {proc.returncode}: {msg}")
        text = out.decode("utf-8", errors="replace").strip()
        if not text:
            raise EngineError(self.name, "CLI respondeu vazio")
        return text

    def api_auth_headers(self) -> Dict[str, str]:
        raise NotImplementedError

    def build_api_payload(self, prompt: str) -> dict:
        raise NotImplementedError

    async def _call_api(self, prompt: str) -> str:
        payload = self.build_api_payload(prompt)
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, self._api_sync, payload)

    def _api_sync(self, payload: dict) -> str:
        headers = {"content-type": "application/json", **self.api_auth_headers()}
        req = urllib.request.Request(
            self.api_url,
            data=json.dumps(payload).encode("utf-8"),
            headers=headers,
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=self.settings.timeout_api) as resp:
                body = json.loads(resp.read().decode("utf-8", errors="replace"))
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")[:300]
            raise EngineError(self.name, f"API HTTP {exc.code}: {detail}", cause=exc)
        except urllib.error.URLError as exc:
            raise EngineError(self.name, f"API inacessível: {exc.reason}", cause=exc)
        return self.extract_api_text(body)

    def extract_api_text(self, body: dict) -> str:
        raise NotImplementedError


class OpenCodeEngine(Engine):
    """OpenCode — nativo do Jarvis (binário embutido em bin/) e orquestrador."""

    name = "opencode"
    cli_name = "opencode"
    supports_api = False

    def bundled_candidates(self, root: Path) -> List[Path]:
        exe = "opencode.exe" if os.name == "nt" else "opencode"
        return [root / "bin" / exe]

    def build_cli_args(self, prompt: str) -> List[str]:
        return ["run", prompt]


class ClaudeCodeEngine(Engine):
    """Claude Code — CLI local (npm) ou API Anthropic."""

    name = "claude"
    cli_name = "claude"
    api_env_key = "ANTHROPIC_API_KEY"
    api_url = API_CLAUDE

    def build_cli_args(self, prompt: str) -> List[str]:
        return ["-p", prompt]

    def api_auth_headers(self) -> Dict[str, str]:
        return {"x-api-key": self.api_key or "", "anthropic-version": "2023-06-01"}

    def build_api_payload(self, prompt: str) -> dict:
        return {
            "model": self.model,
            "max_tokens": 8192,
            "messages": [{"role": "user", "content": prompt}],
        }

    def extract_api_text(self, body: dict) -> str:
        parts = [block.get("text", "") for block in body.get("content", [])]
        return "\n".join(parts).strip()


class CodexEngine(Engine):
    """Codex — CLI local (npm) ou API OpenAI (Responses)."""

    name = "codex"
    cli_name = "codex"
    api_env_key = "OPENAI_API_KEY"
    api_url = API_OPENAI

    def build_cli_args(self, prompt: str) -> List[str]:
        return ["exec", "--skip-git-repo-check", prompt]

    def api_auth_headers(self) -> Dict[str, str]:
        return {"authorization": f"Bearer {self.api_key or ''}"}

    def build_api_payload(self, prompt: str) -> dict:
        return {"model": self.model, "input": prompt}

    def extract_api_text(self, body: dict) -> str:
        text = ""
        for item in body.get("output", []):
            if item.get("type") == "message":
                for c in item.get("content", []):
                    if c.get("type") == "output_text":
                        text += c.get("text", "")
        return text.strip()