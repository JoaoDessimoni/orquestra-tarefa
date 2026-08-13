-- =====================================================================================
--  FONTE DE DADOS DEV — "Disponivel - Modulo Financeiro" (100 clientes, anonimizada)
--  BTR10 · Torre de Controle self-hosted (GCP)
--  Dialeto: GoogleSQL (BigQuery).  Projeto de billing: blips-bigdata
--  Criado: 2026-08-10
-- =====================================================================================
--
--  PARA QUE SERVE
--  --------------
--  Este e o texto que vai em `connection_config.query` de uma data source do
--  Supabase DEV, espelhando a fonte homonima de producao. Mesmo contrato de 43
--  colunas -> o `field_mapping` do pipeline de prod funciona sem alteracao.
--
--  O PONTO CENTRAL: A ANONIMIZACAO ACONTECE AQUI, DENTRO DO BIGQUERY.
--  A PII real nunca sai do BQ. O DEV recebe o dado ja falso — nao existe janela
--  em que o ambiente de dev tenha dado real de cliente.
--
--  CUSTO: ~10 MB de scan em `deals` + ~0,5 MB em `negotiation` (medido 10/08/2026
--  via dry-run). Irrisorio. O LIMIT nao reduz bytes lidos em BigQuery — o custo e
--  o mesmo com ou sem ele.
--
-- -------------------------------------------------------------------------------------
--  O QUE E FALSO (substituido aqui)
-- -------------------------------------------------------------------------------------
--   nome_contato        -> 'Cliente DEV <hash>'
--   razao_social        -> 'Empresa DEV <hash>'
--   documento_contato   -> CPF/CNPJ ficticio, DV VALIDO, unico e deterministico.
--                          CPF se o documento real tiver <= 11 digitos, senao CNPJ.
--                          Nunca comeca com 0 (evita quebra se o destino tratar
--                          como numero).
--   telefone_contato    -> '999999999'
--   email_contato       -> um dos 4 e-mails do time, distribuido por hash
--   endereco_rua        -> 'Rua de Teste'
--   endereco_numero     -> '100'
--   endereco_complemento-> '-'
--   endereco_bairro     -> 'Centro'
--   endereco_cep        -> '00000000'
--   pix_titulo          -> NULL          <-- ver nota "instrumentos de pagamento"
--   boleto_titulo       -> linha fake    <-- idem
--
-- -------------------------------------------------------------------------------------
--  O QUE E REAL (preservado de proposito)
-- -------------------------------------------------------------------------------------
--   endereco_cidade / endereco_estado  — uteis para filtro, nao identificam sozinhos
--   id_contrato / id_titulo            — o ETL precisa deles para dedup e
--                                        reconciliacao; permitem comparar DEV x prod
--                                        ao investigar bug
--   todos os valores, datas, status, parcelas, tags, fase/status de plataforma,
--   empresa_contrato (cedente, nao e cliente), FIDC, safra, juros e multa
--
--  NOTA — instrumentos de pagamento: `pix_titulo` (QR code) e `boleto_titulo`
--  (linha digitavel) sao instrumentos PAGAVEIS de verdade. Trazer os reais para o
--  DEV significa que um teste poderia exibir — ou disparar — um boleto real. Por
--  isso viram falsos. Se voce precisar testar o fluxo de pagamento ponta a ponta,
--  troque por instrumentos de sandbox, nunca pelos de producao.
--
-- -------------------------------------------------------------------------------------
--  AMOSTRA
-- -------------------------------------------------------------------------------------
--  100 CLIENTES distintos (nao 100 linhas), trazendo TODOS os titulos de cada um.
--  Motivo: um cliente com 1 de 5 titulos deixa a carteira incoerente e o app
--  parece bugado. O total de linhas sera maior que 100 — isso e correto.
--
--  Determinismo: a escolha usa FARM_FINGERPRINT do documento, entao rodar de novo
--  traz OS MESMOS 100 clientes. Bug encontrado hoje continua reproduzivel amanha.
--  Para sortear outros, mude o literal da semente em AMOSTRA (marcado abaixo).
--
--  Para amostrar por TITULO em vez de por cliente, troque o bloco AMOSTRA por:
--     SELECT DISTINCT id_titulo FROM BASE ORDER BY FARM_FINGERPRINT(id_titulo) LIMIT 100
--  e ajuste o JOIN final.
-- =====================================================================================

WITH
  -- ---------------------------------------------------------------------------
  -- Ultima safra por contrato (identico a producao)
  -- ---------------------------------------------------------------------------
  BASE_SAFRA AS (
    SELECT contract_number, date_safra
    FROM `blips-bigdata.PARAMETROS_EQUIPE_DADOS.BASE_PRINCIPAL_EQUIPAMENTOS_CONTRATOS`
    QUALIFY ROW_NUMBER() OVER (PARTITION BY contract_number ORDER BY date_safra DESC) = 1
  ),

  -- ---------------------------------------------------------------------------
  -- BASE — a consulta de producao, sem mock ainda.
  -- A PII existe aqui dentro, mas este CTE NAO e retornado: so o SELECT final
  -- sai do BigQuery, e ele ja e anonimizado.
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
      deals.payment_breakdown.installments_paramenters.num_installments
        AS quant_parcelas_contrato,
      (
        SELECT COUNT(*) FROM UNNEST(deals.installments) AS i
        WHERE i.payment_date IS NULL
          AND i.status NOT IN ('Pago', 'Cancelado', 'Removido')
      ) AS parcelas_em_aberto,
      (
        SELECT COUNT(*) FROM UNNEST(deals.installments) AS i
        WHERE i.status = 'Disponivel'
      ) AS parcelas_restantes,
      deals.status.status AS status_contrato,

      -- fase da negociacao (mapa identico a producao)
      CASE negotiation.phase.name
        WHEN 'INITIAL_QUESTION'             THEN 'Questionario de negócios inicial'
        WHEN 'PENDENCY'                     THEN 'Pendência'
        WHEN 'WAITING_FOR_CREDIT_ANALYSIS'  THEN 'Aguardando análise de crédito'
        WHEN 'WAITING_SERIAL_NUMBER'        THEN 'Aguardando vincular ativo'
        WHEN 'WAITING_NEURON'               THEN 'Aguardando neurônio'
        WHEN 'BUSINESS_QUESTIONS'           THEN 'Informações de negócios'
        WHEN 'PAYMENT_SIGNAL'               THEN 'Pagamento do sinal'
        WHEN 'SHIPPING'                     THEN 'Seleção de frete'
        WHEN 'COMPANY_ADDRESS'              THEN 'Endereço da empresa'
        WHEN 'OCR'                          THEN 'Enviar fotos do documento'
        WHEN 'SELFIE'                       THEN 'Enviar selfie'
        WHEN 'RESPONSIBLE_ADDRESS'          THEN 'Endereço do responsável'
        WHEN 'ADDITIONAL_INFO'              THEN 'Informações adicionais'
        WHEN 'SIGNATURE_BY_AUDIO'           THEN 'Assinatura por áudio'
        WHEN 'TERMS_AND_CONDITIONS'         THEN 'Termos e condições'
        WHEN 'IN_ANALYSIS'                  THEN 'Análise de documentos'
        WHEN 'RENEWAL'                      THEN 'Renovação'
        WHEN 'TECHNICIAN_LINK'              THEN 'Vinculação com técnico'
        WHEN 'CHECKLIST'                    THEN 'Checklist'
        WHEN 'PAYMENT_SHIPPING'             THEN 'Pagamento do frete'
        WHEN 'SHIPPING_STATUS'              THEN 'Status de transporte'
        WHEN 'INSTALLATION_SCHEDULE'        THEN 'Agendamento de instalação'
        WHEN 'INSTALLATION'                 THEN 'Instalação'
        WHEN 'CONTRACT_SIGN'                THEN 'Assinatura do contrato'
        WHEN 'WAITING_BUSINESS_PROPOSAL'    THEN 'Aguardando proposta comercial'
        WHEN 'BILLING'                      THEN 'Faturamento'
        WHEN 'AGREED_SIGNAL_TERMS'          THEN 'Termo de intenção'
        WHEN 'DISTANT_TECHNICIANS'          THEN 'Técnicos próximos'
        WHEN 'SHIPPING_CHECKLIST'           THEN 'Checklist de envio'
        WHEN 'VALIDATION'                   THEN 'Validações'
        WHEN 'RENTAL_DATA'                  THEN 'Dados de locação'
        WHEN 'CCB_SIGNATURE'                THEN 'Aguardando Assinatura CCB'
        WHEN 'CONCLUDED'                    THEN 'Concluído'
        ELSE negotiation.phase.name
      END AS fase_plataforma,

      -- status da negociacao (mapa identico a producao)
      CASE negotiation.phase.status
        WHEN 'REPROVED'                THEN 'Reprovado'
        WHEN 'CANCELLED'               THEN 'Cancelado'
        WHEN 'IN_REGISTER'             THEN 'Em cadastro'
        WHEN 'COMPLETED'               THEN 'Completo'
        WHEN 'CONCLUDED'               THEN 'Concluído'
        WHEN 'ASYNCHRONOUS_PROCESSING' THEN 'Processamento Assíncrono'
        WHEN 'WAITING_PAYMENT'         THEN 'Aguardando Pagamento'
        WHEN 'AWAITING_ANALYSIS'       THEN 'Aguardando Análise Manual'
        WHEN 'ERROR'                   THEN 'Erro'
        WHEN 'INSTALLATION'            THEN 'Em Processo de Instalação'
        WHEN 'DIFFERENT_CONTRACT'      THEN 'Contrato com Assinatura diferente'
        WHEN 'CONTRACT_EXCHANGE'       THEN 'Troca de Contrato'
        WHEN 'AWAITING_PENDING'        THEN 'Aguardando Pendência'
        WHEN 'CANCELLATION_REQUESTED'  THEN 'Em processo de Cancelamento'
        WHEN 'IN_ANALYSIS'             THEN 'Em análise'
        WHEN 'IN_ERP_VALIDATION'       THEN 'Aguardando finalizar contrato de origem'
        WHEN 'IN_SHIPMENT'             THEN 'Em Remessa'
        WHEN 'AWAITING_DISPATCH'       THEN 'Aguardando Despacho'
        WHEN 'AWAITING_INVOICE'        THEN 'Aguardando Nota Fiscal'
        WHEN 'AWAITING_DELIVERY'       THEN 'Aguardando Entrega'
        WHEN 'AWAITNG_PREVIOUS_CONTRACT' THEN 'Aguardando finalizar contrato de origem'
        WHEN 'PENDING_PAYMENT'         THEN 'Pagamento Pendente'
        WHEN 'PENDING_RESERVATION'     THEN 'Sem Reserva'
        WHEN 'IN_VALIDATION'           THEN 'Em validação'
        WHEN 'ACTIVE'                  THEN 'Ativo'
        WHEN 'FINISHED'                THEN 'Finalizado'
        WHEN 'PROCESSED'               THEN 'Processado'
        WHEN 'CREDIT_RECOVERY'         THEN 'Recuperação de crédito'
        WHEN 'WAITING'                 THEN 'Aguardando'
        ELSE negotiation.phase.status
      END AS status_plataforma,

      TO_JSON_STRING(ARRAY(
        SELECT DISTINCT t.label FROM UNNEST(negotiation.tags) AS t
        WHERE t.label IS NOT NULL ORDER BY t.label
      )) AS tags_label,
      negotiation.flags.legal_analysis.value AS analise_juridica,
      deals.contract.grantor_name AS empresa_contrato,

      installments.our_number                        AS id_titulo,
      installments.value                             AS valor_titulo,
      installments.penalty.daily_accrued_penalty     AS valor_multa_acumulado,
      installments.interest.daily_accrued_interest   AS valor_juros_acumulado,
      installments.updated_value_interest_penalty    AS valor_atualizado_titulo,
      DATE(PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', installments.due_date))     AS data_vencimento_titulo,
      DATE(PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', installments.payment_date)) AS data_pagamento_titulo,
      installments.received_value                    AS valor_pago_titulo,
      installments.installment_number                AS num_parcela_titulo,
      COALESCE(installments.installment_number = 1, FALSE) AS parcela_pnp,
      installments.status                            AS status_titulo,
      COALESCE(installments.is_advance_payment = TRUE, FALSE) AS fidc,
      installments.financial_institution.name             AS banco_fidc,
      installments.financial_institution.nickname_financial AS instituicao_titulo,
      safra.date_safra AS data_safra_contrato

    FROM `blips-bigdata.bronze_mongodb_moduloFinanceiro.deals` AS deals,
      UNNEST(deals.installments) AS installments
    LEFT JOIN `blips-bigdata.PLATAFORMA.negotiation` AS negotiation
      ON deals.contract.number = negotiation.contract_number
    LEFT JOIN BASE_SAFRA safra
      ON deals.contract.number = safra.contract_number
    WHERE
      installments.status = 'Disponivel'
      AND deals.contract.product_description IS NOT NULL
      AND deals.contract.product_description != ''
      AND DATE(PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', installments.due_date))
            <= DATE_ADD(CURRENT_DATE(), INTERVAL 20 DAY)
      AND deals.contract.number IS NOT NULL
      AND deals.contract.number != ''
      AND installments.our_number IS NOT NULL
      AND installments.our_number != ''
      AND UPPER(deals.contract.grantor_name) NOT LIKE '%FINZA%'
      AND deals.customer.document IS NOT NULL
  ),

  -- ---------------------------------------------------------------------------
  -- AMOSTRA — 100 clientes distintos, escolha deterministica.
  -- Troque a semente 'seed-dev-2026-08-10' para sortear outro conjunto.
  -- ---------------------------------------------------------------------------
  AMOSTRA AS (
    SELECT documento_real
    FROM (SELECT DISTINCT documento_real FROM BASE)
    ORDER BY FARM_FINGERPRINT(CONCAT(documento_real, 'seed-dev-2026-08-10'))
    LIMIT 100
  ),

  -- ---------------------------------------------------------------------------
  -- MOCK_BASE — bases numericas deterministicas por cliente.
  -- Faixas escolhidas para NUNCA comecar com zero.
  -- ---------------------------------------------------------------------------
  MOCK_BASE AS (
    SELECT
      documento_real,
      LENGTH(REGEXP_REPLACE(documento_real, r'\D', '')) > 11 AS is_cnpj,
      MOD(ABS(FARM_FINGERPRINT(CONCAT(documento_real, '#cpf'))),  900000000)    + 100000000    AS b9,
      MOD(ABS(FARM_FINGERPRINT(CONCAT(documento_real, '#cnpj'))), 900000000000) + 100000000000 AS b12
    FROM AMOSTRA
  ),

  -- ---------------------------------------------------------------------------
  -- MOCK_DIG — digitos individuais das bases
  -- ---------------------------------------------------------------------------
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

  -- ---------------------------------------------------------------------------
  -- MOCK_DV1 — primeiro digito verificador (CPF e CNPJ)
  --   CPF : pesos 10..2      CNPJ: pesos 5,4,3,2,9,8,7,6,5,4,3,2
  -- ---------------------------------------------------------------------------
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

  -- ---------------------------------------------------------------------------
  -- MOCK_DV2 — segundo digito verificador (usa o primeiro)
  --   CPF : pesos 11..2      CNPJ: pesos 6,5,4,3,2,9,8,7,6,5,4,3,2
  -- ---------------------------------------------------------------------------
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

  -- ---------------------------------------------------------------------------
  -- MOCK — o pacote final de identidade falsa por cliente
  -- ---------------------------------------------------------------------------
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
--  SAIDA — 43 colunas, mesmo contrato da fonte de producao.
--  Este e o UNICO CTE que sai do BigQuery, e ele ja esta anonimizado.
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
  b.quant_parcelas_contrato,
  b.parcelas_em_aberto,
  b.parcelas_restantes,
  b.status_contrato,
  b.fase_plataforma,
  b.status_plataforma,
  b.tags_label,
  b.analise_juridica,
  b.empresa_contrato,
  b.data_safra_contrato,

  -- titulo: REAL, menos os instrumentos de pagamento
  b.id_titulo,
  b.valor_titulo,
  b.valor_multa_acumulado,
  b.valor_juros_acumulado,
  b.valor_atualizado_titulo,
  b.data_vencimento_titulo,
  b.data_pagamento_titulo,
  b.valor_pago_titulo,
  b.num_parcela_titulo,
  b.parcela_pnp,
  b.status_titulo,
  b.fidc,
  b.banco_fidc,
  b.instituicao_titulo,
  CAST(NULL AS STRING) AS pix_titulo,
  '00000000000000000000000000000000000000000000000' AS boleto_titulo

FROM BASE b
JOIN MOCK m ON m.documento_real = b.documento_real
