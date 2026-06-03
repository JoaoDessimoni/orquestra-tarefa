---
id: BAU01
title: Criar MCPs das plataformas Finza para expandir Valentina e Esperanza
frente: bitrix-automacoes
fonte: backlog
status: a-refinar
prioridade: media
rice:
  reach: 8
  impact: 8
  confidence: 5
  effort: 6
  score: 5.33
esforco: L
valor_negocio: alto
origem:
  pendencias: [P14]
  reunioes:
    - Gestao/Reunioes/15-05-2026/2026-05-15-jornada-cliente-diretoria.md
  solicitacoes: []
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM11
owner: João Vinícius
implementador: null
sponsor: Diretoria
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-Q3
dependencias: []
bloqueia: []
riscos:
  - Cada plataforma (MF, Veritas, Falcon, Bitrix, HyperFlow) tem governança diferente — MCP único é simplificação, na prática são 5+ projetos.
  - Time de Plataformas pode não ter capacidade para suportar — dependência cross-team.
  - Sem autenticação/autorização robusta, MCP vira backdoor.
  - LGPD: agente IA acessando dado real do cliente exige governança forte.
premissas:
  - Time de Plataformas tem capacidade no Q3 para alocar a iniciativa.
  - Há APIs ou bancos consultáveis em cada plataforma.
  - Modelos atuais (Claude Sonnet 4) consomem MCPs sem retrabalho de prompt.
tags: [mcp, valentina, esperanza, plataformas, diretoria]
---

# BAU01 — Criar MCPs das plataformas Finza para expandir Valentina e Esperanza

## História de usuário

Como **agente IA Finza (Valentina, Esperanza)**,
quero **acessar estado operacional real das plataformas via MCPs**,
para **dar respostas baseadas em situação atual do cliente, não em contexto estático**.

## Contexto

Valentina e Esperanza hoje operam com contexto estático (prompt + base de conhecimento). Não têm acesso a estado operacional real do cliente (status do contrato, posição financeira, etapa da formalização do cliente em conversa). Diretoria nomeou MCPs explicitamente em 15/05/2026 como caminho de expansão — confirmando que o vocabulário técnico já circula no nível executivo.

## Critérios de aceite

- **CA-1** — Given inventário de plataformas Finza com APIs/dados relevantes publicado, When supervisor lista, Then cada plataforma tem: owner, API disponível, dados expostos, governança LGPD.
- **CA-2** — Given priorização com time de Plataformas, When acordada, Then 1-3 plataformas viram MCPs prioritários.
- **CA-3** — Given pelo menos 1 servidor MCP implementado, When consumido por Valentina/Esperanza, Then respostas referenciam dado real (não estático).
- **CA-4** — Given autenticação/autorização validada com Segurança, When MCP é acessado, Then chamada é audita+rastreada.
- **CA-5** — Given 30 dias de operação, When métricas são revisadas, Then acurácia de resposta sobre estado do cliente >95%.

## Dependências cruzadas

- **Sinergia:** BTR02 (multi-org — MCPs podem variar por org), BTR07 (refatoração — afeta APIs da Torre).

## Observações PO

**Pontos de atenção:**

1. **"Criar MCPs" no plural = projeto longo.** RICE 5.33 reflete que cada MCP é projeto. Não tratar como item único — é programa de 6-12 meses.
2. **Sugestão PO: começar pelo MF.** É a plataforma com maior alavanca para Esperanza (status título) e Valentina (dúvida sobre boleto/contrato).
3. **Governança LGPD não é decoração.** Agente IA acessando dado real do cliente exige trilha forte. ST-3 é gate.
4. **MCP genérico vs MCP por plataforma** é decisão arquitetural. Genérico é mais barato; específico é mais auditável. Sugestão: começar específico (MF), generalizar depois se padrão emergir.
5. **Cross-team risk:** depende de Plataformas (Marco, Girlan). Sem mandato claro da diretoria, vira espera passiva.
6. **Diretoria como sponsor:** acionar para pressionar capacidade do time de Plataformas se necessário.

## Definição de pronto

- [ ] Inventário publicado
- [ ] Governança LGPD documentada
- [ ] Pelo menos 1 MCP em produção
- [ ] Valentina/Esperanza consumindo MCP em conversas reais
- [ ] Acurácia >95% validada em amostra
- [ ] Padrão documentado para próximos MCPs

## Histórico

- 2026-05-22 — Item criado a partir de P14 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM11) consolidando reunião com diretoria de 15/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 5.33. Esforço: L (corrigido — "criar MCPs" é programa, não item). Recomendação PO: começar pelo MF. Adicionada governança LGPD como gate. Lista de 7 plataformas candidatas.
- 2026-06-02 — **Edição leve.** Menção a BVA01 removida da linha de sinergia (frente Valentina zerada). Valentina segue como consumidora dos MCPs (agente ativo), apenas o vínculo ao item BVA01 deixa de existir.

## Notas

Reunir com lead de Plataformas (Marco para MF) para inventariar APIs candidatas e priorizar o primeiro MCP a construir. Acionar Diretoria se precisar de mandato.
