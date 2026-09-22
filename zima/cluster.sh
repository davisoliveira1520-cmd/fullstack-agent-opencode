# ============================================================
#  Jarvis — Cluster de ZimaBoards (controle de um comando so)
#
#  Rode no seu PC (Git Bash / WSL / Linux) e ele:
#    - baixa o repo em cada placa (clone leve, so as pastas do papel)
#    - configura os nomes da rede (zima-cerebro, zima-apps, ...)
#    - roda o deploy do papel certo em cada placa via SSH
#    - mostra status/logs de todas as placas
#
#  Uso:
#    bash zima/cluster.sh init                          # (1x) perguntas: IPs/dominio
#    bash zima/cluster.sh deploy                        # baixa e instala tudo
#    bash zima/cluster.sh status                        # saude de cada placa
#    bash zima/cluster.sh logs <cerebro|apps|memoria|codigo>
#    bash zima/cluster.sh cmd <papel> "comando livre"   # rodar qualquer comando na placa
#
#  Pre-requisito: chave SSH da maquina onde roda no root/sudoer de cada placa
#    ssh-copy-id <user>@<ip-da-placa>
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/cluster.env"
SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ConnectTimeout=8)

# ---- nomes da rede (cada placa ganha esses nomes no /etc/hosts) ----
declare -A NODES=(
  [cerebro]="zima-cerebro"
  [apps]="zima-apps"
  [memoria]="zima-memoria"
  [codigo]="zima-codigo"
)

# ---- valores padrao (sobrescritos pelo cluster.env se existir) ----
BRAIN_USER=""; BRAIN_HOST=""
APPS_USER="";  APPS_HOST=""
MEMORIA_USER=""; MEMORIA_HOST=""
CODIGO_USER=""; CODIGO_HOST=""
JARVIS_DOMAIN=""; JARVIS_EMAIL=""

if [ -f "${ENV_FILE}" ]; then
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
else
  echo "  [AVISO] zima/cluster.env nao existe. Rode: bash zima/cluster.sh init"
fi

usage() {
  echo "  Uso: bash zima/cluster.sh init | deploy | status | logs <papel> | cmd <papel> \"comando\""
}

get_host_user() {
  local papel="$1" u h
  case "${papel}" in
    cerebro) u="${BRAIN_USER}";  h="${BRAIN_HOST}" ;;
    apps)    u="${APPS_USER}";   h="${APPS_HOST}" ;;
    memoria) u="${MEMORIA_USER}";h="${MEMORIA_HOST}" ;;
    codigo)  u="${CODIGO_USER}"; h="${CODIGO_HOST}" ;;
    *) echo "  [ERRO] papel desconhecido: ${papel}" >&2; exit 1 ;;
  esac
  if [ -z "${u}" ] || [ -z "${h}" ]; then
    echo "  [ERRO] ${papel}: user/host vazios no cluster.env" >&2
    exit 1
  fi
  echo "${u}@${h}"
}

cmd_init() {
  local f=""
  read -r -p "  IP da placa 1 (cerebro, ex.: 10.0.0.10): " BRAIN_HOST
  read -r -p "  User SSH da placa 1: " BRAIN_USER
  read -r -p "  IP da placa 2 (apps): " APPS_HOST
  read -r -p "  User SSH da placa 2: " APPS_USER
  read -r -p "  IP da placa 3 (memoria): " MEMORIA_HOST
  read -r -p "  User SSH da placa 3: " MEMORIA_USER
  read -r -p "  IP da placa 4 (codigo): " CODIGO_HOST
  read -r -p "  User SSH da placa 4: " CODIGO_USER
  read -r -p "  Dominio publico (so placa 1, ex.: jarvis.seudominio.com): " JARVIS_DOMAIN
  read -r -p "  E-mail (certificado SSL): " JARVIS_EMAIL
  cat > "${ENV_FILE}" <<EOF
# Cluster de ZimaBoards do Jarvis
BRAIN_USER="${BRAIN_USER}";      BRAIN_HOST="${BRAIN_HOST}"
APPS_USER="${APPS_USER}";        APPS_HOST="${APPS_HOST}"
MEMORIA_USER="${MEMORIA_USER}";  MEMORIA_HOST="${MEMORIA_HOST}"
CODIGO_USER="${CODIGO_USER}";    CODIGO_HOST="${CODIGO_HOST}"
JARVIS_DOMAIN="${JARVIS_DOMAIN}"
JARVIS_EMAIL="${JARVIS_EMAIL}"
EOF
  echo "  cluster.env criado em ${ENV_FILE}"
  echo "  Dica: uma placa so? deixe apps/memoria/codigo vazias, ou leia zima/README.md."
}

# escreve em /etc/hosts de cada placa os nomes de todas
write_hosts() {
  local papel="$1" host="$1" all="127.0.0.1 localhost"
  for r in cerebro apps memoria codigo; do
    local u h
    case "${r}" in
      cerebro) u="${BRAIN_USER}"; h="${BRAIN_HOST}" ;;
      apps)    u="${APPS_USER}";  h="${APPS_HOST}" ;;
      memoria) u="${MEMORIA_USER}"; h="${MEMORIA_HOST}" ;;
      codigo)  u="${CODIGO_USER}"; h="${CODIGO_HOST}" ;;
    esac
    [ -z "${h}" ] && continue
    all="${all} ${h} ${NODES[$r]}"
  done
  local dest
  dest="$(get_host_user "${papel}")"
  # usa a propria entrada caso a placa ja se declare
  echo "  [network] ${dest} <- /etc/hosts (${NODES[$papel]})"
  # shellcheck disable=SC2029
  ssh "${SSH_OPTS[@]}" "${dest}" "sudo sh -c 'echo \"${all}\" > /etc/hosts; cat /etc/hosts'" >/dev/null
}

deploy_one() {
  local papel="$1" dest env user
  dest="$(get_host_user "${papel}")"
  user="${dest%@*}"
  write_hosts "${papel}"
  echo ""
  echo "  >>> [${papel}] baixando e instalando em ${dest} ..."
  # shellcheck disable=SC2029
  ssh "${SSH_OPTS[@]}" "${dest}" "set -e; cd ~; \
    (sudo apt-get update -y >/dev/null 2>&1 || true); \
    git clone --depth 1 https://github.com/davisoliveira1520-cmd/fullstack-agent-opencode ~/fullstack-agent-opencode 2>/dev/null \
      || (cd ~/fullstack-agent-opencode && git pull --ff-only >/dev/null 2>&1 || true); \
    cd ~/fullstack-agent-opencode && \
    env JARVIS_DOMAIN='${JARVIS_DOMAIN}' JARVIS_EMAIL='${JARVIS_EMAIL}' bash zima/deploy-multi.sh ${papel}" || {
      echo "  [ERRO] deploy do papel ${papel} falhou em ${dest}"; return 1;
    }
  echo "  >>> [${papel}] OK"
}

cmd_deploy() {
  echo "== Deploy do cluster =="
  for r in cerebro apps memoria codigo; do
    local u h
    case "${r}" in
      cerebro) u="${BRAIN_USER}"; h="${BRAIN_HOST}" ;;
      apps)    u="${APPS_USER}";  h="${APPS_HOST}" ;;
      memoria) u="${MEMORIA_USER}"; h="${MEMORIA_HOST}" ;;
      codigo)  u="${CODIGO_USER}"; h="${CODIGO_HOST}" ;;
    esac
    [ -n "${h}" ] && deploy_one "${r}"
  done
  echo ""
  echo "== Cluster instalado. Testando status... =="
  cmd_status
}

cmd_status() {
  for r in cerebro apps memoria codigo; do
    local u h
    case "${r}" in
      cerebro) u="${BRAIN_USER}"; h="${BRAIN_HOST}" ;;
      apps)    u="${APPS_USER}";  h="${APPS_HOST}" ;;
      memoria) u="${MEMORIA_USER}"; h="${MEMORIA_HOST}" ;;
      codigo)  u="${CODIGO_USER}"; h="${CODIGO_HOST}" ;;
    esac
    [ -z "${dest}" ] && continue
    # shellcheck disable=SC2029
    ssh "${SSH_OPTS[@]}" "${dest}" "echo '[${r}] ${dest} ('\$(hostname)')'; uptime; free -m | head -2 | tail -1 | sed 's/^/    RAM: /'; \
      for s in jarvis-gateway hermes-gateway caddy; do systemctl is-active \$s >/dev/null 2>&1 && echo \"    OK  ${r}/\$s\"; done; \
      echo '    ping: '\$(ping -c1 -W2 ${NODES[$r]} >/dev/null 2>&1 && echo 'cluster nome OK' || echo 'nome nao responde')" || echo "  [erro] ${dest}"
    echo ""
  done
}

cmd_logs() {
  local papel="${1:-}"
  [ -z "${papel}" ] && { usage; exit 1; }
  local dest
  dest="$(get_host_user "${papel}")"
  local svc="caddy"
  case "${papel}" in
    cerebro) svc="jarvis-gateway" ;;
    apps)    svc="app" ;;
    memoria) svc="hermes-gateway" ;;
    codigo)  svc="codex" ;;
  esac
  # shellcheck disable=SC2029
  ssh "${SSH_OPTS[@]}" "${dest}" "sudo journalctl -u ${svc} -f" || echo "  [erro] serviço ${svc} em ${dest}"
}

cmd_cmd() {
  local papel="${1:-}"; local comando="${2:-}"
  [ -z "${papel}" ] || [ -z "${comando}" ] && { usage; exit 1; }
  # shellcheck disable=SC2029
  ssh "${SSH_OPTS[@]}" "$(get_host_user "${papel}")" "cd ~/fullstack-agent-opencode 2>/dev/null || true; ${comando}"
}

case "${1:-}" in
  init)   cmd_init ;;
  deploy) cmd_deploy ;;
  status) cmd_status ;;
  logs)   cmd_logs "${2:-}" ;;
  cmd)    cmd_cmd "${2:-}" "${3:-}" ;;
  *)      usage; exit 1 ;;
esac