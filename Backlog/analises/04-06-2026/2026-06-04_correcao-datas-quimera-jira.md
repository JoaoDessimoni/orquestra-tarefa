---
titulo: "Correção de datas de criação — tickets migrados Jira → Quimera"
data: 2026-06-04
autor: João Vinícius
tipo: reconciliacao-de-dados
status: APLICADO — 130 created_at gravados (MCP, 2026-06-04). Parte B (histórico) pendente no banco.
tags: [quimera, jira, kpi, cycle-time, backfill, correcao-dados]
---

# Correção de datas — migração Jira → Quimera

## Problema

Import em lote via CSV (2026-05-20 ~15:09) resetou `created_at` de todos os 130 tickets para o timestamp do import, quebrando KPIs: Lead Time, Cycle Time, Conclusão, Intruders. O Jira preserva as datas reais.

## Escopo

- **130 tickets** com `fonte: quimera+jira` (QMR3287–QMR3436)
- 129 Jira keys distintas — IAF-122 mapeia 2 tickets (QMR3371 e QMR3372; ⚠️ QMR3372 é IAF-123, não IAF-122 — corrigido 2026-06-05)

## Resultado (Parte A — MCP, 2026-06-04)

- **130/130** `created_at` gravados com valores reais do Jira via `update_ticket`. Nenhum erro.
- Efeitos colaterais: nulos (`resolved_at`, `status_changed_at`, campos todos intactos; nenhuma notificação/e-mail).
- Amostra verificada: QMR3287→`2026-03-06`, QMR3338→`2025-11-14` (outlier nov/2025 ✓), QMR3372→`2026-04-22`, QMR3436→`2026-05-19`.

## Limitação importante

`update_ticket` grava **só `created_at`**. Lead/Cycle Time derivam do `ticket_status_history` — **não são gravados pelo MCP**. Confirmado em 2026-06-05: mesmo com `created_at` corrigido, dashboards não mudaram (Cycle Time current_month seguiu ~3 d.ú.). Correção real dos dashboards exige Parte B.

## Parte B — backfill de histórico (banco, pendente)

**Script:** `Backlog/referencias/sql/2026-06-05_backfill-status-history-quimera.sql`

- 369 eventos de status reais do Jira (changelog extraído).
- Estratégia: DELETE histórico bogus do import + INSERT transições reais + UPDATE `status`/`status_changed_at`/`resolved_at`.
- Captura reaberturas (ex: IAF-177 fechou 08/05, reabriu, fechou 12/05 → Cycle Time conta os dois ciclos).
- Premissa: 1º evento = `backlog` (não-contável Cycle Time).
- **Default ROLLBACK — trocar por COMMIT após validar os SELECTs.**
- **Responsável:** dev/DBA do Quimera.

## Caveats pós-aplicação

1. **QMR3372 é IAF-123, não IAF-122.** `created_at` corrigido com valor de IAF-123 (`2026-04-22 14:57:56 -0400`) em 2026-06-05. O `.md` de origem deve corrigir o mapa `fonte: quimera+jira` para 3372→IAF-123.

2. **`get_gestao_overview` last_month/last_quarter quebrado.** Com 130 tickets distribuídos em mar–mai, a sub-query de Cycle Time monta um `IN(...)` que estoura limite URL/HTTP2 do endpoint Supabase. `current_month` (junho) funciona. Reportar ao time do Quimera para paginar/chunkar o `IN`.

## Dados de referência

- Tabela de reconciliação completa (130 tickets × 20 colunas): `Backlog/referencias/csv/2026-06-04_dados-correcao-datas-quimera-jira.csv`
- Eventos de status (369 linhas): `Backlog/referencias/csv/2026-06-05_eventos-reconstruidos.csv`
- Changelog raw do Jira (6 lotes JSON): `Backlog/referencias/json/quimera-jira-changelog/`
- Relatório de aplicação: `relatorios/2026-06-04_relatorio-quimera-vs-jira.md`
