# 18 · Telas de Agentes de IA

> Documento de referência funcional do módulo **Agentes de IA** da Torre de Controle (repositório `cobranca-finza`), escrito para que um redesenho da interface possa ser feito **sem perder nenhuma funcionalidade**.
> Tudo aqui foi extraído da leitura do código-fonte. Onde o código não permite concluir com segurança, há uma marcação `⚠️ A confirmar:`.
> Caminhos de arquivo são relativos à raiz do repositório `cobranca-finza`.

---

## 0. Resumo do domínio

### 0.1 Telas e rotas

| Tela / Aba | Rota | Arquivo-fonte principal | Permissão |
|---|---|---|---|
| Galeria de agentes | `/agent-ia` | `src/pages/AgentGalleryPage.tsx` | Rota: `agent-ia:read`. Escrita (criar/renomear/status): `agent-ia:write`. Excluir: papel `owner`/`admin`. |
| Tags da organização | `/agent-ia/tags` | `src/pages/AgentTagsPage.tsx` | Rota: `agent-ia:read`. Escrita: `agent-ia:write` (**não** exige `settings:write` dentro da área de IA). |
| Workspace do agente | `/agent-ia/:agentId` | `src/pages/AgentWorkspace.tsx` | Rota: `agent-ia:read`. Escrita: `agent-ia:write`. |
| → Aba **Versões** | `/agent-ia/:agentId?tab=versions` | `src/components/ia/VersionManager.tsx` | leitura `agent-ia:read`; ações `agent-ia:write` |
| → Aba **Personalidade** | `?tab=personality` | `src/components/ia/PersonalityEditor.tsx` | `agent-ia:write` para editar |
| → Aba **Diretrizes** | `?tab=guidelines` | `src/components/ia/GuidelinesEditor.tsx` | `agent-ia:write` |
| → Aba **Regras** | `?tab=rules` | `src/components/ia/BusinessRulesBuilder.tsx` | `agent-ia:write` |
| → Aba **Prompts** | `?tab=prompts` | `src/components/ia/PromptEditor.tsx` | `agent-ia:write`; o **Prompt Base** (`general`) exige papel `owner`/`admin` |
| → Aba **Funil** (sub-aba Funil) | `?tab=funnel&funnel=stages` | `src/components/ia/FunnelStagesConfig.tsx` | `agent-ia:write` |
| → Aba **Funil** (sub-aba Tags de Transferência) | `?tab=funnel&funnel=transfer-tags` | `src/components/ia/TransferTagsConfig.tsx` | `agent-ia:write` |
| → Aba **Tags** | `?tab=tags` | `TagCatalogTab` + `src/components/ia/AgentAllowedTagsConfig.tsx` | `agent-ia:write` |
| → Aba **Playground** | `?tab=playground` | `src/components/ia/AIPlayground.tsx` | leitura livre; **Configurações do webhook** só para papel `owner` |
| → Aba **Conversas** | `?tab=conversations` (+ `?interaction=`) | `src/components/ia/ConversationLogs.tsx` | `agent-ia:read` |
| → Aba **Conhecimento** (RAG) | `?tab=knowledge` | `src/components/agent-ia/KnowledgeBase.tsx` | leitura `agent-ia:read`; upload/reprocessar/excluir `agent-ia:write` |
| → Aba **Métricas** | `?tab=metrics` | `src/components/ia/AgentMetrics.tsx` | `agent-ia:read` |
| Diálogo **Integração N8N** | dentro do workspace (Dialog) | `src/components/ia/AgentN8NIntegration.tsx` | visível a quem abre o workspace; fechamento A2A só `owner`/`admin` |

Fonte das rotas: `src/App.tsx` (linhas 422–425) — a rota **estática** `/agent-ia/tags` é declarada **antes** de `/agent-ia/:agentId` de propósito, senão `"tags"` seria interpretado como um `agentId`.

### 0.2 Componentes do domínio (inventário completo)

| Arquivo | Papel |
|---|---|
| `src/components/ia/AgentSelectorBar.tsx` | Troca rápida de agente + "Novo Agente" + menu de ações, no cabeçalho do workspace |
| `src/components/ia/AgentFormDialog.tsx` | Diálogo único de **criar/renomear** agente (nome, descrição, tipo) |
| `src/components/ia/AgentActionsMenu.tsx` | Menu "⋯" do agente (Abrir, Renomear, Padrão, Ativar/Inativar/Arquivar, Excluir) + confirmação de status |
| `src/components/ia/AgentDeleteDialog.tsx` | Exclusão lógica (tombstone) com preflight, impacto e confirmação por slug |
| `src/components/ia/agent-deletion-blockers.ts` | Mensagens por código de bloqueio da exclusão |
| `src/components/ia/AgentAllowedTagsConfig.tsx` | Whitelist de tags de conversa **por agente** (modo `all`/`restricted`) |
| `src/components/ia/AgentN8NIntegration.tsx` | Identificadores (`agent_slug`, `agent_id`) + headers obrigatórios + card A2A |
| `src/components/ia/A2AClosureSettingsCard.tsx` | Fechamento automático de protocolos A2A (webhook, cadência, observabilidade, teste) |
| `src/components/ia/PersonalityEditor.tsx` | Nome do agente, tom de voz, avatar (upload/URL), criação da v1 |
| `src/components/ia/PromptEditor.tsx` | Prompts por cenário (Base + cenários livres), temperatura, tamanho da resposta |
| `src/components/ia/PromptTextarea.tsx` | Editor rico com autocomplete de variáveis `{{...}}` + `PromptPreview` |
| `src/components/ia/GuidelinesEditor.tsx` | Diretrizes por categoria (Tom, Compliance, Escalação, Negociação) |
| `src/components/ia/BusinessRulesBuilder.tsx` | Regras SE→ENTÃO com filtros e ação |
| `src/components/ia/FunnelStagesConfig.tsx` | Etapas do funil (drag-and-drop, ícone, cor, webhook, ação automática) |
| `src/components/ia/TransferTagsConfig.tsx` | Catálogo de tags de transferência do agente + troca de tipo com vigência |
| `src/components/ia/VersionManager.tsx` | Tabela de versões: publicar, duplicar, restaurar, excluir |
| `src/components/ia/FilterSelector.tsx` | Seleção de filtros (AND/OR) usada nas Regras de Negócio |
| `src/components/ia/InfoTooltip.tsx` | Popover "i" com modos único ou dual (Negócio × Técnica) |
| `src/components/ia/MetricSectionBoundary.tsx` | Estados transversais de seção de métrica (loading/empty/error/unavailable/stale) + `ChartDataTable` |
| `src/components/ia/MetricsFiltersBar.tsx` | Toolbar sticky de período, filtros de protocolo, granularidade, relatório |
| `src/components/ia/ProtocolDateFilter.tsx` | Filtro de intervalo para criação do protocolo / última interação |
| `src/components/ia/InteractionFilterToggle.tsx` | Recorte Todas / Humano / A2A + `InteractionBadge` |
| `src/components/ia/DashboardAgentSelector.tsx` | Dropdown "Todos os agentes" usado pelo Dashboard |
| `src/components/ia/SelectedContractContextCard.tsx` | Card somente-leitura do contrato real escolhido no Playground |
| `src/components/ia/AIPlayground.tsx` | Playground de testes (chat + histórico + prompt compilado) |
| `src/components/ia/PlaygroundComposer.tsx` | Composer multiline (Enter envia, Shift+Enter quebra) |
| `src/components/ia/PlaygroundContextSelector.tsx` | Origem dos dados (real/fictício), busca de contrato, campos do contexto |
| `src/components/ia/PlaygroundHistory.tsx` | Lista paginada de sessões anteriores |
| `src/components/ia/PlaygroundSettingsDialog.tsx` | Webhook de envio, modo de resposta, timeout, campos do contexto, webhook de resposta, cURL |
| `src/components/ia/playground-context.ts` | Tipos/helpers puros do contexto do playground |
| `src/components/ia/playground-turn.ts` | Máquina de estados do turno do playground |
| `src/components/ia/ConversationLogs.tsx` | Aba Conversas: lista de protocolos + modal de transcrição |
| `src/components/ia/ConversationMessage.tsx` | Bolha de mensagem (cliente/agente) + mídias + metadados |
| `src/components/ia/ConversationFilters.tsx` | Filtros de período, tags e etapa do funil |
| `src/components/ia/ProtocolConversationList.tsx` | Lista de protocolos (uma linha por atendimento) |
| `src/components/ia/AgentMetrics.tsx` | Orquestrador da aba Métricas (snapshot canônico × dashboard legado) |
| `src/components/ia/AiPerformanceSnapshotDashboard.tsx` | Dashboard do snapshot canônico |
| `src/components/ia/snapshot-sections/*` | Seções do snapshot (KPIs, transferências, atividade, ciclo de vida, tags, funil, sentimento, A2A, invariantes) |
| `src/components/ia/charts/*` | Kit visual canônico de gráficos (tendência, composição, ranking, funil, tags, A2A, primitivos) |
| `src/components/ia/AgentCallsMetricsSection.tsx` / `AgentCallsOverviewSection.tsx` | Chamadas A2A: detalhe de um agente × correlação entre agentes |
| `src/components/ia/FunnelMetricsSection.tsx` / `FunnelSankeyView.tsx` | Funil legado (trapezoidal em CSS) e Sankey de drop-off |
| `src/components/ia/TagMetricsSection.tsx` | Evolução das tags no tempo + `TagRankingList` |
| `src/components/ia/TransferMetricsSection.tsx` / `TransferOverviewSection.tsx` | Transferências por evento: detalhe do agente × comparativo entre agentes |
| `src/components/ia/TransferDrilldownPanel.tsx` | Drawer de drill-down das transferências + modal de conversa |
| `src/components/ia/TransferSummaryKpis.tsx` | Bloco "Transferências para humano" (protocol-level) |
| `src/components/ia/TransferTimeSeriesChart.tsx` | Série temporal com toggle Por tipo / Por tag |
| `src/components/ia/TransferReasonNote.tsx` | Nota inline com o motivo da transferência |
| `src/components/ia/InteractionBreakdownSection.tsx` | Humano × A2A + `NotApplicableSection` |
| `src/components/ia/AiReportExportButton.tsx` | Botão "Gerar relatório" (HTML) com gates |
| `src/components/ia/AutoDraftWrapper.tsx` | Copy-on-write: visualizar publicada, criar rascunho para editar |
| `src/components/agent-ia/KnowledgeBase.tsx` + `RagUploadForm` + `RagDocumentList` + `RagQueryTester` | Base de conhecimento (RAG) |
| `src/lib/agent-workspace-url.ts` | Estado das abas na URL, abas por tipo de agente, recorte de interação |
| `src/lib/ai-metrics/metric-catalog.ts` | Catálogo canônico de métricas |
| `src/types/ai.ts` | Tipos, enums e dicionários de rótulo do domínio |

---

## 1. Objetivo e personas

### 1.1 O que este módulo faz

O módulo de Agentes de IA é onde a organização **configura, testa, audita e mede** os agentes de inteligência artificial que atuam na operação de cobrança. Ele não executa a conversa — a execução acontece em um agente externo (n8n / WhatsApp / Hyperflow). A Torre é a **fonte de verdade da configuração** (prompts, diretrizes, regras, funil, tags, base de conhecimento) e o **repositório de telemetria** (protocolos, mensagens, transferências, funil, tags, chamadas A2A).

Texto exibido na própria galeria (`src/pages/AgentGalleryPage.tsx`):

> "Gerencie os agentes de cobrança da organização. Clique em um agente para configurá-lo."
> Empty state: "Configure um assistente inteligente para automatizar suas negociações de cobrança via WhatsApp."

### 1.2 Personas identificáveis pelo código

| Persona | Papel RBAC | O que faz no módulo | Evidência |
|---|---|---|---|
| **Operador / analista** | `viewer`, `operator` (com `agent-ia:read`) | Lê conversas, acompanha métricas, gera relatório (se a flag permitir) | Guard de rota `agent-ia:read` em `src/App.tsx` |
| **Configurador do agente** | `manager`/`admin` com `agent-ia:write` | Cria agente, edita personalidade, diretrizes, regras, funil, tags, RAG, publica versões | `hasPermission("agent-ia:write")` em `AgentWorkspace.tsx`, `RagUploadForm.tsx` |
| **Administrador da organização** | `owner`, `admin` | Exclui agente (tombstone), edita o Prompt Base (`general`), configura fechamento A2A | `currentRole === "owner" \|\| "admin"` em `AgentActionsMenu.tsx`, `PromptEditor.tsx`, `A2AClosureSettingsCard.tsx` |
| **Owner da organização** | `owner` | Configurações do Playground (webhook de envio/resposta, timeout, campos) | `const isOwner = currentRole === "owner"` em `AIPlayground.tsx` |
| **Integrador (n8n)** | — (consome a API) | Copia `agent_slug`/`agent_id` e os headers; recebe o payload do webhook; devolve `request_id`/`session_id` | `AgentN8NIntegration.tsx`, `PlaygroundSettingsDialog.tsx` |

### 1.3 Princípios de produto que a UI atual materializa

Estes princípios estão **escritos no código** e precisam sobreviver ao redesenho:

1. **Falha nunca vira zero.** Erro de cálculo renderiza um bloco de erro com "Tentar novamente", nunca `0` ou `—` silencioso (`MetricSectionBoundary.tsx`, `SectionErrorState`).
2. **"Não se aplica" ≠ "sem dados".** Agente interno não tem funil nem transferência; a seção some ou vira `Não se aplica` em vez de mostrar zeros (`NotApplicableSection`, `SECTION_STATUS_LABELS.not_applicable`).
3. **Toda métrica declara unidade e janela.** Nenhum número aparece rotulado genericamente como "Transferências" sem dizer se conta protocolos ou eventos (`metric-catalog.ts`, `MetricChartHeader`).
4. **Dado inconsistente é omitido, não publicado.** Invariante do servidor reprovada bloqueia a seção com diagnóstico (`ChartInconsistentState`).
5. **Estado de tela vive na URL.** Aba, sub-aba e recorte de interação são deep-linkáveis (`src/lib/agent-workspace-url.ts`).
6. **Nada destrutivo em um clique.** Trocar status, excluir agente, excluir tag e remover URL de webhook passam por confirmação com impacto declarado.
7. **Sem autosave.** Nenhum editor do workspace salva sozinho — o banner do rascunho diz isso explicitamente (`DraftEditingBanner`).

---

## 2. Modelo mental do domínio

Esta seção define o vocabulário. O redesenho **não pode fundir** conceitos distintos listados aqui.

### 2.1 Entidades

| Conceito | Definição operacional | Onde vive | Fonte |
|---|---|---|---|
| **Agente** (`AIAgent`) | Unidade de configuração da IA da organização. Tem `id`, `name`, `slug`, `description`, `status`, `agent_type`, `is_default`, `allowed_tags_mode`, `deleted_at`. Uma org tem N agentes e exatamente 1 `is_default`. | `org_{slug}.ai_agents` | `src/types/ai.ts` L60–87 |
| **Tipo de agente** (`AIAgentType`) | `conversational` → rótulo **"Agente Externo"** ("Fala direto com o cliente"); `internal` → **"Agente Interno"** ("Fala direto com a equipe interna"). O valor técnico no banco continua `conversational`/`internal`. | idem | `AI_AGENT_TYPE_LABELS`, `src/types/ai.ts` L149–158 |
| **Status do agente** (`AIAgentStatus`) | `active` → "Ativo" (badge `default`); `inactive` → "Inativo" (`secondary`); `archived` → "Arquivado" (`outline`). | idem | `AI_AGENT_STATUS_LABELS`, L140–144 |
| **Versão** (`AIVersion`) | Snapshot versionado da configuração do agente: `version` (string numérica), `name`, `description`, `status`, `agent_name`, `agent_avatar_url`, `agent_tone`, `playground_config`, `published_at`. | `ai_versions` | `src/types/ai.ts` L347–361 |
| **Status da versão** (`AIVersionStatus`) | `draft` → "Rascunho"; `published` → "Publicado"; `archived` → "Arquivado". Publicar um rascunho **arquiva automaticamente** a versão publicada anterior. | idem | `VersionManager.tsx` L61–70, L166 |
| **Protocolo** | Identidade de **um atendimento**. É a unidade padrão das métricas de IA. Um protocolo tem status (`em_andamento`, `transferido`, `finalizado`), pode ser `is_a2a`, e agrega mensagens. | `ai_protocols` / `ai_protocol_status_log` | `AgentMetrics.tsx`, `ConversationLogs.tsx` |
| **Conversa** (`conversation_id`) | Agrupador legado = telefone + dia. **Não** é o mesmo que protocolo: dois atendimentos no mesmo dia e telefone compartilham `conversation_id`. | `actions_interaction_logs` | `ProtocolConversationList.tsx` (cabeçalho do arquivo) |
| **Mensagem** | Unidade individual trocada. A fonte **canônica** é `ai_messages` (por `occurred_at`); a base legada é `actions_interaction_logs` (por `created_at`). | `ai_messages` | `SentimentSection.tsx` (rodapé), `METRIC_DEFINITIONS.messageActivity` |
| **Transferência** | Passagem do atendimento para um humano. Tem dois tipos: **Transbordo** (`overflow`, vermelho `#EF4444`, "A IA não conseguiu resolver e transferiu (falha)") e **Transferência** (`transfer`, verde `#22C55E`, "Transferência por motivo correto/esperado"). Sem tipo → **Não classificado** (`unclassified`, cinza `#9CA3AF`). | `ai_funnel_events` | `useTransferMetrics.ts` L898–908; `TransferTagsConfig.tsx` `TYPE_META` |
| **Transbordo** | Subtipo de transferência: falha da IA. Sai do funil sozinho nas métricas de acurácia. | idem | `TransferSummaryKpis.tsx` (tooltip técnico) |
| **Etapa de funil** (`AIFunnelStage`) | Estágio que o agente percorre e notifica: `stage_key` (slug imutável), `stage_name`, `description`, `is_active`, `notify_webhook`, `auto_action`, `auto_action_config`, `display_order`, `icon`, `color`. | `ai_funnel_stages` | `src/types/ai.ts` L450–464 |
| **Tag de conversa / intenção** (`tag_catalog`) | Catálogo **da organização**. Dois tipos: `conversation` → "Conversa" ("Classifica a conversa (padrão)") e `intent` → "Intenção" ("Marca uma intenção detectada"). Tags de sistema (`is_system`) não podem ser editadas/excluídas. | `tag_catalog` | `TagCatalogTab.tsx` L152–168 |
| **Whitelist de tags do agente** | `allowed_tags_mode` = `all` (catálogo inteiro) ou `restricted` (somente as marcadas — **pode ser zero**, que é diferente de `all`). | `agent_allowed_tags` + `ai_agents.allowed_tags_mode` | `src/types/ai.ts` L49–54; `AgentAllowedTagsConfig.tsx` |
| **Tag de transferência** | Catálogo **do agente** (não da org). Tem `slug` (imutável, usado pelo n8n), `label`, `description`, `color`, `is_active`, e um **tipo vigente** com histórico de vigência. | `transfer_tags` | `TransferTagsConfig.tsx` |
| **A2A** (agent-to-agent) | Chamada/conversa **entre agentes**, derivada de `ai_protocols.is_a2a`. Um protocolo A2A é atendimento entre agentes; um protocolo humano é `is_a2a=false`. Ausente/`null` = humano. | `ai_protocols.is_a2a`, `agent_call_logs` | `src/lib/agent-workspace-url.ts` L163–206 |
| **RAG** | Base de conhecimento: documentos (JSON/PDF/Word/Excel) indexados em chunks vetoriais, com visibilidade opcional por filtro. | `rag_documents` / chunks | `KnowledgeBase.tsx`, `RagUploadForm.tsx` |
| **Snapshot de performance** | Objeto imutável (`get_ai_performance_snapshot_v1`) que alimenta **tela e relatório com os mesmos números**. Nenhum componente recalcula fórmula localmente. | RPC | `metric-catalog.ts` cabeçalho; `AgentMetrics.tsx` L428–434 |

### 2.2 Relações que importam para o layout

```
Organização
 ├─ tag_catalog (tags de conversa/intenção)  ── compartilhado por TODOS os agentes
 └─ Agente (N)
     ├─ agent_allowed_tags  (whitelist sobre o tag_catalog)
     ├─ transfer_tags       (catálogo PRÓPRIO do agente)
     ├─ ai_funnel_stages    (etapas, escopadas por agente)
     ├─ rag_documents       (conhecimento, escopado por agente)
     ├─ a2a_closure_settings (só para agent_type = internal)
     └─ Versão (N)
         ├─ personality  (agent_name, agent_tone, agent_avatar_url)
         ├─ ai_guidelines
         ├─ ai_business_rules
         ├─ ai_prompts (por cenário)
         └─ playground_config
```

### 2.3 Vocabulário de status de seção de métrica

`SECTION_STATUS_LABELS` (`supabase/functions/_shared/ai-report/view-model.ts` L124–135) — **estes textos aparecem literalmente na tela**:

| Status | Rótulo exibido | Significado |
|---|---|---|
| `success` | **OK** | Seção calculada normalmente |
| `empty` | **Sem dados no período** | Cálculo rodou, resultado vazio |
| `error` | **Erro ao calcular** | Falha técnica — nunca vira zero |
| `unavailable` | **Indisponível** | Recurso indisponível (≠ vazio) |
| `not_applicable` | **Não se aplica** | Não pode haver dado (funil/transferência em agente interno) |
| `partial` | **Parcial (só agentes externos)** | Número válido, alcance menor que o pedido |

Motivo padrão do `not_applicable` (`NOT_APPLICABLE_REASON`, L150–151):

> "Este agente é interno: ele atende outros agentes e não transfere para atendimento humano nem percorre etapas de funil. Os números foram omitidos de propósito — zero aqui afirmaria que nunca transferiu."

---

## 3. Galeria de agentes (`/agent-ia`)

Arquivo: `src/pages/AgentGalleryPage.tsx`.

### 3.1 Anatomia da tela

```
┌──────────────────────────────────────────────────────────────────────┐
│ HERO (rounded-xl, border, gradiente primary/5 → background, p-6)     │
│  [ícone Bot 48px em caixa arredondada]                               │
│  H1 "Agentes de IA"                                                  │
│  p  "Gerencie os agentes de cobrança da organização. Clique em um    │
│      agente para configurá-lo."                                      │
│                       … à direita (empilha em <sm) …                 │
│                       [Tags da organização] (outline, lg, ícone Tag) │
│                       [Criar Agente]        (primary, lg, ícone +)   │
└──────────────────────────────────────────────────────────────────────┘

GRID de cards: 1 coluna (mobile) → sm:2 → lg:3, gap-4
```

### 3.2 Cabeçalho — botões

| Botão | Visibilidade | Destino / ação |
|---|---|---|
| **Tags da organização** (`outline`, `size=lg`, ícone `Tag`) | Sempre (quem passou pelo guard `agent-ia:read`) | Link para `/agent-ia/tags` |
| **Criar Agente** (primário, `size=lg`, ícone `Plus`, `shadow-sm`) | Só se `canWrite` **e** já existe ao menos 1 agente | Abre `AgentFormDialog` em modo `create` |

> Observação importante: quando **não há nenhum agente**, o botão "Criar Agente" do cabeçalho **não aparece** — a criação acontece pelo botão do empty state ("Criar Meu Agente"). O comentário do código explicita que nada impede criar um segundo agente quando já existe 1.

### 3.3 Card do agente — anatomia completa

| Região | Conteúdo | Regras |
|---|---|---|
| **Link de cobertura** (`stretched-link`) | `<Link>` absoluto cobrindo o card, `aria-label="Abrir agente {nome}"`, `z-10` | É o alvo de clique/teclado principal. Não há `div onClick`. O menu de ações fica acima (`z-20`). |
| **Avatar** (48px, `ring-2 ring-border`) | Imagem do avatar da versão **publicada** (prioridade) ou da primeira versão com avatar; fallback = iniciais (máx. 2 letras) ou ícone `Bot` | `agentInitials()`: 1 palavra → 2 primeiras letras; N palavras → inicial da primeira + inicial da última, em maiúsculas |
| **Nome** | `font-semibold`, truncado | — |
| **Slug** | `font-mono text-xs text-muted-foreground`, truncado | — |
| **Menu "⋯"** | `AgentActionsMenu` (só se `canWrite`) | `aria-label="Ações do agente {nome}"` |
| **Descrição** | `line-clamp-2`, altura mínima `2.5rem`; fallback **"Sem descrição."** | Mantém altura constante entre cards |
| **Badges (linha)** | 1) **Padrão** (`outline`, borda âmbar, ícone `Star` preenchido) — só se `is_default`; 2) **status** (`Ativo`/`Inativo`/`Arquivado`); 3) **tipo** (`Agente Externo`/`Agente Interno`, `secondary`) | — |
| **Footer** (`border-t`, `bg-muted/20`) | **`Produção v{n}`** (`default`, ícone `CheckCircle`) quando há versão publicada; senão **"Sem produção"** (`outline`, muted). Depois: **`{n} versão/versões`** (`secondary`, ícone `Layers`) quando `total > 0` | Pluralização feita no código |

**Estilos condicionais do card:**
- Hover: `-translate-y-0.5`, borda `primary/50`, `shadow-md`; `focus-within` também acende a borda.
- `is_default`: borda âmbar 40% + `ring-1 ring-amber-500/20`, e o avatar ganha `ring-amber-500/40`.
- Status ≠ `active`: `opacity-70 grayscale-[0.3]` (o card fica "apagado").

### 3.4 Estados da galeria (mutuamente exclusivos)

| Estado | Condição | Render |
|---|---|---|
| **Loading** | `agentsLoading` | `aria-busy="true"` + `<span role="status" class="sr-only">Carregando agentes…</span>` + **3 cards skeleton** (avatar 48px circular, 2 linhas de texto, 2 linhas de conteúdo, 2 pílulas) |
| **Erro** | `!loading && isError` | Card centralizado `max-w-lg`, borda `destructive/40`, ícone `AlertTriangle` em círculo, **H2 "Não foi possível carregar os agentes"**, `<p role="alert">` com a mensagem do erro (fallback: "Ocorreu um erro ao buscar os agentes desta organização."), botão **"Tentar novamente"** (`outline`, ícone `RotateCcw`) |
| **Vazio (onboarding)** | Sucesso **e** lista com zero itens | Card `border-dashed`, gradiente `muted/30 → background`; avatar 80px com `ring-4 ring-primary/10` e selo `Sparkles` no canto; **H2 "Crie seu primeiro agente"**; parágrafo de valor; botão **"Criar Meu Agente"** (`size=lg`, ícone `Sparkles`) — só se `canWrite` |
| **Sucesso** | Sucesso com ≥1 agente | Grid de cards |

> Regra explícita no código (UX.3): **o empty state nunca aparece em caso de erro**. São estados distintos.

### 3.5 Origem dos dados

- `useAIAgents()` — lista de agentes (filtra `deleted_at IS NULL`).
- `useAIVersions()` — **uma única query** com todas as versões da org, agrupadas por `agent_id` no cliente (evita N+1). Versão com `agent_id = null` (legado) não casa com nenhum card.
- Agregação por agente: `{ total, publishedVersion, avatarUrl }`. O avatar da versão **publicada** tem prioridade; o fallback é a primeira versão (mais recente) com avatar.

### 3.6 Criação de agente a partir da galeria

Ao concluir a criação, o handler `onCreated` **navega direto para o workspace do novo agente** (`/agent-ia/{id}`). O diálogo recebe `isFirstAgent = !hasAgents`, o que marca o agente como `is_default` quando é o primeiro da organização.

---

## 4. Workspace do agente (`/agent-ia/:agentId`)

Arquivo: `src/pages/AgentWorkspace.tsx`.

### 4.1 Layout geral

```
[← Agentes]                                   (ghost, sm, ícone ArrowLeft)

┌── HEADER (flex-col em mobile, flex-row em lg, justify-between) ──────┐
│ H1: [Bot 28px] {nome do agente}                                     │
│      [★ Padrão] [status≠ativo] [tipo]        (badges inline)         │
│ p:  "Configure prompts, diretrizes e regras de negócio deste agente" │
│                                                                      │
│ (direita) [AgentSelectorBar]  [Integração N8N]  [badge de versão]    │
│           [AgentActionsMenu ⋯]                                       │
└──────────────────────────────────────────────────────────────────────┘

┌── TabsList sticky (top-2, z-10, backdrop-blur, bg-muted/95) ─────────┐
│ Versões · Personalidade · Diretrizes · Regras · Prompts · Funil ·    │
│ Tags · Playground · Conversas · Conhecimento · Métricas             │
│ (flex-nowrap, overflow-x-auto — rola horizontalmente)               │
└──────────────────────────────────────────────────────────────────────┘

[conteúdo da aba]
```

### 4.2 Badge de versão no cabeçalho (`getHeaderBadge`)

Duas formas:

1. **Quando existem rascunho E publicada distintas:** dois badges lado a lado, separados por `|`:
   - `Rascunho v{n}` (`secondary`, ícone `Edit3`)
   - `Produção v{n}` (`default`, ícone `CheckCircle`)
2. **Caso contrário:** um badge único com `{agent_name || name} ({Rascunho|Publicado|Arquivado})`, com a variante do status.

### 4.3 Seletor de agente (`AgentSelectorBar`)

Arquivo: `src/components/ia/AgentSelectorBar.tsx`.

| Elemento | Detalhe |
|---|---|
| **Select** (`w-[260px]`, `aria-label="Selecionar agente"`) | Trigger com ícone `Bot`; placeholder "Selecione um agente". Cada item mostra: nome truncado, `Star` âmbar se `is_default`, badge de status quando ≠ `active` (texto 10px) |
| **Botão "Novo Agente"** (`outline`, `sm`, ícone `Plus`) | Só com `canWrite`. Abre `AgentFormDialog` (create). `onCreated` seleciona o agente novo. |
| **`AgentActionsMenu`** (`align="end"`) | Só com `canWrite` e agente selecionado |

A barra aparece **já com 1 agente** — nada esconde a criação do segundo.

### 4.4 Barra de abas: metadados, ícones e bloqueio

`AGENT_WORKSPACE_TAB_META` (`src/lib/agent-workspace-url.ts` L59–71) + `TAB_ICONS` (`AgentWorkspace.tsx` L98–110):

| Ordem | `value` | Rótulo | Ícone lucide | Sempre disponível? |
|---|---|---|---|---|
| 1 | `versions` | Versões | `Layers` | **Sim** |
| 2 | `personality` | Personalidade | `User` | Não (liberada durante a criação da 1ª versão) |
| 3 | `guidelines` | Diretrizes | `BookOpen` | Não |
| 4 | `rules` | Regras | `Cog` | Não |
| 5 | `prompts` | Prompts | `FileText` | Não |
| 6 | `funnel` | Funil | `Target` | Não · **oculta para agente interno** |
| 7 | `tags` | Tags | `Tag` | **Sim** (não é versionada) |
| 8 | `playground` | Playground | `TestTube` | Não |
| 9 | `conversations` | Conversas | `History` | **Sim** |
| 10 | `knowledge` | Conhecimento | `Database` | **Sim** |
| 11 | `metrics` | Métricas | `BarChart2` | **Sim** |

**Regra de bloqueio (`isTabLocked`)**: enquanto o agente **não tiver nenhuma versão**, só ficam liberadas `versions`, `conversations`, `knowledge`, `metrics` e `tags`. As demais aparecem **desabilitadas**, com ícone `Lock` (14px) no lugar do ícone próprio e `title="{rótulo} — crie a primeira versão para desbloquear"`. Exceção: durante o fluxo de criação da 1ª versão (`isCreatingFirstAgent`), `personality` é liberada.

**Regra por tipo (`isTabAvailableForAgentType`)**: agente `internal` **não renderiza a aba Funil**. Se a URL pedir `?tab=funnel` para um agente interno, `resolveTabForAgentType` devolve o default (`versions`).

**Aba efetivamente exibida:** se a aba pedida na URL está bloqueada, a tela cai visualmente em `versions` **sem reescrever a URL** (o bloqueio é transitório).

### 4.5 Navegação por URL

Arquivo: `src/lib/agent-workspace-url.ts`.

| Parâmetro | Valores | Default | Histórico |
|---|---|---|---|
| `?tab=` | `versions`, `personality`, `guidelines`, `rules`, `prompts`, `funnel`, `tags`, `playground`, `conversations`, `knowledge`, `metrics` | `versions` | **push** — cada troca de aba entra no histórico (back/forward navega entre abas) |
| `?funnel=` | `stages`, `transfer-tags` | `stages` | **replace** — micro-navegação não polui o histórico |
| `?interaction=` (aba Conversas) | `all`, `human`, `a2a` | `a2a` para agente **interno**, `all` para externo (`defaultInteractionFilter`) | **replace** |

**Deep link legado:** `?tab=funnel&funnel=conversation-tags` (endereço antigo das Tags de conversa) é **redirecionado** para `?tab=tags`, com `replace: true` e sem deixar `funnel` pendurado (`isLegacyConversationTagsDeepLink` + `rewriteLegacyConversationTagsDeepLink`).

**Troca de agente preserva a aba:** `buildAgentWorkspacePath(agentId, params)` carrega todos os search params para a nova rota. A seleção de versão é estado local e reinicia.

### 4.6 Dirty guard (proteção contra perda de edição)

Contexto compartilhado `DirtyFormGuardContext` (`src/hooks/useDirtyFormGuard`). Toda navegação interna passa por `guardNavigation`:

- troca de aba (`handleTabChange`)
- troca de sub-aba do funil (`handleFunnelSubTabChange`)
- troca de agente (`handleSelectAgent`)
- botão "← Agentes"
- cancelar a criação da primeira versão

**Modal de confirmação** (`AlertDialog` no fim do arquivo):

| Elemento | Texto |
|---|---|
| Título | **"Descartar alterações?"** |
| Descrição | "Há alterações não salvas nesta seção. Se você sair agora, elas serão perdidas." |
| Cancelar | **"Continuar editando"** (mantém a edição e devolve o foco à origem) |
| Ação | **"Descartar alterações"** |

Escape / clique fora = "continuar editando".

### 4.7 Estados do workspace

| Estado | Condição | Render |
|---|---|---|
| **Carregando a rota** | `agentsLoading` | `Loader2` 32px girando, centralizado, `py-24` |
| **Agente inexistente ou excluído (tombstone)** | `agentId` presente e `currentAgent` ausente | Bloco centralizado: ícone `Bot` 48px muted; **H2 "Agente não encontrado ou excluído"**; parágrafo: "Este agente não existe nesta organização ou foi excluído. O histórico de um agente excluído permanece disponível nos relatórios e métricas."; botão **"Voltar para a galeria"** (`outline`, `ArrowLeft`) → `/agent-ia`. **Nada do workspace monta.** |
| **Sem nenhuma versão** (aba Versões) | `!hasVersions && !versionsLoading` | `FirstVersionOnboarding`: card `max-w-lg`; `Bot` 48px em círculo `primary/10`; **H2 "Crie a primeira versão"**; "Este agente ainda não tem nenhuma versão. Defina a personalidade para criar a versão 1."; botão **"Configurar Personalidade"** (`lg`, `Sparkles`) — só com `canWrite` |

### 4.8 Resolução da versão efetiva

```
effectiveVersionId = selectedVersionId
                  || draftVersion?.id
                  || currentPublishedVersion?.id
                  || versions[0]?.id
```

As abas versionadas (Personalidade, Diretrizes, Regras, Prompts, Funil › etapas) são embrulhadas em `AutoDraftWrapper`, que decide se o editor é editável ou somente leitura. Cada editor recebe `key={effectiveId}` — trocar de versão/agente **remonta** o componente, descartando o estado local de verdade.

### 4.9 Fluxo de criação da primeira versão

1. `FirstVersionOnboarding` → botão "Configurar Personalidade" → `isCreatingFirstAgent = true` e aba muda para `personality`.
2. `PersonalityEditor` monta em modo `isFirstAgent`, com o nome **pré-preenchido** a partir de `ai_agents.name` (`defaultAgentName`), editável.
3. Botão **"Criar Agente V1"** (`size=lg`, ícone `Sparkles`) → cria a versão.
4. `onAgentCreated` seleciona a nova versão e **navega para a aba `guidelines`**.
5. Botão **"Voltar"** (`outline`, `ArrowLeft`) cancela e volta para `versions`, passando pelo dirty guard.

### 4.10 Diálogo "Integração N8N"

Gatilho: botão **"Integração N8N"** (`outline`, `sm`, ícone `Plug`) no cabeçalho. Ver §17.

---

## 5. Abas de configuração do agente (versionadas)

As cinco abas desta seção compartilham o mesmo envelope: `AutoDraftWrapper` → banner de rascunho (se aplicável) → editor com `key={effectiveId}`.

### 5.0 `AutoDraftWrapper` — copy-on-write

Arquivo: `src/components/ia/AutoDraftWrapper.tsx`.

**Objetivo:** permitir **visualizar** a versão publicada sem editá-la e criar um rascunho sob demanda.

| Situação | Banner exibido | Ação |
|---|---|---|
| Versão **publicada** e **não existe rascunho** | `Alert` neutro (`bg-muted/50`), ícone `Eye`: **"Visualizando versão publicada."** + "Para fazer alterações, crie um rascunho." (ou "Você não tem permissão para editar." quando `!canWrite`) | Botão **"Criar Rascunho para Editar"** (`sm`, ícone `Edit3`, spinner enquanto pendente) — só com `canWrite` |
| Versão **publicada** e **já existe rascunho** distinto | `Alert` âmbar (`bg-warning/10`), ícone `Edit3`: **"Visualizando versão publicada."** + "Já existe um rascunho (v{n}) com alterações pendentes." | Botão **"Ir para Rascunho"** (`outline`, `sm`) |
| Versão **arquivada** | `Alert` neutro, ícone `Eye`: **"Visualizando versão arquivada."** + "Use a opção "Restaurar" na aba de Versões para criar um rascunho a partir desta versão." | — |
| Carregando a versão | `Loader2` 32px centralizado (`py-12`) | — |
| Erro ao criar rascunho | `Alert variant="destructive"` com `AlertTriangle` e a mensagem | — |

**Toasts do fluxo:**
- Rascunho criado: título **"Rascunho criado"**, descrição "Um novo rascunho foi criado a partir da versão publicada. Você já está editando o rascunho."
- Redirecionado para rascunho existente: **"Redirecionado para rascunho"** / "Suas alterações serão salvas no rascunho existente."
- Erro: **"Erro"** + mensagem, variante destrutiva.

**`DraftEditingBanner`** (exibido quando o usuário está editando o rascunho):

> ⚠️ **"Editando rascunho."** As alterações são gravadas somente quando você salva em cada seção — não há salvamento automático. Publique quando estiver pronto.

> Nota do código: o texto anterior prometia autosave inexistente. **Nenhum editor do workspace tem salvamento automático.**

**`ReadOnlyBadge`** (exportado): badge `secondary` com ícone `Eye` e texto **"Somente Leitura"**.

**Faixa de somente leitura** repetida nos editores (Prompts, Diretrizes, Regras, Funil):

> "Modo somente leitura - crie um rascunho para editar" — bloco `p-3 bg-muted/30 border border-dashed rounded-lg`, texto centralizado.

---

### 5.1 Aba Personalidade (`PersonalityEditor`)

Arquivo: `src/components/ia/PersonalityEditor.tsx`.

**Objetivo:** definir como o agente se apresenta ao cliente (nome, tom, avatar) — e, na primeira vez, **criar a versão 1**.

#### Anatomia

1. **(Só em criação)** Card `bg-primary/5 border-primary/20`: ícone `Sparkles` em círculo, **"Criando seu primeiro agente"**, "Defina a personalidade do seu assistente de cobrança IA. Você poderá ajustar depois!"
2. **Card "Preview do Agente"** — descrição "Veja como o agente aparecerá para os clientes". Bloco `bg-muted/50 rounded-lg`: avatar 64px (fallback = 1ª letra do nome em maiúscula, ou ícone `Bot` 32px), `H3` com o nome (ou **"Assistente"**) e a descrição do tom selecionado.
3. **Grid 2 colunas (md)**:
   - **Card "Nome do Agente"** (ícone `User`, asterisco vermelho quando em criação) — descrição "O nome que será usado nas conversas com clientes"; `Input` placeholder `Ex: Ana, Carlos, Assistente Blips`.
   - **Card "Tom de Voz"** (ícone `Bot`) — descrição "O estilo de comunicação do agente"; `Select` com ícone por tom; abaixo, a descrição do tom escolhido em `text-xs`.
4. **Card "Avatar (Opcional)"** (largura total, ícone `ImageIcon`) — descrição "Imagem para representar o agente nas conversas". `Tabs` de 2 colunas.
5. **Barra de ações** (rodapé, `justify-between`).

#### Campos

| Campo | Tipo | Valores / validação | Observações |
|---|---|---|---|
| `agentName` | texto | Obrigatório **só** na criação (`canCreateAgent = trim().length > 0`) | Pré-preenchido com `ai_agents.name` uma única vez, apenas se o campo estiver virgem |
| `agentTone` | select | `professional` → **Profissional** ("Tom formal e objetivo", ícone `Briefcase`); `friendly` → **Amigável** ("Tom cordial e empático", ícone `Heart`); `assertive` → **Assertivo** ("Tom direto e firme", ícone `Zap`) | `AGENT_TONES` em `src/types/ai.ts` L756–769 |
| `avatarUrl` | texto/URL | Opcional | Salvo como `null` quando vazio |
| `avatarMode` | aba | `upload` \| `url` | Detecção automática: se a URL salva contém `ai-avatars`, abre em `upload` |

#### Aba "Enviar Imagem"

- **Preview do avatar atual** (quando há URL): avatar 48px, "Avatar atual", URL truncada, botão `X` (ghost, icon) para remover — só se editável.
- **Dropzone**: `border-2 border-dashed`, `p-8`, clicável (abre o `input[type=file]` oculto). Hover acende borda `primary/50`.
  - Idle: ícone `Upload` 32px, **"Clique para enviar uma imagem"**, "JPG, PNG, GIF ou WebP - Máximo 5MB".
  - Enviando: `Loader2` 32px girando + **"Enviando..."**; a área fica `opacity-50 pointer-events-none`.
- **Validações** (mensagens exatas, exibidas em `text-destructive`):
  - Tipo não aceito → **"Tipo de arquivo não suportado. Use JPG, PNG, GIF ou WebP."** (aceita `image/jpeg`, `image/png`, `image/gif`, `image/webp`)
  - Acima de 5 MB → **"Arquivo muito grande. Máximo: 5MB."**
  - Organização não carregada → **"Organizacao nao carregada. Tente novamente."**
  - Falha no upload → **"Erro ao fazer upload. Tente novamente."**
- **Somente leitura sem avatar**: "Nenhum avatar configurado" (texto centralizado).
- **Armazenamento:** bucket `ai-avatars`, caminho `{org.slug}/avatars/{versionId|temp-timestamp}-{timestamp}.{ext}`, `cacheControl: 3600`, `upsert: true`. O prefixo por org existe para isolamento via Storage RLS.

#### Aba "URL da Imagem"

- Label "URL da Imagem", `Input` placeholder `https://exemplo.com/avatar.png`, hint "Cole a URL de uma imagem hospedada externamente".
- Preview idêntico ao da aba de upload (avatar 48px + "Preview" + URL truncada + `X`).

#### Ações

| Modo | Botões |
|---|---|
| Criação (`isFirstAgent`) | **"Voltar"** (`outline`, `ArrowLeft`) à esquerda · **"Criar Agente V1"** (`size=lg`, `Sparkles`, spinner) à direita — desabilitado sem nome |
| Edição | **"Salvar Alterações"** (`Save`, spinner) — desabilitado quando não há mudanças (`hasChanges` compara nome, tom e avatar com a versão) |
| Somente leitura | Nenhum botão de ação; inputs com classe `bg-muted/50 cursor-not-allowed opacity-70 border-dashed` |

**Dirty guard:** em criação, o prefill do nome **não conta** como alteração (baseline própria); em edição, `hasChanges` alimenta o guard.

**Erro na criação:** toast **"Erro ao criar agente"** + mensagem (ou "Erro desconhecido"), destrutivo.

---

### 5.2 Aba Diretrizes (`GuidelinesEditor`)

Arquivo: `src/components/ia/GuidelinesEditor.tsx`.

**Objetivo:** "Configure as regras de comportamento do agente de IA".

#### Anatomia

- Cabeçalho: `H2` **"Diretrizes do Agente"** + subtítulo + botão **"Nova Diretriz"** (`Plus`), desabilitado em somente leitura.
- Faixa de somente leitura (quando aplicável).
- **Grid 2 colunas (md)** com **um card por categoria**:

| Categoria | Rótulo | Descrição | Ícone |
|---|---|---|---|
| `tone` | **Tom de Voz** | "Diretrizes sobre o tom da comunicação" | `MessageSquare` |
| `compliance` | **Compliance** | "Regras de conformidade legal (CDC, LGPD)" | `Shield` |
| `escalation` | **Escalação** | "Quando transferir para atendente humano" | `ArrowUpRight` |
| `negotiation` | **Negociação** | "Estratégias e limites de negociação" | `HandshakeIcon` |

(`GUIDELINE_CATEGORIES`, `src/types/ai.ts` L737–754)

#### Card de categoria

- Título: ícone + rótulo + contagem entre parênteses quando > 0.
- Lista de itens (com `ScrollArea` de 280px quando há mais de 3):
  - Bloco `p-3 rounded-lg border`; item inativo fica `bg-muted/50 opacity-60`.
  - Texto da diretriz (`text-sm`, flex-1).
  - Controles (só se editável): **Switch** `aria-label="Ativar diretriz"`, botão **editar** (`Edit`, 28px), botão **excluir** (`Trash2`, 28px, `text-destructive`).
  - Badge **"Prioridade: {n}"** (`outline`, `text-xs`) quando `priority > 0`.
- Vazio: "Nenhuma diretriz de {categoria em minúsculas}" (centralizado, `py-4`).
- Rodapé: botão **"Adicionar {Categoria}"** (`ghost`, `sm`, largura total, ícone `Plus`) — abre o diálogo já com a categoria pré-selecionada.

#### Modal "Nova Diretriz" / "Editar Diretriz"

| Item | Detalhe |
|---|---|
| Tamanho | `w-[95vw] h-[95vh]`, `flex flex-col p-0` |
| Header | `border-b`, gradiente `primary/5 → transparent`; título dinâmico; descrição "Defina uma regra de comportamento para o agente" |
| Campo **Categoria** | `Select` com ícone por categoria |
| Campo **Diretriz \*** | `Textarea` 4 linhas, placeholder "Ex: Sempre cumprimente o cliente pelo nome antes de iniciar a negociação..." |
| Campo **Prioridade (0-100)** | `Input type=number`, min 0 / max 100; hint "Diretrizes com maior prioridade têm precedência" |
| Footer | `border-t bg-muted/30`; **Cancelar** (`outline`) · **Salvar**/**Criar** (desabilitado com texto vazio ou mutation pendente; spinner) |
| Fechar com alterações | Passa por `confirmIfDirty` (mesmo modal "Descartar alterações?") — vale para X, Escape, clique fora e Cancelar |

**Exclusão:** `confirm()` nativo do navegador com a mensagem **"Tem certeza que deseja excluir esta diretriz?"**.
⚠️ A confirmar: o uso de `window.confirm` (em vez de `AlertDialog`) é inconsistente com o resto do módulo — candidato natural a padronização no redesenho.

---

### 5.3 Aba Regras (`BusinessRulesBuilder`)

Arquivo: `src/components/ia/BusinessRulesBuilder.tsx`.

**Objetivo:** "Configure ações automáticas baseadas em condições".

#### Lista de regras

Cada regra é um `Card` (opacidade 60% se inativa) com:

- Linha 1: nome da regra (`font-medium`), badge **Ativa**/**Inativa**, badge `P{prioridade}` (`outline`) quando > 0.
- Descrição (se houver).
- **Bloco SE → ENTÃO** (`bg-muted/50 rounded-lg`, 3 colunas):
  - `SE` (label `text-xs`) + `<code>` com `condition_expression` **cru** (JSON `{logic, filterIds}`).
  - Ícone `ArrowRight`.
  - `ENTÃO` + ícone da ação + rótulo da ação.
- Controles à direita (só editável): **Switch** ativo/inativo, botão editar (`Edit`), botão excluir (`Trash2`, destrutivo).

⚠️ Oportunidade: o `condition_expression` é exibido como JSON bruto (ex.: `{"logic":"AND","filterIds":["uuid",...]}`), o que é ilegível para o usuário final. O nome dos filtros existe e é mostrado no diálogo — mas não na listagem.

#### Ações disponíveis (`BUSINESS_RULE_ACTIONS`, `src/types/ai.ts` L771–792)

| Valor | Rótulo | Descrição | Ícone |
|---|---|---|---|
| `offer_discount` | **Oferecer Desconto** | "Oferece desconto baseado em condições" | `Percent` |
| `escalate_human` | **Escalar para Humano** | "Transfere a conversa para atendente" | `UserX` |
| `suggest_payment_plan` | **Sugerir Parcelamento** | "Sugere opções de parcelamento" | `CreditCard` |
| `send_notification` | **Enviar Notificação** | "Notifica responsável sobre evento" | `Bell` |
| `update_status` | **Atualizar Status** | "Atualiza status do contato/ação" | `CheckCircle` |

#### Estado vazio

Card centralizado (`py-12`): ícone `Cog` 48px; **H3 "Nenhuma regra configurada"**; "Crie regras para automatizar decisões do agente"; botão **"Nova Regra"**.

#### Modal "Nova Regra de Negócio" / "Editar Regra"

Mesmo formato `w-[95vw] h-[95vh]` dos demais. Descrição: "Configure uma condição e a ação que o agente deve executar".

| Campo | Tipo | Regras |
|---|---|---|
| **Nome da Regra \*** | `Input` | placeholder "Ex: Desconto para atrasos longos"; obrigatório |
| **Descrição** | `Textarea` 2 linhas | placeholder "Descreva o objetivo desta regra..." |
| **Filtros \*** | `FilterSelector` | Obrigatório ao menos 1 filtro (`filterIds.length === 0` bloqueia o salvar) |
| **Ação** | `Select` com ícones | Descrição da ação escolhida aparece abaixo em `text-xs` |
| **Prioridade (0-100)** | `Input type=number` | min 0 / max 100 |

Ao salvar, a condição é serializada como `JSON.stringify({ logic, filterIds })`.

#### `FilterSelector`

Arquivo: `src/components/ia/FilterSelector.tsx`. Usa `useAgentConfigFilters({ pageSize: 100 })` — filtros **comuns + de agente**.

| Elemento | Comportamento |
|---|---|
| **Seletor de lógica** | Só aparece com **mais de 1** filtro. Dois botões: **"E (AND)"** e **"OU (OR)"**; o ativo fica `default`, o outro `outline` |
| **Lista de filtros selecionados** | Cada linha: badge `E`/`OU` (a partir do 2º), ícone `Filter`, nome + descrição truncados, badge **"{n} registros"** (`preview_count`, quando não-nulo), botão `X` destrutivo |
| **"Adicionar Filtro"** | `Popover` + `Command`; lista agrupada em **"Filtros Cadastrados"** (nome, descrição, badge com `preview_count`); separador; item **"Criar Novo Filtro"** (`PlusCircle`, cor primária) |
| Vazio no popover | "Nenhum filtro disponível." |
| **Hint** (sem filtros) | "Selecione os filtros cadastrados que devem ser aplicados quando esta regra for acionada." |
| **Prévia da condição** | Bloco `bg-muted/50`: **"Condição: "** + `"Filtro A" AND "Filtro B"` |
| **Criar filtro** | `FilterBuilderDialog` com `defaultUsageScope="agent"` e `allowAgentScope` — o filtro nasce com escopo `agent` (não aparece em campanhas/portfólios); o usuário pode escolher `common` explicitamente |

Ao criar um filtro pelo diálogo, ele é **adicionado automaticamente** à seleção assim que a lista revalida (`pendingFilterToAdd`).

**Exclusão de regra:** `confirm()` nativo — "Tem certeza que deseja excluir esta regra?".

---

### 5.4 Aba Prompts (`PromptEditor`)

Arquivo: `src/components/ia/PromptEditor.tsx`.

**Objetivo:** "Configure o comportamento do agente para cada tipo de interação".

#### Estrutura em dois blocos

**A) Prompt Base** (cenário `general`) — bloco próprio, destacado:

- Cabeçalho: `H3` "Prompt Base" + badge **"Apenas Admin"** (`outline`, âmbar, ícone `Lock`).
- Card com borda âmbar 30% e gradiente `amber-500/5 → transparent`; `border-dashed` quando ainda não configurado.
- Ícone `Settings2` em caixa; título **"Base"**; descrição **"Instruções base aplicadas em todos os cenários"**.
- Badge **"Configurado"** (âmbar) quando existe.
- Conteúdo: preview de 150 caracteres + `...`; linha `Temp: {temperature} • Resposta: {Curta|Média|Longa}`.
- Quando não configurado: "Clique para configurar" (se admin) ou **"Apenas Admin/Proprietário pode configurar"**.
- Sem permissão: card com `opacity-70 cursor-not-allowed` e **Tooltip**: "Apenas Proprietário ou Administrador pode editar este prompt".

**B) Prompts de Cenário** — `H3` "Prompts de Cenário" + grid `md:2 / lg:3` de cards clicáveis:

- Ícone do cenário (mapa `SCENARIO_ICONS`), título, descrição, preview de 150 caracteres, linha `Temp` / `Resposta`.
- Botão excluir (`Trash2`, ghost, `aria-label="Excluir cenário {label}"`) que não propaga o clique do card.
- Vazio: "Nenhum cenário adicional. Use "Novo cenário" para adicionar." (bloco tracejado ocupando a largura).

#### Cenários conhecidos (`AI_SCENARIOS`, `src/types/ai.ts` L706–735)

| Chave | Rótulo | Descrição | Ícone |
|---|---|---|---|
| `general` | **Base** | "Instruções base aplicadas em todos os cenários" | `Settings2` |
| `initial_contact` | **Primeiro Contato** | "Início da conversa com o cliente" | `MessageCircle` |
| `negotiation` | **Negociação** | "Negociação de acordo de pagamento" | `HandshakeIcon` |
| `follow_up` | **Acompanhamento** | "Acompanhamento de promessa de pagamento" | `Clock` |
| `complaint` | **Reclamação** | "Tratamento de reclamação do cliente" | `AlertCircle` |
| `payment_confirmation` | **Confirmação de Pagamento** | "Confirmação após pagamento realizado" | `CheckCircle` |
| `renegotiation` | **Renegociação** | "Renegociação de acordo quebrado" | `RefreshCw` |

> O enum de cenário é **aberto** (`type AIScenario = string`). Cenários personalizados recebem rótulo derivado (`Title Case` a partir do slug) e a descrição **"Cenário personalizado"**; o ícone cai em `Settings2`.

#### Modal de prompt

| Campo | Detalhe |
|---|---|
| **Nome do cenário \*** (só na criação) | `Input` `maxLength=100`, placeholder "Ex.: Segunda via do boleto"; desabilitado quando o cenário é `general`; hint "O cenário será criado como uma configuração independente e poderá ser excluído depois." O slug é derivado por `scenarioKey()` (NFD, sem acento, minúsculas, `[^a-z0-9]+ → _`, corta em 100). Criar com slug duplicado é **silenciosamente ignorado** (`return`) ⚠️ A confirmar: não há mensagem de erro para cenário duplicado. |
| **Prompt Template \*** | `PromptTextarea` (10 linhas) — editor rico com variáveis. Placeholder longo de exemplo com `{{contact.name}}`, `{{total_debt}}`, `{{max_discount}}`, `{{days_overdue}}`, `{{previous_agreements}}` |
| **Pré-visualização** | Aparece assim que há texto: `PromptPreview` com `max-h-[120px]` rolável, renderizando `{{var}}` como *chips* (`.variable-chip`) |
| **Temperatura** | `Input type=number`, min 0 / max 1 / step 0.1. Label mostra o valor; à direita, rótulo qualitativo: `< 0.3` → **"Mais previsível"**; `> 0.7` → **"Mais criativo"**; senão **"Balanceado"** |
| **Tamanho da Resposta** | `Select` com 3 opções (ver tabela abaixo); hint "Tamanho ideal para conversas por WhatsApp" |

**`RESPONSE_SIZES`:**

| Valor | Rótulo | Descrição | `max_tokens` |
|---|---|---|---|
| `small` | **Curta** | "1-2 mensagens de WhatsApp" | 150 |
| `medium` | **Média** | "2-3 mensagens de WhatsApp" | 300 |
| `large` | **Longa** | "3-5 mensagens de WhatsApp" | 500 |

Conversão inversa (`getResponseSizeFromTokens`): `≤200` → Curta; `≤400` → Média; acima → Longa.

**Footer do modal:** **Cancelar** · **Excluir** (destrutivo, só na edição e **nunca** para `general`) · **Salvar**/**Criar**.

**Exclusão:** `confirm()` "Tem certeza que deseja excluir este prompt?". O cenário `general` **não pode ser excluído** (guard no início de `handleDelete`).

#### `PromptTextarea` e `PromptPreview`

Arquivo: `src/components/ia/PromptTextarea.tsx`.

- Envolve `RichVariableInput` com as variáveis de `VARIABLES_BY_CATEGORY` **combinadas com os custom fields do ETL** (`useCustomFieldDefinitions` + `combineWithCustomFields`).
- Cada variável carrega `key`, `label`, `category`, `description`.
- `showPreview={false}` — a pré-visualização é renderizada separadamente pelo `PromptEditor`.
- `PromptPreview`: divide o template por `/(\{\{[^}]+\}\})/g`; cada variável vira um `<span class="variable-chip">` com o nome sem as chaves; fonte monoespaçada, `whitespace-pre-wrap`. Sem template: **"Nenhum prompt definido"**.

---

## 6. Aba Playground

Arquivo: `src/components/ia/AIPlayground.tsx` (+ `PlaygroundComposer`, `PlaygroundContextSelector`, `PlaygroundHistory`, `PlaygroundSettingsDialog`, `playground-context.ts`, `playground-turn.ts`).

**Objetivo declarado na tela:** "Teste o agente com mensagens simuladas".

### 6.1 Banner de modo de teste

Quando existe um rascunho, o `AgentWorkspace` exibe **antes** do playground um `Alert` (`bg-accent/50 border-accent`, ícone `TestTube`):

> **Modo de teste.** O Playground está testando o **rascunho (v{n})**, não a versão em produção.

O `AIPlayground` recebe `versionId = draftVersion?.id || effectiveVersionId` — ou seja, **testa o rascunho quando ele existe**.

### 6.2 Layout

```
┌ Cabeçalho (flex-wrap) ───────────────────────────────────────────────┐
│ H2 "Playground de Testes" / "Teste o agente com mensagens simuladas" │
│                          [⚙ Configurações do webhook] (só owner)     │
│                          [↻ Nova simulação]                          │
└──────────────────────────────────────────────────────────────────────┘
(live region sr-only, aria-live="polite")

┌ grid lg:3 ─────────────────────────────────────────────────────────┐
│ Card "Configuração" (1 col) │ Card "Chat de Teste" (2 cols)         │
│  • Cenário (Select)         │  Tabs: [Chat] [Histórico]             │
│  • PlaygroundContextSelector│  ScrollArea h=min(60vh,32rem)         │
│  • Ver/Ocultar Prompt Comp. │  … bolhas …                           │
│                             │  [faixa de erro/retry]                │
│                             │  PlaygroundComposer                   │
└─────────────────────────────────────────────────────────────────────┘

[Card "Prompt Compilado"]  (aparece ao alternar o botão)
```

### 6.3 Painel "Configuração"

| Controle | Detalhe |
|---|---|
| **Cenário** (`Select`, id `playground-scenario`) | Opções = união de `AI_SCENARIOS` **+** os cenários que existem em prompts da versão. **Desabilitado quando já há mensagens**; nesse caso aparece o hint "Inicie uma nova simulação para trocar o cenário." Tentar trocar com mensagens abre o diálogo de nova simulação. |
| **Contexto** | `PlaygroundContextSelector` (ver 6.4), separado por `border-t` |
| **Ver/Ocultar Prompt Compilado** | Botão `ghost` largura total, ícone `FileText`. **Desabilitado enquanto não houver prompt compilado**; nesse estado exibe "Envie uma mensagem para compilar o prompt." |

### 6.4 `PlaygroundContextSelector`

Arquivo: `src/components/ia/PlaygroundContextSelector.tsx`.

#### Estado "travado" (já há mensagens)

Bloco `border-dashed bg-muted/30`:
- **"Simulação em andamento"**
- Resumo do contexto (`describePlaygroundContext`): `Dados reais — contrato {número}` · `Dados reais — nenhum contrato selecionado` · `Dados fictícios — {nome}` · `Dados fictícios`
- "Você já enviou mensagens. Para trocar o contexto, os dados ou o cenário, inicie uma nova simulação."
- Botão **"Iniciar nova simulação"** (`outline`, `sm`)

#### Estado editável

**1. Origem dos dados** — `RadioGroup` em grid de 2 colunas, cada opção é um cartão clicável que acende `border-primary bg-primary/5`:
- **Dados reais** (ícone `Bot`)
- **Dados fictícios** (ícone `Sparkles`)

**2a. Modo "Dados reais" — sem contrato selecionado:**
- Label "Contrato" + **combobox de busca** (`Popover` + `Command`), botão com texto "Buscar por contrato, nome, documento ou telefone..." e `aria-label="Buscar contrato"`.
- `CommandInput` placeholder "Contrato, nome, documento ou telefone...", busca com **debounce de 300 ms**.
- Estados da busca:
  - Carregando: `Loader2` + **"Buscando..."**
  - Erro: ícone `AlertCircle` + **"Erro ao buscar contratos."** + botão **"Tentar novamente"**
  - Menos de 2 caracteres: **"Digite ao menos 2 caracteres."**
  - Sem resultados: **"Nenhum contrato encontrado."**
  - Resultados: linha com check (marcado quando é o selecionado), `{contract_number || "Sem número"} · {nome mascarado}` e, abaixo, `{valor em aberto} em aberto · {documento mascarado || "sem documento"}`
  - Paginação: botão **"Carregar mais"** (`ghost`, largura total) quando há próxima página
- Hint: **"A busca é segura: nome, documento e telefone aparecem mascarados."**

**2b. Modo "Dados reais" — com contrato selecionado:** `SelectedContractContextCard` (ver 6.5) + **Escopo da simulação** (`RadioGroup`):
- **"Somente este contrato"** *(recomendado)*
- **"Todos os contratos do contato"** *(agrega os valores de todos os contratos)*

**2c. Modo "Dados fictícios":**
- Cabeçalho da seção: label "Contexto fictício" + botão **"Usar exemplo"** (`ghost`, 28px) que aplica o preset.
- Se **nenhum campo estiver habilitado**: bloco tracejado com ícone `AlertCircle` âmbar e o texto:
  > "Nenhum campo de contexto está habilitado. O agente não receberá dados do cliente nesta simulação. Habilite campos em Configurações do Playground."
- Caso contrário, um `Input` por campo habilitado (id derivado, `h-8 text-sm`), com tipo/`inputMode`/`step` conforme o tipo do campo, seguido do hint:
  > **"Campos em branco não são enviados (não viram zero)."**

**Campos embutidos e seus placeholders** (`BUILTIN_PLAYGROUND_FIELD_KEYS` / `BUILTIN_PLAYGROUND_FIELD_DEFAULTS`, `src/types/ai.ts` L179–218):

| Chave | Rótulo | Tipo | Placeholder | Caminho no prompt |
|---|---|---|---|---|
| `name` | Nome | `text` | "Ex.: Maria de Exemplo" | `{{contact.name}}` |
| `document` | Documento | `text` | "Ex.: 123.456.789-00" | `{{contact.document}}` |
| `debt_value` | Valor da dívida | `currency` | "R$" | `{{total_debt}}` |
| `days_overdue` | Dias em atraso | `integer` | "dias" | `{{days_overdue}}` |

Campos personalizados usam `{{custom.{chave}}}`.

**Preset de exemplo** (`FICTIONAL_PRESET_CONTEXT`, `playground-context.ts`): `Maria de Exemplo`, `123.456.789-00`, `1500`, `45` — aplicado **apenas** aos campos embutidos habilitados.

**Regra de parsing (`parseNullableNumber`):** vazio → `null`; inválido → `null`; **nunca** cai em `0` implícito. Vírgula é normalizada para ponto. `debt_value` exige número finito ≥ 0; `days_overdue` exige inteiro finito (**aceita negativos** — cobrança preventiva).

### 6.5 `SelectedContractContextCard`

Arquivo: `src/components/ia/SelectedContractContextCard.tsx`. Card `bg-muted/30`, **100% somente leitura** (nenhum campo é `input`).

| Região | Conteúdo |
|---|---|
| Topo | Ícone `Lock` + "Contrato (somente leitura)"; número do contrato (`font-semibold`) ou "Sem número de contrato"; badge de `contract_status` à direita |
| Bloco 1 | **Nome** (mascarado), **Documento** (mascarado), **Telefone** (mascarado) — `—` quando ausente |
| Bloco 2 | **Saldo em aberto** (BRL), **Valor vencido** (BRL), **Maior atraso** (`{n} dia(s)` ou `—`), **Títulos** (contagem), **Atualizado em** (`dd/mm/aa hh:mm` pt-BR, `—` se inválido) |
| Portfólios | Badges `secondary` com os nomes, quando houver |
| Ações | **"Trocar contrato"** (`outline`, `sm`, ícone `Repeat`) · **"Atualizar dados"** (`ghost`, `sm`, ícone `RefreshCw` que gira enquanto atualiza) com tooltip **"Re-busca os valores atuais deste contrato"** |

### 6.6 Área de chat

| Elemento | Detalhe |
|---|---|
| **Cabeçalho do card** | Título "Chat de Teste" com ícone `TestTube` + badge `outline` com o rótulo do cenário ativo |
| **Tabs** | 2 colunas: **Chat** · **Histórico** |
| **Área de mensagens** | `ScrollArea` `h-[min(60vh,32rem)] min-h-[16rem]`; auto-scroll suave para o fim a cada mudança |
| **Vazio** | Ícone `Bot` 48px, **"Nenhuma mensagem"**, "Envie uma mensagem para testar o agente" |
| **Bolha do usuário** | Alinhada à direita (`flex-row-reverse`), avatar circular `bg-primary` com ícone `User`, balão `bg-primary text-primary-foreground` |
| **Bolha do agente** | Alinhada à esquerda, `Avatar` com a imagem da versão (fallback `Bot`; `Loader2` quando é placeholder de espera), balão `bg-muted` |
| **Placeholder de espera** | Balão `bg-muted/50 border border-dashed` com `Loader2` + texto |
| **Metadados da bolha** | Hora (`toLocaleTimeString("pt-BR")`) e, quando houver, `• ⏱ {n}ms` |
| **Indicador "enviando"** | Enquanto `turn.status === "sending"`: avatar + balão com `Loader2`, `role="status" aria-label="Enviando mensagem"` |

**Mensagens de sistema exibidas como bolha do agente:**
- `"Aguardando resposta do agente externo..."` — placeholder de polling
- `"A entrega não foi confirmada. Aguardando uma possível resposta do agente externo..."` — quando a chamada HTTP falhou mas a entrega é **incerta** (o n8n pode ter recebido e ainda responder)

### 6.7 Máquina de estados do turno

Arquivo: `src/components/ia/playground-turn.ts`.

```
idle --SEND--> sending
sending --SENT(awaitingExternal=false)--> completed      (síncrono / sem webhook)
sending --SENT(awaitingExternal=true)---> awaiting_external
sending --FAIL--> failed
awaiting_external --EXTERNAL_RESPONSE--> completed
awaiting_external --TIMEOUT-----------> timeout
awaiting_external --FAIL--------------> failed
{sending|awaiting_external} --CANCEL--> cancelled   (unmount / troca de versão / nova simulação)
{failed|timeout} --RETRY--> sending    (REUSA o mesmo request_id: idempotente)
* --RESET--> idle
```

| Regra | Implementação |
|---|---|
| **Uma pendente por vez** | `isTurnPending` (`sending` \| `awaiting_external`) bloqueia o composer |
| **Retry idempotente** | `RETRY` reusa o `request_id` — o backend deduplica a mensagem do usuário |
| **Timeout** | `PLAYGROUND_TURN_TIMEOUT_MS = 75_000` (75 s) por padrão; sobrescrito por `playground_config.response_timeout_ms` |
| **Casamento da resposta** | **Nunca por substring de texto.** O polling casa pelo prefixo `` `${requestId}:resp` `` no `request_id` da mensagem persistida (`responseRequestIdPrefix`) |
| **Compatibilidade de rollback** | Com a flag `ai_playground_sessions_v2` **OFF**, aceita também assistente **sem** `request_id` cujo `created_at ≥ startedAt − 1000ms` |
| **Polling** | `usePlaygroundMessagesRpc(conversationId, versionId, isAwaitingExternal)`, `refetchInterval` 2500 ms — só enquanto o turno aguarda; a máquina garante o fim, então **não há polling infinito** |
| **Cancelamento** | `CANCEL` no unmount; trocar de versão dispara `RESET` completo (mensagens, conversa, prompt compilado) |

### 6.8 Estados de erro de entrega (texto exibido)

Faixa de alerta abaixo do chat (`role="alert"`, `tabIndex={-1}`, recebe foco automático), borda tracejada âmbar:

| Estado | Texto |
|---|---|
| `timeout` | **"O agente externo não respondeu a tempo."** |
| `failed` | `turn.error` (mensagem do erro) ou o fallback **"Falha ao processar a mensagem."** |

Botão **"Tentar novamente"** (`outline`, `sm`, ícone `RotateCcw`) — só aparece em `timeout`/`failed` (`canRetryTurn`).

**Acessibilidade do foco:** resposta recebida → foco volta ao composer; erro/timeout → foco vai para a faixa de alerta. A live region (`aria-live="polite"`, `sr-only`) anuncia apenas **"Resposta do agente recebida."** — nunca cada ciclo de polling.

### 6.9 `PlaygroundComposer`

Arquivo: `src/components/ia/PlaygroundComposer.tsx`.

| Comportamento | Detalhe |
|---|---|
| Envio | **Enter** envia; **Shift+Enter** quebra linha |
| IME | Nunca envia durante composição (`isComposing` ou `keyCode === 229`) — protege acentos e teclados asiáticos |
| Auto-resize | Altura acompanha o conteúdo até **160 px** (`max-h-40`); acima disso rola internamente |
| Placeholder | Normal: "Digite uma mensagem... (Enter envia, Shift+Enter quebra linha)" · Pendente: **"Aguarde a resposta atual..."** |
| Acessibilidade | `aria-label="Mensagem para o agente"`; botão de envio com `aria-label="Enviar mensagem"` e `title="Enviar mensagem (Enter)"` |
| Estado bloqueado | Textarea e botão desabilitados enquanto `pending`; o botão mostra `Loader2` no lugar de `Send` |

### 6.10 Aba Histórico (`PlaygroundHistory`)

Arquivo: `src/components/ia/PlaygroundHistory.tsx`. Lista **sessões** (`ai_playground_sessions`) via RPC `list_playground_sessions`, paginada no servidor e **escopada por `version_id`**.

| Estado | Render |
|---|---|
| **Carregando** | `role="status" aria-busy`, `Loader2` 24px, `sr-only` "Carregando histórico…", altura mínima 200px |
| **Erro** | `role="alert"`, ícone `AlertTriangle` 32px destrutivo, "Não foi possível carregar o histórico de conversas.", botão **"Tentar novamente"** |
| **Vazio** | Ícone `MessageSquare` 48px, **"Nenhuma conversa anterior"**, "As conversas do playground aparecerão aqui" |
| **Lista** | Cabeçalho: "{n} conversa(s)" + botão **"Atualizar"** (`ghost`, `RotateCcw`). `ScrollArea` `h-[min(55vh,24rem)]`, `<ul aria-label="Conversas anteriores">` |

Cada item é um `<button>` real (teclado + leitor de tela), com:
- rótulo do cenário (ou **"Sem cenário"**), badge **"Real"**/**"Fictício"** conforme `session.mode`
- `Loader2` quando aquela conversa está sendo carregada; todos os itens ficam desabilitados durante o carregamento
- linha de metadados: `💬 {n} mensagem/mensagens` · `⏱ {tempo relativo pt-BR}` (`formatDistanceToNow` com locale `ptBR`)
- rodapé: botão **"Carregar mais"** / **"Carregando…"** quando há próxima página

Ao selecionar, busca as mensagens da sessão (escopadas por conversa **e** versão), carrega no chat e volta para a aba **Chat**. Em erro: toast **"Erro ao carregar conversa"** / "Não foi possível carregar as mensagens. Tente novamente."

### 6.11 Diálogo "Nova simulação"

`AlertDialog` disparado por: trocar o cenário com mensagens já enviadas, ou pelo botão "Iniciar nova simulação" do seletor de contexto.

| Item | Texto |
|---|---|
| Título | **"Iniciar nova simulação?"** |
| Descrição | "Trocar o contexto, os dados ou o cenário depois de enviar mensagens inicia uma nova simulação. As mensagens atuais serão limpas." |
| Botões | **Cancelar** · **"Iniciar nova simulação"** |

O botão **"Nova simulação"** do cabeçalho (`outline`, ícone `RefreshCw`, `title="O histórico anterior permanece salvo"`) limpa direto, sem diálogo, e fica desabilitado enquanto há turno pendente.

### 6.12 Card "Prompt Compilado"

Aparece quando o toggle está ligado **e** existe um prompt compilado. Card com título "Prompt Compilado" e descrição "O prompt final enviado para o modelo de IA". Conteúdo em `<pre>` (`bg-muted`, `font-mono`, `whitespace-pre-wrap break-words`, rolagem horizontal). O conteúdo é **sempre tratado como texto** — o React escapa; nunca é renderizado como HTML.

### 6.13 Modal "Configurações do Playground" (`PlaygroundSettingsDialog`)

Arquivo: `src/components/ia/PlaygroundSettingsDialog.tsx`. Gatilho: botão de engrenagem no cabeçalho (`aria-label="Configurações do webhook"`), **visível apenas para `owner`**. Tamanho `w-[95vw] max-w-2xl max-h-[90vh]`, corpo rolável.

Descrição do header: "Configure os webhooks para testes do agente de IA".

#### 6.13.1 Webhook de Envio

- `Input` id `playground-webhook-url`, placeholder `https://n8n.exemplo.com/webhook/ai-test`.
- Validação client-side por `validateWebhookUrl` (HTTPS + sintaxe segura). Vazio = "sem webhook" (modo síncrono), permitido.
- Estados do hint:
  - **Erro** (`role="alert"`, destrutivo, ícone `AlertTriangle`): a razão retornada pela validação.
  - **Host válido** (ícone `ShieldCheck` primário): "As mensagens de teste serão enviadas para **{host}**. O servidor validará o DNS e bloqueará redes privadas."
  - **Neutro**: "URL (HTTPS) para onde as mensagens de teste serão enviadas. O agente externo receberá as mensagens neste endpoint. Deixe em branco para não usar webhook."

#### 6.13.2 Modo de resposta (`RadioGroup`, 3 cartões)

| Valor | Rótulo | Descrição exibida |
|---|---|---|
| `auto` | **Automático** | "Padrão: o servidor detecta pela resposta do webhook. A entrega é limitada a 15 s e o tempo máximo vale como espera da resposta assíncrona." |
| `sync` | **Síncrono** | "O agente responde no próprio POST. O tempo máximo passa a ser o timeout da chamada ao webhook (substitui os 15 s), mas a plataforma encerra a requisição em ~150 s." |
| `async` | **Assíncrono** | "O agente sempre responde por callback. A entrega segue com 15 s e o tempo máximo é a espera do callback." |

(`PLAYGROUND_SYNC_PLATFORM_LIMIT_SECONDS = 150`, `src/types/ai.ts` L167)

#### 6.13.3 Tempo máximo de resposta (segundos)

- `Input type=number`, min 1, max **600** (`MAX_PLAYGROUND_TIMEOUT_SECONDS`), step 1, placeholder `75`.
- **Erro**: "Informe um número inteiro de segundos entre 1 e 600."
- **Avisos** (âmbar):
  - modo `sync` e valor > 150 → "A Edge Function encerra a requisição em ~150 s (limite da plataforma); valores acima disso não serão respeitados no modo síncrono."
  - demais modos e valor < 15 → "A entrega do webhook expira em 15 s; valores menores podem gerar timeouts antes da resposta."
- **Hint padrão**: varia por modo, mas sempre informa "Deixe em branco para usar o padrão. Padrão: 75 segundos. Máximo: 600 segundos."

#### 6.13.4 Campos do contexto

Descrição: "Definem o formulário de dados fictícios do Playground. Campos desabilitados não aparecem, não são enviados ao agente e não entram no prompt."

Cada campo é um bloco `rounded-md border p-3` com:
- **Switch** de habilitado (`aria-label="Habilitar campo {rótulo}"`)
- **Rótulo** (`Input`, `maxLength = 70`, placeholder "Ex.: Nome do avalista")
- **Tipo**: campos embutidos exibem o tipo como **texto fixo**; personalizados têm `Select` com *Texto* / *Valor (R$)* / *Número inteiro*
- **Identificador** (só personalizados): `Input` monoespaçado, placeholder `ex.: nome_avalista`
- Botão remover (`Trash2`, ghost, `aria-label="Remover campo {rótulo}"`) — só personalizados
- Linha final: **"No prompt: `{{caminho}}`"**

**Validações (mensagens exatas):**
| Regra | Mensagem |
|---|---|
| Chave fora do padrão `^[a-z][a-z0-9_]{0,39}$` | "Use apenas letras minúsculas, números e _ (começando por letra), até 40 caracteres." |
| Chave duplicada | "Já existe outro campo com este identificador." |
| Rótulo vazio | "Informe um rótulo para o campo." |
| Rótulo > 60 caracteres | "O rótulo deve ter no máximo 60 caracteres." |
| Mais de 10 personalizados | "Máximo de 10 campos personalizados. Remova {n}." |

**Rodapé da seção:** botão **"Adicionar campo"** (`outline`, `sm`, `Plus`) — desabilitado no limite — e o contador **"{n} de 10 campos personalizados"** (+ " (limite atingido)").

**Aviso âmbar fixo:**
> ⚠️ "Campos personalizados servem para **simular** o prompt aqui no Playground. A variável `{{custom.sua_chave}}` **não resolve em produção** a menos que exista um custom field com o mesmo nome vindo do ETL."

#### 6.13.5 Webhook de Resposta

- `Input` **somente leitura**, monoespaçado, com a URL `{SUPABASE_URL}/functions/v1/api/ai/ai-playground-response/{versionId}` + botão copiar (`aria-label="Copiar URL do webhook de resposta"`, vira `Check` verde por 2 s).
- Hint: "URL que o agente externo deve usar para enviar as respostas de volta para o playground. As respostas aparecerão automaticamente no chat."
- Toast ao copiar: **"URL copiada"** / "Webhook de resposta copiado.". Falha: **"Não foi possível copiar"** / "Copie a URL manualmente."

#### 6.13.6 Exemplo de Requisição (cURL)

Bloco `<pre>` com o comando montado usando o **slug real da org** e um placeholder `SUA_API_KEY` (nunca uma chave real):

```
curl -X POST "{responseWebhookUrl}" \
  -H "Content-Type: application/json" \
  -H "x-api-key: SUA_API_KEY" \
  -H "x-org-slug: {orgSlug}" \
  -d '{ "response": "...", "conversation_id": "{{conversation_id}}", "request_id": "{{request_id}}",
        "session_id": "{{session_id}}", "processing_time_ms": 1500,
        "intent_detected": "payment_promise", "sentiment": "positive" }'
```

Botão **"Copiar"** (`ghost`, `sm`). Toast: **"Exemplo copiado"** / "Substitua SUA_API_KEY pela sua chave antes de executar." Hint abaixo: "Substitua `SUA_API_KEY` pela sua chave (Configurações → Integrações → API Keys) antes de executar. Use este exemplo para configurar o webhook de resposta no seu agente externo (N8N, Make, etc.)."

#### 6.13.7 Campos do Payload de Resposta

Tabela de referência (linhas `bg-muted/50`):

| Campo | Descrição exibida |
|---|---|
| `response` | Mensagem de resposta do agente (obrigatório) |
| `conversation_id` | ID da conversa para agrupar mensagens (obrigatório) |
| `request_id` | Ecoe sem alterar o valor recebido (obrigatório no v2) |
| `session_id` | Ecoe sem alterar o valor recebido (obrigatório no v2) |
| `processing_time_ms` | Tempo de processamento em milissegundos |
| `intent_detected` | Intenção detectada na conversa |
| `sentiment` | Sentimento: positive, neutral, negative |

> ⚠️ Bug de encoding presente no código: as descrições de `request_id` e `session_id` estão gravadas como `"obrigatÃ³rio no v2"` (mojibake). Corrigir no redesenho.

#### 6.13.8 Bloco informativo azul

Ícone `ExternalLink`: "As respostas enviadas para o webhook serão exibidas automaticamente no chat do playground por polling. Devolva sem alterar `conversation_id`, `request_id` e `session_id` recebidos no payload de entrada."

#### 6.13.9 Rodapé e confirmação de descarte

- **Cancelar** · **"Salvar Configurações"** (texto vira "Salvando..." e fica desabilitado enquanto `busy`; também desabilita com erro de URL, erro de timeout ou campos inválidos).
- **Pending único**: um `useRef`/estado local impede dois saves no mesmo frame.
- Ao fechar com alterações não salvas, abre `AlertDialog` (`z-[70]`): **"Descartar alterações?"** / "Você alterou as configurações do playground e ainda não salvou. Se sair agora, as alterações serão perdidas." → **"Continuar editando"** · **"Descartar"**.
- Toasts de validação ao tentar salvar: **"URL do webhook inválida"**, **"Tempo máximo de resposta inválido"**, **"Campos do contexto inválidos"** (descrição = limite excedido ou "Revise os identificadores e rótulos dos campos personalizados.").
- Toast de sucesso (no `AIPlayground`): **"Configurações salvas"** / "As configurações do webhook foram atualizadas." · Erro: **"Erro ao salvar"** + mensagem.

---

## 7. Aba Métricas — visão geral

Arquivo: `src/components/ia/AgentMetrics.tsx`.

### 7.1 Dois dashboards, uma porta de entrada

`AgentMetrics` decide qual dashboard renderizar com base no **status agregado do snapshot canônico**:

```
snapshotStatus = snapshotQuery.aggregateStatus ?? (snapshot ? "success" : "disabled")

se snapshotStatus !== "disabled"  →  AiPerformanceSnapshotDashboard   (§10)
senão                             →  LegacyAgentMetrics               (§7–§9)
```

`AIPerformanceAggregateStatus` (`src/hooks/useAIPerformanceSnapshot.ts` L67–73): `disabled` · `loading` · `error` · `partial` · `success` · `idle`.

Regras da agregação:
- Sem org / flag `ai_metrics_snapshot_v1` OFF → `disabled`
- Flags ainda carregando ou query carregando → `loading`
- Query com erro **ou todas as seções em erro** → `error`
- Alguma seção em `error`, **alguma invariante reprovada** ou alguma seção `partial` → `partial`
- Com dados → `success`; senão `idle`
- Seções **report-only** (`agentsOverview`) são **excluídas** desse cálculo (a tela nem as renderiza), mas continuam íntegras no `sectionStatuses` exportado para auditoria.

> **Não há fallback silencioso.** Em `loading` ou `error` o dashboard canônico mostra seu próprio estado — misturar com as consultas v1 significaria misturar fotografias.

### 7.2 Props de `AgentMetrics`

| Prop | Efeito |
|---|---|
| `agentId` | Escopa as RPCs (`p_agent_id`). `null`/ausente = **todos os agentes**: as seções A2A e Transferência viram **comparativos entre agentes** em vez do detalhe |
| `agentType` | `internal` remove funil, transferência e o estado "transferido" do layout |
| `headerSlot` | Slot injetado no grupo "Agente" da toolbar (usado pelo Dashboard) |
| `period` / `onPeriodChange` | Modo **controlado** (Dashboard, estado na URL). Ausentes = estado local (workspace) |
| `granularity` / `onGranularityChange` | idem |

Default local: **últimos 30 dias em BRT** (`defaultAIPeriod()` = preset `30d`), granularidade `day`.

### 7.3 Toolbar de filtros (`MetricsFiltersBar`)

Arquivo: `src/components/ia/MetricsFiltersBar.tsx`. Barra **sticky** (`top-0`, `z-20`, `backdrop-blur`, borda inferior). Os grupos fazem *wrap* e cada um tem um rótulo em maiúsculas (11px):

| Grupo | Conteúdo |
|---|---|
| **Agente** | `agentSlot` (ex.: `DashboardAgentSelector`). Só aparece se fornecido |
| **Período dos eventos** | 4 botões de preset: **7 dias**, **30 dias**, **90 dias**, **Este mês** (o ativo fica `default`, com `aria-pressed`); botão **"Personalizado"** (ícone `CalendarDays`) que abre um `Popover` com *Data inicial* / *Data final* e botão **"Aplicar"**; quando há período, botão `X` (`aria-label="Limpar período dos eventos"`); quando não há, o texto **"Sem restrição"** |
| **Criação do protocolo** | `ProtocolDateFilter` — "Seleciona protocolos iniciados neste intervalo." |
| **Última interação** | `ProtocolDateFilter` — "Seleciona protocolos cuja mensagem mais recente está neste intervalo. Uma mensagem posterior exclui o protocolo." |
| **Agrupamento temporal** | `Select` (**Por dia** / **Por semana** / **Por mês**). Só aparece quando não há período ou o span é > 30 dias. `title` do trigger: "Define o passo temporal das séries de Atividade de mensagens, Transferências, Tags e Chamadas A2A" |
| **Relatório** (`ml-auto`) | `reportSlot` (`AiReportExportButton`) ou, na ausência, um botão desabilitado **"Gerar relatório"** com tooltip **"Disponível em breve"** |

**Rodapé fixo da barra:**
> "Criação e última interação filtram os protocolos e se combinam. O período dos eventos delimita as mensagens, transferências e demais eventos dos indicadores."

**Regras de período (`src/lib/ai-dashboard-url.ts`):**
- Presets são **inclusivos** em BRT: `7d` = hoje + 6 anteriores; `30d` = hoje + 29; `90d` = hoje + 89; `this_month` = do 1º dia do mês até hoje.
- Clicar no preset **já ativo** limpa o período (e a granularidade vira `month`).
- Granularidade derivada do span: > 90 dias → `month`; > 30 → `week`; senão `day`.
- Validação do período customizado (`validateCustomPeriod`), mensagens exatas: **"Selecione as duas datas."**, **"Selecione datas válidas."**, **"A data inicial deve ser anterior ou igual à final."**, **"A data final não pode estar no futuro."**, **"O intervalo máximo é de 366 dias."**
- Ao reabrir o popover, os campos são re-sincronizados com o período vigente (não com um rascunho antigo).

### 7.4 `ProtocolDateFilter`

Arquivo: `src/components/ia/ProtocolDateFilter.tsx`.

- Botão com `aria-label="{rótulo}: {dd/mm/aaaa a dd/mm/aaaa}"` ou **"Sem restrição"**; fica `default` quando há valor.
- Popover (`w-80`): título, descrição + **"Datas em Brasília."**, quatro presets (7 dias / 30 dias / 90 dias / Este mês), campos *Data inicial* e *Data final* (nativos `type=date`, com `max` = hoje BRT), mensagem de erro `role="alert"` e botão **"Aplicar"**.
- Botão `X` (`aria-label="Limpar {rótulo em minúsculas}"`) quando há valor.

### 7.5 Rótulo de cobertura

Abaixo da toolbar, no dashboard legado:

```
Filtro: {requestedLabel}  ·  dados desde {dataSince}
```

O `requestedLabel` vem do **período solicitado no filtro**, nunca da primeira/última linha carregada. O sufixo "dados desde" só aparece quando o snapshot comprova janela parcial, com `title="Não há dados anteriores a esta data no período solicitado"`.

### 7.6 Hierarquia visual do dashboard legado

```
[SectionGroupHeading] VISÃO GERAL
  ├─ TransferSummaryKpis  (bloco full-width, protocol-level)  — oculto p/ agente interno
  ├─ Grid de 3 StatCards: Protocolos · Acurácia · Mensagens
  [SectionGroupHeading] ATIVIDADE E CICLO DE VIDA
  ├─ Card "Ciclo de vida dos atendimentos"  (snapshot atual)
  └─ Card "Conversas por dia" (LineChart)

[SectionGroupHeading] DETALHAMENTO
  [DetailAnchorIndex — pílulas de âncora]
  ├─ #sec-interaction  "Interações: humano × A2A"
  ├─ #sec-transfer     "Eventos de transferência"      (oculto p/ interno)
  ├─ #sec-tags         "Tags ao longo do tempo"
  ├─ #sec-rankings     "Rankings e sentimento"
  ├─ #sec-funnel       "Métricas do funil"             (oculto p/ interno)
  └─ #sec-a2a          "Chamadas entre agentes"
```

- `SectionGroupHeading`: rótulo `text-xs uppercase tracking-wide` + linha divisória.
- `CollapsibleSection`: cabeçalho com chevron rotativo, ícone opcional, título, **badge de unidade**, badge extra e `InfoTooltip`; conteúdo colapsável, aberto por padrão; `id` para âncora; `scroll-mt-24`.
- `DetailAnchorIndex`: `<nav aria-label="Ir para seção do detalhamento">` com pílulas `<a href="#id">`. **Âncoras de funil e transferência somem junto das seções** para agente interno ("um índice que aponta para o nada é pior que não ter o item").

### 7.7 Badge de unidade (`UnitBadge`)

Explicita por que dois números da tela podem divergir. `title` de cada unidade:

| Unidade | Texto do `title` |
|---|---|
| `protocolo` | "Unidade: protocolo (atendimento). Um protocolo pode gerar várias mensagens e eventos." |
| `mensagem` | "Unidade: mensagem individual trocada na conversa." |
| `evento` | "Unidade: evento de transferência. Um mesmo protocolo pode gerar vários eventos." |
| `snapshot` | "Unidade: snapshot do estado atual, sem recorte de período." |
| `conversa` | "Unidade: conversa distinta (telefone + dia)." |

### 7.8 Os três `StatCard` da visão geral

Anatomia do `StatCard`: rótulo + `UnitBadge` + `InfoTooltip`; valor em `text-3xl font-bold tabular-nums`; subtítulo; linha de aviso âmbar opcional; ícone em caixa `bg-primary/10`; rodapé opcional separado por borda.

#### Card 1 — Protocolos

| Item | Conteúdo |
|---|---|
| Ícone | `Users` |
| Unidade | `protocolo` |
| Valor | `protocolCounts.total` (fonte: `useProtocolStatusTransitions` → `ai_protocol_status_log`) |
| Subtítulo | "protocolos distintos com movimentação no período" |
| Aviso (âmbar) | Só quando `agentId == null` e existem conversas órfãs: **"{n} conversa(s) sem agente atribuído"** |
| Tooltip · Negócio | "Quantos atendimentos (protocolos) se movimentaram no período." |
| Tooltip · Técnica | "Protocolos distintos com movimentação no período (fonte: ai_protocol_status_log, o log de transições de status) — mesmo denominador da Acurácia ao lado e mesmo número do badge 'Protocolos' do painel de ciclo de vida abaixo. Um protocolo aberto sem mensagens conta aqui. O aviso de conversas sem agente vem da fonte de CONVERSAS (get_ai_conversation_counts) e só aparece na visão 'Todos os agentes' — em geral indica payload do n8n com agent_slug inválido/ausente." |
| Erro | Substituído por `SectionErrorState` com título "Protocolos" e retry — **nunca "0"** |

#### Card 2 — Acurácia

| Item | Conteúdo |
|---|---|
| Ícone | `Target` |
| Unidade | `protocolo` |
| Valor | `{accuracy_pct}%` ou **`—`** quando `null` |
| Subtítulo (externo) | `{acertos} acertos ÷ {total} protocolos do período` (ou "acertos ÷ protocolos do período" sem dados) |
| Subtítulo (interno) | `{n} finalizados ÷ {n} finalizados ou em andamento` (ou "finalizados ÷ (finalizados + em andamento)") |
| Tooltip · Negócio (externo) | "Taxa de sucesso do agente: a parcela de protocolos que não transbordaram nem foram transferidos para atendimento humano." |
| Tooltip · Técnica (externo) | "Acurácia = (total de protocolos − transbordos − transferidos) ÷ total de protocolos. Transferidos inclui transferência assistida e transferência não classificada. Portanto, somente protocolos finalizados ou ainda em andamento ficam no numerador. Cada protocolo conta em um único bucket." |
| Tooltip · Negócio (interno) | "Taxa de conclusão do agente interno entre os protocolos que terminaram ou continuam em andamento." |
| Tooltip · Técnica (interno) | "Acurácia = protocolos finalizados ÷ (protocolos finalizados + protocolos em andamento). Cada protocolo conta uma única vez, pelo último status no período; transferidos não entram neste indicador." |
| Rodapé (só externo) | Bolinha na cor do transbordo + "Transbordo" + valor + "· {n}% do total" (ou "— do total") |
| Erro | `SectionErrorState` "Acurácia" + retry |

#### Card 3 — Mensagens

| Item | Conteúdo |
|---|---|
| Ícone | `MessageSquare` · Unidade `mensagem` |
| Valor | `metrics.totalMessages` |
| Subtítulo | "mensagens trocadas" |
| Tooltip · Negócio | "Total de mensagens trocadas nas conversas — do cliente e do agente." |
| Tooltip · Técnica | "Cada mensagem individual trocada nas conversas do período, contada separadamente — tanto as do cliente quanto as do agente. Snapshots de estágio do funil não entram na conta." |

### 7.9 Card "Ciclo de vida dos atendimentos"

- Título + `InfoTooltip`:
  - Negócio: "Como estão todos os atendimentos neste momento, considerando o status atual de cada protocolo."
  - Técnica: "Snapshot do status atual em ai_protocols, sem recorte de período. Cada protocolo aparece em um único estado e as porcentagens usam o total atual como base. A movimentação no período continua no KPI 'Protocolos' do topo."
- Subtítulo: **"Situação atual de todos os atendimentos, sem recorte de data."**
- Uma coluna única (`LifecycleColumn`) com título **"No momento"**, badge de unidade `snapshot` e badge **"Total: {n}"**.
- Três mini-stats (`LifecycleStat`): ícone + rótulo, valor grande e **% discreta entre parênteses** (omitida quando a base é 0):
  - `Clock` **"Em andamento no momento"**
  - `ArrowRightLeft` **"Transferidos no momento"** — **oculto para agente interno**
  - `CheckCircle2` **"Finalizados no momento"**
- Para agente interno, o total exibido desconta os transferidos e o grid vira 2 colunas.

### 7.10 Card "Conversas por dia"

- Só renderiza quando há pontos. Título + `UnitBadge conversa` + `InfoTooltip`:
  - Negócio: "Quantas conversas distintas houve em cada dia do período."
  - Técnica: "Conversas distintas por dia (fonte de CONVERSAS: actions_interaction_logs, a mesma do KPI 'Mensagens'). É uma série diferente dos KPIs de PROTOCOLO (Protocolos, Acurácia e a zona de ciclo de vida), que vêm de ai_protocol_status_log — por isso os totais não precisam coincidir."
- `LineChart` (recharts) 220px, eixo X `dd/mm`, tooltip com data completa e rótulo "Conversas".
- **`ChartDataTable`** abaixo: `<details>` "Ver tabela de dados" com colunas *Dia* / *Conversas*.

### 7.11 Skeleton da visão geral

Enquanto `isLoading`: `SectionLoadingState` com label "métricas" (região viva `role=status aria-live=polite aria-busy`), contendo 1 skeleton de 128px (bloco de transferências), 3 skeletons de 112px em grid, 1 de 256px e 1 de 288px.

---

## 8. Aba Métricas — funil, transferências e drill-down

### 8.1 Seção "Eventos de transferência" (`#sec-transfer`)

Cabeçalho da seção colapsável:
- Título **"Eventos de transferência"**, `UnitBadge evento`, badge **"Total: {n}"**.
- `InfoTooltip`:
  - Negócio: "Cada transferência para humano registrada pelo agente, contada por evento e segmentada por tipo (Transbordo / Transferência / Não classificado)."
  - Técnica: "Contagem por EVENTO de transferência (fonte: ai_funnel_events, transferred_to_human=true), NÃO por protocolo. Por isso o total aqui pode diferir do bloco 'Transferências para humano' no topo, que conta PROTOCOLOS: um protocolo pode gerar vários eventos, e um protocolo transferido sem evento de funil human_transfer aparece só no topo (como 'Não classificado') e não aqui."
- **Subtítulo de reconciliação** (calculado): `"{N} eventos em {M} protocolos transferidos (resumo por protocolo no topo)"`. Sem dados suficientes, cai no texto "Cada transferência para humano, contada por evento. O resumo por protocolo fica no topo da tela."

Conteúdo depende do escopo:
- **Agente selecionado** → `TransferMetricsSection`
- **Todos os agentes** → `TransferOverviewSection`

### 8.2 `TransferMetricsSection` (detalhe de um agente)

Arquivo: `src/components/ia/TransferMetricsSection.tsx`.

**Cards de resumo** — grid `2 / lg:4`:
1. **Total no período** (não clicável): valor + "transferências para humano"
2..4. Um card por tipo, na ordem `overflow` → `transfer` → `unclassified`: bolinha colorida + rótulo, valor e **"{n}% do total"**. São `<button>` clicáveis **quando há dado** (abrem o drill-down); sem dado ficam `opacity-60 cursor-default` e desabilitados.

**Gráfico "Transferências por dia"** (2/3 da largura): `TransferTimeSeriesChart` (ver 8.4).

**Ranking "Por tag"** (1/3): lista com **barra proporcional em CSS** (largura = total ÷ maior total, cor do tipo com alpha `1A`):
- Alvo de drill-down é um `<button>` com `aria-label="Ver conversas — {label} ({tipo}), {n} transferências"`.
- Bolinha do tipo + label truncado + badge `outline` com o rótulo do tipo (cor da borda e do texto = cor do tipo).
- À direita: ícone `Info` com **tooltip da descrição da tag** (quando existe; o ícone fica **fora** do botão para não criar *nested interactive*) e o total em negrito.
- Top 8 por padrão; botão **"Ver todas ({n})"** / **"Ver menos"**.
- Vazio: bloco tracejado "Nenhuma tag no período."

**Estados:** `isLoading` → `SectionLoadingState` label "transferências". `total === 0` → `SectionEmptyState` com ícone `ArrowRightLeft` e "Nenhuma transferência registrada no período selecionado."

**Descrição das tags:** vem de `useTransferTags(agentId)`, casada por `transfer_tag_id`. Com `agentId = null` (modo "todos") o hook fica desabilitado e as descrições simplesmente não aparecem.

### 8.3 `TransferOverviewSection` (todos os agentes)

Arquivo: `src/components/ia/TransferOverviewSection.tsx`.

- **Gráfico principal**: `TransferTimeSeriesChart` (altura 340) — mesma UX do detalhe.
- **Card "Comparativo por agente (por tipo)"**: `BarChart` **empilhado** (`stackId="a"`), uma barra por agente, uma série por tipo presente. Eixo X rotaciona −20° e cresce para 60px quando há mais de 4 agentes. **Clicar numa barra abre o drill-down escopado ao agente + tipo.**
- Subtítulo: "Transferências para humano de todos os agentes, ao longo do tempo. Alterne entre tipo e tag; o comparativo por agente detalha por quem transferiu. Clique numa barra do comparativo para ver as conversas."

### 8.4 `TransferTimeSeriesChart`

Arquivo: `src/components/ia/TransferTimeSeriesChart.tsx`.

| Elemento | Detalhe |
|---|---|
| **Toggle** | `ToggleGroup` **Por tipo** / **Por tag** |
| **Modo "tipo"** | Uma linha por tipo (ordem fixa `overflow`, `transfer`, `unclassified`), pivotando `by_day_type`. Dias sem evento recebem **0** (sem buraco na linha) |
| **Modo "tag"** | `Select` (220px) escolhe **uma** tag (ordem = ranking por total; cada opção tem bolinha na cor do tipo). A série vem de `by_day_tag` filtrado pelo `transfer_tag_id`; o domínio de dias é a **união** de todos os dias com qualquer transferência |
| **Sentinela** | Tag sem id usa a chave `__unclassified__` e o rótulo "Não classificado" |
| **Eixos** | X = `dd/mm` com `interval = floor(linhas/12)`; Y sem decimais |
| **Tooltip** | Valor em pt-BR; rótulo = nome do tipo/tag; label = data completa `dd/mm/aaaa` |
| **Vazios** | "Nenhum dado diário disponível." (modo tipo) · "Nenhuma tag com dados no período." (modo tag) |

### 8.5 `TransferSummaryKpis` — "Transferências para humano" (topo)

Arquivo: `src/components/ia/TransferSummaryKpis.tsx`. Bloco `rounded-xl border p-4` com quatro mini-KPIs (`grid 2 / lg:4`).

| KPI | Valor | Percentual e base |
|---|---|---|
| **Total** | soma dos 3 buckets | `{n}% dos protocolos` (base = `accuracy.total`) |
| **Transbordo** | `breakdown.transbordo` | `{n}% das transferências` |
| **Transferência** | `breakdown.transferido_transfer` | `{n}% das transferências` |
| **Não classificado** | `breakdown.transferido_null` | `{n}% das transferências` |

Base 0 → o percentual vira **`—`**.

`InfoTooltip` do bloco:
- **Negócio:** "Atendimentos que foram passados para um humano, separados por motivo: Transbordo = a IA falhou e precisou passar o caso; Transferência = encaminhamento correto (o caso pedia um humano); Não classificado = transferido sem tag de motivo."
- **Técnica:** "Contagem por PROTOCOLO (fonte: breakdown da RPC get_ai_accuracy_metrics) — cada protocolo cai em um único bucket, com prioridade finalizado > transferido: um protocolo que transbordou e depois foi finalizado não conta aqui. Bases das %: nos cards por tipo, a base é o total de transferências para humano (Transbordo + Transferência + Não classificado); no card Total, a base é o total de protocolos com movimentação no período (mesmo denominador da Acurácia). Por isso os números diferem da seção 'Transbordo e Transferência' abaixo, que conta EVENTOS de transferência — um protocolo pode gerar vários eventos."

Skeleton: bloco com 1 barra de título + 4 cartões de 80px.

### 8.6 `TransferDrilldownPanel` — drawer de investigação

Arquivo: `src/components/ia/TransferDrilldownPanel.tsx`. É um `Sheet` ancorado à direita + um `Dialog` de conversa.

#### Redimensionamento

- Largura persistida em `localStorage` (chave `transfer-drilldown-width`), default **480 px**, mínimo **360**, máximo **min(720, 90% da viewport)**.
- Handle na **borda esquerda** (`role="separator"`, `aria-orientation="vertical"`, `aria-label="Redimensionar painel"`, com `aria-valuemin/max/now`), operável por **ponteiro** e por **teclado** (←/→ em passos de 24 px).
- `maxWidth: 90vw` também no CSS.

#### Cabeçalho (fixo, não rola)

- Título **"Conversas de transferência"**.
- Descrição `sr-only`: "Detalhamento dos atendimentos que formam o número clicado, com o filtro efetivo, a unidade selecionada e o acesso à conversa."
- **Chips do filtro efetivo** (`data-testid="transfer-drill-filter-chips"`):
  - filtro por tipo → badge com o rótulo e as cores do tipo
  - filtro "sem classificação" → badge "Não classificado"
  - filtro por tag → (opcional) badge do tipo + `›` + chip da tag com botão `X` (`aria-label="Remover filtro de tag"`, `title="Remover apenas a tag"`)
- Badge de contagem: `{n} protocolo(s)` / `{n} evento(s)` no v2; `{n} conversa(s)` no v1.
- **Toggle de unidade** (só v2): `ToggleGroup` **Eventos** / **Protocolos**.

"Remover apenas a tag" (`broadenFilter`): se a linha era o par (tag, tipo), mantém o tipo; senão o filtro deixa de existir e o painel **fecha** — nunca amplia silenciosamente.

#### Corpo v2 (RPC `get_transfer_drilldown_v2`, flag `ai_metrics_snapshot_v1` ON)

1. **Reconciliação** (`bg-muted/30`): frase resumo do servidor + linha "**{n} sem protocolo**" ou "**Todos com protocolo**".
2. **Facets** — "Tags no conjunto filtrado": lista com bolinha do tipo, label (ou **"Sem tag"**) e total.
3. **Ocorrências** (título **"Protocolos"** ou **"Ocorrências"** conforme a unidade): cada item é um `<button>` com ícone `MessageSquare`, `protocol_display`, `conversation_id` monoespaçado, badge do tipo, badge da tag (quando resolvida), e — na unidade *protocolo* — o texto "{n} eventos" quando `matching_event_count > 1`. Data à direita (`dd/MM/yy HH:mm`). Item sem `conversation_id` fica **desabilitado**.
4. **"Carregar mais"** (cursor/keyset) quando há próxima página; texto vira "Carregando…".
5. Vazio: ícone `AlertCircle` + **"Nenhuma transferência encontrada para este filtro."** (a reconciliação continua visível acima).

#### Corpo v1 (fallback, flag OFF)

1. **"Tags como {Tipo} no período"**: badges das tags vigentes; com descrição, viram tooltip com a descrição + a **vigência** (`Vigente de dd/mm/aa até dd/mm/aa` ou `Vigente desde dd/mm/aa`); sem descrição, a vigência vai no `title`. Vazio: "Nenhuma tag classificada como {tipo} no período."
2. **"Conversas"** + contagem: cada conversa é um `<button>` com protocolo (ou `conversation_id`), `conversation_id` monoespaçado, badge da tag (com tooltip de descrição) e data. Vazio: **"Nenhuma conversa encontrada para este tipo."**

#### Modal de conversa (dentro do drilldown)

- `Dialog` `w-[90vw] max-w-2xl h-[85vh]`.
- Header: **"Conversa"**, descrição `sr-only` "Mensagens do atendimento selecionado, em ordem cronológica."; **"Protocolo: {n}"** (quando houver) e o `conversation_id` monoespaçado.
- Corpo: para cada log, `TransferReasonNote` + `ConversationMessage`.
- Loading: 4 skeletons de 80px. Vazio: `AlertCircle` + **"Nenhuma mensagem registrada."**

### 8.7 `TransferReasonNote`

Arquivo: `src/components/ia/TransferReasonNote.tsx`. Bloco centrado `w-fit max-w-md`, `bg-muted/40`:
- Cabeçalho: ícone `ArrowRightLeft` + **"Motivo da transferência"**.
- **Label** da tag (coluna `transfer_reason`), em `font-medium`.
- **Texto rico original** do agente (`funnel_data.transfer_reason`) **apenas quando difere do label** — evita duplicar quando a tag não resolveu.
- Sem transferência ou sem motivo → **não renderiza nada** (sem placeholder).

### 8.8 Seção "Métricas do funil" (`#sec-funnel`) — dashboard legado

Arquivo: `src/components/ia/FunnelMetricsSection.tsx`.

- Card **"Conversas por estágio"** com `Tabs`: **Histórico** · **Estado atual**.
- **`FunnelChart`** — funil trapezoidal em **CSS puro** (sem recharts):
  - Larguras **fixas por posição** (topo da 1ª etapa = 100%, decrescendo por passo constante até 38%; base mínima 24%) — o funil afunila mesmo quando as contagens não são monotônicas.
  - Cada etapa é um `clip-path: polygon(...)` com gradiente da cor da etapa em alpha (`59` → `2E`), garantindo contraste em tema claro e escuro.
  - Rótulo sobreposto com hierarquia invertida: **valor dominante** (`text-lg font-bold`), nome da etapa secundário, `({n,n}%)` — a % é a **fatia sobre o total** de todas as etapas do dataset ativo.
  - `title` do bloco: `{etapa}: {n} ({x,x}%)`.
- **Modo "Todos os agentes"** (`aggregateByName`): etapas de **mesmo nome** (normalizado por `trim().toLowerCase()`) são somadas; o representante exibido é o de menor `display_order`; a chave React passa a ser o nome normalizado.
- Estados: loading → `SectionLoadingState` label "funil"; sem `stages_meta` → **"Funil não configurado. Adicione estágios na aba Funil."**; total 0 → **"Nenhuma conversa registrada nas etapas do funil neste período."**; aba Histórico vazia → "Nenhum dado histórico disponível no período."; aba Atual vazia → "Nenhuma conversa ativa nos estágios do funil."

**Mapa de cores das etapas** (dado vindo do banco, não é design token): `yellow #EAB308`, `green #22C55E`, `blue #3B82F6`, `red #EF4444`, `purple #A855F7`, `orange #F97316`, `gray #6B7280`, `emerald #10B981`; fallback `#6366F1`.

### 8.9 `FunnelSankeyView` (drop-off)

Arquivo: `src/components/ia/FunnelSankeyView.tsx`.
⚠️ A confirmar: **não encontrei consumidor ativo deste componente** nas telas de agente — aparenta ser código disponível mas não montado no fluxo atual (`AgentMetrics` usa `FunnelMetricsSection`). Documentado aqui porque foi listado no escopo.

- `Sankey` do recharts, altura `max(320, nº de etapas × 60)`.
- Nós: uma etapa por nó (ordenados por `display_order`) + um nó final **"Abandono"** (cinza `#6B7280`). Rótulo do nó: `{nome} ({n})`. Clicar num nó com `stage_key` dispara `onStageSelect`.
- Links: **Avanço** (verde `#22C55E`, `min(passados_origem, passados_destino)`) e **Abandono** (vermelho `#EF4444`, `max(0, origem − destino)`), ambos com `fillOpacity 0.6`.
- Legenda com `HelpTip`: **Avanço** = "Conversas que passaram do estágio atual para o próximo."; **Abandono** = "Conversas que pararam naquele estágio e não avançaram para o próximo."
- Vazio: "Nenhum dado de drop-off no período selecionado."

---

## 9. Aba Métricas — chamadas A2A, tags e interações

### 9.1 Seção "Interações: humano × A2A" (`#sec-interaction`)

Arquivo: `src/components/ia/InteractionBreakdownSection.tsx`. Para agente **interno** esta é a seção principal (aparece primeiro no detalhamento).

**Dois cards lado a lado** (ordem invertida para agente interno: A2A primeiro):

| Card | Badge | Métricas (grid 2×2) |
|---|---|---|
| **"Entre agentes (A2A)"** (ícone `Bot`) | `A2A` (`default`) | **Conversas** (`hint: protocolos`) · **Em andamento** · **Concluídas** (`hint: {x,x}% do total` ou **"sem base de cálculo"**) · **Duração média** (`hint: somente concluídas`) |
| **"Com humano"** (ícone `Users`) | `Humano` (`secondary`) | idem |

Rodapé de cada card (separado por borda): **Mensagens** com o hint **"contadas em ai_messages, não somadas às conversas"**.

> Regras materializadas: o **denominador de conversa é o protocolo**; **"—" quando não há dado** (`formatDuration(null)`), porque `0` afirmaria "demorou 0s" / "concluiu 0%".

**Card "Por tipo de agente"** (só no recorte "Todos"): uma linha por tipo com nome (**Interno** / **Externo** / **Sem agente**), badge "{n} agente(s)" e a linha `{n} conversa(s) · {n} humano · {n} A2A`. Quando o tipo não tem funil/transferência, badge `outline` **"sem funil/transferência"**.

**Card "Chamadas recebidas de outros agentes"** — 4 métricas:
- **Chamadas** (`hint: eventos brutos`)
- **Conversas** (`hint: protocolos distintos`) — o ponto que evita ler "N chamadas = N conversas"
- **Agentes solicitantes**
- **Sem protocolo** (`hint: legado, sem correlação`)

Abaixo: top 5 **por solicitante** (`{nome} — {n} chamada(s) · {n} conversa(s)`) e, separado, o ranking **"Agentes que mais receberam"** (top 5, com badge do tipo do agente ao lado do nome).

Quando o registro não existe: **"Registro de chamadas entre agentes indisponível nesta organização."**

**`NotApplicableSection`** (exportado no mesmo arquivo): card com título em `text-muted-foreground`, badge **"Não se aplica"** e o motivo em texto. Usado para seções que não cabem no tipo do agente — "Deixar a seção com zeros seria pior que escondê-la: leria como 'aconteceu zero vez' em vez de 'não se aplica'."

### 9.2 Seção "Tags ao longo do tempo" (`#sec-tags`)

Arquivo: `src/components/ia/TagMetricsSection.tsx`.

- Card **"Evolução das tags mais usadas (top 8)"**: `LineChart` 280px com uma linha por tag (top 8 por total), dots de raio 3, `connectNulls`.
- Preenchimento explícito de zeros: todo período do domínio recebe `0` para cada tag do top N (não há buraco).
- Eixo X formatado por granularidade: `month` → `jan/26`; demais → `dd/mm`. A formatação usa **slice de string** para evitar deslocamento de fuso.
- Legenda e tooltip traduzem a chave da tag para o `label`.
- Vazio: "Nenhuma tag registrada no período selecionado."
- **`ChartDataTable`** "Total por tag (top tags do período)" com colunas *Tag* / *Total*.

### 9.3 Seção "Rankings e sentimento" (`#sec-rankings`)

Grid de 3 colunas (`lg`):

**1) `TagRankingList` "Top Intents"** — tags do catálogo com `type = 'intent'`, ordenadas desc, com **Top 8 + "Outros (n)"** (`applyTopN`). Vazio: *"Nenhuma tag classificada como Intenção. Classifique tags como Intenção no catálogo (Configurações › Tags) para vê-las aqui."*

**2) `TagRankingList` "Tags de conversa"** — tags com `type = 'conversation'`. Vazio: *"Nenhuma tag de conversa registrada no período."*

> Aviso do código: **"Top Intents" ≠ intents detectados.** São tags do catálogo marcadas como Intenção — os `intent_detected` de `actions_interaction_logs` continuam só no backend.

Anatomia do `TagRankingList`: card com título; `<ul>` rolável (`max-h-72`); cada linha tem bolinha da cor (resolvida pelo mapa de cores), label truncado e total em `tabular-nums`.

**3) Card "Sentimento"** — badge `outline` com ícone `Info`: **"{n}% com análise"** (`sentimentCoverage`). `PieChart` 240px com rótulo `{nome} {n}%` e legenda. Quando a cobertura é **< 50%**, aparece abaixo: *"Apenas {n}% das mensagens têm análise de sentimento"*. Vazio: *"Nenhuma análise de sentimento no período."* Também tem `ChartDataTable` (*Sentimento* / *Mensagens*).

> Em caso de erro nas tags, **as duas listas de ranking** são substituídas por um único `SectionErrorState` de título "ranking de tags" (ocupando 2 colunas) — lista vazia deixaria o erro passar por "nenhuma tag". O card de Sentimento (outra fonte) continua renderizando.

### 9.4 Seção "Chamadas entre agentes" (`#sec-a2a`)

#### Detalhe de um agente — `AgentCallsMetricsSection`

Arquivo: `src/components/ia/AgentCallsMetricsSection.tsx`.

- Subtítulo: **"Quantas vezes outros agentes acionaram este agente, segmentado por solicitante."**
- **Gráfico "Chamadas por dia (por solicitante)"** (2/3): `LineChart` 300px, uma linha por solicitante; dias sem dado recebem **0**. Cores vêm de uma paleta estável de 10 cores indexada pela ordem do ranking (`by_requester` já vem ordenado desc), de modo que a cor de cada solicitante é estável dentro do período.
- **Card "Solicitantes"** (1/3): ranking que também serve de legenda — bolinha da cor + nome truncado (com `title`) + total.
- Vazio: **"Nenhuma chamada de outro agente para este agente no período selecionado."**

Paleta (`SERIES_PALETTE`): `#3B82F6`, `#22C55E`, `#F97316`, `#A855F7`, `#EAB308`, `#EF4444`, `#10B981`, `#EC4899`, `#06B6D4`, `#8B5CF6`.

#### Comparativo entre agentes — `AgentCallsOverviewSection`

Arquivo: `src/components/ia/AgentCallsOverviewSection.tsx`. Usado quando o filtro é "Todos os agentes".

- Subtítulo: "Correlação entre agentes ao longo do tempo: quem solicitou (solicitante) × quem foi acionado (solicitado)."
- **Dois dropdowns** (200px cada): **Solicitante** e **Solicitado**, ambos com a opção "Todos". Se a opção selecionada desaparece (mudança de período), o filtro cai para "Todos" sem travar.
- **Regra de agrupamento** (resolve os 4 casos):
  - ambos "Todos" → uma linha por **solicitado**
  - solicitante fixo → uma linha por solicitado que ele chamou
  - solicitado fixo → uma linha por solicitante que o chamou
  - ambos fixos → uma única linha do par
- **Top 8 séries + "Outros"** agregando a cauda (evita explodir a legenda).
- **Gráfico** (2/3) `LineChart` 300px + **Card de ranking** (1/3) cujo título é **"Solicitados"** ou **"Solicitantes"** conforme o agrupamento.
- **Fallback de migração**: quando `by_day_pair` está vazio mas há dados agregados, mostra um aviso tracejado — *"A correlação solicitante × solicitado aparece após a atualização do sistema. Por enquanto, veja quantas vezes cada Agente Externo foi acionado no período."* — e o card **"Ranking de agentes"**.
- Vazios: "Nenhuma chamada entre agentes no período selecionado." · "Nenhuma chamada para o par selecionado no período."

---

## 10. Painel de snapshot de performance (`AiPerformanceSnapshotDashboard`)

Arquivo: `src/components/ia/AiPerformanceSnapshotDashboard.tsx`. É o dashboard **canônico** — a tela e o relatório HTML recebem **o mesmo objeto imutável** e **o mesmo view model**.

### 10.1 Arquitetura de informação

```
filtros → KPIs → transferências → atividade → ciclo de vida atual
        → tags → funil → sentimento + A2A → detalhes técnicos
```

Ordem real de render:

```
MetricsFiltersBar  (mesma toolbar do §7.3, com AiReportExportButton no slot)

[loading]  ou  [erro]  ou  ↓

┌ header (rounded-lg border bg-card, px-4 py-3) ──────────────────────┐
│ H2 "Performance da IA"                                             │
│ [badge: rótulo do agente] [badge: rótulo do período] [badge Parcial]│
└────────────────────────────────────────────────────────────────────┘
[Alert "Cobertura parcial"]        ← só quando coverage.isComplete = false
[SectionAnchorIndex]               ← índice de âncoras

#snapshot-overview          "Visão geral"       → OverviewKpis + MetricCompositionBar
#snapshot-transfers         (título do VM)       → TransfersSection   (oculto p/ interno)
  └ TransferDrilldownPanel (drawer)
grid xl:12 →  #snapshot-message-activity (8 cols) | #snapshot-lifecycle-period (4 cols)
#snapshot-lifecycle-current "Fotografia atual — todos os protocolos"
#snapshot-tags              (título do VM)
#snapshot-funnel            "Jornada no funil"   (oculto p/ interno)
grid xl:12 →  #snapshot-sentiment (5 cols) | #snapshot-agent-calls (7 cols)
[TechnicalDetailsPanel]  (accordion recolhido)
```

Índice de âncoras (`anchorItems`): **Visão geral**, **Transferências**\*, **Atividade**, **Movimentação no período**, **Fotografia atual**, **Tags**, **Funil**\*, **Sentimento**, **Chamadas A2A**, **Consistência**. (\* omitidos para agente interno.)

### 10.2 Detecção de agente interno

```
isInternalAgent = viewModel.meta.agentType === "internal"
               || viewModel.sections.accuracy.data?.internalMetricName === "internal_completion_rate"
```

### 10.3 `SectionShell` — casca comum

Arquivo: `src/components/ia/snapshot-sections/SectionShell.tsx`.

| Elemento | Detalhe |
|---|---|
| `<section id aria-labelledby>` + `Card` | Uma âncora navegável por seção, com **um único `<h2>`** |
| Cabeçalho | `<h2>` + `MetricExplanationPopover` (o "?" derivado do catálogo) + badges + (opcional) ações à direita |
| Subtítulo | texto `text-sm text-muted-foreground` |
| Colapsável | quando `collapsible`, o chevron fica antes do título com `aria-label="Recolher {título}"` / `"Expandir {título}"` |

**Regra de colapso automático** (`secondaryCollapse`): uma seção secundária nasce **recolhida apenas quando está vazia ou indisponível**. **Erro nunca colapsa** — "esconder um erro atrás de um chevron o faz parecer 'sem dados'". Aplicado a: *Fotografia atual*, *Tags*, *Sentimento*, *Chamadas A2A*.

**`SectionStatusBadge`**: badge `secondary` com o `statusLabel` — não renderiza nada quando o status é `success`.

### 10.4 `VmSectionBody` — precedência de estados

**Ordem fixa: inconsistente → erro/vazio → dados.**

| Caso | Render |
|---|---|
| `isInconsistent` | `ChartInconsistentState` com título, mensagem, **códigos das invariantes** e a **tabela esperado/observado/diferença** |
| `status === "success"` e `data !== null` | os filhos |
| `status === "error"` | `Alert role="alert"` com `AlertCircle`, título = `statusLabel` ("Erro ao calcular") e descrição **"A seção não foi substituída por zero{ (código)}."** |
| vazio **com diagnóstico** | `Alert role="alert"`, título **"Lacuna de ingestão"**, descrição = `{diagnosticMessage} ({diagnosticCode})` |
| vazio simples | `Alert role="status"` com `CheckCircle2`, título = `statusLabel` e descrição **"Não há valores disponíveis para esta seção no recorte selecionado."** |

### 10.5 `OverviewKpis` — os cinco números da primeira dobra

Arquivo: `src/components/ia/snapshot-sections/OverviewKpis.tsx`. Grid **responsivo por espaço do container** (`repeat(auto-fit, minmax(min(210px,100%), 1fr))`) — não por viewport, porque a tela vive dentro da sidebar.

| # | Card | `metricKey` | Nota exibida |
|---|---|---|---|
| 1 | **Acurácia** | `accuracy.rate` | `{ratioLabel} · Base: protocolos com transição de status no período.{ · ressalva}` |
| 2 | **Protocolos com mensagens** | `messages.protocolsWithMessages` | "Base: protocolos com ao menos uma mensagem no período. População diferente da base da acurácia." |
| 3 | **Mensagens** | `messages.total` | — |
| 4 | **Média por protocolo** | `messages.perProtocol` | — |
| 5 | **Protocolos transferidos para humano** *(oculto p/ interno)* | `transfers.protocols.total` | "Unidade protocolo — eventos ficam na seção de transferências." |

Cada card mostra: rótulo + "?" (popover derivado do catálogo), valor `text-2xl tabular-nums`, **caption = `formatMetricLabel(metricKey)`** (rótulo canônico com unidade, 11px) e a nota.

**Regra de indisponibilidade (`unavailableReasonFor`)** — o valor vira **`—`** e a nota é substituída:

| Status | Texto |
|---|---|
| `error` | "{Métrica} indisponível (erro no cálculo)." |
| `unavailable` | "{Métrica} indisponível." |
| outros (vazio) | "Sem {métrica em minúsculas} no período." |
| inconsistente (material) | **"Dados inconsistentes nesta seção."** |
| lacuna de ingestão | o `diagnosticMessage` (ver §11) |

**Materialidade:** só `inconsistencySeverity === "material"` esconde o valor da **Acurácia** (é a única seção com denominador de materialidade). Quando é `immaterial`, o número é publicado **com ressalva** (`inconsistencyCaveat`), e a ressalva **acompanha** a razão — não a substitui. Guard adicional: a ressalva só aparece quando há valor publicado.

> Nota de produto explícita no código: *"Protocolos com mensagens" (ex.: 22) e o denominador da acurácia (ex.: 20) são conjuntos diferentes por construção* — o primeiro conta quem teve mensagem (`ai_messages.occurred_at`), o segundo quem teve transição de status (`ai_protocol_status_log.changed_at`). Forçá-los a coincidir seria inventar dado; por isso a tela **diz isso** nas notas dos dois cards.

### 10.6 Barra de composição dos desfechos

Abaixo dos KPIs, `MetricCompositionBar` com `metricKey="accuracy.rate"`, `dimensionKey="buckets"`:
- Título: **"Desfechos por protocolo"** (externo) ou **"Protocolos finalizados e em andamento"** (interno).
- Vazio: "Nenhum protocolo com movimentação no período." / "Nenhum protocolo finalizado ou em andamento no período."

Rótulos dos buckets (`ACCURACY_BUCKET_LABELS`): **Finalizado** (`#22c55e`), **Transferência (assistida)** (`#3b82f6`), **Transferido sem classificação** (`#a855f7`), **Transbordo** (`#ef4444`), **Em andamento** (`#eab308`), **Encerrado por inatividade** (`#14b8a6`).

### 10.7 `TransfersSection`

Arquivo: `src/components/ia/snapshot-sections/TransfersSection.tsx`. Subtítulo da seção: **"Protocolos é a unidade padrão; eventos são tentativas e reclassificações."**

| Controle | Detalhe |
|---|---|
| **Toggle de unidade** | `Protocolos` \| `Eventos` (`aria-label="Unidade das transferências"`) — define qual `metricKey` alimenta o gráfico e o ranking |
| **Toggle de agrupamento** | `Por tipo` \| `Por tag` (`aria-label="Agrupamento das transferências"`) |
| **Dois totais sempre visíveis** (`data-testid="transfer-unit-totals"`) | Dois cartões com o **rótulo canônico completo**: "Protocolos transferidos no período (protocolos)" e "Eventos de transferência no período (eventos)" |
| **Gráfico** | `TransferTrendPanel` (toggle interno desligado; o modo vem do estado da seção) |
| **Ranking** | `MetricRankingList` — **"Por tipo"** ("Clique para ver os atendimentos que formam o número.", vazio "Nenhuma transferência no período.") ou **"Por motivo (tag)"** ("Uma tag pode aparecer em mais de um tipo: cada linha é o par tag + tipo.", vazio "Nenhuma tag de transferência no período.", com `expandOthers`) |

**Identidade composta da tag:** a chave é `(tagId, eventType)`. Uma tag usada em Transferência e em Transbordo gera **duas linhas distintas**, e o clique reproduz exatamente a identidade exibida. A linha **"Outros"** agrega linhas distintas e **não é drillável**.

### 10.8 `MessageActivitySection`

Arquivo: `src/components/ia/snapshot-sections/MessageActivitySection.tsx`.

`MetricTrendChart` com três séries **de unidades diferentes** no mesmo eixo:

| Série | Unidade declarada | Cor |
|---|---|---|
| **Mensagens** | mensagens | `#6366F1` |
| **Protocolos** | protocolos | `#0EA5E9` |
| **Transferências** (omitida para agente interno) | protocolos | `#F97316` |

- Título: **"Atividade ao longo do tempo"**.
- `canonicalLabel` sobrescrito: "Mensagens, protocolos e transferências no período (contagens)"; `unitLabel` = "contagens".
- Descrição (texto exato): *"Três indicadores de UNIDADES DIFERENTES no mesmo eixo: mensagens são mensagens; protocolos e transferências são protocolos. Compare a FORMA das curvas, não a altura entre elas. Selecione os itens da legenda para isolar cada indicador."*
- Vazio: "Nenhuma atividade no período."

### 10.9 `LifecyclePeriodSection` — movimentação no período

Arquivo: `src/components/ia/snapshot-sections/LifecyclePeriodSection.tsx`.

- Badges: **"Protocolos que se moveram: {n}"** (`secondary`), **"Passagens: {n}"** (`outline`, quando disponível) e **"Respeita o período do filtro"** (`outline`).
- `MetricRankingList` com `metricKey="lifecycle.period.passages"`, `dimensionKey="states"`, **sem Top N** (`applyTopN={false}`), título **"Estados tocados no período"**.
- Descrição: *"Protocolos que PASSARAM por cada estado dentro do período escolhido. Um mesmo protocolo pode aparecer em mais de uma linha — isto não é uma distribuição de 100%."*
- Vazio: "Nenhuma movimentação de protocolo no período."
- `total` passado = `distinctProtocols` (**não** a soma das linhas).
- Agente interno: o estado `transferido` é filtrado fora.

> **Decisão de design registrada no código:** esta seção **não pode** virar barra de composição. Passagens são multivalor; a `MetricCompositionBar` recusa dimensões `multivalue` por contrato do catálogo.

### 10.10 `LifecycleCurrentSection` — fotografia atual

Arquivo: `src/components/ia/snapshot-sections/LifecycleCurrentSection.tsx`.

- **Alerta âmbar fixo** (`role="status"`, `data-testid="lifecycle-current-period-warning"`):
  > "Esta visualização não respeita o filtro de período. Ela mostra o estado atual de **todos** os protocolos do agente, acumulado desde sempre."
- Badges: **"Protocolos: {n}"** e **"Em {data do snapshot}"**.
- `MetricCompositionBar` (`lifecycle.current.distinctProtocols`, dimensão `states`), título **"Distribuição agora"**, descrição "Estado atual de cada protocolo. Não respeita o período do filtro.", vazio "Nenhum protocolo na fotografia atual."
- Rótulos dos estados (`LIFECYCLE_STATE_LABELS`): **Em andamento** (`#eab308`), **Transferido** (`#3b82f6`), **Finalizado** (`#22c55e`).
- Agente interno: `transferido` some e o total exibido é a soma dos segmentos visíveis.

### 10.11 `TagsSection`

Arquivo: `src/components/ia/snapshot-sections/TagsSection.tsx`.

- Subtítulo da seção: **"Unidade: aplicações de tag. Um protocolo pode receber várias tags."**
- `ToggleGroup` de tipo: **Todas** · **Intenções** · **Tags de conversa** (`aria-label="Tipo de tag"`).
- **Domínio temporal compartilhado** entre os recortes — trocar o filtro não encolhe o eixo do tempo (o que sugeriria que o período mudou).
- O filtro por tipo é aplicado **antes** do Top N, sobre as séries brutas (filtrar depois faria o bucket "Outros", que é heterogêneo, sumir inteiro e levar junto o volume da cauda).
- `TagEvolutionPanel` com título **"Evolução — {recorte}"**.

### 10.12 `FunnelSection` — jornada no funil

Arquivo: `src/components/ia/snapshot-sections/FunnelSection.tsx`. Subtítulo da seção: *"Conversão da corte observada, passagens no período e estado atual — três leituras independentes."*

`Tabs` com três abas (default = `cohort`):

| Aba | Métrica | Natureza |
|---|---|---|
| **Conversão da corte observada** | `funnel.cohort.reached` | Única corte sequencial real; única com funil proporcional e drop-off |
| **Passagens no período** | `funnel.passages.touched` | Protocolos que **tocaram** cada etapa; **pode crescer**; não é conversão, não tem drop-off; barras ordenadas por volume |
| **Estado atual** | `funnel.current.stage` | Partição exclusiva → barra 100% |

Rodapé fixo da seção (11px):
> "As três leituras respondem perguntas diferentes: a corte segue a mesma turma etapa a etapa (conversão real); passagens conta quem tocou cada etapa (pode crescer); estado atual é a fotografia de agora. Os totais não precisam coincidir."

**Chave React:** sempre `stageId`, nunca `key` de negócio — etapas homônimas coexistem entre agentes/versões.

**A seleção da definição de corte vive no `FunnelSection`** (o painel desmonta ao trocar de aba), então a escolha do usuário sobrevive à troca de aba.

### 10.13 `FunnelCohortPanel`

Arquivo: `src/components/ia/snapshot-sections/FunnelCohortPanel.tsx`.

- Cabeçalho `MetricChartHeader` com título **"Conversão da corte observada"** e descrição *"Sequência derivada de eventos append-only — não de arestas gravadas. A série é não crescente."*
- **Seletor de definição** (só quando há mais de uma disponível): `Select` 280px, `aria-label="Selecionar definição de funil"`, opção = `"{nome do agente} · {n} atendimentos"`. Seleção inicial = definição **dominante** (maior corte inicial, desempate estável por `definitionId`) — a mesma regra do relatório HTML.
- **Funil trapezoidal**: `<ol aria-label="Etapas da corte">`; a largura de cada barra é o **campo do payload** `conversionFromInitialPct` (nunca recalculada no cliente), com mínimo visual de 12% e `min-width: 10rem`; fundo = cor da etapa com alpha `26` e borda esquerda sólida de 3px.
- Linha sob cada etapa: **"Base da corte"** na primeira; nas demais, `conversão {x%} · abandono {y%}`; sempre seguido de `· {z%} do início`.
- Linha informativa: **"Agente: {nome}"**.
- Quando há exclusões: *"{n} protocolo(s) foi/foram excluído(s) por sequência ambígua (empate de horário entre etapas diferentes)."*
- **Tabela acessível** em `<details>` "Ver tabela de dados" com colunas *Etapa* · *Alcançaram* · *Conversão da anterior* · *Abandono* · *Do início*.

**Estado indisponível (`CohortUnavailable`)** — `Alert role="status"`:
- Título: **"Conversão indisponível — sequência insuficiente"**
- Corpo: frase do motivo + "As leituras de passagens e estado atual seguem disponíveis nas outras abas."

Frases de motivo (`COHORT_REASON_LABELS`, `view-model.ts` L741–745):

| Código | Frase |
|---|---|
| `NO_COHORT_IN_WINDOW` | "Nenhum protocolo iniciou o funil dentro do período." |
| `NON_UNIQUE_ORDER` | "A ordem das etapas do funil não é única." |
| `NO_UNIQUE_INITIAL_STAGE` | "O funil não tem uma etapa inicial única." |
| `INSUFFICIENT_STAGES` | "O funil tem etapas insuficientes para formar uma corte." |
| *(fallback)* | "Não há corte sequencial suficiente para calcular conversão neste recorte." |

### 10.14 `SentimentSection`

Arquivo: `src/components/ia/snapshot-sections/SentimentSection.tsx`.

- **Donut em CSS** (`conic-gradient`), 160px, com `role="img"` e `aria-label="Distribuição de sentimento de {n} mensagens analisadas"`. No centro: o **rótulo de cobertura** grande + a palavra **"analisadas"**.
- Legenda `<ul aria-label="Legenda do sentimento">`: bolinha + label + `{total} · {percentual}`.
- Só entram os buckets `positive` / `neutral` / `negative` com total > 0 — **"Sem análise" não é sentimento neutro** e não recebe percentual.
- Rodapé (separado por borda):
  - **"Base elegível para sentimento: {n} registros"** com `title` "Registros de interacao elegiveis a analise de sentimento. Base propria (log de interacoes), diferente do card Mensagens da Visao geral, que conta mensagens da base canonica."
  - **"Analisadas: {n} registros"**
  - Nota final: **"Base própria com retenção de 30 dias — janelas maiores aparecem truncadas."**

### 10.15 `AgentCallsSection`

Arquivo: `src/components/ia/snapshot-sections/AgentCallsSection.tsx`. Unidade: **chamadas**, nunca protocolos.

- Séries pivotadas por **solicitante** a partir dos pares diários.
- `AgentCallsTrendPanel` com título **"Chamadas entre agentes ao longo do tempo"** e ranking **"Solicitantes no período"** (dimensão `byRequester`).
- O painel aplica **Top 5 + "Outros"** ponto a ponto (a linha agregada preserva o total por dia) e usa `renderMode="line"`.

### 10.16 `TechnicalDetailsPanel` — "Detalhes técnicos e verificações"

`Accordion` **recolhido por padrão**, sempre no fim da página. Cinco grupos:

| Grupo | Linhas |
|---|---|
| **Identidade da fotografia** | Snapshot (id) · Versão das definições · Versão do schema · Gerada em |
| **Corte de ingestão** | Dados considerados até · Fonte do corte (quando existe). Nota fixa: *"A lista do drill-down pode ser mais recente que esta fotografia: ela consulta o banco no momento do clique, sem o corte de ingestão acima."* |
| **Cobertura** | Dados desde · Retenção de interações · lista de avisos de cobertura traduzidos |
| **Contadores de qualidade** | `QUALITY_LABELS`: **Mensagens sem protocolo**, **Protocolos sem mensagens**, **Protocolos sem agente atribuído**, **Divergências de agente**, **Eventos duplicados rejeitados** |
| **Situação das seções** | Uma linha por seção: título + `statusLabel` |
| **Verificações do servidor** | Frase de cobertura + `InvariantDetailsTable` |

**Regra de escopo:** com um agente selecionado, **"Protocolos sem agente atribuído" é omitido** (`AGENT_SCOPED_BLIND_QUALITY_KEYS`), porque o predicado da RPC (`agent_id IS NULL AND agent_id = $3`) é contraditório e o zero seria **estrutural**. Nesse caso aparece a nota:
> *""Protocolos sem agente atribuído" não é exibido no recorte de um agente: a pergunta não se aplica a este escopo."*

**Frase das verificações:**
- Com invariantes: `"{n} verificação(ões) publicadas pelo servidor · {m} reprovada(s)."`
- Sem invariantes: **"Esta fotografia NÃO publica invariantes: as métricas não foram verificadas — o que não é o mesmo que aprovadas."**

Valor ausente numa linha técnica renderiza **`—`**, nunca `0`.

### 10.17 Chip "Parcial" e suas causas

Quando `snapshotStatus === "partial"`, o header ganha um badge `secondary` **"Parcial"** com `tabIndex={0}`, `cursor-help` e `aria-describedby`. O motivo aparece em **tooltip** e também em um `<span class="sr-only">` (leitor de tela não passa o mouse).

`partialScopeReasons(viewModel)` — derivação **pura**, sem recalcular nada:

| Causa | Texto gerado |
|---|---|
| Seções em erro | "Seções que não puderam ser calculadas ({n}): {títulos}." |
| Invariantes reprovadas | "Verificações de consistência reprovadas ({n}): {códigos}. As seções afetadas ficam sem número, de propósito." |
| Recorte restrito a externos | "Alcance reduzido a agentes externos: {rótulo} Os números são válidos, mas cobrem menos que o recorte pedido." · sem rótulo: "Alcance reduzido: parte das seções cobre apenas agentes externos. Os números são válidos, mas cobrem menos que o recorte pedido." |
| Nenhuma causa declarada | "A fotografia não cobriu tudo o que foi pedido, e o snapshot não declarou o motivo. Abra os detalhes técnicos abaixo." |

Título do tooltip: **"Por que esta fotografia está parcial"**; conteúdo em lista.

### 10.18 Alerta de cobertura parcial

Fora do accordion (é **crítico**), quando `coverage.isComplete === false`:

> **Cobertura parcial** — {summaryLabel} · dados desde {dataSinceLabel}

### 10.19 Avisos de cobertura conhecidos

`COVERAGE_WARNING_LABELS`:

| Código | Texto |
|---|---|
| `TIME_DOMAIN_SPARSE_BY_DAY_TAG` | "A série de transferências por tag foi densificada com muitos dias sem ocorrência — leia o gráfico por tag com atenção às barras zeradas." |
| `CONTENT_REDACTED_BEYOND_RETENTION` | "Parte do conteúdo além da janela de retenção foi ocultada." |
| `INVALID_EMPTY_TAG_ID_DROPPED` | "Uma ou mais tags legadas sem identificador foram ignoradas. As demais métricas continuam disponíveis." |

O primeiro é exibido como `Alert role="status"` âmbar **dentro da seção de Transferências**; o terceiro, dentro da seção de **Tags**. Códigos desconhecidos são exibidos **crus** (nunca ocultados).

### 10.20 Estados do dashboard canônico

| Estado | Render |
|---|---|
| `loading` / `idle` | `role="status" aria-live="polite" aria-busy`, `sr-only` "Carregando fotografia das métricas de IA", 1 skeleton de 80px + 2 de 192px em grid |
| `error` ou sem view model | `Alert role="alert" variant="destructive"`: **"Não foi possível carregar a fotografia das métricas"** + mensagem do erro (fallback **"O snapshot canônico não retornou dados válidos."**) + botão **"Tentar novamente"** (`outline`, ícone `RefreshCw`) |
| `partial` | Renderiza tudo, com o chip "Parcial" e as seções afetadas bloqueadas individualmente |
| `success` | Render completo |

### 10.21 Kit visual canônico (`src/components/ia/charts/`)

Regras que o kit impõe (e que o redesenho precisa preservar):

| Componente | Regra |
|---|---|
| `MetricChartHeader` | Sempre publica `formatMetricLabel(metricKey)` — rótulo + unidade — e a natureza da janela: **"respeita o período do filtro"** ou **"fotografia atual (sem filtro de período)"** |
| `ChartLegend` | Legenda **selecionável por teclado** (`aria-pressed`), com marcador textual + cor (dois sinais redundantes) e `sr-only` "(série visível, ativar para ocultar)" / "(série oculta, ativar para mostrar)" |
| `MetricTrendChart` | `type="linear"` (reta), **nunca `monotone`** — curva suave inventaria valores não medidos. Domínio temporal completo (bucket sem registro é `0` de verdade). Com **menos de 3 observações vira gráfico de barras** (`TREND_MIN_POINTS_FOR_LINE = 3`). Respeita `prefers-reduced-motion`. Sempre acompanha `ChartDataTable` |
| `MetricCompositionBar` | Barra 100% para **partições exclusivas**. **Recusa** dimensão declarada como `multivalue` no catálogo e cai em "dados inconsistentes" com a mensagem: *"A dimensão "{dim}" de {métrica} é multivalor: um mesmo {unidade} pode aparecer em mais de um segmento, então a soma não é 100%. Use um ranking em vez de uma composição."* Renderização em CSS puro |
| `MetricRankingList` | Top 5 + "Outros" (`CHART_TOP_N`), preservando o total. Em dimensão multivalor, escreve na tela: *"Dimensão multivalor: um mesmo item pode aparecer em mais de uma linha — a soma das linhas não corresponde ao total."* e **omite o percentual**. `expandOthers` permite abrir a cauda e publicar o ranking completo na tabela |
| `FunnelJourneyPanel` | Três modos (`cohort` / `passages` / `current`); `passages` ordena por volume (a sequência não representa avanço) e **não** desenha drop-off; `current` delega para a barra de composição |
| `TagEvolutionPanel` | Top 5 + "Outros" com soma **ponto a ponto**; ranking recebe as séries **cruas** para que "Outros" seja expansível; descrição fixa: *"Um protocolo pode receber várias tags: as séries não somam o total de atendimentos."* |
| `AgentCallsTrendPanel` | Unidade **chamadas**; descrição "Uma linha por agente solicitante." |
| `TransferTrendPanel` | `metricKey` **obrigatória** — protocolos e eventos são métricas diferentes e nunca podem aparecer ambas como "Transferências" |
| `ChartDataTable` | `<details>` "Ver tabela de dados" com `<table>` de 2 colunas, `<caption class="sr-only">`, cabeçalho sticky, altura máxima 224px. **Não renderiza com zero linhas** |

---

## 11. Estados de lacuna, indisponibilidade e erro de métrica

Esta seção reúne **todos os textos** que a tela mostra quando um número **não** é publicado. O princípio geral: *falha nunca vira zero; "não sabemos" nunca vira "está vazio"*.

### 11.1 Catálogo de estados por seção

| Situação | Onde aparece | Texto exibido |
|---|---|---|
| Seção **sem dados** no período | `VmSectionBody` | Título **"Sem dados no período"** + "Não há valores disponíveis para esta seção no recorte selecionado." (`role="status"`, ícone `CheckCircle2`) |
| Seção com **erro** | `VmSectionBody` | Título **"Erro ao calcular"** + **"A seção não foi substituída por zero{ (CÓDIGO)}."** (`role="alert"`) |
| Seção **indisponível** | badge/`statusLabel` | **"Indisponível"** |
| Seção **não aplicável** | badge/`statusLabel` | **"Não se aplica"** + `NOT_APPLICABLE_REASON` |
| Seção **parcial** | badge/`statusLabel` | **"Parcial (só agentes externos)"** |
| **Lacuna de ingestão** | `VmSectionBody` + `OverviewKpis` | Título **"Lacuna de ingestão"** + mensagem admin + `(MESSAGE_ACTIVITY_CANONICAL_GAP)` |
| **Dados inconsistentes** | `ChartInconsistentState` | Ver 11.3 |

### 11.2 Lacuna de ingestão (`MESSAGE_ACTIVITY_CANONICAL_GAP`)

Detecção: a seção `messageActivity` lê **exclusivamente** `ai_messages`. Quando ela vem vazia **mas existem protocolos no período** (evidência: protocolos sem mensagens, denominador de acurácia, transferências ou movimentação de ciclo de vida), o view model declara a lacuna em vez de publicar zero.

**Dois textos, um código** (`view-model.ts` L443–449):

| Audiência | Texto |
|---|---|
| **Administrativa (tela)** | "Existem protocolos no período, mas não foram encontradas mensagens canônicas em ai_messages. Verifique a ingestão canônica dos produtores de mensagem ou execute o backfill." |
| **Destinatário (e-mail / relatório)** | "A atividade de mensagens está temporariamente indisponível por uma lacuna de processamento. Contate o suporte informando o código MESSAGE_ACTIVITY_CANONICAL_GAP." |

Regras: `status: 'error'`/`'unavailable'` **nunca** viram lacuna; `not_applicable` não é evidência; **seção inconsistente tem precedência** (não se dá duas explicações concorrentes para o mesmo vazio).

### 11.3 Dados inconsistentes (`ChartInconsistentState`)

Arquivo: `src/components/ia/charts/chart-primitives.tsx`. `Alert role="alert"` âmbar (`border-amber-500/50 bg-amber-500/10`):

| Elemento | Conteúdo |
|---|---|
| Título | **"Dados inconsistentes — {título da seção}"** |
| Mensagem padrão | **"Uma verificação de consistência desta métrica falhou. Os números foram omitidos de propósito para não publicar um valor incorreto."** (`INCONSISTENT_SECTION_MESSAGE`) |
| Códigos | **"Verificações que falharam: "** + cada código em `<code>` (`data-testid="inconsistency-codes"`) |
| Mensagens do servidor | Lista `<ul>` **deduplicada** com a `message` escrita pelo próprio SQL (`data-testid="inconsistency-messages"`) |
| Tabela | `InvariantDetailsTable` com legenda "Diagnóstico de qualidade — {seção}" |

**O que este banner NUNCA mostra:** o valor omitido. "Publicar o valor bloqueado aqui anularia o bloqueio."

**`InvariantDetailsTable`** — 6 colunas: **Métrica** (`metricKey`, monoespaçada) · **Verificação** (código) · **Esperado** · **Observado** · **Diferença** (com sinal, ex. `+2` / `−2`) · **Status** (**Falhou** / **OK**). Lista vazia → não renderiza tabela.

### 11.4 Severidade da inconsistência

| Severidade | Efeito na tela |
|---|---|
| `material` | O número é **omitido** (`—`) e o card diz "Dados inconsistentes nesta seção." |
| `immaterial` | O número **continua publicado**, com a ressalva `inconsistencyCaveat` ("Pode estar inflado em até N de M protocolos.") |
| `null` | Sem inconsistência |

`accuracy` é a **única** seção que recebe denominador de materialidade; nas demais, `material` é equivalente ao booleano (fail-closed).

### 11.5 `InvariantDiagnosticsPanel` (código presente, sem uso)

Arquivo: `src/components/ia/snapshot-sections/InvariantDiagnosticsPanel.tsx`.

⚠️ **Não é renderizado na tela atual.** O comentário em `AiPerformanceSnapshotDashboard.tsx` (L756–780) documenta a resolução de conflito de merge: existiam dois painéis para a mesma finalidade e ficou apenas o `TechnicalDetailsPanel`, que é superset. O arquivo permanece no repo **sem uso** — candidato a remoção em card próprio.

Conteúdo (caso volte a ser usado): alerta âmbar "{n} verificações de consistência falharam neste recorte. A validação não foi desativada — o que está abaixo é o diagnóstico exato do que divergiu." + tabela **Seção · Verificação · Esperado · Encontrado · Diferença · Efeito**, com os rótulos:
- `material` → "Material — os números desta seção foram omitidos de propósito."
- `immaterial` → "Imaterial — os números continuam publicados, com ressalva."
- Sem falhas: **"Todas as verificações de consistência passaram neste recorte."**

### 11.6 Estados transversais (`MetricSectionBoundary`)

Arquivo: `src/components/ia/MetricSectionBoundary.tsx`. Seis estados com **ícone + texto** (cor nunca é o único sinal):

| Estado | Componente | Acessibilidade | Texto padrão |
|---|---|---|---|
| `loading` | `SectionLoadingState` | `role="status" aria-live="polite" aria-busy="true"` + `sr-only` **"Carregando {label}…"** | skeletons |
| `error` | `SectionErrorState` | `Alert role="alert"` | **"Erro ao carregar {título}"** + mensagem + botão **"Tentar novamente"** (`RefreshCw`) que refaz **só** a query da seção |
| `empty` | `SectionEmptyState` (ícone `Inbox`) | — | **"Nenhum dado no período selecionado."** |
| `unavailable` | `SectionEmptyState variant="unavailable"` (ícone `CircleSlash`) | `role="status"` | **"Este recurso está indisponível no momento."** |
| `stale` | `SectionStaleNotice` | `role="status"` | Aviso âmbar **acima** do conteúdo, sem esconder os dados já carregados |
| `success` | — | — | os filhos |

---

## 12. Exportação de relatório de IA (`AiReportExportButton`)

Arquivo: `src/components/ia/AiReportExportButton.tsx` + `src/hooks/useAiReportExport.ts` + `supabase/functions/_shared/ai-report/report-core.ts`.

### 12.1 Formato e conteúdo

- **Formato único: HTML** (`text/html;charset=utf-8`), baixado como arquivo via Blob + `<a download>`.
- O HTML é gerado **do mesmo snapshot congelado** que está na tela: `snapshot → buildAiPerformanceViewModel → renderAiPerformanceReport`. Os números são byte-for-byte derivados do snapshot auditado.
- Nome do arquivo: `buildAiReportFilename({ orgName, agentName, fromDate, toDate, generatedAt })`.

### 12.2 Estados do botão

| Estado | Render |
|---|---|
| **Flag `ai_performance_html_report` OFF** | Botão **desabilitado** "Gerar relatório" com tooltip **"Disponível em breve"** (mesmo visual do placeholder da toolbar) |
| **Bloqueado** | Botão desabilitado; o **motivo** vai no tooltip (ver 12.3) |
| **Habilitado** | Tooltip: "Exporta as métricas exibidas em HTML — {cobertura}" (ou "Exporta as métricas exibidas em um arquivo HTML") |
| **Gerando** | Texto **"Gerando…"**, ícone `Loader2` girando, `aria-busy`, desabilitado; tooltip "Gerando relatório…"; `sr-only role="status" aria-live="polite"` anuncia "Gerando relatório…" |

O `<span tabIndex>` em volta do botão existe para o tooltip funcionar sobre botão desabilitado.

### 12.3 Motivos de bloqueio (textos exatos)

`getAiReportBlockReason` (`report-core.ts` L102–146):

| Condição | Mensagem |
|---|---|
| `snapshotStatus === "disabled"` | "O snapshot de métricas (ai_metrics_snapshot_v1) está desativado para esta organização. Ative-o para gerar o relatório." |
| `"loading"` | "Aguarde o carregamento das métricas para gerar o relatório." |
| `"error"` | "As métricas estão com erro. Recarregue a tela antes de gerar o relatório." |
| Sem snapshot | "Snapshot de métricas indisponível. Recarregue a tela antes de gerar o relatório." |
| Seção **obrigatória** em erro | "Seções obrigatórias com erro: {títulos}. Recarregue a tela antes de gerar o relatório." |
| Seção obrigatória `partial` **sem dados** | "Seções obrigatórias sem dados publicáveis: {títulos}. O recorte de agentes externos não pôde ser calculado, então o relatório não seria representativo." |
| Subconjunto externo não calculado | "O subconjunto de agentes externos não pôde ser calculado, e Acurácia, Transferências para humano só se aplicam a eles. Recarregue a tela antes de gerar o relatório." |

**Seções obrigatórias** (`REQUIRED_REPORT_SECTIONS`): `messageActivity`, `accuracy`, `transfers`, `lifecyclePeriod`, `lifecycleCurrent` — as cinco de `overview`. Seções de **detalhe** em erro **não bloqueiam**: o relatório declara o erro na própria seção.

**Só `error` bloqueia.** `not_applicable` e `partial` são resultados **válidos**.

### 12.4 Auditoria antes do download

Ordem obrigatória: **auditoria → render → download**. O escopo auditado (`buildAiReportExportScope`) contém apenas metadados — **sem PII e sem HTML**:

```
{ agentId, from, toExclusive, granularity, sectionStatuses }
```

`from`/`toExclusive` são convertidos para **data civil** `YYYY-MM-DD` (enviar timestamp causa erro 22023 e a exportação é corretamente bloqueada). O `sectionStatuses` é repassado **íntegro** (não pode ser filtrado nem falsificado). O snapshot também gera um **SHA-256 hex** (`hashSnapshotSha256`) registrado na auditoria.

### 12.5 Resultado e erros

| Resultado | Toast |
|---|---|
| Sucesso | **"Relatório gerado"** / "Download iniciado: {filename}" |
| Falha **recuperável** | destrutivo, **"Falha ao gerar o relatório"** / mensagem do erro (fallback "Não foi possível registrar a exportação. Tente novamente.") + ação **"Tentar novamente"** |
| Falha **não recuperável** (código `22023`) | destrutivo, **"Auditoria do banco desatualizada"** / "Não foi possível registrar o relatório porque a versão da auditoria do banco está desatualizada." — **sem** botão de retry |

**Proteção contra duplo clique:** além do `disabled`, um `useRef` (`generationLockRef`) fecha a janela síncrona em que dois cliques no mesmo frame gerariam dois downloads.

**Nada é baixado quando a auditoria falha** — a auditoria vem antes do download.

---

## 13. Aba Conversas / Logs

Arquivo: `src/components/ia/ConversationLogs.tsx`.

### 13.1 Princípio estrutural

Existe **uma única lista navegável**, protocol-level, com **todos os recortes resolvidos no banco** (busca, tags, etapa, período, tipo de interação, paginação). Antes existiam duas listas simultâneas (a filtrada e "Conversas Recentes" sem recorte), e a segunda fazia o filtro A2A/Humano **parecer não funcionar**.

### 13.2 Anatomia

```
H2 "Conversas"
p  "Um atendimento por linha, com o recorte por tipo de interação"
[🔍 Input de busca — "Nome, documento, telefone, contrato, e-mail ou protocolo"]  maxLength 200

[Todas|Humano|A2A]  [● Ao vivo]  [📄 Status no período: N em andamento · M transferidos · K finalizados]
                                  [Limpar todos]                       [spinner de fetching]

[ConversationFilters: Hoje | Ontem | Esta semana | Personalizado · Tags · Etapa]
[badges removíveis de etapa]
[badges removíveis de tag]
[contador "N de M conversas"]

[ProtocolConversationList]
```

### 13.3 Busca

- `Input` com ícone `Search`, `maxLength=200`, **debounce de 300 ms**.
- A busca só é enviada com **≥ 2 caracteres**; abaixo disso vai `null`.
- Resolvida **no banco** por nome, documento, telefone, contrato, e-mail e protocolo.

### 13.4 Recorte de interação (`InteractionFilterToggle`)

Arquivo: `src/components/ia/InteractionFilterToggle.tsx`. `role="tablist"` com `aria-label="Filtrar conversas por tipo de interação"`, três `role="tab"`:

| Valor | Rótulo | Ícone |
|---|---|---|
| `all` | **Todas** | `MessageCircle` |
| `human` | **Humano** | `Users` |
| `a2a` | **A2A** | `Bot` |

A opção selecionada exibe um badge com o **total do recorte vindo do banco** (`total.toLocaleString("pt-BR")`). O valor vive em `?interaction=` (replace) e é **preservado ao abrir e fechar o detalhe**.

**`InteractionBadge`** — selo por protocolo, **sempre visível** (inclusive em "Todas"): badge `default` com `Bot` + "A2A", ou `secondary` com `Users` + "Humano". *"Numa lista mista, sem o selo não há como saber qual atendimento foi com humano e qual foi entre agentes."*

### 13.5 Indicadores ao lado do toggle

- **"Ao vivo"**: bolinha verde pulsante + texto `text-green-600`.
- **Status no período**: `📄 Status no período: {n} em andamento · {n} transferidos · {n} finalizados`. O trecho "transferidos" **some** para agente interno.
  - Fonte: `useProtocolStatusCounts` (**snapshot** do estado atual), não o KPI histórico — o operador lê "N em andamento" como "agora".
  - Em erro: `role="alert"` com **"Falha ao carregar status dos protocolos."** + link **"Tentar novamente"**.
- **"Limpar todos"** (`ghost`, `sm`): aparece quando há busca, tags, etapas, data **ou** recorte diferente do default do tipo do agente. Reseta tudo, inclusive o recorte.
- Spinner discreto (`Loader2` 12px) enquanto refetching (sem ser paginação).

### 13.6 `ConversationFilters`

Arquivo: `src/components/ia/ConversationFilters.tsx`.

**Botões de período** (altura 28px, `text-xs`): **Hoje** · **Ontem** · **Esta semana** · **Personalizado**. Clicar no ativo **desliga** o filtro. O "Personalizado" ativo vira um `Popover` com `Calendar` em modo **range** (1 mês visível) e o rótulo do botão mostra `dd/mm/aaaa – dd/mm/aaaa`, `A partir de {data}` ou `Até {data}`. Botão `X` (`title="Limpar filtro de data"`) quando há data.

**Cálculo do range** (`getDateRange` em `ConversationLogs.tsx`): usa "agora em BRT" (UTC − 3 h) para que o `slice(0,10)` devolva a data correta mesmo após as 21 h BRT. "Esta semana" começa na **segunda-feira**.

**Filtro de Tags**: botão com ícone `Tag` (ou `Loader2` carregando) + badge com a quantidade selecionada; `Popover` 208px com checkboxes. Vazio: **"Nenhuma tag cadastrada ainda"**. Tags selecionadas viram badges `secondary` removíveis (`aria-label="Remover filtro de tag: {tag}"`).

**Filtro de Etapa** (oculto para agente interno): botão com ícone `Target` + badge de contagem; `Popover` 224px com checkbox + bolinha da cor + nome da etapa. Vazio: **"Nenhuma etapa configurada"**. Etapas selecionadas viram badges **coloridos** (fundo `{cor}20`, texto e borda na cor) removíveis (`aria-label="Remover filtro de etapa: {nome}"`).

**Contador**: `"{filtrados} de {total} conversas"` — só aparece quando há filtro ativo **e** os números divergem.

**Catálogo de tags do filtro**: união das tags do banco (`useDistinctConversationTags`) com as tags que aparecem nos protocolos já carregados — garante que uma tag recém-aplicada apareça no filtro antes da revalidação.

### 13.7 `ProtocolConversationList`

Arquivo: `src/components/ia/ProtocolConversationList.tsx`. **Uma linha por protocolo.** Dois atendimentos da mesma `ai_conversation` (telefone + dia) aparecem **separados**.

Cada linha é um `Card` cujo conteúdo inteiro é um `<button>` (`aria-label="Abrir conversa {protocolo}"`):

| Região | Conteúdo |
|---|---|
| Linha 1 | `InteractionBadge` · nome do contato (ou telefone, ou protocolo) em `font-medium` · badge `outline` com o **status** do protocolo |
| Linha 2 | Última mensagem truncada (`—` quando ausente) |
| Linha 3 | `💬 {n} mensagens` · `·` · protocolo em `font-mono` |
| Tags | Ícone `Tag` + badges `secondary` das tags do protocolo |
| Etapa (oculta p/ interno) | Ícone `Target` + badge com o nome da etapa, colorido pela cor da etapa (`{cor}20` de fundo) |
| Direita | `⏱ {tempo relativo}`: "agora", "há {n} min", "há {n}h", "há {n}d" |

**Estados:**

| Estado | Render |
|---|---|
| **Erro** | `role="alert"`, bloco `border-destructive/40 bg-destructive/5`: "Falha ao carregar as conversas." + botão **"Tentar novamente"**. *Erro nunca vira lista vazia.* |
| **Carregando** | 3 blocos `h-20 animate-pulse bg-muted` |
| **Vazio** | Texto centralizado com a mensagem contextual do recorte: "Nenhuma conversa entre agentes neste recorte." (a2a) · "Nenhuma conversa com humano neste recorte." (human) · "Nenhuma conversa neste recorte." (all) |
| **Lista** | Cards + botão **"Carregar mais"** (largura total, spinner) + rodapé **"{carregadas} de {total} conversa(s)"** |

A paginação **acumula** (`useInfiniteQuery`) — a contagem no rodapé prova que a página anterior não foi substituída.

### 13.8 Modal de transcrição

`Dialog` `w-[95vw] h-[95vh]`.

**Header** (gradiente `primary/5 → transparent`):
- Título: `InteractionBadge` (quando há protocolo selecionado) + **"Conversa: {nome do contato | telefone | 'Contato'}"**
- Subtítulo: `{data por extjson}` · `{n} turno(s)` — ou, sem dados, `ID: {conversation_id}`
  - A contagem usa o **total do banco** quando disponível; o cabeçalho **não** anuncia o tamanho da página como se fosse o tamanho da conversa.
- **"Protocolo: {n}"** como **link externo** para `https://conversas.hyperflow.global/all-chats/{protocolo}` (`target=_blank`, `rel="noopener noreferrer"`, ícone `ExternalLink`, `title`/`aria-label` "Abrir conversa {protocolo} no Hyperflow")

**Corpo** — fluxo de mensagens:
- **Separador de data** (quando a conversa cruza dias): linha divisória centralizada com badge da data por extenso (`15 de março de 2025`).
- **Marcador "Conversa encerrada"**: divisor com badge `secondary` + ícone `PhoneOff`. Detectado por `context.event_type === "conversation_ended"` ou `ai_response === "Conversa encerrada"`.
- **Bolhas** (`ConversationMessage`) — só quando há conteúdo do usuário ou do agente.
- Turnos sem nada renderizável são **pulados**.

> Nota do código: os marcadores **inline** de etapa de funil e de transferência foram removidos da transcrição porque a leitura passou a ser da fonte canônica (`ai_messages`), que é message-centric e não carrega esses campos. A etapa continua visível **na linha da lista**.

**Estados de completude da transcrição** (todos com `data-testid` próprio):

| Estado | Texto |
|---|---|
| Falha ao carregar **página seguinte** | (âmbar) "Falha ao carregar mais mensagens. As {n} já carregadas continuam abaixo." + botão **"Tentar novamente"** — as mensagens já lidas **permanecem** |
| **Truncada** | "Exibindo {n} de {total} mensagens desta conversa." + botão **"Carregar mais mensagens"** |
| **Completa** | "Transcrição completa: {n} mensagem(ns)." — exige as **três** condições: sem mais páginas, sem expurgo por retenção e protocolo **já encerrado** |
| **Incompleta — em andamento** | "Conversa em andamento: novas mensagens podem chegar depois desta leitura." |
| **Incompleta — retenção** | "Transcrição parcial: {n} mensagem(ns) tiveram o conteúdo removido pela política de retenção." |
| **Incompleta — outro motivo** | "Transcrição possivelmente incompleta." |
| **Carregando** | `Loader2` 24px centralizado |
| **Erro inicial** | `role="alert"`: "Falha ao carregar a transcrição desta conversa." + **"Tentar novamente"** |
| **Vazio** | Ícone `MessageSquare` 32px + "Nenhuma mensagem registrada" |

> Regra: **só o erro inicial toma a tela**. Falha de página seguinte nunca apaga o que já foi lido, e o retry refaz o **mesmo cursor** (não duplica nem pula mensagem).

### 13.9 `ConversationMessage`

Arquivo: `src/components/ia/ConversationMessage.tsx`.

**Parsing da mensagem**: o campo pode ser JSON com `{ combined|text, images[], audios[], files[] }`; se não for JSON, é tratado como texto puro.

| Lado | Alinhamento | Avatar | Balão |
|---|---|---|---|
| **Cliente** | direita (`justify-end`) | círculo `bg-primary/15` com `User` | `bg-muted`, cantos `rounded-2xl rounded-br-sm` |
| **Agente** | esquerda | círculo `bg-primary` com `Bot` | `bg-primary text-primary-foreground`, `rounded-2xl rounded-bl-sm` |

Acima de cada balão: o nome (contato → `contactName || "Cliente"`; agente → `agentName`, default "Agente IA" — no workspace vem do `agent_name` da versão **publicada do agente da aba**).

**Anexos (`MediaAttachments`)**:
- **Imagens**: `<img>` com `max-h-[120px]`, dentro de link que abre em nova aba.
- **Áudios**: `<audio controls preload="none">` com sources `audio/ogg; codecs=opus` e `audio/ogg`, largura total (mín. 260px); abaixo, link **"Abrir áudio"** com ícone `Volume2`.
- **Arquivos**: link com ícone `Paperclip` + nome extraído da URL.

**Metadados do agente** (`AgentMetadata`, linha 12px separada por `·`):
1. Hora `HH:mm`
2. **Sentimento** com ícone e cor: `positive` → `Smile` verde **"Positivo"**; `neutral` → `Meh` amarelo **"Neutro"**; `negative` → `Frown` vermelho **"Negativo"**
3. **Intenção** traduzida (`INTENT_LABELS`)
4. **Tempo de processamento**: `{n}ms` abaixo de 1 s; `{x,x}s` a partir de 1 s

**Dicionário de intenções (`INTENT_LABELS`):**

| Chave | Rótulo |
|---|---|
| `payment_request` | Cobrança Preventiva |
| `payment_promise` | Promessa de Pag. |
| `payment_confirmation` | Confirmação de Pagamento |
| `payment_negotiation` | Negociação |
| `dispute` | Contestação |
| `request_statement` | Pedido de Extrato |
| `request_discount` | Pedido de Desconto |
| `installment_request` | Parcelamento |
| `escalate_human` | Escalar p/ Humano |
| `complaint` | Reclamação |
| `greeting` | Saudação |
| `farewell` | Encerramento |
| `out_of_scope` | Fora do Escopo |

Intenção desconhecida vira `Title Case` a partir do slug.

A prop `side` (`"client" | "agent" | "both"`, default `both`) permite renderizar só um lado — ⚠️ A confirmar: não encontrei consumidor que use algo diferente de `both`.

---

## 14. Base de conhecimento / RAG

Arquivo raiz: `src/components/agent-ia/KnowledgeBase.tsx`. Três seções separadas por `Separator`, cada uma com um `SectionHeader` (ícone em caixa `bg-primary/10` + título + descrição).

| Seção | Ícone | Título | Descrição |
|---|---|---|---|
| 1 | `Upload` | **Enviar documento** | "Faça upload de arquivos JSON, PDF, Word ou Excel para indexar como chunks vetoriais." |
| 2 | `FileText` | **Documentos indexados** | Com agente: "Arquivos do agente selecionado. Suporta JSON, PDF, Word (.docx) e Excel (.xlsx)." · Sem agente: "Arquivos carregados nesta organização. Suporta JSON, PDF, Word (.docx) e Excel (.xlsx)." |
| 3 | `Search` | **Testar busca semântica** | "Simule uma consulta RAG para verificar quais chunks o agente receberia para um dado texto." |

Tudo é **escopado ao agente** quando `agentId` é passado (lista filtrada, upload vinculado, busca isolada).

### 14.1 `RagUploadForm`

Arquivo: `src/components/agent-ia/RagUploadForm.tsx`.

**Sem permissão de escrita**, o formulário inteiro é substituído por:
> `Alert` com ícone `AlertCircle`: "Você não tem permissão para enviar documentos. Contate um administrador."

| Campo | Detalhe |
|---|---|
| **Nome do documento** | `Input` id `rag-doc-name`, placeholder "Ex: FAQ Clientes, Políticas de Cobrança..." — obrigatório |
| **Visibilidade** | `Select` id `rag-visibility` com **"Todos os contatos"** (default, sentinela `__all__`) + a lista de filtros de configuração de IA. Hint dinâmico: *"Este documento será disponibilizado apenas para contatos que atendem ao filtro selecionado."* ou *"Este documento será disponibilizado para todos os contatos."* |
| **Arquivo (JSON, PDF, Word, Excel)** | `Input type=file` com `accept=".json,.pdf,.docx,.doc,.xlsx,.xls"` |

**Validação de extensão** (`ACCEPTED_EXTENSIONS`): `.json`, `.pdf`, `.docx`, `.doc`, `.xlsx`, `.xls`. Erro exibido em `text-destructive` com ícone:
> **"Formato não suportado. Use JSON, PDF, Word (.docx) ou Excel (.xlsx)."**

**Arquivo selecionado**: ícone por formato (`FileJson` para JSON; `FileText` para PDF/Word; `FileSpreadsheet` para Excel), nome e badge com o tamanho formatado (`B` / `KB` / `MB`).

**Estados do envio:**

| Estado | Render |
|---|---|
| Sucesso | `Alert` verde com `CheckCircle`: "Documento enviado. O processamento de embeddings foi iniciado e pode levar alguns minutos." (some após 3 s) |
| Erro | `Alert variant="destructive"`: "Erro ao enviar o documento. Tente novamente." (some após 5 s) |
| Enviando | Botão vira **"Enviando..."** com `Loader2` |

Toasts: **"Documento enviado"** / "O processamento foi iniciado." · **"Erro no upload"** + mensagem.

Botão: **"Enviar documento"** (ícone `Upload`), desabilitado sem arquivo, sem nome ou durante o envio. No sucesso, o formulário é **limpo** (nome, arquivo, filtro e o `input[type=file]`).

### 14.2 `RagDocumentList`

Arquivo: `src/components/agent-ia/RagDocumentList.tsx`. Tabela com 7 colunas:

| Coluna | Conteúdo | Visibilidade responsiva |
|---|---|---|
| **Nome** | `doc.name`; abaixo, `error_message` em `text-destructive` quando `status = error` | sempre |
| **Arquivo original** | nome + badge de formato colorido | `hidden sm:table-cell` |
| **Chunks** | `total_chunks` (pt-BR, alinhado à direita, `tabular-nums`) | sempre |
| **Status** | `StatusBadge` | sempre |
| **Visibilidade** | badge `outline` com ícone `Filter` + nome do filtro, ou o texto **"Todos"** | `hidden lg:table-cell` |
| **Data** | `dd/mm/aaaa` | `hidden md:table-cell` |
| **Ações** | 4 botões ghost | sempre |

**Badges de formato** (`getFormatBadge`): **JSON** (neutro) · **PDF** (rosa) · **Word** (azul) · **Excel** (verde) · **FILE** (neutro, fallback).

**Badges de status** (`StatusBadge`):

| `status` | Rótulo | Estilo |
|---|---|---|
| `pending` | **Aguardando** | `secondary` |
| `processing` | **Processando** | `outline` com borda/texto amarelos |
| `ready` | **Pronto** | `default` com fundo/texto verdes |
| `error` | **Erro** | `destructive` |

**Ações por linha** (cada uma vira `Loader2` enquanto pendente; todas as outras ficam desabilitadas durante uma ação daquela linha):

| Botão | Ícone | Condição | Toast |
|---|---|---|---|
| **Abrir arquivo** | `Eye` | desabilitado sem `storage_path` | Erro: **"Erro ao abrir arquivo"** + mensagem |
| **Baixar arquivo original** | `Download` | desabilitado sem `storage_path` | Sucesso: **"Download iniciado"** / "O link expira em 5 minutos." · Erro: **"Erro ao baixar"** |
| **Re-processar documento** | `RefreshCw` | só com `agent-ia:write`; desabilitado enquanto `processing` | Sucesso: **"Reprocessamento iniciado"** / nome do doc · Erro: **"Erro ao reprocessar"** |
| **Deletar documento** | `Trash2` (destrutivo) | só com `agent-ia:write` | Sucesso: **"Documento removido"** / nome · Erro: **"Erro ao deletar"** |

**Modal de exclusão** (`AlertDialog`):
- Título: **"Deletar documento?"**
- Descrição: "O documento **{nome}** e todos os seus chunks serão removidos permanentemente. Essa ação não pode ser desfeita."
- Botões: **Cancelar** · **Deletar** (destrutivo)

**Estados da lista:**

| Estado | Render |
|---|---|
| Carregando | `Loader2` + **"Carregando documentos..."** (centralizado, `py-12`) |
| Erro | Ícone `AlertCircle` + **"Erro ao carregar documentos."** em `text-destructive` |
| Vazio | Card com `FileJson` 40px, **"Nenhum documento carregado ainda."** e "Use o formulário acima para enviar um arquivo JSON, PDF, Word ou Excel." |

### 14.3 `RagQueryTester`

Arquivo: `src/components/agent-ia/RagQueryTester.tsx`.

**Formulário:**

| Campo | Detalhe |
|---|---|
| **Consulta** | `Textarea` 3 linhas, id `rag-query-text`, placeholder "Digite a pergunta ou texto para buscar na base de conhecimento..." |
| **Número de resultados (top_k)** | `Input type=number`, min 1, max 20, default **5** |
| **Threshold de similaridade** *(0–1)* | `Input type=number`, min 0, max 1, step 0.05, default **0.7** |
| **CNPJ do contato** *(opcional — avalia documentos com filtro)* | `Input`, placeholder `00.000.000/0000-00` |

Botão **"Buscar"** (ícone `Search`; vira **"Buscando..."** com spinner), desabilitado sem consulta.
Digitar na consulta **reseta** o resultado/erro anterior.

**Resultados:**
- Cabeçalho: **"{n} resultado(s) encontrado(s)"** ou **"Nenhum resultado encontrado"**; badge `secondary` **"{n} exibido(s)"**.
- **`ChunkCard`** por chunk: nome do documento + **`SimilarityBadge`** (`{n}% similar`, verde ≥ 80%, amarelo 70–79%, vermelho < 70%); conteúdo com `whitespace-pre-wrap`, truncado em **300 caracteres** com botão **"Mostrar mais"** / **"Mostrar menos"** (chevrons).
- Zero chunks acima do threshold: card com ícone `Search` + *"Nenhum chunk encontrado com similaridade acima de {n}%."* + *"Tente reduzir o threshold ou usar termos diferentes."*
- Erro: `Alert variant="destructive"` com a mensagem do erro (fallback "Erro ao executar a busca.").
- Estado inicial: card com `Search` 32px + **"Faça uma busca para ver os resultados"**.

---

## 15. Configuração de tags

Tags aparecem em **três lugares diferentes** neste módulo, e o redesenho **não pode fundi-los**:

| Camada | Escopo | Onde se edita | Tabela |
|---|---|---|---|
| **Catálogo de tags de conversa/intenção** | **Organização** (compartilhado por todos os agentes) | `/agent-ia/tags` (`AgentTagsPage`) ou aba **Tags** do workspace | `tag_catalog` |
| **Whitelist de tags permitidas** | **Um agente** (restringe o catálogo acima) | aba **Tags** do workspace (`AgentAllowedTagsConfig`) | `agent_allowed_tags` + `ai_agents.allowed_tags_mode` |
| **Tags de transferência** | **Um agente** (catálogo próprio, não é o `tag_catalog`) | aba **Funil** → sub-aba *Tags de Transferência* (`TransferTagsConfig`) | `transfer_tags` |

### 15.1 Página `/agent-ia/tags` — `AgentTagsPage`

Arquivo: `src/pages/AgentTagsPage.tsx`. É uma página **fina**: ela só desenha o cabeçalho e delega todo o CRUD ao `TagCatalogTab` (o **mesmo** componente usado em Configurações).

```
[← Voltar para a galeria]                          ghost, sm, -ml-2

┌ hero (rounded-xl, border, gradient from-primary/5 via-background) ─────┐
│ [□ ícone Tag 24px em caixa 48×48 rounded-xl border-primary/20]        │
│ H1 "Tags da organização"                          text-2xl font-bold  │
│ p  "Catálogo de tags de conversa e intenção compartilhado por todos   │
│     os agentes de IA da organização. Alterações aqui valem para       │
│     todos os agentes."                                                │
└───────────────────────────────────────────────────────────────────────┘

<TagCatalogTab canWrite={hasPermission("agent-ia:write")} />
```

| Elemento | Detalhe |
|---|---|
| Botão de volta | `Button variant="ghost" size="sm"` como `Link` para `/agent-ia`, com `ArrowLeft` |
| Ícone do hero | `Tag` (lucide) `h-6 w-6 text-primary`, em caixa com `bg-primary/10` e `shadow-sm` |
| Espaçamento | `space-y-6` no container; hero com `p-6` |

**Regra de permissão que o redesenho precisa preservar:** dentro da área de Agentes de IA a escrita segue **`agent-ia:write`** — **não** se exige `settings:write`. O mesmo `TagCatalogTab`, quando renderizado na página de **Configurações**, continua exigindo `settings:write`. Ou seja: o componente é o mesmo, a permissão é injetada pela página (`canWrite`).

**Regra de roteamento:** a rota estática `/agent-ia/tags` é declarada **antes** de `/agent-ia/:agentId` em `src/App.tsx`; se a ordem inverter, `"tags"` passa a ser lido como um `agentId` e a página quebra.

> ⚠️ A confirmar: o detalhamento interno do `TagCatalogTab` (formulário de criação, colunas da tabela, diálogos) não foi coberto nesta leitura — ele vive em `src/components/settings/tabs/TagCatalogTab.tsx` e é compartilhado com o módulo de Configurações. Os pontos citados nas seções 2.1 e 9.3 (tipos `conversation`/`intent`, `is_system` não editável) vieram daquele arquivo.

### 15.2 `AgentAllowedTagsConfig` — whitelist por agente

Arquivo: `src/components/ia/AgentAllowedTagsConfig.tsx`. Props: `agentId` (obrigatório na prática — sem ele a tela fica read-only) e `readOnly`.

#### Modelo conceitual (o que não pode ser simplificado)

O modo é **explícito** (`ai_agents.allowed_tags_mode`), **não** inferido por "whitelist vazia":

| `allowed_tags_mode` | Significado |
|---|---|
| `all` | O agente pode usar o **catálogo inteiro** da organização, inclusive tags criadas no futuro |
| `restricted` | O agente fica restrito às tags marcadas — e **zero tags marcadas é um estado válido**: o agente não usa nenhuma tag. **Não volta sozinho para `all`.** |

Comentário do código: *"Remover a ÚLTIMA tag selecionada em modo restricted e salvar resulta em NENHUMA tag ativa — NÃO reverte silenciosamente para 'all'."*

#### Anatomia

```
┌ header ────────────────────────────────────────────────────────────────┐
│ H3 [ListChecks] "Tags permitidas para este agente"                     │
│    [badge outline: 🤖 Escopo: Este agente]                             │
│ p  "Restrinja quais tags do catálogo este agente pode aplicar nas      │
│     conversas."                                                        │
│                          (direita) [badge do estado SALVO]             │
│                                    [badge outline "Alterações não      │
│                                     salvas"]  ← só quando dirty        │
└────────────────────────────────────────────────────────────────────────┘

[Alert · ícone Info · "Como funciona"]
   "Todas as tags: o agente pode usar o catálogo inteiro da organização.
    Somente selecionadas: o agente fica restrito às tags marcadas abaixo —
    se nenhuma estiver marcada, o agente não usa nenhuma tag (não volta
    automaticamente para 'todas')."

[bloco tracejado "Modo somente leitura"]   ← só quando readOnly

( ) Todas as tags     ( ) Somente selecionadas       RadioGroup

[conteúdo condicional — ver tabela abaixo]

                                 [Descartar alterações] [Salvar]   ← só se dirty
```

#### Badge do estado salvo (canto superior direito)

| Estado no servidor | Badge |
|---|---|
| `all` | `secondary` — **"Todas as tags permitidas"** |
| `restricted` | `default` — **"{n} selecionada"** / **"{n} selecionadas"** |
| Rascunho diferente do servidor | acrescenta `outline` — **"Alterações não salvas"** |

#### Conteúdo condicional

| Condição | Render |
|---|---|
| Carregando (catálogo, modo ou whitelist) | `Card` com **4 `Skeleton`** de altura 10 |
| `localMode === "all"` | Bloco tracejado: **"O agente pode usar todas as tags do catálogo desta organização."** |
| `restricted` **e catálogo vazio** | `Card` com ícone `Tag` 40px, **"Nenhuma tag no catálogo"** e "Cadastre tags no catálogo da organização (abaixo) para poder restringir o agente a um subconjunto delas." |
| `restricted` **com catálogo** | `Card` "Catálogo da organização" (ícone `Tag`), descrição **"{n} tag disponível/tags disponíveis — marque as tags permitidas para este agente."**, corpo com `<ul className="divide-y">` |

**Linha de tag** (`<li>`, `px-4 py-3`):

| Região | Conteúdo |
|---|---|
| Esquerda | `Badge outline` colorido com o `label` da tag + `name` em `font-mono text-xs`; abaixo, `description` truncada (com `title` completo) |
| Direita | `Checkbox` com `aria-label="Permitir a tag {label} para este agente"` |

**Paleta (`COLOR_MAP`)** — mesma do catálogo de tags: `gray`, `green`, `blue`, `yellow`, `red`, `orange`, `purple`. Cor desconhecida cai em `gray`.

#### Rascunho local e ciclo de salvamento

| Comportamento | Detalhe |
|---|---|
| **Hidratação única** | O rascunho local é hidratado do servidor **uma vez por agente** (`syncedForAgentRef`). Refetch de fundo **não apaga** o que o usuário está editando |
| **Dirty** | `localMode !== serverMode` **ou** conjunto de ids diferente (`sameIdSet`) |
| **Guard de saída** | `useDirtyFormGuard(canWrite && isDirty)` — trocar de aba/sub-aba/agente com seleção não salva **pergunta antes de descartar**; fora do workspace, instala apenas o `beforeunload` |
| **Salvamento transacional** | `useSetAgentAllowedTags` → RPC `set_agent_allowed_tags` grava **modo + conjunto numa única chamada**. Nunca duas mutations divergentes |
| **Payload** | `tagIds` é enviado como `[]` quando o modo é `all` |
| **Descartar** | Restaura modo e seleção do servidor, sem chamar o banco |

#### Confirmação de ampliação de acesso

Só existe fricção em **um** caminho: **`restricted` (salvo) → `all` (rascunho)**. Estreitar (`all` → `restricted`) e permanecer `restricted` com zero tags salvam **direto**.

| Campo | Conteúdo |
|---|---|
| Gatilho | Clique em **Salvar** com `serverMode === "restricted" && localMode === "all"` |
| Tipo | `AlertDialog` |
| Título | **"Liberar todas as tags para este agente?"** |
| Descrição | "Este agente está restrito a um subconjunto de tags hoje. Ao confirmar, ele passará a poder usar **todas** as tags do catálogo da organização, inclusive as que forem criadas no futuro." |
| Botões | **Cancelar** · **Confirmar** (ambos desabilitados enquanto `isPending`) |
| Destrutivo? | Não destrutivo, mas **amplia permissão** — é uma escalada |

#### Toasts

| Resultado | Toast |
|---|---|
| Sucesso, modo `all` | **"Configuração salva"** / "O agente pode usar todas as tags da organização." |
| Sucesso, modo `restricted` | **"Configuração salva"** / "O agente pode usar {n} tag(s) selecionada(s)." |
| Erro | **"Erro ao salvar"** / mensagem do erro, `variant="destructive"` |

### 15.3 `TransferTagsConfig` — catálogo de tags de transferência do agente

Arquivo: `src/components/ia/TransferTagsConfig.tsx`. Props: `agentId`, `readOnly`.

É o catálogo **do agente** (não da organização) com os **motivos** de transferência/transbordo que o n8n informa ao encerrar transferindo para humano.

#### Anatomia

```
┌ header ────────────────────────────────────────────────────────────────┐
│ H2 "Tags de Transferencia"  [badge outline: 🤖 Escopo: Este agente]    │
│ p  "Motivo do transbordo/transferencia quando o agente encerra a       │
│     conversa transferindo para um humano."                             │
│                                              [+ Nova tag]              │
└────────────────────────────────────────────────────────────────────────┘

[bloco tracejado "Modo somente leitura - crie um rascunho para editar"]

┌ Card tracejado (bg-muted/50) · ícone ArrowRightLeft ───────────────────┐
│ "Transbordo vs Transferencia"                                          │
│ "Transbordo: A IA nao conseguiu resolver e transferiu (falha).         │
│  Transferencia: Transferencia por motivo correto/esperado."            │
│ "Trocar o tipo de uma tag vale a partir de agora — as metricas ja      │
│  registradas continuam com o tipo que estava vigente na epoca."        │
└────────────────────────────────────────────────────────────────────────┘

[Tabela de tags]  ou  [empty state]
```

#### Os dois tipos (`TYPE_META`)

| Valor | Rótulo | Cor do badge | Descrição exibida |
|---|---|---|---|
| `overflow` | **Transbordo** | vermelho (`bg-red-100 text-red-800 border-red-200`) | "A IA nao conseguiu resolver e transferiu (falha)." |
| `transfer` | **Transferencia** | azul (`bg-blue-100 text-blue-800 border-blue-200`) | "Transferencia por motivo correto/esperado." |
| *(sem tipo vigente)* | **Nao definido** | `outline` com `text-muted-foreground` | — |

> ⚠️ Observação de conteúdo: os textos deste componente estão **sem acentuação** no código-fonte ("Transferencia", "metricas", "acao"). Os componentes vizinhos (ex.: `AgentAllowedTagsConfig`) usam acentos. Um redesenho é a oportunidade de uniformizar — mas **é mudança de copy**, não só de layout.

#### Tabela de tags

`Card` com título **"Tags"** (ícone `Tag`) e descrição **"{n} tag cadastrada / tags cadastradas"**. Cinco colunas:

| Coluna | Conteúdo |
|---|---|
| **Label** | `Badge outline` colorido com o `label`; abaixo, `description` truncada (`max-w-xs`, `title` completo) |
| **Chave (slug)** | `font-mono text-sm text-muted-foreground` |
| **Tipo vigente** | `<button>` com o `TypeBadge` + ícone `ArrowRightLeft` (quando há escrita); `title="Trocar tipo"`; abre o diálogo de troca de tipo |
| **Status** | `secondary` **"Ativa"** ou `outline` **"Inativa"** |
| **Ações** (direita) | `Pencil` (`aria-label="Editar tag {label}"`) e `Trash2` destrutivo (`aria-label="Excluir tag {label}"`) — só com escrita |

Linha de tag **inativa** recebe `opacity-60`.

**Empty state:** `Card` com ícone `Tag` 40px, **"Nenhuma tag cadastrada"**, "Cadastre os motivos de transferencia deste agente para classificar os transbordos e transferencias nas metricas." e, com escrita, botão `outline` **"Criar primeira tag"**.

**Carregando:** `Loader2` 32px centralizado (`py-12`).

#### Modal — criar/editar tag de transferência (`TagFormDialog`)

| Campo | Conteúdo |
|---|---|
| **Objetivo** | Cadastrar ou editar um motivo de transferência do agente |
| **Gatilho** | Botão **"Nova tag"** / **"Criar primeira tag"** (criação) ou o ícone `Pencil` da linha (edição) |
| **Tipo** | `Dialog` `sm:max-w-md` |
| **Título** | "Nova tag de transferencia" / "Editar tag de transferencia" |
| **Descrição** | Criação: "Defina o motivo e o tipo agora. A tag nasce inativa e é ativada automaticamente assim que o tipo for classificado." · Edição: "Rotulo do motivo do transbordo/transferencia." |

Campos:

| Campo | Modo | Detalhe |
|---|---|---|
| **Label** `*` | ambos | `Input` `id="tt-label"`, `autoFocus`, placeholder "Ex: Cliente pediu atendente". Validação: obrigatório ("Label é obrigatório") |
| **Chave (slug)** `*` | **só criação** | `Input` `id="tt-slug"` `font-mono`, placeholder "Ex: cliente_pediu_atendente". Regex `^[a-z0-9_]+$` → "Use apenas letras minúsculas, números e _". Hint: "Enviado pelo n8n no evento de transferencia para identificar o motivo." **Auto-derivado do label** enquanto o usuário não digitar nele (`toSlug`: minúsculas, sem acento, espaços → `_`) |
| **Chave (slug)** | **edição** | **Somente leitura**, exibida em bloco `bg-muted font-mono`, com o aviso "A chave nao pode ser alterada: e usada pelo n8n para identificar o motivo." |
| **Descricao (opcional)** | ambos | `Textarea` 3 linhas, `id="tt-description"`. Hint: "Orienta o agente sobre **quando** usar esta tag e aparece no contexto do agente." |
| **Cor** | ambos | `ColorPicker` — `role="group"` `aria-label="Cor da tag de transferência"`, 7 pílulas (`Cinza`, `Verde`, `Azul`, `Amarelo`, `Vermelho`, `Laranja`, `Roxo`) com `aria-pressed` e `ring` na selecionada |
| **Tipo desta tag** `*` | **só criação** | `Select` `id="tt-type"` com **Transbordo** / **Transferencia**; abaixo, a descrição do tipo escolhido. Default: `transfer` |
| **Tag ativa** | **só edição** | Bloco com `Switch` e a nota "Tags inativas nao sao resolvidas na ingestao." |
| *(aviso de criação)* | só criação | Bloco tracejado: "A tag nasce inativa e é ativada automaticamente assim que o tipo acima for classificado com sucesso." |

**Botões:** **Cancelar** (`outline`) · **Criar tag** / **Salvar** (desabilitado quando não há alteração ou há requisição em voo; mostra `Loader2`).

**Cadeia de criação em 3 passos** (decisão de produto explícita no código — TAG.5):

```
1. create (is_active: false)   →  a tag NASCE INATIVA
2. setType(type)               →  classifica o tipo
3. update(is_active: true)     →  só então ativa
```

Motivo: fecha a janela em que uma tag aparecia **ativa e "Nao definido"**. Se qualquer passo falhar, a tag permanece **inativa**.

| Falha no passo | Toast (destrutivo) |
|---|---|
| Criação | **"Erro ao criar tag"** + mensagem |
| Tipo | **"Tag criada, mas falhou ao definir o tipo"** / "{erro} A tag ficou inativa — abra "Editar" e troque o tipo antes de ativá-la." — o diálogo **fecha** |
| Ativação | **"Tag criada e classificada, mas não foi possível ativá-la"** / "{erro} Abra "Editar" para ativar quando estiver pronto." — o diálogo **fecha** |
| Sucesso total | **"Tag de transferencia criada"** / "Classificada como {Tipo} e ativada." |

**Edição:** monta um **PATCH semântico** (`buildTransferTagPatch`) — envia **somente os campos alterados**; chave ausente = não alterar; `description: null` = limpar; o **slug nunca entra no patch**. Patch vazio → fecha o diálogo sem chamar o banco. Toast de sucesso: **"Tag de transferencia atualizada"**. **Erro não fecha o diálogo** (valores e foco preservados para retry): **"Erro ao atualizar tag"**.

**Confirmação de descarte:** fechar (X, Escape, clique fora, Cancelar) com formulário sujo abre um `AlertDialog`:
- Título: **"Descartar alterações?"**
- Descrição: "Há alterações não salvas neste formulário. Se você fechar agora, elas serão perdidas."
- Botões: **Continuar editando** · **Descartar**

O guard de saída do workspace também é registrado (`useDirtyFormGuard(open && isDirty)`).

#### Modal — trocar o tipo vigente (`ChangeTypeDialog`)

| Campo | Conteúdo |
|---|---|
| **Objetivo** | Reclassificar uma tag entre Transbordo e Transferência **a partir de agora** |
| **Gatilho** | Clique no `TypeBadge` da coluna "Tipo vigente" |
| **Tipo** | `Dialog` `sm:max-w-md` |
| **Título** | ícone `ArrowRightLeft` + **"Tipo da tag: {label}"** |
| **Descrição** | "Escolha se esta tag conta como Transbordo ou Transferencia daqui pra frente." |

Corpo:

1. **Linha de transição:** `Tipo atual:` + `TypeBadge` atual → (quando vai mudar) `ArrowRight` + `TypeBadge` novo.
2. **Select "Tipo vigente"** com os dois tipos; abaixo, a descrição do tipo escolhido.
3. **Aviso âmbar** (`border-amber-200 bg-amber-50`, ícone `AlertTriangle`):
   > "A mudanca vale **a partir de agora** e **nao altera as metricas passadas**. A partir de agora, essa tag conta como **{Tipo}**. O historico anterior permanece com o tipo que estava vigente na epoca."

**Botões:** **Cancelar** · **"Aplicar mudanca"** — que vira **"Sem alteracao"** e fica **desabilitado** quando o tipo selecionado é igual ao vigente.

| Resultado | Toast |
|---|---|
| Mudou (`res.changed`) | **"Tipo alterado para {Tipo}"** / "A mudanca vale a partir de agora. Metricas passadas nao mudam." |
| Não mudou | **"Tipo mantido (sem alteracao)"** |
| Erro | **"Erro ao trocar o tipo"** + mensagem (destrutivo) |

**Descarte:** fechar com seleção pendente abre `AlertDialog` **"Descartar alteração de tipo?"** / "O novo tipo ainda não foi aplicado. Se você fechar agora, a seleção será perdida." · **Continuar editando** / **Descartar**.

**Regra de sincronização:** ao abrir, a seleção é re-sincronizada com o tipo vigente — *"Tag overflow NUNCA abre como transfer."*

#### Modal — remover tag de transferência

| Campo | Conteúdo |
|---|---|
| **Objetivo** | Excluir uma tag do catálogo do agente |
| **Gatilho** | Ícone `Trash2` da linha |
| **Tipo** | `AlertDialog` — **destrutivo** |
| **Título** | **"Remover tag de transferencia"** |
| **Descrição** | "Tem certeza que deseja remover a tag **{label}**? Esta acao nao pode ser desfeita. As metricas historicas ja registradas nao sao afetadas." |

**Bloco de impacto** (buscado só ao abrir, via `useTransferTagUsageCount`):

| Estado | Render |
|---|---|
| Carregando | `Skeleton` `h-4 w-48` |
| Uso > 0 | Bloco âmbar com `AlertTriangle`: "Esta tag foi usada em **{n}** interação(ões) registrada(s). As métricas históricas já registradas não são afetadas ao remover." |
| Uso = 0 | "Nenhuma interação registrada usa esta tag no momento." |

**Botões:** **Cancelar** · **Remover** (destrutivo; vira **"Removendo..."**). Toasts: **"Tag removida"** / **"Erro ao remover tag"** + mensagem.

---

## 16. Etapas do funil (`FunnelStagesConfig`)

Arquivo: `src/components/ia/FunnelStagesConfig.tsx`. Props: `versionId` (recebido mas **não usado** — as etapas são escopadas por agente, com `version_id = null`), `agentId`, `readOnly`.

### 16.1 O que a tela faz

Define **quais eventos o agente externo deve notificar** e, opcionalmente, o que a Torre faz ao receber cada evento. As etapas são **ordenáveis por arrastar** e a ordem (`display_order`) é o que define a sequência do funil nas métricas.

```
┌ header ────────────────────────────────────────────────────────────────┐
│ H2 "Etapas do Funil"                                 [+ Nova Etapa]    │
│ p  "Configure quais eventos o agente externo deve notificar"           │
└────────────────────────────────────────────────────────────────────────┘

[bloco tracejado "Modo somente leitura - crie um rascunho para editar"]

┌ Card tracejado (bg-muted/50) · ícone Target ──────────────────────────┐
│ "Como funciona?"                                                       │
│ "O agente externo (WhatsApp/N8N) enviará webhooks para a Torre de      │
│  Controle quando cada etapa configurada for atingida. Você pode        │
│  definir ações automáticas para cada evento recebido.                  │
│  **Arraste as etapas** para reordenar."                                │
└────────────────────────────────────────────────────────────────────────┘

[lista ordenável de etapas — DndContext + SortableContext vertical]
```

**Carregando:** `Loader2` 32px centralizado (`py-12`).

### 16.2 Linha de etapa (`SortableStageItem`)

Cada etapa é um `Card` (`CardContent py-4`) em linha horizontal:

| Região | Conteúdo |
|---|---|
| **Handle de arraste** | `GripVertical` 20px em área `cursor-grab` / `active:cursor-grabbing`, com `aria-label="Reordenar etapa: {stage_name}"` e anel de foco visível. **Oculto em `readOnly`** |
| **Número da ordem** | Círculo 32×32 `bg-muted` com o índice + 1 |
| **Ícone** | Ícone da etapa em caixa `rounded-lg border` colorida pela cor da etapa |
| **Info** | `stage_name` em `font-medium` + `Badge outline font-mono` com o `stage_key`; abaixo, `description` truncada |
| **Ação automática** | Quando existe: `ArrowRight` + ícone da ação + rótulo da ação, em `text-xs text-muted-foreground` |
| **Controles** (só com escrita) | `Switch` **Webhook** (desabilitado quando a etapa está inativa) · `Switch` **Ativo** · `Button` ícone `Settings` com `aria-label="Configurar etapa: {stage_name}"` |

Etapa **inativa** recebe `opacity-50`; a linha sendo arrastada recebe `opacity-0.5` + `shadow-lg ring-2 ring-primary`.

Os dois `Switch` gravam **imediatamente** (`updateStage.mutateAsync`) — não há botão de salvar para eles.

### 16.3 Catálogo de ícones e cores

**Ícones (`STAGE_ICONS`)** — 10 opções, expostas pelo **nome técnico** no `Select`:

`MessageCircle` · `CreditCard` · `Calendar` · `RefreshCw` · `CheckCircle` · `User` · `DollarSign` · `XCircle` · `Target` · `Bell`

Ícone desconhecido cai em `Target`.

> ⚠️ O `Select` de ícone mostra o **nome em inglês do componente lucide** (ex.: "CreditCard"), não um rótulo em português. É uma dívida de copy visível ao usuário final.

**Cores (`STAGE_COLORS`)** — 8 opções, também expostas pela **chave crua**: `blue`, `yellow`, `green`, `orange`, `emerald`, `purple`, `gray`, `red`. Cada uma é um trio `bg-{cor}-100 text-{cor}-700 border-{cor}-200`. Cor desconhecida cai em `gray`.

### 16.4 Ações automáticas (`FUNNEL_AUTO_ACTIONS`, `src/types/ai.ts`)

| Valor | Ícone | Campo de configuração que aparece ao escolher |
|---|---|---|
| `update_status` | `CheckCircle` | **Novo Status** — `Input`, placeholder "Ex: em_negociacao, aguardando_pagamento" → `auto_action_config.new_status` |
| `create_task` | `ListTodo` | **Descrição da Tarefa** — `Textarea` 2 linhas, placeholder "Ex: Verificar se cliente realizou pagamento" → `auto_action_config.task_description` |
| `send_notification` | `Bell` | **Mensagem da Notificação** — `Textarea` 2 linhas, placeholder "Ex: Cliente {{contact_name}} atingiu etapa de pagamento" → `auto_action_config.message` |
| `trigger_workflow` | `Workflow` | *(nenhum campo extra renderizado)* |

O `label` e a `description` de cada ação vêm de `FUNNEL_AUTO_ACTIONS` em `src/types/ai.ts`; a descrição aparece abaixo do `Select` assim que uma ação é escolhida. A opção **"Nenhuma ação automática"** (valor sentinela `none`) grava `null`.

### 16.5 Reordenação (drag-and-drop)

| Aspecto | Detalhe |
|---|---|
| Biblioteca | `@dnd-kit` (`DndContext`, `SortableContext` com `verticalListSortingStrategy`) |
| Sensores | `PointerSensor` **e** `KeyboardSensor` com `sortableKeyboardCoordinates` — **a reordenação funciona pelo teclado** |
| Detecção de colisão | `closestCenter` |
| Efeito | Ao soltar, **todas** as etapas recebem `display_order = índice + 1` numa única `reorderStages.mutateAsync({ stages, versionId: null })` |
| `readOnly` | `useSortable({ disabled: readOnly })` — o handle nem é renderizado |

### 16.6 Modal — Nova Etapa do Funil

| Campo | Conteúdo |
|---|---|
| **Objetivo** | Criar uma etapa que o agente externo passará a notificar |
| **Gatilho** | Botão **"Nova Etapa"** (ícone `Plus`), desabilitado em `readOnly` |
| **Tipo** | `Dialog` |
| **Título** | **"Nova Etapa do Funil"** |
| **Descrição** | "Crie uma nova etapa para o agente notificar" |

| Campo do formulário | Detalhe |
|---|---|
| **Nome da Etapa** `*` | `Input`, placeholder "Ex: Acordo Parcial" |
| **Chave (slug)** `*` | `Input`, placeholder "Ex: partial_agreement". **Normalizada no submit**: minúsculas + espaços → `_` |
| **Descrição** | `Textarea` 2 linhas, placeholder "Descreva quando esta etapa é atingida..." |
| **Ícone** | `Select` com os 10 ícones (ícone + nome) |
| **Cor** | `Select` com as 8 cores (amostra quadrada + nome) |

**Botões:** **Cancelar** · **Criar Etapa** (desabilitado sem nome **ou** sem chave, ou durante o envio; mostra `Loader2`).

**Valores enviados na criação:** `agent_id`, `version_id: null`, `stage_key` normalizado, `stage_name`, `description`, `icon`, `color`, `display_order = (nº de etapas) + 1`.

> Nota: os campos **is_active**, **notify_webhook** e **ação automática** existem no estado do formulário de criação (`is_active: true`, `notify_webhook: true`, `auto_action: null`) mas **não são renderizados nem enviados** no diálogo de criação — a etapa nasce com os defaults do banco e se configura depois, pelo diálogo de edição. ⚠️ A confirmar: se o default do banco para `notify_webhook` coincide com o `true` do estado local.

### 16.7 Modal — Configurar Etapa

| Campo | Conteúdo |
|---|---|
| **Objetivo** | Editar aparência, ativação, webhook e ação automática de uma etapa |
| **Gatilho** | Botão `Settings` da linha |
| **Tipo** | `Dialog` |
| **Título** | **"Configurar Etapa: {stage_name}"** |
| **Descrição** | "Defina o comportamento quando este evento for recebido" |

| Campo | Detalhe |
|---|---|
| **Nome da Etapa** | `Input` editável |
| **Chave (slug)** | `Input` **desabilitado** (`bg-muted`) — imutável |
| **Descrição** | `Textarea` 2 linhas |
| **Ícone** / **Cor** | Mesmos `Select` da criação |
| **Etapa Ativa** | Bloco com `Switch` — "Processar eventos desta etapa" |
| **Notificar via Webhook** | Bloco com `Switch` — "Enviar ao agente externo" |
| **Ação Automática (Opcional)** | `Select` (ver 16.4) + campo de configuração condicional |

**Rodapé** com `justify-between`:
- **Esquerda:** botão `destructive` **Excluir** (ícone `Trash2`; vira `Loader2` enquanto pendente)
- **Direita:** **Cancelar** (`outline`) · **Salvar** (com `Loader2`)

**Exclusão de etapa — ponto crítico do redesenho:**

> A confirmação usa **`window.confirm("Tem certeza que deseja excluir esta etapa?")`** — um diálogo **nativo do navegador**, não um `AlertDialog` do design system. É a única exclusão do módulo que faz isso. Não declara impacto (quantos protocolos passaram pela etapa, se ela aparece em métricas históricas) e não é estilizável.
>
> **Recomendação para o redesenho:** trocar por `AlertDialog` destrutivo, no padrão das demais exclusões (tag de transferência, documento RAG, agente), com declaração de impacto.

### 16.8 Guard de alterações não salvas

O formulário usa um **snapshot** (`formBaseline = JSON.stringify(formData)` no momento da abertura); `isFormDirty` compara o estado atual com ele. `useDirtyFormGuard(isFormDirty)` devolve `confirmIfDirty`, aplicado em **todos** os caminhos de fechamento (X, Escape, clique fora, Cancelar) dos **dois** diálogos.

---

## 17. Fechamento A2A e integração n8n

### 17.1 Diálogo "Integração N8N" (`AgentN8NIntegration`)

Arquivo: `src/components/ia/AgentN8NIntegration.tsx`. Renderiza **apenas o corpo** — o título e a descrição vêm do `Dialog` que o embute (`AgentWorkspace`).

```
[CopyRow  agent_slug   {slug}    "Parâmetro recomendado (?agent_slug= na URL
                                  ou no payload do webhook)"]
[CopyRow  agent_id     {uuid}    "Alternativa ao slug (?agent_id=)"]

HEADERS OBRIGATÓRIOS                       (uppercase, tracking-wide, 12px)
[CopyRow  x-org-slug   {org.slug} "Organização ativa (também aceito como
                                   X-Active-Org)"]
[linha    x-api-key   [badge "Sua API key universal"]
                      "Gere/copie em Configurações → Integrações → API Keys"]

[A2AClosureSettingsCard]      ← SOMENTE para agent_type === "internal"
```

**Anatomia do `CopyRow`:** bloco `rounded-md border bg-muted/30 p-3`, com rótulo em `text-xs font-medium text-muted-foreground`, valor truncado em `font-mono` (com `title` completo) e botão `outline sm` à direita.

| Estado do botão | Render |
|---|---|
| Padrão | ícone `Copy` + **"Copiar"**; `title="Copiar {label}"` |
| Após copiar | ícone `Check` em `text-primary` + **"Copiado"**, por **1500 ms** |
| Clipboard indisponível | Falha **silenciosa** (contexto inseguro) — ⚠️ nenhum feedback é dado ao usuário. Candidato a melhoria no redesenho |

**A linha `x-api-key` não é copiável** — ela só aponta onde obter a chave. É a única linha do bloco sem botão.

**Rotas que consomem esses identificadores** (documentadas no cabeçalho do arquivo):
```
GET /api/ai/agent?agent_slug=...
GET /api/ai/agent-context?contact_id=...&agent_slug=...
payload do ai-conversation-webhook: { ..., agent_slug }
```

### 17.2 `A2AClosureSettingsCard` — fechamento automático de protocolos A2A

Arquivo: `src/components/ia/A2AClosureSettingsCard.tsx` + `src/hooks/useA2AClosureSettings.ts`.

#### Modelo de execução (o que a UI está configurando)

```
SUPERVISOR GLOBAL (um só, toda a plataforma, bate a cada minuto)
   └─ varre agentes cuja verificação venceu
      └─ enfileira protocolos A2A parados há N horas
         └─ WORKER GLOBAL: UM POST por protocolo para a URL deste agente,
            respeitando o intervalo mínimo entre envios
            └─ n8n lê a transcrição, aplica as tags e chama a finalização
```

**Nota do código que o redesenho não pode contrariar:** *"Os campos de cadência NÃO criam um cron por agente — eles só decidem quando este agente entra na varredura e com que espaçamento os envios saem."*

Além disso: **2xx do n8n significa `accepted`, nunca `closed`** — só a finalização explícita fecha o protocolo.

#### Escopo e permissão

| Regra | Efeito na UI |
|---|---|
| **Exclusivo de agente `internal`** | Para agente externo o card **não é renderizado** (`supported === false` → `return null`). *"Controle desabilitado sugeriria que basta um clique para habilitar algo que o banco rejeita."* |
| **Escrita só `owner`/`admin`** | Todos os campos ficam `disabled`; aparece a nota **"Somente owner ou admin da organização podem alterar esta configuração."** |

#### Cabeçalho e estados de carga

| Estado | Render |
|---|---|
| **Carregando** | Bloco com `Loader2` + **"Carregando configuração do fechamento A2A…"** |
| **Erro de leitura** | `role="alert"`, bloco `border-destructive/40 bg-destructive/5` com `AlertTriangle`, **"Não foi possível carregar a configuração do fechamento A2A."** + botão **"Tentar novamente"**. *Falha de leitura **nunca** vira "não configurado": o operador reconfiguraria um fechamento que já está ativo* |
| **Refetch em fundo** | `Loader2` 12px discreto ao lado do badge |

**Badge de status** (`data-testid="a2a-closure-status"`):

| Situação | Badge |
|---|---|
| Configurado **e** habilitado | `secondary` com `ShieldCheck` — **"Ativo"** |
| Configurado **e** desabilitado | `secondary` com `ShieldCheck` — **"Configurado (pausado)"** |
| Sem URL gravada | `outline` — **"Não configurado"** |

**Título:** "Fechamento automático A2A" em `text-xs font-semibold uppercase tracking-wide`.

**Texto explicativo fixo:**
> "Um supervisor global (um só, para toda a plataforma) verifica os protocolos A2A deste agente na cadência definida abaixo. Os que estiverem sem mensagem nova há mais que o tempo de inatividade são enviados **um a um** para este webhook, respeitando o intervalo mínimo entre envios. O n8n lê a transcrição, aplica as tags e chama a finalização."

#### Campos

| Campo | Controle | Faixa (min/max/default) | Observação |
|---|---|---|---|
| **URL do webhook (https)** | `Input type="url"` | — | Placeholder muda: **"Deixe em branco para manter a URL atual"** (configurado) ou `"https://…"` |
| **Inatividade (horas)** | `Input type="number"` `w-28` | 1 / 168 / **6** | Tempo sem mensagem nova para o protocolo entrar na fila |
| **Verificar protocolos a cada (minutos)** | `Input type="number"` `w-36` | 1 / 10080 / **360** | Cadência **lógica** da varredura |
| **Intervalo mínimo entre envios (minutos)** | `Input type="number"` `w-40` | 1 / 1440 / **1** | Espaçamento entre dois POSTs deste agente |
| **Fechamento habilitado** | `Switch` | — | Habilitar sem URL é recusado pelo banco |

**Validação local (`limitError`)** — mensagem em `role="alert"` `text-destructive`, e o botão **Salvar** fica desabilitado:

| Campo fora da faixa | Texto |
|---|---|
| Horas | "As horas de inatividade precisam estar entre 1 e 168." |
| Verificação | "A verificação de protocolos precisa estar entre 1 e 10080 minutos." |
| Envios | "O intervalo mínimo entre envios precisa estar entre 1 e 1440 minutos." |

#### A URL é credencial — regras que o redesenho não pode afrouxar

| Regra | Motivo declarado no código |
|---|---|
| **A URL salva nunca reaparece na tela** | Ela carrega o token no path/query; reexibi-la a colocaria no DOM e no histórico do navegador. O banco devolve só `webhook_host_masked` (ex.: `n8n****com`) |
| **Linha "Destino atual"** | `Destino atual: {host mascarado} · a URL completa não é exibida novamente.` |
| **Campo vazio = manter** | Salvar sem digitar nada **mantém** a URL gravada — é assim que se mexe no switch sem ter a credencial em mãos |
| **Sucesso limpa o input imediatamente** | Deixar o valor manteria o token vivo no DOM, no devtools e em qualquer captura de tela, mesmo com o segredo já guardado |
| **Remoção é ação própria** | Apagar o input **não** remove nada (vazio = manter). A remoção explícita usa `webhookUrl: ""` |
| **Teste sai do servidor** | O navegador nunca chama o n8n direto — isso exporia a URL e pularia a validação de SSRF |

**Sugestão padrão:** só na **primeira** configuração, o backend pode devolver `default_webhook_url` (só para agente interno vivo e ainda sem URL). A UI preenche o campo uma única vez e mostra: **"Sugestão padrão preenchida. Confira e salve para aplicar."** A sugestão **nunca é gravada sozinha** — salvar continua sendo ação explícita de owner/admin.

#### Botões de ação

| Botão | Habilitado quando | Comportamento |
|---|---|---|
| **Testar webhook** (`outline sm`, ícone `PlugZap`) | Tem escrita, **está configurado** e nada pendente | Dispara `dispatch-a2a-open-protocols` em `mode: "test"` — POST do servidor, com payload **sintético**, sem tocar em protocolo real |
| **Salvar** (`sm`) | Tem escrita, **dirty**, sem `limitError`, sem requisição em voo | Chama `update_a2a_closure_settings` |

**Definição de "dirty":** URL digitada (ou sugerida) **ou** mudança tocada em switch/horas/varredura/envios. Uma URL preenchida já basta para habilitar o Salvar.

**Após salvar com sucesso:** URL some do estado, `touched` volta a `false`, a confirmação **"Configuração salva. A URL não é exibida novamente."** aparece.

#### Bloco de observabilidade (`<dl>` de 2 colunas)

> Comentário do código: *"os valores acima são a intenção; estes são os fatos."*

| Rótulo | Valor | Fallback |
|---|---|---|
| **Última varredura** | `last_scan_at` em `pt-BR` (data curta + hora curta) | `—` |
| **Próxima verificação (estimada)** | `next_scan_at` | **"na próxima batida"** |
| **Último envio** | `last_dispatch_at` | `—` |
| **Resultado do último envio** | ver tabela abaixo | `—` |

**Rótulos de `last_dispatch_status` (`describeDispatchStatus`):**

| Valor | Rótulo |
|---|---|
| `accepted` | **"Aceito pelo webhook"** |
| `failed` | **"Falhou"** |
| `pending` | **"Aguardando nova tentativa"** |
| *(outro)* | exibido **cru** |
| ausente | `—` |

> Regra: só existe valor aqui quando houve **tentativa real de POST**. Descarte antes do envio (protocolo deixou de ser elegível, URL removida) **não escreve nada**, para que "Último envio" continue significando envio.

#### Resultado do teste

| Estado | Render |
|---|---|
| Em andamento | **"Enviando requisição de teste…"** (`text-muted-foreground`) |
| Sucesso | `CheckCircle2` em `text-primary` + mensagem + ` · HTTP {status}` + ` · {n} ms` (quando presentes) |
| Falha | `role="alert"`, `AlertTriangle`, mensagem em `text-destructive` + ` · HTTP {status}` |

**Regra:** uma requisição que "saiu" **não** é sucesso — só HTTP 2xx é, e quem decide é o backend. O resultado é sanitizado: **nunca contém URL, token ou stack**.

#### Remoção da URL — confirmação em duas etapas inline

Não é um modal: a confirmação acontece **no próprio card**, numa faixa separada por borda.

| Etapa | Render |
|---|---|
| 1 | Botão `outline sm` em `text-destructive` com `Trash2` — **"Remover URL"** |
| 2 | Texto **"Remover a URL desliga o fechamento automático deste agente. Confirmar?"** + botão `destructive` **"Confirmar remoção"** + botão `ghost` **"Cancelar"** |

Confirmar envia `webhookUrl: ""` **e** `enabled: false` na mesma chamada. Visível apenas quando **configurado e com permissão de escrita**.

#### Mensagens de erro de salvamento (`describeA2AClosureError`)

A RPC devolve `22023` com o motivo em texto e `42501` para permissão. A UI traduz:

| Padrão no erro cru | Mensagem exibida |
|---|---|
| `requires owner or admin` / `access denied` | "Apenas owner ou admin da organização podem alterar esta configuração." |
| `exclusivo de agente interno` | "O fechamento automático A2A é exclusivo de agentes internos." |
| `agente excluido` / `agente excluído` | "Este agente foi excluído e não pode ser configurado." |
| `agente inexistente` | "Agente não encontrado nesta organização." |
| `deve ser https` | "A URL do webhook precisa começar com https://." |
| `habilitar sem webhook_url` | "Informe a URL do webhook antes de habilitar o fechamento automático." |
| `inactivity_hours` | "As horas de inatividade precisam estar entre 1 e 168." |
| `scan_interval_minutes` | "A verificação de protocolos precisa estar entre 1 e 10080 minutos." |
| `dispatch_interval_minutes` | "O intervalo mínimo entre envios precisa estar entre 1 e 1440 minutos." |
| `muito longa` | "A URL do webhook é longa demais (máximo de 2000 caracteres)." |
| *(nenhum)* | o erro cru, ou "Não foi possível salvar a configuração." |

O erro aparece em `role="alert"` `text-xs text-destructive` no rodapé do card.

#### `data-testid` do card (contrato de teste a preservar)

`a2a-closure-card` · `a2a-closure-error` · `a2a-closure-status` · `a2a-closure-url` · `a2a-closure-host` · `a2a-closure-default-hint` · `a2a-closure-hours` · `a2a-closure-scan` · `a2a-closure-dispatch` · `a2a-closure-enabled` · `a2a-closure-test` · `a2a-closure-save` · `a2a-closure-limit-error` · `a2a-closure-observability` · `a2a-closure-last-scan` · `a2a-closure-next-scan` · `a2a-closure-last-dispatch` · `a2a-closure-last-dispatch-status` · `a2a-closure-test-loading` · `a2a-closure-test-success` · `a2a-closure-test-error` · `a2a-closure-remove` · `a2a-closure-remove-warning` · `a2a-closure-remove-confirm` · `a2a-closure-remove-cancel` · `a2a-closure-readonly` · `a2a-closure-save-error` · `a2a-closure-saved`

---

## 18. Versionamento do agente (`VersionManager`)

Arquivo: `src/components/ia/VersionManager.tsx`. É a aba **Versões** do workspace (`?tab=versions`).

### 18.1 Conceito

Uma **versão** (`ai_versions`) é o snapshot da configuração do agente: personalidade (`agent_name`, `agent_tone`, `agent_avatar_url`), diretrizes, regras de negócio, prompts e `playground_config`. O agente tem, no máximo, **um rascunho e um publicado** vivos ao mesmo tempo; publicar um rascunho **arquiva automaticamente** o publicado anterior.

Isso é o que sustenta o **copy-on-write** do workspace (`AutoDraftWrapper`, §… do documento): o usuário *visualiza* a versão publicada e, para editar, cria um rascunho.

### 18.2 Props e contrato

| Prop | Papel |
|---|---|
| `versions` / `isLoading` | Lista e estado de carga, fornecidos pelo workspace |
| `selectedVersionId` | Versão atualmente aberta (linha destacada com `bg-muted`) |
| `onSelectVersion(version)` | Seleciona a versão — chamado **no clique da linha inteira** e no item "Editar" |
| `search` / `onSearchChange` | Busca **controlada pelo pai** (o componente não filtra nada por conta própria) |
| `canWrite` | Default `true`; quando `false`, some **Nova Versão** e todos os itens de escrita do menu |

### 18.3 Anatomia

```
[🔍 Input "Buscar versões..."  (pl-9, flex-1)]      [+ Nova Versão]

┌ rounded-md border ─────────────────────────────────────────────────────┐
│ Versão(80) │ Status(120) │ Nome / Descrição │ Criado em(130) │         │
│                                             │ Última Edição(130) │ ⋯(60)│
├────────────────────────────────────────────────────────────────────────┤
│ v3         │ [Rascunho]  │ Esperanza        │ 12/05/2026 │ 14/05/2026 │⋯│
│ v2         │ [Publicado] │ Esperanza        │ …                        │ │
│ v1         │ [Arquivado] │ …                                           │ │
└────────────────────────────────────────────────────────────────────────┘
```

### 18.4 Ordenação (regra de produto)

A ordenação **não é cronológica**: é por **relevância operacional**.

```
statusOrder = { draft: 0, published: 1, archived: 2 }
desempate → número da versão DESC
```

Ou seja: o **rascunho** (o que está sendo trabalhado) fica sempre no topo, o **publicado** (o que está no ar) logo abaixo, e o histórico arquivado por último.

### 18.5 Badges de status (`VERSION_STATUS_CONFIG`)

| `status` | Rótulo | Variante | Ícone | Cor do ícone |
|---|---|---|---|---|
| `draft` | **Rascunho** | `secondary` | `Circle` | `text-yellow-500` |
| `published` | **Publicado** | `default` | `CheckCircle` | `text-primary` |
| `archived` | **Arquivado** | `outline` | `Archive` | `text-muted-foreground` |

O badge usa **ícone + texto** — a cor nunca é o único sinal.

### 18.6 Colunas

| Coluna | Largura | Conteúdo |
|---|---|---|
| **Versão** | 80px | `v{version}` em `font-mono font-semibold` |
| **Status** | 120px | Badge acima |
| **Nome / Descrição** | flex | `agent_name` (fallback `name`) em `font-medium`; abaixo, `description` em `text-xs` com `line-clamp-1` |
| **Criado em** | 130px | `dd/mm/aaaa` (`pt-BR`) |
| **Última Edição** | 130px | `dd/mm/aaaa` |
| **Ações** | 60px | `DropdownMenu` com gatilho `MoreHorizontal` (`ghost`, 32×32) |

A linha inteira é clicável (`cursor-pointer hover:bg-muted/50`); o gatilho do menu faz `stopPropagation` para não selecionar a versão ao abrir o menu.

> ⚠️ O gatilho `MoreHorizontal` desta tabela **não tem `aria-label`** — diferente do `AgentActionsMenu`, que usa `aria-label="Ações do agente {nome}"`. É um achado de acessibilidade a corrigir no redesenho (regra `button-name`).

### 18.7 Menu de ações da versão

| Item | Ícone | Aparece quando | Efeito |
|---|---|---|---|
| **Editar** | `Edit` | sempre | `onSelectVersion(version)` — abre a versão nas demais abas |
| **Duplicar** | `Copy` | `canWrite` | Abre o diálogo em modo `new` com **esta** versão como origem |
| **Publicar** | `Rocket` | `canWrite` **e** `status === "draft"` | `window.confirm` + `publishVersion` |
| **Restaurar como Rascunho** | `RotateCcw` | `canWrite` **e** `status === "archived"` | Abre o diálogo em modo `restore` |
| *(separador)* | — | sempre | — |
| **Excluir** | `Trash2` (`text-destructive`) | `canWrite` **e** `status !== "published"` | `window.confirm` + `deleteVersion` |

**Regras estruturais:**
- **A versão publicada não pode ser excluída** — o item simplesmente não aparece.
- **Restaurar não sobrescreve nada**: cria um **novo rascunho** a partir do arquivado.

### 18.8 Modal — Nova Versão / Restaurar Versão

O **mesmo** `Dialog` serve aos dois modos (`dialogMode`: `"new"` | `"restore"`).

| Campo | Modo `new` | Modo `restore` |
|---|---|---|
| **Título** | "Nova Versão do Agente" | "Restaurar Versão" |
| **Descrição** | "Crie uma nova versão duplicando uma existente. Todas as configurações, diretrizes, regras e prompts serão copiados." | "Crie um novo rascunho baseado nesta versão arquivada. Você poderá revisar antes de publicar." |
| **Origem pré-selecionada** | `defaultSourceVersion` (publicada → rascunho → primeira da lista) ou a versão do menu | a versão arquivada clicada |
| **Descrição pré-preenchida** | vazia | **"Restauração de versão anterior"** |
| **Botão de ação** | `Copy` + **"Criar v{n}"** | `RotateCcw` + **"Restaurar como v{n}"** |

Corpo do diálogo:

| Bloco | Conteúdo |
|---|---|
| **Baseado em** | `Select` com **todas** as versões: `v{n}` em `font-mono` · `-` · nome do agente · badge do status |
| **Bloco de preview** (`bg-muted/50 rounded-lg p-3`) | "**Nova versão:** `v{próximo}`{ (baseada em v{origem})}" e, abaixo, "Será criada como [badge `secondary` **Rascunho**]" |
| **Descrição das Mudanças** | `Textarea` 3 linhas, `id="description"`, placeholder "Descreva o que será ajustado nesta nova versão...". Hint: "Opcional. Ajuda a documentar as mudanças entre versões." |

**Cálculo do próximo número (`nextVersionNumber`):** `max(versões numéricas) + 1`; lista vazia → **"2"**. Valor não numérico conta como `0`.

**Botões:** **Cancelar** (`outline`) · botão de ação (desabilitado sem origem ou durante o envio; mostra `Loader2`).

**Após criar:** o diálogo fecha, os campos são limpos e a **nova versão é selecionada automaticamente** (`onSelectVersion(newVersion)`).

**Erro:** apenas `logError` — ⚠️ **não há toast nem mensagem na tela** quando a duplicação falha. O diálogo permanece aberto, mas sem explicação. É um buraco de feedback a resolver no redesenho.

### 18.9 Estados da tabela

| Estado | Render |
|---|---|
| Carregando | `Loader2` 32px centralizado (`py-12`) |
| Vazio **com busca** | `Card` com `Layers` 48px, **"Nenhuma versão encontrada"**, "Tente ajustar os filtros de busca" |
| Vazio **sem busca** | `Card` com `Layers` 48px, **"Nenhuma versão encontrada"**, "Crie seu primeiro agente para começar" |
| Com dados | Tabela |

### 18.10 Confirmações nativas — dívida do módulo

Duas ações destrutivas usam **`window.confirm`**, não o design system:

| Ação | Texto do `confirm` |
|---|---|
| **Publicar** | "Publicar este rascunho? A versão atual publicada será arquivada automaticamente." |
| **Excluir versão** | "Tem certeza que deseja excluir esta versão? Esta ação não pode ser desfeita." |

Isso contraria o princípio *"nada destrutivo em um clique"* só pela metade: há confirmação, mas ela é **nativa do navegador**, não estilizável, não acessível pelo padrão do resto do módulo e **não declara impacto** (quantas conversas usaram aquela versão, o que a publicação muda na operação).

> **Recomendação para o redesenho:** migrar os dois para `AlertDialog` no padrão do `AgentStatusConfirmDialog` — com título, impacto explícito, estado `pending` e botão destrutivo. É a mesma dívida do **Excluir etapa** (§16.7).

---

## 19. Exclusão de agente (`AgentDeleteDialog`)

Arquivos: `src/components/ia/AgentDeleteDialog.tsx`, `src/components/ia/agent-deletion-blockers.ts`, `src/hooks/useAIAgents.ts`, `src/types/ai.ts`.

### 19.1 Princípio: agente não se apaga fisicamente

> Comentário do código: *"A exclusão é LÓGICA: o agente sai da operação e da galeria, o histórico (métricas, conversas, chamadas A2A, versões, RAG, auditoria) permanece íntegro e o slug continua reservado."*

E em `useAIAgents.ts`: o `crud.useDelete` genérico (DELETE físico em `ai_agents`) **não é exportado de propósito** — um DELETE físico dispararia os `ON DELETE CASCADE` das tabelas filhas (versões, RAG, funil, whitelist de tags, logs A2A) e destruiria o histórico.

| Efeito real da "exclusão" | Detalhe |
|---|---|
| `deleted_at` / `deleted_by` | Gravados pela RPC `delete_ai_agent_v1` — **nunca** por update direto |
| Status | O agente é **arquivado** |
| Fechamento A2A | **Desabilitado** e a URL do webhook é **apagada** |
| Linhas filhas | **Nenhuma** é apagada |
| Slug | **Continua reservado** — não pode ser reutilizado por outro agente |
| Listagens | `useAIAgents` filtra `deleted_at IS NULL` |

### 19.2 Fluxo completo

```
abre o diálogo
   └─ preflight (delete_ai_agent_v1 com p_execute = false, dry-run)
      ├─ agente não encontrado        → alerta destrutivo, sem formulário
      ├─ já excluído                  → alerta informativo, sem formulário
      ├─ bloqueadores                 → alerta destrutivo com a lista, sem formulário
      └─ elegível
         ├─ bloco "O que será preservado" (contagens)
         └─ campo de confirmação: digitar o SLUG EXATO
            └─ "Remover da operação"  → RPC com p_execute = true
```

**Sem cache entre aberturas** (`staleTime: 0`) — os bloqueadores mudam com a operação, então cada abertura consulta de novo.

**Sem janela TOCTOU:** a RPC **revalida todos os bloqueadores dentro da transação**. O preflight é só informativo.

**Idempotente:** sucesso é `deleted: true` **ou** `already_deleted: true`.

### 19.3 Modal — anatomia

| Campo | Conteúdo |
|---|---|
| **Objetivo** | Tirar o agente da operação preservando todo o histórico |
| **Gatilho** | Item **"Excluir agente"** (`Trash2`, `text-destructive`) no `AgentActionsMenu` — visível só para `owner`/`admin` |
| **Tipo** | `Dialog` `sm:max-w-lg` — **destrutivo** |
| **Título** | `Trash2` em `text-destructive` + **"Excluir agente"** |
| **Descrição** | "O agente **{nome}** será removido da operação e da galeria. Todo o histórico (métricas, conversas, chamadas A2A, versões e auditoria) será preservado, e o slug `{slug}` continuará reservado — não poderá ser reutilizado por outro agente." |

### 19.4 Estados do preflight

| Estado | Render |
|---|---|
| **Carregando** | `aria-busy="true"` + `sr-only role="status"` **"Verificando impacto da exclusão…"** + 3 `Skeleton` (larguras `full`, `2/3`, `1/2`) |
| **Erro no preflight** | `Alert variant="destructive"` com `AlertTriangle`: **"Não foi possível verificar a exclusão"** / "Erro ao consultar o impacto da exclusão. Feche e tente novamente." |
| **Agente não encontrado** (`found === false`) | `Alert variant="destructive"`: **"Agente não encontrado"** / "O agente não existe mais nesta organização." |
| **Já excluído** (`already_deleted`) | `Alert` neutro com `ShieldCheck`: **"Agente já excluído"** / "Este agente já foi excluído anteriormente. Nenhuma ação é necessária." |
| **Bloqueado** (`blockers.length > 0`) | `Alert variant="destructive"`: **"A exclusão está bloqueada"** + `<ul>` com uma mensagem por bloqueador |
| **Elegível** | Bloco de impacto + campo de confirmação |

### 19.5 Catálogo de bloqueadores (`DELETION_BLOCKER_MESSAGES`)

Códigos **estáveis** devolvidos pela RPC (`AIAgentDeletionBlocker`):

| Código | Mensagem exibida | Como o usuário resolve |
|---|---|---|
| `agent_is_default` | "Este é o agente padrão da organização. Defina outro agente como padrão antes de excluir." | Menu de ações de outro agente → **Definir como padrão** |
| `agent_not_archived` | "O agente precisa estar arquivado antes da exclusão. Arquive-o pelo menu de ações e tente novamente." | Menu de ações → **Arquivar** |
| `open_protocols` | "Existem protocolos em andamento deste agente. Aguarde a finalização (ou finalize-os) antes de excluir." | Aguardar ou finalizar na aba Conversas |
| `pending_a2a_dispatches` | "Existem dispatches A2A pendentes deste agente. Aguarde o processamento da fila antes de excluir." | Aguardar a fila |
| `confirmation_mismatch` | "A confirmação não confere com o slug do agente. Digite o slug exato." | Digitar o slug correto |

**Detalhe de UI importante:** `confirmation_mismatch` é **filtrado fora** da lista exibida no bloco de bloqueadores — ele é uma condição do formulário, não um impedimento operacional. O preflight roda **sem** slug, então ele sempre apareceria ali. Ele só aparece como mensagem via **toast**, quando a execução falha.

> Consequência de sequência que o redesenho precisa comunicar: **exclusão exige arquivamento antes**, e **arquivar exige não ser o padrão** (o item "Arquivar" do menu fica desabilitado quando `agent.is_default`). O caminho completo para excluir o agente padrão é: promover outro a padrão → arquivar → excluir. Hoje esse encadeamento só é descoberto **um erro por vez**.

### 19.6 Bloco "O que será preservado"

`rounded-md border bg-muted/30 p-3`, com título **"O que será preservado:"** e uma lista de 5 linhas (rótulo à esquerda, número em `font-mono` à direita):

| Linha | Campo do `impact` |
|---|---|
| **Versões** | `impact.versions` |
| **Documentos de conhecimento (RAG)** | `impact.rag_documents` |
| **Protocolos** | `impact.protocols` |
| **Mensagens** | `impact.messages` |
| **Chamadas A2A registradas** | `impact.agent_call_logs` |

> O `AIAgentDeletionImpact` também carrega `open_protocols` e `pending_a2a_dispatches`, que **não** são exibidos como linhas — eles viram **bloqueadores**. ⚠️ Oportunidade de redesenho: mostrar a contagem junto do bloqueador (*"3 protocolos em andamento"*) em vez de só a frase genérica.

### 19.7 Confirmação por slug

| Elemento | Detalhe |
|---|---|
| Rótulo | "Para confirmar, digite o slug **`{slug}`**" (o slug em `font-mono font-semibold`) |
| Campo | `Input` `id="agent-delete-confirmation"`, `placeholder = slug`, `autoComplete="off"`, `spellCheck={false}` |
| Validação | Igualdade **exata** (`confirmation === agent.slug`) — case-sensitive, sem trim |
| Desabilitado | Enquanto a exclusão está pendente |

**Habilitação do botão:** `eligible && confirmationMatches && !isPending`.

### 19.8 Botões e travas

| Botão | Detalhe |
|---|---|
| **Cancelar** | `outline`; desabilitado durante a exclusão |
| **Remover da operação** | `destructive`; mostra `Loader2`; só habilita com as três condições acima |

**Travas:**
- O diálogo **não fecha** por ESC ou clique no overlay enquanto a mutation está pendente.
- **Erro preserva o formulário** — o texto digitado permanece intacto; só a causa é exibida.
- **Reabrir recomeça do zero** — `setConfirmation("")` + `deletion.reset()` acontecem no ciclo *fechar/abrir*, nunca por causa de um erro.

### 19.9 Toasts

| Resultado | Toast |
|---|---|
| Excluído | **"Agente excluído"** / ""{nome}" saiu da operação. O histórico foi preservado." |
| Já estava excluído | **"Agente já estava excluído"** / mesma descrição |
| Bloqueado na execução | **"Erro ao excluir agente"** (destrutivo) / as mensagens dos bloqueadores **concatenadas por espaço** |
| Erro genérico | **"Erro ao excluir agente"** / "Não foi possível excluir o agente. Tente novamente." |

Após sucesso, o diálogo fecha e `onDeleted?.()` é chamado — no workspace, isso navega de volta para `/agent-ia`.

---

## 20. Catálogo completo de métricas de IA

Arquivo: `src/lib/ai-metrics/metric-catalog.ts`.

> **Este é o documento mais importante para o redesenho.** Ele é o **contrato semântico** de cada número que aparece na tela. O arquivo **não calcula nada** — declara o que cada série significa. Qualquer rótulo, eixo, legenda ou tooltip que o redesenho escrever tem de sair daqui.

### 20.1 A regra central

> "A mesma pergunta de negócio usa a mesma `metricKey` e, portanto, o **MESMO valor** em card, gráfico, tabela, drilldown e relatório. Dois números diferentes só podem coexistir quando **unidade, universo, data de referência ou escopo** forem realmente diferentes — e nesse caso a diferença **PRECISA estar explícita no rótulo**. Nunca exibir dois valores genericamente chamados 'Transferências'."

Para que serve o contrato:
1. A UI carrega a `metricKey` **junto** do valor (rótulo, unidade, janela).
2. Os testes validam aditividade sem repetir a regra em prosa.
3. Uma dimensão **multivalor** nunca é comparada ao total de protocolos.

**Fuso de todas as métricas:** `METRIC_TIMEZONE = "America/Sao_Paulo"`.

**Fonte dos valores:** sempre o snapshot (`get_ai_performance_snapshot_v1`). **Nenhum componente recalcula fórmula localmente.**

### 20.2 Vocabulário do catálogo

**Unidades (`MetricUnit`)** — aparecem no rótulo; `protocolos` ≠ `eventos`:

| Valor | `unitLabel` típico | Significado |
|---|---|---|
| `protocol` | protocolos | Um atendimento |
| `event` | eventos | Uma ocorrência bruta (tentativa, reclassificação) |
| `message` | mensagens / registros | Uma mensagem trocada ou um registro de interação |
| `tag_application` | aplicações de tag | Uma aplicação de tag (um protocolo pode gerar várias) |
| `call` | chamadas | Uma chamada A2A registrada |

**Tipos de dimensão (`MetricDimensionKind`)** — definem o que a soma dos baldes significa:

| Valor | Contrato de soma | Visualização permitida |
|---|---|---|
| `exclusive_partition` | A soma dos baldes **DEVE** ser igual ao total (invariante testada) | Barra 100% (`MetricCompositionBar`), ranking, série |
| `multivalue` | Um item pode cair em vários baldes; somar **NÃO** dá o total | **Somente ranking**, com o aviso de multivalor e **sem percentual** |
| `informational` | Recorte auxiliar, sem contrato de soma | Funil / série |

**Campos de uma `MetricDefinition`:**

| Campo | Papel na tela |
|---|---|
| `metricKey` | Identidade única; viaja junto do valor |
| `label` | Rótulo de negócio **completo** — nunca ambíguo |
| `description` | Frase curta para tooltip/subtítulo |
| `unit` / `unitLabel` | Grão contado; `unitLabel` vai em eixos e legendas |
| `population` | O universo considerado (o "quem entra na conta") |
| `referenceDate` | A coluna/data usada para recortar o período |
| `periodFiltered` | `true` = respeita `[from, toExclusive)`; `false` = fotografia sem período |
| `dimensions[]` | Dimensões publicadas e seu contrato de soma |
| `formula` | `formulaId` + numerador + denominador (só em métricas derivadas) |
| `inclusions[]` / `exclusions[]` | O que entra e o que sai — auditável |
| `doNotCompareWith[]` | Métricas com as quais **não** se compara sem qualificador |

### 20.3 Tabela-mestra das 15 métricas

| `metricKey` | Rótulo exibido | O que conta (definição) | Como é calculada | Formato | Nota / ressalva |
|---|---|---|---|---|---|
| `transfers.protocols.total` | **Protocolos transferidos no período** | Protocolos distintos com ao menos um evento válido de transferência no período | Um protocolo = um evento representante: o de **transbordo**, se houver; senão o **primeiro** da janela (desempate por `id`) | Contagem inteira, unidade **protocolos** | Não exige histórico de movimentação de status — por isso difere dos baldes de transferência de "Desfechos por protocolo". **Não comparar** com `transfers.events.total` nem `accuracy.buckets` |
| `transfers.events.total` | **Eventos de transferência no período** | **Todos** os eventos/tentativas de transferência do período, incluindo repetições e reclassificações | Contagem bruta por `received_at` do próprio evento | Contagem inteira, unidade **eventos** | Eventos sem protocolo entram em bucket explícito **"Sem protocolo"**. **Não comparar** com `transfers.protocols.total` |
| `accuracy.rate` | **Acurácia do atendimento** | Percentual de protocolos que **não** transbordaram nem foram transferidos para humano | `non_human_transfer_rate_v2`: (Total − transbordos − transferidos) ÷ Σ buckets | **Percentual** | População = protocolos **com ao menos uma mensagem** no período. Transferidos inclui `transferido_transfer` **e** `transferido_null`. **Não comparar** com `transfers.protocols.total` |
| `lifecycle.current.distinctProtocols` | **Ciclo de vida no momento** | Último estado de cada protocolo **na fotografia atual** | Estado vigente no instante do snapshot (`asOf`) | Contagem inteira, unidade **protocolos** | **NÃO respeita o filtro de período.** **Não comparar** com `lifecycle.period.passages` nem `transfers.protocols.total` |
| `lifecycle.period.passages` | **Passagens de estado no período** | Protocolos que **tocaram** cada estado no período | Contagem de protocolos distintos por estado tocado, por `changed_at` da transição | Contagem inteira, unidade **protocolos** | Estados **não** são exclusivos: a soma **pode superar** o total. **Nunca representar como distribuição de 100%** |
| `messages.total` | **Mensagens no período** | Mensagens trocadas no período, por papel | Contagem por `occurred_at` da mensagem | Contagem inteira, unidade **mensagens** | Papel desconhecido recebe bucket explícito — **nunca some da soma** |
| `messages.protocolsWithMessages` | **Protocolos com mensagens** | Protocolos com ao menos uma mensagem no período | Contagem distinta de protocolos por `occurred_at` | Contagem inteira, unidade **protocolos com ao menos uma mensagem** | **Não comparar** com `messages.total` (unidades diferentes) |
| `messages.perProtocol` | **Média de mensagens por protocolo** | Mensagens no período ÷ protocolos com mensagens no período | `messages.perProtocol.v1`: `messages.total` ÷ `messages.protocolsWithMessages` | **Média**, unidade **mensagens por protocolo** | Métrica derivada — os dois operandos precisam vir do mesmo recorte |
| `tags.applications` | **Aplicações de tag no período** | Quantidade de **aplicações** de tag | Contagem por `created_at` da aplicação | Contagem inteira, unidade **aplicações de tag** | Um protocolo pode receber várias tags. **Nunca rotular como quantidade de protocolos**; **não exigir** que a soma feche com o total de atendimentos. **Não comparar** com `transfers.protocols.total` nem `lifecycle.current.distinctProtocols` |
| `sentiment.coverage` | **Cobertura de análise de sentimento** | Registros analisados sobre registros elegíveis | `sentiment.coverage.v1`: `analyzedMessages` ÷ `eligibleMessages` | **Percentual**, unidade **registros** | Base própria (log de interações). **Não comparar** com `sentiment.distribution` |
| `sentiment.distribution` | **Distribuição de sentimento** | Positivo / neutro / negativo **apenas** sobre registros analisados | Partição exclusiva dos registros analisados | Percentual sobre analisados, unidade **registros analisados** | **"Sem análise" não é sentimento neutro**: `unknown` significa NÃO ANALISADA e **não recebe percentual**. **Não comparar** com `sentiment.coverage` |
| `funnel.cohort.reached` | **Conversão da corte** | Protocolos que entraram na etapa inicial dentro da janela e alcançaram as seguintes **em ordem** | `funnel.cohort.v1`: protocolos que alcançaram a etapa ÷ corte inicial | Contagem + **percentual** por etapa | Série **não crescente** — conversão e abandono são válidos **aqui e só aqui**. **Não comparar** com `funnel.passages.touched` |
| `funnel.passages.touched` | **Passagens no período** | Protocolos distintos que **tocaram** cada etapa no período | Contagem distinta por etapa tocada | Contagem inteira, unidade **protocolos** | **Pode CRESCER entre etapas — não é conversão.** Não derivar drop-off por diferença entre totais marginais; não aplicar teste de monotonicidade. **Não comparar** com `funnel.cohort.reached` |
| `funnel.current.stage` | **Estado atual no funil — sem filtro de período** | Última etapa de cada protocolo na fotografia atual | Etapa vigente no instante do snapshot (`asOf`) | Contagem inteira, unidade **protocolos** | **Não respeita o período.** Bucket nulo explícito: **"Sem etapa"**. **Não comparar** com as duas outras leituras de funil |
| `agentCalls.total` | **Chamadas entre agentes** | Chamadas A2A segmentadas por solicitante e solicitado | Contagem por `created_at` da chamada | Contagem inteira, unidade **chamadas** | Unidade é **chamada**, nunca protocolo — N chamadas ≠ N conversas |

### 20.4 Detalhe por métrica

Abaixo, o registro completo de cada entrada do catálogo. **Os textos são literais do código.**

#### `transfers.protocols.total`

| Campo | Valor |
|---|---|
| **Rótulo** | Protocolos transferidos no período |
| **Descrição** | "Protocolos distintos com ao menos um evento válido de transferência no período, representados pelo evento de TRANSBORDO, se houver; senão pelo primeiro da janela." |
| **Unidade** | `protocol` — "protocolos" |
| **População** | "Protocolos com ao menos um evento de transferência válido dentro da janela. NÃO exige histórico de movimentação de status — por isso o total difere dos baldes de transferência de 'Desfechos por protocolo', que partem do status log." |
| **Data de referência** | "`received_at` do evento canônico do protocolo na janela — o de transbordo, se houver; senão o primeiro (desempate por `id`)." |
| **Respeita o período?** | Sim |
| **Dimensões** | `byDay` (Por período, exclusiva) · `byType` (Por tipo, exclusiva, nulo = **"Tipo não classificado"**) · `byTag` (Por tag, exclusiva, nulo = **"Sem tag"**) · `byAgent` (Por agente, exclusiva, nulo = **"Sem agente"**) |
| **Inclusões** | "Dia, tipo e tag derivam do MESMO evento canônico (o de transbordo, se houver; senão o primeiro da janela)." |
| **Exclusões** | "Eventos sem protocolo (reportados apenas em qualidade)." · "Eventos cujo protocolo é um marcador de 'sem protocolo' (undefined, null, nan, vazio) — contados só na visão Eventos e em qualidade, nunca como um protocolo." · "Reclassificações e tentativas posteriores (só na visão Eventos)." |
| **Não comparar com** | `transfers.events.total`, `accuracy.buckets` |

#### `transfers.events.total`

| Campo | Valor |
|---|---|
| **Rótulo** | Eventos de transferência no período |
| **Descrição** | "Todos os eventos/tentativas de transferência ocorridos no período, incluindo repetições e reclassificações." |
| **Unidade** | `event` — "eventos" |
| **População** | "Todos os eventos de transferência na janela." |
| **Data de referência** | "`received_at` do próprio evento." |
| **Respeita o período?** | Sim |
| **Dimensões** | `byDay` · `byType` (nulo = "Tipo não classificado") · `byTag` (nulo = "Sem tag") · `byAgent` (nulo = "Sem agente") — **todas exclusivas** |
| **Inclusões** | "Eventos sem protocolo entram em bucket explícito 'Sem protocolo'." |
| **Não comparar com** | `transfers.protocols.total` |

> **Par crítico do domínio.** Protocolos e eventos são **duas métricas diferentes** e nunca podem aparecer ambas rotuladas como "Transferências". É por isso que o `TransferTrendPanel` exige `metricKey` **obrigatória** e que a `TransfersSection` mostra **os dois totais sempre visíveis**, cada um com o rótulo canônico completo.

#### `accuracy.rate`

| Campo | Valor |
|---|---|
| **Rótulo** | Acurácia do atendimento |
| **Descrição** | "Percentual de protocolos que não transbordaram nem foram transferidos para atendimento humano." |
| **Unidade** | `protocol` — "protocolos" |
| **População** | "Protocolos com ao menos uma mensagem no período." |
| **Data de referência** | "`occurred_at` da mensagem." |
| **Respeita o período?** | Sim |
| **Dimensões** | `buckets` (Desfecho, **exclusiva**, nulo = **"Em andamento"**) |
| **Fórmula** | `non_human_transfer_rate_v2` — numerador: "Total de protocolos − transbordos − transferidos (assistidos ou não classificados)" ÷ denominador: "Σ buckets (todos os desfechos classificados)" |
| **Inclusões** | "Cada protocolo entra em um único bucket da classificação canônica." · "Transferidos inclui os buckets `transferido_transfer` e `transferido_null`." |
| **Não comparar com** | `transfers.protocols.total` |

> **Transbordo sai do numerador sozinho.** É essa propriedade que mantém a acurácia honesta num apagão de ingestão: um protocolo que transbordou nunca é contado como acerto.

#### `lifecycle.current.distinctProtocols`

| Campo | Valor |
|---|---|
| **Rótulo** | Ciclo de vida no momento |
| **Descrição** | "Último estado de cada protocolo na fotografia atual. NÃO respeita o filtro de período." |
| **Unidade** | `protocol` — "protocolos" |
| **População** | "Todos os protocolos da organização/agente, sem recorte temporal." |
| **Data de referência** | "Estado vigente no instante do snapshot (`asOf`)." |
| **Respeita o período?** | **Não** — fotografia |
| **Dimensões** | `states` (Estado atual, **exclusiva**) |
| **Não comparar com** | `lifecycle.period.passages`, `transfers.protocols.total` |

> É a única métrica com **alerta âmbar fixo na tela** avisando que não respeita o período (§10.10).

#### `lifecycle.period.passages`

| Campo | Valor |
|---|---|
| **Rótulo** | Passagens de estado no período |
| **Descrição** | "Protocolos que tocaram cada estado no período. Estados NÃO são exclusivos: a soma pode superar o total de protocolos." |
| **Unidade** | `protocol` — "protocolos" |
| **População** | "Protocolos com ao menos uma transição de status na janela." |
| **Data de referência** | "`changed_at` da transição." |
| **Respeita o período?** | Sim |
| **Dimensões** | `states` (Estado tocado, **multivalor**) |
| **Exclusões** | "Não representar como distribuição de 100%." |
| **Não comparar com** | `lifecycle.current.distinctProtocols` |

> Por ser multivalor, a `MetricCompositionBar` **recusa** esta dimensão por contrato — a seção usa `MetricRankingList` **sem Top N**, e o total exibido é `distinctProtocols`, **não** a soma das linhas.

#### `messages.total`

| Campo | Valor |
|---|---|
| **Rótulo** | Mensagens no período |
| **Descrição** | "Mensagens trocadas no período, por papel." |
| **Unidade** | `message` — "mensagens" |
| **População** | "Mensagens de protocolos do agente/organização na janela." |
| **Data de referência** | "`occurred_at` da mensagem." |
| **Respeita o período?** | Sim |
| **Dimensões** | `byDay` (exclusiva) · `byRole` (Por papel, exclusiva, nulo = **"Papel desconhecido"**) |
| **Inclusões** | "Papel desconhecido recebe bucket explícito — nunca some da soma." |

#### `messages.protocolsWithMessages`

| Campo | Valor |
|---|---|
| **Rótulo** | Protocolos com mensagens |
| **Descrição** | "Protocolos com ao menos uma mensagem no período." |
| **Unidade** | `protocol` — **"protocolos com ao menos uma mensagem"** |
| **População** | "Protocolos do agente/organização com mensagem na janela." |
| **Data de referência** | "`occurred_at` da mensagem." |
| **Respeita o período?** | Sim |
| **Dimensões** | *(nenhuma)* |
| **Não comparar com** | `messages.total` |

> O `unitLabel` é deliberadamente **longo** ("protocolos com ao menos uma mensagem") — é ele que impede a leitura "protocolos do período". O redesenho **não pode encurtá-lo** para caber num card.

#### `messages.perProtocol`

| Campo | Valor |
|---|---|
| **Rótulo** | Média de mensagens por protocolo |
| **Descrição** | "Mensagens no período dividido por protocolos com mensagens no período." |
| **Unidade** | `message` — "mensagens por protocolo" |
| **População** | "Protocolos do agente/organização com mensagem na janela." |
| **Data de referência** | "`occurred_at` da mensagem." |
| **Respeita o período?** | Sim |
| **Dimensões** | *(nenhuma)* |
| **Fórmula** | `messages.perProtocol.v1` — `messages.total` ÷ `messages.protocolsWithMessages` |

#### `tags.applications`

| Campo | Valor |
|---|---|
| **Rótulo** | Aplicações de tag no período |
| **Descrição** | "Quantidade de aplicações de tag. Um protocolo pode receber várias tags." |
| **Unidade** | `tag_application` — "aplicações de tag" |
| **População** | "Aplicações de tag na janela." |
| **Data de referência** | "`created_at` da aplicação da tag." |
| **Respeita o período?** | Sim |
| **Dimensões** | `series` (Por tag ao longo do tempo, **multivalor**) · `ranking` (Ranking do período, **multivalor**) |
| **Exclusões** | "Nunca rotular como quantidade de protocolos." · "Não exigir que a soma seja igual ao total de atendimentos." |
| **Não comparar com** | `transfers.protocols.total`, `lifecycle.current.distinctProtocols` |

#### `sentiment.coverage`

| Campo | Valor |
|---|---|
| **Rótulo** | Cobertura de análise de sentimento |
| **Descrição** | "Registros analisados sobre registros elegíveis." |
| **Unidade** | `message` — "registros" |
| **População** | "Registros de interação elegíveis para análise." |
| **Data de referência** | "`created_at` do registro de interação." |
| **Respeita o período?** | Sim |
| **Dimensões** | `coverage` (Analisadas x não analisadas, **exclusiva**) |
| **Fórmula** | `sentiment.coverage.v1` — `analyzedMessages` ÷ `eligibleMessages` |
| **Não comparar com** | `sentiment.distribution` |

> A base é **própria** (log de interações), com **retenção de 30 dias** — janelas maiores aparecem truncadas. É diferente da base canônica que alimenta `messages.total`; a tela diz isso no rodapé da seção (§10.14).

#### `sentiment.distribution`

| Campo | Valor |
|---|---|
| **Rótulo** | Distribuição de sentimento |
| **Descrição** | "Positivo/neutro/negativo APENAS sobre registros analisados. 'Sem análise' não é sentimento neutro." |
| **Unidade** | `message` — "registros analisados" |
| **População** | "Somente registros efetivamente analisados." |
| **Data de referência** | "`created_at` do registro de interação." |
| **Respeita o período?** | Sim |
| **Dimensões** | `distribution` (Sentimento, **exclusiva**) |
| **Exclusões** | "'unknown' significa NÃO ANALISADA e não recebe percentual sobre `analyzedMessages`." |
| **Não comparar com** | `sentiment.coverage` |

#### `funnel.cohort.reached`

| Campo | Valor |
|---|---|
| **Rótulo** | Conversão da corte |
| **Descrição** | "Protocolos que entraram na etapa inicial dentro da janela e alcançaram as etapas seguintes EM ORDEM." |
| **Unidade** | `protocol` — "protocolos" |
| **População** | "corte que entrou na etapa inicial dentro da janela." |
| **Data de referência** | "Entrada na etapa inicial." |
| **Respeita o período?** | Sim |
| **Dimensões** | `stages` (Etapa, **informacional**) |
| **Fórmula** | `funnel.cohort.v1` — "Protocolos que alcançaram a etapa" ÷ "corte inicial" |
| **Inclusões** | "Série é NÃO CRESCENTE — conversão e abandono são válidos aqui." |
| **Não comparar com** | `funnel.passages.touched` |

> A largura das barras do funil trapezoidal vem do campo `conversionFromInitialPct` **do payload** — **nunca é recalculada no cliente** (§10.13).

#### `funnel.passages.touched`

| Campo | Valor |
|---|---|
| **Rótulo** | Passagens no período |
| **Descrição** | "Protocolos distintos que tocaram cada etapa no período. Pode CRESCER entre etapas — não é conversão." |
| **Unidade** | `protocol` — "protocolos" |
| **População** | "Protocolos que tocaram qualquer etapa na janela." |
| **Data de referência** | "Evento de etapa." |
| **Respeita o período?** | Sim |
| **Dimensões** | `stages` (Etapa, **multivalor**) |
| **Exclusões** | "Não chamar de conversão." · "Não derivar drop-off por diferença entre totais marginais." · "Não aplicar teste de monotonicidade." |
| **Não comparar com** | `funnel.cohort.reached` |

> Consequência de layout: nesta aba as barras são ordenadas **por volume**, porque a sequência não representa avanço, e **não** há desenho de drop-off.

#### `funnel.current.stage`

| Campo | Valor |
|---|---|
| **Rótulo** | Estado atual no funil — sem filtro de período |
| **Descrição** | "Última etapa de cada protocolo na fotografia atual." |
| **Unidade** | `protocol` — "protocolos" |
| **População** | "Todos os protocolos atuais." |
| **Data de referência** | "Etapa vigente no instante do snapshot (`asOf`)." |
| **Respeita o período?** | **Não** |
| **Dimensões** | `stages` (Etapa atual, **exclusiva**, nulo = **"Sem etapa"**) |
| **Não comparar com** | `funnel.cohort.reached`, `funnel.passages.touched` |

#### `agentCalls.total`

| Campo | Valor |
|---|---|
| **Rótulo** | Chamadas entre agentes |
| **Descrição** | "Chamadas A2A segmentadas por solicitante e solicitado." |
| **Unidade** | `call` — "chamadas" |
| **População** | "Chamadas A2A registradas na janela." |
| **Data de referência** | "`created_at` da chamada." |
| **Respeita o período?** | Sim |
| **Dimensões** | `byRequester` (Por solicitante) · `byReceiver` (Por solicitado) · `byDayPair` (Por período e par) — **todas exclusivas** |
| **Inclusões / Exclusões** | *(nenhuma declarada)* |

### 20.5 Mapa das dimensões e seu contrato de soma

| Métrica | Dimensão | Rótulo | Tipo | Bucket nulo |
|---|---|---|---|---|
| `transfers.protocols.total` | `byDay` | Por período | exclusiva | — |
| `transfers.protocols.total` | `byType` | Por tipo | exclusiva | Tipo não classificado |
| `transfers.protocols.total` | `byTag` | Por tag | exclusiva | Sem tag |
| `transfers.protocols.total` | `byAgent` | Por agente | exclusiva | Sem agente |
| `transfers.events.total` | `byDay` | Por período | exclusiva | — |
| `transfers.events.total` | `byType` | Por tipo | exclusiva | Tipo não classificado |
| `transfers.events.total` | `byTag` | Por tag | exclusiva | Sem tag |
| `transfers.events.total` | `byAgent` | Por agente | exclusiva | Sem agente |
| `accuracy.rate` | `buckets` | Desfecho | exclusiva | Em andamento |
| `lifecycle.current.distinctProtocols` | `states` | Estado atual | exclusiva | — |
| `lifecycle.period.passages` | `states` | Estado tocado | **multivalor** | — |
| `messages.total` | `byDay` | Por período | exclusiva | — |
| `messages.total` | `byRole` | Por papel | exclusiva | Papel desconhecido |
| `messages.protocolsWithMessages` | — | — | — | — |
| `messages.perProtocol` | — | — | — | — |
| `tags.applications` | `series` | Por tag ao longo do tempo | **multivalor** | — |
| `tags.applications` | `ranking` | Ranking do período | **multivalor** | — |
| `sentiment.coverage` | `coverage` | Analisadas x não analisadas | exclusiva | — |
| `sentiment.distribution` | `distribution` | Sentimento | exclusiva | — |
| `funnel.cohort.reached` | `stages` | Etapa | informacional | — |
| `funnel.passages.touched` | `stages` | Etapa | **multivalor** | — |
| `funnel.current.stage` | `stages` | Etapa atual | exclusiva | Sem etapa |
| `agentCalls.total` | `byRequester` | Por solicitante | exclusiva | — |
| `agentCalls.total` | `byReceiver` | Por solicitado | exclusiva | — |
| `agentCalls.total` | `byDayPair` | Por período e par | exclusiva | — |

**As quatro dimensões multivalor do sistema** — `lifecycle.period.passages/states`, `tags.applications/series`, `tags.applications/ranking`, `funnel.passages.touched/stages` — são as únicas que **nunca** podem virar barra de composição, pizza ou qualquer visualização que sugira 100%.

### 20.6 Funções derivadas (o que a UI consome do catálogo)

| Função | Comportamento |
|---|---|
| `getMetricDefinition(key)` | Acesso tipado. **Lança** em chave desconhecida (fail-loud) |
| `getExclusiveDimensions(key)` | Só as dimensões cuja soma deve fechar com o total — base dos testes de invariante |
| `isMultivalueDimension(key, dim)` | `true` quando somar os baldes **não** reproduz o total |
| `formatMetricLabel(key)` | **`"{label} ({unitLabel})"`** — garante que nenhum número apareça como "Transferências" sem dizer protocolos vs eventos |

`formatMetricLabel` é o que produz, por exemplo:
- "Protocolos transferidos no período (protocolos)"
- "Eventos de transferência no período (eventos)"
- "Protocolos com mensagens (protocolos com ao menos uma mensagem)"

É esse texto que aparece como **caption** dos KPIs e no cabeçalho de cada gráfico. **Encurtar essa caption quebra o contrato.**

### 20.7 O "?" da tela é derivado do catálogo

Arquivo: `src/lib/ai-metrics/metric-explanation.ts`.

> "Escrever a explicação da tela à mão criaria uma segunda fonte de verdade — e é exatamente assim que o painel passa a dizer uma coisa e o relatório outra. Aqui a tela só **FORMATA** o que o catálogo declara; mudar a regra é mudar o catálogo, e o '?' acompanha sozinho."

`explanationFromCatalog(key)` monta um `KPIExplanation` com **cinco campos**:

| Campo do popover | Como é montado |
|---|---|
| **what** | `description` + `population`, unidas com pontuação garantida |
| **formula** | `"{numerador}\n÷ {denominador}"` — só quando a métrica tem `formula` |
| **excludes** | As `exclusions` unidas |
| **period** | Se `periodFiltered`: *"Respeita o período selecionado, recortado por {referenceDate}. Fuso America/Sao_Paulo."* · Senão: **"Fotografia do estado atual — não muda com o período selecionado."** |
| **note** | As `inclusions` + *"Não compare diretamente com: {lista de metricKeys}"* |

**Regra de honestidade:** chave **fora** do catálogo devolve `undefined` e o chamador **simplesmente não renderiza o ícone "?"**.

> "**Nunca** inventa explicação: métrica sem entrada no catálogo aparece **sem "?"**, que é honesto, em vez de ganhar um texto genérico que ninguém revisou."

**Consequência para o redesenho:** o "?" é um sinal de que **aquele número tem contrato**. Um redesenho que force um ícone de ajuda em todo card produziria explicações inventadas — o padrão atual é intencional.

### 20.8 `InfoTooltip` — o outro "?" do módulo

Arquivo: `src/components/ia/InfoTooltip.tsx`. Diferente do `MetricExplanationPopover` (derivado do catálogo), este é o tooltip **escrito à mão** usado nas seções legadas.

| Modo | Uso | Conteúdo |
|---|---|---|
| **Único** (`text`) | Padrão do app | `Popover` clicável com conteúdo único |
| **Dual** (`business` + `technical`) | Métricas com leitura de negócio e leitura técnica | `Popover` com `ToggleGroup` **Negócio** / **Técnica**; abre em **Negócio** |

| Detalhe | Valor |
|---|---|
| Gatilho | `<button>` com ícone `Info` 14px, `text-muted-foreground` → `text-foreground` no hover |
| Hit area | `p-1 -m-1` amplia para ~24px **sem mudar o layout** |
| Acessibilidade | `aria-label` obrigatório (prop `label`) |
| Popover | `max-w-[300px] p-3 text-xs`, `side` configurável (default `right`), `align="start"` |
| Propagação | **O clique nunca propaga** — o gatilho vive dentro de linhas clicáveis de drill-down |

> É **clicável, não hover**: escolha deliberada para funcionar no mobile e para o texto nunca truncar.

### 20.9 Validação do payload (fail-loud)

Arquivo: `src/lib/ai-metrics/snapshot-validation.ts` — um re-export de `supabase/functions/_shared/ai-report/snapshot-validation.ts`. **Fonte única** compartilhada entre a tela (`useAIPerformanceSnapshot`) e a Edge Function do relatório.

**Princípios declarados:**

| Princípio | Efeito |
|---|---|
| **FAIL-LOUD** | Incompatibilidade → `SnapshotContractError` com a lista de problemas. **Nunca chega silenciosamente na UI** |
| **Não remove chaves desconhecidas** | Campos aditivos novos do SQL precisam **chegar intactos** ao view model — por isso guards manuais, não um schema que faz stripping |
| **Campos aditivos são opcionais** | Ausência é válida (snapshot antigo). O que é rejeitado é o campo **presente com shape errado** — *"existe mas mentiroso" é pior que "não existe"* |
| **Número inválido nunca é aceito** | `NaN`/`Infinity` virariam "—"/0 na tela, e o usuário leria **ausência de dado** onde houve **corrupção de contrato** |
| **Compatibilidade legada é pontual** | Tags com `tagId` vazio são descartadas com o warning auditável `INVALID_EMPTY_TAG_ID_DROPPED`; os demais erros continuam fail-loud |

**Status válidos de seção (`VALID_STATUSES`):** `success` · `empty` · `error` · `unavailable` · `not_applicable` · `partial`.

- `not_applicable` = *"não pode haver dado"* (agente interno) — **distinto** de `empty`, que diz *"não houve no período"*.
- `partial` = números válidos que cobrem apenas o **subconjunto externo** do recorte "Todos".

**Seções opcionais (`OPTIONAL_SNAPSHOT_SECTIONS`):** `interactionBreakdown`. Ausência vira `unavailable` no view model — exigi-la derrubaria o relatório inteiro por uma seção que nem existia.

**Tipos de evento de transferência aceitos:** `overflow` · `transfer` · `unclassified`.

**Derivação de inconsistência — fonte única `quality.invariants`:**

| Função | Regra |
|---|---|
| `getFailedInvariants(snapshot)` | Invariantes com `status === "fail"` |
| `isSectionInconsistent(snapshot, section)` | A seção tem invariante quebrada → **não publica números**, mostra "Dados inconsistentes" **apenas nela** |
| `hasInvariantCoverage(snapshot)` | O snapshot **publica** invariantes? |
| `hasFailedInvariants(snapshot)` | Alguma falhou? |

> **Ausência de invariantes = "não verificado", NUNCA "aprovado".** `isSectionInconsistent` devolve `false` (não bloqueia) e `hasInvariantCoverage` permite a UI dizer que a checagem **não rodou** — é de onde sai a frase "Esta fotografia NÃO publica invariantes: as métricas não foram verificadas — o que não é o mesmo que aprovadas" (§10.16).
>
> O status técnico da seção (`success|empty|error|unavailable`) **permanece intacto**: o SQL não publica um status "inconsistent", que sequer pertence ao domínio de `MetricSectionStatus`. Inconsistência é uma **camada por cima**, não um estado.

### 20.10 Recorte por datas de protocolo (`protocol-date-filters.ts`)

Arquivo: `src/lib/ai-metrics/protocol-date-filters.ts`. É o que faz os filtros **"Criação do protocolo"** e **"Última interação"** (da `MetricsFiltersBar`) valerem para **todas** as métricas.

| Função | Papel |
|---|---|
| `isEventPeriodUnrestricted(period)` | `true` quando `startDate` e `endDate` são ambos `null` — o período de evento não restringe nada |
| `protocolDateFilters(period)` | Extrai `{ created, lastInteraction }` do período |
| `protocolDateKey(period)` | **Preserva as chaves de cache legadas** quando nenhuma corte de protocolo foi escolhida (devolve `[]`) |
| `metricsRpc(period)` | Devolve um chamador de RPC que **troca a função** quando há corte de protocolo |

**A regra de arquitetura (comentário literal):** *"One server-side cohort for every metric and drilldown; **never filter capped rows in the browser**."*

Quando há corte de protocolo (`created`, `lastInteraction`) **ou** o período de evento é irrestrito, a chamada deixa de ir à RPC da métrica e passa por um **wrapper**:

```
get_ai_metrics_by_protocol_dates(
  p_schema_name, p_metric: "<rpc original>", p_args: {...},
  p_created_from, p_created_to, p_interaction_from, p_interaction_to
)
```

Com período de evento irrestrito, `p_args` ganha `eventPeriodUnrestricted: true`.

> **Por que isso importa para o redesenho:** a corte é resolvida **no servidor, uma vez, para todas as métricas e drill-downs**. Filtrar no navegador produziria números diferentes entre o card e o drill-down — exatamente o defeito que o catálogo existe para impedir.

---

## 21. Modais do domínio

Um bloco por modal. Modais já detalhados em seções anteriores aparecem aqui em forma resumida, com a referência cruzada.

### 21.1 Novo Agente / Renomear Agente (`AgentFormDialog`)

Arquivo: `src/components/ia/AgentFormDialog.tsx`. **Um único componente para os dois modos** (`create` | `rename`) — antes existiam duas implementações divergentes (a do seletor nem tinha o campo de tipo).

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Criar um agente novo ou atualizar nome/descrição/tipo de um existente |
| **Gatilho** | Galeria: botão "Novo Agente" · Workspace: `AgentSelectorBar` → "Novo Agente" · `AgentActionsMenu` → **Renomear** |
| **Tipo** | `Dialog` padrão |
| **Destrutivo?** | Não |
| **Título** | "Novo Agente" / "Renomear Agente" |
| **Descrição** | create: "Crie um novo agente de IA. Em seguida você configura suas versões, prompts e conhecimento." · rename: "Atualize o nome, a descrição e o tipo do agente." |

**Campos:**

| Campo | Controle | Detalhe |
|---|---|---|
| **Nome do Agente** | `Input` `id="{base}-name"`, `autoFocus` | Placeholder "Ex: Esperanza, Agente de Cobrança". **Obrigatório** (botão desabilitado sem ele) |
| **Descrição (opcional)** | `Textarea` 3 linhas | Placeholder "Para que serve este agente..." |
| **Tipo do Agente** | `RadioGroup` com `aria-labelledby` | Dois cartões clicáveis (`Label` envolvendo o `RadioGroupItem`); o selecionado ganha `border-primary bg-primary/5` |

**Cartões de tipo (`AI_AGENT_TYPE_LABELS`):**

| Valor técnico | Rótulo | Descrição |
|---|---|---|
| `conversational` | **Agente Externo** | "Fala direto com o cliente" |
| `internal` | **Agente Interno** | "Fala direto com a equipe interna" |

> O valor técnico no banco continua `conversational`/`internal` — só o **rótulo** mudou. O redesenho não pode "corrigir" o rótulo para "Conversacional".

**Botões:** **Cancelar** (`outline`) · **"Criar Agente"** / **"Salvar"** (desabilitado sem nome ou durante o envio; mostra `Loader2`).

**Comportamentos:**
- **Slug derivado automaticamente** no modo create (`slugifyAgentName`): remove diacríticos, minúsculas, mantém `[a-z0-9-]`, colapsa separadores, remove hífens das pontas; vazio vira **`"agente"`**. **O slug não é editável na UI.**
- `isFirstAgent` marca o agente criado como **padrão** (usado quando é o primeiro da org).
- **Re-hidratação guardada por ref**: o formulário só re-preenche quando o diálogo **abre** (ou o alvo/modo muda) — nunca durante a digitação.
- O prefixo dos `id` muda por modo (`agent-create-*` / `agent-rename-*`), então os dois podem coexistir no DOM sem colisão.

| Resultado | Toast |
|---|---|
| Criado | **"Agente criado"** / ""{nome}" foi criado." |
| Atualizado | **"Agente atualizado"** |
| Erro | **"Erro ao salvar agente"** + mensagem (destrutivo) |

⚠️ **Sem guard de descarte:** este diálogo fecha direto (X, Escape, clique fora, Cancelar) **sem perguntar**, mesmo com campos preenchidos — diferente do `TagFormDialog` e dos editores do workspace.

### 21.2 Confirmação de troca de status (`AgentStatusConfirmDialog`)

Arquivo: `src/components/ia/AgentActionsMenu.tsx` (exportado à parte para teste direto, sem depender do dropdown Radix).

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Confirmar Ativar / Inativar / Arquivar declarando o impacto |
| **Gatilho** | Itens **Ativar**, **Inativar**, **Arquivar** do `AgentActionsMenu` |
| **Tipo** | `AlertDialog` |
| **Destrutivo?** | Só **Arquivar** |

**Conteúdo por status alvo (`STATUS_ACTION_META`):**

| Alvo | Título | Impacto (descrição) | Botão | Destrutivo |
|---|---|---|---|---|
| `active` | **"Ativar agente?"** | "O agente volta a operar: pode ser usado nas integrações, campanhas e conversas." | **Ativar** | Não |
| `inactive` | **"Inativar agente?"** | "O agente deixa de ser oferecido em novas conversas e integrações. As conversas e métricas já registradas são preservadas — você pode reativá-lo quando quiser." | **Inativar** | Não |
| `archived` | **"Arquivar agente?"** | "O agente sai da operação e fica oculto das listas ativas. O histórico é preservado e ele pode ser reativado depois." | **Arquivar** | **Sim** (botão `bg-destructive`) |
| *(fallback)* | "Alterar status?" | — | Confirmar | Não |

**Comportamentos:**
- O `AlertDialogAction` faz `e.preventDefault()` — **não fecha antes de a mutation resolver**.
- Ambos os botões ficam desabilitados enquanto `isPending`; o de confirmar mostra `Loader2`.
- **Arquivar fica desabilitado quando o agente é o padrão** (`agent.is_default`) — é a pré-condição da exclusão (§19.5).

| Resultado | Toast |
|---|---|
| Sucesso | **"Status atualizado"** / ""{nome}" — {Ativo\|Inativo\|Arquivado}." |
| Erro | **"Erro ao atualizar status"** (destrutivo, sem descrição) |

### 21.3 Excluir agente (`AgentDeleteDialog`)

Bloco completo em **§19**. Resumo:

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Tombstone: tirar o agente da operação preservando o histórico |
| **Gatilho** | `AgentActionsMenu` → **Excluir agente** (só `owner`/`admin`) |
| **Tipo** | `Dialog` `sm:max-w-lg` — **destrutivo** |
| **Confirmação** | Digitar o **slug exato** |
| **Trava** | Não fecha por ESC/overlay enquanto pendente; erro preserva o digitado |

### 21.4 Integração N8N

Arquivo: `src/pages/AgentWorkspace.tsx` (casca) + `src/components/ia/AgentN8NIntegration.tsx` (corpo).

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Entregar ao integrador os identificadores e headers do agente, e (para agente interno) configurar o fechamento A2A |
| **Gatilho** | Botão no cabeçalho do workspace (`DialogTrigger`) |
| **Tipo** | `Dialog` `max-w-2xl`, `max-h-[92vh]`, corpo com rolagem própria (`overscroll-contain`) |
| **Destrutivo?** | Não — mas contém a **remoção da URL do webhook**, que é destrutiva |
| **Título** | ícone `Plug` + **"Integração N8N"** |
| **Descrição** | "Use estes identificadores para configurar o workflow do agente no N8N. O **agent_slug** (ou **agent_id**) deve ser enviado nas chamadas das rotas de IA; sem ele, a org cai no agente padrão." |

**Conteúdo:** ver §17.1 (linhas copiáveis) e §17.2 (`A2AClosureSettingsCard`, exclusivo de agente interno).

**Sem botões de rodapé** — é um diálogo de consulta/configuração; cada bloco tem suas próprias ações.

### 21.5 Nova / Editar tag de transferência (`TagFormDialog`)

Bloco completo em **§15.3**. Resumo:

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Cadastrar/editar um motivo de transferência do agente |
| **Tipo** | `Dialog` `sm:max-w-md` |
| **Campos** | Label, Chave (slug — imutável na edição), Descrição, Cor, Tipo (só criação), Tag ativa (só edição) |
| **Especial** | Criação é uma **cadeia de 3 passos**: nasce inativa → classifica o tipo → ativa |
| **Guard** | `AlertDialog` "Descartar alterações?" ao fechar sujo |

### 21.6 Trocar tipo da tag (`ChangeTypeDialog`)

Bloco completo em **§15.3**. Resumo:

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Reclassificar a tag entre Transbordo e Transferência **com vigência** |
| **Tipo** | `Dialog` `sm:max-w-md` |
| **Elemento-chave** | Aviso âmbar: a mudança vale **a partir de agora** e **não altera métricas passadas** |
| **Botão** | "Aplicar mudanca" / "Sem alteracao" (desabilitado sem mudança) |

### 21.7 Remover tag de transferência

Bloco completo em **§15.3**. `AlertDialog` destrutivo com **bloco de impacto** (contagem de uso, buscada ao abrir).

### 21.8 Liberar todas as tags para este agente

Bloco completo em **§15.2**. `AlertDialog` de **escalada de permissão** (restricted → all), não destrutivo.

### 21.9 Nova Etapa do Funil / Configurar Etapa

Blocos completos em **§16.6** e **§16.7**.

| Aspecto | Nova Etapa | Configurar Etapa |
|---|---|---|
| **Tipo** | `Dialog` | `Dialog` |
| **Campos** | Nome, Chave, Descrição, Ícone, Cor | Nome, Chave (**bloqueada**), Descrição, Ícone, Cor, Etapa Ativa, Notificar via Webhook, Ação Automática + config |
| **Rodapé** | Cancelar · Criar Etapa | **Excluir** (destrutivo, à esquerda) · Cancelar · Salvar |
| **Guard** | `confirmIfDirty` em todos os caminhos de fechamento | idem |

### 21.10 Nova Versão / Restaurar Versão

Bloco completo em **§18.8**. Um único `Dialog` com dois modos; cria sempre um **rascunho**.

### 21.11 Diretriz — Nova / Editar (`GuidelinesEditor`)

Arquivo: `src/components/ia/GuidelinesEditor.tsx`.

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Criar ou editar uma diretriz de comportamento do agente |
| **Gatilho** | Botão de nova diretriz / ação de editar na lista |
| **Tipo** | `Dialog` **em tela cheia** — `p-0 w-[95vw] h-[95vh]`, `flex flex-col` |
| **Título** | "Nova Diretriz" / "Editar Diretriz" |
| **Descrição** | "Defina uma regra de comportamento para o agente" |
| **Cabeçalho** | `px-6 py-4 border-b` com gradiente `from-primary/5 to-transparent` |
| **Corpo** | `flex-1 overflow-y-auto px-6 py-4 space-y-4` — a rolagem é do corpo, não da página |
| **Destrutivo?** | Não |
| **Guard** | `handleDialogOpenChange` → `confirmIfDirty` |

> Campos e categorias: ver a seção da aba **Diretrizes** deste documento.

### 21.12 Regra de Negócio — Nova / Editar (`BusinessRulesBuilder`)

Arquivo: `src/components/ia/BusinessRulesBuilder.tsx`.

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Configurar uma regra SE → ENTÃO |
| **Tipo** | `Dialog` em tela cheia — `p-0 w-[95vw] h-[95vh]` |
| **Título** | "Nova Regra de Negócio" / "Editar Regra" |
| **Descrição** | "Configure uma condição e a ação que o agente deve executar" |
| **Cabeçalho** | mesmo padrão gradiente |
| **Destrutivo?** | Não |
| **Guard** | `confirmIfDirty` |

### 21.13 Prompt — Novo / Editar (`PromptEditor`)

Arquivo: `src/components/ia/PromptEditor.tsx`.

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Escrever o prompt de um cenário |
| **Tipo** | `Dialog` em tela cheia — `p-0 w-[95vw] h-[95vh]` |
| **Título** | "Novo Prompt" / "Editar Prompt" |
| **Descrição** | "Configure o prompt para o cenário selecionado" |
| **Destrutivo?** | Não |
| **Restrição** | O prompt **`general`** (Prompt Base) não pode ser excluído (`handleDelete` retorna cedo) e sua edição exige papel `owner`/`admin` |

### 21.14 Configurações do Playground (`PlaygroundSettingsDialog`)

Arquivo: `src/components/ia/PlaygroundSettingsDialog.tsx`.

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Configurar os webhooks de teste do agente (envio, modo de resposta, timeout, campos do contexto, webhook de resposta, cURL) |
| **Gatilho** | Botão de configurações no Playground — **só para papel `owner`** |
| **Tipo** | `Dialog` `p-0 w-[95vw] max-w-2xl max-h-[90vh]`, cabeçalho com gradiente e corpo rolável |
| **Título** | **"Configurações do Playground"** |
| **Descrição** | "Configure os webhooks para testes do agente de IA" |
| **Destrutivo?** | Não |

**Guard de descarte próprio** — `AlertDialog` com `z-[70]` (para ficar acima do diálogo pai):
- Título: **"Descartar alterações?"**
- Descrição: "Você alterou as configurações do playground e ainda não salvou. Se sair agora, as alterações serão perdidas."
- Botões: **Continuar editando** · **Descartar**

### 21.15 Iniciar nova simulação (`AIPlayground`)

Arquivo: `src/components/ia/AIPlayground.tsx`.

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Avisar que trocar contexto/dados/cenário **limpa a conversa de teste** |
| **Gatilho** | Trocar o contexto, os dados ou o cenário **depois** de já ter enviado mensagens |
| **Tipo** | `AlertDialog` |
| **Título** | **"Iniciar nova simulação?"** |
| **Descrição** | "Trocar o contexto, os dados ou o cenário depois de enviar mensagens inicia uma nova simulação. As mensagens atuais serão limpas." |
| **Botões** | **Cancelar** · **"Iniciar nova simulação"** |
| **Destrutivo?** | Sim na prática (descarta a sessão em tela), mas **sem estilo destrutivo** |

### 21.16 Modal de transcrição da conversa (`ConversationLogs`)

Bloco completo em **§13.8**. Resumo:

| Aspecto | Detalhe |
|---|---|
| **Tipo** | `Dialog` `p-0 w-[95vw] h-[95vh] overflow-hidden` |
| **Título** | `InteractionBadge` + **"Conversa: {contato}"** |
| **Descrição** | Data, nº de turnos e o **link externo** para o Hyperflow |
| **Destrutivo?** | Não — somente leitura |
| **Especial** | Sete estados distintos de completude da transcrição |

### 21.17 Conversa do drill-down (`TransferDrilldownPanel`)

Arquivo: `src/components/ia/TransferDrilldownPanel.tsx`.

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Ler a conversa de um atendimento a partir do drill-down de transferências |
| **Gatilho** | Clique numa linha do drawer de drill-down |
| **Tipo** | `Dialog` `p-0 w-[90vw] max-w-2xl h-[85vh] overflow-hidden` — **menor** que o modal da aba Conversas |
| **Título** | **"Conversa"** (`text-base`) |
| **Descrição** | `sr-only`: "Mensagens do atendimento selecionado, em ordem cronológica." |
| **Subtítulo** | **"Protocolo: {n}"** truncado, quando existe |
| **Destrutivo?** | Não |

> É um **segundo** visualizador de conversa, com casca própria e menor. ⚠️ Oportunidade de redesenho: unificar com o modal de transcrição da aba Conversas — hoje o mesmo conteúdo tem duas aparências e dois tamanhos.

### 21.18 Deletar documento (RAG)

Bloco completo em **§14.2**. `AlertDialog` destrutivo:
- Título: **"Deletar documento?"**
- Descrição: "O documento **{nome}** e todos os seus chunks serão removidos permanentemente. Essa ação não pode ser desfeita."
- Botões: **Cancelar** · **Deletar**

> É a **única** exclusão do módulo que é de fato **permanente** (agente vira tombstone; tag de transferência preserva métricas). O texto diz isso corretamente.

### 21.19 Descartar alterações (guard global do workspace)

Arquivo: `src/pages/AgentWorkspace.tsx` + `src/hooks/useDirtyFormGuard.ts`.

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Impedir perda silenciosa de alterações não salvas em **qualquer** editor do workspace |
| **Gatilho** | Troca de aba/sub-aba, troca de agente, voltar para a galeria, clique em link SPA, botão Voltar/Avançar do navegador |
| **Tipo** | `AlertDialog` único, renderizado pelo **host** (o workspace) |
| **Título** | **"Descartar alterações?"** |
| **Descrição** | "Há alterações não salvas nesta seção. Se você sair agora, elas serão perdidas." |
| **Botões** | **Continuar editando** · **Descartar alterações** |
| **Destrutivo?** | Sim na prática (descarta trabalho), sem estilo destrutivo |

**Arquitetura headless (o que o redesenho precisa preservar):**

| Peça | Papel |
|---|---|
| `useDirtyFormGuardController()` (host) | Mantém o registro de formulários sujos, o estado do `AlertDialog` e `guardNavigation(onProceed)` |
| `useDirtyFormGuard(isDirty)` (cada form) | Registra a sujeira no host via context, instala `beforeunload` enquanto sujo, e devolve `confirmIfDirty(onProceed)` para fluxos locais (fechar um `Dialog` de edição) |

**Comportamentos finos:**

| Situação | Tratamento |
|---|---|
| **Foco** | Ao "Continuar editando", o foco **volta ao controle que originou a navegação** (capturado em `document.activeElement` no momento da confirmação) |
| **Reload / fechar aba / URL externa** | `beforeunload` — prompt **nativo** do navegador |
| **Links da sidebar / AppLayout** | Capturados no `document` em fase de captura, **antes** do React Router. `Ctrl/Cmd+clique`, `download` e `target` externo preservam o comportamento nativo |
| **Voltar / Avançar do navegador** | Uma **entrada sentinela** com a mesma URL é empilhada enquanto há sujeira; ela absorve o primeiro `popstate`, então o Router não desmonta o formulário antes da confirmação. Descartar avança dois passos (`history.go(-2)`) |
| **Salvar sem navegar** | A sentinela é **retirada** para não exigir dois cliques em Voltar |
| **Fora do workspace (sem provider)** | `confirmIfDirty` **prossegue imediatamente** — o guard local passa a ser responsabilidade do próprio componente (padrão do `TagFormDialog`, que tem o seu próprio) |

> Detalhe de implementação relevante: o app usa `<BrowserRouter>` (não data router), então `useBlocker` **não está disponível** — daí a sentinela de histórico. Um redesenho que troque a estrutura de rotas precisa **reimplementar essa proteção**, não apenas reestilizar o diálogo.

### 21.20 Confirmações nativas (`window.confirm`) — as cinco dívidas

Estas **não são modais do design system**. São diálogos do navegador, sem estilo, sem impacto declarado e sem estado de carregamento.

| # | Onde | Texto |
|---|---|---|
| 1 | `FunnelStagesConfig` → Excluir etapa | "Tem certeza que deseja excluir esta etapa?" |
| 2 | `VersionManager` → Publicar | "Publicar este rascunho? A versão atual publicada será arquivada automaticamente." |
| 3 | `VersionManager` → Excluir versão | "Tem certeza que deseja excluir esta versão? Esta ação não pode ser desfeita." |
| 4 | `GuidelinesEditor` → Excluir diretriz | "Tem certeza que deseja excluir esta diretriz?" |
| 5 | `BusinessRulesBuilder` → Excluir regra | "Tem certeza que deseja excluir esta regra?" |
| 6 | `PromptEditor` → Excluir prompt | "Tem certeza que deseja excluir este prompt?" |

> **Bloco de trabalho para o redesenho:** migrar as seis para `AlertDialog` destrutivo, no padrão do `AgentStatusConfirmDialog` — com impacto explícito, estado `pending` e botão destrutivo. O princípio *"nada destrutivo em um clique"* está cumprido; o que falta é o **padrão visual e de conteúdo**.

---

## 22. Estados das telas

O módulo trata **estado como conteúdo**: cada situação tem texto próprio, papel ARIA próprio e, quando cabe, ação de recuperação. Esta seção consolida o repertório.

### 22.1 Os nove estados do módulo

| Estado | Significado | Sinal visual padrão | Ação oferecida |
|---|---|---|---|
| **Carregando** | Requisição em voo | `Loader2` girando **ou** `Skeleton`; `role="status" aria-live="polite" aria-busy` | — |
| **Vazio** | Consultou e não há nada no recorte | Ícone neutro (`Inbox`, `Tag`, `FileJson`, `Layers`, `Search`) + frase contextual | Às vezes, um CTA de criação |
| **Erro** | A consulta falhou | `Alert role="alert"`, borda/fundo destrutivos, ícone `AlertTriangle`/`AlertCircle` | **"Tentar novamente"** |
| **Indisponível** | O recurso não existe nesta org / não foi publicado | Ícone `CircleSlash`, `role="status"` | — |
| **Não se aplica** | Não **pode** haver dado (ex.: funil de agente interno) | Badge **"Não se aplica"** + motivo; ou a seção some | — |
| **Parcial** | Números válidos que cobrem menos que o pedido | Badge **"Parcial"** + tooltip com as causas | — |
| **Lacuna de ingestão** | Existe evidência de atividade, mas a fonte canônica está vazia | `Alert role="alert"` **"Lacuna de ingestão"** + código | — |
| **Inconsistente** | Invariante do servidor reprovada | `Alert` âmbar **"Dados inconsistentes"** + códigos + tabela | — |
| **Desatualizado (stale)** | Dados carregados, mas possivelmente velhos | Aviso âmbar **acima** do conteúdo, sem escondê-lo | — |

**Regras que separam esses estados** (todas explícitas no código):

1. **Falha nunca vira zero.** Erro renderiza bloco de erro, nunca `0` ou `—` silencioso.
2. **"Não sabemos" nunca vira "está vazio".** `error`/`unavailable` **nunca** viram lacuna de ingestão.
3. **"Não se aplica" ≠ "sem dados".** Zeros num agente interno leriam como "aconteceu zero vez".
4. **Erro nunca colapsa.** Seção secundária vazia nasce recolhida; seção **em erro nunca** — *"esconder um erro atrás de um chevron o faz parecer 'sem dados'"*.
5. **Lista vazia não pode mascarar erro.** Em erro de tags, **as duas** listas de ranking viram um único `SectionErrorState`.
6. **Só o erro inicial toma a tela.** Falha de página seguinte nunca apaga o que já foi lido.
7. **Erro de leitura não vira "não configurado".** No fechamento A2A, isso levaria o operador a reconfigurar algo que já está ativo.
8. **Valor ausente renderiza `—`, nunca `0`.** Vale para todas as linhas do painel técnico.

### 22.2 Matriz de estados por tela

| Tela / componente | Carregando | Vazio | Erro | Somente leitura |
|---|---|---|---|---|
| **Galeria** (`AgentGalleryPage`) | — | "Configure um assistente inteligente para automatizar suas negociações de cobrança via WhatsApp." | — | Botões de escrita ocultos sem `agent-ia:write` |
| **Tags da organização** (`AgentTagsPage`) | delegado ao `TagCatalogTab` | delegado | delegado | `canWrite` propagado |
| **Tags permitidas** (`AgentAllowedTagsConfig`) | `Card` com 4 `Skeleton` `h-10` | "Nenhuma tag no catálogo" + orientação | ⚠️ **não há estado de erro** — falha de carga se comporta como vazio | Bloco tracejado **"Modo somente leitura"** |
| **Tags de transferência** (`TransferTagsConfig`) | `Loader2` 32px (`py-12`) | "Nenhuma tag cadastrada" + CTA "Criar primeira tag" | ⚠️ **não há estado de erro** dedicado (só toasts nas mutations) | "Modo somente leitura - crie um rascunho para editar" |
| **Etapas do funil** (`FunnelStagesConfig`) | `Loader2` 32px (`py-12`) | ⚠️ lista simplesmente vazia, **sem empty state** | ⚠️ **não há estado de erro** (só `logError`) | "Modo somente leitura - crie um rascunho para editar" + botão desabilitado |
| **Versões** (`VersionManager`) | `Loader2` 32px (`py-12`) | `Card` com `Layers` 48px, texto muda conforme haja busca | ⚠️ **não há estado de erro** (falha de duplicar só faz `logError`) | `canWrite=false` some com "Nova Versão" e ações de escrita |
| **Fechamento A2A** (`A2AClosureSettingsCard`) | "Carregando configuração do fechamento A2A…" | badge **"Não configurado"** | bloco `role="alert"` + **"Tentar novamente"** | Campos `disabled` + "Somente owner ou admin da organização podem alterar esta configuração." |
| **Exclusão de agente** (`AgentDeleteDialog`) | 3 `Skeleton` + `sr-only` "Verificando impacto da exclusão…" | — | `Alert` "Não foi possível verificar a exclusão" | Item do menu oculto para quem não é `owner`/`admin` |
| **Conversas** (`ConversationLogs`) | 3 blocos `h-20 animate-pulse` | frase contextual por recorte (all/human/a2a) | `role="alert"` "Falha ao carregar as conversas." + **"Tentar novamente"** | leitura pura |
| **Transcrição** | `Loader2` 24px | `MessageSquare` 32px + "Nenhuma mensagem registrada" | `role="alert"` + **"Tentar novamente"** | leitura pura |
| **RAG — lista** | `Loader2` + "Carregando documentos..." | `Card` com `FileJson` 40px + orientação | `AlertCircle` + "Erro ao carregar documentos." | `Alert`: "Você não tem permissão para enviar documentos. Contate um administrador." |
| **RAG — busca** | botão vira "Buscando..." | "Nenhum resultado encontrado" / card de threshold | `Alert variant="destructive"` com a mensagem | — |
| **Métricas — seção** (`MetricSectionBoundary`) | `Skeleton` + `sr-only` "Carregando {label}…" | "Nenhum dado no período selecionado." | "Erro ao carregar {título}" + **"Tentar novamente"** (refaz **só** a query da seção) | leitura pura |
| **Snapshot canônico** | skeleton 80px + 2×192px | por seção (`VmSectionBody`) | "Não foi possível carregar a fotografia das métricas" + **"Tentar novamente"** | leitura pura |

> **Achado transversal:** as quatro telas de **configuração** (tags permitidas, tags de transferência, etapas do funil, versões) **não têm estado de erro de leitura**. Uma falha de carga se apresenta como lista vazia — exatamente o anti-padrão que o lado de métricas combate com rigor. É a maior inconsistência de estado do módulo e um item concreto para o redesenho.

### 22.3 Estados de escrita (formulários)

| Estado | Como aparece |
|---|---|
| **Limpo** | Nada de especial; botões de ação **ocultos** (tags permitidas) ou desabilitados |
| **Sujo** | Badge `outline` **"Alterações não salvas"** (tags permitidas); botões **Descartar** / **Salvar** aparecem; guard de navegação armado |
| **Enviando** | Botão com `Loader2`, texto muda ("Enviando...", "Removendo...", "Gerando…"), demais controles `disabled` |
| **Erro de envio** | Toast destrutivo; **o diálogo não fecha** (`TransferTagsConfig`) ou o formulário é preservado (`AgentDeleteDialog`) |
| **Sucesso** | Toast + fechamento + (quando aplicável) limpeza do formulário |

**Regra geral de edição no workspace:** **não há autosave**. O banner do rascunho diz isso explicitamente. Toda seção editável tem `Salvar` próprio.

### 22.4 Estados de permissão

| Papel | O que muda visualmente |
|---|---|
| Sem `agent-ia:read` | A rota inteira é bloqueada pelo guard (`src/App.tsx`) |
| Com `read`, sem `write` | Editores em **modo somente leitura** (bloco tracejado), botões de criar ocultos ou desabilitados, RAG substitui o formulário por um `Alert` |
| `manager`/`admin` com `write` | Edita tudo, exceto o Prompt Base e o fechamento A2A |
| `owner`/`admin` | + Prompt Base (`general`), + fechamento A2A, + **Excluir agente** |
| `owner` | + Configurações do Playground |

**Padrão declarado:** onde a ação é **impossível** (fechamento A2A em agente externo), a seção **não é renderizada** — *"um controle desabilitado sugeriria que basta um clique para habilitar algo que o banco rejeita"*. Onde a ação é **possível mas não permitida**, o controle aparece desabilitado **com a explicação**.

### 22.5 Estado de tela na URL

Arquivo: `src/lib/agent-workspace-url.ts`.

| Parâmetro | Conteúdo |
|---|---|
| `?tab=` | Aba do workspace (`versions`, `personality`, `guidelines`, `rules`, `prompts`, `funnel`, `tags`, `playground`, `conversations`, `knowledge`, `metrics`) |
| `?funnel=` | Sub-aba do funil (`stages`, `transfer-tags`) |
| `?interaction=` | Recorte de interação (`all`, `human`, `a2a`) — gravado com `replace` |
| `?agentId` (path) | `/agent-ia/:agentId` |

Regras:
- Aba, sub-aba e recorte são **deep-linkáveis** — o estado é compartilhável por link.
- O recorte de interação é **preservado ao abrir e fechar** o detalhe da conversa.
- As abas disponíveis **dependem do tipo do agente** (agente interno não tem funil nem transferências).
- Toda navegação interna passa pelo `guardNavigation` do dirty guard.

---

## 23. Fluxos de uso passo a passo

Cada fluxo abaixo é reconstruído a partir do código. Eles são o **teste de aceitação do redesenho**: se um deles ficar mais longo ou perder um aviso, a interface regrediu.

### 23.1 Criar o primeiro agente da organização

1. Usuário com `agent-ia:write` abre `/agent-ia`.
2. Vê o empty state: *"Configure um assistente inteligente para automatizar suas negociações de cobrança via WhatsApp."*
3. Clica em **Novo Agente** → abre o `AgentFormDialog` em modo `create`.
4. Preenche **Nome** (obrigatório) e, opcionalmente, **Descrição**.
5. Escolhe o **Tipo**: **Agente Externo** (fala com o cliente) ou **Agente Interno** (fala com a equipe).
6. **Criar Agente** → o slug é derivado do nome automaticamente; `isFirstAgent` marca o agente como **padrão**.
7. Toast **"Agente criado"**; o consumidor navega para o workspace do agente.

**O que o usuário ainda não tem neste ponto:** versão publicada, prompts, etapas de funil, tags de transferência, base de conhecimento. O próximo passo natural é a aba **Personalidade** (que cria a v1).

### 23.2 Editar uma configuração publicada (copy-on-write)

1. Abrir o workspace do agente. A versão exibida é a **publicada**.
2. As seções aparecem em **modo somente leitura** — bloco tracejado *"Modo somente leitura - crie um rascunho para editar"*.
3. O `AutoDraftWrapper` oferece criar um **rascunho**.
4. Com o rascunho ativo, os editores destravam. O banner do rascunho lembra que **não há autosave**.
5. Editar → **Salvar** em cada seção.
6. Ir para a aba **Versões** → menu da versão rascunho → **Publicar**.
7. `window.confirm`: *"Publicar este rascunho? A versão atual publicada será arquivada automaticamente."*
8. Confirmar → o rascunho vira `published` e a versão anterior vira `archived`.

**Onde o usuário pode se perder hoje:** o passo 6 exige trocar de aba; não há botão "Publicar" a partir do editor. Se houver alterações não salvas, o **dirty guard** intercepta a troca de aba com *"Descartar alterações?"*.

### 23.3 Voltar para uma versão antiga

1. Aba **Versões** → localizar a versão `Arquivado`.
2. Menu ⋯ → **Restaurar como Rascunho**.
3. O diálogo abre em modo `restore`, com a versão escolhida como origem e a descrição pré-preenchida **"Restauração de versão anterior"**.
4. **Restaurar como v{n}** → cria um **novo rascunho** (não sobrescreve nada).
5. Revisar nas abas de edição.
6. **Publicar** (passo 7 do fluxo 23.2).

> A restauração **nunca** é destrutiva: ela sempre cria uma versão nova com o próximo número.

### 23.4 Restringir quais tags um agente pode usar

1. Workspace → aba **Tags**.
2. Bloco superior: **"Tags permitidas para este agente"**, com badge de escopo **"Escopo: Este agente"**.
3. Ler o `Alert` "Como funciona" — em especial: *"se nenhuma estiver marcada, o agente não usa nenhuma tag (não volta automaticamente para 'todas')"*.
4. Selecionar o modo **Somente selecionadas**.
5. Marcar as tags desejadas na lista do catálogo da organização.
6. Badge **"Alterações não salvas"** aparece; surgem **Descartar alterações** e **Salvar**.
7. **Salvar** → grava modo + conjunto numa única chamada transacional.
8. Toast: *"O agente pode usar {n} tag(s) selecionada(s)."*

**Caminho inverso (ampliar):**
4'. Selecionar **Todas as tags** → **Salvar** → `AlertDialog` **"Liberar todas as tags para este agente?"** → **Confirmar**.

**Caminho vizinho (catálogo vazio):** se a organização não tem tags, o passo 5 mostra *"Nenhuma tag no catálogo"* e orienta a cadastrar em `/agent-ia/tags`.

### 23.5 Cadastrar um motivo de transferência

1. Workspace → aba **Funil** → sub-aba **Tags de Transferência**.
2. Ler o card **"Transbordo vs Transferencia"**.
3. **Nova tag**.
4. Preencher **Label** (o slug é derivado automaticamente), **Descrição** (orienta o agente sobre *quando* usar) e **Cor**.
5. Escolher o **Tipo**: Transbordo (falha) ou Transferencia (esperado).
6. **Criar tag** → a cadeia roda: nasce **inativa** → classifica o tipo → **ativa**.
7. Toast: *"Classificada como {Tipo} e ativada."*
8. Copiar o **slug** — é ele que o n8n envia no evento de transferência.

**Se a classificação falhar** (passo 6): a tag fica **inativa** e o toast instrui a abrir "Editar" para corrigir antes de ativar.

### 23.6 Reclassificar uma tag de transferência já em uso

1. Sub-aba **Tags de Transferência** → clicar no badge da coluna **Tipo vigente**.
2. Ler a linha de transição: `Tipo atual: [Transbordo] → [Transferencia]`.
3. Escolher o novo tipo.
4. Ler o aviso âmbar: *"A mudanca vale a partir de agora e nao altera as metricas passadas."*
5. **Aplicar mudanca**.
6. Toast: *"A mudanca vale a partir de agora. Metricas passadas nao mudam."*

> Este é um fluxo com **consequência analítica**: a mesma tag passa a contar em outro balde de acurácia daqui para frente. O aviso de vigência é o que impede o usuário de achar que "corrigiu o histórico".

### 23.7 Configurar as etapas do funil

1. Workspace → aba **Funil** → sub-aba **Funil**.
2. Ler o card "Como funciona?" — o agente externo notifica a Torre por webhook a cada etapa.
3. **Nova Etapa** → Nome, Chave (slug), Descrição, Ícone, Cor → **Criar Etapa**.
4. Arrastar as etapas (mouse **ou teclado**) para definir a ordem do funil.
5. Nos toggles da linha: ligar/desligar **Webhook** e **Ativo** (gravam na hora).
6. Para comportamento automático: `Settings` → **Ação Automática** → configurar o campo correspondente → **Salvar**.

**Excluir etapa:** `Settings` → **Excluir** → `window.confirm` genérico. ⚠️ Nenhum impacto é declarado (ver §25).

### 23.8 Ligar o fechamento automático A2A (agente interno)

1. Workspace de um agente **interno** → botão **Integração N8N**.
2. Rolar até o card **"Fechamento automático A2A"** (ele não existe em agente externo).
3. Conferir o badge: **"Não configurado"**.
4. Se houver **Sugestão padrão preenchida**, conferir a URL; senão, colar a URL `https://…` do webhook.
5. Ajustar **Inatividade (horas)**, **Verificar protocolos a cada (minutos)** e **Intervalo mínimo entre envios (minutos)**.
6. Ligar **Fechamento habilitado**.
7. **Salvar** → a URL some do campo imediatamente; aparece *"Configuração salva. A URL não é exibida novamente."*
8. **Testar webhook** → o POST sai do servidor, com payload sintético; o resultado mostra sucesso/falha + HTTP + duração.
9. Acompanhar em **Última varredura / Próxima verificação / Último envio / Resultado do último envio**.

**Mexer só no switch depois:** deixar a URL em branco (placeholder *"Deixe em branco para manter a URL atual"*) e salvar.

**Trocar a URL:** digitar a nova e salvar (substitui).

**Desligar de vez:** **Remover URL** → confirmação inline *"Remover a URL desliga o fechamento automático deste agente. Confirmar?"* → **Confirmar remoção**.

### 23.9 Excluir um agente (caminho completo)

Este é o fluxo mais longo do módulo — e o encadeamento **só é descoberto um erro por vez** hoje.

1. `owner`/`admin` abre o menu ⋯ do agente → **Excluir agente**.
2. O preflight roda. Três desfechos possíveis:
   - **Bloqueado por `agent_is_default`** → fechar, abrir o menu de **outro** agente → **Definir como padrão** → voltar ao passo 1.
   - **Bloqueado por `agent_not_archived`** → fechar, menu ⋯ → **Arquivar** → confirmar → voltar ao passo 1.
   - **Bloqueado por `open_protocols` / `pending_a2a_dispatches`** → aguardar a operação/fila → voltar ao passo 1.
3. Elegível: ler o bloco **"O que será preservado"** (versões, RAG, protocolos, mensagens, chamadas A2A).
4. Digitar o **slug exato** no campo de confirmação.
5. **Remover da operação**.
6. Toast **"Agente excluído"** — *""{nome}" saiu da operação. O histórico foi preservado."*
7. O workspace navega de volta para `/agent-ia`.

**Sequência real das pré-condições:** promover outro a padrão → arquivar → excluir. **O slug permanece reservado** para sempre.

### 23.10 Auditar uma queda de acurácia

1. Workspace → aba **Métricas**.
2. Ajustar o período na `MetricsFiltersBar`.
3. Ler o card **Acurácia** na primeira dobra e a caption com o rótulo canônico.
4. Abrir o **"?"** do card: população, data de referência, fórmula, exclusões e com quem **não** comparar.
5. Conferir a **barra de composição "Desfechos por protocolo"** — quais baldes cresceram (Transbordo? Transferência assistida? Transferido sem classificação?).
6. Descer para a seção **Transferências**: trocar a unidade (**Protocolos** ↔ **Eventos**) e o agrupamento (**Por tipo** ↔ **Por tag**).
7. Clicar numa linha do ranking → **drill-down** com os atendimentos que formam o número.
8. Abrir uma conversa do drill-down para ler a transcrição.
9. Se houver badge **"Parcial"**, abrir o tooltip **"Por que esta fotografia está parcial"**.
10. Abrir **"Detalhes técnicos e verificações"** no rodapé: identidade da fotografia, corte de ingestão, cobertura, contadores de qualidade, situação das seções e invariantes.

**Se aparecer "Lacuna de ingestão"** em Atividade de mensagens: o número **não** é zero — a fonte canônica está vazia com protocolos existindo. O texto administrativo instrui a verificar a ingestão ou executar backfill.

### 23.11 Gerar o relatório para terceiros

1. Aba **Métricas**, com o recorte já ajustado.
2. Botão **Gerar relatório** na toolbar.
3. Se desabilitado, ler o **tooltip** — ele diz o motivo exato (snapshot desativado, carregando, erro, seção obrigatória em erro, subconjunto externo não calculado).
4. Habilitado: clicar → **"Gerando…"**.
5. Ordem interna obrigatória: **auditoria → render → download**.
6. Toast **"Relatório gerado"** / "Download iniciado: {arquivo}".

**Se a auditoria falhar:** nada é baixado. Erro recuperável oferece **"Tentar novamente"**; erro `22023` (**"Auditoria do banco desatualizada"**) **não** oferece retry.

### 23.12 Investigar um atendimento específico

1. Aba **Conversas**.
2. Buscar por nome, documento, telefone, contrato, e-mail ou protocolo (≥ 2 caracteres, debounce 300 ms, resolvido **no banco**).
3. Ajustar o recorte: **Todas** / **Humano** / **A2A**.
4. Filtrar por período (Hoje / Ontem / Esta semana / Personalizado), tags e etapa.
5. Clicar na linha do protocolo → abre a **transcrição**.
6. Ler as bolhas, os metadados do agente (hora, sentimento, intenção, tempo de processamento) e os anexos.
7. Conferir o rodapé de completude ("Transcrição completa", "Conversa em andamento", "Transcrição parcial…").
8. Se precisar do contexto completo, abrir o **link externo do Hyperflow** no cabeçalho.

### 23.13 Alimentar a base de conhecimento (RAG)

1. Workspace → aba **Conhecimento**.
2. Seção **Enviar documento**: dar um **Nome**, escolher a **Visibilidade** (Todos os contatos ou um filtro) e selecionar o **Arquivo** (JSON, PDF, Word, Excel).
3. **Enviar documento** → mensagem verde: "Documento enviado. O processamento de embeddings foi iniciado e pode levar alguns minutos."
4. Acompanhar em **Documentos indexados** o `StatusBadge`: **Aguardando** → **Processando** → **Pronto** (ou **Erro**, com a mensagem na própria linha).
5. Seção **Testar busca semântica**: escrever a consulta, ajustar `top_k` e o threshold, opcionalmente informar o CNPJ do contato (para avaliar documentos com filtro) → **Buscar**.
6. Ler os chunks e o `SimilarityBadge` de cada um; expandir com **Mostrar mais**.
7. Se nada retornar: *"Tente reduzir o threshold ou usar termos diferentes."*

**Reprocessar** (ícone `RefreshCw`) quando o documento mudou de status para erro ou o conteúdo foi atualizado; **Deletar** remove documento + chunks **permanentemente**.

### 23.14 Testar o agente no Playground

1. Workspace → aba **Playground**.
2. (owner) **Configurações do Playground** → webhook de envio, modo de resposta, timeout, campos do contexto, webhook de resposta, cURL → **Salvar**.
3. Escolher a origem dos dados: contrato **real** (com busca) ou **fictício**.
4. Conferir o `SelectedContractContextCard` (somente leitura).
5. Conversar no composer (**Enter** envia, **Shift+Enter** quebra linha).
6. Trocar contexto/dados/cenário depois de enviar → `AlertDialog` **"Iniciar nova simulação?"** avisando que as mensagens serão limpas.
7. Consultar o **histórico** de sessões anteriores e o **prompt compilado**.

---

## 24. Responsividade e acessibilidade

### 24.1 Responsividade — o princípio que difere do usual

O módulo vive **dentro de uma sidebar**, então a largura disponível **não** é a do viewport. O código responde a isso em dois lugares:

| Caso | Técnica |
|---|---|
| **KPIs da primeira dobra** (`OverviewKpis`) | `repeat(auto-fit, minmax(min(210px,100%), 1fr))` — o grid reage ao **espaço do container**, não a breakpoints de viewport |
| **Barras de ação** (`A2AClosureSettingsCard`, cabeçalhos) | `flex-wrap` com `ml-auto` no botão secundário — em telas baixas o "Testar webhook" continua junto das ações principais, não afunda abaixo da observabilidade |

### 24.2 Breakpoints observados

| Padrão | Onde | Efeito |
|---|---|---|
| `sm:` | `AgentAllowedTagsConfig` (`RadioGroup` vira linha), `A2AClosureSettingsCard` (`<dl>` de 2 colunas), diálogos `sm:max-w-md` / `sm:max-w-lg` | Ajuste de eixo e largura |
| `md:` | `RagDocumentList` — coluna **Data** (`hidden md:table-cell`) | Esconde coluna secundária |
| `lg:` | `RagDocumentList` — coluna **Visibilidade** (`hidden lg:table-cell`); grid de 3 colunas dos rankings/sentimento | Densidade progressiva |
| `xl:` | Grids de 12 colunas do snapshot (`8+4`, `5+7`) | Layout de painel |

**Colunas que somem primeiro** (ordem de sacrifício na tabela de RAG): *Arquivo original* (`sm`) → *Data* (`md`) → *Visibilidade* (`lg`). **Nome, Chunks, Status e Ações nunca somem.**

### 24.3 Diálogos em tela pequena

| Padrão | Diálogos |
|---|---|
| `w-[95vw] h-[95vh]` | Transcrição de conversa, Diretriz, Regra, Prompt |
| `w-[90vw] max-w-2xl h-[85vh]` | Conversa do drill-down |
| `w-[95vw] max-w-2xl max-h-[90vh]` | Configurações do Playground |
| `max-w-2xl max-h-[92vh]` | Integração N8N |
| `sm:max-w-md` | Tag de transferência, troca de tipo |
| `sm:max-w-lg` | Exclusão de agente |

**Padrão estrutural dos diálogos grandes:** `flex flex-col p-0` com cabeçalho `shrink-0` e corpo `flex-1 overflow-y-auto` — **a rolagem é do corpo**, o cabeçalho fica fixo. O de Integração N8N ainda usa `overscroll-contain` para não rolar a página atrás.

### 24.4 Acessibilidade — o que já está feito

**Nomes acessíveis (`aria-label`):**

| Elemento | Rótulo |
|---|---|
| Menu de ações do agente | "Ações do agente {nome}" |
| Handle de arraste da etapa | "Reordenar etapa: {stage_name}" |
| Botão de configurar etapa | "Configurar etapa: {stage_name}" |
| Checkbox de tag permitida | "Permitir a tag {label} para este agente" |
| Editar/Excluir tag de transferência | "Editar tag {label}" / "Excluir tag {label}" |
| Seletor de cor | `role="group"` + "Cor da tag de transferência"; cada pílula com o nome da cor e `aria-pressed` |
| Abrir conversa | "Abrir conversa {protocolo}" |
| Link do Hyperflow | "Abrir conversa {protocolo} no Hyperflow" |
| Remover filtro | "Remover filtro de tag: {tag}" / "Remover filtro de etapa: {nome}" |
| Chevron de seção | "Recolher {título}" / "Expandir {título}" |
| Toggles de métrica | "Unidade das transferências", "Agrupamento das transferências", "Tipo de tag" |
| Seletor de definição de funil | "Selecionar definição de funil" |
| `InfoTooltip` | `label` é prop **obrigatória** |

**Papéis e regiões:**

| Padrão | Uso |
|---|---|
| `role="tablist"` + `role="tab"` | `InteractionFilterToggle` (Todas/Humano/A2A), com `aria-label="Filtrar conversas por tipo de interação"` |
| `role="alert"` | Todo bloco de **erro** (a11y anuncia sem interação) |
| `role="status"` + `aria-live="polite"` | Carregamentos e avisos não urgentes |
| `aria-busy` | Enquanto carrega |
| `sr-only` | Textos que o leitor precisa e o mouse não: "Carregando {label}…", "Verificando impacto da exclusão…", o motivo do chip "Parcial", a descrição do modal de drill-down |
| `aria-labelledby` | `SectionShell` (`<section>` ↔ `<h2>`), `RadioGroup` de tipo de agente |
| `aria-describedby` | Chip "Parcial" |
| `role="img"` + `aria-label` | Donut de sentimento: "Distribuição de sentimento de {n} mensagens analisadas" |
| `<caption class="sr-only">` | Toda `ChartDataTable` |

**Teclado:**

| Interação | Suporte |
|---|---|
| **Reordenar etapas do funil** | `KeyboardSensor` com `sortableKeyboardCoordinates` — funciona **sem mouse** |
| **Legenda de gráfico** | `ChartLegend` é selecionável por teclado, com `aria-pressed` |
| **Chip "Parcial"** | `tabIndex={0}` + `cursor-help` |
| **Composer do Playground** | Enter envia, Shift+Enter quebra linha |
| **Retorno de foco** | Ao "Continuar editando" no dirty guard, o foco volta ao controle de origem |
| **Hit area do "?"** | `p-1 -m-1` amplia para ~24px sem alterar o layout |

**Cor nunca é o único sinal:**

| Componente | Sinal redundante |
|---|---|
| Badges de status (versão, documento RAG, agente) | Ícone + texto |
| `MetricSectionBoundary` | Ícone + texto em todos os seis estados |
| `ChartLegend` | Marcador textual + cor |
| Metadados de sentimento | Ícone (`Smile`/`Meh`/`Frown`) + rótulo |
| Etapas do funil | Ícone + nome + `stage_key` |

**Movimento:** `MetricTrendChart` respeita `prefers-reduced-motion`.

**Tabelas acessíveis:** todo gráfico canônico acompanha uma `ChartDataTable` em `<details>` "Ver tabela de dados" — o dado existe em forma tabular, não só em pixels. E o funil da corte tem a sua própria tabela com *Etapa · Alcançaram · Conversão da anterior · Abandono · Do início*.

### 24.5 Acessibilidade — lacunas encontradas

| Lacuna | Onde | Gravidade |
|---|---|---|
| Gatilho `MoreHorizontal` **sem nome acessível** | `VersionManager` (menu de ações da versão) | Alta — falha `button-name` |
| `window.confirm` no lugar de `AlertDialog` | 6 exclusões/publicações (§21.20) | Média — sem controle de foco nem de anúncio pelo app |
| Falha silenciosa ao copiar | `CopyRow` (`AgentN8NIntegration`) — clipboard indisponível não dá feedback | Média |
| `Select` de ícone/cor expõe **nome técnico** | `FunnelStagesConfig` ("CreditCard", "emerald") | Baixa (compreensão), mas visível ao usuário final |
| Sem estado de erro de leitura | 4 telas de configuração (§22.2) | Alta — falha se apresenta como vazio |
| Textos sem acentuação | `TransferTagsConfig`, `FunnelStagesConfig` (parcialmente) | Baixa, mas inconsistente com o resto |

> ⚠️ A confirmar: não auditei contraste de cor das paletas `bg-{cor}-100 / text-{cor}-700` em tema escuro. As classes são fixas (não usam tokens de tema), então **é provável** que os badges coloridos de tag e de etapa fiquem com contraste ruim no dark mode. Vale verificar antes do redesenho.

---

## 25. Dores e oportunidades para o redesenho

Esta seção separa **o que precisa sobreviver** de **o que pode (e deve) mudar**. Nada aqui é opinião de estilo: cada item aponta para uma evidência no código.

### 25.1 O que NÃO pode mudar (invariantes de produto)

| # | Invariante | Por quê |
|---|---|---|
| 1 | **Falha nunca vira zero** | Um `0` em lugar de erro é um número falso publicado. Todo bloco de erro tem texto próprio e "Tentar novamente" |
| 2 | **"Não se aplica" ≠ "sem dados"** | Agente interno não tem funil nem transferência; zeros leriam como "aconteceu zero vez" |
| 3 | **"Não sabemos" ≠ "está vazio"** | A lacuna de ingestão (`MESSAGE_ACTIVITY_CANONICAL_GAP`) existe só para isso |
| 4 | **Toda métrica declara unidade e janela** | `formatMetricLabel` publica `"{label} ({unitLabel})"`; encurtar quebra o contrato |
| 5 | **Protocolos ≠ eventos em transferências** | São duas `metricKey` distintas; a seção mostra **os dois totais** sempre |
| 6 | **Transferência ≠ transbordo** | Tipos diferentes, cores diferentes, efeito diferente na acurácia |
| 7 | **Dimensão multivalor nunca vira composição** | Quatro dimensões do catálogo; a `MetricCompositionBar` as recusa por contrato |
| 8 | **Dado inconsistente é omitido, não publicado** | Invariante reprovada bloqueia a seção com diagnóstico — e **nunca** mostra o valor bloqueado |
| 9 | **Nada destrutivo em um clique** | Toda ação de risco passa por confirmação com impacto |
| 10 | **Agente não se apaga: vira tombstone** | Confirmação por slug, slug segue reservado, histórico íntegro |
| 11 | **A URL do webhook A2A nunca reaparece** | É credencial; só o host mascarado volta para a tela |
| 12 | **Sem autosave** | Todo editor tem Salvar próprio, e o dirty guard protege a saída |
| 13 | **Estado de tela vive na URL** | Aba, sub-aba e recorte são deep-linkáveis |
| 14 | **Fechamento A2A só existe em agente interno** | Fora dele a seção **não é renderizada** — nunca desabilitada |
| 15 | **Métrica sem entrada no catálogo aparece sem "?"** | Melhor não explicar do que inventar explicação |

### 25.2 Dores estruturais

#### D1 — Quatro telas de configuração sem estado de erro

`AgentAllowedTagsConfig`, `TransferTagsConfig`, `FunnelStagesConfig` e `VersionManager` **não têm estado de erro de leitura**. Uma falha de rede se apresenta como **lista vazia** — o mesmo anti-padrão que o lado de métricas combate com rigor (§22.2).

**Oportunidade:** aplicar `MetricSectionBoundary` (ou um equivalente) às telas de configuração. O componente já existe, com os seis estados e o botão de retry.

#### D2 — Seis confirmações nativas (`window.confirm`)

§21.20. Sem estilo, sem impacto declarado, sem estado `pending`, sem controle de foco pelo app.

**Oportunidade:** migrar para `AlertDialog` no padrão do `AgentStatusConfirmDialog`, acrescentando **impacto real** — hoje "Tem certeza que deseja excluir esta etapa?" não diz quantos protocolos passaram por ela nem o que acontece com as métricas históricas.

#### D3 — A exclusão de agente revela as pré-condições uma por vez

O caminho real é **promover outro a padrão → arquivar → excluir** (§23.9), mas o usuário descobre isso em três rodadas de tentativa e erro.

**Oportunidade:** transformar o `AgentDeleteDialog` num fluxo que mostra as pré-condições como **checklist** desde a abertura, com atalho para resolver cada uma. As contagens `open_protocols` e `pending_a2a_dispatches` já vêm no `impact` e hoje não são exibidas.

#### D4 — Dois visualizadores de conversa

O modal da aba Conversas (`95vw × 95vh`, com cabeçalho rico e sete estados de completude) e o do drill-down de transferências (`90vw × 85vh`, cabeçalho mínimo) mostram a **mesma coisa** com aparências diferentes (§21.17).

**Oportunidade:** um único visualizador, parametrizado.

#### D5 — Publicar versão está longe de onde se edita

Não há caminho do editor para a publicação: é preciso trocar para a aba **Versões**, achar o rascunho e usar o menu ⋯ (§23.2). E a troca de aba pode ser interceptada pelo dirty guard.

**Oportunidade:** ação de publicar acessível do próprio banner de rascunho, com o mesmo aviso de arquivamento automático.

#### D6 — Criação de etapa e configuração de etapa são incoerentes

O diálogo de **criar** não expõe **Ativa**, **Webhook** nem **Ação automática** — embora os campos existam no estado do formulário (§16.6). O usuário cria e precisa reabrir em "Configurar" para terminar.

**Oportunidade:** um formulário só, ou uma criação que assuma explicitamente os defaults e diga quais são.

#### D7 — Rótulos técnicos vazando na UI

O `Select` de ícone mostra "CreditCard", "MessageCircle"; o de cor mostra "emerald", "gray" (§16.3).

**Oportunidade:** rótulos em português (ou só a amostra visual, sem nome).

#### D8 — Copy sem acentuação em parte do módulo

`TransferTagsConfig` inteiro ("Transferencia", "metricas", "Acoes", "Rotulo") e trechos do funil.

**Oportunidade:** normalizar. É mudança de conteúdo — precisa de decisão, não só de CSS.

#### D9 — Densidade da aba Métricas

O painel canônico tem **10 seções ancoradas** + painel técnico em accordion, com toolbar sticky, filtros de protocolo, granularidade e exportação. É a tela mais pesada do módulo.

**Oportunidade:** o índice de âncoras já existe (`SectionAnchorIndex`); o redesenho pode transformá-lo em navegação persistente e tratar a primeira dobra como resumo executivo real. **Sem** remover nenhuma seção — todas carregam contrato.

#### D10 — Três lugares diferentes chamados "Tags"

Catálogo da organização, whitelist do agente e tags de transferência (§15). Os badges de escopo ("Escopo: Este agente") já ajudam, mas a nomenclatura ainda colide.

**Oportunidade:** nomes distintos na navegação (ex.: *Tags de conversa* · *Tags permitidas* · *Motivos de transferência*), preservando os conceitos.

#### D11 — Feedback silencioso em dois pontos

- `CopyRow`: falha de clipboard não avisa nada.
- `VersionManager`: falha ao duplicar/restaurar só faz `logError` — sem toast, sem mensagem.

**Oportunidade:** toast em ambos. É a regra do próprio módulo ("falha nunca some").

#### D12 — Menu de ações da versão sem nome acessível

§18.6. Falha direta de `button-name`.

### 25.3 Oportunidades de alto valor (não são correções)

| # | Oportunidade | Base no código |
|---|---|---|
| O1 | **Onboarding do agente novo**: depois de criar, o usuário fica num workspace vazio sem saber a ordem (Personalidade → Prompts → Funil → Tags → Conhecimento → Publicar) | A ordem existe nas abas, mas nada a comunica |
| O2 | **Painel de saúde da integração**: `agent_slug`, headers, último evento recebido, estado do fechamento A2A e freshness num só lugar | Os dados já existem em `AgentN8NIntegration` + observabilidade A2A + contadores de qualidade |
| O3 | **Diff entre versões**: hoje só há "Descrição das Mudanças" escrita à mão | `ai_versions` guarda o snapshot completo |
| O4 | **Impacto antes de publicar**: o que muda entre o rascunho e a publicada | Mesmo dado do O3 |
| O5 | **Ponte tag ↔ métrica**: da tag de transferência para o ranking "Por motivo (tag)" e daí para o drill-down | As duas pontas existem; falta o link |
| O6 | **Explicar a diferença entre "Protocolos com mensagens" e o denominador da acurácia na primeira dobra** | Hoje está nas notas dos cards; é a dúvida recorrente que o código documenta em prosa |
| O7 | **Estado de "configuração incompleta" do agente**: sem prompt base, sem etapas, sem tags, sem versão publicada | Todos verificáveis; nada é exibido hoje |

### 25.4 Onde o redesenho tende a errar

Riscos concretos, derivados das notas do código:

| Risco | Consequência |
|---|---|
| Encurtar os rótulos canônicos para caber no card | "Transferências" volta a ser ambíguo entre protocolos e eventos |
| Transformar "Passagens no período" em barra 100% | Publica uma distribuição que não existe (dimensão multivalor) |
| Usar curva suave (`monotone`) nos gráficos de tendência | Inventa valores não medidos — o código força `type="linear"` de propósito |
| Colapsar seções em erro para "limpar a tela" | Erro escondido atrás de chevron parece "sem dados" |
| Unificar "Sem análise" com "Neutro" no sentimento | "Sem análise" **não é** sentimento neutro |
| Mostrar o valor omitido junto do aviso de inconsistência | Anula o bloqueio |
| Tratar o donut de sentimento e o card de Mensagens como a mesma base | São bases diferentes (log de interações × base canônica), com retenções diferentes |
| Reexibir a URL do webhook A2A "para facilitar a edição" | Coloca o token no DOM e no histórico do navegador |
| Trocar o `<BrowserRouter>` sem reimplementar a sentinela de histórico | O dirty guard para de interceptar Voltar/Avançar |
| Forçar um "?" em todo card | Produz explicações inventadas — o catálogo é a única fonte |

---

## 26. Inventário de modais do domínio

Todos os diálogos do módulo, incluindo as confirmações nativas. **Destrutivo** = a ação apaga, remove da operação ou descarta trabalho.

| Modal | Arquivo | Aberto por | Tipo | Destrutivo? |
|---|---|---|---|---|
| **Novo Agente** | `src/components/ia/AgentFormDialog.tsx` | Galeria → "Novo Agente"; `AgentSelectorBar` → "Novo Agente" | `Dialog` | Não |
| **Renomear Agente** | `src/components/ia/AgentFormDialog.tsx` | `AgentActionsMenu` → **Renomear** | `Dialog` | Não |
| **Ativar agente?** | `src/components/ia/AgentActionsMenu.tsx` | `AgentActionsMenu` → **Ativar** | `AlertDialog` | Não |
| **Inativar agente?** | `src/components/ia/AgentActionsMenu.tsx` | `AgentActionsMenu` → **Inativar** | `AlertDialog` | Não |
| **Arquivar agente?** | `src/components/ia/AgentActionsMenu.tsx` | `AgentActionsMenu` → **Arquivar** (desabilitado se for o padrão) | `AlertDialog` | **Sim** |
| **Excluir agente** | `src/components/ia/AgentDeleteDialog.tsx` | `AgentActionsMenu` → **Excluir agente** (`owner`/`admin`) | `Dialog` `sm:max-w-lg` + confirmação por slug | **Sim** (lógico/tombstone) |
| **Integração N8N** | `src/pages/AgentWorkspace.tsx` (casca) + `src/components/ia/AgentN8NIntegration.tsx` | Botão no cabeçalho do workspace | `Dialog` `max-w-2xl` | Não (contém ação destrutiva dentro) |
| **Liberar todas as tags para este agente?** | `src/components/ia/AgentAllowedTagsConfig.tsx` | **Salvar** com mudança `restricted → all` | `AlertDialog` | Não (escalada de permissão) |
| **Nova tag de transferencia** | `src/components/ia/TransferTagsConfig.tsx` | "Nova tag" / "Criar primeira tag" | `Dialog` `sm:max-w-md` | Não |
| **Editar tag de transferencia** | `src/components/ia/TransferTagsConfig.tsx` | Ícone `Pencil` da linha | `Dialog` `sm:max-w-md` | Não |
| **Descartar alterações?** (tag) | `src/components/ia/TransferTagsConfig.tsx` | Fechar o form de tag com alterações | `AlertDialog` | **Sim** (descarta trabalho) |
| **Tipo da tag: {label}** | `src/components/ia/TransferTagsConfig.tsx` | Clique no badge "Tipo vigente" | `Dialog` `sm:max-w-md` | Não (muda vigência) |
| **Descartar alteração de tipo?** | `src/components/ia/TransferTagsConfig.tsx` | Fechar a troca de tipo sem aplicar | `AlertDialog` | **Sim** (descarta seleção) |
| **Remover tag de transferencia** | `src/components/ia/TransferTagsConfig.tsx` | Ícone `Trash2` da linha | `AlertDialog` + bloco de impacto | **Sim** |
| **Nova Etapa do Funil** | `src/components/ia/FunnelStagesConfig.tsx` | Botão "Nova Etapa" | `Dialog` | Não |
| **Configurar Etapa: {nome}** | `src/components/ia/FunnelStagesConfig.tsx` | Botão `Settings` da linha | `Dialog` | Não (contém Excluir) |
| **"Tem certeza que deseja excluir esta etapa?"** | `src/components/ia/FunnelStagesConfig.tsx` | Botão **Excluir** do diálogo de edição | **`window.confirm` nativo** | **Sim** |
| **Nova Versão do Agente** | `src/components/ia/VersionManager.tsx` | Botão "Nova Versão" ou menu ⋯ → **Duplicar** | `Dialog` | Não |
| **Restaurar Versão** | `src/components/ia/VersionManager.tsx` | Menu ⋯ de versão arquivada → **Restaurar como Rascunho** | `Dialog` (mesmo componente, modo `restore`) | Não |
| **"Publicar este rascunho?…"** | `src/components/ia/VersionManager.tsx` | Menu ⋯ de rascunho → **Publicar** | **`window.confirm` nativo** | Parcial (arquiva a publicada) |
| **"Tem certeza que deseja excluir esta versão?…"** | `src/components/ia/VersionManager.tsx` | Menu ⋯ → **Excluir** (indisponível na publicada) | **`window.confirm` nativo** | **Sim** |
| **Nova Diretriz / Editar Diretriz** | `src/components/ia/GuidelinesEditor.tsx` | Botão de nova diretriz / editar na lista | `Dialog` `95vw × 95vh` | Não |
| **"Tem certeza que deseja excluir esta diretriz?"** | `src/components/ia/GuidelinesEditor.tsx` | Ação de excluir da diretriz | **`window.confirm` nativo** | **Sim** |
| **Nova Regra de Negócio / Editar Regra** | `src/components/ia/BusinessRulesBuilder.tsx` | Botão de nova regra / editar na lista | `Dialog` `95vw × 95vh` | Não |
| **"Tem certeza que deseja excluir esta regra?"** | `src/components/ia/BusinessRulesBuilder.tsx` | Ação de excluir da regra | **`window.confirm` nativo** | **Sim** |
| **Novo Prompt / Editar Prompt** | `src/components/ia/PromptEditor.tsx` | Botão de novo prompt / editar na lista | `Dialog` `95vw × 95vh` | Não |
| **"Tem certeza que deseja excluir este prompt?"** | `src/components/ia/PromptEditor.tsx` | Ação de excluir (bloqueada para o cenário `general`) | **`window.confirm` nativo** | **Sim** |
| **Configurações do Playground** | `src/components/ia/PlaygroundSettingsDialog.tsx` | Botão de configurações no Playground (papel `owner`) | `Dialog` `95vw`, `max-w-2xl` | Não |
| **Descartar alterações?** (playground) | `src/components/ia/PlaygroundSettingsDialog.tsx` | Fechar as configurações com alterações | `AlertDialog` (`z-[70]`) | **Sim** (descarta trabalho) |
| **Iniciar nova simulação?** | `src/components/ia/AIPlayground.tsx` | Trocar contexto/dados/cenário após enviar mensagens | `AlertDialog` | **Sim** (limpa a conversa de teste) |
| **Conversa: {contato}** (transcrição) | `src/components/ia/ConversationLogs.tsx` | Clique numa linha de `ProtocolConversationList` | `Dialog` `95vw × 95vh` | Não |
| **Conversa** (drill-down) | `src/components/ia/TransferDrilldownPanel.tsx` | Clique numa linha do drawer de drill-down | `Dialog` `90vw × 85vh` | Não |
| **Deletar documento?** | `src/components/agent-ia/RagDocumentList.tsx` | Ícone `Trash2` da linha do documento | `AlertDialog` | **Sim** (permanente de verdade) |
| **Descartar alterações?** (guard global) | `src/pages/AgentWorkspace.tsx` + `src/hooks/useDirtyFormGuard.ts` | Troca de aba/sub-aba/agente, volta à galeria, link SPA, Voltar/Avançar | `AlertDialog` (host único) | **Sim** (descarta trabalho) |
| *(prompt nativo)* **beforeunload** | `src/hooks/useDirtyFormGuard.ts` | Reload, fechar aba ou sair para URL externa com formulário sujo | **Prompt nativo do navegador** | **Sim** |

**Resumo quantitativo:**

| Categoria | Quantidade |
|---|---|
| `Dialog` do design system | 16 |
| `AlertDialog` do design system | 11 |
| `window.confirm` / prompt nativo | 7 |
| **Total de pontos de diálogo** | **34** |
| Destrutivos (apagam, removem da operação ou descartam trabalho) | 17 |
| Destrutivos que **não** usam o design system | 6 |

> **Leitura para o redesenho:** metade dos diálogos do módulo é destrutiva, e **seis deles não passam pelo design system**. Padronizar essas seis é o item de maior retorno por esforço — e não muda nenhuma regra de negócio.

---

*Fim do documento.*
