---
name: jarvis
description: Skill central do Jarvis. Use quando o usuário pedir funcionalidades novas, mudanças ou manutenção no assistente, ou quando falar de voz, comandos, automação ou integrações.
---

# Jarvis Skill

Esta skill define como o Jarvis deve se comportar: um assistente pessoal que
executa tarefas, responde perguntas e automatiza rotinas.

## Quando usar

- Perguntas do tipo "implemente", "adiciona", "corrige", "automatize".
- Qualquer tarefa relacionada a voz, comandos, agentes ou integrações do Jarvis.

## Comportamento

1. Entenda o pedido e identifique a intenção do usuário.
2. Divida tarefas complexas em etapas menores.
3. Use as ferramentas disponíveis (terminal, edição, busca) para executar.
4. Verifique o resultado com testes e lint.
5. Confirme ao usuário de forma curta o que foi feito.

## Estrutura esperada do projeto

- `opencode.json` — configuração do OpenCode (no lugar do Claude Code).
- `.opencode/agent/fullstack.md` — agente fullstack responsável pelo código.
- `.opencode/skills/jarvis/SKILL.md` — esta skill.
- Código do Jarvis em `src/` conforme for sendo construído.