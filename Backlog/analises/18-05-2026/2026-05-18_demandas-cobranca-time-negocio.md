---
title: Cruzamento das demandas do anexo com respostas do time IAF
data: 2026-05-18
autor: João Vinícius
tipo: cruzamento
fontes-consultadas:
  - "Imagem anexa enviada pelo time de negócio — 10 tickets do board Jira"
  - "Mensagem João Lucas Freitas (Tech Lead) — 2026-05-15"
  - "Mensagem Marcos Rodrigues (dev IAF) — 2026-05-15"
relacionadas: []
status: publicada
solicitante: joao.martins@blips.com.br
tags: [demandas, cobranca, time-negocio, jira]
---

# Cruzamento demandas cobrança × IAF (2026-05-18)

**Pergunta:** Qual o status real das 10 demandas cobradas, com previsão honesta e separação de escopo?

## Resultado consolidado

| Ticket | Título (oficial) | Status real | Responsável | Escopo |
|---|---|---|---|---|
| 1871 | Status de contrato em questão plataforma — Torre | Concluída (2026-05-15) | João Lucas | IAF |
| 1869 | Blocklist Torre de Controle | Bloqueada (aguarda Torre) | Marcos | IAF |
| 1865 | Correção/atualização do gatilho buscar títulos Sankhya | Em curso (início 2026-05-13) | João Pedro | IAF |
| **1821** | Top's 270 e 271 | **Cancelada** | Mateus Alberone | **Fora do IAF** |
| 1807 | Status Cancelamento — Em análise judicial \| Plataforma | Em validação | Marcos | IAF |
| 1785 | Adicionar novo campo Torre de Controle | Concluída (validação pendente) | Marcos | IAF |
| 1779 | Novo campo Torre de Controle | Concluída (validação pendente) | Marcos | IAF |
| 1775 | Inclusão da org Finza no AuditorIA | Não iniciada (bloqueio externo HyperFlow) | Vinícius Cunha + Dados | IAF (dep. externa) |
| 1747 | Templates e configurações \| Corporativo Hyper | Finalizando testes | Leandro Marques | IAF |
| **1699** | Funil/Esteira Retirada | **Não é IAF** (time de Dados) | Time de Dados | **Fora do IAF** |

**Síntese:** 8 são IAF · 3 concluídas (1785/1779 validação pendente) · 2 em andamento · 1 em validação · 1 bloqueada prioridade interna · 1 bloqueada dependência externa. **2 fora do escopo** (1821, 1699).

## Divergências a confirmar

| Ticket | Divergência | Criticidade |
|---|---|---|
| **1747** | João Lucas relatou "gatilho de encerrar atendimento"; título oficial é "templates Corporativo Hyper" | Crítica — confirmar com Leandro |
| **1821** | João Lucas: "consulta Shankya"; título: "Top's 270 e 271" | Média — confirmar com Mateus |
| **1871** | João Lucas: "quarta dia 15"; 15/05 foi sexta | Baixa — não afeta status |

## Ações para o supervisor

- [ ] Confirmar com Leandro qual é o ticket real do 1747 — deadline: 2026-05-21
- [ ] Confirmar com Mateus o conteúdo de "Top's 270 e 271" (1821) — deadline: 2026-05-22
- [ ] Falar com Vinícius Cunha sobre 1775 (destravar HyperFlow) — deadline: 2026-05-22
- [ ] Validar 1785 e 1779 com Marcos — deadline: 2026-05-22
- [ ] Decidir com Marcos a raia das demandas em validação (1807) — deadline: 2026-05-22
- [ ] Atualizar status 1871 no board (ainda "Demanda internalizada") — owner: João Lucas

## Notas

- Relatório de devolução ao time de negócio em `relatorios/2026-05-18_relatorio-demandas-cobranca.md`.
- "Raia" = coluna do board Kanban. Marcos pediu orientação sobre onde mover tickets em validação.
- HyperFlow e Hyper = mesma plataforma. Sankhya e "Shankya" = mesmo ERP.
