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

You need [OpenCode](https://opencode.ai) with a model provider signed in (`opencode auth login`). Mac and Linux also use git (macOS offers to install it the first time you use it). Windows needs nothing else: the installer sets up git for you during setup. Then one paste into your terminal.

Mac and Linux:

```
mkdir -p ~/my-agent && cd ~/my-agent && git clone https://github.com/davisoliveira1520-cmd/fullstack-agent-opencode && cd fullstack-agent-opencode && opencode "set me up"
```

Windows (PowerShell):

```
$d="$env:USERPROFILE\.local\bin"; if (Test-Path "$d\opencode.exe") { $env:Path="$d;$env:Path" }; New-Item -ItemType Directory -Force -Path $HOME\my-agent | Out-Null; cd $HOME\my-agent; if (-not (Test-Path fullstack-agent\fullstack-agent.md)) { Invoke-WebRequest https://github.com/davisoliveira1520-cmd/fullstack-agent-opencode/archive/refs/heads/main.zip -OutFile fsa.zip; Expand-Archive fsa.zip . -Force; New-Item -ItemType Directory -Force -Path fullstack-agent | Out-Null; Get-ChildItem fullstack-agent-opencode-main -Force | Copy-Item -Destination fullstack-agent -Recurse -Force; Remove-Item fullstack-agent-opencode-main -Recurse -Force; Remove-Item fsa.zip }; cd fullstack-agent; if (Get-Command opencode -ErrorAction SilentlyContinue) { opencode "set me up" } else { Write-Output "OpenCode is not installed yet. Install it first at https://opencode.ai then paste this again." }
```

(The Windows command downloads the toolbox as a zip on purpose, so it works on a machine with no git installed. The installer sets up git for you during setup. Safe to paste as many times as you like: it skips the download when the toolbox is already there, and if an earlier attempt died partway and left a half-finished folder, it downloads again and finishes the job rather than assuming it was already done.)

OpenCode opens with the installer already talking to you. Everything after that is a conversation: it asks for your agent's name and personality (or hands you mine, Jarvis, ready to use), which pieces you want, and where your notes live. It does the installing, the configuring, and the wiring itself.

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

## License

Copyright (c) 2026 Jared Rhodenizer. Licensed under the GNU Affero General Public License, version 3 or later (AGPL-3.0-or-later), which this adaptation also carries.