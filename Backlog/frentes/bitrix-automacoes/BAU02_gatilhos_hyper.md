---
id: BAU02
title: Revisar gatilhos Hyper existentes e mapear novas oportunidades
frente: bitrix-automacoes
status: a-refinar
prioridade: media
rice:
  reach: 6
  impact: 5
  confidence: 7
  effort: 3
  score: 7.0
esforco: S
valor_negocio: medio
origem:
  pendencias: [P35]
  reunioes:
    - Gestao/Reunioes/18-05-2026/2026-05-18-alinhamento-jessica-revisao-roadmap.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM22
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-Q3
dependencias: []
bloqueia: []
riscos:
  - Time HyperFlow pode não ter inventário formalizado — extração vira retrabalho.
  - Gatilhos "obsoletos" podem ainda ter consumidores não-óbvios (mesma cauda longa do BBT02).
  - Sem ownership do HyperFlow no squad IAF, decisões de remover/criar dependem de time externo.
premissas:
  - Time HyperFlow tem inventário disponível ou pode produzir em sessão curta.
  - Operadores são acessíveis para feedback sobre quais gatilhos usam.
tags: [hyper, gatilhos, automacao, jessica, revisao]
---

# BAU02 — Revisar gatilhos Hyper existentes e mapear novas oportunidades

## História de usuário

Como **gestor de cobrança**,
quero **inventário revisado de gatilhos HyperFlow + lista de novos gatilhos priorizados**,
para **eliminar redundâncias, desativar obsoletos e capturar oportunidades de automação não exploradas**.

## Contexto

Os gatilhos do Hyper (HyperFlow) automatizam consultas recorrentes em sistemas e otimizam atendimento operacional. O inventário atual nunca foi revisado sistematicamente.

**Origem da demanda:** Doc `2026-05-18_jessica_roadmap-ia-automacoes.txt`:
> "Gatilhos Hyper — Revisão dos gatilhos existentes e identificação de novas oportunidades, visando facilitar consultas recorrentes em sistemas e otimizar o atendimento operacional."

Há suspeita de gatilhos obsoletos, sobrepostos ou mal configurados — e oportunidades não exploradas.

## Critérios de aceite

- **CA-1** — Given inventário atual de gatilhos Hyper publicado, When listado, Then cada gatilho tem: propósito, frequência de uso, último incidente, opinião dos operadores.
- **CA-2** — Given gatilhos obsoletos identificados, When propostos para desativação, Then validados com operadores antes de remover.
- **CA-3** — Given gatilhos sobrepostos identificados, When propostos para consolidação, Then plano de fusão documentado.
- **CA-4** — Given lacunas identificadas, When mapeadas, Then top 5 novos gatilhos com estimativa de ganho.
- **CA-5** — Given inventário versionado, When mudança acontece, Then é atualizado antes de produção.

## Subtarefas

- [ ] **ST-1 — Identificar quem tem o inventário** — time HyperFlow tem owner? Mateus? Marco?
- [ ] **ST-2 — Extrair inventário atual** de gatilhos.
- [ ] **ST-3 — Para cada gatilho coletar:**
  - Propósito declarado.
  - Frequência de uso real (do log do HyperFlow).
  - Último incidente.
  - Opinião dos operadores (3-5 entrevistas curtas).
- [ ] **ST-4 — Identificar obsoletos** — não dispara há 90+ dias.
- [ ] **ST-5 — Identificar sobrepostos** — múltiplos gatilhos fazem coisa similar.
- [ ] **ST-6 — Mapear lacunas** — onde operadores fazem ação manual repetitiva.
- [ ] **ST-7 — Top 5 novos gatilhos prioritários** com estimativa de ganho (tempo/mês economizado).
- [ ] **ST-8 — Desativar obsoletos** (após validar com operadores).
- [ ] **ST-9 — Implementar top 5 novos** (sob priorização do squad).
- [ ] **ST-10 — Estabelecer revisão recorrente** (trimestral?).

## Dependências cruzadas

- Sem dependência direta de outro item de backlog.
- Sinergia com BAU01 (MCPs) — gatilhos podem virar MCPs se evoluírem.

## Observações PO

**Pontos de atenção:**

1. **RICE 7.0 = banda alta, mas RICE conservador.** Esforço S, alavanca em volume operacional. Vale a pena.
2. **Risco principal: gatilho "obsoleto" tem consumidor obscuro.** Mesma armadilha de BBT02. ST-2 (operadores opinam antes) reduz risco.
3. **"Estimativa de ganho" para novos gatilhos é difícil sem dado.** Time tracking de operadores não existe — usar estimativa conservadora.
4. **Item pode virar trabalho contínuo, não one-shot.** ST-10 (revisão recorrente) sinaliza que após primeira passada, vira processo.
5. **HyperFlow é caixa-preta para a IAF.** Sem ownership claro, decisões sobre criar/remover dependem de time externo. Sinalizar quem é o owner antes de começar.

## Definição de pronto

- [ ] Inventário publicado
- [ ] Obsoletos desativados (com aprovação dos operadores)
- [ ] Sobrepostos consolidados
- [ ] Top 5 novos gatilhos priorizados com estimativa de ganho
- [ ] Revisão recorrente estabelecida (cadência definida)

## Histórico

- 2026-05-22 — Item criado a partir de P35 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM22) consolidando reunião revisão geral com Jéssica de 18/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 7.0. Esforço: S. CAs em G/W/T. ST-10 (revisão recorrente) adicionada para sinalizar que item vira processo após primeira passada.

## Notas

Extrair inventário atual de gatilhos com time HyperFlow. Sem inventário, revisão é cega. Validar ownership do HyperFlow antes de propor desativação.
