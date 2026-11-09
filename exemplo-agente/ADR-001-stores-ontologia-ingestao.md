# ADR-001 — Modelo de dados, ontologia de conhecimento e pipeline de ingestão

> Architecture Decision Record consolidando as decisões **D2, D3 e D4** da Etapa 2.
> Status: **ACEITO** · Data: junho/2026 · Escopo: OrquestrAi MVP
> Depende de: `VISAO_PRODUTO_v2.md` (visão ratificada).
> Substitui, no que conflitar: docs marcados `REVISAR-ETAPA-2` em `STATUS_DOCS.md`.

> 🟡 **Nota de status (reconciliação C-docs):** a **projeção Postgres→Neo4j está implementada**
> (`runner/ProjetorNeo4j.py`, método `reconstruir_total`, acionado por `POST /grafo/reconstruir-grafo`
> — `controllers/GrafoController.py` → `GrafoService.py`). O **re-embedder Postgres→pgvector NÃO
> existe** e o **pgvector segue DORMANTE**: a dependência `pgvector` está declarada em
> `apps/api/pyproject.toml` mas nunca é importada em `apps/api/src/`; `tbl_embeddings` existe só como
> DDL cru (`0001_schema_inicial.py`), sem Model, sem INSERT/UPDATE e sem query vetorial; o índice HNSW
> `idx_embeddings_vetor` está órfão; o provider de embedding `bge_m3` foi seedado **não-vigente**
> (`fl_ativo=false` **e** `fl_disponivel=false` — casca dormente, `0010_plugins_capacidade.py`). A **triagem C8** recupera candidatos por **FTS
> `portuguese`** (`RecuperacaoRepository.py`, `to_tsvector`/`ts_rank` sobre `tbl_features`,
> `tbl_regras_negocio`, `tbl_demandas`) somada a contexto de grafo Neo4j best-effort, não por busca
> vetorial. A decisão **D2 segue válida como alvo** — só a metade vetorial (pgvector) não foi ativada;
> a metade de grafo (Neo4j) está em produção.

---

## Decisão D2 — Modelo de stores e fonte da verdade

### Contexto
A ferramenta usa quatro stores (Quimera externo, Postgres, Neo4j, pgvector). Era preciso definir quem é dono da verdade de quê, com requisito explícito de ser **durável, robusta e escalável**, single-user e 100% local (Neo4j Community via docker, não Aura).

### Decisão
**Modelo B — Postgres como fonte única da verdade; Neo4j e pgvector como projeções derivadas e reconstruíveis.**

| Store | Papel | Fonte da verdade de |
|---|---|---|
| **Quimera** (externo, via MCP) | Sistema oficial de demandas | Campos-core das demandas. Em conflito, **Quimera ganha** |
| **Postgres** | Espinha do sistema | **Todo o conteúdo e todas as relações** (entidades, conteúdo de conhecimento, arestas, enriquecimento de demanda) |
| **Neo4j** (Community, local) | Read-model de travessia | **Projeção derivada** do grafo — reconstruível a partir do Postgres |
| **pgvector** | Read-model de similaridade | **Projeção derivada** dos embeddings — reconstruível a partir do Postgres |

### Alternativa rejeitada
**Modelo A — Neo4j autoritativo para relações.** Rejeitado: cria dois donos da verdade, exige backup de dois stores, e torna as relações (que são decisões reais confirmadas) não-reconstruíveis em caso de corrupção do grafo. Incompatível com o requisito de robustez.

### Consequências
- **Backup = dump do Postgres.** Os volumes de Neo4j e pgvector são descartáveis/reconstruíveis.
  > 🟡 **Complemento posterior (ADR-004):** esta consequência ficou **incompleta** com a entrada do
  > MinIO. `orquestrai_miniodata` é o **segundo volume alvo de backup** e, ao contrário de Neo4j/pgvector,
  > **não é reconstruível** a partir do Postgres — o Postgres guarda o metadado e a chave do objeto, os
  > bytes vivem só no MinIO (perder o volume = perder o arquivo). A decisão D2 ("Postgres fonte única"
  > do relacional) segue válida e não é contradita; só a régua de backup mudou. Ver `.specs/ADR-004-plugins-capacidade.md`
  > §"MinIO é fonte da verdade dos binários".
- Existe um **projetor idempotente `Postgres → Neo4j`** — implementado (`runner/ProjetorNeo4j.reconstruir_total`,
  acionado por `POST /grafo/reconstruir-grafo`). O **re-embedder `Postgres → pgvector`** é **planejado
  (não implementado)** — ver nota de status no topo do documento.
- Custo aceito: as arestas vivem também em tabela relacional no Postgres (não só no grafo), e há um passo de projeção. Pago em troca de durabilidade e backup trivial.
- Qualquer divergência entre grafo e Postgres se resolve por **rebuild a partir do Postgres**, nunca o contrário.
  Hoje isso vale para **Neo4j**, via `POST /grafo/reconstruir-grafo`; a contraparte de rebuild vetorial
  (pgvector) é planejada, junto com o re-embedder.

---

## Decisão D3 — Ontologia-semente do grafo (schema-light)

### Contexto
O grafo precisa de estrutura suficiente para a triagem (dedup/recusa de demanda) funcionar via query consistente, sem engessar a evolução. Schema-free foi rejeitado (vira "sopa" não-consultável); schema rígido foi rejeitado (engessa).

### Decisão
**Ontologia-semente mínima e obrigatória; agentes enriquecem dentro dela; tipos novos só entram via adição confirmada pelo humano** (o portão da D4 garante isso de graça).

**Tipos de nó (7, travados para o MVP):**

| Label | É | Durável? |
|---|---|---|
| `Projeto` | Escopo/iniciativa temporária que envolve um ou mais produtos | não (temporário) |
| `Produto` | Sistema ou agente de IA sob responsabilidade do supervisor | **sim (ativo durável)** |
| `Demanda` | Pedido (espelho Quimera + enriquecimento) | — |
| `Feature` | Capacidade já entregue de um produto | sim |
| `RegraNegocio` | Regra que barra/condiciona demanda | sim |
| `Decisao` | Decisão técnica ou de negócio tomada | sim |
| `Pessoa` | Desenvolvedor do time | sim |

`Projeto` e `Produto` são **distintos**: produto é ativo durável, projeto é iniciativa temporária. Relação **M:N** (`Projeto -[ENVOLVE]-> Produto`).

**Arestas (semente):**

| Aresta | De → Para | Semântica |
|---|---|---|
| `ENVOLVE` | Projeto → Produto (M:N) | projeto escopa produtos |
| `É_DE` | Feature → Produto | feature é capacidade de um produto |
| `SOBRE` | Demanda → Produto | do que a demanda trata (definido na triagem) |
| `NO_ESCOPO_DE` | Demanda → Projeto (opcional) | demanda faz parte de uma iniciativa |
| `RESTRINGE` | RegraNegocio → Produto | regra que constrange um produto |
| `CONTEMPLA` | Feature → Demanda | **dedup**: demanda já atendida por algo existente |
| `BLOQUEADA_POR` | Demanda → RegraNegocio | **recusa**: demanda barrada por regra |
| `ORIGINOU` | Demanda → Feature | proveniência: demanda virou feature |
| `DESMEMBRA_EM` | Demanda → Demanda | quebra em sub-demandas |
| `DERIVA_DE` | Relatorio → Análise; Decisao → Análise | proveniência |
| `ATRIBUIDA_A` | Demanda → Pessoa | roteamento |
| `TEM_AFINIDADE` | Pessoa → Produto | roteamento por afinidade |

> 🟢 **A coluna "De → Para" é enforçada em código** (C-hardening): transcrita em
> `dominio/Ontologia.DIRECAO_ARESTA` e validada em `RelacaoService.aplicar_criacao` — par que não casa
> com o `st_tipo` é rejeitado (422 na criação manual, descarte com log na saída de agente). Antes disso
> a direção existia só neste documento, e `ProjetorNeo4j` reproduzia no grafo qualquer inversão gravada.
> Duas ressalvas: `DESMEMBRA_EM` é homogênea (o mapa valida tipos, não distingue mãe de filha) e
> `DERIVA_DE` segue inexequível (`Análise`/`Relatorio` não estão entre os 7 tipos de nó e não têm
> repository de resolução). Tabela de pares no contrato: `.specs/02-contratos/conhecimento.md §2.1`.
> Ressalva adicional: `dominio/Enums.py` (`TipoEntidade`) tem **9** valores em código — `projeto,
> produto, demanda, feature, regra_negocio, decisao, pessoa, analise, relatorio` —, contra os **7** nós
> travados nesta seção. `analise` e `relatorio` existem no enum mas não têm resolvedor em
> `RelacaoService._resolvedores` (`dominio/Ontologia.py` já registra essa lacuna), o que é exatamente o
> que sustenta a ressalva de `DERIVA_DE` acima: a aresta está mapeada na ontologia, mas não é
> exequível hoje porque os dois tipos de nó que ela liga não têm caminho de resolução no código.

**Propriedades comuns de nó (na projeção Neo4j):** `id` (= id do Postgres), `tipo`, `titulo`, `projeto_id`/`produto_id`, `status`, `origem` (humano/auto), `confirmado_em`.

### Fluxo de triagem (razão de ser do grafo)

**Fluxo real (hoje, sem pgvector):**
```
Nova demanda D
  -> FTS 'portuguese' (to_tsvector/ts_rank, RecuperacaoRepository) recupera candidatos em
     tbl_features, tbl_regras_negocio, tbl_demandas (limiar 0.05, top_k 8, cap 30; Decisao excluida
     de proposito)
  -> contexto adicional de grafo: Cypher best-effort no Neo4j (Feature/RegraNegocio ativas do produto);
     qualquer exceção devolve {} e marca fl_contexto_parcial=true
  -> agente de triagem decide, com os candidatos + contexto de grafo:
       existe Feature que ja CONTEMPLA equivalente?  -> CANCELA (ja existe)
       D casa com RegraNegocio via BLOQUEADA_POR?     -> RECUSA (nao pode)
       senao                                          -> SEGUE -> roteia por TEM_AFINIDADE
```

**Fluxo-alvo (quando o re-embedder pgvector ligar — planejado, não implementado):**
```
Nova demanda D
  -> embedding(D) -> pgvector retorna Features/Demandas semanticamente proximas
  -> sobre os candidatos, no grafo:
       existe Feature que ja CONTEMPLA equivalente?  -> CANCELA (ja existe)
       D casa com RegraNegocio via BLOQUEADA_POR?     -> RECUSA (nao pode)
       senao                                          -> SEGUE -> roteia por TEM_AFINIDADE
```
Vetor acha o **parecido**; grafo confirma o **vínculo**. Essa combinação continua sendo o design-alvo
da triagem; hoje a metade "vetor" está substituída por FTS lexical.

### Consequências
- Roteamento por afinidade = consulta sobre `SOBRE` (demanda→produto) + `TEM_AFINIDADE` (pessoa→produto). O módulo Equipe é essencialmente essa query.
- `Topico` e `Reuniao` ficam **fora** da semente; entram depois via adição confirmada, se a dor aparecer.
- **Regra de coerência de arestas (onde cada relação mora no Postgres):** relações **entre entidades de conhecimento** — `TEM_AFINIDADE`, `SOBRE`, `CONTEMPLA`, `BLOQUEADA_POR`, `RESTRINGE`, `ORIGINOU`, `DESMEMBRA_EM`, `DERIVA_DE`, `ATRIBUIDA_A`, `É_DE`, `NO_ESCOPO_DE` — são linhas em `tbl_relacoes` (polimórfica, sujeita a `st_curadoria`, projetável pro Neo4j). Já relações **estruturais/de composição** da organização — `ENVOLVE` (projeto↔produto), Time↔Projeto, Time↔Agente — vivem em **tabelas de junção próprias** (`tbl_projetos_produtos`, `tbl_times_projetos`, `tbl_times_agentes`); o projetor as lê para o grafo, mas a verdade fica na junção, **não** em `tbl_relacoes`. Consequência: afinidade Pessoa→Produto é uma aresta `TEM_AFINIDADE` em `tbl_relacoes` (criada por humano ⇒ `st_origem_dado='humano'`, `st_curadoria='confirmada'`; remoção = **desativação** via `dt_desativacao` + `ds_motivo_desativacao` obrigatório — a aresta permanece projetada no grafo, marcada `fl_ativo=false`). A coluna `nr_confianca` é **reusada como peso da afinidade** (0..1) nessas arestas; em propostas de curadoria automática mantém o sentido original de confiança.

---

## Decisão D4 — Pipeline de ingestão e modelo de autonomia

### Contexto
A retroalimentação precisa manter a estrutura sempre coerente com a fonte da verdade **sem** estourar a economia de token (NFR nº1) e **sem** encher o grafo de ruído. Houve risco de juntar duas operações distintas num único "gatilho por CRUD".

### Decisão
**Duas camadas distintas:**

| Camada | Dispara em | Faz | LLM? | Confirmação |
|---|---|---|---|---|
| **1 · Projeção estrutural** | todo write relevante (POST/PUT/DELETE) no Postgres | sincroniza nó/aresta no Neo4j; re-embeda no pgvector se o conteúdo mudou | **Não** | nenhuma (dado já autoritativo) |
| **2 · Curadoria semântica** | eventos de ciclo de vida (demanda concluída/cancelada/recusada, análise publicada, criação manual) | agente de curadoria extrai conhecimento novo tipado e enfileira proposta | **Sim** | conforme política de commit |

**Agente de curadoria dedicado:** trabalha de forma autônoma até a beira do commit — lê o trabalho concluído, extrai nós/arestas já tipados conforme a ontologia-semente, liga aos nós existentes, mantém a fila de propostas atualizada. **Não** decide sozinho o que vira verdade no modo default.

**Modelo de autonomia — pipeline único, política comutável:**
- Toda proposta carrega `score de confiança` + `proveniência` (execução, agente, fonte).
- Política de commit (`KNOWLEDGE_COMMIT_POLICY`):
  - `human_in_loop` (**default — Modo B**): nada commita sozinho; tudo vai à fila de confirmação humana.
  - `autonomous` (**Modo A — comutável no Settings**): proposta `>= KNOWLEDGE_AUTO_COMMIT_THRESHOLD` auto-commita (marcada `origem: auto`); abaixo do limiar, cai na fila humana.
- Todo conhecimento carrega `origem` (humano/auto) + rastro de auditoria, e é **desativável de forma reversível** (`dt_desativacao` + `ds_motivo_desativacao` obrigatório; reativar limpa ambos).
- **Desativar/reativar conhecimento confirmado** também passa pelo portão (apagar verdade é decisão). Hard-delete (remoção física) fica para uma etapa futura (C7c) e só se aplica a item já desativado.

**Estado de curadoria e filtro de projeção (Etapa 3):** cada artefato curável (features, regras de
negócio, decisões e relações) carrega um estado `st_curadoria` ∈ {`proposta`, `confirmada`, `rejeitada`}
(default `confirmada` no caminho humano; o agente de curadoria cria como `proposta`). **A Camada 1
projeta para Neo4j/pgvector somente linhas `st_curadoria='confirmada'`, independentemente de
desativação** — `proposta` e `rejeitada` nunca são projetadas, logo **nunca poluem a triagem**.
`rejeitada` é estado terminal próprio (a linha permanece para auditoria; não é desativação). Um nó/
aresta **desativado** (`dt_desativacao` preenchido) **permanece projetado** no grafo, marcado
`fl_ativo=false` + `ds_motivo_desativacao`; ele só some da consulta de triagem se a query
explicitamente filtrar `fl_ativo=true`. **Só o hard-delete (C7c) remove** o item do grafo. `dt_confirmacao`
marca a virada para `confirmada`.

### Alternativas rejeitadas
- **Curadoria (LLM) em todo CRUD:** rejeitado — estoura token, enche o grafo de ruído, inutiliza o portão humano.
- **Agente autônomo sem guardrails:** rejeitado — drift envenena a triagem sem rastro nem reversão.

### Consequências
- Modos A e B compartilham o mesmo pipeline (sem código duplicado); a diferença é uma config.
- A Camada 2 é o **maior consumidor de LLM** do sistema → alvo principal da D5 (RAG seletivo + cache).
- Auditabilidade e reversibilidade ficam garantidas por design (alinhado ao padrão enterprise de rastreabilidade).

---

## Apêndice — Referência de implementação (insumo para a Etapa 3)

> Nível conceitual. O layout exato de tabelas é **decisão da Etapa 3 (schema)**.

**Estruturas relacionais implícitas no Postgres:**
- Entidades de primeira classe (com campos próprios ricos): `projetos`, `produtos`, `demandas` (espelho Quimera + enriquecimento), `pessoas`.
- Artefatos de conhecimento: `features`, `regras_negocio`, `decisoes` — table-per-type vs tabela polimórfica `conhecimento` é **questão aberta da Etapa 3**.
- `relacoes` (arestas, polimórfica): `tipo`, `origem_tipo`/`origem_id`, `destino_tipo`/`destino_id`, `origem` (humano/auto), `confianca`, `execucao_id`, `confirmado_em`, `created_at`, desativação. *(Nomes conceituais; o físico canônico usa prefixos PT — `st_tipo`, `st_origem_tipo`/`id_origem`, `st_origem_dado`, `nr_confianca`, `fk_execucao`, `dt_confirmacao`, `dt_criacao`, `dt_desativacao` + `ds_motivo_desativacao` — ver `.specs/01-schema/DDL.sql` `tbl_relacoes`.)*
- `embeddings` (pgvector): `alvo_tipo`, `alvo_id`, `vector`, `modelo`, `created_at`. *(Estado real: a
  tabela existe apenas como DDL — `0001_schema_inicial.py` — sem Model nem produtor; único toque é um
  `DELETE` defensivo em `RelacaoRepository.remover_incidentes`, sempre 0 linhas hoje.)*

**Projeções derivadas:**
- `Postgres -> Neo4j`: projetor idempotente (upsert de nós a partir das entidades; upsert de arestas a
  partir de `relacoes`). **Implementado** — `runner/ProjetorNeo4j.py`.
- `Postgres -> pgvector`: re-embedder disparado em mudança de conteúdo. **PLANEJADO** — não implementado.
- Comando de **rebuild total** do Neo4j e do pgvector a partir do Postgres. Estado real: existe **só
  para Neo4j**, como endpoint HTTP `POST /grafo/reconstruir-grafo` (não há CLI/script de rebuild); a
  parte de pgvector é planejada, junto com o re-embedder.

**Configurações (identificadores em inglês, conforme padrão):**
- `KNOWLEDGE_COMMIT_POLICY` = `human_in_loop` (default) | `autonomous`
- `KNOWLEDGE_AUTO_COMMIT_THRESHOLD` = float 0.0–1.0 (usado só em `autonomous`)

**Pipeline (Camada 2):**
```
evento de ciclo de vida
  -> agente de curadoria le o trabalho concluido
  -> extrai nos/arestas candidatos (tipados pela ontologia-semente) + confianca + proveniencia
  -> politica de commit:
       human_in_loop -> fila de confirmacao (voce aprova/edita/rejeita)
       autonomous    -> >= limiar: commit (origem=auto) · < limiar: fila
  -> commit no Postgres (autoritativo)
  -> Camada 1 projeta para Neo4j + pgvector (idempotente)
```

---

## Decisões abertas remanescentes da Etapa 2
- **D5** — Economia de token (RAG seletivo, prompt cache, sumarização) + escolha do modelo de embedding.
- **D6** — Contrato do runner (CLI plugável).
- **D7** — Sync Quimera (agente-mediado vs sistêmico; resolução de conflito).
- **D8** — Modelo de execução de Time (orquestrador/supervisor).
