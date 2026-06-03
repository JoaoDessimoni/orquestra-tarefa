---
id: QMR3365
title: Otimizações e correções de segurança em Campanhas/Repique/Broadcast — 17/04
frente: bitrix-automacoes
status: entregue
prioridade: media
fonte: quimera+jira
quimera: 3365
jira: IAF-116
categoria: Crédito
deliverable_type: Outros
story_points: 5
tipo_origem: Tarefa
responsavel: Marcos Rodrigues
criada: 2026-04-17
concluida: 2026-04-16
prazo: null
prazo_estimado: False
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: []
bloqueia: []
tags: [fonte-quimera-jira, cat-credito]
---

# QMR3365 — Otimizações e correções de segurança em Campanhas/Repique/Broadcast — 17/04

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3365 · Jira IAF-116 · categoria: Crédito

# Resumo do dia — 2026-04-17

Foram 6 commits + 1 migration + 1 deploy de Edge Function. Todos commits assinados por `marocosz`.

---

## 1. `feat(repique)` — Mover Repique para Campanhas + backend otimizado (`08a5e41`, 12:11)

**O que foi feito:**

* **Frontend:** movida aba Repique de `/dashboard` para `/campaigns` (ao lado de Monitoramento). Unificados os hooks `useRepiqueActions` + `useRepiqueStats` em um único `useRepiqueDashboard` (1 call só). Paginação no backend (50 rows/página). Reuso do `DashboardFiltersBar` para filtro de período.
* **Backend:** criada RPC `public.get_repique_dashboard_json` (agregação + paginação em SQL único) + EF `get-repique-dashboard` + índice parcial `idx_actions_repique` nos schemas `org_*`.
* **Migration:** `20260417100000_repique_dashboard_backend.sql` aplicada em produção.

**Por que:**

* Stats (total/enviados/falhas/campanhas) antes eram calculados em cima de só 500 rows → **KPIs errados** em alto volume. Agora rodam sobre o dataset completo.
* Query antiga fazia seq-scan na tabela `actions` → índice parcial transforma em index scan.
* Repique é funcionalmente uma campanha, então pertence à área de Campanhas na UI.

**Segurança:**

* Zero funções preexistentes reescritas (grep confirmou nomes novos).
* NÃO tocou em `on_organization_created` (trigger crítico com histórico de 17 rewrites).
* `CREATE INDEX IF NOT EXISTS` → idempotente.
* DROP da RPC antiga deixada para migration de cleanup posterior (só após frontend confirmado em prod).

---

## 2. `fix(repique)` — Auth + membership check em `get-repique-dashboard` (`d982ba1`, 14:15)

**O que foi feito:**

* Adicionado `Authorization: Bearer` obrigatório na EF.
* Validação de JWT via `ANON_KEY` client (`getUser`).
* Checagem de membership em `public.organization_users` usando **userClient (RLS)**, não service_role.
* Só depois de validar, usa SERVICE_ROLE para chamar a RPC interna.
* Removido `x-org-slug` do CORS.
* 401/403 retornam `{"error":"unauthorized"}` genérico.

**Por que:**

* Falha de segurança: a EF aceitava POST com `org_slug` e usava `SERVICE_ROLE` sem validar JWT nem membership → **qualquer usuário autenticado poderia ler o dashboard de qualquer org** passando o slug.

**Segurança:**

* Fail-closed: sem match de membership → 403 sem vazar se a org existe.
* Resposta de erro genérica (não diferencia 401 de 403 em detalhes).
* Preservado regex de validação de schema name e CORS canônicos.

---

## 3. `fix(campaigns)` — Preservar chaves de settings no save do dialog (`330a057`, 15:27)

**O que foi feito:**

* `CampaignDialog` agora faz spread de `campaign.settings` antes de aplicar `repique_enabled`, preservando todas as chaves existentes.
* Adicionada interface `CampaignSettings` tipando chaves conhecidas (frontend + triggers) com index signature.

**Por que:**

* Bug: ao salvar uma campanha pelo dialog, o JSONB `settings` inteiro era sobrescrito, **apagando chaves plantadas por triggers** (ex: `paused_reason` do `workflow_deactivation_cascade`). Antes do fix, sobrava só `repique_enabled`.

**Segurança / Impacto:**

* Teste manual: campanha com `paused_*` plantados mantém as 4 chaves após save.
* Sem mudança de schema nem de backend.

---

## 4. `docs` — Consolidar CLAUDE.md em CLAUDE.local.md (`811bae4`, 15:27)

**O que foi feito:**

* Merge do conteúdo único de `CLAUDE.md` (comandos, arquitetura não óbvia, regras de segurança de RPC) em `CLAUDE.local.md`.
* Remoção do `CLAUDE.md`.

**Por que:**

* Os dois arquivos estavam divergindo, causando risco de instruções contraditórias.

**Segurança:**

* Apenas docs, sem impacto em código.

---

## 5. `fix(migrations)` — Timestamp inválido 20260416300000 → 20260417000000 (`f87088f`, 15:56)

**O que foi feito:**

* Renomeação do arquivo de migration (timestamp 30h é formato inválido `YYYYMMDDHHMMSS`).
* Rename já aplicado via `migration repair` nos dois bancos (main e dev) para manter histórico consistente.

**Por que:**

* Supabase CLI poderia rejeitar futuras migrations por causa de ordem não monotônica/formato inválido.

**Segurança:**

* Zero mudança de conteúdo SQL (só rename).
* Repair aplicado em ambos os bancos → sem divergência entre main/dev.

---

## 6. `fix(broadcast)` — Batchear `.in()` para respeitar limite PostgREST \~8KB (`fbe3cb9`, 16:22)

**O que foi feito:**

* Introduzido helper `batchedIn<T>()` com batch de 150 UUIDs (\~5.4KB por call) em `broadcast-processor`.
* Aplicado nas 3 queries vulneráveis: actions dedup, contracts fetch, `vw_titles_live` enrich.
* **Fail-closed** em erro de batch (throw).
* Sort global DESC aplicado após batching do `vw_titles_live` (intra-batch DESC não bastava — um contato pode ter contratos em batches diferentes).
* Remoção de guards redundantes (`batchedIn` garante `T[]`, nunca null).

**Por que:**

* Queries com `.in(col, array)` sem batching viram URL >8KB quando ultrapassam \~200 UUIDs → **HTTP 414 ou truncamento silencioso** pelo PostgREST.
* Bug introduzido em `aaf74b2` e `99d381e`.

**Segurança:**

* Fail-closed alinhado com filosofia do commit `99d381e` (melhor erro do que mensagem errada/duplicada).
* Pattern já validado em `getContactsAlreadyContactedToday` (commit `4ba8338`).
* Sem mudança de schema, RPCs, ou outras EFs.

## Rastreabilidade

- **Responsável:** Marcos Rodrigues
- **Quimera:** #3365 (status fonte mapeado → `entregue`)
- **Jira:** IAF-116 (projeto IAF)
- **Categoria fonte:** Crédito
- **Criada:** 2026-04-17
- **Concluída:** 2026-04-16

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.