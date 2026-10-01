# 13 · Tela Gestão de Carteira

> Documento de referência para redesign. Descreve o frontend **atual** (setembro/2026) da tela `/portfolio` da Torre de Controle, com nível de detalhe suficiente para que a interface seja redesenhada sem perda de funcionalidade.
>
> Tudo aqui foi extraído da leitura do código-fonte em `cobranca-finza/src/`. Onde o código não permite afirmar algo com certeza, o texto marca `⚠️ A confirmar: ...`.

---

## Índice

- [0. Identidade](#0-identidade)
- [1. Objetivo e personas](#1-objetivo-e-personas)
- [2. Modelo de dados exibido](#2-modelo-de-dados-exibido)
- [3. Anatomia visual da tela](#3-anatomia-visual-da-tela)
- [4. Barra de KPIs](#4-barra-de-kpis)
- [5. Barra de filtros](#5-barra-de-filtros)
- [6. Grid de dados](#6-grid-de-dados)
- [7. Visão Kanban](#7-visão-kanban)
- [8. Painel de detalhe do contato](#8-painel-de-detalhe-do-contato-sheet)
- [9. Aba Lista de Bloqueio / Blocklist V2](#9-aba-lista-de-bloqueio--blocklist-v2)
- [10. Selos e tags](#10-selos-e-tags)
- [11. Ação manual (ManualActionDialog)](#11-ação-manual-manualactiondialog)
- [12. Wizards e modais de cadastro/edição](#12-wizards-e-modais-de-cadastroedição)
- [13. Ações em massa e exportações](#13-ações-em-massa-e-exportações)
- [14. Estados da tela](#14-estados-da-tela)
- [15. Fluxos de uso passo a passo](#15-fluxos-de-uso-passo-a-passo)
- [16. Responsividade e acessibilidade](#16-responsividade-e-acessibilidade)
- [17. Dores e oportunidades para o redesign](#17-dores-e-oportunidades-para-o-redesign)
- [18. Inventário completo de modais do domínio](#18-inventário-completo-de-modais-do-domínio)

---

## 0. Identidade

### 0.1 Rota e montagem

| Item | Valor | Fonte |
|---|---|---|
| Rota canônica | `/portfolio` | `src/App.tsx` (linha ~408) |
| Rotas legadas (redirect) | `/contacts` → `/portfolio`, `/contracts` → `/portfolio` (`<Navigate replace>`) | `src/App.tsx` |
| Componente de página | `PortfolioManagementPage` | `src/pages/PortfolioManagementPage.tsx` |
| Carregamento | `React.lazy` + `<Suspense fallback={<PageLoader />}>` | `src/App.tsx` |
| Guardas de rota | `RequireOrg` → `AgentPanelProvider` → `AppLayout` | `src/App.tsx` |
| Título exibido | "Gestão de Carteira" com ícone `Briefcase` | `src/pages/PortfolioManagementPage.tsx` |

Não há `RequirePermission` na rota: **a tela é acessível a todos os perfis**. O controle é por botão/ação (ver 0.3).

### 0.2 Layout externo

A página assume a viewport inteira, anulando o padding do `AppLayout`:

```tsx
<div className="flex flex-col h-screen -m-3 sm:-m-6 bg-background overflow-hidden">
```

Consequências para o redesign:

- Altura fixa de tela (`h-screen`), sem scroll de página — o scroll vive **dentro** do grid e das colunas do kanban.
- O container de conteúdo do `AppLayout` é neutralizado por margem negativa (`-m-3` mobile / `-m-6` desktop).
- Estrutura em três faixas verticais: header (fixo) → tabs (fixo) → conteúdo da aba (flex-1, `min-h-0`), com rodapé de paginação fixo dentro da aba Contatos.

### 0.3 Permissões (RBAC frontend)

Hook `useOrganization().hasPermission(...)`; mapa em `src/contexts/OrganizationContext.tsx` (`ROLE_PERMISSIONS`). Papéis: `owner > admin > manager > operator > viewer`. `owner` = `["*"]`.

| Permissão | O que libera na tela | owner | admin | manager | operator | viewer |
|---|---|:-:|:-:|:-:|:-:|:-:|
| `contacts:read` | ver a tela (implícito) | sim | sim | sim | sim | sim |
| `contacts:write` (`canWrite`) | botão **Novo Cadastro**, **Aplicar Selo**, ação **Editar** da linha, atribuição de Operador na ficha, todos os botões de escrita da aba Blocklist | sim | sim | sim | não | não |
| `contacts:delete` (`canDelete`) | ação **Excluir** da linha (`DeleteContactDialog`) | sim | sim | não | não | não |
| `reports:export` (`canExport`) | botão **Exportar** do header; botão **Exportar histórico** na aba Histórico da ficha | sim | sim | sim | não | não |
| `contracts:write` | editar contrato / título / suprimento / parcela de suprimento a partir da ficha | sim | sim | sim | não | não |
| `actions:write` | botão **Nova Ação** na ficha do contato | sim | sim | sim | sim | não |
| `actions:override_blocklist` | switch **Respeitar blocklist** no `ManualActionDialog` | sim | sim | não | não | não |
| `seals:apply` | aplicar/remover selo (picker na ficha, modo selo do grid) | sim | sim | sim | sim | não |
| `seals:manage_catalog` | item "Criar novo selo" dentro dos pickers | sim | sim | sim | sim | não |

> Nota de design: hoje a ausência de permissão **esconde** o controle (não desabilita com explicação). Ver §17.

### 0.4 Arquivos-fonte do domínio

```
src/pages/PortfolioManagementPage.tsx          ← orquestrador da tela
src/components/portfolio/
├── PortfolioFiltersBar.tsx                    ← barra de filtros (compartilhada Contatos+Kanban)
├── PortfolioKPIBar.tsx                        ← faixa de KPIs
├── PortfolioDataGrid.tsx                      ← tabela (TanStack Table)
├── PortfolioColumnToggle.tsx                  ← seletor de colunas
├── PortfolioFooter.tsx                        ← paginação
├── types.ts                                   ← catálogo DEFAULT_COLUMNS + storage de visibilidade
├── usePortfolioColumns.ts                     ← merge colunas estáticas + custom fields
├── PortfolioCreateWizard.tsx                  ← wizard Novo Cadastro (3 passos)
├── PortfolioEditDialog.tsx                    ← edição (3 abas)
├── ContractEditDialog.tsx / TitleEditDialog.tsx
├── SupplyEditDialog.tsx / SupplyTitleEditDialog.tsx
├── DeleteContactDialog.tsx
├── DynamicFieldInput.tsx                      ← input por tipo de custom field
├── OverdueBadge.tsx / OverflowBadgeList.tsx / PastedListResolver.tsx
├── ApplySealButton.tsx / ApplySealMode.tsx
├── PortfolioDetailSheet.tsx                   ← barrel re-export de detail/ContactDetailSheet
├── Blocklist*.tsx                             ← 10 arquivos (ver §9 e §18)
├── filters/                                   ← átomos da barra de filtros
├── kanban/                                    ← board, colunas, cards, constantes
└── detail/                                    ← ficha do contato (sheet) + abas + shared
src/components/seals/                          ← SealBadge, SealPicker, SealDialog
src/components/contacts/ ; src/components/contracts/  ← diálogos legados (ver §12.9)
```

---

## 1. Objetivo e personas

### 1.1 O que a tela é

Citação do guia de negócio embarcado no próprio app (`src/pages/central-docs/negocio/data/gestao-carteira.ts`):

> "A central operacional de contatos e contratos. É onde o time vê quem deve, quanto deve e há quanto tempo — em lista, em quadro por faixa de atraso (Kanban) ou na lista de bloqueados (Blocklist) —, abre o histórico completo de cada cliente, cadastra novos registros, aplica selos e exporta a base."
>
> "Diferente do Dashboard (que mede), aqui você AGE."

É a tela mais densa do produto: concentra **3 abas**, **~45 colunas configuráveis**, **11 dimensões de filtro**, **1 sheet de detalhe com 5 abas** e **21 modais** (§18).

### 1.2 Personas

| Persona | Papel RBAC típico | O que faz aqui |
|---|---|---|
| **Operador de cobrança** | `operator` | Busca um cliente específico (telefone/CPF que chegou no atendimento), abre a ficha, lê a situação financeira, dispara uma **Nova Ação** manual, aplica selo de triagem. Não cadastra nem exclui. |
| **Supervisor / gestor de carteira** | `manager` | Recorta a base por carteira/régua/filtro, usa o Kanban para ver concentração de risco, distribui contatos entre operadores (campo Operador), exporta a base, cria filtros na hora. |
| **Administrador de operação** | `admin` / `owner` | Cadastra cliente manualmente, corrige dados (contato/contrato/título), administra a blocklist (regras por filtro, bloqueio/liberação em massa), força envio ignorando blocklist. |
| **Auditor / visualização** | `viewer` | Só lê: grid, KPIs, kanban, ficha. Sem nenhum botão de escrita. |

### 1.3 Perguntas que a tela responde

1. Quem deve, quanto deve e há quantos dias? → grid + KPIs
2. Onde o risco está concentrado? → Kanban por faixa de aging
3. Qual a situação completa de um cliente? → ficha (5 abas)
4. O que já foi feito com esse cliente? → aba Histórico da ficha
5. Quem não pode ser cobrado? → aba Blocklist
6. Como recortar um público para campanha? → filtros + construtor de filtro + exportação

---

## 2. Modelo de dados exibido

### 2.1 Glossário

| Entidade | Definição operacional | Onde aparece na tela |
|---|---|---|
| **Contato** (`contacts`) | O cliente — pessoa física (CPF) ou jurídica (CNPJ). Unidade de **cada linha do grid**. Tem nome, nome fantasia, documento, N telefones, N e-mails, endereço, tags, `custom_fields` (jsonb). | Grid (1 linha = 1 contato), cards do kanban modo "Contatos", ficha completa |
| **Contrato** (`contracts`) | Acordo financeiro do contato. Tem `contract_number`, `modality`, `status`, `total_value`, `paid_value`, `pending_value`, `portfolio` (texto), datas, `custom_fields`. Um contato tem N contratos. | Colunas agregadas do grid, cards do kanban modo "Contratos", cascata da aba Visão Geral |
| **Título / parcela** (`titles`) | A parcela individual, unidade avaliada pelo motor de cobrança. Tem `title_number`, `installment_number`/`total_installments`, `due_date`, `original_value`, `current_value`, `paid_value`, `discount_value`, `interest_value`, `fees_value`, `days_overdue` (**pode ser negativo** = a vencer), `status` canônico, `payment_date`, `payment_method`, `external_id`, códigos de boleto/PIX, `owner_pipeline`. | Colunas agregadas do grid, cascata dentro de cada contrato na aba Visão Geral |
| **Suprimento** (`supplies`) | Equipamento locado — **segunda espécie de dívida**, irmã do contrato, não é um contrato. Tem `supply_number`, `status`, `total_value`, `paid_value`, `pending_value`, `aging_bucket`, `oldest_due_date`, `custom_fields`. | Grupo de colunas "Suprimento" (ocultas por padrão), tile de KPI condicional, aba Suprimentos da ficha |
| **Parcela de suprimento** (`supply_titles`) | Título do suprimento. Mesmos campos financeiros do título. | Cascata da aba Suprimentos |
| **Selo** (`seal_catalog` + junções) | Marcador colorido aplicável a contato, contrato ou título (`scope`). Tem `name`, `color` (hex), `description`, `display_order`. | Coluna "Selos", cabeçalho da ficha, linha de selos por contrato/título, modo de aplicação em massa |
| **Tag** (`contacts.tags`, `string[]`) | Etiqueta textual livre do contato, vinda do cadastro/ETL. **Não é selo**: sem cor, sem catálogo, sem escopo. | Aba Informações da ficha ("Etiquetas"), `ContactDialog` legado |
| **Carteira / portfólio** (`portfolios` via `filter_definitions`) | Segmento **dinâmico** de títulos. Tem nome, cor, ícone. Contato "pertence" a uma carteira por avaliação ao vivo — não há coluna `portfolio_ids`. | Coluna "Carteira", filtro Carteiras, chips do card kanban, "Vínculos Ativos" da ficha |
| **Régua / workflow** (`workflows`) | Fluxo de cobrança. Contato é **elegível** a uma régua (avaliação ao vivo). | Coluna "Réguas", filtro Réguas, filtro Step da régua, "Vínculos Ativos" |
| **Campanha** (`campaigns`) | Execução de régua sobre carteiras. | "Vínculos Ativos" da ficha |
| **Bloqueio** (`blocklist_entries`) | Registro que impede envio para um alvo. 7 tipos de alvo, 3 origens, prazo opcional, escopo de canal (só contato). | Aba Blocklist → sub-aba "Bloqueios ativos"; `BlocklistActiveCard` dentro da ficha e dos editores |
| **Exceção / passe livre** (`blocklist_exceptions`) | **Neutraliza** um bloqueio sem apagá-lo. Mesmos 7 tipos de alvo, motivo próprio, validade opcional. | Sub-aba "Desbloqueados" |
| **Regra de blocklist** (`blocklist_filter_rules`) | Bloqueia automaticamente quem casa um filtro salvo. Alvo: contato, contrato ou título. Dois prazos distintos. | Sub-aba "Regras de Filtro" |
| **Ação** (`actions`) | Comunicação/evento de cobrança (WhatsApp, e-mail, SMS, RCS, voz, negativação, notificação, webhook). 12 status canônicos. | Colunas de "Ações", aba Histórico, ManualActionDialog |
| **Filtro salvo** (`filter_definitions`) | Regra salva que seleciona títulos. Tem nome, cor, ícone, `cached_contact_count`. | Filtro "Filtros", `FilterBuilderDialog` |

### 2.2 Relações (como a UI as expressa)

```
Contato (1 linha do grid)
├── N Contratos ───────── N Títulos (parcelas)          → cascata da aba "Visão Geral"
├── N Suprimentos ─────── N Parcelas de suprimento      → cascata da aba "Suprimentos"
├── N Ações (histórico)                                 → aba "Histórico"
├── N Selos (scope=contact)                             → cabeçalho da ficha / coluna Selos
├── N Tags (texto livre)                                → aba "Informações"
├── N Carteiras (dinâmico) / N Réguas (dinâmico) / N Campanhas → "Vínculos Ativos"
├── 0..1 Operador atribuído (contact_assignments)       → seletor no topo da ficha
└── N Bloqueios / Exceções (nível contato)              → aba "Bloqueios"

Contrato ── N Selos (scope=contract), N Bloqueios (target_type=contract)
Título   ── N Selos (scope=title),   N Bloqueios (target_type=title)
```

### 2.3 Regra de colapso (crítica para o redesign do grid)

Cada linha do grid é **um contato**, mas a maioria das colunas descreve contratos/títulos. `src/components/portfolio/types.ts` classifica cada coluna por:

- `entity`: `"contact" | "contract" | "title" | "supply"` — **de onde o dado vem**;
- `aggregated: boolean` — se o valor colapsa N registros em 1 célula (SUM/COUNT/MIN/MAX/AVG/BOOL_OR/ARRAY_AGG/distintos).

Colunas agregadas recebem: ícone `Layers` ao lado do rótulo + nota de agregação no popover de ajuda. As notas padrão por entidade estão em `COLUMN_ENTITY_META`:

| Entidade | Label | Nota de agregação |
|---|---|---|
| `contact` | Contato | (nenhuma) |
| `contract` | Contrato | "Valor agregado dos contratos do contato." |
| `title` | Titulo | "Valor agregado dos titulos do contato." |
| `supply` | Suprimento | "Valor agregado dos suprimentos do contato." |

### 2.4 Convenções de valor

| Conceito | Regra | Impacto visual |
|---|---|---|
| `days_overdue` negativo | Suportado e **significativo**: `-7` = vence em 7 dias (cobrança preventiva). Nunca coalescer para 0. | `OverdueBadge` renderiza `D-7` em azul; `ManualActionDialog` exibe `D-7` / `D+15`; bucket "Em dia" cobre `min = -Infinity` |
| `days_overdue = 0` | "Vence hoje" | `OverdueBadge` em verde esmeralda |
| Status de título | Canônicos em português: `Disponivel`, `Pago`, `Cancelado`, `Removido`, `Expirado`, `Recomprado`, `Renegociado`, `Aguardando Recompra`, `Aguardando Cancelamento`, `Para Antecipar`, `Pendente`. Resolvidos por `resolveStatus()` (`src/lib/constants/title-status-config.ts`). | `TitleStatusBadge` e `StatusBadge` |
| Status de ação | 12 canônicos; rótulos de **exibição** diferem do valor gravado (`Falhou` → "Falha Temporária de Ação", `Respondido` → "Solicitou Atendimento"). Fonte: `getActionStatusLabel`. | Timeline do histórico, resultado do envio manual |
| Valor "atual" vs "original" | `getSafeValue(current, original)` — usa o atual quando existe; `hasRealUpdatedValue()` decide se vale mostrar a linha "Valor Atual". | Cascata de títulos |

---

## 3. Anatomia visual da tela

### 3.1 Ordem dos blocos (aba Contatos, desktop)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ [Briefcase] Gestão de Carteira        [↻] [Aplicar Selo] [Exportar▾] [+ Novo] │ header (fixo, border-b, p-4)
├──────────────────────────────────────────────────────────────────────────────┤
│ ( Contatos 12.345 ) ( Kanban ) ( Blocklist 61 )                              │ TabsList (fixo, px-4 pt-2, border-b)
├──────────────────────────────────────────────────────────────────────────────┤
│ [?] [🔍 busca] │ [Carteiras·2][?] [Réguas][?] [Filtros][+][?] [Segmento][?]  │
│      │ Operador:[▾] (•) Meus contatos │ Ação:[?][▾] [Tipo de ação][?]        │ PortfolioFiltersBar
│      [Step da régua][?] [Colunas (7)]                                        │ (bg-card, border-b, p-4)
│ Filtros ativos: [Carteira: X ✕] OU [Carteira: Y ✕] [Limpar todos]            │
├──────────────────────────────────────────────────────────────────────────────┤
│ [?] 👥 12.345 contatos  📄 20.110 contratos  🧾 98.400 títulos  $ R$ 12,3 M   │ PortfolioKPIBar
│     ✓ R$ 3,1 M pago  ◐ R$ 9,2 M em aberto  ⚠ R$ 7,8 M vencido               │ (bg-muted/30, border-b, py-2.5)
├──────────────────────────────────────────────────────────────────────────────┤
│ [faixa de modo selo — só quando ativo]                                       │ ApplySealMode (sticky, z-20)
├──────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Carteira │ Réguas │ Nome │ Documento │ Telefone │ Valor Devido │ … │ ⋯   │ thead sticky top-0 z-10
│ ─────────────────────────────────────────────────────────────────────────────│
│ ☐ │ [chip][chip]+3 │ … │ (linhas clicáveis)                             │ ⋯  │ tbody (scroll x+y)
├──────────────────────────────────────────────────────────────────────────────┤
│ Itens por página [50▾]                         1-50 de 12.345  [‹] 1/247 [›] │ PortfolioFooter (border-t, bg-muted/30)
└──────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Abas do topo (`Tabs` raiz)

| Valor | Rótulo | Ícone | Badge | Conteúdo |
|---|---|---|---|---|
| `contacts` (default) | Contatos | `Briefcase` | `data.total` formatado pt-BR, em `bg-muted` arredondado — só aparece se `> 0` | filtros + KPIs + grid + footer |
| `kanban` | Kanban | `LayoutGrid` | — | `KanbanTab` (recebe a MESMA barra de filtros e a MESMA barra de KPIs por props) |
| `blocklist` | Blocklist | `Ban` | `blocklistStats.total` em `bg-destructive/10 text-destructive` — só se `> 0` | `BlocklistTabV2` |

A aba ativa é persistida na URL (`?tab=`) e inicializada a partir dela.

### 3.3 Botões do header

Fonte: `src/pages/PortfolioManagementPage.tsx` (linhas 655-701).

| Botão | Visibilidade | Comportamento |
|---|---|---|
| `RefreshButton` (ícone ↻) | **sempre**, em qualquer aba | `handleRefresh()`: `refetch()` do grid + invalida 8 query keys (`contact-portfolios-map`, `contact-workflows`, `contact-custom-fields`, `contact-contract-custom-fields`, `contact-supply-custom-fields`, `contact-action-stats`, `contact-seals-map`, `portfolio-kpis`). Mostra spinner enquanto `isFetching` |
| **Aplicar Selo** | aba `contacts` **e** `canWrite` | Abre popover com o catálogo de selos de contato; escolher entra no "modo selo". `disabled` enquanto já há selo ativo |
| **Exportar** (dropdown) | aba `contacts` **e** `canExport` | 3 itens (ver §13). `disabled` enquanto `exportMutation.isPending`. Ícone `Download`; o rótulo some em telas `<sm` |
| **Novo Cadastro** | aba `contacts` **e** `canWrite` | Abre `PortfolioCreateWizard`. Ícone `Plus`; rótulo some em `<sm` |

Nas abas Kanban e Blocklist o header mostra **apenas** o `RefreshButton` — cada uma tem os próprios botões internos.

---

## 4. Barra de KPIs

Arquivo: `src/components/portfolio/PortfolioKPIBar.tsx`. Dados: `usePortfolioKPIs` → RPC `get_portfolio_kpis`.

### 4.1 Layout

```
flex-wrap, justify-center, gap-x-5 gap-y-1, px-4 py-2.5, bg-muted/30, border-b, text-sm
```

Cada KPI é um par `[ícone 3.5] [<strong>valor</strong> rótulo]`, com o valor em `text-foreground` e o rótulo em `text-muted-foreground`. É uma **faixa horizontal de texto**, não cards.

Antes do primeiro KPI há um `HelpTip topic="kpi_titlecentric"`:
> "Os números refletem só os títulos que casam com os filtros ativos (não o total do contato). Valores em aberto/vencido usam os campos já calculados do sistema."

### 4.2 Os 8 indicadores

| # | Rótulo | Campo | Ícone | Cor do ícone | Formato | Condição de exibição |
|---|---|---|---|---|---|---|
| 1 | contatos | `contactCount` | `Users` | herdada (muted) | inteiro `toLocaleString("pt-BR")` | sempre |
| 2 | contratos | `contractCount` | `FileText` | muted | inteiro pt-BR | sempre |
| 3 | suprimentos | `supplyCount` | `Package` | muted | inteiro pt-BR | **só se `supplyCount > 0`** |
| 4 | títulos | `titleCount` | `Receipt` | muted | inteiro pt-BR | sempre |
| 5 | total | `totalValue` | `DollarSign` | muted | moeda BRL; **notação compacta** (`R$ 12,3 mi`) quando `abs(valor) ≥ 1.000.000` | sempre |
| 6 | pago | `paidValue` | `CheckCircle2` | `text-emerald-600` | moeda BRL (mesma regra compacta) | sempre |
| 7 | em aberto | `openValue` | `CircleDot` | `text-amber-600` | moeda BRL | sempre |
| 8 | vencido | `overdueValue` | `AlertTriangle` | `text-destructive` | moeda BRL | sempre |

### 4.3 Semântica de cálculo

Os 8 valores vêm inteiros da RPC `get_portfolio_kpis` (schema da org, campos pré-calculados da MV `vw_titles_live`). O hook (`src/hooks/usePortfolioKPIs.ts`) apenas faz `Number(...) || 0`.

Parâmetros enviados (todos opcionais, todos vindos da barra de filtros):
`p_schema_name`, carteiras/filtros multi + combinadores E/OU, dimensão régua (+ `sem régua`), `p_assigned_user_id`, `p_search_term`, `p_contact_ids` (interseção de Ação + Segmento), `p_exclude_contact_ids` (modo "Sem ação").

Regras importantes:

- `staleTime: 60_000` (1 min).
- Se `filters.contactIds` é um array **vazio**, o hook devolve os KPIs zerados sem ir ao servidor (recorte ativo que não casou com ninguém).
- A barra é **gateada**: `enabled: !filtersResolving && !resolvedFilterError`. Enquanto os resolvedores de Ação/Segmento carregam, a barra não consulta (evita mostrar por um instante o universo maior).

### 4.4 Estados da barra

| Estado | Render |
|---|---|
| `error` (do KPI ou dos resolvedores) | `<div role="alert">` em `text-destructive`, texto: `Não foi possível aplicar os filtros: {mensagem}` — substitui a barra inteira |
| `isLoading && !kpis` | 7 `<Skeleton>` (larguras 20/20/20/28/28/28/28) |
| `!kpis && !isLoading` | retorna `null` — a barra **some** |
| ok | os 8 tiles |

---

## 5. Barra de filtros

Arquivo: `src/components/portfolio/PortfolioFiltersBar.tsx` (632 linhas). **A mesma instância** é passada por props para a aba Contatos e para a aba Kanban (`sharedFiltersBar` em `PortfolioManagementPage`), então mexer num filtro numa aba já está aplicado na outra.

Existe ainda `src/components/portfolio/kanban/KanbanFiltersBar.tsx` — uma barra reduzida legada que **não é mais usada** por esta tela (`KanbanTab` recebe a barra compartilhada). ⚠️ A confirmar: se ela ainda é usada por alguma outra tela ou é código morto.

### 5.1 Estrutura visual

```
<MobileCollapsibleFilters activeCount={N} label="Filtros">
  [alerta de falha de catálogo, se houver]
  <div className="flex-col gap-3 p-4 bg-card border-b">
     <div className="flex items-center gap-4 flex-wrap">   ← linha principal
        HelpTip(entre_tipos_and)
        Busca
        │ divider │
        Carteiras + HelpTip
        Réguas + HelpTip
        Filtros + [+] + HelpTip
        Segmento + HelpTip          (condicional)
        │ divider │
        Operador:  [select]
        (•) Meus contatos
        │ divider │
        Ação: [?] [select]          (+ popover de calendário quando "Personalizado")
        Tipo de ação + HelpTip      (condicional)
        Step da régua + HelpTip     (condicional)
        Colunas                     (condicional a showColumnToggle)
     </div>
     <ActiveFilterChips .../>                              ← linha de chips
  </div>
</MobileCollapsibleFilters>
```

Os separadores são `<div className="h-6 w-px bg-border" />` e marcam 3 grupos semânticos: **dados** (busca, carteira, régua, filtro, segmento) · **atribuição** (operador, meus contatos) · **ação** (data, tipo, step).

### 5.2 Tabela completa dos filtros

| # | Filtro | Controle | Opções / fonte | Default | Lógica interna | Persistido na URL | Reseta página? | Limpa seleção de linhas? |
|---|---|---|---|---|---|---|---|---|
| 1 | **Busca de cliente** | `Input type="search"` com ícone `Search`, `maxLength={200}`, largura 220px, placeholder = `CUSTOMER_SEARCH_PLACEHOLDER` | texto livre | `""` | debounce via `useDebouncedSearchInput`; `Enter` submete na hora. Termo é **literal** (`%` e `_` escapados no backend) | `?search=` | sim | sim |
| 2 | **Carteiras** | `PortfolioMultiSelect` → `FilterMultiSelect` (Button outline + Badge contador + Popover/Command) | `usePortfolios({fetchAll:true, activeOnly:true})` — só carteiras ativas, com cor e ícone | `[]` = todas | **OU** (união) por padrão; toggle E/OU no cabeçalho do dropdown quando ≥2 selecionadas | `?portfolios=a,b` + `?portfoliosLogic=and` (só se ≠ default) | sim | sim |
| 3 | **Réguas** | `WorkflowMultiSelect` → `FilterMultiSelect` | `useWorkflowCatalog()` + pseudo-item `"— Sem régua —"` no topo (ícone `CircleOff`) | `[]` | **OU** por padrão; toggle E/OU conta **só réguas reais** (`logicSelectionCount`). "Sem régua" é sempre termo de união e vira o flag booleano `includeNoWorkflow` | `?workflows=`, `?workflowsLogic=`, `?noWorkflow=1` | sim | sim |
| 4 | **Filtros salvos** | `FilterDefinitionMultiSelect` → `FilterMultiSelect` + botão `Plus` ghost ao lado ("Criar novo filtro") | `useFilters({fetchAll:true, pageSize:100})` — **pageSize explícito**, porque o default da factory é 20 e escondia 63% dos filtros | `[]` | **E** (interseção) por padrão; toggle E/OU quando ≥2 | `?filters=`, `?filtersLogic=` | sim | sim |
| 5 | **Segmento** | `FilterMultiSelect` genérico, ícone `Layers` | `useSegmentOptions()` → RPC `get_segment_options`; rótulo = `"{label} ({contactCount})"`; valores normalizados lower+btrim no backend | `[]` | qualquer um dos escolhidos (OR). Resolve para `contact_ids` e **intersecta** com os demais resolvedores | `?segments=` | sim | sim |
| 6 | **Operador** | `OperatorSelect` (`Select` shadcn, 180px), Label externo "Operador:" | `useOrganizationUsers()`; item "Todos" com ícone `Users`, demais com ícone `User` e `full_name \|\| email \|\| id.slice(0,8)` | `null` ("Todos") | escolher um usuário **desliga** "Meus contatos" | **não** | sim (via efeito) | sim |
| 7 | **Meus contatos** | `ShowOnlyMineToggle` (`Switch` + Label clicável) | booleano | `false` | ligar **zera** o Operador escolhido; tem precedência (`effectiveAssignedUserId = showOnlyMine ? user.id : assignedUserId`) | **não** | sim | sim |
| 8 | **Ação (data)** | `Select` 160px com ícone `Zap`, dentro de um `Popover` (o calendário) | `all` / `today` / `yesterday` / `custom` / `none` / `has_action` | `all` | "Hoje"/"Ontem" setam o range automaticamente (`startOfDay`/`endOfDay`); "Personalizado" abre calendário `mode="range"`, locale ptBR, 1 mês; "Sem ação" e "Teve ação" usam janela fixa de **30 dias** e compartilham o mesmo universo (o modo decide include vs exclude) | **não** | sim | sim |
| 9 | **Tipo de ação** | `FilterMultiSelect`, ícone `Zap` | `ACTION_TYPE_FILTER_OPTIONS`: WhatsApp, E-mail, SMS, RCS, Ligação, Negativação, Notificação extrajudicial | `[]` | OR entre os escolhidos; combina por **E** com a janela de data (mesma RPC `get_action_contact_ids`). Cada opção expande para os valores crus (`send_whatsapp` **e** `whatsapp`) | `?actionTypes=` | sim | sim |
| 10 | **Step da régua** | `FilterMultiSelect`, ícone `Zap`, **desabilitado** sem régua | `useWorkflowStepOptions(workflowIds)`; rótulo `"D+15 · WhatsApp"` (ou o nome do step), sufixo `(passo N)` quando colide, sufixo `— Nome da régua` quando há ≥2 réguas | `[]` | OR; depende da régua selecionada. Tooltip no estado desabilitado: "escolha uma régua primeiro" | `?steps=` | sim | sim |
| 11 | **Colunas** | `PortfolioColumnToggle` (Popover 288px) | ver §6.4 | — | não é filtro de dados, é de exibição | localStorage | não | não |

### 5.3 Comportamentos transversais

**Combinação entre tipos.** Sempre **E**. O `HelpTip topic="entre_tipos_and"` no início da barra explica:
> "Cada tipo de filtro (carteiras, filtros salvos, busca, operador, ação, data) se combina com os OUTROS por 'E': o resultado atende a todos os tipos que você preencheu. Um tipo deixado em branco não restringe nada."

**Toggle E/OU.** Vive **dentro** do dropdown (cabeçalho `"Combinar carteiras" / "Combinar réguas" / "Combinar filtros"`), como `ToggleGroup` com dois itens `E` e `OU` (`FilterLogicToggle`). Só aparece com ≥2 seleções reais. `aria-label` e `title` explicam ("E — precisa satisfazer todos" / "OU — basta satisfazer um").

**Poda de steps órfãos.** Um `useEffect` remove steps que não pertencem mais às réguas selecionadas; se nenhuma régua está selecionada, limpa todos. Enquanto o catálogo carrega, **não** poda (senão limparia a seleção a cada troca de aba).

**Falha de catálogo.** Se `usePortfolios`, `useFilters` ou `useWorkflowCatalog` erram, aparece um `<p role="alert">` no topo da barra:
> "Não foi possível carregar todas as opções de filtro. Atualize a página."

**Contador de filtros ativos** (`activeFiltersCount`, usado pelo badge do colapsável mobile):
`busca(0|1) + nº carteiras + nº filtros + nº réguas + (semRégua?1:0) + nº tipos de ação + nº steps + nº segmentos + (data≠all?1:0) + (operador?1:0) + (meusContatos?1:0)`.

### 5.4 Chips de filtros ativos

Componente: `src/components/portfolio/filters/ActiveFilterChips.tsx`. Renderiza `null` quando não há chips.

```
Filtros ativos:  [● Carteira: Blips ✕]  OU  [● Carteira: Finza ✕]  [Filtro: Alto risco ✕]  [Limpar todos]
```

| Elemento | Detalhe |
|---|---|
| Prefixo | `<span className="text-xs text-muted-foreground">Filtros ativos:</span>` |
| Chip | `Badge variant="secondary"` com: bolinha de cor (2.5×2.5, se o item tem `color`), ícone opcional, rótulo, botão `X` (`aria-label="Remover filtro"`, hover `text-destructive`) |
| Conector | Pílula textual `E` / `OU` **antes** do 2º..N-ésimo chip do mesmo tipo (`text-[10px] font-semibold uppercase`) |
| "Limpar todos" | `Button variant="ghost" size="sm"` no fim da linha |

Chips emitidos, na ordem: `search` → 1 por carteira → 1 por filtro → 1 por régua → `no-workflow` → `operator` → `mine` → 1 por segmento → 1 por tipo de ação (ícone `Zap`) → 1 por step (ícone `Zap`) → `action` (ícone `Zap`).

Rótulos: `Busca: "termo"`, `Carteira: X`, `Filtro: X`, `Régua: X`, `Régua: Sem régua`, `Operador: Nome`, `Meus contatos`, `Segmento: X (N)`, `Tipo de ação: X`, `Step: X`, `Acao: Hoje|Ontem|dd/MM - dd/MM|Sem acao|Teve acao`.

**`clearAllFilters()` zera tudo, inclusive os operadores lógicos**: busca `""`, carteiras `[]`, filtros `[]`, `portfoliosLogic="or"`, `filtersLogic="and"`, `workflowsLogic="or"`, réguas `[]`, `includeNoWorkflow=false`, ação `"all"` + range nulo, operador `null`, meus contatos `false`, tipos `[]`, steps `[]`, segmentos `[]`.

### 5.5 Persistência na URL

Constante `PORTFOLIO_URL_DEFAULTS` em `PortfolioManagementPage.tsx`; hook `useUrlFilterState`. Adoção **write-through**: a URL alimenta o estado inicial e é reescrita nos handlers; o estado composto `filters` continua sendo a fonte durante a sessão.

| Chave | Tipo | Default | Observação |
|---|---|---|---|
| `tab` | string | `contacts` | aba ativa |
| `portfolios` / `filters` / `workflows` | ids comma-joined | `""` | formato idêntico ao do Dashboard |
| `portfoliosLogic` / `filtersLogic` / `workflowsLogic` | `and`\|`or` | `or` / `and` / `or` | só serializa quando ≠ default |
| `noWorkflow` | `"1"` | ausente | pseudo-item "Sem régua" |
| `actionTypes` / `steps` / `segments` | comma-joined | `""` | Card 6176 |
| `search` | string | `""` | |
| `page` | número | `"1"` | `pageSize` **não** é versionado |
| `portfolioId` / `filterId` | id único | `""` | **legadas — só leitura de compat**; a escrita sempre limpa |
| `contact` / `contract` | uuid | `""` | deep-link; limpos após abrir a ficha |

**Deep-link de contato.** `?contact=<uuid>` busca o contato por id (`useContactEnrichedById`) **mesmo que ele não esteja na página/filtro atual**, abre a ficha e limpa o parâmetro. `?contract=` é aceito para não quebrar a URL mas é informativo — a sheet abre no nível do contato.

### 5.6 Busca de cliente (motor)

Motor único `public.search_customer_ids(schema, term)`, consumido por grid, KPIs, exportação e pelo seletor global do menu. Campos cobertos: **nome, razão social, documento (normalizado), telefone (normalizado, tolera DDI 55), e-mail, número de contrato**. Além disso, o `p_search_term` da `get_kanban_data` também alcança número do título e campos personalizados.

Propriedades que a UI comunica:
- termo é **literal** — digitar `50%` procura o texto `50%`;
- normalização numérica só quando o termo **inteiro** é numérico/pontuação;
- identidade exata é tentada **antes** do parcial;
- filtro/carteira inexistente é **erro visível**, não "sem filtro".

---

## 6. Grid de dados

Arquivo: `src/components/portfolio/PortfolioDataGrid.tsx`. Base: **TanStack Table v8** com `manualSorting: true`, sem `getSortedRowModel` (ordenação é server-side).

### 6.1 Estrutura da tabela

| Aspecto | Implementação |
|---|---|
| Container | `div.relative.h-full.overflow-auto` — scroll vertical **e** horizontal |
| Tabela | `table.w-full.min-w-max.border-collapse` |
| Cabeçalho | `thead.sticky.top-0.z-10`; cada `th` em `bg-muted`, `p-3`, `text-sm font-medium text-muted-foreground`, `whitespace-nowrap`, com `minWidth`/`width` = `col.width` |
| Última coluna (ações) | `th` e `td` com `sticky right-0`, `z-20` no header, sombra `-2px 0 4px rgba(0,0,0,0.1)`; `td` recebe `bg-background` |
| Linha | `tr.border-b.hover:bg-muted/30.cursor-pointer`; clique abre a ficha (ou aplica selo, no modo selo) |
| Célula | `td.p-3.text-sm`; células `select` e `actions` fazem `stopPropagation` no clique |
| Densidade | **fixa** — `p-3` em todas as células. Não há seletor de densidade |
| Larguras | por coluna, em px, definidas em `DEFAULT_COLUMNS` (`width`) |
| Zebra | não há |
| Redimensionar coluna | não há |
| Reordenar coluna | não há |
| Congelar coluna à esquerda | não há (só a coluna de ações à direita é sticky) |

### 6.2 Catálogo completo de colunas

Fonte: `DEFAULT_COLUMNS` em `src/components/portfolio/types.ts`. Versão do catálogo: `COLUMN_VERSION = "v14"` (mudar a versão limpa a preferência salva).

Legenda: **Agg** = coluna agregada (ícone `Layers`) · **Vis** = visível por padrão · **Ord** = ordenável (server-side).

#### Grupo "Associações" (categoria `Associacoes`)

| id | Cabeçalho | Conteúdo / formato | Largura | Entidade | Agg | Vis | Ord | Descrição (popover "?") |
|---|---|---|---|---|---|:-:|:-:|---|
| `portfolios` | Carteira | `badge` — `OverflowBadgeList` com 2 chips + "+N" clicável; cor de fundo `{color}20`, texto na cor | 150 | contact | não | **sim** | não | "Carteiras (segmentos dinamicos de titulos) a que o contato pertence no momento." |
| `workflows` | Reguas | `badge` — idem, e cada item **navega** para `/reguas-cobranca/{id}/editor` | 150 | contact | não | **sim** | não | "Reguas de cobranca em que o contato esta elegivel atualmente." |
| `modalities` | Modalidade | `badge` — modalidades distintas entre os contratos | 150 | contract | **sim** | não | não | "Todas as modalidades distintas entre os contratos do contato." |
| `segments` | Segmento | `badge` | 150 | contract | **sim** | não | não | "Todos os segmentos distintos entre os contratos do contato." |
| `companies` | Empresa | `badge` | 150 | contract | **sim** | não | não | "Todas as empresas distintas entre os contratos do contato." |

#### Grupo "Contato"

| id | Cabeçalho | Formato | Largura | Align | Vis | Ord | Descrição |
|---|---|---|---|---|:-:|:-:|---|
| `name` | Nome | texto | 200 | left | **sim** | **sim** | "Nome do contato (pessoa fisica ou juridica)." |
| `document` | Documento | `document` (CPF/CNPJ formatado por comprimento) | 150 | left | **sim** | **sim** | "Documento do contato: CPF (pessoa fisica) ou CNPJ (pessoa juridica)." |
| `document_type` | Tipo Doc | texto | 90 | center | não | não* | "Tipo do documento do contato: CPF ou CNPJ." |
| `trading_name` | Nome Fantasia | texto | 180 | left | não | não* | "Nome fantasia do contato, quando pessoa juridica." |
| `primary_phone` | Telefone | `phone` | 140 | left | **sim** | não* | "Telefone principal cadastrado do contato." |
| `primary_email` | E-mail | texto | 200 | left | não | não* | "E-mail principal cadastrado do contato." |

\* "não" porque o id não está em `SORT_FIELD_MAP` — ver §6.5.

#### Grupo "Financeiro"

| id | Cabeçalho | Formato | Largura | Align | Entidade | Agg | Vis | Ord | Descrição |
|---|---|---|---|---|---|:-:|:-:|:-:|---|
| `total_pending_value` | Valor Devido | `currency` | 140 | right | title | sim | **sim** | **sim** | "Soma do valor ainda devido (nao pago) dos titulos do contato." |
| `total_overdue_value` | Valor Vencido | `currency` | 140 | right | title | sim | não | **sim** | "Soma do valor vencido (titulos ja em atraso e nao pagos) do contato." |
| `total_open_value` | Valor em Aberto | `currency` | 140 | right | title | sim | não | **sim** | "Soma do valor em aberto (nao pago) de todos os titulos do contato." |
| `total_paid_value` | Valor Pago | `currency` | 140 | right | title | sim | não | **sim** | "Soma do valor ja pago dos titulos do contato." |
| `total_original_value` | Valor Original | `currency` (accessor `total_contract_value`) | 140 | right | title | sim | não | **sim** | "Soma do valor original (de face) dos titulos do contato, sem juros/multa." |
| `total_current_value` | Valor Atualizado | `currency` | 140 | right | title | sim | não | **sim** | "Soma do valor atualizado dos titulos do contato (com encargos ate hoje)." |
| `supply_total_debt` | Divida Suprimento | `currency` | 150 | right | **supply** | sim | não | não | "Soma do valor em aberto SO dos suprimentos (equipamentos locados) do contato." |

#### Grupo "Quantidades"

| id | Cabeçalho | Formato | Largura | Align | Entidade | Agg | Vis | Ord | Descrição |
|---|---|---|---|---|---|:-:|:-:|:-:|---|
| `total_contracts` | Contratos | `number` | 100 | center | contract | sim | **sim** | **sim** | "Quantidade de contratos do contato." |
| `total_supplies` | Suprimentos | `number` | 110 | center | supply | sim | não | não | "Quantidade de suprimentos (equipamentos locados) do contato." |
| `supply_max_days_overdue` | Atraso Suprimento | `number` | 140 | center | supply | sim | não | não | "MAIOR atraso (em dias) entre os suprimentos de divida ativa do contato. Valores negativos indicam a vencer." |
| `supply_aging_bucket` | Aging Suprimento | texto | 140 | center | supply | sim | não | não | "Faixa de aging (categoria de atraso) agregada dos suprimentos do contato." |
| `overdue_titles` | Titulos Vencidos | `number` | 130 | center | title | sim | **sim** | **sim** | "Quantidade de titulos vencidos (em atraso, nao pagos) do contato." |
| `total_titles` | Total Titulos | `number` | 110 | center | title | sim | não | **sim** | "Quantidade total de titulos do contato." |
| `open_titles` | Titulos em Aberto | `number` | 130 | center | title | sim | não | **sim** | "Quantidade de titulos em aberto (nao pagos) do contato." |
| `paid_titles` | Titulos Pagos | `number` | 110 | center | title | sim | não | não | "Quantidade de titulos ja pagos do contato." |
| `max_days_overdue` | Maior Atraso (dias) | `number` | 140 | center | title | sim | não | **sim** | "MAIOR atraso (em dias) entre os titulos de divida ativa do contato — nao e o atraso de um titulo especifico." |
| `min_days_overdue` | Dias Min. Atraso | `number` | 130 | center | title | sim | não | **sim** | "MENOR atraso (em dias) entre os titulos de divida ativa do contato. Valores negativos indicam titulos a vencer." |
| `avg_days_overdue` | Media Atraso | `number` | 120 | center | title | sim | não | **sim** | "Atraso medio (em dias) dos titulos de divida ativa do contato." |
| `avg_payment_delay` | Media Atraso Pgto | `number` | 140 | center | title | sim | não | **sim** | "Atraso medio de pagamento (em dias) dos titulos ja pagos do contato." |
| `safra_days` | Safra Mais Antiga (dias) | `number` | 160 | center | contract | sim | não | não | "Dias desde a safra MAIS ANTIGA entre os contratos do contato (MAX de dias de safra por contrato)." |
| `min_open_installment` | 1ª Parc. em Aberto (maior entre contratos) | `number` | 200 | center | contract | sim | não | não | "Numero da 1ª parcela em aberto de cada contrato; para contato com varios contratos, mostra o MAIOR entre eles (contrato mais avancado) — nao a parcela mais cedo do contato." |
| `min_open_installment_disponivel` | 1ª Parc. Disponivel (maior entre contratos) | `number` | 200 | center | contract | sim | não | não | "Numero da 1ª parcela Disponivel de cada contrato; … mostra o MAIOR entre eles …" |
| `has_pnp` | Tem PNP | `boolean` → "Sim"/"Não" | 100 | center | contract | sim | não | não | "Sim se QUALQUER contrato do contato tem PNP." |

#### Grupo "Datas"

| id | Cabeçalho | Formato | Largura | Entidade | Agg | Vis | Ord | Descrição |
|---|---|---|---|---|:-:|:-:|:-:|---|
| `next_due_date` | Prox. Vencimento | `date` (`toLocaleDateString("pt-BR")`) | 140 | title | sim | não | **sim** | "Data do proximo vencimento entre os titulos em aberto do contato." |
| `last_payment_date` | Ultimo Pagamento | `date` | 140 | title | sim | não | **sim** | "Data do pagamento mais recente registrado entre os titulos do contato." |
| `oldest_overdue_date` | Vencido Mais Antigo | `date` | 150 | title | sim | não | **sim** | "Data de vencimento do titulo vencido mais antigo do contato." |

#### Grupo "Ações" (contact-scoped, **nunca** ordenáveis — dado enriquecido no cliente)

| id | Cabeçalho | Accessor | Formato | Largura | Vis | Descrição |
|---|---|---|---|---|:-:|---|
| `last_action_date` | Ultima Acao | `action_stats.last_action_date` | `date` | 140 | não | "Data da ultima acao de cobranca registrada para o contato." |
| `last_action_channel` | Canal Ultima Acao | `action_stats.last_action_channel` | texto | 140 | não | "Canal (WhatsApp, e-mail, etc.) da ultima acao de cobranca do contato." |
| `last_action_status` | Status Ultima Acao | `action_stats.last_action_status` | texto | 150 | não | "Status da ultima acao de cobranca registrada para o contato." |
| `action_count_30d` | Acoes (30d) | `action_stats.action_count_30d` | `number`, center | 110 | não | "Quantidade de acoes de cobranca do contato nos ultimos 30 dias." |
| `total_action_count` | Total Acoes | `action_stats.total_action_count` | `number`, center | 110 | não | "Quantidade total de acoes de cobranca ja registradas para o contato." |

#### Grupo "Selos"

| id | Cabeçalho | Conteúdo | Largura | Vis | Ord |
|---|---|---|---|:-:|:-:|
| `seals` | Selos | render especial: até **2** `SealBadge` (pílula com `{color}20` de fundo, borda na cor) + `Badge secondary "+N"`. Vazio → `-` em muted | 180 | não | não |

#### Colunas dinâmicas (campos personalizados)

Geradas por `usePortfolioColumns()` a partir de `useMappedFilterFields()`, para **3 entidades**: `contacts`, `contracts`, `supplies`.

| Propriedade | Valor |
|---|---|
| `id` | `custom_{entity}_{campo}` — garante que campos homônimos de contato e contrato sejam colunas **separadas** |
| `label` | `fieldDef.label` |
| `accessor` | `custom.{campo}` |
| `visible` | `false` (sempre nasce oculta) |
| `width` | 150 |
| `format` | `number` se tipo number; `date` se date; senão `text` |
| `category` | "Campos Personalizados" |
| `entity` | `contact` / `contract` / `supply` |
| `aggregated` | `true` para contrato e suprimento |
| `description` | `Campo personalizado "{label}" do contato/do contrato/do suprimento, importado do ETL.` + `" (agregado por contato)"` quando aplicável |
| Ordenável | **nunca** |

**Render de célula de custom field de contrato/suprimento** (valores distintos entre N registros):
- 0 valores → `-` em muted;
- 1 valor → texto simples;
- 2+ → `primeiro valor` + `Badge secondary "+N"` com **Tooltip** listando todos os valores, e no rodapé do tooltip a nota `HELP_COPY.col_valor_mais_n`: *"O contato/contrato tem mais de um valor neste campo. Mostramos o primeiro e '+N' para os demais — passe o mouse para ver todos."*

**Otimização gateada:** a query de custom fields de **contrato** só roda se houver alguma coluna custom de contrato visível; idem para **suprimento**. A de **contato** nunca é gateada (alimenta também `trading_name` e o pré-preenchimento do `PortfolioEditDialog`).

### 6.3 Cabeçalho de coluna (anatomia)

```
[ botão de ordenar: "Rótulo" + (Layers se agregada) + (↑ | ↓ | ↕ opaco) ]  [ ? ]
```

- O botão de ordenar tem `aria-label` descritivo e `aria-sort` (`ascending`/`descending`/`none`), e a frase muda conforme o estado: "Clique para ordenar por X" / "Ordenado por X em ordem crescente. Clique para ordenar em ordem decrescente" / "... Clique para remover ordenacao".
- O `HelpTip` (ícone `HelpCircle`, 3.5) fica **fora** do botão (evita botão dentro de botão). Corpo = `description` + (se agregada) nota de agregação em 2º parágrafo.
- Coluna não ordenável renderiza só `[rótulo][Layers?][?]`.

### 6.4 Seletor de colunas (`PortfolioColumnToggle`)

| Elemento | Detalhe |
|---|---|
| Gatilho | `Button variant="outline" size="sm"` com ícone `Columns3`, texto "Colunas" e contador `(N)` em muted |
| Popover | `align="end"`, largura 288px (`w-72`), sem padding |
| Cabeçalho | Título "Visibilidade de Colunas"; subtítulo `"{visíveis} de {total} visiveis"`; campo de busca com ícone (`h-8`, placeholder "Buscar coluna...") — filtra por `label` (case-insensitive) |
| Corpo | `ScrollArea` de **400px**. Grupos por **entidade de origem**, na ordem `contact → contract → supply → title`, cada um com ícone (`User`, `FileText`, `Package`, `Receipt`) e título em `uppercase tracking-wide`. Grupo "Outros" para colunas sem `entity` (defensivo) |
| Item | `Checkbox` + `Label` clicável com o rótulo da coluna |
| Grupo "Suprimento" | **escondido** quando `useHasSupply().hasSupply` é falso |
| Vazio | "Nenhuma coluna encontrada" |
| Rodapé | `Button ghost` full-width "Restaurar Padrao" — reaplica `col.visible` de `DEFAULT_COLUMNS` a todas e regrava o localStorage |

**Persistência:** `localStorage["portfolio-column-visibility"]` = `Record<columnId, boolean>`; `localStorage["portfolio-columns-version"]` guarda `COLUMN_VERSION`. Se a versão mudar, a página **apaga** a preferência no mount (efeito em `PortfolioManagementPage`). Leitura/escrita protegidas por try/catch com `logError`.

### 6.5 Ordenação

- Mapa `SORT_FIELD_MAP` (grid id → valor de `p_order_by` da RPC) com **19 colunas**: `name`, `document`, os 6 valores financeiros, `total_contracts`, `overdue_titles`, `total_titles`, `open_titles`, os 4 de dias (`max`/`min`/`avg_days_overdue`, `avg_payment_delay`) e as 3 datas.
- Regra de habilitação: `isSortable = format !== "badge" && !isCustom && !isActionStats`. **Mas** só há efeito se o id estiver no mapa — colunas como `primary_phone`, `paid_titles`, `has_pnp` aparecem com o botão de ordenar e, ao clicar, caem no fallback.
- Fallback: limpar a ordenação (ou coluna não mapeada) volta para `max_days_overdue` **desc**.
- Default da tela: `orderBy = "max_days_overdue"`, `orderDirection = "desc"`.
- Ordenar **reseta a página para 1**. Não limpa a seleção de linhas.
- Apenas **uma** coluna por vez (sorting single).
- ⚠️ A confirmar: o comportamento de clicar numa coluna "ordenável" fora do `SORT_FIELD_MAP` é silenciosamente equivalente a "não fazer nada visível além de resetar a ordenação padrão" — é um defeito de UX a resolver no redesign.

### 6.6 Seleção de linhas

| Aspecto | Comportamento |
|---|---|
| Coluna | primeira, id `select`, largura 40, `enableSorting: false` |
| Header | `Checkbox` "Selecionar todos" — `table.getIsAllPageRowsSelected()` / `toggleAllPageRowsSelected` → seleciona **a página**, não a base |
| Célula | `Checkbox` `aria-label="Selecionar linha"` |
| Estado | sincronizado por índice; `selectedIds` (array de uuid) sobe para a página |
| Limpeza automática | busca, carteiras, filtros, réguas/semRégua, tipo de ação, step, segmento, data de ação e mudança de operador/meus contatos **zeram** a seleção. Trocar de página **não** zera |
| Uso | só habilita "Exportar Selecionados" no menu de exportação. **Não existe barra de ações em massa sobre a seleção** |

### 6.7 Coluna de ações (sticky à direita)

`Button ghost size="icon"` com `MoreHorizontal` → `DropdownMenu align="end"`:

| Item | Ícone | Condição | Ação |
|---|---|---|---|
| Ver Detalhes | `Eye` | sempre | abre a ficha (`PortfolioDetailSheet`) |
| Editar | `Pencil` | `canWrite` | abre `PortfolioEditDialog` |
| Excluir | `Trash2` | `canDelete` | abre `DeleteContactDialog`; item em `text-destructive focus:text-destructive` |

### 6.8 Rodapé / paginação (`PortfolioFooter`)

```
Itens por página [50 ▾]                         1-50 de 12.345   [‹]  1 / 247  [›]
```

| Elemento | Detalhe |
|---|---|
| Container | `flex justify-between px-4 py-3 border-t bg-muted/30`, `flex-shrink-0` |
| Seletor de tamanho | `Select` `h-8 w-[70px]`; opções **10, 25, 50, 100**; default **50** |
| Intervalo | `{from}-{to} de {total}` com total em pt-BR; `from = (page-1)*pageSize+1`, `to = min(page*pageSize, total)` |
| Navegação | dois `Button variant="outline" size="icon" h-8 w-8` com `ChevronLeft`/`ChevronRight`; desabilitados nos extremos |
| Indicador | `{page} / {totalPages || 1}` num span de largura mínima 60px |
| Sem "ir para a página N" | não há input de página nem botões primeiro/último |

Trocar o tamanho da página **reseta para a página 1**; `pageSize` não é gravado na URL.

### 6.9 Estados do grid

| Estado | Render |
|---|---|
| `isLoading` (1ª carga) | Skeleton próprio: `thead` com 7 `Skeleton h-4 w-20` + 10 linhas × 7 células `Skeleton h-4 w-full` |
| `isRefetching` (troca de filtro/sort, com dados antigos) | Overlay absoluto `inset-0 z-30` `bg-background/60 backdrop-blur-[1px]` com `Loader2` girando ao centro; a tabela fica `opacity-50 pointer-events-none` e recebe `aria-busy` |
| `data.length === 0` | Bloco centralizado: "Nenhum contato encontrado" (`text-lg`) + "Tente ajustar os filtros de busca" (`text-sm`), ambos em muted |
| Erro da consulta | fora do grid: `<div role="alert" className="p-3 text-sm text-destructive">Falha ao consultar a carteira: {mensagem}</div>`, renderizado logo abaixo da barra de KPIs |
| Modo selo ativo | linhas com selo aplicado ganham `backgroundColor: {seal.color}25`, `boxShadow: inset 4px 0 0 {seal.color}` e `fontWeight: 500`; as demais recebem borda esquerda transparente para manter o alinhamento |

---

## 7. Visão Kanban

Arquivos: `src/components/portfolio/kanban/` (`KanbanTab`, `KanbanBoard`, `KanbanColumn`, `KanbanContractColumn`, `KanbanCard`, `KanbanContractCard`, `constants.ts`, `types.ts`) + hooks `useBucketContacts`, `useBucketContracts`, `useAgingBuckets`, `useContactAssignments`.

### 7.1 Estrutura da aba

```
┌─ (barra de filtros compartilhada — a MESMA da aba Contatos) ────────────────┐
├─ (barra de KPIs compartilhada — a MESMA) ──────────────────────────────────┤
├─ Visualizar por: [ Contatos | Contratos ]   ← ToggleGroup, px-4 py-2, border-b
├─ Board: scroll horizontal, gap-4, p-4, min-w-max, h-full ──────────────────┤
│  [col Em dia] [col 1-15] [col 16-30] [col 31-60] [col 61-90] [col 91-180] … │
└────────────────────────────────────────────────────────────────────────────┘
```

O único controle **exclusivo** do Kanban é o toggle "Visualizar por". Tudo o mais é herdado da página.

| Item | Valor |
|---|---|
| Modo default | `contracts` (um card por contrato) |
| Alternativa | `contacts` (um card por contato) |
| Componente | `ToggleGroup type="single"` com dois `ToggleGroupItem` e `aria-label` |

### 7.2 Colunas (faixas de aging)

Fonte: `useAgingBuckets()` — lê `organization.settings.aging_buckets`; se não houver, usa `DEFAULT_AGING_BUCKETS`.

| id | Rótulo | min | max | Cor |
|---|---|---|---|---|
| `current` | Em dia | `-Infinity` | 0 | `#10B981` (emerald-500) |
| `1-15` | 1-15 dias | 1 | 15 | `#EAB308` (yellow-500) |
| `16-30` | 16-30 dias | 16 | 30 | `#F97316` (orange-500) |
| `31-60` | 31-60 dias | 31 | 60 | `#EF4444` (red-500) |
| `61-90` | 61-90 dias | 61 | 90 | `#DC2626` (red-600) |
| `91-180` | 91-180 dias | 91 | 180 | `#B91C1C` (red-700) |
| `180+` | 180+ dias | 181 | `Infinity` | `#7C3AED` (violet-600) |

As faixas são configuráveis por organização (1 a 15 buckets, com validação de gaps/overlaps/cores em `validateAgingBuckets`). O redesign **não pode** assumir 7 colunas fixas.

### 7.3 Anatomia da coluna

| Parte | Detalhe |
|---|---|
| Container | `w-[300px] min-w-[300px] h-full`, `rounded-lg border bg-muted/30`, `flex flex-col` |
| Header | `p-3 border-b rounded-t-lg`, fundo `{bucket.color}10`. Linha 1: bolinha 12×12 na cor + `h3` com o rótulo + pílula de contagem à direita (`{color}20` de fundo, texto na cor). Linha 2: **valor somado** da faixa em `text-xs text-muted-foreground tabular-nums` |
| Corpo | `flex-1 overflow-y-auto p-2` com `contain: strict`; lista **virtualizada** (`@tanstack/react-virtual`, `overscan: 5`) |
| Altura estimada do item | 110 + 8 de gap (contatos) · 130 + 8 (contratos) |
| "Carregar mais" | último item virtual quando `hasNextPage`: `Button outline size="sm"` full-width com `ChevronDown` e texto `Carregar mais ({restantes})`; enquanto busca, `Loader2` + "Carregando..." |
| Vazio | `Inbox` 40×40 opaco + "Nenhum contato" / "Nenhum contrato" + `em "{rótulo da faixa}"` |
| Loading | 4 esqueletos com a silhueta do card |

**Paginação:** `KANBAN_PAGE_SIZE = 20` por página de rolagem infinita (constante `KANBAN_INITIAL_LOAD = 50` existe mas não é usada pelo fluxo atual). Ordenação interna da coluna: `p_order_by: "total_pending_value"`.

### 7.4 Card de contato (`KanbanCard`)

```
┌──────────────────────────────────────────┐
│ Nome do Cliente Ltda            (AV)     │  ← nome (font-medium, truncate) + avatar do operador
│ 12.345.678/0001-90                       │  ← documento (font-mono, xs, muted)
│                                          │
│ R$ 12.345,67                  [ 45d ]    │  ← valor (semibold, tabular) + badge do bucket
│                                          │
│ [🧰 Carteira A] [🧰 Carteira B] [+3]      │  ← até 2 chips + "+N" com tooltip
└──────────────────────────────────────────┘
```

| Elemento | Regra |
|---|---|
| Container | `<button>` full-width, `p-3 rounded-lg border bg-card`, hover `shadow-md` + `border-primary/30` + `-translate-y-0.5`, focus ring |
| Nome | `title` com o nome completo |
| Documento | `formatDocument` decidindo CPF/CNPJ **pelo comprimento** |
| Avatar | `Avatar h-7 w-7` com iniciais (2 primeiras palavras) em `bg-primary/10 text-primary`; tooltip com nome e e-mail. Só quando há operador atribuído |
| Valor | `total_pending_value`; `text-destructive` quando `max_days_overdue > 90` |
| Badge de dias | `{color}20` de fundo, texto e borda na cor do bucket; texto `"Em dia"` quando `max_days_overdue <= 0`, senão `"{N}d"` |
| Carteiras | até **2** chips `Badge outline` com ícone `Briefcase`, cor `{color}15`/borda `{color}40`, `max-w-[100px] truncate`; "+N" com **tooltip** listando as ocultas |
| Sem carteira | `"Sem carteira"` em `text-[10px] italic muted` |
| Clique | abre a ficha do contato |

### 7.5 Card de contrato (`KanbanContractCard`)

```
┌──────────────────────────────────────────┐
│ Nome do Cliente Ltda            (AV)     │
│ 📄 CTR-2026-001                          │  ← número do contrato (mono) ou "Sem número"
│ 👤 12.345.678/0001-90                     │  ← documento do contato
│ R$ 4.500,00                   [ 45d ]    │
│ [Locação]  [3 de 12 títulos]             │
└──────────────────────────────────────────┘
```

Diferenças em relação ao card de contato: mostra número do contrato e documento em linhas próprias; no rodapé, badge de **modalidade** (quando existe) e badge `"{vencidos} de {total} títulos"`. Não mostra carteiras.

Clique: hoje chama `handleContractClick`, que — na ausência de `onOpenContractDetail` — monta um **stub de contato** a partir dos dados do contrato e abre a ficha do contato. ⚠️ A confirmar: não existe hoje uma ficha de contrato dedicada a partir do kanban.

### 7.6 Dados e filtros do Kanban

| Aspecto | Detalhe |
|---|---|
| Resumo por coluna | `useKanbanSummaries` (contatos) ou `useKanbanContractSummaries` (contratos) — **uma** chamada atômica que devolve contagem e valor por bucket. Só o summary do modo **ativo** é buscado |
| Conteúdo da coluna | `useBucketContacts` / `useBucketContracts` — `useInfiniteQuery` por bucket, via `get_kanban_data` |
| Atribuições | `useContactAssignments(contactIds)` por coluna, para pintar o avatar |
| Filtros herdados | **todos** os do estado da página: carteiras+lógica, filtros+lógica, réguas+lógica+semRégua, busca, operador, e os conjuntos já resolvidos `contactIds` / `excludeContactIds` (Ação + Segmento) |
| Gate | `isResolving` → a aba mostra `<Skeleton className="h-40 m-4" />` no lugar do board |
| Erro | `<div role="alert" className="p-4 text-destructive">Não foi possível aplicar os filtros: {mensagem}</div>`; erro de bucket/summary tem mensagem própria ("Não foi possível consultar o Kanban: ..."; por coluna: `"{label}: {mensagem}"`) |
| Loading de configuração | "Carregando configuracao..." centralizado enquanto os buckets carregam |

### 7.7 Drag & drop

**Não existe.** Não há `dnd-kit`, `react-beautiful-dnd` nem handlers de drag em nenhum arquivo de `kanban/`. As colunas são uma **projeção read-only** de `days_overdue`; mover um card não faria sentido no modelo de dados (a faixa é derivada, não atribuída).

---

## 8. Painel de detalhe do contato (sheet)

Arquivos: `src/components/portfolio/detail/ContactDetailSheet.tsx` (+ `ContactDetailHeader`, `tabs/*`, `shared/*`). Exportado como `PortfolioDetailSheet` por barrel (`src/components/portfolio/PortfolioDetailSheet.tsx`).

### 8.1 Container

Apesar do nome "sheet", é um **Dialog quase full-screen**:

```tsx
<DialogContent className="w-screen h-screen sm:w-[95vw] sm:h-[95vh] max-w-none max-h-none
                          p-0 flex flex-col rounded-none sm:rounded-lg">
```

- Mobile: ocupa a tela inteira, sem cantos arredondados.
- Desktop: 95% × 95% da viewport, cantos arredondados.
- Fecha com ESC / clique fora / botão X do Dialog.
- Abre quando `detailContact !== null`; o gatilho é o clique na linha do grid, no card do kanban, no item "Ver Detalhes" ou no deep-link `?contact=`.

### 8.2 Cabeçalho (`ContactDetailHeader`)

```
┌───────────────────────────────────────────────────────────────────────────┐
│ (👤)  Nome do Cliente Ltda                              [⚠ 45 dias] [✏]   │
│       12.345.678/0001-90                                                  │
│       Selos: [VIP ✕] [Em negociação ✕] [+]                                │
└───────────────────────────────────────────────────────────────────────────┘
```

| Elemento | Detalhe |
|---|---|
| Avatar | círculo `bg-primary/10`, 40px mobile / 56px desktop, ícone `User` |
| Título | `DialogTitle` `text-lg sm:text-xl font-semibold truncate` = `contact.name` |
| Documento | `DialogDescription` com `font-mono text-sm`, formatado por comprimento (>11 → CNPJ) |
| Linha de selos | prefixo "Selos:" + `SealBadge` por selo aplicado (com `X` se `seals:apply`) + `SealPicker` (botão `+`) |
| Badge de risco | só quando `max_days_overdue > 0`: `Badge` `destructive` se `> 90`, senão `secondary`; ícone `AlertTriangle` + `formatDaysOverdue(dias)` |
| Editar | `Button ghost size="sm"` com `Pencil`; só quando `canWrite`. Abre `PortfolioEditDialog` |
| Padding | `p-4 sm:p-6 pb-4 border-b`, `pr-10` para não colidir com o X do Dialog |

### 8.3 Linha de abas + controles

Na mesma faixa (`mx-3 sm:mx-6 mt-4`, empilha em coluna no mobile):

**Esquerda — `TabsList`:**

| Valor | Rótulo | Condição |
|---|---|---|
| `overview` | Visão Geral | sempre (default) |
| `info` | Informações | sempre |
| `supplies` | Suprimentos | **só se `useHasSupply().hasSupply`** |
| `history` | Histórico | sempre |
| `blocklist` | Bloqueios | sempre |

**Direita:**

| Controle | Detalhe |
|---|---|
| **Nova Ação** | `Button outline size="sm"` com `Send`; só com `actions:write`. Abre `ManualActionDialog` |
| **Operador** | ícone `UserPlus` + label "Operador:" + `Select` (`w-full sm:w-[200px] h-8`). Item "Não atribuído" (`value="none"`, em muted) + um item por usuário da org (`full_name \|\| email \|\| id.slice(0,8)`). Escolher chama `useAssignContact`; "Não atribuído" chama `useUnassignContact`. `disabled` enquanto a mutation roda **ou** sem `contacts:write` |

O corpo das abas vive dentro de um `ScrollArea flex-1 px-3 sm:px-6 pb-4 sm:pb-6`.

### 8.4 Dados carregados pela sheet

`ContactDetailSheet` dispara, ao abrir:

| Hook | O que traz |
|---|---|
| `useContact(id)` | cadastro completo (telefones, e-mails, endereço, custom_fields) |
| `useContracts({contact_id})` | contratos |
| `useTitlesByContact(id)` | todos os títulos (não removidos) |
| `useContractMetrics(id)` | `safra_days`, `min_open_installment`, `min_open_installment_disponivel` por contrato (de `vw_titles_live`) |
| `useSupplies({contact_id})` / `useSupplyTitlesByContact(id)` / `useSupplyMetrics(id)` | mundo suprimento |
| `useCustomFieldDefinitions(...)` × 5 | definições de campos personalizados de `contacts`, `contracts`, `titles`, `supplies`, `supply_titles` |
| `useContactPortfolios` / `useContactWorkflows` / `useContactCampaigns` | vínculos ativos |
| `useContactAssignment(id)` + `useOrganizationUsers()` | operador atribuído |

**Recalculo local:** `recalculatedMetrics` percorre os títulos **filtrados (não removidos)** e recalcula `maxDaysOverdue`, `totalOverdueValue` e `totalOpenValue` — os StatCards da Visão Geral usam esses números, não os agregados da MV.

---

### 8.5 Aba **Visão Geral** (`tabs/OverviewTab.tsx`)

#### 8.5.1 Faixa de StatCards

Grid `2 col (mobile) / 3 (sm) / 6 (lg)`, gap 2/4. Cada card: `rounded-lg p-3`, linha de ícone (16px) + rótulo em `text-xs muted`, valor em `font-semibold text-lg`.

| # | Ícone | Rótulo | Valor | Variante |
|---|---|---|---|---|
| 1 | `FileText` | Contratos | `contact.total_contracts` | default |
| 2 | `AlertTriangle` | Títulos Vencidos | `countOverdueTitles(titles)` | `warning` se `> 0` |
| 3 | `DollarSign` | Valor em Atraso | `formatCurrency(totalOverdueValue)` | `danger` se `> 0` |
| 4 | `DollarSign` | Saldo em Aberto | `formatCurrency(totalOpenValue)` | `warning` se `> 0` |
| 5 | `Clock` | Dias em Atraso | `maxDaysOverdue` | `warning` se `> 30` |
| 6 | `TrendingUp` | Média Atraso Pgto | `"{avg_payment_delay}d"` ou `"---"` | `warning` se `> 30` |

Variantes (`shared/StatCard.tsx`): `default` = `bg-muted/50` + ícone muted; `warning` = `bg-orange-50 dark:bg-orange-950/30` + ícone `text-orange-500`; `danger` = `bg-red-50 dark:bg-red-950/30` + ícone `text-red-500`.

#### 8.5.2 Layout de duas colunas

`grid lg:grid-cols-[1fr_320px] gap-6`. Abaixo de `lg` vira uma coluna, com a lateral ganhando `border-t pt-4`.

#### 8.5.3 Coluna esquerda — cascata Contratos → Títulos

Título da seção: ícone `FileText` + "Contratos e Títulos".

**Card do contrato** (`border rounded-lg`, `Collapsible` fechado por padrão):

Cabeçalho (botão full-width, hover `bg-muted/50`):
- esquerda: chevron (`ChevronDown`/`ChevronRight`) + ícone `FileText` + **número do contrato** (font-medium) e **modalidade** (xs muted);
- direita: `StatusBadge` do status do contrato · bloco "Pendente" com `pending_value` (oculto `<sm`) · bloco "Títulos" com a contagem (oculto `<sm`) · botão `Pencil` (só com `contracts:write`, `stopPropagation`).

Conteúdo expandido:
1. **Linha de selos do contrato** — label "Selos:" + `ContractSealsCell` (badges + picker). Fica dentro do conteúdo porque o gatilho do Collapsible já é um `<button>`.
2. **Grade de 9 detalhes** (`grid-cols-2 sm:grid-cols-3`): Valor Total, Valor Pago (em verde), Dias em Atraso (recalculado do MAX dos títulos ativos), Data Inicio, Data Fim, Carteira, Dias de Safra, 1ª Parc. em Aberto, 1ª Parc. Disponível.
3. **Campos do Contrato** — `CustomFieldsGrid` compacto (3 colunas) com toggle "Mostrar todos (N)" / "Ocultar vazios", por contrato.
4. **Títulos (N)** — subtítulo com ícone `Receipt` e a lista aninhada.

**Card do título** (`border rounded-md bg-muted/20`, `Collapsible` fechado):

Cabeçalho:
- esquerda: chevron + ícone `Receipt` + **número do título** e `Parcela {n}/{total}`;
- direita: bloco "Vencimento" com a data (oculto `<sm`) · `TitleStatusBadge` · **valor** (`getSafeValue(current, original)`, `min-w-[90px]` à direita) · botão `Pencil` (com `contracts:write`).

Conteúdo expandido:
1. **Selos do título** (`TitleSealsCell`);
2. **Grade de até 11 campos** (`grid-cols-2 sm:grid-cols-4`): Valor Original · *Valor Atual* (só se `hasRealUpdatedValue`) · Valor Pago (verde) · Desconto · Juros · Multa · "Dias em Atraso" **ou** "Atraso no Pagamento" (o rótulo muda se o título está pago; valor em `text-destructive` quando em atraso e não pago; "No prazo" quando `days_overdue <= 0`) · Forma Pagamento · Data Vencimento · Data Pagamento · ID Externo;
3. **Pipeline / Fonte de dados** — quando há `owner_pipeline`: ícone `Database` + `Pipeline: {nome}` · `Fonte: {data_source.name}`;
4. **Códigos copiáveis** — quando há boleto/PIX: `CopyableField` "Linha Digitavel (Boleto)" (`boleto_digitable_line || bank_slip_code`) e "Chave PIX" (`pix_key || pix_code`). Cada um é um `<code>` com botão `Copy` e tooltip "Copiar";
5. **Campos do Titulo** — `CustomFieldsGrid` compacto com toggle próprio por título.

Estados: enquanto carrega, 2 `Skeleton h-16`; sem contratos, bloco central com `FileText` opaco + "Nenhum contrato encontrado".

#### 8.5.4 Coluna direita (320px)

1. **Vínculos Ativos** (`shared/BindingsSection.tsx`) — título com ícone `Puzzle`. Três linhas rotuladas (`min-w-[70px]`): **Carteiras:** (ícone `Briefcase`, chips com fundo na cor sólida e texto branco), **Reguas:** (ícone `Route`, cada item **navega** para `/reguas-cobranca/{id}/editor`), **Campanhas:** (ícone `Megaphone`, `badgeVariant="outline"`). Cada uma usa `OverflowBadgeList` com `visibleCount=3` e nota de rodapé explicativa. A seção inteira retorna `null` se as três listas estiverem vazias.
2. **Informações de Contato** — "Telefones" (lista com ícone `Phone` e `formatPhone`) e "Emails" (ícone `Mail`, `text-xs truncate`). Enquanto carrega, 2 skeletons.
3. **Endereço** — só quando há `address_street` ou `address_city`. Título com ícone `MapPin`; 3 linhas: logradouro+número+complemento · bairro − cidade/UF · `CEP: xxxxx`.
4. **Datas Importantes** — título com ícone `Calendar`; três `DateItem`: Próximo Vencimento, Último Pagamento, Cadastrado em (`formatDate` ou `"---"`).

Separadores `Separator` entre os blocos. **Os campos personalizados do contato saíram desta coluna** e viraram a aba Informações (decisão documentada em comentário no próprio arquivo).

---

### 8.6 Aba **Informações** (`tabs/InfoTab.tsx` + `tabs/contactInfoItems.ts`)

O cadastro completo do cliente em um lugar só. Módulo de dados **puro** e testado (`__tests__/contactInfoItems.spec.ts`, `__tests__/InfoTab.spec.tsx`).

#### 8.6.1 Barra superior

```
[🔍 Buscar campo ou valor…            ✕]        42 campos   [👁 Mostrar vazios]
```

| Controle | Detalhe |
|---|---|
| Busca | `Input` com ícone `Search` à esquerda e botão `X` "Limpar busca" à direita (só quando há texto). `aria-label="Buscar nas informações do cliente"`. Largura máx. `sm:max-w-md` |
| Contador | `"{visíveis} de {total} campos"` durante a busca; `"{total} campos"` fora dela. Singular/plural correto |
| Toggle vazios | `Button ghost size="sm"` alternando `Eye`/"Mostrar vazios" ↔ `EyeOff`/"Ocultar vazios". **Desabilitado durante a busca** |

**Regras de busca** (`normalizeSearch`): remove acentos (NFD + faixa de diacríticos), minúsculas, trim — aplicado nos **dois lados**. Casa `label`, `text` **ou** `hint`. Seção que fica sem item **desaparece** (não vira título órfão). Durante a busca, campos vazios aparecem de qualquer forma (esconder responderia "não existe" a algo que existe e está vazio).

#### 8.6.2 Seções e campos

Cada seção é um `<section className="rounded-lg border">` com header `bg-muted/30` contendo ícone, título e a contagem de itens. Grade `1 / 2 (sm) / 3 (xl)` colunas.

| Seção | id | Ícone | Itens |
|---|---|---|---|
| Identificação | `identificacao` | `IdCard` | **Nome** · **Nome fantasia / Razão social** · **Documento** (mono) · **Tipo de documento** (derivado do **comprimento**, não da coluna `document_type` — 84% dos CNPJ vêm gravados como `cpf` pelo ETL) · **Situação do cadastro** (badge `Ativo` secondary / `Inativo` outline) · **ID interno** (mono) |
| Telefones | `telefones` | `Phone` | 1 item por telefone: rótulo `Telefone {n}`, valor `formatPhone`, hint = `tipo · WhatsApp · verificado · inativo` (o que se aplicar). Sem telefones → um item vazio rotulado "Telefones" |
| E-mails | `emails` | `Mail` | 1 item por e-mail: `E-mail {n}`, hint = `tipo · verificado · inativo`. Sem e-mails → item vazio |
| Endereço | `endereco` | `MapPin` | **Logradouro** (rua, número, complemento) · **Bairro** · **Cidade / UF** · **CEP** · **Endereço completo** (tudo junto separado por ` · `) |
| Datas e atividade | `datas` | `Calendar` | **Próximo vencimento** · **Último pagamento** · **Primeiro contrato** · **Fim do último contrato** · **Dias desde a última atividade** · **Cadastrado em** (`formatDateTime`) · **Atualizado em** (`formatDateTime`) |
| Etiquetas e anotações | `anotacoes` | `StickyNote` | **Etiquetas** (`contact.tags` — render rico: `Badge outline` por tag; texto para busca = tags separadas por vírgula) · **Anotações** (`contact.notes`) |
| Campos personalizados | `personalizados` | `SlidersHorizontal` | **todos** os custom fields de contato, **preenchidos primeiro** e depois os vazios, cada bloco em ordem alfabética de rótulo (pt-BR). Render rico vem de `formatCustomValue` |

#### 8.6.3 Item de campo (`InfoField`)

```
┌──────────────────────────────────┐
│ Rótulo                    [copiar]│  ← rótulo xs muted; botão aparece no hover/foco
│ Valor                             │  ← ou "—" em itálico muted/50 se vazio
│ hint · secundário                 │
└──────────────────────────────────┘
```

- `group` + `hover:bg-muted/40`, `rounded-md px-2 py-1.5`.
- Botão copiar: `opacity-0` → visível no hover/`focus-visible`; **sempre visível** em dispositivos sem hover (`[@media(hover:none)]:opacity-100`). Vira `Check` verde por 1,2 s após copiar. `aria-label="Copiar valor"`. Não renderiza quando o valor é vazio.
- `mono: true` para documentos e ids.

#### 8.6.4 Estados

| Estado | Render |
|---|---|
| `isLoading` | `Skeleton h-9` (barra) + 3 × `Skeleton h-32` |
| Busca sem resultado | bloco tracejado (`border-dashed py-12`) com ícone `Building2` e `Nenhuma informação corresponde a **{termo}**.` |

---

### 8.7 Aba **Suprimentos** (`tabs/SuppliesTab.tsx`)

Clone focado da Visão Geral para o mundo suprimento. Só existe quando `hasSupply`.

#### 8.7.1 StatCards (5)

| Ícone | Rótulo | Valor | Variante |
|---|---|---|---|
| `Package` | Suprimentos | `supplies.length` | default |
| `AlertTriangle` | Parcelas Vencidas | `countOverdueTitles(supplyTitles)` | warning se `> 0` |
| `DollarSign` | Valor em Atraso | soma do aberto dos vencidos | danger se `> 0` |
| `DollarSign` | Saldo em Aberto | soma do aberto | warning se `> 0` |
| `Clock` | Dias em Atraso | MAX dos vencidos | warning se `> 30` |

Grid `2 / 3 (sm) / 5 (lg)`.

#### 8.7.2 Cascata Suprimento → Parcelas

Título: ícone `Package` + "Suprimentos e Parcelas".

**Card do suprimento** (Collapsible):
- Cabeçalho: chevron + `Package` + **número do suprimento** + subtítulo literal "Suprimento"; à direita `StatusBadge`, "Pendente" com `pending_value`, "Parcelas" com a contagem, e `Pencil` (com `contracts:write`).
- Conteúdo: grade de **8 campos** — Valor Total · Valor Pago (verde) · Dias em Atraso · **Faixa de Atraso** (`aging_bucket`) · **Venc. Mais Antigo** (`oldest_due_date`) · Dias de Safra · 1ª Parc. em Aberto · 1ª Parc. Disponível. Depois, "Campos do Suprimento" (`CustomFieldsGrid`) e a lista de parcelas.

**Card da parcela** — idêntico ao card de título da Visão Geral (mesma grade de 11 campos, mesmo `TitleStatusBadge`, mesmo bloco de Pipeline/Fonte, mesmos códigos copiáveis — aqui só `boleto_digitable_line` e `pix_key`), com o subtítulo "Campos da Parcela" para os custom fields.

**Diferença notável:** a aba Suprimentos **não** tem linha de selos (não há `SealScope` de suprimento).

Estados: 2 `Skeleton h-16` durante o carregamento; vazio com ícone `Package` + "Nenhum suprimento encontrado".

---

### 8.8 Aba **Histórico** (`tabs/HistoryTab.tsx` + `shared/ActionTimelineItem.tsx`)

#### 8.8.1 Cabeçalho (só com `reports:export`)

```
A linha do tempo mostra as interacoes mais recentes. A exportacao traz o
historico completo, em ordem cronologica.                [⤓ Exportar histórico]
```

O texto existe porque a timeline mostra **as 100 mais recentes** (teto de `useContactActions`) enquanto a exportação lê pela RPC, sem teto.

#### 8.8.2 Linha do tempo

Estrutura: uma linha vertical (`absolute left-[19px] w-0.5 bg-border`) atravessando os itens, com `space-y-4`.

**Item (`ActionTimelineItem`):**

| Parte | Detalhe |
|---|---|
| Bolinha | círculo 40px com borda 2px; o **mais recente** (`isLatest`) fica `border-primary bg-primary text-primary-foreground`, os demais `border-border bg-background` + ícone muted |
| Ícone do tipo | `MessageSquare` (whatsapp) · `Mail` (email) · `Phone` (sms) · `Globe` (webhook) · `Send` (default) |
| Card | `rounded-lg border p-4`; o mais recente ganha `border-primary/30 bg-primary/5` |
| Linha 1 | `Badge` do tipo (cor de `ACTION_TYPES`) + `Badge outline` do status com ícone (`CheckCircle2` para Interagiu; `XCircle` para Falhou/Falha Permanente; `Send` para Enviado; `Clock` para o resto) + badge **Manual** (violeta) ou **Teste** (âmbar) conforme `action.source`; à direita, data/hora `formatDateTime(created_at)` |
| Destinatário | `Para: {recipient}` em mono, quando existe |
| Campanha / step | linha com ícone `Megaphone` (nome da campanha) e `GitBranch` (nome do step + nome da régua entre parênteses) |
| Assunto | `Assunto: {subject}` (e-mail) |
| Conteúdo | bloco `bg-muted/50 rounded-md p-3` com `line-clamp-3 whitespace-pre-wrap` |
| Erro | bloco `bg-destructive/10 text-destructive` com ícone `XCircle` e a mensagem |
| Timeline de entrega | até 3 marcadores com tooltip de data/hora: **Enviado** (`Send`), **Entregue** (`CheckCircle2`, verde), **Lido** (`Eye`, azul) |
| Clique | abre o **drill-down** da ação |

#### 8.8.3 Drill-down da ação

Clicar num item **substitui o conteúdo da aba** (não abre outro modal): aparece um botão `← Voltar ao Histórico` e o `ActionDetailContent` (componente compartilhado com a tela de Ações). Enquanto carrega: botão "Voltar" + `Skeleton h-64`. Se não achar: "Não foi possível carregar os detalhes da ação."

#### 8.8.4 Estados

| Estado | Render |
|---|---|
| carregando | 3 × `Skeleton h-20` |
| vazio | ícone `Clock` 48px opaco + "Nenhuma interacao registrada" + "As acoes e mensagens enviadas aparecerao aqui." |

---

### 8.9 Aba **Bloqueios**

Renderiza apenas `<BlocklistActiveCard targetType="contact" targetId={contact.id} document={contact.document} showHistory />`. Detalhado em §9.7.

---

## 9. Aba Lista de Bloqueio / Blocklist V2

Arquivo principal: `src/components/portfolio/BlocklistTabV2.tsx` (955 linhas). Existe ainda `BlocklistTab.tsx` (V1, por documento único) — **não montado** pela `PortfolioManagementPage`, junto com `BlocklistDialog.tsx`. Ver §18.

### 9.1 Estrutura

```
┌─ Header ───────────────────────────────────────────────────────────────────┐
│ (Ban) Blocklist                    [Nova Regra] [Bloquear em massa]         │
│       61 bloqueios ativos — 45 contato(s), 12 contrato(s), 4 título(s),     │
│       3 email(s), 1 telefone(s)    [Liberar em massa] [+ Novo Bloqueio]     │
├─ Sub-abas ─────────────────────────────────────────────────────────────────┤
│ ( Bloqueios ativos 61 ) ( Desbloqueados 4 ) ( Regras de Filtro 2 )          │
├─ Filtros da sub-aba ───────────────────────────────────────────────────────┤
│ [🔍 buscar...] [Tipo ▾] [Origem ▾] [Estado ▾]                              │
├─ Tabela ───────────────────────────────────────────────────────────────────┤
│ Tipo │ Alvo │ Origem │ Motivo │ Prazo │ Adicionado │ (⋯)                    │
└────────────────────────────────────────────────────────────────────────────┘
```

### 9.2 Cabeçalho

| Elemento | Detalhe |
|---|---|
| Ícone + título | `Ban` em `text-destructive` + `<h2>Blocklist</h2>` |
| Subtítulo | `{total} bloqueio(s) ativo(s)` com plural correto; quando `total > 0`, acrescenta a quebra: `— {contact} contato(s), {contract} contrato(s), {title} título(s)` e, **se houver**, `, {email} email(s), {phone} telefone(s)` |
| Botões (só `contacts:write`) | 4, em `flex-wrap justify-end gap-2`: **Nova Regra** (outline, `Filter`) · **Bloquear em massa** (outline, `Layers`) · **Liberar em massa** (outline, `KeyRound`) · **Novo Bloqueio** (primário, `Plus`) |

### 9.3 Sub-abas (contadores)

| Valor | Rótulo | Badge |
|---|---|---|
| `entries` (default) | Bloqueios ativos | `stats.total` |
| `exceptions` | Desbloqueados | `exceptionStats.total` |
| `rules` | Regras de Filtro | nº de regras **ativas** (`rules.filter(r => r.is_active).length`) |

### 9.4 Esferas de bloqueio (7 tipos de alvo)

`TARGET_TYPE_LABELS` (`src/types/blocklist-v2.ts`):

| `target_type` | Rótulo | Badge variant | Onde é criável |
|---|---|---|---|
| `contact` | Contato | `default` | unitário + massa |
| `contract` | Contrato | `secondary` | unitário + massa |
| `title` | Título | `outline` | **só unitário** |
| `supply` | Suprimento | `outline` (fallback) | unitário + massa (só com `hasSupply`) |
| `supply_title` | Parcela de Suprimento | `outline` | **só unitário** |
| `email` | E-mail | `secondary` | unitário + massa |
| `phone` | Telefone | `secondary` | unitário + massa |

Título e parcela de suprimento ficam fora do fluxo em massa **de propósito**: `title_number` só é único dentro do contrato/suprimento, então uma lista colada casaria com alvos de contratos diferentes.

**Escopo de canal** (`channel_scope`, só para `contact`): `null` = "Todos os canais"; `phone` = "Apenas Telefone" (cobre WhatsApp, SMS e voz); `email` = "Apenas e-mail". Aparece no `TargetCell` como `Contato · só Telefone`.

**Origens** (`SOURCE_LABELS`): `manual` → "Manual" (badge `default`) · `filter` → "Por Filtro" (`secondary`) · `external` → "Externo" (`outline`).

**Motivos de bloqueio** (`BLOCKLIST_REASONS`): Processo Judicial, Procon, Acordo Externo, Não Perturbe, Óbito, Regra de Filtro (interno, **filtrado fora** do select manual), Outro. Motivos de origem `filter` chegam como `filter_rule_match:{nome}` e são renderizados como `Regra: {nome}`.

### 9.5 Sub-aba **Bloqueios ativos**

#### 9.5.1 Filtros

| Filtro | Controle | Opções | Default |
|---|---|---|---|
| Busca | `Input` com ícone `Search`, `flex-1 min-w-[200px]` | texto — busca por **documento, motivo, observação** (valores do próprio registro, não busca de cliente) | `""` |
| Tipo | `Select` 160px | Todos os tipos · Contato · Contrato · Título · E-mail · Telefone | `all` |
| Origem | `Select` 160px | Todas origens · Manual · Por Filtro · Externo | `all` |
| Estado | `Select` 140px | Ativos · Expirados · Todos | `active` |

⚠️ Inconsistência de catálogo: o Select de **Tipo** desta sub-aba **não** oferece Suprimento nem Parcela de Suprimento, enquanto a sub-aba "Desbloqueados" oferece os 7. Corrigir no redesign.

#### 9.5.2 Tabela (7 colunas)

| Coluna | Largura | Conteúdo |
|---|---|---|
| Tipo | 110 | `Badge` com `TARGET_TYPE_LABELS[target_type]`, variante por tipo |
| Alvo | flex | `TargetCell` (ver abaixo) + eventual selo "Desbloqueado por exceção" |
| Origem | 110 | `Badge` com `SOURCE_LABELS[source]` |
| Motivo | 220 | `reasonLabel(reason)` truncado em 200px, com `title` completo |
| Prazo | 140 | ícone `Clock` + `dd/MM/yy` quando há `blocked_until`; senão "Permanente" em muted |
| Adicionado | 140 | `formatDistanceToNow(created_at, {locale: ptBR, addSuffix: true})` → "há 3 dias" |
| (ações) | 60 | lixeira |

**`TargetCell`** (compartilhado com Desbloqueados — as duas tabelas guardam o alvo igual):
- nome do alvo em `text-sm font-medium` (quando enriquecido);
- **contato**: documento formatado (CPF/CNPJ) em mono + linha `Contato · só Telefone|só Email` quando há `channel_scope`;
- **email**: o endereço em mono, `break-all`;
- **phone**: telefone formatado `(DD) NNNNN-NNNN` (tolera DDI 55);
- **demais**: `target_id.slice(0,8)...` em mono;
- contato sem nome e sem `target_id`: `Não cadastrado` em itálico muted (bloqueio preventivo por documento).

**Selo "Desbloqueado por exceção"**: pílula âmbar (`bg-amber-100 text-amber-800`, dark `bg-amber-950/50 text-amber-300`) com ícone `KeyRound`, exibida quando a chave do alvo está no conjunto de exceções **ativas**. `title`: *"Existe um passe livre ativo para este alvo: o bloqueio está registrado, mas não é aplicado no envio."*

A chave de conflito é `blocklistTargetKey` = `target_type|target_id|document_number|target_value`. Como a exceção de **contato** libera contratos e títulos dele, o selo indica conflito **direto** — a ausência dele não prova ausência de liberação.

#### 9.5.3 Ação de remover

| Origem | Estado do botão |
|---|---|
| `manual` / `external` | `Button ghost size="icon"` com `Trash2`, hover `text-destructive`, `title="Remover bloqueio"` |
| `filter` | mesmo botão, **desabilitado**, `opacity-30 cursor-not-allowed`, `title="Bloqueios por regra de filtro só são removidos quando o alvo deixa de bater no filtro, ou quando a regra é pausada/excluída"` |

Confirmação (`AlertDialog`): título "Remover bloqueio?"; corpo "O bloqueio será removido. Comunicações para o alvo voltarão a fluir (a menos que outro bloqueio ativo exista para o mesmo alvo)."; botões "Cancelar" e ação destrutiva "Remover" / "Removendo...".

#### 9.5.4 Estado vazio

Ícone `AlertTriangle` 32px opaco, "Nenhum bloqueio encontrado" + subtexto condicional: com filtros → "Ajuste os filtros para ver outros resultados"; sem filtros → "Nenhum bloqueio ativo. Adicione bloqueio manual ou crie regra por filtro."

### 9.6 Sub-aba **Desbloqueados** (passe livre)

#### 9.6.1 Explicação fixa no topo

> "Passe livre: o alvo continua aparecendo como bloqueado, mas o bloqueio **não é aplicado** no envio enquanto o passe estiver válido. Vale contra bloqueio de qualquer origem — manual, por regra de filtro ou externo."

#### 9.6.2 Filtros (independentes da outra sub-aba)

| Filtro | Opções | Default |
|---|---|---|
| Busca | documento, motivo, observação | `""` |
| Tipo | Todos · Contato · Contrato · Título · **Suprimento** · **Parcela de Suprimento** · Email · Telefone | `all` |
| Estado | Ativos · Expirados · Todos | `active` |

#### 9.6.3 Tabela (6 colunas)

| Coluna | Largura | Conteúdo |
|---|---|---|
| Tipo | 110 | badge do `target_type` |
| Alvo | flex | mesmo `TargetCell` |
| Motivo | 220 | `exceptionReasonLabel(reason)` truncado; `title` = `notes` ou o próprio rótulo |
| Válido até | 140 | `Clock` + `dd/MM/yy`, ou "Permanente" |
| Adicionado | 140 | `formatDistanceToNow` |
| (ações) | 60 | lixeira "Remover passe livre" (só `canWrite`) |

**Motivos de exceção** (`BLOCKLIST_EXCEPTION_REASONS`): Negociação em andamento · Acordo de pagamento · Solicitação do cliente · Revisão operacional · Liberação jurídica · Outro. O resolvedor de rótulo tem fallback para `BLOCKLIST_REASONS` (uma exceção criada por outro caminho pode trazer motivo de bloqueio).

Confirmação de remoção: "Remover passe livre?" / "O alvo volta a respeitar os bloqueios que já existiam para ele — inclusive os gerados por regra de filtro, que continuaram registrados durante a liberação." Toast de sucesso: "Passe livre removido — Os bloqueios que já existiam para esse alvo voltam a valer."

Vazio: ícone `KeyRound` + "Nenhum alvo desbloqueado" + `Use "Liberar em massa" para dar passe livre a uma lista de alvos.`

### 9.7 Sub-aba **Regras de Filtro**

#### 9.7.1 Tabela (7 colunas); linha inteira é clicável → abre o detalhe

| Coluna | Largura | Conteúdo |
|---|---|---|
| Regra | flex | nome (font-medium) + descrição truncada em 300px |
| Alvo | 110 | badge do `target_entity` |
| Filtro | flex | `filter_definition_name`, ou `filtro órfão` em itálico muted |
| Bloqueios ativos | 120 | `Badge secondary` com `active_entries_count ?? 0` |
| Último sync | 140 | `formatDistanceToNow(last_synced_at)` ou "Nunca"; se houver `last_sync_error`, segunda linha `Erro no último sync` em `text-destructive` com `title` = a mensagem |
| Status | 100 | `Badge default "Ativa"` ou `Badge outline "Pausada"` |
| (menu) | 60 | `MoreHorizontal` → **Pausar/Reativar** e **Excluir** (destrutivo). A célula faz `stopPropagation` |

#### 9.7.2 Confirmações

| Ação | Título | Corpo | Toast |
|---|---|---|---|
| Pausar | "Pausar regra?" | "Regra **{nome}** será pausada. Todos os bloqueios gerados por ela serão removidos no próximo sync (até 16 min)." | "Regra pausada — Bloqueios desta regra serão removidos no próximo sync (até 16 min)." |
| Reativar | "Reativar regra?" | "Regra **{nome}** será reativada. Bloqueios serão materializados no próximo sync." | "Regra ativada — Bloqueios serão materializados no próximo sync (até 16 min)." |
| Excluir | "Excluir regra?" | "Regra **{nome}** será excluída permanentemente." + (se houver) " Os **{N} bloqueio(s)** gerados por ela também serão removidos imediatamente." | "Regra excluída — {N} bloqueio(s) gerado(s) por esta regra também foram removidos." |

Vazio: `Filter` 32px + "Nenhuma regra de filtro" + "Crie regras para bloquear automaticamente contatos que matcham um filtro."

### 9.8 `BlocklistActiveCard` (card embutido)

Arquivo: `src/components/portfolio/BlocklistActiveCard.tsx`. Aparece em: aba **Bloqueios** da ficha do contato (com `showHistory`), e no topo dos editores `ContractEditDialog`, `TitleEditDialog`, `SupplyEditDialog`, `SupplyTitleEditDialog`.

| Props | `targetType`, `targetId`, `document?` (só contato, cobre bloqueio órfão sem `target_id`), `showHistory?` |
|---|---|
| Sem bloqueios | `Card` com título "Bloqueios ativos" e corpo `Nenhum bloqueio ativo para este {tipo em minúsculas}.` |
| Com bloqueios | Título em `text-destructive`: `Bloqueios ativos ({N})`. Um `Alert variant="destructive"` por bloqueio, com: badge da origem + motivo em negrito · observações em xs muted · linha `Desde {data} · Expira {data}` ou `· Permanente` |
| Histórico (opcional) | Bloco separado com ícone `History` e "Histórico recente" — até 5 itens: `{rótulo do evento} · {data/hora} — {notas}` |

**Rótulos de evento** (`HISTORY_EVENT_LABELS`): Criado · Expirado · Filtro deixou de bater · Regra pausada · **Regra venceu** · Regra excluída · Removido manualmente · Removido (API externa) · Atualizado · **Desbloqueado (passe livre)** · **Passe livre removido** · **Passe livre venceu**.

---

## 10. Selos e tags

### 10.1 Selo vs tag

| | Selo | Tag |
|---|---|---|
| Armazenamento | `seal_catalog` + tabelas de junção por escopo | `contacts.tags` (`string[]`) |
| Escopo | `contact` · `contract` · `title` | só contato |
| Cor | sim (hex, 10 cores padrão) | não |
| Catálogo | sim, gerenciado em Configurações | não (texto livre) |
| Aplicação na tela | picker por entidade + **modo de aplicação em massa** | só no `ContactDialog` legado |
| Onde aparece | coluna "Selos", cabeçalho da ficha, linha por contrato/título | aba Informações ("Etiquetas") |

Paleta padrão (`SEAL_DEFAULT_COLORS`): `#6b7280` gray · `#ef4444` red · `#f97316` orange · `#eab308` yellow · `#22c55e` green · `#14b8a6` teal · `#3b82f6` blue · `#8b5cf6` violet · `#ec4899` pink · `#a855f7` purple.

### 10.2 `SealBadge`

Pílula `rounded-full` com borda, fundo `{color}20`, borda e texto na cor do selo. Dois tamanhos: `sm` (`text-xs px-2 py-0.5`, default) e `md` (`text-sm px-3 py-1`). Nome truncado em `max-w-36`. Quando `onRemove` é passado, ganha um `X` com `aria-label="Remover selo {nome}"`.

### 10.3 `SealPicker` (aplicar em uma entidade)

| Elemento | Detalhe |
|---|---|
| Visibilidade | retorna `null` sem `seals:apply` |
| Gatilho | `icon` (default): `Button ghost size="icon" h-7 w-7` com `Plus`; ou `button`: `Button outline size="sm"` com o `triggerLabel` |
| Popover | 288px, `align="end"` |
| Busca | `Input h-8` com ícone, filtra o catálogo por nome (case-insensitive) |
| Lista | `max-h-64 overflow-y-auto`; cada item é um `<button>` com `SealBadge` e, se aplicado, `Check` à direita + `bg-accent/50`. Clicar **alterna** (aplica/remove) |
| Vazio | "Nenhum selo encontrado" |
| Rodapé | "Criar novo selo" (`Plus`, só com `seals:manage_catalog`) + link `Gerenciar selos →` para `/settings?tab=seals` |
| Criação inline | ao criar, o novo selo é **aplicado automaticamente** à entidade |

### 10.4 `SealDialog` (criar/editar selo)

| Campo | Controle | Validação |
|---|---|---|
| Nome | `Input`, `maxLength={64}` | `required`, `.trim()` não vazio (gate do botão) |
| Cor | grade de 10 bolinhas 32×32 `rounded-full`; a selecionada ganha `border-foreground scale-110`; `aria-label="Cor {hex}"` | default = 1ª cor |
| Descrição (opcional) | `Textarea` 2 linhas, `maxLength={256}` | — |

Título: "Novo Selo" / "Editar Selo". Botões: "Cancelar" e "Criar"/"Salvar" (→ "Salvando..."). ⚠️ Bug conhecido: o arquivo usa `<Textarea>` sem importá-lo — `src/components/seals/SealDialog.tsx` importa apenas `Input`, `Label`, `Button`. A confirmar em runtime.

### 10.5 Modo "Aplicar Selo" em massa (grid)

Fluxo de 4 passos (é a única ação verdadeiramente em massa da tela):

1. **Escolher** — `ApplySealButton` no header abre popover com o catálogo de **contato**; texto de topo: "Escolha um selo para entrar no modo de aplicação". Cada item é um botão com `SealBadge`. Rodapé com "Criar novo selo" (com `seals:manage_catalog`), que ao criar já entra no modo com o selo novo.
2. **Modo ativo** — `ApplySealMode` renderiza uma faixa `sticky top-0 z-20` acima do grid, com `backgroundColor: {color}15` e `borderColor: {color}`: `Aplicando: [SealBadge md] — clique nas linhas para aplicar/remover (ESC para sair)` e um botão `Sair do modo` (`X`).
3. **Marcar** — clicar numa linha chama `handleRowClickInSealMode(contactId, alreadyApplied)`: aplica ou remove via `useApplySeal`/`useRemoveSeal`, com toast ("Selo aplicado" / "Selo removido", descrição `"{nome}" aplicado ao contato.`). O clique **não** abre a ficha.
4. **Sair** — botão da faixa **ou** tecla **ESC** (listener global registrado enquanto há selo ativo).

Realce visual das linhas no modo: descrito em §6.9.

O `OverflowBadgeList` e o `HelpTip` fazem `stopPropagation` justamente para não aplicar selo por acidente ao clicar em "+N" ou no "?".

### 10.6 Onde os selos aparecem

| Local | Escopo | Interativo? |
|---|---|---|
| Coluna "Selos" do grid | contact | **não** (read-only, `SealsCellReadonly`, até 2 + "+N") |
| Cabeçalho da ficha | contact | sim (badges removíveis + picker) |
| Card de contrato (Visão Geral) | contract | sim (`ContractSealsCell`) |
| Card de título (Visão Geral) | title | sim (`TitleSealsCell`) |
| Aba Suprimentos | — | **não há** |

---

## 11. Ação manual (`ManualActionDialog`)

Arquivo: `src/components/portfolio/detail/ManualActionDialog.tsx` (1.381 linhas). Hook: `src/hooks/useManualAction.ts`. É o formulário mais complexo do domínio.

### 11.1 Identidade

| Item | Valor |
|---|---|
| Gatilho | botão **Nova Ação** no topo da ficha do contato (requer `actions:write`) |
| Container | `DialogContent` `sm:w-[640px] sm:max-w-[640px] h-[85vh] flex flex-col gap-0 p-0 overflow-hidden` |
| Header | `Send` + "Enviar Ação Manual", `px-6 pt-6 pb-4 border-b`, `shrink-0` |
| Corpo | `ScrollArea flex-1 min-h-0` → `div.px-6.py-4.space-y-4` |
| Rodapé | `DialogFooter` fixo `px-6 py-4 border-t`; em mobile empilha invertido (`flex-col-reverse`) |
| Props | `contactId` (obrigatório), `open`, `onClose`, `contact?: {name, document}` (só para o header de contexto) |

### 11.2 Máquina de estados do rodapé

O diálogo tem **3 fases** e o rodapé muda inteiramente:

| Fase | Condição | Botão esquerdo | Botão direito |
|---|---|---|---|
| **Edição** | sem `preview` e sem `result` | `Cancelar` (outline, `disabled` durante o preview) | `Pré-visualizar` (`Eye`; `disabled` se `!canSend`; vira `Gerando...` com `Loader2`) |
| **Confirmação** | com `preview`, sem `result` | `Voltar` (descarta o preview) | `Confirmar Envio` (`Send`; **`disabled` se `!preview.would_send`**; vira `Enviando...`) |
| **Resultado** | com `result` | `Fechar` | `Enviar outra` (`Send`) |

**Invalidação do preview:** um `useEffect` zera `preview` e `previewError` sempre que muda qualquer um de: `actionLevel`, `selectedTitleId`, `selectedContractId`, `selectedIntegrationId`, `phone`, `email`, `subject`, `content`, `selectedMetaTemplate`, `templateVarMap`, `respectBlocklist`. Ou seja, **nunca** se confirma sobre um `would_send` obsoleto.

**Auto-scroll:** quando o preview aparece, um `setTimeout(50ms)` faz `scrollIntoView({behavior:"smooth", block:"start"})` no card — ele fica abaixo da dobra e passava despercebido.

### 11.3 Bloco 0 — Contexto

#### 11.3.1 `ContactContextHeader`

```
┌────────────────────────────────────────────────────────┐
│ Nome do Cliente Ltda                 EM ABERTO   [D+45]│
│ 12.345.678/0001-90                  R$ 12.345,67       │
└────────────────────────────────────────────────────────┘
```

- `rounded-md border bg-muted/30 px-3 py-2.5`;
- nome (`text-sm font-semibold truncate`) e documento (`text-xs font-mono muted`, formatado por comprimento);
- à direita: rótulo "EM ABERTO" (`text-[10px] uppercase tracking-wide`) + soma `getSafeValue(current, original)` de **todos** os títulos elegíveis;
- badge de dias: `D{n}` quando `<= 0`, `D+{n}` quando `> 0`, com escala de cor por faixa:

| Faixa | Classe |
|---|---|
| `<= 0` | `bg-blue-100 text-blue-800` |
| `1..15` | `bg-yellow-100 text-yellow-800` |
| `16..30` | `bg-orange-100 text-orange-800` |
| `31..60` | `bg-red-100 text-red-800` |
| `> 60` | `bg-red-200 text-red-900` |

#### 11.3.2 `RecentActionsSection`

`Collapsible` **fechado por padrão**, dentro de `rounded-md border`.

- Gatilho: ícone `History` + "Ações recentes" + `Badge` com a contagem + chevron.
- Conteúdo: `max-h-48 overflow-y-auto border-t px-3 py-2`. Uma linha por ação (até **10**, `useContactRecentActions`): badge do canal (cor de `INTEGRATION_TYPES`) · rótulo de status (`getActionStatusLabel`) · à direita "Campanha"/"Manual" e `created_at` em `toLocaleString("pt-BR")`.
- Carregando: `Loader2`. Vazio: "Nenhuma ação anterior para este contato."

### 11.4 Bloco 1 — Nível e alvo

**Toggle "Nível"** (par de botões dentro de `rounded-md border overflow-hidden`):

| Botão | Ícone | Estado ativo | `disabled` quando |
|---|---|---|---|
| **Título** | `FileText` | `bg-primary text-primary-foreground` | `contactData.titles.length === 0` |
| **Contrato** | `FolderOpen` | idem | `contactData.contracts.length === 0` |

Trocar para "Título" limpa `selectedContractId`; trocar para "Contrato" limpa `selectedTitleId` e, se nada escolhido, seleciona o **primeiro contrato** da lista.

**Auto-comportamentos:**
- se não há títulos mas há contratos, a UI **muda sozinha** para o nível Contrato e pré-seleciona o primeiro;
- se há títulos e nada selecionado, seleciona o **primeiro** (a lista vem ordenada por `days_overdue` desc → o mais atrasado);
- telefone e e-mail são pré-preenchidos com os principais do contato.

**Seletor de Título** (`Select`), visível no nível Título com ≥1 título:
- valor selecionado no trigger: número do título + badge `D±n` colorido + número do contrato em muted;
- cada item: linha 1 = número + badge de dias; linha 2 (xs muted) = `Contrato: {n}` · `Venc: {dd/MM/yyyy}` · `{valor BRL}`.
- Fonte dos títulos: `vw_titles_live`, `is_paid = false`, `entity_kind = 'contract'`, `removed_at IS NULL`, ordenado por `days_overdue` desc. **Suprimento não entra** na ação manual no v1.

**Seletor de Contrato** (`Select`), no nível Contrato:
- trigger: número + modalidade + badge de status + valor pendente;
- item: linha 1 = número + modalidade + badge de status; linha 2 = `Pendente: {BRL}` · `Total: {BRL}`;
- ordenado por `pending_value` desc.

**Avisos deste bloco:**

| Situação | Render |
|---|---|
| Nível Título, 0 títulos | `Alert` com `Info`: "Este contato não possui títulos ativos. Use o modo **Contrato** para enviar ações." |
| Nível Contrato, contrato sem títulos ativos | linha xs muted com `Info`: "Este contrato não possui títulos ativos — variáveis de título não serão preenchidas." |
| Nível Contrato, 0 contratos | `Alert variant="destructive"`: "Este contato não possui contratos." |

### 11.5 Bloco 2 — Tipo de ação (canal)

`Select` "Tipo de Ação" (`data-testid="manual-action-type-trigger"`), com as **categorias distintas das integrações ativas** da org (`useIntegrations({isActive:true})`). Cada item mostra um `Badge` colorido com o rótulo de `INTEGRATION_TYPES` seguido do próprio rótulo.

Ao trocar o tipo: se a categoria tem **exatamente uma** integração, ela é auto-selecionada; senão zera. Também zera `selectedMetaTemplate`, `templateVarMap` e `result`.

### 11.6 Bloco 3 — Integração

`Select` "Integração" (`data-testid="manual-action-integration-trigger"`) — **só aparece quando o tipo tem mais de uma integração**. Itens: `int.name`. Trocar zera template/mapa/resultado.

Derivados a partir da integração escolhida:

```ts
channel     = selectedIntegration?.category
showPhone   = ["whatsapp","rcs","sms","voice"].includes(channel)
showEmail   = channel === "email"
showSubject = channel === "email"
isMessaging = ["whatsapp","email","rcs","sms","voice"].includes(channel)
```

### 11.7 Bloco 4 — Configuração (só com integração **e** alvo escolhidos)

Precedido de um `Separator`. Na ordem:

#### 11.7.1 Aviso de duplicidade (não-bloqueante)

`Alert` âmbar (`border-amber-200 bg-amber-50`) com `AlertTriangle`:
> "Já houve um envio por {Canal} para este contato nas últimas 24h ({data/hora})."

Critério local: alguma ação recente no **mesmo canal** dentro de `DUPLICATE_WINDOW_MS = 24h`. É independente do `duplicate_warning` do preview (que é a checagem autoritativa server-side).

#### 11.7.2 Override de blocklist (só `actions:override_blocklist`)

Bloco `rounded-md border px-3 py-2.5`:

| Elemento | Detalhe |
|---|---|
| Label | "Respeitar blocklist deste contato" (clicável, `htmlFor="respect-blocklist"`) |
| Texto de apoio | "Desative para forçar o envio mesmo se o contato estiver bloqueado." |
| Controle | `Switch`, **default ligado** (`respectBlocklist = true`) |
| Ao desligar | aparece `Alert variant="destructive"` com `ShieldAlert`: "Você está forçando o envio ignorando a blocklist. Esta ação será auditada." |

No envio, `overrideBlocklist = !respectBlocklist` vai para o corpo da EF **e** para `source_detail` da ação (`blocklist_overridden`, `overridden_by`, `overridden_at`), alimentando o trigger de auditoria.

#### 11.7.3 Destinatário

| Campo | Condição | Detalhe |
|---|---|---|
| **Telefone** | `showPhone` | `Input` simples; placeholder = telefone do contato ou "Sem telefone" |
| **E-mail** | `showEmail` | `Input`; placeholder = e-mail do contato ou "Sem email" |

Ambos são **editáveis** — o valor digitado vira `recipient_override`.

#### 11.7.4 Template Meta (só canal `whatsapp` e só se há templates)

| Elemento | Detalhe |
|---|---|
| Label | ícone `MessageSquare` + "Template Meta (opcional)" |
| Gatilho | `Button outline role="combobox"` full-width; quando há template: badge verde "Meta" + nome; senão texto muted "Nenhum template (envio livre)" |
| Popover | 360px, `Command` com `CommandInput "Buscar template..."` |
| Itens | primeiro `Nenhum template (envio livre)`; depois **só templates com `meta_status === "APPROVED"`**, cada um com nome + categoria em xs muted; `Check` marca o selecionado |
| Vazio | "Nenhum template Meta encontrado" |
| Ao selecionar | extrai as variáveis `{{1}}`, `{{2}}`… do texto de todos os `meta_components` e inicializa `templateVarMap` com strings vazias |
| Mapeador | quando há variáveis, renderiza `MetaVariableMapper` (componente compartilhado das réguas) recebendo `variables`, `examples` (extraídos do `example.body_text[0]` do componente BODY), `value`, `onChange` |

#### 11.7.5 Assunto (só e-mail)

`InputWithVariables` — input com suporte a inserção de variáveis `{{...}}`; placeholder "Assunto do email".

#### 11.7.6 Conteúdo

`RichVariableInput` (`variableContext="integration"`, `rows={3}`, `compact`). Label: `Conteúdo` + `(opcional)` quando **não** é canal de mensageria. Placeholders:
- mensageria: "Conteúdo da mensagem (opcional, usa template da integração se vazio)";
- demais: "Conteúdo do payload (opcional)".

### 11.8 Bloco 5 — Pré-visualização (dry-run)

Gatilho: botão **Pré-visualizar**, que monta os parâmetros (`buildParams()`) e chama `usePreviewManualAction` → invoca a Edge Function `send-message` com `preview: true` (sem `action_id`, **sem gravar nada**).

Validação de contrato no hook: se a resposta não tiver `preview === true` e `blocklist` preenchido, **lança** erro explicando que a EF pode estar desatualizada (evita tela branca).

`canSend` = integração escolhida **e** (título escolhido, no nível título | contrato escolhido, no nível contrato) **e** não está enviando.

#### 11.8.1 Card de preview

```
┌ 👁 Pré-visualização ───────────────────────────────────┐
│ Destinatário          │ Canal                          │
│ 5511999998888         │ WhatsApp · Blips Oficial       │
│ ┌ [MessagePreview — a mensagem como o cliente verá] ─┐ │
│ └────────────────────────────────────────────────────┘ │
│ ┌ bg-muted/20 ───────────────────────────────────────┐ │
│ │ RESULTADO DA VERIFICAÇÃO      [Pronto para enviar] │ │
│ │ Link de pagamento: https://…                       │ │
│ │ O QUE VAI ACONTECER                                │ │
│ │  ✓ Não está na blocklist                           │ │
│ │  ✓ Título ativo                                    │ │
│ │  ⚠ Já foi enviado um WhatsApp nas últimas 24h (…)  │ │
│ │ [Alert de bloqueio, se would_send = false]         │ │
│ │ › Ver dados enviados à integração                  │ │
│ └────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

| Bloco | Detalhe |
|---|---|
| Título | `Eye` + "Pré-visualização"; `data-testid="manual-action-preview-card"` |
| Grade 2 col | **Destinatário** (em `text-destructive` quando nulo, texto "Sem destinatário") e **Canal** (`{rótulo do canal} · {nome da integração}`) |
| Herói | `MessagePreview` (compartilhado com o editor de réguas) recebendo `channel`, `resolved_message`, `resolved_subject`, `metaComponents` do template, `resolvedParams` do `meta_template`, `recipientLabel` e `contactName`. Renderiza HTML de e-mail e cards de WhatsApp/RCS como o cliente verá |
| Veredito | rótulo "RESULTADO DA VERIFICAÇÃO" + `Badge secondary "Pronto para enviar"` ou `Badge destructive "Não será enviado"` |
| Link de pagamento | quando `payment_link` existe: `<a target="_blank">` em `text-primary underline break-all` |
| Checklist | ver abaixo |
| Motivo do bloqueio | quando `!would_send`: `Alert destructive` com o texto de `getWouldSendBlockReason` |
| Raio-x | `Collapsible` fechado "Ver dados enviados à integração" → `OutboundRequestView` |

#### 11.8.2 Checklist "O que vai acontecer" (`buildPreviewChecklist`)

`data-testid="manual-action-checklist"`. Três tons: `ok` (`CheckCircle2` verde) · `bad` (`XCircle` destructive) · `warn` (`AlertTriangle` âmbar; texto `text-amber-800`).

| Ordem | Item | Tom | Texto |
|---|---|---|---|
| 1 | blocklist | `bad` se bloqueado e respeitando; `warn` se bloqueado e forçando; `ok` se livre | "Na blocklist" / "Na blocklist — será forçado (auditado)" / "Não está na blocklist" |
| 2 | título (quando há `title_status`) | `ok` se `actionable`; senão `bad` | "Título ativo" / "Título pago" / "Título removido" / "Título inativo" |
| 3 | duplicidade (quando há `duplicate_warning`) | `warn` | "Já foi enviado um {Canal} nas últimas 24h ({data/hora})" |
| 4..n | avisos extras do backend | `warn` | os `warnings` da EF, **deduplicados**: descarta os que contêm "blocklist", "título pago", "título removido", "ação semelhante"/"acao semelhante" — já viraram item dedicado |

#### 11.8.3 Motivo do bloqueio (`getWouldSendBlockReason`), em ordem de precedência

1. título não acionável → "Título pago — não é possível enviar." / "Título removido — …" / "Título inativo — …";
2. blocklist → com permissão de override: `Na blocklist — desative "Respeitar blocklist" para forçar o envio.`; sem: "Contato na blocklist — envio bloqueado.";
3. sem destinatário → "Sem destinatário — não é possível enviar.";
4. fallback → "Envio bloqueado por uma regra de segurança."

#### 11.8.4 Raio-x do payload (`OutboundRequestView`)

Só quando a EF devolve `outbound_request`.

| Tipo | Render |
|---|---|
| `kind: "provider"` | só a nota explicativa em xs muted (SDK do provedor, sem request reconstruível) |
| `kind: "webhook"` | bloco `rounded-md border bg-muted/10 p-2.5` com: **método** (`Badge outline` mono) + **URL** (mono, `break-all`) + botão **Copiar JSON** (vira "Copiado!" verde por 1,5 s); seção **Headers** (`bg-muted/40`, pares `nome: valor`); seção **Corpo** (`max-h-72 overflow-auto`, lista chave/valor alinhada à direita) |

**Classificação visual dos valores do corpo (`BodyValue`):**

| Classe | Detecção | Render |
|---|---|---|
| Variável não resolvida | contém `{{...}}` | âmbar + ícone `AlertTriangle`, `title="Variável sem valor — vai literal pro webhook"` |
| Vazio | `""` | `vazio` em itálico muted |
| Secret mascarado | contém `****` | muted + ícone `Lock` |
| Objeto | `typeof === object` | `JSON.stringify` em mono |
| Outros | — | `String(value)` em mono |

Headers seguem a mesma regra de mascaramento (cadeado).

### 11.9 Envio e resultado

`handleSend` só roda com `preview` presente. Sequência do hook `useSendManualAction`:

1. `supabase.auth.getUser()` — sem usuário, erro "Not authenticated";
2. **INSERT** em `actions` do schema da org, com: `contact_id`, `contract_id`, `title_id`, `campaign_id: null`, `integration_id`, `action_type = channel`, `channel`, `status: Pendente`, `processing_started_at`, `content`, `subject`, `source: "manual"`, `source_detail` (autoria + flags de override), `template_variable_map`, `metadata.meta_template_name`;
3. **invoke** da EF `send-message` com o corpo comum + `action_id` + `override_blocklist`;
4. **re-fetch** da ação (`status`, `recipient`, `error_message`);
5. devolve `{actionId, status, recipient, errorMessage, responseTime}` e invalida `["contact-actions", contactId]`.

**Banner de resultado** (`data-testid="manual-action-result"`), com 3 tons — `success` (`border-green-200 bg-green-50` + `CheckCircle2`), `warning` (`border-amber-200 bg-amber-50` + `AlertTriangle`), `error` (`Alert variant="destructive"` + `XCircle`):

| Ordem de decisão (`describeManualActionResult`) | Tom | Título | Detalhe |
|---|---|---|---|
| status `Cancelado (Pago)` | warning | rótulo de exibição do status | "O título já estava pago — a ação foi cancelada antes do envio." |
| status `Cancelado (Removido)` | warning | idem | "O título foi removido — a ação foi cancelada antes do envio." |
| status `Cancelado` **ou** mensagem contém "blocklist" | warning | "Bloqueado (blocklist)" | "O contato está na blocklist. A ação foi cancelada antes do envio." |
| sem `errorMessage` | success | rótulo do status ou "Enviado com sucesso" | — |
| com `errorMessage` | error | rótulo do status ou "Falha no envio" | a mensagem **real** (nunca mascarada como "Sem destinatário") |
| fallback | error | "Sem destinatário" | "Não foi possível identificar um destinatário válido para este canal." |

O banner mostra ainda: tempo de resposta (`{n}s`, 1 casa) quando `> 0`, e `Destinatário: {recipient}` quando existe.

**"Enviar outra"** reseta o formulário (mantendo o contato), repõe telefone/e-mail do cadastro, religa `respectBlocklist`, limpa preview/resultado e **invalida** `["contact-actions", contactId, "recent"]`.

### 11.10 Reset ao fechar

Ao `open` virar `false`, um efeito zera: nível (volta a `title`), título, contrato, tipo, integração, telefone, e-mail, assunto, conteúdo, resultado, template Meta, mapa de variáveis, preview, erro de preview e `respectBlocklist` (volta a `true`).

### 11.11 Avisos de negócio (do guia embarcado)

- **Sem trava de deduplicação/cooldown** — diferente das campanhas, a única trava é a blocklist. O aviso de duplicidade alerta, não impede.
- **Guarda de título pago/removido** — se no momento do envio o título já estiver pago/removido, a ação é cancelada antes de sair.
- **Guarda de tamanho (RCS)** — corpo resolvido acima de 3.000 caracteres não é enviado (`rcs.over_limit` no preview).
- **Nova Ação × Disparos** — 1 ação para 1 contato, feita da ficha; para uma lista inteira, a tela **Disparos**.

---

## 12. Wizards e modais de cadastro/edição

### 12.1 `PortfolioCreateWizard` — Novo Cadastro

Arquivo: `src/components/portfolio/PortfolioCreateWizard.tsx`.

| Item | Valor |
|---|---|
| Gatilho | botão **Novo Cadastro** (header, aba Contatos, `contacts:write`) |
| Container | `DialogContent max-w-3xl h-[90vh] flex flex-col overflow-hidden` |
| Título | ícone por passo em caixa `bg-primary/10` (`User` → `FileText` → `Receipt`) + "Novo Cadastro" |
| Descrição | "Preencha os dados seguindo a hierarquia: Contato → Contrato → Títulos" |
| Stepper | `WizardStepper` (compartilhado com os wizards de ETL) numa faixa `px-4 py-3 border-b` |
| Corpo | `ScrollArea flex-1 px-6` |
| Navegação | `WizardNavigation` com `nextLabel="Continuar"` e `submitLabel="Finalizar Cadastro"` |

**Passos:** 1 "Contato — Dados do cliente" · 2 "Contrato — Informações do contrato" · 3 "Títulos — Parcelas e vencimentos".

**Regra arquitetural importante:** os passos 1 e 2 **não gravam nada**. Tudo é coletado no estado e gravado **de uma vez**, no submit final, pela RPC transacional `create_manual_client` (`p_schema_name`, `p_contact`, `p_contract`, `p_titles`). Isso elimina contato/contrato órfãos e colisão de documento ao reabrir.

#### 12.1.1 Passo 1 — Contato (`react-hook-form` + zod, `mode: "onChange"`)

| Campo | Controle | Validação | Default |
|---|---|---|---|
| Documento (CPF/CNPJ) | `Input`, placeholder `000.000.000-00` | `min(11)`, `max(18)` | `""` |
| Tipo | campo **read-only** (caixa `bg-muted` com ícone `User`/`Building2` e o texto CPF/CNPJ) | derivado: `>11` dígitos → `cnpj` | `cpf` |
| Nome / Razão Social | `Input` | `min(2, "Nome deve ter pelo menos 2 caracteres")` | `""` |
| Nome Fantasia (opcional) | `Input` | — | `""` |
| Telefones (array) | por linha: `Input` + `<select>` nativo (Celular / WhatsApp / Fixo) + `Trash2` (só se >1) | cada telefone `min(10, "Telefone inválido")` | 1 linha vazia, tipo `mobile` |
| Emails (array) | por linha: `Input type=email` + `<select>` (Pessoal / Trabalho) + `Trash2` (só se >1) | `.email("Email inválido")` | 1 linha vazia, tipo `personal` |

Botões "Adicionar" (ghost, `Plus`) por seção. Ícones de seção `Phone` e `Mail`. Mensagens de erro em `text-sm text-destructive` sob o campo.

#### 12.1.2 Passo 2 — Contrato

Começa com um **resumo do contato** (caixa `bg-muted/30` com `Check` + nome e documento).

| Campo | Controle | Validação | Default |
|---|---|---|---|
| Número do Contrato | `Input`, placeholder `CTR-2024-001` | obrigatório | `""` |
| Modalidade | `Input`, placeholder "Ex: Locação, Venda" | obrigatória | `""` |
| Status | `<select>` nativo full-width | enum | `active` |
| Data de Início | `Input type=date` | opcional | **hoje** |
| Data de Término (opcional) | `Input type=date` | opcional | `""` |
| Valor Total | `Input type=number step=0.01` | `min(0)` | `0` |

Opções de status: Ativo (`active`) · Concluído (`completed`) · Cancelado (`cancelled`) · Inadimplente (`defaulted`).

#### 12.1.3 Passo 3 — Títulos

Resumo de contato **e** contrato no topo (duas linhas com `Check`).

Cabeçalho da lista: ícone `Receipt` + "Títulos / Parcelas" + `Badge` com a quantidade + botão outline "Adicionar Título".

Cada título é um card `p-4 border rounded-lg` com "Título {n}" e `Trash2` (só se houver >1), e **6 campos** em duas linhas de 3:

| Campo | Tipo | Default ao adicionar |
|---|---|---|
| Número do Título | texto (`TIT-001`) | `""` |
| Parcela | número `min=1` | `último + 1` |
| Total Parcelas | número `min=1` | herdado do anterior |
| Vencimento | `date` | `""` |
| Valor Original | número `step=0.01` | herdado |
| Valor Atual | número `step=0.01` | herdado |

**Gate do passo 3:** `titles.length > 0 && todos têm title_number, due_date e original_value > 0`. Quando não atendido, aparece o texto: "É obrigatório ao menos um título. Preencha número, vencimento e valor original (maior que zero) para finalizar o cadastro."

#### 12.1.4 Submit

Revalida os dois forms; se o passo 3 não passa, toast destrutivo "Adicione ao menos um título". Sem organização ativa, toast "Organização não disponível".

Em caso de sucesso: invalida 8 query keys da carteira e mostra o toast:
> **"Cliente cadastrado com sucesso!"** — "Ele aparecerá na Carteira no próximo ciclo de atualização (a materialização roda por agendamento; se estiver pausada, reative na aba Materialização)."

Erro: `logError` (severity high) + toast destrutivo "Erro ao cadastrar cliente" com a mensagem real.

Fechar reseta tudo (passo 1, títulos para 1 linha vazia, ambos os forms).

### 12.2 `PortfolioEditDialog` — Editar Cadastro

Arquivo: `src/components/portfolio/PortfolioEditDialog.tsx` (931 linhas). Gatilhos: ação "Editar" da linha do grid **e** botão de lápis no cabeçalho da ficha.

| Item | Valor |
|---|---|
| Container | `w-[95vw] max-w-4xl h-[90vh] max-h-[90vh] p-0 flex flex-col` |
| Header | caixa `bg-primary/10` com `Pencil` + "Editar Cadastro" + descrição `{nome} • {documento formatado}` |
| Abas | `Contato` (`User`) · `Contratos (N)` (`FileText`) · `Títulos (N)` (`Receipt`) — `TabsList` 3 colunas |
| Aba inicial | prop `initialTab` (default `contact`); resetada a cada abertura |
| Corpo | `ScrollArea flex-1 px-6 pb-6` |

#### 12.2.1 Aba Contato (`ContactEditForm`)

Seções: **Dados Básicos** · **Telefones** · **E-mails** · **Campos Personalizados**.

| Campo | Controle | Obrigatório |
|---|---|---|
| Nome / Razão Social * | `Input` | sim (`required` do RHF) |
| Nome Fantasia | `Input` | não |
| Documento (CPF/CNPJ) | `Input` | não |
| Tipo de Documento | `Select` (CPF / CNPJ) | — |
| Telefones[] | `Input` + `Select` (Celular/Fixo/WhatsApp) + `Checkbox "WA"` (`is_whatsapp`) + `Trash2` | — |
| E-mails[] | `Input type=email` + `Select` (Pessoal/Trabalho) + `Trash2` | — |
| Campos personalizados | `DynamicFieldInput` por definição de `contacts`, em grade de 2 colunas | conforme `is_required` |

Estado vazio das listas: "Nenhum telefone cadastrado" / "Nenhum e-mail cadastrado". Botões "Adicionar" outline com `Plus`.

Preenchimento: usa `contact.phones/emails` quando disponíveis (`ContactWithDetails`); caindo para `primary_phone`/`primary_email` (`ContactEnriched`). Ao salvar, telefones/e-mails em branco são filtrados.

Rodapé do form: "Cancelar" + "Salvar Contato" (→ "Salvando..."). Sucesso: toast "Contato atualizado / Os dados foram salvos com sucesso." e fecha o diálogo. Erro: `logError` + toast destrutivo.

#### 12.2.2 Aba Contratos

**Lista** (`ContractsListView`): texto de apoio "Clique em um contrato para editar seus dados"; cada contrato é um card clicável com ícone `FileText`, número (font-medium), `{modalidade || "Sem modalidade"} • {valor total}`, `Badge` de status (`default` quando `active`) e ícone de lápis. Vazio: `FileText` 48px + "Nenhum contrato encontrado". Carregando: 2 `Skeleton h-20`.

**Form inline** (`ContractEditForm`, substitui a lista): cabeçalho `← Voltar` + `Editar Contrato: {número}`; campos Número * · Modalidade · Status (`Select`: Ativo/Quitado/Cancelado/Inadimplente) · Valor Total (number) · Carteira (texto, full-width) + custom fields de `contracts`. Rodapé "Cancelar" / "Salvar Contrato".

#### 12.2.3 Aba Títulos

**Lista** (`TitlesListView`): cada título é card clicável com `Receipt`, número, `Venc: {data} • {valor}` e badge de status com cores locais (`paid` verde, `pending` amarelo, `cancelled` cinza, outros azul) e rótulos locais (Pago/Pendente/Parcial/Cancelado/Negociado). Vazio: `Receipt` + "Nenhum título encontrado". Carregando: 3 `Skeleton h-16`.

**Form inline** (`TitleEditForm`): Número * · Status (`Select`: Pendente/Pago/Parcial/Cancelado/Negociado) · Valor Original · Valor Atual · Valor Pago · Juros · Multa (todos number `step=0.01`) + custom fields de `titles`.

⚠️ Inconsistência: esta lista/edição usa os status **legados em inglês** (`pending`, `paid`, `partial`, `cancelled`, `negotiated`), enquanto o resto da tela usa os canônicos em português (`Disponivel`, `Pago`, `Removido`…). Ver §17.

### 12.3 `ContractEditDialog`

Arquivo: `src/components/portfolio/ContractEditDialog.tsx`. Gatilho: lápis no card de contrato da **Visão Geral** (requer `contracts:write`).

| Item | Valor |
|---|---|
| Container | `max-w-xl max-h-[90vh] overflow-y-auto` |
| Título | `FileText` + "Editar Contrato" |
| Topo do corpo | **`BlocklistActiveCard targetType="contract"`** — mostra bloqueios ativos do contrato antes dos campos |
| Campos | Número do Contrato * (erro "Obrigatório") · Modalidade · Status (`Select` com 4 opções) · Valor Total (number) · Carteira (full-width) |
| Custom fields | seção "Campos Personalizados" (ícone `Puzzle`) com `DynamicFieldInput` em grade 2 col; enquanto carrega: "Carregando campos personalizados..." |
| Rodapé | "Cancelar" / "Salvar" (→ "Salvando...") |
| Toasts | "Contrato atualizado / Os dados foram salvos com sucesso." · destrutivo "Erro ao atualizar / Não foi possível salvar as alterações." |

Reset: `useEffect` repovoa o form sempre que `contract` ou `open` mudam.

### 12.4 `TitleEditDialog`

Mesma anatomia do anterior. Título: `Receipt` + "Editar Título". Topo: `BlocklistActiveCard targetType="title"`.

Campos: Número do Título * · Status (`Select` — Pendente/Pago/Parcial/Cancelado/Negociado) · Valor Original · Valor Atual · Valor Pago · Juros · Multa. Todos os numéricos `type=number step=0.01` placeholder `0,00`. Depois, custom fields de `titles`.

### 12.5 `SupplyEditDialog`

Título: `Package` + "Editar Suprimento". Topo: `BlocklistActiveCard targetType="supply"`.

| Campo | Controle | Observação |
|---|---|---|
| Número do Suprimento * | `Input` | erro "Obrigatório" |
| Status | **`Input` de texto livre** (placeholder "Ex: active") | ⚠️ não é `Select` — inconsistente com contrato |
| Valor Total | `Input number step=0.01`, full-width | — |
| Campos personalizados | `supplies` | — |

### 12.6 `SupplyTitleEditDialog`

Título: `Receipt` + "Editar Parcela de Suprimento". Topo: `BlocklistActiveCard targetType="supply_title"`.

Campos: Número da Parcela * (`SUP-TIT-001`) · **Status como `Input` de texto** (placeholder "Ex: Disponivel", default `"Removido"`) · Valor Original · Valor Atual · Valor Pago · Juros · Multa + custom fields de `supply_titles`.

⚠️ O default `"Removido"` para status de parcela nova é surpreendente na UI — vem do padrão do ETL (regra 12 do projeto). A confirmar se deve continuar visível como texto editável.

### 12.7 `DeleteContactDialog`

Arquivo: `src/components/portfolio/DeleteContactDialog.tsx`. **Único `AlertDialog` destrutivo do fluxo de contato.**

```
┌ ⚠ Confirmar Exclusão ──────────────────────────────┐
│ Tem certeza que deseja excluir o contato **Nome**? │
│ ┌ bg-muted p-3 ────────────────────────────────┐   │
│ │ Nome: …                                      │   │
│ │ Documento: …                                 │   │
│ │ Contratos: N          (só se > 0)            │   │
│ └──────────────────────────────────────────────┘   │
│ Esta ação não pode ser desfeita. Todos os dados    │
│ relacionados serão permanentemente removidos.      │
│                       [Cancelar] [Excluir Contato] │
└────────────────────────────────────────────────────┘
```

- Título com `AlertTriangle` em `text-destructive`.
- Aviso final em `text-destructive font-medium`.
- Botão de ação com classe destrutiva; texto vira "Excluindo..." durante a mutation; ambos os botões ficam `disabled`.
- **Sem digitação de confirmação** (não pede o nome do cliente).
- **Não mostra toast de erro próprio** de propósito: o `onError` de `useDeleteContact` já exibe a mensagem real (FK em uso, timeout 57014, sessão, permissão) e `useToast` tem `TOAST_LIMIT = 1` — um toast genérico aqui substituiria o diagnóstico.

### 12.8 `DynamicFieldInput`

Arquivo: `src/components/portfolio/DynamicFieldInput.tsx`. Renderiza o input adequado ao `field_type` de um custom field. Label com o `display_name` e asterisco `*` em destructive quando `is_required`. Erro em `text-xs text-destructive` abaixo.

| `field_type` | Controle | Detalhes |
|---|---|---|
| `text` (e default) | `Input` | placeholder `Digite {rótulo minúsculo}`; borda destructive em erro |
| `number` | `Input type=number` | `""` → `null`; `NaN` → `null` |
| `date` | `DateInput` próprio | `Input` mascarado **DD/MM/AAAA** (`maxLength=10`) + botão de calendário que abre um popover com o texto "Use o formato DD/MM/AAAA" (⚠️ **não há calendário real**); grava em `yyyy-MM-dd` quando o texto tem 10 caracteres e é válido |
| `boolean` | `Switch` + texto "Sim"/"Não" ao lado | usa `parseBooleanValue` |
| `select` | `Select` com `field.options` | placeholder "Selecione..." |
| `multi_select` | `MultiSelectInput` próprio: caixa com borda e uma linha `<label><input type=checkbox> opção</label>` por opção | vazio: "Nenhuma opção disponível" |

### 12.9 Diálogos legados (fora do fluxo atual)

| Arquivo | O que é | Status na tela |
|---|---|---|
| `src/components/contacts/ContactDetailDialog.tsx` | Detalhe read-only de contato (cards: Informações Básicas, Telefones, Emails, Campos Customizados, metadados) em `w-[95vw] h-[95vh]` | **não usado** por `/portfolio` — substituído pelo `ContactDetailSheet` |
| `src/components/contacts/ContactDialog.tsx` | Criar/editar contato com **tags** (input + Enter, chips removíveis), telefones e e-mails | **não usado** por `/portfolio` |
| `src/components/contracts/ContractDetailDialog.tsx` | Detalhe de contrato com resumo financeiro em 4 cards (Total/Pago/Pendente/Vencido), tabela de títulos e botão **"Baixar"** (marcar título como pago, `useMarkTitleAsPaid`) | **não usado** por `/portfolio` |
| `src/components/contracts/ContractDialog.tsx` | Criar/editar contrato com **busca de cliente** (`useCustomerSearch` + debounce 300ms) | **não usado** por `/portfolio` |

⚠️ A confirmar: se ainda são montados por outras telas. Se não forem, são candidatos a remoção — e a funcionalidade "Baixar título" (marcar como pago pela UI) **não existe** hoje na Gestão de Carteira, o que é uma lacuna relevante para o redesign.

---

## 13. Ações em massa e exportações

### 13.1 O que existe hoje de "em massa"

| Fluxo | Onde | Alcance | Observação |
|---|---|---|---|
| **Modo Aplicar Selo** | grid, aba Contatos | clique a clique, sem limite | é a única ação em massa sobre contatos — e não usa a seleção por checkbox |
| **Exportar Selecionados** | header | as linhas marcadas | client-side |
| **Exportar Página Atual** | header | a página visível | client-side |
| **Exportar Toda a Base** | header | todo o recorte filtrado | Edge Function |
| **Bloquear em massa** | aba Blocklist | lista colada | RPC transacional |
| **Liberar em massa** | aba Blocklist | lista colada | RPC transacional |
| **Exportar histórico** | ficha → Histórico | todos os disparos de 1 cliente | Edge Function compartilhada com a tela de Ações |

**Não existe:** barra de ações em massa sobre a seleção do grid (atribuir operador em lote, bloquear em lote a partir da seleção, excluir em lote, aplicar selo à seleção). A seleção por checkbox serve **apenas** à exportação.

### 13.2 Menu Exportar

`DropdownMenu align="end"`, gatilho `Button variant="outline"` com `Download` (rótulo "Exportar" some em `<sm`), `disabled` durante `exportMutation.isPending`.

| Item | Condição | Implementação | Nome do arquivo |
|---|---|---|---|
| `Exportar Selecionados (N)` | só se `selectedIds.length > 0` | client-side | `carteira_selecionados_{YYYY-MM-DD}.csv` |
| `Exportar Página Atual` | sempre | client-side | `carteira_pagina_{YYYY-MM-DD}.csv` |
| `Exportar Toda a Base ({total})` | sempre | EF `export-portfolio` | `carteira_completa_{YYYY-MM-DD}.csv` |

### 13.3 CSV client-side (selecionados / página)

Gerado por `exportContactsClientSide` em `PortfolioManagementPage.tsx`. **1 linha por contato** — bate exatamente com o grid. Encoding: `Blob` com BOM (`﻿`) e `text/csv;charset=utf-8;`. Separador `,`; todos os campos entre aspas com escape de `"` duplicado; números com 2 casas e **vírgula decimal**.

Colunas (13, nesta ordem):

```
contato_documento, contato_tipo_documento, contato_nome, contato_telefone,
contato_email, total_contratos, total_titulos, titulos_em_aberto,
titulos_vencidos, valor_total, valor_pago, valor_pendente, max_dias_atraso
```

Se não houver dados: toast destrutivo "Nenhum dado para exportar". Sucesso: toast "Exportação concluída — {N} contatos exportados."

### 13.4 Exportação server-side (toda a base)

`useExportPortfolio` → `orgClient.functions.invoke("export-portfolio")`. O corpo envia os **filtros** (não os ids), com a mesma degradação single/multi das RPCs:

```
portfolio_id / filter_id          (quando há exatamente 1)
portfolio_ids / filter_ids        (quando há ≥2)
portfolio_combinator / filter_combinator   (só quando multi e ≠ default)
workflow_ids / workflows_logic / include_no_workflow
search, assigned_user_id
action_contact_ids / action_exclude_contact_ids
```

Conteúdo (segundo o guia de negócio): além de documento/tipo/nome, traz **nome fantasia**, **todos** os telefones e e-mails (não só os principais), as mesmas contagens, os valores original/atualizado/pago (**não há** coluna "pendente") e **uma coluna por campo personalizado do contato**.

Falha: toast destrutivo "Erro na exportação — Não foi possível exportar os dados."

### 13.5 Exportar histórico do cliente

`ContactHistoryExportButton` → `ReportExportDialog` (compartilhado com a tela de Ações) → `useActionsExport` → mesma EF e mesmo renderizador do relatório de Ações, com `contactId` no recorte.

| Opção | Valores |
|---|---|
| Formato | **HTML** (abre nova aba navegável) ou **PDF** (versão de impressão; "Salvar como PDF" no navegador) |
| Visibilidade | **Dados protegidos** (padrão — documento e destinatário parcialmente ocultos) ou **Dados completos** (exige marcar uma confirmação de necessidade; a escolha vai para auditoria) |
| Nota de população | "Inclui todos os disparos do cliente no recorte, do mais antigo para o mais recente." |
| Limite | 20.000 registros; acima disso a operação **informa o problema** em vez de entregar parte |

### 13.6 Blocklist em massa (`BlocklistBulkDialog`)

**Um único componente serve bloquear e liberar** (prop `kind: "block" | "exception"`), porque o fluxo é o mesmo: esfera → colar → resolver → relatório → motivo/prazo/observações → confirmar com a contagem. O `key={bulkDialogKind}` força remount ao alternar.

| | `block` | `exception` |
|---|---|---|
| Título | "Bloquear em massa" (`Ban`) | "Liberar em massa (passe livre)" (`KeyRound`) |
| Descrição | "Cole a lista de alvos, escolha o motivo e o prazo. Todos entram na blocklist de uma vez." | "Cole a lista de alvos que devem deixar de ser bloqueados. O bloqueio não é apagado: ele fica registrado e volta a valer quando o passe livre vencer ou for removido." |
| Alerta inicial | — | `Alert destructive`: "O passe livre vence bloqueios de **qualquer origem** — inclusive manuais como **Óbito** e **Processo Judicial**. Liberar um contato libera também os contratos e títulos dele." |
| Catálogo de motivos | `BLOCKLIST_REASONS` | `BLOCKLIST_EXCEPTION_REASONS` |
| Botão de confirmar | `variant="destructive"` | `variant="default"` |

**Campos, na ordem:**

1. **Esfera** (`RadioGroup` horizontal): Contato · Contrato · **Suprimento** (só com `hasSupply`) · Email · Telefone. Nota abaixo: "Título e parcela de suprimento não entram na lista colada: o número deles só é único dentro do contrato/suprimento. Use o bloqueio unitário para esses dois."
2. **Colar lista** (`PastedListResolver`) — título `Colar lista ({chave} — um por linha)`, `Textarea` mono de 4 linhas com placeholder por esfera; botões **Resolver** (→ "Resolvendo...") e **Limpar**; badge no cabeçalho `"{N} alvo(s)"` quando resolvido.
3. **Escopo de canal** (`Select`) — **só na esfera Contato**: Todos os canais / Apenas Telefone / Apenas e-mail.
4. **Motivo** (`Select`) — obrigatório nos dois modos.
5. **Prazo** (`Input type=date`) — rótulo "Bloquear até (opcional)" ou "Passe livre até (opcional)". Texto de apoio explica que vazio = permanente e que a data vale até o fim do dia (BRT 23:59).
6. **Observações** (`Textarea` 2 linhas) — placeholder "Contexto para quem revisar depois (nº do chamado, quem pediu...)".

**Relatório da resolução** (`PastedListResolver`): caixa tracejada com `"{N} {unidade}(s) · {M} não encontrado(s)"`; quando `N = 0`, mensagem destacada ("Nenhum alvo encontrado nesta organização — nada será aplicado." ou "Nenhum endereço válido na lista."); os **não encontrados** saem por `OverflowBadgeList` (3 visíveis + "+N" clicável, mono, com nota de rodapé "Estes itens não existem no cadastro desta organização — confira digitação ou se pertencem a outra org.").

**Guardas de segurança (deliberadas):**
- o botão só habilita com `targetCount > 0` **e** motivo preenchido, e **mostra o número**: `Bloquear 175 alvo(s)`;
- editar o texto **invalida** a resolução (o número não pode descrever um texto que mudou);
- **trocar de esfera descarta** a resolução anterior (senão 300 documentos resolvidos viriam aplicados como alvos de contrato);
- reabrir sempre reseta tudo.

**Resultado:** aplicação transacional (`blocklist_bulk_apply`). Toasts:
- `applied > 0`: `"{N} alvo(s) aplicados"` + (se houver) `" · {M} já existiam."`;
- `applied === 0`: **"Nada novo a aplicar"** com `"{M} alvo(s) já estavam nessa condição."` ou "Nenhum alvo foi afetado.";
- erro: "Erro ao bloquear em massa" / "Erro ao liberar em massa" com a mensagem real.

---

## 14. Estados da tela

### 14.1 Matriz de estados

| Área | Loading | Vazio | Erro | Sem permissão |
|---|---|---|---|---|
| **KPIs** | 7 `Skeleton` (larguras variadas) | retorna `null` (barra some) | `role="alert"` destructive: "Não foi possível aplicar os filtros: {msg}" | n/a (todos veem) |
| **Grid** | skeleton de 7 col × 10 linhas | bloco central "Nenhum contato encontrado" + "Tente ajustar os filtros de busca" | acima do grid: "Falha ao consultar a carteira: {msg}" | botões de linha somem (Editar/Excluir) |
| **Grid, refetch** | overlay `bg-background/60` + `Loader2`, linhas a 50% de opacidade, `aria-busy` | — | — | — |
| **Barra de filtros** | selects desabilitados enquanto os catálogos carregam (`isLoadingUsers`, `isLoadingSteps`) | Step da régua desabilitado com tooltip "escolha uma régua primeiro" | `role="alert"`: "Não foi possível carregar todas as opções de filtro. Atualize a página." | controles opcionais não renderizam quando o handler não é passado |
| **Kanban** | "Carregando configuracao..." (buckets) · `Skeleton h-40` (resolvendo filtros) · 4 cards-esqueleto por coluna | por coluna: `Inbox` + "Nenhum contato/contrato em «faixa»" | board: "Não foi possível consultar o Kanban: {msg}" · coluna: "{faixa}: {msg}" | — |
| **Ficha — Visão Geral** | 2 `Skeleton h-16` (cascata) + 2 `Skeleton h-4` (contato) | "Nenhum contrato encontrado" | ⚠️ sem tratamento de erro visível | lápis de contrato/título some sem `contracts:write` |
| **Ficha — Informações** | `Skeleton h-9` + 3 × `h-32` | "Nenhuma informação corresponde a «termo»" | ⚠️ sem tratamento explícito | — |
| **Ficha — Suprimentos** | 2 `Skeleton h-16` | `Package` + "Nenhum suprimento encontrado" | ⚠️ sem tratamento | — |
| **Ficha — Histórico** | 3 `Skeleton h-20` | `Clock` + "Nenhuma interacao registrada" | drill-down: "Não foi possível carregar os detalhes da ação." | botão de exportar some sem `reports:export` |
| **Ficha — Bloqueios** | `Loader2` no card | "Nenhum bloqueio ativo para este contato." | ⚠️ sem tratamento | — |
| **Blocklist — entries/exceptions** | 5 linhas × N células `Skeleton h-4` | ícone + título + subtexto condicional a filtros | ⚠️ sem estado de erro na tabela (erro só aparece em toast de mutation) | 4 botões do header somem; lixeiras somem |
| **Blocklist — rules** | 3 linhas de skeleton | `Filter` + "Nenhuma regra de filtro" | erro de sync exibido na célula "Último sync" | menu de ações some |
| **Ação manual** | `Loader2` centralizado (dados do contato) · `Loader2` no botão (preview/envio) | "Nenhuma ação anterior para este contato." | `Alert destructive` "Não foi possível gerar a pré-visualização: {msg}" | o diálogo inteiro só existe com `actions:write`; o switch de override só com a permissão |

### 14.2 Estado especial: modo selo

Faixa `sticky top-0 z-20` entre a barra de KPIs e o grid, com fundo e borda na cor do selo. O clique na linha muda de significado (aplica/remove em vez de abrir a ficha). Saída por botão ou ESC. É o único **modo** (estado global que altera o significado da interação) da tela.

### 14.3 Estado "sem permissão"

Não existe tela/bloco de "sem permissão" — a tela é sempre acessível e os controles simplesmente **não renderizam**. Um `viewer` vê: header só com Atualizar, as 3 abas, a barra de filtros completa, KPIs, grid (com o menu de linha contendo só "Ver Detalhes"), rodapé, kanban e a blocklist em modo leitura. Na ficha, não vê Nova Ação, não pode trocar o operador, não vê lápis nem exportação.

---

## 15. Fluxos de uso passo a passo

### 15.1 Investigar um cliente que ligou (operador)

1. Digitar telefone/CPF no campo de **Busca** (dispara com debounce ou Enter).
2. O grid filtra; a barra de KPIs recalcula; a seleção é limpa; a página volta a 1; a URL ganha `?search=`.
3. Clicar na linha → abre a ficha (95vw × 95vh).
4. Ler os 6 StatCards e a cascata Contratos → Títulos; expandir o contrato e o título relevante para ver vencimento, encargos e **copiar a linha digitável / chave PIX**.
5. Trocar para **Informações** para confirmar identidade e copiar dados (busca por campo, botão copiar por valor).
6. Trocar para **Histórico** para ver o que já foi enviado; clicar num item para o drill-down.
7. Se for agir: **Nova Ação** → §15.4.

### 15.2 Recortar um público e exportar (supervisor)

1. Selecionar 2 carteiras; abrir o dropdown e alternar o combinador para **E** se quiser interseção.
2. Aplicar um filtro salvo (ou criar um na hora pelo botão `+` → `FilterBuilderDialog`; o filtro novo **soma** à seleção).
3. Opcional: restringir por **Régua** e, então, por **Step da régua**; ou por **Segmento**; ou por **Tipo de ação** + janela de **Ação**.
4. Conferir a linha de chips e os KPIs.
5. Ligar colunas extras no seletor **Colunas** (fica salvo no navegador).
6. Ordenar por "Valor Devido" desc.
7. **Exportar → Toda a Base (N)**.
8. Copiar a URL e enviar ao colega — ela reproduz o recorte.

### 15.3 Distribuir carteira entre operadores

1. Recortar a base (carteira/filtro).
2. Abrir a ficha de cada contato e escolher o **Operador** no seletor do topo.
3. Voltar à lista e usar o filtro **Operador** (ou o toggle **Meus contatos**) para conferir.

> Hoje **não há** atribuição em lote — é contato a contato. Ver §17.

### 15.4 Disparar uma ação manual

1. Ficha → **Nova Ação**.
2. Conferir o header de contexto (valor em aberto, D+n) e abrir "Ações recentes" se quiser checar duplicidade.
3. Escolher **Nível** (Título ou Contrato) e o alvo no select.
4. Escolher **Tipo de Ação**; se houver mais de uma integração, escolher a **Integração**.
5. Ajustar telefone/e-mail se preciso; escolher Template Meta (WhatsApp) e mapear as variáveis; preencher assunto (e-mail) e conteúdo.
6. (owner/admin) decidir sobre **Respeitar blocklist**.
7. **Pré-visualizar** → ler a mensagem renderizada, o veredito e o checklist; abrir o raio-x se quiser ver o payload.
8. **Confirmar Envio** (só habilita se `would_send`).
9. Ler o banner de resultado; **Enviar outra** ou **Fechar**.

### 15.5 Cadastrar cliente manualmente

1. **Novo Cadastro** → passo 1 (documento, nome, telefones, e-mails) → **Continuar**.
2. Passo 2 (contrato) → **Continuar**.
3. Passo 3 (ao menos 1 título com número, vencimento e valor > 0) → **Finalizar Cadastro**.
4. Ler o toast: o cliente aparece na Carteira **no próximo ciclo de materialização**.

### 15.6 Bloquear uma lista de 175 documentos

1. Aba **Blocklist** → **Bloquear em massa**.
2. Esfera **Contato**; colar 175 CPFs/CNPJs (um por linha) → **Resolver**.
3. Ler o relatório: `163 contato(s) · 12 não encontrado(s)` e abrir o "+N" para ver quais falharam.
4. Escolher escopo de canal (se aplicável), **Motivo**, prazo e observações.
5. Confirmar com o botão que mostra `Bloquear 163 alvo(s)`.
6. Ler o toast (aplicados × já existentes).

### 15.7 Liberar um alvo capturado por regra automática

1. Aba **Blocklist** → sub-aba **Bloqueios ativos** → localizar o alvo (a lixeira está desabilitada, porque a origem é `filter`).
2. **Liberar em massa** (ou, para um único alvo, colar só ele) → esfera correspondente → resolver → motivo (ex. "Negociação em andamento") → prazo → confirmar.
3. Voltar aos Bloqueios ativos: o alvo agora exibe o selo **"Desbloqueado por exceção"**; a linha de bloqueio **permanece**.
4. Para reverter, remover o passe na sub-aba **Desbloqueados** — os bloqueios voltam a valer imediatamente.

### 15.8 Criar uma regra de bloqueio automático

1. **Nova Regra** → nome e descrição.
2. **Nível do bloqueio**: Contatos / Contratos / Títulos.
3. **Filtro a usar**: escolher um filtro salvo (o select mostra `{nome} ({N} contatos)`); se não houver nenhum, um alerta manda criar na tela de Filtros.
4. **Prazo padrão das entradas geradas**: Permanente / 7 / 15 / 30 / 60 / 90 dias.
5. **Regra vale até** (opcional): data absoluta.
6. Criar. A regra entra em vigor no próximo sync (**até 16 minutos**).
7. Abrir o detalhe clicando na linha → ver "Bloqueados agora (N)" × "Filtro retorna (M)", o alerta de divergência e **Sincronizar agora**.

---

## 16. Responsividade e acessibilidade

### 16.1 Breakpoints em uso

Tailwind padrão; a tela usa quase só `sm` (640px) e `lg` (1024px); `xl` aparece na aba Informações.

| Área | `<sm` (mobile) | `sm..lg` | `≥lg` |
|---|---|---|---|
| Container da página | `-m-3` | `-m-6` | `-m-6` |
| Header | botões viram só ícone (rótulos com `hidden sm:inline`) | ícone + rótulo | idem |
| Barra de filtros | **colapsada** em `MobileCollapsibleFilters` (<768px): botão full-width "Filtros" com badge de contagem e chevron | expandida | expandida |
| KPIs | `flex-wrap` — quebra em várias linhas | idem | uma linha |
| Grid | scroll horizontal (`min-w-max`) — sem transformação em cards | idem | idem |
| Kanban | scroll horizontal; colunas fixas de 300px | idem | idem |
| Ficha do contato | `w-screen h-screen`, sem cantos | `95vw × 95vh` | idem |
| Ficha: abas + operador | empilha (`flex-col`) | mesma linha | idem |
| Ficha: Visão Geral | 1 coluna (lateral vai para baixo com `border-t`) | 1 coluna | 2 colunas `1fr / 320px` |
| Ficha: StatCards | 2 col | 3 col | 6 col |
| Ficha: grade de contrato | 2 col | 3 col | 3 col |
| Ficha: grade de título | 2 col | 4 col | 4 col |
| Aba Informações | 1 col | 2 col | 3 col (`xl`) |
| Cascata: colunas "Pendente"/"Títulos"/"Vencimento" | **ocultas** (`hidden sm:block`) | visíveis | visíveis |
| `ManualActionDialog` | largura total; rodapé `flex-col-reverse` | 640px | 640px |
| `PortfolioCreateWizard` | `max-w-3xl h-[90vh]` | idem | idem |

`MobileCollapsibleFilters` detecta mobile por `window.innerWidth < 768` no primeiro render e por `matchMedia("(max-width: 767px)")` depois; em desktop devolve os filhos sem wrapper.

### 16.2 Acessibilidade — o que já existe

| Recurso | Onde |
|---|---|
| `role="alert"` em erros | KPI bar, erro do grid, erro do kanban, erro dos catálogos de filtro, erro de busca em comboboxes |
| `aria-busy` | tabela durante refetch |
| `aria-sort` + `aria-label` descritivo | cabeçalhos ordenáveis do grid |
| `aria-label` em checkboxes | "Selecionar todos" / "Selecionar linha" |
| `aria-label` em ícones-ação | "Remover filtro", "Remover selo {nome}", "Copiar valor", "Limpar busca", "Ajuda: {título}", `"{título}: ver todos os {N}"` (o "+N") |
| `aria-expanded` + `role="combobox"` | gatilhos de multi-select e comboboxes |
| Navegação por teclado | gatilho do "+N" é `<button>`; o `X` dos chips da variante badges responde a Enter/Espaço; `HelpTip` é popover clicável (funciona em toque) |
| Foco visível | `focus-visible:ring-2 focus-visible:ring-ring` nos cards do kanban, no "+N", nos links do popover, nos botões de copiar |
| `aria-hidden` em ícones decorativos | `Layers`, setas de ordenação, ícones de grupo do seletor de colunas, chevrons |
| Tooltip em controle desabilitado | `FilterMultiSelect` embrulha o gatilho num `<span tabIndex={0}>` quando está `disabled` **e** tem `title` — botão desabilitado não emite evento de mouse no Chrome, então o `title` nativo nunca apareceria |
| `TooltipProvider` aninhado | proposital em `FilterMultiSelect`, para não quebrar quando renderizado fora da árvore do provider global |
| Atalho de teclado | **ESC** sai do modo selo (listener global); ESC fecha diálogos (padrão Radix) |

### 16.3 Lacunas de acessibilidade observadas

- Não há `<caption>` nem `scope` nas tabelas do grid e da blocklist.
- As linhas do grid são `<tr onClick>` — **não são focáveis nem acionáveis por teclado** (não têm `tabIndex`, `role="button"` ou `onKeyDown`). O mesmo vale para as linhas de regra de filtro.
- O `MultiSelectInput` de custom fields usa `<input type=checkbox>` nativo dentro de `<label>` (ok), mas o grupo não tem `role="group"` nem rótulo associado.
- O "modo selo" não é anunciado por região viva (`aria-live`) — só visualmente.
- Cores de status usam classes fixas (`bg-green-100 text-green-800` etc.) que **não** respondem ao tema escuro em vários pontos (badges de título, badges de dias no ManualActionDialog, alertas âmbar). Contraste em dark mode a validar.
- `formatDocument` decide CPF/CNPJ por **comprimento** em quase todos os pontos (correto), mas `ContactDetailDialog` legado usa `document_type` — que o ETL grava errado em 84% dos CNPJ.
- Não há skip-link para o conteúdo da tabela nem indicação textual de quantas colunas estão fora da viewport no scroll horizontal.

---

## 17. Dores e oportunidades para o redesign

### 17.1 Densidade e hierarquia

| # | Dor | Evidência no código | Oportunidade |
|---|---|---|---|
| 1 | A barra de filtros tem **11 controles** numa única linha `flex-wrap`, separados apenas por três divisores de 1px. Em telas médias ela quebra em 3-4 linhas e perde a leitura de grupos. | `PortfolioFiltersBar.tsx`, um único `div.flex.items-center.gap-4.flex-wrap` | Agrupar visualmente (dados / atribuição / ação), com rótulos de grupo ou um painel lateral/gaveta para os filtros avançados; manter só busca + 2-3 recortes sempre visíveis |
| 2 | A faixa de KPIs é **texto corrido centralizado**, não cards — difícil de escanear e sem hierarquia entre "vencido" (o número que importa) e "contratos". | `PortfolioKPIBar.tsx` | Tornar "vencido" e "em aberto" primários; permitir clicar num KPI para aplicar o recorte correspondente |
| 3 | O grid tem **densidade fixa** (`p-3`) e larguras fixas em px; sem redimensionar, reordenar ou congelar colunas à esquerda. | `PortfolioDataGrid.tsx` | Seletor de densidade (compacto/confortável), coluna Nome congelada, resize por arraste, salvamento do layout junto com a visibilidade |
| 4 | Com 45 colunas possíveis e scroll horizontal, o usuário perde a referência de qual contato está lendo. | idem | Congelar as colunas de identificação |

### 17.2 Seleção e ações em massa

| # | Dor | Evidência | Oportunidade |
|---|---|---|---|
| 5 | A seleção por checkbox **só serve para exportar**. Não há atribuir operador, aplicar selo, bloquear, excluir ou disparar em lote a partir da seleção. | `PortfolioManagementPage.tsx` — `selectedIds` é usado apenas em `handleExport` | Barra de ações contextual ("N selecionados: [Atribuir] [Aplicar selo] [Bloquear] [Exportar]") |
| 6 | O "modo selo" é um **modo global** que muda o significado do clique na linha — poderoso, mas invisível para quem chega depois (e conflita com a seleção por checkbox, que continua ativa). | `ApplySealMode.tsx` + `PortfolioDataGrid` | Substituir por ação em massa sobre a seleção; ou manter o modo mas com `aria-live` e bloqueio visual da seleção |
| 7 | "Selecionar todos" seleciona **a página**, não o recorte. Sem indicação de "selecionar todos os 12.345". | `table.toggleAllPageRowsSelected` | Padrão de duas etapas ("50 selecionados nesta página · Selecionar todos os 12.345") |

### 17.3 Consistência entre abas e telas

| # | Dor | Evidência | Oportunidade |
|---|---|---|---|
| 8 | O Kanban herda **toda** a barra de filtros, mas o toggle Contatos/Contratos fica numa faixa separada, e o modo default (`contracts`) difere do da lista (contatos). | `KanbanTab.tsx` | Unificar a linguagem de "unidade de análise" entre lista e quadro |
| 9 | O Select de **Tipo** da sub-aba "Bloqueios ativos" não oferece Suprimento/Parcela de Suprimento; a sub-aba "Desbloqueados" oferece. | `BlocklistTabV2.tsx` | Catálogo único de esferas |
| 10 | **Status de título legado em inglês** (`pending/paid/partial/cancelled/negotiated`) no `PortfolioEditDialog` e no `TitleEditDialog`, contra os canônicos em português no resto da tela. | `PortfolioEditDialog.tsx`, `TitleEditDialog.tsx` × `title-status-config.ts` | Um único catálogo de status na UI de edição |
| 11 | Status de **suprimento** e de **parcela de suprimento** são `Input` de texto livre (com default `"Removido"`), enquanto contrato e título são `Select`. | `SupplyEditDialog.tsx`, `SupplyTitleEditDialog.tsx` | `Select` com o catálogo canônico |
| 12 | Existem **duas gerações** de diálogos de contato/contrato (`components/contacts/*`, `components/contracts/*`) que não são usadas por esta tela, com funcionalidade que a tela atual **não tem** (marcar título como pago / "Baixar"). | §12.9 | Decidir: portar a ação "Baixar" para a ficha ou remover o legado |

### 17.4 Feedback e confiabilidade

| # | Dor | Evidência | Oportunidade |
|---|---|---|---|
| 13 | Clicar numa coluna "ordenável" **fora** do `SORT_FIELD_MAP` não ordena por ela — cai no fallback `max_days_overdue desc` sem avisar. | `PortfolioDataGrid.tsx`, `handleSortingChange` | Ou desabilitar o botão (com tooltip "não é possível ordenar por esta coluna"), ou implementar a ordenação |
| 14 | Falta de estado de **erro** nas tabelas da blocklist e nas abas da ficha (só há loading e vazio) — uma falha de consulta se lê como "não existe nada". | `BlocklistTabV2.tsx`, `OverviewTab.tsx`, `SuppliesTab.tsx` | Padronizar o trio loading/vazio/erro em todos os blocos, como já é feito no grid e no kanban |
| 15 | O campo de data de custom field abre um popover que **não tem calendário** — só diz "Use o formato DD/MM/AAAA". | `DynamicFieldInput.tsx` (`DateInput`) | Usar o `Calendar` do design system |
| 16 | `SealDialog` usa `<Textarea>` sem importar o componente. | `src/components/seals/SealDialog.tsx` | Corrigir na migração |
| 17 | A exclusão de contato é irreversível e **não pede confirmação forte** (nenhuma digitação do nome). | `DeleteContactDialog.tsx` | Confirmação por digitação para contatos com contratos/títulos |

### 17.5 Navegação e descoberta

| # | Dor | Evidência | Oportunidade |
|---|---|---|---|
| 18 | A "sheet" de detalhe é, na verdade, um **Dialog de 95vw × 95vh** — não dá para consultar o detalhe e a lista ao mesmo tempo, e não há navegação "próximo/anterior" entre contatos. | `ContactDetailSheet.tsx` | Sheet lateral real (ou split-view) + setas para navegar na lista filtrada |
| 19 | A ficha tem **5 abas** e a Visão Geral é uma cascata de 2 níveis com tudo fechado por padrão — encontrar um título específico exige N cliques. | `OverviewTab.tsx` | Busca dentro da cascata; expandir por padrão o contrato com maior atraso; lista plana de títulos com filtro |
| 20 | Clicar num card de **contrato** no Kanban abre a ficha do **contato** (com um stub montado no cliente), não um detalhe de contrato. | `KanbanTab.tsx`, `handleContractClick` | Ficha de contrato dedicada, ou abrir a ficha do contato **já expandida** naquele contrato |
| 21 | Não há forma de saber, olhando o grid, que um contato está bloqueado (o cadeado não é coluna). | não existe coluna de bloqueio em `DEFAULT_COLUMNS` | Coluna/indicador de bloqueio — com a ressalva de que o selo da carteira **não** considera o passe livre |
| 22 | Ajuda contextual é rica (`HELP_COPY`, "?" em toda coluna) mas dispersa em 12+ ícones de interrogação na mesma tela. | `PortfolioFiltersBar.tsx` | Consolidar num painel "Como ler esta tela" + manter o "?" só onde o conceito é ambíguo |

### 17.6 Performance percebida

| # | Dor | Evidência | Oportunidade |
|---|---|---|---|
| 23 | Trocar de filtro dispara: resolvedores (Ação/Segmento) → grid → KPIs → 7 queries de enriquecimento por página. O overlay de refetch cobre a tabela inteira. | `PortfolioManagementPage.tsx` | Skeleton por célula/coluna em vez de overlay total; indicar quais colunas ainda estão carregando |
| 24 | O grid **não é virtualizado** (o kanban é). Com `pageSize=100` e 20 colunas, são 2.000 células. | `PortfolioDataGrid.tsx` × `KanbanColumn.tsx` | Virtualização de linhas |
| 25 | As preferências de coluna vivem só no `localStorage` do navegador e são apagadas a cada bump de `COLUMN_VERSION`. | `types.ts`, efeito em `PortfolioManagementPage` | Persistir por usuário no servidor; migrar em vez de apagar; permitir "visões" salvas (conjunto de colunas + filtros) |

---

## 18. Inventário completo de modais do domínio

Legenda de tipo: **Dialog** = `@/components/ui/dialog` · **AlertDialog** = confirmação destrutiva · **Popover** = painel ancorado · **Inline** = substitui o conteúdo de uma aba/área.

### 18.1 Modais montados pela tela `/portfolio`

| # | Modal | Arquivo | Aberto por | Tipo | Destrutivo? |
|---|---|---|---|---|:-:|
| 1 | Ficha do contato (`ContactDetailSheet` / `PortfolioDetailSheet`) | `src/components/portfolio/detail/ContactDetailSheet.tsx` | clique na linha do grid · "Ver Detalhes" no menu · clique no card do kanban · deep-link `?contact=` | Dialog quase full-screen | não |
| 2 | Editar Cadastro (`PortfolioEditDialog`) | `src/components/portfolio/PortfolioEditDialog.tsx` | "Editar" no menu da linha · lápis no cabeçalho da ficha | Dialog `max-w-4xl h-[90vh]` | não |
| 3 | Confirmar Exclusão (`DeleteContactDialog`) | `src/components/portfolio/DeleteContactDialog.tsx` | "Excluir" no menu da linha | AlertDialog | **sim** |
| 4 | Novo Cadastro (`PortfolioCreateWizard`) | `src/components/portfolio/PortfolioCreateWizard.tsx` | botão "Novo Cadastro" | Dialog wizard 3 passos | não |
| 5 | Construtor de filtro (`FilterBuilderDialog`) | `src/components/filters/filter-builder` | botão `+` ao lado do seletor de Filtros | Dialog | não |
| 6 | Seletor de colunas (`PortfolioColumnToggle`) | `src/components/portfolio/PortfolioColumnToggle.tsx` | botão "Colunas" | Popover 288px | não |
| 7 | Seletor de selo para o modo (`ApplySealButton`) | `src/components/portfolio/ApplySealButton.tsx` | botão "Aplicar Selo" | Popover 288px | não |
| 8 | Menu de exportação | inline em `PortfolioManagementPage.tsx` | botão "Exportar" | DropdownMenu | não |
| 9 | Calendário de período de ação | inline em `PortfolioFiltersBar.tsx` | opção "Personalizado" no filtro Ação | Popover com `Calendar` + Cancelar/Aplicar | não |
| 10 | Lista completa de vínculos ("+N") (`OverflowBadgeList`) | `src/components/portfolio/OverflowBadgeList.tsx` | clique no chip "+N" (colunas Carteira/Réguas, Vínculos Ativos, não-encontrados do bulk) | Popover 320px | não |
| 11 | Ajuda contextual (`HelpTip`) | `src/components/common/HelpTip.tsx` | ícone "?" (barra de filtros, KPIs, cabeçalhos de coluna) | Popover 320px | não |

### 18.2 Modais abertos a partir da ficha do contato

| # | Modal | Arquivo | Aberto por | Tipo | Destrutivo? |
|---|---|---|---|---|:-:|
| 12 | Ação Manual (`ManualActionDialog`) | `src/components/portfolio/detail/ManualActionDialog.tsx` | botão "Nova Ação" | Dialog 640px × 85vh, 3 fases | não (mas **envia** comunicação real; pode forçar blocklist) |
| 13 | Seletor de Template Meta | inline em `ManualActionDialog.tsx` | combobox "Template Meta" | Popover 360px com `Command` | não |
| 14 | Raio-x do payload (`OutboundRequestView`) | `src/components/portfolio/detail/OutboundRequestView.tsx` | "Ver dados enviados à integração" no preview | Collapsible (não é modal) | não |
| 15 | Editar Contrato (`ContractEditDialog`) | `src/components/portfolio/ContractEditDialog.tsx` | lápis no card de contrato (Visão Geral) | Dialog `max-w-xl` | não |
| 16 | Editar Título (`TitleEditDialog`) | `src/components/portfolio/TitleEditDialog.tsx` | lápis no card de título (Visão Geral) | Dialog `max-w-xl` | não |
| 17 | Editar Suprimento (`SupplyEditDialog`) | `src/components/portfolio/SupplyEditDialog.tsx` | lápis no card de suprimento (aba Suprimentos) | Dialog `max-w-xl` | não |
| 18 | Editar Parcela de Suprimento (`SupplyTitleEditDialog`) | `src/components/portfolio/SupplyTitleEditDialog.tsx` | lápis na parcela (aba Suprimentos) | Dialog `max-w-xl` | não |
| 19 | Exportar histórico (`ReportExportDialog`) | `src/components/reports/ReportExportDialog.tsx` (gatilho em `detail/ContactHistoryExportButton.tsx`) | botão "Exportar histórico" (aba Histórico) | Dialog | não (expõe dados sensíveis se "completos") |
| 20 | Seletor de selos (`SealPicker`) | `src/components/seals/SealPicker.tsx` | botão `+` nas linhas de selo (contato/contrato/título) | Popover 288px | não |
| 21 | Novo/Editar Selo (`SealDialog`) | `src/components/seals/SealDialog.tsx` | "Criar novo selo" (dentro do picker ou do ApplySealButton) | Dialog | não |
| 22 | Detalhe da Ação (`ActionDetailContent`) | `src/components/actions/ActionDetailDialog.tsx` | clique num item da timeline | **Inline** (substitui o conteúdo da aba) | não |

### 18.3 Modais da aba Blocklist

| # | Modal | Arquivo | Aberto por | Tipo | Destrutivo? |
|---|---|---|---|---|:-:|
| 23 | Novo Bloqueio Manual (`BlocklistManualDialog`) | `src/components/portfolio/BlocklistManualDialog.tsx` | botão "Novo Bloqueio" | Dialog 520px | não (mas impede cobrança) |
| 24 | Busca de contato do bloqueio (`BlocklistContactCombobox`) | `src/components/portfolio/BlocklistContactCombobox.tsx` | campo "Contato" do dialog acima | Popover 460px com `Command` | não |
| 25 | Busca de contrato/título/suprimento (`BlocklistTargetCombobox`) | `src/components/portfolio/BlocklistTargetCombobox.tsx` | campos de alvo do dialog de bloqueio manual | Popover 420px com `Command` | não |
| 26 | Nova/Editar Regra (`BlocklistFilterRuleDialog`) | `src/components/portfolio/BlocklistFilterRuleDialog.tsx` | botão "Nova Regra" · "Editar regra" no detalhe | Dialog 600px | não |
| 27 | Detalhe da Regra (`BlocklistRuleDetailDialog`) | `src/components/portfolio/BlocklistRuleDetailDialog.tsx` | clique na linha da sub-aba Regras | Dialog 640px × 90vh, 2 abas | não (tem "Sincronizar agora") |
| 28 | Bloquear em massa (`BlocklistBulkDialog` kind=block) | `src/components/portfolio/BlocklistBulkDialog.tsx` | botão "Bloquear em massa" | Dialog 620px | **sim** (botão destructive; afeta N alvos) |
| 29 | Liberar em massa (`BlocklistBulkDialog` kind=exception) | mesmo arquivo | botão "Liberar em massa" | Dialog 620px | **sim de fato** (fura bloqueios de qualquer origem) |
| 30 | Colagem + relatório (`PastedListResolver`) | `src/components/portfolio/PastedListResolver.tsx` | dentro do dialog de massa | Collapsible/Card (não é modal) | não |
| 31 | Confirmar remoção de bloqueio | inline em `BlocklistTabV2.tsx` | lixeira da linha de bloqueio | AlertDialog | **sim** |
| 32 | Confirmar remoção de passe livre | inline em `BlocklistTabV2.tsx` | lixeira da linha de exceção | AlertDialog | **sim** |
| 33 | Confirmar pausar/reativar regra | inline em `BlocklistTabV2.tsx` | menu da linha de regra | AlertDialog | **sim** (pausar apaga as entradas geradas) |
| 34 | Confirmar excluir regra | inline em `BlocklistTabV2.tsx` | menu da linha de regra | AlertDialog | **sim** |

### 18.4 Modais legados do domínio (não montados por `/portfolio`)

| # | Modal | Arquivo | Observação |
|---|---|---|---|
| 35 | Blocklist V1 — Novo Bloqueio (`BlocklistDialog`) | `src/components/portfolio/BlocklistDialog.tsx` | usado só por `BlocklistTab.tsx` (V1), que não é montado |
| 36 | Detalhe do Contato legado (`ContactDetailDialog`) | `src/components/contacts/ContactDetailDialog.tsx` | ⚠️ A confirmar uso em outra tela |
| 37 | Contato legado (`ContactDialog`) | `src/components/contacts/ContactDialog.tsx` | tem edição de **tags**, que a ficha atual não tem |
| 38 | Detalhe do Contrato legado (`ContractDetailDialog`) | `src/components/contracts/ContractDetailDialog.tsx` | tem a ação **"Baixar"** (marcar título como pago), ausente na tela atual |
| 39 | Contrato legado (`ContractDialog`) | `src/components/contracts/ContractDialog.tsx` | tem busca de cliente com debounce |

### 18.5 Resumo por criticidade

| Criticidade | Modais |
|---|---|
| **Destrutivo irreversível** | Confirmar Exclusão de contato (3), Excluir regra (34) |
| **Destrutivo reversível / de alto impacto** | Bloquear em massa (28), Liberar em massa (29), Pausar regra (33), Remover bloqueio (31), Remover passe livre (32) |
| **Efeito externo real** | Ação Manual (12) — envia mensagem ao cliente; Exportar histórico (19) com "Dados completos" |
| **Escrita local** | Editar Cadastro (2), Novo Cadastro (4), editores de Contrato/Título/Suprimento/Parcela (15-18), Novo Bloqueio (23), Nova/Editar Regra (26), Selo (21) |
| **Leitura / configuração de UI** | Ficha (1), Detalhe da Regra (27), Detalhe da Ação (22), seletores e popovers (5-11, 13, 14, 20, 24, 25, 30) |

---

## Apêndice A — Tokens e padrões visuais recorrentes

| Padrão | Uso | Classes / valores |
|---|---|---|
| Cor derivada de entidade | carteira, selo, bucket, filtro | fundo `{color}10` (header de coluna kanban), `{color}15` (faixa do modo selo, chip de carteira), `{color}20` (badge, pílula de contagem), `{color}25` (linha realçada), `{color}40` (borda de badge); texto sempre na cor cheia |
| Superfície de faixa | KPIs, rodapé | `bg-muted/30` + `border-b` / `border-t` |
| Superfície de barra de controle | filtros | `bg-card` + `border-b` |
| Cabeçalho de tabela | grid | `bg-muted`, `sticky top-0 z-10` |
| Coluna sticky à direita | ações do grid | `sticky right-0`, sombra `-2px 0 4px rgba(0,0,0,0.1)`, `bg-background` na célula |
| Hover de linha | grid, listas | `hover:bg-muted/30` (grid) / `hover:bg-muted/50` (listas e cascatas) |
| Card colapsável | cascatas da ficha | `border rounded-lg` (contrato/suprimento) · `border rounded-md bg-muted/20` (título/parcela) |
| Chip de dado | carteiras, réguas, tags, selos | `Badge` shadcn com variantes `secondary` / `outline` |
| Valor monetário | grid, cards, StatCards | `tabular-nums`; compacto (`R$ 1,2 mi`) só na barra de KPIs |
| Positivo / negativo | valores pagos × vencidos | `text-green-600` (pago) · `text-destructive` (vencido/atrasado) · `text-orange-500` / âmbar (atenção) |
| Estado de carga | várias | `Skeleton` com a silhueta do conteúdo; `Loader2 animate-spin` para ações pontuais |
| Ajuda | filtros, colunas, KPIs | `HelpCircle size-3.5 text-muted-foreground cursor-help` + Popover `w-80 max-w-[90vw]` |

## Apêndice B — Mapa hook → superfície de UI

| Hook | Alimenta |
|---|---|
| `usePortfolioManagement` | grid (linhas, total, páginas) |
| `usePortfolioKPIs` | barra de KPIs |
| `useActionContactIds` | resolvedor do filtro de Ação (data + tipo + step) → `p_contact_ids` / `p_exclude_contact_ids` |
| `useSegmentContactIds` / `useSegmentOptions` | filtro Segmento |
| `useWorkflowStepOptions` | filtro Step da régua |
| `usePortfolioColumns` | catálogo de colunas (estáticas + dinâmicas) |
| `useContactPortfolios` / `useContactWorkflows` / `useContactCampaigns` | colunas Carteira/Réguas e "Vínculos Ativos" |
| `useContactCustomFields` / `useContactContractCustomFields` / `useContactSupplyCustomFields` | colunas de campos personalizados (as duas últimas **gateadas** por visibilidade) |
| `useContactActions` | colunas do grupo "Ações" e a timeline do Histórico |
| `useContactSeals` / `useSealCatalog` / `useEntitySeals` / `useApplySeal` / `useRemoveSeal` | coluna Selos, pickers, modo selo |
| `useAgingBuckets` | colunas do kanban |
| `useBucketContacts` / `useBucketContracts` (+ summaries) | conteúdo e cabeçalho das colunas do kanban |
| `useContactAssignments` / `useContactAssignment` / `useAssignContact` / `useUnassignContact` | avatar do card e seletor de Operador da ficha |
| `useContact` / `useContracts` / `useTitlesByContact` / `useContractMetrics` | ficha: Visão Geral e Informações |
| `useSupplies` / `useSupplyTitlesByContact` / `useSupplyMetrics` | ficha: aba Suprimentos |
| `useHasSupply` | existência da aba Suprimentos, do grupo de colunas "Suprimento" e das esferas de suprimento na blocklist |
| `useManualActionData` / `usePreviewManualAction` / `useSendManualAction` / `useContactRecentActions` | `ManualActionDialog` |
| `useBlocklistEntries` / `useBlocklistStatsV2` / `useBlocklistFilterRules` / `useBlocklistHistory` / `useSyncBlocklistRule` / `useBlocklistRuleTargets` | aba Blocklist |
| `useBlocklistExceptions` / `useBlocklistExceptionStats` / `useRemoveBlocklistException` | sub-aba Desbloqueados e o selo de conflito |
| `useResolveBySphere` / `useBlocklistBulkApply` | `BlocklistBulkDialog` |
| `useExportPortfolio` / `useActionsExport` | exportações |
| `useUrlFilterState` | persistência do recorte na URL |

