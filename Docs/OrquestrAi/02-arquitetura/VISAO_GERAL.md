# Visão Geral da Arquitetura — OrquestrAI

> Diagrama de blocos + fluxos principais + decisões arquiteturais. Última atualização: 20/05/2026.

## Fontes

- [BRIEFING.md](../BRIEFING.md)
- [ESCOPO_MVP.md](../01-requisitos/ESCOPO_MVP.md)
- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md)

---

## 1 · Diagrama de blocos

```
┌─────────────────────────────────────────────────────────────────────┐
│                          MÁQUINA LOCAL DO USUÁRIO                   │
│                                                                     │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                       docker-compose                        │   │
│   │                                                             │   │
│   │  ┌─────────────────────┐         ┌────────────────────┐    │   │
│   │  │     web (Next.js)   │         │   api (FastAPI)    │    │   │
│   │  │     :3000           │◀──REST─▶│   :8000            │    │   │
│   │  │                     │         │                    │    │   │
│   │  │   Pages:            │◀──SSE───│  Endpoints:        │    │   │
│   │  │   - Dashboard       │         │  /api/agents       │    │   │
│   │  │   - Agentes         │         │  /api/skills       │    │   │
│   │  │   - Subagentes      │         │  /api/executions   │    │   │
│   │  │   - Skills          │         │  /api/analyses     │    │   │
│   │  │   - Execuções       │         │  /api/reports      │    │   │
│   │  │   - Análises        │         │  /api/export       │    │   │
│   │  │   - Relatórios      │         │  /events/exec/{id} │    │   │
│   │  │   - Settings        │         │       (SSE)        │    │   │
│   │  │   - Cmd+K palette   │         │                    │    │   │
│   │  └─────────────────────┘         │  Runner:           │    │   │
│   │                                  │  ClaudeCodeRunner  │    │   │
│   │                                  │  (asyncio)         │    │   │
│   │                                  └────────┬───────────┘    │   │
│   │                                           │ SQL            │   │
│   │                                           ▼                │   │
│   │                                  ┌────────────────────┐    │   │
│   │                                  │   db (Postgres)    │    │   │
│   │                                  │   :5432            │    │   │
│   │                                  │   Volume nomeado   │    │   │
│   │                                  │   (persistente)    │    │   │
│   │                                  └────────────────────┘    │   │
│   │                                                             │   │
│   │     Volume bind: ../Repasse  →  /workspace/Repasse         │   │
│   └────────────────────────┬────────────────────────────────────┘   │
│                            │ subprocess.Popen                       │
│                            ▼                                        │
│                   ┌─────────────────────────┐                       │
│                   │  claude code (CLI host) │                       │
│                   │  (instalado fora do     │                       │
│                   │   container, na máquina │                       │
│                   │   do usuário)           │                       │
│                   └─────────────────────────┘                       │
└─────────────────────────────────────────────────────────────────────┘
```

> **Importante:** o Claude Code CLI roda **na máquina host**, não dentro do container `api`. O container `api` precisa invocar o binário do host. Estratégia detalhada em [EXECUCAO_DE_AGENTES.md](EXECUCAO_DE_AGENTES.md) §2.

---

## 2 · Camadas e responsabilidades

### 2.1 Frontend (web)

- **Stack**: Next.js 14 App Router + TypeScript + Tailwind + zustand (state local) + tanstack-query (server state) + fuse.js (busca no Cmd+K).
- **Responsabilidades**: renderização das views, formulários, navegação, command palette, consumo SSE para streaming.
- **NÃO faz**: acesso a filesystem do host, invocação direta de Claude Code, SQL.

### 2.2 Backend (api)

- **Stack**: FastAPI + SQLAlchemy 2 (async) + Alembic + asyncpg + pydantic-v2 + uvicorn.
- **Responsabilidades**:
  - CRUD de todas as entidades.
  - Validação (regras de negócio — ver [REGRAS_DE_NEGOCIO.md](../03-dominio/REGRAS_DE_NEGOCIO.md)).
  - Execução de agentes (módulo `runner`).
  - Streaming SSE.
  - Export `.md` para `Gestao/`.
  - Health/version endpoints.

### 2.3 Banco (db)

- **Stack**: Postgres 16, volume nomeado `pgdata`.
- **Responsabilidades**: persistência relacional + buscas indexadas (GIN em tags, btree em FKs).
- **NÃO faz**: lógica de aplicação (sem stored procedures pesadas; só triggers de `updated_at`).

### 2.4 Claude Code CLI (no host)

- **Stack**: Claude Code (versão do usuário, já instalada).
- **Responsabilidades**: executar o agente com prompt+input+tools, escrever output em stdout, reportar tool calls.
- **Invocação**: subprocess gerenciado pelo runner do backend.

---

## 3 · Fluxos principais

### 3.1 Fluxo: criar e executar agente

```
[Usuário] ──POST /api/agents──▶ [api]
                                   ├─▶ Valida slug, prompt, tools
                                   ├─▶ INSERT agents
                                   └─▶ 201 + Agent JSON
                                          │
                                          ▼
[Usuário] ──navega para /agents/X──▶ [web]
                                          │
                                          ▼
[Usuário] ──clica "Executar"──▶ [web]
   ├─ Form: input + cwd (default workspace)
   │
   ▼
[web] ──POST /api/executions──▶ [api]
                                   ├─▶ Valida cwd, limites
                                   ├─▶ Snapshot do agente (prompt+model+tools+skills resolvidas)
                                   ├─▶ INSERT executions (status=running)
                                   ├─▶ Spawn subprocess Claude Code (async)
                                   └─▶ 201 + execution_id
                                          │
                                          ▼
[web] ──EventSource /api/events/executions/{id}──▶ [api]
                                   │
                                   ├─◀── stream: token → token → tool_call → tool_result → ... → done
                                   ├─▶ Persiste cada evento em execution_events
                                   └─▶ Encerra stream + UPDATE executions (status=done, output, métricas)
                                          │
                                          ▼
[web] mostra status final + output + métricas
```

### 3.2 Fluxo: derivar relatório de análise + exportar

```
[Análise existente em status=publicada]
        │
        ▼
[Usuário] ──na tela Análise, clica "+ Relatório"──▶ [web]
   ├─ Form: título, destinatário, classificação
   │
   ▼
[web] ──POST /api/reports──▶ [api]
                                ├─▶ Valida analysis_id existe e está publicada
                                ├─▶ INSERT reports (status=rascunho)
                                └─▶ 201 + Report JSON
                                          │
                                          ▼
[Usuário] edita body_md no editor markdown
        │
        ▼
[Usuário] muda status para "enviado" → [api] valida análise publicada
        │
        ▼
[Usuário] clica "Exportar para Gestao/"
        │
        ▼
[web] ──POST /api/export/reports/{id}──▶ [api]
                                ├─▶ Calcula path destino (RN-28)
                                ├─▶ Cria dir se não existe
                                ├─▶ Gera frontmatter + body
                                ├─▶ Escreve .md (não-sobrescrita conforme RN-29)
                                └─▶ 200 + exported_path
```

### 3.3 Fluxo: command palette

```
[Usuário] ──Cmd+K──▶ [web]
                       │
                       ▼
   Overlay abre, foco no input
                       │
                       ▼
   Usuário digita "exec ag"
                       │
                       ▼
   fuse.js filtra index em memória (agentes + ações + views)
                       │
                       ▼
   Mostra: "▶ Executar Agente: Researcher Finza"
           "▶ Executar Agente: Drafter"
           "→ Ir para Execuções"
                       │
                       ▼
   Enter no primeiro → navega para /executions/new?agent=researcher-finza
```

---

## 4 · Decisões arquiteturais

| # | Decisão | Justificativa | Trade-off aceito |
|---|---|---|---|
| AD-01 | Monorepo com `apps/web` e `apps/api` | Single-user, deploy local, sem versionamento separado | Build coupling |
| AD-02 | Postgres (não SQLite) | Tipos JSONB, full-text search, índices GIN, base sólida pra V1 multi-user | Setup mais pesado |
| AD-03 | SSE (não WebSocket) | Unidirecional server→client é tudo que precisamos; mais simples; sem reconnect manual | Sem upload via mesmo canal |
| AD-04 | Subprocess Claude Code CLI (não SDK Python) | Reusa a licença/instalação do usuário; sem custo Anthropic direto pelo backend | Acoplamento ao binário; spec mais complexa |
| AD-05 | docker-compose (não Kubernetes/Podman) | Já no toolset do dev; suficiente pra local | Não testado em outros runtimes |
| AD-06 | Single-user sem auth | Reduz escopo MVP em 30% | Multi-user só com refactor |
| AD-07 | Tailwind (não CSS-in-JS) | Class-based, alinhado com paradigma Linear/Notion-like, baixo overhead | Verbose nas classes |
| AD-08 | tanstack-query (não SWR) | Mutations + invalidations explícitas; melhor pra CRUD pesado | Bundle maior |
| AD-09 | Soft delete (não hard) | Preserva histórico de execuções com FK estáveis | Queries precisam filtrar |
| AD-10 | Snapshot de agente em execução | Reprodutibilidade auditável; permite editar agente sem quebrar histórico | Storage extra |

---

## 5 · O que NÃO está na arquitetura (out-of-scope MVP)

- **Worker assíncrono** (Celery/RQ): execuções rodam in-process do FastAPI (asyncio + asyncio.create_subprocess_exec). V1+ pode separar.
- **Cache (Redis)**: dados locais, baixa cardinalidade — overhead não compensa.
- **Reverse proxy (nginx)**: localhost only, sem TLS.
- **Logs centralizados (ELK/Loki)**: stdout do container basta.
- **APM (Sentry/Datadog)**: telemetria local em arquivo se necessário.
- **CDN / static optimization**: Next.js dev mode local, build em V1.

Tudo isso pode entrar V1+ se justificado. Spec de roadmap em [08-roadmap/FASES.md](../08-roadmap/FASES.md).
