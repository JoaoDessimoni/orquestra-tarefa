---
id: QMR3434
title: [Bitrix ID-1903] Cliente Inadimplente sem Card
frente: bitrix-automacoes
status: entregue
prioridade: media
fonte: quimera+jira
quimera: 3434
jira: IAF-205
categoria: Cobrança
deliverable_type: Outros
story_points: 3
tipo_origem: Bug
responsavel: Leandro Marques
criada: 2026-05-18
concluida: 2026-05-25
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

# QMR3434 — [Bitrix ID-1903] Cliente Inadimplente sem Card

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3434 · Jira IAF-205 · categoria: Cobrança

Solicitante: Maycon Ramos  
Área Solicitante: Cobrança  
Demanda Original: 12506336 e 12506335 - cliente inadimplente à 64 dias - 18/05 não tinha card  
12406127 - cliente inadimplente à 93 dias - 14/05 não tinha card  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1903/](https://blips.bitrix24.com.br/crm/type/1170/details/1903/)

Descrição: Verificar por que os clientes inadimplentes informados não tiveram cards gerados/criados no processo de cobrança, mesmo estando com atraso relevante.

Casos reportados:

* Clientes/IDs 12506336 e 12506335: inadimplentes há 64 dias; em 18/05 não havia card criado.
* Cliente/ID 12406127: inadimplente há 93 dias; em 14/05 não havia card criado.

Objetivo da tarefa:

* Investigar a automação/regra responsável pela geração de cards para clientes inadimplentes.
* Validar se os clientes citados atendiam aos critérios para criação de card nas datas informadas.
* Identificar se houve falha na execução, filtro/regra incorreta, ausência de dados ou outro impedimento.
* Corrigir o fluxo, caso seja confirmado erro, para evitar reincidência.
* Se aplicável, criar ou reprocessar os cards pendentes para os clientes mencionados.

Anexos/links adicionais: não informado.

## Rastreabilidade

- **Responsável:** Leandro Marques
- **Quimera:** #3434 (status fonte mapeado → `entregue`)
- **Jira:** IAF-205 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-05-18
- **Concluída:** 2026-05-25

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.