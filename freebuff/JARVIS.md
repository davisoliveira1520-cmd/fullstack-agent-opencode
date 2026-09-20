# Freebuff + Open-Lovable — fluxo conjunto no Jarvis

O Jarvis usa **duas engrenagens de criar apps** que trabalham juntas:

- **Open-Lovable** (`../open-lovable`) cria e recria apps a partir de uma conversa (web UI estilo Lovable: clone um site, descreva o app, ele monta).
- **Freebuff** (esta pasta) codeja, melhora, testa e revisa o projeto no terminal — **com modelos gratuitos inclusos, sem nenhuma chave de API**.

## Fluxo recomendado

1. **Gere o app** com o Open-Lovable (conversa):
   ```bash
   cd ../open-lovable
   npm install
   npm run dev        # web UI — crie/descreva o app
   ```

2. **Melhore e termine** com o Freebuff, no mesmo diretório do app que o Open-Lovable gerou:
   ```bash
   npm install -g freebuff     # ou: cd ../freebuff && npm install -g .
   pushd <pasta-do-app-gerado>
   freebuff                    # codeja, corrige, roda checks
   popd
   ```

3. **Publique**: rode o app e peça ao Jarvis (voz) para revisar, ou use `freebuff` para rodar os checks de qualidade.

## Por que os dois juntos

| A tarefa                      | Quem faz                                    |
|-------------------------------|---------------------------------------------|
| Criar o app a partir da conversa | Open-Lovable (web UI + scaffolding)       |
| Codar/corrigir/otimizar direto  | Freebuff (CLI, modelos grátis inclusos)    |
| Rodar testes e revisar          | Freebuff (roda os checks do projeto)       |
| Recriar app existente (clone)   | Open-Lovable                                |

O Freebuff não exige chave: os modelos (GLM 5.3 Flash, DeepSeek V4.1 Flash, entre outros) vêm inclusos com acesso gratuito.

## Requisitos

- Node.js ≥ 18 (Open-Lovable e Freebuff CLI).
- **Bun** para rodar o Freebuff a partir do código-fonte local:
  `npm install -g bun && cd freebuff && bun install && bun start-cli`