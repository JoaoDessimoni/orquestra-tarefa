---
title: Report consolidado das 10 demandas do anexo
data: 2026-05-18
destinatario: <a confirmar — time de negócio que enviou a cobrança>
analise-fonte: Gestao/Analises/18-05-2026/2026-05-18_demandas-cobranca-time-negocio.md
owner: João Vinícius
status: rascunho
classificacao: interno
janela: tickets 1699..1871
tags: [demandas, cobranca, time-negocio]
---

# Report consolidado das 10 demandas do anexo

**Para:** <a confirmar — time de negócio>
**De:** João Vinícius — Supervisor IAF
**Data:** 18 de maio de 2026
**Classificação:** interno

## Sumário executivo

Das 10 demandas cobradas, **8 são do squad IAF**. Dessas: **3 concluídas** (2 aguardando validação), **2 em andamento**, **1 em validação aguardando decisão de processo**, **2 bloqueadas** (1 por prioridade interna da Torre, 1 por dependência externa do HyperFlow). As outras **2 demandas (1821 e 1699) não pertencem ao squad IAF** — foram cobradas indevidamente.

## Status por demanda

| # | Ticket | Descrição (anexo) | Status | Prazo | Responsável | Escopo |
|---|--------|---|--------|------|-------------|--------|
| 1 | **1871** | Status de contrato em questão plataforma — Torre de Controle | Concluída | 15/05/2026 (entregue) | João Lucas | IAF |
| 2 | **1869** | Blocklist Torre de Controle (extensão com novas características) | Bloqueada | aguarda desbloqueio da Torre | Marcos | IAF |
| 3 | **1865** | Correção e atualização do gatilho de buscar títulos no Sankhya (executa no Hyper) | Em curso | 22/05/2026 | João Pedro | IAF |
| 4 | **1821** | Top's 270 e 271 (cancelada por Mateus) | Cancelada | — | — | **Fora do IAF** |
| 5 | **1807** | Status de cancelamento — Em análise judicial \| Plataforma | Em validação | 22/05/2026 | Marcos | IAF |
| 6 | **1785** | Adicionar novo campo na Torre de Controle | Concluída | 22/05/2026 (validação final) | Marcos | IAF |
| 7 | **1779** | Novo campo na Torre de Controle | Concluída | 22/05/2026 (validação final) | Marcos | IAF |
| 8 | **1775** | Inclusão da organização Finza no AuditorIA (depende de acesso ao HyperFlow) | Não iniciada | aguarda conversa HyperFlow | Vinícius Cunha + Dados | IAF (dep. externa) |
| 9 | **1747** | Criação de templates e demais configurações — Corporativo Hyper | Finalizando testes | 22/05/2026 | Leandro Marques | IAF |
| 10 | **1699** | Funil/Esteira Retirada (do time de Dados) | Não é IAF | — | Time de Dados | **Fora do IAF** |

## Bloqueios

- **1869** — bloqueada por prioridades internas da Torre. Marcos tem implementação parcial em branch; segue esperando finalizar o priorizado para retomar.
- **1775** — não iniciada por dependência externa: o HyperFlow (empresa de atendimentos) precisa liberar acesso direto às bases. Hoje o IAF consome via base fornecida indiretamente. Conversa pendente entre Vinícius Cunha + time de Dados ↔ HyperFlow.
- **1807** (e demais em validação com Marcos) — bloqueio de processo: definir raia de board para tickets em validação que são features/fixes da Torre.

## Demandas fora do escopo IAF

Duas demandas no anexo **não pertencem ao squad IAF** e foram incluídas indevidamente na cobrança:

- **1821 — Top's 270 e 271**: consulta no gatilho do Hyper (sem possibilidade de alteração nesse caminho). Cancelada por Mateus Alberone Mesquita.
- **1699 — Funil/Esteira Retirada**: pertence ao time de Dados.

Sugestão: o time de negócio remova essas duas da cobrança ao IAF. Para 1699, direcionar ao time de Dados para confirmação de fechamento, se relevante.

## Divergências internas detectadas (lado IAF)

Durante o cruzamento dos relatos do squad com o título oficial do board, identifiquei pontos que precisam de confirmação interna **antes** de devolver o report final ao time de negócio:

- **1747** — título oficial é "Criação de templates e demais configurações \| Coorporativo Hyper", mas o Tech Lead descreveu como "gatilho de encerrar atendimento". Vou confirmar com Leandro qual é o ticket dele de fato — se a divergência for confirmada, o report ao time de negócio será ajustado.
- **1821** — título "Top's 270 e 271" não dá pista do conteúdo descrito pelo Tech Lead ("consulta do Shankya"). Vou confirmar com Mateus o conteúdo real antes de fechar a posição de "cancelada".
- **1871** — concluída em 15/05/2026 conforme Tech Lead, mas o board ainda mostra etapa "Demanda internalizada". Pedi atualização do status no board.

## Pendências geradas (lado do supervisor IAF)

<!-- Cada uma será criada via /pendencia add -->
- Confirmar com Leandro qual é o ticket real do 1747 (anexo cita "templates Corporativo Hyper", relato cita "gatilho de encerrar atendimento").
- Confirmar com Mateus o conteúdo de "Top's 270 e 271" (1821).
- Falar com Vinícius Cunha sobre 1775 (destravar HyperFlow / AuditorIA).
- Validar 1785 com Marcos (novo campo Torre).
- Validar 1779 com Marcos (novo campo Torre).
- Atualizar status do 1871 no board (de "Demanda internalizada" para "Concluída").
- Decidir com Marcos a raia das demandas em validação (1807 +).

## Próximos checkpoints

- **20/05/2026** — devolutiva sobre 1785 e 1779 após validação com Marcos.
- **22/05/2026** — devolutiva sobre 1775 após conversa com Vinícius Cunha, e sobre a decisão de raia (1807).
- **Semana de 25/05/2026** — atualização sobre 1869 caso a Torre destrave prioridade.

## Notas

- Este report é resultado do cruzamento entre o pedido feito ao squad em 15/05/2026, as respostas do Tech Lead João Lucas Freitas e do dev Marcos Rodrigues, e o título oficial dos tickets no board Jira (anexo recebido em 18/05/2026).
- Descrições da tabela usam o **título oficial do anexo** como fonte primária (revisado em 18/05/2026 após double-check).
- Confirmações diretas: **Leandro Marques** confirmou que está finalizando os testes de 1747 — pendente confirmação se o ticket dele é mesmo o 1747 (vide divergências internas). **Marcos** confirmou que 1785 e 1779 estão concluídos de fato.
- Pendente do supervisor: conversa com **Vinícius Cunha** sobre 1775; alinhamento com Leandro sobre 1747; alinhamento com Mateus sobre 1821.
- Inconsistência menor: relato do João Lucas escreveu "quarta dia 15" para o 1871 (15/05 foi sexta). Não afeta o status; vale confirmar a data se for relevante para o time de negócio.
- Etapas no board (anexo): 1871 e 1699 estão como "Demanda internalizada"; 1869 e 1821 como "Backlog"; 1865, 1785, 1779, 1747 como "Em Andamento"; 1807 como "Em Validação"; 1775 como "Bloqueado".
