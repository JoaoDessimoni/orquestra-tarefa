---
id: BTR07
title: Refatoração da Torre — backend FastAPI/Postgres + arquitetura enterprise
frente: torre
status: em-refinamento
prioridade: alta
rice:
  reach: 9
  impact: 9
  confidence: 5
  effort: 10
  score: 4.05
esforco: XL
valor_negocio: alto
origem:
  pendencias: []
  reunioes:
    - Gestao/Reunioes/19-05-2026/2026-05-19-alinhamento-torre-multi-org.md
  solicitacoes:
    - Backlog/solicitacoes/Alinhamento Torre - 2026_05_19 15_47 GMT-03_00 - Anotações do Gemini.txt
  analises: []
roadmap_vinculado: null
owner: João Vinícius
implementador: null
sponsor: João Vinícius
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-Q4
dependencias: []
bloqueia: []
riscos:
  - Refatoração POSTERGADA explicitamente em 19/05 para priorizar multi-org (BTR02) — ordem pode estar errada.
  - Reescrita de subsistema em produção é XL clássico — high risk, high reward, prazo realista 6+ meses.
  - Sem ambiente HML maduro (P01 Torre), cutover é arriscado.
  - Equipe atual pode não ter banda para BTR02 + BTR07 simultâneos.
  - Migração de Edge Functions para FastAPI exige rebuild de toda lógica de negócio — não é "lift and shift".
premissas:
  - Time IAF + Plataformas tem capacidade de banca para projeto XL.
  - Stakeholders aceitam janela de cutover com risco controlado.
  - Versão Supabase atual continua operando durante reescrita (não há paralisação total).
  - Decisão de POSTERGAR (reunião 19/05) é reversível — pode ser revista se BTR02 mostrar que multi-org sobre Supabase é doloroso.
tags: [torre, refatoracao, backend, fastapi, postgres, enterprise, performance, fila, xl, postergado]
---

# BTR07 — Refatoração da Torre — backend FastAPI/Postgres + arquitetura enterprise

## História de usuário

Como **time IAF + Plataformas**,
quero **reescrever a Torre com stack enterprise (FastAPI + PostgreSQL, fila com reprocessamento, paralelismo nos disparos, observabilidade robusta)**,
para **eliminar débito técnico do Supabase, melhorar performance/confiabilidade dos disparos e refletir o Módulo Financeiro com fidelidade**.

## Contexto

A Torre cresceu sobre Supabase + Edge Functions e acumulou débito arquitetural — consultas mal-otimizadas, disparos sequenciais, tratamento de erros pontual, sem fila de reprocessamento padrão, divergências entre Torre e Módulo Financeiro. Esta iniciativa é a **reescrita controlada para stack enterprise**, mantendo paridade funcional inicial e abrindo caminho para escala (multi-org, novos canais, novos originadores).

⚠️ **STATUS RECENTE:** Refatoração foi **POSTERGADA** explicitamente na reunião 19/05 (Doc `Alinhamento Torre 2026-05-19`) para priorizar BTR02 (multi-org). Citação direta da reunião:
> "Discussões sobre a refatoração completa da 'Torre' foram postergadas, pois a prioridade atual da equipe é a implementação do modelo multiorganização para evitar atrasos e sobrecarga de trabalho."

Item **XL** — provavelmente precisa quebrar em itens-filhos durante refinement com João Lucas (Tech Lead) e lead técnico da Torre.

## Critérios de aceite

- **CA-1** — Given backend reescrito em FastAPI + PostgreSQL, When publicado, Then mantém paridade funcional da versão Supabase atual.
- **CA-2** — Given frontend reajustado, When publicado, Then componentes consolidados, fluxos auditados, débito UX eliminado.
- **CA-3** — Given consultas reavaliadas, When profiling roda, Then sem N+1 conhecido, índices revisados, plano de execução checado em queries críticas.
- **CA-4** — Given disparos com paralelismo, When jobs rodam, Then são paralelos configuráveis por job/canal sem perda de ordem onde necessário.
- **CA-5** — Given fila enterprise, When mensagem falha, Then reprocessamento automático com backoff exponencial + DLQ + observabilidade.
- **CA-6** — Given tratamento de erros padronizado, When erro acontece, Then estrutura única, observabilidade (traces/logs/metrics), retry inteligente.
- **CA-7** — Given Torre reflete Módulo Financeiro, When dados são consultados, Then sem divergência operacional registrada.
- **CA-8** — Given cutover em produção, When acontece, Then sem perda de dados, janela de rollback validada, runbook publicado.

## Subtarefas

> ⚠️ **Item XL** — DEVE ser quebrado em itens-filhos no próximo refinement com João Lucas.

- [ ] **ST-1 — Reescrever backend Supabase → FastAPI + PostgreSQL.**
  - Portar tabelas, migrar Edge Functions para endpoints FastAPI, manter compatibilidade de API externa.
- [ ] **ST-2 — Reajustar arquitetura de frontend e usabilidade.**
- [ ] **ST-3 — Revisar arquitetura de disparos e otimizações.**
- [ ] **ST-4 — Reavaliar todas as consultas da Torre** (performance + correção).
- [ ] **ST-5 — Implementar paralelismo nos disparos.**
- [ ] **ST-6 — Processamento de fila com reprocessamento (padrão enterprise).**
- [ ] **ST-7 — Melhorar tratamento de erros** (estrutura, observabilidade, retry).
- [ ] **ST-8 — Refletir Módulo Financeiro** — sincronização ou consulta consistente.

### Pré-requisitos antes de retomar (pós-postergação):

- [ ] **PR-1 — Avaliar com BTR02:** multi-org sobre Supabase está doloroso o suficiente para inverter ordem?
- [ ] **PR-2 — Validar capacidade** — squad tem banca para XL no Q4?
- [ ] **PR-3 — Definir ambiente HML maduro** (P01 Torre) — sem isso, cutover é alto risco.

## Dependências cruzadas

- **Sinergia técnica forte com BTR02 (Multi-Org):** desenhar arquitetura multi-tenant junto com a reescrita evita retrabalho.
- **Insumo para BES03/BES04/BES06:** dashboards e relatórios desses itens vão usar nova base de dados/queries.

## Observações PO

**Pontos de atenção:**

1. **POSTERGADO mas não cancelado.** Decisão foi correta naquele momento (19/05) mas item segue ativo. Revisitar prioridade após BTR02 fase 1.
2. **RICE 4.05** reflete efforat 10 (XL) e confidence 5 (alta variabilidade). Score baixo NÃO significa que item não vale — significa que esforço:retorno requer cuidado.
3. **Inversão de ordem (BTR07 → BTR02) ainda é discutível.** Multi-org sobre Supabase pode duplicar trabalho quando refatoração entrar. Sugestão PO: revisitar com lead técnico em julho/agosto.
4. **Item NÃO É 1 ITEM — É 5+.** ST-1 a ST-8 são candidatos a itens-filhos:
   - BTR07a — Backend FastAPI/PostgreSQL
   - BTR07b — Frontend reajuste
   - BTR07c — Fila enterprise + observabilidade
   - BTR07d — Paralelismo disparos
   - BTR07e — Reflexão Módulo Financeiro
5. **Sem ambiente HML maduro (P01), cutover XL é roleta russa.** PR-3 não é opcional.
6. **"Refletir MF com fidelidade" pode ser item separado** — é diferença operacional crítica e provavelmente justifica próprio item agora, mesmo com BTR07 postergado.

## Definição de pronto

- [ ] Torre rodando em FastAPI/PostgreSQL em produção.
- [ ] Métricas de performance e confiabilidade melhoraram em relação à baseline atual (KPIs em refinement).
- [ ] Sem regressão funcional reportada por Jéssica/operação.
- [ ] Documentação de arquitetura e runbook operacional publicados.
- [ ] Cutover validado com rollback testado.

## Histórico

- 2026-05-22 — Item criado a partir de briefing direto do supervisor. Sem pendência tática origem. Status inicial: a-refinar. Esforço camiseta estimado em XL.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 4.05 (efeito do effort XL). Origem da reunião 19/05 adicionada documentando postergação. Pré-requisitos PR-1 a PR-3 marcados. Recomendação de quebra em 5 itens-filhos. Observação sobre "Refletir MF" como candidato a item separado imediato.

## Notas

Postergado mas não cancelado. Revisitar com lead técnico Torre + João Lucas em julho/agosto após BTR02 fase 1. Considerar extrair "Refletir MF" como item próprio imediato.
