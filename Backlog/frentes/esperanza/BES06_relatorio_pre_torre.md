---
id: BES06
title: Resgatar relatório pré-Torre sobre redirecionamento IA→humano
frente: esperanza
fonte: backlog
status: entregue
prioridade: alta
rice:
  reach: 5
  impact: 6
  confidence: 5
  effort: 2
  score: 7.5
esforco: XS
valor_negocio: medio
origem:
  pendencias: [P21]
  reunioes: []
  solicitacoes: []
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM05
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-06-30
dependencias: []
bloqueia: []
riscos:
  - Relatório pode não existir mais (perdido, autor não lembra) — esforço vira arqueologia sem resultado.
  - Metodologia de medição original pode ser incompatível com dado atual — comparativo "antes vs depois" pode ser inválido.
premissas:
  - O relatório existe em algum lugar (e-mail, Drive, planilha) — não foi totalmente perdido.
  - Alguém da equipe original (pré-Torre) ainda está acessível.
tags: [esperanza, relatorio, torre, historico]
---

# BES06 — Resgatar relatório pré-Torre sobre redirecionamento IA→humano

## História de usuário

Como **supervisor IAF**,
quero **localizar e reproduzir relatório pré-Torre de redirecionamento IA→humano**,
para **ter âncora histórica que permita comparar "antes vs depois" da Torre com base quantitativa, e fortalecer narrativa de impacto da IA**.

## Contexto

Anotação do caderno do supervisor: antes da Torre de Controle existir, havia um relatório com volume de casos de redirecionamento IA→humano. Esse número é estratégico — sem ele, qualquer comparação "antes vs depois" da Torre fica sem âncora. Precisa ser resgatado antes que se perca completamente.

Complementa BES03 (dashboard de transferências) e alimenta BST03 (narrativa IA).

## Critérios de aceite

- **CA-1** — Given lista de pessoas que operavam pré-Torre, When supervisor entrevista cada uma, Then identifica quem produzia o relatório.
- **CA-2** — Given pessoa identificada, When solicita arquivo, Then arquivo original (e-mail/Drive/planilha) é recuperado E metodologia descrita.
- **CA-3** — Given metodologia conhecida, When aplicada a dado atual, Then produz número de comparação válido — OU sinaliza incompatibilidade explicitamente.
- **CA-4** — Given resgate concluído, When documentado, Then vira insumo de BES05 (discovery) e BST03 (narrativa IA).

## Dependências cruzadas

- **Insumo de:** BES05 (discovery — referência histórica), BST03 (narrativa — número para lastrear).

## Observações PO

**Pontos de atenção:**

1. **Risco de virar arqueologia infinita.** ST-7 (timebox de 1 semana) é não-negociável. Se em 7 dias ninguém lembra, abortar e produzir baseline do zero com dado da Torre — não atrasar BES03 esperando isso.
2. **Mesmo se relatório aparecer, metodologia pode ser inválida hoje.** Tabelas/queries da Torre mudaram. Não comparar maçã com laranja.
3. **Valor real é narrativa, não dado preciso.** O número "antes da Torre éramos X" é poderoso para BST03 (deck para diretoria) mesmo com margem. Não precisa de precisão clínica — precisa ser defensável.
4. **Esforço XS** — não vale grande dispendio. Item certo, prioridade média.

## Definição de pronto

- [ ] Relatório original localizado OU aborto documentado em 1 semana
- [ ] Metodologia documentada
- [ ] Número de referência publicado (se viável)
- [ ] Documento publicado em `Gestao/Analises/`

## Histórico

- 2026-05-22 — Item criado a partir de P21 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM05) consolidando anotações de caderno.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 7.5. Esforço: XS (escopo enxuto). Timebox de 1 semana adicionado (ST-7) — risco de arqueologia infinita. Observação PO sobre valor real ser narrativa (defensável) não precisão clínica.

## Notas

Timebox 1 semana. Se ninguém lembra do relatório, abortar e usar baseline da Torre atual como ponto-zero da narrativa.
