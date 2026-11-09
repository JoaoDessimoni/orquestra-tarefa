"""Funções compartilhadas pelos scripts do raio-x da Clara. Só leitura (GET) em todo lugar."""
import csv, datetime as dt, json, os, re, sys, urllib.request

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..'))

# IDs fixos da esteira da Clara (ver SKILL.md, "Onde mora cada dado")
WF_ACIONAMENTO = 'eA8E5LjPtA2bXVce'      # n8n-prod-automacao: Webhook Plataforma - Análise de Documentos
WF_CLARA = 'uEJKmrPILPNwYNGQ'            # n8n-prod-assistants: Clara - Formalização
DEPT_FORMALIZACAO = {'blips': '6a80917d9e841905d20806e0', 'finza': '6a70b455e2304d735ed7477b'}
AGENTE_TORRE = {'blips': '418fb5c2-0804-4dfe-b9a7-9425b0d23939', 'finza': 'b9939d16-9acd-4937-b717-55cd90d297e9'}


def env(ambiente):
    """URL e KEY do n8n a partir do .env do repo (ambiente: PROD_AUTOMACAO, PROD_ASSISTANTS...)."""
    e = dict(re.findall(r'^([A-Z_0-9]+)=(.*)$', open(os.path.join(REPO, '.env'), encoding='utf-8').read(), re.M))
    clean = lambda v: v.strip().strip('"').strip("'")
    return clean(e[f'N8N_{ambiente}_URL']).rstrip('/'), clean(e[f'N8N_{ambiente}_KEY'])


def n8n_get(base, key, path, timeout=180):
    req = urllib.request.Request(base + path, headers={'X-N8N-API-KEY': key, 'Accept': 'application/json'})
    for i in range(4):
        try:
            return json.load(urllib.request.urlopen(req, timeout=timeout))
        except (TimeoutError, OSError):
            if i == 3: raise


def listar_execucoes(base, key, wf):
    out, cur = [], None
    while True:
        d = n8n_get(base, key, f'/api/v1/executions?workflowId={wf}&limit=250&includeData=false' + (f'&cursor={cur}' if cur else ''))
        out += d.get('data', [])
        cur = d.get('nextCursor')
        if not cur or len(out) > 50000:
            return out


def brt(s):
    """ISO UTC do n8n/BQ -> datetime BRT ingênuo."""
    return dt.datetime.strptime(s[:19].replace(' ', 'T'), '%Y-%m-%dT%H:%M:%S') - dt.timedelta(hours=3)


def P(s):
    return dt.datetime.fromisoformat(s[:19].replace('T', ' ')) if s else None


def chave_tel(ph):
    """DDD + 8 últimos dígitos: única chave que casa plataforma, n8n, Hyperflow e banco da Clara."""
    d = re.sub(r'\D', '', ph or '')
    if d.startswith('55') and len(d) > 11:
        d = d[2:]
    return d[:2] + d[-8:] if len(d) >= 10 else ''


def ler_csv(p):
    return list(csv.DictReader(open(p, encoding='utf-8'))) if os.path.exists(p) else []


def gravar_csv(p, rows):
    if not rows:
        open(p, 'w').close(); return
    w = csv.DictWriter(open(p, 'w', newline='', encoding='utf-8'), fieldnames=list(rows[0].keys()))
    w.writeheader(); w.writerows(rows)


def bq(sql, out_csv):
    from google.cloud import bigquery
    c = bigquery.Client(project='blips-bigdata')
    job = c.query(sql)
    res = job.result()
    cols = [f.name for f in res.schema]
    rows = [{k: r[k] for k in cols} for r in res]
    w = csv.writer(open(out_csv, 'w', newline='', encoding='utf-8'))
    w.writerow(cols)
    for r in rows:
        w.writerow([r[k] for k in cols])
    print(os.path.basename(out_csv), 'linhas', len(rows), 'GB', round((job.total_bytes_billed or 0) / 1e9, 2))
    return rows


if __name__ == '__main__':
    assert chave_tel('+55 (43) 98830-9878') == '4388309878'
    assert chave_tel('4398830-9878') == '4388309878'
    assert chave_tel('5543988309878') == '4388309878'
    assert chave_tel('123') == ''
    assert brt('2026-10-01T01:16:00.000Z') == dt.datetime(2026, 9, 30, 22, 16)
    print('ok')
