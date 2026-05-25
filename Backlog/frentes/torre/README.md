# Frente — Torre de Controle

Itens relacionados à plataforma Torre de Controle v2 (SaaS multi-tenant de cobrança digital da Finza).

**Sponsor padrão:** Jéssica (Gerente Cobrança)
**ID prefix:** `BTR##`

## Prioridades atuais (22/05/2026)

1. **BTR02 — Implementação Multi-Org na Torre** · `urgente`. Iniciativa-mãe da frente. Habilita Rhino como originador e qualquer novo cliente sem reescrita por carteira. Absorve parcialmente o escopo do BTR06 (inteligência por carteira) via camada de conhecimento com filtros.
2. **BTR07 — Refatoração da Torre** · `alta`. Reescrita do backend Supabase → FastAPI + Postgres, refatoração de frontend, otimização de consultas, paralelismo nos disparos, processamento de fila com reprocessamento, tratamento de erros padrão enterprise, reflexão de informações do Módulo Financeiro. Item XL — precisa quebrar em refinement.
3. **BTR03, BTR04** — validação conjunta de dashboards e relatórios IA, prioridade `media`.
4. **BTR05 — RCS** · prioridade `baixa`, exploração de canal.

## Itens cancelados / removidos

- **BTR01** (Destravar ticket 1775) — removido em 22/05/2026. Era follow-up tático (não estratégico).
- **BTR06** (Inteligência específica por carteira) — `cancelado`. Arquitetura multi-org atual da Torre (RAG com `filter_definition_id` por carteira) já cobre o cenário. Itens residuais (escopo de filtro em Regras + UI de perfil + piloto) foram absorvidos como subtarefas internas do BTR02.

## Escopo geral

- Dashboards (5 abas: Executive, Operational, Workflows, AI, Attribution)
- Relatórios IA (gerenciais + operacionais)
- Multi-org: novos originadores (Rhino e futuros)
- Canais de comunicação (RCS, etc.)
- Refatoração arquitetural (backend, frontend, fila, observabilidade)
- Validação conjunta de cálculos e conceitos

## Contexto técnico

Detalhamento completo em `Backlog/contexto/torre_de_controle_overview.md`.

## Fora de escopo

- Configuração interna dos agentes IA (vão para Esperanza/Clara/Valentina/Lívia)
- Gatilhos HyperFlow puros (vão para frente Bitrix & Automações)
- Definição de processo do squad (vai para Estratégica)
