"""Execuções do fluxo de acionamento (n8n-prod-automacao) -> exec_parsed.csv.

Uso: python 01_acionamento_n8n.py <pasta_saida> <de AAAA-MM-DD> <ate AAAA-MM-DD>
Só GET. Cacheia cada execução em <pasta_saida>/exec_data/ (rodar de novo só baixa o que falta).
"""
import json, os, sys, datetime as dt
from concurrent.futures import ThreadPoolExecutor
from comum import env, n8n_get, listar_execucoes, brt, gravar_csv, WF_ACIONAMENTO

out, de, ate = sys.argv[1], dt.datetime.fromisoformat(sys.argv[2]), dt.datetime.fromisoformat(sys.argv[3])
os.makedirs(os.path.join(out, 'exec_data'), exist_ok=True)
U, K = env('PROD_AUTOMACAO')

lst = listar_execucoes(U, K, WF_ACIONAMENTO)
sel = [e for e in lst if de <= brt(e['startedAt']) < ate]
st = sorted(e['startedAt'] for e in lst)
print('execuções na instância', len(lst), 'de', st[0] if st else '-', '| na janela', len(sel))
if st and brt(st[0]) > de:
    print('AVISO: a retenção não cobre o início da janela; os dias antes de', brt(st[0]), 'ficam sem acionamento')


def baixar(e):
    p = os.path.join(out, 'exec_data', f"{e['id']}.json")
    if os.path.exists(p) and os.path.getsize(p) > 50:
        return
    for i in range(3):
        try:
            json.dump(n8n_get(U, K, f"/api/v1/executions/{e['id']}?includeData=true"), open(p, 'w', encoding='utf-8')); return
        except Exception as x:
            if i == 2:
                json.dump({'__err': str(x)}, open(p, 'w'))


with ThreadPoolExecutor(max_workers=4) as x:
    list(x.map(baixar, sel))


def first(rd, node):
    try: return rd[node][0]['data']['main'][0][0]['json']
    except Exception: return None


def stat(rd, n):
    try: return 'ERROR' if rd[n][0].get('error') else 'OK'
    except Exception: return ''


rows, ids = [], {str(e['id']) for e in sel}
for f in os.listdir(os.path.join(out, 'exec_data')):
    if f[:-5] not in ids:
        continue
    d = json.load(open(os.path.join(out, 'exec_data', f), encoding='utf-8'))
    if '__err' in d:
        rows.append({'id': f[:-5], 'erro_fetch': 1}); continue
    rd = (d.get('data') or {}).get('resultData', {}).get('runData', {}) or {}
    entry = 'Webhook Coleta' if 'Webhook Coleta' in rd else ('Webhook Recoleta' if 'Webhook Recoleta' in rd else '?')
    body = (first(rd, entry) or {}).get('body') or {}
    dados = (first(rd, 'Input') or {}).get('dados') or body
    pp = first(rd, 'Preparar Payload (Hyperflow Completo)') or {}
    err = (d.get('data') or {}).get('resultData', {}).get('error') or {}
    rows.append({
        'id': d.get('id'), 'erro_fetch': 0, 'inicio_brt': brt(d['startedAt']).isoformat(sep=' '), 'status': d.get('status'), 'entry': entry,
        'negotiation_id': dados.get('negotiation_id') or body.get('negotiation_id') or '',
        'contract_number': str((dados.get('data') or {}).get('contract_number') or pp.get('contract_number') or ''),
        'canal': pp.get('canal') or '', 'cellphone': pp.get('cellphone') or (dados.get('data') or {}).get('cellphone') or '',
        'ativar_hyper': int('Ativar Hyper' in rd), 'ativar_hyper1': int('Ativar Hyper1' in rd),
        'ah_stat': stat(rd, 'Ativar Hyper'), 'ah1_stat': stat(rd, 'Ativar Hyper1'),
        'err_node': (err.get('node') or {}).get('name', '') if isinstance(err.get('node'), dict) else '',
        'err_msg': (err.get('message') or '')[:180], 'nodes': '|'.join(rd.keys()),
    })
rows.sort(key=lambda r: r.get('inicio_brt') or '')
gravar_csv(os.path.join(out, 'exec_parsed.csv'), rows)
print('exec_parsed.csv', len(rows), 'linhas;', sum(r.get('erro_fetch') == 1 for r in rows), 'com erro de download (404 = execução podada, ignorar)')
