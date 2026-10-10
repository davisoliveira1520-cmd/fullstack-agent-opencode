"""Jarvis Engine Manager: colaboração multi-engine (OpenCode, Claude Code, Codex)."""

from .config import EngineSettings, load_dotenv
from .engines import (
    ClaudeCodeEngine,
    CodexEngine,
    Engine,
    EngineError,
    OpenCodeEngine,
)
from .engine_manager import (
    EngineManager,
    EngineResult,
    NoEngineAvailableError,
    Step,
)

__all__ = [
    "EngineSettings",
    "Engine",
    "EngineError",
    "OpenCodeEngine",
    "ClaudeCodeEngine",
    "CodexEngine",
    "EngineManager",
    "EngineResult",
    "Step",
    "NoEngineAvailableError",
    "load_dotenv",
]