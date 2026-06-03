---
id: QMR3351
title: [Bitrix ID-1729] IA não localizando Suprimentos
frente: bitrix-automacoes
status: entregue
prioridade: alta
fonte: quimera+jira
quimera: 3351
jira: IAF-96
categoria: Cobrança
deliverable_type: Outros
story_points: 13
tipo_origem: Bug
responsavel: Leandro Marques
criada: 2026-04-10
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

# QMR3351 — [Bitrix ID-1729] IA não localizando Suprimentos

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3351 · Jira IAF-96 · categoria: Cobrança

Solicitante: João Martins  
Área Solicitante: Cobrança  
Demanda Original: IA não localizando Suprimentos  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1729/](https://blips.bitrix24.com.br/crm/type/1170/details/1729/)  
Descrição: Demanda original: Bom dia Senhores(as)

Abrindo essa demanda apenas para formalizar uma situação que foi passada ao Leandro e JL sendo a seguinte situação.

Cliente inadimplente entra em contato solicitando boletos, IA manda apenas 1. Cliente questiona se não tem nenhum outro, IA informa que não e encerra.

Porém cliente tinha suprimentos no qual não enxergou. Peço que seja ajustado pra IA enxergar o suprimentos na Torre de preferencia ou que pra solução temporária que seja feito algo pelo N8N.

Grato J.

Descrição detalhada: Ajustar o fluxo da IA relacionado ao atendimento de clientes inadimplentes que solicitam boletos, pois atualmente a automação está retornando apenas 1 boleto e, quando questionada sobre a existência de outros, informa incorretamente que não há mais títulos pendentes, encerrando o atendimento. Conforme relatado, existem casos em que o cliente também possui suprimentos em aberto, mas esses itens não estão sendo localizados pela IA. Avaliar prioritariamente uma correção para que a IA passe a enxergar os suprimentos na Torre. Caso a correção definitiva na origem não seja viável no curto prazo, implementar uma solução temporária via N8N para contornar o problema e garantir que a IA considere esses suprimentos durante o atendimento. O objetivo é evitar respostas incorretas ao cliente e garantir a consulta completa dos débitos disponíveis.

## Rastreabilidade

- **Responsável:** Leandro Marques
- **Quimera:** #3351 (status fonte mapeado → `entregue`)
- **Jira:** IAF-96 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-04-10
- **Concluída:** 2026-05-14

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.