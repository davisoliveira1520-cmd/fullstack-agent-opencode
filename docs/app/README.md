# Jarvis Web — Assistente por voz (modo local)

O **Jarvis Web** é o app web do Jarvis: um assistente pessoal que responde por texto **e por voz**, e que **cria aplicativos** quando você pede (ex.: "crie um app de lista de tarefas") — gerando um arquivo HTML pronto para baixar e usar.

## Como funciona (auto-suficiente)

Por padrão o Jarvis Web usa o **OpenCode + OpenClaw** — nada de chave no site:

**Opção A — Um único link (recomendado):** o Jarvis rodando numa máquina sempre ligada (ex.: ZimaBoard) com HTTPS serve o app **e** o cérebro juntos:
1. Na ZimaBoard: `bash zima/deploy.sh` (instala OpenClaw, Caddy/HTTPS e copia o app).
2. Pronto: um único link `https://jarvis.seudominio` funciona no PC, na internet e no celular — **sem instalar nada em nenhum aparelho**.

**Opção B — Só na sua máquina:** rode `jarvis-server.bat` (Windows) / `./jarvis-server.sh` e abra `http://localhost:8080`.

## Como rodar

- **Um link, tudo dentro (Zima/nuvem):** `bash zima/deploy.sh` e abra o domínio HTTPS. O app e o gateway vivem no mesmo endereço (sem CORS).
- **Página publicada:** `https://davisoliveira1520-cmd.github.io/fullstack-agent-opencode/app/` — funciona com provedores de nuvem (plano B). O modo Jarvis local via página publicada é **bloqueado pelo navegador (CORS)**; para isso use a Opção A ou B.

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

- Para o modo Jarvis local (sem chave), use a **Opção A** (Zima/domínio HTTPS — recomendado) ou **Opção B** (`jarvis-server`, `http://localhost:8080`). A página publicada no GitHub Pages não acessa o gateway local por causa do CORS do navegador.
- A voz é processada no próprio navegador (Web Speech API).
- O Jarvis Web é uma interface web; os agentes de terminal (OpenCode, Claude Code, Codex, OpenClaw) continuam rodando pela CLI — veja o `README.md` na raiz deste repositório.