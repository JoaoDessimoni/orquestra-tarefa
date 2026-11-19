-- Dimensão de departamentos (nome + flags). SOMENTE LEITURA.
SELECT department_id, name, tenant_name, active, is_ia_dpto, is_cobranca_dpto, categoria_dpto
FROM `blips-bigdata.bronze_external_hyperflow.tb_departments_ref`
WHERE tenant_name IN ('FINZA','BLIPS')
