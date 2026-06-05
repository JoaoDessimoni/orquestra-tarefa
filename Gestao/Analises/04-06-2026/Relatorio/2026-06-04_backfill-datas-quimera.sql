-- =============================================================================
-- BACKFILL DE DATAS — tickets IAF migrados do Jira -> Quimera
-- Gerado: 2026-06-04
-- Autor:  João Vinícius (Supervisor IAF) via Claude Code
-- Fonte da verdade: Jira (projeto IAF, blips-dev.atlassian.net) — fields.created / fields.resolutiondate
-- Escopo: 130 tickets do time ia_automacao_finza importados do Jira em lote (≈ 2026-05-26).
--         O import resetou created_at e a finalização para o timestamp do import,
--         quebrando Conclusão, Intruders, Lead Time e Cycle Time.
-- =============================================================================
--
-- POR QUE ESTE SCRIPT EXISTE
-- --------------------------
-- O MCP do Quimera só grava `created_at` (via update_ticket). A data de FINALIZAÇÃO
-- vive no histórico de status (status_history) e NÃO é gravável por MCP — e o Cycle
-- Time deriva desse histórico. Logo:
--   * Parte A (created_at, 130) — pode ser feita pelo MCP OU por este script (redundante; rede de segurança).
--   * Parte B (finalização, 72) — SÓ no banco. É o que de fato normaliza Cycle/Lead Time.
--
-- >>> SCHEMA REAL CONFIRMADO (2026-06-05) <<<
--   Nomes abaixo confirmados ao vivo: a tabela de histórico apareceu na query do endpoint
--   Gestão > Indicadores (`ticket_status_history?select=ticket_id,new_status,changed_at`).
--     - Tabela de tickets ............ public.tickets
--     - PK do ticket ................. id                  (UUID) — é a FK usada no histórico
--     - Chave de negócio ............. ticket_number       (o "#3288") — só p/ leitura humana
--     - Coluna de criação ............ created_at          (timestamptz)  [já corrigida via MCP]
--     - Tabela de histórico .......... public.ticket_status_history   ◀ nome REAL (não "status_history")
--     - FK p/ ticket no histórico .... ticket_id           (UUID → tickets.id)
--     - Coluna de status ............. new_status          (texto)  ◀ nome REAL (não "status")
--     - Coluna de data do evento ..... changed_at          (timestamptz)
--     - Valor de conclusão ........... 'finalizado'        (enum: backlog|fila_exec|em_andamento|bloqueado|em_validacao|finalizado|cancelado)
--
--   >>> LIMITE IMPORTANTE DO BACKFILL created+resolved <<<
--   O Cycle Time soma dias úteis em (em_andamento+bloqueado+em_validacao) ao longo de TODO
--   o histórico até o último move p/ 'finalizado'. Corrigir só o 1º evento (created) e o
--   último ('finalizado') conserta LEAD TIME e as datas exibidas, mas NÃO reconstrói o
--   Cycle Time real — para isso é preciso reescrever cada transição intermediária a partir
--   do CHANGELOG do Jira (campo `changelog`/histories por issue). Ver Parte C (opcional).
--   O DBA deve confirmar (a) e (b) na Parte B e escolher.
--
-- COMO USAR
--   1. Confirmar/ajustar as premissas de schema acima.
--   2. Rodar dentro de transação, conferir os SELECTs de verificação, e só então COMMIT.
--   3. Tirar dump/backup das tabelas tickets e status_history antes.
-- =============================================================================

BEGIN;  -- rodar como transação; revisar verificação antes do COMMIT

-- -----------------------------------------------------------------------------
-- STAGING: dados reais do Jira (created + resolved). resolved NULL = não concluído no Jira.
-- -----------------------------------------------------------------------------
CREATE TEMP TABLE _iaf_backfill (
    ticket_number integer PRIMARY KEY,
    jira_key      text,
    created_real  timestamptz,
    resolved_real timestamptz  -- NULL quando o Jira não tem resolutiondate
) ON COMMIT DROP;

INSERT INTO _iaf_backfill (ticket_number, jira_key, created_real, resolved_real) VALUES
 (3287,'IAF-6',  '2026-03-06T19:27:40.506-04:00', NULL),
 (3288,'IAF-12', '2026-03-18T08:33:48.852-04:00', '2026-04-07T08:50:19.551-04:00'),
 (3289,'IAF-13', '2026-03-18T08:33:50.686-04:00', '2026-04-07T08:48:05.886-04:00'),
 (3290,'IAF-14', '2026-03-18T08:33:52.396-04:00', '2026-04-07T08:47:45.706-04:00'),
 (3291,'IAF-15', '2026-03-18T08:33:53.786-04:00', '2026-05-07T16:22:26.842-04:00'),
 (3292,'IAF-16', '2026-03-18T08:33:56.701-04:00', '2026-04-30T12:54:33.856-04:00'),
 (3293,'IAF-17', '2026-03-18T08:33:58.430-04:00', NULL),
 (3294,'IAF-18', '2026-03-18T08:33:59.739-04:00', '2026-04-07T08:48:50.111-04:00'),
 (3295,'IAF-19', '2026-03-18T08:34:01.226-04:00', NULL),
 (3296,'IAF-20', '2026-03-18T08:34:02.630-04:00', '2026-04-07T08:47:56.818-04:00'),
 (3297,'IAF-22', '2026-03-18T08:34:06.010-04:00', '2026-04-06T08:28:20.195-04:00'),
 (3298,'IAF-23', '2026-03-18T08:34:07.424-04:00', '2026-05-08T13:03:56.613-04:00'),
 (3299,'IAF-24', '2026-03-18T08:34:09.545-04:00', '2026-04-07T08:49:10.946-04:00'),
 (3300,'IAF-25', '2026-03-18T08:34:10.959-04:00', '2026-04-07T08:47:59.040-04:00'),
 (3301,'IAF-26', '2026-03-18T08:34:12.352-04:00', '2026-04-07T08:48:09.069-04:00'),
 (3302,'IAF-28', '2026-03-18T08:41:56.906-04:00', '2026-04-14T08:52:30.133-04:00'),
 (3303,'IAF-29', '2026-03-18T08:41:59.004-04:00', '2026-04-14T08:51:57.425-04:00'),
 (3304,'IAF-30', '2026-03-17T08:43:22.854-04:00', NULL),
 (3305,'IAF-31', '2026-03-18T11:01:53.680-04:00', '2026-04-02T14:53:46.050-04:00'),
 (3306,'IAF-36', '2026-03-19T08:07:00.158-04:00', '2026-04-10T08:50:24.947-04:00'),
 (3327,'IAF-67', '2026-04-07T08:19:02.808-04:00', NULL),
 (3328,'IAF-69', '2026-04-07T08:19:03.084-04:00', NULL),
 (3329,'IAF-71', '2026-04-07T08:19:04.421-04:00', '2026-04-08T12:57:30.980-04:00'),
 (3330,'IAF-72', '2026-04-07T08:19:04.708-04:00', '2026-04-08T23:24:44.115-04:00'),
 (3331,'IAF-73', '2026-04-07T08:19:05.307-04:00', '2026-04-15T08:56:20.337-04:00'),
 (3332,'IAF-74', '2026-04-07T08:19:05.376-04:00', '2026-04-07T18:43:31.232-04:00'),
 (3333,'IAF-75', '2026-04-07T08:49:43.699-04:00', '2026-04-10T18:13:10.640-04:00'),
 (3334,'IAF-76', '2026-04-07T08:51:11.365-04:00', '2026-04-14T08:52:45.633-04:00'),
 (3335,'IAF-77', '2026-04-07T10:07:21.913-04:00', NULL),
 (3336,'IAF-78', '2026-04-07T14:26:05.345-04:00', '2026-05-15T09:43:41.185-04:00'),
 (3337,'IAF-79', '2026-04-07T14:34:32.287-04:00', '2026-04-07T14:34:32.905-04:00'),
 (3338,'IAF-81', '2025-11-14T14:50:23.343-04:00', NULL),
 (3339,'IAF-82', '2026-04-09T08:45:17.689-04:00', '2026-04-30T12:54:15.746-04:00'),
 (3340,'IAF-83', '2026-04-09T09:00:18.399-04:00', '2026-04-09T15:59:36.108-04:00'),
 (3341,'IAF-84', '2026-04-09T09:15:00.521-04:00', '2026-04-13T08:33:58.004-04:00'),
 (3342,'IAF-85', '2026-04-09T09:15:50.368-04:00', '2026-04-14T08:49:49.530-04:00'),
 (3343,'IAF-86', '2026-04-09T09:16:02.617-04:00', '2026-04-13T08:34:07.008-04:00'),
 (3344,'IAF-89', '2026-04-09T13:16:02.257-04:00', '2026-04-13T08:27:49.726-04:00'),
 (3345,'IAF-90', '2026-04-09T13:25:48.143-04:00', '2026-04-13T08:27:57.425-04:00'),
 (3346,'IAF-91', '2026-04-09T13:26:18.930-04:00', '2026-04-28T10:57:33.206-04:00'),
 (3347,'IAF-92', '2026-04-09T13:36:22.991-04:00', '2026-04-10T14:18:40.023-04:00'),
 (3348,'IAF-93', '2026-04-09T16:22:13.856-04:00', '2026-04-15T13:17:20.314-04:00'),
 (3349,'IAF-94', '2026-04-10T07:23:55.046-04:00', '2026-04-16T09:16:07.968-04:00'),
 (3350,'IAF-95', '2026-04-10T08:54:12.474-04:00', '2026-05-04T09:43:32.902-04:00'),
 (3351,'IAF-96', '2026-04-10T10:30:07.931-04:00', '2026-05-15T09:43:39.427-04:00'),
 (3352,'IAF-97', '2026-04-13T08:33:39.034-04:00', '2026-04-13T08:34:11.640-04:00'),
 (3353,'IAF-98', '2026-04-13T08:46:42.869-04:00', '2026-04-15T08:56:59.686-04:00'),
 (3354,'IAF-99', '2026-04-13T09:12:49.747-04:00', '2026-04-22T08:41:52.109-04:00'),
 (3355,'IAF-101','2026-04-14T08:50:11.833-04:00', '2026-04-17T08:18:35.874-04:00'),
 (3356,'IAF-102','2026-04-14T08:50:56.657-04:00', '2026-04-30T12:34:46.714-04:00'),
 (3357,'IAF-103','2026-04-15T09:08:04.318-04:00', NULL),
 (3358,'IAF-109','2026-04-15T16:53:31.726-04:00', NULL),
 (3359,'IAF-110','2026-04-16T09:12:02.212-04:00', '2026-04-27T15:44:18.817-04:00'),
 (3360,'IAF-111','2026-04-16T14:49:03.432-04:00', '2026-04-24T10:19:21.086-04:00'),
 (3361,'IAF-112','2026-04-16T15:14:50.216-04:00', '2026-04-17T08:18:19.203-04:00'),
 (3362,'IAF-113','2026-04-16T15:45:37.301-04:00', '2026-04-22T08:42:58.463-04:00'),
 (3363,'IAF-114','2026-04-14T22:16:11.137-04:00', '2026-04-22T08:41:02.699-04:00'),
 (3364,'IAF-115','2026-04-17T14:17:11.068-04:00', '2026-04-30T12:57:03.428-04:00'),
 (3365,'IAF-116','2026-04-17T15:31:44.213-04:00', '2026-04-17T15:39:48.237-04:00'),
 (3366,'IAF-117','2026-04-20T07:35:48.939-04:00', '2026-04-30T12:59:57.816-04:00'),
 (3367,'IAF-118','2026-04-20T12:52:19.232-04:00', NULL),
 (3368,'IAF-119','2026-04-20T16:44:44.348-04:00', '2026-04-22T20:53:40.890-04:00'),
 (3369,'IAF-120','2026-04-22T09:35:16.534-04:00', '2026-04-23T21:04:22.157-04:00'),
 (3370,'IAF-121','2026-04-22T13:25:38.532-04:00', '2026-05-11T10:25:10.378-04:00'),
 (3371,'IAF-122','2026-04-22T14:56:24.104-04:00', '2026-05-08T12:27:22.105-04:00'),
 (3372,'IAF-122','2026-04-22T14:56:24.104-04:00', '2026-05-08T12:27:22.105-04:00'),  -- desdobramento de IAF-122
 (3373,'IAF-125','2026-04-22T16:19:52.916-04:00', '2026-05-08T12:49:45.482-04:00'),
 (3374,'IAF-128','2026-04-24T11:17:50.543-04:00', '2026-04-28T09:58:31.758-04:00'),
 (3375,'IAF-129','2026-04-24T13:25:00.603-04:00', NULL),
 (3376,'IAF-130','2026-04-27T08:15:39.499-04:00', NULL),
 (3377,'IAF-131','2026-04-27T08:16:08.557-04:00', '2026-05-04T09:43:24.991-04:00'),
 (3378,'IAF-132','2026-04-27T08:16:16.390-04:00', NULL),
 (3379,'IAF-133','2026-04-27T08:16:22.030-04:00', '2026-05-04T07:23:38.829-04:00'),
 (3380,'IAF-134','2026-04-27T08:16:32.302-04:00', NULL),
 (3381,'IAF-136','2026-04-27T08:16:47.317-04:00', NULL),
 (3382,'IAF-137','2026-04-27T08:16:54.825-04:00', '2026-05-11T07:56:35.440-04:00'),
 (3383,'IAF-138','2026-04-27T08:17:04.210-04:00', NULL),
 (3384,'IAF-139','2026-04-27T08:17:19.431-04:00', NULL),
 (3385,'IAF-140','2026-04-27T08:17:46.011-04:00', NULL),
 (3386,'IAF-145','2026-04-27T11:10:18.659-04:00', NULL),
 (3387,'IAF-146','2026-04-27T11:10:24.400-04:00', NULL),
 (3388,'IAF-147','2026-04-27T11:10:30.668-04:00', NULL),
 (3389,'IAF-148','2026-04-27T11:10:36.700-04:00', NULL),
 (3390,'IAF-149','2026-04-27T11:10:43.718-04:00', NULL),
 (3391,'IAF-150','2026-04-27T11:10:50.087-04:00', NULL),
 (3392,'IAF-151','2026-04-27T11:10:56.446-04:00', NULL),
 (3393,'IAF-152','2026-04-27T11:11:02.862-04:00', NULL),
 (3394,'IAF-153','2026-04-27T11:11:10.413-04:00', NULL),
 (3395,'IAF-154','2026-04-27T11:11:18.099-04:00', NULL),
 (3396,'IAF-155','2026-04-27T11:11:44.025-04:00', NULL),
 (3397,'IAF-156','2026-04-27T11:11:51.628-04:00', NULL),
 (3398,'IAF-157','2026-04-27T11:11:58.411-04:00', NULL),
 (3399,'IAF-158','2026-04-27T11:12:06.351-04:00', NULL),
 (3400,'IAF-159','2026-04-27T11:12:14.762-04:00', NULL),
 (3401,'IAF-160','2026-04-27T11:12:21.761-04:00', NULL),
 (3402,'IAF-161','2026-04-27T11:12:28.210-04:00', NULL),
 (3403,'IAF-162','2026-04-27T11:12:47.783-04:00', NULL),
 (3404,'IAF-163','2026-04-27T11:12:53.571-04:00', NULL),
 (3405,'IAF-164','2026-04-27T11:13:04.254-04:00', NULL),
 (3406,'IAF-165','2026-04-27T11:13:10.231-04:00', NULL),
 (3407,'IAF-166','2026-04-27T11:13:15.805-04:00', NULL),
 (3408,'IAF-167','2026-04-27T11:13:21.456-04:00', NULL),
 (3409,'IAF-168','2026-04-27T12:23:57.268-04:00', NULL),
 (3410,'IAF-169','2026-04-27T12:24:45.954-04:00', NULL),
 (3411,'IAF-171','2026-04-29T16:16:31.685-04:00', NULL),
 (3412,'IAF-172','2026-04-30T12:37:10.636-04:00', '2026-05-11T14:02:47.929-04:00'),
 (3413,'IAF-173','2026-04-30T12:56:45.386-04:00', '2026-05-11T10:25:15.534-04:00'),
 (3414,'IAF-174','2026-04-30T12:58:17.160-04:00', '2026-05-11T10:25:25.307-04:00'),
 (3415,'IAF-176','2026-05-07T12:59:10.835-04:00', NULL),
 (3416,'IAF-177','2026-05-08T10:52:33.986-04:00', '2026-05-08T16:09:48.549-04:00'),
 (3417,'IAF-178','2026-05-08T12:47:32.844-04:00', '2026-05-11T10:25:27.622-04:00'),
 (3418,'IAF-181','2026-05-08T15:46:47.802-04:00', NULL),
 (3419,'IAF-182','2026-05-11T08:58:27.247-04:00', NULL),
 (3420,'IAF-183','2026-05-11T09:23:55.522-04:00', '2026-05-13T10:41:56.932-04:00'),
 (3421,'IAF-184','2026-05-11T10:26:23.490-04:00', NULL),
 (3422,'IAF-185','2026-05-11T10:48:27.696-04:00', '2026-05-13T12:22:01.893-04:00'),
 (3423,'IAF-186','2026-05-11T10:55:16.602-04:00', NULL),
 (3424,'IAF-187','2026-05-11T11:04:53.048-04:00', NULL),
 (3425,'IAF-188','2026-05-11T11:09:30.206-04:00', NULL),
 (3426,'IAF-189','2026-05-11T13:02:21.247-04:00', NULL),
 (3427,'IAF-192','2026-05-12T14:15:46.419-04:00', '2026-05-13T12:56:06.616-04:00'),
 (3428,'IAF-194','2026-05-12T14:17:34.151-04:00', '2026-05-13T12:56:12.212-04:00'),
 (3429,'IAF-196','2026-05-14T12:34:52.408-04:00', '2026-05-14T12:34:57.220-04:00'),
 (3430,'IAF-198','2026-05-14T12:40:05.938-04:00', NULL),
 (3431,'IAF-200','2026-05-14T15:47:14.074-04:00', NULL),
 (3432,'IAF-203','2026-05-18T15:48:41.809-04:00', '2026-05-19T13:47:08.917-04:00'),
 (3433,'IAF-204','2026-05-18T16:33:44.129-04:00', NULL),
 (3434,'IAF-205','2026-05-18T16:37:22.193-04:00', NULL),
 (3435,'IAF-206','2026-05-19T09:10:45.147-04:00', '2026-05-19T14:16:20.052-04:00'),
 (3436,'IAF-207','2026-05-19T12:49:54.859-04:00', NULL);
-- Total: 130 linhas | com resolved (conclusão real): 72 | sem resolved: 58

-- -----------------------------------------------------------------------------
-- SANIDADE: quantas linhas do staging realmente casam com tickets existentes?
-- (Esperado: 130. Se vier menos, a chave de junção (ticket_number) está errada.)
-- -----------------------------------------------------------------------------
SELECT
    (SELECT count(*) FROM _iaf_backfill)                                   AS staging_total,
    (SELECT count(*) FROM _iaf_backfill b
        JOIN tickets t ON t.ticket_number = b.ticket_number)               AS casados_em_tickets,
    (SELECT count(*) FROM _iaf_backfill WHERE resolved_real IS NOT NULL)   AS com_conclusao;

-- =============================================================================
-- PARTE A — created_at (130 tickets)  [redundante com o MCP; rede de segurança]
-- =============================================================================
UPDATE tickets t
   SET created_at = b.created_real
  FROM _iaf_backfill b
 WHERE t.ticket_number = b.ticket_number;
-- Verificação A:
SELECT t.ticket_number, b.jira_key, t.created_at, b.created_real
  FROM tickets t JOIN _iaf_backfill b ON b.ticket_number = t.ticket_number
 WHERE t.created_at IS DISTINCT FROM b.created_real;   -- esperado: 0 linhas

-- =============================================================================
-- PARTE B — finalização / Cycle Time (72 tickets com resolved)  >>> ESCOLHER UMA VARIANTE <<<
-- =============================================================================

-- ---- VARIANTE B1: finalização modelada como COLUNA na própria tabela tickets ----
-- (se existir tickets.finalizado_at / closed_at / resolved_at)
/*
UPDATE tickets t
   SET finalizado_at = b.resolved_real          -- ajuste o nome da coluna
  FROM _iaf_backfill b
 WHERE t.ticket_number = b.ticket_number
   AND b.resolved_real IS NOT NULL;
*/

-- ---- VARIANTE B2 (APLICÁVEL — schema real confirmado): LINHA em ticket_status_history ----
-- O dashboard (Lead/Cycle Time, datas de "surgiu/finalizou") lê ESTA tabela, não tickets.created_at.
-- Por isso a correção via MCP (só created_at) NÃO moveu o dashboard. Esta é a correção que move.
-- Atualiza o changed_at do(s) evento(s) new_status='finalizado' de cada ticket concluído.
/*
UPDATE ticket_status_history sh
   SET changed_at = b.resolved_real
  FROM _iaf_backfill b
  JOIN tickets t ON t.ticket_number = b.ticket_number
 WHERE sh.ticket_id = t.id
   AND sh.new_status = 'finalizado'
   AND b.resolved_real IS NOT NULL;
*/
-- Se NÃO existir a linha 'finalizado' no histórico, inserir o evento
-- (ajuste colunas obrigatórias extras — autor, old_status etc. — conforme o schema real):
/*
INSERT INTO ticket_status_history (ticket_id, new_status, changed_at)
SELECT t.id, 'finalizado', b.resolved_real
  FROM _iaf_backfill b
  JOIN tickets t ON t.ticket_number = b.ticket_number
 WHERE b.resolved_real IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM ticket_status_history sh
         WHERE sh.ticket_id = t.id AND sh.new_status = 'finalizado');
*/
-- TAMBÉM corrigir o 1º evento do histórico (o "created" exibido no dashboard), que o import
-- carimbou na data de import. Alinha a data de criação exibida + o início do Lead Time:
/*
WITH primeiro AS (
  SELECT DISTINCT ON (sh.ticket_id) sh.ctid, sh.ticket_id, b.created_real
    FROM ticket_status_history sh
    JOIN tickets t ON t.id = sh.ticket_id
    JOIN _iaf_backfill b ON b.ticket_number = t.ticket_number
   ORDER BY sh.ticket_id, sh.changed_at ASC
)
UPDATE ticket_status_history sh
   SET changed_at = p.created_real
  FROM primeiro p
 WHERE sh.ctid = p.ctid;
*/
-- Verificação B: conferir tickets-chave
--   3288 -> finalização 2026-04-07 | 3338/IAF-81 -> created 2025-11-14 (sem conclusão)

-- =============================================================================
-- PARTE C (OPCIONAL — Cycle Time REAL) — reconstruir transições intermediárias
-- =============================================================================
-- B só corrige o 1º e o último evento. O Cycle Time real (tempo em em_andamento+
-- bloqueado+em_validacao) precisa das transições intermediárias REAIS, que vivem no
-- CHANGELOG do Jira (GET issue?expand=changelog → histories[].items[field='status']).
-- Sem isso, o Cycle Time dos 130 fica aproximado. Se quiser o número fiel:
--   1. Extrair, por issue IAF, cada transição de status com timestamp (changelog Jira).
--   2. Substituir o bloco de eventos importado de cada ticket por essas transições reais.
-- (Isso é uma extração à parte do Jira — peça ao Claude p/ gerar o staging de transições.)

-- =============================================================================
-- NÃO ESQUECER: revisar os SELECTs de verificação ANTES de confirmar.
-- =============================================================================
-- COMMIT;     -- descomente após validar
ROLLBACK;      -- padrão seguro: nada é persistido até troca manual por COMMIT
