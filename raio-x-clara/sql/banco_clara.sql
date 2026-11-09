-- =====================================================================
-- Banco da Clara (skill raio-x-clara) (credencial "Clara v2", id NnKgQ1T7ShqIvQHD, n8n-prod-assistants)
-- ATENÇÃO: é a mesma credencial dos nós Postgres do fluxo "Clara - Formalização".
-- Outra credencial Postgres aponta para outro banco e devolve "relation ... does not exist".
-- SOMENTE LEITURA. Nenhuma consulta altera dado.
--
-- Como rodar: execute cada bloco Qn separadamente e exporte o resultado
-- como CSV (separador vírgula, com cabeçalho) com o nome indicado em
-- "Arquivo:", dentro de <pasta_saida>/clara-db/.
--
-- Dado pessoal: nenhuma consulta exporta nome, CNPJ, CPF, URL de arquivo
-- ou conteúdo extraído do documento. Telefone sai reduzido a DDD + 8
-- últimos dígitos, que é a chave usada para cruzar com a plataforma.
--
-- Janela: troque 2026-08-01 pela data de início do relatório (a Clara v2 entrou em 03/08/2026).
-- Todas as datas saem em BRT.
-- =====================================================================


-- Q1 — Negociações que a Clara conheceu
-- Arquivo: q1_negociacoes.csv
-- Para: universo da Clara por contrato e canal (CLA-02).
SELECT n.negotiation_id,
       n.canal,
       n.origem,
       n.segmento,
       n.fase_correta,
       n.status,
       n.coleta_forcada,
       (n.created_at AT TIME ZONE 'America/Sao_Paulo') AS criado_brt,
       (n.updated_at AT TIME ZONE 'America/Sao_Paulo') AS atualizado_brt,
       CASE WHEN length(regexp_replace(n.telefone,'[^0-9]','','g')) >= 10
            THEN substr(regexp_replace(regexp_replace(n.telefone,'[^0-9]','','g'),'^55(?=\d{10,11}$)',''),1,2)
                 || right(regexp_replace(n.telefone,'[^0-9]','','g'),8)
       END AS chave_tel
FROM negotiations_clara n
WHERE n.created_at >= timestamptz '2026-08-01 00:00 America/Sao_Paulo'
ORDER BY n.created_at;


-- Q2 — Mensagens por conversa: acionamento, resposta e envio de arquivo
-- Arquivo: q2_mensagens.csv
-- Para: etapas "Respondeu" e "Enviou documento" (CLA-02) e o número de
--       envios de arquivo por conversa (proxy de retrabalho, CLA-05).
-- Armadilha respeitada: o acionamento também é linha (event = 'inicio').
WITH m AS (
  SELECT chat_key,
         payload->>'event' AS evento,
         COALESCE((payload->>'recebido_em')::timestamptz, created_at) AS quando,
         (COALESCE(payload->>'midia_url','') <> ''
          OR (jsonb_typeof(payload->'midias') = 'array' AND jsonb_array_length(payload->'midias') > 0)) AS tem_midia,
         CASE WHEN jsonb_typeof(payload->'midias') = 'array' THEN jsonb_array_length(payload->'midias')
              WHEN COALESCE(payload->>'midia_url','') <> '' THEN 1 ELSE 0 END AS qtd_midias,
         lower(substring(COALESCE(payload->>'midia_file_name', payload->>'midia_url','') from '\.([A-Za-z0-9]{2,5})(\?|$)')) AS extensao
  FROM chat_messages_clara
  WHERE created_at >= timestamptz '2026-08-01 00:00 America/Sao_Paulo'
)
SELECT CASE WHEN chat_key ~ '^[0-9a-f]{24}$' THEN chat_key END AS negotiation_id,
       CASE WHEN chat_key !~ '^[0-9a-f]{24}$' AND length(regexp_replace(chat_key,'[^0-9]','','g')) >= 10
            THEN substr(regexp_replace(regexp_replace(chat_key,'[^0-9]','','g'),'^55(?=\d{10,11}$)',''),1,2)
                 || right(regexp_replace(chat_key,'[^0-9]','','g'),8)
       END AS chave_tel,
       COUNT(*) FILTER (WHERE evento = 'inicio')                         AS n_inicio,
       MIN(quando) FILTER (WHERE evento = 'inicio') AT TIME ZONE 'America/Sao_Paulo'   AS primeiro_inicio_brt,
       COUNT(*) FILTER (WHERE COALESCE(evento,'') <> 'inicio')           AS n_msgs_cliente,
       MIN(quando) FILTER (WHERE COALESCE(evento,'') <> 'inicio') AT TIME ZONE 'America/Sao_Paulo' AS primeira_resposta_brt,
       COUNT(*) FILTER (WHERE tem_midia AND COALESCE(evento,'') <> 'inicio')           AS n_msgs_com_arquivo,
       SUM(qtd_midias) FILTER (WHERE COALESCE(evento,'') <> 'inicio')                  AS n_arquivos,
       MIN(quando) FILTER (WHERE tem_midia AND COALESCE(evento,'') <> 'inicio') AT TIME ZONE 'America/Sao_Paulo' AS primeiro_arquivo_brt,
       MAX(quando) FILTER (WHERE tem_midia AND COALESCE(evento,'') <> 'inicio') AT TIME ZONE 'America/Sao_Paulo' AS ultimo_arquivo_brt,
       STRING_AGG(DISTINCT extensao, '|') FILTER (WHERE tem_midia)        AS extensoes
FROM m
GROUP BY 1,2
ORDER BY 4 NULLS LAST;


-- Q3 — Documentos registrados pela Clara, por tipo
-- Arquivo: q3_documentos.csv
-- Para: pendências por tipo de documento (CLA-04) e etapa "Enviou documento".
-- Só metadados: o conteúdo de "dados" (titular, CEP, endereço) NÃO sai.
SELECT d.negotiation_id,
       d.tipo,
       d.status,
       (d.created_at AT TIME ZONE 'America/Sao_Paulo') AS registrado_brt,
       d.mime,
       lower(substring(COALESCE(d.file_name, d.url, '') from '\.([A-Za-z0-9]{2,5})(\?|$)')) AS extensao,
       (SELECT COUNT(*) FROM jsonb_object_keys(COALESCE(d.dados,'{}'::jsonb))) AS qtd_campos_extraidos
FROM documents_clara d
WHERE d.created_at >= timestamptz '2026-08-01 00:00 America/Sao_Paulo'
ORDER BY d.created_at;


-- Q4a — Teste de formato da memória da Clara (rodar ANTES do Q4)
-- Arquivo: q4a_amostra.csv
-- Mostra 3 trechos curtos, com todos os dígitos trocados por 9, ao redor
-- do veredito da pré-análise. Serve para eu confirmar o padrão do Q4.
SELECT id,
       regexp_replace(
         substring(message::text from greatest(1, position('aprovado_prefiltro' in message::text) - 400) for 900),
         '[0-9]', '9', 'g') AS trecho
FROM chat_history_clara
WHERE message::text LIKE '%aprovado_prefiltro%'
ORDER BY id DESC
LIMIT 3;


-- Q4 — Vereditos da pré-análise de documentos, um por tentativa
-- Arquivo: q4_vereditos.csv
-- Para: documento aprovado/reprovado (CLA-02), motivo da reprova por tipo
--       (CLA-04), tentativas até aprovar (CLA-05) e aprovação sem ajuste (CLA-01).
-- A memória do agente guarda as chamadas de ferramenta com entrada e resultado.
-- Cada ocorrência de "aprovado_prefiltro" vira uma linha.
WITH h AS (
  SELECT id, session_id, message::text AS txt
  FROM chat_history_clara
  WHERE message::text LIKE '%aprovado_prefiltro%'
),
v AS (
  SELECT h.id, h.session_id, x.ord,
         x.m[1] AS aprovado_prefiltro
  FROM h, LATERAL regexp_matches(h.txt, 'aprovado_prefiltro\\*"\s*:\s*(true|false)', 'g') WITH ORDINALITY AS x(m, ord)
),
t AS (
  SELECT h.id, x.ord, x.m[1] AS tipo_detectado
  FROM h, LATERAL regexp_matches(h.txt, 'tipo_detectado\\*"\s*:\s*\\*"([^"\\]*)', 'g') WITH ORDINALITY AS x(m, ord)
),
e AS (
  SELECT h.id, x.ord, x.m[1] AS tipo_esperado
  FROM h, LATERAL regexp_matches(h.txt, 'tipo_esperado\\*"\s*:\s*\\*"([^"\\]*)', 'g') WITH ORDINALITY AS x(m, ord)
),
mo AS (
  SELECT h.id, x.ord, left(x.m[1], 160) AS motivo
  FROM h, LATERAL regexp_matches(h.txt, 'motivo\\*"\s*:\s*\\*"([^"\\]*)', 'g') WITH ORDINALITY AS x(m, ord)
),
f AS (
  SELECT h.id, x.ord, x.m[1] AS fraude
  FROM h, LATERAL regexp_matches(h.txt, 'fraude\\*"\s*:\s*(true|false)', 'g') WITH ORDINALITY AS x(m, ord)
)
SELECT v.id AS mensagem_id,
       v.ord AS ordem_na_mensagem,
       CASE WHEN v.session_id ~ '^\d{10,13}-\d{4}-\d{2}-\d{2}$'
            THEN substr(regexp_replace(split_part(v.session_id,'-',1),'^55(?=\d{10,11}$)',''),1,2)
                 || right(split_part(v.session_id,'-',1),8)
       END AS chave_tel,
       CASE WHEN v.session_id ~ '^\d{10,13}-\d{4}-\d{2}-\d{2}$'
            THEN substring(v.session_id from '\d{4}-\d{2}-\d{2}$')
       END AS dia_sessao,
       CASE WHEN v.session_id !~ '^\d{10,13}-\d{4}-\d{2}-\d{2}$' THEN v.session_id END AS conversa_id,
       v.aprovado_prefiltro,
       e.tipo_esperado,
       t.tipo_detectado,
       f.fraude,
       regexp_replace(mo.motivo, '[0-9]', '9', 'g') AS motivo
FROM v
LEFT JOIN e  ON e.id  = v.id AND e.ord  = v.ord
LEFT JOIN t  ON t.id  = v.id AND t.ord  = v.ord
LEFT JOIN mo ON mo.id = v.id AND mo.ord = v.ord
LEFT JOIN f  ON f.id  = v.id AND f.ord  = v.ord
ORDER BY v.id, v.ord;


-- Q5 — Conferência rápida de volume (para eu validar os arquivos acima)
-- Arquivo: q5_volumes.csv
SELECT 'negotiations_clara' AS tabela, COUNT(*) AS linhas, MIN(created_at) AT TIME ZONE 'America/Sao_Paulo' AS mais_antiga FROM negotiations_clara
UNION ALL SELECT 'chat_messages_clara', COUNT(*), MIN(created_at) AT TIME ZONE 'America/Sao_Paulo' FROM chat_messages_clara
UNION ALL SELECT 'documents_clara', COUNT(*), MIN(created_at) AT TIME ZONE 'America/Sao_Paulo' FROM documents_clara
UNION ALL SELECT 'chat_history_clara', COUNT(*), NULL FROM chat_history_clara
UNION ALL SELECT 'chat_history_clara com veredito', COUNT(*), NULL FROM chat_history_clara WHERE message::text LIKE '%aprovado_prefiltro%';


-- Q6 — Decisões do time sobre o que a Clara coletou (aprovar / reprovar)
-- Arquivo: q6_decisoes.csv
-- Para: CLA-01 (aprovado pelo time) e o motivo de quem tem kit completo
--       mas não foi aprovado. Tabela criada pelo fluxo "[Clara] Webhook -
--       decisão formalização" (82XTClppueXroKLW). Leve: poucas centenas de linhas.
-- Rodar num nó ligado direto no gatilho (ou com "Execute Once").
SELECT negotiation_id,
       decisao,
       left(regexp_replace(COALESCE(motivo,''), '[0-9]', '9', 'g'), 160) AS motivo,
       (created_at AT TIME ZONE 'America/Sao_Paulo') AS decidido_brt
FROM decisoes_clara
ORDER BY created_at;
