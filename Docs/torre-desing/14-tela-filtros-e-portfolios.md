# 14 · Tela de Filtros e Portfólios

> Documento de UX/produto do frontend **atual** da Torre de Controle (SaaS multi-tenant de cobrança da Finza).
> Objetivo: permitir que um designer redesenhe a interface **sem perder nenhuma funcionalidade**.
> Tudo aqui foi extraído da leitura do código. Onde o código é ambíguo, a linha está marcada com `⚠️ A confirmar:`.
> Repositório de origem: `cobranca-finza/`. Todos os caminhos citados são relativos a essa raiz.

---

## 0. Identidade (rota, arquivo, permissões, layout)

### 0.1 Rota e montagem

| Item | Valor | Fonte |
|---|---|---|
| Rota | `/filters` | `src/App.tsx` (linha ~414) |
| Componente | `FiltersPage` (export nomeado) | `src/pages/FiltersPage.tsx` |
| Carregamento | `lazy()` + `<Suspense fallback={<PageLoader />}>` | `src/App.tsx` (linha ~23) |
| Guardas de rota | `<ProtectedRoute>` → `<RequireOrg>` → `<AgentPanelProvider>` → `<AppLayout>` | `src/App.tsx` |
| Guarda de permissão na rota | **Nenhuma** (`<RequirePermission>` NÃO envolve `/filters`) | `src/App.tsx` |
| Entrada no menu lateral | "Filtros", ícone `Filter`, `permission: "filters:read"` | `src/components/layout/Sidebar.tsx` (linha 40) |

**Consequência de produto:** a rota em si não é bloqueada por permissão — quem digitar `/filters` na URL entra. O que filtra o acesso na prática é o **menu lateral** (`filters:read`) e, dentro da tela, a ocultação de botões por `hasPermission(...)`. Um `viewer` que digite a URL veria a lista (sem botões de escrita).
`⚠️ A confirmar:` se isso é intencional ou se a rota deveria receber `<RequirePermission permission="filters:read">` como as rotas de ETL, Integrações e Agentes de IA.

### 0.2 Permissões usadas na tela

Fonte: `src/contexts/OrganizationContext.tsx` (`ROLE_PERMISSIONS`) + `src/pages/FiltersPage.tsx`.

| Permissão | O que libera na tela | Papéis que têm |
|---|---|---|
| `filters:read` | Ver o item "Filtros" no menu lateral | owner (`*`), admin, manager, operator |
| `filters:write` | Botão **Novo Filtro**; itens de menu **Editar**, **Duplicar**, **Ativar/Desativar**; a chave (Switch) Ativo/Inativo do card; o link "Criar primeiro filtro" do estado vazio | owner (`*`), admin, manager, operator |
| `filters:delete` | Item de menu **Excluir**; botão **Excluir selecionados** da barra de seleção múltipla | owner (`*`), admin |

`viewer` **não tem** `filters:read` — a tela não aparece no menu para esse papel.

**Detalhe importante do RBAC (frontend-only):** `hasPermission` é resolvido no cliente a partir de `ROLE_PERMISSIONS`; `owner` recebe `["*"]`. Não há checagem de permissão nos hooks de mutação — a proteção é apenas de UI (e RLS no banco, fora do escopo deste documento).

### 0.3 Layout externo

- A página vive dentro do `AppLayout` (sidebar + topbar do produto). Este documento **não** descreve o AppLayout.
- Container raiz da página: `<div className="space-y-6">` — pilha vertical com 24px entre blocos, sem largura máxima própria (herda o container do `AppLayout`).
- A página é **single-column**: cabeçalho, card de controles, (barra de seleção condicional), bloco de resultados, paginação. Não há abas nesta rota.

### 0.4 Onde ficam os Portfólios (carteiras)

**Os Portfólios NÃO ficam em `/filters`.** Eles são uma **aba da tela de ETL**:

| Item | Valor | Fonte |
|---|---|---|
| Rota | `/etl` (protegida por `<RequirePermission permission="etl:read">`) | `src/App.tsx` (linha ~421) |
| Aba | `value="portfolios"`, rótulo **"Carteiras"**, ícone `Briefcase` | `src/pages/ETLPage.tsx` (linhas ~322-325) |
| Componente | `<PortfoliosTab ref={portfoliosTabRef} search={search} />` | `src/pages/ETLPage.tsx` (linha ~406) |
| Botão de criação | Vem do cabeçalho compartilhado do ETLPage: rótulo **"Nova Carteira"** quando a aba ativa é `portfolios`; chama `portfoliosTabRef.current?.openCreateModal()` | `src/pages/ETLPage.tsx` (linhas ~238-253) |
| Busca | Campo do cabeçalho do ETLPage, placeholder **"Buscar carteiras..."**, repassado como prop `search` | `src/pages/ETLPage.tsx` (linhas ~264-269) |

**Implicação de redesign:** filtro e carteira são conceitos irmãos (a carteira pode ser *definida por* um filtro), mas moram em telas diferentes, com permissões diferentes (`filters:*` vs `etl:read`). Um filtro pode ser criado por um `operator`; uma carteira, não (operator não tem `etl:read`).

### 0.5 Componentes de terceiros e design system

- shadcn/ui (`src/components/ui/*`): `Button`, `Input`, `Badge`, `Checkbox`, `Card`, `DropdownMenu`, `Popover`, `Tooltip`, `AlertDialog`, `Dialog`, `Table`, `Select`, `RadioGroup`, `Switch`, `ToggleGroup`, `Tabs`, `Textarea`, `ScrollArea`, `Separator`, `Label`, `Command`.
- Ícones: `lucide-react` (incluindo o mapa dinâmico `icons` para ícone por filtro).
- Drag & drop: `@dnd-kit/core` + `@dnd-kit/sortable` + `@dnd-kit/utilities`.
- Formulários: `react-hook-form` + `@hookform/resolvers/zod` + `zod`.
- Datas: `date-fns` com locale `ptBR`.
- Dados: TanStack Query v5 (React Query), via a factory `createCrudHooks`.

> Restrição de projeto (CLAUDE.md do repo): **não mover/alterar `src/components/ui/`** (compatibilidade Lovable), **não usar cores hardcoded** (usar CSS vars), **usar imports `@/`**. Um redesign deve respeitar isso ou declarar explicitamente a quebra.

---

## 1. Objetivo e personas

### 1.1 O que a tela resolve

`src/pages/central-docs/negocio/data/filtros.ts` descreve a tela como **"a biblioteca de recortes reutilizáveis da operação"**. A frase do próprio cabeçalho da página (`src/pages/FiltersPage.tsx`, linha ~518) é:

> "Crie filtros reutilizáveis para segmentar contatos e contratos"

Um filtro é uma **pergunta salva** ("quem deve mais de R$ 1.000 e está vencido há mais de 15 dias?") que:

1. é avaliada **ao vivo** contra a `vw_titles_live` (nunca materializada num campo do contato);
2. mostra **quantos** contatos/contratos/títulos casam e **quanto** representam em dinheiro;
3. é **consumida por outras telas**: Gestão de Carteira, Kanban, Dashboard, réguas de cobrança, campanhas, blocklist, configuração de Agentes de IA e base de conhecimento (RAG).

### 1.2 Personas

| Persona | Papel RBAC | O que faz aqui | Dor principal |
|---|---|---|---|
| **Operador de cobrança** | `operator` | Cria e ajusta recortes para campanhas do dia; confere com Visualizar/Ver Contatos antes de mandar pra régua | Precisa saber se o filtro "pega" quem ele imagina — sem SQL |
| **Gestor de cobrança** | `manager` | Audita a biblioteca, desativa filtros mortos, olha os valores agregados por recorte | A biblioteca acumula lixo e ele não sabe o que está em uso |
| **Administrador / TI** | `admin`, `owner` | Exclui filtros, resolve filtros com erro de cálculo, cria filtros de suprimento e de Agente de IA | Precisa distinguir "erro" de "carteira vazia" |
| **Analista de dados** | qualquer com `filters:write` | Usa a prévia + exportação CSV como ferramenta de conferência | Exportação limitada a 10.000 contatos |
| **Configurador de IA** | `admin`/`owner` (via telas de Agente) | Cria filtros de escopo `agent` pela tela de Agentes — que aparecem **aqui** com o selo "Agente de IA" | Escopo é imutável: errar exige duplicar |

### 1.3 Jobs-to-be-done observáveis no código

1. **Encontrar** um filtro na biblioteca (busca, tag de cor, ordenação, tri-state Ativos/Inativos/Todos).
2. **Entender** o que um filtro faz sem abrir o construtor (contagem de condições, selo AND/OR, descrição).
3. **Medir** o recorte (7 métricas: contatos, contratos, títulos, valor total, pago, em aberto, vencido).
4. **Conferir** quem está dentro (prévia com amostra de 10; carteira do filtro com lista paginada de 50 + CSV).
5. **Construir/editar** a árvore de condições (grupos, regras, E/OU, NÃO, arrastar, aninhar).
6. **Higienizar** a biblioteca (desativar, duplicar, excluir em massa).
7. **Ligar** o filtro a uma carteira (feito na outra tela, `/etl` → aba Carteiras).

---

## 2. Modelo mental: filtro, regra, grupo, escopo de uso, entidade alvo, portfólio/carteira

Esta seção é a base conceitual sem a qual o redesign quebra invariantes do backend.

### 2.1 Os sete conceitos

| Conceito | Onde vive | Definição operacional |
|---|---|---|
| **Filtro** (`filter_definition`) | Tabela `filter_definitions` do schema da org | Registro com nome, descrição, cor, ícone, escopo de uso, entidade alvo, flag ativo, a árvore de condições (JSONB) e 8 colunas de cache de estatística |
| **Regra** (`FilterRule`) | Folha da árvore | `{ id, field, operator, value, table?, negate? }` — uma comparação |
| **Grupo** (`FilterGroup`) | Nó da árvore | `{ id, logic: "and"\|"or", rules: (regra\|grupo)[], negate? }` — recursivo |
| **Lógica** | Propriedade do grupo | `and` (todas) ou `or` (qualquer uma). **Não existe lógica por regra** — a regra herda a do grupo pai |
| **Negação** (`negate`) | Propriedade de regra **e** de grupo | Aplica `NOT(...)` ao resultado já combinado. É opcional (retrocompatibilidade) |
| **Escopo de uso** (`usage_scope`) | Coluna do filtro | `common` (aparece em tudo) ou `agent` (só na configuração de Agentes de IA). **IMUTÁVEL após a criação** |
| **Entidade alvo** (`target_entity`) | Coluna do filtro | `contacts`\|`contracts`\|`titles`\|`supplies`\|`supply_titles`. Define contra qual partição de `entity_kind` o filtro é avaliado |

### 2.2 A árvore de condições

Definição canônica em `src/lib/filters/schema.ts` e `src/types/filters.ts`:

```ts
interface FilterRule {
  id: string;
  field: string;                                   // ex.: "days_overdue", "custom.segmento"
  operator: FilterOperator;                        // ver §7
  value: string | number | boolean | string[] | number[] | null;
  table?: FilterTable;                             // default "contacts"
  negate?: boolean;
}

interface FilterGroup {
  id: string;
  logic: "and" | "or";
  rules: (FilterRule | FilterGroup)[];             // recursivo
  negate?: boolean;
}
```

Discriminação regra × grupo na UI (`src/components/filters/filter-builder/utils.ts`):

```ts
export const isFilterGroup = (item) => "rules" in item && "logic" in item;
```

### 2.3 Formato inicial da árvore (o que o usuário vê ao abrir "Novo Filtro")

`src/components/filters/filter-builder/utils.ts`:

| Função | Produz |
|---|---|
| `createEmptyRule()` | `{ id: uuid, field: "", operator: "eq", value: "", table: "contacts" }` |
| `createEmptyNestedGroup()` | `{ id: uuid, logic: "and", rules: [createEmptyRule()] }` |
| `createEmptyGroup()` | `{ id: uuid, logic: "and", rules: [createEmptyNestedGroup()] }` — **raiz já nasce com um grupo dentro, que já nasce com uma regra vazia dentro** |

Ou seja: um filtro novo abre com **raiz (nível 0) → grupo (nível 1) → 1 regra vazia**. O usuário nunca vê uma raiz literalmente vazia na criação.

### 2.4 Regra de ouro: a raiz não aceita regras soltas

`src/components/filters/filter-builder/FilterGroupItem.tsx`, no `FilterGroupHeader`:

```tsx
{/* At depth 0 (root), only allow adding groups, not individual conditions */}
{depth > 0 && (<Button ... onClick={onAddRule}>Condicao</Button>)}
```

No nível 0 **só existe o botão "Grupo"**. O botão "Condição" só aparece a partir do nível 1. O mesmo vale no estado vazio (`EmptyGroupState`): o link "Adicionar condição" só é renderizado com `depth > 0`.

`⚠️ A confirmar:` o tipo e o compilador SQL aceitam regra direto na raiz (uma árvore antiga/importada pode ter isso). A UI **renderiza** essa regra normalmente (o `map` não discrimina por profundidade), só não deixa **criar** uma nova ali. Ou seja, a restrição é de criação, não de exibição.

### 2.5 Limites defensivos da árvore

`src/lib/filters/schema.ts` (card 6858):

| Constante | Valor | Semântica |
|---|---|---|
| `MAX_FILTER_DEPTH` | **20** | Profundidade máxima de aninhamento de grupos. É barreira **defensiva**, não limite de produto |
| `MAX_FILTER_NODES` | **500** | Teto de nós (regras + grupos) numa definição |

Mensagens de erro literais lançadas por `measureFilterTree` / `assertFilterTreeLimits`:

| Situação | Mensagem |
|---|---|
| Ciclo entre grupos | `Filtro inválido: referência circular entre grupos de condições.` |
| Profundidade excedida | `Filtro inválido: profundidade de N grupos excede o limite de 20.` |
| Nós excedidos | `Filtro inválido: N condições/grupos excedem o limite de 500.` |

Histórico relevante para o redesign (do comentário no código): **antes do 6858, a UI travava em 2 níveis** (`depth < 2` escondia o botão "Grupo") — um limite de produto disfarçado de detalhe de UI, invisível. Hoje o botão só some no teto de 20, **e quando some a tela escreve o porquê**:

```tsx
<span className="text-xs text-muted-foreground px-2">
  Limite de 20 niveis atingido
</span>
```

**Princípio de design a preservar:** quando um controle desaparece, a interface diz por quê.

### 2.6 Onde os limites são checados

| Ponto | Função | Arquivo |
|---|---|---|
| Criação do filtro | `assertFilterTreeLimits(data.conditions)` dentro de `transformCreate` | `src/hooks/useFilters.ts` |
| Atualização (só quando `conditions` vem no payload) | `assertFilterTreeLimits(conditions)` dentro de `transformUpdate` | `src/hooks/useFilters.ts` |
| Prévia | `assertFilterTreeLimits(conditions)` no início do `mutationFn` de `useFilterPreview` | `src/hooks/useFilters.ts` |
| Schema de borda | `BoundedFilterGroupSchema` (Zod `unknown → assert → pipe(FilterGroupSchema)`) | `src/lib/filters/schema.ts` |

**Não há checagem em tempo de edição** — o usuário pode montar 501 nós na tela e só descobrir ao salvar. `⚠️ A confirmar:` se o redesign deve antecipar esse feedback (contador de nós visível, por exemplo).

### 2.7 Escopo de uso (`usage_scope`) — descoberta, não execução

`src/hooks/useFilters.ts`:

| Valor | Efeito |
|---|---|
| `common` (default) | Aparece em todos os consumidores: dashboard, réguas, campanhas, portfólios, blocklist, kanban |
| `agent` | Aparece **somente** na configuração de Agentes de IA (Regras/Conhecimento) |

Três contextos de listagem (`FilterListContext`), que entram na query key do React Query:

| Contexto | Predicado aplicado no banco | Quem usa |
|---|---|---|
| `common` (default seguro) | `usage_scope = 'common'` | Todo consumidor operacional |
| `agent_config` | `usage_scope IN ('common','agent')` | Telas de configuração de IA |
| `all_admin` | *(nenhum predicado de escopo)* | **Esta tela** (`/filters`) — é o inventário administrativo |

**O escopo é imutável.** No banco existe o trigger `enforce_filter_usage_scope_immutable`, que recusa `UPDATE`. Na UI:
- o seletor de escopo só aparece na **criação** e só quando `allowAgentScope` é `true`;
- na **edição** o escopo vira **texto somente-leitura** com a frase "— imutável após a criação.";
- o `usage_scope` **não é enviado** no update (`src/components/filters/filter-builder/index.tsx`, comentário explícito).

### 2.8 Ativo × Inativo (`is_active`) — também descoberta, não execução

`src/hooks/useFilters.ts` + `src/pages/central-docs/topics/data/filtros-portfolios.ts`.

| Estado | Efeito |
|---|---|
| `is_active = true` (ou `NULL`, legado) | Aparece em todos os seletores |
| `is_active = false` | **Some dos seletores** de régua, carteira, kanban, dashboard, portfólio, blocklist, agente de IA, RAG e `GET /api/reguas` |

**O que NÃO muda ao desativar:** régua, carteira ou regra de blocklist que **já apontam para o filtro por id** continuam executando exatamente igual, e continuam exibindo o nome dele.

Recorte de ativação na listagem (`FilterActiveStatus`), só lido no contexto `all_admin`:

| Valor | Predicado |
|---|---|
| `active` (**default da tela**) | `is_active = true` |
| `inactive` | `is_active = false` |
| `all` | nenhum |

Nos demais contextos, o predicado é sempre `is_active = true`, sem opção.

**Null-safety na UI:** a coluna ainda é nullable em orgs onde a migration de `NOT NULL` não chegou. Por isso a tela usa **`is_active !== false`** (e nunca `!is_active`) em todos os lugares: `FilterInactiveBadge`, o `checked` do Switch, o rótulo "Ativo/Inativo", a opacidade da linha/card.

### 2.9 Entidade alvo (`target_entity`) — o "mundo" do filtro

`src/lib/filters/target-entity.ts` (IAF-4795). Dois campos codificam "isto é suprimento ou contrato":

1. **`conditions[].table`** — nível da CONDIÇÃO. É o dropdown que o usuário vê.
2. **`filter_definitions.target_entity`** — nível do FILTRO (escopo-raiz). É o que o motor usa.

**A UI nunca preenche `target_entity` diretamente.** Ele é **derivado** das condições, no hook, no único ponto por onde todo save passa:

```ts
// transformCreate / transformUpdate em src/hooks/useFilters.ts
target_entity: data.target_entity ?? deriveTargetEntity(data.conditions)
```

Regra de derivação (`deriveTargetEntity`):

| Tabelas presentes na árvore | `target_entity` resultante |
|---|---|
| Qualquer `supplies` ou `supply_titles` | `supplies` |
| Nenhuma delas | `contracts` |

Classificação das tabelas:

| Classe | Tabelas | Papel na derivação |
|---|---|---|
| Suprimento (`SUPPLY_TABLES`) | `supplies`, `supply_titles` | Ancoram o filtro no mundo suprimento |
| Contrato (`CONTRACT_TABLES`) | `contracts`, `titles` | Ancoram no mundo contrato |
| **Neutras** | `contacts`, `actions`, `aging`, `data_sources` | Existem nos dois ramos; **sozinhas não decidem a raiz** |

### 2.10 Filtro misto é proibido (validação bloqueante no save)

`hasMixedEntityTables(conditions)` retorna `true` quando há **simultaneamente** tabela de suprimento e tabela de contrato/título na árvore. Nesse caso o `onSubmit` do construtor **aborta antes de qualquer mutação** e dispara um toast destrutivo:

| Elemento | Texto literal |
|---|---|
| Título | `Filtro misto nao e permitido` |
| Descrição | `Este filtro combina condicoes de Suprimento com condicoes de Contrato/Titulo. Um filtro avalia um mundo por vez — separe em dois filtros.` |

**Motivo técnico (do comentário no código):** `entity_kind` na `vw_titles_live` é ou/ou. Um filtro misto não é representável — o compilador escolheria uma partição e as regras da outra passariam a ser avaliadas contra as colunas erradas, **em silêncio**.

### 2.11 Portfólio (carteira)

`src/types/portfolios.ts`, `src/hooks/usePortfolios.ts`, `src/pages/central-docs/topics/data/filtros-portfolios.ts`.

Uma carteira é um **segmento dinâmico**: o pertencimento é **derivado a cada leitura**, nunca gravado no contato. Invariante de arquitetura do projeto (CLAUDE.md, regra 5): **não existe coluna `portfolio_ids` em contatos**.

Dois tipos de definição (`definition_type`):

| Tipo | Campos usados | O que significa |
|---|---|---|
| `field` | `field_name` + `field_values[]` | "Pertence quem tem o campo X com um dos valores Y" — sintetiza um OR-of-in |
| `filter` | `filter_definition_id` (ou `filter_conditions` inline, legado) | "Pertence quem casa com este filtro salvo" |

Ordem de resolução no backend (`evaluate_portfolios_batch`): `filter_conditions` inline → `filter_definition_id` → `definition_type='field'` → zeros.

**O vínculo filtro ⇄ carteira é a ponte entre as duas telas:** o filtro é criado em `/filters`; a carteira que o consome é criada em `/etl` → aba Carteiras → modo "Por Filtro".

### 2.12 Três sistemas de contagem que coexistem — e por que os números divergem

| Origem | Granularidade | Quando é usada |
|---|---|---|
| `cached_*` (8 colunas em `filter_definitions`) | Último cálculo salvo | Primeiro paint da lista — instantâneo |
| `evaluate_filters_batch` (RPC) | Recalculado agora, N filtros numa query | Refresh em background da lista |
| `evaluate-filter` (Edge Function → RPC de preview) | Recalculado agora, 1 conjunto de condições | Prévia (`FilterPreviewDialog`) e fallback individual |

As 8 colunas de cache: `cached_contact_count`, `cached_contract_count`, `cached_title_count`, `cached_overdue_value`, `cached_total_debt`, `cached_total_value`, `cached_paid_value`, `cached_open_value`.

**Regra de leitura do `openValue`** (`src/hooks/useFilters.ts`): `cached_open_value ?? cached_total_debt ?? 0` — `total_debt` é alias histórico de `open_value`.
**Regra do `overdueValue`:** sempre `Math.max(0, ...)` — vencido nunca é negativo na UI.

### 2.13 Erro ≠ vazio (invariante de produto)

Presente em todos os caminhos de estatística. Quando o cálculo de um filtro falha:

- os números exibidos **preservam o cache** (`cachedStats[id] ?? EMPTY_FILTER_STATS`);
- o registro recebe `hasError: true` e `errorMessage`;
- a UI mostra um **ícone de alerta vermelho** (`AlertCircle`) com o motivo no tooltip;
- **nunca** aparece "0 contatos" por falha.

Motivo: "0" é uma resposta plausível e silenciosa; um filtro quebrado que mostra 0 vira decisão errada de cobrança.

---

## 3. Anatomia visual da tela (abas, lista, cards, barra de ações)

Fonte: `src/pages/FiltersPage.tsx`.

### 3.1 Estrutura em blocos (de cima para baixo)

```
┌─ <div class="space-y-6"> ───────────────────────────────────────────────┐
│                                                                          │
│  [1] CABEÇALHO  (flex items-center justify-between)                      │
│      ├─ esquerda: <h1> [ícone Filter 32px] "Filtros" [HelpTip ?]         │
│      │            <p muted> "Crie filtros reutilizáveis para segmentar   │
│      │                       contatos e contratos"                       │
│      └─ direita:  [RefreshButton ⟳] [HelpTip ?] [Botão "Novo Filtro"]    │
│                                                                          │
│  [2] CARD DE CONTROLES  (<Card><CardContent class="py-4">)               │
│      └─ <div class="flex flex-wrap items-center gap-3">                  │
│         ├─ Busca (Input com ícone Search, flex-1 max-w-md)               │
│         ├─ ToggleGroup tri-state: Ativos | Inativos | Todos              │
│         ├─ Popover "Tags" (paleta de 10 cores)                           │
│         ├─ Botão ícone ArrowUpDown (inverte asc/desc)                    │
│         ├─ Botão contendo <select>: A-Z | Criação | Atualização          │
│         └─ ViewToggle (lista ⇄ card)                                     │
│                                                                          │
│  [3] BARRA DE SELEÇÃO  (condicional: selectedIds.size > 0)               │
│      <Card class="border-primary bg-primary/5">                          │
│      ├─ "N filtro(s) selecionado(s)"  [Limpar seleção]                   │
│      └─ [Excluir selecionados]  (só com filters:delete)                  │
│                                                                          │
│  [4] BLOCO DE RESULTADOS                                                 │
│      ├─ contador: "N filtros encontrados" | "Carregando..."              │
│      └─ um de: Skeleton | EstadoVazio | Tabela | Grade de cards          │
│                                                                          │
│  [5] PAGINAÇÃO  (condicional: totalPages > 1, FORA dos branches)         │
│      "Página X de Y"          [< Anterior]  [Próxima >]                  │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
+ 5 overlays: FilterBuilderDialog (criar), FilterBuilderDialog (editar),
              FilterPreviewDialog, FilterPortfolioModal,
              AlertDialog (bulk), AlertDialog (individual)
```

### 3.2 Cabeçalho — detalhe

| Elemento | Especificação | Observação |
|---|---|---|
| Título | `<h1 class="text-3xl font-bold flex items-center gap-2">` | Ícone `Filter` em `h-8 w-8` (32px) à esquerda |
| HelpTip do título | `topic="what_is_filter"`, `side="bottom"`, `align="start"` | Popover clicável (ver §3.6) |
| Subtítulo | `<p class="text-muted-foreground">` | Texto fixo |
| RefreshButton | `onRefresh={handleRefreshStats}`, `isFetching={isFetchingStats}`, `title="Atualizar estatísticas"` | Envolto em `Tooltip` com o mesmo texto — **redundância**: o botão tem `title` HTML **e** um Tooltip shadcn |
| HelpTip de frescor | `topic="stats_freshness"`, `side="bottom"`, `align="end"` | |
| Novo Filtro | `<Button>` com ícone `Plus` (`h-4 w-4 mr-2`) | Só com `filters:write` |

### 3.3 Card de controles — os 6 controles

| # | Controle | Componente | Estado | Persistência |
|---|---|---|---|---|
| 1 | Busca | `Input` + ícone `Search` absoluto (`left-3`, `pl-10`) | `urlState.search` | **URL** (query string) |
| 2 | Status | `ToggleGroup type="single"` com 3 `ToggleGroupItem` | `statusFilter` (useState) | **Só memória** |
| 3 | Tags (cores) | `Popover` + grid 2 colunas de 10 botões | `selectedColors` (useState) | **Só memória** |
| 4 | Direção | `Button variant="outline" size="icon"` com `ArrowUpDown` | `urlState.sortDirection` | **URL** |
| 5 | Critério | `<select>` HTML nativo dentro de `<Button asChild><div>` | `urlState.sortBy` | **URL** |
| 6 | Visualização | `ViewToggle` | `useViewPreference("filters")` | **localStorage** (`view-preference-filters`) |

**Inconsistência de persistência a resolver no redesign:** três mecanismos diferentes para seis controles da mesma barra. Busca/página/ordenação vão pra URL (compartilhável), status e cores morrem no reload, e a visualização vai pro localStorage.

**Nota de implementação do controle 5:** o `<select>` nativo está aninhado dentro de um `Button asChild` que envolve uma `<div>`. Visualmente parece um botão outline; semanticamente é um select solto com `className="bg-transparent border-0 focus:outline-none cursor-pointer text-sm"`. Não há `<label>` associado nem `aria-label`.

**Comentário no código sobre o `flex-wrap`:** "a barra ganhou o tri-state de status (IAF-6986) e passa a quebrar em telas estreitas em vez de espremer os controles".

### 3.4 As duas visualizações

| | Lista (`viewMode === "list"`) | Grade (`viewMode === "card"`) |
|---|---|---|
| Container | `<RefreshableSection className="rounded-md border bg-card">` | `<RefreshableSection className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">` |
| Unidade | `<TableRow>` (12 colunas) | `<Card>` |
| Densidade | ~12 filtros na tela | 6 cards (3 colunas em `lg`) |
| Ações rápidas | Menu `⋯` | Menu `⋯` + **Switch Ativo/Inativo** |
| Ativar/Desativar no menu | **Sim** | **Não** (só o Switch) |
| Indicação de cor | Quadrado 32px com fundo `cor+20` | Borda esquerda 4px + quadrado 40px |
| Estatísticas | 7 colunas numéricas | Bloco agrupado clicável |
| Nº de condições / lógica | **Não mostra** | **Mostra** ("N condições" + selo `and`/`or`) |

**Assimetria funcional relevante:** a grade mostra a contagem de condições e o selo de lógica; a lista não. A lista tem "Ativar/Desativar" no menu; a grade tem o Switch mas não o item de menu. Um redesign deve decidir se as duas visões são equivalentes ou deliberadamente diferentes.

### 3.5 `RefreshableSection` — o "dim" de refresh

`src/components/common/RefreshableSection.tsx`:

```tsx
<div aria-busy={isRefreshing}
     className={cn("transition-opacity", isRefreshing && "pointer-events-none opacity-60", className)}>
```

Aplicado na seção inteira (tabela ou grade), com `isStatsRefreshing = isFetchingStats && !isLoadingStats`.
**Não dima na primeira carga** — só em refresh de background. Comentário no código (PORT-19): "dim único da seção durante refresh (sem spinners per-cell)".

### 3.6 `HelpTip` — a ajuda contextual "?"

`src/components/common/HelpTip.tsx` + `src/lib/filters/help-copy.ts`.

| Aspecto | Especificação |
|---|---|
| Gatilho | `<button>` com ícone `HelpCircle` `size-3.5`, `text-muted-foreground`, `cursor-help`, `aria-label="Ajuda: {título}"` |
| Variante padrão | `popover` — **clicável** (acessível no mobile, texto não trunca) |
| Variante alternativa | `tooltip` — hover, só para textos curtos |
| Conteúdo do popover | `w-80 max-w-[90vw]`, título em `text-sm font-semibold`, corpo em `text-xs text-muted-foreground`, `whitespace-normal break-words` |
| Comportamento | `onClick={(e) => e.stopPropagation()}` — convive com linhas/cards clicáveis |
| Fonte do texto | Chave de `HELP_COPY` (fonte única) ou conteúdo inline |

Os 5 tópicos de ajuda usados no domínio Filtros (`src/lib/filters/help-copy.ts`):

| Chave | Título | Corpo (literal) |
|---|---|---|
| `what_is_filter` | O que é um filtro | "Um filtro é uma regra salva que seleciona títulos por critérios (atraso, valor, status, campos do contrato/contato…). Ele é avaliado título a título: as contagens mostram só o que casa com a regra." |
| `builder_group_logic` | Lógica do grupo (E/OU) | "Combina as regras DESTE grupo. 'E' exige todas; 'OU' basta uma. Você pode aninhar grupos para montar lógicas como (A E B) OU C." |
| `builder_negate` | Negação (NÃO) | "Inverte a regra/grupo: passa quem NÃO atende. Títulos com o campo vazio (nulo) entram no resultado do 'NÃO' (comportamento seguro para não perder ninguém)." |
| `stats_freshness` | Frescor dos números | "'Em cache' = número salvo do último cálculo (aparece na hora). 'Atualizado' = recalculado agora. Se der erro no recálculo, mantemos o último valor válido em vez de mostrar zero." |
| `aging_bucket` | Faixa de atraso | "Faixas por dias de atraso: em dia, 1–30, 31–60, 61–90, 91–180, 180+. 'Em dia' inclui títulos a vencer (atraso negativo)." |

**Onde cada um aparece:**

| Tópico | Local |
|---|---|
| `what_is_filter` | Ao lado do `<h1>` "Filtros" |
| `stats_freshness` | No cabeçalho, ao lado do RefreshButton |
| `builder_negate` | No construtor, ao lado do botão "NÃO (NOT)" do **grupo** |
| `builder_group_logic` | No construtor, ao lado do seletor E/OU do grupo |
| `aging_bucket` | Na regra individual, **condicional**: só quando `rule.table === "aging"` |

**Observação:** o botão "NÃO (NOT)" da **regra** (não do grupo) **não tem** HelpTip — só `title` HTML. Assimetria com o grupo.

---

## 4. Lista de filtros (colunas, badges, contadores, menu de ações por item, busca, ordenação)

### 4.1 Consulta que alimenta a lista

`src/pages/FiltersPage.tsx`:

```ts
const { data, isLoading, error, refetch: refetchFilters } = useFilters({
  context: "all_admin",
  search: search || undefined,
  page,
  pageSize: 20,
  colors: selectedColors.length > 0 ? selectedColors : undefined,
  status: statusFilter,
  orderBy: sortBy,
  orderAscending: sortDirection === "asc",
});
```

| Parâmetro | Valor | Nota |
|---|---|---|
| `context` | `"all_admin"` | **Único lugar do produto** que vê os dois escopos e os três estados de ativação |
| `pageSize` | **20** | Fixo, não configurável pelo usuário |
| `orderBy` | `name` \| `created_at` \| `updated_at` | **Server-side** (PORT-4). Antes era client-side sobre a página atual — "Criação desc" nunca revelava o mais novo global |
| `colors` | `string[]` | Vira `.in("color", colors)` |
| `status` | `active`\|`inactive`\|`all` | Só lido em `all_admin` |

Retorno: `{ filters, total, page, pageSize, totalPages }`.

### 4.2 Estado da URL

`src/hooks/useUrlFilters.ts` — `useUrlFilterState(FILTERS_URL_DEFAULTS)`.

```ts
const FILTERS_URL_DEFAULTS = {
  search: "",
  page: "1",
  sortBy: "name",
  sortDirection: "asc",
};
```

Regras do hook:
- **Só chaves não-default aparecem na URL** (URL limpa por padrão);
- escreve com `{ replace: true }` (não empilha histórico);
- **regra anti-loop:** escrever somente em handlers de usuário, nunca em `useEffect` que observa o próprio estado;
- passar `undefined` num campo o remove da URL.

Saneamento defensivo na página:

```ts
const page = Math.max(1, Number(urlState.page) || 1);
const sortBy = SORT_KEYS.includes(urlState.sortBy) ? urlState.sortBy : "name";
const sortDirection = urlState.sortDirection === "desc" ? "desc" : "asc";
```

URL suja (`?sortBy=xpto`) cai no default sem erro.

### 4.3 Colunas da tabela (visualização Lista)

| # | Cabeçalho | Largura | Alinhamento | Conteúdo | Click |
|---|---|---|---|---|---|
| 1 | *(checkbox)* | `w-[40px]` | — | `Checkbox` "Selecionar todos" | `stopPropagation` |
| 2 | `Tag` | `w-[48px]` | — | Quadrado 32px (`rounded-md`) com fundo `filter.color + "20"` e ícone dinâmico na cor cheia. **Só renderiza se `filter.icon && filter.color`** | propaga → edita |
| 3 | `Nome` | auto | esquerda | Nome + `FilterScopeBadge` + `FilterInactiveBadge`; descrição abaixo (`text-xs`, `truncate max-w-[200px]`) | propaga → edita |
| 4 | `Contatos` | auto | direita | `contactCount.toLocaleString("pt-BR")` | **abre carteira do filtro** |
| 5 | `Contratos` | auto | direita | `contractCount` | **abre carteira** |
| 6 | `Titulos` | auto | direita | `titleCount` | **abre carteira** |
| 7 | `Vl Total` | auto | direita | `formatCompactCurrency(totalValue)` + Tooltip com valor cheio | **abre carteira** |
| 8 | `Vl Pago` | auto | direita | idem, `text-emerald-600` | **abre carteira** |
| 9 | `Em Aberto` | auto | direita | idem, `text-orange-500` | **abre carteira** |
| 10 | `Vencido` | auto | direita | idem, `text-red-500` | **abre carteira** |
| 11 | `Atualizado` | auto | esquerda | `dd/MM/yy` + `StatsFreshnessIndicator` | propaga → edita |
| 12 | *(menu)* | `w-[70px]` | — | `DropdownMenu` com `MoreHorizontal` | `stopPropagation` |

Notas:
- Os cabeçalhos estão **sem acento** no código: "Titulos".
- As colunas 4–10 têm `hover:bg-primary/10 transition-colors` — feedback de "clicável".
- A linha inteira tem `cursor-pointer hover:bg-muted/50` e `onClick={() => setEditingFilter(filter)}`.
- Linha selecionada: `bg-primary/5`. Linha de filtro inativo: `opacity-60`.
- **Não há cabeçalho clicável para ordenar** — a ordenação vive só na barra de controles.

### 4.4 Formatação de moeda

`src/pages/FiltersPage.tsx`:

```ts
function formatCurrency(value)         // Intl pt-BR, BRL, 0 casas decimais
function formatCompactCurrency(value)  // >= 1M → "R$ 1.2M" ; >= 1K → "R$ 45K" ; senão formatCurrency
```

A lista mostra **sempre a forma compacta**, com o valor cheio no Tooltip (apenas para as 4 colunas monetárias, não para as de contagem).

**Detalhe:** `formatCurrency` usa `minimumFractionDigits: 0` — centavos nunca aparecem na tela de Filtros. Já o `FilterPortfolioModal` usa sua própria `formatCurrency` com **2 casas**. Dois formatos de moeda no mesmo domínio.

### 4.5 Card da visualização Grade

Estrutura (`<Card>` com `hover:shadow-md transition-shadow cursor-pointer relative`):

| Região | Conteúdo |
|---|---|
| Borda esquerda | `border-l-4` com `borderLeftColor: filter.color` (só se houver cor) |
| Canto superior esquerdo | `Checkbox` absoluto (`top-3 left-3 z-10`), com `stopPropagation` |
| `CardHeader` (`pb-2 pl-10`) | Quadrado 40px (`rounded-lg`) com ícone; `CardTitle text-lg truncate`; badges de escopo e inativo; `CardDescription line-clamp-2` |
| Canto superior direito | `DropdownMenu` (`h-8 w-8 p-0`) |
| Bloco de estatísticas | `bg-muted/50 rounded-lg`, `hover:bg-primary/10`, clicável → abre carteira |
| Linha 1 do bloco | grid 3 colunas: contatos (ícone `Users` primary), contratos (`FileStack`), títulos (`FileText`). Número em `text-xs font-semibold`, rótulo em `text-[9px]` |
| Separador | `<Separator className="my-1" />` |
| Linha 2 do bloco | grid 2×2: Total (`Banknote`), Pago (`CircleCheck` emerald), Aberto (`CircleAlert` orange), Vencido (`DollarSign` red). Valor alinhado à direita com `ml-auto` |
| Rodapé 1 | `N condições` (ícone `Filter`) · selo de lógica (`and`/`or` em caixa alta, `bg-muted`) · **Switch Ativo/Inativo** (`ml-auto`, só com `filters:write`) |
| Rodapé 2 | "Atualizado em dd/MM/yyyy 'às' HH:mm" + `StatsFreshnessIndicator` |

Estados visuais do card: selecionado → `ring-2 ring-primary`; inativo → `opacity-60`.

**Tipografia minúscula:** os rótulos "contatos/contratos/titulos" usam `text-[9px]` — abaixo do mínimo legível confortável. Candidato claro a revisão no redesign.

### 4.6 Contagem de condições

```ts
const countConditions = (filter) => {
  const countRules = (group) => group.rules.reduce((count, rule) =>
    (typeof rule === "object" && rule !== null && "rules" in rule)
      ? count + countRules(rule)   // grupo: recursa, NÃO conta o próprio grupo
      : count + 1,                 // regra: conta 1
  0);
  return filter.conditions?.rules ? countRules(filter.conditions) : 0;
};
```

**Conta apenas folhas (regras).** Grupos não entram na conta. Um filtro com 3 grupos de 2 regras exibe "6 condições".

### 4.7 Selo de lógica

```tsx
<span className="text-xs uppercase font-medium px-1.5 py-0.5 rounded bg-muted">
  {filter.conditions?.logic || "and"}
</span>
```

Exibe o valor cru em inglês, em caixa alta: **"AND" / "OR"** — divergindo do construtor, que escreve "E (AND)" / "OU (OR)". `⚠️ A confirmar:` se a exibição em inglês no card é intencional (o guia de negócio a documenta como "a lógica em inglês abreviado, em maiúsculas") ou dívida.

### 4.8 Badges

#### `FilterScopeBadge` (exportado da página)

```tsx
if (usageScope !== "agent") return null;
<Badge variant="outline" className="h-5 shrink-0 gap-1 px-1.5 text-xs font-normal"
       title="Aparece somente em Regras e Conhecimento dos Agentes de IA"
       data-testid="filter-scope-agent">
  <Bot className="h-3 w-3" /> Agente de IA
</Badge>
```

Filtro comum **não recebe selo** — é o caso majoritário e poluiria a lista (comentário no código, IAF-5187).

#### `FilterInactiveBadge` (exportado da página)

```tsx
if (isActive !== false) return null;
<Badge variant="outline" className="h-5 shrink-0 gap-1 px-1.5 text-xs font-normal text-muted-foreground"
       title="Não aparece nos seletores de régua, carteira, dashboard e blocklist. Vínculos que já existem continuam funcionando."
       data-testid="filter-inactive-badge">
  <PowerOff className="h-3 w-3" /> Inativo
</Badge>
```

Os dois badges aparecem **nas duas visualizações**, logo após o nome.

### 4.9 `StatsFreshnessIndicator` — 3 estados

```tsx
function StatsFreshnessIndicator({ source, isFetching, stats })
```

| Condição | Ícone | Tooltip |
|---|---|---|
| `stats.hasError === true` | `AlertCircle h-3 w-3 text-destructive` | "Não foi possível calcular os números deste filtro." + `stats.errorMessage` em `text-xs text-muted-foreground` |
| `source === "cached"` e há stats | `Clock h-3 w-3 text-muted-foreground/60` | "Números em cache — atualizando..." (se `isFetching`) ou "Números em cache" |
| `source === "fresh"` | **nenhum ícone** | — |

O `TooltipContent` do caso de erro tem `max-w-[300px]`.

**Semântica declarada no comentário (PORT-8/spec-08/D6):** o indicador está atado ao **dado certo** — os números vêm do cache (`cached_*`) até o batch RPC responder **nesta sessão**. Substitui uma heurística antiga de "30 minutos sobre `preview_updated_at`" (timestamp de outra coisa).

### 4.10 Menu de ações por item

#### Na Lista (6 itens possíveis)

| Ordem | Item | Ícone | Permissão | Ação |
|---|---|---|---|---|
| 1 | Ver Contatos | `Users` | — | `setPortfolioFilter(filter)` |
| 2 | Visualizar | `Eye` | — | `setPreviewingFilter(filter)` |
| 3 | Editar | `Pencil` | `filters:write` | `setEditingFilter(filter)` |
| 4 | Duplicar | `Copy` | `filters:write` | `handleDuplicate(filter)` |
| 5 | Ativar **ou** Desativar | `Power` / `PowerOff` | `filters:write` | `handleToggleActive(filter, filter.is_active === false)`; `disabled={toggleFilterActive.isPending}` |
| 6 | Excluir | `Trash2` | `filters:delete` | `setDeleteTarget(filter)`; classe `text-destructive` |

#### Na Grade (5 itens — **sem** Ativar/Desativar)

Mesma lista, menos o item 5. Todos os handlers recebem `e.stopPropagation()` explicitamente, porque o card inteiro é clicável.

Alinhamento do menu: `align="end"` nas duas visões.

### 4.11 Duplicar — comportamento exato

```ts
const handleDuplicate = (filter) => {
  setEditingFilter({
    ...filter,
    id: "",                          // limpa o ID → vira criação
    name: `${filter.name} (cópia)`,
  });
};
```

Consequências:
- reaproveita o **mesmo dialog de edição** (`open={!!editingFilter}`), pois o objeto é truthy;
- dentro do construtor, `isEditing = !!filter?.id` → `false` → o botão diz **"Criar Filtro"** e o submit chama `createFilter`;
- o dialog de edição é montado **sem** `allowAgentScope`, então **o seletor de escopo não aparece** mesmo sendo uma criação;
- o `usage_scope` do original é carregado no `reset` e enviado no create → **a cópia herda o escopo silenciosamente**;
- o bloco "Escopo: … — imutável após a criação" **não aparece** (é condicionado a `isEditing`).

`⚠️ A confirmar:` duplicar um filtro de Agente de IA cria outro filtro de Agente sem nenhum aviso na tela. É o comportamento desejado (dado que escopo é imutável e "para mudar, duplique") ou deveria oferecer a escolha?

### 4.12 Seleção múltipla

| Estado / handler | Comportamento |
|---|---|
| `selectedIds: Set<string>` | Guarda os ids marcados |
| `allSelected` | `data.filters.every(f => selectedIds.has(f.id))` — **só da página atual** |
| `toggleSelection(id)` | Adiciona/remove um id |
| `toggleSelectAll()` | Se `allSelected`, **esvazia o Set inteiro**; senão, seleciona todos os visíveis |
| `clearSelection()` | `new Set()` |

**Armadilha conhecida:** `toggleSelectAll` no estado "todos selecionados" limpa a seleção **global**, não só a da página. Se o usuário selecionou itens na página 1, foi para a 2 e clicou "desmarcar todos", perde a seleção da página 1 também. Além disso, a seleção **não é limpa ao trocar de página, buscar ou trocar o recorte de status** — é possível excluir em massa itens que não estão mais visíveis.

`⚠️ A confirmar:` se manter seleção entre páginas é intencional (permite montar um lote grande) ou é bug latente de exclusão em massa.

### 4.13 Barra de seleção

```tsx
<Card className="border-primary bg-primary/5">
  <CardContent className="py-3 flex items-center justify-between">
    <span className="font-medium">N filtro(s) selecionado(s)</span>
    <Button variant="ghost" size="sm">[X] Limpar seleção</Button>
    {/* direita */}
    <Button variant="destructive" size="sm">[Trash2] Excluir selecionados</Button>
```

Pluralização manual: `filtro{size > 1 ? "s" : ""} selecionado{size > 1 ? "s" : ""}`.
A barra aparece **acima** do bloco de resultados e só quando `selectedIds.size > 0`.

### 4.14 Paginação

```tsx
{!isLoading && data && data.totalPages > 1 && ( ... )}
```

| Elemento | Especificação |
|---|---|
| Container | `flex items-center justify-between mt-6 pt-4 border-t` |
| Texto | `Página {page} de {data.totalPages}` |
| Anterior | `variant="outline" size="sm"`, ícone `ChevronLeft`, `disabled={page === 1}` |
| Próxima | idem, `ChevronRight` à direita, `disabled={page === data.totalPages}` |

**Comentário no código (PORT-2/spec-07):** a paginação foi **içada para fora** dos branches list/grid — antes vivia só no branch da grade e a visualização em lista não paginava (ficava presa nos 20 primeiros).

Não há: seletor de itens por página, salto para página específica, nem indicação de total de itens junto à paginação (o total aparece só no contador acima da lista).

### 4.15 Busca

- Campo único, `placeholder="Buscar filtros..."`;
- escreve direto na URL a cada tecla: `setUrlState({ search: e.target.value || undefined, page: undefined })`;
- **sem debounce** — cada tecla dispara uma nova query key do React Query;
- resetar `page` para `undefined` volta para a página 1;
- campos pesquisados (`searchFields` da factory): `name` e `description`.

`⚠️ A confirmar:` ausência de debounce é intencional (React Query dedupe + staleTime segura) ou deveria ganhar debounce de ~300ms no redesign.

### 4.16 Filtro por Tag (cor)

| Elemento | Especificação |
|---|---|
| Gatilho | `Button variant="outline" gap-2` |
| Conteúdo do gatilho | Se há cores: até **3 bolinhas** de 12px + `+N` em `text-xs` para as demais. Se não há: ícone `Filter` |
| Rótulo | "Tags" |
| Contador | `Badge variant="secondary" h-5 px-1.5 text-xs` com a quantidade |
| Popover | `w-64 p-3`, `align="start"` |
| Cabeçalho do popover | "Filtrar por Tag" + botão ghost "Limpar" (só se há seleção) |
| Grade | `grid grid-cols-2 gap-2` com os 10 itens de `FILTER_COLORS` |
| Item | Botão com bolinha 12px + label truncado; selecionado ganha `ring-2 ring-primary bg-accent` |

Paleta (`src/types/filters.ts`, `FILTER_COLORS` — idêntica à de portfólios):

| # | Hex | Rótulo |
|---|---|---|
| 1 | `#3B82F6` | Azul |
| 2 | `#10B981` | Verde |
| 3 | `#F59E0B` | Amarelo |
| 4 | `#EF4444` | Vermelho |
| 5 | `#8B5CF6` | Roxo |
| 6 | `#EC4899` | Rosa |
| 7 | `#6366F1` | Indigo |
| 8 | `#14B8A6` | Teal |
| 9 | `#F97316` | Laranja |
| 10 | `#6B7280` | Cinza |

**Observação de acessibilidade:** as cores são hex fixos em `style={{ backgroundColor }}`, fora do sistema de tokens CSS — não respondem a tema claro/escuro. E o rótulo textual salva a identificação para quem não distingue cores (bom), mas o filtro se chama "Tags" e mostra cores, sem nenhum nome de tag real.

### 4.17 Ordenação

| Critério (`<option>`) | Valor | Direção aplicada ao selecionar |
|---|---|---|
| A-Z | `name` | `asc` |
| Criação | `created_at` | `desc` |
| Atualização | `updated_at` | `desc` |

O handler troca critério **e** direção de uma vez:

```ts
setUrlState({
  sortBy: newSort,
  sortDirection: newSort === "name" ? "asc" : "desc",
  page: undefined,
});
```

O botão `ArrowUpDown` inverte a direção; seu `title` é "Crescente" / "Decrescente" (mostrando o estado **atual**, não a ação — possível confusão).

---

## 5. Construtor de filtros (FilterBuilder) — anatomia completa

Arquivos: `src/components/filters/FilterBuilderDialog.tsx` (apenas re-export) e `src/components/filters/filter-builder/` (implementação).

```
FilterBuilderDialog.tsx        → re-export de ./filter-builder
filter-builder/
├── index.tsx                  → o Dialog, o form, a validação, o submit
├── FilterHeader.tsx           → nome, descrição, cor, ícone
├── FilterGroupItem.tsx        → grupo recursivo + cabeçalho do grupo + conector + estado vazio
├── FilterRuleItem.tsx         → regra + o seletor de valor (5 variantes) + selos
├── FieldCombobox.tsx          → combobox de campo com busca
├── ValueCombobox.tsx          → combobox de valor (single e multi)
├── SortableItem.tsx           → wrapper de drag & drop
├── DynamicIcon.tsx            → ícone Lucide por nome
├── hooks.ts                   → useMappedFields, useFieldOptionsMap
├── types.ts                   → props e re-exports
└── utils.ts                   → createEmptyRule/Group, isFilterGroup, cleanFieldLabel
```

### 5.0 O dialog

| Aspecto | Especificação |
|---|---|
| Tamanho | `w-[95vw] h-[95vh] overflow-hidden flex flex-col` — **quase tela cheia** |
| Cabeçalho | `DialogTitle` com um quadrado `p-2 rounded-lg bg-primary/10 text-primary` contendo `Filter h-5 w-5`, seguido de "Editar Filtro" ou "Novo Filtro" |
| Descrição | "Atualize as condicoes do filtro" (edição) ou "Defina as condicoes para segmentar contatos e contratos" (criação) |
| Corpo | `DialogBody className="flex-1 overflow-y-auto"` contendo um `<form id="filter-form">` com `space-y-6` |
| Rodapé | `DialogFooter` com **Cancelar** (`variant="outline"`, fecha) e submit (`type="submit" form="filter-form"`) |
| Rótulo do submit | "Criar Filtro" ou "Salvar Alterações"; com `Loader2` girando quando `isSubmitting` |

O botão de submit está **fora** do `<form>` e se liga a ele por `form="filter-form"` — padrão necessário porque o form rola e o rodapé é fixo.

### 5.0.1 Props do dialog

`src/components/filters/filter-builder/types.ts`:

| Prop | Tipo | Default | Papel |
|---|---|---|---|
| `open` | `boolean` | — | Controle externo |
| `onOpenChange` | `(open: boolean) => void` | — | Fechamento |
| `filter` | `FilterDefinition?` | — | Presente = edição (ou duplicação, se `id === ""`) |
| `onFilterCreated` | `(filterId: string) => void` | — | Callback usado por telas que criam filtro inline (ex.: Gestão de Carteira) |
| `defaultUsageScope` | `"common" \| "agent"` | `"common"` | Escopo sugerido por quem abriu |
| `allowAgentScope` | `boolean` | `false` | Mostra ou não o seletor de escopo |

Na `FiltersPage` há **duas instâncias**:

```tsx
<FilterBuilderDialog open={isCreateOpen} onOpenChange={handleFilterDialogClose}
                     defaultUsageScope="common" allowAgentScope />   {/* criar */}

<FilterBuilderDialog open={!!editingFilter} onOpenChange={handleEditDialogClose}
                     filter={editingFilter || undefined} />          {/* editar e duplicar */}
```

### 5.0.2 Ciclo de vida do estado interno

```ts
const [conditions, setConditions] = useState<FilterGroup>(getInitialConditions);
const prevOpenRef = useRef(open);
```

O reset acontece **na transição fechado → aberto**, dentro de `queueMicrotask` (para não atualizar estado durante o render):

| Cenário | O que é resetado |
|---|---|
| Abriu com `filter` | Form ← nome/descrição/cor/ícone/`usage_scope ?? "common"`; condições ← `filter.conditions` se tiver `rules`, senão `createEmptyGroup()` |
| Abriu sem `filter` | Form ← vazio, cor/ícone `null`, `usage_scope ← defaultUsageScope`; condições ← `createEmptyGroup()` |

Comentário no código: "Reabrir o dialog reaplica o escopo do CONTEXTO, não o último usado — abrir em Regras não deve herdar 'common' de antes."

**Consequência:** as condições são estado **local não controlado** por React Hook Form. Fechar o dialog descarta tudo sem aviso — **não há confirmação de descarte**.

### 5.0.3 Fechamento não invalida estatística

```ts
// F2 (perf IAF-4402)
const handleFilterDialogClose = (open) => { if (!open) setIsCreateOpen(false); };
const handleEditDialogClose  = (open) => { if (!open) setEditingFilter(null); };
```

Comentário: fechar o dialog **não** invalida mais o batch de stats. A invalidação incondicional no close re-executava o batch de 20 filtros (20 aggregates + 20 UPDATEs de `cached_*`) mesmo em cancelamento sem edição. Quem invalida é a **mutação**.

---

### 5.1 Cabeçalho do filtro (nome, descrição, escopo, entidade alvo, ativo/inativo)

#### 5.1.1 `FilterHeader` — os 4 campos de identidade

`src/components/filters/filter-builder/FilterHeader.tsx`. Layout: `grid grid-cols-4 gap-4`, duas linhas.

| Posição | Campo | Componente | Obrigatório | Placeholder / opções |
|---|---|---|---|---|
| Linha 1, cols 1–3 | **Nome do Filtro** | `Input` (register `name`) | **Sim** | `Ex: Inadimplentes > 30 dias` |
| Linha 1, col 4 | **Cor** | `Select` controlado por `Controller` | Não | "Nenhuma" + 10 cores de `FILTER_COLORS` |
| Linha 2, cols 1–3 | **Descricao (opcional)** | `Input` (register `description`) | Não | `Descreva o proposito deste filtro...` |
| Linha 2, col 4 | **Icone** | `Select` controlado | Não | "Nenhum" + 10 ícones de `FILTER_ICONS` |

Detalhes:
- o erro de nome aparece abaixo do input: `<p className="text-sm text-destructive">{errors.name.message}</p>` com o texto **"Nome e obrigatorio"** (sem acento, do schema Zod);
- cor e ícone usam a sentinela `"__none__"` internamente, convertida para `null` no `onChange` (shadcn `Select` não aceita `value=""`);
- o `SelectValue` renderiza a **prévia** do item escolhido: bolinha 16px + nome da cor; ícone + nome do ícone;
- a descrição é um `Input` de uma linha, **não** um `Textarea` (diferente do `PortfolioDialog`, que usa `Textarea rows={2}`).

Catálogo de ícones (`src/types/filters.ts`, `FILTER_ICONS`):

| Valor (Lucide) | Rótulo |
|---|---|
| `ListFilter` | Filtro |
| `Tag` | Tag |
| `Target` | Alvo |
| `Star` | Estrela |
| `Flag` | Bandeira |
| `Bookmark` | Marcador |
| `CircleAlert` | Alerta |
| `CircleCheck` | Verificado |
| `Clock` | Relógio |
| `TrendingUp` | Tendência |

`DynamicIcon` (`filter-builder/DynamicIcon.tsx`) resolve pelo mapa `icons` do lucide-react e **retorna `null`** se o nome não existir. Já o `DynamicIcon` local da `FiltersPage` faz fallback para o ícone `Filter`. **Duas implementações com fallbacks diferentes** no mesmo domínio.

#### 5.1.2 Escopo de uso — o bloco condicional

Renderizado só quando `allowAgentScope && !isEditing`. `data-testid="filter-usage-scope"`.

| Elemento | Texto literal |
|---|---|
| Label | **Onde este filtro aparece** |
| Opção 1 (título) | **Somente Agentes de IA** |
| Opção 1 (corpo) | "Aparece apenas em Regras e Conhecimento do agente. Não polui campanhas, réguas, portfólios nem blocklist." |
| Opção 2 (título) | **Comum (todos os lugares)** |
| Opção 2 (corpo) | "Fica disponível também em campanhas, réguas, portfólios, blocklist e dashboard." |
| Nota de rodapé | "O escopo não pode ser alterado depois. Para mudar, duplique o filtro." |

Visual: `RadioGroup` com `gap-2`; cada opção é um `<label>` com `flex cursor-pointer items-start gap-3 rounded-lg border p-3 hover:bg-accent/50`, o `RadioGroupItem` com `mt-0.5`.

**Ordem das opções:** "Somente Agentes de IA" aparece **primeiro**, mesmo sendo o caso minoritário. `⚠️ A confirmar:` a ordem é intencional (o bloco só aparece quando aberto a partir da configuração de IA, onde `agent` é o esperado) — parece coerente, mas o default vem de `defaultUsageScope`, que pode ser `common`.

Em edição, o bloco é substituído por uma linha de texto (`data-testid="filter-usage-scope-readonly"`):

> Escopo: somente Agentes de IA | comum (todos os lugares) — imutável após a criação.

`<p className="text-xs text-muted-foreground">`.

#### 5.1.3 Entidade alvo — **não existe controle**

Não há nenhum campo de "entidade alvo" no construtor. O `target_entity` é **inteiramente derivado** das tabelas usadas nas condições (§2.9), no hook. O usuário só o influencia indiretamente, escolhendo "Suprimento" no dropdown de tabela de alguma regra.

**Lacuna de UX:** o usuário não vê em lugar nenhum se o filtro que ele está montando é "de contrato" ou "de suprimento". Só descobre quando erra e recebe o toast de filtro misto. Um redesign pode expor isso como um indicador derivado (read-only) no cabeçalho.

#### 5.1.4 Ativo/inativo — **não existe no construtor**

O toggle de ativação vive **só na listagem** (menu da lista + Switch do card). O construtor não expõe `is_active`.

#### 5.1.5 Separador

Entre o bloco de identidade/escopo e o bloco de condições há um `<Separator />`.

#### 5.1.6 Cabeçalho do bloco "Condicoes"

```tsx
<ListFilter className="h-4 w-4 text-muted-foreground" />
<Label className="text-base">Condicoes</Label>
<p className="text-xs text-muted-foreground mt-1">
  Combine condicoes e grupos com diferentes logicas (E/OU)
</p>
```

O `flex items-center justify-between` deste cabeçalho tem o lado direito **vazio** — há espaço reservado para ações que não existem (ex.: "limpar tudo", "pré-visualizar").

---

### 5.2 Grupo de regras (lógica E/OU, aninhamento, botões)

`src/components/filters/filter-builder/FilterGroupItem.tsx` — componente **recursivo**.

#### 5.2.1 Props

| Prop | Tipo | Default | Papel |
|---|---|---|---|
| `group` | `FilterGroup` | — | O nó |
| `onUpdate` | `(group: FilterGroup) => void` | — | Devolve o nó inteiro modificado (imutável) |
| `onRemove` | `() => void` | — | Só existe em nós não-raiz |
| `depth` | `number` | `0` | Profundidade; a raiz é chamada com `depth={0}` |
| `canRemove` | `boolean` | `false` | `group.rules.length > 1` do **pai** |
| `mappedFields` | `MappedFieldsByEntity` | — | Catálogo de campos por entidade |
| `fieldOptionsMap` | `Record<string, ValueOption[]>` | — | Opções de valor por campo |

#### 5.2.2 Container do grupo

```tsx
<div className={cn(
  "rounded-lg p-3 space-y-3",
  depth > 0 && "border-l-4",
  depth > 0 && colorClass,
  group.negate === true && "ring-2 ring-destructive/30"
)}>
```

A raiz (`depth === 0`) **não tem borda nem cor de fundo** — é só um contêiner. A partir do nível 1, o grupo ganha borda esquerda de 4px e fundo tênue.

Cores por nível (`LEVEL_COLORS`, ciclo de 4):

| depth % 4 | Classe |
|---|---|
| 0 | `border-l-primary/50 bg-muted/20` |
| 1 | `border-l-blue-500/50 bg-blue-500/5` |
| 2 | `border-l-purple-500/50 bg-purple-500/5` |
| 3 | `border-l-amber-500/50 bg-amber-500/5` |

#### 5.2.3 Nível em texto (redundância de acessibilidade)

```tsx
{depth > 0 && (
  <span className="text-xs font-medium text-muted-foreground uppercase"
        title={`Grupo aninhado no nivel ${depth}`}>
    Grupo · nivel {depth}
  </span>
)}
```

Comentário no código: "a cor cíclica sozinha não basta a partir do 5º nível (`LEVEL_COLORS` tem 4 entradas) e nunca bastou para quem não distingue cores. Por isso o cabeçalho passa a carregar o NÍVEL em texto — o sinal visual é redundante, não substituído."

**Princípio a preservar no redesign:** profundidade tem de ser legível sem depender de cor.

#### 5.2.4 Cabeçalho do grupo — todos os controles

Layout: `flex items-center justify-between gap-2`.

**Lado esquerdo (da esquerda para a direita):**

| # | Elemento | Especificação |
|---|---|---|
| 1 | "Grupo · nivel N" | Só com `depth > 0` |
| 2 | Botão **NÃO (NOT)** | `px-2 py-1 rounded text-xs font-medium border`. Ativo: `bg-destructive/10 text-destructive border-destructive/30`. Inativo: `bg-muted text-muted-foreground border-transparent hover:text-foreground`. `title` alterna entre "Negar este grupo (NOT)" e "Remover negacao do grupo" |
| 3 | `HelpTip topic="builder_negate"` | `side="bottom" align="start"` |
| 4 | Seletor E/OU | `flex items-center gap-1 bg-muted rounded-md p-0.5` com dois botões. Ativo: `bg-background text-foreground shadow-sm`. Inativo: `text-muted-foreground hover:text-foreground`. Rótulos: **"E (AND)"** e **"OU (OR)"** |
| 5 | `HelpTip topic="builder_group_logic"` | `side="bottom" align="start"` |

**Lado direito:**

| # | Elemento | Condição | Especificação |
|---|---|---|---|
| 1 | Botão **Condicao** | `depth > 0` | `variant="ghost" size="sm"`, ícone `Plus h-4 w-4 mr-1` |
| 2 | Botão **Grupo** | `depth + 1 < 20` | `variant="ghost" size="sm"`, ícone `FolderPlus h-4 w-4 mr-1` |
| 2b | Aviso de teto | `depth + 1 >= 20` | `<span className="text-xs text-muted-foreground px-2">Limite de 20 niveis atingido</span>` |
| 3 | Botão remover | `canRemove && onRemove` | `variant="ghost" size="sm"`, ícone `Trash2 h-4 w-4`, classe `text-destructive hover:text-destructive` |

**Não há** botão de duplicar grupo, nem de colapsar grupo, nem de mover para cima/baixo por clique.

#### 5.2.5 Mutações do grupo

Todas imutáveis, via `onUpdate`:

| Ação | Implementação |
|---|---|
| `addRule()` | `rules: [...group.rules, createEmptyRule()]` — sempre **no fim** |
| `addGroup()` | `rules: [...group.rules, createEmptyNestedGroup()]` — grupo novo já vem com 1 regra vazia |
| `removeItem(id)` | `rules: group.rules.filter(r => r.id !== id)` |
| `updateRule(id, updates)` | `map` com merge raso; ignora nós que são grupo (`!isFilterGroup(r)`) |
| `updateNestedGroup(id, g)` | `map` substituindo o nó inteiro |
| `changeLogic(logic)` | `{ ...group, logic }` |
| `toggleNegate()` | `{ ...group, negate: !group.negate }` |

#### 5.2.6 Conector lógico entre itens

```tsx
{index > 0 && <LogicConnector logic={group.logic} />}

function LogicConnector({ logic }) {
  return (
    <div className="flex items-center justify-center py-1">
      <span className="text-xs font-medium text-muted-foreground uppercase px-2">
        {logic === "and" ? "E" : "OU"}
      </span>
    </div>
  );
}
```

Renderizado **antes** de cada item a partir do segundo, **dentro** do `SortableItem` — ou seja, o conector viaja junto com o item quando arrastado, o que é visualmente correto (o conector sempre pertence ao item que o sucede).

O conector mostra só "E"/"OU" (sem o termo em inglês), enquanto o seletor no cabeçalho mostra "E (AND)"/"OU (OR)".

#### 5.2.7 Estado vazio do grupo

```tsx
{group.rules.length === 0 && <EmptyGroupState depth={depth} ... />}
```

| Elemento | Especificação |
|---|---|
| Container | `text-center py-4 text-muted-foreground border border-dashed rounded-lg` |
| Texto | `depth === 0` → **"Nenhum grupo definido"**; senão → **"Nenhuma condicao definida"** |
| Ações | `Button variant="link" size="sm"`: "Adicionar condicao" (só `depth > 0`) e "Adicionar grupo" (só se `depth + 1 < 20`) |

#### 5.2.8 Aninhamento — o que a UI permite hoje

| Pergunta | Resposta |
|---|---|
| Profundidade máxima | 20 níveis (`MAX_FILTER_DEPTH`); o botão some no nível 19 e a tela explica |
| Grupo pode conter grupo? | Sim, arbitrariamente |
| Grupo pode conter regras e grupos misturados? | Sim — a ordem é a de inserção/arraste |
| Raiz pode conter regra? | Não pela UI (§2.4) |
| Há limite de regras por grupo? | Não individualmente; só o teto global de 500 nós |
| Grupo vazio é válido? | O Zod exige `.min(1, "Grupo deve ter pelo menos uma regra")` — mas **a UI permite chegar a zero** e só falha no save (§5.5) |

---

### 5.3 Regra individual (campo, operador, valor) e seus controles

`src/components/filters/filter-builder/FilterRuleItem.tsx`.

#### 5.3.1 Container da regra

```tsx
<div className={cn(
  "flex items-center gap-2 p-2 border rounded-lg bg-background flex-wrap",
  rule.negate === true && "ring-2 ring-destructive/30"
)}>
```

Linha única que **quebra** (`flex-wrap`) em telas estreitas. Os controles, na ordem:

```
[NÃO (NOT)] [select Tabela] [?aging] [FieldCombobox] [select Operador] [Valor…] [🗑]
```

#### 5.3.2 Controle 1 — botão NÃO (NOT)

Idêntico em estilo ao do grupo (§5.2.4, item 2), com `title` alternando entre "Negar esta regra (NOT)" e "Remover negacao da regra". **Sem HelpTip** (diferente do grupo).

#### 5.3.3 Controle 2 — seletor de Tabela (entidade)

`<select className="w-32 rounded-md border bg-background px-2 py-1.5 text-sm">` — HTML nativo, 8 opções:

| `value` | Rótulo exibido |
|---|---|
| `contacts` | Contato |
| `contracts` | Contrato |
| `titles` | Titulo |
| `supplies` | Suprimento |
| `supply_titles` | Titulo de Suprimento |
| `data_sources` | Fonte de Dados |
| `actions` | Acao |
| `aging` | Aging |

**Efeito colateral da troca de tabela:**

```ts
onUpdate({
  table: newTable,
  field: newFields[0]?.field || "",   // pula para o PRIMEIRO campo da nova tabela
});
```

O **operador e o valor não são resetados**. Trocar de "Contato → Nome (text)" para "Título" seleciona o primeiro campo de título; se o operador atual não for válido para o novo tipo, ele fica inconsistente até o usuário tocar no campo. `⚠️ A confirmar:` isso é um bug latente — o reset de operador só acontece no `onChange` do `FieldCombobox`, não no do seletor de tabela.

**Nota:** "Aging" é o rótulo cru em inglês no meio de rótulos em português.

#### 5.3.4 HelpTip condicional de Aging

```tsx
{rule.table === "aging" && <HelpTip topic="aging_bucket" side="bottom" align="start" />}
```

Único ajuda contextual que aparece/some conforme a seleção.

#### 5.3.5 Controle 3 — `FieldCombobox` (campo)

`src/components/filters/filter-builder/FieldCombobox.tsx`.

| Aspecto | Especificação |
|---|---|
| Gatilho | `Button variant="outline" role="combobox" aria-expanded={open} className="min-w-52 justify-between text-left font-normal"` |
| Conteúdo | Rótulo limpo (`cleanFieldLabel`) em `line-clamp-1` + `Badge variant="secondary" text-[10px]` **"Custom"** se `field.isCustom` |
| Placeholder | `"Selecionar campo..."` — ou **`"Sem campos mapeados"`** quando `availableFields.length === 0` |
| Ícone | `ChevronsUpDown ml-1 h-4 w-4 shrink-0 opacity-50` |
| Popover | `w-80 p-0`, `align="start"` |
| Busca | `CommandInput placeholder="Buscar campo..."` — filtro nativo do `cmdk` (`shouldFilter` default, casando por `value={cleanFieldLabel(field.label)}`) |
| Vazio | `"Nenhum campo encontrado."` |
| Item | `Check` (visível só no selecionado) + rótulo + `Badge variant="outline" text-[10px]` "Custom" |
| Key do item | `custom-${field}` ou `standard-${field}` — evita colisão entre campo padrão e customizado de mesmo nome |

`cleanFieldLabel` (`utils.ts`) remove os prefixos `"Custom Fields."` e `"custom."` do rótulo.

**Efeito da seleção de campo:**

```ts
onChange={(field, type) => {
  const newOperators = getOperatorsForField(type);
  const currentOperatorValid = newOperators.includes(rule.operator);
  onUpdate({
    field,
    operator: currentOperatorValid ? rule.operator : newOperators[0],
  });
}}
```

O operador é **preservado se continuar válido** para o novo tipo; senão cai no **primeiro operador da lista** daquele tipo. O **valor não é resetado** — trocar de um campo `text` para um `number` mantém o valor de texto anterior.

`⚠️ A confirmar:` manter o valor ao trocar o tipo do campo produz valores inválidos silenciosos (ex.: `value: "Silva"` num campo numérico). Não há validação que barre isso no save.

**Não há agrupamento por categoria** dentro do combobox — é uma lista única ordenada por rótulo (a ordenação vem de `useMappedFilterFields`, que faz `sort((a,b) => a.label.localeCompare(b.label, "pt-BR"))` sobre os campos customizados/mapeados; os campos do registry entram na ordem de declaração e os customizados são **concatenados depois**).

`⚠️ A confirmar:` a ordem final da lista é "campos do registry na ordem de declaração, depois os customizados em ordem alfabética" — não é alfabética global. Verificar se é intencional.

#### 5.3.6 Controle 4 — seletor de Operador

`<select className="w-36 rounded-md border bg-background px-2 py-1.5 text-sm">` — HTML nativo.

Opções: `getOperatorsForFieldType(fieldType)` renderizadas com `OPERATOR_LABELS[op]`. Ver §7 para o catálogo completo.

Quando o campo ainda não foi escolhido, `getFieldType` devolve `"text"` (fallback) — então o select já mostra os 7 operadores de texto.

#### 5.3.7 Controle 5 — o input de valor (5 variantes)

O valor é renderizado por `FilterValueInput`, e **não é renderizado** para operadores unários:

```tsx
{!["is_null","is_not_null","is_empty","is_not_empty"].includes(rule.operator) && (
  <FilterValueInput ... />
)}
```

Ordem de decisão dentro de `FilterValueInput`:

| Ordem | Condição | Controle renderizado |
|---|---|---|
| 1 | `operator === "between"` | **Faixa** — dois `Input` com "e" no meio |
| 2 | `field === "seals"` e operador em `in\|not_in\|all_of` e tabela em `contacts\|contracts\|titles` | **`SealsValueInput`** — popover de selos |
| 3 | `fieldType === "boolean"` | **Select Sim/Não** |
| 4 | Há opções em `fieldOptionsMap` | **`ValueCombobox`** (single ou multi) |
| 5 | fallback | **`Input`** livre (`text`/`number`/`date`) |

##### Variante 1 — faixa ("entre")

```tsx
const arr = Array.isArray(rule.value) ? rule.value : ["", ""];
```

| Elemento | Especificação |
|---|---|
| Container | `flex items-center gap-1 flex-1 min-w-40` |
| Input mínimo | `placeholder="mín."` |
| Separador | `<span className="text-xs text-muted-foreground">e</span>` |
| Input máximo | `placeholder="máx."` |
| `type` dos inputs | `date` se o campo é data; `number` se numérico; senão `text` |
| Valor salvo | **Array de 2 posições**: `[min, max]` |
| Parsing | `fieldType === "number"` → `parseFloat` (ou `""` se vazio); senão string crua |

Comentário no código (BLD-5): "'entre' precisa de DOIS valores — `value = [min, max]`. O compiler exige `jsonb_array_length >= 2` e o `evaluate-filter` retorna false para não-array; um input único gerava escalar e a regra era dropada."

**Sem validação de min ≤ max na UI.**

##### Variante 2 — selos (`SealsValueInput`)

| Aspecto | Especificação |
|---|---|
| Escopo derivado da tabela | `contacts → "contact"`, `contracts → "contract"`, `titles → "title"` |
| Fonte | `useSealCatalog(scope)` |
| Gatilho | `Button variant="outline" size="sm" className="min-w-40 justify-start font-normal h-9"` |
| Gatilho vazio | `<span className="text-muted-foreground">Selecionar selos...</span>` |
| Gatilho com seleção | Até **2 `SealBadge`** + `+N` em `text-xs text-muted-foreground` |
| Popover | `w-72 p-0`, `align="start"`; lista com `max-h-64 overflow-y-auto p-1` |
| Item | Botão full-width com `SealBadge` e `Check h-4 w-4` quando selecionado; selecionado ganha `bg-accent` |
| Catálogo vazio | `"Nenhum selo cadastrado neste escopo"` (`px-2 py-3 text-sm text-muted-foreground text-center`) |
| Valor salvo | `string[]` de **UUIDs** de `seal_catalog` |

**Sem campo de busca** dentro do popover de selos — se a org tiver 50 selos, é rolagem pura.

##### Variante 3 — booleano

```tsx
<select className="flex-1 min-w-24 rounded-md border bg-background px-2 py-1.5 text-sm">
  <option value="">Selecionar...</option>
  <option value="true">Sim</option>
  <option value="false">Não</option>
</select>
```

O valor é salvo como **string** `"true"`/`"false"`, não booleano. `⚠️ A confirmar:` o compilador SQL aceita a string; o tipo `FilterValue` também aceita boolean — há inconsistência de tipo gravado entre o que a UI produz e o que o schema permite.

##### Variante 4 — `ValueCombobox`

`src/components/filters/filter-builder/ValueCombobox.tsx`. Modo definido por:

```ts
const isMulti = ["in", "nin", "not_in", "all_of"].includes(rule.operator);
```

**Lookup das opções (BLD-14):**

```ts
const fieldOptions =
  fieldOptionsMap[`${rule.table ?? "contacts"}:${rule.field}`] ?? fieldOptionsMap[rule.field];
```

Chave com escopo de tabela primeiro (desambigua `titles.status` × `contracts.status`), com fallback para a chave crua.

**Modo múltiplo:**

| Aspecto | Especificação |
|---|---|
| Container | `flex-1 min-w-32` |
| Gatilho | `Button variant="outline" role="combobox" className="w-full justify-between text-left font-normal min-h-9 h-auto"` |
| Selecionados | Até **3 `Badge variant="secondary" text-xs`**, cada um com botão `X h-3 w-3` (`hover:text-destructive`) para remover sem abrir o popover |
| Excedente | `Badge variant="outline"` com `+N` |
| Placeholder | `"Selecione valores..."` |
| Popover | `w-64 p-0`, `align="start"` |
| Busca | `Command shouldFilter={false}` + filtro manual por `label` **ou** `value` (case-insensitive) |
| Vazio | `"Nenhuma opção encontrada."` |
| Item | `Check` + `option.label`; clique alterna |

**Modo único:**

| Aspecto | Especificação |
|---|---|
| Gatilho | Mostra `selectedOption.label` → senão o valor cru → senão o placeholder em `text-muted-foreground` |
| Placeholder | `"Selecione ou digite..."` |
| Busca | `CommandInput placeholder="Buscar ou digitar..."` |
| **Valor livre** | Quando a busca não casa nada, o `CommandEmpty` vira um botão: **`Usar "{search}"`** — grava o texto digitado como valor |

O valor livre existe **só no modo único**. No modo múltiplo, se nada casa, o usuário só vê "Nenhuma opção encontrada." e não consegue adicionar um valor fora da lista.

##### Variante 5 — Input livre

```tsx
<Input
  value={rule.value != null ? String(rule.value) : ""}
  placeholder="Valor..."
  type={fieldType === "number" ? "number" : fieldType === "date" ? "date" : "text"}
  className="flex-1 min-w-24"
/>
```

Parsing: `number` → `parseFloat` (ou `""` se vazio); demais → string crua.

#### 5.3.8 Controle 6 — remover regra

```tsx
{canRemove && (
  <Button type="button" variant="ghost" size="sm" onClick={onRemove}>
    <Trash2 className="h-4 w-4 text-destructive" />
  </Button>
)}
```

`canRemove = group.rules.length > 1` — **a última regra de um grupo não pode ser removida** pelo botão. Para esvaziar, é preciso remover o grupo inteiro.

`⚠️ A confirmar:` isso significa que o estado "grupo com 0 regras" (que o `EmptyGroupState` renderiza) é **inalcançável pela UI** em grupos criados por ela — só apareceria em dados legados/importados. O `EmptyGroupState` é, na prática, código defensivo.

#### 5.3.9 De onde vêm os campos (`useMappedFields`)

`src/components/filters/filter-builder/hooks.ts`:

```ts
baseFields = { contacts, contracts, titles, supplies, supply_titles, data_sources, actions, aging }
          ← FILTER_FIELDS_REGISTRY (estático, src/lib/filters/fields.ts)

if (customFieldsData)  // ← useMappedFilterFields()
  retorna { [entidade]: [...baseFields[entidade], ...customFieldsData[entidade]] }
  // EXCETO aging, que NUNCA recebe campos customizados
```

`useMappedFilterFields` (`src/hooks/etl/useCustomFields.ts`) monta a lista de campos dinâmicos a partir de:

1. **`etl_pipelines.field_mapping`** dos pipelines ativos — campos efetivamente mapeados na importação;
2. **`custom_field_definitions`** ativos — rótulo (`display_name`) e tipo (`field_type`) corretos;
3. **campos de sistema** sempre disponíveis, por entidade:

| Entidade | Campos de sistema injetados |
|---|---|
| `contacts` | `has_pnp`, `seals` |
| `contracts` | `days_overdue`, `has_pnp`, `safra_days`, `min_open_installment`, `min_open_installment_disponivel`, `seals` |
| `titles` | `days_overdue`, `seals` |
| `supplies` | `days_overdue`, `seals` |
| `supply_titles` | `days_overdue`, `seals` |

Campos customizados recebem a chave **`custom.<nome>`** e `isCustom: true` (é isso que pinta o badge "Custom" no combobox).

Se o campo mapeado não é coluna real da entidade nem tem rótulo padrão, vira `custom.<campo>` com rótulo derivado (`snake_case` → Title Case).

Erro no carregamento é apenas logado no console (`console.error("[useMappedFields] Failed to load custom fields:", error)`) — **a UI não mostra nada**. O usuário vê a lista só com os campos estáticos, sem saber que os customizados falharam.

#### 5.3.10 De onde vêm as opções de valor (`useFieldOptionsMap`)

Mesma `hooks.ts`. Ordem de montagem (**quem vem depois vence**):

| Ordem | Origem | Chaves geradas |
|---|---|---|
| 1 | `getStaticFieldOptionsMap()` (registry) | `table:field` **e** `field` para todo campo com `options` |
| 2 | `useStandardValues()` — `field_type === "status"` | `status`, `titles:status` |
| 3 | `useStandardValues()` — `field_type === "modality"` | `modality`, `contracts:modality` |
| 4 | `usePipelinesForSelect()` | `contact_source_pipelines`, `contract_source_pipelines` (usa `p.label` como value **e** label) |
| 5 | `useDataSources()` | `contact_data_sources`, `contract_data_sources` (usa `ds.name` como value e label) |
| 6 | `useCustomFieldOptions()` | `custom.<campo>` para campos com ≤ 50 valores distintos (ou marcados como `list_fields`) |
| 7 | `useTagCatalog()` | `tags` (value = `t.name`, label = `t.label`) |

**Sobre `useCustomFieldOptions`:** lê os `unique_values` pré-computados em `data_sources.query_config` (não consulta a `vw_titles_live` em runtime). Critério de inclusão: campo explicitamente marcado como `list_fields` nas `transform_rules`, **ou** com **≤ 50 valores distintos**. Valores ordenados com `localeCompare(pt-BR)`.

**Campos sem entrada no mapa caem no Input livre.** É por isso que `owner_pipeline_id` (declarado como `select` no registry, mas **sem `options`** e sem override dinâmico correspondente) renderiza como campo de texto livre.

`⚠️ A confirmar:` `owner_pipeline_id` é `type: "select"` no registry mas nenhuma das 7 fontes acima popula a chave `owner_pipeline_id` nem `titles:owner_pipeline_id`. O usuário teria que digitar um UUID de pipeline à mão. Idem `contracts.modality` quando a org não tem `standard_values` de modalidade.

---

### 5.4 Interações (arrastar, duplicar, remover, colapsar)

#### 5.4.1 Arrastar e soltar

**Onde:** dentro de **cada grupo**, reordenando seus filhos diretos (regras e subgrupos, misturados).

Configuração (`FilterGroupItem.tsx`):

```ts
const sensors = useSensors(
  useSensor(PointerSensor, { activationConstraint: { distance: 8 } }),
  useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates })
);

<DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
  <SortableContext items={ruleIds} strategy={verticalListSortingStrategy}>
```

| Aspecto | Valor |
|---|---|
| Ativação por ponteiro | Precisa mover **8px** antes de iniciar o arraste (evita disparar em cliques) |
| Teclado | `KeyboardSensor` com `sortableKeyboardCoordinates` — **arraste por teclado funciona** |
| Detecção de colisão | `closestCenter` |
| Estratégia | `verticalListSortingStrategy` (lista vertical) |
| Reordenação | `arrayMove(group.rules, oldIndex, newIndex)` |
| Escopo | **Só dentro do mesmo grupo.** Não existe `DndContext` compartilhado entre níveis |

**Não é possível arrastar uma regra de um grupo para outro.** Cada `FilterGroupItem` cria seu próprio `DndContext` — inclusive os aninhados, o que gera contextos DnD encaixados.

`⚠️ A confirmar:` `DndContext` aninhado é um padrão frágil no dnd-kit (o evento pode ser capturado pelo contexto interno). Na prática funciona porque os `SortableContext` são disjuntos, mas mover item entre grupos é uma funcionalidade ausente que o redesign provavelmente quer.

#### 5.4.2 A alça de arraste (`SortableItem`)

`src/components/filters/filter-builder/SortableItem.tsx`:

```tsx
<div ref={setNodeRef} style={{transform, transition}}
     className={cn("relative", isDragging && "z-50 opacity-90")}>
  <div className="flex items-start gap-1">
    {!disabled && (
      <button type="button" className={cn(
        "p-1.5 mt-2 rounded cursor-grab text-muted-foreground hover:text-foreground hover:bg-muted transition-colors",
        isDragging && "cursor-grabbing")}
        {...attributes} {...listeners}>
        <GripVertical className="h-4 w-4" />
      </button>
    )}
    <div className="flex-1">{children}</div>
  </div>
</div>
```

| Aspecto | Comportamento |
|---|---|
| Alça | Ícone `GripVertical`, à **esquerda** do item, alinhado ao topo (`mt-2`) |
| `disabled` | `group.rules.length <= 1` — **a alça desaparece quando o grupo tem um único filho** |
| Feedback ao arrastar | `z-50 opacity-90` no item; cursor vira `grabbing` |
| Alça `aria-*` | Vem do `{...attributes}` do dnd-kit (`role="button"`, `aria-roledescription="sortable"`, `tabIndex`, `aria-describedby`) |
| Sem alça | Quando `disabled`, o item perde o recuo da alça — **o alinhamento horizontal muda** entre grupo com 1 filho e com 2+ |

#### 5.4.3 Duplicar

**Não existe duplicação dentro do construtor.** Não há botão para duplicar regra nem grupo. A única duplicação do domínio é a do **filtro inteiro**, na listagem (§4.11).

Lacuna clara: montar 5 regras parecidas exige criar cada uma do zero.

#### 5.4.4 Remover

| Alvo | Controle | Condição |
|---|---|---|
| Regra | `Trash2` ghost no fim da linha | `canRemove` = pai tem > 1 filho |
| Grupo aninhado | `Trash2` ghost no fim do cabeçalho | `canRemove` = pai tem > 1 filho, **e** `onRemove` existe |
| Grupo raiz | — | Nunca removível (não recebe `onRemove`) |

**Não há confirmação** ao remover regra ou grupo, e **não há desfazer**. Remover um grupo com 10 regras é um clique irreversível.

#### 5.4.5 Colapsar

**Não existe colapso/expansão de grupos.** Toda a árvore fica sempre expandida. Num filtro grande (o limite é 500 nós), o dialog de 95vh vira uma rolagem longa sem nenhuma âncora, minimapa ou sumário.

Este é, provavelmente, o maior ganho disponível para o redesign.

#### 5.4.6 Outras interações ausentes

| Interação | Existe? |
|---|---|
| Desfazer / refazer | Não |
| Converter regra em grupo (envolver) | Não |
| Extrair grupo (desembrulhar) | Não |
| Copiar/colar regra | Não |
| Ver o SQL / pseudo-linguagem gerada | Não (só a prévia, em outro modal) |
| Prévia dentro do construtor | **Não** — é preciso salvar e usar "Visualizar" |
| Contador de nós / profundidade atual | Não |
| Atalhos de teclado | Só os do dnd-kit e os nativos do `Command` |

---

### 5.5 Validações e mensagens de erro

#### 5.5.1 Validação do formulário (Zod + React Hook Form)

`src/components/filters/filter-builder/index.tsx`:

```ts
const filterSchema = z.object({
  name: z.string().min(1, "Nome e obrigatorio"),
  description: z.string().optional(),
  color: z.string().nullable().optional(),
  icon: z.string().nullable().optional(),
  usage_scope: z.enum(["common", "agent"]).optional(),
});
```

| Campo | Regra | Mensagem | Onde aparece |
|---|---|---|---|
| `name` | mínimo 1 caractere | **"Nome e obrigatorio"** | Abaixo do input, `text-sm text-destructive` |
| demais | nenhuma | — | — |

**As condições NÃO passam pelo schema do formulário** — são estado local. Nenhuma regra impede salvar um filtro com campo vazio, operador incompatível ou valor em branco.

#### 5.5.2 Validação bloqueante: filtro misto

Primeira coisa dentro do `onSubmit` (§2.10). Toast destrutivo, `return` antes de qualquer mutação.

#### 5.5.3 Validação de limites da árvore

Lançada por `assertFilterTreeLimits` dentro de `transformCreate`/`transformUpdate` (§2.6). A exceção sobe até o `catch` do `onSubmit`, que a transforma em toast:

```ts
catch (error) {
  logError(error, { source: "FilterBuilderDialog", action: "save filter" });
  toast({ variant: "destructive", title: "Erro ao salvar filtro", description: getErrorMessage(error) });
}
```

| Título do toast | Descrição |
|---|---|
| **Erro ao salvar filtro** | `getErrorMessage(error)` — a mensagem real (nunca `[object Object]`) |

Comentário no código (PORT-11/spec-07): "toast destrutivo com a mensagem real em vez de `alert()`".

#### 5.5.4 Validação do schema de grupo (Zod, camada de borda)

`FilterGroupSchema` exige:

| Campo | Regra | Mensagem |
|---|---|---|
| `rules` | `.min(1, ...)` | **"Grupo deve ter pelo menos uma regra"** |
| `field` (na regra) | `.min(1, ...)` | **"Campo obrigatorio"** |
| `operator` | enum de 17 valores | erro padrão do Zod |

**Mas esse schema não é aplicado no caminho de save da UI.** `transformCreate`/`transformUpdate` chamam apenas `assertFilterTreeLimits` (profundidade/nós/ciclo), **não** `BoundedFilterGroupSchema.parse`. Ou seja: **"Campo obrigatorio" e "Grupo deve ter pelo menos uma regra" nunca chegam ao usuário desta tela.**

`⚠️ A confirmar:` um filtro salvo com `field: ""` é aceito pelo frontend. O que acontece no compilador SQL depende do backend (provavelmente vira predicado `FALSE` pelo fail-closed de 01/09/2026). Vale confirmar com o time se a UI deveria barrar antes.

#### 5.5.5 Inventário completo de validações ausentes

| O que deveria ser validado | Hoje | Consequência |
|---|---|---|
| Campo selecionado em toda regra | Não | Regra `field: ""` salva |
| Valor preenchido (operador binário) | Não | Regra com `value: ""` salva |
| Valor compatível com o tipo | Não | Texto num campo numérico |
| Operador compatível após troca de **tabela** | Não | Combinação inválida persiste |
| `between` com min ≤ max | Não | Faixa invertida salva |
| `between` com os dois valores | Não | Array `["", ""]` salva |
| Grupo com pelo menos 1 filho | Não (na UI) | Só via Zod, que não roda aqui |
| Nome duplicado | Não | Dois filtros com o mesmo nome |
| Contagem de nós antes do teto | Não | Descobre só ao salvar |
| Descarte de alterações não salvas | Não | Fecha e perde tudo |

#### 5.5.6 Mensagens de erro do domínio — tabela consolidada

| Contexto | Tipo | Título | Corpo |
|---|---|---|---|
| Nome vazio | Inline | — | Nome e obrigatorio |
| Filtro misto | Toast destrutivo | Filtro misto nao e permitido | Este filtro combina condicoes de Suprimento com condicoes de Contrato/Titulo. Um filtro avalia um mundo por vez — separe em dois filtros. |
| Falha no save | Toast destrutivo | Erro ao salvar filtro | *(mensagem real do erro)* |
| Ciclo na árvore | Toast destrutivo (via save) | Erro ao salvar filtro | Filtro inválido: referência circular entre grupos de condições. |
| Profundidade | Toast destrutivo (via save) | Erro ao salvar filtro | Filtro inválido: profundidade de N grupos excede o limite de 20. |
| Nós demais | Toast destrutivo (via save) | Erro ao salvar filtro | Filtro inválido: N condições/grupos excedem o limite de 500. |
| Falha ao ativar/desativar | Toast destrutivo | Erro ao alterar status do filtro | *(mensagem real)* |
| Falha ao excluir (individual/bulk) | Toast destrutivo | Erro ao excluir | `getDeleteErrorMessage(error)` |
| Falha ao carregar a lista | Tela inteira de erro | Erro ao carregar filtros | `getErrorMessage(error)` + botão "Tentar novamente" |
| Estatística de um filtro falhou | Ícone + tooltip | Não foi possível calcular os números deste filtro. | `stats.errorMessage` |
| Falha na prévia | Bloco na dialog | Erro ao carregar prévia | *(sem detalhe)* |
| Falha nas colunas da amostra | Linha na tabela | Não foi possível consultar as colunas da amostra. | + botão "Tentar novamente" |
| Falha ao carregar contatos do filtro | Bloco na dialog | Erro ao carregar contatos | `(error as Error)?.message ?? "Erro desconhecido"` + "Tentar novamente" |
| Falha na exportação | Toast destrutivo | Não foi possível exportar os contatos | *(mensagem real ou "Falha ao consultar os dados. Tente novamente.")* |

**Inconsistência notável:** a prévia (`FilterPreviewDialog`) é o **único** ponto que mostra "Erro ao carregar prévia" **sem** o motivo e **sem** botão de retentar — justamente contrário à invariante "erro ≠ vazio, e erro diz o porquê" que o resto do domínio segue.

#### 5.5.7 Toasts de sucesso

| Ação | Título | Descrição |
|---|---|---|
| Ativar filtro | **Filtro ativado** | `"{nome}" voltou a aparecer nos seletores.` |
| Desativar filtro | **Filtro desativado** | `"{nome}" não aparecerá mais nos seletores. Réguas e carteiras que já usam este filtro continuam funcionando normalmente.` |
| Exclusão em massa | **Filtros excluídos** | `N filtro(s) excluído(s) com sucesso.` |

Quando o nome não é passado, o texto cai em **"O filtro"**.

**Design da mensagem de desativação (do comentário no código):** "O toast diz as DUAS metades de propósito: sem a segunda, desativar é lido como 'desliguei a régua' e vira chamado."

**Não há toast de sucesso** ao criar ou salvar um filtro — o dialog simplesmente fecha.

---

## 6. Catálogo completo de campos filtráveis

Fonte primária: `src/lib/filters/fields.ts` (`FILTER_FIELDS_REGISTRY`). Complementos dinâmicos: `src/components/filters/filter-builder/hooks.ts` e `src/hooks/etl/useCustomFields.ts`.

### 6.0 Como ler este catálogo

O registry é **estático e por tabela**. A tabela escolhida no dropdown da regra (§5.3.3) determina qual lista de campos o `FieldCombobox` mostra. O catálogo abaixo é a lista completa — **88 campos estáticos** distribuídos em 8 categorias:

| Categoria (`table`) | Rótulo do dropdown | Campos estáticos | Classe na derivação de `target_entity` |
|---|---|---|---|
| `contacts` | Contato | 26 | Neutra |
| `contracts` | Contrato | 8 | Contrato |
| `titles` | Titulo | 15 | Contrato |
| `supplies` | Suprimento | 6 | Suprimento |
| `supply_titles` | Titulo de Suprimento | 10 | Suprimento |
| `data_sources` | Fonte de Dados | 6 | Neutra |
| `actions` | Acao | 16 | Neutra |
| `aging` | Aging | 1 | Neutra |
| **Total** | | **88** | |

**Colunas deste catálogo:**

- **Campo** — a chave gravada em `conditions[].field`.
- **Rótulo exibido** — literal do registry, **exatamente como aparece na tela** (a maioria sem acento; três campos de `actions` têm acento).
- **Tipo de dado** — `FieldType` (`text`, `number`, `date`, `boolean`, `select`, `multi_select`, `multi_select_dynamic`, `phone`).
- **Operadores permitidos** — derivados do tipo via `OPERATORS_BY_FIELD_TYPE` (§7). Aqui usam-se as siglas; os rótulos em português estão em §7.1.
- **Controle de valor** — qual das 5 variantes de `FilterValueInput` (§5.3.7) é renderizada **na prática**, considerando as opções estáticas do registry e os overrides dinâmicos de `useFieldOptionsMap`.
- **Entidade alvo** — o `target_entity` que aquele campo, sozinho, força na derivação (§2.9).

**Convenção de "Controle de valor":**

| Sigla usada abaixo | Controle real |
|---|---|
| `Input texto` | `Input` livre `type="text"` (variante 5) |
| `Input número` | `Input` livre `type="number"`, `parseFloat` no save (variante 5) |
| `Input data` | `Input` livre `type="date"` (variante 5) |
| `Faixa` | Dois inputs `[mín.] e [máx.]` — só quando o operador escolhido é `between` (variante 1) |
| `Select Sim/Não` | `<select>` nativo com `""`/`true`/`false` (variante 3) |
| `Combobox único` | `ValueCombobox` modo único, com busca e **valor livre** via `Usar "{texto}"` (variante 4) |
| `Combobox múltiplo` | `ValueCombobox` modo múltiplo, badges removíveis, **sem valor livre** (variante 4) |
| `Selos` | `SealsValueInput` — popover do catálogo de selos, grava UUIDs (variante 2) |
| `Nenhum` | O operador é unário (`is_null`, `is_not_null`, `is_empty`, `is_not_empty`) — o controle de valor **não é renderizado** |

> **Regra transversal:** o controle depende do **operador escolhido**, não só do campo. Todo campo `number`/`date` vira `Faixa` quando o operador é `between`; todo campo vira `Nenhum` quando o operador é unário. As linhas abaixo listam o controle do **caso comum** (operador binário), com a variação anotada.

### 6.1 Categoria `contacts` — Contato (26 campos)

`target_entity` resultante: **neutro** (não decide a raiz sozinho — §2.9).

| # | Campo | Rótulo exibido | Tipo | Operadores permitidos | Controle de valor | Observação |
|---|---|---|---|---|---|---|
| 1 | `document` | Documento (CPF/CNPJ) | `text` | eq, neq, like, ilike, nlike, is_null, is_not_null | Input texto | Sem máscara de CPF/CNPJ na entrada |
| 2 | `name` | Nome | `text` | eq, neq, like, ilike, nlike, is_null, is_not_null | Input texto | |
| 3 | `trading_name` | Nome Fantasia | `text` | eq, neq, like, ilike, nlike, is_null, is_not_null | Input texto | |
| 4 | `phone` | Telefone | `phone` | like, ilike, nlike, eq, is_null, is_not_null | Input texto | `description`: "Busca normalizada (sem formatacao)" — **o texto da descrição não é exibido em lugar nenhum da UI** |
| 5 | `is_active` | Ativo | `boolean` | eq, is_null, is_not_null | Select Sim/Não | Grava string `"true"`/`"false"` (§5.3.7) |
| 6 | `tags` | Tags | `multi_select` | in, nin, is_null, is_not_null | Combobox múltiplo | Opções vêm de `useTagCatalog()` (chave `tags`); value = `t.name`, label = `t.label` |
| 7 | `seals` | Selos | `multi_select_dynamic` | in, not_in, all_of, is_empty, is_not_empty | Selos | Escopo `contact`; grava UUIDs de `seal_catalog`. `is_empty`/`is_not_empty` → controle `Nenhum` |
| 8 | `address_city` | Cidade | `text` | eq, neq, like, ilike, nlike, is_null, is_not_null | Input texto | Sem autocomplete de município |
| 9 | `address_state` | Estado | `text` | eq, neq, like, ilike, nlike, is_null, is_not_null | Input texto | **Sem lista de UFs** — digitação livre, sujeita a "SP"/"sp"/"São Paulo" |
| 10 | `total_contracts` | Total de Contratos | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | |
| 11 | `active_contracts` | Contratos Ativos | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | |
| 12 | `cancelled_contracts` | Contratos Cancelados | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | |
| 13 | `total_contract_value` | Valor Total dos Contratos | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | Valor em reais digitado cru (sem máscara monetária) |
| 14 | `total_paid_value` | Valor Pago | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | Coluna real: `contact_total_paid_value` |
| 15 | `max_days_overdue` | Dias em Atraso (Maximo) | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | Aceita negativo (cobrança preventiva) |
| 16 | `avg_days_overdue` | Media de Atraso (Atual) | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | `description`: "Media de dias em atraso de todos os titulos" (não exibida) |
| 17 | `avg_payment_delay` | Media de Atraso no Pagamento | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | `description`: "Media de dias de atraso dos titulos ja pagos" (não exibida) |
| 18 | `has_notified_titles` | Possui Titulos Notificados | `boolean` | eq, is_null, is_not_null | Select Sim/Não | |
| 19 | `has_negativated_titles` | Possui Titulos Negativados | `boolean` | eq, is_null, is_not_null | Select Sim/Não | |
| 20 | `total_titles` | Total de Titulos | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | |
| 21 | `open_titles` | Titulos em Aberto | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | |
| 22 | `overdue_titles` | Titulos Vencidos | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | |
| 23 | `total_open_value` | Valor Total em Aberto | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | Substituiu `total_pending_value`, removido no BLD-2 (coluna inexistente) |
| 24 | `first_contract_date` | Data do Primeiro Contrato | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | |
| 25 | `next_due_date` | Proximo Vencimento | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | |
| 26 | `last_payment_date` | Data do Ultimo Pagamento | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | |

**Campos removidos do registry (não aparecem mais, mas podem existir em filtros salvos antigos):**

| Campo removido | Motivo (comentário no código) |
|---|---|
| `total_pending_value` | BLD-2 — coluna `contact_total_pending_value` não existe em `mv_titles_base`; usar `total_open_value` (o compilador remapeia definições legadas) |
| `paid_titles` | BLD-2 — não há coluna `contact_paid_titles` |
| `total_paid_amount` | BLD-2 — duplicata de `total_paid_value` |
| `days_since_last_activity` | Exigia join com `actions`, indisponível em `vw_titles_live` |

**Implicação de redesign:** um filtro salvo antes da remoção continua carregando esses campos. A UI **não sinaliza** campo órfão — o `FieldCombobox` simplesmente não encontra o item e mostra o `field` cru (via `cleanFieldLabel`) sem nenhum aviso. `⚠️ A confirmar:` se o redesign deve marcar visualmente regras cujo `field` não está mais no catálogo da tabela.

### 6.2 Categoria `contracts` — Contrato (8 campos)

`target_entity` resultante: **`contracts`**.

| # | Campo | Rótulo exibido | Tipo | Operadores permitidos | Controle de valor | Observação |
|---|---|---|---|---|---|---|
| 1 | `contract_number` | Numero do Contrato | `text` | eq, neq, like, ilike, nlike, is_null, is_not_null | Input texto | |
| 2 | `modality` | Modalidade | `select` | eq, neq, in, nin, is_null, is_not_null | Combobox único/múltiplo **ou** Input texto | **Sem `options` no registry.** Só vira combobox se a org tiver `standard_values` de `field_type = "modality"` (chaves `modality` e `contracts:modality`). Sem isso, cai no Input livre |
| 3 | `status` | Status | `select` | eq, neq, in, nin, is_null, is_not_null | Combobox único/múltiplo | Opções estáticas `CONTRACT_STATUS_OPTIONS` (4 valores, §6.9.1) |
| 4 | `total_value` | Valor Total | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | |
| 5 | `start_date` | Data de Inicio | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | |
| 6 | `avg_days_overdue` | Media de Atraso (Atual) | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | Homônimo do campo de `contacts` — **mesmo rótulo, escopo diferente**. A UI não diferencia visualmente |
| 7 | `avg_payment_delay` | Media de Atraso no Pagamento | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | Idem |
| 8 | `seals` | Selos | `multi_select_dynamic` | in, not_in, all_of, is_empty, is_not_empty | Selos | Escopo `contract` |

### 6.3 Categoria `titles` — Titulo (15 campos)

`target_entity` resultante: **`contracts`** (título é do mundo contrato).

| # | Campo | Rótulo exibido | Tipo | Operadores permitidos | Controle de valor | Observação |
|---|---|---|---|---|---|---|
| 1 | `title_number` | Numero do Titulo | `text` | eq, neq, like, ilike, nlike, is_null, is_not_null | Input texto | |
| 2 | `installment_number` | Parcela | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | |
| 3 | `due_date` | Data de Vencimento | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | |
| 4 | `original_value` | Valor Original | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | |
| 5 | `current_value` | Valor Atual | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | |
| 6 | `status` | Status | `select` | eq, neq, in, nin, is_null, is_not_null | Combobox único/múltiplo | Opções estáticas `TITLE_STATUS_OPTIONS` (15 valores, §6.9.2). Em runtime pode ser **sobrescrito** pelos `standard_values` da org (chaves `status` e `titles:status`) |
| 7 | `days_overdue` | Dias em Atraso | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | **Aceita negativo** (regra crítica 2 do projeto: D-7, D-1 = cobrança preventiva). A UI não avisa isso |
| 8 | `owner_pipeline_id` | Pipeline (Titulo) | `select` | eq, neq, in, nin, is_null, is_not_null | **Input texto** | `description`: "Pipeline que importou o titulo". **Declarado `select` mas sem `options` e sem override dinâmico** → cai na variante 5 e o usuário precisa digitar um UUID à mão (§5.3.10) |
| 9 | `payment_method` | Forma de Pagamento (Titulo) | `text` | eq, neq, like, ilike, nlike, is_null, is_not_null | Input texto | |
| 10 | `is_notified` | Notificado | `boolean` | eq, is_null, is_not_null | Select Sim/Não | |
| 11 | `is_negativated` | Negativado | `boolean` | eq, is_null, is_not_null | Select Sim/Não | Estado **atual** |
| 12 | `was_negativated` | Ja Foi Negativado | `boolean` | eq, is_null, is_not_null | Select Sim/Não | Histórico — a diferença com o anterior só existe no rótulo |
| 13 | `notified_at` | Data da Notificacao | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | |
| 14 | `negativated_at` | Data da Negativacao | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | |
| 15 | `seals` | Selos | `multi_select_dynamic` | in, not_in, all_of, is_empty, is_not_empty | Selos | Escopo `title` |

**Colisão de nome relevante:** `titles.status` e `contracts.status` compartilham o `field` cru `status`, com catálogos de opções **diferentes**. É por isso que o `fieldOptionsMap` emite chaves `table:field` além da chave crua (BLD-14) e que o `ValueCombobox` consulta `${rule.table}:${rule.field}` **primeiro** (§5.3.7). Um redesign que simplifique essa chave reintroduz o bug de mostrar status de contrato num filtro de título.

### 6.4 Categoria `supplies` — Suprimento (6 campos)

`target_entity` resultante: **`supplies`**. Espelha `contracts`, mas com **duas ausências deliberadas**.

| # | Campo | Rótulo exibido | Tipo | Operadores permitidos | Controle de valor | Observação |
|---|---|---|---|---|---|---|
| 1 | `contract_number` | Numero do Suprimento | `text` | eq, neq, like, ilike, nlike, is_null, is_not_null | Input texto | Mesma chave de `contracts.contract_number`, rótulo diferente |
| 2 | `status` | Status | `select` | eq, neq, in, nin, is_null, is_not_null | Combobox único/múltiplo | Reusa `CONTRACT_STATUS_OPTIONS` |
| 3 | `total_value` | **Valor Total do Suprimento (ERP)** | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | **Único campo com `description` longa e advertência explícita** — ver abaixo |
| 4 | `avg_days_overdue` | Media de Atraso (Atual) | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | |
| 5 | `avg_payment_delay` | Media de Atraso no Pagamento | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | |
| 6 | `seals` | Selos | `multi_select_dynamic` | in, not_in, all_of, is_empty, is_not_empty | Selos | `description`: "Selos aplicados ao suprimento (catalogo dinamico)" |

**Campos ausentes em `supplies` (removidos no IAF-4795 F1):** `modality` e `start_date` — não existem na tabela `supplies`, então seriam sempre `NULL` na view. Filtro inútil, removido do catálogo.

**O caso `supplies.total_value` — o único campo do produto com ressalva documentada:**

O rótulo diz "Valor Total do Suprimento (ERP)" e a `description` no código é:

> "Valor cheio do suprimento no Sankhya, somando TODAS as parcelas — inclusive as que estao fora da janela de cobranca importada. Costuma ser maior que o saldo mostrado na carteira."

Motivo (comentário do código): `supplies.total_value` compila para `contract_original_value`, que no ramo supply da view é `supplies.original_value` = `SUM(VLRDESDOB)` de **todas** as parcelas no Sankhya (janela plena) — **não** é o valor que a carteira mostra. Medição em `org_blips` (11/08/2026): divergem em **74,1% dos suprimentos** — R$ 13,7M contra R$ 5,15M (2,7×).

**Lacuna crítica de UX:** essa advertência existe **só no código**. O `FieldCombobox` (§5.3.5) renderiza apenas `label` — `description` **nunca é exibida em lugar nenhum da interface**. O operador escolhe um campo que diverge 2,7× do que ele vê na carteira sem nenhum aviso.

**Oportunidade direta para o redesign:** exibir `description` no item do combobox (linha secundária) ou num `HelpTip` ao lado do campo selecionado. Hoje **9 campos do registry têm `description` escrita e nenhuma é mostrada**: `contacts.phone`, `contacts.seals`, `contacts.avg_days_overdue`, `contacts.avg_payment_delay`, `contracts.seals`, `titles.owner_pipeline_id`, `titles.seals`, `supplies.total_value`, `supplies.seals`, `supply_titles.owner_pipeline_id`, `supply_titles.seals`, `aging.aging_bucket`.

### 6.5 Categoria `supply_titles` — Titulo de Suprimento (10 campos)

`target_entity` resultante: **`supplies`**. Espelha `titles`, sem os 5 campos de notificação/negativação.

| # | Campo | Rótulo exibido | Tipo | Operadores permitidos | Controle de valor | Observação |
|---|---|---|---|---|---|---|
| 1 | `title_number` | Numero do Titulo (Suprimento) | `text` | eq, neq, like, ilike, nlike, is_null, is_not_null | Input texto | |
| 2 | `installment_number` | Parcela | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | |
| 3 | `due_date` | Data de Vencimento | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | |
| 4 | `original_value` | Valor Original | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | |
| 5 | `current_value` | Valor Atual | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | |
| 6 | `status` | Status | `select` | eq, neq, in, nin, is_null, is_not_null | Combobox único/múltiplo | Reusa `TITLE_STATUS_OPTIONS` |
| 7 | `days_overdue` | Dias em Atraso | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | |
| 8 | `owner_pipeline_id` | Pipeline (Titulo) | `select` | eq, neq, in, nin, is_null, is_not_null | **Input texto** | Mesmo problema de §6.3 item 8 |
| 9 | `payment_method` | Forma de Pagamento (Titulo) | `text` | eq, neq, like, ilike, nlike, is_null, is_not_null | Input texto | |
| 10 | `seals` | Selos | `multi_select_dynamic` | in, not_in, all_of, is_empty, is_not_empty | Selos | Escopo derivado: **`supply_titles` não está no mapa de escopo do `SealsValueInput`** (que só mapeia `contacts`/`contracts`/`titles`) |

`⚠️ A confirmar:` a condição da variante 2 (`SealsValueInput`) exige `rule.table` em `contacts|contracts|titles`. Para `supplies` e `supply_titles` o campo `seals` **não** renderiza o popover de selos — cai na variante 4/5 (combobox ou input livre), obrigando o usuário a digitar UUID. Isso parece um bug: o registry declara `seals` nas 5 entidades, mas a UI só o suporta em 3.

### 6.6 Categoria `data_sources` — Fonte de Dados (6 campos)

`target_entity` resultante: **neutro**.

| # | Campo | Rótulo exibido | Tipo | Operadores permitidos | Controle de valor | Origem das opções |
|---|---|---|---|---|---|---|
| 1 | `contact_source_pipelines` | Pipeline de Origem (Contato) | `multi_select` | in, nin, is_null, is_not_null | Combobox múltiplo | `usePipelinesForSelect()` — value **e** label = `p.label` |
| 2 | `contact_data_sources` | Fonte de Dados (Contato) | `multi_select` | in, nin, is_null, is_not_null | Combobox múltiplo | `useDataSources()` — value e label = `ds.name` |
| 3 | `contact_first_imported_at` | Primeira Importacao (Contato) | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | — |
| 4 | `contact_last_imported_at` | Ultima Importacao (Contato) | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | — |
| 5 | `contract_source_pipelines` | Pipeline de Origem (Contrato) | `multi_select` | in, nin, is_null, is_not_null | Combobox múltiplo | `usePipelinesForSelect()` |
| 6 | `contract_data_sources` | Fonte de Dados (Contrato) | `multi_select` | in, nin, is_null, is_not_null | Combobox múltiplo | `useDataSources()` |

**Nota técnica:** pipelines e fontes de dados usam o **nome/rótulo como valor**, não o UUID. Renomear um pipeline no ETL **quebra silenciosamente** todo filtro que o referencie. `⚠️ A confirmar:` se isso é intencional (o compilador compara texto na view) ou dívida.

**Assimetria:** existem `contact_first_imported_at` e `contact_last_imported_at`, mas **não existem** os equivalentes de contrato (`contract_first_imported_at` / `contract_last_imported_at`).

### 6.7 Categoria `actions` — Acao (16 campos)

`target_entity` resultante: **neutro**.

| # | Campo | Rótulo exibido | Tipo | Operadores permitidos | Controle de valor | Origem das opções |
|---|---|---|---|---|---|---|
| 1 | `last_action_type` | Tipo da Ultima Acao | `select` | eq, neq, in, nin, is_null, is_not_null | Combobox único/múltiplo | `ACTION_TYPE_OPTIONS` (7 valores, §6.9.3) |
| 2 | `last_action_channel` | Canal da Ultima Acao | `select` | eq, neq, in, nin, is_null, is_not_null | Combobox único/múltiplo | `ACTION_CHANNEL_OPTIONS` (6 valores, §6.9.4) |
| 3 | `last_action_status` | Status da Ultima Acao | `select` | eq, neq, in, nin, is_null, is_not_null | Combobox único/múltiplo | `ACTION_STATUS_OPTIONS` (12 valores, §6.9.5) |
| 4 | `last_action_sent_at` | Data de Envio (Ultima Acao) | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | — |
| 5 | `last_action_delivered_at` | Data de Entrega (Ultima Acao) | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | — |
| 6 | `last_action_read_at` | Data de Leitura (Ultima Acao) | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | — |
| 7 | `last_action_replied_at` | Data de Resposta (Ultima Acao) | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | — |
| 8 | `last_notification_sent_at` | **Último Envio de Notificação Extrajudicial** | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | — |
| 9 | `last_negativation_sent_at` | **Último Envio de Negativação** | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | — |
| 10 | `total_actions` | Total de Acoes | `number` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input número / Faixa | — |
| 11 | `action_types_received` | Tipos de Acao Recebidos | `multi_select` | in, nin, is_null, is_not_null | Combobox múltiplo | `ACTION_TYPE_OPTIONS` |
| 12 | `action_channels_received` | Canais Recebidos | `multi_select` | in, nin, is_null, is_not_null | Combobox múltiplo | `ACTION_CHANNEL_OPTIONS` |
| 13 | `has_action_reply` | Teve Resposta | `boolean` | eq, is_null, is_not_null | Select Sim/Não | — |
| 14 | `last_funnel_stage` | Etapa do Funil | `select` | eq, neq, in, nin, is_null, is_not_null | Combobox único/múltiplo | `FUNNEL_STAGE_OPTIONS` (9 valores, §6.9.6) |
| 15 | `last_funnel_stage_name` | Nome da Etapa do Funil | `text` | eq, neq, like, ilike, nlike, is_null, is_not_null | Input texto | — |
| 16 | `last_funnel_event_at` | Data da Ultima Etapa | `date` | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | Input data / Faixa | — |

**Inconsistência tipográfica visível na tela:** os campos 8 e 9 são os **únicos dois** do registry inteiro com acentuação completa ("Último Envio de Notificação Extrajudicial"). Todos os outros 86 estão sem acento ("Data de Envio (Ultima Acao)"). No mesmo dropdown, lado a lado.

**Divergência de rótulo de status (relevante para o redesign):** `ACTION_STATUS_OPTIONS` usa `value === label` — ou seja, o filtro mostra **"Falhou"**, **"Falha Permanente"** e **"Respondido"**. A tela de Ações, porém, exibe esses mesmos status como **"Falha Temporária de Ação"**, **"Falha Definitiva de Ação"** e **"Solicitou Atendimento"** (fonte: `src/lib/constants/action-status-display.ts`, override só de exibição — IAF-4700). **O construtor de filtros não aplica esse mapa de exibição.** O mesmo status tem dois nomes no produto, dependendo da tela.

### 6.8 Categoria `aging` — Aging (1 campo)

`target_entity` resultante: **neutro**.

| # | Campo | Rótulo exibido | Tipo | Operadores permitidos | Controle de valor | Observação |
|---|---|---|---|---|---|---|
| 1 | `aging_bucket` | Faixa de Aging | `select` | eq, neq, in, nin, is_null, is_not_null | Combobox único/múltiplo | Opções `AGING_BUCKET_OPTIONS` (6 valores, §6.9.7). `description`: "Contatos que TÊM títulos na faixa selecionada" (não exibida) |

**Particularidades desta categoria:**

- é a **única** com um único campo — o dropdown de Tabela leva a uma lista de um item só;
- é a **única** que dispara um `HelpTip` condicional na regra (`aging_bucket`, §5.3.4) — a ajuda que compensa a `description` não exibida;
- é a **única** que **nunca recebe campos customizados** (`useMappedFields` exclui `aging` explicitamente);
- o rótulo do dropdown é **"Aging"**, o único em inglês entre 8 rótulos em português;
- `max_aging_bucket` foi removido no BLD-2 (coluna inexistente — filtros sobre ele davam erro em runtime).

**Semântica que a UI não conta:** `aging_bucket` é avaliado **título a título**. Um contato "casa" a faixa `91_180` se **tiver ao menos um** título nela — não significa que a dívida inteira está nessa faixa. O `HelpTip` diz "Faixas por dias de atraso… 'Em dia' inclui títulos a vencer (atraso negativo)", mas não explica o quantificador existencial. `⚠️ A confirmar:` se vale reforçar isso na copy do redesign.

### 6.9 Catálogos de opções estáticas (valores exatos)

Todos vivem em `src/lib/filters/fields.ts` ou são derivados de constantes canônicas do projeto.

#### 6.9.1 `CONTRACT_STATUS_OPTIONS` — usado por `contracts.status` e `supplies.status`

| `value` | `label` |
|---|---|
| `active` | Ativo |
| `suspended` | Suspenso |
| `cancelled` | Cancelado |
| `finished` | Finalizado |

#### 6.9.2 `TITLE_STATUS_OPTIONS` — usado por `titles.status` e `supply_titles.status`

Derivado de `TITLE_STATUS_CONFIG` (`src/lib/constants/title-status-config.ts`) — fonte única, BLD-13. Os `value` são os nomes **canônicos do BigQuery**, nunca os legados em inglês (regra crítica 9 do projeto).

| # | `value` (canônico BQ) | `label` exibido | Classificação | É dívida? |
|---|---|---|---|---|
| 1 | `Disponivel` | Disponivel | active | Sim |
| 2 | `Pago` | Pago | paid | Não |
| 3 | `Cancelado` | Cancelado | inactive | Não |
| 4 | `Aguardando Recompra` | Aguardando Recompra | active | Sim |
| 5 | `Renegociado` | Renegociado | active | Sim |
| 6 | `Expirado` | Expirado | active | Sim |
| 7 | `Provisionado` | Provisionado | active | Sim |
| 8 | `Pendente` | Pendente | active | Sim |
| 9 | `Para Antecipar` | Para Antecipar | active | Sim |
| 10 | `Recompra Solicitada` | Recompra Solicitada | active | Sim |
| 11 | `Informacoes Pendente` | **Info. Pendente** | active | Sim |
| 12 | `Antecipacao Rejeitada` | **Antecip. Rejeitada** | active | Sim |
| 13 | `Aguardando Cancelamento` | **Aguard. Cancelamento** | active | Sim |
| 14 | `Removido` | Removido | inactive | Não |
| 15 | `Recomprado` | Recomprado | active | Sim |

Três labels são **abreviações** do valor (11, 12, 13) — o combobox mostra "Info. Pendente" mas grava `Informacoes Pendente`. A busca do `ValueCombobox` casa por `label` **ou** `value` (§5.3.7), então digitar "Informacoes" encontra o item mesmo com o label abreviado.

**Override em runtime:** `useFieldOptionsMap` semeia as chaves `status` e `titles:status` com os `standard_values` da org quando existem (`field_type === "status"`), **substituindo** a lista estática. Ou seja, o conjunto real de opções visto na tela **varia por organização**.

#### 6.9.3 `ACTION_TYPE_OPTIONS` (7)

| `value` | `label` |
|---|---|
| `whatsapp` | WhatsApp |
| `email` | E-mail |
| `sms` | SMS |
| `voice` | Ligacao |
| `webhook` | Webhook |
| `notification` | Notificacao |
| `negativation` | Negativacao |

#### 6.9.4 `ACTION_CHANNEL_OPTIONS` (6)

Idêntico ao anterior **menos `webhook`**:

| `value` | `label` |
|---|---|
| `whatsapp` | WhatsApp |
| `email` | E-mail |
| `sms` | SMS |
| `voice` | Ligacao |
| `notification` | Notificacao |
| `negativation` | Negativacao |

**Nota:** dois catálogos quase idênticos com nomes parecidos ("Tipo" × "Canal") num mesmo dropdown. Para o usuário, a diferença é 1 item.

#### 6.9.5 `ACTION_STATUS_OPTIONS` (12)

Derivado de `ACTION_STATUSES` (`src/lib/constants/action-status-config.ts`) — `value === label`.

| # | `value` = `label` no filtro | Rótulo na tela de Ações (`ACTION_STATUS_DISPLAY`) |
|---|---|---|
| 1 | Pendente | Pendente |
| 2 | Processando | Processando |
| 3 | Enviado | Enviado |
| 4 | Interagiu | Interagiu |
| 5 | Respondido | **Solicitou Atendimento** |
| 6 | Falhou | **Falha Temporária de Ação** |
| 7 | Falha Permanente | **Falha Definitiva de Ação** |
| 8 | Em Atendimento | Em Atendimento |
| 9 | Cancelado | Cancelado |
| 10 | Cancelado (Pago) | Cancelado (Pago) |
| 11 | Cancelado (Removido) | Cancelado (Removido) |
| 12 | Duplicado | Duplicado |

#### 6.9.6 `FUNNEL_STAGE_OPTIONS` (9)

| `value` | `label` |
|---|---|
| `contact_initiated` | Contato Iniciado |
| `em_andamento` | Em andamento |
| `payment_requested` | Solicitou Pagamento |
| `payment_promise` | Promessa de Pagamento |
| `renegotiation_requested` | Pediu Renegociacao |
| `agreement_reached` | Acordo Fechado |
| `human_transfer` | Transferido p/ Humano |
| `payment_confirmed` | Pagamento Confirmado |
| `conversation_ended` | Conversa Encerrada |

**Detalhe:** `em_andamento` é o único `value` em português no meio de 8 em inglês, e o único `label` que não está em Title Case ("Em andamento").

#### 6.9.7 `AGING_BUCKET_OPTIONS` (6)

Os `value` são os literais **exatos** emitidos pelo `CASE` de `aging_bucket` em `mv_titles_base` (BLD-1). Divergência aqui (ex.: o antigo `31-60` com hífen em vez de underscore) **não casa nada**.

| `value` | `label` |
|---|---|
| `current` | Em dia |
| `1_30` | 1-30 dias |
| `31_60` | 31-60 dias |
| `61_90` | 61-90 dias |
| `91_180` | 91-180 dias |
| `180_plus` | 180+ dias |

A MV também emite `paid` e `inactive`, **deliberadamente não expostos** como opção de filtro (decisão D4 — podem ser adicionados se o produto quiser).

### 6.10 Campos dinâmicos — o catálogo que o registry não cobre

Além dos 88 estáticos, `useMappedFields` concatena **campos dinâmicos por organização** (§5.3.9). Eles não têm entrada em `fields.ts` e por isso não aparecem nas tabelas acima, mas são indistinguíveis deles na tela (exceto pelo badge "Custom").

#### 6.10.1 Campos de sistema sempre injetados

| Entidade | Campo | Presente também no registry? |
|---|---|---|
| `contacts` | `has_pnp` | **Não** — só via injeção |
| `contacts` | `seals` | Sim (duplica) |
| `contracts` | `days_overdue` | **Não** — só via injeção |
| `contracts` | `has_pnp` | **Não** |
| `contracts` | `safra_days` | **Não** |
| `contracts` | `min_open_installment` | **Não** |
| `contracts` | `min_open_installment_disponivel` | **Não** |
| `contracts` | `seals` | Sim (duplica) |
| `titles` | `days_overdue` | Sim (duplica) |
| `titles` | `seals` | Sim (duplica) |
| `supplies` | `days_overdue` | **Não** — o registry de `supplies` não tem `days_overdue` |
| `supplies` | `seals` | Sim (duplica) |
| `supply_titles` | `days_overdue` | Sim (duplica) |
| `supply_titles` | `seals` | Sim (duplica) |

`⚠️ A confirmar:` a concatenação é `[...baseFields[entidade], ...customFieldsData[entidade]]` **sem deduplicação**. Campos como `seals` e `titles.days_overdue` aparecem nas duas listas — se o hook de campos customizados os injeta de fato, o combobox pode listar o mesmo campo **duas vezes**. A chave do item (`custom-${field}` vs `standard-${field}`) evita o crash do React, mas não evita a duplicata visual. Verificar em uma org com muitos campos mapeados.

#### 6.10.2 Campos customizados de ETL

| Aspecto | Comportamento |
|---|---|
| Chave gerada | `custom.<nome>` |
| Marcação na UI | `Badge "Custom"` no `FieldCombobox` (gatilho e item da lista) |
| Rótulo | `custom_field_definitions.display_name`; se ausente, derivado do `snake_case` → Title Case |
| Tipo | `custom_field_definitions.field_type`; se ausente, `text` |
| Origem | `etl_pipelines.field_mapping` dos pipelines **ativos** |
| Opções de valor | `useCustomFieldOptions()` — só para campos marcados como `list_fields` nas `transform_rules` **ou** com ≤ 50 valores distintos pré-computados em `data_sources.query_config` |
| Ordenação | Alfabética `pt-BR`, **depois** dos campos do registry |
| Entidade `aging` | **Nunca** recebe customizados |
| Falha ao carregar | Só `console.error` — a UI não avisa nada (§5.3.9) |

**Consequência para o redesign:** o catálogo real de campos de um cliente é **registry + injeção + customizados**, e só o terceiro grupo é visualmente distinguível. Um operador não tem como saber se "Segmento" é campo nativo do produto ou coluna que o ETL da empresa dele trouxe — a não ser pelo badge.

---

## 7. Catálogo completo de operadores

Fonte: `src/lib/filters/schema.ts` (`FilterOperatorSchema`) e `src/lib/filters/fields.ts` (`OPERATORS_BY_FIELD_TYPE`, `OPERATOR_LABELS`).

### 7.1 Os 18 operadores do enum

| # | `value` | Rótulo exibido (`OPERATOR_LABELS`) | Semântica SQL (do comentário no schema) | Precisa de valor? | Forma do valor |
|---|---|---|---|---|---|
| 1 | `eq` | igual a | `=` | Sim | Escalar |
| 2 | `neq` | diferente de | `!=` | Sim | Escalar |
| 3 | `gt` | maior que | `>` | Sim | Escalar |
| 4 | `gte` | maior ou igual a | `>=` | Sim | Escalar |
| 5 | `lt` | menor que | `<` | Sim | Escalar |
| 6 | `lte` | menor ou igual a | `<=` | Sim | Escalar |
| 7 | `in` | **tem algum** | `IN` / array `&&` (ANY) | Sim | **Array** |
| 8 | `nin` | **nao esta em** | `NOT IN` | Sim | **Array** |
| 9 | `not_in` | **nao tem** | `NOT IN` (alias aceito por `compile_filter_to_sql_v2`) | Sim | **Array** |
| 10 | `between` | entre | `BETWEEN` | Sim | **Array de exatamente 2** `[min, max]` |
| 11 | `like` | contem | `LIKE` | Sim | Escalar (texto) |
| 12 | `ilike` | contem (ignorar maiusculas) | `ILIKE` | Sim | Escalar (texto) |
| 13 | `nlike` | nao contem | `NOT LIKE` | Sim | Escalar (texto) |
| 14 | `is_null` | e vazio | `IS NULL` | **Não** | — |
| 15 | `is_not_null` | nao e vazio | `IS NOT NULL` | **Não** | — |
| 16 | `all_of` | tem todos | array `@>` (contém TODOS) | Sim | **Array** |
| 17 | `is_empty` | vazio | array vazio | **Não** | — |
| 18 | `is_not_empty` | nao vazio | array não vazio | **Não** | — |

`⚠️ A confirmar:` a §5.5.4 deste documento diz "enum de 17 valores". A contagem real do `FilterOperatorSchema` é **18**. Tratar 18 como o número correto.

### 7.2 Operadores por tipo de dado (`OPERATORS_BY_FIELD_TYPE`)

Esta é a tabela que governa **o que aparece no `<select>` de operador** (§5.3.6). A ordem das colunas abaixo é a ordem literal do array — e **a primeira da lista é o fallback** quando o operador atual deixa de ser válido ao trocar de campo (§5.3.5).

| Tipo de dado | Nº de operadores | Lista (na ordem exibida) | Fallback (1º da lista) |
|---|---|---|---|
| `text` | 7 | eq, neq, like, ilike, nlike, is_null, is_not_null | `eq` |
| `number` | 9 | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | `eq` |
| `date` | 9 | eq, neq, gt, gte, lt, lte, between, is_null, is_not_null | `eq` |
| `select` | 6 | eq, neq, in, nin, is_null, is_not_null | `eq` |
| `multi_select` | 4 | in, nin, is_null, is_not_null | `in` |
| `multi_select_dynamic` | 5 | in, not_in, all_of, is_empty, is_not_empty | `in` |
| `boolean` | 3 | eq, is_null, is_not_null | `eq` |
| `phone` | 6 | like, ilike, nlike, eq, is_null, is_not_null | `like` |

**Fallback global:** `getOperatorsForFieldType` devolve a lista de `text` quando o tipo não é reconhecido. E `getFieldType` devolve `"text"` quando o campo não existe no registry — por isso um **campo ainda não escolhido** já mostra os 7 operadores de texto no select (§5.3.6).

### 7.3 O que cada tipo NÃO oferece — e por quê

| Tipo | Operadores ausentes | Leitura |
|---|---|---|
| `text` | `gt/gte/lt/lte`, `between`, `in/nin` | **Não há "está em uma lista de valores" para texto livre.** Para "cidade é São Paulo OU Campinas", o usuário precisa criar duas regras num grupo `OU` |
| `number` / `date` | `like`, `in/nin` | Coerente |
| `select` | `between`, `like` | Coerente |
| `multi_select` | `eq/neq`, `all_of` | **Não dá para exigir TODOS** num `multi_select` estático (só `in` = "qualquer um"). Só `multi_select_dynamic` (selos) tem `all_of` |
| `multi_select_dynamic` | `eq/neq`, `nin`, `is_null/is_not_null` | Usa o par próprio `is_empty`/`is_not_empty` (array vazio ≠ NULL) |
| `boolean` | `neq` | **Não existe "diferente de"** para booleano — "não é Sim" se faz com `eq: false` ou com a negação `NÃO (NOT)` da regra |
| `phone` | `gt/gte/lt/lte`, `between`, `in/nin` | Mesma limitação de `text` |

### 7.4 As três formas de "não está" — e a armadilha

O domínio tem **três** maneiras de negar, com semânticas distintas e nomes parecidos:

| Mecanismo | Onde fica | Rótulo na UI | O que faz |
|---|---|---|---|
| Operador `nin` | Dropdown de operador (`select`, `multi_select`) | "nao esta em" | `NOT IN` sobre a lista informada |
| Operador `not_in` | Dropdown de operador (só `multi_select_dynamic`) | "nao tem" | `NOT IN` array-native |
| Flag `negate` | Botão **NÃO (NOT)** da regra/grupo | "NÃO (NOT)" | Inverte o resultado **já combinado** da regra ou do grupo inteiro |

**A armadilha documentada:** o `HelpTip` `builder_negate` avisa que **"Títulos com o campo vazio (nulo) entram no resultado do 'NÃO'"** — comportamento seguro por definição, para não perder ninguém. Já `nin`/`not_in` seguem a semântica SQL de `NOT IN`, que em geral **exclui** registros com NULL. Os dois caminhos que o usuário lê como "não está" produzem **conjuntos diferentes** quando há nulos.

Hoje isso está documentado só no HelpTip do botão do **grupo** — e o botão NÃO da **regra** não tem HelpTip nenhum (§3.6). **Oportunidade clara de redesign:** unificar ou explicitar a diferença no ponto de escolha.

### 7.5 Operadores unários — efeito visual

Quatro operadores **suprimem o controle de valor** (§5.3.7):

```tsx
{!["is_null","is_not_null","is_empty","is_not_empty"].includes(rule.operator) && (
  <FilterValueInput ... />
)}
```

| Operador | Efeito na linha da regra |
|---|---|
| `is_null` ("e vazio") | A linha fica com 4 controles em vez de 5 — sobra espaço à direita |
| `is_not_null` ("nao e vazio") | Idem |
| `is_empty` ("vazio") | Idem |
| `is_not_empty` ("nao vazio") | Idem |

**Consequência de layout:** como a regra é um `flex ... flex-wrap`, a remoção do input faz os controles restantes **não** se redistribuírem — o botão de lixeira simplesmente fica mais à esquerda. Regras unárias e binárias na mesma lista têm larguras visuais diferentes, sem alinhamento de coluna.

### 7.6 Ambiguidade dos rótulos em português

| Rótulo exibido | Operador | Problema |
|---|---|---|
| "e vazio" | `is_null` | Sem acento no código (`é vazio`). E "vazio" aqui significa **NULL**, não string vazia |
| "vazio" | `is_empty` | Rótulo quase idêntico ao anterior, mas significa **array vazio**. Os dois nunca aparecem no mesmo dropdown (tipos diferentes), o que atenua — mas não elimina — a confusão |
| "nao e vazio" / "nao vazio" | `is_not_null` / `is_not_empty` | Mesmo par |
| "tem algum" | `in` | Lê bem para array (selos), estranho para `select` escalar ("Status tem algum: Pago") |
| "nao esta em" / "nao tem" | `nin` / `not_in` | Dois rótulos diferentes para a mesma operação lógica, separados só pelo tipo do campo |
| "contem (ignorar maiusculas)" | `ilike` | O rótulo mais longo da lista — estoura o `<select class="w-36">` (144px) e é truncado pelo browser |

`⚠️ A confirmar:` a largura fixa `w-36` do select de operador trunca pelo menos "contem (ignorar maiusculas)" e "maior ou igual a". Um redesign deve medir o rótulo mais longo ou trocar por um combobox com largura automática.

### 7.7 Onde os operadores são validados

| Camada | O que checa | Bloqueia? |
|---|---|---|
| `<select>` de operador | Só oferece operadores do tipo do campo | Sim — por construção |
| `FieldCombobox.onChange` | Mantém o operador se continuar válido; senão troca pelo 1º da lista | Sim |
| **Troca de tabela** | **Nada** — só troca o campo, mantém operador e valor | **Não** (§5.3.3) |
| `FilterRuleSchema` (Zod) | `operator` deve estar no enum de 18 | Sim, **mas não roda no save da UI** (§5.5.4) |
| `compile_filter_to_sql_v2` (backend) | Compila o operador contra a coluna | Fora do escopo deste documento |

**Resumo:** a única brecha real é a troca de tabela — e ela produz combinação inválida silenciosa.

---

## 8. Prévia do filtro (`FilterPreviewDialog`)

Arquivos: `src/components/filters/FilterPreviewDialog.tsx`, `src/components/filters/PreviewColumnPicker.tsx`, `src/lib/filters/preview-columns.ts`, `src/lib/filters/contact-enrichment.ts`, `src/lib/filters/export-pagination.ts`, `src/hooks/fetchFilterPreviewEnrichment.ts`.

### 8.1 O que a prévia é — e o que ela não é

| Pergunta | Resposta |
|---|---|
| Como se abre | Menu `⋯` → **Visualizar** (ícone `Eye`), nas duas visualizações da lista |
| Quem pode | **Qualquer um que chegue à tela** — não há checagem de permissão no item de menu |
| O que mostra | (a) as condições do filtro em linguagem legível; (b) 7 métricas agregadas do filtro inteiro; (c) uma **amostra de até 10 contatos** |
| O que **não** mostra | A lista completa — isso é a "carteira do filtro" (`FilterPortfolioModal`, §10.1), aberta por **Ver Contatos** |
| Recalcula? | **Sim, sempre.** Dispara `useFilterPreview()` a cada abertura; não usa o cache `cached_*` da lista |

**Distinção crítica de produto (comentário 6859 no código):** a amostra é **amostra**. Antes, isso era implícito e "o operador lia as linhas como *o resultado do filtro*". Hoje há uma frase literal acima da tabela:

> "Amostra de ate 10 contatos, ordenada pelo maior atraso. Os cartoes acima somam o filtro inteiro."

**Princípio a preservar:** a interface diz de onde vem cada número. Os 7 cartões somam o universo; as 10 linhas são uma janela.

### 8.2 O dialog

| Aspecto | Especificação |
|---|---|
| Componente | `Dialog` shadcn, `open={!!filter}` |
| Tamanho | `w-[95vw] h-[95vh] overflow-y-auto flex flex-col` — quase tela cheia, igual ao construtor |
| Título | Ícone `Filter h-5 w-5` + **"Visualizar Filtro"** |
| `DialogDescription` | `className="sr-only"` — "Visualize as condições do filtro e uma prévia dos resultados." (**só para leitores de tela**) |
| Rodapé | **Não existe.** Não há botão de fechar explícito além do `X` do Dialog e do ESC |
| Corpo | Dois `Card` empilhados (`space-y-6`): *Informações do filtro* e *Prévia dos Resultados* |

**Observação de layout:** o `DialogContent` tem `overflow-y-auto` **e** `flex flex-col` — a rolagem é do container inteiro, não de uma região interna. Com muitas condições, os 7 cartões saem da viewport.

### 8.3 Card 1 — Informações do filtro

| Região | Conteúdo |
|---|---|
| `CardHeader` | `CardTitle text-lg` com `filter.name` |
| Descrição | `<p class="text-muted-foreground mb-4">` — renderizada **só se** `filter.description` existir |
| Rótulo | `<p class="text-sm font-medium">Condições:</p>` |
| Corpo | `renderConditions(filter.conditions)` ou, se não houver `rules`, o texto **"Nenhuma condição definida"** |

#### 8.3.1 `renderConditions` — a tradução da árvore para leitura

Função recursiva local. Cada **regra** vira uma linha `flex items-center gap-2 text-sm` com 5 partes:

```
[E|OU]  Contato  →  Nome do Campo   contem   `valor`
```

| Parte | Especificação |
|---|---|
| Conector | Só a partir do segundo item. Regra: `text-xs font-medium text-primary uppercase bg-primary/10 px-1.5 py-0.5 rounded`. Grupo: `text-xs font-medium text-muted-foreground uppercase` (**sem** o fundo azul) |
| Entidade | Ternário literal: `contacts → "Contato"`, `contracts → "Contrato"`, **qualquer outra coisa → "Título"** |
| Seta | `<span class="text-muted-foreground">→</span>` |
| Campo | `getFieldLabel(table, field)` — busca em `FILTER_FIELDS` (`src/types/filters.ts`); se não achar, mostra o `field` cru |
| Operador | `OPERATOR_LABELS[operator]` em `text-primary` |
| Valor | `<span class="font-mono bg-muted px-1.5 py-0.5 rounded">{String(rule.value)}</span>` — omitido para `is_null`/`is_not_null` |

Cada **grupo aninhado** é envolvido em `ml-4 pl-4 border-l-2 border-muted` (indentação de 16px + barra à esquerda), recursivamente.

#### 8.3.2 Cinco defeitos conhecidos desta tradução

| # | Defeito | Consequência |
|---|---|---|
| 1 | **Rótulo de entidade errado para 5 das 8 tabelas** | `supplies`, `supply_titles`, `data_sources`, `actions` e `aging` são todas exibidas como **"Título"**. Um filtro de suprimento aparece como filtro de título |
| 2 | **`String(rule.value)` num array** | `["a","b"]` vira `a,b`; `[10, 50]` de um `between` vira `10,50` — sem indicar que são dois limites |
| 3 | **Valor de selo é UUID cru** | `seals in [uuid]` mostra o UUID, não o nome do selo |
| 4 | **Operadores unários incompletos** | Só `is_null`/`is_not_null` suprimem o valor. `is_empty`/`is_not_empty` mostram `<span>undefined</span>` ou o valor residual |
| 5 | **`negate` não é exibido** | Uma regra ou grupo com **NÃO (NOT)** ativo aparece aqui **exatamente igual** a uma sem negação. A prévia mente sobre a lógica |

O defeito 5 é o mais grave: a prévia é justamente a tela de conferência, e ela **omite a negação**.

`⚠️ A confirmar:` o defeito 1 pode ser resultado de o componente ser anterior ao IAF-4795 (suprimentos) e nunca ter sido atualizado. O mapa correto de rótulos já existe em `FilterRuleItem.tsx` (§5.3.3) — é reutilizável.

#### 8.3.3 Fonte de rótulos divergente

`FilterPreviewDialog` importa `FILTER_FIELDS` e `OPERATOR_LABELS` de **`@/types/filters`**, enquanto o construtor usa `FILTER_FIELDS_REGISTRY` e `OPERATOR_LABELS` de **`@/lib/filters/fields`**.

`⚠️ A confirmar:` são dois catálogos de campo no produto. Se divergirem, o mesmo campo aparece com um rótulo no construtor e outro na prévia. Verificar se `src/types/filters.ts` re-exporta de `lib/filters/fields` ou mantém uma cópia própria — se for cópia, é dívida a consolidar no redesign.

### 8.4 Card 2 — Prévia dos Resultados

#### 8.4.1 Cabeçalho do card

| Elemento | Especificação |
|---|---|
| Título | Ícone `Users h-5 w-5` + **"Prévia dos Resultados"**, `text-lg` |
| Controle 1 | `PreviewColumnPicker` (§8.6) |
| Controle 2 | Botão recarregar — `variant="outline" size="sm"`, ícone `RefreshCw h-4 w-4`, vira `Loader2 animate-spin` quando `preview.isPending`, `disabled` durante o cálculo |

**O botão de recarregar não tem rótulo, `title` nem `aria-label`** — é um ícone solto. `⚠️ A confirmar:` falha de acessibilidade a corrigir no redesign.

#### 8.4.2 Os 7 cartões de métrica

`<div class="grid grid-cols-7 gap-2 mb-6">` — **sempre 7 colunas, sem responsividade declarada**.

| # | Rótulo | Ícone | Cor | Fonte do valor | Formato |
|---|---|---|---|---|---|
| 1 | Contatos | `Users` | `text-primary` | `contactCount ?? count` | `toLocaleString("pt-BR")` |
| 2 | Contratos | `FileStack` | `text-muted-foreground` | `contractCount ?? 0` | `toLocaleString("pt-BR")` |
| 3 | Titulos | `FileText` | `text-muted-foreground` | `titleCount ?? 0` | `toLocaleString("pt-BR")` |
| 4 | Valor Total | `Banknote` | `text-muted-foreground` | `totalValue ?? 0` | **`formatCurrency` com 2 casas decimais** |
| 5 | Valor Pago | `CircleCheck` | `text-emerald-600` (ícone **e** número) | `paidValue ?? 0` | moeda |
| 6 | Em Aberto | `CircleAlert` | `text-orange-500` | `openValue ?? 0` | moeda |
| 7 | Vencido | `DollarSign` | `text-red-500` | `overdueValue ?? 0` | moeda |

Estrutura de cada cartão: `text-center p-3 bg-muted/50 rounded-lg` → ícone `h-5 w-5 mx-auto mb-1` → valor em `text-lg font-bold` → rótulo em **`text-[10px]`**.

**Três problemas de escala visual:**

1. `grid-cols-7` fixo em `w-[95vw]`: num monitor de 1366px, cada cartão tem ~180px. Um valor como `R$ 1.234.567,89` **estoura** o cartão de 180px em `text-lg font-bold`.
2. O rótulo em `text-[10px]` está abaixo do mínimo confortável (o card da lista usa `text-[9px]` — §4.5). Mesmo problema, dois valores diferentes.
3. **Formato de moeda divergente:** aqui a moeda tem **2 casas decimais**; na lista (`FiltersPage`) tem **0 casas** e é compactada (`R$ 1.2M`). O mesmo filtro mostra `R$ 1.2M` na lista e `R$ 1.234.567,89` na prévia — o operador não tem como cruzar os dois de relance.

**Ausência notável:** os cartões **não** têm indicador de frescor (`StatsFreshnessIndicator`) nem tratamento de erro parcial. A prévia é tudo-ou-nada.

#### 8.4.3 A tabela de amostra

| Aspecto | Especificação |
|---|---|
| Container | `<div class="overflow-x-auto">` com `<table class="w-full text-sm">` (tabela HTML crua, **não** o componente `Table` do shadcn) |
| `<caption>` | `sr-only` — "Amostra dos contatos que casam com o filtro. Colunas marcadas como 'no filtro' agregam apenas os títulos que casaram; as demais são totais do contato, iguais aos da Gestão de Carteira." |
| Cabeçalho | `<th scope="col">` com `py-2 px-3 font-medium whitespace-nowrap`, alinhamento por `column.align`, `title={column.description}` |
| Linha | `<tr class="border-b">`, key = `contact_id` |
| Célula | `py-2 px-3` + alinhamento |
| Máximo de linhas | **10** (definido pelo backend do preview) |
| Ordenação | Maior atraso primeiro (declarado na frase acima da tabela; ordenação vem do backend) |
| Linha clicável? | **Não** — diferente do `FilterPortfolioModal`, aqui a linha não abre o detalhe do contato |

#### 8.4.4 `renderPreviewCell` — a formatação de célula

Ordem de decisão:

| Ordem | Condição | Saída |
|---|---|---|
| 1 | `column.id` é `filter_days_overdue` **ou** `max_days_overdue` | `<OverdueBadge daysOverdue={raw} />` — badge compartilhado (PORT-15): negativo = `D-x` preventivo, `0` = "Vence hoje", `null` = neutro |
| 2 | `raw` é `null`, `undefined` ou `""` | **`"-"`** |
| 3 | `raw` é array | Junta com `", "`, extraindo `name ?? label ?? id` de cada objeto; se vazio → `"-"` |
| 4 | `column.format === "currency"` | `Intl.NumberFormat("pt-BR", BRL)` — **2 casas** |
| 5 | `column.format === "number"` | `toLocaleString("pt-BR")` |
| 6 | `column.format === "date"` | `formatPreviewDate(raw)` |
| 7 | `typeof raw === "boolean"` | `"Sim"` / `"Não"` |
| 8 | fallback | `String(raw)` |

**Invariante de produto declarada no comentário:** valor ausente vira `"-"`, **nunca `0` nem string vazia** — "'0' e 'não sei' são leituras diferentes, e confundi-las é o tipo de erro que faz alguém concluir que um contato não deve nada."

**Divergência:** o `FilterPortfolioModal` tem sua própria `renderColumnValue`, quase idêntica, mas com um `case "boolean"` explícito no `switch` (em vez do `typeof` no fallback). **Duas implementações da mesma formatação** — candidatas a consolidação.

### 8.5 As duas semânticas de valor — a sutileza central desta tela

Documentada no cabeçalho de `src/lib/filters/preview-columns.ts`:

| `valueScope` | O que agrega | Exemplos |
|---|---|---|
| `"filter"` | **Apenas os títulos que casaram com o filtro** | `filter_total_debt`, `filter_overdue_value`, `filter_days_overdue`, `filter_title_count`, `filter_contract_count`, `filter_contract_number` |
| `"contact"` | **O contato inteiro**, pré-calculado na MV — os **mesmos** números da Gestão de Carteira | `total_open_value`, `max_days_overdue`, `total_titles`, campos personalizados etc. |

**Por que isso importa:** sem a distinção, "Valor em Aberto" mostraria um número aqui e outro na carteira, **com o mesmo rótulo**. A solução adotada foi:

1. as colunas de recorte ganham o sufixo literal **"(no filtro)"** no rótulo;
2. o `PreviewColumnPicker` marca cada uma com o selo textual **`filtro`** (`text-[10px]`), com `title` explicando;
3. a `<caption>` `sr-only` da tabela repete a distinção para leitores de tela.

**As 6 colunas exclusivas do filtro (`FILTER_SCOPED_COLUMNS`):**

| `id` | Rótulo | Categoria | Formato | Alinhamento | `accessor` | `description` |
|---|---|---|---|---|---|---|
| `filter_contract_number` | Contrato (no filtro) | Associações | — | esquerda | `contract_number` | "Número do contrato quando o filtro casou com um só; caso contrário, quantos contratos casaram." |
| `filter_total_debt` | Em aberto (no filtro) | Financeiro | `currency` | direita | `total_debt` | "Soma do valor em aberto APENAS dos títulos que casaram com o filtro." |
| `filter_overdue_value` | Vencido (no filtro) | Financeiro | `currency` | direita | `overdue_value` | "Soma do valor vencido APENAS dos títulos que casaram com o filtro." |
| `filter_days_overdue` | Atraso (no filtro) | Quantidades | — | direita | `days_overdue` | "Maior atraso ENTRE OS TÍTULOS que casaram com o filtro." |
| `filter_title_count` | Títulos (no filtro) | Quantidades | `number` | centro | `title_count` | *(sem descrição)* |
| `filter_contract_count` | Contratos (no filtro) | Quantidades | `number` | centro | `contract_count` | *(sem descrição)* |

**Lacuna:** `filter_title_count` e `filter_contract_count` são as **únicas duas** sem `description` — logo sem `title` no cabeçalho e sem tooltip no picker. Inconsistência trivial de corrigir.

**Observação de acentuação:** essas 6 colunas são as **únicas** do domínio de filtros com acentuação completa ("Títulos", "Associações"). Todo o resto do registry de campos está sem acento (§6).

### 8.6 `PreviewColumnPicker` — o seletor de colunas

`src/components/filters/PreviewColumnPicker.tsx`. Usado por **dois** modais: a prévia e a carteira do filtro.

| Aspecto | Especificação |
|---|---|
| Gatilho | `Button variant="outline" size="sm"`, ícone `Columns3 h-4 w-4 mr-2`, rótulo **`Colunas (N)`** onde N = quantidade selecionada. `data-testid="preview-column-picker"` |
| Popover | `w-80 p-0`, `align="end"` |
| Topo | Campo de busca — `Input` com ícone `Search` absoluto (`left-2 top-2.5`), `placeholder="Buscar coluna..."`, `pl-8 h-9` |
| Nota explicativa | `text-[11px] text-muted-foreground` — "Mesmo catálogo dinâmico da Gestão de Carteira. Campos sem valor no contato aparecem vazios, mas continuam selecionáveis." |
| Separador | `<Separator />` acima e abaixo da lista |
| Lista | `<ScrollArea className="h-72">` (288px fixos) com `p-3 space-y-4` |
| Agrupamento | Por `column.category`, com cabeçalho `text-xs font-semibold text-muted-foreground uppercase` |
| Item | `Checkbox` + `Label` clicável (`text-sm font-normal`, `title={column.description}`) |
| Selo de escopo | `<span class="text-[10px] text-muted-foreground" title="Valor agregado APENAS sobre os títulos que casaram com o filtro.">filtro</span>` — só quando `valueScope === "filter"` |
| Busca vazia | "Nenhuma coluna encontrada." (`text-sm text-muted-foreground text-center py-6`) |
| Rodapé | `Button variant="ghost" size="sm" className="w-full"` → **"Restaurar colunas padrão"** |

#### 8.6.1 Busca — comportamento exato

```ts
const term = search.trim().toLocaleLowerCase("pt-BR");
if (term && !column.label.toLocaleLowerCase("pt-BR").includes(term)) continue;
```

Casa **só pelo rótulo**, não pela categoria nem pela descrição. Case-insensitive com locale `pt-BR`, mas **sem normalização de acento** — buscar "titulos" não encontra "Títulos".

#### 8.6.2 As 6 colunas padrão (`DEFAULT_PREVIEW_COLUMN_IDS`)

| Ordem | `id` | Origem |
|---|---|---|
| 1 | `name` | Carteira (`contact_name`) |
| 2 | `filter_contract_count` | Filtro |
| 3 | `filter_title_count` | Filtro |
| 4 | `filter_days_overdue` | Filtro |
| 5 | `filter_total_debt` | Filtro |
| 6 | `filter_overdue_value` | Filtro |

Comentário no código: "as seis que a tela já mostrava" — a seleção de colunas foi adicionada depois (6859) preservando o layout anterior como padrão.

#### 8.6.3 Ordem das colunas selecionadas — o detalhe não óbvio

```ts
const selectedColumns = selectedIds
  .map((id) => catalog.available.find((c) => c.id === id))
  .filter(Boolean);
```

A ordem das colunas na tabela é a **ordem do array `selectedIds`**, ou seja, **a ordem em que o usuário foi marcando** — não a ordem do catálogo. Desmarcar e remarcar uma coluna a **joga para o fim da tabela**.

`⚠️ A confirmar:` isso é comportamento emergente, não intencional. Não há reordenação por arraste nem restauração da ordem canônica (o "Restaurar colunas padrão" corrige, mas descarta toda a seleção).

#### 8.6.4 Diferença de comportamento entre os dois consumidores

| | `FilterPreviewDialog` | `FilterPortfolioModal` |
|---|---|---|
| `toggleColumn` ao desmarcar a última | **Permite chegar a zero colunas** | **Bloqueia** — `current.length === 1 ? current : filter(...)` |
| Consequência | Tabela renderiza `<thead>` e `<tbody>` vazios, sem mensagem | Sempre resta ao menos 1 coluna |

**Divergência real entre dois usos do mesmo componente.** No redesign, escolher um dos dois comportamentos.

#### 8.6.5 Persistência — decisão explícita de NÃO compartilhar

Comentário no topo do arquivo, literal:

> "Aquele componente [`PortfolioColumnToggle`] grava a escolha direto em `localStorage`, na chave global `portfolio-column-visibility` — a mesma da Gestão de Carteira, sem escopo de organização nem de usuário. Reusá-lo aqui faria escolher uma coluna no preview de um filtro MUDAR a grade da carteira, e vice-versa. O card pede que as duas telas CONVERSEM, e conversar não é compartilhar estado por acidente."

Resultado:

| O que é compartilhado | O que **não** é |
|---|---|
| O **catálogo** (`buildPreviewColumnCatalog` a partir de `DEFAULT_COLUMNS`) — mesmo `id`, rótulo, categoria, formato, alinhamento e descrição | A **seleção** — local a cada dialog, em `useState`, **perdida ao fechar** |

**Consequência de UX:** toda vez que o operador abre a prévia ou a carteira de um filtro, ele volta às 6 colunas padrão. Se ele trabalha sempre com as mesmas 12 colunas, refaz a seleção **toda vez**.

`⚠️ A confirmar:` o redesign provavelmente quer persistência — mas **com escopo próprio** (por usuário + org + "preview de filtro"), nunca reusando a chave da carteira. A decisão de não compartilhar é deliberada e deve ser preservada.

#### 8.6.6 `unavailable` — contrato morto

`buildPreviewColumnCatalog` sempre devolve `unavailable: []`. O `PreviewColumnPicker` ainda renderiza o ramo (checkbox desabilitado + ícone `Info` + `sr-only` com o motivo), mas **ele nunca aparece**. Comentário: "permanece no contrato apenas por compatibilidade defensiva com consumidores antigos".

Um redesign pode remover — ou reaproveitar o padrão visual, que é bom (explica por que o controle está desabilitado).

### 8.7 Enriquecimento da amostra — a segunda consulta

A prévia faz **duas** buscas, não uma:

| # | O quê | Hook | Quando |
|---|---|---|---|
| 1 | Contagens + amostra de 10 | `useFilterPreview()` (mutation) | `useEffect` a cada troca de `filter` |
| 2 | Valores das colunas selecionadas para essas 10 linhas | `useQuery` → `fetchFilterPreviewEnrichment(context, sample, selectedColumns)` | `enabled: Boolean(filter && preview.data && !preview.isPending)`, `staleTime: 60_000` |

Query key: `["filter-preview-columns", org.slug, sample, selectedColumns]` — **inclui o array `sample` inteiro e o array de colunas como objetos**.

`⚠️ A confirmar:` usar objetos grandes na query key força serialização a cada render e invalida o cache sempre que a referência muda. Como `sample` é recriado por `useMemo` sobre `preview.data?.sample`, a referência é estável enquanto o preview não refizer — mas `selectedColumns` também é `useMemo`. Funciona, mas é frágil. Marcar como dívida técnica que o redesign não precisa herdar.

**Consequência visível:** trocar uma coluna no picker **dispara uma nova consulta** ao banco para as mesmas 10 linhas. Não há debounce.

### 8.8 Estados do card de prévia

Ordem literal do ternário aninhado em `CardContent`:

| # | Condição | O que aparece |
|---|---|---|
| 1 | `preview.isPending` | `<Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />` centralizado, `py-8`. **Sem texto** |
| 2 | `preview.isError` | `<div class="text-center py-8 text-destructive">Erro ao carregar prévia</div>` — **sem motivo, sem botão de retentar** |
| 3 | `preview.data` **e** `sample.length > 0` | Cartões + frase da amostra + tabela |
| 4 | `preview.data` **e** `sample.length === 0` | Ícone `FileText h-12 w-12` + **"Nenhum registro encontrado com este filtro"**, `text-center py-8 text-muted-foreground`. **Os 7 cartões continuam visíveis** (todos zerados) |
| 5 | `preview.data` é `null`/`undefined` | **`null`** — o card fica com o cabeçalho e o corpo vazio |

#### 8.8.1 Estados aninhados da tabela de amostra

Dentro do `<tbody>`, um segundo ternário para a consulta de enriquecimento:

| Condição | Linha renderizada |
|---|---|
| `enrichedPreview.isPending` | `<td colSpan={N} class="py-4 text-center text-muted-foreground">Carregando as colunas da amostra...</td>` |
| `enrichedPreview.isError` | `<td colSpan={N} class="py-4 text-center text-destructive">Não foi possível consultar as colunas da amostra.` + `<Button variant="outline" size="sm">Tentar novamente</Button>` |
| sucesso | As linhas |

**Contraste que expõe a inconsistência:** o erro **interno** (colunas) tem mensagem específica **e** botão de retentar. O erro **externo** (prévia inteira) não tem nem um nem outro. O caminho de erro menos importante é melhor tratado que o mais importante.

**Este é o único ponto do domínio que viola a invariante "erro ≠ vazio, e erro diz o porquê"** (§2.13, §5.5.6). Correção obrigatória no redesign.

### 8.9 Exportação — onde ela realmente vive

**A prévia NÃO exporta.** A exportação CSV existe apenas no `FilterPortfolioModal` ("Ver Contatos"), detalhado em §10.1. O mecanismo, porém, é do domínio de filtros e está documentado aqui.

#### 8.9.1 `collectFilterExportRows` — paginação defensiva

`src/lib/filters/export-pagination.ts`.

| Constante | Valor |
|---|---|
| `FILTER_EXPORT_MAX_ROWS` | **10.000** |
| `FILTER_EXPORT_PAGE_SIZE` | **500** |

Loop de até **20 páginas** (`10000 / 500`), chamando a RPC `get_filter_contacts_paginated`.

**Sete invariantes verificadas a cada página — todas abortam a exportação inteira:**

| # | Verificação | Mensagem de erro (literal) |
|---|---|---|
| 1 | Resposta não é array | `Resposta inválida ao exportar os contatos.` |
| 2 | Página 1 vazia | *(não é erro — devolve `[]`, nada a exportar)* |
| 3 | Página > 1 vazia | `Os contatos mudaram durante a exportação. Tente novamente.` |
| 4 | Item não é objeto | `Resposta inválida ao exportar os contatos.` |
| 5 | `total_count` não é inteiro seguro ≥ 1 | `Contagem inválida ao exportar os contatos.` |
| 6 | `total > 10.000` | `O filtro excede o limite de 10.000 contatos por CSV. Refine o filtro para exportar sem cortes.` |
| 7 | `total_count` mudou entre páginas, `contact_id` ausente/não-string, ou **`contact_id` duplicado** | `Os contatos mudaram durante a exportação. Tente novamente.` |
| 8 | Página com tamanho diferente do esperado | `A consulta retornou contatos incompletos. Tente novamente; nenhum CSV parcial foi gerado.` |
| 9 | Loop terminou sem atingir `total` | `Não foi possível obter todos os contatos. Nenhum CSV parcial foi gerado.` |

**Princípio de produto explícito (comentário no código e nas mensagens):** *nenhum CSV parcial é gerado*. Um CSV com 8.500 de 10.000 linhas é indistinguível de um CSV completo e vira decisão errada de cobrança. A frase "nenhum CSV parcial foi gerado" aparece **literalmente** em duas das mensagens — é tranquilização deliberada.

#### 8.9.2 Geração do CSV (`exportRowsToCsv`)

| Aspecto | Especificação |
|---|---|
| Separador | **`;`** (ponto e vírgula — padrão Excel pt-BR) |
| Quebra de linha | `\n` |
| BOM | `"﻿" + csv` — garante acentuação correta no Excel |
| MIME | `text/csv;charset=utf-8;` |
| Nome do arquivo | `filtro-{nome do filtro}-{YYYY-MM-DD}.csv` |
| Cabeçalho | Os `label` das colunas selecionadas |
| Colunas exportadas | **Exatamente as selecionadas no picker** — por isso o botão mostra a contagem: `Exportar CSV (6)` |
| Download | `<a>` criado em memória + `.click()` + `URL.revokeObjectURL` |

#### 8.9.3 Proteção contra injeção de fórmula (`csvCell`)

```ts
const protectedValue = /^[\s -]*[=+\-@]/.test(flat) ? `'${flat}` : flat;
return `"${protectedValue.replace(/"/g, '""')}"`;
```

| Regra | Efeito |
|---|---|
| Valor começa com `=`, `+`, `-` ou `@` (após espaços/controles) | Recebe prefixo `'` — neutraliza fórmula do Excel/Sheets |
| Aspas internas | Duplicadas (`""`) |
| Todo valor | Envolvido em aspas |
| `null`/`undefined` | `""` (string vazia entre aspas) |
| Array | `formatPreviewArray` — junta com `", "`, extraindo `name ?? label ?? id` |

**Isto é uma proteção de segurança real (CSV injection).** Um redesign que reescreva a exportação **precisa preservá-la**.

**Efeito colateral visível:** um telefone gravado como `-11999998888` ou um valor negativo exportado como texto ganham uma aspa simples à esquerda no Excel. É o preço aceito.

#### 8.9.4 Formatação dos valores no CSV

| `column.format` | Tratamento no CSV |
|---|---|
| `currency` | `formatCurrency` — **texto formatado** `R$ 1.234,56`, não número |
| `date` | `formatPreviewDate` |
| `boolean` | `"Sim"` / `"Não"` |
| demais | Valor cru via `csvCell` |

**Consequência:** a coluna de moeda chega ao Excel como **texto**, não como número — não soma sem tratamento. `⚠️ A confirmar:` se o usuário prefere número cru (somável) ou texto formatado (legível). Hoje é texto.

### 8.10 Resumo das lacunas da prévia

| # | Lacuna | Gravidade |
|---|---|---|
| 1 | `negate` (NÃO/NOT) não aparece na tradução das condições | **Alta** — a tela de conferência esconde parte da lógica |
| 2 | 5 de 8 tabelas rotuladas como "Título" | **Alta** — filtro de suprimento parece filtro de título |
| 3 | Erro sem motivo e sem retentar | **Alta** — viola a invariante do domínio |
| 4 | Sem exportação na prévia (só na carteira) | Média |
| 5 | Seleção de colunas não persiste | Média |
| 6 | Valores de array e `between` renderizados como `String()` | Média |
| 7 | `grid-cols-7` fixo estoura em telas médias | Média |
| 8 | Botão de recarregar sem rótulo acessível | Média |
| 9 | Duas casas decimais aqui × zero na lista | Baixa, mas confunde |
| 10 | Ordem das colunas = ordem de clique | Baixa |
| 11 | Linhas da amostra não são clicáveis (na carteira, são) | Baixa |

---

## 9. Portfólios (carteiras)

Arquivos: `src/components/portfolios/PortfoliosTab.tsx`, `PortfolioDialog.tsx`, `PortfolioIntegrationsPanel.tsx`, `src/hooks/usePortfolios.ts`, `src/hooks/usePortfolioIntegrations.ts`, `src/types/portfolios.ts`, `src/pages/ETLPage.tsx`.

> **Lembrete de localização (§0.4):** os portfólios **não** vivem em `/filters`. São a aba **"Carteiras"** de `/etl`, protegida por `etl:read`.

### 9.1 Vocabulário — três nomes para a mesma coisa

| Onde | Nome usado |
|---|---|
| Banco / tipos / arquivos | `portfolio`, `portfolios`, `Portfolio` |
| Aba e botões da interface | **"Carteiras"**, "Nova Carteira" |
| Guias de negócio do app | "carteiras (portfólios)" |

**O código inteiro fala "portfolio"; a interface inteira fala "carteira".** Um redesign deve escolher um termo de UI e mantê-lo — hoje o operador nunca vê a palavra "portfólio", mas o desenvolvedor nunca vê "carteira".

**Colisão adicional:** existe também a tela **"Gestão de Carteira"** (`/portfolio`), que é o kanban/grade de contatos — **outra coisa**. "Carteira" no produto significa (a) o segmento configurado aqui e (b) a tela de gestão. As duas convivem sem desambiguação visual.

### 9.2 Modelo de dados (`src/types/portfolios.ts`)

```ts
interface Portfolio {
  id: string;
  name: string;
  description: string | null;
  color: string | null;
  icon: string | null;
  definition_type: "field" | "filter";
  field_name: string | null;
  field_values: string[] | null;
  filter_conditions: FilterGroup | null;     // legado inline
  filter_definition_id: string | null;       // vínculo com um filtro salvo
  responsible_user_id: string | null;
  cached_contract_count: number;
  cached_contact_count: number;
  cached_total_debt: number;
  cached_avg_days_overdue: number;
  stats_updated_at: string | null;
  is_active: boolean;
  display_order: number;
  created_at: string;
  updated_at: string;
}
```

**Campos do modelo que a interface NÃO expõe:**

| Campo | Situação na UI |
|---|---|
| `responsible_user_id` | **Nenhum controle.** Não há atribuição de responsável em lugar nenhum do `PortfolioDialog` |
| `is_active` | **Nenhum controle.** Diferente dos filtros, a carteira não pode ser desativada pela tela (`transformCreate` força `true`). O parâmetro `activeOnly` existe no hook, mas a aba não o usa |
| `display_order` | **Nenhum controle.** Sempre `0` na criação, e é o critério de ordenação da lista (`orderBy: "display_order"`). Não há arraste para reordenar |
| `filter_conditions` | Legado inline. A UI nunca o preenche — só `filter_definition_id` |

**Consequência:** a lista é ordenada por um campo que ninguém consegue editar. Na prática, todas as carteiras têm `display_order = 0` e a ordem final fica a critério do banco.

### 9.3 Os dois tipos de definição

| `definition_type` | Campos usados | Semântica | Onde se configura |
|---|---|---|---|
| `field` (**padrão**) | `field_name` + `field_values[]` | "Pertence quem tem o campo X com **um dos** valores Y" (OR-of-IN) | Aba "Por Campo" |
| `filter` | `filter_definition_id` | "Pertence quem casa com **este filtro salvo**" | Aba "Por Filtro" |

Ordem de resolução no backend (`evaluate_portfolios_batch`): `filter_conditions` inline → `filter_definition_id` → `definition_type='field'` → zeros.

#### 9.3.1 Os 5 campos disponíveis no modo "Por Campo" (`PORTFOLIO_FIELD_OPTIONS`)

| `value` | Rótulo exibido | Tabela |
|---|---|---|
| `modality` | Modalidade | `contracts` |
| `status` | Status do Contrato | `contracts` |
| `custom_fields.cedente` | Cedente | `contracts` |
| `custom_fields.carteira` | Carteira (campo customizado) | `contracts` |
| `custom_fields.segmento` | Segmento | `contracts` |

**Esta lista é HARDCODED.** Ao contrário dos filtros (88 campos + dinâmicos), a carteira "Por Campo" só enxerga **5 campos fixos**, três deles assumindo que a org tem exatamente os custom fields `cedente`, `carteira` e `segmento`. Uma org que chame seu campo de `originador` em vez de `cedente` **não consegue** criar carteira por campo sobre ele — precisa criar um filtro e usar o modo "Por Filtro".

**Lacuna óbvia para o redesign:** essa lista deveria ser derivada dos custom fields reais da org (o mecanismo já existe — `useMappedFilterFields`, §5.3.9).

**Ironia do item 4:** existe um campo chamado "Carteira (campo customizado)" dentro do formulário de criação de Carteira. Três sentidos de "carteira" na mesma tela.

#### 9.3.2 Como os valores do campo são descobertos (`useFieldValues`)

`src/hooks/usePortfolios.ts`:

| Aspecto | Comportamento |
|---|---|
| Consulta | `contracts.select(column).not(column, "is", null).limit(100)` |
| Campo customizado | `custom_fields->{coluna}`, mesmo padrão |
| Deduplicação | `new Set()` no cliente |
| Ordenação | `Array.from(values).sort()` — **sort padrão do JS**, não `localeCompare("pt-BR")` |
| Cache | `staleTime: 2 minutos` |
| Tipo aceito | **Só strings** — valores não-string são descartados silenciosamente |

**Três problemas:**

1. **`limit(100)` é sobre LINHAS, não sobre valores distintos.** Se os 100 primeiros contratos tiverem todos a mesma modalidade, a lista de valores terá **1 item**, e o usuário conclui que a org só tem uma modalidade. Não há aviso de truncamento.
2. **`sort()` sem locale** ordena por code point: "Ágil" vem depois de "Zeta".
3. A consulta lê `contracts` diretamente — **não** `vw_titles_live` —, então valores que só existem em contratos removidos/inativos também aparecem.

`⚠️ A confirmar:` os três são bugs latentes, não decisões. O #1 é o mais grave: produz carteira incompleta sem sintoma.

### 9.4 A lista de carteiras (`PortfoliosTab`)

#### 9.4.1 Consulta

```ts
const { data, isLoading } = usePortfolios({ search: search || undefined, pageSize: 50 });
```

| Parâmetro | Valor |
|---|---|
| `pageSize` | **50** (fixo) |
| Ordenação | `display_order` ascendente (fixa, não configurável) |
| Busca | `name` e `description` (`searchFields` da factory) |
| Paginação | **NÃO EXISTE NA UI.** Com 51+ carteiras, as demais ficam invisíveis, sem aviso |

**Diferença marcante com a tela de Filtros:** filtros têm busca na URL, ordenação, tri-state, filtro por cor e paginação. Carteiras têm **só busca** — e nem ela está na URL.

#### 9.4.2 Cabeçalho da aba

| Elemento | Especificação | Origem |
|---|---|---|
| Contador | `<p class="text-muted-foreground">{total} carteiras encontradas</p>` | `PortfoliosTab` |
| `ViewToggle` | lista ⇄ card, `useViewPreference("portfolios")` → `localStorage` | `PortfoliosTab` |
| `RefreshButton` | `variant="outline" size="sm"`, **com rótulo visível** "Atualizar Estatísticas", `title` e `Tooltip` "Recalcular estatísticas de todas as carteiras" | `PortfoliosTab` |
| Busca | Campo do cabeçalho do **ETLPage**, `placeholder="Buscar carteiras..."` | `ETLPage` |
| Botão criar | **"Nova Carteira"** no cabeçalho do **ETLPage**, chama `portfoliosTabRef.current?.openCreateModal()` | `ETLPage` |

**Padrão arquitetural incomum:** o botão de criar mora no componente pai e alcança o filho por `forwardRef` + `useImperativeHandle`. O `PortfoliosTab` expõe uma única API: `openCreateModal()`.

**Redundância tripla no `RefreshButton`:** ele tem `label` visível **e** `title` HTML **e** um `Tooltip` shadcn com o mesmo texto. Na tela de Filtros o mesmo botão é só ícone (`title` + `Tooltip`). Dois padrões para o mesmo controle.

#### 9.4.3 Visualização Lista — 6 colunas

| # | Cabeçalho | Conteúdo |
|---|---|---|
| 1 | `Nome` | Quadrado `p-1.5 rounded-md` com fundo `cor+20` + `DynamicIcon` na cor cheia; nome em `font-medium`; descrição abaixo em `text-xs truncate max-w-[200px]` |
| 2 | `Tipo` | `field` → ícone `Tag` + **o `field_name` cru** (ex.: `custom_fields.cedente`). `filter` → ícone `Filter` + a palavra "Filtro" |
| 3 | `Contratos` | `contractCount.toLocaleString("pt-BR")`, `font-medium` |
| 4 | `Contatos` | `contactCount`, `font-medium` |
| 5 | `Dívida Total` | `formatCurrency(totalDebt)`, `font-medium text-emerald-600` |
| 6 | *(menu)* | `w-[70px]`, `DropdownMenu` com `MoreHorizontal` |

**Três observações:**

1. A coluna "Tipo" no modo `field` mostra **`custom_fields.cedente`** literalmente — o nome técnico, não o rótulo "Cedente". No card, o mesmo dado aparece como "Por campo: custom_fields.cedente".
2. **A linha NÃO é clicável.** Diferente da tela de Filtros (linha inteira abre a edição), aqui só o menu `⋯` age. Os números também não são clicáveis.
3. `avgDaysOverdue` (dias médios em atraso) **existe nos dados mas não aparece na Lista** — só no card. Assimetria entre as duas visões, igual à da tela de Filtros (§3.4).

**Cor de "Dívida Total":** `text-emerald-600` (verde). Na tela de Filtros, verde é **Valor Pago** e laranja é **Em Aberto**. Aqui, dívida (dinheiro a receber) é verde. **Semântica de cor contraditória entre as duas telas.**

#### 9.4.4 Visualização Card

| Região | Conteúdo |
|---|---|
| Borda esquerda | `borderLeftWidth: 4px`, `borderLeftColor: portfolio.color \|\| "#6B7280"` (cinza como fallback) |
| Cabeçalho | Quadrado `p-2 rounded-lg` com fundo `cor+20` e ícone `h-5 w-5`; nome em `font-semibold truncate`; descrição em `text-sm line-clamp-1` |
| Canto direito | `DropdownMenu` (`h-8 w-8`) |
| Selo de tipo | `text-xs text-muted-foreground bg-muted/50 px-2 py-1 rounded` — "Por campo: {field_name}" ou "Por filtro" |
| Bloco de stats | `grid grid-cols-2 gap-2 py-2 px-3 bg-muted/30 rounded-lg` |
| — célula 1 | `FileText` primary + `contractCount` + "contratos" |
| — célula 2 | `Users` `text-blue-500` + `contactCount` + "contatos" |
| — célula 3 | `DollarSign` `text-emerald-600` + `formatCurrency(totalDebt)` **sem rótulo** |
| — célula 4 | `Calendar` `text-orange-500` + `Math.round(avgDaysOverdue)` + "dias médios" |
| Rodapé | "Stats atualizados em dd/MM/yyyy 'às' HH:mm" **ou**, se nunca calculado, "Criada em dd/MM/yyyy" |

**Detalhes:**

- **A célula 3 (dívida) é a única sem rótulo textual.** As outras três dizem "contratos", "contatos", "dias médios". O valor monetário fica órfão — só o ícone `DollarSign` e a cor o identificam.
- **O card NÃO tem checkbox de seleção** e **não há seleção múltipla nem exclusão em massa** de carteiras (a tela de Filtros tem as duas).
- **O card NÃO é clicável** — nem o card, nem o bloco de stats.
- O rodapé é **mutuamente exclusivo**: ou mostra quando as stats foram calculadas, ou quando a carteira foi criada. Nunca os dois.

#### 9.4.5 Menu de ações (idêntico nas duas visões)

| Ordem | Item | Ícone | Ação |
|---|---|---|---|
| 1 | Editar | `Edit` | `handleEdit(portfolio)` — abre o `PortfolioDialog` |
| — | *(separador)* | — | **Não.** O separador fica entre 2 e 3 |
| 2 | Atualizar Stats | `RefreshCw` | `refreshStats.mutateAsync(id)` → EF `evaluate-portfolio` com `update_cache: true` |
| — | `DropdownMenuSeparator` | — | — |
| 3 | Excluir | `Trash2`, `text-destructive` | `handleDelete(portfolio)` |

**Não há:** Duplicar, Visualizar, Ver Contatos, Ativar/Desativar. A tela de Filtros tem as quatro primeiras — carteiras têm **três ações no total**.

**Nenhum item é gateado por permissão.** O acesso inteiro depende de `etl:read` na rota; dentro da aba, quem entra pode criar, editar e excluir. Comparar com `/filters`, que separa `filters:read`/`write`/`delete`.

#### 9.4.6 Exclusão — `confirm()` nativo

```ts
if (confirm(`Tem certeza que deseja excluir a carteira "${portfolio.name}"?`)) {
  await deletePortfolio.mutateAsync(portfolio.id);
}
```

**Este é o único ponto do domínio Filtros+Carteiras que ainda usa `window.confirm()`.** A tela de Filtros migrou para `AlertDialog` no PORT-10 justamente para eliminar isso (comentário: "confirm() nativo → AlertDialog (mesmo padrão do bulk)"). A aba de Carteiras ficou para trás.

Consequências: diálogo do sistema operacional, fora do design system, sem estado de carregamento, sem botão destrutivo estilizado, sem foco gerenciado.

**Correção obrigatória no redesign.**

Em caso de erro, o `catch` é **vazio de propósito** — o hook da factory já dispara o toast destrutivo com a mensagem real (comentário explícito no código).

#### 9.4.7 Estatísticas — três caminhos

| Caminho | Quando | Mecanismo |
|---|---|---|
| `cached_*` | Fallback sempre disponível | 4 colunas: `cached_contract_count`, `cached_contact_count`, `cached_total_debt`, `cached_avg_days_overdue` |
| `usePortfoliosStats` | Ao carregar a aba | **1 RPC** `evaluate_portfolios_batch` (agregação SQL sobre `vw_titles_live`) para todas as carteiras. **Não escreve no cache** (`p_update_cache` ausente de propósito) |
| `useRefreshPortfolioStats` | Menu → "Atualizar Stats" | EF `evaluate-portfolio` com `update_cache: true` — **escreve** no cache |

Comentário no código sobre o batch: "O caminho anterior (N chamadas paralelas à EF `evaluate-portfolio`) podia dar 500 em carteiras grandes (limite de recurso agregando títulos em JS), fazendo a página cair silenciosamente para 0."

**Fallback em cascata:** qualquer falha (erro do RPC, exceção, carteira ausente na resposta) devolve `cachedFallback(portfolio)` — os valores em cache, **nunca zeros**. Mesma invariante "erro ≠ vazio" dos filtros (§2.13).

**Mas há uma diferença crítica:** nas carteiras, **o erro é invisível**. Não existe `hasError`, nem ícone de alerta, nem tooltip. A UI mostra o cache como se fosse fresco. A tela de Filtros marca a falha (`AlertCircle` + motivo); a de Carteiras apenas registra `logError` no console.

`⚠️ A confirmar:` isso é regressão do padrão do domínio. A invariante "erro ≠ vazio" está cumprida; a invariante "erro diz o porquê" não.

**Isolamento multi-tenant na query key (PORT-18):** `["portfolios-stats", currentOrg?.slug, portfolios.map(p => p.id)]` — o slug da org entra na chave **para não vazar stats entre orgs**. Invariante a preservar em qualquer refatoração de cache.

#### 9.4.8 Invalidação após criar/editar — o `setTimeout`

```ts
const handleDialogClose = useCallback(() => {
  setDialogOpen(false);
  setEditingPortfolio(null);
  setTimeout(() => {
    queryClient.invalidateQueries({ queryKey: ["portfolios-stats"] });
  }, 500);
}, [queryClient]);
```

Um atraso fixo de **500ms** antes de invalidar as estatísticas. `⚠️ A confirmar:` provavelmente espera o commit no banco antes de recalcular — mas é tempo arbitrário, não sincronização. Se o banco demorar 600ms, as stats recalculam sobre o estado antigo. Dívida técnica clara.

### 9.5 Vínculo filtro ⇄ carteira — a ponte entre as duas telas

| Direção | Existe? | Como |
|---|---|---|
| Carteira → filtro | **Sim** | `PortfolioDialog` → aba "Por Filtro" → `<Select>` de filtros salvos |
| Filtro → carteiras que o usam | **Não** | Não há nenhuma indicação, em `/filters`, de que um filtro está vinculado a uma carteira |

**Esta é a lacuna estrutural mais séria do domínio.** Consequências concretas:

1. Ao **excluir** um filtro em `/filters`, nada avisa que 3 carteiras dependem dele. O `AlertDialog` diz apenas "Esta ação não pode ser desfeita."
2. Ao **desativar** um filtro, o toast diz "Réguas e carteiras que já usam este filtro continuam funcionando normalmente" — mas **não diz quais**, nem quantas.
3. Não há tela de "onde este filtro é usado" em lugar nenhum.

**Oportunidade central do redesign:** um indicador de uso ("usado por 3 carteiras, 2 réguas") na lista de filtros e no `AlertDialog` de exclusão. Os dados existem (`portfolios.filter_definition_id`); falta a consulta e a superfície.

#### 9.5.1 O seletor de filtros dentro da carteira

```ts
const { data: filtersData } = useFilters({ pageSize: 100 });
```

| Aspecto | Comportamento |
|---|---|
| Contexto | **Default** — ou seja, `context: "common"`, `usage_scope = 'common'` e `is_active = true` |
| Consequência 1 | Filtros de **Agente de IA** não aparecem (correto — §2.7) |
| Consequência 2 | Filtros **desativados** não aparecem (correto — §2.8) |
| Consequência 3 | **Teto de 100 filtros.** Com 101+, os excedentes ficam invisíveis, sem aviso e sem busca |
| Controle | `<Select>` simples — **sem campo de busca**, sem agrupamento, sem descrição, sem contagem de contatos |
| Item | Ícone `Filter h-4 w-4` + `filter.name` |

**Contraste gritante:** o construtor de filtros tem `FieldCombobox` com busca para escolher **um campo**; a carteira usa um `<Select>` sem busca para escolher **um filtro** entre até 100. O controle mais crítico tem a ferramenta mais pobre.

#### 9.5.2 Confirmação visual do vínculo

Ao selecionar um filtro, aparece um bloco `p-3 bg-muted/50 rounded-lg`:

> ✓ Filtro selecionado: **{nome do filtro}**

Ícone `Check h-4 w-4 text-green-600`. **Cor hardcoded (`text-green-600`)** em vez de token do design system — contraria a regra do projeto de não usar cores fixas.

**O bloco é redundante:** o `<Select>` acima já mostra o nome do filtro escolhido. O bloco repete a mesma informação logo abaixo.

**O que o bloco NÃO mostra:** quantos contatos/contratos o filtro pega, quais são as condições, quando foi atualizado. A confirmação é puramente nominal.

### 9.6 Integrações da carteira (`PortfolioIntegrationsPanel`)

#### 9.6.1 O que resolve

Define **qual integração** (instância de WhatsApp, e-mail etc.) será usada por canal, **para aquela carteira**. Sem configuração, vale o padrão da campanha.

Texto literal do painel:

> "Configure quais integracoes serao usadas para cada canal nesta carteira"

E, em cada canal sem configuração:

> "Nenhuma integracao configurada para este canal. Sera usado o padrao da campanha."

#### 9.6.2 Os 5 canais (`CHANNELS`)

| `value` | `label` | `description` |
|---|---|---|
| `whatsapp` | WhatsApp | Mensagens via WhatsApp |
| `email` | E-mail | Envio de emails |
| `sms` | SMS | Mensagens de texto |
| `voice` | **Voz** | Ligacoes telefonicas |
| `webhook` | Webhook | Integracoes customizadas |

**Divergência com o catálogo de filtros (§6.9.4):** lá o canal `voice` tem rótulo **"Ligacao"**; aqui é **"Voz"**. E `ACTION_CHANNEL_OPTIONS` inclui `notification` e `negativation`, que **não** existem aqui. Três catálogos de canal no produto, com conjuntos e rótulos diferentes.

#### 9.6.3 Layout

| Região | Especificação |
|---|---|
| Cabeçalho | `<h3 class="text-lg font-semibold">Integracoes da Carteira</h3>` + subtítulo `text-sm text-muted-foreground` + botão **"Adicionar Integracao"** (`Plus h-4 w-4 mr-2`) |
| Corpo | `<ScrollArea className="h-[400px]">` com uma seção por canal (`space-y-4`) |
| Seção de canal | `border rounded-lg p-4` com `<h4 class="font-medium">{label}</h4>` + `<p class="text-xs text-muted-foreground">{description}</p>` |
| Canal vazio | Botão `variant="outline" size="sm"` **"Configurar"** (`Plus h-3 w-3 mr-1`) à direita + texto em itálico `text-sm text-muted-foreground italic` |
| Canal com integrações | Lista `space-y-2` de linhas `p-2 bg-muted/50 rounded-md` |

#### 9.6.4 Linha de integração

| Elemento | Especificação |
|---|---|
| Selo principal | Ícone `Star h-4 w-4 fill-yellow-400 text-yellow-400` com `Tooltip` "Integracao principal" — só quando `is_primary` |
| Nome | `text-sm font-medium`; fallback literal **"Integracao desconhecida"** quando o join falha |
| Slug | `Badge variant="outline" text-[10px]` com `integration.slug` |
| Ação "tornar principal" | `Button ghost icon h-7 w-7` com `StarOff h-3.5 w-3.5`, `Tooltip` "Definir como principal". Só aparece quando **não** é principal |
| Ação "remover" | `Button ghost icon h-7 w-7 text-destructive`, `Trash2 h-3.5 w-3.5`, `Tooltip` "Remover integracao" |

**Problema de acessibilidade:** o `TooltipTrigger` da estrela não tem `asChild` nem elemento focável — é um `<span>` implícito com um ícone. Não é alcançável por teclado.

**Problema de destrutividade:** **remover uma integração NÃO pede confirmação.** Um clique no lixo desvincula na hora. É a única ação destrutiva do domínio sem confirmação de nenhum tipo — nem `confirm()` nativo, nem `AlertDialog`.

**Semântica invertida do ícone:** clicar em `StarOff` (estrela vazada) **torna principal**. O ícone mostra o estado atual, a ação faz o oposto — mesmo problema do botão `ArrowUpDown` da ordenação de filtros (§4.17).

#### 9.6.5 Regra de "principal" — exclusividade por canal

Nos hooks `useCreatePortfolioIntegration` e `useUpdatePortfolioIntegration`:

```ts
if (input.is_primary) {
  await orgClient.from("portfolio_integrations")
    .update({ is_primary: false })
    .eq("portfolio_id", ...).eq("channel", ...).eq("is_primary", true);
}
```

Antes de gravar, **desmarca a principal anterior daquele canal**. No update há ainda `.neq("id", id)` para não desmarcar a si mesma.

**Não é transacional** — são duas operações separadas. Se a segunda falhar, o canal fica **sem nenhuma principal**. `⚠️ A confirmar:` se há constraint no banco garantindo unicidade; pelo código do frontend, não há.

**Não há como remover o status de principal** sem promover outra ou apagar a linha.

#### 9.6.6 Toasts do painel

| Ação | Variante | Título | Descrição |
|---|---|---|---|
| Vincular | sucesso | **Integracao vinculada** | "A integracao foi vinculada a carteira com sucesso." |
| Vincular (erro) | destrutivo | **Erro ao vincular integracao** | "Nao foi possivel vincular a integracao. Tente novamente." — **genérico, esconde o erro real** |
| Atualizar | sucesso | **Integracao atualizada** | "A configuracao da integracao foi atualizada com sucesso." |
| Atualizar (erro) | destrutivo | **Erro ao atualizar integracao** | "Nao foi possivel atualizar a integracao. Tente novamente." — genérico |
| Remover | sucesso | **Integracao removida** | "A integracao foi desvinculada da carteira." |
| Remover (erro) | destrutivo | **Erro ao remover integracao** | `getDeleteErrorMessage(error)` — **mensagem real** |

**Inconsistência:** dois dos três erros escondem o motivo real; só o de remoção o mostra. O resto do domínio (filtros) usa `getErrorMessage(error)` sempre (§5.5.6, comentário PORT-11: "toast destrutivo com a mensagem real em vez de `alert()`").

**Acentuação:** todos os textos deste painel estão **sem acento** ("Integracoes", "sao", "padrao"), inclusive nos toasts. O resto da aba de Carteiras usa acentuação normal ("Estatísticas", "Dívida Total", "Descrição").

---

## 10. Modais do domínio — um bloco por modal

Esta seção documenta cada modal integralmente. Modais já detalhados em profundidade nas seções anteriores (o `FilterBuilderDialog` em §5, o `FilterPreviewDialog` em §8) recebem aqui apenas a ficha de referência.

### 10.1 `FilterPortfolioModal` — "Contatos do Filtro"

`src/components/filters/FilterPortfolioModal.tsx`.

#### 10.1.1 Ficha

| Item | Valor |
|---|---|
| **Objetivo** | Mostrar a **lista completa e paginada** dos contatos que casam com um filtro, com colunas configuráveis e exportação CSV |
| **Gatilho 1** | Menu `⋯` → **Ver Contatos** (ícone `Users`) — lista e grade |
| **Gatilho 2** | **Clique nas colunas numéricas** da tabela (Contatos, Contratos, Titulos, Vl Total, Vl Pago, Em Aberto, Vencido) |
| **Gatilho 3** | **Clique no bloco de estatísticas** do card na visualização em grade |
| **Permissão** | Nenhuma — disponível para quem chega à tela |
| **Estado de abertura** | `portfolioFilter` na `FiltersPage`; `open={!!filter}` |
| **Fechamento** | `X` do Dialog, ESC, ou clique fora |

#### 10.1.2 Layout

| Região | Especificação |
|---|---|
| `DialogContent` | `w-[96vw] sm:max-w-[1200px] max-h-[88vh] flex flex-col p-6` — **teto de 1200px**, diferente dos outros dois modais (95vw livre) |
| Título | `text-lg font-semibold` → **"Contatos do Filtro: {nome}"** |
| Controles do cabeçalho | `PreviewColumnPicker` (§8.6) + botão **"Exportar CSV (N)"** |
| `DialogDescription` | Dinâmica: `"Carregando..."` / `"Erro ao carregar contatos"` / `"{total} contatos encontrados"` — **visível** (ao contrário da prévia, que a esconde com `sr-only`) |
| Corpo | `flex-1 overflow-auto min-h-0` com `<Table className="min-w-max">` (componente shadcn) |
| Rodapé | Paginação, condicional a `totalPages > 1` e `!showError` |
| Overlay filho | `<PortfolioDetailSheet>` — abre ao clicar numa linha |

#### 10.1.3 Tabela

| Aspecto | Especificação |
|---|---|
| Page size | **50** (fixo) |
| Cabeçalho | `sticky top-0 z-20 bg-background min-w-[130px] whitespace-nowrap`; a coluna `name` tem `min-w-[220px]`; `title={column.description}` |
| Célula | `max-w-[260px]` + alinhamento; `text-right` recebe `tabular-nums` |
| Coluna `name` | Renderização especial: avatar `w-7 h-7 rounded-full bg-muted` com ícone `User h-3.5 w-3.5` + nome `font-medium truncate max-w-[190px]` com `title` |
| Demais colunas | `renderColumnValue(column, contact)` |
| Linha | `cursor-pointer hover:bg-muted/50 transition-colors` → abre o `PortfolioDetailSheet` |

**A linha É clicável aqui** (abre o detalhe do contato), ao contrário da prévia. Assimetria entre os dois modais que usam o mesmo picker de colunas.

#### 10.1.4 Enriquecimento — 7 consultas paralelas

`enrichFilterContactRows` (`src/lib/filters/contact-enrichment.ts`) funde o resultado de 7 hooks nas linhas:

| Hook | Enriquece | Condicional? |
|---|---|---|
| `useContactPortfolios(ids)` | `portfolios[]` | Não |
| `useContactWorkflows(ids)` | `workflows[]` | Não |
| `useContactCustomFields(ids)` | `trading_name`, `contact_custom_fields` | Não |
| `useContactContractCustomFields(ids)` | `contract_custom_fields_agg` | **Sim** — só se houver coluna de contrato selecionada |
| `useContactSupplyCustomFields(ids)` | `supply_custom_fields_agg` | **Sim** — só se houver coluna de suprimento selecionada |
| `useContactActions(ids)` | `action_stats` | Não |
| `useContactSeals(ids)` + `useSealCatalog("contact")` | `contact_seal_ids`, `seal_names` (resolvidos por nome) | Não |

Comentário no código: "Mesmos enriquecimentos da Gestão de Carteira. O catálogo e os valores das colunas de associação, ações, selos e campos personalizados passam a ter a mesma fonte nas duas telas; somente as seis colunas '(no filtro)' mantêm a semântica própria do recorte salvo."

**Custo:** abrir a carteira de um filtro dispara **1 consulta de lista + até 7 de enriquecimento** = 8 round-trips para 50 linhas. Trocar de página refaz todas.

**Resolução de selo:** `seal_names` mapeia UUID → nome via `sealCatalog`; **se o selo não estiver no catálogo, o UUID cru é exibido** (`?? sealId`). Fallback silencioso.

#### 10.1.5 Botões e confirmações

| Botão | Especificação | Confirma? |
|---|---|---|
| `PreviewColumnPicker` | `Colunas (N)` — bloqueia desmarcar a última (§8.6.4) | — |
| Exportar CSV | `variant="outline" size="sm"`, ícone `Download` → `Loader2 animate-spin` durante; rótulo **`Exportar CSV ({N})`** com N = colunas; `disabled` quando não há contatos ou já está exportando | **Não** — dispara direto |
| Tentar novamente | Só no estado de erro; `RefreshCw` que gira quando `isFetching` | — |
| Anterior / Próxima | `variant="outline" size="sm"` com `ChevronLeft`/`ChevronRight`; `disabled` no extremo **ou quando `isFetching`** | — |

**A exportação não avisa nada antes de começar.** Com um filtro de 9.800 contatos, são 20 chamadas sequenciais de 500 linhas + 1 enriquecimento — segundos ou dezenas de segundos de espera, com o único feedback sendo o spinner no botão. Não há barra de progresso, contagem de páginas, nem estimativa.

**Nenhum aviso prévio de que o filtro excede 10.000** — o erro só aparece **depois** da primeira página, como toast destrutivo.

#### 10.1.6 Estados

| Estado | Condição | Renderização |
|---|---|---|
| Carregando | `isLoading && !data` | `Loader2 h-8 w-8 animate-spin text-muted-foreground`, `py-12` centralizado |
| Erro | `!!error && !isFetching` | `AlertCircle h-8 w-8` + **"Erro ao carregar contatos"** (`font-medium`) + `(error as Error)?.message ?? "Erro desconhecido"` em `text-xs text-muted-foreground max-w-md text-center` + botão **"Tentar novamente"** |
| Vazio | Nenhum dos anteriores e `contacts.length === 0` | `User h-12 w-12` + **"Nenhum contato encontrado"** (`text-lg`) + **"Ajuste as condições do filtro para encontrar contatos"** (`text-sm mt-1`) |
| Normal | — | A tabela |

**Este modal é o modelo correto de tratamento de erro do domínio:** ícone + título + motivo real + ação de recuperação. O `FilterPreviewDialog` deveria copiá-lo (§8.8).

**Reset de página:** `useEffect` sobre `filter?.id` volta para a página 1 — necessário porque o Dialog reaproveita a instância do componente entre filtros diferentes.

#### 10.1.7 Diferenças de formatação em relação à tela de Filtros

| | `FiltersPage` | `FilterPortfolioModal` |
|---|---|---|
| Moeda | `minimumFractionDigits: 0` + compactação (`R$ 1.2M`) | `minimumFractionDigits: 2, maximumFractionDigits: 2` |
| `boolean` | — | `case "boolean"` explícito no `switch` |
| Array | — | `formatPreviewArray` |

**Três implementações de `formatCurrency` no domínio:** `FiltersPage` (0 casas + compacta), `FilterPreviewDialog` (2 casas), `FilterPortfolioModal` (2 casas, função própria). Consolidar no redesign.

### 10.2 `FilterPreviewDialog` — "Visualizar Filtro"

Detalhado em §8. Ficha de referência:

| Item | Valor |
|---|---|
| **Objetivo** | Conferir o que o filtro faz (condições legíveis) e quanto ele pega (7 métricas + amostra de 10) |
| **Gatilho** | Menu `⋯` → **Visualizar** (ícone `Eye`) |
| **Permissão** | Nenhuma |
| **Layout** | `w-[95vw] h-[95vh]`, dois cards empilhados |
| **Campos editáveis** | **Nenhum** — o modal é somente leitura, exceto pela seleção de colunas |
| **Botões** | `PreviewColumnPicker`; botão de recarregar (só ícone `RefreshCw`, sem rótulo); dentro do erro de colunas, "Tentar novamente" |
| **Rodapé** | **Não existe** — sem "Fechar", sem "Editar filtro", sem "Ver todos os contatos" |
| **Confirmações** | Nenhuma (não há ação destrutiva) |
| **Estados** | 5 no card de prévia + 3 aninhados na tabela (§8.8) |

**Lacuna de fluxo:** da prévia não se vai para lugar nenhum. Para editar o filtro que se acabou de conferir, é preciso fechar e clicar de novo na lista. Não há "Editar" nem "Ver todos os contatos" — mesmo sendo os dois passos naturais depois de conferir.

### 10.3 `FilterBuilderDialog` — "Novo Filtro" / "Editar Filtro"

Detalhado em §5. Ficha de referência:

| Item | Valor |
|---|---|
| **Objetivo** | Criar ou editar um filtro: identidade (nome, descrição, cor, ícone), escopo de uso e a árvore de condições |
| **Gatilho 1** | Botão **"Novo Filtro"** do cabeçalho (`filters:write`) |
| **Gatilho 2** | Link **"Criar primeiro filtro"** do estado vazio (`filters:write`) |
| **Gatilho 3** | Menu `⋯` → **Editar**, **ou clique na linha/card** (`filters:write` só para o menu — o clique na linha **não** é gateado) |
| **Gatilho 4** | Menu `⋯` → **Duplicar** — abre o mesmo dialog em modo criação (§4.11) |
| **Layout** | `w-[95vw] h-[95vh] overflow-hidden flex flex-col` |
| **Campos** | Nome (obrigatório), Descrição, Cor, Ícone, Escopo de uso (só na criação com `allowAgentScope`), árvore de condições |
| **Botões do rodapé** | **Cancelar** (`variant="outline"`) e **"Criar Filtro"** / **"Salvar Alterações"** (`type="submit" form="filter-form"`, com `Loader2` quando `isSubmitting`) |
| **Confirmação de descarte** | **NÃO EXISTE** — fechar com alterações perde tudo em silêncio |
| **Validações bloqueantes** | Nome vazio (inline); filtro misto (toast); limites da árvore (toast, no save) |
| **Toast de sucesso** | **Nenhum** — o dialog só fecha |

**A ausência de confirmação de descarte é a lacuna mais cara do construtor.** Um filtro de 30 condições montado em 10 minutos desaparece com um clique fora do dialog ou um ESC acidental.

`⚠️ A confirmar:` `DialogContent` do shadcn fecha ao clicar no overlay por padrão. Não há `onInteractOutside` interceptado em `filter-builder/index.tsx` — ou seja, **clique fora fecha e descarta**.

### 10.4 `PortfolioDialog` — "Nova Carteira" / "Editar Carteira"

`src/components/portfolios/PortfolioDialog.tsx`.

#### 10.4.1 Ficha

| Item | Valor |
|---|---|
| **Objetivo** | Criar/editar uma carteira: identidade, tipo de definição (campo ou filtro) e — só na edição — integrações por canal |
| **Gatilho 1** | Botão **"Nova Carteira"** do cabeçalho do `ETLPage` (via `ref.openCreateModal()`) |
| **Gatilho 2** | Botão **"Nova Carteira"** do estado vazio da aba |
| **Gatilho 3** | Menu `⋯` → **Editar** |
| **Permissão** | Nenhuma além de `etl:read` na rota |
| **Estado** | `dialogOpen` + `editingPortfolio` no `PortfoliosTab` |
| **`isEditing`** | `!!portfolio?.id` |

#### 10.4.2 Layout

| Região | Especificação |
|---|---|
| `DialogContent` | `flex flex-col p-0 w-[95vw] h-[95vh]` — **sem padding no container**, cada região aplica o seu |
| `DialogHeader` | `px-6 py-4 border-b bg-gradient-to-r from-primary/5 to-transparent` — **único cabeçalho com gradiente** do domínio |
| Título | "Editar Carteira" ou "Nova Carteira" — **sem ícone** (o construtor de filtros tem um quadrado com ícone) |
| Descrição | "Altere as configurações da carteira de cobrança" / "Configure uma nova carteira para segmentar seus contratos" |
| Corpo | `flex-1 overflow-y-auto px-6 py-4 space-y-4` |
| `DialogFooter` | `px-6 py-4 border-t bg-muted/30` |

**`h-95vh` para um formulário de 5 campos.** Com o modo "Por Campo" e sem integrações, o conteúdo ocupa talvez 40% da altura — o resto é espaço vazio. O construtor de filtros precisa de 95vh (árvore arbitrária); a carteira não.

#### 10.4.3 Campos

| # | Campo | Componente | Obrigatório | Padrão | Placeholder / opções |
|---|---|---|---|---|---|
| 1 | Nome da Carteira | `Input` (`id="name"`) | **Sim** (via `isValid`) | `""` | `Ex: FIDC, Ideal, Suprimentos...` |
| 2 | Cor | `Select` | Não | **`#3B82F6` (Azul)** | 10 cores de `PORTFOLIO_COLORS` |
| 3 | Descrição (opcional) | **`Textarea rows={2}`** | Não | `""` | `Descreva o propósito desta carteira...` |
| 4 | Ícone | `Select` | Não | **`Briefcase`** | 10 ícones de `PORTFOLIO_ICONS` |
| 5 | Definição da Carteira | `Tabs` de 2 abas | **Sim** | `field` | "Por Campo" (`Tag`) / "Por Filtro" (`Filter`) |

Layout: dois `grid grid-cols-4 gap-4` — linha 1 (nome ocupa 3 colunas, cor 1), linha 2 (descrição 3, ícone 1). **Mesma grade do `FilterHeader`** (§5.1.1).

**Três diferenças relevantes em relação ao construtor de filtros:**

| | `FilterHeader` | `PortfolioDialog` |
|---|---|---|
| Descrição | `Input` de 1 linha | **`Textarea rows={2}`** |
| Cor padrão | `null` ("Nenhuma") | **`#3B82F6`** (sempre tem cor) |
| Ícone padrão | `null` ("Nenhum") | **`Briefcase`** (sempre tem ícone) |
| Prévia no `SelectValue` | Bolinha **+ nome** da cor / ícone **+ nome** | **Só a bolinha** / **só o ícone** — sem o nome |
| Formulário | `react-hook-form` + Zod | **`useState` cru**, validação manual (`isValid`) |

O `SelectValue` mostrando só a bolinha, sem o nome da cor, é regressão de acessibilidade: quem não distingue cores não sabe qual está selecionada.

#### 10.4.4 Catálogos de cor e ícone

`PORTFOLIO_COLORS` é **idêntico** a `FILTER_COLORS` (§4.16) — os mesmos 10 hex e rótulos. **Duas constantes duplicadas** em `src/types/portfolios.ts` e `src/types/filters.ts`.

`PORTFOLIO_ICONS` (10, distintos dos ícones de filtro):

| `value` (Lucide) | `label` |
|---|---|
| `Briefcase` | Maleta |
| `Wallet` | **Carteira** |
| `Building2` | Empresa |
| `Users` | Usuários |
| `CreditCard` | Cartão |
| `Landmark` | Banco |
| `FileText` | Documento |
| `TrendingUp` | Crescimento |
| `Target` | Alvo |
| `Star` | Estrela |

Sobreposição com `FILTER_ICONS`: apenas `Target`, `Star` e `TrendingUp` (com os mesmos rótulos "Alvo", "Estrela", "Tendência"/"Crescimento" — **`TrendingUp` tem rótulos diferentes nos dois catálogos**).

O `DynamicIcon` local faz fallback para `Briefcase` quando o nome não existe (a `FiltersPage` cai em `Filter`; o do construtor devolve `null`). **Três implementações de `DynamicIcon` com três fallbacks diferentes.**

#### 10.4.5 Aba "Por Campo"

| Elemento | Especificação |
|---|---|
| Rótulo | **"Campo para Segmentação"** |
| Controle | `Select` com os 5 campos de `PORTFOLIO_FIELD_OPTIONS`, `placeholder="Selecione um campo..."` |
| Efeito da troca | **Limpa `fieldValues`** (`setFieldValues([])`) — comportamento correto |
| Bloco de valores | Só aparece quando há `fieldName` |
| Rótulo do bloco | **"Valores para incluir nesta carteira"** |
| Carregando | `Loader2 h-4 w-4 animate-spin` + "Carregando valores..." |
| Lista | `<ScrollArea className="h-[150px] border rounded-md p-3">` com um `Checkbox` + `<label>` por valor |
| Vazio | **"Nenhum valor encontrado para este campo. Importe dados primeiro."** |
| Resumo | `Badge variant="secondary"` por valor selecionado, cada um com botão `X h-3 w-3` para remover |

**Sem busca na lista de valores.** Com 100 valores distintos, é rolagem pura numa área de 150px. O picker de colunas (§8.6) tem busca; este, não.

**Sem "selecionar todos" / "limpar tudo".**

**A lista de badges duplica a informação dos checkboxes** — os dois estão visíveis ao mesmo tempo, na mesma tela.

#### 10.4.6 Aba "Por Filtro"

| Elemento | Especificação |
|---|---|
| Rótulo | **"Filtro Existente"** |
| Controle | `Select`, `placeholder="Selecione um filtro..."`, itens com ícone `Filter` + nome |
| Nota | `text-xs text-muted-foreground` — "A carteira usará as condições deste filtro para determinar quais contratos pertencem a ela." |
| Confirmação | Bloco `p-3 bg-muted/50 rounded-lg` com `Check text-green-600` + "Filtro selecionado: **{nome}**" |

Ver §9.5.1 e §9.5.2 para as limitações (teto de 100, sem busca, confirmação puramente nominal).

**Não há link para criar um filtro novo daqui.** Se o filtro necessário não existe, o usuário precisa: fechar → sair do ETL → ir para `/filters` → criar → voltar ao ETL → aba Carteiras → recomeçar. O `FilterBuilderDialog` já aceita a prop `onFilterCreated` exatamente para esse caso (§5.0.1), mas ela não é usada aqui.

#### 10.4.7 Integrações — só na edição

```tsx
{isEditing && portfolio && (
  <div className="space-y-2 pt-4 border-t">
    <PortfolioIntegrationsPanel portfolioId={portfolio.id} portfolioName={portfolio.name} />
  </div>
)}
```

Na **criação**, o painel não aparece — a carteira precisa existir para receber vínculos. **Nada avisa isso ao usuário**: não há texto do tipo "configure integrações depois de salvar". O bloco simplesmente não existe, e reaparece na edição sem explicação.

#### 10.4.8 Validação e submissão

```ts
const isValid =
  name.trim() &&
  ((definitionType === "field" && fieldName && fieldValues.length > 0) ||
   (definitionType === "filter" && filterDefinitionId));
```

| Regra | Efeito |
|---|---|
| Nome vazio | Botão desabilitado |
| Modo `field` sem campo ou sem nenhum valor | Botão desabilitado |
| Modo `filter` sem filtro | Botão desabilitado |

**A validação é toda por `disabled`, sem nenhuma mensagem.** O usuário vê o botão "Criar Carteira" cinza e **não sabe por quê** — não há erro inline, asterisco de obrigatório, nem tooltip. Compare com o construtor de filtros, que escreve "Nome e obrigatorio" abaixo do campo.

**Correção de alto valor no redesign:** botão desabilitado sem explicação é o anti-padrão que o próprio projeto já combate em outro lugar (§2.5: "quando um controle desaparece, a interface diz por quê").

#### 10.4.9 Botões do rodapé

| Botão | Especificação |
|---|---|
| Cancelar | `variant="outline"`, `disabled={isSubmitting}`, chama `onClose()` |
| Salvar | `disabled={!isValid \|\| isSubmitting}`; `Loader2 animate-spin` quando submetendo; rótulo **"Salvar"** (edição) ou **"Criar Carteira"** (criação) |

**Assimetria de rótulo:** "Criar Carteira" (com substantivo) × "Salvar" (sem). O construtor de filtros usa "Criar Filtro" × "Salvar Alterações".

#### 10.4.10 Erro na submissão — `alert()` nativo

```ts
catch (error) {
  logError(error, { source: "PortfolioDialog", action: "save portfolio" });
  alert("Erro ao salvar carteira");
}
```

**Este é o segundo ponto do domínio com diálogo nativo** (o primeiro é o `confirm()` da exclusão, §9.4.6). E é pior: **descarta a mensagem real do erro**, mostrando um texto genérico de 4 palavras.

O comentário do PORT-11 na tela de Filtros diz literalmente: "toast destrutivo com a mensagem real em vez de `alert()`". A aba de Carteiras não recebeu essa correção.

**Correção obrigatória no redesign.**

#### 10.4.11 Confirmação de descarte

**Não existe** — igual ao construtor de filtros. Fechar descarta tudo.

#### 10.4.12 Reset do formulário

```ts
useEffect(() => {
  if (open) {
    if (portfolio) { /* carrega os 8 campos */ }
    else { /* volta aos defaults */ }
  }
}, [open, portfolio]);
```

Dispara na **abertura**, num `useEffect` comum (o construtor de filtros usa `queueMicrotask` + `prevOpenRef` para não atualizar estado durante o render — §5.0.2). Dois padrões de reset no mesmo domínio.

### 10.5 `AddIntegrationDialog` — modal aninhado

Definido dentro de `PortfolioIntegrationsPanel.tsx`. **É um Dialog dentro de um Dialog** (`AddIntegrationDialog` dentro de `PortfolioDialog`).

#### 10.5.1 Ficha

| Item | Valor |
|---|---|
| **Objetivo** | Vincular uma integração existente a um canal da carteira |
| **Gatilho 1** | Botão **"Adicionar Integracao"** do cabeçalho do painel — abre **sem canal pré-selecionado** |
| **Gatilho 2** | Botão **"Configurar"** de um canal vazio — abre **com aquele canal pré-selecionado** |
| **Tamanho** | `DialogContent` **sem classe** — tamanho padrão do shadcn (bem menor que os 95vh dos outros) |
| **Título** | "Adicionar Integracao" |
| **Descrição** | "Vincule uma integracao a carteira **{nome}**" |

#### 10.5.2 Campos — revelação progressiva

| # | Campo | Aparece quando | Componente |
|---|---|---|---|
| 1 | Canal | Sempre | `Select` com os 5 canais, `placeholder="Selecione um canal..."` |
| 2 | Integracao | `channel` preenchido | `Select` com as integrações do canal, `placeholder="Selecione uma integracao..."`; item = ícone `Settings2` + nome + `(slug)` em `text-xs` |
| 3 | Definir como principal | `integrationId` preenchido | **`<input type="checkbox">` HTML cru** com `className="h-4 w-4 rounded border-gray-300"` |

**Três problemas no campo 3:**

1. É um `<input type="checkbox">` **nativo**, não o componente `Checkbox` do design system — o único do domínio.
2. Usa **`border-gray-300` hardcoded**, violando a regra do projeto de não usar cores fixas (não responde a tema escuro).
3. Vem **marcado por padrão** (`useState(true)`) — ou seja, adicionar uma integração **rebaixa a principal anterior** silenciosamente, a menos que o usuário desmarque.

#### 10.5.3 Estados do campo Integracao

| Condição | Renderização |
|---|---|
| `isLoadingIntegrations` | `Loader2 h-4 w-4 animate-spin` + "Carregando integracoes..." |
| `filteredIntegrations.length > 0` | O `Select` |
| Lista vazia | **"Nenhuma integracao disponivel para este canal. Configure integracoes em Configuracoes > Integracoes."** (`text-sm text-muted-foreground py-2`) |

O estado vazio **diz onde resolver** — bom padrão. Mas é **texto**, não link: o usuário precisa navegar manualmente.

**Filtro aplicado:** `availableIntegrations.filter(i => !existingIntegrationIds.includes(i.id))` — integração já vinculada (**em qualquer canal**, não só neste) não aparece.

`⚠️ A confirmar:` a mesma integração não pode ser vinculada a dois canais da mesma carteira. Se isso é intencional (uma integração pertence a um canal por natureza, via `integrations.category`) ou se é restrição acidental.

#### 10.5.4 Botões

| Botão | Especificação |
|---|---|
| Cancelar | `variant="outline"`, chama `onClose()` |
| Adicionar | `disabled={!channel \|\| !integrationId \|\| isPending}`; `Loader2` quando submetendo; rótulo fixo **"Adicionar"** |

**Sem confirmação.** A vinculação é imediata; o rebaixamento da integração principal anterior acontece junto, sem aviso.

#### 10.5.5 Reset

```ts
const handleOpenChange = (isOpen: boolean) => {
  if (isOpen) { setChannel(defaultChannel || ""); setIntegrationId(""); setIsPrimary(true); }
  else { onClose(); }
};
```

`⚠️ A confirmar:` o reset roda no `onOpenChange` do Dialog, que **não dispara** quando o `open` muda por prop externa. Como o `PortfolioIntegrationsPanel` controla `addDialogOpen` diretamente, o ramo `isOpen === true` pode nunca executar — o estado do formulário sobreviveria entre aberturas. Verificar em teste manual.

### 10.6 `AlertDialog` de exclusão em massa (FiltersPage)

`src/pages/FiltersPage.tsx`, linhas ~1373-1402.

| Item | Valor |
|---|---|
| **Objetivo** | Confirmar a exclusão de N filtros selecionados |
| **Gatilho** | Botão **"Excluir selecionados"** da barra de seleção (`filters:delete`) |
| **Estado** | `showDeleteConfirm` (boolean) |
| **Título** | **"Confirmar exclusão"** |
| **Descrição** | `Você está prestes a excluir {N} filtro{s}. Esta ação não pode ser desfeita.` |
| **Botão cancelar** | `AlertDialogCancel` → "Cancelar" |
| **Botão confirmar** | `AlertDialogAction` com `className="bg-destructive text-destructive-foreground hover:bg-destructive/90"`; conteúdo: `Loader2 animate-spin` + "Excluindo..." **ou** `Trash2` + `Excluir {N} filtro{s}` |
| **Fechamento** | `finally { setShowDeleteConfirm(false) }` — fecha mesmo em erro |
| **Toast de sucesso** | "Filtros excluídos" / "{N} filtro(s) excluído(s) com sucesso." |
| **Erro** | Toast destrutivo do hook, com `getDeleteErrorMessage(error)` |

**O que o dialog NÃO diz:**

1. **Quais** filtros serão excluídos — só a quantidade. Como a seleção sobrevive à troca de página (§4.12), o usuário pode estar excluindo filtros que não vê há 3 páginas.
2. **Se algum está em uso** por carteira, régua ou blocklist.
3. Não oferece desativar em vez de excluir — sendo que a desativação existe e é reversível.

**As três lacunas são o mesmo problema:** a confirmação mais destrutiva da tela é a que informa menos.

**Pluralização manual** (`filtro{N > 1 ? "s" : ""}`) aparece **quatro vezes** neste bloco.

### 10.7 `AlertDialog` de exclusão individual (FiltersPage)

`src/pages/FiltersPage.tsx`, linhas ~1405-1437. Introduzido no PORT-10 para substituir o `confirm()` nativo.

| Item | Valor |
|---|---|
| **Objetivo** | Confirmar a exclusão de um filtro |
| **Gatilho** | Menu `⋯` → **Excluir** (`filters:delete`) |
| **Estado** | `deleteTarget: FilterDefinition \| null`; `open={!!deleteTarget}` |
| **Título** | **"Confirmar exclusão"** (idêntico ao do bulk) |
| **Descrição** | `Tem certeza que deseja excluir o filtro "{nome}"? Esta ação não pode ser desfeita.` |
| **Botão cancelar** | "Cancelar" |
| **Botão confirmar** | Mesmas classes destrutivas; `Loader2` + "Excluindo..." **ou** `Trash2` + **"Excluir"** |
| **Fechamento** | `finally { setDeleteTarget(null) }` |
| **Erro** | `catch` vazio — o hook já exibe o toast com a mensagem real (comentário explícito) |
| **Toast de sucesso** | **Nenhum** — diferente do bulk, que tem |

**Inconsistência:** excluir 2 filtros gera toast de sucesso; excluir 1 não gera nada. O feedback do caso mais comum é o mais fraco.

**Mesma lacuna do bulk:** não diz se o filtro está em uso, e não oferece desativar como alternativa — embora o produto documente a desativação exatamente como "a saída reversível" (§2.8).

### 10.8 `confirm()` nativo de exclusão de carteira

`src/components/portfolios/PortfoliosTab.tsx`, linha ~147.

| Item | Valor |
|---|---|
| **Objetivo** | Confirmar a exclusão de uma carteira |
| **Gatilho** | Menu `⋯` → **Excluir** |
| **Implementação** | `window.confirm()` — **diálogo do sistema operacional** |
| **Texto** | `Tem certeza que deseja excluir a carteira "{nome}"?` |
| **Botões** | OK / Cancelar do navegador (não estilizáveis, não traduzíveis) |
| **Estado de carregamento** | **Nenhum** |
| **Erro** | `catch` vazio — o hook da factory exibe o toast |
| **Toast de sucesso** | Do hook da factory |

**Substituir por `AlertDialog` no redesign** — o padrão já existe no mesmo produto (§10.6, §10.7).

**Nota:** como usa `confirm()`, a execução do JS **bloqueia** até a resposta. Em alguns navegadores com bloqueio de diálogos ativo, `confirm()` retorna `false` silenciosamente e a exclusão **nunca acontece, sem mensagem nenhuma**.

### 10.9 Quadro comparativo dos modais

| | Builder | Preview | Portfolio (contatos) | PortfolioDialog | AddIntegration |
|---|---|---|---|---|---|
| Largura | `95vw` | `95vw` | `96vw` / máx. 1200px | `95vw` | padrão shadcn |
| Altura | `95vh` | `95vh` | máx. `88vh` | `95vh` | auto |
| Ícone no título | Sim (quadrado azul) | Sim (`Filter`) | Não | Não | Não |
| Descrição visível | Sim | **`sr-only`** | Sim (dinâmica) | Sim | Sim |
| Rodapé com ações | Sim | **Não** | Só paginação | Sim | Sim |
| Formulário | RHF + Zod | — | — | `useState` cru | `useState` cru |
| Erro | Toast com msg real | **Texto sem msg** | Bloco completo + retry | **`alert()` genérico** | Toast genérico |
| Confirmação de descarte | Não | n/a | n/a | Não | Não |
| Reset ao abrir | `queueMicrotask` + ref | `useEffect` sobre `filter` | `useEffect` sobre `filter?.id` | `useEffect` sobre `open` | `onOpenChange` |

**Leitura:** cinco modais, cinco convenções. Uniformizar largura, posição de ícone, presença de rodapé, tratamento de erro e política de descarte é trabalho de redesign de alto retorno e baixo risco funcional.

---

## 11. Estados das telas

Inventário completo de todos os estados não-felizes. Fontes: `src/pages/FiltersPage.tsx`, `src/components/ui/loading-states.tsx`, `src/components/portfolios/PortfoliosTab.tsx`, os três modais.

### 11.1 Tela de Filtros (`/filters`) — a ordem de precedência

O `FiltersPage` decide o que renderizar nesta ordem:

```
1. if (error)                        → tela inteira de erro (return antecipado)
2. isLoading                         → FiltersPageSkeleton
3. data?.filters.length === 0        → Card de estado vazio
4. viewMode === "list"               → tabela
5. senão                             → grade de cards
```

**Detalhe estrutural:** o erro faz `return` **antes** do cabeçalho — a tela perde título, botão "Novo Filtro" e a barra de controles inteira. O usuário não consegue nem limpar a busca que possivelmente causou o erro.

`⚠️ A confirmar:` isso é decisão ou efeito colateral do `return` antecipado. Um erro de rede apaga a tela inteira, incluindo controles que não dependem do dado.

### 11.2 Loading

| Contexto | Componente/visual | Observação |
|---|---|---|
| Primeira carga da lista | `<FiltersPageSkeleton viewMode={viewMode} count={6} />` | **Respeita o modo de visualização** — esqueleto de tabela ou de cards |
| Esqueleto Lista | Cabeçalho com 8 `Skeleton` de larguras diferentes + 6 linhas com checkbox, bolinha, nome (`h-4 w-32`) + descrição (`h-3 w-48`), 5 números e o botão de menu | Espelha a estrutura real |
| Esqueleto Grade | 6 `<Card>` com bolinha + título (`h-5 w-32`) no header | Menos fiel que o de lista |
| Refresh de estatísticas | `RefreshableSection` — `opacity-60 pointer-events-none` + `aria-busy` na seção inteira | **Não dima na primeira carga** (§3.5) |
| Botão de refresh | `RefreshButton` com `isFetching` | — |
| Contador de resultados | `"Carregando..."` no lugar de `"{N} filtros encontrados"` | — |
| Aba Carteiras | `<Loader2 className="h-8 w-8 animate-spin" />` centralizado, `py-12` | **Sem esqueleto** — spinner genérico |
| Stats de um card de carteira | `Loader2 h-4 w-4` + "Carregando..." dentro do bloco de stats | Só quando `isLoadingStats && !hasStats` |
| Modal de contatos | `Loader2 h-8 w-8`, `py-12` | — |
| Prévia | `Loader2 h-8 w-8`, `py-8` | **Sem texto** |
| Colunas da amostra | Linha na tabela: "Carregando as colunas da amostra..." | — |
| Valores de campo (carteira) | `Loader2 h-4 w-4` + "Carregando valores..." | — |
| Integrações | `Loader2 h-6 w-6`, `py-8` | — |
| Integrações disponíveis | `Loader2 h-4 w-4` + "Carregando integracoes..." | — |
| Submissão de formulário | `Loader2 h-4 w-4 animate-spin` **dentro do botão** | Padrão consistente |

**Inconsistência de padrão:** uma tela tem esqueleto (Filtros), a outra tem spinner (Carteiras). Dentro dos modais, spinners de 3 tamanhos diferentes (`h-4`, `h-6`, `h-8`). Quatro loaders têm texto; cinco não têm.

### 11.3 Vazio

| Contexto | Ícone | Título | Subtítulo | Ação |
|---|---|---|---|---|
| Filtros — sem resultado, `statusFilter ≠ inactive` | `Filter h-12 w-12` | "Nenhum filtro encontrado" (`text-lg`) | "Filtros permitem segmentar contatos e contratos para campanhas" | **"Criar primeiro filtro"** (`variant="link"`, só com `filters:write`) |
| Filtros — sem resultado, `statusFilter === "inactive"` | `Filter h-12 w-12` | **"Nenhum filtro desativado"** | "Filtros desativados deixam de aparecer nos seletores, mas continuam valendo onde já estão vinculados" | **Nenhuma** |
| Carteiras — nenhuma carteira, sem busca | `Briefcase h-12 w-12` | "Nenhuma carteira encontrada" (`text-lg font-medium`) | "Carteiras permitem segmentar contratos por cedente, modalidade ou regras customizadas" | **"Nova Carteira"** (botão primário) |
| Carteiras — nenhuma carteira, com busca | `Briefcase h-12 w-12` | "Nenhuma carteira encontrada" | **"Tente ajustar os filtros de busca"** | **Nenhuma** |
| Prévia — amostra vazia | `FileText h-12 w-12` | "Nenhum registro encontrado com este filtro" | — | Nenhuma |
| Contatos do filtro | `User h-12 w-12` | "Nenhum contato encontrado" (`text-lg`) | "Ajuste as condições do filtro para encontrar contatos" | Nenhuma |
| Valores de campo (carteira) | — | — | "Nenhum valor encontrado para este campo. Importe dados primeiro." | Nenhuma |
| Integrações de um canal | — | — | "Nenhuma integracao configurada para este canal. Sera usado o padrao da campanha." (itálico) | Botão "Configurar" |
| Integrações disponíveis | — | — | "Nenhuma integracao disponivel para este canal. Configure integracoes em Configuracoes > Integracoes." | Nenhuma (texto, não link) |
| Grupo do construtor vazio | — | "Nenhum grupo definido" (raiz) / "Nenhuma condicao definida" | — | Links "Adicionar condicao" / "Adicionar grupo" |
| Selos sem catálogo | — | — | "Nenhum selo cadastrado neste escopo" | Nenhuma |
| Campo sem opções | — | — | "Nenhuma opção encontrada." | No modo único: botão `Usar "{texto}"` |
| Combobox de campo vazio | — | — | "Nenhum campo encontrado." | Nenhuma |
| Sem campos mapeados | — | — | Placeholder **"Sem campos mapeados"** no gatilho do combobox | Nenhuma |
| Picker de colunas — busca | — | — | "Nenhuma coluna encontrada." | Nenhuma |

**Duas falhas de desenho do estado vazio:**

1. **O estado vazio de Filtros não distingue "biblioteca vazia" de "busca sem resultado".** Uma busca por "xpto" produz o mesmo texto de uma org recém-criada, com o mesmo botão "Criar primeiro filtro" — que ali é enganoso (já existem 40 filtros; o que faltou foi limpar a busca). A aba de Carteiras **faz** essa distinção (`search ? "Tente ajustar os filtros de busca" : ...`). Padrão certo na tela errada.
2. **Nenhum estado vazio oferece "limpar busca/filtros".** O caminho de recuperação existe (apagar o campo, clicar em "Todos"), mas não é oferecido.

**Acerto a preservar:** o texto do vazio de "Inativos" explica o conceito ("continuam valendo onde já estão vinculados") em vez de só dizer que não há nada — é a mesma disciplina do toast de desativação (§5.5.7).

### 11.4 Erro

| Contexto | Superfície | Mostra o motivo? | Oferece recuperação? |
|---|---|---|---|
| Lista de filtros | Tela inteira: `AlertCircle h-12 w-12 text-destructive` + "Erro ao carregar filtros" + `getErrorMessage(error)` + botão "Tentar novamente" | **Sim** | **Sim** |
| Estatística de um filtro | Ícone `AlertCircle h-3 w-3` na coluna "Atualizado" + Tooltip (`max-w-[300px]`) com "Não foi possível calcular os números deste filtro." + `stats.errorMessage` | **Sim** | Não (o refresh geral serve) |
| Salvar filtro | Toast destrutivo "Erro ao salvar filtro" + `getErrorMessage(error)` | **Sim** | Não (o dialog permanece aberto) |
| Filtro misto | Toast destrutivo com título e descrição específicos (§2.10) | **Sim**, e explica como resolver | Não |
| Ativar/desativar | Toast destrutivo "Erro ao alterar status do filtro" + mensagem real | **Sim** | Não |
| Excluir filtro | Toast destrutivo + `getDeleteErrorMessage(error)` | **Sim** | Não |
| **Prévia** | Texto `text-center py-8 text-destructive`: **"Erro ao carregar prévia"** | **NÃO** | **NÃO** |
| Colunas da amostra | Linha na tabela + botão "Tentar novamente" | Não (mensagem fixa) | **Sim** |
| Contatos do filtro | Bloco completo: `AlertCircle` + título + `(error as Error)?.message` + "Tentar novamente" | **Sim** | **Sim** |
| Exportação CSV | Toast destrutivo "Não foi possível exportar os contatos" + mensagem real ou "Falha ao consultar os dados. Tente novamente." | **Sim** | Não (repetir manualmente) |
| Stats de carteiras | **Nada** — cai para `cached_*` silenciosamente, só `logError` no console | **NÃO** | **NÃO** |
| Salvar carteira | **`alert("Erro ao salvar carteira")`** | **NÃO** | Não |
| Excluir carteira | Toast destrutivo do hook | Sim | Não |
| Vincular integração | Toast "Erro ao vincular integracao" + "Nao foi possivel vincular a integracao. Tente novamente." | **NÃO** (genérico) | Não |
| Atualizar integração | Toast "Erro ao atualizar integracao" + genérico | **NÃO** | Não |
| Remover integração | Toast + `getDeleteErrorMessage(error)` | **Sim** | Não |
| Campos customizados | **Nada** — só `console.error` | **NÃO** | **NÃO** |

**Cinco pontos cegos** (erro que o usuário não vê ou não entende):

1. Prévia — erro sem motivo e sem retry.
2. Stats de carteiras — falha totalmente invisível, cache exibido como se fosse fresco.
3. Salvar carteira — `alert()` genérico que descarta a causa.
4. Vincular/atualizar integração — mensagens genéricas.
5. Campos customizados no construtor — a lista fica incompleta e nada avisa.

**Padrão de referência do domínio** (a copiar nos cinco): ícone + título + **motivo real** + **ação de recuperação**. Está implementado corretamente em dois lugares: a tela de erro da lista de filtros e o erro do `FilterPortfolioModal`.

### 11.5 Sem permissão

**Não existe estado "sem permissão" visível em nenhuma das duas telas.** O modelo é de **ocultação**, não de bloqueio:

| Papel | `/filters` no menu? | O que vê ao digitar a URL |
|---|---|---|
| `owner` (`*`) | Sim | Tudo |
| `admin` | Sim | Tudo |
| `manager` | Sim | Tudo menos **Excluir** e **Excluir selecionados** |
| `operator` | Sim | Tudo menos **Excluir** |
| `viewer` | **Não** (sem `filters:read`) | **A lista completa, sem nenhum botão de escrita** — a rota não é guardada (§0.1) |

**Elementos ocultados por `filters:write`:** botão "Novo Filtro", link "Criar primeiro filtro", itens de menu Editar/Duplicar/Ativar-Desativar, Switch do card.

**Elementos ocultados por `filters:delete`:** item Excluir, botão "Excluir selecionados".

**Elementos NÃO gateados (acessíveis a qualquer um que chegue à tela):**

| Elemento | Risco |
|---|---|
| **Clique na linha da tabela** → abre o `FilterBuilderDialog` de edição | Um `viewer` que digite a URL consegue **abrir o construtor e clicar em "Salvar Alterações"**. O gate é só de UI; não há checagem no hook de mutação |
| Menu "Ver Contatos" | Expõe a lista completa de contatos + exportação CSV de até 10.000 registros |
| Menu "Visualizar" | Expõe contagens e amostra |
| Exportação CSV | **Sem permissão própria** |

`⚠️ A confirmar:` a exportação de até 10.000 contatos (com documento, telefone, e-mail, valores) não tem permissão dedicada. Vale checar com o time se deveria ter (`filters:export` ou reaproveitar `contacts:export`).

**Aba Carteiras:** nenhum gate interno. Quem tem `etl:read` cria, edita e exclui.

**Mensagem de "sem permissão":** não existe em lugar nenhum do domínio. Se um redesign introduzir bloqueio de rota, precisará criar essa superfície do zero.

### 11.6 Filtro inválido

Não há **um** estado "filtro inválido" — há uma dispersão de comportamentos:

| Situação | Momento da descoberta | Superfície |
|---|---|---|
| Nome vazio | Ao submeter | Erro inline abaixo do campo: "Nome e obrigatorio" |
| Filtro misto (suprimento + contrato) | Ao submeter | Toast destrutivo bloqueante, com instrução de como resolver |
| Profundidade > 20 | Ao submeter | Toast "Erro ao salvar filtro" + "Filtro inválido: profundidade de N grupos excede o limite de 20." |
| Nós > 500 | Ao submeter | Toast + "Filtro inválido: N condições/grupos excedem o limite de 500." |
| Referência circular | Ao submeter | Toast + "Filtro inválido: referência circular entre grupos de condições." |
| Profundidade no teto (19) | **Em tempo de edição** | O botão "Grupo" some e é substituído por "Limite de 20 niveis atingido" |
| Regra com `field: ""` | **Nunca** | Salva normalmente (§5.5.4) |
| Regra com `value: ""` | **Nunca** | Salva |
| Valor incompatível com o tipo | **Nunca** | Salva |
| Operador incompatível após troca de tabela | **Nunca** | Salva |
| `between` invertido ou incompleto | **Nunca** | Salva |
| Grupo sem regras | **Nunca** (inalcançável pela UI — §5.3.8) | — |
| Nome duplicado | **Nunca** | Dois filtros com o mesmo nome |
| Filtro salvo que falha no cálculo | Na listagem | `AlertCircle` + tooltip com o motivo, **preservando o cache** (§2.13) |
| Filtro com campo que não existe mais | **Nunca** | O combobox mostra o `field` cru, sem aviso (§6.1) |

**Assimetria central:** o produto valida **estrutura** (profundidade, nós, ciclo, mundo) com rigor e mensagens excelentes, e **não valida conteúdo** (campo, operador, valor) de forma nenhuma. Um filtro estruturalmente perfeito e semanticamente vazio salva sem um pio.

**O único feedback em tempo de edição de todo o construtor** é o aviso de teto de profundidade. Não há contador de nós, indicador de entidade alvo, marcação de regra incompleta, nem prévia embutida.

### 11.7 Estados de transição e pendência

| Ação | Feedback |
|---|---|
| Ativar/desativar filtro | Item de menu e Switch ficam `disabled` enquanto `toggleFilterActive.isPending` — **mas a mudança só aparece após a resposta** (não há atualização otimista) |
| Salvar filtro | Botão vira `Loader2` + mantém o rótulo |
| Excluir (individual/massa) | `AlertDialogAction` vira `Loader2` + "Excluindo..." |
| Exportar CSV | Botão vira `Loader2`, `disabled` |
| Paginação do modal de contatos | Botões `disabled` quando `isFetching` |
| Paginação da lista de filtros | **Não** desabilita durante o fetch — só nos extremos |
| Refresh de stats | `RefreshableSection` dima a seção; o botão gira |
| Carteira: "Atualizar Stats" | **Nenhum feedback visual no item de menu** — o menu fecha e nada indica progresso até os números mudarem |

**Lacuna:** "Atualizar Stats" de uma carteira é uma chamada a Edge Function que pode levar segundos, sem nenhum indicador. O usuário clica de novo achando que não funcionou.

---

## 12. Fluxos de uso passo a passo

Cada fluxo abaixo é a sequência real de cliques no produto atual, com os pontos de atrito marcados.

### 12.1 Criar um filtro simples ("inadimplentes acima de 30 dias")

| # | Ação | O que acontece | Atrito |
|---|---|---|---|
| 1 | Menu lateral → **Filtros** | Lista carrega (20 por página, ativos, A-Z) | — |
| 2 | Botão **Novo Filtro** | Dialog abre em `95vw × 95vh`, com raiz → 1 grupo → 1 regra vazia | Dialog ocupa a tela inteira para um filtro de 1 condição |
| 3 | Digita o nome | — | — |
| 4 | *(opcional)* escolhe cor e ícone | `SelectValue` mostra bolinha + nome | Chama-se "Tags" na listagem, mas aqui é "Cor" |
| 5 | Escolhe o escopo | `RadioGroup` com 2 opções (só na criação a partir do botão do cabeçalho, que passa `allowAgentScope`) | "Somente Agentes de IA" aparece **primeiro**, sendo o caso raro |
| 6 | Na regra: dropdown **Tabela** → "Titulo" | O campo pula para o **primeiro** da lista de títulos (`title_number`) | Operador e valor **não** resetam |
| 7 | Clica no **FieldCombobox** → busca "atraso" → "Dias em Atraso" | Operador se ajusta (era `eq`, continua válido para `number`) | Lista única, sem agrupamento por categoria |
| 8 | Dropdown **Operador** → "maior que" | — | Rótulos longos truncam no `w-36` |
| 9 | Digita `30` no valor | `parseFloat` no save | Sem unidade ("dias"), sem validação de faixa |
| 10 | Botão **Criar Filtro** | Dialog fecha | **Sem toast de sucesso** — nada confirma que salvou |
| 11 | O filtro aparece na lista | Números vêm do cache (zeros na primeira vez) até o batch responder | — |

**Custo total:** ~10 interações para 1 condição.

### 12.2 Criar um filtro composto ("(atraso > 30 E status Disponivel) OU valor > 5.000")

| # | Ação | Atrito |
|---|---|---|
| 1-5 | Idem 12.1 (identidade) | — |
| 6 | Configura a 1ª regra (atraso > 30) | — |
| 7 | Clica **+ Condicao** no grupo | Nova regra vazia **no fim** |
| 8 | Configura a 2ª regra (status = Disponivel) | Tem de reescolher a tabela "Titulo" — **a regra nova nasce em `contacts`**, não herda a tabela da irmã |
| 9 | Confere que o grupo está em **E (AND)** | Padrão correto |
| 10 | Volta ao nível 0 e clica **+ Grupo** | Novo grupo no fim, já com 1 regra |
| 11 | No **grupo 2**, muda a lógica para **OU (OR)** | **Erro comum:** a lógica que precisa mudar é a do nível 0 (que combina os dois grupos), não a do grupo novo. E **o nível 0 não tem seletor de lógica visível no mesmo lugar** — ele tem, mas sem o rótulo "Grupo · nivel N" que ancora a leitura |
| 12 | Configura a regra do grupo 2 (valor > 5.000) | Idem passo 8 |
| 13 | Salva | — |
| 14 | Menu ⋯ → **Visualizar** para conferir | A prévia mostra as condições — **mas sem a negação, e com "Título" no lugar de tabelas que não sejam contato/contrato** |

**Ponto de atrito mais caro:** a leitura da lógica. O conector entre itens mostra "E"/"OU"; o seletor do grupo mostra "E (AND)"/"OU (OR)"; o card da lista mostra "AND"/"OR". **Três vocabulários para o mesmo conceito, na mesma jornada.**

### 12.3 Conferir se o filtro pega quem deveria

| # | Ação | Resultado |
|---|---|---|
| 1 | Menu ⋯ → **Visualizar** | Prévia com 7 métricas + amostra de 10 |
| 2 | Lê os cartões | Números do universo inteiro, recalculados agora |
| 3 | Lê a amostra | 10 contatos, ordenados pelo maior atraso |
| 4 | Precisa de outra coluna (ex.: telefone) | Picker **"Colunas (6)"** → busca → marca | Nova consulta ao banco; coluna vai para o **fim** da tabela |
| 5 | Quer ver todos | **Fecha a prévia**, volta à lista, menu ⋯ → **Ver Contatos** | **Não há atalho** da prévia para a carteira |
| 6 | No modal de contatos, refaz a seleção de colunas | A seleção da prévia **não** foi herdada | Refaz do zero |
| 7 | Clica numa linha | `PortfolioDetailSheet` abre com o contato | — |
| 8 | Exporta | **"Exportar CSV (6)"** → até 20 páginas de 500 → download | Sem progresso; erro só aparece no fim |

**Dois atritos estruturais:** (a) prévia e carteira são becos sem saída — nenhuma leva à outra nem à edição; (b) a seleção de colunas é refeita em cada modal, em cada abertura.

### 12.4 Ajustar um filtro existente

| # | Ação | Atrito |
|---|---|---|
| 1 | Busca pelo nome | **Sem debounce** — uma query por tecla |
| 2 | Clica na linha (ou ⋯ → Editar) | Construtor abre com as condições carregadas | O clique na linha **não** verifica `filters:write` |
| 3 | Ajusta a condição | — |
| 4 | Percebe que errou e quer descartar | Clica fora / ESC → **perde tudo, sem aviso** |
| 5 | Salva | Dialog fecha, sem toast |
| 6 | Quer conferir o impacto | Reabre pelo menu ⋯ → Visualizar | Sem prévia dentro do construtor |

**O passo 4 é o risco real do fluxo.** Sem confirmação de descarte, um ESC acidental num filtro de 20 condições é irrecuperável.

### 12.5 Higienizar a biblioteca

| # | Ação | Como |
|---|---|---|
| 1 | Descobrir o que não é usado | **Impossível pela interface.** Não há indicador de uso, data de último uso, nem "usado por N carteiras/réguas" |
| 2 | Filtrar por estado | ToggleGroup **Ativos / Inativos / Todos** |
| 3 | Desativar um candidato | ⋯ → Desativar (lista) **ou** Switch (card) — reversível, com toast explicando as duas metades |
| 4 | Confirmar que ninguém reclamou | Espera |
| 5 | Excluir de vez | ⋯ → Excluir → `AlertDialog` → confirma |
| 6 | Em massa | Marca os checkboxes → barra azul → "Excluir selecionados" → `AlertDialog` com a contagem |

**Armadilha do passo 6:** a seleção **não é limpa** ao trocar de página, buscar ou trocar o recorte de status (§4.12). É possível confirmar "Excluir 12 filtros" vendo apenas 3 na tela.

**O passo 1 é a lacuna central de toda a tela.** O gestor não tem como saber o que é lixo — e sem isso, o fluxo de higienização começa no escuro.

### 12.6 Criar uma carteira a partir de um filtro

| # | Ação | Atrito |
|---|---|---|
| 1 | Cria/identifica o filtro em `/filters` | — |
| 2 | Navega para **ETL** | Rota diferente, permissão diferente (`etl:read`) — um `operator` **não chega aqui** |
| 3 | Aba **Carteiras** | — |
| 4 | Botão **Nova Carteira** | Dialog `95vh` |
| 5 | Nome, cor, ícone | Cor e ícone já vêm preenchidos |
| 6 | Aba **Por Filtro** | Padrão é "Por Campo" — precisa trocar |
| 7 | `<Select>` de filtros | **Sem busca**, teto de 100, só o nome |
| 8 | Confirmação "✓ Filtro selecionado: X" | Redundante; não diz quantos contatos |
| 9 | **Criar Carteira** | Se der erro: `alert("Erro ao salvar carteira")` |
| 10 | Configurar integrações | **Precisa reabrir** em modo edição — o painel não existe na criação, e nada avisa isso |

**Atrito de fluxo mais visível do produto:** o operador que cria o filtro frequentemente **não tem permissão** para criar a carteira que o consome. Duas telas, duas permissões, um único trabalho.

### 12.7 Vincular integrações a uma carteira

| # | Ação | Atrito |
|---|---|---|
| 1 | Aba Carteiras → ⋯ → **Editar** | — |
| 2 | Rola até o fim do dialog | O painel fica **abaixo** de todo o formulário, sem âncora |
| 3 | Clica em **Configurar** no canal desejado | Abre `AddIntegrationDialog` **dentro** do `PortfolioDialog` — dois modais empilhados |
| 4 | Canal já vem selecionado (se veio pelo "Configurar") | — |
| 5 | Escolhe a integração | Se não houver: texto dizendo para ir em Configurações > Integrações — **sem link** |
| 6 | Checkbox "principal" **já marcado** | Rebaixa a principal anterior sem avisar |
| 7 | **Adicionar** | Toast de sucesso |
| 8 | Remover uma integração | **Um clique no lixo, sem confirmação nenhuma** |

### 12.8 Investigar um filtro que está com erro

| # | Ação | Resultado |
|---|---|---|
| 1 | Vê o `AlertCircle` vermelho na coluna "Atualizado" | — |
| 2 | Passa o mouse | Tooltip: "Não foi possível calcular os números deste filtro." + o `errorMessage` real |
| 3 | Confere que os números exibidos são o cache antigo | O ícone `Clock` do `StatsFreshnessIndicator` indica cache |
| 4 | Clica no refresh geral | Recalcula todos |
| 5 | Se persistir, abre a **Prévia** | **E aqui o diagnóstico para:** se o preview também falhar, a mensagem é "Erro ao carregar prévia", **sem motivo** |
| 6 | Abre o construtor para inspecionar as condições | Sem contador de nós, sem indicador de entidade alvo, sem SQL gerado |

**O fluxo de diagnóstico começa bem (tooltip com o motivo) e termina cego.** O ponto onde o usuário mais precisa de detalhe é o que menos oferece.

### 12.9 Fluxo de um `viewer` (papel sem `filters:read`)

| # | Ação | O que acontece |
|---|---|---|
| 1 | Abre o produto | **"Filtros" não aparece no menu lateral** |
| 2 | Recebe um link `/filters` de um colega | **Entra normalmente** — a rota não é guardada |
| 3 | Vê a lista completa | Sem botão "Novo Filtro", sem itens de escrita no menu |
| 4 | Clica numa linha | **O construtor abre em modo edição** |
| 5 | Altera algo e clica em "Salvar Alterações" | A mutação é disparada; a proteção efetiva depende de RLS no banco |
| 6 | Menu ⋯ → Ver Contatos → Exportar CSV | **Funciona** — exporta até 10.000 contatos |

`⚠️ A confirmar:` os passos 4-6 precisam de validação com o time. O modelo declarado é "RBAC frontend-only + RLS no banco", mas a UI expõe superfícies de escrita e de exportação em massa a um papel que não deveria nem ver a tela.

---

## 13. Responsividade e acessibilidade

### 13.1 Breakpoints declarados

Inventário de todas as classes responsivas do domínio:

| Local | Classe | Efeito |
|---|---|---|
| Grade de cards de filtro | `grid gap-4 md:grid-cols-2 lg:grid-cols-3` | 1 col → 2 (≥768px) → 3 (≥1024px) |
| Grade de cards de carteira | `grid gap-4 md:grid-cols-2 lg:grid-cols-3` | Idem |
| Esqueleto de filtros (grade) | `grid gap-4 md:grid-cols-2 lg:grid-cols-3` | Idem |
| Barra de controles | `flex flex-wrap items-center gap-3` | Quebra em telas estreitas (comentário IAF-6986: "passa a quebrar em telas estreitas em vez de espremer os controles") |
| Linha de regra do construtor | `flex items-center gap-2 ... flex-wrap` | Quebra |
| `FilterPortfolioModal` | `w-[96vw] sm:max-w-[1200px]` | Teto de largura a partir de `sm` |
| HelpTip popover | `w-80 max-w-[90vw]` | Nunca ultrapassa a viewport |

**Isso é tudo.** Sete pontos responsivos em todo o domínio.

### 13.2 O que NÃO é responsivo

| Elemento | Problema |
|---|---|
| **Tabela de filtros (12 colunas)** | `<Table>` sem container de scroll horizontal explícito. Em telas estreitas as colunas espremem ou a página ganha scroll horizontal |
| **Tabela de carteiras (6 colunas)** | Idem |
| **7 cartões da prévia** | `grid-cols-7` **fixo**. Em 1366px, ~180px por cartão — valores monetários estouram. Em mobile, 7 colunas de ~50px |
| **Dialogs `95vw × 95vh`** | Em desktop grande, desperdício; em mobile, ocupam a tela inteira sem adaptação de layout interno |
| **`PortfolioDialog` `95vh`** | Formulário de 5 campos numa janela de altura quase total |
| **`ScrollArea h-[400px]`** (integrações), **`h-72`** (picker), **`h-[150px]`** (valores de campo), **`h-64`** (selos) | Alturas fixas em pixels — não se adaptam à altura da viewport |
| **`<select>` nativos** `w-32` / `w-36` | Larguras fixas; rótulos longos truncam |
| **`FieldCombobox`** `min-w-52` | Mínimo de 208px numa linha que já tem 5 outros controles |
| **Indentação de grupos** `border-l-4` + `p-3` | Cada nível consome ~28px de largura. No nível 10, restam ~280px para a regra numa tela de 1366px |

**Conclusão:** o domínio é desenhado para **desktop largo**. Em tablet, a tabela de 12 colunas e os 7 cartões já degradam. Em telefone, o construtor é inutilizável.

`⚠️ A confirmar:` se mobile é requisito. O produto é uma torre de controle operacional — talvez desktop-only seja decisão consciente. Se for, deve ser declarada; hoje há `md:`/`lg:` espalhados que sugerem intenção responsiva incompleta.

### 13.3 Acessibilidade — o que está certo

| Prática | Onde |
|---|---|
| `aria-busy` na seção durante refresh | `RefreshableSection` |
| `aria-label` no Switch de ativação, com o nome do filtro | `"Ativar filtro {nome}"` / `"Desativar filtro {nome}"` |
| `aria-label` no gatilho do HelpTip | `"Ajuda: {título}"` |
| `aria-expanded` no combobox | `FieldCombobox`, `ValueCombobox` |
| `role="combobox"` | Idem |
| `<caption className="sr-only">` explicando as duas semânticas | Tabela da prévia |
| `<th scope="col">` | Tabela da prévia |
| `DialogDescription sr-only` | `FilterPreviewDialog` |
| `<span className="sr-only">Indisponível: {motivo}</span>` | `PreviewColumnPicker` (ramo morto, mas correto) |
| **Arraste por teclado** | `KeyboardSensor` + `sortableKeyboardCoordinates` no dnd-kit |
| **Profundidade em texto**, não só em cor | "Grupo · nivel N" (§5.2.3) — decisão explícita: "a cor cíclica sozinha não basta… e nunca bastou para quem não distingue cores" |
| **Rótulo textual ao lado da cor** | Popover de Tags (§4.16) e `SelectValue` de cor do `FilterHeader` |
| HelpTip como **popover clicável**, não tooltip de hover | Decisão declarada: "acessível no mobile, texto não trunca" |
| `Label htmlFor` | `PreviewColumnPicker`, `PortfolioDialog`, valores de campo |
| `stopPropagation` em controles dentro de linhas clicáveis | Checkbox, menu, HelpTip |

**O domínio tem consciência de acessibilidade em pontos específicos e bem argumentados.** A redundância cor+texto na profundidade dos grupos é um acerto de design que o redesign deve preservar explicitamente.

### 13.4 Acessibilidade — o que está errado

| # | Problema | Onde | Gravidade |
|---|---|---|---|
| 1 | **`<select>` nativo sem `<label>` nem `aria-label`** | Ordenação da barra de controles; Tabela e Operador da regra; booleano do valor | Alta — leitor de tela anuncia "combo box" sem nome |
| 2 | **Botão de recarregar sem nome acessível** | `FilterPreviewDialog` (só ícone `RefreshCw`) | Alta |
| 3 | **`TooltipTrigger` sem `asChild` e sem elemento focável** | Estrela de "integração principal" | Alta — inalcançável por teclado |
| 4 | **Linha de tabela clicável sem semântica** | `<TableRow onClick>` na lista de filtros e no modal de contatos — não é `<button>`, não tem `role`, `tabIndex` nem `onKeyDown` | Alta — a ação principal da linha não existe para teclado |
| 5 | **Bloco de stats do card clicável** sem semântica | Card da grade de filtros | Alta |
| 6 | **Colunas numéricas clicáveis** (`<TableCell onClick>`) sem semântica | Colunas 4-10 da lista | Alta |
| 7 | **`<input type="checkbox">` cru com `border-gray-300`** | `AddIntegrationDialog` | Média — fora do design system e do tema |
| 8 | **Cores hex fixas em `style={{}}`** | Paleta de tags, bolinhas de cor, bordas de card, ícones de carteira | Média — não respondem a tema claro/escuro; contraste não verificado |
| 9 | **`text-[9px]` e `text-[10px]`** | Rótulos de stats do card de filtro, cartões da prévia, badges de slug, selo "filtro" | Média — abaixo do mínimo legível |
| 10 | **Estado só por cor** | Verde/laranja/vermelho dos valores; `text-green-600` do check de filtro selecionado | Média |
| 11 | **Alça de arraste some quando o grupo tem 1 filho** | `SortableItem disabled` — o alinhamento muda e o controle desaparece sem explicação | Média (contraria o princípio do §2.5) |
| 12 | **Botão desabilitado sem motivo** | "Criar Carteira" cinza sem nenhuma indicação do que falta | Média |
| 13 | **`title` HTML como único mecanismo de ajuda** | Botão NÃO da regra; badges de escopo/inativo; `title` dos cabeçalhos de coluna | Média — `title` não aparece em toque e tem delay longo |
| 14 | **Toast como único feedback de ações destrutivas** | Exclusões | Baixa — `useToast` do shadcn tem `role="status"`; verificar se é `assertive` |
| 15 | **Ordem de foco no dialog `95vh`** | Construtor com árvore longa: o rodapé é fixo mas vem por último no DOM | Baixa |
| 16 | **Sem `aria-live`** para a contagem de resultados | "{N} filtros encontrados" muda sem anúncio | Baixa |
| 17 | **Modais aninhados** | `AddIntegrationDialog` dentro de `PortfolioDialog` — gestão de foco em dois níveis | Baixa a média |

**Os itens 4, 5 e 6 são o mesmo defeito, repetido:** toda a navegação por clique do domínio (abrir edição, abrir carteira do filtro) é implementada com `onClick` em elementos não-interativos. **Para quem usa teclado, a tela de Filtros só tem o menu `⋯`.**

### 13.5 Contraste e tema

| Aspecto | Situação |
|---|---|
| Tokens CSS | A maior parte do domínio usa `text-muted-foreground`, `bg-muted`, `border-primary`, `text-destructive` — corretos e temáticos |
| Exceções hardcoded | `text-emerald-600`, `text-orange-500`, `text-red-500`, `text-blue-500`, `text-green-600`, `fill-yellow-400`, `border-gray-300`, `#6B7280`, e os 10 hex das paletas |
| Cores por nível de grupo | `border-l-blue-500/50 bg-blue-500/5`, `purple`, `amber` — classes Tailwind fixas, não tokens |
| Tema escuro | As cores de estado (emerald/orange/red) têm contraste **não verificado** em fundo escuro; as bolinhas hex **não mudam** |

**Regra do projeto violada:** o `CLAUDE.md` do repo diz "NUNCA usar cores hardcoded (usar CSS vars)". O domínio de filtros e carteiras a viola em pelo menos 12 lugares.

**Nuance:** as cores de **tag** (paleta de 10) são **dado do usuário**, não decoração — precisam mesmo ser hex fixos. O problema não é armazená-las, é **renderizá-las sem ajuste de contraste** contra o fundo do tema.

### 13.6 Recomendações mínimas de acessibilidade para o redesign

| # | Mudança | Resolve |
|---|---|---|
| 1 | Toda linha/card clicável vira `<button>` ou ganha `role="button"` + `tabIndex={0}` + `onKeyDown` (Enter/Espaço) | Itens 4, 5, 6 |
| 2 | Todo `<select>` nativo ganha `<label>` visível ou `aria-label` | Item 1 |
| 3 | Todo botão só-ícone ganha `aria-label` | Itens 2, 3 |
| 4 | Substituir `<input type="checkbox">` cru pelo `Checkbox` do design system | Item 7 |
| 5 | Mínimo de `text-xs` (12px) para qualquer texto informativo | Item 9 |
| 6 | Estado sempre com ícone **e** cor (o `OverdueBadge` já faz isso — usar como referência) | Item 10 |
| 7 | Botão desabilitado sempre acompanhado do motivo | Item 12 |
| 8 | `HelpTip` no lugar de `title` HTML em toda ajuda que não seja trivial | Item 13 |
| 9 | Renderizar cor de tag com ajuste de contraste por tema, mantendo o rótulo textual ao lado | Item 8 |
| 10 | Preservar a redundância cor+texto de profundidade de grupo (§5.2.3) | — (já correto) |

---

## 14. Dores e oportunidades para o redesign

Esta seção é a leitura de produto do que foi levantado nas §0-13. Nada aqui é invenção: cada item aponta a seção que o documenta.

### 14.1 As oito invariantes que o redesign NÃO pode quebrar

Antes das oportunidades, o que é intocável. Cada uma existe por um incidente ou uma decisão documentada no código.

| # | Invariante | Fonte | O que quebra se ignorar |
|---|---|---|---|
| 1 | **Erro ≠ vazio.** Falha de cálculo preserva o cache e sinaliza o erro; nunca mostra `0` | §2.13 | "0 contatos" por falha vira decisão errada de cobrança |
| 2 | **Escopo de uso é imutável.** Sem controle de edição; para mudar, duplicar | §2.7, regra 29 do projeto | Trocar escopo esconderia o filtro de réguas/blocklists que já o referenciam |
| 3 | **Filtro misto é proibido.** Suprimento e contrato não convivem numa árvore | §2.10 | O compilador escolheria uma partição e as regras da outra seriam avaliadas contra colunas erradas, **em silêncio** |
| 4 | **Desativar ≠ desligar.** Some dos seletores; vínculos existentes continuam valendo — e o toast diz as duas metades | §2.8, §5.5.7 | Sem a segunda metade, desativar é lido como "desliguei a régua" e vira chamado |
| 5 | **Quando um controle some, a tela diz por quê** | §2.5 | O limite de 2 níveis anterior era um limite de produto disfarçado de detalhe de UI, invisível |
| 6 | **Profundidade é legível sem depender de cor** | §5.2.3 | A cor cíclica tem 4 entradas e nunca bastou para quem não distingue cores |
| 7 | **Nenhum CSV parcial.** Exportação aborta inteira em qualquer inconsistência | §8.9.1 | Um CSV com 8.500 de 10.000 linhas é indistinguível de um completo |
| 8 | **`null` vira `"-"`, nunca `0`** nas células | §8.4.4 | "0" e "não sei" são leituras diferentes |

**Além destas, duas invariantes técnicas:** `days_overdue` aceita negativos (cobrança preventiva D-7, D-1) e a proteção anti-injeção de fórmula no CSV (§8.9.3).

### 14.2 Dores estruturais (mudam a arquitetura da tela)

#### D1 — Não se sabe onde um filtro é usado

| Aspecto | Situação |
|---|---|
| Sintoma | Excluir ou desativar um filtro é decisão às cegas |
| Evidência | §9.5 — o vínculo existe no banco (`portfolios.filter_definition_id`), mas não há nenhuma superfície de leitura reversa |
| Impacto | Biblioteca acumula lixo porque ninguém arrisca apagar; ou apaga-se algo em produção |
| Personas afetadas | Gestor (§1.2 — "a biblioteca acumula lixo e ele não sabe o que está em uso"), Admin |
| Oportunidade | Coluna/badge "usado por N" na lista; lista nominal no `AlertDialog` de exclusão; aba "Onde é usado" na prévia |
| Custo | Média — precisa de consulta nova, mas os dados existem |

**É a dor nº 1 do domínio.** Aparece nos jobs-to-be-done (§1.3, item 6), nas dores das personas (§1.2) e em três fluxos (§12.5, §12.8).

#### D2 — Filtro e carteira são o mesmo trabalho em duas telas com permissões diferentes

| Aspecto | Situação |
|---|---|
| Sintoma | O operador cria o filtro em `/filters` e **não consegue** criar a carteira que o consome (`etl:read`) |
| Evidência | §0.4, §12.6 |
| Impacto | Trabalho dividido entre duas pessoas; ida e volta entre rotas |
| Oportunidade | Unificar num domínio "Segmentação" com abas, ou permitir criar carteira a partir do filtro (a prop `onFilterCreated` já existe no builder — §5.0.1) |
| Custo | Alto (rota/permissão) ou baixo (só o atalho) |

#### D3 — O construtor não dá feedback do que está sendo construído

| Falta | Evidência |
|---|---|
| Prévia embutida | §5.4.6 — "é preciso salvar e usar Visualizar" |
| Contagem de nós / profundidade atual | §2.6 — "o usuário pode montar 501 nós e só descobrir ao salvar" |
| Indicador de entidade alvo (contrato × suprimento) | §5.1.3 — "o usuário não vê em lugar nenhum se o filtro é de contrato ou de suprimento. Só descobre quando erra" |
| Tradução legível da árvore | Existe, mas **só na prévia**, em outro modal, e com 5 defeitos (§8.3.2) |
| Colapso de grupos | §5.4.5 — "provavelmente o maior ganho disponível" |

**Oportunidade combinada:** um painel lateral no construtor com (a) a leitura em linguagem natural da árvore, (b) a contagem ao vivo de contatos/títulos, (c) o indicador de entidade alvo, (d) o contador de nós. Resolve D3 inteira e mata a necessidade de abrir a prévia em 80% dos casos.

#### D4 — A biblioteca não tem estratégia de organização

| Aspecto | Situação |
|---|---|
| O que existe | Busca (nome/descrição), cor ("Tags"), tri-state de ativação, 3 ordenações |
| O que não existe | Pastas, tags reais (com nome), favoritos, agrupamento por frente, filtro por criador, filtro por data, filtro por entidade alvo |
| Evidência | §4.16 — "o filtro se chama 'Tags' e mostra cores, sem nenhum nome de tag real" |
| Impacto | Com 100+ filtros, a busca por nome é a única navegação viável |
| Oportunidade | Tags nomeadas (a cor vira atributo da tag); agrupamento por entidade alvo (o dado já existe em `target_entity`) |

#### D5 — Carteiras são uma tela de segunda classe

Comparação direta:

| Recurso | Filtros | Carteiras |
|---|---|---|
| Busca | Sim (na URL) | Sim (só em memória) |
| Ordenação | 3 critérios + direção | Fixa em `display_order` (que ninguém edita) |
| Paginação | Sim | **Não** (teto invisível de 50) |
| Seleção múltipla | Sim | Não |
| Exclusão em massa | Sim | Não |
| Confirmação de exclusão | `AlertDialog` | **`confirm()` nativo** |
| Erro ao salvar | Toast com motivo | **`alert()` genérico** |
| Erro de estatística | Ícone + tooltip | **Invisível** |
| Ativar/desativar | Sim | **Não** (campo existe, controle não) |
| Duplicar | Sim | Não |
| Ver contatos | Sim | Não |
| Estados de loading | Esqueleto | Spinner |
| Permissões granulares | 3 níveis | Nenhuma |
| Campos filtráveis | 88 + dinâmicos | **5 hardcoded** |

**A aba de Carteiras parece uma versão de 2 anos atrás da tela de Filtros.** Paridade de recursos é trabalho grande mas mecânico — os padrões já existem no mesmo produto.

#### D6 — Não há preservação do trabalho em andamento

| Perda | Onde |
|---|---|
| Árvore de condições ao fechar o dialog | §5.0.2, §12.4 — "não há confirmação de descarte" |
| Formulário de carteira ao fechar | §10.4.11 |
| Seleção de colunas ao fechar prévia/carteira do filtro | §8.6.5 |
| Estado de ordenação/tri-state/cores ao recarregar | §3.3 — só busca, página e ordenação vão para a URL |
| Desfazer / refazer no construtor | §5.4.6 — não existe |
| Remoção de grupo com 10 regras | §5.4.4 — "um clique irreversível" |

**Três mecanismos de persistência diferentes** para seis controles da mesma barra (URL, memória, localStorage) — §3.3.

### 14.3 Dores de consistência (mudam a linguagem visual, não a arquitetura)

| # | Dor | Evidência | Esforço |
|---|---|---|---|
| C1 | **Três vocabulários de lógica:** "E"/"OU" (conector), "E (AND)"/"OU (OR)" (seletor), "AND"/"OR" (card) | §4.7, §5.2.4, §5.2.6 | Baixo |
| C2 | **Três formatos de moeda:** 0 casas + compacta (lista), 2 casas (prévia), 2 casas (carteira do filtro) | §4.4, §8.4.2, §10.1.7 | Baixo |
| C3 | **Três implementações de `DynamicIcon`** com três fallbacks (`null`, `Filter`, `Briefcase`) | §5.1.1, §10.4.4 | Baixo |
| C4 | **Duas paletas de cor idênticas** duplicadas em `types/filters.ts` e `types/portfolios.ts` | §10.4.4 | Baixo |
| C5 | **Acentuação inconsistente:** 86 campos sem acento, 2 com; painel de integrações inteiro sem acento; colunas "(no filtro)" com acento | §6.7, §8.5, §9.6.6 | Baixo |
| C6 | **Dois catálogos de campo** (`types/filters.ts` × `lib/filters/fields.ts`) alimentando construtor e prévia | §8.3.3 | Média |
| C7 | **Três catálogos de canal** com conjuntos e rótulos diferentes ("Ligacao" × "Voz") | §9.6.2 | Baixa |
| C8 | **Status com dois nomes:** o filtro mostra "Falhou"; a tela de Ações mostra "Falha Temporária de Ação" | §6.9.5 | Baixa |
| C9 | **Cinco modais, cinco convenções** de largura, ícone, rodapé, erro e reset | §10.9 | Média |
| C10 | **Verde significa coisas opostas:** "Valor Pago" em Filtros, "Dívida Total" em Carteiras | §9.4.3 | Baixo |
| C11 | **Lista × grade não são equivalentes:** a grade mostra condições e lógica; a lista tem Ativar/Desativar no menu | §3.4 | Baixo |
| C12 | **Ícones que mostram o estado, não a ação:** `ArrowUpDown` com `title="Crescente"`; `StarOff` que torna principal | §4.17, §9.6.4 | Baixo |

### 14.4 Dores de conteúdo e dado

| # | Dor | Evidência |
|---|---|---|
| N1 | **`description` de 12 campos nunca é exibida** — inclusive a advertência de `supplies.total_value`, que diverge 2,7× do que a carteira mostra | §6.4 |
| N2 | **Campos `select` sem opções caem em input livre** — `owner_pipeline_id` exige digitar UUID à mão | §6.3, §5.3.10 |
| N3 | **`seals` só funciona em 3 das 5 entidades** que o declaram | §6.5 |
| N4 | **Pipelines e fontes de dados usam o nome como valor** — renomear quebra o filtro em silêncio | §6.6 |
| N5 | **`useFieldValues` limita a 100 LINHAS, não a 100 valores** — a carteira "Por Campo" pode nascer incompleta sem sintoma | §9.3.2 |
| N6 | **Seletor de filtro da carteira tem teto de 100, sem busca** | §9.5.1 |
| N7 | **Campos removidos do registry** ficam órfãos em filtros antigos, sem marcação | §6.1 |
| N8 | **Falha ao carregar campos customizados é invisível** | §5.3.9 |
| N9 | **Nenhuma validação de conteúdo** (campo vazio, valor vazio, tipo incompatível, `between` invertido) | §5.5.5 |
| N10 | **Troca de tabela não reseta operador nem valor** — produz combinação inválida silenciosa | §5.3.3 |

### 14.5 Oportunidades ordenadas por relação valor/esforço

#### Tier 1 — alto valor, baixo esforço

| # | Oportunidade | Resolve |
|---|---|---|
| 1 | **Confirmação de descarte** no construtor e no `PortfolioDialog` | D6 |
| 2 | **Erro da prévia com motivo + "Tentar novamente"** (copiar o padrão do `FilterPortfolioModal`) | §8.8, invariante 1 |
| 3 | **Substituir `confirm()` e `alert()` das Carteiras** por `AlertDialog` e toast com mensagem real | §9.4.6, §10.4.10 |
| 4 | **Exibir `description` do campo** no item do combobox e ao lado do campo selecionado | N1 |
| 5 | **Unificar o vocabulário de lógica** (escolher um: "E"/"OU") | C1 |
| 6 | **Unificar o formato de moeda** | C2 |
| 7 | **Confirmação ao remover integração** | §9.6.4 |
| 8 | **Distinguir "biblioteca vazia" de "busca sem resultado"** na tela de Filtros (o padrão já existe nas Carteiras) | §11.3 |
| 9 | **Motivo do botão desabilitado** no `PortfolioDialog` | §10.4.8 |
| 10 | **Toast de sucesso ao criar/salvar filtro** e ao excluir um filtro | §5.5.7, §10.7 |
| 11 | **Mostrar `negate` (NÃO/NOT) na tradução das condições da prévia** | §8.3.2 defeito 5 |
| 12 | **Corrigir o rótulo de entidade da prévia** (5 de 8 tabelas viram "Título") | §8.3.2 defeito 1 |

#### Tier 2 — alto valor, esforço médio

| # | Oportunidade | Resolve |
|---|---|---|
| 13 | **Indicador de uso do filtro** ("usado por N carteiras/réguas"), na lista e na confirmação de exclusão | **D1** |
| 14 | **Painel de leitura ao vivo no construtor** (tradução da árvore + contagem + entidade alvo + contador de nós) | **D3** |
| 15 | **Colapsar/expandir grupos** | D3, §5.4.5 |
| 16 | **Persistir a seleção de colunas** com escopo próprio (usuário + org + contexto), sem reusar a chave da carteira | D6, §8.6.5 |
| 17 | **Validação de conteúdo da regra** (campo obrigatório, valor obrigatório, tipo compatível, `between` ordenado) com marcação visual em tempo de edição | N9, N10 |
| 18 | **Atalhos entre modais:** da prévia para "Editar" e "Ver Contatos"; do modal de contatos para "Editar" | §12.3 |
| 19 | **Busca no seletor de filtros da carteira** + remoção do teto de 100 | N6 |
| 20 | **Paridade de recursos da aba Carteiras** (paginação, ordenação, confirmação, erros) | D5 |
| 21 | **Semântica de teclado** em todas as linhas/cards/células clicáveis | §13.6 |
| 22 | **Consolidar o catálogo de campos** numa fonte única | C6 |

#### Tier 3 — alto valor, esforço alto

| # | Oportunidade | Resolve |
|---|---|---|
| 23 | **Unificar Filtros e Carteiras** num domínio de Segmentação, ou ao menos permitir criar a carteira a partir do filtro | **D2** |
| 24 | **Tags nomeadas** substituindo o filtro por cor | D4 |
| 25 | **Mover regra entre grupos** por arraste (hoje o DnD é por grupo) | §5.4.1 |
| 26 | **Desfazer/refazer no construtor** | D6 |
| 27 | **Duplicar regra e grupo** dentro do construtor | §5.4.3 |
| 28 | **Envolver/desembrulhar grupo** (converter regra em grupo e vice-versa) | §5.4.6 |
| 29 | **Campos da carteira "Por Campo" derivados dos custom fields reais da org** | §9.3.1 |
| 30 | **Estratégia responsiva declarada** (desktop-only assumido ou adaptação real) | §13.2 |

### 14.6 Riscos do redesign — o que é fácil quebrar sem perceber

| # | Risco | Por quê |
|---|---|---|
| 1 | **Reusar a persistência de colunas da Gestão de Carteira** | Decisão deliberada de NÃO compartilhar (§8.6.5). Reusar faria escolher coluna aqui mudar a grade de lá |
| 2 | **Simplificar a chave do `fieldOptionsMap` para só o nome do campo** | Reintroduz o bug de `titles.status` × `contracts.status` (BLD-14, §6.3) |
| 3 | **Reescrever a exportação** | Perde a proteção anti-injeção de fórmula (§8.9.3) e/ou passa a gerar CSV parcial (§8.9.1) |
| 4 | **Tornar o escopo de uso editável** | Trigger no banco recusa o UPDATE (§2.7). A UI quebraria contra o backend |
| 5 | **Usar `!filter.is_active`** em vez de `is_active !== false` | A coluna ainda é nullable em orgs sem a migration (§2.8) |
| 6 | **"Corrigir" os valores de `AGING_BUCKET_OPTIONS`** (ex.: `31-60` com hífen) | Os literais precisam casar exatamente o `CASE` da MV (§6.9.7) |
| 7 | **Aplicar `ACTION_STATUS_DISPLAY` nos valores gravados** | Os rótulos de exibição são **frontend-only**; o valor gravado deve continuar canônico (§6.9.5) |
| 8 | **Mostrar `0` quando o cálculo falha** | Invariante 1 |
| 9 | **Mover ou alterar `src/components/ui/`** | Regra de compatibilidade Lovable do projeto (§0.5) |
| 10 | **Introduzir cores hardcoded novas** | Regra do projeto; e o domínio já tem 12 violações a corrigir, não a ampliar |

### 14.7 Três perguntas de produto que o redesign precisa responder

1. **Lista e grade devem ser equivalentes?** Hoje divergem em funcionalidade (§3.4). Ou se unifica, ou se declara que a grade é "visão rica" e a lista é "visão densa".
2. **Mobile é requisito?** O domínio é desktop-first com resíduos responsivos incompletos (§13.2). A decisão muda o desenho do construtor inteiro.
3. **A exportação de até 10.000 contatos deveria ter permissão própria?** Hoje qualquer um que alcance a tela exporta documento, telefone, e-mail e valores (§11.5).

---

## 15. Inventário de modais do domínio

Lista fechada de **toda** superfície sobreposta (dialog, alert, sheet, popover com estado) que o domínio Filtros + Carteiras abre. Detalhamento em §10.

### 15.1 Dialogs

| # | Componente | Arquivo | Título exibido | Gatilho | Tamanho | Detalhe em |
|---|---|---|---|---|---|---|
| 1 | `FilterBuilderDialog` (criar) | `src/components/filters/filter-builder/index.tsx` | "Novo Filtro" | Botão "Novo Filtro"; link "Criar primeiro filtro" | `95vw × 95vh` | §5, §10.3 |
| 2 | `FilterBuilderDialog` (editar/duplicar) | idem | "Editar Filtro" | Menu "Editar"; clique na linha/card; menu "Duplicar" | `95vw × 95vh` | §5, §10.3 |
| 3 | `FilterPreviewDialog` | `src/components/filters/FilterPreviewDialog.tsx` | "Visualizar Filtro" | Menu "Visualizar" | `95vw × 95vh` | §8, §10.2 |
| 4 | `FilterPortfolioModal` | `src/components/filters/FilterPortfolioModal.tsx` | "Contatos do Filtro: {nome}" | Menu "Ver Contatos"; clique nas colunas numéricas; clique no bloco de stats do card | `96vw`, máx. `1200px × 88vh` | §10.1 |
| 5 | `PortfolioDialog` (criar) | `src/components/portfolios/PortfolioDialog.tsx` | "Nova Carteira" | Botão "Nova Carteira" (cabeçalho do ETLPage e estado vazio) | `95vw × 95vh` | §10.4 |
| 6 | `PortfolioDialog` (editar) | idem | "Editar Carteira" | Menu "Editar" da aba Carteiras | `95vw × 95vh` | §10.4 |
| 7 | `AddIntegrationDialog` | dentro de `PortfolioIntegrationsPanel.tsx` | "Adicionar Integracao" | Botão "Adicionar Integracao"; botão "Configurar" de canal vazio | Padrão shadcn | §10.5 |

**Observação:** os itens 1/2 e 5/6 são **a mesma instância de componente** com props diferentes. São contados separadamente porque a experiência difere (rótulos, campos disponíveis, painel de integrações).

### 15.2 AlertDialogs

| # | Arquivo | Título | Gatilho | Ação destrutiva | Detalhe em |
|---|---|---|---|---|---|
| 8 | `src/pages/FiltersPage.tsx` (~1373) | "Confirmar exclusão" | Botão "Excluir selecionados" | `deleteFilters.mutateAsync(ids)` | §10.6 |
| 9 | `src/pages/FiltersPage.tsx` (~1405) | "Confirmar exclusão" | Menu "Excluir" | `deleteFilter.mutateAsync(id)` | §10.7 |

### 15.3 Diálogos nativos do navegador (a eliminar)

| # | Arquivo | Tipo | Texto | Detalhe em |
|---|---|---|---|---|
| 10 | `PortfoliosTab.tsx` (~147) | `window.confirm()` | `Tem certeza que deseja excluir a carteira "{nome}"?` | §10.8 |
| 11 | `PortfolioDialog.tsx` (~138) | `window.alert()` | `Erro ao salvar carteira` | §10.4.10 |

### 15.4 Sheets (painéis laterais)

| # | Componente | Aberto por | Conteúdo |
|---|---|---|---|
| 12 | `PortfolioDetailSheet` | Clique numa linha do `FilterPortfolioModal` | Detalhe do contato (fora do escopo deste documento — pertence ao domínio de Gestão de Carteira) |

### 15.5 Popovers com estado próprio

Não são modais, mas são superfícies sobrepostas com estado e lógica próprios — o redesign precisa tratá-las.

| # | Componente | Arquivo | Gatilho | Tamanho | Detalhe em |
|---|---|---|---|---|---|
| 13 | Popover de Tags (cores) | `FiltersPage.tsx` | Botão "Tags" da barra de controles | `w-64 p-3` | §4.16 |
| 14 | `PreviewColumnPicker` | `src/components/filters/PreviewColumnPicker.tsx` | Botão "Colunas (N)" — **usado por 2 modais** | `w-80 p-0`, lista `h-72` | §8.6 |
| 15 | `FieldCombobox` | `filter-builder/FieldCombobox.tsx` | Botão de campo da regra | `w-80 p-0` | §5.3.5 |
| 16 | `ValueCombobox` (único e múltiplo) | `filter-builder/ValueCombobox.tsx` | Botão de valor da regra | `w-64 p-0` | §5.3.7 |
| 17 | `SealsValueInput` | dentro de `FilterRuleItem.tsx` | Botão "Selecionar selos..." | `w-72 p-0`, lista `max-h-64` | §5.3.7 |
| 18 | `HelpTip` (5 tópicos) | `src/components/common/HelpTip.tsx` | Ícone `?` | `w-80 max-w-[90vw]` | §3.6 |

### 15.6 Menus suspensos

| # | Onde | Itens | Detalhe em |
|---|---|---|---|
| 19 | Linha da tabela de filtros | 6: Ver Contatos, Visualizar, Editar, Duplicar, Ativar/Desativar, Excluir | §4.10 |
| 20 | Card da grade de filtros | 5: os mesmos **sem** Ativar/Desativar | §4.10 |
| 21 | Linha da tabela de carteiras | 3: Editar, Atualizar Stats, Excluir | §9.4.5 |
| 22 | Card da grade de carteiras | 3: os mesmos | §9.4.5 |

### 15.7 Contagem final

| Categoria | Quantidade |
|---|---|
| Dialogs | 7 (5 componentes, 7 experiências) |
| AlertDialogs | 2 |
| Diálogos nativos (a eliminar) | 2 |
| Sheets | 1 (de outro domínio) |
| Popovers com estado | 6 |
| Menus suspensos | 4 |
| **Total de superfícies sobrepostas** | **22** |

### 15.8 Aninhamento — quais modais abrem outros

```
FiltersPage
├── FilterBuilderDialog (criar)
│   ├── FieldCombobox (popover)          ← por regra
│   ├── ValueCombobox (popover)          ← por regra
│   ├── SealsValueInput (popover)        ← por regra de selo
│   └── HelpTip × 3 (popover)
├── FilterBuilderDialog (editar/duplicar)  [mesma árvore]
├── FilterPreviewDialog
│   └── PreviewColumnPicker (popover)
├── FilterPortfolioModal
│   ├── PreviewColumnPicker (popover)
│   └── PortfolioDetailSheet (sheet)     ← 2 níveis de sobreposição
├── AlertDialog (exclusão em massa)
├── AlertDialog (exclusão individual)
├── Popover de Tags
└── HelpTip × 2 (cabeçalho)

ETLPage → aba Carteiras
├── PortfolioDialog (criar)
├── PortfolioDialog (editar)
│   └── PortfolioIntegrationsPanel
│       └── AddIntegrationDialog          ← 2 níveis de Dialog
└── confirm() nativo (exclusão)
```

**Dois pontos de aninhamento de 2 níveis:**

1. `FilterPortfolioModal` → `PortfolioDetailSheet` (Dialog + Sheet)
2. `PortfolioDialog` → `AddIntegrationDialog` (Dialog + Dialog)

Ambos exigem gestão de foco em camadas e ESC que fecha apenas a camada superior. `⚠️ A confirmar:` comportamento do ESC no caso 2 — se fecha só o `AddIntegrationDialog` ou os dois (perdendo o formulário da carteira sem aviso, §10.4.11).

### 15.9 Componentes reutilizados entre modais

| Componente | Usado por | Divergência de comportamento |
|---|---|---|
| `PreviewColumnPicker` | `FilterPreviewDialog`, `FilterPortfolioModal` | **Sim** — a prévia permite zerar as colunas; a carteira bloqueia na última (§8.6.4) |
| `buildPreviewColumnCatalog` | Os dois acima | Não |
| `getPreviewColumnValue` | Os dois | Não |
| `OverdueBadge` | Os dois (célula de atraso) | Não |
| Renderização de célula | `renderPreviewCell` × `renderColumnValue` | **Duas implementações quase idênticas** (§8.4.4) |
| `formatCurrency` | Três implementações distintas | **Sim** (§10.1.7) |
| `DynamicIcon` | Três implementações distintas | **Sim** — fallbacks diferentes (§10.4.4) |
| `PORTFOLIO_COLORS` / `FILTER_COLORS` | Duas constantes idênticas duplicadas | — (§10.4.4) |

**Leitura para o redesign:** o domínio já tem um núcleo compartilhado bem desenhado (catálogo de colunas, badge de atraso, acessor de valor). O que falta consolidar é a camada de formatação e de ícones — trabalho mecânico, sem risco funcional.

---

*Fim do documento. Todas as afirmações foram extraídas da leitura do código em `cobranca-finza/` na data de redação. Itens marcados `⚠️ A confirmar:` exigem validação com o time antes de virar requisito de redesign.*
