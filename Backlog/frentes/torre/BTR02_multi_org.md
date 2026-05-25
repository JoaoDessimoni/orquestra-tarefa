---
id: BTR02
title: Implementação Multi-Org na Torre
frente: torre
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
    - Gestao/Reunioes/18-05-2026/2026-05-18-alinhamento-jessica-revisao-roadmap.md
    - Gestao/Reunioes/19-05-2026/2026-05-19-alinhamento-torre-multi-org.md
    - Gestao/Reunioes/20-05-2026/2026-05-20-filtros-prompts-trigger-agenda.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
    - Backlog/solicitacoes/Alinhamento Torre - 2026_05_19 15_47 GMT-03_00 - Anotações do Gemini.txt
    - Backlog/solicitacoes/Filtros prompts e Trigger agenda - 2026_05_20 16_59 GMT-03_00 - Anotações do Gemini.txt
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM16
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-06-08
dependencias: [BVA02, BVA03, BVA05]
bloqueia: [BVA04]
riscos:
  - **CRÍTICO** — Deadline declarado 08/jun é agressivo. Reunião 19/05 confirmou mapeamento de 79 tabelas, ETL, normalização — escopo XL em janela de 3 semanas é alto risco.
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

Esta iniciativa **absorve** o escopo anteriormente representado por:
- BTR06 (cancelado em 22/05/2026) — IA específica por carteira coberta via `filter_definition_id` no RAG.
- "Integração Rhino" (P29) — Rhino é o **primeiro tenant** validado pelo multi-org.

## Critérios de aceite

- **CA-1** — Given mapeamento das 79 tabelas Supabase concluído (lixo / alteração / plug-and-play), When publicado, Then cada tabela tem destino: schema_public, schema_org, exclusão.
- **CA-2** — Given Torre com schemas isolados, When org Rhino é provisionada via DDL único, Then responde em produção sem afetar operação Finza.
- **CA-3** — Given Funções SQL revisadas (reunião 19/05), When schema muda, Then funções continuam operando sem regressão (validado em HML).
- **CA-4** — Given camada de conhecimento (RAG) com `filter_definition_id`, When 2 carteiras piloto cadastradas, Then documento só aparece para contatos elegíveis.
- **CA-5** — Given escopo de filtro estendido para Regras (Directives), When regra com filter ativa, Then só atua sobre contatos elegíveis.
- **CA-6** — Given UI "perfil por carteira" implementada, When gestor abre, Then vê regras+conhecimentos ativos em uma carteira.
- **CA-7** — Given dashboards e relatórios da Torre, When org é selecionada, Then dados são filtrados.
- **CA-8** — Given cutover 08/jun, When deploy ocorre, Then operação Finza continua sem downtime crítico.
- **CA-9** — Given decisão público vs privado entre orgs (pendente reunião 20/05), When alinhada com Jéssica, Then schemas refletem decisão antes do cutover.
- **CA-10** — Given mascaramento de dados sensíveis (CNPJ) para HML, When ETL roda (reunião 19/05), Then dado de prod não vai cru para dev.

## Subtarefas

> ⚠️ **Item XL** — provavelmente precisa quebrar em itens-filhos (BTR02a, BTR02b…) durante refinement com lead técnico Torre + João Lucas + Marcos.

### Fase 1 — Mapeamento e Limpeza (até 04/jun, conforme reunião 19/05)

- [ ] **ST-1 — Mapear estado das 79 tabelas** ⚠️ EM CURSO (Marcos).
  - Categorizar em: lixo (excluir), alteração (ajustar), plug-and-play (manter).
- [ ] **ST-2 — Estruturar ETL** ⚠️ EM CURSO (Joao Lucas).
  - Validar regras de importação com Léo.
  - Mascaramento de CNPJ e dados sensíveis para HML.
- [ ] **ST-3 — Limpar repositório de arquivos temporários** (Marcos).
- [ ] **ST-4 — Normalizar funções SQL** — `Cron`, `Alf`, `Secrets` precisam ser reconstruídas (mudança de schema quebra implementação atual).

### Fase 2 — Decisões Arquiteturais (urgente)

- [ ] **ST-5 — Definir público vs privado entre orgs** ⚠️ PENDENTE COM JÉSSICA (Doc 20/05).
  - Carteira/contatos: schema_public (visão unificada) OU schema_org (isolado)?
  - Configuração Esperança: schema_org (autonomia) ✅ decidido.
- [ ] **ST-6 — Script DDL único para criação de nova org** (decisão 19/05).
- [ ] **ST-7 — Decidir estratégia de regras + prompts:**
  - Reunião 20/05: regras modulares > prompts complexos.
  - "Prompt é esqueleto, regra é roupa, conhecimento é cérebro" — adotar como princípio.
- [ ] **ST-8 — Filtros de conhecimento por departamento** (Doc 20/05).
  - Implementar via `filter_definition_id` (já existente).

### Fase 3 — Implementação Backend

- [ ] **ST-9 — Implementar suporte multi-tenant no backend.**
- [ ] **ST-10 — Migrar entidades core para schema_org.**
- [ ] **ST-11 — Estender Regras com escopo de filtro** (mesma mecânica do RAG).
- [ ] **ST-12 — UI "perfil por carteira"** — visão consolidada de regras + conhecimento.

### Fase 4 — Provisionamento Piloto

- [ ] **ST-13 — Aguardar BVA02 (roteamento Rhino) + BVA03 (inventário números) + BVA05 (demandas Rhino).**
- [ ] **ST-14 — Provisionar Rhino como org piloto.**
- [ ] **ST-15 — Validar RAG com `filter_definition_id`** em 2-3 carteiras piloto.

### Fase 5 — Dashboards + Cutover

- [ ] **ST-16 — Estender dashboards + relatórios com dimensão "originador".**
- [ ] **ST-17 — Workflows N8N segregados** (Esperanza Finza, Esperanza Blips) — reunião 20/05.
- [ ] **ST-18 — BACKUP COMPLETO antes do cutover** (exigência reunião 20/05).
- [ ] **ST-19 — Cutover 08/jun** com janela definida e rollback testado.
- [ ] **ST-20 — Validação operacional end-to-end com Jéssica.**

## Dependências cruzadas

- **Depende de:** BVA02 (roteamento Rhino), BVA03 (inventário números), BVA05 (mapeamento demandas Rhino).
- **Sinergia técnica forte:** BTR07 (refatoração Torre) — **postergada** mas conceitualmente conectada.
- **Bloqueia:** BVA04 (originador automático precisa do multi-org).
- **Stakeholders externos:** Marcos Rodrigues (TI, mapeamento), Joao Lucas (TI, ETL), Léo (validação regras de importação), Jéssica (sponsor + decisões público/privado).

## Observações PO

**Pontos de atenção:**

1. **Prazo 08/jun é altamente otimista para escopo XL.** RICE 6.3 reflete confidence média (7) — dependências de Marcos/Joao Lucas estão fora do controle do squad IAF. Recomendação: tratar 08/jun como deadline de FASE 1+2, não de tudo.
2. **Decisão "público vs privado" PENDENTE.** Sem fechar com Jéssica (Doc 20/05), schemas podem ser refeitos. Pressionar para decisão até 28/maio.
3. **BTR07 (refatoração FastAPI) foi explicitamente POSTERGADA na reunião 19/05.** Decisão correta para não estourar prazo, mas:
   - Multi-org sobre Supabase = construir multi-tenant sobre arquitetura já pesada.
   - Quando BTR07 entrar, pode exigir REFAZER multi-org. Sinalizar risco.
   - **Sugestão PO:** considerar inverter — fazer BTR07 primeiro, multi-org já nativo. Discutir com lead técnico.
4. **Item NÃO É 1 ITEM — É 5+.** Refinement deve quebrar em BTR02a (backend multi-tenant), BTR02b (dashboards), BTR02c (RAG/Regras filter), BTR02d (UI perfil), BTR02e (cutover). Cada um com responsável e deadline.
5. **Funções SQL com mudança de schema é o tipo de coisa que quebra silenciosamente.** Cobertura de testes mínima antes do cutover é crítica — discutir com Joao Lucas.
6. **HML sem mascaramento expõe dado real para dev.** ST-2 + ST-10 precisam de governança LGPD.
7. **Backup antes de mudança (Doc 20/05) é não-negociável.** Verificar que ST-18 está agendado.

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
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. Adicionadas 3 origens (reuniões 19/05 e 20/05). RICE 6.3, esforço XL confirmado. Subtarefas estruturadas em 5 fases. Adicionado risco crítico de prazo. Recomendação PO de inverter ordem com BTR07 (refatoração primeiro) marcada. ST-5 (público vs privado) elevado a pendência urgente. ST-18 (backup) marcado como não-negociável.

## Notas

Quebrar em itens-filhos é prioridade. Reunir com lead técnico Torre + Joao Lucas + Marcos para fechar arquitetura final + cronograma realista. Discutir inversão de ordem com BTR07.
