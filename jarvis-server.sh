#!/usr/bin/env bash
# ============================================================
#  Jarvis Server (macOS / Linux / Android-Termux)
#  Sobe o OpenClaw Gateway + usa as chaves/agentes que voce
#  ja tem na sua maquina (OpenCode / OpenClaw / Open-Lovable).
#  O Jarvis Web conecta em http://localhost:18789 sem chave.
# ============================================================
set -euo pipefail

echo ""
echo "  ============================================================"
echo "    JARVIS SERVER  -  modo local"
echo "  ============================================================"
echo ""

OPENCLAW=""
if command -v openclaw >/dev/null 2>&1; then
  OPENCLAW="openclaw"
elif [ -f "$HOME/bin/openclaw" ]; then
  OPENCLAW="$HOME/bin/openclaw"
fi

if [ -z "${OPENCLAW}" ]; then
  echo "  [ERRO] OpenClaw nao encontrado."
  echo "  Instale primeiro:  npm install -g openclaw@latest"
  echo "  (ou rode a partir da pasta do Jarvis, que ja vem com tudo)"
  exit 1
fi

echo "  OpenClaw: ${OPENCLAW}"
echo "  Iniciando gateway em http://localhost:18789 ..."
echo "  Deixe este terminal aberto enquanto usar o Jarvis Web."
echo "  (Ctrl-C para parar o servidor.)"
echo ""

"${OPENCLAW}" gateway run --port 18789 --allow-unconfigured

echo ""
echo "  Servidor encerrado."