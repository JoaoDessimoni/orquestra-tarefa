-- =====================================================================================
--  VALIDACAO DO SUPABASE DEV (self-hosted GCP) — gates G2..G9 do plano BTR10
--  Criado: 2026-08-10
-- =====================================================================================
--
--  RODA ONDE: no Supabase de DEV, depois do 01_estrutura.sql e do 02_dados.sql.
--  ESCREVE ALGO? Nao. Somente SELECT.
--
--  COMO RODAR
--    psql "$DEV_URL" -X -f 2026-08-10_torre_validacao-dev.sql
--
--  COMO LER: cada gate imprime uma linha com veredito. Qualquer "FALHOU" impede
--  a liberacao do ambiente para o time.
-- =====================================================================================

\pset pager off
\timing off

\echo ''
\echo '======================================================================'
\echo ' G2 · PARIDADE ESTRUTURAL — compare estes numeros com os de PROD'
\echo '======================================================================'
SELECT n.nspname                                        AS schema,
       count(*) FILTER (WHERE c.relkind = 'r')          AS tabelas,
       count(*) FILTER (WHERE c.relkind = 'v')          AS views,
       count(*) FILTER (WHERE c.relkind = 'm')          AS matviews,
       count(*) FILTER (WHERE c.relkind = 'i')          AS indices
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname IN ('public') OR n.nspname LIKE 'org\_%'
 GROUP BY 1 ORDER BY 1;

SELECT n.nspname AS schema,
       count(*) FILTER (WHERE p.prokind = 'f') AS funcoes,
       (SELECT count(*) FROM pg_policies pol WHERE pol.schemaname = n.nspname) AS policies_rls
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
 WHERE n.nspname IN ('public') OR n.nspname LIKE 'org\_%'
 GROUP BY 1 ORDER BY 1;

\echo ''
\echo '======================================================================'
\echo ' G3 · ZERO E-MAIL REAL  (esperado: 0 linhas)'
\echo '======================================================================'
-- Varre TODA coluna de e-mail de TODA tabela-base e devolve o que nao esta
-- na allowlist do time de dev.
DO $$
DECLARE r record; n bigint; total bigint := 0; amostra text;
BEGIN
  FOR r IN
    SELECT c.table_schema AS sch, c.table_name AS tbl, c.column_name AS col
      FROM information_schema.columns c
      JOIN pg_class k  ON k.relname = c.table_name
      JOIN pg_namespace ns ON ns.oid = k.relnamespace AND ns.nspname = c.table_schema
     WHERE k.relkind = 'r'
       AND (c.table_schema = 'public' OR c.table_schema LIKE 'org\_%')
       AND c.column_name ~ '(email|mail)'
       AND c.data_type IN ('text','character varying')
     ORDER BY 1,2,3
  LOOP
    EXECUTE format($q$
      SELECT count(*), min(%2$I::text) FROM %1$I.%3$I
       WHERE %2$I IS NOT NULL AND %2$I::text <> ''
         AND %2$I::text NOT IN ('joao.dessimoni@blips.com.br','marcos.oliveira@finza.com.br',
                                'leandro.gontijo@blips.com.br','joaopedro@blips.com.br',
                                'dev-anon@blips.com.br')
    $q$, r.sch, r.col, r.tbl) INTO n, amostra;
    IF n > 0 THEN
      total := total + n;
      RAISE NOTICE 'VAZAMENTO  %.%.%  ->  % linha(s), ex: %', r.sch, r.tbl, r.col, n, amostra;
    END IF;
  END LOOP;
  IF total = 0 THEN RAISE NOTICE 'G3 OK — nenhum e-mail fora da allowlist do time';
  ELSE            RAISE NOTICE 'G3 FALHOU — % valor(es) de e-mail nao anonimizado(s)', total;
  END IF;
END $$;

\echo ''
\echo '======================================================================'
\echo ' G4 · ZERO TELEFONE REAL  (esperado: 0 linhas)'
\echo '======================================================================'
DO $$
DECLARE r record; n bigint; total bigint := 0; amostra text;
BEGIN
  FOR r IN
    SELECT c.table_schema AS sch, c.table_name AS tbl, c.column_name AS col
      FROM information_schema.columns c
      JOIN pg_class k  ON k.relname = c.table_name
      JOIN pg_namespace ns ON ns.oid = k.relnamespace AND ns.nspname = c.table_schema
     WHERE k.relkind = 'r'
       AND (c.table_schema = 'public' OR c.table_schema LIKE 'org\_%')
       AND c.column_name ~ '(phone|celular|whatsapp)'
       AND c.data_type IN ('text','character varying')
     ORDER BY 1,2,3
  LOOP
    EXECUTE format($q$
      SELECT count(*), min(%2$I::text) FROM %1$I.%3$I
       WHERE %2$I IS NOT NULL AND %2$I::text <> '' AND %2$I::text <> '999999999'
    $q$, r.sch, r.col, r.tbl) INTO n, amostra;
    IF n > 0 THEN
      total := total + n;
      RAISE NOTICE 'VAZAMENTO  %.%.%  ->  % linha(s), ex: %', r.sch, r.tbl, r.col, n, amostra;
    END IF;
  END LOOP;
  IF total = 0 THEN RAISE NOTICE 'G4 OK — todo telefone e 999999999';
  ELSE            RAISE NOTICE 'G4 FALHOU — % valor(es) de telefone nao anonimizado(s)', total;
  END IF;
END $$;

\echo ''
\echo '======================================================================'
\echo ' G5 · DOCUMENTOS: unicos e com formato valido'
\echo '======================================================================'
DO $$
DECLARE s text; n_dup bigint; n_bad bigint;
BEGIN
  FOR s IN SELECT nspname FROM pg_namespace WHERE nspname LIKE 'org\_%' ORDER BY 1 LOOP
    EXECUTE format($q$
      SELECT (SELECT count(*) FROM (SELECT document FROM %1$I.contacts
                WHERE document IS NOT NULL GROUP BY document HAVING count(*) > 1) d),
             (SELECT count(*) FROM %1$I.contacts
               WHERE document IS NOT NULL
                 AND length(regexp_replace(document,'\D','','g')) NOT IN (11,14))
    $q$, s) INTO n_dup, n_bad;
    IF n_dup = 0 AND n_bad = 0 THEN
      RAISE NOTICE 'G5 OK  %  — documentos unicos e com 11/14 digitos', s;
    ELSE
      RAISE NOTICE 'G5 FALHOU  %  — % duplicado(s), % com formato invalido', s, n_dup, n_bad;
    END IF;
  END LOOP;
END $$;

\echo ''
\echo '-- G5b (rodar em PROD): confirma que nenhum documento do DEV existe em prod.'
\echo '-- Exporte a lista do DEV e cruze:'
\echo '--   DEV : \copy (SELECT document FROM org_blips.contacts WHERE document IS NOT NULL) TO ''dev_docs.csv'' CSV'
\echo '--   PROD: crie temp table, \copy dev_docs FROM ''dev_docs.csv'' CSV, e'
\echo '--         SELECT count(*) FROM org_blips.contacts c JOIN dev_docs d ON d.document = c.document;  -- esperado 0'

\echo ''
\echo '======================================================================'
\echo ' G6 · PII DENTRO DE JSONB  (esperado: 0 ocorrencias)'
\echo '======================================================================'
DO $$
DECLARE r record; n bigint; total bigint := 0;
BEGIN
  FOR r IN
    SELECT c.table_schema AS sch, c.table_name AS tbl, c.column_name AS col
      FROM information_schema.columns c
      JOIN pg_class k  ON k.relname = c.table_name
      JOIN pg_namespace ns ON ns.oid = k.relnamespace AND ns.nspname = c.table_schema
     WHERE k.relkind = 'r'
       AND (c.table_schema = 'public' OR c.table_schema LIKE 'org\_%')
       AND c.data_type = 'jsonb'
     ORDER BY 1,2,3
  LOOP
    EXECUTE format($q$
      SELECT count(*) FROM %1$I.%3$I
       WHERE %2$I IS NOT NULL
         AND (
           %2$I::text ~ '[A-Za-z0-9._%%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
           AND %2$I::text !~ 'dev-anon@|@blips\.com\.br|@finza\.com\.br'
         )
    $q$, r.sch, r.col, r.tbl) INTO n;
    IF n > 0 THEN
      total := total + n;
      RAISE NOTICE 'JSONB suspeito  %.%.%  ->  % linha(s)', r.sch, r.tbl, r.col, n;
    END IF;
  END LOOP;
  IF total = 0 THEN RAISE NOTICE 'G6 OK — nenhum e-mail estranho dentro de jsonb';
  ELSE            RAISE NOTICE 'G6 FALHOU — % linha(s) com e-mail em jsonb; aperte o anon_text do gerador', total;
  END IF;
END $$;

\echo ''
\echo '======================================================================'
\echo ' G7 · O QUE O APP VE (vw_titles_live) — o gate que pega MV nao refrescada'
\echo '======================================================================'
DO $$
DECLARE s text; n bigint; tot bigint;
BEGIN
  FOR s IN SELECT nspname FROM pg_namespace WHERE nspname LIKE 'org\_%' ORDER BY 1 LOOP
    IF to_regclass(format('%I.vw_titles_live', s)) IS NULL THEN
      RAISE NOTICE 'G7 ??  %  — vw_titles_live nao existe', s; CONTINUE;
    END IF;
    EXECUTE format($q$
      SELECT count(*),
             count(*) FILTER (WHERE
                  (primary_email IS NOT NULL AND primary_email NOT IN
                     ('joao.dessimoni@blips.com.br','marcos.oliveira@finza.com.br',
                      'leandro.gontijo@blips.com.br','joaopedro@blips.com.br','dev-anon@blips.com.br'))
               OR (primary_phone IS NOT NULL AND primary_phone <> '999999999'))
        FROM %I.vw_titles_live
    $q$, s) INTO tot, n;
    IF tot = 0 THEN
      RAISE NOTICE 'G7 ATENCAO  %  — vw_titles_live esta VAZIA. Falta o REFRESH MATERIALIZED VIEW.', s;
    ELSIF n = 0 THEN
      RAISE NOTICE 'G7 OK  %  — % titulo(s) visiveis, nenhum com PII real', s, tot;
    ELSE
      RAISE NOTICE 'G7 FALHOU  %  — % de % linhas com PII real. MV materializou dado pre-anonimizacao: refresque.', s, n, tot;
    END IF;
  END LOOP;
END $$;

\echo ''
\echo '======================================================================'
\echo ' G8 · MOTOR DESARMADO — nenhum cron ativo'
\echo '======================================================================'
SELECT CASE
         WHEN to_regclass('cron.job') IS NULL
           THEN 'G8 OK — extensao pg_cron sem jobs (schema cron nao veio no dump)'
         WHEN (SELECT count(*) FROM cron.job WHERE active) = 0
           THEN 'G8 OK — ' || (SELECT count(*) FROM cron.job) || ' job(s) cadastrado(s), 0 ativo(s)'
         ELSE 'G8 FALHOU — ' || (SELECT count(*) FROM cron.job WHERE active) || ' cron(s) ATIVO(s): '
              || (SELECT string_agg(jobname, ', ') FROM cron.job WHERE active)
       END AS veredito;

\echo ''
\echo '======================================================================'
\echo ' G9 · NENHUMA CREDENCIAL DE PROD NO DEV'
\echo '======================================================================'
WITH chk(item, n, esperado) AS (
  SELECT 'public.project_config',
         (SELECT count(*) FROM public.project_config), 0
  UNION ALL SELECT 'public.api_keys',
         (SELECT count(*) FROM public.api_keys), 0
  UNION ALL SELECT 'public.organization_secrets',
         (SELECT count(*) FROM public.organization_secrets), 0
  UNION ALL SELECT 'org_blips.integration_secrets',
         (SELECT count(*) FROM org_blips.integration_secrets), 0
  UNION ALL SELECT 'org_finza.integration_secrets',
         (SELECT count(*) FROM org_finza.integration_secrets), 0
  UNION ALL SELECT 'integracoes ATIVAS (blips)',
         (SELECT count(*) FROM org_blips.integrations WHERE is_active), 0
  UNION ALL SELECT 'integracoes ATIVAS (finza)',
         (SELECT count(*) FROM org_finza.integrations WHERE is_active), 0
  UNION ALL SELECT 'report_schedules ATIVOS (blips)',
         (SELECT count(*) FROM org_blips.report_schedules WHERE is_active), 0
  UNION ALL SELECT 'report_schedules ATIVOS (finza)',
         (SELECT count(*) FROM org_finza.report_schedules WHERE is_active), 0
  UNION ALL SELECT 'mv_refresh_config habilitados',
         (SELECT count(*) FROM public.mv_refresh_config WHERE enabled), 0
)
SELECT item, n, CASE WHEN n = esperado THEN 'OK' ELSE 'FALHOU' END AS veredito FROM chk ORDER BY 3 DESC, 1;

\echo ''
\echo '======================================================================'
\echo ' EXTRA · integridade referencial apos a carga com FK desligada'
\echo '======================================================================'
-- Reativa a checagem das FKs sem alterar dado: se alguma referencia ficou orfa,
-- este comando falha e aponta a constraint. Rode dentro de uma transacao que
-- voce descarta, para nao deixar nada validado a forca.
\echo '-- Rode manualmente, tabela por tabela do nucleo, dentro de BEGIN/ROLLBACK:'
\echo '--   BEGIN;'
\echo '--   ALTER TABLE org_blips.titles VALIDATE CONSTRAINT titles_contract_id_fkey;'
\echo '--   ALTER TABLE org_blips.contracts VALIDATE CONSTRAINT contracts_contact_id_fkey;'
\echo '--   ROLLBACK;'
\echo ''
\echo '-- Alternativa rapida: conferir orfaos do nucleo por consulta.'
SELECT 'titles sem contrato'   AS check, count(*) AS orfaos
  FROM org_blips.titles t LEFT JOIN org_blips.contracts c ON c.id = t.contract_id
 WHERE c.id IS NULL
UNION ALL
SELECT 'contracts sem contato', count(*)
  FROM org_blips.contracts c LEFT JOIN org_blips.contacts p ON p.id = c.contact_id
 WHERE p.id IS NULL
UNION ALL
SELECT 'titles com action inexistente', count(*)
  FROM org_blips.titles t
 WHERE t.attributed_action_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM org_blips.actions a WHERE a.id = t.attributed_action_id);

\echo ''
\echo '======================================================================'
\echo ' RESUMO DE VOLUME'
\echo '======================================================================'
SELECT 'org_blips' AS org,
       (SELECT count(*) FROM org_blips.contacts)  AS contatos,
       (SELECT count(*) FROM org_blips.contracts) AS contratos,
       (SELECT count(*) FROM org_blips.titles)    AS titulos,
       (SELECT count(*) FROM org_blips.actions)   AS actions
UNION ALL
SELECT 'org_finza',
       (SELECT count(*) FROM org_finza.contacts),
       (SELECT count(*) FROM org_finza.contracts),
       (SELECT count(*) FROM org_finza.titles),
       (SELECT count(*) FROM org_finza.actions);

SELECT pg_size_pretty(pg_database_size(current_database())) AS tamanho_dev;
