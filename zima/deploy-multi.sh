#!/usr/bin/env bash
# ============================================================
#  Jarvis — Deploy multi-ZimaBoard (ate 4 placas como servidores)
#
#  Rode em CADA placa apenas o papel dela:
#
#    bash zima/deploy-multi.sh cerebro   -> P1: cérebro + link unico HTTPS
#    bash zima/deploy-multi.sh apps      -> P2: cria apps (Open-Lovable + Freebuff)
#    bash zima/deploy-multi.sh memoria   -> P3: Hermes (memoria + Telegram/Discord)
#    bash zima/deploy-multi.sh codigo    -> P4: Codex + Claude Code (terminal)
#    bash zima/deploy-multi.sh tudo      -> tudo numa placa so (recomendado 8GB+)
#
#  Rodar o mesmo papel de novo e seguro (idempotente).
# ============================================================
set -euo pipefail

ROLE="${1:-}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(id -u)" = "0" ]; then
  SUDO=""
else
  SUDO="sudo"
fi
SERVICE_USER="${SUDO_USER:-$USER}"

usage() {
  echo "  Uso: bash zima/deploy-multi.sh <papel>"
  echo "  Papeis: cerebro | apps | memoria | codigo | tudo"
}

banner() {
  echo ""
  echo "  ============================================================"
  echo "    JARVIS - DEPLOY MULTI-ZIMABOARD ($1)"
  echo "  ============================================================"
  echo ""
}

install_node() {
  echo "  Node.js"
  if command -v node >/dev/null 2>&1 && [ "$(node -v | sed 's/v//' | cut -d. -f1)" -ge 18 ]; then
    echo "        Node ja instalado: $(node -v)"
  else
    echo "        Instalando Node.js 20 LTS..."
    if command -v apt-get >/dev/null 2>&1; then
      $SUDO apt-get update -y
      $SUDO apt-get install -y curl ca-certificates gnupg
      curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO -E bash -
      $SUDO apt-get install -y nodejs
    else
      echo "        [ERRO] detecte um apt-get para instalar o Node. Instale manualmente."
      exit 1
    fi
  fi
}

# roda um comando como o usuario dono da config (nunca como root)
run_as_user() {
  if [ "$(id -u)" = "0" ]; then
    if command -v runuser >/dev/null 2>&1; then
      runuser -u "${SERVICE_USER}" -- "$@"
    else
      echo "        [AVISO] runuser nao encontrado; rode o passo manualmente como ${SERVICE_USER}."
    fi
  else
    "$@"
  fi
}

# ------------------------------------------------------------------
role_cerebro() {
  banner "PAPEL: cerebro (placa 1 - link unico)"
  echo "  Subindo o cerebro + HTTPS + webapp (mesmo fluxo do deploy.sh):"
  bash "${DIR}/deploy.sh"
  echo "  Pronto. Essa placa e o link publico https://<seu dominino>."
}

# ------------------------------------------------------------------
role_apps() {
  banner "PAPEL: apps (placa 2 - construtor de apps)"
  install_node

  echo "  [2/4] Open-Lovable (web UI de criar apps)"
  if [ -f "${DIR}/../open-lovable/package.json" ]; then
    ( cd "${DIR}/../open-lovable" && npm install )
    echo "        Dependencias do Open-Lovable instaladas."
  else
    echo "        [AVISO] pasta open-lovable nao encontrada neste clone."
  fi

  echo "  [3/4] Freebuff (codificar/corrigir sem chave)"
  $SUDO npm install -g freebuff
  echo "        freebuff instalado globalmente."

  echo "  [4/4] Como usar"
  echo "        - Criar app:  cd ../open-lovable && npm run dev"
  echo "        - Terminar:   freebuff  (no diretorio do app gerado)"
}

# ------------------------------------------------------------------
role_memoria() {
  banner "PAPEL: memoria (placa 3 - Hermes: memoria, skills, Telegram/Discord)"

  echo "  [2/5] Hermes Agent (instalador oficial)"
  run_as_user bash -c "curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash" \
    || echo "        [AVISO] instale manualmente: curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash"

  HERMES_BIN="$(command -v hermes 2>/dev/null || true)"
  if [ -z "${HERMES_BIN}" ]; then
    for p in "${HOME}/.local/bin/hermes" "${HOME}/.hermes/bin/hermes" "${HOME}/bin/hermes" /usr/local/bin/hermes /usr/bin/hermes; do
      if [ -x "${p}" ]; then HERMES_BIN="${p}"; break; fi
    done
  fi
  if [ -z "${HERMES_BIN}" ]; then
    echo "        [ERRO] nao achei o comando 'hermes'. Rode manualmente e depois repita:"
    echo "        hermes gateway setup && hermes gateway start"
    return 1
  fi
  echo "        Hermes bin: ${HERMES_BIN}  (usuario: ${SERVICE_USER})"

  echo "  [3/5] Modelo/provedor + gateway de mensagens"
  run_as_user "${HERMES_BIN}" setup --portal \
    || run_as_user "${HERMES_BIN}" gateway setup \
    || echo "        [AVISO] configure o provedor depois: hermes model / hermes setup"

  echo "  [4/5] Servico hermes-gateway (systemd)"
  cat > /tmp/hermes-gateway.service <<EOF
[Unit]
Description=Hermes Gateway (memoria + Telegram/Discord/WhatsApp)
After=network.target

[Service]
Type=simple
User=${SERVICE_USER}
Environment=PATH=${HOME}/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=${HERMES_BIN} gateway start
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  $SUDO cp /tmp/hermes-gateway.service /etc/systemd/system/hermes-gateway.service
  $SUDO systemctl daemon-reload
  $SUDO systemctl enable hermes-gateway 2>/dev/null || true
  $SUDO systemctl restart hermes-gateway 2>/dev/null || true
  echo "        Servico criado. Veja: sudo journalctl -u hermes-gateway -f"

  echo "  [5/5] Como usar"
  echo "        - Falar com o Jarvis de qualquer lugar: mande msg no Telegram/Discord."
  echo "        - Enviar tarefas longas: o resultado chega no canal quando terminar."
}

# ------------------------------------------------------------------
role_codigo() {
  banner "PAPEL: codigo (placa 4 - agentes de terminal)"
  install_node

  echo "  [2/4] Codex (OpenAI)"
  $SUDO npm install -g @openai/codex
  echo "        codex instalado."

  echo "  [3/4] Claude Code (Anthropic)"
  if [ "${SERVICE_USER}" = "root" ]; then
    $SUDO npm install -g @anthropic-ai/claude-code
  else
    run_as_user npm install -g @anthropic-ai/claude-code
  fi
  echo "        claude instalado. Primeiro uso: claude (login uma vez)."

  echo "  [4/4] Como usar"
  echo "        codex / claude  (rodam no terminal desta placa)"
}

# ------------------------------------------------------------------
role_tudo() {
  banner "PAPEL: tudo (1 placa so - recomendo 8GB+)"
  role_cerebro
  role_apps
  role_memoria || true
  role_codigo
}

# ------------------------------------------------------------------
case "${ROLE}" in
  cerebro) role_cerebro ;;
  apps)    role_apps ;;
  memoria) role_memoria ;;
  codigo)  role_codigo ;;
  tudo)    role_tudo ;;
  *)       echo "  [ERRO] papel desconhecido: ${ROLE}"; usage; exit 1 ;;
esac

echo ""
echo "  ============================================================"
echo "    PRONTO!  Papel '${ROLE}' configurado na placa."
echo "  ============================================================"
echo ""