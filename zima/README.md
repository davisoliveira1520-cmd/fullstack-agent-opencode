# Jarvis — Deploy ZimaBoard (servidor único, 1 link)

Sobe o Jarvis numa **ZimaBoard** (ou qualquer PC Linux sempre ligado) para que o app web
e o cérebro (OpenClaw/OpenCode) rodem juntos, atrás de um **único link HTTPS**:

- o **app web** (voz + chat + criar apps) é servido em `https://jarvis.sedominio`
- o **gateway** (OpenClaw/OpenCode) roda no mesmo domínio, proxied pelo Caddy
- PC, celular, qualquer dispositivo: **só abrir o link — nada instalado**

## Com 4 placas (recomendado)

Sim, dá pra usar as ZimaBoards como **seus servidores**. Cada placa tem um papel; rode em
**cada uma** o deploy do papel dela — é idempotente (repetir é seguro):

```bash
Placa 1  bash zima/deploy-multi.sh cerebro   # cérebro + link único HTTPS (roda o deploy.sh)
Placa 2  bash zima/deploy-multi.sh apps      # Open-Lovable + Freebuff (cria e termina apps)
Placa 3  bash zima/deploy-multi.sh memoria   # Hermes Agent (memória, skills, Telegram/Discord)
Placa 4  bash zima/deploy-multi.sh codigo    # Codex + Claude Code (agentes de terminal)
```

```bash
Placa única (8 GB+)  bash zima/deploy-multi.sh tudo   # tudo dentro de uma placa só
```

### Cluster de um comando só (`zima/cluster.sh`)

Do **seu PC** (Git Bash/WSL/Linux), sem entrar em cada placa: o script baixa o repo
em cada placa, define os nomes da rede (`zima-cerebro`, `zima-apps`, `zima-memoria`,
`zima-codigo` no `/etc/hosts` de todas) e roda o deploy do papel certo onde precisa:

```bash
# 0) uma vez por placa: copie sua chave SSH (senha so na primeira vez)
ssh-copy-id zima1@10.0.0.10        # (repita para os outros IPs)

# 1) configurar o cluster (pergunta os IPs, users, domínio) — gera zima/cluster.env
bash zima/cluster.sh init

# 2) baixar + instalar tudo em todas as placas (a primeira vez demora)
bash zima/cluster.sh deploy

# 3) ver a saúde de todas: RAM, serviços (jarvis-gateway/caddy/hermes-gateway), nomes
bash zima/cluster.sh status

# extras
bash zima/cluster.sh logs cerebro    # acompanhar logs do papel em tempo real
bash zima/cluster.sh cmd codigo "codex exec \"me ajude no projeto\""  # comando livre
```

Depois de instalado, o acesso de fora continua entrando só pela **placa 1**:
registro **A** do domínio → IP público, port-forward **80/443** no roteador.
As placas 2–4 ficam só na rede local, comandadas pela `cmd`/SSH.

| Papel        | RAM mínima | O que instala                                       |
|--------------|-----------|-----------------------------------------------------|
| `cerebro`    | 4 GB      | Node, OpenClaw/OpenCode, Caddy/HTTPS, webapp        |
| `apps`       | 4 GB      | Node, Open-Lovable, Freebuff                        |
| `memoria`    | 8 GB      | Hermes Agent (gateway de mensagens, memória, cron)  |
| `codigo`     | 4 GB      | Node, Codex, Claude Code                            |
| `tudo`       | 8 GB+     | todos os anteriores numa placa só                   |

Dicas:

- O acesso público entra pela **placa 1** (DNS → IP da casa + port-forward 80/443).
  As outras placas podem ficar só na rede local.
- Placas de 8 GB para `cerebro` e `memoria` (Hermes em Python é o mais pesado).
- Nada de modelo local: as placas chamam APIs na nuvem; CPU fraca é suficiente.
  Para LLM local, só com GPU de verdade.

## Como usar

1. Clone o repositório na ZimaBoard:

   ```bash
   git clone https://github.com/davisoliveira1520-cmd/fullstack-agent-opencode
   cd fullstack-agent-opencode
   ```

2. Rode o deploy (pede o domínio e o e-mail):

   ```bash
   bash zima/deploy.sh
   ```

   Ou defina antes, para não perguntar:

   ```bash
   JARVIS_DOMAIN=jarvis.seudominio.com JARVIS_EMAIL=voce@email.com bash zima/deploy.sh
   ```

3. Libere o acesso de fora de casa:
   - Crie o registro **A** do seu domínio apontando para o IP público da sua casa.
   - No roteador, faça **port-forward** das portas `80` e `443` para o IP da ZimaBoard na rede.
   - Espere 1–2 minutos (Caddy emite o certificado SSL automaticamente via Let's Encrypt).

4. Abra `https://jarvis.seudominio` — pronto.

## Configuração do gateway (saúde)

- Parar/ver logs do cérebro (rodando como serviço `jarvis-gateway`):
  ```bash
  sudo systemctl stop jarvis-gateway
  sudo journalctl -u jarvis-gateway -f
  ```
- O arquivo de config do OpenClaw fica em `~/.openclaw/openclaw.json`.
- Certificado SSL: gerenciado automaticamente pelo Caddy (`/etc/caddy/Caddyfile`).
- O webapp é copiado para `/var/www/jarvis`.

## Repetir/redeploy

Rodar `bash zima/deploy.sh` de novo é seguro: atualiza o Caddyfile e reinicia o gateway.
Para atualizar o app sozinho: copie `docs/app/.` para `/var/www/jarvis/`.

## Segurança (importante)

O gateway fica atrás do Caddy escutando só em `loopback` (`127.0.0.1:18789`).
Ainda assim, o endpoint `/v1` só é acessível por quem tiver o link do seu domínio — escolha
um domínio que você não divulgue e não aponte para ele em páginas públicas.