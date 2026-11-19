-- Spec 02 §3/§6 — turnos da IA FINZA (Torre): user_message + ai_response por turno. SOMENTE LEITURA.
SELECT protocol, agent_id, FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E3SZ', created_at) created_at,
  user_message, ai_response, sentiment, intent_detected, transferred_to_human, transfer_reason, transfer_type, processing_time_ms
FROM `finza-prod-481500.silver_torre.org_finza_actions_interaction_logs`
WHERE created_at >= TIMESTAMP('2026-08-20 03:00:00') AND protocol IS NOT NULL
