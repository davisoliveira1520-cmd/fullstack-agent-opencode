# Jarvis Engine Manager (Python)

Gerenciador de conexão dos **3 motores de execução do Jarvis**, com detecção
automática, fallback e **processamento colaborativo**:

```
engine_manager (Python)  ->  OpenCode   (nativo / orquestrador)
                                \  /----->  Claude Code  (CLI local / API)
                                 \/----->  Codex        (CLI local / API)
```

Apenas **stdlib** (sem dependências). Funciona com Python 3.8+.

## Cenários automáticos

| Motores ativos | Cenário | Fluxo |
|---|---|---|
| 1 | `solo` | executa tudo sozinho, autônomo |
| 2 | `peer` | um gera o rascunho, o outro **revisa/otimiza/corrige** antes de entregar |
| 3 | `pipeline` | Claude e Codex propõem **em paralelo**; OpenCode **orquestra**, cruza e sintetiza o resultado final |
| falha durante | fallback | motor é **isolado temporariamente** (cooldown) e o fluxo migra para os motores restantes sem interromper |

Se a síntese orquestrada falhar, o sistema cai para **votação heurística**
(rank por completude) entre as propostas que deram certo.

## Verificação de disponibilidade

Na inicialização, cada motor é checado nesta ordem:

1. **CLI instalada** no PATH (ou caminho explícito / binário embutido do OpenCode);
2. **Credencial de API válida** via env (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`);
3. senão o motor é marcado como indisponível (com o motivo).

O OpenCode é tratado como nativo: usa sempre o binário embutido em `bin/`
(`opencode.exe` no Windows) ou o `opencode` do PATH.

## Usar

Da pasta `python/`:

```bash
# Quais motores estão prontos nesta máquina?
python -m engines.cli --detect

# Executa com colaboração automática (cenário conforme os motores ativos)
python -m engines.cli --run "crie um app de lista de tarefas"

# Saída estruturada para integrar no Jarvis Web / outra ferramenta
python -m engines.cli --run "crie um app de lista de tarefas" --json
```

Uso como biblioteca:

```python
import asyncio
from engines import EngineManager

async def main():
    mgr = EngineManager()
    mgr.detect()
    result = await mgr.execute("crie um app de lista de tarefas")
    print(result.render())
    print(result.final_output)

asyncio.run(main())
```

## Variáveis de ambiente

| Variável | Valor padrão | Função |
|---|---|---|
| `ANTHROPIC_API_KEY` | — | credencial API do Claude Code (fallback quando não há CLI) |
| `OPENAI_API_KEY` | — | credencial API do Codex (fallback quando não há CLI) |
| `JARVIS_ORCHESTRATOR` | `opencode` | motor que sintetiza no cenário pipeline |
| `JARVIS_CLAUDE_MODEL` | `claude-sonnet-4-20250514` | modelo do Claude (modo API) |
| `JARVIS_CODEX_MODEL` | `gpt-5-codex` | modelo do Codex (modo API) |
| `JARVIS_MAX_FAILURES` | `2` | falhas consecutivas antes de isolar um motor |
| `JARVIS_RECOVERY_SECONDS` | `30` | cooldown do motor isolado |
| `JARVIS_TIMEOUT_CLI` | `600` | timeout (s) por chamada de CLI |
| `JARVIS_TIMEOUT_API` | `120` | timeout (s) por chamada HTTP |

Também aceita um `.env` no padrão `KEY=VALUE` (via `load_dotenv`) e um
`config.json` opcional com as mesmas chaves.

## Testes

Requer um Python real instalado (não o alias da Microsoft Store):

```bash
# na raiz do repositório
python -m unittest discover -s python/tests -t python
```

Os testes usam motores falsos (sem CLI/API de verdade) e cobrem detecção,
solo, peer review (com fallbacks), pipeline, votação, isolamento e cooldown.

## Integração futura com o Jarvis Web

O pipeline hoje roda por CLI. Para ligar no Jarvis Web (Node), o caminho é um
**sidecar**: `jarvis-web-server.mjs` delega requests de `/v1/chat/completions`
para um processo Python (`python -m engines.cli --run <prompt> --json`) quando
quiser colaboração multi-engine, mantendo o modo atual (gateway OpenClaw) como
fallback. O `EngineResult` já é serializável em JSON para isso.