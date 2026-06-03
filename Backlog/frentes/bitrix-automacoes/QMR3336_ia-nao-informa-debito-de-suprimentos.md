---
id: QMR3336
title: [Bitrix ID-1679] IA não informa débito de suprimentos
frente: bitrix-automacoes
status: entregue
prioridade: alta
fonte: quimera+jira
quimera: 3336
jira: IAF-78
categoria: Cobrança
deliverable_type: Outros
story_points: 13
tipo_origem: Bug
responsavel: Leandro Marques
criada: 2026-04-07
concluida: 2026-05-14
prazo: null
prazo_estimado: False
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: []
bloqueia: []
tags: [fonte-quimera-jira, cat-cobranca]
---

# QMR3336 — [Bitrix ID-1679] IA não informa débito de suprimentos

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3336 · Jira IAF-78 · categoria: Cobrança

Solicitante: joao.martins@blips.com.br  
Área Solicitante: Cobrança  
Demanda Original: IA não informa débito de suprimentos  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1679/](https://blips.bitrix24.com.br/crm/type/1170/details/1679/)  
Descrição: Boa tarde time,

Nos deparamos com uma situação no qual a IA não consegue localizar o débito de Suprimentos do cliente, deixando de informar o que gerou inadimplência e juros, e o cliente se recusa a pagar.

Segundo o contexto informado, a IA não retornou essa informação porque a torre atual não possui os dados de suprimentos. Também existe uma integração para buscar suprimentos no Sankhya, porém ela não está ativa, o que contribui diretamente para a falha no retorno do débito.

Há relação com o ticket 1337, já aberto anteriormente, que solicita a inclusão da base Sankhya na torre.

Solicita-se analisar a causa do problema, validar a dependência da integração com o Sankhya e/ou da inclusão da base na torre, e corrigir o comportamento da IA para que consiga localizar e informar corretamente os débitos de suprimentos ao cliente, evitando omissão de valores que geram inadimplência e juros.

Anexo: não informado.

## Rastreabilidade

- **Responsável:** Leandro Marques
- **Quimera:** #3336 (status fonte mapeado → `entregue`)
- **Jira:** IAF-78 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-04-07
- **Concluída:** 2026-05-14

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.