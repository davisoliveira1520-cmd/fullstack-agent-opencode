"""CLI do Engine Manager: python -m engines.cli --detect | --run "prompt"."""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import sys

from .engine_manager import EngineManager, NoEngineAvailableError


def _make_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="engines",
        description="Jarvis Engine Manager (OpenCode + Claude Code + Codex)",
    )
    p.add_argument("--detect", action="store_true", help="verifica quais motores estão disponíveis")
    p.add_argument("--run", metavar="PROMPT", help="executa um pedido com colaboração automática")
    p.add_argument("--json", action="store_true", help="saída em JSON (com --run)")
    p.add_argument("--verbose", action="store_true", help="mostra log de debug")
    return p


async def _detect() -> int:
    mgr = EngineManager()
    status = mgr.detect()
    print(f"{'motor':10} {'status':12} {'modo':8} detalhe")
    print("-" * 64)
    for e in mgr.engines:
        ok = status.get(e.name, False)
        print(f"{e.name:10} {'OK' if ok else 'indisponível':12} {(e.mode or '-'):8} {e.last_check_reason}")
    return 0 if any(status.values()) else 1


async def _run(prompt: str, as_json: bool) -> int:
    mgr = EngineManager()
    try:
        res = await mgr.execute(prompt)
    except NoEngineAvailableError as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        return 2
    if as_json:
        print(json.dumps(res.as_dict(), ensure_ascii=False, indent=2))
        return 0
    print(res.render())
    print("\n" + "=" * 20 + " RESULTADO FINAL " + "=" * 20)
    print(res.final_output)
    return 0


def main(argv: list = None) -> int:
    args = _make_parser().parse_args(argv)
    if args.verbose:
        logging.basicConfig(level=logging.DEBUG, format="%(levelname)s %(name)s: %(message)s")
    if args.detect:
        return asyncio.run(_detect())
    if args.run:
        return asyncio.run(_run(args.run, args.json))
    _make_parser().print_help()
    return 0


if __name__ == "__main__":
    sys.exit(main())