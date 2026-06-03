---
description: Gera resumo executivo da semana — lê Backlog/frentes/, Gestao/Reunioes/, Analises/, 1on1s/ e produz overview de itens de backlog em curso, reuniões realizadas, análises produzidas. Sem agente externo — leitura direta + síntese.
---

# /status — status semanal do supervisor

Use no fim da semana (ou quando o usuário pedir) para produzir resumo executivo do estado do squad e da gestão.

## Passo 1 — Janela temporal

`$ARGUMENTS` pode ser:
- vazio → últimos 7 dias (default).
- `--mes` → últimos 30 dias.
- `--sprint` → desde a última segunda-feira.
- `--desde=YYYY-MM-DD` → data customizada.

## Passo 2 — Coletar

Use Glob + Read para juntar:

1. **Backlog em curso**
   - `Glob Backlog/frentes/**/B*.md` (exclua `README.md`).
   - Leia frontmatter de cada (id, title, frente, status, prioridade, rice.score, deadline_alvo).
   - Filtrar: `status ∈ {em-curso, bloqueado}` + itens `refinado` com prioridade `urgente`/`alta`.
   - Ordenar: prioridade (urgente > alta > media > baixa) → RICE score desc → deadline mais próxima.

2. **Backlog movimentado na janela**
   - Itens `entregue`/`cancelado` cuja última entrada de histórico cai na janela.
   - Itens criados/refinados na janela (sinaliza vazão de refinement).

3. **Reuniões na janela**
   - `Glob Gestao/Reunioes/**/*.md` (recursivo — pasta datada).
   - Filtrar por nome do arquivo (`YYYY-MM-DD-*.md`) onde data >= data-corte.

4. **Análises na janela**
   - `Glob Gestao/Analises/**/*.md` (recursivo).
   - Ignorar arquivos em subpasta `Relatorio/` quando o objetivo é listar análises.

5. **Relatórios na janela** (opcional, se janela for ≤7 dias)
   - `Glob Gestao/Analises/**/Relatorio/*.md`.
   - Lista separada no status: "Relatórios enviados".

6. **1:1s na janela**
   - `Glob Gestao/1on1s/**/*.md` (recursivo) filtrado por data no nome.

7. **Decks produzidos na janela**
   - `Glob Apresentacoes/executando/*.html` + `Apresentacoes/entregues/*.html`.
   - Filtrar por data no nome (`<tema>_<destino>_DD-MM-YYYY.html`).

## Passo 3 — Sintetizar

Produza o status no formato canônico:

```markdown
# Status semanal — Squad IAF

**Período:** YYYY-MM-DD → YYYY-MM-DD
**Supervisor:** João Vinícius

## Resumo executivo
<2-3 linhas: estado geral, principais avanços, principais bloqueadores>

## Backlog
**Em curso:** N · **Bloqueados:** B · **Refinados aguardando:** R
**Movimentado no período:** entregues M · cancelados C · refinados novos K

### Críticos (urgente/alta + bloqueados)
| ID | Frente | Título | RICE | Deadline |
|---|---|---|---|---|
| BTR02 | torre | Multi-Org — Rhino + x-api-key | 12.5 | 2026-06-09 |

### Próximos a vencer (≤14 dias)
| ID | Frente | Título | Deadline |

### Movimentado no período
| ID | Frente | Título | Mudança |

## Reuniões
- **YYYY-MM-DD** — <título> · <participantes> · <decisão chave em 1 linha>
- ...

## 1:1s
- **YYYY-MM-DD** — <pessoa> · <highlight>

## Análises produzidas
- <título> (YYYY-MM-DD) · <1 linha>

## Decks/apresentações
- <nome> · <destino> · <data>

## Bloqueadores
<itens de backlog bloqueados (status=bloqueado) com motivo + o que/quem destrava>

## Próxima semana — foco
<3-5 itens prioritários derivados do que ficou aberto>

## Sinalizações para o CTO
<2-3 itens que merecem visibilidade de Leonardo nesta semana — decisões pendentes fora do squad, riscos, métricas>
```

## Passo 4 — Persistir (opcional)

Pergunte ao usuário se quer salvar o status como arquivo:

```
Salvar este status em Gestao/Analises/YYYY-MM-DD_status-semanal.md?
```

Se sim, Write o markdown acima nesse caminho.

## Regras

- **Datas absolutas** sempre. Calcule a partir de "hoje" (do contexto), mas grave em ISO.
- **Não invente sinalizações.** Se a janela só teve trabalho cotidiano sem nada para o CTO, escreva "Sem sinalizações para esta semana."
- **Resumo executivo curto.** 2-3 linhas, direto. Sem preâmbulo.
- **Tom técnico-executivo.** Mesma voz dos slides Finza — sem jargão, números absolutos.
