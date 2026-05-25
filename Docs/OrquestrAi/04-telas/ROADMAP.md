# Tela: Roadmap

> Kanban de iniciativas por frente. Derivado da análise de roadmap (`Gestao/Analises/<>/2026-05-19_roadmap-ia-automacoes-jessica.md`). Última atualização: 21/05/2026.

## Fontes

- 24 iniciativas RM01-RM24 (do BOARD copy.html, geradas pela análise de roadmap)
- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md) §RF-RM
- [SCHEMA_POSTGRES.md](../03-dominio/SCHEMA_POSTGRES.md) §3.13 roadmap_items

## Rotas

- `/roadmap` — kanban
- `/roadmap/[id]` — modal detalhe

---

## 1 · Kanban (6 frentes)

```
┌── Esperanza (6) ──┐ ┌── Valentina (5) ─┐ ┌── Clara (4) ────┐ ┌── Torre (5) ──┐ ┌── Auto (2) ──┐ ┌── Estrat (2) ─┐
│ RM01 Conclusão …  │ │ RM07 Identificar │ │ RM12 Compro-    │ │ RM16 Integr.  │ │ RM21 Bitrix  │ │ RM23 NPS     │
│  [alta] [2P]      │ │  originador      │ │  vantes endereço │ │  Rhino Torre  │ │  histórico   │ │  jornada     │
│ ────────────────  │ │  [alta] [1P]     │ │  [alta] [1P]    │ │  [media] [1P] │ │  [media] [1P]│ │  [alta] [1P] │
│ RM02 Mapear vol.  │ │ RM08 Mapear      │ │ RM13 Tratativa  │ │ RM17 Valid.   │ │ RM22 Hyper   │ │ RM24 Discov. │
│  [alta] [1P]      │ │  Rhino           │ │  reprovados     │ │  dashboards   │ │  gatilhos    │ │  narrativa   │
│ ────────────────  │ │  [alta] [1P]     │ │  [alta] [1P]    │ │  [media] [1P] │ │  [media] [1P]│ │  [alta] [1P] │
│ RM03 Tabulações   │ │ RM09 Roteam.     │ │ RM14 Biometria  │ │ RM18 Valid.   │ │              │ │              │
│  [media] [1P]     │ │  Rhino (urg.)    │ │  [alta] [1P]    │ │  relatórios   │ │              │ │              │
│ ────────────────  │ │  [alta] [1P]     │ │ ────────────────│ │  [media] [1P] │ │              │ │              │
│ RM04 Discovery    │ │ RM10 Base ctx    │ │ RM15 Raia Bitrix│ │ RM19 RCS      │ │              │ │              │
│  [alta] [1P]      │ │  [alta] [1P]     │ │  reembolso      │ │  [baixa] [1P] │ │              │ │              │
│ ────────────────  │ │ RM11 MCPs        │ │  [alta] [1P]    │ │ RM20 Intelig. │ │              │ │              │
│ RM05 Relat. pré-T │ │  [media] [1P]    │ │                 │ │  específicas  │ │              │ │              │
│ RM06 Números IA   │ │                  │ │                 │ │  [media] [1P] │ │              │ │              │
└───────────────────┘ └──────────────────┘ └─────────────────┘ └───────────────┘ └──────────────┘ └──────────────┘
```

### Estrutura visual

```css
.kanban { display: grid; grid-template-columns: repeat(6, minmax(220px, 1fr)); gap: 12px; overflow-x: auto; }
.kcol { background: #FAFAFC; border: 1px solid var(--border); border-radius: var(--radius-md); padding: 12px; }
.kcol-head { display: flex; justify-content: space-between; padding: 0 4px 12px; }
.kcol-head .ttl { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .1em; color: var(--text-muted); }
.kcol-head .ct { font-family: mono; font-size: 10px; background: var(--surface); padding: 1px 6px; border-radius: 99px; }
.kcard { background: var(--surface); border: 1px solid var(--border); border-radius: 6px; padding: 10px; margin-bottom: 8px; cursor: pointer; }
.kcard:hover { box-shadow: var(--shadow-sm); border-color: var(--finza-blue-soft); }
```

### Cores das frentes (header da coluna)

| Frente | Cor (`--frente-*`) |
|---|---|
| Esperanza | `#1A1AFF` (azul Finza) |
| Valentina | `#6B5BFF` (roxo) |
| Clara | `#00B8D4` (cyan) |
| Torre | `#FF6B35` (laranja) |
| Automações | `#10B981` (verde) |
| Estratégica | `#8B5CF6` (roxo profundo) |

---

## 2 · Card de iniciativa

```
┌──────────────────────────────┐
│ RM01                          │  ← id mono pequeno
│ Conclusão da renegociação de │  ← título weight 500
│ valores vencidos             │
│                              │
│ [ALTA] · 2P                  │  ← prioridade + count pendências
└──────────────────────────────┘
```

---

## 3 · Modal detalhe

```
┌──── Modal ───────────────────────────────────────────┐
│ RM01 · Conclusão da renegociação de valores vencidos │
├──────────────────────────────────────────────────────┤
│ [esperanza] [ALTA] [nao-iniciado]                    │
│ Owner: João Vinícius · criada 19/05                  │
│                                                      │
│ PENDÊNCIAS VINCULADAS (2)                            │
│ [P16] [P17]                                          │
│                                                      │
│ PROGRESSO                                            │
│ ▓░░░░░░░░░ 0%                                        │
└──────────────────────────────────────────────────────┘
```

---

## 4 · Form (V1)

MVP: roadmap é **read-only** — gerado pela análise de roadmap. V1: form para editar progresso, status, owner.

| Campo | Tipo | Default |
|---|---|---|
| id | text readonly | auto `RM${N+1}` |
| title | text | — |
| frente | select | enum 6 frentes |
| status | select | `nao-iniciado` |
| prioridade | select | enum |
| pendencias_vinculadas | multi-select de pendências | `[]` |
| progresso | number 0-100 | 0 |
| owner | text | João Vinícius |

---

## 5 · API

| Método | Path |
|---|---|
| GET | `/api/roadmap` |
| GET | `/api/roadmap/{id}` |
| PATCH | `/api/roadmap/{id}` (V1) |

---

## 6 · Interações

| Evento | Comportamento |
|---|---|
| Click card | Abre modal detalhe |
| Click pendência vinculada [P16] | Abre modal da pendência |
| V1: Drag entre colunas | Muda frente |

---

## 7 · Histórico

| Versão | Data | Mudança |
|---|---|---|
| **v2** | **2026-05-21** | Doc criado. Roadmap como módulo do produto. |
