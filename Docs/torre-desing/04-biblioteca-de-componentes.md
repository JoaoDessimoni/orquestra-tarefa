# 04 · Biblioteca de Componentes Base

> Fonte da verdade: `cobranca-finza/src/components/ui/*`.
> Base: **shadcn/ui sobre Radix UI**, com variantes por `class-variance-authority` (CVA) e merge por `tailwind-merge` (helper `cn()` em `src/lib/utils.ts`).
> Restrição dura: a pasta `src/components/ui/` **não pode ser movida** (sincronização com Lovable.dev). O redesenho reestiliza esses arquivos; não os realoca.

---

## 1. Inventário completo (40 primitivos)

| Componente | Arquivo | Base | Papel |
|---|---|---|---|
| Accordion | `accordion.tsx` | Radix | Seções expansíveis empilhadas. |
| Alert | `alert.tsx` | — | Faixa de aviso inline. |
| AlertDialog | `alert-dialog.tsx` | Radix | Confirmação bloqueante (ações destrutivas). |
| Avatar | `avatar.tsx` | Radix | Foto/iniciais do usuário. |
| Badge | `badge.tsx` | — | Pílula de status/rótulo. |
| Button | `button.tsx` | Radix Slot | Ação. |
| Calendar | `calendar.tsx` | react-day-picker | Seleção de data. |
| Card | `card.tsx` | — | Contêiner de bloco. |
| Checkbox | `checkbox.tsx` | Radix | Booleano / seleção em lista. |
| Collapsible | `collapsible.tsx` | Radix | Mostrar/ocultar bloco. |
| Command | `command.tsx` | cmdk | Paleta de busca/comando (base de todos os comboboxes). |
| Dialog | `dialog.tsx` | Radix | **Modal** (customizado — ver §4). |
| DropdownMenu | `dropdown-menu.tsx` | Radix | Menu de ações. |
| Form | `form.tsx` | react-hook-form | Campo com label, descrição e mensagem de erro. |
| Input | `input.tsx` | — | Texto de uma linha. |
| Label | `label.tsx` | Radix | Rótulo de campo. |
| LoadingStates | `loading-states.tsx` | — | **Catálogo de esqueletos de carregamento** (20 KB — ver doc 22). |
| MobileCollapsibleFilters | `mobile-collapsible-filters.tsx` | — | Recolhe a barra de filtros em telas pequenas. |
| MultiSelect | `multi-select.tsx` | Popover + Command | Seleção múltipla com chips. |
| Popover | `popover.tsx` | Radix | Painel flutuante ancorado. |
| Progress | `progress.tsx` | Radix | **Três variantes** — ver §6. |
| RadioGroup | `radio-group.tsx` | Radix | Escolha exclusiva. |
| ScrollArea | `scroll-area.tsx` | Radix | Área rolável com barra estilizada. |
| Select | `select.tsx` | Radix | Escolha única em lista. |
| Separator | `separator.tsx` | Radix | Divisória. |
| Sheet | `sheet.tsx` | Radix Dialog | **Painel lateral/gaveta** — ver §5. |
| Skeleton | `skeleton.tsx` | — | Bloco cinza pulsante. |
| Slider | `slider.tsx` | Radix | Valor contínuo. |
| SqlEditor | `sql-editor.tsx` | CodeMirror | Edição de SQL com realce. |
| Switch | `switch.tsx` | Radix | Liga/desliga. |
| Table | `table.tsx` | — | Tabela semântica. |
| Tabs | `tabs.tsx` | Radix | Abas. |
| Textarea | `textarea.tsx` | — | Texto multilinha. |
| Toast | `toast.tsx` | Radix | Notificação temporária. |
| Toaster | `toaster.tsx` | — | Container global de toasts. |
| ToggleGroup | `toggle-group.tsx` | Radix | Grupo de botões alternáveis. |
| Tooltip | `tooltip.tsx` | Radix | Dica no hover/foco. |
| VariablePreview | `variable-preview.tsx` | — | Prévia de variável `{{...}}` resolvida. |
| ViewToggle | `view-toggle.tsx` | — | Alterna cards ↔ lista. |
| RichVariableInput | `rich-variable-input/` | TipTap + Tippy | **Editor de mensagem com chips de variável** — ver §9. |

---

## 2. Button

`src/components/ui/button.tsx`

**Classes base:** `inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors cursor-pointer focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 disabled:cursor-not-allowed [&_svg]:size-4 [&_svg]:shrink-0`

### Variantes

| Variante | Aparência | Quando é usada no produto |
|---|---|---|
| `default` | Azul sólido (`bg-primary`), texto branco, hover 90% | Ação principal da tela/modal: Salvar, Criar, Executar, Enviar. |
| `destructive` | Vermelho sólido, texto branco | Excluir, Bloquear, Cancelar ações, Revogar chave. |
| `outline` | Borda `input`, fundo `background`, hover `accent` | Ação secundária: Cancelar, Filtros, Exportar, seletor de organização. |
| `secondary` | Fundo `secondary` cinza, hover 80% | Ação terciária. |
| `ghost` | Sem fundo, hover `accent` | Ação de ícone, item de barra de ferramentas, menu, fechar. |
| `link` | Texto azul sublinhado no hover | Navegação inline. |

### Tamanhos

| Tamanho | Medidas |
|---|---|
| `default` | `h-10 px-4 py-2` |
| `sm` | `h-9 px-3` |
| `lg` | `h-11 px-8` |
| `icon` | `h-10 w-10` |

`asChild` (Radix Slot) permite aplicar o visual de botão em um `<Link>`.

**Observação para o redesenho:** não existe variante `success` nem `warning` de botão. Onde o produto precisa de ação "positiva" com cor, ele usa `default` (azul) + ícone. E não existe estado de carregamento embutido — cada tela implementa o seu (geralmente trocando o ícone por um `Loader2 animate-spin` e desabilitando). **Padronizar `loading` no Button é uma melhoria de alto retorno.**

---

## 3. Badge

`src/components/ui/badge.tsx`

**Base:** `inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors`

| Variante | Aparência |
|---|---|
| `default` | Azul sólido, texto branco. |
| `secondary` | Cinza, texto escuro. |
| `destructive` | Vermelho sólido, texto branco. |
| `outline` | Só texto `foreground` com borda. |

**Limitação crítica:** o Badge **não tem variantes `success`, `warning` ou `info`** — mas o produto precisa delas o tempo todo (12 status de ação, status de título, status de campanha, status de pipeline, saúde de MV...). Resultado: as telas aplicam classes Tailwind soltas por cima (`className="bg-green-100 text-green-800"` etc.), gerando **inconsistência cromática entre telas**.

> **Esta é a maior dívida do design system atual.** O redesenho deve entregar um Badge com variantes semânticas completas (`success`, `warning`, `info`, `destructive`, `neutral`) em versões sólida e suave (`soft`), e migrar todos os badges de status para elas.

---

## 4. Dialog (modal) — customizado

`src/components/ui/dialog.tsx`

O Dialog **não é o shadcn padrão**. Foi reescrito para resolver conflito entre posicionamento por `transform` e as animações. Anatomia:

```
DialogPortal
 └ DialogOverlay        fixed inset-0 z-[60] bg-black/80
 └ div (wrapper)        fixed inset-0 z-[60] flex items-center justify-center overflow-y-auto
                        p-4  (ou p-0 quando fullscreen)
    └ DialogPrimitive.Content   relative z-10 grid gap-4 border bg-background px-6 shadow-xl
                                max-h-[calc(100vh-2rem)] sm:rounded-xl overflow-hidden
                                animação: fade-in-0 + zoom-in-95, 200ms
       ├ DialogHeader   -mx-6 px-6 pt-6 pb-4 border-b
       │                bg-gradient-to-r from-primary/5 to-transparent   ← assinatura visual
       │   ├ DialogTitle        text-lg font-semibold tracking-tight flex items-center gap-2
       │   └ DialogDescription  text-sm text-muted-foreground
       ├ DialogBody     -mx-6 px-6 py-4
       └ DialogFooter   -mx-6 px-6 py-4 border-t bg-muted/30
                        flex-col-reverse → sm:flex-row sm:justify-end sm:space-x-2
       └ DialogClose    absolute right-4 top-4 · rounded-full p-1.5 · ícone X h-4 w-4 · sr-only "Close"
```

Pontos de design a preservar:

1. **Centralização por flex**, não por `transform` — permite modal mais alto que a tela rolar no wrapper.
2. **Cabeçalho com gradiente azul sutil** (`from-primary/5 to-transparent`) — é a assinatura visual do modal da Torre.
3. **Rodapé em `bg-muted/30` com borda superior** e botões alinhados à direita; **em mobile inverte a ordem** (`flex-col-reverse`), colocando a ação primária embaixo/primeiro na leitura de baixo para cima.
4. **`fullscreen`** (prop própria): remove padding do wrapper, `h-full`, sem raio. Usado em modais gigantes (prévia de campanha, ação manual).
5. `overflow-hidden` no Content: a rolagem acontece dentro do `DialogBody`, não no modal inteiro.
6. `z-[60]` — acima de Sheet (`z-50`).

O `DialogBody` é uma extensão própria (não existe no shadcn padrão) e serve justamente para isolar a área rolável.

---

## 5. Sheet (painel lateral)

`src/components/ui/sheet.tsx`

| Lado | Classes |
|---|---|
| `top` | `inset-x-0 top-0 border-b`, entra deslizando de cima. |
| `bottom` | `inset-x-0 bottom-0 border-t`. |
| `left` | `inset-y-0 left-0 h-full w-3/4 border-r sm:max-w-sm`. |
| `right` | `inset-y-0 right-0 h-full w-3/4 border-l sm:max-w-sm`. |

Overlay `z-50 bg-black/80`. Animação: 500ms na entrada, 300ms na saída.

`SheetHeader` é `text-center sm:text-left` (centralizado em mobile). `SheetFooter` inverte ordem em mobile como o Dialog.

**Uso no produto:** painel de detalhe do contato (Carteira), construtor de integração, configuração de passo da régua. Ou seja: **sheet = inspetor/edição contextual; dialog = confirmação ou formulário focado.** Essa distinção deve sobreviver.

⚠️ `sm:max-w-sm` (384px) é estreito para o detalhe do contato, que tem 4 abas densas. Na prática as telas sobrescrevem via `className`. O redesenho deveria oferecer tamanhos nomeados (`sm`/`md`/`lg`/`xl`) no Sheet.

---

## 6. Progress — três variantes

`src/components/ui/progress.tsx`

| Componente | Aparência | Uso |
|---|---|---|
| `Progress` | Barra `h-4 rounded-full bg-secondary`, indicador `bg-primary` movido por `translateX`. | Progresso simples. |
| `ProgressDual` | Barra `h-4` com **dois segmentos**: enviados (`bg-primary`) e falhas (`bg-destructive`), posicionados por `left`/`width`. | Progresso de envio em massa (Disparos/Ações). |
| `ProgressMulti` | Barra **`h-2`** com N segmentos arbitrários (`{percentage, color, label}`), cada um com **tooltip opcional** mostrando `label + X.X%`. Segmentos com 0% são omitidos e as posições são acumuladas. | Composição de status (ex.: distribuição de uma campanha entre enviado/falhou/cancelado). |

`ProgressMulti` é efetivamente um **gráfico de barra empilhada 100%** — e é um dos poucos lugares onde o produto já acerta em mostrar composição sem gráfico pesado.

---

## 7. MultiSelect

`src/components/ui/multi-select.tsx`

Popover + Command (cmdk) + Badges.

| Recurso | Comportamento |
|---|---|
| Opções | `{ label, value, color?, icon? }` — **icon é o nome de um ícone lucide resolvido dinamicamente** (`DynamicIcon`), e `color` tinge o chip. |
| Exibição padrão | **1 chip + badge "+N"** quando há múltiplos selecionados. |
| `showAllSelected` | Opt-in: renderiza **todos** os chips com quebra de linha, sem "+N". |
| Remover | `X` no chip (`handleUnselect`). |
| Busca | `CommandInput` dentro do popover. |
| Vazio | `CommandEmpty`. |
| Desabilitado | prop `disabled`. |

Esse componente é a base de quase todos os filtros multi-valor do produto (carteiras, réguas, status, tags, canais).

⚠️ O padrão "1 chip + N" economiza espaço mas esconde a seleção — várias telas passaram a usar `showAllSelected`. O redesenho deve decidir um padrão único e previsível.

---

## 8. ViewToggle

`src/components/ui/view-toggle.tsx`

Par de botões `h-8 w-8` dentro de um trilho `rounded-lg border bg-muted/30 p-0.5`. Ativo: `bg-background shadow-sm text-foreground`. Inativo: `text-muted-foreground`.

Ícones: `LayoutGrid` (cards) e `List` (lista). Títulos (tooltip nativo): "Visualização em cards" / "Visualização em lista".

Tipo: `ViewMode = "card" | "list"`.

**Observação:** o Kanban da Carteira usa um mecanismo próprio (não este toggle) — logo há duas maneiras diferentes de trocar visualização no produto. Unificar é melhoria.

---

## 9. RichVariableInput (editor de mensagem)

`src/components/ui/rich-variable-input/`

Editor TipTap com extensão `mention` configurada para variáveis `{{...}}`. Ao digitar o gatilho, abre um dropdown Tippy (tema `suggestion`) com a lista de variáveis; ao escolher, insere um **chip** não editável.

| Chip | Aparência |
|---|---|
| `.variable-chip` | Azul — variável de sistema. |
| `.variable-chip-custom` | Teal — campo personalizado do cliente. |

Estilos em `src/index.css`. O placeholder vem de `data-placeholder` via `::before` no primeiro parágrafo vazio.

Esse componente aparece em: editor de passo de régua, template de mensagem, composição de disparo, prompt de agente de IA.

---

## 10. Table

`src/components/ui/table.tsx`

Primitivo semântico simples: `Table` (`w-full caption-bottom text-sm`), `TableHeader` (`[&_tr]:border-b`), `TableBody`, `TableFooter` (`border-t bg-muted/50 font-medium`), `TableRow`, `TableHead`, `TableCell`, `TableCaption`.

**Não** traz ordenação, seleção, paginação nem virtualização — isso é responsabilidade de cada tela, usando **TanStack Table 8** e, nas listas grandes, **TanStack Virtual 3**.

**Consequência:** cada tela implementou seu próprio cabeçalho ordenável, sua própria paginação e seu próprio estado vazio. É por isso que a Carteira, Ações e Campanhas têm tabelas visualmente diferentes.

> **Segunda maior dívida do design system.** O redesenho deveria entregar um `DataTable` único com: cabeçalho ordenável, seleção com checkbox e barra de ações em massa, seletor de colunas, densidade, paginação, estado vazio, estado de erro e overlay de "atualizando" sobre dados antigos.

---

## 11. Tabs

`src/components/ui/tabs.tsx`

`TabsList`: `inline-flex h-10 items-center justify-center rounded-md bg-muted p-1 text-muted-foreground`.
`TabsTrigger`: `rounded-sm px-3 py-1.5 text-sm font-medium`; ativo → `bg-background text-foreground shadow-sm`.
`TabsContent`: `mt-2`.

Padrão "pílula sobre trilho cinza". Em mobile, o CSS global torna o `[role="tablist"]` rolável horizontalmente com scrollbar escondida.

⚠️ Telas com muitas abas (Configurações tem ~15) ficam com rolagem horizontal pouco descobrível. O redesenho deveria considerar navegação lateral para esses casos.

---

## 12. Alert

`src/components/ui/alert.tsx`

`relative w-full rounded-lg border p-4`, com posicionamento automático de ícone (`[&>svg]:absolute [&>svg]:left-4 [&>svg]:top-4`) e recuo do conteúdo (`[&>svg~*]:pl-7`).

Variantes: `default` e `destructive` apenas.

⚠️ Mesma lacuna do Badge: **faltam `warning`, `success` e `info`**, que o produto usa constantemente para avisos de campanha, limites e lacunas de métrica. As telas improvisam com classes soltas.

---

## 13. Input, Textarea, Label, Form

- `Input`: `h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm`, com `placeholder:text-muted-foreground`, anel de foco e estilo de `file:`.
- `Textarea`: equivalente, multilinha.
- `Label`: Radix Label.
- `Form`: integração com react-hook-form — `FormItem`, `FormLabel`, `FormControl`, `FormDescription`, `FormMessage` (mensagem de erro em `text-destructive`).

**Padrão de erro de campo:** mensagem abaixo do campo, em vermelho, via `FormMessage`. Validação por zod.

⚠️ Nem todas as telas usam `Form` — muitas manipulam estado manualmente e mostram erro por toast. **Inconsistência a resolver no redesenho.**

---

## 14. Componentes especializados

| Componente | O que faz |
|---|---|
| `sql-editor.tsx` | CodeMirror com `@codemirror/lang-sql` — usado na configuração de fonte de dados e em consultas. |
| `variable-preview.tsx` | Mostra a variável `{{x}}` ao lado do valor resolvido para o registro de exemplo. |
| `mobile-collapsible-filters.tsx` | Envolve a barra de filtros e a recolhe em telas pequenas. |
| `calendar.tsx` | `react-day-picker` — seleção de data e intervalo (filtros de período). |
| `command.tsx` | cmdk — base de comboboxes de campo, de valor, de contato, de template. |
| `loading-states.tsx` | Catálogo de esqueletos (20 KB). Detalhado no doc 22. |
| `skeleton.tsx` | `animate-pulse rounded-md bg-muted`. |

---

## 15. Padrão de composição de combobox

O produto repete um mesmo padrão em pelo menos 8 lugares (`FieldCombobox`, `ValueCombobox`, `TargetFieldCombobox`, `BlocklistContactCombobox`, `BlocklistTargetCombobox`, `FilterMultiSelect`, `PortfolioMultiSelect`, `WorkflowMultiSelect`):

```
Popover
 └ PopoverTrigger → Button variant="outline" com valor atual + ChevronsUpDown
 └ PopoverContent
    └ Command
       ├ CommandInput   (busca)
       ├ CommandEmpty   ("Nenhum resultado")
       └ CommandList → CommandGroup → CommandItem (com Check no selecionado)
```

Existem **múltiplas cópias** desse padrão em pastas diferentes (`src/components/etl/FieldCombobox.tsx`, `src/components/filters/filter-builder/FieldCombobox.tsx`, `src/components/etl/wizards/PipelineWizard/components/FieldCombobox.tsx`). São implementações distintas do mesmo conceito.

> **Terceira dívida.** O redesenho deveria consolidar em um único `Combobox` parametrizável (single/multi, com ícone, com cor, com agrupamento, com criação de item novo).

---

## 16. Resumo das dívidas do design system

| # | Dívida | Impacto | Correção proposta no redesenho |
|---|---|---|---|
| 1 | Badge sem variantes semânticas | Cores de status divergem entre telas | Badge com `success/warning/info/destructive/neutral` × `solid/soft` |
| 2 | Sem `DataTable` compartilhado | Tabelas visualmente diferentes; estados vazios/erro improvisados | Um `DataTable` com seleção, colunas, paginação, densidade e estados |
| 3 | Combobox duplicado em 8 lugares | Comportamento e visual divergentes | Um `Combobox` parametrizável |
| 4 | Alert sem `warning`/`success`/`info` | Avisos improvisados com classes soltas | Completar variantes |
| 5 | Button sem estado `loading` | Cada tela inventa o seu | Prop `loading` no Button |
| 6 | Duas bibliotecas de gráfico (Recharts + Chart.js) | Gráficos com linguagem visual diferente | Escolher uma; tema único de gráfico |
| 7 | Sheet com largura única estreita | Sobrescrito caso a caso | Tamanhos nomeados |
| 8 | Dois mecanismos de troca de visualização | Inconsistência | Um `ViewToggle` extensível |
| 9 | Validação ora por `Form`, ora por toast | Usuário não sabe onde procurar o erro | Padrão único: erro no campo + resumo no topo |
| 10 | `Header.tsx` morto | Confusão de manutenção | Remover |
