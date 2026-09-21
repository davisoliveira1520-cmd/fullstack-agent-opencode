# fullstack-agent (OpenCode)

> Give your AI a full stack: memory, voice, face, and hands. This is the "I want an AI agent" shortcut. It sets up the entire jaredrhod stack with an installation wizard — but running on **OpenCode** instead of Claude Code.

**Runs on:** [OpenCode](https://github.com/anomalyco/opencode), the open-source AI coding agent. Everything is driven from OpenCode; the installer itself is an OpenCode wizard.

Not an agent that writes full-stack code. **An agent that HAS a full stack: memory, voice, and face, plus an optional set of hands.** This repo assembles the whole setup on your machine in one guided conversation, and when it finishes, your screen is a living circuit board with your agent's name on the chip, and it speaks first:

> "Hello [you], what are we working on today?"

## What you get

Four pieces, each its own open repo, each excellent alone, assembled here into one agent:

- **The mind: [ai-memory-vault](https://github.com/jaredrhod/ai-memory-vault).** A real, persistent memory built on plain text files your AI reads and writes. It remembers you, your work, and every lesson, across every session, with no size ceiling.
- **The mouth: [backtalk](https://github.com/jaredrhod/backtalk).** Hold a key, talk out loud, and your agent answers through your speakers about a second later, with all its tools and its whole personality.
- **The face: [ai-visualizer](https://github.com/jaredrhod/ai-visualizer).** Full-screen visualizers that idle, listen, think, and speak in sync with the real conversation. Four faces ship, including the living circuit board.
- **The hands, the optional extra: [barehands](https://github.com/jaredrhod/barehands).** Move notes and images around your screen with your bare hands through your webcam. No headset, no controllers. Opens in its own window instead of the face. Take it now or add it later by running the same install again.

Every piece is optional. The wizard asks which ones you want and explains each in plain English before you decide.

## Install

**O Jarvis já vem completo.** Este repositório tem tudo dentro: o OpenCode (binário embutido), o Claude Code, o OpenClaw, o Open-Lovable, o Freebuff, o Hermes Agent e o OpenJarvis. Nada se instala no seu PC além de descompactar esta pasta — o próprio Jarvis cuida do resto.

**Windows (PowerShell):** baixa o toolbox e abre o Jarvis no navegador. Na primeira execução, o `jarvis.bat` instala Node.js/OpenClaw automaticamente e sobe o assistente:

```
$d="$env:USERPROFILE\.local\bin"; if (Test-Path "$d\opencode.exe") { $env:Path="$d;$env:Path" }; New-Item -ItemType Directory -Force -Path $HOME\jarvis | Out-Null; cd $HOME\jarvis; if (-not (Test-Path jarvis.bat)) { Invoke-WebRequest https://github.com/davisoliveira1520-cmd/fullstack-agent-opencode/archive/refs/heads/main.zip -OutFile jarvis.zip; Expand-Archive jarvis.zip . -Force; New-Item -ItemType Directory -Force -Path jarvis | Out-Null; Get-ChildItem fullstack-agent-opencode-main -Force | Copy-Item -Destination jarvis -Recurse -Force; Remove-Item fullstack-agent-opencode-main -Recurse -Force; Remove-Item jarvis.zip }; cd jarvis
```

Depois do download, é só **duplo-clique em `jarvis.bat`** (Windows). Na primeira vez ele instala Node.js e o OpenClaw sozinho e **abre o Jarvis no navegador automaticamente** — fale e use. Prefere terminal? `jarvis-cli.bat`. No macOS/Linux: `chmod +x jarvis.sh && ./jarvis.sh`.

**Instalação oficial:**

```
winget install davisoliveira1520-cmd.Jarvis        # Windows
brew tap davisoliveira1520-cmd/jarvis              # macOS / Linux
brew install jarvis
```

Os manifests de publicação estão em `packaging/winget/` (PR para microsoft/winget-pkgs) e a formula em `brew/jarvis.rb`.

## Instalar por plataforma (terminal)

**Windows (PowerShell ou Prompt):** baixa o repo, descompacta o OpenCode embutido em `bin\` e abre o Jarvis:

```powershell
winget install davisoliveira1520-cmd.Jarvis   # após aprovação do PR
# ou manual (funciona já):
git clone --depth 1 https://github.com/davisoliveira1520-cmd/fullstack-agent-opencode.git jarvis
cd jarvis
.\jarvis.bat
```

**macOS:**

```bash
brew tap davisoliveira1520-cmd/jarvis && brew install jarvis && jarvis.sh
# ou manual:
git clone --depth 1 https://github.com/davisoliveira1520-cmd/fullstack-agent-opencode.git jarvis
cd jarvis && chmod +x jarvis.sh && ./jarvis.sh
```

**Linux (Debian/Ubuntu etc.):**

```bash
sudo apt install curl unzip -y
git clone --depth 1 https://github.com/davisoliveira1520-cmd/fullstack-agent-opencode.git jarvis
cd jarvis && chmod +x jarvis.sh && ./jarvis.sh
```

**Android (app Termux):** usa o binário Linux arm64, funciona normalmente:

```bash
pkg update && pkg install git curl unzip -y
git clone --depth 1 https://github.com/davisoliveira1520-cmd/fullstack-agent-opencode.git jarvis
cd jarvis && chmod +x jarvis.sh && ./jarvis.sh
```

**iOS:** sem suporte nativo. O OpenCode não roda de verdade no terminal do iPhone/iPad. Caminho experimental: app **iSH** (emula Linux x86_64) com os comandos do Linux — instável e lento. Recomendado: a versão web (`opencode web`) em qualquer navegador.

> No macOS/Linux/Android, o primeiro `jarvis.sh` baixa o binário certo do OpenCode para `bin/` automaticamente (uma vez só). No Windows, o `jarvis.bat` extrai o `bin\opencode-windows-x64.zip` embutido.

OpenCode abre com o instalador já conversando com você. Tudo depois disso é conversa: ele pergunta o nome e a personalidade do seu agente (ou entrega o meu, Jarvis, pronto para usar), quais peças você quer e onde suas notas vivem. Ele mesmo faz o instalar, o configurar e o ligar isso tudo.

## Already built some of this?

Then you're exactly who this was designed around. If you set up a memory vault, a voice system, or a visualizer before, the wizard adopts before it installs:

- **Your agent's identity and your vault are yours.** Found, kept, never rebuilt, never moved. No questions you already answered.
- **Hand-built voice lines and visualizers get honestly replaced**, because these repos carry a year of fixes and keep improving with a `git pull`, while a hand-built version is frozen the day it was written. Your old build stays on disk, untouched. Nothing you made is ever deleted.
- **Except your visualizer scene, which gets promoted.** If your AI built you a custom scene back then, the wizard copies it into the visualizer's gallery as your own face, sitting right beside mine.

## After setup

- **Use your agent:** the wizard leaves three shortcuts on your Desktop, named after your agent. **Chat** opens a typed OpenCode session, terminal only. **Talk** starts the voice and the face. **Barehands** starts the voice and the hands board (the board is the screen in that mode). Double-click the mood you want; Ctrl-C in the window stops it. (They just run `fullstack-agent/start.sh`, or `start.bat` on Windows, if you ever prefer the terminal.)
- **Something broken or confusing? Ask your agent to fix it.** Seriously. Open the chat and describe the problem. Every repo here ships a troubleshooting guide written for your agent to read, and your agent is instructed during setup to do the fixing itself. This is the part everyone finds out late: you never have to debug this stack yourself.
- **Update everything:** `./fullstack-agent/update.sh` on macOS. On Windows, ask your agent: "update everything and tell me what changed." Your files live outside the repos, so updates never touch who your agent is or what it remembers.
- **Daily habit:** open OpenCode in your agent's folder. That's where it lives.

## The fine print that matters

- The wizard never deletes, overwrites, or moves anything you built. Replacements retire the old thing in place and say so.
- Your vault stays wherever it already lives. Pieces connect by configuration paths, not by relocation.
- Requirements per piece: the voice needs a mic and about 1 GB of local models on first run; the hands need a webcam and Chrome; the mind and face need nothing but Python 3, which ships with macOS and most Linux distributions. **Windows ships none**, and the name `python` there is a Microsoft Store placeholder that passes a check and then exits without running, so the face and the hands each carry a `run.bat` that finds a working interpreter or says plainly that there is not one. Windows notes live in each piece's own README.
- Cross-piece problems: `TROUBLESHOOTING.md` here. Everything else: each piece's own guide.

## Sources and thanks

Built on the free and open work of **Jared Rhodenizer** ([jaredrhod/fullstack-agent](https://github.com/jaredrhod/fullstack-agent)), adapted to run on **OpenCode** ([anomalyco/opencode](https://github.com/anomalyco/opencode)) in place of Claude Code. Community, videos, and Discord: https://jaredrhod.com

## OpenJarvis

Em `openjarvis/` está o **[OpenJarvis](https://github.com/open-jarvis/OpenJarvis)** (Stanford / Hazy Research) — framework Python para IA pessoal local-first, Apache 2.0:

```bash
jarvis                          # start chatting
jarvis init --preset <name> --force
jarvis doctor                   # status
```

Skills, agentes built-in (morning_digest, deep_research, orchestrator, code-assistant etc.), docs e tutoriais: https://open-jarvis.github.io/OpenJarvis/

## OpenClaw

Em `openclaw/` está o **[OpenClaw](https://github.com/openclaw/openclaw)** — assistente de IA open-source que roda na sua máquina e atende nos canais que você já usa (Discord, iMessage, Slack, Teams, Telegram, WhatsApp, +20), com apps nativos e Gateway local (MIT):

```bash
npm install -g openclaw@latest --allow-scripts=openclaw
openclaw onboard --install-daemon
openclaw gateway status
openclaw dashboard
```

Docs, modelos, skills e plugins: https://docs.openclaw.ai

## Claude Code

Em `claude-code/` está o **[Claude Code](https://github.com/anthropics/claude-code)** — o agente de codificação da Anthropic (terminal):

```bash
npm install -g @anthropic-ai/claude-code
claude
```

USO: https://docs.anthropic.com/en/docs/claude-code
Politica comercial / licença: https://www.anthropic.com/legal/commercial-terms

## Open-Lovable

Em `open-lovable/` está o **[Open-Lovable](https://github.com/firecrawl/open-lovable)** — uma recriação open-source do Lovable: crie, clone e recrie apps com IA a partir de uma conversa (copie um site existente e faça o Jarvis reconstruí-lo):

```bash
npm install
npm run dev        # web UI (assistente de apps)
```

Pergunte ao Jarvis (falando): "crie um app com a cópia do Lovable" — ele usa esta pasta para gerar a aplicação.

## Freebuff

Em `freebuff/` está o **[Freebuff](https://github.com/CodebuffAI/freebuff)** — o agente de codificação gratuito (Apache-2.0): **5 produtos de IA gratuitos** (CLI, Web, Cloud, Desktop e Chat) para codificar, construir e pesquisar — **sem assinatura, sem créditos e sem chave de API** (modelos incluídos, com anúncios em texto):

```bash
npm install -g freebuff
freebuff           # CLI: descreva o que quer e ele edita, roda e revisa
```

O Freebuff roda **junto com o Open-Lovable**: enquanto o Open-Lovable gera o app a partir da conversa (web UI), o Freebuff codeja/melhora o projeto no terminal usando os modelos grátis inclusos. Veja `freebuff/JARVIS.md` para o fluxo conjunto.

Integração no Jarvis:

```bash
cd freebuff && npm install -g .   # instala o CLI local
freebuff                         # no diretório do app gerado pelo Open-Lovable
```

Modelos gratuitos inclusos: GLM 5.3 Flash, DeepSeek V4.1 Flash, GPT-5.6 Luna, MiMo 2.5, Solar Pro 4 e Muse Spark 1.2.

Docs: https://freebuff.com
Licença: Apache-2.0 (ver `freebuff/LICENSE`)

## Hermes Agent

Em `hermes-agent/` está o **[Hermes Agent](https://github.com/nousresearch/hermes-agent)** — o agente de IA **auto-melhorativo** da Nous Research (MIT): cria skills a partir da experiência, melhora elas durante o uso, busca nas próprias conversas passadas, tem memória persistente entre sessões, cron de automações e fala com você pelo **Telegram/Discord/Slack/WhatsApp/CLI** a partir de um único gateway — inclusive rodando fora do seu PC:

```bash
# Linux/macOS/WSL2/Termux
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# Windows nativo (PowerShell)
iex (irm https://hermes-agent.nousresearch.com/install.ps1)
```

O Hermes roda **junto com o resto do Jarvis**: enquanto o OpenClaw/OpenCode atendem no gateway web e o Open-Lovable/Freebuff constroem os apps, o Hermes guarda memória de longo prazo, agenda tarefas e pode ser acionado pelo Telegram de qualquer lugar. Veja `hermes-agent/JARVIS.md` para o fluxo conjunto.

Docs: https://hermes-agent.nousresearch.com/docs
Licença: MIT (ver `hermes-agent/LICENSE`)

## Codex

Em `codex/` está o **[Codex](https://github.com/openai/codex)** — o agente de codificação terminal-first da OpenAI (Rust), com modo de supervisão CLI/TUI, auto-continue, voice e execução em sandbox Docker:

```bash
npm install -g @openai/codex
codex          # TUI com chat e supervisor
codex exec     # modo CLI/automação
codex --voice  # entrada por fala (requer microfone)
```

USO: https://developers.openai.com/codex/
Licença: Apache-2.0 (ver `codex/LICENSE`)

## License

Copyright (c) 2026 Jared Rhodenizer. Licensed under the GNU Affero General Public License, version 3 or later (AGPL-3.0-or-later), which this adaptation also carries.