-- =====================================================================================
--  GERADOR DO SEED DO SUPABASE DEV (self-hosted GCP) — Torre de Controle
--  BTR10 · origem Quimera #4786
--  Criado: 2026-08-10
-- =====================================================================================
--
--  O QUE ESTE ARQUIVO FAZ
--  ----------------------
--  Ele NAO altera nada. Ele LE o banco de PRODUCAO e IMPRIME na saida padrao um
--  segundo arquivo SQL (o "02_dados.sql") contendo os INSERTs ja anonimizados,
--  prontos para rodar no DEV.
--
--  RODA ONDE: no Supabase de PRODUCAO.
--  ESCREVE ALGO EM PROD? Nao. Cria apenas objetos TEMPORARIOS (pg_temp / TEMP TABLE),
--  que existem so durante a sessao do psql e morrem quando voce desconecta.
--  Nenhum INSERT/UPDATE/DELETE/DDL permanente em prod.
--
--  COMO RODAR
--  ----------
--    psql "$PROD_URL" -X -A -t -q -v ON_ERROR_STOP=1 \
--         -f 2026-08-10_torre_gerar-seed-dev.sql > 02_dados.sql
--
--    -X  ignora seu ~/.psqlrc      -A  sem alinhamento de colunas
--    -t  sem cabecalho/rodape      -q  silencioso
--
--  DEPOIS: confira o 02_dados.sql com os olhos (ele e texto puro) e rode no DEV:
--    psql "$DEV_URL" -v ON_ERROR_STOP=1 -f 02_dados.sql
--
-- =====================================================================================
--  DECISOES EMBUTIDAS AQUI (todas reversiveis editando este arquivo)
--  -------------------------------------------------------------------------------
--  1. AMOSTRA: 100 contatos por org, escolhidos de forma DETERMINISTICA
--     (ordenados por md5(id || semente)). Rodar de novo pega os MESMOS 100 —
--     o dev e reproduzivel. Troque a semente em _SEED_ para sortear outros.
--
--  2. NADA E APAGADO. O gerador simplesmente NAO EMITE INSERT para tabelas de
--     log/historico e para tabelas de segredo. Elas existem no DEV com a
--     estrutura completa, apenas vazias.
--
--  3. SEGREGACAO POR OMISSAO, nao por DELETE:
--     - o schema `cron` nao entra no dump de estrutura  -> DEV nasce com ZERO cron
--     - `public.project_config` nao e semeada           -> invoke_edge_function()
--                                                          nao tem para onde apontar,
--                                                          logo o DEV nao chama a prod
--     - `api_keys`, `integration_secrets`, `organization_secrets` nao sao semeadas
--
--  4. DUAS EXCECOES em que um VALOR e substituido (a coluna continua existindo):
--     - integrations.is_active -> false   e  integrations.config -> '{}'
--       (a integracao aparece na UI, mas nao tem credencial e nao dispara)
--     - report_schedules.is_active -> false  e recipient_emails -> time de dev
--     Sem isso nao ha como ter "integracao visivel mas desligada".
--
--  5. auth.users NAO e clonado. Motivo: o schema `auth` do self-hosted e criado
--     pelo GoTrue do bootstrap e pode divergir em colunas do Cloud; alem disso
--     clonar 32 logins reais amplia superficie sem ganho. Crie os usuarios do
--     time no Studio do DEV depois. As 2 FKs de auditoria que apontam para
--     auth.users (campaign_workflows.added_by, message_templates.created_by)
--     ficam com referencia orfa — inofensivas, e por isso o seed roda com os
--     triggers de FK desligados (session_replication_role).
--
--  6. MOCKS (e-mails reais do time, vindos do Quimera):
--       joao.dessimoni@blips.com.br  ·  marcos.oliveira@finza.com.br
--       leandro.gontijo@blips.com.br ·  joaopedro@blips.com.br
--     Telefone: 999999999 para todos.
--     Nao ha unique no VALOR de email/phone (o unique e (contact_id, priority)),
--     portanto repetir o mesmo e-mail/telefone e seguro.
--     contacts.document E unique -> CPF/CNPJ ficticio, valido no digito
--     verificador e deterministico por id.
-- =====================================================================================

\set ON_ERROR_STOP on
\pset pager off
\timing off

-- ------------------------------------------------------------------------------------
-- 0 · Saida acumulada em ordem
-- ------------------------------------------------------------------------------------
CREATE TEMP TABLE _out (seq bigserial PRIMARY KEY, line text);

CREATE FUNCTION pg_temp.emit(p text) RETURNS void
LANGUAGE sql AS $$ INSERT INTO _out(line) VALUES (p); $$;

-- ------------------------------------------------------------------------------------
-- 1 · Helpers de anonimizacao
-- ------------------------------------------------------------------------------------

-- 1.1 · e-mail de dev, distribuido entre o time de forma estavel
CREATE FUNCTION pg_temp.dev_email(seed text) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT (ARRAY[
    'joao.dessimoni@blips.com.br',
    'marcos.oliveira@finza.com.br',
    'leandro.gontijo@blips.com.br',
    'joaopedro@blips.com.br'
  ])[1 + (get_byte(decode(md5(coalesce(seed,'x')),'hex'), 0) % 4)];
$$;

-- 1.2 · CPF ficticio valido (11 digitos, DV correto), deterministico
CREATE FUNCTION pg_temp.fake_cpf(seed text) RETURNS text
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE h text; b int[] := '{}'; i int; s int; d1 int; d2 int;
BEGIN
  h := md5(coalesce(seed,'x'));
  FOR i IN 1..9 LOOP
    b := b || (get_byte(decode(substr(h, i*2-1, 2),'hex'), 0) % 10);
  END LOOP;
  s := 0; FOR i IN 1..9 LOOP s := s + b[i] * (11 - i); END LOOP;
  d1 := 11 - (s % 11); IF d1 >= 10 THEN d1 := 0; END IF;
  s := 0; FOR i IN 1..9 LOOP s := s + b[i] * (12 - i); END LOOP;
  s := s + d1 * 2;
  d2 := 11 - (s % 11); IF d2 >= 10 THEN d2 := 0; END IF;
  RETURN array_to_string(b,'') || d1::text || d2::text;
END $$;

-- 1.3 · CNPJ ficticio valido (14 digitos, DV correto), deterministico
CREATE FUNCTION pg_temp.fake_cnpj(seed text) RETURNS text
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE h text; b int[] := '{}'; i int; s int; d1 int; d2 int;
        w1 int[] := ARRAY[5,4,3,2,9,8,7,6,5,4,3,2];
        w2 int[] := ARRAY[6,5,4,3,2,9,8,7,6,5,4,3,2];
BEGIN
  h := md5(coalesce(seed,'x') || 'cnpj');
  FOR i IN 1..12 LOOP
    b := b || (get_byte(decode(substr(h, i*2-1, 2),'hex'), 0) % 10);
  END LOOP;
  s := 0; FOR i IN 1..12 LOOP s := s + b[i] * w1[i]; END LOOP;
  d1 := 11 - (s % 11); IF d1 >= 10 THEN d1 := 0; END IF;
  s := 0; FOR i IN 1..12 LOOP s := s + b[i] * w2[i]; END LOOP;
  s := s + d1 * w2[13];
  d2 := 11 - (s % 11); IF d2 >= 10 THEN d2 := 0; END IF;
  RETURN array_to_string(b,'') || d1::text || d2::text;
END $$;

-- 1.4 · varredura de texto livre: troca e-mail, CNPJ, CPF e telefone por mock.
--       Ordem importa: CNPJ (14) antes de CPF (11), senao o regex de CPF come
--       os 11 primeiros digitos de um CNPJ.
--       Vies proposital: agressivo. Estragar um numero de contrato em dev e
--       inofensivo; deixar passar um CPF real nao e.
CREATE FUNCTION pg_temp.anon_text(t text) RETURNS text
LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
  IF t IS NULL THEN RETURN NULL; END IF;
  t := regexp_replace(t, '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}', 'dev-anon@blips.com.br', 'g');
  t := regexp_replace(t, '\d{2}\.?\d{3}\.?\d{3}/?\d{4}-?\d{2}', '00000000000000', 'g');
  t := regexp_replace(t, '\d{3}\.?\d{3}\.?\d{3}-?\d{2}',        '00000000000',    'g');
  t := regexp_replace(t, '(\+?55)?\s?\(?\d{2}\)?\s?9?\d{4}[- ]?\d{4}', '999999999', 'g');
  RETURN t;
END $$;

-- 1.4b · SCRUB DE SEGREDO — remove chaves por NOME, recursivamente.
--
--  Por que existe: em 2026-08-10, uma tentativa de redigir segredos removendo
--  nomes de chave ADIVINHADOS ('credentials', 'private_key', 'service_account')
--  passou ao lado de `credentials_json` em data_sources.connection_config, e uma
--  chave privada de service account GCP foi exposta. Adivinhar nome de chave nao
--  funciona. Este scrubber casa por PADRAO no nome, nao por lista.
--
--  Roda ANTES da anonimizacao de PII: segredo nao e PII, nao se anonimiza —
--  se remove.
--
--  Alvos conhecidos hoje:
--    data_sources.connection_config -> credentials_json  (chave privada GCP)
--    data_sources.query_config      -> sample_data, unique_values (PII cacheada da fonte)
--    integrations.config            -> headers, bodyTemplate, url (auth)
--    agent_llm_configs.additional_config / ai_agents.metadata (possiveis API keys)
CREATE FUNCTION pg_temp.scrub_secrets(j jsonb) RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE k text; v jsonb; acc jsonb;
        pat text := '(credential|secret|token|password|passwd|private[_-]?key|api[_-]?key'
                 || '|apikey|authorization|bearer|headers|body_?template|sample_data'
                 || '|unique_values|access[_-]?key|client[_-]?secret|webhook_url|url)';
BEGIN
  IF j IS NULL THEN RETURN NULL; END IF;
  CASE jsonb_typeof(j)
    WHEN 'object' THEN
      acc := '{}'::jsonb;
      FOR k, v IN SELECT key, value FROM jsonb_each(j) LOOP
        IF k ~* pat THEN
          acc := acc || jsonb_build_object(k, '[removido: segredo]'::jsonb);
        ELSE
          acc := acc || jsonb_build_object(k, pg_temp.scrub_secrets(v));
        END IF;
      END LOOP;
      RETURN acc;
    WHEN 'array' THEN
      RETURN (SELECT coalesce(jsonb_agg(pg_temp.scrub_secrets(e)), '[]'::jsonb)
                FROM jsonb_array_elements(j) e);
    ELSE
      RETURN j;
  END CASE;
END $$;

-- 1.5 · o mesmo, mas caminhando dentro de um jsonb.
--       Preserva TODAS as chaves e a estrutura; troca so valores string.
CREATE FUNCTION pg_temp.anon_jsonb(j jsonb) RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE k text; v jsonb; acc jsonb;
BEGIN
  IF j IS NULL THEN RETURN NULL; END IF;
  CASE jsonb_typeof(j)
    WHEN 'object' THEN
      acc := '{}'::jsonb;
      FOR k, v IN SELECT key, value FROM jsonb_each(j) LOOP
        acc := acc || jsonb_build_object(k, pg_temp.anon_jsonb(v));
      END LOOP;
      RETURN acc;
    WHEN 'array' THEN
      RETURN (SELECT coalesce(jsonb_agg(pg_temp.anon_jsonb(e)), '[]'::jsonb)
                FROM jsonb_array_elements(j) e);
    WHEN 'string' THEN
      RETURN to_jsonb(pg_temp.anon_text(j #>> '{}'));
    ELSE
      RETURN j;
  END CASE;
END $$;

-- ------------------------------------------------------------------------------------
-- 2 · Regra por coluna: devolve o trecho SQL que produz o LITERAL a ser embutido
--     no INSERT. O default preserva o valor com cast explicito de tipo.
-- ------------------------------------------------------------------------------------
CREATE FUNCTION pg_temp.col_expr(p_tbl text, p_col text, p_typ text) RETURNS text
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE keep text;
BEGIN
  keep := format('CASE WHEN t.%1$I IS NULL THEN ''NULL'' ELSE quote_literal(t.%1$I::text) || ''::%2$s'' END',
                 p_col, p_typ);

  -- ---- e-mail -------------------------------------------------------------
  IF p_col ~ '^(email|primary_email|user_email|contact_email)$' THEN
    RETURN format('CASE WHEN t.%1$I IS NULL THEN ''NULL'' ELSE quote_literal(pg_temp.dev_email(t.%1$I::text)) || ''::%2$s'' END',
                  p_col, p_typ);
  END IF;

  IF p_col = 'recipient_emails' THEN
    RETURN format('quote_literal(''{joao.dessimoni@blips.com.br}'') || ''::%s''', p_typ);
  END IF;

  -- ---- telefone -----------------------------------------------------------
  IF p_col ~ '^(phone|primary_phone|phone_e164|contact_phone|celular|whatsapp)$' THEN
    RETURN format('CASE WHEN t.%1$I IS NULL THEN ''NULL'' ELSE quote_literal(''999999999'') || ''::%2$s'' END',
                  p_col, p_typ);
  END IF;

  -- ---- documento (CPF/CNPJ) — unico e valido no DV ------------------------
  IF p_col ~ '^(document|document_number|contact_document)$' THEN
    RETURN format($x$CASE
        WHEN t.%1$I IS NULL THEN 'NULL'
        WHEN length(regexp_replace(t.%1$I::text, '\D', '', 'g')) > 11
          THEN quote_literal(pg_temp.fake_cnpj(t.%1$I::text)) || '::%2$s'
        ELSE quote_literal(pg_temp.fake_cpf(t.%1$I::text)) || '::%2$s'
      END$x$, p_col, p_typ);
  END IF;

  -- ---- destinatario real do envio (actions.recipient) --------------------
  IF p_tbl = 'actions' AND p_col = 'recipient' THEN
    RETURN format($x$CASE
        WHEN t.%1$I IS NULL THEN 'NULL'
        WHEN t.%1$I::text LIKE '%%@%%' THEN quote_literal(pg_temp.dev_email(t.%1$I::text)) || '::%2$s'
        ELSE quote_literal('999999999') || '::%2$s'
      END$x$, p_col, p_typ);
  END IF;

  -- ---- nome e endereco: SO nas tabelas de contato -------------------------
  --      (name/trading_name existem em campaigns, workflows, portfolios,
  --       tag_catalog etc. — ali sao nome de configuracao, nao PII)
  IF p_tbl IN ('contacts','contact_summaries') THEN
    IF p_col IN ('name','contact_name') THEN
      RETURN format('quote_literal(''Cliente DEV '' || upper(left(md5(t.%1$I::text), 6))) || ''::%2$s''',
                    p_col, p_typ);
    END IF;
    IF p_col = 'trading_name' THEN
      RETURN format('CASE WHEN t.%1$I IS NULL THEN ''NULL'' ELSE quote_literal(''Empresa DEV '' || upper(left(md5(t.%1$I::text), 6))) || ''::%2$s'' END',
                    p_col, p_typ);
    END IF;
  END IF;

  IF p_tbl = 'contacts' AND p_col LIKE 'address\_%' THEN
    RETURN CASE p_col
      WHEN 'address_street'       THEN format('CASE WHEN t.%1$I IS NULL THEN ''NULL'' ELSE quote_literal(''Rua de Teste'') || ''::%2$s'' END', p_col, p_typ)
      WHEN 'address_number'       THEN format('CASE WHEN t.%1$I IS NULL THEN ''NULL'' ELSE quote_literal(''100'') || ''::%2$s'' END', p_col, p_typ)
      WHEN 'address_complement'   THEN format('CASE WHEN t.%1$I IS NULL THEN ''NULL'' ELSE quote_literal(''-'') || ''::%2$s'' END', p_col, p_typ)
      WHEN 'address_neighborhood' THEN format('CASE WHEN t.%1$I IS NULL THEN ''NULL'' ELSE quote_literal(''Centro'') || ''::%2$s'' END', p_col, p_typ)
      WHEN 'address_zipcode'      THEN format('CASE WHEN t.%1$I IS NULL THEN ''NULL'' ELSE quote_literal(''00000000'') || ''::%2$s'' END', p_col, p_typ)
      ELSE keep   -- address_city / address_state ficam (uteis p/ filtro, nao identificam)
    END;
  END IF;

  -- ---- texto livre --------------------------------------------------------
  IF p_col IN ('notes','blocked_reason','target_value','user_notes') THEN
    RETURN format('CASE WHEN t.%1$I IS NULL THEN ''NULL'' ELSE quote_literal(pg_temp.anon_text(t.%1$I::text)) || ''::%2$s'' END',
                  p_col, p_typ);
  END IF;

  IF p_col = 'ip_address' THEN
    RETURN format('CASE WHEN t.%1$I IS NULL THEN ''NULL'' ELSE quote_literal(''127.0.0.1'') || ''::%2$s'' END',
                  p_col, p_typ);
  END IF;

  -- ---- desligar disparadores (excecao 4 do cabecalho) --------------------
  IF p_tbl IN ('integrations','report_schedules') AND p_col = 'is_active' THEN
    RETURN '''false''';
  END IF;
  IF p_tbl = 'integrations' AND p_col = 'config' THEN
    RETURN format('quote_literal(''{}'') || ''::%s''', p_typ);
  END IF;
  IF p_tbl = 'mv_refresh_config' AND p_col = 'enabled' THEN
    RETURN '''false''';
  END IF;
  IF p_tbl = 'mv_refresh_config' AND p_col = 'force_requested_at' THEN
    RETURN '''NULL''';
  END IF;

  -- ---- qualquer jsonb: scrub de segredo PRIMEIRO, depois PII -------------
  --      A ordem importa. Segredo se remove (scrub_secrets); PII se substitui
  --      (anon_jsonb). Aplicado a TODA coluna jsonb, sem lista de excecao —
  --      e o que impede o proximo `credentials_json` de escapar.
  IF p_typ = 'jsonb' THEN
    RETURN format('CASE WHEN t.%1$I IS NULL THEN ''NULL'' ELSE quote_literal(pg_temp.anon_jsonb(pg_temp.scrub_secrets(t.%1$I))::text) || ''::jsonb'' END',
                  p_col);
  END IF;

  RETURN keep;
END $$;

-- ------------------------------------------------------------------------------------
-- 3 · Emissor generico de INSERT
--     Le as colunas do catalogo (nunca de lista fixa), pula colunas geradas,
--     e usa OVERRIDING SYSTEM VALUE quando ha identity.
-- ------------------------------------------------------------------------------------
CREATE FUNCTION pg_temp.gen_inserts(p_sch text, p_tbl text, p_where text)
RETURNS SETOF text LANGUAGE plpgsql AS $$
DECLARE v_cols text; v_vals text; v_ident bool; v_ovr text; v_sql text;
BEGIN
  SELECT string_agg(quote_ident(a.attname), ', ' ORDER BY a.attnum),
         string_agg(pg_temp.col_expr(p_tbl, a.attname, format_type(a.atttypid, a.atttypmod)),
                    ' || '', '' || ' ORDER BY a.attnum),
         bool_or(a.attidentity = 'a')
    INTO v_cols, v_vals, v_ident
    FROM pg_attribute a
   WHERE a.attrelid = format('%I.%I', p_sch, p_tbl)::regclass
     AND a.attnum > 0
     AND NOT a.attisdropped
     AND a.attgenerated = '';

  IF v_cols IS NULL THEN RETURN; END IF;
  v_ovr := CASE WHEN v_ident THEN ' OVERRIDING SYSTEM VALUE' ELSE '' END;

  v_sql := format('SELECT %L || %s || %L FROM %I.%I t WHERE %s',
                  format('INSERT INTO %I.%I (%s)%s VALUES (', p_sch, p_tbl, v_cols, v_ovr),
                  v_vals,
                  ');',
                  p_sch, p_tbl, p_where);

  RETURN QUERY EXECUTE v_sql;
END $$;

-- ------------------------------------------------------------------------------------
-- 4 · Emissor com cabecalho, contagem e tolerancia a tabela ausente
-- ------------------------------------------------------------------------------------
CREATE FUNCTION pg_temp.emit_table(p_sch text, p_tbl text, p_where text DEFAULT 'true')
RETURNS void LANGUAGE plpgsql AS $$
DECLARE n bigint;
BEGIN
  IF to_regclass(format('%I.%I', p_sch, p_tbl)) IS NULL THEN
    PERFORM pg_temp.emit(format('-- [ignorado] %s.%s nao existe nesta org', p_sch, p_tbl));
    RETURN;
  END IF;

  EXECUTE format('SELECT count(*) FROM %I.%I t WHERE %s', p_sch, p_tbl, p_where) INTO n;

  IF n = 0 THEN
    PERFORM pg_temp.emit(format('-- %s.%s : 0 linha (nada a inserir)', p_sch, p_tbl));
    RETURN;
  END IF;

  PERFORM pg_temp.emit(format('-- %s.%s : %s linha(s)', p_sch, p_tbl, n));
  INSERT INTO _out(line) SELECT pg_temp.gen_inserts(p_sch, p_tbl, p_where);
  PERFORM pg_temp.emit('');
END $$;

-- ------------------------------------------------------------------------------------
-- 5 · Amostra: 100 contatos por org, deterministica
-- ------------------------------------------------------------------------------------
CREATE TEMP TABLE _sel (schema_name text, contact_id uuid);

-- Configuracao da amostra. Fica numa TEMP TABLE, e nao numa variavel \set do psql,
-- porque o psql NAO interpola variaveis (dois-pontos + nome) dentro de blocos
-- dollar-quoted ($$...$$) — usa-las dentro do DO abaixo daria erro de sintaxe.
-- Para sortear outros 100 clientes, troque a semente aqui.
CREATE TEMP TABLE _cfg (seed text, n int);
INSERT INTO _cfg VALUES ('seed-dev-2026-08-10', 100);

DO $$
DECLARE s text; v_seed text; v_n int;
BEGIN
  SELECT seed, n INTO v_seed, v_n FROM _cfg;

  FOR s IN SELECT nspname FROM pg_namespace WHERE nspname LIKE 'org\_%' ORDER BY 1 LOOP
    EXECUTE format($f$
      INSERT INTO _sel(schema_name, contact_id)
      SELECT %L, id
        FROM %I.contacts
       WHERE coalesce(is_active, true)
       ORDER BY md5(id::text || %L)
       LIMIT %s
    $f$, s, s, v_seed, v_n);
  END LOOP;
END $$;

-- ------------------------------------------------------------------------------------
-- 6 · Montagem do arquivo de saida
-- ------------------------------------------------------------------------------------
SELECT pg_temp.emit('-- ===================================================================');
SELECT pg_temp.emit('--  02_dados.sql · SEED DO SUPABASE DEV (self-hosted GCP)');
SELECT pg_temp.emit('--  Gerado por 2026-08-10_torre_gerar-seed-dev.sql');
SELECT pg_temp.emit('--  Gerado em: ' || now()::text);
SELECT pg_temp.emit('--  Amostra: ' || (SELECT count(*) FROM _sel) || ' contatos ('
                    || (SELECT string_agg(DISTINCT schema_name, ' + ' ORDER BY schema_name) FROM _sel) || ')');
SELECT pg_temp.emit('--  ATENCAO: rodar SOMENTE no DEV. Nunca em producao.');
SELECT pg_temp.emit('-- ===================================================================');
SELECT pg_temp.emit('');
SELECT pg_temp.emit('\set ON_ERROR_STOP on');
SELECT pg_temp.emit('BEGIN;');
SELECT pg_temp.emit('');
SELECT pg_temp.emit('-- Desliga os triggers de FK durante a carga. Isso torna a ordem dos');
SELECT pg_temp.emit('-- INSERTs irrelevante e resolve as FKs circulares (workflows <-> ');
SELECT pg_temp.emit('-- workflow_versions, workflow_steps -> proprio workflow_steps).');
SELECT pg_temp.emit('-- Requer superusuario. A integridade e conferida depois, no 03_validacao.sql.');
SELECT pg_temp.emit('SET session_replication_role = replica;');
SELECT pg_temp.emit('');

-- 6.1 · control plane (public) ------------------------------------------------------
SELECT pg_temp.emit('-- ============ public · control plane ============');
SELECT pg_temp.emit_table('public', 'organizations');
SELECT pg_temp.emit_table('public', 'marketplace_integrations');   -- FK de workflow_steps.integration_id
SELECT pg_temp.emit_table('public', 'mv_refresh_config');          -- entra com enabled = false
SELECT pg_temp.emit('-- NAO semeados de proposito: project_config, api_keys,');
SELECT pg_temp.emit('-- organization_secrets, user_invitations, organization_users.');
SELECT pg_temp.emit('-- (segregacao: sem eles o DEV nao alcanca prod nem canal externo)');
SELECT pg_temp.emit('');

-- 6.2 · por org --------------------------------------------------------------------
DO $$
DECLARE
  s          text;
  v_contacts text;
  v_contract text;
  v_title    text;
  v_action   text;
  v_n        int;
BEGIN
  SELECT n INTO v_n FROM _cfg;

  FOR s IN SELECT DISTINCT schema_name FROM _sel ORDER BY 1 LOOP

    v_contacts := format('(SELECT contact_id FROM _sel WHERE schema_name = %L)', s);
    v_contract := format('(SELECT id FROM %I.contracts WHERE contact_id IN %s)', s, v_contacts);
    v_title    := format('(SELECT id FROM %I.titles WHERE contract_id IN %s)',  s, v_contract);
    -- somente as actions REFERENCIADAS pelos titulos selecionados (mantem a FK valida
    -- sem trazer o historico operacional inteiro)
    v_action   := format($a$(
        SELECT attributed_action_id   FROM %1$I.titles WHERE contract_id IN %2$s AND attributed_action_id   IS NOT NULL
        UNION SELECT negativation_action_id FROM %1$I.titles WHERE contract_id IN %2$s AND negativation_action_id IS NOT NULL
        UNION SELECT notification_action_id FROM %1$I.titles WHERE contract_id IN %2$s AND notification_action_id IS NOT NULL
      )$a$, s, v_contract);

    PERFORM pg_temp.emit(format('-- ================================================================'));
    PERFORM pg_temp.emit(format('-- ============ %s ============', s));
    PERFORM pg_temp.emit(format('-- ================================================================'));
    PERFORM pg_temp.emit('');

    -- catalogos e valores de dominio
    PERFORM pg_temp.emit('-- ---- catalogos / dominio ----');
    PERFORM pg_temp.emit_table(s, 'standard_values');
    PERFORM pg_temp.emit_table(s, 'tag_catalog');
    PERFORM pg_temp.emit_table(s, 'seal_catalog');
    PERFORM pg_temp.emit_table(s, 'custom_field_definitions');
    PERFORM pg_temp.emit_table(s, 'custom_variables');
    PERFORM pg_temp.emit_table(s, 'blocked_dates');
    PERFORM pg_temp.emit_table(s, 'channel_costs');
    PERFORM pg_temp.emit_table(s, 'channel_rate_limits');
    PERFORM pg_temp.emit_table(s, 'sending_controls');
    PERFORM pg_temp.emit_table(s, 'blocklist_filter_rules');

    -- ETL
    PERFORM pg_temp.emit('-- ---- ETL ----');
    PERFORM pg_temp.emit_table(s, 'data_sources');
    PERFORM pg_temp.emit_table(s, 'data_source_skills');
    PERFORM pg_temp.emit_table(s, 'etl_pipelines');

    -- filtros e carteiras
    PERFORM pg_temp.emit('-- ---- filtros / carteiras ----');
    PERFORM pg_temp.emit_table(s, 'filter_definitions');
    PERFORM pg_temp.emit_table(s, 'portfolios');
    PERFORM pg_temp.emit_table(s, 'portfolio_integrations');

    -- campanhas e reguas
    PERFORM pg_temp.emit('-- ---- campanhas / reguas ----');
    PERFORM pg_temp.emit_table(s, 'campaigns');
    PERFORM pg_temp.emit_table(s, 'workflow_versions');
    PERFORM pg_temp.emit_table(s, 'workflows');
    PERFORM pg_temp.emit_table(s, 'workflow_steps');
    PERFORM pg_temp.emit_table(s, 'campaign_workflows');
    PERFORM pg_temp.emit_table(s, 'message_templates');

    -- integracoes (DESLIGADAS, sem credencial)
    PERFORM pg_temp.emit('-- ---- integracoes (is_active=false, config={}) ----');
    PERFORM pg_temp.emit_table(s, 'integrations');
    PERFORM pg_temp.emit('-- integration_secrets NAO e semeada (segredo de prod nao desce)');
    PERFORM pg_temp.emit('');

    -- relatorios agendados (DESLIGADOS)
    PERFORM pg_temp.emit('-- ---- relatorios agendados (is_active=false) ----');
    PERFORM pg_temp.emit_table(s, 'report_schedules');

    -- IA
    PERFORM pg_temp.emit('-- ---- configuracao de IA ----');
    PERFORM pg_temp.emit_table(s, 'ai_versions');
    PERFORM pg_temp.emit_table(s, 'ai_agents');
    PERFORM pg_temp.emit_table(s, 'ai_prompts');
    PERFORM pg_temp.emit_table(s, 'ai_guidelines');
    PERFORM pg_temp.emit_table(s, 'ai_business_rules');
    PERFORM pg_temp.emit_table(s, 'ai_funnel_stages');
    PERFORM pg_temp.emit_table(s, 'agent_llm_configs');
    PERFORM pg_temp.emit_table(s, 'agent_allowed_tags');
    PERFORM pg_temp.emit_table(s, 'a2a_closure_config');

    -- RAG
    PERFORM pg_temp.emit('-- ---- RAG ----');
    PERFORM pg_temp.emit_table(s, 'rag_documents');
    PERFORM pg_temp.emit_table(s, 'rag_chunks');

    -- os 100 clientes
    PERFORM pg_temp.emit(format('-- ---- os %s clientes da amostra (anonimizados) ----', v_n));
    PERFORM pg_temp.emit_table(s, 'contacts',          format('t.id IN %s', v_contacts));
    PERFORM pg_temp.emit_table(s, 'contact_emails',    format('t.contact_id IN %s', v_contacts));
    PERFORM pg_temp.emit_table(s, 'contact_phones',    format('t.contact_id IN %s', v_contacts));
    PERFORM pg_temp.emit_table(s, 'contact_summaries', format('t.contact_id IN %s', v_contacts));
    PERFORM pg_temp.emit_table(s, 'contact_seals',     format('t.contact_id IN %s', v_contacts));
    PERFORM pg_temp.emit_table(s, 'contact_assignments', format('t.contact_id IN %s', v_contacts));
    PERFORM pg_temp.emit_table(s, 'blocklist',         format('t.contact_id IN %s', v_contacts));

    PERFORM pg_temp.emit_table(s, 'contracts',           format('t.contact_id IN %s', v_contacts));
    PERFORM pg_temp.emit_table(s, 'contract_portfolios', format('t.contract_id IN %s', v_contract));
    PERFORM pg_temp.emit_table(s, 'contract_seals',      format('t.contract_id IN %s', v_contract));

    PERFORM pg_temp.emit('-- actions: SO as referenciadas por titles (FK), nao o historico');
    PERFORM pg_temp.emit_table(s, 'actions',    format('t.id IN %s', v_action));

    PERFORM pg_temp.emit_table(s, 'titles',      format('t.contract_id IN %s', v_contract));
    PERFORM pg_temp.emit_table(s, 'title_seals', format('t.title_id IN %s', v_title));

    PERFORM pg_temp.emit('');
  END LOOP;
END $$;

-- 6.3 · fechamento -----------------------------------------------------------------
SELECT pg_temp.emit('-- ============ fechamento ============');
SELECT pg_temp.emit('SET session_replication_role = DEFAULT;');
SELECT pg_temp.emit('');
SELECT pg_temp.emit('COMMIT;');
SELECT pg_temp.emit('');
SELECT pg_temp.emit('-- Materializar as views (elas nascem vazias no DEV).');
SELECT pg_temp.emit('-- Sem isto, vw_titles_live devolve zero linha e o app parece vazio.');

DO $$
DECLARE s text;
BEGIN
  FOR s IN SELECT DISTINCT schema_name FROM _sel ORDER BY 1 LOOP
    PERFORM pg_temp.emit(format('REFRESH MATERIALIZED VIEW %I.mv_titles_base;', s));
  END LOOP;
END $$;

SELECT pg_temp.emit('');
SELECT pg_temp.emit('ANALYZE;');
SELECT pg_temp.emit('');
SELECT pg_temp.emit('-- Proximo passo: rodar 03_validacao.sql (gates G1..G10).');

-- ------------------------------------------------------------------------------------
-- 7 · Imprime o arquivo
-- ------------------------------------------------------------------------------------
SELECT line FROM _out ORDER BY seq;
