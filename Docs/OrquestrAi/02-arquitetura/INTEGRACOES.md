# Integrações — OrquestrAI

> Pontos de contato com sistemas externos. MVP é estreito (só `Gestao/`). Última atualização: 20/05/2026.

## Fontes

- [BRIEFING.md](../BRIEFING.md)
- [REGRAS_DE_NEGOCIO.md](../03-dominio/REGRAS_DE_NEGOCIO.md) §6 (export)
- `CLAUDE.md` do workspace pai (convenções de `Gestao/`)

---

## 1 · Integrações no MVP

### 1.1 `Gestao/` (workspace pai) — export `.md`

**Tipo**: outbound, manual (trigger por botão).
**Direção**: OrquestrAI escreve `.md` em `Gestao/`. Não lê.

#### Path destinos

| Entidade | Path |
|---|---|
| Análise | `<export_path>/Analises/<dd-mm-aaaa-published_at>/<YYYY-MM-DD>_<slug>.md` |
| Relatório | `<export_path>/Analises/<dd-mm-aaaa-fonte>/Relatorio/<YYYY-MM-DD>_<slug>.md` |

`<export_path>` vem de `settings.export_path` (default `/workspace/Repasse/Gestao`).
`<dd-mm-aaaa-published_at>` = data de publicação da Análise no formato `dd-mm-aaaa`.

#### Frontmatter gerado — Análise

```yaml
---
title: <title>
data: <YYYY-MM-DD>
autor: João Vinícius
tipo: <kind>
fontes-consultadas:
  - <slug da execução 1>
  - <slug da execução 2>
relacionadas: []
status: <status>
tags: <tags>
---
<!-- gerado-por: orquestr-ai versão X.Y.Z em 2026-05-20T14:32:00Z -->
```

#### Frontmatter gerado — Relatório

```yaml
---
title: <title>
data: <YYYY-MM-DD>
destinatario: <destinatario>
analise-fonte: <slug da análise>
owner: João Vinícius
status: <status>
classificacao: <classificacao>
tags: <tags>
---
<!-- gerado-por: orquestr-ai versão X.Y.Z em 2026-05-20T14:32:00Z -->
```

#### Corpo

Markdown bruto do campo `body_md`, sem transformação.

#### Estratégia de não-sobrescrita

1. Se arquivo no path destino **não existe** → escreve direto.
2. Se existe e contém `<!-- gerado-por: orquestr-ai -->` → sobrescreve.
3. Se existe e **não** contém esse marker → sufixar slug com `_2`, `_3`, ...

Garantia: arquivos criados manualmente em `Gestao/` (por `/analise` do `.claude/commands/`) nunca são sobrescritos.

#### Atualização do `BOARD.html`

Após export bem-sucedido, o `board-updater` (`.claude/agents/board-updater.md`) deveria, idealmente, re-scanear `Gestao/` e atualizar o JSON inline do `BOARD.html`. **No MVP isso é manual** — usuário roda `/atualizar-board` no Claude Code.

V1+: OrquestrAI pode chamar o board-updater via subprocess local após export.

---

### 1.2 Filesystem do host (volume bind)

**Tipo**: inbound + outbound, runtime.
**Direção**: OrquestrAI (container `api`) lê `.claude/agents`, `.claude/skills`, `.claude/commands` em modo somente leitura; escreve em `Gestao/`.

#### Volumes Docker

```yaml
volumes:
  - ../Repasse:/workspace/Repasse:ro             # leitura geral
  - ../Repasse/Gestao:/workspace/Repasse/Gestao  # exception: rw para export
```

Cuidado: o segundo bind sobrescreve a permissão do primeiro especificamente para `Gestao/`.

#### Segurança

- `cwd` de execução de agente sempre dentro de `/workspace/Repasse` (RN-13).
- Path traversal bloqueada (RN-32).
- Sem acesso a outros paths do host.

---

### 1.3 Claude Code CLI

Coberto em [EXECUCAO_DE_AGENTES.md](EXECUCAO_DE_AGENTES.md). Resumo: subprocess gerenciado pelo `api`.

---

## 2 · Integrações fora do MVP (roadmap)

### 2.1 Quimera (V2)

**Tipo**: bidirecional, API REST.
**Objetivo**:
- **Inbound**: importar issues do Quimera como contexto adicional em Análises (anexar issue ID, puxar título/descrição/status).
- **Outbound**: criar issues no Quimera a partir de pendências geradas em análises.

**Bloqueadores atuais**:
- Não temos especificação da API Quimera nesta documentação.
- Precisamos definir mapeamento `Análise ↔ Issue Quimera` (1:1? N:1?).

<!-- TODO: solicitar acesso à API Quimera e levantar spec V2 -->

### 2.2 Slack (V1)

**Tipo**: outbound, webhook.
**Objetivo**: notificar canal de gestão quando um Relatório vai para status `enviado`.

**Componentes**:
- Webhook URL configurável em Settings.
- Template de mensagem com link para Relatório (não-público, então só metadados).

### 2.3 E-mail (V1)

**Tipo**: outbound, SMTP.
**Objetivo**: enviar Relatório por e-mail para destinatário automaticamente.

**Componentes**:
- SMTP config em Settings (host, port, user, pass, from).
- Anexo do `.md` exportado (ou renderizado HTML).

### 2.4 Importação inicial de `Gestao/` (V1)

**Tipo**: inbound, one-shot.
**Objetivo**: popular DB com Análises e Relatórios existentes em `Gestao/Analises/` no bootstrap.

**Processo**:
- Comando CLI `python -m orquestr_ai.import_gestao`.
- Lê todos `.md`, parseia frontmatter, INSERT no DB.
- Slug = nome do arquivo sem extensão.
- Conflito de slug → sufixa com `_imported_N`.

### 2.5 Importação de agentes do `.claude/agents/` (V1)

**Tipo**: inbound, one-shot por agente.
**Objetivo**: aproveitar os 8 agentes já documentados em `.claude/agents/`.

**Processo**:
- Lê arquivo `<slug>.md`, parseia frontmatter (description, tools, model).
- Mapeia para schema OrquestrAI:
  - `description` → `agents.description`
  - `model` → `agents.model`
  - `tools` (CSV string) → `agents.tools` (JSONB array)
  - corpo → `agents.system_prompt`
- Slug do arquivo = `agents.slug`.

---

## 3 · Pontos de integração internos (não-externos, mas vale documentar)

### 3.1 Frontend ↔ Backend

- REST via `fetch` com tipos gerados de OpenAPI.
- SSE via `EventSource`.
- CORS: backend permite só `http://localhost:3000` em dev.

### 3.2 Backend ↔ Postgres

- SQLAlchemy 2 async + asyncpg.
- Pool de conexões: 10 (config).
- Migrations Alembic rodam no entrypoint do container `api` antes do uvicorn subir.

### 3.3 OpenAPI generation

- FastAPI gera `openapi.json` em `/openapi.json`.
- Frontend roda `npx openapi-typescript http://localhost:8000/openapi.json -o lib/api/types.gen.ts` para regenerar tipos.
- Comando integrado a um script `npm run gen:api`.

---

## 4 · Anti-integrações (explicitamente NÃO)

| Sistema | Por quê não |
|---|---|
| Anthropic API direta | Claude Code CLI já a usa; duplicaria custo + complexidade |
| OAuth (Google/GitHub) | Single-user; sem necessidade de identidade externa |
| Sentry / Datadog | Local-only; sem rede pública; logs em stdout bastam |
| GitHub API | Workspace é local; sem necessidade de sync com remote |
| LDAP/AD | Sem auth corporativa |
| OpenAI / outros LLMs | Foco em Claude Code CLI; trocar provider rompe modelo |

V1+ pode reconsiderar item-a-item se justificado.
