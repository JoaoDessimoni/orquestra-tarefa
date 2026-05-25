# BRIEFING — OrquestrAI

> Briefing executivo do produto. Documento vivo, atualizado a cada decisão estrutural. Última atualização: 20/05/2026.

## Fontes

- Conversa de design com João Vinícius (Supervisor IAF Finza), 20/05/2026
- `Docs/BRIEFING.md` (workspace gerencial)
- `Docs/finza/CONTEXTO-FINZA.md`
- `BOARD.html` (protótipo visual em uso)

---

## 1 · Problema

O Supervisor IAF da Finza coordena um squad técnico e gera, semanalmente, **análises e relatórios** — investigações pontuais, cruzamentos de dados, devolutivas para stakeholders. Hoje esse trabalho é manual:

- Coleta de informação espalhada (Slack, e-mail, Quimera, planilhas).
- Redação artesanal de cada relatório, mesmo quando o formato é repetível.
- Sem rastreio de quais análises geraram quais decisões.
- Sem reuso: cada análise é tratada como artefato único, sem template ou contexto persistente.

Existe também uma **oportunidade técnica** subaproveitada: o Claude Code CLI roda local com licença pessoal e pode executar agentes especializados (research, drafting, review), mas é trabalhoso configurar cada novo agente via arquivo no `.claude/agents/` do workspace.

## 2 · Solução

**OrquestrAI** é um sistema enterprise pessoal local que:

1. **Persiste** análises e relatórios em Postgres com relações explícitas (análise → relatórios derivados, análise → pendências relacionadas).
2. **Configura agentes via tela** — o usuário cria Agentes, Subagentes e Skills no browser, salvando prompts, modelo (`opus`/`sonnet`/`haiku`), ferramentas habilitadas e relações.
3. **Executa agentes** disparando subprocess do Claude Code CLI local sobre o workspace do supervisor (`Repasse/`), com streaming do output em tempo real para o browser via SSE.
4. **Exporta para `.md`** em `Gestao/` quando necessário, mantendo compatibilidade com o workspace `.claude/` atual (slash commands, board-updater, etc.).

## 3 · Não-objetivos (MVP)

- **Não substitui o Quimera.** Pendências de demanda do squad continuam no Quimera.
- **Não tem multi-usuário.** Single-user, sem auth real, sem RBAC.
- **Não roda na nuvem.** Localhost only. Sem deploy fora da máquina pessoal.
- **Não integra com Slack/e-mail/Quimera no MVP.** Roadmap V1+.
- **Não tem mobile.** Desktop browser only.

## 4 · Personas

Único usuário no MVP: **João Vinícius**, Supervisor IAF Finza. Detalhes em [01-requisitos/PERSONAS.md](01-requisitos/PERSONAS.md).

## 5 · Casos de uso prioritários (P0)

1. **CRUD de Agente.** Criar agente "Pesquisador de fatos Finza" via tela, com prompt customizado, modelo Sonnet 4.6, ferramentas Read+Grep+Glob, vinculado à Skill "Contexto Finza".
2. **Execução com streaming.** Disparar esse agente sobre o workspace `Repasse/` e ver tokens chegando em tempo real, com tool calls visualizadas inline.
3. **Histórico de execução.** Consultar execuções passadas (output completo, duração, custo estimado, tool calls).
4. **CRUD de Análise.** Criar uma análise, anexar agentes executados sobre ela, derivar relatórios.

## 6 · Arquitetura (resumo)

```
┌────────────┐   REST + SSE   ┌────────────┐   subprocess   ┌──────────────┐
│  Next.js   │ ─────────────▶ │  FastAPI   │ ─────────────▶ │  claude code │
│  (browser) │ ◀───────────── │ (uvicorn)  │ ◀───────────── │     CLI      │
└────────────┘                └────────────┘                └──────────────┘
                                    │ SQLAlchemy
                                    ▼
                              ┌──────────────┐
                              │  Postgres 16 │
                              └──────────────┘
```

Detalhe em [02-arquitetura/VISAO_GERAL.md](02-arquitetura/VISAO_GERAL.md).

## 7 · Decisões travadas

| # | Decisão | Implicação |
|---|---|---|
| 1 | Local-only, single-user | Sem auth, sem rede pública, volume Docker local |
| 2 | Subprocess Claude Code CLI | Reusa licença do usuário; FastAPI gerencia processos filhos |
| 3 | Postgres é fonte da verdade | `Gestao/` .md é export; sem sync bidirecional |
| 4 | Visual Linear/Notion-like | Light theme, denso, Cmd+K, accent Finza blue |
| 5 | Modelo de agentes hierárquico | Agente + Subagentes + Skills (espelha Claude Code) |
| 6 | Streaming via SSE | Eventos tipados (token, tool_call, status, error, done) |

## 8 · Estado atual

- **Documentação**: esta pasta (`Docs/orquestrAi/`).
- **Protótipo visual**: `BOARD.html` (raiz do Repasse) sendo refatorado para refletir as telas do produto.
- **Código**: ainda não existe. Bootstrap previsto após validação desta especificação.

## 9 · Histórico de versões

| Versão | Data | Mudanças |
|---|---|---|
| v1 | 2026-05-20 | Documentação inicial completa; decisões travadas; BOARD.html refatorado como protótipo visual (light Linear-style) |
| **v2** | **2026-05-21** | (a) BOARD.html volta à paleta **canônica Finza** (sidebar dark, cards dotted, ghost h1, ◆ iaf marker, hero-dark). (b) Bootstrap embute dados reais de `Gestao/` (26 pendências, 3 reuniões, 2 análises, 1 relatório, 24 roadmap) e `.claude/` (9 agentes, 3 skills, 10 commands). (c) CRUD funcional com localStorage para 8 entidades. (d) Dashboard reformulado com foco em produção e gestão (hero "esta semana", KPIs de pendências/reuniões/análises, barchart por prioridade e status, deadlines próximas, atalhos rápidos). (e) Módulos Pendências/Reuniões/1on1s/Roadmap/Commands **promovidos a MVP**. (f) Docs em `Docs/OrquestrAi/` sincronizados com o redesign (TOKENS, COMPONENTES, DASHBOARD, MAPA_NAVEGACAO + 5 novos docs de tela + schema Postgres ampliado + RFs novos). |
