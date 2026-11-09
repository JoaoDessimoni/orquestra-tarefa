"""Converte o resultado do MCP supabase-prod (sql/torre_protocolos.sql) em torre_protocolos.csv.

Uso: python torre_csv.py <arquivo_do_resultado_mcp> <pasta_saida>
O resultado grande do MCP é salvo em tool-results/*.txt; o JSON vem entre as marcas <untrusted-data-...>.
"""
import json, os, sys
from comum import gravar_csv

t = open(sys.argv[1], encoding='utf-8').read()
try:
    d = json.loads(t)
    t = d['result'] if isinstance(d, dict) else d[0]['text']
except ValueError:
    pass
arr = json.loads(t[t.index('['):t.rindex(']') + 1])
gravar_csv(os.path.join(sys.argv[2], 'torre_protocolos.csv'), arr)
print('torre_protocolos.csv', len(arr), 'protocolos')
