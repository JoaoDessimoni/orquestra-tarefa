---
id: QMR3418
title: [Bitrix ID-1853] Negativação Indevida Finza e Ideal
frente: livia
status: cancelado
prioridade: media
fonte: quimera+jira
quimera: 3418
jira: IAF-181
categoria: TI
deliverable_type: Pipeline de dados
story_points: 3
tipo_origem: Bug
responsavel: Joao Lucas Pontes Freitas
criada: 2026-05-08
concluida: null
prazo: null
prazo_estimado: False
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: []
bloqueia: []
tags: [fonte-quimera-jira, cat-ti]
---

# QMR3418 — [Bitrix ID-1853] Negativação Indevida Finza e Ideal

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3418 · Jira IAF-181 · categoria: TI

Solicitante: João Vinicius Dessimoni  
Área Solicitante: IA  
Demanda Original: o João Martins teve a seguinte duvida:

Uma dúvida sobre a baixa das negativações indevidas da Finza e Ideal no CNPJ Blips. Time Tech fez esse processo, porém a torre ainda consta a marcação de negativado na Finza e Ideal. Irão realizar a retirada da flag? Pergunto pra quando for negativar corretamente precisaria dessa limpeza

Hoje não recebemos nada de volta, teriamos que ajustar a consulta do ETL pra verificar esse campo no MF e atualizar na Torre.

Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1853/](https://blips.bitrix24.com.br/crm/type/1170/details/1853/)

Descrição: Verificar o fluxo/consulta de ETL responsável por refletir na Torre o status de negativação da Finza e Ideal para o CNPJ Blips. O processo de baixa/limpeza das negativações indevidas teria sido realizado pelo Time Tech, porém a Torre ainda exibe a marcação de negativado em Finza e Ideal. É necessário analisar se a consulta atual do ETL está capturando corretamente o campo no MF, ajustar a lógica de leitura/validação desse campo quando necessário e garantir que a Torre seja atualizada com a remoção da flag de negativado quando a baixa já tiver ocorrido. O objetivo é evitar inconsistências antes de futuras negativações corretas e garantir que a Torre reflita o status atualizado.

Anexos/Links adicionais: não informado.

## Rastreabilidade

- **Responsável:** João Lucas Freitas
- **Quimera:** #3418 (status fonte mapeado → `refinado`)
- **Jira:** IAF-181 (projeto IAF)
- **Categoria fonte:** TI
- **Criada:** 2026-05-08

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.
- 2026-06-15 — Status sincronizado do Quimera #3418: cancelado. Responsável: Joao Lucas Pontes Freitas.
