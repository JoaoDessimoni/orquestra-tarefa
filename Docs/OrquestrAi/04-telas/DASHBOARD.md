# Tela: Dashboard — Produção & Gestão

> Página inicial. **Foco em produção e gestão do supervisor IAF** (não em métricas de agente IA). Última atualização: 21/05/2026.

## Fontes

- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md) §RF-DB
- [COMPONENTES.md](../07-design-system/COMPONENTES.md) §1.8 hero-dark
- `BOARD.html` (v2 — implementação de referência)

## Rota

`/dashboard` (também `/` → redirect)

---

## 1 · Objetivo

Em um relance, o supervisor sabe:

- Quantos **itens demandam atenção esta semana** (pendências c/ deadline + reuniões + análises em rascunho + relatórios pendentes).
- **Distribuição de pendências** por prioridade e status.
- **Próximas deadlines** (top 6) com indicador de urgência/atraso.
- **Análises em andamento** com link direto.
- **Próximas reuniões** (7 dias).
- **Atalhos** para criar Pendência/Análise/Relatório/Reunião/Agente/Skill.

**Anti-objetivo**: dashboard de métricas IA (essas vivem em `/executions`).

---

## 2 · Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  ◆ iaf                                                          │
│  h1.ghost · Dashboard — accent(Produção & Gestão)               │
│  sub · panorama executivo do supervisor IAF                     │
├─────────────────────────────────────────────────────────────────┤
│  ┌── HERO DARK ─────────────────────────────────────────────┐  │
│  │  Esta semana · 21 de maio de 2026                         │  │
│  │  ─── 11 itens demandam atenção (font 26 weight 300)       │  │
│  │                                                           │  │
│  │  5 pend.    2 reun.    3 anál.    1 rel.                  │  │
│  │  c/ deadline próx. 7d   rascunho   aguardando             │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  KPI grid · 5 cards dotted                                     │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐                                       │
│  │26│ │ 3│ │ 2│ │ 1│ │24│                                       │
│  └──┘ └──┘ └──┘ └──┘ └──┘                                       │
│  pend abertas · reun (total) · anál rascunho · rel curso · iniciat │
│                                                                 │
│  ┌─ Por prioridade ────┐  ┌─ Por status ────────┐               │
│  │ ▓▓▓▓▓▓ alta · 17    │  │ ▓▓▓▓ aberta · 22    │               │
│  │ ▓▓▓▓ media · 8     │  │ ▓ em-curso · 1     │               │
│  │ ▓ baixa · 1        │  │ — bloqueada · 0    │               │
│  │                    │  │ ▓▓ fechada · 3     │               │
│  └────────────────────┘  └─────────────────────┘                │
│                                                                 │
│  Deadlines próximas →  [tabela compacta dotted]                │
│  P21  Resgatar relatório pré-Torre        22/05  [em 1d]       │
│  P09  Falar com Vinícius Cunha (1775)     22/05  [em 1d]       │
│  P11  Decidir com Marcos a raia           22/05  [em 1d]       │
│  P15  Valentina roteamento Rhino (urg.)   26/05  [em 5d]       │
│  P22  Mapear agentes IA por número         26/05  [em 5d]       │
│  P20  Discovery Esperanza                  29/05  [em 8d]       │
│                                                                 │
│  ┌─ Análises em andamento ────┐  ┌─ Atalhos rápidos ──┐         │
│  │ 🔍 Roadmap Q3 2026          │  │ + Nova Pendência  │         │
│  │   rascunho · 25 vinculadas │  │ + Nova Análise    │         │
│  │ 🔍 Cruzamento demandas      │  │ + Novo Relatório  │         │
│  │   rascunho · 5 vinculadas  │  │ + Nova Reunião    │         │
│  └────────────────────────────┘  │ + Novo Agente     │         │
│                                  │ + Nova Skill      │         │
│                                  └────────────────────┘         │
│                                                                 │
│                                  ┌─ Próximas reuniões ┐         │
│                                  │ Nenhuma agendada   │         │
│                                  │ [+ Agendar nova]   │         │
│                                  └────────────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3 · Componentes

### 3.1 Hero dark (esta semana)

Spec em [COMPONENTES.md §1.8](../07-design-system/COMPONENTES.md). Calcula:

```js
const today = TODAY;
const in7 = today + 7 dias;
const heroNumbers = {
  pendWeek:  pendencias.filter(p => p.deadline && p.deadline <= in7 && p.status !== 'fechada').length,
  reunWeek:  reunioes.filter(r => r.data >= today && r.data <= in7).length,
  analDraft: analises.filter(a => a.status === 'rascunho').length,
  relDraft:  relatorios.filter(r => r.status in ['rascunho','revisao']).length,
};
const total = pendWeek + reunWeek + analDraft + relDraft;
```

Big number: `${total} itens demandam atenção` em 26px peso 300 com `itens` como `.accent`.

### 3.2 KPI cards (5 cards dotted)

| KPI | Fórmula | Delta |
|---|---|---|
| Pendências abertas | `count(status != 'fechada')` | `X alta · Y média` |
| Reuniões (total) | `count(reunioes)` | `Z próximas 7d` |
| Análises rascunho | `count(status='rascunho')` | `Total: N` |
| Relatórios em curso | `count(status in [rascunho, revisao])` | `Total: N` |
| Iniciativas roadmap | `count(roadmap)` | `24 vinculadas a P12-P36` |

### 3.3 Barchart inline — Por prioridade

Linhas: alta (--danger fill), media (--warning fill), baixa (--neutral fill). Width % proporcional ao max.

### 3.4 Barchart inline — Por status

Linhas: aberta (--neutral), em-curso (--info), bloqueada (--danger), fechada (--success).

### 3.5 Deadlines próximas (tabela)

Top 6 pendências ordenadas por `deadline` ascending, `status != 'fechada'`.

| Coluna | Conteúdo |
|---|---|
| ID | mono | P21 |
| Título | weight 500 |
| Prio. | badge |
| Deadline | mono (fmtDate) |
| Em Xd | badge urgência: <0 → danger (atraso), ≤7 → warning, >7 → neutral |

Click → modal de detalhe da pendência.

### 3.6 Análises em andamento

Cards compactos clickáveis para análises com `status='rascunho'`. Top 3.

### 3.7 Atalhos rápidos

Side-items estilizados com bg `--surface`. Acionam `openForm(entity)`:
- + Nova Pendência
- + Nova Análise
- + Novo Relatório
- + Nova Reunião
- + Novo Agente
- + Nova Skill

### 3.8 Próximas reuniões

Lista compacta de reuniões com `data` entre hoje e hoje+7d. Se vazio: empty state com CTA "+ Agendar nova".

---

## 4 · Dados consumidos

```ts
GET /api/dashboard → {
  hero: { pendWeek, reunWeek, analDraft, relDraft },
  kpis: { pendOpen, reunTotal, analDraft, relDraft, roadmapTotal, pendByPrio, pendByStatus },
  deadlines: [...top 6 pendencias],
  analyses_in_progress: [...top 3 analises rascunho],
  next_meetings: [...reunioes próximas 7d],
}
```

V0 protótipo: tudo derivado de `DB` em memória/localStorage.

---

## 5 · Estados

- **Loading**: skeletons em KPIs e hero-dark.
- **Empty (zero pendências, etc.)**: hero mostra "0 itens" + mensagem positiva "Tudo em ordem por aqui".
- **Erro de API**: fallback "Não foi possível carregar o Dashboard. [Tentar novamente]".

---

## 6 · Interações

| Evento | Comportamento |
|---|---|
| Click KPI | Navega para listagem da entidade |
| Click linha "Deadlines próximas" | Abre modal de detalhe da pendência (não navega) |
| Click card "Análise em andamento" | Abre modal de detalhe da análise |
| Click "+ Atalho" | `openForm(entity)` — modal de criação |
| Click "+ Agendar nova reunião" | `openForm('reuniao')` |

---

## 7 · Acessibilidade

- Hero dark `role="region" aria-label="Resumo desta semana"`
- KPI numbers com `aria-label` legível ("vinte e seis pendências abertas")
- Barchart: tabular alternativa via `<details>` opcional V1+

---

## 8 · Performance

- Cache local em React Query 30s
- Bar widths animados com transição (entrada)
- Hero glow radial gradient via `::after` pseudo-elemento (não dispara repaint)

---

## 9 · Histórico

| Versão | Data | Mudança |
|---|---|---|
| v1 | 2026-05-20 | KPIs de agente IA (light Linear) — descartado |
| **v2** | **2026-05-21** | Reformulação completa: hero-dark + KPIs de produção + barcharts + deadlines + atalhos. Foco supervisor IAF. |
