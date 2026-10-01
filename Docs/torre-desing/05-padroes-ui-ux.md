# 05 · Padrões de UI/UX Transversais

> Fonte da verdade: `src/components/common/*`, `src/components/ui/loading-states.tsx`, `src/hooks/useToast.ts`, `src/hooks/useDirtyFormGuard.ts`, `src/lib/error-handler.ts`, `src/index.css`.
> Estes são os padrões que se repetem em **todas** as telas. Se o redesenho mudar um deles, muda o produto inteiro — por isso cada um está descrito com o **problema que resolve**, não só com a aparência.

---

## 1. Anatomia padrão de uma página

Quase toda tela interna segue esta estrutura:

```
┌─────────────────────────────────────────────────────────────┐
│ CABEÇALHO DA PÁGINA                                         │
│  título (h1/h2) + descrição (muted)      [ações primárias]  │
├─────────────────────────────────────────────────────────────┤
│ BARRA DE KPIs (opcional)                                    │
│  grid de 2 (md) / 4 (lg) cards                              │
├─────────────────────────────────────────────────────────────┤
│ BARRA DE FILTROS                                            │
│  controles + chips de filtros ativos + botão limpar         │
│  (recolhível em mobile via MobileCollapsibleFilters)        │
├─────────────────────────────────────────────────────────────┤
│ ABAS (opcional)                                             │
├─────────────────────────────────────────────────────────────┤
│ CONTEÚDO                                                    │
│  tabela / grid de cards / kanban / gráficos                 │
├─────────────────────────────────────────────────────────────┤
│ RODAPÉ                                                      │
│  contadores + paginação                                     │
└─────────────────────────────────────────────────────────────┘
```

Container: `p-3` (mobile) → `sm:p-6` (desktop), dentro do scroller único do `AppLayout`.

---

## 2. Padrão de carregamento híbrido (assinatura do produto)

Este é o padrão mais importante e mais bem resolvido do produto atual. **Deve ser preservado.**

O problema que resolve: o React Query está configurado com `refetchOnWindowFocus: false`, então o usuário **precisa** atualizar manualmente — e uma atualização não pode apagar a tela que ele está lendo.

A regra é:

| Situação | O que a interface faz |
|---|---|
| **Primeiro carregamento** (sem dado ainda) | Mostra **esqueleto** (skeleton) da estrutura final. Nunca spinner nu. |
| **Atualização com dado já na tela** | **Mantém o dado visível**, aplica um escurecimento sutil, mostra uma barra de progresso indeterminada no topo e gira o ícone do botão de atualizar. |

Três componentes implementam isso:

### 2.1 `RefreshButton` — `src/components/common/RefreshButton.tsx`

| Aspecto | Comportamento |
|---|---|
| Ícone | `RefreshCw`, `h-4 w-4`; gira (`animate-spin`) enquanto ocupado. |
| Variante padrão | `outline`. Tamanho: `sm` com rótulo, `icon` sem rótulo. |
| Estado ocupado | Gira **se** `isFetching` externo for verdadeiro **ou** se a promessa devolvida por `onRefresh` estiver pendente (rastreamento interno). |
| Desabilitado | Enquanto ocupado. |
| Acessibilidade | `aria-label` e `title` (padrão "Atualizar"), `aria-busy`. |
| Erro | Silencioso no botão — o erro é tratado pela camada de query/mutação; o botão apenas reabilita. |

### 2.2 `RefreshTopBar` — `src/components/common/RefreshTopBar.tsx`

Barra fina indeterminada no topo da área de conteúdo.

- `absolute inset-x-0 top-0 z-20 h-0.5`, trilho `bg-primary/15`, indicador `bg-primary` com largura `w-1/3`.
- Animação `refresh-bar`: percorre da esquerda para a direita, 1.1s, infinita.
- `pointer-events-none`, `role="progressbar"`, `aria-busy="true"`, `aria-label="Atualizando"`.
- Não renderiza nada quando `active` é falso.

### 2.3 `RefreshableSection` — `src/components/common/RefreshableSection.tsx`

Envolve o bloco de dados. Enquanto atualiza: `opacity-60` + `pointer-events-none` + `aria-busy`, com `transition-opacity`.

> **Trio obrigatório:** `RefreshTopBar` (barra) + `RefreshableSection` (escurecimento) + `RefreshButton` (spinner). Aparecem juntos.

---

## 3. Catálogo de estados de carregamento, vazio e erro

`src/components/ui/loading-states.tsx`

| Componente | Forma | Parâmetros | Uso |
|---|---|---|---|
| `CardSkeleton` | Card com cabeçalho + valor | `showIcon` | Um KPI. |
| `KPIGridSkeleton` | Grade `md:2 / lg:4` de cards | `count` (4) | Barra de KPIs. |
| `ChartSkeleton` | Barras de alturas variadas | `height` (250) | Gráfico. |
| `TableSkeleton` | Cabeçalho + N linhas × M colunas | `rows` (5), `columns` (4), `showHeader` | Tabela. |
| `ListSkeleton` | Itens com avatar + duas linhas | `items` (5), `showAvatar` | Lista. |
| `GridCardSkeleton` | Grade de cards | `count` (6), `columns` (2\|3\|4) | Galeria de cards. |
| `PageHeaderSkeleton` | Título + descrição | `showDescription` | Cabeçalho de página. |
| `FormSkeleton` | N campos | `fields` (4) | Formulário. |
| `FiltersPageSkeleton` | Variável por modo | `viewMode`, `count` | Tela de filtros. |
| `FullPageLoading` | Spinner + mensagem, `h-[50vh]` centrado | `message` ("Carregando...") | Carregamento de seção inteira. |
| `EmptyState` | Ícone + título + descrição + ação | `icon`, `title`, `description`, ação | **Vazio.** |
| `ErrorState` | Ícone + título + descrição + "tentar novamente" | padrão: "Erro ao carregar dados" / "Ocorreu um erro ao carregar os dados. Tente novamente." | **Erro.** |

**Textos padrão que o redesenho herda:**
- Carregando: *"Carregando..."*
- Erro: título *"Erro ao carregar dados"*, corpo *"Ocorreu um erro ao carregar os dados. Tente novamente."*

⚠️ **Problema real:** apesar de o catálogo existir, **nem todas as telas o usam**. Há telas com spinner nu, telas com "Nenhum registro" em texto solto e telas que engolem erro de rede e mostram estado vazio (comportamento confirmado em `fetchOrganizations`). **Padronizar o uso é uma das maiores entregas possíveis do redesenho.**

---

## 4. Notificações (toasts)

`src/hooks/useToast.ts` + `src/components/ui/toast.tsx` + `toaster.tsx`

| Aspecto | Valor |
|---|---|
| **Limite simultâneo** | **1** (`TOAST_LIMIT = 1`) — um toast novo **substitui** o anterior. |
| Tempo até remoção | 3000 ms (`TOAST_REMOVE_DELAY`). |
| Variantes | `default` e `destructive`. |
| Estrutura | `title` + `description` + `action` opcional. |
| API | `toast({ title, description, variant })`, com `update()` e `dismiss()`. |
| Estado | Store global em memória com listeners (fora do React). |

**Consequências de design:**
1. Com limite 1, uma operação em lote que emite vários toasts mostra **apenas o último**. Operações em massa precisam de outro canal de feedback (painel de resultado, não toast).
2. Só há duas variantes — sucesso e aviso usam `default`, o que apaga a diferença entre "deu certo" e "atenção". **O redesenho deveria ter `success`, `warning`, `info` e `destructive`.**
3. 3 segundos é curto para mensagens de erro com instrução. Erros acionáveis deveriam persistir até dispensa.

---

## 5. Ajuda contextual — `HelpTip`

`src/components/common/HelpTip.tsx`

Átomo "?" que explica métricas, colunas e conceitos. Padrão maduro e bem pensado — **preservar o modelo**.

| Aspecto | Comportamento |
|---|---|
| Gatilho | Botão redondo com ícone `HelpCircle` `size-3.5`, `text-muted-foreground` → hover `text-foreground`, `cursor-help`, `aria-label="Ajuda: <título>"`, com `stopPropagation` (convive com linhas e cabeçalhos clicáveis). |
| Variante `popover` (**padrão**) | **Clicável** — acessível no toque, bom para texto longo, nunca trunca (`whitespace-normal break-words`). Largura `w-80 max-w-[90vw]`. |
| Variante `tooltip` | Hover, só para dicas curtas. `max-w-xs`. |
| Conteúdo | Ou uma **chave** do catálogo único `HELP_COPY` (`src/lib/filters/help-copy.ts`), ou conteúdo inline (`title`/`body`), ou uma **explicação estruturada**. |

### 5.1 Explicação estruturada (padrão de ouro do produto)

Quando recebe `explanation`, renderiza campos fixos, na ordem, com rótulo em negrito e corpo em `muted`:

| Campo | Rótulo exibido | Formato |
|---|---|---|
| `what` | **O que é** | texto |
| `origin` | **Origem** | texto |
| `howCalc` | **Como calcula** | bloco `code` com fundo `muted` |
| `when` | **Quando acontece** | texto |
| `note` | **Observação** | texto |

> Este é o **contrato de transparência** da Torre: toda métrica pode dizer de onde veio e como foi calculada. O redesenho deve estender esse padrão, não reduzi-lo.

Complemento: `MetricExplanationPopover` (`src/components/common/MetricExplanationPopover.tsx`) para métricas do Dashboard.

---

## 6. Barra de filtros

Padrão comum às telas de Dashboard, Ações, Carteira, Campanhas, Filtros.

| Elemento | Comportamento |
|---|---|
| Controles | `Select` (valor único), `MultiSelect` (múltiplo, com chips), `Calendar`/intervalo (período), `Input` com debounce (busca). |
| Busca | Debounce via `useDebouncedSearchInput` / `useDebouncedValue`. |
| Chips de filtros ativos | Lista de pílulas removíveis abaixo dos controles (`ActiveFilterChips`). |
| Limpar | Botão "Limpar filtros" quando há filtro ativo. |
| Persistência | Parte dos filtros vai para a **query string** (`useUrlFilters`) — permite compartilhar a visão por link. |
| Mobile | Recolhida por `MobileCollapsibleFilters`. |
| Lógica E/OU | Presente nas telas de Carteira e Filtros (`FilterLogicToggle`). |

⚠️ Inconsistência: cada tela montou sua própria barra (`DashboardFiltersBar`, `ActionsFiltersBar`, `PortfolioFiltersBar`, `KanbanFiltersBar`, `MetricsFiltersBar`, `ConversationFilters`). Os controles são parecidos mas não idênticos — rótulos, ordem e comportamento de limpar divergem. **Unificar é alta prioridade.**

---

## 7. Tabelas de dados

Não existe um `DataTable` compartilhado (ver doc 04, dívida nº 2). O que se repete, implementado caso a caso:

| Recurso | Como costuma aparecer |
|---|---|
| Ordenação | Clique no cabeçalho, com ícone de seta. |
| Seleção | Checkbox na primeira coluna + checkbox "selecionar todos" no cabeçalho. |
| Ações em massa | Barra que aparece quando há seleção, com contador ("N selecionados") e botões. |
| Ações por linha | Menu `DropdownMenu` com ícone de três pontos na última coluna. |
| Seletor de colunas | Popover com checkboxes (`PortfolioColumnToggle`, `PreviewColumnPicker`). |
| Paginação | Rodapé com contador total e navegação. |
| Virtualização | TanStack Virtual nas listas grandes. |
| Rolagem horizontal | `overflow-x-auto` com toque suave em mobile. |
| Densidade | Linha padrão; sem controle de densidade explícito. |

**Limite técnico que afeta o design:** o PostgREST não aceita mais de ~200 identificadores na URL. Isso restringe "selecionar todos" em listas grandes — a UI precisa de "aplicar ao filtro inteiro" em vez de "aplicar à seleção".

---

## 8. Formulários

| Padrão | Situação atual |
|---|---|
| Biblioteca | `react-hook-form` + `zod`, via componente `Form`. |
| Erro de campo | `FormMessage` abaixo do campo, em `text-destructive`. |
| Erro de operação | Toast `destructive`. |
| Campo obrigatório | ⚠️ Sem marcação visual padronizada (asterisco) — varia por tela. |
| Botão de envio | `default` (azul) no rodapé do modal, à direita; "Cancelar" como `outline` à esquerda. |
| Estado de envio | Cada tela implementa (não há `loading` no Button). |
| Formulários longos | Wizards com `WizardStepper` (ETL, régua, carteira). |

⚠️ **Inconsistência conhecida:** nem toda tela usa `Form` — várias gerenciam estado manualmente e reportam erro só por toast, o que faz o usuário não saber **qual campo** está errado.

### 8.1 Guarda de formulário sujo — `useDirtyFormGuard`

`src/hooks/useDirtyFormGuard.ts`

Impede sair de um formulário com alterações não salvas, exibindo confirmação. Usado nos editores (régua, broadcast) e nos wizards. Detalhado no doc 22.

---

## 9. Confirmação de ação destrutiva

Padrões observados, em ordem de intensidade:

| Nível | Padrão | Onde |
|---|---|---|
| 1 | `AlertDialog` simples: título + descrição + "Cancelar" / botão destrutivo. | Excluir item comum. |
| 2 | `AlertDialog` com **digitação de confirmação** (nome ou slug do recurso). | Excluir organização (**pede nome E slug**), excluir agente de IA (pede slug). |
| 3 | Modal dedicado com **consequências listadas** e contadores. | Cancelar ações pendentes de campanha, bloqueio em massa, executar fora da janela. |

⚠️ Falta um padrão único para **operações irreversíveis de alto volume** (disparo em massa, execução de campanha). Hoje cada uma inventa o seu aviso. **Proposta para o redesenho:** um componente `DangerConfirm` com: verbo da ação, escopo numérico ("vai enviar 4.812 mensagens"), o que **não** poderá ser desfeito, e confirmação proporcional ao risco.

---

## 10. Alternância de visualização

Dois mecanismos coexistem:

1. `ViewToggle` (cards ↔ lista) — `src/components/ui/view-toggle.tsx`, com persistência via `useViewPreference`.
2. Abas próprias para Kanban na Carteira.

Unificar num só controle extensível (tabela / cards / kanban / timeline) é melhoria direta.

---

## 11. Navegação secundária

| Padrão | Uso |
|---|---|
| Abas (`Tabs`) | Dashboard (5), Carteira, ETL (4), Configurações (~15), Workspace do Agente. |
| Sheet lateral | Detalhe do contato, construtor de integração, configuração de passo. |
| Modal | Formulários focados e confirmações. |
| Rota dedicada em tela cheia | Editores de régua e broadcast. |
| Painel lateral persistente | Maestro (empurra o conteúdo). |

⚠️ Configurações com ~15 abas em rolagem horizontal é o pior caso de navegação do produto. **Proposta:** navegação lateral em duas colunas, agrupada por tema.

---

## 12. Mensagens e voz da interface

Observações do código atual:

- Idioma: **português do Brasil**, com exceções pontuais em inglês (papel do convite aparece como `operator`/`admin`; alguns rótulos de Super Admin sem acentuação).
- Tom: direto e operacional.
- Números: sem formatação padronizada única — há `formatters.ts`, mas nem toda tela o usa.
- Datas: fuso de Brasília tratado explicitamente (`brt-date.ts`), porque a plataforma de execução distorce o fuso.

⚠️ **Dívida de copy:** o produto tem termos técnicos vazando para a interface (disposições de pipeline, nomes de RPC em mensagens de erro, `excluded_not_max_overdue`). O redesenho deve incluir um **glossário de rótulos** e uma revisão de copy.

---

## 13. Acessibilidade — estado atual

| Já existe | Falta |
|---|---|
| Link "pular para conteúdo" | Cards clicáveis como `<div>` sem `role`/`tabIndex` (confirmado na tela de organização) |
| Landmarks `navigation` / `main` | Ações reveladas só no hover (invisíveis no toque, mas focáveis) |
| Anel de foco consistente | Contraste não auditado nos badges improvisados |
| `aria-busy` nos estados de atualização | Anúncio de mudança de estado para leitor de tela em operações longas |
| `prefers-reduced-motion` | Ordem de foco em modais aninhados |
| Radix (foco preso, ESC, teclado) | Rótulos de gráfico para leitor de tela |

---

## 14. Os 10 padrões que o redesenho precisa entregar

1. **Carregamento híbrido** (esqueleto na 1ª vez, dado + barra + escurecimento na atualização) — aplicado em **todas** as telas, sem exceção.
2. **Estados vazio / erro / sem permissão** padronizados, sempre com ação de saída.
3. **Ajuda estruturada** (O que é / Origem / Como calcula / Quando / Observação) em toda métrica e toda coluna não óbvia.
4. **Badge semântico** único para todos os status do produto.
5. **DataTable** único com seleção, colunas, ordenação, paginação, densidade e estados.
6. **Barra de filtros** única, com chips, limpar e persistência em URL.
7. **Toasts** com quatro variantes e duração proporcional à criticidade; feedback de lote fora do toast.
8. **Confirmação de risco** proporcional, com escopo numérico explícito.
9. **Indicador de frescor do dado** em toda tela que lê a view materializada.
10. **Glossário de rótulos** — nenhum termo técnico de banco na interface.
