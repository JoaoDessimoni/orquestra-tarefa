# OrquestrAI — Documentação técnica

> Documentação de produto e engenharia do **OrquestrAI**, ferramenta enterprise pessoal local para análises, relatórios e orquestração de agentes Claude Code. Última atualização: 20/05/2026.

## Fontes

- `Docs/BRIEFING.md` (workspace gerencial Finza)
- `Docs/finza/CONTEXTO-FINZA.md`, `PLATAFORMAS.md`
- `BOARD.html` (protótipo visual em uso)
- Conversas de design com o usuário (João Vinícius, Supervisor IAF Finza)

---

## O que é o OrquestrAI

Sistema **local, single-user, dockerizado**, que roda na máquina do supervisor e cumpre três papéis:

1. **Banco analítico** — registra análises, relatórios e suas relações.
2. **Estúdio de agentes** — permite criar/configurar agentes Claude Code (com subagentes e skills) por tela, sem editar arquivo.
3. **Cockpit de execução** — dispara agentes via subprocess do Claude Code CLI local e mostra o streaming em tempo real no browser.

**Não substitui o Quimera** (Jira interno da Finza). É braço complementar: o Quimera continua sendo a ferramenta primária para gestão de demandas do time. O OrquestrAI cuida do trabalho **investigativo e de saída** (relatórios, análises) e da **automação inteligente** via agentes.

---

## Stack

| Camada | Tecnologia |
|---|---|
| Frontend | Next.js 14 (App Router) + TypeScript + Tailwind |
| Backend | FastAPI + SQLAlchemy 2 + Alembic + asyncio |
| Banco | Postgres 16 |
| Runner | Claude Code CLI (subprocess) |
| Orquestração local | docker-compose |

Detalhes em [02-arquitetura/STACK_TECNICO.md](02-arquitetura/STACK_TECNICO.md).

---

## Como navegar nesta documentação

Os documentos seguem uma ordem **funcional**, do mais conceitual ao mais executável. Recomendado ler na ordem se for a primeira vez:

| Ordem | Pasta | O que tem |
|---|---|---|
| 1 | [BRIEFING.md](BRIEFING.md) | Visão de 1 página: problema, solução, escopo |
| 2 | [01-requisitos/](01-requisitos/) | Personas, escopo MVP, RFs e RNFs numerados |
| 3 | [03-dominio/](03-dominio/) | Glossário, schema Postgres, regras de negócio |
| 4 | [02-arquitetura/](02-arquitetura/) | Visão geral, stack, execução de agentes, streaming, integrações |
| 5 | [07-design-system/](07-design-system/) | Tokens (paleta, tipografia) e componentes |
| 6 | [04-telas/](04-telas/) | Mapa de navegação + spec de cada tela |
| 7 | [05-api/](05-api/) | Endpoints REST/SSE e contratos Pydantic |
| 8 | [06-infra/](06-infra/) | docker-compose, estrutura do repo, .env, setup |
| 9 | [08-roadmap/](08-roadmap/) | Fases (MVP → V1 → V2) |

---

## Convenções desta documentação

- **Sem frontmatter YAML.** Cada doc começa com `# Título` + linha de contexto + seção `## Fontes`.
- **Tom técnico-executivo.** Frases curtas. Sem jargão de consultoria.
- **Datas absolutas** (`2026-05-20`, nunca "hoje").
- **TODOs marcados** como `<!-- TODO: confirmar com gestor -->` quando incerto.
- **Tabelas** para listas longas (RFs, endpoints, env vars).
- **ASCII diagrams** para fluxos e ER.
- **Nomes de arquivo**: `UPPERCASE_COM_UNDERSCORE.md` (segue padrão de `Docs/finza/`).

---

## Estado da documentação

| Pasta | Status | Última revisão |
|---|---|---|
| README.md | ✅ completo (v2) | 2026-05-21 |
| BRIEFING.md | ✅ completo (v2) | 2026-05-21 |
| 01-requisitos/ | ✅ completo + RFs novos (PE/RU/OO/RM/CM) | 2026-05-21 |
| 02-arquitetura/ | ✅ completo | 2026-05-20 |
| 03-dominio/ | ✅ completo + 5 tabelas novas | 2026-05-21 |
| 04-telas/ | ✅ completo + 5 docs novos (Pendências, Reuniões, 1on1s, Roadmap, Commands) | 2026-05-21 |
| 05-api/ | ✅ completo | 2026-05-20 |
| 06-infra/ | ✅ completo | 2026-05-20 |
| 07-design-system/ | ✅ paleta canônica Finza (v2) | 2026-05-21 |
| 08-roadmap/ | ✅ P0 expandido (v2) | 2026-05-21 |

**Telas documentadas em `04-telas/`:**
- MAPA_NAVEGACAO.md
- DASHBOARD.md (foco produção/gestão)
- AGENTES.md
- SUBAGENTES.md
- SKILLS.md
- EXECUCOES.md
- ANALISES.md
- RELATORIOS.md
- COMMAND_PALETTE.md
- SETTINGS.md
- **PENDENCIAS.md** (novo v2)
- **REUNIOES.md** (novo v2)
- **ONE_ON_ONES.md** (novo v2)
- **ROADMAP.md** (novo v2)
- **COMMANDS.md** (novo v2)

---

## Próximos passos (após esta documentação)

1. Validar com o usuário se a especificação está completa para entrar em desenvolvimento.
2. Bootstrap do repositório novo (`orquestr-ai/`) seguindo [06-infra/ESTRUTURA_REPO.md](06-infra/ESTRUTURA_REPO.md).
3. Implementar P0 do roadmap (ver [08-roadmap/FASES.md](08-roadmap/FASES.md)).
