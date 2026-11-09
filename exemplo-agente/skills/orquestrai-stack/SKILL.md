---
name: orquestrai-stack
description: Stack técnica travada do OrquestrAi — frontend Next.js, backend FastAPI em camadas, 3 stores locais (Postgres fonte única, Neo4j projeção de grafo, MinIO storage binário); pgvector/embedding BGE-m3 1024 é decisão fechada mas DORMENTE (sem código produtor). Runner Claude Code CLI plugável, infra docker-compose. Condensado de STACK_TECNICO.md + ADR-002.
---

# Stack técnica — OrquestrAi

Condensado de `OrquestrAi/02-arquitetura/STACK_TECNICO.md` + `.specs/ADR-002`. Versões evoluem; o doc-fonte é canônico.

## §1 Frontend — `apps/web/`
Next.js 14 (App Router) · TypeScript 5.4+ · Tailwind 3.4+ · zustand 4.5+ · @tanstack/react-query 5.x ·
react-hook-form+zod · react-markdown · fuse.js · react-hotkeys-hook · lucide-react · sonner ·
openapi-typescript · vitest+RTL. Componentes **PascalCase PT** (`CartaoDemanda`, `GrafoConhecimento3D`).

## §2 Backend — `apps/api/`
FastAPI 0.115+ · uvicorn · pydantic 2.7+ · SQLAlchemy 2 async · alembic · asyncpg · sse-starlette ·
**neo4j** (driver async) · structlog · pydantic-settings · tenacity (retry) · pytest+pytest-asyncio+httpx · ruff/mypy.
Pacote **`orquestrai`**, em camadas (ver `.specs/03-estrutura/ESTRUTURA_API.md`).

## §3 Stores (3 locais — ADR-001 §D2 + ADR-004)
- **Postgres 16 + pgvector** (`pgvector/pgvector:pg16`; host `127.0.0.1:15432`→container `:5432`) —
  **fonte única**. Extensão pgvector instalada, `vt_embedding vector(1024)` + índice **HNSW** cosseno
  existem no DDL (`tbl_embeddings`), mas **dormentes**: sem Model/produtor no código, provider `bge_m3`
  seedado com `fl_ativo=false`/`fl_disponivel=false`.
- **Neo4j Community** (`neo4j:5-community`, :7474 HTTP / :7687 Bolt) — **projeção de grafo** (read-model, descartável).
- **MinIO** (`minio/minio`, :9000) — **storage binário** (capacidade `storage`, ADR-004); não é reconstruível a partir do Postgres.
- Quimera = externo (via MCP), não é store local.

## §4 Embedding & Runner (ADR-002)
- Embedding **BGE-m3 local, 1024 dims** — decisão fechada (sentence-transformers/Ollama; R$0; dado não
  sai da máquina), mas **dormente**: nenhum código gera embedding hoje; triagem usa FTS Postgres.
- Runner driver **plugável** (CLI default / API futuro). CLI: `claude -p --model <alias> --output-format stream-json` (**sem `--bare`**).
- Roteamento de modelo: cadeado > auto-route híbrido > default. Tiers Haiku 4.5 / Sonnet 4.6 / Opus 4.8.

## §5 Infraestrutura
`docker-compose v2`. **Compose sobe o stack inteiro** (`postgres`+`neo4j`+`minio`+`api`+`web`, mais
`test` sob profile). No **Modo Local** (`USO_LOCAL=true`, uso diário — ADR-003), `api`/`web` rodam no
host mesmo assim (runner CLI precisa do terminal real); o serviço `api` do compose fica com
`USO_LOCAL=false` fixo e só responde CRUD (sem executar agente — Modo Servidor real é trabalho futuro, C6d).
Volumes: `pgdata` (backup), `neo4jdata` (descartável), `miniodata` (2º alvo de backup, binário não
reconstituível); binds `../Repasse:/workspace/Repasse:ro` e `../Repasse/Gestao` (rw).
Healthchecks: `pg_isready`, Neo4j `:7474`, HTTP `api`/`web`. Tudo em `127.0.0.1`.

## Estrutura `apps/api/` (camadas — `.specs/03-estrutura`)
```
apps/api/src/orquestrai/
├── Main.py · core/{Configuracoes,BancoDados,Neo4j,Logging,Excecoes,ManipuladorExcecoes,Dependencias}.py
├── dominio/Enums.py
├── controllers/  (DemandaController.py, TriagemController.py, CuradoriaController.py, …)
├── services/     (DemandaService.py, TriagemService.py, CuradoriaConhecimentoService.py, …)
├── repositories/ (DemandaRepository.py, RelacaoRepository.py, …)
├── models/       (DemandaModel.py, RelacaoModel.py, Base.py, …)   → mapeiam tbl_*
├── dtos/         (DemandaDto.py [Criar/Editar/Resposta], Comuns.py)
├── capacidades/  (Contratos.py, Resolvedor.py, StorageMinio.py, ExtracaoLibLocal.py)
├── rag/          (Chunker.py, BlocoTrechos.py)
└── runner/       (Driver.py, DriverCli.py, DriverApi.py, RoteadorModelo.py, ClassificadorModelo.py,
    ProjetorNeo4j.py, AgenteTriagem.py, AgenteCuradoria.py, BrokerSse.py; sem ReembedderPgvector — não existe)
alembic/{env.py,versions/} · tests/{unit,integration}
```

## Estrutura `apps/web/`
```
apps/web/app/(dashboard)/{dashboard,demandas,triagem,projetos,times,agentes,subagentes,skills,mcps,
  execucoes,analises,relatorios,conhecimento,equipe,reunioes,pendencias,roadmap,settings}/
components/{ui,layout,command-palette,stream-viewer,markdown-editor,markdown-viewer,grafo}/
lib/{api,hooks,stores}/ · styles/globals.css · tailwind.config.ts
```
