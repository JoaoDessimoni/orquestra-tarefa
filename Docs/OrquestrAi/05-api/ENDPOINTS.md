# Endpoints REST + SSE — OrquestrAI

> Tabela completa de endpoints com método, path, request, response, status codes. Última atualização: 20/05/2026.

## Fontes

- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md)
- [SCHEMA_POSTGRES.md](../03-dominio/SCHEMA_POSTGRES.md)
- [REGRAS_DE_NEGOCIO.md](../03-dominio/REGRAS_DE_NEGOCIO.md)
- [STREAMING_SSE.md](../02-arquitetura/STREAMING_SSE.md)

---

## Convenções

- Base URL: `http://localhost:8000`
- Todos os endpoints prefixados com `/api/` exceto `/health` e `/version`.
- Content-Type: `application/json` (exceto SSE: `text/event-stream`).
- Resource IDs aceitos via `slug` (`/agents/{slug}`) ou `UUID` (`/agents/by-id/{id}`).
- Listagens paginadas: `?page=1&limit=20&sort=field:asc|desc`.
- Filtros por query string (`?status=done&agent_slug=...`).
- Status codes seguem [REST conventions](https://restfulapi.net/http-status-codes/).
- Erros: ver [ERROS_E_STATUS](#9--padrão-de-erros).

---

## 1 · Health / Version

| Método | Path | Descrição | Status OK |
|---|---|---|---|
| GET | `/health` | Liveness + readiness (DB conectado) | 200 / 503 |
| GET | `/version` | Build SHA + data + versão | 200 |

### `/health` response

```json
{
  "status": "ok",
  "uptime_seconds": 1234,
  "db": "connected",
  "claude_code_cli": "v0.5.2"
}
```

---

## 2 · Agentes

| Método | Path | Descrição |
|---|---|---|
| GET | `/api/agents` | Lista (paginada, filtros) |
| POST | `/api/agents` | Criar |
| GET | `/api/agents/check-slug?slug=...` | Validar slug único |
| GET | `/api/agents/{slug}` | Detalhe |
| PATCH | `/api/agents/{id}` | Atualizar parcial |
| DELETE | `/api/agents/{id}` | Soft-delete |
| POST | `/api/agents/{id}/clone` | Clonar (V1) |
| GET | `/api/agents/{slug}/executions` | Execuções deste agente |

### `GET /api/agents` query params

| Param | Tipo | Default | Descrição |
|---|---|---|---|
| `q` | string | — | Busca em name, slug, description |
| `model` | string | — | Filtra por modelo |
| `is_subagent` | bool | `false` | Filtra subagentes |
| `tags` | csv | — | Filtra por tags (qualquer) |
| `page` | int | `1` | Página |
| `limit` | int | `20` | Itens por página (max 100) |
| `sort` | string | `updated_at:desc` | Campo:direção |

### `POST /api/agents` request

```json
{
  "slug": "researcher-finza",
  "name": "Researcher Finza",
  "description": "Pesquisa fatos no contexto Finza",
  "system_prompt": "# Researcher Finza\n\nVocê é...",
  "model": "sonnet",
  "tools": ["Read","Grep","Glob","WebFetch"],
  "is_subagent": false,
  "skill_ids": ["uuid-a","uuid-b"],
  "subagent_ids": []
}
```

### Status codes

| Status | Quando |
|---|---|
| 200 | GET, PATCH OK |
| 201 | POST OK |
| 204 | DELETE OK |
| 400 | Body inválido |
| 404 | Agente não encontrado |
| 409 | Slug duplicado / ciclo detectado |
| 422 | Falha de validação semântica (RN-XX) |

---

## 3 · Subagentes

> São agentes com filtro `is_subagent=true`. Endpoints paralelos para conveniência da UI; backend pode reusar handlers de Agentes com flag fixa.

| Método | Path | Descrição |
|---|---|---|
| GET | `/api/subagents` | Lista filtrada |
| GET | `/api/subagents/{slug}` | Detalhe |
| GET | `/api/subagents/{slug}/used-by` | Agentes que invocam este |

---

## 4 · Skills

| Método | Path | Descrição |
|---|---|---|
| GET | `/api/skills` | Lista |
| POST | `/api/skills` | Criar |
| GET | `/api/skills/{slug}` | Detalhe |
| GET | `/api/skills/{slug}/used-by` | Agentes que usam |
| PATCH | `/api/skills/{id}` | Atualizar |
| DELETE | `/api/skills/{id}` | Soft-delete |

### `GET /api/skills` query params

| Param | Tipo |
|---|---|
| `q` | string |
| `tags` | csv |
| `page`, `limit`, `sort` | (padrão) |

---

## 5 · Execuções

| Método | Path | Descrição |
|---|---|---|
| GET | `/api/executions` | Lista (filtros) |
| POST | `/api/executions` | Disparar nova |
| GET | `/api/executions/{id}` | Detalhe + métricas |
| GET | `/api/executions/{id}/events` | Lista de eventos (REST, paginado — replay sem SSE) |
| POST | `/api/executions/{id}/abort` | Aborta execução em curso |
| GET | `/api/events/executions/{id}` | **SSE** stream live ou replay |

### `POST /api/executions` request

```json
{
  "agent_slug": "researcher-finza",
  "input": "Liste plataformas Finza com responsável",
  "cwd": "/workspace/Repasse",
  "model_override": null,
  "timeout_seconds": null
}
```

### `POST /api/executions` response (201)

```json
{
  "id": "uuid-...",
  "agent_id": "uuid-...",
  "agent_slug": "researcher-finza",
  "status": "running",
  "started_at": "2026-05-20T14:32:00Z",
  "input": "...",
  "cwd": "..."
}
```

### `GET /api/executions` query params

| Param | Tipo |
|---|---|
| `agent_slug` | string |
| `status` | csv enum |
| `from` | ISO datetime |
| `to` | ISO datetime |
| `page`, `limit`, `sort` | (padrão) |

### `POST /api/executions/{id}/abort` response

```json
{
  "id": "uuid-...",
  "status": "aborted",
  "ended_at": "2026-05-20T14:32:30Z"
}
```

### Status codes

| Status | Quando |
|---|---|
| 201 | Execução criada e iniciada |
| 200 | GET / abort OK |
| 409 | Tentativa de abort em execução já terminal |
| 422 | cwd inválido / agente inativo |
| 429 | Limite de concorrência atingido (`max_concurrent`) |
| 500 | Falha ao spawnar Claude Code |

---

## 6 · Análises

| Método | Path | Descrição |
|---|---|---|
| GET | `/api/analyses` | Lista |
| POST | `/api/analyses` | Criar |
| GET | `/api/analyses/{slug}` | Detalhe |
| PATCH | `/api/analyses/{id}` | Atualizar |
| DELETE | `/api/analyses/{id}` | Soft-delete (bloqueada se há relatórios) |
| POST | `/api/analyses/{id}/publish` | Transição → publicada |
| POST | `/api/analyses/{id}/executions` | Vincular execuções |
| DELETE | `/api/analyses/{id}/executions/{exec_id}` | Desvincular |

### `POST /api/analyses` request

```json
{
  "slug": "demandas-cobranca",
  "title": "Demandas cobrança time negócio",
  "kind": "investigacao",
  "question": "Qual a fila atual...",
  "body_md": "## Contexto\n...",
  "tags": ["cobranca","demandas"]
}
```

### `POST /api/analyses/{id}/executions` request

```json
{ "execution_ids": ["uuid-1","uuid-2"], "note": "Insumos da fase 1" }
```

### Status codes

| Status | Quando |
|---|---|
| 201/200 | OK |
| 409 | Tentativa de delete com relatórios vinculados (RN-23) |
| 422 | Execução não-concluída anexada (RN-22) |

---

## 7 · Relatórios

| Método | Path | Descrição |
|---|---|---|
| GET | `/api/reports` | Lista |
| POST | `/api/reports` | Criar |
| GET | `/api/reports/{slug}` | Detalhe |
| PATCH | `/api/reports/{id}` | Atualizar |
| PATCH | `/api/reports/{id}/status` | Mudar status (rascunho/revisao/enviado) |
| DELETE | `/api/reports/{id}` | Soft-delete (bloqueado se enviado — vira arquivar) |

### `POST /api/reports` request

```json
{
  "slug": "repasse-leonardo",
  "title": "Repasse semanal — Leonardo",
  "analysis_id": "uuid-...",
  "destinatario": "Leonardo (CTO)",
  "body_md": "...",
  "classificacao": "interno",
  "tags": ["repasse"]
}
```

### Status codes

| Status | Quando |
|---|---|
| 201/200 | OK |
| 404 | analysis_id não existe |
| 422 | Tentativa `enviado` com analysis não publicada (RN-25) |

---

## 8 · Export

| Método | Path | Descrição |
|---|---|---|
| POST | `/api/export/analyses/{slug}` | Exporta análise para `.md` |
| POST | `/api/export/reports/{slug}` | Exporta relatório para `.md` |

### Request

Sem body (export usa configuração default de `settings.export_path`).
Opcional: `{ "override_path": "..." }` para forçar destino diferente (V1+).

### Response (200)

```json
{
  "exported_path": "/workspace/Repasse/Gestao/Analises/18-05-2026/2026-05-19_demandas-cobranca.md",
  "exported_at": "2026-05-20T14:32:00Z",
  "bytes_written": 4231,
  "was_overwrite": false
}
```

### Status codes

| Status | Quando |
|---|---|
| 200 | OK |
| 500 | I/O erro no host |

---

## 9 · Settings

| Método | Path | Descrição |
|---|---|---|
| GET | `/api/settings` | Todas as settings |
| PATCH | `/api/settings` | Atualizar parcial |
| POST | `/api/settings/validate-workspace` | Testa path do workspace |

### `GET /api/settings` response

```json
{
  "workspace_path": "/workspace/Repasse",
  "export_path": "/workspace/Repasse/Gestao",
  "default_model": "sonnet",
  "max_concurrent": 3,
  "execution_timeout_seconds": 900,
  "pricing_table": {
    "opus": {"input": 15.0, "output": 75.0},
    "sonnet": {"input": 3.0, "output": 15.0},
    "haiku": {"input": 0.8, "output": 4.0}
  }
}
```

### `POST /api/settings/validate-workspace` response

```json
{
  "valid": true,
  "claude_code_version": "v0.5.2",
  "error": null
}
```

---

## 10 · Dashboard

| Método | Path | Descrição |
|---|---|---|
| GET | `/api/dashboard` | KPIs + dados agregados (combinado) |
| GET | `/api/dashboard/kpis` | Só KPIs |
| GET | `/api/dashboard/executions-by-day?days=30` | Sparkline data |

### `GET /api/dashboard` response

```json
{
  "kpis": {
    "agents_active": 12,
    "executions_this_month": 84,
    "cost_this_month_usd": 0.42,
    "analyses_published": 7,
    "reports_sent": 3
  },
  "recent_executions": [ /* até 5 execuções */ ],
  "executions_by_day": [
    { "date": "2026-05-01", "count": 3 },
    { "date": "2026-05-02", "count": 5 },
    ...
  ]
}
```

---

## 11 · Padrão de erros

Toda resposta de erro (4xx/5xx) tem o shape:

```json
{
  "error": {
    "code": "slug_already_exists",
    "message": "Já existe um item com este slug.",
    "field": "slug",
    "details": null,
    "request_id": "req-abc-123"
  }
}
```

| Campo | Descrição |
|---|---|
| `code` | Code canônico (snake_case). Lista em [REGRAS_DE_NEGOCIO §9](../03-dominio/REGRAS_DE_NEGOCIO.md) |
| `message` | Mensagem em PT-BR amigável |
| `field` | Campo do request que causou (se aplicável) |
| `details` | Estrutura extra (ex: lista de erros de validação) |
| `request_id` | Para correlação com logs do backend |

---

## 12 · Versionamento

- API v1 implícita (sem prefixo `/v1/` no MVP).
- Breaking changes futuras → `/api/v2/...` paralelo.
- Versão no header `X-API-Version: 1` (todas as respostas).

---

## 13 · OpenAPI

FastAPI gera automaticamente:
- `GET /openapi.json` — schema OpenAPI 3.x
- `GET /docs` — Swagger UI (dev only)
- `GET /redoc` — ReDoc (dev only)

Frontend consome via `openapi-typescript` para gerar tipos.
