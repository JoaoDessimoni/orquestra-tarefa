---
name: orquestrai-padroes
description: Convenções de código obrigatórias do OrquestrAi — idioma PT sem acento, PascalCase classe/arquivo + snake_case método, banco tbl_/prefixos, API RPC-PT, camadas Controller/Service/Repository/Model/Dto, resiliência. Fonte canônica .specs/CONVENCOES.md.
---

# Padrões de código — OrquestrAi

Condensado de **`.specs/CONVENCOES.md`** (autoridade absoluta de nomenclatura). Em conflito, a
CONVENCOES e os ADRs (`.specs/ADR-001`, `.specs/ADR-002`) prevalecem. Schema build-ready em
`.specs/01-schema`; contratos em `.specs/02-contratos`; estrutura em `.specs/03-estrutura`.

## Idioma (regra-chave)
- **PT-BR sem acento em TODO identificador do nosso código**: arquivos, classes, métodos, funções,
  variáveis, tabelas, colunas, endpoints, componentes. Ex.: `descricao`, `criar_demanda`, `tbl_demandas`.
- **Classes/arquivos:** PascalCase PT (`DemandaService.py`, `class DemandaController`).
- **Métodos/funções/variáveis:** snake_case PT (`criar_demanda`, `buscar_por_id`, `lista_demandas`).
- **Exceções (mantêm inglês):** nomes de biblioteca (`APIRouter`, `BaseModel`, `useState`); variáveis de
  **ambiente** (UPPER_SNAKE: `DATABASE_URL`, `KNOWLEDGE_COMMIT_POLICY`); contrato de **wire**
  (`error_code`, nomes de evento SSE `token`/`tool_call`/…, `cd_quimera` = código externo).

## Banco (.specs/01-schema, SCHEMA_POSTGRES.md)
- Tabelas `tbl_` + **plural PT** (`tbl_demandas`, `tbl_execucoes`, `tbl_relacoes`). Views `vw_`/`vwm_`.
- **PK `id_<entidade> BIGSERIAL`**; **FK real `fk_<entidade> BIGINT`**.
- Prefixos de coluna: `id_` PK · `fk_` FK · `nm_` nome · `ds_` texto longo · `nr_` número · `cd_` código
  · `fl_` flag · `st_` status/enum · `vl_` valor · `dt_` data · `js_` jsonb · `vt_` vetor · `ig_` imagem.
- **Soft-delete `dt_exclusao`** (NULL = ativo); toda listagem filtra `dt_exclusao IS NULL`. Exceção:
  `tbl_execucoes`/`tbl_eventos_execucao` são imutáveis (sem soft-delete).
- Timestamps `dt_criacao`/`dt_atualizacao`; trigger `trg_set_dt_atualizacao`. Enums em **PT**
  (`status_demanda`, `status_triagem`, `status_curadoria`…). PK textual legível via `cd_slug`.
- Refs polimórficas (`tbl_relacoes`/`tbl_embeddings`): par `st_<x>_tipo` + `id_<x>` **sem FK** (exceção
  ADR-001). `tbl_embeddings` existe só no DDL — **dormente**, sem Model/produtor no código.

## API — RPC-PT (.specs/02-contratos)
- **Sem prefixo `/api/`**. Forma `{recurso-plural}/{verbo-acao}[/{idX}]`, verbo HTTP coerente:
  criar→POST, listar/obter→GET, **editar→PUT**, excluir→DELETE, ação→POST.
  Ex.: `POST /demandas/criar-demanda`, `PUT /agentes/editar-agente/{idAgente}`, `POST /triagem/triar-demanda/{idDemanda}`.
- Path params camelCase PT alinhados à PK (`{idDemanda}`).
- **DTOs** Pydantic v2: `CriarXDto` / `EditarXDto` / `XRespostaDto` (campos = colunas com prefixo).
- **Lista:** `{ itens, nr_total, nr_pagina, nr_por_pagina }`; query `nr_pagina`/`nr_por_pagina`/`ds_busca`.
- **Erro:** `{ error_code, ds_mensagem, js_detalhes? }` + status do mapa exception→HTTP.
- **SSE:** `GET /eventos/execucoes/{idExecucao}` (eventos em wire; replay `Last-Event-ID`).

## Camadas backend (.specs/03-estrutura)
`Controller → Service → Repository → Model`; DTOs Pydantic. Pacote `orquestrai`, pastas por camada
(`controllers/ services/ repositories/ models/ dtos/`) + `core/` (config, logging, exceptions, db, neo4j)
+ `runner/` (DriverCli, DriverApi, RoteadorModelo, ProjetorNeo4j, AgenteTriagem, AgenteCuradoria — **sem**
`ReembedderPgvector`, não existe) + `capacidades/` (storage/extração plugáveis) + `rag/` (chunking). Sem pular camadas.

## Frontend
- Componentes/arquivos **PascalCase PT** (`CartaoDemanda.tsx`, `BotaoPrimario.tsx`, `GrafoConhecimento3D.tsx`);
  props/estado/funções PT sem acento (`aoConfirmar`, `lista_demandas`). Libs em inglês (`useState`, `useQuery`).
- Tokens **CSS custom properties canônicas Finza** em `globals.css` (não inventar paleta).
- Server state `@tanstack/react-query`; client `zustand`; forms `react-hook-form`+`zod`; tipos via `openapi-typescript`.

## Resiliência (.specs/CONVENCOES §7)
- Logs JSON `structlog` (campos `id_execucao`/`evento`/`nivel`/`camada`/`timestamp`); sem `print`.
- Exceptions PT: `OrquestrAiErro` → `RecursoNaoEncontradoErro`/`ValidacaoErro`/`IntegracaoExternaErro`/`ConflitoErro`;
  handler mapeia exception→HTTP; nunca vazar `Exception` genérica.
- Fronteiras externas (MCP Quimera, projeção Neo4j, storage MinIO) com retry+backoff (`tenacity`), timeout,
  idempotência. (Embedding não é fronteira ativa hoje — dormente, sem código produtor.)
- Por camada: Repository trata persistência; Service decide retry; Controller só mapeia.

## Migrations & Commits
- Alembic **sempre reversível** (`downgrade`); migrations = fonte da verdade do schema físico (`.specs/01-schema/MIGRATIONS.md`).
- Commits `feat:`/`fix:`/`refactor:`/`docs:`/`test:`/`chore:` em PT-BR.
