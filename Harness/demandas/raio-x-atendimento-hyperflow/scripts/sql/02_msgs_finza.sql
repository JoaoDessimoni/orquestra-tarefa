-- Spec 02 §5.2 — mensagens A · FINZA (reconstrução via lastMessage; ~65 MB). SOMENTE LEITURA.
WITH ev AS (
  SELECT protocol, chat AS chat_id, eventType, agent, department, timestamp ev_ts,
    JSON_VALUE(metadata,'$.chat.lastMessage.id') message_id,
    JSON_VALUE(metadata,'$.chat.lastMessage.direction') direction,
    JSON_VALUE(metadata,'$.chat.lastMessage.type') message_type,
    SAFE_CAST(JSON_VALUE(metadata,'$.chat.lastMessage.createdAt') AS TIMESTAMP) mensagem_em,
    SAFE.PARSE_JSON(JSON_VALUE(metadata,'$.chat.lastMessage.payload')) p
  FROM `blips-bigdata.bigquery___finza.chat_events`
  WHERE timestamp >= TIMESTAMP('2026-08-20 03:00:00'))
SELECT protocol, chat_id, message_id,
  ANY_VALUE(direction) direction, ANY_VALUE(message_type) message_type,
  FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E3SZ', COALESCE(MIN(mensagem_em), MIN(ev_ts))) mensagem_em,
  ANY_VALUE(COALESCE(JSON_VALUE(p,'$.text'), JSON_VALUE(p,'$.comment'))) texto,
  CAST(NULL AS STRING) tpl,
  CAST(NULL AS BOOL) tem_midia,
  ANY_VALUE(JSON_VALUE(p,'$.type')) system_type,            -- CHAT_TRANSFERED, FINISH_CHAT, ACTIVE_CHAT, COMMENT_ADDED, TRIGGER quando direction='info'
  ANY_VALUE(COALESCE(JSON_VALUE(p,'$.department'), JSON_VALUE(p,'$.department._id'))) sys_department,
  ANY_VALUE(COALESCE(JSON_VALUE(p,'$.agent'), JSON_VALUE(p,'$.agent._id'))) sys_agent,
  ANY_VALUE(department) department_id,
  CASE WHEN ANY_VALUE(direction)='in' THEN 'client'
       WHEN LOGICAL_OR(eventType='chat_user_interaction' AND direction='out') THEN 'agent'
       WHEN ANY_VALUE(direction)='out' THEN 'bot' ELSE 'system' END sender_kind,
  ANY_VALUE(IF(eventType='chat_user_interaction', agent, NULL)) agent_id,
  CAST(NULL AS BOOL) is_webhook,
  'reconstrucao_lastMessage' fonte
FROM ev WHERE message_id IS NOT NULL
GROUP BY 1,2,3
