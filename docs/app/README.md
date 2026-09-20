# Jarvis Web — Assistente por voz (modo local)

O **Jarvis Web** é o app web do Jarvis: um assistente pessoal que responde por texto **e por voz**, e que **cria aplicativos** quando você pede (ex.: "crie um app de lista de tarefas") — gerando um arquivo HTML pronto para baixar e usar.

## Como funciona (auto-suficiente)

Por padrão o Jarvis Web usa o **OpenCode + OpenClaw da sua própria máquina** — nada de chave no site:

1. Rode o servidor local no seu PC:
   - **Windows:** `jarvis-server.bat` (na raiz do Jarvis)
   - **macOS/Linux:** `./jarvis-server.sh`
2. Ele sobe o **OpenClaw Gateway** em `http://localhost:18789` **e o próprio app web** em `http://localhost:8080` — usando as chaves e agentes que você já tem (OpenCode / OpenClaw / Open-Lovable).
3. Abra **http://localhost:8080** e fale. Ele conversa com o seu Jarvis — sem pedir chave nenhuma.

## Como rodar

- **Recomendado (modo local, sem chave):** rode `jarvis-server.bat`/`.sh` e abra `http://localhost:8080`. O app e o gateway são servidos localmente (sem bloqueios de CORS).
- **Página publicada:** abra em `https://davisoliveira1520-cmd.github.io/fullstack-agent-opencode/app/` — funciona com os provedores de nuvem (plano B). O modo local pela página publicada é **bloqueado pelo navegador (CORS)**, use o `localhost:8080` para isso.

## Configuração

Abra **Configurações**:

| Campo | O que é | Exemplo |
|---|---|---|
| Provedor | `Jarvis local (OpenCode/OpenClaw)` é o padrão — sem chave | local |
| Provedor de nuvem (opcional) | Para conversar sem ter o servidor local rodando | OpenRouter |

> **Sem servidor local?** O Jarvis Web tenta primeiro o gateway local. Se não estiver rodando, usa o provedor de nuvem configurado (ex.: OpenRouter) — ou avisa para você ligar o `jarvis-server`.

Provedores de nuvem suportados (plano B): **OpenRouter**, **OpenAI**, **HuggingFace** (rota compatível `router.huggingface.co`). A chave fica só no `localStorage` do seu navegador.

## Comando de voz

- **Falar**: clique no microfone (botão vermelho pulsando = ouvindo). Fale o pedido. Ao parar de falar, o Jarvis envia automaticamente.
- **Ler respostas em voz**: o toggle no canto superior direito ativa/desativa o Jarvis falando as respostas.

Comandos especiais por voz:
- "limpe a conversa" → zera a conversa atual.
- "configurações" → abre o painel de configurações.

Funciona em navegadores com suporte a Web Speech API (**Chrome/Edge** recomendados).

## Criando apps com o Jarvis

Qualquer pedido com "crie/faz/gera" + algo de app faz o Jarvis **gerar um app HTML completo** no chat:

> "crie um app de lista de tarefas"
> "faz um site de previsão do tempo"
> "criar um app de calculadora"

O resultado vem em um bloco de código com o código html. No bloco, o botão **⬇ Baixar app** salva o arquivo `.html` — abra e use.

## Limitações conhecidas

- Para o modo local (sem chave), rode o `jarvis-server` e abra **http://localhost:8080** (o modo local não funciona pela página publicada por causa do CORS do navegador).
- A voz é processada no próprio navegador (Web Speech API).
- O Jarvis Web é uma interface web; os agentes de terminal (OpenCode, Claude Code, Codex, OpenClaw) continuam rodando pela CLI — veja o `README.md` na raiz deste repositório.