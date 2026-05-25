# Requisitos Funcionais — OrquestrAI

> RFs numerados, testáveis, escritos no formato "O sistema deve...". Última atualização: 20/05/2026.

## Fontes

- [ESCOPO_MVP.md](ESCOPO_MVP.md)
- [PERSONAS.md](PERSONAS.md)
- [04-telas/](../04-telas/) (referência das telas)

---

## Convenção

- **RF-XX-YY**: XX = módulo, YY = sequencial dentro do módulo.
- Prioridades: **P0** (MVP obrigatório), **P1** (V1), **P2** (V2+).
- Status: cada RF deve poder ser verificado por um teste automatizado OU passo manual.

---

## RF-AG · Agentes

| ID | Prioridade | Descrição |
|---|---|---|
| RF-AG-01 | P0 | O sistema deve permitir criar um Agente com: nome, slug (único, kebab-case), descrição, prompt do sistema (markdown), modelo (`opus`/`sonnet`/`haiku`), ferramentas habilitadas (multi-select), e flag `is_subagent` (bool). |
| RF-AG-02 | P0 | O sistema deve listar todos os Agentes em uma tabela paginada, com filtros por nome, modelo e flag `is_subagent`. |
| RF-AG-03 | P0 | O sistema deve permitir editar um Agente; salvar gera registro novo se prompt mudou (versão imutável de prompt no histórico de Execuções). |
| RF-AG-04 | P0 | O sistema deve permitir vincular N Skills a um Agente (relacionamento M:N). |
| RF-AG-05 | P0 | O sistema deve permitir vincular N Subagentes a um Agente (relacionamento M:N), com validação: o Agente não pode se vincular a si mesmo, e vínculos circulares devem ser detectados e rejeitados. |
| RF-AG-06 | P0 | O sistema deve permitir excluir um Agente; soft-delete (campo `deleted_at`), preservando execuções históricas. |
| RF-AG-07 | P0 | A tela de detalhe do Agente deve mostrar: prompt em modo preview (markdown renderizado) + tabs para Skills/Subagentes/Execuções. |
| RF-AG-08 | P1 | O sistema deve permitir clonar um Agente existente (cria cópia com sufixo `-copy`). |
| RF-AG-09 | P1 | O sistema deve permitir importar agentes do `.claude/agents/` do workspace via botão "Importar". |

## RF-SK · Skills

| ID | Prioridade | Descrição |
|---|---|---|
| RF-SK-01 | P0 | O sistema deve permitir criar uma Skill com: nome, slug, descrição curta, corpo markdown, tags (array). |
| RF-SK-02 | P0 | O sistema deve listar Skills com filtros por tag e busca por nome. |
| RF-SK-03 | P0 | O sistema deve permitir editar e excluir Skills (soft-delete). |
| RF-SK-04 | P0 | A tela de detalhe da Skill deve renderizar o markdown com preview. |
| RF-SK-05 | P1 | O sistema deve mostrar em quais Agentes uma Skill está vinculada. |

## RF-EX · Execuções

| ID | Prioridade | Descrição |
|---|---|---|
| RF-EX-01 | P0 | O sistema deve permitir disparar uma Execução de um Agente, com: input (texto livre, multilinha), cwd (path do workspace, default `/workspace/Repasse`), opções avançadas (modelo override, max turns). |
| RF-EX-02 | P0 | O sistema deve registrar a Execução com snapshot do prompt do Agente, modelo, ferramentas, input e timestamp de início. |
| RF-EX-03 | P0 | O sistema deve transmitir eventos de execução via SSE em tempo real: `status`, `token`, `tool_call`, `tool_result`, `error`, `done`. Spec em [02-arquitetura/STREAMING_SSE.md](../02-arquitetura/STREAMING_SSE.md). |
| RF-EX-04 | P0 | O sistema deve persistir todos os eventos em tabela `execution_events` para replay. |
| RF-EX-05 | P0 | O sistema deve permitir abortar uma execução em andamento (botão "Stop"); processo filho deve ser terminado (SIGTERM com fallback SIGKILL após 5s). |
| RF-EX-06 | P0 | O sistema deve calcular e exibir, ao fim da execução: duração, número de tool calls, tokens de input/output (se Claude Code reportar), custo estimado (com base em pricing table local). |
| RF-EX-07 | P0 | O sistema deve listar execuções em tabela com filtros: agente, status (`running`/`done`/`error`/`aborted`), data, custo. |
| RF-EX-08 | P0 | A tela de detalhe da Execução deve mostrar timeline ordenada de eventos, output final em markdown renderizado, e botão "Replay stream" (re-emite eventos persistidos). |
| RF-EX-09 | P1 | O sistema deve permitir vincular uma Execução a uma Análise existente (botão "Anexar a análise"). |
| RF-EX-10 | P1 | O sistema deve permitir agendar execuções recorrentes (cron-like). |

## RF-AN · Análises

| ID | Prioridade | Descrição |
|---|---|---|
| RF-AN-01 | P0 | O sistema deve permitir criar uma Análise com: título, tipo (`investigacao`/`comparativo`/`rfc`/`postmortem`/`proposta`/`cruzamento`), pergunta de investigação, contexto (markdown), status (`rascunho`/`revisao`/`publicada`), tags. |
| RF-AN-02 | P0 | O sistema deve permitir vincular N Execuções como insumos de uma Análise. |
| RF-AN-03 | P0 | O sistema deve listar Análises em cards com filtros por tipo, status e tags. |
| RF-AN-04 | P0 | A tela de detalhe da Análise deve mostrar: corpo, lista de execuções vinculadas (com link para detalhe), lista de relatórios derivados. |
| RF-AN-05 | P0 | O sistema deve permitir editar a Análise (qualquer campo) enquanto status for `rascunho` ou `revisao`. |
| RF-AN-06 | P0 | O sistema deve permitir exportar a Análise para `.md` no path `../Gestao/Analises/<dd-mm-aaaa>/<YYYY-MM-DD>_<slug>.md`. Conforme spec em [02-arquitetura/INTEGRACOES.md](../02-arquitetura/INTEGRACOES.md). |
| RF-AN-07 | P1 | O sistema deve permitir importar análises existentes de `Gestao/Analises/` (bootstrap). |

## RF-RP · Relatórios

| ID | Prioridade | Descrição |
|---|---|---|
| RF-RP-01 | P0 | O sistema deve permitir criar um Relatório com: título, destinatário (texto), análise-fonte (FK obrigatória), corpo markdown, status (`rascunho`/`revisao`/`enviado`), classificação (`interno`/`restrito`/`publico`), tags. |
| RF-RP-02 | P0 | O sistema deve listar Relatórios com filtros por destinatário, status, classificação. |
| RF-RP-03 | P0 | O sistema deve impedir exclusão do Relatório se status = `enviado` (apenas arquivar). |
| RF-RP-04 | P0 | O sistema deve permitir exportar Relatório para `.md` no path `../Gestao/Analises/<dd-mm-aaaa-fonte>/Relatorio/<YYYY-MM-DD>_<slug>.md`. |
| RF-RP-05 | P1 | O sistema deve permitir gerar Relatório a partir de Análise + Agente (executa agente com prompt template "Redija relatório para <destinatario> baseado em..."). |

## RF-DB · Dashboard

| ID | Prioridade | Descrição |
|---|---|---|
| RF-DB-01 | P0 | O Dashboard deve mostrar KPIs do mês corrente: agentes ativos (total), execuções totais, custo estimado total, análises publicadas, relatórios enviados. |
| RF-DB-02 | P0 | O Dashboard deve mostrar últimas 5 execuções com link para detalhe. |
| RF-DB-03 | P0 | O Dashboard deve mostrar atalhos para ações: "Nova Análise", "Novo Relatório", "Executar Agente". |
| RF-DB-04 | P1 | O Dashboard deve mostrar sparkline de execuções por dia nos últimos 30 dias. |

## RF-CP · Command Palette

| ID | Prioridade | Descrição |
|---|---|---|
| RF-CP-01 | P0 | O sistema deve abrir Command Palette via `Cmd+K` / `Ctrl+K` em qualquer tela. |
| RF-CP-02 | P0 | O Command Palette deve oferecer: navegação para qualquer view, ações (`+ Nova Análise`, `+ Novo Agente`, `▶ Executar Agente`), busca fuzzy em entidades (agentes, análises, relatórios). |
| RF-CP-03 | P0 | O Command Palette deve fechar com `Esc`, executar item com `Enter`, navegar com `↑↓`. |

## RF-ST · Settings

| ID | Prioridade | Descrição |
|---|---|---|
| RF-ST-01 | P0 | O sistema deve permitir configurar: path absoluto do workspace (default `/workspace/Repasse`), modelo padrão de agentes, path de export Gestao/ (default `/workspace/Repasse/Gestao`). |
| RF-ST-02 | P0 | Settings deve validar que o path do workspace existe e que `claude code --version` retorna sucesso ao invocá-lo no cwd. |
| RF-ST-03 | P0 | Settings deve permitir ver versão do Claude Code CLI detectada. |
| RF-ST-04 | P1 | Settings deve permitir configurar pricing table (custo por modelo por 1k tokens) para cálculo de custo estimado. |

## RF-EXP · Export

| ID | Prioridade | Descrição |
|---|---|---|
| RF-EXP-01 | P0 | O sistema deve gerar arquivos `.md` com **frontmatter compatível** com o workspace `.claude/` existente (campos `title`, `data`, `autor`, `tipo`, `status`, `tags`, etc. — ver [03-dominio/SCHEMA_POSTGRES.md](../03-dominio/SCHEMA_POSTGRES.md)). |
| RF-EXP-02 | P0 | O export não deve sobrescrever arquivo existente — se existir, sufixar com `_2`, `_3`, etc. |
| RF-EXP-03 | P0 | O export deve criar a pasta datada (`dd-mm-aaaa/`) se ela não existir. |
| RF-EXP-04 | P1 | O sistema deve permitir re-export (substitui arquivo .md anterior se ele tem header com `gerado-por: orquestr-ai`). |

---

## RF-PE · Pendências (v2 — promovido a MVP)

| ID | Prioridade | Descrição |
|---|---|---|
| RF-PE-01 | P0 | Criar Pendência: id (auto `P${N+1}`), title, status (`aberta`/`em-curso`/`bloqueada`/`fechada`), prioridade (`alta`/`media`/`baixa`), owner, criada, deadline, origem, tags, body_excerpt. |
| RF-PE-02 | P0 | Listar em tabela com filtros: status, prioridade, owner, busca (título/ID/tags). |
| RF-PE-03 | P0 | Ordenar por deadline asc default; `fechada` sempre ao final. |
| RF-PE-04 | P0 | Destacar (border-left danger) deadlines em atraso. |
| RF-PE-05 | P0 | Editar com persistência imediata. |
| RF-PE-06 | P0 | Excluir (soft-delete). Bloqueia se há análises vinculadas (V1+). |
| RF-PE-07 | P0 | Exportar para `Gestao/Pendencias/<dd-mm-aaaa>/<id>_<slug>.md`. |
| RF-PE-08 | P1 | Bulk-action: fechar múltiplas, mudar status, atribuir owner. |

## RF-RU · Reuniões (v2 — promovido a MVP)

| ID | Prioridade | Descrição |
|---|---|---|
| RF-RU-01 | P0 | Criar Reunião: title, data, tipo (`alinhamento`/`review`/`brainstorm`/`externa`/`1on1`), duracao, participantes (multi), tags, body_excerpt. |
| RF-RU-02 | P0 | Listar em cards com filtros por tipo, período, participante. |
| RF-RU-03 | P0 | Vincular pendências geradas (multi-select). |
| RF-RU-04 | P0 | Detalhe mostra pendências geradas como tags clicáveis. |
| RF-RU-05 | P0 | Editar/excluir. |
| RF-RU-06 | P0 | Exportar para `Gestao/Reunioes/<dd-mm-aaaa>/<YYYY-MM-DD>-<slug>.md`. |

## RF-OO · 1on1s (v2 — promovido a MVP)

| ID | Prioridade | Descrição |
|---|---|---|
| RF-OO-01 | P0 | Criar 1on1: pessoa, papel, data, duracao, recorrencia (`semanal`/`quinzenal`/`mensal`/`ad-hoc`), tags, body_excerpt. |
| RF-OO-02 | P0 | Listar em cards com filtros por pessoa, recorrência, período. |
| RF-OO-03 | P0 | Classificação default `restrito` (sensibilidade). |
| RF-OO-04 | P0 | Editar/excluir. |
| RF-OO-05 | P0 | Exportar para `Gestao/1on1s/<dd-mm-aaaa>/<YYYY-MM-DD>-1on1-<pessoa>.md`. |

## RF-RM · Roadmap (v2 — promovido a MVP)

| ID | Prioridade | Descrição |
|---|---|---|
| RF-RM-01 | P0 | Listar iniciativas em kanban por frente (`esperanza`/`valentina`/`clara`/`torre`/`automacoes`/`estrategica`). |
| RF-RM-02 | P0 | Cards mostram id, título, prioridade, count de pendências vinculadas. |
| RF-RM-03 | P0 | Detalhe mostra pendências vinculadas como tags clicáveis. |
| RF-RM-04 | P1 | Editar progresso (0-100), status, drag entre frentes. |
| RF-RM-05 | P0 | MVP: read-only (geradas pela análise de roadmap). V1+ habilita CRUD. |

## RF-CM · Commands (v2 — read-only no MVP)

| ID | Prioridade | Descrição |
|---|---|---|
| RF-CM-01 | P0 | Listar slash commands em cards (slug, target_agent, descrição). |
| RF-CM-02 | P0 | Importação inicial de `.claude/commands/*.md`. |
| RF-CM-03 | P1 | Criar/editar/excluir command (gera/atualiza .md). |

---

## Tabela-resumo: contagem de RFs por módulo

| Módulo | P0 | P1 | P2 | Total |
|---|---|---|---|---|
| Agentes | 7 | 2 | 0 | 9 |
| Skills | 4 | 1 | 0 | 5 |
| Execuções | 8 | 2 | 0 | 10 |
| Análises | 6 | 1 | 0 | 7 |
| Relatórios | 4 | 1 | 0 | 5 |
| Dashboard | 3 | 1 | 0 | 4 |
| Command Palette | 3 | 0 | 0 | 3 |
| Settings | 3 | 1 | 0 | 4 |
| Export | 3 | 1 | 0 | 4 |
| **Total** | **41** | **10** | **0** | **51** |

> **Subagentes não tem módulo separado**: subagentes são Agentes com `is_subagent=true`. Reusam RFs do módulo Agentes.
