# Tela: Relatórios

> CRUD de Relatórios derivados de Análises. Cada relatório tem 1 destinatário e 1 classificação. Última atualização: 20/05/2026.

## Fontes

- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md) §RF-RP
- [REGRAS_DE_NEGOCIO.md](../03-dominio/REGRAS_DE_NEGOCIO.md) §5
- [SCHEMA_POSTGRES.md](../03-dominio/SCHEMA_POSTGRES.md) §3.8

## Rotas

- `/reports`
- `/reports/new?analysis=<slug>` (analysis-fonte é obrigatória → recomenda passar via query)
- `/reports/[slug]`
- `/reports/[slug]/edit`

---

## 1 · /reports — Lista

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│  Relatórios                              [⌘K]  [+ Novo Relatório]    │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  [🔍 Buscar...] [Destinatário ▾] [Status ▾] [Classificação ▾]        │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ TÍTULO              DESTINATÁRIO   STATUS    CLASS    DATA      ││
│  ├─────────────────────────────────────────────────────────────────┤│
│  │ Repasse semanal     Leonardo CTO   enviado   interno  2026-05-19││
│  │ Devolutiva NPS      Felipe         rascunho  restrito 2026-05-18││
│  │ Síntese roadmap     Roberta        revisao   interno  2026-05-17││
│  └─────────────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────────┘
```

### Colunas

| Coluna | Sortable |
|---|---|
| Título | ✓ |
| Destinatário | ✓ |
| Status | ✓ |
| Classificação | ✓ |
| Data (updated_at) | ✓ (default desc) |
| Análise-fonte (mobile-hide) | — |

### Filtros

- Busca em título + destinatário
- Destinatário: dropdown com unique destinatarios
- Status: multi (rascunho, revisao, enviado)
- Classificação: multi (interno, restrito, publico)

### API

`GET /api/reports?q=...&destinatario=...&status=...&classificacao=...&page=1&limit=20&sort=updated_at:desc`

---

## 2 · /reports/new — Form

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│  Relatórios / Novo                          [Cancelar] [Salvar]      │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Identificação                                                       │
│  ────────────────────────                                            │
│  Título*           [Repasse semanal — Leonardo                ]       │
│  Slug*             [repasse-semanal-leonardo                  ] auto  │
│  Análise-fonte*    [🔍 demandas-cobranca-time-negocio ▾] ⓘ          │
│  Destinatário*     [Leonardo (CTO)                            ]       │
│                                                                      │
│  Classificação                                                       │
│  ────────────────────────                                            │
│  Classificação*    ◉ interno   ○ restrito   ○ publico                │
│  Tags              [repasse×] [cto×] [+]                              │
│                                                                      │
│  Conteúdo                                                            │
│  ┌──── Editor ───────────────┬──── Preview ──────────────────┐     │
│  │  ## Resumo                │  ## Resumo                    │     │
│  │  ...                      │  ...                          │     │
│  └───────────────────────────┴───────────────────────────────┘     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Campos

| Campo | Tipo | Default | Validação |
|---|---|---|---|
| título* | text | — | required, max 200 |
| slug* | text | auto-gen | regex, único |
| analysis_id* | autocomplete | pré-preenchido se `?analysis=slug` | required, FK existente |
| destinatário* | text | — | required, max 200 |
| classificação* | radio | `interno` | enum |
| tags | chips | `[]` | max 10 |
| body_md | markdown | "" | max 100000 |
| status (no edit) | select | `rascunho` | transições válidas (RN-26) |

### Comportamentos

- Se URL tem `?analysis=slug`, pré-preenche `analysis_id` (não-editável após criar).
- Slug auto-gen baseado em `título`.
- Análise-fonte tem ⓘ tooltip: "Apenas análises publicadas permitem relatório `enviado`".

---

## 3 · /reports/[slug] — Detalhe

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│  Relatórios / repasse-semanal-leonardo   [Editar] [Enviar] [⋮ Mais]  │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  📤 Repasse semanal — Leonardo                                       │
│  para: Leonardo (CTO) · interno · enviado · 2026-05-19              │
│  análise-fonte: ◆ demandas-cobranca-time-negocio  →                  │
│  [repasse] [cto]                                                     │
│                                                                      │
│  ── Conteúdo ──────────────────────────                              │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  ## Resumo                                                   │  │
│  │  ...                                                         │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ── Export ──────────────────────────                                │
│  ✓ Exportado em: 2026-05-19 14:30                                    │
│  Path: /workspace/Repasse/Gestao/Analises/18-05-2026/Relatorio/     │
│        2026-05-19_repasse-semanal-leonardo.md                        │
│  [Exportar novamente]                                                │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Ações header

- **Editar** → `/reports/{slug}/edit`
- **Enviar** (visível em revisao) → muda status para `enviado`, valida RN-25
- **⋮ Mais**:
  - Voltar para rascunho (se em revisao)
  - Exportar `.md`
  - Arquivar (soft-delete, mantém se enviado — RN-27)
  - Duplicar (cria novo `rascunho` com mesmo body, slug `-copy`)

### Seções

- Header: meta + análise-fonte (link)
- Conteúdo (MarkdownViewer)
- Export panel (mostra status e path; botão re-export)

### API

- `GET /api/reports/{slug}`
- `PATCH /api/reports/{id}/status` body `{status: "enviado"}`
- `POST /api/export/reports/{slug}` → exporta `.md`
- `DELETE /api/reports/{id}` → soft-delete (bloqueado se enviado, vira "arquivar")

---

## 4 · Geração assistida via Agente (V1+ — RF-RP-05)

Botão "✨ Gerar com agente" no form `/reports/new` (visível V1+):

1. Modal pede: agente (selector) + template ("Redija relatório para <destinatario> baseado em <analise>").
2. Dispara execução com analysis + destinatario como input.
3. Streaming na própria página (componente compacto).
4. Output preenche `body_md` ao terminar.

**MVP: não implementado.** Apenas marcado como roadmap.

---

## 5 · Estados

- Loading: skeleton
- Empty (lista): "Nenhum relatório ainda" + CTA
- Erro: ErrorState
- 404 detalhe: NotFoundState

---

## 6 · Validações específicas

| Cenário | Comportamento |
|---|---|
| Tentativa de status `enviado` com análise não-publicada | Toast danger: "A análise-fonte precisa estar publicada" + bloqueio (RN-25) |
| Tentativa de excluir relatório `enviado` | Modal: "Este relatório foi enviado. Você pode apenas arquivar." → botão "Arquivar" (soft-delete) |
| Mudança de análise-fonte após criar | Bloqueada (FK fixa). Para mudar, criar novo relatório. |
