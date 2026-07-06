---
name: n8n-projeto
description: Mapa que o workspace orquestra-tarefa tem do subprojeto acoplado N8N-AGENT (github.com/blips-ai/N8N-AGENT) — o repositório do conhecimento de n8n da empresa. Carregue antes de qualquer operação via /n8n ou pelo agente n8n-bridge. Cobre a lei read-only, os 6 ambientes n8n + Grafana, as 5 skills locais, a estrutura (patterns/workflows/bitrix), o setup de MCP/keys e quando entrar no subprojeto. NÃO substitui o CLAUDE.md e as skills DENTRO do N8N-AGENT — é índice + ponte; para detalhe operacional, leia os originais lá.
---

# Skill — N8N-AGENT (subprojeto acoplado, n8n read-only)

`N8N-AGENT/` é um **repositório git próprio** (`github.com/blips-ai/N8N-AGENT.git`) acoplado dentro do workspace orquestra-tarefa, em `C:\Users\João Vinicius\Documents\Finza\Projetos\orquestra-tarefa\N8N-AGENT`. Ele transforma o Claude num **especialista em n8n** da Blips/Finza, operando as instâncias em **modo somente leitura**.

Esta skill é o **mapa que o parent tem** do subprojeto — para que o agente `n8n-bridge` e o comando `/n8n` saibam o que existe lá e quando entrar. **A fonte de verdade do domínio é o `N8N-AGENT/CLAUDE.md`, `patterns/` e as skills locais** — leia de lá para detalhe.

## 🔒 Lei read-only

O Claude **nunca** cria/edita/deleta/executa workflows, credenciais ou data tables nas instâncias. Bloqueado por `deny` (no `settings.json` do N8N-AGENT e replicado no `settings.json` do parent):
`n8n_create_workflow`, `n8n_update_full_workflow`, `n8n_update_partial_workflow`, `n8n_delete_workflow`, `n8n_autofix_workflow`, `n8n_test_workflow`, `n8n_deploy_template`, `n8n_manage_datatable`, `n8n_manage_credentials`, `n8n_generate_workflow`, e curl `POST/PUT/PATCH/DELETE`.

**Liberado (read-only):** `n8n_list_workflows`, `n8n_get_workflow`, `n8n_validate_workflow`, `n8n_executions` (get/list), `n8n_workflow_versions` (histórico), `n8n_health_check`, `n8n_audit_instance`, `search_nodes`, `get_node`, `search_templates`, `get_template`, `validate_workflow`, `validate_node`, `tools_documentation`.

**Fluxo de criação:** Claude monta o JSON localmente (em `N8N-AGENT/workflows/templates/`), valida via MCP (read-only), apresenta — e **o usuário importa manualmente** na instância (UI: Workflows > Import from File). Daqui (parent), isso é apenas roteado: a construção acontece dentro do subprojeto.

## Os 6 ambientes n8n + Grafana

Cada ambiente é um MCP server com namespace próprio (`mcp__<server>__<tool>`):

| MCP server | Host | Finalidade |
|---|---|---|
| `n8n-dev` | n8n-dev.blips-labs.com | Dev/rascunho/staging. Nada de prod. |
| `n8n-prod-assistants` | n8n-assistants.blips-labs.com | Agentes de IA fora do comercial (exceto Dalila). |
| `n8n-prod-salesops` | salesops.blips-labs.com | Comercial/marketing + Dalila (IA comercial). |
| `n8n-prod-automacao` | automacao.blips-labs.com | Automação operacional recorrente/simples, sem IA. |
| `n8n-prod-auditoria` | n8n-auditoria.blips-labs.com | Auditoria + plataforma Nascimento. |
| `n8n-prod-monitoria` | monitoria.blips-labs.com | Monitoria/observabilidade. |
| `grafana` | blipsdata.grafana.net | Métricas dos n8ns (dashboard UID `darn2dz`). |

Há ainda **4 ambientes só-Postgres** sem MCP/REST (`motor_credito`, `n8n_performance`, `performance_mkt`, `n8n_engenharia`), acessíveis só via a skill local `n8n-db`.

Ao reportar dado de workflow/execução, **sempre diga o ambiente**. Em dúvida de qual usar, **pergunte**.

## Skills locais do subprojeto (deep dive — dentro do N8N-AGENT)

| Skill | Para quê |
|---|---|
| `bitrix24-api` | API REST do Bitrix24 — entidades (Lead/Deal/SPA 1070), endpoints, batch, paginação, gotchas. Cache de schema em `bitrix/` + `/update-bitrix`. |
| `hyperflow-blips` | Plataforma de atendimento (chatbot/WhatsApp) — GraphQL/Webhook/Runtime + análise BigQuery. |
| `n8n-db` | SQL direto no Postgres backend dos n8ns — cross-ambiente, estatísticas de execução, busca no JSON dos nodes, execuções travadas. Cobre os 4 ambientes só-Postgres. |
| `n8n-metrics-grafana` | Métricas via Grafana (taxa de sucesso, erros, latência p50/p95/p99, log por Execution ID). |
| `fantasmas-blips` | Agentes fantasma no Hyperflow (BigQuery + validação cruzada + retransferência). |

## Estrutura do subprojeto (referência global)

- `patterns/` — **leitura obrigatória antes de criar workflow**: nomenclatura, triggers, sub-workflows, error handling, expressões, Set vs Code, integrações, estrutura visual. Fonte única de estilo.
- `workflows/examples/` — JSONs reais exportados por ambiente (qualquer exemplo pode informar qualquer alvo). Gap conhecido: `prod-salesops` sem exemplos.
- `workflows/templates/` — rascunhos locais do Claude (gitignored).
- `bitrix/` — cache do schema Bitrix (SPA 1070, Deals, stages). Atualiza com `/update-bitrix`.
- `.claude/commands/update-bitrix.md` — único comando local.

> Regra de ouro do subprojeto: se um `pattern` diverge de um exemplo, o **pattern vence**.

## Setup do MCP no parent (pré-requisito para o /n8n funcionar)

Os MCP servers do n8n **não** são herdados automaticamente do subprojeto — o parent precisa do próprio `.mcp.json`. Passos:

1. Copiar `orquestra-tarefa/.mcp.json.example` → `.mcp.json` (gitignored) e `orquestra-tarefa/.env.example` → `.env`.
2. Preencher as chaves:
   - **`N8N_*_KEY`** (uma por ambiente): na instância n8n (`https://<host>/` → Settings → **n8n API** → *Create an API key*). Referência adicional do time no **Confluence** (ver `N8N-AGENT/README.md`).
   - **`GRAFANA_SERVICE_ACCOUNT_TOKEN`**: `blipsdata.grafana.net` → Administration → **Service accounts** → criar token.
3. **Reiniciar o Claude Code** para subir os servers (`enableAllProjectMcpServers: true` no `settings.json`).
4. Testar: `/n8n` → `n8n_health_check` por ambiente. Saúde OK = conexão validada. Tools ausentes = key/`.mcp.json` faltando, não bug.

> O `.mcp.json` real e o `.env` **nunca** são commitados (gitignored).

## Quando ENTRAR no subprojeto

Consultas rápidas (listar/ler/validar/auditar/métrica) ficam no `/n8n`. Para **criar/alterar/debugar workflow a fundo**, **Bitrix**, **Hyperflow**, **SQL cross-ambiente** ou **fantasmas**, abra o subprojeto: `cd N8N-AGENT` e rode `claude` lá — é onde vivem as skills profundas e o fluxo read-only de construção de workflow.
