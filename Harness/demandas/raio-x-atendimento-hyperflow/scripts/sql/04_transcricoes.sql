-- Spec 02 §5.4 — transcrição/descrição de mídia do cliente (auditor Nascimento), só BLIPS Cobrança. SOMENTE LEITURA.
WITH cob AS (SELECT ARRAY_AGG(department_id) ids FROM `blips-bigdata.bronze_external_hyperflow.tb_departments_ref`
             WHERE tenant_name='BLIPS' AND is_cobranca_dpto=1 AND is_ia_dpto=0),
base AS (
  SELECT l.protocol FROM `blips-bigdata.bronze_external_hyperflow.list_all_chats` l CROSS JOIN cob
  WHERE l.tenant_name='BLIPS'
    AND l.created_at >= TIMESTAMP('2026-08-20 00:00:00','America/Sao_Paulo')
    AND l.created_at <  TIMESTAMP('2026-11-19 00:00:00','America/Sao_Paulo')
    AND (l.department_id IN UNNEST(cob.ids) OR EXISTS (SELECT 1 FROM UNNEST(l.historical_info.interactions) i WHERE i.department IN UNNEST(cob.ids))))
SELECT h.protocol, h.type, h.text, FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E3SZ', h.created_at) created_at
FROM `blips-bigdata.silver_auditoria.helper_messages` h
WHERE h.created_at >= TIMESTAMP('2026-08-19') AND h.protocol IN (SELECT protocol FROM base)
