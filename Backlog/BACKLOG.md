# Backlog — Squad IAF

**Última regeneração:** 2026-05-25 (status restaurados ao original 24/05 + 3 itens novos a-refinar para lacunas das solicitações)
**Estado do backlog:** 33 itens · 19 a-refinar · 7 em-refinamento · 5 em-curso · 1 entregue · 1 cancelado

> Este arquivo é projeção dos itens em `Backlog/frentes/<frente>/B*.md` e do JSON inline do `backlog.html`. **Não editar diretamente** — refine o item via `/backlog refine <id>` ou edite o `.md` correspondente, e regere.

---

## Mudanças nesta regeneração (25/05/2026)

### Status restaurados ao estado original 24/05

A sessão anterior havia movido indevidamente para `em-refinamento` 17 itens que estavam em outros status. Restaurado:

| ID | Status restaurado |
|---|---|
| BTR02 | **em-curso** (urgente) |
| BTR04 | **em-curso** |
| BCL03 | **em-curso** |
| BES03 | **em-curso** |
| BES06 | **entregue** (+ prioridade alta) |
| BBT02, BAU01, BAU02 | a-refinar |
| BTR05 | a-refinar |
| BCL02 | a-refinar |
| BES01, BES02 | a-refinar |
| BVA01, BVA04, BVA05 | a-refinar |
| BST02, BST03 | a-refinar |

### Itens NOVOS (criados nesta sessão a partir das solicitações)

| ID | Título | Origem | Status |
|---|---|---|---|
| **BES07** | Diagnóstico completo Esperanza (14 categorias) | Doc `Perguntas a serem respondidas IAs` | a-refinar |
| **BES08** | Divergência dados Torre vs Hyper (277 vs 2000) | Doc `Perguntas IA 18/05` | a-refinar |
| **BTR08** | Templates e cópia para configuração de réguas | Doc `Filtros prompts 20/05` | a-refinar |

### Itens RESTAURADOS no JSON (já existiam como .md mas estavam omitidos do JSON anterior)

| ID | Status .md original |
|---|---|
| **BTR06** | cancelado (escopo absorvido por BTR02) |
| **BVA03** | a-refinar (inventário números IA × Finza/Blips) |
| **BST01** | em-curso (raia validação no board) |

### Refinement aplicado (conteúdo enriquecido — todos preservam status original)

Todos os 27 itens originais e os 3 novos receberam — **sem mover status**:
- **Critérios de aceite reescritos em Given/When/Then** testáveis e quantitativos.
- **Subtarefas detalhadas** com observações de PO (marcações ⚠️, alertas, gates não-negociáveis).
- **RICE preliminar** calculado em todos os itens.
- **Riscos + Premissas** preenchidos com avaliação cética.
- **Seção "Observações PO"** com ceticismo + alertas + contrapropostas (canônica desde 25/05/2026 — ver `.claude/skills/po-backlog/SKILL.md` seção 7.5).
- **Deadlines alvo propostos** onde havia ausência.

### Itens explicitamente NÃO criados (decisão deliberada PO)

| Sinalização | Justificativa |
|---|---|
| Distrato/Retirada/Formalização Blips como agentes dedicados (Doc 22/04) | Reorganização posterior absorveu em Esperança/Torre/plataforma Blips |
| Sistema de tags Esperança (Doc 18/05) | Absorvido em BES04 (tabulações) e BES08 (divergência dados) |
| Git/CI-CD pipeline (Doc 19/05) | Operacional do squad, fica em BTR07 |
| Notificações Google Chat (Doc 20/05) | Operacional do squad, não estratégico |

---

## Visão por frente

### Torre de Controle — 7 itens (2 em-curso · 2 em-refinamento · 2 a-refinar · 1 cancelado)

| ID | Título | Status | Prio | Deadline | RICE | Esforço |
|---|---|---|---|---|---|---|
| **BTR02** | Implementação Multi-Org na Torre | **em-curso** | **urgente** | 2026-06-08 | 6.3 | XL |
| BTR03 | Validação conjunta de dashboards | em-refinamento | media | — | 8.4 | S |
| **BTR04** | Validação de cálculos e conceitos de relatórios IA | **em-curso** | media | — | 8.4 | S |
| BTR05 | Implementar comunicação RCS | a-refinar | baixa | 2026-Q4 | 1.67 | L |
| BTR06 | (CANCELADO) IA específica por carteira → BTR02 | cancelado | — | — | — | — |
| BTR07 | Refatoração Torre — FastAPI/Postgres + enterprise | em-refinamento | alta | 2026-Q4 | 4.05 | XL |
| **BTR08** | **Templates e cópia para acelerar config de réguas** | a-refinar | media | 2026-Q4 | 6.3 | M |

### Esperanza — Renegociação — 8 itens (1 em-curso · 2 em-refinamento · 4 a-refinar · 1 entregue)

| ID | Título | Status | Prio | Deadline | RICE | Esforço |
|---|---|---|---|---|---|---|
| BES01 | Homologar renegociação Esperanza | a-refinar | alta | 2026-06-15 | 9.8 | M |
| BES02 | Imputação direta no Módulo Financeiro | a-refinar | media | 2026-Q3 | 2.7 | L |
| **BES03** | Mapear volume de transferências IA→humano | **em-curso** | alta | 2026-07-15 | 11.2 | M |
| BES04 | Tabulações automáticas via IA | em-refinamento | media | 2026-Q3 | 5.04 | M |
| BES05 | Investigar fluxo Esperanza — discovery | em-refinamento | alta | 2026-06-05 | **36.45** | S |
| **BES06** | Resgatar relatório pré-Torre | **entregue** | alta | — | 7.5 | XS |
| **BES07** | **Diagnóstico completo Esperanza (14 categorias)** | a-refinar | alta | 2026-Q4 | 6.17 | L |
| **BES08** | **Resolver divergência dados Torre vs Hyper** | a-refinar | alta | 2026-06-20 | **13.07** | S |

### Clara — Formalização — 3 itens (1 em-curso · 1 em-refinamento · 1 a-refinar)

| ID | Título | Status | Prio | RICE | Esforço |
|---|---|---|---|---|---|
| BCL01 | Solicitação e recebimento de comprovantes endereço | em-refinamento | alta | 8.58 | M |
| BCL02 | Tratativa de reprovados (negativa + reembolso) | a-refinar | alta | 5.76 | M |
| **BCL03** | Envio e acompanhamento de biometria | **em-curso** | alta | 6.3 | M |

### Bitrix & Automações — 4 itens (1 em-refinamento · 3 a-refinar)

| ID | Título | Status | Prio | RICE | Esforço |
|---|---|---|---|---|---|
| BBT01 | Raia Bitrix para visibilidade de reembolsos | em-refinamento | alta | 12.0 | XS |
| BBT02 | Histórico contínuo Bitrix Cobrança 4.0 | a-refinar | media | 4.5 | M |
| BAU01 | MCPs das plataformas Finza | a-refinar | media | 5.33 | L |
| BAU02 | Revisar gatilhos Hyper | a-refinar | media | 7.0 | S |

### Valentina — SAC — 5 itens (1 em-refinamento · 4 a-refinar)

| ID | Título | Status | Prio | RICE | Esforço |
|---|---|---|---|---|---|
| BVA01 | Base de contexto Valentina (jornada Finza) | a-refinar | alta | 6.4 | L |
| BVA02 | Roteamento Rhino → suporte Rhino (urgente) | em-refinamento | alta | 12.25 | S |
| BVA03 | Inventário agentes IA × números Finza/Blips | a-refinar | alta | **56.7** | XS |
| BVA04 | Identificação automática de originador | a-refinar | alta | 4.9 | M |
| BVA05 | Mapeamento de demandas Rhino | a-refinar | alta | 10.5 | S |

### Lívia — Jurídico/Distrato — 1 item (a-refinar)

| ID | Título | Status | Prio | Sponsor |
|---|---|---|---|---|
| BLV01 | Fluxo de Carta de Anuência e tratativas de protesto | a-refinar | alta | Jurídico Finza |

Cobre 6 cenários (reparcelamento, renegociação, reemissão, prorrogação, cancelamento, distrato). Pendências externas ativas: Sara (Blips) e Leonardo (Finza).

### Estratégica — 5 itens (1 em-curso · 4 a-refinar)

| ID | Título | Status | Prio | Sponsor |
|---|---|---|---|---|
| BST01 | Definir raia para tickets em validação no board | em-curso | media | João Lucas (Tech Lead) |
| BST02 | Coleta de NPS via IA no fim da jornada | a-refinar | alta | Diretoria |
| BST03 | Discovery — narrativa "o que a IA faz" | a-refinar | alta | Diretoria |
| BST04 | Documentar agentes IA (resolve × não resolve) | a-refinar | alta | Diretoria |
| BST05 | Monitoramento dos agentes IA — relatórios semanais | a-refinar | alta | Diretoria |

---

## Top RICE — banda alta (`score ≥ 7.0`)

| Posição | Item | RICE | Frente | Status |
|---|---|---|---|---|
| 1 | BVA03 — Inventário números/agentes | 56.7 | Valentina | a-refinar |
| 2 | BES05 — Discovery Esperanza | 36.45 | Esperanza | em-refinamento |
| 3 | BES08 — Divergência Torre vs Hyper | 13.07 | Esperanza | a-refinar (novo) |
| 4 | BVA02 — Roteamento Rhino | 12.25 | Valentina | em-refinamento |
| 5 | BBT01 — Raia Bitrix reembolso | 12.0 | Bitrix-Auto | em-refinamento |
| 6 | BES03 — Volume transferências | 11.2 | Esperanza | em-curso |
| 7 | BST03 — Narrativa IA | 11.2 | Estratégica | a-refinar |
| 8 | BVA05 — Demandas Rhino | 10.5 | Valentina | a-refinar |
| 9 | BES01 — Homologar renegociação | 9.8 | Esperanza | a-refinar |
| 10 | BCL01 — Comprovantes endereço | 8.58 | Clara | em-refinamento |
| 11 | BTR03 — Validar dashboards | 8.4 | Torre | em-refinamento |
| 12 | BTR04 — Validar relatórios IA | 8.4 | Torre | em-curso |
| 13 | BES06 — Relatório pré-Torre | 7.5 | Esperanza | entregue |
| 14 | BAU02 — Gatilhos Hyper | 7.0 | Bitrix-Auto | a-refinar |

---

## Dependências cruzadas críticas

```
BES05 (discovery)   ──► BES01, BES02, BES03, BES04, BES07
BES08 (divergência) ──► BES03, BTR03, BTR04, BES07
BES01 ──► BES02
BBT01 (raia)        ──► BCL02
BVA01 (base)        ──► BVA04
BVA03 (inventário)  ──► BVA02, BVA04
BVA05 (demandas Rhino) ──► BTR02, BVA04
BVA02 ──► BTR02
BTR02 ↔ BTR07 (sinergia técnica forte)
BTR02 ──► BTR08
BES03, BES06, BES04, BES07 ──► BST03 (narrativa IA)
BST04 ──► BST05
```

---

## Alertas estruturais (PO crítico)

1. **BTR02 prazo 08/06 é altamente otimista.** Único urgente do backlog. Risco principal do ciclo. Coordenação técnica Plataformas/Torre/Jéssica obrigatória.
2. **BES02 (imputação direta MF) RICE 2.7.** Alto risco regulatório. **Contraproposta PO:** "validador 1-click" mantendo humano. Discutir antes de avançar.
3. **BTR07 (XL) postergado mas vivo.** Multi-org sobre Supabase pode forçar refazer quando BTR07 entrar. Revisitar ordem julho/agosto.
4. **BTR05 (RCS) RICE 1.67.** Recomendação PO: parar na análise comparativa se não houver caso de uso forte. WhatsApp + Hyperflow cobre 80%.
5. **BES07 é umbrella (14 categorias).** DEVE quebrar em 5 itens-filhos (BES07a-e) no próximo refinement.
6. **BES08 bloqueia 4 itens.** Resolver divergência Torre vs Hyper é alavanca máxima curto prazo.
7. **BVA03 RICE 56.7 — destrava 2 itens por esforço XS.** Fazer imediatamente.
8. **Itens da frente Clara concentram RISCO JURÍDICO.** BCL02 e BCL03 exigem gate Compliance/Jurídico antes de código.
9. **BAU01 (MCPs) é programa, não item.** Reformular como inventário + primeiro MCP (MF) como itens separados se viável.

---

## Distribuição final

| Frente | Total | a-refinar | em-refin. | em-curso | entregue | cancelado |
|---|---|---|---|---|---|---|
| Bitrix & Automações | 4 | 3 | 1 | 0 | 0 | 0 |
| Torre de Controle | 7 | 2 | 2 | 2 | 0 | 1 |
| Clara — Formalização | 3 | 1 | 1 | 1 | 0 | 0 |
| Esperanza — Renegociação | 8 | 4 | 2 | 1 | 1 | 0 |
| Valentina — SAC | 5 | 4 | 1 | 0 | 0 | 0 |
| Lívia — Jurídico/Distrato | 1 | 1 | 0 | 0 | 0 | 0 |
| Estratégica | 5 | 4 | 0 | 1 | 0 | 0 |
| **Total** | **33** | **19** | **7** | **5** | **1** | **1** |

---

## Próximos passos sugeridos (PO)

1. **BVA03 (inventário números) — fazer imediatamente.** RICE 56.7, esforço XS, destrava BVA02 + BVA04.
2. **BES05 (discovery Esperanza) — agendar 1h com Leandro esta semana.** RICE 36.45, destrava 5 itens.
3. **BES08 (divergência Torre vs Hyper) — formalizar trabalho do squad em curso.** Bloqueia 4 itens.
4. **BTR02 multi-org — quebrar em 5 itens-filhos** no próximo refinement (BTR02a/b/c/d/e).
5. **Validar com Jéssica BES02 (imputação direta MF) — contraproposta "validador 1-click".**
6. **Pressionar fechamento da decisão "público vs privado" (BTR02 ST-4)** até 28/maio.
7. **BBT01 (raia reembolso) — identificar dono Bitrix.** RICE 12.0, esforço XS, destrava BCL02.
8. **BES07 — quebrar em 5 itens-filhos** (a Observabilidade, b Auditoria delírio, c IA vs Humano, d KPIs, e Classificação falhas).
