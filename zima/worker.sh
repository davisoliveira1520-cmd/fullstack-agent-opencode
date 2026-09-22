#!/usr/bin/env bash
# ============================================================
#  Jarvis — entrypoint do WORKER (placa 2/3/4)
#  Rode na placa worker (uma vez) para ser alcançado pelo mestre:
#    bash zima/worker.sh setup <chave-publica-do-mestre>
#  E para o mestre executar tarefas:
#    bash zima/worker.sh run "<comando>"
#  (chamado via ssh a partir da Placa 1)
# ============================================================
set -euo pipefail

MODE="${1:-setup}"

case "${MODE}" in
  setup)
    CHAVE="${2:-}"
    if command -v sshd >/dev/null 2>&1; then
      echo "  sshd ja instalado."
    else
      echo "  Instalando openssh-server..."
      sudo apt-get update -y >/dev/null
      sudo apt-get install -y openssh-server
    fi
    sudo systemctl enable --now ssh 2>/dev/null || sudo systemctl enable --now sshd 2>/dev/null || true
    echo "  ssh ativo. Hostname deste worker: $(hostname)"
    if [ -n "${CHAVE}" ]; then
      mkdir -p "${HOME}/.ssh"
      touch "${HOME}/.ssh/authorized_keys"
      grep -qF "${CHAVE}" "${HOME}/.ssh/authorized_keys" || echo "${CHAVE}" >> "${HOME}/.ssh/authorized_keys"
      echo "  Chave do mestre registrada."
    else
      echo "  Dica: par a chave do mestre nao foi passada. Cole em ~/.ssh/authorized_keys ou rode:"
      echo "        bash zima/worker.sh setup \"\$(cat ~/.ssh/id_ed25519.pub)\""
    fi
    echo ""
    echo "  Do MESTRE (placa 1), teste com:"
    echo "        ssh ${USER}@$(hostname) \"bash zima/worker.sh run 'echo oi worker'\""
    ;;

  run)
    shift
    echo "[worker:$(hostname)] tarefa recebida: $*"
    if [ -d "${HOME}/fullstack-agent-opencode" ]; then
      cd "${HOME}/fullstack-agent-opencode"
    fi
    bash -c "$*"
    echo "[worker:$(hostname)] tarefa concluida."
    ;;

  *)
    echo "  Uso: bash zima/worker.sh setup [chave-do-mestre] | run \"<comando>\""
    exit 1
    ;;
esac