---
description: Visão de gestor sobre as demandas do squad IAF no Quimera. Puxa todas as demandas da equipe (João Lucas, João Pedro, Leandro, Marcos + você) de uma vez, agrupadas por pessoa e status. Leitura livre — não escreve nada. Para operar um ticket específico, use /quimera.
---

# /equipe — painel de demandas da equipe (Quimera)

Visão de **gestor** do supervisor IAF: o estado de **todas as demandas do time inteiro** no Quimera, num só lugar. Roteia para o agente **`quimera-ops`** (skill `quimera`). Escopo = time **`ia_automacao_finza`**, restrito ao **roster da sua equipe** (não a Finza inteira).

> **/equipe ≠ /quimera demandas.** `/quimera demandas` é consulta genérica com filtros. `/equipe` é o recorte fixo "minha equipe inteira", agrupado por pessoa, pensado para o gestor conferir status recorrentemente. **Só leitura** — não cria, não muda status, não comenta. Para agir num ticket, use `/quimera`.

## A equipe (roster fixo)

| Pessoa | Papel | UUID (`assigned_to`) |
|---|---|---|
| Joao Lucas Pontes Freitas | Implementador | `b90f482e-5852-4e8c-87c5-578d9b82b93b` |
| João Pedro da Silva Neto | Implementador | `f403707d-27d8-4c49-8632-28d53c3eafe3` |
| Leandro Marques Gontijo Jersé | Implementador | `857575b1-6803-4d5b-b817-b521cc45c5eb` |
| Marcos Rodrigues de Oliveira Júnior | Implementador | `409661f3-603f-4ab1-ae15-146076ddca0a` |
| João Vinícius Dessimoni Fernandes | **Supervisor IAF** (você) | `34a15ef4-cfb6-4c4a-86e8-e069b068677f` |

> Esses UUIDs são canônicos — vivem na skill `quimera` (§1). Se alguém entrar/sair da equipe, atualize **lá** e aqui.

## Subcomandos

`$ARGUMENTS` define o recorte:

| Forma | O que faz |
|---|---|
| `/equipe` (vazio) | **Default.** Demandas **ativas** (não `finalizado`/`cancelado`) de cada membro do roster, agrupadas por pessoa → status. Visão "o que cada um tem em mãos agora". |
| `/equipe tudo` | Inclui também finalizadas e canceladas (histórico completo por pessoa). |
| `/equipe <nome>` | Recorte de uma pessoa só (ex.: `/equipe joao lucas`, `/equipe leandro`). |
| `/equipe status=<status>` | Filtra por um status em toda a equipe (ex.: `/equipe status=em_andamento` → quem está executando o quê). |
| `/equipe bloqueios` | Atalho para o que trava: ativos em `fila_exec` + `em_validacao` parados + prioridade `high` aberta, em toda a equipe. |
| `/equipe carga` | Visão de carga: contagem de ativos e soma de story points por pessoa (quem está sobrecarregado). |
| `/equipe sem-dono` | Tickets do time `ia_automacao_finza` **sem `assigned_to`** — demanda órfã que ninguém pegou. |

## Execução

Invoque `quimera-ops` assim:
```
Subcomando: equipe
Recorte: <vazio|tudo|nome|status=…|bloqueios|carga|sem-dono>
Escopo: time ia_automacao_finza, roster da equipe (5 UUIDs acima; supervisor incluído)
```

Como o `list_tickets` aceita **um** `assigned_to` por chamada, o agente roda **uma chamada por membro do roster em paralelo** (filtrando `team=ia_automacao_finza`), depois consolida. Para `sem-dono`, roda `list_tickets team=ia_automacao_finza` e filtra os sem `assigned_to`.

## Formato de saída (visão de gestor)

- **Cabeçalho:** total de ativos da equipe + leitura rápida (ex.: "2 highs abertos, 1 em validação parado há 5d").
- **Por pessoa:** mini-tabela `#número · título · status · prio · SP · idade`, ordenada por status (em_andamento → fila_exec → em_validacao → backlog). Membro sem demanda ativa: linha "— sem demandas ativas".
- **Você (supervisor)** numa seção própria ao final, separada dos liderados.
- **Destaque** highs abertos e itens parados há muito tempo (idade alta em `em_validacao`/`fila_exec`).
- Conciso e factual. Não despeje JSON cru. Idade contada até a data de hoje.

## Regras duras

- **Somente leitura.** `/equipe` nunca chama `create_*`, `change_ticket_status`, `add_comment`, `update_*`, `add_tags`/`remove_tags`. Se o usuário quiser agir num ticket que apareceu aqui, oriente para `/quimera status …`, `/quimera comentar …`, etc.
- **Roster fixo.** Não inventa membro nem UUID. Pessoa fora do roster → é caso de `/quimera demandas assignee=<nome>`, não de `/equipe`.
- **Não gera `.md`.** O Quimera é o sistema de registro. Para persistir um recorte (ex.: status semanal), encadeie com `/status`, `/analise` ou `/relatorio` depois.
