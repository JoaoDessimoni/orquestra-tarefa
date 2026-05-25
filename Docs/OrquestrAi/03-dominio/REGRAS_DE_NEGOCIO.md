# Regras de Negócio — OrquestrAI

> Invariantes, validações, eventos de domínio. O backend é responsável por garantir todas estas regras. Última atualização: 20/05/2026.

## Fontes

- [SCHEMA_POSTGRES.md](SCHEMA_POSTGRES.md)
- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md)

---

## Convenção

- **RN-XX**: regra de negócio numerada.
- **Tipo**: `invariante` (sempre verdadeiro) | `validação` (na entrada) | `evento` (dispara ação) | `política` (decisão de design).

---

## 1 · Agentes

### RN-01 — Slug único e válido (validação)

Slug deve casar com `^[a-z0-9][a-z0-9-]*[a-z0-9]$` e ser único na tabela `agents`. Erros: `slug_invalid`, `slug_already_exists`.

### RN-02 — Subagente é Agente com flag (invariante)

Não há tabela separada. Para listar "subagentes": `WHERE is_subagent = true AND deleted_at IS NULL`.

### RN-03 — Vínculo de subagente: sem ciclos (validação)

Ao criar relação em `agent_subagents`, backend executa BFS/DFS de detecção de ciclo. Se ciclo, rejeita com `cycle_detected`. Pseudo-código em [SCHEMA_POSTGRES.md §4.4](SCHEMA_POSTGRES.md).

### RN-04 — Self-reference proibida (invariante)

`agent_subagents.agent_id <> agent_subagents.sub_id` (CHECK constraint).

### RN-05 — Edição de agente preserva execuções (política)

Atualizar prompt/modelo/tools de um agente **não afeta** execuções históricas (que têm `agent_snapshot` imutável). Execuções futuras usarão nova configuração.

### RN-06 — Soft delete de agente (política)

Agente "excluído" recebe `deleted_at = now()`. Execuções continuam visíveis. Vínculos M:N (skills, subagents) **permanecem** mas não aparecem em listagens.

### RN-07 — Limite de ferramentas (validação)

Campo `tools` aceita apenas valores do enum permitido: `["Read", "Edit", "Write", "Grep", "Glob", "Bash", "WebSearch", "WebFetch"]`. Valor fora da lista → `unknown_tool`.

---

## 2 · Skills

### RN-08 — Slug único e válido (validação)

Mesmas regras de RN-01, aplicadas a `skills`.

### RN-09 — Tamanho do body (validação)

`body_md` aceita até **20.000 chars**. Acima → `body_too_large`.

### RN-10 — Tag formato (validação)

Cada tag (string) deve casar com `^[a-z0-9-]{1,30}$`. Array máximo 10 tags. Erros: `tag_invalid`, `too_many_tags`.

---

## 3 · Execuções

### RN-11 — Status transitions (invariante)

Transições permitidas:

```
running ─┬─▶ done
         ├─▶ error
         ├─▶ aborted
         └─▶ unknown   (recuperado de crash do backend)
```

Status terminais (`done`, `error`, `aborted`, `unknown`) **não podem retroceder**. Tentativa → `invalid_state_transition`.

### RN-12 — Snapshot obrigatório (validação)

Ao criar Execução, `agent_snapshot` deve conter pelo menos: `slug`, `system_prompt`, `model`, `tools`. Sem isso → `incomplete_snapshot`.

### RN-13 — cwd validado (validação)

`cwd` deve estar dentro de `settings.workspace_path` (path-traversal bloqueada). Senão → `cwd_outside_workspace`.

### RN-14 — Limite de concorrência (política)

Backend não dispara nova execução se já houver `settings.max_concurrent` execuções com `status=running`. Em vez disso, retorna `429 Too Many Requests` com header `Retry-After` ou enfileira (TBD V1).

### RN-15 — Abort timing (política)

Ao abortar: SIGTERM imediato → aguarda 5s → SIGKILL. Status final = `aborted`. Campo `aborted_by` = `"user"` (MVP single-user; V1 = `user_id`).

### RN-16 — Eventos persistidos antes do done (invariante)

Backend persiste **todos** os `execution_events` **antes** de emitir o evento `done` (commit transacional). Garantia: não há `done` sem timeline completa no DB.

### RN-17 — `seq` monotônico (invariante)

`execution_events.seq` inicia em 0 e incrementa em 1 por evento. Unique `(execution_id, seq)`.

### RN-18 — Custo calculado no fim (política)

`cost_estimated_usd` é calculado apenas quando status vira terminal, usando pricing_table do momento. Fórmula:

```
cost = (tokens_input / 1_000_000) * pricing[model].input
     + (tokens_output / 1_000_000) * pricing[model].output
```

Se `tokens_input` ou `tokens_output` for `NULL`, custo = `NULL`.

### RN-19 — Detecção de crash do backend (evento)

Ao subir o backend, varrer `executions WHERE status='running' AND started_at < NOW() - INTERVAL '10 minutes'`. Marcar como `unknown` e logar `recovered_stale_execution`.

---

## 4 · Análises

### RN-20 — Status transitions

```
rascunho ─▶ revisao ─▶ publicada
   ▲          │           │
   └──────────┘           │
           (volta)        │
                          │
   (publicada NÃO volta para revisao)
```

Tentativa de `publicada → rascunho/revisao` → `invalid_state_transition`.

### RN-21 — `published_at` setado ao publicar (evento)

Transição para `publicada` seta `published_at = NOW()`. Edits subsequentes não alteram esse campo.

### RN-22 — Vincular execução a análise (validação)

Execução vinculada deve ter `status = done` (não pode anexar execução em andamento ou erro). Senão → `execution_not_done`.

### RN-23 — Exclusão de análise com relatórios (política)

Não permitir delete (mesmo soft) se houver `reports WHERE analysis_id = X AND deleted_at IS NULL`. Erro: `analysis_has_reports`. Primeiro deletar relatórios.

---

## 5 · Relatórios

### RN-24 — Análise-fonte obrigatória (invariante)

`reports.analysis_id` NOT NULL. FK `ON DELETE RESTRICT`. Cria fluxo: análise sempre vem antes do relatório.

### RN-25 — Análise-fonte deve estar publicada para relatório enviado (validação)

Se transição de relatório para `enviado`, validar que `analyses[analysis_id].status = 'publicada'`. Senão → `analysis_not_published`.

### RN-26 — Status transitions de relatório

```
rascunho ─▶ revisao ─▶ enviado
   ▲          │           
   └──────────┘           
```

`enviado` é terminal — não pode voltar (somente arquivar via soft-delete, e mesmo assim mantém registro).

### RN-27 — Exclusão de relatório enviado bloqueada (política)

`DELETE` físico bloqueado se `status = 'enviado'`. Soft-delete permitido (vira "arquivado").

---

## 6 · Export

### RN-28 — Path de export determinístico (invariante)

Análise: `<export_path>/Analises/<dd-mm-aaaa-published_at>/<YYYY-MM-DD>_<slug>.md`.
Relatório: `<export_path>/Analises/<dd-mm-aaaa-analise>/Relatorio/<YYYY-MM-DD>_<slug>.md`.

### RN-29 — Não-sobrescrita (política)

Se arquivo já existe no path destino e **não** contém o header `<!-- gerado-por: orquestr-ai -->`, sufixar com `_2`, `_3`, ... Senão (gerado por nós), sobrescrever.

### RN-30 — Atualizar `exported_at` e `exported_path` (evento)

Após escrita bem-sucedida, atualizar campos da entidade no DB. Falha de I/O → status do export = `failed`, sem update.

### RN-31 — Frontmatter compatível (invariante)

Frontmatter gerado deve seguir convenção do workspace `.claude/` (campos `title`, `data`, `autor`, `tipo`/`destinatario`, `status`, `tags` — ver `Gestao/Analises/<dia>/*.md` existentes).

---

## 7 · Settings

### RN-32 — `workspace_path` validado (validação)

Ao salvar `settings.workspace_path`: backend valida que (a) é diretório existente, (b) é acessível, (c) `claude code --version` retorna sucesso quando invocado com cwd = path. Senão → `workspace_invalid` com mensagem específica.

### RN-33 — `pricing_table` schema (validação)

JSON deve casar com schema:
```json
{
  "<model>": {"input": <number>, "output": <number>},
  ...
}
```
Modelos válidos: `opus`, `sonnet`, `haiku`. Campos `input`/`output` em USD por 1M tokens.

---

## 8 · Eventos de domínio (cross-entidade)

| Evento | Dispara |
|---|---|
| `execution.done` | Atualiza `agents.last_executed_at` (cache, opcional) |
| `analysis.published` | Habilita relatórios para transitar a `enviado` |
| `report.exported` | Marca `reports.exported_at` |
| `agent.deleted` | Detecta execuções em andamento → aborta-as antes de aplicar soft delete |

---

## 9 · Mensagens de erro canônicas

Padronizar `error_code` (snake_case) e `message` (PT-BR) para frontend exibir consistentemente:

| code | mensagem |
|---|---|
| `slug_invalid` | "Slug inválido. Use letras minúsculas, números e hífens." |
| `slug_already_exists` | "Já existe um item com este slug." |
| `cycle_detected` | "Esse vínculo criaria um ciclo entre agentes." |
| `cwd_outside_workspace` | "O diretório informado está fora do workspace." |
| `execution_not_done` | "Só é possível anexar execuções concluídas." |
| `analysis_has_reports` | "Esta análise possui relatórios. Exclua-os antes." |
| `analysis_not_published` | "A análise-fonte precisa estar publicada para enviar o relatório." |
| `workspace_invalid` | "O path do workspace é inválido ou o Claude Code não foi encontrado." |
| `too_many_concurrent` | "Limite de execuções simultâneas atingido. Tente em alguns segundos." |
| `invalid_state_transition` | "Transição de status não permitida." |

Frontend mapeia `error_code` → toast com mensagem amigável.
