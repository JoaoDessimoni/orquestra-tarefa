# Tela: Reuniões

> Notas de reunião com pauta, participantes, decisões e pendências geradas. Última atualização: 21/05/2026.

## Fontes

- `Gestao/Reunioes/` (3 reuniões reais 15-18/05/2026)
- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md) §RF-RU
- [SCHEMA_POSTGRES.md](../03-dominio/SCHEMA_POSTGRES.md) §3.12 reunioes

## Rotas

- `/reunioes` — grid de cards
- `/reunioes/[id]` — modal detalhe

---

## 1 · Listagem (cards)

```
┌──── Card 1 (dotted) ──────────────────────┐  ┌──── Card 2 ──────────┐
│ 🗓 Jornada do Cliente Finza               │  │ 🗓 Alinhamento Jéssi.│
│ 15/05/2026 · externa · 1h · 2 part.       │  │ 18/05 · alinhamento  │
│                                           │  │                      │
│ Pauta: alinhar entendimento da jornada    │  │ Revisão completa do  │
│ completa do cliente Finza e identificar   │  │ roadmap de IA &      │
│ pontos onde a IA atual deve evoluir.      │  │ Automações...        │
│                                           │  │                      │
│ [5 pendências geradas]                    │  │ [15 pendências]      │
│ [diretoria] [jornada-cliente] [valentina] │  │ [jessica] [roadmap]  │
└───────────────────────────────────────────┘  └──────────────────────┘
```

### Conteúdo do card

- Título (h3, weight 600)
- Meta: data · tipo · duração · N participantes
- Excerpt (3 linhas)
- Pill com count de pendências geradas
- Top 3 tags

### Filtros

- Busca textual
- Tipo: alinhamento / review / brainstorm / externa / 1on1
- Período: hoje / 7d / 30d / custom
- Participante (V1)

---

## 2 · Modal detalhe

```
┌──── Modal (dotted) ──────────────────────────────────┐
│ 🗓 Alinhamento Jéssica — revisão geral Roadmap       │
├──────────────────────────────────────────────────────┤
│ 18/05/2026 · alinhamento · 1h                        │
│ Participantes: Jéssica (Gerente Cobrança), João V.    │
│ ─────────────────────────────────                    │
│ Revisão completa do roadmap de IA & Automações.      │
│ 4 seções: Agentes IA (Esperanza, Valentina, Clara),  │
│ Torre, Automações e Regras Operacionais.             │
│                                                      │
│ PENDÊNCIAS GERADAS (15)                              │
│ [P16] [P17] [P18] [P19] [P20] [P22] [P23] [P24]      │
│ [P29] [P30] [P31] [P32] [P33] [P34] [P35]            │
├──────────────────────────────────────────────────────┤
│                              [Fechar] [Editar]       │
└──────────────────────────────────────────────────────┘
```

Tags `[P16]` clicáveis → abrem modal de pendência.

---

## 3 · Form criar/editar

| Campo | Tipo | Default | Validação |
|---|---|---|---|
| id | text readonly | auto `R${N+1}` | seq |
| title | text | — | required |
| data | date | hoje | required |
| tipo | select | `alinhamento` | enum |
| duracao | text | `1h` | livre (1h, 30min, 2h) |
| participantes | chipinput | `[]` | multi |
| tags | chipinput | `[]` | max 10 |
| body_excerpt | textarea | — | max 1000 |

**Pendências geradas**: V1+ permite multi-select dos IDs de pendências existentes. MVP: vínculo manual (campo `pendencias_geradas` no JSON).

---

## 4 · API

| Método | Path |
|---|---|
| GET | `/api/reunioes` |
| GET | `/api/reunioes/{id}` |
| POST | `/api/reunioes` |
| PATCH | `/api/reunioes/{id}` |
| DELETE | `/api/reunioes/{id}` |
| POST | `/api/export/reunioes/{id}` |

---

## 5 · Estados

- Loading: 4 skeleton cards.
- Empty: "Nenhuma reunião. + Nova Reunião".
- Erro: ErrorState.

---

## 6 · Histórico

| Versão | Data | Mudança |
|---|---|---|
| **v2** | **2026-05-21** | Doc criado. Reuniões promovidas a módulo de produção. |
