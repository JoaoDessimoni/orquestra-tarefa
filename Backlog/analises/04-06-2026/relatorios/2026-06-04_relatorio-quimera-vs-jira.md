---
titulo: "Relatório — correção de datas Quimera × Jira (aplicação via MCP)"
data: 2026-06-04
autor: João Vinícius
tipo: relatorio
deriva_de: Backlog/analises/04-06-2026/2026-06-04_correcao-datas-quimera-jira.md
destinatario: registro interno IAF + dev/DBA Quimera
status: APLICADO (Parte A) · PENDENTE (Parte B no banco)
tags: [quimera, jira, backfill, kpi, cycle-time]
---

# Relatório — Correção de Datas Quimera × Jira

## 1. O que foi feito

| Item | Detalhe |
|---|---|
| **Campo ajustado** | `created_at` via `mcp__quimera__update_ticket(id, created_at)` |
| **Tickets** | 130 (QMR3287–QMR3436, `fonte: quimera+jira`) |
| **Resultado** | 130/130 gravados sem erro em **2026-06-04** |
| **Efeitos colaterais** | Nenhum — `status`, `resolved_at`, `status_changed_at`, `story_points`, `assigned_to` intactos; sem notificação/e-mail |
| **Fonte da verdade** | Jira `blips-dev.atlassian.net`, projeto IAF, campo `fields.created` |

## 2. Por que `created_at` não move o dashboard

> **⚠️ Confirmado 2026-06-05:** Lead/Cycle Time **não leem `created_at`** — derivam do `ticket_status_history`. Mesmo com `created_at` corrigido, Cycle Time current_month seguiu ~3 d.ú. O único caminho é a Parte B (backfill do histórico no banco).

## 3. Verificação (amostra pós-escrita)

| Ticket | created_at gravado (UTC) | Local −04:00 | Confere c/ Jira |
|---|---|---|---|
| QMR3287 / IAF-6 | 2026-03-06T23:27:40 | 06/03 19:27 | ✓ |
| QMR3338 / IAF-81 | 2025-11-14T18:50:23 | 14/11/2025 14:50 (outlier) | ✓ |
| QMR3372 / IAF-123 | 2026-04-22T18:57:56 | 22/04 14:57 (corrigido 06/05) | ✓ |
| QMR3436 / IAF-207 | 2026-05-19T16:49:54 | 19/05 12:49 | ✓ |

## 4. Caveats

1. **QMR3372 era mapeado como IAF-122 — corrigido para IAF-123 (2026-06-05).** `created_at` regravado com valor real de IAF-123. Ação pendente: corrigir campo `fonte` no `.md` de origem.

2. **`get_gestao_overview` last_month/last_quarter falha.** Com 130 tickets distribuídos em mar–mai, sub-query de Cycle Time monta `IN(...)` grande que estoura limite do endpoint Supabase. `current_month` (junho) funciona. Reportar ao time do Quimera. Verificação "depois" dos KPIs só será possível após (a) fix do endpoint e (b) Parte B.

## 5. O que ainda falta — Parte B

**Script:** `Backlog/referencias/sql/2026-06-05_backfill-status-history-quimera.sql`

Reconstrói `ticket_status_history` completo (130 tickets, 369 eventos). Substitui a abordagem da Parte A+B do script 04-06 (faz tudo, de forma fiel, incluindo reaberturas). **Default ROLLBACK — trocar por COMMIT após validar.** Owner: dev/DBA do Quimera.

## 6. Resumo executivo

| Item | Situação |
|---|---|
| `created_at` dos 130 tickets | ✅ corrigido (valor real do Jira), incluindo QMR3372→IAF-123 |
| Efeitos colaterais | ✅ nenhum |
| Dashboard Lead/Cycle Time | ❌ não mudou — lê `ticket_status_history`, não `created_at` |
| Correção dos dashboards | ✅ SQL pronto — rodar no banco |
| 58 tickets sem conclusão | ✅ nada além do `created_at` a fazer |
| `get_gestao_overview` last_month/quarter | ⚠️ endpoint quebra no `IN` grande — reportar ao Quimera |
| Mapa 3372→IAF-123 no `.md` de origem | ⚠️ corrigir (Quimera já certo) |
