# 19 · Tela Fonte de Dados (ETL)

> Documento de referência para redesenho. Descreve o frontend **atual** da tela Fonte de Dados da Torre de Controle, tal como está no código, sem propor mudanças (exceto na seção 18, que lista dores observadas).
>
> Fonte primária: `cobranca-finza/src/pages/ETLPage.tsx` e toda a árvore `cobranca-finza/src/components/etl/**`.
> Regra de leitura: **tudo aqui saiu do código**. Onde o código é ambíguo, o texto traz `⚠️ A confirmar: ...`.

---

## 0. Identidade (rota, arquivo, permissão, layout)

| Item | Valor | Fonte |
|---|---|---|
| Rota | `/etl` | `src/App.tsx` linha 421 |
| Componente de página | `ETLPage` (export nomeado) | `src/pages/ETLPage.tsx` |
| Carregamento | `lazy(() => import("@/pages/ETLPage").then(m => ({ default: m.ETLPage })))` | `src/App.tsx` linha 28 |
| Guarda de rota | `<RequirePermission permission="etl:read">` | `src/App.tsx` linha 421 |
| Guarda de escrita (dentro da tela) | `hasPermission("etl:write")` → constante `canWrite` | `src/pages/ETLPage.tsx` linha 46 |
| Permissão de delete | `hasPermission("etl:delete")` — **existe mas está comentada** (`// temporarily unused`) | `src/pages/ETLPage.tsx` linha 47 |
| Layout | Página dentro do shell padrão (sidebar + área de conteúdo). Container raiz: `<div className="space-y-6">` | `src/pages/ETLPage.tsx` linha 296 |
| Título | `Fonte de Dados` (`h1`, `text-2xl font-bold tracking-tight`) | idem, linha 299 |
| Subtítulo | `Gerencie fontes de dados, pipelines de importacao e campos personalizados` | idem, linha 300-302 |
| Rota irmã (documentação viva) | `/docs/fonte-de-dados` — tela full-screen separada, também gated por `etl:read` | `src/App.tsx` linhas 385-395 |

### 0.1 Multi-tenant

Toda leitura/escrita da tela passa pelo `orgClient` de `useOrganization()`, que aponta para o schema `org_{slug}`. As exceções são as RPCs de Materialização, que vivem em `public` e recebem `p_schema_name = org_<slug>` como parâmetro (`src/hooks/useMvRefresh.ts`).

### 0.2 Observação de nomenclatura

O nome da tela no menu e no `h1` é **"Fonte de Dados"** (singular), mas a primeira aba se chama **"Fontes de Dados"** (plural). O domínio interno chama tudo de "ETL". Os três termos convivem no produto.

---

## 1. Objetivo e personas

### 1.1 O que a tela resolve

É o ponto de entrada de dados da Torre. Toda a operação de cobrança (Dashboard, Carteira, Campanhas, Ações, Filtros, Relatórios) lê de `vw_titles_live`, e `vw_titles_live` só existe porque um pipeline desta tela importou contatos, contratos e títulos de alguma origem externa. Sem esta tela, não há o que cobrar.

O guia de negócio embutido no próprio app descreve a metáfora canônica (`src/pages/central-docs/negocio/data/fonte-de-dados.ts`, bloco `whatIs`):

> "Pense nesta tela como a doca de recebimento de um armazém. As Fontes de Dados são os caminhões que chegam (cada um de um lugar diferente). Os Pipelines são a esteira que descarrega, confere e guarda a mercadoria no lugar certo. Os Campos Personalizados são etiquetas extras que você cria. As Carteiras agrupam o estoque por dono ou tipo. E a Materialização é o painel que garante que a prateleira exibida para o time esteja sempre com a contagem mais recente."

### 1.2 Personas

| Persona | O que faz aqui | Permissão típica |
|---|---|---|
| Implantador / analista de dados | Conecta uma fonte nova (BigQuery, CSV), monta o mapeamento de campos, normaliza valores, agenda a carga | `etl:write` |
| Operação / supervisão de cobrança | Roda pipeline manualmente, acompanha execução, investiga erro de importação, força atualização da MV | `etl:write` |
| Consulta (viewer/operator) | Vê fontes, pipelines, histórico de execuções — mas **não vê** o botão de criar nem as ações de escrita | `etl:read` |
| Suporte técnico | Abre o detalhe de uma execução da MV, copia o `id` do log e o SQL, abre os Postgres logs no Supabase | `etl:write` |

Perfis declarados no guia de negócio: `owner`, `admin`, `manager` (`permissions: ["owner","admin","manager"]`).

### 1.3 Frequência de uso

- **Configuração** (wizards) — raro, concentrado em implantação ou mudança de fonte.
- **Operação** (rodar/testar/pausar pipeline, ver histórico) — diário.
- **Materialização** — consultado sob suspeita de dado defasado; o agendamento é mexido raramente.

---

## 2. Modelo mental: fonte de dados, pipeline, execução/job, lote, campo personalizado, mapeamento, normalização, materialização

Esta seção define o vocabulário. Um redesenho que troque qualquer um destes termos quebra a comunicação com o backend e com os guias internos.

### 2.1 Fonte de Dados (`data_sources`)

Diz **DE ONDE** os dados vêm e **COMO conectar**. Guarda:

| Campo | Papel | Tipo (frontend) |
|---|---|---|
| `id` | UUID | string |
| `name` | Apelido escolhido pelo usuário | string |
| `description` | Opcional | string? |
| `source_type` | Um de 6 tipos (ver 2.1.1) | `DataSourceType` |
| `connection_config` | JSONB com credenciais/endereço — **segredo** | `Record<string, unknown>` |
| `query_config` | JSONB com metadados cacheados: `fields`, `sample_data`, `unique_values`, `unique_values_source`, `cached_at`, `fileName`, `recordCount`, `data` | `Record<string, unknown>?` |
| `payment_check_url` | URL de verificação de pagamento (nível raiz, **não** dentro de `connection_config`) | string? |
| `storage_path` | Caminho no bucket `etl-uploads` para CSV/CNAB | string? |
| `is_active` | boolean | boolean |
| `last_sync_at` / `last_sync_status` / `last_sync_error` | Carimbo da última execução | string? |
| `created_at` / `updated_at` | Timestamps | string |

Definição em `src/hooks/etl/types.ts` linhas 9-24.

#### 2.1.1 Os 6 tipos reais de fonte

Extraídos de `DATA_SOURCE_TYPES` (`src/hooks/etl/constants.ts` linhas 5-36) e do type `DataSourceType` (`src/hooks/etl/types.ts` linha 3):

| Chave | Label na UI | Descrição exibida | Ícone (lucide) |
|---|---|---|---|
| `bigquery` | BigQuery | `Google BigQuery data warehouse` | `Database` |
| `rest_api` | REST API | `External REST API endpoint` | `Globe` |
| `csv` | CSV Upload | `Upload CSV files` | `FileSpreadsheet` |
| `cnab` | CNAB | `Arquivos bancários CNAB 240/400` | `Landmark` |
| `postgresql` | PostgreSQL | `PostgreSQL database` | `Server` |
| `mysql` | MySQL | `MySQL database` | `Server` |

Mapa de ícones duplicado em três arquivos (`SOURCE_ICONS` em `DataSourcesTab.tsx`, `TypeSelectionStep.tsx` e `DataSourceSelectionStep.tsx`) e ainda uma quarta cópia como string em `wizards/shared/types.ts` (`SOURCE_TYPE_ICONS`).

> Nota: as descrições de `bigquery`, `rest_api` e `csv` estão **em inglês** no código, enquanto `cnab`, `postgresql` e `mysql` estão em português/neutro. Isso aparece direto na UI (cards da aba e do passo 1 do wizard).

### 2.2 Pipeline (`etl_pipelines`)

Diz **COMO** transformar e carregar. Um pipeline aponta para **uma** fonte (`data_source_id`); uma fonte pode alimentar **vários** pipelines.

| Campo | Papel |
|---|---|
| `name` / `description` | Identificação |
| `data_source_id` | FK para a fonte |
| `target_entity` | Entidade-alvo principal (`contacts`\|`contracts`\|`titles`\|`supplies`\|`supply_titles`) |
| `field_mapping` | `Record<string, string>` — coluna da fonte → `"entidade:campo"`. Aceita **1:N** (valor array) |
| `transform_rules` | Array com **um** objeto (`transform_rules[0]`) contendo `value_mappings`, `list_fields`, `data_transforms`, `custom_standard_values` |
| `dedup_field` / `dedup_strategy` | Chave e estratégia da entidade principal |
| `dedup_strategy_contacts` / `_contracts` / `_titles` | Estratégia por entidade (não existe coluna para supplies) |
| `schedule_cron` | Expressão cron de 5 campos (uma linha) ou `null` |
| `is_scheduled` | Derivado: `!!scheduleCron` |
| `is_active` | Ativo/Pausado — é o toggle de "Pausar agendamento" |
| `skip_reconciliation` | Não remover títulos ausentes após a execução |

Definição em `src/hooks/etl/types.ts` linhas 33-58.

### 2.3 Família do pipeline (equipamento × suprimento)

Introduzida na IAF-4795. O wizard é **single-source**: um pipeline importa **OU** a cadeia de equipamento **OU** a de suprimento. Contato é compartilhado (necessário para o lookup por documento).

```
equipment: contacts → contracts → titles
supply:    contacts → supplies  → supply_titles
```

Constante `FAMILY_ENTITIES` em `src/components/etl/wizards/PipelineWizard/types.ts` linhas 54-57. A família é inferida ao editar via `familyForEntity(target_entity)` e escolhida por ToggleGroup ao criar.

### 2.4 Execução / job (`etl_job_runs`)

Cada disparo gera um `ETLJobRun` (`src/hooks/etl/types.ts` linhas 62-87):

| Campo | Valores |
|---|---|
| `run_type` | `manual` \| `scheduled` (o código também grava `"test"` ao testar — ver 2.4.1) |
| `status` | `pending` \| `running` \| `completed` \| `failed` \| `cancelled` |
| `current_phase` | `fetching` \| `preloading` \| `processing` \| `finalizing` |
| contadores | `total_records`, `processed_records`, `created_records`, `updated_records`, `skipped_records`, `failed_records` |
| `errors` | array de objetos `{ row, field?, error }` |
| `entity_stats` | `{ contacts?, contracts?, titles?, supplies?, supply_titles? }` com `created/updated/skipped` e, para títulos, `removed?`/`restored?` |
| tempos | `started_at`, `completed_at`, `last_heartbeat` |

#### 2.4.1 Divergência de tipo em `run_type`

O tipo TS declara `run_type: "manual" | "scheduled"`, mas `useRunPipeline` insere `run_type: testMode ? "test" : "manual"` (`src/hooks/etl/useJobRuns.ts` linha 147). O `PipelineHistoryDialog` renderiza `run.run_type === "manual" ? "Manual" : "Agendado"` — ou seja, **uma execução de teste aparece rotulada como "Agendado"** no histórico.
⚠️ A confirmar: se isso é bug conhecido ou comportamento aceito.

### 2.5 Lote (`etl_batch_jobs`)

O frontend **não expõe lotes**. Eles existem no backend (lotes de 300, ondas de 6) e só aparecem indiretamente na barra de progresso estimada e nas fases. Nenhuma tela desta página lista batches.

### 2.6 Campo personalizado (`custom_field_definitions`)

Campo extra por entidade, gravado em `custom_fields` (JSONB) da entidade. Estrutura (`src/hooks/etl/types.ts` linhas 179-190):

```
{ id, entity_type, field_name, display_name, field_type, options?, is_required, is_active, created_at, updated_at }
```

`field_type` ∈ `text | number | date | boolean | select`.

### 2.7 Mapeamento

Par (campo de origem → campo de destino), com a entidade de destino embutida no valor: `"id_titulo": "titles:title_number"`. No wizard, o objeto de trabalho é `FieldMapping` (`PipelineWizard/types.ts` linhas 5-14):

```
{ sourceField, targetTable, targetField, isCustomField, customFieldType?, isRequired?, isLookup?, lookupSource? }
```

Na serialização (`usePipelineWizard.handleSubmit`), campo customizado vira `entidade:custom_fields.<nome>`, e um mesmo `sourceField` com 2+ destinos vira array.

### 2.8 Lookup (campo de vínculo auto-ligado)

Definido em `LOOKUP_FIELDS` (`src/hooks/etl/constants.ts` linhas 298-312):

| Entidade | Campo lookup | Origem | Campo de origem | Label |
|---|---|---|---|---|
| `contacts` | — | — | — | (sem lookup) |
| `contracts` | `contact_document` | `contacts` | `document` | Documento (CPF/CNPJ) do contato |
| `titles` | `contract_number` | `contracts` | `contract_number` | Número do Contrato |
| `supplies` | `contact_document` | `contacts` | `document` | Documento (CPF/CNPJ) do contato |
| `supply_titles` | `supply_number` | `supplies` | `supply_number` | Número do Suprimento |

Lookups são **auto-preenchidos** a partir do mapeamento da entidade de origem e **não** têm combobox editável — aparecem num bloco separado "Campos Vinculados Automaticamente".

### 2.9 Normalização

Tradução de **valores** (não de campos): `"em_aberto" → "Disponivel"`. Só se aplica a três campos-alvo (`VALUE_MAPPING_FIELDS` em `NormalizationStep.tsx` linha 45): `status`, `modality`, `payment_method`.

Resolução do tipo de valor-padrão por entidade (`DB_FIELD_TYPE_MAP`, linhas 50-53):

| Entidade | Campo | `field_type` na tabela `standard_values` |
|---|---|---|
| `contracts` | `status` | `contract_status` |
| `contracts` | `modality` | `modality` |
| `titles` | `status` | `status` |
| `titles` | `payment_method` | `payment_method` |

> Nota: `supplies` e `supply_titles` **não** estão no `DB_FIELD_TYPE_MAP`. Nesses casos o código cai no fallback `mapping.targetField` (ex.: `"status"`), pegando os valores-padrão de título.

### 2.10 Materialização

Rotina que refresca `mv_titles_base` (a base pré-calculada que `vw_titles_live` expõe). Modelo vigente (IAF-4021): **por agendamento cron**, executado por um supervisor in-DB (`public.process_mv_refresh()`), com heartbeat de 1 minuto. Edge Functions **não** refrescam mais a MV. A aba é o painel de controle dessa rotina.

### 2.11 Cadeia conceitual completa

```
Fonte de Dados ──(1:N)── Pipeline ──(1:N)── Execução (job run) ──(1:N)── Erro de linha
                              │                       │
                              │                       └── entity_stats por entidade
                              └── field_mapping · transform_rules · dedup · schedule_cron

Campos Personalizados ─── alimentam os destinos de mapeamento (por entidade)

Materialização ─── independente dos pipelines, mas o card de agendamento LÊ os crons
                   dos pipelines para avisar sobre colisão de horário
```

---

## 3. Anatomia visual da tela (abas, ordem, barra de ações)

Fonte: `src/pages/ETLPage.tsx` linhas 296-413.

### 3.1 Estrutura vertical

```
┌────────────────────────────────────────────────────────────────────┐
│ h1 "Fonte de Dados"                             [RefreshButton ⟳] │  ← flex justify-between
│ p  "Gerencie fontes de dados, pipelines de importacao e campos..." │
├────────────────────────────────────────────────────────────────────┤
│ [TabsList: 5 abas]                          [+ <label dinâmico>]   │  ← flex justify-between
├────────────────────────────────────────────────────────────────────┤
│ Card > CardContent > Input de busca com ícone Search à esquerda    │  ← só se aba ≠ materializacao
├────────────────────────────────────────────────────────────────────┤
│ TabsContent (mt-4) — conteúdo da aba ativa                          │
└────────────────────────────────────────────────────────────────────┘
+ Dialogs montados fora: PipelineDetailDialog, PipelineHistoryDialog,
  DataSourceWizard, PipelineWizard
```

### 3.2 As 5 abas, na ordem do código

| # | `value` | Label | Ícone | Componente |
|---|---|---|---|---|
| 1 | `sources` | Fontes de Dados | `Database` | `DataSourcesTab` |
| 2 | `pipelines` | Pipelines | `ArrowRightLeft` | `PipelinesTab` |
| 3 | `custom-fields` | Campos Personalizados | `Settings2` | `CustomFieldsTab` |
| 4 | `portfolios` | Carteiras | `Briefcase` | `PortfoliosTab` (fora do escopo deste documento) |
| 5 | `materializacao` | Materializacao | `DatabaseZap` | `MaterializationTab` |

Aba inicial: `sources` (`useState("sources")`, linha 48).
Os `TabsTrigger` usam `className="gap-2"` (ícone + texto).

> Grafia: os labels "Materializacao" e "Pipelines de importacao" aparecem **sem acento** no código-fonte da página, enquanto outras partes da tela usam acentuação normal ("Descrição", "Execução"). A inconsistência de acentuação é generalizada no domínio ETL.

### 3.3 Barra de ações — botão "+" contextual

Renderizado apenas quando `canWrite && activeTab !== "materializacao"` (linha 332).

| Aba ativa | Label do botão | Ação |
|---|---|---|
| `sources` | `Nova Fonte de Dados` | `setDataSourceWizardOpen(true)` |
| `pipelines` | `Novo Pipeline` | `setPipelineWizardOpen(true)` |
| `custom-fields` | `Novo Campo` | `customFieldsTabRef.current?.openCreateModal()` |
| `portfolios` | `Nova Carteira` | `portfoliosTabRef.current?.openCreateModal()` |
| (default) | `Novo` | — |

Ícone `Plus` (`mr-2 h-4 w-4`).

### 3.4 Barra de busca — placeholder contextual

Renderizada quando `activeTab !== "materializacao"` (linha 341). Um único estado `search` compartilhado por **todas** as abas — trocar de aba **não limpa** o termo digitado.

| Aba | Placeholder |
|---|---|
| `sources` | `Buscar fontes de dados...` |
| `pipelines` | `Buscar pipelines...` |
| `custom-fields` | `Buscar campos personalizados...` |
| `portfolios` | `Buscar carteiras...` |
| (default) | `Buscar...` |

Comportamento do filtro:
- `sources` e `pipelines`: **server-side**, via `ilike("name", %termo%)` nos hooks `useDataSources`/`usePipelines` (com `escapeLikePattern`). Sem debounce — cada tecla dispara nova query.
- `custom-fields`: **client-side**, filtra por `display_name` **ou** `field_name` (case-insensitive).
- `portfolios`: fora do escopo.

### 3.5 Botão Atualizar (canto superior direito)

`RefreshButton` (`src/components/common/RefreshButton.tsx`). Comportamento por aba (`handleRefresh`, linhas 274-291):

| Aba | O que recarrega |
|---|---|
| `sources` | `refetchSources()` |
| `pipelines` | `refetchPipelines()` |
| `materializacao` | invalida `["mv-refresh-status"]`, `["mv-refresh-settings"]`, `["mv-refresh-runs"]` |
| outras | invalida `["custom-field-definitions"]` e `["portfolios"]` |

O spinner (`isFetching`) só reflete `sources` e `pipelines`; nas demais abas o prop `isFetching` é `false` (linha 293), mas o `RefreshButton` ainda gira enquanto a promise interna estiver pendente. Atributos de acessibilidade: `aria-label`, `aria-busy`, `title`.

### 3.6 Alternância grade/lista (ViewToggle)

Só existe nas abas `sources` e `pipelines`. Componente `ViewToggle` (`src/components/ui/view-toggle.tsx`): dois botões-ícone (`LayoutGrid` e `List`), 32×32, dentro de um container `rounded-lg border bg-muted/30 p-0.5`. Renderizado **dentro** do conteúdo da aba, alinhado à direita (`flex justify-end`), acima da grade/tabela.

Persistência: `useViewPreference(pageKey)` grava em `localStorage` sob a chave `view-preference-etl-sources` / `view-preference-etl-pipelines`. Default `card`.

### 3.7 Toda escrita passa por `window.confirm`

A tela não usa `AlertDialog` para confirmações destrutivas (exceto o `DataSourceSkillViewer`, que é código órfão). Confirmações via `confirm()` nativo:

| Ação | Texto |
|---|---|
| Excluir fonte | `Tem certeza que deseja excluir esta fonte de dados? Pipelines associados tambem serao afetados.` |
| Excluir pipeline | `Tem certeza que deseja excluir este pipeline?` |
| Executar pipeline | `Executar o pipeline "<nome>"?` |
| Testar pipeline | `Testar o pipeline "<nome>" com as primeiras 100 linhas?` |
| Cancelar execução | `Tem certeza que deseja cancelar esta execucao?` |
| Marcar job como falho | `Marcar esta execucao como falha?` |
| Excluir campo personalizado | `Tem certeza que deseja excluir o campo "<nome>"? Esta ação não pode ser desfeita.` |

Não há confirmação para: pausar/retomar agendamento, retomar job travado, pausar/retomar materialização, forçar atualização da MV, salvar agendamento da MV.

---

## 4. Aba Fontes de Dados: lista/cards, colunas, status, ações, teste de conexão

Fonte: `src/components/etl/tabs/DataSourcesTab.tsx`.

### 4.1 Contrato do componente

```ts
interface DataSourcesTabProps {
  dataSources: DataSource[] | undefined;
  isLoading: boolean;
  search: string;
  view: ViewMode;
  onViewChange: (view: ViewMode) => void;
  onEdit: (source: DataSource) => void;
  onDelete: (id: string) => void;
  onOpenWizard: () => void;
}
// ref: { openCreateModal: () => void }  → aponta para onOpenWizard
```

### 4.2 Estado de carregamento

`<GridCardSkeleton count={6} columns={3} />` — 6 cartões esqueleto em grade `md:grid-cols-2 lg:grid-cols-3`. Cada esqueleto: bloco 40×40 arredondado + duas linhas de texto + bloco 32×32 à direita + 2 linhas no corpo.

### 4.3 Estado vazio

`Card > CardContent(py-0) > EmptyState`:
- Ícone: `Database` (48×48, `text-muted-foreground/50`)
- Título: `Nenhuma fonte de dados encontrada`
- Descrição: `Tente ajustar os filtros de busca` (se há `search`) ou `Configure sua primeira fonte de dados`
- Ação: botão `+ Nova Fonte` — **só aparece se não houver termo de busca**. Não checa `canWrite` (ver 15.6).
- `EmptyState` tem `role="status" aria-live="polite"`.

### 4.4 Visão Grade (default)

Grade `md:grid-cols-2 lg:grid-cols-3`, gap 4. Cada card (`hover:shadow-md transition-shadow`):

```
┌───────────────────────────────────────────────┐
│ [ícone]  <name>                          [⋮]  │  CardHeader pb-2
│  40×40   <label do tipo>                      │  ícone em bg-primary/10, p-2, rounded-lg
├───────────────────────────────────────────────┤
│ <descrição DO TIPO> (text-sm muted)           │  CardContent
│ Criado em dd/mm/aaaa (text-xs muted, mt-2)    │
└───────────────────────────────────────────────┘
```

**Importante para o redesenho:** o texto do corpo **não** é `source.description` — é `sourceType.description`, a descrição genérica do *tipo* (ex.: "Google BigQuery data warehouse"). A descrição que o usuário escreveu no wizard **não é exibida em lugar nenhum desta aba**.

### 4.5 Visão Lista

Tabela com borda arredondada. Colunas:

| Coluna | Conteúdo | Largura |
|---|---|---|
| Nome | ícone (24×24 em `bg-primary/10`) + `source.name` em `font-medium` | auto |
| Tipo | `<Badge variant="outline">{sourceType.label}</Badge>` | auto |
| Descricao | `sourceType.description` (muted, `max-w-[300px] truncate`) | auto |
| Criado em | `new Date(created_at).toLocaleDateString("pt-BR")` | auto |
| (ações) | `⋮` DropdownMenu | `w-[70px]` |

Cabeçalho da coluna 3 é literalmente `Descricao` (sem cedilha/acento).

### 4.6 Ações (DropdownMenu `⋮`, align end)

| Item | Ícone | Efeito |
|---|---|---|
| Editar | `Edit` | `onEdit(source)` → abre o `DataSourceWizard` em modo edição |
| — separador — | | |
| Excluir | `Trash2` (`className="text-destructive"`) | `confirm(...)` e, se OK, `onDelete(source.id)` |

**Não há gate de `canWrite` nesta aba** — Editar e Excluir aparecem para qualquer um que chegue na tela (`etl:read`). É uma divergência em relação à aba Pipelines, que gateia.

### 4.7 Status de uma fonte

A aba **não exibe** `is_active`, `last_sync_at`, `last_sync_status` nem `last_sync_error`, embora todos existam no tipo `DataSource`. Não há indicador de saúde de fonte, nem contagem de pipelines que a usam, nem "última sincronização".

### 4.8 Teste de conexão

**Não existe na aba.** O teste de conexão vive exclusivamente **dentro do wizard**, no passo 2, e **apenas para BigQuery** (ver 5.4.6). Para REST API, PostgreSQL e MySQL não há botão de teste em lugar nenhum.

### 4.9 Exclusão em cascata (efeito real do "Excluir")

`useDeleteDataSource` (`src/hooks/etl/useDataSources.ts` linhas 121-195) executa, em sequência, no cliente:
1. busca `etl_pipelines` com `data_source_id = id`;
2. para cada pipeline, busca `etl_job_runs` e apaga os `etl_job_errors` correspondentes;
3. apaga os `etl_job_runs` do pipeline;
4. apaga os pipelines;
5. apaga a fonte, com `ensureDeleted(...)`.

Em erro: toast `variant: destructive`, título `Erro ao excluir`, descrição de `getDeleteErrorMessage(error)`. Invalida `["data-sources"]` e `["etl-pipelines"]`.

O texto da confirmação diz "Pipelines associados tambem serao afetados" — na prática eles são **excluídos**, junto com todo o histórico de execuções e erros. O texto subestima o efeito.

---

## 5. Wizard de Fonte de Dados — passo a passo, por tipo de fonte (todos os campos)

Fonte: `src/components/etl/wizards/DataSourceWizard/index.tsx` (1377 linhas) + `steps/*` + `types.ts`.

### 5.1 Casca do modal

| Propriedade | Valor |
|---|---|
| Container | `<Dialog open={open && !pipelineWizardOpen}>` |
| `DialogContent` | `flex flex-col p-0 w-[95vw] h-[95vh]` — quase tela cheia |
| Título | `Nova Fonte de Dados` ou `Editar Fonte de Dados` |
| Descrição | `Configure sua fonte de dados em 3 etapas simples` |
| Header | `px-6 py-4 border-b bg-gradient-to-r from-primary/5 to-transparent` |
| Stepper | faixa `px-6 py-4 border-b bg-muted/30` |
| Corpo | `flex-1 overflow-y-auto px-6 py-6 relative`, conteúdo limitado a `max-w-3xl mx-auto` |
| Rodapé | `px-6 py-4 border-t bg-muted/30` |
| Fechar | `onOpenChange={handleClose}` → `resetWizard()` + `onClose()` — **sem confirmação de descarte** |

### 5.2 Os 3 passos

`DATA_SOURCE_WIZARD_STEPS` (`types.ts` linhas 87-91):

| id | title | description |
|---|---|---|
| 1 | Tipo | Escolha a fonte |
| 2 | Configuração | Configure a conexão |
| 3 | Preview | Valide os dados |

### 5.3 Stepper e navegação

`WizardStepper` variante horizontal (`wizards/shared/WizardStepper.tsx`):
- Indicador circular 32×32: número do passo, ou `Check` quando concluído.
- Estados: `active` (bg-primary + `ring-4 ring-primary/20`), `completed` (bg-primary), `error` (bg-destructive), `pending` (bg-muted + borda).
- Título e descrição do passo ficam `hidden sm:block` — **em telas < 640px só aparecem os círculos**.
- Linha conectora `h-0.5 bg-border` entre passos, preenchida quando o passo anterior está em `completedSteps`. **`completedSteps` nunca é passado pelo DataSourceWizard**, então a linha conectora nunca preenche e nenhum passo mostra o ✓. ⚠️ A confirmar: se é intencional.
- `aria-current="step"` no passo ativo.

Regras de clique no stepper (`index.tsx` linhas 1188-1198):

| Modo | Comportamento |
|---|---|
| Criação (`editingSource == null`) | `allowFreeNavigation=false`. Só permite **voltar** (`step < currentStep`). |
| Edição | `allowFreeNavigation=true`. Qualquer passo é clicável, roteado por `handleStepJump`. |

`handleStepJump` (linhas 891-920): se o salto **cruza a fronteira 2→3 para frente** e o tipo é `bigquery` ou `rest_api`, re-executa a query antes de mudar de passo; se a query falhar, **volta/permanece no passo 2**.

Rodapé (`WizardNavigation`):
- Esquerda: `Voltar` (desabilitado no passo 1).
- Centro: `Etapa {n} de 3`.
- Direita: `Continuar` nos passos 1-2; no passo 3 muda conforme o modo (ver 5.7).
- Estado `isSubmitting` do rodapé agrega: `isSubmitting || isFetchingBigQuery || isFetchingRestApi || isLoadingPreview`.

### 5.4 Passo 1 — Tipo (`TypeSelectionStep.tsx`)

| Campo | Tipo | Obrigatório | Default | Validação |
|---|---|---|---|---|
| `Nome da Fonte de Dados *` | `Input` (id=`name`, `autoFocus`) | Sim | `""` (ou nome atual, ao editar) | `sourceName.trim() !== ""` trava o `Continuar` |
| `Descrição (opcional)` | `Textarea` rows=2 (id=`description`) | Não | `""` | — |
| `Tipo de Fonte *` | Grade de cards clicáveis | Sim | `csv` | Sempre válido (há default) |

Placeholders:
- Nome: `Ex: Base de clientes, Planilha de vendas...`
- Descrição: `Descreva a origem e propósito dos dados...`

Grade de tipos: `grid-cols-2 md:grid-cols-3 gap-3`. Cada tipo é um `Card` clicável com:
- Ícone 20×20 em bloco `p-2 rounded-lg`; quando selecionado, `bg-primary text-primary-foreground`, senão `bg-muted`.
- Nome (`font-medium truncate`) e descrição (`text-xs muted truncate`).
- Card selecionado: `ring-2 ring-primary border-primary`.

Acessibilidade: os cards são `<Card onClick>` — **não são `<button>` nem `<input type=radio>`**, não têm `role`, `tabIndex` nem `aria-pressed`. Não são alcançáveis por teclado.

### 5.4.1 Passo 2 — visão geral

`ConfigurationStep` (`steps/ConfigurationStep.tsx`, 1081 linhas) é um roteador por `sourceType`. Todos os tipos recebem, ao final, o mesmo `AdvancedSettingsCard` (verificação de pagamento).

| `sourceType` | Bloco principal renderizado |
|---|---|
| `csv` | Dropzone de CSV |
| `cnab` | Dropzone de CNAB + card explicativo |
| `bigquery` | `BigQueryConfigForm` (auth + projeto + query + testar conexão) |
| `rest_api` | URL + método + headers |
| `postgresql` / `mysql` | Host/porta/database/usuário/senha/query |
| (outro) | `return null` |

Abaixo do `ConfigurationStep`, no passo 2, a `index.tsx` ainda renderiza dois `Alert variant="destructive"` condicionais:
- `bigQueryError` → título `Erro ao conectar com BigQuery:` + mensagem.
- `restApiError` → título `Erro ao conectar com a API:` + mensagem.

### 5.4.2 Passo 2 — CSV

```
┌─── border-2 border-dashed rounded-lg p-8 text-center ───┐
│           [Upload 48×48]                                │
│   Arraste um arquivo CSV ou clique para selecionar      │
│   Formatos aceitos: .csv (UTF-8)                        │
└─────────────────────────────────────────────────────────┘
```

- `<input type="file" accept=".csv" className="hidden">` dentro de um `<label>`.
- Enquanto `isUploading`: `Loader2` 48×48 girando no lugar do conteúdo.
- Com arquivo carregado: ícone `FileSpreadsheet` 48×48 `text-primary`, nome do arquivo em `font-medium`, legenda `Arquivo carregado com sucesso` (se há `File` em memória) ou `Dados carregados do banco` (edição, sem File), e botão `Remover arquivo` (`variant=outline size=sm`, ícone `X`).
- Texto diz "Arraste um arquivo" mas **não há handler de drag-and-drop** — só clique. ⚠️ A confirmar: se o drop é suportado por comportamento nativo do label (não é).

Parsing (`handleCsvUpload`, index.tsx linhas 377-435):
1. `parseFileWithEncoding(file)` — detecção de encoding.
2. `Papa.parse(conteúdo, { header: true, skipEmptyLines: "greedy" })`.
3. Filtra linhas totalmente vazias.
4. `setTotalRecords(data.length)`, `setFullCsvData(data)`.
5. `previewData = data.slice(0, 100)` (`PREVIEW_LIMIT`).
6. Detecta campos: cabeçalhos do primeiro registro; `sampleValues` = 5 primeiras linhas; tipo por `detectFieldType`.

### 5.4.3 Passo 2 — CNAB

Mesma dropzone, com:
- `accept=".ret,.rem,.txt"`.
- Ícone `Landmark` 48×48.
- Textos: `Arraste um arquivo CNAB ou clique para selecionar` / `Formatos aceitos: .ret, .rem, .txt (CNAB 240 ou 400)`.

Com arquivo carregado, exibe um bloco de metadados extras vindos do parser (`cnabResult`):

| Linha | Conteúdo |
|---|---|
| Registros | `{cnabResult.total_registros ?? 0} registros detectados` (+ ` (dados carregados do banco)` se não há File) |
| Formato | `cnabResult.format.toUpperCase()` |
| Banco | `cnabResult.banco` |
| Data do arquivo | `cnabResult.data_arquivo` (se houver) |
| Erros de parsing | `{n} erros de parsing` em `text-destructive` (se `errors.length > 0`) |

Leitura: `FileReader.readAsText(file, "latin1")` → `parseCnab(content)` → `cnabRecordsToEtlData(result.records)`. O campo `custom_fields` é ignorado na detecção de colunas.

Card informativo fixo abaixo da dropzone — título `Sobre arquivos CNAB`, com três parágrafos explicando CNAB, arquivos `.ret` (retorno) e `.rem` (remessa).

### 5.4.4 Passo 2 — BigQuery (`BigQueryConfigForm`)

Formulário mais complexo da tela. Campos na ordem:

**A. Método de Autenticação**

| Campo | Controle | Obrigatório | Default | Opções |
|---|---|---|---|---|
| `Método de Autenticação *` | `Select` | Sim | `service_account` | `service_account` → "Service Account (JSON)"; `oauth2` → "OAuth2 (Client ID/Secret)" |

Texto de ajuda muda com a escolha:
- oauth2: `Use OAuth2 para autenticação interativa com usuário`
- service_account: `Use Service Account para automações e integrações server-to-server`

Trocar o método **limpa** o resultado do teste de conexão.

**B. Credenciais — Service Account** (`bq_auth_type === "service_account"`)

Subtítulo `Credenciais Service Account` + `Faça upload do arquivo JSON ou cole o conteúdo`.

Estado *travado* (`credentialsLocked = isEditing && !!config.credentials_json`):
```
┌ p-4 border rounded-lg bg-muted/30 ──────────────────────────────┐
│ [Shield verde]  Credenciais configuradas                        │
│                 As credenciais estão salvas de forma segura.    │
│                 Para alterar, clique em substituir.  [Substituir]│
└─────────────────────────────────────────────────────────────────┘
```
`Substituir` (`variant=outline size=sm`, ícone `RefreshCw`) destrava, **limpa `credentials_json`** e zera o resultado do teste.

Estado destravado — dois caminhos alternativos:

| Campo | Controle | Obrigatório | Detalhe |
|---|---|---|---|
| `Upload do arquivo JSON *` | `<input type="file" accept=".json">` em dropzone tracejada (`Escolher arquivo JSON`) | Sim (ou colar) | Ao ler, valida **imediatamente** via `validateServiceAccountJson` e mostra o erro no mesmo painel de resultado do teste |
| `Ou cole o JSON manualmente` | `Textarea` rows=6, `font-mono text-xs` | — | Placeholder: `{\n "type": "service_account",\n "project_id": "...",\n "private_key_id": "...",\n ...\n}`. Digitar aqui **limpa** o nome do arquivo exibido. Ajuda: `Baixe o arquivo JSON da Service Account no Console do GCP` |

Com arquivo escolhido, o campo vira uma linha com ícone `FileSpreadsheet`, o nome do arquivo (truncado) e um botão `X` para remover (que também limpa `credentials_json`).

Validação de forma do JSON (`src/lib/etl/bigquery-credentials.ts`) — mensagens exatas:

| Situação | Mensagem |
|---|---|
| vazio | `Informe o JSON da chave da Service Account (envie o arquivo .json ou cole o conteúdo).` |
| não é JSON | `O conteúdo informado não é um JSON válido. Envie o arquivo .json da chave da Service Account sem editar — se colou manualmente, confira se veio inteiro.` |
| não é objeto | `O JSON informado não é um objeto. Esperado o arquivo da chave da Service Account, que começa com { e tem os campos client_email e private_key.` |
| é OAuth Client ID (`installed`/`web`) | `Este é um JSON de OAuth 2.0 Client ID, não de Service Account. Na tela de Credenciais do Google Cloud os dois ficam lado a lado: abra a Service Account, aba Chaves, e crie/baixe uma chave (o arquivo tem "type": "service_account" e um campo private_key).` |
| falta `client_email` e/ou `private_key` | `O JSON informado é válido, mas não tem <campos>. Isso normalmente significa que o arquivo baixado não é a chave da Service Account — confira se abriu a Service Account no Google Cloud, aba Chaves, e baixou uma chave em JSON.` |
| `private_key` sem PEM | `O campo private_key existe mas não contém uma chave PEM (falta o trecho -----BEGIN PRIVATE KEY-----). O arquivo pode ter sido editado ou colado pela metade.` |

Essas mensagens são **espelhadas** na Edge Function (`_shared/bigquery-credentials.ts`) e há um teste de paridade que quebra se divergirem.

**C. Credenciais — OAuth2** (`bq_auth_type === "oauth2"`)

Subtítulo `Credenciais OAuth2` + `Configure as credenciais OAuth2 do Google Cloud`.

| Campo | Controle | Obrigatório | Placeholder |
|---|---|---|---|
| `Client ID *` | `Input` | Sim | `seu-client-id.apps.googleusercontent.com` |
| `Client Secret *` | `Input type="password"` | Sim | `SEU_CLIENT_SECRET` |
| `Refresh Token *` | `Textarea` rows=2 | Sim | `SEU_REFRESH_TOKEN` — ajuda: `Obtenha o refresh token através do fluxo de autorização OAuth2` |

Qualquer edição limpa o resultado do teste.

**D. Configuração do Projeto** (bloco `pt-4 border-t`)

| Campo | Controle | Obrigatório | Placeholder / ajuda |
|---|---|---|---|
| `Project ID *` | `Input` | **Sim** (trava o avanço) | `meu-projeto-gcp` |
| `Dataset ID (opcional)` | `Input` | Não | `meu_dataset (ou deixe vazio para especificar na query)` · ajuda: `Deixe vazio se sua query SQL incluir o dataset completo (ex: projeto.dataset.tabela)` |
| `Table ID (opcional)` | `Input` | Não | `minha_tabela (ou deixe vazio para query customizada)` · ajuda: `Deixe vazio se for usar uma query SQL customizada abaixo` |
| `Query SQL (opcional se Table ID preenchido)` | `SqlEditor` (`minHeight="120px"`) | Não | `SELECT * FROM \`projeto.dataset.tabela\` WHERE ... LIMIT 1000` · ajuda: `Escreva uma query SQL customizada. Use LIMIT para restringir os resultados. Se não informar a query, será feito SELECT * da tabela especificada.` |

O rótulo "(opcional)" é renderizado como `<span className="text-muted-foreground font-normal">`.

**E. Testar Conexão** (bloco `pt-4 border-t`)

- Botão `Testar Conexão` (`variant=outline`, ícone `Zap`), desabilitado enquanto `!canTestConnection()` ou já testando; enquanto testa vira `Loader2` + `Testando...`.
- `canTestConnection()`: exige `project_id` **e** (oauth2: `client_id` + `client_secret` + `refresh_token`; service_account: `credentials_json`).
- Quando desabilitado, mostra ao lado: `Preencha as credenciais e o Project ID para testar`.
- O teste invoca a EF `bigquery-query` com `query: "SELECT 1 as test"` e `max_results: 1`, precedido da validação local de forma (evita mandar ~56 KB para receber 400).
- Resultado num `Alert`:
  - sucesso: `variant="default"`, ícone `CheckCircle2` verde, texto `Conexão estabelecida com sucesso!` em `text-green-700`;
  - falha: `variant="destructive"`, mensagem da EF extraída de `error.context` via `readFunctionErrorMessage` (senão `Erro ao conectar com BigQuery`), ou `Falha na autenticação com BigQuery`.

### 5.4.5 Passo 2 — REST API

| Campo | Controle | Obrigatório | Default | Placeholder |
|---|---|---|---|---|
| `URL do Endpoint *` | `Input` | **Sim** (trava avanço) | `""` | `https://api.example.com/data` |
| `Método HTTP` | `Select` | Não | `GET` | Opções: `GET`, `POST` |
| `Headers (JSON)` | `Textarea` rows=3 | Não | `""` | `{"Authorization": "Bearer token"}` |

Não há campo de **body** no formulário, embora `SourceConfig.body` exista no tipo e seja usado em `executeRestApiQuery` quando o método é POST. ⚠️ A confirmar: body só é preenchível editando o registro fora da UI.

Headers inválidos (JSON malformado) são **silenciosamente ignorados** (`catch {}`) na execução.

### 5.4.6 Passo 2 — PostgreSQL / MySQL

Layout: dois `grid-cols-2` intercalados com campos de largura total.

| Campo | Controle | Obrigatório | Placeholder |
|---|---|---|---|
| `Host *` | `Input` | **Sim** | `localhost` |
| `Porta` | `Input` | Não | `5432` (postgresql) / `3306` (mysql) |
| `Database *` | `Input` | **Sim** | `my_database` |
| `Usuário` | `Input` | Não | `admin` |
| `Senha` | `Input type="password"` | Não | `********` |
| `Query SQL` | `Textarea` rows=4 | Não | `SELECT * FROM my_table WHERE ...` |

**Não há teste de conexão, nem busca de preview.** Ao avançar para o passo 3, `detectedFields` fica vazio e o `Continuar`/`Criar` é travado por `canProceed()` do passo 3 (`detectedFields.length > 0`). Na prática, **é impossível concluir o wizard para PostgreSQL/MySQL pela UI**.
⚠️ A confirmar: se esses dois tipos estão ativos em produção ou são placeholders.

### 5.4.7 Card "Configuracoes Avancadas" (verificação de pagamento)

Renderizado **em todos os tipos**, ao fim do passo 2. Componente interno `AdvancedSettingsCard` (linhas 126-349).

Cabeçalho: ícone `Zap` + `Configuracoes Avancadas` (`CardTitle text-sm`).

| Campo | Controle | Detalhe |
|---|---|---|
| `URL Base de Verificacao de Pagamento` | `Input` | Placeholder `https://api.example.com/check-payment`. Ajuda: `Endpoint base para verificar se o titulo foi pago antes do disparo.` |
| `Campos enviados na verificacao` | Checkboxes agrupados | 3 grupos (ver tabela abaixo), `grid-cols-2` dentro de cada grupo. Rótulo do grupo em `text-xs font-semibold uppercase tracking-wide` |
| `URL Final` | `Input` `font-mono text-xs` | Mostra a URL gerada (modo automático) ou a digitada (modo manual) |

Catálogo de campos (`PAYMENT_CHECK_FIELDS`, linhas 39-48):

| Grupo | Variável | Param na URL | Label | Marcado por padrão |
|---|---|---|---|---|
| Titulo | `title.number` | `title` | Num. do titulo | ✅ |
| Titulo | `title.id` | `title_id` | ID do titulo | — |
| Contrato | `contract.number` | `contract` | Num. do contrato | ✅ |
| Contrato | `contract.id` | `contract_id` | ID do contrato | — |
| Contrato | `contract.external_id` | `external_id` | ID externo | — |
| Contato | `contact.document` | `document` | Documento (CPF/CNPJ) | ✅ |
| Contato | `contact.id` | `contact_id` | ID do contato | — |
| Contato | `contact.name` | `name` | Nome | — |

Modos:

| Modo | Badge | Comportamento |
|---|---|---|
| Automático | `Automatico` (verde, `bg-emerald-50 text-emerald-700`) | A URL Final é gerada por `buildPaymentCheckUrl(baseUrl, selectedParams)`: `base?param={{var}}&...`. Ajuda: `Gerada automaticamente. Editar diretamente ativa o modo manual.` |
| Manual | `Manual` (âmbar, `bg-amber-50 text-amber-700`) | Ativado assim que o usuário **digita** no campo URL Final. Os checkboxes ficam `opacity-50 pointer-events-none` e desabilitados. Aparece o link `Resetar para automatico` |

`Resetar para automatico` tenta re-parsear a URL manual (`parsePaymentCheckUrl`); se todos os params forem reconhecidos, restaura base + checkboxes; senão regenera a partir do estado atual.

Inicialização (`useEffect` com guarda `initialized`): sem URL salva → marca os 3 defaults; com URL parseável → modo automático com os params detectados; com URL não parseável (ex.: path-based com `{{}}`) → modo manual.

Rodapé do card: lista de todas as 8 variáveis em `<code className="bg-muted px-1 rounded">`, precedida de `Variaveis disponiveis:`.

> Observação de domínio: o `CLAUDE.md` da Torre documenta **11** variáveis de payment check (`title.title_number`, `action.type`, `action.channel` entre elas). A UI só oferece **8**. As outras 3 só entram digitando no modo manual.

### 5.5 Passo 3 — Preview (`PreviewStep.tsx`)

Composto por três blocos:

**A. `MetadataCard`** (`wizards/shared/MetadataCard.tsx`)

Caixa `bg-gradient-to-br from-muted/50 to-muted/20 rounded-xl border p-4` com:

| Métrica | Ícone | Cor do ícone | Valor |
|---|---|---|---|
| Colunas | `Columns3` | `text-blue-500` | `detectedFields.length` |
| Registros | `Rows3` | `text-green-500` | `totalRecords` (formatado pt-BR) |

Se `totalRecords > 5000`, o cartão "Registros" ganha badge `Grande volume` (âmbar).
Se `warnings.length === 0 && totalRecords > 0`, rodapé verde com `CheckCircle2` + `Dados validados com sucesso`.

O `PreviewStep` **não passa** `fields`, `fileName`, `sourceType` nem `warnings` — então o header do card e o breakdown de tipos detectados **nunca aparecem** neste uso (existem no componente mas ficam mortos aqui).

**B. `LargeDatasetInfo`** — renderizado quando `totalRecords > 1000` **pelo PreviewStep**, mas o próprio componente retorna `null` se `totalRecords <= 5000`. Efeito líquido: só aparece acima de 5000.

Conteúdo: caixa azul (`bg-blue-500/10 border-blue-200`) com ícone `Info`, título `Processamento otimizado ativado` e texto: `Com {N} registros, o sistema utilizará processamento em lotes para garantir performance. O preview mostra uma amostra representativa dos dados.`

**C. Tabela de preview** (`DataPreviewTable`)

Cabeçalho da seção: `Preview dos Dados` à esquerda; `Mostrando {n} de {total} registros` à direita.

`DataPreviewTable` (`wizards/shared/DataPreviewTable.tsx`):
- Virtualização de linhas via `@tanstack/react-virtual` (`ROW_HEIGHT = 40`, overscan 5, altura máxima = 10 linhas).
- Colunas com largura fixa de **160px** cada; `minWidth = fields.length * 160`; scroll horizontal via `ScrollBar orientation="horizontal"`.
- Cabeçalho `sticky top-0 z-10 bg-muted/50`, com nome do campo (truncado) + badge de tipo.
- Linhas zebradas (`bg-background` / `bg-muted/20`).
- Barra de info (quando mostrando parcial): `Mostrando N de M registros` + badge `Preview`.
- Vazio (`fields.length === 0`): caixa tracejada h-40 com `Nenhum dado disponível para visualização`.

Badges de tipo (`FieldTypeBadge`):

| Tipo | Rótulo | Cores |
|---|---|---|
| `string` | `Abc` | azul |
| `number` | `123` | verde |
| `date` | `📅` | laranja |
| `boolean` | `✓/✗` | roxo |
| `unknown` | `?` | cinza |

Formatação de célula (`formatCellValue`): `null`/`undefined` → `—`; array vazio → `[]`; array de objetos → `[N itens]`; array simples → join por `, `; objeto → `{k1, k2...}`; boolean → `Sim`/`Não`.

**D. Botão "Re-executar query"** — só em modo edição e só para `bigquery`/`rest_api` (index.tsx linhas 1266-1281). Botão outline com ícone `RefreshCw` (gira enquanto carrega), alinhado à direita acima do preview. Re-roda a query sem trocar de passo.

### 5.6 Regras de avanço (`canProceed`)

`index.tsx` linhas 943-987:

| Passo | Condição para habilitar o botão |
|---|---|
| 1 | `sourceName.trim() !== ""` |
| 2 · csv/cnab | `(file !== null \|\| fullCsvData.length > 0) && previewData.length > 0` |
| 2 · bigquery + service_account | `!!credentials_json && !!project_id` |
| 2 · bigquery + oauth2 | `!!client_id && !!client_secret && !!refresh_token && !!project_id` |
| 2 · rest_api | `!!url` |
| 2 · postgresql/mysql | `!!host && !!database` |
| 2 · outro | `true` |
| 3 | `detectedFields.length > 0` |

Nenhuma mensagem explica **por que** o botão está desabilitado — ele fica apenas com `opacity-50 cursor-not-allowed`.

### 5.7 Transições 2→3 e busca de dados

`handleNextStep` (linhas 846-881):
1. Rola o container para o topo (`scrollTo({top:0, behavior:"smooth"})`).
2. Se passo 2 e tipo `bigquery`: `setIsLoadingPreview(true)` → `executeBigQueryQuery()`. Se falhar, **não avança**.
3. Se passo 2 e tipo `rest_api`: idem com `executeRestApiQuery()`.
4. Avança.

**Overlay de carregamento** (linhas 1205-1211): cobre o corpo (`absolute inset-0 bg-background/80 backdrop-blur-sm`), com `Loader2` 32×32 girando, `Carregando dados da fonte...` e `Executando consulta e processando preview`.

#### 5.7.1 Execução BigQuery (`executeBigQueryQuery`)

1. Guarda de reentrância `bqRunIdRef` — apenas o run mais recente aplica `setState` (IAF-4083 Fix B).
2. Monta o corpo com `auth_type`, credenciais, `project_id`, `dataset_id`, `table_id`, `max_results: 100`.
3. **Injeta LIMIT automaticamente**: se há query e ela não contém `limit` (case-insensitive), envolve em `SELECT * FROM (<query>) LIMIT 100`.
4. Invoca a EF `bigquery-query`.
5. Achata objetos aninhados (`flattenObject`, profundidade máx. 3, notação de ponto; array de objetos vira JSON + expande o `[0]`).
6. Monta a lista de colunas pela **união** do schema autoritativo (`typedResult.fields`) com as chaves de **todas** as linhas achatadas (IAF-4083 Fix A).
7. Tipa cada coluna pelo schema BQ (`INTEGER/INT64/FLOAT/FLOAT64/NUMERIC/BIGNUMERIC` → number; `DATE/DATETIME/TIMESTAMP/TIME` → date; `BOOLEAN/BOOL` → boolean; senão, heurística por amostra).
8. Ordena colunas: não-aninhadas primeiro, depois por profundidade e alfabética.
9. **Busca valores únicos** para normalização: filtra campos não-numéricos/não-data, quebra em lotes de **5**, monta `UNION ALL` de `SELECT DISTINCT ... ORDER BY COUNT(*) DESC LIMIT 500` por campo, e invoca a EF por lote com `max_results = 5*500`. Falhas parciais só logam `console.warn`; se **todos** falharem, `fetchedUniqueValues = null`.

Esse passo 9 é o que faz a transição 2→3 do BigQuery demorar segundos (N/5 chamadas sequenciais à EF). Não há indicação de progresso além do overlay genérico.

#### 5.7.2 Execução REST API (`executeRestApiQuery`)

1. `fetch(url, { method, headers })` — **direto do navegador** (sujeito a CORS).
2. Se `!response.ok`: `Erro na requisição: {status} {statusText}`.
3. Extrai o array da resposta testando, nesta ordem: array raiz → `data` → `results` → `items`. Se nenhum casar: `Não foi possível extrair array da resposta da API`.
4. Achata, seta `totalRecords`, `previewData` (100) e `fullCsvData`.
5. Detecta campos pela união das chaves das **20 primeiras** linhas (diferente do BigQuery, que usa todas).
6. **Não busca valores únicos** — a normalização depende só do preview.

### 5.8 Salvamento (`handleSubmit`)

Monta `connection_config` = cópia de `sourceConfig` **sem** `payment_check_url` (que vai no nível raiz do registro).

`query_config` montado por tipo:

| Tipo | Chaves gravadas |
|---|---|
| csv/cnab | `fileName`, `recordCount`, `fields[{name,type}]`, `sample_data` (100 linhas), `unique_values` (calculado localmente), `unique_values_source: "preview"`, `cached_at` |
| bigquery/rest_api | `fields[{name,type}]`, `sample_data` (100), `recordCount`, `unique_values` (do DISTINCT se disponível, senão do preview), `unique_values_source: "distinct"\|"preview"`, `cached_at` |

`calculateUniqueValuesForNormalization` (linhas 39-66): ignora campos `number`/`date`; ignora campos com **mais de 500** valores distintos (texto livre); guarda no máximo os 500 mais frequentes.

Upload para Storage (`uploadDataToStorage`): converte os dados em CSV (com escaping de aspas/vírgula/quebra), sobe em `etl-uploads/{orgSlug}/{dataSourceId}/{timestamp}.csv` com `upsert: true`. Retorna o path, gravado em `storage_path`.

Fluxo:
- **Edição**: se o arquivo foi trocado (`fileWasReplaced`), sobe o novo antes; monta `updatePayload` com nome, descrição, tipo, `connection_config`, `query_config` (preserva o antigo se não houver novo), `payment_check_url` e, se aplicável, `storage_path`. Chama `updateDataSource`, depois `onComplete(id)` e fecha.
- **Criação**: cria a fonte; para csv/cnab, sobe os dados e faz um **segundo** update só com `storage_path` (falha aqui é apenas logada — os dados ficam no `sample_data`); depois bifurca conforme `skipPipeline`.

Erros de salvamento são apenas logados (`logError`) — **não há toast nem mensagem na UI**. Do ponto de vista do usuário, o botão volta ao normal e nada acontece.

### 5.9 Rodapé especial do passo 3 (criação)

Quando `currentStep === 3 && !editingSource`, o rodapé padrão é substituído por (linhas 1295-1343):

```
[Voltar]              Etapa 3 de 3        [Criar sem Pipeline]  [Criar e Configurar Pipeline]
                                           (outline)             (primary, px-6)
```

- `Criar sem Pipeline` → `handleSubmit(true)`: salva e fecha.
- `Criar e Configurar Pipeline` → `handleSubmit(false)`: salva, guarda `createdDataSourceId` e abre o **PipelineWizard** encadeado, já com `sourceFields` (de `detectedFields`) e `previewData`.
- Ambos mostram spinner + `Salvando...` enquanto `isSubmitting`.

Em modo edição, o rodapé é o `WizardNavigation` padrão com `submitLabel = "Salvar Alterações"`.

### 5.10 Encadeamento com o PipelineWizard

Enquanto `pipelineWizardOpen`, o `Dialog` da fonte é fechado (`open && !pipelineWizardOpen`) e o `PipelineWizard` é renderizado com:

```tsx
<PipelineWizard
  open={pipelineWizardOpen}
  onClose={handlePipelineWizardClose}
  onComplete={handlePipelineWizardComplete}
  dataSourceId={createdDataSourceId}
  sourceFields={detectedFields.map(f => ({ name: f.name, type: f.type }))}
  previewData={previewData}
/>
```

Fechar ou completar o pipeline dispara `onComplete(createdDataSourceId)` e `handleClose()` da fonte — ou seja, **fechar o wizard de pipeline encadeado fecha tudo**, sem opção de voltar para a fonte.

### 5.11 Reidratação em modo edição

`useEffect` com dependência **apenas em `editingSource?.id`** (linha 334) — deliberado (IAF-4083 Fix C): a página faz polling da Materialização, o pai re-renderiza e passa um novo *objeto* `editingSource`; depender do objeto reinjetaria o `query_config.fields` antigo por cima da detecção fresca.

O que é reidratado:
- nome, descrição, tipo;
- todos os campos de `connection_config` (`bq_auth_type`, `credentials_json`, `client_id`, `client_secret`, `refresh_token`, `project_id`, `dataset_id`, `table_id`, `query`, `url`, `method`, `headers`, `host`, `port`, `database`, `username`, `password`);
- `payment_check_url` (do nível raiz);
- se há `credentials_json`, o indicador de arquivo vira a string literal `credentials.json (carregado)`;
- para csv/cnab: `fileName`, `recordCount`, `fields`, e `data` completo (`fullCsvData` + preview + re-detecção de tipos pelas 5 primeiras linhas);
- para bigquery/rest_api: `fields` e `sample_data` do cache.

---

## 6. Aba Pipelines: cards, status de execução, ações, histórico

Fonte: `src/components/etl/tabs/PipelinesTab.tsx` + `src/components/etl/PipelineCard.tsx` + `PipelineExecutionStatus.tsx`.

### 6.1 Contrato do componente

```ts
interface PipelinesTabProps {
  pipelines: ETLPipeline[] | undefined;
  isLoading: boolean;
  search: string;
  view: ViewMode;
  canWrite: boolean;
  runningPipelines: Set<string>;   // ids em execução disparados nesta sessão
  togglingPipelines: Set<string>;  // ids com pausar/retomar em voo
  onViewChange, onView, onViewHistory, onEdit, onRun, onDelete,
  onCancel, onResume, onMarkFailed, onTogglePause, onOpenWizard
}
```

Tudo é envolvido em `<TooltipProvider>`.

### 6.2 Estados de lista

- **Carregando**: `<GridCardSkeleton count={6} columns={3} />`.
- **Vazio**: `EmptyState` com ícone `ArrowRightLeft`, título `Nenhum pipeline encontrado`, descrição `Tente ajustar os filtros de busca` / `Crie seu primeiro pipeline de importacao`, e botão `+ Novo Pipeline` só quando `!search && canWrite`.

### 6.3 Visão Lista (tabela)

| Coluna | Conteúdo |
|---|---|
| Nome | nome em `font-medium` + descrição em `text-xs muted truncate max-w-[200px]` |
| Fonte | badge outline com o **label do tipo** da fonte (não o nome da fonte). Sem fonte: `N/A` muted |
| Status | `Badge variant={is_active ? "default" : "secondary"}` com texto `Ativo` / `Pausado` |
| Mapeamentos | `{Object.keys(field_mapping).length} campos` |
| Ultima Execucao | `<PipelineExecutionStatus />` (ver 6.5) |
| (ações) | `⋮` — `w-[70px]` |

### 6.4 Visão Grade — o `PipelineCard`

Card com **borda esquerda de 4px colorida** por saúde (`border-l-4`), `hover:shadow-md`; quando pausado, fundo `bg-muted/20`.

```
┌▌──────────────────────────────────────────────┐
│▌ <nome do pipeline>                      [⋮]  │
│▌ [chip de saúde · legenda]  [badge do tipo]   │
│▌ <descrição, 1 linha>                         │
├▌──────────────────────────────────────────────┤
│▌ 🗓 <cron traduzido> (pausado)                 │
│▌ 🕐 Último: há 3h   🗓 Próximo: sexta, 06:00  │
│▌ ┌─────────┬─────────┬─────────┐              │
│▌ │Duração  │Registros│Sucesso  │  mini-KPIs   │
│▌ │  43s    │  1.240  │  96%    │              │
│▌ └─────────┴─────────┴─────────┘              │
│▌ ⧉ 12 mapeamentos · <nome da fonte>           │
│▌ ─────────────────────────────────────────    │
│▌ <PipelineExecutionStatus ao vivo>            │
│▌ [ ▶ Rodar agora        ] [⏸]                 │
└───────────────────────────────────────────────┘
```

#### 6.4.1 Estados de saúde (chip do header)

`resolveHealth(effectivelyRunning, jobIsStuck, isActive, latestRun)`:

| Estado | Quando | Borda esquerda | Chip | Ícone | Legenda |
|---|---|---|---|---|---|
| `stuck` | rodando **e** travado | `border-l-amber-500` | âmbar | `AlertTriangle` | `Possivelmente travado` |
| `running` | rodando | `border-l-blue-500` | azul | `Loader2` girando | `Rodando…` |
| `never` | sem execução e ativo | `border-l-muted-foreground/30` | cinza | `Clock` | `Nunca executado` |
| `paused` | `is_active === false` | `border-l-yellow-500` | amarelo | `Pause` | `Pausado` |
| `completed` | última = completed | `border-l-green-500` | verde | `CheckCircle2` | `Concluido` + `· há Xh` |
| `failed` | última = failed | `border-l-destructive` | vermelho | `XCircle` | `Falhou` + `· há Xh` |
| `cancelled` | última = cancelled | `border-l-muted-foreground/40` | cinza | `XCircle` | `Cancelado` + `· há Xh` |

`effectivelyRunning = isRunning (estado local) || latestRun.status ∈ {running, pending}`.
`jobIsStuck = isJobStuck(latestRun)` — **sem heartbeat há mais de 10 minutos** (`src/hooks/etl/useJobErrors.ts` linhas 249-266). Só vale para status `running`/`pending`; se não há `last_heartbeat`, usa `started_at`.

#### 6.4.2 Bloco de agendamento

- Com cron: ícone `CalendarClock` + `translateCronExpression(schedule_cron)` em `font-medium tabular-nums`; se pausado, sufixo ` (pausado)` em muted.
- Sem cron: ícone `CalendarOff` + `Execução manual` em muted.
- `Último: <relativo>` com tooltip de data/hora absoluta (`dd/mm/aaaa hh:mm`), ou `Sem execuções`.
- `Próximo: <data extensa>` — só quando há cron **e** `is_active`. Calculado **no cliente** por `getNextExecutionDate` (`wizards/shared/utils.ts`), que formata `weekday long, dd, mês curto, hh:mm` em pt-BR.

Tempo relativo local (`fmtRelative` do PipelineCard): `há instantes` (<60s), `há N min`, `há Nh`, `há Nd`, `há N mes(es)`.

#### 6.4.3 Mini-KPIs (grid de 3)

Derivados de `deriveKpis(runs)` sobre as **20 últimas** execuções (limite do `useJobRuns`):

| KPI | Ícone | Valor | Detalhe |
|---|---|---|---|
| Duração | `Timer` | duração da **última execução concluída** (`Xs`, `Xm Ys`, `Xh Ym`) | `—` se nunca concluiu |
| Registros | `Rows3` | `created + updated` da última concluída | Tooltip: `N criados · M atualizados` |
| Sucesso | `Gauge` | `% de completed entre completed+failed` | Cor: ≥90% verde, ≥60% âmbar, <60% destructive |

#### 6.4.4 Rodapé de contexto

`⧉ {N} mapeamento(s) · {nome da fonte ou "Sem fonte"}` — ícone `Layers`, texto `text-xs muted`.

#### 6.4.5 Ações primárias (só com `canWrite`)

- **`▶ Rodar agora`** — botão primário `flex-1`, desabilitado enquanto `effectivelyRunning` (vira `Loader2`).
- **`⏸`/`▶`** — botão outline quadrado ao lado, com tooltip `Pausar execução automática` / `Retomar execução automática`. Desabilitado enquanto `isToggling`. `aria-label` correspondente.

Note que o botão primário do card chama `onRun(pipeline)` — **execução completa**. "Testar (100 linhas)" só existe no dropdown.

### 6.5 `PipelineExecutionStatus` — status ao vivo

Renderizado tanto na coluna "Ultima Execucao" (lista) quanto no rodapé do card (grade). Usa `useJobRuns(pipelineId)`, que faz **polling a cada 2s** enquanto houver job `running`/`pending` e para quando não houver (`refetchInterval` dinâmico).

Quatro estados:

**A. Rodando e travado** (`effectivelyRunning && jobIsStuck`)
```
⚠ Possivelmente Travado            (text-warning, text-xs font-medium)
1.240/10.976 registros             (text-xs muted)
[⟳ Retomar]  [Marcar Falho]        (h-6, text-xs; o 2º em text-destructive)
```

**B. Rodando normalmente** → `EstimatedProgressBar`:
- Percentual grande + rótulo de fase.
- Fases e cores: `fetching` → `Buscando dados...` (azul, `Database`); `preloading` → `Pre-carregando...` (laranja, `RefreshCw` girando); `processing` → `Processando...` (primary, `Loader2`); `finalizing` → `Finalizando...` (verde, `CheckCircle2`); default → `Iniciando...`.
- Barra `h-2 bg-muted rounded-full` com preenchimento colorido pela fase, largura mínima 3%.
- Progresso = `max(estimado, real)`. Estimado: `elapsed / (total_records × 5ms)`, clampado entre 5s e 300s e **limitado a 95%**; atualizado a cada 500ms. Real: `processed/total`.
- `{total_records} registros` abaixo (pt-BR).
- Botão `Cancelar` (ghost, `h-5`, destrutivo) no canto superior direito.

**C. Sem execução**: ícone `Clock` + `Nunca executado` (muted, `text-xs`).

**D. Execução finalizada**:
```
[ícone colorido] <label do status>
🕐 dd/mm hh:mm
{created} criados, {updated} atualizados ({failed} erros em vermelho)
```
Labels: `completed` → `Concluido` (verde), `failed` → `Falhou` (destructive), `running` → `Executando` (primary, ícone girando), `cancelled` → `Cancelado` (muted), default → o próprio status (amarelo).
A terceira linha só aparece quando `status === "completed"`.

### 6.6 Menu de ações (`⋮`)

Idêntico em lista e card, exceto por dois itens:

| Item | Ícone | Gate | Lista | Card |
|---|---|---|---|---|
| Visualizar / Detalhes | `Eye` | — | `Visualizar` | `Detalhes` |
| Ver Historico / Ver histórico | `BarChart3` | — | `Ver Historico` | `Ver histórico` |
| Editar | `Edit` | `canWrite` | ✅ | ✅ |
| Testar (100 linhas) | `FlaskConical` | `canWrite` | ✅ | ✅ |
| **Executar** | `Play` | `canWrite` | ✅ | ❌ (é o botão primário do card) |
| Pausar/Retomar agendamento | `Pause`/`Play` | `canWrite` | ✅ | ✅ |
| — separador — | | | ✅ | ✅ |
| Excluir | `Trash2` (destructive) | `canWrite` | ✅ | ✅ |

### 6.7 Semântica de cada ação (handlers na `ETLPage`)

| Ação | Handler | Efeito |
|---|---|---|
| Executar | `handleRunPipeline(pipeline, false)` | `confirm("Executar o pipeline \"X\"?")` → marca id em `runningPipelines`, aguarda 100ms, chama `runPipeline.mutateAsync({pipelineId, testMode:false})`, invalida `["etl-job-runs", id]` |
| Testar | `handleRunPipeline(pipeline, true)` | `confirm("Testar o pipeline \"X\" com as primeiras 100 linhas?")` → idem com `testMode:true` |
| Cancelar | `handleCancelPipeline(pipelineId, jobId)` | `confirm("Tem certeza que deseja cancelar esta execucao?")` → `cancelJob(jobId)` e remove de `runningPipelines` |
| Retomar | `handleResumePipeline` | **Sem confirmação.** `resumeJob(jobId)` e invalida os runs |
| Marcar como falha | `handleMarkPipelineFailed` | `confirm("Marcar esta execucao como falha?")` → `markJobFailed(jobId)` |
| Pausar/Retomar agendamento | `handleTogglePause` | `updatePipeline({id, is_active: !is_active})` — **mesmo caminho do wizard**. Não mexe em `schedule_cron`/`is_scheduled` |
| Excluir | `handleDeletePipeline` | `confirm(...)` na aba → `deletePipeline(id)` |

Toasts de `handleTogglePause`:
- Sucesso: título `Agendamento retomado` / `Agendamento pausado`; descrição `"<nome>" voltara a rodar conforme o agendamento.` / `"<nome>" nao sera mais executado automaticamente.`
- Erro: `Erro ao alterar o agendamento` + mensagem.

Toasts de `useRunPipeline`:
- Sucesso: `Teste Iniciado` / `Pipeline Iniciado`; descrição `Processando apenas as primeiras 100 linhas para validação.` / `O processamento está sendo executado no servidor. Acompanhe o progresso abaixo.`
- Erro: `Erro ao Iniciar Pipeline` + mensagem.

Toasts de `useCancelJob`: `Job Cancelado` / `O processamento foi interrompido.`; erro `Erro ao Cancelar`.
Toasts de `useResumeJob`: `Job Retomado` / `O processamento foi reiniciado no servidor.`; erro `Erro ao Retomar`.
Toast de `useMarkJobFailed`: `Job marcado como falho` / `O job foi marcado como falho. {N} registros foram processados.`

### 6.8 Validação de pré-voo ao executar

`useRunPipeline` (`src/hooks/etl/useJobRuns.ts`) valida **no cliente** antes de criar o job (`validatePipelineMappings`):
- agrupa `field_mapping` por entidade (suportando valores array 1:N);
- exige, por entidade **que tiver algum mapeamento**: `contacts` → `document` e `name`; `contracts` → `contract_number`; `supplies` → `supply_number`; `titles`/`supply_titles` → nada;
- exige pelo menos **um** mapeamento total, senão `Nenhum campo foi mapeado. Configure pelo menos um mapeamento.`

Erros viram `throw` e chegam como toast destrutivo `Erro ao Iniciar Pipeline`, com as mensagens unidas por `\n` (renderizadas numa linha só no toast).

Para CSV/CNAB com dados em `query_config.data` mas **sem** `storage_path`, o hook sobe os dados para o Storage antes de criar o job.

O job é criado com `status: "pending"` e a EF `execute-etl` é invocada **fire-and-forget** (`.catch(logError)`).

### 6.9 O que a aba **não** mostra

- Nenhum indicador de `skip_reconciliation`.
- Nenhum indicador da família (equipamento × suprimento) nem do `target_entity`.
- Nenhuma contagem de erros pendentes fora do modal de histórico.
- Nenhum filtro por status (ativo/pausado), por fonte ou por saúde — só busca por nome.
- Nenhuma ordenação configurável (a lista vem sempre por `created_at DESC`).

---

## 7. Wizard de Pipeline — passo a passo (seleção da fonte, mapeamento de entidades e campos, normalização, agendamento)

Fonte: `src/components/etl/wizards/PipelineWizard/index.tsx` + `hooks/usePipelineWizard.ts` (1264 linhas) + `steps/*`.

### 7.1 Casca do modal

Igual à do wizard de fonte: `DialogContent` `flex flex-col p-0 w-[95vw] h-[95vh]`, header com gradiente, stepper em faixa, corpo rolável com `max-w-4xl mx-auto` (note: **4xl**, mais largo que o da fonte), rodapé com `WizardNavigation`.

| Item | Valor |
|---|---|
| Título | `Novo Pipeline de Importação` / `Editar Pipeline` |
| Descrição | `Configure o mapeamento de campos e agendamento de execução` |
| Submit label | `Criar Pipeline` / `Salvar Alterações` |

### 7.2 Modo standalone × encadeado

```ts
const isStandalone = !initialDataSourceId;
```

| Modo | Origem | Passos |
|---|---|---|
| Encadeado | Aberto pelo `DataSourceWizard` com `dataSourceId` | 3 passos: Mapeamento, Normalização, Agendamento |
| Standalone | Aberto pelo botão "Novo Pipeline" ou por "Editar" | 4 passos: **Fonte de Dados** + os 3 acima |

`getWizardSteps(isStandalone)` desloca os ids em +1 quando standalone. `contentStep = isStandalone ? currentStep - 1 : currentStep`.

Passos base (`PIPELINE_WIZARD_STEPS`):

| id | title | description |
|---|---|---|
| 1 | Mapeamento | Configure os campos |
| 2 | Normalização | Padronize valores |
| 3 | Agendamento | Configure a execução |

Passo extra standalone: `{ id: 1, title: "Fonte de Dados", description: "Selecione a fonte" }`.

Navegação do stepper: livre em edição (`allowFreeNavigation={!!editingPipeline}`); em criação, só para trás. **Diferente do wizard de fonte, não há `handleStepJump`** — o salto em edição é direto (`setCurrentStep`), sem re-executar nada.

### 7.3 Passo 0 (standalone) — Seleção da fonte

`steps/DataSourceSelectionStep.tsx`.

Cabeçalho: `Selecione a Fonte de Dados` + `Escolha qual fonte de dados será usada neste pipeline de importação`.

| Elemento | Detalhe |
|---|---|
| Busca | `Label "Buscar"` + `Input` com ícone `Search` à esquerda, placeholder `Buscar fontes de dados...`. Filtro **server-side** via `useDataSources({search})`. Estado local, independente da busca da página |
| Grade | `md:grid-cols-2 lg:grid-cols-3`, gap 3 |
| Card da fonte | ícone do tipo (bloco `p-2 rounded-lg`, `bg-primary/10` quando selecionado) + nome (`font-medium truncate`) + label do tipo + descrição (`line-clamp-2`) |
| Seleção | `ring-2 ring-primary bg-primary/5`; ícone `Check` primary ao lado do nome (ou `Loader2` enquanto carrega campos) |
| Badge `Cache` | ícone `Clock` + texto `Cache` quando `query_config.fields` existe e tem itens |
| Linha de cache | `Cacheado <há X tempo>` via `formatDistanceToNow(..., {locale: ptBR})` |
| Carregando lista | 3 cards `animate-pulse` |
| Lista vazia | ícone `Database` 48×48 opacity-50 + `Nenhuma fonte de dados encontrada` + `Crie uma fonte de dados primeiro` |

Após selecionar, aparecem:
- **Enquanto carrega campos** (e não é refresh): linha `Loader2` + `Carregando campos da fonte de dados...`
- **Painel "Atualizar Campos"** (`p-4 rounded-lg border bg-muted/30`): título `Atualizar Campos`, texto `Se a estrutura da fonte de dados mudou, clique para recarregar os campos disponíveis.`, botão outline `⟳ Atualizar Campos` (vira `Atualizando...`). Só aparece quando há fonte selecionada, não está carregando e não há erro.
- **Erro** (`p-4 rounded-lg bg-destructive/10 border-destructive/20`): `Erro ao carregar campos` + a mensagem.

Os cards de fonte também são `<Card onClick>` sem semântica de botão.

### 7.3.1 Como os campos da fonte são carregados (`loadSourceFields`)

`usePipelineWizard.ts` linhas 432-672. Ordem de prioridade:

1. **Cache** (`skipCache === false`): se `query_config.fields` existe e tem itens → usa direto; carrega `sample_data` (ou `data.slice(0,100)` para csv/cnab) e `unique_values` + `unique_values_source`. Retorna. Caminho rápido.
2. **Fallback por tipo** (ou quando `skipCache === true`):
   - `bigquery`: monta a query (usa `connection_config.query`, ou `SELECT * FROM \`proj.ds.tbl\` LIMIT 100`); se não houver nem query nem dataset+table, erro `Esta fonte BigQuery não possui query SQL nem dataset/tabela configurados. Edite a fonte para adicionar essas informações.`; invoca a EF; em erro usa `readFunctionErrorMessage`; converte `type` para minúsculas.
   - `csv`/`cnab`: erro `Nenhum campo encontrado para esta fonte de dados. Edite a fonte para reprocessar o arquivo.`
   - `rest_api`: primeiro tenta `query_config.fields`; senão faz `fetch` direto da URL, procura o array em `data`/`results`/`items`/qualquer propriedade array, achata (recursivo, sem limite de profundidade aqui) e infere tipos por `typeof` + `Date.parse`. Erros específicos: `URL da API não configurada.`, `Erro ao chamar API: {status} {statusText}`, `Nenhum dado retornado pela API. Verifique a configuração da fonte.`, `Erro ao conectar na API: {msg}`.
   - `postgresql`/`mysql`: **nenhum ramo** — nada acontece, `sourceFields` fica vazio e o avanço trava.

### 7.4 Passo 1 — Mapeamento (`steps/MappingStep.tsx`)

Ordem visual dos blocos:

1. Banner de **sugestões de auto-fix** (condicional)
2. Banner de **campos de vínculo ausentes** (condicional)
3. Nome e descrição do pipeline
4. Seletor de **família** (o que este pipeline importa)
5. Cabeçalho "Mapeamento de Campos" + badge de detectados + botão Auto-detectar
6. Um `EntityMappingGroup` por entidade ativa
7. Card de **Deduplicação**

#### 7.4.1 Campos de identificação

| Campo | Controle | Obrigatório | Placeholder |
|---|---|---|---|
| `Nome do Pipeline *` | `Input` (id=`name`) | **Sim** (trava avanço) | `Ex: Importação diária de clientes` |
| `Descrição (opcional)` | `Input` (id=`description`) | Não | `Descreva o propósito deste pipeline...` |

Layout: `grid-cols-1 md:grid-cols-2`.

#### 7.4.2 Seletor de família

`Label: O que este pipeline importa?` + `ToggleGroup type="single"`:

| Valor | Ícone | Texto | aria-label |
|---|---|---|---|
| `equipment` | `FileText` | `Contrato` | `Contrato (contato, contrato, título)` |
| `supply` | `Package` | `Suprimento` | `Suprimento (contato, suprimento, parcela de suprimento)` |

Estilo selecionado: `data-[state=on]:border-primary data-[state=on]:bg-primary/10`.

Texto de ajuda abaixo:
- equipment: `Cadeia Contato → Contrato → Título. Trocar de tipo remove os mapeamentos que não pertencem a este tipo.`
- supply: `Cadeia Contato → Suprimento → Parcela de Suprimento. Trocar de tipo remove os mapeamentos que não pertencem a este tipo.`

`handleFamilyChange` **poda** os mapeamentos cuja `targetTable` não pertence à nova família (contato sobrevive). **Sem confirmação** — a perda é imediata e silenciosa.

#### 7.4.3 Cabeçalho do bloco de mapeamento

```
Mapeamento de Campos                         [✨ N detectado(s)]  [✨ Auto-detectar]
Configure o mapeamento de campos da fonte para cada entidade destino.
Campos obrigatórios estão marcados com *
```

- Badge `N detectado(s)` (`Sparkles`) só aparece se `autoDetectedCount > 0`.
- Botão `Auto-detectar` (outline, sm) desabilitado quando `unmappedRequiredCount === 0 && autoFixSuggestions.length === 0`.

#### 7.4.4 Inicialização automática dos mapeamentos

`useEffect` com assinatura `${sourceFields.length}|${activeEntities.join(",")}` (linha 234). Roda quando os campos carregam ou a família muda.

1. `initializeRequiredMappings` — cria uma linha para **cada campo obrigatório** (não-lookup) de cada entidade ativa, com `sourceField: ""` e `isRequired: true`; e uma linha para cada **lookup**, com `isLookup: true` e `lookupSource`.
2. Se **não** há mapeamentos com origem preenchida (pipeline novo), aplica `applyAutoDetectionToMappings` e conta quantos foram preenchidos.
3. Só chama `onFieldMappingsChange` se houve mudança real.

Segundo `useEffect` (linhas 272-280): `autoLinkLookups` — para cada mapeamento de lookup, copia o `sourceField` do mapeamento da entidade de origem. Roda a cada mudança de `fieldMappings`.

#### 7.4.5 `EntityMappingGroup` — um card por entidade

`components/EntityMappingGroup.tsx`. Cores e ícones por entidade:

| Entidade | Ícone | Cor do bloco |
|---|---|---|
| `contacts` | `Users` | `text-blue-600 bg-blue-100` |
| `contracts` | `FileText` | `text-green-600 bg-green-100` |
| `titles` | `Receipt` | `text-amber-600 bg-amber-100` |
| `supplies` | `Package` | `text-purple-600 bg-purple-100` |
| `supply_titles` | `Receipt` | `text-amber-600 bg-amber-100` |

Header (clicável, `Collapsible`, aberto por padrão):
```
[ícone]  Contatos  [N campo(s)]                    [⚠ M obrigatório(s)]  [▲/▼]
```
- Contador `regularMappings.length` (badge secondary).
- Badge destructive `M obrigatório(s)` quando faltam obrigatórios.
- Card inteiro com `opacity-60` quando não há nenhum mapeamento nem lookup.

Corpo:

**A. Aviso de obrigatórios** (`p-3 rounded-lg bg-destructive/10 border-destructive/20`): `Campos obrigatórios não mapeados:` + `<ul>` com os labels.

**B. Cabeçalho da grade** (`grid-cols-[1fr_auto_1fr_auto]`): `Campo Destino` · (vazio) · `Campo Origem` · (vazio), em `text-xs uppercase tracking-wide muted`.

**C. Linhas de mapeamento** — cada uma:
```
[destino]   ←   [origem]   [🗑]
```
- **Destino obrigatório**: renderizado como caixa estática (`px-3 py-2 border rounded-md bg-muted/50`) com o label + `*` vermelho; ícone `Puzzle` se for campo personalizado. **Não editável.**
- **Destino opcional**: `FieldCombobox` com placeholder `Campo destino...` e busca `Buscar campo destino...`, com `showCreateCustom`.
- **Seta**: `←` em `text-muted-foreground` (o fluxo é lido da direita para a esquerda: destino ← origem).
- **Origem**: sempre `FieldCombobox` com placeholder `Campo origem...` / `Buscar campo origem...`.
- **Remover**: `Trash2` ghost 32×32, `hover:text-destructive`. **Ausente** (espaço `w-8`) em campos obrigatórios.

**D. Campos Vinculados Automaticamente** — bloco separado, `text-xs uppercase muted` como título. Cada lookup:
```
🔗 Número do Contrato → [nome_da_coluna]        (mono, bg-muted)
🔗 Documento (CPF/CNPJ) do contato → (aguardando mapeamento de contacts)   (text-warning)
```
Caixa `bg-muted/30 border border-dashed`.

**E. Adicionar mapeamento** — um `FieldCombobox` com `value=""`, borda tracejada, placeholder `Adicionar mapeamento...`, listando apenas destinos ainda não mapeados. Só aparece se houver destinos livres.

**F. Chips de campos disponíveis** — bloco `pt-3 border-t border-dashed`:
- Título: `Campos disponíveis — clique para adicionar:` (a primeira parte em `text-primary font-medium`).
- Container `flex flex-wrap gap-1.5 max-h-40 overflow-y-auto p-2 rounded-md bg-muted/30 border-dashed`.
- Cada chip: `Badge` com `+ {nome}` (mono, truncado em 150px), borda primary/40, `hover:bg-primary/20`, `active:scale-95`. Clicar cria um mapeamento com a origem preenchida e o destino **vazio**.
- Se todos já foram mapeados: `Todos os campos da fonte já foram mapeados.`

**G. Estado vazio da entidade**: `Nenhum campo mapeado para {entidade}.` + `Clique acima para adicionar mapeamentos.`

#### 7.4.6 Campos de destino por entidade

`TARGET_TABLES` (`src/hooks/etl/constants.ts` linhas 38-151). Os campos `required: true` são os que aparecem com `*` no combobox; os lookups são **removidos** da lista de destinos selecionáveis.

**contacts** (15 campos): `document`* (Documento CPF/CNPJ), `name`* (Nome), `document_type` (Tipo Documento cpf/cnpj), `trading_name` (Nome Fantasia), `phone` (Telefone), `email` (E-mail), `address_street`, `address_number`, `address_complement`, `address_neighborhood`, `address_city`, `address_state`, `address_zipcode`, `tags` (Tags), `notes` (Observações).

**contracts** (20 campos): `contract_number`*, `contact_document`* (lookup), `modality`, `status`, `original_value`, `current_value`, `pending_value`, `paid_value`, `days_overdue`, `start_date`, `end_date`, `oldest_due_date`, `total_value`, `open_balance`, `product`, `due_date`, `portfolio`, `aging_bucket`, `external_source`, `external_id`.

**titles** (19 campos): `title_number`*, `contract_number`* (lookup), `due_date`*, `original_value`*, `installment_number`, `current_value`, `paid_value`, `status` (Status pending/paid), `payment_date`, `payment_method`, `total_installments`, `discount_value`, `interest_value`, `fees_value`, `payment_link_url`, `days_overdue`, `pix_key`, `boleto_digitable_line`, `external_id`.

**supplies** (13 campos): `supply_number`*, `contact_document`* (lookup), `status`, `original_value`, `current_value`, `pending_value`, `paid_value`, `total_value`, `days_overdue`, `oldest_due_date`, `aging_bucket`, `external_source`, `external_id`.

**supply_titles** (19 campos): `title_number`* (Número da Parcela), `supply_number`* (lookup), `due_date`*, `original_value`*, e o resto espelhando `titles`.

#### 7.4.7 Card de Deduplicação

Renderizado apenas se `entitiesWithMappings.length > 0` (entidades ativas com pelo menos um mapeamento não-lookup).

```
Configuração de Deduplicação
Configure como duplicatas serão tratadas para cada entidade mapeada.

[contacts]  [Select: campo chave ▾]  [Select: estratégia ▾]
[contracts] [Select: campo chave ▾]  [Select: estratégia ▾]
```

Grid `grid-cols-[120px_1fr_1fr] gap-4 items-center`. O nome da entidade aparece **cru e capitalizado por CSS** (`capitalize`) — ou seja, "Contacts", "Contracts", "Supply_titles", **não** os labels em português.

Campo chave: opções = os `targetField` já mapeados naquela entidade (excluindo lookups). Placeholder `Campo chave...`. Default: `DEFAULT_DEDUP_FIELDS` (`contacts: document`, `contracts: contract_number`, `titles: title_number`, `supplies: supply_number`, `supply_titles: title_number`).

Estratégia (`DEDUP_STRATEGIES`, constants.ts linhas 153-157) — o texto do item é `{label} - {description}`:

| Valor | Label | Descrição |
|---|---|---|
| `skip` | Ignorar | Ignora registros duplicados |
| `update` | Atualizar | Atualiza registros existentes |
| `create_new` | Criar Novo | Cria novo registro mesmo se duplicado |

Default de todas as entidades: `update`.

#### 7.4.8 Banners de assistência

**Banner de auto-fix** (`Alert border-warning/50 bg-warning/10`):
```
⚠ Campos obrigatórios não mapeados
Encontramos campos da fonte que parecem corresponder aos campos obrigatórios faltantes:

[contacts] CPF/CNPJ ← `documento_cliente` [95% match]              [✓ Aplicar]
[titles]   Valor Original ← `vl_titulo`   [85% match]              [✓ Aplicar]

[🪄 Aplicar todas as sugestões (2)]
```
- A entidade aparece como badge com o **nome cru** (`contacts`, `titles`).
- O label do campo vem de `getRequiredFieldLabel(entity, field)`.
- A origem sugerida em `<code>`.
- Percentual = `Math.round(confidence * 100)`.

**Banner de lookups ausentes** (`Alert variant="destructive"`):
```
⚠ Campos de vínculo obrigatórios ausentes
[contracts] O campo 'contact_document' (Documento (CPF/CNPJ) do contato) não está mapeado.
            Registros de Contratos não poderão ser vinculados a Contatos, causando falhas
            durante a atualização (UPDATE) de registros existentes.

Dica: Mapeie o campo de documento/número do contrato da sua fonte para os campos de lookup
correspondentes, ou verifique se os lookups estão sendo auto-vinculados corretamente a partir
dos mapeamentos de contatos/contratos.
```
Só dispara para entidades ativas que **já têm** algum mapeamento não-lookup com origem.

### 7.5 Passo 2 — Normalização (`steps/NormalizationStep.tsx`)

#### 7.5.1 Estado de carregamento

Enquanto `useStandardValues()` carrega: bloco centrado com `Loader2` 48×48 girando, `Carregando valores padrão...` e `Buscando configurações de normalização da organização.`

#### 7.5.2 Estado "nada a fazer"

Se `fieldsForNormalization.length === 0 && listFields.length === 0`: ícone `RefreshCw` 48×48 muted, `Nenhuma normalização necessária`, `Os campos mapeados não requerem normalização de valores. Você pode avançar para a próxima etapa.`

#### 7.5.3 Banners do topo

**A. Sugestões automáticas** (`Card border-primary/20 bg-primary/5`) — só se `totalSuggestions > 0`:
```
[✨] Sugestões Automáticas Detectadas
     Encontramos {N} mapeamento(s) sugerido(s) com base nos seus dados      [🪄 Aplicar Todas]
```

**B. Valores únicos possivelmente incompletos** (`Card` âmbar) — quando há campos a normalizar, existe `onRefreshUniqueValues` e `uniqueValuesSource !== "distinct"`:
```
[⟳] Valores únicos podem estar incompletos
    A fonte possui {N} registros, mas os valores únicos foram calculados com base
    em apenas {M} registros de amostra.                                [⟳ Buscar Todos]
```
Se `totalSourceRecords` for 0: `Os valores únicos podem estar incompletos. Clique em "Buscar Todos" para atualizar.`

**C. Prévia de Impacto** (`Card bg-muted/50`):
```
Prévia de Impacto                                   1.240        87
Baseado em valores distintos da fonte completa   Normalizados  Sem mapeamento
```
Subtítulo alterna para `Baseado em {N} registros de amostra — valores podem estar incompletos` quando a origem não é `distinct`. Números em `text-2xl font-bold` verde e âmbar.

#### 7.5.4 Cabeçalho da seção de valores

```
⟳ Normalização de Valores                        ⚙ Gerenciar Valores Padrão ↗
Mapeie os valores da fonte para os valores padrão do sistema.
```
O link abre `/settings?tab=standard-values` em nova aba (`target="_blank"`), com ícones `Settings2` e `ExternalLink`.

#### 7.5.5 Card por campo a normalizar

Um `Collapsible` por mapeamento cujo `targetField` ∈ {`status`, `modality`, `payment_method`} **e** tenha `sourceField`. Header:
```
[Títulos] Campo: `status`  [12 valor(es) único(s)]  [✨ 5 sugestão(ões)]  [⚙ 2 customizado(s)]   ▲
```
- Badge outline com `ENTITY_LABELS[targetTable]` (Contatos/Contratos/Títulos/Suprimentos/Parcelas de Suprimento).
- `Campo:` + o `targetField` em `<code className="text-primary">`.
- Contadores: valores únicos (secondary), sugestões pendentes (primary, com `Sparkles`), customizados (outline, com `Settings2`).

Corpo:

**Barra de gestão de valores customizados** (`border-b pb-2`):
- Botão `+ Novo Valor` (outline sm) → abre `CustomValueModal`.
- Botão `⚙ Gerenciar`/`Fechar` (ghost sm) — só se já houver customizados.
- À direita: `{N} valores disponíveis`.

**Lista de customizados** (quando "Gerenciar" está ativo): caixa `bg-muted/30 rounded-lg p-3`, título `Valores Customizados`, e uma linha por valor:
```
Em Análise                                                    [🗑]
Valor: Em Analise • Aliases: em analise, analise
```

**Tabela de mapeamento de valores** — grade `grid-cols-[1fr_auto_1fr_auto]`, cabeçalho `Valor Original` · · `Valor Padrão` · :

```
[input desabilitado: "em_aberto"] [12x]   →   [Select: Disponivel ▾]   [✓ Aplicar]/[✓ Mapeado]
```
- Origem: `Input` desabilitado, `font-mono text-sm bg-muted`, com badge outline `{count}x` ao lado.
- Destino: `Select` cujo valor é o mapeamento atual ou a sentinela `__keep_original__`. Primeira opção: `Manter original`. Demais: os valores-padrão, cada um com badge `Custom` se for customizado e sufixo `← Sugerido` em `text-primary` quando bate com a sugestão.
- Quando há sugestão não aplicada: a linha ganha `bg-primary/5 border border-primary/10`, o `SelectTrigger` ganha `border-primary/30`, o placeholder vira `Sugestão: {label}` e aparece o botão `✓ Aplicar` (texto oculto em telas pequenas, `hidden sm:inline`).
- Quando já mapeado: badge verde `✓ Mapeado`.

#### 7.5.6 Motor de sugestão

`findBestMatchWithCustom` (linhas 148-212):
1. **Exato**: valor normalizado igual ao `value` ou ao `label` do padrão → confiança `high`, tipo `exact`.
2. **Alias**: igual a algum alias → `high`, tipo `alias`.
3. **Similaridade**: `stringSimilarity` (Levenshtein normalizado, com atalho 1.0 para igual e 0.8 para "um contém o outro"). Aceita ≥ 0.6; ≥ 0.8 → `medium`, senão `low`.

`normalizeString`: minúsculas, remove acentos (NFD), remove tudo que não for `[a-z0-9]`.

#### 7.5.7 Campos de Lista (Filtros)

Bloco final, renderizado quando `listFields.length > 0`:
```
☑ Campos de Lista (Filtros)
Marque os campos que serão usados como filtros no sistema.

┌─────────────────────────────────────────────────┐
│ status                                [Ativado] │
│ 12 valor(es) único(s) detectado(s)              │
├─────────────────────────────────────────────────┤
│ modality                            [Desativado]│
│ 4 valor(es) único(s) detectado(s)               │
└─────────────────────────────────────────────────┘
```
- Critério de detecção: campo com **2 a 50** valores únicos (do cache, se houver; senão do preview).
- **Mostra no máximo 10** (`listFields.slice(0, 10)`) — sem paginação nem aviso de que há mais.
- A linha inteira é clicável (`cursor-pointer`), sem `role="checkbox"`/`aria-checked`.
- Ativado: `bg-primary/5 border-primary/20` + badge `default`.
- Grava/remove em `transformRules.list_fields` usando o **`targetField`** (não o `sourceField`) — enquanto a detecção e a contagem usam o `sourceField`.

#### 7.5.8 Refresh de valores únicos (`handleRefreshUniqueValues`)

Só funciona para fontes `bigquery`. Sequência:
1. Filtra `sourceFields` não-numéricos/não-data **que estejam mapeados** (reduz o custo).
2. Monta a referência de tabela: `(query customizada)` ou `` `proj.dataset.table` ``.
3. Lotes de **5** campos, `UNION ALL` de `SELECT '<campo>' as field_name, CAST(<campo> AS STRING) as field_value, COUNT(*) as value_count ... GROUP BY ... ORDER BY value_count DESC LIMIT 500`.
4. Falhas parciais → `console.warn`; falha total → `uniqueValuesSource = "failed"`.
5. Sucesso → ordena por contagem, seta o estado **e persiste** no `data_sources.query_config` (merge com `unique_values`, `unique_values_source: "distinct"`, `cached_at`).

**Auto-disparo**: um `useEffect` roda esse refresh automaticamente ao **entrar** no passo de normalização, se a fonte é BigQuery e a origem dos valores não é `distinct` nem `failed` (linhas 1006-1018). O usuário pode ver o banner âmbar aparecer e sumir sozinho.

### 7.6 Passo 3 — Agendamento (`steps/ScheduleStep.tsx`)

Ordem dos blocos: ativação → pular reconciliação → tipo de agendamento → configuração de horário → card informativo.

#### 7.6.1 Card de ativação

```
[▶ verde / ⏸ cinza]  Pipeline Ativo / Pipeline Pausado                    [Switch]
                     O pipeline será executado conforme agendamento
                     O pipeline não será executado automaticamente
```
Ícone em bloco `p-2 rounded-lg`: ativo → `bg-green-100 text-green-600` com `Play`; pausado → `bg-muted text-muted-foreground` com `Pause`. Default: **ativo**.

#### 7.6.2 Card "Pular Reconciliacao"

```
[⟳]  Pular Reconciliacao                                                  [Switch]
     Nao remover titulos ausentes apos a execucao. Use para pipelines
     complementares que nao representam a fonte completa de dados.
```
Ícone `RefreshCw` em `bg-amber-100 text-amber-600` quando ligado, `bg-muted` quando desligado. Default: **desligado**.

#### 7.6.3 Tipo de Agendamento (RadioGroup)

Card com header `🕐 Tipo de Agendamento`. Cinco opções, cada uma numa caixa `p-3 rounded-lg border hover:bg-muted/50`:

| Valor | Título | Descrição |
|---|---|---|
| `manual` | Manual | Executar apenas quando solicitado manualmente |
| `daily` | Diariamente | Executar todos os dias em um horário específico |
| `weekly` | Dias da Semana | Executar em dias específicos da semana |
| `interval` | A cada intervalo | Executar repetidamente dentro de uma janela (ex.: a cada 30 min das 6h às 18h) |
| `multiple_daily` | Múltiplas vezes ao dia | Executar em horários avulsos (irregulares) no mesmo dia |

Existe um sexto valor no type (`custom`) usado só como fallback de parsing — **não é oferecido na UI**.

#### 7.6.4 Configuração de Horário (condicional a `≠ manual`)

Card `🗓 Configuração de Horário`.

**Modo `interval`** → renderiza apenas o `CronIntervalField` (ver seção 9).

**Modo `weekly`** → `Label "Dias da Semana"` + botões-chip por dia (`DAYS_OF_WEEK`), `px-4 py-2 rounded-lg border text-sm font-medium`; selecionado = `bg-primary text-primary-foreground border-primary`. Default: `[1,2,3,4,5]` (seg-sex).

**Seleção de horário** (todos os modos exceto `interval`):
- Label: `Primeiro Horario` (se `multiple_daily`) ou `Horario de Execucao`.
- Dois `Select` de 96px (`w-24`) separados por `:` em `text-lg font-bold`.
- Horas: 0-23, exibidas com zero à esquerda.
- Minutos: **apenas `0, 15, 30, 45`**.
- Defaults: hora 8, minuto 0.

**Horários adicionais** (só `multiple_daily`):
- Label `Horarios Adicionais`.
- Uma linha por horário extra: `Select hora` `:` `Select minuto` `[🗑 destructive]`.
- Botão `+ Adicionar horario` (outline sm).
- Ao escolher o modo pela primeira vez, cria automaticamente um horário extra = `min(hora+6, 23)` com o mesmo minuto.
- Ao adicionar, o novo é `min(último+4, 23)`.

**Preview do CRON** (não aparece no modo `interval`, que tem preview próprio):
```
┌ p-3 rounded-lg bg-muted/50 ─────────────────────────┐
│ Expressão CRON:              `0 8 * * 1,2,3,4,5`    │
│ Próxima execução:            [segunda-feira, 23 jun, 08:00] │
└─────────────────────────────────────────────────────┘
```
A próxima execução só aparece quando `isActive` é true.

#### 7.6.5 Card informativo fixo

`bg-blue-50/50 border-blue-100`, ícone `Info`:
> **Sobre o agendamento**
> Pipelines agendados são executados automaticamente nos horários configurados **(horário de Brasília)**. Você sempre pode executar manualmente a qualquer momento pela página de pipelines.
> *Nota: Se houver uma execução em andamento no horário agendado, ela será cancelada automaticamente para iniciar a nova execução programada.*

> ⚠️ Esse card tem cores **hardcoded** (`bg-blue-50/50`, `text-blue-900`, `text-blue-700`, `text-blue-600`) sem variante para tema escuro — diferente do resto da tela, que usa tokens ou pares `dark:`.

### 7.7 Regras de avanço (`canProceed`)

`usePipelineWizard.ts` linhas 1021-1042:

| Passo | Condição |
|---|---|
| 0 (fonte, standalone) | `selectedDataSourceId !== null && !isLoadingFields && sourceFields.length > 0` |
| 1 (mapeamento) | `pipelineName.trim() !== ""` **e** `fieldMappings.length > 0` **e** **todos** os mapeamentos têm `targetField` **e** `sourceField` **e** `missingRequiredFields.length === 0` |
| 2 (normalização) | `true` |
| 3 (agendamento) | `true` |

`missingRequiredFields` (linhas 962-994) percorre apenas as entidades **que têm algum mapeamento**, e considera satisfeito um lookup cuja entidade de origem já mapeia o campo-fonte correspondente.

> Consequência prática: as linhas de campo obrigatório criadas automaticamente com `sourceField: ""` **travam o avanço** — o botão "Continuar" fica desabilitado até que todas tenham origem, mesmo campos que o usuário não quer importar. Não há como remover uma linha obrigatória (o botão de lixeira não é renderizado).

### 7.8 Serialização no submit (`handleSubmit`)

1. Monta `fieldMappingObj`:
   - pula mapeamentos sem `sourceField` ou sem `targetField`;
   - **pula lookups** cuja entidade de origem já está mapeada (o backend resolve a FK);
   - campo customizado vira `custom_fields.<nome>`;
   - chave = `sourceField`, valor = `"entidade:campo"`; colisão vira **array** (1:N).
2. Define `target_entity`:
   - família `supply`: `supply_titles` se houver mapeamento dela, senão `supplies`;
   - família `equipment`: `contacts` → senão `contracts` → senão `titles` (ordem de preferência).
3. `dedup_field`/`dedup_strategy` = os da `target_entity`.
4. Grava também `dedup_strategy_contacts`, `_contracts`, `_titles` (não há colunas para supplies).
5. `transform_rules: [transformRules]` (array de 1).
6. `schedule_cron`, `is_scheduled: !!scheduleCron`, `is_active`, `skip_reconciliation`.
7. Cria ou atualiza o pipeline.
8. **Depois** do save, faz `upsert` em `custom_field_definitions` para cada mapeamento customizado, com `display_name = field_name` (sem label amigável) e `field_type` do mapeamento (default `text`), `is_filterable: true`, `onConflict: "entity_type,field_name"`.
9. `onComplete()` + `handleClose()`.

Erros: apenas `logError` — **nenhum feedback visual**.

### 7.9 Reidratação em modo edição

`useEffect` em `[editingPipeline]` (linhas 282-379):
- nome, descrição, `schedule_cron`, `is_active`, `skip_reconciliation`, `data_source_id`;
- família inferida de `target_entity`;
- `transform_rules`: aceita array ou objeto (`Array.isArray ? [0] : raw`);
- `field_mapping`: expande valores array em pares; separa `"entidade:campo"` por `split(":")`; detecta `custom_fields.` como prefixo; remarca `isRequired`/`isLookup`/`lookupSource` a partir de `REQUIRED_FIELDS` e `LOOKUP_FIELDS`;
- dedup: usa `dedup_strategy_<entidade>` com fallback para `dedup_strategy` e default `update`; o **campo** volta sempre para `DEFAULT_DEDUP_FIELDS` (o `dedup_field` salvo **não** é reidratado).

Os campos da fonte são carregados por um efeito próprio (`[editingPipeline?.data_source_id, loadSourceFields]`), para refazer quando o `orgClient` fica disponível.

O `MappingStep` recebe `key={editingPipeline?.id ?? "new"}` para forçar remount e resetar o `hasInitialized` interno.

---

## 8. Mapeamento de campos: combobox de origem/destino, autodetecção, valores customizados, grupos de entidade

### 8.1 `FieldCombobox` do wizard

`wizards/PipelineWizard/components/FieldCombobox.tsx` (existe **outro** `FieldCombobox` órfão em `components/etl/FieldCombobox.tsx` — ver 13.3).

Estrutura: `Popover` + `Command` (cmdk).

**Trigger**: `Button variant="outline" role="combobox"` largura total, `justify-between`, `font-normal`. Conteúdo:
- Selecionado: `[Puzzle se custom] (tipo em mono/xs) Label [* se obrigatório]`.
- Vazio: o `placeholder` em `text-muted-foreground`.
- Ícone `ChevronsUpDown` à direita (`opacity-50`).
- `aria-expanded={open}`.
- O `onClick` faz `preventDefault` + `stopPropagation` e alterna manualmente (necessário para funcionar dentro do `CollapsibleTrigger`).

**Popover**: `w-[300px] p-0 z-[100] bg-popover border shadow-lg`, `align="start"`, `sideOffset={4}`, com `onOpenAutoFocus` prevenido.

**Conteúdo**:
- `CommandInput` com o `searchPlaceholder`.
- `CommandEmpty`: `Nenhum campo encontrado.`
- Grupo **`Campos Padrão`** (opções sem `isCustom`).
- Separador + grupo **`Campos Personalizados`** (com ícone `Puzzle` primary em cada item).
- Separador + item **`+ Criar campo personalizado`** em `text-primary` (só se `showCreateCustom && onCreateCustom`).
- Cada item mostra `Check` à esquerda (opacity 100 quando selecionado) e fica com `opacity-50` quando `disabled`.

**Detalhe crítico**: o `CommandItem` usa `value={option.label}` (não `option.value`) — a **busca filtra pelo label**, não pelo nome técnico. Para campos de origem, label e value são iguais (o nome da coluna), então isso só afeta os destinos.

**Outro detalhe**: opções `disabled` recebem apenas `opacity-50`; o `onSelect` **continua funcionando**. Ou seja, o usuário pode selecionar um destino já usado por outra linha.
⚠️ A confirmar: se há proteção no backend contra dois mapeamentos para o mesmo destino.

### 8.2 Origem × destino — quem pode ser escolhido

| Combobox | Fonte das opções | Desabilitados |
|---|---|---|
| Destino | `TARGET_TABLES[entity].fields` **menos** os campos de lookup, **mais** os `customFields[entity]` | os já mapeados na mesma entidade (exceto o da própria linha) |
| Origem | `sourceFields` (todos) | os já usados em qualquer entidade (exceto o da própria linha) |

O tipo detectado da coluna aparece em `font-mono text-xs` ao lado do nome no combobox de origem.

### 8.3 Autodetecção (`utils/field-auto-detection.ts`)

#### 8.3.1 `autoDetectMappings(sourceFields, entity, existingMappings)`

Para cada campo-alvo com aliases definidos:
1. Ignora colunas já usadas.
2. **Exato** com o nome do campo-alvo normalizado → confiança `1`, motivo `exact`, para o loop.
3. **Alias exato** → confiança `0.95`, motivo `alias`.
4. **Fuzzy** por `similarityScore` ≥ 0.7 → motivo `similar`.
5. Reserva a coluna vencedora (não pode ser reusada por outro alvo).

`normalizeFieldName`: minúsculas, NFD sem acentos, não-alfanumérico vira `_`, colapsa `_` repetidos, trim de `_`.
`similarityScore`: 1 se igual; **0.8 se um contém o outro**; senão `1 - levenshtein/maxLen`.

`applyAutoDetectionToMappings` (no `MappingStep`) só aplica sugestões com **confiança ≥ 0.7** e só em linhas que já existem, estão **vazias** e **não são lookup**.

#### 8.3.2 Dicionário de aliases (`FIELD_ALIASES`)

Exemplos por entidade (lista completa no arquivo, linhas 6-85):

- **contacts.document**: `cpf`, `cnpj`, `cpf_cnpj`, `documento`, `doc`, `cpf/cnpj`, `nr_cpf_cnpj`, `num_documento`, `nr_documento`
- **contacts.name**: `nome`, `razao_social`, `razao`, `name`, `nome_cliente`, `cliente`, `nm_cliente`, `nm_razao_social`
- **contacts.phone**: `telefone`, `tel`, `phone`, `celular`, `fone`, `nr_telefone`, `nr_celular`
- **contracts.contract_number**: `contrato`, `nr_contrato`, `num_contrato`, `numero_contrato`, `contract_number`, `cd_contrato`, `id_contrato`
- **titles.title_number**: `titulo`, `nr_titulo`, `num_titulo`, `numero_titulo`, `title_number`, `nosso_numero`, `id_titulo`
- **titles.due_date**: `vencimento`, `dt_vencimento`, `data_vencimento`, `due_date`, `dt_vcto`
- **supplies.supply_number**: `suprimento`, `nr_suprimento`, `num_suprimento`, `numero_suprimento`, `supply_number`, `cd_suprimento`, `id_suprimento`
- **supply_titles.title_number**: `parcela`, `nr_parcela`, `num_parcela`, `titulo`, `nr_titulo`, `title_number`, `nosso_numero`, `id_titulo`, `nufin`

O arquivo carrega um comentário explicando que os aliases com sufixo `_titulo` em `supply_titles` **não são cosméticos**: sem eles, `title_number` casava com `parcelas_em_aberto` (ambos contêm "parcela", score 0.8) em vez de `id_titulo`.

`contacts` **não** tem alias para `email` na chave `email`? Tem: `["email","e_mail","e-mail","ds_email"]`. Mas note que `contracts` **não** tem entrada para `total_value`, `open_balance`, `product`, `due_date`, `portfolio`, `aging_bucket` — esses campos nunca são auto-detectados.

#### 8.3.3 `autoFixRequiredFields` — o "modo agressivo"

Roda só sobre os campos obrigatórios de `REQUIRED_AUTO_FIX`:

| Entidade | Campos considerados |
|---|---|
| contacts | `document`, `name` |
| contracts | `contract_number` |
| titles | `title_number`, `due_date`, `original_value` |
| supplies | `supply_number` |
| supply_titles | `title_number`, `due_date`, `original_value` |

Usa aliases estendidos (`REQUIRED_FIELD_EXTENDED_ALIASES`) unidos aos normais. Pontuação: exato = 1; alias exato = 0.95; **contém** = 0.85; fuzzy ≥ 0.75. Aceita resultado ≥ 0.7.

Só existem aliases estendidos para `contacts:document`, `contacts:name`, `contracts:contract_number`, `titles:title_number`, `titles:due_date`, `titles:original_value` — **nenhum para supplies/supply_titles** (esses caem só nos aliases normais).

`getRequiredFieldLabel` traduz a chave `entidade:campo` para português (tabela de 12 entradas).

### 8.4 Valores customizados de normalização (`CustomValueModal`)

`components/CustomValueModal.tsx`. Modal pequeno (`sm:max-w-md`).

| Elemento | Detalhe |
|---|---|
| Título | ícone `Tag` + `Novo Valor Padrão` (ou `Editar Valor Padrão`) |
| Descrição | `Defina um novo valor padrão para o campo **{fieldName}** com aliases para auto-detecção.` |
| `Valor Interno *` | `Input`. Sanitiza a digitação removendo tudo fora de `[\w\sÀ-ɏ]`. Placeholder `ex: Em Analise`. Ajuda: `Identificador único (letras, números, espaços e underscore)` |
| `Nome de Exibição *` | `Input`. Placeholder `ex: Em Análise` |
| `Aliases (para auto-detecção)` | `Input` + botão `+` (desabilitado se vazio). Enter adiciona. Ajuda: `Variações do valor que serão detectadas automaticamente`. Aliases viram `Badge secondary` com `X` para remover. Sempre em minúsculas, sem duplicatas |
| Rodapé | `Cancelar` (outline) · `Adicionar Valor` / `Salvar Alterações` |

Validação no save:
- `Valor interno é obrigatório` se vazio;
- `Use apenas letras, números, espaços e underscore` se não casar `^[\w\sÀ-ɏ]+$`;
- `Nome de exibição é obrigatório` se vazio;
- se nenhum alias foi informado, usa `[label.toLowerCase()]`.

Campos com erro ganham `border-destructive` e a mensagem em `text-xs text-destructive`.

O valor criado vive **só neste pipeline**, dentro de `transform_rules.custom_standard_values[targetField]`. Não vai para a tabela global `standard_values` (para isso, o link "Gerenciar Valores Padrão").

### 8.5 Criação de campo personalizado a partir do mapeamento

Dois caminhos abrem o `CustomFieldModal` a partir do `MappingStep`:

| Gatilho | Handler | `customFieldMappingIndex` |
|---|---|---|
| `+ Criar campo personalizado` dentro do combobox de **destino de uma linha** | `onCreateCustomField(globalIndex)` | índice da linha |
| `+ Criar campo personalizado` dentro do combobox de **adicionar mapeamento** | `onCreateCustomFieldForEntity(entity)` | `-1` (sentinela) |

Ao salvar (`handleSaveCustomField`):
1. Determina a entidade: `fieldData.entity_type` → senão a da linha → senão `customFieldTargetEntity`.
2. **Persiste imediatamente** via `upsert` em `custom_field_definitions` (`is_filterable: true`, `is_active: true`), com `onConflict: "entity_type,field_name"`. Erro é apenas logado.
3. Adiciona na lista local `customFields[entidade]` (sem duplicar).
4. Se veio de uma linha (`index >= 0`), preenche o `targetField` daquela linha e marca `isCustomField: true` com o `customFieldType`.

Os campos personalizados existentes da org são carregados ao abrir o wizard (`useEffect` em `[open, orgClient]`), filtrando `is_active = true`, ordenados por `created_at DESC`, e mesclados com os criados localmente.

---

## 9. Agendamento (CronIntervalField): modos de agendamento, tradução em linguagem natural, validações

### 9.1 Onde o cron aparece

| Local | Formato | Editor |
|---|---|---|
| Pipeline (passo 3) | **uma linha** de cron | `ScheduleStep` (5 modos) — o modo `interval` usa `CronIntervalField` |
| Materialização | **multi-cron** (1+ linhas separadas por `\n`) | `MvScheduleField` (2 modos) — o modo `interval` usa o **mesmo** `CronIntervalField` |
| Cards de pipeline | leitura | `translateCronExpression` |
| Detalhe do pipeline | leitura | `translateCronExpression` |
| Card de agendamento da MV | leitura | `describeSchedule(cron, translateCronExpression)` |

### 9.2 `CronIntervalField` — o editor de cadência

`src/components/etl/shared/CronIntervalField.tsx`. Componente **controlado**: recebe `IntervalSpec`, emite `onChange(spec)`.

```ts
interface IntervalSpec {
  intervalMin: 10 | 15 | 20 | 30 | 60;  // divisores de 60
  startHour: number;  // 0..23, inclusive
  endHour: number;    // 0..23, inclusive, >= startHour
  offsetMin: number;  // 0..intervalMin-1, múltiplo de 5
  days: number[];     // 0=dom..6=sáb; vazio = todos
}
```

Layout (linha `flex flex-wrap items-end gap-x-3 gap-y-2`):

| Controle | Label | Largura | Opções |
|---|---|---|---|
| Intervalo | `A cada` | `w-[6.5rem]` | `10 min`, `15 min`, `20 min`, `30 min`, `60 min` |
| Hora inicial | `das (Brasília)` | `w-[4.5rem]` | `00h`..`23h` |
| Hora final | (mesma label, separado por `às`) | `w-[4.5rem]` | `00h`..`23h` |
| Offset | `Início em :MM` | `w-[5.5rem]` | `:00`, `:05`, ... até `< intervalMin`. **Só aparece se `intervalMin < 60` e houver mais de uma opção** |

`aria-label` em todos: `Intervalo em minutos`, `Hora inicial`, `Hora final`, `Minuto de início (offset)`.

Bloco de dias:
```
Dias
[Todos os dias] [Dias úteis] [Específicos]
  (quando "Específicos") [Dom][Seg][Ter][Qua][Qui][Sex][Sáb]
```
- Botões `aria-pressed`, `rounded-md border px-2.5 py-1 text-xs font-medium`; ativo = `border-primary bg-primary text-primary-foreground`.
- Aviso quando `custom` e nenhum dia marcado: `Nenhum dia marcado — selecione ao menos um.` (âmbar).

Bloco de preview (`rounded-lg border bg-muted/40 p-3`):
```
🔁 a cada 30 min, das 06:00 às 18:30 — roda 06:00, 06:30 … 18:30 (26×/dia), todos os dias
   26 execuções/dia                                    `0,30 6-18 * * *`
```

Regras de coerção automática:
- Trocar `intervalMin` que invalida o offset → `offsetMin = 0`.
- Escolher `startHour > endHour` → `endHour = max(start, endHour)`.
- Escolher `endHour < startHour` → `startHour = min(end, startHour)`.
- Trocar para "Dias úteis" → `[1,2,3,4,5]`; "Todos" → `[]`; "Específicos" mantendo os dias atuais, ou `[1..5]` se vazio.

O `dayMode` é **estado explícito**, não derivado — porque `[1,2,3,4,5]` é ambíguo (é "dias úteis" e também um "custom" válido). Um `useEffect` com `lastDaysKey` re-deriva o modo apenas quando o `value` externo muda (round-trip), ignorando as próprias edições.

### 9.3 Geração e parsing (`shared/cron-interval.ts`)

**Geração** (`generateIntervalCron`): `"{minutos} {hora} * * {dow}"`, onde minutos = progressão `offset, offset+step, ...` < 60 juntada por vírgula, hora = `start-end` (ou só `start` se iguais), dow = `*` ou lista.

Exemplos documentados no arquivo:
| Spec | Cron |
|---|---|
| 30 min, 6-18, offset 0, todos | `0,30 6-18 * * *` |
| 30 min, 6-18, offset 20 | `20,50 6-18 * * *` |
| 15 min, 8-17, offset 0, dias úteis | `0,15,30,45 8-17 * * 1-5` |
| 60 min, hora 0, offset 30 | `30 0 * * *` |

**Parsing** (`parseIntervalCron`): exige 5 campos, `dom === "*"` e `month === "*"`. Os minutos precisam ser uma **progressão aritmética perfeita e completa dentro da hora** (`offset, offset+step, ... < 60`), com `step ∈ INTERVAL_OPTIONS`; minuto único = intervalo 60. A hora precisa ser **range contíguo** (`H` ou `H1-H2`), sem vírgula, `*` ou `/`. Retorna `null` em qualquer desvio.

Casos que **não** casam (e caem no editor de horários): `0 6,10,13,16 * * *` (horas irregulares), `0 */6 * * *` (step de hora), `*/15 6-18 * * *` (step de minuto).

**Descrição** (`describeIntervalCron`): `"{cadência}, das {primeiro} às {último} — roda {resumo} ({N}×/dia), {dias}"`. Cadência = `1× por hora` se 60min, senão `a cada N min`. Resumo lista todos se ≤ 4, senão `primeiro, segundo … último`. Dias = `todos os dias` / `dias úteis` / `Seg, Qua`.

### 9.4 Cron do pipeline — modos e tradução

`ScheduleStep` monta o cron por `generateCronExpression` (`wizards/shared/utils.ts`):

| Modo | Cron gerado |
|---|---|
| `manual` | `null` |
| `daily` | `{m} {h} * * *` |
| `weekly` | `{m} {h} * * {dias}` (default `1-5`) |
| `multiple_daily` | `{m} {h1,h2,h3} * * *` — **todas as horas usam o minuto do primeiro horário** |
| `interval` | `generateIntervalCron(spec)` |
| `custom` (fallback) | tratado como `weekly` |

> **Bug observável**: no modo `multiple_daily` a UI permite escolher minutos diferentes por horário, mas `generateCronExpression` descarta os minutos extras (`allHours = [h, ...extraTimes.map(t => t.hour)]`, minuto único). Configurar `08:00` + `14:30` gera `0 8,14 * * *` — o 14:30 vira 14:00, silenciosamente.

Detecção do modo ao abrir/editar (`useState` inicial + `useEffect` em `[scheduleCron]`):
1. Se não há cron → `manual` e **reseta** hora/minuto/dias para os defaults.
2. Se `parseIntervalCron` casa **e** roda > 1×/dia → `interval`.
3. Senão, `parseCronExpression`: hora com vírgula → `multiple_daily`; dow `*` → `daily`; senão → `weekly`.

O passo 2 é deliberado: um cron de 1×/dia (`0 8 * * *`) também "casa" como IntervalSpec, mas deve continuar abrindo como `daily`.

### 9.5 Tradução para português (`src/lib/cron-translator.ts`)

`translateCronExpression(expr)` — reconhece, nesta ordem:

| Padrão | Saída |
|---|---|
| `* * * * *` | `A cada minuto` |
| `*/X * * * *` | `A cada X minutos` |
| `X * * * *` | `A cada hora, no minuto X` |
| `0 */X * * *` | `A cada X horas` |
| `M H[,H...] * * *` | `Diariamente às 07:00 e 13:00` |
| `M H[,H...] * * 1-5` | `Dias úteis (seg a sex) às 08:00` |
| `M H[,H...] * * D` | `Toda segunda-feira às 08:00` |
| `M H D * *` | `Todo dia 15 do mês às 09:00` |
| `M H D Mo *` | `Todo dia 1 de janeiro às 09:00` |
| não reconhecido | `Executa às 8-10h no minuto 30` (fallback) ou `Expressão CRON personalizada` |
| entrada inválida | `Expressão inválida` / `Formato inválido (esperado: 5 campos)` |

Listas de horários são unidas em pt-BR: 1 item → `07:00`; 2 → `07:00 e 13:00`; 3+ → `07:00, 13:00 e 19:00`.

`expandHours` retorna `null` para campos com `/`, `-` ou `*` — por isso `0,30 6-18 * * *` (o cron do modo intervalo) **não é traduzido** pelo tradutor; cai no fallback `Executa às 6-18h no minuto 0,30`.
Isso importa: no card de agendamento da Materialização, uma linha de cadência aparece com esse texto.

Existe também `CRON_PRESETS` no tradutor (7 presets) — **não usado** por esta tela.

### 9.6 Próxima execução (`getNextExecutionDate`)

`wizards/shared/utils.ts` linhas 339-393. Calcula **no navegador**, com o fuso local:
- `multiple_daily`: procura a próxima hora do dia que ainda não passou; se todas passaram, primeira hora do dia seguinte.
- `daily`/`weekly`: monta hoje no horário; se já passou, +1 dia; em `weekly`, avança até cair num dia marcado.
- Formato: `toLocaleString("pt-BR", { weekday:"long", day:"2-digit", month:"short", hour:"2-digit", minute:"2-digit" })`.

> Divergência conhecida: o agendamento roda em **horário de Brasília** (declarado no card informativo), mas a previsão é calculada no **fuso do navegador**. Para quem estiver fora de BRT, "Próximo" mostra um horário diferente do real.

### 9.7 `parseCronExpression` × `parseIntervalCron` — dois parsers

| Parser | Arquivo | Retorna | Usado em |
|---|---|---|---|
| `parseCronExpression` | `wizards/shared/utils.ts` | `{ type: daily\|weekly\|multiple_daily\|custom, minute, hour, hours?, daysOfWeek? }` | ScheduleStep, getNextExecutionDate |
| `parseIntervalCron` | `etl/shared/cron-interval.ts` | `IntervalSpec \| null` | ScheduleStep, MvScheduleField, materialization-helpers |
| `parseCronParts` | `lib/cron-translator.ts` | `{minute,hour,dayOfMonth,month,dayOfWeek}` | tradução |
| `parseScheduleToSlots` | `tabs/materialization-helpers.ts` | `{mode, slots[], daysOfWeek[]}` | MvScheduleField |

Quatro implementações de parsing de cron convivem no domínio.

### 9.8 Validações de cron

| Onde | Regra | Feedback |
|---|---|---|
| Pipeline | Nenhuma validação explícita — o cron é sempre gerado pelos controles | — |
| Materialização | `isValidScheduleCron` (`useMvRefresh.ts`): cada linha não-vazia precisa casar `^(\S+\s+){4}\S+$` (exatamente 5 campos) | `⚠ Expressao cron invalida — cada horario deve ter 5 campos.` em `text-destructive` |
| Materialização (mutation) | Normaliza (trim por linha, colapsa espaços, descarta vazias) e revalida; se inválido, `throw` com mensagem longa | toast destrutivo `Erro ao salvar o agendamento` |

Mensagem de erro da mutation: `Expressao cron invalida. Cada linha deve ter 5 campos no formato 'minuto hora dia mes dia-da-semana' (ex.: 30 5 * * *).`

Nenhum dos dois valida **semanticamente** os campos (ex.: `99 99 * * *` passa nos dois).

---

## 10. Aba Materialização: KPIs, barra de status, saúde, agendamento multi-cron, forçar atualização, pausa, histórico

Fonte: `src/components/etl/tabs/MaterializationTab.tsx` (1368 linhas) + `MvStatusBar.tsx` + `MvKpiCards.tsx` + `MvScheduleField.tsx` + `mv-health.tsx` + `materialization-helpers.ts` + `src/hooks/useMvRefresh.ts`.

### 10.1 Layout (rebuild 2026-06-19, documentado no cabeçalho do arquivo)

```
┌──────────────────────────────────────────────────────────────────────────┐
│ FAIXA DE STATUS (largura total) — MvStatusBar                            │
├───────────────────────────────────┬──────────────────────────────────────┤
│ COLUNA ESQUERDA (flex-col)        │ COLUNA DIREITA                       │
│  ┌ MvKpiCards (2×2, altura nat.) │  ┌ Card "Historico"                  │
│  │ [Ultima duracao][Linhas]      │  │  tabela paginada (11 linhas/pág)  │
│  │ [Tamanho base ][Sucesso]      │  │  rodapé de paginação              │
│  └                                │  │  "Janela das até 200 execucoes"   │
│  ┌ Card "Agendamento" (flex-1)    │  └                                   │
│  │  MvScheduleField               │                                      │
│  │  chips de preset               │                                      │
│  │  preview do cron               │                                      │
│  │  avisos inline                 │                                      │
│  │  collapsible "horarios de ETL" │                                      │
│  │  [Salvar agendamento] (mt-auto)│                                      │
│  └                                │                                      │
├───────────────────────────────────┴──────────────────────────────────────┤
│ ⓘ Nota do modelo (rodapé discreto)                                        │
└──────────────────────────────────────────────────────────────────────────┘
```

Grade: `grid items-stretch gap-4 lg:grid-cols-2` — **iso-altura**: as duas colunas ganham a altura da mais alta; o card de agendamento (`flex-1`) e o wrapper do histórico (`flex-1`) preenchem a célula, alinhando os fundos. Abaixo de `lg` empilha.

A aba **não tem** busca nem botão de criar (a `ETLPage` suprime os dois quando `activeTab === "materializacao"`).

### 10.2 Estados de carregamento e guarda

| Situação | Renderização |
|---|---|
| `statusLoading && settingsLoading` | Skeleton: `h-16` largura total + grade `lg:grid-cols-2` com dois `h-80` |
| `!currentOrg` | Card com `Nenhuma organizacao selecionada.` (py-12, centrado, muted) |
| `statusError` | `Alert variant="destructive"` no lugar da faixa: `Nao foi possivel carregar o estado da materializacao` / `Verifique sua conexao e tente novamente.` + `RefreshButton label="Tentar de novo"` |

### 10.3 Faixa de status (`MvStatusBar`)

`Card` com classe de superfície vinda do tema de saúde. Layout `flex flex-col gap-3 p-4 md:flex-row md:items-center md:justify-between`.

**Lado esquerdo** — indicador + frase + badges:

1. **Bolinha de saúde** 10×10 (`h-2.5 w-2.5`), com `animate-ping` sobreposto quando `theme.ping`.
2. **Título de saúde** em `text-sm font-semibold` com a cor de acento (ou `Carregando…` enquanto `statusLoading`).
3. **Próxima execução**: `· 🕐 proxima: {label}` com tooltip = `{hint}`.
4. **Última execução**: `✓ {relativo}` (`text-xs muted`) com tooltip `Ultima atualizacao: {absoluto}`.
5. **Badges de estado** (podem coexistir):

| Badge | Condição | Estilo | Tooltip |
|---|---|---|---|
| `⏸ Pausado` | `!isEnabled && healthState !== "running"` | outline amarelo | — |
| `⟳ Rodando` | `isRunningNow` | outline azul, `Loader2` girando | `Um refresh esta em andamento agora para esta organizacao.` |
| `⟳ Solicitada — roda em ate 1 min` | `isForcePending` | secondary azul, `Loader2` girando | `Voce pediu "Atualizar agora". O agendador captura no proximo ciclo (ate 1 min) e a faixa volta ao normal sozinha quando concluir — nada fica preso.` |
| `🗓 Sem agendamento` | `isEnabled && healthState !== "running" && hasNoSchedule` | outline âmbar | `Nenhum horario (cron) definido — a MV nao refresca automaticamente. Defina um agendamento ao lado.` |

**Lado direito** — ações:

| Controle | Gate | Detalhe |
|---|---|---|
| `HelpTip` ⓘ | sempre | Título `Como funciona a materializacao`. Corpo: *"A MV **não** atualiza sozinha após o ETL: ela roda **somente nos horarios agendados** ao lado, mais o botão *Atualizar agora*. Recomendado: 1 horário diário fixo de madrugada (ex.: 05:30) **+** horários logo depois de cada janela de ETL."* |
| `RefreshButton` | sempre | `title="Recarregar estado"`. Só recarrega a tela |
| `Pausar` / `Retomar` | `canWrite` | outline sm, ícone `Pause`/`Play` (ou `Loader2` enquanto pendente). Desabilitado se `togglePending \|\| settingsUnavailable`. Tooltip: `Pausa a atualizacao automatica.` / `Retoma a atualizacao automatica.` |
| `⟳ Atualizar agora` | `canWrite` | primário sm. Desabilitado se `forcePending \|\| isRunningNow \|\| !isEnabled`. Envolto num `<span tabIndex>` para o tooltip funcionar desabilitado. Tooltip contextual: `Retome o agendamento para executar — pausado nao roda nem forcado.` / `Ja ha um refresh em andamento.` / `Forca um refresh agora (roda no proximo ciclo, ate 1 min).` |

### 10.4 Modelo de saúde (`mv-health.tsx`)

```ts
computeFreshness(ageSeconds):
  null        → "unknown"
  ≤ 13h       → "fresh"
  ≤ 26h       → "stale"
  > 26h       → "old"

resolveHealthState(isRunningNow, isEnabled, freshness):
  isRunningNow  → "running"
  !isEnabled    → "paused"
  senão         → freshness
```

Limiares fixos: `FRESH_MAX_SECONDS = 13h`, `STALE_MAX_SECONDS = 26h`. A justificativa no código: como o run diário garantido deve cair de madrugada, até ~13h ainda é fresco.

Tema por estado (`buildHealthTheme`):

| Estado | Superfície | Bolinha | Acento | Título | Ping |
|---|---|---|---|---|---|
| `running` | `border-blue-500/30 bg-blue-500/5` | `bg-blue-500` | azul | `Atualizando agora…` | não |
| `fresh` | verde | `bg-green-500` | verde | `Atualizado {idade}` | **sim** |
| `stale` | amarelo | `bg-yellow-500` | amarelo | `Atualizado {idade}` | não |
| `old` | destructive | `bg-destructive` | destructive | `Desatualizado {idade}` | não |
| `paused` | amarelo | `bg-yellow-500` | amarelo | `Atualizacao pausada` | não |
| `unknown` | `border-border bg-muted/30` | `bg-muted-foreground` | muted | `Sem registro de atualizacao` | não |

`fmtAge`: `sem registro` / `ha Ns` / `ha N min` / `ha Nh Nmin` / `ha Nd`.

> O campo `icon` do `HealthTheme` (ícone 28×28) é montado mas **nunca usado** pela `MvStatusBar` — sobrou do antigo `MvStatusHero`.

### 10.5 Descrição da próxima atualização (`describeNextRefresh`)

Ordem de decisão (`materialization-helpers.ts` linhas 197-232):

| Condição | label | hint |
|---|---|---|
| `!isEnabled` | `pausada` | `retome e defina um agendamento para a MV voltar a rodar` |
| cron vazio | `sem agendamento` | `defina um horario (cron) para a MV refrescar automaticamente` |
| `force_pending` | `em instantes` | `execucao forcada — roda no proximo ciclo (ate 1 min)` |
| `is_running` | `rodando agora` | `atualizacao em andamento` |
| `next_window_at` no futuro | tempo relativo (ex.: `em 17 minutos`) | `proxima ocorrencia do agendamento (cron)` |
| fallback | `no proximo horario agendado` | `conforme o cron configurado (horario de Brasilia)` |

### 10.6 KPIs (`MvKpiCards`)

Grade **2×2** (`grid-cols-2 gap-2.5`). Cada cartão: `rounded-lg border bg-card p-2.5`, com ícone 14×14 + label em `text-[11px]`, valor em `text-base font-semibold tabular-nums`, e hint em `text-[11px] muted`.

| # | Label | Ícone | Valor | Hint |
|---|---|---|---|---|
| 1 | `Ultima duracao` | `Timer` | duração do **último run bem-sucedido** | `media {X}` (média das durações dos sucessos) ou `sem sucesso recente` |
| 2 | `Linhas na base` | `Rows3` | `status.mv_row_estimate` (pt-BR) | `estimativa` |
| 3 | `Tamanho da base` | `Database` | `status.mv_size_pretty` (ex.: `412 MB`) | `materializada` · tooltip: `{N} bytes` |
| 4 | `Sucesso` | `CheckCircle2` (verde se ≥90%) | `{taxa}%` sobre a janela carregada | `{sucessos}/{total} execucoes` ou `sem execucoes` |

Skeleton: 4 blocos `h-[58px]` quando `loading && !status && runs vazio`.

> O guia de negócio do próprio app descreve **5** KPIs (incluindo "Execuções" e "Sucesso (24h)"). O código atual tem **4**, e a taxa é sobre a janela de 200 runs carregada, não sobre 24h. A documentação de negócio está defasada em relação ao código.

`fmtDuration`: `< 1000ms` → `{N} ms`; `< 60s` → `{X.X} s`; senão `{M}m {S}s`.

### 10.7 Card de Agendamento

Header: ícone `CalendarClock` + `Agendamento`. Descrição: `Em quais horarios a base e refrescada (horario de Brasilia).`

Conteúdo, na ordem:

**A. Alerta de config indisponível** (`settingsUnavailable = !settingsLoading && (settingsError || settings == null)`):
`Alert destructive` → `Configuracao indisponivel` / `Nao foi possivel carregar a configuracao da materializacao.` + `RefreshButton label="Tentar de novo"`.

**B. Nota "sem agendamento"** (`!cronTouched && cron salvo vazio && !settingsUnavailable`):
Caixa âmbar `border-amber-500/30 bg-amber-500/5 p-2.5 text-xs` com ícone `CalendarOff`:
> Esta organizacao esta **sem agendamento**. Defina os horarios abaixo, salve e ative para a MV voltar a refrescar.

**C. `MvScheduleField`** (ver 10.8).

**D. Chips de preset** (`flex flex-wrap gap-1.5`, botões `h-7 px-2 text-xs`):

| Cron | Label |
|---|---|
| `30 5 * * *` | `05:30 (madrugada)` |
| `0 6,13,19 * * *` | `3x/dia (06h, 13h, 19h)` |
| `0 */6 * * *` | `A cada 6h` |
| `0 1 * * *` | `01:00` |

Variante `secondary` quando o preset **coincide** com o cron atual (`cronsCoincide` = compartilha ao menos uma linha), senão `outline`. Clicar **substitui** o cron inteiro pelo preset.

**E. Preview do cron** (`rounded-md border bg-muted/30 p-2.5`), uma linha por expressão:
```
✓ Diariamente às 05:30                              `30 5 * * *`
✓ Executa às 6-18h no minuto 0,30                   `0,30 6-18 * * *`
```
Ícone `CheckCircle2` verde + tradução em `font-medium`; à direita, o cron cru em `<code>` mono `text-[10px]`.

**F. Erro de validação**: `⚠ Expressao cron invalida — cada horario deve ter 5 campos.`

**G. Aviso "virada do dia"** (`cronLacksDailyRun`) — nota inline âmbar com ícone `MoonStar`:
> Sem garantia de execucao diaria: o **days_overdue** so envelhece quando a MV roda. Inclua ao menos **1 horario diario** de madrugada (ex.: `30 5 * * *`).

Heurística (`hasGuaranteedDailyOccurrence`): basta **uma** linha garantir. Por linha: 5 campos válidos; hora curinga/step (`*`, `*/n`) com dom/mês/dow todos `*`; senão, dom/mês/dow todos `*`.

**H. Aviso de colisão com ETL** (`collidingPipelines.length > 0`) — nota inline âmbar com `AlertTriangle`:
> Mesmo horario do pipeline **X, Y**. Prefira agendar a MV **logo apos** a janela de ETL.

**I. Disclosure "Ver horarios dos pipelines de ETL"** (`Collapsible`, só se houver pipelines agendados):
- Gatilho: ícone `CalendarClock` + texto + badge com a contagem + chevron que rotaciona 180°.
- Conteúdo: dica com ícone `Lightbulb` (`Agende a MV **logo apos** estas janelas de ETL para materializar dados ja ingeridos.`) + lista (`divide-y rounded-md border bg-background`):
```
🗓 Importação diária                    [inativo]  [⚠ mesmo horario]
   Diariamente às 06:00
```
Cada item: nome em `font-medium`; badge `inativo` se `!is_active`; badge âmbar `mesmo horario` se coincide; abaixo, o schedule traduzido (`describeSchedule`) ou o cron normalizado.

Fonte dos pipelines: `usePipelines({})` filtrado por `is_scheduled && !!schedule_cron`.

**J. Botão de salvar** (`mt-auto w-full`):
- Texto: `Salvar agendamento` ou, se o cron está vazio, `Remover agendamento`.
- Desabilitado se `!canWrite || !cronValid || !cronDirty || updateSettings.isPending || settingsUnavailable`.
- Spinner `Loader2` enquanto salva.

Toast de sucesso:
- com cron: título `Agendamento salvo`, descrição `A MV sera materializada {descrição em minúsculas} (horario de Brasilia).`
- sem cron: título `Agendamento removido`, descrição `A MV ficara inerte ate voce definir um horario e ativar.`

Toast de erro: `Erro ao salvar o agendamento` + mensagem.

**Importante**: salvar o cron envia `enabled: settings.enabled` — **não** liga a materialização. Definir o cron e salvar numa org pausada mantém tudo pausado; o usuário precisa clicar "Retomar" separadamente (o texto da nota B já avisa: "Defina os horarios abaixo, salve e ative").

### 10.8 `MvScheduleField` — o editor multi-cron

`src/components/etl/tabs/MvScheduleField.tsx`. Componente controlado (`value: string | null` → `onChange(string | null)`), com **dois modos**.

Seletor de modo (`ToggleGroup` `grid grid-cols-2`):

| Valor | Label | aria-label |
|---|---|---|
| `interval` | `A cada intervalo` | `A cada intervalo` |
| `times` | `Horários` | `Horarios` |

#### 10.8.1 Modo "A cada intervalo"

1. `CronIntervalField` (seção 9.2) para a **cadência**.
2. Bloco **"Horários extras (Brasília)"** (`rounded-lg border bg-muted/30 p-3`):
   - Ícone `Clock` + label.
   - Texto: `Execuções avulsas fora da cadência — ex.: 00:30 para envelhecer o atraso na virada do dia.`
   - Sem extras: botão `+ Adicionar horário extra`.
   - Com extras: uma linha por horário — `[HH ▾] : [MM ▾] [🗑]` e, na última linha, `+ Adicionar`.
   - Novo extra nasce em **00:30**.
   - `aria-label` por controle: `Hora do horário extra N`, `Minuto do horário extra N`, `Remover horário extra N`.

Cron gerado (`generateIntervalSchedule`): linha da cadência **primeiro**, depois uma linha `{m} {h} * * *` por extra (ordenados por hora/minuto), unidas por `\n`.

#### 10.8.2 Modo "Horários"

1. `ToggleGroup` secundário: `Todos os dias` (`daily`) | `Dias da semana` (`weekly`).
2. Se `weekly`: chips de dia (`min-w-[2.25rem] rounded-md border px-2 py-1 text-xs`); aviso âmbar `Nenhum dia marcado — sera usado dias uteis (seg a sex).` quando vazio.
3. Lista de slots — label `Horario (Brasilia)` (singular) ou `Horarios (Brasilia)` (plural):
```
[HH ▾] : [MM ▾] [🗑]
[HH ▾] : [MM ▾] [🗑] [+ Adicionar]
```
- Horas 0-23; minutos de **5 em 5** (`0,5,10,...,55`) — mais granular que o ScheduleStep do pipeline, que só oferece 0/15/30/45.
- Botão de remover **desabilitado quando há só um slot**, com `title="Mantenha ao menos um horario"`.
- Novo slot = `min(último+4, 23)` com o mesmo minuto.
- Default inicial: **05:30**, dias `[1,2,3,4,5]`.

Cron gerado (`generateScheduleFromSlots`): uma linha por slot; `daily` → `{m} {h} * * *`; `weekly` → `{m} {h} * * {dias}` (ou `1-5` se nenhum dia marcado).

#### 10.8.3 Decisão de modo ao carregar

`parseIntervalSchedule(cron)` retorna `null` (→ modo `times`) quando:
- schedule vazio;
- **não** há linha de cadência (só horários avulsos) — o editor de slots representa melhor;
- há **2 ou mais** linhas de cadência (ambíguo);
- alguma linha não casa nem como cadência nem como 1×/dia (ex.: horas irregulares, step de hora).

Caso contrário, modo `interval` com `intervalSpec` = a cadência e `extraSlots` = as linhas de 1×/dia.

Resync externo: `useEffect` em `[value]` com guarda `lastEmitted` — ignora o eco das próprias emissões.

`parseScheduleToSlots` ignora linhas cujo campo de **minuto contém vírgula** (isso é cadência, não slot) e linhas com step/curinga na hora, evitando corromper `0,30` em `0`.

### 10.9 Forçar atualização

`handleForceNow` → `useRequestMvRefreshNow()` → RPC `request_mv_refresh_now(p_schema_name)`.

Toast: `Atualizacao agendada` / `Roda no proximo ciclo (ate 1 min). A tela atualiza sozinha quando concluir.`
Erro: `Erro ao agendar execucao` + mensagem.

Pontos de disparo: botão na faixa de status; botão `Atualizar agora` no estado vazio do histórico.

Após o disparo, `force_pending` fica `true` e o polling acelera para **5s** (`MV_REFRESH_POLL_ACTIVE_MS`) até concluir; em repouso é **30s** (`MV_REFRESH_POLL_IDLE_MS`). O polling do histórico segue a mesma cadência.

### 10.10 Pausar/retomar

`handleToggleEnabled(next)` → `useUpdateMvRefreshSettings({ scheduleCron: settings.schedule_cron, enabled: next })`.

Toast:
- ligando: `Materializacao retomada` / `O refresh voltara a rodar nos horarios agendados (defina um cron se ainda nao houver).`
- desligando: `Materializacao pausada` / `O refresh automatico foi pausado. Os dados nao serao atualizados ate retomar.`
- erro: `Erro ao alterar o estado` + mensagem.

**Sem confirmação**, mesmo sendo a ação que congela toda a base de consulta da org.

### 10.11 Histórico de execuções

Card `Historico` com descrição `Clique numa execucao para ver detalhes.` No header, à direita, badge condicional:
```
[⚠ Falha há 2 dias]     ← tooltip com a data absoluta
```
(só se existir alguma falha na janela carregada).

Estados:

| Situação | Renderização |
|---|---|
| `runsError` | `Alert destructive`: `Nao foi possivel carregar o historico` / `Tente atualizar novamente.` |
| `runsLoading` | 6 `Skeleton h-10` |
| lista vazia | Caixa tracejada centrada: círculo `bg-muted` com `Database`, `Nenhuma execucao registrada`, `Assim que a rotina rodar, o historico aparecera aqui.` + (se `canWrite`) botão `⟳ Atualizar agora`, desabilitado se `requestNow.isPending \|\| isRunningNow \|\| !isEnabled` (com `title="Retome o agendamento para executar"` quando pausado) |
| normal | Tabela + rodapé |

Tabela (cabeçalho `sticky top-0 z-10 bg-card`):

| Coluna | Alinhamento | Conteúdo |
|---|---|---|
| `Quando` | esquerda | ícone `CheckCircle2` verde / `XCircle` destructive + tempo relativo em `font-medium` (tooltip com `dd/MM/yyyy HH:mm:ss`) |
| `Linhas` | direita | `row_count` em pt-BR, `tabular-nums` |
| `Duracao` | direita | `fmtDuration(duration_ms)` |

Cada `TableRow` tem `role="button"`, `tabIndex={0}`, `aria-label` completo (`Ver detalhes da execucao de {data} — sucesso/falha`), responde a **Enter** e **Espaço**, e ganha `bg-destructive/5 hover:bg-destructive/10` quando falhou.

> Só **3 colunas** — o gatilho (`Forcado`/`Automatico`) e a variação (`rows_delta`) existem no dado e nos componentes `TriggerPill`/`DeltaBadge`, mas **só aparecem no modal de detalhe**. O comentário no código explica: "o gatilho e a variacao vivem no Dialog de detalhe (a coluna e estreita)".

Paginação (rodapé fixo, `mt-3`):
```
Mostrando 1–11 de 200        [‹] [1] [2] [3] … [19] [›]
Janela das ate 200 execucoes mais recentes.
```
- `RUNS_WINDOW = 200` (quantidade buscada do servidor), `RUNS_PAGE_SIZE = 11` (por página, cliente).
- `buildPageItems`: até 7 páginas mostra todas; senão `1 … (page-1, page, page+1) … N` com reticências.
- Botões de página: 32×32, `variant="default"` na atual, com `aria-label="Pagina N"` e `aria-current="page"`.
- Setas `ChevronLeft`/`ChevronRight` com `aria-label` `Pagina anterior`/`Proxima pagina`.
- Reset para página 1 **só ao trocar de org**; ao chegarem runs novos, há apenas um clamp para não estourar o total.

### 10.12 Hooks e RPCs da aba

`src/hooks/useMvRefresh.ts`:

| Hook | RPC | Cadência |
|---|---|---|
| `useMvRefreshStatus()` | `get_mv_refresh_status` | `refetchInterval` dinâmico: 5s se `force_pending \|\| is_running`, senão 30s. `staleTime` 10s |
| `useMvRefreshSettings()` | `get_mv_refresh_settings` | sem polling, `staleTime` 30s |
| `useMvRefreshRuns(limit, ms)` | `list_mv_refresh_runs` | `refetchInterval` recebido do componente (5s/30s), `staleTime` 10s |
| `useUpdateMvRefreshSettings()` | `update_mv_refresh_settings` | mutation; invalida status+settings+runs |
| `useRequestMvRefreshNow()` | `request_mv_refresh_now` | mutation; invalida os três |

Campos de `MvRefreshStatus` disponíveis mas **não exibidos** na UI: `last_success_row_count`, `last_run_at`, `last_run_success`, `last_run_message`, `heartbeat_schedule`, `heartbeat_active`. O cabeçalho do arquivo registra que o painel técnico antigo (`MvDiagnostics`, com heartbeat/timeout/org) **não foi recriado** no rebuild.

### 10.13 Nota do modelo (rodapé)

```
ⓘ Modelo de materializacao por *agendamento (cron)*: a MV roda so nos horarios definidos,
  mais o *Atualizar agora*. Nao ha mais refresh por intervalo nem disparo automatico apos o ETL.
```

---

## 11. Aba Campos Personalizados: lista, modal de campo, tipos suportados, onde o campo aparece depois

Fonte: `src/components/etl/CustomFieldsTab.tsx` + `CustomFieldModal.tsx`.

### 11.1 Contrato

```ts
interface CustomFieldsTabProps { search: string }
export interface CustomFieldsTabRef { openCreateModal: () => void }
```

A aba é auto-suficiente: usa `useCustomFieldDefinitions()`, `useCreate/Update/DeleteCustomFieldDefinition()` diretamente. A `ETLPage` só a aciona via `ref` para o botão "+ Novo Campo".

### 11.2 Estados

| Situação | Renderização |
|---|---|
| Carregando | `Loader2` 32×32 girando, centrado, `py-12` |
| Vazio / sem resultado | `Card` com `Settings2` 48×48 muted, `Nenhum campo personalizado encontrado`, `Tente ajustar os filtros de busca` ou `Crie seu primeiro campo personalizado`, + botão `+ Novo Campo` (só sem busca). **Não checa `canWrite`** |
| Normal | Um `Card` por entidade que tenha campos |

### 11.3 Agrupamento por entidade

Itera `Object.keys(TARGET_TABLES)` na ordem de declaração: `contacts`, `contracts`, `titles`, `supplies`, `supply_titles`. Grupos vazios não renderizam.

Cada card:
```
Contratos  [9]
Campos personalizados para contratos
────────────────────────────────────────
| Nome de Exibição | Nome Interno | Tipo | Opções | Status | ⋮ |
```
- Título: `TARGET_TABLES[entity].label` + `Badge secondary` com a contagem.
- Descrição: `Campos personalizados para {label em minúsculas}`.

### 11.4 Colunas da tabela

| Coluna | Conteúdo | Estilo |
|---|---|---|
| Nome de Exibição | `display_name` | `font-medium` |
| Nome Interno | `field_name` | `font-mono text-sm text-muted-foreground` |
| Tipo | `Badge variant="outline"` com o label PT | — |
| Opções | Até **3** badges secondary com as opções; se houver mais, badge `+N`. Se não é `select` ou não há opções: `-` muted | `max-w-[200px] flex-wrap` |
| Status | `Badge variant={is_active ? "default" : "secondary"}` com `Ativo`/`Inativo` | — |
| (ações) | `⋮` | `w-[70px]` |

Labels de tipo (`FIELD_TYPE_LABELS`, linhas 45-51):

| Valor | Label |
|---|---|
| `text` | Texto |
| `number` | Número |
| `date` | Data |
| `boolean` | Sim/Não |
| `select` | Lista de Opções |

### 11.5 Ações (`⋮`)

| Item | Ícone | Efeito |
|---|---|---|
| Editar | `Edit` | `setEditingField(field)`, `setSelectedTargetTable(field.entity_type)`, abre o modal |
| — separador — | | |
| Excluir | `Trash2` destructive | `confirm("Tem certeza que deseja excluir o campo \"X\"? Esta ação não pode ser desfeita.")` → `deleteField.mutateAsync(id)` |

**Sem gate de `canWrite`.**

Erro na exclusão: toast destrutivo `Erro ao excluir` + `getDeleteErrorMessage(error)`.

> Não há ação de **ativar/desativar** o campo na UI, embora `is_active` seja exibido como coluna e o hook `useUpdateCustomFieldDefinition` aceite o campo. Um campo inativo só pode ser reativado fora da tela.

### 11.6 Modal de campo (`CustomFieldModal`)

**Dois usos distintos, com props diferentes:**

| Origem | `allowEntityChange` | `existingFields` | `editingField` |
|---|---|---|---|
| Aba Campos Personalizados | `!editingField` (true ao criar) | não passado → objeto vazio (**checagem de duplicata desligada**) | o campo em edição |
| PipelineWizard | não passado → `false` | `wizard.customFields` (ativa a checagem) | nunca |

Casca: `DialogContent flex flex-col p-0 w-[95vw] h-[95vh]` — **modal em tela cheia para um formulário de 4 campos**. Header com gradiente, corpo rolável `px-6 py-4 space-y-4`, rodapé `border-t bg-muted/30`.

Título: `Criar Campo Personalizado` / `Editar Campo Personalizado`.
Descrição: `Editar campo de {entidade}` (edição) · `Selecione a entidade e configure o novo campo` (com seletor) · `Adicionar novo campo para {entidade}` (sem seletor).

Campos:

| Campo | Controle | Obrigatório | Visível quando | Detalhe |
|---|---|---|---|---|
| `Entidade *` | `Select` com as 5 entidades | Sim | `allowEntityChange && !isEditing` | Ajuda: `Selecione a entidade à qual este campo será associado.` |
| `Nome de Exibicao *` | `Input` (id=`display_name`) | Sim | sempre | Placeholder `Ex: Codigo do Cliente` |
| `Nome Interno` | `Input` mono | derivado | sempre | Auto-gerado por `slugify(displayName)`; **desabilitado ao editar**. Digitar aplica `slugify` a cada tecla |
| `Tipo do Campo *` | `Select` | Sim | sempre | 5 opções (ver 11.7) |
| `Opcoes da Lista *` | `Input` + botão `+` | Sim se tipo `select` | tipo `select` | Enter adiciona; badges com `X` para remover; ajuda `Adicione pelo menos uma opcao para o campo de selecao.` |

`slugify`: minúsculas, NFD sem acentos, não-alfanumérico → `_`, trim de `_`, **truncado em 50 caracteres**.

Checagem de duplicata (só quando `existingFields` é passado e não está editando): compara `field_name` case-insensitive dentro da entidade selecionada. Se bate:
- o `Input` ganha `border-destructive`;
- aparece `⚠ Já existe um campo "{label}" com este nome interno.`;
- o botão de salvar é bloqueado.

Ajuda padrão do nome interno: `O nome interno não pode ser alterado após a criação.` (editando) / `Gerado automaticamente. Use apenas letras, numeros e underscores.` (criando).

`canSave = displayName.trim() && fieldName.trim() && !duplicateField && (tipo !== "select" || options.length > 0)`.

Rodapé: `Cancelar` (outline) · `Criar Campo` / `Salvar`.

### 11.7 Tipos suportados (`FIELD_TYPES` do modal)

| Valor | Label no modal |
|---|---|
| `text` | Texto |
| `number` | Numero |
| `date` | Data |
| `boolean` | Sim/Nao |
| `select` | Lista de Opcoes |

> Os labels do modal estão **sem acento** (`Numero`, `Sim/Nao`, `Opcoes`), enquanto a tabela da aba usa acento (`Número`, `Sim/Não`, `Lista de Opções`). Mesmo dado, duas grafias.

### 11.8 Onde o campo aparece depois

Cadeia real, a partir do código:

1. **No wizard de pipeline** — o campo entra na lista de destinos do `FieldCombobox` (grupo "Campos Personalizados", com ícone `Puzzle`), por entidade.
2. **No ETL** — mapeado, o valor cai em `custom_fields` (JSONB) da entidade.
3. **Em filtros e colunas** — `useMappedFilterFields()` (`src/hooks/etl/useCustomFields.ts` linhas 134-329) monta a lista de campos filtráveis cruzando:
   - os `field_mapping` dos pipelines **ativos**;
   - as `custom_field_definitions` **ativas**;
   - e os campos de sistema fixos (`has_pnp`, `seals`, `days_overdue`, `safra_days`, `min_open_installment`, `min_open_installment_disponivel`).
   Campos que **não** são coluna real da entidade recebem o prefixo `custom.` (ex.: `custom.instituicao`) e `isCustom: true`.
4. **Nas opções de filtro** — `useCustomFieldOptions()` (linhas 340-424) monta os valores selecionáveis a partir do `query_config.unique_values` **cacheado na fonte** (não consulta a base), incluindo o campo se ele está em `transform_rules.list_fields` **ou** tem ≤ 50 valores distintos.
5. **No Dicionário de Dados** (`/settings`, aba Field Explorer) — `useFieldExplorer` agrega `STANDARD_FIELD_LABELS` + definições customizadas + `standard_values` + `transform_rules`. ⚠️ Esse hook só cobre `contacts`, `contracts`, `titles` — **campos de `supplies`/`supply_titles` não aparecem no dicionário**.
6. **Em templates/prompts** — como variável `{{entidade.custom.<campo>}}` (fora do escopo desta tela; documentado em `variaveis-e-templates`).

**O que a aba não diz:** nada disso é explicado na UI. A tela lista campos sem indicar em quantos pipelines cada um é usado, se já tem dados, ou onde ele aparece.

---

## 12. Erros de execução (JobErrorsDialog) e histórico (PipelineHistoryDialog)

### 12.1 `PipelineHistoryDialog`

`src/components/etl/PipelineHistoryDialog.tsx`. Acionado por "Ver Histórico" no menu do pipeline.

**Casca**: `DialogContent flex flex-col p-0 w-[95vw] h-[95vh] overflow-hidden`.
Título: `📊 Histórico de Execuções: {pipelineName}`.
`DialogDescription` com `className="sr-only"` (`Visualize o histórico de execuções do pipeline.`).

**Cards de estatísticas** (`grid grid-cols-4 gap-4 px-6 shrink-0`, cada um `p-3 border rounded-lg bg-card`):

| Card | Valor | Detalhe |
|---|---|---|
| Total Execuções | `jobRuns.length` | limitado a **20** pelo hook |
| Taxa de Sucesso | `round(completed / total × 100)%` | + `TrendingUp` verde se ≥80%, senão `TrendingDown` vermelho |
| Duração Média | string formatada | ver 12.1.1 |
| Total Processado | `sum(processed_records)` | `toLocaleString()` (sem locale explícito) |

`Separator` abaixo. Lista rolável no restante.

#### 12.1.1 Cálculo da duração média

```ts
avgDuration = formatDuration(
  new Date(Date.now() - stats.totalDuration / stats.completedCount).toISOString(),
  new Date().toISOString()
)
```
Ou seja: monta duas datas artificiais para reusar o formatador. Funciona, mas é frágil e ilegível. Se `completedCount === 0`, mostra `N/A`.

#### 12.1.2 Item de execução

Cada run é uma caixa `border rounded-lg p-4 hover:bg-accent/50`:

**Linha de cabeçalho** (esquerda → direita):
- Badge de status (outline, com classe de cor de fundo): `Concluído` (verde), `Falhou` (vermelho), `Executando` (azul, ícone girando), `Cancelado` (amarelo, ícone `Ban`), default (cinza, ícone `AlertCircle`).
- Badge secondary: `Manual` ou `Agendado` (ver a divergência de `run_type` na seção 2.4.1).
- Badge destructive `⚠ Possivelmente Travado` quando `isJobStuck(run)`.

**Ações à direita**:

| Botão | Condição | Ícone |
|---|---|---|
| `Ver Erros` | `failed_records > 0` | `Eye` (ghost sm) — abre o `JobErrorsDialog` |
| `Retomar` | `isJobStuck(run)` | `PlayCircle` (default sm) — `resumeJob.mutate(run.id)`, **sem confirmação** |
| `Marcar Falho` | `isJobStuck(run)` | `XCircle` (outline sm) — `markJobFailed.mutate(run.id)`, **sem confirmação** |
| data/hora | sempre | `formatDateTime(started_at)` ou `Aguardando...` |

> Note: aqui "Retomar" e "Marcar Falho" **não pedem confirmação**, enquanto na `ETLPage` (aba Pipelines) "Marcar como falha" pede. Dois caminhos, comportamentos diferentes.

**Detalhamento por Entidade** (só se `entity_stats` existe) — caixa `bg-muted/50 rounded-md`, título `Detalhamento por Entidade`, tabela:

| Entidade | Criados (verde) | Atualizados (azul) | Ignorados (amarelo) | Removidos (laranja) |
|---|---|---|---|---|
| Contatos | ✓ | ✓ | ✓ | `-` |
| Contratos | ✓ | ✓ | ✓ | `-` |
| Títulos | ✓ | ✓ | ✓ | `removed ?? -` |

> **Lacuna**: `supplies` e `supply_titles` **não são renderizados** aqui, embora existam no tipo `entity_stats`. Um pipeline de suprimento mostra a caixa de detalhamento **vazia**.

**Grade de métricas** (`grid-cols-5`):

| Rótulo | Valor |
|---|---|
| Processados | `{processed_records} / {total_records}` |
| Criados | verde |
| Atualizados | azul |
| Removidos | `entity_stats?.titles?.removed ?? "-"` (laranja) |
| Falhas | vermelho |

**Duração**: `Duração: {formatDuration(started_at, completed_at)}` (só se ambos existem). Formato: `Xh Ym` / `Xm Ys` / `Xs`.

**Bloco de erros inline** (só se `run.errors?.length > 0`): caixa `bg-destructive/10`, título `Erros (N):`, lista das **3 primeiras** (`Linha {row}: {error}`), e `... e mais {N-3} erros`. Área com `max-h-20 overflow-y-auto`.

**Vazio**: ícone `Clock` 48×48 opacity-50 + `Nenhuma execução registrada`.

### 12.2 `JobErrorsDialog`

`src/components/etl/JobErrorsDialog.tsx`. Aberto de dentro do `PipelineHistoryDialog` (aninhamento de dialogs).

**Casca**: `DialogContent flex flex-col p-0 w-[90vw] max-w-4xl h-[80vh]` — menor que os demais.
Header com gradiente **destructive** (`from-destructive/5`), título `⚠ Erros do Job`, descrição `sr-only`.

**Barra de resumo** (`px-6 py-3 border-b bg-muted/30`):
```
3 erros totais | 2 pendentes                  [⟳ Retentar Todos]  [⏭ Ignorar Todos]
```
Os dois botões só aparecem se `pendingCount > 0`.

**Lista de erros** (dentro de `ScrollArea`), uma caixa por erro:

```
┌─ border rounded-lg, hover:border-destructive/30 ────────────────────┐
│ [Linha 42] [⚠ Pendente] [2 tentativas]            [⟳] [⏭]  [▼/▲]   │
│ Campo "due_date" com formato inválido                               │
│ Campo: due_date                                                     │
├─ (expandido) ───────────────────────────────────────────────────────┤
│ 🗎 Dados Originais                                                   │
│ { "id_titulo": "778899", ... }        (pre, mono, max-h-48)         │
└─────────────────────────────────────────────────────────────────────┘
```

Badges de `retry_status`:

| Status | Badge | Ícone |
|---|---|---|
| (retentando) | `Retentando...` primary | `Loader2` girando |
| `pending` | `Pendente` warning | `AlertTriangle` |
| `success` | `Sucesso` success | `CheckCircle2` |
| `failed` | `Falhou` destructive | `XCircle` |
| `skipped` | `Ignorado` muted | `SkipForward` |

Botões por linha (só quando `retry_status === "pending" && retry_count < 5`):
- `⟳` — `title="Retentar"`, chama a API de retry com `errorIds: [id]`;
- `⏭` — `title="Ignorar"`, marca `retry_status = "skipped"`.
Ambos com `stopPropagation` (o clique no corpo expande/recolhe).

Cabeçalho do erro inteiro é clicável (`cursor-pointer hover:bg-muted/50`) e alterna a expansão. **Não tem `role="button"` nem `aria-expanded`.**

**Estados**: carregando → `Loader2` 32×32; vazio → `CheckCircle2` 48×48 opacity-50 + `Nenhum erro registrado para este job`.

### 12.3 Hooks de erro (`src/hooks/etl/useJobErrors.ts`)

| Hook | O que faz |
|---|---|
| `useJobErrors(jobRunId)` | `select * from etl_job_errors where job_run_id = ? order by row_number asc` |
| `usePendingErrorsCount(jobRunId)` | count exato de `retry_status = 'pending'` — **não usado na UI atual** |
| `useUpdateJobError()` | update de `retry_status` de um erro |
| `useSkipAllErrors()` | update em massa de `pending → skipped`; toast `Erros ignorados` / `Todos os erros pendentes foram marcados como ignorados.` |
| `useRetryErrors()` | `POST {SUPABASE_URL}/functions/v1/api/etl/retry-errors` com headers `x-org-slug` e `x-api-key: <JWT>`; body `{job_run_id, error_ids?}`. Toast `Retry concluído` / `{success} sucesso, {failed} falha(s)` (destrutivo se houve falha); erro → `Erro ao retentar` |
| `useMarkJobFailed()` | update `etl_job_runs` para `failed` + `completed_at`, **só se ainda estiver `running`** |
| `isJobStuck(job)` | true se status ∈ {running, pending} e o heartbeat (ou `started_at`) é anterior a 10 minutos atrás |

> `useRetryErrors` envia o **JWT do usuário no header `x-api-key`** (comentário no código: `// Using JWT as API key for now`). É um contrato provisório.

### 12.4 `PipelineDetailDialog`

`src/components/etl/PipelineDetailDialog.tsx`. Acionado por "Visualizar"/"Detalhes".

Casca: `w-[95vw] h-[95vh]`, título `⇄ Detalhes do Pipeline`, descrição `sr-only`.

Quatro cards empilhados:

**1. Informações básicas**
```
{nome}                          [Ativo/Inativo]  [🧪 Testar]  [▶ Executar]
{descrição}
🗄 Fonte: {nome da fonte ou N/A}       🕐 Agendamento: {cron traduzido ou "Manual"}
```
Os dois botões chamam `useRunPipeline` **direto**, sem passar pelos handlers da `ETLPage` — ou seja, **sem `window.confirm`**. O `Testar` tem `title="Processar apenas as primeiras 100 linhas para validar mapeamentos"`.

**2. Deduplicação**
```
Estratégia: {label}          Campo Chave: {dedup_field ou N/A}
```

**3. Mapeamento de Campos** — tabela `Campo Origem | Tabela Destino | Campo Destino`. Decodifica `"entidade:campo"`; se não houver `:`, assume `pipeline.target_entity`. Vazio: `Nenhum mapeamento configurado`.

> **Limitação**: a decodificação usa `(targetField as string).indexOf(":")`. Quando o valor é um **array** (mapeamento 1:N), o `String()` implícito junta com vírgula e a linha fica corrompida na exibição. O `validatePipelineMappings` já trata arrays; este dialog **não**.

**4. Histórico de Execuções** — tabela `Status | Início | Fim | Processados | Criados | Atualizados | Falhas` com as 20 últimas execuções (`useJobRuns`). Vazio: `Nenhuma execução registrada`.

Este dialog e o `PipelineHistoryDialog` mostram **o mesmo histórico** com granularidade diferente: aqui é uma tabela achatada; lá são cards com `entity_stats` e ações de recuperação.

---

## 13. Onboarding assistido de fonte (DataSourceOnboardingChat) e visualizador de skill (DataSourceSkillViewer)

### 13.1 Status: **código órfão**

Nenhum dos dois é importado por qualquer componente vivo. A varredura por `DataSourceOnboardingChat|DataSourceSkillViewer` em `src/` retorna apenas:
- as próprias definições;
- menções na documentação interna `src/components/fonte-de-dados-docs/sections/S1Holistica.tsx`, que os classifica explicitamente como **"Código órfão (DataSourceOnboardingChat, DataSourceSkillViewer, useDataSourceSkills, comboboxes duplicados)"**.

O hook `useDataSourceSkills.ts` é um **stub declarado**: o próprio arquivo diz `// Data Source Skills - Stub module / TODO: Implement full data source skills functionality`. Todas as queries têm `enabled: false` e retornam `[]`/`null`; todas as mutations fazem `throw new Error("Not implemented")`.

Ou seja: **a funcionalidade não existe em produção**. O que segue descreve o que os componentes fariam se fossem religados — útil para decidir se o redesenho deve ressuscitar, remover ou repensar a ideia.

### 13.2 `DataSourceOnboardingChat` (o que o componente faz)

`src/components/etl/DataSourceOnboardingChat.tsx`.

**Props**: `dataSourceId`, `dataSourceName`, `detectedFields[]`, `previewData[]`, `onSkillGenerated?`.

**Layout**: caixa `border rounded-lg bg-background` colapsável:
```
┌ header clicável ─────────────────────────────────────┐
│ 🗄 Onboarding Maestro   [Skill existente]      [▲/▼] │
├──────────────────────────────────────────────────────┤
│ ScrollArea h-[300px] — bolhas de mensagem             │
│   [🤖] mensagem do assistente (bg-muted, esquerda)    │
│   mensagem do usuário (bg-primary, direita)  [👤]     │
│   ⟳ Analisando...                                     │
├──────────────────────────────────────────────────────┤
│ Perguntas sugeridas:  [chip] [chip] [chip] [chip]     │
├──────────────────────────────────────────────────────┤
│ [Textarea: "Faca uma pergunta sobre os dados..."] [▶] │
│ [🗎 Gerar Documento de Referencia ✨]                 │
└──────────────────────────────────────────────────────┘
```

**Mensagem de boas-vindas** (gerada no mount):
- com skill existente: `Bem-vindo de volta! Ja temos um documento de referencia para "{nome}". Posso ajudar a atualiza-lo ou responder perguntas sobre esta fonte de dados.`
- sem skill: `Ola! Vou ajudar a documentar a fonte "{nome}". Detectei {N} campos. Posso fazer algumas perguntas para entender melhor os dados?`

**Perguntas sugeridas** (`generateSuggestedQuestions`, máximo 4, heurística por nome/tipo de campo):
- campo com "status" → `O que significa cada valor de "{campo}"?`
- campo de data (tipo `date`, nome com `date` ou `_at`) → `O campo "{campo}" indica qual data?`
- campo de valor (`value`/`amount`/`price`) → `Qual a moeda/formato do campo "{campo}"?`
- campos `_id`/`id_` → `Quais campos sao chaves de relacionamento com outras tabelas?`
- sempre: `Quais campos indicam inadimplencia?` e `Ha regras de negocio especificas para esta fonte?`

Os chips só aparecem enquanto `messages.length <= 2`.

**Integração**: chama a EF `ai-orchestrator` (`invokeEdgeFunctionFetch`) com `action: "create_session"` (modo `plan`, `context_type: "data_onboarding"`) e depois `action: "send_message"`. O contexto enviado inclui `data_source_id`, nome, campos detectados (com até 3 amostras cada), 5 linhas de `sample_data` e a skill existente.

Enter envia (Shift+Enter quebra linha). Erro vira `Alert destructive` com o texto cru.

**Botão "Gerar/Atualizar Documento de Referência"** (aparece após 2 mensagens) envia um prompt fixo pedindo a geração da skill.

### 13.3 `DataSourceSkillViewer` (o que o componente faz)

`src/components/etl/DataSourceSkillViewer.tsx`. Renderiza um `DataSourceSkill` como card:

```
🗎 {title}                                              [✏] [🗑]
   Versao {version} • Gerado por Maestro/Manual
───────────────────────────────────────────────────────────────
{overview}  (bg-muted/50 p-3 rounded-lg)

▸ 🗄 Campos Importantes [N]
     | Campo | Tipo | Descricao |
     (tipo com badge colorido; abaixo da descrição: "Ex: a, b, c"
      e "Mapear para: X" em text-cyan-600)

▸ 📖 Regras de Negocio [N]
     ⓘ {rule} / {description}

▸ 🌿 Mapeamentos Sugeridos [N]
     | Origem | → | Destino | Transformacao |

Observacoes                                            [✏ Editar]
{user_notes ou "Nenhuma observacao adicionada."}
```

Três seções `Collapsible` (`fields` aberta por padrão; `rules` e `mappings` fechadas). Edição inline das observações (Textarea + Cancelar/Salvar).

Exclusão usa `AlertDialog` (o **único** lugar do domínio ETL com confirmação acessível em vez de `window.confirm`): título `Excluir documento?`, corpo `Esta acao nao pode ser desfeita. O documento de referencia sera permanentemente removido.`, ações `Cancelar` / `Excluir` (destructive).

Vazio: `AlertCircle` 32×32 + `Este documento ainda nao tem informacoes detalhadas.` + `Use o chat de onboarding para documentar esta fonte.`

Badge de tipo de campo com paleta própria (10 mapeamentos: `string` verde, `number`/`integer` azul, `boolean` roxo, `date`/`datetime`/`timestamp` laranja, `array` rosa, `object`/`record` amarelo, default cinza) — **diferente** das paletas de `FieldTypeBadge` do `DataPreviewTable` e do `MetadataCard`.

### 13.4 Outros órfãos do domínio

| Arquivo | Situação |
|---|---|
| `src/components/etl/FieldCombobox.tsx` | Duplicata do combobox do wizard, sem uso. Não tem grupos, nem "criar customizado" |
| `src/components/etl/TargetFieldCombobox.tsx` | Lista **própria** de campos de destino (`STANDARD_FIELDS`), divergente de `TARGET_TABLES` — inclui `product_name`, `product_type`, `segment` em contracts, que **não existem** na constante viva. Sem uso |
| `src/hooks/etl/useDataSourceSkills.ts` | Stub, tudo desabilitado |

Três comboboxes coexistem no repositório (dois órfãos + o vivo). Qualquer redesenho deve remover os órfãos antes, para não replicar inconsistências.

---

## 14. Modais do domínio (um bloco completo por modal)

### 14.1 `DataSourceWizard`

| Aspecto | Descrição |
|---|---|
| **Objetivo** | Cadastrar ou editar uma fonte de dados em 3 etapas, terminando com a validação visual dos dados |
| **Gatilho** | Botão `+ Nova Fonte de Dados` (barra de ações da aba `sources`); botão `Nova Fonte` do estado vazio; item `Editar` do menu de uma fonte; `dataSourcesTabRef.openCreateModal()` |
| **Tamanho** | `w-[95vw] h-[95vh]`, conteúdo centrado em `max-w-3xl` |
| **Layout** | Header (gradiente) · Stepper (faixa `bg-muted/30`) · Corpo rolável (com overlay de loading) · Rodapé (`bg-muted/30`) |
| **Campos** | Passo 1: nome*, descrição, tipo* · Passo 2: varia por tipo (ver 5.4.2 a 5.4.7) + card de verificação de pagamento · Passo 3: leitura |
| **Botões** | `Voltar` · `Continuar` · Passo 3 criação: `Criar sem Pipeline` (outline) + `Criar e Configurar Pipeline` (primary) · Passo 3 edição: `Salvar Alterações` |
| **Confirmações** | Nenhuma. Fechar descarta tudo sem avisar |
| **Estados** | `isUploading` (spinner na dropzone) · `isLoadingPreview` (overlay full) · `isFetchingBigQuery`/`isFetchingRestApi` (travam o rodapé) · `isTestingConnection` (botão de teste) · `isSubmitting` (`Salvando...`) · `bigQueryError`/`restApiError` (alerts no passo 2) · `connectionTestResult` (alert no form BQ) |
| **Pós-ação** | `onComplete(dataSourceId)` → a `ETLPage` invalida `["data-sources"]` e fecha |
| **Reset** | `resetWizard()` no fechar: volta ao passo 1, tipo `csv`, tudo limpo |

### 14.2 `PipelineWizard`

| Aspecto | Descrição |
|---|---|
| **Objetivo** | Criar ou editar um pipeline: mapeamento, normalização e agendamento |
| **Gatilho** | Botão `+ Novo Pipeline`; botão do estado vazio; item `Editar` do menu; encadeado a partir do `DataSourceWizard` (`Criar e Configurar Pipeline`) |
| **Tamanho** | `w-[95vw] h-[95vh]`, conteúdo em `max-w-4xl` |
| **Passos** | 3 (encadeado) ou 4 (standalone, com seleção de fonte na frente) |
| **Campos** | Ver seções 7.3 a 7.6 |
| **Botões** | `Voltar` · `Continuar` · `Criar Pipeline` / `Salvar Alterações` |
| **Confirmações** | Nenhuma — inclusive trocar a família **poda mapeamentos sem avisar** |
| **Estados** | `isLoadingFields`/`isRefreshingFields` (passo da fonte) · `loadFieldsError` (caixa destructive) · `isLoadingStandardValues` (bloqueia o passo 2 inteiro) · `isRefreshingUniqueValues` (banner âmbar) · `isSubmitting` |
| **Pós-ação** | `onComplete()` → a `ETLPage` invalida `["etl-pipelines"]` e fecha. Encadeado: fecha também o wizard de fonte |
| **Modal filho** | `CustomFieldModal`, renderizado **fora** do `Dialog` (comentário: "to avoid portal conflicts") |

### 14.3 `CustomFieldModal`

| Aspecto | Descrição |
|---|---|
| **Objetivo** | Criar ou editar um campo personalizado (nome, tipo, opções, entidade) |
| **Gatilho** | Botão `+ Novo Campo` (aba); item `Editar` da tabela de campos; `+ Criar campo personalizado` dentro de qualquer `FieldCombobox` do wizard |
| **Tamanho** | `w-[95vw] h-[95vh]` — **desproporcional ao conteúdo** |
| **Campos** | `Entidade *` (condicional), `Nome de Exibicao *`, `Nome Interno` (derivado, travado ao editar), `Tipo do Campo *`, `Opcoes da Lista *` (se `select`) |
| **Botões** | `Cancelar` (outline) · `Criar Campo` / `Salvar` |
| **Validação** | `canSave`: nome de exibição e nome interno preenchidos, sem duplicata, e ao menos 1 opção quando o tipo é `select` |
| **Confirmações** | Nenhuma |
| **Estados** | Erro de duplicata (borda destructive + mensagem inline). Não há estado de "salvando" — o botão não vira spinner |
| **Pós-ação** | Aba: `create`/`update` + fecha. Wizard: persiste via upsert, adiciona à lista local e preenche a linha de mapeamento |

### 14.4 `CustomValueModal`

| Aspecto | Descrição |
|---|---|
| **Objetivo** | Adicionar um valor-padrão customizado (com aliases) para um campo de normalização, válido **só neste pipeline** |
| **Gatilho** | Botão `+ Novo Valor` dentro de um card de campo do passo de Normalização |
| **Tamanho** | `sm:max-w-md` — o **único modal pequeno** do domínio |
| **Campos** | `Valor Interno *`, `Nome de Exibição *`, `Aliases` (lista via Enter ou botão `+`) |
| **Botões** | `Cancelar` (outline) · `Adicionar Valor` / `Salvar Alterações` |
| **Validação** | Valor interno obrigatório e com caracteres permitidos; nome de exibição obrigatório. Erros inline em `text-xs text-destructive` |
| **Confirmações** | Nenhuma |
| **Estados** | Campos com erro ganham `border-destructive`. Botão `+` de alias desabilitado quando o input está vazio |
| **Pós-ação** | Grava em `transformRules.custom_standard_values[targetField]` (substitui se o `value` já existir) e limpa o formulário |

### 14.5 `PipelineDetailDialog`

| Aspecto | Descrição |
|---|---|
| **Objetivo** | Ver a configuração completa de um pipeline e seu histórico, sem entrar no wizard |
| **Gatilho** | Item `Visualizar` (lista) / `Detalhes` (card) |
| **Tamanho** | `w-[95vw] h-[95vh] overflow-hidden` |
| **Layout** | 4 cards empilhados: básico (com ações) · deduplicação · mapeamento · histórico |
| **Botões** | `🧪 Testar` e `▶ Executar` no card de cabeçalho — **executam sem confirmação** |
| **Estados** | `isLoading` (spinner 32×32) · `runsLoading` (spinner 24×24 na tabela de runs) · `runPipeline.isPending` (ambos os botões viram spinner) |
| **Fechamento** | `onOpenChange` → `onClose()`; controlado por `open={!!pipeline}` |

### 14.6 `PipelineHistoryDialog`

| Aspecto | Descrição |
|---|---|
| **Objetivo** | Analisar o desempenho das importações e recuperar jobs travados |
| **Gatilho** | Item `Ver Histórico` / `Ver histórico` |
| **Tamanho** | `w-[95vw] h-[95vh] overflow-hidden` |
| **Layout** | Header · 4 cards de estatística · Separator · lista rolável de execuções |
| **Botões** | Por execução: `Ver Erros` (se há falhas), `Retomar` e `Marcar Falho` (se travado) |
| **Confirmações** | **Nenhuma**, nem para Retomar nem para Marcar Falho |
| **Estados** | Badges por status; badge `Possivelmente Travado`; spinners nos botões de mutation; vazio com ícone `Clock` |
| **Modal filho** | `JobErrorsDialog`, renderizado **dentro** do `DialogContent` do histórico |

### 14.7 `JobErrorsDialog`

| Aspecto | Descrição |
|---|---|
| **Objetivo** | Listar as linhas que falharam numa execução, ver os dados originais e decidir entre retentar ou ignorar |
| **Gatilho** | Botão `Ver Erros` de uma execução com `failed_records > 0` |
| **Tamanho** | `w-[90vw] max-w-4xl h-[80vh]` |
| **Layout** | Header destructive · barra de resumo com ações em massa · `ScrollArea` com as linhas |
| **Botões** | Massa: `Retentar Todos`, `Ignorar Todos` · Por linha: `⟳` (retentar), `⏭` (ignorar), chevron (expandir) |
| **Confirmações** | Nenhuma — `Ignorar Todos` marca tudo como `skipped` num clique |
| **Estados** | `isLoading` · `retryingIds` (badge `Retentando...` + spinner por linha) · `retryErrors.isPending`/`skipAll.isPending` (desabilitam os botões de massa) · vazio |
| **Limite** | Retentar só é oferecido enquanto `retry_count < 5` |

### 14.8 `RunDetailDialog` (Materialização)

Componente interno da `MaterializationTab` (linhas 376-620).

| Aspecto | Descrição |
|---|---|
| **Objetivo** | Investigar uma execução de refresh da MV, sucesso ou falha |
| **Gatilho** | Clique (ou Enter/Espaço) numa linha da tabela de histórico |
| **Tamanho** | `max-h-[85vh] w-full max-w-2xl`, `flex-col gap-0 p-0` |
| **Scroll** | Header e footer `shrink-0`; corpo é um `<div>` plano `min-h-0 flex-1 overflow-y-auto` (o comentário explica: `ScrollArea` do Radix não respeita a altura do pai flex) |

Conteúdo:

**Header**: título `☑ Detalhe da execucao`; descrição = `RunResultPill` (`✓ Sucesso` verde / `✗ Falha` destructive) + `TriggerPill` (`⚡ Forcado` âmbar / `⟳ Automatico`).

**1. Banner de resumo** — caixa colorida por resultado com a frase de `buildRunSummary`:
- sucesso: `Refresh {manual|automatico} concluido com sucesso — 24.003 linhas materializadas em 1.8 s (+3 linhas vs. refresh anterior).`
- variação zero: `... (0 linhas alteradas vs. refresh anterior — contagem identica (datas/atraso podem ter envelhecido mesmo assim)).`
- primeira medição: `... (primeira medicao (sem comparacao)).`
- falha: `Refresh {modo} FALHOU apos {duração}. Veja a mensagem de erro abaixo.`

**2. Métricas** (`Metricas`, grade `sm:grid-cols-2` de cartões `FieldRow`):

| Cartão | Ícone | Valor | Hint |
|---|---|---|---|
| Status | `CheckCircle2`/`XCircle` | `Sucesso`/`Falha` | `refresh concluido` / `refresh nao concluido` (com acento de cor na borda) |
| Gatilho | `Zap`/`RefreshCw` | `Forcado`/`Automatico` | explicação por `trigger_source` (ver abaixo) |
| Inicio | `Clock` | `dd/MM/yyyy HH:mm:ss BRT` | tempo relativo |
| Duracao | `Timer` | formatada | `{N} ms` |
| Linhas processadas | `Rows3` | número pt-BR | `linhas na MV apos o refresh` |
| Variacao | `Activity` | `DeltaBadge` (↑ verde `+N` / ↓ destructive) | `0 — ja estava atualizada (sem dado novo do pipeline), nao e erro` ou `diferenca vs. o refresh anterior; 0 = sem mudanca de contagem` |
| Throughput | `Gauge` | `≈ {N} linhas/s` | `derivado de linhas / duracao` — só em sucesso com duração > 0 |
| Organizacao | `Database` | `org_{slug}` em mono | `schema da org` |

`triggerExplanation`:
| `trigger_source` | Texto |
|---|---|
| `scheduled` | `automatico — disparado pelo agendamento (cron) configurado` |
| `supervisor` | `automatico (modelo antigo: supervisor por intervalo)` |
| `manual` | `manual — 'Atualizar agora' / force (request_mv_refresh_now)` |
| outro | `valor cru: {x}` ou `origem desconhecida` |

`triggerLabel`: `manual`→`Forcado`; `supervisor`/`scheduled`/`cron`→`Automatico`; `etl`→`ETL`; vazio→`—`.

**3. Linha de log** — `Linha de log` + botão `Copiar log`, e um `<pre>` (`max-h-40`, mono, quebra em qualquer caractere):
```
2026-06-18 00:54:00 BRT | org_blips | trigger=manual | status=success | rows=24003 | Δrows=3 | 1840ms | id=<uuid>
```
O timestamp é calculado por aritmética UTC (`fmtBrtLogTimestamp`), independente do fuso do navegador — diferente do `fmtDateTime` do resto da tela, que usa `date-fns` com o fuso local.

**4. Mensagem / Erro** — `<pre>` rolável (`max-h-56`); em falha, com borda e fundo destructive. Sem mensagem: caixa tracejada `Sem mensagem registrada.`

**5. ID do log** — `<code>` truncado + botão `Copiar ID`.

**Ajuda** (caixa `bg-muted/30`, ícone `Info`):
> Esta execucao roda via *pg_cron* no banco (nao e Edge Function), entao nao ha execucao de funcao linkavel. Para investigar mais, filtre os Postgres logs pela hora acima (BRT) ou pelo id, ou rode o SQL abaixo.

**Rodapé**:
- `Copiar SQL` → copia `SELECT * FROM public.mv_refresh_log WHERE id = '<uuid>';`
- `Abrir Postgres logs no Supabase` (`ExternalLink`, `target="_blank" rel="noopener noreferrer"`) — **só aparece** se a URL do Supabase casar `^([a-z0-9]+)\.supabase\.co$`. Link: `https://supabase.com/dashboard/project/{ref}/logs/postgres-logs`.

**`CopyButton`**: ícone alterna `Copy` → `Check` por 1500ms, dispara toast (`SQL copiado para a area de transferencia.` / `Linha de log copiada.` / `ID copiado.`); em falha, toast destrutivo `Nao foi possivel copiar` / `Copie manualmente o valor exibido.`

---

## 15. Estados da tela (loading, vazio, erro, execução em andamento, pausado, sem permissão)

### 15.1 Loading

| Contexto | Padrão |
|---|---|
| Aba Fontes / Pipelines | `GridCardSkeleton count=6 columns=3` |
| Aba Campos Personalizados | `Loader2` 32×32 centrado (`py-12`) — **padrão diferente** |
| Aba Materialização (inicial) | Skeleton estrutural: `h-16` + dois `h-80` |
| Materialização · KPIs | 4 `Skeleton h-[58px]` |
| Materialização · Histórico | 6 `Skeleton h-10` |
| Wizard de fonte · transição 2→3 | Overlay full com `Loader2` + duas linhas de texto |
| Wizard de pipeline · lista de fontes | 3 cards `animate-pulse` |
| Wizard de pipeline · valores-padrão | Bloco centrado com `Loader2` 48×48 (bloqueia o passo inteiro) |
| Detalhe de pipeline | `Loader2` 32×32 |
| Erros de job | `Loader2` 32×32 |

**Cinco padrões distintos de loading** convivem na mesma tela.

### 15.2 Vazio

| Contexto | Componente | Ação oferecida |
|---|---|---|
| Fontes | `EmptyState` (`Database`) | `+ Nova Fonte` (sem gate de permissão) |
| Pipelines | `EmptyState` (`ArrowRightLeft`) | `+ Novo Pipeline` (com gate) |
| Campos Personalizados | Card manual (`Settings2`) | `+ Novo Campo` (sem gate) |
| Materialização · histórico | Caixa tracejada (`Database`) | `⟳ Atualizar agora` (com gate) |
| Wizard · lista de fontes | Texto + `Database` opacity-50 | nenhuma |
| Wizard · normalização | Texto + `RefreshCw` | nenhuma (instrui a avançar) |
| Wizard · entidade sem mapeamento | Texto inline | nenhuma |
| Erros de job | `CheckCircle2` opacity-50 | nenhuma |
| Histórico de pipeline | `Clock` opacity-50 | nenhuma |
| Preview sem colunas | Caixa tracejada h-40 | nenhuma |

Todos os vazios diferenciam "sem dados" de "busca sem resultado" trocando a descrição — exceto os de dentro dos wizards.

### 15.3 Erro

| Contexto | Padrão | Recuperação |
|---|---|---|
| Status da MV | `Alert destructive` no lugar da faixa | `Tentar de novo` |
| Settings da MV | `Alert destructive` dentro do card | `Tentar de novo` |
| Histórico da MV | `Alert destructive` | texto `Tente atualizar novamente.` (sem botão) |
| BigQuery no wizard | `Alert destructive` abaixo do form | corrigir e tentar de novo |
| REST API no wizard | `Alert destructive` | idem |
| Teste de conexão BQ | `Alert` no bloco de teste | idem |
| Carga de campos (pipeline) | caixa `bg-destructive/10` | botão `Atualizar Campos` |
| Mutations de lista | **toast** destrutivo | — |
| Salvar fonte/pipeline | **nada** (só `logError`) | — |

Falta crítica: erro ao salvar nos dois wizards é invisível.

### 15.4 Execução em andamento

Sinais na tela:
- Card do pipeline: borda esquerda azul, chip `Rodando…`, botão `Rodar agora` desabilitado com spinner.
- `PipelineExecutionStatus`: barra de progresso + fase + `{N} registros` + botão `Cancelar`.
- Polling de 2s enquanto houver job `running`/`pending`.
- Materialização: badge `Rodando` (azul), `Atualizar agora` desabilitado, polling de 5s.
- Materialização com force pendente: badge `Solicitada — roda em ate 1 min`.

### 15.5 Pausado

| Objeto | Sinais |
|---|---|
| Pipeline | badge `Pausado`/`Inativo`, borda esquerda amarela, fundo `bg-muted/20`, cron seguido de ` (pausado)`, "Próximo" **some** |
| Materialização | faixa amarela, badge `⏸ Pausado`, título `Atualizacao pausada`, `Atualizar agora` desabilitado com tooltip explicativo, `describeNextRefresh` → `pausada` |
| Campo personalizado | badge `Inativo` (sem ação para reativar) |

### 15.6 Sem permissão

`canWrite = hasPermission("etl:write")`.

| Elemento | Respeita `canWrite`? |
|---|---|
| Botão `+` da barra de ações | ✅ |
| Ações de escrita do menu de **pipeline** | ✅ |
| Botões `Rodar agora` / pausa no card | ✅ |
| `+ Novo Pipeline` do estado vazio | ✅ |
| Pausar/Retomar e Atualizar agora da MV | ✅ |
| `Salvar agendamento` da MV | ✅ |
| `Atualizar agora` do histórico vazio da MV | ✅ |
| Ações `Editar`/`Excluir` de **fonte de dados** | ❌ |
| Botão `+ Nova Fonte` do estado vazio | ❌ |
| Ações `Editar`/`Excluir` de **campo personalizado** | ❌ |
| Botão `+ Novo Campo` do estado vazio | ❌ |
| `Testar`/`Executar` do `PipelineDetailDialog` | ❌ |
| `Retomar`/`Marcar Falho` do `PipelineHistoryDialog` | ❌ |
| Botões do `JobErrorsDialog` | ❌ |

Um usuário `etl:read` consegue **excluir uma fonte de dados e todos os pipelines dela** pela UI. O backend (RLS) pode barrar; a UI não.
⚠️ A confirmar: se a RLS bloqueia essas operações em produção.

### 15.7 Sem organização

Só a `MaterializationTab` trata explicitamente (`Nenhuma organizacao selecionada.`). As outras abas dependem de `enabled: !!orgClient` nos hooks — ficam em loading indefinido.

---

## 16. Fluxos de uso passo a passo

### 16.1 Conectar uma fonte CSV do zero e importar

1. `/etl` → aba **Fontes de Dados** → `+ Nova Fonte de Dados`.
2. **Passo 1**: digita o nome (obrigatório), descrição opcional, mantém o tipo `CSV Upload` (default).
3. `Continuar`.
4. **Passo 2**: clica na dropzone, escolhe o `.csv`. O Papa Parse roda no navegador; o card passa a mostrar o nome do arquivo e `Arquivo carregado com sucesso`.
5. (Opcional) preenche a URL base de verificação de pagamento e marca os campos; a URL Final é montada sozinha.
6. `Continuar`.
7. **Passo 3**: confere `Colunas` e `Registros` no cartão de metadados e as 10 primeiras linhas na tabela.
8. Clica em **`Criar e Configurar Pipeline`**.
9. A fonte é criada; os dados sobem para `etl-uploads/{org}/{id}/{ts}.csv`; o `PipelineWizard` abre encadeado (3 passos).
10. **Mapeamento**: escolhe a família (`Contrato` por padrão); o wizard já criou as linhas obrigatórias e tentou auto-detectar. Se sobrou obrigatório vazio, o banner de sugestões oferece `Aplicar`.
11. Preenche as origens faltantes pelos comboboxes ou clicando nos chips de "Campos disponíveis".
12. Confere a Deduplicação (default `Atualizar` em todas).
13. `Continuar` (só habilita com nome e todos os mapeamentos completos).
14. **Normalização**: se há `status`/`modality`/`payment_method` mapeados, aplica as sugestões (`Aplicar Todas`) e marca os campos de lista.
15. `Continuar`.
16. **Agendamento**: escolhe `Manual` (ou um horário), mantém `Pipeline Ativo`, decide `Pular Reconciliacao`.
17. `Criar Pipeline` → os dois wizards fecham.
18. Aba **Pipelines**: menu `⋮` → `Testar (100 linhas)` → confirma.
19. Acompanha a barra de progresso no card; ao terminar, abre `Ver Histórico` e confere `entity_stats`.
20. Se OK, `Rodar agora` (execução completa).

### 16.2 Conectar uma fonte BigQuery

1. Passo 1: nome + tipo **BigQuery**.
2. Passo 2 · autenticação: `Service Account (JSON)` → sobe o `.json`. Se o arquivo for o de OAuth Client, o erro aparece **na hora**, com a instrução de onde baixar o correto.
3. Preenche `Project ID` (obrigatório). Ou informa `Dataset ID` + `Table ID`, ou escreve a `Query SQL`.
4. `Testar Conexão` → aguarda `Conexão estabelecida com sucesso!`.
5. `Continuar` → overlay `Carregando dados da fonte...`. O wizard injeta `LIMIT 100` se a query não tiver, roda a query e, em seguida, roda N/5 consultas `DISTINCT` para levantar valores únicos (pode levar vários segundos).
6. Passo 3: confere colunas e linhas. Em edição, pode usar `Re-executar query`.
7. Segue igual ao fluxo CSV a partir do passo 8.

### 16.3 Mudar o mapeamento de um pipeline existente

1. Aba Pipelines → `⋮` → `Editar`.
2. O wizard abre em modo edição (4 passos, navegação livre pelo stepper).
3. O passo da fonte já vem com ela selecionada; os campos vêm do **cache** (`query_config.fields`). Se a estrutura mudou, usa `Atualizar Campos` (força busca sem cache).
4. Pula direto para **Mapeamento** clicando no stepper.
5. Ajusta as linhas; adiciona novas pelo combobox ou pelos chips.
6. Pula para **Agendamento** (ou passa pela Normalização, que pode auto-disparar o refresh de valores únicos).
7. `Salvar Alterações`.
8. Volta à aba e usa `Testar (100 linhas)` antes de rodar completo.

### 16.4 Investigar uma execução que falhou

1. Aba Pipelines: o card está com borda vermelha e chip `Falhou · há 2h`.
2. `⋮` → `Ver Histórico`.
3. Nos cards do topo, olha `Taxa de Sucesso`.
4. Na execução com falha, lê `Detalhamento por Entidade` e a grade de métricas (`Falhas: 37`).
5. Se há erros inline, lê os 3 primeiros.
6. Clica em `Ver Erros` → `JobErrorsDialog`.
7. Expande uma linha para ver os `Dados Originais` (JSON cru).
8. Decide: `⟳` retentar a linha, `⏭` ignorar, ou `Retentar Todos` / `Ignorar Todos`.
9. Fecha e reabre o histórico para ver o resultado (o retry invalida `["etl-job-runs"]`).

### 16.5 Destravar um job preso

1. O card mostra chip âmbar `Possivelmente travado` (sem heartbeat há >10 min).
2. No próprio card/linha, o `PipelineExecutionStatus` mostra `N/M registros` e dois botões.
3. `Retomar` → reseta o job para `pending`, limpa a fase e re-invoca a EF `execute-etl` (sem reprocessar o que já entrou).
4. Se não resolver, `Marcar Falho` → grava `failed` + `completed_at` (só se ainda estiver `running`).
5. Os mesmos dois botões existem no `PipelineHistoryDialog`, mas lá **sem confirmação**.

### 16.6 Ajustar o agendamento da materialização

1. Aba **Materializacao**.
2. Lê a faixa: cor, `Atualizado há Xh`, `proxima: em 17 minutos`, badges.
3. No card **Agendamento**, escolhe o modo:
   - **A cada intervalo**: define `A cada 30 min`, `das 06h às 18h`, dias `Todos os dias`; adiciona um horário extra `00:30` para envelhecer `days_overdue`.
   - **Horários**: lista `05:30`, `13:00`, `19:00`, modo `Todos os dias`.
4. Confere o preview (uma linha traduzida por expressão) e os avisos:
   - se falta run diário garantido, o aviso `MoonStar` aparece;
   - se algum horário coincide com um pipeline, o aviso âmbar nomeia o pipeline.
5. (Opcional) abre `Ver horarios dos pipelines de ETL` para escolher um horário logo **depois** das janelas de ETL.
6. `Salvar agendamento` → toast com a descrição do novo schedule.
7. Se a org estava pausada, clica em **`Retomar`** na faixa (salvar o cron **não** ativa).
8. Para efeito imediato, `Atualizar agora` → badge `Solicitada — roda em ate 1 min`; a tela atualiza sozinha (polling 5s).

### 16.7 Criar um campo personalizado e usá-lo

1. Aba **Campos Personalizados** → `+ Novo Campo`.
2. Escolhe a `Entidade` (ex.: Títulos), digita `Nome de Exibicao` (`Instituição`); o `Nome Interno` vira `instituicao` sozinho.
3. Escolhe o `Tipo do Campo`. Se `Lista de Opcoes`, adiciona as opções uma a uma.
4. `Criar Campo`.
5. Vai para Pipelines → `Editar` o pipeline → passo **Mapeamento**.
6. No combobox de destino da entidade Títulos, o campo aparece no grupo **Campos Personalizados** com ícone `Puzzle`.
7. Aponta a coluna de origem e salva.
8. A partir da próxima execução, o valor cai em `titles.custom_fields.instituicao` e o campo passa a aparecer em filtros/colunas (via `useMappedFilterFields`).

Atalho: o mesmo modal pode ser aberto **de dentro do wizard** (`+ Criar campo personalizado` no combobox), e nesse caminho a checagem de duplicata está ativa.

---

## 17. Responsividade e acessibilidade

### 17.1 Breakpoints usados

| Contexto | Classe | Efeito |
|---|---|---|
| Grades de cards (fontes, pipelines, fontes no wizard) | `md:grid-cols-2 lg:grid-cols-3` | 1 → 2 → 3 colunas |
| Grade de tipos de fonte (passo 1) | `grid-cols-2 md:grid-cols-3` | 2 → 3 colunas |
| Nome + descrição do pipeline | `grid-cols-1 md:grid-cols-2` | empilha |
| Materialização (grade principal) | `lg:grid-cols-2` | empilha abaixo de `lg` |
| Materialização · faixa de status | `flex-col md:flex-row` | estado acima, ações abaixo |
| Métricas do `RunDetailDialog` | `grid-cols-1 sm:grid-cols-2` | — |
| Stepper (título/descrição) | `hidden sm:block` | **some abaixo de 640px** |
| Botão `Aplicar` da normalização | `hidden sm:inline` no texto | vira só ícone |
| Badge `Mapeado` da normalização | `hidden sm:inline` no texto | vira só ícone |

### 17.2 Pontos frágeis de responsividade

1. **Modais `w-[95vw] h-[95vh]`** — em telas pequenas ocupam quase tudo, mas o conteúdo interno tem larguras fixas que não acompanham.
2. **Grade de mapeamento `grid-cols-[1fr_auto_1fr_auto]`** — não tem variante mobile. Em telas estreitas, dois comboboxes de largura 1fr + seta + lixeira ficam apertados demais para uso real.
3. **Grade de deduplicação `grid-cols-[120px_1fr_1fr]`** — idem, sem breakpoint.
4. **Grade de normalização `grid-cols-[1fr_auto_1fr_auto]`** — idem.
5. **Estatísticas do histórico `grid-cols-4`** e detalhamento `grid-cols-5` — **sem breakpoint nenhum**; em mobile viram 4-5 colunas espremidas.
6. **`DataPreviewTable` com colunas de 160px fixos** — uma fonte com 40 colunas gera `minWidth: 6400px` e scroll horizontal longo, sem congelar a primeira coluna.
7. **`PopoverContent` do FieldCombobox com `w-[300px]` fixo** — pode extravasar em telas muito estreitas.
8. **Card informativo do agendamento com cores azuis hardcoded** — quebra no tema escuro.
9. **Stepper sem rótulos abaixo de `sm`** — em mobile o usuário vê só "1 2 3" sem saber o que são.

### 17.3 Acessibilidade — o que existe

| Padrão | Onde |
|---|---|
| `aria-current="step"` | `WizardStepper` (passo ativo) |
| `aria-expanded` | `FieldCombobox`, `TargetFieldCombobox` (trigger do popover) |
| `role="combobox"` | os mesmos triggers |
| `aria-label` + `aria-busy` | `RefreshButton` |
| `aria-label` | selects do `CronIntervalField` e do `MvScheduleField`, botões de página do histórico, botões de pausa do card de pipeline |
| `aria-pressed` | chips de dia e de modo de dia do `CronIntervalField` |
| `aria-current="page"` | botão da página atual no histórico da MV |
| `role="status" aria-live="polite"` | `EmptyState` |
| `role="button" tabIndex={0}` + Enter/Espaço | linha da tabela de histórico da MV (e `aria-label` descritivo completo) |
| `sr-only` em `DialogDescription` | `PipelineDetailDialog`, `PipelineHistoryDialog`, `JobErrorsDialog` |
| `title` como tooltip | vários botões-ícone |
| `htmlFor`/`id` | nome e descrição (ambos os wizards), campos do `CustomFieldModal`, itens do RadioGroup de agendamento |

### 17.4 Acessibilidade — lacunas

1. **Cards de seleção de tipo de fonte** (passo 1) e **cards de fonte** (passo 0 do pipeline) são `<Card onClick>` sem `role`, `tabIndex` ou `aria-pressed`. **Não são navegáveis por teclado.**
2. **Chips de "Campos disponíveis"** no `EntityMappingGroup` são `<Badge onClick>` — mesmo problema.
3. **Linhas de "Campos de Lista"** na normalização são `<div onClick>` sem `role="checkbox"`/`aria-checked`.
4. **Cabeçalho de erro** no `JobErrorsDialog` é `<div onClick>` sem `aria-expanded`.
5. **`window.confirm`** para todas as confirmações destrutivas — não é estilizável, não segue o tema, e o texto não pode ter estrutura.
6. **Falta de `aria-invalid`** e de associação `aria-describedby` entre campos e mensagens de erro (ex.: nome interno duplicado no `CustomFieldModal`).
7. **Botões desabilitados sem explicação acessível** — o `Continuar` dos wizards não diz por que está travado (não há `aria-describedby` nem texto visível).
8. **Emoji `📅` como rótulo de badge de tipo** no `DataPreviewTable` — sem `aria-label`; um leitor de tela anuncia o emoji.
9. **Cores como único indicador** em várias métricas (criados/atualizados/falhas no histórico são diferenciados só pela cor do número, com rótulos acima — aceitável, mas o `DeltaBadge` depende de seta + cor).
10. **Nenhum `aria-live`** nos estados de execução em andamento — a barra de progresso muda sem anúncio.
11. **Foco não é gerenciado** ao abrir/fechar os wizards multi-passo: mudar de passo não move o foco para o novo conteúdo.
12. **Modais aninhados** (`JobErrorsDialog` dentro de `PipelineHistoryDialog`) criam duas armadilhas de foco sobrepostas.

### 17.5 Tema escuro

A maior parte da tela usa tokens (`bg-card`, `text-muted-foreground`, `border-border`) ou pares explícitos (`text-green-700 dark:text-green-400`). Exceções encontradas:

| Lugar | Problema |
|---|---|
| Card informativo do `ScheduleStep` | `bg-blue-50/50 border-blue-100 text-blue-900/700/600` sem `dark:` |
| Badges do `AdvancedSettingsCard` | `bg-emerald-50 text-emerald-700 border-emerald-200` e `bg-amber-50 ...` sem `dark:` |
| `ENTITY_COLORS` do `EntityMappingGroup` | `bg-blue-100`, `bg-green-100`, `bg-amber-100`, `bg-purple-100` sem `dark:` |
| Badges de status do `PipelineHistoryDialog` | `bg-green-50`, `bg-red-50`, `bg-blue-50`, `bg-yellow-50`, `bg-gray-50` sem `dark:` |
| `FieldTypeBadge` (`DataPreviewTable`) e `TypeBadge` (`MetadataCard`) | `bg-*-500/10 text-*-600` sem `dark:` |
| `DataSourceSkillViewer` (órfão) | `bg-green-100 text-green-700` etc. |

---

## 18. Dores e oportunidades para o redesign

Cada item é uma observação factual do código, com a consequência para o usuário.

### 18.1 Dores de informação

| # | Dor | Evidência |
|---|---|---|
| 1 | A aba Fontes mostra a **descrição do tipo**, não a do usuário. A descrição escrita no wizard nunca aparece | `DataSourcesTab.tsx` linhas 155, 241 |
| 2 | A aba Fontes não mostra `last_sync_at`, `last_sync_status`, `is_active` nem quantos pipelines usam a fonte | campos existem em `DataSource`, nenhum é renderizado |
| 3 | O histórico da MV só tem 3 colunas; gatilho e variação ficam escondidos no modal | comentário explícito em `MaterializationTab.tsx` linha 255 |
| 4 | `entity_stats` de `supplies`/`supply_titles` **não é renderizado** no histórico de pipeline | `PipelineHistoryDialog.tsx` linhas 290-336 |
| 5 | Pipeline não mostra a família (equipamento × suprimento) nem `skip_reconciliation` em lugar nenhum da lista | `PipelineCard.tsx`, `PipelinesTab.tsx` |
| 6 | Os KPIs da MV são 4, mas o guia de negócio do próprio produto descreve 5 (incl. "Sucesso 24h") | `MvKpiCards.tsx` × `negocio/data/fonte-de-dados.ts` |
| 7 | Não há indicação de quantos erros pendentes existem sem abrir dois modais | `usePendingErrorsCount` existe e não é usado |

### 18.2 Dores de fluxo

| # | Dor | Evidência |
|---|---|---|
| 8 | Erro ao salvar fonte ou pipeline é **silencioso** (só `logError`) | `DataSourceWizard/index.tsx` linha 1157; `usePipelineWizard.ts` linha 1162 |
| 9 | `Continuar` desabilitado sem dizer o motivo | `canProceed()` nos dois wizards |
| 10 | Linhas de campo obrigatório nascem vazias e **travam o avanço**, sem poder ser removidas | `initializeRequiredMappings` + `canProceed` do passo 1 |
| 11 | Trocar a família **apaga mapeamentos** sem confirmação | `handleFamilyChange` (`usePipelineWizard.ts` linha 425) |
| 12 | Fechar qualquer wizard descarta tudo sem confirmação | `handleClose` → `resetWizard()` |
| 13 | Fechar o PipelineWizard encadeado fecha também o wizard de fonte, sem volta | `handlePipelineWizardClose` |
| 14 | `Testar`/`Executar` do `PipelineDetailDialog` disparam **sem confirmação**, ao contrário da lista | `PipelineDetailDialog.tsx` linhas 50-58 |
| 15 | `Retomar`/`Marcar Falho` do `PipelineHistoryDialog` também não confirmam | linhas 235, 253 |
| 16 | Salvar o cron da MV **não ativa** a materialização — precisa clicar "Retomar" depois | `handleSaveCron` envia `enabled: settings.enabled` |
| 17 | O refresh de valores únicos **auto-dispara** ao entrar na Normalização, com banner que aparece e some sozinho | `useEffect` em `contentStep` (linha 1006) |
| 18 | A transição 2→3 do BigQuery pode levar muitos segundos (N/5 chamadas sequenciais) com overlay genérico, sem progresso | `executeBigQueryQuery`, lotes de 5 |
| 19 | PostgreSQL e MySQL **não conseguem concluir o wizard** (sem preview, `detectedFields` vazio trava o passo 3) | `loadSourceFields` não trata esses tipos; `canProceed` do passo 3 |

### 18.3 Bugs e divergências observáveis

| # | Problema | Evidência |
|---|---|---|
| 20 | Modo `multiple_daily` permite minutos diferentes por horário, mas o cron gerado usa **só o minuto do primeiro** | `generateCronExpression` (`shared/utils.ts` linha 325) |
| 21 | Execução de teste (`run_type: "test"`) aparece como **"Agendado"** no histórico | `useJobRuns.ts` linha 147 × `PipelineHistoryDialog.tsx` linha 205 |
| 22 | "Próxima execução" é calculada no **fuso do navegador**, mas o cron roda em BRT | `getNextExecutionDate` × card informativo |
| 23 | `translateCronExpression` **não traduz** o cron do modo intervalo (`0,30 6-18 * * *`) — cai no fallback `Executa às 6-18h no minuto 0,30` | `expandHours` retorna null com `-` |
| 24 | `PipelineDetailDialog` corrompe a exibição de mapeamentos 1:N (valor array) | `indexOf(":")` sobre `String(array)` |
| 25 | `CustomFieldModal` aberto pela aba **não recebe `existingFields`** → checagem de duplicata desativada justamente onde ela mais importa | `CustomFieldsTab.tsx` linhas 164-171, 274-281 |
| 26 | Combobox marca opções já usadas como `disabled` mas **permite selecioná-las** (só `opacity-50`) | `FieldCombobox.tsx` — `CommandItem` sem guarda |
| 27 | A busca do combobox filtra pelo **label**, não pelo nome técnico | `value={option.label}` |
| 28 | `MvKpiCards` exibe `icon` do `HealthTheme` que nunca é renderizado (código morto do `MvStatusHero`) | `mv-health.tsx` |
| 29 | `MetadataCard` suporta `fields`, `fileName`, `sourceType` e `warnings`, mas o `PreviewStep` não passa nenhum — metade do componente é morta | `PreviewStep.tsx` linhas 32-35 |
| 30 | `LargeDatasetInfo` é renderizado com `> 1000` mas retorna `null` abaixo de 5000 — limiar duplo | `PreviewStep.tsx` linha 38 × `MetadataCard.tsx` linha 192 |
| 31 | Campos de Lista mostram **no máximo 10** sem avisar que há mais | `NormalizationStep.tsx` linha 913 |
| 32 | Campos de Lista gravam `targetField` mas detectam/contam por `sourceField` | `toggleListField` × `listFields` |
| 33 | `supplies`/`supply_titles` não estão em `DB_FIELD_TYPE_MAP` → caem no fallback de valores-padrão de título | `NormalizationStep.tsx` linhas 50-53 |
| 34 | `useFieldExplorer` (Dicionário de Dados) só cobre 3 entidades — campos de suprimento somem | `useFieldExplorer.ts` linha 22 |
| 35 | O card de deduplicação mostra `contacts`/`supply_titles` crus com `capitalize`, e não os labels PT | `MappingStep.tsx` linha 706 |
| 36 | Banner de auto-fix mostra a entidade crua (`contacts`) em vez do label | `MappingStep.tsx` linha 511 |
| 37 | A UI de payment check oferece 8 variáveis; o contrato documentado tem 11 | `PAYMENT_CHECK_FIELDS` × `CLAUDE.md` regra 7 |

### 18.4 Dores de permissão e segurança de UI

| # | Problema |
|---|---|
| 38 | Fonte de dados e campos personalizados **não gateiam** Editar/Excluir por `canWrite` — um `etl:read` pode apagar uma fonte e toda a cascata |
| 39 | O texto de confirmação de exclusão de fonte diz que pipelines "serão afetados"; na prática são **excluídos**, junto com todo o histórico |
| 40 | A exclusão em cascata roda **no cliente**, em sequência, sem transação — uma falha no meio deixa o estado inconsistente |
| 41 | `useRetryErrors` envia o JWT do usuário no header `x-api-key` (marcado como provisório no código) |

### 18.5 Dores de consistência visual

| # | Problema |
|---|---|
| 42 | Cinco padrões de loading diferentes na mesma tela |
| 43 | Dois padrões de confirmação (`window.confirm` × `AlertDialog` só no órfão) |
| 44 | Três paletas distintas de badge de tipo de campo (`DataPreviewTable`, `MetadataCard`, `DataSourceSkillViewer`) |
| 45 | Quatro parsers de cron e dois geradores no mesmo domínio |
| 46 | Acentuação inconsistente: `Materializacao`, `Descricao`, `Numero`, `Sim/Nao` × `Descrição`, `Número`, `Sim/Não` |
| 47 | Descrições de tipo de fonte metade em inglês, metade em português |
| 48 | Modais de conteúdo pequeno usando `95vw × 95vh` (`CustomFieldModal` com 4 campos) |
| 49 | Cores hardcoded sem variante escura em 6 lugares |
| 50 | `ViewToggle` fica **dentro** do conteúdo da aba, não na barra de ações — some quando a lista está vazia |

### 18.6 Oportunidades estruturais

| # | Oportunidade | Justificativa no código |
|---|---|---|
| A | Unificar `PipelineDetailDialog` e `PipelineHistoryDialog` — hoje mostram o mesmo histórico com granularidades diferentes | ambos usam `useJobRuns(pipeline.id)` |
| B | Remover os 4 arquivos órfãos (`DataSourceOnboardingChat`, `DataSourceSkillViewer`, `FieldCombobox` raiz, `TargetFieldCombobox`) e o stub `useDataSourceSkills` | já identificados como órfãos pela própria documentação interna do app |
| C | Trazer o "gatilho" e a "variação" para a tabela do histórico da MV (o espaço existe em telas largas) | os componentes `TriggerPill`/`DeltaBadge` já estão prontos e só são usados no modal |
| D | Dar à fonte de dados um estado de saúde equivalente ao do pipeline (`last_sync_status` já existe no dado) | `DataSource.last_sync_*` |
| E | Unificar o editor de horários: o `ScheduleStep` (pipeline) oferece minutos 0/15/30/45; o `MvScheduleField` (MV) oferece de 5 em 5; os dois compartilham o `CronIntervalField` mas divergem no resto | `ScheduleStep.tsx` linha 226 × `MvScheduleField.tsx` linha 64 |
| F | Suportar multi-cron também no pipeline (o backend do ETL já casa cron por linha? ⚠️ A confirmar) — hoje só a MV tem multi-cron | `schedule_cron` do pipeline é string única |
| G | Expor a família e as entidades-alvo do pipeline na listagem, já que o comportamento de reconciliação depende disso | `target_entity`, `FAMILY_ENTITIES` |
| H | Consolidar a confirmação destrutiva num componente único com `AlertDialog` | 7 `window.confirm` espalhados |
| I | Persistir o progresso do wizard (rascunho) — hoje fechar perde tudo, e os wizards têm 3-4 passos longos | `resetWizard()` |
| J | Mostrar, no modal do campo personalizado, onde o campo já é usado (pipelines, filtros) antes de permitir excluir | `useMappedFilterFields` já cruza essa informação |

---

## 19. Inventário de modais do domínio

| # | Modal | Arquivo | Tamanho | Gatilho | Modal pai | Confirma? |
|---|---|---|---|---|---|---|
| 1 | `DataSourceWizard` | `components/etl/wizards/DataSourceWizard/index.tsx` | `95vw × 95vh` | `+ Nova Fonte de Dados`; `Editar` de fonte; `Nova Fonte` do estado vazio | — | não |
| 2 | `PipelineWizard` | `components/etl/wizards/PipelineWizard/index.tsx` | `95vw × 95vh` | `+ Novo Pipeline`; `Editar` de pipeline; encadeado pelo #1 | (encadeado ao #1) | não |
| 3 | `CustomFieldModal` | `components/etl/CustomFieldModal.tsx` | `95vw × 95vh` | `+ Novo Campo`; `Editar` de campo; `+ Criar campo personalizado` nos comboboxes | renderizado **fora** do #2 | não |
| 4 | `CustomValueModal` | `.../PipelineWizard/components/CustomValueModal.tsx` | `sm:max-w-md` | `+ Novo Valor` no passo de Normalização | dentro do #2 | não |
| 5 | `PipelineDetailDialog` | `components/etl/PipelineDetailDialog.tsx` | `95vw × 95vh` | `Visualizar` / `Detalhes` | — | não (executa direto) |
| 6 | `PipelineHistoryDialog` | `components/etl/PipelineHistoryDialog.tsx` | `95vw × 95vh` | `Ver Histórico` | — | não |
| 7 | `JobErrorsDialog` | `components/etl/JobErrorsDialog.tsx` | `90vw × 80vh`, `max-w-4xl` | `Ver Erros` numa execução com falhas | dentro do #6 | não |
| 8 | `RunDetailDialog` | interno em `tabs/MaterializationTab.tsx` | `max-w-2xl`, `max-h-85vh` | clique/Enter numa linha do histórico da MV | — | n/a (só leitura) |
| 9 | `AlertDialog` de exclusão de skill | `components/etl/DataSourceSkillViewer.tsx` | padrão shadcn | ícone 🗑 no card de skill | **órfão** | sim |

### 19.1 Popovers e overlays não-modais

| Componente | Onde | Conteúdo |
|---|---|---|
| `FieldCombobox` (wizard) | `EntityMappingGroup`, todas as linhas de mapeamento | `Popover` `w-[300px] z-[100]` com `Command` (busca + grupos + criar customizado) |
| `DropdownMenu` `⋮` | fontes, pipelines, campos personalizados | itens de ação, `align="end"` |
| `Tooltip` | cards de pipeline, faixa da MV, KPIs, histórico | datas absolutas, explicações de estado |
| `HelpTip` ⓘ | faixa da MV | explicação do modelo de materialização |
| `Collapsible` | `EntityMappingGroup`, cards de normalização, "horários de ETL", seções da skill (órfã) | conteúdo expansível |
| Overlay de loading | corpo do `DataSourceWizard` | `absolute inset-0 bg-background/80 backdrop-blur-sm` |

### 19.2 Diálogos nativos do navegador (`window.confirm`)

| # | Origem | Texto |
|---|---|---|
| 1 | `DataSourcesTab.handleDelete` | `Tem certeza que deseja excluir esta fonte de dados? Pipelines associados tambem serao afetados.` |
| 2 | `PipelinesTab.handleDelete` | `Tem certeza que deseja excluir este pipeline?` |
| 3 | `ETLPage.handleRunPipeline` (normal) | `Executar o pipeline "{nome}"?` |
| 4 | `ETLPage.handleRunPipeline` (teste) | `Testar o pipeline "{nome}" com as primeiras 100 linhas?` |
| 5 | `ETLPage.handleCancelPipeline` | `Tem certeza que deseja cancelar esta execucao?` |
| 6 | `ETLPage.handleMarkPipelineFailed` | `Marcar esta execucao como falha?` |
| 7 | `CustomFieldsTab.handleDelete` | `Tem certeza que deseja excluir o campo "{nome}"? Esta ação não pode ser desfeita.` |

### 19.3 Toasts do domínio

| Origem | Título | Variante |
|---|---|---|
| `handleTogglePause` | `Agendamento retomado` / `Agendamento pausado` | default |
| `handleTogglePause` (erro) | `Erro ao alterar o agendamento` | destructive |
| `useRunPipeline` | `Teste Iniciado` / `Pipeline Iniciado` | default |
| `useRunPipeline` (erro) | `Erro ao Iniciar Pipeline` | destructive |
| `useCancelJob` | `Job Cancelado` | default |
| `useCancelJob` (erro) | `Erro ao Cancelar` | destructive |
| `useResumeJob` | `Job Retomado` | default |
| `useResumeJob` (erro) | `Erro ao Retomar` | destructive |
| `useMarkJobFailed` | `Job marcado como falho` | default |
| `useMarkJobFailed` (erro) | `Erro ao marcar job` | destructive |
| `useSkipAllErrors` | `Erros ignorados` | default |
| `useRetryErrors` | `Retry concluído` | default ou destructive (se houve falha) |
| `useRetryErrors` (erro) | `Erro ao retentar` | destructive |
| `useDeleteDataSource` / `useDeletePipeline` / `useDeleteCustomFieldDefinition` (erro) | `Erro ao excluir` | destructive |
| `handleSaveCron` | `Agendamento salvo` / `Agendamento removido` | default |
| `handleSaveCron` (erro) | `Erro ao salvar o agendamento` | destructive |
| `handleToggleEnabled` | `Materializacao retomada` / `Materializacao pausada` | default |
| `handleToggleEnabled` (erro) | `Erro ao alterar o estado` | destructive |
| `handleForceNow` | `Atualizacao agendada` | default |
| `handleForceNow` (erro) | `Erro ao agendar execucao` | destructive |
| `CopyButton` | `SQL copiado...` / `Linha de log copiada.` / `ID copiado.` | default |
| `CopyButton` (erro) | `Nao foi possivel copiar` | destructive |

**Sem toast**: salvar fonte de dados, salvar pipeline, criar/editar campo personalizado, criar valor customizado.

---

## Apêndice A · Mapa de arquivos do domínio

| Arquivo | Linhas | Papel |
|---|---|---|
| `src/pages/ETLPage.tsx` | 465 | Orquestrador: abas, busca, handlers, montagem dos dialogs |
| `src/components/etl/tabs/DataSourcesTab.tsx` | 255 | Lista/grade de fontes |
| `src/components/etl/tabs/PipelinesTab.tsx` | 288 | Lista/grade de pipelines |
| `src/components/etl/tabs/MaterializationTab.tsx` | 1368 | Aba Materialização completa + `RunDetailDialog` |
| `src/components/etl/tabs/MvScheduleField.tsx` | 467 | Editor multi-cron (2 modos) |
| `src/components/etl/tabs/MvStatusBar.tsx` | 283 | Faixa de status (puro, sem estado) |
| `src/components/etl/tabs/MvKpiCards.tsx` | 198 | 4 KPIs compactos |
| `src/components/etl/tabs/mv-health.tsx` | 130 | Frescor + tema de saúde |
| `src/components/etl/tabs/materialization-helpers.ts` | 568 | Helpers puros: formatação, resumo, cron, slots |
| `src/components/etl/PipelineCard.tsx` | 580 | Card de pipeline (saúde, KPIs, ações) |
| `src/components/etl/PipelineExecutionStatus.tsx` | 307 | Status ao vivo + barra de progresso estimada |
| `src/components/etl/PipelineDetailDialog.tsx` | 307 | Modal de detalhes |
| `src/components/etl/PipelineHistoryDialog.tsx` | 412 | Modal de histórico + estatísticas |
| `src/components/etl/JobErrorsDialog.tsx` | 300 | Modal de erros de linha |
| `src/components/etl/CustomFieldsTab.tsx` | 285 | Aba de campos personalizados |
| `src/components/etl/CustomFieldModal.tsx` | 326 | Modal de campo |
| `src/components/etl/shared/CronIntervalField.tsx` | 281 | Editor de cadência (compartilhado ETL+MV) |
| `src/components/etl/shared/cron-interval.ts` | 304 | Núcleo puro do modo intervalo |
| `src/components/etl/wizards/DataSourceWizard/index.tsx` | 1377 | Wizard de fonte |
| `.../DataSourceWizard/types.ts` | 168 | Tipos + `flattenObject` + `detectFieldType` |
| `.../DataSourceWizard/steps/TypeSelectionStep.tsx` | 104 | Passo 1 |
| `.../DataSourceWizard/steps/ConfigurationStep.tsx` | 1081 | Passo 2 (todos os tipos + payment check) |
| `.../DataSourceWizard/steps/PreviewStep.tsx` | 61 | Passo 3 |
| `src/components/etl/wizards/PipelineWizard/index.tsx` | 169 | Casca do wizard de pipeline |
| `.../PipelineWizard/types.ts` | 146 | Tipos, famílias, obrigatórios, dedup |
| `.../PipelineWizard/hooks/usePipelineWizard.ts` | 1264 | Toda a lógica do wizard |
| `.../PipelineWizard/steps/DataSourceSelectionStep.tsx` | 237 | Passo 0 (standalone) |
| `.../PipelineWizard/steps/MappingStep.tsx` | 750 | Passo de mapeamento |
| `.../PipelineWizard/steps/NormalizationStep.tsx` | 963 | Passo de normalização |
| `.../PipelineWizard/steps/ScheduleStep.tsx` | 552 | Passo de agendamento |
| `.../PipelineWizard/components/EntityMappingGroup.tsx` | 412 | Card por entidade |
| `.../PipelineWizard/components/FieldCombobox.tsx` | 223 | Combobox vivo |
| `.../PipelineWizard/components/CustomValueModal.tsx` | 219 | Modal de valor customizado |
| `.../PipelineWizard/utils/field-auto-detection.ts` | 399 | Aliases + autodetecção + auto-fix |
| `src/components/etl/wizards/shared/WizardStepper.tsx` | 324 | Stepper + navegação |
| `.../shared/DataPreviewTable.tsx` | 234 | Tabela virtualizada de preview |
| `.../shared/MetadataCard.tsx` | 215 | Cartão de metadados + large dataset |
| `.../shared/utils.ts` | 394 | flatten, detect, cron (parse/generate/next) |
| `.../shared/types.ts` | 231 | Tipos compartilhados + `ENTITY_LABELS` |
| `src/hooks/etl/constants.ts` | 313 | `DATA_SOURCE_TYPES`, `TARGET_TABLES`, `DEDUP_STRATEGIES`, `LOOKUP_FIELDS`, `STANDARD_FIELD_LABELS` |
| `src/hooks/etl/types.ts` | 226 | Todos os tipos do domínio |
| `src/hooks/etl/useDataSources.ts` | 196 | CRUD de fontes (com cascata no delete) |
| `src/hooks/etl/usePipelines.ts` | 219 | CRUD de pipelines |
| `src/hooks/etl/useJobRuns.ts` | 419 | Runs, cancel, run, resume, validação, upload |
| `src/hooks/etl/useJobErrors.ts` | 267 | Erros, retry, skip, `isJobStuck` |
| `src/hooks/etl/useCustomFields.ts` | 425 | CRUD + `useMappedFilterFields` + `useCustomFieldOptions` |
| `src/hooks/useMvRefresh.ts` | 298 | 5 hooks da Materialização + `isValidScheduleCron` |
| `src/lib/cron-translator.ts` | 243 | Tradução de cron para pt-BR |
| `src/lib/etl/bigquery-credentials.ts` | 133 | Validação de forma do JSON de Service Account |

**Órfãos** (sem uso): `src/components/etl/DataSourceOnboardingChat.tsx` (502), `src/components/etl/DataSourceSkillViewer.tsx` (444), `src/components/etl/FieldCombobox.tsx` (121), `src/components/etl/TargetFieldCombobox.tsx` (275), `src/hooks/etl/useDataSourceSkills.ts` (103, stub).

---

## Apêndice B · Glossário de rótulos exatos da UI

Lista de todo texto visível do domínio, para que o redesenho possa preservá-los ou decidir conscientemente mudá-los.

**Página**: `Fonte de Dados` · `Gerencie fontes de dados, pipelines de importacao e campos personalizados`

**Abas**: `Fontes de Dados` · `Pipelines` · `Campos Personalizados` · `Carteiras` · `Materializacao`

**Botões de criação**: `Nova Fonte de Dados` · `Novo Pipeline` · `Novo Campo` · `Nova Carteira` · `Novo` · `Nova Fonte`

**Placeholders de busca**: `Buscar fontes de dados...` · `Buscar pipelines...` · `Buscar campos personalizados...` · `Buscar carteiras...` · `Buscar...`

**Colunas (fontes)**: `Nome` · `Tipo` · `Descricao` · `Criado em`
**Colunas (pipelines)**: `Nome` · `Fonte` · `Status` · `Mapeamentos` · `Ultima Execucao`
**Colunas (campos)**: `Nome de Exibição` · `Nome Interno` · `Tipo` · `Opções` · `Status`
**Colunas (histórico MV)**: `Quando` · `Linhas` · `Duracao`
**Colunas (histórico pipeline, detalhe)**: `Status` · `Início` · `Fim` · `Processados` · `Criados` · `Atualizados` · `Falhas`
**Colunas (mapeamento, detalhe)**: `Campo Origem` · `Tabela Destino` · `Campo Destino`

**Ações de menu**: `Editar` · `Excluir` · `Visualizar` · `Detalhes` · `Ver Historico` · `Ver histórico` · `Testar (100 linhas)` · `Executar` · `Pausar agendamento` · `Retomar agendamento`

**Status de pipeline**: `Ativo` · `Pausado` · `Inativo` · `Rodando…` · `Possivelmente travado` · `Concluido` · `Falhou` · `Cancelado` · `Nunca executado` · `Executando` · `Concluído` · `Pendente`

**Fases de execução**: `Buscando dados...` · `Pre-carregando...` · `Processando...` · `Finalizando...` · `Iniciando...`

**Wizard de fonte**: `Nova Fonte de Dados` / `Editar Fonte de Dados` · `Configure sua fonte de dados em 3 etapas simples` · `Tipo` / `Escolha a fonte` · `Configuração` / `Configure a conexão` · `Preview` / `Valide os dados` · `Criar sem Pipeline` · `Criar e Configurar Pipeline` · `Salvar Alterações` · `Re-executar query` · `Carregando dados da fonte...` · `Executando consulta e processando preview`

**Wizard de pipeline**: `Novo Pipeline de Importação` / `Editar Pipeline` · `Configure o mapeamento de campos e agendamento de execução` · `Fonte de Dados` / `Selecione a fonte` · `Mapeamento` / `Configure os campos` · `Normalização` / `Padronize valores` · `Agendamento` / `Configure a execução` · `Criar Pipeline`

**Navegação**: `Voltar` · `Continuar` · `Finalizar` · `Salvar` · `Etapa {n} de {m}` · `Salvando...`

**Mapeamento**: `O que este pipeline importa?` · `Contrato` · `Suprimento` · `Mapeamento de Campos` · `Auto-detectar` · `{N} detectado(s)` · `Campo Destino` · `Campo Origem` · `Campos Vinculados Automaticamente` · `Adicionar mapeamento...` · `Campos disponíveis` · `— clique para adicionar:` · `Todos os campos da fonte já foram mapeados.` · `Configuração de Deduplicação` · `Campo chave...`

**Normalização**: `Normalização de Valores` · `Gerenciar Valores Padrão` · `Valor Original` · `Valor Padrão` · `Manter original` · `Aplicar` · `Mapeado` · `Sugestão: {x}` · `← Sugerido` · `Novo Valor` · `Gerenciar` · `Fechar` · `Valores Customizados` · `Prévia de Impacto` · `Normalizados` · `Sem mapeamento` · `Campos de Lista (Filtros)` · `Ativado` · `Desativado` · `Aplicar Todas` · `Buscar Todos`

**Agendamento (pipeline)**: `Pipeline Ativo` / `Pipeline Pausado` · `Pular Reconciliacao` · `Tipo de Agendamento` · `Manual` · `Diariamente` · `Dias da Semana` · `A cada intervalo` · `Múltiplas vezes ao dia` · `Configuração de Horário` · `Horario de Execucao` · `Primeiro Horario` · `Horarios Adicionais` · `Adicionar horario` · `Expressão CRON:` · `Próxima execução:` · `Sobre o agendamento`

**CronIntervalField**: `A cada` · `das (Brasília)` · `às` · `Início em :MM` · `Dias` · `Todos os dias` · `Dias úteis` · `Específicos` · `{N} execuções/dia` · `Nenhum dia marcado — selecione ao menos um.`

**Materialização**: `Agendamento` · `Em quais horarios a base e refrescada (horario de Brasilia).` · `Salvar agendamento` / `Remover agendamento` · `Historico` · `Clique numa execucao para ver detalhes.` · `Atualizar agora` · `Pausar` / `Retomar` · `Como funciona a materializacao` · `A cada intervalo` / `Horários` · `Horários extras (Brasília)` · `Adicionar horário extra` · `Ver horarios dos pipelines de ETL` · `Mostrando {a}–{b} de {n}` · `Janela das ate 200 execucoes mais recentes.` · `Detalhe da execucao` · `Metricas` · `Linha de log` · `ID do log` · `Copiar log` · `Copiar ID` · `Copiar SQL` · `Abrir Postgres logs no Supabase`

**KPIs da MV**: `Ultima duracao` · `Linhas na base` · `Tamanho da base` · `Sucesso` · `media {x}` · `sem sucesso recente` · `estimativa` · `materializada` · `{a}/{b} execucoes` · `sem execucoes`

**Saúde da MV**: `Atualizando agora…` · `Atualizado {idade}` · `Desatualizado {idade}` · `Atualizacao pausada` · `Sem registro de atualizacao` · `Pausado` · `Rodando` · `Solicitada — roda em ate 1 min` · `Sem agendamento` · `proxima: {x}`

**Erros de job**: `Erros do Job` · `{N} erros totais` · `{N} pendentes` · `Retentar Todos` · `Ignorar Todos` · `Retentando...` · `Pendente` · `Sucesso` · `Falhou` · `Ignorado` · `{N} tentativas` · `Linha {N}` · `Campo: {x}` · `Dados Originais` · `Nenhum erro registrado para este job`

**Histórico de pipeline**: `Histórico de Execuções: {nome}` · `Total Execuções` · `Taxa de Sucesso` · `Duração Média` · `Total Processado` · `Manual` / `Agendado` · `Possivelmente Travado` · `Ver Erros` · `Retomar` · `Marcar Falho` · `Detalhamento por Entidade` · `Entidade` · `Criados` · `Atualizados` · `Ignorados` · `Removidos` · `Processados` · `Falhas` · `Duração: {x}` · `Erros ({N}):` · `... e mais {N} erros` · `Nenhuma execução registrada`

