---
id: BST03
title: Discovery — definir narrativa "o que a IA faz para o negócio Finza"
frente: estrategica
fonte: backlog
status: a-refinar
prioridade: alta
rice:
  reach: 8
  impact: 7
  confidence: 6
  effort: 3
  score: 11.2
esforco: S
valor_negocio: alto
origem:
  pendencias: [P36]
  reunioes:
    - Backlog/reunioes/15-05-2026/2026-05-15-jornada-cliente-diretoria.md
  solicitacoes: []
  analises:
    - Backlog/analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM24
owner: João Vinícius
implementador: null
sponsor: Diretoria
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-06-30
dependencias: [BES03, BES06]
bloqueia: []
riscos:
  - Narrativa sem dado é retórica — risco de virar slogan vazio.
  - Dados ainda não coletados (BES03, BES06) — narrativa pode esperar dependência.
  - Mensagens divergentes para audiências diferentes podem virar inconsistência percebida (CTO ouve uma coisa, operação ouve outra).
premissas:
  - Dados quantitativos suficientes existem (BES03, BES06) para lastrear pelo menos parte da narrativa.
  - Diretoria valida em sessão curta.
tags: [discovery, narrativa, ia, estrategico, diretoria]
---

# BST03 — Discovery — definir narrativa "o que a IA faz para o negócio Finza"

## História de usuário

Como **diretoria Finza**,
quero **narrativa institucional consolidada sobre o impacto da IA no negócio**,
para **comunicar internamente e externamente sem improviso, com lastro de dados**.

## Contexto

Anotação do caderno do supervisor reforçada pela reunião com diretoria de 15/05/2026: não existe narrativa institucional consolidada sobre o impacto da IA no negócio Finza. Sem ela, qualquer apresentação executiva sai manca (já aconteceu). Posicionamento interno também sofre — squad IAF é confundido com "automação genérica".

Pré-requisito implícito para qualquer comunicação executiva futura.

## Critérios de aceite

- **CA-1** — Given dado quantitativo de BES03 (volume transferências) e BES06 (relatório pré-Torre) disponível, When narrativa é rascunhada, Then é lastreada em número defensável.
- **CA-2** — Given documento síntese curto (1-2 páginas), When publicado, Then cobre: (a) por que existe IA, (b) o que faz hoje, (c) valor entregue (números), (d) para onde vai.
- **CA-3** — Given 3 versões produzidas (diretoria, CTO/Tech, operação), When comparadas, Then não há divergência factual entre versões — apenas de foco.
- **CA-4** — Given validação com diretoria, When acordada, Then é adotada como narrativa oficial.
- **CA-5** — Given narrativa adotada, When citada em deck/apresentação posterior, Then bate com versão oficial (não improvisa).

## Dependências cruzadas

- **Depende de:** BES03 (volume transferências), BES06 (relatório pré-Torre — ou baseline alternativa).
- **Beneficia-se de:** BES04 (tabulações — riqueza qualitativa).

## Observações PO

**Pontos de atenção:**

1. **RICE 11.2 = alta alavanca.** Item de comunicação tem efeito multiplicador — uma narrativa boa fortalece deck, posicionamento, contratação.
2. **Risco de virar slogan vazio.** Sem dado, narrativa é literatura. Por isso depende de BES03/BES06.
3. **3 versões precisam ser consistentes.** Mesma fato, foco diferente. Não pode haver contradição.
4. **"Squad IAF é confundido com automação genérica" é diagnóstico real.** Narrativa boa muda isso.
5. **Esforço S** — não é projeto longo. É exercício de síntese + validação.
6. **Pode rodar em paralelo com discovery (BES05)** — o que aprender no discovery alimenta narrativa.

## Definição de pronto

- [ ] 3 versões publicadas
- [ ] Validação diretoria concluída
- [ ] Narrativa adotada como oficial em `Docs/finza/`
- [ ] Squad comunicado e usando

## Histórico

- 2026-05-22 — Item criado a partir de P36 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM24) consolidando anotações de caderno e reunião com diretoria de 15/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 11.2 (alta alavanca por efeito multiplicador). Esforço: S. Dependências de BES03 e BES06 marcadas. CAs em G/W/T. Subtarefa ST-7 (comunicar squad) adicionada — sem isso, narrativa fica órfã.

## Notas

Rascunhar 3 versões da narrativa em formato curto. Levar para próxima 1on1 com superior direto antes de virar deck. Sem dado quantitativo, vira literatura.
