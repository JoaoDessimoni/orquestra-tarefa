---
name: orquestrai-contexto
description: Contexto de produto do OrquestrAi (visão v2) — cockpit local single-user que orbita o Quimera; triagem de demanda como feature central, conhecimento em grafo, projetos/times/equipe. Condensado de VISAO_PRODUTO_v2.md + ADR-001.
---

# Contexto do OrquestrAi (visão v2)

Condensado de **`OrquestrAi/VISAO_PRODUTO_v2.md`** + `.specs/ADR-001`. Para o detalhe, ler os docs-fonte.

## Posicionamento
**Cockpit pessoal single-user (só o João)** que orbita o **Quimera** (Jira interno da Finza, plataforma
oficial de demandas). O Quimera manda nas demandas; o OrquestrAi é a muleta de raciocínio, memória e
orquestração de agentes Claude Code em volta delas. Conecta o João às ferramentas externas **via MCP**,
acumula conhecimento de longo prazo em **grafo**, e usa esse conhecimento para **triar e refinar demandas**.

## Solução (o loop central)
Demanda entra (meet transcrita / Quimera / pedido solto) → sincroniza com Quimera (Quimera ganha) →
**triagem** contra o conhecimento → SEGUE / CANCELA / RECUSA → análise/relatório → roteia ao dev →
tarefa concluída + confirmação humana → retroalimenta o grafo (curadoria).

## Feature central — Triagem (J2, "feature-assassina")
Cruza a demanda nova com o conhecimento acumulado: hoje a recuperação de candidatos é **FTS (Postgres,
`portuguese`)** — vetor/pgvector é decisão fechada (ADR-002) mas ainda **dormente**, não implementada.
O grafo (Neo4j) complementa com contexto best-effort. Feature `contempla` → **cancela** (já existe);
Demanda `bloqueada_por` RegraNegocio → **recusa** (a Demanda é a origem da aresta); senão **segue** →
roteia por afinidade.

## Conceitos
- **Conhecimento em grafo:** nós (Projeto, Produto, Demanda, Feature, RegraNegocio, Decisao, Pessoa) +
  arestas tipadas; Postgres é fonte única, Neo4j é projeção (grafo); pgvector é projeção de similaridade
  **planejada, ainda dormente**. Curadoria com humano no loop por padrão (`human_in_loop`); modo
  `autonomous` comutável.
- **Projeto ≠ Produto:** produto é ativo durável; projeto é iniciativa temporária (M:N `ENVOLVE`).
- **Times de agentes** atuam em projetos (M:N). **Aparato Claude Code** (agentes/subagentes/skills/hooks/
  commands/MCPs) gerenciável por tela.
- **Equipe = roteador:** perfis de dev com afinidades; roteamento = `SOBRE` (demanda→produto) × `TEM_AFINIDADE` (pessoa→produto).
- **Análise** (investigação + execuções insumo) → **Relatório** (saída dupla `.md` + `.html`).

## Persona (única)
**João Vinícius** — Supervisor do squad IAF Finza. Técnico-direto, usa Claude Code diariamente. Opera o
sistema como cockpit pessoal; a squad humana **não** usa o produto — é gerenciada por ele.

## Não-objetivos
Não substitui o Quimera. Sem multi-usuário/auth/RBAC/cloud/mobile no MVP. Sem ingestão de conhecimento
sem rastro (curadoria com proveniência + auditoria + soft-delete reversível). Não reimplementa tool-use/turnos (é do Claude Code).

## Princípios travados
1. Economia de token **com precisão** (RAG seletivo + cache + embedding local — embedding é decisão
fechada, ainda dormente). 2. Humano no loop para a
verdade (default). 3. Quimera é fonte da verdade das demandas. 4. Runner **CLI-first, plugável**. 5. Grafo
**schema-light** (ontologia-semente). 6. Liberdade de configuração. 7. Local, single-user, dockerizado.
8. PT-BR sem acento em identificadores; ver `orquestrai-padroes`.

> **Flag:** os ACs e o `ESCOPO_MVP.md` em `01-requisitos/` ainda refletem o produto antigo (sem
> triagem/demandas/grafo) — a visão v2 acima prevalece; reconciliação dos ACs fica para um passo futuro.
