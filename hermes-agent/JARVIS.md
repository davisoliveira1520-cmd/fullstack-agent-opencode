# Hermes Agent + Jarvis — fluxo conjunto

O Hermes é a **memória e a presença externa** do Jarvis. Enquanto o OpenClaw/OpenCode atendem o app web (voz + chat) e o Open-Lovable/Freebuff constroem os apps, o Hermes:

- **Lembra entre sessões**: memoria de longo prazo, busca nas conversas antigas e um modelo do que voce e/ou prefere.
- **Cria skills sozinho**: depois de tarefas complexas ele grava skills e melhora elas durante o uso (padrão [agentskills.io](https://agentskills.io)).
- **Esta em qualquer lugar**: um so gateway fala por Telegram, Discord, Slack, WhatsApp, Signal e CLI — voce manda "manda o Jarvis fazer X" do celular.
- **Agenda tarefas**: cron em linguagem natural (relatorio diario, backup noturno, auditoria semanal).

## Fluxo recomendado

1. **Instale** (uma vez, na maquina que fica como cerebro, ex.: a ZimaBoard):
   ```bash
   curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash   # Linux/WSL2/Termux
   # Windows nativo:  iex (irm https://hermes-agent.nousresearch.com/install.ps1)
   ```

2. **Apresente o Hermes ao resto do Jarvis**: aponte o gateway Hermes para os mesmos canais que voce ja usa (Telegram/Discord/WhatsApp) — ele e o "braco fora do PC" do Jarvis.

3. **Hora a hora**: usa o Jarvis web (voz) no dia a dia; manda tarefas longas de qualquer lugar pelo Telegram; o Hermes entrega o resultado no canal quando terminar.

4. **Publique**: apps gerados pelo Open-Lovable/Freebuff ganham link do Jarvis web (`?app=`) — e o Hermes pode rodar/devolver o resultado em qualquer aparelho.

## Por que usar junto

| A tarefa                        | Quem faz                                            |
|---------------------------------|-----------------------------------------------------|
| Chat/voz no navegador           | OpenClaw/OpenCode (gateway local, sem chave)       |
| Gerar apps a partir da conversa | Open-Lovable                                        |
| Codar/corrigir/testar apps      | Freebuff (modelos gratis inclusos)                  |
| Memoria de longo prazo, skills  | Hermes Agent                                        |
| Falar com o Jarvis do celular   | Hermes Agent (Telegram/Discord/WhatsApp...)         |
| Automacoes e cron               | Hermes Agent (agenda e entrega em qualquer canal)   |

## Requisitos

- Python 3.11+ + uv (o instalador oficial cuida de tudo: Node, ripgrep, ffmpeg e Git Bash portatil no Windows).
- Rodar o gateway em uma maquina sempre ligada (ZimaBoard/VPS) libera o caminho "um link so".
- Modelos: use qualquer um (OpenRouter, OpenAI, endpoint proprio, Nous Portal) — `hermes model` troca na hora; sem lock-in.