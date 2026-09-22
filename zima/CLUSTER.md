# Jarvis no cluster de ZimaBoards — arquitetura mestre/worker

Fluxo que você quer (e funciona):

```
 Pessoa → Jarvis (web + voz)
              │
              ▼
      Placa 1 · SERVIDOR/MESTRE (cérebro OpenClaw + web + HTTPS)
              │  percebe o pedido e despacha o trabalho
      ├────────┼────────────────┬───────────────┐
      ▼        ▼                ▼               ▼
  Placa 1    Placa 2          Placa 3        Placa 4
  responde   APPS             MEMORIA        CODIGO
  direto     Open-Lovable +   Hermes         Codex +
             Freebuff         (Telegram,      Claude Code
                              lembranças)
              │                │               │
              └──── resultado volta pro mestre ─┘
                        │
                        ▼
                 Jarvis responde a pessoa
```

## Quem é quem

| Peça             | Papel no pedido                                              |
|------------------|--------------------------------------------------------------|
| **Pessoa**       | Fala/escreve no link HTTPS (`jarvis.seudominio`) ou Telegram |
| **Placa 1**      | **Mestre**: OpenClaw/OpenCode (cérebro), webapp, Caddy. É o único "servidor" público; recebe o pedido e decide **onde** trabalhar |
| **Placa 2**      | **Worker apps**: Open-Lovable (cria app) + Freebuff (termina/testa) |
| **Placa 3**      | **Worker memoria**: Hermes (memória de longo prazo, skills, cron, Telegram/Discord) |
| **Placa 4**      | **Worker codigo**: Codex + Claude Code (programação pesada/terminal) |

Cada placa divide a força que tem: a 1 é a porta de entrada + cérebro, e as outras fazem o
trabalho pesado **em paralelo**. O que seria lento numa placa só vira 4 máquinas dividindo.

## Como o mestre chama os workers

O `cluster.sh` já garante que todas se conhecem pelos nomes de rede
(`zima-cerebro`, `zima-apps`, `zima-memoria`, `zima-codigo` no `/etc/hosts`). Da Placa 1,
os workers são alcançáveis assim:

```bash
ssh zima@zima-apps     "bash zima/worker.sh run 'cd open-lovable && npm run dev'"
ssh zima@zima-codigo   "codex exec 'corrija o bug em X'"
ssh zima@zima-memoria  "hermes gateway start"
```

Três maneiras do Jarvis (mestre) usar isso automaticamente:

1. **Hermes SSH backend (nativo)** — o Hermes tem "sete backends de terminal" (local, Docker,
   SSH, ...). Na Placa 1:
   ```bash
   hermes config set terminal.backend ssh
   hermes config set terminal.ssh.hosts '["zima@zima-apps","zima@zima-codigo"]'
   ```
   Aí quando você pede "crie um app", o Hermes lança a tarefa num worker e espera o resultado.

2. **Skill do OpenClaw** — crie uma skill "distribuir" que roda
   `ssh zima@<worker> "<comando>"` e devolve a saída ao chat. O `worker.sh` é o entrypoint.

3. **Cron/memória** — o Hermes da Placa 3 guarda o contexto entre sessões; pedidos
   automatizados (resumo diário, backup) rodam sozinhos e entregam no canal.

## Exemplo real (o que você descreveu)

"crie um app de lista de tarefas e publique"

1. Pessoa fala no link → Placa 1 (mestre) entende o pedido;
2. Mestre **despacha**: Placa 2 gera o app no Open-Lovable e o Freebuff revisa/testa;
   Placa 4 roda os checks de código (Codex/Claude Code), se preciso;
3. Placa 3 guarda o que você já pediu antes (memória) pra personalizar o próximo pedido;
4. Resultado volta pro mestre → Jarvis responde com o **link do app** pro seu celular.

## Importante (realidade, sem enganação)

- Os agentes **não se fundem** num binário único; o padrão real é **mestre/orquestra +
  workers que executam**. Pra esse fim, ZimaBoard (CPU fraca, sem GPU) exige esse design —
  é o "cluster" viável e é exatamente o fluxo que você descreveu.
- O gateway do OpenClaw guarda sessão local, então ele fica numa placa só (a 1).
- Modelo de IA roda **na nuvem** (API); as placas são quem executa o trabalho dos agentes.
- Quer alta disponibilidade do brain (se a Placa 1 cair, outra assume)? Aí sim vale um
  `k3s` nas 4 — mas comece com mestre/worker, que é mais simples e resolve o fluxo acima.