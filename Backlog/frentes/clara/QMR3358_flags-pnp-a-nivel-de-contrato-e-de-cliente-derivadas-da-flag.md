---
id: QMR3358
title: Flags PNP a nível de contrato e de cliente (derivadas da flag por parcela)
frente: clara
status: entregue
prioridade: alta
fonte: quimera+jira
quimera: 3358
jira: IAF-109
categoria: Formalização
deliverable_type: Outros
story_points: 8
tipo_origem: Tarefa
responsavel: Marcos Rodrigues
criada: 2026-04-15
concluida: 2026-06-11
prazo: null
prazo_estimado: False
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: []
bloqueia: []
tags: [fonte-quimera-jira, cat-formalizacao]
---

# QMR3358 — Flags PNP a nível de contrato e de cliente (derivadas da flag por parcela)

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3358 · Jira IAF-109 · categoria: Formalização

  Contexto

  A flag PNP ("Primeira Não Paga") vem do ETL e é armazenada a nível de parcela, em  
  titles.custom_fields->>'parcela_pnl' (nome mantido com "l" por compatibilidade, não mexer). O  
  sistema é title-centric, então a flag por parcela cumpre o papel em avaliações de título — mas  
   quando se precisa segmentar por contrato ou por cliente, ela não basta.

  Problema

  Filtros que agregam por contrato ou por cliente perdem disjunção: um cliente com parcelas PNP  
  e parcelas não-PNP aparece nos dois lados de um filtro que deveria separá-lo em apenas um.

  Exemplo: cliente com 10 títulos em aberto, 3 PNP e 7 não-PNP →

* Filtro "clientes PNP" inclui o cliente
* Filtro "clientes não-PNP" também inclui o mesmo cliente

  Isso inviabiliza segmentação por PNP em qualquer régua, portfolio, dashboard ou relatório que  
  opere a nível de contrato ou cliente.

  Resultado esperado

  Criar duas flags novas, derivadas (não vêm do ETL, são calculadas internamente):

* PNP no contrato — binária, vigente
* PNP no cliente — binária, vigente

  A flag por parcela continua vindo do ETL como hoje, sem alteração.

  Regras de negócio

* Um título é PNP ⇔ parcela_pnl='true' (regra atual, inalterada).
* Um contrato é PNP ⇔ tem ao menos 1 parcela PNP naquele momento.
* Um cliente é PNP ⇔ tem ao menos 1 contrato PNP naquele momento.
* Flags são vigentes: quando a última parcela PNP de um contrato é paga ou removida, o  
  contrato deixa de ser PNP. O mesmo vale em cascata para o cliente.

  O ETL já garante vigência da flag por parcela: o upsert de pagos traz explicitamente FALSE AS  
  parcela_pnp e o reconcile limpa a flag em remoção. 

  Frescor da informação

  Pode usar o caminho natural no projeto: calcular as flags dentro da materialized view  
  mv_titles_base (mesmo padrão dos agregados existentes como contact_total_open_value,  
  contract_avg_days_overdue). A defasagem de até 30min do refresh da MV é aceitável para esta  
  feature.

  Critérios de aceite

* Existem duas flags novas, uma por contrato e uma por cliente, disponíveis no construtor de  
  filtros.
* Teste de disjunção (obrigatório): testar os filtros "contratos PNP" e outro "contratos  
  não-PNP" e verificar que nenhum contrato aparece nos dois. Repetir o mesmo teste com "clientes PNP" / "clientes não-PNP" — nenhum cliente pode aparecer nos dois.
* Quando a última parcela PNP de um contrato é paga ou removida, o contrato sai do filtro  
  "contratos PNP" na próxima rodada da MV (até 30min).
* A flag por parcela existente (parcela_pnl) continua funcionando como hoje  
  (backward-compatível).
* O tempo de refresh da mv_titles_base não aumenta significativamente após a mudança (medir  
  antes/depois).

  Cuidado operacional

  As flags novas só ficam populadas após a primeira rodada de refresh da MV pós-deploy (até  
  30min). Avisar o time antes de ativar filtros em produção.

  Fora do escopo

* Alterar como o ETL popula parcela_pnl nas parcelas.
* Renomear o campo parcela_pnl para corrigir o typo.
* Reescrever a lógica title-centric do pipeline de campanhas.

## Rastreabilidade

- **Responsável:** Marcos Rodrigues
- **Quimera:** #3358 (status fonte mapeado → `bloqueado`)
- **Jira:** IAF-109 (projeto IAF)
- **Categoria fonte:** Formalização
- **Criada:** 2026-04-15

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.
- 2026-06-15 — Status sincronizado do Quimera #3358: entregue. Concluída 2026-06-11. Responsável: Marcos Rodrigues.
