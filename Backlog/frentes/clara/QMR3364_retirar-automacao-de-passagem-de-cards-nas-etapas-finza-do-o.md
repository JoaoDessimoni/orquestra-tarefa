---
id: QMR3364
title: [Bitrix ID-1773] Retirar automação de passagem de cards nas etapas Finza do Onboarding Documentação
frente: clara
status: entregue
prioridade: alta
fonte: quimera+jira
quimera: 3364
jira: IAF-115
categoria: Formalização
deliverable_type: Outros
story_points: 5
tipo_origem: Bug
responsavel: João Lucas Freitas
criada: 2026-04-17
concluida: 2026-04-29
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

# QMR3364 — [Bitrix ID-1773] Retirar automação de passagem de cards nas etapas Finza do Onboarding Documentação

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3364 · Jira IAF-115 · categoria: Formalização

Solicitante: Rodolfo Santos  
Área Solicitante: Processos  
Demanda Original: Contexto: Em alinhamento com Jéssica, houve a necessidade da NÃO passagem de cards automáticos desde Nova Compra/Locação até Checklist pois no meio destas fases existe a necessidade de uma aprovação de documentos por meio da Finza, o que não acontecia antes da empresa ter o handover. Para medida futura, a Finza trabalhará no próprio sistema que recebera informação de quando atuar e repassará os contratos aprovados novamente pro fluxo Blips, mas precisamos dessa ação de contenção rápida.

Problema maior: clientes que inserem os dados na plataforma e ela avança sem verificação do time, onerando muito a identificação destes contratos sem validação.  
Além disso, cliente prepara infraestrutrura e pagamentos, podendo não efetivar o contrato por conta de reprovação de documentos nas etapas anteriores.

Ação de contenção bitrix: retirar passagem de cards automaticamente das fases Nova Compra/Locação, Envio de Fotos de Documentos, Endereço do Responsável e Checklist.

Ação definitiva: plataforma Finza e Blips irão se comunicar e a Finza entregará apenas contratos com documentação aceita.  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1773/](https://blips.bitrix24.com.br/crm/type/1170/details/1773/)  
Descrição: Demanda para correção/ajuste de comportamento atual da automação no fluxo de Onboarding Documentação relacionado à Finza. Deve ser implementada uma ação de contenção rápida para interromper a passagem automática de cards entre as etapas Nova Compra/Locação, Envio de Fotos de Documentos, Endereço do Responsável e Checklist, evitando avanço sem validação documental pelo time responsável. O objetivo é impedir que contratos avancem indevidamente no fluxo, gerando preparação de infraestrutura e pagamentos antes da aprovação dos documentos. Como solução definitiva, está previsto um modelo de integração em que a plataforma Finza sinalizará quais contratos tiveram documentação aprovada para então serem reenviados ao fluxo Blips.

## Rastreabilidade

- **Responsável:** João Lucas Freitas
- **Quimera:** #3364 (status fonte mapeado → `entregue`)
- **Jira:** IAF-115 (projeto IAF)
- **Categoria fonte:** Formalização
- **Criada:** 2026-04-17
- **Concluída:** 2026-04-29

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.