-- Protocolo → agente de IA (Torre), as duas orgs. SOMENTE LEITURA.
SELECT 'A' rec, protocol, agent_id, source, status, is_a2a,
  FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E3SZ', started_at) started_at,
  FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E3SZ', transferred_at) transferred_at,
  FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E3SZ', finalized_at) finalized_at, finalized_reason
FROM `finza-prod-481500.silver_torre.org_finza_ai_protocols`
WHERE protocol IS NOT NULL AND started_at >= TIMESTAMP('2026-08-01')
UNION ALL
SELECT 'B' rec, protocol, agent_id, source, status, is_a2a,
  FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E3SZ', started_at),
  FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E3SZ', transferred_at),
  FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E3SZ', finalized_at), finalized_reason
FROM `finza-prod-481500.silver_torre.org_blips_ai_protocols`
WHERE protocol IS NOT NULL AND started_at >= TIMESTAMP('2026-08-01')
