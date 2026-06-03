---
id: QMR3349
title: [Bitrix ID-1723] Flag de desativar repique e visualizar público de repique - Torre de Controle
frente: torre
status: entregue
prioridade: baixa
fonte: quimera+jira
quimera: 3349
jira: IAF-94
categoria: Cobrança
deliverable_type: Outros
story_points: 5
tipo_origem: Tarefa
responsavel: Marcos Rodrigues
criada: 2026-04-10
concluida: 2026-04-15
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

# QMR3349 — [Bitrix ID-1723] Flag de desativar repique e visualizar público de repique - Torre de Controle

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3349 · Jira IAF-94 · categoria: Cobrança

Solicitante: João Martins  
Área Solicitante: Cobrança  
Demanda Original: Flag de desativar repique e visualizar público de repique - Torre de Controle  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1723/](https://blips.bitrix24.com.br/crm/type/1170/details/1723/)  
Descrição: Solicitação para evoluir a Torre de Controle com duas frentes funcionais relacionadas ao controle de repique em campanhas/réguas de cobrança.

1\. Permitir marcar/desmarcar o repique em envios anteriores, criando uma opção de ativar ou desativar essa lógica para ações pontuais.  
2\. Garantir que, em cenários específicos como ações de negativação, seja possível desativar o repique para alcançar 100% do público definido na ação.  
3\. Disponibilizar visibilidade, dentro da campanha/régua, dos seguintes volumes:

* público total
* público de repique
* público que será efetivamente disparado  
  4\. A melhoria deve apoiar a tomada de decisão operacional sobre manter ou desativar repique em réguas pontuais.

Objetivo: dar maior controle operacional ao time de Cobrança sobre o uso do repique em campanhas específicas e ampliar a visibilidade do público impactado antes do disparo.

‌

---

> Mensagem João:  
> Tem uma regra na torre que fala que ações geradas por campanhas broadcast são 'puladas' se a pessoa já tiver recebido com sucesso qualquer outra ação no dia
>
> Então esses contatos já tinham recebido alguma ação naquele dia e por isso pulou algumas das ações geradas pela campanha de negativação.
>
> Agora preciso ver com vcs, queremos deixar essa regra? Ela é feita para evitar que a gente gere spam
>
> Mandar várias mensagens em vários horários diferentes para a mesma pessoa
>
> A minha sugestão é deixar essa regra, mas adicionar uma opção na hora configurar a campanha para ignroar essa regra, ou seja, mesmo que a pessoa já tenha recebido ação no dia de hoje
>
> Ela vai disparar as ações dessa campanha
>
> Aí a gente só liga isso pra campanhas críticas
>
> para conseguir ainda evitar o spam

## Rastreabilidade

- **Responsável:** Marcos Rodrigues
- **Quimera:** #3349 (status fonte mapeado → `entregue`)
- **Jira:** IAF-94 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-04-10
- **Concluída:** 2026-04-15

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.