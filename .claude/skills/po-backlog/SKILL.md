---
name: po-backlog
description: Princípios canônicos de Product Ownership do supervisor IAF — INVEST, Given/When/Then, escala de camisetas, definição das 7 frentes Finza, RICE simplificado, anti-padrões. Carregue antes de qualquer operação de backlog (criação, refinamento, priorização) ou ao referenciar item de backlog em outros artefatos (decks, análises, status).
---

# Product Ownership — Backlog IAF

Princípios canônicos para criação, refinamento e priorização de itens em `Backlog/`. Carregue esta skill em todo agente/comando que toca em backlog.

---

## 1 · As 7 frentes da Finza

| Frente | Prefix ID | Pasta | Escopo | Sponsor padrão | Plataforma Finza |
|---|---|---|---|---|---|
| **Bitrix & Automações** | `BBT##` / `BAU##` | `bitrix-automacoes/` | CRM Bitrix24 (BBT) + infra de automação técnica HyperFlow/MCPs (BAU) | Jéssica | Bitrix Cobrança 4.0 + HyperFlow |
| **Torre de Controle** | `BTR##` | `torre/` | SaaS multi-tenant de cobrança — multi-org, refatoração, dashboards, relatórios, novos originadores, canais | Jéssica | Torre de Controle v2 |
| **Clara (Formalização)** | `BCL##` | `clara/` | Agente IA Clara — comprovantes, biometria, reprovados | Jéssica | Plataforma Blips + Veritas |
| **Esperanza (Renegociação)** | `BES##` | `esperanza/` | Agente IA Esperanza — cobrança WhatsApp, renegociação, métricas | Jéssica | Torre de Controle + Esperanza |
| **Valentina (SAC)** | `BVA##` | `valentina/` | Agente IA Valentina — SAC/N1, roteamento, base de contexto | Jéssica / Diretoria | Esperanza-style multi-canal |
| **Lívia (Jurídico/Distrato)** | `BLV##` | `livia/` | Agente IA Lívia — fluxos jurídicos, distrato, compliance jurídico | Jurídico Finza | (a definir conforme discovery) |
| **Estratégica** | `BST##` | `estrategica/` | Transversal — NPS, narrativa IA, processo de squad, governança | Diretoria | N/A (corte transversal) |

> A frente **Bitrix & Automações** é unificada (fusão das ex-frentes Bitrix e Automações em 22/05/2026) — aceita os dois prefixos para preservar IDs históricos.

### Critério de inclusão em "Estratégica"

Um item é Estratégica SE:
- Não tem frente operacional única (toca 3+ frentes), OU
- É decisão de governança/processo, OU
- É comunicação executiva (narrativa, deck para diretoria), OU
- É métrica de jornada completa (NPS, CSAT, satisfação)

Caso contrário, vai para a frente operacional específica.

---

## 2 · INVEST — Princípios para histórias bem escritas

**I — Independent:** Item não bloqueia 5+ outros. Se bloqueia, é épico — quebrar.
**N — Negotiable:** Escopo é discutível com sponsor. Não é spec rígida.
**V — Valuable:** Sponsor identificado. Valor claro para o usuário final descrito na história.
**E — Estimable:** Tem esforço camiseta (XS/S/M/L/XL) e RICE preenchido (após refinement).
**S — Small:** Pode ser entregue em 1 trimestre. Se é XL, quebrar em 2-3 itens menores.
**T — Testable:** Tem pelo menos 2 critérios de aceite Given/When/Then.

### Exemplo bom (INVEST OK)

```
Como Jéssica (gerente de cobrança),
quero que cada conversa Esperanza seja categorizada por tipo de tabulação automaticamente,
para gerar indicadores de tipo de chamado sem tabulação manual.

CA-1: Given conversa encerrada, When pós-processamento roda,
  Then registro contém campo `tabulacao` não-nulo em >80% dos casos.
```

### Exemplo ruim (anti-padrões)

```
"Implementar tabulações automáticas"      ← Tarefa, não história. Sem usuário, valor, contexto.
"Melhorar Esperanza"                       ← Não-testável. Não-mensurável.
"Como dev, quero refatorar o módulo X"     ← Usuário interno raramente entrega valor de negócio.
```

---

## 3 · Given/When/Then — Critérios de aceite testáveis

Cada CA tem 3 elementos:
- **Given** — pré-condição observável.
- **When** — ação ou gatilho.
- **Then** — resultado verificável (idealmente quantitativo).

### Mau exemplo (vago)

```
- Sistema funciona bem para clientes.
```

### Bom exemplo (testável)

```
- Given cliente reprovado em compliance com entrada paga
- When Clara comunica negativa
- Then mensagem enviada em <30s, com tom humano (validado por amostra de 10 mensagens),
  e link de dados de reembolso anexado
```

### Regra prática

Se não consigo construir um teste/observação que verifica o CA, ele não está testável. Reescreva.

---

## 4 · Escala de esforço — Camisetas

Camisetas, não story points. Sem velocity histórica não há story point calibrado — camisetas carregam a mesma informação com menos pretensão.

| Camiseta | Dev-semanas equivalentes | Exemplo âncora |
|---|---|---|
| **XS** | <1 semana | Mudança de prompt em produção; ajuste de template; configuração de raia |
| **S** | 1-3 semanas | Nova tela CRUD simples; relatório novo; integração ponto-a-ponto leve |
| **M** | 3-6 semanas | Nova entidade no schema com migração; classificador IA novo; dashboard novo |
| **L** | 6-12 semanas | Nova frente de integração (ex: ETL de origem nova); refatoração arquitetural |
| **XL** | >12 semanas | Nova plataforma; reescrita de subsistema |

**Regra:** se item é XL, ele deve ser quebrado em 2-3 itens menores antes de seguir.

---

## 5 · RICE simplificado — Priorização

**Fórmula:**
```
score = (reach × impact × confidence) / (effort × 10)
```

**Cada variável usa escala 1-10:**

| Variável | 1 | 5 | 10 |
|---|---|---|---|
| **Reach** | 1 caso isolado | dezenas de operações | toda a Finza |
| **Impact** | cosmético | novo recurso útil | desbloqueia frente |
| **Confidence** | palpite | conversa rápida | spec validada com sponsor |
| **Effort** | <1 dev-semana | ~5 dev-semanas | >10 dev-semanas |

**Banda derivada do score:**
- `score >= 7.0` → **urgente** (com confirmação de sponsor de restrição temporal)
- `5.0 <= score < 7.0` → **alta**
- `2.0 <= score < 5.0` → **media**
- `score < 2.0` → **baixa**

**Banda `urgente` requer dupla validação:**
1. RICE score ≥ 7.0 (sinal quantitativo).
2. Sponsor declara explicitamente restrição temporal crítica (sinal qualitativo).

Sem o segundo critério, item com score alto vira `alta`, não `urgente`. Princípio: `urgente` é raro e custoso — degrada confiança quando aplicado em demasia.

### Override manual

Sponsor (Jéssica, Diretoria, CTO) pode sobrepor a banda calculada quando há contexto além do RICE (urgência regulatória, política, contrato). Override é registrado no histórico do item — não disfarçado de número.

---

## 6 · Anti-padrões a evitar

| Anti-padrão | Por quê é ruim | Como corrigir |
|---|---|---|
| **História = tarefa** ("Implementar X") | Sem usuário, sem valor, sem contexto | Reescrever: "Como <usuário>, quero <Y>, para <Z>" |
| **CA não-testável** ("funciona bem") | Não dá pra verificar nem provar entrega | Given/When/Then com resultado mensurável |
| **Subtarefa sem responsável** | Vira "alguém faz" e ninguém faz | Atribuir pessoa ou marcar "a definir" |
| **RICE preguiçoso (tudo 5)** | Não diferencia, não informa priorização | Pensar cada eixo separadamente, ancorar com exemplos |
| **Item XL não-quebrado** | Não cabe em 1 trimestre, vira eterno | Quebrar em 2-3 itens M/L |
| **Item órfão (sem sponsor)** | Ninguém quer, ninguém valida | Negar criação ou marcar `bloqueado` até identificar sponsor |
| **Item órfão (sem origem)** | Não dá pra explicar de onde veio | Pelo menos 1 referência (pendência, reunião, análise, solicitação) |
| **Refinar 10 itens de uma vez** | Refinement consome contexto; qualidade cai | 1-2 itens por sessão com profundidade |
| **CA copiando subtarefa** | CA é observável; subtarefa é ação | CA é "como verifico que entregou", subtarefa é "como faço" |

---

## 7 · Definição de Pronto (DoD) padrão

Todo item entregue deve atender (adapte por item se necessário):

- [ ] Todos os critérios de aceite verificados (não-vazios, não-vagos, executáveis)
- [ ] Sponsor (Jéssica/Diretoria) validou a entrega
- [ ] Documentação técnica em `Docs/` (se aplicável) ou em `Backlog/contexto/` (se backlog-specific)
- [ ] Métricas de cobertura/qualidade publicadas (se há dashboard relacionado)
- [ ] Pelo menos 2 semanas de produção sem regressão crítica

---

## 7.5 · Observações PO — voz cética obrigatória após refinement

A partir do refinement-pass de **25/05/2026**, todo item refinado carrega uma seção **"Observações PO"** (ou bloco análogo no JSON do `backlog.html`). Não é decoração — é a voz cética do PO que protege o supervisor de levar adiante demandas perigosas, redundantes ou mal-formuladas.

**O que entra:**
- Gates não-negociáveis antes de código (Compliance, Jurídico, LGPD, validação de premissa).
- Contrapropostas concretas quando o pedido original é mais arriscado do que necessário (ex: BES02 — "validador 1-click" em vez de IA imputando direto no MF).
- Sugestões de quebra em itens-filhos para itens umbrella (XL ou multi-categoria).
- Risco político — alertas sobre como entrega pode ser lida (NPS punitivo? Diagnóstico que enfraquece narrativa?).
- Marcações ⚠️ em subtarefas críticas para sinalização visual em escala.

**O que NÃO entra:**
- Riscos puramente técnicos (vão para `riscos:`).
- Premissas não-validadas (vão para `premissas:`).
- Tarefa do que fazer (vai para `subtarefas`).

**Princípio:** "Não tudo que o negócio pede vai pra frente." Item de backlog não é fila de pedidos — é proposta de valor avaliada. Observações PO marcam onde o supervisor precisa parar, pensar, ou contrapropor antes de empurrar para execução.

---

## 8 · Glossário

| Termo | Definição |
|---|---|
| **Item** | Unidade de backlog. Um `.md` em `Backlog/frentes/<frente>/`. Tem história, CA, subtarefas, RICE. |
| **Frente** | Categoria estratégica. Existem 7 fixas. |
| **Sponsor** | Quem do negócio quer o item entregue. Padrão: Jéssica para Esperanza/Torre/Clara/Bitrix-Automações; Diretoria para Estratégica/Valentina-base; Jurídico Finza para Lívia. |
| **Owner** | Quem é responsável (gerencia o item). Default: João Vinícius. |
| **Implementador** | Quem efetivamente codifica. Pode ser null se ainda não atribuído. |
| **Refinement** | Sessão de detalhamento — escrever história, CA, subtarefas, calcular RICE. Move item de `a-refinar` → `em-refinamento` (parcial) ou `refinado` (completo). |
| **Subtarefa** | Objeto com id, title, description, responsavel, esforco, prazo, status, dependencias, historico. Vive dentro do item. |
| **Status** | a-refinar · em-refinamento · refinado · em-curso · bloqueado · cancelado · entregue · arquivado |
| **Prioridade** | urgente · alta · media · baixa (urgente = RICE ≥ 7.0 + sponsor declara restrição temporal) |
| **RICE** | Reach × Impact × Confidence / Effort × 10. Score 1-100. |
| **Camiseta** | Escala de esforço XS/S/M/L/XL. |
| **P##** | ID histórico de pendência tática (subsistema `Gestao/Pendencias/` **aposentado em 27/05/2026**; `Gestao/` migrada para `Backlog/` em 2026-06-15). Sobrevive só como rótulo de origem em `origem.pendencias` — não há mais arquivo. Tático agora é subtarefa do item. |
| **RM##** | ID de iniciativa do Roadmap original (RM01..RM24). Itens de backlog podem materializar uma iniciativa via campo `roadmap_vinculado`. |
| **B<prefix>##** | ID de item de backlog. Prefixes: BBT (Bitrix), BAU (Automações), BTR (Torre), BCL (Clara), BES (Esperanza), BVA (Valentina), BLV (Lívia), BST (Estratégica). |

---

## 9 · Fontes canônicas

- Itens individuais: `Backlog/frentes/<frente>/B*.md`
- Visão consolidada: `Backlog/BACKLOG.md` (regenerada por `/backlog regenerate`)
- Solicitações originais do negócio: `Backlog/solicitacoes/`
- Docs de apoio: `Backlog/contexto/` (Torre overview, Esperanza overview)
- Agente operador: `.claude/agents/po-backlog.md`
- Comando: `.claude/commands/backlog.md`
