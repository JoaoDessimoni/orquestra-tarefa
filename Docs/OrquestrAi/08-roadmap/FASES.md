# Fases / Roadmap — OrquestrAI

> Sequência de releases com critérios de transição e escopo por fase. Última atualização: 20/05/2026.

## Fontes

- [BRIEFING.md](../BRIEFING.md)
- [ESCOPO_MVP.md](../01-requisitos/ESCOPO_MVP.md)
- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md)
- [INTEGRACOES.md](../02-arquitetura/INTEGRACOES.md) §2

---

## Visão consolidada

| Fase | Codinome | Foco | Tempo estimado |
|---|---|---|---|
| **P0** | MVP | Análises + Agentes + Streaming + Export | 3-4 semanas |
| **V1** | "Bibliotecário" | Importação, integrações leves, automações | 2-3 semanas |
| **V2** | "Multi" | Multi-tenant, deploy remoto, Quimera, mobile | 4-6 semanas |
| **V3+** | (TBD) | Conforme uso real revelar necessidade | — |

---

## P0 · MVP — "Cockpit pessoal"

### Objetivo
Entregar produto local funcional para 1 supervisor (João Vinícius) operar suas análises e relatórios com apoio de agentes Claude Code.

### Inclui (in-scope)

Tudo descrito em [ESCOPO_MVP §1](../01-requisitos/ESCOPO_MVP.md):

- Dashboard com KPIs de produção/gestão (hero "esta semana", barchart por prioridade/status, deadlines próximas)
- CRUD de Agentes (com modelo, tools, prompt, skills, subagentes)
- CRUD de Subagentes (variante de Agentes)
- CRUD de Skills
- Disparar Execuções
- Streaming em tempo real (SSE) com tokens + tool calls
- Histórico de execuções com filtros
- CRUD de Análises com vínculo a execuções
- CRUD de Relatórios derivados de Análise
- **CRUD de Pendências** (promovido em v2 — RF-PE)
- **CRUD de Reuniões** (promovido em v2 — RF-RU)
- **CRUD de 1on1s** (promovido em v2 — RF-OO)
- **Roadmap kanban** (promovido em v2; read-only no P0, CRUD em V1 — RF-RM)
- **Commands** read-only (promovido em v2; CRUD em V1 — RF-CM)
- Export `.md` para `Gestao/`
- Command Palette (Cmd+K)
- Settings
- docker-compose com 3 serviços

### Critérios de pronto

Todos os AC-01 a AC-10 do [ESCOPO_MVP §3](../01-requisitos/ESCOPO_MVP.md) passando.

### Excludes (out-of-scope MVP)

- Auth, multi-user
- Integração Quimera/Slack/e-mail
- Importação automática de `.claude/agents/`
- Geração assistida de Relatório
- Mobile/responsive

### Métricas de sucesso

| Métrica | Alvo |
|---|---|
| Tempo de setup novo (clone → app rodando) | <15 min |
| Tempo entre disparar execução e primeiro token | <2s |
| Uso semanal (João rodando análises) | ≥3 análises/semana após 2 semanas |
| Zero perda de dados após restart | 100% |

---

## V1 · "Bibliotecário" — Reuso e automação leve

### Objetivo
Acelerar criação de novo conteúdo aproveitando o histórico do supervisor e integrando com ferramentas usadas no dia.

### Inclui

- **Importação inicial de `.claude/agents/`** (RF-AG-09): bootstrap dos 8 agentes já documentados.
- **Importação de `Gestao/Analises/`** (RF-AN-07): popular DB com análises antigas.
- **Geração assistida de Relatório** (RF-RP-05): botão "✨ Gerar com agente" que dispara execução e preenche body_md.
- **Clonar Agente** (RF-AG-08).
- **Importação de Skill** a partir de `.claude/skills/`.
- **Tabela de uso de Skill** (RF-SK-05): mostra agentes vinculados.
- **Sparkline** em Dashboard (RF-DB-04).
- **Notificação Slack/e-mail** quando Relatório = `enviado`.
- **Editor markdown melhor** (TipTap ou similar).
- **Agendamento de execução recorrente** (cron-like) (RF-EX-10).
- **Replay realista** de stream (com delays proporcionais).
- **Cost dashboard**: gráficos de uso/custo por agente e período.

### Critérios para iniciar V1

- MVP rodando em produção (uso pessoal) há pelo menos 4 semanas.
- João identificou 3+ frustrações concretas que V1 resolve.
- Lista priorizada de features V1 validada.

### Estimativa
2-3 semanas (1 supervisor + 1 dev part-time).

---

## V2 · "Multi" — Compartilhamento e integração

### Objetivo
Permitir uso por outros supervisores Finza, conectar com Quimera, e suportar acesso fora da máquina pessoal.

### Inclui

- **Autenticação** (login básico → OAuth Google se necessário) (RNF-SG-02 expandido).
- **Multi-usuário** com isolamento básico (cada user vê seu workspace).
- **RBAC mínimo** (admin, user, viewer).
- **Integração Quimera** (V2 ENTRADA): pull issues como contexto de análise.
- **Integração Quimera** (V2 SAÍDA): push pendência → criar issue.
- **Deploy** (cloud privada ou self-hosted on-prem).
- **Compartilhamento de Relatório** via link (com auth).
- **Mobile/responsive** mínimo (read-only em mobile primeiro).
- **i18n** (PT-BR + EN).
- **Anthropic API direta** como alternativa ao Claude Code CLI (para uso server-side).

### Critérios para iniciar V2

- 2+ outros supervisores Finza interessados em adotar.
- Decisão estratégica de Finza sobre hospedar a ferramenta.
- Definição de papel ("ferramenta pessoal expandida" vs "produto Finza interno").

### Estimativa
4-6 semanas (time pequeno: 1 dev + 1 PM part-time).

### Riscos

- Migração de DB single-user → multi-tenant.
- Auth e segurança real (RNFs todos sobem em complexidade).
- Acoplamento com Quimera depende de API estável dele.

---

## V3+ · TBD

Não documentado intencionalmente. Decisões aqui dependem de:
- Como o uso real evoluir.
- Se Finza adotar como produto interno.
- Se Anthropic mudar o modelo do Claude Code.

Hipóteses possíveis (não-comprometidas):
- Hooks customizados via UI (MCP servers locais)
- Workflows multi-agente (pipelines)
- Métricas / observability avançada
- Plugins / marketplace de skills
- Custom LLMs (Bedrock, locais)
- Voice input / output

---

## Princípios para passagem de fase

1. **Não pular fases.** V1 só inicia quando MVP estiver maduro de fato.
2. **Validar com uso.** Cada fase precisa de uso real antes de planejar a próxima.
3. **Documentar decisões.** Todo "por quê" de feature/fora-de-escopo registrado nesta pasta.
4. **MVP é congelado.** Após corte do MVP, não adicionar feature: registra como V1 candidata.
5. **Refatoração estrutural só entre fases.** Não no meio.

---

## Histórico de revisões

| Versão | Data | Mudanças |
|---|---|---|
| v1 | 2026-05-20 | Roadmap inicial: P0/V1/V2 com escopo, critérios, estimativas |
| **v2** | **2026-05-21** | P0 expandido: módulos Pendências/Reuniões/1on1s/Roadmap/Commands promovidos a MVP. Justificativa: validado no protótipo BOARD.html v2 que CRUD genérico cobre tudo com custo marginal. Estimativa P0 ajustada para **~4-5 semanas** (vs 3-4 da v1) por conta dos novos módulos. |
