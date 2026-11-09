# ADR-002 — Embedding, economia de token e roteamento de modelo

> Consolida a decisão D5 e a parte runner da D6. Status: ACEITO · Junho/2026.
> Depende de ADR-001, CONVENCOES, VISAO_PRODUTO_v2.

> 🟡 **Nota de status (reconciliação C-docs):** o **roteamento de modelo** (D5.3) está implementado
> (`runner/RoteadorModelo.py` + `ClassificadorModelo.py`). O **pgvector/embedding permanece DORMANTE** —
> não há `ReembedderPgvector` no código. A **triagem (C8)** recupera candidatos por **FTS `portuguese`**
> (índices GIN em features/regras/decisoes/demandas), não por vetor. A decisão de embedding segue válida
> como alvo; só ainda não foi ativada.

## D5.1 — Modelo de embedding
Decisão: BGE-m3 local, 1024 dimensões. Roda localmente (sentence-transformers ou Ollama).
Custo R$0, dado não sai da máquina, qualidade sólida em PT-BR. Como o embedding é projeção
derivada (ADR-001 §D2), é reconstruível a partir do Postgres — trocar de modelo depois é
re-embeddar, sem perda. Fixa a dimensão do índice pgvector em 1024 (índice HNSW recomendado).
Rejeitado/adiado: embedding via API (OpenAI/Voyage) — adiciona vendor + chave + custo;
reversível se a qualidade local decepcionar.

> **Status MVP (C7a):** No MVP não há modelo de embedding em uso — não há modelo local rodando e a
> Anthropic não oferece API de embedding. O `pgvector` permanece no schema porém **vazio** no MVP.
> A recuperação para triagem usará **FTS (Postgres) + grafo (Neo4j) + raciocínio do agente**, sem
> busca vetorial. O provider de embedding é **decisão a fechar antes do C8**; quando definido,
> re-embeda a partir do Postgres (projeção derivada — ADR-001 §D2), sem perda.

## D5.2 — Estratégia de economia de token
Maiores consumidores: agente de curadoria (Camada 2) e triagem. Alavancas:
1. RAG seletivo (pgvector top-K + limiar) — recupera só o relevante, nunca despeja o grafo.
2. Sumarização hierárquica — nó guarda resumo curto (recuperação) + corpo completo (sob demanda).
3. Prompt cache — preâmbulo estável (ontologia, instruções, skill) reaproveitado.
4. Roteamento de modelo por tarefa (ver D5.3).
5. Embedding local — R$0 na indexação.
Princípio: economia sempre subordinada à precisão ("R$ com precisão").

## D5.3 — Roteamento de modelo (runner CLI)
Mecânica: a api spawna `claude -p --model <alias> --output-format stream-json` (NÃO usar
`--bare`, pra carregar o MCP do Quimera + skills). Modelo selecionável por execução via `--model`.
Ordem de resolução: (1) cadeado ligado → modelo travado; (2) auto-route → classificador;
(3) default do agente (cd_modelo).
Auto-route = híbrido (Opção C): heurística resolve os óbvios sem custo; classificador Haiku só
no meio-termo. Viés de escalonamento: na dúvida, sobe de modelo.
Defesas: viés de escalonamento; cadeado como override soberano; proveniência registrada
(modelo escolhido + motivo, na execução); piso de modelo por agente.
Tiers: Haiku 4.5 (barato) · Sonnet 4.6 (médio) · Opus 4.8 (complexo).

## Impactos no schema (aplicar)
- pgvector: dimensão = 1024 (remover placeholder); índice HNSW.
- tbl_agentes: + cd_modelo_minimo (piso), + fl_modelo_travado (cadeado).
- tbl_execucoes: + cd_modelo_usado, + ds_motivo_modelo (proveniência do roteamento).
- tbl_configuracoes: chaves EMBEDDING_MODEL=bge-m3, EMBEDDING_DIM=1024, AUTO_ROUTE_ENABLED + tiers.

## Decisões ainda abertas
D6 contrato detalhado do runner (parte decidida aqui), D7 sync Quimera, D8 coordenação de Time.
