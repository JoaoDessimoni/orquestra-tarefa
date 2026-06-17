-- =============================================================================
-- BACKFILL DE HISTÓRICO DE STATUS — tickets IAF migrados do Jira -> Quimera
-- Gerado: 2026-06-05 | Autor: João Vinícius (Supervisor IAF) via Claude Code
-- Fonte: CHANGELOG do Jira (projeto IAF, blips-dev.atlassian.net) — histórico real de status.
-- =============================================================================
--
-- POR QUE ESTE SCRIPT EXISTE
-- --------------------------
-- O import em lote (2026-05-20) carimbou TODO o ticket_status_history na data do import.
-- Os indicadores do Quimera (Lead Time, Cycle Time, datas de "surgiu/finalizou") leem
-- ESTA tabela — não o tickets.created_at (já corrigido via MCP). Logo, só o backfill
-- abaixo move os dashboards. Reconstrói o histórico real a partir do changelog do Jira.
--
-- Cobertura: 130 tickets, 369 eventos de status reconstruídos.
--
-- >>> SCHEMA (confirmar nomes/colunas obrigatórias antes de rodar) <<<
--   tickets(id uuid PK, ticket_number int, status text, status_changed_at timestamptz,
--           resolved_at timestamptz, created_at timestamptz)
--   ticket_status_history(ticket_id uuid FK->tickets.id, new_status text, changed_at timestamptz, ...)
--   ^ Nomes confirmados via endpoint Gestão. Se a tabela tiver colunas NOT NULL extras
--     (id PK, old_status, author/changed_by, etc.), AJUSTE os INSERTs abaixo.
--
-- >>> PREMISSA ÚNICA (status inicial) <<<
--   O 1º evento de cada ticket com transições é assumido 'backlog' (status de criação no
--   fluxo Jira — não-contável p/ Cycle Time). Issues SEM transição recebem 1 evento no
--   status atual. Métricas (Lead/Cycle) são robustas a isso: nenhuma issue foi criada
--   diretamente em em_andamento/bloqueado/em_validacao neste workflow.
--
-- COMO USAR: backup das 2 tabelas -> rodar em transação -> conferir SELECTs -> trocar
--   ROLLBACK por COMMIT. Mapeamento de status Jira->Quimera aplicado:
--     Backlog|To Do|Tarefas pendentes -> backlog ; Priorizado -> fila_exec
--     EM ANDAMENTO|EM DESENVOLVIMENTO  -> em_andamento ; BLOQUEADO -> bloqueado
--     VALIDAÇÃO -> em_validacao ; Done|Concluído -> finalizado ; Cancelado -> cancelado
-- =============================================================================

BEGIN;

-- STAGING: eventos reais (ticket_number, seq cronológico, status Quimera, timestamp ISO)
CREATE TEMP TABLE _iaf_status_events (
  ticket_number integer,
  seq           integer,
  new_status    text,
  changed_at    timestamptz,
  PRIMARY KEY (ticket_number, seq)
) ON COMMIT DROP;

INSERT INTO _iaf_status_events (ticket_number, seq, new_status, changed_at) VALUES
  (3287,  1, 'backlog', '2026-03-06T19:27:40.506-04:00'),
  (3287,  2, 'fila_exec', '2026-04-17T06:56:51.402-04:00'),
  (3287,  3, 'em_andamento', '2026-04-20T12:55:09.199-04:00'),
  (3287,  4, 'bloqueado', '2026-04-20T14:21:34.978-04:00'),
  (3287,  5, 'em_andamento', '2026-04-24T08:37:45.049-04:00'),
  (3287,  6, 'bloqueado', '2026-05-11T10:45:31.329-04:00'),
  (3288,  1, 'backlog', '2026-03-18T08:33:48.852-04:00'),
  (3288,  2, 'bloqueado', '2026-03-18T08:34:16.569-04:00'),
  (3288,  3, 'finalizado', '2026-04-07T08:50:19.576-04:00'),
  (3289,  1, 'backlog', '2026-03-18T08:33:50.686-04:00'),
  (3289,  2, 'em_andamento', '2026-03-18T08:34:17.610-04:00'),
  (3289,  3, 'finalizado', '2026-04-07T08:48:05.914-04:00'),
  (3290,  1, 'backlog', '2026-03-18T08:33:52.396-04:00'),
  (3290,  2, 'em_andamento', '2026-03-18T08:34:19.106-04:00'),
  (3290,  3, 'finalizado', '2026-04-07T08:47:45.730-04:00'),
  (3291,  1, 'backlog', '2026-03-18T08:33:53.786-04:00'),
  (3291,  2, 'em_validacao', '2026-03-18T08:34:20.173-04:00'),
  (3291,  3, 'finalizado', '2026-05-07T16:22:26.867-04:00'),
  (3292,  1, 'backlog', '2026-03-18T08:33:56.701-04:00'),
  (3292,  2, 'em_validacao', '2026-03-18T08:34:21.264-04:00'),
  (3292,  3, 'finalizado', '2026-04-30T12:54:33.884-04:00'),
  (3293,  1, 'backlog', '2026-03-18T08:33:58.430-04:00'),
  (3293,  2, 'fila_exec', '2026-03-18T08:34:23.020-04:00'),
  (3294,  1, 'backlog', '2026-03-18T08:33:59.739-04:00'),
  (3294,  2, 'fila_exec', '2026-03-18T08:34:24.117-04:00'),
  (3294,  3, 'finalizado', '2026-04-07T08:48:50.133-04:00'),
  (3295,  1, 'backlog', '2026-03-18T08:34:01.226-04:00'),
  (3295,  2, 'em_andamento', '2026-03-18T08:34:25.224-04:00'),
  (3296,  1, 'backlog', '2026-03-18T08:34:02.630-04:00'),
  (3296,  2, 'em_validacao', '2026-03-18T08:34:26.839-04:00'),
  (3296,  3, 'finalizado', '2026-04-07T08:47:56.844-04:00'),
  (3297,  1, 'backlog', '2026-03-18T08:34:06.010-04:00'),
  (3297,  2, 'cancelado', '2026-04-06T08:28:15.835-04:00'),
  (3297,  3, 'finalizado', '2026-04-06T08:28:20.221-04:00'),
  (3298,  1, 'backlog', '2026-03-18T08:34:07.424-04:00'),
  (3298,  2, 'fila_exec', '2026-03-18T08:34:29.504-04:00'),
  (3298,  3, 'finalizado', '2026-05-08T13:03:56.645-04:00'),
  (3299,  1, 'backlog', '2026-03-18T08:34:09.545-04:00'),
  (3299,  2, 'fila_exec', '2026-03-18T08:34:30.622-04:00'),
  (3299,  3, 'finalizado', '2026-04-07T08:49:10.973-04:00'),
  (3300,  1, 'backlog', '2026-03-18T08:34:10.959-04:00'),
  (3300,  2, 'em_validacao', '2026-03-18T08:34:31.881-04:00'),
  (3300,  3, 'finalizado', '2026-04-07T08:47:59.059-04:00'),
  (3301,  1, 'backlog', '2026-03-18T08:34:12.352-04:00'),
  (3301,  2, 'em_andamento', '2026-03-18T08:34:33.393-04:00'),
  (3301,  3, 'finalizado', '2026-04-07T08:48:09.104-04:00'),
  (3302,  1, 'backlog', '2026-03-18T08:41:56.906-04:00'),
  (3302,  2, 'em_andamento', '2026-04-14T08:52:27.847-04:00'),
  (3302,  3, 'finalizado', '2026-04-14T08:52:30.159-04:00'),
  (3303,  1, 'backlog', '2026-03-18T08:41:59.004-04:00'),
  (3303,  2, 'em_andamento', '2026-04-14T08:51:45.503-04:00'),
  (3303,  3, 'finalizado', '2026-04-14T08:51:57.445-04:00'),
  (3304,  1, 'backlog', '2026-03-17T08:43:22.854-04:00'),
  (3304,  2, 'em_andamento', '2026-03-17T08:43:23.391-04:00'),
  (3304,  3, 'bloqueado', '2026-04-29T16:00:06.759-04:00'),
  (3305,  1, 'backlog', '2026-03-18T11:01:53.680-04:00'),
  (3305,  2, 'em_andamento', '2026-03-18T11:01:54.321-04:00'),
  (3305,  3, 'em_validacao', '2026-03-23T13:36:33.999-04:00'),
  (3305,  4, 'finalizado', '2026-04-02T14:53:46.078-04:00'),
  (3306,  1, 'backlog', '2026-03-19T08:07:00.158-04:00'),
  (3306,  2, 'em_andamento', '2026-03-19T08:07:00.894-04:00'),
  (3306,  3, 'finalizado', '2026-04-10T08:50:24.974-04:00'),
  (3327,  1, 'backlog', '2026-04-07T08:19:02.808-04:00'),
  (3327,  2, 'em_andamento', '2026-05-11T08:43:36.588-04:00'),
  (3328,  1, 'backlog', '2026-04-07T08:19:03.084-04:00'),
  (3328,  2, 'em_andamento', '2026-04-08T12:57:50.123-04:00'),
  (3329,  1, 'backlog', '2026-04-07T08:19:04.421-04:00'),
  (3329,  2, 'em_andamento', '2026-04-07T14:29:13.307-04:00'),
  (3329,  3, 'finalizado', '2026-04-08T12:57:31.006-04:00'),
  (3330,  1, 'backlog', '2026-04-07T08:19:04.708-04:00'),
  (3330,  2, 'em_andamento', '2026-04-08T18:43:30.682-04:00'),
  (3330,  3, 'finalizado', '2026-04-08T23:24:44.142-04:00'),
  (3331,  1, 'backlog', '2026-04-07T08:19:05.307-04:00'),
  (3331,  2, 'em_andamento', '2026-04-13T08:45:43.581-04:00'),
  (3331,  3, 'finalizado', '2026-04-15T08:56:20.360-04:00'),
  (3332,  1, 'backlog', '2026-04-07T08:19:05.376-04:00'),
  (3332,  2, 'em_andamento', '2026-04-07T12:54:27.131-04:00'),
  (3332,  3, 'backlog', '2026-04-07T12:54:30.263-04:00'),
  (3332,  4, 'em_andamento', '2026-04-07T14:29:25.917-04:00'),
  (3332,  5, 'finalizado', '2026-04-07T18:43:31.262-04:00'),
  (3333,  1, 'backlog', '2026-04-07T08:49:43.699-04:00'),
  (3333,  2, 'em_andamento', '2026-04-07T08:49:44.256-04:00'),
  (3333,  3, 'fila_exec', '2026-04-07T14:32:34.138-04:00'),
  (3333,  4, 'em_andamento', '2026-04-09T09:00:43.483-04:00'),
  (3333,  5, 'finalizado', '2026-04-10T18:13:10.662-04:00'),
  (3334,  1, 'backlog', '2026-04-07T08:51:11.365-04:00'),
  (3334,  2, 'em_validacao', '2026-04-07T08:51:11.999-04:00'),
  (3334,  3, 'finalizado', '2026-04-14T08:52:45.653-04:00'),
  (3335,  1, 'backlog', '2026-04-07T10:07:21.913-04:00'),
  (3335,  2, 'em_andamento', '2026-04-13T14:42:42.662-04:00'),
  (3335,  3, 'backlog', '2026-04-13T14:42:50.067-04:00'),
  (3335,  4, 'em_andamento', '2026-04-15T08:51:21.260-04:00'),
  (3335,  5, 'backlog', '2026-04-15T16:45:39.905-04:00'),
  (3335,  6, 'em_andamento', '2026-04-15T16:45:41.954-04:00'),
  (3335,  7, 'backlog', '2026-04-20T07:35:31.924-04:00'),
  (3336,  1, 'backlog', '2026-04-07T14:26:05.345-04:00'),
  (3336,  2, 'bloqueado', '2026-04-28T13:01:42.526-04:00'),
  (3336,  3, 'finalizado', '2026-05-15T09:43:41.209-04:00'),
  (3337,  1, 'backlog', '2026-04-07T14:34:32.287-04:00'),
  (3337,  2, 'finalizado', '2026-04-07T14:34:32.914-04:00'),
  (3337,  3, 'em_andamento', '2026-04-07T14:35:20.398-04:00'),
  (3337,  4, 'finalizado', '2026-04-07T14:35:30.166-04:00'),
  (3338,  1, 'backlog', '2025-11-14T14:50:23.343-04:00'),
  (3338,  2, 'em_andamento', '2026-02-19T08:32:23.779-04:00'),
  (3338,  3, 'fila_exec', '2026-03-03T08:39:20.463-04:00'),
  (3338,  4, 'backlog', '2026-04-08T16:28:46.654-04:00'),
  (3338,  5, 'bloqueado', '2026-04-15T12:58:28.216-04:00'),
  (3339,  1, 'backlog', '2026-04-09T08:45:17.689-04:00'),
  (3339,  2, 'fila_exec', '2026-04-09T08:45:21.817-04:00'),
  (3339,  3, 'finalizado', '2026-04-30T12:54:15.766-04:00'),
  (3340,  1, 'backlog', '2026-04-09T09:00:18.399-04:00'),
  (3340,  2, 'em_andamento', '2026-04-09T09:00:44.638-04:00'),
  (3340,  3, 'finalizado', '2026-04-09T15:59:36.131-04:00'),
  (3341,  1, 'backlog', '2026-04-09T09:15:00.521-04:00'),
  (3341,  2, 'em_andamento', '2026-04-13T08:33:55.841-04:00'),
  (3341,  3, 'finalizado', '2026-04-13T08:33:58.028-04:00'),
  (3342,  1, 'backlog', '2026-04-09T09:15:50.368-04:00'),
  (3342,  2, 'em_andamento', '2026-04-13T08:34:13.340-04:00'),
  (3342,  3, 'finalizado', '2026-04-14T08:49:49.549-04:00'),
  (3343,  1, 'backlog', '2026-04-09T09:16:02.617-04:00'),
  (3343,  2, 'em_andamento', '2026-04-13T08:34:05.203-04:00'),
  (3343,  3, 'finalizado', '2026-04-13T08:34:07.034-04:00'),
  (3344,  1, 'backlog', '2026-04-09T13:16:02.257-04:00'),
  (3344,  2, 'em_andamento', '2026-04-09T13:19:58.063-04:00'),
  (3344,  3, 'finalizado', '2026-04-13T08:27:49.759-04:00'),
  (3345,  1, 'backlog', '2026-04-09T13:25:48.143-04:00'),
  (3345,  2, 'em_andamento', '2026-04-09T13:25:57.818-04:00'),
  (3345,  3, 'finalizado', '2026-04-13T08:27:57.451-04:00'),
  (3346,  1, 'backlog', '2026-04-09T13:26:18.930-04:00'),
  (3346,  2, 'em_andamento', '2026-04-09T13:26:26.219-04:00'),
  (3346,  3, 'finalizado', '2026-04-28T10:57:33.232-04:00'),
  (3347,  1, 'backlog', '2026-04-09T13:36:22.991-04:00'),
  (3347,  2, 'fila_exec', '2026-04-10T08:37:16.755-04:00'),
  (3347,  3, 'finalizado', '2026-04-10T14:18:40.045-04:00'),
  (3348,  1, 'backlog', '2026-04-09T16:22:13.856-04:00'),
  (3348,  2, 'em_andamento', '2026-04-13T08:37:37.730-04:00'),
  (3348,  3, 'em_validacao', '2026-04-13T13:52:30.705-04:00'),
  (3348,  4, 'finalizado', '2026-04-15T13:17:20.342-04:00'),
  (3349,  1, 'backlog', '2026-04-10T07:23:55.046-04:00'),
  (3349,  2, 'em_andamento', '2026-04-15T13:13:08.237-04:00'),
  (3349,  3, 'finalizado', '2026-04-16T09:16:08.011-04:00'),
  (3349,  4, 'em_validacao', '2026-04-16T10:17:37.617-04:00'),
  (3349,  5, 'finalizado', '2026-04-16T13:14:00.274-04:00'),
  (3350,  1, 'backlog', '2026-04-10T08:54:12.474-04:00'),
  (3350,  2, 'em_andamento', '2026-04-10T08:54:28.821-04:00'),
  (3350,  3, 'finalizado', '2026-05-04T09:43:32.923-04:00'),
  (3351,  1, 'backlog', '2026-04-10T10:30:07.931-04:00'),
  (3351,  2, 'bloqueado', '2026-04-28T13:02:23.548-04:00'),
  (3351,  3, 'finalizado', '2026-05-15T09:43:39.459-04:00'),
  (3352,  1, 'backlog', '2026-04-13T08:33:39.034-04:00'),
  (3352,  2, 'em_andamento', '2026-04-13T08:34:09.128-04:00'),
  (3352,  3, 'finalizado', '2026-04-13T08:34:11.663-04:00'),
  (3353,  1, 'backlog', '2026-04-13T08:46:42.869-04:00'),
  (3353,  2, 'em_andamento', '2026-04-13T10:29:38.747-04:00'),
  (3353,  3, 'em_validacao', '2026-04-13T13:58:24.628-04:00'),
  (3353,  4, 'finalizado', '2026-04-15T08:56:59.711-04:00'),
  (3354,  1, 'backlog', '2026-04-13T09:12:49.747-04:00'),
  (3354,  2, 'em_andamento', '2026-04-13T13:48:47.139-04:00'),
  (3354,  3, 'em_validacao', '2026-04-15T08:51:05.338-04:00'),
  (3354,  4, 'finalizado', '2026-04-22T08:41:52.128-04:00'),
  (3355,  1, 'backlog', '2026-04-14T08:50:11.833-04:00'),
  (3355,  2, 'em_andamento', '2026-04-14T08:51:07.399-04:00'),
  (3355,  3, 'finalizado', '2026-04-17T08:18:35.896-04:00'),
  (3356,  1, 'backlog', '2026-04-14T08:50:56.657-04:00'),
  (3356,  2, 'em_andamento', '2026-04-30T12:34:40.438-04:00'),
  (3356,  3, 'finalizado', '2026-04-30T12:34:46.740-04:00'),
  (3357,  1, 'backlog', '2026-04-15T09:08:04.318-04:00'),
  (3357,  2, 'fila_exec', '2026-05-11T12:59:01.751-04:00'),
  (3357,  3, 'em_andamento', '2026-05-13T13:01:49.902-04:00'),
  (3357,  4, 'em_validacao', '2026-05-19T11:52:57.124-04:00'),
  (3358,  1, 'backlog', '2026-04-15T16:53:31.726-04:00'),
  (3358,  2, 'em_andamento', '2026-05-06T19:24:16.096-04:00'),
  (3358,  3, 'em_validacao', '2026-05-07T12:04:27.349-04:00'),
  (3359,  1, 'backlog', '2026-04-16T09:12:02.212-04:00'),
  (3359,  2, 'em_andamento', '2026-04-16T13:14:11.257-04:00'),
  (3359,  3, 'backlog', '2026-04-16T13:14:12.535-04:00'),
  (3359,  4, 'em_andamento', '2026-04-22T08:50:35.922-04:00'),
  (3359,  5, 'em_validacao', '2026-04-24T13:39:30.449-04:00'),
  (3359,  6, 'finalizado', '2026-04-27T15:44:18.846-04:00'),
  (3360,  1, 'backlog', '2026-04-16T14:49:03.432-04:00'),
  (3360,  2, 'em_validacao', '2026-04-16T14:49:04.070-04:00'),
  (3360,  3, 'finalizado', '2026-04-24T10:19:21.107-04:00'),
  (3361,  1, 'backlog', '2026-04-16T15:14:50.216-04:00'),
  (3361,  2, 'finalizado', '2026-04-17T08:18:19.228-04:00'),
  (3362,  1, 'backlog', '2026-04-16T15:45:37.301-04:00'),
  (3362,  2, 'em_andamento', '2026-04-16T15:45:40.297-04:00'),
  (3362,  3, 'em_validacao', '2026-04-20T07:35:26.200-04:00'),
  (3362,  4, 'finalizado', '2026-04-22T08:42:58.487-04:00'),
  (3363,  1, 'backlog', '2026-04-14T22:16:11.137-04:00'),
  (3363,  2, 'em_andamento', '2026-04-14T22:16:15.703-04:00'),
  (3363,  3, 'em_validacao', '2026-04-15T15:25:24.558-04:00'),
  (3363,  4, 'finalizado', '2026-04-22T08:41:02.724-04:00'),
  (3364,  1, 'backlog', '2026-04-17T14:17:11.068-04:00'),
  (3364,  2, 'em_andamento', '2026-04-20T12:54:37.646-04:00'),
  (3364,  3, 'em_validacao', '2026-04-20T14:21:44.493-04:00'),
  (3364,  4, 'bloqueado', '2026-04-22T08:43:51.839-04:00'),
  (3364,  5, 'finalizado', '2026-04-30T12:57:03.450-04:00'),
  (3365,  1, 'backlog', '2026-04-17T15:31:44.213-04:00'),
  (3365,  2, 'em_andamento', '2026-04-17T15:32:23.990-04:00'),
  (3365,  3, 'finalizado', '2026-04-17T15:39:48.265-04:00'),
  (3366,  1, 'backlog', '2026-04-20T07:35:48.939-04:00'),
  (3366,  2, 'em_andamento', '2026-04-20T07:35:52.127-04:00'),
  (3366,  3, 'em_validacao', '2026-04-23T13:48:56.232-04:00'),
  (3366,  4, 'finalizado', '2026-04-30T12:59:57.842-04:00'),
  (3367,  1, 'backlog', '2026-04-20T12:52:19.232-04:00'),
  (3367,  2, 'bloqueado', '2026-05-13T16:56:17.729-04:00'),
  (3368,  1, 'backlog', '2026-04-20T16:44:44.348-04:00'),
  (3368,  2, 'em_andamento', '2026-04-22T15:28:11.672-04:00'),
  (3368,  3, 'finalizado', '2026-04-22T20:53:40.910-04:00'),
  (3369,  1, 'backlog', '2026-04-22T09:35:16.534-04:00'),
  (3369,  2, 'em_andamento', '2026-04-23T08:39:20.278-04:00'),
  (3369,  3, 'finalizado', '2026-04-23T21:04:22.181-04:00'),
  (3370,  1, 'backlog', '2026-04-22T13:25:38.532-04:00'),
  (3370,  2, 'em_andamento', '2026-04-22T13:26:00.276-04:00'),
  (3370,  3, 'bloqueado', '2026-04-27T17:20:55.153-04:00'),
  (3370,  4, 'em_validacao', '2026-04-29T13:43:23.314-04:00'),
  (3370,  5, 'finalizado', '2026-05-11T10:25:10.398-04:00'),
  (3371,  1, 'backlog', '2026-04-22T14:56:24.104-04:00'),
  (3371,  2, 'em_andamento', '2026-04-27T09:36:27.061-04:00'),
  (3371,  3, 'em_validacao', '2026-05-06T19:22:28.718-04:00'),
  (3371,  4, 'em_andamento', '2026-05-07T01:05:31.140-04:00'),
  (3371,  5, 'em_validacao', '2026-05-07T12:04:33.509-04:00'),
  (3371,  6, 'finalizado', '2026-05-08T12:27:22.149-04:00'),
  (3372,  1, 'backlog', '2026-04-22T14:57:56.206-04:00'),
  (3372,  2, 'em_andamento', '2026-04-27T09:36:29.999-04:00'),
  (3372,  3, 'em_validacao', '2026-05-06T19:22:26.230-04:00'),
  (3372,  4, 'em_andamento', '2026-05-07T01:05:42.755-04:00'),
  (3372,  5, 'em_validacao', '2026-05-07T12:04:34.936-04:00'),
  (3373,  1, 'backlog', '2026-04-22T16:19:52.916-04:00'),
  (3373,  2, 'fila_exec', '2026-04-22T16:19:58.791-04:00'),
  (3373,  3, 'em_andamento', '2026-04-27T07:42:57.828-04:00'),
  (3373,  4, 'bloqueado', '2026-04-27T17:20:43.628-04:00'),
  (3373,  5, 'em_andamento', '2026-05-06T08:47:16.932-04:00'),
  (3373,  6, 'em_validacao', '2026-05-08T12:49:20.818-04:00'),
  (3373,  7, 'finalizado', '2026-05-08T12:49:45.507-04:00'),
  (3374,  1, 'backlog', '2026-04-24T11:17:50.543-04:00'),
  (3374,  2, 'em_andamento', '2026-04-27T12:10:58.741-04:00'),
  (3374,  3, 'finalizado', '2026-04-28T09:58:31.780-04:00'),
  (3375,  1, 'backlog', '2026-04-24T13:25:00.603-04:00'),
  (3375,  2, 'em_andamento', '2026-04-27T12:12:43.130-04:00'),
  (3375,  3, 'em_validacao', '2026-05-07T12:04:41.161-04:00'),
  (3376,  1, 'backlog', '2026-04-27T08:15:39.499-04:00'),
  (3376,  2, 'em_andamento', '2026-04-27T08:44:00.157-04:00'),
  (3377,  1, 'backlog', '2026-04-27T08:16:08.557-04:00'),
  (3377,  2, 'em_andamento', '2026-04-28T10:59:03.889-04:00'),
  (3377,  3, 'finalizado', '2026-05-04T09:43:25.013-04:00'),
  (3378,  1, 'backlog', '2026-04-27T08:16:16.390-04:00'),
  (3379,  1, 'backlog', '2026-04-27T08:16:22.030-04:00'),
  (3379,  2, 'em_andamento', '2026-04-28T10:59:05.429-04:00'),
  (3379,  3, 'finalizado', '2026-05-04T07:23:38.916-04:00'),
  (3380,  1, 'backlog', '2026-04-27T08:16:32.302-04:00'),
  (3380,  2, 'em_andamento', '2026-04-30T12:54:47.755-04:00'),
  (3380,  3, 'em_validacao', '2026-05-08T12:49:15.694-04:00'),
  (3380,  4, 'em_andamento', '2026-05-08T12:49:41.136-04:00'),
  (3381,  1, 'backlog', '2026-04-27T08:16:47.317-04:00'),
  (3381,  2, 'bloqueado', '2026-04-29T12:53:29.188-04:00'),
  (3381,  3, 'em_andamento', '2026-05-13T10:18:57.031-04:00'),
  (3381,  4, 'em_validacao', '2026-05-14T13:00:13.406-04:00'),
  (3381,  5, 'em_andamento', '2026-05-14T13:00:17.009-04:00'),
  (3381,  6, 'bloqueado', '2026-05-18T12:55:24.292-04:00'),
  (3381,  7, 'em_andamento', '2026-05-19T16:17:46.210-04:00'),
  (3382,  1, 'backlog', '2026-04-27T08:16:54.825-04:00'),
  (3382,  2, 'em_andamento', '2026-04-28T10:59:10.478-04:00'),
  (3382,  3, 'finalizado', '2026-05-11T07:56:35.463-04:00'),
  (3383,  1, 'backlog', '2026-04-27T08:17:04.210-04:00'),
  (3384,  1, 'backlog', '2026-04-27T08:17:19.431-04:00'),
  (3384,  2, 'fila_exec', '2026-05-19T11:52:54.281-04:00'),
  (3385,  1, 'backlog', '2026-04-27T08:17:46.011-04:00'),
  (3385,  2, 'em_andamento', '2026-04-30T12:55:03.593-04:00'),
  (3386,  1, 'backlog', '2026-04-27T11:10:18.659-04:00'),
  (3387,  1, 'backlog', '2026-04-27T11:10:24.400-04:00'),
  (3388,  1, 'backlog', '2026-04-27T11:10:30.668-04:00'),
  (3389,  1, 'backlog', '2026-04-27T11:10:36.700-04:00'),
  (3390,  1, 'backlog', '2026-04-27T11:10:43.718-04:00'),
  (3391,  1, 'backlog', '2026-04-27T11:10:50.087-04:00'),
  (3392,  1, 'backlog', '2026-04-27T11:10:56.446-04:00'),
  (3393,  1, 'backlog', '2026-04-27T11:11:02.862-04:00'),
  (3394,  1, 'backlog', '2026-04-27T11:11:10.413-04:00'),
  (3395,  1, 'backlog', '2026-04-27T11:11:18.099-04:00'),
  (3396,  1, 'backlog', '2026-04-27T11:11:44.025-04:00'),
  (3397,  1, 'backlog', '2026-04-27T11:11:51.628-04:00'),
  (3398,  1, 'backlog', '2026-04-27T11:11:58.411-04:00'),
  (3399,  1, 'backlog', '2026-04-27T11:12:06.351-04:00'),
  (3400,  1, 'backlog', '2026-04-27T11:12:14.762-04:00'),
  (3401,  1, 'backlog', '2026-04-27T11:12:21.761-04:00'),
  (3402,  1, 'backlog', '2026-04-27T11:12:28.210-04:00'),
  (3403,  1, 'backlog', '2026-04-27T11:12:47.783-04:00'),
  (3404,  1, 'backlog', '2026-04-27T11:12:53.571-04:00'),
  (3405,  1, 'backlog', '2026-04-27T11:13:04.254-04:00'),
  (3406,  1, 'backlog', '2026-04-27T11:13:10.231-04:00'),
  (3407,  1, 'backlog', '2026-04-27T11:13:15.805-04:00'),
  (3408,  1, 'backlog', '2026-04-27T11:13:21.456-04:00'),
  (3409,  1, 'backlog', '2026-04-27T12:23:57.268-04:00'),
  (3409,  2, 'em_andamento', '2026-04-30T11:43:35.715-04:00'),
  (3409,  3, 'em_validacao', '2026-05-20T09:29:43.611-04:00'),
  (3410,  1, 'backlog', '2026-04-27T12:24:45.954-04:00'),
  (3410,  2, 'em_andamento', '2026-05-13T10:54:55.764-04:00'),
  (3411,  1, 'backlog', '2026-04-29T16:16:31.685-04:00'),
  (3411,  2, 'fila_exec', '2026-04-29T16:18:18.829-04:00'),
  (3411,  3, 'em_andamento', '2026-04-30T15:59:50.277-04:00'),
  (3411,  4, 'em_validacao', '2026-05-06T10:27:46.945-04:00'),
  (3412,  1, 'backlog', '2026-04-30T12:37:10.636-04:00'),
  (3412,  2, 'em_andamento', '2026-04-30T12:37:14.764-04:00'),
  (3412,  3, 'finalizado', '2026-05-11T14:02:47.952-04:00'),
  (3413,  1, 'backlog', '2026-04-30T12:56:45.386-04:00'),
  (3413,  2, 'em_andamento', '2026-04-30T12:56:48.805-04:00'),
  (3413,  3, 'em_validacao', '2026-05-06T08:47:14.444-04:00'),
  (3413,  4, 'finalizado', '2026-05-11T10:25:15.542-04:00'),
  (3414,  1, 'backlog', '2026-04-30T12:58:17.160-04:00'),
  (3414,  2, 'em_andamento', '2026-04-30T12:59:09.556-04:00'),
  (3414,  3, 'em_validacao', '2026-05-08T12:47:37.764-04:00'),
  (3414,  4, 'finalizado', '2026-05-11T10:25:25.331-04:00'),
  (3415,  1, 'backlog', '2026-05-07T12:59:10.835-04:00'),
  (3415,  2, 'fila_exec', '2026-05-08T12:24:37.418-04:00'),
  (3415,  3, 'em_andamento', '2026-05-08T12:24:38.533-04:00'),
  (3416,  1, 'backlog', '2026-05-08T10:52:33.986-04:00'),
  (3416,  2, 'finalizado', '2026-05-08T16:09:48.570-04:00'),
  (3416,  3, 'em_andamento', '2026-05-08T16:11:23.371-04:00'),
  (3416,  4, 'em_validacao', '2026-05-10T16:51:28.905-04:00'),
  (3416,  5, 'finalizado', '2026-05-12T14:40:20.353-04:00'),
  (3417,  1, 'backlog', '2026-05-08T12:47:32.844-04:00'),
  (3417,  2, 'em_validacao', '2026-05-08T12:47:38.943-04:00'),
  (3417,  3, 'finalizado', '2026-05-11T10:25:27.646-04:00'),
  (3417,  4, 'em_validacao', '2026-05-11T10:28:57.174-04:00'),
  (3417,  5, 'finalizado', '2026-05-11T10:37:16.957-04:00'),
  (3418,  1, 'backlog', '2026-05-08T15:46:47.802-04:00'),
  (3419,  1, 'backlog', '2026-05-11T08:58:27.247-04:00'),
  (3419,  2, 'em_andamento', '2026-05-11T08:59:57.505-04:00'),
  (3419,  3, 'em_validacao', '2026-05-11T10:53:05.237-04:00'),
  (3420,  1, 'backlog', '2026-05-11T09:23:55.522-04:00'),
  (3420,  2, 'bloqueado', '2026-05-11T12:59:07.881-04:00'),
  (3420,  3, 'finalizado', '2026-05-13T10:41:56.955-04:00'),
  (3421,  1, 'backlog', '2026-05-11T10:26:23.490-04:00'),
  (3421,  2, 'em_andamento', '2026-05-11T10:26:26.916-04:00'),
  (3421,  3, 'bloqueado', '2026-05-12T14:16:10.071-04:00'),
  (3421,  4, 'em_andamento', '2026-05-19T12:48:44.708-04:00'),
  (3422,  1, 'backlog', '2026-05-11T10:48:27.696-04:00'),
  (3422,  2, 'em_andamento', '2026-05-11T15:27:20.539-04:00'),
  (3422,  3, 'em_validacao', '2026-05-12T08:39:00.659-04:00'),
  (3422,  4, 'finalizado', '2026-05-13T12:22:01.921-04:00'),
  (3423,  1, 'backlog', '2026-05-11T10:55:16.602-04:00'),
  (3423,  2, 'em_andamento', '2026-05-12T10:04:14.946-04:00'),
  (3423,  3, 'bloqueado', '2026-05-18T12:51:06.800-04:00'),
  (3423,  4, 'em_andamento', '2026-05-18T12:52:36.779-04:00'),
  (3424,  1, 'backlog', '2026-05-11T11:04:53.048-04:00'),
  (3425,  1, 'backlog', '2026-05-11T11:09:30.206-04:00'),
  (3425,  2, 'fila_exec', '2026-05-12T08:33:09.588-04:00'),
  (3426,  1, 'backlog', '2026-05-11T13:02:21.247-04:00'),
  (3427,  1, 'backlog', '2026-05-12T14:15:46.419-04:00'),
  (3427,  2, 'em_andamento', '2026-05-12T14:16:36.331-04:00'),
  (3427,  3, 'finalizado', '2026-05-13T12:56:06.641-04:00'),
  (3428,  1, 'backlog', '2026-05-12T14:17:34.151-04:00'),
  (3428,  2, 'em_andamento', '2026-05-12T14:18:43.076-04:00'),
  (3428,  3, 'finalizado', '2026-05-13T12:56:12.232-04:00'),
  (3429,  1, 'backlog', '2026-05-14T12:34:52.408-04:00'),
  (3429,  2, 'finalizado', '2026-05-14T12:34:57.247-04:00'),
  (3430,  1, 'backlog', '2026-05-14T12:40:05.938-04:00'),
  (3431,  1, 'backlog', '2026-05-14T15:47:14.074-04:00'),
  (3432,  1, 'backlog', '2026-05-18T15:48:41.809-04:00'),
  (3432,  2, 'em_andamento', '2026-05-19T13:05:04.862-04:00'),
  (3432,  3, 'finalizado', '2026-05-19T13:47:08.939-04:00'),
  (3433,  1, 'backlog', '2026-05-18T16:33:44.129-04:00'),
  (3433,  2, 'em_validacao', '2026-05-18T17:18:13.898-04:00'),
  (3434,  1, 'backlog', '2026-05-18T16:37:22.193-04:00'),
  (3435,  1, 'backlog', '2026-05-19T09:10:45.147-04:00'),
  (3435,  2, 'em_andamento', '2026-05-19T12:38:30.502-04:00'),
  (3435,  3, 'finalizado', '2026-05-19T14:16:20.079-04:00'),
  (3436,  1, 'backlog', '2026-05-19T12:49:54.859-04:00'),
  (3436,  2, 'em_andamento', '2026-05-19T12:49:57.100-04:00');

-- Sanidade: todos os ticket_number do staging existem em tickets? (esperado: 130)
SELECT count(DISTINCT e.ticket_number) AS staging_tickets,
       count(DISTINCT t.id)            AS casados_em_tickets
  FROM _iaf_status_events e
  LEFT JOIN tickets t ON t.ticket_number = e.ticket_number;

-- -----------------------------------------------------------------------------
-- 1) APAGA o histórico importado (bogus, carimbado na data do import) desses tickets
-- -----------------------------------------------------------------------------
DELETE FROM ticket_status_history sh
 USING tickets t
 WHERE sh.ticket_id = t.id
   AND t.ticket_number IN (SELECT DISTINCT ticket_number FROM _iaf_status_events);

-- -----------------------------------------------------------------------------
-- 2) INSERE o histórico reconstruído do Jira
--    (se houver colunas NOT NULL extras, adicione-as aqui; old_status via LAG abaixo)
-- -----------------------------------------------------------------------------
INSERT INTO ticket_status_history (ticket_id, new_status, changed_at)
SELECT t.id, e.new_status, e.changed_at
  FROM _iaf_status_events e
  JOIN tickets t ON t.ticket_number = e.ticket_number
 ORDER BY e.ticket_number, e.seq;

-- 2b) OPCIONAL — se a tabela exigir old_status (status anterior), preencher via janela:
/*
WITH ord AS (
  SELECT t.id AS ticket_id, e.new_status, e.changed_at,
         lag(e.new_status) OVER (PARTITION BY e.ticket_number ORDER BY e.seq) AS old_status
    FROM _iaf_status_events e JOIN tickets t ON t.ticket_number = e.ticket_number
)
UPDATE ticket_status_history sh SET old_status = o.old_status
  FROM ord o WHERE sh.ticket_id = o.ticket_id AND sh.changed_at = o.changed_at;
*/

-- -----------------------------------------------------------------------------
-- 3) Sincroniza colunas-resumo do ticket com o novo histórico
-- -----------------------------------------------------------------------------
-- status_changed_at = último evento; status = status do último evento
WITH ult AS (
  SELECT DISTINCT ON (ticket_number) ticket_number, new_status, changed_at
    FROM _iaf_status_events ORDER BY ticket_number, seq DESC
)
UPDATE tickets t
   SET status_changed_at = u.changed_at,
       status            = u.new_status
  FROM ult u WHERE t.ticket_number = u.ticket_number;

-- resolved_at = ÚLTIMO move para 'finalizado' (NULL se nunca finalizou)
WITH fin AS (
  SELECT ticket_number, max(changed_at) AS resolved_at
    FROM _iaf_status_events WHERE new_status = 'finalizado'
   GROUP BY ticket_number
)
UPDATE tickets t
   SET resolved_at = f.resolved_at
  FROM fin f WHERE t.ticket_number = f.ticket_number;
-- (tickets que não finalizaram mantêm resolved_at atual; se quiser zerar, rode um UPDATE
--  ... SET resolved_at = NULL WHERE ticket_number IN (staging) AND NOT IN (fin).)

-- -----------------------------------------------------------------------------
-- VERIFICAÇÃO (conferir ANTES do COMMIT)
-- -----------------------------------------------------------------------------
-- a) histórico reconstruído de tickets-chave
SELECT t.ticket_number, sh.new_status, sh.changed_at
  FROM ticket_status_history sh JOIN tickets t ON t.id = sh.ticket_id
 WHERE t.ticket_number IN (3288, 3416, 3338, 3403)
 ORDER BY t.ticket_number, sh.changed_at;
-- esperado 3288: backlog 03-18 08:33 -> bloqueado 03-18 08:34 -> finalizado 04-07 08:50
-- esperado 3416: ... -> finalizado 05-08 16:09 -> em_andamento -> em_validacao -> finalizado 05-12 (reabertura)

-- b) contagem de eventos por ticket bate com o staging?
SELECT e.ticket_number, count(*) AS staging, (
   SELECT count(*) FROM ticket_status_history sh JOIN tickets t ON t.id=sh.ticket_id
    WHERE t.ticket_number = e.ticket_number) AS gravados
  FROM _iaf_status_events e GROUP BY e.ticket_number
 HAVING count(*) <> (SELECT count(*) FROM ticket_status_history sh JOIN tickets t ON t.id=sh.ticket_id
                      WHERE t.ticket_number = e.ticket_number);
-- esperado: 0 linhas (todas batem)

-- =============================================================================
ROLLBACK;   -- padrão seguro. Troque por COMMIT após validar os SELECTs acima.
-- COMMIT;
-- =============================================================================
