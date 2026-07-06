WITH
  BASE_SAFRA AS (
    SELECT
      contract_number,
      date_safra
    FROM
      `blips-bigdata.PARAMETROS_EQUIPE_DADOS.BASE_PRINCIPAL_EQUIPAMENTOS_CONTRATOS`
    QUALIFY
      ROW_NUMBER()
        OVER (
          PARTITION BY contract_number
          ORDER BY DATE_SAFRA DESC
        )
      = 1
  ),
  BASE AS (
    SELECT
      deals.customer.fullname AS razao_social,
      CASE
        WHEN
          negotiation.contractor.personal_data.name IS NULL
          OR negotiation.contractor.personal_data.name = ''
          THEN deals.customer.fullname
        ELSE negotiation.contractor.personal_data.name
        END
        AS nome_contato,
      deals.customer.document AS documento_contato,
      negotiation.contractor.business_data.cellphone AS telefone_contato,
      (
        SELECT value
        FROM UNNEST(deals.customer.contacts)
        WHERE type = 'E-mail'
        LIMIT 1
      ) AS email_contato,
      -- Endereço (COALESCE: business_data primeiro, personal_data fallback)
      COALESCE(
        NULLIF(negotiation.contractor.business_data.address.st_ave, ''),
        NULLIF(negotiation.contractor.personal_data.address.st_ave, ''))
        AS endereco_rua,
      COALESCE(
        NULLIF(negotiation.contractor.business_data.address.number, ''),
        NULLIF(negotiation.contractor.personal_data.address.number, ''))
        AS endereco_numero,
      COALESCE(
        NULLIF(negotiation.contractor.business_data.address.complement, ''),
        NULLIF(negotiation.contractor.personal_data.address.complement, ''))
        AS endereco_complemento,
      COALESCE(
        NULLIF(negotiation.contractor.business_data.address.neighborhood, ''),
        NULLIF(negotiation.contractor.personal_data.address.neighborhood, ''))
        AS endereco_bairro,
      COALESCE(
        NULLIF(negotiation.contractor.business_data.address.city, ''),
        NULLIF(negotiation.contractor.personal_data.address.city, ''))
        AS endereco_cidade,
      COALESCE(
        NULLIF(negotiation.contractor.business_data.address.state, ''),
        NULLIF(negotiation.contractor.personal_data.address.state, ''))
        AS endereco_estado,
      COALESCE(
        NULLIF(negotiation.contractor.business_data.address.zip_code, ''),
        NULLIF(negotiation.contractor.personal_data.address.zip_code, ''))
        AS endereco_cep,
      deals.contract.number AS id_contrato,
      deals.contract.type AS modalidade_contrato,
      deals.contract.product_description AS produto_contrato,
      deals.contract.segment AS segmento_contrato,
      deals.payment_breakdown.total_amount AS valor_total_contrato,
      deals.payment_breakdown.installments_paramenters.num_installments
        AS quant_parcelas_contrato,
      (
        SELECT COUNT(*)
        FROM UNNEST(deals.installments) AS i
        WHERE i.status = 'Disponivel'
      ) AS parcelas_restantes,
      deals.status.status AS status_contrato,
      -- Fase da negociação (mapa: negotiation.phase.name → PT-BR)
      CASE negotiation.phase.name
        WHEN 'INITIAL_QUESTION' THEN 'Questionario de negócios inicial'
        WHEN 'PENDENCY' THEN 'Pendência'
        WHEN 'WAITING_FOR_CREDIT_ANALYSIS'
          THEN 'Aguardando análise de crédito'
        WHEN 'WAITING_SERIAL_NUMBER' THEN 'Aguardando vincular ativo'
        WHEN 'WAITING_NEURON' THEN 'Aguardando neurônio'
        WHEN 'BUSINESS_QUESTIONS' THEN 'Informações de negócios'
        WHEN 'PAYMENT_SIGNAL' THEN 'Pagamento do sinal'
        WHEN 'SHIPPING' THEN 'Seleção de frete'
        WHEN 'COMPANY_ADDRESS' THEN 'Endereço da empresa'
        WHEN 'OCR' THEN 'Enviar fotos do documento'
        WHEN 'SELFIE' THEN 'Enviar selfie'
        WHEN 'RESPONSIBLE_ADDRESS' THEN 'Endereço do responsável'
        WHEN 'ADDITIONAL_INFO' THEN 'Informações adicionais'
        WHEN 'SIGNATURE_BY_AUDIO' THEN 'Assinatura por áudio'
        WHEN 'TERMS_AND_CONDITIONS' THEN 'Termos e condições'
        WHEN 'IN_ANALYSIS' THEN 'Análise de documentos'
        WHEN 'RENEWAL' THEN 'Renovação'
        WHEN 'TECHNICIAN_LINK' THEN 'Vinculação com técnico'
        WHEN 'CHECKLIST' THEN 'Checklist'
        WHEN 'PAYMENT_SHIPPING' THEN 'Pagamento do frete'
        WHEN 'SHIPPING_STATUS' THEN 'Status de transporte'
        WHEN 'INSTALLATION_SCHEDULE' THEN 'Agendamento de instalação'
        WHEN 'INSTALLATION' THEN 'Instalação'
        WHEN 'CONTRACT_SIGN' THEN 'Assinatura do contrato'
        WHEN 'WAITING_BUSINESS_PROPOSAL' THEN 'Aguardando proposta comercial'
        WHEN 'BILLING' THEN 'Faturamento'
        WHEN 'AGREED_SIGNAL_TERMS' THEN 'Termo de intenção'
        WHEN 'DISTANT_TECHNICIANS' THEN 'Técnicos próximos'
        WHEN 'SHIPPING_CHECKLIST' THEN 'Checklist de envio'
        WHEN 'VALIDATION' THEN 'Validações'
        WHEN 'RENTAL_DATA' THEN 'Dados de locação'
        WHEN 'CCB_SIGNATURE' THEN 'Aguardando Assinatura CCB'
        WHEN 'CONCLUDED' THEN 'Concluído'
        ELSE negotiation.phase.name
        END AS fase_plataforma,
      -- Status da negociação (mapa: negotiation.phase.status → PT-BR)
      CASE negotiation.phase.status
        WHEN 'REPROVED' THEN 'Reprovado'
        WHEN 'CANCELLED' THEN 'Cancelado'
        WHEN 'IN_REGISTER' THEN 'Em cadastro'
        WHEN 'COMPLETED' THEN 'Completo'
        WHEN 'CONCLUDED' THEN 'Concluído'
        WHEN 'ASYNCHRONOUS_PROCESSING' THEN 'Processamento Assíncrono'
        WHEN 'WAITING_PAYMENT' THEN 'Aguardando Pagamento'
        WHEN 'AWAITING_ANALYSIS' THEN 'Aguardando Análise Manual'
        WHEN 'ERROR' THEN 'Erro'
        WHEN 'INSTALLATION' THEN 'Em Processo de Instalação'
        WHEN 'DIFFERENT_CONTRACT' THEN 'Contrato com Assinatura diferente'
        WHEN 'CONTRACT_EXCHANGE' THEN 'Troca de Contrato'
        WHEN 'AWAITING_PENDING' THEN 'Aguardando Pendência'
        WHEN 'CANCELLATION_REQUESTED' THEN 'Em processo de Cancelamento'
        WHEN 'IN_ANALYSIS' THEN 'Em análise'
        WHEN 'IN_ERP_VALIDATION' THEN 'Aguardando finalizar contrato de origem'
        WHEN 'IN_SHIPMENT' THEN 'Em Remessa'
        WHEN 'AWAITING_DISPATCH' THEN 'Aguardando Despacho'
        WHEN 'AWAITING_INVOICE' THEN 'Aguardando Nota Fiscal'
        WHEN 'AWAITING_DELIVERY' THEN 'Aguardando Entrega'
        WHEN 'AWAITNG_PREVIOUS_CONTRACT'
          THEN 'Aguardando finalizar contrato de origem'
        WHEN 'PENDING_PAYMENT' THEN 'Pagamento Pendente'
        WHEN 'PENDING_RESERVATION' THEN 'Sem Reserva'
        WHEN 'IN_VALIDATION' THEN 'Em validação'
        WHEN 'ACTIVE' THEN 'Ativo'
        WHEN 'FINISHED' THEN 'Finalizado'
        WHEN 'PROCESSED' THEN 'Processado'
        WHEN 'CREDIT_RECOVERY' THEN 'Recuperação de crédito'
        WHEN 'WAITING' THEN 'Aguardando'
        ELSE negotiation.phase.status
        END AS status_plataforma,
      -- Todas as tags da negociacao (PLATAFORMA.negotiation.tags) como array JSON
      TO_JSON_STRING(ARRAY(
        SELECT DISTINCT t.label
        FROM UNNEST(negotiation.tags) AS t
        WHERE t.label IS NOT NULL
        ORDER BY t.label
      )) AS tags_label,
      deals.contract.grantor_name AS empresa_contrato,
      installments.our_number AS id_titulo,
      -- COALESCE(installments.value, 0)
      installments.value
        AS valor_titulo,
      -- COALESCE(installments.penalty.daily_accrued_penalty, 0)
      installments.penalty.daily_accrued_penalty
        AS valor_multa_acumulado,
      -- COALESCE(installments.interest.daily_accrued_interest, 0)
      installments.interest.daily_accrued_interest
        AS valor_juros_acumulado,
      -- COALESCE( installments.updated_value_interest_penalty, installments.value, 0)
      -- COALESCE(installments.updated_value_interest_penalty, 0)
      installments.updated_value_interest_penalty
        AS valor_atualizado_titulo,
      DATE(PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', installments.due_date))
        AS data_vencimento_titulo,
      DATE(PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', installments.payment_date))
        AS data_pagamento_titulo,
      installments.received_value AS valor_pago_titulo,
      installments.installment_number AS num_parcela_titulo,
      COALESCE(installments.installment_number = 1, FALSE) AS parcela_pnp,
      installments.qr_code AS pix_titulo,
      installments.payment_line AS boleto_titulo,
      installments.status AS status_titulo,
      COALESCE(installments.is_advance_payment = TRUE, FALSE) AS fidc,
      installments.financial_institution.name AS banco_fidc,
      installments.financial_institution.nickname_financial
        AS instituicao_titulo,
      safra.date_safra AS data_safra_contrato
    FROM
      `blips-bigdata.bronze_mongodb_moduloFinanceiro.deals` AS deals,
      UNNEST(deals.installments) AS installments
    LEFT JOIN `blips-bigdata`.`PLATAFORMA`.`negotiation` AS negotiation
      ON deals.contract.number = negotiation.contract_number
    LEFT JOIN BASE_SAFRA safra
      ON deals.contract.number = safra.contract_number
    WHERE
      (
        installments.status = 'Disponivel'
        AND deals.contract.product_description IS NOT NULL
        AND deals.contract.product_description != ''
        AND DATE(PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', installments.due_date))
          <= DATE_ADD(CURRENT_DATE(), INTERVAL 20 DAY))
      AND deals.contract.number IS NOT NULL
      AND deals.contract.number != ''
      AND installments.our_number IS NOT NULL
      AND installments.our_number != ''
      AND UPPER(deals.contract.grantor_name) NOT LIKE '%FINZA%'
  )
SELECT *
FROM BASE
