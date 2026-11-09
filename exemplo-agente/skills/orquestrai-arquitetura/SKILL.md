---
name: orquestrai-arquitetura
description: Arquitetura do OrquestrAi — Postgres (fonte única) + Neo4j (projeção de grafo) + MinIO (storage binário) local, mais Quimera via MCP; pgvector/embedding é decisão fechada mas DORMENTE (nada roda). Triagem hoje é FTS Postgres + grafo, não vetor. Pipeline de duas camadas + st_curadoria, runner CLI com driver plugável e roteamento de modelo, SSE. Fonte canônica .specs/ADR-001 e ADR-002.
---

# Arquitetura — OrquestrAi

Condensado de **`.specs/ADR-001`** (stores/ontologia/ingestão), **`.specs/ADR-002`** (embedding/token/
roteamento) e `OrquestrAi/02-arquitetura/*`. Os ADRs são autoridade e **substituem** o que conflitar
nas decisões antigas AD-01..AD-10.

## Stores locais (ADR-001 §D2 + ADR-004)
```
MÁQUINA LOCAL
├─ docker-compose → postgres (host 127.0.0.1:15432→5432, pgvector) + neo4j (:7474/:7687, community)
│                    + minio (:9000, storage binário) + api + web (compose sobe o stack inteiro;
│                    "api"/"web" no host só no Modo Local — ver ADR-003)
└─ claude code (CLI no host) ──MCP──> QUIMERA (externo)
```
- **Postgres = fonte única da verdade** (todo conteúdo + arestas em `tbl_relacoes` + metadado de arquivo).
- **Neo4j (grafo) = projeção derivada e reconstruível** — volume descartável, rebuild via
  `POST /grafo/reconstruir-grafo` (`runner/ProjetorNeo4j.reconstruir_total`).
- **pgvector = extensão instalada mas DORMENTE**: `vt_embedding`/HNSW existem no DDL (`tbl_embeddings`),
  mas sem Model/produtor no código; provider `bge_m3` seedado com `fl_ativo=false` e `fl_disponivel=false`.
  Nada gera embedding hoje.
- **MinIO = 3º store**, guarda o binário de arquivos (capacidade `storage`, ADR-004); o volume
  `orquestrai_miniodata` **não é reconstruível** a partir do Postgres — é 2º alvo de backup (Postgres
  guarda metadado + `cd_storage`; os bytes só existem no MinIO). "Backup = dump do Postgres" está incompleto.
- **Quimera** = sistema externo de demandas, via **MCP** agente-mediado; em conflito, **Quimera ganha**.

## Pipeline de ingestão — duas camadas (ADR-001 §D4)
- **Camada 1 — projeção estrutural:** todo write relevante → projeta nó/aresta no Neo4j. **Sem LLM,
  idempotente.** Projeta **só `st_curadoria='confirmada'`** (proposta/rejeitada nunca poluem a triagem);
  divergência resolve por **rebuild a partir do Postgres**. Re-embedar no pgvector é **alvo planejado**,
  não implementado (não existe `ReembedderPgvector`; hoje só projeta Neo4j).
- **Camada 2 — curadoria semântica:** agente de curadoria (com LLM) extrai propostas (`st_curadoria='proposta'`,
  `st_origem_dado='auto'`, confiança+proveniência) em eventos de ciclo de vida. Política `KNOWLEDGE_COMMIT_POLICY`:
  `human_in_loop` (fila) | `autonomous` (auto-commit ≥ `KNOWLEDGE_AUTO_COMMIT_THRESHOLD`).

## Triagem (feature central, J2)
Hoje é **FTS (full-text search `portuguese`) sobre Postgres**, não vetor: `RecuperacaoRepository` rankeia
candidatos em `tbl_features`/`tbl_regras_negocio`/`tbl_demandas` (`ts_rank`/`websearch_to_tsquery`, limiar
0.05, top_k 8) → contexto de grafo (Neo4j) **best-effort** (falha não bloqueia, marca `fl_contexto_parcial`)
→ o agente LLM decide: Feature `contempla` → cancela; Demanda `bloqueada_por` RegraNegocio → recusa
(**a Demanda é a origem da aresta**, não a regra); senão segue. Veredito nasce como proposta; confirmação
humana grava `st_triagem`. Vetor/pgvector como recuperação é decisão fechada (ADR-002) mas **não implementada**.

## Runner — driver plugável + roteamento (ADR-002 §D5.3)
- Driver default **CLI**: `claude -p --model <alias> --output-format stream-json` (**sem `--bare`** — carrega
  MCP do Quimera + skills); parser NDJSON → eventos canônicos → SSE + `tbl_eventos_execucao`. `DriverApi` previsto, fora do MVP.
- **Roteamento de modelo:** cadeado (`fl_modelo_travado`) > auto-route híbrido (heurística + classificador Haiku;
  viés de escalonamento; respeita `cd_modelo_minimo`) > default `st_modelo`. Grava `cd_modelo_usado`+`ds_motivo_modelo`.
- Embedding **BGE-m3 local, 1024 dims** (HNSW cosseno) — decisão fechada (ADR-002 §D5.1), **dormente**: sem código produtor.

## SSE — 7 eventos
`status` · `token` · `tool_call` · `tool_result` · `error` · `ping` (~15s) · `done` (encerra).
Formato `id:`/`event:`/`data:`; replay via `Last-Event-ID`; broker in-process (single worker no MVP).

## Reconciliação AD-01..AD-10 (histórico)
Mantidas: AD-01 monorepo · AD-03 SSE · AD-05 docker-compose · AD-06 single-user · AD-07 Tailwind ·
AD-08 tanstack-query · AD-09 soft-delete (`dt_exclusao`) · AD-10 snapshot de agente.
**Atualizadas pelos ADRs:** AD-02 "Postgres-only" → **Postgres fonte única + Neo4j (projeção) + MinIO
(storage); pgvector é projeção planejada, hoje dormente** (ADR-001, ADR-004);
AD-04 subprocess CLI → **driver plugável CLI/API** (ADR-002). Detalhe em `OrquestrAi/02-arquitetura/VISAO_GERAL §4.1`.
