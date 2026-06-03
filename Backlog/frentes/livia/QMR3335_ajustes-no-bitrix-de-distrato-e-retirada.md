---
id: QMR3335
title: [Bitrix ID-1673] Ajustes no Bitrix de Distrato e Retirada
frente: livia
status: entregue
prioridade: alta
fonte: quimera+jira
quimera: 3335
jira: IAF-77
categoria: Cobrança
deliverable_type: Outros
story_points: 13
tipo_origem: Tarefa
responsavel: João Pedro
criada: 2026-04-07
concluida: 2026-06-01
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

# QMR3335 — [Bitrix ID-1673] Ajustes no Bitrix de Distrato e Retirada

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3335 · Jira IAF-77 · categoria: Cobrança

Solicitante: Maycon Ramos  
Área Solicitante: Cobrança  
Demanda Original: Preciso que seja configurado nos funis de Logística Reversa, Distrato e Retirada os seguintes pontos:

1 - Rodar a rotina de atualização de financeiro, contemplando os valores atualizados, dias em atraso e status do contrato na plataforma;  
2 - Alterar o nome dos cards para o mesmo modelo utilizado no funil de cobrança, mantendo eles na mesma raia em que se encontram;  
3 - Eliminar os cards duplicados considerando o número do contrato;  
4 - Migrar os clientes com status “Recuperação de Crédito” na plataforma Blips para o board Recuperação de Crédito, na raia “Backlog Recuperação Crédito”;  
5 - Remover dos boards os contratos que estejam nas seguintes raias do Bitrix Jurídico:

Processo Ajuizado  
Liminar Indeferida  
Liminar Deferida  
Máquina Recuperada  
Acordo  
Desistência

6 - Colocar informação no campos localizados nos funis de Distrato e Retirada:

Altura: `Altura`  
Largura: `Largura`  
Comprimento: {{ Comprimento}}  
Peso: `Peso`

7 - Inserir informação nos campos da mesma forma que foi feito no funil de Cobrança 4.0.  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1673/](https://blips.bitrix24.com.br/crm/type/1170/details/1673/)

Descrição: Configurar ajustes nos funis de Logística Reversa, Distrato e Retirada no Bitrix/automação da operação Finza, contemplando atualização financeira com valores, dias em atraso e status do contrato; padronização do nome dos cards conforme o modelo do funil de cobrança sem alterar a raia atual; remoção de cards duplicados por número de contrato; migração automática de clientes com status “Recuperação de Crédito” para o board e raia correspondentes; remoção de contratos presentes em raias específicas do Bitrix Jurídico; preenchimento dos campos Altura, Largura, Comprimento e Peso nos funis de Distrato e Retirada; e replicação da mesma lógica de inserção de informações já aplicada no funil de Cobrança 4.0. Garantir consistência entre boards, evitar duplicidades e preservar a organização operacional dos funis impactados.

## Rastreabilidade

- **Responsável:** João Pedro
- **Quimera:** #3335 (status fonte mapeado → `entregue`)
- **Jira:** IAF-77 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-04-07
- **Concluída:** 2026-06-01

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.