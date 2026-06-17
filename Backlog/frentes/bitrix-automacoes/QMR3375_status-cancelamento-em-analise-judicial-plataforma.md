---
id: QMR3375
title: [Bitrix ID-1807] Status Cancelamento - Em análise judicial | Plataforma
frente: bitrix-automacoes
status: entregue
prioridade: alta
fonte: quimera+jira
quimera: 3375
jira: IAF-129
categoria: Cobrança
deliverable_type: Outros
story_points: 5
tipo_origem: Tarefa
responsavel: Marcos Rodrigues
criada: 2026-04-24
concluida: 2026-06-11
prazo: 2026-06-09
prazo_estimado: True
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: []
bloqueia: []
tags: [fonte-quimera-jira, cat-cobranca]
---

# QMR3375 — [Bitrix ID-1807] Status Cancelamento - Em análise judicial | Plataforma

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3375 · Jira IAF-129 · categoria: Cobrança

Solicitante: João Martins  
Área Solicitante: Cobrança  
Demanda Original: Status Cancelamento - Em análise judicial | Plataforma  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1807/](https://blips.bitrix24.com.br/crm/type/1170/details/1807/)  
Descrição: Boa tarde senhores(as),

Atualmente temos contratos dentro da plataforma com status de cancelamento igual a "Em análise judicial" no qual estão sendo acionado pela torre de controle ou pelo Hyper quando cliente entra em contato.

Pedimos que seja feito a adição de todos esses contratos no blocklist para que não seja acionado pela torre porém que esta rotina seja atualizada diariamente pra verificar se tem novos ou se algum contrato saiu da analise judicial podendo voltar a ser acionado e saindo do blocklist consequentemente.

Além disso tem a situação de clientes em analise judicial entrar em contato de forma espontânea no Hyper para isso pedimos que seja criado um fluxo no Hyper parar verificar na plataforma se o contrato é um analise judicial e adicionar o rótulo de analise judicial em todos clientes receptivo para evitar acionamento incorreto.

Descrição detalhada: Implementar automação para tratamento de contratos com status de cancelamento "Em análise judicial" na operação Finza. A demanda contempla duas frentes: (1) inclusão automática de contratos com esse status em uma blocklist para impedir acionamentos indevidos pela torre de controle, com rotina diária de atualização para incluir novos contratos elegíveis e remover da blocklist aqueles que deixarem de estar em análise judicial; (2) criação de fluxo no Hyper para consultar a plataforma quando houver contato receptivo espontâneo, identificar se o contrato está em análise judicial e aplicar rótulo específico de "análise judicial" nos clientes receptivos, evitando acionamentos incorretos. A implementação deve considerar integração/consulta à plataforma, atualização recorrente da blocklist e consistência da regra entre canais de acionamento e atendimento receptivo.

## Rastreabilidade

- **Responsável:** Marcos Rodrigues
- **Quimera:** #3375 (status fonte mapeado → `validacao`)
- **Jira:** IAF-129 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-04-24
- **Prazo (estimado):** 2026-06-09

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.
- 2026-06-15 — Status sincronizado do Quimera #3375: entregue. Concluída 2026-06-11. Responsável: Marcos Rodrigues.
