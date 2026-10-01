# 11 · Tela Dashboard

> Documento de UX/produto do frontend **atual** da tela Dashboard da Torre de Controle (`cobranca-finza`).
> Objetivo: permitir um redesenho completo da interface **sem perder nenhuma funcionalidade**.
> Tudo aqui foi extraído da leitura do código-fonte. Onde o código não é conclusivo, há marcação `⚠️ A confirmar:`.
> Data da leitura: 2026-09-17.

---

## 0. Identidade (rota, arquivo, permissão, layout)

| Item | Valor |
|---|---|
| Rota | `/` (raiz da aplicação autenticada) — `src/App.tsx` (`<Route path="/" element={<DashboardPage />} />`) |
| Carregamento | `lazy()` + `<Suspense fallback={<PageLoader />}>` — a tela é code-split |
| Componente raiz | `DashboardPage` — `src/pages/DashboardPage.tsx` |
| Wrapper de layout | `AppLayout` (sidebar + topo da aplicação) + `ErrorBoundary` + `TooltipProvider` globais (`src/App.tsx`) |
| Guard de rota | **Nenhum `RequirePermission`** na rota. Basta estar autenticado e com organização selecionada |
| Guard interno | 4 das 5 abas exigem `currentRole === "owner"` (`useOrganization()`), renderizadas com cadeado (`Lock`) |
| Barreira de dados | `currentOrg` obrigatório; sem org → `EmptyState` (ver §13) |
| Elemento semântico raiz | `<article className="relative flex flex-col h-full" aria-label="Dashboard de Business Intelligence">` |
| Fonte de estado | **URL query string** (`useSearchParams`) — aba ativa + todos os filtros globais + namespace `ai_*` |
| Cache/dados | TanStack Query v5; prefixos `["dashboard", …]`, `["dashboard-costs"]`, `["attribution-kpis"]`, `aiPerformanceKeys.*` |
| Multi-tenant | Todas as leituras passam por `orgClient` (schema `org_{slug}`) ou por RPC com `p_schema_name` |

**Arquivos-fonte do domínio desta tela**

```
src/pages/DashboardPage.tsx
src/components/dashboard/
  index.ts
  DashboardFiltersBar.tsx
  KPICard.tsx
  ExportButton.tsx              ← implementado, NÃO renderizado (ver §10)
  dashboard-filter-prune.ts
  tabs/ExecutiveTab.tsx | OperationalTab.tsx | AITab.tsx | AttributionTab.tsx | WorkflowsTab.tsx
  charts/CollectionFunnel.tsx | collection-funnel-copy.ts | ActionsTimelineChart.tsx
        | StepEvolutionChart.tsx | StepConversionTable.tsx | StepDynamicTable.tsx
        | ActionFrequencyTable.tsx | ActionFrequencyTrend.tsx | AgingChart.tsx
        | FunnelChart.tsx | HeatmapChart.tsx | PaymentHealthChart.tsx | ErrorSummaryCard.tsx
src/components/common/HelpTip.tsx | MetricExplanationPopover.tsx | RefreshButton.tsx
        | RefreshTopBar.tsx | RefreshableSection.tsx
src/components/portfolio/filters/FilterMultiSelect.tsx | PortfolioMultiSelect.tsx
        | FilterDefinitionMultiSelect.tsx | ActiveFilterChips.tsx | FilterLogicToggle.tsx
src/components/ui/mobile-collapsible-filters.tsx
src/hooks/useDashboardFilters.ts | useDashboardScope.ts | useDashboardSelectionLabels.ts
        | usePaymentAttribution.ts | usePaymentHealth.ts | useDashboard.ts
        | useDashboardKPIsOptimized.ts | useDashboardCosts.ts | useAIDashboardFilters.ts
src/lib/ai-dashboard-url.ts | dashboard-export.ts | filters/help-copy.ts
src/pages/central-docs/negocio/data/dashboard.ts   (guia de negócio embutido no app)
```

---

## 1. Objetivo e personas

### 1.1 O que a tela responde

Do guia de negócio do próprio app (`src/pages/central-docs/negocio/data/dashboard.ts`):

> "O painel de inteligência da operação de cobrança. É a primeira tela ao entrar na Torre e reúne, num só lugar, a saúde da carteira, o resultado das cobranças e quanto a Torre está recuperando — do total devido até o pagamento atribuído a uma ação."
>
> "O Dashboard responde, num relance, três perguntas: quanto a carteira deve, quanto já recuperamos e o que a operação está fazendo para cobrar. Ele não cobra ninguém — apenas mede e mostra."

Analogia canônica do guia: *"o painel do carro da cobrança"* — os números grandes no topo são os mostradores; os gráficos e tabelas abaixo explicam o porquê de cada número.

### 1.2 Personas e o que cada uma enxerga

| Persona / role | Abas visíveis | Pergunta típica |
|---|---|---|
| `viewer`, `operator`, `manager`, `admin` | Apenas **Visão Executiva** | "Quanto a carteira deve? Quanto já entrou? O funil está convertendo?" |
| `owner` | **Todas as 5** | Acrescenta: "Quanto dos pagamentos é mérito da Torre? Quanto custa? Qual régua/campanha performa melhor? A IA está entregando?" |

Roles do sistema (RBAC frontend, `OrganizationContext.tsx`): `owner > admin > manager > operator > viewer`. `owner = ["*"]`.

### 1.3 Princípios de produto embutidos no código (valem para o redesign)

Esses princípios estão escritos como comentários longos e travas explícitas no código; são **decisões de produto**, não detalhes de implementação:

1. **Erro nunca vira zero nem vazio.** Todo painel distingue `isLoading` / `isError` / `vazio`. Falha exibe mensagem + botão "Tentar novamente"; nunca "R$ 0,00" nem "Sem dados". (`spec-08`, presente em 8 componentes)
2. **Todo número enganoso carrega explicação.** Porcentagens que podem passar de 100% têm `"?"` obrigatório explicando o eixo de data.
3. **Etapa ≠ desfecho.** O funil separa população encaixada (série) de saídas paralelas (lado a lado), porque empilhá-las produzia a "pílula de 266,7%".
4. **Cobertura ≠ repartição.** Painéis por canal declaram que a soma passa de 100%.
5. **Consulta lenta não pode travar a tela.** O overlay de refetch é decorativo (`pointer-events-none`).
6. **Poda de filtro só remove o comprovadamente inválido.** Lista ainda carregando = "não sei", nunca "inválido".

---

## 2. Anatomia visual da tela (hierarquia completa, ordem dos blocos)

Fonte: `src/pages/DashboardPage.tsx`.

```
<article  relative flex flex-col h-full  aria-label="Dashboard de Business Intelligence">
│
├─ 1. RefreshTopBar                      (absolute, inset-x-0 top-0, z-20, h-0.5)
│     └─ visível somente quando isRefreshing === true (clique no botão Atualizar)
│
├─ 2. <header>  px-4 sm:px-6 py-4 border-b bg-background  flex items-center justify-between gap-3
│     ├─ bloco esquerdo (min-w-0)
│     │   ├─ <h1> "Dashboard"                    text-xl sm:text-2xl font-bold
│     │   └─ <p>  "Business Intelligence - {currentOrg.name}"
│     │            text-muted-foreground text-sm  ·  hidden sm:block  (some no mobile)
│     └─ bloco direito (shrink-0)
│         └─ RefreshButton (ícone-only, variant outline, aria-label "Atualizar")
│
├─ 3. <nav aria-label="Filtros do dashboard">     ← SÓ quando activeTab !== "ai"
│     └─ <DashboardFiltersBar />                  (ver §3; sticky top-0 z-10 bg-card border-b)
│
└─ 4. <div className="relative flex-1 min-h-0">
      ├─ overlay de refetch (condicional — ver §4 e §13)
      │    data-testid="dashboard-refetch-overlay"
      │    pointer-events-none absolute inset-0 z-20 bg-background/60 backdrop-blur-[1px]
      │    + <Loader2 animate-spin /> centralizado ·  aria-hidden="true"
      │
      └─ <section h-full overflow-auto transition-opacity  aria-label="Conteudo do dashboard"
                  aria-busy={isRefetchingContent}  [opacity-60 quando refetching]>
           └─ <Tabs value={activeTab} onValueChange={handleTabChange}>
                ├─ faixa de abas  px-4 sm:px-6 pt-4 border-b bg-background overflow-x-auto
                │   └─ <TabsList aria-label="Abas do dashboard">
                │        ├─ "Visao Executiva"                      (sempre)
                │        ├─ "Atribuicao"            + <Lock 3x3>   (owner)
                │        ├─ "Eficiencia Operacional"+ <Lock 3x3>   (owner)
                │        ├─ "Performance de Cobranças" + <Lock>    (owner)
                │        └─ "Performance da IA"      + <Lock 3x3>  (owner)
                │
                └─ <div className="p-4 sm:p-6">
                     ├─ <GlobalFilteredTabs />   ← só quando tab !== "ai"
                     │     ├─ TabsContent "executive"   → <ExecutiveTab filters={resolvedFilters} />
                     │     ├─ TabsContent "attribution" → <AttributionTab … />   (owner)
                     │     ├─ Alert "Filtro sem efeito de escopo"      (condicional)
                     │     ├─ Alert "Escopo parcialmente resolvido"    (condicional)
                     │     ├─ Alert "Não foi possível resolver o escopo" (condicional, destructive)
                     │     ├─ TabsContent "operational" → <OperationalTab … />   (owner)
                     │     └─ TabsContent "workflows"   → <WorkflowsTab … />     (owner)
                     └─ TabsContent "ai" → <AITab />    ← só quando tab === "ai" E owner
```

### 2.1 Observações de hierarquia relevantes ao redesign

- **A ordem visual dos rótulos das abas não bate com a ordem de declaração do conteúdo.** Os gatilhos são `executive → attribution → operational → workflows → ai`; o conteúdo em `GlobalFilteredTabs` é declarado `executive → attribution → [alertas] → operational → workflows`. Como só uma aba fica visível por vez, o efeito prático é apenas que **os três alertas de escopo aparecem depois do conteúdo de Atribuição e antes de Operacional no DOM** — ou seja, ficam visíveis em qualquer aba (são irmãos dos `TabsContent`, não filhos).
- **A barra de filtros é desmontada na aba IA** (`!isAITab`). O estado global continua na URL; ao voltar, a barra e os filtros reaparecem intactos.
- **Nada é buscado das abas globais enquanto `tab=ai`**: `GlobalFilteredTabs` (e portanto `useDashboardFilters`/`useDashboardScope`/`useWorkflows`/`useCampaigns`) não monta.
- A tela **não tem rodapé próprio** nem breadcrumb. O único scroll interno é a `<section>` de conteúdo.
- A faixa de abas tem `overflow-x-auto` — no mobile as 5 abas rolam horizontalmente.

---

## 3. Barra de filtros global

Fonte: `src/components/dashboard/DashboardFiltersBar.tsx`, `src/hooks/useDashboardFilters.ts`.

### 3.1 Container e comportamento geral

| Aspecto | Comportamento |
|---|---|
| Wrapper externo | `<MobileCollapsibleFilters activeCount={n} label="Filtros do Dashboard">` |
| Desktop (≥768px) | Renderiza o conteúdo direto, sem colapso |
| Mobile (<768px) | Vira um `Collapsible`: botão ghost full-width, `h-10`, ícone `Filter`, texto "Filtros do Dashboard", `Badge` com o nº de filtros ativos, chevron ↑/↓. Inicia **fechado** no mobile |
| Wrapper interno | `sticky top-0 z-10 bg-card border-b` — a barra gruda no topo ao rolar |
| Layout interno | `flex flex-col gap-3 p-4` → linha 1 = controles (`flex flex-wrap items-center gap-4`); linha 2 = chips |
| Separadores | `<div className="h-6 w-px bg-border" />` entre grupos |
| Prop `periodOnly` | Quando `true`, esconde tudo exceto o período e a linha de chips. **Não é usada pelo Dashboard** (`<DashboardFiltersBar />` sem props) — existe para reuso |

**Contagem de filtros ativos** (`activeFilterCount`, usada no badge mobile):
`portfolioIds.length + campaignIds.length + workflowIds.length + filterIds.length + (period !== "all" ? 1 : 0)`.
⚠️ Note que `entityKind` **não** entra nessa contagem, embora entre em `hasActiveFilters` do hook.

**Erro de carregamento das opções**: se qualquer um dos 4 fetches de opções falhar, renderiza acima da barra:
`<p role="alert" className="p-3 text-sm text-destructive">Não foi possível carregar todas as opções de filtro. Atualize a página.</p>`

### 3.2 Tabela completa dos filtros

| # | Label / rótulo | Controle | Ícone | Opções | Default | Multi | Param na URL | Notas |
|---|---|---|---|---|---|---|---|---|
| 1 | *(sem label textual — ícone `CalendarDays`)* **Período** | `Select` (shadcn), trigger `w-[160px] h-9` | `CalendarDays` | `Todo período`, `Hoje`, `Últimos 7 dias`, `Últimos 30 dias`, `Este mês`, `Mês passado`, `Últimos 12 meses`, `Personalizado` | `all` = "Todo período" | Não | `period` | Sempre serializado. Trocar para ≠ `custom` apaga `start_date`/`end_date` |
| 2 | Intervalo de datas | **(a)** `Badge variant="outline"` read-only com `dd/MM - dd/MM`, quando `period ≠ custom`. **(b)** `Popover` com `Calendar mode="range" numberOfMonths={2}`, quando `period = custom` | `CalendarIcon` no botão trigger (`variant outline`, `min-w-[200px]`) | livre | vazio → texto "Selecione o período" | — | `start_date`, `end_date` (`yyyy-MM-dd`) | O calendário usa estado **temporário**: só commita ao clicar **Aplicar**. **Cancelar** fecha sem mudar. `Aplicar` fica `disabled` sem `from`. Sem `to`, `end = start` |
| 3 | **Eixo Contrato/Suprimento/Ambos** | Grupo de 3 `<button>` num "segmented control" (`bg-muted rounded-md p-0.5`) | — | `Contrato` / `Suprimento` / `Ambos` | `contract` | Não (radio) | `entity_kind` (só serializa `supply` \| `all`) | **Só aparece se `useHasSupply().hasSupply === true`** (org com fonte de suprimento configurada) |
| 4 | **Carteiras** | `PortfolioMultiSelect` → `FilterMultiSelect` (Button outline `role="combobox"` + `Badge · N` + Popover com `Command`) | `Briefcase` | Todas as carteiras ativas (`usePortfolios({fetchAll:true, activeOnly:true, pageSize:100})`) | `[]` | **Sim** | `portfolios` (CSV de uuids) | Título do trigger: "Carteiras (qualquer uma)". Toggle **E/OU** no cabeçalho do dropdown ("Combinar carteiras"), só com 2+ selecionadas. Default lógica **OU** |
| 5 | **Réguas** | `FilterMultiSelect` | `GitBranch` | Réguas ativas **filtradas em cascata pelas carteiras** (`useWorkflows({fetchAll:true, isActive:true, pageSize:100})`) | `[]` | **Sim** | `workflows` (CSV) | Sem toggle E/OU. Mostra ícone `Link2` azul + tooltip "Filtrado por carteira selecionada" quando há carteira selecionada |
| 6 | **Campanhas** | `FilterMultiSelect` | `Megaphone` | Campanhas **ativas** filtradas em cascata por réguas/carteiras (`useCampaigns({fetchAll:true, status:"active", pageSize:100})`) | `[]` | **Sim** | `campaigns` (CSV) | Idem indicador de cascata. **Só lista campanhas `status=active`** |
| 7 | **Filtros** (filtros salvos) | `FilterDefinitionMultiSelect` → `FilterMultiSelect` | `Filter` | Todas as `filter_definitions` (`useFilters({fetchAll:true, pageSize:100})`) | `[]` | **Sim** | `filters` (CSV) | Título do trigger: "Filtros salvos (todos se aplicam)". Toggle **E/OU** no cabeçalho ("Combinar filtros"). Default lógica **E** |
| — | Operador das carteiras | `FilterLogicToggle` dentro do dropdown #4 | — | `E` / `OU` | `or` | — | `portfolios_logic` (só serializa `and`) | |
| — | Operador dos filtros salvos | `FilterLogicToggle` dentro do dropdown #7 | — | `E` / `OU` | `and` | — | `filters_logic` (só serializa `or`) | |

**Anatomia interna de todo `FilterMultiSelect`** (`src/components/portfolio/filters/FilterMultiSelect.tsx`):

- Trigger: `Button variant="outline" role="combobox" h-9 w-[180px]` (default), ícone + label + `Badge secondary "· N"` quando há seleção. Label fica `text-muted-foreground` quando nada selecionado.
- Popover: largura amarrada ao trigger (`w-[var(--radix-popover-trigger-width)] min-w-[240px]`), altura limitada (`max-h-[var(--radix-popover-content-available-height)]`), scroll vertical.
- Cabeçalho opcional: linha "Combinar carteiras / Combinar filtros:" + toggle `E`/`OU` — **só com ≥2 seleções**.
- `Command` com `CommandInput placeholder="Buscar..."`, `CommandEmpty "Nenhum resultado encontrado."`.
- Primeiro item sempre: **"Selecionar todos"** / **"Limpar seleção"** (checkbox tri-state: cheio, meio-preenchido, vazio).
- Itens: checkbox + bolinha de cor (se `color`) + ícone dinâmico (se `icon`) + label com `break-words`.

### 3.3 Dependências e cascata entre filtros

| Regra | Comportamento |
|---|---|
| Carteira → Réguas | `filteredWorkflows`: mostra régua **sem restrição de carteira** OU com pelo menos uma das carteiras selecionadas em `assignment_filters.portfolios` |
| Carteira/Régua → Campanhas | `filteredCampaigns`: com carteiras mas sem réguas, filtra por `target_reguas ∩ réguas disponíveis`; com réguas selecionadas, filtra por `target_reguas ∩ réguas selecionadas`; campanha sem `target_reguas` sempre passa |
| Indicador de cascata | `Link2` (h-3.5) em `text-primary` + `Tooltip` "Filtrado por carteira selecionada", ao lado de Réguas e Campanhas, quando `portfolioIds.length > 0` |
| Poda ao trocar carteira | `handlePortfolioChange` recalcula réguas válidas, poda `workflowIds` e `campaignIds`, e grava **as três chaves em UMA escrita de URL** (1 entrada de histórico) |
| Poda ao trocar régua | `handleWorkflowChange` poda `campaignIds` contra as réguas selecionadas. **Limpar réguas (`[]`) nunca poda campanha** |
| Regra de segurança da poda | `dashboard-filter-prune.ts`: só poda o que dá para **provar** inválido. Lista `undefined` (ainda carregando) → não poda nada. Id ausente de lista capada/filtrada → preserva |

### 3.4 Linha de chips ativos

Componente: `ActiveFilterChips` (`src/components/portfolio/filters/ActiveFilterChips.tsx`). Renderiza `null` se não houver chips.

```
Filtros ativos:  [🗓 Período: Últimos 30 dias ✕]  [● Carteira: Inadimplentes ✕]  OU  [● Carteira: VIP ✕]
                 [⑂ Régua: Régua padrão ✕]  [📣 Campanha: Campanha X ✕]  [● Filtro: Alto risco ✕]
                 (Limpar todos)
```

| Chip | Rótulo | Ícone / cor | Conector E/OU | Ação do ✕ |
|---|---|---|---|---|
| Período | `Período: {label}` — com `custom`, `dd/MM - dd/MM` | `CalendarDays` 3x3 | — | `setFilter("period","all")` |
| Carteira | `Carteira: {nome}` | bolinha com a cor da carteira | a partir do **2º** chip: `E` ou `OU` conforme `portfoliosLogic` | remove só aquele id (via `handlePortfolioChange`, com poda) |
| Régua | `Régua: {nome}` | `GitBranch` | — | remove aquele id (via `handleWorkflowChange`, com poda de campanha) |
| Campanha | `Campanha: {nome}` | `Megaphone` | — | remove aquele id |
| Filtro salvo | `Filtro: {nome}` | bolinha com a cor do filtro | a partir do 2º chip: `E`/`OU` conforme `filtersLogic` | remove aquele id |

- Chips renderizados como `Badge variant="secondary"`; o ✕ é um `<button aria-label="Remover filtro">` com hover `text-destructive`.
- Botão final: `Button variant="ghost" size="sm"` **"Limpar todos"** → `clearFilters()`, que **preserva `tab` e todos os params `ai_*`** e apaga o resto.
- **Resolução de nome** (`useDashboardSelectionLabels`): se o id selecionado não está na lista carregada (deep-link, campanha pausada, item além do 100º), o nome é buscado por id. Enquanto busca → `"carregando…"`. Se ainda assim falhar → `#{8 primeiros chars do uuid}`. **Nunca renderiza nome vazio.**
- O chip de período **não** aparece quando `period = "all"`. O eixo `entityKind` **não gera chip**.

### 3.5 Persistência de estado

**Toda a barra vive na URL** — não há `localStorage`.

| Param | Valores | Quando é omitido |
|---|---|---|
| `tab` | `executive` \| `attribution` \| `operational` \| `workflows` \| `ai` | ausente = `executive` |
| `period` | os 8 presets | sempre presente após a 1ª interação; ausente = `all` |
| `start_date`, `end_date` | `yyyy-MM-dd` | fora do modo `custom` |
| `portfolios`, `campaigns`, `workflows`, `filters` | CSV de uuids | lista vazia |
| `portfolios_logic` | `and` | quando é `or` (default) |
| `filters_logic` | `or` | quando é `and` (default) |
| `entity_kind` | `supply` \| `all` | quando é `contract` (default) |
| `ai_agent`, `ai_period`, `ai_from`, `ai_to`, `ai_granularity`, `ai_created_from/to`, `ai_last_interaction_from/to` | ver §7 | defaults |

Comportamentos de navegação:

- **Trocar de aba** → `push` no histórico (`replace: false`). Back/forward navegam entre abas e **preservam os demais params**.
- **Trocar um filtro global** → escrita via `setFilters`/`setFilter` (push). Escritas múltiplas no mesmo tick são acumuladas num `pendingRef` para não se perderem.
- **Trocar um filtro da aba IA** → `replace: true` (não polui o histórico).
- Parâmetro inválido nunca quebra: cai no default (`parseDashboardTab`, `parseAIDashboardParams`).
- Aba owner-only pedida por não-owner → cai em `executive` silenciosamente.

### 3.6 Cálculo do intervalo de datas (`dateRange` / `sqlDateRange`)

`useDashboardFilters` deriva um intervalo concreto a partir do preset:

| Preset | start | end |
|---|---|---|
| `all` | data de vencimento mais antiga da base (`titles.due_date`, cache 1h) **ou** `2024-01-01` se não houver | fim de hoje |
| `today` | início de hoje | fim de hoje |
| `7d` | início de (hoje − 6 dias) | fim de hoje |
| `30d` | início de (hoje − 29 dias) | fim de hoje |
| `this_month` | 1º do mês atual | fim do mês atual |
| `last_month` | 1º do mês anterior | fim do mês anterior |
| `12m` | 1º do mês de 11 meses atrás | fim do mês atual |
| `custom` | `start_date` (parse local com `T00:00:00`) | `end_date`, com fallback para início/fim do mês |

`sqlDateRange` = o mesmo formatado `yyyy-MM-dd`. É esse par que o `Badge` read-only exibe como `dd/MM - dd/MM`.

### 3.7 Resolução de escopo (régua/campanha → carteiras) e seus três avisos

`useDashboardScope` (`src/hooks/useDashboardScope.ts`) traduz as réguas/campanhas selecionadas em **ids de carteira**, buscando por id (sem paginação, sem filtro de status, em chunks de 150 para não estourar o limite de URL do PostgREST).

`GlobalFilteredTabs` combina: `effectivePortfolioIds = portfolioIds ∪ scope.portfolioIds`. **Filtros salvos (`filterIds`) NÃO são resolvidos em carteiras** — vão direto para a RPC.

Três alertas (componentes `Alert` do shadcn, renderizados dentro do `<div className="pb-4">`):

| Condição | Variante | Título | Corpo |
|---|---|---|---|
| `scopeUnresolved` — há régua/campanha selecionada e **nada** resolveu | `border-amber-500/50`, ícone `AlertTriangle` âmbar | "Filtro sem efeito de escopo" + `HelpTip topic="dash_escopo_vazio"` | "A régua/campanha selecionada não restringe por carteira — o dashboard está exibindo toda a base. Selecione uma carteira ou um filtro salvo para restringir o escopo." |
| `scopePartial` — parte resolveu e parte não (e não é o caso acima) | âmbar | "Escopo parcialmente resolvido" + `HelpTip dash_escopo_vazio` | "{n} de {m} seleções de régua/campanha não apontam para nenhuma carteira e ficaram de fora do recorte — os números refletem apenas as demais." |
| `scopeError` — a query de escopo falhou | `variant="destructive"` | "Não foi possível resolver o escopo" | "Falha ao carregar as carteiras da régua/campanha selecionada. Os números abaixo podem estar considerando toda a base." |

### 3.8 Ajudas contextuais na barra (`HelpTip`)

| Posição | `topic` | Título | Conteúdo |
|---|---|---|---|
| Ao lado do ícone de calendário | `dash_periodo` | "Período" | "A data é só um recorte de tempo: limita o intervalo analisado. Ela NÃO entra na lógica E/OU dos filtros — é sempre somada por 'E'. 'Todo período' = sem limite de tempo." |
| Ao lado de Carteiras | `carteira_multi` | "Carteiras" | "Carteiras são segmentos dinâmicos de títulos. Escolha uma ou várias. Com 2+, o botão E/OU define: 'OU' = quem está em QUALQUER uma (mais amplo, padrão); 'E' = quem está em TODAS ao mesmo tempo (mais restrito). Nenhuma carteira escolhida = considera todas." |
| Ao lado de Carteiras, **só com ≥2 carteiras** | `dash_vs_carteira` | "Dashboard × Carteira" | "No Dashboard, o pertencimento às carteiras usa um índice pré-calculado (atualizado periodicamente). Em telas que recalculam ao vivo, os números podem diferir levemente logo após mudanças — especialmente no modo 'E'." |
| Ao lado de Réguas (cobre também Campanhas) | `dash_regua_campanha` | "Régua e campanha" | "Filtrar por régua/campanha traz os contatos das carteiras associadas a elas (união). É um atalho para 'ver o público daquela régua/campanha'." |
| Ao lado de Filtros salvos | `filtro_salvo_multi` | "Filtros salvos" | "Aplica filtros salvos por cima. Com 2+, o E/OU define: 'E' = precisa atender todos (padrão, mais restrito); 'OU' = basta atender um. Nenhum filtro escolhido = não restringe." |

---

## 4. Padrão de atualização (RefreshTopBar / RefreshButton / RefreshableSection)

Esse trio implementa o que o código chama de **"hybrid loading pattern"**: *skeleton só na primeira carga; em refresh com dado já na tela, o dado permanece visível, esmaecido, com barra de progresso*.

### 4.1 Componentes

| Componente | Arquivo | O que é | Props | Onde aparece no Dashboard |
|---|---|---|---|---|
| `RefreshButton` | `src/components/common/RefreshButton.tsx` | Botão padrão de recarga. `Button variant="outline"`, `size="icon"` quando sem label. Ícone `RefreshCw` que gira (`animate-spin`) enquanto ocupado; fica `disabled`; `aria-busy` + `aria-label`/`title` = "Atualizar". Rastreia internamente a promise devolvida por `onRefresh` **ou** o flag externo `isFetching` | `onRefresh`, `isFetching`, `label?`, `size?`, `variant?`, `title?`, `disabled?` | **Cabeçalho da tela**, ícone-only |
| `RefreshTopBar` | `src/components/common/RefreshTopBar.tsx` | Barra fina indeterminada no topo do container. `role="progressbar" aria-busy="true" aria-label="Atualizando"`. `h-0.5`, trilho `bg-primary/15`, cursor `w-1/3 bg-primary` com `animate-refresh-bar`. Retorna `null` quando inativa | `active`, `className?` | **Topo do `<article>`**, ativa só no refresh manual |
| `RefreshableSection` | `src/components/common/RefreshableSection.tsx` | Wrapper que, durante refresh, deixa o conteúdo `opacity-60 pointer-events-none` e marca `aria-busy` | `isRefreshing`, `children` | **⚠️ Não é usado nesta tela** — o `DashboardPage` reimplementa o mesmo efeito inline na `<section>` |

### 4.2 Os dois estados de "atualizando" (são diferentes)

**(A) Refresh manual — `isRefreshing`**

Disparado pelo `RefreshButton`. `handleRefresh` invalida **todos** os prefixos de query consumidos por **todas** as abas, em paralelo:

```
["dashboard"]                               (KPIs, aging, funil, timeline, steps, payment-health, scope…)
["dashboard-costs"]                         (custo por canal da aba Operacional)
["attribution-kpis"]                        (aba Atribuição)
…aiPerformanceKeys.legacyRoots()            (todos os prefixos v1 da Performance da IA)
aiPerformanceKeys.all                       (snapshot canônico v2)
```

Efeito visual: `RefreshTopBar` ativa + ícone girando + botão desabilitado. **O overlay NÃO aparece** (`isRefetchingContent = dashboardRefetching > 0 && !isRefreshing`).

**(B) Refetch automático de conteúdo — `isRefetchingContent`**

Contado por `useIsFetching` com predicado: query cujo root está em `DASHBOARD_QUERY_ROOTS` **e** que já tem `data` (isto é, refetch sobre conteúdo já renderizado, não primeira carga). Ocorre tipicamente ao **trocar um filtro**.

Efeito visual:
- Overlay `bg-background/60 backdrop-blur-[1px]` com `Loader2` girando no centro;
- conteúdo em `opacity-60` com `transition-opacity`;
- `aria-busy` na `<section>`;
- **o overlay é `pointer-events-none`** — o clique passa para o conteúdo, e trocar de aba continua funcionando durante uma consulta lenta.

### 4.3 Por que esse padrão existe (contexto que o redesign precisa preservar)

O comentário de ~40 linhas em `DashboardPage.tsx` documenta:

- Um gate anterior (`hasSettledOnce`) fazia o overlay aparecer em **toda carga fria**, e uma RPC lenta (`get_funnel_data` estourando `statement_timeout` de 30s, ~71s com retry) deixava "a tela inteira girando e travada".
- A correção: contar só queries **com `data` definido** (equivale a `isFetching && !isLoading` por query), sem latch e sem efeito.
- O bloqueio de interação foi movido para fora: overlay decorativo. **Lentidão de backend não pode virar "tela travada".**

### 4.4 Serialização deliberada das 4 RPCs pesadas da Visão Executiva

`ExecutiveTab.tsx` (Regra 32 do projeto): `get_funnel_data`, `get_step_conversion_data`, `get_actions_timeline` e `get_action_frequency_timeline` leem o mesmo heap de `{org}.actions` (2,2 GB em `org_blips`) com `shared_buffers` de 512 MB.

```ts
const heavyRpcsEnabled = !funnelFetching;   // o funil vai primeiro; os outros 3 esperam
```

- `!funnelFetching` cobre **sucesso e erro**: se o funil falhar, os secundários rodam mesmo assim.
- Consequência de UI: os três painéis secundários ficam em **skeleton enquanto esperam a vez na fila** (`stepLoadingUi`, `timelineLoadingUi`, `freqTrendLoadingUi` incluem `|| !heavyRpcsEnabled`), porque com `enabled: false` o React Query v5 devolve `isLoading=false` + `data=undefined` e a UI piscaria "sem dados".
- **Para o redesign:** painel novo que leia `actions` **entra na fila**. Não paralelizar.

---

## 5. Aba Visão Executiva

Arquivo: `src/components/dashboard/tabs/ExecutiveTab.tsx`. Container: `<div className="space-y-6">`.
Visível para **todos os perfis**. É a aba default.

### 5.0 Ordem dos blocos

1. Grid de **8 KPI Cards**
2. Grid 2 colunas: **Evolução Mensal** | **Tendência de Recuperação**
3. Grid 5 colunas (`lg:grid-cols-5 lg:items-start`): **Funil de Cobrança** (3 col) | sidebar (2 col) com **Aging**, **Saúde da Carteira**, **Status de Entrega**
4. Card full-width: **Freq. de Acionamento** (tabela + série temporal)
5. Card full-width: **Acionamentos ao Longo do Tempo**
6. Card full-width: **Eficiência por Step** (gráfico opcional + tabela dinâmica)

### 5.1 Bloco 1 — Faixa de KPIs

Grid: `grid gap-4 md:grid-cols-2 lg:grid-cols-4` (2 linhas de 4 no desktop).

**Componente `KPICard`** (`src/components/dashboard/KPICard.tsx`):

```
┌─ Card [variantStyles] ─────────────────────────────┐
│ CardHeader (flex row, justify-between, pb-2)       │
│   [Título text-sm font-medium] [?]        [Ícone]  │
│ CardContent                                        │
│   [Valor text-2xl font-bold]  [▲/▼ xx,x%]          │
│   [descrição text-xs text-muted-foreground]        │
└────────────────────────────────────────────────────┘
```

| Prop | Efeito |
|---|---|
| `variant` | `default` (sem borda colorida) · `success` (`border-success/30 bg-success/5`) · `warning` · `danger` (`border-destructive/30`) · `info` (`border-info/30`) — também colore o ícone |
| `previousValue` + `currentValue` | Calcula tendência: variação <0,5% → `stable` (ícone `Minus`, cinza); alta → `TrendingUp` verde (`text-success`); queda → `TrendingDown` (`text-destructive`). Exibe `xx.x%`. **⚠️ Nenhum KPI do Dashboard passa essas props hoje — a faixa de variação existe no componente mas não é alimentada** |
| `isLoading` | Renderiza o card com `Skeleton` (h-4 w-24 no título, h-4 w-4 no ícone, h-8 w-32 no valor, h-3 w-20 na descrição) |
| `explanation` | Abre `MetricExplanationPopover` estruturado (precedência sobre `tooltip`) |
| `tooltip` | Texto simples no mesmo popover |

`KPIGridSkeleton({count, className})` renderiza N cards em loading. Na Visão Executiva: `count={8}` com a mesma classe de grid.

#### Os 8 KPIs, um a um

| # | Título exato | Valor / formato | Descrição (linha inferior) | Ícone | Variante (cor semântica) | Fonte de dado |
|---|---|---|---|---|---|---|
| 1 | **Carteira Total** | Moeda BRL. Se `period = "all"` → `totalCurrentValue`; senão → `totalOpenValue + totalPaidValue` | `{totalTitles} títulos` (pt-BR) | `Wallet` | `default` | `useDashboardKPIsUnified` |
| 2 | **Carteira Original** | Moeda — `totalOriginalValue` | `{totalTitles} títulos` | `Banknote` | `default` | idem |
| 3 | **Em Aberto** | Moeda — `totalOpenValue` | `{pendingTitles} títulos` | `DollarSign` | `info` (azul) | idem |
| 4 | **Paga** | Moeda — `totalPaidValue` | `{paidTitles} títulos` | `DollarSign` | `success` (verde) | idem |
| 5 | **Vencida** | Moeda — `overdueValue` | `{overdueTitles} títulos` | `AlertTriangle` | `warning` (amarelo) | idem |
| 6 | **A Vencer** | Moeda — `aging.current.value` | `{aging.current.count} títulos` | `CalendarClock` | `info` | idem |
| 7 | **Taxa de Recuperação** | Percentual, 1 casa — `recoveryRate.toFixed(1)%` | texto fixo: `"Pago / Valor atual da carteira"` | `TrendingUp` | **condicional**: `> 10` → `success`; senão `info` | idem |
| 8 | **Media Atraso Efetivo** *(sem acento no código)* | `{avgEffectiveDelay.toFixed(1)} dias` | `{pagos+vencidos} titulos ({pagos} pagos + {vencidos} vencidos)` | `Clock` | **condicional**: `>30` → `danger`; `>15` → `warning`; senão `success` | `usePaymentHealth` (tem `isLoading` próprio) |

#### Conteúdo integral das explicações (`?`) dos KPIs

> Esses textos são o contrato de significado da tela. Devem sobreviver ao redesign.

**1 · Carteira Total — com `period = "all"`**
- *O que é*: "Tamanho total da carteira pelo valor ATUALIZADO de cada título (já com juros e multa)."
- *Como calcula*: `Σ valor atual de cada título (usa o valor original quando o atual está ausente)`
- *Exclui*: "Títulos removidos (removed_at preenchido)."
- *Observação*: "Como nenhum período está selecionado, mostra o valor atualizado de toda a carteira. Compare com o card 'Carteira Original' para ver o efeito de juros e multa."

**1 · Carteira Total — com período selecionado**
- *O que é*: "Tamanho da carteira no período pelo valor ATUALIZADO (já com juros e multa): o que está em aberto mais o que já foi pago."
- *Como calcula*: `Em Aberto + Paga (saldo em aberto + valor pago no período)`
- *Com período selecionado*: "Em Aberto considera títulos com vencimento no período; Paga considera pagamentos recebidos no período."
- *Observação*: "É o valor atualizado. Compare com o card 'Carteira Original' para ver o efeito de juros e multa."

**2 · Carteira Original**
- *O que é*: "Valor ORIGINAL (de face) dos títulos no escopo selecionado, sem juros nem multa."
- *Como calcula*: `Σ valor original de cada título`
- *Exclui*: "Títulos removidos (removed_at preenchido)."
- *Com período*: "Respeita o período, a carteira e os filtros salvos selecionados."
- *Observação*: "Compare com 'Carteira Total' (valor atualizado) para ver o efeito de juros e multa."

**3 · Em Aberto**
- *O que é*: "Saldo devedor total ainda em aberto. Em Aberto = Vencida + A Vencer."
- *Como calcula*: `Vencida + A Vencer = Σ saldo devedor por título, onde saldo = maior(valor atual, valor original) − valor pago`
- *Exclui*: "Títulos pagos, cancelados e removidos (saldo zero)."
- *Com período*: "Considera apenas títulos com vencimento dentro do período."
- *Observação*: "O detalhamento está nos cards 'Vencida' (já vencidos) e 'A Vencer' (ainda a vencer)."

**4 · Paga**
- *O que é*: "Valor efetivamente pago (recebido) dos títulos quitados."
- *Como calcula*: `Σ valor pago dos títulos = valor pago informado (ou valor original/atual quando ausente)`
- *Exclui*: "Títulos em aberto e removidos."
- *Com período*: "Soma os pagamentos recebidos dentro do período (data de pagamento no intervalo). Sem período, soma todos os pagos."

**5 · Vencida**
- *O que é*: "Saldo em aberto dos títulos já vencidos (vencimento anterior a hoje) e ainda não pagos."
- *Como calcula*: `Σ saldo devedor dos títulos vencidos = maior(valor atual, valor original) − valor pago`
- *Exclui*: "Títulos pagos, cancelados e removidos."
- *Com período*: "Considera apenas títulos com vencimento dentro do período."
- *Observação*: "Parte do card 'Em Aberto' (Em Aberto = Vencida + A Vencer)."

**6 · A Vencer**
- *O que é*: "Saldo devedor dos títulos que ainda não venceram e não foram pagos — vencem hoje ou no futuro (inclui as vincendas e as que vencem hoje)."
- *Como calcula*: `Σ saldo devedor dos títulos com days_overdue ≤ 0 e não pagos = maior(valor atual, original) − pago`
- *Exclui*: "Títulos pagos, cancelados, removidos e VENCIDOS (estes estão em 'Vencida')."
- *Com período*: "Considera títulos com vencimento no período."
- *Observação*: "Mesma base do bucket 'Em dia' do gráfico de Aging. Parte do card 'Em Aberto'."

**7 · Taxa de Recuperação**
- *O que é*: "Percentual da carteira já recuperado."
- *Como calcula*: `valor pago dos títulos ÷ valor atual total da carteira × 100`
- *Com período*: "Considera títulos com vencimento no período."
- *Observação*: "O denominador é o valor atual total dos títulos no escopo (total_current_value), não a soma Pago + Em Aberto — por isso pode divergir de uma conta manual com esses dois cards."

**8 · Media Atraso Efetivo**
- *O que é*: "Atraso médio efetivo dos títulos, em dias."
- *Como calcula*: `Média do atraso efetivo: pagos usam o atraso no pagamento (data de pagamento − vencimento); em aberto usam os dias de atraso atuais`
- *Exclui*: "Títulos a vencer (ainda não vencidos)."
- *Com período*: "Considera títulos com vencimento no período."

#### Estado de erro da faixa de KPIs

Quando `kpisError`, a faixa inteira é substituída por (não por cards zerados):

```
┌ rounded-lg border p-6 text-center ────────────────┐
│           [AlertCircle h-8 destructive]            │
│  Não foi possível carregar os indicadores.         │  (text-destructive font-medium)
│  {mensagem do erro}                                │  (text-sm muted)
│        [ Tentar novamente ]  outline sm            │
└────────────────────────────────────────────────────┘
```

### 5.2 Bloco 2 — Evolução Mensal (gráfico de barras)

| Item | Valor |
|---|---|
| Card title | `Evolução Mensal` + ícone `BarChart3` h-5 |
| Card description | `Dívida vs Recuperação ({n} meses)` |
| Tipo | `BarChart` (recharts), altura 250, `ResponsiveContainer` 100% |
| Eixo X | `dataKey="month"`, `fontSize 12` |
| Eixo Y | valores; formatador: `≥1000 → "{n/1000}k"` |
| Séries | **Dívida** (`dataKey="debt"`, `fill="hsl(var(--destructive))"`, `radius 4`) · **Recuperado** (`dataKey="recovered"`, `fill="hsl(var(--primary))"`, `radius 4`) |
| Grid | `CartesianGrid strokeDasharray="3 3" className="stroke-muted"` |
| Legenda | `<Legend />` padrão do recharts |
| Tooltip | valores formatados em BRL; `contentStyle` com `hsl(var(--card))`, borda `hsl(var(--border))`, `borderRadius 8px` |
| Loading | `ChartSkeleton height={250}` |
| Vazio | ícone `BarChart3` h-12 opacity-50 + **"Sem dados para exibir"**, altura 250 (condição: nenhum mês com `debt>0 || recovered>0`) |
| Erro | ⚠️ **Não há estado de erro dedicado** — falha cai no estado vazio |
| Responde ao gestor | "mês a mês, quanto havia para cobrar e quanto foi recuperado" |

### 5.3 Bloco 2b — Tendência de Recuperação (gráfico de linhas)

| Item | Valor |
|---|---|
| Card title | `Tendência de Recuperação` + ícone `TrendingUp` |
| Card description | `Meta vs Realizado ao longo do mês` |
| Tipo | `LineChart`, altura 250 |
| Séries | **Recuperado** (`dataKey="recovered"`, `stroke hsl(var(--primary))`, `strokeWidth 2`, com `dot`) · **Meta** (`dataKey="target"`, `stroke hsl(var(--muted-foreground))`, `strokeDasharray="5 5"`, `dot={false}`) |
| Vazio | ícone `TrendingUp` + "Sem dados para exibir" (condição: nenhum mês com `recovered > 0`) |
| Erro | ⚠️ Sem estado dedicado |
| Fonte | mesmo `useMonthlyData(filters)` do bloco anterior |

### 5.4 Bloco 3 — Funil de Cobrança (`CollectionFunnel`)

Card: title `Funil de Cobrança` + ícone `Filter`; description `Da base elegível até a conversão em pagamento`. Ocupa `lg:col-span-3` de 5.

#### 5.4.1 Estrutura do componente

```
[ Contar por [?] ]                              [ Contratos | Títulos | Contatos ]  ← MetricToggle
────────────────────────────────────────────────────────────────────────────────
ETAPAS                                                          (SectionEyebrow)
  ┌ LevelCard 01 · Base Elegível ───────────────────────┐
  │ 01 · Base Elegível [?]                 [N contratos]│
  │ em carteira de campanha ativa, vencendo no período  │  ← legend
  │ POR DATA DE VENCIMENTO                              │  ← dateAxis (uppercase)
  │ ┌────────┬────────┬────────┐                        │
  │ │ 4.990  │ 5.439  │ 4.207  │  ← 3 células SEMPRE    │
  │ │Contratos│Títulos │Contatos│    (a primária em      │
  │ └────────┴────────┴────────┘     bg-muted/30, xl)   │
  │ ▸ Ver detalhes                                      │
  └─────────────────────────────────────────────────────┘
              ▼  [ 118,9% títulos ] [?]  acima de 100% — ver "?"      ← StageArrow
  ┌ LevelCard 02 · Contatados com Sucesso ──────────────┐
  └─────────────────────────────────────────────────────┘

DESFECHOS  — Saídas paralelas do nível 02 — a mesma conta pode estar nas duas,
             e pagar não exige ter respondido.                  (SectionEyebrow + hint)
  ┌ 03 · Solicitaram Atendimento ┐  ┌ 04 · Pagamentos Atribuídos ┐   ← grid sm:grid-cols-2
  │ …  [N]  [xx% do nível 02 [?]]│  │ …                          │
  └──────────────────────────────┘  └────────────────────────────┘

────────────────────────────────────────────────────────────────
        PAGAMENTOS ATRIBUÍDOS SOBRE A BASE ELEGÍVEL [?]
            2,1% contratos · 1,8% títulos · 2,4% contatos
              ▸ Ver por canal e pagamentos totais
```

#### 5.4.2 Controles e interações

| Elemento | Tipo | Comportamento |
|---|---|---|
| **Contar por** (`MetricToggle`) | Grupo de 3 botões, `role="group" aria-label="Contar por"`, `aria-pressed` | Alterna `Contratos` / `Títulos` / `Contatos`. Estado local do `ExecutiveTab` (`metricMode`, default `"contracts"`). **Não persiste na URL** |
| `?` ao lado de "Contar por" | `MetricExplanationPopover` | Texto `METRIC_MODE_EXPLANATION` (ver §12) |
| `?` de cada nível | `MetricExplanationPopover side="right"` | `FUNNEL_LEVEL_COPY[n].explanation` (ver §12) |
| `?` da porcentagem entre etapas | `MetricExplanationPopover side="right"` | Gerado por `stageArrowExplanation(from, to)` — cita os **eixos de data** dos dois níveis |
| `?` da porcentagem de desfecho | `MetricExplanationPopover side="left"` | `outcomeShareExplanation(outcome, stage)` |
| **Ver detalhes / Ocultar detalhes** | `<button>` com `aria-expanded`, chevron `ChevronRight`/`ChevronDown` | Abre os painéis de breakdown do nível. **Apenas um nível expandido por vez** (`expandedStep` é um único número; clicar no mesmo fecha) |
| **Ver por canal e pagamentos totais** | `<button aria-expanded>` centralizado no rodapé | Abre `ConversionChannelPanel` + `OrganicBreakdownPanel` |
| Aviso inline `acima de 100% — ver "?"` | `<span>` text-[10px] | Aparece na seta quando `toValue > fromValue` |

#### 5.4.3 Os quatro níveis (dados + cores)

| Nível | Label | `kind` | Cor (accent bar + badge text) | Badge bg | Campos de dado | Breakdown |
|---|---|---|---|---|---|---|
| 01 | **Base Elegível** | `stage` | `#94a3b8` (slate) | `rgb(148 163 184 / 0.15)` | `contractCount` / `portfolio` / `contactCount` | `CoverageBreakdownPanel` (títulos, contratos, contatos vs totais da base) |
| 02 | **Contatados com Sucesso** | `stage` | `#3b82f6` (azul) | `rgb(59 130 246 / 0.15)` | `actionedContracts` / `actionedTitles` / `actionedContacts` | `ChannelBreakdownPanel` a partir de `channelSent` |
| 03 | **Solicitaram Atendimento** | `outcome` | `#8b5cf6` (roxo) | `rgb(139 92 246 / 0.15)` | `repliedContracts` / `repliedTitles` / `repliedContacts` | `ChannelBreakdownPanel` a partir de `channelReplied` |
| 04 | **Pagamentos Atribuídos** | `outcome` | `#10b981` (verde) | `rgb(16 185 129 / 0.15)` | `paidContracts` / `paid` / `paidContacts` | `ChannelBreakdownPanel` a partir de `channelPaid` |

Legendas e eixos de data (de `collection-funnel-copy.ts`):

| Nível | `legend` | `dateAxis` |
|---|---|---|
| 01 | "em carteira de campanha ativa, vencendo no período" | "por data de vencimento" |
| 02 | "receberam ao menos uma ação entregue" | "por data da ação" |
| 03 | "responderam a alguma cobrança" | "por data da ação" |
| 04 | "pagaram, com o pagamento creditado à Torre" | "por data do pagamento" |

#### 5.4.4 Painéis de breakdown

**`CoverageBreakdownPanel` (nível 01)** — título "Cobertura da base" + `?`.
Três linhas (Títulos, Contratos, Contatos), cada uma com: rótulo | barra horizontal (h-2, cor do nível @60% opacidade, largura `min(ratio,100)%`) | `xx.x%` | `{valor} / {total}`.

**`ChannelBreakdownPanel` (níveis 02-04)** — título "Por canal ({unidade})" + `?`.
Texto de advertência fixo, sempre visível: *"Cobertura por canal, não repartição: a mesma conta pode receber mais de um canal, então a soma passa de 100%."*
Linhas ordenadas por volume desc; grid `[1fr, 2fr, auto]`: bolinha colorida + nome do canal | barra (largura proporcional ao maior) + `%` | `{n}/{total}`.

**Paleta de canais (`CHANNEL_CONFIG` do `CollectionFunnel`)**

| Chave | Rótulo | Cor do ponto |
|---|---|---|
| `whatsapp` | WhatsApp | `#22c55e` |
| `sms` | SMS | `#8b5cf6` |
| `email` | E-mail | `#eab308` |
| `voice` | Voz | `#3b82f6` |
| `rcs` | RCS | `#06b6d4` |
| `negativation` | Negativação | `#f97316` |
| `notification` | Notificação | `#14b8a6` |
| `outro` | Outro | `#6b7280` |
| *(fallback)* | nome cru do banco | `#6b7280` |

**`ConversionChannelPanel`** (dentro do rodapé expandido) — "Conversão por canal ({unidade})" + `?`.
Pagamentos atribuídos por canal, medidos sobre a **Base Elegível**. Barras verdes `#10b981` @60%.

**`OrganicBreakdownPanel`** (dentro do rodapé expandido) — "Pagamentos totais" (ou **"Pagamentos totais · toda a carteira"** quando há filtro de campanha/régua).
- Cabeçalho: `TrendingUp` + título + `?` + `{n} títulos` + `({valor BRL})`.
- **Aviso condicional (`scopeFiltered`)**: *"Não segue o filtro de campanha/régua: pagamento orgânico não tem ação atribuída, logo não tem campanha — filtrar zeraria a fatia orgânica. O nível **Pagamentos Atribuídos** acima, esse sim, é da campanha selecionada."*
- Barra proporcional h-3: verde `#10b981` (Torre) | cinza `#94a3b8` (Orgânico), com `title` de hover em cada segmento.
- Duas linhas de legenda: **Torre Atribuídos** e **Orgânicos**, cada uma com quadradinho colorido, contagem em negrito, `(xx.x%)` e valor em BRL, alinhados em colunas de largura fixa.
- Só renderiza se `totalPaidTitles > 0`.

#### 5.4.5 Resumo do rodapé

Título: **"Pagamentos atribuídos sobre a base elegível"** (uppercase, tracking-wide) + `?` (`FUNNEL_PANEL_EXPLANATIONS.overall`).
Três porcentagens lado a lado separadas por `·`: `{x}% contratos · {y}% títulos · {z}% contatos` — sempre nível 4 ÷ nível 1, nas **três** unidades ao mesmo tempo (não segue o "Contar por").

#### 5.4.6 Estados do funil

| Estado | Render |
|---|---|
| `isLoading` | 4 retângulos `h-28 bg-muted rounded-lg animate-pulse` |
| `isError` (**tem precedência sobre vazio**) | Bloco de 300px: `AlertCircle` h-8 destructive + "**Não foi possível carregar o funil.**" + "A consulta excedeu o tempo limite. Tente um período menor ou aplique uma carteira para reduzir o volume." + botão `Tentar novamente` (outline sm) |
| `levels` vazio | Bloco de 300px centralizado: "Sem dados para exibir" |

> O comentário do código explica a ordem: `levels` chega vazio nos dois casos, então **erro tem de ser checado antes** — senão um timeout de 30s pareceria "organização sem carteira".

### 5.5 Bloco 3b — Sidebar: Aging

Card compacto: `CardTitle text-sm` **"Aging"** + `AgingMetricToggle` no canto direito do header.

| Item | Valor |
|---|---|
| Toggle | 3 botões segmented (`bg-muted rounded-md p-0.5`): `Contratos` \| `Titulos` \| `Contatos`. Estado local `agingMetricMode`, default `"contracts"` |
| Tipo de gráfico | Lista de **barras horizontais empilhadas verticalmente** (não é recharts — HTML/CSS puro) |
| Linha | `{range}` + `({count} titulo/titulos)` à esquerda; **valor em BRL** à direita (font-semibold); abaixo, trilho `h-3 bg-muted rounded-full` com preenchimento colorido; abaixo, `xx.x%` alinhado à direita |
| Largura da barra | `percentage` do total, com piso de 2% quando `> 0` (para a faixa nunca sumir) |
| Paleta por índice | 0 `bg-success` (Em dia) · 1 `bg-emerald-400` (1-30) · 2 `bg-warning` (31-60) · 3 `bg-orange-500` (61-90) · 4 `bg-red-500` (91-180) · 5 `bg-destructive` (180+) |
| Buckets (da RPC) | `current`, `days1_30`, `days31_60`, `days61_90`, `days91_180`, `days180Plus` |
| Animação | `transition-all duration-500 ease-out` |
| Loading | 4 blocos skeleton (linha de rótulos + barra) |
| Vazio | "Nenhum titulo em atraso" |
| Erro | ⚠️ Sem estado dedicado |
| Interação | **Nenhuma** — sem hover, sem clique, sem drill-down |
| Responde | "onde está concentrado o risco da carteira" |

### 5.6 Bloco 3c — Sidebar: Saúde da Carteira (`PaymentHealthChart`)

Card compacto: `CardTitle text-sm` **"Saude da Carteira"** (sem acento no código) + `AgingMetricToggle` (estado `healthMetricMode`, default `"contracts"`).

| Item | Valor |
|---|---|
| Tipo | Mesma linguagem visual do Aging: barras horizontais CSS |
| Linha | `{bucket.label}` + `({count} unidade)` **dentro de um `Tooltip`** | `xx.x%` à direita |
| Tooltip (hover no rótulo) | `"{paid_count} pagos | {unpaid_count} em aberto"` |
| Sub-linha | `media {avg_delay.toFixed(1)} dias de atraso` — **exceto** no bucket `a_vencer` e quando `avg_delay = 0` |
| Paleta por chave | `pontual` → `bg-success` · `leve` → `bg-emerald-400` · `moderado` → `bg-warning` · `grave` → `bg-orange-500` · `critico` → `bg-destructive` · `a_vencer` → `bg-muted-foreground/30` |
| Fonte | RPC `get_payment_health` (`usePaymentHealth`) — retorna `buckets` + agregados |
| Loading | 4 skeletons |
| Vazio | "Sem dados de pagamento" (quando `!data` ou total = 0) |
| Erro | ⚠️ Sem estado dedicado |

### 5.7 Bloco 3d — Sidebar: Status de Entrega (`ActionStatusBreakdown`)

**Card condicional**: só renderiza se `funnelData && funnelData.statusBreakdown.length > 0`.

| Item | Valor |
|---|---|
| Card title | `Status de Entrega` (text-sm) |
| Cabeçalho interno | `**{total}** acoes processadas` |
| Linha | bolinha colorida + **rótulo de exibição** (com `cursor-help` quando há descrição, dentro de `Tooltip`) | `{pct}% {count}` à direita | barra fina `h-1` proporcional ao **maior** valor |
| Rótulos de exibição | Via `getActionStatusLabel()`: `Falhou` → "Falha Temporária de Ação"; `Falha Permanente` → "Falha Definitiva de Ação"; `Respondido` → "Solicitou Atendimento" |
| Formato do % | `≥1%` → 0 casas; `<1%` → 1 casa |
| Loading | 5 barras skeleton |
| Vazio | "Nenhuma acao no periodo" (altura 120) |

**Cores por status (`STATUS_CATEGORY`)**

| Status canônico | Categoria exibida | Cor |
|---|---|---|
| `Interagiu` | Interagiu | `#06b6d4` |
| `Respondido` | Sucesso | `#22c55e` |
| `Enviado` | Enviado | `#3b82f6` |
| `Em Atendimento` | Em atendimento | `#8b5cf6` |
| `Falhou` / `Falha Permanente` | Falha | `#ef4444` |
| `Cancelado` / `Cancelado (Pago)` / `Cancelado (Removido)` | Cancelado | `#f59e0b` |
| `Duplicado` | Cancelado | `#64748b` |
| *(outros)* | Outro | `#94a3b8` |

**Tooltips por status (`STATUS_DESCRIPTIONS`)**

| Status | Texto |
|---|---|
| Enviado | "Mensagem enviada com sucesso ao provedor de entrega" |
| Interagiu | "Contato interagiu com a mensagem (entrega confirmada, leitura ou clique)" |
| Respondido | "Contato solicitou atendimento respondendo à mensagem" |
| Em Atendimento | "Contato está em atendimento humano, ação não foi enviada para não interferir" |
| Falhou | "Falha no envio vinda da integração, pode ser retentada" |
| Falha Permanente | "Falha definitiva: número inválido, contato bloqueou ou template rejeitado" |
| Cancelado | "Ação cancelada manualmente" |
| Cancelado (Pago) | "Ação cancelada automaticamente porque o título foi pago antes do envio" |
| Cancelado (Removido) | "Ação cancelada porque a ação foi substituida ou o título foi removido da carteira" |
| Duplicado | "Ação não enviada porque já foi realizada anteriormente" |

### 5.8 Bloco 4 — Freq. de Acionamento (card full-width)

Header: `CardTitle text-sm` **"Freq. de Acionamento"** + subtítulo `text-xs muted`: *"Média de ações por título, contrato e contato no período selecionado."*

#### 5.8.1 `ActionFrequencyTable` (parte superior)

Grid CSS de 5 colunas (não é `<table>`):

| (canal) | Título | Contrato | Contato | Total |
|---|---|---|---|---|
| ● WhatsApp | `2.3x` | `1.8x` | `1.4x` | `12.404` |
| ● E-mail | … | … | … | … |
| **Total** | média global | média global | média global | total |

- Ordenação: `totalActions` desc.
- Formato de média: `{v.toFixed(1)}x`; quando `0` → `-`.
- Paleta de canal (própria deste componente): `whatsapp #22c55e`, `sms #8b5cf6`, `email #eab308`, `voice #3b82f6`, `outro #6b7280`.
- **Linha Total** usa os `DISTINCT` globais do backend (`actionedTitles/Contracts/Contacts`) — comentário explícito: somar os distintos por canal duplicaria entidades acionadas em mais de um canal.
- Loading: 3 barras skeleton. Vazio: "Sem dados de frequência" (h-120). Erro: `AlertCircle` + "Não foi possível carregar a frequência de acionamento." + `Tentar novamente`.

#### 5.8.2 `ActionFrequencyTrend` (parte inferior, separada por `border-t`)

Cabeçalho: `Evolução por período` (text-xs, à esquerda) + `GranularityToggle` (à direita).

| Item | Valor |
|---|---|
| Toggle | `Dia` \| `Semana` \| `Mes` — estado `freqGranularity`, default `"day"`. **Dedicado**: desacoplado do toggle do timeline full-width, "para não surpreender o usuário ao trocar uma delas" |
| Tipo | `LineChart` (recharts), altura 140, margens negativas à esquerda |
| Séries | `avgPerTitle` "Ações/título" `#3b82f6` · `avgPerContract` "Ações/contrato" `#8b5cf6` · `avgPerContact` "Ações/contato" `#22c55e`. `strokeWidth 2`, `dot={false}` |
| Eixo X | `period`, formatado: dia `dd/MM`; semana `Sem. dd/MM`; mês `MMM/yy` (pt-BR); `interval="preserveStartEnd"` |
| Eixo Y | `allowDecimals` |
| Tooltip customizado | Card `rounded-lg border bg-card p-3 shadow-md`, min 180px: rótulo do período; 3 linhas com bolinha + nome + `x.xx` ; separador; **Total de ações** |
| Tabela de apoio | Abaixo do gráfico, grid de 5 colunas com cabeçalho sticky, `max-h-180px` com scroll: Período / Título / Contrato / Contato / Total |
| Rodapé explicativo (fixo) | *"Fonte: ações enviadas (Enviado/Interagiu/Respondido/Em Atendimento). Numerador: nº de ações. Denominadores: títulos, contratos e contatos distintos POR período. O total global não é a soma dos períodos."* |
| Loading | bloco 120px + 2 barras, `data-testid="freq-trend-loading"` |
| Erro | `AlertCircle` + "Não foi possível carregar a série de frequência." + `Tentar novamente` |
| Vazio | "Sem dados de frequência no período" |

### 5.9 Bloco 5 — Acionamentos ao Longo do Tempo (`ActionsTimelineChart`)

Header do card: título `Acionamentos ao Longo do Tempo` + ícone `BarChart3` + **`HelpTip` composto** (ver §12); descrição: *"Acoes por periodo (status de entrega) e, ao lado, os pagamentos do periodo separados entre Torre e espontaneo"*. À direita, `GranularityToggle` (estado `timelineGranularity`, default `"day"`).

| Item | Valor |
|---|---|
| Tipo | `BarChart` empilhado, altura 300 — **duas pilhas por período** (`stackId` por família) |
| Eixo X | `period`, `tickFormatter`: dia `dd/MM`; semana `Sem dd/MM`; mês `MMM yy` (pt-BR); `interval="preserveStartEnd"` |
| Eixo Y | `≥1000 → {n}k` |
| Interação | Hover → tooltip customizado. **Sem clique nem drill-down** |

**As 7 séries, em duas famílias:**

| Família (`stackId`) | Série | `dataKey` | Rótulo | Cor |
|---|---|---|---|---|
| `actions` | 1 | `success` | Sucesso | `#22c55e` |
| `actions` | 2 | `sent` | Enviado | `#3b82f6` |
| `actions` | 3 | `inService` | Em Atendimento | `#8b5cf6` |
| `actions` | 4 | `failed` | Falha | `#ef4444` |
| `actions` | 5 | `cancelled` | Cancelado | `#f59e0b` |
| `payments` | 6 | `paid` | **Pago (Torre)** | `#10b981` |
| `payments` | 7 | `paidOrganic` | **Pago (espontâneo)** | `#94a3b8` |

> O cinza `#94a3b8` é deliberadamente o **mesmo** do "Orgânicos" no painel "Pagamentos totais" do funil, na mesma tela.

**Tooltip customizado** (`min-width 220px`): rótulo do período; depois **um bloco por família**, cada um com seu subtotal (`actionsTotal` / `paidTotal`) no cabeçalho; dentro, uma linha por categoria com bolinha, `{label} ({valor}) · {pct}%` **calculado sobre o subtotal da própria família**; e, quando houver mais de um status canônico dentro da categoria, um sub-bloco indentado listando `status / count` ordenado desc. **Não existe mais um "Total" geral no pé** — somar ações com pagamentos era o bug original.

**Legenda customizada** (`ChartLegend`, abaixo do gráfico): duas linhas agrupadas por família, cada família com o nome em uppercase e os quadradinhos coloridos de suas séries.

| Estado | Render |
|---|---|
| Loading | `ChartSkeleton height={300}` |
| Erro | `AlertCircle` h-6 + "Não foi possível carregar os acionamentos do período." + `Tentar novamente` (altura 300) |
| Vazio | ícone `BarChart3` h-12 opacity-50 + "Sem acoes no periodo" (condição: sem pontos ou todos com `total = 0`) |

### 5.10 Bloco 6 — Eficiência por Step

Header do card: título `Eficiencia por Step` + `BarChart3`; descrição *"Performance de cada faixa de acionamento (trigger day)"*. À direita, **dois `Select`**:

| Select | Largura | Opções | Default | Efeito |
|---|---|---|---|---|
| Granularidade | `h-8 w-[150px] text-xs` | `Consolidado` (`none`) · `Evolucao por dia` · `Evolucao por semana` · `Evolucao por mes` | `Consolidado` | `null` = só a tabela consolidada (1 consulta). Escolher dia/semana/mês **liga uma 2ª consulta** e faz aparecer o `StepEvolutionChart` acima da tabela |
| Canal | `h-8 w-[130px] text-xs` | `Todos` · `WhatsApp` · `E-mail` · `SMS` · `Voz` | `Todos` (`null`) | Recorta **tanto a tabela quanto o gráfico** |

> Decisão de produto registrada no código: a evolução **não substitui** a tabela — "a tabela diz qual faixa converte melhor; a evolução diz se ela melhorou ou piorou". As duas convivem.

#### 5.10.1 `StepEvolutionChart` (só com granularidade ≠ Consolidado)

| Item | Valor |
|---|---|
| Tipo | `LineChart`, altura 280 — **uma linha por faixa de acionamento** |
| Seletor de métrica | Fileira de `Button variant="ghost" size="sm"` com `aria-pressed`: `Ações` (`totalActions`) · `Acionadas` (`delivered`) · `Respostas` (`responses`) · `Conversões` (`conversions`) · `Valor convertido` (`convertedValue`, em BRL). Default `Ações` |
| Regra | **Uma métrica por vez, nunca duas no mesmo eixo** (ações e conversões diferem por ordem de grandeza) |
| Top N | Máximo **6 séries**, escolhidas por volume total (`MAX_SERIES = 6`) |
| Rótulo da faixa | `D+0`, `D+{n}`, `D{-n}`, `N/D` |
| Eixo X | rótulo do bucket: mês `MMM/yy`; dia/semana `dd/MM` |
| Eixo Y | BRL quando a métrica é monetária (largura 80), senão `toLocaleString` (largura 48) |
| Paleta das séries | `#6366F1` (sólido) · `#0EA5E9` (`6 3`) · `#F97316` (sólido) · `#10B981` (`3 3`) · `#A855F7` (`8 4`) · `#EF4444` (`2 4`) — **traço variável para não depender só de cor** (acessibilidade) |
| Legenda | `<Legend wrapperStyle={{fontSize:11}} />` |
| Texto de apoio | "Uma linha por faixa de acionamento, agrupada por {dia/semana/mês}. Unidade: {unidade}. Comparar dois pontos da mesma linha é a comparação entre períodos." + quando há faixas ocultas: "Exibindo as 6 faixas de maior volume; **{n}** ficaram fora do gráfico e continuam na tabela." |
| Tabela acessível | `<details>` com summary **"Ver os dados do gráfico em tabela"** — tabela HTML com `<caption class="sr-only">`, `scope="col"`/`scope="row"`, mesmos números e unidade. Existe porque "o gráfico sozinho não é legível por leitor de tela nem imprimível" |
| Loading | `ChartSkeleton` |
| Erro | `AlertCircle` + "Não foi possível carregar a evolução por step." + `Tentar novamente` (h-280) |
| Vazio | ícone `LineChart` + "Sem evolução para exibir no período e na granularidade escolhidos." |

#### 5.10.2 `StepDynamicTable` (sempre presente)

Container: `<section className="overflow-hidden rounded-xl border bg-background shadow-sm">`.

**Barra de controle** (`border-b bg-muted/20 p-4`, empilha no mobile):
- Esquerda: ícone `TableProperties` + **"Tabela dinâmica"**; abaixo, *"Escolha a hierarquia e as métricas. Os percentuais são recalculados sobre cada agrupamento."*
- Direita:
  - `Select` de hierarquia — **só aparece com granularidade ≠ Consolidado**: `Faixa → período` (default) \| `Período → faixa`;
  - `Popover` **"Métricas ({n})"** com ícone `Columns3` — lista de 8 checkboxes; item selecionado ganha `Check` verde; rodapé *"Ao menos uma métrica permanece selecionada."* (a última não pode ser desmarcada).

**As 8 métricas selecionáveis** (todas visíveis por default):

| id | Rótulo | Cálculo | Formato |
|---|---|---|---|
| `totalActions` | Ações | soma | inteiro pt-BR |
| `delivered` | Acionadas | soma | inteiro |
| `deliveryRate` | Tx. acionadas | `delivered ÷ totalActions × 100` | `%` com 1 casa |
| `responses` | Respostas | soma | inteiro |
| `responseRate` | Tx. resposta | `responses ÷ delivered × 100` | `%` |
| `conversions` | Conversões | soma | inteiro |
| `conversionRate` | Tx. conversão | `conversions ÷ delivered × 100` | `%` |
| `convertedValue` | Valor convertido | soma | BRL |

**Tabela**:
- Cabeçalho `sticky top-0 z-20 bg-background`; container com `max-h-[520px]` e scroll (`data-testid="step-table-scroll-container"`); `min-w-max` (scroll horizontal).
- 1ª coluna (`min-w-[220px]`): rótulo dinâmico — `Faixa` (consolidado), `Faixa / período` ou `Período / faixa`.
- Linhas de grupo (`bg-muted/15 font-medium`): botão com chevron (`ChevronRight`/`ChevronDown`), rótulo e `{n} itens`. Expansível **só quando há granularidade**; `aria-expanded`.
- Linhas filhas (`bg-muted/5`): rótulo indentado `pl-10`, valores em `text-muted-foreground`.
- `TableFooter sticky bottom-0`: **"Total do recorte"** com todas as métricas recalculadas sobre o agregado global.
- Múltiplos grupos podem ficar abertos ao mesmo tempo (`Set` de chaves).

**Rótulos**: faixa → `D+0` / `D+{n}` / `D{-n}` / `Sem faixa`; período → `Todo o período` (consolidado), `dd/MM/yyyy` (dia), `Semana de dd/MM/yyyy`, `MMMM 'de' yyyy` (mês, pt-BR).

| Estado | Render |
|---|---|
| Loading | `ChartSkeleton` |
| Erro | `AlertCircle` + "Não foi possível carregar a tabela de eficiência por step." + `Tentar novamente` |
| Vazio | "Nenhum dado para o recorte selecionado." (min-h-52) |

#### 5.10.3 `StepConversionTable` — componente legado

`src/components/dashboard/charts/StepConversionTable.tsx` existe e está completo (tabela HTML com 9 colunas: Faixa, Acoes, Acionadas, Tx Acionadas, Respostas, Tx Resp., Conversoes, Tx Conv., Valor Conv.; pílula colorida por faixa — azul `≤0`, âmbar `≤30`, laranja `≤60`, vermelho `>60`; destaque verde-esmeralda na melhor taxa de resposta e de conversão; linha de totais; `HelpTip` na coluna "Acoes": *"Apenas acoes vinculadas a workflow steps. Broadcasts e acoes manuais nao sao incluidas."*).

⚠️ **Ele não é renderizado pela `ExecutiveTab` atual** — foi substituído por `StepDynamicTable`. Vale como referência de padrões visuais (pílula por faixa de atraso, destaque do melhor) que o redesign pode querer recuperar.

---

## 6. Aba Eficiência Operacional

Arquivo: `src/components/dashboard/tabs/OperationalTab.tsx`. **Owner-only.** Container `space-y-6`.
Consome `useFunnelDataUnified`, `useDeliveryRatesUnified`, `useFailureReasonsUnified`, `useDashboardCosts` — todos com os mesmos filtros globais.

### 6.1 Funil de Cobrança (operacional) — `FunnelChart`

Card: título `Funil de Cobrança` + `Filter`; descrição *"Jornada completa: da carteira ao pagamento"*.

> ⚠️ **Este é um segundo funil, diferente do da Visão Executiva.** Mesmo título, 7 estágios, outro componente, outra leitura.

| Item | Valor |
|---|---|
| Tipo | `BarChart` **horizontal** (`layout="vertical"`), altura 300, `barSize 28`, `radius [0,4,4,0]` |
| Eixo X | numérico, `≥1000 → {n}k` |
| Eixo Y | categórico, `dataKey="name"`, `width 90` |
| Rótulos | `LabelList position="right"` com o valor absoluto (pt-BR) |
| Grid | apenas vertical (`horizontal={false}`) |
| Tooltip | `[valor, "Valor"]` |
| Interação | Hover apenas |
| Loading | 6 barras skeleton com larguras decrescentes (`100 - i*12`%) |
| Vazio | "Sem dados para exibir" (h-300) |
| Erro | ⚠️ Sem estado dedicado |

**Os 7 estágios e suas cores:**

| # | Nome | Campo | Cor |
|---|---|---|---|
| 1 | Carteira do Dia | `portfolio` | `hsl(var(--primary))` |
| 2 | Processados | `processed` | `hsl(var(--info))` |
| 3 | Enviados | `sent` | `hsl(142 76% 36%)` (verde) |
| 4 | Interagiram | `delivered` | `hsl(38 92% 50%)` (âmbar) |
| 5 | Solicitaram Atendimento | `replied` | `hsl(270 60% 50%)` (roxo) |
| 6 | Promessa | `promised` | `hsl(340 82% 52%)` (rosa) |
| 7 | Pagamento | `paid` | `hsl(142 76% 36%)` (verde) |

**`ConversionRates`** (abaixo do gráfico, `border-t`, `flex-wrap gap-3`): uma pílula de texto por transição — `{etapa anterior} → {etapa} **{taxa}%**`, calculada como `valor ÷ valor anterior × 100`. São 6 pares. Não há explicação `?` nem ressalva sobre eixos de data neste funil.

### 6.2 Taxa de Interação por canal — 4 KPI Cards

Grid `md:grid-cols-2 lg:grid-cols-4`.

| KPI | Valor | Descrição | Ícone | Variante | Tooltip |
|---|---|---|---|---|---|
| **WhatsApp** | `{deliveryRates.whatsapp.toFixed(1)}%` | "Taxa de Interação" | `MessageSquare` | `> 90` → success; senão warning | "Interações confirmadas pelo WhatsApp ÷ total de mensagens enviadas" |
| **Email** | `{…email…}%` | "Taxa de Interação" | `Send` | `> 80` → success; senão warning | "Interações com emails ÷ total de emails enviados" |
| **SMS** | `{…sms…}%` | "Taxa de Interação" | `MessageSquare` | `> 85` → success; senão warning | "Interações com SMS ÷ total de SMS enviados" |
| **Voz** | `{…voice…}%` | "Taxa de **Atendimento**" | `CheckCircle` | `> 70` → success; senão warning | "Ligações atendidas ÷ total de chamadas realizadas" |

Todos usam `isLoading={ratesLoading}` (skeleton do próprio `KPICard`) e `tooltip` simples (não `explanation` estruturada).

### 6.3 Custo Estimado de Envios

Card: título `Custo Estimado de Envios` + `DollarSign`; descrição *"Baseado nos custos configurados x ações no período"*. Dentro, um grid de 4 `KPICard`.

| KPI | Valor | Descrição | Ícone | Variante | Tooltip |
|---|---|---|---|---|---|
| **Custo Total** | `formatBRL(totalCost)` ou `R$ 0,00` | `{Σ count} ações no período` | `DollarSign` | `info` | "Soma dos custos estimados de todas as ações no período filtrado" |
| **WhatsApp** | custo do canal `whatsapp` | `{count} envios` | `MessageSquare` | default | "Custo estimado de envios WhatsApp no período" |
| **IA** | custo do canal `ai` | `{count} interações` | `Bot` | default | "Custo estimado de interações com IA (GPT-5.2 / Gemini 3 Flash)" |
| **Outros** | soma dos canais ≠ whatsapp/ai | `{count} ações (SMS, Email, Voz, Neg.)` | `Send` | default | "Custo estimado de SMS + Email + Voz + Negativação no período" |

Fonte: `useDashboardCosts` conta ações por canal no período e cruza com `channel_costs` configurados. ⚠️ Se não houver custos cadastrados, a query nem roda (`enabled` falso) e os cards mostram `R$ 0,00` / `0` — sem aviso na tela de que a origem é "custo não configurado".

### 6.4 Principais Motivos de Falha

Card: título `Principais Motivos de Falha` + `AlertCircle`; descrição *"Top erros de entrega no período"*.

| Coluna | Conteúdo | Alinhamento |
|---|---|---|
| **Motivo** | `Badge variant="outline"` com `#{índice+1}` + texto do motivo | esquerda |
| **Quantidade** | inteiro pt-BR | direita, `tabular-nums` |
| **%** | `{percentage.toFixed(1)}%` | direita, `font-medium` |

Cor do badge de posição: `percentage > 30` → `border-destructive text-destructive`; `> 15` → `border-warning text-warning`; senão neutro.

| Estado | Render |
|---|---|
| Loading | 5 linhas de skeletons (3 blocos cada) |
| Vazio | ícone `CheckCircle` h-12 opacity-50 + **"Nenhuma falha registrada no período"** (estado positivo, não neutro) |
| Erro | ⚠️ Sem estado dedicado |
| Interação | Nenhuma (sem ordenação, sem clique) |

---

## 7. Aba Performance da IA

Arquivo: `src/components/dashboard/tabs/AITab.tsx`. **Owner-only.** É a menor aba em código (30 linhas) e a maior em conteúdo renderizado.

### 7.1 Composição

```tsx
<AgentMetrics
  agentId={filters.agentId}
  period={filters.period}     onPeriodChange={setPeriod}
  granularity={filters.granularity}  onGranularityChange={setGranularity}
  headerSlot={<DashboardAgentSelector value={filters.agentId} onChange={setAgentId} />}
/>
```

A aba **reusa integralmente** o painel `AgentMetrics` (a aba "Métricas" da tela Agente IA), injetando um seletor de agente no `headerSlot`.

### 7.2 Diferenças estruturais em relação às outras abas

| Aspecto | Comportamento |
|---|---|
| Filtros globais | **Não se aplicam.** A `DashboardFiltersBar` é **desmontada** quando `tab=ai` — "a IA nunca consumiu os filtros globais; a barra visível ali era enganosa" |
| Filtros próprios | Namespace `ai_*` na URL (`useAIDashboardFilters` + `src/lib/ai-dashboard-url.ts`) |
| Escrita na URL | `replace: true` — ajustar filtro da IA não entra no histórico |
| Fetch | Nada das abas globais é buscado enquanto `tab=ai` |

### 7.3 Filtros próprios da aba IA

| Param | Valores | Default | Notas |
|---|---|---|---|
| `ai_agent` | uuid do agente | ausente = **todos os agentes** | Validado com `z.uuid()`; inválido → ignorado |
| `ai_period` | `7d` \| `30d` \| `90d` \| `this_month` \| `all` | `30d` | Presets **inclusivos** em BRT: 7 dias = hoje + 6 anteriores |
| `ai_from` / `ai_to` | `yyyy-MM-dd` | — | **Têm precedência** sobre `ai_period`. Validados: data real, `from ≤ to`, sem futuro, **máximo 366 dias** |
| `ai_granularity` | `day` \| `week` \| `month` | derivada do span (`>90d` → mês; `>30d` → semana; senão dia) | Omitida da URL quando igual à derivada |
| `ai_created_from` / `ai_created_to` | `yyyy-MM-dd` | — | Recorte por data de criação do protocolo |
| `ai_last_interaction_from` / `_to` | `yyyy-MM-dd` | — | Recorte por última interação |

Mensagens de validação do período custom (pt-BR): "Selecione as duas datas." · "Selecione datas válidas." · "A data inicial deve ser anterior ou igual à final." · "A data final não pode estar no futuro." · "O intervalo máximo é de 366 dias."

### 7.4 `DashboardAgentSelector`

`src/components/ia/DashboardAgentSelector.tsx` — `Select` com trigger `h-8 w-[240px]`, ícone `Bot`, placeholder "Todos os agentes".

- 1ª opção sempre: **"Todos os agentes"** (`value="__all__"` → `null`).
- Demais: nome do agente + `Star` âmbar preenchida se `is_default` + tipo em `text-[10px]` (ex.: "Agente Externo") + `Badge` de status quando `status !== "active"`.
- Prop opcional `typeFilter` restringe por tipo de agente (não usada pela `AITab`).

### 7.5 Conteúdo (conforme o guia de negócio do app)

> Conteúdo renderizado por `AgentMetrics`, fora do escopo de arquivos deste documento. Descrito aqui pelo guia `src/pages/central-docs/negocio/data/dashboard.ts` para que o redesign saiba o que a aba contém.

- **Barra de filtros própria**: período (7/30/90 dias, Este mês, Custom) + "Agrupamento temporal" (dia/semana/mês, só em janelas > 30 dias).
- **Selo "Parcial"** no topo, com motivo no hover (seção não calculável, verificação de consistência reprovada, alcance restrito aos agentes externos).
- **Visão geral**: Transferências para humano (Total, Transbordo, Transferência, Não classificado); indicadores **Protocolos**, **Acurácia**, **Mensagens**; **Ciclo de vida dos atendimentos** (No período × Agora); gráfico **Conversas por dia**.
- **Detalhamento**: Transbordo e Transferência com drill-down; Tags ao longo do tempo; Top Intents; Tags de conversa; Sentimento; funil trapezoidal (Conversas por estágio, Histórico/Estado atual); Chamadas entre agentes (A2A).
- **Painel recolhido "Detalhes técnicos e verificações"** no fim: procedência da fotografia, cobertura e verificações reprovadas.
- Há um botão próprio de exportação nesta aba (`AiReportExportButton`, "Gerar relatório") — ver §10.

---

## 8. Aba Atribuição

Arquivo: `src/components/dashboard/tabs/AttributionTab.tsx`. **Owner-only.** Container `space-y-6`.

Fonte: `useAttributionKPIs({startDate, endDate})` — Edge Function `get-attribution-kpis`.
⚠️ **Esta aba consome apenas o intervalo de datas** (`sqlDateRange`, com fallback para `filters.startDate/endDate`). **Carteira, régua, campanha, filtro salvo e eixo Contrato/Suprimento NÃO são repassados.** Os filtros aparecem na barra mas não afetam nada aqui.

### 8.1 Cabeçalho da aba

| Elemento | Conteúdo |
|---|---|
| Título (`h3 text-lg font-medium`) | **Atribuição de Pagamentos** |
| Subtítulo (`text-sm muted`) | "Método conservador: pagamentos até 2 dias após interação efetiva (delivered, sent, executed, replied)" |
| Botão (direita) | `Button variant="outline" size="sm"` — ícone `RefreshCw` (gira durante execução) + **"Recalcular Atribuição"** |

**Ação do botão**: invoca a Edge Function `batch-calculate-attribution` com `{ force_recalculate: true }`.
- Sucesso → toast **"Atribuição recalculada"** / `"{processed} títulos: {tower} torre, {manual} manual, {organic} orgânico"`, seguido de `refetch()`.
- Erro → toast destrutivo **"Erro ao recalcular"** com a string do erro.
- Durante: botão `disabled`.

### 8.2 Três cards de origem do pagamento

Grid `md:grid-cols-3`. Cada card tem `border-l-4` com cor própria.

| Card | Cor da borda | Ícone | Descrição | Valor (2xl bold) | Rodapé |
|---|---|---|---|---|---|
| **Torre de Controle** | `hsl(var(--primary))` | `Target` (primary) | "Janela de 2 dias após interação" | `formatCurrency(tower.value)` | `Badge secondary "{count} pagamentos"` + `{pct}%` em `text-primary` |
| **Contato Manual** | `hsl(var(--accent))` | `Users` | "Pagamentos após interação humana" | `formatCurrency(manual.value)` | `Badge` + `{pct}%` em `text-accent-foreground` |
| **Orgânico** | `hsl(var(--muted-foreground))` | `Leaf` | "Pagamentos espontâneos" | `formatCurrency(organic.value)` | `Badge` + `{pct}%` em `text-muted-foreground` |

O card **Torre de Controle** traz um `HelpTip` inline (ver §12).
Moeda: `Intl.NumberFormat("pt-BR", {style:"currency", currency:"BRL"})`. Percentual: 1 casa decimal.

### 8.3 Taxa de Conversão + Atribuição por Canal

Grid `md:grid-cols-2`.

**Card "Taxa de Conversão"**
- Título `text-sm font-medium` + ícone `TrendingUp` + `HelpTip` "Status Efetivos".
- Descrição: "Ações efetivas que converteram em pagamento".
- Valor: **`text-4xl font-bold text-primary`** — `{conversionRate}%` (o maior número da tela).
- Sub-linha: `{tower.count} pagamentos de {round(tower.count / (conversionRate/100))} ações enviadas` (denominador derivado por engenharia reversa).

**Card "Atribuição por Canal"**
- Descrição: "Distribuição dos pagamentos atribuídos à torre por canal".
- Lista ordenada por **valor desc**; cada linha: ícone do canal + nome (`capitalize`) + `Badge outline` com a contagem | valor em BRL + `({pct}%)` em `text-xs muted`.
- Percentual = `stats.value ÷ tower.value × 100`.
- Ícones por canal: `whatsapp → MessageSquare`, `email → Mail`, `sms → Phone`, `voice → Phone`, `webhook → Globe`, fallback `Zap`.
- Vazio: "Nenhum dado por canal disponível".

### 8.4 Resumo do Período

Card com título `Resumo do Período`; grid `md:grid-cols-4`, cada item = rótulo `text-sm muted` + valor `text-xl font-bold`.

| Item | Valor | Cor |
|---|---|---|
| Total de Pagamentos | `kpis.total` (inteiro) | padrão |
| Valor Total Recebido | `formatCurrency(totalValue)` | padrão |
| Valor Atribuído à Torre | `formatCurrency(tower.value)` | `text-primary` |
| **ROI da Automação** | `tower.value ÷ totalValue × 100` em `%` (ou `"0%"`) | `text-primary` |

### 8.5 Estados da aba

| Estado | Render |
|---|---|
| `isLoading` | Grid de 3 cards com skeletons (`h-4 w-24` no header; `h-8 w-32` + `h-4 w-20` no corpo). **Só a primeira linha** é esqueletizada |
| `!kpis` | Card único: "Nenhum dado de atribuição disponível" (py-8, centralizado, muted) |
| Erro | ⚠️ **Sem estado de erro dedicado.** Falha da EF cai em `!kpis` → "Nenhum dado disponível" (indistinguível de vazio) |

---

## 9. Aba Performance de Cobranças (Workflows/Réguas)

Arquivo: `src/components/dashboard/tabs/WorkflowsTab.tsx`. **Owner-only.** Container `space-y-6`.
Rótulo da aba na UI: **"Performance de Cobranças"** (o valor interno é `workflows`).

### 9.1 Comparativo de Réguas

Card: título `Comparativo de Réguas` + `GitBranch`; descrição *"Performance das réguas ativas no período"*.

**Colunas:**

| Coluna | Ícone no header | Conteúdo | Formato |
|---|---|---|---|
| **Régua** | — | nome + `Badge` "Melhor" quando é a de maior `conversionRate` | texto, `font-medium` |
| **Contatos** | `Users` | `contactCount` | inteiro pt-BR, direita |
| **Entrega** | `Send` | `deliveryRate` em `Badge variant="outline"` | `%` 1 casa |
| **Resposta** | — | `responseRate` em `Badge outline` | `%` 1 casa |
| **Conversão** | `HandCoins` | `conversionRate` em `Badge` sólido | `%` 1 casa |

**Cores semânticas por limiar:**

| Métrica | Verde (`success`) | Amarelo (`warning`) | Vermelho / neutro |
|---|---|---|---|
| Entrega | `> 90%` | `> 70%` | `≤ 70%` → `destructive` |
| Resposta | `> 15%` | `> 8%` | `≤ 8%` → `muted-foreground` |
| Conversão (badge sólido) | `> 5%` → `bg-success` | `> 2%` → `bg-warning` | `≤ 2%` → `bg-muted-foreground` |

**Destaque da melhor régua**: a linha inteira ganha `bg-success/5` e um `Badge secondary bg-success/20 text-success` com `TrendingUp` + texto **"Melhor"**. O critério é `conversionRate` máximo.

**Sub-linhas por canal** (`bg-muted/30`), quando `channelBreakdown` não é vazio:
- Coluna 1: `└` + ícone do canal + rótulo (`whatsapp → WhatsApp / MessageSquare`, `email → E-mail / Mail`, `sms → SMS / MessageCircle`, `voice → Voz / Phone`), indentado `pl-8`.
- Coluna Contatos: `{actionCount} ações`.
- Entrega e Resposta: texto colorido (mesmos limiares), sem badge.
- Conversão: `—` (não existe por canal).

| Estado | Render |
|---|---|
| Loading | 5 linhas de skeletons (5 blocos cada) |
| Vazio | ícone `GitBranch` h-12 opacity-50 + "Nenhuma régua com dados no período" |
| Erro | ⚠️ Sem estado dedicado |
| Interação | **Nenhuma** — linhas não são clicáveis, não há ordenação nem drill-down |

### 9.2 Comparativo de Campanhas

Card: título `Comparativo de Campanhas` + `Megaphone`; descrição *"Performance das campanhas no período"*.

Mesma linguagem visual, com **7 colunas** e uma coluna extra de status:

| Coluna | Conteúdo |
|---|---|
| Campanha | nome (`font-medium`) |
| **Status** (centralizado) | `Badge outline`: `active` → "Ativa" (`border-success text-success`); `paused` → "Pausada" (`border-warning`); outro → "Finalizada" (`border-muted-foreground`) |
| Contatos (`Users`) | inteiro |
| **Ações** (`Activity`) | inteiro — coluna que não existe na tabela de réguas |
| Entrega (`Send`) | badge `%` com os mesmos limiares |
| Resposta | badge `%` |
| Conversão (`HandCoins`) | badge sólido `%` |

Sub-linhas por canal: `—` em Status, Contatos e Conversão; `actionCount` em Ações; entrega e resposta coloridas.
**Não há destaque de "melhor campanha".**
Vazio: ícone `Megaphone` + "Nenhuma campanha com dados no período".

### 9.3 Mapa de Calor — Melhor Horário (`HeatmapChart`)

Card: título `Mapa de Calor - Melhor Horário` + `Clock`; descrição *"Taxa de resposta por dia da semana e hora"*.

| Item | Valor |
|---|---|
| Tipo | Grade HTML/CSS 7 × 16 (não é recharts) |
| Linhas | `Dom, Seg, Ter, Qua, Qui, Sex, Sáb` (índices 0-6) |
| Colunas | **Horas 6h a 21h** — 16 colunas fixas. Dados fora dessa faixa **não são exibidos** |
| Célula | `flex-1 h-6 rounded-sm`, cor por intensidade |
| Escala de intensidade | `0` → `bg-muted`; `<0.2` → `bg-primary/20`; `<0.4` → `/40`; `<0.6` → `/60`; `<0.8` → `/80`; senão `bg-primary` (6 níveis, relativo ao máximo do conjunto) |
| Interação | `title` nativo no hover: `"{dia} {hora}h: {valor} respostas"`. **Sem clique** |
| Canto superior esquerdo | célula `w-10` com o rótulo da unidade — a `WorkflowsTab` passa `label="%"` |
| Legenda | rodapé alinhado à direita: "Menor" + 6 quadradinhos em escala + "Maior" |
| Loading | grade inteira em skeleton animado |
| Vazio | ⚠️ **Não há estado vazio** — sem dados, a grade renderiza toda em `bg-muted` |
| Erro | ⚠️ Sem estado dedicado |

---

## 10. Exportação

### 10.1 Situação atual: o botão existe mas NÃO está na tela

`src/pages/DashboardPage.tsx`, linha 14:

```tsx
import {
  DashboardFiltersBar,
  // ExportButton,        ← COMENTADO
  ExecutiveTab,
  …
```

**`ExportButton` está implementado, exportado em `src/components/dashboard/index.ts` e não é renderizado em lugar nenhum** (busca em todo `src/`: nenhuma instância de `<ExportButton`). O Dashboard hoje **não tem exportação**.

⚠️ A confirmar: se o redesign deve reativar a exportação do Dashboard ou tratá-la como funcionalidade descontinuada. O código está íntegro e pronto para uso.

> Outros botões de exportação **existem e funcionam**, mas fora desta tela: `ActionsExportButton` (tela Ações), `ContactHistoryExportButton` (detalhe do cliente) e `AiReportExportButton` (dentro de `AgentMetrics`, portanto **visível na aba Performance da IA**).

### 10.2 Anatomia do `ExportButton` (se reativado)

| Elemento | Detalhe |
|---|---|
| Trigger | `Button variant="outline" size="sm"`, ícone `Download` (ou `Loader2 animate-spin` durante export), rótulo **"Exportar"**, `disabled` enquanto exporta |
| Menu | `DropdownMenuContent align="end" className="w-48"` |
| Item 1 | ícone `FileSpreadsheet` (text-primary) + **"Exportar para Excel"** |
| Separador | `DropdownMenuSeparator` |
| Item 2 | ícone `FileText` (text-destructive) + **"Exportar para PDF"** |

**Feedback (toasts)**

| Ação | Toast |
|---|---|
| Excel OK | "Exportação concluída" / "O arquivo Excel foi baixado com sucesso." |
| Excel erro | "Erro na exportação" / "Não foi possível gerar o arquivo Excel." (destructive) |
| PDF OK | "Relatório gerado" / **"Use Ctrl+P ou Cmd+P para salvar como PDF."** |
| PDF erro | "Erro na exportação" / "Não foi possível gerar o relatório PDF." (destructive) |

### 10.3 O que entra no arquivo Excel (`.xlsx`)

Nome do arquivo: `dashboard_{org_em_snake_case}_{yyyy-MM-dd_HH-mm}.xlsx`. Biblioteca: `xlsx`.

**Cabeçalho comum a todas as abas**: título "Relatório de Dashboard - {org}", descrição dos filtros (`Período: {label} | De dd/MM/yyyy até dd/MM/yyyy | Carteiras: N selecionada(s) | Campanhas: N | Réguas: N | Filtros Salvos: N`) e data de geração.

| Planilha | Conteúdo |
|---|---|
| **Visão Executiva** | Carteira Total, Valor em Atraso, Títulos em Atraso, Recuperado no Período, Taxa de Recuperação, Total de Contatos, Contratos Ativos · **Análise de Aging** (Faixa, Valor, Quantidade) · **Evolução Mensal** (Mês, Dívida, Recuperado, Meta) |
| **Eficiência Operacional** | **Funil** (Etapa, Contratos, Títulos, Contatos, % Contratos) com 4 linhas: Universo de Cobranca / Acionados / Responderam / Pagamentos Atribuidos · **Frequência de acionamento por canal** · **Status de entrega** (Status, Quantidade, Percentual) · **Taxas de interação por canal** · **Motivos de falha** |
| **Performance Réguas** | Nome, Contatos, Taxa Entrega, Taxa Resposta, Taxa Conversão · **Mapa de calor** — top 10 células (Dia, Horário, Taxa de Resposta) |
| **Performance IA** | Total de Atendimentos, Taxa de Retenção, Promessas Geradas pela IA, Transferências para Humano · **Motivos de transbordo** |

⚠️ O export usa um **shape legado de KPIs** (`totalDebt`, `totalRecovered`, `totalContacts`, `activeContracts`) — não os 8 KPIs atuais da tela. Um redesign que reative a exportação deve realinhar as duas listas.
⚠️ A aba **Atribuição não tem planilha** e a aba **Campanhas** também não.

### 10.4 O que entra no PDF

Não é um PDF gerado: é **HTML montado em memória, aberto em `window.open("", "_blank")` e enviado para `window.print()`**. O usuário salva como PDF pela caixa de impressão do navegador.

Estrutura do HTML (estilos inline próprios, independentes do design system do app):

1. Cabeçalho: "Relatório de Dashboard", org + descrição dos filtros, data de geração;
2. **Visão Executiva** — grid de 4 kpi-cards: Carteira Total, Valor em Atraso, Recuperado, Taxa de Recuperação;
3. **Análise de Aging** — tabela (Faixa, Valor, Quantidade);
4. **Funil de Cobrança** — tabela de 4 linhas;
5. **Performance de Cobranças** — tabela (com `page-break-before: always`);
6. **Performance da IA** — 4 kpi-cards + tabela de motivos de transbordo.

Regras de impressão embutidas: `padding: 20px` no `@media print`; `.section { page-break-inside: avoid }`.

---

## 11. Catálogo completo de KPIs e métricas

| Métrica | Aba | Definição (resumida) | Formato | Cor semântica | Fonte / hook |
|---|---|---|---|---|---|
| Carteira Total | Executiva | Valor atualizado da carteira (com juros e multa). Sem período: toda a base; com período: Em Aberto + Paga | BRL | neutra | `useDashboardKPIsUnified` |
| Carteira Original | Executiva | Valor de face, sem encargos | BRL | neutra | idem |
| Em Aberto | Executiva | Saldo devedor pendente = Vencida + A Vencer | BRL | `info` | idem |
| Paga | Executiva | Valor recebido dos títulos quitados | BRL | `success` | idem |
| Vencida | Executiva | Saldo dos títulos vencidos antes de hoje e não pagos | BRL | `warning` | idem |
| A Vencer | Executiva | Saldo dos títulos com `days_overdue ≤ 0` e não pagos | BRL | `info` | idem (`aging.current`) |
| Taxa de Recuperação | Executiva | `pago ÷ valor atual total da carteira × 100` | `%` 1 casa | `>10%` success, senão info | idem |
| Media Atraso Efetivo | Executiva | Média de dias: pagos usam atraso do pagamento; abertos usam atraso atual | `{n} dias` | `>30` danger, `>15` warning, senão success | `usePaymentHealth` |
| Evolução Mensal — Dívida | Executiva | Dívida do mês | BRL | `destructive` | `useMonthlyData` |
| Evolução Mensal — Recuperado | Executiva | Recuperado do mês | BRL | `primary` | idem |
| Tendência — Meta | Executiva | Meta do mês | BRL | `muted` tracejado | idem |
| Funil N1 — Base Elegível | Executiva | Títulos em carteira de campanha ativa vencendo no período | inteiro ×3 (contratos/títulos/contatos) | `#94a3b8` | `useFunnelData` |
| Funil N2 — Contatados com Sucesso | Executiva | Receberam ≥1 ação entregue no período | inteiro ×3 | `#3b82f6` | idem |
| Funil N3 — Solicitaram Atendimento | Executiva | Responderam a alguma cobrança | inteiro ×3 | `#8b5cf6` | idem |
| Funil N4 — Pagamentos Atribuídos | Executiva | Pagaram com crédito a uma ação da Torre (janela 48h) | inteiro ×3 | `#10b981` | idem |
| % entre etapas (N2÷N1) | Executiva | Intensidade de acionamento (**não** é taxa de conversão) | `%` 1 casa | cor do nível destino | derivado |
| % do desfecho (N3÷N2, N4÷N2) | Executiva | Quantos da etapa 2 terminaram naquele desfecho | `%` 1 casa | muted | derivado |
| Resumo "Pagamentos atribuídos sobre a base elegível" | Executiva | N4 ÷ N1, nas 3 unidades simultaneamente | `%` 1 casa ×3 | neutra | derivado |
| Cobertura da base | Executiva (funil, expandido) | N1 ÷ total de títulos/contratos/contatos do período | `%` + `n/total` | cor do nível | `funnelData.total*` |
| Por canal (níveis 2-4) | Executiva (funil, expandido) | Cobertura de cada canal no nível | `%` + `n/total` | paleta de canal | `channelSent/Replied/Paid` |
| Conversão por canal | Executiva (rodapé do funil) | Pagamentos por canal ÷ Base Elegível | `%` 1 casa | `#10b981` | `channelConversion` |
| Pagamentos totais — Torre × Orgânicos | Executiva (rodapé do funil) | Divisão de todos os pagamentos do período | `n` + `%` + BRL | verde/cinza | `totalPaid*`/`towerPaid*` |
| Aging por faixa | Executiva (sidebar) | Distribuição da carteira por faixa de atraso | BRL + `n` + `%` | escala verde→vermelho | `useAgingDataUnified` |
| Saúde da Carteira por bucket | Executiva (sidebar) | Distribuição por qualidade de pagamento (pontual→crítico + a vencer) | `n` + `%` + média de atraso | escala verde→vermelho | `usePaymentHealth` |
| Status de Entrega | Executiva (sidebar) | Distribuição das ações por status canônico | `%` + `n` | paleta por status | `funnelData.statusBreakdown` |
| Freq. de acionamento por canal | Executiva | Ações ÷ títulos/contratos/contatos distintos | `x.x` | paleta de canal | `funnelData.frequency` |
| Freq. de acionamento — série | Executiva | As 3 médias por bucket temporal | `x.x` | 3 cores fixas | `useActionFrequencyTimeline` |
| Acionamentos — 5 séries de ação | Executiva | Ações por período e status agregado | inteiro | ver §5.9 | `useActionsTimeline` |
| Acionamentos — Pago (Torre) | Executiva | Títulos pagos creditados a ação nos 2 dias anteriores | inteiro | `#10b981` | idem |
| Acionamentos — Pago (espontâneo) | Executiva | Títulos pagos sem ação da Torre na janela | inteiro | `#94a3b8` | idem |
| Ações (step) | Executiva | Ações vinculadas a workflow steps da faixa | inteiro | — | `useStepConversionData` |
| Acionadas (step) | Executiva | Ações efetivamente entregues da faixa | inteiro | — | idem |
| Tx. acionadas | Executiva | `Acionadas ÷ Ações` | `%` | — | derivado |
| Respostas (step) | Executiva | Respostas da faixa | inteiro | — | idem |
| Tx. resposta | Executiva | `Respostas ÷ Acionadas` | `%` | — | derivado |
| Conversões (step) | Executiva | Títulos pagos atribuídos à faixa | inteiro | — | idem |
| Tx. conversão | Executiva | `Conversões ÷ Acionadas` | `%` | — | derivado |
| Valor convertido | Executiva | Valor dos títulos convertidos da faixa | BRL | — | idem |
| Funil operacional — 7 estágios | Operacional | Carteira do Dia → Processados → Enviados → Interagiram → Solicitaram Atendimento → Promessa → Pagamento | inteiro | ver §6.1 | `useFunnelDataUnified` |
| Taxas entre estágios | Operacional | `estágio ÷ estágio anterior` | `%` 1 casa | neutra | derivado |
| Taxa de Interação WhatsApp | Operacional | Interações confirmadas ÷ mensagens enviadas | `%` 1 casa | `>90` success | `useDeliveryRatesUnified` |
| Taxa de Interação Email | Operacional | Interações ÷ e-mails enviados | `%` | `>80` success | idem |
| Taxa de Interação SMS | Operacional | Interações ÷ SMS enviados | `%` | `>85` success | idem |
| Taxa de Atendimento Voz | Operacional | Ligações atendidas ÷ chamadas | `%` | `>70` success | idem |
| Custo Total | Operacional | Σ custos estimados das ações no período | BRL | `info` | `useDashboardCosts` |
| Custo WhatsApp / IA / Outros | Operacional | Custo por canal / agregado | BRL | neutra | idem |
| Motivos de falha (Quantidade, %) | Operacional | Top erros de entrega | inteiro + `%` | badge `>30` destructive, `>15` warning | `useFailureReasonsUnified` |
| Torre de Controle (valor/qtd/%) | Atribuição | Pagamentos creditados a ação automatizada, janela de 2 dias | BRL + `n` + `%` | `primary` | `useAttributionKPIs` |
| Contato Manual | Atribuição | Pagamentos após interação humana | BRL + `n` + `%` | `accent` | idem |
| Orgânico | Atribuição | Pagamentos espontâneos | BRL + `n` + `%` | `muted` | idem |
| Taxa de Conversão | Atribuição | Ações efetivas que viraram pagamento | `%` 1 casa (4xl) | `primary` | idem |
| Atribuição por Canal | Atribuição | Valor por canal ÷ valor Torre | BRL + `%` | neutra | idem |
| Total de Pagamentos | Atribuição | Contagem de pagamentos do período | inteiro | neutra | idem |
| Valor Total Recebido | Atribuição | Soma recebida no período | BRL | neutra | idem |
| Valor Atribuído à Torre | Atribuição | Valor creditado à Torre | BRL | `primary` | idem |
| ROI da Automação | Atribuição | `valor Torre ÷ valor total × 100` | `%` 1 casa | `primary` | derivado |
| Comparativo de Réguas — Contatos | Cobranças | Contatos alcançados pela régua | inteiro | neutra | `useWorkflowsComparisonUnified` |
| Comparativo de Réguas — Entrega/Resposta/Conversão | Cobranças | Taxas da régua | `%` 1 casa | ver §9.1 | idem |
| Comparativo de Campanhas — Ações | Cobranças | Ações da campanha | inteiro | neutra | `useCampaignsComparisonUnified` |
| Comparativo de Campanhas — Status | Cobranças | Ativa / Pausada / Finalizada | badge | verde/âmbar/cinza | idem |
| Mapa de Calor | Cobranças | Taxa de resposta por (dia da semana × hora 6-21h) | `%` (no `title`) | escala `primary` 6 níveis | `useHeatmapDataUnified` |
| Protocolos / Acurácia / Mensagens | IA | Indicadores do agente | ver `AgentMetrics` | — | `aiPerformanceKeys` |
| Transferências (Total/Transbordo/Transferência/Não classificado) | IA | Transferências para humano | inteiro | — | idem |

---

## 12. Modais, popovers e explicações — inventário e conteúdo

### 12.1 Os dois átomos de ajuda (coexistem de propósito)

| | `HelpTip` | `MetricExplanationPopover` |
|---|---|---|
| Arquivo | `src/components/common/HelpTip.tsx` | `src/components/common/MetricExplanationPopover.tsx` |
| Ícone | `HelpCircle` `size-3.5`, `text-muted-foreground`, `cursor-help` | `HelpCircle` `h-3.5 w-3.5`, mesmo estilo |
| Variantes | `popover` (clicável, **default**) e `tooltip` (hover, só textos curtos) | Só popover |
| Largura | `w-80 max-w-[90vw]` | `w-80 max-w-sm` |
| `aria-label` | `Ajuda: {título}` (ou "Ajuda") | `Como calculamos {título}` |
| Fonte do texto | Chave de `HELP_COPY` (`topic`) **ou** `title`/`body` inline **ou** `explanation` estruturada | `explanation` estruturada **ou** `tooltip` simples |
| Campos estruturados | O que é · Origem · Como calcula (mono) · Quando acontece · Observação | O que é · Como calcula (mono) · Exclui · Com período selecionado · Observação |
| `stopPropagation` | Sim (no gatilho) | Sim (gatilho e conteúdo) — para conviver com linhas clicáveis |
| Renderiza nada quando | — | `!explanation && !tooltip` |

Ambos são **clicáveis** (não hover) por decisão explícita: acessível no toque, bom para texto longo, e o texto nunca trunca (`whitespace-normal break-words`).

### 12.2 Inventário completo de ajudas no Dashboard

| # | Onde | Componente | Chave / título |
|---|---|---|---|
| 1 | Barra de filtros — período | `HelpTip` | `dash_periodo` |
| 2 | Barra — Carteiras | `HelpTip` | `carteira_multi` |
| 3 | Barra — Carteiras, com ≥2 selecionadas | `HelpTip` | `dash_vs_carteira` |
| 4 | Barra — Réguas (cobre Campanhas) | `HelpTip` | `dash_regua_campanha` |
| 5 | Barra — Filtros salvos | `HelpTip` | `filtro_salvo_multi` |
| 6 | Alerta "Filtro sem efeito de escopo" | `HelpTip side="bottom"` | `dash_escopo_vazio` |
| 7 | Alerta "Escopo parcialmente resolvido" | `HelpTip side="bottom"` | `dash_escopo_vazio` |
| 8-15 | Cada um dos 8 KPI Cards da Visão Executiva | `MetricExplanationPopover` | `explanation` estruturada (conteúdo integral em §5.1) |
| 16 | Funil — "Contar por" | `MetricExplanationPopover side="right"` | `METRIC_MODE_EXPLANATION` |
| 17-20 | Funil — cada um dos 4 níveis | `MetricExplanationPopover side="right"` | `FUNNEL_LEVEL_COPY[n].explanation` |
| 21 | Funil — seta entre etapas | `MetricExplanationPopover side="right"` | `stageArrowExplanation(from,to)` (dinâmico) |
| 22-23 | Funil — `% do nível 02` em cada desfecho | `MetricExplanationPopover side="left"` | `outcomeShareExplanation(...)` (dinâmico) |
| 24 | Funil — painel "Cobertura da base" | `MetricExplanationPopover side="top"` | `FUNNEL_PANEL_EXPLANATIONS.coverage` |
| 25 | Funil — painel "Por canal" | idem | `.channel` |
| 26 | Funil — painel "Conversão por canal" | idem | `.channelConversion` |
| 27 | Funil — painel "Pagamentos totais" | idem | `.organic` |
| 28 | Funil — resumo do rodapé | idem | `.overall` |
| 29 | Card "Acionamentos ao Longo do Tempo" | `HelpTip` **inline composto** | 4 tópicos empilhados: `dash_pagamento_eixos`, `dash_pago_torre`, `dash_pago_espontaneo`, `dash_cancelado_pago` — título "Ações e pagamentos neste painel" |
| 30 | Atribuição — card "Torre de Controle" | `HelpTip` inline | "Método de Atribuição Conservador" |
| 31 | Atribuição — card "Taxa de Conversão" | `HelpTip` inline | "Status Efetivos" |
| 32 | Operacional — 8 KPI Cards (4 canais + 4 custos) | `MetricExplanationPopover` via `tooltip` simples | textos em §6.2 e §6.3 |
| — | Legado (não renderizado) | `StepConversionTable` tem `HelpTip` na coluna "Acoes" | "Apenas acoes vinculadas a workflow steps. Broadcasts e acoes manuais nao sao incluidas." |

### 12.3 Conteúdo integral dos textos do funil

**`METRIC_MODE_EXPLANATION`** (seletor "Contar por")
- *O que é*: "Escolhe em qual unidade as porcentagens do funil são calculadas: contratos, títulos ou contatos."
- *Observação*: "Não é um filtro — nada sai da conta ao trocar. Os três números continuam visíveis em todos os níveis; o seletor só muda qual deles fica em destaque e qual entra nas porcentagens."

**Nível 01 · Base Elegível**
- *O que é*: "Os títulos que estão em carteiras de campanhas ativas e vencem no período escolhido. É o ponto de partida do funil — o denominador de 'quantos da minha base foram alcançados'."
- *Como calcula*: "títulos ativos, em carteira de campanha ativa, com vencimento no período — mantendo os que já receberam ação alguma vez"
- *Exclui*: "Títulos removidos da carteira. Pagos que NUNCA receberam ação (pagamento espontâneo). E os que passaram do maior dia de atraso configurado nas réguas ativas, porque nenhuma régua alcança mais eles."
- *Com período*: "Recorta por DATA DE VENCIMENTO — é o único nível que usa essa data. Os níveis 2 e 3 usam a data da ação e o nível 4 a data do pagamento."
- *Observação*: "Um título já pago continua aqui se recebeu ação algum dia: ele fez parte da base trabalhada. Em janelas curtas isso é a maioria do nível — na medição de 30 dias, 3.239 dos 5.439 títulos."

**Nível 02 · Contatados com Sucesso**
- *O que é*: "Quem recebeu ao menos uma ação entregue no período: WhatsApp, e-mail, RCS, SMS ou voz. Negativação e notificação também entram na conta."
- *Como calcula*: "ações com status Enviado, Interagiu, Solicitou Atendimento ou Em Atendimento — contando cada título, contrato e contato uma única vez"
- *Exclui*: "Ações de teste, ações que falharam e ações de títulos que foram removidos da carteira."
- *Com período*: "Recorta por DATA DA AÇÃO (o agendamento, ou a criação quando não houver agendamento) — não pela data de vencimento do nível 1."
- *Observação*: "É por isso que este número pode ficar MAIOR que o nível 1, com porcentagem acima de 100%: um título que vence em julho e foi acionado em agosto entra aqui e não lá. Use os dois números absolutos; a divisão entre eles ainda não é uma taxa de conversão."

**Nível 03 · Solicitaram Atendimento**
- *O que é*: "Quem respondeu a alguma cobrança — o sinal mais direto de engajamento. É o mesmo conjunto que a tela de Ações mostra como 'Solicitou Atendimento'."
- *Como calcula*: "ações com resposta registrada ou com status Solicitou Atendimento"
- *Exclui*: "Ações de teste e ações de títulos removidos da carteira."
- *Com período*: "Mesma data do nível 2: a data da ação."
- *Observação*: "É um DESFECHO da etapa 2, não uma etapa seguinte. Quem paga direto sem responder nunca passa por aqui — por isso este cartão fica ao lado dos pagamentos, e não antes deles."

**Nível 04 · Pagamentos Atribuídos**
- *O que é*: "Quem pagou e cujo pagamento foi creditado a uma ação da Torre, dentro da janela de atribuição de 48 horas antes do pagamento."
- *Como calcula*: "títulos pagos no período cuja atribuição aponta para uma ação da Torre"
- *Exclui*: "Pagamento espontâneo, que não tem ação atribuída — ele aparece no painel 'Pagamentos totais', ao abrir o resumo no rodapé."
- *Com período*: "Recorta por DATA DO PAGAMENTO."
- *Observação*: "Outro DESFECHO da etapa 2, paralelo ao 'Solicitaram Atendimento'. Não some os dois nem divida um pelo outro: são duas saídas diferentes da mesma etapa, e a mesma conta pode estar nos dois."

**`stageArrowExplanation(from, to)`** (dinâmico)
- *O que é*: "Quantos de '{from}' aparecem em '{to}', na unidade selecionada em 'Contar por'."
- *Como calcula*: `{to} ÷ {from}`
- *Com período*: "Os dois níveis recortam o período por datas DIFERENTES: '{from}' {eixo de from}, '{to}' {eixo de to}."
- *Observação*: "Por isso o valor pode passar de 100% sem que nada esteja quebrado: uma conta que vence fora do período mas foi acionada dentro dele entra no numerador e não no denominador. Trate como indicador de intensidade de acionamento, não como taxa de conversão — para 'quantos da base foram alcançados', compare os números absolutos dos dois níveis."

**`outcomeShareExplanation(outcome, stage)`** (dinâmico)
- *O que é*: "Quantos de '{stage}' terminaram em '{outcome}', na unidade selecionada em 'Contar por'."
- *Como calcula*: `{outcome} ÷ {stage}`
- *Observação*: "Os dois desfechos NÃO somam 100% e podem se sobrepor: a mesma conta pode responder e pagar, ou pagar sem nunca responder. Cada porcentagem se lê contra a etapa, nunca contra o outro desfecho."

**`FUNNEL_PANEL_EXPLANATIONS`**

| Chave | O que é | Como calcula | Observação |
|---|---|---|---|
| `coverage` | "Quanto a Base Elegível representa da carteira inteira no mesmo período." | `nível 1 ÷ todos os títulos ativos com vencimento no período` | "O denominador também recorta por data de vencimento. No eixo de contatos ele pode ficar MENOR que o nível 2, que conta por data da ação — não é erro, são recortes diferentes." |
| `channel` | "Quantos do nível receberam cada canal." | — | "NÃO é uma repartição do total: a mesma conta recebe e-mail E WhatsApp, então as porcentagens somam bem mais de 100% (na medição de 30 dias, 199%). Leia cada linha como 'cobertura deste canal', não como fatia de uma pizza." |
| `channelConversion` | "Pagamentos atribuídos a cada canal, medidos sobre a Base Elegível." | — | "O numerador recorta por data do pagamento e o denominador por data de vencimento — a mesma ressalva do funil vale aqui. Serve para comparar canais entre si, não como taxa absoluta." |
| `organic` | "Todos os pagamentos do período, separando o que a Torre pode reivindicar do que entrou sozinho." | `pagamentos com atribuição à Torre × pagamentos sem ação atribuída (espontâneos)` | "Este painel é o único que NÃO segue o filtro de campanha ou régua: pagamento espontâneo não tem ação atribuída, logo não tem campanha, e filtrar zeraria a fatia espontânea inteira." |
| `overall` | "Quantos da Base Elegível terminaram em pagamento atribuído à Torre." | `nível 4 ÷ nível 1` | "Numerador e denominador usam datas diferentes (pagamento × vencimento), então trate como ordem de grandeza, não como taxa exata." |

### 12.4 Conteúdo dos textos de pagamento (card de Acionamentos)

| Tópico | Título | Corpo |
|---|---|---|
| `dash_pagamento_eixos` | "Por que são duas barras" | "Ação e pagamento são eventos diferentes, em datas diferentes: a ação entra no dia em que foi enviada, o pagamento no dia em que foi pago. Somar os dois na mesma coluna não significaria nada — por isso cada família tem sua barra e sua porcentagem. O pagamento do dia aparece após a classificação automática, que roda a cada hora." |
| `dash_pago_torre` | "Pago (Torre)" | "Título pago que o sistema conseguiu creditar a uma ação de cobrança: houve envio nos 2 dias anteriores ao dia do pagamento. O crédito é conservador — hoje, pagamento no MESMO dia do envio não entra nessa conta, e cai em 'Pago (espontâneo)'." |
| `dash_pago_espontaneo` | "Pago (espontâneo)" | "Título pago sem ação da Torre naquela janela: o cliente pagou por conta própria. Quando o pagamento veio depois de um contato humano (não automatizado), o detalhe mostra 'Pago (contato manual)' dentro desta mesma fatia." |
| `dash_cancelado_pago` | "Cancelado (Pago)" | "NÃO é um pagamento: é uma AÇÃO que foi cancelada porque o título já havia sido pago antes do envio. Por isso ela conta na barra de Ações (em 'Cancelado'), nunca na de Pagamentos — senão o mesmo pagamento seria contado duas vezes." |

### 12.5 Ajudas da aba Atribuição (inline)

**"Método de Atribuição Conservador"** (card Torre de Controle)
> "Pagamento realizado até **2 dias** após a última interação efetiva (delivered, sent, executed, replied)."
> "Este critério rigoroso garante que apenas conversões com alta probabilidade de causalidade sejam atribuídas à Torre."

**"Status Efetivos"** (card Taxa de Conversão)
> "Apenas ações com status de sucesso:" — lista com marcadores: `delivered (entregue/lido)`, `sent (enviado)`, `executed (executado)`, `replied (respondido)`.

### 12.6 Modais e overlays

**Não existe nenhum `Dialog`/modal nesta tela.** Todas as camadas sobrepostas são:

| Overlay | Tipo | Gatilho | Fechamento |
|---|---|---|---|
| Popover do calendário (período custom) | `Popover` com `Calendar` 2 meses | clique no botão do intervalo | botão **Cancelar**, botão **Aplicar**, ou clique fora |
| Popovers dos multi-selects (4) | `Popover` + `Command` | clique no trigger | clique fora / Esc |
| Popover "Métricas (n)" da tabela de steps | `Popover` com checkboxes | clique no botão | clique fora / Esc |
| Popovers de ajuda (32 instâncias) | `Popover` | clique no `?` | clique fora / Esc |
| Tooltips (cascata, aging/saúde, status, heatmap) | `Tooltip` ou `title` nativo | hover | sair do hover |
| Dropdown de exportação | `DropdownMenu` | clique em "Exportar" | seleção / clique fora |
| Overlay de refetch | `div` decorativo | refetch com dado em tela | fim do fetch |
| Toasts | `useToast` | recalcular atribuição, exportar | auto / manual |

---

## 13. Estados da tela

### 13.1 Estados globais (`DashboardPage`)

| Estado | Condição | Render |
|---|---|---|
| **Carregando organização** | `orgLoading` | `<FullPageLoading message="Carregando organização..." />` — ocupa a tela inteira; nada do dashboard é montado |
| **Sem organização** | `!currentOrg` | `<EmptyState icon={AlertTriangle} title="Nenhuma organização encontrada" description="Você não está associado a nenhuma organização." />` |
| **Sem permissão para uma aba** | não-owner | Os `TabsTrigger` das 4 abas owner simplesmente **não são renderizados** (não há aba desabilitada nem mensagem). `?tab=ai` numa sessão não-owner cai silenciosamente em `executive` |
| **Refresh manual** | `isRefreshing` | `RefreshTopBar` ativa + botão girando/desabilitado. Conteúdo **não** esmaece |
| **Refetch de conteúdo** | `dashboardRefetching > 0 && !isRefreshing` | Overlay `bg-background/60 backdrop-blur-[1px]` + `Loader2` girando; conteúdo em `opacity-60`; `aria-busy`. **Interação preservada** |
| **Primeira carga de uma aba** | queries sem `data` | Cada painel mostra o **seu próprio skeleton**. Não há skeleton de página inteira |

### 13.2 Matriz de estados por painel

Legenda: ✅ = estado dedicado presente · ⚠️ = ausente (a falha cai no estado vazio)

| Painel | Loading | Erro + retry | Vazio | Texto do vazio |
|---|---|---|---|---|
| Faixa de KPIs (Executiva) | ✅ `KPIGridSkeleton count=8` | ✅ bloco + "Tentar novamente" | — | — |
| KPI "Media Atraso Efetivo" | ✅ skeleton do card | ⚠️ | ⚠️ mostra `0 dias` | — |
| Evolução Mensal | ✅ `ChartSkeleton 250` | ⚠️ | ✅ | "Sem dados para exibir" |
| Tendência de Recuperação | ✅ | ⚠️ | ✅ | "Sem dados para exibir" |
| Funil de Cobrança | ✅ 4 blocos pulse | ✅ (**precedência sobre vazio**) | ✅ | "Sem dados para exibir" |
| Aging | ✅ 4 skeletons | ⚠️ | ✅ | "Nenhum titulo em atraso" |
| Saúde da Carteira | ✅ 4 skeletons | ⚠️ | ✅ | "Sem dados de pagamento" |
| Status de Entrega | ✅ 5 barras | ⚠️ | ✅ (card inteiro some se `statusBreakdown` vazio) | "Nenhuma acao no periodo" |
| Freq. de Acionamento (tabela) | ✅ 3 barras | ✅ | ✅ | "Sem dados de frequência" |
| Freq. de Acionamento (série) | ✅ | ✅ | ✅ | "Sem dados de frequência no período" |
| Acionamentos ao Longo do Tempo | ✅ `ChartSkeleton 300` | ✅ | ✅ | "Sem acoes no periodo" |
| Eficiência por Step — gráfico | ✅ | ✅ | ✅ | "Sem evolução para exibir no período e na granularidade escolhidos." |
| Eficiência por Step — tabela | ✅ | ✅ | ✅ | "Nenhum dado para o recorte selecionado." |
| Funil operacional | ✅ 6 barras | ⚠️ | ✅ | "Sem dados para exibir" |
| KPIs de canal (Operacional) | ✅ skeleton do card | ⚠️ | ⚠️ mostra `0%` | — |
| Custos | ✅ | ⚠️ | ⚠️ mostra `R$ 0,00` | — |
| Motivos de falha | ✅ 5 linhas | ⚠️ | ✅ (positivo) | "Nenhuma falha registrada no período" |
| Atribuição (aba inteira) | ✅ 3 cards skeleton | ⚠️ | ✅ | "Nenhum dado de atribuição disponível" |
| Comparativo de Réguas | ✅ 5 linhas | ⚠️ | ✅ | "Nenhuma régua com dados no período" |
| Comparativo de Campanhas | ✅ 5 linhas | ⚠️ | ✅ | "Nenhuma campanha com dados no período" |
| Mapa de Calor | ✅ grade skeleton | ⚠️ | ⚠️ **grade toda cinza** | — |
| Opções da barra de filtros | ⚠️ (sem indicador) | ✅ `role="alert"` acima da barra | — | "Não foi possível carregar todas as opções de filtro. Atualize a página." |
| Escopo régua/campanha | — | ✅ 3 alertas (§3.7) | ✅ (alerta âmbar) | ver §3.7 |
| Nome de um chip | ✅ `"carregando…"` | ✅ fallback `#a1b2c3d4` | — | — |

### 13.3 Carregamento serializado (fila das RPCs pesadas)

Enquanto o **Funil de Cobrança** está buscando, os painéis **Eficiência por Step**, **Acionamentos ao Longo do Tempo** e **Freq. de Acionamento (série)** exibem **skeleton**, mesmo sem fetch em voo — porque `heavyRpcsEnabled = !funnelFetching` e a UI trata "esperando a vez na fila" como carregando.

Consequência visível para o usuário: a Visão Executiva carrega **em duas ondas** — KPIs + gráficos mensais + funil primeiro; os três painéis pesados depois. É intencional (ver §4.4). Em org grande a segunda onda pode demorar dezenas de segundos.

---

## 14. Fluxos de uso passo a passo

### 14.1 Fluxo canônico do gestor (roteiro do guia de negócio do app)

1. **Comece pelo período** — "Escolha a janela de análise. Para acompanhar o mês, use 'Este mês'; para uma visão histórica, 'Todo período'."
2. **Leia os KPIs do topo** — "Carteira Total (e a Original, de face), Em Aberto — com o detalhe em Vencida e A Vencer —, Paga, Taxa de Recuperação e Média de Atraso dão o diagnóstico imediato."
3. **Desça ao funil** — "Veja onde a jornada perde força — entre acionar e responder, ou entre responder e pagar."
4. **Recorte quando precisar** — "Aplique carteira, régua ou campanha para isolar uma frente específica. Use Limpar para voltar ao todo."
5. **Aprofunde (Owner)** — "Use Atribuição para medir o retorno da Torre, Eficiência Operacional para custos e falhas, e as demais abas para comparar réguas, campanhas e a IA."

### 14.2 Fluxo: analisar o desempenho de uma campanha específica

1. Barra de filtros → dropdown **Carteiras** → seleciona a carteira da campanha (opcional; ativa a cascata).
2. Dropdown **Campanhas** → busca pelo nome → marca a campanha (a lista já vem podada pelo passo 1, com o ícone `Link2`).
3. A URL passa a ter `?portfolios=…&campaigns=…`; aparecem os chips e o conteúdo esmaece durante o refetch.
4. **Se um alerta âmbar aparecer** ("Filtro sem efeito de escopo"), a campanha não tem carteira associada → o painel está mostrando a base inteira; voltar e escolher uma carteira.
5. Na Visão Executiva, ler o funil: **N1 continua sendo o universo elegível**; N2/N3/N4 passam a ser só o que aquela campanha fez.
6. Expandir **"Ver por canal e pagamentos totais"** no rodapé do funil → notar o aviso de que "Pagamentos totais" **não segue o filtro de campanha**.
7. (Owner) Ir à aba **Performance de Cobranças** → linha da campanha na tabela → comparar Entrega/Resposta/Conversão com as demais e com o breakdown por canal.

### 14.3 Fluxo: investigar queda na entrega

1. Período = "Últimos 30 dias".
2. Aba **Eficiência Operacional** → ler os 4 cartões de Taxa de Interação por canal; o canal fora do limiar fica amarelo.
3. Rolar até **Principais Motivos de Falha** → ler o #1 e sua participação (badge vermelho se >30%).
4. Voltar à **Visão Executiva** → sidebar **Status de Entrega** → conferir a fatia de "Falha Temporária" vs "Falha Definitiva" (tooltip explica a diferença).
5. Card **Acionamentos ao Longo do Tempo** → alternar para `Semana` → localizar o período em que a fatia vermelha cresce.
6. Card **Eficiência por Step** → seletor de canal = o canal afetado → ver se a queda está concentrada numa faixa de atraso.

### 14.4 Fluxo: medir o retorno da Torre num mês fechado

1. Período = **Mês passado**.
2. Aba **Atribuição** (owner).
3. Ler os três cards (Torre / Manual / Orgânico) e o **ROI da Automação** no Resumo do Período.
4. Se os números parecerem defasados, clicar em **Recalcular Atribuição** e aguardar o toast com a quebra (`N títulos: X torre, Y manual, Z orgânico`).
5. ⚠️ Lembrar que **esta aba ignora carteira/régua/campanha** — apenas o intervalo de datas.

### 14.5 Fluxo: comparar o desempenho de uma faixa de acionamento entre períodos

1. Visão Executiva → card **Eficiência por Step**.
2. Seletor de granularidade → `Evolucao por semana` (liga a 2ª consulta e revela o gráfico de linhas).
3. No gráfico, escolher a métrica (`Conversões`, por exemplo) na fileira de botões.
4. Ler a linha da faixa desejada — "comparar dois pontos da mesma linha é a comparação entre períodos".
5. Se a faixa não estiver no gráfico (limite de 6 séries), o texto avisa quantas ficaram fora → continuar na tabela abaixo.
6. Na tabela dinâmica, trocar a hierarquia para `Período → faixa`, expandir o período e ler os detalhes.
7. Abrir **"Ver os dados do gráfico em tabela"** se precisar dos números exatos ou imprimir.

### 14.6 Fluxo: abrir um recorte compartilhado por link

1. Colega envia a URL completa (`/?tab=workflows&period=30d&portfolios=uuid1,uuid2&portfolios_logic=and`).
2. Ao abrir: a aba correta é restaurada; os filtros são lidos da URL; os chips aparecem.
3. Se um id selecionado **não está nas listas dos dropdowns** (carteira além do 100º item, campanha pausada), o chip busca o nome por id — mostra `"carregando…"` e depois o nome. A seleção **não é apagada**.
4. Se o link tiver uma aba owner-only e o usuário não for owner, a tela abre em **Visão Executiva** sem erro.
5. **Voltar** no navegador desfaz a interação inteira (cada troca de aba/filtro é uma entrada só).

### 14.7 Fluxo: uso no mobile

1. A barra de filtros vem **colapsada**; o botão mostra "Filtros do Dashboard" + badge com o nº de filtros ativos.
2. Toque abre o painel; os seletores viram popovers de largura do campo, com busca.
3. A faixa de abas rola horizontalmente.
4. O subtítulo "Business Intelligence - {org}" **some** (`hidden sm:block`).
5. Todas as ajudas `?` funcionam por toque (são popovers clicáveis, não tooltips de hover).

---

## 15. Responsividade, impressão/PDF e acessibilidade

### 15.1 Breakpoints e comportamento responsivo

| Breakpoint | Elemento | Comportamento |
|---|---|---|
| `< 640px` (`sm`) | Header | `px-4` (vs `sm:px-6`); `h1` em `text-xl` (vs `2xl`); subtítulo **oculto** |
| `< 640px` | Conteúdo das abas | `p-4` (vs `sm:p-6`) |
| `< 768px` (`md`) | Barra de filtros | Colapsada em `MobileCollapsibleFilters` (detecta via `matchMedia("(max-width: 767px)")`) |
| `< 768px` | Grid de KPIs | 1 coluna (base) → `md:grid-cols-2` → `lg:grid-cols-4` |
| `< 768px` | Evolução/Tendência | Empilham (`md:grid-cols-2`) |
| `< 1024px` (`lg`) | Funil + sidebar | Empilham; acima de `lg`, `grid-cols-5` com 3/2 e `items-start` |
| `< 640px` | Desfechos do funil | Empilham (`sm:grid-cols-2`) |
| Qualquer | Faixa de abas | `overflow-x-auto` |
| Qualquer | Barra de filtros | `flex-wrap` nos controles |
| Qualquer | Tabelas de comparativo | Não têm wrapper de scroll horizontal explícito — ⚠️ podem estourar no mobile |
| Qualquer | `StepDynamicTable` | `min-w-max` + container com scroll; `max-h-[520px]` com header sticky e footer sticky |
| Qualquer | `StepConversionTable` (legado) | `overflow-x-auto` |
| Qualquer | Popovers de multi-select | `w-[var(--radix-popover-trigger-width)] min-w-[240px]`, `max-h` = espaço disponível na viewport, labels com `break-words` |
| Qualquer | Popovers de ajuda | `w-80 max-w-[90vw]` |
| Qualquer | Gráficos recharts | `ResponsiveContainer width="100%"` com **alturas fixas** (140 / 250 / 280 / 300 px) |

### 15.2 Impressão / PDF

- **A tela não tem folha de estilo de impressão própria.** Imprimir o Dashboard direto do navegador produz resultado não otimizado (sticky, scroll interno, overlays).
- O único caminho de PDF é o `exportToPDF` do `ExportButton` — que **não está renderizado** (§10): ele monta um HTML separado com CSS próprio (`@media print`, `page-break-inside: avoid`, `page-break-before` entre seções) e chama `window.print()`.
- O `<details>` **"Ver os dados do gráfico em tabela"** do `StepEvolutionChart` existe explicitamente porque "o gráfico sozinho não é legível por leitor de tela nem imprimível" — é o único painel com alternativa textual.
- ⚠️ A confirmar: se o redesign deve introduzir um modo "imprimir esta visão" nativo.

### 15.3 Acessibilidade — o que já existe

| Recurso | Onde |
|---|---|
| Landmarks | `<article aria-label="Dashboard de Business Intelligence">`, `<header>`, `<nav aria-label="Filtros do dashboard">`, `<section aria-label="Conteudo do dashboard">` |
| `aria-busy` | `<section>` durante refetch; `RefreshButton`; `RefreshableSection` |
| `role="progressbar"` + `aria-label="Atualizando"` | `RefreshTopBar` |
| `aria-hidden="true"` | Overlay de refetch (decorativo) |
| `role="alert"` | Mensagem de falha das opções de filtro |
| `aria-label` em abas | `<TabsList aria-label="Abas do dashboard">` |
| `aria-pressed` | `MetricToggle` do funil; botões de métrica do `StepEvolutionChart` |
| `role="group" aria-label="Contar por"` | `MetricToggle` do funil |
| `aria-expanded` | "Ver detalhes" dos níveis do funil; "Ver por canal…"; grupos da tabela dinâmica |
| `aria-label` nos gatilhos de ajuda | `Ajuda: {título}` / `Como calculamos {título}` |
| `aria-label="Remover filtro"` | ✕ de cada chip |
| `role="combobox"` + `aria-expanded` | Trigger de todo `FilterMultiSelect` |
| Foco visível | `focus-visible:ring-2 focus-visible:ring-ring` nos botões de expandir, toggles e gatilhos de ajuda |
| Botão real em vez de div clicável | Comentário explícito no `CollectionFunnel`: "BOTÃO, não div com onClick (antes o cartão inteiro era clicável e inacessível por teclado)" |
| Tabela acessível | `<caption class="sr-only">`, `scope="col"`, `scope="row"` no `<details>` do `StepEvolutionChart` |
| Não depender só de cor | Paleta do `StepEvolutionChart` varia **traço** (`strokeDasharray`) além da cor |
| `tabular-nums` | Todos os números em tabelas e barras — alinhamento consistente |
| Ajuda clicável (não hover) | Decisão explícita do `HelpTip` para funcionar no toque |
| `title` de fallback | `HeatmapChart` (célula), barras do `OrganicBreakdownPanel` |

### 15.4 Acessibilidade — lacunas observadas

| Lacuna | Onde |
|---|---|
| Gráficos recharts sem alternativa textual | Evolução Mensal, Tendência, Acionamentos, Freq. Trend, Funil operacional — só o `StepEvolutionChart` tem `<details>` com tabela |
| `HeatmapChart` usa apenas `title` nativo | Sem `role`/`aria-label` por célula; sem navegação por teclado; sem tabela equivalente |
| `AgingChart` / `PaymentHealthChart` | Barras são `div`s sem `role="img"`/`aria-label`; o dado está no texto adjacente (mitigação parcial) |
| Contraste de escala | `HeatmapChart` usa 6 níveis de opacidade da mesma cor — indistinguíveis para daltonismo severo, sem padrão alternativo |
| Legenda do `ActionsTimelineChart` | É visual (quadradinhos + texto); `aria-hidden` nos quadradinhos, mas o gráfico não anuncia as séries |
| Sem `skip link` | Não há atalho para pular a barra de filtros |
| Toggles de granularidade | `<button>` sem `aria-pressed` no `GranularityToggle` e no `AgingMetricToggle` (o `MetricToggle` do funil tem) |

---

## 16. Dores e oportunidades para o redesign

### 16.1 Inconsistências estruturais (alta prioridade)

| # | Problema | Evidência |
|---|---|---|
| 1 | **Dois "Funis de Cobrança" com o mesmo nome e leituras diferentes.** Visão Executiva usa `CollectionFunnel` (4 níveis, etapas × desfechos, eixos de data declarados, `?` em tudo). Operacional usa `FunnelChart` (7 estágios, barras horizontais, taxas encadeadas, **sem nenhuma ressalva**) | `ExecutiveTab.tsx` vs `OperationalTab.tsx` |
| 2 | **A aba Atribuição ignora todos os filtros de escopo.** Só o intervalo de datas é repassado. A barra de filtros fica visível e sugere que carteira/régua/campanha/filtro salvo se aplicam — não se aplicam | `AttributionTab.tsx` linhas 54-57 |
| 3 | **A exportação está morta.** `ExportButton` implementado, exportado no índice, e comentado no import da página. O Dashboard não tem como exportar nada | `DashboardPage.tsx:14` |
| 4 | **Cobertura de estados de erro é irregular.** 9 painéis têm erro dedicado com retry; 12 caem no estado vazio quando falham (Aging, Saúde, Evolução Mensal, Tendência, Funil operacional, custos, motivos de falha, réguas, campanhas, heatmap, Atribuição) — exatamente o problema que o `spec-08` corrigiu nos outros | §13.2 |
| 5 | **A faixa de variação (▲/▼ %) do `KPICard` nunca é usada.** Nenhum KPI passa `previousValue`/`currentValue` — não há comparação com o período anterior em lugar nenhum da tela | `KPICard.tsx` + todos os `<KPICard>` |
| 6 | **Três componentes de ajuda com layouts distintos** (`HelpTip` estruturado, `HelpTip` inline, `MetricExplanationPopover`) coexistem, com campos diferentes ("Origem"/"Quando acontece" vs "Exclui"/"Com período selecionado") | §12.1 |
| 7 | **Dois vocabulários visuais para barras de proporção.** Aging/Saúde/Status usam classes Tailwind (`bg-success`, `bg-warning`); funil/timeline/step usam hex (`#22c55e`, `#3b82f6`). O mesmo conceito ("sucesso") tem duas cores dependendo do painel | `AgingChart` vs `CollectionFunnel` |
| 8 | **`StepConversionTable` é código morto** — tabela completa, com padrões visuais valiosos (pílula por faixa de atraso, destaque da melhor taxa), não renderizada | §5.10.3 |
| 9 | **Os alertas de escopo são irmãos dos `TabsContent`**, aparecendo depois do conteúdo de Atribuição no DOM e visíveis em qualquer aba — posicionamento acidental | `DashboardPage.tsx` `GlobalFilteredTabs` |

### 16.2 Dores de leitura (o que confunde o gestor)

| # | Dor | Mitigação atual |
|---|---|---|
| 10 | **Porcentagens do funil passam de 100%** (já apareceu 118,9% e até 800% em recortes estreitos), porque os níveis usam eixos de data diferentes | Cada nível declara o `dateAxis` visível; `?` em cada porcentagem; aviso inline "acima de 100% — ver '?'". **É um paliativo declarado — a correção é decisão de produto com card próprio** |
| 11 | **"Pagamentos totais" não segue o filtro de campanha**, ficando maior que o nível 4 do funil logo acima | Aviso textual no painel + sufixo "· toda a carteira" no título |
| 12 | **Painéis "Por canal" somam mais de 100%** (a mesma conta recebe e-mail e WhatsApp) | Frase de advertência fixa + `?` |
| 13 | **Taxa de Recuperação não fecha com Pago ÷ (Pago + Em Aberto)** — o denominador é o valor atual total | Explicado no `?` |
| 14 | **A Visão Executiva carrega em duas ondas**, com skeleton persistente nos 3 painéis pesados | Intencional (serialização); mas o usuário não sabe *por quê* — não há mensagem de "aguardando a consulta principal" |
| 15 | **Custos zerados por falta de configuração são indistinguíveis de custo real zero** | Só um aviso genérico no guia ("É estimativa, não fatura") |
| 16 | **O heatmap sem dados renderiza uma grade toda cinza**, que parece "tudo zero" e não "sem dados" | Nenhuma |
| 17 | **Mesmos limiares de cor repetidos em 3 lugares** (entrega >90/>70, resposta >15/>8, conversão >5/>2) sem legenda visível em nenhum | Nenhuma |

### 16.3 Oportunidades de estado e persistência

| # | Oportunidade |
|---|---|
| 18 | **Vários estados locais não vão para a URL e se perdem no reload / não são compartilháveis**: `metricMode` do funil, `agingMetricMode`, `healthMetricMode`, `timelineGranularity`, `freqGranularity`, `stepChannel`, `stepGranularity`, hierarquia e métricas visíveis da tabela dinâmica, nível expandido do funil. Um link do funil "Contar por Contatos" é impossível hoje |
| 19 | **`entityKind` não vira chip** e não entra no `activeFilterCount` do badge mobile — um recorte relevante fica invisível |
| 20 | **Não há `localStorage` para preferências** (unidade preferida, granularidade padrão, colunas da tabela) — o usuário reconfigura a cada visita |
| 21 | **Tabelas sem ordenação, sem clique, sem drill-down**: réguas, campanhas, motivos de falha, atribuição por canal. Nenhum caminho de "ver as ações desta régua" |
| 22 | **Vários limites silenciosos**: dropdowns com `pageSize: 100`, campanhas só `status=active`, heatmap só 6h-21h, gráfico de step com 6 séries (este último **avisa**; os demais, não) |

### 16.4 Oportunidades de acessibilidade e mídia

| # | Oportunidade |
|---|---|
| 23 | Estender o padrão `<details>` "Ver os dados do gráfico em tabela" (hoje só no `StepEvolutionChart`) para **todos** os gráficos |
| 24 | Dar `role="img"` + `aria-label` resumido às barras CSS (Aging, Saúde, Status, painéis do funil) |
| 25 | Tornar o heatmap navegável por teclado e adicionar padrão/textura além da opacidade |
| 26 | Adicionar `aria-pressed` aos toggles que não têm (`GranularityToggle`, `AgingMetricToggle`) |
| 27 | Criar uma folha de impressão nativa da tela (hoje só existe o HTML paralelo do export desligado) |
| 28 | Garantir scroll horizontal explícito nas tabelas de comparativo (réguas/campanhas) no mobile |

### 16.5 Restrições que o redesign NÃO pode quebrar

> Travas de performance e de significado documentadas no código com histórico de incidente em produção.

| # | Restrição | Consequência de quebrar |
|---|---|---|
| A | **Painel novo que leia `{org}.actions` entra na fila `heavyRpcsEnabled`** (não paralelizar as consultas pesadas da Visão Executiva) | Os 4 RPCs se evictam no `shared_buffers` de 512 MB e estouram o `statement_timeout` juntos. Regra 33: isso **degrada o pipeline de ENVIO**, não só o dashboard (incidente de 17/08/2026: login de produção fora por ~30 min) |
| B | **O overlay de refetch deve continuar `pointer-events-none`** | Lentidão de backend volta a virar "tela travada" — nem trocar de aba funcionava |
| C | **Erro nunca pode renderizar estado vazio** (erro tem precedência) | Timeout vira "organização sem carteira"; o mesmo fetch já foi exibido como erro num painel e como vazio em outro na mesma tela |
| D | **A poda de filtros só remove o comprovadamente inválido** | Clicar numa carteira durante o carregamento apagava régua e campanha selecionadas; campanha pausada ou vinda de link sumia em silêncio |
| E | **Chips resolvem o nome por id quando o item não está na lista** | Volta o chip `"Carteira: "` sem nome, lido como filtro corrompido |
| F | **Escritas em cascata de filtro em UMA operação de URL** | Updates se perdem (last-write-wins do snapshot stale) e o histórico enche de estados intermediários |
| G | **A aba IA não recebe filtros globais e desmonta a barra** | A barra visível ali é enganosa (a IA nunca consumiu esses filtros); e montar `GlobalFilteredTabs` dispara fetches inúteis |
| H | **Etapas × Desfechos separados; sem seta entre desfechos** | Volta a pílula de 266,7% que "não descreve nada" |
| I | **Ação e pagamento em pilhas separadas no timeline** | O mesmo pagamento é contado duas vezes (como ação `Cancelado (Pago)` e como título pago) e a porcentagem do tooltip perde significado |
| J | **Cada nível do funil declara seu eixo de data** | A tela volta a publicar "118,9% de conversão" sem pista de que numerador e denominador vêm de conjuntos que não se contêm |
| K | **A granularidade da série de frequência é independente da do timeline** | Trocar uma altera a outra e surpreende o usuário |
| L | **"Consolidado" é o padrão da Eficiência por Step** | A 2ª consulta (não index-only; com filtro de régua o scan volta ao heap) passa a rodar sempre, dobrando a leitura mais cara da aba |

---

## Apêndice A · Mapa rápido componente → arquivo

| Elemento da UI | Arquivo |
|---|---|
| Página, abas, refresh global, alertas de escopo | `src/pages/DashboardPage.tsx` |
| Barra de filtros | `src/components/dashboard/DashboardFiltersBar.tsx` |
| Estado dos filtros na URL, presets de data | `src/hooks/useDashboardFilters.ts` |
| Régua/campanha → carteiras | `src/hooks/useDashboardScope.ts` |
| Nomes de chips ausentes | `src/hooks/useDashboardSelectionLabels.ts` |
| Poda de seleções dependentes | `src/components/dashboard/dashboard-filter-prune.ts` |
| Multi-select genérico + E/OU | `src/components/portfolio/filters/FilterMultiSelect.tsx` |
| Presets Carteiras / Filtros salvos | `PortfolioMultiSelect.tsx` / `FilterDefinitionMultiSelect.tsx` |
| Chips ativos + Limpar todos | `src/components/portfolio/filters/ActiveFilterChips.tsx` |
| Colapso mobile da barra | `src/components/ui/mobile-collapsible-filters.tsx` |
| Cartão de KPI + skeleton do grid | `src/components/dashboard/KPICard.tsx` |
| Popover de explicação de métrica | `src/components/common/MetricExplanationPopover.tsx` |
| Ajuda contextual `?` | `src/components/common/HelpTip.tsx` + `src/lib/filters/help-copy.ts` |
| Barra de progresso / botão / seção de refresh | `src/components/common/RefreshTopBar.tsx`, `RefreshButton.tsx`, `RefreshableSection.tsx` |
| Aba Visão Executiva | `src/components/dashboard/tabs/ExecutiveTab.tsx` |
| Funil principal + copy | `charts/CollectionFunnel.tsx` + `charts/collection-funnel-copy.ts` |
| Aging | `charts/AgingChart.tsx` |
| Saúde da Carteira | `charts/PaymentHealthChart.tsx` + `src/hooks/usePaymentHealth.ts` |
| Status de Entrega | `charts/ErrorSummaryCard.tsx` (`ActionStatusBreakdown`) |
| Frequência de acionamento | `charts/ActionFrequencyTable.tsx` + `charts/ActionFrequencyTrend.tsx` |
| Timeline de acionamentos | `charts/ActionsTimelineChart.tsx` |
| Eficiência por step | `charts/StepEvolutionChart.tsx` + `charts/StepDynamicTable.tsx` (+ legado `StepConversionTable.tsx`) |
| Aba Eficiência Operacional | `tabs/OperationalTab.tsx` + `charts/FunnelChart.tsx` |
| Aba Atribuição | `tabs/AttributionTab.tsx` + `src/hooks/usePaymentAttribution.ts` |
| Aba Performance de Cobranças | `tabs/WorkflowsTab.tsx` + `charts/HeatmapChart.tsx` |
| Aba Performance da IA | `tabs/AITab.tsx` → `src/components/ia/AgentMetrics.tsx` + `DashboardAgentSelector.tsx` |
| Estado da aba IA na URL | `src/hooks/useAIDashboardFilters.ts` + `src/lib/ai-dashboard-url.ts` |
| Exportação (desligada) | `src/components/dashboard/ExportButton.tsx` + `src/lib/dashboard-export.ts` |
| Guia de negócio dentro do app | `src/pages/central-docs/negocio/data/dashboard.ts` |

## Apêndice B · Itens marcados "A confirmar"

1. ⚠️ **Exportação**: reativar o `ExportButton` no Dashboard ou tratá-la como descontinuada? O código está íntegro e usa um shape legado de KPIs que precisaria ser realinhado.
2. ⚠️ **Aba Atribuição vs filtros globais**: é intencional que carteira/régua/campanha/filtro salvo não afetem a aba, ou é uma lacuna? Hoje a barra fica visível e sugere o contrário.
3. ⚠️ **Modo de impressão nativo**: deve existir um "imprimir esta visão" do Dashboard, ou o caminho continua sendo o HTML paralelo do export?
4. ⚠️ **Faixa de variação do `KPICard`**: a comparação com período anterior está prevista no componente mas nunca foi alimentada. É requisito do redesign?
5. ⚠️ **`StepConversionTable`**: remover de vez ou recuperar seus padrões visuais (pílula por faixa de atraso, destaque da melhor taxa) no redesign?
6. ⚠️ **Prop `periodOnly` da `DashboardFiltersBar`**: existe e não é usada por esta tela. Verificar se algum outro consumidor depende dela antes de removê-la no redesign.
</content>
</invoke>
