---
id: QMR3409
title: [Bitrix ID-1815] Automação da raia KIT AJUIZAMENTO
frente: clara
status: entregue
prioridade: baixa
fonte: quimera+jira
quimera: 3409
jira: IAF-168
categoria: Formalização
deliverable_type: Outros
story_points: 5
tipo_origem: Tarefa
responsavel: Marcos Rodrigues
criada: 2026-04-27
concluida: 2026-06-02
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

# QMR3409 — [Bitrix ID-1815] Automação da raia KIT AJUIZAMENTO

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3409 · Jira IAF-168 · categoria: Formalização

Solicitante: Sara Teixeira  
Área Solicitante: Jurídico  
Demanda Original: Demanda para o time de IA – Automação da raia KIT AJUIZAMENTO

Precisamos automatizar a etapa de montagem do KIT AJUIZAMENTO, que hoje é feita manualmente e representa um gargalo operacional.

Objetivo

Automatizar a coleta, consolidação e disponibilização dos documentos necessários para ajuizamento, tanto para os casos Blips quanto Ideal.

Cenário atual

Atualmente, a equipe faz manualmente a busca dos documentos em diferentes plataformas/sistemas, o que gera demora, retrabalho e risco operacional.

Documentos e respectivas fontes

Os documentos atualmente são coletados nas seguintes plataformas:

Contrato → Plataforma Blips  
Nota fiscal → Sankhya  
Demonstrativo de débito → Looker Studio  
Notificação → MRS  
Lembrete de pagamento / retirada / bloqueio / distrato → e-mails Blips e Ideal  
Necessidade de automação

A ideia é que a IA/automação consiga:

Identificar o caso a ser tratado;  
Buscar automaticamente os documentos nas fontes correspondentes;  
Consolidar todos os arquivos que compõem o KIT AJUIZAMENTO;  
Organizar os documentos de forma padronizada;  
Disponibilizar o kit final para o time jurídico.

Hoje os documentos são colocados em uma Drive compartilhada com a assessoria jurídica.

Como alternativa, também podemos avaliar a disponibilização na Drive e/ou no Bitrix, para acesso do time jurídico interno.

Resultado esperado

Esperamos reduzir o trabalho manual na montagem do kit, ganhar velocidade no fluxo de ajuizamento e diminuir riscos de perda de documentos ou inconsistências na composição dos arquivos.

Pontos para avaliação do time de IA

* Viabilidade de integração com as plataformas mencionadas;
* Captura de documentos a partir de e-mails;
* Padronização do nome e organização dos arquivos;
* Definição do melhor repositório final: Drive ou Bitrix;
* Possibilidade de rastreabilidade/status da montagem do kit.

Observação: A automação deve contemplar os casos das operações Blips e Ideal.

Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1815/](https://blips.bitrix24.com.br/crm/type/1170/details/1815/)

Descrição: Criar uma automação para montagem do KIT AJUIZAMENTO, contemplando a identificação do caso, coleta automática de documentos em múltiplas fontes (Plataforma Blips, Sankhya, Looker Studio, MRS e e-mails), consolidação dos arquivos obrigatórios, padronização de nomenclatura e organização dos documentos, além da disponibilização do kit final ao time jurídico. A solução deve considerar os fluxos das operações Blips e Ideal, avaliar a viabilidade técnica das integrações necessárias, permitir definição do repositório final entre Drive e Bitrix e, se possível, fornecer rastreabilidade/status da montagem do kit.

## Rastreabilidade

- **Responsável:** Marcos Rodrigues
- **Quimera:** #3409 (status fonte mapeado → `entregue`)
- **Jira:** IAF-168 (projeto IAF)
- **Categoria fonte:** Formalização
- **Criada:** 2026-04-27
- **Concluída:** 2026-06-02

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.