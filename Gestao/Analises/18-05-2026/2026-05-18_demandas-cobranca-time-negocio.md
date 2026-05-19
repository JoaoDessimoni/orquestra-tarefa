---
title: Cruzamento das demandas do anexo com respostas do time IAF
data: 2026-05-18
autor: João Vinícius
tipo: cruzamento
fontes-consultadas:
  - "Imagem anexa enviada pelo time de negócio (lista de 10 tickets) — descrições oficiais do board Jira"
  - "Mensagem João Lucas Freitas (Tech Lead) — 15/05/2026"
  - "Mensagem Marcos Rodrigues (dev IAF) — 15/05/2026"
  - "Anexo do board Jira recebido 18/05/2026 — titulos oficiais dos tickets (revisão pós double-check)"
relacionadas: []
status: rascunho
tags: [demandas, cobranca, time-negocio, jira]
---

# Cruzamento das demandas do anexo com respostas do time IAF

**Data:** 18 de maio de 2026
**Autor:** João Vinícius
**Tipo:** cruzamento

## Contexto

Na sexta 15/05/2026, o time de negócio enviou ao supervisor IAF uma imagem com 10 tickets (1871, 1869, 1865, 1821, 1807, 1785, 1779, 1775, 1747, 1699) cobrando um report consolidado de status.

No mesmo dia, o supervisor pediu ao squad IAF que respondesse para cada demanda:
- Data de início;
- Previsão honesta de conclusão;
- Status resumido com andamento;
- Marcar quando concluída (incluindo o que faltou de homologação — porque já houve casos de demanda fechada sem aviso).

As respostas vieram de João Lucas Freitas (Tech Lead) e Marcos Rodrigues (dev IAF). Esta análise cruza o pedido original com as respostas e separa o que é IAF do que não é, para preparar o relatório de devolução ao time de negócio.

## Pergunta de investigação

Qual o status real de cada uma das 10 demandas, com previsão honesta, responsável correto e separação entre escopo IAF e fora-do-escopo?

## Dados / Insumos

### Pedido original do supervisor ao squad (15/05/2026)

> "pessoal, me ajudem nisso aqui por favor? eu preciso de saber isso sobre essas demandas no anexo:
> Data que foi iniciada, Previsão honesta sobre conclusão, Atualização dos status resumindo os andamentos da demanda, Informar quando ela for concluida (teve demandas que foram finalizadas que não sei quando porque apenas foi finalizada e depois quando eu lembro dela e vou utilizar vejo que faltou alguns pontos de homologação etc)"

### Resposta João Lucas Freitas — Tech Lead

| Ticket | Resposta verbatim (resumida) |
|---|---|
| 1871 | "Iniciada e terminada na quarta feira dia 15. é aquela de colocar os campos de status e fase da plataforma" |
| 1869 | "Demanda meio que duplicada... Marcos já tinha feito algumas coisas do blocklist e aqui adicionou mais. Foi iniciada antes, mas agora está bloqueada pelas coisas de mais prioridade da torre. Quando iniciada, demora um dia só pra fazer, aí um dia pra testar e dar deploy depois." |
| 1865 | "Demanda que o João Pedro tá fazendo do gatilho no hyper. Agora que ele já entendeu a base, se priorizado demora um dia pra fazer, mas depois precisamos que teste com o J antes de marcar para concluído. Não tem a ver com a torre. Começou dia 13/05" |
| 1821 | "Cancelada. Não é uma demanda nossa. É uma coisa de consulta do shankya, no gatilho do hyper que o João Pedro tá mexendo não tem nem como mudar isso. O Mateus cancelou ela." |
| 1807 | "vc deixou em validação Marcos aí vc explica por favor." |
| 1785 | "tá concluído na fila do Marcos, valide aí pra mim, já foi feito?" |
| 1779 | "tá concluído na fila do Marcos, valide aí pra mim, já foi feito?" |
| 1775 | "Bloqueada comigo. Não tem como colocar até o Vinícius Cunha e o time de dados conversarem com o HyperFlow (empresa de atendimentos) para disponibilizar acesso às bases deles, hj pegamos informações diretamente da base que eles fornecem, não tem base disso. Não iniciada." |
| 1747 | "Leandro fala quando vc começou, mas se não me engano vc tá terminando os testes né? É o gatilho dele de encerrar e voltar o atendimento pra pessoa que ele tá fazendo e falou hj. Não é torre" |
| 1699 | "é uma demanda do time de dados que tá marcada como feita pra eles, não é nossa" |

### Resposta Marcos Rodrigues — dev IAF

| Ticket | Resposta verbatim (resumida) |
|---|---|
| 1869 | "antes/no meio do processo do ci-cd e ambientes, eu tinha implementado a blocklist (via ticket anterior, depois adicionaram outro ticket com mais algumas características e aí não mexi ainda), então ele está em alguma branch aí implementado, tô esperando terminarmos o que está priorizado para dar continuidade" |
| Demais em validação | "mesma coisa para todos os tickets em validação (devo mudar a raia?) que eram features da torre ou fix..." |
| 1785 / 1779 | "O 1785 e o 1779 estão concluídos de fato" |

### Verificações pendentes do supervisor

- **Vinícius Cunha (1775)**: João Vinícius precisa falar com ele para entender o avanço da conversa com o HyperFlow.
- **Leandro Marques (1747)**: confirmou diretamente que está finalizando os testes.

## Cruzamento / Análise

### Tabela consolidada (com título oficial do anexo)

| # | Ticket | Título oficial (anexo) | Status real | Etapa no board | Responsável | Escopo |
|---|--------|------------------------|-------------|----------------|-------------|--------|
| 1 | 1871 | Status de contrato em questão plataforma — Torre de Controle | Concluída (15/05/2026) | Demanda internalizada | João Lucas | IAF |
| 2 | 1869 | Blocklist Torre de Controle | Bloqueada | Backlog | Marcos | IAF |
| 3 | 1865 | Correção e atualização do Gatilho buscar títulos Sankhya | Em curso (início 13/05) | Em Andamento | João Pedro | IAF |
| 4 | 1821 | Top's 270 e 271 | Cancelada | Backlog | (Mateus cancelou) | **Fora do IAF** |
| 5 | 1807 | Status Cancelamento — Em análise judicial \| Plataforma | Em validação | Em Validação | Marcos | IAF |
| 6 | 1785 | Adicionar novo campo Torre de Controle | Concluída (pendente validação) | Em Andamento | Marcos | IAF |
| 7 | 1779 | Novo campo Torre de Controle | Concluída (pendente validação) | Em Andamento | Marcos | IAF |
| 8 | 1775 | Inclusão da organização Finza no AuditorIA | Não iniciada (bloqueio externo) | Bloqueado | Vinícius Cunha + Dados | IAF (dep. externa) |
| 9 | 1747 | Criação de templates e demais configurações \| Coorporativo Hyper | Finalizando testes | Em Andamento | Leandro Marques | IAF |
| 10 | 1699 | Funil/Esteira Retirada | Não é IAF (do time de Dados) | Demanda internalizada | Time de Dados | **Fora do IAF** |

### Divergências detectadas entre respostas do João Lucas e título oficial do anexo

| Ticket | João Lucas relatou | Anexo Jira diz | Status da divergência |
|---|---|---|---|
| **1747** | "Gatilho de encerrar e voltar atendimento" | "Criação de templates e demais configurações \| Coorporativo Hyper" | **Crítica** — confirmar com Leandro qual é o ticket dele de fato. Pode ser que João Lucas confundiu com outro ticket. |
| **1821** | "Consulta do Shankya no gatilho do Hyper" | "Top's 270 e 271" | **Média** — título do anexo não dá pista de "Shankya"; confirmar com Mateus o que era "Top's 270 e 271". |
| **1871** | "Campos de status e fase da plataforma" | "Status de contrato em questão plataforma — Torre de Controle" | **Baixa** — descrições compatíveis; "fase" não aparece no título, mas João Lucas confirmou conclusão em 15/05. |
| **1865** | "Gatilho no Hyper" | "Correção e atualização do gatilho de buscar títulos Sankhya" | **Baixa** — gatilho roda no Hyper buscando no Sankhya (ERP). Compatível. |
| **1775** | "Acesso a base do HyperFlow" | "Inclusão da organização Finza no AuditorIA" | **Baixa** — João Lucas descreveu a causa do bloqueio (acesso HyperFlow); demanda em si é AuditorIA. Compatível. |
| **1699** | "Marcada como feita pelo time de Dados" | "Funil/Esteira Retirada" — Etapa: Demanda internalizada | **Baixa** — pode estar como "concluída" para o time de Dados mas ainda "Demanda internalizada" no board do IAF. Confirmar status real. |

### Síntese

- **3 demandas IAF concluídas:** 1871, 1785, 1779. Destas, 1785 e 1779 precisam de validação do supervisor antes de marcar oficialmente como entregues.
- **2 demandas em andamento:** 1865 (João Pedro) e 1747 (Leandro).
- **1 demanda em validação aguardando decisão de processo:** 1807 (Marcos pergunta "devo mudar a raia?").
- **1 demanda IAF bloqueada por prioridade interna:** 1869 (espera Torre desbloquear).
- **1 demanda IAF bloqueada por dependência externa:** 1775 (Hyperflow precisa liberar acesso a base).
- **2 demandas fora do escopo IAF foram cobradas indevidamente:** 1821 (cancelada por Mateus, era do Shankya) e 1699 (do time de Dados, já marcada como feita pelo time deles).

### Pontos para o supervisor agir

1. **Falar com Vinícius Cunha** — destravar 1775 (conversa com HyperFlow / acesso a bases).
2. **Validar 1785 e 1779 com Marcos** — testar funcionalidade e marcar como entregue oficial.
3. **Confirmar fechamento de 1747 com Leandro** — ele disse que está terminando, sem data exata.
4. **Decidir com Marcos a raia** das demandas em validação (1807 e similares). Marcos pediu orientação direta.
5. **Devolver report ao time de negócio** explicitando: 8 demandas IAF + 2 fora do escopo (1821 e 1699). Sem inflar números nem omitir bloqueios.

## Conclusão

Das 10 demandas cobradas, **8 são do squad IAF**. Dessas 8: 3 estão concluídas (com 2 aguardando validação do supervisor), 2 em andamento, 1 em validação aguardando decisão de processo, e 2 bloqueadas (1 por prioridade interna, 1 por dependência externa do HyperFlow). As outras 2 demandas (1821 e 1699) **não pertencem ao squad IAF** e foram incluídas indevidamente na cobrança — precisam ser explicitadas no report ao time de negócio.

A devolutiva ao time de negócio (vide [Relatorio/2026-05-18_relatorio-demandas-cobranca.md](Relatorio/2026-05-18_relatorio-demandas-cobranca.md)) deve usar linguagem honesta — sem prometer data em demandas bloqueadas por terceiros, e separando claramente IAF vs fora-de-escopo.

## Próximas ações

<!-- Cada item deve virar pendência via /pendencia add -->
- [ ] **Confirmar com Leandro qual é o ticket real do 1747** — anexo cita "templates Corporativo Hyper", João Lucas relatou "gatilho de encerrar atendimento". Divergência crítica. Owner: João V., deadline: 21/05/2026
- [ ] **Confirmar com Mateus o conteúdo de "Top's 270 e 271" (1821)** — entender por que o título não condiz com a explicação do João Lucas. Owner: João V., deadline: 22/05/2026
- [ ] Atualizar status do 1871 no board — anexo mostra "Demanda internalizada" mas demanda foi concluída em 15/05. Owner: João Lucas, deadline: 22/05/2026
- [ ] Falar com Vinícius Cunha sobre 1775 (acesso HyperFlow / AuditorIA) — owner: João V., deadline: 22/05/2026
- [ ] Validar 1785 com Marcos (novo campo Torre) — owner: João V., deadline: 22/05/2026
- [ ] Validar 1779 com Marcos (novo campo Torre) — owner: João V., deadline: 22/05/2026
- [ ] Decidir com Marcos a raia das demandas em validação (1807 +) — owner: João V., deadline: 22/05/2026
- [ ] Gerar relatório de devolução para o time de negócio — owner: João V., deadline: 19/05/2026

## Notas / observações

- **Double-check feito em 18/05/2026:** após o cruzamento inicial, recebi a imagem do board Jira com os títulos oficiais dos 10 tickets. As descrições nesta análise foram atualizadas para refletir o título oficial. As respostas verbatim do João Lucas e do Marcos foram preservadas na seção de Dados/Insumos para rastreabilidade.
- **Solicitante de todas as 10 demandas:** `joao.martins@blips.com.br` (time de negócio).
- **Demandas marcadas como urgentes no anexo:** 1871, 1865, 1821, 1807. Demais (1869, 1785, 1779, 1775, 1747, 1699) não urgentes.
- **Pessoa responsável atribuída ao João Vinícius no board:** 1871, 1865, 1869. As demais estão com Mateus Alberone (1821, 1807, 1785, 1779, 1775, 1747) ou Thiago Pereira Queiroz (1699) como responsáveis.
- **Inconsistência no relato do João Lucas (1871):** Escreveu "quarta feira dia 15", mas 15/05/2026 foi sexta-feira. Não afeta o status; vale confirmar com ele se a data correta é 15/05 (sexta) ou 13/05 (quarta).
- **"Raia" mencionada pelo Marcos** — termo de board (Kanban). Marcos pediu orientação porque os tickets em validação são features/fixes da Torre e ele não sabe se mantém na raia atual ou move. **Decisão pendente do supervisor.**
- **HyperFlow vs Hyper:** Os documentos canônicos Finza referenciam **HyperFlow** como plataforma conversacional. "Hyper" nas mensagens é a mesma coisa. Tickets 1775 (AuditorIA), 1865 (gatilho) e 1747 (templates) envolvem o Hyper.
- **Sankhya** (ERP) é diferente de "Shankya" (citado pelo João Lucas no 1821). Provavelmente o João Lucas escreveu "shankya" como aproximação fonética de "Sankhya" — ambos se referem ao mesmo sistema.
- **Sistema de tickets oficial:** Jira `IAF` no board `blips-dev.atlassian.net` (conforme `Docs/finza/CONTEXTO-FINZA.md`).
