# Referências — Squad IAF

Artefatos não-markdown de suporte: dados estruturados, scripts, prints, documentos.

## Estrutura

```
Backlog/referencias/
├── sql/        # Scripts SQL de manutenção/migração (DBA)
├── csv/        # Datasets estruturados, exports, reconciliações
├── json/       # Exports raw, changelogs, payloads de API
├── prints/     # Screenshots de consulta (era Backlog/prints/)
├── pdf/        # Documentos PDF de referência
└── docx/       # Documentos Word de referência
```

## Convenção de nome

`YYYY-MM-DD_<sistema>_<assunto>.<ext>` — ex: `2026-06-05_quimera_eventos-reconstruidos.csv`

Arquivos cujo nome já segue convenção de origem (ex: `lote_1.json`) podem manter o nome, desde que estejam na subpasta correta.

## Arquivos ativos

| Arquivo | Tipo | Descrição |
|---|---|---|
| `sql/2026-06-04_backfill-datas-quimera.sql` | SQL | Backfill Parte A+B (abordagem inicial) — rede de segurança |
| `sql/2026-06-05_backfill-status-history-quimera.sql` | SQL | **APLICÁVEL** — reconstrói histórico completo de status (369 eventos, 130 tickets). Trocar ROLLBACK→COMMIT após validar. |
| `csv/2026-06-04_dados-correcao-datas-quimera-jira.csv` | CSV | Tabela de reconciliação 130 tickets (Quimera↔Jira, 20 colunas) |
| `csv/2026-06-05_eventos-reconstruidos.csv` | CSV | 369 eventos de status reais extraídos do Jira (changelog) |
| `json/quimera-jira-changelog/lote_1..6.json` | JSON | Changelog raw do Jira (projeto IAF) por lote — source of truth para auditoria Cycle Time |
