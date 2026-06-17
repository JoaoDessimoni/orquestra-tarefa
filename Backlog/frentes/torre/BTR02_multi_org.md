---
id: BTR02
title: Implementação Multi-Org na Torre
frente: torre
fonte: backlog
status: em-curso
prioridade: urgente
rice:
  reach: 9
  impact: 9
  confidence: 7
  effort: 9
  score: 6.3
esforco: XL
valor_negocio: alto
origem:
  pendencias: [P29]
  reunioes:
    - Backlog/reunioes/18-05-2026/2026-05-18-alinhamento-jessica-revisao-geral.md
    - Backlog/reunioes/19-05-2026/2026-05-19-alinhamento-torre-multi-org.md
    - Backlog/reunioes/20-05-2026/2026-05-20-filtros-prompts-trigger-agenda.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
    - Backlog/solicitacoes/Alinhamento Torre - 2026_05_19 15_47 GMT-03_00 - Anotações do Gemini.txt
    - Backlog/solicitacoes/Filtros prompts e Trigger agenda - 2026_05_20 16_59 GMT-03_00 - Anotações do Gemini.txt
  analises:
    - Backlog/analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM16
owner: João Vinícius
implementador: Marcos Rodrigues + João Lucas
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-06-09
dependencias: []
bloqueia: []
riscos:
  - **CRÍTICO** — Deadline declarado 09/jun é agressivo. Reunião 19/05 confirmou mapeamento de 79 tabelas, ETL, normalização — escopo concentrado em janela curta é alto risco.
  - Refatoração da Torre (BTR07) foi POSTERGADA explicitamente para priorizar multi-org. Decisão correta mas cria débito técnico que crescerá.
  - Migração de schema com produção rodando exige janela de cutover — sem ambiente HML maduro (P01 Torre), risco operacional alto.
  - "Definir o que é público vs privado entre orgs" (Doc 20/05) ainda não fechado — sem essa decisão, schema_public vs schema_org pode ser refeito.
  - Backup antes de mudança estrutural foi exigido em reunião 20/05 — operacional não-negociável.
premissas:
  - Cronograma Marcos Rodrigues + Joao Lucas: mapeamento e limpeza até 04/jun, deploy 08/jun (reunião 19/05).
  - Time Plataformas + IAF tem capacidade para entregar XL no Q3.
  - Decisão "schema_public para recursos compartilhados, demais schemas migram para org" (reunião 19/05) é estável.
  - Diretoria mantém prioridade `urgente` declarada.
tags: [torre, multi-org, rhino, originador, urgente, jessica, xl, cutover]
---

# BTR02 — Implementação Multi-Org na Torre

## História de usuário

Como **gestor de cobrança**,
quero **operar múltiplos originadores na Torre com isolamento de dados, regras e configuração por organização**,
para **absorver Rhino e futuros clientes sem reescrita por carteira nem improviso operacional**.

## Contexto

**Iniciativa-mãe da frente Torre — prioridade `urgente`.**

A Torre opera hoje em modelo single-org com adaptações por carteira. Com a entrada de Rhino como novo originador (e perspectiva de outros clientes em sequência), o modelo precisa virar **multi-org real**.

**Origens convergentes (3 docs):**
1. Doc `2026-05-18_jessica_roadmap-ia-automacoes.txt` — demanda do negócio (novos originadores + IA por carteira).
2. Doc `Alinhamento Torre - 2026_05_19` — reunião técnica que materializou o plano: 79 tabelas mapeadas, esquema `public` para recursos compartilhados, demais esquemas migrados para organização, script DDL único para nova org, cronograma deploy 08/jun.
3. Doc `Filtros prompts e Trigger agenda - 2026_05_20` — discussão arquitetural: regras modulares > prompts complexos, filtros de conhecimento por departamento, backup antes de mudanças, workflows N8N segregados.

Esta iniciativa **absorve** o escopo anteriormente representado por "Integração Rhino" (P29) — Rhino é o **primeiro tenant** validado pelo multi-org.

> **Escopo deste item:** schema migration (mapeamento + limpeza + normalização de functions) + ETL/migração Rhino + cutover. **Não cobre** UI "perfil por carteira", RAG por carteira, dashboards multi-org, n8n segregado nem RBAC consolidado — esses pertencem a outros BTRs (ver BTR03 dashboards, BTR06 inteligência_carteira) ou viram itens novos quando refinados.

## Critérios de aceite

- **CA-1** — Given mapeamento das 79 tabelas Supabase concluído (lixo / alteração / plug-and-play), When publicado, Then cada tabela tem destino: schema_public, schema_org, exclusão.
- **CA-2** — Given Torre com schemas isolados, When org Rhino é provisionada via DDL único, Then responde em produção sem afetar operação Finza.
- **CA-3** — Given Funções SQL revisadas (reunião 19/05), When schema muda, Then funções continuam operando sem regressão (validado em HML).
- **CA-4** — Given cutover 09/jun, When deploy ocorre, Then operação Finza continua sem downtime crítico.
- **CA-5** — Given decisão público vs privado entre orgs (pendente reunião 20/05), When alinhada com Jéssica, Then schemas refletem decisão antes do cutover.
- **CA-6** — Given mascaramento de dados sensíveis (CNPJ) para HML, When ETL roda (reunião 19/05), Then dado de prod não vai cru para dev.

## Dependências cruzadas

- **Sinergia técnica forte:** BTR07 (refatoração Torre) — **postergada** mas conceitualmente conectada.
- **Stakeholders externos:** Marcos Rodrigues (TI, mapeamento), Joao Lucas (TI, ETL), Léo (validação regras de importação), Jéssica (sponsor + decisões público/privado).
- Nota 2026-06-02: vínculos com a frente Valentina (dependia de BVA02/03/05, bloqueava BVA04) removidos — frente Valentina zerada (Valentina já preparada p/ Rhino + multi-org via dev João Pedro). Vínculo interno BTR08→BTR02 também removido por decisão do supervisor. Escopo técnico (Rhino como primeiro tenant, originador) permanece.

## Observações PO

**Pontos de atenção:**

1. **Prazo 09/jun é apertado.** 4 de 7 marcos concluídos, mas a janela final concentra pacote dev (29/05), teste dev (01-05/06) e cutover (até 09/06) — sem espaço para imprevistos.
2. **Decisão "público vs privado" PENDENTE.** Sem fechar com Jéssica (Doc 20/05), schemas podem ser refeitos. Pressionar para decisão até 28/maio.
3. **BTR07 (refatoração FastAPI) foi explicitamente POSTERGADA na reunião 19/05.** Decisão correta para não estourar prazo, mas:
   - Multi-org sobre Supabase = construir multi-tenant sobre arquitetura já pesada.
   - Quando BTR07 entrar, pode exigir REFAZER multi-org. Sinalizar risco.
   - **Sugestão PO:** considerar inverter — fazer BTR07 primeiro, multi-org já nativo. Discutir com lead técnico.
4. **Funções SQL com mudança de schema é o tipo de coisa que quebra silenciosamente** (ST-3 entregue 27/05). Cobertura de testes mínima antes do cutover é crítica — discutir com João Lucas no ciclo ST-5 (teste no ambiente dev).
5. **HML sem mascaramento expõe dado real para dev.** ST-7 (Levantamento ETLs / migração Rhino) precisa carregar governança LGPD — não foi explicitado como subtarefa, mas é gate operacional.
6. **Backup antes do cutover é não-negociável** (exigência reunião 20/05). Não aparece nos 7 marcos do time — confirmar com Marcos/João Lucas que está agendado na janela 05-09/jun antes do deploy.
7. **Validação operacional end-to-end com Jéssica** (sponsor) também não aparece nos 7 marcos — confirmar checkpoint no cutover.

## Definição de pronto

- [ ] Rhino em produção como tenant separado validado por Jéssica
- [ ] Dashboards e relatórios com dimensão "originador" publicados
- [ ] Camada RAG e Regras com filter por carteira em pelo menos 2 carteiras piloto
- [ ] UI de perfil por carteira disponível e usada pelo gestor
- [ ] Operação Finza sem regressão operacional
- [ ] Cutover documentado em runbook
- [ ] Backups verificados (não só feitos, restaurados em ambiente de teste)

## Histórico

- 2026-05-22 — Item criado a partir de P29 (pendência). Status inicial: bruto. Título original: "Integrar Rhino (novo originador) ao ecossistema operacional Torre".
- 2026-05-22 — **Repositionado** como "Implementação Multi-Org na Torre". Prioridade promovida a `urgente`. Escopo expandido para absorver BTR06 (cancelado) e contemplar tenancy real.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. Adicionadas 3 origens (reuniões 19/05 e 20/05). RICE 6.3, esforço XL confirmado. Subtarefas estruturadas em 5 fases (obsoletas após correção de 28/05). Adicionado risco crítico de prazo. Recomendação PO de inverter ordem com BTR07 (refatoração primeiro) marcada. Decisão público vs privado elevada a pendência urgente. Backup antes do cutover marcado como não-negociável.
- 2026-05-28 — **Atualização operacional + correção de escopo.** Supervisor consolidou o controle real do time: BTR02 cobre EXCLUSIVAMENTE schema migration + ETL Rhino, com 7 subtarefas concretas (5 Marcos Rodrigues + 2 João Lucas). Deadline ajustado de 2026-06-08 para 2026-06-09 (deadline total acordado). 3 marcos do Marcos concluídos (21/05, 22/05, 27/05); 1 marco do João Lucas concluído (27/05). Implementadores atribuídos no frontmatter (`Marcos Rodrigues + João Lucas`). **Removidos do item** (correção pós-feedback do supervisor): as 13 subtarefas teóricas pós-cutover do refinement de 25/05 (UI carteira, RAG por carteira, dashboards, n8n segregado, RBAC consolidado, etc.), CA-4 a CA-7 que descreviam essas entregas, bullet do Contexto que dizia "BTR02 absorve BTR06", e a Observação PO item 4 ("quebrar em 5+ itens-filhos"). Esse escopo pertence a outros BTRs (BTR03 dashboards, BTR06 inteligência_carteira) ou vira itens novos quando refinados. CA-8 (cutover) renumerado para CA-4 e data corrigida para 09/jun.
- 2026-06-02 — **Item totalmente desvinculado.** `dependencias: [BVA02, BVA03, BVA05]` → `[]`; `bloqueia: [BVA04]` → `[]`. Vínculos com a frente Valentina removidos — Valentina já está preparada para Rhino + multi-org (validado com o dev João Pedro), e a frente Valentina foi zerada. Vínculo interno BTR08→BTR02 também removido por decisão do supervisor. Mantidos os critérios CA-2/ST-7 (multi-org/ETL Rhino) e as tags `rhino`/`originador` — escopo técnico legítimo do item.

## Notas

Quebrar em itens-filhos é prioridade. Reunir com lead técnico Torre + Joao Lucas + Marcos para fechar arquitetura final + cronograma realista. Discutir inversão de ordem com BTR07.
