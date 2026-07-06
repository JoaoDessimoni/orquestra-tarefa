---
description: Ponte read-only para o subprojeto N8N-AGENT (conhecimento de n8n da empresa). Subcomandos — workflows, show, execucoes, validar, auditar, metricas, padroes, entrar. Opera os 6 ambientes n8n (dev + 5 prod) + Grafana via MCP em SOMENTE LEITURA. Criação/alteração de workflow acontece DENTRO do subprojeto (import manual). Não confunde com /quimera, /jira, /torre nem /backlog.
---

# /n8n — consultar os workflows da empresa (read-only)

Roteia para o agente **`n8n-bridge`**, que usa as ferramentas MCP `mcp__n8n-*__*` em **modo somente leitura**. Conhecimento do subprojeto na skill `n8n-projeto`; o domínio profundo vive dentro de `N8N-AGENT/`.

> **n8n é read-only daqui.** Esta ponte lista, lê, valida e audita — **nunca** cria/edita/deleta/executa workflow. Para construir ou alterar um workflow, **entre no subprojeto** (`/n8n entrar`): lá o Claude monta o JSON localmente, valida read-only e **você importa manualmente** na instância.

> **n8n ≠ Quimera ≠ Jira ≠ Torre ≠ /backlog.** Cada um é um sistema distinto. Não cruze.

`$ARGUMENTS` define o subcomando. Quando o ambiente não for dado e não for óbvio, **pergunte** (nunca assuma):

| Forma | O que faz |
|---|---|
| `/n8n` (vazio) | Saúde dos ambientes — `n8n_health_check` em dev + prod, resumo de conectividade. |
| `/n8n workflows [ambiente] [busca]` | Lista workflows (`n8n_list_workflows`) do ambiente. Tabela `id · nome · ativo? · ambiente`. |
| `/n8n show <id> [ambiente]` | Detalhe de um workflow (`n8n_get_workflow`) — trigger, nodes, status. JSON completo sob demanda. |
| `/n8n execucoes <id> [ambiente] [status=]` | Execuções de um workflow (`n8n_executions`, modo list/get). Falhas destacam erro + node. |
| `/n8n validar <arquivo.json\|id> [ambiente]` | Valida um JSON (`validate_workflow`) ou um workflow da instância (`n8n_validate_workflow`). Read-only, não publica. |
| `/n8n auditar <ambiente>` | Auditoria de segurança da instância (`n8n_audit_instance`). |
| `/n8n nodes <busca>` | Busca documentação de nodes/templates (`search_nodes`, `get_node`, `search_templates`). |
| `/n8n metricas [ambiente]` | Métricas via Grafana (taxa de sucesso, erros, latência). Para log detalhado por Execution ID → entrar no subprojeto (skill `n8n-metrics-grafana`). |
| `/n8n padroes <assunto>` | Lê `N8N-AGENT/patterns/` e `workflows/examples/` para responder sobre estilo/convenção interna. |
| `/n8n entrar [tarefa]` | Orienta abrir o subprojeto (`cd N8N-AGENT` → `claude`) e nomeia a skill certa para a tarefa (criar workflow, Bitrix, Hyperflow, Postgres cross-ambiente, fantasmas). |

## Execução

Invoque `n8n-bridge` passando o subcomando + args. Brief:
```
Subcomando: <workflows|show|execucoes|validar|auditar|nodes|metricas|padroes|entrar>
Args: <args>
Ambiente: <n8n-dev|n8n-prod-assistants|n8n-prod-salesops|n8n-prod-automacao|n8n-prod-auditoria|n8n-prod-monitoria> (perguntar se ambíguo)
```

## Quando pedir input adicional (via AskUserQuestion)

- Subcomando que toca instância sem ambiente claro → ofereça a lista dos 6 e pergunte.
- Pedido de **criar/alterar** workflow → não execute; explique que é só leitura e ofereça `/n8n entrar`.
- `show`/`execucoes` sem id → rode `workflows` primeiro e pergunte qual.

## Regras duras

- **Leitura livre** (`workflows`, `show`, `execucoes`, `validar`, `auditar`, `nodes`, `metricas`, `padroes`) — executa direto.
- **Escrita é proibida daqui** e bloqueada por deny no `settings.json`. Criar/editar/deletar/executar workflow só dentro do `N8N-AGENT/`, com import manual pelo usuário.
- **Sempre indicar o ambiente** de origem do dado. Em dúvida de ambiente, perguntar.
- Não gera artefato `.md` no workspace — o n8n é o sistema de registro. (Para persistir um recorte como análise/relatório, encadeie `/analise` ou `/relatorio` depois.)
- Se as tools MCP não responderem, é provável `.mcp.json`/key faltando (ver setup na skill `n8n-projeto`), não bug.
