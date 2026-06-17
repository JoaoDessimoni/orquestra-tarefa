---
id: QMR3287
title: [Bitrix ID-957] Atualização Bitrix - mover casos pós-recompra FIDC para fila normal
frente: bitrix-automacoes
status: cancelado
prioridade: media
fonte: quimera+jira
quimera: 3287
jira: IAF-6
categoria: Cobrança
deliverable_type: Outros
story_points: 3
tipo_origem: Bug
responsavel: Joao Lucas Pontes Freitas
criada: 2026-03-06
concluida: null
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

# QMR3287 — [Bitrix ID-957] Atualização Bitrix - mover casos pós-recompra FIDC para fila normal

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3287 · Jira IAF-6 · categoria: Cobrança

Solicitante: Lucas Reimer (lucas.reimer@blips.com.br)  
Área Solicitante: Finza  
Demanda Original: Hoje os titulos do FIDC em atraso estão caindo para uma fila separada no Bitrix para a cobrança. Gostaria que os casos após a recompra, saíssem da fila do FIDC e entrassem em fila normal de atendimento.  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/957/](https://blips.bitrix24.com.br/crm/type/1170/details/957/)

Descrição detalhada (para o time de IA e Automação):  
1) Contexto atual:

* Casos de títulos do FIDC em atraso são roteados automaticamente para uma fila separada no Bitrix destinada à cobrança.
* Quando ocorre a recompra (recompra do título), os casos permanecem ou não saem corretamente dessa fila, sendo necessário que passem para a fila normal de atendimento.

2) Objetivo:

* Ajustar a lógica/automação no Bitrix para que, quando um caso receber o evento/flag de "recompra", ele seja removido da fila FIDC e reencaminhado para a fila normal de atendimento.

3) Escopo sugerido (tarefas esperadas):

* Revisar as automações/workflows e regras de roteamento atuais que movem casos para a fila FIDC.
* Identificar o campo/evento que sinaliza "recompra" (ex.: status, campo customizado, tag ou evento de integração) e confirmar como a informação chega ao Bitrix.
* Implementar condição adicional na regra de roteamento: se recompra = true (ou status correspondente), mover para fila normal em vez de fila FIDC.
* Garantir que quaisquer automações concorrentes (ex.: regras de prioridade, time de cobrança) não revertam o roteamento.
* Testes em ambiente de homologação (casos de teste: recompra antes do roteamento, recompra após roteamento, sem recompra) e validar o comportamento esperado.
* Planejar liberação/implantação e monitoramento pós-implementação (logs, alertas, rollback se necessário).

4) Critérios de aceitação:

* Quando um caso tiver o indicador de recompra, ele não deve ficar na fila FIDC e deve aparecer na fila normal de atendimento.
* Testes com diferentes cenários (recompra pré e pós-roteamento) aprovados em homologação.
* Registro das alterações no Bitrix e documentação das regras atualizadas.

5) Informações pendentes / perguntas ao solicitante (se aplicável):

* Qual o campo ou evento exato que identifica a recompra no Bitrix (nome do campo, valor e/ou integração responsável)?
* Há preferência sobre qual fila "normal" deve receber os casos (nome da fila)?
* Existe ambiente de homologação disponível para testes e quem é o contato técnico no time do cliente para validar os testes?

Observações:

* Não identificado anexo no pedido original.
* Demanda não marcada como urgente.

## Rastreabilidade

- **Responsável:** João Lucas Freitas
- **Quimera:** #3287 (status fonte mapeado → `refinado`)
- **Jira:** IAF-6 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-03-06

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.
- 2026-06-15 — Status sincronizado do Quimera #3287: cancelado. Responsável: Joao Lucas Pontes Freitas.
