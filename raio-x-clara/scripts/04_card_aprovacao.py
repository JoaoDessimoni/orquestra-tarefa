"""Coletas concluídas pela Clara e se o card de aprovação foi enviado ao time -> card_aprovacao.json.

Uso: python 04_card_aprovacao.py <pasta_saida>
Lê as execuções do fluxo "Clara - Formalização" no n8n-prod-assistants (só GET).
A retenção lá é de ~12 dias: rode logo após o fim do mês ou só terá a cauda do período.
A instância é compartilhada com Valentina e Esperanza: 2 downloads por vez, nunca mais.
Guarda só o resumo de cada execução (summ/), nunca a execução inteira.
"""
import json, os, re, sys
from concurrent.futures import ThreadPoolExecutor
from comum import env, n8n_get, listar_execucoes, WF_CLARA

out = sys.argv[1]
os.makedirs(os.path.join(out, 'summ'), exist_ok=True)
U, K = env('PROD_ASSISTANTS')
lst = listar_execucoes(U, K, WF_CLARA)
print('execuções Clara - Formalização', len(lst), 'desde', min((e['startedAt'] for e in lst), default='-'))


def resumo(e):
    p = os.path.join(out, 'summ', f"{e['id']}.json")
    if os.path.exists(p):
        return json.load(open(p))
    try:
        d = n8n_get(U, K, f"/api/v1/executions/{e['id']}?includeData=true", timeout=300)
    except Exception as x:
        return {'id': e['id'], 'err': str(x)}
    rd = (d.get('data') or {}).get('resultData', {}).get('runData', {}) or {}
    first = lambda n: (rd.get(n) or [{}])[0].get('data', {}).get('main', [[{}]])[0][0].get('json') if rd.get(n) else None
    saida = (first('Clara') or {}).get('output', '') or ''
    r = {'id': e['id'], 't': d['startedAt'], 'nid': (first('Variáveis Globais') or {}).get('negotiation_id', ''),
         'completa': (first('Reavaliar Coleta') or {}).get('coleta_completa') is True, 'card': 'notificar_negocios' in rd,
         'encaminhei': bool(re.search(r'encaminhei|encaminhad|enviei para an[aá]lise', saida, re.I))}
    json.dump(r, open(p, 'w'))
    return r


with ThreadPoolExecutor(max_workers=2) as x:
    res = list(x.map(resumo, lst))
por = {}
for r in sorted((r for r in res if r.get('nid')), key=lambda r: r['t']):
    v = por.setdefault(r['nid'], {'completa': False, 'card': False, 'encaminhei': False, 'concluida_em': ''})
    if r['completa'] and not v['completa']:
        v['completa'], v['concluida_em'] = True, r['t']
    v['card'] |= r['card']; v['encaminhei'] |= r['encaminhei']
conc = {n: v for n, v in por.items() if v['completa']}
json.dump(conc, open(os.path.join(out, 'card_aprovacao.json'), 'w'), indent=1)
print('coletas concluídas', len(conc), '| sem card', sum(not v['card'] for v in conc.values()), '| erros de download', sum('err' in r for r in res))
