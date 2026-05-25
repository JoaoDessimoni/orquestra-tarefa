# Glossário — OrquestrAI

> Termos do domínio. Toda doc deste repositório deve usar exatamente estes termos. Última atualização: 20/05/2026.

## Fontes

- [BRIEFING.md](../BRIEFING.md)
- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md)
- Convenções herdadas do workspace `.claude/agents/` Finza

---

## Entidades primárias

### Agente

Unidade configurável invocável pelo usuário. Tem **prompt do sistema**, **modelo Claude** (`opus`/`sonnet`/`haiku`), **ferramentas habilitadas** (Read, Edit, Write, Grep, Glob, Bash, WebSearch, WebFetch), e pode ter **Skills** e **Subagentes** vinculados.

Equivalente conceitual: um arquivo `.md` em `.claude/agents/` do Claude Code workspace.

### Subagente

Tecnicamente é um **Agente com flag `is_subagent=true`**. A diferença é semântica: subagentes são pensados para serem invocados *por outros agentes*, e não diretamente pelo usuário. Listagem em tela separada para clareza, mas modelo de dados é unificado.

Equivalente conceitual: agentes em `.claude/agents/` que outros agentes referenciam via `subagent_type:`.

### Skill

Bloco de **conhecimento reutilizável** em markdown, vinculável a Agentes. Carrega no contexto da execução para o agente operar com base mais sólida.

Equivalente conceitual: `.claude/skills/<nome>/SKILL.md` no Claude Code.

### Execução

Uma **invocação concreta** de um Agente. Persiste:
- Snapshot do prompt do agente no momento da execução (versão imutável)
- Input do usuário
- cwd usado
- Todos os eventos (token, tool_call, tool_result, error, done) — ver [STREAMING_SSE.md](../02-arquitetura/STREAMING_SSE.md)
- Output final
- Métricas (duração, custo estimado, tokens, tool call count)
- Status (`running`, `done`, `error`, `aborted`, `unknown`)

### Análise

Documento de **investigação** com pergunta, contexto e conclusão. Pode ter:
- **Execuções vinculadas** como insumos (resultado de agentes que pesquisaram para a análise)
- **Relatórios derivados** como saída

Tipos: `investigacao`, `comparativo`, `rfc`, `postmortem`, `proposta`, `cruzamento`.
Status: `rascunho`, `revisao`, `publicada`.

### Relatório

Documento **derivado de uma Análise** para um **destinatário específico**, com **classificação** de confidencialidade.

Status: `rascunho`, `revisao`, `enviado`.
Classificação: `interno`, `restrito`, `publico`.

---

## Entidades de suporte

### Evento de execução (execution_event)

Cada item da timeline de uma Execução. Tipos: `status`, `token`, `tool_call`, `tool_result`, `error`, `done`.

### Setting

Par chave-valor de configuração single-user. Chaves: `workspace_path`, `default_model`, `export_path`, `pricing_table`, etc.

### Pricing table

Tabela local (JSON em Settings) que mapeia `(modelo, tipo_token)` → `usd_por_1k_tokens`, usada para estimar custo da Execução. Não influencia execução real.

---

## Termos de processo

### Disparar uma execução

Ato do usuário: clicar "Executar" em um Agente, fornecendo input + cwd. Backend cria Execução em DB, marca `status=running`, spawna subprocess Claude Code, abre stream SSE para o browser.

### Abortar uma execução

Botão "Stop" no detalhe da execução em andamento. Backend envia SIGTERM ao subprocess, aguarda 5s, manda SIGKILL se necessário. Status vira `aborted`.

### Exportar

Gerar arquivo `.md` em `../Gestao/` (do workspace pai do OrquestrAI) a partir de Análise ou Relatório, com frontmatter compatível com workspace `.claude/`.

### Importar

(V1+) Ler `.md` existente em `Gestao/` e criar registro correspondente no DB. Resolve conflitos por slug.

### Workspace

A pasta de trabalho do usuário onde o Claude Code roda como subprocess. No setup MVP é `/workspace/Repasse` dentro do container, montado do host onde o `Repasse/` real está.

---

## Termos visuais (do design system)

### Sidebar
Painel lateral esquerdo, fixo, com navegação primária. Densidade alta, off-white (`#FAFAFA`).

### Topbar
Faixa superior do main com breadcrumb, busca global e atalho Cmd+K.

### Command Palette (Cmd+K)
Overlay invocado por `Cmd+K`/`Ctrl+K`. Combina navegação, ações rápidas e busca fuzzy.

### View
Cada seção navegável da sidebar (Dashboard, Agentes, Subagentes, Skills, Execuções, Análises, Relatórios, Settings).

### Card
Container de bloco de informação. Bordas sólidas `1px solid #E8E8EC`, hover com ring sutil.

### Empty state
Estado de view sem dados. Inclui ilustração SVG simples, texto explicativo, e CTA para criar primeiro item.

### Toast
Notificação efêmera (canto inferior direito, 3s). Tipos: `info`, `success`, `warning`, `error`.

---

## Termos NÃO usados aqui

Para evitar confusão:

| Termo evitado | Por quê | Use no lugar |
|---|---|---|
| "Bot" | Conota chatbot conversacional | Agente |
| "Workflow" | Vago, evoca BPMN | Execução ou Análise (com execuções) |
| "Plugin" | Conota módulo carregável dinamicamente | Skill |
| "Pipeline" | Pode confundir com CI/CD | Execução (de Agente) |
| "Dashboard de monitoramento" | Implica observabilidade de prod | Dashboard (do produto) |
| "Ticket" / "Issue" | Vocabulário Quimera, não OrquestrAI | Análise (se interno) |
| "Tenant" | Não tem multi-tenancy no MVP | — (não usar) |
