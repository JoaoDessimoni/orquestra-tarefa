-- Spec 02 §5.1 — base de chats por recorte (metadados + jornada + CNPJ). SOMENTE LEITURA.
-- Parâmetro: {{TENANT}} = FINZA | BLIPS
WITH cob AS (SELECT ARRAY_AGG(department_id) ids FROM `blips-bigdata.bronze_external_hyperflow.tb_departments_ref`
             WHERE tenant_name='BLIPS' AND is_cobranca_dpto=1 AND is_ia_dpto=0),
l AS (
  SELECT IF(l.tenant_name='FINZA','A','B') rec, l.protocol, l._id chat_id,
    FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E3SZ', l.created_at) created_at,
    FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E3SZ', l.finished_at) finished_at,
    FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E3SZ', l.last_event_timestamp) last_event_at,
    l.status, l.is_broadcast, l.channel, l.department_id, l.department_name, l.agent_id,
    l.contact_phone, l.contact_id,
    l.historical_info.userInteractions hi_ui, l.historical_info.systemInteractions hi_si,
    l.historical_info.firstInteractionAt hi_first,
    ARRAY(SELECT AS STRUCT i.department d, i.agent a, i.queuedAt q, i.transferAt t, i.firstInteractionAt f, i.finishedAt e
          FROM UNNEST(l.historical_info.interactions) i) jornada,
    ARRAY(SELECT DISTINCT a.agent._id FROM UNNEST(l.historical_info.agents) a WHERE a.agent._id IS NOT NULL) agentes,
    REGEXP_REPLACE(REGEXP_REPLACE(l.contact_phone, r'\D', ''), r'^55(\d{10,11})$', r'\1') t,
    (l.department_id IN UNNEST(cob.ids) OR EXISTS (SELECT 1 FROM UNNEST(l.historical_info.interactions) i WHERE i.department IN UNNEST(cob.ids))) passou_cob
  FROM `blips-bigdata.bronze_external_hyperflow.list_all_chats` l CROSS JOIN cob
  WHERE l.created_at >= TIMESTAMP('2026-08-20 00:00:00','America/Sao_Paulo')
    AND l.created_at <  TIMESTAMP('2026-11-19 00:00:00','America/Sao_Paulo')
    AND l.tenant_name = '{{TENANT}}')
SELECT l.* EXCEPT (t, passou_cob),
  IF(LENGTH(l.t) BETWEEN 10 AND 11, CONCAT(SUBSTR(l.t,1,2), RIGHT(l.t,8)), NULL) tel_canon,
  x.cliente_principal.cnpj_cpf cnpj_principal, x.cliente_principal.nome_cliente nome_crm, x.match_ambiguo,
  ARRAY(SELECT AS STRUCT c.cnpj_cpf, c.nome_cliente FROM UNNEST(x.clientes_crm) c) clientes_crm
FROM l LEFT JOIN `blips-bigdata.bronze_external_hyperflow.tb_contacts_crm_ref` x
  ON x.telefone_canonico = IF(LENGTH(l.t) BETWEEN 10 AND 11, CONCAT(SUBSTR(l.t,1,2), RIGHT(l.t,8)), NULL)
WHERE l.rec='A' OR l.passou_cob
