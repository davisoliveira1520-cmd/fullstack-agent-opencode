"""Configuração do sistema de motores do Jarvis.

Carrega chaves e CLIs de forma dinâmica: variáveis de ambiente padrão,
um arquivo .env opcional e um config.json opcional. Apenas stdlib.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Optional, Union

PathLike = Union[str, Path]

API_CLAUDE = "https://api.anthropic.com/v1/messages"
API_OPENAI = "https://api.openai.com/v1/responses"


def load_dotenv(path: PathLike) -> Dict[str, str]:
    """Carrega um .env simples (KEY=VALUE) sem sobrescrever o ambiente."""
    values: Dict[str, str] = {}
    p = Path(path)
    if not p.is_file():
        return values
    for raw in p.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        val = val.strip().strip('"').strip("'").replace("\\n", "\n")
        key = key.strip()
        os.environ.setdefault(key, val)
        values[key] = val
    return values


def _int_env(key: str, default: int) -> int:
    try:
        return int(os.environ.get(key, default))
    except ValueError:
        return default


@dataclass
class EngineSettings:
    """Todas as opções do gerenciador (defaults sobrescritos por env/config)."""

    timeout_cli: int = 600
    timeout_api: int = 120
    max_failures_before_isolate: int = 2
    recovery_seconds: int = 30
    use_cli_first: bool = True
    orchestrator: str = "opencode"

    model_claude: str = "claude-sonnet-4-20250514"
    model_codex: str = "gpt-5-codex"
    model_opencode: str = "gemini-3-pro-preview-05-28"

    api_claude: str = API_CLAUDE
    api_openai: str = API_OPENAI

    cli_paths: Dict[str, Optional[str]] = field(default_factory=dict)

    @classmethod
    def from_env(
        cls,
        dotenv: Optional[PathLike] = None,
        config_json: Optional[PathLike] = None,
    ) -> "EngineSettings":
        if dotenv:
            load_dotenv(dotenv)
        s = cls(
            timeout_cli=_int_env("JARVIS_TIMEOUT_CLI", 600),
            timeout_api=_int_env("JARVIS_TIMEOUT_API", 120),
            max_failures_before_isolate=_int_env("JARVIS_MAX_FAILURES", 2),
            recovery_seconds=_int_env("JARVIS_RECOVERY_SECONDS", 30),
            orchestrator=os.environ.get("JARVIS_ORCHESTRATOR", "opencode"),
        )
        s.model_claude = os.environ.get("JARVIS_CLAUDE_MODEL", s.model_claude)
        s.model_codex = os.environ.get("JARVIS_CODEX_MODEL", s.model_codex)
        s.model_opencode = os.environ.get("JARVIS_OPENCODE_MODEL", s.model_opencode)
        s.api_claude = os.environ.get("JARVIS_CLAUDE_API_URL", s.api_claude)
        s.api_openai = os.environ.get("JARVIS_CODEX_API_URL", s.api_openai)
        if config_json and Path(config_json).is_file():
            data = json.loads(Path(config_json).read_text(encoding="utf-8"))
            for key, value in data.items():
                if hasattr(s, key):
                    setattr(s, key, value)
        return s