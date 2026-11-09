"""Cruza tudo e gera <pasta>/contratos.csv (1 linha por contrato) e <pasta>/metricas.json (números da página).

Uso: python 03_metricas.py <pasta_saida> <data_corte AAAA-MM-DD>
Entradas obrigatórias: base.csv, exec_parsed.csv, chats_ia.csv, eventos_contato.csv, aprovacao_anexo.csv, torre_protocolos.csv
Opcionais (indicadores CLA): clara-db/q2_mensagens.csv, q3_documentos.csv, q4_vereditos.csv, q6_decisoes.csv; card_aprovacao.json (passo 04)
"""
import collections, datetime as dt, json, os, re, statistics, sys
from comum import P, chave_tel, ler_csv, gravar_csv, DEPT_FORMALIZACAO

D, CORTE = sys.argv[1], dt.datetime.fromisoformat(sys.argv[2])
f = lambda n: os.path.join(D, n)
CORE = ['identidade', 'comprovante_residencial', 'comprovante_empresa', 'comprovante_entrega']
PUB = ('BLIPS', 'FINZA')   # público da Clara; IDEAL fica como informação adicional

base = ler_csv(f('base.csv'))
ex = [x for x in ler_csv(f('exec_parsed.csv')) if x.get('erro_fetch') == '0']
ok = lambda r: (r['ativar_hyper'] == '1' and r['ah_stat'] == 'OK') or (r['ativar_hyper1'] == '1' and r['ah1_stat'] == 'OK')
exn = collections.defaultdict(list)
for x in ex:
    if x['negotiation_id']: exn[x['negotiation_id']].append(x)
hyk = collections.defaultdict(list)
for h in ler_csv(f('chats_ia.csv')):
    h['t'] = P(h['ts_e']); hyk[chave_tel(h['sender'])].append(h)
evc = collections.defaultdict(list)
for e in ler_csv(f('eventos_contato.csv')): evc[e['nid']].append(e)
anx = {x['nid'] for x in ler_csv(f('aprovacao_anexo.csv'))}
tor = {}
for t in ler_csv(f('torre_protocolos.csv')):
    if t['first_user']: tor[t['protocol']] = (t['org'], P(t['first_user']) - dt.timedelta(hours=3))  # Torre grava UTC

# banco da Clara (opcional)
cdb = lambda n: f(os.path.join('clara-db', n))
TEM_DB = os.path.exists(cdb('q3_documentos.csv'))
q2 = {x['negotiation_id']: x for x in ler_csv(cdb('q2_mensagens.csv')) if x['negotiation_id']}
q3 = collections.defaultdict(set)
for x in ler_csv(cdb('q3_documentos.csv')): q3[x['negotiation_id']].add(x['tipo'])
q4 = collections.defaultdict(list)
for x in ler_csv(cdb('q4_vereditos.csv')):
    if re.fullmatch(r'[0-9a-f]{24}', x.get('conversa_id') or ''): q4[x['conversa_id']].append(x)
for v in q4.values(): v.sort(key=lambda x: (int(x['mensagem_id']), int(x['ordem_na_mensagem'])))
q6 = collections.defaultdict(list)
for x in ler_csv(cdb('q6_decisoes.csv')): q6[x['negotiation_id']].append(x)

rows = []
for b in base:
    ra, ck, kk = P(b['ra']), P(b['ck']), chave_tel(b['cel'])
    e = exn.get(b['nid'], []); ac = [x for x in e if ok(x)]
    fim = ra + dt.timedelta(days=30)
    chats = [h for h in hyk.get(kk, []) if ra - dt.timedelta(hours=1) <= h['t'] <= fim] if kk else []
    resp_t = any(h['protocol'] in tor for h in chats)
    m, docs, an = q2.get(b['nid'], {}), q3.get(b['nid'], set()), q4.get(b['nid'], [])
    canal = 'blips' if any(x['ativar_hyper'] == '1' for x in ac) else ('finza' if ac else '')
    # por que o acionado não virou conversa: eventos do contato perto do acionamento
    ev = [y for y in evc.get(b['nid'], []) if y['ten'] == canal]
    sem_conv = '' if (not ac or chats) else ('sem registro no Hyperflow' if not ev else
               'chat da Clara já existia' if any(y['department'] == DEPT_FORMALIZACAO[canal] for y in ev) else 'cliente em chat com vendedor/outro depto')
    dec = sorted(q6.get(b['nid'], []), key=lambda x: x['decidido_brt'])
    rows.append(dict(
        nid=b['nid'], contrato=b['contrato'], marca=b['marca'], tipo=b['tipo'], sale_type=b['sale_type'], mes=b['ra'][:7], ra=b['ra'], ck=b['ck'],
        fase=b['fase_atual'], desistiu=b['desistiu'], post=int(bool(e)), acionado=int(bool(ac)), canal=canal,
        bloqueio_vista=int(any('Avisar - Motivo' in x['nodes'] for x in e)),
        erro_no=next((x['err_node'] for x in e if x['err_node']), '') if not ac else '',
        chat=int(bool(chats)), sem_conversa=sem_conv, resp_torre=int(resp_t),
        resp_db=int(int(m.get('n_msgs_cliente') or 0) > 0), env=int(int(m.get('n_msgs_com_arquivo') or 0) > 0 or bool(an) or bool(docs)),
        apr=int(bool(docs) or any(a['aprovado_prefiltro'] == 'true' for a in an)), kit=int(all(t in docs for t in CORE)),
        anexado=int(b['nid'] in anx), decisao=dec[-1]['decisao'] if dec else '',
        completo=int(bool(ck)), completo30=int(bool(ck and ck <= fim)), ciclo_d=round((ck - ra).total_seconds() / 86400, 2) if ck else ''))
gravar_csv(f('contratos.csv'), rows)

pct = lambda a, b: round(100 * a / b, 1) if b else None
S = lambda rr, k: sum(int(r[k]) for r in rr)
meses = sorted({r['mes'] for r in rows})
res = {'corte': sys.argv[2], 'tem_banco_clara': TEM_DB, 'meses': {}, 'semanas': {}, 'aging': {}, 'torre': {}}

for mes in meses:
    M = [r for r in rows if r['mes'] == mes]
    pub = [r for r in M if r['marca'] in PUB]
    def funil(rr):
        return dict(turma=len(rr), acionado=S(rr, 'acionado'), conversa=S(rr, 'chat'), respondeu_torre=S(rr, 'resp_torre'),
                    respondeu=sum(1 for r in rr if r['resp_torre'] or r['resp_db']), enviou=S(rr, 'env'), aprovado_preanalise=S(rr, 'apr'),
                    kit_completo=S(rr, 'kit'), aprovado_anexado=S(rr, 'anexado'), formalizado_30d=S(rr, 'completo30'), formalizado=S(rr, 'completo'))
    na = [r for r in pub if not r['acionado']]
    sc = [r for r in pub if r['acionado'] and not r['chat']]
    fechados = [float(r['ciclo_d']) for r in pub if r['ciclo_d'] != '']
    q = lambda v, p: round(statistics.quantiles(v, n=10)[p], 1) if len(v) >= 2 else None
    kit = [r for r in pub if r['kit']]
    res['meses'][mes] = {
        'publico': funil(pub), 'BLIPS': funil([r for r in M if r['marca'] == 'BLIPS']), 'FINZA': funil([r for r in M if r['marca'] == 'FINZA']),
        'IDEAL': dict(turma=sum(r['marca'] == 'IDEAL' for r in M), acionado=sum(r['acionado'] for r in M if r['marca'] == 'IDEAL'),
                      bloqueio_vista=sum(r['bloqueio_vista'] for r in M if r['marca'] == 'IDEAL'), formalizado=sum(r['completo'] for r in M if r['marca'] == 'IDEAL')),
        'nao_acionados': dict(collections.Counter('plataforma não chamou o n8n' if not r['post'] else 'bloqueio venda à vista' if r['bloqueio_vista']
                                                  else f"erro no nó {r['erro_no']}" if r['erro_no'] else 'sem erro registrado' for r in na)),
        'acionados_sem_conversa': dict(collections.Counter(f"{r['canal']}: {r['sem_conversa']}" for r in sc)),
        'ciclo_dias': dict(fechados=len(fechados), mediana=round(statistics.median(fechados), 1) if fechados else None, p90=q(fechados, 8)),
        'decisao_kit': dict(collections.Counter('aprovado e anexado' if r['anexado'] else 'aprovado sem anexo' if r['decisao'] == 'aprovar'
                                                else 'reprovado pelo time' if r['decisao'] == 'reprovar' else 'sem decisão' for r in kit)),
    }
    if TEM_DB:  # CLA-04 pendências e CLA-05 envios até aprovar
        pend, att = collections.Counter(), collections.Counter()
        for r in pub:
            an = q4.get(r['nid'], [])
            if r['env'] and not r['kit']:
                for t in CORE:
                    if t in q3.get(r['nid'], set()): continue
                    a = [x for x in an if x['tipo_esperado'] == t]
                    pend[f"{t}|{'reprovado' if a and not any(x['aprovado_prefiltro'] == 'true' for x in a) else 'pendente'}"] += 1
            by = collections.defaultdict(list)
            for x in an: by[x['tipo_esperado']].append(x)
            for v in by.values():
                k = next((i + 1 for i, x in enumerate(v) if x['aprovado_prefiltro'] == 'true'), None)
                if k: att['4+' if k >= 4 else str(k)] += 1
        res['meses'][mes].update(pendencias=dict(pend), contratos_com_pendencia=sum(1 for r in pub if r['env'] and not r['kit']), envios_ate_aprovar=dict(att))

# série semanal (segunda-feira da entrada na fase), público da Clara
wk = collections.defaultdict(lambda: [0, 0, 0, 0])
for r in rows:
    if r['marca'] not in PUB: continue
    d = P(r['ra']).date(); w = wk[(d - dt.timedelta(days=d.weekday())).isoformat()]
    w[0] += 1; w[1] += r['acionado']; w[2] += r['acionado'] and r['chat']; w[3] += r['acionado'] and r['chat'] and r['resp_torre']
res['semanas'] = {k: dict(zip(['turma', 'acionado', 'conversa', 'respondeu'], v)) for k, v in sorted(wk.items())}

# CLA-06 aging: em formalização no fim de cada mês e no corte (desistência é o status de hoje: aproximação)
for d in [dt.datetime.fromisoformat(m + '-01') for m in meses[1:]] + [CORTE]:
    ab = [r for r in rows if r['marca'] in PUB and P(r['ra']) <= d and not (r['ck'] and P(r['ck']) <= d) and r['desistiu'] != 'True']
    dias = [(d - P(r['ra'])).days for r in ab]
    res['aging'][(d - dt.timedelta(days=1)).date().isoformat() if d != CORTE else d.date().isoformat()] = {
        '0-2': sum(x <= 2 for x in dias), '3-5': sum(3 <= x <= 5 for x in dias), '6-10': sum(6 <= x <= 10 for x in dias), '>10': sum(x > 10 for x in dias)}

for org, t in tor.values():
    k = t.strftime('%Y-%m'); res['torre'].setdefault(k, collections.Counter())[org] += 1
res['torre'] = {k: dict(v) for k, v in sorted(res['torre'].items())}

if TEM_DB:
    rep = collections.defaultdict(collections.Counter)
    nids = {r['nid'] for r in rows if r['marca'] in PUB}
    for n, v in q4.items():
        if n in nids:
            for x in v:
                if x['aprovado_prefiltro'] == 'false': rep[x['tipo_esperado']][x['tipo_detectado']] += 1
    res['reprovacoes_preanalise'] = {t: dict(total=sum(c.values()), detectado=dict(c.most_common(6))) for t, c in rep.items()}
    todas = [x for v in q6.values() for x in v]
    res['decisoes_time'] = dict(collections.Counter(x['decisao'] for x in todas), reprovar_sem_motivo=sum(1 for x in todas if x['decisao'] == 'reprovar' and not x['motivo'].strip()))

if os.path.exists(f('card_aprovacao.json')):
    c = json.load(open(f('card_aprovacao.json')))
    res['card_aprovacao'] = dict(coletas_concluidas=len(c), sem_card=[n for n, v in c.items() if not v['card']],
                                 disse_encaminhei_sem_card=[n for n, v in c.items() if not v['card'] and v['encaminhei']])

json.dump(res, open(f('metricas.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
for mes, v in res['meses'].items():
    p = v['publico']
    print(mes, 'turma', p['turma'], '| acionado', p['acionado'], pct(p['acionado'], p['turma']), '% | conversa', p['conversa'], pct(p['conversa'], p['turma']),
          '% | respondeu(Torre)', p['respondeu_torre'], '| kit', p['kit_completo'], '| aprovado+anexado', p['aprovado_anexado'], '| formalizado', p['formalizado'])
    print('   não acionados', v['nao_acionados']); print('   sem conversa', v['acionados_sem_conversa'])
print('torre', res['torre'])
