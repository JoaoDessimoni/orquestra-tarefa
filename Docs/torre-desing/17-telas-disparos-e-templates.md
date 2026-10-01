# 17 · Telas de Disparos e Templates de Mensagem

> Documento de análise de UX/produto do **frontend ATUAL** da Torre de Controle (SaaS multi-tenant de cobrança da Finza).
> Objetivo: permitir um **redesenho completo da interface sem perder nenhuma funcionalidade**.
> Tudo aqui foi extraído da leitura do código-fonte em `cobranca-finza/src/`. Onde o código não é conclusivo, há uma marca `⚠️ A confirmar:`.
> Data da leitura: 2026-09-17.

**Escopo deste documento — duas telas:**

| Tela | Rota | Arquivo raiz |
|---|---|---|
| Disparos (envio pontual em massa) | `/disparos` | `src/pages/DisparosPage.tsx` |
| Templates de Mensagem | `/templates` | `src/pages/MessageTemplatesPage.tsx` |

---

# PARTE A — DISPAROS

## A0. Identidade

**Fonte:** `src/pages/DisparosPage.tsx`

| Atributo | Valor no código |
|---|---|
| Rota | `/disparos` |
| Título (H1) | `Disparos` |
| Ícone do H1 | `Send` (lucide-react), `h-5 w-5` no mobile / `h-6 w-6` a partir de `sm` |
| Subtítulo | "Envie uma ação (mensagem, e-mail, negativação, etc.) para uma lista de contatos de uma só vez" — `text-muted-foreground text-sm`, **oculto abaixo de `sm`** (`hidden sm:block`) |
| Componente exportado | `export default function DisparosPage()` |
| Permissão de acesso | `disparos:write` (owner, admin, manager, operator). Viewer não vê a tela. Fonte declarada: `src/pages/central-docs/negocio/data/disparos.ts` → `permissions: ["owner","admin","manager","operator"]` |
| Permissão extra | `disparos:override_blocklist` (owner/admin) — libera o toggle "Respeitar blocklist" |
| Origem histórica | Cards IAF-4893 / IAF-4953 (Fase 1), Entrega 2 (fatias 2 e 3), cards internos 7136 e 7137 |

**Badge no cabeçalho:** quando há ao menos um contato selecionado **e** o lote ainda não foi criado (`batchId === null`), aparece à direita do H1 um `Badge variant="secondary"` com o texto `{n} selecionado(s)` (número formatado `pt-BR`).

**Estrutura de abas (`Tabs`, default `new`):**

| Valor | Rótulo do gatilho | Conteúdo |
|---|---|---|
| `new` | `Novo disparo` | Fluxo de 3 cards **ou** o card "Acompanhamento do lote" (após disparar) |
| `history` | `Histórico` | `DisparoHistoryTab` |

---

## A1. Objetivo e personas

### A1.1 O problema que a tela resolve

A Torre tem dois motores de cobrança:

1. **Campanhas/réguas** (automáticas): decidem *quem* cobrar e *quando*, pelo Pipeline v2.
2. **Disparos** (esta tela, manual e imediato): o operador escolhe ele mesmo uma lista de contatos e manda **a mesma ação** para todos de uma vez, sem criar régua nenhuma.

Citação do guia do próprio app (`src/pages/central-docs/negocio/data/disparos.ts`, seção `visao-geral`):

> "As campanhas e réguas decidem QUEM cobrar e QUANDO, de forma automática. Os Disparos são o caminho MANUAL e imediato: você mesmo escolhe uma lista de contatos e manda uma ação para todos de uma vez — um lembrete pontual, um comunicado, uma leva de negativações — sem precisar criar uma régua."

### A1.2 Personas

| Persona | Papel na tela | Poderes |
|---|---|---|
| **Operador de cobrança** | Monta o lote do dia (planilha colada, filtro de carteira), escreve o texto, confere na prévia, dispara | Tudo, menos o override de blocklist |
| **Gerente/Supervisor de cobrança** | Mesma coisa, com foco em lotes grandes (negativação em massa) e em auditar o histórico | Tudo, menos o override |
| **Owner / Administrador** | Autoriza o envio excepcional para contato bloqueado | + toggle "Respeitar blocklist" (`disparos:override_blocklist`) |
| **Auditor** (papel implícito) | Abre a aba Histórico, expande a entrada, lê payload/retorno redigidos, baixa JSON/CSV | Leitura |

### A1.3 Modelo mental que a tela impõe

- A ordem dos cards **não é uma trava**: a lista de alvos funciona sem o tipo de ação escolhido. Só aparece um aviso discreto.
- O **grão** (1 ação por contato x 1 ação por contrato) é determinado pelo *tipo de ação*, e por isso o tipo de ação vem **antes** da lista (inversão deliberada feita na Entrega 2, fatia 3).
- Preview e envio operam sobre **os mesmos alvos congelados** — invariante central da tela.
- O envio é **assíncrono**: a tela só cria ações `Pendente`; quem envia é o cron `scheduled-action-processor`.
- O disparo **não tem deduplicação** — nem cooldown, nem mesmo-passo, nem cross-campaign. A única trava real é a blocklist.

---

## A2. Anatomia visual

**Fonte:** `src/pages/DisparosPage.tsx` (linhas 298–503)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ [Send] Disparos                                        [Badge: N selecionado(s)] │
│ Envie uma ação (mensagem, e-mail, negativação, etc.) para uma lista de …      │
├─────────────────────────────────────────────────────────────────────────────┤
│ ( Novo disparo ) ( Histórico )                        ← TabsList             │
└─────────────────────────────────────────────────────────────────────────────┘

ABA "Novo disparo", estado PRÉ-DISPARO (batchId === null):

  ┌ Card ────────────────────────────────────────────────────────────────────┐
  │ 1. Configurar a ação                                                     │
  │ ────────────────────────────────────────────────────────────────────────  │
  │  [Label] Tipo de Ação      → Select (badge colorido + rótulo)            │
  │  [Label] Integração        → Select (só se >1 integração ativa no tipo)  │
  └──────────────────────────────────────────────────────────────────────────┘

  ┌ Card ────────────────────────────────────────────────────────────────────┐
  │ 2. Selecionar alvos                                                      │
  │ ────────────────────────────────────────────────────────────────────────  │
  │  (aviso discreto se não há tipo de ação escolhido)                       │
  │  ┌ PortfolioFiltersBar: busca · Carteiras · Filtros · Réguas · lógicas ┐ │
  │  ┌ Collapsible: "Colar documentos (CPF/CNPJ — um por linha)"          ┐ │
  │  ┌ Collapsible: "Colar contratos (número — um por linha)"             ┐ │
  │  (aviso de interseção vazia entre as duas listas coladas)                │
  │  N contato(s) no filtro atual   [Selecionar todos os N]                  │
  │                         [Users] N selecionado(s) no total  [Limpar seleção] │
  │  ┌ Card > Table (sticky header) ───────────────────────────────────────┐ │
  │  │ [☐] [▸] Nome | Documento | Telefone | E-mail | Valor Devido | …    │ │
  │  │  …linhas, com linha expandida de contratos cobráveis…              │ │
  │  └─────────────────────────────────────────────────────────────────────┘ │
  │  ┌ PortfolioFooter: paginação + page size ─────────────────────────────┐ │
  └──────────────────────────────────────────────────────────────────────────┘

  ┌ Card ────────────────────────────────────────────────────────────────────┐
  │ 3. Conteúdo                                                              │
  │ ────────────────────────────────────────────────────────────────────────  │
  │  [Switch] Respeitar blocklist  (+ alerta destrutivo se desligado)        │
  │  [Popover] Template Meta (opcional) — só WhatsApp                        │
  │  [TemplateHSMSelector] Template RCS (opcional) — só RCS                  │
  │  [Input] Assunto — só e-mail                                             │
  │  [RichVariableInput] Conteúdo (+ hint vermelho se vazio)                 │
  │  ─── Separator ───                                                       │
  │  ┌ DisparoPreviewNavigator (só após clicar Pré-visualizar) ───────────┐  │
  │  │ [Eye] Prévia  ‹ i de N ›              [Próximo com problema]      │  │
  │  │ Nome do contato · documento · Contrato X   [Badge: Pronto/Não]    │  │
  │  │ Destinatário | Canal                                              │  │
  │  │ MessagePreview (mock do canal)                                    │  │
  │  │ Alerta "Este contato não seria enviado — <motivo>"                │  │
  │  │ Lista de warnings                                                 │  │
  │  │ Collapsible "Ver dados enviados à integração"                     │  │
  │  └───────────────────────────────────────────────────────────────────┘  │
  │  ─── Separator ───                                                       │
  │  Alertas: overLimit · targetOverLimit · resumo · zero alvos · duplicidade │
  │  Hint de bloqueio          [Pré-visualizar]  [Disparar N ações]          │
  └──────────────────────────────────────────────────────────────────────────┘

ABA "Novo disparo", estado PÓS-DISPARO (batchId !== null):

  ┌ Card ────────────────────────────────────────────────────────────────────┐
  │ Acompanhamento do lote                        [RotateCcw] Novo disparo   │
  │ ────────────────────────────────────────────────────────────────────────  │
  │  4 StatChips: Enviado · Falhou · Duplicado · Pendente/Processando        │
  │                              [Baixar JSON]  [Baixar CSV]                 │
  │  Tabela: [▸] Contato | Contrato | Status | Destinatário | Erro           │
  └──────────────────────────────────────────────────────────────────────────┘
```

### A2.1 Espaçamentos e grid declarados

| Elemento | Classe |
|---|---|
| Raiz da página | `space-y-6` |
| Cabeçalho | `flex items-center justify-between gap-3` |
| H1 | `text-xl sm:text-2xl font-bold flex items-center gap-2` |
| Tabs | `space-y-4` |
| `TabsContent value="new"` | `space-y-4` |
| Container dos 3 cards | `space-y-4` |
| `CardTitle` de cada card | `text-base` |
| `CardContent` do card 3 | `space-y-4` |
| Barra de botões final | `flex flex-col-reverse gap-3 sm:flex-row sm:items-center sm:justify-between` |
| Grupo dos 2 botões | `flex flex-col-reverse gap-2 sm:flex-row` |
| Chips do acompanhamento | `grid grid-cols-2 gap-2 sm:grid-cols-4` |

> `flex-col-reverse` no mobile significa que, em tela estreita, **os botões aparecem acima do texto de hint** e **"Disparar" aparece acima de "Pré-visualizar"** — a ação primária fica no topo da pilha.

---

## A3. Escolha do público (todas as formas, controles, validações)

**Fonte principal:** `src/components/disparos/DisparoTargetList.tsx` (≈45 KB — o coração da tela), com apoio de `src/hooks/useDisparos.ts` e `src/hooks/usePortfolioManagement.ts`.

Existem **cinco caminhos** para montar o público, e eles se **combinam**:

| # | Caminho | Controle | Efeito |
|---|---|---|---|
| 1 | Filtros de Carteira | `PortfolioFiltersBar` (busca, Carteiras, Filtros salvos, Réguas, lógicas E/OU) | Restringe a **lista exibida** |
| 2 | Colar documentos (CPF/CNPJ) | Collapsible "Colar documentos" | Restringe a **lista exibida** (filtro por `contactIds`) |
| 3 | Colar contratos (números) | Collapsible "Colar contratos" | Restringe a lista **E** faz merge na seleção (marca exatamente aqueles contratos) |
| 4 | Seleção manual | Checkbox por linha + checkbox do cabeçalho (página) | Define a **seleção** |
| 5 | Selecionar todos do filtro | Botão `Selecionar todos os N` | Materializa **todos** os ids do filtro atual na seleção |

E ainda, dentro de (4), a **escolha de contratos por contato** (linha expansível).

### A3.1 Estado inicial dos filtros

`INITIAL_FILTERS` (`DisparoTargetList.tsx`, l. 73–87):

| Campo | Valor inicial | Observação |
|---|---|---|
| `search` | `""` | Busca textual |
| `portfolioIds` | `[]` | Carteiras selecionadas |
| `filterIds` | `[]` | Filtros salvos |
| `portfoliosLogic` | `"or"` | Combinador entre carteiras |
| `filtersLogic` | `"and"` | Combinador entre filtros |
| `workflowIds` | `[]` | Réguas |
| `workflowsLogic` | `"or"` | Combinador entre réguas |
| `includeNoWorkflow` | `false` | "Incluir sem régua" |
| `page` | `1` | |
| `pageSize` | `50` | |
| `orderBy` | `"max_days_overdue"` | **Mesmo default da Gestão de Carteira** (`p_order_by` da RPC `get_kanban_data`) |
| `orderDirection` | `"desc"` | |

Todo controle de filtro **volta para a página 1** ao mudar (`page: 1` em todos os handlers), inclusive a ordenação.

### A3.2 Caminho 1 — `PortfolioFiltersBar`

Reusa **100%** a barra de filtros da Gestão de Carteira, com uma única diferença: `showColumnToggle={false}` (o Disparo **não tem** customização de colunas).

Props passadas (`DisparoTargetList.tsx`, l. 544–562):

| Prop | Handler | Comportamento |
|---|---|---|
| `search` / `onSearchChange` | `handleSearchChange` | Busca textual; segundo o guia do app, "a busca também casa número de contrato" |
| `portfolioIds` / `onPortfoliosChange` | `handlePortfoliosChange` | Multi-seleção de carteiras |
| `portfoliosLogic` / `onPortfoliosLogicChange` | `handlePortfoliosLogicChange` | `or` (default) ou `and` |
| `filterIds` / `onFiltersChange` | `handleFiltersChange` | Multi-seleção de filtros salvos |
| `filtersLogic` / `onFiltersLogicChange` | `handleFiltersLogicChange` | `and` (default) ou `or` |
| `workflowIds` / `onWorkflowsChange` | `handleWorkflowsChange` | Multi-seleção de réguas |
| `workflowsLogic` / `onWorkflowsLogicChange` | `handleWorkflowsLogicChange` | `or` (default) |
| `includeNoWorkflow` / `onIncludeNoWorkflowChange` | `handleIncludeNoWorkflowChange` | Booleano |

⚠️ A confirmar: o layout interno exato do `PortfolioFiltersBar` (chips, popovers, ordem dos controles) não foi lido neste documento — pertence ao domínio da tela de Carteira.

### A3.3 Caminho 2 — "Colar documentos (CPF/CNPJ — um por linha)"

**Componente:** `Collapsible` → `Card` → `CardHeader` clicável (`cursor-pointer py-3 hover:bg-muted/50`).

| Elemento | Detalhe |
|---|---|
| Ícone do título | `ClipboardPaste` (`h-4 w-4 text-muted-foreground`) |
| Título | `Colar documentos (CPF/CNPJ — um por linha)` |
| Badge condicional | `{n} contato(s) aplicado(s)` — aparece quando `documentContactIds.length > 0` |
| Chevron | `ChevronDown` que rotaciona 180° quando aberto |
| Campo | `Textarea`, `rows={4}`, `font-mono text-sm` |
| Placeholder | `Um CPF/CNPJ por linha (vírgula ou ponto-e-vírgula também funcionam)` + nova linha + `Ex: 123.456.789-01` |
| Botão primário | `Aplicar` (`size="sm"`) — desabilitado se o texto estiver vazio ou enquanto `resolveDocuments.isPending`; rótulo vira `Resolvendo...` durante a mutação |
| Botão secundário | `Limpar` (`variant="ghost"`) — só aparece se há filtro ativo, texto digitado ou resultado anterior |

**Resolução (`useResolveDocuments`, `useDisparos.ts` l. 70–104):**

1. `parsePastedDocuments(rawText)` normaliza (de `@/lib/paste-list`) — aceita quebra de linha, vírgula e ponto-e-vírgula; normaliza para **só dígitos**.
2. Consulta `contacts` via `orgClient`, em **chunks de 400** (`DOCUMENTS_IN_CHUNK_SIZE`; documento tem no máximo 14 dígitos, então cabe mais que o chunk padrão de 200 UUIDs).
3. Devolve `{ contactIds, notFound }`.

**Painel de resultado** (borda tracejada, `rounded-md border border-dashed p-3 text-sm`):

| Linha | Condição | Texto/estilo |
|---|---|---|
| Resumo | sempre após sucesso | `{n} encontrado(s) · {m} não encontrado(s)` (`font-medium`) |
| Aviso de zero | `contactIds.length === 0` | `Nenhum contato encontrado — o filtro não foi aplicado (a lista segue sem essa restrição).` — `text-destructive` |
| Lista de não encontrados | `notFound.length > 0` | `Não encontrados: {lista separada por vírgula}` — `text-amber-600 dark:text-amber-400 break-all` |
| Erro | `isError` | `Erro ao resolver documentos: {mensagem}` — `text-sm text-destructive` |

**Regra de segurança de UX (crítica para o redesign):** *0 documentos resolvidos NÃO restringe a lista*. O código comenta o motivo: "evita esconder a lista inteira por engano". O aviso deixa isso explícito.

**Limpar** (`handleClearPastedDocuments`) zera **só** a metade de documentos: texto, `reset()` da mutação, `documentContactIds = null`, volta para a página 1. O filtro de contratos continua valendo.

### A3.4 Caminho 3 — "Colar contratos (número — um por linha)"

Bloco **irmão** do anterior, mas com efeito duplo.

| Elemento | Detalhe |
|---|---|
| Ícone do título | `FileText` |
| Título | `Colar contratos (número — um por linha)` |
| Badge condicional | `{n} contrato(s) aplicado(s)` — conta **contratos** (é o que o usuário colou), não contatos |
| Campo | `Textarea`, `rows={4}`, `font-mono text-sm` |
| Placeholder | `Um número de contrato por linha (vírgula ou ponto-e-vírgula também funcionam)` + `Ex: CTR-001` |
| Texto explicativo (varia pelo grão) | ver tabela abaixo |
| Botões | `Aplicar` / `Resolvendo...` e `Limpar` (mesmas regras do bloco de documentos) |

**Texto explicativo condicional (`isContractGrain`):**

| Grão | Texto exibido |
|---|---|
| Contrato-grão (negativação/notificação) | "Filtra a lista pelos contatos donos desses contratos e marca EXATAMENTE esses contratos em cada um — os demais contratos ficam desmarcados." |
| Contato-grão (comunicação) | "O tipo de ação escolhido cria 1 ação por contato — aqui os contratos servem para localizar e selecionar os contatos donos. A escolha fica guardada e passa a valer se você trocar para um tipo que cria 1 ação por contrato (negativação/notificação)." |

**Resolução (`useResolveContracts`, `useDisparos.ts` l. 382–433):**

1. `parsePastedContractNumbers(rawText)`.
2. Consulta `contracts` (`id, contract_number, contact_id`) via `orgClient`, em **chunks de 200** (`CONTRACTS_IN_CHUNK_SIZE` — `contract_number` é texto livre, maior que um CNPJ).
3. Classifica cada número em **três** baldes:
   - `pairs`: `{contactId, contractId, contractNumber}` — existe e tem dono.
   - `withoutContact`: **existe** mas `contact_id` é nulo (não vira alvo).
   - `notFound`: não existe.

**Painel de resultado — três estados de aviso:**

| Situação | Texto | Estilo |
|---|---|---|
| Resumo | `{n} contrato(s) encontrado(s) · {m} não encontrado(s)` (+ ` · {k} sem contato dono` quando aplicável) | `font-medium` |
| 0 pares **e já havia filtro aplicado** | "Nada a aplicar — a lista de contratos aplicada antes continua valendo (veja o contador no título do bloco). Use \"Limpar\" para removê-la." | âmbar |
| 0 pares **e sem filtro aplicado** | "Nenhum contrato utilizável — o filtro não foi aplicado (a lista segue sem essa restrição)." | `text-destructive` |
| `notFound.length > 0` | `Não encontrados: {lista}` | âmbar, `break-all` |
| `withoutContact.length > 0` | `Existem, mas não têm contato vinculado (não viram alvo): {lista}` | âmbar, `break-all` |
| Erro | `Erro ao resolver contratos: {mensagem}` | `text-destructive` |

**Efeito duplo ao aplicar (`handleApplyPastedContracts`):**

1. `setContractFilter({ contactIds: únicos, contractCount: pairs.length })` → filtra a lista.
2. `setSelection(prev => mergePastedContractsIntoSelection(prev, pairs))` → **MERGE** na seleção: sobrescreve a entrada de cada contato colado com **exatamente** os contratos colados; contatos fora da colagem são **preservados**.

**Decisão de produto documentada no código** (`mergePastedContractsIntoSelection`, l. 452 e comentário em `handleApplyPastedContracts`, l. 379–390): os arrays de contrato são gravados **sempre**, mesmo quando o grão vigente é contato-grão. O motivo é um bug real: antes, colar contratos antes de escolher "Notificação" gravava `null` ("todos os contratos") e o lote saía com **todos** os contratos cobráveis — dezenas de notificações extrajudiciais a mais.

**Limpar** (`handleClearPastedContracts`) zera só a metade de contratos e **NÃO desfaz a seleção já feita** (o usuário pode ter continuado a montar o lote manualmente).

### A3.5 Combinação dos dois blocos de colagem

`combineContactIdFilters(documentContactIds, contractContactIds)` (`useDisparos.ts` l. 500–519) produz `{ contactIds, emptyIntersection }`:

| Caso | Resultado |
|---|---|
| Nenhum ativo (`null` ou array vazio) | `contactIds: undefined` (sem restrição) |
| Só documentos ativo | vale a lista de documentos |
| Só contratos ativo | vale a lista de contratos |
| Os dois ativos | **INTERSEÇÃO** |
| Interseção vazia | `contactIds: undefined` + `emptyIntersection: true` |

**Aviso de interseção vazia** (renderizado entre os blocos e a lista, `px-1 text-sm text-destructive`):

> "Nenhum contato aparece nas duas listas coladas ao mesmo tempo (documentos e contratos) — nenhum dos dois filtros foi aplicado. Limpe um dos blocos para usar o outro isoladamente."

**Por que dois estados separados** (comentário l. 280–284): antes os dois blocos escreviam no **mesmo** `filters.contactIds`; o badge de um aparecia no outro e o "Limpar" de um apagava o filtro do outro — a lista voltava à população inteira sem o usuário pedir, "engordando o lote".

### A3.6 Caminho 4 — seleção manual

**Estrutura de dados:** `Map<contactId, string[] | null>`.

| Valor da entrada | Significado |
|---|---|
| ausente (`undefined`) | Contato **não selecionado** |
| `null` | Selecionado, **todos** os contratos cobráveis |
| `string[]` | Selecionado, **apenas** os contratos listados |

A seleção **PERSISTE entre páginas e trocas de filtro** — o usuário monta o lote incrementalmente.

**Checkbox da linha (`toggleRow`):** alterna presença no Map. Ao marcar, entra como `null` ("todos").

**Estado visual do checkbox da linha** (`DisparoTargetList.tsx`, l. 857–862):

```
entry === undefined                       → false (desmarcado)
entry === null  OU  !isContractGrain      → true  (marcado)
entry é array  E  isContractGrain         → "indeterminate" (parcial)
```

> Nota de design registrada no código: em contato-grão um array guardado **não pode** pintar a linha como "parcial" — "seria mentira e convidaria o clique que DESmarca o contato".

**Checkbox do cabeçalho (`toggleSelectAllPage`):** opera **só sobre a página atual** (`pageContactIds`).

| Estado | Condição |
|---|---|
| `true` | `allPageSelected` — todos os ids da página estão no Map |
| `"indeterminate"` | `somePageSelected` — alguns |
| `false` | nenhum |

`aria-label`: `Selecionar todos os contatos desta página`.

**Limpar seleção:** botão `variant="ghost" size="sm" className="h-7"` com ícone `X`, rótulo `Limpar seleção`. Só aparece quando `selection.size > 0`. Zera o Map inteiro.

### A3.7 Caminho 5 — "Selecionar todos os N" (card 7137)

| Atributo | Valor |
|---|---|
| Posição | Ao lado do contador "N contato(s) no filtro atual", **acima** da tabela |
| Componente | `Button variant="outline" size="sm" className="h-7"` |
| Ícone | `CheckCheck` (`h-3.5 w-3.5`) |
| Rótulo | `Selecionar todos os {total}` — **o número vai no rótulo**, para o usuário saber o tamanho do que pede antes de clicar |
| Estado pendente | `Loader2` girando + `Selecionando...`, botão desabilitado |
| Condição de exibição | `total > 0` |

**Resolução (`useResolveAllContactIds`, `useDisparos.ts` l. 677–711):**

- Chama a RPC `public.get_portfolio_contact_ids` — a **mesma** do "Toda a Base" do export da Carteira — pelo client **BASE** `supabase` com `p_schema_name` (nunca via `orgClient`).
- Parâmetros derivados dos helpers canônicos `buildMultiFilterRpcParams`, `buildWorkflowFilterRpcParams`, `portfolioCombinatorForPayload`, `filterCombinatorForPayload`.
- **Interseção obrigatória** com as listas coladas via `applyPastedIntersection`. O comentário do código nomeia a armadilha: `get_portfolio_contact_ids` é a **única** das três RPCs da Carteira que **não aceita** `p_contact_ids` — sem a interseção manual, "colei 600 documentos + selecionar todos" renderizaria os 6.867 do filtro, "engordando o lote em SILÊNCIO".

**Comportamentos-limite:**

| Situação | O que acontece |
|---|---|
| RPC devolve 0 ids | Toast **não destrutivo**: título `Nenhum contato para selecionar`, descrição `O filtro atual não retornou contatos.` — **não** cai para "toda a base" nem limpa o que já estava marcado |
| Erro | Toast `variant="destructive"`, título `Falha ao selecionar todos`, descrição = mensagem do erro |
| Contato já selecionado com escolha de contratos | **Preservado** (`if (!next.has(id)) next.set(id, null)`) — o botão só **acrescenta** |

**Decisão de arquitetura visível na UI:** os ids são **materializados** no Map (não existe um modo virtual "todos + exceções"). O comentário mede o custo: 7.279 ids em `org_blips` custam ~1 MB.

### A3.8 Escolha de contratos por contato (linha expansível)

**Gatilho:** botão `ghost size="icon" h-7 w-7` na segunda coluna, **só quando `contact.total_contracts >= 2`**.

| Estado | Ícone | `aria-label` |
|---|---|---|
| Fechado | `ChevronRight` | `Ver contratos de {nome ou documento}` |
| Aberto | `ChevronDown` | `Ocultar contratos de {nome ou documento}` |

`aria-expanded` acompanha o estado. **Um por vez**: `expandedId` guarda um único id — abrir outro fecha o anterior ("evita N queries de contratos simultâneas").

**Conteúdo da linha expandida (`ContactContractsRow`)** — `TableRow className="bg-muted/20 hover:bg-muted/20"`, `colSpan = TARGET_COLUMNS.length + 2`:

| Estado | Render |
|---|---|
| Carregando | 3 `Skeleton` (`h-4 w-48`, `h-4 w-full`, `h-4 w-2/3`) |
| Erro | `Erro ao carregar contratos: {mensagem}` (`text-destructive`) + botão `Tentar novamente` |
| Vazio | `Nenhum contrato cobrável — este contato não vira alvo.` |
| Sucesso | Cabeçalho `{n} contrato(s) cobrável(is)` + uma `<label>` por contrato com `Checkbox` + número do contrato (ou os 8 primeiros chars do id quando não há número) |
| Sucesso **e** `!isContractGrain` | + rodapé: "O tipo de ação escolhido cria 1 ação por contato — a escolha de contrato não se aplica agora, mas fica guardada se você trocar para negativação/notificação." |

**Armadilha de UX documentada no código** (`ContactContractsRow`, comentário l. 951–958): `total_contracts` conta **TODOS** os contratos, não só os cobráveis. Logo o expansor pode aparecer com "2+" e abrir mostrando **0 ou 1** item.

**Lógica do toggle de contrato (`toggleContract`, l. 501–533):**

| Estado atual da entrada | Ação | Novo estado |
|---|---|---|
| `undefined` (contato não selecionado) | marcar um contrato | contato entra selecionado **só com aquele contrato** |
| `null` ("todos") | desmarcar um | materializa a lista completa **menos** o desmarcado |
| array contendo o id | desmarcar | remove do array; **se ficar vazio, o contato sai da seleção** |
| array sem o id | marcar | adiciona ao array (não "colapsa" de volta para `null`, mesmo quando o array fica completo) |

**Fonte dos contratos (`useContactBillableContracts`, `useDisparos.ts` l. 551–609):**

- Reusa a **mesma RPC** que resolve os alvos do lote: `public.get_max_overdue_title_per_contract`, com um único `contact_id`. Decisão explícita — "o gate de cobrável fica em UM lugar só", evitando "a lista oferecendo um contrato que NÃO vira alvo, ou escondendo um que viraria".
- É **lazy** (só ao expandir), cacheada por `["disparo-contact-contracts", orgSlug, contactId]` com `staleTime` de 5 min — recolher e reexpandir **não** refaz rede.
- Rótulos (`contract_number`) vêm de um lookup por PK em `contracts`.
- Ordenação: por `contractNumber` (`localeCompare`), com nulos por último.
- **Não traz `pending_value`** de propósito: a coluna existe mas o trigger que a mantém compara `status != 'paid'` (lowercase legado) — "dinheiro errado na tela é pior que dinheiro nenhum".
- Linhas sem `contract_id` são **descartadas** aqui (não são representáveis na UI), mas **mantidas** pelo filtro de alvos (ver A4.6).

### A3.9 Contadores do público

Linha acima da tabela (`flex flex-wrap items-center justify-between gap-2 px-1`):

| Lado | Conteúdo |
|---|---|
| Esquerda | `{total} contato(s) no filtro atual` + sufixo ` · atualizando...` quando `isFetching && !isLoading`. Se `total === 0`, o texto não é renderizado. |
| Esquerda (cont.) | Botão `Selecionar todos os {total}` |
| Direita | Ícone `Users` + `{selection.size} selecionado(s) no total` (`text-sm font-medium`) |
| Direita (cont.) | Botão `Limpar seleção` |

### A3.10 Validações e regras de proteção do público (resumo)

| # | Regra | Motivo declarado no código |
|---|---|---|
| V1 | 0 documentos resolvidos ⇒ **não** aplica filtro | Evitar esconder a lista inteira por engano |
| V2 | 0 contratos resolvidos ⇒ **não** aplica filtro (e não apaga o filtro anterior) | Mesma razão; e dizer "a lista segue sem restrição" seria mentira se já houvesse filtro |
| V3 | Interseção vazia entre as duas colagens ⇒ **nenhum** filtro aplicado + aviso vermelho | Sem o aviso, "a lista pareceria ter voltado ao normal sozinha" |
| V4 | "Selecionar todos" intersecta com as listas coladas | Nunca ampliar o lote além do que foi colado |
| V5 | "Selecionar todos" com 0 resultados ⇒ toast informativo, nada muda | Não cair para "toda a base" |
| V6 | Desmarcar todos os contratos de um contato ⇒ contato sai da seleção | Não deixar entrada com array vazio |
| V7 | `Limpar` de um bloco de colagem não afeta o outro | Estados separados desde a Entrega 2 |
| V8 | Colagem de contratos faz MERGE (nunca substitui o Map inteiro) | Não apagar trabalho manual |
| V9 | "Selecionar todos" preserva escolha de contratos existente | Não desfazer trabalho manual |

---

## A4. Lista de destinatários (todas as colunas, seleção, contadores, badges, ações)

**Fonte:** `src/components/disparos/DisparoTargetList.tsx`, `src/components/portfolio/types.ts` (metadados canônicos das colunas).

### A4.1 Colunas da tabela de alvos

A tabela é **fixa** — não há seletor de colunas. `TARGET_COLUMNS` (l. 103–111) define 7 colunas de dados, precedidas por 2 colunas de controle.

| Ordem | Coluna | Rótulo exibido | Largura/alinhamento | Ordenável? (`sortField`) | Agregada? | Formato | Fonte do valor |
|---|---|---|---|---|---|---|---|
| 0 | checkbox | — | `w-10` | não | — | — | Estado local de seleção |
| 1 | expansor | — | `w-8` | não | — | — | `contact.total_contracts >= 2` |
| 2 | `name` | **Nome** | esquerda, `font-medium` | sim (`name`) | não | texto | `contact.name` · fallback `-` |
| 3 | `document` | **Documento** | esquerda | sim (`document`) | não | `formatDocument(document, document_type)` | `contact.document` |
| 4 | `primary_phone` | **Telefone** | esquerda | **não** (RPC não ordena) | não | `formatPhone()` | `contact.primary_phone` · fallback `-` |
| 5 | `primary_email` | **E-mail** | esquerda | **não** (RPC não ordena) | não | texto | `contact.primary_email` · fallback `-` |
| 6 | `total_pending_value` | **Valor Devido** | `text-right` | sim (`total_pending_value`) | **sim** | `formatCurrency()` | `contact.total_pending_value` |
| 7 | `total_contracts` | **Contratos** | `text-center` | sim (`total_contracts`) | **sim** | número | `contact.total_contracts` |
| 8 | `overdue_titles` | **Titulos Vencidos** | `text-center` | sim (`overdue_titles`) | **sim** | número | `contact.overdue_titles ?? contact.titles_overdue` |

> Os rótulos e descrições **não são escritos aqui**: vêm de `DEFAULT_COLUMNS` (`src/components/portfolio/types.ts`), fonte única da Gestão de Carteira, "para não haver drift de texto de ajuda".

### A4.2 Textos de ajuda por coluna (`HelpTip`)

Cada cabeçalho com metadados renderiza um ícone de ajuda `?` (`HelpTip`, `side="top" align="start"`), cujo corpo é a `description` da coluna + (quando agregada) a `aggregationNote` da entidade.

| Coluna | Descrição exibida no HelpTip |
|---|---|
| Nome | "Nome do contato (pessoa fisica ou juridica)." |
| Documento | "Documento do contato: CPF (pessoa fisica) ou CNPJ (pessoa juridica)." |
| Telefone | "Telefone principal cadastrado do contato." |
| E-mail | "E-mail principal cadastrado do contato." |
| Valor Devido | "Soma do valor ainda devido (nao pago) dos titulos do contato." + nota de agregação da entidade `title` |
| Contratos | "Quantidade de contratos do contato." + nota de agregação da entidade `contract` |
| Titulos Vencidos | "Quantidade de titulos vencidos (em atraso, nao pagos) do contato." + nota de agregação da entidade `title` |

**Fallback da nota de agregação** (quando a entidade não tem nota própria): `"Valor agregado dos contratos/titulos do contato."`

**Marcador visual de coluna agregada:** ícone `Layers` (`h-3 w-3 text-muted-foreground/70`, `aria-hidden`) ao lado do rótulo.

### A4.3 Cabeçalho ordenável (`TargetColumnHeader`)

Colunas **com** `sortField` renderizam um `<button type="button">` com o rótulo + ícone de estado:

| Estado | Ícone | `aria-sort` |
|---|---|---|
| Ordenado ascendente | `ArrowUp` (`h-3.5 w-3.5`) | `ascending` |
| Ordenado descendente | `ArrowDown` (`h-3.5 w-3.5`) | `descending` |
| Não ordenado | `ArrowUpDown` (`opacity-50`) | `none` |

**`aria-label` dinâmico (texto exato):**

| Estado | `aria-label` |
|---|---|
| asc | `Ordenado por {label} em ordem crescente. Clique para ordenar em ordem decrescente` |
| desc | `Ordenado por {label} em ordem decrescente. Clique para ordenar em ordem crescente` |
| neutro | `Clique para ordenar por {label}` |

**Interação:** clicar alterna asc↔desc (`sorted === "asc" ? "desc" : "asc"`); a ordenação é **server-side** (mesmo `p_order_by` da RPC `get_kanban_data`) e volta para a página 1. **Não mexe na seleção.**

Colunas **sem** `sortField` (Telefone, E-mail) renderizam só rótulo + `HelpTip`, sem botão.

### A4.4 Estados da tabela

| Estado | Render | Componente |
|---|---|---|
| `isLoading` | Skeleton de grade com 8 linhas | `PortfolioGridSkeleton rows={8}` |
| `isError` | Título `Erro ao carregar contatos`, descrição = mensagem do erro, botão de retry | `ErrorState` com `onRetry={refetch}` |
| Lista vazia | Ícone `Users`, título `Nenhum contato encontrado`, descrição `Ajuste os filtros ou a busca para encontrar contatos.` | `EmptyState` |
| Com dados | `Table` com `TableHeader className="sticky top-0 bg-card z-10"` | — |
| Refetch em andamento | Sufixo ` · atualizando...` no contador de total | — |

O `Card` que envolve a tabela: `flex-1 overflow-hidden flex flex-col`, com `CardContent className="p-0 flex-1 overflow-auto"` — ou seja, **scroll interno** com cabeçalho fixo.

### A4.5 Linha selecionada

`<TableRow data-state={checked !== false ? "selected" : undefined}>` — o estilo de "linha selecionada" é o padrão do design system (shadcn `Table`) e cobre também o estado `indeterminate`.

`aria-label` do checkbox da linha: `Selecionar {contact.name || contact.document}`.

### A4.6 Rodapé / paginação

`PortfolioFooter` (mesmo componente da Carteira), renderizado apenas quando `!isLoading && !isError && contacts.length > 0`:

| Prop | Valor |
|---|---|
| `page` | `data?.page ?? filters.page ?? 1` |
| `pageSize` | `data?.pageSize ?? filters.pageSize ?? 50` |
| `totalPages` | `data?.totalPages ?? 0` |
| `totalItems` | `data?.total ?? 0` |
| `onPageChange` | Só muda `page` (não reseta nada) |
| `onPageSizeChange` | Muda `pageSize` **e volta para a página 1** |

### A4.7 Da seleção aos ALVOS (`DispatchTarget`)

Este é o conceito mais importante da tela para o redesign: **selecionar um contato não é o mesmo que criar uma ação**.

```
selection (Map<contactId, contractIds|null>)
   ↓ onSelectionChange → DispatchSelectionEntry[]
   ↓ clique em "Pré-visualizar"
   ↓ RPC por GRÃO:
   │   contato-grão  → public.get_max_overdue_title_per_contact   (1 linha/contato)
   │   contrato-grão → public.get_max_overdue_title_per_contract  (1 linha/contrato cobrável)
   ↓ filterTargetsBySelection(targets, selection, isContractGrain)
   ↓
targets: DispatchTarget[] = { contactId, contractId|null, titleId|null }
   ↓ (CONGELADOS na PreviewSession)
   ├→ prévia (buildPreviewParams)
   └→ envio  (buildDispatchRows)   ← MESMOS alvos
```

**Grão por tipo de ação (`CONTRACT_GRAIN_ACTION_TYPES`, `useDisparos.ts` l. 139):**

| Tipos | Grão | Quantas ações | Título usado |
|---|---|---|---|
| `negativation`, `notification` | **contrato-grão** | 1 por **contrato cobrável** (fan-out) | O de maior atraso **de cada contrato** |
| Todos os demais (`whatsapp`, `email`, `sms`, `rcs`, `voice`, `human_activity`, `webhook`, `block`) | **contato-grão** | 1 por **contato** | O de maior atraso **do contato** |

> `block` **não** está no conjunto de contrato-grão — decisão explícita ("se block não é claramente por-contrato, trate como contato-grão").

**Regras de `filterTargetsBySelection` (l. 260–278) — nesta ordem:**

| # | Regra | Efeito |
|---|---|---|
| 1 | `!isContractGrain` | Devolve `targets` **inalterado** |
| 2 | Contato sem entrada na seleção | **Descarta** todos os alvos dele (defesa: alvo fora da seleção não vaza para o lote) |
| 3 | `contractIds === null` | Mantém (contato marcado como "todos") |
| 4 | `target.contractId === null` | **Mantém sempre** — um alvo assim não aparece na expansão e não poderia ser desmarcado; descartá-lo removeria do lote algo que o usuário nunca viu |
| 5 | Caso geral | Mantém só se `contractIds.includes(target.contractId)` |

> Princípio de segurança declarado: a operação é **INTERSEÇÃO** (só reduz). Nunca constrói um alvo a partir de um `contract_id` vindo do cliente — se fosse união, o cliente poderia injetar um contrato que a RPC não autorizou.

### A4.8 Contadores derivados (pós-preview)

| Variável | Cálculo | Onde aparece |
|---|---|---|
| `selectedContactIds.length` | `selection.length` | Badge do header, alerta de `overLimit`, textos de hint |
| `targetCount` | `previewSession.targets.length` | Rótulo do botão Disparar, alertas de resumo |
| `leftOutCount` | Contatos da sessão **sem nenhum alvo** resolvido | Alerta de resumo |
| `overLimit` | `selectedContactIds.length > 5000` | Alerta destrutivo |
| `targetOverLimit` | `previewSession && targetCount > 5000` | Alerta destrutivo |

`MAX_DISPATCH_CONTACTS = 5000` (`useDisparos.ts` l. 619) — **teto SOFT**: avisa, não bloqueia.

---

## A5. Catálogo de problemas detectados

Os "problemas" da tela de Disparos vivem em **dois níveis**: (a) alertas do **lote** (card 3, acima dos botões) e (b) avisos **por destinatário** (dentro do `DisparoPreviewNavigator`).

### A5.1 Alertas do LOTE (`DisparosPage.tsx`, l. 388–458)

| Código interno | Rótulo exibido (texto exato) | Condição | Variante | Ícone | Bloqueia envio? |
|---|---|---|---|---|---|
| `overLimit` | "Você selecionou **{n}** contatos — acima do recomendado de **5.000** por lote. O disparo ainda é possível, mas pode levar mais tempo para processar." | `selectedContactIds.length > 5000` | `destructive` | `AlertTriangle` | **Não** |
| `targetOverLimit` | "Este lote vai criar **{n}** ações — acima do recomendado de **5.000** por lote. O disparo ainda é possível, mas pode levar mais tempo para processar." | `previewSession && targetCount > 5000` | `destructive` | `AlertTriangle` | **Não** |
| `resumo` | "**{n}** ação será criada / ações serão criadas" + (contrato-grão) " (uma por contrato selecionado de **{m}** contato(s))" + (se houver) " · **{k}** de **{m}** contato(s) ficaram de fora por não ter título cobrável[ nos contratos selecionados]." | `previewSession && targetCount > 0` | default | `Send` | Não (informativo) |
| `zeroAlvos` | "Nenhum dos **{m}** contato(s) selecionado(s) tem título cobrável[ nos contratos selecionados] — não há ação a disparar. Ajuste a seleção." | `previewSession && targetCount === 0` | `destructive` | `AlertTriangle` | **Sim** (`canDispatch` exige `targetCount > 0`) |
| `duplicateWarning` | "**{n}** de **{m}** contatos já têm ação pendente ou enviada nos últimos 3 dias neste canal (**{a}** com ação pendente · **{b}** com ação enviada) — disparar mesmo assim pode gerar contato duplicado." | `recentSummary.flaggedCount >= 1` | default | `AlertTriangle` | **Não** |
| `overrideAtivo` | "Você está forçando o envio ignorando a blocklist deste lote — auditado." | `config.overrideBlocklist === true` | `destructive` | `ShieldAlert` | Não |
| `contentMissing` | "Escreva o conteúdo da ação ou selecione um template — um dos dois é obrigatório para disparar." | `!hasDispatchContent(config)` | texto `text-xs text-destructive` (não é `Alert`) | — | **Sim** |

**Detalhe de redação deliberado no alerta de resumo:** o texto diz "contrato **SELECIONADO**", não "cobrável". Comentário no código (l. 419–422): com escolha parcial, "cobrável" mentiria — há contratos cobráveis deixados de fora de propósito.

**Detalhe do `leftOutCount`:** a mensagem **não pode culpar só a falta de título** — há duas causas possíveis: (a) o contato não tem título cobrável; (b) em contrato-grão, os contratos que o usuário deixou marcados não resolvem título cobrável. Por isso o sufixo muda com o grão.

### A5.2 Aviso de duplicidade — como é calculado

**Fonte:** `useCheckRecentActions` + `summarizeRecentActions` + `buildDuplicateWarning` (`useDisparos.ts` l. 616–802).

| Parâmetro | Valor |
|---|---|
| Janela | `RECENT_ACTION_WINDOW_HOURS = 72` (3 dias) |
| RPC | `public.get_contacts_with_recent_actions` (client base + `p_schema_name`) |
| Chave de escopo | `contactIds` + `actionType` (= `config.channel`) + `integrationId` |
| Flags por contato | `has_pending` (pendente/processando) e `has_recent_sent` (já enviada) |
| Agregados | `flaggedCount` (alguma flag), `pendingCount`, `recentSentCount` |
| Falha da consulta | **Best-effort**: erro é logado (`logError`) e vira `null` — **não trava** a prévia |

Em contrato-grão o aviso é **uma aproximação** (checa o contato, não cada contrato) — comentário explícito no código.

### A5.3 Problemas POR DESTINATÁRIO (prévia)

**Fonte da verdade:** o campo `would_send` do dry-run, calculado pelo **próprio `send-message`**. `preview-problems.ts` documenta por que **não** reavalia `blocklist`/`title_status`/`recipient` por conta própria: eles são as *razões* de um `would_send === false`, não critérios independentes — checá-los de novo **contradiria o override** e marcaria como problema um contato que na verdade seria enviado.

**Detecção (`preview-problems.ts`):**

| Função | Regra |
|---|---|
| `previewHasProblem(preview)` | `!preview.would_send` |
| `entryHasProblem(entry)` | `undefined` (não cacheado) ⇒ **não é problema** ("desconhecido"); `status === "error"` ⇒ **é problema**; senão delega a `previewHasProblem` |

**Catálogo de motivos exibidos (`getBlockReason`, `DisparoPreviewNavigator.tsx` l. 60–80) — em ordem de precedência:**

| # | Código / campo do preview | Rótulo exibido (texto exato do frontend) | Significado | Bloqueia o lote? |
|---|---|---|---|---|
| 1 | `preview.rcs.over_limit` | "o corpo do RCS tem **{n}** caracteres, acima do limite de **{m}** do canal — acima disso a mensagem não é entregue, então o envio é recusado." | Corpo resolvido do RCS ultrapassou `body_limit` (3.000 caracteres). **Único motivo que o operador resolve editando o template.** | **Não bloqueia o lote**; bloqueia **aquela** ação no envio (a EF grava falha sem chamar o provedor) |
| 2 | `preview.blocklist.blocked` | "bloqueado pela blocklist" + (se houver) " ({reason})" | Contato/endereço na blocklist e sem override válido nem passe livre | Não bloqueia o lote |
| 3 | `preview.title_status.is_paid` (com `actionable === false`) | "o título mais atrasado já está pago." | O título resolvido não é acionável | Não |
| 4 | `preview.title_status.removed` (com `actionable === false`) | "o título mais atrasado foi removido." | idem | Não |
| 5 | `!preview.recipient` | "não há telefone/e-mail cadastrado para este contato." | Sem destinatário para o canal | Não |
| 6 | fallback | "verifique os avisos abaixo." | `would_send === false` por motivo não mapeado nesta lista | Não |
| — | `status === "error"` (falha do dry-run) | Badge `Erro na prévia` + alerta "Não foi possível gerar a pré-visualização deste contato: {mensagem}" | O dry-run falhou (rede/EF) | Não |
| — | `preview.warnings[]` | Cada string do array, com ícone `AlertTriangle` âmbar | Avisos livres vindos da EF `send-message` | Não |
| — | `preview.duplicate_warning` | ⚠️ A confirmar: o campo existe em `ManualActionPreview` (`{channel, last_action_at}`) mas **não é renderizado** pelo `DisparoPreviewNavigator` — o aviso de duplicidade do Disparo vem do agregado do lote (A5.2). |

**Frase-moldura que acompanha todo motivo** (l. 402–404):

> "Este contato não seria enviado — {motivo} Isso não bloqueia o lote: cada contato é reavaliado individualmente no envio."

### A5.4 Badge de status do destinatário atual

| Condição | Badge | Variante |
|---|---|---|
| `entry.status === "error"` | `Erro na prévia` | `destructive`, `text-[10px]` |
| `preview.would_send === true` | `Pronto para enviar` | `secondary`, `text-[10px]` |
| `preview.would_send === false` | `Não será enviado` | `destructive`, `text-[10px]` |
| Ainda carregando | nenhum badge | — |

### A5.5 Regra de ouro do catálogo (para o redesign)

**Nenhum problema por destinatário bloqueia o lote.** Os únicos bloqueios reais do botão Disparar são: sem prévia, zero alvos, sem integração, sem conteúdo, ou mutação em andamento (ver A8.1). Todo o resto é **informativo** — o `send-message` reavalia cada contato individualmente no envio.

---

## A6. Composição da mensagem (canal, template, variáveis, limites)

**Fonte:** `src/components/disparos/DisparoComposer.tsx` — dois componentes exportados a partir do mesmo `DisparoConfig`.

### A6.1 O objeto `DisparoConfig`

Config **compartilhada pelo lote inteiro**. Não há seleção de título/contrato nem override de telefone/e-mail por contato — cada contato resolve os próprios dados no envio.

| Campo | Tipo | Default (`EMPTY_CONFIG`) | Significado |
|---|---|---|---|
| `integrationId` | `string` | `""` | Integração escolhida |
| `channel` | `string` | `""` | Categoria da integração (= `action_type` da ação) |
| `content` | `string \| null` | `null` | Corpo livre |
| `subject` | `string \| null` | `null` | Assunto (só e-mail) |
| `metaTemplateName` | `string?` | — | Nome do template **aprovado na Meta** (WhatsApp) |
| `templateVariableMap` | `Record<string,string>?` | — | Mapa `{{1}}`,`{{2}}`… → valor/variável |
| `rcsTemplateId` | `string?` | — | **ID** do template local de RCS (`message_templates.id`) |
| `overrideBlocklist` | `boolean` | `false` | `true` = ignora a blocklist |

> Nota de arquitetura no código: `rcsTemplateId` **não reusa** `metaTemplateName` de propósito — "aquele é o NOME do template aprovado na Meta e o RCS é resolvido por ID. Misturar os dois faria o guard do processor isentar WhatsApp sem template, que é o que ele existe para pegar."

### A6.2 Bloco 1 — `DisparoActionPicker` (card "1. Configurar a ação")

| Campo | Componente | Condição de exibição | Placeholder | `data-testid` |
|---|---|---|---|---|
| **Tipo de Ação** | `Select` | `availableTypes.length > 0` | `Selecionar tipo...` | `disparo-composer-type-trigger` |
| **Integração** | `Select` | `selectedType && filteredIntegrations.length > 1` | `Selecionar integração...` | `disparo-composer-integration-trigger` |

**Opções de "Tipo de Ação":** categorias **únicas** das integrações **ATIVAS** (`useIntegrations({ isActive: true })`). Cada item mostra um `Badge secondary` colorido (`text-[10px] px-1.5 py-0`) com o rótulo, **seguido do mesmo rótulo em texto**.

Cores/rótulos vêm de `INTEGRATION_TYPES` (`src/lib/constants/integration-types.ts`):

| Chave | Rótulo | Cor do badge | Grão |
|---|---|---|---|
| `whatsapp` | WhatsApp | `bg-green-100 text-green-800` | contato |
| `email` | E-mail | `bg-blue-100 text-blue-800` | contato |
| `rcs` | RCS | `bg-teal-100 text-teal-800` | contato |
| `sms` | SMS | `bg-purple-100 text-purple-800` | contato |
| `voice` | Voz/TTS | `bg-orange-100 text-orange-800` | contato |
| `human_activity` | Atividade Humana | `bg-cyan-100 text-cyan-800` | contato |
| `negativation` | Negativação | `bg-red-100 text-red-800` | **contrato** |
| `block` | Bloqueio | `bg-amber-100 text-amber-800` | contato |
| `notification` | Notificação | `bg-yellow-100 text-yellow-800` | **contrato** |
| `webhook` | Webhook | `bg-gray-100 text-gray-800` | contato |

**Auto-seleção de integração:** ao trocar o tipo, se existir **exatamente uma** integração ativa naquela categoria, ela é selecionada automaticamente (`filtered.length === 1 ? filtered[0].id : ""`) e o seletor de integração **não é exibido**.

**Resets ao trocar tipo OU integração** (`handleTypeChange` / `handleIntegrationChange`): `metaTemplateName = undefined`, `templateVariableMap = undefined`, `rcsTemplateId = undefined`. Motivo: template é por canal/integração — "senão sobra id de outro canal na config (e na chave de invalidação da prévia)".

### A6.3 Bloco 2 — `DisparoContentComposer` (card "3. Conteúdo")

**Gate global:** o componente **não renderiza nada** enquanto `value.integrationId` estiver vazio.

O `channel` efetivo é derivado do próprio `useIntegrations({ isActive: true })` (servido do cache do TanStack, sem requisição duplicada):

```
channel = integrations.find(i => i.id === value.integrationId)?.category
       || value.channel
       || ""
```

Conjuntos de controle:

| Constante | Valor | Uso |
|---|---|---|
| `EMAIL_CHANNELS` | `["email"]` | Mostra o campo Assunto |
| `MESSAGING_CATEGORIES` | `{whatsapp, email, rcs, sms, voice}` | Define se Conteúdo é obrigatório e o placeholder |

#### Sub-bloco 3 — Toggle "Respeitar blocklist"

| Atributo | Valor |
|---|---|
| Condição | `hasPermission("disparos:override_blocklist")` (owner/admin) |
| Container | `space-y-2 rounded-md border px-3 py-2.5` |
| Label | `Respeitar blocklist` (`cursor-pointer text-sm font-medium`, `htmlFor="disparo-respect-blocklist"`) |
| Descrição | "Desative para forçar o envio deste lote mesmo para contatos bloqueados." (`text-xs text-muted-foreground`) |
| Controle | `Switch id="disparo-respect-blocklist"` com `checked={!value.overrideBlocklist}` (lógica **invertida**) |
| Default | Ligado (respeita a blocklist) |
| Alerta ao desligar | `Alert variant="destructive"` + `ShieldAlert`: "Você está forçando o envio ignorando a blocklist deste lote — auditado." |

> A auditoria real acontece no banco: o trigger `enforce_action_override_guard` carimba `auth.uid()` e **rejeita** se o autor não for owner/admin. O frontend só propõe a auditoria.

#### Sub-bloco 4 — Template Meta (WhatsApp)

| Atributo | Valor |
|---|---|
| Condição | `channel === "whatsapp" && metaTemplates && metaTemplates.length > 0` |
| Label | `Template Meta (opcional)` com ícone `MessageSquare` (`h-4 w-4`) |
| Controle | `Popover` + `Command` (combobox) |
| Gatilho fechado (sem seleção) | Texto `Nenhum template (envio livre)`, cor `text-muted-foreground`, ícone `ChevronsUpDown` |
| Gatilho fechado (com seleção) | `Badge secondary` verde (`bg-green-100 text-green-800`, `text-[10px]`) com o texto `Meta` + nome do template (truncado) |
| Busca | `CommandInput placeholder="Buscar template..."` |
| Vazio | `Nenhum template Meta encontrado` |
| Primeira opção | `Nenhum template (envio livre)` (valor `__none__`) |
| Demais opções | Só templates com `meta_status === "APPROVED"`; cada item mostra `meta_template_name || name` + a `meta_category` em `text-xs text-muted-foreground` |
| Marca de seleção | `Check` (`h-3 w-3`), `opacity-100`/`opacity-0` |
| Largura do popover | `w-[360px] p-0`, `align="start"` |

**Extração de variáveis:** ao selecionar, o código varre `meta_components[].text` com a regex `/\{\{(\d+)\}\}/g`, monta o conjunto ordenado numericamente e inicializa `templateVariableMap` com `{ "1": "", "2": "", … }`.

**Exemplos:** o componente `BODY` do template pode trazer `example.body_text[0]` — um array de strings que vira `{ "1": exemplo1, "2": exemplo2, … }` e alimenta o `MetaVariableMapper`.

**`MetaVariableMapper`:** renderizado quando há template selecionado **e** `metaVariables.length > 0`. Recebe `variables`, `examples`, `value` (o mapa atual) e `onChange`.
⚠️ A confirmar: a UI interna do `MetaVariableMapper` (vem de `src/components/reguas-cobranca/config-forms/SharedComponents`) não foi lida neste documento.

#### Sub-bloco 4b — Template RCS

| Atributo | Valor |
|---|---|
| Condição | `channel === "rcs"` (sem exigir lista não-vazia) |
| Label | `Template RCS (opcional)` com ícone `MessageSquare` |
| Controle | `TemplateHSMSelector channel="rcs"` (o **mesmo** seletor usado na configuração de passo de régua) |
| Valor | `value.rcsTemplateId`; limpar devolve `undefined` |
| Alerta quando selecionado | `Alert` + `Info`: "O corpo do template vence o conteúdo digitado abaixo — o texto só é usado como reserva, se o template não tiver corpo." |

**Ausência deliberada de `MetaVariableMapper` no RCS** (comentário l. 436–441): medido em produção, **28 de 28** templates RCS usam variável **nomeada** (`{{contract.number}}`) e **zero** usa numerada (`{{1}}`). O `send-message` resolve as nomeadas no envio. "Mapear variável aqui seria UI para um problema que não existe."

#### Sub-bloco 5 — Assunto (só e-mail)

| Atributo | Valor |
|---|---|
| Condição | `EMAIL_CHANNELS.includes(channel)` |
| Label | `Assunto` (`text-xs`) |
| Controle | `InputWithVariables` (aceita variáveis `{{...}}`) |
| Placeholder | `Assunto do email` |
| Vazio | Gravado como `null` |

#### Sub-bloco 6 — Conteúdo

| Atributo | Valor |
|---|---|
| Label | `Conteúdo` + sufixo ` (opcional)` quando **não** é canal de mensageria |
| Controle | `RichVariableInput`, `rows={4}`, `variableContext="integration"` |
| Placeholder (mensageria) | `Conteúdo da mensagem (usa o Template Meta se selecionado)` |
| Placeholder (demais) | `Conteúdo do payload` |
| Vazio | Gravado como `null` |
| Hint de erro | `text-xs text-destructive`: "Escreva o conteúdo da ação ou selecione um template — um dos dois é obrigatório para disparar." |

### A6.4 Regra de conteúdo válido (`hasDispatchContent`)

**Uma única função** gateia o botão Disparar **e** o hint vermelho (correção do card 7136 — antes eram duas verdades, e a tela mostrava "selecione um Template Meta" em vermelho com o template RCS já escolhido e o botão habilitado).

```
hasDispatchContent(config) =
      content preenchido (trim > 0)
   OU metaTemplateName preenchido (trim > 0)
   OU (channel === "rcs" E rcsTemplateId preenchido)
```

> O terceiro termo é **restrito a `rcs`** de propósito, espelhando o guard do `scheduled-action-processor`: WhatsApp com template local continua exigindo conteúdo.

### A6.5 Limites de caracteres no Disparo

| Canal | Limite aplicado na tela de Disparos | Onde aparece |
|---|---|---|
| RCS | **3.000** caracteres no corpo (`preview.rcs.body_limit`) | Só na **prévia**, como motivo de "Não será enviado" — **não** há contador ao vivo no campo de conteúdo |
| Demais canais | ⚠️ A confirmar: o `DisparoComposer` **não** aplica nem exibe limite de caracteres. Os limites por canal (`BODY_CHAR_LIMITS`) são validados no backend/`send-message`. |

> Diferença importante para o redesign: a tela de **Templates** (Parte B) mostra contador e limite ao vivo; a tela de **Disparos** não — ela só descobre o estouro na prévia, alvo por alvo.

### A6.6 Variáveis no Disparo

- Campo de conteúdo: `RichVariableInput` com `variableContext="integration"`.
- Campo de assunto: `InputWithVariables`.
- As variáveis são resolvidas **no envio**, com os dados do alvo (contato/contrato/título). Não há mapeamento manual, exceto o `MetaVariableMapper` das variáveis numeradas do WhatsApp.
- O catálogo completo de variáveis está na seção **B9** deste documento (é o mesmo de Templates).

---

## A7. Prévia por destinatário

**Fonte:** `src/components/disparos/DisparoPreviewNavigator.tsx` + `src/components/disparos/preview-problems.ts`.

### A7.1 Conceito: a `PreviewSession` congelada

O clique em **Pré-visualizar** captura uma *sessão*:

```ts
interface PreviewSession {
  contactIds: string[];          // contatos no clique
  config: DisparoConfig;         // config no clique
  targets: DispatchTarget[];     // alvos JÁ filtrados pela escolha de contratos
  recentSummary: RecentActionsSummary | null;  // aviso de duplicidade
}
```

Duas chaves de React controlam o ciclo de vida:

| Chave | Efeito |
|---|---|
| `previewSessionKey` | Incrementa a cada preview novo → **remonta** o navigator com cache limpo |
| `listResetKey` | Incrementa em "Novo disparo" → **remonta** o `DisparoTargetList` (zera a seleção de verdade) |

### A7.2 Invalidação da prévia

A sessão é **descartada** (apenas estado local, sem chamada de rede) sempre que `buildPreviewInvalidationKey` muda. A chave serializa:

| Campo na chave | Origem |
|---|---|
| `selection` | `buildSelectionKey(selection)` — **ordenada** (contatos por `contactId`, contratos dentro de cada um) |
| `channel` | `config.channel` |
| `integrationId` | `config.integrationId` |
| `content` | `config.content` |
| `subject` | `config.subject` |
| `metaTemplateName` | `config.metaTemplateName ?? null` |
| `templateVariableMap` | `config.templateVariableMap ?? null` |
| `rcsTemplateId` | `config.rcsTemplateId ?? null` |
| `overrideBlocklist` | `config.overrideBlocklist` |

**Por que a serialização é estável (ordenada):** o `DisparoTargetList` propaga um array novo a cada render; sem ordenação, a prévia seria invalidada por recriação de referência, não por edição real.

**Por que a chave é memoizada em DUAS camadas** (comentário l. 129–135): `config` muda **a cada tecla** digitada no conteúdo. Com "Selecionar todos", o teto passa a ser a população da org (7.279 contatos em `org_blips`) — seriam **~451 KB de `JSON.stringify` + um `sort` com `localeCompare` de 7 mil elementos POR CARACTERE**. Separando `selectionKey`, a metade cara só recomputa quando a **seleção** muda.

**Guarda de corrida (`previewKeyRef`):** o `handlePreview` compara a chave **depois** do `await`. Se a seleção/config mudou durante o "Preparando…", o resultado é **descartado em silêncio** — sem toast de erro, porque "o usuário acabou de mexer na tela; um toast de erro seria culpar ele por uma ação própria".

### A7.3 O que acontece no clique em "Pré-visualizar"

```
1. canPreview? (há contato + integração + não está preparando)
2. setPreparingPreview(true)  → botão vira "Preparando..." com Loader2
3. Promise.all:
   a) useResolveDispatchTargets  → RPC por grão  [CRÍTICO — falha aborta]
   b) useCheckRecentActions      → aviso duplicidade [best-effort — erro vira null]
4. filterTargetsBySelection(...)  ← ÚNICO ponto de aplicação da escolha de contratos
5. previewKeyRef.current !== keyAtClick ? descarta em silêncio : congela a sessão
6. setPreviewSessionKey(k => k+1)  → remonta o navigator
7. finally: setPreparingPreview(false)
```

**Erro:** toast `variant="destructive"`, título `Erro ao preparar a pré-visualização`, descrição = `getErrorMessage(error)`.

### A7.4 Layout do navegador de prévia

Container: `space-y-3 rounded-md border p-3`, `data-testid="disparo-preview-navigator"`. **Não renderiza nada** quando `total === 0`.

**Linha 1 — barra de navegação:**

| Elemento | Detalhe |
|---|---|
| Título | Ícone `Eye` + `Prévia` (`text-sm font-semibold`) |
| Botão anterior | `ghost icon h-7 w-7`, `ChevronLeft`, `aria-label="Contato anterior"`, desabilitado em `currentIndex === 0` ou durante varredura |
| Contador | `{i+1} de {N}` — `min-w-[4.5rem] text-center text-xs tabular-nums text-muted-foreground`, números em `pt-BR` |
| Botão próximo | `ghost icon h-7 w-7`, `ChevronRight`, `aria-label="Próximo contato"`, desabilitado no último ou durante varredura |
| Botão de varredura | `outline sm` — `SearchCheck` + `Próximo com problema` / `Loader2` + `Procurando...`; desabilitado durante varredura ou no último índice |

**Linha 2 — identidade do alvo atual:**

| Elemento | Detalhe |
|---|---|
| Nome | `truncate text-sm font-medium` — `identity?.name || "Sem nome"` |
| Documento | `formatDocument(document, document_type)`, `text-xs text-muted-foreground` |
| Contrato | Só quando `currentContractId` existe: separador `·` + `Contrato {contract_number || "—"}` |
| Badge de status | ver A5.4 |

**Linha 3 — nota permanente:**

> "Cada contato resolve os próprios dados (destinatário, título mais atrasado) no envio real — esta prévia mostra como ficaria para cada um."

**Corpo (`PreviewBody`):**

| Bloco | Conteúdo |
|---|---|
| Grade 2 colunas (`grid grid-cols-2 gap-x-4 gap-y-2 text-xs`) | **Destinatário** (`text-destructive` se ausente, texto `Sem destinatário`) e **Canal** (`{rótulo do canal} · {integration_name}`) |
| `MessagePreview` | Mock fiel do canal: `channel`, `message`, `resolvedMessage`, `subject`, `resolvedParams` (do template Meta), `recipientLabel`, `metaComponents` (card RCS resolvido) |
| Alerta de bloqueio | `Alert destructive` + `AlertTriangle` quando `!would_send` (ver A5.3) |
| Lista de warnings | `<ul>` com itens `text-xs text-amber-800 dark:text-amber-400` + `AlertTriangle` (`h-3.5 w-3.5`) |
| Raio-x do payload | `Collapsible` "Ver dados enviados à integração" → `OutboundRequestView` (só quando `preview.outbound_request` existe) |

### A7.5 Lazy loading e cache

| Regra | Implementação |
|---|---|
| **Só busca ao navegar** | `useEffect` dispara `fetchIndex(currentIndex)` apenas se o índice **não** estiver no cache |
| **Cache em memória por índice** | `useRef<Map<number, PreviewEntry>>` — fonte de verdade **síncrona**, para o laço de varredura ler resultados recém-buscados sem esperar re-render |
| **Re-render forçado** | `useReducer((x) => x + 1, 0)` — `forceRender()` após cada `set` |
| **Nunca pré-busca os N** | Evita "floodar" o `send-message` |
| **Cache limpo por sessão** | O pai remonta via `key={previewSessionKey}` |
| **Spinner localizado** | `pendingIndex === currentIndex` → 2 `Skeleton` (`h-4 w-40`, `h-20 w-full`), `data-testid="disparo-preview-loading"` |
| **Raio-x fecha ao trocar de alvo** | `useEffect` zera `outboundOpen` quando `currentIndex` muda |

**Identidades cacheadas via TanStack Query (`staleTime` 5 min):**

| Query key | Busca |
|---|---|
| `["disparo-contact-identity", orgSlug, contactId]` | `contacts` → `name, document, document_type` |
| `["disparo-contract-identity", orgSlug, contractId]` | `contracts` → `contract_number` |

### A7.6 "Próximo com problema" — algoritmo

`handleNextProblem` (l. 212–235) + `findNextProblemIndex` (puro, testável sem DOM):

```
loop:
  decision = findNextProblemIndex(cache, from, total, entryHasProblem)
  · "found" → setCurrentIndex(decision.index); fim
  · "none"  → toast "Nenhum problema encontrado a partir daqui."; fim
  · "fetch" → await fetchIndex(decision.index); from = decision.index - 1; repete
```

Ou seja: varre **sequencialmente** a partir do índice atual (exclusive), buscando os previews faltantes **um a um** (não em paralelo), aproveitando o cache, e para no primeiro problema.

### A7.7 Paridade prévia ↔ envio (invariante crítica)

`buildPreviewParams(target, config)` e `buildDispatchRows(targets, config, …)` são **duas funções puras irmãs** em `useDisparos.ts`, comparadas campo a campo por um teste de paridade (`useDisparos.spec.ts`).

**História documentada no código:** a entrega do card 7136 ensinou o INSERT a levar o template RCS e **esqueceu a prévia**, que montava um objeto irmão à mão em outro arquivo → **card em branco na tela**, sem nenhum teste vermelho.

> Regra para o redesign: **toda chave nova de `DisparoConfig` que molda a mensagem precisa entrar nas duas funções e na chave de invalidação.**

### A7.8 A prévia não envia nada

Conforme o guia do app (`disparos.ts`, bloco `callout level: "ok"`):

> "Ela é um 'ensaio': resolve tudo exatamente como no envio real (mesmo destinatário, mesmo texto, mesmo payload), mas não cria ação, não chama o provedor e não gera link de pagamento novo. É 100% leitura."

---

## A8. Confirmação e execução do envio

**Fonte:** `DisparosPage.tsx` (`handleConfirm`) + `useCreateDispatchBatch` (`useDisparos.ts` l. 1027–1100).

### A8.1 Gates do botão "Disparar"

`canDispatch` exige **todas** as condições:

| # | Condição | Mensagem de hint quando falha |
|---|---|---|
| 1 | `previewSession !== null` | "Clique em Pré-visualizar para preparar o disparo." |
| 2 | `targetCount > 0` | (alerta destrutivo de zero alvos) |
| 3 | `config.integrationId` preenchido | "Escolha o tipo de ação e a integração para continuar." |
| 4 | `hasDispatchContent(config)` | "Escreva o conteúdo da ação ou selecione um Template Meta para continuar." |
| 5 | `!createBatch.isPending` | — |
| — | (antes de tudo) seleção vazia | "Selecione ao menos um contato na lista acima." |

**Hint textual** (`text-xs text-muted-foreground`, à esquerda dos botões) — cadeia de precedência exata do código:

```
seleção vazia            → "Selecione ao menos um contato na lista acima."
sem integrationId        → "Escolha o tipo de ação e a integração para continuar."
sem conteúdo válido      → "Escreva o conteúdo da ação ou selecione um Template Meta para continuar."
sem previewSession       → "Clique em Pré-visualizar para preparar o disparo."
tudo ok                  → null (nenhum texto)
```

### A8.2 Gate do botão "Pré-visualizar"

`canPreview = !!representativeId && !!config.integrationId && !preparingPreview`
(`representativeId = selectedContactIds[0]`)

### A8.3 Os dois botões

| Botão | Variante | Ícone normal | Ícone pendente | Rótulo normal | Rótulo pendente |
|---|---|---|---|---|---|
| Pré-visualizar | `outline` | `Eye` | `Loader2 animate-spin` | `Pré-visualizar` | `Preparando...` |
| Disparar | default (primário) | `Send` | `Loader2 animate-spin` | `Disparar {n} ações` (ou `Disparar` sem prévia) | `Disparando...` |

**Rótulo dinâmico do Disparar (`dispatchLabel`):**

```
previewSession ? `Disparar ${targetCount} ${targetCount === 1 ? "ação" : "ações"}` : "Disparar"
```

> **Achado relevante para o redesign:** **NÃO existe modal de confirmação.** O clique em "Disparar" executa o lote imediatamente. A "confirmação" é o próprio fluxo obrigatório de Pré-visualizar (que congela os alvos) + o número no rótulo do botão + os alertas de resumo logo acima. A irreversibilidade é comunicada por **texto**, não por um `AlertDialog`.

### A8.4 Irreversibilidade — o que o código garante

| Fato | Evidência |
|---|---|
| O lote é **criado**, não enviado | `useCreateDispatchBatch` faz bulk-insert de N linhas `actions` com `status = Pendente`, `source = "disparo"`. **Nenhum invoke síncrono de `send-message` acontece na tela.** |
| Quem envia | O cron `scheduled-action-processor`, de forma assíncrona |
| Não há botão de cancelar lote na UI | Após criar, a tela troca para o acompanhamento — **não existe ação de "cancelar lote"** no `DisparoResultsTable` nem no `DisparoHistoryTab` |
| Não há deduplicação | O guia do app é explícito: "O disparo é uma ação DELIBERADA: ele NÃO passa pelas travas de deduplicação/cooldown/mesmo-passo das campanhas. A única trava real é a blocklist. Se você disparar de novo para os mesmos contatos, a Torre cria ações repetidas e envia de novo" |
| O único aviso de duplicidade é informativo | Ver A5.2 |

⚠️ A confirmar: há um cleanup programático (`delete_dispatch_batch_pending`) usado **apenas** no rollback de falha parcial — não há gatilho de usuário para ele.

### A8.5 Estrutura de uma ação criada (`buildDispatchRows`)

Uma linha por **alvo**:

| Campo | Valor |
|---|---|
| `contact_id` / `contract_id` / `title_id` | Do `DispatchTarget` congelado no preview |
| `campaign_id` | `null` |
| `integration_id` | `config.integrationId` |
| `action_type` | `config.channel` |
| `channel` | `config.channel` |
| `status` | `ACTION_STATUSES.PENDENTE` |
| `content` | `config.content \|\| null` |
| `subject` | `config.subject \|\| null` |
| `source` | `"disparo"` (o cron reivindica **sem** a janela-de-graça do `manual`) |
| `source_detail.user_id` | `auth.getUser().id` |
| `source_detail.created_at` | ISO do clique |
| `source_detail.batch_id` | `crypto.randomUUID()` |
| `source_detail.blocklist_overridden` | `config.overrideBlocklist === true` |
| `source_detail.overridden_by` / `overridden_at` | Preenchidos **só** quando há override |
| `template_variable_map` | `config.templateVariableMap ?? null` |
| `metadata.meta_template_name` | `config.metaTemplateName ?? null` |
| `metadata.rcs_template_id` | `config.rcsTemplateId` **somente se `channel === "rcs"`**, senão `null` |
| `metadata.batch_id` | Mesmo `batch_id` |

### A8.6 Execução em chunks e rollback compensatório

| Parâmetro | Valor |
|---|---|
| Tamanho do chunk | `DISPATCH_INSERT_CHUNK_SIZE = 500` |
| Atomicidade | **Cada chunk é atômico; o LOOP não é** |
| Falha no meio | Tenta apagar as `Pendente` já inseridas via RPC `delete_dispatch_batch_pending` (best-effort) e lança `PartialDispatchError` |
| Por que RPC e não PostgREST | Com RLS ativo, `metadata->>batch_id` não é avaliável antes da policy → Seq Scan que estoura o `statement_timeout` de 8s |
| Ações já avançadas (Processando/Enviado) | **Não** são apagadas (ficam rastreáveis pelo `batchId`) |

### A8.7 Toasts do envio

| Situação | Variante | Título | Descrição |
|---|---|---|---|
| Sucesso | default | `{n} ação enfileirada — enviando…` / `{n} ações enfileiradas — enviando…` | — |
| Lote parcial revertido | `destructive` | `Falha no disparo — lote parcial revertido` | "Algumas ações podem ter sido criadas e foram apagadas automaticamente (lote **{8 primeiros chars do batchId}**). Pode tentar disparar novamente. Detalhe: {mensagem}" |
| Erro genérico | `destructive` | `Erro ao criar o lote de disparo` | `getErrorMessage(error)` |

### A8.8 Transição de estado após o sucesso

```
setBatchId(result.batchId)
  → TabsContent "new" troca de RAMO: os 3 cards somem,
    entra o Card "Acompanhamento do lote"
```

Além disso, `onSuccess` do hook invalida a query `["contact-actions"]`.

**Botão "Novo disparo"** (`variant="outline" size="sm"`, ícone `RotateCcw`, no `CardHeader` do acompanhamento) executa `handleNewDispatch`:

```
setBatchId(null)          // volta aos 3 cards
setSelection([])          // zera a seleção no pai
setConfig(EMPTY_CONFIG)   // zera a configuração
setPreviewSession(null)   // descarta a prévia
setListResetKey(k => k+1) // REMONTA o DisparoTargetList (zera o Map interno + filtros + colagens)
```

---

## A9. Resultados do disparo

**Fonte:** `src/components/disparos/DisparoResultsTable.tsx` + `src/components/disparos/dispatch-row.tsx` + `useDispatchBatchStatus`.

### A9.1 Polling

| Regra | Valor |
|---|---|
| Query key | `["dispatch-batch", batchId]` |
| RPC | `public.get_dispatch_batch_actions` (client **base** + `p_schema_name`) |
| Intervalo | `5000 ms` enquanto **alguma** linha estiver em `PENDING_STATUSES` (Pendente/Processando) |
| Parada | Assim que tudo fica terminal → `refetchInterval` devolve `false` |

> Motivo de ser RPC e não PostgREST: regressão de produção (2026-07-31) — `eq("metadata->>batch_id", …)` dava **HTTP 500 em todo poll** em org grande (Seq Scan de ~10s contra `statement_timeout` de 8s). A RPC é `SECURITY DEFINER` e o índice volta a servir.

### A9.2 Chips agregados (`StatChip`)

Grade `grid grid-cols-2 gap-2 sm:grid-cols-4`. Cada chip é um `Card` com ícone + número grande (`text-lg font-semibold tabular-nums`) + rótulo (`text-xs text-muted-foreground truncate`).

| Chip | Ícone | Cor | Regra de contagem (primeiro match vence) |
|---|---|---|---|
| **Enviado** | `CheckCircle2` | `text-green-700 dark:text-green-400` | `SENT_STATUSES.has(status)` |
| **Falhou** | `XCircle` | `text-red-700 dark:text-red-400` | `FAILURE_STATUSES.has(status)` |
| **Duplicado** | `Copy` | `text-muted-foreground` | `status === ACTION_STATUSES.DUPLICADO` |
| **Pendente / Processando** | `Clock` | `text-amber-700 dark:text-amber-400` | `PENDING_STATUSES.has(status)` |

> Status fora desses quatro grupos (ex.: Cancelado) **não aparecem em chip** no acompanhamento do lote — mas aparecem no Histórico (ver A10.3).

### A9.3 Tabela de resultados (`DispatchActionResultTable`)

| # | Coluna | Conteúdo |
|---|---|---|
| 0 | expansor | Botão `ghost icon h-7 w-7`, `ChevronRight`/`ChevronDown`, `aria-label` `Ver detalhes`/`Ocultar detalhes`, `aria-expanded` |
| 1 | **Contato** | Duas linhas: `primary` (`font-medium text-sm`) e `secondary` (`text-xs text-muted-foreground`) |
| 2 | **Contrato** | `contract_number` ou `—` |
| 3 | **Status** | `Badge variant="outline"` colorido por categoria, com o **rótulo de exibição** (`getActionStatusLabel`) |
| 4 | **Destinatário** | `row.recipient ?? "-"` |
| 5 | **Erro** | `row.error_message ?? "-"`, `text-xs text-destructive` |

**Rótulo de identidade do contato (`buildContactRowLabel`, `dispatch-labels.ts`) — prioridade:**

| Prioridade | `primary` | `secondary` |
|---|---|---|
| 1 | Nome do contato | Documento formatado (ou `null`) |
| 2 | Documento formatado | `null` |
| 3 | 8 primeiros chars do `contact_id` | `null` |
| 4 (sem contato) | `-` | `null` |

> O passo 3 é **tolerância de deploy**: a RPC antiga (pré-`20260731030000`) não devolve os campos de identidade, e a tela cai no id curto em vez de quebrar.

**Cor do badge de status (`statusBadgeClassName`):**

| Categoria | Classe |
|---|---|
| `SENT_STATUSES` | `border-green-300 text-green-700 dark:text-green-400` |
| `FAILURE_STATUSES` | `border-red-300 text-red-700 dark:text-red-400` |
| `Duplicado` | `border-gray-300 text-gray-600 dark:text-gray-400` |
| `PENDING_STATUSES` | `border-amber-300 text-amber-700 dark:text-amber-400` |
| fallback | `border-gray-300 text-gray-600 dark:text-gray-400` |

**Rótulos de exibição ≠ valores canônicos** (`src/lib/constants/action-status-display.ts`, regra 11 do CLAUDE.md da Torre):

| Valor canônico gravado | Rótulo exibido na UI |
|---|---|
| `Falhou` | **Falha Temporária de Ação** |
| `Falha Permanente` | **Falha Definitiva de Ação** |
| `Respondido` | **Solicitou Atendimento** |
| Demais (Pendente, Processando, Enviado, Interagiu, Em Atendimento, Cancelado, Cancelado (Pago), Cancelado (Removido), Duplicado) | Iguais ao valor canônico |

### A9.4 Linha de detalhe expandida (painel de auditoria)

`TableRow className="bg-muted/20"`, `colSpan={6}`, `p-3`, conteúdo em `space-y-3`:

| Bloco | Conteúdo |
|---|---|
| Barra de ação | Botão `outline sm h-7 gap-1 text-xs` — `Copiar JSON` → `Copiado!` por 1.500 ms (ícone `Copy` → `Check`). Falha do clipboard é **silenciosa** |
| Grade 2 colunas (`md:grid-cols-2`) | `JsonBlock` **Payload enviado** e `JsonBlock` **Retorno** — ambos passando por `redactSecrets` |
| Erro (condicional) | Rótulo `ERRO` + caixa `bg-destructive/10 p-2 text-xs text-destructive` |
| **Referência** | 8 pares chave/valor |
| **Auditoria** | 5 pares chave/valor |

**Bloco "Referência":** Contato (id) · Canal · Integração · Contrato · Título · Enviado em · Duração (ms) · Tentativas. Valores ausentes viram `-`.

**Bloco "Auditoria":** Usuário · Lote · Blocklist ignorada · Ignorada por · Ignorada em. Valores `null`/`undefined`/`""` viram `-`.

**`JsonBlock`:** rótulo em `text-xs font-medium uppercase tracking-wide text-muted-foreground` + `<pre>` `whitespace-pre-wrap break-all font-mono text-xs` dentro de `max-h-72 overflow-auto rounded-md bg-muted/40 p-2`.

### A9.5 Redação de segredos (`redactSecrets`)

Aplicada **antes** de exibir, copiar ou baixar. O `request_payload` gravado em `actions` **não é mascarado no backend**.

| Regra | Detalhe |
|---|---|
| Chave sensível | Regex `/authorization\|api[_-]?key\|apikey\|token\|secret\|password\|senha\|bearer/i` → valor vira `"****"` |
| Valor que parece bearer | `/^Bearer\s+/i` → vira `"****"` |
| Recursividade | Clona arrays e objetos recursivamente; **não muta** o original |

### A9.6 Exportação

Dois botões `outline sm gap-1` com ícone `Download`, alinhados à direita (`flex flex-wrap items-center justify-end gap-2`), desabilitados quando não há linhas.

| Botão | Arquivo | Conteúdo |
|---|---|---|
| **Baixar JSON** | `disparo-{batchId}.json` (`application/json`) | Array de `BatchExportItem` — payload e retorno **redigidos**, + bloco `audit` completo |
| **Baixar CSV** | `disparo-{batchId}.csv` (`text/csv;charset=utf-8`) | Só colunas escalares |

**Campos do JSON (`BatchExportItem`):** `action_id`, `batch_id`, `contact_id`, `contact_name`, `contact_document`, `contract_number`, `contract_id`, `title_id`, `integration_id`, `channel`, `recipient`, `status`, `error_message`, `sent_at`, `created_at`, `processing_duration_ms`, `retry_count`, `audit{…}`, `request_payload`, `response`.

**Bloco `audit` do JSON (12 campos):** `user_id`, `created_at`, `batch_id`, `blocklist_overridden`, `overridden_by`, `overridden_at`, `blocklist_level`, `blocklist_override_applied`, `blocklist_blocked_levels`, `blocklist_blocked_reasons`, `blocklist_blocked_sources`, `blocklist_trail_detail_error`.

> `blocklist_trail_detail_error` só existe quando a RPC de detalhe falhou — é o marcador de "razões indisponíveis", distinto de "nenhuma razão".

**Colunas do CSV (`BATCH_CSV_COLUMNS`, 17):** `action_id`, `contact_id`, `contact_name`, `contact_document`, `contract_number`, `recipient`, `channel`, `status`, `error_message`, `sent_at`, `created_at`, `processing_duration_ms`, `retry_count`, `user_id`, `batch_id`, `blocklist_overridden`, `overridden_by`.

Escape de CSV: células com `"`, `,`, `\n` ou `\r` são envolvidas em aspas duplas, com `"` duplicado.

### A9.7 Estados do acompanhamento

| Estado | Render |
|---|---|
| Carregando | 4 `Skeleton h-16` em grade + 1 `Skeleton h-48` |
| Erro | `ErrorState` — título `Erro ao carregar o status do lote`, botão de retry |
| Vazio | `EmptyState` com ícone `Clock`, título `Nenhuma ação encontrada`, descrição `Este lote ainda não tem ações registradas.` |
| Com dados | Chips + botões de export + tabela |

---

## A10. Histórico de disparos

**Fonte:** `src/components/disparos/DisparoHistoryTab.tsx` + `src/hooks/useDisparoHistory.ts`.

### A10.1 Natureza

Aba **read-only**. Lista paginada de entradas que juntam **dois tipos**:

| `entry_kind` | Significado | Badge | Ícone |
|---|---|---|---|
| `batch` | Disparo **em massa** — o lote inteiro vira UMA linha | `Em massa` (`variant="default"`) | `Users` (`h-3 w-3`) |
| `single` | Ação **avulsa** (a "Nova Ação" feita de dentro de um contato) | `Único` (`variant="secondary"`) | `User` (`h-3 w-3`) |

### A10.2 Paginação

| Parâmetro | Valor |
|---|---|
| `PAGE_SIZE` | `25` |
| `page` | 0-based no frontend |
| RPC | `public.get_dispatch_history` (`p_schema_name`, `p_limit`, `p_offset`) |
| Clamp | A RPC clampa `p_limit` em `[1,100]` |
| Ordenação | `first_created_at DESC` (vem da RPC) |
| `totalEntries` | Lido da coluna `total_entries` da primeira linha (mesmo valor em todas) |
| `placeholderData` | `(prev) => prev` — mantém a página anterior visível durante o fetch |

**Rodapé:** `{n} entrada(s) · Página {p+1} de {totalPages}` + `Loader2` girando quando `isFetching`; botões `Anterior` / `Próxima` (`outline sm`), desabilitados nos extremos ou durante fetch.

### A10.3 Card de entrada (`HistoryEntryCard`)

Gatilho: `<button>` de largura total, `flex w-full items-start gap-3 p-3 text-left hover:bg-muted/40 focus-visible:ring-2`, com `aria-expanded`.

**Linha 1 — metadados:**

| Elemento | Detalhe |
|---|---|
| Badge de tipo | `Em massa` / `Único` |
| Badge de canal | `variant="outline"` com `channelLabel(entry.channel)` — rótulo pt-BR de `INTEGRATION_TYPES`, caindo no valor cru se desconhecido |
| Contagem | `{n} ação` / `{n} ações` (`text-sm text-muted-foreground`) |
| Badge de override | Só quando `entry.any_override` — `outline` âmbar (`border-amber-300 text-amber-700`) + ícone `ShieldAlert`, texto `override` |

**Linha 2 — proveniência:** data/hora `pt-BR` (`toLocaleString`) + ícone `User` + nome do ator.

**Resolução do ator:** `useOrganizationUsers()` é chamado **uma vez** e vira um `Map<user_id, label>`; o label é `full_name || email || 8 primeiros chars do id`. Sem `actor_user_id` → `—`. Não há query por linha.

**Linha 3 — chips de status (`summarizeStatusChips`):** `Badge variant="outline"` com `{contagem} {rótulo do grupo}`, colorido por `statusBadgeClassName(sampleStatus)`.

Grupos (ordem fixa, **primeiro match vence**):

| Ordem | Chave | Rótulo | Teste |
|---|---|---|---|
| 1 | `sent` | **Enviado** | `SENT_STATUSES.has(s)` |
| 2 | `failed` | **Falhou** | `FAILURE_STATUSES.has(s)` |
| 3 | `pending` | **Pendente / Processando** | `PENDING_STATUSES.has(s)` |
| 4 | `duplicated` | **Duplicado** | `s === ACTION_STATUSES.DUPLICADO` |
| 5 | `cancelled` | **Cancelado** | `CANCELLED_STATUSES.has(s)` |
| — | (fora de grupo) | `getActionStatusLabel(status)` | Vira chip próprio, após os grupos |

> A ordem importa: `Duplicado` é testado **antes** de `Cancelado`.
> Contagens `<= 0` são ignoradas.

### A10.4 Drill-down

| Tipo | Render ao expandir |
|---|---|
| `batch` com `batch_id` | `DisparoResultsTable batchId={…}` — **exatamente** a mesma tela do acompanhamento, com chips, export e polling |
| `single` com `action_id` | `SingleActionDetail` → `DispatchActionResultTable rows={[data]}` — a **mesma** linha expansível |
| Sem referência válida | `EmptyState` ícone `History`, título `Sem detalhe disponível`, descrição `Esta entrada não tem uma referência de ação válida.` |

**`SingleActionDetail` (lazy, só ao expandir):**

| Estado | Render |
|---|---|
| Carregando | `Skeleton h-24 w-full` |
| Erro | `ErrorState` — `Erro ao carregar a ação` + retry |
| Vazio | `EmptyState` ícone `History` — `Ação não encontrada` / `Esta ação pode ter sido removida.` |
| Sucesso | Tabela de uma linha |

**Busca da ação avulsa (`useDispatchSingleAction`):** via `orgClient`, filtro por **PK** (`.eq("id", actionId)`) com embeds `contact:contacts(name, document, document_type)` e `contract:contracts(contract_number)`. Os embeds são achatados por `flattenSingleActionRow` nos **mesmos nomes** que a RPC do lote devolve, para o render compartilhado não precisar saber a origem.

> `pickEmbed` trata o fato de que um embed do PostgREST pode voltar **objeto OU array** (regra do projeto).

### A10.5 Estados da aba Histórico

| Estado | Render |
|---|---|
| Carregando | 5 `Skeleton h-24 w-full` |
| Erro | `ErrorState` — `Erro ao carregar o histórico` + retry |
| Vazio | `EmptyState` ícone `History`, título `Nenhum disparo no histórico ainda`, descrição `Os disparos em massa e as ações avulsas aparecerão aqui assim que forem criados.` |
| Com dados | Lista de cards + rodapé de paginação |

---

## A11. Estados da tela (Disparos)

### A11.1 Máquina de estados do fluxo principal

```
        ┌──────────────────────────────────────────────┐
        │  VAZIO  (nenhum contato selecionado)         │
        │  hint: "Selecione ao menos um contato…"      │
        └───────────────┬──────────────────────────────┘
                        │ seleciona contato(s)
        ┌───────────────▼──────────────────────────────┐
        │  SELECIONADO SEM AÇÃO                        │
        │  hint: "Escolha o tipo de ação e a integração"│
        └───────────────┬──────────────────────────────┘
                        │ escolhe tipo + integração
        ┌───────────────▼──────────────────────────────┐
        │  SEM CONTEÚDO                                │
        │  hint: "Escreva o conteúdo… ou template"     │
        │  + hint vermelho abaixo do campo              │
        └───────────────┬──────────────────────────────┘
                        │ escreve conteúdo / escolhe template
        ┌───────────────▼──────────────────────────────┐
        │  PRONTO PARA PRÉVIA                          │
        │  hint: "Clique em Pré-visualizar…"           │
        └───────────────┬──────────────────────────────┘
                        │ clique
        ┌───────────────▼──────────────────────────────┐
        │  PREPARANDO  (botão "Preparando...")         │
        └───────┬──────────────────────────┬───────────┘
                │ sucesso                  │ erro → toast destrutivo
        ┌───────▼──────────────────────────▼───────────┐
        │  PRÉVIA ATIVA                                │
        │  navigator + alertas + botão "Disparar N"    │
        │  QUALQUER edição → volta para PRONTO P/ PRÉVIA│
        └───────────────┬──────────────────────────────┘
                        │ clique em Disparar
        ┌───────────────▼──────────────────────────────┐
        │  DISPARANDO  (botão "Disparando...")         │
        └───────┬──────────────────────────┬───────────┘
                │ sucesso                  │ erro/parcial → toast, permanece
        ┌───────▼──────────────────────────────────────┐
        │  ACOMPANHAMENTO  (batchId !== null)          │
        │  3 cards somem; polling 5s                   │
        │  [Novo disparo] → volta para VAZIO           │
        └──────────────────────────────────────────────┘
```

### A11.2 Inventário de estados por componente

| Componente | Estados |
|---|---|
| `DisparosPage` | vazio · selecionado · preparando prévia · prévia ativa · disparando · acompanhamento |
| `DisparoActionPicker` | sem integrações ativas (nada renderiza) · tipo escolhido com 1 integração (seletor oculto) · tipo escolhido com N integrações |
| `DisparoContentComposer` | oculto (sem `integrationId`) · WhatsApp (com/sem templates Meta) · RCS (com/sem template) · e-mail (com Assunto) · demais · com/sem permissão de override |
| `DisparoTargetList` | loading · erro · vazio · com dados · refetching · com/sem colagem aplicada · interseção vazia · selecionando todos |
| `ContactContractsRow` | loading · erro · vazio ("não vira alvo") · com contratos · aviso de grão |
| `DisparoPreviewNavigator` | oculto (0 alvos) · carregando alvo · erro do alvo · ok (pronto / não será enviado) · varrendo problemas |
| `DisparoResultsTable` | loading · erro · vazio · com dados (polling ativo/parado) |
| `DisparoHistoryTab` | loading · erro · vazio · com dados · paginando |
| `SingleActionDetail` | loading · erro · não encontrada · ok |

### A11.3 Todos os textos de estado vazio/erro (inventário literal)

| Contexto | Título | Descrição |
|---|---|---|
| Lista de alvos vazia | `Nenhum contato encontrado` | `Ajuste os filtros ou a busca para encontrar contatos.` |
| Lista de alvos com erro | `Erro ao carregar contatos` | mensagem do erro + botão de retry |
| Contratos do contato vazios | — | `Nenhum contrato cobrável — este contato não vira alvo.` |
| Contratos do contato com erro | — | `Erro ao carregar contratos: {msg}` + `Tentar novamente` |
| Lote vazio | `Nenhuma ação encontrada` | `Este lote ainda não tem ações registradas.` |
| Lote com erro | `Erro ao carregar o status do lote` | mensagem + retry |
| Histórico vazio | `Nenhum disparo no histórico ainda` | `Os disparos em massa e as ações avulsas aparecerão aqui assim que forem criados.` |
| Histórico com erro | `Erro ao carregar o histórico` | mensagem + retry |
| Ação avulsa não encontrada | `Ação não encontrada` | `Esta ação pode ter sido removida.` |
| Ação avulsa com erro | `Erro ao carregar a ação` | mensagem + retry |
| Entrada sem referência | `Sem detalhe disponível` | `Esta entrada não tem uma referência de ação válida.` |
| Template Meta sem resultado | — | `Nenhum template Meta encontrado` |

---

## A12. Fluxos de uso passo a passo (Disparos)

### F1 — WhatsApp em massa por filtro de carteira (caminho feliz)

1. Abre `/disparos`, aba **Novo disparo**.
2. Card 1: **Tipo de Ação** = `WhatsApp`. Se houver uma única integração ativa de WhatsApp, ela é auto-selecionada e o seletor de Integração nem aparece.
3. Card 2: usa a `PortfolioFiltersBar` para escolher a carteira / filtro salvo / régua; ordena por "Valor Devido" clicando no cabeçalho.
4. Marca o checkbox do cabeçalho (seleciona a página) ou clica em **Selecionar todos os N**.
5. Confere o contador "N selecionado(s) no total".
6. Card 3: (opcional) escolhe **Template Meta** e preenche as variáveis numeradas; ou escreve o **Conteúdo** com variáveis `{{...}}`.
7. Clica em **Pré-visualizar** → botão vira "Preparando...".
8. Navega com ‹ › pelos alvos; usa **Próximo com problema** para achar bloqueios.
9. Lê o alerta de resumo ("N ações serão criadas") e o aviso de duplicidade, se houver.
10. Clica em **Disparar N ações** → toast "N ações enfileiradas — enviando…".
11. A tela troca para **Acompanhamento do lote**, com polling de 5 s.
12. (opcional) **Baixar JSON** / **Baixar CSV**.
13. **Novo disparo** para começar outro lote.

### F2 — Negativação por lista de contratos colada (fan-out por contrato)

1. Card 1: **Tipo de Ação** = `Negativação` → grão vira **contrato**.
2. Card 2: abre **Colar contratos**, cola os números (um por linha), clica **Aplicar**.
3. A lista é filtrada pelos contatos donos; a seleção recebe **exatamente** aqueles contratos em cada contato.
4. Lê o painel de resultado: encontrados / não encontrados / sem contato dono.
5. (opcional) Abre a setinha de um contato para conferir os contratos marcados e desmarcar algum.
6. Card 3: escreve o conteúdo do payload.
7. **Pré-visualizar** → o resumo diz "N ações serão criadas (uma por contrato selecionado de M contato(s))".
8. Se `N > 5.000`, aparece o alerta destrutivo de lote grande (por **AÇÕES**, não por contatos).
9. **Disparar**.

### F3 — Lista de CPFs vinda de planilha

1. Card 2 → **Colar documentos**, cola a coluna de CPF/CNPJ, **Aplicar**.
2. Lê `{n} encontrado(s) · {m} não encontrado(s)` e, se houver, a lista dos não encontrados (âmbar).
3. Se o resultado for 0 encontrados, a lista **não** é filtrada e o aviso vermelho explica isso.
4. Seleciona (página, todos ou manual) e segue o fluxo F1.

### F4 — Combinação de documentos + contratos

1. Aplica os dois blocos de colagem.
2. A lista passa a mostrar a **interseção**.
3. Se a interseção for vazia, aparece o aviso vermelho e **nenhum** dos dois filtros é aplicado.
4. "Limpar" de um bloco não afeta o outro.

### F5 — Override de blocklist (owner/admin)

1. Card 3: desliga o `Switch` **Respeitar blocklist**.
2. Aparece o alerta destrutivo "Você está forçando o envio ignorando a blocklist deste lote — auditado."
3. A prévia deixa de marcar os contatos bloqueados como "Não será enviado" (o `would_send` da EF já considera o override).
4. Ao disparar, `source_detail` grava `blocklist_overridden`, `overridden_by`, `overridden_at`.
5. O trigger no banco valida se o autor é owner/admin ativo e **rejeita** caso contrário.

### F6 — Auditoria de um disparo antigo

1. Aba **Histórico**.
2. Localiza a entrada (paginação de 25).
3. Lê tipo/canal/quantidade/ator/data e os chips por status; identifica a badge `override` se houver.
4. Expande → vê o lote inteiro (mesma tela do acompanhamento) ou a ação avulsa.
5. Expande a linha de uma ação → payload/retorno redigidos, erro, Referência e Auditoria.
6. **Copiar JSON** da ação, ou **Baixar JSON/CSV** do lote.

### F7 — Caminho de erro: lote parcial

1. Durante o bulk-insert, um chunk (de 500) falha após outros terem commitado.
2. O hook tenta apagar as `Pendente` daquele `batch_id` via RPC.
3. Toast destrutivo: "Falha no disparo — lote parcial revertido … (lote `abc12345`). Pode tentar disparar novamente."
4. A tela **permanece** no estado de prévia (`batchId` continua `null`), permitindo novo disparo com `batch_id` novo.

### F8 — Caminho de erro: nenhum alvo cobrável

1. O usuário seleciona contatos cujos títulos estão todos pagos/removidos.
2. **Pré-visualizar** resolve 0 alvos.
3. Aparece o alerta destrutivo: "Nenhum dos {m} contato(s) selecionado(s) tem título cobrável — não há ação a disparar. Ajuste a seleção."
4. O botão **Disparar** permanece desabilitado.

---

# PARTE B — TEMPLATES DE MENSAGEM

## B0. Identidade

**Fonte:** `src/pages/MessageTemplatesPage.tsx`

| Atributo | Valor no código |
|---|---|
| Rota | `/templates` |
| Título (H1) | `Templates de Mensagem` — `text-3xl font-bold flex items-center gap-2` |
| Ícone do H1 | `MessageSquareText` (`h-8 w-8`) |
| Subtítulo | "Gerencie templates HSM para WhatsApp e outros canais" (`text-muted-foreground`) |
| Container | `space-y-6 p-6` (a página traz seu **próprio padding**, diferente de Disparos) |
| Componentes exportados | `export function MessageTemplatesPage()` e `export default` |
| Tabela no banco | `message_templates` (schema da org) |

**Permissões lidas de `useOrganization()`:**

| Flag | Regra | O que libera |
|---|---|---|
| `canWrite` | `hasPermission("templates:write")` | Botões "Novo Template", "Sincronizar Meta", itens "Editar" e "Duplicar" do menu |
| `canDelete` | `hasPermission("templates:delete")` | Item "Excluir", barra de seleção em massa e "Excluir Selecionados" |
| `canToggleActive` | `currentRole === "admin" \|\| currentRole === "owner"` | Item "Ativar"/"Desativar" |

> `canToggleActive` **não** usa `hasPermission` — é uma checagem direta de papel. ⚠️ A confirmar: essa assimetria é intencional ou dívida técnica.

---

## B1. Objetivo e personas

### B1.1 O problema que a tela resolve

Templates de mensagem são o **conteúdo reutilizável** das réguas de cobrança (e, no caso do RCS, também dos Disparos). A tela concentra dois mundos que convivem na mesma tabela:

| Origem (`source`) | Quem cria | Editável? | Como chega |
|---|---|---|---|
| `local` | O próprio usuário, nesta tela | **Sim** — CRUD completo | Botão "Novo Template" |
| `meta` | A Meta/WhatsApp (via HyperFlow) | **Não** — somente leitura | Sincronização (`sync-meta-templates`, cron diário 6h UTC + botão manual) |

### B1.2 Personas

| Persona | Uso |
|---|---|
| **Analista de cobrança / redator** | Cria e edita templates locais (texto, RCS, e-mail HTML), testa a prévia com dados de exemplo |
| **Gestor de canal WhatsApp** | Sincroniza e audita os templates Meta, acompanha `APPROVED`/`PENDING`/`REJECTED` e motivo de rejeição |
| **Designer de RCS** | Monta cartões e carrosséis, faz upload de imagens, testa a prévia visual |
| **Administrador** | Ativa/desativa templates (controla o que aparece nos seletores de régua), exclui em massa |

### B1.3 Modelo mental imposto pela tela

- **Clique na linha/card tem comportamento condicional:** template `meta` abre **prévia read-only**; template local abre o **modal de edição**.
- **Template inativo não some** — fica com `opacity-60` e badge `Inativo`, e deixa de aparecer nos seletores de régua.
- O **canal** define completamente a experiência de edição: texto simples, construtor RCS ou editor HTML de e-mail.
- **Excluir é irreversível** e pode afetar réguas — o próprio diálogo de confirmação diz isso.

---

## B2. Anatomia visual

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ [MessageSquareText] Templates de Mensagem                                     │
│ Gerencie templates HSM para WhatsApp e outros canais                          │
│                    [⟳ Atualizar lista]  [RefreshCw Sincronizar Meta]  [+ Novo Template] │
├──────────────────────────────────────────────────────────────────────────────┤
│ ┌ Card (só quando há seleção e canDelete) ─────────────────────────────────┐ │
│ │ [Check] N template(s) selecionado(s)        [X Limpar] [Trash Excluir …] │ │
│ └───────────────────────────────────────────────────────────────────────────┘ │
│ ┌ Card ─────────────────────────────────────────────────────────────────────┐ │
│ │ ( Todos [n] ) ( Meta [n] ) ( Locais [n] )         ← Tabs de origem        │ │
│ │ [🔍 Buscar templates...]                             [ViewToggle lista/grade] │
│ └───────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
│ VISÃO LISTA:                                                                  │
│ ┌ Card > Table ─────────────────────────────────────────────────────────────┐ │
│ │ [☐] Nome | Canal | Origem | Conteúdo | Status | Atualizado em | [⋯]      │ │
│ └───────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
│ VISÃO GRADE (grid-cols-1 md:2 lg:3 gap-4):                                    │
│ ┌ Card ─────┐ ┌ Card ─────┐ ┌ Card ─────┐                                     │
│ │ ☐   ⋯     │ │ ☐   ⋯     │ │ ☐   ⋯     │                                     │
│ │ Nome      │ │           │ │           │                                     │
│ │ descrição │ │           │ │           │                                     │
│ │ badges    │ │           │ │           │                                     │
│ │ conteúdo… │ │           │ │           │                                     │
│ │ Atualizado│ │           │ │           │                                     │
│ └───────────┘ └───────────┘ └───────────┘                                     │
└──────────────────────────────────────────────────────────────────────────────┘
```

### B2.1 Cabeçalho e ações globais

| Ação | Componente | Condição | Comportamento |
|---|---|---|---|
| Atualizar lista | `RefreshButton` dentro de `Tooltip` (conteúdo `Atualizar lista`) | sempre | `refetch()`; anima enquanto `isFetching` |
| Sincronizar Meta | `Button variant="outline"` + `RefreshCw` (gira quando pendente) | `canWrite` | Invoca a EF `sync-meta-templates`; desabilitado enquanto pendente |
| Novo Template | `Button` primário + `Plus` | `canWrite` | Abre `TemplateDialog` em modo criação |

**Toasts da sincronização (`useSyncMetaTemplates`):**

| Situação | Título | Descrição |
|---|---|---|
| Sucesso | `Templates sincronizados` | `{synced} template(s) sincronizado(s), {removed ?? deactivated} removido(s).` |
| Erro | `Erro ao sincronizar templates` (`destructive`) | mensagem do erro |

### B2.2 Barra de seleção em massa

Renderizada **apenas** quando `selectedIds.size > 0 && canDelete`. Visual: `Card className="border-primary bg-primary/5"`, `CardContent className="py-3"`.

| Elemento | Detalhe |
|---|---|
| Ícone | `Check` (`h-5 w-5 text-primary`) |
| Texto | `{n} template selecionado` / `{n} templates selecionados` (pluralização dupla) |
| Botão | `Limpar` (`outline sm`, ícone `X`) |
| Botão | `Excluir Selecionados` (`destructive sm`, ícone `Trash2`) |

### B2.3 Estado de carregamento da página

`isLoading` substitui **toda** a página por: um `Skeleton h-10 w-64` + `Skeleton h-10 w-32` no cabeçalho, e um `Card` com 5 `Skeleton h-16 w-full`.

---

## B3. Lista de templates

### B3.1 Abas de origem (filtro `sourceFilter`)

`Tabs` com três `TabsTrigger`, cada um com `Badge secondary` de contagem (`ml-1.5 text-xs px-1.5 py-0`):

| Valor | Rótulo | Contagem |
|---|---|---|
| `all` | **Todos** | `templates.length` |
| `meta` | **Meta** | templates com `source === "meta"` |
| `local` | **Locais** | templates com `source !== "meta"` |

### B3.2 Busca

| Atributo | Valor |
|---|---|
| Componente | `Input` com ícone `Search` posicionado à esquerda (`absolute left-3`, `pl-10`) |
| Container | `relative flex-1 max-w-md` |
| Placeholder | `Buscar templates...` |
| Campos varridos | `name`, `content`, `channel` (todos em lowercase, `includes`) |
| Filtragem | **Client-side**, sobre a lista já carregada |

### B3.3 Alternância de visão

`ViewToggle view={view} onViewChange={setView}` — a preferência é **persistida** via `useViewPreference("message-templates-view", "list")`. Valores: `list` (default) e grade.

### B3.4 Colunas da visão LISTA

| # | Coluna | Largura | Conteúdo |
|---|---|---|---|
| 0 | checkbox | `w-12` | Seleção; `aria-label` `Selecionar todos` no cabeçalho e `Selecionar {nome}` na linha |
| 1 | **Nome** | — | `name` (`font-medium`) + `description` em `text-sm text-muted-foreground line-clamp-1` |
| 2 | **Canal** | — | `Badge outline` colorido (ver B3.5) |
| 3 | **Origem** | — | Badges de origem (ver B3.6) |
| 4 | **Conteúdo** | — | `content` em `text-sm text-muted-foreground line-clamp-2 max-w-md` |
| 5 | **Status** | — | `Badge variant={is_active ? "default" : "secondary"}` com texto `Ativo` / `Inativo` |
| 6 | **Atualizado em** | — | `updated_at` em `dd/MM/yyyy HH:mm` (locale `ptBR`), ou `-`. Para Meta, segunda linha `Sync: dd/MM HH:mm` (`text-xs text-muted-foreground/70`) |
| 7 | menu | `w-12` | `DropdownMenu` com `MoreHorizontal` |

**Estilo da linha:** `cursor-pointer hover:bg-muted/50`; `bg-primary/5` quando selecionada; `opacity-60` quando `!is_active`.

**Cliques:** a linha inteira é clicável (`handleTemplateClick`); as células do checkbox e do menu fazem `e.stopPropagation()`.

### B3.5 Badge de canal (`CHANNEL_LABELS`)

| Chave | Rótulo | Cor |
|---|---|---|
| `whatsapp` | WhatsApp | `bg-green-500/10 text-green-600 border-green-500/20` |
| `sms` | SMS | `bg-blue-500/10 text-blue-600 border-blue-500/20` |
| `email` | E-mail | `bg-purple-500/10 text-purple-600 border-purple-500/20` |
| `voice` | Voz | `bg-orange-500/10 text-orange-600 border-orange-500/20` |
| *(fallback)* | valor cru do canal | `bg-muted text-muted-foreground` |

> **Achado para o redesign:** o canal **`rcs` não está em `CHANNEL_LABELS`** — um template de RCS aparece na lista com o badge cinza escrito `rcs` (minúsculo, valor cru), embora o modal de criação ofereça RCS como opção. É uma inconsistência visível.

### B3.6 Badges de origem e aprovação Meta (`getOriginBadges`)

**Template local:** um único `Badge variant="secondary"` com o texto `Local`.

**Template Meta:** grupo `flex items-center gap-1 flex-wrap` com até três badges:

| Badge | Texto | Cor |
|---|---|---|
| 1 | `Meta` | `bg-blue-500/10 text-blue-600 border-blue-500/20` (`variant="outline"`) |
| 2 | Status Meta cru (`APPROVED` / `PENDING` / `REJECTED`) | ver tabela abaixo |
| 3 | `meta_category` (ex.: `UTILITY`, `MARKETING`) | `Badge variant="secondary" text-xs` |

**Cores do status Meta (`META_STATUS_COLORS`):**

| Status | Cor | Significado |
|---|---|---|
| `APPROVED` | `bg-green-500/10 text-green-600 border-green-500/20` | Aprovado pela Meta — **único** que pode ser usado como Template Meta no Disparo |
| `PENDING` | `bg-amber-500/10 text-amber-600 border-amber-500/20` | Em análise |
| `REJECTED` | `bg-red-500/10 text-red-600 border-red-500/20` | Rejeitado (motivo aparece na prévia) |
| *(outro)* | `bg-muted text-muted-foreground` | Status não mapeado, exibido cru |

> Os status são exibidos **em inglês e maiúsculas**, exatamente como vêm da Meta — não há tradução.

### B3.7 Menu de ações (`DropdownMenu`, `align="end"`)

Idêntico nas visões lista e grade.

| Item | Ícone | Condição | Ação |
|---|---|---|---|
| **Visualizar** | `Eye` | `source === "meta"` | Abre `MetaTemplatePreview` |
| **Resincronizar** | `RefreshCw` (gira quando pendente) | `source === "meta"` | `syncMeta.mutate()` — sincroniza **todos**, não só aquele |
| **Editar** | `Pencil` | local **e** `canWrite` | Abre `TemplateDialog` com o template |
| **Duplicar** | `Copy` | local **e** `canWrite` | Abre o modal com `id: ""` e nome `{nome} (Cópia)` |
| **Ativar** / **Desativar** | `Eye` / `EyeOff` | `canToggleActive` | `toggleActive.mutate({ id, is_active: !is_active })` — **sem confirmação** |
| **Ver Uso em Reguas** | `GitBranch` | sempre | Abre `TemplateUsageDialog` |
| *(separador)* | — | `canDelete` | `DropdownMenuSeparator` |
| **Excluir** | `Trash2` | `canDelete` | Abre o `AlertDialog` de confirmação — item com `className="text-destructive"` |

**Toasts de ativar/desativar:**

| Ação | Título | Descrição |
|---|---|---|
| Ativar | `Template ativado` | `O template está disponível para uso em réguas.` |
| Desativar | `Template desativado` | `O template não aparecerá mais nos seletores de régua.` |
| Erro | `Erro ao alterar status do template` (`destructive`) | mensagem |

> **Achado para o redesign:** "Resincronizar" no menu de um template específico dispara a sincronização **global** — o rótulo sugere escopo individual que não existe.

### B3.8 Visão GRADE

`Card` com `cursor-pointer hover:border-primary/50 transition-colors relative`.

| Elemento | Posição | Detalhe |
|---|---|---|
| Checkbox | `absolute top-3 left-3 z-10` | Com `stopPropagation` |
| `CardHeader` | `pb-2 pt-10` | Padding-top de 40px para não colidir com o checkbox |
| Título | — | `CardTitle text-base` = nome |
| Descrição | — | `line-clamp-1` |
| Menu | canto superior direito | `Button ghost icon h-8 w-8` |
| Badges | `CardContent` | canal + origem + Ativo/Inativo, em `flex flex-wrap gap-2` |
| Conteúdo | — | `text-sm text-muted-foreground line-clamp-3` |
| Rodapé | — | `Atualizado em {dd/MM/yyyy}` + (Meta) ` \| Sync: dd/MM HH:mm` |

Estados: `border-primary bg-primary/5` quando selecionado, `opacity-60` quando inativo.

### B3.9 Seleção

| Ação | Comportamento |
|---|---|
| Checkbox da linha/card | Alterna o id no `Set<string>` |
| Checkbox do cabeçalho (só na lista) | `checked` quando `selectedIds.size === filteredTemplates.length && length > 0`; alterna entre "tudo" e "nada" **sobre a lista FILTRADA** |
| `Limpar` | Zera o `Set` |

> ⚠️ Nota de UX: **não há estado `indeterminate`** no checkbox do cabeçalho — com seleção parcial ele aparece desmarcado.
> ⚠️ A seleção **não é limpa** ao mudar de aba ou de busca. É possível ter templates selecionados que não estão visíveis, e "Excluir Selecionados" os apaga.

### B3.10 Estado vazio

`Card` com `CardContent className="py-12"` e conteúdo centralizado:

| Elemento | Valor |
|---|---|
| Ícone | `MessageSquareText` (`h-12 w-12 mx-auto text-muted-foreground mb-4`) |
| Título | `Nenhum template encontrado` (`text-lg font-semibold`) |
| Descrição (com busca) | `Tente ajustar sua busca.` |
| Descrição (sem busca) | `Crie seu primeiro template de mensagem.` |
| CTA | Botão `Criar Template` (+ `Plus`) — só quando **não** há busca ativa **e** `canWrite` |

---

## B4. Modal de template (`TemplateDialog`)

**Fonte:** `src/components/message-templates/TemplateDialog.tsx`

### B4.1 Objetivo, gatilho e layout

| Atributo | Valor |
|---|---|
| Objetivo | Criar ou editar um template **local** (Meta é read-only) |
| Gatilhos | Botão "Novo Template"; "Criar Template" do estado vazio; item "Editar"; item "Duplicar"; clique na linha/card de template local |
| Modo | `isEditing = !!template?.id` — duplicar passa `id: ""`, logo cai em **criação** |
| Largura | `max-w-2xl` normalmente; **`max-w-5xl` quando o canal é RCS** (abre espaço para o builder + prévia lado a lado) |
| Altura | `max-h-[90vh] overflow-y-auto` |
| Título | `Editar Template` / `Novo Template de Mensagem` |
| Descrição | `Atualize as informações do template.` / `Crie um novo template de mensagem para usar nas réguas de cobrança.` |
| Corpo | `space-y-4 py-4` |

### B4.2 Campos comuns a todos os canais

| Campo | Componente | Obrigatório | Placeholder | Observação |
|---|---|---|---|---|
| **Nome do Template \*** | `Input id="name"` | **Sim** (`name.trim()`) | `Ex: Lembrete de Vencimento` | — |
| **Descrição** | `Input id="description"` | Não | `Descrição opcional do template` | — |
| **Canal \*** | `Select` | Sim (default `whatsapp`) | `Selecione o canal` | 5 opções (B4.3) |
| **Template Ativo** | `Switch id="is_active"` | — | — | Default `true`. Container `flex items-center justify-between rounded-lg border p-3`. Texto de apoio: "Templates inativos não aparecem na seleção das réguas." |

### B4.3 Opções de canal (`CHANNELS`)

| Valor | Rótulo | Experiência de edição |
|---|---|---|
| `whatsapp` | WhatsApp | `RichVariableInput` (texto) |
| `email` | E-mail | `EmailTemplateEditor` + `EmailHtmlPreview` |
| `rcs` | RCS | Seletor de formato + `RcsCardBuilder` / `RcsCarouselBuilder` |
| `sms` | SMS | `RichVariableInput` (texto) |
| `voice` | Voz | `RichVariableInput` (texto) |

> Trocar o canal **não** limpa o conteúdo já digitado — o mesmo `formData.content` é reaproveitado entre canais.

### B4.4 Corpo por canal — texto (WhatsApp / SMS / Voz)

`RichVariableInput` com:

| Prop | Valor |
|---|---|
| `variableContext` | `"workflow"` |
| `label` | `Conteúdo do Template *` |
| `description` | `Digite {{ para inserir variáveis dinâmicas` |
| `placeholder` | `Olá {{contact.name}}, seu título no valor de {{title.current_value}} vence em {{title.due_date}}.` |
| `rows` | `5` |

**Bloco "Variáveis Detectadas"** (só quando `formData.variables.length > 0`): `Label` cinza + `flex flex-wrap gap-1.5` de `Badge variant="secondary" className="font-mono text-xs"` com o texto `{{chave}}`.

**Extração (`extractVariables`):** regex `/\{\{([^}]+)\}\}/g`, deduplicada, recalculada **a cada mudança** de conteúdo. Vai para a coluna `variables` do template.

### B4.5 Corpo por canal — RCS

Antes do builder, um `Select` **Formato \***:

| Valor | Rótulo exibido |
|---|---|
| `simples` | `Simples (texto + imagem opcional + resposta rápida)` |
| `card` | `Card (imagem + título + descrição + botões)` |
| `carousel` | `Carrossel (2 a 10 cards)` |

Depois: `RcsCarouselBuilder` (formato carrossel) ou `RcsCardBuilder` (simples/card). Detalhes completos em **B6**.

> No RCS, o bloco "Variáveis Detectadas" **não** é exibido (fica fora do ramo `isRcs`).

### B4.6 Corpo por canal — E-mail

`EmailTemplateEditor` seguido de `EmailHtmlPreview` (o modal mostra os dois empilhados). Detalhes em **B7**.

### B4.7 Validação de submissão (`canSubmit`)

```
canSubmit =
     name.trim() não vazio
  E  (isRcs ? rcsValid : content.trim() não vazio)
  E  (channel !== "email" OU renderEmailHtml(content).errors.length === 0)
```

**`rcsValid` por formato:**

| Formato | Regra |
|---|---|
| `simples` | `body.trim()` não vazio |
| `card` | `imageUrl` preenchido **E** `body.trim()` não vazio |
| `carousel` | `validateRcsCarousel(cards) === null` |

**`validateRcsCarousel` — mensagens de erro (texto exato):**

| Condição | Mensagem |
|---|---|
| `cards.length < 2` | `Carrossel exige no mínimo 2 cards.` |
| `cards.length > 10` | `Carrossel aceita no máximo 10 cards.` |
| Algum card sem imagem | `Cada card do carrossel exige uma imagem.` |
| Algum card sem texto | `Cada card do carrossel exige um texto.` |

> ⚠️ Observação de UX: essa função **retorna** a mensagem, mas o `TemplateDialog` só a usa como booleano — a string **não é exibida**. Os avisos que o usuário vê são os inline do próprio builder (`Adicione ao menos 2 cards.`, `Imagem obrigatória em cada card.`). O botão simplesmente fica desabilitado.

### B4.8 Payload gravado

| Canal | `content` | `variables` | `meta_components` | `source` |
|---|---|---|---|---|
| Não-RCS | `formData.content` | extraídas do conteúdo | não enviado | (default do banco) |
| RCS simples/card | `rcsCard.body` | extraídas de `rcsCard.body` | `buildRcsMetaComponents(rcsCard)` | `template?.source ?? "local"` |
| RCS carrossel | `rcsCard.cards[0]?.body ?? ""` | extraídas da concatenação de **título + corpo + texto e valor do botão** de **todos** os cards | `buildRcsMetaComponents(rcsCard)` | `local` |

### B4.9 Rodapé e estados de submissão

| Botão | Variante | Estado |
|---|---|---|
| `Cancelar` | `outline` | Desabilitado enquanto `isPending` |
| `Salvar Alterações` / `Criar Template` | primário | Desabilitado enquanto `isPending` ou `!canSubmit`; mostra `Loader2 animate-spin` quando pendente |

**Toasts:**

| Situação | Título | Descrição |
|---|---|---|
| Criação OK | `Template criado` | `O template de mensagem foi salvo com sucesso.` |
| Edição OK | `Template atualizado` | `As alterações foram salvas com sucesso.` |
| Erro de criação | `Erro ao criar template` (`destructive`) | mensagem |
| Erro de edição | `Erro ao atualizar template` (`destructive`) | mensagem |

**Reset:** um `useEffect` com deps `[template, open]` repopula o formulário sempre que o modal abre ou o template muda — inclusive fazendo `parseRcsMetaComponents` para reconstruir o estado do builder de RCS a partir do `meta_components` salvo.

### B4.10 Limites de caracteres por canal (o que a tela realmente aplica)

| Canal / campo | Limite | Onde é aplicado | Como aparece |
|---|---|---|---|
| RCS **simples** — Texto da mensagem | **3.000** (`MAX_RCS_SIMPLES_BODY`) | Truncado no `onChange` (`body.slice(0, 3000)`) | Contador no rótulo: `Texto da mensagem (N/3000)` |
| RCS **card** — Descrição | **sem limite na tela** | — | Rótulo apenas `Descrição` |
| RCS **carrossel** — Texto de cada card | **1.000** (`MAX_RCS_CAROUSEL_BODY`) | Truncado no `onChange` | Contador: `Texto (N/1000)` |
| RCS — Texto do botão | **20** (`MAX_RCS_BUTTON_TEXT`) | `maxLength={20}` **e** `slice(0,20)` no `onChange` | Contador: `Texto (N/20)` |
| RCS — nº de botões (card/simples) | **3** (`MAX_RCS_BUTTONS`) | Botão "Adicionar botão" desabilitado | Contador: `Botões (N/3)` |
| RCS — nº de cards do carrossel | **2 a 10** | "Adicionar card" desabilitado no teto | Contador: `Cards (N/10)` + aviso de mínimo |
| WhatsApp / SMS / Voz | **nenhum limite na tela** | — | — |
| E-mail | **nenhum limite de caracteres**; a validação é de **HTML válido** | `renderEmailHtml` | Lista de erros abaixo do campo |

> **Achado importante para o redesign:** não existe **limite** de caracteres para WhatsApp, SMS nem Voz nesta tela, embora o backend tenha `BODY_CHAR_LIMITS` por canal (CLAUDE.md da Torre, regra 45 — estouro vira **erro explícito** no envio). O `RichVariableInput` mostra um contador puro (`{n} caracteres`), sem teto nem cor de alerta. O único canal com limite visual real é o RCS.

---

## B5. Inserção de variáveis (chips) e prévia com dados reais

### B5.1 `RichVariableInput` — o editor de variáveis

**Fonte:** `src/components/ui/rich-variable-input/index.tsx`, `utils.ts`, `types.ts`.

Editor **TipTap** (ProseMirror) configurado como **texto puro**: heading, listas, blockquote, code block, hr, **bold, italic, strike e code estão todos desabilitados**, "porque WhatsApp, SMS e Email não suportam formatação markdown".

**Extensão própria `VariableNode`:**

| Propriedade | Valor |
|---|---|
| `name` | `variableNode` |
| `group` / `inline` | `inline` / `true` |
| `atom` | `true` — **indivisível**: o chip é apagado inteiro, nunca "pela metade" |
| `selectable` | `true` |
| Atributo | `id` = a chave da variável (ex.: `contact.name`) |
| Render | `<span data-variable="{key}" class="variable-chip" contenteditable="false">{rótulo PT-BR}</span>` |

**Rótulo do chip (`getVariableLabelFromKey`) — ordem de resolução:**

1. Busca a chave em `INTEGRATION_VARIABLES` → usa o `label` canônico (ex.: `contact.name` → **Nome do Cliente**).
2. Se a chave contém `.custom.` → pega o sufixo, troca `_` por espaço e capitaliza (ex.: `contact.custom.etapa_negociacao` → **Etapa Negociacao**).
3. Fallback: pega a última parte da chave e humaniza.

### B5.2 Autocomplete por `{{`

| Gatilho | Digitar `{{` no editor |
|---|---|
| Painel | `absolute z-[100] w-[320px] bg-popover border rounded-md shadow-lg`, posicionado pelas coordenadas do cursor (`coordsAtPos`), com clamp à direita (`containerRect.width - 320`) |
| Lista | `max-h-[250px] overflow-y-auto p-1` |
| Agrupamento | Por **categoria**, com cabeçalho `sticky top-0` em `text-xs font-semibold uppercase tracking-wider` |
| Item | `label` em `font-medium` + segunda linha `Ex: {exemplo}` em `text-xs` |
| Item selecionado | `bg-primary text-primary-foreground` |
| Busca | O texto digitado após `{{` filtra por **chave, rótulo ou categoria** (`filterVariables`) |

**Teclado (`handleKeyDown`):**

| Tecla | Ação |
|---|---|
| `ArrowDown` | Próximo item (circular) |
| `ArrowUp` | Item anterior (circular) |
| `Tab` **ou** `Enter` | Insere o item selecionado |
| `Escape` | Fecha as sugestões |

**Fechamento:** clique fora (listener de `mousedown` em `document`) ou quando o texto até o cursor deixa de ter um `{{` sem `}}`.

**Inserção:** apaga o texto do gatilho (`{{` + query) e insere o nó `variableNode` no lugar.

**Rótulos de categoria no autocomplete (`categoryLabels` local):** `contato`→Contato, `titulo`→Título, `contrato`→Contrato, `financeiro`→Financeiro, `carteira`→Carteira, `pagamento`→Pagamento, `sistema`→Sistema, `outros`→Outros.

> ⚠️ Inconsistência: este mapa **local** não cobre `suprimento`, `organizacao`, `acao`, `campos_customizados` nem `variaveis_personalizadas` — que existem em `VARIABLE_CATEGORY_LABELS` (`integration-variables.ts`). Nessas categorias o cabeçalho do autocomplete mostra a **chave crua** (ex.: `suprimento`, `organizacao`).

### B5.3 Botão explícito de inserção (`VariableInserter`)

Renderizado **apenas quando a prop `label` é passada** — fica na mesma linha do rótulo, alinhado à direita. Insere a variável na posição do cursor.

Também é usado, isoladamente, pelo `EmailTemplateEditor` (com `context="workflow"`).

⚠️ A confirmar: a UI interna do `VariableInserter` (vem de `src/components/reguas-cobranca/config-forms/SharedComponents/VariableInserter`) não foi lida neste documento.

### B5.4 Rodapé do editor

| Elemento | Condição | Texto |
|---|---|---|
| Dica | `!compact` | `Digite {{ para inserir variáveis` (com `{{` em `<code>` sobre `bg-muted`) |
| Contador | `!compact` | `{n} caracteres` |
| Indicador | `!compact` e o valor contém `{{` | `✓ Contém variáveis` (`text-primary`) |

### B5.5 Serialização (ida e volta)

| Função | O que faz |
|---|---|
| `parseTemplateToContent(template)` | Converte a string `{{chave}}` em documento TipTap; **cada `\n` vira um parágrafo** |
| `serializeContentToTemplate(content)` | Volta para string: `variableNode` → `{{id}}`; cada parágrafo adiciona `\n`; o `\n` final é removido |
| `getPlainText(content)` | Texto puro, mantendo `{{chave}}` |

**Sincronização externa:** um `useEffect` só reescreve o conteúdo do editor quando ele **não está focado** e o valor serializado difere — evita brigar com a digitação.

### B5.6 Validação de variável desconhecida

`findUnknownVariables(template)` (em `utils.ts`) devolve as chaves `{{...}}` que **não** são conhecidas, ignorando:

- qualquer chave com `.custom.` (campos personalizados, variam por org);
- qualquer chave iniciada por `var.` (variáveis personalizadas da org);
- tudo que está em `ALL_VARIABLE_KEYS` (catálogo + aliases snake_case).

⚠️ A confirmar: essa função **não é chamada** pelo `TemplateDialog` nem pelo `DisparoComposer` — não localizei um ponto na tela de Templates onde o aviso de "variável desconhecida" seja exibido ao usuário.

### B5.7 Prévia com variáveis — as três estratégias

| Componente | Estratégia | Dados usados |
|---|---|---|
| `VariablePreview` | Renderiza o texto com as variáveis como **chips visuais** (`.variable-chip`), mostrando o **rótulo** em vez da chave | Nenhum dado — é decorativa |
| `replaceVariablesWithExamples` / `replaceWithExamples` | Substitui `{{chave}}` pelo **exemplo estático** do catálogo | `VARIABLE_EXAMPLES` |
| `useTemplatePreview` → `createTemplatePreview` | **Resolve de verdade** as variáveis personalizadas compostas (`{{var.*}}`), usando `useVariables({context:"workflow"})` + `customVariables` | Definições reais da org |

**`VariablePreview` — classes CSS:**

| Situação | Classe |
|---|---|
| Variável do catálogo | `variable-chip` |
| Variável de campo personalizado (`.custom.`) | `variable-chip variable-chip-custom` |

**`VariablePreviewBlock`** é a versão em bloco (`p-3 bg-muted/30 rounded-lg text-sm`), com placeholder `Nenhum conteúdo definido` quando vazio.

**`replaceWithExamples` (catálogo) — três comportamentos:**

| Caso | Resultado |
|---|---|
| Chave estática conhecida | O exemplo do catálogo (ex.: `João Silva Santos`) |
| Chave de namespace dinâmico | Marcador legível: `[Campo personalizado do contato: etapa]` |
| Chave desconhecida (typo) | Sai **crua** de propósito — "é assim que o erro fica visível" |

### B5.8 Prévia de variáveis compostas (`{{var.*}}`)

Introduzida pelo card IAF-6862. A regra do frontend é: **só quando o texto contém `{{var.`** o componente troca de caminho e vai buscar as definições reais.

| Componente | Gate | Caminho alternativo |
|---|---|---|
| `TemplateMessagePreview` | `channel !== "email"` **e** `/\{\{\s*var\./.test(message)` | `ComposedMessagePreview` com `resolver.render(message)` |
| `EmailHtmlPreview` | `!resolved && !examples` **e** o texto tem `{{var.` | `CustomEmailPreview` com `resolver.resolve` |
| `EmailSubjectPreview` | idem, para o assunto | `CustomEmailSubject` |

**Estados desses componentes:**

| Estado | Render |
|---|---|
| Carregando | `Carregando variáveis…` (`text-sm text-muted-foreground`) |
| Erro | `Não foi possível carregar as variáveis da prévia.` com `role="alert"` e `text-destructive` |
| Sucesso | A mensagem renderizada |

### B5.9 Prévia com um cliente real (`useCustomerTemplatePreview`)

| Atributo | Valor |
|---|---|
| Query key | `["customer-template-preview", orgSlug, contactId]` |
| Gate | `enabled && orgSlug && orgClient && contactId` |
| `staleTime` / `gcTime` / `retry` | `30 s` / `0` (não cacheia após desmontar) / `false` (não repete) |
| Erro sem contato | `Selecione um cliente para visualizar a variável.` |
| Carga | `loadCustomerTemplatePreview(orgClient, contactId)` (`src/lib/customer-template-preview`) |

⚠️ A confirmar: este hook **não é usado** por nenhum dos componentes lidos de `message-templates/` — pelo nome e pela mensagem de erro, pertence à tela de **Variáveis Personalizadas** (Configurações). Se o redesign quiser "prévia com um cliente de verdade" dentro do modal de template, essa peça já existe e está disponível.

---

## B6. Construtor RCS: cartão e carrossel

**Fontes:** `RcsCardBuilder.tsx`, `RcsCarouselBuilder.tsx`, `RcsImagePicker.tsx`, `RcsPreview.tsx`, `rcs-meta.ts`, `useUploadRcsImage.ts`.

### B6.1 Os três formatos

| Formato | Peças | Campos obrigatórios |
|---|---|---|
| `simples` | Imagem **opcional** + texto + botões de resposta rápida | Texto |
| `card` | Imagem **obrigatória** + título + descrição + botões | Imagem **e** descrição |
| `carousel` | 2 a 10 cards, cada um com imagem + título + texto + 1 botão | Cada card: imagem **e** texto |

O formato é gravado como um componente `{ type: "FORMAT", value: "simples"|"card"|"carousel" }` dentro de `meta_components`.

> Compatibilidade: ao ler um template antigo, o valor `"common"` é normalizado para `"simples"`.

### B6.2 Layout do `RcsCardBuilder`

`grid gap-4 md:grid-cols-2` — **editor à esquerda, prévia ao vivo à direita** (`md:pt-6`). Em telas estreitas, empilha.

### B6.3 Bloco Imagem

| Elemento | Formato `simples` | Formato `card` |
|---|---|---|
| Rótulo | `Imagem (opcional)` | `Imagem do card *` |
| Aviso quando vazia | — | `Imagem obrigatória — o RCS não entrega o card sem imagem.` (`text-xs text-destructive`) |

**Sem imagem:** dois botões `outline` lado a lado:

| Botão | Ícone | Estado pendente |
|---|---|---|
| `Enviar imagem` | `ImagePlus` | `Loader2` girando + `Enviando…`; desabilitado |
| `Galeria` | `Images` | desabilitado durante upload |

O input `type="file"` fica **oculto** (`className="hidden"`), com `accept="image/gif,image/jpeg,image/png"`.

**Com imagem:** miniatura `max-h-40 rounded-md border object-contain` com um botão `destructive icon` circular (`absolute -right-2 -top-2 h-6 w-6 rounded-full`, ícone `X`) para remover, e abaixo um botão `ghost sm` **`Trocar pela galeria`**.

**Legenda de restrições (sempre visível):**

> `.gif, .jpg ou .png · máx. 2MB · ideal 500×300px`

### B6.4 Upload de imagem (`useUploadRcsImage`)

| Regra | Valor |
|---|---|
| Bucket | `rcs-media` (público) |
| Caminho | `{organization.id}/rcs-{Date.now()}.{ext}` |
| MIME aceitos | `image/gif`, `image/jpeg`, `image/png` |
| Tamanho máximo | **2 MB** (`RCS_MAX_SIZE_BYTES`) |
| Resolução recomendada | **500 × 300** — recomendação, **não bloqueia** |
| Upload | `cacheControl: "3600"`, `upsert: true` |
| Pós-upload | `getPublicUrl` + invalidação de `["rcs-images", orgId]` (a galeria se atualiza sozinha) |

**Toasts de erro:**

| Situação | Título | Descrição |
|---|---|---|
| Sem org | `Organização não selecionada` | `Selecione uma organização antes de enviar a imagem.` |
| Tipo inválido | `Arquivo inválido` | `Formato não suportado. Use .gif, .jpg ou .png.` |
| Tamanho | `Arquivo inválido` | `Imagem muito grande. Tamanho máximo: 2MB.` |
| Falha no upload | `Erro no upload` | `Não foi possível enviar a imagem. Tente novamente.` |

### B6.5 Modal `RcsImagePicker` (galeria)

| Atributo | Valor |
|---|---|
| **Objetivo** | Reaproveitar uma imagem já enviada, sem subir de novo |
| **Gatilho** | Botões `Galeria` ou `Trocar pela galeria`, no card e em cada card do carrossel |
| **Largura** | `max-w-2xl max-h-[80vh] overflow-y-auto` |
| **Título** | `Escolher imagem da galeria` |
| **Descrição** | `Selecione uma imagem já enviada anteriormente para reutilizá-la no card.` |
| **Grade** | `grid grid-cols-2 gap-3 sm:grid-cols-3`, miniaturas `aspect-video object-cover` |
| **Item selecionado** | `ring-2 ring-primary` + selo circular com `Check` no canto superior direito |
| **Hover** | `hover:border-primary` |
| **Confirmação** | Nenhuma — clicar **seleciona e fecha** o modal |

**Estados:**

| Estado | Render |
|---|---|
| Carregando | `Loader2` girando, `py-12`, centralizado |
| Erro | `Não foi possível carregar a galeria. Tente novamente.` (`text-destructive`, centralizado) |
| Vazio | Ícone `ImageOff` (`h-8 w-8`) + `Nenhuma imagem enviada ainda.` |
| Com imagens | Grade |

**Fonte dos dados (`useRcsImages`):** `supabase.storage.from("rcs-media").list(orgId, { limit: 100, sortBy: { column: "created_at", order: "desc" } })`, filtrando `.emptyFolderPlaceholder` e entradas sem `id` (subpastas).

> Limite implícito: **as 100 imagens mais recentes**. Não há busca nem paginação na galeria.

### B6.6 Título e corpo

| Campo | Condição | Componente | Rótulo |
|---|---|---|---|
| **Título do card** | só formato `card` | `Input` | `Título do card`, placeholder `Ex: Sua fatura venceu` |
| **Corpo** | sempre | `RichVariableInput` (`rows={4}`, `variableContext="workflow"`) | `simples`: `Texto da mensagem (N/3000)` · `card`: `Descrição` |

Placeholder do corpo: `Olá {{contact.name}}, sua fatura de {{title.current_value}} venceu.`
Descrição: `Digite {{ para inserir variáveis dinâmicas`

### B6.7 Aviso "só imagem" (RCS simples)

**Condição:** formato `simples` **e** `imageUrl` preenchido **e** `body.trim().length === 0`.

`Alert` com `border-warning/50 text-warning` e ícone `AlertTriangle`:

> "Mensagens RCS só com imagem (sem texto) não permitem rastrear falha de entrega — ex.: quando o aparelho não tem suporte a RCS. Adicione um texto para habilitar o rastreio."

> É **aviso**, não bloqueio — mas na prática o `canSubmit` do formato `simples` já exige texto, então o botão fica desabilitado.

### B6.8 Botões (card e simples)

| Atributo | Valor |
|---|---|
| Máximo | **3** (`MAX_RCS_BUTTONS`) |
| Rótulo | `Botões (N/3)` |
| Botão de adicionar | `outline sm` + `Plus`, texto `Adicionar botão`, desabilitado no teto |
| Estado vazio | `Nenhum botão (opcional).` |
| Container de cada botão | `space-y-2 rounded-md border p-3`, cabeçalho `Botão {i+1}` + lixeira `ghost icon h-6 w-6` |

**Campos por botão:** grade de 2 colunas — **Tipo** (`Select` ou campo fixo) e **Texto** (`Input`, `maxLength=20`, contador `(N/20)`, placeholder `Ex: Pagar agora`). Quando o tipo é `url`, aparece um terceiro campo **Link** (`Input`, placeholder `{{pix_link}} ou https://…`).

**Tipos de botão (`RCS_BUTTON_TYPE_LABEL`):**

| Chave | Rótulo exibido | Natureza | Ícone na prévia |
|---|---|---|---|
| `url` | **Link/URL** | Botão URL nativo — abre link | `ExternalLink` |
| `confirmacao_pagamento` | **Confirmação de pagamento** | Postback | `CheckCircle2` |
| `realizar_pagamento` | **Realizar pagamento** | Postback | `CreditCard` |
| `comprovante` | **Enviar comprovante** | Postback | `Receipt` |
| `atendente` | **Falar com atendente** | Postback | `Headset` |

> Todos os postbacks **transferem o atendimento** — a categoria carrega a intenção do cliente, e o flow decide se vai para humano ou IA. O texto do botão é livre.

**Regra de slot (`rcsButtonSlot` / `rcsButtonSlotFor`) — para os formatos `card`:**

| Nº de botões | Posição 0 | Posição 1 | Posição 2 |
|---|---|---|---|
| 1 | livre (url ou postback) | — | — |
| 2 | **postback** | livre | — |
| 3 | **postback** | **postback** | **url** (fixo, campo não editável) |

No formato `simples`, **toda** posição é `postback` — não há botão de link.

**Texto de ajuda exibido:**

| Formato | Texto |
|---|---|
| `simples` | "Botões de resposta rápida: Confirmação de pagamento, Realizar pagamento, Enviar comprovante ou Falar com atendente (todas transferem o atendimento)." |
| `card` | "Regra: 1 = postback ou link · 2 = postback + (link ou postback) · 3 = postback + postback + link. Postback = Confirmação de pagamento, Realizar pagamento, Enviar comprovante ou Falar com atendente (todas transferem o atendimento)." |

**Campo de tipo quando o slot é `url`:** não é um `Select` — é um bloco estático `flex h-9 items-center rounded-md border bg-muted/40 px-3 text-sm text-muted-foreground` com o texto `Link/URL (fixo)`.

**Normalização automática (`normalizeRcsButtons`):** sempre que a lista muda (adicionar, remover, reordenar por remoção), cada botão tem o tipo **corrigido** para o primeiro tipo permitido na sua posição, se o atual for inválido. Isso acontece **em silêncio** — o usuário vê o tipo mudar sozinho.

### B6.9 Construtor de carrossel (`RcsCarouselBuilder`)

Mesmo layout de 2 colunas (editor + prévia).

**Cabeçalho:** `Cards (N/10)` + botão `outline sm` `Adicionar card` (`Plus`), desabilitado em 10.

**Texto de ajuda:**

> "Carrossel: 2 a 10 cards. Cada card exige imagem, texto (até 1000) e aceita até 1 botão (link ou resposta rápida). Com mais de 2 cards, o botão de link (URL) só é permitido no último card."

**Aviso de mínimo:** `Adicione ao menos 2 cards.` (`text-xs text-destructive`) quando `cards.length < 2`.

**Editor de cada card (`CarouselCardEditor`)** — `space-y-3 rounded-md border p-3`:

| Elemento | Detalhe |
|---|---|
| Cabeçalho | `Card {i+1}` + 3 botões `ghost icon h-6 w-6`: `ArrowUp` (desabilitado no primeiro), `ArrowDown` (desabilitado no último), `Trash2` |
| **Imagem \*** | Mesma mecânica do card, miniatura `max-h-32`; aviso `Imagem obrigatória em cada card.` quando vazia |
| **Título** | `Input`, placeholder `Ex: Oferta especial` |
| **Texto** | `RichVariableInput` `rows={3}`, rótulo `Texto (N/1000)`, placeholder `Olá {{contact.name}}…` |
| **Botão** | No máximo **1** por card. Sem botão: `Adicionar botão` (`outline sm` + `Plus`). Com botão: bloco `rounded-md border p-2` com cabeçalho `Botão` + lixeira, grade Tipo/Texto e campo Link quando `url` |

**Regra de URL no carrossel (`rcsCarouselUrlAllowed`):**

```
URL permitido  ⟺  cardCount <= 2  OU  cardIndex === cardCount - 1
```

Ou seja: com 2 cards ou menos, qualquer card pode ter link; com 3+, **só o último**. `normalizeRcsCarouselCards` corrige automaticamente o tipo quando a regra é violada (ex.: ao adicionar um terceiro card).

**Reordenação:** por setas (troca de posição com o vizinho) — **não há drag and drop**.

### B6.10 Prévia RCS (`RcsPreview`)

Renderizada **ao vivo** a partir de `buildRcsMetaComponents(value)` — ou seja, passa pela mesma serialização que será salva, e volta por `parseRcsMetaComponents`. Isso é deliberado: garante que o que se vê é o que se grava.

| Elemento | Detalhe |
|---|---|
| Rótulo | `Pré-visualização` (`text-xs font-medium text-muted-foreground`) |
| Cartão (`CardView`) | `overflow-hidden rounded-2xl border bg-card shadow-sm` |
| Imagem | `h-40 w-full object-cover`; sem imagem e com placeholder, um bloco `bg-muted` com ícone `ImageIcon` (`h-10 w-10`) |
| Título | `break-words text-base font-semibold` — só no formato `card` |
| Corpo | `whitespace-pre-wrap break-words text-[15px] leading-relaxed` |
| Botões | `border-t pt-2`, empilhados, centralizados, `text-sm font-medium text-primary` com o ícone do tipo |
| Variáveis | Renderizadas como **chips** via `VariablePreview` (título, corpo e texto dos botões) |

**Textos de corpo vazio (`emptyBodyLabel`):**

| Contexto | Texto |
|---|---|
| Formato `card` | `Descrição…` |
| Formato `simples` | `Texto da mensagem…` |
| Card de carrossel | `Texto…` |

**Placeholder de imagem:** exibido no formato `card` e em **todos** os cards do carrossel; **não** exibido no formato `simples` (lá a imagem é opcional, então a ausência não é um buraco).

**Carrossel na prévia:** `flex gap-3 overflow-x-auto pb-2`, cada card com `w-64 shrink-0` — rolagem horizontal. Sem cards: bloco `rounded-2xl border bg-card p-6 text-center` com `Adicione cards para visualizar o carrossel.`

**Cartão único:** `mx-auto w-full max-w-md`.

**Regra do corpo herdada do envio:** em `parseRcsMetaComponents`, um `BODY` vazio ou só com espaços conta como **ausente** e **não apaga** o `fallbackBody`. O comentário explica: espelha `pickRcsBodyText` de `supabase/functions/send-message/rcs-body.ts` — "prévia e envio precisam decidir o corpo pela MESMA regra, senão a prévia mostra vazio e o envio manda o fallback".

### B6.11 Serialização RCS → `meta_components`

**`buildRcsMetaComponents(state)` — ordem dos componentes gerados:**

| Formato | Componentes |
|---|---|
| Qualquer | `{ type: "FORMAT", value }` (sempre o primeiro) |
| `carousel` | `{ type: "CAROUSEL", cards: [...] }` e para. Cards vazios (sem imagem, título, corpo e texto de botão) são **filtrados fora**; o corpo é truncado em 1.000 |
| `simples` / `card` | `{ type:"HEADER", format:"IMAGE", text: imageUrl }` (se houver) → `{ type:"TITLE", text }` (só `card`, se preenchido) → `{ type:"BODY", text }` (se preenchido) → `{ type:"BUTTONS", buttons }` (se houver) |

**Serialização de botão (`serializeButton`):**

| Tipo | Saída |
|---|---|
| `url` | `{ type: "URL", text, url }` |
| postback | `{ type: "POSTBACK", category: <chave>, text }` |

O texto é sempre `trim()` + `slice(0, 20)`.

**Parsing (`parseRcsMetaComponents`) — compatibilidade com o legado:**

| Categoria legada | Mapeada para |
|---|---|
| `pagamento` | `confirmacao_pagamento` |
| `humano` | `atendente` |
| categoria desconhecida em botão não-URL | `atendente` (fallback) |

---

## B7. Editor de e-mail HTML e sua prévia/validação

**Fontes:** `EmailTemplateEditor.tsx`, `EmailHtmlPreview.tsx`, `src/lib/email-html.ts` (shim) → `supabase/functions/_shared/email-html.ts` (motor).

### B7.1 Princípio de arquitetura (relevante para o redesign)

O validador e o renderizador são **o mesmo módulo** usado pelo envio (`send-message`), com o parser `parse5@8.0.0` injetado por adaptador. Citação do CLAUDE.md da Torre (regra 44): "A prova de que front e envio não divergem é o módulo ser o mesmo: duplicar o validador quebra a paridade previa==envio por construção."

**Consequência prática:** o que a prévia aceita, o envio aceita. O que ela recusa, o envio recusa — e a ação **falha** em vez de cair para texto puro.

### B7.2 `EmailTemplateEditor` — layout

| Elemento | Detalhe |
|---|---|
| Linha do rótulo | `flex items-center justify-between gap-2` — rótulo à esquerda, `VariableInserter` à direita |
| Rótulo | `Corpo do e-mail — texto ou HTML` |
| Texto de ajuda (`id={id}-help`) | "Cole seu HTML com tabelas, estilos e imagens. Use variáveis no texto ou nos links. A prévia usa dados de exemplo; o layout pode variar entre clientes de e-mail. Comentários condicionais do Outlook são removidos; imagens devem usar a tag img." |
| Campo | `Textarea`, `rows={12}`, `spellCheck={false}`, `className="font-mono text-sm"` |
| Placeholder | `<p>Olá {{contact.name}},</p>` + nova linha + `<p>Confira seus títulos: {{titles_list}}</p>` |
| Acessibilidade | `aria-invalid={errors.length > 0}`, `aria-describedby` apontando para o texto de ajuda e (quando há erros) para a lista |
| Lista de erros | `<ul role="alert" className="list-disc pl-5 text-sm text-destructive">` abaixo do campo |

**Inserção de variável:** o `VariableInserter` insere na posição do cursor (`selectionStart`/`selectionEnd`), e um `requestAnimationFrame` devolve o foco e reposiciona o cursor **depois** da variável inserida.

> Diferença importante em relação aos outros canais: aqui **não** há chips visuais nem autocomplete por `{{` — é um `Textarea` monoespaçado cru, com um botão de inserção.

### B7.3 Modo texto puro vs modo HTML

`isHtmlEmail(source)` decide pelo regex `/<!doctype\b|<\/?[a-z][a-z0-9:-]*(?:\s|\/?>|$)/i`.

| Modo | Tratamento |
|---|---|
| **Texto puro** (sem tags) | Escapa o HTML e envolve em `<div style="white-space:pre-wrap">…</div>`. Continua funcionando exatamente como antes da entrega IAF-6857 |
| **HTML** | Parse completo + validação por allowlist + resolução de variáveis **na árvore** |

### B7.4 Catálogo completo de validações do e-mail

**Limite global:** `MAX_SOURCE_LENGTH = 256.000` caracteres — vale para o fonte, para o resultado montado e para o total de substituições.

| # | Condição | Mensagem exibida (texto exato) |
|---|---|---|
| 1 | Fonte acima de 256 mil caracteres | `O corpo do e-mail excede o limite de 256 mil caracteres.` |
| 2 | Resultado montado acima do limite | `O e-mail montado excede o limite de 256 mil caracteres.` |
| 3 | Mais de 10.000 substituições ou tamanho resolvido acima do limite | `O e-mail montado excede o limite de tamanho ou de variáveis.` (lançada como exceção) |
| 4 | Erro do parser (exceto `missing-doctype`) | `HTML inválido na linha {n}: {code}.` |
| 5 | Aninhamento acima de 80 níveis | `O HTML possui níveis demais de aninhamento.` |
| 6 | Tag fora da allowlist ou fora do namespace XHTML | `A tag <{tag}> não é permitida em e-mails.` |
| 7 | Tag não fechada (não-void, não-opcional) | `Feche a tag <{tag}> da linha {n}.` |
| 8 | Atributo fora da allowlist | `O atributo {attr} de <{tag}> não é permitido.` |
| 9 | Variável no **nome** de um atributo | `Variáveis devem ser usadas em texto ou no valor de um atributo.` |
| 10 | Variável dentro de `style=` | `Use variáveis no conteúdo, fora do CSS.` |
| 11 | CSS inline com `\`, `@import`, `url(`, `expression(`, `behavior:` ou `-moz-binding` | `CSS com importação, URL ou expressão não é permitido; use <img> para imagens.` |
| 12 | `href`/`src` com URL inválida | `URL inválida no atributo {attr}; use um endereço completo http/https, mailto ou tel.` (para `href`) / `… http/https ou cid.` (para `src`) |
| 13 | `<meta http-equiv>` diferente de `content-type` | `Redirecionamentos e políticas em <meta> não são permitidos.` |
| 14 | `<style>` com variáveis ou CSS inseguro | `O bloco <style> contém CSS não permitido ou variáveis.` |

> Erros são **deduplicados** (`addError` só empurra se ainda não existir na lista).

**Allowlist de TAGS (65):**
`html head body title meta style a abbr b bdi bdo blockquote br caption center col colgroup dd del div dl dt em font h1 h2 h3 h4 h5 h6 hr i img ins li ol p pre s small span strong sub sup table tbody td tfoot th thead tr u ul wbr`

**Allowlist de ATRIBUTOS (38):**
`id class style title lang dir role aria-label aria-hidden align valign width height bgcolor color face size border cellpadding cellspacing colspan rowspan scope alt src href target rel name charset content http-equiv type start reversed`

**Tags void (não exigem fechamento):** `meta br col hr img wbr`
**Tags de fechamento opcional:** `html head body p li dt dd colgroup thead tbody tfoot tr td th`

**Protocolos aceitos em URL:**

| Atributo | Protocolos |
|---|---|
| `src` (imagem) | `http://`, `https://`, `cid:` |
| `href` | `http://`, `https://`, `mailto:`, `tel:` |
| — | Âncoras `#…` são aceitas em `href`; caracteres de controle (` - `, ``) reprovam a URL |

> Quando o texto ainda tem variáveis não resolvidas, a URL é validada substituindo `{{...}}` por `https://example.com` — assim `{{payment_link}}` não é acusado de inválido.

### B7.5 Transformações silenciosas

| Transformação | Detalhe |
|---|---|
| **Comentários removidos** | Todos, **inclusive os condicionais do Outlook** — "seu conteúdo não passa pela árvore HTML e viraria um segundo documento não validado" |
| **Quebras de linha** | Só as que vêm **do valor de uma variável** viram `<br>`; a indentação do código-fonte continua sendo espaço, como em qualquer cliente de e-mail |
| **Valor resolvido é dado** | Entra escapado na serialização — nunca cria tag, atributo ou script |
| **`<title>` não resolve variáveis** | O walker pula a substituição quando `tag === "title"` |

### B7.6 `EmailHtmlPreview` — a prévia

| Atributo | Valor |
|---|---|
| Container | `<iframe>` com `sandbox=""` (tudo bloqueado), `referrerPolicy="no-referrer"`, `srcDoc={emailPreviewDocument(html)}` |
| Dimensões | `h-[420px] w-full border-0 bg-white` |
| Título acessível | `Pré-visualização do e-mail` |
| CSP injetada (só na prévia) | `default-src 'none'; img-src https: http:; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'` + `<meta name="referrer" content="no-referrer">` |

**Estados:**

| Estado | Render |
|---|---|
| Sem conteúdo | `O conteúdo do seu e-mail aparecerá aqui...` (`p-4 text-sm text-muted-foreground`) |
| Com erros | `Corrija o HTML para visualizar: {erros unidos por espaço}` (`role="alert"`, `text-destructive`) |
| Com `{{var.` e carregando | `Carregando variáveis…` |
| Com `{{var.` e erro | `Não foi possível carregar as variáveis da prévia.` (`role="alert"`) |
| OK | O iframe |

**Resolução dos valores na prévia:** por padrão, `(key) => (examples ?? VARIABLE_EXAMPLES)[key] ?? "[" + key + "]"` — ou seja, exemplos do catálogo, com fallback `[chave]` para o que não existir. Com `resolved={true}`, nenhuma resolução é feita (o texto já vem pronto).

### B7.7 Bloqueio de salvamento

No `TemplateDialog`, o terceiro termo do `canSubmit` é:

```
formData.channel !== "email" || renderEmailHtml(formData.content).errors.length === 0
```

Ou seja: **qualquer erro de HTML desabilita o botão de salvar.** A mesma checagem roda no envio.

---

## B8. Uso do template (`TemplateUsageDialog`)

**Fonte:** `src/components/message-templates/TemplateUsageDialog.tsx`

| Atributo | Valor |
|---|---|
| **Objetivo** | Mostrar onde o template está sendo usado, antes de alterar ou excluir |
| **Gatilho** | Item `Ver Uso em Reguas` do menu de ações (disponível para Meta **e** local, sem exigir permissão) |
| **Largura** | `max-w-lg` |
| **Título** | Ícone `GitBranch` (`h-5 w-5`) + `Uso do Template` |
| **Descrição** | `Réguas de cobrança que utilizam o template "{nome}"` |
| **Corpo** | `py-4` |

### B8.1 Como o uso é descoberto

| Passo | Detalhe |
|---|---|
| Query key | `["template-usage", template?.id]` |
| `enabled` | `open && !!template?.id && !!orgClient` (lazy — só ao abrir) |
| Consulta | `workflow_steps` com embed `workflows(id, name)`, ordenado por `created_at desc` |
| Filtro | **Client-side**: `config.activation_template_id === template.id` |

> **Achado relevante para o redesign:** a query traz **todos** os passos de todas as réguas da org e filtra no navegador. Além disso, a chave verificada é **apenas `activation_template_id`** — um template referenciado por outra chave de config (por exemplo, o `rcs_template_id` que o Disparo grava, ou outra convenção de passo) **não** aparece aqui. O rótulo "Ver Uso em Reguas" pode, portanto, dar um falso "não está em uso".

### B8.2 Estados

| Estado | Render |
|---|---|
| Carregando | 3 blocos de skeleton: `Skeleton h-10 w-10 rounded` + duas linhas (`h-4 w-3/4`, `h-3 w-1/2`) |
| Sem uso | Ícone `AlertCircle` (`h-10 w-10 mx-auto text-muted-foreground mb-3`) + `Este template ainda não está sendo usado em nenhuma régua.` |
| Com uso | Contador + lista |

### B8.3 Lista de usos

**Cabeçalho:** `Encontrado em {n} passo` / `{n} passos` `de régua` (`text-sm text-muted-foreground mb-4`).

**Item** (`flex items-center justify-between p-3 rounded-lg border bg-card hover:bg-muted/50 transition-colors`):

| Elemento | Conteúdo |
|---|---|
| Linha 1 | Nome da régua (`font-medium`) — fallback `Régua sem nome` |
| Linha 2 | `Passo: {nome do passo}` (fallback `Passo sem nome`) + `Badge variant="outline" text-xs` com o `step_type` **cru** |
| Ação | Botão `ghost sm` com ícone `ExternalLink` e texto `Abrir` |

**Navegação:** `Abrir` fecha o modal e navega para `/reguas-cobranca/{workflowId}/editor`.

> O `step_type` é exibido sem tradução (ex.: `send_whatsapp`, `negativation`).

---

## B9. Catálogo completo de variáveis disponíveis

**Fonte:** `src/lib/constants/integration-variables.ts` (catálogo estático) + `src/hooks/useVariables.ts` (filtro por contexto e enriquecimento dinâmico).

### B9.1 Contrato do catálogo

Citação do cabeçalho do arquivo:

> "ONLY variables that are actually resolved by the send-message edge function. O contrato acima vale nos dois sentidos: variável resolvida pelo `send-message` que NÃO esteja listada aqui é funcionalidade invisível — quem monta um template não descobre que ela existe."

### B9.2 Onde cada categoria funciona (contextos)

`useVariables({ context })` filtra as categorias oferecidas no picker:

| Contexto | Onde é usado | Categorias oferecidas |
|---|---|---|
| `workflow` | Templates (todos os canais), builder RCS, editor de e-mail | contato, titulo, contrato, suprimento, financeiro, pagamento, carteira, sistema, organizacao, variaveis_personalizadas |
| `integration` | **Campo Conteúdo do Disparo** e assunto | contato, titulo, contrato, suprimento, financeiro, pagamento, sistema, organizacao, carteira, variaveis_personalizadas |
| `integration_payload` | Body Template da integração (fora destas duas telas) | as de `integration` **+ `acao`** |
| `ai` | Prompts de agente de IA | contato, titulo, contrato, suprimento, financeiro, pagamento, sistema, organizacao, variaveis_personalizadas |
| `all` | Sem filtro | todas |

**Regra dinâmica de suprimento:** se a org **não** tem fonte de suprimento (`useHasSupply`), a categoria `suprimento` inteira é **removida** do picker, junto com os campos personalizados de `supplies`/`supply_titles`.

**Regra crítica da categoria `acao`:** `{{action.recipient}}` vive em `allVariables` do `send-message`, **não** em `baseVariables`. Corpo e assunto são resolvidos **antes** — uma chave dessa categoria usada no corpo **sai literal** na mensagem do cliente. Por isso ela nunca é oferecida em `workflow`, `ai` ou `integration`.

### B9.3 Catálogo estático completo (73 chaves)

#### Categoria `contato` — "Contato" (9)

| Chave | Rótulo | Exemplo | Onde funciona |
|---|---|---|---|
| `contact.name` | Nome do Cliente | `João Silva Santos` | Todos os contextos |
| `contact.first_name` | Primeiro Nome | `João` | Todos |
| `contact.document` | Documento (CPF/CNPJ) | `123.456.789-00` | Todos |
| `contact.phone` | Telefone | `11999887766` | Todos |
| `contact.email` | E-mail | `joao.silva@email.com` | Todos |
| `contact.tags` | Tags | `VIP, Recorrente` | Todos |
| `contact.id` | ID do Contato | `contact-uuid-1234` | Todos |
| `contact.trading_name` | Razão Social / Nome Fantasia | `Loja do João ME` | Todos |
| `contact.has_pnp` | Tem PNP no Cliente | `Sim` | Todos |

> `contact.has_pnp` = o cliente tem ao menos 1 contrato com parcela PNP (Primeira Não Paga) vigente.

#### Categoria `titulo` — "Título" (9)

| Chave | Rótulo | Exemplo | Descrição |
|---|---|---|---|
| `title.number` | Número do Título | `TIT-2024-001234` | Identificador do título |
| `title.original_value` | Valor Original | `1.500,00` | Sem juros/multa |
| `title.current_value` | Valor Atual | `1.725,50` | Atualizado com juros/multa |
| `title.due_date` | Data de Vencimento | `15/12/2024` | — |
| `title.days_overdue` | Dias em Atraso | `35` | Dias desde o vencimento |
| `title.status` | Status do Título | `Em Aberto` | — |
| `title.pix_key` | Chave PIX do Título | `empresa@pix.com` | — |
| `title.boleto_digitable_line` | Linha Digitável do Boleto | `23793.38128 60000.000003 00000.000405 1 84340000012500` | — |
| `title.id` | ID do Título | `title-uuid-1234` | — |

#### Categoria `contrato` — "Contrato" (15)

| Chave | Rótulo | Exemplo (resumido) | Descrição |
|---|---|---|---|
| `contract.number` | Número do Contrato | `CTR-2024-5678` | — |
| `contract.modality` | Modalidade | `Crédito Pessoal` | — |
| `contract.status` | Status do Contrato | `Ativo` | — |
| `contract.start_date` | Data de Início | `01/01/2024` | — |
| `contract.end_date` | Data de Término | `01/01/2026` | — |
| `contract.id` | ID do Contrato | `contract-uuid-1234` | — |
| `contract.safra_days` | Dias de Safra | `120` | Dias desde a Data Safra (**aceita negativos** para safra futura) |
| `contract.has_pnp` | Tem PNP no Contrato | `Sim` | Contrato com ao menos 1 parcela PNP vigente |
| `contract.min_open_installment` | 1ª Parcela em Aberto | `1` | Menor `installment_number` entre títulos **Disponível, Recomprado ou Expirado** e sem pagamento |
| `contract.min_open_installment_disponivel` | 1ª Parcela Disponivel | `6` | Primeira parcela com status `Disponivel` (aceita os legados `overdue` e `vencido`) |
| `contracts_list` | Lista de Contratos (números) | `CTR-2024-001, CTR-2024-002` | Números separados por vírgula |
| `contracts_list_detailed` | Lista de Contratos (todos em aberto) | `Contrato: CTR-001 \| Total: R$ 2.500,00 …` | **Todos** os títulos em aberto (vencidos e a vencer), agrupados por contrato |
| `contracts_list_disponivel` | Contratos com Títulos Disponíveis, Recomprado ou Expirado (vencidos e a vencer 10 dias) | `Contrato: CTR-001 \| Aberto: R$ 500,00 …` | Só status Disponível/Recomprado/Expirado, janela de -10 dias |
| `contracts_overdue_list` | Contratos com Títulos Vencidos (e a vencer 10 dias) | `Contrato: CTR-001 \| Vencido: R$ 1.500,00 …` | Qualquer status ativo, vencidos ou a vencer em 10 dias |
| `contracts_and_supplies_list_disponivel` | Contratos E Suprimentos com Títulos Cobráveis (vencidos e a vencer 10 dias) | bloco vertical com emoji por parcela | Equipamento **e** suprimento na MESMA lista; até 10 parcelas por carteira, mas o total soma todas |

**Formato exato do exemplo de `contracts_and_supplies_list_disponivel` (Quimera 6910):**

```
📄 Parcelas de Equipamento

Contrato CTR-001

📌 Parcela 3
• Identificador: TIT-001
• Vencimento: 15/01/2026 (vencida)
• Valor: R$ 500,00

💰 Total do contrato: R$ 500,00

📄 Parcelas de Suprimentos

Nota 199-45678

📌 Parcela 2
• Identificador: TIT-009
• Vencimento: 20/02/2026 (vencida)
• Valor: R$ 320,00

💰 Total da nota: R$ 320,00

💰 Total em aberto: R$ 820,00 (2 parcelas)
```

> O rótulo de seção só aparece quando existem **as duas** carteiras; suprimento é chamado de **"Nota"**, não de "Contrato".

#### Categoria `suprimento` — "Suprimento" (11)

> **Só aparece no picker se a org tiver fonte de suprimento.**

| Chave | Rótulo | Exemplo |
|---|---|---|
| `supply.number` | Número do Suprimento | `SUP-2024-5678` |
| `supply.status` | Status do Suprimento | `Ativo` |
| `supply.total` | Valor Total do Suprimento | `4.500,00` |
| `supply_title.number` | Número da Parcela de Suprimento | `SUP-TIT-2024-001` |
| `supply_title.original_value` | Valor Original do Título de Suprimento | `1.500,00` |
| `supply_title.current_value` | Valor Atual do Título de Suprimento | `1.725,50` |
| `supply_title.due_date` | Vencimento do Título de Suprimento | `15/12/2024` |
| `supply_title.days_overdue` | Dias em Atraso (Suprimento) | `35` |
| `supply_title.status` | Status do Título de Suprimento | `Em Aberto` |
| `supply_title.pix_key` | Chave PIX do Título de Suprimento | `empresa@pix.com` |
| `supply_title.boleto_digitable_line` | Linha Digitável do Boleto (Suprimento) | `23793.38128 …` |

> São **aliases**: numa cobrança de suprimento, `{{title.*}}` e `{{contract.*}}` já resolvem para o suprimento. Os aliases servem para deixar o template explícito.

#### Categoria `financeiro` — "Financeiro" (10)

| Chave | Rótulo | Exemplo | Descrição |
|---|---|---|---|
| `total_debt` | Valor Total da Dívida | `4.532,75` | Soma dos valores **atualizados** de todos os títulos em aberto (inclui a vencer) |
| `days_overdue` | Dias em Atraso (Max) | `45` | Maior atraso entre todos os títulos |
| `oldest_due_date` | Vencimento Mais Antigo | `05/11/2024` | — |
| `titles_count` | Quantidade de Títulos | `3` | Títulos em aberto |
| `original_value` | Valor Original Total | `4.000,00` | Soma dos valores originais |
| `updated_value` | Valor Atualizado Total | `4.532,75` | Com juros/multa, inclui a vencer |
| `overdue_debt` | Valor Total Vencido | `2.250,00` | **Só** títulos vencidos |
| `titles_list` | Lista de Títulos | `1. Título: TIT-001 \| Valor: R$ 500,00 \| Venc: 15/01/2026 \| Atraso: 10 dias` | Valores atualizados |
| `titles_list_original` | Lista de Títulos (Valor Original) | `1. Título: TIT-001 \| Valor: R$ 450,00 …` | Sem juros/multa |
| `total_debt_original` | Dívida Total (Valor Original) | `4.000,00` | — |

#### Categoria `carteira` — "Carteira" (3)

| Chave | Rótulo | Exemplo |
|---|---|---|
| `portfolio.name` | Nome da Carteira | `Carteira Premium` |
| `portfolio.code` | Código da Carteira | `CART-001` |
| `portfolio.id` | ID da Carteira | `portfolio-uuid-1234` |

> ⚠️ Nota histórica do CLAUDE.md da Torre (regra 34): `portfolios.code` é uma coluna que **nunca existiu**, e por ~6 meses o `send-message` deixava `{{portfolio.*}}` **vazio** em toda mensagem — a chamada morta foi removida no card 6325. Vale confirmar se `portfolio.code` resolve hoje.

#### Categoria `pagamento` — "Pagamento" (10)

| Chave | Rótulo | Exemplo |
|---|---|---|
| `payment_link` | Link de Pagamento | `https://finza.com/pay/abc123` |
| `pix_link` | Link do PIX | `https://finza.com/pay/abc123` |
| `pix_code` | Código PIX Copia e Cola | `00020126...` |
| `pix_key` | Chave PIX | `empresa@pix.com` |
| `boleto_link` | Link do Boleto | `https://finza.com/pay/def456` |
| `boleto_barcode` | Código de Barras | `23793.38128 60000.000003...` |
| `payment_value` | Valor do Pagamento | `1.725,50` |
| `payment_value_original` | Valor Original do Pagamento | `1.500,00` |
| `payment_date` | Data do Pagamento | `20/01/2025` |
| `titles_list_with_links` | Lista de Títulos com Links | `1. TIT-001 \| R$ 500,00 \| Link: https://...` |

#### Categoria `sistema` — "Sistema" (3)

| Chave | Rótulo | Exemplo |
|---|---|---|
| `current_date` | Data Atual | `19/01/2026` |
| `current_time` | Hora Atual | `14:30` |
| `organization_name` | Nome da Organização | `Empresa Exemplo LTDA` |

#### Categoria `organizacao` — "Organização" (2)

| Chave | Rótulo | Exemplo |
|---|---|---|
| `org.slug` | Slug da Organização | `blips` |
| `org.name` | Nome da Organização | `Blips Cobrança` |

#### Categoria `acao` — "Ação" (1)

| Chave | Rótulo | Exemplo | Onde funciona |
|---|---|---|---|
| `action.recipient` | Destinatário Resolvido da Ação | `11999887766` | **Somente** `integration_payload` (Body Template da integração). **No corpo/assunto sai LITERAL.** |

Descrição completa do catálogo:

> "Endereço de entrega que o motor de fato resolveu e gravou em `actions.recipient` (telefone ou e-mail, conforme o canal). É a variável de DESTINO recomendada no Body Template da integração: o payload, a coluna da ação, o gate de blocklist e a tela de Ações passam a mostrar provadamente o mesmo valor."

### B9.4 Namespaces dinâmicos (não são chaves)

`DYNAMIC_VARIABLE_NAMESPACES` — prefixos cuja parte final varia por organização. **Não aparecem** como itens fixos no picker; quem enumera as chaves reais é `useVariables`, a partir de `custom_field_definitions` da própria org.

| Prefixo | Rótulo | Descrição | Onde resolve |
|---|---|---|---|
| `contact.custom.` | Campo personalizado do contato | Valor de `contacts.custom_fields` (ETL com `entity_type=contacts`) | Corpo, assunto **e** payload |
| `contract.custom.` | Campo personalizado do contrato | Valor de `contracts.custom_fields` do contrato da ação | — |
| `title.custom.` | Campo personalizado do título | Valor de `titles.custom_fields` do título da ação | — |
| `var.` | Variável personalizada da organização | Valor definido em **Configurações › Variáveis Personalizadas** | — |

**Exemplo na prévia:** `{{contact.custom.etapa}}` vira `[Campo personalizado do contato: etapa]`.

**Tratamento visual:** no `VariablePreview` e no `RichVariableInput`, chaves com `.custom.` ganham a classe extra `variable-chip-custom` e o rótulo é o sufixo humanizado.

### B9.5 Aliases aceitos

`VARIABLE_KEY_ALIASES` — chaves snake_case que o `send-message` resolve mas que **não aparecem no picker** (seriam duas linhas para o mesmo valor):

| Alias | Chave canônica |
|---|---|
| `action_recipient` | `action.recipient` |

Entram em `ALL_VARIABLE_KEYS` (para não serem acusadas de "variável desconhecida") e herdam o exemplo da chave canônica em `VARIABLE_EXAMPLES`.

### B9.6 Rótulos de categoria (`VARIABLE_CATEGORY_LABELS`)

| Chave | Rótulo |
|---|---|
| `contato` | Contato |
| `titulo` | Título |
| `contrato` | Contrato |
| `suprimento` | Suprimento |
| `financeiro` | Financeiro |
| `carteira` | Carteira |
| `pagamento` | Pagamento |
| `sistema` | Sistema |
| `organizacao` | Organização |
| `acao` | Ação |
| `campos_customizados` | Campos Personalizados |
| `variaveis_personalizadas` | Variaveis Personalizadas |

> Note o acento faltando em "Variaveis Personalizadas" — está assim no código.

### B9.7 Variáveis com ajuste automático de tamanho

Segundo o guia do app (`templates.ts`), **duas** variáveis de lista se ajustam ao limite do canal no momento do envio:

| Variável | Ajusta? |
|---|---|
| `contracts_list_disponivel` | **Sim** |
| `contracts_and_supplies_list_disponivel` | **Sim** |
| `titles_list` (e variantes) | **Não** |
| `contracts_list_detailed` | **Não** |
| `contracts_overdue_list` | **Não** |

**O que o ajuste preserva, em ordem de prioridade:**

1. O **total de cada contrato** continua somando **todas** as parcelas em aberto — o cliente nunca vê uma dívida menor do que tem.
2. As parcelas detalhadas são as **mais atrasadas**.
3. Cada contrato avisa quantas ficaram de fora ("… e mais 4 parcelas não listadas").
4. Contrato que perdeu todas as parcelas vira uma linha-resumo ("Contrato: 12509075 — 6 parcelas · R$ 10.341,28").

**Limites por canal citados no guia:** 3.000 caracteres no RCS, 1.024 no WhatsApp, sem limite no e-mail.

---

## B10. Estados da tela (Templates)

### B10.1 Estados da página

| Estado | Condição | Render |
|---|---|---|
| Carregando | `isLoading` | Página inteira substituída por skeletons (2 no cabeçalho + 5 linhas) |
| Atualizando | `isFetching` | O `RefreshButton` anima; a lista permanece |
| Vazio sem busca | `filteredTemplates.length === 0 && !search` | `Nenhum template encontrado` + `Crie seu primeiro template de mensagem.` + CTA `Criar Template` (se `canWrite`) |
| Vazio com busca | `filteredTemplates.length === 0 && search` | `Nenhum template encontrado` + `Tente ajustar sua busca.` (**sem** CTA) |
| Com dados — lista | `view === "list"` | `Card` > `Table` |
| Com dados — grade | `view !== "list"` | `grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4` |
| Seleção ativa | `selectedIds.size > 0 && canDelete` | + barra de ação em massa no topo |
| Sincronizando | `syncMeta.isPending` | Ícone `RefreshCw` girando no botão de topo **e** no item "Resincronizar" de todos os menus; ambos desabilitados |
| Alternando ativo | `toggleActive.isPending` | Item do menu desabilitado |

> ⚠️ **Não há estado de erro na página.** `useAllMessageTemplates` não expõe `isError` para a tela — em caso de falha, `templates` é `undefined` e a UI cai no estado **vazio**, dizendo "Nenhum template encontrado". É indistinguível de "a org não tem templates".

### B10.2 Estados por template (linha/card)

| Estado | Sinal visual |
|---|---|
| Ativo | `Badge variant="default"` com `Ativo` |
| Inativo | `Badge variant="secondary"` com `Inativo` + linha/card em `opacity-60` |
| Selecionado | Lista: `bg-primary/5` · Grade: `border-primary bg-primary/5` |
| Meta aprovado | Badges `Meta` + `APPROVED` (verde) + categoria |
| Meta pendente | Badges `Meta` + `PENDING` (âmbar) + categoria |
| Meta rejeitado | Badges `Meta` + `REJECTED` (vermelho); motivo visível só na prévia |
| Local | Badge único `Local` |

### B10.3 Estados do modal de template

| Estado | Sinal |
|---|---|
| Criação | Título `Novo Template de Mensagem`, botão `Criar Template` |
| Edição | Título `Editar Template`, botão `Salvar Alterações` |
| Duplicação | Comporta-se como criação, com o nome pré-preenchido `{nome} (Cópia)` |
| Inválido | Botão de salvar desabilitado (sem indicação textual do porquê, exceto no e-mail) |
| E-mail com erro de HTML | Lista `role="alert"` abaixo do campo + botão desabilitado + `aria-invalid` no textarea |
| RCS card sem imagem | `Imagem obrigatória — o RCS não entrega o card sem imagem.` + botão desabilitado |
| RCS carrossel < 2 cards | `Adicione ao menos 2 cards.` + botão desabilitado |
| RCS carrossel com card sem imagem | `Imagem obrigatória em cada card.` + botão desabilitado |
| Salvando | `Loader2` no botão + ambos os botões desabilitados |
| Upload de imagem em curso | Botões de imagem desabilitados, texto `Enviando…` |

### B10.4 Inventário literal de textos de estado (Templates)

| Contexto | Texto |
|---|---|
| Página vazia — título | `Nenhum template encontrado` |
| Página vazia — sem busca | `Crie seu primeiro template de mensagem.` |
| Página vazia — com busca | `Tente ajustar sua busca.` |
| Galeria vazia | `Nenhuma imagem enviada ainda.` |
| Galeria com erro | `Não foi possível carregar a galeria. Tente novamente.` |
| Uso sem resultado | `Este template ainda não está sendo usado em nenhuma régua.` |
| Prévia de e-mail vazia | `O conteúdo do seu e-mail aparecerá aqui...` |
| Prévia de e-mail com erro | `Corrija o HTML para visualizar: {erros}` |
| Prévia de variáveis carregando | `Carregando variáveis…` |
| Prévia de variáveis com erro | `Não foi possível carregar as variáveis da prévia.` |
| Carrossel sem cards (prévia) | `Adicione cards para visualizar o carrossel.` |
| Card sem botões | `Nenhum botão (opcional).` |
| Componente Meta vazio (prévia) | `Vazio` (em itálico, `text-muted-foreground`) |

---

## B11. Fluxos de uso passo a passo (Templates)

### G1 — Criar um template de WhatsApp com variáveis

1. `/templates` → **Novo Template**.
2. Preenche **Nome do Template** (obrigatório) e **Descrição** (opcional).
3. **Canal** = WhatsApp (já é o default).
4. No **Conteúdo do Template**, digita o texto e usa `{{` para abrir o autocomplete; navega com ↑↓ e insere com Tab/Enter — a variável vira um **chip** com o rótulo em português.
5. Confere o bloco **Variáveis Detectadas** (badges monoespaçadas `{{chave}}`).
6. Confere o contador `{n} caracteres` e o indicador `✓ Contém variáveis`.
7. Deixa **Template Ativo** ligado.
8. **Criar Template** → toast `Template criado`.

### G2 — Criar um card RCS

1. **Novo Template** → Canal = **RCS** → o modal se alarga para `max-w-5xl`.
2. **Formato** = `Card (imagem + título + descrição + botões)`.
3. **Imagem do card \***: `Enviar imagem` (upload até 2 MB, .gif/.jpg/.png) ou `Galeria` (reaproveita uma das 100 últimas).
4. Preenche **Título do card** e a **Descrição** (com variáveis).
5. **Botões**: `Adicionar botão` até 3. Escolhe o **Tipo** (respeitando a regra de slot) e o **Texto** (máx. 20 caracteres). Se o tipo for `Link/URL`, preenche o **Link** (aceita `{{pix_link}}`).
6. Acompanha a **Pré-visualização** à direita, que se atualiza a cada tecla.
7. **Criar Template**.

### G3 — Criar um carrossel RCS

1. Canal = RCS → **Formato** = `Carrossel (2 a 10 cards)`.
2. `Adicionar card` pelo menos 2 vezes.
3. Para cada card: imagem (**obrigatória**), título, texto (até 1.000) e, opcionalmente, **1** botão.
4. Reordena com as setas ↑↓; remove com a lixeira.
5. Observa: com 3+ cards, o botão de **link** só é permitido no **último** — o sistema corrige o tipo automaticamente nos demais.
6. Confere a prévia horizontal (cards de 256 px, rolagem).
7. Salva.

### G4 — Criar um e-mail HTML

1. Canal = **E-mail** → aparecem `EmailTemplateEditor` e `EmailHtmlPreview`.
2. Cola o HTML do layout (tabelas, `<style>`, `<img>`).
3. Usa o `VariableInserter` para inserir variáveis na posição do cursor (funcionam em texto e em `href`).
4. Se houver erro, a lista vermelha aparece abaixo do campo e o botão de salvar fica desabilitado.
5. Corrige até a lista sumir — a prévia renderiza dentro de um iframe isolado, com dados de exemplo.
6. Salva.

### G5 — Auditar templates Meta

1. **Sincronizar Meta** → toast com quantos foram sincronizados/removidos.
2. Aba **Meta** (com contador).
3. Identifica os badges de status: verde `APPROVED`, âmbar `PENDING`, vermelho `REJECTED`.
4. Clica num rejeitado → abre a prévia read-only → lê o bloco **Motivo da Rejeicao**.
5. Corrige no painel da Meta e sincroniza de novo.

### G6 — Verificar impacto antes de excluir

1. Menu de ações → **Ver Uso em Reguas**.
2. Lê `Encontrado em N passos de régua` ou `Este template ainda não está sendo usado em nenhuma régua.`
3. (opcional) Clica em **Abrir** para ir ao editor da régua.
4. Fecha; menu → **Excluir** → confirma no `AlertDialog`.

### G7 — Desativar em vez de excluir

1. Menu → **Desativar** (só admin/owner) — **sem confirmação**.
2. Toast `Template desativado` / `O template não aparecerá mais nos seletores de régua.`
3. A linha/card fica com `opacity-60` e badge `Inativo`.

### G8 — Exclusão em massa

1. Marca vários checkboxes (lista ou grade).
2. Surge a barra `N templates selecionados` no topo.
3. **Excluir Selecionados** → `AlertDialog` com título `Excluir {n} Templates`.
4. Confirma em **Excluir Todos** → toast `Templates removidos` / `{n} template(s) excluído(s) com sucesso.`

### G9 — Duplicar como ponto de partida

1. Menu de um template local → **Duplicar**.
2. O modal abre em **modo criação**, com o nome `{original} (Cópia)` e todo o conteúdo copiado.
3. Ajusta e salva — o original permanece intacto.

---

# PARTE C — COMUM

## C1. Responsividade e acessibilidade

### C1.1 Responsividade — o que existe hoje

#### Disparos

| Elemento | Comportamento responsivo |
|---|---|
| H1 | `text-xl` → `sm:text-2xl`; ícone `h-5 w-5` → `sm:h-6 sm:w-6` |
| Subtítulo | **Oculto abaixo de `sm`** (`hidden sm:block`) — o usuário mobile perde a explicação da tela |
| Badge de selecionados | `shrink-0` — nunca comprime |
| Barra de ações do card 3 | `flex-col-reverse` → `sm:flex-row sm:items-center sm:justify-between` |
| Grupo dos dois botões | `flex-col-reverse gap-2` → `sm:flex-row` — no mobile, **Disparar fica acima de Pré-visualizar** |
| Chips de resultado | `grid-cols-2` → `sm:grid-cols-4` |
| Detalhe da ação (payload/retorno) | `grid` empilhado → `md:grid-cols-2` |
| Contadores da lista de alvos | `flex-wrap` nos dois lados |
| Barra de navegação da prévia | `flex-wrap items-center justify-between` |
| Identidade do alvo na prévia | `flex-wrap` com `gap-x-2 gap-y-0.5` |
| Botões de upload RCS | `flex flex-wrap gap-2` |

#### Templates

| Elemento | Comportamento responsivo |
|---|---|
| Grade de cards | `grid-cols-1` → `md:grid-cols-2` → `lg:grid-cols-3` |
| Modal de template | `max-w-2xl`, ou `max-w-5xl` no RCS; sempre `max-h-[90vh] overflow-y-auto` |
| Builder RCS | `grid gap-4 md:grid-cols-2` — empilha editor e prévia abaixo de `md` |
| Galeria de imagens | `grid-cols-2` → `sm:grid-cols-3` |
| Busca | `flex-1 max-w-md` |
| Badges de origem | `flex-wrap` |
| Prévia do carrossel | `overflow-x-auto` com cards `w-64 shrink-0` |

### C1.2 Lacunas de responsividade identificadas

| # | Problema | Onde |
|---|---|---|
| R1 | **Tabelas não têm tratamento mobile.** Nem a tabela de alvos (9 colunas), nem a de resultados (6), nem a de templates (8) têm scroll horizontal declarado ou versão em cards. Em telas estreitas elas quebram ou estouram. | `DisparoTargetList`, `dispatch-row`, `MessageTemplatesPage` |
| R2 | O cabeçalho de Templates é `flex items-center justify-between` **sem `flex-wrap`** — com 3 botões de ação, o título é comprimido em telas médias. | `MessageTemplatesPage` l. 394 |
| R3 | O `iframe` da prévia de e-mail tem altura **fixa** de `420px`, sem ajuste por viewport. | `EmailHtmlPreview` |
| R4 | O popover do Template Meta tem largura **fixa** de `360px`, podendo estourar em telas muito estreitas. | `DisparoComposer` |
| R5 | O painel de autocomplete de variáveis tem largura fixa de `320px` e é posicionado por coordenadas absolutas; só há clamp à direita, não à esquerda nem vertical. | `rich-variable-input/index.tsx` |
| R6 | O subtítulo de Disparos some no mobile sem substituto (nem tooltip nem ícone de ajuda). | `DisparosPage` |
| R7 | O builder de RCS empilhado no mobile coloca a prévia **depois** de todo o formulário — o usuário perde o feedback ao vivo enquanto digita. | `RcsCardBuilder`, `RcsCarouselBuilder` |

### C1.3 Acessibilidade — o que já existe

| Recurso | Onde |
|---|---|
| `aria-label` em checkbox de linha | `Selecionar {nome}` (alvos e templates) |
| `aria-label` em checkbox de cabeçalho | `Selecionar todos os contatos desta página` / `Selecionar todos` |
| `aria-sort` + `aria-label` descritivo em cabeçalho ordenável | `TargetColumnHeader` — inclui a ação ("Clique para ordenar em ordem decrescente") |
| `aria-expanded` | Expansor de contratos, linha de resultado, entradas do histórico, gatilho do combobox |
| `aria-label` dinâmico em expansores | `Ver contratos de X` / `Ocultar contratos de X`; `Ver detalhes` / `Ocultar detalhes` |
| `aria-label` na navegação da prévia | `Contato anterior` / `Próximo contato` |
| `role="alert"` | Lista de erros do HTML de e-mail; mensagens de falha de resolução de variáveis |
| `aria-invalid` + `aria-describedby` | `Textarea` do e-mail (aponta para ajuda e, quando há erro, para a lista) |
| `aria-hidden` em ícones decorativos | `Layers`, setas de ordenação, separador `·` da prévia |
| `focus-visible:ring-2 focus-visible:ring-ring` | Gatilho do card do histórico; editor TipTap |
| `htmlFor` ↔ `id` | Toggle de blocklist (`disparo-respect-blocklist`), Nome, Descrição, Template Ativo (`is_active`), corpo do e-mail (`useId`) |
| `title` acessível em iframe | `Pré-visualização do e-mail` |
| `alt` em imagens | `Prévia da imagem`, `Card {i+1}`, `Imagem do card`, nome do arquivo na galeria |
| `role="combobox"` | Gatilho do seletor de Template Meta |
| Navegação por teclado no autocomplete | ↑ ↓ Tab Enter Esc |
| `sandbox=""` + CSP no iframe | Prévia de e-mail isolada |

### C1.4 Lacunas de acessibilidade identificadas

| # | Problema | Onde |
|---|---|---|
| A1 | **Linha inteira clicável sem semântica de botão.** `TableRow onClick` em Templates não é focável por teclado nem anunciado como acionável. | `MessageTemplatesPage` |
| A2 | **Checkbox de cabeçalho de Templates sem `indeterminate`.** Com seleção parcial, aparece desmarcado — informação errada para leitor de tela e para o olho. | `MessageTemplatesPage` |
| A3 | **Alertas do lote não têm `role="status"`/`aria-live`.** Quando a prévia termina e os alertas de resumo/duplicidade aparecem, nada é anunciado. | `DisparosPage` |
| A4 | **Contadores dinâmicos não são regiões vivas.** "N selecionado(s) no total", "i de N" e os chips de resultado mudam em silêncio. | `DisparoTargetList`, `DisparoPreviewNavigator`, `DisparoResultsTable` |
| A5 | **Cor como único portador de significado** nos badges de status Meta (`APPROVED`/`PENDING`/`REJECTED`) e nos de status de ação — o texto ajuda, mas não há ícone diferenciador. | Templates, resultados |
| A6 | **Status Meta não traduzidos.** `APPROVED`, `PENDING`, `REJECTED` aparecem em inglês numa interface em português. | `MessageTemplatesPage` |
| A7 | **Botões só com ícone sem `aria-label`** no menu de ações (`MoreHorizontal`), na lixeira de botão RCS, nas setas de reordenar card e no `X` de remover imagem. | `MessageTemplatesPage`, `RcsCardBuilder`, `RcsCarouselBuilder` |
| A8 | **Falha de clipboard silenciosa.** `Copiar JSON` engole o erro sem avisar — em HTTP ou sem permissão, o usuário acha que copiou. | `dispatch-row.tsx` |
| A9 | **Erro global da lista de templates invisível.** Falha de rede vira "Nenhum template encontrado". | `MessageTemplatesPage` |
| A10 | **Validação de carrossel não é lida.** `validateRcsCarousel` produz mensagens específicas que nunca chegam à tela; o botão só fica desabilitado. | `TemplateDialog` |
| A11 | **Botão desabilitado sem explicação** no modal de template para canais não-e-mail. | `TemplateDialog` |
| A12 | O `EditorContent` do TipTap não recebe `aria-label` nem `aria-describedby` apontando para a dica "Digite `{{`". | `rich-variable-input` |

---

## C2. Dores e oportunidades para o redesign

### C2.1 Dores de Disparos

| # | Dor | Evidência no código | Oportunidade |
|---|---|---|---|
| D1 | **Não há confirmação explícita de uma operação irreversível.** O clique em "Disparar" cria o lote na hora. | `handleConfirm` chama `createBatch.mutate` direto | Modal de confirmação com o resumo (N ações, canal, template, override) e digitação do total, ou ao menos um `AlertDialog` |
| D2 | **O fluxo tem 3 cards longos empilhados numa página só.** A lista de alvos (com filtros, 2 blocos de colagem, tabela paginada e expansões) fica no meio, e os botões de ação ficam no fim. | `DisparosPage` l. 338–493 | Wizard com passos, ou sidebar de resumo fixa (sticky) com o estado do lote |
| D3 | **Os alertas competem por atenção.** Podem aparecer 5 alertas simultâneos entre a prévia e os botões (`overLimit`, `targetOverLimit`, resumo, zero alvos, duplicidade). | l. 388–458 | Consolidar num painel de "checklist do lote" com severidade |
| D4 | **A relação contatos → ações é aprendida tarde.** Só depois do preview o usuário descobre que 100 contatos viraram 250 ações. | `targetCount` só existe pós-preview | Estimar o fan-out **antes** (já há `total_contracts` na tabela) |
| D5 | **A prévia navega um a um, sem visão de conjunto.** Para achar problemas em um lote de 5.000, o usuário depende do botão "Próximo com problema", que varre sequencialmente. | `handleNextProblem` | Painel de resumo de problemas (quantos sem destinatário, quantos bloqueados, quantos acima do limite) com filtro |
| D6 | **A escolha de contratos é invisível por padrão.** O expansor só aparece com `total_contracts >= 2` e nada indica que há escolha a fazer. | `contact.total_contracts >= 2` | Coluna/indicador dizendo "N ações" por linha em contrato-grão |
| D7 | **O expansor mente sobre a contagem.** `total_contracts` conta todos, não só os cobráveis — abre e mostra menos itens (ou zero). | Comentário em `ContactContractsRow` | Mostrar as duas contagens, ou resolver os cobráveis sob demanda no badge |
| D8 | **Dois blocos de colagem quase idênticos**, com semânticas diferentes (um só filtra, o outro filtra **e** seleciona). | Dois `Collapsible` irmãos | Um único bloco "Colar lista" com seletor de tipo (documento/contrato) e explicação do efeito |
| D9 | **"Selecionar todos os N" materializa milhares de ids** e vira um Map de ~1 MB; toda a cadeia depende disso. | Comentário em `handleSelectAllFiltered` | Manter, mas comunicar melhor (o rótulo já traz o número — bom padrão a preservar) |
| D10 | **Sem cancelamento de lote.** Depois de criado, não há como parar as ações `Pendente` pela tela. | Nenhuma ação de cancelamento no `DisparoResultsTable` | Botão "Cancelar pendentes do lote" (a RPC `delete_dispatch_batch_pending` já existe) |
| D11 | **Limite de caracteres invisível no compositor.** O estouro do RCS só aparece na prévia, alvo por alvo. | `DisparoComposer` sem contador | Contador com limite do canal no campo de conteúdo |
| D12 | **Histórico sem filtros.** Só paginação de 25 — não há filtro por canal, ator, período ou status. | `DisparoHistoryTab` | Barra de filtros + busca |
| D13 | **O toggle de blocklist tem lógica invertida** (`checked={!overrideBlocklist}`), o que é fácil de errar num redesign. | `DisparoComposer` l. 331 | Manter o rótulo positivo ("Respeitar blocklist") mas documentar a inversão |
| D14 | **Mobile perde o subtítulo** e enfrenta uma tabela de 9 colunas sem adaptação. | `hidden sm:block` + `Table` | Versão em cards para a lista de alvos |

### C2.2 Dores de Templates

| # | Dor | Evidência | Oportunidade |
|---|---|---|---|
| T1 | **Canal `rcs` sem badge.** Aparece como texto cru cinza `rcs` na lista, embora seja um canal de primeira classe no modal. | `CHANNEL_LABELS` não tem `rcs` | Acrescentar rótulo e cor |
| T2 | **"Resincronizar" no menu do template sincroniza tudo.** O rótulo promete escopo individual. | `syncMeta.mutate()` sem argumento | Renomear para "Sincronizar biblioteca Meta" ou implementar escopo |
| T3 | **"Ver Uso em Reguas" só enxerga `activation_template_id`.** Template usado por outra chave (ex.: `rcs_template_id` do Disparo) aparece como "não usado" — e o usuário exclui. | Filtro client-side em `TemplateUsageDialog` | Ampliar a checagem; o próprio guia do app já afirma que disparos aparecem ali |
| T4 | **Consulta de uso traz todos os passos da org** e filtra no navegador. | `.select(...)` sem `where` | RPC dedicada |
| T5 | **Erro da lista some.** Falha de rede vira estado vazio. | Página não consome `isError` | `ErrorState` com retry, como nas outras telas |
| T6 | **Seleção sobrevive a mudanças de filtro/aba.** É possível excluir em massa itens que não estão na tela. | `selectedIds` nunca é limpo em `setSearch`/`setSourceFilter` | Limpar ao mudar filtro, ou listar os nomes no diálogo de confirmação |
| T7 | **Sem `indeterminate` no cabeçalho.** | `checked={size === length}` | Adicionar |
| T8 | **Mensagens de validação do carrossel não aparecem.** | `validateRcsCarousel(...) === null` usado só como booleano | Exibir a mensagem |
| T9 | **Botão salvar desabilitado sem motivo visível** (fora do e-mail). | `canSubmit` | Lista de pendências, como no e-mail |
| T10 | **Trocar de canal não migra nem limpa o conteúdo.** Um HTML de e-mail pode virar corpo de SMS. | `formData.content` compartilhado | Avisar/confirmar na troca |
| T11 | **Ativar/Desativar sem confirmação**, embora afete réguas em produção. | `toggleActive.mutate` direto no item | Confirmar quando o template estiver em uso |
| T12 | **Normalização silenciosa de tipo de botão RCS.** Ao adicionar o 3º botão, o tipo dos anteriores pode mudar sozinho. | `normalizeRcsButtons` | Sinalizar a mudança |
| T13 | **Galeria de imagens sem busca, sem paginação e sem exclusão.** Limite de 100 e nomes gerados (`rcs-{timestamp}`). | `useRcsImages` | Busca, data, nome amigável, remover |
| T14 | **Reordenação de carrossel só por setas.** | `moveCard` | Drag and drop |
| T15 | **Editor de e-mail é um `Textarea` cru.** Sem destaque de sintaxe, sem numeração de linha — mas os erros citam número de linha. | `EmailTemplateEditor` | Editor de código com gutter, ou ao menos numeração |
| T16 | **Duas experiências de variável no mesmo modal:** chips + autocomplete nos canais de texto, botão inseridor no e-mail. | `RichVariableInput` vs `VariableInserter` | Unificar o padrão de inserção |
| T17 | **Categorias sem rótulo no autocomplete** (`suprimento`, `organizacao`, …) por causa do mapa local duplicado. | `categoryLabels` em `index.tsx` | Usar `VARIABLE_CATEGORY_LABELS` |
| T18 | **Sem contador/limite por canal** (WhatsApp 1.024, RCS 3.000) fora do RCS. | `RichVariableInput` mostra só `{n} caracteres` | Contador com o limite do canal escolhido |
| T19 | **`findUnknownVariables` existe e não é usada.** Um typo (`{{contact.nome}}`) passa batido até o envio. | `utils.ts` | Avisar no modal |
| T20 | **Status Meta em inglês.** | `META_STATUS_COLORS` | Traduzir mantendo o valor original como tooltip |

### C2.3 Oportunidades transversais

| # | Oportunidade |
|---|---|
| O1 | **Unificar a linguagem de "prévia".** Hoje existem pelo menos cinco: `MessagePreview` (réguas/disparo), `RcsPreview` (builder), `EmailHtmlPreview` (iframe), `MetaTemplatePreview` (componentes) e `VariablePreview` (chips). Um sistema único de "mock de canal" reduziria drift. |
| O2 | **Tornar o vínculo Templates ↔ Disparos explícito.** O Disparo consome templates (Meta por nome, RCS por id) e a tela de Templates não mostra isso. |
| O3 | **Padronizar o feedback de bloqueio de botão.** Só o e-mail explica por que não dá para salvar. |
| O4 | **Padronizar estados de erro.** Disparos usa `ErrorState` com retry; Templates não usa nada. |
| O5 | **Mostrar limites de canal em um único lugar** (3.000 RCS, 1.024 WhatsApp, 256 mil e-mail) e aplicá-los consistentemente na composição, no template e na prévia. |
| O6 | **Explicitar a irreversibilidade** com um padrão visual comum (Disparo criado; template excluído; template desativado em uso). |
| O7 | **Preservar as invariantes de segurança do redesign:** paridade prévia↔envio (`buildPreviewParams`/`buildDispatchRows`), interseção-só-reduz (`filterTargetsBySelection`), redação de segredos (`redactSecrets`) e validador único de e-mail. São decisões pagas com incidentes de produção. |

---

## C3. Inventário de modais dos dois domínios

> Convenção: "modal" aqui inclui `Dialog`, `AlertDialog`, `Popover` com conteúdo complexo e `Collapsible` que funciona como painel de entrada.

### C3.1 Visão geral

| # | Nome | Domínio | Tipo | Gatilho | Tamanho |
|---|---|---|---|---|---|
| M1 | Galeria de imagens RCS (`RcsImagePicker`) | Templates | `Dialog` | Botões `Galeria` / `Trocar pela galeria` | `max-w-2xl max-h-[80vh]` |
| M2 | Criar/Editar Template (`TemplateDialog`) | Templates | `Dialog` | Novo Template · Editar · Duplicar · clique na linha local | `max-w-2xl` / `max-w-5xl` (RCS) |
| M3 | Prévia de Template Meta (`MetaTemplatePreview`) | Templates | `Dialog` | Item `Visualizar` · clique na linha Meta | `max-w-lg` |
| M4 | Uso do Template (`TemplateUsageDialog`) | Templates | `Dialog` | Item `Ver Uso em Reguas` | `max-w-lg` |
| M5 | Confirmar exclusão única | Templates | `AlertDialog` | Item `Excluir` | padrão |
| M6 | Confirmar exclusão em massa | Templates | `AlertDialog` | `Excluir Selecionados` | padrão |
| M7 | Seletor de Template Meta | Disparos | `Popover` + `Command` | Botão combobox no card 3 | `w-[360px] p-0` |
| M8 | Colar documentos | Disparos | `Collapsible` (inline) | Cabeçalho do card | largura total |
| M9 | Colar contratos | Disparos | `Collapsible` (inline) | Cabeçalho do card | largura total |
| M10 | Raio-x do payload da prévia | Disparos | `Collapsible` (inline) | `Ver dados enviados à integração` | largura total |
| M11 | Detalhe de ação do lote | Disparos | Linha expansível | Seta da linha | `colSpan=6` |
| M12 | Entrada do histórico | Disparos | `Collapsible` (card) | Card inteiro | largura total |
| M13 | Expansão de contratos do contato | Disparos | Linha expansível | Seta da linha | `colSpan = 9` |
| M14 | Seletor de Template RCS (`TemplateHSMSelector`) | Disparos | ⚠️ A confirmar | Card 3, canal RCS | ⚠️ A confirmar |

---

### M1 · Galeria de imagens RCS (`RcsImagePicker`)

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Reaproveitar imagem já enviada ao bucket `rcs-media` da org |
| **Gatilho** | `Galeria` (sem imagem) ou `Trocar pela galeria` (com imagem), no `RcsCardBuilder` e em cada card do `RcsCarouselBuilder` |
| **Layout** | `DialogContent max-w-2xl max-h-[80vh] overflow-y-auto`; grade `grid-cols-2 sm:grid-cols-3 gap-3` |
| **Título** | `Escolher imagem da galeria` |
| **Descrição** | `Selecione uma imagem já enviada anteriormente para reutilizá-la no card.` |
| **Campos** | Nenhum — só a grade de miniaturas (`aspect-video object-cover`) |
| **Botões** | Nenhum botão de rodapé. Cada miniatura é um `<button type="button">` |
| **Confirmação** | Nenhuma — clicar **seleciona e fecha** |
| **Estados** | Carregando (`Loader2`) · Erro (`Não foi possível carregar a galeria. Tente novamente.`) · Vazio (`ImageOff` + `Nenhuma imagem enviada ainda.`) · Com imagens |
| **Seleção atual** | `ring-2 ring-primary` + selo `Check` no canto |
| **Limites** | 100 imagens mais recentes, sem busca nem paginação |

---

### M2 · Criar/Editar Template (`TemplateDialog`)

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | CRUD de template local |
| **Gatilhos** | `Novo Template` · `Criar Template` (estado vazio) · menu `Editar` · menu `Duplicar` · clique na linha/card de template local |
| **Layout** | `max-w-2xl` (ou `max-w-5xl` em RCS) · `max-h-[90vh] overflow-y-auto` · corpo `space-y-4 py-4` |
| **Título** | `Editar Template` / `Novo Template de Mensagem` |
| **Descrição** | `Atualize as informações do template.` / `Crie um novo template de mensagem para usar nas réguas de cobrança.` |
| **Campos comuns** | Nome do Template \* · Descrição · Canal \* · Template Ativo (Switch) |
| **Campos condicionais** | Texto: `RichVariableInput` + Variáveis Detectadas · E-mail: `EmailTemplateEditor` + `EmailHtmlPreview` · RCS: Formato \* + builder de card/carrossel + prévia |
| **Botões** | `Cancelar` (`outline`) · `Salvar Alterações` / `Criar Template` (primário) |
| **Confirmação** | Nenhuma — salva direto. **Fechar não avisa sobre alterações não salvas** |
| **Estados** | criação · edição · duplicação · inválido (botão desabilitado) · salvando (`Loader2`) · e-mail com erros · RCS com pendências · upload em curso |
| **Reset** | `useEffect([template, open])` repopula tudo, inclusive `parseRcsMetaComponents` |

---

### M3 · Prévia de Template Meta (`MetaTemplatePreview`)

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Ler um template Meta (somente leitura) como ele se apresenta no WhatsApp |
| **Gatilho** | Item `Visualizar` do menu · clique na linha/card de template Meta |
| **Layout** | `DialogContent max-w-lg`; corpo `space-y-4` |
| **Título** | Ícone `Cloud` (`h-5 w-5 text-blue-600`) + o nome do template |
| **Descrição** | Nenhuma (`DialogDescription` ausente) |
| **Bloco 1 — Selos** | `flex items-center gap-2 flex-wrap`: status Meta (colorido) · `meta_category` (`secondary`) · `meta_language` (`outline`) |
| **Bloco 2 — Componentes** | Quatro seções, cada uma com rótulo `text-xs font-semibold uppercase` e caixa `rounded-md border bg-muted/50 p-3 text-sm` |
| — `HEADER` | Se `format` existe e **não** é `TEXT`, mostra `[{FORMAT}]` em itálico cinza (ex.: `[IMAGE]`); senão o `text`, ou `Vazio` em itálico |
| — `BODY` | `whitespace-pre-wrap`; ou `Vazio` em itálico |
| — `FOOTER` | `text-muted-foreground`; ou `-` |
| — `BUTTONS` | Uma linha por botão: `flex items-center justify-between`, texto à esquerda e `Badge outline text-xs` com o `type` à direita |
| **Fallback** | Sem componentes **e** com `content`: seção `Conteudo` com o texto cru |
| **Bloco 3 — Rejeição** | Só quando há `meta_rejected_reason`: caixa `border-red-500/20 bg-red-500/5 p-3` com título `Motivo da Rejeicao` e o texto em `text-red-600` |
| **Bloco 4 — Sincronização** | Só quando há `synced_at`: `Sincronizado em dd/MM/yyyy HH:mm` (`text-xs text-muted-foreground`) |
| **Botões** | Nenhum — só o fechar padrão do `Dialog` |
| **Confirmação** | Não se aplica |
| **Estados** | `template === null` → não renderiza nada. Sem estado de carregamento (os dados já vieram na lista) |
| **Observação** | Os rótulos das seções estão **em inglês** (`Header`, `Body`, `Footer`, `Buttons`) e "Conteudo"/"Motivo da Rejeicao" estão **sem acento** |

---

### M4 · Uso do Template (`TemplateUsageDialog`)

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Mostrar em quais passos de régua o template está referenciado |
| **Gatilho** | Item `Ver Uso em Reguas` (disponível para todos os perfis e para as duas origens) |
| **Layout** | `max-w-lg`; corpo `py-4` |
| **Título** | `GitBranch` + `Uso do Template` |
| **Descrição** | `Réguas de cobrança que utilizam o template "{nome}"` |
| **Campos** | Nenhum — lista read-only |
| **Item da lista** | Régua (`font-medium`) · `Passo: {nome}` + `Badge outline` com `step_type` cru · botão `Abrir` (`ghost sm`, `ExternalLink`) |
| **Botões** | `Abrir` por item; sem rodapé |
| **Navegação** | Fecha o modal e vai para `/reguas-cobranca/{workflowId}/editor` |
| **Estados** | Carregando (3 skeletons) · Sem uso (`AlertCircle` + texto) · Com uso (contador + lista) |
| **Limitação** | Só detecta `config.activation_template_id` |

---

### M5 · Confirmar exclusão única

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Confirmar a exclusão irreversível de um template |
| **Gatilho** | Item `Excluir` do menu (exige `canDelete`) |
| **Layout** | `AlertDialogContent` padrão |
| **Título** | `AlertTriangle` (`h-5 w-5 text-destructive`) + `Confirmar Exclusão` |
| **Descrição** | "Tem certeza que deseja excluir este template? Esta ação não pode ser desfeita. Réguas que usam este template podem ser afetadas." |
| **Campos** | Nenhum — **não pede digitação de confirmação** |
| **Botões** | `Cancelar` (`AlertDialogCancel`) · `Excluir` (`AlertDialogAction` com `bg-destructive text-destructive-foreground hover:bg-destructive/90`) |
| **Estados** | Sem estado de carregamento visível no botão |
| **Pós-ação** | Fecha, remove o id da seleção, toast `Template removido` / `O template foi excluído com sucesso.` Erro → toast `Erro ao remover template` |

---

### M6 · Confirmar exclusão em massa

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Confirmar exclusão de N templates selecionados |
| **Gatilho** | `Excluir Selecionados` na barra de seleção |
| **Título** | `AlertTriangle` + `Excluir {n} Templates` |
| **Descrição** | "Tem certeza que deseja excluir os templates selecionados? Esta ação não pode ser desfeita. Réguas que usam estes templates podem ser afetadas." |
| **Campos** | Nenhum — **os nomes dos templates não são listados** |
| **Botões** | `Cancelar` · `Excluir Todos` (destrutivo) |
| **Pós-ação** | Fecha, zera a seleção, toast `Templates removidos` / `{n} template(s) excluído(s) com sucesso.` |
| **Risco** | A seleção pode conter itens invisíveis (fora do filtro/aba atual) — ver T6 |

---

### M7 · Seletor de Template Meta (Disparos)

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Escolher um template aprovado da Meta para o lote de WhatsApp |
| **Gatilho** | Botão combobox `role="combobox"` no card "3. Conteúdo" |
| **Condição** | `channel === "whatsapp"` e existem templates Meta |
| **Layout** | `PopoverContent w-[360px] p-0 align="start"` com `Command` |
| **Busca** | `CommandInput placeholder="Buscar template..."`; o valor buscável de cada item é `{meta_template_name} {name}` |
| **Vazio** | `Nenhum template Meta encontrado` |
| **Itens** | 1ª opção fixa `Nenhum template (envio livre)` (cinza) + um item por template `APPROVED`, com nome e `meta_category` abaixo |
| **Marca** | `Check` (`h-3 w-3`) com `opacity-100`/`opacity-0` |
| **Efeito colateral** | Selecionar extrai as variáveis numeradas `{{1}}`,`{{2}}`… e monta `templateVariableMap` com valores vazios; abre o `MetaVariableMapper` abaixo |
| **Estados** | Sem seleção (gatilho cinza) · Com seleção (badge verde `Meta` + nome truncado) |

---

### M8 · Colar documentos (painel inline)

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Restringir a lista de alvos por uma lista externa de CPF/CNPJ |
| **Gatilho** | Cabeçalho clicável do `Collapsible` (`cursor-pointer py-3 hover:bg-muted/50`) |
| **Layout** | `Card` com `CardHeader` (ícone `ClipboardPaste` + título + badge + `ChevronDown` rotativo) e `CardContent` `pt-0 flex flex-col gap-3` |
| **Campo** | `Textarea rows={4} font-mono text-sm` |
| **Botões** | `Aplicar` / `Resolvendo...` · `Limpar` (ghost, condicional) |
| **Confirmação** | Nenhuma |
| **Estados** | fechado · aberto vazio · resolvendo · sucesso (painel tracejado com contagens) · 0 encontrados (aviso vermelho) · erro |

---

### M9 · Colar contratos (painel inline)

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Restringir a lista **e** marcar exatamente aqueles contratos em cada contato |
| **Gatilho** | Cabeçalho do `Collapsible` (ícone `FileText`) |
| **Campo** | `Textarea rows={4} font-mono text-sm` |
| **Texto de apoio** | Muda conforme o grão (ver A3.4) |
| **Botões** | `Aplicar` / `Resolvendo...` · `Limpar` |
| **Confirmação** | Nenhuma — o merge na seleção acontece direto |
| **Estados** | fechado · aberto · resolvendo · sucesso com 3 contagens (encontrados · não encontrados · sem contato dono) · 0 pares com/sem filtro anterior · erro |

---

### M10 · Raio-x do payload (prévia)

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Mostrar exatamente o que sairia para a integração naquele alvo |
| **Gatilho** | Botão de largura total `Ver dados enviados à integração` |
| **Condição** | `preview.outbound_request` existe |
| **Layout** | `CollapsibleTrigger` `flex w-full items-center justify-between rounded-md px-1 py-1 hover:bg-muted/50` + `CollapsibleContent pt-1.5` com `OutboundRequestView` |
| **Conteúdo** | Webhook: método, URL, headers e body (segredos **já mascarados server-side**). Provider SDK: só uma nota |
| **Estados** | fechado (default) · aberto. **Fecha automaticamente ao trocar de alvo** |

---

### M11 · Detalhe de ação do lote (linha expansível)

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Auditar uma ação: payload, retorno, erro, referências e override |
| **Gatilho** | Seta da linha (`ChevronRight`/`ChevronDown`, `aria-expanded`) |
| **Layout** | `TableRow bg-muted/20`, `colSpan=6`, `p-3`, `space-y-3` |
| **Blocos** | Botão `Copiar JSON` · grade `md:grid-cols-2` com Payload enviado e Retorno · Erro (condicional) · Referência (8 itens) · Auditoria (5 itens) |
| **Botões** | `Copiar JSON` → `Copiado!` por 1,5 s |
| **Confirmação** | Nenhuma |
| **Estados** | fechado · aberto · copiado · falha de clipboard (silenciosa) |
| **Reuso** | O mesmo componente serve ao acompanhamento do lote **e** ao drill-down de ação avulsa do histórico |

---

### M12 · Entrada do histórico (card expansível)

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Auditar um disparo passado (lote ou ação avulsa) |
| **Gatilho** | O card inteiro é um `<button>` com `aria-expanded` |
| **Layout** | `Card` > `Collapsible`; conteúdo expandido em `border-t p-3` |
| **Cabeçalho** | Badge de tipo · badge de canal · contagem de ações · badge `override` (condicional) · data/hora · ator · chips de status |
| **Conteúdo** | Lote → `DisparoResultsTable` completo (com chips, export e polling). Avulsa → `DispatchActionResultTable` de uma linha |
| **Botões** | Nenhum próprio (herda os do conteúdo) |
| **Estados** | fechado · aberto lote · aberto avulsa (loading/erro/não encontrada/ok) · sem referência válida |

---

### M13 · Expansão de contratos do contato

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Escolher quais contratos do contato entram no lote |
| **Gatilho** | Seta da linha, visível só com `total_contracts >= 2`; **um por vez** |
| **Layout** | `TableRow bg-muted/20`, `colSpan = TARGET_COLUMNS.length + 2` (= 9), `py-3` |
| **Campos** | Um `Checkbox` por contrato cobrável, dentro de `<label>` clicável, com o número do contrato (ou 8 chars do id) |
| **Cabeçalho** | `{n} contrato(s) cobrável(is)` (`text-xs font-medium text-muted-foreground`) |
| **Aviso condicional** | Em contato-grão: "O tipo de ação escolhido cria 1 ação por contato — a escolha de contrato não se aplica agora, mas fica guardada se você trocar para negativação/notificação." |
| **Botões** | `Tentar novamente` só no estado de erro |
| **Confirmação** | Nenhuma — desmarcar todos **remove o contato da seleção** |
| **Estados** | loading (3 skeletons) · erro · vazio (`Nenhum contrato cobrável — este contato não vira alvo.`) · com contratos |

---

### M14 · Seletor de Template RCS (`TemplateHSMSelector`)

| Aspecto | Detalhe |
|---|---|
| **Objetivo** | Escolher o template local de RCS para o lote |
| **Gatilho** | Bloco `Template RCS (opcional)` no card 3, quando `channel === "rcs"` |
| **Componente** | `TemplateHSMSelector channel="rcs"` — **o mesmo** usado na configuração de passo de régua |
| **Efeito** | Grava `config.rcsTemplateId`; limpar devolve `undefined` |
| **Alerta associado** | "O corpo do template vence o conteúdo digitado abaixo — o texto só é usado como reserva, se o template não tiver corpo." |
| **Comportamento documentado no guia do app** | Abre direto na aba **"Templates Locais"** (antes abria em "Templates Meta", que no RCS é sempre vazia); o rótulo diz **"Template de RCS (card)"**, sem "Ativação (HSM)" nem "janela de 24h" |
| **Estados** | ⚠️ A confirmar: a UI interna (layout, abas, busca, estados de carregamento/vazio/erro) vive em `src/components/reguas-cobranca/config-forms/SharedComponents/TemplateHSMSelector` e **não foi lida** neste documento |

---

## Apêndice — Índice de arquivos-fonte

### Disparos

| Arquivo | Papel |
|---|---|
| `src/pages/DisparosPage.tsx` | Orquestra o fluxo, sessão de preview, alertas e envio |
| `src/components/disparos/DisparoComposer.tsx` | `DisparoActionPicker` + `DisparoContentComposer` + tipo `DisparoConfig` |
| `src/components/disparos/DisparoTargetList.tsx` | Lista de alvos: filtros, colagens, seleção, expansão de contratos |
| `src/components/disparos/DisparoPreviewNavigator.tsx` | Prévia navegável por alvo |
| `src/components/disparos/preview-problems.ts` | Lógica pura de detecção de problema e varredura |
| `src/components/disparos/DisparoResultsTable.tsx` | Acompanhamento do lote: chips, export, tabela |
| `src/components/disparos/dispatch-row.tsx` | `StatChip`, `JsonBlock`, `RefItem`, linha expansível, tabela compartilhada |
| `src/components/disparos/dispatch-labels.ts` | Rótulos de identidade (contato/contrato) — módulo puro |
| `src/components/disparos/DisparoHistoryTab.tsx` | Aba Histórico |
| `src/hooks/useDisparos.ts` | Alvos, seleção, chaves de invalidação, lote, status, export, redação |
| `src/hooks/useDisparoHistory.ts` | Histórico paginado e ação avulsa |
| `src/hooks/useManualAction.ts` | Dry-run compartilhado (`ManualActionPreview`) |
| `src/pages/central-docs/negocio/data/disparos.ts` | Guia de negócio da tela (dentro do app) |

### Templates

| Arquivo | Papel |
|---|---|
| `src/pages/MessageTemplatesPage.tsx` | Lista, filtros, seleção, menus, `MetaTemplatePreview`, diálogos de exclusão |
| `src/components/message-templates/TemplateDialog.tsx` | Modal de criação/edição |
| `src/components/message-templates/TemplateUsageDialog.tsx` | Uso em réguas |
| `src/components/message-templates/TemplateMessagePreview.tsx` | Prévia com resolução de `{{var.*}}` |
| `src/components/message-templates/EmailTemplateEditor.tsx` | Editor de corpo de e-mail |
| `src/components/message-templates/EmailHtmlPreview.tsx` | Prévia em iframe + prévias de assunto |
| `src/components/message-templates/RcsCardBuilder.tsx` | Builder de card/simples |
| `src/components/message-templates/RcsCarouselBuilder.tsx` | Builder de carrossel |
| `src/components/message-templates/RcsImagePicker.tsx` | Galeria de imagens |
| `src/components/message-templates/RcsPreview.tsx` | Prévia visual do RCS |
| `src/components/message-templates/rcs-meta.ts` | Constantes, regras de botão, (de)serialização e validação |
| `src/components/ui/rich-variable-input/index.tsx` | Editor TipTap com chips de variável |
| `src/components/ui/rich-variable-input/utils.ts` | Parse/serialize, filtro, exemplos, variáveis desconhecidas |
| `src/components/ui/variable-preview.tsx` | `VariablePreview` e `VariablePreviewBlock` |
| `src/hooks/useMessageTemplates.ts` | CRUD, listagens, toggle, sync Meta |
| `src/hooks/useUploadRcsImage.ts` | Upload e galeria de imagens RCS |
| `src/hooks/useTemplatePreview.ts` | Resolver de variáveis compostas |
| `src/hooks/useCustomerTemplatePreview.ts` | Prévia com um cliente real |
| `src/hooks/useVariables.ts` | Catálogo por contexto + campos personalizados |
| `src/lib/constants/integration-variables.ts` | Catálogo canônico de variáveis |
| `src/lib/email-html.ts` → `supabase/functions/_shared/email-html.ts` | Validador/renderizador único de e-mail |
| `src/pages/central-docs/negocio/data/templates.ts` | Guia de negócio da tela (dentro do app) |

### Compartilhados citados

| Arquivo | Papel |
|---|---|
| `src/lib/constants/integration-types.ts` | Rótulos e cores de canal/tipo de ação |
| `src/lib/constants/action-status-config.ts` | Status canônicos e conjuntos (`SENT_STATUSES` etc.) |
| `src/lib/constants/action-status-display.ts` | Rótulos de exibição dos status |
| `src/components/portfolio/types.ts` | `DEFAULT_COLUMNS` (rótulos e descrições das colunas) |
| `src/components/portfolio/PortfolioFiltersBar.tsx` | Barra de filtros reusada nos alvos |
| `src/components/portfolio/PortfolioFooter.tsx` | Paginação reusada nos alvos |
| `src/lib/paste-list.ts` | Parsers de lista colada (documentos e contratos) |
| `src/lib/portfolio-filter-params.ts` | Tradutores canônicos de filtro para RPC |

---

## Apêndice — Glossário mínimo para o designer

| Termo | Significado nesta interface |
|---|---|
| **Alvo (`DispatchTarget`)** | Uma **ação** a ser criada: `{contactId, contractId?, titleId?}`. Não é o mesmo que "contato selecionado" |
| **Grão** | Se o tipo de ação cria 1 ação por **contato** ou 1 por **contrato** |
| **Fan-out** | A multiplicação de ações quando o grão é contrato |
| **Lote (`batch_id`)** | O identificador que agrupa todas as ações criadas por um clique em Disparar |
| **Blocklist** | Lista de contatos/endereços que não devem ser contatados |
| **Override de blocklist** | Forçar o envio ignorando a blocklist, auditado e restrito a owner/admin |
| **Dry-run / Prévia** | Resolução completa da mensagem **sem** criar ação nem chamar o provedor |
| **Template Meta / HSM** | Template de WhatsApp aprovado pela Meta, identificado por **nome** |
| **Template RCS** | Template local da Torre, identificado por **id** |
| **Postback** | Botão de RCS que devolve uma intenção (não abre link) e transfere o atendimento |
| **Carrossel** | Formato de RCS com 2 a 10 cards deslizáveis |
| **Variável / chip** | `{{chave}}` resolvida no envio; na interface aparece como chip com rótulo em português |
| **Cobrável** | Título com status Disponível/Recomprado/Expirado e sem pagamento |

---

*Fim do documento 17.*
