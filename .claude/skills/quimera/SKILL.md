---
name: quimera
description: Conhecimento canônico do Quimera — o sistema de tickets/Jira interno da Finza, acessível via MCP (server "quimera"). Define o catálogo de 29 ferramentas, o workflow de status, o mapa de times (com o time da IA Finza = ia_automacao_finza), categorias, membros do squad com UUID, regras de criação de ticket e a definição dos indicadores gerenciais (Conclusão, Cycle Time, Intruders, CSAT). Carregue antes de qualquer operação no Quimera (criar/consultar card, indicadores) para não fabricar IDs, times ou e-mails.
---

# Skill — Quimera (tickets internos Finza via MCP)

O **Quimera** é o sistema de gestão de demandas/tickets interno da Finza (o "Jira interno" citado no CLAUDE.md). É acessível por um servidor **MCP HTTP** registrado neste workspace como `quimera`. As ferramentas aparecem como `mcp__quimera__<nome>`. **As permissões são as do dono da API key** (papel/time/página resolvidos no servidor) — o que o agente consegue ler/escrever é exatamente o nível de acesso do João Vinícius.

> **Quimera ≠ Backlog/.** O `Backlog/` deste workspace é o backlog **estratégico interno** do squad (arquivos `.md`, RICE, história). O Quimera é o **sistema de registro corporativo** onde as demandas de negócio vivem como tickets. São mundos diferentes: um item de `Backlog/` pode *referenciar* um ticket Quimera, mas não são a mesma coisa. Não confunda `/backlog` (estratégia .md) com `/quimera` (sistema de tickets ao vivo).

---

## 1 · O time da IA Finza

O squad IAF corresponde ao time **`ia_automacao_finza`** ("IA & Automação - Finza"). **Sempre filtre por esse `team` por padrão** ao consultar/criar, salvo pedido explícito de outro time.

Outros times existentes (não são o squad IAF — só use se pedido):
| id | nome |
|---|---|
| `ia_automacao_finza` | **IA & Automação - Finza** ← squad IAF (default) |
| `ia_automacao` | IA & Automação - Operações |
| `ia_salesops` | IA & Automação - SalesOps |
| `dados` | Dados |

**Categorias** usadas no time `ia_automacao_finza`: `Cobrança`, `Recuperação`, `TI`. (Há um conjunto muito maior de categorias globais, mas para o squad IAF use essas três salvo indicação contrária.)

### Membros do time `ia_automacao_finza` (para `assigned_to` e `requester_email`)

| Pessoa | E-mail | UUID (`assigned_to`) |
|---|---|---|
| João Vinícius Dessimoni Fernandes (supervisor IAF / owner — dono da API key) | `joao.dessimoni@blips.com.br` | `34a15ef4-cfb6-4c4a-86e8-e069b068677f` |
| Joao Lucas Pontes Freitas (implementador) | `joao.freitas@blips.com.br` | `b90f482e-5852-4e8c-87c5-578d9b82b93b` |
| João Pedro da Silva Neto | `joaopedro@blips.com.br` | `f403707d-27d8-4c49-8632-28d53c3eafe3` |
| Leandro Marques Gontijo Jersé | `leandro.gontijo@blips.com.br` | `857575b1-6803-4d5b-b817-b521cc45c5eb` |
| Marcos Rodrigues de Oliveira Júnior | `marcos.oliveira@finza.com.br` | `409661f3-603f-4ab1-ae15-146076ddca0a` |

> `assigned_to` usa **UUID**; `requester_email`/`author_email` usam **e-mail** (que deve existir em `profiles`). Para descobrir UUID/e-mail de alguém fora desta lista, use `list_users` com `search`. **Não invente UUID nem e-mail** — se não estiver nesta tabela, consulte `list_users` primeiro.

### A equipe direta do supervisor IAF (roster do `/equipe`)

João Vinícius (supervisor) **lidera diretamente** estes quatro implementadores. Esse é o roster fixo da visão de gestor (`/equipe`) — todos pertencem ao time `ia_automacao_finza`:

| Pessoa | Papel | UUID |
|---|---|---|
| Joao Lucas Pontes Freitas | Implementador | `b90f482e-5852-4e8c-87c5-578d9b82b93b` |
| João Pedro da Silva Neto | Implementador | `f403707d-27d8-4c49-8632-28d53c3eafe3` |
| Leandro Marques Gontijo Jersé | Implementador | `857575b1-6803-4d5b-b817-b521cc45c5eb` |
| Marcos Rodrigues de Oliveira Júnior | Implementador | `409661f3-603f-4ab1-ae15-146076ddca0a` |
| João Vinícius Dessimoni Fernandes | **Supervisor IAF** (dono da API key) | `34a15ef4-cfb6-4c4a-86e8-e069b068677f` |

> Como **gestor**, o João confere recorrentemente o status das demandas do time inteiro. O comando **`/equipe`** materializa isso: roda um `list_tickets assigned_to=<UUID>` por membro do roster (em paralelo, `team=ia_automacao_finza`) e consolida a visão por pessoa → status. É **só leitura**. Mudou a composição da equipe? Atualize esta tabela e o roster em `.claude/commands/equipe.md`.

---

## 2 · Workflow de status

Um ticket percorre estes estados (enum aceito por `create_ticket`, `create_subtask`, `change_ticket_status`):

```
backlog → fila_exec → em_andamento → em_validacao → finalizado
                                   ↘ cancelado
```

| status | significado |
|---|---|
| `backlog` | criado, ainda não priorizado para execução |
| `fila_exec` | priorizado, na fila de execução |
| `em_andamento` | em execução ativa |
| `em_validacao` | entregue, aguardando validação do solicitante |
| `finalizado` | concluído e validado |
| `cancelado` | encerrado sem entrega |

> Existe também um estado `bloqueado` que aparece no **histórico** e nos cálculos de Cycle Time (wait), mas **não é um valor gravável** por `change_ticket_status` (não está no enum). Não tente setá-lo.

`change_ticket_status` dispara `status_history`, notificações e automações de e-mail — é uma ação com efeito externo (ver §5).

---

## 3 · Catálogo de ferramentas (29)

### Tickets — consulta
- **`list_tickets`** — lista com filtros: `status`, `team`, `assigned_to` (UUID), `priority` (low|medium|high), `requester_email`, `parent_ticket_id`, `only_subtasks`, `only_parents` (exclui subtarefas), `search` (texto em título/descrição), `limit` (≤200, default 50), `offset`. Ordena por `created_at desc`.
- **`get_ticket`** — um ticket por `id` (UUID) **ou** `ticket_number` (número). Traz tags, subtarefas, watchers, comentários recentes.

### Tickets — escrita
- **`create_ticket`** — cria ticket pai. **Obrigatórios:** `title`, `description`, `team`, `category`, `priority`, `requester_email`. Opcionais: `deliverable_type`, `justification` (**obrigatório quando `priority=high`**), `story_points`, `assigned_to`, `status` (default `backlog`), `tags[]`, `source` (default `mcp`), `created_at`. Valida team, requester_email (deve existir em profiles) e justificativa de alta prioridade.
- **`create_subtask`** — cria subtarefa sob um pai. **Obrigatórios:** `parent_ticket_id`, `title`. Opcionais: `description`, `priority` (default medium), `story_points`, `assigned_to`, `status`. **Team, category, requester e company são herdados do pai automaticamente.**
- **`update_ticket`** — edita campos: `title`, `priority`, `category`, `story_points`, `assigned_to` (UUID, ou string vazia para desatribuir), `deliverable_type`, `created_at`. Requer `id`.
- **`update_ticket_description`** — substitui a descrição. Requer `id`, `description`.
- **`change_ticket_status`** — muda status. Requer `id`, `status`. **Dispara automações/e-mail.**

### Comentários
- **`add_comment`** — requer `ticket_id`, `content`, `author_email`. `is_internal=true` para nota só de analista.
- **`update_comment`** — requer `comment_id`; ao menos um de `content` / `is_internal`.
- **`delete_comment`** — requer `comment_id`.

### Tags
- **`add_tags`** — `ticket_id`, `tags[]` (dedup contra existentes).
- **`remove_tags`** — `ticket_id`, `tags[]`.

### Auxiliares (descoberta)
- **`list_teams`** — times habilitados.
- **`list_users`** — perfis (`id`, `email`, `full_name`, `company`, `team`, `status`). Filtros: `search`, `status` (approved|pending|rejected), `team`, `limit`.
- **`list_categories`** — categorias distintas em uso, agrupadas por time.

### Indicadores gerenciais (read-only — espelham a página Gestão)
Todos aceitam `team` e (quando histórico) `period`/`months`. Para o squad IAF, passe `team="ia_automacao_finza"`.
- **`get_completion_rate`** — **Conclusão**: % de tickets finalizados vs criados no período (`current_month`|`last_month`|`last_quarter`|`last_semester`|`last_year`).
- **`get_cycle_time`** — **Cycle Time**: dias úteis em `em_andamento`+`bloqueado`+`em_validacao` (touch+wait) até o último move para `finalizado`. Retorna mean/median/p90 + count. **Meta: 3,7 dias úteis.**
- **`get_intruders_rate`** — **Intruders %**: tickets marcados como intruso vs criados no período.
- **`get_daily_performance_history`** — % conclusão acumulado diário, últimos N meses (default 6, ≤12).
- **`get_cycle_time_history`** — cycle time mensal (cycle_mean = touch_mean + wait_mean), últimos N meses (default 12, ≤24).
- **`get_intruders_history`** — contagem/% de intruders mensal.
- **`get_gerencial_summary`** — contagens agregadas por status, prioridade, time e empresa do solicitante.
- **`get_operacional_summary`** — snapshot operacional atual: tickets por status, idade média em fila/andamento/validação, top assignees por abertos.
- **`get_story_points_history`** — story points entregues por mês (finalizados).
- **`get_breakdown_history`** — finalizados por dimensão: `category`, `requester_company`, `priority`, `deliverable_type`, `intruder`.
- **`get_ratings_summary`** — **CSAT**: distribuição 1–5, média geral, evolução mensal, breakdown tipo NPS.
- **`list_ratings`** — avaliações individuais (filtros: team, faixa de rating, datas, requester, ticket, texto no comentário).
- **`get_ticket_rating`** — CSAT de um ticket (`ticket_id` ou `ticket_number`).
- **`get_gestao_overview`** — snapshot consolidado: Indicadores + Gerencial + Operacional + CSAT no período.

---

## 4 · Regras de criação (anti-fabricação)

1. **`requester_email` deve existir em `profiles`.** Para o squad, use a tabela §1. Para terceiros, confirme via `list_users`.
2. **`priority=high` exige `justification`.** Sem justificativa concreta, não crie como high — pergunte ao usuário ou rebaixe para `medium`.
3. **`team` padrão = `ia_automacao_finza`**; **`category`** ∈ {`Cobrança`, `Recuperação`, `TI`} salvo pedido.
4. **`assigned_to` é UUID, não e-mail.** Se o usuário disser "atribui pro Joao Lucas", traduza para o UUID da tabela.
5. **Subtarefa herda contexto do pai** — não repasse team/category/requester em `create_subtask`.
6. Nunca invente `ticket_number` nem `id`. Para localizar, use `list_tickets`/`get_ticket`.

---

## 5 · Ações com efeito externo (confirme antes)

O Quimera é sistema de registro **vivo e compartilhado**. As ferramentas abaixo escrevem nele e podem disparar e-mail/notificação a terceiros — **confirme com o usuário antes de executar**, salvo autorização explícita na mesma conversa:

- `create_ticket`, `create_subtask` (cria registro visível ao time/solicitante)
- `change_ticket_status` (dispara `status_history` + notificações + automações de e-mail)
- `add_comment` com `is_internal=false` (comentário público, visível ao solicitante)
- `update_ticket`, `update_ticket_description`, `update_comment`, `delete_comment`, `add_tags`, `remove_tags`

Leituras (`list_*`, `get_*`) são livres — não pedem confirmação.

---

## 6 · Como esta skill se usa

- Carregada pelo agente **`quimera-ops`** e pelo comando **`/quimera`**.
- É **índice + regras**, não substitui consultar o estado ao vivo: para números e listas, sempre chame as tools (o conteúdo do Quimera muda a cada minuto).
- Se uma tool retornar erro de permissão, reporte ao usuário — pode ser limite de papel/time da API key, não bug.
