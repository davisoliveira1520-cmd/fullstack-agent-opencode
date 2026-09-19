# Jarvis Web — Assistente por voz

O **Jarvis Web** é o app web do Jarvis: um assistente pessoal que responde por texto **e por voz**, e que **cria aplicativos** quando você pede (ex.: "crie um app de lista de tarefas") — gerando um arquivo HTML pronto para baixar e usar.

## Como rodar

Não precisa de build nem de instalar nada. Duas opções:

1. **Direto no navegador**: abra o arquivo `index.html` (clique duas vezes). Tudo roda no browser.
2. **Servidor local** (opcional):
   ```bash
   npx serve .
   ```
   e abra `http://localhost:3000`.

## Configuração

Clique em **Configurações** e preencha:

| Campo | O que é | Exemplo |
|---|---|---|
| Provedor | Quem responde as mensagens | OpenRouter (recomendado) |
| Modelo | O modelo de IA | `openai/gpt-4o-mini` |
| Chave da API | Sua chave (fica só no seu navegador) | `sk-or-…` |
| Personalidade | Como o Jarvis se comporta | (pré-preenchido) |

> A chave fica armazenada apenas no `localStorage` do seu navegador — não sai da sua máquina.

Provedores suportados: **OpenRouter**, **OpenAI**, **HuggingFace** (rota compatível `router.huggingface.co`).

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

- Precisa de internet e de uma chave de API configurada.
- A voz é processada no próprio navegador (Web Speech API).
- O Jarvis Web é uma interface web; os agentes de terminal (OpenCode, Claude Code, Codex, OpenClaw) continuam rodando pela CLI — veja o `README.md` na raiz deste repositório.