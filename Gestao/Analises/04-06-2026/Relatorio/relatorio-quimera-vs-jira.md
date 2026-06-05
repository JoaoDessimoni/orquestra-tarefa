---
titulo: "Relatório — correção de datas Quimera × Jira (aplicação via MCP)"
data: 2026-06-04
autor: João Vinícius
tipo: relatorio / reconciliacao de dados
deriva_de: ../2026-06-04_correcao-datas-quimera-jira.md
destinatario: registro interno IAF + dev/DBA Quimera
status: APLICADO (Parte A) · PENDENTE (Parte B no banco)
---

# Relatório — correção de datas dos tickets migrados Jira → Quimera

## 1. O que foi ajustado

| | |
|---|---|
| **Campo ajustado via MCP** | `created_at` (data de criação) — **e somente ele** |
| **Ferramenta** | `mcp__quimera__update_ticket(id, created_at)` |
| **Tickets afetados** | **130** (escopo `fonte: quimera+jira`, QMR3287–QMR3436) |
| **Resultado** | 130/130 gravados sem erro em **2026-06-04** |
| **Fonte da verdade** | Jira legado, projeto **IAF** (`blips-dev.atlassian.net`), campo `fields.created` |
| **Efeitos colaterais** | nenhum — `status`, `resolved_at`, `status_changed_at`, `story_points`, `assigned_to` **intactos**; nenhuma notificação/e-mail disparado (edição de metadata) |

### Por que só `created_at`?
A migração Jira → Quimera via CSV (import em lote em **2026-05-20 ~15:09**) reescreveu o `created_at` de todos os tickets para o **timestamp do import**. O MCP `update_ticket` grava **apenas** `created_at`.

> **⚠️ VERIFICADO 2026-06-05 — `created_at` sozinho NÃO move o dashboard.**
> Os indicadores **Lead Time, Cycle Time e as datas de "surgiu/finalizou"** do dashboard **não leem `created_at`** — derivam **inteiramente** do histórico de status (`ticket_status_history`, eventos `new_status`/`changed_at`), todos carimbados na data do import. Confirmado: mesmo com `created_at` já em março, o `status_changed_at` dos finalizados segue `2026-05-20T15:09`, e o Cycle Time current_month seguiu ~3 d.ú. (sem mudança). A definição oficial do indicador (MCP) é explícita: *"summed across the whole status history up to the last move to 'finalizado'"*.
> **Conclusão:** a correção via MCP é necessária (deixa o campo `created_at` certo) mas **insuficiente para os dashboards**. O único caminho que move Lead/Cycle Time é a **Parte B (backfill de `ticket_status_history` no banco)** — não existe ferramenta MCP que escreva essa tabela (`change_ticket_status` só cria evento com data de AGORA). Ver §4.

### Verificação (amostra relida pós-escrita)
| Ticket | created_at gravado (UTC) | = local −04:00 | confere c/ Jira |
|---|---|---|---|
| QMR3287 / IAF-6 | `2026-03-06T23:27:40` | 06/03 19:27 | ✓ |
| QMR3338 / IAF-81 | `2025-11-14T18:50:23` | 14/11/**2025** 14:50 (outlier) | ✓ |
| QMR3372 | `2026-04-22T18:56:24` | 22/04 14:56 | ✓ |
| QMR3436 / IAF-207 | `2026-05-19T16:49:54` | 19/05 12:49 | ✓ |

**Antes (todos os 130):** timestamp do import em lote, `2026-05-20T15:09:xx` (confirmado por amostragem nos tickets 3288 e 3436 antes da escrita — os 130 não foram relidos individualmente pré-update). **Depois:** o valor real do Jira listado na tabela §2.

## 2. Demandas ajustadas (todas, por IAF-[número])

> `created_at (novo)` em horário local do Jira (−0400). `resolved` = data de conclusão real no Jira (`—` = não concluído lá; não há finalização a fazer). 130 linhas.

| Jira | Quimera | created_at (novo) | resolved | status Jira |
|---|---|---|---|---|
| IAF-6 | QMR3287 | 2026-03-06 19:27:40.506 -0400 | — | BLOQUEADO |
| IAF-12 | QMR3288 | 2026-03-18 08:33:48.852 -0400 | 2026-04-07 | Concluído |
| IAF-13 | QMR3289 | 2026-03-18 08:33:50.686 -0400 | 2026-04-07 | Concluído |
| IAF-14 | QMR3290 | 2026-03-18 08:33:52.396 -0400 | 2026-04-07 | Concluído |
| IAF-15 | QMR3291 | 2026-03-18 08:33:53.786 -0400 | 2026-05-07 | Concluído |
| IAF-16 | QMR3292 | 2026-03-18 08:33:56.701 -0400 | 2026-04-30 | Concluído |
| IAF-17 | QMR3293 | 2026-03-18 08:33:58.430 -0400 | — | Priorizado |
| IAF-18 | QMR3294 | 2026-03-18 08:33:59.739 -0400 | 2026-04-07 | Concluído |
| IAF-19 | QMR3295 | 2026-03-18 08:34:01.226 -0400 | — | EM ANDAMENTO |
| IAF-20 | QMR3296 | 2026-03-18 08:34:02.630 -0400 | 2026-04-07 | Concluído |
| IAF-22 | QMR3297 | 2026-03-18 08:34:06.010 -0400 | 2026-04-06 | Concluído |
| IAF-23 | QMR3298 | 2026-03-18 08:34:07.424 -0400 | 2026-05-08 | Concluído |
| IAF-24 | QMR3299 | 2026-03-18 08:34:09.545 -0400 | 2026-04-07 | Concluído |
| IAF-25 | QMR3300 | 2026-03-18 08:34:10.959 -0400 | 2026-04-07 | Concluído |
| IAF-26 | QMR3301 | 2026-03-18 08:34:12.352 -0400 | 2026-04-07 | Concluído |
| IAF-28 | QMR3302 | 2026-03-18 08:41:56.906 -0400 | 2026-04-14 | Concluído |
| IAF-29 | QMR3303 | 2026-03-18 08:41:59.004 -0400 | 2026-04-14 | Concluído |
| IAF-30 | QMR3304 | 2026-03-17 08:43:22.854 -0400 | — | BLOQUEADO |
| IAF-31 | QMR3305 | 2026-03-18 11:01:53.680 -0400 | 2026-04-02 | Concluído |
| IAF-36 | QMR3306 | 2026-03-19 08:07:00.158 -0400 | 2026-04-10 | Concluído |
| IAF-67 | QMR3327 | 2026-04-07 08:19:02.808 -0400 | — | EM DESENVOLVIMENTO |
| IAF-69 | QMR3328 | 2026-04-07 08:19:03.084 -0400 | — | EM DESENVOLVIMENTO |
| IAF-71 | QMR3329 | 2026-04-07 08:19:04.421 -0400 | 2026-04-08 | Concluído |
| IAF-72 | QMR3330 | 2026-04-07 08:19:04.708 -0400 | 2026-04-08 | Concluído |
| IAF-73 | QMR3331 | 2026-04-07 08:19:05.307 -0400 | 2026-04-15 | Concluído |
| IAF-74 | QMR3332 | 2026-04-07 08:19:05.376 -0400 | 2026-04-07 | Concluído |
| IAF-75 | QMR3333 | 2026-04-07 08:49:43.699 -0400 | 2026-04-10 | Concluído |
| IAF-76 | QMR3334 | 2026-04-07 08:51:11.365 -0400 | 2026-04-14 | Concluído |
| IAF-77 | QMR3335 | 2026-04-07 10:07:21.913 -0400 | — | Backlog |
| IAF-78 | QMR3336 | 2026-04-07 14:26:05.345 -0400 | 2026-05-15 | Concluído |
| IAF-79 | QMR3337 | 2026-04-07 14:34:32.287 -0400 | 2026-04-07 | Concluído |
| IAF-81 | QMR3338 | 2025-11-14 14:50:23.343 -0400 | — | BLOQUEADO |
| IAF-82 | QMR3339 | 2026-04-09 08:45:17.689 -0400 | 2026-04-30 | Concluído |
| IAF-83 | QMR3340 | 2026-04-09 09:00:18.399 -0400 | 2026-04-09 | Concluído |
| IAF-84 | QMR3341 | 2026-04-09 09:15:00.521 -0400 | 2026-04-13 | Concluído |
| IAF-85 | QMR3342 | 2026-04-09 09:15:50.368 -0400 | 2026-04-14 | Concluído |
| IAF-86 | QMR3343 | 2026-04-09 09:16:02.617 -0400 | 2026-04-13 | Concluído |
| IAF-89 | QMR3344 | 2026-04-09 13:16:02.257 -0400 | 2026-04-13 | Concluído |
| IAF-90 | QMR3345 | 2026-04-09 13:25:48.143 -0400 | 2026-04-13 | Concluído |
| IAF-91 | QMR3346 | 2026-04-09 13:26:18.930 -0400 | 2026-04-28 | Concluído |
| IAF-92 | QMR3347 | 2026-04-09 13:36:22.991 -0400 | 2026-04-10 | Concluído |
| IAF-93 | QMR3348 | 2026-04-09 16:22:13.856 -0400 | 2026-04-15 | Concluído |
| IAF-94 | QMR3349 | 2026-04-10 07:23:55.046 -0400 | 2026-04-16 | Concluído |
| IAF-95 | QMR3350 | 2026-04-10 08:54:12.474 -0400 | 2026-05-04 | Concluído |
| IAF-96 | QMR3351 | 2026-04-10 10:30:07.931 -0400 | 2026-05-15 | Concluído |
| IAF-97 | QMR3352 | 2026-04-13 08:33:39.034 -0400 | 2026-04-13 | Concluído |
| IAF-98 | QMR3353 | 2026-04-13 08:46:42.869 -0400 | 2026-04-15 | Concluído |
| IAF-99 | QMR3354 | 2026-04-13 09:12:49.747 -0400 | 2026-04-22 | Concluído |
| IAF-101 | QMR3355 | 2026-04-14 08:50:11.833 -0400 | 2026-04-17 | Concluído |
| IAF-102 | QMR3356 | 2026-04-14 08:50:56.657 -0400 | 2026-04-30 | Concluído |
| IAF-103 | QMR3357 | 2026-04-15 09:08:04.318 -0400 | — | VALIDAÇÃO |
| IAF-109 | QMR3358 | 2026-04-15 16:53:31.726 -0400 | — | VALIDAÇÃO |
| IAF-110 | QMR3359 | 2026-04-16 09:12:02.212 -0400 | 2026-04-27 | Concluído |
| IAF-111 | QMR3360 | 2026-04-16 14:49:03.432 -0400 | 2026-04-24 | Concluído |
| IAF-112 | QMR3361 | 2026-04-16 15:14:50.216 -0400 | 2026-04-17 | Concluído |
| IAF-113 | QMR3362 | 2026-04-16 15:45:37.301 -0400 | 2026-04-22 | Concluído |
| IAF-114 | QMR3363 | 2026-04-14 22:16:11.137 -0400 | 2026-04-22 | Concluído |
| IAF-115 | QMR3364 | 2026-04-17 14:17:11.068 -0400 | 2026-04-30 | Concluído |
| IAF-116 | QMR3365 | 2026-04-17 15:31:44.213 -0400 | 2026-04-17 | Concluído |
| IAF-117 | QMR3366 | 2026-04-20 07:35:48.939 -0400 | 2026-04-30 | Concluído |
| IAF-118 | QMR3367 | 2026-04-20 12:52:19.232 -0400 | — | BLOQUEADO |
| IAF-119 | QMR3368 | 2026-04-20 16:44:44.348 -0400 | 2026-04-22 | Concluído |
| IAF-120 | QMR3369 | 2026-04-22 09:35:16.534 -0400 | 2026-04-23 | Concluído |
| IAF-121 | QMR3370 | 2026-04-22 13:25:38.532 -0400 | 2026-05-11 | Concluído |
| IAF-122 | QMR3371 | 2026-04-22 14:56:24.104 -0400 | 2026-05-08 | Concluído |
| IAF-123 | QMR3372 | 2026-04-22 14:57:56.206 -0400 | — | VALIDAÇÃO |  (corrigido 2026-06-05: era IAF-122 por erro de mapa)
| IAF-125 | QMR3373 | 2026-04-22 16:19:52.916 -0400 | 2026-05-08 | Concluído |
| IAF-128 | QMR3374 | 2026-04-24 11:17:50.543 -0400 | 2026-04-28 | Concluído |
| IAF-129 | QMR3375 | 2026-04-24 13:25:00.603 -0400 | — | VALIDAÇÃO |
| IAF-130 | QMR3376 | 2026-04-27 08:15:39.499 -0400 | — | EM ANDAMENTO |
| IAF-131 | QMR3377 | 2026-04-27 08:16:08.557 -0400 | 2026-05-04 | Concluído |
| IAF-132 | QMR3378 | 2026-04-27 08:16:16.390 -0400 | — | Backlog |
| IAF-133 | QMR3379 | 2026-04-27 08:16:22.030 -0400 | 2026-05-04 | Concluído |
| IAF-134 | QMR3380 | 2026-04-27 08:16:32.302 -0400 | — | EM ANDAMENTO |
| IAF-136 | QMR3381 | 2026-04-27 08:16:47.317 -0400 | — | EM ANDAMENTO |
| IAF-137 | QMR3382 | 2026-04-27 08:16:54.825 -0400 | 2026-05-11 | Concluído |
| IAF-138 | QMR3383 | 2026-04-27 08:17:04.210 -0400 | — | Backlog |
| IAF-139 | QMR3384 | 2026-04-27 08:17:19.431 -0400 | — | Priorizado |
| IAF-140 | QMR3385 | 2026-04-27 08:17:46.011 -0400 | — | EM DESENVOLVIMENTO |
| IAF-145 | QMR3386 | 2026-04-27 11:10:18.659 -0400 | — | Backlog |
| IAF-146 | QMR3387 | 2026-04-27 11:10:24.400 -0400 | — | Backlog |
| IAF-147 | QMR3388 | 2026-04-27 11:10:30.668 -0400 | — | Backlog |
| IAF-148 | QMR3389 | 2026-04-27 11:10:36.700 -0400 | — | Backlog |
| IAF-149 | QMR3390 | 2026-04-27 11:10:43.718 -0400 | — | Backlog |
| IAF-150 | QMR3391 | 2026-04-27 11:10:50.087 -0400 | — | Backlog |
| IAF-151 | QMR3392 | 2026-04-27 11:10:56.446 -0400 | — | Backlog |
| IAF-152 | QMR3393 | 2026-04-27 11:11:02.862 -0400 | — | Backlog |
| IAF-153 | QMR3394 | 2026-04-27 11:11:10.413 -0400 | — | Backlog |
| IAF-154 | QMR3395 | 2026-04-27 11:11:18.099 -0400 | — | Backlog |
| IAF-155 | QMR3396 | 2026-04-27 11:11:44.025 -0400 | — | Backlog |
| IAF-156 | QMR3397 | 2026-04-27 11:11:51.628 -0400 | — | Backlog |
| IAF-157 | QMR3398 | 2026-04-27 11:11:58.411 -0400 | — | Backlog |
| IAF-158 | QMR3399 | 2026-04-27 11:12:06.351 -0400 | — | Backlog |
| IAF-159 | QMR3400 | 2026-04-27 11:12:14.762 -0400 | — | Backlog |
| IAF-160 | QMR3401 | 2026-04-27 11:12:21.761 -0400 | — | Backlog |
| IAF-161 | QMR3402 | 2026-04-27 11:12:28.210 -0400 | — | Backlog |
| IAF-162 | QMR3403 | 2026-04-27 11:12:47.783 -0400 | — | Tarefas pendentes |
| IAF-163 | QMR3404 | 2026-04-27 11:12:53.571 -0400 | — | Tarefas pendentes |
| IAF-164 | QMR3405 | 2026-04-27 11:13:04.254 -0400 | — | Tarefas pendentes |
| IAF-165 | QMR3406 | 2026-04-27 11:13:10.231 -0400 | — | Tarefas pendentes |
| IAF-166 | QMR3407 | 2026-04-27 11:13:15.805 -0400 | — | Tarefas pendentes |
| IAF-167 | QMR3408 | 2026-04-27 11:13:21.456 -0400 | — | Tarefas pendentes |
| IAF-168 | QMR3409 | 2026-04-27 12:23:57.268 -0400 | — | VALIDAÇÃO |
| IAF-169 | QMR3410 | 2026-04-27 12:24:45.954 -0400 | — | EM ANDAMENTO |
| IAF-171 | QMR3411 | 2026-04-29 16:16:31.685 -0400 | — | VALIDAÇÃO |
| IAF-172 | QMR3412 | 2026-04-30 12:37:10.636 -0400 | 2026-05-11 | Concluído |
| IAF-173 | QMR3413 | 2026-04-30 12:56:45.386 -0400 | 2026-05-11 | Concluído |
| IAF-174 | QMR3414 | 2026-04-30 12:58:17.160 -0400 | 2026-05-11 | Concluído |
| IAF-176 | QMR3415 | 2026-05-07 12:59:10.835 -0400 | — | EM ANDAMENTO |
| IAF-177 | QMR3416 | 2026-05-08 10:52:33.986 -0400 | 2026-05-08 | Concluído |
| IAF-178 | QMR3417 | 2026-05-08 12:47:32.844 -0400 | 2026-05-11 | Concluído |
| IAF-181 | QMR3418 | 2026-05-08 15:46:47.802 -0400 | — | Backlog |
| IAF-182 | QMR3419 | 2026-05-11 08:58:27.247 -0400 | — | VALIDAÇÃO |
| IAF-183 | QMR3420 | 2026-05-11 09:23:55.522 -0400 | 2026-05-13 | Concluído |
| IAF-184 | QMR3421 | 2026-05-11 10:26:23.490 -0400 | — | EM ANDAMENTO |
| IAF-185 | QMR3422 | 2026-05-11 10:48:27.696 -0400 | 2026-05-13 | Concluído |
| IAF-186 | QMR3423 | 2026-05-11 10:55:16.602 -0400 | — | EM ANDAMENTO |
| IAF-187 | QMR3424 | 2026-05-11 11:04:53.048 -0400 | — | Backlog |
| IAF-188 | QMR3425 | 2026-05-11 11:09:30.206 -0400 | — | Priorizado |
| IAF-189 | QMR3426 | 2026-05-11 13:02:21.247 -0400 | — | Backlog |
| IAF-192 | QMR3427 | 2026-05-12 14:15:46.419 -0400 | 2026-05-13 | Concluído |
| IAF-194 | QMR3428 | 2026-05-12 14:17:34.151 -0400 | 2026-05-13 | Concluído |
| IAF-196 | QMR3429 | 2026-05-14 12:34:52.408 -0400 | 2026-05-14 | Concluído |
| IAF-198 | QMR3430 | 2026-05-14 12:40:05.938 -0400 | — | Backlog |
| IAF-200 | QMR3431 | 2026-05-14 15:47:14.074 -0400 | — | Backlog |
| IAF-203 | QMR3432 | 2026-05-18 15:48:41.809 -0400 | 2026-05-19 | Concluído |
| IAF-204 | QMR3433 | 2026-05-18 16:33:44.129 -0400 | — | VALIDAÇÃO |
| IAF-205 | QMR3434 | 2026-05-18 16:37:22.193 -0400 | — | Backlog |
| IAF-206 | QMR3435 | 2026-05-19 09:10:45.147 -0400 | 2026-05-19 | Concluído |
| IAF-207 | QMR3436 | 2026-05-19 12:49:54.859 -0400 | — | EM ANDAMENTO |

## 3. Caveats descobertos na aplicação

1. **QMR3372 é IAF-123, não IAF-122 — CORRIGIDO 2026-06-05.** O ticket 3372 é `[IAF-123] [Bitrix ID-1791]` (Bitrix 1791), gêmeo de IAF-122 (Bitrix 1789). Tinha recebido o `created_at` de IAF-122 (14:56:24). Regravado com o valor real de IAF-123 (`2026-04-22 14:57:56.206 -0400`) via MCP. Obs.: IAF-123 está em VALIDAÇÃO no Jira (sem `resolutiondate`) — o resolved que constava (08/05) era de IAF-122 e não se aplica. Ação restante: corrigir o mapa `fonte: quimera+jira` no `.md` de origem para 3372 → IAF-123.

2. **`created_at` antes não foi capturado por ticket.** O "antes" (timestamp do import `2026-05-20T15:09:xx`) foi confirmado por amostragem (3288, 3436) e não lido nos 130 individualmente antes de sobrescrever. Para o objetivo (restaurar a data real) isso é irrelevante; registra-se a limitação por transparência.

## 4. O que ainda falta — e por quê

### 4.0 ✅ Backfill de histórico REAL gerado (2026-06-05) — `2026-06-05_backfill-status-history-quimera.sql`
Após o changelog do Jira ser extraído (130 issues, **369 eventos de status reais**), foi gerado o SQL que **realmente conserta os dashboards**: reconstrói `ticket_status_history` a partir das transições reais (DELETE do histórico bogus do import + INSERT das transições do Jira) e sincroniza `status` / `status_changed_at` / `resolved_at`. Captura inclusive reaberturas (ex.: IAF-177 fechou 08/05, reabriu, refechou 12/05 → Cycle Time conta os dois ciclos). **Este arquivo substitui a Parte B abaixo** (faz tudo, de forma fiel). Premissa única documentada: 1º evento = `backlog` (status de criação não-contável). Default `ROLLBACK`; trocar por `COMMIT` após validar. **Rodar no banco.**

### 4.1 Parte B — finalização / Cycle Time (substituída pela 4.0)
- **72 tickets** têm data de conclusão real no Jira (`resolved`). O Cycle/Lead Time do Quimera deriva do histórico `ticket_status_history`, que **não é gravável por MCP**.
- A correção exige o SQL em **`Relatorio/2026-06-04_backfill-datas-quimera.sql`** (staging com os 130 + 2 variantes de schema p/ o DBA escolher). Default seguro = `ROLLBACK`; trocar por `COMMIT` após validar.
- **Responsável:** dev/DBA do Quimera (o usuário roda a partir de 2026-06-05).
- Os **58 tickets sem `resolved`** ainda não foram concluídos no Jira → não há finalização a fazer backfill; só o `created_at` (já aplicado) os afeta.

### 4.2 Verificação `get_gestao_overview` — bloqueada pós-correção
- **Antes (current_month / junho, capturado 2026-06-04):** Conclusão 36,61% (41/112) · Cycle médio 3,13 dias úteis (mediana 1,91 · p90 10) · Touch 1,49 · Wait 1,64 · Intruders 7,14% (8/112) · CSAT 4,96.
- **Depois (last_month / last_quarter):** **falhou** — com os 130 tickets agora distribuídos em mar–mai, a sub-query de Cycle Time monta um `IN(...)` de centenas de `ticket_id` em `ticket_status_history` que **estoura o limite de URL/HTTP2** do endpoint Supabase (`stream error / unspecific protocol error`). `current_month` (junho) segue funcionando.
- **Diagnóstico:** limitação do endpoint do Quimera (precisa paginar/chunkar o `IN`), exposta pelo aumento de volume na janela após a correção. **Não é regressão dos dados** — é o relatório que não consegue mais montar a query. **Reportar ao time do Quimera.** A verificação "depois" dos KPIs só será possível após (a) o fix do endpoint e (b) a Parte B (que recompõe o histórico do qual o Cycle Time depende).

## 5. Resumo executivo

| Item | Situação |
|---|---|
| `created_at` dos 130 tickets | ✅ corrigido (real do Jira), persistido — inclui QMR3372→IAF-123 (06/05) |
| Efeitos colaterais | ✅ nenhum (só metadata) |
| **Dashboard Lead/Cycle Time + datas exibidas** | ❌ **NÃO mudou e não muda via MCP** — lê `ticket_status_history`, que o MCP não escreve |
| **Único caminho de correção do dashboard** | ✅ SQL pronto — `2026-06-05_backfill-status-history-quimera.sql` (rodar no banco) |
| Cycle Time *fiel* (com reaberturas) | ✅ incluído no SQL — 369 eventos reais do changelog do Jira |
| 58 tickets sem conclusão | ✅ nada além do `created_at` a fazer |
| `get_gestao_overview` last_month/quarter | ⚠️ endpoint quebra no `IN` grande — reportar ao Quimera |
| Mapa 3372 → IAF-123 no `.md` de origem | ⚠️ corrigir (valor no Quimera já certo) |
