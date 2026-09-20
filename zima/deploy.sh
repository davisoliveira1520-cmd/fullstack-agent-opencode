#!/usr/bin/env bash
# ============================================================
#  Jarvis ZimaBoard — Deploy servidor único (1 link, tudo dentro)
#  Instala numa ZimaBoard (Debian/Ubuntu):
#    - Node.js
#    - OpenClaw/OpenCode (o "cérebro")
#    - Caddy (HTTPS automático via Let's Encrypt)
#    - O webapp do Jarvis servido no MESMO domínio do gateway
#  Resultado: um único link https://jarvis.seudominio que roda
#  no PC, na internet e no celular, sem instalar nada em nada.
# ============================================================
set -euo pipefail

if [ "$(id -u)" = "0" ]; then
  RUN=""
  SUDO=""
else
  RUN="sudo"
  SUDO="sudo"
fi

echo ""
echo "  ============================================================"
echo "    JARVIS - DEPLOY ZIMABOARD (servidor unico)"
echo "  ============================================================"
echo ""

if [ -z "${JARVIS_DOMAIN:-}" ]; then
  read -r -p "  Digite o dominio (ex.: jarvis.seudominio.com): " JARVIS_DOMAIN
fi
export JARVIS_DOMAIN

if [ -z "${JARVIS_EMAIL:-}" ]; then
  read -r -p "  Digite seu e-mail (certificado SSL, ex.: voce@email.com): " JARVIS_EMAIL
fi
export JARVIS_EMAIL

echo ""
echo "  Dominio:   ${JARVIS_DOMAIN}"
echo "  E-mail:    ${JARVIS_EMAIL}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_DIR="/var/www/jarvis"
SERVICE_NAME="jarvis-gateway"

echo "  [1/6] Node.js"
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

echo "  [2/6] OpenClaw (cerebro do Jarvis)"
if command -v openclaw >/dev/null 2>&1; then
  echo "        OpenClaw ja instalado."
else
  $SUDO npm install -g openclaw@latest
fi

echo "  [3/6] Configuracao do gateway (~/.openclaw/openclaw.json)"
OCONF="${HOME}/.openclaw"
OCONF_FILE="${OCONF}/openclaw.json"
if [ ! -d "${OCONF}" ]; then
  mkdir -p "${OCONF}"
fi
if [ ! -f "${OCONF_FILE}" ]; then
  cat > "${OCONF_FILE}" <<EOF
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
  echo "        Config criada: ${OCONF_FILE}"
else
  echo "        Config ja existe. Conferindo endpoint HTTP..."
  if ! grep -q "chatCompletions" "${OCONF_FILE}" 2>/dev/null; then
    echo "        [AVISO] Sua config nao habilita chatCompletions."
    echo "        Edite ${OCONF_FILE} e adicione:"
    echo '        "gateway": { "http": { "endpoints": { "chatCompletions": { "enabled": true } } } }'
  fi
fi

echo "  [4/6] Copiando o webapp (servido junto com o gateway)"
if [ -d "${SCRIPT_DIR}/../docs/app" ]; then
  $SUDO mkdir -p "${WEB_DIR}"
  $SUDO cp -r "${SCRIPT_DIR}/../docs/app/." "${WEB_DIR}/"
  echo "        Webapp copiado para ${WEB_DIR}"
else
  echo "        [AVISO] docs/app nao encontrado a partir de ${SCRIPT_DIR}"
fi

echo "  [5/6] Caddy (HTTPS automatico + proxy /v1 para o gateway)"
if command -v caddy >/dev/null 2>&1; then
  echo "        Caddy ja instalado."
else
  if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | $SUDO gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | $SUDO tee /etc/apt/sources.list.d/caddy-stable.list
    $SUDO apt-get update -y
    $SUDO apt-get install -y caddy
  else
    echo "        [ERRO] detecte um apt-get para instalar o Caddy."
    exit 1
  fi
fi

echo "  [6/6] Configurando servidor (Caddyfile + servico do gateway)"
CADDYFILE="/etc/caddy/Caddyfile"
$SUDO tee "${CADDYFILE}" > /dev/null <<EOF
${JARVIS_DOMAIN} {
    tls ${JARVIS_EMAIL}
    root * ${WEB_DIR}
    encode gzip

    handle /v1/* {
        reverse_proxy 127.0.0.1:18789
    }

    handle {
        file_server
        try_files {path} {path}/ /index.html
    }
}
EOF
echo "        Caddyfile escrito."

cat > /tmp/jarvis-gateway.service <<EOF
[Unit]
Description=Jarvis Gateway (OpenClaw/OpenCode)
After=network.target

[Service]
Type=simple
User=${USER}
Environment=PATH=/usr/local/bin:/usr/bin:/bin
ExecStart=/usr/local/bin/openclaw gateway run --port 18789 --allow-unconfigured
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
$SUDO cp /tmp/jarvis-gateway.service /etc/systemd/system/${SERVICE_NAME}.service
$SUDO systemctl daemon-reload
$SUDO systemctl enable ${SERVICE_NAME}
$SUDO systemctl restart ${SERVICE_NAME}

$SUDO systemctl reload caddy 2>/dev/null || $SUDO systemctl restart caddy

echo ""
echo "  ============================================================"
echo "    PRONTO!  Tudo no ar."
echo ""
echo "    O link unico do Jarvis:"
echo "        https://${JARVIS_DOMAIN}"
echo ""
echo "    - O OpenCode/OpenClaw executam na ZimaBoard, por tras do"
echo "      domínio (HTTPS), no mesmo endereço do app."
echo "    - Nenhum PC/celular instala nada: eh so abrir o link."
echo ""
echo "    ANTES DE TESTAR DE FORA:"
echo "    1) Aponte o DNS de ${JARVIS_DOMAIN} para o IP publico da casa"
echo "       (registro A). Se usar subdominio, crie o registro."
echo "    2) No roteador, encaminhe as portas 80 (HTTP) e 443 (HTTPS)"
echo "       para o IP da ZimaBoard na rede local."
echo "    3) Aguarde 1-2 min (o Caddy emite o certificado SSL)."
echo ""
echo "    Para parar o cerebro do Jarvis:  sudo systemctl stop ${SERVICE_NAME}"
echo "    Para ver os logs:                sudo journalctl -u ${SERVICE_NAME} -f"
echo "  ============================================================"
echo ""