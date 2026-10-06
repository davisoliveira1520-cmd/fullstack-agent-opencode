# Jarvis — Deploy ZimaBoard (servidor único, 1 link)

Sobe o Jarvis numa **ZimaBoard** (ou qualquer PC Linux sempre ligado) para que o app web
e o cérebro (OpenClaw/OpenCode) rodem juntos, atrás de um **único link HTTPS**:

- o **app web** (voz + chat + criar apps) é servido em `https://jarvis.sedominio`
- o **gateway** (OpenClaw/OpenCode) roda no mesmo domínio, proxied pelo Caddy
- PC, celular, qualquer dispositivo: **só abrir o link — nada instalado**

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