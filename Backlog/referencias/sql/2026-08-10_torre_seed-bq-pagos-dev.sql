-- =====================================================================================
--  FONTE DE DADOS DEV — "Pagos - Modulo Financeiro" (100 clientes, anonimizada)
--  BTR10 · Torre de Controle self-hosted (GCP)
--  Dialeto: GoogleSQL (BigQuery).  Projeto de billing: blips-bigdata
--  Criado: 2026-08-10
-- =====================================================================================
--
--  Par do arquivo `2026-08-10_torre_seed-bq-disponivel-dev.sql`. Mesmas regras de
--  anonimizacao e de amostra — leia o cabecalho daquele arquivo para o racional
--  completo. Aqui ficam apenas as diferencas desta fonte.
--
--  CONTRATO: 35 colunas, identico a fonte "Pagos - Modulo Financeiro" de producao.
--
--  A ANONIMIZACAO ACONTECE DENTRO DO BIGQUERY. A PII real nunca sai do BQ.
--
-- -------------------------------------------------------------------------------------
--  DIFERENCA DELIBERADA EM RELACAO A PRODUCAO — a janela de pagamento
-- -------------------------------------------------------------------------------------
--  Em producao esta fonte olha os ultimos 2 DIAS, porque e um sync incremental que
--  roda de hora em hora. Num seed de dev isso traria quase nada — e um ambiente sem
--  titulo pago nao permite testar recuperacao, atribuicao nem dashboard de pagamento.
--
--  Por isso a janela aqui e de 90 DIAS. E uma escolha de seed, nao uma mudanca de
--  contrato: as COLUNAS sao as mesmas. Ajuste em JANELA_DIAS abaixo se quiser outra.
--
--  Consequencia a ter em mente: se voce depois configurar esta query como sync
--  RECORRENTE no DEV, volte para 2 dias, senao cada execucao reprocessa 90 dias.
--  Para carga inicial, 90 e o certo.
-- -------------------------------------------------------------------------------------
--  ALINHAMENTO DE AMOSTRA
-- -------------------------------------------------------------------------------------
--  A semente e a MESMA do arquivo Disponivel ('seed-dev-2026-08-10'). Isso e
--  intencional: onde os conjuntos de clientes se cruzarem, o MESMO cliente real
--  recebe o MESMO documento/nome/e-mail falso nas duas fontes. Sem isso, o mesmo
--  cliente entraria no DEV como duas pessoas diferentes e o dedup do ETL quebraria.
--
--  Se voce mudar a semente em um arquivo, mude nos DOIS.
-- =====================================================================================

WITH
  -- ---------------------------------------------------------------------------
  -- Parametro da janela de pagamento (ver cabecalho)
  -- ---------------------------------------------------------------------------
  PARAM AS (SELECT 90 AS JANELA_DIAS),

  -- ---------------------------------------------------------------------------
  -- BASE — consulta de producao sem mock. Nao e retornada.
  -- ---------------------------------------------------------------------------
  BASE AS (
    SELECT
      deals.customer.fullname AS razao_social_real,
      CASE
        WHEN negotiation.contractor.personal_data.name IS NULL
          OR negotiation.contractor.personal_data.name = ''
          THEN deals.customer.fullname
        ELSE negotiation.contractor.personal_data.name
      END AS nome_contato_real,
      CAST(deals.customer.document AS STRING) AS documento_real,

      COALESCE(
        NULLIF(negotiation.contractor.business_data.address.city, ''),
        NULLIF(negotiation.contractor.personal_data.address.city, '')
      ) AS endereco_cidade,
      COALESCE(
        NULLIF(negotiation.contractor.business_data.address.state, ''),
        NULLIF(negotiation.contractor.personal_data.address.state, '')
      ) AS endereco_estado,

      deals.contract.number              AS id_contrato,
      deals.contract.type                AS modalidade_contrato,
      deals.contract.product_description AS produto_contrato,
      deals.contract.segment             AS segmento_contrato,
      deals.payment_breakdown.total_amount AS valor_total_contrato,
      deals.payment_breakdown.down_payment AS valor_contrato_pago,
      deals.payment_breakdown.installments_paramenters.num_installments
        AS quant_parcelas_contrato,
      (
        SELECT COUNT(*) FROM UNNEST(deals.installments) AS i
        WHERE i.payment_date IS NULL
          AND i.status NOT IN ('Pago', 'Cancelado', 'Removido')
      ) AS parcelas_em_aberto,
      deals.status.status AS status_contrato,

      TO_JSON_STRING(ARRAY(
        SELECT DISTINCT t.label FROM UNNEST(negotiation.tags) AS t
        WHERE t.label IS NOT NULL ORDER BY t.label
      )) AS tags_label,
      negotiation.flags.legal_analysis.value AS analise_juridica,
      deals.contract.grantor_name AS empresa_contrato,

      installments.our_number  AS id_titulo,
      installments.value       AS valor_titulo,
      DATE(PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', installments.due_date))     AS data_vencimento_titulo,
      DATE(PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', installments.payment_date)) AS data_pagamento_titulo,
      installments.received_value     AS valor_pago_titulo,
      installments.installment_number AS num_parcela_titulo,
      installments.status             AS status_titulo,
      installments.financial_institution.nickname_financial AS instituicao_titulo

    FROM `blips-bigdata.bronze_mongodb_moduloFinanceiro.deals` AS deals,
      UNNEST(deals.installments) AS installments
    LEFT JOIN `blips-bigdata.PLATAFORMA.negotiation` AS negotiation
      ON deals.contract.number = negotiation.contract_number
    CROSS JOIN PARAM
    WHERE
      (
        (
          installments.status = 'Pago'
          AND DATE(PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', installments.payment_date))
                >= DATE_SUB(CURRENT_DATE(), INTERVAL PARAM.JANELA_DIAS DAY)
        )
        OR (
          installments.status = 'Pago'
          AND (installments.payment_date IS NULL OR installments.payment_date = '')
          -- so aceita pago-sem-data se houver valor recebido (evita desync de
          -- status na fonte sem liquidacao) — regra identica a producao
          AND installments.received_value > 0
        )
      )
      AND deals.contract.product_description IS NOT NULL
      AND deals.contract.product_description != ''
      AND deals.contract.number IS NOT NULL
      AND deals.contract.number != ''
      AND installments.our_number IS NOT NULL
      AND installments.our_number != ''
      AND installments.status IS NOT NULL
      AND UPPER(deals.contract.grantor_name) NOT LIKE '%FINZA%'
      AND deals.customer.document IS NOT NULL
  ),

  -- ---------------------------------------------------------------------------
  -- AMOSTRA — 100 clientes distintos. MESMA semente do arquivo Disponivel.
  -- ---------------------------------------------------------------------------
  AMOSTRA AS (
    SELECT documento_real
    FROM (SELECT DISTINCT documento_real FROM BASE)
    ORDER BY FARM_FINGERPRINT(CONCAT(documento_real, 'seed-dev-2026-08-10'))
    LIMIT 100
  ),

  -- ---------------------------------------------------------------------------
  -- MOCK — identidade falsa deterministica (identico ao arquivo Disponivel,
  -- para que o mesmo cliente real produza o mesmo cliente falso nas duas fontes)
  -- ---------------------------------------------------------------------------
  MOCK_BASE AS (
    SELECT
      documento_real,
      LENGTH(REGEXP_REPLACE(documento_real, r'\D', '')) > 11 AS is_cnpj,
      MOD(ABS(FARM_FINGERPRINT(CONCAT(documento_real, '#cpf'))),  900000000)    + 100000000    AS b9,
      MOD(ABS(FARM_FINGERPRINT(CONCAT(documento_real, '#cnpj'))), 900000000000) + 100000000000 AS b12
    FROM AMOSTRA
  ),
  MOCK_DIG AS (
    SELECT
      documento_real, is_cnpj, b9, b12,
      MOD(DIV(b9, 100000000), 10) AS c1, MOD(DIV(b9, 10000000), 10) AS c2,
      MOD(DIV(b9,  1000000), 10) AS c3, MOD(DIV(b9,   100000), 10) AS c4,
      MOD(DIV(b9,    10000), 10) AS c5, MOD(DIV(b9,     1000), 10) AS c6,
      MOD(DIV(b9,      100), 10) AS c7, MOD(DIV(b9,       10), 10) AS c8,
      MOD(    b9,            10) AS c9,
      MOD(DIV(b12, 100000000000), 10) AS n1, MOD(DIV(b12, 10000000000), 10) AS n2,
      MOD(DIV(b12,  1000000000), 10) AS n3, MOD(DIV(b12,   100000000), 10) AS n4,
      MOD(DIV(b12,    10000000), 10) AS n5, MOD(DIV(b12,     1000000), 10) AS n6,
      MOD(DIV(b12,      100000), 10) AS n7, MOD(DIV(b12,       10000), 10) AS n8,
      MOD(DIV(b12,        1000), 10) AS n9, MOD(DIV(b12,         100), 10) AS n10,
      MOD(DIV(b12,          10), 10) AS n11, MOD(    b12,          10) AS n12
    FROM MOCK_BASE
  ),
  MOCK_DV1 AS (
    SELECT *,
      CASE WHEN 11 - MOD(c1*10 + c2*9 + c3*8 + c4*7 + c5*6 + c6*5 + c7*4 + c8*3 + c9*2, 11) >= 10
           THEN 0
           ELSE 11 - MOD(c1*10 + c2*9 + c3*8 + c4*7 + c5*6 + c6*5 + c7*4 + c8*3 + c9*2, 11)
      END AS cdv1,
      CASE WHEN 11 - MOD(n1*5 + n2*4 + n3*3 + n4*2 + n5*9 + n6*8 + n7*7 + n8*6 + n9*5 + n10*4 + n11*3 + n12*2, 11) >= 10
           THEN 0
           ELSE 11 - MOD(n1*5 + n2*4 + n3*3 + n4*2 + n5*9 + n6*8 + n7*7 + n8*6 + n9*5 + n10*4 + n11*3 + n12*2, 11)
      END AS ndv1
    FROM MOCK_DIG
  ),
  MOCK_DV2 AS (
    SELECT *,
      CASE WHEN 11 - MOD(c1*11 + c2*10 + c3*9 + c4*8 + c5*7 + c6*6 + c7*5 + c8*4 + c9*3 + cdv1*2, 11) >= 10
           THEN 0
           ELSE 11 - MOD(c1*11 + c2*10 + c3*9 + c4*8 + c5*7 + c6*6 + c7*5 + c8*4 + c9*3 + cdv1*2, 11)
      END AS cdv2,
      CASE WHEN 11 - MOD(n1*6 + n2*5 + n3*4 + n4*3 + n5*2 + n6*9 + n7*8 + n8*7 + n9*6 + n10*5 + n11*4 + n12*3 + ndv1*2, 11) >= 10
           THEN 0
           ELSE 11 - MOD(n1*6 + n2*5 + n3*4 + n4*3 + n5*2 + n6*9 + n7*8 + n8*7 + n9*6 + n10*5 + n11*4 + n12*3 + ndv1*2, 11)
      END AS ndv2
    FROM MOCK_DV1
  ),
  MOCK AS (
    SELECT
      documento_real,
      CASE WHEN is_cnpj
           THEN CONCAT(CAST(b12 AS STRING), CAST(ndv1 AS STRING), CAST(ndv2 AS STRING))
           ELSE CONCAT(CAST(b9  AS STRING), CAST(cdv1 AS STRING), CAST(cdv2 AS STRING))
      END AS documento_fake,
      CONCAT('Cliente DEV ', UPPER(SUBSTR(TO_HEX(MD5(documento_real)), 1, 6))) AS nome_fake,
      CONCAT('Empresa DEV ', UPPER(SUBSTR(TO_HEX(MD5(documento_real)), 1, 6))) AS razao_fake,
      [ 'joao.dessimoni@blips.com.br',
        'marcos.oliveira@finza.com.br',
        'leandro.gontijo@blips.com.br',
        'joaopedro@blips.com.br'
      ][OFFSET(MOD(ABS(FARM_FINGERPRINT(documento_real)), 4))] AS email_fake
    FROM MOCK_DV2
  )

-- =====================================================================================
--  SAIDA — 35 colunas, mesmo contrato da fonte de producao.
-- =====================================================================================
SELECT
  -- identidade: FALSA
  m.razao_fake      AS razao_social,
  m.nome_fake       AS nome_contato,
  m.documento_fake  AS documento_contato,
  '999999999'       AS telefone_contato,
  m.email_fake      AS email_contato,

  -- endereco: FALSO, exceto cidade/estado
  'Rua de Teste'    AS endereco_rua,
  '100'             AS endereco_numero,
  '-'               AS endereco_complemento,
  'Centro'          AS endereco_bairro,
  b.endereco_cidade,
  b.endereco_estado,
  '00000000'        AS endereco_cep,

  -- contrato: REAL
  b.id_contrato,
  b.modalidade_contrato,
  b.produto_contrato,
  b.segmento_contrato,
  b.valor_total_contrato,
  b.valor_contrato_pago,
  b.quant_parcelas_contrato,
  b.parcelas_em_aberto,
  b.status_contrato,
  b.tags_label,
  b.analise_juridica,
  b.empresa_contrato,

  -- titulo: REAL, menos os instrumentos de pagamento
  b.id_titulo,
  b.valor_titulo,
  b.data_vencimento_titulo,
  b.data_pagamento_titulo,
  b.valor_pago_titulo,
  b.num_parcela_titulo,
  FALSE             AS parcela_pnp,   -- identico a producao nesta fonte
  b.status_titulo,
  b.instituicao_titulo,
  CAST(NULL AS STRING) AS pix_titulo,
  '00000000000000000000000000000000000000000000000' AS boleto_titulo

FROM BASE b
JOIN MOCK m ON m.documento_real = b.documento_real
