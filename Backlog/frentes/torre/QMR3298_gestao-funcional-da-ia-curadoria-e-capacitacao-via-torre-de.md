---
id: QMR3298
title: [Bitrix ID-1343] Gestão Funcional da IA - Curadoria e capacitação via Torre de Controle
frente: torre
status: entregue
prioridade: alta
fonte: quimera+jira
quimera: 3298
jira: IAF-23
categoria: Cobrança
deliverable_type: Outros
story_points: 13
tipo_origem: Tarefa
responsavel: Leandro Marques
criada: 2026-03-18
concluida: 2026-05-07
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

# QMR3298 — [Bitrix ID-1343] Gestão Funcional da IA - Curadoria e capacitação via Torre de Controle

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3298 · Jira IAF-23 · categoria: Cobrança

Solicitante: João Martins (joao.martins@blips.com.br)  
Área Solicitante: Cobrança  
Demanda Original:  
Boa tarde Senhores segue formalização da demanda passada no grupo dia 26/02/2026.

4️⃣ Gestão Funcional da IA  
Permitir gestão e curadoria da IA pelo time de operações diretamente na plataforma Torre de Controle, impactando diretamente na performance operacional.

Capacitação e treinamento da IA por parte do time de Cobrança de forma agnóstica. Descentralizando e ganhando aceleridade nos processos.

att;

Descrição detalhada da tarefa:  
Objetivo: Implementar funcionalidades na plataforma Torre de Controle que permitam ao time de operações (Cobrança) gerir, curar e treinar modelos/rotinas da IA sem depender diretamente do time de IA/Desenvolvimento, garantindo segurança, rastreabilidade e controle de versão.

Escopo proposto:  
1) Interface de Curadoria

* Painel para visualizar exemplos de inputs/outputs da IA, com filtros por data, origem e status.
* Permitir marcação/manual de exemplos como corretos/errados e anotação de observações.
* Mecanismo para agrupar e priorizar exemplos a serem usados em treino/retreinamento.

2) Módulo de Treinamento/Capacitação Agnóstico

* Fluxo para que o time de Cobrança submeta conjuntos de exemplos (CSV/JSON) para treinar/ajustar pesos/parametros de modo controlado.
* Validação automática dos dados submetidos (schema, volumes, duplicatas) antes de aceitar para treino.
* Capacidade de rodar treinos em sandbox/ambiente controlado com métricas geradas (precisão, recall, F1, perda).

3) Controle de Versão e Segurança

* Histórico de versões do modelo e do dataset usado no treino, com possibilidade de rollback.
* Permissões: papéis definidos (operador, curador, aprovador) para limitar ações sensíveis.
* Auditoria: logs de quem fez alterações, quando e quais parâmetros foram alterados.

4) Avaliação e Aprovação

* Ambiente de pré-produção para avaliação dos resultados por stakeholders.
* Processo de aprovação para promover o modelo para produção (checklist de métricas e teste de aceitação).

5) Integração com pipelines existentes na Torre de Controle

* Endpoints/API para disparar treinos e para recuperar métricas e versões.
* Notificações (Slack/Email/Bitrix) sobre status de treinos e aprovações.

Critérios de aceitação sugeridos:

* Operadores do time de Cobrança conseguem submeter exemplos e marcá-los em produção de forma rastreável.
* É possível executar um treino controlado e obter métricas comparativas entre versões.
* Implementadas permissões e logs de auditoria.
* Processo de aprovação que permita promover um modelo para produção com checklist preenchido.

Dependências e dúvidas:

* Precisamos confirmar qual(s) modelos/serviços de IA atuais serão gerenciados por essa funcionalidade.
* Confirmar armazenamento de dados sensíveis e políticas de anonimização (LGPD).
* Definir ambientes disponíveis para treino (sandbox/prd) e custos computacionais.

Links/Anexos:

* (Nenhum anexo fornecido)

Prioridade: 1 (Altíssima) — solicitada como urgente pelo solicitante.

Observações finais:

* Recomenda-se alinhamento inicial entre time de IA/Automação e representantes de Cobrança para detalhar requisitos UX e fluxos de permissão antes de iniciar desenvolvimento.

## Rastreabilidade

- **Responsável:** Leandro Marques
- **Quimera:** #3298 (status fonte mapeado → `entregue`)
- **Jira:** IAF-23 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-03-18
- **Concluída:** 2026-05-07

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.