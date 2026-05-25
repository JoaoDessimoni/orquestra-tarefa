---
id: BVA02
title: Ajustar Valentina para roteamento Rhino → suporte Rhino (urgente)
frente: valentina
status: em-refinamento
prioridade: alta
rice:
  reach: 5
  impact: 7
  confidence: 7
  effort: 2
  score: 12.25
esforco: S
valor_negocio: alto
origem:
  pendencias: [P15]
  reunioes:
    - Gestao/Reunioes/15-05-2026/2026-05-15-reuniao-diretoria-jornada-cliente.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM09
owner: João Vinícius
implementador: null
sponsor: Diretoria
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-06-01
dependencias: [BVA03]
bloqueia: [BTR02]
riscos:
  - "Suporte Rhino" pode não existir operacionalmente pronto para receber — transferência redireciona para vazio.
  - Identificação técnica de originador na entrada da Valentina pode não estar disponível na arquitetura atual (Doc 22/04: Mateus disse que "no Módulo Financeiro hoje a gente não consegue saber qual foi a empresa que originou o contrato Finza").
  - Sem inventário canônico de números (BVA03), implementação é especulativa.
premissas:
  - Suporte Rhino operacionalmente existe e tem capacidade.
  - É possível identificar Rhino na entrada (canal, número, prefixo, payload).
  - Diretoria mantém prioridade "o quanto antes" declarada.
tags: [valentina, rhino, urgente, roteamento, diretoria]
---

# BVA02 — Ajustar Valentina para roteamento Rhino → suporte Rhino (urgente)

## História de usuário

Como **cliente Rhino contatando Finza**,
quero **ser direcionado para o suporte Rhino específico, não para o suporte genérico Finza**,
para **receber atendimento com contexto adequado ao meu originador**.

## Contexto

Diretoria sinalizou em 15/05/2026 como "o quanto antes" — não é projeto futuro, é correção urgente. Demandas vindas do originador Rhino estão sendo roteadas para o suporte genérico Finza (Valentina) em vez do suporte específico Rhino.

⚠️ **Doc 22/04 (Mateus → Jéssica) revela problema técnico:** "hoje no Módulo Financeiro, do jeito que funciona, a gente não consegue saber qual foi a empresa que originou o contrato Finza, que entra como finza, mas é tudo finza". Ou seja: identificação automática pode não ser viável com a arquitetura atual. Pode ser que solução seja Valentina **perguntar** ao cliente "comprou com qual empresa?" antes de tentar identificar — workaround documentado pelo Mateus.

## Critérios de aceite

- **CA-1** — Given originador Rhino identificável tecnicamente OU via pergunta direta ao cliente, When Valentina detecta, Then registra evento "originador identificado=Rhino" na sessão.
- **CA-2** — Given originador=Rhino, When Valentina tenta atender, Then ou (a) transfere para fluxo de suporte Rhino dedicado OU (b) usa contexto Rhino-específico para responder.
- **CA-3** — Given fluxo de suporte Rhino confirmado operacional, When transferência acontece, Then 100% dos casos chegam a humano/sistema Rhino (não pulam de volta para Finza genérico).
- **CA-4** — Given 30 dias de operação, When métricas são revisadas, Then volume de cliente Rhino atendido por Valentina genérica cai para <5%.

## Subtarefas

- [ ] **ST-1 — Aguardar BVA03 (inventário números)** — sem saber qual número Rhino usa, não dá pra rotear.
- [ ] **ST-2 — Validar com operação Finza** que "suporte Rhino" existe e está pronto para receber.
  - Quem absorve? Qual canal? Qual SLA?
- [ ] **ST-3 — Mapear identificação técnica** — canal, número de entrada, prefixo de mensagem, payload da sessão Hyper.
  - Se identificação técnica não é viável → workaround: Valentina pergunta "comprou equipamento com qual empresa?".
- [ ] **ST-4 — Implementar regra de roteamento** — se originador=Rhino, transferir para suporte Rhino.
- [ ] **ST-5 — Teste com mensagens reais Rhino** (não simuladas).
- [ ] **ST-6 — Comunicação Rhino** — alinhar com a empresa Rhino que vamos rotear automaticamente.
- [ ] **ST-7 — Métricas** — volume Rhino antes/depois, taxa de transferência correta.

## Dependências cruzadas

- **Depende de:** BVA03 (inventário números IA), BVA05 (mapeamento demandas Rhino).
- **Bloqueia:** BTR02 (multi-org) — Rhino entra na Torre como primeiro tenant.

## Observações PO

**Pontos de atenção:**

1. **Identificação técnica pode não ser viável** com arquitetura atual (Mateus disse explicitamente em 22/04). Workaround "pergunta direta" deve estar no plano desde o início — não como fallback de emergência.
2. **"Suporte Rhino existe operacionalmente" é premissa não validada.** ST-2 não-negociável. Se Rhino não tem capacidade, transferência redireciona para vazio.
3. **Esforço S é estimativa otimista.** Se descobrir que precisa mexer no Hyper, no canal, no Módulo Financeiro, vira M ou L. Validar escopo cedo.
4. **Item é PRECONDIÇÃO para BTR02 (multi-org).** Rhino entra na Torre como tenant via multi-org — mas antes precisa estar minimamente roteado.
5. **Urgência declarada por Diretoria.** Deadline curto (1 semana? 2 semanas?) merece respeito mas precisa de validação realista — não prometer o impossível.

## Definição de pronto

- [ ] Roteamento Rhino em produção
- [ ] Validação operacional com suporte Rhino confirmada
- [ ] Métricas iniciais de volume coletadas
- [ ] Volume Rhino na Valentina genérica <5% em 30 dias

## Histórico

- 2026-05-22 — Item criado a partir de P15 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM09) consolidando reunião com diretoria de 15/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 12.25 (alta — esforço baixo + alavanca clara). Esforço: S. Adicionada dependência de BVA03 (inventário números). Risco crítico documentado: identificação técnica de originador pode não ser viável (Mateus 22/04) — workaround "pergunta direta" incluído desde o início.

## Notas

Alinhar com operação Finza onde fica o "suporte Rhino" e qual é o fluxo de transferência atual. Workaround "Valentina pergunta originador" pode ser caminho mais rápido que mexer em Módulo Financeiro.
