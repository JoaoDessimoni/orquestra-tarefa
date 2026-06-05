---
titulo: "Correção de datas de criação — tickets migrados Jira → Quimera (dry-run)"
data: 2026-06-04
autor: João Vinícius
tipo: analise / reconciliacao de dados
status: APLICADO — 130 created_at gravados no Quimera em 2026-06-04 (MCP). Parte B (Cycle Time) segue pendente no banco.
---

# Correção de datas — migração Jira → Quimera

## Contexto

A migração das tarefas do Jira (projeto **IAF**, `blips-dev.atlassian.net`) para o Quimera via CSV **redefiniu o `created_at` de todos os tickets para o timestamp do import**, quebrando os KPIs sensíveis a data (Lead Time, Cycle Time, Conclusão, Intruders). O Jira preserva as datas reais. Este documento cruza os dois sistemas e propõe a correção do `created_at` no Quimera.

## Método

- **Mapa Quimera↔Jira:** frontmatter dos itens `fonte: quimera+jira` em `Backlog/frentes/**/*.md` (reconciliação de 2026-06-02).
- **Datas reais:** AO VIVO no Jira (JQL) — `fields.created` e `fields.resolutiondate`. Jira é a fonte da verdade (o `.md` estava ~1 dia defasado no resolved).
- **Escopo:** apenas `fonte: quimera+jira`. Itens só-Jira e nativos do Quimera não entram.

## Resumo

- **Tickets-alvo (Quimera a corrigir):** 130
- **Jira keys distintas:** 129 — IAF-122 mapeia para 2 tickets (QMR3371 e QMR3372).
- **Ação por ticket:** `update_ticket(id=<nº>, created_at = <created real do Jira>)`.

## Limitação dura do MCP (decidido: corrigir criação + escalar resto)

`update_ticket` grava **só `created_at`**. NÃO há como gravar data de finalização nem reescrever histórico de status — e o **Cycle Time** do Quimera deriva desse histórico, não do `created_at`. Logo: corrigir `created_at` conserta a âncora de criação (Conclusão, Intruders, início do Lead Time), mas **finalização e Cycle Time ficam para o backfill no banco** (ver §Spec de backfill).

## Tabela de reconciliação (dry-run)

> `created_at atual (Quimera)` = **PENDENTE** — preenchido quando o MCP Quimera conectar. Espera-se ≈ timestamp do import em todas as linhas.

| Quimera | Jira | Título | created REAL (Jira) → gravar | resolved (Jira) | status Jira | status .md |
|---|---|---|---|---|---|---|
| 3287 | IAF-6 | [Bitrix ID-957] Atualização Bitrix - mover c.. | **2026-03-06** | — | BLOQUEADO | refinado |
| 3288 | IAF-12 | Configuração cloud boleto@finza.com.br | **2026-03-18** | 2026-04-07 | Concluído | entregue |
| 3289 | IAF-13 | Recriação fluxo de renegociação | **2026-03-18** | 2026-04-07 | Concluído | entregue |
| 3290 | IAF-14 | Adicionar guardrails aos fluxos | **2026-03-18** | 2026-04-07 | Concluído | entregue |
| 3291 | IAF-15 | [Bitrix ID-615] Projeto IA atendimento Nível.. | **2026-03-18** | 2026-05-07 | Concluído | entregue |
| 3292 | IAF-16 | [Bitrix ID-817] Erro IA dados financeiros | **2026-03-18** | 2026-04-30 | Concluído | entregue |
| 3293 | IAF-17 | [Bitrix ID-861] Automação diária de validaçã.. | **2026-03-18** | — | Priorizado | refinado |
| 3294 | IAF-18 | Melhoria IA torre v2.0 | **2026-03-18** | 2026-04-07 | Concluído | entregue |
| 3295 | IAF-19 | Acompanhamento dos atendimentos hypeflow e u.. | **2026-03-18** | — | EM ANDAMENTO | entregue |
| 3296 | IAF-20 | Correção de erros fluxos | **2026-03-18** | 2026-04-07 | Concluído | entregue |
| 3297 | IAF-22 | [Bitrix ID-1341] Solicitação Prioridades Vin.. | **2026-03-18** | 2026-04-06 | Concluído | entregue |
| 3298 | IAF-23 | [Bitrix ID-1343] Gestão Funcional da IA - Cu.. | **2026-03-18** | 2026-05-08 | Concluído | entregue |
| 3299 | IAF-24 | [Bitrix ID-1371] Valentina base de dados | **2026-03-18** | 2026-04-07 | Concluído | entregue |
| 3300 | IAF-25 | Centralização dos agentes Esperanza e Valent.. | **2026-03-18** | 2026-04-07 | Concluído | entregue |
| 3301 | IAF-26 | Passar estrutura de templates para Finza | **2026-03-18** | 2026-04-07 | Concluído | entregue |
| 3302 | IAF-28 | n8n - ajustar whatsapp | **2026-03-18** | 2026-04-14 | Concluído | entregue |
| 3303 | IAF-29 | validação do 'transferiu humano' - Hyper | **2026-03-18** | 2026-04-14 | Concluído | entregue |
| 3304 | IAF-30 | Fluxo de consistência de dados da torre | **2026-03-17** | — | BLOQUEADO | refinado |
| 3305 | IAF-31 | Importar novos dados para a torre de controle | **2026-03-18** | 2026-04-02 | Concluído | entregue |
| 3306 | IAF-36 | Migração de tools da Socorro para Valentina | **2026-03-19** | 2026-04-10 | Concluído | entregue |
| 3327 | IAF-67 | Realizar indexação da pesquisa na aba de ações | **2026-04-07** | — | EM DESENVOLVIMENTO | validacao |
| 3328 | IAF-69 | Desenvolver IA para formalização na Finza | **2026-04-07** | — | EM DESENVOLVIMENTO | cancelado |
| 3329 | IAF-71 | Implementar opções de cooldown 0 e infinito .. | **2026-04-07** | 2026-04-08 | Concluído | entregue |
| 3330 | IAF-72 | Verificar falha na extração de base filtrada.. | **2026-04-07** | 2026-04-08 | Concluído | entregue |
| 3331 | IAF-73 | Adicionar identificação de PNP quando maior .. | **2026-04-07** | 2026-04-15 | Concluído | entregue |
| 3332 | IAF-74 | Incluir colunas de segmento, modalidade e em.. | **2026-04-07** | 2026-04-07 | Concluído | entregue |
| 3333 | IAF-75 | Implementação de novos Templates da MRS para.. | **2026-04-07** | 2026-04-10 | Concluído | entregue |
| 3334 | IAF-76 | Sistema de Tags Agente | **2026-04-07** | 2026-04-14 | Concluído | entregue |
| 3335 | IAF-77 | [Bitrix ID-1673] Ajustes no Bitrix de Distra.. | **2026-04-07** | — | Backlog | entregue |
| 3336 | IAF-78 | [Bitrix ID-1679] IA não informa débito de su.. | **2026-04-07** | 2026-05-15 | Concluído | entregue |
| 3337 | IAF-79 | Criação da visualização do histórico da dete.. | **2026-04-07** | 2026-04-07 | Concluído | entregue |
| 3338 | IAF-81 | [Bitrix ID-663] Automação de envio de formul.. | **2025-11-14** | — | BLOQUEADO | cancelado |
| 3339 | IAF-82 | Upgrades Torre (Open to Read) | **2026-04-09** | 2026-04-30 | Concluído | entregue |
| 3340 | IAF-83 | Desenvolver atualização automática de coluna.. | **2026-04-09** | 2026-04-09 | Concluído | entregue |
| 3341 | IAF-84 | Ajuste de formatação das Conversas na torre | **2026-04-09** | 2026-04-13 | Concluído | entregue |
| 3342 | IAF-85 | Implementar salvamento frequente de tags e c.. | **2026-04-09** | 2026-04-14 | Concluído | entregue |
| 3343 | IAF-86 | Corrigir filtros de busca por nome na Torre | **2026-04-09** | 2026-04-13 | Concluído | entregue |
| 3344 | IAF-89 | [FRANCISCO] Setup inicial e normalização de .. | **2026-04-09** | 2026-04-13 | Concluído | entregue |
| 3345 | IAF-90 | [FRANCISCO] Desenvolvimento das tools | **2026-04-09** | 2026-04-13 | Concluído | entregue |
| 3346 | IAF-91 | [FRANCISCO] Persistência do histórico de con.. | **2026-04-09** | 2026-04-28 | Concluído | entregue |
| 3347 | IAF-92 | [Bitrix ID-1715] Problema ao Gerar relatório.. | **2026-04-09** | 2026-04-10 | Concluído | entregue |
| 3348 | IAF-93 | [Bitrix ID-1721] Criação de template de liga.. | **2026-04-09** | 2026-04-15 | Concluído | entregue |
| 3349 | IAF-94 | [Bitrix ID-1723] Flag de desativar repique e.. | **2026-04-10** | 2026-04-16 | Concluído | entregue |
| 3350 | IAF-95 | [VALENTINA] Preparar deploy em prod | **2026-04-10** | 2026-05-04 | Concluído | entregue |
| 3351 | IAF-96 | [Bitrix ID-1729] IA não localizando Suprimen.. | **2026-04-10** | 2026-05-15 | Concluído | entregue |
| 3352 | IAF-97 | Filtros de data e tags | **2026-04-13** | 2026-04-13 | Concluído | entregue |
| 3353 | IAF-98 | Refatorar regra de revalidar filtro da torre | **2026-04-13** | 2026-04-15 | Concluído | entregue |
| 3354 | IAF-99 | Criar versão do agente de transferência vers.. | **2026-04-13** | 2026-04-22 | Concluído | entregue |
| 3355 | IAF-101 | Padronizar Tags | **2026-04-14** | 2026-04-17 | Concluído | entregue |
| 3356 | IAF-102 | Modificar Dashboard para mostrar dados sobre.. | **2026-04-14** | 2026-04-30 | Concluído | entregue |
| 3357 | IAF-103 | [Bitrix ID-1747] Criação de templates e dema.. | **2026-04-15** | — | VALIDAÇÃO | entregue |
| 3358 | IAF-109 | Flags PNP a nível de contrato e de cliente (.. | **2026-04-15** | — | VALIDAÇÃO | bloqueado |
| 3359 | IAF-110 | Sistema lógico de Tag para contatos na Torre | **2026-04-16** | 2026-04-27 | Concluído | entregue |
| 3360 | IAF-111 | Ajustes gatilho shankya Hyperflow | **2026-04-16** | 2026-04-24 | Concluído | entregue |
| 3361 | IAF-112 | [Bitrix ID-1761] Unificação de departamentos.. | **2026-04-16** | 2026-04-17 | Concluído | entregue |
| 3362 | IAF-113 | Investigar porque não foram enviadas mensage.. | **2026-04-16** | 2026-04-22 | Concluído | entregue |
| 3363 | IAF-114 | Segmento cards documentação | **2026-04-14** | 2026-04-22 | Concluído | entregue |
| 3364 | IAF-115 | [Bitrix ID-1773] Retirar automação de passag.. | **2026-04-17** | 2026-04-30 | Concluído | entregue |
| 3365 | IAF-116 | Otimizações e correções de segurança em Camp.. | **2026-04-17** | 2026-04-17 | Concluído | entregue |
| 3366 | IAF-117 | Refatorar bistrix de cobrança 4.0 | **2026-04-20** | 2026-04-30 | Concluído | entregue |
| 3367 | IAF-118 | [Bitrix ID-1775] Inclusão da organização Fin.. | **2026-04-20** | — | BLOQUEADO | bloqueado |
| 3368 | IAF-119 | [Bitrix ID-1779] Novo campo Torre de Controle | **2026-04-20** | 2026-04-22 | Concluído | entregue |
| 3369 | IAF-120 | [Bitrix ID-1785] Adicionar novo campo Torre .. | **2026-04-22** | 2026-04-23 | Concluído | entregue |
| 3370 | IAF-121 | Ajustar regras de transferencia do cobrança | **2026-04-22** | 2026-05-11 | Concluído | entregue |
| 3371 | IAF-122 | [Bitrix ID-1789] Retirar avisos de cobrança. | **2026-04-22** | 2026-05-08 | Concluído | entregue |
| 3372 | IAF-122 | [Bitrix ID-1789] Retirar avisos de cobrança. | **2026-04-22** | 2026-05-08 | Concluído | validacao |
| 3373 | IAF-125 | Separação de Ambiente Produção/Dev | **2026-04-22** | 2026-05-08 | Concluído | entregue |
| 3374 | IAF-128 | [Bitrix ID-1805] Finalizar as Cobranças do C.. | **2026-04-24** | 2026-04-28 | Concluído | entregue |
| 3375 | IAF-129 | [Bitrix ID-1807] Status Cancelamento - Em an.. | **2026-04-24** | — | VALIDAÇÃO | validacao |
| 3376 | IAF-130 | Roadmap 7 Agentes IA Finza (Reunião 22/abr/2.. | **2026-04-27** | — | EM ANDAMENTO | em-curso |
| 3377 | IAF-131 | [Sprint 0] Valentina live no número da Finza.. | **2026-04-27** | 2026-05-04 | Concluído | entregue |
| 3378 | IAF-132 | [Sprint 0] Trocar automação Hyper: Onboardin.. | **2026-04-27** | — | Backlog | entregue |
| 3379 | IAF-133 | [Sprint 0] FAQ inicial Valentina + onboardin.. | **2026-04-27** | 2026-05-04 | Concluído | entregue |
| 3380 | IAF-134 | [Sprint 0] Migrar fluxo de trabalho Torre pa.. | **2026-04-27** | — | EM ANDAMENTO | entregue |
| 3381 | IAF-136 | [Sprint 1] Clara multi-org STIA (Finza + Bli.. | **2026-04-27** | — | EM ANDAMENTO | bloqueado |
| 3382 | IAF-137 | [Sprint 1] Francisco — deploy final + difere.. | **2026-04-27** | 2026-05-11 | Concluído | entregue |
| 3383 | IAF-138 | [Sprint 1] Agendas de escopo: Distrato + Ret.. | **2026-04-27** | — | Backlog | cancelado |
| 3384 | IAF-139 | [Sprint 1] Spec técnica Torre 2.0: Prompts a.. | **2026-04-27** | — | Priorizado | entregue |
| 3385 | IAF-140 | Documentar fluxo branches/PR/deploy dev/depl.. | **2026-04-27** | — | EM DESENVOLVIMENTO | validacao |
| 3386 | IAF-145 | [Sprint 2] Torre 2.0: Modelagem fase/filtro/.. | **2026-04-27** | — | Backlog | cancelado |
| 3387 | IAF-146 | [Sprint 2] Torre 2.0: Backend — troca de pro.. | **2026-04-27** | — | Backlog | cancelado |
| 3388 | IAF-147 | [Sprint 2] Torre 2.0: UI gestão visual de pr.. | **2026-04-27** | — | Backlog | cancelado |
| 3389 | IAF-148 | [Sprint 2] Torre 2.0: Validação E2E — migrar.. | **2026-04-27** | — | Backlog | cancelado |
| 3390 | IAF-149 | [Sprint 2] Integração Clara ↔ sistema novo F.. | **2026-04-27** | — | Backlog | cancelado |
| 3391 | IAF-150 | [Sprint 3] Evaluation Torre: criação de cená.. | **2026-04-27** | — | Backlog | cancelado |
| 3392 | IAF-151 | [Sprint 3] Evaluation Torre: engine de execu.. | **2026-04-27** | — | Backlog | cancelado |
| 3393 | IAF-152 | [Sprint 3] Versionamento de prompts (staging.. | **2026-04-27** | — | Backlog | cancelado |
| 3394 | IAF-153 | [Sprint 3] Conteúdo Distrato: prompt + integ.. | **2026-04-27** | — | Backlog | cancelado |
| 3395 | IAF-154 | [Sprint 3] Funcionalidade reembolso na Clara.. | **2026-04-27** | — | Backlog | cancelado |
| 3396 | IAF-155 | [Sprint 4] Conteúdo Retirada de Equipamentos.. | **2026-04-27** | — | Backlog | bloqueado |
| 3397 | IAF-156 | [Sprint 4] Esteiras sequenciais Torre: cobra.. | **2026-04-27** | — | Backlog | cancelado |
| 3398 | IAF-157 | [Sprint 4] Validação completa via Evaluation.. | **2026-04-27** | — | Backlog | cancelado |
| 3399 | IAF-158 | [Sprint 5] Dashboards dos 7 agentes (recuper.. | **2026-04-27** | — | Backlog | cancelado |
| 3400 | IAF-159 | [Sprint 5] Valentina avançada: orquestração .. | **2026-04-27** | — | Backlog | cancelado |
| 3401 | IAF-160 | [Sprint 5] Playbook curadoria autônoma (STIA.. | **2026-04-27** | — | Backlog | cancelado |
| 3402 | IAF-161 | [Sprint 5] Retrospectiva + plano de evolução.. | **2026-04-27** | — | Backlog | cancelado |
| 3403 | IAF-162 | Distrato — Integração Intel Post (cotação lo.. | **2026-04-27** | — | Tarefas pendentes | em-curso |
| 3404 | IAF-163 | Distrato — Cálculo automático de valores con.. | **2026-04-27** | — | Tarefas pendentes | em-curso |
| 3405 | IAF-164 | Distrato — Geração automática de termo de di.. | **2026-04-27** | — | Tarefas pendentes | em-curso |
| 3406 | IAF-165 | Retirada — Integração Intel Coast + contato .. | **2026-04-27** | — | Tarefas pendentes | refinado |
| 3407 | IAF-166 | Retirada — Fluxo de agendamento com cliente .. | **2026-04-27** | — | Tarefas pendentes | bloqueado |
| 3408 | IAF-167 | Retirada — Abertura automática de OS | **2026-04-27** | — | Tarefas pendentes | cancelado |
| 3409 | IAF-168 | [Bitrix ID-1815] Automação da raia KIT AJUIZ.. | **2026-04-27** | — | VALIDAÇÃO | entregue |
| 3410 | IAF-169 | [Bitrix ID-1817] IA LÍVIA - MELHORIA | **2026-04-27** | — | EM ANDAMENTO | em-curso |
| 3411 | IAF-171 | Torre de Controle: identificar org via x-api.. | **2026-04-29** | — | VALIDAÇÃO | em-curso |
| 3412 | IAF-172 | Criação de vídeo/documentação do processo de.. | **2026-04-30** | 2026-05-11 | Concluído | entregue |
| 3413 | IAF-173 | Problemas agente de transferência Finza | **2026-04-30** | 2026-05-11 | Concluído | entregue |
| 3414 | IAF-174 | Ajustar fluxo formalização dev para enviar m.. | **2026-04-30** | 2026-05-11 | Concluído | entregue |
| 3415 | IAF-176 | [Bitrix ID-1839] Inclusão da carteira Rhino .. | **2026-05-07** | — | EM ANDAMENTO | em-curso |
| 3416 | IAF-177 | [Bitrix ID-1847] Livia não está respondendo | **2026-05-08** | 2026-05-08 | Concluído | entregue |
| 3417 | IAF-178 | Subir para produção o novo fluxo de formaliz.. | **2026-05-08** | 2026-05-11 | Concluído | entregue |
| 3418 | IAF-181 | [Bitrix ID-1853] Negativação Indevida Finza .. | **2026-05-08** | — | Backlog | refinado |
| 3419 | IAF-182 | Resolver bug de visualização de contatos dos.. | **2026-05-11** | — | VALIDAÇÃO | validacao |
| 3420 | IAF-183 | [Bitrix ID-1859] Cobrança Indevida | **2026-05-11** | 2026-05-13 | Concluído | entregue |
| 3421 | IAF-184 | Refatorar CLUADE.MD e SKILLS da torre e limp.. | **2026-05-11** | — | EM ANDAMENTO | validacao |
| 3422 | IAF-185 | [Bitrix ID-1863] Adicionar email alternativo.. | **2026-05-11** | 2026-05-13 | Concluído | entregue |
| 3423 | IAF-186 | [Bitrix ID-1865] Correção e atualização do G.. | **2026-05-11** | — | EM ANDAMENTO | entregue |
| 3424 | IAF-187 | [Bitrix ID-1869] Blocklist Torre de Controle | **2026-05-11** | — | Backlog | validacao |
| 3425 | IAF-188 | [Bitrix ID-1871] Status de contrato platafor.. | **2026-05-11** | — | Priorizado | entregue |
| 3426 | IAF-189 | MCP não exibe boletos a vencer — visibilidad.. | **2026-05-11** | — | Backlog | entregue |
| 3427 | IAF-192 | Corrigir GIT para que ele não apague as bran.. | **2026-05-12** | 2026-05-13 | Concluído | entregue |
| 3428 | IAF-194 | Configurar nova branch de dev e dev legacy | **2026-05-12** | 2026-05-13 | Concluído | entregue |
| 3429 | IAF-196 | Rodar uma vez a view materializada enquanto .. | **2026-05-14** | 2026-05-14 | Concluído | entregue |
| 3430 | IAF-198 | Estudar e projetar estrutura nova de deploy .. | **2026-05-14** | — | Backlog | em-curso |
| 3431 | IAF-200 | Ajustar o fluxo para que os testes sejam fei.. | **2026-05-14** | — | Backlog | cancelado |
| 3432 | IAF-203 | [Bitrix ID-1899] Acesso ao Hyper | **2026-05-18** | 2026-05-19 | Concluído | entregue |
| 3433 | IAF-204 | [Bitrix ID-1901] Novo template | **2026-05-18** | — | VALIDAÇÃO | entregue |
| 3434 | IAF-205 | [Bitrix ID-1903] Cliente Inadimplente sem Card | **2026-05-18** | — | Backlog | entregue |
| 3435 | IAF-206 | [Bitrix ID-1909] Mensagem de cobrança indevida | **2026-05-19** | 2026-05-19 | Concluído | entregue |
| 3436 | IAF-207 | Investigação do deploy | **2026-05-19** | — | EM ANDAMENTO | entregue |

## ⚠️ Casos a confirmar

**IAF-122 → 2 tickets (QMR3371, QMR3372).** Ambos recebem o mesmo `created`/`resolved`. Confirmar se foi desdobramento intencional.

**Divergência de estado (.md = entregue, Jira sem data de conclusão):** 13 casos. O created_at é corrigido normalmente; sem esolved no Jira não há finalização a fazer backfill.

| Quimera | Jira | status Jira | título |
|---|---|---|---|
| 3295 | IAF-19 | EM ANDAMENTO | Acompanhamento dos atendimentos hypeflow e u.. |
| 3335 | IAF-77 | Backlog | [Bitrix ID-1673] Ajustes no Bitrix de Distra.. |
| 3357 | IAF-103 | VALIDAÇÃO | [Bitrix ID-1747] Criação de templates e dema.. |
| 3378 | IAF-132 | Backlog | [Sprint 0] Trocar automação Hyper: Onboardin.. |
| 3380 | IAF-134 | EM ANDAMENTO | [Sprint 0] Migrar fluxo de trabalho Torre pa.. |
| 3384 | IAF-139 | Priorizado | [Sprint 1] Spec técnica Torre 2.0: Prompts a.. |
| 3409 | IAF-168 | VALIDAÇÃO | [Bitrix ID-1815] Automação da raia KIT AJUIZ.. |
| 3423 | IAF-186 | EM ANDAMENTO | [Bitrix ID-1865] Correção e atualização do G.. |
| 3425 | IAF-188 | Priorizado | [Bitrix ID-1871] Status de contrato platafor.. |
| 3426 | IAF-189 | Backlog | MCP não exibe boletos a vencer — visibilidad.. |
| 3433 | IAF-204 | VALIDAÇÃO | [Bitrix ID-1901] Novo template |
| 3434 | IAF-205 | Backlog | [Bitrix ID-1903] Cliente Inadimplente sem Card |
| 3436 | IAF-207 | EM ANDAMENTO | Investigação do deploy |

## Spec de backfill de `status_history` (para o dev/DBA do Quimera)

O MCP não reescreve histórico. Para restaurar Cycle/Lead Time reais, ajustar no banco, por ticket, os timestamps abaixo (origem: Jira, ISO-8601). Tickets sem `resolved` ainda não foram concluídos no Jira.

Tickets com data de conclusão real: **72**.

| Quimera | Jira | created_at (ISO) | finalizado_at (ISO) |
|---|---|---|---|
| 3288 | IAF-12 | 2026-03-18T08:33:48.852-0400 | 2026-04-07T08:50:19.551-0400 |
| 3289 | IAF-13 | 2026-03-18T08:33:50.686-0400 | 2026-04-07T08:48:05.886-0400 |
| 3290 | IAF-14 | 2026-03-18T08:33:52.396-0400 | 2026-04-07T08:47:45.706-0400 |
| 3291 | IAF-15 | 2026-03-18T08:33:53.786-0400 | 2026-05-07T16:22:26.842-0400 |
| 3292 | IAF-16 | 2026-03-18T08:33:56.701-0400 | 2026-04-30T12:54:33.856-0400 |
| 3294 | IAF-18 | 2026-03-18T08:33:59.739-0400 | 2026-04-07T08:48:50.111-0400 |
| 3296 | IAF-20 | 2026-03-18T08:34:02.630-0400 | 2026-04-07T08:47:56.818-0400 |
| 3297 | IAF-22 | 2026-03-18T08:34:06.010-0400 | 2026-04-06T08:28:20.195-0400 |
| 3298 | IAF-23 | 2026-03-18T08:34:07.424-0400 | 2026-05-08T13:03:56.613-0400 |
| 3299 | IAF-24 | 2026-03-18T08:34:09.545-0400 | 2026-04-07T08:49:10.946-0400 |
| 3300 | IAF-25 | 2026-03-18T08:34:10.959-0400 | 2026-04-07T08:47:59.040-0400 |
| 3301 | IAF-26 | 2026-03-18T08:34:12.352-0400 | 2026-04-07T08:48:09.069-0400 |
| 3302 | IAF-28 | 2026-03-18T08:41:56.906-0400 | 2026-04-14T08:52:30.133-0400 |
| 3303 | IAF-29 | 2026-03-18T08:41:59.004-0400 | 2026-04-14T08:51:57.425-0400 |
| 3305 | IAF-31 | 2026-03-18T11:01:53.680-0400 | 2026-04-02T14:53:46.050-0400 |
| 3306 | IAF-36 | 2026-03-19T08:07:00.158-0400 | 2026-04-10T08:50:24.947-0400 |
| 3329 | IAF-71 | 2026-04-07T08:19:04.421-0400 | 2026-04-08T12:57:30.980-0400 |
| 3330 | IAF-72 | 2026-04-07T08:19:04.708-0400 | 2026-04-08T23:24:44.115-0400 |
| 3331 | IAF-73 | 2026-04-07T08:19:05.307-0400 | 2026-04-15T08:56:20.337-0400 |
| 3332 | IAF-74 | 2026-04-07T08:19:05.376-0400 | 2026-04-07T18:43:31.232-0400 |
| 3333 | IAF-75 | 2026-04-07T08:49:43.699-0400 | 2026-04-10T18:13:10.640-0400 |
| 3334 | IAF-76 | 2026-04-07T08:51:11.365-0400 | 2026-04-14T08:52:45.633-0400 |
| 3336 | IAF-78 | 2026-04-07T14:26:05.345-0400 | 2026-05-15T09:43:41.185-0400 |
| 3337 | IAF-79 | 2026-04-07T14:34:32.287-0400 | 2026-04-07T14:34:32.905-0400 |
| 3339 | IAF-82 | 2026-04-09T08:45:17.689-0400 | 2026-04-30T12:54:15.746-0400 |
| 3340 | IAF-83 | 2026-04-09T09:00:18.399-0400 | 2026-04-09T15:59:36.108-0400 |
| 3341 | IAF-84 | 2026-04-09T09:15:00.521-0400 | 2026-04-13T08:33:58.004-0400 |
| 3342 | IAF-85 | 2026-04-09T09:15:50.368-0400 | 2026-04-14T08:49:49.530-0400 |
| 3343 | IAF-86 | 2026-04-09T09:16:02.617-0400 | 2026-04-13T08:34:07.008-0400 |
| 3344 | IAF-89 | 2026-04-09T13:16:02.257-0400 | 2026-04-13T08:27:49.726-0400 |
| 3345 | IAF-90 | 2026-04-09T13:25:48.143-0400 | 2026-04-13T08:27:57.425-0400 |
| 3346 | IAF-91 | 2026-04-09T13:26:18.930-0400 | 2026-04-28T10:57:33.206-0400 |
| 3347 | IAF-92 | 2026-04-09T13:36:22.991-0400 | 2026-04-10T14:18:40.023-0400 |
| 3348 | IAF-93 | 2026-04-09T16:22:13.856-0400 | 2026-04-15T13:17:20.314-0400 |
| 3349 | IAF-94 | 2026-04-10T07:23:55.046-0400 | 2026-04-16T09:16:07.968-0400 |
| 3350 | IAF-95 | 2026-04-10T08:54:12.474-0400 | 2026-05-04T09:43:32.902-0400 |
| 3351 | IAF-96 | 2026-04-10T10:30:07.931-0400 | 2026-05-15T09:43:39.427-0400 |
| 3352 | IAF-97 | 2026-04-13T08:33:39.034-0400 | 2026-04-13T08:34:11.640-0400 |
| 3353 | IAF-98 | 2026-04-13T08:46:42.869-0400 | 2026-04-15T08:56:59.686-0400 |
| 3354 | IAF-99 | 2026-04-13T09:12:49.747-0400 | 2026-04-22T08:41:52.109-0400 |
| 3355 | IAF-101 | 2026-04-14T08:50:11.833-0400 | 2026-04-17T08:18:35.874-0400 |
| 3356 | IAF-102 | 2026-04-14T08:50:56.657-0400 | 2026-04-30T12:34:46.714-0400 |
| 3359 | IAF-110 | 2026-04-16T09:12:02.212-0400 | 2026-04-27T15:44:18.817-0400 |
| 3360 | IAF-111 | 2026-04-16T14:49:03.432-0400 | 2026-04-24T10:19:21.086-0400 |
| 3361 | IAF-112 | 2026-04-16T15:14:50.216-0400 | 2026-04-17T08:18:19.203-0400 |
| 3362 | IAF-113 | 2026-04-16T15:45:37.301-0400 | 2026-04-22T08:42:58.463-0400 |
| 3363 | IAF-114 | 2026-04-14T22:16:11.137-0400 | 2026-04-22T08:41:02.699-0400 |
| 3364 | IAF-115 | 2026-04-17T14:17:11.068-0400 | 2026-04-30T12:57:03.428-0400 |
| 3365 | IAF-116 | 2026-04-17T15:31:44.213-0400 | 2026-04-17T15:39:48.237-0400 |
| 3366 | IAF-117 | 2026-04-20T07:35:48.939-0400 | 2026-04-30T12:59:57.816-0400 |
| 3368 | IAF-119 | 2026-04-20T16:44:44.348-0400 | 2026-04-22T20:53:40.890-0400 |
| 3369 | IAF-120 | 2026-04-22T09:35:16.534-0400 | 2026-04-23T21:04:22.157-0400 |
| 3370 | IAF-121 | 2026-04-22T13:25:38.532-0400 | 2026-05-11T10:25:10.378-0400 |
| 3371 | IAF-122 | 2026-04-22T14:56:24.104-0400 | 2026-05-08T12:27:22.105-0400 |
| 3372 | IAF-122 | 2026-04-22T14:56:24.104-0400 | 2026-05-08T12:27:22.105-0400 |
| 3373 | IAF-125 | 2026-04-22T16:19:52.916-0400 | 2026-05-08T12:49:45.482-0400 |
| 3374 | IAF-128 | 2026-04-24T11:17:50.543-0400 | 2026-04-28T09:58:31.758-0400 |
| 3377 | IAF-131 | 2026-04-27T08:16:08.557-0400 | 2026-05-04T09:43:24.991-0400 |
| 3379 | IAF-133 | 2026-04-27T08:16:22.030-0400 | 2026-05-04T07:23:38.829-0400 |
| 3382 | IAF-137 | 2026-04-27T08:16:54.825-0400 | 2026-05-11T07:56:35.440-0400 |
| 3412 | IAF-172 | 2026-04-30T12:37:10.636-0400 | 2026-05-11T14:02:47.929-0400 |
| 3413 | IAF-173 | 2026-04-30T12:56:45.386-0400 | 2026-05-11T10:25:15.534-0400 |
| 3414 | IAF-174 | 2026-04-30T12:58:17.160-0400 | 2026-05-11T10:25:25.307-0400 |
| 3416 | IAF-177 | 2026-05-08T10:52:33.986-0400 | 2026-05-08T16:09:48.549-0400 |
| 3417 | IAF-178 | 2026-05-08T12:47:32.844-0400 | 2026-05-11T10:25:27.622-0400 |
| 3420 | IAF-183 | 2026-05-11T09:23:55.522-0400 | 2026-05-13T10:41:56.932-0400 |
| 3422 | IAF-185 | 2026-05-11T10:48:27.696-0400 | 2026-05-13T12:22:01.893-0400 |
| 3427 | IAF-192 | 2026-05-12T14:15:46.419-0400 | 2026-05-13T12:56:06.616-0400 |
| 3428 | IAF-194 | 2026-05-12T14:17:34.151-0400 | 2026-05-13T12:56:12.212-0400 |
| 3429 | IAF-196 | 2026-05-14T12:34:52.408-0400 | 2026-05-14T12:34:57.220-0400 |
| 3432 | IAF-203 | 2026-05-18T15:48:41.809-0400 | 2026-05-19T13:47:08.917-0400 |
| 3435 | IAF-206 | 2026-05-19T09:10:45.147-0400 | 2026-05-19T14:16:20.052-0400 |

## Próximos passos (gate)

1. ~~**Habilitar o MCP `quimera`**~~ — ✅ conectado em 2026-06-04.
2. ~~Ler `created_at` atual~~ — ✅ confirmado = timestamp do import (`2026-05-20T15:09`, não 26/05 como estimado).
3. ~~**Aprovação humana**~~ — ✅ João Vinícius autorizou (aplicar os 130 de uma vez).
4. ~~Aplicar `update_ticket(created_at)` em lote~~ — ✅ **130/130 gravados** em 2026-06-04. Flag global `mcp_allow_edit_created_at` estava ligada. Amostra verificada (3287/3338/3372/3436): `created_at` real gravado; `resolved_at` e `status_changed_at` preservados.
5. ⏳ **Parte B (Cycle/Lead Time) — PENDENTE no banco.** `update_ticket` grava só `created_at`; finalização/histórico exige o SQL em `Relatorio/2026-06-04_backfill-datas-quimera.sql` (DBA).

## Resultado da aplicação (2026-06-04)

- **130/130** tickets com `created_at` corrigido via MCP `update_ticket`. Nenhum erro de escrita.
- **Verificação por amostra (UTC gravado):** 3287 → `2026-03-06T23:27:40` (19:27 -04); 3338 → `2025-11-14T18:50:23` (outlier nov/2025); 3372 → `2026-04-22T18:56:24`; 3436 → `2026-05-19T16:49:54`. Todos batem com o Jira.
- **Efeitos colaterais nulos:** `resolved_at` intacto (3288 seguia correto = 2026-04-07), `status_changed_at` não tocado, nenhum e-mail/notificação disparado (só metadata).

### ⚠️ Caveats descobertos na aplicação

- **3372 é IAF-123, não IAF-122.** Ao reler o ticket 3372, a descrição é `[IAF-123] [Bitrix ID-1791]` ("Retirar avisos de cobrança", contrato 12602742) — demanda gêmea de IAF-122 (Bitrix 1789), mesma data 2026-04-22. O `created_at` aplicado (22/04 14:56, de IAF-122) está certo em nível de **data/dia**; o segundo exato pode divergir do IAF-123 real. Sem impacto em KPI (mesmo dia). Revisar o mapa `fonte: quimera+jira` no `.md` de origem para corrigir 3372→IAF-123.
- **`get_gestao_overview` (last_month/last_quarter) quebrando pós-correção.** Com os 130 tickets agora distribuídos em mar–mai, a sub-query de Cycle Time monta um `IN(...)` de centenas de `ticket_id` em `ticket_status_history` que estoura o tamanho de URL/HTTP2 do endpoint Supabase (`stream error / unspecific protocol error`). É **limitação do endpoint do Quimera** (precisa paginar/chunkar o `IN`), exposta pelo aumento de volume na janela. `current_month` (junho) segue funcionando. Reportar ao time do Quimera.
