"""Plataforma + Hyperflow no BigQuery -> base.csv, chats_ia.csv, eventos_contato.csv, aprovacao_anexo.csv.

Uso: python 02_bigquery.py <pasta_saida> <de AAAA-MM-DD>
Precisa do exec_parsed.csv do passo 01 (para casar os eventos de chat com cada acionamento).
"""
import os, sys, collections
from comum import bq, ler_csv, chave_tel, DEPT_FORMALIZACAO

out, de = sys.argv[1], sys.argv[2]
FASES = 'n.business_rule_obj.sequence_of_phases.array_br_com_blips_Sequence_of_phase_value'
fase = lambda f: f"(SELECT DATETIME(TIMESTAMP(MIN(p.started_at)),'America/Sao_Paulo') FROM UNNEST({FASES}) p WHERE p.identifier='{f}')"

# 1. Turma: quem entrou em Endereço do Responsável (fase em que a Clara deve acionar) desde <de>
bq(f"""
WITH b AS (
SELECT n.id nid, COALESCE(n.contract_number,'') contrato, UPPER(COALESCE(n.financial.identifier,'INDEFINIDO')) marca,
 COALESCE(n.business_rule_obj.type,'') tipo, COALESCE(n.business_rule_obj.selected_commercial_definition_obj.sale_type,'') sale_type,
 COALESCE(n.contractor.personal_data.cellphone, n.contractor.business_data.cellphone,'') cel,
 n.phase.name fase_atual, n.has_given_up desistiu,
 {fase('RESPONSIBLE_ADDRESS')} ra, {fase('ANTI_FRAUD_FORMALIZATION')} af, {fase('CHECKLIST')} ck
FROM `blips-bigdata.PLATAFORMA.negotiation` n)
SELECT * FROM b WHERE ra >= '{de}' ORDER BY ra""", os.path.join(out, 'base.csv'))

# 2. Conversas abertas pela Clara: chat_created no departamento IA - Formalização dos dois tenants
bq(f"""
SELECT 'blips' ten, CAST(DATETIME(timestamp,'America/Sao_Paulo') AS STRING) ts_e, protocol, sender
FROM `blips-bigdata.blips___desk.chat_events` WHERE timestamp >= '{de}' AND eventType='chat_created' AND department='{DEPT_FORMALIZACAO['blips']}'
UNION ALL
SELECT 'finza', CAST(DATETIME(timestamp,'America/Sao_Paulo') AS STRING), protocol, sender
FROM `blips-bigdata.bigquery___finza.chat_events` WHERE timestamp >= '{de}' AND eventType='chat_created' AND department='{DEPT_FORMALIZACAO['finza']}'
""", os.path.join(out, 'chats_ia.csv'))

# 3. Todos os eventos de chat do contato entre -2 min e +30 min do acionamento (explica "acionado sem conversa")
ex = ler_csv(os.path.join(out, 'exec_parsed.csv'))
ok = lambda r: (r['ativar_hyper'] == '1' and r['ah_stat'] == 'OK') or (r['ativar_hyper1'] == '1' and r['ah1_stat'] == 'OK')
ac = {}
for x in ex:
    if x.get('erro_fetch') == '0' and x['negotiation_id'] and ok(x) and chave_tel(x['cellphone']) and x['negotiation_id'] not in ac:
        ac[x['negotiation_id']] = (x['negotiation_id'], chave_tel(x['cellphone']), x['inicio_brt'][:19], 'blips' if x['ativar_hyper'] == '1' else 'finza')
print('acionamentos com telefone', len(ac), collections.Counter(v[3] for v in ac.values()))
vals = ',\n'.join(f"STRUCT('{n}' AS nid,'{k}' AS phk,DATETIME '{t}' AS ts,'{c}' AS canal)" for n, k, t, c in ac.values())
ev = lambda ds, ten: f"""SELECT '{ten}' ten, DATETIME(timestamp,'America/Sao_Paulo') ts_e, eventType, department, protocol,
 CONCAT(SUBSTR(REGEXP_REPLACE(REGEXP_REPLACE(c,r'\\D',''),r'^55',''),1,2), RIGHT(REGEXP_REPLACE(c,r'\\D',''),8)) phk
 FROM `blips-bigdata.{ds}.chat_events`, UNNEST([sender,receiver]) c
 WHERE timestamp >= '{de}' AND c IS NOT NULL AND LENGTH(REGEXP_REPLACE(c,r'\\D',''))>=10"""
if ac:
    bq(f"""WITH a AS (SELECT * FROM UNNEST([{vals}])),
e AS ({ev('blips___desk', 'blips')} UNION ALL {ev('bigquery___finza', 'finza')})
SELECT a.nid, a.canal, CAST(a.ts AS STRING) ts, e.ten, CAST(e.ts_e AS STRING) ts_e, e.eventType, e.department, e.protocol
FROM a JOIN e ON e.phk=a.phk AND e.ts_e BETWEEN DATETIME_SUB(a.ts, INTERVAL 2 MINUTE) AND DATETIME_ADD(a.ts, INTERVAL 30 MINUTE)""",
       os.path.join(out, 'eventos_contato.csv'))

# 4. Aprovado pelo time E anexado pela Clara (CLA-01): marca no histórico da negociação
bq("""
SELECT n.id nid, UPPER(n.financial.identifier) marca, CAST(DATETIME(TIMESTAMP(h.date),'America/Sao_Paulo') AS STRING) quando
FROM `blips-bigdata.PLATAFORMA.negotiation` n, UNNEST(n.historical_status) h
WHERE h.justification LIKE 'Formalizacao APROVADA por%'""", os.path.join(out, 'aprovacao_anexo.csv'))
