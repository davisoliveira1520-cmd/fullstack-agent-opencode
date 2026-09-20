#!/usr/bin/env bash
# ============================================================
#  Jarvis Server (macOS / Linux / Android-Termux)
#  Sobe o OpenClaw Gateway + servidor do Jarvis Web em localhost.
#  Abra http://localhost:8080 no navegador e fale com o Jarvis
#  via voz — usa as chaves/agentes da sua maquina, SEM chave.
# ============================================================
set -euo pipefail

echo ""
echo "  ============================================================"
echo "    JARVIS SERVER  -  modo local"
echo "  ============================================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OCONF="${HOME}/.openclaw"
OCONF_FILE="${OCONF}/openclaw.json"

if [ ! -d "${OCONF}" ]; then
  mkdir -p "${OCONF}"
fi

if [ ! -f "${OCONF_FILE}" ]; then
  cat > "${OCONF_FILE}" <<'EOF'
{
  "gateway": {
    "mode": "local",
    "port": 18789,
    "bind": "loopback",
    "auth": { "mode": "none" },
    "http": { "endpoints": { "chatCompletions": { "enabled": true } } }
  }
}
EOF
  echo "  [OK] Config criada: ${OCONF_FILE}"
else
  if ! grep -q "chatCompletions" "${OCONF_FILE}" 2>/dev/null; then
    echo "  [AVISO] Sua config ${OCONF_FILE} nao habilita o endpoint HTTP."
    echo "  Adicione manualmente:"
    echo '    "gateway": { "http": { "endpoints": { "chatCompletions": { "enabled": true } } } }'
    echo ""
  else
    echo "  [OK] Endpoint HTTP ja habilitado na config."
  fi
fi

OPENCLAW=""
if command -v openclaw >/dev/null 2>&1; then
  OPENCLAW="openclaw"
elif [ -f "${HOME}/bin/openclaw" ]; then
  OPENCLAW="${HOME}/bin/openclaw"
fi

if [ -z "${OPENCLAW}" ]; then
  echo "  [ERRO] OpenClaw (node) nao encontrado."
  echo "  Instale o Node.js (https://nodejs.org) e depois:"
  echo "      npm install -g openclaw@latest"
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "  [ERRO] Node.js nao encontrado no PATH."
  exit 1
fi

echo "  OpenClaw: ${OPENCLAW}"
echo ""
echo "  Iniciando servidor do Jarvis Web em http://localhost:8080"
echo "  Deixe este terminal aberto enquanto usar o Jarvis Web."
echo "  (Ctrl-C para parar tudo.)"
echo ""

export OPENCLAW_PATH="${OPENCLAW}"
node "${SCRIPT_DIR}/jarvis-web-server.mjs"

echo ""
echo "  Servidor encerrado."