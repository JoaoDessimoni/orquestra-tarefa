# Escopo MVP — OrquestrAI

> Definição de in-scope / out-of-scope do MVP (P0). Critérios de aceitação para considerar o MVP "entregue". Última atualização: 21/05/2026.

> **Atualização v2 (2026-05-21)**: módulos de **gestão** (Pendências, Reuniões, 1on1s, Roadmap, Commands read-only) foram **promovidos a MVP** após validação no protótipo `BOARD.html` v2. Antes ficavam como "legacy/V1". Justificativa: o supervisor IAF demanda essas funções tanto quanto agentes/análises — e o protótipo provou que o esforço de implementar CRUD genérico para todas é marginal (mesma camada de forms + localStorage no proto, mesma camada de tabelas + REST no produto). RFs novos em [REQUISITOS_FUNCIONAIS.md](REQUISITOS_FUNCIONAIS.md) §RF-PE, §RF-RU, §RF-OO, §RF-RM, §RF-CM.

## Fontes

- [BRIEFING.md](../BRIEFING.md)
- [PERSONAS.md](PERSONAS.md)
- Decisões travadas em conversa de design (20/05/2026)

---

## 1 · O que está dentro do MVP (in-scope)

### 1.1 Módulos funcionais

| Módulo | Descrição | Telas necessárias |
|---|---|---|
| **Dashboard** | Visão consolidada (KPIs, últimas execuções, atalhos) | 1 (Dashboard) |
| **Agentes** | CRUD de Agente; vínculo com Skills e Subagentes | Lista, Detalhe, Form |
| **Subagentes** | CRUD de Subagente (mesma natureza, marcado como invocável) | Lista, Detalhe, Form |
| **Skills** | CRUD de bloco de conhecimento markdown + tags | Lista, Detalhe, Editor |
| **Execuções** | Disparar agente; ver streaming em tempo real; consultar histórico | Lista, Detalhe (com stream) |
| **Análises** | CRUD; pode anexar execuções como insumo | Lista, Detalhe, Form |
| **Relatórios** | CRUD; derivados de análise; metadado de destinatário e classificação | Lista, Detalhe, Form |
| **Settings** | Path do workspace; modelo padrão; paths de export | 1 (Settings) |
| **Command Palette** | Cmd+K para navegação rápida + ações + busca fuzzy | Overlay global |

### 1.2 Capacidades técnicas

- Persistência em **Postgres 16** (Alembic migrations).
- Backend **FastAPI** com endpoints REST + 1 endpoint SSE para streaming.
- Frontend **Next.js 14** com App Router, TypeScript, Tailwind.
- Execução de agente via **subprocess do Claude Code CLI local**.
- **Streaming SSE** do output de execução do Claude Code para o browser.
- Export de Análise/Relatório para **`.md` em `Gestao/`** do workspace pai (compatível com workspace `.claude` existente).
- Tudo orquestrado por **`docker-compose`** (web, api, db).
- **Local-only** — bindings em `127.0.0.1`, nada exposto.

### 1.3 Capacidades de produto

- Criação de agente com prompt customizado, modelo (`opus`/`sonnet`/`haiku`), ferramentas habilitadas (Read, Edit, Write, Grep, Glob, Bash, WebSearch, WebFetch), skills vinculadas, subagentes vinculados.
- Execução manual de agente (botão "Executar") com input livre + cwd configurável.
- Tabela de execuções com filtros (agente, status, data, custo).
- Tela de detalhe de execução com timeline de eventos (token, tool call, tool result, error, done).
- Análise pode listar execuções vinculadas como "insumos".
- Relatório referencia exatamente 1 análise-fonte.

---

## 2 · O que está fora do MVP (out-of-scope)

| Item | Por quê fora | Roadmap |
|---|---|---|
| Multi-usuário, auth, RBAC | Single-user é decisão travada | V1 |
| Deploy fora do localhost | Local-only é decisão travada | V2 |
| Integração Quimera (pull/push) | Complexidade alta; depende API Quimera | V2 |
| Slack/e-mail (notificação ou export) | Não-crítico para fluxo solo | V1 |
| Compartilhamento de relatório por link público | Sem auth, sem servidor público | V1 |
| Agendamento (cron) de execuções | Decisão: trigger manual primeiro | V1 |
| Editor de prompt com syntax highlighting avançado | Textarea básico cobre MVP | V1 |
| Versionamento de prompt/agente (Git-like) | Histórico de execução cobre rastreio mínimo | V2 |
| Métricas agregadas (cost dashboard, latência por modelo) | Apenas KPIs simples no Dashboard | V1 |
| Importar agentes do `.claude/agents/` do workspace | Bootstrap manual no MVP | V1 |
| Sync bidirecional `Gestao/` ↔ DB | Decisão: DB é fonte; `Gestao/` é só export | Reavaliar V2 |
| Templates de Análise/Relatório | Free-form no MVP | V1 |
| Anexos (PDF, imagem) em Análise/Relatório | Texto markdown só | V1 |
| Mobile / responsive completo | Desktop-only | V2 |
| Internacionalização (i18n) | PT-BR fixo | V2 |

---

## 3 · Critérios de aceitação do MVP

O MVP é considerado **entregue** quando, em uma máquina nova, o usuário consegue:

| # | Cenário | Resultado esperado |
|---|---|---|
| AC-01 | Clonar repo + `docker-compose up` | Sobe web/api/db sem erro em <2 min |
| AC-02 | Acessar `http://localhost:3000` | Vê Dashboard com mocks ou dados reais |
| AC-03 | Criar um Agente "Researcher Finza" com prompt + modelo Sonnet + 3 ferramentas + 1 Skill | Agente aparece na lista, detalhe abre, pode ser editado |
| AC-04 | Executar o agente com input "qual o roadmap do Esperanza?" e cwd `/workspace/Repasse` | Stream começa em <2s; tokens aparecem em tempo real; tool calls visíveis |
| AC-05 | Após execução terminar | Aparece em Execuções com output completo, duração, status `done` |
| AC-06 | Criar Análise vinculada à execução acima | Análise lista a execução como insumo |
| AC-07 | Derivar Relatório com destinatário "Leonardo" e classificação "interno" | Relatório criado, aponta para a análise-fonte |
| AC-08 | Clicar em "Exportar para Gestao/" no Relatório | Arquivo `.md` criado em `Gestao/Analises/<dd-mm-aaaa>/Relatorio/` com frontmatter correto |
| AC-09 | Pressionar Cmd+K | Command palette abre, busca fuzzy funciona, navegação por teclado funciona |
| AC-10 | Reiniciar containers (`docker-compose restart`) | Dados persistem (volume nomeado) |

## 4 · Critérios de "não-entregue"

O MVP **não** é entregue se:

- Qualquer um dos AC-01..AC-10 falha.
- Stream de execução não funciona ou trava após N tokens.
- Subprocess do Claude Code não termina em caso de erro (orphan process).
- Dados são perdidos ao reiniciar containers.
- Setup leva >30 min em uma máquina já com Docker instalado.

## 5 · Tamanho estimado

| Componente | Estimativa (engenheiro sênior solo) |
|---|---|
| Backend (FastAPI + SQLAlchemy + Alembic + runner) | 5-7 dias |
| Frontend (Next.js + Tailwind + telas + Cmd+K + stream UI) | 7-10 dias |
| Infra (docker-compose, scripts, .env) | 1-2 dias |
| QA / refinamento | 3-5 dias |
| **Total** | **~3-4 semanas** |

<!-- TODO: validar estimativa com complexidade real do streaming SSE do Claude Code CLI -->
