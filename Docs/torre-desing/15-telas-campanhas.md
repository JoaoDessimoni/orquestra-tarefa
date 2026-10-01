# 15 · Telas de Campanhas e Broadcast

> Documento de inventário funcional exaustivo do frontend **atual** da Torre de Controle (SaaS multi-tenant de cobrança da Finza), domínio **Campanhas e Broadcast**.
> Destinatário: designer encarregado do redesenho. Objetivo: permitir redesenhar a interface **sem perder nenhuma funcionalidade**.
> Tudo aqui foi extraído por leitura direta do código-fonte. Onde o código não permite concluir, há marcação `⚠️ A confirmar:`.
> Repositório: `cobranca-finza/`. Todos os caminhos citados são relativos à raiz desse repositório.

---

## 0. Resumo do domínio

### 0.1 Telas e rotas

| Tela | Rota | Arquivo-fonte | Permissão | Layout |
|---|---|---|---|---|
| Campanhas (hub com 3 abas) | `/campaigns` | `src/pages/CampaignsPage.tsx` | Rota sem `RequirePermission`; item de menu exige `campaigns:read`. Ações de escrita exigem `campaigns:write`; exclusão exige `campaigns:delete`; cancelamento em massa exige `actions:write` | Dentro do `AppLayout` (sidebar + topbar). Página com header, `Tabs` de 3 abas, cartão de filtros, grid/tabela, paginação |
| Editor de Broadcast | `/broadcasts/:id/editor` | `src/pages/BroadcastEditorPage.tsx` | `ProtectedRoute` + `RequireOrg` (sem `RequirePermission` na rota). Edição gated por `broadcasts:write` | **Tela cheia**, FORA do `AppLayout`: `h-screen`, header próprio de 64 px, main com scroll |

Fonte das rotas: `src/App.tsx` (linhas ~24, ~27, ~201-209, ~412). Fonte da permissão de menu: `src/components/layout/Sidebar.tsx` (`{ name: "Campanhas", href: "/campaigns", icon: Target, permission: "campaigns:read" }`).

### 0.2 Abas da tela `/campaigns`

| Aba | `value` | Ícone | Componente que renderiza | O que mostra |
|---|---|---|---|---|
| Campanhas | `campaigns` (default) | `Target` | Inline em `CampaignsPage.tsx` | Filtros + lista (tabela ou cards) + paginação |
| Monitoramento | `monitoring` | `Activity` | `ExecutionMonitoringPanel` | Runs do pipeline v2 de hoje, KPIs agregados, histórico de execuções |
| Repique | `repique` | `Repeat` | `DashboardFiltersBar periodOnly` + `RepiqueTab` | KPIs de repique + tabela de ações com repique |

### 0.3 Componentes do domínio

| Arquivo | Papel |
|---|---|
| `src/components/campaigns/CampaignDialog.tsx` (936 linhas) | Formulário criar/editar campanha |
| `src/components/campaigns/CampaignTypeSelector.tsx` | Seletor recorrente × broadcast (só na criação) |
| `src/components/campaigns/WorkflowMultiSelect.tsx` | Multi-seleção de réguas |
| `src/components/campaigns/WorkflowFilterPreview.tsx` | Prévia de público por régua (broadcast) |
| `src/components/campaigns/RepiquePreview.tsx` | Impacto do repique no público (broadcast) |
| `src/components/campaigns/BroadcastScheduleInput.tsx` | Imediato × agendado (broadcast) |
| `src/components/campaigns/CampaignDetailDialog.tsx` | Detalhe read-only + histórico |
| `src/components/campaigns/CampaignCostBreakdown.tsx` | Custo estimado por canal |
| `src/components/campaigns/CampaignPreviewModal.tsx` (687 linhas) | Modal "Ações previstas" (funil real + estimativa + andamento) |
| `src/components/campaigns/preview/CampaignFunnelReal.tsx` | Funil de elegibilidade (barras) |
| `src/components/campaigns/preview/CampaignActivityMatrix.tsx` | Andamento dos envios (Hoje/Total) |
| `src/components/campaigns/preview/CampaignReasonsDrilldown.tsx` | Motivos por título |
| `src/components/campaigns/CampaignDryRunDialog.tsx` | Ensaio (dry-run) |
| `src/components/campaigns/ExecuteOutsideWindowDialog.tsx` | Confirmação "fora da janela" |
| `src/components/campaigns/ExecutionMonitoringPanel.tsx` (608 linhas) | Aba Monitoramento |
| `src/components/campaigns/execution/PipelineRunStatusCard.tsx` | Cartão de run do pipeline v2 |
| `src/components/campaigns/execution/CampaignExecutionFunnel.tsx` | Funil de execução (lote ou campanha) |
| `src/components/campaigns/execution/CampaignExecutionCandidatesTable.tsx` | Tabela de candidatos |
| `src/components/campaigns/execution/CampaignExecutionRunsList.tsx` | Lista de runs (componente existente, **sem callsite ativo** — ver §18) |
| `src/components/campaigns/CampaignLogDetailDialog.tsx` | Detalhe de uma execução |
| `src/components/campaigns/CancelCampaignActionsDialog.tsx` | Cancelamento em massa de pendentes |
| `src/components/campaigns/RepiqueTab.tsx` | Aba Repique |
| `src/components/campaigns/BroadcastTimelineView.tsx` | Lista de ações do broadcast |
| `src/components/campaigns/BroadcastAddStepDialog.tsx` | Adicionar canal ao broadcast |
| `src/lib/campaigns/campaign-log-funnel.ts` | Derivação pura do funil por campanha |
| `src/lib/constants/campaign-preview-help.ts` | Cópia canônica dos "?" do modal de prévia |
| `src/lib/cost-calculator.ts` | Cálculo de custo por canal |

### 0.4 Hooks que impactam a UI

| Hook | Arquivo | O que entrega para a tela |
|---|---|---|
| `useCampaigns` | `src/hooks/useCampaigns.ts` | Lista paginada (`{campaigns, page, totalPages}`), com busca e filtro de status |
| `useCreateCampaign` / `useUpdateCampaign` / `useDeleteCampaign` | idem | CRUD |
| `useToggleCampaignStatus` | idem | Ativa/pausa + validações de broadcast + disparo automático |
| `useManualExecuteCampaign` | idem | "Executar Agora" / "Forçar Execução" |
| `useCampaignDryRun` | idem | "Ensaiar" |
| `useCampaign` | idem | Campanha + réguas associadas (detalhe) |
| `useCampaignLogs` | idem | Últimas 50 execuções de uma campanha |
| `useAvailableWorkflows` / `useBroadcastWorkflows` | idem | Opções do multi-select de réguas |
| `useWorkflowForPreview` | idem | `assignment_filters` de uma régua |
| `useCampaignPreview` / `useCampaignsPreview` | `src/hooks/useCampaignPreview.ts` | Estimativa ao vivo (contatos, ações, breakdown, janela, data bloqueada) |
| `useCampaignPreviewState` | `src/hooks/useCampaignPreviewState.ts` | Matriz de estado do modal de prévia |
| `useCampaignFunnel` | `src/hooks/useCampaignFunnel.ts` | Funil real (`today` \| `last`) |
| `useCampaignActivity` | `src/hooks/useCampaignActivity.ts` | Andamento dos envios (Hoje/Total, por status) |
| `useCampaignExecutionRuns` / `useCampaignExecutionRun` | `src/hooks/useCampaignExecutionRuns.ts` | Runs do pipeline v2 |
| `useCampaignExecutionCandidates` | `src/hooks/useCampaignExecutionCandidates.ts` | Candidatos + catálogo de disposições |
| `useCampaignsWithRuns` | `src/hooks/useCampaignsWithRuns.ts` | Set de campanhas que já rodaram |
| `useCampaignPendingCounts` / `useCancelCampaignActions` | `src/hooks/useCancelCampaignActions.ts` | Contagem e cancelamento em massa |
| `useRepiqueDashboard` | `src/hooks/useRepiqueActions.ts` | KPIs + lista da aba Repique |
| `useChannelCosts` | `src/hooks/useChannelCosts.ts` | Custo por canal (para estimativas) |
| `useWorkflowNames` | `src/hooks/useWorkflowNames.ts` | Mapa id→nome das réguas (badges do card) |
| `useViewPreference` | `src/hooks/useViewPreference.ts` | Persiste card/list em `localStorage` |
| `useDashboardFilters` | `src/hooks/useDashboardFilters.ts` | Período da aba Repique |

---

## 1. Objetivo e personas

### 1.1 O que a tela resolve

A régua (`workflow`) define **o que** é enviado e em que dia de atraso. A campanha define **quando** essa régua vai para a rua: em que horário, em que dias da semana, com que velocidade e por qual gatilho. **Sem campanha ativa, a régua não dispara nada.**

Citação do próprio guia de negócio do app (`src/pages/central-docs/negocio/data/campanhas.ts`):

> "O centro de controle do disparo das réguas de cobrança. É aqui que você decide quando e com que velocidade as réguas saem para a rua: cria campanhas, liga e desliga, agenda, dispara na hora, acompanha as execuções em tempo real, cancela em massa a fila que ainda não saiu e revisa os repiques."

Subtítulo literal da página: **"Controle o disparo das Réguas de Cobrança"**.

### 1.2 Personas

| Persona | Perfil RBAC típico | O que faz nesta tela |
|---|---|---|
| **Gestor de cobrança / supervisor** | `owner`, `admin`, `manager` | Cria e configura campanhas, define janela e velocidade, ativa/pausa, avalia custo antes de disparar, ensaia |
| **Operador de cobrança** | `operator` | Acompanha Monitoramento, dispara manualmente quando autorizado, cancela fila errada (se tiver `actions:write`) |
| **Analista / auditoria** | `viewer` | Só leitura: lista, detalhe, modal de prévia, monitoramento. Não vê botões de escrita |
| **Plantonista de incidente** | qualquer com `actions:write` | Usa "Cancelar ações pendentes" quando uma campanha disparou errado e a fila ainda não escoou |

O guia de negócio declara `permissions: ["owner", "admin", "manager", "operator", "viewer"]` para `/campaigns` e `["owner", "admin", "manager"]` para o editor de broadcast.

### 1.3 Momentos de uso

1. **Planejamento** — antes de ativar: olhar contatos elegíveis, ações estimadas e custo estimado no rodapé do card.
2. **Validação** — "Ensaiar (não cria ações)": roda os 5 primeiros passos do pipeline e mostra quem entraria e quem sairia, sem criar nada.
3. **Disparo** — ativar (agendado) ou "Executar Agora" (manual).
4. **Acompanhamento** — aba Monitoramento: run em andamento, travado, falho.
5. **Reconciliação** — modal "Ações previstas": o funil real bate 1:1 com a tela de Ações.
6. **Freio de emergência** — cancelar em massa as ações Pendentes de uma campanha.

---

## 2. Modelo mental

Esta seção existe para o designer entender o vocabulário exibido na tela. Os conceitos abaixo aparecem literalmente em rótulos, badges, tooltips e textos de ajuda.

### 2.1 Campanha

Registro em `{org}.campaigns`. Tipo TypeScript: `Campaign` em `src/hooks/useCampaigns.ts`.

Campos que a UI lê ou escreve:

| Campo | Tipo | Onde aparece na UI |
|---|---|---|
| `id` | uuid | Chaves, deep links, `?campaign=` do editor de broadcast |
| `name` | string | Título do card/linha, headers dos modais |
| `description` | string \| null | Subtítulo do card (`line-clamp-2`) / segunda linha da tabela (`truncate max-w-[200px]`) |
| `status` | `draft \| active \| paused \| completed \| cancelled` | Badge de status, switch "Ativo" |
| `campaign_type` | `recurring \| broadcast` | Badge "Campanha"/"Broadcast", ícone `Megaphone` |
| `producer_trigger_type` | `scheduled \| manual \| on_pipeline_complete` | Badge de Trigger, seção "Geração de Ações" |
| `trigger_type` (legado, deprecated) | `scheduled \| manual \| webhook` | Fallback do badge de Trigger; usado no histórico (`campaign_logs.trigger_type`) |
| `producer_cron_expression` | string \| null | Presets + input CRON + tradução em linguagem natural |
| `producer_pipeline_id` | uuid \| null | Select "Pipeline de ETL" |
| `target_reguas` | string[] | Badges de régua no card; multi-select no formulário; `target_reguas[0]` vira a rota do editor de broadcast |
| `start_time` / `end_time` | `HH:MM:SS` | "08:00 - 20:00" no card; inputs `type=time` no formulário |
| `active_days` | number[] (0=Dom … 6=Sáb) | "Seg - Sex" / "Todos os dias" no card; botões de dia no formulário |
| `timezone` | string | Não editável na UI; default `America/Sao_Paulo`; usado no cálculo de janela |
| `actions_per_minute` | number (1-100) | "10 ações/min" no card; slider no formulário |
| `contact_cooldown_hours` | number (-1 … 168) | ToggleGroup "Cooldown Anti-Spam" |
| `scheduled_at` | ISO \| null | "Agendado: dd/mm/aa hh:mm" ou "Disparo imediato" no card; badge no header do editor |
| `processed` | boolean | Alimenta o `BroadcastStatusIndicator` |
| `broadcast_filter_ids` / `broadcast_filter_id` / `broadcast_filter_logic` | string[] / string / `AND \| OR` | Linha "N filtros" + badge "E"/"OU" no card |
| `settings.repique_enabled` | boolean | Switch "Repique" (broadcast) |
| `use_pipeline_v2` | boolean | **Não tem UI própria.** Decide se "Ensaiar" aparece e qual executor é chamado. Toda campanha criada hoje nasce `true` |
| `last_manual_execution_at` | ISO \| null | "Última execução manual" no detalhe |
| `created_at` / `updated_at` | ISO | "Criado em" / "Última atualização" no detalhe |

Campos do tipo que **não** têm superfície visual hoje: `start_date`, `end_date`, `total_contacts`, `contacted_count`, `success_count`.

### 2.2 Tipo de campanha

| Tipo | Rótulo na UI | Descrição exibida | Motor |
|---|---|---|---|
| `recurring` | **Régua de Cobrança** (seletor) / **Campanha** (badge) | "Dispara automaticamente baseado em dias de atraso do título" | `campaign-pipeline-orchestrator` (v2) ou `campaign-executor` (v1, legado) |
| `broadcast` | **Disparo Pontual** (seletor) / **Broadcast** (badge) | "Dispara uma única vez para um público selecionado" | `broadcast-processor` |

O tipo **não pode ser trocado depois de criado**: o `CampaignTypeSelector` só é renderizado quando `!isEditing`.

### 2.3 Gatilho (trigger)

`PRODUCER_TRIGGER_TYPES` em `src/hooks/useCampaigns.ts`:

| Valor | Rótulo | Descrição (exibida como `FormDescription`) | Ícone no formulário | Ícone na lista |
|---|---|---|---|---|
| `scheduled` | **Agendado (CRON)** | "Gera ações automaticamente no horário configurado" | `Clock` | `Clock` |
| `manual` | **Manual** | "Gera ações apenas quando disparado manualmente" | `Play` | `Play` |
| `on_pipeline_complete` | **Após Pipeline ETL** | "Gera ações automaticamente após a conclusão de um pipeline de importação" | `Database` | `Database` |

`TRIGGER_TYPES` (legado, ainda usado para rotular `campaign_logs.trigger_type` no Monitoramento e no Histórico):

| Valor | Rótulo | Descrição |
|---|---|---|
| `scheduled` | Agendado | "Executa automaticamente nos horários e dias configurados" |
| `manual` | Manual | "Executa apenas quando disparado manualmente pelo usuário" |
| `webhook` | Webhook | "Executa quando recebe uma chamada de API externa" (ícone `Zap`) |

Para broadcast, o formulário **força** `producer_trigger_type = "manual"` no submit, independentemente do que estiver no estado.

### 2.4 Régua vinculada (workflow)

- Campanha recorrente consome réguas **sequenciais** (`workflow_type = 'sequential'` ou `null`).
- Broadcast consome réguas **pontuais** (`workflow_type = 'broadcast'`).
- A relação é N:N pelo array `target_reguas`.
- O multi-select mostra, por régua: nome, contagem de passos (`{n} ações`), ícone (`GitBranch` sequencial / `Megaphone` broadcast) e status ativo/inativo (`CheckCircle2` verde / `XCircle` muted).
- Régua inativa **aparece** na lista (o formulário passa `filterByStatus={false}`) e, se selecionada, dispara o aviso: "Algumas réguas selecionadas estão inativas e não serão executadas."

### 2.5 Carteira / público-alvo

O público não é definido na campanha: vem dos `assignment_filters` de cada régua (`{ portfolios: string[], filter_ids: string[], aggregation_logic: 'AND' | 'OR' }`). O `WorkflowFilterPreview` resolve isso e mostra contatos, contratos e dívida total.

### 2.6 Execução: run, log e lote

Três entidades distintas — e a UI já foi corrigida (IAF-6990) justamente por confundi-las:

| Entidade | Tabela | Granularidade | Onde aparece |
|---|---|---|---|
| **Run (lote)** | `campaign_execution_runs` | **1 linha por LOTE de N campanhas** | `PipelineRunStatusCard` (Pipeline v2 — Hoje), faixa "Execução em lote" do `CampaignLogDetailDialog`, métricas do `CampaignDryRunDialog` |
| **Log (campanha)** | `campaign_logs` | **1 linha por campanha por execução** | Tabela "Histórico de Execuções", `CampaignDetailDialog` → aba Histórico, funil real do modal de prévia |
| **Candidato** | `campaign_execution_candidates` | 1 linha por (contato × título × step) | `CampaignExecutionCandidatesTable`, `CampaignReasonsDrilldown` |

Consequências visuais que o redesign precisa preservar:

- **"Títulos avaliados" e "Duração" só existem no nível do LOTE.** No funil da campanha a barra "Títulos" não é renderizada, e a duração fica na faixa recolhível "Ver números do lote", rotulada **"Duração do lote"**.
- **Candidatos têm retenção de 48 h** (cron `cleanup_exec_candidates`). A tabela vazia mostra a nota: "O detalhamento por candidato fica disponível por 48h após a execução."
- Os números do funil vêm de `campaign_logs`, que é durável — funcionam para qualquer execução do histórico.

Campos de `CampaignExecutionRun` usados pela UI: `current_step`, `campaign_ids[]`, `total_eligible_contacts`, `total_titles_fetched`, `total_matches`, `matches_after_integration_dedup`, `matches_after_rules`, `matches_after_cross_dedup`, `actions_created`, `skipped_blocklist`, `skipped_cooldown`, `skipped_same_step`, `skipped_higher_priority`, `skipped_cross_campaign`, `heartbeat_at`, `started_at`, `completed_at`, `error_details`, `retry_count`, `is_dry_run`, `execution_date`.

Campos de `CampaignLog` usados pela UI: `status`, `trigger_type`, `contacts_processed`, `actions_created`, `errors_count`, `skipped_duplicates`, `skipped_cooldown`, `skipped_blocklist`, `skipped_already_contacted`, `skipped_cross_integration`, `skipped_higher_priority`, `deferred_actions_created/promoted/cancelled`, `metadata` (contém `run_id` e os 6 contadores novos), `error_details`, `started_at`, `completed_at`, `campaigns { id, name, campaign_type }`.

### 2.7 Pipeline de 6 passos

Constante `PIPELINE_STEPS` em `PipelineRunStatusCard.tsx` — é o que a trilha de progresso desenha:

| # | `key` | Rótulo curto na trilha | Rótulo longo (`CampaignExecutionRunsList`) |
|---|---|---|---|
| 1 | `resolve_contacts` | **Resolver** | Resolvendo contatos |
| 2 | `fetch_titles` | **Buscar** | Buscando titulos |
| 3 | `match_titles` | **Match** | Matching |
| 4 | `apply_rules` | **Regras** | Aplicando regras |
| 5 | `cross_dedup` | **Dedup** | Cross-dedup |
| 6 | `create_actions` | **Criar** | Criando acoes |

Estados adicionais de `current_step` reconhecidos: `plan` ("Planejando"), `completed` ("Concluido"), `failed` ("Falhou"). O tooltip de cada bolinha da trilha mostra a **chave técnica** (ex.: `match_titles`).

### 2.8 Disposição (disposition)

Estado de um candidato ao longo do pipeline. É o vocabulário dos **motivos de exclusão** exibidos no drill-down e no detalhamento de execução. Catálogo completo na **§9**.

### 2.9 Ensaio (dry-run)

Execução dos passos 1-5 do pipeline v2 que **para antes** de `create_actions`. Cria uma linha real em `campaign_execution_runs` com `is_dry_run = true`. Três garantias que a UI comunica textualmente (`DRY_RUN_GUARANTEES`):

1. **Nenhuma ação é criada.**
2. **Não consome a execução do dia** (o agendador ignora ensaios nas duas travas anti-duplicação).
3. **Não mexe no card "Ações previstas"** (aquele funil lê `campaign_logs`, que só `create_actions` escreve).

Disponível apenas quando `campaignSupportsDryRun(campaign)` = `campaign_type !== 'broadcast' && use_pipeline_v2 === true`.

---

## 3. Tela `/campaigns` — anatomia visual

Fonte: `src/pages/CampaignsPage.tsx`.

### 3.1 Container

```
<div className="space-y-4 sm:space-y-6">
```

Tudo dentro do `AppLayout` (sidebar + conteúdo). Espaçamento vertical menor no mobile.

### 3.2 Header da página

```
flex items-center justify-between gap-3
├── div.min-w-0
│   ├── h1  "Campanhas"                 text-xl sm:text-2xl font-bold tracking-tight
│   └── p   "Controle o disparo das Réguas de Cobrança"
│           text-muted-foreground text-sm  hidden sm:block   ← some no mobile
└── div.flex.gap-2.shrink-0
    ├── <RefreshButton onRefresh={refetch} isFetching={isFetching} />
    └── <Button size="icon" className="sm:w-auto sm:px-4">     ← só se canWrite
          <Plus /> <span className="hidden sm:inline">Nova</span>
```

Comportamento responsivo do botão "Nova": no mobile é um botão quadrado só com o `+`; a partir de `sm` vira botão com rótulo.

### 3.3 Barra de abas

```
<Tabs defaultValue="campaigns" className="space-y-4 sm:space-y-6">
  <TabsList>
    <TabsTrigger value="campaigns">  <Target />   Campanhas
    <TabsTrigger value="monitoring"> <Activity /> Monitoramento
    <TabsTrigger value="repique">    <Repeat />   Repique
```

Cada trigger é `flex items-center gap-2`, ícone `h-4 w-4`. A aba **não** está sincronizada com a URL (`⚠️ A confirmar:` se o redesign deve introduzir deep-link por aba — hoje recarregar a página volta para "Campanhas").

### 3.4 Aba Campanhas — estrutura

```
TabsContent value="campaigns"  (space-y-4 sm:space-y-6, mt-0)
├── Card de filtros
│   └── CardContent pt-4 sm:pt-6
│       └── flex flex-col sm:flex-row gap-3 sm:gap-4
│           ├── div.relative.flex-1        → ícone Search absoluto + Input pl-9
│           └── div.flex.gap-2
│               ├── Select de status       w-full sm:w-[180px]
│               └── <ViewToggle />
├── Corpo condicional (loading | erro | vazio | lista | grade)
└── Paginação (só se totalPages > 1)
```

### 3.5 Aba Monitoramento

`<TabsContent value="monitoring" className="mt-0"><ExecutionMonitoringPanel /></TabsContent>` — ver §8.

### 3.6 Aba Repique

```
<TabsContent value="repique" className="mt-0 space-y-4">
  <DashboardFiltersBar periodOnly />
  <RepiqueTab filters={repiqueFilters} />
```

O `DashboardFiltersBar periodOnly` expõe apenas o seletor de período (today / 7d / 30d / this_month / last_month / 12m / custom / all). Ver §11.

### 3.7 Modais montados no fim da página

Sempre montados (controlados por estado), na ordem:

1. `<CampaignDialog open={dialogOpen} campaign={editingCampaign} />`
2. `<CampaignDetailDialog campaign={viewingCampaign} />`
3. `<CampaignPreviewModal campaign={previewCampaign} open={!!previewCampaign} />`
4. `<CampaignDryRunDialog key={dryRunCampaign?.id ?? "closed"} campaign={dryRunCampaign} />`
5. `<ExecuteOutsideWindowDialog open={!!pendingExecution} campaign={pendingExecution} />`

O `key` do dry-run garante estado limpo ao ensaiar outra campanha.

---

## 4. Lista de campanhas

### 4.1 Filtros e busca

| Controle | Tipo | Valor default | Opções | Efeito |
|---|---|---|---|---|
| **Buscar campanhas...** | `Input` com ícone `Search` à esquerda (`absolute left-3`, input `pl-9`) | `""` | — | Filtro server-side em `name` e `description` (`searchFields` do `createCrudHooks`) |
| **Status** | `Select` (`placeholder="Status"`) | `all` | `all` "Todos os status", `draft` "Rascunho", `active` "Ativa", `paused` "Pausada", `completed` "Concluída" | Filtro server-side `eq("status", …)` |
| **Alternar visualização** | `ViewToggle` (dois botões ghost, `LayoutGrid` e `List`) | `card` | `card` \| `list` | Persistido em `localStorage["view-preference-campaigns"]` |

Observações importantes:

- `cancelled` **não aparece** no filtro de status, embora seja um status válido de `Campaign` e tenha badge em `CAMPAIGN_STATUS`. (Oportunidade de redesign — §17.)
- Trocar busca ou status **reseta a página para 1** (`useEffect` em `[search, statusFilter]`).
- O `applyFilters` do hook **sempre** esconde a campanha de nome literal `"Teste Integracao"` (`query.neq("name", "Teste Integracao")`) — filtro invisível ao usuário.
- Ordenação fixa: `created_at` descendente. **Não há controle de ordenação na UI.**
- Os títulos dos botões do `ViewToggle` são `"Visualização em cards"` e `"Visualização em lista"`.

### 4.2 Visão LISTA (tabela)

`<div className="rounded-md border"><Table>`

| # | Coluna (`TableHead`) | Largura | Conteúdo |
|---|---|---|---|
| 1 | **Tipo** | auto | `Badge variant="outline"` com ícone: `Megaphone` + "Broadcast" ou `Target` + "Campanha" |
| 2 | **Nome** | auto | `flex flex-col`: nome em `font-medium`; descrição em `text-xs text-muted-foreground truncate max-w-[200px]` (só se existir) |
| 3 | **Status** | auto | `Badge` com a cor de `CAMPAIGN_STATUS[status]` |
| 4 | **Trigger** | auto | `Badge variant="outline"` com ícone do trigger + rótulo (`PRODUCER_TRIGGER_TYPES[…].label`, fallback `TRIGGER_TYPES`, fallback literal "Agendado") |
| 5 | **Ativo** | `w-[60px]` | `Switch` (checked = status `active`), **ou** um traço `-` se `status === 'completed'` |
| 6 | (sem cabeçalho) | `w-[70px]` | Botão `MoreHorizontal` que abre o `DropdownMenu` |

Comportamentos da linha:

- `className="cursor-pointer hover:bg-muted/50"`.
- **Clique na linha**: se `status === 'completed'` → abre `CampaignDetailDialog`; caso contrário → abre `CampaignDialog` em modo edição. (Regra em `handleCampaignClick`.)
- As células 5 e 6 têm `onClick={(e) => e.stopPropagation()}` para não disparar o clique da linha.
- O `Switch` fica `disabled` quando `toggleStatus.isPending || !canWrite`.

**Menu de ações na visão LISTA** (`DropdownMenuContent align="end"`) — repare que é **menor** que o da visão em grade:

| Item | Ícone | Condição | Ação |
|---|---|---|---|
| Visualizar | `Eye` | sempre | `setViewingCampaign(campaign)` |
| Editar | `Edit` | `canWrite` | abre `CampaignDialog` |
| Pausar / Ativar | `Pause` / `Play` | `canWrite && status !== 'completed'` | `handleToggleStatus` |
| — separador — | | `canDelete` | |
| Excluir | `Trash2` (texto `text-destructive`) | `canDelete` | `confirm()` nativo + `deleteCampaign` |

**Faltam na visão lista** (existem só na visão grade): "Configurar Ações", "Executar Agora", "Ensaiar (não cria ações)". É uma inconsistência real do código — ver §17.

### 4.3 Visão GRADE (cards)

`<div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">` — 1 coluna no mobile, 2 em `md`, 3 em `lg`.

Cada card: `<Card className="hover:shadow-md transition-shadow cursor-pointer">` com o mesmo `handleCampaignClick`.

#### 4.3.1 `CardHeader` (pb-2)

```
flex items-start justify-between
├── div.space-y-1.flex-1.min-w-0
│   ├── flex items-center gap-2
│   │   ├── <Megaphone className="h-4 w-4 text-primary shrink-0" />   ← só broadcast
│   │   └── <CardTitle className="text-lg truncate">{name}</CardTitle>
│   └── <CardDescription className="line-clamp-2">{description}</CardDescription>
└── botão MoreHorizontal (dentro de div com stopPropagation em onClick e onPointerDown)
```

#### 4.3.2 `CardContent` — bloco de badges

```
flex items-center justify-between
├── flex items-center gap-2 flex-wrap
│   ├── Badge de status (cor de CAMPAIGN_STATUS)
│   ├── Badge de tipo:
│   │     broadcast → outline + bg-primary/5 border-primary/30, Megaphone, "Broadcast"
│   │     recurring → outline, ícone do trigger, rótulo do trigger
│   └── <BroadcastStatusIndicator />   ← só broadcast
└── <Switch> (só se status !== 'completed', com stopPropagation)
```

#### 4.3.3 `BroadcastStatusIndicator` — o indicador de processamento do broadcast

Componente inline em `CampaignsPage.tsx`. Só renderiza quando `campaign.status === 'active'`; caso contrário retorna `null`.

| Condição | Badge | Cores |
|---|---|---|
| `processed === true` | `CheckCircle2` + **"Concluído"** | `bg-green-100 text-green-700 border-green-200` |
| `scheduled_at` no futuro | `Timer` + **"Aguardando"** | `bg-amber-100 text-amber-700 border-amber-200` |
| ativo e `!processed` | `Timer` + **"Aguardando disparo"** | `bg-amber-100 text-amber-700 border-amber-200` |

Comentário no código explica por que o rótulo mudou: o antigo **"Em execução"** escondeu por ~48 dias um cron morto do `broadcast-processor` — o time criava a campanha "Ativa", via "Em execução" e concluía que estava disparando, quando nada havia sido acionado. **Esse rótulo é semanticamente carregado; não trocar por algo mais "otimista" no redesign.**

#### 4.3.4 `CardContent` — bloco de metadados (`space-y-2 text-sm`)

Cada linha é `flex items-center gap-2 text-muted-foreground`, com ícone `h-4 w-4`:

| Linha | Ícone | Condição | Conteúdo |
|---|---|---|---|
| Agendamento (broadcast) | `Calendar` | broadcast com `scheduled_at` | `Agendado: dd/mm/aa hh:mm` (pt-BR, 2 dígitos em tudo, ano com 2 dígitos) |
| Disparo imediato (broadcast) | `Zap` | broadcast sem `scheduled_at` | "Disparo imediato" |
| Janela horária (recurring) | `Clock` | recorrente | `{start_time} - {end_time}` (só `HH:MM`; `-` quando nulo) |
| Dias (recurring) | `Calendar` | recorrente | `formatDays(active_days)` → "Nenhum dia" \| "Todos os dias" \| "Seg - Sex" \| lista "Dom, Seg, Ter…" |
| Filtros (broadcast) | `Filter` | broadcast com `broadcast_filter_ids?.length` ou `broadcast_filter_id` | `"N filtro(s)"` + badge `E`/`OU` quando `>1` filtro e há `broadcast_filter_logic` |
| Réguas | `GitBranch` (shrink-0) | `target_reguas.length > 0` | `flex flex-wrap gap-1` com um `Badge variant="outline" text-xs font-normal` por régua; nome vem de `useWorkflowNames`; **placeholder `"..."` enquanto carrega** |
| Velocidade | `Gauge` | sempre | `{actions_per_minute ?? 10} ações/min` |

Regra de `formatDays` (também usada no `CampaignDetailDialog` com rótulos longos):

- `[]` ou nulo → "Nenhum dia"
- 7 dias → "Todos os dias"
- exatamente 5 dias sem 0 e sem 6 → "Seg - Sex"
- caso geral → dias ordenados, abreviados, separados por vírgula

#### 4.3.5 Rodapé do card — prévia (`CampaignPreviewBadgeInline`)

Renderizado quando `!isBroadcast && target_reguas.length > 0`, dentro de `<div className="pt-2 border-t mt-2">`.

O componente retorna `null` para broadcast ou campanha sem régua. Estado de carregamento: `Loader2` girando + **"Carregando prévia..."**.

Conteúdo quando carregado:

```
flex flex-col gap-2
├── flex flex-wrap items-center justify-between gap-2
│   ├── flex flex-wrap items-center gap-2 text-xs text-muted-foreground
│   │   ├── <Users/> "{total} contatos elegíveis"
│   │   ├── "|"  +  "~{totalActions} estimadas"  + HelpTip        ← só se totalActions > 0
│   │   └── "|"  +  <DollarSign emerald/>  "~{R$ x,xx}"           ← só se custo > 0
│   └── <Button variant="outline" size="sm" data-testid="open-campaign-preview">
│         <BarChart3/> Ver ações previstas <ChevronRight/>
└── aviso fora da janela (condicional)
```

Detalhes:

- Números formatados com `toLocaleString("pt-BR")`.
- Custo em `font-mono font-medium text-emerald-600`, prefixado por `~`.
- O `HelpTip` de "Ações estimadas" tem corpo literal:
  > "Estimativa ao vivo do que a régua casaria agora. NÃO desconta cooldown, prioridade nem deduplicação entre campanhas — por isso é sempre maior ou igual ao que é de fato disparado. O número real, já tratado, aparece em 'Ver ações previstas'."
- Aviso fora da janela (quando `preview.isOutsideWindow && preview.nextValidSlot`): `flex items-center gap-1.5 text-xs text-amber-600 dark:text-amber-500` com `Timer` + **"Fora da janela - próx: {dia abreviado} {hh:mm}"**.
- O botão "Ver ações previstas" chama `e.stopPropagation()` antes de abrir o modal.

#### 4.3.6 Rodapé alternativo — campanha MANUAL sem régua que já rodou

Quando `!isBroadcast && !target_reguas?.length && (producer_trigger_type === 'manual' || trigger_type === 'manual') && campaignsWithRuns.has(id)`:

Renderiza **apenas** o botão "Ver ações previstas" (mesmo `data-testid`), sem estimativa nem custo — porque nesses casos o modal mostra só o funil real.

#### 4.3.7 Menu de ações na visão GRADE (completo)

| Ordem | Item | Ícone | Condição |
|---|---|---|---|
| 1 | **Visualizar** | `Eye` | sempre |
| 2 | **Configurar Ações** | `Settings` | `canWrite && isBroadcast && target_reguas[0]` → navega para `/broadcasts/{target_reguas[0]}/editor?campaign={id}` |
| 3 | **Editar** | `Edit` | `canWrite` |
| 4 | **Executar Agora** | `Rocket` (ou `Loader2` girando) | `canWrite && (producer_trigger_type === 'manual' \|\| trigger_type === 'manual') && status === 'active'`. Rótulo muda para **"Executando..."** e fica `disabled` enquanto `manualExecute.isPending` |
| 5 | **Ensaiar (não cria ações)** | `FlaskConical` | `canWrite && campaignSupportsDryRun(campaign)` |
| 6 | **Pausar / Ativar** | `Pause` / `Play` | `canWrite && status !== 'completed'` |
| — | separador | | `canDelete` |
| 7 | **Excluir** | `Trash2`, `text-destructive` | `canDelete` |

Comentário relevante no código sobre o item 5: o ensaio fica ao lado do disparo manual **de propósito** — é a alternativa segura a ele —, mas **não herda** os gates de trigger/status: ensaiar campanha agendada ou pausada é justamente o caso de uso.

### 4.4 Paginação

```
flex justify-center gap-2     ← só se data.totalPages > 1
├── <Button variant="outline" size="sm" disabled={page <= 1}>Anterior</Button>
├── <span className="flex items-center px-3 text-sm text-muted-foreground">
│     Página {data.page} de {data.totalPages}
└── <Button variant="outline" size="sm" disabled={page >= totalPages}>Próxima</Button>
```

Ambos os botões fazem `window.scrollTo({ top: 0, behavior: "smooth" })`. Não há seletor de itens por página (o page size é o default do `createCrudHooks`).

### 4.5 Ações destrutivas e confirmações da lista

| Ação | Confirmação | Texto |
|---|---|---|
| Excluir campanha | `window.confirm()` **nativo do browser** | "Tem certeza que deseja excluir esta campanha?" |
| Executar Agora (fora da janela) | `ExecuteOutsideWindowDialog` | ver §13.5 |
| Ativar/Pausar | **sem confirmação** | toasts de resultado |

O `confirm()` nativo é uma inconsistência com o resto do produto, que usa `AlertDialog` — ver §17.

### 4.6 Toasts disparados a partir da lista

| Gatilho | Título | Descrição | Variante |
|---|---|---|---|
| Execução manual OK | "Execução iniciada" | `A campanha "{nome}" foi disparada manualmente.` | default |
| Execução manual falhou (catch da página) | "Erro" | "Não foi possível executar a campanha." | destructive |
| Broadcast manual OK (hook) | "Broadcast disparado!" | "O processamento foi iniciado. Confira os logs no painel de Monitoramento." | default |
| Campanha v1/v2 OK (hook) | "Campanha executada com sucesso!" | `{N} contatos processados, {M} ações criadas.` (+ `({k} duplicata(s) ignorada(s))` se houver) | default |
| Erro na execução (hook) | "Erro ao executar campanha" | mensagem do erro ou "Ocorreu um erro inesperado" | destructive |
| Ativar campanha | "Campanha ativada" | "A campanha foi ativada com sucesso." | default |
| Pausar campanha | "Campanha pausada" | "A campanha foi pausada." | default |
| Ativar broadcast manual OK | "Broadcast ativado e disparado!" | "A campanha foi ativada e o processamento foi iniciado automaticamente." | default |
| Ativar broadcast, disparo falhou | "Campanha ativada, mas o disparo falhou" | `{erro}. Use "Executar Agora" no menu da campanha para tentar novamente.` | destructive |
| Erro ao alternar status | "Erro ao alterar status" | mensagem do erro | destructive |

Validações de ativação de broadcast que viram toast destrutivo (lançadas por `useToggleCampaignStatus`):

- "O broadcast não possui réguas associadas."
- `A régua "{nome}" não possui filtros de contatos configurados.`
- `A régua "{nome}" não possui ações configuradas.`
- `A régua "{nome}" possui ações sem configuração completa.`

A checagem de "configuração completa" considera passo incompleto quando: `config` nulo; ou, para os tipos `send_whatsapp | send_email | send_sms | send_voice | webhook`, falta `integration_id` ou faltam ambos `message` e `template`.

---

## 5. Formulário de campanha (`CampaignDialog`)

Fonte: `src/components/campaigns/CampaignDialog.tsx` (993 linhas). Componentes-filhos: `CampaignTypeSelector.tsx`, `WorkflowMultiSelect.tsx`, `WorkflowFilterPreview.tsx`, `RepiquePreview.tsx`, `BroadcastScheduleInput.tsx`. Constantes: `src/lib/constants/days-of-week.ts`, `src/lib/cron-translator.ts`, `src/hooks/useCampaigns.ts`.

### 5.1 Contêiner e cabeçalho

```
<Dialog>
  <DialogContent className="w-[95vw] max-w-2xl h-[90vh] overflow-hidden flex flex-col">
    <DialogHeader>
      <DialogTitle>
        <div className="p-2 rounded-lg bg-primary/10 text-primary"><Target className="h-5 w-5" /></div>
        {isEditing ? "Editar Campanha" : "Nova Campanha"}
      <DialogDescription>
        {isEditing ? "Atualize as configurações da campanha"
                   : "Configure uma campanha para disparar comunicações"}
    <DialogBody className="flex-1 overflow-y-auto">
      <form id="campaign-form" className="space-y-6"> … 5 seções …
    <DialogFooter>  [Cancelar]  [Criar Campanha | Salvar Alterações]
```

Características fixas:

- Modal **alto e estreito**: 95% da largura da viewport, teto de `max-w-2xl` (672 px), altura fixa de 90 vh.
- **Só o corpo rola.** Header e footer são `shrink-0` de fato (o `DialogBody` é `flex-1 overflow-y-auto`).
- Não existe indicador de progresso, stepper nem sumário lateral — é um formulário longo de rolagem única, dividido por `<Separator />`.
- O modo (criar × editar) é decidido por `isEditing = !!campaign?.id`.

### 5.2 Mapa das seções

| # | Marcação no código | Título visível | Ícone do título | Visível quando |
|---|---|---|---|---|
| A | `SECTION A: Tipo de Campanha` | "Tipo de Campanha" (só `FormLabel`) | — | **só na criação** (`!isEditing`) |
| B | `SECTION B: Dados Básicos` | sem cabeçalho de grupo | — | sempre |
| B.2 | `SECTION B.2: Prévia do Disparo` | **"Público-Alvo"** | `Users` | `isBroadcast && target_reguas.length > 0` |
| C | `SECTION C: Status e Agendamento` | **"Status e Disparo"** | `Clock` | sempre |
| C.2 | (bloco interno) | **"Janela de Atendimento"** | `Calendar` | sempre (texto muda por tipo) |
| D | `SECTION D: Controle de Volumetria` | **"Configurações de Batching e Anti-Spam"** | `Gauge` | sempre |
| E | `SECTION E: Configurações Avançadas` | **"Geração de Ações (Producer)"** | `Settings2` | **só recorrente** (`!isBroadcast`) |

Os títulos de grupo são `flex items-center gap-2` + `<h3 className="font-medium">`, com ícone `h-4 w-4 text-muted-foreground`.

### 5.3 Inventário completo de campos

Schema Zod: `campaignSchema` (linhas 78-104). Tipo do formulário: `CampaignFormData`.

| Campo (form) | Rótulo visível | Controle | Obrigatório | Validação | Default (criação) | Visível quando |
|---|---|---|---|---|---|---|
| `campaign_type` | **Tipo de Campanha** | `CampaignTypeSelector` (2 cards radio) | sim | enum `recurring \| broadcast` | `recurring` | só criação |
| `name` | **Nome** | `Input` (`placeholder="Nome da campanha"`) | **sim** | `z.string().min(1, "Nome é obrigatório")` | `""` | sempre |
| `description` | **Descrição** | `Textarea` (`placeholder="Descrição da campanha"`) | não | `z.string()` (aceita vazio) | `""` | sempre |
| `target_reguas` | **Réguas de Cobrança** / **Réguas de Broadcast** | `WorkflowMultiSelect` | **sim (na prática)** | Zod aceita `[]`; o `onSubmit` barra com toast | `[]` | sempre |
| `status` | **Campanha Ativa** | `Switch` dentro de cartão bordado | sim | enum de 5 valores | `draft` | sempre |
| `schedule_type` | **Quando Disparar** | `BroadcastScheduleInput` (2 cards radio) | sim | enum `immediate \| scheduled` | `immediate` | só broadcast |
| `scheduled_at` | **Data e Hora do Disparo** | `Input type="datetime-local"` | não (Zod) | `min = agora + 5 min` (atributo HTML) | `null` | broadcast + `schedule_type === "scheduled"` |
| `start_time` | **Horário de Início** | `Input type="time"` | sim | `z.string()` | `08:00` | sempre |
| `end_time` | **Horário de Fim** | `Input type="time"` | sim | `z.string()` | `20:00` (recorrente) / `18:00` (broadcast) | sempre |
| `active_days` | **Dias da Semana** | 7 botões toggle (`Button` `min-w-[60px]`) | sim | `z.array(z.number())` — **aceita vazio** | `[1,2,3,4,5]` (rec.) / `[1,2,3,4,5,6]` (broad.) | sempre |
| `actions_per_minute` | **Ações por Minuto** | `Slider` 1→100, passo 1 | sim | `.min(1).max(100)` | `10` | sempre |
| `contact_cooldown_hours` | **Cooldown Anti-Spam** | `ToggleGroup` 3 modos + `Slider` 1→168 + 5 atalhos | sim | `.min(-1).max(168)` | `24` | sempre |
| `repique_enabled` | **Repique** | `Switch` dentro de cartão bordado | sim (bool) | `z.boolean()` | `false` | só broadcast |
| `producer_trigger_type` | **Tipo de Gatilho** | 3 cards-botão em `grid-cols-3` | sim | enum de 3 | `scheduled` | só recorrente |
| `producer_pipeline_id` | **Pipeline de ETL** | `Select` | condicional | Zod opcional; `onSubmit` barra com toast | `null` | recorrente + `producer_trigger_type === "on_pipeline_complete"` |
| `producer_cron_expression` | **Agendamento** | 7 botões preset + `Input` mono | não (Zod) | sem validação de sintaxe | `"0 0 * * *"` | recorrente + `producer_trigger_type === "scheduled"` |
| `broadcast_filter_ids` | — | **sem UI** | — | `z.array(z.string())` | `[]` | nunca renderizado |
| `broadcast_filter_logic` | — | **sem UI** | — | enum `AND \| OR` | `OR` | nunca renderizado |
| `broadcast_filter_id` | — | **sem UI** (legado) | — | opcional/nullable | `null` | nunca renderizado |

⚠️ **Achado relevante para o redesign:** `broadcast_filter_ids`, `broadcast_filter_logic` e `broadcast_filter_id` existem no schema, no `defaultValues`, no `reset` e no `submitData` — mas **nenhum deles tem controle visual no formulário**. Hoje eles só podem chegar preenchidos por dado legado. Ainda assim o card da lista exibe "N filtros" + badge "E/OU" a partir deles (§4.3.4). O redesign precisa decidir: (a) expor um seletor de filtros para broadcast, ou (b) remover a leitura no card. Não inventar comportamento — os filtros reais do broadcast hoje vêm dos `assignment_filters` da régua.

### 5.4 Seção A — Tipo de Campanha

Fonte: `src/components/campaigns/CampaignTypeSelector.tsx`.

`RadioGroup` em `grid grid-cols-2 gap-4`. Cada opção é um `<Label>` clicável envolvendo um `<Card className="p-4">`:

| Valor | Título | Descrição | Ícone |
|---|---|---|---|
| `recurring` | **Régua de Cobrança** | "Dispara automaticamente baseado em dias de atraso do título" | `GitBranch` |
| `broadcast` | **Disparo Pontual** | "Dispara uma única vez para um público selecionado" | `Megaphone` |

Estados visuais do card:

| Estado | Classes |
|---|---|
| Selecionado | `border-primary bg-primary/5 ring-1 ring-primary` |
| Não selecionado | `hover:bg-muted/50` |
| Desabilitado | `opacity-50 cursor-not-allowed` |

Layout interno: `flex items-start gap-3` → `RadioGroupItem` (`mt-1`) + coluna com `[ícone h-4 w-4 text-muted-foreground] [título font-medium text-sm]` e descrição `text-xs text-muted-foreground mt-1`.

**Efeitos colaterais de trocar o tipo (3 gatilhos distintos):**

1. `onChange` do seletor limpa `target_reguas` para `[]` (as listas de régua são disjuntas).
2. `useEffect` em `[watchedCampaignType, campaign, form]` — **só na criação** (`if (campaign) return`) — reajusta:
   - broadcast → `active_days = [1,2,3,4,5,6]`, `end_time = "18:00"`
   - recorrente → `active_days = [1,2,3,4,5]`, `end_time = "20:00"`
   - Comentário do código cita `ID_3690`. `start_time` **não** é tocado.
3. Ao submeter, o `isBroadcast` reescreve 6 campos (ver §5.10).

### 5.5 Seção B — Dados Básicos

**Nome** — `Input` simples. Único campo com mensagem de erro própria no Zod ("Nome é obrigatório"). O `FormMessage` renderiza abaixo; além disso o erro vira toast (§5.11).

**Descrição** — `Textarea` sem limite de caracteres nem contador.

**Réguas** (`target_reguas`) — `WorkflowMultiSelect`, fonte `src/components/campaigns/WorkflowMultiSelect.tsx`.

| Aspecto | Recorrente | Broadcast |
|---|---|---|
| Rótulo | "Réguas de Cobrança" | "Réguas de Broadcast" |
| Ícone do rótulo | `GitBranch` | `Megaphone` |
| Hook-fonte | `useAvailableWorkflows()` — `workflow_type eq 'sequential'` **ou** `is null`, ordenado por nome | `useBroadcastWorkflows()` — `workflow_type eq 'broadcast'`, ordenado por nome |
| Placeholder | "Selecione as réguas de cobrança..." | "Selecione as réguas de broadcast..." |
| `FormDescription` | "Selecione uma ou mais réguas de cobrança que serão executadas por esta campanha. **Apenas réguas ativas serão processadas.**" | "Selecione uma ou mais réguas pontuais que serão executadas por esta campanha." |

Anatomia do `WorkflowMultiSelect` (`space-y-3`):

1. `<MultiSelect>` — placeholder vira **"Carregando réguas..."** enquanto `isLoading`; fica `disabled` nesse período. Cada opção carrega `label` (nome), `icon` (`Megaphone` para broadcast, `GitBranch` caso contrário) e `description` = `"{stepCount} ações"` quando o contador existe.
2. **Chips das réguas selecionadas** (`flex flex-wrap gap-2`) — um `Badge` por régua:
   - `variant="secondary"` se ativa, `variant="outline"` + `opacity-60` se inativa;
   - ícone do tipo (`h-3 w-3`), nome com `max-w-[150px] truncate`;
   - selo de status: `CheckCircle2 text-green-500` (ativa) ou `XCircle text-muted-foreground` (inativa);
   - contagem de passos entre parênteses, `text-xs text-muted-foreground`.
3. Contador `"{n} de {max} réguas selecionadas"` — **só aparece se `maxSelections` for passado**, e o `CampaignDialog` **não passa**. Código morto na tela de campanhas.
4. Aviso âmbar quando há régua inativa selecionada: **"Algumas réguas selecionadas estão inativas e não serão executadas."** (`text-xs text-amber-600 dark:text-amber-400`).

Regras de filtragem: o dialog passa `filterByStatus={false}` (**régua inativa aparece na lista**) e `workflowType` = `"broadcast"` ou `"sequential"`. Com `filterByStatus={false}`, a opção inativa recebe `disabled: true` no `MultiSelect` — ou seja, aparece mas **não é selecionável de novo**; só continua listada se já estava no valor.

### 5.6 Seção B.2 — Público-Alvo (só broadcast)

Renderizada apenas quando `isBroadcast && form.watch("target_reguas")?.length > 0`. Para **cada** régua selecionada renderiza dois blocos, nesta ordem: todos os `WorkflowFilterPreview` e depois todos os `RepiquePreview`.

#### 5.6.1 `WorkflowFilterPreview`

Fonte: `src/components/campaigns/WorkflowFilterPreview.tsx`. Resolve os `assignment_filters` da régua (`portfolios[]`, `filter_ids[]`, `aggregation_logic`), monta um `FilterGroup` combinado e chama a Edge Function **`evaluate-filter`** com `limit: 1`.

Estados do componente, em ordem de precedência:

| Estado | Condição | Visual |
|---|---|---|
| Sem régua | `!workflowId` | Faixa `bg-muted/50`, `AlertCircle`, "Selecione uma régua para ver a prévia de contatos" |
| Carregando | `workflowLoading \|\| statsLoading` | Faixa `bg-muted/50`, `Loader2` girando, "Carregando prévia..." |
| Erro | `isError` | Faixa `bg-destructive/10 text-destructive`, `AlertCircle`, "Erro ao calcular contatos" |
| Régua sem filtro | `portfolios` e `filter_ids` ambos vazios | Faixa âmbar (`bg-amber-500/10 text-amber-700 border-amber-500/20`), "Esta régua não possui filtros configurados. Configure os filtros na tela de Réguas." |
| Normal | — | Cartão (ver abaixo) |

Cartão normal: `p-4 rounded-lg border`, com fundo `bg-primary/5 border-primary/20` quando há contatos e `bg-muted/50 border-border` quando é zero.

```
flex items-center justify-between (mb-3)
├── [Users text-primary] "Prévia do Disparo"   (font-medium text-sm)
└── Badge outline: [GitBranch h-3 w-3] {nome da régua}

flex flex-wrap gap-1 (mb-3) — um Badge secondary por filtro/carteira
     carteira aparece como "Carteira: {nome}"

grid grid-cols-3 gap-4
├── {contactCount}  text-2xl font-bold text-primary   / "Contatos"
├── {contractCount} text-2xl font-bold text-foreground / "Contratos"
└── {totalDebt}     text-lg font-semibold, Intl BRL    / "Dívida Total"

(se contactCount === 0) "Nenhum contato encontrado com os filtros da régua"
```

Notas de comportamento documentadas no próprio código (IAF-6986): a prévia **não filtra por `is_active`** ao resolver filtros e carteiras — filtro desativado some da descoberta, nunca da execução, e a prévia precisa reproduzir a audiência real. `staleTime` de 5 minutos.

#### 5.6.2 `RepiquePreview`

Fonte: `src/components/campaigns/RepiquePreview.tsx`. Chama a RPC **`preview_broadcast_audience`** com `p_schema`, `p_workflow_id`, `p_repique_enabled`, `p_campaign_id` (null na criação). `staleTime` de 2 minutos. Retorno: `{ matched, blocked, no_debt, already_contacted_today, would_send }`.

| Estado | Condição | Visual |
|---|---|---|
| Oculto | `!workflowId` **ou** `matched === 0` | retorna `null` (nada aparece) |
| Carregando | `isLoading` | Faixa `bg-muted/50`, `Loader2`, "Calculando estimativa de repique..." |
| Sem descarte | `already_contacted_today`, `blocked` e `no_debt` todos zero | Faixa verde (`bg-green-50 border-green-200 text-green-700`), ícone `Repeat`: "Nenhum contato desta campanha sera pulado. Todos os {matched} receberao o disparo." |
| Com descarte | qualquer um > 0 | Cartão (abaixo) |

Cartão com descarte: `p-4 rounded-lg border`, fundo **âmbar** (`bg-amber-50 border-amber-200`) quando o repique está ligado e `bg-muted/50 border-border` quando desligado.

```
flex items-center justify-between (mb-2)
├── [Repeat] "Impacto do Repique"
└── Badge outline "Repique ativo" (amber) — só se repiqueEnabled

(se already_contacted_today > 0)
  caixa: [UserMinus] {n em text-lg font-bold} "de {matched} ja contatados hoje"
  fundo bg-red-50/border-red-200 quando repique DESLIGADO;
  número com line-through + text-muted-foreground quando repique LIGADO

frase de resultado:
  repique ON  → "Com Repique ativo, os {n} ja contatados serao incluidos.
                 {would_send} contatos receberao o envio."      (text-amber-600)
  repique OFF → "Apenas {would_send} de {matched} receberao.
                 Ative o Repique para incluir os ja contatados hoje."

(opcional) "{X} bloqueados + {Y} sem débito ativo serao descartados."
```

⚠️ Os textos deste componente estão **sem acentuação** no código (`sera`, `receberao`, `ja`, `serao`). É um defeito real de copy que o redesign deve corrigir.

### 5.7 Seção C — Status e Disparo

#### 5.7.1 Switch "Campanha Ativa"

`FormItem` estilizado como cartão: `flex flex-row items-center justify-between rounded-lg border p-4`.

| Estado do switch | Valor gravado | `FormDescription` |
|---|---|---|
| Ligado | `status = "active"` | "A campanha está ativa e processando ações" |
| Desligado | `status = "draft"` | "A campanha está inativa (rascunho/pausada)" |

⚠️ Assimetria real: desligar o switch grava **sempre** `draft`, mesmo se a campanha estava `paused`. Editar e salvar uma campanha pausada com o switch desligado **converte `paused` em `draft`** silenciosamente.

O texto "ativa e processando ações" é semanticamente carregado — é o mesmo compromisso que levou o `onSubmit` a disparar o broadcast na criação (§5.10).

#### 5.7.2 `BroadcastScheduleInput` (só broadcast)

Fonte: `src/components/campaigns/BroadcastScheduleInput.tsx`. Rótulo do grupo: **"Quando Disparar"**. `RadioGroup` vertical (`space-y-3`), mesma linguagem de cards do `CampaignTypeSelector`.

| Valor | Título | Descrição | Ícone |
|---|---|---|---|
| `immediate` | **Manual** | "Disparo controlado manualmente pelo usuário" | `Hand` (`text-amber-500`) |
| `scheduled` | **Agendar** | "Define uma data e horário específico para o disparo" | `CalendarClock` (`text-blue-500`) |

Quando `scheduled`, abre um bloco recuado (`pl-6 space-y-2`):

- `Label` "Data e Hora do Disparo"
- `Input type="datetime-local"` `className="max-w-xs"`, com `min` = **agora + 5 minutos** (`new Date()` local, `.toISOString().slice(0,16)`)
- Nota: "O disparo ocorrerá no horário especificado (fuso horário local)"

⚠️ A confirmar: o `min` é calculado a partir de `toISOString()` (UTC) sobre um relógio local — em BRT o valor mínimo exibido fica deslocado. O redesign deve validar o cálculo com o time técnico antes de replicar.

#### 5.7.3 Bloco "Janela de Atendimento"

Cartão `p-4 rounded-lg border bg-muted/20`. Cabeçalho `Calendar` + "Janela de Atendimento". Texto de apoio (`text-xs text-muted-foreground`) muda por tipo:

| Tipo | Texto |
|---|---|
| Broadcast | "Define os dias e horários em que as ações criadas pelo broadcast podem ser enviadas. O broadcast cria as ações no momento do disparo, mas o envio respeita esta janela." |
| Recorrente | "Define os horários e dias permitidos para disparo de ações." |

Conteúdo:

- `grid grid-cols-2 gap-4` com **Horário de Início** e **Horário de Fim** (`Input type="time"`).
- **Dias da Semana**: `flex flex-wrap gap-2` com 7 botões, um por entrada de `DAYS_OF_WEEK` (`src/lib/constants/days-of-week.ts`):

| `value` | `label` | `shortLabel` (é o que o botão mostra) |
|---|---|---|
| 0 | Domingo | **Dom** |
| 1 | Segunda | **Seg** |
| 2 | Terça | **Ter** |
| 3 | Quarta | **Qua** |
| 4 | Quinta | **Qui** |
| 5 | Sexta | **Sex** |
| 6 | Sábado | **Sáb** |

Botão selecionado = `variant="default"`; não selecionado = `variant="outline"`. Largura mínima `60px`. **Não há validação impedindo zero dias selecionados** — é possível salvar uma campanha que nunca dispara.

⚠️ Não existe campo de `timezone` na UI. O valor é fixado em `America/Sao_Paulo` pelo `transformCreate` do hook.

### 5.8 Seção D — Batching e Anti-Spam

#### 5.8.1 Ações por Minuto

Cabeçalho em duas colunas: `FormLabel` "Ações por Minuto" à esquerda e, à direita, `<span className="text-sm font-medium text-primary">{valor} contatos/min</span>`.

⚠️ Inconsistência de vocabulário: o rótulo diz **ações**, o valor ao lado diz **contatos**, e o card da lista diz **"N ações/min"**. Escolher um termo no redesign.

`Slider` de 1 a 100, passo 1, `className="py-4"`. `FormDescription` com ícone `Info`:

> "Controla a velocidade de processamento. Valores menores são mais seguros para evitar bloqueios de operadoras."

Não há presets nem entrada numérica direta.

#### 5.8.2 Cooldown Anti-Spam

Campo de valor único (`contact_cooldown_hours`) exposto por um **modo derivado** do valor:

| Valor gravado | Modo inferido | Rótulo à direita |
|---|---|---|
| `0` | `none` | **Desativado** |
| `-1` | `once` | **Infinito** |
| `1`–`168` | `custom` | **{n}h** |

`ToggleGroup type="single"` com 3 itens (`text-xs`), alinhado à esquerda:

| Item | Rótulo | Grava |
|---|---|---|
| `none` | **Sem cooldown** | `0` |
| `custom` | **Personalizado** | último valor custom, ou `24` |
| `once` | **Apenas uma vez** | `-1` |

No modo `custom` abre: `Slider` 1→168 (passo 1) + linha de 5 atalhos `Button` — **6h, 12h, 24h, 48h, 72h** (o atalho ativo vira `variant="default"`).

Textos de apoio por modo:

| Modo | Ícone | Cor | Texto |
|---|---|---|---|
| `none` | `AlertTriangle` | `text-amber-600` | "O mesmo contato pode receber múltiplas mensagens do mesmo canal no mesmo dia. Use com cuidado para evitar spam." |
| `custom` | `Info` | padrão | "Intervalo mínimo entre contatos para o mesmo destinatário. Previne spam e melhora taxas de entrega." |
| `once` | `Info` | padrão | "Cada contato recebe apenas uma mensagem por canal/integração durante toda a vida da campanha. Ideal para notificações únicas ou avisos legais." |

Detalhe de implementação relevante ao redesign: o "último valor custom" **não é memorizado** — ao sair de `custom` e voltar, o slider retorna a `24` (o `sliderValue` só preserva o valor enquanto o modo é `custom`).

#### 5.8.3 Repique (só broadcast)

Precedido de `<Separator className="my-2" />`. Mesmo padrão de cartão do switch de status:

- `FormLabel` "**Repique**" (`text-base`)
- `FormDescription` "Permite recontatar pessoas que já receberam mensagens hoje"
- `Switch`

Quando **ligado**, aparece abaixo um bloco de alerta `bg-amber-50 border-amber-200 text-amber-600`, `AlertTriangle`:

> "**Atenção:** Com o Repique ativo, contatos que já receberam mensagens hoje poderão ser contatados novamente. Use com cautela para evitar excesso de comunicação e bloqueios de operadora."

O valor é gravado em `settings.repique_enabled` (JSONB), **não** em coluna própria. Para campanha recorrente o submit força `false`.

### 5.9 Seção E — Geração de Ações (Producer), só recorrente

Texto de apoio do grupo: "Define quando o sistema deve gerar as ações de disparo para os contatos".

**Tipo de Gatilho** — `grid grid-cols-3 gap-3`, cada opção é um `<button type="button">` vertical:

```
flex flex-col items-center gap-2 p-3 rounded-lg border-2 transition-all text-center
selecionado:     border-primary bg-primary/5   + ícone text-primary
não selecionado: border-muted hover:border-muted-foreground/30 + ícone text-muted-foreground
```

| Valor | Rótulo (`text-xs font-medium`) | Ícone `h-5 w-5` | `FormDescription` quando selecionado |
|---|---|---|---|
| `scheduled` | **Agendado (CRON)** | `Clock` | "Gera ações automaticamente no horário configurado" |
| `manual` | **Manual** | `Play` | "Gera ações apenas quando disparado manualmente" |
| `on_pipeline_complete` | **Após Pipeline ETL** | `Database` | "Gera ações automaticamente após a conclusão de um pipeline de importação" |

**Campo dependente 1 — Pipeline de ETL** (`producer_trigger_type === "on_pipeline_complete"`):

- `Select` com placeholder "Selecione o pipeline"; opções vêm de `usePipelinesForSelect()` (`src/hooks/etl`).
- `FormDescription`: "Ações serão geradas automaticamente após a conclusão deste pipeline".
- Obrigatório **só no submit**: se vazio, toast destrutivo "Erro de validação" / "Selecione um pipeline de ETL para o gatilho 'Após Pipeline ETL'".

**Campo dependente 2 — Agendamento CRON** (`producer_trigger_type === "scheduled"`):

1. Linha de presets (`flex flex-wrap gap-2`), de `CRON_PRESETS` em `src/lib/cron-translator.ts`:

| Rótulo do botão | Valor |
|---|---|
| Diariamente à meia-noite | `0 0 * * *` |
| Diariamente às 8h | `0 8 * * *` |
| Dias úteis às 9h | `0 9 * * 1-5` |
| Toda segunda-feira às 8h | `0 8 * * 1` |
| Todo dia 1º do mês às 9h | `0 9 1 * *` |
| A cada hora | `0 * * * *` |
| A cada 30 minutos | `*/30 * * * *` |

O preset cujo valor é igual ao campo fica `variant="default"`.

2. Sub-rótulo `text-xs text-muted-foreground`: "Ou digite uma expressão CRON personalizada:" + `Input` com `placeholder="0 0 * * *"` e `className="font-mono"`.

3. **Tradução em linguagem natural** — sempre que o campo não está vazio, aparece uma faixa `p-2 rounded-md bg-muted/50 border border-muted` com `CalendarClock text-primary` + o texto de `translateCronExpression()`.

Padrões que a tradução reconhece (`src/lib/cron-translator.ts`):

| Padrão | Saída |
|---|---|
| `* * * * *` | "A cada minuto" |
| `*/X * * * *` | "A cada X minutos" |
| `M * * * *` | "A cada hora, no minuto M" |
| `0 */X * * *` | "A cada X horas" |
| `M H * * *` | "Diariamente às HH:MM" (aceita lista de horas: "07:00, 13:00 e 19:00") |
| `M H * * 1-5` | "Dias úteis (seg a sex) às HH:MM" |
| `M H * * D` | "Toda {dia por extenso} às HH:MM" |
| `M H D * *` | "Todo dia D do mês às HH:MM" |
| `M H D Mes *` | "Todo dia D de {mês} às HH:MM" |
| menos de 5 campos | "Formato inválido (esperado: 5 campos)" |
| vazio / não-string | "Expressão inválida" |
| não classificado | frase montada com "Executa às …", ou "Expressão CRON personalizada" |

⚠️ A expressão CRON **não é validada** — digitar lixo produz "Expressão CRON personalizada" (ou "Formato inválido…") mas **o formulário salva assim mesmo**. Oportunidade de redesign (§17).

### 5.10 O que o submit realmente grava

Função `onSubmit` (linhas 211-311). Ordem exata:

**Gate 1 — régua obrigatória.** `targetReguas.length === 0` → toast destrutivo "Erro de validação" / "Selecione ao menos uma régua antes de criar a campanha" e **aborta**. Vale para os dois tipos.

**Gate 2 — pipeline obrigatório.** `!isBroadcast && producer_trigger_type === "on_pipeline_complete" && !producer_pipeline_id` → toast destrutivo e aborta.

**Reescritas por tipo** no objeto enviado:

| Campo enviado | Recorrente | Broadcast |
|---|---|---|
| `start_time` / `end_time` | valor do form + `":00"` | idem (broadcast **também** manda janela desde o ID_3690) |
| `producer_trigger_type` | valor do form | **forçado `"manual"`** |
| `producer_cron_expression` | valor do form | `null` |
| `producer_pipeline_id` | valor só se trigger = `on_pipeline_complete`, senão `null` | `null` |
| `scheduled_at` | `null` | valor só se `schedule_type === "scheduled"`, senão `null` |
| `broadcast_filter_id` | `null` | `broadcast_filter_ids[0]` se houver, senão `null` |
| `broadcast_filter_ids` | `null` | array do form |
| `broadcast_filter_logic` | `null` | valor só se houver **mais de 1** filtro, senão `null` |
| `processed` | `false` | `false` |
| `settings` | merge `{...campaign.settings, repique_enabled: false}` | merge com `repique_enabled` do form |

O merge de `settings` é deliberado: preserva chaves escritas por triggers do banco (ex.: `paused_reason` do cascade de régua).

Campos gravados pelo `transformCreate` do hook e **invisíveis no formulário** (`src/hooks/useCampaigns.ts`):

| Campo | Valor |
|---|---|
| `timezone` | `"America/Sao_Paulo"` |
| `use_pipeline_v2` | **`true`** — toda campanha nova nasce no pipeline v2 |
| `contact_cooldown_hours` | `?? 24` |
| `actions_per_minute` | `|| 10` |
| `start_date` / `end_date` | `null` |

**Disparo automático na criação (broadcast).** Após o `create`, se `shouldDispatchBroadcastNow(created)` — ou seja, `campaign_type === "broadcast"` **e** `status === "active"` **e** (`scheduled_at` ausente ou já passado) — o formulário **aguarda** `invokeBroadcastProcessor(id, "creation")`:

| Resultado | Toast | Variante |
|---|---|---|
| Sucesso | "Campanha criada e disparada!" / "O processamento do broadcast foi iniciado." | default |
| Falha | "Campanha criada, mas o disparo falhou" / `{erro}. Use "Executar Agora" no menu da campanha para tentar novamente.` | destructive |

Comentário do código explica o porquê, e é uma regra de produto que o redesign **não pode perder**: criar marcando "Campanha Ativa" **deve** disparar, porque o switch promete "ativa e processando ações". Entre 2026-06-11 e 2026-07-29 o cron do `broadcast-processor` ficou fora do ar e a campanha ficava parada exibindo selo de que estava rodando.

Depois do disparo, `onClose()`. **O editor de broadcast não abre automaticamente** ("Campanha criada - não abre editor automaticamente").

### 5.11 Rodapé, erros e estados

| Botão | Tipo | Comportamento |
|---|---|---|
| **Cancelar** | `variant="outline"` | fecha sem confirmação — **não há guarda de alterações não salvas** |
| **Criar Campanha** / **Salvar Alterações** | primário | `disabled` enquanto `isSubmitting`; mostra `Loader2` girando à esquerda do rótulo |

`isSubmitting = createCampaign.isPending || updateCampaign.isPending`.

O botão de salvar é `type="button"` e chama `form.handleSubmit(onSubmit, onInvalid)` no `onClick` — não é submit nativo do `<form id="campaign-form">`.

**Erros de validação viram toast**, além do `FormMessage` inline. O handler `onInvalid` monta a mensagem juntando `"{Rótulo}: {mensagem}"` com quebra de linha, usando um dicionário de 3 rótulos:

| Chave técnica | Rótulo no toast |
|---|---|
| `name` | Nome |
| `description` | Descrição |
| `target_reguas` | Réguas |

Qualquer outro campo aparece com a **chave técnica crua**. Fallback quando não há mensagem: "Verifique os campos obrigatórios".

**Erro ao salvar**: toast destrutivo "Erro ao salvar campanha" com `error.message` ou "Ocorreu um erro inesperado", e `logError` com `{ source: "CampaignDialog", action: "save campaign" }`.

**Estado de carregamento das réguas**: não bloqueia o formulário inteiro — só o multi-select fica desabilitado com placeholder "Carregando réguas...".

⚠️ Não existe estado de "carregando campanha para edição": o `CampaignDialog` recebe o objeto `Campaign` já pronto da lista e popula via `form.reset` num `useEffect`.

---

## 6. Detalhe da campanha (`CampaignDetailDialog`)

Fonte: `src/components/campaigns/CampaignDetailDialog.tsx`. Aberto por: item **Visualizar** do menu (ambas as visões) **ou** clique na linha/card quando `status === "completed"`.

### 6.1 Contêiner

```
<DialogContent className="flex flex-col p-0 w-[95vw] max-w-4xl h-[90vh] overflow-hidden">
```

Mais largo que o formulário (`max-w-4xl` = 896 px) e sem padding no contêiner — cada região controla o seu.

### 6.2 Cabeçalho

`px-6 py-4 border-b bg-gradient-to-r from-primary/5 to-transparent shrink-0`.

Linha única `flex items-center justify-between`:

- **Esquerda**: `DialogTitle` com `Target h-5 w-5` + "**Detalhes da Campanha**". A `DialogDescription` existe mas é `sr-only` ("Visualize as informações detalhadas da campanha selecionada.") — só para leitores de tela.
- **Direita**: até dois botões, nesta ordem:

| Ordem | Botão | Variante | Condição | `title` (tooltip nativo) |
|---|---|---|---|---|
| 1 | **Ensaiar** (`FlaskConical`) | `outline`, `size="sm"` | `campaignSupportsDryRun(campaign)` | "Roda os passos 1 a 5 do pipeline e mostra o resultado sem criar nenhuma ação" |
| 2 | **Forçar Execução** (`Play`) | primário, `size="sm"` | **sempre** | — |

O ensaio vem **antes** do disparo de propósito (comentário IAF-6392-6390): é a opção segura e é o que a maioria quer antes de forçar execução.

Estado do botão de execução: enquanto `isExecuting`, o ícone vira `Loader2` girando e o rótulo vira "**Executando...**", com `disabled`.

⚠️ **"Forçar Execução" não tem gate de permissão nem de status.** Diferente do "Executar Agora" do menu da lista (que exige `canWrite`, trigger manual e status `active`), aqui o botão aparece para qualquer campanha e qualquer perfil que consiga abrir o modal — inclusive `viewer`. É uma inconsistência real (§17).

Fluxo do clique em **Forçar Execução** (`handleForceExecute`):

1. `checkExecutionWindow(campaign)` (de `src/hooks/useCampaignPreview.ts`).
2. Se `isOutsideWindow` → abre o `ExecuteOutsideWindowDialog` e **para**.
3. Senão → `doExecute()` → `useManualExecuteCampaign().mutateAsync(campaign.id)`.

### 6.3 Abas

`<Tabs defaultValue="details">` com `TabsList` em `mx-6 mt-4 w-fit`:

| Aba | `value` | Rótulo | Adorno |
|---|---|---|---|
| Informações | `details` | "Informações" | — |
| Histórico | `history` | `History` + "Histórico" | `Badge secondary` com a contagem de execuções, **só se > 0** |

A contagem do badge é `logs.length`, e `useCampaignLogs` limita a **50** registros — o badge satura em 50.

### 6.4 Aba "Informações"

Carregamento: `useCampaign(id)` — busca a campanha e, se houver `target_reguas`, as réguas correspondentes (`id, name, status`). Enquanto carrega, mostra apenas um `Loader2 h-8 w-8` centralizado com `py-8`. Se o retorno for nulo, a aba renderiza **nada** (sem estado vazio dedicado).

Blocos, na ordem:

#### Bloco 1 — Cartão de identificação

```
CardHeader (pb-2): flex items-start justify-between
├── CardTitle text-lg  {nome}
└── [Badge outline {rótulo do trigger}]  [Badge {cor do status} {rótulo do status}]

CardContent:
├── {descrição}  text-muted-foreground   (só se existir)
└── (mt-4 pt-4 border-t) [Zap] "{actions_per_minute ?? 10} ações/minuto"
```

Resolução do rótulo de trigger: `PRODUCER_TRIGGER_TYPES[producer_trigger_type]` → fallback `TRIGGER_TYPES[trigger_type]` → `null` (badge some).

Cores de status (`CAMPAIGN_STATUS` em `src/lib/constants/status.ts`):

| Status | Rótulo | Classes |
|---|---|---|
| `draft` | Rascunho | `bg-gray-100 text-gray-800` |
| `active` | Ativa | `bg-green-100 text-green-800` |
| `paused` | Pausada | `bg-yellow-100 text-yellow-800` |
| `completed` | Concluída | `bg-blue-100 text-blue-800` |
| `cancelled` | Cancelada | `bg-red-100 text-red-800` |

#### Bloco 2 — KPIs agregados (só se `totalExecutions > 0`)

`grid grid-cols-4 gap-4`, um `Card` por métrica, valor em `text-2xl font-bold` e rótulo em `text-xs text-muted-foreground`:

| # | Valor | Rótulo | Derivação |
|---|---|---|---|
| 1 | `logs.length` | **Execuções** | contagem bruta (teto 50) |
| 2 | logs com `status === "completed"` | **Sucesso** | em `text-green-600` |
| 3 | `Σ contacts_processed` | **Contatos** | soma sobre os logs carregados |
| 4 | `Σ actions_created` | **Ações** | soma sobre os logs carregados |

⚠️ Os quatro números são **derivados dos últimos 50 logs**, não do histórico completo da campanha. A tela não avisa isso. Oportunidade de redesign (§17).

`completed_with_errors` **não** conta como sucesso no KPI 2.

#### Bloco 3 — Custo Estimado

`<CampaignCostBreakdown campaignId={id} totalContacts={totalContacts} />`, renderizado só quando `totalExecutions > 0`. Detalhado na **§10**.

#### Bloco 4 — Horário de Execução

Cartão com `CardTitle` `Clock h-5 w-5` + "Horário de Execução":

- `grid grid-cols-2 gap-4`: "Início" e "Fim" — valor cru de `start_time`/`end_time`, **incluindo os segundos** (`08:00:00`), ou "**Não definido**" quando nulo.
- Linha "Dias Ativos" com `Calendar`: usa `formatDays` **local deste arquivo**, que difere do da lista:

| Entrada | Saída aqui | Saída na lista (§4.3.4) |
|---|---|---|
| vazio/nulo | "Nenhum dia selecionado" | "Nenhum dia" |
| 7 dias | "Todos os dias" | "Todos os dias" |
| `[1,2,3,4,5]` | "Segunda, Terça, Quarta, Quinta, Sexta" | "Seg - Sex" |
| outro | nomes **longos** por extenso, vírgula | abreviações |

⚠️ Duas implementações de `formatDays` com regras diferentes. Unificar no redesign.

#### Bloco 5 — Réguas Associadas

`CardTitle` `GitBranch h-5 w-5` + "Réguas Associadas". Lista `space-y-2` com uma linha por régua (`flex items-center gap-2 p-2 bg-muted/50 rounded-md`, `GitBranch` + nome). Vazio: "**Nenhuma régua associada**".

⚠️ O `status` da régua é buscado no hook (`select("id, name, status")`) mas **não é exibido** — régua inativa aparece igual à ativa. No formulário o mesmo dado é sinalizado com `XCircle` e aviso âmbar. Inconsistência a resolver.

#### Bloco 6 — Metadados

`grid grid-cols-2 gap-4 text-sm`, rótulo em `text-muted-foreground` e valor em `font-medium`, formato `dd/MM/yyyy 'às' HH:mm` (`formatDate` de `src/lib/formatters`):

| Rótulo | Campo | Condição |
|---|---|---|
| Criado em | `created_at` | sempre |
| Última atualização | `updated_at` | sempre |
| Última execução manual | `last_manual_execution_at` | só se preenchido (ocupa `col-span-2`) |

### 6.5 Aba "Histórico" — `ExecutionTimeline`

Componente local do mesmo arquivo. Fonte de dados: `useCampaignLogs(id)` → `campaign_logs` filtrado por `campaign_id`, ordenado por `started_at` desc, **limite 50**.

Estados:

| Estado | Visual |
|---|---|
| Carregando | `Loader2 h-6 w-6` centralizado, `py-8` |
| Vazio | `History h-12 w-12 text-muted-foreground/30`, "**Nenhuma execução registrada**" + "As execuções aparecerão aqui quando a campanha for disparada" |
| Com dados | Linha do tempo vertical |

Estrutura da linha do tempo: uma linha contínua `w-0.5 bg-border` posicionada em `left-[19px]`, com espaçamento `space-y-6`. Cada item é `flex gap-4`:

1. **Bolinha de status** — `h-10 w-10 rounded-full border-2`. O item mais recente (`index === 0`) recebe `border-primary bg-primary text-primary-foreground`; os demais, `border-border bg-background` com ícone em `text-muted-foreground`.
2. **Cartão** — `flex-1`, com `border-primary/30` quando é o mais recente.

Conteúdo do cartão (`p-4`):

```
cabeçalho
├── Badge outline com a cor do status + rótulo
├── Badge secondary text-xs: rótulo do TRIGGER_TYPES[log.trigger_type] (fallback: valor cru)
└── data: dd/MM/yyyy 'às' HH:mm:ss   (text-sm text-muted-foreground)

grid grid-cols-3 gap-4 (mt-4) — três métricas com "pastilha" de ícone
├── [Users azul]  {contacts_processed}  / "Contatos"
├── [Zap verde]   {actions_created}     / "Ações"
└── [XCircle]     {errors_count}        / "Erros"
      pastilha vermelha (bg-red-100) e ícone vermelho quando errors_count > 0;
      cinza (bg-muted) quando zero

(se completed_at) [Timer] "Duração: {…}"

(se error_details) caixa bg-destructive/10:
   "Detalhes do erro:" (font-medium text-destructive)
   + primeiros 200 caracteres, whitespace-pre-wrap, com "..." se truncado
```

**Catálogo de status de log** (`LOG_STATUS_CONFIG`) — é o vocabulário que o usuário lê:

| Valor | Rótulo exibido | Ícone | Cores |
|---|---|---|---|
| `pending` | **Pendente** | `Timer` | `bg-muted text-muted-foreground` |
| `running` | **Executando** | `PlayCircle` | `bg-blue-100 text-blue-800` (dark: `bg-blue-900 text-blue-300`) |
| `completed` | **Concluído** | `CheckCircle2` | `bg-green-100 text-green-800` (dark: `bg-green-900 text-green-300`) |
| `completed_with_errors` | **Concluído com erros** | `AlertCircle` | `bg-amber-100 text-amber-800` (dark: `bg-amber-900 text-amber-300`) |
| `deferred` | **Agendado** | `Clock` | `bg-purple-100 text-purple-800` (dark: `bg-purple-900 text-purple-300`) |
| `failed` | **Falhou** | `XCircle` | `bg-destructive/10 text-destructive` |
| `failed_retrying` | **Falhou (retry automático)** | `AlertCircle` | `bg-amber-100 text-amber-800` |
| qualquer outro | cai no visual de `pending` | `Timer` | `bg-muted` |

**Formato de duração** (`calculateDuration`, local do arquivo):

| Faixa | Formato |
|---|---|
| < 1 s | `< 1s` |
| < 1 min | `{n}s` (arredondado) |
| < 1 h | `{m}m {s}s` |
| ≥ 1 h | `{h}h {m}m` |

### 6.6 Modais filhos montados pelo detalhe

Dois modais vivem **fora** do `Dialog` principal, montados em paralelo:

| Modal | Controle | Observação |
|---|---|---|
| `ExecuteOutsideWindowDialog` | `showOutsideWindowDialog` | `onConfirm` fecha e chama `doExecute()`; `onCancel` só fecha |
| `CampaignDryRunDialog` | `showDryRun` | recebe `key={`dry-run-${campaign?.id ?? "closed"}`}` para não herdar o resultado de outra campanha |

### 6.7 O que o detalhe **não** mostra

Levantamento explícito, porque o redesign pode querer preencher essas lacunas:

- Tipo da campanha (recorrente × broadcast) — não há badge de tipo aqui.
- `contact_cooldown_hours` / cooldown anti-spam.
- `scheduled_at` do broadcast, `processed`, `repique_enabled`.
- `producer_cron_expression` (nem o texto traduzido) e `producer_pipeline_id`.
- Status das réguas associadas.
- Qualquer vínculo com o pipeline v2 (`campaign_execution_runs`) — o histórico só lê `campaign_logs`.
- Botões de editar, pausar/ativar, excluir ou abrir o editor de broadcast: **não existem no detalhe**. Para editar é preciso fechar o modal e voltar à lista.

---

## 7. Prévia e Ensaio

Duas telas diferentes que o usuário confunde — e o redesign precisa manter separadas:

| | **Ações previstas** (`CampaignPreviewModal`) | **Ensaiar** (`CampaignDryRunDialog`) |
|---|---|---|
| Gatilho | Botão "Ver ações previstas" no rodapé do card | Item "Ensaiar (não cria ações)" do menu, ou botão "Ensaiar" no detalhe |
| O que mostra | O que **já aconteceu** (funil real) + projeção ao vivo | O que **aconteceria agora**, rodando o pipeline de verdade em modo seco |
| Escreve no banco | Nada | **Sim** — cria linha em `campaign_execution_runs` com `is_dry_run = true` e candidatos |
| Fonte do funil | `campaign_logs` | `campaign_execution_runs` + `campaign_execution_candidates` |
| Roda ao abrir | Sim (consultas) | **Não** — exige clique em "Rodar ensaio" |
| Disponível para | Qualquer campanha | Só recorrente com `use_pipeline_v2 === true` |

### 7.1 `CampaignPreviewModal` — "Ações previstas"

Fonte: `src/components/campaigns/CampaignPreviewModal.tsx` (725 linhas).

#### Contêiner

```
<DialogContent className="max-w-2xl max-h-[92vh] flex flex-col p-0 gap-0">
```

Comentário do código é explícito: **largura fixa de propósito** — "esqueleto único, seções sempre na mesma ordem/tamanho — nunca vira 'modal mais estreito'". O redesign não deve variar a largura por estado.

Quando `campaign` é `null`, o modal renderiza só o header com o título "Ações previstas".

#### Blocos A-F

| Bloco | Nome no código | Sempre visível? |
|---|---|---|
| A | Header | sim |
| B | Funil de elegibilidade (real) | sim (com empty-state contextual) |
| C | Estimativa da próxima ativação | **sim** (muda de forma, nunca some) |
| D | Andamento dos envios | sim |
| E | Detalhes (motivo dominante, distribuição por canal, drill-down) | sim |
| F | Legado (janela, data bloqueada, distribuição por dia de atraso) | só com estimativa aplicável |

#### Bloco A — Header

```
DialogTitle: [Eye h-5 w-5] "Ações previstas — {nome da campanha}"

linha de pílulas (flex-wrap gap-2):
├── Badge outline com a cor do status + rótulo        + HelpTip "Status da campanha"
├── Badge secondary: [Clock h-3 w-3] {rótulo do gatilho} + HelpTip "Gatilho"
└── (se houver) texto muted: "{Seg, Ter, … · HH:MM–HH:MM}" + HelpTip "Janela de execução"

linha de contexto (text-sm text-muted-foreground):
└── {topLabel} + HelpTip "Última ativação / Próxima"
    (+ "· Próxima: estimativa abaixo" quando willRunAgain)
```

Rótulo do gatilho (`triggerLabel`): broadcast → **"Pontual"**; senão o `label` de `PRODUCER_TRIGGER_TYPES`; sem trigger → **"—"**.

Rótulo da janela (`windowLabel`): dias ordenados e abreviados (`Dom Seg Ter Qua Qui Sex Sáb`) + horário `HH:MM–HH:MM` (travessão, não hífen), unidos por " · ". Se faltar tudo, a linha some.

#### A matriz de estado (`useCampaignPreviewState`)

Fonte: `src/hooks/useCampaignPreviewState.ts`. É o coração do modal: decide, de forma determinística, qual número é o herói. Consome dois funis — `useCampaignFunnel(id, "today")` e `useCampaignFunnel(id, "last")`.

Definições:

- `ranToday` = existe log com `completed_at` no dia BRT de hoje.
- `everRan` = existe ao menos um log com `completed_at`.
- `isPontual` = `producer_trigger_type === "manual"` **ou** `campaign_type === "manual"` **ou** `campaign_type === "broadcast"`.

**Escolha do funil herói:** usa o de hoje **só quando** `ranToday && (status === "active" || isPontual)`. Caso contrário, usa a última run, se houver. Campanha pausada/rascunho/concluída/cancelada **nunca** usa "hoje" como herói.

**Rótulo do topo (`topLabel`)** — tabela completa:

| Situação | Rótulo |
|---|---|
| Pontual (broadcast) que já rodou | `Pontual · última {DD/MM}` |
| Pontual (broadcast) que nunca rodou | `Pontual · ainda não disparada` |
| Manual que já rodou | `Manual · última {DD/MM}` |
| Manual que nunca rodou | `Manual · ainda não disparada` |
| Ativa + rodou hoje | `Ativa · rodou hoje ({N} runs)` |
| Ativa + já rodou (não hoje) | `Ativa · última {DD/MM}` |
| Ativa + nunca rodou | `Ativa · ainda não executou` |
| Pausada + já rodou | `Pausada` |
| Pausada + nunca rodou | `Pausada · nunca executou` |
| Rascunho | `Rascunho` |
| Concluída | `Concluída` |
| Cancelada | `Cancelada` |

**Rótulo de data do funil (`funnelDateLabel`)**, exibido como subtítulo do card do funil:

| Herói | Rótulo |
|---|---|
| Hoje | `Hoje ({N} runs)` |
| Última run com data | `Última ativação · {DD/MM}` |
| Última run sem data | `Última ativação` |
| Sem herói | `null` (nenhum subtítulo) |

**Estimativa (`estimate`)** — nunca some, só muda de rótulo e de peso:

| Situação | `applicable` | `label` | `isHero` |
|---|---|---|---|
| Manual ou broadcast (qualquer status) | **false** | "Sem estimativa automática (disparo sob demanda)" | false |
| Ativa com régua, **nunca rodou** | true | "Próxima ativação" | **true** |
| Ativa com régua, já rodou | true | "Próxima ativação" | false |
| Pausada | true | "Não será disparada (pausada)" | false |
| Rascunho | true | "Rascunho — não ativa" | false |
| Concluída | true | "Não será disparada (concluída)" | false |
| Cancelada | true | "Não será disparada (cancelada)" | false |

Outros derivados: `willRunAgain` = ativa **e** não pontual; `openReasonsByDefault` = pontual **e** já rodou (abre o acordeão "Ver motivos" automaticamente).

⚠️ O hook ainda expõe 4 campos marcados `@deprecated` (`state`, `heroLabel`, `funnel`, `showEstimate`) de um contrato anterior, com um shim `resolveLegacyState` que reproduz a lógica antiga. **O modal atual já não os usa.** É código morto a ser removido; o redesign não deve reintroduzir esse vocabulário.

#### Bloco B — Funil de elegibilidade

Componente: `src/components/campaigns/preview/CampaignFunnelReal.tsx`. Dados: `useCampaignFunnel` (`src/hooks/useCampaignFunnel.ts`), que lê `campaign_logs`.

Sete linhas, todas no **mesmo nível visual** (comentário do código: cada exclusão é uma fatia separada e aditiva do topo, não subconjunto de outra — por isso sem indentação):

| Ordem | Rótulo | Campo em `campaign_logs` |
|---|---|---|
| 1 | **Total** | soma dos 6 abaixo |
| 2 | − Deduplicado | `skipped_duplicates` |
| 3 | − Dedup entre campanhas | `skipped_cross_integration` |
| 4 | − Cooldown | `skipped_cooldown` |
| 5 | − Prioridade | `skipped_higher_priority` |
| 6 | − Blocklist | `skipped_blocklist` |
| 7 | **= Elegível** | `actions_created` |

Anatomia de cada linha: `flex items-center gap-3`

```
[ rótulo (w-36, alinhado à direita, truncate) + HelpTip "?" ]
[ barra flex-1: trilho h-7 rounded-sm bg-muted, preenchimento colorido ]
[ delta (w-16, alinhado à direita) ]
```

| Linha | Cor da barra | Peso do número |
|---|---|---|
| Total | `bg-primary/60`, largura 100% | `font-medium`, `text-primary-foreground` |
| Exclusões | `bg-primary/30` | `font-medium`, `text-foreground` |
| Elegível | `bg-primary` (cheio) | `font-semibold`, `text-primary-foreground` |

Regras de renderização das barras:

- A barra de cada linha de exclusão mostra o **remanescente após a subtração**, não o valor subtraído. O valor subtraído aparece à direita, em `text-destructive`, como `−{n}` (só quando > 0).
- Largura = `max(valor / total × 100, 2)%`, ou `0%` se valor ≤ 0. O piso de 2% garante barra visível em valores pequenos.
- O número fica **dentro** da barra se a largura passar de 15%; abaixo disso, é posicionado absolutamente à direita do trilho.
- Todos os números com `toLocaleString("pt-BR")`. Transição `duration-500`.

Rodapé do card:

```
[CheckCircle2 text-primary] "Bate com a tela de Ações"     [Ações ↗]
```

O botão "Ações" (`variant="link"`, `data-testid="funnel-open-actions"`) fecha o modal e navega para `/actions` com os parâmetros:

| Parâmetro | Valor |
|---|---|
| `campaignId` | id da campanha |
| `startDate` / `endDate` | data BRT de hoje se `ranToday`; senão a data BRT de `lastCompletedAt` |

Os nomes dos parâmetros são os mesmos que a tela de Ações usa (`generateReportUrl` em `ActionsPage.tsx`). **Esse link é o contrato de reconciliação 1:1** — o número "Elegível" tem que bater com a contagem da tela de Ações naquele recorte.

**Empty-states do bloco B** — o texto muda por estado (função `funnelEmptyState`):

| Condição | Mensagem | Dica |
|---|---|---|
| `status === "draft"` | "Rascunho — nunca disparou" | "Ative a campanha para gerar ações; o funil real aparece após a primeira ativação." |
| Com régua, nunca rodou, status `active` | "Ainda não executou" | "O funil real aparece após a primeira ativação da campanha." |
| Com régua, nunca rodou, outros status | "Nunca executou" | idem |
| Sem régua (manual/broadcast) | "Manual — ainda não disparada" | "O funil real aparece após o primeiro disparo manual da campanha." |
| Fallback | "Sem execução registrada" | "O funil real aparece após a primeira ativação da campanha." |

Visual: caixa `border-dashed py-8`, ícone `Info size-5`, mensagem em `text-sm font-medium`, dica em `text-xs text-muted-foreground`.

⚠️ O componente `CampaignFunnelReal` tem um empty-state próprio (quando `!data.hasData`) com o texto fixo "Ainda não executou" — mas ele nunca é alcançado pelo modal, porque o modal só o renderiza quando `heroFunnel` existe. Código redundante.

#### Bloco C — Estimativa da próxima ativação

Cartão com `CardTitle` `Sparkles text-primary` + `estimate.label`, e `border-primary/40` quando `isHero`.

Três formas possíveis:

**(a) Não aplicável** (manual/broadcast) — parágrafo:

> "Esta campanha é de disparo sob demanda — não há projeção automática de volume. Os números acima vêm da execução real."

**(b) Herói** (`isHero`, ativa e nunca rodou) — `grid grid-cols-2 md:grid-cols-3`:

| Métrica | Formato | Rótulo (com HelpTip) |
|---|---|---|
| `~{totalActions}` | `text-3xl font-bold text-primary` | "~N ações estimadas" |
| `{totalEligibleContacts}` | `text-2xl font-bold` | "Contatos elegíveis" |
| `{DollarSign} {custo}` | `text-2xl font-bold text-emerald-600` (dark: `emerald-400`); `—` se nulo | "Custo estimado" |

Cada célula troca o número por um `Loader2` girando enquanto `isLoading`.

**(c) Secundário** (ativa que já rodou) — linha compacta `flex flex-wrap items-baseline`:

```
~{totalActions}   (text-2xl font-bold text-primary)
"ações estimadas · {contatos} contatos elegíveis · {custo}"   (text-xs muted)
```

As formas (b) e (c) terminam com a **mesma ressalva literal**:

> "É uma projeção ao vivo; pode divergir do que foi/será disparado (régua e carteira mudam entre execuções, e não desconta cooldown/prioridade/dedup)."

Origem dos números: `useCampaignPreview(campaign, open && estimate.applicable)` → RPC **`evaluate_campaign_preview_batch`** com `p_schema_name` e `p_campaign_ids`. O hook só é habilitado quando `campaign_type !== "broadcast"` **e** `target_reguas.length > 0`. Cache `staleTime` de 5 min, `retry: 1`.

Custo: `calculateEstimatedCost(actionsByStepType, channelCosts)` — ver §10. Só calcula quando há `channelCosts` e ao menos um step-type.

Erro do preview aparece **acima do bloco B**, como faixa `border-destructive/50 bg-destructive/10`: "Erro ao carregar prévia: {mensagem}".

#### Bloco D — Andamento dos envios

Componente: `src/components/campaigns/preview/CampaignActivityMatrix.tsx`. Dados: `useCampaignActivity(campaign.id)` → duas chamadas paralelas à RPC **`get_filtered_action_stats`** (uma com janela do dia BRT, outra sem janela). `staleTime` 30 s.

Enquanto não há dado: caixa `rounded-md border p-6` centralizada, `Loader2` + "Carregando andamento...".

Estrutura:

```
[Andamento dos envios]  + HelpTip
├── ScopeProgress "Hoje"
└── ScopeProgress "Total da campanha"
└── StatusDetailExpander "Ver todos os status (N)"
```

**`ScopeProgress`** — um bloco por escopo temporal:

Se `scope.total === 0`, renderiza só o rótulo + uma linha de vazio:

| Escopo | Mensagem vazia |
|---|---|
| Hoje | "Nenhuma ação hoje — a campanha não rodou hoje ou está fora da janela de execução." |
| Total da campanha | "Nenhuma ação gerada até agora." |

Com dados:

```
{label} — Total real: {n} ação|ações

Envios ativos  + HelpTip
  [ProgressMulti com 3 segmentos]
  legenda: ● Enviado {n}   ● Pendente {n}   ● Falhas {n} + HelpTip

Engajamento: Em Atendimento {n} · Solicitou Atendimento {n} · Interagiu {n}   + HelpTip
Não enviadas: Canceladas {n} · Duplicadas {n} [· Outros {n}]                   + HelpTip
(Custo: {BRL})  ← só se `cost` for fornecido
```

**Cores dos segmentos** (tokens reaproveitados do `SendingProgressCard` da tela de Ações — o código é explícito: "nada de hex"):

| Segmento | Rótulo | Classe |
|---|---|---|
| `enviado` | Enviado | `bg-primary` |
| `pendente` | Pendente | `bg-amber-500` |
| `falhou` | **Falhas** (plural, porque agrega dois status) | `bg-destructive` |

A barra é **proporcional ao subtotal de envios ativos**, não ao total do escopo. Se `enviosTotal === 0`, a barra some e aparece "Nenhum envio ativo neste escopo.".

**Mapeamento status → balde** (`mapStatsToActivity` em `src/hooks/useCampaignActivity.ts`) — os baldes são **disjuntos** e somam exatamente o total real:

| Balde | Status canônicos agregados |
|---|---|
| `enviado` | Enviado |
| `pendente` | Pendente + Processando |
| `falhou` | Falhou + Falha Permanente |
| `emAtendimento` | Em Atendimento |
| `respondido` | Respondido |
| `interagiu` | Interagiu |
| `cancelada` | Cancelado + Cancelado (Pago) + Cancelado (Removido) |
| `duplicada` | Duplicado |
| `outros` | qualquer status não reconhecido (nunca descartado) |

Partição declarada no código: `Envios ativos + Engajamento + Não enviadas = total`.

**`StatusDetailExpander`** — `Collapsible` com trigger "Ver todos os status ({N})" e chevron que gira 180° ao abrir. Mostra o detalhe por status **cru**, agrupado:

| Grupo | Status listados |
|---|---|
| **Envios (pipeline de despacho)** | Enviado, Pendente, Processando, Falhou, Falha Permanente |
| **Engajamento (o contato reagiu)** | Interagiu, Respondido, Em Atendimento |
| **Não enviadas** | Cancelado (Pago), Cancelado (Removido), Cancelado, Duplicado |
| **Outros** | status desconhecidos, ordenados por Total desc |

Cada linha: `{rótulo de exibição} [?]` à esquerda; `Hoje {n}  Total {n}` à direita, `tabular-nums`. Só aparecem status com contagem > 0 em Hoje **ou** Total. Se nenhum, o expander inteiro some.

⚠️ Os rótulos de **exibição** diferem dos valores canônicos (Regra 11 do `CLAUDE.md` da Torre): `Falhou` → "Falha Temporária de Ação", `Falha Permanente` → "Falha Definitiva de Ação", `Respondido` → "Solicitou Atendimento". A fonte única é `src/lib/constants/action-status-display.ts`. O redesign **não pode** trocar rótulo por valor.

⚠️ **Custo realizado não é exibido.** O modal passa `costHoje={undefined}` e `costTotal={undefined}` com um comentário explícito: "Custo realizado por canal não é confiável a partir do status → passamos undefined (o custo é omitido, sem '—'). NÃO inventar." O redesign não deve preencher esse buraco com número estimado.

#### Bloco E — Detalhes

`grid gap-4 md:grid-cols-2` com dois cartões:

**Motivo dominante** — derivado do funil real. Pega o maior entre `deduplicado`, `crossCampanha`, `cooldown`, `prioridade`, `blocklist` e calcula sua fatia do total de exclusões (`total − elegivel`).

| Estado | Texto |
|---|---|
| Há exclusões | "**{pct}%** das exclusões foram **{rótulo}**." (percentual em `text-2xl font-bold text-primary`) |
| Sem exclusões | "Sem exclusões registradas para detalhar." |

Rótulos usados (`EXCLUSION_LABELS` local do modal): `deduplicação`, `dedup entre campanhas`, `cooldown`, `prioridade`, `blocklist`.

**Distribuição por canal** — só aparece quando `estimate.applicable` e há step-types com contagem > 0. `flex flex-wrap gap-2` de `Badge outline` no formato `{rótulo}: {n}`.

Rótulos (`ACTION_TYPE_LABELS` local do modal):

| Chave | Rótulo |
|---|---|
| `send_email` | E-mail |
| `send_whatsapp` | WhatsApp |
| `send_rcs` | RCS |
| `send_sms` | SMS |
| `notification` | Notificação |
| `negativation` | Negativação |

Chave não mapeada aparece com o valor cru.

**"Ver motivos (por título)"** — acordeão que abre o `CampaignReasonsDrilldown` (§7.3), montado com `runIds` do funil herói. Abre automaticamente quando `openReasonsByDefault`.

- Quando `runIds.length === 0`, o acordeão é substituído por uma caixa `border-dashed`: "Sem execução registrada para detalhar motivos por título."
- O `HelpTip` fica como **irmão** do trigger, nunca dentro dele (comentário do código: "nunca botão-dentro-de-botão") — é um requisito de acessibilidade a preservar.

#### Bloco F — Legado (só com estimativa aplicável)

Quando `!estimate.applicable`, o bloco inteiro vira uma linha: "Distribuição por dia de atraso e alertas de janela não se aplicam a disparo manual/pontual."

**Alerta "Fora da Janela de Execução"** — `Alert` âmbar (`border-amber-200 bg-amber-50`, dark `bg-amber-950/30`), ícone `Timer`:

```
Título: "Fora da Janela de Execução" + HelpTip
Corpo:  {executionWindow.reason}
        "As ações serão criadas como **diferidas** e executadas em: {próximo slot}"
```

Formato de `reason` (gerado em `checkExecutionWindow`):

| Causa | Texto |
|---|---|
| Dia fora dos dias ativos | `Dia atual ({n}) não está nos dias ativos: [{lista}]` |
| Horário fora da janela | `Horário atual ({HH:MM}) fora da janela: {start} - {end}` |

⚠️ O texto expõe o **número** do dia da semana (`Dia atual (0)`), não o nome. Defeito de copy a corrigir.

Formato do próximo slot: `toLocaleString("pt-BR", { weekday: "long", day: "2-digit", month: "2-digit", hour: "2-digit", minute: "2-digit" })`.

**Alerta "Data Bloqueada"** — `Alert` vermelho (`border-red-200 bg-red-50`), ícone `CalendarOff`:

> "Hoje e uma data bloqueada: **{nome}**. Campanhas nao serao executadas ate a proxima data valida."

⚠️ Sem acentuação no código. Corrigir.

Origem: consulta a `blocked_dates` da org filtrando `blocked_date = hoje (BRT)` e `is_active = true`.

**Tabela "Distribuição por Dia de Atraso (estimativa)"** — só quando `!isLoading && !error && breakdown.length > 0`. `ScrollArea` de altura fixa `300px` dentro de `rounded-md border`.

| Coluna | Largura | Conteúdo |
|---|---|---|
| **Dia** | `w-[100px]` | Badge com `D{n}` negativo / `D0` / `D+{n}` |
| **Contatos** | `w-[120px]`, à direita | `contactCount` em `font-medium`, `pt-BR` |
| **Steps Acionados** | resto | até 3 badges + `+{n}` de excedente |

Variante do badge de Dia:

| `daysOverdue` | Variante | Classe extra |
|---|---|---|
| < 0 (preventivo) | `secondary` | — |
| = 0 (vencimento) | `outline` | — |
| > 0 (atrasado) | `default` | `bg-orange-100 text-orange-700 border-orange-200` |

Os badges de step usam os **nomes** dos steps quando existem; se todos vierem vazios, caem para os rótulos de `ACTION_TYPE_LABELS` sobre os `stepTypes`.

#### Rodapé

`flex justify-end px-6 py-4 border-t shrink-0` com um único botão **Fechar** (`variant="outline"`). Nenhuma ação de escrita sai deste modal.

#### Defaults de janela usados pela prévia

`src/hooks/useCampaignPreview.ts` declara fallbacks que espelham o backend (`scheduled-action-processor:isWithinExecutionWindow`) — o redesign precisa saber que campanha com campo nulo **não** é "sem janela":

| Campo nulo/vazio | Fallback |
|---|---|
| `active_days` | `[1,2,3,4,5,6]` (seg-sáb) |
| `start_time` | `08:00:00` |
| `end_time` | `18:00:00` |
| `timezone` | `America/Sao_Paulo` |

### 7.2 `CampaignDryRunDialog` — "Ensaiar campanha"

Fonte: `src/components/campaigns/CampaignDryRunDialog.tsx`.

**Objetivo.** Rodar os passos 1 a 5 do pipeline v2 e mostrar o que a campanha faria, sem criar nenhuma ação.

**Gatilho.** Item "Ensaiar (não cria ações)" do menu da visão grade, ou botão "Ensaiar" no cabeçalho do `CampaignDetailDialog`. Fechado quando `campaign === null`.

**Contêiner.**

```
<DialogContent className="flex h-[90vh] w-[95vw] max-w-3xl flex-col gap-0 overflow-hidden p-0">
```

**Cabeçalho** (`shrink-0 border-b px-6 py-4`):

```
[FlaskConical text-amber-600] "Ensaiar campanha"  [Badge âmbar "não cria ações"]
DialogDescription: "{nome da campanha} — veja o que a campanha faria, sem disparar nada."
```

**Bloco de garantias** — `Alert` esmeralda (`border-emerald-500/40 bg-emerald-500/5`), ícone `ShieldCheck`, título "**É um ensaio — nada é enviado**". **Sempre visível, inclusive depois de rodar.** Lista de 3 itens (`DRY_RUN_GUARANTEES`):

| Título (negrito) | Corpo |
|---|---|
| **Nenhuma ação é criada** | "O ensaio executa os 5 primeiros passos do pipeline (resolver contatos, buscar títulos, casar com os steps, aplicar regras e deduplicar) e para antes do passo que grava em Ações." |
| **Não consome a execução do dia** | "O agendador ignora ensaios nos dois testes que evitam disparo repetido — o limite de uma execução por dia e a janela de 5 minutos. A campanha real continua no horário dela." |
| **Não mexe no card "Ações previstas"** | "Aquele funil é montado a partir do registro de execução, que só o passo omitido escreve. O ensaio aparece apenas no painel de Monitoramento, com o selo 'Prévia'." |

Comentário do código sobre por que o ensaio **não** roda ao abrir: "o motivo pelo qual ninguém usa uma prévia é o medo de 'gastar' o disparo do dia. Se o ensaio começasse na abertura, as três garantias abaixo seriam lidas DEPOIS do susto — ou não seriam lidas." **Regra de produto a preservar.**

**Caso "não suportado"** — quando `!campaignSupportsDryRun(campaign)`, o corpo vira um `Alert` âmbar "**Ensaio indisponível para esta campanha**" com um de dois textos:

| Causa | Texto |
|---|---|
| `campaign_type === "broadcast"` | "Disparos em massa (broadcast) são processados por outro motor, que não tem modo de ensaio." |
| `use_pipeline_v2 !== true` | "Só campanhas do pipeline v2 têm ensaio — esta campanha usa o executor antigo." |

**Botão de ação.** Rótulo dinâmico:

| Estado | Ícone | Rótulo |
|---|---|---|
| Ocioso, sem resultado | `FlaskConical` | **Rodar ensaio** |
| Rodando | `Loader2` girando | **Rodando ensaio...** (`disabled`) |
| Já rodou | `FlaskConical` | **Rodar ensaio novamente** |

Ao lado, quando há duração: "concluído em {n}s" (uma casa decimal).

**Estados do ensaio:**

| Estado | Visual |
|---|---|
| Rodando | Caixa `rounded-md border p-4` com "Rodando os passos 1 a 5 do pipeline..." + 2 `Skeleton` |
| Erro | `Alert variant="destructive"` "**Não foi possível concluir o ensaio**" + mensagem + botão "Tentar novamente" (persistente, além do toast) |
| `no_campaigns` | `Alert` "**Nada para ensaiar**" / "Nenhuma campanha elegível para hoje — nenhum candidato foi produzido, então não há resultado para detalhar." |
| `timeout_partial` | `Alert` âmbar, `Timer`, "**Ensaio parcial**" / "O ensaio parou em **{passo}** por tempo de execução. Nenhuma ação foi criada. Os números abaixo são parciais — rode novamente para um resultado completo." |
| `dry_run_completed` | `DryRunResultBody` (abaixo) |

**Resultado (`DryRunResultBody`).** Cartão "O que a campanha faria" (`CheckCircle2` esmeralda), com **6 métricas** em `grid grid-cols-2 sm:grid-cols-3`, valor em `text-lg font-semibold tabular-nums`:

| # | Rótulo (literal, sem acento no código) | Campo do run | Destaque |
|---|---|---|---|
| 1 | Contatos elegiveis | `total_eligible_contacts` | — |
| 2 | Titulos avaliados | `total_titles_fetched` | — |
| 3 | Casaram um step | `total_matches` | — |
| 4 | Passaram pelas regras | `matches_after_rules` | — |
| 5 | **Acoes que seriam criadas** | `matches_after_cross_dedup` | `text-primary` |
| 6 | Acoes criadas agora | sempre `0` (contrato do ensaio) | — |

Valor ausente aparece como `-`. Enquanto carrega, 6 `Skeleton`. Em erro, mensagem + "Tentar novamente".

Nota de rodapé: "Ensaio `{8 primeiros caracteres do run_id}` · o rastro por título fica disponível por 48 horas (limpeza automática dos candidatos)."

Comentário relevante: os números vêm da **linha de `campaign_execution_runs`** (a mesma que o `PipelineRunStatusCard` mostra), não do `results` cru das RPCs — "assim o ensaio e o painel de monitoramento nunca divergem".

Abaixo: "**Motivos por título**" com o `CampaignReasonsDrilldown`, montado com `includeTransientDispositions` — ver §7.3.

**Contrato de resposta do ensaio** (`useCampaignDryRun` em `src/hooks/useCampaigns.ts`):

| `status` | Significado | `runId` | `durationMs` |
|---|---|---|---|
| `dry_run_completed` | rodou até o passo 5 | preenchido | preenchido |
| `no_campaigns` | nenhuma campanha elegível hoje (**nenhum run é criado**) | `null` | `null` |
| `timeout_partial` | parou por tempo, retomável | preenchido | `null` |

Validação defensiva do hook: se a resposta não trouxer `dry_run === true` **ou** `actions_created !== 0`, lança "Resposta incompatível com a prévia. Atualize a página e tente novamente após a publicação terminar." Se o status for outro, lança `A função de campanhas respondeu "{x}" em vez de "dry_run_completed". A prévia não foi concluída. Aguarde e tente novamente.`

Erro do Edge Function é desembrulhado por `readEdgeFunctionError`, produzindo `Prévia falhou no passo "{failed_step}": {detalhe}` — sem isso o usuário veria "non-2xx status code".

Toasts do ensaio:

| Situação | Título | Descrição |
|---|---|---|
| `no_campaigns` | "Nada para ensaiar" | "Nenhuma campanha elegível para hoje — a prévia não gerou candidatos." |
| `timeout_partial` | "Prévia parcial" | `A prévia parou em "{passo}" por tempo. Nenhuma ação foi criada; rode novamente para continuar.` |
| Sucesso | "Prévia concluída" | "Nenhuma ação foi criada. Veja abaixo o que a campanha faria." |
| Erro | "Erro na prévia" | mensagem do erro (destructive) |

Invalidação de cache após o ensaio: apenas `campaign-execution-runs` e `campaign-execution-run/{id}`. **`campaign-funnel` e `campaigns-with-runs` não são invalidados** — leem `campaign_logs`, que o ensaio não escreve.

### 7.3 `CampaignReasonsDrilldown` — motivos por título

Fonte: `src/components/campaigns/preview/CampaignReasonsDrilldown.tsx`. Usado em **dois lugares**: dentro do acordeão do modal de prévia e dentro do resultado do ensaio.

**Recorte.** Recebe `runIds[]` (ordenados por recência) e usa **apenas `runIds[0]`** — a última run. Quando há mais de uma:

> Faixa âmbar (`border-amber-500/40 bg-amber-500/5`) com `Info`: "Este escopo tem {N} execucoes. Exibindo apenas a **ultima ativacao** ({8 chars}...)."

**Escopo vazio** (`runIds` vazio): caixa `border-dashed py-10` com `Info`, "Nenhuma execucao registrada para esta campanha ainda." + "Os motivos por titulo aparecem apos a primeira ativacao."

**Barra de filtro:**

```
[ListFilter] [Select h-8 w-56 "Todos os motivos"]  "{N} titulo(s)" + HelpTip
```

O `Select` lista "Todos os motivos" + uma opção por disposição de `DISPOSITION_LABELS`, **na ordem de declaração do objeto** (o código avisa que mexer na ordem muda a tela de quem já usa). Trocar o filtro reseta a página para 0.

**Nota de rodapé**, que muda por modo:

| Modo | Texto |
|---|---|
| Execução real (default) | "Exclusões por dedup de integração e 'sem step' não são detalháveis (removidas do histórico após a execução)." |
| Ensaio (`includeTransientDispositions`) | "Como este é um ensaio, 'sem step compativel' e 'dedup por integração' também aparecem — numa execução real essas linhas são removidas do histórico ao final." |

Em execução real, `dedup_integration` e `no_step_match` são **removidas do dropdown** (`NON_DETAILABLE_DISPOSITIONS`), porque o `DELETE` final do `create_actions` apaga essas linhas e o filtro sempre devolveria 0. `pending` continua listada. As demais exclusões **sobrevivem** e são filtráveis.

**Tabela** (`rounded-md border`), 4 colunas:

| Coluna | Conteúdo |
|---|---|
| **Contato / Titulo** | `font-mono text-xs`: `{8 chars do contact_id}...` + ` · {8 chars do title_id}...` (o título só aparece se existir) |
| **Dias em atraso** | `tabular-nums`, alinhado à direita; `-` quando nulo |
| **Motivo** | `Badge outline` com rótulo e cor da disposição (§9) |
| **Detalhe** | `max-w-[280px] text-xs text-muted-foreground`, texto formatado (abaixo) |

Estados da tabela:

| Estado | Visual |
|---|---|
| Carregando | 5 linhas com `Skeleton` de largura total |
| Erro | `AlertCircle` + mensagem + botão "Tentar novamente" |
| Vazio | "Nenhum titulo encontrado para este motivo." |

**Paginação:** 50 itens por página, só aparece quando há mais de uma página. "Pagina {n} de {N}" à esquerda; dois botões de seta (`ChevronLeft`/`ChevronRight`) à direita. Ordenação fixa: `days_overdue` desc, nulos por último.

**Coluna "Detalhe" — tradução dos motivos.** O pipeline grava `disposition_details.reason` em inglês; o componente traduz. Tabela completa (`REASON_LABELS`):

| `reason` gravado (inglês) | Texto exibido |
|---|---|
| `contact on blocklist` | Contato na blocklist |
| `contact received same channel within cooldown` | Contato recebeu o mesmo canal dentro do cooldown |
| `action for same step already exists` | Ja existe acao para o mesmo step |
| `contact already actioned for more overdue title via same channel` | Contato ja acionado por titulo mais atrasado no mesmo canal |
| `another title with higher days_overdue won for same contact+channel+integration` | Outro titulo mais atrasado venceu o mesmo contato/canal/integracao |
| `another campaign won for same contact+channel+integration` | Outra campanha venceu (dedup entre campanhas) |
| `title is not the highest days_overdue in its scope` | Titulo nao e o de maior atraso no escopo |
| `step cadence window has not elapsed` | Intervalo minimo do step ainda nao completou desde o ultimo envio |
| `step is fire_once and an action already exists for this contact+step` | Step de disparo unico — o contato ja recebeu esta acao |
| `daily action cap for the contact was reached` | Teto diario de acoes do contato foi atingido |
| `step requires recipient: variable but the resolved address does not match the channel shape` | Endereco resolvido nao tem a forma do canal (step com destinatario por variavel) |
| `communication step has no recipient address for channel {canal}` (prefixo) | Contato sem endereco para o canal {canal} |

Motivo não mapeado aparece **cru, em inglês**.

**Sufixos ("extras") anexados entre parênteses**, quando os campos existem em `disposition_details`:

| Campo | Texto |
|---|---|
| `cooldown_hours` | `janela {n}h` |
| `winner_campaign_id` | `campanha vencedora {8 chars}...` |
| `winner_days_overdue` | `{n} dias de atraso` |
| `max_days_overdue` | `maior atraso do escopo: {n}` |
| `scope === "contact"` | `escopo do contato` |
| `scope === "contract"` | `escopo do contrato` |
| `repeat_every_days` | `intervalo minimo de {n} dia(s)` |
| `daily_cap` | `teto de {n} por dia` |
| `already_created_today` | `{n} ja criada(s) hoje` |

Sem `reason` e sem extras, a célula mostra o **JSON cru** (`JSON.stringify(details)`). Sem `disposition_details`, mostra `-`.

⚠️ Praticamente **todos os textos deste componente estão sem acentuação** ("Nenhuma execucao", "titulo(s)", "Ja existe acao"). É o pior caso de copy do domínio e deve ser corrigido no redesign.

---

## 8. Monitoramento de execução

Aba **Monitoramento** de `/campaigns`. Componente raiz: `src/components/campaigns/ExecutionMonitoringPanel.tsx` (642 linhas).

### 8.1 Estrutura da aba

```
<div className="space-y-6">
├── Card "Pipeline v2 — Hoje"          ← só se há runs hoje
│     └── N × <PipelineRunStatusCard>
├── grid de 4 KPIs (md:grid-cols-2 lg:grid-cols-4)
├── Card "Histórico de Execuções"
│     ├── filtros (busca + status)
│     └── tabela em ScrollArea h-[500px]
├── <CampaignLogDetailDialog>           ← sempre montado
└── <CancelCampaignActionsDialog>       ← montado só com alvo escolhido
```

Duas fontes de dados independentes:

| Bloco | Hook / query | Tabela | Limite | Auto-refresh |
|---|---|---|---|---|
| Pipeline v2 — Hoje | `useCampaignExecutionRuns({from: hoje, to: hoje})` | `campaign_execution_runs` | 50 | 30 s |
| KPIs + Histórico | query `all-campaign-logs` | `campaign_logs` + join `campaigns!inner` | **100** | 30 s |

A data "hoje" é calculada em BRT por aritmética UTC-3 (`getTodayDateString`), não por `Intl`.

⚠️ O join é `campaigns!inner` — **execução de campanha excluída desaparece da tabela**, ainda que a célula tenha um fallback "Campanha removida" que nunca é alcançado por esse caminho.

### 8.2 `PipelineRunStatusCard` — o cartão de run do lote

Fonte: `src/components/campaigns/execution/PipelineRunStatusCard.tsx`.

**Um cartão por run (lote), não por campanha.** O título é a lista de nomes das campanhas do lote, separados por vírgula (`campaign_ids` → `campaignNames`); id não resolvido aparece com os 8 primeiros caracteres.

**Os quatro estados do run** — esta é a parte mais importante da tela para o redesign:

| Estado | Condição | Ícone | Badge | Borda do card |
|---|---|---|---|---|
| **Falhou** | `current_step === "failed"` | `XCircle` destrutivo | `destructive` "Falhou" | `border-destructive/50` |
| **Concluido** | `current_step === "completed"` | `CheckCircle2` verde | `default` "Concluido" | padrão |
| **Travado** | não terminal **e** sem progresso há > 15 min | `AlertTriangle` âmbar | `secondary` + `border-amber-500 text-amber-600`, texto "Travado" | `border-amber-400` |
| **Em andamento** | não terminal e com heartbeat recente | `Loader2` azul girando | `secondary` "Em andamento" | `border-blue-300` |

Detecção de travamento (`isStaleRun`): lê `heartbeat_at` com **fallback para `started_at`** (um run que morreu antes de fechar o primeiro passo nunca recebeu heartbeat). Limiar: `STALE_RUN_MS = 15 min`, espelhando o `STALE_RUN_MINUTES` do watchdog em `campaign-logs-cleanup`.

O comentário do código explica a origem: "Sem isto, um run morto aparece com o mesmo spinner azul de 'Em andamento' indefinidamente — foi o que a tela mostrou por **2h40 em 26/08/2026**, enquanto as 7 campanhas de org_blips não geravam nenhuma ação." **Este estado não pode ser removido no redesign.**

**Badges adicionais** na mesma linha do título:

| Badge | Condição | Visual |
|---|---|---|
| `FlaskConical` + **"Prévia — nenhuma ação criada"** | `is_dry_run === true` | `outline`, âmbar (`border-amber-500/40 bg-amber-500/10`) |
| **"{n} retentativa(s)"** | `retry_count > 0` | `outline` |

Comentário sobre o selo de prévia: a prévia cria uma linha real, concluída e com 0 ações — "sem o selo, o operador leria 'a campanha rodou e não fez nada'".

**Linha de metadados** (`text-xs text-muted-foreground`): `{HH:mm de início}` · `{duração}` · `{n} acoes` (só quando `actions_created > 0`, em `text-primary font-medium`).

**Botões**, à direita:

| Botão | Condição | Comportamento |
|---|---|---|
| **Retry** (`RotateCcw`) | `isFailed \|\| isStale` | invoca a Edge Function com `{ run_id }`; endpoint é `campaign-pipeline-preview` se `is_dry_run`, senão `campaign-pipeline-orchestrator`. Vira `Loader2` + `disabled` enquanto roda |
| Chevron (`ChevronDown`/`ChevronUp`) | sempre | expande/recolhe o detalhe |

Toasts do retry:

| Resultado | Título | Descrição |
|---|---|---|
| OK | "Pipeline re-iniciado" | "O orchestrator foi acionado com sucesso." |
| Erro | "Erro ao re-iniciar" | mensagem do erro (destructive) |

⚠️ O botão não tem gate de permissão. Qualquer perfil que veja a aba pode reiniciar um run.

**Trilha de 6 passos** — `flex items-center gap-1`, cada passo com ícone `h-3.5 w-3.5` + rótulo `text-[10px]`, ligados por traços de 12 px (`w-3 h-px`):

| Estado do passo | Ícone | Cor do texto | Cor do traço à esquerda |
|---|---|---|---|
| Concluído (`idx < completedStepIdx`) | `CheckCircle2` verde | `text-green-600` | `bg-green-400` |
| Falhou (`isFailed && idx === completedStepIdx`) | `XCircle` destrutivo | `text-destructive` | `bg-destructive` |
| Atual (`isRunning && idx === completedStepIdx`) | `Loader2` azul girando | `text-blue-600 font-medium` | `bg-border` |
| Pendente | `Circle` `text-muted-foreground/40` | `text-muted-foreground/50` | `bg-border` |

O tooltip de cada bolinha mostra a **chave técnica** do passo (`resolve_contacts`, `fetch_titles`, …).

Cálculo do índice de progresso (`completedStepIdx`):

| Situação | Valor |
|---|---|
| Concluído e **não** é prévia | `PIPELINE_STEPS.length` (6) → todos verdes |
| Concluído e **é** prévia | índice de `create_actions` (5) → **o último passo fica cinza** |
| Falhou com `error_details` parseável | índice extraído de `/Step (\w+) failed/` |
| Falhou sem parse | índice de `current_step` |
| Em andamento | índice de `current_step` |

O teto da prévia é deliberado: a prévia é fechada com `current_step = 'completed'` para o auto-resume não reabrir a linha, mas `create_actions` não rodou — "sem o teto aqui, a trilha marcaria 'Criar' em verde — a única coisa que a prévia provadamente não fez".

⚠️ `extractFailedStep` faz regex sobre `error_details` procurando `Step <passo> failed`. Esse formato é **contrato com o backend** (Regra 39 do `CLAUDE.md` da Torre), não texto livre. O redesign não pode mudar a forma como esse campo é exibido sem alinhar com o time técnico.

**Painel expandido** (`mt-3 pt-3 border-t`):

1. **Nota de prévia** (só se `is_dry_run`): "Prévia: os passos 1 a 5 rodaram e o passo que cria as ações foi omitido. **Apos dedup** é quantas ações seriam criadas. Este ensaio não conta como a execução do dia."

2. **Grade de 6 métricas** (`grid grid-cols-3 gap-2 text-xs`):

| Rótulo | Campo do run | Destaque |
|---|---|---|
| Contatos | `total_eligible_contacts` | — |
| Titulos | `total_titles_fetched` | — |
| Matches | `total_matches` | — |
| Apos regras | `matches_after_rules` | — |
| Apos dedup | `matches_after_cross_dedup` | `text-primary` **se é prévia** |
| Acoes / **Acoes (nao criadas)** | `actions_created` | `text-primary` **se não é prévia** |

O rótulo da 6ª métrica muda para "Acoes (nao criadas)" em prévia, e o destaque migra para "Apos dedup". Valor nulo → `-`.

3. **Linha de pulados** — só se algum for > 0. Formato: `**Pulados:** {n} blocklist, {n} cooldown, {n} step dup, {n} prioridade, {n} cross-campaign` (só os não-zero).

4. **Erro** — caixa `bg-destructive/5` com `AlertTriangle` e os primeiros **300 caracteres** de `error_details` (`break-all`).

⚠️ Todos os rótulos deste cartão estão **sem acentuação** (`Titulos`, `Apos regras`, `Acoes`, `Concluido`). Corrigir no redesign.

### 8.3 KPIs agregados

`grid gap-4 md:grid-cols-2 lg:grid-cols-4`. Cada card: `CardHeader` com título `text-sm font-medium` + ícone `h-4 w-4 text-muted-foreground`; valor `text-2xl font-bold`.

| # | Título | Ícone | Valor | Subtexto |
|---|---|---|---|---|
| 1 | **Execuções** | `Activity` | `logs.length` | "últimas 100 execuções" |
| 2 | **Taxa de Sucesso** | `TrendingUp` | `{n}%` em `text-primary` | "execuções bem-sucedidas" |
| 3 | **Ações Criadas** | `Zap` | `Σ actions_created` | `{n} contatos` + badges (abaixo) |
| 4 | **Tempo Médio** | `Clock` | `{m}m {s}s` ou `{s}s` | "por execução" |

Fórmula da taxa de sucesso: `(completed + completed_with_errors) / (completed + completed_with_errors + failed) × 100`, arredondado.

⚠️ O denominador **ignora** `running`, `pending` e `superseded`. Um dia inteiro de runs `running` não muda a taxa. E `completed_with_errors` conta como **sucesso** aqui, mas **não** conta como sucesso no KPI equivalente do `CampaignDetailDialog` (§6.4). Duas definições de "sucesso" no mesmo produto.

Badges do card 3 (aparecem só quando > 0):

| Badge | Fórmula | Visual |
|---|---|---|
| `{n} pulados` | soma de `skipped_duplicates + cooldown + blocklist + cross_integration + higher_priority` | `outline` padrão |
| `{n} já contatados` | `Σ skipped_already_contacted` | `outline` âmbar (`bg-amber-50 border-amber-200 text-amber-700`) |

⚠️ A soma de "pulados" do KPI **não inclui** `skipped_already_contacted`, mas a soma da coluna equivalente na tabela (§8.4) **inclui**. Números diferentes na mesma tela.

Tempo médio: média de `completed_at − started_at` sobre os logs que têm `completed_at`, em segundos. Exibido como `{m}m {s}s` acima de 60 s.

⚠️ Todos os quatro KPIs são calculados sobre **os últimos 100 logs**, sem recorte de período. Só o card 1 avisa isso.

### 8.4 Histórico de Execuções

Card com `CardTitle` `BarChart3 h-5 w-5` + "Histórico de Execuções" e um `RefreshButton` (`outline`, rótulo "Atualizar") à direita.

**Filtros** (`flex gap-4 mb-4`), ambos **client-side** sobre os 100 logs já carregados:

| Controle | Tipo | Efeito |
|---|---|---|
| **Buscar por campanha...** | `Input` com `Search` absoluto à esquerda (`pl-9`) | `includes` case-insensitive no nome da campanha |
| **Status** | `Select w-[180px]` | igualdade exata em `log.status` |

Opções do `Select`: `all` "Todos", `completed` "Concluído", `completed_with_errors` "Com erros", `failed` "Falhou", `running` "Executando", `pending` "Pendente", `superseded` "Substituído".

**Estados do corpo:**

| Estado | Visual |
|---|---|
| Carregando | `Loader2 h-8 w-8` centralizado, `py-12` |
| Vazio (após filtro) | `Activity h-12 w-12 text-muted-foreground/30`, "**Nenhuma execução encontrada**" + "As execuções aparecerão aqui quando as campanhas forem disparadas" |
| Com dados | tabela dentro de `ScrollArea h-[500px]` |

**Colunas da tabela:**

| # | Cabeçalho | Conteúdo |
|---|---|---|
| 1 | **Campanha** | nome, `font-medium max-w-[200px] truncate`; fallback "Campanha removida" |
| 2 | **Status** | `Badge outline` com cor + ícone de `LOG_STATUS_CONFIG` |
| 3 | **Tipo** | `Badge secondary` com o rótulo de `TRIGGER_TYPES[trigger_type]` (fallback: valor cru) |
| 4 | ícone `Users` (tooltip "Contatos processados") | `contacts_processed`, centro, `font-medium` |
| 5 | ícone `Zap` (tooltip "Ações criadas") | `actions_created`, centro, `font-medium text-primary` |
| 6 | ícone `SkipForward` (tooltip "Contatos pulados (total)") | badge com o total, ou `-` |
| 7 | ícone `AlertTriangle` (tooltip "Erros") | `Badge destructive` com `errors_count`, ou `-` |
| 8 | **Duração** | `calculateDuration(started_at, completed_at)` — `-` se não completou |
| 9 | **Iniciado em** | `dd/MM HH:mm` |
| 10 | (sem cabeçalho, `w-[52px]`) | botão `Ban` — **só se `actions:write`** |

⚠️ As colunas 4-7 têm **apenas ícone no cabeçalho**, com o significado escondido em tooltip. É um problema de acessibilidade e de escaneabilidade que o redesign deve resolver.

**Coluna 6 — tooltip de detalhamento.** O total soma **seis** campos: `skipped_duplicates`, `skipped_cooldown`, `skipped_blocklist`, `skipped_already_contacted`, `skipped_cross_integration`, `skipped_higher_priority`. O tooltip lista apenas os > 0, com rótulos:

| Rótulo no tooltip | Campo |
|---|---|
| Duplicados | `skipped_duplicates` |
| Cooldown | `skipped_cooldown` |
| Blocklist | `skipped_blocklist` |
| Já contatados | `skipped_already_contacted` |
| Cross-campaign | `skipped_cross_integration` |
| Prioridade | `skipped_higher_priority` |

**Coluna 7 — tooltip de erro.** Mostra os primeiros 200 caracteres de `error_details` (`max-w-[300px]`, `whitespace-pre-wrap`).

**Interações da linha:**

- `cursor-pointer hover:bg-muted/50`; clique abre o `CampaignLogDetailDialog`.
- O botão `Ban` da coluna 10 chama `e.stopPropagation()` — sem isso, cancelar abriria os dois ao mesmo tempo. Tooltip: "Cancelar ações pendentes desta campanha".

**Status de log** (`LOG_STATUS_CONFIG` deste arquivo — **difere do `CampaignDetailDialog`**):

| Valor | Rótulo aqui | Rótulo no `CampaignDetailDialog` | Ícone | Cores |
|---|---|---|---|---|
| `pending` | Pendente | Pendente | `Timer` | `bg-muted text-muted-foreground` |
| `running` | Executando | Executando | `PlayCircle` | azul |
| `completed` | Concluído | Concluído | `CheckCircle2` | verde |
| `completed_with_errors` | **Com erros** | **Concluído com erros** | `AlertCircle` | âmbar |
| `failed` | Falhou | Falhou | `XCircle` | `bg-destructive/10 text-destructive` |
| `superseded` | **Substituído** | *(não existe lá)* | `SkipForward` | `bg-slate-100 text-slate-600` |
| `deferred` | *(não existe aqui)* | **Agendado** | `Clock` | roxo |
| `failed_retrying` | *(não existe aqui)* | **Falhou (retry automático)** | `AlertCircle` | âmbar |

⚠️ **Dois catálogos de status de log, com rótulos e coberturas diferentes.** Um log `deferred` aparece como "Pendente" no Monitoramento e como "Agendado" no detalhe da campanha. Unificar é requisito do redesign.

### 8.5 `CampaignLogDetailDialog` — detalhe de uma execução

Fonte: `src/components/campaigns/CampaignLogDetailDialog.tsx`. Gatilho: clique numa linha do Histórico.

**Contêiner:** `w-full max-w-5xl max-h-[85vh] flex flex-col p-0 gap-0` — é o modal mais largo do domínio.

**A distinção central (IAF-6990).** `log` é `campaign_logs` (uma linha por **campanha**); `run` é `campaign_execution_runs` (uma linha por **lote**). Antes, título e identidade vinham do log enquanto KPIs, funil e candidatos vinham do run — "abrir qualquer uma das 7 campanhas do run de 26/08 mostrava os mesmos números sob 7 títulos diferentes". Hoje:

- Tudo que é da campanha sai de `buildCampaignFunnel(log)` (módulo puro, sem I/O).
- O lote vira **contexto explícito**, numa faixa recolhível.

`isV2` é derivado da existência de `log.metadata.run_id`. Sem ele, o modal cai no layout legado v1.

**Cabeçalho** (`px-6 py-4 border-b`):

```
[Activity h-4 w-4] {nome da campanha}          (text-base font-semibold)
[Badge de status] [Badge secondary "Pipeline v2"] {dd/MM/yyyy 'às' HH:mm}
```

A **duração não aparece no cabeçalho** de propósito: `log.started_at` é o início do lote e `log.completed_at` é o `now()` do fim do lote, então seria idêntica para todas as campanhas do run. Ela vive na faixa de contexto, rotulada "Duração do lote".

**Faixa de KPIs da campanha** (`grid grid-cols-3 bg-muted/30 border-b`, só em v2):

| Ícone | Rótulo | Campo derivado |
|---|---|---|
| `Users` | Contatos processados | `funnel.total_eligible_contacts` |
| `GitMerge` | Matches | `funnel.total_matches` |
| `Zap` | Ações criadas | `funnel.actions_created` (em `text-green-600`) |

**Bloco 1 — `BatchContextCard` (contexto do lote).** `Collapsible` dentro de `rounded-md border bg-muted/30`, ícone `Layers`. Enquanto carrega: "Carregando o contexto do lote..." com `Loader2`.

Frase de contexto, três variantes:

| Situação | Texto |
|---|---|
| Lote de 1 campanha | `Execução individual — esta campanha foi a única do lote de {dd/MM 'às' HH:mm}.` |
| Campanha localizada no lote | `Execução em lote — esta campanha foi {i} de {N} campanhas do lote de {quando}.` |
| Campanha não localizada | `Execução em lote — o lote de {quando} rodou {N} campanhas.` |

Gatilho do collapsible: link "**Ver números do lote**" / "**Ocultar números do lote**" com chevron.

Conteúdo aberto — `grid grid-cols-2 sm:grid-cols-5`:

| Rótulo | Campo do run |
|---|---|
| Contatos elegíveis | `total_eligible_contacts` |
| **Títulos avaliados** | `total_titles_fetched` |
| Matches | `total_matches` |
| Ações criadas | `actions_created` |
| **Duração do lote** | `calculateDuration(started_at, completed_at)` |

Nota de rodapé: "{Números do lote inteiro[, somando as N campanhas]}. 'Títulos avaliados' e a duração existem só neste nível: o matching consome a linha do título, e o log da campanha herda o início e o fim do lote."

**Bloco 2 — `CampaignExecutionFunnel` "Funil da campanha"** (§8.7), com `contactsLabel="Contatos processados"` e `matchingBreakdown` derivado.

**Bloco 3 — `ExclusionsCard` "Candidatos excluídos ({total})".** Barras horizontais, uma por motivo com valor > 0, ordenadas pela ordem canônica do funil:

```
[rótulo w-44 alinhado à direita] [barra h-5] [valor w-12] [percentual w-12]
```

Largura da barra = `max(valor / total × 100, 3)%`. O valor fica **dentro** da barra se o percentual passar de 20%; senão, numa coluna à direita. O percentual aparece sempre, com zero casas decimais.

Cores por **família de motivo** (`EXCLUSION_BAR_COLORS`), alinhadas com o `DISPOSITION_COLORS` do drill-down:

| Motivo | Cor da barra |
|---|---|
| `excluded_not_max_overdue` | `bg-purple-500` |
| `excluded_cadence` | `bg-amber-500` |
| `skipped_duplicates` | `bg-orange-500` |
| `excluded_already_fired` | `bg-amber-600` |
| `excluded_daily_cap` | `bg-rose-500` |
| `skipped_blocklist` | `bg-red-500` |
| `skipped_cooldown` | `bg-amber-500` |
| `skipped_higher_priority` | `bg-violet-500` |
| `skipped_cross_integration` | `bg-fuchsia-500` |
| `excluded_missing_recipient` | `bg-yellow-500` |
| `excluded_missing_reference` | `bg-yellow-600` |

Vazio: "Nenhum candidato foi excluído nesta execução."

**Sub-bloco "Fora da contagem de matches"** — separado por `border-t`, em `grid grid-cols-2`, lista `excluded_missing_recipient` e `excluded_missing_reference` quando > 0. Nota: "Descartados antes de virarem match, então não entram na subtração do funil."

**Bloco 4 — Erro.** Card `border-destructive/50` com `AlertTriangle`. Título muda: "**Erro na execução**" quando vem do log; "**Erro na execução do lote**" quando só o run tem erro. Corpo em `<pre>` com `max-h-32 overflow-auto`.

**Bloco 5 — Candidatos detalhados.** Botão de largura total "**Ver candidatos detalhados**" / "**Ocultar candidatos**", que revela o `CampaignExecutionCandidatesTable` **recortado por `campaignId`** (§8.8).

**Layout legado v1** (`LegacyLogCard`, quando não há `run_id`):

| Card | Conteúdo |
|---|---|
| "Resumo da Execucao" | grid de 3: Contatos processados / Acoes criadas (verde) / Erros (destrutivo se > 0) |
| "Candidatos Pulados" | grid de 2 colunas, só os motivos > 0: Duplicados, Cooldown, Blocklist, Ja contatados, Cross-campanha, Prioridade |
| "Detalhes do Erro" | `<pre>` com `error_details` completo |

### 8.6 Derivação do funil por campanha (`campaign-log-funnel.ts`)

Fonte: `src/lib/campaigns/campaign-log-funnel.ts`. Módulo **puro** — o designer precisa entender que os números do funil da campanha são **derivados**, não lidos diretamente.

Fórmula declarada no código:

```
matches     = actions_created
            + blocklist + cooldown + higher_priority
            + duplicates + cross_integration
            + not_max_overdue + cadence + already_fired + daily_cap

apos_dedup  = matches     − (not_max_overdue + cadence + duplicates + already_fired + daily_cap)
apos_regras = apos_dedup  − (blocklist + cooldown + higher_priority)
apos_cross  = apos_regras − cross_integration            (== actions_created)
```

Monotônico por construção: todo termo é ≥ 0.

**Origem de cada contador:**

| Contador | Onde vive |
|---|---|
| `skipped_blocklist`, `skipped_cooldown`, `skipped_duplicates`, `skipped_higher_priority`, `skipped_cross_integration` | colunas de `campaign_logs` |
| `excluded_not_max_overdue`, `excluded_cadence`, `excluded_already_fired`, `excluded_daily_cap`, `excluded_missing_recipient`, `excluded_missing_reference` | `campaign_logs.metadata` (escrito pelo `create_actions`) |

Contador ausente/nulo/negativo/não-numérico vira **0** — é o que mantém a derivação exata em log antigo, anterior à introdução das chaves novas.

**Os três estágios** e seus motivos, na ordem exata em que a tela os lista:

| Estágio | Motivos |
|---|---|
| `matching` | Não é o maior atraso · Intervalo mínimo do step · Dedup por integração/step · Já disparado (disparo único) · Teto diário atingido |
| `rules` | Blocklist · Cooldown · Prioridade maior |
| `cross` | Dedup entre campanhas |
| `outside` | Sem destinatário · Sem data de referência válida (**não** entram na subtração) |

⚠️ `skipped_same_step` é **sempre 0** na derivação por campanha — `campaign_logs.skipped_duplicates` já funde `excluded_same_step` com `dedup_integration`, e a fusão é contabilizada no estágio de matching.

⚠️ **Por que não se recalcula de `campaign_execution_candidates`:** (1) retenção de 48 h pelo cron `cleanup_exec_candidates`; (2) o `DELETE` final do run apaga `no_step_match`, `dedup_integration` e `pending`. O log é o registro durável para todo o histórico.

### 8.7 `CampaignExecutionFunnel` — o funil de barras

Fonte: `src/components/campaigns/execution/CampaignExecutionFunnel.tsx`. **Componente compartilhado**: atende tanto o nível do LOTE (recebe o `CampaignExecutionRun` direto) quanto o nível da CAMPANHA (recebe o objeto derivado). Por isso os nomes de campo são os mesmos.

Etapas renderizadas, em ordem:

| # | Rótulo | Valor | Cor | Delta anotado (`excludedLabel`) |
|---|---|---|---|---|
| 1 | **Contatos elegíveis** (ou "Contatos processados") | `total_eligible_contacts` | `bg-blue-500` | — (contexto, não etapa subtrativa) |
| 2 | **Títulos** | `total_titles_fetched` | `bg-blue-400` | — **só renderizada se o campo existir** |
| 3 | **Matches** | `total_matches` | `bg-indigo-500` | "Sem step compatível" (só com `total_titles_fetched`) |
| 4 | **Após travas do matching** | `matches_after_integration_dedup` | `bg-violet-500` | detalhamento por motivo, ou o texto genérico |
| 5 | **Após regras** | `matches_after_rules` | `bg-purple-500` | "Blocklist: N, Cooldown: N, Step duplicado: N, Prioridade maior: N" |
| 6 | **Após dedup entre campanhas** | `matches_after_cross_dedup` | `bg-fuchsia-500` | "Outra campanha venceu o mesmo contato/canal" |
| 7 | **Ações criadas** | `actions_created` | `bg-green-500` | — |

Regra declarada no código: a aresta **contatos → matches nunca é anotada** com "excluídos", porque contato e match têm unidades diferentes (um contato com 5 títulos gera até 5 matches).

Renderização de cada linha:

```
[rótulo w-44, alinhado à direita, truncate]
[trilho h-7 bg-muted rounded-sm; preenchimento colorido]
[delta -N em text-red-500 w-16, só quando > 0 e não é a última linha]
```

Largura = `max(valor / maxValue × 100, 2)%`, onde `maxValue` é o maior valor entre as etapas. Número dentro da barra (`text-white`) se a largura passar de 15%; senão, absoluto à direita.

Tooltip (lado direito, `max-w-xs`):

```
{rótulo}: {valor}
Excluídos: {n} ({excludedLabel})
```

Texto genérico da etapa 4 quando não há detalhamento: "Maior atraso, cadência, dedup por integração/step, disparo único e teto diário".

Motivo do `matchingBreakdown` existir (comentário do código): "Sem ele o tooltip atribuía a queda inteira a 'Dedup por integração' — no run de 26/08 essa queda foi 3.192, dos quais 3.040 eram a trava do maior atraso e só 152 eram dedup."

⚠️ `text-white` é hardcoded nesse componente (diferente do `CampaignFunnelReal`, que usa tokens semânticos). Inconsistência de design system.

### 8.8 `CampaignExecutionCandidatesTable`

Fonte: `src/components/campaigns/execution/CampaignExecutionCandidatesTable.tsx`. Aceita `runId` (obrigatório) e `campaignId` (opcional, para recortar a uma campanha do lote).

**Filtros** (`flex flex-wrap gap-2`):

| Controle | Detalhe |
|---|---|
| **Buscar por contact_id...** | `Input h-8` com `Search` (`pl-8`), `max-w-xs` |
| **Todas as disposicoes** | `Select w-48 h-8`, opção "Todas" + todas as entradas de `DISPOSITION_LABELS` (**sem exclusão de transitórias**, diferente do drill-down) |
| Contador | "{n} registros" em `text-xs text-muted-foreground` |

⚠️ **O campo de busca não funciona.** O componente passa `search` no filtro, mas o hook `useCampaignExecutionCandidates` **não usa** `filters.search` na query. Digitar ali só reseta a página. Defeito real.

**Tabela** — `min-w-[720px]` dentro de `overflow-x-auto`, 7 colunas:

| Coluna | Conteúdo |
|---|---|
| **Contact ID** | 8 primeiros caracteres + `...`, `font-mono` |
| **Title ID** | 8 primeiros caracteres + `...`, ou `-...` quando nulo |
| **Days Overdue** | à direita; `-` quando nulo |
| **Canal** | rótulo PT de `action_type`: WhatsApp, E-mail, RCS, SMS, Webhook; senão valor cru; `-` se nulo |
| **Disposicao** | `Badge outline` com rótulo e cor da disposição |
| **Step** | `disposition_step` cru, ou `-` |
| **Detalhes** | `disposition_details.reason` **cru (em inglês)**, ou o JSON; `max-w-[240px] truncate` com `title` completo |

⚠️ Cabeçalhos em inglês/técnico (`Contact ID`, `Title ID`, `Days Overdue`) e a coluna "Detalhes" **não traduz o motivo** — diferente do `CampaignReasonsDrilldown` (§7.3), que tem o dicionário completo. Duas tabelas para o mesmo dado, com qualidade de copy muito diferente.

⚠️ Bug visual: quando `title_id` é nulo a célula renderiza `-...` (o `...` fica colado no fallback).

**Estados:**

| Estado | Visual |
|---|---|
| Carregando | linha única com "Carregando..." em `colSpan={7}` |
| Vazio sem filtro | "Nenhum candidato encontrado" + **"O detalhamento por candidato fica disponível por 48h após a execução."** |
| Vazio com filtro | só "Nenhum candidato encontrado" |

A segunda linha do vazio é obrigatória por design: "Vazio aqui quase sempre é RETENÇÃO, não ausência (…) Vazio mudo levava a ler 'a campanha não avaliou ninguém'".

**Paginação:** 50 por página, ordenação fixa `days_overdue` desc (nulos por último). Só aparece com mais de uma página: "Pagina {n} de {N}" + dois botões de seta.

### 8.9 `CampaignExecutionRunsList` — componente sem callsite

Fonte: `src/components/campaigns/execution/CampaignExecutionRunsList.tsx`.

**Este componente não é renderizado por nenhuma tela do domínio hoje** (ver §18). Está documentado porque contém a única navegação master-detail de runs do produto, e o redesign pode querer reaproveitá-la ou removê-la de vez.

Comportamento:

- Sem seleção: card "**Execucoes Pipeline v2**" com uma lista `divide-y` dentro de `ScrollArea max-h-[500px]`. Cada linha (`RunRow`) é um `<button>` com ícone de status, data da execução, badge de passo, e metadados `{N} campanhas · {N} acoes · {N}s`, mais um `ChevronRight`.
- Com seleção: botão "**Voltar**" + "Execucao de {data}" + badge de status; abaixo, o `CampaignExecutionFunnel` com título "**Funil do lote**" e um card "**Candidatos ({n})**" com a tabela de candidatos **sem recorte de campanha**.
- Vazio: "Nenhuma execucao do pipeline v2 encontrada. Ative o pipeline v2 em uma campanha para comecar."

**Catálogo de rótulos longos de passo** (`StatusBadge`) — é a única fonte desses textos:

| `current_step` | Rótulo | Variante |
|---|---|---|
| `plan` | Planejando | `secondary` |
| `resolve_contacts` | Resolvendo contatos | `secondary` |
| `fetch_titles` | Buscando titulos | `secondary` |
| `match_titles` | Matching | `secondary` |
| `apply_rules` | Aplicando regras | `secondary` |
| `cross_dedup` | Cross-dedup | `secondary` |
| `create_actions` | Criando acoes | `secondary` |
| `completed` | Concluido | `default` |
| `failed` | Falhou | `destructive` |
| outro | valor cru | `outline` |

Ícone de status (`StatusIcon`): `CheckCircle2` verde para `completed`, `XCircle` vermelho para `failed`, `Clock` âmbar para **qualquer outro** (inclusive travado — este componente **não tem** detecção de run travado).

### 8.10 Execução travada e a ambiguidade do erro sem falha

Ponto de domínio que o redesign precisa representar corretamente.

**(a) Run travado.** Um run pode parar de avançar sem marcar `failed`. A tela o detecta por ausência de heartbeat há mais de 15 minutos e mostra o selo **"Travado"** (âmbar, `AlertTriangle`), com botão **Retry**. O watchdog do `campaign-logs-cleanup` roda a cada 5 minutos e faz o mesmo automaticamente, até 3 vezes (`retry_count`).

**(b) Erro que não é falha.** Uma chamada pesada pode devolver erro **sem** o trabalho ter falhado: o proxy do PostgREST espera ~125 s e devolve **504**, mas **não cancela a query** — o Postgres continua, termina e **commita**. O caller recebe "falhou" para um trabalho que deu certo.

Como a interface representa isso hoje:

| Superfície | Representação |
|---|---|
| `CampaignDryRunDialog` | status `timeout_partial` → alerta âmbar "**Ensaio parcial**", nomeando o passo em que parou e dizendo "rode novamente para um resultado completo" |
| `PipelineRunStatusCard` | o run fica **"Travado"** (não "Falhou") quando o heartbeat envelhece, com Retry disponível |
| `CampaignLogDetailDialog` | separa "Erro na execução" (do log) de "**Erro na execução do lote**" (do run) — o segundo pode existir sem o primeiro |
| `PipelineRunStatusCard` (expandido) | `error_details` exibido cru, truncado em 300 caracteres |

⚠️ **Nenhuma dessas superfícies diz ao usuário, em português, que "erro pode significar 'não sabemos'".** O `timeout_partial` chega mais perto ("parou por tempo de execução"), e é o vocabulário a estender no redesign. Um run que sofreu esse teto aparece como `failed` com `error_details` no formato `Step <passo> failed: <msg>`, sem qualquer indicação de que o trabalho pode ter sido concluído.

---

## 9. Catálogo de disposições e motivos de exclusão

Fonte dos rótulos e cores: `src/hooks/useCampaignExecutionCandidates.ts` (`DISPOSITION_LABELS`, `DISPOSITION_COLORS`). Fonte dos rótulos do funil derivado: `src/lib/campaigns/campaign-log-funnel.ts`.

Este é o vocabulário que o operador lê no drill-down, na tabela de candidatos e no cartão de exclusões. **A ordem da tabela abaixo é a ordem de declaração do objeto — que é literalmente a ordem do dropdown de motivos.** O código avisa que mexer nela muda a tela de quem já usa o drill-down.

### 9.1 Tabela canônica

| Valor (`disposition`) | Rótulo exibido | Passo do pipeline que atribui | Cor do badge | O que significa para o usuário |
|---|---|---|---|---|
| `pending` | **Pendente** | `resolve_contacts` | `bg-gray-100 text-gray-800` | Contato entrou na fila de avaliação e ainda não foi processado. Estado transitório |
| `no_step_match` | **Sem step compativel** | `match_titles` | `bg-yellow-100 text-yellow-800` | Nenhum passo da régua corresponde ao dia de atraso (ou à etapa) deste título. Não é erro — é a régua não cobrindo aquele dia |
| `dedup_integration` | **Dedup por integracao** | `match_titles` | `bg-orange-100 text-orange-800` | Já havia um candidato equivalente para o mesmo contato/canal/integração dentro do run. Sobrou um só |
| `selected` | **Selecionado** | `match_titles` | `bg-blue-100 text-blue-800` | Passou pelo matching e segue para as regras. Estado intermediário de sucesso |
| `excluded_blocklist` | **Blocklist** | `apply_rules` | `bg-red-100 text-red-800` | O contato, contrato, título ou endereço (telefone/e-mail) está bloqueado. Não pode ser contatado |
| `excluded_cooldown` | **Cooldown** | `apply_rules` | `bg-amber-100 text-amber-800` | O contato recebeu o mesmo canal dentro da janela de cooldown configurada na campanha |
| `excluded_same_step` | **Step duplicado** | `apply_rules` | `bg-orange-100 text-orange-800` | Já existe ação criada para o mesmo passo da régua e o mesmo contato |
| `excluded_higher_priority` | **Prioridade maior** | `apply_rules` | `bg-purple-100 text-purple-800` | Outro candidato de prioridade superior venceu a disputa pelo mesmo contato/canal/integração |
| `excluded_cross_campaign` | **Dedup cross-campanha** | `cross_dedup` | `bg-pink-100 text-pink-800` | Outra campanha já ia contatar o mesmo alvo pelo mesmo canal. Só uma ação sobrevive |
| `action_created` | **Acao criada** | `create_actions` | `bg-green-100 text-green-800` | Virou ação de verdade. É o desfecho positivo |
| `excluded_not_max_overdue` | **Nao e o maior atraso** | `match_titles` (passe A) | `bg-purple-100 text-purple-800` | O contato tem outro título mais atrasado; só o maior atraso gera comunicação. Escopo: contato para comunicação/IA, contrato para negativação/notificação |
| `excluded_cadence` | **Intervalo minimo do step** | `match_titles` (passe B) | `bg-amber-100 text-amber-800` | O passo tem intervalo mínimo entre repetições (`repeat_every_days`) e ele ainda não passou desde o último envio |
| `excluded_missing_reference` | **Sem data de referencia valida** | `fetch_titles` | `bg-yellow-100 text-yellow-800` | Perfil de formalização: o contato não tem data de referência legível para calcular há quantos dias está na etapa |
| `excluded_missing_recipient` | **Sem destinatario** | `match_titles` | `bg-yellow-100 text-yellow-800` | O passo é de comunicação mas não há endereço válido para o canal (ou o endereço resolvido não tem a forma do canal) |
| `excluded_already_fired` | **Ja disparado (disparo unico)** | `match_titles` (passe C) | `bg-amber-100 text-amber-800` | O passo é de disparo único (`fire_once`) e o contato já recebeu essa ação |
| `excluded_daily_cap` | **Teto diario atingido** | `match_titles` (passe D) | `bg-rose-100 text-rose-800` | Perfil de formalização: o contato já atingiu o teto de ações permitidas no dia |

**Lógica de cor por família** (declarada no código):

| Cor | Família |
|---|---|
| roxo / violeta | disputa de prioridade (`excluded_higher_priority`, `excluded_not_max_overdue`) |
| âmbar | freio de repetição no tempo (`excluded_cooldown`, `excluded_cadence`, `excluded_already_fired`) |
| amarelo | dado ausente ou inválido (`no_step_match`, `excluded_missing_reference`, `excluded_missing_recipient`) |
| laranja | dedup dentro do run (`dedup_integration`, `excluded_same_step`) |
| rosa / fúcsia | dedup entre campanhas (`excluded_cross_campaign`) |
| vermelho | bloqueio (`excluded_blocklist`) |
| rosé | teto/limite operacional (`excluded_daily_cap`) |
| verde | sucesso (`action_created`) |
| azul | intermediário positivo (`selected`) |
| cinza | transitório (`pending`) |

### 9.2 Disposições que somem do histórico

O `DELETE` final do `create_actions` apaga três disposições: `no_step_match`, `dedup_integration` e `pending`.

Consequências visíveis:

| Superfície | Comportamento |
|---|---|
| `CampaignReasonsDrilldown` em execução real | `dedup_integration` e `no_step_match` são **removidas do dropdown** (`NON_DETAILABLE_DISPOSITIONS`); nota de rodapé explica |
| `CampaignReasonsDrilldown` em ensaio | as três aparecem (`includeTransientDispositions`), porque o `create_actions` não rodou |
| `CampaignExecutionCandidatesTable` | lista **todas** as opções, sem exclusão — filtrar por elas devolve 0 em execução real |

⚠️ Inconsistência real entre as duas tabelas. `pending` continua no dropdown do drill-down apesar de também ser apagada.

Todas as demais exclusões **sobrevivem** e são filtráveis, inclusive as do gate de julho (`excluded_not_max_overdue`, `excluded_cadence`) e as do perfil de formalização.

### 9.3 Duas nomenclaturas para o mesmo motivo

O produto tem **dois** conjuntos de rótulos para os mesmos motivos, dependendo de a tela ler candidatos ou o log derivado:

| Conceito | Rótulo em `DISPOSITION_LABELS` (drill-down, candidatos) | Rótulo em `campaign-log-funnel` (funil e exclusões do log) |
|---|---|---|
| Maior atraso | Nao e o maior atraso | Não é o maior atraso |
| Cadência | Intervalo minimo do step | Intervalo mínimo do step |
| Dedup de integração/step | Dedup por integracao / Step duplicado (**dois** rótulos) | Dedup por integração/step (**um só**, porque a coluna funde os dois) |
| Disparo único | Ja disparado (disparo unico) | Já disparado (disparo único) |
| Teto diário | Teto diario atingido | Teto diário atingido |
| Blocklist | Blocklist | Blocklist |
| Cooldown | Cooldown | Cooldown |
| Prioridade | Prioridade maior | Prioridade maior |
| Cross-campanha | Dedup cross-campanha | Dedup entre campanhas |
| Sem destinatário | Sem destinatario | Sem destinatário |
| Sem data de referência | Sem data de referencia valida | Sem data de referência válida |

⚠️ Além da acentuação, há divergência semântica real em "Dedup cross-campanha" × "Dedup entre campanhas". E um **terceiro** conjunto aparece no `CampaignPreviewModal` (§7): "deduplicação", "dedup entre campanhas", "cooldown", "prioridade", "blocklist" (minúsculas, para caber na frase do motivo dominante). Três vocabulários para a mesma coisa.

### 9.4 Disposição sem rótulo

`fetch_titles` grava `disposition = 'fetched'` nas linhas de título expandidas (Regra 15 do `CLAUDE.md` da Torre). Esse valor **não existe** em `DISPOSITION_LABELS` nem em `DISPOSITION_COLORS`.

Consequência visual: um candidato em `fetched` aparece no badge com o **valor cru** e com a cor de fallback (`bg-muted text-muted-foreground` no drill-down; `bg-gray-100` na tabela de candidatos). Na prática é raro, porque `match_titles` consome essas linhas — mas num ensaio interrompido ou num run travado em `fetch_titles` é exatamente o que o operador veria.

⚠️ A confirmar: se o redesign deve rotular `fetched` explicitamente ("Título carregado, aguardando matching") ou se é considerado estado interno que nunca deve chegar à tela.

---

## 10. Custos

### 10.1 As duas superfícies de custo

| Superfície | Componente | Base | Quando aparece |
|---|---|---|---|
| **Custo estimado da próxima ativação** | dentro do `CampaignPreviewModal` (§7.1, bloco C) e no rodapé do card da lista (§4.3.5) | `actionsByStepType` da RPC de prévia | antes de disparar |
| **Custo Estimado (realizado)** | `CampaignCostBreakdown`, dentro do `CampaignDetailDialog` | contagem real de `actions` da campanha, agrupada por `action_type` | depois de ao menos uma execução |

Ambas usam o mesmo motor: `src/lib/cost-calculator.ts` + `useChannelCosts` (tabela `channel_costs` da org).

### 10.2 Motor de cálculo (`src/lib/cost-calculator.ts`)

**Mapa `step_type` → canal** (`STEP_TYPE_TO_CHANNEL`):

| `step_type` / `action_type` | Canal |
|---|---|
| `send_whatsapp` | `whatsapp` |
| `send_email` | `email` |
| `send_rcs` | `rcs` |
| `send_sms` | `sms` |
| `send_voice` | `voice` |
| `webhook` | `webhook` |
| `negativation` | `negativation` |
| `human_activity` | `human_activity` |
| `block` | `block` |
| `trigger_ai` | `ai` |

**Rótulos pt-BR dos canais** (`CHANNEL_LABELS`):

| Canal | Rótulo |
|---|---|
| `whatsapp` | WhatsApp |
| `sms` | SMS |
| `email` | E-mail |
| `voice` | Voz |
| `negativation` | Negativacao |
| `ai` | IA |
| `human_activity` | Atividade Humana |
| `webhook` | Webhook |
| `block` | Bloqueio |

Canal sem rótulo mapeado aparece com a chave crua. ⚠️ `rcs` **não tem rótulo** em `CHANNEL_LABELS` — aparece como literal `rcs` na tabela de custos, embora tenha rótulo "RCS" em outras telas.

**Regra do custo de IA (`CHANNELS_WITH_AI`).** Os canais **`whatsapp`** e **`voice`** disparam atendimento de IA automaticamente após o envio. Por isso, em `calculateEstimatedCost` e em `getCostForStepType`, o custo unitário desses dois canais é **`custo do canal + custo do canal `ai``**.

⚠️ **Assimetria importante:** `calculateCostBreakdown` — usada pelo `CampaignCostBreakdown` — **não** soma o custo de IA. Ou seja, a estimativa ao vivo do modal de prévia e a tabela de custo do detalhe usam fórmulas diferentes para o mesmo canal. Para uma campanha de WhatsApp, o número do modal é **maior** que o da tabela. Não é bug documentado; é comportamento real do código. O redesign precisa decidir qual é a verdade.

**Filtro de custo ativo:** `buildCostMap` só considera linhas com `is_active === true`. Canal sem custo configurado tem custo unitário **0** (não gera erro nem alerta).

**Formato monetário:** `formatBRL` → `toLocaleString("pt-BR", { style: "currency", currency: "BRL", minimumFractionDigits: 2, maximumFractionDigits: 2 })`.

### 10.3 `CampaignCostBreakdown` — o card do detalhe

Fonte: `src/components/campaigns/CampaignCostBreakdown.tsx`.

**Entrada de dados:** consulta `actions` filtrando `campaign_id`, seleciona só `action_type`, e agrupa **no cliente**. Recebe `totalContacts` do pai (a soma de `contacts_processed` dos últimos 50 logs).

⚠️ Essa query traz **uma linha por ação** da campanha inteira, sem paginação, só para contar. Em campanha grande é um download pesado. Oportunidade técnica do redesign.

**Estados:**

| Estado | Visual |
|---|---|
| Carregando | `Card` com `Skeleton h-5 w-48` no header e 3 `Skeleton h-8` no corpo |
| Sem dados (`breakdown` nulo ou sem itens) | **retorna `null`** — o card some inteiro, sem mensagem |

**Cabeçalho:** `CardTitle` com `DollarSign h-5 w-5` + "**Custo Estimado**"; `CardDescription` "Estimativa baseada nos custos configurados por canal".

**Grade de 3 KPIs** (`grid grid-cols-3 gap-4`), cada um `text-center p-3 rounded-lg bg-muted/50`:

| # | Valor | Formato | Rótulo |
|---|---|---|---|
| 1 | `breakdown.totalCost` | `text-2xl font-bold font-mono`, BRL | **Custo Total** |
| 2 | `totalCost / totalContacts` | `text-2xl font-bold font-mono`, BRL; `-` quando não há contatos | **Por Contato** |
| 3 | `breakdown.items[0].label` | `text-lg font-bold` | **Canal Mais Caro** |

O "canal mais caro" é o primeiro item da lista, que vem ordenada por `totalCost` **decrescente** — é o canal de maior custo **total**, não de maior custo unitário.

**Tabela de detalhamento:**

| Coluna | Alinhamento | Formato |
|---|---|---|
| **Canal** | esquerda | `Badge variant="outline"` com o rótulo pt-BR |
| **Acoes** | direita | `tabular-nums`, `pt-BR` |
| **Custo Unit.** | direita | `tabular-nums font-mono`, BRL |
| **Custo Total** | direita | `tabular-nums font-mono font-medium`, BRL |

Linha final **Total** (`font-bold border-t-2`): soma das ações à direita, célula de custo unitário **vazia**, custo total geral.

**Rodapé:** "Valores estimados. Custos reais podem variar conforme provedor." (`text-xs text-muted-foreground text-center`).

⚠️ Cabeçalho "**Acoes**" sem acento.

### 10.4 Custo no rodapé do card da lista

Detalhado em §4.3.5. Formato: `~{BRL}` em `font-mono font-medium text-emerald-600`, precedido de `DollarSign` esmeralda, e **só aparece quando o custo é maior que zero**. O `~` sinaliza estimativa.

### 10.5 Custo realizado — o buraco declarado

O `CampaignPreviewModal` passa `costHoje={undefined}` e `costTotal={undefined}` para o `CampaignActivityMatrix`, com comentário explícito:

> "Custo realizado por canal não é confiável a partir do status → passamos undefined (o custo é omitido, sem '—'). NÃO inventar."

Ou seja: **não existe, hoje, "quanto essa campanha custou de verdade"**. Existe "quanto ela custaria" (estimativa) e "quanto custariam as ações que ela criou" (`CampaignCostBreakdown`, que conta ações independentemente de terem sido enviadas, falhado ou canceladas).

⚠️ O redesign **não pode** preencher esse espaço com um número derivado. É uma lacuna de dado, não de interface.

---

## 11. Repique

O repique é a permissão de **recontatar hoje alguém que já foi contatado hoje**. Aparece em três lugares, com papéis distintos:

| Superfície | Papel | Fonte |
|---|---|---|
| Switch "Repique" no formulário (só broadcast) | **configura** (`settings.repique_enabled`) | `CampaignDialog.tsx` |
| `RepiquePreview` no formulário | **simula o impacto** antes de salvar | `RepiquePreview.tsx` |
| Aba **Repique** de `/campaigns` | **audita o que já saiu** com repique ativo | `RepiqueTab.tsx` |

O switch e o preview estão documentados em §5.8.3 e §5.6.2. Esta seção cobre a aba.

### 11.1 Cabeçalho da aba

```
<TabsContent value="repique" className="mt-0 space-y-4">
  <DashboardFiltersBar periodOnly />
  <RepiqueTab filters={repiqueFilters} />
```

O `DashboardFiltersBar periodOnly` expõe **apenas** o seletor de período, gerido por `useDashboardFilters`. Períodos suportados por `getDateRange` (`src/hooks/useRepiqueActions.ts`):

| Valor | Janela calculada |
|---|---|
| `today` | dia corrente, `00:00:00-03:00` → `23:59:59-03:00` |
| `7d` | últimos 7 dias (hoje − 6 até hoje) |
| `30d` | últimos 30 dias (hoje − 29 até hoje) |
| `this_month` | primeiro ao último dia do mês corrente |
| `last_month` | mês anterior inteiro |
| `12m` | últimos 12 meses |
| `custom` | `startDate`/`endDate` informados; **cai para 12 meses** se algum faltar |
| `all` | **também vira 12 meses** — não existe "tudo" de verdade |

⚠️ O valor `all` **não** significa "sem limite": o código cai no mesmo intervalo de 12 meses. Se a interface oferecer "Todo o período", ela está mentindo. Corrigir ou renomear no redesign.

Todos os limites são montados com offset fixo `-03:00` no texto do ISO, não por conversão de fuso.

### 11.2 KPIs

`grid gap-4 md:grid-cols-2 lg:grid-cols-4`, componente `KPICard` (compartilhado com o dashboard):

| # | Título | Valor | Descrição | Ícone | Variante |
|---|---|---|---|---|---|
| 1 | **Total de Repiques** | `stats.total` (pt-BR) | "Acoes criadas com repique ativo" | `Repeat` | default |
| 2 | **Campanhas** | `stats.campanhas` | "Campanhas que usaram repique" | `Megaphone` | default |
| 3 | **Taxa de Envio** | `{enviados/total × 100}%` com 1 casa | "Acoes enviadas com sucesso" | `Send` | `success` |
| 4 | **Falhas** | `stats.falhas` (pt-BR) | "Acoes que falharam" | `AlertTriangle` | `danger` se > 0, senão default |

Os quatro `KPICard` recebem `isLoading` e mostram o esqueleto nativo do componente.

Taxa de envio é `"0.0"` quando `total === 0`.

⚠️ Descrições sem acento (`Acoes`).

### 11.3 Tabela "Acoes com Repique"

`CardTitle` `Repeat h-5 w-5` + "**Acoes com Repique**". `CardDescription`: "Detalhes das acoes criadas quando o Repique estava ativo ({N} no total)".

| Coluna | Alinhamento | Conteúdo |
|---|---|---|
| **Contato** | esquerda | `contact.name` em `font-medium`, ou `—` |
| **Campanha** | esquerda | `campaign.name`, ou `—` |
| **Canal** | esquerda | `Badge outline` com o rótulo do canal |
| **Status** | esquerda | `Badge` com variante derivada do status |
| **Data** | **direita** | `dd/MM/yyyy 'as' HH:mm` (`tabular-nums text-sm text-muted-foreground`) |

⚠️ O formato de data usa a string `'as'` — sem crase. Aparece literalmente como "18/09/2026 as 14:30". Defeito de copy.

**Rótulos de canal** (`channelLabels`, local do arquivo): tenta primeiro `action_type`, depois `channel`, senão mostra o `action_type` cru.

| Chave | Rótulo |
|---|---|
| `send_whatsapp` / `whatsapp` | WhatsApp |
| `send_email` / `email` | E-mail |
| `send_rcs` | RCS |
| `send_sms` / `sms` | SMS |
| `send_voice` | Voz |
| `webhook` | Webhook |
| `negativation` | Negativacao |
| `human_activity` | Atividade Humana |
| `trigger_ai` | IA |

**Variante do badge de status** (`getStatusColor`):

| Variante | Status |
|---|---|
| `default` | Enviado, Interagiu, Respondido, Em Atendimento |
| `secondary` | Pendente, Processando |
| `destructive` | Falhou, Falha Permanente |
| `outline` | qualquer outro (inclusive os 3 Cancelado* e Duplicado) |

⚠️ **Esta tabela exibe o valor canônico do status, não o rótulo de exibição.** Aparece "Falhou" e "Respondido", enquanto o resto do produto mostra "Falha Temporária de Ação" e "Solicitou Atendimento" (§7.1). É a única superfície do domínio que não usa `getActionStatusLabel`. Corrigir no redesign.

**Estados:**

| Estado | Visual |
|---|---|
| Carregando | 8 linhas de `Skeleton` com 5 blocos de larguras diferentes (`w-40 w-32 w-20 w-24 w-28`) |
| Vazio | `Repeat h-12 w-12 opacity-50` + "Nenhuma acao com repique no periodo selecionado" |
| Com dados | tabela dentro de `overflow-x-auto` |

**Paginação:** 50 por página; barra separada por `border-t` no topo (`pt-4 mt-4`). "Pagina {n} de {N}" à esquerda; botões "**Anterior**" (com `ChevronLeft`) e "**Proxima**" (com `ChevronRight`) à direita, ambos `outline size="sm"`.

⚠️ Este é o **terceiro** padrão de paginação do domínio: a lista de campanhas usa "Anterior/Próxima" com scroll-to-top (§4.4); o drill-down e a tabela de candidatos usam só setas; aqui são setas **com** rótulo, sem scroll-to-top. E "Proxima" está sem acento aqui e com acento na lista de campanhas.

### 11.4 Origem dos dados

`useRepiqueDashboard` (`src/hooks/useRepiqueActions.ts`) invoca a Edge Function **`get-repique-dashboard`** com `{ start_date, end_date, limit, offset }`. `staleTime` 30 s, sem refetch ao focar a janela.

A resposta traz `{ stats, actions, total_actions, returned }`. Erro do invoke, `success: false` ou payload ausente lançam — e a tela **não tem estado de erro**: o `useQuery` falha e a aba fica em "Nenhuma acao com repique no periodo selecionado", indistinguível de vazio legítimo.

⚠️ Lacuna real: **a aba Repique não distingue erro de vazio**. Requisito do redesign.

---

## 12. Editor de Broadcast (`/broadcasts/:id/editor`)

Fonte: `src/pages/BroadcastEditorPage.tsx`. É a **única tela cheia** do domínio — vive fora do `AppLayout`, sem sidebar nem topbar da aplicação.

### 12.1 Rota e parâmetros

| Parte | Valor |
|---|---|
| Path | `/broadcasts/:id/editor` |
| `:id` | id da **régua** (`workflow`), não da campanha |
| Query string | `?campaign={id}` — opcional, mas é o que liga o editor à campanha |

Ponto de entrada real: item **"Configurar Ações"** do menu da visão grade, que navega para `/broadcasts/{target_reguas[0]}/editor?campaign={campaign.id}`.

⚠️ Só a **primeira** régua do broadcast é editável por esse caminho. Um broadcast com 3 réguas só expõe a régua `target_reguas[0]` no menu. As outras duas não têm ponto de entrada na tela de Campanhas.

⚠️ Sem `?campaign=`, a página carrega e funciona, mas: o título cai para o nome da régua, o badge de agendamento some, o switch "Ativo/Inativo" **não faz nada** (`handleToggleCampaign` retorna cedo) e ainda assim continua clicável.

Permissão: `canWrite = hasPermission("broadcasts:write")` — diferente da tela de campanhas, que usa `campaigns:write`.

### 12.2 Estados de página inteira

| Estado | Visual |
|---|---|
| Carregando (régua **ou** campanha) | `h-screen flex items-center justify-center` com `Loader2 h-8 w-8` |
| Régua não encontrada | `h-screen` centralizado: "Workflow não encontrado" + botão **Voltar** |

⚠️ A mensagem usa o termo técnico **"Workflow"**, que não aparece em nenhum outro lugar da UI (o produto chama de "régua"). Corrigir.

### 12.3 Header (64 px, `h-16 border-b`)

**Esquerda** (`flex items-center gap-4`):

```
[← Voltar]  │  [Megaphone em caixa bg-primary/10]  {nome da campanha ou da régua}
                                                    "Disparo Pontual (Broadcast)"  (text-xs muted)
```

O botão **Voltar** invalida as queries `campaigns` e `workflows` e navega para **`/reguas-cobranca`** — **não** para `/campaigns`, de onde o usuário provavelmente veio.

⚠️ Navegação de retorno inconsistente com a origem. Requisito do redesign.

**Direita** (`flex items-center gap-4`), na ordem:

| # | Elemento | Condição | Detalhe |
|---|---|---|---|
| 1 | Indicador de salvamento | sempre | `Loader2` + "**Salvando...**" enquanto há mutação; senão `Save` + "**Salvo**" |
| 2 | Divisor `h-6 w-px bg-border` | sempre | — |
| 3 | Badge de agendamento | `campaign.scheduled_at` | `dd/MM HH:mm`, com tooltip "Agendado para este horário" |
| 4 | Badge de canais | sempre | `Users h-3 w-3` + "{n} canal" / "{n} canais" |
| 5 | Switch Ativo/Inativo | sempre | rótulo "Ativo"/"Inativo" à esquerda; `disabled` se `!canWrite \|\| updateCampaign.isPending` |

⚠️ O indicador "Salvo" é **permanente**, não um feedback de ação: aparece mesmo antes de qualquer edição. Ele significa "nenhuma mutação em voo", não "suas alterações foram salvas". Semântica enganosa.

⚠️ O `disabled` do switch checa `updateCampaign.isPending`, mas a ação real usa `toggleCampaignStatus` — o switch **não fica desabilitado** durante a própria operação que ele dispara.

### 12.4 Ativação do broadcast — as três camadas de validação

Ao ligar o switch (`handleToggleCampaign(true)`):

**Camada 1 — local, rápida.** Se `hasIncompleteSteps`, toast destrutivo e **aborta**:

> "**Não é possível ativar o broadcast**" / "Existem ações sem configuração completa. Configure todas as ações antes de ativar."

A checagem local considera passo incompleto quando `config` é nulo **ou** quando o tipo está em `[send_whatsapp, send_email, send_sms, send_voice, webhook, human_activity, negativation, block]` e falta `integration_id`.

**Camada 2 — local, sem passos.** Se `steps.length === 0`:

> "**Não é possível ativar o broadcast**" / "Adicione pelo menos uma ação ao broadcast."

**Camada 3 — `useToggleCampaignStatus`.** Aplica as validações completas (§4.6): réguas associadas, filtros configurados, ações configuradas, configuração completa. Essa terceira camada usa uma lista de tipos **diferente** da camada 1 (`[send_whatsapp, send_email, send_sms, send_voice, webhook]`, sem `human_activity`/`negativation`/`block`) e **também** exige `message` ou `template`.

⚠️ **Duas definições de "configuração completa" no mesmo fluxo de ativação.** Um passo `negativation` sem integração é barrado pela camada 1 mas passaria pela camada 3; um `send_whatsapp` com integração mas sem mensagem passa pela camada 1 e é barrado pela camada 3. O redesign precisa de **uma** definição.

Desligar o switch grava `status: "paused"` (diferente do formulário, que grava `draft` — §5.7.1).

### 12.5 Corpo — `BroadcastTimelineView`

`<main className="flex-1 overflow-y-auto p-6">` com `max-w-3xl mx-auto`. Fonte: `src/components/campaigns/BroadcastTimelineView.tsx`.

**Cabeçalho do card:**

```
[Megaphone em caixa bg-primary/10]  "Ações do Disparo"          [Badge secondary:
                                     "Todas as ações serão        → Execução Paralela]
                                      executadas simultaneamente"
```

**Estado vazio:** `Megaphone h-12 w-12`, "**Nenhuma ação configurada**", "Adicione canais de comunicação para disparar para o seu público. Você pode adicionar um canal de cada tipo." + botão "**Adicionar Primeira Ação**" (só se `canWrite`).

**Com passos:**

1. `Alert` fixo no topo (`AlertCircle`): "**Execução paralela:** Todas as ações abaixo serão enviadas ao mesmo tempo. Cada tipo de canal só pode ser usado uma vez."
2. Lista arrastável (`@dnd-kit`) dentro de `ScrollArea`, `space-y-3`, ordenada por `position_y` ascendente. Cada item é um `StepCard` (componente compartilhado com o editor de réguas).
3. Rodapé `border-t`: botão "**Adicionar Canal**" de largura total, `disabled` quando já há 8 tipos; abaixo, quando saturado: "Todos os tipos de canal já foram adicionados".

**Drag-and-drop:** sensores `PointerSensor` (ativa após 8 px de movimento) e `KeyboardSensor` (navegável por teclado). Ao soltar, reatribui `position_y = índice × 10` e persiste **todos** os passos em paralelo.

⚠️ **A ordem não significa nada.** O próprio card diz "execução paralela" e "ao mesmo tempo", mas a lista é reordenável e persiste a ordem. Só serve como organização visual. O redesign precisa decidir se mantém (e explica) ou remove.

⚠️ O limite de 8 no botão (`usedTypes.length >= 8`) não bate com as **10** opções do dialog de adicionar (§12.6). Com 8 tipos adicionados, o botão trava e 2 tipos ficam inalcançáveis.

⚠️ `onDuplicate={() => {}}` — o `StepCard` provavelmente renderiza um botão "Duplicar" que **não faz nada** neste contexto (broadcast não permite duplicar tipo). ⚠️ A confirmar: se o botão aparece visualmente inerte ou se o `StepCard` o esconde quando o handler é vazio.

**Passos e `days_overdue`:** a página força `config.days_overdue = 0` em três pontos — ao mapear os passos para exibição, ao criar e ao salvar. Em broadcast não existe dia de atraso.

**Fonte de verdade de `is_active`:** a **coluna** `workflow_steps.is_active` (o motor lê a coluna, não `config.is_active`). O `handleToggleStep` grava **os dois** para retrocompatibilidade.

### 12.6 `BroadcastAddStepDialog` — adicionar canal

Fonte: `src/components/campaigns/BroadcastAddStepDialog.tsx`. Contêiner `max-w-lg`.

**Cabeçalho:** "**Adicionar Canal**" / "Escolha um canal de comunicação. Cada tipo só pode ser usado uma vez."

**Quando todos os tipos já foram usados:** `Alert` com `CheckCircle` — "Todos os tipos de canal já foram adicionados ao broadcast." (o resto do formulário some).

**Campos:**

| Campo | Rótulo | Tipo | Obrigatório |
|---|---|---|---|
| Nome | **Nome da Ação (opcional)** | `Input` (`placeholder="Ex: Comunicado Especial"`) | não — vazio vira o rótulo do canal |
| Tipo | **Tipo de Canal** | `RadioGroup` dentro de `ScrollArea h-[300px] rounded border p-4` | **sim** |

**Catálogo de canais** (10 opções, agrupadas em 3 categorias):

| Categoria | Tipo | Rótulo | Descrição | Ícone |
|---|---|---|---|---|
| **Comunicação** | `send_whatsapp` | WhatsApp | "Enviar mensagem via WhatsApp" | `MessageCircle` |
| | `send_email` | E-mail | "Enviar email automatizado" | `Mail` |
| | `send_rcs` | RCS | "Enviar mensagem rica (RCS): imagem, texto e botões" | `MessageSquare` |
| | `send_sms` | SMS | "Enviar mensagem de texto SMS" | `Smartphone` |
| | `send_voice` | Voz/TTS | "Realizar ligação automatizada com TTS" | `Phone` |
| **Integração** | `webhook` | Webhook | "Disparar webhook para sistema externo" | `Webhook` |
| **Ações** | `human_activity` | Atividade Humana | "Criar tarefa manual para operador" | `User` |
| | `notification` | **Notificacao** | "Enviar notificacao extrajudicial" | `FileWarning` |
| | `negativation` | Negativação | "Negativar cliente em órgãos de proteção" | `AlertTriangle` |
| | `block` | Bloqueio | "Bloquear serviço ou equipamento" | `Ban` |

Rótulos de categoria: **Comunicação**, **Integração**, **Ações** (`text-xs font-medium uppercase text-muted-foreground`).

**Item da lista** (`<label>` clicável, `p-3 rounded-lg border`):

| Estado | Classes |
|---|---|
| Já usado | `opacity-50 cursor-not-allowed bg-muted/30` + `Badge secondary "Já adicionado"` + `RadioGroupItem disabled` |
| Selecionado | `border-primary bg-primary/5` |
| Normal | `hover:bg-muted/50` |

O `RadioGroupItem` é `sr-only` — o rádio não é visível, só o realce da borda indica seleção.

⚠️ Problema de acessibilidade: sem o controle visível e sem outro indicador além da cor da borda, a seleção não é percebível por quem não distingue a cor.

**Rodapé:** **Cancelar** (`outline`) e **Adicionar** (`disabled` quando não há tipo selecionado ou o tipo já existe). Fechar por qualquer caminho limpa nome e seleção.

**Validação dupla de unicidade:** o dialog desabilita o tipo usado, e a página revalida no `handleCreateStep`, com toast destrutivo:

> "**Tipo já adicionado**" / `Você já tem uma ação do tipo "{nome}". Em broadcasts, cada canal só pode ser usado uma vez.`

Ao criar com sucesso: toast "**Ação criada**" / "Configure a ação para ativá-la."

⚠️ O tipo `notification` está no catálogo do dialog mas **não** na lista de tipos aceitos pelo `createStep.mutateAsync` (`send_whatsapp | send_email | send_sms | send_voice | wait | condition | webhook | trigger_ai`). Há um `as` forçando o tipo. ⚠️ A confirmar: se adicionar "Notificacao", "Negativação" ou "Bloqueio" num broadcast funciona de fato.

### 12.7 `StepConfigSheet` — configuração do passo

Aberto ao clicar em "Configurar" num `StepCard`. É o `StepWizard` em `mode="edit"`, compartilhado com o editor de réguas (`src/components/reguas-cobranca/timeline/StepConfigSheet.tsx` e `.../wizard`). **Está fora do escopo deste documento** — é o mesmo componente da tela de Réguas.

O que o editor de broadcast impõe sobre ele:

- Recebe `siblingSteps={steps}` para validações cruzadas.
- No `onSave` (`StepWizardSavePayload` com `stepId`, `config`, `name`, `isActive`), a página força `days_overdue: 0` antes de gravar.
- Erro ao salvar: toast "**Erro**" / "Não foi possível salvar as configurações." e **relança** — o wizard precisa saber que falhou.

### 12.8 Outras operações do editor

| Operação | Gatilho | Sucesso | Erro |
|---|---|---|---|
| Ativar/desativar passo | `Switch` no `StepCard` | silencioso | toast "Erro" / "Não foi possível alterar o status da ação." |
| Reordenar | drag-and-drop | silencioso | toast "Erro" / "Não foi possível reordenar as ações." |
| Excluir passo | botão no `StepCard` | silencioso | toast "Erro" / "Não foi possível excluir a ação." + relança |

⚠️ **Nenhuma dessas operações pede confirmação — inclusive excluir um passo.** É a única exclusão sem confirmação do domínio (a exclusão de campanha usa `window.confirm`). Requisito do redesign.

⚠️ Todas as operações bem-sucedidas são silenciosas: o único feedback é o indicador "Salvando..." → "Salvo" no header, que é fácil de não ver.

Todos os handlers de escrita são passados como `undefined` quando `!canWrite` — o `BroadcastTimelineView` então esconde os controles correspondentes. **Exceção:** `onConfigureStep` é passado **sempre**, então quem não tem `broadcasts:write` ainda abre o sheet de configuração. ⚠️ A confirmar: se o `StepConfigSheet` tem gate próprio de permissão.

---

## 13. Modais do domínio — bloco por modal

Nove superfícies modais. As seções anteriores já detalham o conteúdo; aqui está a ficha operacional de cada uma, no formato que o designer precisa para reconstruí-las.

### 13.1 `CampaignDialog` — Nova / Editar Campanha

| Item | Valor |
|---|---|
| **Arquivo** | `src/components/campaigns/CampaignDialog.tsx` |
| **Objetivo** | Criar ou editar a configuração completa de uma campanha |
| **Gatilho** | Botão "Nova" no header; clique na linha/card de campanha não-concluída; item "Editar" do menu |
| **Contêiner** | `Dialog`, `w-[95vw] max-w-2xl h-[90vh]`, coluna com header/corpo rolável/footer fixos |
| **Título** | "Nova Campanha" / "Editar Campanha", ícone `Target` em caixa `bg-primary/10` |
| **Campos** | 18 campos — inventário completo em §5.3 |
| **Botões** | **Cancelar** (`outline`, fecha sem guarda) · **Criar Campanha** / **Salvar Alterações** (primário, `Loader2` enquanto salva) |
| **Confirmações** | Nenhuma. Nem ao descartar alterações, nem ao ativar |
| **Estados** | Normal · salvando (botão `disabled` + spinner) · réguas carregando (multi-select desabilitado) |
| **Erros** | `FormMessage` inline **e** toast agregado "Erro de validação"; toast destrutivo "Erro ao salvar campanha" |
| **Efeito colateral** | Criar broadcast ativo e imediato **dispara** o `broadcast-processor` (§5.10) |

### 13.2 `CampaignDetailDialog` — Detalhes da Campanha

| Item | Valor |
|---|---|
| **Arquivo** | `src/components/campaigns/CampaignDetailDialog.tsx` |
| **Objetivo** | Ver a configuração e o histórico de execuções de uma campanha, em leitura |
| **Gatilho** | Item "Visualizar" do menu (ambas as visões); clique na linha/card quando `status === "completed"` |
| **Contêiner** | `Dialog`, `w-[95vw] max-w-4xl h-[90vh]`, `p-0` |
| **Título** | "Detalhes da Campanha", ícone `Target`; header com gradiente `from-primary/5` |
| **Abas** | **Informações** (default) · **Histórico** (com badge de contagem) |
| **Botões** | **Ensaiar** (`outline`, só com suporte a dry-run) · **Forçar Execução** (primário, **sem gate de permissão**) |
| **Confirmações** | `ExecuteOutsideWindowDialog` quando fora da janela. Nenhuma outra |
| **Estados** | Carregando (spinner) · sem dados (renderiza nada) · executando ("Executando...") |
| **Erros** | Toasts do `useManualExecuteCampaign` |
| **Não tem** | Editar, pausar, excluir, abrir editor de broadcast |

### 13.3 `CampaignPreviewModal` — Ações previstas

| Item | Valor |
|---|---|
| **Arquivo** | `src/components/campaigns/CampaignPreviewModal.tsx` |
| **Objetivo** | Mostrar o funil real da última ativação + a projeção ao vivo da próxima + o andamento dos envios |
| **Gatilho** | Botão "Ver ações previstas" (`data-testid="open-campaign-preview"`) no rodapé do card, em duas variantes (§4.3.5, §4.3.6) |
| **Contêiner** | `Dialog`, `max-w-2xl max-h-[92vh]`, `p-0 gap-0` — **largura fixa por decisão de produto** |
| **Título** | "Ações previstas — {nome}", ícone `Eye` |
| **Blocos** | A Header · B Funil · C Estimativa · D Andamento · E Detalhes · F Legado (§7.1) |
| **Botões** | **Fechar** (`outline`, rodapé) · link "**Ações ↗**" no funil, que navega para `/actions` filtrado |
| **Confirmações** | Nenhuma — o modal é 100% leitura |
| **Estados** | 5 estados de funil + 3 formas de estimativa + carregando/erro por bloco (§7.1) |
| **Ajuda** | 20 `HelpTip` com cópia estruturada de `campaign-preview-help.ts` (o que é → origem → como calcula → observação) |

### 13.4 `CampaignDryRunDialog` — Ensaiar campanha

| Item | Valor |
|---|---|
| **Arquivo** | `src/components/campaigns/CampaignDryRunDialog.tsx` |
| **Objetivo** | Rodar os passos 1-5 do pipeline sem criar ações e mostrar o que sairia |
| **Gatilho** | Item "Ensaiar (não cria ações)" do menu grade; botão "Ensaiar" no `CampaignDetailDialog` |
| **Contêiner** | `Dialog`, `h-[90vh] w-[95vw] max-w-3xl`, `p-0` |
| **Título** | "Ensaiar campanha" + badge âmbar "**não cria ações**", ícone `FlaskConical` |
| **Campos** | Nenhum — só ação |
| **Botões** | **Rodar ensaio** / **Rodando ensaio...** / **Rodar ensaio novamente**. Sem botão de fechar dedicado (fecha pelo X / overlay) |
| **Confirmações** | Nenhuma — mas **não roda ao abrir**, por decisão de produto |
| **Estados** | Não suportado · ocioso · rodando · erro · `no_campaigns` · `timeout_partial` · concluído |
| **Sempre visível** | Bloco esmeralda com as 3 garantias, inclusive após rodar |
| **Chave de montagem** | O pai passa `key={campaign?.id ?? "closed"}` para não herdar resultado de outra campanha |
| **Escreve no banco** | **Sim** — linha em `campaign_execution_runs` com `is_dry_run = true` |

### 13.5 `CampaignLogDetailDialog` — Detalhe de uma execução

| Item | Valor |
|---|---|
| **Arquivo** | `src/components/campaigns/CampaignLogDetailDialog.tsx` |
| **Objetivo** | Explicar uma execução **de uma campanha**: funil, exclusões por motivo, candidatos, erro |
| **Gatilho** | Clique numa linha da tabela "Histórico de Execuções" (aba Monitoramento) |
| **Contêiner** | `Dialog`, `max-w-5xl max-h-[85vh]`, `p-0 gap-0` — o mais largo do domínio |
| **Título** | Nome da campanha, ícone `Activity`; badges de status, "Pipeline v2" e data |
| **Blocos** | KPIs da campanha · contexto do lote (recolhível) · funil da campanha · exclusões · erro · candidatos (recolhível) |
| **Botões** | "**Ver candidatos detalhados**" / "**Ocultar candidatos**" (largura total) · "Ver/Ocultar números do lote" (link) |
| **Confirmações** | Nenhuma — leitura pura |
| **Estados** | v2 (completo) · v1 legado (`LegacyLogCard`) · lote carregando · sem erro |
| **Regra crítica** | Números da **campanha** vêm do log derivado; números do **lote** ficam confinados à faixa de contexto (§8.5) |

### 13.6 `CancelCampaignActionsDialog` — Cancelar ações pendentes

| Item | Valor |
|---|---|
| **Arquivo** | `src/components/campaigns/CancelCampaignActionsDialog.tsx` |
| **Objetivo** | Freio de emergência: cancelar em massa as ações que ainda não saíram de uma campanha |
| **Gatilho** | Botão `Ban` na última coluna da tabela de Histórico — **só com `actions:write`** |
| **Contêiner** | `AlertDialog` (não `Dialog`) — bloqueia até decidir |
| **Título** | "**Cancelar ações pendentes**" |
| **Montagem** | Só é montado quando há alvo escolhido, para a contagem não rodar por linha |
| **Campos** | Um `Checkbox`: "Incluir também **{n}** em **Processando**" — só aparece se `processing > 0` |
| **Botões** | **Voltar** (`AlertDialogCancel`, `disabled` enquanto cancela) · **Cancelar {N} ação(ões)** (contagem no próprio rótulo) |
| **Estados** | Contando · nada a fazer · pronto · cancelando |

**Corpo, por estado:**

| Estado | Texto |
|---|---|
| Contando | `Loader2` + "Contando ações..." |
| Nada a fazer | "Esta campanha não tem ações pendentes — a fila já foi processada. Ações já enviadas não podem ser canceladas." |
| Pronto | "**{n}** ação(ões) em **Pendente** serão canceladas. Ações já enviadas, com falha ou canceladas não são afetadas." |

**Bloco de opt-in** (âmbar, `border-amber-300 bg-amber-50`), quando há ações em Processando:

```
[✓] Incluir também **{n}** em **Processando**
    Essas já estão saindo. Podem ser **entregues mesmo assim** e ficar
    registradas como canceladas.
```

**Alerta adicional** quando o opt-in é marcado (`Alert variant="destructive"`, `AlertTriangle`):

> "Total a cancelar: {N}. O histórico pode mostrar como cancelada uma mensagem que chegou ao cliente."

O opt-in é **resetado toda vez que o dialog abre** — "reabrir o diálogo nunca herda o opt-in de risco da vez anterior".

**Por que o opt-in é separado** (do próprio código): `Cancelado` tem prioridade 10 contra 2 do `Enviado` no `STATUS_PRIORITY`, então o `send-message` **preserva** o Cancelado — cancelar uma ação cujo POST já saiu grava "Cancelado" numa mensagem que **foi entregue**. "A tela passaria a mentir sobre um contato cobrado."

**Escala do problema** (medida em 60 dias de `org_blips`): maior lote por (campanha, dia) = **4.687** ações, p95 = **1.663**. Por isso o número aparece **antes** de agir e **dentro** do rótulo do botão.

**Toasts de resultado:**

| Resultado | Título | Descrição |
|---|---|---|
| `cancelled === 0`, sem skip | "Nenhuma ação pendente para cancelar" | "A fila desta campanha já foi processada." |
| `cancelled === 0`, com skip | "Nenhuma ação pendente para cancelar" | "{n} ação(ões) em Processando ficaram de fora." |
| `cancelled > 0`, sem skip | "{n} ação(ões) cancelada(s)" | — |
| `cancelled > 0`, com skip | "{n} ação(ões) cancelada(s)" | "{n} em Processando ficaram de fora (já estavam saindo)." |
| Erro | "Falha ao cancelar as ações" | mensagem do erro (destructive) |

O primeiro caso existe para distinguir "nada pendente" de "sucesso": "um toast de sucesso vazio faz o operador achar que cancelou algo que já tinha sido enviado."

**Origem dos números:** RPC `search_actions` (a mesma da lista de Ações), com `p_campaign_id` e `p_statuses`, lendo `total_count`. **Não** existe contagem própria — uma segunda definição de "ação cancelável" divergiria da primeira. Escrita: RPC `cancel_campaign_pending_actions`.

Após cancelar, invalida: `actions`, `campaign-pending-counts`, `scheduled-progress`, `campaign-logs`, `campaign-execution-runs`.

### 13.7 `ExecuteOutsideWindowDialog` — Fora da janela

| Item | Valor |
|---|---|
| **Arquivo** | `src/components/campaigns/ExecuteOutsideWindowDialog.tsx` |
| **Objetivo** | Avisar que o disparo manual está fora do dia/horário configurado, antes de executar |
| **Gatilho** | "Executar Agora" (menu grade) ou "Forçar Execução" (detalhe), quando `checkExecutionWindow().isOutsideWindow` |
| **Contêiner** | `AlertDialog` |
| **Título** | "**Hoje está fora da janela desta campanha**" |
| **Campos** | Nenhum |
| **Botões** | **Cancelar** · **Disparar mesmo assim** (estilizado como destrutivo: `bg-destructive text-destructive-foreground`) |
| **Estados** | Único — retorna `null` sem campanha |

**Corpo — três parágrafos:**

1. "Esta campanha dispara apenas em: **{dias}**, das **{HH:MM}** às **{HH:MM}**."
2. Mensagem contextual (abaixo).
3. "Se você disparar agora, as ações serão criadas mas só vão ser enviadas no próximo dia/horário válido: **{data por extenso}**."

**Mensagem contextual**, quatro variantes:

| Causa | Texto |
|---|---|
| Dia **e** horário fora | `Hoje ({data por extenso}) está fora dos dias ativos e o horário atual está fora da janela.` |
| Só o dia | `Hoje é {data por extenso} — fora dos dias ativos da campanha.` |
| Só o horário | `Agora são {HH:MM} — fora da janela de envio ({início}–{fim}).` |
| Fallback | "Esta campanha está fora da janela de envio configurada." |

A causa é detectada por **prefixo da string** de `windowInfo.reason` (`"Dia atual"` / `"Horário atual"`).

⚠️ Acoplamento frágil: a mensagem técnica de `checkExecutionWindow` virou contrato de UI. Mudar o texto lá quebra a ramificação aqui, silenciosamente.

**Formatos de data:** `toLocaleString("pt-BR", { weekday: "long", day, month, year[, hour, minute], timeZone: "America/Sao_Paulo" })`. Dias exibidos por `formatDaysList`: `—` se vazio, "Todos os dias" com 7, senão abreviações ordenadas (`Dom, Seg, …`).

**Fallbacks de janela** usados quando o campo é nulo: `[1,2,3,4,5,6]`, `08:00:00`, `18:00:00` — os mesmos do backend.

### 13.8 `BroadcastAddStepDialog` — Adicionar Canal

Ficha completa em §12.6. Resumo:

| Item | Valor |
|---|---|
| **Arquivo** | `src/components/campaigns/BroadcastAddStepDialog.tsx` |
| **Objetivo** | Escolher um tipo de canal para o broadcast, com unicidade por tipo |
| **Gatilho** | "Adicionar Primeira Ação" (vazio) ou "Adicionar Canal" (rodapé) — só com `broadcasts:write` |
| **Contêiner** | `Dialog max-w-lg` |
| **Campos** | Nome (opcional) · Tipo de Canal (`RadioGroup` de 10 opções, agrupadas em 3 categorias) |
| **Botões** | **Cancelar** · **Adicionar** (`disabled` sem tipo válido) |
| **Estados** | Normal · saturado ("Todos os tipos de canal já foram adicionados ao broadcast.") |
| **Confirmações** | Nenhuma |

### 13.9 Confirmação nativa — excluir campanha

| Item | Valor |
|---|---|
| **Arquivo** | `src/pages/CampaignsPage.tsx` |
| **Objetivo** | Confirmar a exclusão permanente de uma campanha |
| **Gatilho** | Item "Excluir" do menu (ambas as visões), com `campaigns:delete` |
| **Contêiner** | **`window.confirm()` nativo do browser** |
| **Texto** | "Tem certeza que deseja excluir esta campanha?" |
| **Botões** | OK / Cancelar do sistema operacional |

⚠️ **É a única confirmação do produto que não usa `AlertDialog`.** Não mostra o nome da campanha, não avisa sobre logs/ações associados, não é estilizável e é bloqueante da thread. Substituir é item de alta prioridade do redesign (§17).

### 13.10 `StepConfigSheet` — configuração do passo (externo)

| Item | Valor |
|---|---|
| **Arquivo** | `src/components/reguas-cobranca/timeline/StepConfigSheet.tsx` (+ `.../wizard`) |
| **Objetivo** | Configurar um passo (canal, integração, mensagem, gatilho) |
| **Gatilho** | "Configurar" num `StepCard` do editor de broadcast |
| **Contêiner** | `Sheet` (painel lateral), não `Dialog` |
| **Escopo** | **Compartilhado com a tela de Réguas** — fora do escopo deste documento |
| **Contrato com o editor** | Recebe `step` e `siblingSteps`; devolve `StepWizardSavePayload` = `{ stepId, config, name, isActive }`; a página injeta `days_overdue: 0` |

---

## 14. Estados das telas

Inventário exaustivo por superfície. O redesign precisa de um tratamento explícito para cada linha — muitas delas hoje são silenciosas ou ambíguas.

### 14.1 `/campaigns` — aba Campanhas

Fonte: `src/pages/CampaignsPage.tsx`.

| Estado | Condição | O que a tela mostra |
|---|---|---|
| **Carregando** | `isLoading` do `useCampaigns` | `<CampaignsPageSkeleton viewMode={viewMode} count={6} />` — esqueleto que respeita a visão atual (cards × tabela) |
| **Erro** | `isError` | `<div className="text-center py-12 text-destructive">Erro ao carregar campanhas</div>` — **texto puro, sem ícone, sem botão de retentar** |
| **Vazio sem busca** | lista vazia e `search === ""` | `Target h-12 w-12 text-muted-foreground`, "**Nenhuma campanha encontrada**", "Crie sua primeira campanha" + botão "**Nova Campanha**" (só com `campaigns:write`) |
| **Vazio com busca** | lista vazia e `search !== ""` | mesmo ícone e título, subtexto "Tente ajustar os filtros de busca", **sem** botão |
| **Atualizando** | `isFetching` | o `RefreshButton` gira; a lista atual permanece visível |
| **Prévias carregando** | `previewLoading` | cada rodapé de card mostra `Loader2` + "Carregando prévia..." independentemente |
| **Nomes de régua carregando** | `useWorkflowNames` pendente | cada badge de régua mostra o placeholder literal **`"..."`** |
| **Alternando status** | `toggleStatus.isPending` | **todos** os switches da página ficam `disabled` ao mesmo tempo |
| **Executando manualmente** | `manualExecute.isPending` | o item de menu vira "Executando..." e fica `disabled` |
| **Sem permissão de escrita** | `!campaigns:write` | somem: botão "Nova", "Editar", "Executar Agora", "Ensaiar", "Configurar Ações", "Pausar/Ativar". O `Switch` fica `disabled` (não some) |
| **Sem permissão de exclusão** | `!campaigns:delete` | somem o separador e o item "Excluir" |

⚠️ O estado de erro é o mais fraco da tela: sem ícone, sem detalhe, sem ação de recuperação. E o `disabled` global dos switches faz parecer que a página inteira travou ao pausar uma campanha.

### 14.2 `/campaigns` — aba Monitoramento

| Estado | Condição | O que a tela mostra |
|---|---|---|
| **Sem runs hoje** | `todayRuns` vazio | o card "Pipeline v2 — Hoje" **não é renderizado** — some inteiro, sem explicação |
| **Carregando histórico** | `isLoading` | `Loader2 h-8 w-8` centralizado, `py-12` |
| **Histórico vazio** | `filteredLogs.length === 0` | `Activity h-12 w-12`, "Nenhuma execução encontrada" + "As execuções aparecerão aqui quando as campanhas forem disparadas" |
| **Erro do histórico** | — | **não tratado** — a query lança e a tela fica presa no estado de carregamento ou vazio |
| **Run em andamento** | `current_step` não terminal, heartbeat recente | `Loader2` azul, badge "Em andamento", borda azul, trilha com passo atual girando |
| **Run travado** | não terminal, sem progresso há > 15 min | `AlertTriangle` âmbar, badge "Travado", borda âmbar, botão **Retry** |
| **Run falhou** | `current_step === "failed"` | `XCircle`, badge "Falhou", borda destrutiva, `X` no passo que falhou, botão **Retry** |
| **Run concluído** | `current_step === "completed"` | `CheckCircle2` verde, badge "Concluido", trilha toda verde |
| **Run de prévia** | `is_dry_run === true` | badge âmbar "Prévia — nenhuma ação criada"; último passo da trilha **fica cinza** |
| **Retentando** | `retrying` | botão vira `Loader2` + `disabled` |
| **Sem `actions:write`** | — | a coluna do botão `Ban` **não é renderizada** (o `TableHead` também some) |

⚠️ **O card "Pipeline v2 — Hoje" sumir quando não há runs é ambíguo**: é indistinguível de "nada rodou hoje" e de "a query falhou". Requisito do redesign: um estado explícito.

⚠️ Não há estado de erro para `all-campaign-logs`. Uma falha de rede deixa a aba parecendo vazia.

### 14.3 `/campaigns` — aba Repique

| Estado | Condição | O que a tela mostra |
|---|---|---|
| Carregando KPIs | `isLoading` | os 4 `KPICard` mostram o esqueleto nativo |
| Carregando tabela | `isLoading` | 8 linhas de `Skeleton` com 5 blocos cada |
| Vazio | `actions.length === 0` | `Repeat h-12 w-12 opacity-50` + "Nenhuma acao com repique no periodo selecionado" |
| **Erro** | query rejeitada | **sem tratamento** — cai no estado vazio, indistinguível |

### 14.4 Modais

| Modal | Carregando | Vazio | Erro | Em execução |
|---|---|---|---|---|
| `CampaignDialog` | só o multi-select ("Carregando réguas...") | — | `FormMessage` + toast agregado | botão `disabled` + `Loader2` |
| `CampaignDetailDialog` | `Loader2 h-8 w-8` na aba Informações; `Loader2 h-6 w-6` na aba Histórico | "Nenhuma execução registrada" + dica; "Nenhuma régua associada" | **não tratado** (dado nulo renderiza nada) | "Executando..." + `disabled` |
| `CampaignPreviewModal` | `Loader2` por métrica; "Carregando andamento..." no bloco D | 5 variantes de empty-state do funil (§7.1); "Sem exclusões registradas para detalhar"; "Sem execução registrada para detalhar motivos por título." | faixa destrutiva "Erro ao carregar prévia: {msg}" acima do funil | — (leitura pura) |
| `CampaignDryRunDialog` | "Rodando os passos 1 a 5..." + 2 `Skeleton`; 6 `Skeleton` no resultado | "Nada para ensaiar" | `Alert` destrutivo + "Tentar novamente" (persistente) | botão "Rodando ensaio..." + `disabled` |
| `CampaignLogDetailDialog` | "Carregando o contexto do lote..." | "Nenhum candidato foi excluído nesta execução." | card "Erro na execução" / "Erro na execução do lote" | — |
| `CancelCampaignActionsDialog` | "Contando ações..." | "Esta campanha não tem ações pendentes…" + confirmar `disabled` | toast "Falha ao cancelar as ações" | "Cancelando..." + `disabled` nos dois botões |
| `ExecuteOutsideWindowDialog` | — | retorna `null` sem campanha | — | — |
| `BroadcastAddStepDialog` | — | "Todos os tipos de canal já foram adicionados ao broadcast." | toast "Tipo já adicionado" | — |
| `CampaignReasonsDrilldown` | 5 linhas de `Skeleton` | "Nenhum titulo encontrado para este motivo."; "Nenhuma execucao registrada…" | `AlertCircle` + mensagem + "Tentar novamente" | — |
| `CampaignExecutionCandidatesTable` | "Carregando..." em `colSpan={7}` | "Nenhum candidato encontrado" + nota das 48 h | **não tratado** | — |

### 14.5 Editor de Broadcast

| Estado | Condição | O que a tela mostra |
|---|---|---|
| Carregando | régua ou campanha pendente | `h-screen` centralizado com `Loader2 h-8 w-8` |
| Régua não encontrada | `!workflow` | "Workflow não encontrado" + botão **Voltar** |
| Sem passos | `steps.length === 0` | `Megaphone h-12 w-12`, "Nenhuma ação configurada" + botão "Adicionar Primeira Ação" |
| Salvando | qualquer mutação em voo | header mostra `Loader2` + "Salvando..." |
| Ocioso | sem mutação | header mostra `Save` + "Salvo" (**permanente**, não é feedback de ação) |
| Todos os canais usados | `usedTypes.length >= 8` | botão "Adicionar Canal" `disabled` + "Todos os tipos de canal já foram adicionados" |
| Ativação bloqueada | passos incompletos ou zero passos | toast destrutivo, o switch **volta sozinho** |
| Sem `broadcasts:write` | — | somem: toggle de passo, excluir, adicionar, reordenar. **Configurar continua disponível** |
| Sem `?campaign=` | query string ausente | título cai para o nome da régua; badge de agendamento some; switch **não faz nada** mas continua clicável |
| Erro de operação | qualquer mutação falha | toast "Erro" com mensagem genérica |

### 14.6 Execução travada — representação atual (resumo)

| Onde | Sinal |
|---|---|
| `PipelineRunStatusCard` | badge "**Travado**" + borda âmbar + `AlertTriangle` + botão Retry (limiar de 15 min sem heartbeat) |
| `CampaignExecutionRunsList` | **nenhum** — trata qualquer passo não terminal como `Clock` âmbar |
| `ExecutionMonitoringPanel` (tabela) | **nenhum** — o log fica em "Executando" indefinidamente |
| `CampaignDetailDialog` (histórico) | **nenhum** — badge "Executando" sem limite de tempo |

⚠️ Só **uma** das quatro superfícies detecta travamento. As outras três mostram "Executando" para sempre.

### 14.7 Erro que pode não ser falha — representação atual (resumo)

| Onde | Sinal | Suficiente? |
|---|---|---|
| `CampaignDryRunDialog` | status `timeout_partial` → "Ensaio parcial", nomeia o passo, "rode novamente" | **sim** — é o melhor vocabulário existente |
| `PipelineRunStatusCard` | run vira "Travado" com Retry | parcial — não explica a ambiguidade |
| `CampaignLogDetailDialog` | separa "Erro na execução" de "Erro na execução do lote" | parcial |
| Toasts de execução manual | "Erro ao executar campanha: {msg}" | **não** — afirma falha categoricamente |
| `error_details` exibido | `Step <passo> failed: <msg>` cru | **não** — texto técnico, afirma falha |

⚠️ Gap central: **a UI não tem um estado "indeterminado"**. Quando o teto de tempo do proxy devolve erro para um trabalho que foi concluído e commitado, a tela diz "falhou". O redesign deve introduzir um terceiro estado — algo como "**Não sabemos se concluiu — verifique no Monitoramento antes de repetir**".

---

## 15. Fluxos de uso passo a passo

Cada fluxo abaixo é o caminho real no código, com os pontos de decisão e os textos que o usuário vê.

### 15.1 Criar uma campanha recorrente

| # | Passo | Onde | O que acontece |
|---|---|---|---|
| 1 | Garantir que a régua existe | `/reguas-cobranca` | Pré-requisito: régua sequencial com passos e público. "Sem ela, não há o que enviar" |
| 2 | Clicar em **Nova** | header de `/campaigns` | Abre o `CampaignDialog` em modo criação (só com `campaigns:write`) |
| 3 | Escolher **Régua de Cobrança** | seção A | Mantém `recurring`; limpa `target_reguas`; aplica os defaults `[1..5]` / `20:00` |
| 4 | Preencher Nome (obrigatório) e Descrição | seção B | Validação Zod no nome |
| 5 | Selecionar uma ou mais **Réguas de Cobrança** | seção B | Multi-select de réguas sequenciais; chips mostram estado ativo/inativo |
| 6 | Decidir **Campanha Ativa** | seção C | Ligado = `active`, desligado = `draft` |
| 7 | Ajustar **Janela de Atendimento** | seção C.2 | Horários e dias da semana |
| 8 | Ajustar **Ações por Minuto** e **Cooldown** | seção D | Slider 1-100; 3 modos de cooldown |
| 9 | Escolher o **Tipo de Gatilho** | seção E | Agendado (CRON) / Manual / Após Pipeline ETL |
| 10a | Se Agendado: escolher preset ou digitar CRON | seção E | Tradução em linguagem natural aparece abaixo |
| 10b | Se Após Pipeline: escolher o pipeline | seção E | Obrigatório no submit |
| 11 | Clicar **Criar Campanha** | rodapé | Gates de régua e pipeline; erro vira toast "Erro de validação" |
| 12 | Conferir a prévia | rodapé do card na lista | Contatos elegíveis, ~ações estimadas, custo estimado |

O guia do app recomenda o caminho seguro: "crie a campanha como Rascunho, confira a prévia e só então ative."

### 15.2 Criar um broadcast (disparo pontual)

| # | Passo | Diferença em relação ao fluxo acima |
|---|---|---|
| 1 | Escolher **Disparo Pontual** | Defaults viram `[1..6]` / `18:00`; a seção E (Producer) **some** |
| 2 | Selecionar **Réguas de Broadcast** | Lista só `workflow_type = 'broadcast'` |
| 3 | Conferir **Público-Alvo** | Aparecem `WorkflowFilterPreview` + `RepiquePreview` por régua |
| 4 | Escolher **Quando Disparar** | Manual (imediato) ou Agendar com data/hora |
| 5 | Decidir **Repique** | Switch com aviso âmbar quando ligado |
| 6 | Clicar **Criar Campanha** | O submit força `producer_trigger_type = "manual"` |
| 7 | **Disparo automático** | Se ativo + imediato, o formulário **aguarda** o `broadcast-processor` e mostra "Campanha criada e disparada!" ou "Campanha criada, mas o disparo falhou" |
| 8 | Configurar as ações | **Não é automático** — voltar à lista e usar "Configurar Ações" no menu |

⚠️ Furo de fluxo: um broadcast recém-criado com "Campanha Ativa" ligada **dispara antes de ter ações configuradas**. As validações de `useToggleCampaignStatus` (que exigem passos configurados) só rodam no toggle, **não** na criação. O redesign deveria fechar essa porta.

### 15.3 Ensaiar antes de disparar

| # | Passo | Detalhe |
|---|---|---|
| 1 | Abrir o menu da campanha (visão **grade**) | O item "Ensaiar" **não existe na visão lista** |
| 2 | Clicar em **Ensaiar (não cria ações)** | Requer `campaigns:write` e `campaignSupportsDryRun`. **Não** exige status ativo nem trigger manual |
| 3 | Ler as 3 garantias | Bloco esmeralda, sempre visível. O ensaio **não roda sozinho** |
| 4 | Clicar em **Rodar ensaio** | Invoca `campaign-pipeline-preview` com `dry_run: true` |
| 5 | Ler os 6 números | "Acoes que seriam criadas" é o número que importa (`matches_after_cross_dedup`) |
| 6 | Abrir **Motivos por título** | Drill-down com as 3 disposições transitórias liberadas |
| 7 | Rodar de novo, se parcial | `timeout_partial` → "rode novamente para um resultado completo" |

Caminho alternativo: botão **Ensaiar** no cabeçalho do `CampaignDetailDialog`, que vem **antes** do "Forçar Execução" de propósito.

### 15.4 Executar manualmente

| # | Passo | Detalhe |
|---|---|---|
| 1 | Abrir o menu da campanha | "Executar Agora" exige `campaigns:write` **+** trigger manual **+** `status === "active"` |
| 2 | Clicar em **Executar Agora** | `handleExecuteNow` roda `checkExecutionWindow(campaign)` |
| 3a | Dentro da janela | Executa direto |
| 3b | **Fora da janela** | Abre o `ExecuteOutsideWindowDialog`; opções **Cancelar** / **Disparar mesmo assim** |
| 4 | O executor é escolhido pelo tipo | broadcast → `broadcast-processor`; recorrente v2 → `campaign-pipeline-orchestrator`; recorrente v1 → `campaign-executor` (com log `pending` criado antes) |
| 5 | Ler o toast | "Execução iniciada" (página) + toast do hook com os números ou o erro |
| 6 | Acompanhar | Aba **Monitoramento** |

Caminho alternativo: **Forçar Execução** no `CampaignDetailDialog` — mesmo fluxo, **sem** os gates de permissão/status/trigger.

### 15.5 Monitorar uma execução em andamento

| # | Passo | O que observar |
|---|---|---|
| 1 | Abrir a aba **Monitoramento** | Atualiza sozinha a cada 30 s |
| 2 | Olhar o card "Pipeline v2 — Hoje" | Um cartão por lote; a trilha de 6 passos mostra onde está |
| 3 | Distinguir os estados | Azul girando = andando · âmbar `AlertTriangle` = **travado** · verde = concluído · vermelho = falhou |
| 4 | Expandir o cartão | 6 métricas, linha de pulados, erro truncado em 300 caracteres |
| 5 | Se travado ou falhou: **Retry** | Re-invoca o orquestrador com `{ run_id }` — mesmo caminho do watchdog automático |
| 6 | Ir ao Histórico | Uma linha por campanha por execução; clicar abre o detalhe |
| 7 | No detalhe, separar campanha de lote | KPIs e funil = campanha; "Ver números do lote" = lote |
| 8 | Investigar exclusões | Barras por motivo real, com percentual |
| 9 | Ver candidatos | Botão "Ver candidatos detalhados" — **disponível por 48 h** |

### 15.6 Cancelar as ações pendentes de uma campanha (freio de emergência)

| # | Passo | Detalhe |
|---|---|---|
| 1 | Perceber que a campanha disparou errado | A janela entre criar e enviar chega a **76 h** num lote de sábado |
| 2 | Ir a Monitoramento → Histórico de Execuções | Localizar a linha da campanha |
| 3 | Clicar no botão `Ban` da última coluna | Só visível com `actions:write`. Tooltip "Cancelar ações pendentes desta campanha" |
| 4 | Ler a contagem | "Contando ações..." → "**{n}** ação(ões) em **Pendente** serão canceladas" |
| 5 | Decidir sobre **Processando** | Checkbox de opt-in, **desligado por padrão**, resetado a cada abertura |
| 6 | Se marcar, ler o alerta vermelho | "O histórico pode mostrar como cancelada uma mensagem que chegou ao cliente." |
| 7 | Confirmar | Botão com a contagem no rótulo: "Cancelar {N} ação(ões)" |
| 8 | Ler o toast | Distingue "Nenhuma ação pendente para cancelar" de "{n} ação(ões) cancelada(s)" |

**Por que as outras ferramentas não servem** (documentado no hook):

| Ferramenta | Por que erra o alvo |
|---|---|
| "Pausar Envios" (tela de Ações) | para **todas** as campanhas do canal |
| "Pausar" a campanha | só impede execuções **futuras** |
| Cancelar ação por ação | um clique por linha — inviável para milhares |

### 15.7 Montar e disparar um broadcast completo

| # | Passo | Onde |
|---|---|---|
| 1 | Criar o broadcast | `CampaignDialog` (§15.2), preferencialmente como **Rascunho** |
| 2 | Abrir o menu do card → **Configurar Ações** | Navega para `/broadcasts/{regua}/editor?campaign={id}` |
| 3 | Clicar em **Adicionar Primeira Ação** / **Adicionar Canal** | `BroadcastAddStepDialog` |
| 4 | Escolher o tipo de canal e (opcional) nomear | Cada tipo só uma vez |
| 5 | Clicar em **Configurar** no cartão criado | `StepConfigSheet` — integração, conteúdo, nome, ativo |
| 6 | Repetir para outros canais | Todos executam **em paralelo** |
| 7 | (Opcional) Reordenar arrastando | Não afeta a execução |
| 8 | Conferir o selo de agendamento no header | Só aparece com `scheduled_at` |
| 9 | Ligar o switch **Ativo** | Três camadas de validação (§12.4); ativar também **dispara** se for imediato |
| 10 | Acompanhar | Voltar a `/campaigns` → aba Monitoramento |

⚠️ O passo 10 exige navegar manualmente: o botão **Voltar** do editor leva a `/reguas-cobranca`, não a `/campaigns`.

### 15.8 Reconciliar "previstas" × "reais"

Este é o fluxo que o modal de prévia existe para resolver.

| # | Passo | O que se aprende |
|---|---|---|
| 1 | Olhar o rodapé do card | "~{n} estimadas" — projeção ao vivo, **bruta** |
| 2 | Clicar em **Ver ações previstas** | Abre o modal |
| 3 | Ler o **Funil de elegibilidade** | Total → 5 exclusões → **Elegível** |
| 4 | Comparar `Elegível` com `~estimadas` | `Elegível ≤ estimadas` sempre. A diferença é o que as 5 linhas explicam |
| 5 | Ler o **Motivo dominante** | "62% das exclusões foram cooldown" |
| 6 | Clicar em **Ações ↗** | Abre `/actions?campaignId=…&startDate=…&endDate=…` |
| 7 | Conferir a contagem lá | Deve bater **1:1** com o `Elegível` |

O texto do próprio produto: "Por muito tempo o número de 'ações previstas' do card não batia com o total da tela de Ações — e o time achava que estava errado. Não estava: são dois universos."

---

## 16. Responsividade e acessibilidade

### 16.1 Breakpoints em uso

O produto usa os breakpoints padrão do Tailwind. Os efetivamente aplicados no domínio:

| Prefixo | Largura | Onde aparece |
|---|---|---|
| (base) | < 640 px | 1 coluna em tudo |
| `sm:` | ≥ 640 px | header da página, botão "Nova", espaçamentos, filtros |
| `md:` | ≥ 768 px | grade de cards (2 colunas), KPIs do Monitoramento, blocos do modal de prévia |
| `lg:` | ≥ 1024 px | grade de cards (3 colunas), KPIs (4 colunas) |

### 16.2 Comportamento responsivo por superfície

| Superfície | Mobile (< 640) | ≥ `sm` | ≥ `md` | ≥ `lg` |
|---|---|---|---|---|
| Container da página | `space-y-4` | `space-y-6` | — | — |
| Título | `text-xl` | `text-2xl` | — | — |
| Subtítulo "Controle o disparo…" | **oculto** (`hidden sm:block`) | visível | — | — |
| Botão "Nova" | quadrado, só ícone `+` | com rótulo (`sm:w-auto sm:px-4`) | — | — |
| Filtros | coluna (`flex-col`) | linha (`sm:flex-row`) | — | — |
| Select de status | largura total | `w-[180px]` | — | — |
| Grade de cards | 1 coluna | 1 coluna | **2 colunas** | **3 colunas** |
| KPIs do Monitoramento | 1 coluna | 1 coluna | 2 colunas | 4 colunas |
| Métricas do dry-run | 2 colunas | 2 colunas | — | `sm:grid-cols-3` |
| Estimativa (bloco C herói) | 2 colunas | 2 colunas | **3 colunas** | — |
| Detalhes do modal de prévia | 1 coluna | 1 coluna | **2 colunas** | — |
| Números do lote | 2 colunas | `sm:grid-cols-5` | — | — |
| Modais | `w-[95vw]` | `w-[95vw]` com teto (`max-w-2xl`/`4xl`/`5xl`) | — | — |

### 16.3 Problemas de responsividade identificados

| Problema | Onde | Detalhe |
|---|---|---|
| **Tabela sem tratamento mobile** | visão lista de `/campaigns` | `<Table>` dentro de `rounded-md border` **sem** `overflow-x-auto`. 6 colunas em 360 px de largura |
| **Tabela de histórico idem** | aba Monitoramento | 10 colunas dentro de `ScrollArea h-[500px]`, sem scroll horizontal explícito |
| **Grade fixa de 3 colunas** | KPIs do detalhe da campanha | `grid-cols-4` e `grid-cols-3` **sem prefixo responsivo** — não quebram no mobile |
| **Grade fixa no custo** | `CampaignCostBreakdown` | `grid-cols-3` sem breakpoint |
| **Grade fixa nos KPIs do log** | `CampaignLogDetailDialog` | `grid-cols-3` sem breakpoint |
| **Trilha de 6 passos** | `PipelineRunStatusCard` | `flex` sem `flex-wrap`; 6 ícones + 6 rótulos + 5 traços não cabem em telas estreitas |
| **Funil com rótulo `w-44`** | `CampaignExecutionFunnel` | 176 px fixos de rótulo + barra + delta |
| **Modal de 90 vh** | `CampaignDialog`, `CampaignDryRunDialog` | altura fixa em viewport curta (teclado aberto no mobile) |
| **`min-w-[720px]`** | `CampaignExecutionCandidatesTable` | tem `overflow-x-auto` — **é a única tabela do domínio que trata isso** |

⚠️ Conclusão para o redesign: **o domínio de campanhas não foi desenhado para mobile**. Só o header, os filtros e a grade de cards têm tratamento; tabelas e modais assumem desktop.

### 16.4 Acessibilidade — o que existe

| Prática | Onde |
|---|---|
| `DialogDescription` para leitor de tela | `CampaignDetailDialog` usa `sr-only` |
| `aria-hidden` em ícones decorativos | `CampaignFunnelReal` (`Info`, `CheckCircle2`), `CampaignActivityMatrix` (separadores `·`) |
| `Label` com `htmlFor` | `BroadcastScheduleInput`, `CancelCampaignActionsDialog`, `BroadcastAddStepDialog` |
| Navegação por teclado no drag-and-drop | `KeyboardSensor` + `sortableKeyboardCoordinates` no `BroadcastTimelineView` |
| `HelpTip` como irmão do trigger | `CampaignPreviewModal` — comentário explícito "nunca botão-dentro-de-botão" |
| `title` em botão | "Ensaiar" no `CampaignDetailDialog` |
| `title` no texto truncado | coluna "Detalhes" da tabela de candidatos |
| `AlertDialog` para ações destrutivas | cancelamento em massa, fora da janela |
| `tabular-nums` em números | tabelas de custo, candidatos, andamento |

### 16.5 Acessibilidade — problemas identificados

| Problema | Onde | Impacto |
|---|---|---|
| **Cabeçalho de coluna só com ícone** | 4 colunas da tabela de histórico (`Users`, `Zap`, `SkipForward`, `AlertTriangle`) | Sem texto nem `aria-label`; o significado só existe no tooltip, inacessível por teclado |
| **Rádio `sr-only` sem indicador alternativo** | `BroadcastAddStepDialog` | A seleção é comunicada **só pela cor da borda** |
| **Estado do run só por cor** | `PipelineRunStatusCard` | Azul/âmbar/verde/vermelho — há ícone distinto, mas o badge textual "Travado"/"Em andamento" ajuda. Aceitável, mas a trilha de passos é só cor + ícone |
| **`window.confirm` nativo** | excluir campanha | Fora do fluxo de foco da aplicação; sem contexto do que será excluído |
| **Coluna de ação sem cabeçalho** | tabela de histórico (`w-[52px]`) | `TableHead` vazio — leitor de tela anuncia célula sem nome |
| **Botão `Ban` sem `aria-label`** | idem | Só ícone; o nome acessível depende do tooltip |
| **Tooltips como única fonte de informação** | vários | `TooltipTrigger` sem `asChild` em alguns pontos gera `<button>` aninhado |
| **Toast como único canal de erro de validação** | `CampaignDialog` (campos sem rótulo mapeado) | Erro aparece com a **chave técnica** do campo |
| **Menu de ações com `stopPropagation` em `onPointerDown`** | card da visão grade | Pode interferir com navegação por teclado/leitor |
| **Sem `aria-live`** | estados de execução em andamento | Mudança de "Em andamento" → "Concluido" não é anunciada |
| **Contraste de texto em barras coloridas** | `CampaignExecutionFunnel` usa `text-white` hardcoded sobre 6 cores diferentes | Não garante contraste em todas |
| **Ausência de foco visível gerenciado** | modais que abrem outros modais (`CampaignDetailDialog` → dry-run / fora da janela) | Ordem de foco não é declarada |

⚠️ A confirmar: se os componentes base (`src/components/ui/`, shadcn) já cobrem foco e ARIA de `Dialog`, `AlertDialog`, `Select` e `Tabs` — o código do domínio não adiciona nada além do listado.

---

## 17. Dores e oportunidades para o redesign

Organizadas por severidade. Cada item cita onde foi observado.

### 17.1 Bloqueadores — inconsistências que produzem erro de leitura

| # | Dor | Evidência | Oportunidade |
|---|---|---|---|
| B1 | **Menu de ações diferente entre visão lista e visão grade** | §4.2 × §4.3.7 — "Configurar Ações", "Executar Agora" e "Ensaiar" só existem na grade | Um único conjunto de ações, independente da visão |
| B2 | **Dois catálogos de status de log** | §8.4 — `completed_with_errors` é "Com erros" no Monitoramento e "Concluído com erros" no detalhe; `deferred` e `failed_retrying` só existem num; `superseded` só no outro | Fonte única de rótulos de status de log |
| B3 | **Três vocabulários para os mesmos motivos de exclusão** | §9.3 — `DISPOSITION_LABELS`, `campaign-log-funnel` e `EXCLUSION_LABELS` do modal | Um catálogo canônico com acentuação correta |
| B4 | **Duas definições de "sucesso"** | §6.4 × §8.3 — `completed_with_errors` conta como sucesso num KPI e não no outro | Definir e documentar uma |
| B5 | **Duas fórmulas de custo** | §10.2 — `calculateEstimatedCost` soma custo de IA; `calculateCostBreakdown` não | Decidir a verdade e unificar |
| B6 | **Duas definições de "configuração completa"** no mesmo fluxo de ativação | §12.4 — camada local × `useToggleCampaignStatus` | Uma validação, aplicada nos dois pontos |
| B7 | **Duas somas de "pulados" na mesma aba** | §8.3 — o KPI exclui `skipped_already_contacted`, a coluna inclui | Alinhar |
| B8 | **Dois `formatDays` com regras diferentes** | §4.3.4 × §6.4 — "Seg - Sex" × "Segunda, Terça, Quarta, Quinta, Sexta" | Um formatador |
| B9 | **`window.confirm` nativo para excluir campanha** | §13.9 — única confirmação fora do padrão, sem nome da campanha nem aviso de impacto | `AlertDialog` com nome e consequências |
| B10 | **Estado indeterminado não existe** | §14.7 — erro por teto de tempo do proxy é exibido como falha categórica | Terceiro estado: "não sabemos se concluiu" |

### 17.2 Alto impacto — lacunas funcionais

| # | Dor | Evidência | Oportunidade |
|---|---|---|---|
| A1 | **Erro indistinguível de vazio** em duas superfícies | §11.4 (aba Repique) e §14.2 (histórico do Monitoramento) | Estado de erro explícito com retentar |
| A2 | **Estado de erro da lista é texto puro** | §14.1 — "Erro ao carregar campanhas", sem ícone nem ação | Padrão de erro com recuperação |
| A3 | **Card "Pipeline v2 — Hoje" some quando vazio** | §14.2 | Estado explícito "Nenhuma execução hoje" |
| A4 | **Travamento detectado em uma só superfície** | §14.6 — 3 de 4 telas mostram "Executando" para sempre | Propagar o selo "Travado" |
| A5 | **KPIs derivados de amostra sem avisar** | §6.4 (últimos 50 logs) e §8.3 (últimos 100) | Declarar o recorte, ou paginar de verdade |
| A6 | **Campo de busca que não funciona** | §8.8 — `CampaignExecutionCandidatesTable` ignora `filters.search` | Implementar ou remover |
| A7 | **Filtros do broadcast sem UI** | §5.3 — `broadcast_filter_ids`/`logic` existem no schema e aparecem no card, mas não há controle | Expor ou remover a leitura |
| A8 | **Status `cancelled` não filtrável** | §4.1 — existe como status e tem badge, mas falta no `Select` | Incluir |
| A9 | **Sem controle de ordenação na lista** | §4.1 — `created_at` desc fixo | Ordenação por nome, status, última execução |
| A10 | **Abas não sincronizadas com a URL** | §3.3 — recarregar volta para "Campanhas" | Deep-link por aba |
| A11 | **Broadcast multi-régua com uma só régua editável** | §12.1 — só `target_reguas[0]` tem entrada no menu | Seletor de régua no editor |
| A12 | **Broadcast pode disparar sem ações configuradas** | §15.2 — criar ativo+imediato dispara antes de o editor ser aberto | Validar na criação, ou nascer sempre como rascunho |
| A13 | **Excluir passo sem confirmação** | §12.8 — única exclusão sem guarda | `AlertDialog` |
| A14 | **Sem guarda de alterações não salvas** | §5.11 — Cancelar fecha o formulário longo sem avisar | Confirmação de descarte |
| A15 | **Custo realizado inexistente** | §10.5 — lacuna de dado, declarada no código | Instrumentar no backend antes de expor |

### 17.3 Médio impacto — atrito de uso

| # | Dor | Evidência | Oportunidade |
|---|---|---|---|
| M1 | **Três padrões de paginação** | §4.4, §7.3, §11.3 | Um componente |
| M2 | **Cabeçalhos de coluna só com ícone** | §8.4, §16.5 | Texto + ícone |
| M3 | **Formulário longo de rolagem única, sem navegação** | §5.1 — 5 seções em 90 vh sem stepper nem índice | Passos ou navegação lateral |
| M4 | **"Forçar Execução" sem gate de permissão** | §6.2 — `viewer` consegue disparar pelo detalhe | Aplicar os mesmos gates do menu |
| M5 | **Retry de run sem gate de permissão** | §8.2 | Idem |
| M6 | **Switch desabilita todos os switches da página** | §14.1 | Desabilitar só o afetado |
| M7 | **"Salvo" permanente no editor** | §12.3 — é "sem mutação em voo", não "salvo com sucesso" | Feedback de ação real |
| M8 | **Voltar do editor leva a `/reguas-cobranca`** | §12.3 | Voltar para a origem |
| M9 | **Reordenar passos sem efeito funcional** | §12.5 — card diz "execução paralela" | Remover ou explicar o propósito |
| M10 | **Limite de 8 canais × 10 tipos ofertados** | §12.5 × §12.6 | Alinhar |
| M11 | **Toggle "Ativo" desligado grava `draft` no formulário e `paused` no editor** | §5.7.1 × §12.4 | Um comportamento |
| M12 | **Cooldown custom não memoriza o último valor** | §5.8.2 | Persistir na sessão do formulário |
| M13 | **CRON sem validação de sintaxe** | §5.9 — salva expressão inválida | Validar antes de salvar |
| M14 | **Zero dias da semana é salvável** | §5.7.3 — campanha que nunca dispara | Exigir ao menos um |
| M15 | **Filtro invisível de "Teste Integracao"** | §4.1 — o hook sempre oculta essa campanha | Tornar explícito ou remover |
| M16 | **Detalhe da campanha não mostra tipo, cooldown, CRON, agendamento nem repique** | §6.7 | Completar |
| M17 | **Status da régua buscado e não exibido** | §6.4 | Exibir, como no formulário |
| M18 | **Drill-down só mostra a última run do escopo** | §7.3 — MVP declarado | Seletor de run |

### 17.4 Copy e polimento

| # | Dor | Evidência |
|---|---|---|
| C1 | **Textos sem acentuação em blocos inteiros** | `RepiquePreview` (§5.6.2), `CampaignReasonsDrilldown` (§7.3), `PipelineRunStatusCard` (§8.2), `RepiqueTab` (§11.3), `CampaignExecutionRunsList` (§8.9), `DISPOSITION_LABELS` (§9.1), `CampaignCostBreakdown` ("Acoes"), `LegacyLogCard` |
| C2 | **`'as'` sem crase no formato de data** | §11.3 — "18/09/2026 as 14:30" |
| C3 | **Número do dia da semana no aviso de janela** | §7.1 — "Dia atual (0) não está nos dias ativos" |
| C4 | **"Workflow" no lugar de "régua"** | §12.2 — "Workflow não encontrado" |
| C5 | **"ações" × "contatos" no mesmo controle** | §5.8.1 — rótulo "Ações por Minuto", valor "{n} contatos/min", card "{n} ações/min" |
| C6 | **`-...` quando `title_id` é nulo** | §8.8 |
| C7 | **Canal `rcs` sem rótulo no cálculo de custo** | §10.2 |
| C8 | **Disposição `fetched` sem rótulo** | §9.4 |
| C9 | **Período "all" que na verdade são 12 meses** | §11.1 |
| C10 | **Motivo de exclusão não traduzido na tabela de candidatos** | §8.8 — inglês cru, enquanto o drill-down traduz |
| C11 | **Erro de validação mostra chave técnica** | §5.11 — só `name`, `description` e `target_reguas` têm rótulo |
| C12 | **Texto de duração truncado em 200/300 caracteres sem "ver mais"** | §6.5, §8.2 |

### 17.5 O que NÃO mexer

Decisões de produto com história documentada. Alterá-las reintroduz defeitos conhecidos:

| # | Regra | Por quê |
|---|---|---|
| P1 | **"Aguardando disparo" não pode virar algo mais otimista** | §4.3.3 — o rótulo antigo "Em execução" escondeu um cron morto por ~48 dias |
| P2 | **Criar broadcast ativo e imediato DEVE disparar, com `await`** | §5.10 — fire-and-forget com toast de sucesso foi a causa do mesmo incidente |
| P3 | **O ensaio não pode rodar sozinho ao abrir** | §7.2 — as garantias precisam ser lidas antes |
| P4 | **As 3 garantias do ensaio ficam visíveis mesmo após rodar** | §7.2 |
| P5 | **"Ensaiar" vem ANTES de "Forçar Execução"** | §6.2 — é a alternativa segura |
| P6 | **"Ensaiar" não herda os gates de trigger/status** | §4.3.7 — ensaiar campanha agendada ou pausada é o caso de uso |
| P7 | **O modal de prévia tem largura fixa e ordem fixa** | §7.1 — esqueleto único, seções nunca somem |
| P8 | **Custo realizado fica omitido, sem "—"** | §10.5 — "NÃO inventar" |
| P9 | **Números da campanha ≠ números do lote** | §8.5 — IAF-6990; o lote mostrava os mesmos números sob 7 títulos |
| P10 | **"Títulos avaliados" e "Duração" só no nível do lote** | §8.5 — não é recuperável por campanha |
| P11 | **A nota de retenção de 48 h aparece na tabela vazia** | §8.8 — vazio mudo era lido como "não avaliou ninguém" |
| P12 | **O selo "Travado" e o limiar de 15 min** | §8.2 — 2h40 de apagão invisível em 26/08/2026 |
| P13 | **A trilha da prévia não marca "Criar" como feito** | §8.2 — é a única coisa que a prévia não fez |
| P14 | **`Processando` é opt-in separado no cancelamento** | §13.6 — cancelar mensagem entregue faz a tela mentir |
| P15 | **A contagem do cancelamento vem de `search_actions`** | §13.6 — segunda definição divergiria |
| P16 | **Toast distinto para "nada pendente"** | §13.6 — sucesso vazio enganava |
| P17 | **O funil "Elegível" reconcilia 1:1 com a tela de Ações** | §7.1 — é o contrato que resolveu a confusão estimativa × real |
| P18 | **Rótulo de exibição ≠ valor canônico de status** | §7.1 — Regra 11 da Torre |
| P19 | **"Após travas do matching", não "Após Dedup Int."** | §8.7 — 3.040 de 3.192 eram maior atraso, não dedup |
| P20 | **A prévia não filtra por `is_active`** ao resolver filtros | §5.6.1 — IAF-6986; a prévia reproduz a audiência real |

---

## 18. Inventário de modais e componentes do domínio

### 18.1 Modais e painéis — com callsite

| Componente | Tipo | Aberto por | Arquivo do callsite |
|---|---|---|---|
| `CampaignDialog` | `Dialog` | Botão "Nova"; clique na linha/card; item "Editar" | `CampaignsPage.tsx` |
| `CampaignDetailDialog` | `Dialog` | Item "Visualizar"; clique em campanha concluída | `CampaignsPage.tsx` |
| `CampaignPreviewModal` | `Dialog` | Botão "Ver ações previstas" (2 variantes de rodapé) | `CampaignsPage.tsx` |
| `CampaignDryRunDialog` | `Dialog` | Item "Ensaiar (não cria ações)" | `CampaignsPage.tsx` |
| `CampaignDryRunDialog` | `Dialog` | Botão "Ensaiar" do cabeçalho | `CampaignDetailDialog.tsx` |
| `ExecuteOutsideWindowDialog` | `AlertDialog` | "Executar Agora" fora da janela | `CampaignsPage.tsx` |
| `ExecuteOutsideWindowDialog` | `AlertDialog` | "Forçar Execução" fora da janela | `CampaignDetailDialog.tsx` |
| `CampaignLogDetailDialog` | `Dialog` | Clique numa linha do Histórico de Execuções | `ExecutionMonitoringPanel.tsx` |
| `CancelCampaignActionsDialog` | `AlertDialog` | Botão `Ban` na tabela de Histórico | `ExecutionMonitoringPanel.tsx` |
| `BroadcastAddStepDialog` | `Dialog` | "Adicionar Primeira Ação" / "Adicionar Canal" | `BroadcastEditorPage.tsx` |
| `StepConfigSheet` | `Sheet` | "Configurar" num `StepCard` | `BroadcastEditorPage.tsx` (componente da tela de Réguas) |
| `window.confirm` nativo | browser | Item "Excluir" | `CampaignsPage.tsx` |

**Total: 11 componentes modais + 1 confirmação nativa**, em 10 pontos de abertura distintos.

### 18.2 Sub-painéis expansíveis (não são modais, mas escondem conteúdo)

| Componente / região | Tipo | Onde | Fechado por padrão? |
|---|---|---|---|
| Acordeão "Ver motivos (por título)" | `Accordion` | `CampaignPreviewModal` | sim, **exceto** quando `openReasonsByDefault` |
| "Ver todos os status ({n})" | `Collapsible` | `CampaignActivityMatrix` | sim |
| "Ver números do lote" | `Collapsible` | `CampaignLogDetailDialog` → `BatchContextCard` | sim |
| "Ver candidatos detalhados" | estado local | `CampaignLogDetailDialog` | sim |
| Detalhe do run (chevron) | estado local | `PipelineRunStatusCard` | sim |

### 18.3 Componentes do domínio sem callsite ativo

| Componente | Situação | Recomendação |
|---|---|---|
| `src/components/campaigns/execution/CampaignExecutionRunsList.tsx` | **Nenhuma tela o renderiza.** Contém a única navegação master-detail de runs (lista → funil do lote → candidatos do lote) e o catálogo de rótulos longos de passo (`StatusBadge`) | Decidir no redesign: reaproveitar como "visão por lote" do Monitoramento, ou remover. Os rótulos longos de passo são úteis e deveriam migrar para a fonte única de status de passo |
| `useCampaignExecutionBreakdown` (em `useCampaignExecutionCandidates.ts`) | Hook exportado, **sem consumidor**. Apesar do nome, apenas lê a linha do run | Remover ou implementar o agrupamento que o nome promete |
| Campos `state`, `heroLabel`, `funnel`, `showEstimate` de `useCampaignPreviewState` | Marcados `@deprecated`, com um shim `resolveLegacyState` inteiro. O modal atual **não os usa** | Remover junto com o shim |
| Contador `"{n} de {max} réguas selecionadas"` do `WorkflowMultiSelect` | Só renderiza com `maxSelections`, que o `CampaignDialog` **não passa** | Remover ou usar |
| `onDuplicate={() => {}}` no `BroadcastTimelineView` | Handler vazio passado ao `StepCard` | Verificar se o botão aparece inerte (⚠️ a confirmar) |
| Campos de `Campaign` sem superfície visual | `start_date`, `end_date`, `total_contacts`, `contacted_count`, `success_count` (§2.1) | Decidir se entram no redesign ou saem do tipo |
| Campos de formulário sem controle | `broadcast_filter_id`, `broadcast_filter_ids`, `broadcast_filter_logic` (§5.3) | Expor um seletor de filtros ou remover a leitura do card |
| Empty-state interno do `CampaignFunnelReal` | Nunca alcançado (o modal gateia antes) | Remover |
| Status `deferred` / `failed_retrying` | Existem no catálogo do `CampaignDetailDialog`, **não** no do Monitoramento nem no filtro | Unificar (B2) |
| Status `superseded` | Existe no Monitoramento, **não** no `CampaignDetailDialog` | Idem |
| Disposição `fetched` | Gravada pelo `fetch_titles`, **sem rótulo nem cor** | Rotular ou confirmar que é estado interno (§9.4) |

### 18.4 Contagem final do domínio

| Categoria | Quantidade |
|---|---|
| Rotas | 2 (`/campaigns`, `/broadcasts/:id/editor`) |
| Abas em `/campaigns` | 3 |
| Componentes em `src/components/campaigns/` | 17 |
| Componentes em `src/components/campaigns/execution/` | 4 |
| Componentes em `src/components/campaigns/preview/` | 3 |
| Modais / painéis (com callsite) | 11 + 1 confirmação nativa |
| Sub-painéis expansíveis | 5 |
| Hooks dedicados | 9 arquivos |
| Módulos de lógica pura | 3 (`campaign-log-funnel.ts`, `cost-calculator.ts`, `cron-translator.ts`) |
| Catálogos de constantes | 5 (`campaign-preview-help.ts`, `days-of-week.ts`, `status.ts`, `DISPOSITION_LABELS/COLORS`, `PRODUCER_TRIGGER_TYPES`/`TRIGGER_TYPES`) |
| Disposições catalogadas | 16 (+1 sem rótulo) |
| Status de log catalogados | 8 valores, em 2 catálogos divergentes |
| Passos do pipeline | 6 (+3 estados: `plan`, `completed`, `failed`) |

---

> **Fim do documento.** Toda afirmação aqui foi extraída por leitura direta do código em `cobranca-finza/`. Pontos marcados `⚠️ A confirmar:` exigem validação com o time técnico antes de virarem requisito de design.
