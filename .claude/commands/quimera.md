---
description: Opera o Quimera (sistema de tickets interno Finza) via MCP. Subcomandos — demandas/consultar, card/novo, sub, status, comentar, tag, indicadores, gestao, csat, users. Escopo padrão = time IA Finza (ia_automacao_finza). Leitura é livre; escrita confirma antes (dispara e-mail/notificação).
---

# /quimera — operar o sistema de tickets da IA Finza

Roteia para o agente **`quimera-ops`**, que usa as ferramentas MCP `mcp__quimera__*`. Escopo padrão = time **`ia_automacao_finza`** (squad IAF). Conhecimento canônico do domínio na skill `quimera`.

> **Quimera ≠ /backlog.** `/quimera` opera o sistema de tickets corporativo ao vivo. `/backlog` opera a estratégia interna do squad (`.md`, RICE). Não confunda.

`$ARGUMENTS` define o subcomando:

| Forma | O que faz |
|---|---|
| `/quimera` (vazio) | Snapshot operacional do squad — `get_operacional_summary` + tickets ativos por status (`list_tickets team=ia_automacao_finza`). |
| `/quimera demandas [filtros]` | Consulta demandas. Aceita `status=`, `prioridade=`, `assignee=<nome>`, `categoria=`, `busca="texto"`, `limit=`. Default: pais ativos do squad. Equivale a `consultar`. |
| `/quimera show <#número\|id>` | Detalhe completo de um ticket (`get_ticket`) — tags, subtarefas, watchers, comentários. |
| `/quimera card "<título>"` | Cria ticket pai (`create_ticket`). Pergunta o que faltar (descrição, categoria, prioridade, requester, assignee). **high exige justificativa.** Monta o payload e confirma antes de criar. Equivale a `novo`. |
| `/quimera sub <#pai> "<título>"` | Cria subtarefa (`create_subtask`) sob o pai (herda team/categoria/requester). |
| `/quimera status <#número> <novo-status>` | Muda status (`change_ticket_status`). **Confirma antes** — dispara notificação/e-mail. Estados: backlog, fila_exec, em_andamento, em_validacao, finalizado, cancelado. |
| `/quimera comentar <#número> "<texto>" [--interno]` | Adiciona comentário (`add_comment`). `--interno` = nota de analista. Público confirma antes. |
| `/quimera tag <#número> +tag -tag` | Adiciona/remove tags (`add_tags`/`remove_tags`). |
| `/quimera atribuir <#número> <nome>` | Atribui (`update_ticket assigned_to=<UUID>`). Traduz nome→UUID pela skill. |
| `/quimera indicadores [period=]` | Painel de indicadores do squad — `get_gestao_overview` (Conclusão, Cycle Time vs meta 3,7d, Intruders, Gerencial, Operacional, CSAT). |
| `/quimera csat [period=]` | CSAT do squad — `get_ratings_summary` + `list_ratings` recentes com comentário. |
| `/quimera users [busca]` | Lista perfis (`list_users`) — para achar UUID/e-mail de quem atribuir. |

## Execução

Invoque `quimera-ops` passando o subcomando + args. Brief:
```
Subcomando: <demandas|show|card|sub|status|comentar|tag|atribuir|indicadores|csat|users>
Args: <args>
Escopo: time ia_automacao_finza (salvo override explícito no pedido)
```

## Quando pedir input adicional (via AskUserQuestion)

- **card** sem descrição clara → peça descrição. Sem categoria → ofereça {Cobrança, Recuperação, TI}. Prioridade `high` sem justificativa → peça a justificativa ou rebaixe.
- **card/sub** com requester ambíguo → default João Vinícius; confirme se for terceiro.
- **status/comentar/atribuir** sem número → liste demandas ativas e pergunte qual.
- **atribuir** com nome fora da tabela da skill → rode `list_users` antes.

## Regras duras

- **Leitura livre** (`demandas`, `show`, `indicadores`, `csat`, `users`) — executa direto.
- **Escrita confirma antes** (`card`, `sub`, `status`, `comentar` público, `tag`, `atribuir`) — apresenta o payload e espera "ok", salvo autorização explícita na mesma conversa.
- `assigned_to` = **UUID**; `requester_email`/`author_email` = **e-mail**. Nunca inventar.
- Default `team=ia_automacao_finza`. Outro time só com pedido explícito.
- Não gera artefato `.md` no workspace — o Quimera é o sistema de registro. (Se o usuário quiser persistir um recorte como análise/relatório, encadeie com `/analise` ou `/relatorio` depois.)
