-- Spec 02 §5.3 — mensagens B · BLIPS Cobrança (chat_history completo quando há; tb_chat_messages amostra no resto). ~3,2 GB por execução. SOMENTE LEITURA.
-- Parâmetros: {{INI}} / {{FIM}} = limites UTC do created_at do chat (fatia mensal)
WITH cob AS (SELECT ARRAY_AGG(department_id) ids FROM `blips-bigdata.bronze_external_hyperflow.tb_departments_ref`
             WHERE tenant_name='BLIPS' AND is_cobranca_dpto=1 AND is_ia_dpto=0),
base AS (
  SELECT l.protocol FROM `blips-bigdata.bronze_external_hyperflow.list_all_chats` l CROSS JOIN cob
  WHERE l.tenant_name='BLIPS' AND l.created_at >= TIMESTAMP('{{INI}}') AND l.created_at < TIMESTAMP('{{FIM}}')
    AND (l.department_id IN UNNEST(cob.ids) OR EXISTS (SELECT 1 FROM UNNEST(l.historical_info.interactions) i WHERE i.department IN UNNEST(cob.ids)))),
chraw AS (
  SELECT protocol, chat_id, message_id, direction, message_type, SAFE_CAST(created_at AS TIMESTAMP) ts, SAFE.PARSE_JSON(payload) p,
    system_type, sender_kind, agent_id, is_webhook
  FROM `blips-bigdata.bronze_hyperflow.chat_history`
  WHERE empresa='BLIPS' AND message_id IS NOT NULL AND chat_created_at >= '2026-08-19' AND protocol IN (SELECT protocol FROM base)),
ch AS (
  SELECT protocol, ANY_VALUE(chat_id) chat_id, message_id, ANY_VALUE(direction) direction, ANY_VALUE(message_type) message_type,
    FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E3SZ', MIN(ts)) mensagem_em,
    ANY_VALUE(COALESCE(JSON_VALUE(p,'$.text'), JSON_VALUE(p,'$.comment'), JSON_VALUE(p,'$.fallback'))) texto,
    ANY_VALUE(COALESCE(JSON_VALUE(p,'$.template.name'), JSON_VALUE(p,'$.template'))) tpl,
    LOGICAL_OR(COALESCE(JSON_VALUE(p,'$.url'), JSON_VALUE(p,'$.mediaUrl')) IS NOT NULL) tem_midia,
    ANY_VALUE(system_type) system_type,
    ANY_VALUE(COALESCE(JSON_VALUE(p,'$.department'), JSON_VALUE(p,'$.department._id'))) sys_department,
    ANY_VALUE(COALESCE(JSON_VALUE(p,'$.agent'), JSON_VALUE(p,'$.agent._id'))) sys_agent,
    CAST(NULL AS STRING) department_id,
    ANY_VALUE(sender_kind) sender_kind, ANY_VALUE(agent_id) agent_id, LOGICAL_OR(is_webhook) is_webhook
  FROM chraw GROUP BY protocol, message_id),
tm AS (
  SELECT protocol, ANY_VALUE(chat_id) chat_id, message_id, ANY_VALUE(direcao) direction, ANY_VALUE(tipo_mensagem) message_type,
    FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E3SZ', MIN(mensagem_em)) mensagem_em,
    ANY_VALUE(conteudo_texto) texto, CAST(NULL AS STRING) tpl, CAST(NULL AS BOOL) tem_midia,
    CAST(NULL AS STRING) system_type, CAST(NULL AS STRING) sys_department, CAST(NULL AS STRING) sys_agent,
    ANY_VALUE(department_id) department_id,
    CASE WHEN ANY_VALUE(direcao)='in' THEN 'client'
         WHEN LOGICAL_OR(evento_origem_tipo='chat_user_interaction' AND direcao='out') THEN 'agent'
         WHEN ANY_VALUE(direcao)='out' THEN 'bot' ELSE 'system' END sender_kind,
    ANY_VALUE(IF(evento_origem_tipo='chat_user_interaction', agente_evento_id, NULL)) agent_id,
    CAST(NULL AS BOOL) is_webhook
  FROM `blips-bigdata.bronze_external_hyperflow.tb_chat_messages`
  WHERE tenant_name='BLIPS' AND mensagem_em >= TIMESTAMP('2026-08-19')
    AND protocol IN (SELECT protocol FROM base) AND protocol NOT IN (SELECT DISTINCT protocol FROM ch)
  GROUP BY protocol, message_id)
SELECT *, 'chat_history_completo' fonte FROM ch
UNION ALL
SELECT *, 'tb_chat_messages_amostra' fonte FROM tm
