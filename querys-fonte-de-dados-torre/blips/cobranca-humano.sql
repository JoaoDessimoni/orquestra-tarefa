  SELECT
    deals.customer.fullname AS razao_social,
    deals.customer.document AS documento_contato,
    negotiation.contractor.personal_data.cellphone AS telefone_contato,
    CASE WHEN negotiation.contractor.personal_data.name IS NULL OR negotiation.contractor.personal_data.name = '' THEN deals.customer.fullname ELSE negotiation.contractor.personal_data.name END AS
  nome_contato,
    (
      SELECT value
      FROM UNNEST(deals.customer.contacts)
      WHERE type = 'E-mail'
      LIMIT 1
    ) AS email_contato,
    -- Endereço (COALESCE: business_data primeiro, personal_data fallback)
    COALESCE(
      NULLIF(negotiation.contractor.business_data.address.st_ave, ''),
      NULLIF(negotiation.contractor.personal_data.address.st_ave, '')
    ) AS endereco_rua,
    COALESCE(
      NULLIF(negotiation.contractor.business_data.address.number, ''),
      NULLIF(negotiation.contractor.personal_data.address.number, '')
    ) AS endereco_numero,
    COALESCE(
      NULLIF(negotiation.contractor.business_data.address.complement, ''),
      NULLIF(negotiation.contractor.personal_data.address.complement, '')
    ) AS endereco_complemento,
    COALESCE(
      NULLIF(negotiation.contractor.business_data.address.neighborhood, ''),
      NULLIF(negotiation.contractor.personal_data.address.neighborhood, '')
    ) AS endereco_bairro,
    COALESCE(
      NULLIF(negotiation.contractor.business_data.address.city, ''),
      NULLIF(negotiation.contractor.personal_data.address.city, '')
    ) AS endereco_cidade,
    COALESCE(
      NULLIF(negotiation.contractor.business_data.address.state, ''),
      NULLIF(negotiation.contractor.personal_data.address.state, '')
    ) AS endereco_estado,
    COALESCE(
      NULLIF(negotiation.contractor.business_data.address.zip_code, ''),
      NULLIF(negotiation.contractor.personal_data.address.zip_code, '')
    ) AS endereco_cep,
    deals.contract.number AS id_contrato,
    deals.contract.type AS modalidade_contrato,
    deals.contract.product_description AS produto_contrato,
    deals.contract.segment AS segmento_contrato,
    deals.payment_breakdown.total_amount AS valor_total_contrato,
    deals.payment_breakdown.down_payment AS valor_contrato_pago,
    deals.payment_breakdown.installments_paramenters.num_installments
      AS quant_parcelas_contrato,
    deals.status.status AS status_contrato,
    -- Todas as tags da negociacao (PLATAFORMA.negotiation.tags) como array JSON
    TO_JSON_STRING(ARRAY(
      SELECT DISTINCT t.label
      FROM UNNEST(negotiation.tags) AS t
      WHERE t.label IS NOT NULL
      ORDER BY t.label
    )) AS tags_label,
    deals.contract.grantor_name AS empresa_contrato,
    installments.our_number AS id_titulo,
    installments.value AS valor_titulo,
    DATE(PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', installments.due_date))
      AS data_vencimento_titulo,
    DATE(PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', installments.payment_date))
      AS data_pagamento_titulo,
    installments.received_value AS valor_pago_titulo,
    installments.installment_number AS num_parcela_titulo,
    installments.qr_code AS pix_titulo,
    installments.payment_line AS boleto_titulo,
    installments.status AS status_titulo,
    installments.financial_institution.nickname_financial AS instituicao_titulo
  FROM
    `blips-bigdata`.`bronze_mongodb_moduloFinanceiro`.`deals` AS deals,
    UNNEST(deals.installments) AS installments
  LEFT JOIN `blips-bigdata`.`PLATAFORMA`.`negotiation` AS negotiation
    ON deals.contract.number = negotiation.contract_number
  WHERE
    (
      (
        installments.status IN ( SELECT status FROM blips-bigdata.FINANCEIRO.status_parcelas_disponiveis_mf where status != 'Disponivel' )
        OR installments.status = 'Recomprado'
      )
      AND deals.contract.product_description IS NOT NULL
      AND deals.contract.product_description != ''
      AND DATE(PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', installments.due_date))
        <= DATE_ADD(CURRENT_DATE(), INTERVAL 20 DAY)
    )
    AND deals.contract.number IS NOT NULL
    AND deals.contract.number != ''
    AND installments.our_number IS NOT NULL
    AND installments.our_number != ''
    AND UPPER(deals.contract.grantor_name) NOT LIKE '%FINZA%'