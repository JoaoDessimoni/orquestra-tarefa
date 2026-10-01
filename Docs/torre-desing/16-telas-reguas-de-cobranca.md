# 16 · Telas de Réguas de Cobrança

> Documento de inventário funcional do frontend **atual** da Torre de Controle (SaaS multi-tenant de cobrança da Finza), escrito para que um designer possa redesenhar a interface **sem perder nenhuma funcionalidade**.
>
> Escopo deste documento: a **lista de Réguas de Cobrança** (`/reguas-cobranca`) e o **Editor de Régua em tela cheia** (`/reguas-cobranca/:id/editor`), incluindo timeline de passos, wizard de passo, formulários por tipo de passo, assistente de mensagem com IA, versionamento, auditoria, vínculo com carteiras e integração em massa.
>
> Todo conteúdo foi extraído por leitura direta do código-fonte do repositório `cobranca-finza`. Onde o código não decide, o texto marca **⚠️ A confirmar**.
>
> Data da leitura: 2026-09-17.

---

## 0. Resumo do domínio

### 0.1 Telas e rotas

| Tela | Rota | Arquivo-fonte | Permissão | Layout |
|---|---|---|---|---|
| Lista de Réguas de Cobrança | `/reguas-cobranca` | `src/pages/ReguasCobrancaPage.tsx` | Leitura: qualquer papel que acesse a rota. Escrita: `workflows:write` (botão "Nova Régua", "Editar", "Duplicar", switch de ativação). Exclusão: `workflows:delete`. | Layout padrão do app (sidebar + header do shell). Conteúdo: título + ações, card de filtros, grid de cards **ou** tabela, paginação. |
| Editor de Régua (tela cheia) | `/reguas-cobranca/:id/editor` | `src/pages/ReguasCobrancaEditorPage.tsx` | Leitura livre; escrita gated por `workflows:write` (toggle da régua, toggle/edição/exclusão/duplicação de passo, reorder, publicar, trocar integração, configurações). | **Tela cheia**: `h-screen flex flex-col overflow-hidden` — header próprio de 64px (`h-16`) e `<main>` rolável ocupando o resto. Não usa o layout com sidebar. |
| Editor de Broadcast (fora deste documento) | `/broadcasts/:id/editor` | — | — | Rota-irmã: quando a régua é do tipo `broadcast` ("Pontual"), tanto `handleOpenEditor` na lista quanto o redirect pós-criação do `ReguaDialog` mandam para cá, **não** para o editor de régua sequencial. |

### 0.2 Superfícies flutuantes do domínio (modais, sheets, painéis)

| Superfície | Componente | Onde é montada | Tipo |
|---|---|---|---|
| Criar/Editar régua | `ReguaDialog` | Lista (`/reguas-cobranca`) e Editor (botão "Configurações") | `Dialog` 95vw × 95vh |
| Wizard de passo — criar | `AddStepDialog` → `StepWizard` (`mode="create"`) | Editor | `Dialog` 95vw × 95vh |
| Wizard de passo — editar | `StepConfigSheet` → `StepWizard` (`mode="edit"`) | Editor | `Dialog` 95vw × 95vh |
| Editar faixa da cauda (lote) | `EditCaudaDialog` | Editor → cabeçalho do grupo de cauda | `Dialog` `max-w-lg` |
| Confirmar exclusão de passo | `AlertDialog` interno do `StepCard` | Editor → card de passo | `AlertDialog` |
| Confirmar desativação de régua com campanhas dependentes | `AlertDialog` na `ReguasCobrancaPage` | Lista | `AlertDialog` |
| Publicar versão | `PublishDialog` | Editor | `Dialog` |
| Histórico de versões | `VersionHistoryPanel` | Editor | painel/sheet lateral |
| Logs de auditoria | `AuditLogPanel` | Editor | painel/sheet lateral |
| Trocar integração em massa | `BulkIntegrationDialog` | Editor | `Dialog` |

### 0.3 Arquivos-fonte por área

| Área | Arquivos |
|---|---|
| Páginas | `src/pages/ReguasCobrancaPage.tsx`, `src/pages/ReguasCobrancaEditorPage.tsx` |
| Modais de régua | `src/components/reguas-cobranca/ReguaDialog.tsx`, `WorkflowTypeSelector.tsx`, `EntityKindSelector.tsx`, `AssignmentFiltersPanel.tsx`, `BulkIntegrationDialog.tsx` |
| Timeline | `src/components/reguas-cobranca/timeline/TimelineView.tsx`, `DayGroup.tsx`, `StepCard.tsx`, `AddStepDialog.tsx`, `EditCaudaDialog.tsx`, `StepConfigSheet.tsx`, `groupSteps.ts` |
| Wizard | `src/components/reguas-cobranca/wizard/StepWizard.tsx`, `stepWizardPhases.ts`, `steps/ActionStep.tsx`, `steps/WhenStep.tsx`, `steps/IntegrationStep.tsx`, `steps/ContentStep.tsx`, `steps/TypeConfigStep.tsx`, `steps/ReviewStep.tsx` |
| Config puros (não-React) | `config-forms/triggerConfig.ts`, `config-forms/channelStepConfig.ts`, `config-forms/profileStepConfig.ts` |
| Formulários por tipo | `config-forms/ConditionConfigForm.tsx`, `WaitConfigForm.tsx`, `WebhookConfigForm.tsx`, `TriggerAIConfigForm.tsx`, `ProfileStepTriggerFields.tsx` |
| Componentes compartilhados | `config-forms/SharedComponents/AIMessageAssistant.tsx`, `MessagePreview.tsx`, `TemplateHSMSelector.tsx`, `TemplateEditor.tsx`, `VariableInserter.tsx`, `MetaVariableMapper.tsx`, `IntegrationSelector.tsx`, `DaysOverdueInput.tsx`, `DaysOverdueRangeInput.tsx`, `dayOverdueDescription.ts` |
| Versionamento / auditoria | `versioning/PublishDialog.tsx`, `versioning/VersionHistoryPanel.tsx`, `audit/AuditLogPanel.tsx` |
| Tipos | `src/types/reguas-cobranca.ts`, `src/types/workflow-versioning.ts` |
| Hooks | `src/hooks/useReguasCobranca.ts`, `useWorkflowVersions.ts`, `useWorkflowAuditLogs.ts`, `useWorkflowBulkIntegration.ts`, `useWorkflowCatalog.ts` |
| Documentação interna do próprio app | `src/pages/central-docs/negocio/data/reguas-cobranca.ts`, `.../editor-regua.ts`, `src/pages/central-docs/topics/data/reguas-workflows.ts` |

---

## 1. Objetivo e personas

### 1.1 O que a tela resolve

A **régua de cobrança** é o desenho da política de comunicação da empresa com o devedor. Ela responde a uma pergunta: *"quando o título está em determinada situação, o que a empresa faz?"*. Cada "o que a empresa faz" é um **passo** (`workflow_step`), e cada passo carrega **quando dispara** (gatilho) e **o que executa** (canal, webhook, condição, espera, bloqueio, negativação, notificação, atividade humana, gatilho de IA).

A régua **não dispara sozinha**: ela é o molde. Quem executa é a **campanha**, que referencia réguas em `campaigns.target_reguas`. Desativar uma régua pausa em cascata as campanhas ativas que a usam (ver §3.7 e §16.6).

### 1.2 Personas

| Persona | O que faz nestas telas | Permissões relevantes |
|---|---|---|
| **Gestor de cobrança / Operador de régua** | Cria a régua, define carteiras/filtros de atribuição, monta a timeline de passos, escreve as mensagens, publica a versão e ativa. É o usuário primário. | `workflows:write` |
| **Analista / Observador** | Abre o editor para entender o que a régua faz hoje, consulta histórico de versões e logs. Não consegue editar: sem `workflows:write` o header esconde "Publicar", "Trocar integração" e "Configurações", e a `TimelineView` recebe os handlers de escrita como `undefined` (some o switch do passo, a lixeira, o duplicar, o "Adicionar" e o drag-and-drop efetivo). | leitura |
| **Administrador de integrações** | Usa "Trocar integração" (`BulkIntegrationDialog`) para redirecionar todos os passos de um canal para outra integração de uma vez — típico em migração de provedor. | `workflows:write` |
| **Auditor / Supervisão** | Lê `AuditLogPanel` e `VersionHistoryPanel` para reconstituir quem mudou o quê e restaurar uma versão anterior. | leitura (restaurar exige escrita — ver §13) |

### 1.3 Contexto multi-tenant que muda a tela

A Torre é multi-tenant por schema (`org_{slug}`). Há **um** gate que muda radicalmente esta tela: `pipelineProfile` da organização (`useOrganization()`).

- **Org sem perfil** (o caso normal — cobrança): a régua é **orientada a dia de atraso**. A timeline agrupa por dia, existe "cauda" (faixa aberta), e o wizard pede dia/faixa.
- **Org com `pipelineProfile === "formalizacao"`**: a régua é **orientada a etapa do contato**. A timeline agrupa por etapa, com um grupo fixo "Sem etapa definida" no topo; a fase "Quando" **não oferece** campo de dia nem switch de cauda, e **exige** `etapa_trigger` preenchido para salvar.

Isso não é um toggle de usuário: vem da org. O designer precisa desenhar **as duas variantes** da timeline e da fase "Quando".

---

## 2. Modelo mental: régua, passo, gatilho, cauda, versão, publicação, carteira

Fontes: `src/types/reguas-cobranca.ts`, `src/components/reguas-cobranca/config-forms/triggerConfig.ts`, `config-forms/profileStepConfig.ts`, `src/types/workflow-versioning.ts`, `src/pages/central-docs/negocio/data/reguas-cobranca.ts`.

### 2.1 Régua (`workflow`)

Um registro em `workflows` com:

| Campo | Significado na UI |
|---|---|
| `name` | Nome exibido em card, linha de tabela e header do editor. |
| `description` | Subtítulo (card: `line-clamp-2`; tabela: `truncate max-w-[200px]`; header do editor: `text-xs`). |
| `is_active` | Switch "Ativo/Inativo" na lista e "Ativa/Inativa" no editor. |
| `workflow_type` | `"sequential"` (rótulo **Sequencial**) ou `"broadcast"` (rótulo **Pontual**). Decide para qual editor a régua abre. |
| `entity_kind` | `"contract"` (Contratos) ou `"supply"` (Suprimentos). Retrocompat: ausente = `contract`. |
| `assignment_filters` | `{ portfolios: string[], filter_ids: string[], aggregation_logic: "AND" \| "OR" }` — o público da régua. |
| `trigger_config` | Config de gatilho em nível de régua (comparado no cálculo de "alterações não publicadas"). |
| `steps_count` | Contagem exibida como "N ações". |
| `current_published_version_id` | Ausente ⇒ badge **Draft**. Presente ⇒ badge **v{n}**. |
| `version_count` | Número exibido no badge de versão. |

### 2.2 Passo (`workflow_step`)

| Campo | Papel |
|---|---|
| `id` | Identidade; chave do drag-and-drop (`useSortable({ id: step.id })`). |
| `step_type` | Decide ícone, cor, rótulo, formulários e fases do wizard. |
| `name` | Título do card. **Pode ser `null`** em passos legados — o card cai em `step.name \|\| label` (rótulo do tipo). |
| `config` | JSONB com **três famílias de chaves**: gatilho de dia, gatilho de perfil/etapa e config do canal (ou campos do formulário de tipo). |
| `position_x`, `position_y` | `position_y` ordena dentro do grupo; a reordenação regrava `position_y = index * 10`. `position_x` é gravado 0 na criação. |
| `is_active` | **Coluna** do banco é a fonte de verdade do motor. `config.is_active` é mantido em sincronia só por retrocompatibilidade (ver `handleToggleStep` no editor). |

> **Nota de implementação relevante ao redesign** (`ReguasCobrancaEditorPage.tsx`): o hook descarta `position_x`/`position_y` no insert e a leitura de `useWorkflow` ordena por `created_at`. Ou seja, a posição inicial de um passo recém-criado **não** é controlada pela tela; só a reordenação explícita grava `position_y`.

### 2.3 Gatilho — os formatos que existem

`config-forms/triggerConfig.ts` e `config-forms/profileStepConfig.ts` definem quatro formatos de gatilho gravados em `workflow_steps.config`:

1. **Dia exato** — `days_overdue: N`. Dispara quando o título tem exatamente N dias de atraso. **N pode ser negativo** = cobrança preventiva (`-7` = 7 dias antes do vencimento). `0` = no vencimento.
2. **Faixa fechada** — `days_overdue_trigger: { min, max }` com `max` numérico.
3. **Faixa aberta ("cauda")** — `days_overdue_trigger: { min, max: null }`. Sem `repeat_every_days`, **dispara todo dia** a partir de `min`.
4. **Etapa** (só sob perfil `formalizacao`) — `etapa_trigger: "<valor cru>"`, opcionalmente com a janela `etapa_min_days` / `etapa_max_days` (inclusiva nas duas pontas) e `fire_once`.

**Exclusividade dia × etapa** (`StepWizard.buildConfig`): quando o passo tem `etapa_trigger` preenchido e o perfil está ativo, **nenhuma chave de dia é gravada** (`triggerFields = {}`). Motivo declarado no código: `buildTriggerConfig` grava sempre `days_overdue` com default `0`; sem a exclusividade o passo casaria também todo contato com `days_overdue = 0` em qualquer etapa.

### 2.4 Cauda

"Cauda" é o nome de negócio para o passo de **faixa aberta** (sem limite superior). Características de UI:

- Existe **uma cauda por régua**: `caudaJaExiste` é calculado no editor (`steps.some(step => parseTriggerConfig(step.config).mode === "range")`) e passado ao wizard, que trava o switch "Step de cauda".
- Na timeline, a cauda vira um **grupo próprio** (`key: "cauda:<min>"`), separado do grupo de dia exato com o mesmo número — de propósito, para não colidir.
- O grupo de cauda tem dois botões próprios no cabeçalho: **"Adicionar canal"** e **"Editar"** (abre `EditCaudaDialog`, edição **em lote** da faixa/cadência de todos os passos do grupo).
- A faixa é propriedade do **grupo** (todos os passos da cauda compartilham). Isso **não vale** para a janela de etapa, que é por passo.

### 2.5 Versão e publicação

`src/types/workflow-versioning.ts` + `useWorkflowVersions.ts`.

- Uma versão é um **snapshot congelado**: `workflow_snapshot` (campos da régua) + `steps_snapshot` (array de passos).
- Status de versão: `draft` | `published` | `archived`.
- O editor calcula `hasUnpublishedChanges` comparando o estado atual com o snapshot publicado (nome, descrição, `is_active`, `assignment_filters`, `trigger_config`, contagem de passos, e por passo: `name`, `step_type`, `config` — além de detectar passos adicionados e removidos).
- Regra dura de UX: **sem versão publicada, a régua não pode ser ativada**. O switch no header fica `disabled` quando `!publishedVersion && !workflow.is_active`, com tooltip "Publique uma versão para ativar a régua".
- O botão **Publicar** só aparece com `workflows:write` **e** `hasUnpublishedChanges`, e fica `disabled` quando `hasIncompleteSteps`.

### 2.6 Vínculo com carteiras e filtros

`assignment_filters` define **quem** a régua alcança:

- `portfolios: string[]` — IDs de carteiras (portfolios), resolvidos contra `usePortfolios()`.
- `filter_ids: string[]` — IDs de filtros dinâmicos, resolvidos contra `useFilters({ pageSize: 200 })`.
- `aggregation_logic: "AND" | "OR"` — como combinar. O `ReguaDialog` **sempre persiste explicitamente** (default `"AND"`), com o comentário: *"so counts, preview and the canonical membership engine never diverge"*.

Na lista, esses IDs viram **badges coloridos com ícone dinâmico** (`DynamicIcon` sobre `lucide-react/icons`), usando `color` e `icon` do próprio filtro/carteira.

### 2.7 Régua de suprimento

Quando `entity_kind === "supply"`, o `ReguaDialog` mostra um `Alert` informativo:

> "Esta régua cobra **suprimentos**. Os filtros e carteiras de atribuição abaixo devem ser de suprimento (entidade 'Suprimentos'); filtros de contrato/equipamento não encontram público e a régua ficará vazia."

O seletor de `entity_kind` só aparece se a org tem fonte de suprimento (`useHasSupply()`) **ou** se a régua já é de suprimento (para não sumir com o valor existente ao editar).

---

## 3. Tela `/reguas-cobranca` — anatomia

Fonte: `src/pages/ReguasCobrancaPage.tsx` (790 linhas).

### 3.1 Estrutura vertical

```
┌───────────────────────────────────────────────────────────────┐
│ [h1] Réguas de Cobrança          [↻ Refresh] [+ Nova Régua]   │
│ [p]  Crie e gerencie fluxos automatizados de cobrança         │
│      (subtítulo escondido em < sm)                            │
├───────────────────────────────────────────────────────────────┤
│ Card de filtros                                               │
│  [🔍 Buscar réguas...          ] [Tipo ▾] [Status ▾] [◫/☰]   │
├───────────────────────────────────────────────────────────────┤
│ CORPO — um de cinco estados:                                  │
│   (a) skeleton   (b) erro   (c) vazio                         │
│   (d) TABELA (viewMode = "list")                              │
│   (e) GRID de cards (viewMode = "grid")                       │
├───────────────────────────────────────────────────────────────┤
│ Paginação (só se totalPages > 1): [Anterior] Página X de Y [Próxima] │
└───────────────────────────────────────────────────────────────┘
```

Espaçamento raiz: `space-y-4 sm:space-y-6`.

### 3.2 Cabeçalho

| Elemento | Detalhe |
|---|---|
| Título | `h1`, `text-xl sm:text-2xl font-bold tracking-tight` — "Réguas de Cobrança" |
| Subtítulo | `text-muted-foreground text-sm hidden sm:block` — "Crie e gerencie fluxos automatizados de cobrança" |
| `RefreshButton` | `onRefresh={handleRefresh}`; `isFetching` combina `isFetching \|\| isFetchingCounts`. **Recarrega duas coisas**: a lista de workflows (`refetch`) e o cache de contagens de contato (`invalidateContactCounts`) — que têm query keys separadas e antes ficavam stale. |
| Botão "Nova Régua" | Só com `canWrite`. Responsivo: `size="icon"` em mobile (só o `+`), `sm:w-auto sm:px-4` com texto "Nova Régua" em ≥ sm. |

### 3.3 Card de filtros

Um `Card` com `CardContent pt-4 sm:pt-6`, layout `flex-col sm:flex-row gap-3 sm:gap-4`.

| Controle | Tipo | Opções / comportamento | Default |
|---|---|---|---|
| Busca | `Input` com ícone `Search` absoluto à esquerda (`pl-9`), placeholder "Buscar réguas..." | Digitação reseta `page` para 1. Vai como `search` para `useReguasCobranca`. | `""` |
| Tipo | `Select` `w-full sm:w-[150px]`, placeholder "Tipo" | `all` → "Todos os tipos"; `sequential` → "Sequencial"; `broadcast` → "Pontual" | `all` |
| Status | `Select` `w-full sm:w-[150px]`, placeholder "Status" | `all` → "Todos os status"; `active` → "Ativos"; `inactive` → "Inativos" | `all` |
| Alternador de visão | `ViewToggle` | Alterna `grid` ↔ `list`. Persistido em `useViewPreference("reguas")`. | preferência salva |

Ambos os `Select` também resetam `page` para 1 ao mudar.

### 3.4 Visão TABELA (`viewMode === "list"`)

Container: `rounded-md border overflow-x-auto bg-card`, envolvido num `TooltipProvider`.

**Colunas, na ordem:**

| # | `TableHead` | Alinhamento | Conteúdo da célula |
|---|---|---|---|
| 1 | Tipo | esquerda | Badge outline: **Pontual** (`Megaphone`, `border-purple-300 text-purple-600 bg-purple-50`) ou **Sequencial** (`GitBranch`, `border-blue-300 text-blue-600 bg-blue-50`) |
| 2 | Nome | esquerda | `flex flex-col`: nome em `font-medium`; descrição em `text-xs text-muted-foreground truncate max-w-[200px]` |
| 3 | Contatos | direita | `counts.contactCount.toLocaleString("pt-BR")`; `Skeleton h-4 w-16` enquanto carrega |
| 4 | Contratos | direita | `counts.contractCount` idem |
| 5 | Titulos | direita | `counts.titleCount` idem |
| 6 | Vl Total | direita | `formatCompactCurrency(counts.totalValue)` com **Tooltip** mostrando o valor completo (`formatCurrency`); `Skeleton h-4 w-20` |
| 7 | Vl Pago | direita | `counts.paidValue`, idem com tooltip |
| 8 | Em Aberto | direita | `counts.openValue`, idem com tooltip |
| 9 | Vencido | direita | `counts.overdueValue`, idem com tooltip |
| 10 | Passos | esquerda | `"{steps_count ?? 0} ações"` |
| 11 | Status | esquerda | **Badge de versão**: sem `current_published_version_id` → **Draft** (`border-amber-300 text-amber-600 bg-amber-50`); com → **v{version_count \|\| 1}** (`border-green-300 text-green-600 bg-green-50`) |
| 12 | *(sem rótulo, `w-[70px]`)* | — | Na verdade há **duas** células finais: o `Switch` de ativação e o `DropdownMenu` de ações. Ambas com `onClick={e => e.stopPropagation()}`. |

> ⚠️ **Inconsistência observada no código**: o `TableHeader` declara **12** colunas, mas o `TableBody` renderiza **13** células por linha (Tipo, Nome, Contatos, Contratos, Titulos, Vl Total, Vl Pago, Em Aberto, Vencido, Passos, Status(badge de versão), Switch, Menu). A coluna "Status" do header cobre o badge de versão, e o `Switch` fica numa célula sem cabeçalho — além da célula `w-[70px]` do menu. O redesign deve resolver a rotulagem: **"Status" na tabela hoje significa versão, não ativo/inativo.**

**Interação da linha inteira**: `className="cursor-pointer hover:bg-muted/50"`, `onClick={() => handleEdit(regua)}` — clicar na linha abre o `ReguaDialog` em modo edição, **não** o editor visual.

**Nota de rótulo**: o cabeçalho usa "Titulos" sem acento (código literal). ⚠️ A confirmar se é intencional.

### 3.5 Visão GRID (`viewMode === "grid"`)

Container: `grid gap-4 md:grid-cols-2 lg:grid-cols-3`.

Cada card: `hover:shadow-md transition-shadow flex flex-col h-full cursor-pointer`, `onClick={() => handleEdit(regua)}`.

**`CardHeader` (`pb-2`)** — `flex items-start justify-between`:

1. **Título** (`CardTitle text-lg truncate flex items-center gap-2`): ícone `Megaphone` roxo (`text-purple-500`) para broadcast ou `GitBranch` azul (`text-blue-500`) para sequential, seguido do nome.
2. **Linha de badges** (`flex items-center gap-1.5 mt-1`), badges `text-[10px] px-1.5 py-0 h-5 shrink-0`:
   - Badge de tipo: "Pontual" (roxo) ou "Sequencial" (azul).
   - Badge de versão: **Draft** (âmbar) com **Tooltip** "Esta régua não tem versão publicada"; ou **v{version_count}** (verde) quando há versão publicada e `version_count > 0`; ou nada.
3. **Métricas financeiras** (`mt-1 space-y-0.5`, dentro de `TooltipProvider`), duas linhas `text-[11px] text-muted-foreground` separadas por `·` (`text-muted-foreground/40`):
   - Linha 1: `{contactCount} contatos · {contractCount} contratos · {titleCount} titulos`
   - Linha 2: `Total: {compact}` (com tooltip do valor cheio) `· Pago: {compact} · Aberto: {compact} · Vencido: {compact}`
   - Enquanto carrega: dois `Skeleton` (`h-3 w-full` e `h-3 w-3/4`).
4. **Descrição** (`CardDescription line-clamp-2`), se existir.
5. **Menu de ações** (`DropdownMenu`, botão `ghost` `MoreHorizontal` `shrink-0`) — ver §3.6.

**`CardContent` (`flex-1 flex flex-col`)**:

- **Área flexível** — carteiras e filtros:
  - Se há atribuições: duas linhas rotuladas `Carteiras:` e `Filtros:` (label `text-xs text-muted-foreground w-16 shrink-0 mt-0.5`), cada uma com badges `variant="secondary"` `border-0`, **fundo = `{color}20`** (cor da carteira/filtro com 12,5% de alpha) e **texto = `{color}`**, com `DynamicIcon` (`h-3 w-3`) quando há ícone. Cada badge tem **Tooltip** com a `description` (quando existe), `max-w-xs`.
  - A linha de filtros usa `my-[15px]` (margem vertical literal).
  - Se não há nenhuma: `flex items-center gap-2 text-muted-foreground text-sm` com ícone `Filter` e texto "**Nenhum filtro atribuído**".
- **Rodapé** (`mt-auto pt-4 space-y-3 border-t my-px`):
  - Linha 1: à esquerda, ícone `ListTree` + `"{steps_count} ação/ações"` (pluralização correta); à direita, texto "Ativo"/"Inativo" + `Switch` (`stopPropagation`, `disabled={!canWrite}`).
  - Linha 2: botão `outline` `size="sm"` **largura total** — ícone `GitBranch` + "**Abrir Editor**" (`stopPropagation` + `handleOpenEditor`).

### 3.6 Menu de ações (idêntico em card e tabela)

`DropdownMenuContent align="end"`:

| Item | Ícone | Condição | Ação |
|---|---|---|---|
| Editor Visual | `Eye` | sempre | `handleOpenEditor` — navega para `/reguas-cobranca/{id}/editor` ou `/broadcasts/{id}/editor` conforme `workflow_type` |
| Editar | `Edit` | `canWrite` | abre `ReguaDialog` em modo edição |
| Duplicar | `Copy` | `canWrite` | `duplicateRegua.mutateAsync`; rótulo vira "**Duplicando...**" e o item fica `disabled` enquanto `isPending` |
| *(separador)* | — | `canDelete` | `DropdownMenuSeparator` |
| Excluir | `Trash2` | `canDelete` | `className="text-destructive"`; dispara `window.confirm` nativo (ver §16.5) |

Todos os itens chamam `e.stopPropagation()` para não acionar o clique da linha/card.

### 3.7 Ativar / desativar régua — o fluxo assimétrico

`handleToggle` em `ReguasCobrancaPage.tsx`:

- **Ativar** (`nextActive === true`): fluxo **direto**, sem modal. Chama `performToggle(regua, true)`.
- **Desativar**: antes de agir, consulta `orgClient.from("campaigns").select("id, name, status").eq("status", "active").contains("target_reguas", [regua.id])`.
  - Erro na consulta → toast destrutivo "Erro ao verificar campanhas dependentes" + a descrição do erro; **nada é alterado**.
  - Nenhuma campanha ativa → desativa direto.
  - Há campanhas ativas → abre o `AlertDialog` de confirmação (ver §16.6).
- `performToggle` com sucesso e `pausedCount > 0` emite toast: título "**Régua desativada**", descrição "`{N} campanha(s) pausada(s) em cascata.`".
- Falha: toast destrutivo com título "Não foi possível ativar a régua" / "Não foi possível desativar a régua" e a mensagem do erro (ou "Erro desconhecido").

### 3.8 Formatação de números

Duas funções locais na página:

- `formatCurrency(value)` — `Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL", minimumFractionDigits: 0, maximumFractionDigits: 0 })`. Usada **nos tooltips**.
- `formatCompactCurrency(value)` — `≥ 1.000.000` → `R$ {x.x}M`; `≥ 1.000` → `R$ {x}K`; senão cai em `formatCurrency`. Usada **na superfície visível**.
- Contagens inteiras: `toLocaleString("pt-BR")`.

### 3.9 Paginação

Só renderiza se `data.totalPages > 1`. Três elementos centralizados (`flex justify-center gap-2`): botão "Anterior" (`disabled` na página 1), texto "Página {page} de {totalPages}" (`text-sm text-muted-foreground`), botão "Próxima" (`disabled` na última).

---

## 4. Modal de criação/edição da régua — `ReguaDialog`

Fonte: `src/components/reguas-cobranca/ReguaDialog.tsx`.

### 4.1 Objetivo e gatilhos

Cria uma régua nova ou edita os **metadados e o público** de uma existente. **Não** mexe em passos — isso é o editor.

Gatilhos:
1. Botão "Nova Régua" na lista (`regua = null` → modo criação).
2. Item "Editar" do menu de ações **ou clique na linha/card** da lista (modo edição).
3. Botão "Configurações" no header do editor de régua (modo edição, `regua = workflow`).

### 4.2 Layout

`DialogContent` com `w-[95vw] h-[95vh] flex flex-col overflow-hidden` — praticamente tela cheia.

- **`DialogHeader`** (`flex-shrink-0`): `DialogTitle` contém um bloco `p-2 rounded-lg bg-primary/10 text-primary` com o ícone `Ruler` (h-5 w-5), seguido do texto "**Nova Régua**" ou "**Editar Régua**". `DialogDescription`: "Configure uma nova régua de cobrança automatizada" / "Atualize a configuração da régua de cobrança".
- **`DialogBody`** (`flex-1 overflow-y-auto`): o `<form id="regua-form">` com `space-y-6`.
- **`DialogFooter`**: "Cancelar" (`outline`) e o submit.

### 4.3 Campos, na ordem de renderização

| Ordem | Campo | Componente | Visibilidade | Validação | Default |
|---|---|---|---|---|---|
| 1 | **Tipo de Régua** | `WorkflowTypeSelector` | **só na criação** (`!isEditing`) | `z.enum(["sequential","broadcast"])` | `"sequential"` |
| — | separador | `Separator` | só na criação | — | — |
| 2 | **Tipo de Cobrança** | `EntityKindSelector` | só quando `showEntityKind = hasSupply \|\| selectedEntityKind === "supply"` | `z.enum(["contract","supply"])` | `"contract"` |
| 2b | Alerta de suprimento | `Alert` + ícone `Info` | só quando `entity_kind === "supply"` | — | — |
| — | separador | `Separator` | junto com o bloco de entity kind | — | — |
| 3 | **Nome** | `Input`, placeholder "Nome da régua" | sempre | `z.string().min(1, "Nome é obrigatório")` | `""` |
| 4 | **Descrição** | `Textarea`, placeholder "Descrição da régua" | sempre | `z.string()` (sem mínimo — opcional de fato) | `""` |
| 5 | **Filtros de Atribuição** | `AssignmentFiltersPanel` (precedido de `<p class="text-sm font-medium">Filtros de Atribuição</p>`) | sempre | não validado pelo schema | `{ portfolios: [], filter_ids: [], aggregation_logic: "AND" }` |
| 6 | **Régua Ativa** | `Switch` num `FormItem` `flex items-center justify-between rounded-lg border p-3` | sempre | `z.boolean()` | **`false`** |

Descrição do campo 6 (`FormDescription`): "Ative para que a régua seja executada".

> **Observação de produto**: a régua nasce **inativa** por default (`is_active: false`), coerente com a regra "publique uma versão para ativar" do editor.

### 4.4 Comportamento de submit

`onSubmit` monta o payload `{ ...data, assignment_filters: { ...assignmentFilters, aggregation_logic: assignmentFilters.aggregation_logic || "AND" }, workflow_type: data.workflow_type }`.

- **Editando**: `updateRegua.mutateAsync({ id, ...payload })` → `onClose()`. **Permanece na listagem**.
- **Criando**: `createRegua.mutateAsync(payload)` → `onClose()` → **redirect**:
  - `workflow_type === "broadcast"` → `navigate("/broadcasts/{id}/editor")`
  - senão → `navigate("/reguas-cobranca/{id}/editor")`
- Nos dois casos, ao final: `invalidateContactCounts()`.
- Erro: `logError(error, { source: "ReguaDialog", action: "save regua" })`. **Não há toast de erro nesta superfície** — ⚠️ o usuário só percebe pelo fato de o modal não fechar. Ponto de dor para o redesign (ver §20).

### 4.5 Estados dos botões

- Submit: rótulo "**Criar Régua**" ou "**Salvar Alterações**"; `disabled={isSubmitting}` (`createRegua.isPending || updateRegua.isPending`); mostra `Loader2 animate-spin` à esquerda quando submetendo.
- O submit é `type="submit" form="regua-form"` — está **fora** do `<form>`, ligado por atributo `form`.
- "Cancelar": `type="button" variant="outline"`, chama `onClose` — **sem confirmação**, mesmo com alterações pendentes.

### 4.6 Re-hidratação

`useEffect` sobre `[regua, form]`: quando `regua` muda, faz `form.reset(...)` com os valores da régua (com retrocompat `workflow_type || "sequential"` e `entity_kind || "contract"`) e recarrega `assignmentFilters` de `regua.assignment_filters`, com defaults `[]`, `[]`, `"AND"`. Quando `regua` é nulo, reseta para os defaults de criação.

### 4.7 `WorkflowTypeSelector` — detalhe

Fonte: `src/components/reguas-cobranca/WorkflowTypeSelector.tsx`.

`RadioGroup` com `className="grid grid-cols-2 gap-4"`. Cada opção é um `Label` envolvendo um `Card p-4`:

| Valor | Rótulo | Descrição | Ícone |
|---|---|---|---|
| `sequential` | **Sequencial (Cobrança)** | "Dispara automaticamente baseado em dias de atraso do título" | `GitBranch` |
| `broadcast` | **Pontual (Broadcast)** | "Disparo único/imediato para um público selecionado" | `Megaphone` |

Estados visuais:
- Selecionado: `border-primary bg-primary/5 ring-1 ring-primary`
- Não selecionado: `hover:bg-muted/50`
- `disabled`: `opacity-50 cursor-not-allowed`

Layout interno: `flex items-start gap-3` — `RadioGroupItem` (`mt-1`) + bloco com linha de ícone (`h-4 w-4 text-muted-foreground`) e rótulo (`font-medium text-sm`), e descrição embaixo (`text-xs text-muted-foreground mt-1`).

### 4.8 `EntityKindSelector` — detalhe

Fonte: `src/components/reguas-cobranca/EntityKindSelector.tsx`. Estrutura visual **idêntica** ao `WorkflowTypeSelector` (grid 2 colunas de cards com radio).

| Valor | Rótulo | Descrição | Ícone |
|---|---|---|---|
| `contract` | **Contrato** | "Cobra parcelas de contratos" | `FileText` |
| `supply` | **Suprimento** | "Cobra parcelas de suprimentos (insumos/consumíveis)" | `Package` |

Efeito funcional documentado no próprio arquivo: grava `workflows.entity_kind`, que roteia o `campaign_pipeline_fetch_titles` para a MV de contrato ou de suprimento.

---

## 5. Editor de régua em tela cheia — anatomia

Fonte: `src/pages/ReguasCobrancaEditorPage.tsx`.

### 5.1 Esqueleto

```
<div class="h-screen flex flex-col overflow-hidden bg-background">
  <header class="h-16 border-b bg-background flex items-center justify-between px-6 shrink-0">
     … esquerda: Voltar | divisor | nome + descrição
     … direita: status de salvamento | badge de versão | "há X" | Histórico | Logs
                | Publicar | Ativa/Inativa + Switch | expandir/colapsar
                | Trocar integração | Configurações
  </header>
  <main class="flex-1 overflow-y-auto">
     <TimelineView … />
  </main>
  … 7 superfícies flutuantes montadas no final (ver §5.5)
</div>
```

Não há sidebar. O editor **ocupa a tela inteira** — é o único jeito de sair dele é o botão "Voltar".

### 5.2 Cabeçalho — bloco esquerdo

| Elemento | Detalhe |
|---|---|
| Botão "Voltar" | `variant="ghost" size="sm"`, ícone `ArrowLeft`. **Efeito colateral importante**: `queryClient.invalidateQueries({ queryKey: ["workflows"] })` antes de `navigate("/reguas-cobranca")` — garante que os cards da listagem reflitam as mudanças feitas no editor. |
| Divisor | `<div class="h-6 w-px bg-border" />` |
| Identificação | `h1 font-semibold` com `workflow.name`; abaixo, `p text-xs text-muted-foreground` com `workflow.description` (se houver). |

### 5.3 Cabeçalho — bloco direito (`flex items-center gap-3`)

Na ordem de renderização, com divisores `h-6 w-px bg-border` entre grupos:

**Grupo 1 — status de salvamento**

| Estado | Render |
|---|---|
| `isMutating` (qualquer de `updateWorkflow`, `createStep`, `updateStep`, `deleteStep` pendente) | `Loader2 h-3 w-3 animate-spin` + "**Salvando...**" |
| ocioso | ícone `Save h-3 w-3` + "**Salvo**" |

Ambos em `text-sm text-muted-foreground`. **O editor salva automaticamente** — não há botão "Salvar" de página.

*(divisor)*

**Grupo 2 — versão**

| Elemento | Render |
|---|---|
| Badge de versão | `hasUnpublishedChanges` → `variant="secondary"`, texto "**Draft v{versions.length + 1}**". Senão → `variant="default"`, texto "**v{publishedVersion.version_number \|\| 1} Publicada**". `cursor-default`. |
| Tooltip do badge | com mudanças: "Alterações não publicadas". Sem: "Publicada {há X}" via `formatDistanceToNow(..., { addSuffix: true, locale: ptBR })`, ou "Versão publicada" se não houver `published_at`. |
| Selo de tempo | Se `publishedVersion.published_at`: `text-xs text-muted-foreground` com ícone `Clock h-3 w-3` + "há X" (mesmo `formatDistanceToNow`). |

*(divisor)*

**Grupo 3 — ações de versionamento**

| Botão | Ícone | Variante | Tooltip | Condição |
|---|---|---|---|---|
| **Histórico** | `History` | `outline` `sm` | "Ver versões anteriores" | sempre |
| **Logs** | `FileText` | `outline` `sm` | "Ver histórico de alterações" | sempre |
| **Publicar** | `Rocket` | default `sm` | — | só com `canWrite && hasUnpublishedChanges`; `disabled={hasIncompleteSteps}` |

*(divisor)*

**Grupo 4 — ativação da régua**

- Texto `text-sm text-muted-foreground`: "**Ativa**" ou "**Inativa**".
- `Switch` `checked={workflow.is_active}`, `disabled` quando: `!canWrite` **ou** `updateWorkflow.isPending` **ou** (`!publishedVersion && !workflow.is_active`).
- Tooltip (só quando `!publishedVersion && !workflow.is_active`): "**Publique uma versão para ativar a régua**".
- **Guarda de ativação adicional** em `handleToggleWorkflow`: se `isActive && hasIncompleteSteps`, dispara toast destrutivo "**Não é possível ativar a régua** / Existem ações sem configuração completa. Configure todas as ações antes de ativar." e **aborta**.
- Sucesso: toast "Régua ativada" / "Régua desativada" com descrição "A régua começará a processar contatos." / "A régua não processará mais contatos.".
- Falha: toast destrutivo "Erro / Não foi possível alterar o status da régua.".

**Grupo 5 — visualização e escopo de régua**

| Botão | Ícone | Detalhe |
|---|---|---|
| Expandir/colapsar todos | `ChevronsUpDown` | `variant="ghost" size="sm" className="h-8 px-2"`. Alterna `allExpanded` (inicial `true`). Tooltip: "Colapsar todos os grupos" / "Expandir todos os grupos". |
| **Trocar integração** | `Replace` | `variant="outline" size="sm"`, `data-testid="bulk-integration-trigger"`. Só com `canWrite`. Comentário no código: *"ação de escopo RÉGUA, separada visualmente das ações de step para não ser clicada por engano"*. |
| **Configurações** | `Settings` | `variant="outline" size="sm"`. Só com `canWrite`. Abre o `ReguaDialog` com a régua atual. |

### 5.4 `hasIncompleteSteps` — a regra que bloqueia publicação e ativação

Calculado em `useMemo` sobre `[steps, validIntegrationIds]`. Um passo é incompleto quando:

1. `config` é nulo/ausente; **ou**
2. `step_type` ∈ `["send_whatsapp", "send_email", "send_sms", "send_voice", "webhook", "human_activity", "negativation", "block"]` **e** (`!config.integration_id` **ou** a integração não está em `validIntegrationIds`).

`validIntegrationIds` = `Set` dos `id` de `useOrgIntegrations()` filtrados por `is_active`.

> ⚠️ **Divergência entre duas listas de "tipos que exigem integração"**:
> - Página do editor (`hasIncompleteSteps`): **8** tipos — **não inclui** `send_rcs` nem `notification`.
> - `StepCard.checkConfigurationStatus`: **10** tipos — inclui `send_rcs` e `notification`.
>
> Consequência prática: um passo RCS ou de notificação sem integração aparece com badge "**Incompleta**" no card, mas **não** bloqueia "Publicar" nem a ativação da régua. Isso é inconsistência real do código atual, relevante para o redesign.

### 5.5 Superfícies montadas no fim da página

| Componente | Props-chave | Papel |
|---|---|---|
| `StepConfigSheet` | `step={selectedStep}`, `open={isConfigSheetOpen}`, `onSave={handleSaveStep}`, `siblingSteps={steps}` | Wizard em `mode="edit"` |
| `AddStepDialog` | `open={isAddDialogOpen}`, `onCreate={handleCreateStep}`, `target={addStepTarget}`, `caudaJaExiste`, `siblingSteps={steps}` | Wizard em `mode="create"` |
| `ReguaDialog` | `open={isReguaDialogOpen}`, `regua={workflow}` | Configurações da régua |
| `BulkIntegrationDialog` | `workflowId={id!}`, `open`, `onOpenChange` | Troca de integração em massa |
| `VersionHistoryPanel` | `workflowId={id}`, `open`, `onClose` | Histórico de versões |
| `AuditLogPanel` | `workflowId={id}`, `open`, `onClose` | Logs |
| `PublishDialog` | `workflowId`, `workflow`, `steps`, `open`, `onClose` | Publicação |

### 5.6 Operações de passo — o que cada ação faz e o que avisa

| Ação | Handler | Escrita | Toast de sucesso | Toast de erro | Relança? |
|---|---|---|---|---|---|
| Ligar/desligar passo | `handleToggleStep` | `updateStep` com **coluna** `is_active` + `config.is_active` em sincronia | — | "Erro / Não foi possível alterar o status da ação." | não |
| Configurar | `handleConfigureStep` | — (só abre o sheet) | — | — | — |
| Adicionar | `handleAddStep(target?)` | — (só abre o dialog) | — | — | — |
| Reordenar | `handleReorderSteps` | `Promise.all` de `updateStep({ id, position_y })` | — | "Erro / Não foi possível reordenar as ações." | não |
| Salvar passo (wizard edit) | `handleSaveStep` | `updateStep({ id, name, config, is_active })` | — | "Erro / Não foi possível salvar as configurações." | **sim** (`throw`) |
| Criar passo (wizard create) | `handleCreateStep` | `createStep({ workflow_id, step_type, name, config, position_x: 0, is_active })` | "**Passo criado**" + "O passo já está ativo nesta régua." / "O passo foi criado inativo — ative-o quando quiser." | "Erro / Não foi possível criar o passo." | **sim** |
| Excluir | `handleDeleteStep` | `deleteStep({ id, workflowId })` | — | "Erro / Não foi possível excluir o passo." | **sim** |
| Duplicar | `handleDuplicateStep` | `createStep` com `name: step.name ? "{nome} (cópia)" : null`, `config: {...}`, `position_y: +5` | — | "Erro / Não foi possível duplicar o passo." | não |
| Editar cauda em lote | `handleSaveCauda` | `Promise.all` de `updateStep({ id, config: mergeTriggerIntoConfig(...) })` | "**Faixa atualizada**" + "A faixa e a cadência foram atualizadas para todas as ações do grupo." | "Erro / Não foi possível atualizar a faixa do grupo." | **sim** |

> **Detalhe de UX importante do "relança"**: os handlers que relançam mantêm o wizard/dialog **aberto** quando a gravação falha, preservando o que o operador preencheu. Os que não relançam (toggle, reorder, duplicar) só emitem toast.

> **Nota sobre duplicação**: o código explica que passos legados têm `name` NULL no banco ("879 dos 926 medidos em DEV"). Por isso a duplicação usa `step.name ? ... : null` em vez de interpolar — evitaria gravar a string literal `"null (cópia)"`.

### 5.7 Estados de carregamento e de erro da página

| Estado | Render |
|---|---|
| `isLoading` | `h-screen flex items-center justify-center` com `Loader2 h-8 w-8 animate-spin text-muted-foreground`. **Tela inteira**, sem header. |
| `!workflow` (não encontrada) | `h-screen flex flex-col items-center justify-center`: texto "**Régua não encontrada**" (`text-muted-foreground mb-4`) + botão "Voltar". |

---

## 6. Timeline de passos

Fontes: `timeline/TimelineView.tsx`, `timeline/DayGroup.tsx`, `timeline/StepCard.tsx`, `timeline/groupSteps.ts`.

### 6.1 Dois modos de agrupamento

`isEtapaMode = pipelineProfile === "formalizacao"`.

#### Modo DIA (org de cobrança — o caso normal)

Percorre os passos e separa em dois mapas:

| Tipo de grupo | Chave | Critério |
|---|---|---|
| Dia exato | `day:{N}` | `parseTriggerConfig(config).mode !== "range"`; N vem de `config.days_overdue` ?? `step.days_overdue` ?? `0` |
| Cauda | `cauda:{min}` | `parseTriggerConfig(config).mode === "range"`; agrupa por `trigger.min`, guardando `max` e `repeatEveryDays` do **primeiro** passo do grupo |

As chaves são **deliberadamente distintas** para que um grupo de dia exato `5` e um grupo de cauda com `min = 5` não colidam.

Dentro do grupo, os passos são ordenados por `position_y || 0`. Os grupos são ordenados por `daysOverdue` crescente (dia exato e `min` de cauda compartilham a mesma escala).

#### Modo ETAPA (org com perfil `formalizacao`)

`groupStepsByEtapa(steps)` (`timeline/groupSteps.ts`):

- Agrupa por `parseProfileStepConfig(step.config).etapaTrigger`. `""` = **sem etapa**.
- Rótulo: `""` → `"Sem etapa definida"` (constante `SEM_ETAPA_LABEL`); senão `formatEtapaLabel(etapa)` (snake_case → "Aguardando assinatura").
- `needsAttention = (etapa === "")`.
- `sortMinDays` = menor `etapaMinDays` do grupo (ausente conta `0`). **Só para ordenar** — a janela real é por passo.
- **Ordenação**: o grupo `""` fica **fixo no topo**, sempre. O resto ordena por `sortMinDays`, desempatando por `label.localeCompare(..., "pt-BR")`.
  - Justificativa no código: etapas são estados **paralelos** (o contato está em exatamente uma), então não há ordem de jornada no dado; o início do intervalo é o único eixo que a configuração oferece.
- Chave do grupo: `etapa:{valor cru}` — **terceira** forma de chave, pelo mesmo motivo das outras duas.

### 6.2 O grupo "Sem etapa definida"

É o mecanismo de **denúncia** da tela: sob perfil, um passo sem `etapa_trigger` **não dispara por nada**. O grupo:

- Vai **sempre no topo**.
- Ícone do cabeçalho: `AlertTriangle` (`text-destructive`) no lugar de `Milestone`.
- Badge do cabeçalho: `variant="outline"` com `border-destructive/50 bg-destructive/10 text-destructive`.
- **Sublabel**: um `Badge` outline destrutivo com ícone `AlertTriangle h-3 w-3` e o texto "**Não dispara — defina a etapa**".
- **Não emite `etapaTarget`** — clicar em "Adicionar" ali cai no alvo genérico (não há etapa a herdar).

Para grupos de etapa normais, o sublabel é o **valor cru** da etapa num `<code class="rounded bg-muted px-1.5 py-0.5 font-mono text-xs text-muted-foreground">`. Justificativa no código: o motor compara `resolved_etapa = etapa_trigger` sem normalizar; prettificar sem mostrar o original faria o operador não reconhecer o que configurou.

### 6.3 Cabeçalho do grupo (`DayGroup`)

Layout: `flex items-center justify-between`, dentro de um `Collapsible` (`space-y-3`).

**Lado esquerdo** — `CollapsibleTrigger` como `<button class="flex items-center gap-2 hover:bg-muted/50 rounded-md px-2 py-1 -ml-2 transition-colors">`:

| Elemento | Detalhe |
|---|---|
| Chevron | `ChevronDown` quando aberto, `ChevronRight` quando fechado (`h-4 w-4 text-muted-foreground`) |
| Ícone | `AlertTriangle` se `needsAttention`; `Milestone` se grupo de etapa; senão `Calendar`. Cor: `text-destructive` se `needsAttention`, senão `text-muted-foreground`. |
| Badge principal | Ver tabela abaixo |
| Sublabel | `ReactNode` livre (o `<code>` da etapa ou o badge "Não dispara") |
| Contagem | `text-xs text-muted-foreground`: "{N} ação/ações" |
| Custo do grupo | Se `costPerContact > 0`: `text-xs text-muted-foreground font-mono` com "· ~{formatBRL(x)}/contato" |

**Rótulo e variante do badge principal:**

| Caso | Rótulo | Variante / classes extras |
|---|---|---|
| Grupo de etapa normal | `label` (ex.: "Aguardando assinatura") | `secondary` |
| Grupo "Sem etapa definida" | `"Sem etapa definida"` | `outline` + `border-destructive/50 bg-destructive/10 text-destructive` |
| Cauda | `describeCaudaTrigger(min, max, repeat)` — ex.: "De D+111 em diante · a cada 3 dias" | `badgeVariantForDay(min)` + `bg-amber-100 text-amber-700 hover:bg-amber-100` |
| Dia = 0 | "**No vencimento**" | `secondary` |
| Dia < 0 | "**{N} dia(s) antes**" | `secondary` |
| Dia 1–7 | "**{N} dia(s) de atraso**" | `default` |
| Dia 8–30 | "**{N} dias de atraso**" | `default` |
| Dia > 30 | "**{N} dias de atraso**" | `destructive` |

**Lado direito** — botões de ação do grupo:

| Grupo | Botões |
|---|---|
| Cauda | "**Adicionar canal**" (`Plus h-3 w-3`, `ghost sm h-7 text-xs`) → `onAddStep({ kind: "cauda", min, max, repeatEveryDays })`; e "**Editar**" (`Pencil h-3 w-3`) → abre `EditCaudaDialog` |
| Dia ou Etapa | "**Adicionar**" (`Plus h-3 w-3`, `ghost sm h-7 text-xs`) → `onAddStep(etapaTarget ?? { kind: "day", daysOverdue })` |

> **Precedência do alvo**: `addTarget = etapaTarget ?? { kind: "day", daysOverdue }`. Etapa vence dia.

**Corpo** (`CollapsibleContent`): `space-y-2 pl-6 border-l-2 border-muted ml-2` — uma linha vertical à esquerda que dá o efeito de timeline.

**Grupo vazio** (0 passos): texto centralizado `text-sm text-muted-foreground` variando por tipo — "Nenhuma ação configurada para esta faixa" (cauda) / "...para esta etapa" (com `etapaTarget`) / "...para este dia" — e um botão `outline sm` "**Adicionar Canal**" (cauda) ou "**Adicionar Primeira Ação**".

**Sincronia de expansão**: `useEffect` sobre `forceExpanded` — quando o botão `ChevronsUpDown` do header muda `allExpanded`, todos os grupos seguem. Estado inicial próprio: aberto (`useState(true)`).

### 6.4 Card de passo (`StepCard`) — anatomia visual completa

Container externo: `relative transition-all duration-200`, com modificadores de drag:
- arrastando: `opacity-50 z-50 scale-105`
- sendo sobrevoado (não arrastando): `transform translate-y-2`
- indicador de drop: `absolute -top-1 left-0 right-0 h-1 bg-primary rounded-full animate-pulse`

`Card` interno: `p-3 flex items-center gap-3 transition-all hover:shadow-md cursor-pointer`, com:
- `!isActive` → `opacity-60`
- arrastando → `shadow-lg ring-2 ring-primary/50`
- ordenando mas não arrastando este → `cursor-default`
- `!configStatus.isComplete` → `border-amber-300 bg-amber-50/30`

**Clicar no card inteiro abre a configuração** (`onClick={() => onConfigure(step)}`).

Da esquerda para a direita:

1. **Handle de arraste** — `<button>` com `{...attributes} {...listeners}` do `useSortable`, ícone `GripVertical h-4 w-4`, `cursor-grab active:cursor-grabbing touch-none text-muted-foreground hover:text-foreground`, `stopPropagation` no click.
2. **Ícone do tipo** — bloco `p-2 rounded-lg` com a classe de cor do tipo, contendo o ícone `h-4 w-4`. (Tabela completa em §8.)
3. **Bloco de informação** (`flex-1 min-w-0`):
   - **Linha 1** (`flex items-center gap-2`):
     - Nome: `font-medium text-sm` = `step.name || label` (rótulo do tipo quando sem nome).
     - **Badge de status de configuração** (só quando incompleto):
       - Integração inválida/removida: `border-destructive/50 bg-destructive/10 text-destructive`, ícone `AlertTriangle h-3 w-3`, texto "**Integração Inválida**".
       - Demais: `border-amber-300 bg-amber-50 text-amber-700`, ícone `AlertCircle h-3 w-3`, texto "**Incompleta**".
     - **Badge de janela de etapa** (só quando `showEtapaWindow` **e** o passo tem etapa ativa): `outline gap-1 text-xs font-normal text-muted-foreground`, ícone `CalendarClock h-3 w-3` + `describeEtapaWindow(config)`.
     - **Custo unitário** (só quando `unitCost > 0`): `text-xs text-muted-foreground font-mono` com "~{formatBRL}". Se `includesAI`, o valor ganha `border-b border-dotted` e um `HelpTip` ao lado (título "Custo estimado", corpo "Inclui custo de IA automatico").
   - **Linha 2** — `p text-xs text-muted-foreground truncate`: `configStatus.reason` quando incompleto, senão `getDescription()` (ver §6.6).
4. **Ações** (`flex items-center gap-2`, com `stopPropagation` no container):
   - `Switch` (só se `onToggle`, i.e. com `workflows:write`), `disabled={isUpdating}`.
   - Botão `Settings h-4 w-4` (`ghost icon h-8 w-8`) → configurar.
   - Botão `Copy h-4 w-4` (`ghost icon h-8 w-8 text-muted-foreground hover:text-foreground`, `title="Duplicar ação"`) → só se `onDuplicate`.
   - Botão `Trash2 h-4 w-4` (`ghost icon h-8 w-8 text-destructive hover:text-destructive hover:bg-destructive/10`) → só se `onDelete`; abre `AlertDialog` (ver §16.4).

### 6.5 `checkConfigurationStatus` — quando o card fica âmbar

Ordem de verificação em `StepCard`:

1. `config` nulo → `{ isComplete: false, reason: "Ação não configurada" }`.
2. Se `step_type` ∈ `["send_whatsapp","send_email","send_rcs","send_sms","send_voice","webhook","human_activity","negativation","notification","block"]` (**10** tipos):
   - sem `config.integration_id` → `reason: "Integração não selecionada"`;
   - com `validIntegrationIds` disponível e o ID **não** presente → `reason: "Integração inválida ou removida"`, `isIntegrationInvalid: true`.
3. Verificações específicas:
   - `send_whatsapp` / `send_email` / `send_rcs` / `send_sms`: sem `config.message` **e** sem `config.template_id` → "**Mensagem não configurada**".
   - `send_voice`: sem `config.script` → "**Script não configurado**".
   - `webhook`: sem `config.action` → "**Ação não configurada**".
4. Senão: completo.

> ⚠️ `condition`, `wait`, `trigger_ai` e `notification` **não** têm verificação específica além da de integração — ou seja, um `condition` sem campo configurado nunca aparece como "Incompleta".

### 6.6 `getDescription` — a linha secundária do card

| `step_type` | Texto |
|---|---|
| `send_whatsapp`, `send_email`, `send_rcs`, `send_sms` | `config.template_id` → `"Template: {id}"`; senão os primeiros 50 caracteres de `config.message`; senão "Configurar mensagem" |
| `send_voice` | `config.script` → primeiros 50 caracteres + `"..."`; senão "Configurar script" |
| `wait` | `"{duration} {dias\|horas\|minutos}"`; senão "Configurar tempo" |
| `condition` | `"{field} {operator} {value}"`; senão "Configurar condição" |
| `webhook` | `config.action`; senão "Configurar ação" |
| `trigger_ai` | `config.scenario`; senão "Configurar cenário" |
| demais | "Configurar" |
| `config` nulo | "Não configurado" |

> ⚠️ `"Template: {id}"` exibe o **UUID cru** do template, não o nome. Ponto de dor para o redesign.

### 6.7 Reordenação (drag & drop)

Biblioteca: `@dnd-kit/core` + `@dnd-kit/sortable`.

- Sensores: `PointerSensor` com `activationConstraint: { distance: 8 }` (evita arrastar em cliques acidentais) e `KeyboardSensor` com `sortableKeyboardCoordinates` (acessível por teclado).
- Estratégia: `verticalListSortingStrategy`. Detecção de colisão: `closestCenter`.
- **Um `SortableContext` por grupo** (`items = group.steps.map(s => s.id)`).
- `handleDragEnd`: identifica o grupo de origem e o de destino; **só permite reordenar dentro do mesmo grupo** (`activeGroup.key !== overGroup.key` → retorna sem fazer nada). Não existe arrastar um passo de um dia para outro.
- Recalcula: `arrayMove` + `updates = reorderedSteps.map((step, index) => ({ id: step.id, position_y: index * 10 }))`.
- Sem `onReorderSteps` (sem permissão de escrita), o drop é um no-op silencioso.

### 6.8 Rodapé da timeline

`px-4 py-3 border-t bg-background shrink-0 flex items-center justify-between gap-4`.

**Esquerda** — badges `outline gap-1 text-xs`:

| Badge | Ícone | Conteúdo |
|---|---|---|
| Grupos (modo etapa) | `Milestone h-3 w-3` | "{N} etapa(s)" |
| Grupos (modo dia) | `CalendarDays h-3 w-3` | "{N} dia(s)" + `" + cauda"` se existe grupo de cauda. **O grupo de cauda não conta como dia.** |
| Passos | `Zap h-3 w-3` | "{N} ação/ações" |
| Custo total | `DollarSign h-3 w-3`, `font-mono` | "~{formatBRL(soma dos custos de grupo)}/contato" — só quando há dados de custo |

**Direita** — botão `outline sm` com ícone `Plus`:
- Modo etapa: "**Adicionar Ação em Nova Etapa**"
- Modo dia: "**Adicionar Ação em Novo Dia**"

Este botão é o **genérico**: não carrega alvo. Sob perfil, a etapa é escolhida na fase "Quando" (que a exige).

### 6.9 Cálculo de custo

`useChannelCosts()` + `getCostForStepType(step_type, channelCosts)` e `stepIncludesAI(step_type)` (`src/lib/cost-calculator.ts`).

- Passo **inativo** custa `0` e não conta como IA.
- Custo do grupo = soma dos custos dos passos ativos.
- Custo total do rodapé = soma dos custos de grupo.
- Formatação: `formatBRL`.
- Sem `channelCosts` (ou lista vazia), `costData` é `null` e **nenhum** custo aparece.

### 6.10 Estado vazio da timeline

`steps.length === 0` → bloco centralizado `flex flex-col items-center justify-center py-12 text-center`:

- Ícone `GitBranch h-12 w-12 text-muted-foreground mb-4`
- `h3 text-lg font-medium`: "**Nenhuma ação configurada**"
- `p text-muted-foreground mt-1 max-w-md`: "Comece adicionando ações ao seu fluxo de cobrança. Você pode configurar mensagens, webhooks, atividades humanas e muito mais."
- Botão (só se `onAddStep`): `Plus` + "**Adicionar Primeira Ação**" (`mt-4`)

---

## 7. Wizard de passo — fase a fase

Fontes: `wizard/StepWizard.tsx`, `wizard/stepWizardPhases.ts`, `wizard/steps/*`.

### 7.1 Princípios de desenho declarados no código (IAF-7722)

1. **O passo só nasce no fim.** Não há escrita nenhuma antes do botão da fase "Revisar". Motivo histórico registrado no código: antes, "Adicionar" gravava um passo **ativo e vazio**, e configurá-lo era um segundo ato que podia nunca acontecer — havia 3 passos em produção `is_active = true` sem integração e sem etapa por causa disso.
2. **A fase "Quando" existe para TODO tipo.** É o que dá gatilho por etapa a `webhook`, `condition`, `wait` e `trigger_ai`, que nunca passavam pelo formulário de canal.
3. **A identidade da fase é o `phaseId`**, nunca o índice nem o título — a lista de fases muda com o tipo e com o modo.

### 7.2 Container

`DialogContent` com `flex h-[95vh] w-[95vw] max-w-none flex-col p-0`. Três faixas:

| Faixa | Classe | Conteúdo |
|---|---|---|
| Cabeçalho | `border-b bg-gradient-to-r from-primary/5 to-transparent px-6 py-4` | `DialogTitle` + `DialogDescription` |
| Stepper | `border-b bg-muted/30 px-6 py-4` | `WizardStepper` |
| Corpo | `relative flex-1 overflow-y-auto px-6 py-6` com `<div class="mx-auto max-w-3xl">` | a fase atual |
| Rodapé | `border-t bg-muted/30 px-6 py-4` | `WizardNavigation` |

**Título** (`title`):
- Alvo é cauda existente → "**Adicionar canal à cauda**"
- `mode === "edit"` → "**Configurar passo**"
- senão → "**Novo passo da régua**"

**Descrição**:
- edit → "Ajuste o passo e salve — as alterações valem para as próximas execuções."
- create → "**O passo é criado no final: nada é gravado até você concluir.**"

### 7.3 Composição das fases

`resolveStepWizardPhases({ stepType, profile, mode })`:

```
mode === "create"  →  push "action"
                      push "when"
                      se stepType definido:
                          canal   → push "integration", "content"
                          senão   → push "typeConfig"
                      push "review"

mode === "edit"    →  push "when"
                      (mesma lógica de tipo — stepType sempre definido)
                      push "review"
```

**Consequência**: a lista **cresce** quando o operador escolhe o tipo na fase 1. Isso é seguro porque o gate de `action` impede avançar antes da escolha. E a lista **encurta** quando se troca de canal para tipo de form próprio (2 fases → 1): há dois clamps (`phaseIdAt` e um `useEffect` que corrige `currentStep`).

**Contagem final de fases:**

| Modo | Tipo | Fases |
|---|---|---|
| create | (nenhum ainda) | Ação, Quando, Revisar = **3** |
| create | canal | Ação, Quando, Integração, Conteúdo, Revisar = **5** |
| create | webhook/condition/wait/trigger_ai | Ação, Quando, Configuração, Revisar = **4** |
| edit | canal | Quando, Integração, Conteúdo, Revisar = **4** |
| edit | webhook/condition/wait/trigger_ai | Quando, Configuração, Revisar = **3** |

### 7.4 Títulos e descrições das fases

| `phaseId` | Título | Descrição |
|---|---|---|
| `action` | **Ação** | "Escolha o tipo de ação e dê um nome ao passo" |
| `when` | **Quando** | Sob perfil: "Em que etapa o passo dispara — e por quantos dias nela". Sem perfil: "Em que dia de atraso o passo dispara" |
| `integration` | **Integração** | "Escolha por qual integração a ação será executada" |
| `content` | **Conteúdo** | "Escreva a mensagem que será enviada" |
| `typeConfig` | **Configuração** | "Parâmetros específicos deste tipo de passo" |
| `review` | **Revisar** | "Confira o resumo e ative o passo" |

### 7.5 Gates — o que bloqueia o avanço

| Fase | Gate | Função |
|---|---|---|
| `action` | Tipo escolhido (`stepType.trim() !== ""`) | `canProceedFromAction` |
| `when` (com perfil) | `isEtapaTriggerActive(p)` **e** `!isEtapaMinDaysInvalid` **e** `!isEtapaMaxDaysInvalid` **e** `!isEtapaWindowInvalid` | `canProceedFromWhen` |
| `when` (sem perfil) | `isTriggerRangeValid(trigger)` — inválido só quando `mode === "range"` e `max !== null` e `max < min` | idem |
| `integration` | `channel.integration_id.trim() !== ""` — **só** a integração; template HSM é opcional | `canProceedFromIntegration` |
| `content` | `isChannelStepValid(channel, channelType)` | `canProceedFromContent` |
| `typeConfig` | `typeConfigValid === true` — ou seja, o formulário interno aplicou os campos via botão "Salvar Configurações" | — |
| `review` | **Todas as fases anteriores que existem para este tipo** (deriva de `resolveStepWizardPhases` com `mode: "create"`, o superconjunto) | `canProceedFromReview` |

**Fail-closed declarado**: `StepWizardGateState` é `Partial<StepWizardState>`; fatia ausente **nunca** libera a fase.

**Gate extra — `profileKeysInvalid`** (no `StepWizard`, não no módulo puro): quando `profileActive` e a etapa está ativa e alguma das três validações de janela falha. Existe para o **escape hatch** — org **sem** perfil cujo passo carrega chaves de perfil (hand-edit, import, ou perfil removido da org). Sem isso daria para salvar uma janela invertida (`min > max`), que deixa o passo **mudo para sempre** (o motor é fail-closed nesse ponto).

### 7.6 Navegação — as diferenças entre criar e editar

| Aspecto | `mode="create"` | `mode="edit"` |
|---|---|---|
| Navegação pelo stepper | **Linear**: só permite clicar em fase **anterior** (`target < currentStep`) | **Livre** (`allowFreeNavigation`): clica em qualquer fase |
| Botão principal do rodapé | "**Continuar**" até a última fase; "**Criar passo**" na última | "**Salvar**" em toda fase (`alwaysAllowSubmit`), "**Salvar alterações**" na última |
| Gate do botão (`canProceed`) | Gate da **fase atual** | Gate do **conjunto** (`submitGate`) — salvar de uma fase intermediária não pode gravar passo inválido |
| Marcas de conclusão | Fase anterior a `currentStep` e válida | **Qualquer** fase válida |
| Marcas de erro (`errorSteps`) | vazio | Toda fase (exceto `review`) que falha o gate vira **ponto vermelho no stepper** |

> Esse ponto vermelho é o mecanismo de diagnóstico: um passo meio configurado abre o wizard já mostrando **onde** está faltando algo.

> Nota sobre `typeConfig` em edição: mesmo quando o passo é válido no banco, a fase entra em `errorSteps` até o operador clicar "Salvar Configurações" — porque os quatro formulários de tipo só entregam os campos por aquele botão, e antes do clique o wizard não sabe o que gravar.

### 7.7 Inicialização e re-hidratação

Guarda por **assinatura**, não por identidade de objeto: `initSignature = "{mode}|{step.id}|{JSON.stringify(target)}"`.

Motivo declarado: `step` vem de uma query e pode virar um objeto novo com o **mesmo id** a cada refetch — reinicializar ali apagaria o que o operador digitou.

Ao inicializar (`mode === "edit"`):
- `stepType` ← `step.step_type`; `name` ← `step.name ?? ""`; `isActive` ← `step.is_active ?? true`
- `profileStep` ← `parseProfileStepConfig(step.config)`
- `channelValue` ← `parseChannelStepConfig(config, canal, nome)`
- `trigger` ← `parseTriggerConfig(config)`; `isCaudaMode` ← `trigger.mode === "range"`
- `typeConfigFields` ← `null` (obriga reaplicar)

Ao inicializar (`mode === "create"`):
- Tudo vazio; `isActive = true`
- `profileStep` ← `applyEtapaTarget(parseProfileStepConfig(null), target)` — herda a etapa do grupo de origem
- `trigger` ← de `targetToRangeValue(target)`: alvo `cauda` → modo `range` com faixa/cadência herdadas; alvo `day` → modo `exact` com o dia do grupo; alvo `etapa` ou ausente → `exact` em `0`

**Etapa travada (`lockedEtapa`)**: só em `mode === "create"` com `target.kind === "etapa"` e etapa não vazia. Na edição o passo **pode** mudar de etapa (e assim mudar de grupo) — travar tiraria a única forma de fazer isso pela tela. A **janela** de dias continua editável nos dois modos (é por passo).

### 7.8 Fase 1 — "Ação" (`ActionStep`)

Só existe em `mode="create"`. Em edição o tipo não se troca (o código explica: "trocar de tipo é apagar e criar outro, no motor e na auditoria").

**Campo 1 — Tipo de ação** (`Label` "Tipo de ação"). `RadioGroup` organizado em **três categorias**, nesta ordem:

| Categoria | Cabeçalho (`text-xs font-medium uppercase text-muted-foreground`) | Opções |
|---|---|---|
| `communication` | **Comunicação** | WhatsApp, E-mail, RCS, SMS, Voz/TTS |
| `integration` | **Integração** | Webhook |
| `action` | **Ações** | Atividade Humana, Notificacao, Negativação, Bloqueio |

Cada opção é um `<label htmlFor>` com `flex cursor-pointer items-center gap-3 rounded-lg border p-4 transition-colors`:
- Selecionado: `border-primary bg-primary/5`; não selecionado: `hover:bg-muted/50`
- `RadioGroupItem` em `sr-only` (visualmente escondido, acessível)
- Ícone `h-5 w-5 text-muted-foreground`
- Rótulo `text-sm font-medium` + descrição `text-xs text-muted-foreground`

**Catálogo completo** (`STEP_TYPE_OPTIONS`):

| `type` | Rótulo | Descrição | Ícone |
|---|---|---|---|
| `send_whatsapp` | WhatsApp | "Enviar mensagem via WhatsApp" | `MessageCircle` |
| `send_email` | E-mail | "Enviar email automatizado" | `Mail` |
| `send_rcs` | RCS | "Enviar mensagem rica (RCS): imagem, texto e botões" | `MessageSquare` |
| `send_sms` | SMS | "Enviar mensagem de texto SMS" | `Smartphone` |
| `send_voice` | Voz/TTS | "Realizar ligação automatizada com TTS" | `Phone` |
| `webhook` | Webhook | "Disparar webhook para sistema externo" | `Webhook` |
| `human_activity` | Atividade Humana | "Criar tarefa manual para operador" | `User` |
| `notification` | Notificacao | "Enviar notificacao extrajudicial" | `FileWarning` |
| `negativation` | Negativação | "Negativar cliente em órgãos de proteção" | `AlertTriangle` |
| `block` | Bloqueio | "Bloquear serviço ou equipamento" | `Ban` |

> ⚠️ **`condition` e `wait` NÃO estão no catálogo de criação.** Existem no motor, no `StepCard` (ícone/cor/rótulo), no `stepWizardPhases` (caem em `typeConfig`) e têm formulário próprio (`ConditionConfigForm`, `WaitConfigForm`), mas **não há como criá-los pela tela**. Só é possível editá-los se já existirem. ⚠️ A confirmar se isso é intencional.
>
> ⚠️ **Ortografia inconsistente no catálogo**: "Notificacao" e "notificacao extrajudicial" sem cedilha/til, enquanto "Negativação" está acentuada. O `StepCard` usa "Notificação" (correto). Candidato a correção no redesign.

**Campo 2 — Nome do passo (opcional)**: `Input` `id="step-wizard-name"`, `placeholder` = rótulo do tipo escolhido, ou "Ex: Lembrete de Pagamento" se nada escolhido. Texto de ajuda: "Aparece no card do passo, na timeline. Em branco, usamos "{Rótulo}"." (ou "o nome do tipo escolhido").

### 7.9 Fase 2 — "Quando" (`WhenStep`)

**Três mundos, nesta ordem de precedência:**

#### (1) Alvo = cauda existente (`isCaudaTarget`)

Um `ReadOnlyPanel` (`flex items-start gap-2 rounded-md border border-dashed bg-muted/30 p-3`, ícone `Info h-4 w-4`) com:

> **{describeCaudaTrigger(min, max, repeat)}** — faixa e cadência do grupo. Para alterá-las, use "Editar" no cabeçalho do grupo na timeline.

Nenhum campo editável de dia. **Invariante declarada**: faixa/cadência de cauda **não** se edita no wizard (uma versão anterior tentou e foi revertida).

#### (2) Org com perfil `formalizacao` (`orgHasProfile`)

`renderDayBlock()` retorna `null` — **nenhum campo de dia, nenhum switch de cauda**. Só o `ProfileStepTriggerFields` (ver §9.5).

Justificativa no código: "sem campo de dia desaparece o estado 'ainda não escolhi, então grava dia 0'".

#### (3) Org sem perfil — o comportamento de cobrança

Sub-casos, na ordem de teste:

| Sub-caso | Render |
|---|---|
| Passo carrega `etapa_trigger` mas a org não tem perfil | `ReadOnlyPanel`: "Este passo dispara pela **etapa** configurada abaixo. Enquanto houver uma etapa, o gatilho por dia de atraso (dia exato ou faixa) **não é gravado** neste passo — apague a etapa para voltar a disparar por dia." |
| `mode === "edit"` e passo é de cauda | `ReadOnlyPanel`: "Este passo é de **cauda** (faixa de dias com cadência). A faixa e a cadência são configuradas no cabeçalho do grupo, na timeline — não aqui." |
| `mode === "edit"` e passo é de dia exato | `DaysOverdueInput` editável |
| `mode === "create"` | Bloco completo (abaixo) |

**Bloco de criação (org sem perfil):**

1. **Switch "Step de cauda (faixa de dias com cadência)"** num container `flex items-center justify-between gap-4 rounded-lg border p-3`:
   - Descrição: "Em vez de um dia exato, este passo cobre uma faixa de dias (ex.: de X em diante) e repete conforme a cadência configurada."
   - Se `caudaJaExiste`: mensagem `text-xs text-amber-700` — "Esta régua já tem um step de cauda. Para adicionar um canal a ela, use "Adicionar canal" no cabeçalho do grupo, na timeline." — e o `Switch` fica `disabled`.
   - `id="wizard-cauda-toggle"`, `aria-label` igual ao rótulo.
2. **Se ligado**: `DaysOverdueRangeInput` com `hideModeToggle`.
3. **Se desligado**: `DaysOverdueInput` + texto de ajuda "Use valores negativos para ações antes do vencimento."

**Ao alternar o switch** (`handleCaudaModeChange`): muda `trigger.mode` para `"range"`/`"exact"` e, ao ligar, copia `exact` para `min`.

#### Campos de perfil (`profileActive`)

Renderizados **abaixo** do bloco de dia sempre que `profileActive = orgProfile !== null || hasProfileStepConfig(step.config)`. Esconder de um passo que os usa deixaria configuração ativa e invisível.

### 7.10 Fase 3 — "Integração" (`IntegrationStep`)

Só para tipos de canal. Conteúdo (`space-y-5`):

1. **`IntegrationSelector`** — lista de integrações **ativas** do canal (`useIntegrations({ type: channel, isActive: true })`).
2. **Aviso de ausência** (quando `!isLoading` e `integrations.length === 0`): bloco `border-amber-200 bg-amber-50 p-3` com `AlertTriangle` — "Nenhuma integração ativa deste canal nesta organização. Sem integração o passo não pode ser salvo — cadastre uma em Integrações antes de continuar."
3. **`TemplateHSMSelector`** — **só para `whatsapp` e `rcs`**. Ao selecionar, popula de uma vez: `activation_template_id`, `template_content`, `meta_template_name`, `meta_components` e `template_variable_map` (mapa inicializado com `""` para cada variável detectada).

### 7.11 Fase 4 — "Conteúdo" (`ContentStep`)

Layout: `grid gap-6` com `lg:grid-cols-2` quando o canal tem prévia (`whatsapp`, `rcs`, `sms`, `email`, `voice`), senão `grid-cols-1`.

**Coluna esquerda** (`space-y-5`), na ordem:

1. **`MetaVariableMapper`** — só quando há `meta_template_name` **e** o template tem variáveis. Exemplos vêm do componente `BODY` do template Meta (`example.body_text[0]`), mapeados por índice 1-based.
2. **Assunto do e-mail** — só para `channel === "email"`: `Label` "Assunto do e-mail" + `RichVariableInput` (`rows={1}`, `variableContext="workflow"`, placeholder "Ex: Lembrete de pagamento - Título {{title.number}}").
   > Nota do código: o assunto mora **aqui** e não na fase de integração porque `isChannelStepValid` (o gate desta fase) o exige — deixá-lo na fase anterior faria o gate reprovar sem nada visível na tela que o explicasse.
3. **Editor de corpo**:
   - `email` → `EmailTemplateEditor` (aceita HTML fonte)
   - demais → `TemplateEditor` com `showAIAssistant`, `aiScenario="negotiation"`, `aiChannel` (quando suportado), `aiMaxLength = meta.showCharWarning`, `variableContext="workflow"`
4. **Aviso de comprimento** — quando `meta.showCharWarning` e `message.length >` limite: bloco `border-amber-200 bg-amber-50 p-3` com `AlertTriangle` e `meta.charWarningMessage`.
5. **Dica do canal** — quando `meta.tipMessage`: bloco `border-blue-200 bg-blue-50 p-3` com ícone `Lightbulb`.
6. **Opções Avançadas** (só `voice` com `hasAdvancedOptions`): `Collapsible` com trigger `ghost` de borda tracejada, rótulo "Opções Avançadas" (`Settings2`) e `ChevronDown` que rotaciona 180°. Dentro (`rounded-lg border bg-muted/30 p-4`):
   - **Tipo de Voz**: dois botões `sm` — "Feminina" / "Masculina" (o selecionado usa `variant="default"`, o outro `outline`).
   - **Idioma**: `Input` `max-w-[150px]`, placeholder `pt-BR`.

**Coluna direita** (`lg:sticky lg:top-4 lg:self-start`): `TemplateMessagePreview` com `channel`, `message`, `subject`, `metaComponents` (quando há template Meta **ou** canal é `rcs`) e `templateVariableMap` (só quando há template Meta).

**Canais com assistente de IA** (`AI_SUPPORTED_CHANNELS`): `whatsapp`, `sms`, `email`, `voice`. **RCS não tem.**

### 7.12 Fase 5 — "Configuração" (`TypeConfigStep`)

Para `webhook`, `condition`, `wait`, `trigger_ai`. Tipo desconhecido cai aqui também, com um bloco `border-dashed p-4 text-center` — "Tipo de passo não reconhecido: {stepType}".

**Faixa de estado no topo** (`rounded-md border border-dashed bg-muted/30 p-3`):

| Estado | Ícone | Texto |
|---|---|---|
| Não aplicado | `Info` (muted) | "Preencha os campos abaixo e clique em **Salvar Configurações** para aplicar a configuração ao passo. Nada é gravado ainda: a gravação acontece no final do wizard." |
| Aplicado (`committed`) | `Check` (primary) | "Configuração aplicada a este passo. O passo só é gravado ao concluir o wizard — se alterar algo abaixo, clique em **Salvar Configurações** novamente." |

Os quatro formulários são **reusados intactos**: cada um mantém seu estado interno e seu próprio botão "Salvar Configurações". Esse botão **deixou de gravar no banco** e passou a aplicar os campos ao estado do wizard. Além dos campos, ele também devolve o `label`, que sobrescreve o `name` do passo se não for vazio.

### 7.13 Fase 6 — "Revisar" (`ReviewStep`)

O passo **nasce aqui**. Conteúdo (`space-y-5`), na ordem:

**1. Nome do passo** — `Input` `id="step-wizard-review-name"`, placeholder = rótulo do tipo. (É o **segundo** ponto de edição do nome; o primeiro é a fase "Ação".)

**2. Cartão de resumo** — `rounded-lg border` com quatro `SummaryRow` (cada uma: `flex flex-col gap-1 border-b px-4 py-3 last:border-b-0 sm:flex-row sm:items-baseline sm:gap-4`; rótulo `w-28 shrink-0 text-xs font-medium uppercase text-muted-foreground`):

| Rótulo | Conteúdo |
|---|---|
| **Ação** | Rótulo do tipo + `<code>` com o `step_type` cru. Fallback: o `stepType` ou "—". |
| **Quando** | Com etapa ativa: `formatEtapaLabel(etapa)` + `<code>` com o valor cru + linha `text-xs text-muted-foreground` com `describeEtapaWindow`. Cauda: `describeCaudaTrigger`. Dia exato: `describeDay(exact)`. |
| **Integração** | Nome da integração encontrada em `useIntegrations`, ou o ID cru como fallback, ou "**Não definida**" (muted). |
| **Conteúdo** | Template Meta → "Template Meta: {nome}". RCS com template → "Template RCS selecionado". Texto livre → os primeiros 140 caracteres + "…". Form de tipo → "Configuração do tipo aplicada". Nada → "**Não definido**" (muted). |

**3. Aviso de sobreposição — nível ALERTA (mesmo canal)**

Só aparece sob gatilho por **etapa**. Bloco `border-amber-200 bg-amber-50 p-3` com `AlertTriangle`:

- Título: "Outro passo desta etapa envia pelo mesmo canal nos mesmos dias" (1) ou "{N} passos desta etapa enviam pelo mesmo canal nos mesmos dias".
- Corpo: "Em cada dia em comum o contato recebe **duas mensagens do mesmo canal**: sob este perfil a deduplicação é escopada por passo, e a regra de prioridade não separa dois passos da mesma etapa (eles têm o mesmo número de dias na etapa). Pode ser intencional — dois textos diferentes no mesmo dia. **Este é um aviso, não um impedimento.**"
- Lista, um item por passo em conflito: nome (negrito) · janela do irmão · "{N} dia(s) em comum ({descrição})" ou "em comum {descrição}" quando a interseção é aberta · `Badge` outline "**mesmo canal e integração**" ou "**mesmo canal**".

**4. Aviso de sobreposição — nível INFORMATIVO (canal diferente)**

Bloco `border-dashed bg-muted/30 p-3` com `Info`:

- Título: "Neste intervalo o contato recebe por mais de um canal no mesmo dia"
- Corpo: "Outro passo desta etapa cobre dias em comum com este, por um canal diferente. Todas as ações são criadas — nada é descartado na execução."
- Lista: nome · janela · "em comum {descrição}"

> **Por que dois níveis**: o código explica que sobrepor janelas em canais **diferentes** é arranjo legítimo e comum; acender alerta nele ensinaria o operador a ignorar o aviso.

**Cálculo da sobreposição:**
- Considera só irmãos **ativos** (`is_active !== false`), com a **mesma etapa** e `id !== editingStepId`.
- Intersecção: `mine.min <= theirs.max && theirs.min <= mine.max`, com ausência virando ±Infinity (`etapaWindowBounds`).
- Rótulos (`describeOverlap`): ambos infinitos → "todos os dias na etapa" (`days: null`); só o início infinito → "até o dia {end}"; só o fim infinito → "do dia {start} em diante"; ambos finitos → "no dia {start}" (1 dia) ou "do dia {start} ao dia {end}".
- `sameIntegration` só é `true` quando **ambas** as integrações são conhecidas e iguais — por isso o badge distingue "mesmo canal" de "mesmo canal e integração".

**5. Destinatário** (só quando `profileActive`) — `rounded-lg border p-4`:

- `Label` com ícone `Send h-4 w-4` + "Destinatário"
- `RadioGroup` com duas opções:
  - **O próprio contato** (`owner`): "{E-mail|Telefone} do cadastro do contato (padrão)."
  - **Endereço da variável do perfil** (`variable`): quando a org declara o campo, "{E-mail|Telefone} de `{campo}`. O contato continua sendo o cliente — só a entrega muda de endereço."; senão "{E-mail|Telefone} configurado no perfil da organização."
- O campo lido é `recipient_email_field` para `email` e `recipient_phone_field` para os demais canais.
- **Mesmo estado** do radio da fase "Quando" — não há segunda fonte de verdade.

**6. Ativar este passo agora** — `flex items-start justify-between gap-4 rounded-lg border p-4`:

- `Label` "Ativar este passo agora"
- Ajuda: "Ligado, o passo passa a ser avaliado nas próximas execuções da régua. Desligado, ele fica guardado sem disparar — e você pode ligá-lo depois no card do passo."
- `Switch` `id="step-wizard-active"`, `aria-label` igual ao rótulo. Default: `true` na criação; na edição, o `is_active` atual.

> **Invariante de motor**: esse switch vale a **coluna** `workflow_steps.is_active`, nunca `config.is_active`. A confusão entre as duas é regressão conhecida (IAF-4400/4406/4607: passos "desligados" na UI seguiram disparando).

### 7.14 Composição do `config` no submit (`buildConfig`)

Uma escrita só, no fim, juntando as famílias na ordem:

```
etapaOnly = profileActive && isEtapaTriggerActive(profileStep)
triggerFields = etapaOnly ? {} : buildTriggerConfig(trigger)
profileFields = buildProfileStepConfig(profileStep)

canal:      { ...triggerFields, ...profileFields, ...buildChannelStepConfig(channelValue, channelType) }
form tipo:  { ...triggerFields, ...profileFields, ...(typeConfigFields ?? {}) }
```

**O config é reconstruído por inteiro a cada save** — não há merge com o config anterior. Consequência documentada: chaves desconhecidas no config **se perdem**. O código registra que isso é o comportamento atual a preservar, e que trocar por merge seria "melhoria REAL, mas mudança de comportamento não pedida".

Nome final: `name.trim() || defaultNameFor(stepType)` (o rótulo do catálogo).

**Tratamento de falha no submit**: o `catch` é vazio de propósito — o caller já avisa por toast e o wizard **permanece aberto**, preservando o que foi preenchido.

---

## 8. Catálogo de tipos de passo

### 8.1 Tabela mestre

Fontes: `timeline/StepCard.tsx` (ícone/cor/rótulo na timeline), `wizard/steps/ActionStep.tsx` (catálogo de criação), `wizard/stepWizardPhases.ts` (roteamento de fases), `config-forms/channelStepConfig.ts` (`CHANNEL_META`), `src/types/reguas-cobranca.ts` (`STEP_TYPES` — ver nota em §8.3).

| `step_type` | Rótulo na timeline | Ícone | Classe de cor do card | Criável pela UI? | Fases de config | Campos exclusivos |
|---|---|---|---|---|---|---|
| `send_whatsapp` | WhatsApp | `MessageCircle` | `bg-green-100 text-green-700 border-green-200` | sim (Comunicação) | Integração + Conteúdo | `integration_id`, `message`, `activation_template_id`/`template_id`, `template_content`, `meta_template_name`, `meta_components`, `template_variable_map` |
| `send_email` | E-mail | `Mail` | `bg-red-100 text-red-700 border-red-200` | sim (Comunicação) | Integração + Conteúdo | `integration_id`, `subject`, `message` (HTML fonte validado) |
| `send_rcs` | RCS | `MessageSquare` | `bg-teal-100 text-teal-700 border-teal-200` | sim (Comunicação) | Integração + Conteúdo | `integration_id`, `message` (fallback), `activation_template_id`/`template_id`, `meta_components`, `template_variable_map` |
| `send_sms` | SMS | `Smartphone` | `bg-blue-100 text-blue-700 border-blue-200` | sim (Comunicação) | Integração + Conteúdo | `integration_id`, `message` (aviso em 160 caracteres) |
| `send_voice` | Ligação | `Phone` | `bg-purple-100 text-purple-700 border-purple-200` | sim (Comunicação, rótulo "Voz/TTS") | Integração + Conteúdo | `integration_id`, `message` (script TTS), `voice_type` (`male`/`female`), `language` |
| `webhook` | Webhook | `Webhook` | `bg-indigo-100 text-indigo-700 border-indigo-200` | sim (Integração) | Configuração (form próprio) | `action`, `integration_id`, `payload` |
| `human_activity` | Atividade Humana | `User` | `bg-cyan-100 text-cyan-700 border-cyan-200` | sim (Ações) | Integração + Conteúdo | `integration_id`, `message` (descrição da atividade) |
| `notification` | Notificação | `FileWarning` | `bg-yellow-100 text-yellow-700 border-yellow-200` | sim (Ações, rótulo "Notificacao") | Integração + Conteúdo | `integration_id`, `message` (observações) |
| `negativation` | Negativação | `AlertTriangle` | `bg-orange-100 text-orange-700 border-orange-200` | sim (Ações) | Integração + Conteúdo | `integration_id`, `message` (observações) |
| `block` | Bloqueio | `Ban` | `bg-rose-100 text-rose-700 border-rose-200` | sim (Ações) | Integração + Conteúdo | `integration_id`, `message` (motivo) |
| `condition` | Condição | `GitBranch` | `bg-violet-100 text-violet-700 border-violet-200` | **não** | Configuração (form próprio) | `field`, `operator`, `value` |
| `wait` | Aguardar | `Clock` | `bg-amber-100 text-amber-700 border-amber-200` | **não** | Configuração (form próprio) | `duration`, `unit` |
| `trigger_ai` | Agente IA | `Bot` | `bg-emerald-100 text-emerald-700 border-emerald-200` | **não** | Configuração (form próprio) | `days_overdue_trigger`, `ai_version_id`, `channel`, `context`, `max_interactions` |
| *(desconhecido)* | o próprio `step_type` | `AlertCircle` | `bg-gray-100 text-gray-700 border-gray-200` | — | Configuração ("Tipo de passo não reconhecido") | — |

### 8.2 Mapa tipo → canal (`STEP_TYPE_TO_CHANNEL`)

Nove tipos usam as fases de canal:

```
send_whatsapp  → whatsapp
send_email     → email
send_rcs       → rcs
send_sms       → sms
send_voice     → voice
human_activity → human_activity
negativation   → negativation
notification   → notification
block          → block
```

> **Nota importante do código**: `webhook` **não** está no mapa, embora `ChannelType` tenha uma entrada `webhook` (integração HTTP) e `CHANNEL_META` tenha os textos dela. O **passo** `webhook` usa formulário próprio. O comentário explica: derivar "é canal" de `CHANNEL_META` mandaria o webhook para as fases de integração/conteúdo, que não sabem configurá-lo.

### 8.3 Divergência com `src/types/reguas-cobranca.ts`

O arquivo de tipos declara `STEP_TYPES: StepTypeMetadata[]` com **9** entradas, com `icon` (nome em string), `color` (**hex**), `category` e `requiresIntegration`:

| `type` | label | icon | color | category | requiresIntegration |
|---|---|---|---|---|---|
| `send_whatsapp` | WhatsApp | `MessageCircle` | `#25D366` | communication | sim |
| `send_email` | E-mail | `Mail` | `#EA4335` | communication | sim |
| `send_rcs` | RCS | `Smartphone` | `#0F9D8C` | communication | sim |
| `send_sms` | SMS | `Smartphone` | `#4285F4` | communication | sim |
| `send_voice` | Ligação | `Phone` | `#9333EA` | communication | sim |
| `wait` | Aguardar | `Clock` | `#F59E0B` | logic | não |
| `condition` | Condição | `GitBranch` | `#8B5CF6` | logic | não |
| `webhook` | Webhook | `Webhook` | `#6366F1` | integration | sim |
| `trigger_ai` | Agente IA | `Bot` | `#10B981` | ai | não |

> ⚠️ **Essa tabela não é usada pela timeline nem pelo wizard.** O `StepCard` tem seus próprios mapas (`STEP_ICONS`, `STEP_COLORS`, `STEP_LABELS`) com classes Tailwind, e o `ActionStep` tem seu próprio `STEP_TYPE_OPTIONS`. Há portanto **três catálogos paralelos** de tipo de passo no repositório. Consolidar é oportunidade evidente para o redesign (ver §20).
>
> ⚠️ `AVAILABLE_VARIABLES` em `src/types/reguas-cobranca.ts` também parece órfã: declara 11 variáveis (`contact.name`, `contact.document`, `contract.number`, `contract.modality`, `title.number`, `title.due_date`, `title.value`, `title.days_overdue`, `total_debt`, `pix_link`, `boleto_link`) com rótulo e exemplo, mas o editor de conteúdo usa `VariableInserter`/`RichVariableInput` com `variableContext="workflow"`. ⚠️ A confirmar qual é a fonte viva.

### 8.4 Metadados de canal (`CHANNEL_META`)

Estes textos definem o formulário de conteúdo por canal.

| Canal | `defaultLabel` | `templateLabel` | `templateRows` | `showCharWarning` | `tipMessage` | `hasAdvancedOptions` |
|---|---|---|---|---|---|---|
| `whatsapp` | Mensagem WhatsApp | Mensagem WhatsApp | — (default) | — | — | — |
| `rcs` | Mensagem RCS | Texto do card (fallback) | 4 | — | "O conteúdo (imagem, texto e botões) vem do template RCS selecionado." | — |
| `sms` | Mensagem SMS | Mensagem SMS | 4 | **160** | — | — |
| `email` | E-mail de cobrança | Corpo do e-mail | 8 | — | — | `false` |
| `voice` | Ligação de Voz/TTS | Mensagem de Voz (TTS) | 6 | — | "Mantenha a mensagem clara e objetiva. O sistema converterá o texto em áudio automaticamente." | **`true`** |
| `human_activity` | Atividade Humana | Descrição da Atividade | 4 | — | "Esta tarefa será criada automaticamente na fila do operador responsável." | — |
| `negativation` | Negativação | Observações da Negativação | 3 | — | "A negativação será processada de acordo com a integração configurada." | — |
| `notification` | Notificação | Observações da Notificação | 3 | — | "A notificação será processada de acordo com a integração configurada." | — |
| `block` | Bloqueio | Motivo do Bloqueio | 3 | — | "O bloqueio será executado automaticamente via integração configurada." | — |
| `webhook` | Webhook | Payload do Webhook | 6 | — | "O webhook será disparado automaticamente quando este passo for executado." | — |

**Descrições e placeholders:**

| Canal | `templateDescription` | `templatePlaceholder` |
|---|---|---|
| `whatsapp` | "Personalize a mensagem com variáveis do contato e título" | "Olá {{contact.name}}, identificamos um título em atraso no valor de {{title.value}}..." |
| `rcs` | "O corpo da mensagem vem do texto do template RCS selecionado acima. Este campo só é usado quando o template não tem texto." | "Olá {{contact.name}}, sua fatura de {{title.value}} venceu." |
| `sms` | "Mensagens SMS têm limite de 160 caracteres" | "{{contact.name}}, seu título vence em {{title.due_date}}. Pague em: [link]" |
| `email` | "Personalize o conteúdo do email com variáveis" | "Prezado(a) {{contact.name}},\n\nIdentificamos que você possui um título em aberto..." |
| `voice` | "Texto que será convertido em voz e reproduzido na ligação" | "Olá {{contact.name}}, esta é uma ligação automática da empresa X..." |
| `human_activity` | "Descreva a tarefa que o operador deve executar" | "Realizar ligação para {{contact.name}} para negociação do título no valor de {{title.value}}..." |
| `negativation` | "Notas internas sobre a negativação (opcional)" | "Cliente {{contact.name}} negativado após 30 dias de inadimplência..." |
| `notification` | "Notas internas sobre a notificação (opcional)" | "Notificação formal para {{contact.name}} referente ao título no valor de {{title.value}}..." |
| `block` | "Descreva o motivo do bloqueio (opcional)" | "Bloqueio de serviço por inadimplência no valor de {{title.value}}..." |
| `webhook` | "Dados que serão enviados para o endpoint externo" | `{"contact_id": "{{contact.id}}", "title_value": "{{title.value}}"}` |

**Aviso de comprimento (SMS)**: "Mensagem possui mais de 160 caracteres e será enviada em múltiplas partes".

---

## 9. Formulários de configuração por tipo

### 9.1 Configuração de canal (`channelStepConfig.ts` + `IntegrationStep` + `ContentStep`)

Não é um componente único — as fases do wizard montam o formulário. O **estado** é `ChannelStepValue`, sempre preenchido com defaults explícitos:

| Campo do estado | Tipo | Default ao ler config vazio |
|---|---|---|
| `label` | `string` | `CHANNEL_META[channel].defaultLabel` |
| `integration_id` | `string` | `""` |
| `message` | `string` | `""` |
| `activation_template_id` | `string` | `""` |
| `template_content` | `string` | `""` |
| `subject` | `string` | `""` |
| `voice_type` | `"male" \| "female"` | **`"female"`** |
| `language` | `string` | **`"pt-BR"`** |
| `meta_template_name` | `string` | `""` |
| `meta_components` | `MetaComponent[]` | `[]` |
| `template_variable_map` | `Record<string,string>` | `{}` |

**O que é gravado por canal** (`buildChannelStepConfig`):

| Canal | Chaves emitidas |
|---|---|
| todos | `integration_id`, `message` |
| `whatsapp`, `rcs` — **só com template escolhido** | `activation_template_id`, `template_id` (espelho, é o que o `send-message` lê no RCS), `template_content`, e condicionalmente `meta_template_name`, `meta_components`, `template_variable_map` |
| `email` | `subject` |
| `voice` | `voice_type`, `language` |

**Validação (`isChannelStepValid`)**, na ordem:

1. `integration_id` vazio → **inválido**.
2. Se há `meta_template_name`: **todas** as variáveis numeradas do template (`{{1}}`, `{{2}}`...) precisam ter mapeamento não-vazio → senão inválido. (Com template Meta, `message` é **opcional** — o template *é* a mensagem.)
3. Senão, se `rcs` com `activation_template_id`: `message` é opcional (o conteúdo vem do card).
4. Senão: `message` vazio → inválido.
5. `email` sem `subject` → inválido.
6. `email` com HTML inválido (`renderEmailHtml(message).errors.length > 0`) → inválido.

> **Detecção de variáveis Meta** (`metaTemplateVariables`): varre `component.text` de todos os `meta_components` com `/\{\{(\d+)\}\}/g` e devolve os números únicos ordenados numericamente. Exportada de propósito para que a validação e o `MetaVariableMapper` usem **a mesma lista**.

> **Leitura não gateada por canal** (`parseChannelStepConfig`): um config que carrega chave de outro canal (hand-edit, import, `restore_workflow_steps` de versão antiga, passo que trocou de tipo) **aparece na tela e sobrevive ao round-trip**. Quem decide o que é gravado é o `build`.

### 9.2 `WebhookConfigForm`

Fonte: `config-forms/WebhookConfigForm.tsx`. Estado local próprio; aplica via botão.

| Campo | Componente | Opções | Default |
|---|---|---|---|
| **Nome do Passo** | `Input` `id="node-label"`, placeholder "Ex: Criar tarefa de cobrança" | — | `label` recebido ou `"Ação Webhook"` |
| *(separador)* | `Separator` | — | — |
| **Tipo de Ação** | `Select` (rótulo com ícone `Webhook`, ajuda "Selecione o tipo de ação que será executada") | `human_task` → "Human Task" / "Criar tarefa manual"; `negativacao` → "Negativação" / "Enviar para negativação"; `bloqueio` → "Bloqueio" / "Bloquear equipamento"; `custom` → "Custom" / "Webhook customizado" | **`custom`** |
| *(separador)* | `Separator` | — | — |
| **Payload (JSON)** | `RichVariableInput` `rows={8}` `showPreview`, descrição "Configure os dados que serão enviados no webhook. Use variáveis para personalizar.", placeholder `{"contact_id": "{{contact.document}}", "action": "create_task"}` | — | `"{}"` |

**Validação**: `isValid = action && payload` (payload não-vazio; **o JSON não é parseado/validado**).
**Botão**: "Salvar Configurações" (`Save`), `w-full`, container `sticky bottom-0 pt-4 bg-background border-t`.

> ⚠️ **Divergência de nomenclatura**: o `WebhookConfig` do formulário usa `action: "human_task" | "negativacao" | "bloqueio" | "custom"`, enquanto `src/types/reguas-cobranca.ts` declara `WebhookConfig.action: "create_human_task" | "negativation" | "custom"`. Os dois não batem. ⚠️ A confirmar qual o motor lê.
>
> ⚠️ O formulário declara `integration_id` no seu config e o emite no save, mas **não oferece campo** para escolhê-lo. Em `mode="create"` o valor nasce `""` — e como `webhook` está na lista de tipos que exigem integração do `hasIncompleteSteps`, o passo nasce marcado "Incompleta" e **bloqueia a publicação da régua**, sem nenhum lugar na tela para corrigir. Item crítico para o redesign.

### 9.3 `ConditionConfigForm`

Fonte: `config-forms/ConditionConfigForm.tsx`.

| Campo | Componente | Opções | Default |
|---|---|---|---|
| **Nome do Passo** | `Input`, placeholder "Ex: Verificar dias de atraso" | — | `"Condição"` |
| **Campo** | `Select`, placeholder "Selecione um campo" | `title.days_overdue` → "Dias em Atraso"; `title.value` → "Valor do Título"; `contact.segment` → "Segmento do Cliente"; `portfolio.name` → "Carteira"; `contract.modality` → "Modalidade" | `""` |
| **Operador** | `Select` | `==` "Igual a (==)"; `!=` "Diferente de (!=)"; `>` "Maior que (>)"; `>=` "Maior ou igual (>=)"; `<` "Menor que (<)"; `<=` "Menor ou igual (<=)"; `contains` "Contém" | **`==`** |
| **Valor** | `Input` texto, placeholder "Ex: 10" | — | `""` |

Cabeçalho da seção: ícone `GitBranch` + "Condição de Bifurcação", ajuda "Define a condição que separa o fluxo em dois caminhos (verdadeiro/falso)".

**Prévia** (só quando válido): bloco `bg-muted p-3 rounded-md text-xs` com "Condição configurada:" + `<code>` com `{field} {operator} {value}` e duas legendas: "✓ Verdadeiro → Saída esquerda" (`text-green-600`) e "✗ Falso → Saída direita" (`text-red-600`).

**Validação**: `field && operator && value` (todos preenchidos).

> ⚠️ Os operadores gravados (`==`, `!=`, `>`, `>=`, `<`, `<=`, `contains`) divergem do `ConditionConfig` de `src/types/reguas-cobranca.ts` (`eq`, `neq`, `gt`, `gte`, `lt`, `lte`, `in`, `is_null`). ⚠️ A confirmar.
>
> ⚠️ As legendas "Saída esquerda/direita" são resquício de um editor **canvas/nó** que não existe mais — a timeline é linear e não mostra ramificações. O redesign precisa decidir o que fazer com `condition`.

### 9.4 `WaitConfigForm`

Fonte: `config-forms/WaitConfigForm.tsx`.

| Campo | Componente | Restrições | Default |
|---|---|---|---|
| **Nome do Passo** | `Input`, placeholder "Ex: Aguardar 3 dias" | — | `"Aguardar"` |
| **Duração** | `Input type="number" min={1}` | — | `1` |
| **Unidade** | `Select` | `minutes` "Minutos", `hours` "Horas", `days` "Dias" | **`days`** |

Layout: os dois campos num `grid grid-cols-2 gap-4`. Cabeçalho: ícone `Clock` + "Tempo de Espera", ajuda "Define quanto tempo aguardar antes de prosseguir para o próximo passo".

**Prévia**: bloco `bg-muted p-3 rounded-md text-xs` — "Tempo configurado:" / "O fluxo aguardará **{duration} {minuto(s)|hora(s)|dia(s)}** antes de continuar" (o valor em `font-mono font-medium text-foreground`).

**Validação**: `duration > 0`.

### 9.5 `TriggerAIConfigForm`

Fonte: `config-forms/TriggerAIConfigForm.tsx`.

| Campo | Componente | Restrições | Default |
|---|---|---|---|
| **Nome do Passo** | `Input`, placeholder "Ex: IA de negociação" | — | `"Acionar Agente IA"` |
| **Dias de Atraso para Disparar** | `DaysOverdueInput` (versão completa) | — | `0` |
| **Canal de Comunicação** | `Select` | `whatsapp` "WhatsApp", `email` "E-mail", `sms` "SMS" | **`whatsapp`** |
| **Contexto Adicional (Opcional)** | `RichVariableInput` `rows={4}` `showPreview`, descrição "Instruções específicas para o agente IA neste passo. Use variáveis para personalizar.", placeholder "Ex: Oferecer desconto de {{max_discount}}% para pagamento à vista. Dívida total: {{total_debt}}" | — | `""` |
| **Máximo de Interações** | `Input type="number" min={1} max={20}` | ajuda "Número máximo de mensagens que a IA pode trocar antes de encerrar" | **`5`** |

**Bloco informativo fixo**: `bg-purple-50 border border-purple-200 p-3 rounded-md` — "**Como funciona:** O agente IA usa a configuração ativa (personalidade, guidelines, regras de negócio) para conduzir uma conversa inteligente com o contato, buscando negociar o débito."

**Validação**: `min >= 0`.

**O que grava**: `days_overdue_trigger: { min, max }` (o `max` **não tem campo** — fica `null` a menos que já viesse do config), `ai_version_id` (**sem campo na tela**, sempre `""` em criação), `channel`, `context`, `max_interactions`.

> ⚠️ **Conflito de gatilho**: este formulário grava `days_overdue_trigger`, que é a família de chaves do `triggerConfig.ts` — e o `StepWizard.buildConfig` **também** emite `triggerFields` antes de espalhar `typeConfigFields`. Como `typeConfigFields` vem depois no spread, o `days_overdue_trigger` deste formulário **sobrescreve** o que a fase "Quando" produziu. Ou seja: para `trigger_ai`, o campo "Dias de Atraso para Disparar" do formulário de tipo tem precedência sobre a fase "Quando". Isso não está declarado em nenhum texto de tela. ⚠️ A confirmar se é intencional.

### 9.6 `ProfileStepTriggerFields` — os campos do perfil de formalização

Fonte: `config-forms/ProfileStepTriggerFields.tsx`. Componente **controlado** (value/onChange) — nenhum dado do contrato em estado local. Renderizado na fase "Quando" quando `profileActive`.

Container: `space-y-4 rounded-lg border bg-muted/20 p-4`.

**Cabeçalho do bloco**: `Badge` outline com ícone `Filter h-3 w-3` + "**Formalização**", seguido de `text-xs text-muted-foreground` — "Disponível porque esta organização usa o perfil de formalização."

#### Campo 1 — Etapa que dispara este passo

Dois modos:

**(a) Etapa herdada (`lockedEtapa !== null`)** — só em criação a partir do cabeçalho de um grupo de etapa. `Label` **sem** `htmlFor` (não há campo focável). Bloco `flex items-start gap-2 rounded-md border border-dashed bg-background p-3`:
- Ícone `Milestone h-4 w-4`
- `formatEtapaLabel(lockedEtapa)` em `text-sm font-medium`
- O **valor cru** num `<code class="block w-fit rounded bg-muted px-1 py-0.5 font-mono text-xs">`
- Ajuda: "Herdada do grupo de onde você clicou em "Adicionar". Para criar o passo em outra etapa, use "Adicionar" no cabeçalho dela — ou crie aqui e troque a etapa depois, ao configurar o passo."

**(b) Escolher a etapa** — `EtapaTriggerField`, que tem dois sub-modos conforme o catálogo:

*Com catálogo* (`useProfileEtapaValues(orgSlug)` devolveu opções): **combobox** (`Popover` + `Command`, `shouldFilter={false}`, filtro próprio que casa **valor cru E rótulo legível**).
- Trigger: `Button variant="outline" role="combobox" w-full justify-between font-normal` com `ChevronsUpDown`. Texto: `formatEtapaLabel(selected)` ou, vazio, "Selecione ou digite a etapa…" em `text-muted-foreground`.
- `PopoverContent`: largura amarrada ao trigger via `--radix-popover-trigger-width`, `min-w-[280px]`, altura máxima `--radix-popover-content-available-height`.
- `CommandInput` placeholder "Buscar ou digitar a etapa…".
- Grupos da lista:
  - **"Usar o texto digitado"** (quando o digitado não está na lista): item com `Plus`, o valor num `<code>` e a nota "Nenhum contato está nesta etapa hoje — use assim mesmo se é o valor que a fonte manda."
  - **"Etapas dos contatos desta organização"**: cada item com `Check` (opaco só no selecionado), rótulo legível, `<code>` com o valor cru e, à direita, "{N} contato(s)".
  - **Limpar** (quando há seleção): "Limpar — este passo deixa de disparar por etapa".
- `CommandEmpty`: "Nenhuma etapa com esse texto."
- Abaixo: quando há seleção, "Valor comparado na execução: `<code>{valor}</code>`".

*Sem catálogo* (lista vazia — org não resolvida, perfil sem `etapa_field`, ou nenhum contato com o campo preenchido): `Input` `id="profile-etapa-trigger"` com placeholder "Ex: aguardando_assinatura" e `onBlur` que faz o **trim visível**. Mensagens auxiliares:
  - carregando: `Loader2` girando + "Carregando as etapas dos contatos…"
  - erro: "Não foi possível carregar a lista de etapas desta organização. Digite o valor exato como ele vem da fonte — o passo continua válido."
  - sem dados (com fonte consultada): "Nenhum contato desta organização tem esse campo preenchido hoje, então não há lista para escolher. Digite o valor exato como ele vem da fonte."

**Texto de ajuda fixo** (nos dois sub-modos): "Comparação por igualdade com a etapa atual do contato (campo `{etapa_field}`, definido no perfil da organização). Vazio = este passo não dispara por etapa."

> **Por que aceitar texto livre**: a lista sai de `{org}.contacts` ao vivo. Uma etapa nova da fonte só aparece quando algum contato já está nela — e o passo para essa etapa precisa poder ser configurado **antes** disso, senão a régua fica sempre um passo atrás.

> **O `trim` é load-bearing**: o `match_titles` compara `config->>'etapa_trigger'` **cru**, enquanto o `fetch_titles` faz `btrim` no valor gravado em `resolved_etapa`. Uma etapa com espaço na ponta (típico de colar de planilha ou de JSON do n8n) **nunca casaria** — passo morto sem erro nenhum. Por isso o trim acontece no blur (visível) e no commit.

#### Campo 2 — Janela de dias na etapa (só quando há etapa)

`Label` com ícone `Hourglass h-4 w-4` + "**Enviar dentro de um intervalo de dias na etapa**".

Linha de campos (`flex items-center gap-2`):

```
[do dia] [ ___ ] [ao dia] [ ___ ]
```

| Campo | `id` | `aria-label` | Tipo | Placeholder | Classe |
|---|---|---|---|---|---|
| Primeiro dia | `profile-etapa-min-days` | "Primeiro dia na etapa em que este passo dispara" | `number`, `min={0}`, `step={1}`, `inputMode="numeric"` | **`0`** | `w-20 text-center` |
| Último dia | `profile-etapa-max-days` | "Último dia na etapa em que este passo dispara" | idem | **`—`** | `w-20 text-center` |

> Os placeholders são **diferentes de propósito**: `0` no piso (o valor equivalente) e `—` no teto (vazio significa "em diante", não "dia zero").

**Textos de apoio (três parágrafos `text-xs text-muted-foreground`):**

1. `describeEtapaWindow(value)` — o rótulo derivado da **fonte única** (mesma frase que o card do passo e o resumo do wizard mostram).
2. "O **dia 0 é o dia em que o contato entra na etapa** — a contagem sai da data de referência do perfil da organização (campo `{reference_date_field}`). Não é o dia de atraso de título: o gatilho deste passo continua sendo só a etapa."
3. "Os dois vazios: dispara **todos os dias** enquanto o contato estiver na etapa. Só o primeiro dia preenchido: vale **desse dia em diante**. Os dois preenchidos: só dentro do intervalo, incluindo as duas pontas — e iguais entre si, só naquele dia." + (se `fireOnce`) "Com "disparar uma única vez" ligado, ele **sai uma vez só**, no primeiro dia do intervalo que for avaliado."

**Mensagens de erro (`text-xs text-destructive`):**

| Condição | Texto |
|---|---|
| `isEtapaMinDaysInvalid` | "Primeiro dia: use um número inteiro maior ou igual a zero (ou deixe vazio, para disparar assim que o contato entrar na etapa). Corrija antes de salvar o passo." |
| `isEtapaMaxDaysInvalid` | "Último dia: use um número inteiro maior ou igual a zero (ou deixe vazio, para valer do primeiro dia em diante). Corrija antes de salvar o passo." |
| `isEtapaWindowInvalid` | "O último dia é anterior ao primeiro, então nenhum dia cabe no intervalo: este passo ficaria **mudo** — nunca dispararia, e sem nenhum erro na execução. Ajuste o intervalo antes de salvar." |

**Rótulos de `describeEtapaWindow`** (fonte única, usada em três lugares):

| Estado | Rótulo |
|---|---|
| ambos vazios | "Enquanto estiver na etapa" |
| só piso | "Do dia {min} em diante na etapa" |
| só teto | "Ate o dia {max} na etapa" |
| iguais | "So no dia {min} na etapa" |
| ambos | "Do dia {min} ao dia {max} na etapa" |
| + `fireOnce` | sufixo " · uma vez so" |

> ⚠️ Acentuação ausente em "Ate" e "So" (código literal, sem acento). Candidato a correção no redesign.

#### Campo 3 — Disparar uma única vez por contato

`border-t pt-4`, layout `flex items-start justify-between gap-4`.

- `Label` com ícone `Repeat1 h-4 w-4` + "**Disparar uma única vez por contato**"
- Ajuda: "Ligado, o contato recebe este passo uma vez só — mesmo que volte a atender a condição em execuções seguintes. Desligado, o passo é reavaliado em toda execução."
- `Switch` `id="profile-fire-once"`, `aria-label="Disparar uma única vez por contato neste passo"`. Default: **desligado**.

#### Campo 4 — Destinatário

`border-t pt-4`. `Label` com ícone `Send h-4 w-4` + "Destinatário". `RadioGroup` `gap-2`:

| Valor | Rótulo | Ajuda |
|---|---|---|
| `owner` (**default**) | "O próprio contato" | "{E-mail\|Telefone} do cadastro do contato (padrão)." |
| `variable` | "Endereço da variável do perfil" | Com campo configurado: "{E-mail\|Telefone} de `{campo}`. O contato continua sendo o cliente — só a entrega muda de endereço. Contato sem esse dado é excluído na execução, com o motivo "Sem destinatário"." Sem campo: "{E-mail\|Telefone} configurado no perfil da organização. O contato continua sendo o cliente — só a entrega muda de endereço." |

**Aviso de campo ausente** (`recipient === "variable"` e o perfil não declara o campo): bloco `border-amber-200 bg-amber-50 p-3` com `AlertTriangle` e um texto **que varia por canal**:

- **E-mail**: "...este passo é **excluído na execução**, com o motivo "Sem destinatário" — nenhuma ação é criada."
- **Demais canais**: "...a ação **é criada mas não é enviada** — o envio NÃO cai para o telefone do cliente."

Prefixo comum: "O perfil desta organização não tem `{recipient_email_field|recipient_phone_field}` configurado, então nenhum endereço é resolvido:" — sufixo: "Peça a configuração do perfil antes de usar este destinatário."

#### Chaves gravadas (`buildProfileStepConfig`) — regra "default não vaza chave"

Emite **só** o que muda o comportamento:

| Chave | Emitida quando |
|---|---|
| `etapa_trigger` | etapa não vazia (após trim) |
| `etapa_min_days` | **só com etapa** e valor normalizável |
| `etapa_max_days` | **só com etapa** e valor normalizável |
| `fire_once: true` | switch ligado |
| `recipient: "variable"` | radio em "variável" |

> Consequência declarada: passo de org sem perfil (que nunca teve essas chaves) faz round-trip com payload **byte-idêntico** ao de hoje — zero regressão por construção.

**Normalização (`normalizeEtapaDays`)**: aceita número (inteiro seguro, `0 ≤ x ≤ 999.999.999`) ou string numérica que case `/^[0-9]{1,9}$/` após trim. Tudo fora do contrato (negativo, decimal, texto, boolean, > 9 dígitos) vira `null` = **ausente**, nunca `NaN`.

> **Por que 9 dígitos**: é a mesma regex do motor. Lá o `+` seria bug (aceitaria 30 dígitos que estouram no `::INTEGER` e abortam o run de todas as campanhas do lote). Aqui é **alinhamento**: valor de 10+ dígitos é reprovado no motor, e exibi-lo na tela mostraria um valor que o motor não honra.

> **`0` é valor legítimo, não sinônimo de ausente**: ausente = nenhuma condição de dia; `0` = `days_overdue >= 0`, que **não** é verdadeiro quando `days_overdue IS NULL` — logo exige data de referência **conhecida**.

### 9.7 `DaysOverdueInput` — o campo de dia exato

Fonte: `config-forms/SharedComponents/DaysOverdueInput.tsx`. Duas variantes.

**Versão completa** (usada na fase "Quando" e no `TriggerAIConfigForm`):
- `Label` com ícone `Calendar h-4 w-4` + "**Dia de Disparo**"
- `Input type="number"` `w-20 text-center`, placeholder `0`
- `Badge` ao lado com a descrição derivada

**Versão compacta** (`compact`): `Label` "Dia:" com `Calendar h-3.5`, `Input w-16 h-8 text-sm`, `Badge text-xs`.

**Descrição e cor do badge** (`dayOverdueDescription.ts` — fonte única):

| Dia | Texto (`describeDay`) | `variant` | Classe extra |
|---|---|---|---|
| `0` | "**No dia do vencimento**" | `outline` | — |
| `< 0` | "**{N} dia(s) ANTES**" | `secondary` | `bg-blue-100 text-blue-700 hover:bg-blue-100` |
| `> 0` | "**{N} dia(s) APÓS**" | `default` | `bg-amber-100 text-amber-700 hover:bg-amber-100` |

> **Aceita negativos sem restrição** — o `Input` não tem `min`. É o mecanismo de cobrança preventiva (D-7, D-1).

### 9.8 `DaysOverdueRangeInput` — o campo de faixa/cauda

Fonte: `config-forms/SharedComponents/DaysOverdueRangeInput.tsx`.

**Switch de modo** (escondido quando `hideModeToggle`, que é o caso em todos os usos atuais no domínio de régua): `Label` com `Calendar` + "**Usar faixa de atraso**", ajuda "Em vez de um dia exato, dispara em qualquer dia dentro da faixa".

**Modo exato**: `Label` "Dia de Disparo" + `Input number w-20 text-center` + `Badge` com `describeDay`.

**Modo faixa** (`flex flex-wrap items-end gap-3`):

| Campo | `id` | Placeholder | Comportamento |
|---|---|---|---|
| **De (dia)** | `range-min` | — | `Number(e.target.value)` |
| **Até (dia)** | `range-max` | **`∞`** | vazio → `null` (faixa aberta) |
| Badge de resumo | — | — | `bg-amber-100 text-amber-700`. Aberta: "De {descrição em minúsculas} em diante". Fechada: "De D{±min} a D{±max}" |

Ajuda: "Deixe "Até" vazio para uma faixa aberta (cauda) — pega todo atraso a partir do "De"."

**Cadência**: `Label` com ícone `Repeat h-4 w-4` + "**Intervalo mínimo entre envios (dias)**". `Input number min={1} w-32 text-center`, placeholder "sem intervalo mínimo", vazio → `null`.

Ajuda: "Vazio = sem controle de repetição (dispara em todos os dias da faixa). Preenchido, o contato só volta a entrar depois de completados N dias desde o envio anterior — **não é uma periodicidade exata de N em N dias**."

**Aviso de disparo diário** (`showDailyWarning`): aparece quando o modo é faixa **e** (`max === null` **ou** `max > min`) **e** não há cadência. Bloco `border-amber-200 bg-amber-50 p-3` com `AlertTriangle`:

> "**Atenção:** sem cadência, essa faixa **dispara todo dia** do intervalo em que a campanha rodar, indefinidamente. Defina o "Intervalo mínimo entre envios" para espaçar."

> Faixa degenerada (`max === min`, um dia só) **não** avisa.

---

## 10. Editor de conteúdo da mensagem

### 10.1 `TemplateEditor` — o wrapper

Fonte: `config-forms/SharedComponents/TemplateEditor.tsx`. Estrutura (`space-y-3`):

1. **Cabeçalho** (`space-y-2`):
   - `Label text-sm font-medium` com o `templateLabel` do canal
   - Descrição `text-xs text-muted-foreground mt-0.5`
   - Linha de botões (`flex gap-2`): **"Melhorar com IA"** (`AIMessageAssistant`, quando `showAIAssistant`) e **"Inserir Variável"** (`VariableInserter`)
2. **`RichVariableInput`** com `showPreview={true}`, `rows` do canal, `variableContext` (default `"workflow"`).

**Inserção de variável**: `onChange(value + variable)` — **anexa ao final**, não insere no cursor. ⚠️ Ponto de dor conhecido para o redesign.

Defaults do componente: `label = "Mensagem"`, `description = "Use as variáveis para personalizar a mensagem"`, `placeholder = "Digite sua mensagem aqui..."`, `rows = 6`, `aiScenario = "negotiation"`, `aiTone = "professional"`.

### 10.2 `VariableInserter`

Fonte: `config-forms/SharedComponents/VariableInserter.tsx`.

**Trigger**: `Button variant="outline" size="sm" type="button"` com ícone `Variable h-3 w-3` + "**Inserir Variável**".

**`PopoverContent` `w-80 p-0` `align="start"`:**

- **Cabeçalho** (`p-3 border-b`): `h4` "Variáveis Disponíveis", `p text-xs text-muted-foreground` "Clique para inserir no texto", e um `Input h-8 text-sm` com placeholder "Buscar variável...".
- **Lista** (`ScrollArea h-80`):
  - Carregando: `Loader2 h-5 w-5` girando + "Carregando variáveis..."
  - Vazio: "Nenhuma variável encontrada" (com busca) ou "Nenhuma variável disponível"
  - Preenchida: agrupada por **categoria** (`VARIABLE_CATEGORY_LABELS`), com cabeçalho `text-xs font-semibold text-muted-foreground uppercase px-2 sticky top-0 bg-popover py-1`. Cada item é um `<button>` `w-full text-left px-2 py-1.5 rounded-md hover:bg-accent` com: rótulo (`text-xs font-medium truncate`), descrição (`text-xs text-muted-foreground truncate`) e, à direita, um `<code class="text-[10px] bg-muted px-1 py-0.5 rounded shrink-0 opacity-60 group-hover:opacity-100">` com `{{chave}}`.
- **Rodapé** (`border-t px-3 py-2`, só quando há variáveis): "{N} variáveis disponíveis" centralizado.

**Busca**: filtra por `label`, `key` ou `description` (case-insensitive), por categoria; categorias sem resultado somem.

**Formato inserido**: `{{chave}}` — se a chave já começar com `{{`, usa como está.

**Fonte das variáveis**: `useVariables({ context })`, não a constante `AVAILABLE_VARIABLES` de `src/types/reguas-cobranca.ts`.

### 10.3 `TemplateHSMSelector` — seleção de template

Fonte: `config-forms/SharedComponents/TemplateHSMSelector.tsx`. Só aparece para `whatsapp` e `rcs`.

**Rótulo, que muda por canal** (correção do chamado 7136):
- RCS: "**Template de RCS (card)**"
- Demais: "**Template de Ativação (HSM)**"

> Motivo declarado: "Ativação (HSM)" e "janela de 24h" são vocabulário de WhatsApp/Meta. No RCS não existe janela nem aprovação — o template é o **card**.

**Ações no cabeçalho** (`ghost h-7 text-xs`, à direita do rótulo):
- Aba "Meta" ativa: "**Sincronizar**" (`RefreshCw`, gira enquanto `syncMeta.isPending`)
- Aba "Local" ativa: "**Novo Template**" (`Plus`)

**Abas** (`TabsList w-full`):

| Aba | Ícone | Rótulo | Badge |
|---|---|---|---|
| `meta` | `Globe h-3.5` | Templates Meta | contagem `secondary h-5 px-1.5 text-[10px]` |
| `local` | `FileEdit h-3.5` | Templates Locais | contagem idem |

> **Aba inicial**: RCS abre em **"Templates Locais"** (RCS não tem template Meta — a lista vinha vazia e o operador concluía que a org não tinha template de RCS). Os demais canais abrem em "Templates Meta".

**Combobox de template** (`TemplateCombobox`):
- Trigger: `Button outline role="combobox" w-full justify-between`, `border-primary/50` quando há seleção. Estados: carregando (`Loader2` + "Carregando templates..."), selecionado (`FileText` + nome), vazio ("Selecione um template (opcional)").
- `PopoverContent w-[400px] p-0`, `CommandInput` placeholder "Buscar template...".
- `CommandEmpty`: "Nenhum template encontrado" + ação contextual — "Sincronizar do HyperFlow" (Meta) ou "Criar novo template" (Local).
- `CommandGroup heading="Templates Disponíveis"` dentro de `ScrollArea max-h-[300px]`; cada item tem `Check` (opaco só no selecionado).
- **Botão de limpar**: `ghost icon` com `X h-4 w-4` ao lado do combobox, só quando há seleção.

**Item da lista — aba Meta**: nome (`font-medium truncate`) + linha de badges:

| Badge | Fonte | Cores |
|---|---|---|
| Status | `meta_status` | `APPROVED` → "Aprovado" (`bg-green-500/10 text-green-600 border-green-500/20`); `PENDING` → "Pendente" (âmbar); `REJECTED` → "Rejeitado" (vermelho) |
| Categoria | `meta_category` | `outline text-[10px] h-4 px-1` |

**Item da lista — aba Local**: nome + `description` (`text-xs text-muted-foreground truncate`).

**Bloco informativo** (`flex items-start gap-2 p-3 rounded-lg bg-muted/50 border`, ícone `Info`):

| Situação | Título | Texto |
|---|---|---|
| Template Meta selecionado | nome + badge "Meta" (`bg-blue-500/10 text-blue-600`) | "Template importado da Meta/HyperFlow. As variáveis numéricas devem ser mapeadas abaixo." |
| Template local em RCS | nome | "O card do RCS (imagem, título, texto e botões) vem deste template. As variáveis são resolvidas no envio." |
| Template local, outro canal | nome | "Use um template pré-aprovado para iniciar conversas fora da janela de 24h." |
| Nada selecionado, RCS | "Template de RCS" | "Sem template, o RCS sai como texto puro — sem imagem, título nem botões. Os templates de RCS ficam na aba Templates Locais." |
| Nada selecionado, outro | "Template de Ativação" | "Selecione um template Meta (importado do HyperFlow) ou local para iniciar conversas fora da janela de 24h." |

**Prévia do template local** (só quando selecionado e **não** é Meta): `Label text-xs text-muted-foreground` "Prévia do Template" + `<pre class="whitespace-pre-wrap font-sans">` com o conteúdo bruto, num bloco `p-3 bg-muted/30 rounded-lg border text-sm`.

**O que `onChange` entrega ao pai**:
- Meta: `(id, content, meta_template_name, meta_components, variáveis numéricas extraídas)`
- Local: `(id, content, undefined, meta_components, undefined)` — templates locais de RCS também podem ter `meta_components` (o card)
- Limpar: `(undefined, "")`

#### Sub-modal — "Criar Template de Ativação" (`CreateTemplateDialog`)

`DialogContent sm:max-w-[600px]`.

| Campo | Componente | Obrigatório |
|---|---|---|
| **Nome do Template \*** | `Input`, placeholder "Ex: Lembrete de Vencimento" | sim |
| **Descrição (opcional)** | `Textarea rows={2}`, placeholder "Descreva quando usar este template..." | não |
| **Conteúdo do Template \*** | `RichVariableInput rows={6} showPreview`, placeholder "Olá {{contact.name}}, você tem um título em aberto..." | sim |
| *(indicador)* | linha "Canal:" + `Badge outline capitalize` com o canal | — |

`DialogDescription`: "Crie um novo template de mensagem para uso em réguas de cobrança. Você pode usar variáveis como {{contact.name}} para personalização."

**Validação**: nome e conteúdo não vazios. **Botões**: "Cancelar" (`outline`) e "Criar Template" (com `Loader2` quando pendente). Ao criar, o template é **automaticamente selecionado** no passo.

**Extração de variáveis** na criação: `/\{\{([^}]+)\}\}/g`, com trim, únicas — gravadas em `variables`.

### 10.4 `MetaVariableMapper` — mapeamento das variáveis numeradas

Fonte: `config-forms/SharedComponents/MetaVariableMapper.tsx`. Só renderiza quando há variáveis (`variables.length > 0`).

**Cabeçalho**: `Label` com ícone `Variable h-4 w-4` + "**Mapeamento de Variaveis do Template**" (sem acento no código). À direita, quando há pendências: `Badge outline text-amber-600 border-amber-300 bg-amber-50` com `AlertTriangle h-3 w-3` + "**{N} sem mapeamento**".

**Container das linhas**: `space-y-2 rounded-lg border border-border p-3`.

**Cada linha (`VariableRow`)**: `rounded-md border p-3 space-y-2`, com destaque quando vazia — `border-amber-200 bg-amber-50/50`.

- **Linha superior** (`flex items-center justify-between gap-2`):
  - "Variavel `{{N}}`" (`text-sm font-medium`, o número num `<code class="bg-muted px-1.5 py-0.5 rounded text-xs font-mono">`)
  - Exemplo do template (quando existe): `text-xs text-muted-foreground truncate` — "Ex: {valor}"
  - **Botão de modo** (`outline sm h-7 text-xs gap-1.5`, `border-primary/50 text-primary` quando dinâmica):
    - `dynamic` → ícone `Variable` + "**Dinamica**"
    - `fixed` → ícone `Type` + "**Valor fixo**"
    - **Trocar de modo limpa o valor atual.**
- **Linha inferior** — o campo, largura total:
  - **Modo dinâmico**: combobox (`DynamicVariableSelector`). Trigger `outline role="combobox" w-full justify-between h-8 text-sm font-normal`; mostra `<code>{{chave}}</code>` + rótulo quando selecionado, senão "Selecione uma variavel...". `PopoverContent w-[360px]`, `CommandInput` "Buscar variavel...", `CommandEmpty` "Nenhuma variavel encontrada". Itens agrupados por categoria, cada um com `Check`, rótulo, descrição e `<code>` da chave. Grava `{{chave}}`.
  - **Modo fixo**: `RichVariableInput rows={1}` com placeholder "Ex: sua maquina {{contract.equipamento}}" e `variableContext="workflow"`.

**Detecção automática do modo inicial**: se o valor atual começa com `{{` e termina com `}}` → `dynamic`; senão → `fixed`.

> ⚠️ Vários textos sem acento no código: "Variaveis", "Variavel", "Dinamica", "variavel". Candidatos a correção.

### 10.5 `IntegrationSelector`

Fonte: `config-forms/SharedComponents/IntegrationSelector.tsx`.

**Rótulo**: `Label` com ícone `Link2 h-4 w-4` + "**Integração de {tipo}**". Ajuda: "Selecione a integração que será usada para enviar".

**Rótulos de tipo**: WhatsApp, E-mail, SMS, RCS, Voz, Webhook, Atividade Humana, Negativação, Notificação, Bloqueio.

**Ícones por tipo**: `whatsapp` `MessageCircle`; `email` `Mail`; `sms` `Smartphone`; `rcs` **`Radio`**; `voice` `Phone`; `webhook` `Webhook`; `human_activity` `UserCheck`; `negativation` `AlertTriangle`; `notification` `FileWarning`; `block` `Ban`. Fallback: `Link2`.

**Estados:**

| Estado | Render |
|---|---|
| Carregando | `Loader2 h-4 w-4` girando + "Carregando integrações..." |
| Nenhuma ativa | Bloco `p-3 border rounded-md bg-muted`: "Nenhuma integração de {tipo} ativa encontrada." + "Configure uma integração em **Configurações → Integrações**" |
| Com opções | `Select` + indicador de seleção |

**`Select`**: `SelectTrigger` ganha `border-primary/50` quando há valor. Placeholder "Selecione uma integração". Cada `SelectItem`: ícone do tipo + nome + `CheckCircle2 h-3.5 text-primary ml-auto` no selecionado.

**Indicador de seleção** (abaixo do select): `flex items-center gap-2 p-2 rounded-md bg-primary/5 border border-primary/20` com `CheckCircle2 h-4 text-primary`, o nome e um `Badge secondary ml-auto text-xs` com o tipo.

**Resolução de nome e tipo** (suporta dois formatos): tipo vem de `category` → `slug` → `integration.category` → `integration.slug`; nome vem de `name` → `config.name` → `integration.name` → `id`.

**Filtro**: `type === integrationType && is_active !== false`.

### 10.6 Prévia da mensagem (`MessagePreview` / `TemplateMessagePreview`)

Fonte: `config-forms/SharedComponents/MessagePreview.tsx`.

> **Nota**: o `ContentStep` do wizard usa `TemplateMessagePreview` (de `@/components/message-templates`), não este `MessagePreview` diretamente. O `MessagePreview` documentado aqui é o componente do domínio de régua, com a mesma família de prévias por canal. ⚠️ A confirmar se `MessagePreview` ainda é consumido em algum ponto do fluxo de régua ou se ficou órfão.

**Moldura comum**: `rounded-xl border bg-card p-4 shadow-sm`, com um cabeçalho — bolinha verde (`w-2 h-2 rounded-full bg-green-500`) + "**PRÉ-VISUALIZAÇÃO**" (`text-xs font-medium text-muted-foreground uppercase tracking-wider`).

**Roteamento por canal:**

| Canal | Condição | Componente |
|---|---|---|
| `whatsapp` | tem `metaComponents` **e** `message` não-vazia | `CombinedWhatsAppPreview` — **duas bolhas**: "Template de Ativação" e "Mensagem de Acompanhamento" |
| `whatsapp` | tem `metaComponents` **e** `message` vazia | `MetaWhatsAppPreview` — uma bolha com HEADER/BODY/FOOTER/BUTTONS |
| `whatsapp` | sem `metaComponents` | `WhatsAppPreview` — bolha simples |
| `rcs` | — | `RcsPreview` (com `fallbackBody`) |
| `sms` | — | `SMSPreview` |
| `email` | — | `EmailPreview` |
| `voice` | — | `VoicePreview` |
| outro | — | `DefaultPreview` |

**Detalhes visuais por prévia:**

| Prévia | Elementos |
|---|---|
| WhatsApp | Avatar circular `bg-[#25D366]` com `MessageSquare`; área de chat com **wallpaper SVG inline** (padrão de cruzes, `fill-opacity 0.08`) sobre `hsl(var(--muted)/0.3)`; bolha à direita `max-w-[85%] rounded-lg rounded-tr-none` com gradiente `#dcf8c6 → #d4f4be`; hora atual (`toLocaleTimeString("pt-BR")`) + `CheckCheck` azul. HEADER em `font-semibold`, BODY normal, FOOTER `italic text-gray-500`. Botões renderizados **abaixo** da bolha, em blocos brancos com texto `#00a5f4`. |
| SMS | Avatar `bg-blue-500` com `Smartphone`; bolha à **esquerda** `bg-muted rounded-2xl rounded-tl-none`; **contador**: "{N} caracteres" à esquerda e "{N} SMS(s)" à direita (`text-amber-600 font-medium` quando > 160). `smsCount = ceil(chars/160) || 1`. |
| E-mail | Card com cabeçalho `bg-muted/50`: ícone `Mail` + "E-mail", e linhas "De: Sua Empresa LTDA", "Para: {recipientLabel ?? joao.silva@email.com}", "Assunto: {EmailSubjectPreview}". Corpo via `EmailHtmlPreview`. |
| Voz | Avatar `bg-green-600` com `Phone`; bloco `border-dashed` com "Transcrição:" e o texto entre aspas, em `italic text-foreground/80`. |
| Default | Avatar `bg-muted`; nome do canal em `capitalize`; bloco simples. |

**Resolução de variáveis na prévia:**

- Variáveis Torre (`{{contact.name}}`): `replaceVariablesWithExamples(message)`.
- Variáveis Meta numeradas (`{{1}}`), por ordem de prioridade (`replaceMetaVarsForPreview`):
  1. **Valor real resolvido** (`resolvedParams` — dry-run de Ação Manual)
  2. **Rótulo da variável Torre mapeada**: `[Nome do Cliente]` (via `INTEGRATION_VARIABLES`) ou `[chave]` se sem rótulo
  3. **Exemplo do template** (`example.body_text[0][idx-1]`)
  4. **Placeholder**: `[Variavel {N}]`

**Modo resolvido** (aditivo, default-off): `resolvedMessage`, `resolvedSubject`, `resolvedParams`, `recipientLabel`, `contactName` — quando presentes, priorizam valores reais. Sem elas, o comportamento é o de exemplo (que é o caso do editor de régua).

---

## 11. Assistente de mensagem com IA (`AIMessageAssistant`)

Fonte: `config-forms/SharedComponents/AIMessageAssistant.tsx`.

### 11.1 Entrada e gatilho

**Trigger**: `Button type="button" variant="outline" size="sm" className="gap-2"` com ícone `Sparkles h-3 w-3` + "**Melhorar com IA**".

**Desabilitado quando**: `disabled` (prop) **ou** a mensagem tem **menos de 10 caracteres** (`minMessageLength = 10`).

**`title` do botão**: "Digite pelo menos 10 caracteres" (quando curto) ou "Melhorar com IA".

**Contexto enviado à IA**: `{ scenario, tone, channel, maxLength }`.

| Parâmetro | Origem no fluxo de régua | Default do componente |
|---|---|---|
| `scenario` | `aiScenario="negotiation"` fixo no `ContentStep` | `"negotiation"` |
| `tone` | não passado pelo `ContentStep` | `"professional"` |
| `channel` | `getAIChannelType(channel)` — só `whatsapp`, `sms`, `email`, `voice` | `undefined` |
| `maxLength` | `meta.showCharWarning` (160 no SMS; `undefined` nos demais) | `undefined` |

### 11.2 Layout do popover

`PopoverContent className="w-[420px] p-0" align="end"`.

- **Cabeçalho** (`border-b px-4 pt-4 pb-2`): `h4 font-medium text-sm mb-2` "Assistente de IA" + `TabsList grid w-full grid-cols-3`.
- **Três abas** (`text-xs`): **Melhorar** | **Variações** | **Compliance**.
- Conteúdo de cada aba: `p-4 space-y-4`.

### 11.3 Comportamento de execução

- **Ao abrir o popover**: executa automaticamente a aba "Melhorar" se ela nunca rodou (`status === "idle"`) e não há request pendente.
- **Ao trocar de aba**: executa automaticamente **só** se a aba nunca rodou. **Erro exige retry explícito** — não re-executa sozinho.
- **Ao fechar**: reseta tudo (resultado, variações, issues, seleção, aba ativa e os três estados).

### 11.4 Máquina de estados por aba

`RequestStatus = "idle" | "loading" | "done" | "error"` — **estado explícito por aba**, com o comentário do código: *"falha da IA NUNCA pode parecer estado inicial"*.

| Estado | Render (aba Melhorar) | Render (aba Variações) | Render (aba Compliance) |
|---|---|---|---|
| `loading` | `Loader2 h-6 w-6` + "Melhorando mensagem..." | `Loader2` + "Gerando variações..." | `Loader2` + "Verificando compliance..." |
| `error` | `AssistantErrorPanel` | idem | idem (**nunca** cai no verde) |
| `done` com resultado | Sugestão + botões | Lista de variações + botões | Lista de issues ou estado verde |
| `idle` | `AssistantIdlePanel` | idem | idem |

**`AssistantIdlePanel`**: `py-6 text-center` com descrição + botão `outline sm w-full` com `Sparkles`:

| Aba | Descrição | Rótulo do botão |
|---|---|---|
| Melhorar | "Melhore sua mensagem com IA." | "Melhorar mensagem" |
| Variações | "Gere 3 variações da mensagem com abordagens diferentes." | "Gerar variações" |
| Compliance | "Revise a mensagem contra as regras de CDC e LGPD." | "Verificar compliance" |

**`AssistantErrorPanel`**: `py-6 text-center` com `AlertTriangle h-8 w-8 text-destructive`, a mensagem em `text-sm text-destructive` com **`role="alert"`**, e botão `outline sm w-full` com `RefreshCw` + "**Tentar novamente**".

### 11.5 Aba "Melhorar"

**Sucesso**: `p text-xs text-muted-foreground font-medium` "Sugestão da IA:" + `ScrollArea h-40 rounded-md border p-3 bg-muted/30` com o texto em `whitespace-pre-wrap`. Abaixo (`flex gap-2`): botão **"Aplicar"** (`sm flex-1`, ícone `Check`) e botão de regenerar (`outline sm`, só o `RefreshCw`).

**Ao aplicar**: chama `onApply(result)` (substitui o corpo da mensagem no editor), fecha o popover e emite toast "**Mensagem aplicada** / A sugestão da IA foi aplicada ao editor.".

> **200 com texto vazio é tratado como falha**, não como "nada a mostrar" — cai em `EMPTY_COMPLETION`.

### 11.6 Aba "Variações"

**Sucesso**: `ScrollArea h-48` com uma lista de `<button>` `w-full text-left p-3 rounded-md border text-sm`:
- Selecionada: `border-primary bg-primary/5`; demais: `border-border hover:bg-accent`
- Cada uma: "Variação {N}" (`text-xs text-muted-foreground mb-1`) + o texto (`whitespace-pre-wrap line-clamp-3`)

Abaixo: botão **"Aplicar Selecionada"** (`sm flex-1`, `Check`, **`disabled` enquanto nada está selecionado**) e botão de regenerar.

**Ao aplicar**: toast "**Variação aplicada** / A variação selecionada foi aplicada ao editor.".

**Filtro de resposta**: mantém só strings não-vazias. Lista vazia → falha com "A IA não retornou variações. Tente novamente.".

### 11.7 Aba "Compliance"

**Com problemas**: `p text-xs text-muted-foreground font-medium flex items-center gap-1` com `AlertTriangle h-3 w-3 text-amber-500` + "Pontos de atenção encontrados:". `ScrollArea h-40` com `<ul>`; cada `<li>`: `text-sm p-2 rounded-md bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800`. Abaixo, botão `outline sm w-full` com `RefreshCw` + "**Verificar Novamente**".

**Sem problemas** (só quando `status === "done"`): bloco `text-center py-8` com `Check h-8 w-8 text-green-500`, "Nenhum problema de compliance detectado." e, em `text-xs`, "A mensagem está em conformidade com CDC e LGPD."

> **Invariante explícita do código**: falha **nunca** pode virar "em conformidade" (falso verde). O verde exige `status === "done"`.

### 11.8 Tratamento de erro — copy por código

O componente lê o `code` do erro por **duck typing** (não depende da classe em runtime). Copy por código (`AI_ERROR_COPY`), introduzida em IAF-6016 — antes o usuário só via "Não foi possível conectar com a IA" para qualquer causa:

| `code` | Mensagem |
|---|---|
| `AI_NOT_CONFIGURED` | "A IA não está configurada neste ambiente. Fale com o administrador ou o suporte." |
| `MODEL_UNAVAILABLE` | "O modelo de IA está indisponível no momento. Tente novamente mais tarde." |
| `QUOTA_EXCEEDED` | "O limite de uso da IA foi atingido. Tente novamente mais tarde." |
| `CONTENT_BLOCKED` | "O conteúdo foi bloqueado pelos filtros de segurança da IA. Ajuste a mensagem e tente novamente." |
| `EMPTY_COMPLETION` | "A IA não retornou texto. Tente novamente." |
| `UPSTREAM_ERROR` | "O provedor de IA falhou ao responder. Tente novamente em alguns instantes." |
| `INVALID_REQUEST` | "A requisição enviada à IA é inválida. Revise a mensagem e tente novamente." |
| `METHOD_NOT_ALLOWED` | "Não foi possível chamar o assistente de IA. Recarregue a página e tente novamente." |
| `INTERNAL_ERROR` | "O assistente de IA falhou inesperadamente. Tente novamente em alguns instantes." |
| `UNAUTHORIZED` | "Sua sessão expirou. Recarregue a página e tente novamente." |
| `UNKNOWN` | "Não foi possível conectar com a IA. Tente novamente." |

Sem código reconhecido, usa a `error.message` se houver; senão `UNKNOWN`.

**Toast destrutivo em toda falha**, com título por aba:

| Aba | Título do toast |
|---|---|
| `improve` | "Erro ao melhorar mensagem" |
| `variations` | "Erro ao gerar variações" |
| `compliance` | "Erro ao revisar compliance" |

### 11.9 Ações no backend

`useAIAssistant()` (`@/hooks/useAI`) com três ações:

| Ação | Payload | Resposta consumida |
|---|---|---|
| `improve_message` | `content`, `context` | `response.result` (string) |
| `generate_variations` | `content`, `context` | `response.suggestions` (string[]) |
| `review_compliance` | `content` (**sem contexto**) | `response.compliance_issues` (string[]) |

---

## 12. Gatilho: faixa de dias, cauda, janela na etapa, cadência, disparo único

Esta seção consolida o modelo de gatilho, que está espalhado entre `triggerConfig.ts`, `profileStepConfig.ts`, `DaysOverdueInput`, `DaysOverdueRangeInput`, `ProfileStepTriggerFields` e `WhenStep`.

### 12.1 Os quatro formatos e o que grava cada um

| Formato | Chaves gravadas | Onde se configura | Rótulo na timeline |
|---|---|---|---|
| **Dia exato** | `days_overdue: N`, `trigger_day: N` | fase "Quando" → `DaysOverdueInput` | "No vencimento" / "{N} dia(s) antes" / "{N} dia(s) de atraso" |
| **Faixa fechada** | `days_overdue_trigger: {min, max}`, `days_overdue: min`, `trigger_day: min`, opcional `repeat_every_days` | fase "Quando" (criação, switch de cauda) ou `EditCaudaDialog` | "De D+{min} a D+{max}" (+ "· a cada N dias") |
| **Faixa aberta (cauda)** | idem com `max: null` | idem | "De D+{min} em diante" (+ cadência) |
| **Etapa** | `etapa_trigger`, opcional `etapa_min_days`, `etapa_max_days`, `fire_once` | fase "Quando" → `ProfileStepTriggerFields` | rótulo da etapa no cabeçalho do grupo; janela no badge do card |

**`days_overdue` é gravado mesmo em modo faixa** (com o valor de `min`) porque a `TimelineView` agrupa os passos por ele. Isso está documentado no `triggerConfig.ts`.

### 12.2 Dias negativos — cobrança preventiva

Os campos de dia **não têm `min`**. `-7` significa "7 dias antes do vencimento". A UI exibe:

| Valor | `describeDay` | Cor do badge |
|---|---|---|
| `-7` | "7 dias ANTES" | azul (`bg-blue-100 text-blue-700`) |
| `0` | "No dia do vencimento" | outline neutro |
| `+7` | "7 dias APÓS" | âmbar (`bg-amber-100 text-amber-700`) |

E no cabeçalho do grupo da timeline (`getDayLabel`), em português mais longo: "{N} dia(s) antes" / "No vencimento" / "{N} dia(s) de atraso".

> Regra do motor (CLAUDE.md, regra 2): `days_overdue` **deve** suportar negativos; nunca `GREATEST(0, ...)`.

### 12.3 Cauda — as restrições de UI

| Restrição | Onde é aplicada |
|---|---|
| **Uma cauda por régua** | `caudaJaExiste` calculado no editor; o `Switch` "Step de cauda" fica `disabled` com mensagem âmbar explicativa |
| Faixa/cadência **não** se edita no wizard | `WhenStep` mostra `ReadOnlyPanel` apontando para "Editar" no cabeçalho do grupo. Invariante declarada (uma versão anterior tentou e foi revertida). |
| Edição é **em lote** | `EditCaudaDialog` + `handleSaveCauda` aplicam a mesma faixa a **todos** os passos do grupo, preservando as demais chaves via `mergeTriggerIntoConfig` |
| Validação de faixa | `isTriggerRangeValid` — inválida só quando `max !== null && max < min` |

**Mensagem de erro no `EditCaudaDialog`**: `text-xs text-destructive` — `"Até" deve ser maior ou igual a "De".`

### 12.4 Cadência (`repeat_every_days`)

- Campo: "**Intervalo mínimo entre envios (dias)**", `Input number min={1}`, placeholder "sem intervalo mínimo".
- Vazio = `null` → **não é gravado** (`buildTriggerConfig` só emite quando `>= 1`).
- Semântica declarada na ajuda: "o contato só volta a entrar depois de completados N dias desde o envio anterior — **não é uma periodicidade exata de N em N dias**".
- **Sem cadência, faixa aberta (ou faixa larga) dispara TODO DIA** — é o aviso âmbar do `DaysOverdueRangeInput`.
- **A cadência só existe no mundo dos dias.** Em gatilho por etapa, `buildConfig` omite todas as chaves de dia, incluindo `repeat_every_days`. A idempotência ali é o `fire_once`.

### 12.5 Janela de dias na etapa (`etapa_min_days` / `etapa_max_days`)

| Combinação | Rótulo (`describeEtapaWindow`) | Semântica |
|---|---|---|
| ambos vazios | "Enquanto estiver na etapa" | nenhuma condição de dia — dispara todos os dias na etapa |
| só piso = N | "Do dia {N} em diante na etapa" | `days_overdue >= N` |
| só teto = M | "Ate o dia {M} na etapa" | `days_overdue <= M` |
| piso = teto = N | "So no dia {N} na etapa" | só naquele dia |
| piso = N, teto = M | "Do dia {N} ao dia {M} na etapa" | inclusivo nas duas pontas |

- **Dia 0 = o dia em que o contato ENTRA na etapa** (contado a partir do `reference_date_field` do perfil da org).
- **`0` é valor legítimo**, distinto de ausente. Ausente = nenhuma condição; `0` = `days_overdue >= 0`, que **não** é verdadeiro com `days_overdue IS NULL` — exige data de referência conhecida.
- **Janela invertida (`max < min`) deixa o passo MUDO para sempre**, sem erro nenhum na execução. **A tela é quem barra** (`isEtapaWindowInvalid`), porque abortar o run mataria todas as campanhas da org naquele horário.
- **A janela é por PASSO, nunca por grupo** — dois passos da mesma etapa podem legitimamente ter janelas diferentes (0-3 e 4-7). Por isso **não existe** edição em lote como no `EditCaudaDialog`.
- Forma aceita: inteiro não-negativo, **até 9 dígitos** (`/^[0-9]{1,9}$/`). Mesma regex do motor — valor com 10+ dígitos é reprovado no motor e deixaria o passo mudo.

### 12.6 Disparo único (`fire_once`)

- Switch "**Disparar uma única vez por contato**", default **desligado**.
- Ligado: o contato recebe o passo uma vez só, mesmo voltando a atender a condição.
- Desligado: o passo é reavaliado em toda execução — e, dentro de uma janela de dias, **dispara todos os dias do intervalo**.
- Sufixo no rótulo da janela: " · uma vez so".
- Só é gravado quando ligado (`fire_once: true`).

### 12.7 Exclusividade dia × etapa

Duas camadas, com motivos diferentes — nenhuma redundante:

| Camada | Onde | O que faz | Por quê |
|---|---|---|---|
| **Motor** | `match_titles` | Os três formatos de dia carregam `AND config->>'etapa_trigger' IS NULL`, incondicional e para toda org | `workflow_steps` tem produtores além desta tela (`ai-orchestrator`, `ai-proposal-executor`, a API, `restore_workflow_steps`) |
| **UI** | `StepWizard.buildConfig` | Com etapa preenchida, **nenhuma** chave de dia é emitida | A tela não deve mostrar valor que não será gravado nem avaliado |

**O risco de origem**: `buildTriggerConfig` grava **sempre** `days_overdue` (default `0`). Sem a exclusividade, um passo de etapa casaria também **todo contato com `days_overdue = 0`** — todo mundo que entrou na etapa hoje, em qualquer etapa.

### 12.8 Herança do alvo de "Adicionar"

`AddStepTarget` tem três formas:

| `kind` | Campos | O que é herdado |
|---|---|---|
| `day` | `daysOverdue` | Dia **pré-preenchido e editável** |
| `cauda` | `min`, `max`, `repeatEveryDays` | Faixa e cadência **somente leitura** (pertencem ao grupo) |
| `etapa` | `etapa`, `minDays`, `maxDays` | **Só a etapa**, exibida travada. `minDays`/`maxDays` vêm sempre `""` do `TimelineView` — a janela é por passo |

**A etapa só trava em criação.** Na edição o passo pode mudar de etapa (e assim de grupo); travar tiraria a única forma de fazer isso pela tela.

O grupo "Sem etapa definida" **não emite alvo** — um alvo com etapa vazia não pré-preencheria nada e mentiria sobre herdar algo.

> **O tradutor de dia ignora o alvo de etapa de propósito** (`targetToRangeValue`): ele cai no ramo genérico (`dayDefault = 0`), que é inerte sob perfil porque com etapa preenchida o wizard omite todas as chaves de dia.

### 12.9 O `trim` da etapa é load-bearing

O `match_titles` compara `config->>'etapa_trigger'` **cru**, enquanto o `fetch_titles` faz `btrim` no valor gravado em `resolved_etapa`. Uma etapa com espaço na ponta (típico de colar de planilha ou de JSON do n8n) **nunca casaria** — passo morto para sempre, sem erro, sem aviso, sem nada na tela.

Por isso o trim acontece em **dois pontos visíveis**: no `onBlur` do `Input` (o operador vê o espaço desaparecer) e no `commit` do combobox.

---

## 13. Versionamento e publicação

Fontes: `versioning/PublishDialog.tsx`, `versioning/VersionHistoryPanel.tsx`, `src/types/workflow-versioning.ts`, `src/hooks/useWorkflowVersions.ts`.

### 13.1 Modelo de dados

**Status de versão** (`WorkflowVersionStatus`): `draft` | `published` | `archived` | `superseded`.

| Status | Rótulo | Cores (`getVersionStatusColor`) | Ícone no painel |
|---|---|---|---|
| `draft` | **Rascunho** | `bg-amber-50 text-amber-700 border-amber-300` | `GitBranch` âmbar |
| `published` | **Publicada** | `bg-green-50 text-green-700 border-green-300` | `Check` verde |
| `archived` | **Arquivada** | `bg-gray-50 text-gray-500 border-gray-300` | `Archive` cinza |
| `superseded` | **Substituída** | `bg-slate-50 text-slate-500 border-slate-300` | `Clock` slate |

**`WorkflowVersion`** carrega: `version_number`, `version_label`, `status`, `workflow_snapshot`, `steps_snapshot`, `published_at`, `published_by`, `superseded_at`, `superseded_by`, `notes`, `change_summary`, `created_at`, `created_by`.

**`WorkflowSnapshot`**: `name`, `description`, `workflow_type`, `trigger_type` (`filter`/`manual`/`webhook`), `trigger_config`, `assignment_filters`, `is_active`.

**`WorkflowStepSnapshot`**: `id`, `step_order`, `step_type`, `name`, `config`, `position_x`, `position_y`, `is_active`.

> ⚠️ **Nota de arquitetura relevante ao design** (comentário em `profileStepConfig.ts`): `public.restore_workflow_steps` **só reinsere** `step_type`, `step_order`, `config`, `position_x` e `position_y`. Coluna nova em `workflow_steps` **se perde** no restore — é assim que `integration_id` (coluna) e `is_active` já se perdem hoje. Por isso as chaves de perfil vivem dentro do `config` jsonb.

### 13.2 `PublishDialog` — Publicar Nova Versão

**Gatilho**: botão "Publicar" no header do editor (`canWrite && hasUnpublishedChanges`, `disabled` se `hasIncompleteSteps`).

**Layout**: `DialogContent sm:max-w-[500px]`.

- **`DialogTitle`**: ícone `Rocket h-5 w-5 text-primary` + "**Publicar Nova Versão**"
- **`DialogDescription`**: "Você está prestes a publicar uma nova versão de **{nome da régua}**."

**Corpo** (`space-y-6 py-4`):

**1. Resumo das Alterações** — `rounded-lg border p-4 bg-muted/50`, `h4` com ícone `Info h-4` + "Resumo das Alterações".

| Caso | Render |
|---|---|
| Primeira versão | "Esta será a primeira versão publicada desta régua." |
| Ações adicionadas | Linha `text-green-600` com `Plus h-4` — "{N} ação/ações adicionada(s)" |
| Ações removidas | Linha `text-red-600` com `Minus h-4` — "{N} ação/ações removida(s)" |
| Só modificações | Linha `text-amber-600` com `Pencil h-4` — "Configurações de ações modificadas" |

Rodapé do bloco (`mt-3 pt-3 border-t text-sm text-muted-foreground`): "Total: **{N}** ação/ações".

> ⚠️ `stepsModified` é calculado de forma **simplificada**: conta todos os passos que existem nas duas versões, sem comparar conteúdo (o próprio comentário diz "Simplified: count steps that exist in both but might have changed"). Por isso a linha "Configurações de ações modificadas" aparece sempre que há passos em comum e nenhum foi adicionado/removido — mesmo que nada tenha mudado.

**2. Label da versão (opcional)** — `Input` `id="version-label"`, placeholder `v{próximo número}`, ajuda: `Ex: "Release Janeiro", "Hotfix WhatsApp", etc.`

**3. Notas (opcional)** — `Textarea rows={3}`, placeholder "Descreva as principais mudanças nesta versão...".

**4. Alerta** — `Alert` com `AlertCircle h-4`: "Ao publicar, esta versão será usada para processar novos contatos que entrarem na régua."

**5. Confirmação obrigatória** — `Checkbox` `id="confirm"` + `Label` "Entendo que esta versão será usada em produção".

**Rodapé**:
- "Cancelar" (`outline`), `disabled` enquanto publica
- Botão principal: "**Publicar v{N}**" com `Rocket h-4 mr-2`. **`disabled` enquanto o checkbox não está marcado** ou enquanto pendente. Durante a publicação, o texto vira "**Publicando...**" (sem ícone).

**Ao publicar**: `createVersion.mutateAsync({ workflow_id, version_label: versionLabel || "v{N}", notes, auto_publish: true })`.
- Sucesso: toast "**Versão publicada** / A versão v{N} foi publicada com sucesso.", reseta o formulário e fecha.
- Erro: toast destrutivo "Erro ao publicar versão" + a mensagem.

**Ao fechar sem publicar**: reseta `versionLabel`, `notes` e `confirmed`.

`nextVersionNumber = (versions?.length || 0) + 1`.

### 13.3 `VersionHistoryPanel` — Histórico de Versões

**Gatilho**: botão "Histórico" no header do editor (visível para **qualquer** papel).

**Layout**: `Sheet` lateral, `SheetContent w-[400px] sm:w-[540px]`.

- **`SheetTitle`**: `GitBranch h-5 w-5` + "**Histórico de Versões**"
- **`SheetDescription`**: "Visualize e restaure versões anteriores desta régua de cobrança."
- **Corpo**: `ScrollArea h-[calc(100vh-140px)] mt-6 pr-4`

**Cartão de versão** (`space-y-4` entre eles):

- **Conector de timeline**: `absolute left-4 top-12 bottom-0 w-0.5 bg-border -mb-4 z-0` — traço vertical ligando os cartões, **exceto no último**.
- Container: `relative z-10 p-4 border rounded-lg`. Versão publicada ganha `border-green-200 bg-green-50/50`; as demais, `hover:bg-muted/50`.
- **Cabeçalho** (`flex items-start justify-between gap-3`):
  - Círculo `h-8 w-8 rounded-full` com o `bg` do status e o ícone do status
  - "v{version_number}" em `font-medium`, seguido de `version_label` em `text-sm text-muted-foreground` (se houver)
  - Badge de status (`outline mt-1 text-xs` com as três classes de cor)
  - **Botão "Restaurar"** (`outline sm`, `RotateCcw h-3`) — **só para versões que NÃO são `draft`**; `disabled` enquanto restaura
- **Notas** (`mt-2 text-sm text-muted-foreground pl-11`)
- **Change summary** (`mt-1 text-sm text-muted-foreground pl-11 italic`)
- **Metadados** (`mt-3 pl-11 flex flex-wrap gap-4 text-xs text-muted-foreground`):
  - `Calendar h-3` + tempo relativo: `published_at` se `published`, senão `created_at` (`formatDistanceToNow` com `ptBR`)
  - `Layers h-3` + "{N} ações" (do `steps_snapshot`)

**Loading**: três cartões esqueleto (`Skeleton h-8 w-8 rounded-full` + duas barras).

**Vazio**: `text-center py-12 text-muted-foreground` com `GitBranch h-12 w-12 opacity-50`, "Nenhuma versão encontrada." e "Publique sua primeira versão para começar."

### 13.4 Restaurar versão — confirmação

`AlertDialog` disparado pelo botão "Restaurar".

- **Título**: "**Criar rascunho a partir desta versão?**"
- **Descrição**: "Você está prestes a criar um novo rascunho com o conteúdo da versão **v{N}**. Isso irá:" seguida de lista (`list-disc list-inside`):
  1. "Criar um novo rascunho com as configurações desta versão"
  2. "A versão publicada atual continuará ativa"
  3. "Você poderá revisar e publicar o rascunho quando estiver pronto"
- **Botões**: "Cancelar" (`AlertDialogCancel`, `disabled` enquanto pendente) e "**Criar Rascunho**" (vira "**Criando...**" enquanto pendente).

**Sucesso**: toast "**Rascunho criado** / Um novo rascunho foi criado com o conteúdo da versão v{N}. Publique quando estiver pronto."
**Erro**: toast destrutivo "Erro ao restaurar versão" + a mensagem.

> **Semântica importante**: restaurar **não** reverte a produção — cria um **rascunho**. A versão publicada continua ativa até alguém publicar o rascunho.

### 13.5 Detecção de "alterações não publicadas"

`hasUnpublishedChanges` no `ReguasCobrancaEditorPage`, na ordem:

1. Sem versão publicada → **true** (tudo é não publicado)
2. Existe versão e a mais recente é `draft` → **true**
3. Sem `workflow` carregado → false
4. Comparação campo a campo com o snapshot publicado:
   - `name`, `description`, `is_active`
   - `JSON.stringify(assignment_filters)`, `JSON.stringify(trigger_config)`
   - contagem de passos
   - por passo atual: `name`, `step_type`, `JSON.stringify(config)`; passo não encontrado no snapshot → **true**
   - passos do snapshot ausentes no estado atual → **true**

> ⚠️ A comparação **não inclui** `is_active` do passo nem `position_y`. Ligar/desligar um passo ou reordenar a timeline **não** marca a régua como tendo alterações não publicadas (embora o `PublishDialog` publique tudo).

---

## 14. Auditoria (`AuditLogPanel`)

Fontes: `audit/AuditLogPanel.tsx`, `src/hooks/useWorkflowAuditLogs.ts`, `src/types/workflow-versioning.ts`.

### 14.1 Gatilho e layout

**Gatilho**: botão "Logs" no header do editor (visível para qualquer papel).

**Layout**: `Sheet` lateral, `SheetContent w-[400px] sm:w-[540px]`.

- **`SheetTitle`**: `FileText h-5 w-5` + "**Histórico de Alterações**"
- **`SheetDescription`**: "Veja todas as alterações realizadas nesta régua de cobrança."

### 14.2 Filtro

Um `Select w-[180px]`, placeholder "Filtrar por ação":

| Valor | Rótulo |
|---|---|
| `all` | Todas as ações |
| `created` | Criação |
| `updated` | Atualização |
| `step_added` | Ação adicionada |
| `step_updated` | Ação atualizada |
| `step_deleted` | Ação removida |
| `activated` | Ativação |
| `deactivated` | Desativação |
| `version_published` | Publicação |
| `version_restored` | Restauração |

> ⚠️ **O filtro não oferece** `deleted`, `step_reordered` nem `version_created`, embora esses três existam no tipo `WorkflowAuditAction` e tenham ícone e rótulo. Registros desses tipos aparecem em "Todas as ações", mas não podem ser isolados.

### 14.3 Catálogo de ações

| `action` | Rótulo (`getAuditActionLabel`) | Ícone e cor |
|---|---|---|
| `created` | Criou | `Plus` verde |
| `updated` | Atualizou | `Pencil` azul |
| `deleted` | Excluiu | `Trash2` vermelho |
| `step_added` | Adicionou ação | `PlusCircle` verde |
| `step_updated` | Atualizou ação | `Settings` âmbar |
| `step_deleted` | Excluiu ação | `MinusCircle` vermelho |
| `step_reordered` | Reordenou ações | `ArrowUpDown` roxo |
| `activated` | Ativou | `Play` verde |
| `deactivated` | Desativou | `Pause` âmbar |
| `version_created` | Criou versão | `GitBranch` azul |
| `version_published` | Publicou versão | `Rocket` primary |
| `version_restored` | Restaurou versão | `RotateCcw` roxo |

### 14.4 Agrupamento e cabeçalho de data

Os registros são agrupados por data (`groupAuditLogsByDate`). Cada grupo tem um cabeçalho **sticky** (`sticky top-0 bg-background py-2 z-10`) com duas linhas horizontais (`h-px flex-1 bg-border`) e o rótulo da data ao centro (`text-xs font-medium text-muted-foreground px-2`):

| Data | Rótulo |
|---|---|
| hoje | "**Hoje**" |
| ontem | "**Ontem**" |
| outras | a própria data em `pt-BR` |

### 14.5 Entrada de log

`flex items-start gap-3 p-2 rounded-lg hover:bg-muted/50 transition-colors`:

1. **Ícone**: círculo `h-8 w-8 rounded-full bg-muted shrink-0` com o ícone da ação.
2. **Conteúdo** (`flex-1 min-w-0`):
   - Texto principal (`text-sm`): `changes_summary` **ou**, se ausente, o rótulo da ação.
   - Metadados (`flex items-center gap-2 mt-1 text-xs text-muted-foreground`): hora (`HH:mm`, `date-fns` com `ptBR`), e, quando há `user_email`, separador `•` + ícone `User h-3 w-3` + **o e-mail truncado antes do `@`**.
3. **Botão de expandir** (`ghost sm h-6 w-6 p-0`, `ChevronRight`/`ChevronDown`): **só quando `action === "step_updated"` e há `old_values`/`new_values`**.

### 14.6 Detalhe de alterações (`renderChanges`)

**Só para `step_updated`**, e só quando os dois lados existem. Compara chave a chave via `JSON.stringify` e monta uma lista de diferenças.

Render: `mt-2 pl-4 border-l-2 border-muted text-xs space-y-1`. Cada mudança:

```
{campo}:  {valor antigo, riscado, text-red-400}  {valor novo, text-green-600}
```

**Limite de 5 mudanças** exibidas; acima disso, uma linha `text-muted-foreground italic` — "+{N} mais alterações".

**Formatação de valores (`formatValue`)**:

| Tipo | Formato |
|---|---|
| `null`/`undefined` | "**vazio**" |
| `boolean` | "**sim**" / "**não**" |
| `object` | `JSON.stringify(...)` truncado em **30** caracteres + "..." |
| demais | `String(...)` truncado em **50** caracteres (sem reticências) |

> ⚠️ O nome do campo é exibido **cru** (`step_type`, `days_overdue_trigger`, `etapa_min_days`...), sem tradução. Oportunidade clara de melhoria no redesign.

### 14.7 Paginação

`limit` inicial **50**. Quando `data.hasMore`, aparece um botão `outline sm` centralizado — "**Carregar mais**" — que soma 50 ao limite (refetch com o limite maior, não paginação por offset).

### 14.8 Estados

| Estado | Render |
|---|---|
| Carregando | 5 linhas esqueleto (círculo + duas barras) |
| Vazio | `text-center py-12 text-muted-foreground` com `FileText h-12 w-12 opacity-50`, "Nenhum registro de alteração encontrado." e "As alterações feitas na régua aparecerão aqui." |

---

## 15. Vínculo com carteiras/filtros e integração em massa

### 15.1 `AssignmentFiltersPanel`

Fonte: `src/components/reguas-cobranca/AssignmentFiltersPanel.tsx`. Renderizado dentro do `ReguaDialog`.

**Estrutura** (`space-y-6`):

**Cabeçalho próprio** (redundante com o rótulo do `ReguaDialog`): ícone `Filter h-4 w-4` + `h3 font-semibold text-sm` "Filtros de Atribuição", e `p text-xs text-muted-foreground` "Define quais contatos serão incluídos nesta régua de cobrança".

**Campo 1 — Carteiras** (`space-y-2`):
- `Label` com ícone `Briefcase h-3 w-3` + "Carteiras"
- Linha de estado (`text-sm text-muted-foreground mt-1`): "{N} carteira(s) selecionada(s)" ou "**Todas as carteiras**"
- `MultiSelect` com opções de `usePortfolios()` (`{ value: id, label: name, color, icon }`), placeholder "Todas as carteiras"

**Campo 2 — Filtros Cadastrados** (`space-y-2`):
- `Label` com ícone `ListFilter h-3 w-3` + "Filtros Cadastrados"
- Ajuda: "Selecione filtros salvos na tela de Filtros"
- `MultiSelect` com opções de `useFilters({ pageSize: 200 })`, placeholder "Nenhum filtro selecionado", prop `showAllSelected`
- **Ao mudar**, sempre persiste `aggregation_logic` explícito (default `"AND"`)

**Campo 3 — Lógica de Agregação** (`space-y-3`) — **só aparece com mais de 1 filtro selecionado**:
- `Label` com ícone `GitMerge h-3 w-3` + "Lógica de Agregação"
- Ajuda: "Como os **filtros** selecionados devem ser combinados entre si"
- `RadioGroup space-y-3`, cada opção num cartão `flex items-start space-x-3 p-3 rounded-lg border bg-card hover:bg-accent/50 cursor-pointer`:

| Valor | Rótulo | Descrição |
|---|---|---|
| `AND` (default) | **E (AND)** | "O contato deve atender **todos** os filtros selecionados" |
| `OR` | **OU (OR)** | "O contato deve atender **pelo menos um** dos filtros selecionados" |

**Bloco de resumo** (`bg-muted p-3 rounded-md text-xs space-y-2`): "Resumo da atribuição:" seguido de `<ul>`:

| Linha | Ícone | Conteúdo |
|---|---|---|
| Carteiras | `Briefcase h-3 w-3` | "{N} carteira(s)" ou "Todas as carteiras" |
| Filtros | `ListFilter h-3 w-3` | "{N} filtro(s) aplicado(s)" ou "Nenhum filtro aplicado" |
| Lógica (só com > 1 filtro) | `GitMerge h-3 w-3` | "Lógica de filtros: {AND\|OR}" em `font-medium` |
| Nota final (`border-t pt-2 mt-2`) | — | "✓ Carteiras e filtros são **sempre combinados com intersecção (AND)**" |

> **Regra de negócio explícita na UI**: a lógica `AND`/`OR` escolhida vale **entre os filtros**. A combinação entre o conjunto de carteiras e o conjunto de filtros é **sempre AND**. Isso está declarado apenas nessa última linha do resumo — informação crítica e facilmente perdida.

### 15.2 `BulkIntegrationDialog` — Trocar integração em massa

Fontes: `BulkIntegrationDialog.tsx`, `src/hooks/useWorkflowBulkIntegration.ts`.

**Gatilho**: botão "Trocar integração" no header do editor (`canWrite`, `data-testid="bulk-integration-trigger"`). Comentário de código: "ação de escopo RÉGUA, separada visualmente das ações de step para não ser clicada por engano".

**Layout**: `DialogContent max-w-2xl`.

- **Título**: ícone `Replace h-5 w-5` + "**Trocar integração em massa**"
- **Descrição**: "Escolha um ou mais canais e a integração de destino de cada um. Todos os steps correspondentes serão atualizados juntos. A troca vale para as **próximas** ações — as que já estão pendentes continuam saindo pela integração anterior."

**Passo 1 — Canal**: `Label` "Canal" + botões-pílula `size="sm"` que alternam seleção (`variant="default"` quando selecionado, `outline` quando não; `aria-pressed`):

| Canal | Rótulo | `integrationType` |
|---|---|---|
| `send_whatsapp` | WhatsApp | `whatsapp` |
| `send_email` | E-mail | `email` |
| `send_sms` | SMS | `sms` |
| `send_rcs` | RCS | `rcs` |
| `send_voice` | Voz | `voice` |

> Só canais que **têm** integração. `wait`, `condition` e `block` não aparecem.

**Passo 2 — Integrações de destino**: `Label` "Integrações de destino". Para cada canal selecionado, um cartão `rounded-md border p-3` com um `IntegrationSelector`. Sem canal selecionado: "Escolha ao menos um canal para configurar as integrações."

**Passo 3 — Preview obrigatório**: botão `outline w-full` — "**Ver o que muda**". Habilitado só quando há ≥ 1 canal **e** todos têm integração escolhida.

> **Preview não é decorativo** (comentário no código): a operação reconfigura uma régua que pode estar ativa, e o efeito só aparece nos disparos seguintes. O preview vem da **mesma RPC** da aplicação (`workflow_bulk_update_integrations` com `p_dry_run`), então prévia e efeito não podem divergir.

**Invalidação do preview**: toda mudança em `channels` ou `integrationIds` zera o preview. Sem isso, daria para revisar uma lista, trocar o canal e aplicar — confirmando uma coisa e executando outra. Fechar o diálogo também reseta tudo.

**Erro do preview**: `Alert variant="destructive"` com `AlertCircle` e a mensagem do erro.

**Resultado do preview:**

| Caso | Render |
|---|---|
| `affected_count === 0` | `Alert` com `AlertCircle`: "Esta régua não tem nenhum step dos canais escolhidos. Nada será alterado." |
| Com passos | "**{N}** step(s) serão atualizados em **{M}** canal(is)." + tabela |

**Alerta de divergência** (quando há `has_divergence`): `Alert variant="destructive"` com texto `text-xs`:

> "{N} step(s) têm a coluna `integration_id` preenchida. Nesses, o motor ignoraria a alteração, então a operação será **recusada por inteiro**. Trate esses steps antes de aplicar."

**Tabela de preview** (`ScrollArea h-56 rounded border`, `table w-full text-xs`, cabeçalho `bg-muted/50`):

| Coluna | Conteúdo |
|---|---|
| Ordem | `step_order` |
| Step | `step_name ?? "—"` |
| Canal | `step_type` (valor cru) |
| Hoje dispara por | `current_integration_id ?? "—"` em `font-mono`, com `Badge variant="destructive"` "**divergente**" quando aplicável |
| Passará a usar | `target_integration_name ?? target_integration_id` |

**Rodapé**:
- "Cancelar" (`outline`)
- Botão principal: "**Aplicar a {N} step(s)**", **desabilitado** quando: não há preview, `affected_count === 0`, há passos bloqueados, ou a aplicação está pendente. Mostra `Loader2` girando enquanto aplica.

**Feedback da aplicação** (no hook):
- `affected_count === 0`: toast "**Nenhum step alterado** / Esta régua não tem steps dos canais selecionados. Nada foi modificado."
- Sucesso: toast "**{N} step(s) atualizados em massa** / Vale para as PRÓXIMAS ações. Ações já pendentes continuam saindo pela integração anterior."
- Erro: toast destrutivo "**Não foi possível trocar a integração**" + a mensagem, com `logError`.
- Invalida as query keys `workflow-steps`, `workflows` e `workflow-audit-logs`.

> **Conceito de "divergência"**: existe uma **coluna** `integration_id` vestigial em `workflow_steps`, além da chave `integration_id` dentro do `config`. Quando a coluna está preenchida, ela "vence" na leitura do motor — e uma escrita só no config seria ignorada. A RPC **falha alto** nesse caso em vez de aplicar uma escrita inócua.

---

## 16. Modais do domínio — blocos completos

### 16.1 `ReguaDialog` — Nova Régua / Editar Régua

Ver §4 para o detalhamento completo. Resumo:

| Aspecto | Valor |
|---|---|
| **Objetivo** | Criar régua ou editar metadados + público |
| **Gatilhos** | "Nova Régua"; "Editar" no menu; clique na linha/card; "Configurações" no editor |
| **Tamanho** | `w-[95vw] h-[95vh]` |
| **Campos** | Tipo de Régua (só criação), Tipo de Cobrança (condicional), Nome*, Descrição, Filtros de Atribuição, Régua Ativa |
| **Botões** | "Cancelar" (sem confirmação) / "Criar Régua" ou "Salvar Alterações" |
| **Confirmação** | nenhuma |
| **Estados** | `isSubmitting` desabilita o submit e mostra spinner |
| **Pós-ação** | Criação → redirect para o editor. Edição → fecha e fica na listagem. Sempre invalida contagens. |
| **Erro** | **apenas `logError`** — sem toast, sem mensagem na tela ⚠️ |

### 16.2 `AddStepDialog` → `StepWizard` (create)

| Aspecto | Valor |
|---|---|
| **Objetivo** | Criar um passo, completo, numa única gravação |
| **Gatilhos** | "Adicionar" no cabeçalho de um grupo; "Adicionar canal" na cauda; "Adicionar Ação em Novo Dia/Nova Etapa" no rodapé; "Adicionar Primeira Ação" no estado vazio |
| **Tamanho** | `h-[95vh] w-[95vw] max-w-none` |
| **Título** | "Novo passo da régua" ou "Adicionar canal à cauda" (alvo = cauda) |
| **Fases** | 3 a 5, conforme o tipo escolhido |
| **Navegação** | Linear (stepper só volta) |
| **Confirmação** | nenhuma; o passo nasce no botão "Criar passo" |
| **Estados** | `isSubmitting` bloqueia o submit; falha mantém o modal aberto com os dados |
| **Fechar sem salvar** | **Sem guarda** — clicar fora ou ESC descarta tudo ⚠️ |

### 16.3 `StepConfigSheet` → `StepWizard` (edit)

| Aspecto | Valor |
|---|---|
| **Objetivo** | Reconfigurar um passo existente |
| **Gatilhos** | Clique no card do passo; botão de engrenagem no card |
| **Título** | "Configurar passo" |
| **Fases** | 3 ou 4 (sem a fase "Ação" — o tipo não se troca) |
| **Navegação** | Livre; fases inválidas marcadas em vermelho no stepper |
| **Botão** | "Salvar" em qualquer fase, "Salvar alterações" na última |
| **Exclusão** | **não existe aqui** — a lixeira ficou no `StepCard` |
| **Fechar sem salvar** | **Sem guarda** ⚠️ |

> Nota do código: o roteamento "tipo → canal" que vivia neste arquivo foi **removido** (não sincronizado) porque duas rotas divergentes significariam "fase que abre num formulário vazio". Hoje há uma rota só, em `stepWizardPhases.ts`.

### 16.4 `AlertDialog` de exclusão de passo (dentro do `StepCard`)

| Aspecto | Valor |
|---|---|
| **Objetivo** | Confirmar a exclusão de um passo |
| **Gatilho** | Botão `Trash2` no card |
| **Título** | "**Excluir ação**" |
| **Descrição** | "Tem certeza que deseja excluir a ação "{nome ou rótulo do tipo}"? Esta ação não pode ser desfeita." |
| **Botões** | "Cancelar" / "**Excluir**" (`bg-destructive text-destructive-foreground hover:bg-destructive/90`) |
| **Estado** | não mostra progresso — fecha imediatamente ao confirmar |

### 16.5 `window.confirm` de exclusão de régua

| Aspecto | Valor |
|---|---|
| **Objetivo** | Confirmar exclusão de uma régua inteira |
| **Gatilho** | Item "Excluir" no menu de ações (só com `workflows:delete`) |
| **Implementação** | **`window.confirm` nativo do navegador** ⚠️ |
| **Texto** | "Tem certeza que deseja excluir esta régua de cobrança? Todas as ações serão removidas." |
| **Feedback** | nenhum toast de sucesso ou erro na página ⚠️ |

> **Inconsistência gritante de UX**: excluir um **passo** usa um `AlertDialog` estilizado; excluir a **régua inteira** (operação muito mais destrutiva) usa o diálogo nativo do navegador. Item prioritário para o redesign.

### 16.6 `AlertDialog` de desativação com campanhas dependentes

| Aspecto | Valor |
|---|---|
| **Objetivo** | Avisar que desativar a régua pausa campanhas ativas em cascata |
| **Gatilho** | Desligar o switch de uma régua que tem campanhas ativas apontando para ela |
| **Título** | "**Desativar régua?**" |
| **Corpo** | Parágrafo: "Esta régua é usada por **{N}** campanha(s) ativa(s):" + `<ul>` com o nome de cada campanha. Depois: "Desativar a régua vai **pausar** essas campanhas automaticamente. Mensagens já agendadas na fila continuarão sendo enviadas." E, em `text-xs text-muted-foreground`: "Reativar a régua depois **não** reativa as campanhas — isso precisa ser feito manualmente na página de Campanhas." |
| **Botões** | "Cancelar" / "**Desativar régua e pausar {N} campanha(s)**" |
| **Pós-ação** | Toast "Régua desativada / {N} campanha(s) pausada(s) em cascata." |

> **Assimetria proposital**: **ativar** não pede confirmação. Só desativar, e só quando há dependentes.

### 16.7 `EditCaudaDialog` — Editar faixa da cauda

| Aspecto | Valor |
|---|---|
| **Objetivo** | Editar a faixa e a cadência de **todos** os passos do grupo de cauda de uma vez |
| **Gatilho** | Botão "Editar" no cabeçalho do grupo de cauda |
| **Tamanho** | `max-w-lg` |
| **Título** | "**Editar faixa da cauda**" |
| **Descrição** | "A faixa e a cadência valem para todas as ações deste grupo." |
| **Campos** | `DaysOverdueRangeInput` com `hideModeToggle` (De, Até, Intervalo mínimo) |
| **Validação** | `isTriggerRangeValid`; mensagem `text-xs text-destructive`: `"Até" deve ser maior ou igual a "De".` |
| **Botões** | "Cancelar" (`outline`, `disabled` enquanto salva) / "Salvar" (`disabled` se inválido ou salvando, com `Loader2`) |
| **Fechar** | `onOpenChange` só fecha quando **não** está salvando |
| **Re-hidratação** | `useEffect` sobre `[open, initial]` — re-preenche sempre que abre com um grupo selecionado |
| **Persistência** | O dialog **só mexe** em `days_overdue_trigger`/`repeat_every_days`/`days_overdue`. Quem preserva o resto do config de cada passo é o caller, via `mergeTriggerIntoConfig`. |

### 16.8 `PublishDialog` — Publicar Nova Versão

Ver §13.2. Resumo: `sm:max-w-[500px]`, resumo de alterações, label opcional, notas opcionais, alerta, **checkbox obrigatório** "Entendo que esta versão será usada em produção", botões Cancelar / "Publicar v{N}".

### 16.9 `VersionHistoryPanel` — Histórico de Versões

Ver §13.3. `Sheet` lateral `w-[400px] sm:w-[540px]`, timeline vertical de cartões de versão, botão "Restaurar" por versão (exceto `draft`), `AlertDialog` de confirmação que cria um **rascunho**.

### 16.10 `AuditLogPanel` — Histórico de Alterações

Ver §14. `Sheet` lateral `w-[400px] sm:w-[540px]`, filtro por ação, agrupamento por data com cabeçalho sticky, entradas expansíveis (só `step_updated`), "Carregar mais" de 50 em 50.

### 16.11 `BulkIntegrationDialog` — Trocar integração em massa

Ver §15.2. `max-w-2xl`, seleção multi-canal por pílulas, um `IntegrationSelector` por canal, **preview obrigatório** antes de aplicar, tabela DE → PARA, bloqueio total quando há divergência de coluna vestigial.

### 16.12 `CreateTemplateDialog` — Criar Template de Ativação

Ver §10.3. `sm:max-w[600px]`, aninhado dentro do `TemplateHSMSelector` (que por sua vez está dentro do wizard) — **modal dentro de modal**. Campos: Nome*, Descrição, Conteúdo*. Ao criar, o template é auto-selecionado no passo.

> ⚠️ **Profundidade de empilhamento**: no fluxo de WhatsApp com template novo, o usuário chega a **Editor → StepWizard (95vw/95vh) → CreateTemplateDialog**. Três camadas. Ponto de atenção para o redesign.

---

## 17. Estados das telas

### 17.1 Lista `/reguas-cobranca`

| Estado | Condição | Render |
|---|---|---|
| **Carregando** | `isLoading` | `ReguasPageSkeleton viewMode={viewMode} count={6}`. Em `list`: um cabeçalho de 6 barras + 6 linhas (pílula, duas barras de texto, dois números, um switch e um botão). Em `grid`: 6 `Card` com badge, título, barra de descrição e conteúdo esqueleto. |
| **Erro** | `isError` | `text-center py-12 text-destructive` — "**Erro ao carregar réguas**". Sem botão de retry. ⚠️ |
| **Vazio** | `data.workflows.length === 0` | `Card` com `CardContent flex flex-col items-center justify-center py-12`: ícone `GitBranch h-12 w-12 text-muted-foreground mb-4`, `h3 text-lg font-medium` "**Nenhuma régua encontrada**", `p text-muted-foreground mt-1` "Tente ajustar os filtros de busca" (com busca) ou "Crie sua primeira régua de cobrança", e — **só quando não há busca e há `canWrite`** — botão "Nova Régua" (`mt-4`, `Plus`). |
| **Contagens carregando** | `isLoadingCounts \|\| !counts` | Skeletons por célula (tabela) ou dois skeletons de linha (card). A lista **já aparece** enquanto os números carregam — são queries separadas. |
| **Atualizando** | `isFetching \|\| isFetchingCounts` | `RefreshButton` em estado de progresso. Os dados anteriores continuam visíveis. |
| **Duplicando** | `duplicateRegua.isPending` | Item de menu vira "Duplicando..." e fica `disabled`. |
| **Sem permissão de escrita** | `!canWrite` | Somem: botão "Nova Régua", itens "Editar" e "Duplicar" do menu; os `Switch` ficam `disabled`. |
| **Sem permissão de exclusão** | `!canDelete` | Some o separador + item "Excluir". |

### 17.2 Editor `/reguas-cobranca/:id/editor`

| Estado | Condição | Render |
|---|---|---|
| **Carregando** | `isLoading` | Tela inteira (`h-screen flex items-center justify-center`) com `Loader2 h-8 w-8 animate-spin`. **Sem header, sem esqueleto** — a tela some por completo. ⚠️ |
| **Não encontrada** | `!workflow` | `h-screen flex flex-col items-center justify-center`: "**Régua não encontrada**" + botão "Voltar". |
| **Salvando** | `isMutating` | Header mostra `Loader2` + "**Salvando...**". A timeline continua interativa; `isUpdating` desabilita os switches dos cards. |
| **Ocioso** | — | Header mostra `Save` + "**Salvo**". |
| **Rascunho não publicado** | `hasUnpublishedChanges` | Badge `secondary` "**Draft v{N+1}**" com tooltip "Alterações não publicadas"; botão "**Publicar**" aparece (se `canWrite`). |
| **Publicada e sincronizada** | `!hasUnpublishedChanges` | Badge `default` "**v{N} Publicada**" com tooltip "Publicada há X"; o botão "Publicar" **some**. |
| **Passos incompletos** | `hasIncompleteSteps` | "Publicar" fica `disabled`; ativar a régua dispara toast destrutivo e é abortado; os cards afetados ficam âmbar com badge "Incompleta" ou "Integração Inválida". |
| **Sem versão publicada e inativa** | `!publishedVersion && !workflow.is_active` | Switch de ativação `disabled` com tooltip "**Publique uma versão para ativar a régua**". |
| **Timeline vazia** | `steps.length === 0` | Bloco centralizado "Nenhuma ação configurada" + botão "Adicionar Primeira Ação" (se `canWrite`). |
| **Grupo vazio** | grupo com 0 passos | Texto contextual + botão de adicionar dentro do grupo. |
| **Sem permissão de escrita** | `!canWrite` | Somem: "Publicar", "Trocar integração", "Configurações". A `TimelineView` recebe `onToggleStep`, `onDeleteStep`, `onDuplicateStep`, `onAddStep`, `onReorderSteps` e `onSaveCauda` como `undefined` — desaparecem switch, lixeira, duplicar, botões de adicionar e "Editar" da cauda, e o drop vira no-op. |
| **Sem dados de custo** | `channelCosts` vazio/ausente | `costData = null` — nenhum valor de custo aparece (nem por passo, nem por grupo, nem no rodapé). |

### 17.3 Guarda de saída — **não existe**

⚠️ **Não há nenhuma guarda de saída em lugar nenhum deste domínio:**

| Superfície | Comportamento ao sair com alterações |
|---|---|
| `ReguaDialog` | "Cancelar", ESC ou clique fora **descartam** sem aviso |
| `StepWizard` (criar/editar) | ESC ou clique fora **descartam** todo o wizard sem aviso — inclusive uma mensagem longa recém-escrita |
| `EditCaudaDialog` | "Cancelar" descarta; **só** bloqueia o fechamento enquanto salva |
| `PublishDialog` | fecha e reseta label/notas/checkbox |
| `BulkIntegrationDialog` | fecha e reseta canais/integrações/preview |
| Botão "Voltar" do editor | não há o que perder — o editor salva automaticamente |
| Navegação do browser | nenhum `beforeunload` |

> No editor a ausência de guarda é coerente (salvamento automático). Nos **modais** é uma perda real de trabalho — especialmente no `StepWizard`, que por definição acumula estado não gravado até a última fase.

### 17.4 Estados de erro por superfície

| Superfície | Feedback de erro |
|---|---|
| Lista — carregar | Texto vermelho estático, sem retry |
| Lista — toggle | Toast destrutivo com a mensagem |
| Lista — verificar campanhas dependentes | Toast destrutivo, ação abortada |
| Lista — duplicar | Toast destrutivo genérico |
| Lista — excluir | **nenhum feedback** ⚠️ |
| `ReguaDialog` — salvar | **apenas `logError` no console** ⚠️ |
| Editor — toggle régua / toggle passo / reorder / duplicar passo | Toast destrutivo |
| Editor — salvar/criar/excluir passo | Toast destrutivo **+ relança** (mantém o wizard aberto) |
| Editor — salvar cauda | Toast destrutivo + relança |
| `PublishDialog` | Toast destrutivo com a mensagem do erro |
| `VersionHistoryPanel` — restaurar | Toast destrutivo com a mensagem |
| `BulkIntegrationDialog` — preview | `Alert variant="destructive"` **dentro** do modal |
| `BulkIntegrationDialog` — aplicar | Toast destrutivo + `logError` |
| `AIMessageAssistant` | Painel de erro **no lugar do conteúdo** (com retry) **+** toast destrutivo |

> **O `AIMessageAssistant` é o padrão mais maduro de tratamento de erro do domínio**: estado explícito, copy acionável por código, retry no lugar do conteúdo e invariante de "falha nunca vira sucesso". Vale como referência para o redesign dos demais.

---

## 18. Fluxos de uso passo a passo

### 18.1 Criar uma régua do zero até o ar

Baseado no roteiro do guia interno (`central-docs/negocio/data/editor-regua.ts`) + o código.

1. **Lista** → botão "**Nova Régua**".
2. **`ReguaDialog`**: escolher "Sequencial (Cobrança)", tipo de cobrança (se a org tem suprimento), nome, descrição, carteiras e filtros (com a lógica AND/OR se houver 2+ filtros). Deixar "Régua Ativa" desligada (é o default).
3. "**Criar Régua**" → a régua é criada e o app **redireciona para o editor**.
4. **Editor**, timeline vazia → "**Adicionar Primeira Ação**".
5. **Wizard, fase "Ação"**: escolher o tipo (ex.: WhatsApp) e, opcionalmente, um nome.
6. **Fase "Quando"**: escolher o dia de atraso (negativo = preventivo, `0` = vencimento, positivo = atraso) **ou** ligar "Step de cauda" e definir a faixa + intervalo mínimo.
7. **Fase "Integração"**: escolher a integração de WhatsApp e, se quiser, o template HSM.
8. **Fase "Conteúdo"**: escrever a mensagem (com "Inserir Variável" e/ou "Melhorar com IA"), mapear as variáveis do template Meta se houver, conferir a prévia.
9. **Fase "Revisar"**: conferir o resumo (Ação · Quando · Integração · Conteúdo), ajustar o nome, decidir se ativa o passo, e clicar "**Criar passo**". **É aqui que o passo nasce.**
10. Repetir 4–9 para os demais dias, escalonando a cobrança (lembrete, e-mail, ligação, notificação, negativação).
11. **Organizar**: arrastar os passos dentro de cada dia, ligar/desligar switches, conferir o custo estimado no rodapé.
12. **Resolver incompletos**: nenhum card pode estar com "Incompleta" ou "Integração Inválida" — eles bloqueiam publicar e ativar.
13. "**Publicar**" → `PublishDialog` → conferir o resumo, opcionalmente label e notas, **marcar o checkbox de produção**, "Publicar v1".
14. Ligar o **Switch "Ativa"** no header.
15. A partir daí, uma **campanha** ativa pode usar a régua para disparar de verdade.

### 18.2 Adicionar um canal a uma cauda existente

1. Na timeline, localizar o **grupo de cauda** (badge âmbar "De D+N em diante · a cada M dias").
2. Clicar em "**Adicionar canal**" no cabeçalho do grupo.
3. O wizard abre com o título "**Adicionar canal à cauda**".
4. Fase "Ação": escolher o tipo.
5. Fase "Quando": a faixa e a cadência aparecem **somente leitura** — herdadas do grupo. Nada a preencher.
6. Fases de Integração/Conteúdo (ou Configuração) normais.
7. "Criar passo".

### 18.3 Ajustar a faixa de uma cauda inteira

1. Cabeçalho do grupo de cauda → botão "**Editar**".
2. `EditCaudaDialog`: mudar "De (dia)", "Até (dia)" (vazio = `∞`) e "Intervalo mínimo entre envios".
3. Observar o **aviso âmbar** se a faixa ficar sem cadência.
4. "Salvar" → **todos** os passos do grupo são atualizados de uma vez, preservando mensagem, integração e template de cada um.
5. Toast: "Faixa atualizada / A faixa e a cadência foram atualizadas para todas as ações do grupo."

### 18.4 Montar uma régua de jornada (org com perfil `formalizacao`)

1. Editor: a timeline agrupa **por etapa**, com "Sem etapa definida" fixo no topo se houver passos sem etapa.
2. "**Adicionar Ação em Nova Etapa**" (rodapé) → wizard sem etapa pré-preenchida.
3. Fase "Ação": escolher o tipo.
4. Fase "Quando": **não há campo de dia nem switch de cauda**. Aparece o bloco "Formalização":
   - Escolher a **etapa** no combobox (lista de etapas que existem nos contatos, com contagem) ou digitar o valor cru.
   - Definir a **janela**: "do dia [ ] ao dia [ ]" — ambos opcionais. O rótulo derivado ("Enquanto estiver na etapa" / "Do dia 3 ao dia 7 na etapa") atualiza em tempo real.
   - Decidir "Disparar uma única vez por contato".
   - Decidir o **Destinatário** (contato ou endereço da variável do perfil).
5. Fases de Integração/Conteúdo.
6. Fase "Revisar": conferir o resumo (a etapa aparece com rótulo **e** valor cru) e observar os **avisos de sobreposição** — alerta âmbar se outro passo da mesma etapa usa o mesmo canal nos mesmos dias; nota informativa se usa canal diferente.
7. "Criar passo".
8. Para adicionar outro passo **na mesma etapa**: "Adicionar" no cabeçalho **daquele grupo** — a etapa vem travada e pré-preenchida.

### 18.5 Corrigir um passo que não dispara (org com perfil)

1. Abrir o editor. O grupo "**Sem etapa definida**" está no topo, com ícone e badge destrutivos e o texto "Não dispara — defina a etapa".
2. Clicar no card do passo → wizard em modo edição, com **ponto vermelho** no stepper na fase "Quando".
3. Fase "Quando" → preencher a etapa.
4. "Salvar" (disponível em qualquer fase no modo edição).
5. O passo migra para o grupo da etapa na timeline.

### 18.6 Trocar o provedor de WhatsApp de uma régua inteira

1. Editor → "**Trocar integração**".
2. Selecionar a pílula "WhatsApp" (e outras, se quiser).
3. Escolher a integração de destino de cada canal selecionado.
4. "**Ver o que muda**" → tabela com Ordem · Step · Canal · Hoje dispara por · Passará a usar.
5. Se houver passos "**divergente**": a operação é bloqueada por inteiro; tratar esses passos antes.
6. "**Aplicar a {N} step(s)**".
7. Toast confirma e lembra que vale para as **próximas** ações — as pendentes saem pela integração antiga.
8. O log de auditoria é invalidado e passa a mostrar o registro.

### 18.7 Voltar atrás numa mudança ruim

1. Editor → "**Histórico**".
2. Localizar a versão desejada na timeline de versões (pelo número, label, notas ou data).
3. "**Restaurar**" → confirmação explicando que será criado um **rascunho** e que a versão publicada continua ativa.
4. "Criar Rascunho" → toast confirma.
5. Revisar o rascunho no editor.
6. "**Publicar**" quando estiver pronto.

### 18.8 Desativar uma régua que está em uso

1. Lista → desligar o `Switch` da régua.
2. O app consulta as campanhas ativas que a referenciam.
3. Se houver: `AlertDialog` lista os nomes e explica — pausa em cascata; mensagens já agendadas continuam saindo; reativar a régua **não** reativa as campanhas.
4. "**Desativar régua e pausar {N} campanha(s)**".
5. Toast confirma quantas foram pausadas.

### 18.9 Usar o assistente de IA para escrever a mensagem

1. Fase "Conteúdo" → escrever ao menos **10 caracteres** (antes disso o botão está desabilitado, com `title` explicando).
2. "**Melhorar com IA**" → o popover abre e **já executa** a aba "Melhorar".
3. Ler a sugestão, e então:
   - "**Aplicar**" (substitui o corpo) → toast + popover fecha; ou
   - `RefreshCw` para gerar outra; ou
   - ir para "**Variações**" (executa sozinha), escolher uma e "**Aplicar Selecionada**"; ou
   - ir para "**Compliance**" (executa sozinha) e ler os pontos de atenção contra CDC e LGPD.
4. Em caso de falha: o painel de erro aparece **no lugar do conteúdo**, com a causa específica e "**Tentar novamente**". A aba **não** re-executa sozinha depois de um erro.

---

## 19. Responsividade e acessibilidade

### 19.1 Responsividade — o que está resolvido

| Superfície | Comportamento responsivo |
|---|---|
| **Lista — cabeçalho** | Título `text-xl sm:text-2xl`; subtítulo `hidden sm:block`; botão "Nova Régua" vira só ícone abaixo de `sm` (`size="icon" sm:w-auto sm:px-4`, texto em `hidden sm:inline`) |
| **Lista — filtros** | `flex-col sm:flex-row`, gaps `gap-3 sm:gap-4`; `Select` `w-full sm:w-[150px]` |
| **Lista — grid** | `grid gap-4 md:grid-cols-2 lg:grid-cols-3` — 1 / 2 / 3 colunas |
| **Lista — tabela** | `overflow-x-auto` no container. **13 colunas** roláveis horizontalmente. ⚠️ Em telas médias vira uma barra de rolagem longa. |
| **Lista — espaçamento raiz** | `space-y-4 sm:space-y-6` |
| **Fase "Conteúdo"** | `grid gap-6` com `lg:grid-cols-2` (editor + prévia) e `grid-cols-1` abaixo de `lg`; a prévia é `lg:sticky lg:top-4 lg:self-start` |
| **`ReviewStep` — `SummaryRow`** | `flex-col gap-1` empilhado; `sm:flex-row sm:items-baseline sm:gap-4` a partir de `sm` |
| **`VersionHistoryPanel` / `AuditLogPanel`** | `Sheet` `w-[400px] sm:w-[540px]` |
| **`PublishDialog`** | `sm:max-w-[500px]` |
| **`CreateTemplateDialog`** | `sm:max-w-[600px]` |
| **`BulkIntegrationDialog`** | `max-w-2xl` |
| **Listas de sobreposição** | `flex flex-wrap items-center gap-2` |
| **Metadados de versão** | `flex flex-wrap gap-4` |

### 19.2 Responsividade — os pontos frágeis

| Ponto | Problema |
|---|---|
| **Editor em tela cheia** | O header é `flex items-center justify-between px-6` com **até 12 elementos** à direita (status, badge, selo de tempo, 3 divisores, Histórico, Logs, Publicar, texto Ativa, Switch, expandir, Trocar integração, Configurações). **Não há nenhum breakpoint** — em telas estreitas os itens são espremidos ou transbordam. ⚠️ |
| **Modais 95vw × 95vh** | `ReguaDialog` e `StepWizard` usam praticamente a viewport inteira. Em desktop grande sobra espaço vazio; em mobile a densidade fica alta e o stepper de 5 fases não tem tratamento de largura. |
| **Tabela de 13 colunas** | Só `overflow-x-auto`; nenhuma coluna é escondida ou colapsada por breakpoint. |
| **`DayGroup` cabeçalho** | `flex items-center justify-between` sem wrap — badge + sublabel `<code>` + contagem + custo + botões podem estourar com etapas de nome longo. |
| **`StepCard`** | `flex items-center gap-3` com até 5 elementos na linha 1 (nome, badge de status, badge de janela, custo, HelpTip) e 4 botões à direita. Sem wrap. |
| **`ProfileStepTriggerFields` — janela** | `flex items-center gap-2` com "do dia [input w-20] ao dia [input w-20]" — sem wrap. |
| **Tabela de preview do bulk** | `table w-full text-xs` com 5 colunas dentro de `ScrollArea h-56`, sem scroll horizontal explícito. |
| **`AIMessageAssistant`** | `PopoverContent w-[420px]` **fixo** — não se adapta a telas estreitas. |
| **`VariableInserter`** | `PopoverContent w-80` fixo. |
| **`MetaVariableMapper` — combobox** | `PopoverContent w-[360px]` fixo. |
| **`TemplateCombobox`** | `PopoverContent w-[400px]` fixo. |

> **Só o combobox de etapa** (`ProfileStepTriggerFields`) amarra a largura ao trigger (`--radix-popover-trigger-width`) e respeita `--radix-popover-content-available-height`. É o padrão correto; os demais popovers do domínio usam largura fixa.

### 19.3 Acessibilidade — o que está bem feito

| Prática | Onde |
|---|---|
| `Label htmlFor` + `id` explícito | `ActionStep` (cada opção de tipo), `ProfileStepTriggerFields`, `ReviewStep`, `WaitConfigForm`, `ConditionConfigForm`, `WebhookConfigForm`, `TriggerAIConfigForm`, `PublishDialog`, `CreateTemplateDialog` |
| `aria-label` em controles sem texto visível | Switch de cauda (`"Step de cauda (faixa de dias com cadência)"`), switch `fire_once`, switch de ativação do passo, inputs da janela de etapa ("Primeiro dia na etapa em que este passo dispara" / "Último dia...") |
| `role="combobox"` + `aria-expanded` | Combobox de etapa, `DynamicVariableSelector`, `TemplateCombobox` |
| `aria-pressed` | Pílulas de canal do `BulkIntegrationDialog` |
| `role="alert"` | Mensagem de erro do `AIMessageAssistant` |
| Navegação por teclado no drag & drop | `KeyboardSensor` com `sortableKeyboardCoordinates` no `@dnd-kit` |
| Radio acessível com cartão clicável | `ActionStep` usa `RadioGroupItem className="sr-only"` + `<label htmlFor>` — o clique no cartão inteiro chega ao radio e o nome acessível vem do label |
| Rotulagem sem duplicar | O combobox de etapa **não** põe `aria-label` no botão: já é rotulado pelo `<Label htmlFor>` do pai (`button` é elemento rotulável). Comentário explícito no código. |
| `Label` sem `htmlFor` quando não há alvo | Etapa travada (`lockedEtapa`) — não há campo focável; apontar para um id inexistente quebraria a associação |
| `title` explicativo | Botão "Melhorar com IA" ("Digite pelo menos 10 caracteres"), botão de duplicar passo ("Duplicar ação") |
| Tooltips em ações por ícone | Header do editor: Histórico, Logs, expandir/colapsar, badge de versão, switch de ativação |
| Contraste em estados críticos | Uso consistente de `text-destructive`, `bg-amber-50/text-amber-800`, `text-green-600` |

### 19.4 Acessibilidade — as lacunas

| Lacuna | Onde | Impacto |
|---|---|---|
| **Botões só-ícone sem `aria-label`** | `MoreHorizontal` (menu de ações da lista e do card), `Settings`/`Copy`/`Trash2` do `StepCard`, `RefreshCw` de regenerar no `AIMessageAssistant`, `X` de limpar template, chevron de expandir no `AuditLogPanel`, `ChevronsUpDown` do editor (só tem tooltip) | Leitor de tela anuncia "botão" sem função |
| **Handle de arraste sem rótulo** | `GripVertical` no `StepCard` é um `<button>` sem texto nem `aria-label` | Idem |
| **Badges de status não são anunciados como estado** | "Incompleta", "Integração Inválida", "Draft", "Não dispara — defina a etapa" são `Badge` visuais | Estado crítico invisível para leitor de tela |
| **`window.confirm` na exclusão de régua** | `ReguasCobrancaPage.handleDelete` | Fora do fluxo de foco do app; sem estilização e sem contexto |
| **Sem `aria-live` para toasts de resultado** | Todo o domínio | ⚠️ A confirmar se o componente de toast do design system já provê |
| **Cor como único portador de significado** | Diff do `AuditLogPanel`: valor antigo em `line-through text-red-400`, novo em `text-green-600` | O `line-through` ajuda, mas o "novo" só se distingue por cor |
| **Prévias visuais sem texto alternativo** | Mockups de WhatsApp/SMS/E-mail/Voz | O conteúdo é texto real, mas a semântica da "bolha" não é anunciada |
| **Ponto vermelho no stepper** | `errorSteps` no `WizardStepper` | ⚠️ A confirmar se o `WizardStepper` compartilhado expõe isso acessivelmente |
| **Linha da tabela clicável** | `TableRow onClick` sem `role`/`tabIndex` | A linha inteira abre o `ReguaDialog`, mas não é alcançável por teclado |
| **Card do passo clicável** | `Card onClick` sem `role`/`tabIndex` | Idem — embora o botão de engrenagem cubra o caso |
| **Contraste de textos `text-[10px]`/`text-[11px]`** | Badges e métricas do card da lista | Abaixo do tamanho recomendado, em `text-muted-foreground` |

---

## 20. Dores e oportunidades para o redesign

### 20.1 Bloqueadores funcionais (o redesign precisa resolver)

| # | Problema | Evidência no código | Consequência |
|---|---|---|---|
| 1 | **`webhook` não tem como escolher integração** | `WebhookConfigForm` emite `integration_id` mas não oferece campo; `webhook` está na lista de `hasIncompleteSteps` | Todo passo de webhook criado pela tela nasce "Incompleta" e **bloqueia a publicação da régua**, sem lugar para corrigir |
| 2 | **`condition` e `wait` não podem ser criados** | Ausentes de `STEP_TYPE_OPTIONS` | Dois tipos do motor são inacessíveis pela UI |
| 3 | **Duas listas divergentes de "exige integração"** | `hasIncompleteSteps` (8 tipos) vs `StepCard.checkConfigurationStatus` (10 tipos) | RCS e Notificação aparecem como "Incompleta" no card mas não bloqueiam publicar/ativar |
| 4 | **`trigger_ai` sobrescreve a fase "Quando"** | `buildConfig` espalha `typeConfigFields` depois de `triggerFields`, e o form grava `days_overdue_trigger` | O dia escolhido na fase "Quando" é silenciosamente descartado |
| 5 | **Exclusão de régua com `window.confirm`** | `ReguasCobrancaPage.handleDelete` | Diálogo nativo, sem estilo, sem feedback de sucesso/erro — para a operação mais destrutiva do domínio |
| 6 | **`ReguaDialog` não mostra erro de salvamento** | só `logError` | O usuário vê o modal não fechar, sem saber por quê |
| 7 | **Sem guarda de saída nos modais** | nenhum `beforeunload` nem confirmação | ESC no `StepWizard` descarta uma mensagem longa e todo o trabalho da sessão |
| 8 | **Coluna "Status" da tabela mostra versão, não ativo/inativo** | `TableHead`s vs `TableBody` (12 vs 13 células) | Rótulo enganoso + desalinhamento estrutural |
| 9 | **`hasUnpublishedChanges` não detecta toggle nem reorder** | comparação em `ReguasCobrancaEditorPage` | Desligar um passo ou reordenar não marca "Draft" — mas a publicação leva a mudança |
| 10 | **Card do passo mostra o UUID do template** | `getDescription`: `"Template: ${config.template_id}"` | Informação inútil na superfície mais visível |

### 20.2 Débito de consistência

| # | Problema | Detalhe |
|---|---|---|
| 11 | **Três catálogos paralelos de tipo de passo** | `src/types/reguas-cobranca.ts` (`STEP_TYPES`, cores hex, 9 tipos), `StepCard` (3 mapas Tailwind, 13 tipos), `ActionStep` (`STEP_TYPE_OPTIONS`, 10 tipos) |
| 12 | **Rótulos divergentes para o mesmo tipo** | `send_voice`: "Ligação" (card) vs "Voz/TTS" (catálogo) vs "Voz" (bulk); `notification`: "Notificação" (card) vs "Notificacao" (catálogo) |
| 13 | **Enums divergentes entre formulário e tipos** | `WebhookConfig.action`: `human_task\|negativacao\|bloqueio\|custom` vs `create_human_task\|negativation\|custom`; `ConditionConfig.operator`: `==,!=,>,>=,<,<=,contains` vs `eq,neq,gt,gte,lt,lte,in,is_null` |
| 14 | **Acentuação inconsistente** | "Notificacao", "notificacao extrajudicial", "Variaveis", "Variavel", "Dinamica", "Ate o dia", "So no dia", "uma vez so", "Titulos" (cabeçalho da tabela) |
| 15 | **Constante órfã `AVAILABLE_VARIABLES`** | 11 variáveis declaradas em `src/types/reguas-cobranca.ts` que ninguém consome (a UI usa `useVariables`) |
| 16 | **`MessagePreview` possivelmente órfão** | O `ContentStep` usa `TemplateMessagePreview`, não este |
| 17 | **Resquício de editor de nó/canvas** | "Saída esquerda / Saída direita" no `ConditionConfigForm`; `position_x`/`position_y` no modelo; "Condição de Bifurcação" — a timeline atual é linear |
| 18 | **Filtro de auditoria incompleto** | Não oferece `deleted`, `step_reordered` nem `version_created` |
| 19 | **Campos de auditoria em inglês cru no diff** | `step_type`, `days_overdue_trigger`, `etapa_min_days`, sem tradução |
| 20 | **Dois pontos de edição do nome do passo** | Fase "Ação" e fase "Revisar" — sem indicação de que são o mesmo campo |

### 20.3 Oportunidades de produto

| # | Oportunidade | Justificativa |
|---|---|---|
| 21 | **Header do editor precisa de hierarquia** | 12 elementos numa linha, sem breakpoint, misturando estado (salvamento, versão), navegação (Voltar), ações destrutivas de escopo régua (Trocar integração) e ações de visualização (expandir) |
| 22 | **A tabela de 13 colunas precisa de densidade configurável** | Contatos, Contratos, Titulos, Vl Total, Vl Pago, Em Aberto, Vencido — 7 colunas numéricas competindo com a identidade da régua |
| 23 | **Inserção de variável no cursor** | `TemplateEditor.handleVariableInsert` faz `value + variable` — sempre no fim |
| 24 | **Visualizar o que a régua faz sem editá-la** | Hoje só há o editor. Um modo leitura da timeline (ou um diagrama) atenderia o analista |
| 25 | **Diff visual entre versões** | `VersionComparisonResult` existe no tipo e **não tem UI**. O `PublishDialog` só conta passos, e o `stepsModified` é um proxy grosseiro |
| 26 | **Prévia de público** | A régua declara carteiras e filtros, e a lista mostra contagens; mas o editor não mostra quem a régua alcança |
| 27 | **Simulação de linha do tempo de um contato** | Com dias, cauda e cadência interagindo, entender "o que este cliente recebe" exige raciocínio mental |
| 28 | **Avisos de sobreposição só existem sob perfil de etapa** | No mundo de dias, dois passos do mesmo canal no mesmo dia não geram aviso nenhum |
| 29 | **Empilhamento de modais** | Editor → StepWizard (95vw) → CreateTemplateDialog. Um painel lateral ou uma rota dedicada para o passo evitaria a terceira camada |
| 30 | **Custo estimado merece mais destaque** | Hoje é um badge `font-mono` no rodapé e um número minúsculo por card — mas é a métrica que dimensiona o impacto financeiro da régua |
| 31 | **Padronizar o tratamento de erro pelo padrão do `AIMessageAssistant`** | Estado explícito + copy acionável + retry no lugar do conteúdo é o melhor do domínio; o resto usa toast genérico |
| 32 | **Estado de carregamento do editor** | Hoje a tela inteira some e vira um spinner. Um esqueleto com header preservado manteria a orientação |

### 20.4 O que o redesign NÃO pode perder

Lista de invariantes que estão implementadas na UI **por razões de motor** e cuja remoção causaria bug silencioso em produção:

| Invariante | Por quê |
|---|---|
| **O passo só é gravado no fim do wizard** | Antes, "Adicionar" gravava passo ativo e vazio — havia 3 em produção assim |
| **Switch de ativação do passo vale a COLUNA `is_active`** | Confundir com `config.is_active` já causou passos "desligados" na UI que seguiram disparando (IAF-4400/4406/4607) |
| **Exclusividade dia × etapa no `buildConfig`** | Sem ela, passo de etapa casaria também todo contato com `days_overdue = 0` |
| **Trim visível da etapa** | Espaço na ponta deixa o passo mudo para sempre, sem erro |
| **Bloqueio de janela invertida (`max < min`)** | O motor é fail-closed: o passo nunca dispara, e nada avisa |
| **Bloqueio de faixa invertida (`isTriggerRangeValid`)** | Mesma classe de problema |
| **Aviso de faixa sem cadência** | Sem cadência, a cauda dispara **todo dia**, indefinidamente |
| **Uma cauda por régua** | O switch travado + a orientação de usar "Adicionar canal" |
| **Faixa da cauda editada em lote, nunca no wizard** | Ela é propriedade do grupo; uma tentativa anterior de editá-la no formulário de canal foi revertida |
| **Janela de etapa editada por passo, nunca em lote** | Dois passos da mesma etapa podem ter janelas diferentes — é o ponto do par piso/teto |
| **Grupo "Sem etapa definida" fixo no topo, em tom de alerta** | É o único lugar que denuncia passo que não dispara |
| **Valor cru da etapa sempre visível ao lado do rótulo** | O motor compara sem normalizar; prettificar sozinho esconderia o contrato |
| **Preview obrigatório antes da troca em massa** | A operação reconfigura régua ativa e o efeito só aparece nos disparos seguintes |
| **Preview invalidado a cada mudança de seleção** | Evita confirmar uma coisa e executar outra |
| **Bloqueio total quando há divergência de coluna vestigial** | A RPC recusa por inteiro; a UI precisa refletir isso antes |
| **Checkbox obrigatório no `PublishDialog`** | A publicação afeta produção imediatamente |
| **"Publique uma versão para ativar a régua"** | Não há como ativar sem versão publicada |
| **Publicar/ativar bloqueados por passos incompletos** | Evita régua no ar com ações que não executam |
| **Restaurar cria rascunho, não substitui** | A versão publicada continua ativa |
| **Aviso de sobreposição diz "os dois vão sair", nunca "um será barrado"** | Medido no motor: sob perfil, a Rule 4 e a dedup não separam dois passos da mesma etapa |
| **Compliance da IA: verde só quando a revisão rodou** | Falha nunca pode virar "em conformidade" |
| **Aviso de desativação lista as campanhas e diz que reativar não as reativa** | Comportamento assimétrico real do sistema |
| **Chave nova de passo vai no `config` jsonb, nunca em coluna** | `restore_workflow_steps` só reinsere `step_type`, `step_order`, `config`, `position_x`, `position_y` |

---

## 21. Inventário de modais do domínio

| # | Modal / Painel | Componente | Tipo | Tamanho | Gatilho | Confirmação | Permissão |
|---|---|---|---|---|---|---|---|
| 1 | Nova Régua / Editar Régua | `ReguaDialog` | `Dialog` | `w-[95vw] h-[95vh]` | "Nova Régua"; "Editar"; clique na linha/card; "Configurações" no editor | não | criar/editar: `workflows:write` (o clique na linha abre para qualquer papel) |
| 2 | Novo passo da régua / Adicionar canal à cauda | `AddStepDialog` → `StepWizard` (create) | `Dialog` | `h-[95vh] w-[95vw] max-w-none` | "Adicionar" no grupo; "Adicionar canal"; rodapé; estado vazio | não (o passo nasce no botão final) | `workflows:write` |
| 3 | Configurar passo | `StepConfigSheet` → `StepWizard` (edit) | `Dialog` | `h-[95vh] w-[95vw] max-w-none` | Clique no card; engrenagem do card | não | leitura abre; escrita grava |
| 4 | Excluir ação | `AlertDialog` interno do `StepCard` | `AlertDialog` | padrão | Lixeira no card | **sim** — botão destrutivo | `workflows:write` |
| 5 | Excluir régua | `window.confirm` | **nativo** ⚠️ | — | Item "Excluir" do menu | **sim** (nativa) | `workflows:delete` |
| 6 | Desativar régua? | `AlertDialog` na `ReguasCobrancaPage` | `AlertDialog` | padrão | Desligar régua **com** campanhas ativas dependentes | **sim** — lista as campanhas | `workflows:write` |
| 7 | Editar faixa da cauda | `EditCaudaDialog` | `Dialog` | `max-w-lg` | "Editar" no cabeçalho do grupo de cauda | não (mas valida) | `workflows:write` |
| 8 | Publicar Nova Versão | `PublishDialog` | `Dialog` | `sm:max-w-[500px]` | "Publicar" no header | **sim** — checkbox obrigatório | `workflows:write` + `hasUnpublishedChanges` |
| 9 | Histórico de Versões | `VersionHistoryPanel` | `Sheet` lateral | `w-[400px] sm:w-[540px]` | "Histórico" no header | — | leitura livre |
| 10 | Criar rascunho a partir desta versão? | `AlertDialog` interno do `VersionHistoryPanel` | `AlertDialog` | padrão | "Restaurar" num cartão de versão | **sim** — explica o efeito em 3 itens | ⚠️ A confirmar (o botão não é gated por permissão no código lido) |
| 11 | Histórico de Alterações (Logs) | `AuditLogPanel` | `Sheet` lateral | `w-[400px] sm:w-[540px]` | "Logs" no header | — | leitura livre |
| 12 | Trocar integração em massa | `BulkIntegrationDialog` | `Dialog` | `max-w-2xl` | "Trocar integração" no header | **sim** — preview obrigatório antes de aplicar | `workflows:write` |
| 13 | Criar Template de Ativação | `CreateTemplateDialog` | `Dialog` (aninhado) | `sm:max-w-[600px]` | "Novo Template" no `TemplateHSMSelector` (aba Local) | não | `workflows:write` (contexto) |

### Popovers do domínio (não são modais, mas carregam decisão)

| # | Popover | Componente | Tamanho | Gatilho |
|---|---|---|---|---|
| A | Assistente de IA | `AIMessageAssistant` | `w-[420px]` | "Melhorar com IA" |
| B | Variáveis Disponíveis | `VariableInserter` | `w-80` | "Inserir Variável" |
| C | Seletor de template | `TemplateCombobox` | `w-[400px]` | Combobox de template |
| D | Seletor de variável dinâmica | `DynamicVariableSelector` | `w-[360px]` | Modo "Dinamica" no `MetaVariableMapper` |
| E | Seletor de etapa | `EtapaTriggerFieldView` | `var(--radix-popover-trigger-width)`, `min-w-[280px]` | Combobox de etapa (org com perfil) |

### Menus e tooltips relevantes

| Superfície | Onde | Itens |
|---|---|---|
| `DropdownMenu` de ações da régua | Lista (card e tabela) | Editor Visual · Editar · Duplicar · (sep) · Excluir |
| Tooltips do header do editor | Editor | badge de versão, Histórico, Logs, switch de ativação, expandir/colapsar |
| Tooltips de valores monetários | Lista (tabela e card) | Valor completo formatado |
| Tooltips de carteiras e filtros | Lista (card) | `description` do filtro/carteira |
| Tooltip do badge "Draft" | Lista (card) | "Esta régua não tem versão publicada" |
| `HelpTip` de custo com IA | `StepCard` | "Custo estimado / Inclui custo de IA automatico" |

---

## Apêndice A — Mapa de arquivos citados

Todos os caminhos são relativos à raiz do repositório `cobranca-finza`.

```
src/pages/
  ReguasCobrancaPage.tsx                       lista (790 linhas)
  ReguasCobrancaEditorPage.tsx                 editor em tela cheia (660 linhas)
  central-docs/negocio/data/reguas-cobranca.ts guia de negócio da lista
  central-docs/negocio/data/editor-regua.ts    guia de negócio do editor
  central-docs/topics/data/reguas-workflows.ts tópico transversal

src/components/reguas-cobranca/
  ReguaDialog.tsx                              modal de criação/edição da régua
  WorkflowTypeSelector.tsx                     Sequencial × Pontual
  EntityKindSelector.tsx                       Contrato × Suprimento
  AssignmentFiltersPanel.tsx                   carteiras + filtros + AND/OR
  BulkIntegrationDialog.tsx                    troca de integração em massa

  timeline/
    TimelineView.tsx                           agrupamento, DnD, custo, rodapé
    groupSteps.ts                              agrupamento por etapa (puro)
    DayGroup.tsx                               cabeçalho e corpo do grupo
    StepCard.tsx                               card do passo + AlertDialog de exclusão
    AddStepDialog.tsx                          casca do wizard em mode="create"
    StepConfigSheet.tsx                        casca do wizard em mode="edit"
    EditCaudaDialog.tsx                        edição em lote da faixa da cauda

  wizard/
    StepWizard.tsx                             o wizard (570 linhas)
    stepWizardPhases.ts                        fases + gates (puro)
    steps/ActionStep.tsx                       fase 1 + catálogo de tipos
    steps/WhenStep.tsx                         fase "Quando" (3 mundos)
    steps/IntegrationStep.tsx                  fase "Integração"
    steps/ContentStep.tsx                      fase "Conteúdo"
    steps/TypeConfigStep.tsx                   fase "Configuração"
    steps/ReviewStep.tsx                       fase "Revisar" + sobreposições

  config-forms/
    triggerConfig.ts                           família de chaves de DIA (puro)
    profileStepConfig.ts                       família de chaves de ETAPA (puro)
    channelStepConfig.ts                       família de chaves de CANAL (puro)
    ProfileStepTriggerFields.tsx               campos do perfil de formalização
    ConditionConfigForm.tsx                    formulário de condição
    WaitConfigForm.tsx                         formulário de espera
    WebhookConfigForm.tsx                      formulário de webhook
    TriggerAIConfigForm.tsx                    formulário de agente IA

  config-forms/SharedComponents/
    AIMessageAssistant.tsx                     assistente de IA (3 abas)
    TemplateEditor.tsx                         wrapper do editor de mensagem
    VariableInserter.tsx                       popover de variáveis
    MetaVariableMapper.tsx                     mapeamento {{1}}, {{2}}...
    TemplateHSMSelector.tsx                    seleção de template + criação
    IntegrationSelector.tsx                    seleção de integração
    MessagePreview.tsx                         prévias por canal
    DaysOverdueInput.tsx                       campo de dia exato
    DaysOverdueRangeInput.tsx                  campo de faixa + cadência
    dayOverdueDescription.ts                   describeDay / badgeVariantForDay

  versioning/
    PublishDialog.tsx                          publicar versão
    VersionHistoryPanel.tsx                    histórico + restaurar

  audit/
    AuditLogPanel.tsx                          logs de auditoria

src/types/
  reguas-cobranca.ts                           StepConfig, STEP_TYPES, AVAILABLE_VARIABLES
  workflow-versioning.ts                       versões, snapshots, auditoria, helpers

src/hooks/
  useReguasCobranca.ts                         CRUD de régua e passo, contagens (879 linhas)
  useWorkflowVersions.ts                       versões (477 linhas)
  useWorkflowAuditLogs.ts                      logs + diff + agrupamento (247 linhas)
  useWorkflowBulkIntegration.ts                preview + apply da troca em massa
  useWorkflowCatalog.ts                        catálogo enxuto de réguas ativas
```

## Apêndice B — Índice de marcações "⚠️ A confirmar"

| Seção | Item a confirmar |
|---|---|
| §3.4 | Cabeçalho "Titulos" sem acento é intencional? |
| §7.8 | `condition` e `wait` fora do catálogo de criação é intencional? |
| §8.3 | `STEP_TYPES` e `AVAILABLE_VARIABLES` de `src/types/reguas-cobranca.ts` ainda são consumidos em algum lugar? |
| §9.2 | Qual enum de `WebhookConfig.action` o motor lê? |
| §9.3 | Qual enum de operador de condição o motor lê? |
| §9.5 | O `days_overdue_trigger` do `TriggerAIConfigForm` sobrescrever a fase "Quando" é intencional? |
| §10.6 | `MessagePreview` (do domínio de régua) ainda é consumido, ou ficou órfão frente ao `TemplateMessagePreview`? |
| §19.4 | O componente de toast do design system provê `aria-live`? |
| §19.4 | O `WizardStepper` compartilhado expõe `errorSteps` de forma acessível? |
| §21 | O botão "Restaurar" do `VersionHistoryPanel` deveria ser gated por `workflows:write`? |
