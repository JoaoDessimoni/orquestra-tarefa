# 20 · Telas de Integrações e Configurações

> **Propósito deste documento.** Inventário exaustivo, orientado a UX/produto, das duas telas de administração da Torre de Controle: **Integrações** (`/integrations`) e **Configurações** (`/settings`, multi-abas). Destina-se a um designer que vai **redesenhar** a interface sem perder nenhuma funcionalidade. Tudo aqui foi extraído da leitura do código-fonte em `cobranca-finza/src/`. Onde o código não permite concluir com segurança, há uma marcação `⚠️ A confirmar: ...`.
>
> **Escopo de leitura.** `src/pages/IntegrationsPage.tsx`, `src/components/integrations/*`, `src/lib/constants/integration-types.ts`, `src/lib/constants/integration-variables.ts`, `src/lib/curl-parser.ts`, `src/lib/webhook-url-validation.ts`, `src/hooks/useIntegrations.ts`, `src/hooks/useIntegrationTest.ts`, `src/hooks/useApiKeys.ts`, `src/pages/central-docs/negocio/data/integracoes.ts`, `src/pages/SettingsPage.tsx`, `src/components/settings/**`, `src/hooks/useSettings.ts` e hooks irmãos, `src/pages/central-docs/negocio/data/configuracoes.ts`.
>
> **Convenção de leitura.** "Card", "Sheet", "Dialog", "AlertDialog", "Tabs", "Switch", "Badge", "Table" são componentes do **shadcn/ui** (`src/components/ui/`). O redesign pode trocar a implementação, mas precisa preservar o **papel** de cada um, descrito aqui.

---

## PARTE A — INTEGRAÇÕES

---

## A0. Identidade

| Atributo | Valor |
|---|---|
| **Rota** | `/integrations` |
| **Componente raiz** | `IntegrationsPage` — `src/pages/IntegrationsPage.tsx` |
| **Título na tela** | "Integrações" (`h1`, `text-3xl font-bold`), precedido do ícone `Puzzle` (`h-8 w-8`) |
| **Subtítulo** | "Configure as integrações e chaves de API para seus workflows" (`text-muted-foreground`) |
| **Grupo no menu lateral** | Configuração (conforme `src/pages/central-docs/negocio/data/integracoes.ts`, campo `group: "Configuração"`) |
| **Ícone no menu** | `Puzzle` (lucide-react) |
| **Permissão de leitura** | Perfis `owner`, `admin`, `manager` (declarado em `integracoes.ts`, `permissions: ["owner","admin","manager"]`) |
| **Permissão de escrita** | `hasPermission("integrations:write")` → variável local `canEdit` |
| **Gate especial** | A aba "API Keys" só existe se `isSuperAdmin === true` (de `useOrganization()`) |
| **Contexto de dados** | `useOrganization()` → `currentOrg`, `hasPermission`, `isSuperAdmin` |
| **Estado global** | Sem organização selecionada → tela inteira substituída por estado vazio (ver A9) |

### A0.1 Árvore de componentes

```
IntegrationsPage                                   src/pages/IntegrationsPage.tsx
├── Header (h1 + subtítulo + ações)
│   ├── RefreshButton                              src/components/common/RefreshButton.tsx
│   └── Button "Nova Integração"                   (só se canEdit && mainTab === "integrations")
├── Tabs mainTab  ["integrations" | "api-keys"]
│   ├── TabsContent "integrations"
│   │   └── Tabs selectedType  ["all" | <10 tipos>]
│   │       └── TabsContent
│   │           ├── Loader (isLoading)
│   │           ├── grid de IntegrationCard        (função local no mesmo arquivo)
│   │           └── EmptyState
│   └── TabsContent "api-keys"  (só isSuperAdmin)
│       └── ApiKeysSection                         src/components/integrations/ApiKeysSection.tsx
│           ├── Dialog "Criar nova API Key"
│           ├── Table de chaves
│           ├── Bloco "Como usar"
│           └── AlertDialog "Remover API Key?"
└── IntegrationBuilderSheet                        src/components/integrations/IntegrationBuilderSheet.tsx
    ├── Tabs ["general" | "auth" | "test"]
    │   ├── general → campos + BodyEditor          src/components/integrations/BodyEditor.tsx
    │   │              └── InputWithVariables       src/components/integrations/InputWithVariables.tsx
    │   │              └── VariableHighlightTextarea src/components/integrations/VariableHighlightTextarea.tsx
    │   ├── auth    → campos de credencial
    │   └── test    → IntegrationTestPanel          src/components/integrations/IntegrationTestPanel.tsx
    └── ImportCurlModal                             src/components/integrations/ImportCurlModal.tsx
```

### A0.2 Componente órfão (não montado na tela)

`src/components/integrations/TestConnectionPanel.tsx` existe no domínio, mas **não é importado por `IntegrationBuilderSheet` nem por `IntegrationsPage`** — quem ocupa a aba "Testar" é `IntegrationTestPanel`. Ele é documentado na seção A6.2 porque representa uma capacidade real do código (teste HTTP cru, client-side) que o redesign pode querer resgatar ou descartar conscientemente.

⚠️ A confirmar: se `TestConnectionPanel` é consumido por alguma outra tela fora do escopo lido (não foi encontrada referência nos arquivos deste domínio).

---

## A1. Objetivo e personas

### A1.1 O que a tela resolve

A Torre decide **quem** cobrar, **quando** e **com que mensagem**. O disparo físico — entregar o WhatsApp, mandar o e-mail, registrar a negativação — é executado por **sistemas externos**. A tela de Integrações é onde cada um desses sistemas é cadastrado como uma "ponte" HTTP configurável.

Sem uma integração ativa do tipo correspondente, uma régua monta a ação mas **não tem para onde enviá-la**.

Metáfora oficial do produto (do guia embarcado, seção `visao-geral`, bloco `whatIs`): *"Pense numa integração como uma tomada: a Torre é o aparelho e o serviço externo é a energia. Aqui você cadastra cada tomada — o endereço para onde a ação vai, como o serviço espera receber os dados e como se autenticar — e testa se a corrente realmente passa antes de ligar tudo."*

### A1.2 Personas

| Persona | Papel na tela | O que precisa |
|---|---|---|
| **Admin de operação** (owner/admin) | Cadastra e mantém as pontes | Criar integração, colar cURL do provedor, ajustar body, testar com contato real, ativar |
| **Gestor de cobrança** (manager) | Consulta e pausa | Ver quais canais estão ativos; desligar rapidamente um canal problemático via Switch |
| **Leitor** (operator/viewer com `integrations:read`) | Só observa | Ver os cards e o estado (Ativo/Inativo) — **sem** botões Editar/Remover, **sem** Switch, **sem** "Nova Integração" |
| **Super Admin (time Finza)** | Emite credenciais de API | Aba "API Keys": criar chave universal, copiar o segredo uma única vez, revogar |

### A1.3 Momentos de uso

1. **Onboarding de organização nova** — tela vazia; o operador cria a primeira ponte (WhatsApp, normalmente).
2. **Troca de provedor** — editar a integração existente (URL, headers, credencial) sem mexer nas réguas.
3. **Incidente** — desligar o Switch de um canal que está falhando, sem perder a configuração.
4. **Diagnóstico** — aba "Testar": dispara contra um contato real e mostra payload enviado + resposta do provedor.
5. **Integração externa entrando** — Super Admin gera uma API Key para o ERP/sistema legado consumir a API da Torre.

---

## A2. Modelo mental: integração, tipo, canal, credencial/segredo, variável de integração

Cinco conceitos que o redesign precisa manter distintos na interface.

### A2.1 Integração

Registro pertencente à organização (schema `org_{slug}`), exposto pela Edge Function `api` em `/functions/v1/api/integrations`. Shape em `src/hooks/useIntegrations.ts` (`interface OrgIntegration`):

| Campo | Tipo | Papel na UI |
|---|---|---|
| `id` | `string` | Chave do card; usado para enable/disable/delete/teste |
| `name` | `string` | Título do card e campo "Nome da Integração" |
| `slug` | `string \| null` | Não exibido na UI de Integrações |
| `category` | `IntegrationType` | Determina ícone, cor do badge e em que passo de régua a integração aparece |
| `description` | `string \| null` | Exibido no corpo do card **apenas se preenchido** |
| `config` | `Record<string, unknown>` | JSON com `integrationType`, `name`, `description`, `url`, `method`, `headers`, `bodyTemplate`, `authType`, `externalActionUrl`, `has_encrypted_credentials` |
| `is_active` | `boolean` | Switch do card + badge Ativo/Inativo + borda destacada |
| `created_at` / `updated_at` | `string` | Não exibidos na tela de Integrações |

### A2.2 Tipo de integração

Enumeração fechada de **10 valores**, em `src/lib/constants/integration-types.ts` (`INTEGRATION_TYPES`). Cada entrada carrega `label`, `color` (classes Tailwind de fundo/texto), `description` e `icon` (nome textual). O mapa de **ícones efetivamente renderizados** vive em `IntegrationsPage.tsx` (`TYPE_ICONS`) e **diverge** do campo `icon` da constante em três casos — ver A8.1.

O tipo define:
- o ícone e a cor do badge no card;
- a aba de filtro em que o card aparece;
- para qual passo de régua aquela integração fica disponível (regra de negócio declarada no guia: *"Ao montar uma régua, cada passo procura uma integração ativa do tipo correspondente"*).

### A2.3 Canal

`CHANNEL_TYPES` (mesmo arquivo) lista os **10** tipos como canais de comunicação — ou seja, hoje **todos** os tipos são canais, e `isChannelType()` é sempre verdadeiro para qualquer valor do enum. Na tela, "tipo" e "canal" são a mesma coisa; a distinção só existe no código.

No painel de teste (`IntegrationTestPanel`), `channel = integration.category`, e o canal controla quais campos de override aparecem:

| Conjunto | Valores | Efeito na UI de teste |
|---|---|---|
| `PHONE_CHANNELS` | `whatsapp`, `sms`, `voice` | Mostra campo "Telefone" |
| `EMAIL_CHANNELS` | `email` | Mostra campos "Email" e "Assunto" |
| — | todos | Mostra sempre o campo "Conteudo" |
| — | `whatsapp` | Habilita o seletor de Template Meta |

### A2.4 Credencial / segredo

Credenciais **nunca voltam do banco para a UI**. Em `IntegrationBuilderSheet`, ao carregar uma integração existente: `credentials: {}` com o comentário explícito `// Credentials nunca voltam do banco`.

O que a UI sabe sobre a credencial de uma integração salva é apenas o booleano `config.has_encrypted_credentials`, renderizado como um **cadeado** (`Lock`, `h-3.5 w-3.5 text-primary`) ao lado do nome no card, com `title="Credenciais criptografadas"`.

Formato do objeto de credenciais (`IntegrationConfig["credentials"]`):

| Chave | Usada quando `authType` = | Campo na UI |
|---|---|---|
| `token` | `bearer` | "Bearer Token" |
| `username` | `basic` | "Usuário" |
| `password` | `basic` | "Senha" |
| `apiKey` | `api_key` | "API Key" |
| `apiKeyHeader` | `api_key` | "Nome do Header" |

Consequência de UX a preservar: **ao reabrir uma integração, todos os campos de credencial aparecem vazios**. O usuário precisa entender que vazio ≠ "não há credencial" — o cadeado no card é o único sinal de que existe uma credencial salva.

⚠️ A confirmar: se o backend preserva a credencial existente quando o `PUT` chega com `credentials: {}` (o payload é enviado tal como está — `useSaveIntegration` repassa `payload.credentials`). Do lado do frontend nada impede que um "salvar" sem redigitar a credencial a apague.

### A2.5 Variável de integração

Marcador `{{chave}}` que o `send-message` substitui em tempo de envio. Duas famílias:

**(a) Chaves estáticas** — catálogo em `src/lib/constants/integration-variables.ts` (`INTEGRATION_VARIABLES`), **77 entradas** distribuídas em 10 categorias. O catálogo carrega `key`, `label`, `category`, `description` e `example`. Inventário completo em A8.2.

**(b) Namespaces dinâmicos** — `DYNAMIC_VARIABLE_NAMESPACES`, 4 prefixos cuja parte final varia por organização:

| Prefixo | Rótulo | Origem do dado |
|---|---|---|
| `contact.custom.` | Campo personalizado do contato | `contacts.custom_fields` (ETL, `entity_type=contacts`) — resolvido no corpo, assunto e payload |
| `contract.custom.` | Campo personalizado do contrato | `contracts.custom_fields` do contrato da ação |
| `title.custom.` | Campo personalizado do título | `titles.custom_fields` do título da ação |
| `var.` | Variável personalizada da organização | Valor definido em **Configurações › Variáveis Personalizadas** |

Esses namespaces **não** aparecem no catálogo estático de propósito (listar uma chave-exemplo faria o operador inserir literal e resolver vazio). Quem enumera as chaves reais é o hook `useVariables`, a partir de `custom_field_definitions` da própria org.

**(c) Aliases** — `VARIABLE_KEY_ALIASES` mapeia `action_recipient` → `action.recipient`. O alias **não aparece no picker** (seriam duas linhas para o mesmo valor) mas entra em `ALL_VARIABLE_KEYS` para não ser acusado de variável desconhecida, e herda o exemplo da chave canônica.

**Distinção crítica de contexto (IAF-6392/6390).** A categoria `acao` (hoje só `action.recipient`) vive no dicionário `allVariables` do `send-message`, **não** em `baseVariables`. Corpo e assunto da mensagem são resolvidos **antes** — uma chave dessa categoria usada no corpo sai **literal** para o cliente. Por isso ela é oferecida **apenas** no contexto `integration_payload` (o Body Template da integração). Na UI isso se manifesta assim:

| Componente | `variableContext` | Categoria "Ação" oferecida? |
|---|---|---|
| `InputWithVariables` (default) | `"integration"` | Não |
| `InputWithVariables` no BodyEditor (modo Campos) | `"integration_payload"` | **Sim** |
| `VariableHighlightTextarea` (modo JSON do BodyEditor) | contexto `"all"` (via `RichVariableInput`) | Sim |
| `RichVariableInput` no painel de teste (Assunto/Conteudo) | `"integration"` | Não |

### A2.6 Chave de API (API Key)

Conceito **diferente** de credencial de integração e a direção do fluxo é **inversa**:

| | Credencial de integração | API Key |
|---|---|---|
| Direção | Torre → sistema externo | Sistema externo → Torre |
| Onde vive | `integration_secrets` da org (criptografado) | Tabela global `api_keys` |
| Quem gerencia | Quem tem `integrations:write` | **Só Super Admin** |
| Escopo | Uma integração | **Universal** — vale para todas as organizações |
| Como se usa | Header de auth montado pelo `send-message` | Headers `x-api-key` + `x-org-slug` (ambos obrigatórios) |

---

## A3. Anatomia visual da tela

Container raiz: `<div className="space-y-6">`.

### A3.1 Cabeçalho

`flex items-center justify-between`:

**Esquerda**
- `h1` `text-3xl font-bold flex items-center gap-2` → ícone `Puzzle h-8 w-8` + texto "Integrações".
- `p` `text-muted-foreground` → "Configure as integrações e chaves de API para seus workflows".

**Direita** (`flex gap-2`)
- `RefreshButton` — recebe `onRefresh={refetch}` e `isFetching`. Ícone gira enquanto carrega.
- `Button` "Nova Integração" com ícone `Plus h-4 w-4 mr-2`. **Condicional dupla**: `canEdit && mainTab === "integrations"`. Some quando o usuário está na aba API Keys.

### A3.2 Abas principais (nível 1)

`Tabs` controlado por `mainTab`, valores `"integrations" | "api-keys"`.

| Trigger | Ícone | Condição |
|---|---|---|
| "Integrações" | `Puzzle h-4 w-4` | sempre |
| "API Keys" | `Key h-4 w-4` | `isSuperAdmin` |

### A3.3 Faixa de filtro por tipo (nível 2)

`Tabs` aninhado controlado por `selectedType` (`IntegrationType | "all"`).

`TabsList` com `className="flex flex-wrap h-auto gap-1"` — ou seja, **quebra em múltiplas linhas** em telas estreitas (11 triggers no total).

- Primeiro trigger: `"all"` → rótulo "Todas", **sem ícone**.
- Os 10 seguintes: iterados de `Object.entries(INTEGRATION_TYPES)`, cada um com `flex items-center gap-1`, ícone de `TYPE_ICONS` (`h-4 w-4`) + `label`.

**Duplicidade de filtragem.** O filtro é aplicado **duas vezes**: (1) `useOrgIntegrations(selectedType === "all" ? undefined : selectedType)` já filtra no hook; (2) `filteredOrgIntegrations` refiltra em memória por `oi.category === selectedType`. Comportamento idêntico, redundância de código — irrelevante para o redesign, mas explica por que trocar de aba força um novo `queryKey` (`["org","integrations", orgSchema, category]`) e, portanto, um novo fetch.

### A3.4 Grade de cards

`div` com `grid gap-4 md:grid-cols-2 lg:grid-cols-3`:

| Breakpoint | Colunas |
|---|---|
| `< md` (mobile) | 1 |
| `md` | 2 |
| `lg` e acima | 3 |

### A3.5 Anatomia do card de integração (`IntegrationCard`)

`Card` com classe condicional: **ativo** → `border-primary/30 bg-primary/5`; **inativo** → `border-muted`.

**`CardHeader`** (`pb-3`), layout `flex items-start justify-between gap-2`:

*Bloco esquerdo* (`flex items-center gap-3 min-w-0`):
1. **Quadrado de ícone** — `p-2 rounded-lg shrink-0` + a classe de cor do tipo (`typeConfig.color`, ex.: `bg-green-100 text-green-800` para WhatsApp). Dentro, o ícone do tipo `h-5 w-5`.
2. **Coluna de texto** (`min-w-0`):
   - Linha 1: `CardTitle text-base truncate` com `title={instanceName}` (tooltip nativo para nome longo) + **cadeado condicional** (`Lock h-3.5 w-3.5 text-primary shrink-0`, `title="Credenciais criptografadas"`) quando `config.has_encrypted_credentials`.
   - Linha 2 (`flex items-center gap-2 mt-1`): `Badge variant="outline" text-xs` com o rótulo do tipo + `Badge` de situação, `variant="default"` quando ativo (texto "Ativo") e `variant="secondary"` quando inativo (texto "Inativo").

*Bloco direito*: `Switch` (`shrink-0`), só renderizado se `canEdit`. `checked={isActive}`, `disabled` enquanto `disableIntegration.isPending || enableIntegration.isPending`.

**`CardContent`**:
- `CardDescription mb-4 line-clamp-2` — **só renderiza se `orgIntegration.description` existir**. Comentário no código: *"Only show description if user explicitly set one"*.
- `div flex gap-2` com dois botões, ambos só se `canEdit`:
  - `Button size="sm" variant="outline"` → ícone `Settings h-4 w-4 mr-1` + "Editar". Abre o `IntegrationBuilderSheet` com `existingConfig`.
  - `Button size="sm" variant="ghost"` → ícone `Trash2 h-4 w-4 text-destructive`, **sem rótulo textual**. `disabled` enquanto `deleteIntegration.isPending`.

**Nome exibido.** `instanceName = orgIntegration.name || config.name || "Integração"` — triplo fallback.

### A3.6 Estado vazio da grade

`flex flex-col items-center justify-center py-16 text-center`:
- `Puzzle h-16 w-16 text-muted-foreground/50 mb-4`
- `h3 text-lg font-semibold mb-2` → "Nenhuma integração configurada"
- `p text-muted-foreground mb-6 max-w-md` → "Configure suas integrações para conectar canais de comunicação aos seus workflows de cobrança."
- `Button` "Criar Primeira Integração" (ícone `Plus`) — **só se `canEdit`**.

Este estado aparece tanto na organização recém-criada quanto quando o filtro de tipo não retorna nada — **o texto é o mesmo nos dois casos**, o que é uma dor documentada em C5.

### A3.7 Estado de carregamento da grade

`flex items-center justify-center py-12` com `Loader2 h-8 w-8 animate-spin text-muted-foreground`.

---

## A4. Construtor de integração (`IntegrationBuilderSheet`) — seção por seção

**Arquivo:** `src/components/integrations/IntegrationBuilderSheet.tsx`

### A4.0 Contrato e gatilho

| Prop | Tipo | Papel |
|---|---|---|
| `open` | `boolean` | Controla a abertura do Sheet |
| `onClose` | `() => void` | Fecha; também disparado ao clicar fora / ESC (`onOpenChange`) |
| `existingIntegration` | `OrgIntegration \| undefined` | `undefined` = modo criação; preenchido = modo edição |
| `onSave` | `(config: IntegrationConfig) => Promise<void>` | Handler do botão Salvar |
| `isSaving` | `boolean` | Estado do botão Salvar |

**Gatilhos de abertura:** botão "Nova Integração" (header), botão "Criar Primeira Integração" (estado vazio), botão "Editar" de qualquer card.

**Container:** `SheetContent` com `w-full sm:max-w-2xl flex flex-col p-0` — **largura total no mobile**, máximo `2xl` (672px) a partir de `sm`. Desliza pela direita (default do componente `Sheet`).

### A4.1 Cabeçalho do Sheet

`SheetHeader px-6 py-4 border-b`:
- `SheetTitle flex items-center gap-2` → ícone `Settings h-5 w-5` + texto **"Editar Integração"** ou **"Nova Integração"** (conforme `existingIntegration`).
- `SheetDescription` → "Configure os detalhes da integração HTTP/API" (texto fixo nos dois modos).

### A4.2 Abas internas

`Tabs defaultValue="general"` com `TabsList mx-6 mt-4 grid w-auto grid-cols-3` — as três abas ocupam **um terço cada**, largura fixa.

| Valor | Rótulo | Ícone |
|---|---|---|
| `general` | Geral | `Settings h-4 w-4` |
| `auth` | Autenticação | `ShieldCheck h-4 w-4` |
| `test` | Testar | `FlaskConical h-4 w-4` |

Todo o conteúdo das três abas vive dentro de um único `ScrollArea flex-1 px-6 py-4`.

> **Observação de estado:** `defaultValue` (não controlado). Reabrir o Sheet sempre começa em "Geral".

---

### A4.3 Aba **Geral** — campo a campo

Espaçamento: `space-y-4`.

#### A4.3.1 Linha 1 — Tipo de Integração + Importar cURL

Layout `grid grid-cols-3 gap-2`.

**Coluna 1–2: Tipo de Integração**

| Item | Detalhe |
|---|---|
| Rótulo | "Tipo de Integração" seguido de `<span className="text-destructive">*</span>` |
| Controle | `Select` |
| Opções | 10 itens, iterados de `INTEGRATION_TYPES`, exibindo `type.label` |
| Placeholder | "Selecione o tipo..." |
| Estado de erro | `SelectTrigger` ganha `border-destructive/50` quando vazio |
| Mensagem de erro | `p text-xs text-destructive` → "Selecione um tipo de integração" (sempre visível enquanto vazio, não só após submit) |
| Efeito colateral | `onValueChange` atualiza **dois** estados: `integrationType` (local) e `config.integrationType` |
| `SelectContent` | `z-50 bg-popover` (proteção contra sobreposição dentro do Sheet) |

**Coluna 3: botão Importar cURL**
- `Button type="button" variant="outline" className="w-full"`, alinhado ao rodapé da linha (`flex items-end`).
- Ícone `FileCode h-4 w-4 mr-2` + "Importar cURL".
- Abre `ImportCurlModal` (seção A5).

`Separator` abaixo da linha.

#### A4.3.2 Nome da Integração

| Item | Detalhe |
|---|---|
| Rótulo | "Nome da Integração" + asterisco `text-destructive` |
| `id` | `name` |
| Controle | `Input` texto |
| Placeholder | "Ex: API de Envio de SMS" |
| Obrigatório | Sim — entra em `isValid` |
| Feedback de erro | **Nenhum** visual próprio; só o botão Salvar desabilitado |

#### A4.3.3 Descrição

| Item | Detalhe |
|---|---|
| Rótulo | "Descrição" (sem asterisco) |
| `id` | `description` |
| Controle | `Input` (uma linha — **não** é textarea) |
| Placeholder | "Descrição opcional" |
| Uso | Renderizada no card com `line-clamp-2`; se vazia, o card não mostra bloco de descrição |

#### A4.3.4 URL de Visualização Externa

| Item | Detalhe |
|---|---|
| Rótulo | "URL de Visualização Externa" |
| `id` | `externalActionUrl` |
| Controle | `Input` |
| Placeholder | `https://sistema.com/acao/{{external_id}}` |
| Texto de ajuda | `p text-xs text-muted-foreground` → "Use `{{external_id}}` para inserir o ID da ação no sistema externo. Ex: `https://conversas.hyperflow.global/all-chats/{{external_id}}`" |
| Obrigatório | Não |
| Finalidade | Permite abrir a ação no painel do provedor a partir da Torre |

> **Bug de persistência a preservar-ou-corrigir no redesign.** O campo é lido do config existente (`externalActionUrl: existingConfig.externalActionUrl || ""`) e editado no estado local, **mas `IntegrationsPage.handleSaveIntegration` não o inclui no objeto `config` enviado ao backend** — o payload monta apenas `integrationType, name, description, url, method, headers, bodyTemplate, authType`. Ou seja: **o valor digitado aqui é descartado ao salvar**.
> ⚠️ A confirmar: se a Edge Function `api` faz merge do config anterior (o que preservaria um valor já gravado por outro caminho). Pela leitura do frontend, o campo é write-only-para-o-vazio.

#### A4.3.5 Método + URL

Layout `grid grid-cols-4 gap-2`.

**Método** (1 coluna)
- `Select`, valores de `HTTP_METHODS = ["GET","POST","PUT","PATCH","DELETE"]`.
- Default em nova integração: **`POST`**.
- Sem placeholder (sempre há valor).

**URL** (3 colunas)

| Item | Detalhe |
|---|---|
| Rótulo | "URL" + asterisco `text-destructive` |
| `id` | `url` |
| Placeholder | `https://api.exemplo.com/v1/endpoint` |
| Obrigatório | Sim — entra em `isValid` |
| Validação de formato | **Nenhuma na UI**. O módulo `src/lib/webhook-url-validation.ts` (anti-SSRF: HTTPS obrigatório, bloqueio de loopback/RFC1918/link-local/CGNAT/ULA/sufixos internos/rótulo único) **não é usado aqui** — ele serve à configuração de webhook do Playground do agente. Ver A9.5. |

#### A4.3.6 Headers

**Cabeçalho da seção** — `flex items-center justify-between`: rótulo "Headers" + `Button variant="ghost" size="sm"` com ícone `Plus h-4 w-4 mr-1` e texto "Adicionar".

**Linhas** — cada header é um `div flex gap-2` com três elementos:

| Elemento | Detalhe |
|---|---|
| `Input` nome | `flex-1`, placeholder "Nome do header" |
| `Input` valor | `flex-1`, placeholder "Valor" |
| Botão de ação | `X` (remover) **ou** `Lock` (travado) |

**Header travado `x-org-slug`.** Constantes no topo do arquivo:
```
LOCKED_ORG_HEADER       = "x-org-slug"
LOCKED_ORG_HEADER_VALUE = "{{org.slug}}"
```

Regras de comportamento (todas implementadas):

| Regra | Implementação |
|---|---|
| Detecção | `isLockedHeader(key) => key.trim().toLowerCase() === "x-org-slug"` — **case-insensitive** |
| Campo nome | `disabled` + `title="Header obrigatório — não pode ser renomeado"` |
| Campo valor | **Editável** — o usuário pode mudar o valor, só não o nome |
| Botão | `Lock h-4 w-4 text-muted-foreground`, `disabled`, `cursor-default`, `title="Header obrigatório — não pode ser removido"` |
| Defesa em profundidade (rename) | `updateHeader` retorna a linha intacta se `isLockedHeader` — bloqueia inclusive a edição do **valor** quando a linha é a travada |
| Defesa em profundidade (remoção) | `removeHeader` filtra com `i !== index \|\| isLockedHeader(h.key)` — a linha travada sobrevive ao filtro |
| Injeção retroativa | Ao abrir uma integração salva **sem** o header travado, ele é **inserido no topo** da lista com o valor default |

> **Inconsistência real de UX.** O comentário do código diz que só o *nome* é travado ("O usuario nao pode renomear nem remover essa linha"), e o `Input` de valor **não** tem `disabled`. Mas o guard de `updateHeader` retorna `h` inalterado para **qualquer** campo da linha travada — então, na prática, **digitar no campo de valor do `x-org-slug` não surte efeito nenhum**: o campo parece editável e simplesmente não muda. Isso é um defeito de feedback que o redesign deve resolver (ou travar visualmente, ou permitir de fato a edição).

**Defaults de nova integração** (`DEFAULT_HEADERS`):

| Nome | Valor |
|---|---|
| `Content-Type` | `application/json` |
| `x-org-slug` | `{{org.slug}}` |

**Estado vazio da lista**: `p text-sm text-muted-foreground text-center py-2` → "Nenhum header configurado". (Na prática inalcançável em integração nova, já que o header travado é sempre reinjetado.)

**Sincronização.** Um `useEffect` converte `headersList` (array) em `config.headers` (objeto), **ignorando linhas com nome vazio** (`if (key.trim())`). Consequência: duas linhas com o mesmo nome → a última vence, silenciosamente.

#### A4.3.7 Body Template (`BodyEditor`)

**Arquivo:** `src/components/integrations/BodyEditor.tsx`

Rótulo da seção: "Body Template".

**Dois modos**, em `Tabs` com `TabsList grid w-full grid-cols-2`:

| Modo | Rótulo | Ícone |
|---|---|---|
| `fields` (default) | Campos | `List h-3.5 w-3.5` |
| `json` | JSON | `Code h-3.5 w-3.5` |

**Modo "Campos"**
- Lista de linhas `flex gap-2`:
  - `Input` "Chave" (`flex-1`).
  - `InputWithVariables` "Valor (use {{variavel}})" (`flex-1`), com `variableContext="integration_payload"` — **único ponto da UI onde a categoria "Ação" é oferecida**.
  - `Button variant="ghost" size="icon"` com `X` para remover a linha.
- `Button variant="outline" size="sm" className="w-full"` → `Plus h-4 w-4 mr-1` + "Adicionar Campo".
- Abaixo, se houver ao menos uma chave preenchida: rótulo "Template" (`text-xs text-muted-foreground`) + `VariablePreviewBlock` com o JSON montado (`text-xs`).

**Modo "JSON"**
- `VariableHighlightTextarea` (`rows={8}`), placeholder `{"key": "{{contact.name}}"}`.
- Erro de validação: `flex items-center gap-2 text-sm text-destructive` com `AlertCircle h-4 w-4` + mensagem.
- Abaixo, se JSON válido e não vazio: rótulo "Template" + `VariablePreviewBlock`.

**Validações do modo JSON** (`handleJsonChange`):

| Condição | Mensagem |
|---|---|
| Vazio | Sem erro (limpa) |
| `JSON.parse` falha | **"JSON inválido"** |
| Parse OK mas é array ou primitivo | **"O body deve ser um objeto JSON"** |
| Parse OK e é objeto | Sem erro + **re-sincroniza as linhas do modo Campos** |

**Preview com dados de exemplo** — `Collapsible` no rodapé, visível apenas quando `hasContent`:
- Gatilho: `Button variant="ghost" size="sm" w-full justify-between` com ícone `Eye` + texto "Preview com dados de exemplo"; à direita, `EyeOff` quando aberto, `Eye` quando fechado.
- Conteúdo: `div rounded-lg border border-dashed border-primary/30 bg-primary/5 p-3`, rótulo `📋 Exemplo de Payload (dados fictícios)` (`text-xs text-primary font-medium`) e `pre` monoespaçado com o resultado de `replaceWithExamples()`.

**Regra de substituição de exemplos** (`replaceWithExamples`, em `integration-variables.ts`):
1. Chave com entrada estática → substitui pelo `example` do catálogo.
2. Chave de namespace dinâmico → substitui por um marcador legível `[<rótulo do namespace>: <campo>]`, ex.: `[Campo personalizado do contato: etapa]`.
3. Chave desconhecida (typo) → **sai crua, de propósito** — é assim que o erro fica visível.

**Sincronização entre modos.** Trocar Campos → JSON regenera o JSON a partir das linhas. Trocar JSON → Campos **não** dispara conversão explícita no `handleModeChange`, mas `handleJsonChange` já mantém `fields` atualizado a cada digitação válida.

**Body pré-preenchido em nova integração** (`DEFAULT_BODY_FIELDS`, 21 chaves em 6 grupos comentados):

| Grupo | Chave do JSON | Variável |
|---|---|---|
| Contato | `name` | `{{contact.name}}` |
| Contato | `document` | `{{contact.document}}` |
| Contato | `phone` | `{{contact.phone}}` |
| Contato | `email` | `{{contact.email}}` |
| Título | `title_number` | `{{title.number}}` |
| Título | `title_original_value` | `{{title.original_value}}` |
| Título | `title_current_value` | `{{title.current_value}}` |
| Título | `title_due_date` | `{{title.due_date}}` |
| Título | `title_days_overdue` | `{{title.days_overdue}}` |
| Título | `title_pix_key` | `{{title.pix_key}}` |
| Título | `title_boleto_digitable_line` | `{{title.boleto_digitable_line}}` |
| Contrato | `contract_number` | `{{contract.number}}` |
| Contrato | `contract_modality` | `{{contract.modality}}` |
| Carteira | `portfolio_name` | `{{portfolio.name}}` |
| Ação | `action_id` | `{{action.id}}` |
| Ação | `action_type` | `{{action.type}}` |
| Ação | `action_content` | `{{action.content}}` |
| Ação | `action_subject` | `{{action.subject}}` |
| Organização | `org_slug` | `{{org.slug}}` |
| Meta Template | `template_name` | `{{action.meta_template_name}}` |
| Meta Template | `template_vars` | `{{action.template_vars}}` |

> **Nota de consistência.** Cinco dessas variáveis (`action.id`, `action.type`, `action.content`, `action.subject`, `action.meta_template_name`, `action.template_vars`) **não constam** de `INTEGRATION_VARIABLES` — o catálogo só tem `action.recipient` na categoria `acao`. Consequência prática: no preview com dados de exemplo elas **saem cruas** (`{{action.id}}` literal), como se fossem typos. É um ruído visual no onboarding que o redesign deve tratar.

#### A4.3.8 Switch "Integração Ativa"

`div flex items-center justify-between rounded-lg border p-3`:
- Esquerda: `Label` "Integração Ativa" + `p text-xs text-muted-foreground` "Desative para pausar temporariamente".
- Direita: `Switch` ligado a `config.isActive` (default `true` em nova integração).

---

### A4.4 Aba **Autenticação**

Espaçamento `space-y-4`.

#### A4.4.1 Seletor de tipo

| Item | Detalhe |
|---|---|
| Rótulo | "Tipo de Autenticação" |
| Controle | `Select`, valor `config.authType` |
| Default | `none` |
| Efeito colateral crítico | `onValueChange` **zera `credentials: {}`** ao trocar de tipo — o que foi digitado se perde |

Opções:

| Valor | Rótulo exibido |
|---|---|
| `none` | Sem Autenticação |
| `bearer` | Bearer Token |
| `basic` | Basic Auth |
| `api_key` | API Key (Header) |

`Separator` abaixo.

#### A4.4.2 Campos por tipo

**`none`** — nenhum campo. Texto centralizado: `p text-sm text-muted-foreground text-center py-8` → "Nenhuma autenticação será enviada nas requisições".

**`bearer`** — um campo:

| Campo | `id` | Tipo | Placeholder |
|---|---|---|---|
| Bearer Token | `token` | `password` ↔ `text` (toggle) | `seu_token_aqui` |

Rodapé: `🔒 O token será criptografado antes de salvar`.

**`basic`** — dois campos:

| Campo | `id` | Tipo | Placeholder |
|---|---|---|---|
| Usuário | `username` | `text` (sem máscara, **sem toggle**) | `usuario` |
| Senha | `password` | `password` ↔ `text` (toggle) | `senha` |

Rodapé: `🔒 As credenciais serão criptografadas antes de salvar`.

**`api_key`** — dois campos:

| Campo | `id` | Tipo | Placeholder |
|---|---|---|---|
| Nome do Header | `apiKeyHeader` | `text` (sem máscara) | `X-API-Key` |
| API Key | `apiKey` | `password` ↔ `text` (toggle) | `sua_api_key` |

Rodapé: `🔒 A API Key será criptografada antes de salvar`.

#### A4.4.3 Toggle de visibilidade

**Um único estado booleano `showCredentials` compartilhado por todos os campos mascarados.** Botão `variant="ghost" size="icon"` posicionado `absolute right-0 top-0 h-full` dentro de um wrapper `relative`. Ícone `Eye` (oculto) ↔ `EyeOff` (visível).

Consequência: em Basic Auth, revelar a senha e revelar o token de outra aba usam o mesmo estado — comportamento coerente, mas o redesign deve notar que **não há toggle por campo**.

#### A4.4.4 Emojis funcionais

Os três rodapés usam o emoji 🔒 literal no texto. O redesign pode substituí-lo por ícone `Lock`, mantendo a mensagem.

---

### A4.5 Aba **Testar**

**Gate duro:** só renderiza `IntegrationTestPanel` se `existingIntegration?.id` existir.

**Estado bloqueado** (integração nova):
- `flex flex-col items-center justify-center py-12 text-center`
- `FlaskConical h-10 w-10 text-muted-foreground mb-3`
- `p text-sm text-muted-foreground` → "Salve a integracao primeiro para poder testar com dados reais." *(sem acentos no código-fonte)*

**Estado habilitado** — `IntegrationTestPanel` recebe:
```
integration = { id, name, category, config }   (da integração SALVA, não do formulário em edição)
disabled    = !config.url                      (do formulário em edição)
```

> **Armadilha de UX importante.** O painel de teste usa a integração **persistida**, não o rascunho em tela. Se o usuário edita a URL e vai direto testar sem salvar, o teste roda contra a **configuração antiga**. Nada na interface avisa isso. O `disabled` só olha se o campo URL do rascunho está vazio.

---

### A4.6 Rodapé do Sheet

`SheetFooter px-6 py-4 border-t`:

| Botão | Variante | Comportamento |
|---|---|---|
| **Cancelar** | `outline` | `onClose()` — descarta tudo sem confirmação |
| **Salvar** | default | `onSave(config)`; ícone `Save h-4 w-4 mr-2` ou `Loader2 animate-spin` quando `isSaving` |

**Regra de habilitação do Salvar:**
```
isValid = config.name.trim() && config.url.trim() && integrationType
disabled = !isValid || isSaving
```
Ou seja: **três campos obrigatórios** (Nome, URL, Tipo). Nenhum deles mostra erro inline exceto o Tipo.

> **Sem guarda de alterações não salvas.** Clicar Cancelar, pressionar ESC ou clicar fora do Sheet descarta o trabalho **sem confirmação**.

### A4.7 Ciclo de vida do formulário

`useEffect` com deps `[existingIntegration, open]` — **reinicializa o formulário toda vez que o Sheet abre**.

| Modo | Comportamento na inicialização |
|---|---|
| **Edição** | Preenche de `existingIntegration.config`; `integrationType = category \|\| config.integrationType \|\| ""`; `credentials = {}`; `isActive = existingIntegration.is_active ?? true`; injeta `x-org-slug` se ausente |
| **Criação** | `integrationType = ""`; `method = "POST"`; headers = `DEFAULT_HEADERS`; body = `DEFAULT_BODY_TEMPLATE`; `authType = "none"`; `isActive = true` |

### A4.8 O que é gravado ao salvar

`IntegrationsPage.handleSaveIntegration` → `useSaveIntegration` → `POST` (criação) ou `PUT` (edição) em `${SUPABASE_URL}/functions/v1/api/integrations`, com headers `Authorization: Bearer <access_token>` e `x-org-slug: <slug>`.

Corpo enviado:

| Campo do payload | Origem |
|---|---|
| `id` | `builderSheet.existingConfig?.id` (só em edição) |
| `name` | `config.name` |
| `slug` | `payload.slug` (não preenchido pela página) |
| `category` | `config.integrationType \|\| "webhook"` — **fallback silencioso para webhook** |
| `description` | `config.description` |
| `config` | objeto com `integrationType, name, description, url, method, headers, bodyTemplate, authType` |
| `credentials` | `config.credentials` |
| `is_active` | `config.isActive ?? true` |

**Toast de sucesso:** título "Sucesso", descrição "Integração atualizada com sucesso" (edição) ou "Integração configurada com sucesso" (criação). Em seguida o Sheet fecha.

**Toast de erro:** título "Erro", descrição = `error.message` ou "Erro ao salvar integração". O Sheet **permanece aberto**, preservando o que foi digitado. Antes do toast, `logError(error, { source: "IntegrationsPage", action: "save integration" })`.

### A4.9 Ações fora do Sheet (no card)

| Ação | Hook | Endpoint | Confirmação | Feedback |
|---|---|---|---|---|
| **Ativar** | `useEnableIntegration` | `POST /api/integrations/{id}/enable` | Não | Toast de erro apenas em falha: "Não foi possível alterar o status da integração" |
| **Desativar** | `useDisableIntegration` | `POST /api/integrations/{id}/disable` | Não | idem |
| **Remover** | `useDeleteOrgIntegration` | `DELETE /api/integrations/{id}` | **`window.confirm("Tem certeza que deseja remover esta integração?")`** | Sucesso: toast "Integração removida com sucesso". Erro: toast do hook, título "Erro ao excluir", mensagem de `getDeleteErrorMessage(payload)` |

> **Ponto crítico para o redesign.** A remoção usa `window.confirm()` **nativo do browser** — é o único diálogo destrutivo da tela que **não** usa `AlertDialog`. Visualmente destoa de tudo (a remoção de API Key, na mesma página, usa `AlertDialog`). Trocar por `AlertDialog` é ganho gratuito.
>
> Note também a **duplicação de toast de erro na remoção**: o `IntegrationCard` tem seu próprio `catch` com toast "Não foi possível remover a integração", e o hook `useDeleteOrgIntegration` também tem `onError` com toast. Em uma falha, **dois toasts aparecem**.

Todas as três mutations invalidam a query key `["org","integrations"]` no sucesso.

---

## A5. Importar cURL (`ImportCurlModal`)

**Arquivo:** `src/components/integrations/ImportCurlModal.tsx`
**Parser:** `src/lib/curl-parser.ts`

### A5.1 Identidade do modal

| Item | Detalhe |
|---|---|
| Objetivo | Preencher automaticamente URL, método, headers, body e autenticação a partir de um comando cURL copiado da documentação do provedor |
| Gatilho | Botão "Importar cURL" na aba Geral do Construtor |
| Container | `Dialog` → `DialogContent max-w-2xl` |
| Título | Ícone `FileCode h-5 w-5` + "Importar cURL" |
| Descrição | "Cole um comando cURL para preencher automaticamente a configuração da integração" |
| Fechamento | Clique fora / ESC (`onOpenChange`) ou botão Cancelar — ambos passam por `handleClose`, que **limpa o textarea, o erro e o preview** |

### A5.2 Layout

`div space-y-4`:

1. **`Textarea`** — `min-h-[150px] font-mono text-sm`. Placeholder multilinha com exemplo real:
```
curl -X POST 'https://api.example.com/v1/endpoint' \
  -H 'Authorization: Bearer your_token' \
  -H 'Content-Type: application/json' \
  -d '{"key": "value"}'
```
   A cada digitação, **limpa erro e preview** (volta ao estado inicial de dois botões).

2. **Bloco de erro** (condicional) — `Alert variant="destructive"` com `AlertCircle h-4 w-4`.

3. **Bloco de preview** (condicional) — `Alert` com `border-green-200 bg-green-50`, ícone `CheckCircle h-4 w-4 text-green-600`, texto `text-green-800`:
   - "Comando parseado com sucesso:" (`font-medium`)
   - Lista `ul text-sm space-y-0.5`:
     | Linha | Conteúdo |
     |---|---|
     | **Método:** | `preview.method` |
     | **URL:** | `preview.url` |
     | **Headers:** | `<n>` encontrados |
     | **Body:** | "presente" *(só se houver body)* |
     | **Auth:** | `preview.auth.type` *(só se detectada)* |

### A5.3 Rodapé — botão em dois estágios

| Estado | Botões |
|---|---|
| Sem preview | `Cancelar` (outline) + **`Analisar`** |
| Com preview | `Cancelar` (outline) + **`Importar Configuração`** |

Fluxo de duas etapas obrigatório: **analisar → conferir → importar**.

### A5.4 Validações e mensagens de erro

| Condição | Mensagem exibida |
|---|---|
| Textarea vazio/só espaços | "Cole um comando cURL para continuar" |
| `!isValidCurl(cmd)` — não começa com `curl ` nem `curl\n` (case-insensitive) | "O comando não parece ser um cURL válido. Deve começar com 'curl'" |
| Parse OK mas `parsed.url` vazio | "Não foi possível extrair a URL do comando" |
| Exceção no `parseCurl` | "Erro ao processar o comando cURL" |

### A5.5 Capacidades do parser (`parseCurl`)

**Tokenização** — preserva strings entre aspas simples/duplas, trata escapes `\`, e consome continuação de linha (`\` + newline, incluindo `\r\n`).

**Flags reconhecidas:**

| Flag | Efeito |
|---|---|
| `-X`, `--request` | Define `method` (upper-case) |
| `-H`, `--header` | Adiciona ao mapa `headers`, quebrando no **primeiro** `:` |
| `-d`, `--data`, `--data-raw`, `--data-binary`, `--data-urlencode` | Define `body`; se `method` ainda é `GET` e não há `-X`/`--request`, **promove para `POST`** |
| `--url` | Define `url` explicitamente |
| token sem hífen começando por `http` (ou `'http` / `"http`) | Define `url` posicionalmente |

**Detecção automática de autenticação:**

| Header lido | Resultado |
|---|---|
| `authorization: Bearer <v>` (case-insensitive) | `auth = { type: "bearer", value: <v> }` |
| `authorization: Basic <v>` | `auth = { type: "basic", value: <v> }` |
| nome contendo **"api"** E **"key"** (case-insensitive) | `auth = { type: "api_key", value, headerName }` |

**Default de método:** `GET`, salvo promoção por presença de body.

### A5.6 O que a importação sobrescreve

`handleImportCurl` no `IntegrationBuilderSheet` substitui, **sem confirmação e sem merge**:

| Campo | Novo valor |
|---|---|
| `url` | `parsed.url` |
| `method` | `parsed.method` |
| `headers` | `parsed.headers` (substituição total) |
| `bodyTemplate` | `parsed.body \|\| ""` |
| `authType` | `parsed.auth?.type \|\| "none"` |
| `credentials.token` | valor, se `type === "bearer"` |
| `credentials.apiKey` | valor, se `type === "api_key"` |
| `credentials.apiKeyHeader` | nome do header, se `type === "api_key"` |
| `headersList` | reconstruído inteiramente de `parsed.headers` |

**Não são tocados:** `integrationType`, `name`, `description`, `externalActionUrl`, `isActive`.

> **Duas consequências graves para o redesign:**
> 1. **O header travado `x-org-slug` desaparece.** `setHeadersList` recebe *só* os headers do cURL, sem reinjeção do header obrigatório (a reinjeção só acontece no `useEffect` de abertura). Se o cURL do provedor não tiver `x-org-slug`, a integração fica sem ele até o Sheet ser reaberto.
> 2. **Basic Auth importado perde a credencial.** Quando `parsed.auth.type === "basic"`, o objeto `credentials` montado só preenche `token` e `apiKey`/`apiKeyHeader` — **não há ramo para `username`/`password`**. O `authType` vira `basic` mas os dois campos ficam vazios, e nada avisa.

### A5.7 Função inversa não exposta

`curl-parser.ts` exporta também `toCurl(config)`, que serializa uma configuração de volta para um comando cURL formatado com continuação de linha. **Nenhum componente da tela a usa** — é uma capacidade pronta para um futuro botão "Exportar cURL" / "Copiar como cURL".

---

## A6. Painel de teste

### A6.1 `IntegrationTestPanel` — o painel ativo

**Arquivo:** `src/components/integrations/IntegrationTestPanel.tsx`
**Hook:** `src/hooks/useIntegrationTest.ts`

Container: `ScrollArea h-full` > `div space-y-4 pb-4`. Seis seções sequenciais, cada uma revelada pela anterior.

#### Seção 1 — Buscar Contato

| Item | Detalhe |
|---|---|
| Rótulo | "Buscar Contato" (`text-sm font-medium`) |
| Gatilho | `Popover` cujo trigger é um `Button variant="outline" w-full justify-start text-left font-normal` com ícone `Search h-4 w-4` |
| Texto do trigger | Contato selecionado → `"<nome> - <documento formatado>"` (`truncate`); senão → `CUSTOMER_SEARCH_PLACEHOLDER` (`text-muted-foreground`) |
| Conteúdo | `PopoverContent w-[400px] p-0 align="start"` com `Command shouldFilter={false}` (filtragem é server-side) |
| Campo de busca | `CommandInput` com `maxLength={200}` e o mesmo placeholder |
| Debounce | **300 ms** (`setTimeout` dentro de `useEffect`) |
| Mínimo de caracteres | **2** — abaixo disso, resultados são zerados e nada é buscado |
| Anti-race | Flag `active` no cleanup do efeito — resposta atrasada de uma busca anterior é **descartada** |

**Estados da lista:**

| Estado | Render |
|---|---|
| Erro | `p role="alert" className="p-3 text-sm text-destructive"` com a mensagem da exceção |
| Buscando | `Loader2 h-4 w-4 animate-spin` + "Buscando..." (`py-6`, centralizado) |
| Sem resultado (≥2 chars, sem erro) | `CommandEmpty` → "Nenhum contato encontrado." |
| Com resultados | `CommandGroup heading="Contatos"` — cada item: ícone `User h-4 w-4` + nome (`text-sm font-medium`) + documento formatado (`text-xs text-muted-foreground`), `cursor-pointer` |

**Motor de busca:** `searchCustomers(currentOrg.slug, term)` de `src/lib/customer-search.ts` — a mesma busca global da Torre (nome, razão social, documento, telefone, número de contrato, e-mail), independente de o cliente ter título de contrato.

**Formatação de documento** (`formatDocument`): 11 dígitos → `000.000.000-00`; 14 dígitos → `00.000.000/0000-00`; caso contrário devolve como veio.

#### Seção 2 — Cartão-resumo do contato

Só aparece com contato selecionado. `div rounded-md border bg-muted/30 p-3 space-y-1.5`.

| Estado | Conteúdo |
|---|---|
| Carregando | `Loader2 h-4 w-4 animate-spin` + "Carregando dados do contato..." |
| Carregado | Linha com `User h-4 w-4` + nome (`text-sm font-medium`); abaixo, `grid grid-cols-2 gap-x-4 gap-y-1 text-xs text-muted-foreground` com 4 células |

As quatro células do grid (nessa ordem visual: coluna 1 linha 1, coluna 2 linha 1, coluna 1 linha 2, coluna 2 linha 2):

| Célula | Conteúdo | Fallback |
|---|---|---|
| Documento | `formatDocument(document)` | — |
| Telefone | `contactData.phone` | "Nao encontrado" |
| Titulos pendentes | `contactData.titles.length` | `0` |
| Email | `contactData.email` | "Nao encontrado" |

**Origem dos dados** (`fetchContactData`, três consultas em paralelo):

| Dado | Query |
|---|---|
| Títulos | `vw_titles_live` → `title_id, title_number, current_value, original_value, due_date, days_overdue, contract_id`, filtrado por `contact_id`, `is_paid = false` e `entity_kind = "contract"`, ordenado por `days_overdue` **desc** |
| Telefone | `contact_phones` → primeiro ativo por `priority` |
| E-mail | `contact_emails` → primeiro ativo por `priority` |

> Filtro `entity_kind = "contract"` (IAF-4795): **o teste de integração usa apenas títulos de contrato (equipamento)** — títulos de suprimento não aparecem.

#### Seção 3 — Seletor de título

Só aparece se houver títulos. `RadioGroup space-y-2`; cada opção é um `<label>` `flex items-center gap-3 rounded-md border p-3 cursor-pointer hover:bg-muted/50 transition-colors`:

- `RadioGroupItem` com `id={"title-" + title_id}`.
- Linha 1: `title.title_number` (`text-sm font-medium truncate`) + **badge de atraso** (`Badge variant="secondary" text-[10px] px-1.5 py-0`) com rótulo `D<n>` quando `days_overdue <= 0` e `D+<n>` quando positivo.
- Linha 2 (`text-xs text-muted-foreground`): `Venc: <dd/mm/aaaa>` · `Valor: <R$ formatado pt-BR>`.

**Escala de cor do badge de atraso** (`getDaysOverdueColor`):

| Faixa (`days_overdue`) | Classes |
|---|---|
| `<= 0` | `bg-blue-100 text-blue-800` |
| `1 – 15` | `bg-yellow-100 text-yellow-800` |
| `16 – 30` | `bg-orange-100 text-orange-800` |
| `31 – 60` | `bg-red-100 text-red-800` |
| `> 60` | `bg-red-200 text-red-900` |

**Pré-seleção:** o título de maior atraso (primeiro da lista ordenada desc) já vem marcado ao selecionar o contato.

**Contato sem títulos:** `Alert` com "Este contato nao possui titulos pendentes." — e, como `selectedTitleId` fica nulo, as seções 4 e 5 não aparecem e o disparo fica indisponível.

#### Seção 3.5 — Template Meta (só WhatsApp)

Condição tripla: `channel === "whatsapp"` **e** `selectedTitleId` **e** `metaTemplates?.length > 0`. Precedido de `Separator`.

- Rótulo: ícone `MessageSquare h-4 w-4` + "Template Meta (opcional)".
- **Combobox** (`Popover` + `Button role="combobox" w-full justify-between`):
  - Sem seleção → texto "Nenhum template (envio livre)" com `text-muted-foreground`.
  - Com seleção → `Badge` verde `bg-green-100 text-green-800` com texto "Meta" + nome do template (`meta_template_name || name`), tudo `truncate`.
  - Ícone `ChevronsUpDown h-3 w-3 opacity-50` à direita.
- `PopoverContent w-[360px] p-0` com `Command` e `CommandInput` "Buscar template...".
- `CommandEmpty` → "Nenhum template Meta encontrado".
- Primeiro item do grupo: `__none__` → "Nenhum template (envio livre)", limpa a seleção e o mapa de variáveis.
- Demais itens: **somente templates com `meta_status === "APPROVED"`**. Cada linha: `Check h-3 w-3` (opacidade 100/0 conforme seleção) + nome (`text-sm truncate`) + `meta_category` (`text-xs text-muted-foreground`) quando existir.
- **Mapeador de variáveis** — ao selecionar um template, extrai `{{1}}`, `{{2}}`… de todos os `meta_components[].text` via regex `/\{\{(\d+)\}\}/g`, ordena numericamente e inicializa o mapa com strings vazias. Renderiza `MetaVariableMapper` (de `src/components/reguas-cobranca/config-forms/SharedComponents`) com `variables`, `examples`, `value` e `onChange`.
- **Exemplos** — extraídos de `meta_components` do tipo `BODY`, campo `example.body_text[0]`, indexados de 1 em diante.
- Se o template não tem variáveis: `p text-xs text-muted-foreground` → "Este template nao possui variaveis para mapear."

#### Seção 4 — Campos de override

Só com `selectedTitleId`. Precedido de `Separator`. Rótulo da seção: "Dados do Envio (editar para sobrescrever)".

| Campo | `id` | Condição | Controle | Placeholder |
|---|---|---|---|---|
| Telefone | `override-phone` | canal ∈ {whatsapp, sms, voice} | `Input` | valor real do contato, ou "Sem telefone" |
| Email | `override-email` | canal = email | `Input` | valor real, ou "Sem email" |
| Assunto | — | canal = email | `RichVariableInput` (`rows={1}`, `variableContext="integration"`, `showPreview={false}`) | "Assunto do email (opcional)" |
| Conteudo | — | **sempre** | `RichVariableInput` (`rows={3}`, `variableContext="integration"`, `showPreview={false}`) | "Conteudo da mensagem (opcional, usa template da integracao se vazio)" |

**Badge "editado".** Sempre que o campo tem conteúdo, aparece ao lado do rótulo um `Badge variant="outline" text-[10px] px-1.5 py-0 border-orange-300 text-orange-600` com o texto "editado". Marcação visual laranja de que aquele valor **sobrescreve** o dado real.

**Padrão de placeholder inteligente:** telefone e e-mail mostram o valor real do contato como placeholder — o usuário vê o que será usado se deixar em branco.

#### Seção 5 — Botões de ação

Só com contato selecionado. Precedido de `Separator`. `flex items-center gap-2`:

| Botão | Estilo | Estado | Rótulo |
|---|---|---|---|
| **Enviar Teste** | default, `flex-1` | `disabled = !canExecute` | "Enviar Teste" / "Enviando..." com `Loader2` |
| **Limpar** | `outline` | `disabled = isExecuting` | ícone `RotateCcw h-4 w-4 mr-2` + "Limpar" |

```
canExecute = !!selectedContact && !!selectedTitleId && !isExecuting && !disabled
```

"Limpar" reseta: contato, dados, título, os 4 overrides, template Meta, mapa de variáveis, termo de busca, resultados e o resultado do teste.

#### Seção 6 — Resultado do teste

Só com `testResult`. Precedido de `Separator`.

**Critério de sucesso:** `SENT_STATUSES.has(testResult.status)` — conjunto canônico em português de `src/lib/constants/action-status-config.ts` (cobre `Enviado`, `Interagiu`, `Respondido`, permitindo que um callback externo já tenha avançado o status após o envio).

**Banner de status** — `Alert` com `variant="default"` + `border-green-200 bg-green-50` em sucesso, ou `variant="destructive"` em falha. Ícone `CheckCircle2 h-4 w-4 text-green-600` ou `XCircle h-4 w-4`.

| Linha | Conteúdo |
|---|---|
| Título | "Enviado com sucesso" ou "Falha no envio" (`font-medium text-sm`) |
| Tempo | `<n>ms` (`text-xs text-muted-foreground`), na mesma linha |
| Destinatário | "Destinatario: `<valor>`" (`text-xs`), se `testResult.recipient` |
| Erro | `testResult.errorMessage` (`text-xs font-medium text-destructive mt-1`), se houver |

**Conteúdo Resolvido** (se `testResult.content`) — rótulo "Conteudo Resolvido" + botão `Copy h-3 w-3` (ghost, `h-6 px-2`); `pre text-xs bg-muted p-3 rounded-md overflow-auto max-h-40 font-mono whitespace-pre-wrap break-words`.

**Request Payload** (se houver) — `Collapsible` fechado por padrão. Gatilho: `Button ghost sm w-full justify-start h-8 px-2 text-xs` com `ChevronDown`/`ChevronRight h-3 w-3` + "Request Payload" + botão de cópia aninhado à direita (`ml-auto`, com `e.stopPropagation()`). Conteúdo: `pre ... max-h-60` com `JSON.stringify(..., null, 2)`.

**Resposta do Provedor** (se houver) — idêntico ao anterior, rótulo "Resposta do Provedor".

**Action ID** — `p text-[10px] text-muted-foreground` → "Action ID: `<uuid>`".

#### Mecânica do disparo (`executeTest`)

Sequência real de 4 passos, relevante porque **o teste cria registros de verdade**:

1. **`ensureTestCampaign()`** — procura uma campanha de nome exato `"Teste Integracao"`; se não existir, **cria** uma com `description: "Campanha virtual para testes de integracao. Nao executa automaticamente."`, `status: "paused"`, `producer_trigger_type: "manual"`, `active_days: []`, `campaign_type: "recurring"`. O id fica em `useRef` durante a sessão.
2. **Insere uma `action` real** com `status = Pendente`, `source = "teste"`, `metadata = { is_test: true, tested_at, meta_template_name }`, além de `contact_id`, `contract_id`, `title_id`, `campaign_id`, `integration_id`, `action_type`/`channel`, `content`, `subject`, `template_variable_map`.
3. **Invoca a Edge Function `send-message`** (via client global — o `orgClient` com schema custom quebra `functions.invoke`) com `channel, integration_id, contact_id, contract_id, title_id, action_id, message, subject, recipient_override, variables`. **Erros não-2xx são engolidos de propósito** (`.catch(() => {})`) — a fonte da verdade é o registro da ação no banco.
4. **Relê a `action`** para montar o `TestResult`: `status, recipient, content, subject, request_payload, response, error_message`.

`recipient_override` = `overrides.phone || overrides.email`. O objeto `variables` injeta `contact.phone` e/ou `contact.email` quando o operador sobrescreveu.

Em exceção, monta um `TestResult` com `status = Falhou` e `errorMessage` da exceção.

> **Implicação de produto que o redesign deve tornar explícita:** o teste **envia a mensagem de verdade para o cliente real**, cria uma campanha "Teste Integracao" na lista de campanhas da org e deixa uma ação na tela de Ações com `source = "teste"`. Hoje nenhum aviso na interface diz isso.

### A6.2 `TestConnectionPanel` — capacidade existente, não montada

**Arquivo:** `src/components/integrations/TestConnectionPanel.tsx`

Teste **HTTP cru, client-side**, sem criar ação nem envolver contato: dispara `fetch(config.url, { method, headers, body })` direto do navegador.

| Elemento | Detalhe |
|---|---|
| Cabeçalho | `h4 text-sm font-medium` "Testar Conexão" + `Button size="sm"` com `Play h-4 w-4` / `Loader2` e rótulo "Testar" |
| Habilitação | `disabled \|\| isLoading \|\| !config.url` |
| Erro sem URL | Resultado com `error: "URL é obrigatória para testar a conexão"` |
| Content-Type automático | Se há body e falta `Content-Type`, injeta `application/json` |
| Body em GET | Omitido (`config.method !== "GET" && config.body`) |
| Resultado | `Alert` verde (`response.ok`) ou destrutivo |
| Linha de status | "**Status:** `<código> <statusText>`" + `Clock h-3 w-3` + `<n>ms` |
| Corpo da resposta | Rótulo "Resposta:" + `ScrollArea h-[150px] rounded border bg-muted/50 p-2` com `pre text-xs font-mono whitespace-pre-wrap break-all` |
| Formatação | Tenta `JSON.parse` + `stringify(…, null, 2)`; se falhar, mantém texto cru |
| Truncamento | Acima de **2000 caracteres**, corta e anexa `\n...[truncado]` |
| Falha de leitura | "[Não foi possível ler a resposta]" |
| Estado inicial | `p text-xs text-muted-foreground` → "Clique em \"Testar\" para verificar se a integração está funcionando corretamente." |

**Limitação técnica inerente:** requisição direta do browser → sujeita a **CORS**. Provedores que não liberam a origem da Torre falham com erro de rede genérico. É provavelmente o motivo de o componente ter sido substituído pelo teste server-side.

**Decisão para o redesign:** ou (a) remover de vez, ou (b) resgatar como "Teste rápido de conexão" ao lado do "Teste com dados reais" — são capacidades **complementares** (um valida a ponte HTTP sem consumir crédito nem incomodar cliente; o outro valida a resolução de variáveis e o envio de ponta a ponta).

---

## A7. Chaves de API (`ApiKeysSection`)

**Arquivo:** `src/components/integrations/ApiKeysSection.tsx`
**Hooks:** `src/hooks/useApiKeys.ts`

### A7.1 Quem pode

Aba visível **apenas** se `isSuperAdmin`. No backend, RLS com policies *super_admin-only* e a RPC `create_api_key` valida internamente o caller — o frontend não duplica a checagem. O hook `useApiKeys` tem `enabled: isSuperAdmin`, evitando request inútil.

### A7.2 Anatomia

Container: `Card` único.

**`CardHeader`** — `flex items-center justify-between`:
- Esquerda: quadrado `p-2 rounded-lg bg-primary/10` com `Key h-5 w-5 text-primary`; ao lado, `CardTitle text-lg` "API Keys" e `CardDescription` "Gerencie as chaves de acesso para integração via API".
- Direita: `Dialog` cujo trigger é `Button size="sm"` com `Plus h-4 w-4 mr-2` + "Nova API Key".

**`CardContent`** — três estados + bloco de ajuda fixo.

### A7.3 Tabela de chaves

| Coluna | Largura | Conteúdo |
|---|---|---|
| **Nome** | auto | `apiKey.name` (`font-medium`) |
| **Chave** | auto | `<code className="text-xs bg-muted px-2 py-1 rounded font-mono">{key_prefix ?? "—"}…</code>` — **só o prefixo**, seguido de reticências |
| **Criada em** | auto | `format(created_at, "dd/MM/yyyy HH:mm", { locale: ptBR })`, ou `"-"` |
| **Ações** | `w-[100px]` | `Button size="icon" variant="ghost" h-8 w-8` com `Trash2 h-4 w-4 text-destructive` |

**Filtro de exibição:** `allApiKeys?.filter(k => k.is_active)`. Chaves desativadas somem da lista — comentário do código: *"dando a percepcao de delete (\"delete silencioso\")"*.

**Ordenação:** `created_at` descendente (mais nova primeiro), definida na query.

**Campos carregados mas não exibidos:** `created_by` e `last_used_at`. O `last_used_at` seria informação de altíssimo valor operacional ("esta chave ainda é usada?") — oportunidade direta para o redesign.

**SELECT explícito.** A query enumera colunas seguras (`id, name, created_by, is_active, key_prefix, created_at, last_used_at`) e **nunca** usa `SELECT *` — a coluna `key` plaintext foi dropada do banco.

### A7.4 Estados da seção

| Estado | Render |
|---|---|
| Carregando | `flex items-center justify-center py-8` com `Loader2 h-6 w-6 animate-spin text-muted-foreground` |
| Com chaves | `Table` |
| Vazio | `text-center py-8 text-muted-foreground` → `Key h-10 w-10 mx-auto mb-3 opacity-50`, "Nenhuma API Key criada" (`text-sm`), "Crie uma chave para integrar sistemas externos via API" (`text-xs mt-1`) |

### A7.5 Bloco "Como usar" (sempre visível)

`div mt-6 p-4 bg-muted/50 rounded-lg`:
- `h4 text-sm font-medium mb-2` → "Como usar"
- Parágrafo `text-xs text-muted-foreground`: "A chave é **universal** (funciona para todas as organizações). Inclua **os dois headers obrigatórios** em cada requisição — o `x-org-slug` define qual organização será acessada e é obrigatório:"
- `code block text-xs bg-background p-2 rounded border font-mono whitespace-pre`:
```
x-api-key: tc_sua_chave_aqui
x-org-slug: slug-da-org
```
- Fecho: "Requisições sem `x-org-slug` são rejeitadas."

Prefixo das chaves: **`tc_`** (visível no exemplo).

### A7.6 Modal "Criar nova API Key" — dois estágios

| Item | Detalhe |
|---|---|
| Container | `Dialog` → `DialogContent` (largura padrão) |
| Título | "Criar nova API Key" |
| Descrição | "A chave será exibida apenas uma vez. Guarde-a em local seguro." |

**Estágio 1 — nomear** (`!newlyCreatedKey`):

| Elemento | Detalhe |
|---|---|
| Campo | `Input id="keyName"`, rótulo "Nome da chave" |
| Placeholder | "Ex: Integração ERP, Sistema Legado..." |
| Atalho | `Enter` dispara `handleCreate()` |
| Rodapé | `Cancelar` (outline, chama `closeCreateDialog`) + `Criar` |
| Habilitação do Criar | `disabled = !newKeyName.trim() || createApiKey.isPending`; mostra `Loader2 h-4 w-4 mr-2 animate-spin` durante a chamada |

**Estágio 2 — exibição única do segredo** (`newlyCreatedKey` preenchido):

| Elemento | Detalhe |
|---|---|
| Rótulo | "Sua nova API Key" |
| Campo | `Input readOnly className="font-mono text-sm"` com a chave em claro |
| Botão copiar | `Button size="icon" variant="outline"` — `Copy h-4 w-4`, vira `Check h-4 w-4 text-green-500` por **2 segundos** após copiar |
| Rodapé | Um único botão **`Fechar`** (sem Cancelar) |

**Toast na criação:** título "API Key criada", descrição "Copie a chave agora, ela não será exibida novamente."
**Toast de erro:** "Erro" / "Não foi possível criar a API Key".
**Toast ao copiar:** "Copiado!" / "API Key copiada para a área de transferência"; em falha do `navigator.clipboard`, "Erro" / "Não foi possível copiar".

**Limpeza ao fechar** (`closeCreateDialog`): zera `createDialogOpen`, `newKeyName` e `newlyCreatedKey`.

> **Risco de UX severo.** `DialogContent` fecha por **ESC e clique fora** (comportamento padrão do shadcn/ui, não sobrescrito aqui). No estágio 2, isso significa **perder o segredo irrecuperavelmente com um clique acidental**. O redesign deve travar o fechamento nesse estágio (`onPointerDownOutside`/`onEscapeKeyDown` com `preventDefault`) ou exigir confirmação explícita de "já copiei".
>
> Além disso, o estágio 2 **não repete o nome da chave** e não indica visualmente que a chave já foi copiada além do check de 2s.

### A7.7 Mecânica de criação

`useCreateApiKey` chama a RPC `create_api_key(p_name)` (SECURITY DEFINER). Assinatura nova, **sem `role` e sem `organization_id`** — a key é universal. A RPC gera a chave no servidor, persiste apenas o **hash**, e devolve uma `TABLE` de uma linha `{ id, key, key_prefix }`. Se `row.key` vier vazio, o hook lança `"RPC create_api_key nao retornou key"`. Invalida `["api-keys"]` no sucesso.

### A7.8 Remoção — soft-delete

**Gatilho:** ícone de lixeira na linha da tabela → `setDeleteKeyId(apiKey.id)`.

**Modal:** `AlertDialog` (aberto por `!!deleteKeyId`):

| Elemento | Conteúdo |
|---|---|
| Título | "Remover API Key?" |
| Descrição | "Esta ação não pode ser desfeita. Sistemas que usam esta chave perderão acesso imediatamente." |
| `AlertDialogCancel` | "Cancelar" |
| `AlertDialogAction` | "Remover", com `className="bg-destructive text-destructive-foreground hover:bg-destructive/90"`; mostra `Loader2` enquanto `deleteApiKey.isPending` |

**O que acontece de fato:** `useDeactivateApiKey` (exportado também como alias `useDeleteApiKey`) faz `UPDATE api_keys SET is_active = false WHERE id = ?`. **Nunca `DELETE` físico** — por design, para preservar histórico. A chave some da lista porque o filtro só mostra ativas.

**Toasts:** sucesso → "API Key removida" / "A chave foi removida com sucesso". Erro → "Erro" / "Não foi possível remover a API Key". O `finally` sempre limpa `deleteKeyId`.

> **Divergência texto × comportamento.** A descrição diz "Esta ação não pode ser desfeita", mas o registro **permanece no banco** com `is_active = false`. Do ponto de vista do usuário a frase é verdadeira (não há UI de reativação), mas o redesign poderia expor uma visão "Chaves revogadas" — a informação existe.
>
> **Falta de identificação no diálogo.** O `AlertDialog` **não mostra o nome da chave** que será revogada. Com várias chaves na tabela, o risco de revogar a errada é real.

---

## A8. Catálogo de tipos de integração e variáveis disponíveis

### A8.1 Os 10 tipos de integração

Fonte: `src/lib/constants/integration-types.ts` + `TYPE_ICONS` em `src/pages/IntegrationsPage.tsx`.

| Chave | Rótulo | Cor do badge | Descrição (constante) | Ícone declarado (`icon`) | **Ícone renderizado** (`TYPE_ICONS`) |
|---|---|---|---|---|---|
| `whatsapp` | WhatsApp | `bg-green-100 text-green-800` | Envio de mensagens via WhatsApp | `MessageSquare` | **`MessageCircle`** |
| `email` | E-mail | `bg-blue-100 text-blue-800` | Envio de emails | `Mail` | `Mail` |
| `rcs` | RCS | `bg-teal-100 text-teal-800` | Mensagens ricas (RCS): imagem, texto e botões | `Smartphone` | `Smartphone` |
| `sms` | SMS | `bg-purple-100 text-purple-800` | Envio de mensagens SMS | `MessageCircle` | **`MessageSquare`** |
| `voice` | Voz/TTS | `bg-orange-100 text-orange-800` | Ligações de voz (TTS/Bot) | `Phone` | `Phone` |
| `human_activity` | Atividade Humana | `bg-cyan-100 text-cyan-800` | Tarefas manuais para atendentes | `User` | `User` |
| `negativation` | Negativação | `bg-red-100 text-red-800` | Serviços de negativação (Serasa, SPC) | `AlertCircle` | **`AlertTriangle`** |
| `block` | Bloqueio | `bg-amber-100 text-amber-800` | Bloqueio de serviços ou contas | `Ban` | `Ban` |
| `notification` | Notificação | `bg-yellow-100 text-yellow-800` | Notificação extrajudicial ou formal | `FileWarning` | `FileWarning` |
| `webhook` | Webhook | `bg-gray-100 text-gray-800` | Integrações via HTTP webhook | `Webhook` | `Webhook` |

> **Três divergências de ícone** (WhatsApp, SMS, Negativação) entre a constante e o mapa efetivo. Como `TYPE_ICONS` é o que renderiza, WhatsApp aparece com balão redondo e SMS com balão quadrado — o inverso do declarado. O redesign deve unificar a fonte (**um só mapa**).
>
> **Cores só em modo claro.** A paleta `bg-*-100 text-*-800` é fixa, **sem variante `dark:`**. No tema escuro os quadrados de ícone ficam claros sobre fundo escuro. Ver C4.
>
> **Ordem.** A ordem dos filtros e do `Select` de tipo segue a ordem de declaração do objeto (WhatsApp → E-mail → RCS → SMS → Voz → Atividade Humana → Negativação → Bloqueio → Notificação → Webhook). Note que a **descrição** de cada tipo existe na constante mas **não é exibida em lugar nenhum da UI** — nem como tooltip no `Select`, nem no card. Oportunidade barata de melhoria.

### A8.2 Catálogo de variáveis estáticas (`INTEGRATION_VARIABLES`)

Fonte: `src/lib/constants/integration-variables.ts`. Contrato declarado no topo do arquivo: *"ONLY variables that are actually resolved by the send-message edge function"* — variável resolvida pelo `send-message` que não esteja listada aqui é funcionalidade invisível.

#### Categoria `contato` (9)

| Chave | Rótulo | Descrição | Exemplo |
|---|---|---|---|
| `contact.name` | Nome do Cliente | Nome completo do cliente | João Silva Santos |
| `contact.first_name` | Primeiro Nome | Primeiro nome do cliente | João |
| `contact.document` | Documento (CPF/CNPJ) | Documento do cliente | 123.456.789-00 |
| `contact.phone` | Telefone | Telefone principal | 11999887766 |
| `contact.email` | E-mail | Email do cliente | joao.silva@email.com |
| `contact.tags` | Tags | Tags associadas ao cliente | VIP, Recorrente |
| `contact.id` | ID do Contato | Identificador único do contato | contact-uuid-1234 |
| `contact.trading_name` | Razão Social / Nome Fantasia | Nome fantasia ou razão social (CNPJ) | Loja do João ME |
| `contact.has_pnp` | Tem PNP no Cliente | Cliente tem ≥1 contrato com parcela PNP (Primeira Não Paga) vigente | Sim |

#### Categoria `titulo` (9)

| Chave | Rótulo | Descrição | Exemplo |
|---|---|---|---|
| `title.number` | Número do Título | Identificador do título | TIT-2024-001234 |
| `title.original_value` | Valor Original | Valor original do título | 1.500,00 |
| `title.current_value` | Valor Atual | Valor atualizado com juros/multa | 1.725,50 |
| `title.due_date` | Data de Vencimento | Data de vencimento | 15/12/2024 |
| `title.days_overdue` | Dias em Atraso | Dias desde o vencimento | 35 |
| `title.status` | Status do Título | Status atual | Em Aberto |
| `title.pix_key` | Chave PIX do Título | Chave PIX para pagamento | empresa@pix.com |
| `title.boleto_digitable_line` | Linha Digitável do Boleto | Linha digitável | 23793.38128 60000… |
| `title.id` | ID do Título | Identificador único | title-uuid-1234 |

#### Categoria `contrato` (15)

| Chave | Rótulo | Observação |
|---|---|---|
| `contract.number` | Número do Contrato | CTR-2024-5678 |
| `contract.modality` | Modalidade | Crédito Pessoal |
| `contract.status` | Status do Contrato | Ativo |
| `contract.start_date` | Data de Início | 01/01/2024 |
| `contract.end_date` | Data de Término | 01/01/2026 |
| `contract.id` | ID do Contrato | contract-uuid-1234 |
| `contract.safra_days` | Dias de Safra | Dias desde a Data Safra; **suporta negativos** (safra futura) |
| `contract.has_pnp` | Tem PNP no Contrato | ≥1 parcela PNP vigente |
| `contract.min_open_installment` | 1ª Parcela em Aberto | Menor `installment_number` entre títulos **Disponível/Recomprado/Expirado** sem pagamento |
| `contract.min_open_installment_disponivel` | 1ª Parcela Disponivel | Status `Disponivel` (aceita legados `overdue` e `vencido` minúsculos) |
| `contracts_list` | Lista de Contratos (números) | Números separados por vírgula |
| `contracts_list_detailed` | Lista de Contratos (todos em aberto) | Todos os títulos em aberto, agrupados por contrato |
| `contracts_list_disponivel` | Contratos com Títulos Disponíveis/Recomprado/Expirado | Vencidos ou a vencer em até 10 dias |
| `contracts_overdue_list` | Contratos com Títulos Vencidos | Vencidos ou a vencer 10 dias, qualquer status ativo |
| `contracts_and_supplies_list_disponivel` | Contratos **E** Suprimentos com Títulos Cobráveis | IAF-6140 + Quimera 6910 — as duas carteiras na mesma lista, bloco vertical por parcela, teto de 10 parcelas por carteira mas total somando **todas** |

#### Categoria `suprimento` (10)

| Chave | Rótulo |
|---|---|
| `supply.number` | Número do Suprimento |
| `supply.status` | Status do Suprimento |
| `supply.total` | Valor Total do Suprimento |
| `supply_title.number` | Número da Parcela de Suprimento |
| `supply_title.original_value` | Valor Original do Título de Suprimento |
| `supply_title.current_value` | Valor Atual do Título de Suprimento |
| `supply_title.due_date` | Vencimento do Título de Suprimento |
| `supply_title.days_overdue` | Dias em Atraso (Suprimento) |
| `supply_title.status` | Status do Título de Suprimento |
| `supply_title.pix_key` | Chave PIX do Título de Suprimento |
| `supply_title.boleto_digitable_line` | Linha Digitável do Boleto (Suprimento) |

*(11 entradas — `supply.*` 3 + `supply_title.*` 8.)*

#### Categoria `financeiro` (11)

| Chave | Rótulo | Observação |
|---|---|---|
| `total_debt` | Valor Total da Dívida | Soma dos valores atualizados de **todos** os títulos em aberto (inclui a vencer) |
| `days_overdue` | Dias em Atraso (Max) | Maior atraso entre todos os títulos |
| `oldest_due_date` | Vencimento Mais Antigo | — |
| `titles_count` | Quantidade de Títulos | — |
| `original_value` | Valor Original Total | — |
| `updated_value` | Valor Atualizado Total | Com juros/multa, inclui a vencer |
| `overdue_debt` | Valor Total Vencido | **Apenas** títulos vencidos |
| `titles_list` | Lista de Títulos | Valores atualizados |
| `titles_list_original` | Lista de Títulos (Valor Original) | Sem juros/multa |
| `total_debt_original` | Dívida Total (Valor Original) | — |

*(10 entradas.)*

#### Categoria `carteira` (3)

| Chave | Rótulo | Exemplo |
|---|---|---|
| `portfolio.name` | Nome da Carteira | Carteira Premium |
| `portfolio.code` | Código da Carteira | CART-001 |
| `portfolio.id` | ID da Carteira | portfolio-uuid-1234 |

> ⚠️ A confirmar: o `CLAUDE.md` do repositório (regra 34) registra que `portfolios.code` é **coluna que nunca existiu**, deixando `{{portfolio.*}}` vazio em toda mensagem por ~6 meses até o card 6325. A entrada `portfolio.code` permanece no catálogo; se a correção não repôs a coluna, essa variável continua resolvendo vazio.

#### Categoria `pagamento` (10)

| Chave | Rótulo |
|---|---|
| `payment_link` | Link de Pagamento (PIX ou Boleto) |
| `pix_link` | Link do PIX |
| `pix_code` | Código PIX Copia e Cola |
| `pix_key` | Chave PIX |
| `boleto_link` | Link do Boleto |
| `boleto_barcode` | Código de Barras |
| `payment_value` | Valor do Pagamento (atualizado) |
| `payment_value_original` | Valor Original do Pagamento |
| `payment_date` | Data do Pagamento (limite) |
| `titles_list_with_links` | Lista de Títulos com Links |

#### Categoria `sistema` (3)

| Chave | Rótulo | Exemplo |
|---|---|---|
| `current_date` | Data Atual | 19/01/2026 |
| `current_time` | Hora Atual | 14:30 |
| `organization_name` | Nome da Organização | Empresa Exemplo LTDA |

#### Categoria `organizacao` (2)

| Chave | Rótulo | Exemplo |
|---|---|---|
| `org.slug` | Slug da Organização | blips |
| `org.name` | Nome da Organização | Blips Cobrança |

#### Categoria `acao` (1)

| Chave | Rótulo | Regra |
|---|---|---|
| `action.recipient` | Destinatário Resolvido da Ação | Endereço que o motor **de fato** resolveu e gravou em `actions.recipient`. **Não** é resolvida no corpo/assunto (sairia literal); só no Body Template (contexto `integration_payload`). Alias aceito: `action_recipient` |

#### Rótulos de categoria na UI (`VARIABLE_CATEGORY_LABELS`)

| Chave | Rótulo exibido |
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

*(As duas últimas só existem no mapa de rótulos — são categorias produzidas dinamicamente pelo hook `useVariables`, não pelo catálogo estático. Nota: "Variaveis Personalizadas" está **sem acento** no código.)*

### A8.3 O seletor de variáveis (`InputWithVariables`)

**Arquivo:** `src/components/integrations/InputWithVariables.tsx`

| Comportamento | Detalhe |
|---|---|
| **Gatilho** | Digitar `{{` abre o painel de sugestões. A query é o texto entre `{{` e o cursor; fecha se já houver `}}` no trecho |
| **Fonte** | `useVariables({ context: variableContext, includeCustomFields: true })` |
| **Filtro** | Case-insensitive sobre `key`, `label` **e** `category` |
| **Agrupamento** | Por categoria, com cabeçalho `sticky top-0 bg-popover`, `text-xs font-semibold uppercase tracking-wider text-muted-foreground` |
| **Rótulo do grupo** | `VARIABLE_CATEGORY_LABELS[category] || category` — fonte única (antes havia um mapa local incompleto que exibia slugs crus como "campos_customizados") |
| **Item** | `div font-medium` com o `label` + linha `text-xs` "Ex: `<example>`" quando houver |
| **Seleção ativa** | `bg-primary text-primary-foreground`; o exemplo vira `text-primary-foreground/80` |
| **Painel** | `absolute z-[100] top-full mt-1 w-[320px] bg-popover border rounded-md shadow-lg`, lista com `max-h-[250px] overflow-y-auto p-1` |
| **Inserção** | Substitui de `{{` até o cursor por `{{chave}}` completo |
| **Fechamento** | Clique fora (listener global de `mousedown`) ou `Escape` |

**Navegação por teclado:**

| Tecla | Ação |
|---|---|
| `ArrowDown` | Próximo item (circular) |
| `ArrowUp` | Item anterior (circular) |
| `Enter` | Insere o selecionado |
| `Tab` | Insere o selecionado |
| `Escape` | Fecha o painel |

> **Falha de acessibilidade a corrigir no redesign.** O painel é um `div` com `button`s, **sem** `role="listbox"`/`role="option"`, sem `aria-activedescendant`, sem `aria-expanded` no input. Leitores de tela não anunciam as sugestões. Além disso, o item selecionado **não faz scroll into view** — navegar com setas além do 8º item esconde a seleção. Ver C4.

### A8.4 `VariableHighlightTextarea`

**Arquivo:** `src/components/integrations/VariableHighlightTextarea.tsx`

Wrapper fino de `RichVariableInput` (`src/components/ui/rich-variable-input.tsx`) com `showPreview={false}` e `rows` default `6`. Repassa `value`, `onChange`, `placeholder`, `disabled`, `className`. É o editor do modo JSON do `BodyEditor` (lá com `rows={8}`).

---

## A9. Estados da tela e fluxos de uso

### A9.1 Estados da página

| # | Condição | Render |
|---|---|---|
| 1 | `!currentOrg` | Tela inteira: `flex h-full flex-col items-center justify-center` com `Puzzle h-12 w-12 text-muted-foreground mb-4` + `h2 text-xl font-semibold` "Nenhuma organização selecionada". **Sem botão de ação** |
| 2 | `isLoading` | Spinner centralizado `py-12` |
| 3 | `isFetching` (refetch) | Só o ícone do `RefreshButton` gira; a grade continua visível |
| 4 | Lista vazia | Estado vazio com CTA condicional (A3.6) |
| 5 | Lista preenchida | Grade responsiva de cards |
| 6 | Sem permissão de escrita | Cards sem Switch, sem Editar, sem Remover; header sem "Nova Integração"; estado vazio sem CTA |
| 7 | Não super admin | Aba "API Keys" inexistente |

**Ausente: estado de erro.** Se `useOrgIntegrations` falhar (`throw new Error("Failed to fetch integrations")`), a página **não trata `isError`** — cai no estado vazio "Nenhuma integração configurada", que é **mentiroso**: sugere que não há integração quando, na verdade, não foi possível carregar. Correção obrigatória no redesign.

### A9.2 Estados do Construtor

| Estado | Sinal visual |
|---|---|
| Criação | Título "Nova Integração"; campos com defaults; aba Testar bloqueada |
| Edição | Título "Editar Integração"; campos preenchidos; credenciais vazias; aba Testar liberada |
| Inválido | `Select` de tipo com borda destrutiva + mensagem; botão Salvar desabilitado |
| Salvando | `Loader2` no botão Salvar; botão desabilitado |
| Erro ao salvar | Toast destrutivo; Sheet permanece aberto com os dados |

### A9.3 Estados do painel de teste

Progressão em cascata — cada seção só aparece quando a anterior foi resolvida:

```
(vazio) → contato selecionado → dados carregados → título selecionado
        → [WhatsApp: template Meta] → overrides → disparo → resultado
```

| Estado | Sinal |
|---|---|
| Buscando contato | Spinner + "Buscando..." no popover |
| Erro de busca | `p role="alert"` destrutivo dentro da lista |
| Carregando contato | Spinner + "Carregando dados do contato..." no cartão-resumo |
| Contato sem títulos | `Alert` "Este contato nao possui titulos pendentes." + disparo indisponível |
| Enviando | Botão com `Loader2` e rótulo "Enviando..."; "Limpar" desabilitado |
| Sucesso | Banner verde + tempo + destinatário + blocos colapsáveis |
| Falha | Banner destrutivo + `errorMessage` |

### A9.4 Fluxos de uso passo a passo

#### Fluxo A — Criar a primeira integração (WhatsApp)

1. Menu lateral → **Integrações**.
2. Estado vazio → clicar **"Criar Primeira Integração"**.
3. Sheet abre na aba **Geral**. Selecionar **Tipo = WhatsApp** (a borda destrutiva do Select some).
4. *(atalho)* Clicar **Importar cURL**, colar o comando do provedor, **Analisar**, conferir o preview verde, **Importar Configuração**. → URL, método, headers, body e auth preenchidos. **Atenção:** conferir se o `x-org-slug` sobreviveu (ver A5.6).
5. Preencher **Nome da Integração** (obrigatório) e, opcionalmente, **Descrição** e **URL de Visualização Externa**.
6. Revisar **Headers**: `Content-Type: application/json` e `x-org-slug: {{org.slug}}` (travado).
7. Ajustar o **Body Template**: no modo Campos, remover as chaves que o provedor não aceita; usar `{{` para inserir variáveis. Abrir **"Preview com dados de exemplo"** para conferir o JSON final.
8. Aba **Autenticação**: escolher o tipo, digitar a credencial (olho para conferir). Ler o aviso 🔒.
9. Deixar **"Integração Ativa"** desligado enquanto valida (recomendação do guia).
10. **Salvar** → toast "Integração configurada com sucesso"; Sheet fecha; card aparece na grade.

#### Fluxo B — Testar antes de colocar em produção

1. No card, clicar **Editar**.
2. Ir à aba **Testar**.
3. Buscar um contato (nome, documento, telefone, contrato ou e-mail; mínimo 2 caracteres).
4. Conferir o cartão-resumo (telefone/e-mail/quantidade de títulos).
5. Escolher o título — o mais atrasado já vem marcado.
6. *(WhatsApp)* Escolher um template Meta aprovado e mapear `{{1}}`, `{{2}}`…
7. *(opcional)* Sobrescrever telefone/e-mail/assunto/conteúdo — cada campo editado ganha badge laranja "editado".
8. **Enviar Teste**.
9. Ler o banner de resultado; expandir **Request Payload** e **Resposta do Provedor**; copiar o que precisar.
10. Se ok, voltar à aba Geral, ligar **"Integração Ativa"** e **Salvar**.

#### Fluxo C — Pausar um canal com problema

1. Localizar o card (usar o filtro de tipo se houver muitos).
2. Desligar o **Switch** no canto superior direito do card.
3. O badge vira "Inativo", a borda perde o destaque, e a mutation roda sem confirmação.
4. Nenhum toast de sucesso — **só há toast em erro**. A confirmação é puramente visual.

#### Fluxo D — Remover uma integração

1. Card → botão de **lixeira**.
2. `window.confirm("Tem certeza que deseja remover esta integração?")` — diálogo **nativo do browser**.
3. Confirmar → toast "Integração removida com sucesso".
4. Em falha (ex.: integração referenciada por régua), **dois toasts** de erro (A4.9).

#### Fluxo E — Emitir uma API Key (Super Admin)

1. Aba **API Keys** (só visível para Super Admin).
2. **Nova API Key** → nomear (ex.: "Integração ERP") → **Criar** (ou `Enter`).
3. Estágio 2: a chave completa aparece em `readOnly` monoespaçado → clicar **copiar** (`Copy` vira `Check` verde por 2s) → guardar em cofre.
4. **Fechar**. A chave nunca mais será exibida.
5. A tabela passa a mostrar a linha com nome, prefixo (`tc_xxxxxxx…`) e data/hora.
6. Entregar ao time externo as **duas** informações: `x-api-key` e `x-org-slug`.

#### Fluxo F — Revogar uma API Key

1. Aba **API Keys** → lixeira na linha.
2. `AlertDialog` "Remover API Key?" → **Remover**.
3. Toast "API Key removida". A linha some (soft-delete: `is_active = false`).

### A9.5 Validação de URL de webhook (capacidade não usada nesta tela)

`src/lib/webhook-url-validation.ts` implementa uma validação anti-SSRF completa e **pura**, escrita para a configuração de webhook do Playground do agente (PG.6 / IAF-3989). **Não é chamada pelo Construtor de integração** — o campo URL da integração aceita qualquer string.

Regras implementadas (úteis se o redesign quiser endurecer o campo URL):

| Regra | Rejeição |
|---|---|
| Esquema | Só `https:` — "A URL do webhook precisa usar HTTPS (https://)." |
| Credenciais embutidas | `user:pass@host` — "A URL do webhook não pode conter credenciais (usuário:senha@)." |
| IPv4 privado/reservado | `0/8`, `10/8`, `127/8`, `169.254/16`, `172.16–31`, `192.168/16`, `192.0.0/24`, `100.64/10` (CGNAT), `198.18/15`, `≥224` (multicast/reservado), octeto > 255 — "Endereço IP interno/privado não é permitido como webhook." |
| IPv6 interno | `::`, `::1`, `fe80::/10`, `fc00::/7`, IPv4-mapeado privado — "Endereço IPv6 interno não é permitido como webhook." |
| Hosts bloqueados | `localhost`, `localhost.localdomain`, `ip6-localhost`, `ip6-loopback` — "Host interno (localhost) não é permitido como webhook." |
| Sufixos internos | `.localhost`, `.local`, `.internal`, `.lan`, `.home`, `.corp`, `.intranet` — "Host de rede interna não é permitido como webhook." |
| Rótulo único / IP ofuscado | host sem ponto e não-IPv6 (ex.: `2130706433`, `0x7f000001`) — "Use um domínio público válido (ex.: https://n8n.suaempresa.com)." |

Em sucesso devolve `{ ok: true, url, host }` — o `host` existe justamente para a UI **mostrar ao usuário para onde os dados reais serão enviados** antes de confirmar. Padrão de confirmação que o redesign pode adotar no Construtor.

O próprio cabeçalho do módulo avisa que esta é a **primeira** linha de defesa, não a última (burlável por DNS rebinding/redirect) — a validação confiável precisa rodar também no servidor.

---

## PARTE B — CONFIGURAÇÕES

---

## B0. Identidade e mapa das abas

| Atributo | Valor |
|---|---|
| **Rota** | `/settings` |
| **Componente raiz** | `SettingsPage` — `src/pages/SettingsPage.tsx` |
| **Título na tela** | "Configuracoes" (`h1 text-3xl font-bold`), ícone `Settings h-8 w-8` |
| **Subtítulo** | "Gerencie as configuracoes da organizacao" |
| **Contextos** | `useOrganization()` → `currentOrg`, `hasPermission`, `pipelineProfile`, `isSuperAdmin`; `useAuth()` → `user` |
| **Aba inicial** | `"organization"` (estado `activeTab`, controlado) |
| **Sem organização** | Tela inteira substituída por `Settings h-12 w-12 text-muted-foreground` + `h2 text-xl font-semibold` "Nenhuma organizacao selecionada" |

> **Acentuação.** Praticamente todos os rótulos da tela de Configurações estão **sem acento** no código-fonte ("Configuracoes", "Organizacao", "Usuarios", "Reguas", "Relatorios", "Valores Padrao", "Variaveis", "Perfil da Operacao"). Não é decisão de design — é ASCII herdado. O redesign deve corrigir (é ganho gratuito de qualidade percebida).

### B0.1 Mapa das abas montadas em `SettingsPage`

Ordem exata de renderização no `TabsList`:

| # | `value` | Rótulo exibido | Ícone | Arquivo | Gate de visibilidade | O que configura |
|---|---|---|---|---|---|---|
| 1 | `organization` | Organizacao | `Building2` | `tabs/OrganizationTab.tsx` | sempre | Nome, slug, domínio personalizado, logo e cores (white label) |
| 2 | `standard-values` | Valores Padrao | `Tag` | `StandardValuesSettings.tsx` | sempre | Valores padrão de campos do sistema |
| 3 | `variables` | Variaveis | `Braces` | `tabs/CustomVariablesTab.tsx` | sempre | Variáveis personalizadas `{{var.X}}` — texto fixo, composta ou lista |
| 4 | `reguas` | Reguas | `Ruler` | `tabs/ReguasTab.tsx` | sempre | Configurações globais das réguas de cobrança |
| 5 | `aging` | Kanban | `LayoutGrid` | `tabs/AgingBucketsTab.tsx` | sempre | Faixas de atraso (aging buckets) exibidas no Kanban da Carteira |
| 6 | `costs` | Custos | `DollarSign` | `tabs/ChannelCostsTab.tsx` | sempre | Custo unitário por canal de comunicação |
| 7 | `blocked-dates` | Datas Bloqueadas | `CalendarOff` | `tabs/BlockedDatesTab.tsx` | sempre | Feriados e datas em que a Torre não dispara ações |
| 8 | `reports` | Relatorios | `CalendarClock` | `tabs/ReportSchedulesTab.tsx` | `hasPermission("settings:write")` | Agendamento de relatórios por e-mail + rotina da Torre |
| 9 | `tags` | Tags | `Tags` | `tabs/TagCatalogTab.tsx` | sempre (prop `canWrite = hasPermission("settings:write")`) | Catálogo de tags conversacionais/manuais de contato |
| 10 | `seals` | Selos | `Award` | `tabs/SealCatalogTab.tsx` | `hasPermission("seals:manage_catalog")` | Catálogo de selos e suas atribuições |
| 11 | `pipeline-profile` | Perfil da Operacao | `Workflow` | `tabs/PipelineProfileTab.tsx` | `isSuperAdmin \|\| (pipelineProfile !== null && hasPermission("settings:read"))` | Perfil de pipeline da org (`formalizacao`) e suas convenções de campo |
| 12 | `users` | Usuarios | `Users` | `tabs/UsersTab.tsx` | `hasPermission("users:read")` | Membros da org, papéis e convites |

### B0.2 Componentes do domínio **não montados** em `SettingsPage`

| Componente | Arquivo | Onde é usado |
|---|---|---|
| `FieldExplorerTab` | `tabs/FieldExplorerTab.tsx` | **Não importado por `SettingsPage`** — ver B13 |
| `SealAssignmentsList` | `tabs/SealAssignmentsList.tsx` | Usado **dentro** de `SealCatalogTab` (sub-componente) |
| `TowerReportRoutineCard` | `tabs/TowerReportRoutineCard.tsx` | Usado **dentro** de `ReportSchedulesTab` |
| `RolesPermissionsCard` | `RolesPermissionsCard.tsx` | Exporta `RolesPermissionsButton` + `RolesPermissionsModal`, usados **dentro** de `UsersTab` |
| `VariableDefinitionFields` | `VariableDefinitionFields.tsx` | Usado **dentro** de `CustomVariablesTab` |
| `VariablePreviewPanel` | `VariablePreviewPanel.tsx` | Usado **dentro** de `CustomVariablesTab` |
| `pipelineProfileForm` | `tabs/pipelineProfileForm.ts` | Módulo puro de validação usado por `PipelineProfileTab` |

### B0.3 Gate reativo do "Perfil da Operacao"

Regra em `SettingsPage` (IAF-6392/6390), reproduzida na íntegra porque muda a navegação:

```
canSeePipelineProfile = isSuperAdmin || (pipelineProfile !== null && hasPermission("settings:read"))
```

E um `useEffect` de segurança:
> Remover o perfil dentro da própria aba faz o gate virar falso para quem não é super admin. Sem o efeito, `activeTab` continuaria em `"pipeline-profile"` e a área de conteúdo ficaria **vazia**, sem aba selecionada e sem explicação. O efeito força o retorno a `"organization"`.

O redesign precisa manter esse **retorno automático** ao remover o perfil — é um caso real de aba que desaparece debaixo do usuário.

---

## B1. Anatomia visual da tela (navegação entre abas)

Container: `<div className="space-y-6">`.

**Cabeçalho** — `div` simples (sem ações à direita, ao contrário de Integrações): `h1` com ícone + título, e `p text-muted-foreground` com o subtítulo.

**`Tabs`** controlado (`value={activeTab}`, `onValueChange={setActiveTab}`).

**`TabsList className="flex-wrap h-auto"`** — os até 12 triggers **quebram em várias linhas**. Cada `TabsTrigger` tem `className="flex items-center gap-2"` com ícone `h-4 w-4` + rótulo textual.

**`TabsContent`** — todos com `className="mt-6"`.

### B1.1 Problemas estruturais da navegação (para o redesign)

| Problema | Descrição |
|---|---|
| **Escala** | 12 abas em uma `TabsList` que quebra linha. Em telas médias vira um bloco de 2–3 fileiras de pílulas; em mobile, uma parede de pílulas antes de qualquer conteúdo |
| **Sem agrupamento** | Não há hierarquia: "Organizacao" (identidade), "Custos" (financeiro), "Usuarios" (acesso) e "Perfil da Operacao" (motor) convivem no mesmo nível |
| **Sem rota por aba** | `activeTab` é estado local — **não há deep-link** (`/settings/users`), não há histórico de navegação, e recarregar a página sempre volta para "Organizacao" |
| **Rótulo ≠ conteúdo** | A aba chamada **"Kanban"** configura **Faixas de Atraso**; a aba **"Valores Padrao"** usa ícone `Tag` (o mesmo conceito visual de "Tags", que é outra aba) |
| **Sem busca** | Não há campo para "onde configuro X?" |
| **Abas que aparecem/somem** | 4 das 12 dependem de permissão/perfil — a lista muda de tamanho conforme quem entra |

Alternativa natural de redesign: **navegação lateral em duas colunas** (menu de seções à esquerda, conteúdo à direita) com rotas reais, agrupada em famílias como *Organização · Operação · Conteúdo · Acesso*.

---

## B2. Aba **Organizacao**

**Arquivo:** `src/components/settings/tabs/OrganizationTab.tsx`
**Hooks:** `useOrganizationSettings`, `useUpdateOrganization` (`src/hooks/useSettings.ts`)

### B2.1 Objetivo

Identidade da organização e personalização visual (white label): nome, domínio próprio, logo e cores da marca.

### B2.2 Permissões

`canEdit = hasPermission("settings:write")`. Sem permissão, **todos** os campos ficam `disabled` e o botão "Salvar Alteracoes" **não é renderizado**. A aba continua legível.

### B2.3 Anatomia

`div space-y-6` com **dois `Card`s** e um botão solto no fim.

#### Card 1 — "Informacoes da Organizacao"

Descrição: "Configure as informacoes basicas da organizacao". `CardContent space-y-4`.

| # | Campo | `id` | Controle | Editável | Placeholder | Texto de ajuda |
|---|---|---|---|---|---|---|
| 1 | Nome da Organizacao | `org-name` | `Input` | sim (se `canEdit`) | — | — |
| 2 | Slug (identificador unico) | `org-slug` | `Input` `disabled` + `className="bg-muted"` | **nunca** | — | "O slug nao pode ser alterado apos a criacao" |
| 3 | Dominio Personalizado | `custom-domain` | `Input` | sim | `app.suaempresa.com.br` | "Configure um dominio personalizado para acesso ao sistema" |

#### Card 2 — "Personalizacao Visual"

Descrição: "Personalize a aparencia do sistema (White Label)". `CardContent space-y-6`.

**Bloco Logo** (`space-y-4`), rótulo "Logo da Organizacao":

1. **Preview** (condicional a haver logo) — `div relative inline-block` com moldura `border rounded-lg p-4 bg-muted/50` e `img className="max-h-24 max-w-[200px] object-contain"`. Em erro de carregamento (`onError`), a imagem é **escondida** (`style.display = 'none'`) — ficando só a moldura vazia, sem mensagem.
   - Botão de remover (só se `canEdit`): `Button variant="destructive" size="icon"` posicionado `absolute -top-2 -right-2 h-6 w-6` com `X h-3 w-3`. **Sem confirmação** — limpa `logoUrl` e `previewUrl` no ato (a gravação só acontece no Salvar).

2. **Seletor de modo** — dois botões `size="sm"` lado a lado, atuando como toggle (o ativo usa `variant="default"`, o inativo `variant="outline"`):

   | Botão | Ícone | `logoMode` |
   |---|---|---|
   | "Enviar Imagem" | `Upload h-4 w-4 mr-2` | `upload` |
   | "URL Externa" | `Link h-4 w-4 mr-2` | `url` |

   **Default:** `"url"`.

3. **Modo `upload`** — `input type="file"` oculto (`className="hidden"`, `id="logo-upload"`) com `accept="image/jpeg,image/png,image/gif,image/webp,image/svg+xml"`. O gatilho visível é um `Button variant="outline" className="w-full border-dashed"`:
   - Ocioso: `ImageIcon h-4 w-4 mr-2` + "Clique para selecionar uma imagem"
   - Enviando: `Loader2 animate-spin` + "Enviando..."
   - Texto de ajuda: "Formatos aceitos: JPG, PNG, GIF, WebP, SVG. Tamanho maximo: 5MB."

4. **Modo `url`** — `Input id="logo-url"`, placeholder `https://exemplo.com/logo.png`. Digitar atualiza `logoUrl` **e** `previewUrl` simultaneamente (preview ao vivo). Ajuda: "Cole a URL de uma imagem hospedada externamente."

**Bloco Cores** — `grid grid-cols-2 gap-4`, **sempre 2 colunas** (não responsivo):

| Campo | `id` | Controles | Default |
|---|---|---|---|
| Cor Primaria | `primary-color` | `Input type="color" w-12 h-10 p-1` + `Input` de texto, lado a lado (`flex gap-2`), ambos ligados ao mesmo estado | `#000000` |
| Cor Secundaria | `secondary-color` | idem | `#666666` |

**Botão de salvar** — fora dos cards, `Button` solto no fim do `space-y-6`, só se `canEdit`. Texto "Salvar Alteracoes", com `Loader2` quando `updateOrg.isPending`.

### B2.4 Upload de logo — validações e mecânica

| Etapa | Detalhe |
|---|---|
| Tipos aceitos | `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `image/svg+xml` |
| Erro de tipo | **`alert()` nativo** — "Tipo de arquivo nao permitido. Use: JPG, PNG, GIF, WebP ou SVG." |
| Tamanho máximo | **5 MB** (`5 * 1024 * 1024`) |
| Erro de tamanho | **`alert()` nativo** — "Arquivo muito grande. Tamanho maximo: 5MB." |
| Destino | Supabase Storage, bucket **`organization-logos`** |
| Caminho | `${currentOrg.id}/logo-${Date.now()}.${ext}` |
| Opções | `cacheControl: "3600"`, `upsert: true` |
| Após upload | `getPublicUrl(data.path)` → grava em `logoUrl` **e** `previewUrl` |
| Erro de upload | `logError(...)` + **`alert()` nativo** "Erro ao fazer upload da imagem. Tente novamente." |
| Limpeza | `fileInputRef.current.value = ''` no `finally` (permite reenviar o mesmo arquivo) |

> **Três `alert()` nativos** nesta aba. Destoam completamente do sistema de `toast` usado no resto da Torre. Substituição obrigatória no redesign.

### B2.5 Bugs de inicialização de estado (críticos)

O código usa **`useState(() => {...})`** para inicializar o formulário:

```
useState(() => {
  if (settings) { setName(settings.name); ... }
});
```

Isso **não é um efeito** — é o inicializador preguiçoso do `useState`, que roda **uma única vez no primeiro render**, quando `settings` ainda é `undefined` (a query não resolveu). **Portanto o bloco nunca preenche os estados.** Deveria ser `useEffect([settings])`.

Consequências visíveis, que o redesign precisa corrigir e não replicar:

| Sintoma | Mecanismo |
|---|---|
| Campos parecem preenchidos | Porque o `value` tem fallback duplo: `value={name \|\| settings?.name \|\| ""}` |
| **Apagar o campo não funciona** | Zerar o texto faz `name` virar `""`, que é falsy → o fallback volta a exibir `settings?.name`. O usuário não consegue esvaziar Nome, Domínio nem as cores |
| Logo não é pré-carregado no estado | `logoUrl` fica `""`; a exibição vem de `currentLogoUrl = previewUrl \|\| logoUrl \|\| settings?.logo_url` |
| **Salvar sem tocar em nada apaga dados** | `handleSave` envia os **estados**, não os fallbacks: `custom_domain: customDomain \|\| null`, `primary_color: primaryColor \|\| null`, `logo_url: logoUrl \|\| null`. Como os estados nunca foram inicializados, clicar em "Salvar Alteracoes" após editar **só o nome** grava `null` em domínio, cores **e logo** |

⚠️ A confirmar: se a mutation `useUpdateOrganization` (que faz `UPDATE organizations SET ... WHERE id`) é mesmo destrutiva nesse cenário — a leitura do código indica que sim, pois envia explicitamente `null`.

### B2.6 Persistência

`useUpdateOrganization` → `supabase.from("organizations").update(data).eq("id", currentOrg.id)`. No sucesso, invalida `["organization"]` **e** chama `refreshOrganizations()` do contexto (para o header/sidebar refletirem nome e logo novos).

**Nenhum toast de sucesso.** O único feedback é `setPreviewUrl(null)` e o botão parar de girar.

### B2.7 Estados

| Estado | Render |
|---|---|
| Carregando | `flex items-center justify-center py-12` com `Loader2 h-8 w-8 animate-spin` — substitui a aba inteira |
| Somente leitura | Campos `disabled`, sem botão Salvar, sem botão de remover logo, sem seletor de modo ativo |
| Enviando logo | Botão de upload com spinner e "Enviando..." |
| Salvando | `Loader2` no botão Salvar |
| Erro de logo quebrado | Imagem escondida, moldura vazia — **sem mensagem** |

---

## B3. Aba **Usuarios** (usuários e convites)

**Arquivo:** `src/components/settings/tabs/UsersTab.tsx`
**Hooks:** `useOrganizationUsers`, `useUpdateUserRole`, `useRemoveUser`, `useInvitations`, `useCreateInvitation`, `useCancelInvitation`, `useResendInvitation` (`src/hooks/useSettings.ts`)

### B3.1 Objetivo

Gerir quem tem acesso à organização: listar membros, alterar papel, remover, e administrar convites pendentes (enviar, reenviar, cancelar).

### B3.2 Permissões

| Gate | Efeito |
|---|---|
| `hasPermission("users:read")` | A aba inteira só existe com essa permissão (gate em `SettingsPage`) |
| `canInvite = hasPermission("users:invite")` | Mostra o botão "Convidar Usuario" **e** o card inteiro de "Convites Pendentes" |
| `currentRole === "owner"` | Pode editar e remover **qualquer** usuário exceto a si mesmo; no diálogo de edição vê **os 5 papéis** (`ALL_ROLES`, incluindo Proprietario) |
| `currentRole === "admin"` | Pode editar/remover **não-owners**, exceto a si mesmo; no diálogo vê 4 papéis (`ROLES`, sem Proprietario) |
| `currentRole === "manager"` | No diálogo de convite vê **3 papéis** (`ROLES_FOR_MANAGER`: Gerente, Operador, Visualizador — sem Administrador) |
| — | **Ninguém** vê botões de ação na própria linha (`orgUser.user_id !== currentUserId`) |

### B3.3 Catálogo de papéis (`ROLE_CONFIG`)

| Valor | Rótulo | Ícone | Cor (badge sólido) | Descrição |
|---|---|---|---|---|
| `owner` | Proprietario | `Crown` | `bg-amber-500 text-white` | Controle total da organizacao, incluindo exclusao |
| `admin` | Administrador | `Shield` | `bg-red-500 text-white` | Gerencia usuarios, configuracoes e todos os dados |
| `manager` | Gerente | `UserCog` | `bg-blue-500 text-white` | Acesso completo aos dados, configuracoes limitadas |
| `operator` | Operador | `Users` | `bg-green-500 text-white` | Executa acoes e visualiza dados operacionais |
| `viewer` | Visualizador | `Eye` | `bg-gray-500 text-white` | Apenas visualizacao, sem permissao de alteracao |

> **Nota:** as cores de `ROLE_CONFIG` **não são usadas** no `RoleBadge` — ele usa `getRoleBadgeVariant(role)`, que mapeia para variantes do shadcn: `owner → "default"`, `admin → "destructive"`, `manager → "secondary"`, demais → `"outline"`. O campo `color` fica morto. Fonte de verdade duplicada e dessincronizada — unificar no redesign.
>
> A `description` vira o `title` (tooltip nativo) do badge.

**Listas de papéis disponíveis:**

| Constante | Onde vive | Conteúdo |
|---|---|---|
| `ROLES` | `useSettings.ts` | admin, manager, operator, viewer (4) |
| `ROLES_FOR_MANAGER` | `useSettings.ts` | manager, operator, viewer (3) |
| `ALL_ROLES` | `UsersTab.tsx` (local) | owner, admin, manager, operator, viewer (5) |

### B3.4 Card 1 — "Usuarios"

**`CardHeader`** — `flex flex-row items-center justify-between`:
- Esquerda: `CardTitle` "Usuarios" + `CardDescription` "Gerencie os usuarios da organizacao".
- Direita (`flex items-center gap-2`): `RolesPermissionsButton variant="outline"` (ver B4) + `Button` "Convidar Usuario" com `UserPlus h-4 w-4 mr-2` (só se `canInvite`).

**Tabela de membros:**

| Coluna | Largura | Conteúdo |
|---|---|---|
| **Usuario** | auto | Duas linhas: `full_name \|\| email.split("@")[0] \|\| "Usuario"` (`font-medium`) e, abaixo, `email \|\| user_id` (`text-sm text-muted-foreground`) |
| **Role** | auto | `RoleBadge` — ícone `h-3 w-3` + rótulo, com `title` = descrição do papel |
| **Desde** | auto | `new Date(created_at).toLocaleDateString("pt-BR")` (`text-muted-foreground`) |
| *(ações)* | `w-[100px]` | Cabeçalho **vazio**; células com até 2 `Button variant="ghost" size="icon"` |

Botões de ação (ambos com o mesmo gate `orgUser.user_id !== currentUserId && (currentRole === "owner" || (currentRole === "admin" && orgUser.role !== "owner"))`):

| Botão | Ícone | `title` | Ação |
|---|---|---|---|
| Editar | `Pencil h-4 w-4` | "Editar usuario" | Abre `EditUserDialog` |
| Remover | `Trash2 h-4 w-4 text-destructive` | "Remover usuario" | `window.confirm("Tem certeza que deseja remover este usuario?")` → `removeUser` |

**Ordenação:** `created_at` descendente (mais recente primeiro), via `useOrganizationUsers`. Fonte: view `organization_users_with_email`.

**Estados do card:**

| Estado | Render |
|---|---|
| Carregando | `Loader2 h-8 w-8 animate-spin` centralizado, `py-8` |
| **Erro** | `AlertCircle h-12 w-12 text-destructive opacity-70` + "Erro ao carregar usuarios" (`font-medium text-foreground`) + "Nao foi possivel carregar a lista de usuarios." + `Button variant="outline"` com `RefreshCw` e texto "Tentar novamente" (`refetchUsers()`) |
| Vazio | `Users h-12 w-12 opacity-50` + "Nenhum usuario encontrado" + "Convide usuarios para fazer parte da organizacao." |
| Preenchido | Tabela |

> **Esta é a única aba do sistema com tratamento explícito de erro + botão de retry.** É o padrão de referência que o redesign deve propagar para as demais (Integrações inclusive — ver A9.1).

### B3.5 Card 2 — "Convites Pendentes"

Renderizado **só se `canInvite`**. `CardTitle` com `Mail h-5 w-5` + "Convites Pendentes"; descrição "Convites enviados aguardando aceitacao".

| Coluna | Largura | Conteúdo |
|---|---|---|
| **E-mail** | auto | `invitation.email` (`font-medium`) |
| **Role** | auto | `Badge variant="outline"` com `ROLES.find(...)?.label \|\| role` |
| **Expira em** | auto | `Clock h-3 w-3` + data `pt-BR`; se expirado, o texto ganha `text-destructive` e o sufixo **" (expirado)"** |
| *(ações)* | `w-[120px]` | Dois `Button variant="ghost" size="icon"` |

| Botão | Ícone | `title` | Ação |
|---|---|---|---|
| Reenviar | `RefreshCw h-4 w-4` (ou `Loader2` girando enquanto `resendingId === invitation.id`) | "Reenviar convite" | Gera novo token + nova expiração + reenvia e-mail |
| Cancelar | `Trash2 h-4 w-4 text-destructive` | "Cancelar convite" | `window.confirm("Tem certeza que deseja cancelar este convite?")` → `DELETE` |

**Estados:** carregando (`Loader2`), vazio (`Mail h-12 w-12 opacity-50` + "Nenhum convite pendente"), preenchido (tabela).

**Fonte:** `user_invitations` filtrado por `organization_id` e `status = "pending"`, ordenado por `created_at` desc.

> **Convite expirado continua listado.** O hook filtra por `status = "pending"`, não por data — o registro só muda de status quando aceito ou apagado. O sinal de expirado é puramente visual (texto vermelho + sufixo). Isso é bom: permite reenviar. Mas o redesign deveria destacar melhor, com badge próprio.

### B3.6 Modal **Convidar Usuario** (`InviteUserDialog`)

| Item | Detalhe |
|---|---|
| Objetivo | Enviar convite por e-mail para alguém entrar na organização |
| Gatilho | Botão "Convidar Usuario" no header do card de usuários |
| Container | `Dialog` → `DialogContent max-w-md` |
| Título | "Convidar Usuario" |
| Descrição | "Envie um convite para um novo usuario fazer parte da organizacao." |
| Envolvente | `<form onSubmit>` — permite submit por `Enter` |

**Campos:**

| # | Campo | `id` | Controle | Obrigatório | Placeholder / opções |
|---|---|---|---|---|---|
| 1 | E-mail | `invite-email` | `Input type="email" required` | sim (nativo) | `usuario@exemplo.com` |
| 2 | Role | `invite-role` | `Select` | — (default `operator`) | `ROLES` ou `ROLES_FOR_MANAGER` conforme `currentRole` |

Cada `SelectItem` renderiza **duas linhas**: `p font-medium` com o rótulo e `p text-xs text-muted-foreground` com a descrição do papel.

**Rodapé:** `Cancelar` (outline, `type="button"`) + `Enviar Convite` (`type="submit"`, com `Loader2` enquanto `createInvitation.isPending`).

**Validações e regras de negócio** (todas no hook `useCreateInvitation`, executadas **antes** do insert):

| # | Regra | Mensagem de erro |
|---|---|---|
| 1 | Normaliza o e-mail (`trim().toLowerCase()`) para comparação, insert e envio | — |
| 2 | Bloqueia se o e-mail **já é membro** (consulta `organization_users_with_email`) | **"Esse usuário já é membro desta organização."** |
| 3 | Bloqueia se já há convite `pending` para o mesmo e-mail + org (via `ilike` com escape de `%` e `_`) | **"Já existe um convite pendente para este e-mail. Use Reenviar."** |
| 4 | Expiração: **7 dias** a partir de agora | — |
| 5 | Token: `crypto.randomUUID()` | — |

**Efeito colateral:** invoca a Edge Function `send-invitation-email` com `{ email, organizationName, inviterName, role, token }`. **Falha de e-mail não derruba o convite** — é logada e ignorada (*"Don't throw - invitation was created, email just failed"*).

> **Ponto de UX perigoso.** Se o e-mail falhar, o usuário vê o toast de sucesso **"Convite enviado!"** mesmo sem e-mail nenhum ter saído. O convite fica pendente na lista e a única saída é "Reenviar". O redesign deveria diferenciar "convite criado" de "e-mail entregue".

**Toasts:**
- Sucesso: "Convite enviado!" / "Um email de convite foi enviado para `<email>`"
- Erro: "Erro ao enviar convite" / `error.message` ou "Ocorreu um erro ao criar o convite. Tente novamente."

Após sucesso: limpa e-mail, volta o papel para `operator` e fecha o modal.

### B3.7 Modal **Editar Usuario** (`EditUserDialog`)

| Item | Detalhe |
|---|---|
| Objetivo | Alterar o papel de um membro |
| Gatilho | Ícone de lápis na linha da tabela |
| Container | `Dialog` → `DialogContent max-w-md`; abre por `open={!!user}` |
| Título | "Editar Usuario" |
| Descrição | "Altere o role e as permissoes do usuario." |

**Bloco de identificação** — `flex items-center gap-4 p-4 bg-muted/50 rounded-lg`:
- Avatar genérico: `div h-12 w-12 rounded-full bg-primary/10` com `Users h-6 w-6 text-primary`.
- `p font-medium` com `full_name || email.split("@")[0] || "Usuario"`; `p text-sm text-muted-foreground` com o e-mail.

**Seletor de papel** — **não é um `Select`**: é uma lista de cartões clicáveis (`grid gap-2`), um por papel disponível. Cada cartão é um `<button type="button">` `flex items-center gap-3 p-3 rounded-lg border text-left transition-colors`:

| Parte | Selecionado | Não selecionado |
|---|---|---|
| Borda/fundo | `border-primary bg-primary/5` | `border-border hover:border-primary/50 hover:bg-muted/50` |
| Quadrado do ícone | `bg-primary/10` | `bg-muted` |
| Ícone | `text-primary` | `text-muted-foreground` |
| Rótulo | `font-medium text-primary` | `font-medium` |
| Marcador | `div h-2 w-2 rounded-full bg-primary` à direita | ausente |

Sempre com a descrição do papel abaixo (`text-xs text-muted-foreground`).

**Aviso de promoção a Proprietário** — só quando `currentRole === "owner"` e `selectedRole === "owner"`:
`flex items-start gap-2 p-3 bg-amber-500/10 border border-amber-500/20 rounded-lg text-sm` com `Crown h-4 w-4 text-amber-500` e o texto:
> "Ao promover este usuario a Proprietario, ele tera controle total sobre a organizacao, incluindo a capacidade de remover outros proprietarios."

Esse é **o único texto da tela com suporte a dark mode explícito** (`text-amber-700 dark:text-amber-400`).

**Rodapé:** `Cancelar` (outline) + `Salvar Alteracoes`, este último com:
```
disabled = isSaving || !selectedRole || selectedRole === user.role
```
— ou seja, **o botão só habilita se o papel realmente mudou**.

**Mecânica** (`useUpdateUserRole`, M015): não faz `UPDATE` direto — chama a RPC `set_user_role_in_org(p_user_id, p_organization_id, p_role)`, que (a) valida que o caller é admin/owner da org ou super_admin, (b) **bloqueia auto-promoção**, (c) audita em `organization_role_changes`, (d) é `SECURITY DEFINER`.

**Tradução de erros da RPC:**

| Erro do banco | Mensagem exibida |
|---|---|
| contém "cannot change your own role" | "Voce nao pode alterar a propria role. Peca a outro admin." |
| contém "permission denied" | "Permissao negada: apenas admin/owner podem alterar roles." |
| outro | mensagem crua do erro |

**Toasts:** "Role atualizado" / "O role do usuario foi atualizado com sucesso." · "Erro ao atualizar role" / "Ocorreu um erro ao atualizar o role. Tente novamente."

> **Vocabulário inconsistente.** A UI mistura "role" (inglês, nos toasts e no rótulo do campo) com "Proprietario/Administrador/Gerente" (português, nos valores) e "Permissoes" (no modal da matriz). O redesign deve escolher um termo — **"Papel"** ou **"Perfil de acesso"** — e usá-lo em todo lugar.

### B3.8 Remoção de usuário

Confirmação: **`window.confirm("Tem certeza que deseja remover este usuario?")`** — nativo do browser, novamente.

`useRemoveUser` → `DELETE FROM organization_users WHERE organization_id = ? AND user_id = ?` com `.select("id")` e verificação por `ensureDeleted()` (detecta "delete que não deletou nada", tipicamente por RLS). Erro dispara toast destrutivo "Erro ao remover" com mensagem de `getDeleteErrorMessage(error)`.

**Sem toast de sucesso** — a linha simplesmente some.

### B3.9 Cancelamento de convite

Confirmação: `window.confirm("Tem certeza que deseja cancelar este convite?")`. `DELETE FROM user_invitations WHERE id = ?`, com `ensureDeleted`. Erro → toast "Erro ao cancelar convite".

### B3.10 Reenvio de convite

`useResendInvitation`: gera **novo token** (`crypto.randomUUID()`), **nova expiração** (+7 dias), força `status: "pending"`, e reinvoca `send-invitation-email`. **Aqui a falha de e-mail derruba a operação** (`throw new Error("Falha ao reenviar email")`) — comportamento **oposto** ao da criação (B3.6). Inconsistência a resolver.

Durante o reenvio, só o botão da linha em questão gira (`resendingId`). Toast de sucesso: "Convite reenviado!" / "Um novo email de convite foi enviado para `<email>`".

---

## B4. Papéis e Permissões (`RolesPermissionsCard`)

**Arquivo:** `src/components/settings/RolesPermissionsCard.tsx`
**Montagem:** dentro da aba **Usuarios** — não é uma aba própria.

### B4.1 Objetivo

Exibir, em modo **somente leitura**, a matriz de permissões de cada papel por recurso do sistema. É documentação viva: os dados vêm da tabela `roles_permissions`, não de constantes do frontend.

### B4.2 Gatilho — `RolesPermissionsButton`

`Button` com `Shield h-4 w-4 mr-2` + texto **"Ver Permissoes"**. Props com defaults: `variant="outline"`, `size="default"`. Usado no header do card de usuários.

### B4.3 Modal — `RolesPermissionsModal`

| Item | Detalhe |
|---|---|
| Container | `Dialog` → `DialogContent max-w-4xl max-h-[85vh] overflow-hidden flex flex-col` |
| Título | `Shield h-5 w-5` + "Matriz de Permissoes" |
| Descrição | "Permissoes de cada role por recurso do sistema" |
| Corpo | `div flex-1 overflow-auto px-6 pb-6` com `div overflow-x-auto` interno |
| Rodapé | **Nenhum** — fecha só por ESC / clique fora / X do Dialog |

### B4.4 Estrutura da matriz

**Colunas** — 1 coluna de recurso (`w-[180px]`) + 5 colunas de papel (`text-center min-w-[120px]`), na ordem fixa `["owner","admin","manager","operator","viewer"]`. Cada cabeçalho de papel é uma pilha vertical (`flex flex-col items-center gap-1`): ícone `h-4 w-4` colorido + rótulo em `text-xs`.

Cores dos ícones no cabeçalho (`ROLE_CONFIG` **local deste arquivo**, diferente do de `UsersTab`):

| Papel | Rótulo | Ícone | Cor |
|---|---|---|---|
| `owner` | Proprietario | `Crown` | `text-amber-500` |
| `admin` | Administrador | `Shield` | `text-red-500` |
| `manager` | Gerente | `UserCog` | `text-blue-500` |
| `operator` | Operador | `Users` | `text-green-500` |
| `viewer` | Visualizador | `Eye` | `text-gray-500` |

**Linhas** — uma por recurso distinto encontrado nos dados (`[...new Set(permissions.map(p => p.resource))]`), rotulado por `RESOURCE_LABELS`:

| Chave | Rótulo exibido |
|---|---|
| `contacts` | Contatos |
| `contracts` | Contratos |
| `campaigns` | Campanhas |
| `workflows` | Regras de Cobranca |
| `filters` | Filtros |
| `actions` | Acoes |
| `integrations` | Integracoes |
| `etl` | Fonte de Dados |
| `settings` | Configuracoes |
| `users` | Usuarios |

Recurso fora do mapa cai no fallback: exibe a chave crua.

### B4.5 Célula de permissão

Cada célula conta quantos dos 4 verbos (`can_create`, `can_read`, `can_update`, `can_delete`) são `true` e renderiza um `Badge`:

| Contagem | Badge |
|---|---|
| 4 | `variant="default"` + `className="bg-green-500"` → texto **"Total"** |
| 0 | `variant="outline" text-muted-foreground` → texto **"Nenhum"** |
| 1–3 | `variant="secondary"` → texto **"`<n>`/4"** |

Sem registro para `(role, resource)` → célula **vazia**.

**Tooltip** (`TooltipContent side="bottom" className="w-48"`) — detalha os 4 verbos, cada um numa linha `flex items-center justify-between`:

| Rótulo | Indicador |
|---|---|
| Criar | `Check h-4 w-4 text-green-500` ou `X h-4 w-4 text-muted-foreground/30` |
| Visualizar | idem |
| Editar | idem |
| Excluir | idem |

**Rodapé da tabela:** `Info h-3 w-3` + "Passe o mouse sobre as permissoes para ver detalhes (Criar, Visualizar, Editar, Excluir)" (`text-xs text-muted-foreground`).

### B4.6 Estados

| Estado | Render |
|---|---|
| Carregando | `Loader2 h-8 w-8 animate-spin text-muted-foreground`, `py-8` centralizado |
| Carregado | Tabela + nota de rodapé |
| Erro | **Não tratado** — a query lança e nada é renderizado além do container |

### B4.7 Problemas para o redesign

| Problema | Impacto |
|---|---|
| **Só hover** | Toda a informação detalhada está em tooltip — **inacessível em touch** e por teclado. Em tablet/celular, o usuário vê apenas "3/4" sem saber qual verbo falta |
| **`TooltipProvider` por célula** | O provider é instanciado dentro do `map`, em vez de envolver a tabela uma vez |
| **Sem ação** | O modal é puramente informativo. Não há como ajustar permissões pela interface — só pelo banco |
| **`ROLE_CONFIG` duplicado** | Existem duas definições (esta e a de `UsersTab`), com cores diferentes para os mesmos papéis |
| **Sem rodapé** | O `Dialog` não tem botão "Fechar"; em mobile o usuário depende do X do canto |

---

## B5. Aba **Kanban** — Faixas de Atraso (Aging Buckets)

**Arquivo:** `src/components/settings/tabs/AgingBucketsTab.tsx`
**Hooks:** `useAgingBuckets`, `useUpdateAgingBuckets`, `validateAgingBuckets` (`src/hooks/useAgingBuckets.ts`)

### B5.1 Objetivo

Definir as faixas de dias de atraso que viram **colunas do Kanban da Carteira**. Cada faixa tem nome, intervalo (min/max em dias) e cor.

> **Descompasso de rótulo.** A aba se chama **"Kanban"** (ícone `LayoutGrid`), mas o título do card é **"Faixas de Atraso (Aging Buckets)"**. Quem procura "aging" ou "faixa de atraso" não acha a aba. Renomear no redesign.

### B5.2 Permissões

`canEdit = hasPermission("settings:write")`. Sem permissão: inputs `disabled`, handle de arraste com `opacity-50 cursor-not-allowed`, sem botões "Adicionar Faixa", "Restaurar Padrao", "Cancelar" e "Salvar Alteracoes". A lista e o preview continuam visíveis.

### B5.3 Anatomia

Um único `Card`.

**`CardHeader`:**
- `CardTitle` → "Faixas de Atraso (Aging Buckets)"
- `CardDescription` → "Configure as faixas de dias de atraso exibidas no Kanban. Arraste para reordenar." + **pílula condicional** quando `isCustom`: `span ml-2 text-xs bg-primary/10 text-primary px-2 py-0.5 rounded` com o texto **"Configuracao personalizada"**

**`CardContent space-y-6`** — quatro blocos: erros de validação, lista de faixas, preview do Kanban e barra de ações.

### B5.4 Bloco de erros de validação

Renderizado sempre que houver erro (validação roda a cada mudança, via `useEffect` sobre `editableBuckets`):

`div bg-destructive/10 border border-destructive/20 rounded-lg p-4` com `AlertTriangle h-5 w-5 text-destructive`, título "Erros de validacao:" (`font-medium text-destructive`) e `ul list-disc list-inside text-sm text-destructive/90` com uma linha por erro.

**Regras de validação** (`validateAgingBuckets`), com as mensagens exatas:

| # | Regra | Mensagem |
|---|---|---|
| 1 | Mínimo de 1 faixa | "Deve haver pelo menos 1 bucket" *(retorna imediatamente)* |
| 2 | Máximo de 15 faixas | "Máximo de 15 buckets permitido" |
| 3 | `id` obrigatório | "Bucket `<n>`: ID é obrigatório" |
| 4 | `label` obrigatório | "Bucket `<n>`: Label é obrigatório" |
| 5 | `min <= max` | "Bucket \"`<label>`\": min (`<min>`) não pode ser maior que max (`<max>`)" |
| 6 | Cor no formato `#RRGGBB` | "Bucket \"`<label>`\": cor inválida (use formato #RRGGBB)" |
| 7 | Sem sobreposição (sobre a lista ordenada por `min`) | "Buckets \"`<a>`\" e \"`<b>`\" se sobrepõem" |
| 8 | Sem lacuna (`next.min` deve ser `current.max + 1`) | "Gap entre \"`<a>`\" (max: `<x>`) e \"`<b>`\" (min: `<y>`)" |
| 9 | IDs únicos | "IDs duplicados: `<lista>`" |

> Note que **estas mensagens têm acento** (o módulo de validação foi escrito em UTF-8 correto), ao contrário do restante da aba.

### B5.5 Lista de faixas

**Cabeçalho da lista** (`flex items-center gap-3 px-3 py-2 text-xs font-medium text-muted-foreground`), com larguras que espelham as das linhas:

| Rótulo | Largura |
|---|---|
| *(vazio — espaçador do handle)* | `w-5` |
| Cor | `w-10` |
| Nome | `flex-1 min-w-[120px]` |
| Min | `w-24 text-center` |
| Max | `w-24 text-center` |
| Preview | `w-20 text-center` |
| *(vazio — espaçador da lixeira)* | `w-9` |

**Linha (`SortableBucketItem`)** — `flex items-center gap-3 p-3 bg-card border rounded-lg`, com `opacity-50 shadow-lg` enquanto arrastada:

| # | Elemento | Detalhe |
|---|---|---|
| 1 | **Handle de arraste** | `GripVertical h-5 w-5 text-muted-foreground`, `cursor-grab active:cursor-grabbing touch-none` |
| 2 | **Cor** | `Input type="color" w-10 h-10 p-1 cursor-pointer`, `title="Cor do bucket"` |
| 3 | **Nome** | `Input h-9`, placeholder "Nome do bucket" |
| 4 | **Min** | `Input type="number" h-9 pr-8` com sufixo absoluto "dias"; `disabled` na **primeira** faixa; placeholder `"-∞"` quando primeira, senão "Min". Valor vazio ⇒ `-Infinity` |
| 5 | **Max** | idem; `disabled` na **última** faixa; placeholder `"+∞"` quando última, senão "Max". Valor vazio ⇒ `Infinity` |
| 6 | **Preview** | `div w-20 h-8 rounded flex items-center justify-center text-white text-xs font-medium` com `backgroundColor` = cor da faixa; texto truncado em **8 caracteres** + "..." |
| 7 | **Remover** | `Button variant="ghost" size="icon" text-destructive` com `Trash2 h-4 w-4` — **sem confirmação** |

**Drag & drop** — `@dnd-kit/core` + `@dnd-kit/sortable`, com `closestCenter`, `verticalListSortingStrategy` e **dois sensores**: `PointerSensor` e `KeyboardSensor` (com `sortableKeyboardCoordinates`) — ou seja, **a reordenação funciona por teclado**.

**Reajuste automático ao reordenar** (`handleDragEnd`): após o `arrayMove`, cada faixa recebe
```
min = (índice 0) ? -Infinity : anterior.max + 1
max = (último índice) ? Infinity : max atual
```
Ou seja, a primeira sempre vira `-∞` e a última sempre `+∞`, mas os limites intermediários **não** são reencadeados — o que pode gerar gaps/overlaps imediatamente sinalizados pelo bloco de validação.

**Botão "Adicionar Faixa"** — `Button variant="outline" className="w-full border-dashed"` com `Plus h-4 w-4 mr-2`. Só aparece se `canEdit` **e** `editableBuckets.length < 15`.

Nova faixa criada (`handleAddBucket`): inserida **antes da última**, com
- `label: "Novo bucket"`
- `id: "custom-<timestamp>"`
- `color: "#6B7280"` (gray-500)
- `min = anterior.max + 1` (ou `0` se não houver anterior)
- `max = próxima.min - 1` (ou `30` se não houver próxima)

**Remoção** (`handleRemoveBucket`): filtra e reajusta apenas as pontas (primeira → `-Infinity`, última → `Infinity`).

### B5.6 Preview do Kanban

Rótulo "Preview do Kanban" + `div flex gap-2 overflow-x-auto pb-2`. Uma "coluna" por faixa:
- `flex-shrink-0 w-32 rounded-lg p-2 text-center`
- `style`: `backgroundColor = cor + "20"` (alfa ~12%), `borderColor = cor`, `borderWidth: 2`
- Linha 1: nome (`text-xs font-medium truncate`, `color` = cor da faixa)
- Linha 2: `text-[10px] text-muted-foreground` → `"<min|-∞> a <max|+∞> dias"`

### B5.7 Barra de ações

Só se `canEdit`. `flex items-center justify-between pt-4 border-t`.

**Esquerda** — botão **"Restaurar Padrao"**, renderizado **só quando `isCustom`**. `Button variant="outline"` com `RotateCcw h-4 w-4 mr-2`, `disabled` enquanto `isPending`. É o `AlertDialogTrigger`.

**Direita** (`flex items-center gap-2`):
- **"Cancelar"** — `Button variant="ghost"`, renderizado **só quando `hasChanges`**. Restaura a lista a partir da configuração salva e zera `hasChanges`.
- **"Salvar Alteracoes"** — com `Loader2` durante `isPending`. Habilitação:
  ```
  disabled = isPending || validationErrors.length > 0 || !hasChanges
  ```

### B5.8 Modal **Restaurar configuracao padrao?**

| Item | Detalhe |
|---|---|
| Objetivo | Descartar a configuração personalizada e voltar às 7 faixas padrão |
| Gatilho | Botão "Restaurar Padrao" (só visível se `isCustom`) |
| Container | `AlertDialog` |
| Título | "Restaurar configuracao padrao?" |
| Descrição | "Isso ira remover sua configuracao personalizada e restaurar os 7 buckets padrao. Esta acao nao pode ser desfeita." |
| Botões | `AlertDialogCancel` "Cancelar" + `AlertDialogAction` "Restaurar" (**sem estilo destrutivo**) |

Mecânica: `resetToDefault()` remove a chave `aging_buckets` de `organizations.settings` (preservando as demais chaves; se sobrar objeto vazio, grava `null`).

### B5.9 As 7 faixas padrão (`DEFAULT_AGING_BUCKETS`)

Padrão heat-map: verde para em dia, amarelo/laranja para atraso recente, vermelhos crescentes, roxo para atraso severo.

| # | `id` | Rótulo | Min | Max | Cor | Token Tailwind |
|---|---|---|---|---|---|---|
| 1 | `current` | Em dia | `-∞` | 0 | `#10B981` | emerald-500 |
| 2 | `1-15` | 1-15 dias | 1 | 15 | `#EAB308` | yellow-500 |
| 3 | `16-30` | 16-30 dias | 16 | 30 | `#F97316` | orange-500 |
| 4 | `31-60` | 31-60 dias | 31 | 60 | `#EF4444` | red-500 |
| 5 | `61-90` | 61-90 dias | 61 | 90 | `#DC2626` | red-600 |
| 6 | `91-180` | 91-180 dias | 91 | 180 | `#B91C1C` | red-700 |
| 7 | `180+` | 180+ dias | 181 | `+∞` | `#7C3AED` | violet-600 |

### B5.10 Persistência e formato armazenado

Os buckets vivem em **`organizations.settings.aging_buckets`** (jsonb). Como JSON não representa `Infinity`, a conversão é explícita:

| Runtime | Armazenado |
|---|---|
| `min = -Infinity` | `min: null` |
| `max = Infinity` | `max: null` |

Funções: `runtimeToStored` / `storedToRuntime`. `isCustom` = existe `aging_buckets` com ao menos 1 item.

`updateBuckets` **revalida antes de gravar** (segunda barreira, além da UI) e faz **merge** com as demais chaves de `settings`.

### B5.11 Toasts

| Evento | Título | Descrição |
|---|---|---|
| Salvar com erro de validação | "Erro de validacao" (destrutivo) | `validationErrors.join("\n")` |
| Salvar OK | "Configuracao salva" | "Os buckets de aging foram atualizados com sucesso." |
| Salvar falhou | "Erro ao salvar" (destrutivo) | `error.message` ou "Erro desconhecido" |
| Restaurar OK | "Configuracao resetada" | "Os buckets de aging foram restaurados para o padrao." |
| Restaurar falhou | "Erro ao resetar" (destrutivo) | `error.message` ou "Erro desconhecido" |

### B5.12 Estados

| Estado | Render |
|---|---|
| Carregando | `Loader2 h-8 w-8 animate-spin`, `py-12` — substitui a aba |
| Padrão (não custom) | Sem a pílula "Configuracao personalizada", sem botão "Restaurar Padrao" |
| Personalizada | Pílula + botão "Restaurar Padrao" |
| Com alterações | Botão "Cancelar" aparece; "Salvar Alteracoes" habilitado (se válido) |
| Inválido | Bloco vermelho de erros; Salvar desabilitado |
| Limite atingido | Com 15 faixas, o botão "Adicionar Faixa" **some** — sem explicação |
| Somente leitura | Tudo `disabled`, sem barra de ações |

### B5.13 Dores específicas

| Dor | Detalhe |
|---|---|
| **Remoção sem confirmação** | A lixeira apaga a faixa direto. Numa configuração de 7+ faixas, um clique errado exige "Cancelar" (que descarta **todas** as mudanças) |
| **Layout de linha não responsivo** | `flex` com larguras fixas (`w-10`, `w-24`, `w-20`, `w-9`) e um `flex-1` — em telas estreitas, os inputs de Min/Max e o preview espremem o campo Nome. Não há empilhamento |
| **Cabeçalho da lista desacoplado** | Os rótulos das colunas são um `div` separado com larguras duplicadas manualmente — qualquer ajuste precisa ser feito em dois lugares |
| **Preview truncado em 8 caracteres** | O badge de preview corta o nome de forma agressiva; o preview do Kanban abaixo já mostra o nome completo, tornando o badge quase redundante |
| **Botão "Restaurar" sem estilo destrutivo** | O `AlertDialogAction` usa a variante padrão, ao contrário do de API Keys |
| **Reajuste parcial ao reordenar** | Arrastar gera gaps/overlaps que o usuário precisa corrigir manualmente — o reencadeamento automático só trata as pontas |

---

## B6. Aba **Datas Bloqueadas**

**Arquivo:** `src/components/settings/tabs/BlockedDatesTab.tsx`
**Hooks:** `useBlockedDates`, `useCreateBlockedDate`, `useUpdateBlockedDate`, `useDeleteBlockedDate`, `useImportNationalHolidays`, `useHolidaySyncStatus` (`src/hooks/useBlockedDates.ts`)

### B6.1 Objetivo

Manter o calendário de dias em que **campanhas não são executadas** — feriados nacionais/estaduais/municipais e datas definidas manualmente pela operação.

### B6.2 Permissões

**Nenhum gate de permissão nesta aba.** Não há `hasPermission` em lugar nenhum de `BlockedDatesTab` — todos os botões (adicionar, importar, ativar/desativar, remover) aparecem para qualquer usuário que chegue à tela de Configurações. A proteção efetiva é o RLS do banco.

⚠️ A confirmar: se isso é intencional ou lacuna. O padrão das abas vizinhas é gatear por `settings:write`.

### B6.3 Anatomia (não usa `Card` no topo)

`div space-y-6`, com cabeçalho próprio em vez de `CardHeader`:

1. **Cabeçalho de seção** — `h3 text-lg font-medium` "Datas Bloqueadas" + `p text-sm text-muted-foreground` "Gerencie feriados e datas em que campanhas nao devem ser executadas".

2. **Alerta de comportamento** — `Alert` com `Info h-4 w-4`:
   > "Campanhas nao serao executadas em datas bloqueadas ativas. Acoes ja agendadas serao mantidas como pending ate a proxima data valida."

3. **Linha de status da sincronização** (`HolidaySyncStatusLine`) — ver B6.4.

4. **Barra de controles** — `flex items-center justify-between`:
   - Esquerda (`flex items-center gap-3`): `Select` de ano (`w-[130px]`) + botão "Importar Feriados Nacionais".
   - Direita: `AddDateDialog` (botão "Adicionar Data").

5. **Conteúdo** — `Card` com tabela, ou `Card` de estado vazio.

### B6.4 Linha de status da sincronização (`HolidaySyncStatusLine`, card 6860)

Componente dedicado que responde três perguntas que a operação antes não conseguia responder: **quando** rodou pela última vez, **de onde** veio o dado e **se houve erro**.

**Sem execução registrada** (`run === null`):
`Alert` com `Info h-4 w-4` e `AlertDescription text-xs`:
> "Nenhuma sincronização automática registrada ainda. O calendário pode ser importado manualmente pelo botão abaixo."

**Com execução:** `Alert` — ganha `border-destructive/40 bg-destructive/10` e ícone `AlertCircle h-4 w-4 text-destructive` se `error_count > 0`; senão `Info h-4 w-4`. Texto (`text-xs`) montado assim:

> "Última sincronização **{automática|manual}** em **{data/hora pt-BR em `America/Sao_Paulo`}** (BRT) — anos {lista}, fonte: {BrasilAPI|cálculo local}. {n} incluídos, {n} atualizados, {n} preservados." *(+ em negrito, se houver erro: "{n} erro(s): {mensagem ou 'sem detalhe'}")*

Mapeamentos:

| Campo | Valor no banco | Texto exibido |
|---|---|---|
| `trigger_source` | `scheduled` | "automática" |
| `trigger_source` | `manual` | "manual" |
| `source` | `brasilapi` | "BrasilAPI" |
| `source` | `fallback` | "cálculo local" |

**Fonte:** RPC `get_holiday_sync_status(p_org_slug)`, `staleTime: 60_000`. O componente usa **só a execução mais recente** (`syncRuns?.[0]`) — o histórico completo é carregado mas **não é exibido**. Oportunidade de redesign: uma lista/timeline de execuções.

Shape de `HolidaySyncRun`: `run_at`, `trigger_source`, `years[]`, `source`, `inserted_count`, `updated_count`, `skipped_count`, `error_count`, `error_message`.

### B6.5 Seletor de ano

`Select` com **exatamente três opções**: ano anterior, ano corrente (default) e ano seguinte — calculados de `new Date().getFullYear()`.

Trocar o ano refaz a query (`queryKey: ["blocked-dates", orgId, year]`), filtrando `blocked_date` entre `<ano>-01-01` e `<ano>-12-31`.

### B6.6 Botão "Importar Feriados Nacionais"

`Button variant="outline"` com `Download h-4 w-4 mr-2` (ou `Loader2` girando). `title` (tooltip nativo):
> "Sincroniza os feriados nacionais legais do ano selecionado. Datas criadas ou alteradas manualmente são preservadas."

**Sem confirmação** — dispara direto sobre o ano selecionado.

**Mecânica (card 6860):** o hook **não** implementa mais a regra — apenas invoca a Edge Function `sync-national-holidays` com `{ years: [ano] }`, a **mesma** que o cron mensal chama. A regra canônica vive em `supabase/functions/_shared/national-holidays.ts`.

Três defeitos que a versão anterior (regra duplicada no frontend) tinha, documentados no código e relevantes para entender a UI atual:
1. Filtrava por `type === "national"` da BrasilAPI, que marca Carnaval, Corpus Christi e Páscoa como nacionais — importava **ponto facultativo como feriado legal**.
2. O fallback local divergia da própria API (trazia Quarta-feira de Cinzas, não trazia a segunda de Carnaval) e, como o upsert nunca apagava nada, alternar fontes **acumulava datas erradas**.
3. O payload do upsert levava `is_active: true`, então **cada clique ressuscitava** qualquer feriado que a operação tivesse desativado.

**Tratamento de resposta:** considera falha se `!data.success` **ou** `data.totals.errors > 0`. Erro de invocação passa por `readEdgeFunctionError` para extrair a mensagem real.

**`onSettled`** (roda em sucesso **e** falha) invalida `["blocked-dates"]` e `["holiday-sync-status"]` — comentário: *"A failed/partial response may still have committed dates and audit rows."*

**Toast de sucesso:** título "Feriados nacionais de {ano} sincronizados"; descrição montada por partes, sempre incluindo a fonte:
> "{n} incluídos · {n} atualizados · {n} preservados (decisão manual ou já em dia) — fonte: {BrasilAPI | cálculo local (BrasilAPI indisponível)}."

**Toast de erro:** "Erro ao importar feriados" + mensagem.

### B6.7 A marca `is_manual_override`

Campo booleano na linha (`BlockedDate.is_manual_override`) que significa: **a operação decidiu algo sobre esta data** (criou, renomeou ou desativou). A sincronização automática **nunca toca** linha marcada.

| Ação na UI | Efeito no campo |
|---|---|
| Adicionar data pelo modal | `is_manual_override: true` no insert |
| Ativar/desativar pelo botão da linha | `is_manual_override: true` forçado no update |
| Renomear (via update) | idem |
| Importar feriados | linhas marcadas entram em `skipped_count` ("preservados") |

> **Lacuna de UI importante.** Esse campo é **invisível na interface** — não há badge, ícone nem coluna. O usuário não consegue saber quais datas estão "protegidas" da sincronização automática, embora o conceito seja central ao funcionamento da tela. Adicionar esse sinal é uma das melhorias de maior retorno nesta aba.

### B6.8 Tabela de datas

Dentro de `Card` com `CardTitle` = `Calendar h-5 w-5` + "Datas Bloqueadas - {ano}" e `CardDescription` = "{n} data configurada" / "{n} datas configuradas" (pluralização correta).

Ordenação: `blocked_date` ascendente (ordenado na query **e** re-ordenado no componente com `localeCompare`).

| Coluna | Largura | Conteúdo |
|---|---|---|
| **Data** | auto | `Calendar h-4 w-4 text-muted-foreground` + duas linhas: `"d 'de' MMMM 'de' yyyy"` em `font-medium` (ex.: "25 de dezembro de 2026") e, abaixo, o dia da semana em `text-xs text-muted-foreground capitalize` (ex.: "sexta-feira") — ambos com locale `ptBR` |
| **Nome** | auto | `blockedDate.name` |
| **Tipo** | auto | `Badge variant="secondary"` com classe de cor por origem |
| **Status** | auto | `Badge variant="secondary"` verde "Ativo" (`bg-green-100 text-green-700`) ou cinza "Inativo" (`bg-gray-100 text-gray-500`) |
| **Acoes** | `w-[100px]` | Dois `Button size="icon" variant="ghost" h-8 w-8` |

**Origens (`source`) — rótulos e cores:**

| Valor | Rótulo | Classes do badge |
|---|---|---|
| `manual` | Manual | `bg-gray-100 text-gray-700` |
| `national_holiday` | Feriado Nacional | `bg-red-100 text-red-700` |
| `state_holiday` | Feriado Estadual | `bg-orange-100 text-orange-700` |
| `municipal_holiday` | Feriado Municipal | `bg-blue-100 text-blue-700` |

Valor fora do mapa: exibe a string crua com o badge cinza.

**Botões de ação da linha:**

| Botão | Ícone (estado) | `title` | Confirmação |
|---|---|---|---|
| Alternar ativo | `X h-4 w-4` se ativo (ação = desativar); `Check h-4 w-4` se inativo (ação = ativar); `Loader2` durante a mutation | "Desativar" / "Ativar" | **Nenhuma** |
| Remover | `Trash2 h-4 w-4` (`hover:text-destructive`); `Loader2` durante | "Remover" | `window.confirm(\`Deseja remover a data bloqueada "${name}"?\`)` |

> **Semântica do ícone de alternância é ambígua.** O `X` numa linha ativa significa "clique para desativar", mas visualmente parece "está desativado" / "excluir". Um `Switch` (como no card de integração) resolveria.

### B6.9 Modal **Adicionar Data Bloqueada** (`AddDateDialog`)

| Item | Detalhe |
|---|---|
| Objetivo | Cadastrar manualmente uma data em que campanhas não rodam |
| Gatilho | `Button` "Adicionar Data" com `Plus h-4 w-4 mr-2` (é o `DialogTrigger`) |
| Container | `Dialog` → `DialogContent` (largura padrão) |
| Título | "Adicionar Data Bloqueada" |
| Descrição | "Adicione uma data em que campanhas nao devem ser executadas." |
| Envolvente | `<form onSubmit>` — `Enter` submete |

**Campos** (`div space-y-4 py-4`):

| # | Campo | `id` | Controle | Obrigatório | Placeholder / opções |
|---|---|---|---|---|---|
| 1 | Data | `blocked-date` | `Input type="date"` (date picker nativo) | `required` | — |
| 2 | Nome | `blocked-name` | `Input type="text"` | `required` | "Ex: Aniversario da cidade" |
| 3 | Tipo | `blocked-source` | `Select` | default `manual` | **Manual**, **Feriado Municipal**, **Feriado Estadual** |

> **`national_holiday` não é oferecido no modal, de propósito** — feriado nacional só entra pela sincronização automática. Mas a tabela **exibe** esse tipo, o que é coerente.

**Guarda extra de submit:** `if (!dateValue || !name.trim()) return;` — além dos `required` nativos, impede nome só com espaços.

**Rodapé:** `Cancelar` (outline, `type="button"`) + `Adicionar` (`type="submit"`, com `Loader2` durante `createDate.isPending`).

**Limpeza:** no `onSuccess`, fecha o modal e reseta os três campos.

**Toasts:** "Data bloqueada adicionada" (título apenas, sem descrição) · "Erro ao adicionar data bloqueada" + `error.message`.

> **Validações ausentes:** não há checagem de data **duplicada** no mesmo ano, nem aviso se a data selecionada está fora do ano atualmente filtrado (a data é criada, mas **desaparece da lista** porque o filtro é por ano — sem nenhuma explicação).

### B6.10 Estados

| Estado | Render |
|---|---|
| Carregando | `Loader2 h-6 w-6 animate-spin`, `py-12` — substitui a aba inteira |
| Vazio | `Card` com `CalendarOff h-12 w-12 text-muted-foreground mb-4`, "Nenhuma data bloqueada" (`font-medium`) e "Importe feriados nacionais ou adicione datas manualmente" (`text-sm mt-1`). **Sem CTA embutido** — os botões ficam na barra acima |
| Tabela vazia por filtro de ano | Mesmo estado vazio acima — **não distingue** "não há datas" de "não há datas neste ano" |
| Importando | Botão com `Loader2` e desabilitado |
| Tabela com dados | `Card` com contagem no `CardDescription` |

**Tolerância a tabela inexistente:** se a consulta falhar com `42P01` (relation does not exist), o hook devolve array vazio, loga um `console.warn` e **desliga o retry**. Serve para org recém-criada sem a migration aplicada.

### B6.11 Dores específicas

| Dor | Detalhe |
|---|---|
| **Sem gate de permissão** | Qualquer usuário com acesso a Configurações pode apagar feriados |
| **`is_manual_override` invisível** | Conceito central, sem representação visual |
| **Data fora do ano filtrado some** | Criar 01/01 do ano seguinte enquanto olha o ano atual → a data não aparece e nada explica |
| **Sem edição de nome** | O hook `useUpdateBlockedDate` aceita `name`, mas a UI só expõe `is_active`. Renomear é impossível pela interface |
| **Janela de 3 anos** | Não há como ver ou planejar além de ±1 ano |
| **Sem visão de calendário** | Uma tabela linear de ~15 feriados é menos legível que um mini-calendário anual com os dias marcados |
| **Histórico de sync descartado** | A query traz N execuções; só a primeira é usada |
| **`window.confirm` na remoção** | Mesmo problema das outras telas |

---

## B7. Aba **Custos** (Custos Estimados por Canal)

**Arquivo:** `src/components/settings/tabs/ChannelCostsTab.tsx`
**Hooks:** `useChannelCosts`, `useUpdateChannelCost`, `useInitializeChannelCosts` (`src/hooks/useChannelCosts.ts`)
**Formatação:** `formatBRL` de `src/lib/cost-calculator.ts`

### B7.1 Objetivo

Definir o **custo médio estimado por ação** de cada canal, alimentando as estimativas de gasto exibidas em dashboards e prévias de campanha.

### B7.2 Permissões

**Nenhum gate de permissão nesta aba** — mesmo caso de B6. Qualquer usuário com acesso à tela pode editar os custos.

⚠️ A confirmar: se é intencional.

### B7.3 Anatomia

`div space-y-6`, sem `Card` no topo:

1. **Cabeçalho** — `h3 text-lg font-medium` "Custos Estimados por Canal" + `p text-sm text-muted-foreground` "Configure o custo medio por acao de cada canal para estimar gastos".

2. **Alerta de escopo** — `Alert` com `Info h-4 w-4`:
   > "Estes valores sao estimativas para visibilidade de custos. Nao representam faturamento real. Configure o custo medio de cada canal conforme seu provedor."

   Disclaimer importante: essa tela **não** é billing.

3. **Estado vazio** (se `!data || data.length === 0`) — ver B7.6.

4. **Tabela** (se houver dados) — `Card` com `CardTitle` = `DollarSign h-5 w-5` + "Custos por Canal" e `CardDescription` = "Custo medio estimado por acao em cada canal".

### B7.4 Tabela de custos

Ordenação: `channel` **alfabética ascendente** (definida na query) — o que significa que a ordem exibida é `ai, block, email, human_activity, negativation, notification, sms, voice, webhook, whatsapp`, e **não** a ordem de relevância operacional.

| Coluna | Alinhamento | Conteúdo |
|---|---|---|
| **Canal** | esquerda | `Badge variant="secondary"` com a classe de cor do canal + ícone `h-3.5 w-3.5` + rótulo, `gap-1.5` |
| **Descricao** | esquerda | `cost.description` ou `"-"` (`text-muted-foreground`) |
| **Custo Unitario (R$)** | **direita** | `span font-mono text-sm` com `formatBRL(cost_per_unit)`; em edição, vira input inline |
| **Acoes** | — (`w-[100px]`) | `Button size="icon" variant="ghost" h-8 w-8` com `Pencil h-4 w-4` — **some durante a edição** |

**Metadados de canal (`CHANNEL_META`):**

| Chave | Rótulo | Ícone | Classes |
|---|---|---|---|
| `whatsapp` | WhatsApp | `MessageCircle` | `bg-green-100 text-green-700` |
| `sms` | SMS | `Smartphone` | `bg-blue-100 text-blue-700` |
| `email` | E-mail | `Mail` | `bg-red-100 text-red-700` |
| `voice` | Voz | `Phone` | `bg-purple-100 text-purple-700` |
| `negativation` | Negativacao | `AlertTriangle` | `bg-orange-100 text-orange-700` |
| `ai` | IA | `Bot` | `bg-emerald-100 text-emerald-700` |
| `human_activity` | Atividade Humana | `User` | `bg-cyan-100 text-cyan-700` |
| `webhook` | Webhook | `Webhook` | `bg-gray-100 text-gray-700` |
| `block` | Bloqueio | `Ban` | `bg-rose-100 text-rose-700` |

**Fallback** para canal desconhecido: rótulo = a própria chave, ícone `DollarSign`, classes `bg-gray-100 text-gray-700`.

> **Três divergências entre este mapa e o das Integrações (A8.1):**
> 1. **`notification` está ausente** de `CHANNEL_META`, mas **existe** em `DEFAULT_CHANNEL_COSTS` (com custo R$ 30,00 — o mais caro de todos). Resultado: a linha "Notificacao" aparece na tabela com o **rótulo cru `notification`**, ícone genérico de cifrão e badge cinza.
> 2. **`rcs` não existe aqui** — canal válido em Integrações, sem custo configurável.
> 3. **`ai` só existe aqui** — não é tipo de integração.
> 4. As cores dos mesmos canais **divergem** entre as duas telas (ex.: e-mail é azul em Integrações e **vermelho** em Custos; SMS é roxo lá e **azul** aqui). O redesign precisa de **um único mapa de canal → cor/ícone/rótulo** para toda a Torre.

### B7.5 Edição inline

Padrão de edição **na própria célula**, sem modal:

| Elemento | Detalhe |
|---|---|
| Entrada em edição | Clique no lápis → `editValue = String(cost.cost_per_unit)`, `isEditing = true` |
| Controle | `Input type="number" step="0.0001" min="0"`, `className="w-28 h-8 text-right font-mono text-sm"`, `autoFocus` |
| Confirmar | `Button size="icon" variant="ghost" text-green-600 hover:text-green-700` com `Check h-4 w-4` (ou `Loader2`) |
| Cancelar | `Button size="icon" variant="ghost" text-red-600 hover:text-red-700` com `X h-4 w-4` |
| Atalhos | `Enter` → salvar · `Escape` → cancelar |
| Validação | `parseFloat(editValue)`; se `NaN` ou `< 0`, **o save simplesmente não faz nada** — sem mensagem, sem sinal visual |
| Precisão | `step="0.0001"` → 4 casas decimais (necessário para e-mail a R$ 0,003) |

> **Falha silenciosa.** Digitar "abc" ou "-5" e apertar Enter não produz **nenhum** feedback: o input continua em edição e o usuário não sabe por quê. Precisa de mensagem inline no redesign.

**Persistência:** `useUpdateChannelCost` → `UPDATE channel_costs SET cost_per_unit = ? WHERE id = ?` no schema da org (`orgClient`). O hook aceita também `description` e `is_active`, mas **a UI não expõe nenhum dos dois**.

**Toasts:** "Custo atualizado com sucesso" (título apenas) · "Erro ao atualizar custo" + `error.message`.

### B7.6 Estado vazio e inicialização

`Card` com `CardContent flex flex-col items-center justify-center py-8`:
- `DollarSign h-12 w-12 text-muted-foreground mb-4`
- `p text-muted-foreground mb-4` → "Nenhum custo configurado"
- `Button` com `RotateCcw h-4 w-4 mr-2` (e `Loader2` durante) → **"Inicializar Custos Padrao"**

**Mecânica (`useInitializeChannelCosts`), idempotente:**
1. Verifica se já existe algum registro (`select("id").limit(1)`). Se sim, retorna `{ created: 0, message: "Custos ja configurados" }` **sem toast** (o `onSuccess` só notifica se `created > 0`).
2. Senão, faz `upsert` dos 10 defaults com `onConflict: "channel"`, todos com `is_active: true`.

**Toast:** "10 custos de canal criados" (título apenas) · erro: "Erro ao inicializar custos" + mensagem.

### B7.7 Os 10 custos padrão (`DEFAULT_CHANNEL_COSTS`)

| # | `channel` | Custo (R$) | `description` |
|---|---|---|---|
| 1 | `whatsapp` | 0,40 | WhatsApp (Hyperflow) |
| 2 | `sms` | 0,09 | SMS |
| 3 | `email` | 0,003 | Email (SES) |
| 4 | `voice` | 0,35 | Voz/TTS (por ligacao) |
| 5 | `negativation` | 3,00 | Negativacao (Serasa/SPC) |
| 6 | `ai` | 0,15 | IA (por interacao) |
| 7 | `human_activity` | 0,00 | Atividade Humana |
| 8 | `webhook` | 0,00 | Webhook |
| 9 | `block` | 0,00 | Bloqueio |
| 10 | `notification` | 30,00 | Notificacao |

### B7.8 Estados

| Estado | Render |
|---|---|
| Carregando | `Loader2 h-6 w-6 animate-spin`, `py-12` — substitui a aba |
| Vazio | Card com CTA "Inicializar Custos Padrao" |
| Preenchido | Card com tabela |
| Linha em edição | Input + dois botões de ação; o lápis desaparece |
| Salvando | `Loader2` no botão de confirmar; ambos os botões `disabled` |

**Tolerância a tabela inexistente:** mesma proteção `42P01` do `useBlockedDates` — devolve array vazio e desliga o retry.

### B7.9 Dores específicas

| Dor | Detalhe |
|---|---|
| **Sem gate de permissão** | Qualquer um edita custo |
| **`notification` sem metadados** | A linha mais cara da tabela (R$ 30,00) aparece com rótulo cru em inglês |
| **Mapa de canal duplicado e divergente** | 3 mapas diferentes (`INTEGRATION_TYPES`, `TYPE_ICONS`, `CHANNEL_META`) para o mesmo conceito |
| **Ordenação alfabética** | Canais de maior volume (WhatsApp) ficam no fim da lista |
| **Validação silenciosa** | Valor inválido não gera nenhuma mensagem |
| **Sem adicionar / remover canal** | A tabela é fechada — só o que a inicialização criou |
| **`description` e `is_active` não editáveis** | O hook suporta, a UI não expõe. Um canal com `is_active = false` fica **indistinguível** na tabela |
| **Sem histórico** | Não há registro de quando/por quem o custo mudou, embora os valores alimentem estimativas usadas em decisão |
| **Sem sinal de unidade** | "por ação", "por interação" e "por ligação" só aparecem na descrição livre de cada linha |

---

## B8. Aba **Variaveis** (Variáveis Personalizadas)

**Arquivo:** `src/components/settings/tabs/CustomVariablesTab.tsx`
**Sub-componentes:** `src/components/settings/VariableDefinitionFields.tsx`, `src/components/settings/VariablePreviewPanel.tsx`
**Hooks:** `useCustomVariablesList`, `useCreateCustomVariable`, `useUpdateCustomVariable`, `useDeleteCustomVariable`, `useCustomVariableCatalog` (`src/hooks/useCustomVariables.ts`)
**Motor:** `src/lib/template-variables.ts` — re-export puro de `supabase/functions/_shared/template-variables.ts` (o **mesmo** módulo usado pelo envio)

### B8.1 Objetivo

Criar variáveis de organização usáveis em qualquer template como `{{var.<chave>}}`. Desde a IAF-6862, uma variável personalizada pode ser de **três naturezas**:

| Tipo (`definition`) | Valor no banco | Comportamento |
|---|---|---|
| **Texto fixo** (`definition = null`) | `value` literal | O texto sai **exatamente** como escrito. **Nem é olhado por token** — variável legada cujo texto contém `{{...}}` continua saindo com as chaves |
| **Composição de variáveis** (`kind: "template"`) | `value` renderizado | O `value` é um template que pode citar outras variáveis (`{{contact.name}}`, `{{var.outra}}`…) |
| **Lista configurável** (`kind: "list"`) | `value` = texto **por item** | Fonte (contratos ou parcelas do contato), filtros, ordenação, limite, separador e texto de lista vazia vêm do próprio `definition` |

> **Regra 45 do `CLAUDE.md`, que o design precisa respeitar:** `definition = NULL` é **opt-in legado** e **nenhuma variável existente foi convertida**. Colapsar os três casos em "tem token, então renderiza" reescreveria mensagens em produção sem ninguém pedir. Na UI isso aparece como o `Select` "Tipo de conteúdo" com o valor `literal` distinto dos outros dois.

### B8.2 Permissões

`canEdit = hasPermission("settings:write")`. Sem permissão: sem botão "Nova Variavel", `Switch` de ativo `disabled`, e os botões de editar/remover de cada linha `disabled` (visíveis, porém inertes).

### B8.3 Anatomia da listagem

Um `Card`.

**`CardHeader`** — `flex items-start justify-between`:
- Esquerda: `CardTitle` com `Braces h-5 w-5` + "Variaveis Personalizadas"; `CardDescription mt-1.5`:
  > "Crie textos, composições de variáveis e listas de contratos ou parcelas para usar nas mensagens. Use `{{var.nome_da_variavel}}` nos templates."
  (o trecho `{{var.nome_da_variavel}}` é renderizado como `<code className="text-xs bg-muted px-1 py-0.5 rounded">`)
- Direita: `Button size="sm"` "Nova Variavel" com `Plus h-4 w-4 mr-2` (só se `canEdit`).

**Campo de busca** — `div relative mb-4` com `Search h-4 w-4` absoluto à esquerda (`left-3 top-1/2 -translate-y-1/2 text-muted-foreground`) e `Input className="pl-9"`, placeholder "Buscar por chave ou label...". Busca **server-side** nos campos `label` e `variable_key` (config do `createCrudHooks`), sem debounce.

**Tabela** — dentro de `div border rounded-lg`:

| Coluna | Largura | Conteúdo |
|---|---|---|
| **Ativo** | `w-[60px]` | `Switch` ligado a `is_active`, `disabled={!canEdit}` |
| **Chave** | auto | `<code className="text-xs bg-muted px-2 py-1 rounded">var.{chave}</code>` + `Button variant="ghost" size="icon" h-6 w-6` de cópia (`title="Copiar variavel"`) |
| **Label** | auto | `v.label` (`font-medium`) |
| **Valor** | auto | `span text-sm text-muted-foreground max-w-[200px] truncate block` |
| **Acoes** | `text-right` | `Pencil h-4 w-4` (editar) + `Trash2 h-4 w-4` (remover), ambos `variant="ghost" size="icon"`, `disabled={!canEdit}` |

**Linha inativa** ganha `opacity-50` na `TableRow` inteira.

**Botão de cópia:** copia **`{{var.<chave>}}`** completo (não só a chave) para a área de transferência. O ícone vira `Check h-3 w-3 text-green-600` por **2 segundos**. **Sem toast.**

**Ordenação:** `label` ascendente (config do CRUD factory).

### B8.4 Estados da listagem

| Estado | Render |
|---|---|
| **Erro de consulta** | `p role="alert" className="text-sm text-destructive"` → "Não foi possível consultar as variáveis: `<mensagem>`" |
| Carregando | `Loader2 h-8 w-8 animate-spin`, `py-12` |
| Vazio | `div text-center py-12 border rounded-lg bg-muted/50` com `Braces h-12 w-12`, `h3 text-lg font-medium` "Nenhuma variavel personalizada", `p text-sm text-muted-foreground` "Crie textos, composições e listas de contratos ou parcelas. Confira o resultado com exemplos ou um cliente da base." e, se `canEdit`, `Button` "Criar Primeira Variavel" |
| Preenchido | Tabela |

> Esta aba trata erro de listagem explicitamente (`listError`) — assim como `UsersTab`. Bom padrão a propagar.

### B8.5 Modal **Nova / Editar Variavel** — visão geral

| Item | Detalhe |
|---|---|
| Objetivo | Criar/editar uma variável, com pré-visualização ao vivo ao lado |
| Gatilho | "Nova Variavel", "Criar Primeira Variavel" ou o lápis da linha |
| Container | `Dialog` → `DialogContent w-full max-w-6xl max-h-[90vh] flex flex-col overflow-hidden` — **o maior modal do sistema** |
| Título | "Nova Variavel" / "Editar Variavel" |
| Descrição | "Crie um texto, uma composição ou uma lista para usar em mensagens" / "Edite as informacoes da variavel personalizada" |
| Layout | `grid gap-6 lg:grid-cols-[minmax(0,1.1fr)_minmax(0,1fr)]` — **duas colunas a partir de `lg`**, empilhadas abaixo disso |
| Coluna esquerda | Formulário (`space-y-4 min-w-0`) |
| Coluna direita | `VariablePreviewPanel`, `lg:sticky lg:top-0 self-start lg:max-h-[65vh] lg:overflow-y-auto` |
| Rodapé | `Cancelar` (outline) + `Criar`/`Salvar` (com `Loader2` durante a mutation) |

**Reset:** ao fechar (`!dialogOpen`), zera `formData` para `EMPTY_FORM`, limpa `formErrors` e `editingVar`.

**Default de nova variável:** `definition = { version: 1, kind: "template" }` — ou seja, o tipo pré-selecionado é **"Composição de variáveis"**, não "Texto fixo".

**Remontagem do preview:** o `VariablePreviewPanel` recebe `key={\`${currentOrg?.slug}-${dialogOpen}-${editingVar?.id ?? "new"}\`}` — trocar de org, abrir/fechar ou mudar de variável **descarta o estado interno do painel** (modo, cliente selecionado, referências).

### B8.6 Campos do formulário (coluna esquerda)

#### 1. Chave da Variavel *

| Item | Detalhe |
|---|---|
| `id` | `variable_key` |
| Controle | `Input` |
| **Sanitização ao digitar** | `e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, "")` — caracteres inválidos **somem enquanto se digita** |
| Placeholder dinâmico | `list` → "ex: resumo_contratos" · `template` → "ex: saudacao" · `literal` → "ex: telefone_empresa" |
| Ajuda | "Usada como `{{var.<chave ou 'chave'>}}`" — atualiza ao vivo |
| Erro | `p text-xs text-destructive` |

#### 2. Nome de exibição *

| Item | Detalhe |
|---|---|
| `id` | `label` |
| Controle | `Input` |
| Placeholder dinâmico | `list` → "ex: Resumo dos contratos" · `template` → "ex: Saudação do cliente" · `literal` → "ex: Telefone da Empresa" |

#### 3. Bloco `VariableDefinitionFields` — ver B8.7

#### 4. Conteúdo * / Texto de cada item *

| Item | Detalhe |
|---|---|
| `id` | `value` |
| Rótulo dinâmico | `list` → **"Texto de cada item *"**; demais → **"Conteúdo *"** |
| Controle | `Textarea rows={5}` |
| Ferramenta ao lado do rótulo | `VariableInserter context="workflow"` — **só aparece se `definition !== null`** (isto é, **não** em "Texto fixo"). Insere a variável escolhida no **fim** do valor (`prev.value + variable`), não na posição do cursor |
| Placeholder dinâmico | `list`+`contracts` → `Contrato {{contract.number}}\nValor em aberto: R$ {{contract.total_open_value}}` · `list`+`titles` → `Parcela {{title.installment_number}} — {{title.due_date}} — R$ {{title.current_value}}` · `template` → `Olá {{contact.name}}!\nConfira seus contratos: {{var.contratos}}` · `literal` → `ex: (11) 99999-8888` |
| Ajuda dinâmica | `list` → "Este modelo se repete para cada item selecionado. Use Enter para separar as linhas do mesmo item." · demais → "O conteúdo será usado ao inserir esta variável nas mensagens." |

#### 5. Descricao (opcional)

`Input id="description"`, placeholder "Explique quando usar esta variável". **Não é exibida em lugar nenhum da listagem** — só existe no formulário.

⚠️ A confirmar: se a descrição aparece em algum picker de variáveis fora deste domínio.

### B8.7 Bloco de tipo e configuração (`VariableDefinitionFields`)

Container: `div space-y-4 rounded-lg border p-3`.

#### Campo "Tipo de conteúdo"

`Select id="variable-kind"`, valor `definition?.kind ?? "literal"`:

| Opção | Valor | `definition` resultante |
|---|---|---|
| **Texto fixo** | `literal` | `null` |
| **Composição de variáveis** | `template` | `{ version: 1, kind: "template" }` |
| **Lista configurável** | `list` | cópia de `DEFAULT_LIST_DEFINITION` |

> **Trocar de tipo descarta a configuração de lista** — voltar de `list` para `template` e de volta reinicia tudo nos defaults. Sem aviso.

**Dica para `template`:** `p text-xs text-muted-foreground` → "Use variáveis como `{{contact.name}}`, listas existentes e outras `{{var.chave}}`. Enter preserva a quebra de linha."

#### Campos exclusivos de **Lista configurável**

| # | Campo | `id` | Controle | Opções / faixa | Default |
|---|---|---|---|---|---|
| 1 | Itens da lista | `variable-source` | `Select` | **Contratos do cliente** (`contracts`) · **Parcelas do cliente** (`titles`) | `contracts` |
| 2 | Status das parcelas | — | `FilterMultiSelect` | todas as chaves de `TITLE_STATUS_CONFIG`, com `config.label` | `["Disponivel","Recomprado","Expirado"]` |
| 3 | Somente títulos cobráveis | `variable-cobravel` | `Switch` | rótulo completo: "Somente títulos cobráveis (Disponível, Recomprado ou Expirado, a partir de D-10)" | `true` |
| 4 | Ordenar por | `variable-order` | `Select` | **Número** (`number`) · **Vencimento** (`due_date`) · **Dias em atraso** (`days_overdue`) · **Valor** (`value`) | `days_overdue` |
| 5 | Ordem | `variable-direction` | `Select` | **Crescente** (`asc`) · **Decrescente** (`desc`) | `desc` |
| 6 | Máximo de itens (1 a 50) | `variable-limit` | `Input type="number" min={1} max={50} step={1}` | 1–50 | `10` |
| 7 | Separação entre itens | `variable-separator` | `Select` | ver tabela abaixo | `\n\n` (paragraph) |
| 8 | Separador personalizado | `variable-custom-separator` | `Textarea maxLength={100}` | só aparece se o separador **não** for um dos 3 presets | `" | "` ao escolher "Personalizada" |
| 9 | Texto quando não há itens | `variable-empty` | `Input maxLength={500}` | — | "Nenhum item encontrado." |

Os campos 4–7 ficam num `grid grid-cols-2 gap-3`.

**Presets de separador:**

| Rótulo | Valor gravado |
|---|---|
| Uma quebra de linha | `"\n"` |
| Uma linha em branco | `"\n\n"` |
| Vírgula e espaço | `", "` |
| Personalizada | `" | "` (valor inicial; editável no campo 8) |

**Textos de ajuda da lista:**
- Sob "Itens da lista": *"Uma lista de parcelas usada dentro de uma lista de contratos mostra somente as parcelas daquele contrato."* — documenta o **aninhamento** de listas.
- Sob o multi-select de status: *"Sem seleção: todos os status. Na lista de contratos, entram os contratos com parcelas correspondentes. Registros removidos da origem são excluídos."*
- No fim do bloco (texto dinâmico pela fonte): *"O texto abaixo se repete para cada item. Use `{{contract.number}}` e `{{contract.total_open_value}}`"* (contratos) ou *"`{{title.number}}`, `{{title.installment_number}}`, `{{title.due_date}}` e `{{title.current_value}}`"* (parcelas). *"Itens que excederem o limite serão informados no final."*

### B8.8 Pré-visualização (`VariablePreviewPanel`)

`<section aria-label="Pré-visualização da variável" className="min-w-0 rounded-xl border bg-muted/30 p-4 space-y-4">`.

**Cabeçalho:** `h3` com `Eye h-4 w-4` + "Pré-visualização"; `p text-sm text-muted-foreground` → "Veja o texto mudar enquanto edita, sem precisar salvar."

**Seletor de fonte de dados** — `Select id="variable-preview-source"`:

| Opção | Valor | Comportamento |
|---|---|---|
| **Dados de exemplo** | `example` | Usa `VARIABLE_EXAMPLES` + `TEMPLATE_PREVIEW_COLLECTIONS`. Nota: *"Dados fictícios: 2 contratos e 4 parcelas, incluindo uma paga. Os filtros definem quais aparecem."* |
| **Cliente da base** | `customer` | Busca um cliente real e resolve com os dados dele |

Trocar de modo **limpa** o cliente selecionado e as referências.

#### Modo "Cliente da base"

**Busca** — `Input id="variable-preview-customer" maxLength={200}` com ícone `Search` (`absolute left-3 top-3`), placeholder `CUSTOMER_SEARCH_PLACEHOLDER`. Debounce de **300 ms** (`useDebouncedValue`). A lista fica em `div max-h-44 overflow-y-auto space-y-1` com **`aria-live="polite"`**.

Estados da lista de busca:

| Condição | Render |
|---|---|
| `< 2` caracteres | "Digite pelo menos 2 caracteres. Busca na organização atual." (`text-xs text-muted-foreground`) |
| Aguardando (debounce ou fetching) | "Buscando clientes…" |
| Erro | `p role="alert" text-sm text-destructive` com a mensagem |
| Zero resultados | "Nenhum cliente encontrado." |
| Resultados | `button` por cliente: nome (`font-medium`) + documento ou "Sem documento" (`text-xs text-muted-foreground`), com `hover:bg-muted focus-visible:ring-2 focus-visible:ring-ring` |
| Exatamente 20 resultados | Rodapé: "Primeiros 20 resultados. Refine a busca se necessário." |

**Cliente selecionado** — cartão `flex items-start justify-between gap-2 rounded-md border bg-background p-3` com nome (`font-medium break-words`) e documento, mais `Button variant="ghost" size="sm"` com `X h-4 w-4` e `aria-label="Trocar cliente"`.

**Carregamento de dados do cliente** — `p role="status"` com `Loader2 animate-spin` + "Carregando dados do cliente…".

**Erro de dados** — `div role="alert"` com a mensagem e `Button size="sm" variant="outline"` "Tentar novamente" (`data.refetch()`).

**Dados carregados** — linha informativa: "Base consultada: {n} contratos e {n} parcelas não removidas." + `Button variant="ghost" size="sm"` com `RefreshCw h-4 w-4` e `aria-label="Atualizar dados do cliente"`.

**Referências opcionais** — `<details>` colapsável, `summary` = "Contrato ou parcela de referência (opcional)". Explicação: *"Para campos individuais fora de uma lista. As listas continuam considerando os registros do cliente."* Dois `Select`:

| Campo | `id` | Opções |
|---|---|---|
| Contrato de referência | `variable-preview-contract` | "Nenhum" + "Contrato `<número>`" para cada contrato |
| Parcela de referência | `variable-preview-title` | "Nenhuma" + "Parcela `<número>` — `<dd/mm/aaaa>`", **filtradas pelo contrato escolhido** |

Trocar o contrato **reseta** a parcela.

**Nota de privacidade/segurança (sempre visível no modo cliente):**
> "Usa os dados disponíveis agora. O cliente serve apenas para a prévia e não fica vinculado à variável. Nenhuma mensagem é enviada."

#### Bloco "Texto gerado"

`div space-y-2 border-t pt-3`, `h4 text-sm font-medium` "Texto gerado". Cascata de estados:

| Ordem | Condição | Render |
|---|---|---|
| 1 | `catalogError` | `p role="alert" text-sm text-destructive` com o erro do catálogo |
| 2 | `!hasContent` | "Preencha o conteúdo ou o texto de cada item para ver o resultado." |
| 3 | `!sourceReady` | "Selecione um cliente e aguarde os dados para visualizar." |
| 4 | `preview.error` | `div role="alert"` com a mensagem + (no modo cliente) dica: "Para campos de contrato ou parcela fora de listas, escolha a referência acima. Dados exclusivos do envio, como um link ainda não gerado, podem não estar disponíveis nesta prévia." |
| 5 | sucesso | `div role="status" aria-label="Texto gerado da variável" className="max-h-72 overflow-auto rounded-md border bg-background p-3 text-sm whitespace-pre-wrap break-words"` |
| 5b | sucesso com texto vazio | `span text-muted-foreground` → "A variável produziu um texto vazio." |

#### Bloco "Itens selecionados"

Só quando `sourceReady && !catalogError && preview.lists.length > 0`. `div max-h-64 overflow-y-auto space-y-2` com um `<details>` por lista resolvida:

**`summary`:**
- Nome da variável — `"Variável em edição"` se a chave for `var.__preview_draft`, senão a chave sem o prefixo `var.`
- Se aninhada: `" · contrato <número>"`
- Linha secundária (`text-muted-foreground`): **"{totalMatched} {contratos|parcelas} correspondem aos filtros · {shownCount} exibidos · {omittedCount} omitidos pelo limite"**

**Itens** (`ul`, um `li` por item, `border-t pt-2`):

| Fonte | Linha 1 | Linha 2 |
|---|---|---|
| `contracts` | "Contrato `<número>`" | "Primeiro vencimento: `<dd/mm/aaaa>` · Em aberto nas parcelas elegíveis: `<R$>`" |
| `titles` | "Parcela `<número>`" | "`<status>` · Vencimento: `<dd/mm/aaaa>` · Valor: `<R$>`" |

Lista vazia: "Nenhum item atende à configuração atual."

**Formatadores locais:** `money` = `toLocaleString("pt-BR", { style: "currency", currency: "BRL" })`; `date` = `YYYY-MM-DD` → `DD/MM/YYYY`, com fallback **"Sem vencimento"**.

> **Este painel é o ponto forte de UX da tela toda.** Resolve a variável com o **mesmo motor do envio** (`createTemplateResolver`), com `unknown: "error"` — então variável desconhecida **falha** em vez de sair crua. E o bloco "Itens selecionados" explica *por que* a lista ficou daquele jeito (quantos casaram, quantos apareceram, quantos foram cortados pelo limite). O redesign deve preservar esse trio: **prévia · explicação · fonte de dados escolhível**.

### B8.9 Validações do formulário

Executadas em `validateForm()` ao clicar em Criar/Salvar:

| # | Campo | Regra | Mensagem |
|---|---|---|---|
| 1 | `variable_key` | não vazio | "Chave e obrigatoria" |
| 2 | `variable_key` | `/^[a-z0-9_]+$/` | "Use apenas letras minusculas, numeros e underscore" |
| 3 | `variable_key` | ≤ 100 caracteres | "Maximo 100 caracteres" |
| 4 | `variable_key` | `var.<chave>` não pode estar em `ALL_VARIABLE_KEYS` | "Esta chave conflita com uma variavel do sistema" |
| 5 | `variable_key` | não pode existir no catálogo (excluindo a que se edita) | "Esta chave ja existe" |
| 6 | `label` | não vazio | "Label e obrigatorio" |
| 7 | `value` | não vazio | "Valor e obrigatorio" |
| 8 | `definition` | `validateVariableDefinition()` | ver tabela abaixo |
| 9 | `value` | `preview.error` (erro de resolução do template) | a mensagem do motor |

**Mensagens de `validateVariableDefinition`** (motor compartilhado, `_shared/template-variables.ts`):

| Condição | Mensagem |
|---|---|
| Não é objeto / é array | "Configuração de variável inválida." |
| `version !== 1` ou `kind` fora de `template\|list` | "Versão ou tipo de variável inválido." |
| `source` fora de `contracts\|titles` | "Selecione contratos ou parcelas como fonte." |
| `statuses` não-array, > 30 itens, ou item não-string / > 100 chars | "Seleção de status inválida." |
| `cobravelOnly` não booleano | "Regra de títulos cobráveis inválida." |
| `orderBy`/`direction` fora do enum | "Ordenação inválida." |
| `limit` não inteiro, < 1 ou > 50 | "O limite deve ser um inteiro entre 1 e 50." |
| `separator` > 100 chars ou `emptyText` > 500 chars | "Separador ou texto de lista vazia inválido." |

**Mensagens do grafo de dependências** (`templateDependencies`):

| Condição | Mensagem |
|---|---|
| Ciclo | "Referência circular: `<a → b → a>`." |
| Profundidade | "A composição excede 12 níveis." |
| Definição filha inválida | "`<chave>`: `<mensagem do validador>`" |

Limite global de tamanho: `MAX_TEMPLATE_LENGTH = 256_000` caracteres.

> **Observação de design importante:** os erros 8 e 9 são ambos gravados em `errors.value`, ou seja, **aparecem sob o campo Conteúdo** mesmo quando o problema está na configuração da lista (campos do bloco acima). O redesign deve posicionar o erro junto ao campo culpado.

### B8.10 O catálogo completo (`useCustomVariableCatalog`)

A validação de grafo **não pode depender da busca/paginação** — por isso existe uma query separada que carrega **todas** as variáveis da org, paginando de 500 em 500 com `count: "exact"`, `staleTime: 60_000`.

Erros próprios desse carregamento:

| Condição | Mensagem |
|---|---|
| `count` nulo ou mudou entre páginas | "O catálogo mudou durante a leitura. Tente novamente." |
| > 5.000 variáveis, ou página vazia antes de completar | "Não foi possível carregar o catálogo completo de variáveis." |
| Sem org | "Organização não disponível." |

Na UI, enquanto carrega, o preview mostra **"Carregando catálogo de variáveis…"**; em erro, **"Não foi possível validar o catálogo. Tente novamente."** (no `preview`) ou **"Não foi possível carregar o catálogo. Tente novamente."** (no painel).

### B8.11 Persistência

`createCrudHooks` sobre a tabela `custom_variables` do schema da org:

| Config | Valor |
|---|---|
| `tableName` | `custom_variables` |
| `queryKey` | `custom-variables` |
| `resultKey` | `customVariables` |
| `searchFields` | `["label", "variable_key"]` |
| `orderBy` | `label` ascendente |
| `additionalInvalidateKeys` | `["custom-variable-catalog", "custom-variables-for-picker"]` |

**Toasts:** "Variavel criada" · "Variavel atualizada" · "Variavel removida" (todos só com título). Erro ao salvar: "Erro ao salvar" / **"Verifique se a chave nao esta duplicada"** — mensagem genérica que ignora a causa real (o `catch` descarta o erro).

**Alternar ativo:** `updateVar.mutateAsync({ id, is_active: !is_active })` — **sem confirmação e sem toast**.

### B8.12 Modal **Remover Variavel**

| Item | Detalhe |
|---|---|
| Container | `AlertDialog` |
| Título | "Remover Variavel" |
| Descrição | "Tem certeza que deseja remover a variavel \"`<label>`\"? Mensagens que usam `{{var.<chave>}}` deixarao de ser resolvidas." |
| Botões | `AlertDialogCancel` "Cancelar" + `AlertDialogAction` "Remover" com `className="bg-destructive text-destructive-foreground hover:bg-destructive/90"` e `Loader2` durante |

**Boa prática já presente:** o diálogo **nomeia** a variável e **mostra o token** que vai quebrar. É o diálogo destrutivo mais bem escrito do sistema — modelo para os demais.

> **O que falta:** não informa **quantas/quais mensagens** usam a variável. A informação existe no grafo de dependências (`templateDependencies`), mas não é consultada aqui. Uma contagem de referências transformaria esse diálogo de "aviso genérico" em "impacto conhecido".

### B8.13 Dores específicas

| Dor | Detalhe |
|---|---|
| **Erro no campo errado** | Erros de configuração de lista aparecem sob "Conteúdo" |
| **Troca de tipo destrói configuração** | Sem aviso |
| **`VariableInserter` insere no fim** | Não respeita a posição do cursor no textarea |
| **Descrição invisível** | Campo existe no form e nunca é exibido |
| **Mensagem de erro genérica ao salvar** | "Verifique se a chave nao esta duplicada" mesmo quando a causa é outra |
| **Sem contagem de uso** | Não se sabe onde a variável é usada antes de removê-la |
| **Busca sem debounce** | Cada tecla dispara nova query |
| **Modal muito largo** | `max-w-6xl` num modal empilha mal em telas médias (o grid só vira 2 colunas em `lg`) |
| **Sem acento nos rótulos base** | "Variaveis Personalizadas", "Nova Variavel", "Chave da Variavel", "Descricao", "Acoes" — enquanto os textos novos (IAF-6862) estão acentuados corretamente. A tela mistura as duas grafias |

---

## B9. Aba **Valores Padrao** (Valores Padrão de Normalização)

**Arquivo:** `src/components/settings/StandardValuesSettings.tsx`
**Hooks:** `useStandardValues`, `useCreateStandardValue`, `useUpdateStandardValue`, `useDeleteStandardValue`, `useInitializeDefaultValues` (`src/hooks/useStandardValues.ts`)

### B9.1 Objetivo

Definir o vocabulário canônico da organização e os **aliases** que o ETL usa para normalizar dados importados. Quando uma planilha traz "paid" ou "liquidado", a Torre precisa saber que isso é `Pago`.

### B9.2 Permissões

`canEdit = hasPermission("settings:write")`. Sem permissão: sem "Novo Valor", `Switch` de ativo `disabled`, lápis e lixeira `disabled`, botão "Importar" `disabled`. O botão **"Exportar" permanece habilitado** (só depende de haver dados) — leitura é livre.

### B9.3 Anatomia

Um `Card` externo contendo `Tabs` de 4 sub-abas.

**`CardHeader`** — `flex items-start justify-between`:
- Esquerda: `CardTitle` com `Tag h-5 w-5` + "Valores Padrão de Normalização"; `CardDescription mt-1.5` → "Configure os valores padrão utilizados na normalização de dados importados via ETL. Esses valores são aplicados automaticamente durante o mapeamento de campos."
- Direita (`flex gap-2`): `input type="file" accept=".json"` oculto + dois botões:

| Botão | Ícone | `disabled` quando |
|---|---|---|
| **Importar** | `Upload h-4 w-4 mr-2` (ou `Loader2` girando) | `!canEdit \|\| isImporting` |
| **Exportar** | `FileJson h-4 w-4 mr-2` | `!allValues \|\| allValues.length === 0` |

### B9.4 As 4 sub-abas (`FIELD_TYPE_LABELS`)

`TabsList grid grid-cols-4 w-full` — largura igual, **o rótulo textual some abaixo de `sm`** (`<span className="hidden sm:inline">`), restando só o ícone.

| `value` | Rótulo | Ícone | Descrição exibida na aba |
|---|---|---|---|
| `status` (default) | Status | `Tag` | "Status de títulos e contratos (Pendente, Pago, Vencido, etc.)" |
| `payment_method` | Métodos de Pagamento | `CreditCard` | "Formas de pagamento (PIX, Boleto, Cartão, etc.)" |
| `modality` | Modalidades | `Package` | "Modalidades de crédito e produtos (Empréstimo, Financiamento, etc.)" |
| `action_status` | Status de Ações | `Activity` | "Status de ações de cobrança (Sucesso, Falha, Pendente, etc.)" |

### B9.5 Conteúdo de cada sub-aba

**Barra superior** — `flex items-start justify-between gap-4`:
- Esquerda: a descrição do tipo (`text-sm text-muted-foreground`).
- Direita (`flex gap-2`):
  - **"Carregar Padrões"** (`variant="outline" size="sm"`, ícone `Sparkles h-4 w-4 mr-2` ou `Loader2`) — **só aparece quando a lista está vazia**.
  - **"Novo Valor"** (`size="sm"`, `Plus h-4 w-4 mr-2`) — só se `canEdit`.

**Tabela** (dentro de `div border rounded-lg`):

| Coluna | Alinhamento | Conteúdo |
|---|---|---|
| **Ativo** | esquerda | `Switch` ligado a `is_active`, `disabled={!canEdit}` |
| **Valor Interno** | esquerda | `<code className="text-xs bg-muted px-2 py-1 rounded">` + **badge "Sistema"** (`variant="secondary" ml-2 text-xs`) quando `is_system` |
| **Rótulo** | esquerda | `Badge variant="outline"` com a classe de cor do registro (`value.color`) |
| **Aliases** | esquerda | Até **3** `Badge variant="outline" text-xs`; acima disso, um badge `+N`. Container `flex flex-wrap gap-1 max-w-xs` |
| **Ações** | direita | `Pencil` (editar) + `Trash2` (remover) |

**Linha inativa** ganha `opacity-50`.

**Regra de proteção:** o botão de remover é `disabled={!canEdit || value.is_system}` — **valores de sistema não podem ser excluídos**, apenas desativados ou editados no rótulo/aliases/cor. (No modal de edição, o campo "Valor Interno" também fica `disabled` para `is_system`.)

**Ordenação:** `display_order` ascendente, depois `label` ascendente.

**Estado vazio** — `div text-center py-12 border rounded-lg bg-muted/50` com o ícone do tipo ativo (`h-12 w-12`), `h3 text-lg font-medium` "Nenhum valor configurado", `p text-sm` "Clique em \"Carregar Padrões\" para iniciar com valores recomendados" e `Button variant="outline"` com `Download h-4 w-4 mr-2` → **"Carregar Valores Padrão"**.

> **Inconsistência a corrigir:** o mesmo comando tem **dois rótulos e dois ícones** — "Carregar Padrões" (`Sparkles`) na barra superior e "Carregar Valores Padrão" (`Download`) no estado vazio. Quando a lista está vazia, **ambos aparecem simultaneamente**.

### B9.6 Modal **Novo / Editar Valor**

| Item | Detalhe |
|---|---|
| Container | `Dialog` → `DialogContent max-w-md` |
| Título | "Novo Valor" / "Editar Valor" |
| Descrição | "Adicione um novo valor para `<rótulo do tipo ativo>`" / "Edite as informações do valor padrão" |
| Rodapé | `Cancelar` (outline) + `Criar`/`Salvar` (com `Loader2` durante) |

**Campos** (`div space-y-4`):

| # | Campo | `id` | Controle | Obrigatório | Detalhes |
|---|---|---|---|---|---|
| 1 | Valor Interno * | `value` | `Input` | sim | Placeholder "ex: Disponivel, Pago, PIX". **Sanitiza ao digitar**: `replace(/[^\w\s\u00C0-\u024F]/gu, "")` — remove tudo que não for letra (incl. acentuadas Latin-1/Latin Extended-A), número, espaço ou `_`. `disabled` se `editingValue?.is_system`. Ajuda: "Identificador único (letras, números, espaços e underscore)" |
| 2 | Rótulo de Exibição * | `label` | `Input` | sim | Placeholder "ex: Pendente, Pago, PIX" |
| 3 | Aliases para Detecção Automática | — | `Input` + botão `Plus` | não | Ver abaixo |
| 4 | Cor do Badge | — | paleta de 12 bolinhas | não | Ver abaixo |

**Editor de aliases:**
- `Input` com placeholder "Digite um alias e pressione Enter" + `Button variant="outline"` com `Plus h-4 w-4`.
- `Enter` adiciona (com `preventDefault`).
- Cada alias é **normalizado**: `trim().toLowerCase()`, e **duplicatas são ignoradas** silenciosamente.
- Aliases existentes viram `Badge variant="secondary" gap-1` com um `<button>` `X h-3 w-3` (`hover:text-destructive`) para remover.
- Ajuda: "Textos alternativos que serão reconhecidos automaticamente durante a importação".

**Seletor de cor** — 12 opções (`COLOR_OPTIONS`), cada uma um `<button>` `w-8 h-8 rounded-full border-2` com a classe de fundo. Selecionada: `border-primary ring-2 ring-primary/30` e um ponto interno `w-2 h-2 rounded-full` na cor do texto. `title` = nome da cor.

| # | Rótulo | Valor gravado |
|---|---|---|
| 1 | Padrão | `""` (nenhuma classe) |
| 2 | Verde | `bg-green-100 text-green-800` |
| 3 | Azul | `bg-blue-100 text-blue-800` |
| 4 | Amarelo | `bg-yellow-100 text-yellow-800` |
| 5 | Vermelho | `bg-red-100 text-red-800` |
| 6 | Roxo | `bg-purple-100 text-purple-800` |
| 7 | Rosa | `bg-pink-100 text-pink-800` |
| 8 | Laranja | `bg-orange-100 text-orange-800` |
| 9 | Ciano | `bg-cyan-100 text-cyan-800` |
| 10 | Esmeralda | `bg-emerald-100 text-emerald-800` |
| 11 | Índigo | `bg-indigo-100 text-indigo-800` |
| 12 | Cinza | `bg-slate-100 text-slate-800` |

Abaixo da paleta, quando há cor escolhida, aparece um **preview** (`Badge variant="outline"` com a cor) exibindo o rótulo digitado ou a palavra "Preview".

> **Nota técnica para o redesign:** as cores são **strings de classe Tailwind gravadas no banco**. Isso amarra a aparência à implementação atual (sem variante `dark:`) e impede a troca do design system sem migração de dados. Trocar por tokens semânticos (`success`, `warning`, `danger`, `neutral`…) resolveria o dark mode e desacoplaria.

**Validações:**

| # | Campo | Regra | Mensagem |
|---|---|---|---|
| 1 | `value` | não vazio | "Valor interno é obrigatório" |
| 2 | `value` | `/^[\w\s\u00C0-\u024F]+$/u` | "Use apenas letras, números, espaços e underscore" |
| 3 | `value` | **na criação**, não pode duplicar dentro do tipo ativo | "Este valor já existe" |
| 4 | `label` | não vazio | "Rótulo é obrigatório" |

> **Lacuna:** a checagem de duplicidade **não roda na edição** (`if (!editingValue && ...)`), então renomear um valor para um já existente passa pelo frontend.

**Toasts (dos hooks):** "Valor criado com sucesso" · "Valor atualizado com sucesso" · "Valor removido com sucesso" · e os erros "Erro ao criar/atualizar/remover valor" + mensagem.

### B9.7 Modal **Remover Valor**

| Item | Detalhe |
|---|---|
| Container | `AlertDialog` |
| Título | "Remover Valor" |
| Descrição | "Tem certeza que deseja remover o valor \"`<label>`\"? Esta ação não pode ser desfeita." |
| Botões | "Cancelar" + "Remover" (`bg-destructive ...`, com `Loader2`) |

**Não diz** quais dados ou mapeamentos de ETL dependem daquele valor.

### B9.8 Exportar / Importar JSON

**Exportar** (`handleExport`):
- Usa **todos** os valores (`useStandardValues()` sem filtro), não só a aba ativa.
- Remove `id`, `created_at` e `updated_at` do JSON.
- Gera `Blob` `application/json`, cria um `<a download>` temporário e clica.
- Nome do arquivo: **`standard-values-YYYY-MM-DD.json`**.
- Sem dados → toast destrutivo "Nenhum valor para exportar" / "Configure alguns valores antes de exportar."
- Sucesso → toast "Exportação concluída" / "`<n>` valores exportados com sucesso."

**Importar** (`handleImport`) — validado com **Zod**:

```
z.array(z.object({
  field_type: z.enum(["status","payment_method","modality","action_status"]),
  value: z.string().min(1, "Valor interno é obrigatório"),
  label: z.string().min(1),
  aliases: z.array(z.string()).optional().default([]),
  is_active: z.boolean().optional().default(true),
  is_system: z.boolean().optional().default(false),
  display_order: z.number().int().optional().default(0),
}))
```

| Etapa | Comportamento |
|---|---|
| JSON malformado | Erro: "Arquivo JSON inválido. Verifique a sintaxe do arquivo." |
| Falha de schema | Erro: "Erro de validação:\n`<caminho → mensagem>`" — **no máximo 5 linhas**, seguidas de "...e mais N erros" |
| Upsert | Para cada item, procura `field_type + value` em `allValues`. Existe → `update` (label, aliases, is_active, display_order). Não existe → `create` |
| Resultado | Toast "Importação concluída" / "`<n>` criados, `<n>` atualizados." |
| Limpeza | `fileInputRef.current.value = ""` no `finally` |

> **Três problemas para o redesign:**
> 1. **Sem confirmação nem preview.** Selecionar o arquivo já dispara a importação, que **sobrescreve** valores existentes em silêncio.
> 2. **Uma mutation por item, em série** (`for ... await`). Um arquivo com 50 entradas = 50 requisições sequenciais, cada uma invalidando a query. Sem barra de progresso.
> 3. **Sem atomicidade.** Falha no item 30 deixa 29 aplicados e o resto não, com toast de erro genérico.

### B9.9 Os valores padrão (`DEFAULT_STANDARD_VALUES`)

Inseridos com `is_system: true` e `display_order` = índice.

**`status` — 15 valores:**

| Valor | Rótulo | Aliases |
|---|---|---|
| Disponivel | Disponivel | pending, available, open, aberto, pendente, aguardando, em aberto, a vencer |
| Pago | Pago | paid, liquidado, quitado, recebido, baixado |
| Cancelado | Cancelado | cancelled, canceled, excluido, excluded, cancelado, estornado, devolvido, anulado |
| Removido | Removido | removed, deletado, deleted |
| Renegociado | Renegociado | negotiated, negociado, renegociacao, acordo |
| Expirado | Expirado | expired, expirado |
| Recomprado | Recomprado | repurchased, recomprado, buyback |
| Provisionado | Provisionado | provisioned, provisionado |
| Pendente | Pendente | pending_cessao |
| Para Antecipar | Para Antecipar | — |
| Recompra Solicitada | Recompra Solicitada | — |
| Informacoes Pendente | Info. Pendente | informações pendente |
| Antecipacao Rejeitada | Antecip. Rejeitada | antecipação rejeitada |
| Aguardando Cancelamento | Aguard. Cancelamento | — |
| Aguardando Recompra | Aguardando Recompra | — |

**`payment_method` — 7 valores:** `pix` (PIX), `boleto` (Boleto), `credit_card` (Cartão de Crédito), `debit_card` (Cartão de Débito), `bank_transfer` (Transferência Bancária), `cash` (Dinheiro), `check` (Cheque).

**`modality` — 4 valores:** `Locacao`, `Recuperacao`, `Suprimento`, `Venda`.

**`action_status` — 12 valores**, únicos que trazem `color` **e** `metadata`:

| Valor | Cor | `classification` | `icon` | `counts_as_sent` / `_delivered` / `_response` |
|---|---|---|---|---|
| Pendente | `bg-yellow-100 text-yellow-800` | neutro | Clock | f / f / f |
| Processando | `bg-blue-100 text-blue-800` | neutro | Loader2 | f / f / f |
| Enviado | `bg-cyan-100 text-cyan-800` | enviado_ok | Send | **t** / f / f |
| Entregue | `bg-green-100 text-green-800` | entregue_ok | CheckCircle2 | t / **t** / f |
| Lido | `bg-emerald-100 text-emerald-800` | entregue_ok | Eye | t / t / f |
| Respondido | `bg-purple-100 text-purple-800` | resposta | MessageCircle | t / t / **t** |
| Falhou | `bg-red-100 text-red-800` | falha | XCircle | f / f / f |
| Falha Permanente | `bg-red-200 text-red-900` | falha | AlertTriangle | f / f / f |
| Em Atendimento | `bg-teal-100 text-teal-800` | enviado_ok | Headphones | t / f / f |
| Cancelado | `bg-orange-100 text-orange-800` | cancelado | XCircle | f / f / f |
| Cancelado (Pago) | `bg-green-100 text-green-800` | cancelado | DollarSign | f / f / f |
| Cancelado (Removido) | `bg-orange-100 text-orange-800` | cancelado | Trash2 | f / f / f |

> ⚠️ **Divergência com a invariante do sistema.** A regra 11 do `CLAUDE.md` define **12 status canônicos de ação**, incluindo **`Interagiu`** e **`Duplicado`**, e diz explicitamente para **nunca usar os status removidos "Entregue" e "Lido"**. A semente `DEFAULT_STANDARD_VALUES.action_status` deste arquivo **ainda traz "Entregue" e "Lido"** e **não traz "Interagiu" nem "Duplicado"**. Ou seja: uma organização que clicar em "Carregar Padrões" na sub-aba **Status de Ações** semeia o vocabulário **desatualizado**.
> ⚠️ A confirmar com o time: se essa semente ainda é usada em produção ou se a sub-aba deveria ser somente-leitura, já que os status de ação hoje são governados por `src/lib/constants/action-status-config.ts` + `action-status-display.ts`.

**`metadata` não é editável nem exibido na UI** — só existe na semente. Os campos `classification`, `icon`, `counts_as_sent/_delivered/_response` ficam invisíveis para quem administra.

### B9.10 Estados

| Estado | Render |
|---|---|
| Carregando (por sub-aba) | `Loader2 h-8 w-8 animate-spin`, `py-12` |
| Vazio | Bloco central com CTA de carregar padrões |
| Preenchido | Tabela |
| Importando | Botão "Importar" com spinner e desabilitado |
| Somente leitura | Sem "Novo Valor", switches/ações desabilitados; "Exportar" continua ativo |

### B9.11 Dores específicas

| Dor | Detalhe |
|---|---|
| **Semente de `action_status` desatualizada** | Ver o alerta acima |
| **Cores como classes Tailwind no banco** | Acopla design a dado; sem dark mode |
| **Import sem preview/confirmação/atomicidade** | Sobrescreve em silêncio |
| **Duas chamadas para a mesma ação** | "Carregar Padrões" e "Carregar Valores Padrão" |
| **Duplicidade não checada na edição** | Só na criação |
| **`metadata` invisível** | Semântica crucial (o que conta como enviado/respondido) sem representação na UI |
| **Sem reordenação** | `display_order` existe no dado e é respeitado na listagem, mas **não há UI para alterá-lo** (só via import) |
| **Aliases limitados a 3 na exibição** | O `+N` **não tem tooltip** — não há como ver os demais sem abrir o modal |

---

## B10. Aba **Reguas** (configurações globais de régua)

**Arquivo:** `src/components/settings/tabs/ReguasTab.tsx`
**Hooks:** `useOrganizationSettings`, `useUpdateOrganization`

### B10.1 Objetivo

**Não** é a tela de montar réguas. São **dois parâmetros globais** que alimentam visualizações: a faixa de classificação de dívida exibida nos cards das réguas, e o percentual de meta usado no gráfico "Tendência de Recuperação" do Dashboard.

> **Rótulo enganoso.** "Reguas" sugere o editor de réguas de cobrança (que vive em outra tela). O conteúdo real é "Indicadores de Dívida" + "Meta de Recuperação". Renomear no redesign (ex.: **"Indicadores e Metas"**).

### B10.2 Permissões

`canEdit = hasPermission("settings:write")`. Sem permissão: inputs e slider `disabled`, botão "Salvar Alteracoes" não renderizado.

### B10.3 Card 1 — "Indicadores de Divida"

`CardTitle` com `TrendingUp h-5 w-5`; `CardDescription` → "Configure os limites para classificacao de divida nos cards das reguas de cobranca".

**Grid `md:grid-cols-3`** (empilha abaixo de `md`):

| # | Campo | `id` | Controle | Marcador | Prefixo | Ajuda |
|---|---|---|---|---|---|---|
| 1 | Limite "Baixo" | `low-threshold` | `Input type="number" min={0} step={1000} className="w-32"` | bolinha `w-3 h-3 rounded-full bg-emerald-500` | "Ate R$" | "Dividas abaixo deste valor sao classificadas como \"Baixo\"" |
| 2 | Limite "Medio" | `medium-threshold` | `Input type="number" min={0} step={1000} className="w-32"` | bolinha `bg-amber-500` | "Ate R$" | "Dividas entre o limite baixo e este valor sao \"Medio\"" |
| 3 | Limite "Alto" | — | `Input` **`disabled` + `bg-muted`**, exibindo `mediumThreshold.toLocaleString("pt-BR")` | bolinha `bg-red-500` | "Acima de R$" | "Dividas acima do limite medio sao classificadas como \"Alto\"" |

A terceira coluna é **derivada**, não editável — existe só para completar a narrativa visual das três faixas.

**Prévia dos indicadores** — `div border rounded-lg p-4 bg-muted/30` com "Previa dos indicadores:" (`text-sm font-medium mb-3`) e três pílulas (`flex gap-4 flex-wrap`), cada uma `flex items-center gap-2 px-3 py-1.5 rounded-full` com ícone `TrendingUp h-3 w-3`:

| Pílula | Fundo / texto | Conteúdo |
|---|---|---|
| Baixo | `bg-emerald-100` / `text-emerald-700` | "Baixo (< R$ `<low>`)" |
| Medio | `bg-amber-100` / `text-amber-700` | "Medio (R$ `<low>` - R$ `<medium>`)" |
| Alto | `bg-red-100` / `text-red-700` | "Alto (> R$ `<medium>`)" |

Atualiza **ao vivo** conforme se digita.

**Defaults:** `low = 10.000`, `medium = 100.000`.

### B10.4 Card 2 — "Meta de Recuperacao"

`CardTitle` com `Target h-5 w-5`; `CardDescription` → "Configure o percentual da divida como meta de recuperacao mensal no grafico do Dashboard".

**Controle duplo** (`flex items-center gap-4`):
- `Slider id="recovery-goal"` com `min={1} max={100} step={1}`, `className="flex-1"`.
- `Input type="number" min={1} max={100} className="w-16 text-center"` + sufixo "%" — **com clamp real**: `Math.min(100, Math.max(1, Number(e.target.value)))`.

Ambos escrevem o mesmo estado; mexer num atualiza o outro.

**Ajuda:** "O grafico \"Tendencia de Recuperacao\" usara este percentual da divida mensal como meta".

**Prévia do cálculo** — `div border rounded-lg p-4 bg-muted/30` com `grid grid-cols-3 gap-4 text-sm`:

| Coluna | Rótulo | Valor |
|---|---|---|
| 1 | "Divida do mes" | `formatCurrency(1.000.000)` — exemplo fixo |
| 2 | "Meta (`<n>`%)" | `formatCurrency(1.000.000 × n/100)`, em `text-primary` |
| 3 | "Formula" | `divida × <n>%` (`font-mono text-xs`) |

**Default:** `80%`.

### B10.5 Salvar

`Button` **dentro do segundo card**, só se `canEdit`:
```
disabled = updateOrg.isPending || lowThreshold >= mediumThreshold
```

**Mensagem de erro** — abaixo do botão, quando `low >= medium`:
`p text-sm text-destructive` → "O limite \"Baixo\" deve ser menor que o limite \"Medio\"".

**Persistência:** merge em `organizations.settings`:
```
{ ...settingsAtuais, debtThresholds: { low, medium }, recoveryGoalPercentage }
```

**Sem toast de sucesso.**

### B10.6 O mesmo bug de inicialização de B2

`ReguasTab` repete o padrão `useState(() => {...})` de `OrganizationTab` — inicializador preguiçoso executado no primeiro render, quando `settings` ainda é `undefined`.

**Aqui o impacto é menor**, porque os estados são inicializados com `useState(savedThresholds.low)` etc., derivados de `settings` no corpo do componente. Mas `useState` só honra o valor inicial **no primeiro render** — se `settings` chegar depois (o que é o caso normal), os estados ficam nos **defaults constantes** (10.000 / 100.000 / 80%), **não** nos valores salvos.

**Consequência prática:** abrir a aba e clicar em "Salvar Alteracoes" sem tocar em nada pode **sobrescrever a configuração salva pelos defaults**.

⚠️ A confirmar: se o `isLoading` (que substitui a aba inteira por spinner) atrasa a montagem o bastante para os estados já nascerem com os valores salvos. Pela leitura, o `return` de loading acontece **depois** dos `useState`, então os estados são criados antes — e o bug é real.

### B10.7 Dores específicas

| Dor | Detalhe |
|---|---|
| **Rótulo enganoso** | "Reguas" não configura réguas |
| **Bug de inicialização** | Pode sobrescrever a configuração salva com defaults |
| **Botão de salvar no lugar errado** | Fica no segundo card, mas salva os dois |
| **Sem toast de sucesso** | Nenhum feedback de conclusão |
| **Erro de validação abaixo do botão** | Aparece depois do controle que ele bloqueia |
| **Exemplo fixo de R$ 1.000.000** | Não reflete a realidade da org |
| **Sem símbolo de moeda nos inputs** | "Ate R$" é texto solto ao lado, não prefixo do campo |
| **Cores sem dark mode** | `bg-emerald-100`, `bg-amber-100`, `bg-red-100` sem variante escura |

---

## B11. Aba **Perfil da Operacao** (Pipeline Profile)

**Arquivo:** `src/components/settings/tabs/PipelineProfileTab.tsx`
**Módulo puro:** `src/components/settings/tabs/pipelineProfileForm.ts`
**Hooks:** `useOrgPipelineProfile`, `useUpdateOrgPipelineProfile` (`src/hooks/useOrgPipelineProfile.ts`), `useCustomFieldDefinitions("contacts")`
**Seletor:** `src/components/organization/OrgProfileSelector.tsx`

### B11.1 Objetivo

Definir o **perfil de pipeline** da organização — hoje, `cobranca` (sem perfil, comportamento padrão) ou `formalizacao` — e, no caso de formalização, as **convenções de campo** que o motor de campanhas usa: de onde ler a etapa, a data de referência e o destinatário, e qual é o teto diário por contato.

É a aba de maior **consequência operacional** da tela toda: uma configuração errada aqui **para todas as campanhas da organização**.

### B11.2 Contexto arquitetural (do cabeçalho do arquivo)

> "Fecha o ciclo de vida do perfil da org: até aqui `public.org_pipeline_profile` tinha 4 leitores e **nenhum escritor** — a linha só existia se alguém rodasse SQL à mão, e as convenções eram invisíveis na tela."

- **Leitura** pela tabela, via `useOrgPipelineProfile` — **mesma query** que o `OrganizationContext` consome (mesma chave, servida do cache). A aba pede direto porque também exibe `updated_at`/`updated_by`.
- **Escrita** pela RPC `public.update_org_pipeline_profile`. A tabela é `service_role`-only na escrita; `public.pipeline_profile()` tem `EXECUTE` revogado de `authenticated` — **o front nunca a chama**.

### B11.3 Permissões e gate

| Gate | Regra |
|---|---|
| Ver a aba (em `SettingsPage`) | `isSuperAdmin \|\| (pipelineProfile !== null && hasPermission("settings:read"))` |
| Escrever (dentro da aba) | `canWrite = hasPermission("settings:write") \|\| isSuperAdmin` |

Sem escrita: todos os campos `disabled`, sem barra de ações, e um `Alert` com `Info h-4 w-4`:
> "Você pode ver o perfil, mas não alterá-lo. Alterações exigem permissão de escrita em configurações."

### B11.4 Anatomia

`div space-y-6`, **sem `Card` no topo** — cabeçalho próprio:
- `h3 text-lg font-medium` com `Workflow h-5 w-5` + "Perfil da Operação"
- `p text-sm text-muted-foreground`: "Define como as réguas desta organização decidem o que disparar — e de quais campos elas leem a etapa, a data de referência e o destinatário."

Depois, em ordem: alerta de erro do último save → aviso do último save → Card "Tipo da organização" → *(se formalização)* alerta de gatilho ausente → Card "Convenções dos campos" → Card "Teto diário por contato" → alerta de somente-leitura → barra de ações → `AlertDialog` de remoção.

### B11.5 Card "Tipo da organização"

`CardTitle text-base` = "Tipo da organização". `CardDescription` **dinâmica**:

| Estado salvo | Texto |
|---|---|
| `formalizacao` | "Trocar para Cobrança remove o perfil: as convenções abaixo são apagadas e as réguas voltam a disparar apenas por dias de atraso de títulos." |
| `cobranca` | "Cobrança é o comportamento de todas as organizações de hoje. Aplicar Formalização cria o perfil desta organização e habilita, nas réguas, o gatilho por etapa e o destinatário próprio." |

**Controle:** `OrgProfileSelector` (componente próprio), `value = choice`, `disabled = !canWrite`.

⚠️ A confirmar: a anatomia visual interna do `OrgProfileSelector` (arquivo fora da lista de leitura obrigatória deste documento).

**Linha de estado salvo** — `div flex flex-wrap items-center gap-1.5 text-xs text-muted-foreground`:
- "Estado salvo:" + `Badge variant="outline" font-normal` com "Formalização" ou "Cobrança"
- Se há perfil: "· última alteração em `<data/hora pt-BR>` por `<updated_by>`"

`formatUpdatedAt`: `toLocaleString("pt-BR")`; data inválida devolve a string crua; nulo vira `"—"`.
`formatUpdatedBy`: texto livre gravado pela RPC (uid, e-mail ou `'service'`); nulo vira `"—"`.

### B11.6 Card "Convenções dos campos" (só formalização)

`CardDescription`:
> "Todos apontam para campos personalizados **do contato** (o que o ETL grava em `custom_fields` de contatos). Campo de contrato não é lido aqui. Deixe vazio para desligar a capacidade."

**Quatro `FieldRow`**, cada um com ícone, `Input font-mono text-sm`, `datalist` de sugestões e um texto de ajuda longo:

| # | `id` | Rótulo | Ícone | Placeholder | O que a ajuda diz (resumo fiel) |
|---|---|---|---|---|---|
| 1 | `profile-etapa-field` | Campo da etapa | `Tag` | `Ex: custom.etapa` | "Etapa da negociação, comparada por **igualdade** com a etapa configurada em cada passo da régua. **Vazio = nenhum passo pode disparar por etapa.**" |
| 2 | `profile-reference-date-field` | Campo da data de referência | `CalendarClock` | `Ex: custom.data_entrada_etapa` | "Data de onde saem os 'dias' usados pelos passos que disparam por dia. Tem de estar em `AAAA-MM-DD`, ser uma data válida e **não estar no futuro** — fora disso o contato entra na execução com o motivo 'Sem data de referência válida' e não recebe nada. Vazio = a régua só dispara por etapa." |
| 3 | `profile-recipient-phone-field` | Campo do telefone do destinatário | `Phone` | `Ex: custom.vendedor_fone` | "Usado pelos passos com destinatário **'endereço da variável do perfil'** em canais de telefone (WhatsApp, SMS, voz, RCS). Máscara é aceita — o valor é normalizado para dígitos. **Vazio**: se o campo de e-mail abaixo estiver preenchido, é o **e-mail** que vai como destino desses passos (não existe validação de formato de telefone) e o envio falha no provedor; se nenhum dos dois estiver preenchido, a ação é criada e não é enviada — o envio **não** cai para o telefone do cliente." |
| 4 | `profile-recipient-email-field` | Campo do e-mail do destinatário | `Mail` | `Ex: custom.vendedor_email` | "Mesmo papel do campo acima, para passos de e-mail. **Vazio**: o passo de e-mail com destinatário por variável é **excluído** na execução, com o motivo 'Sem destinatário' — nenhuma ação é criada (o endereço resolvido não tem `@`)." |

**Comportamento do `FieldRow`:**
- `Input` com `list={datalistId}` — autocompletar nativo do browser.
- **Normaliza ao sair do campo** (`onBlur`): faz `trim()` e, se mudou, aplica. O motor tolera espaço (`btrim`), mas **ver o valor exato evita dúvida**.

**Sugestões (`datalist id="pipeline-profile-contact-fields"`):** nomes de campos personalizados **ativos** de contato (`useCustomFieldDefinitions("contacts")`), deduplicados, ordenados com `localeCompare(pt-BR)` e prefixados com `custom.` no `value` da `<option>`.

> **Esta é a melhor escrita de microcopy do sistema inteiro.** Cada campo explica **o que acontece se ficar vazio** — incluindo o caso perverso do telefone vazio + e-mail preenchido. O redesign deve preservar esse nível de precisão, mesmo que reorganize o layout (hoje são quatro parágrafos densos de `text-xs`, o que pesa visualmente).

### B11.7 Alerta "Falta configurar o gatilho"

Renderizado quando `isFormalizacao && profileHasNoTrigger(form)` (ambos os campos 1 e 2 vazios).

`Alert` **neutro** (sem `variant="destructive"`, de propósito — comentário do código: *"este é o estado NORMAL de uma organização recém-criada com o perfil... Pintar de vermelho faria parecer que a criação quebrou algo"*), com `ShieldAlert h-4 w-4`:

- **Título:** "Falta configurar o gatilho — nenhuma régua roda ainda"
- **Corpo:** "Preencha **o campo da etapa** ou **o campo da data de referência** (basta um dos dois). Enquanto nenhum deles estiver definido, a execução das campanhas desta organização é interrompida — de propósito: sem gatilho a régua não teria como casar nada, e o sintoma seria 'a régua não dispara', sem aviso nenhum."

### B11.8 Card "Teto diário por contato"

`CardDescription`: "Máximo de ações que um contato pode receber por dia nesta organização. O excedente é registrado como 'Teto diário atingido' e fica auditável."

| Item | Detalhe |
|---|---|
| `id` | `profile-daily-cap` |
| Rótulo | "Teto diário" + `<span className="font-normal text-muted-foreground">(vazio = sem teto)</span>` |
| Controle | `Input className="w-32 font-mono text-sm"`, `inputMode="numeric"` (teclado numérico no mobile, mas **não** `type="number"`) |
| Placeholder | `Ex: 3` |
| Normalização | `trim()` no `onBlur` |
| Ajuda | "Número inteiro. Conta o **dia** (desde a meia-noite de Brasília), não a execução — a mesma régua pode rodar várias vezes por dia. **0 é um teto válido** e bloqueia todos os envios, com rastro." |

**Alerta "Sem teto"** — quando `isFormalizacao && profileHasNoDailyCap(form)` (campo vazio; **`0` não conta como vazio**). `Alert` âmbar (`border-amber-300 bg-amber-50 text-amber-900 dark:bg-amber-950/30`) com `AlertTriangle h-4 w-4`:
- **Título:** "Sem teto, um passo por etapa pode enviar todos os dias"
- **Corpo:** "Um passo com gatilho por etapa e **sem** 'disparar uma única vez por contato' é reavaliado em toda execução: enquanto o contato permanecer naquela etapa, ele recebe todo dia. Neste perfil o teto diário é o **único freio por pessoa/dia** — o intervalo mínimo (cooldown) da campanha fica desligado e a cadência não se aplica a gatilho por etapa. Defina um teto ou marque 'disparar uma única vez' nos passos."

### B11.9 Barra de ações

`div flex flex-wrap items-center justify-end gap-3`, só se `canWrite`:

| Elemento | Detalhe |
|---|---|
| Indicador de sujeira | `span mr-auto text-xs text-muted-foreground` → "Alterações não salvas." — só quando `isDirty` |
| **Descartar** | `Button variant="outline"`, `disabled = !isDirty \|\| isPending`. Restaura `choice` e `form` do servidor e limpa avisos/erros |
| **Salvar / Remover perfil** | Rótulo e variante **dinâmicos**: em modo de remoção (`serverChoice === "formalizacao" && choice === "cobranca"`) vira **"Remover perfil"** com `variant="destructive"` e ícone `Ban h-4 w-4`; senão "Salvar" com `Save h-4 w-4`. `Loader2` durante. `disabled = !isDirty \|\| isPending` |

**`isDirty`** = `choice !== serverChoice || (isFormalizacao && !isProfileFormEqual(form, serverForm))`.

### B11.10 Validação (`validateProfileForm`)

Bloqueia o save **só** no que o motor descartaria em silêncio:

| Regra | Padrão | Mensagem |
|---|---|---|
| Nome de campo (os 4) | `/^(custom\.)?[a-z0-9_]+$/` — **espelho exato** do padrão validado pela RPC | "`<rótulo do campo>`: use o nome do campo em minúsculas (a-z, 0-9 e _), com o prefixo \"custom.\" opcional — por exemplo custom.etapa." |
| Teto diário | `/^\d+$/` (ou vazio) | "O teto diário precisa ser um número inteiro maior ou igual a zero (ou vazio, para não ter teto)." |

A validação vira **toast destrutivo** "Configuração inválida" + a mensagem, e **não salva**.

> "Nenhum gatilho configurado" **não bloqueia** — é estado intermediário legítimo; quem avisa é o alerta neutro de B11.7.

> **Por que a validação do teto é barreira e não enfeite:** o motor faz `CASE WHEN cfg->>'daily_cap' ~ '^[0-9]+$' THEN ...::INTEGER END`. Texto, negativo ou decimal caem em `NULL` = **sem teto, silenciosamente**.

### B11.11 Payload enviado (`buildProfileConfigPayload`)

**Sempre as 5 chaves**, com `null` nas vazias:

| Chave | Origem | Transformação |
|---|---|---|
| `etapa_field` | `etapaField` | `trim()`; `""` → `null` |
| `reference_date_field` | `referenceDateField` | idem |
| `recipient_phone_field` | `recipientPhoneField` | idem |
| `recipient_email_field` | `recipientEmailField` | idem |
| `daily_cap` | `dailyCap` | `Number(cap)` se casar `^\d+$`; senão `null` |

Motivo documentado: a semântica da RPC (substitui ou faz merge) não está sob controle da tela. Omitir chave vazia funciona se ela **substitui** e **falha em silêncio** se faz **merge**. Mandar `null` explícito dá o mesmo resultado nos dois casos — para o motor, `null` == ausente.

Ao **remover** o perfil, o payload vai com `EMPTY_PIPELINE_PROFILE_FORM` — as convenções todas em `null`, para que config de perfil inexistente não sobreviva a uma futura repromoção.

### B11.12 Feedback pós-save

**Toast** — título escolhido pelo que a RPC **fez** (`result.action`), não pelo que se pediu:

| `action` | Título | Descrição |
|---|---|---|
| `noop` | "Nada a alterar" | "Esta organização já estava sem perfil." |
| `removed` (ou `null` com `profile === null`) | "Perfil removido" | "As réguas desta organização voltam a disparar apenas por dias de atraso." |
| `created` | "Perfil aplicado" | "As convenções do perfil de formalização foram atualizadas." |
| outro | "Perfil salvo" | idem |

**Aviso persistente (`saveNotice`)** — `Alert` âmbar (`border-amber-300 bg-amber-50 text-amber-900 dark:bg-amber-950/30`) com `AlertTriangle`:

| `warningCode` | Título | Exibido? |
|---|---|---|
| `etapa_trigger_steps_orphaned` | "Passos de régua ficaram sem disparar" | **sim** |
| `profile_config_incomplete` | — | **não** — é o estado normal da org recém-criada; o alerta neutro do formulário já diz a mesma coisa |
| desconhecido | "Atenção" | sim (mostrar é melhor que engolir) |

**Erro persistente (`saveError`)** — `Alert variant="destructive"`, **permanece na tela** (ao contrário do toast). Dois casos distintos:

| Caso | Ícone | Título | Texto |
|---|---|---|---|
| RPC ausente no ambiente (`isMissingProfileRpcError`) | `Clock h-4 w-4` | "Gravação indisponível neste ambiente" | `PROFILE_RPC_UNAVAILABLE_MESSAGE` |
| Erro de validação/servidor | `AlertTriangle h-4 w-4` | "Não foi possível salvar" | `describeRpcError(error)` = `"<message> — <hint>"` |

`describeRpcError` existe porque o erro do PostgREST chega como **objeto** (`{ message, details, hint, code }`) e cairia no fallback genérico de `getErrorMessage` — jogando fora exatamente a parte útil: o **hint** da RPC diz o que corrigir (chave fora da allowlist, nome de campo inválido, teto negativo…).

**Nada é limpo no erro** — o formulário continua exatamente como estava.

> **Padrão de excelência:** distinguir "ainda não disponível neste ambiente" (ordem de deploy, volta a funcionar sozinho) de "sua configuração é inválida" (pede correção). Misturar as duas manda o operador procurar erro onde não há.

### B11.13 Re-hidratação por assinatura

Efeito com `profileFormSignature(profile, config)` como chave: um refetch que devolve os **mesmos** valores não dispara o efeito e **não apaga o que o usuário está digitando**. Quando o valor realmente muda (outra pessoa salvou, ou o próprio save), a tela passa a refletir o servidor.

A assinatura usa `JSON.stringify` (não `join`) porque concatenação simples tornaria `"ab" + ""` e `"a" + "b"` a **mesma** assinatura.

> **Contraste direto com B2 e B10.** As mesmas três abas resolvem "sincronizar formulário com dados do servidor" de três formas: `useState(() => ...)` quebrado (Organização e Réguas) e re-hidratação por assinatura (Perfil). O redesign deve padronizar pelo padrão desta aba.

### B11.14 Modal **Remover o perfil de formalização?**

| Item | Detalhe |
|---|---|
| Gatilho | Clicar em "Remover perfil" (o `handleSave` desvia para o diálogo quando `isRemoving`) |
| Container | `AlertDialog` |
| Título | `flex items-center gap-2 text-destructive` com `Ban h-5 w-5` + "Remover o perfil de formalização?" |
| Corpo | `AlertDialogDescription asChild` com um `div space-y-3 text-sm` de até 3 blocos |

**Blocos do corpo:**
1. "As convenções de campo desta organização serão apagadas e as réguas voltam a disparar apenas por dias de atraso de títulos."
2. "Passos já configurados com **gatilho por etapa** deixam de casar qualquer contato — ficam silenciosos, sem erro na tela. O mesmo vale para passos com destinatário por variável."
3. **Contagem de impacto** (`useEtapaTriggerStepCount`, só consulta quando o diálogo abre, `staleTime: 30_000`):

| Estado | Render |
|---|---|
| Carregando | `Skeleton h-4 w-56` |
| `> 0` | `p rounded-md border border-amber-300 bg-amber-50 p-2 text-amber-900` → "Hoje existem **`<n>`** passo(s) de régua com gatilho por etapa nesta organização." |
| `= 0` | `p text-muted-foreground` → "Nenhum passo de régua usa gatilho por etapa hoje." |
| Erro | **Fail-soft**: a confirmação continua, só sem o número |

A contagem consulta `workflow_steps` com `count: "exact", head: true`, filtrando `config->>etapa_trigger` não-nulo e não-vazio. O comentário do código explica a imprecisão deliberada: o PostgREST não faz `btrim`, então um valor só-de-espaços entra na contagem — **erra para mais num aviso, que é o lado seguro**.

**Rodapé:** `AlertDialogCancel` "Cancelar" + `AlertDialogAction` "Remover perfil" (`bg-destructive ...`), ambos `disabled` durante a mutation.

> **Este é o diálogo destrutivo de referência do sistema:** explica a consequência funcional (passos ficam silenciosos), **quantifica o impacto** e ainda diz que a falha é silenciosa. Modelo para todos os outros.

### B11.15 Estados

| Estado | Render |
|---|---|
| Sem org | `return null` |
| Carregando perfil | Três `Skeleton` (`h-6 w-64`, `h-32 w-full`, `h-64 w-full`) — **não** renderiza o formulário com "Cobrança" pré-selecionado, para não induzir a leitura errada |
| Cobrança | Só o Card "Tipo da organização" + barra de ações |
| Formalização | Todos os cards + alertas condicionais |
| Sem gatilho | Alerta neutro `ShieldAlert` |
| Sem teto | Alerta âmbar `AlertTriangle` |
| Sujo | "Alterações não salvas." + botões habilitados |
| Removendo | Botão vermelho "Remover perfil" com `Ban` |
| Salvando | `Loader2` no botão; ambos os botões desabilitados |
| Erro de save | `Alert` destrutivo persistente |
| Somente leitura | `Alert` informativo, sem barra de ações |

### B11.16 Dores específicas

| Dor | Detalhe |
|---|---|
| **Densidade de texto** | Quatro parágrafos longos de `text-xs`, cada um com 3–5 orações e negritos. O conteúdo é excelente, a forma cansa. Candidato a **divulgação progressiva** (resumo + "saiba mais") |
| **Sem validação de existência do campo** | O `datalist` **sugere**, mas nada impede digitar `custom.campo_que_nao_existe`. A consequência (execução parada) só aparece depois |
| **`inputMode="numeric"` sem `type="number"`** | O teto aceita qualquer texto; a validação só roda no save |
| **Vocabulário "etapa"** | Depende do leitor já conhecer o modelo de formalização; não há glossário na tela |
| **Sem prévia do efeito** | Não há "simular": mostrar quantos contatos teriam etapa válida com o campo escolhido |

---

## B12. Explorador de Campos (`FieldExplorerTab`) — **não montado**

**Arquivo:** `src/components/settings/tabs/FieldExplorerTab.tsx`
**Hook:** `useFieldExplorer` (`src/hooks/useFieldExplorer.ts`)

### B12.1 Status

**Este componente não é importado por `SettingsPage.tsx`.** Não há aba que o exiba. Está documentado aqui porque (a) faz parte do domínio de Configurações, (b) é uma capacidade pronta e útil, e (c) o redesign precisa decidir conscientemente entre resgatá-lo ou removê-lo.

⚠️ A confirmar: se ele é montado em alguma outra rota fora do escopo deste documento.

### B12.2 Objetivo

**"Dicionário de Dados"** — listar todos os campos disponíveis nas três entidades principais e seus valores possíveis. É a resposta natural à pergunta que o Perfil da Operação (B11) obriga o usuário a fazer: *"qual é mesmo o nome do campo?"*.

### B12.3 Anatomia

`div space-y-6`:

1. **Cabeçalho** — `h2 text-lg font-semibold` com `BookOpen h-5 w-5` + "Dicionario de Dados"; `p text-sm text-muted-foreground` → "Visualize todos os campos disponiveis no sistema e seus valores possiveis".

2. **Barra de busca + filtro** (`flex items-center gap-3`):
   - `Input` (`flex-1`) com `Search h-4 w-4` absoluto, placeholder "Buscar campo...", `className="pl-9"`. Filtra por `displayName` **ou** `fieldName`, case-insensitive, em memória.
   - `Select className="w-48"` com: **Todas as Entidades** (default), **Contatos**, **Contratos**, **Titulos**.

3. **Seções por entidade** — `div space-y-4` com um `EntitySection` por entidade visível.

### B12.4 Entidades (`ENTITY_CONFIG`)

| Chave | Rótulo | Ícone |
|---|---|---|
| `contacts` | Contatos | `Users` |
| `contracts` | Contratos | `FileText` |
| `titles` | Titulos | `Receipt` |

### B12.5 Seção de entidade (`EntitySection`)

`Collapsible` envolvendo um `Card`. **Todas começam abertas** (`useState(new Set(["contacts","contracts","titles"]))`).

**Cabeçalho clicável** — `CardHeader className="cursor-pointer hover:bg-muted/50 transition-colors py-3"`:
- Esquerda: ícone `h-4 w-4` + rótulo + `Badge variant="secondary" ml-2` com a **contagem de campos**.
- Direita: `ChevronDown h-4 w-4 transition-transform`, com `rotate-180` quando aberto.

**Conteúdo** — tabela ou, se vazio, `p text-sm text-muted-foreground py-4 text-center` → "Nenhum campo encontrado".

### B12.6 Tabela de campos

| Coluna | Largura | Conteúdo |
|---|---|---|
| **Campo** | auto | Duas linhas: `displayName` (`font-medium text-sm`) + indicadores; abaixo, `fieldName` em `text-xs text-muted-foreground font-mono` |
| **Tipo** | `w-[120px]` | `Badge variant="secondary" text-xs` com o rótulo traduzido |
| **Valores Possiveis** | auto | Até **4** `Badge variant="outline" text-xs font-normal`; acima disso, badge `+N` com **tooltip** listando o restante (`TooltipContent max-w-sm`). Sem valores: `span text-muted-foreground text-sm` → `"---"` |
| **Origem** | `w-[80px]` | `Badge` com variante por origem |

**Indicadores na coluna Campo:**
- `Tag h-3 w-3 text-primary` com tooltip **"Campo de lista (valores catalogados)"**, quando `field.isListField`.
- `Badge variant="outline" text-[10px] px-1 py-0` com o texto **"custom"**, quando `field.isCustom`.

**Tipos (`TYPE_LABELS`):**

| Valor | Rótulo |
|---|---|
| `text` | Texto |
| `number` | Numero |
| `date` | Data |
| `boolean` | Sim/Nao |
| `select` | Lista |

**Origens (`SOURCE_LABELS`) e variantes:**

| Valor | Rótulo | Variante do Badge |
|---|---|---|
| `custom_definition` | Custom | `default` |
| `standard` | Padrao | `secondary` |
| `etl_mapping` | ETL | `outline` |

### B12.7 Estados

| Estado | Render |
|---|---|
| Carregando | Cabeçalho normal + 4 `Skeleton` (`h-10 w-full` e três `h-48 w-full`) — **o único lugar do domínio que usa skeleton em vez de spinner na listagem** |
| Carregado | Seções colapsáveis |
| Busca sem resultado | Seção com contagem 0 e "Nenhum campo encontrado" |

### B12.8 Avaliação para o redesign

**A favor de resgatar:**
- Resolve uma necessidade real e recorrente (descobrir nomes de campo) que hoje não tem resposta na interface.
- É o complemento natural de **Perfil da Operação** (B11), **Variáveis Personalizadas** (B8, namespace `contact.custom.*`) e do construtor de Body Template (A4.3.7).
- Já usa skeleton, tooltip, colapsável e busca — está pronto.

**Ajustes necessários:**
- Tooltip como **único** canal de detalhe (o `+N`) não funciona em touch.
- `TooltipProvider` instanciado por célula.
- Rótulos sem acento ("Dicionario", "Titulos", "Numero", "Sim/Nao", "Padrao", "Valores Possiveis").
- Sem permissão nem gate.

---

## B13. Aba **Relatorios** (Relatórios Agendados)

**Arquivos:** `src/components/settings/tabs/ReportSchedulesTab.tsx` (container) + `src/components/settings/tabs/TowerReportRoutineCard.tsx` (card da rotina de IA)
**Hooks:** `useReportSchedulesList`, `useCreateReportSchedule`, `useUpdateReportSchedule`, `useDeleteReportSchedule`, `useReportDeliveryStatus`, `useReportManualTestStatus` (`src/hooks/useReportSchedules.ts`)

### B13.1 Objetivo e estrutura

A aba tem **dois blocos independentes**:

| # | Bloco | Componente | O que é |
|---|---|---|---|
| 1 | **Relatório de Performance dos Agentes de IA** | `TowerReportRoutineCard` | Rotina especial (IAF-4518), com N disparos semanais, recorte por disparo, teste manual e status de entrega |
| 2 | **Outros agendamentos** | corpo de `ReportSchedulesTab` | CRUD genérico de agendamentos de relatório semanal |

**Gate:** a aba inteira só existe se `hasPermission("settings:write")` (gate em `SettingsPage`). Dentro dela, `canEdit` é a mesma permissão — ou seja, **quem vê, edita**.

### B13.2 Separação entre os dois blocos

`selectTowerSchedules(schedules)` identifica o que pertence à rotina de IA:
- `report_type === "ai_performance"` → **sim**; ou
- `report_type === "weekly"` **e** o par dia/horário casa com um dos **slots legados**: `monday_0800` (dia 1, 08:00) ou `friday_1800` (dia 5, 18:00).

Tudo que sobra vai para "Outros agendamentos".

> Comentário do código: *"Os disparos da rotina de IA agora são N e têm slot **gerado** — filtrar por uma lista fixa de slots deixaria os disparos novos vazarem para 'outros relatórios', onde poderiam ser editados fora da rotina."*

---

### B13.3 Bloco 1 — Card "Relatório de Performance dos Agentes de IA"

#### Contexto

Persiste **N** schedules `report_type='ai_performance'` com os **mesmos destinatários**. O relatório enviado é o de "Todos os agentes" (`p_agent_id = null`, granularidade `day`) — o mesmo do download manual da tela de Performance de IA, anexado em HTML.

Schedules legados `weekly` que ocupam os slots antigos são **migrados** para `ai_performance` no próximo salvamento.

#### Cabeçalho do card

`div flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between` (empilha no mobile):

**Esquerda:**
- `CardTitle` com `CalendarClock h-5 w-5` + "Relatório de Performance dos Agentes de IA".
- `CardDescription mt-1.5 flex flex-col gap-1`:
  - Linha 1 (pluralizada): "Um envio semanal por e-mail" ou "`<n>` envios semanais por e-mail" + "no horário de Brasília, com o relatório completo anexado em HTML."
  - Linha 2 (`flex items-center gap-1 font-medium text-foreground`): `Bot h-3.5 w-3.5` + "Escopo: todos os agentes".

**Direita** (`flex items-center gap-2`):

| Elemento | Detalhe |
|---|---|
| **Badge de estado** | `variant="default"` "**Ativa**" · `variant="secondary"` "**Pausada**" ou "**Configuração pendente**" |
| **"Enviar teste agora"** | `Button size="sm" variant="outline"` com `Send h-4 w-4 mr-2` (ou `Loader2`). Só se `canEdit && isFullyConfigured`. `disabled` se enviando **ou** se não há schedule testável; nesse caso, `title` = "Salve a rotina uma vez para migrar o agendamento antes de testar." |
| **"Configurar" / "Ativar rotina"** | `Button size="sm"`; o rótulo depende de `isFullyConfigured`. Só se `canEdit` |

**Definições de estado:**
```
isFullyConfigured = configuredWindows.length > 0 && toda janela tem schedule persistido
isRoutineActive   = isFullyConfigured && toda janela tem schedule.is_active === true
```

#### Aviso de migração pendente

Quando algum schedule da rotina ainda é `weekly`:
`p text-sm text-muted-foreground` → "Um dos horários ainda usa o agendamento antigo. Salve a rotina uma vez para migrá-lo — o teste manual só fica disponível depois disso."

#### Grade de disparos

`div grid gap-3 md:grid-cols-2` — um cartão `rounded-lg border p-4` por disparo:

| Linha | Conteúdo |
|---|---|
| Título | `dispatchLabel(window)` (`font-medium`) — ex.: **"Toda segunda-feira, às 08h"** · à direita, `CheckCircle2 h-4 w-4` verde (`text-emerald-600`) se ativo, cinza se pausado, com `aria-label` "Ativo"/"Pausado" |
| Recorte | `periodLabelFor(periodMode)` (`text-sm text-muted-foreground`) |
| Último envio agendado | "Último envio agendado: `<data/hora BRT>`" ou **"Nunca enviado (agendado)"** (`text-xs`) |
| Último teste manual | "Último teste manual: `<data/hora>`" (+ " (falhou)" se falhou) ou **"Nenhum teste manual registrado"** (`text-xs`) |
| Badge de falha | `Badge variant="destructive"` com `AlertTriangle h-3 w-3` + "Falha no último envio" — quando `delivery.status === "failed"` |
| Badge de migração | `Badge variant="secondary"` com `AlertTriangle h-3 w-3` + "Pendente de migração" — quando `report_type !== "ai_performance"` |

> **Separação deliberada entre envio agendado e teste manual** (IAF-5187/A2): são duas linhas distintas no ledger. *"Sem isso, uma falha no teste ficava indistinguível de uma falha da rotina."*

**Prévia para org nunca configurada:** se não há nada persistido, o card exibe os **dois disparos padrão** como prévia (`schedule` undefined ⇒ badge "Configuração pendente"). *"Sem isso o cartão ficaria vazio e o usuário não saberia o que a rotina fará ao ser ativada."*

**Formatação de rótulo (`dispatchLabel`):** artigo de gênero correto — **"Toda"** para segunda a sexta (`-feira` é feminino), **"Todo"** para sábado e domingo. Horário: `08h` quando os minutos são `00`, senão `08h30`.

#### Bloco de destinatários

`p mb-2 text-sm font-medium` "Destinatários" + lista de `Badge variant="outline"` com `Mail h-3 w-3 mr-1` + e-mail, deduplicados de todos os schedules da rotina. Vazio → "Nenhum e-mail configurado."

#### Os dois recortes (`TOWER_PERIOD_MODES`)

| Valor | Rótulo | Dica (exibida no modal, abaixo do seletor) |
|---|---|---|
| `previous_week` | Semana anterior completa (segunda a domingo) | "Segunda a domingo da semana que fechou. Recorte estável em qualquer dia." |
| `current_week_to_date` | Semana atual até o dia do disparo | "Da segunda-feira até o dia do envio. Quanto mais cedo na semana, menos dados." |

> O recorte é **escolha por disparo**, não derivada do dia: *"com o dia livre, derivar o período do dia produziria surpresas silenciosas — um disparo de segunda com 'semana atual' cobriria só o próprio dia."*

**Disparos padrão de uma org nova:** segunda 08:00 (`previous_week`) e sexta 18:00 (`current_week_to_date`).

#### Modal **Configurar Relatório de Performance dos Agentes de IA**

| Item | Detalhe |
|---|---|
| Gatilho | "Configurar" / "Ativar rotina" |
| Container | `Dialog` → `DialogContent max-w-lg` |
| Título | "Configurar Relatório de Performance dos Agentes de IA" |
| Descrição | "Defina quantos disparos quiser, cada um com seu dia, horário e recorte, no horário de Brasília. Os destinatários abaixo valem para todos eles. O relatório cobre todos os agentes de IA da organização." |
| Rodapé | `Cancelar` (outline) + `Salvar rotina` (com `Loader2` durante) |

**Seção "Disparos semanais *"** — cabeçalho com o rótulo e `Button size="sm" variant="outline"` → `Plus h-3.5 w-3.5 mr-1.5` + "Adicionar disparo".

Cada disparo é um `div rounded-md border p-3` com `grid flex-1 gap-2 sm:grid-cols-3`:

| # | Campo | Controle | Opções |
|---|---|---|---|
| 1 | Dia da semana | `<select>` nativo `h-9 w-full rounded-md border border-input bg-background px-2 text-sm` | Domingo … Sábado (`WEEKDAY_LABELS`, índice 0–6) |
| 2 | Horário (BRT) | `Input type="time" h-9` | — |
| 3 | Recorte do relatório | `<select>` nativo | os 2 modos de `TOWER_PERIOD_MODES` |

Mais um `Button size="icon" variant="ghost" mt-5 h-8 w-8 shrink-0` com `X h-4 w-4` e `aria-label="Remover disparo de <dia>"`.

Abaixo de cada linha, `p mt-2 text-xs text-muted-foreground` com a **dica do recorte selecionado** — *"a consequência de escolher 'semana atual' numa segunda precisa estar visível ANTES de salvar, não depois do envio vazio."*

**Lista vazia:** `p rounded-md border border-dashed p-3 text-sm text-muted-foreground` → "Nenhum disparo configurado. Adicione ao menos um — para interromper os envios sem perder a configuração, use a chave 'Rotina ativa'."

> **Nota de design:** os dois `<select>` são **elementos nativos**, não o `Select` do shadcn usado em toda a aplicação. Inconsistência visual clara a resolver no redesign.

**Seção "E-mails destinatários *"** — `Input type="email" id="tower-report-email"` + `Button variant="outline" size="icon"` com `Plus` e `aria-label="Adicionar e-mail"`. `Enter` adiciona (com `preventDefault`). Cada e-mail vira `Badge variant="secondary" gap-1 pr-1` com `Mail h-3 w-3`, o endereço e um `<button>` `X h-3 w-3` (`aria-label="Remover <email>"`).

**Chave "Rotina ativa"** — `div flex items-center justify-between rounded-lg border p-3` com `Label` "Rotina ativa" + `p text-xs` "Pausa ou retoma os dois disparos sem apagar a configuração." e um `Switch id="tower-report-active"`.

> ⚠️ O texto diz **"os dois disparos"**, mas a rotina agora suporta **N** disparos. Copy desatualizada.

#### Validações do salvamento da rotina

| # | Regra | Mensagem |
|---|---|---|
| 1 | Ao menos 1 e-mail | "Adicione pelo menos um e-mail destinatário" (em `emailError`) |
| 2 | E-mail válido | `/^[^\s@]+@[^\s@]+\.[^\s@]+$/` → "Informe um e-mail válido" |
| 3 | E-mail não duplicado | "Este e-mail já foi adicionado" |
| 4 | Ao menos 1 disparo | "A rotina precisa de pelo menos um disparo. Para parar os envios, desative a rotina." |
| 5 | **Sem dois disparos no mesmo dia+hora** | "Há dois disparos em `<dia>` às `<HH:MM>`. Isso enviaria o mesmo relatório duas vezes — ajuste o dia ou o horário." |

Justificativa da regra 5, no código: *"Dois disparos no MESMO dia e hora gerariam dois e-mails idênticos: cada linha tem seu próprio `schedule_id`, então o claim de idempotência (UNIQUE `schedule_id` + `scheduled_for`) não os reconhece como duplicata. Horários diferentes no mesmo dia são legítimos e continuam permitidos."*

#### Mecânica do salvamento (diff)

`saveRoutine` faz **diff contra o persistido**:
- Disparos com `scheduleId` → `updateSchedule`
- Disparos sem `scheduleId` → `createSchedule`
- Disparos persistidos que sumiram do rascunho → **`deleteSchedule`** — *"Sem o delete, um disparo 'removido' na tela continuaria disparando pelo cron."*

`config` gravado em cada schedule:
```
{ ...configAnterior,
  schedule_slot: <slot>, period_mode: <modo>,
  agent_scope: "all", agent_id: null,
  granularity: "day", delivery: "email_attachment" }
```
mais `report_type: "ai_performance"` (que efetua a migração dos legados) e `name` gerado por `dispatchName()` — ex.: "Performance dos Agentes de IA — segunda-feira 08:00".

**Execução:** `Promise.allSettled` sobre todas as operações. Se qualquer uma falhar:
> toast destrutivo "Não foi possível salvar toda a rotina" / "Revise os agendamentos e tente novamente. Os horários já salvos foram mantidos."

Sucesso → fecha o modal e toast "Rotina de relatórios configurada" / "Os envios de segunda às 08h e sexta às 18h foram sincronizados."

> ⚠️ A descrição do toast de sucesso está **hard-coded nos horários antigos** e não reflete os disparos realmente salvos. Copy a corrigir.

**Slots:** identidade estável e **opaca** (`ai_perf_<12 hex>`, de `crypto.randomUUID()`). O nome **não codifica** dia/hora, porque eles mudam.

#### Modal **Enviar teste agora?**

| Item | Detalhe |
|---|---|
| Gatilho | Botão "Enviar teste agora" |
| Container | `AlertDialog` |
| Título | "Enviar teste agora?" |
| Descrição | "Um e-mail de teste com o Relatório de Performance dos Agentes de IA (todos os agentes) será enviado imediatamente para `<n>` destinatário(s), pelo mesmo pipeline do envio automático. **O teste não conta como envio da rotina.**" |
| Botões | `AlertDialogCancel` "Cancelar" + `AlertDialogAction` "Enviar teste" (**sem estilo destrutivo**), ambos `disabled` durante o envio |

**Mecânica:** invoca a EF `send-weekly-report` com `{ action: "test_send", schedule_id }`. Mesmo pipeline do envio automático (claim `manual_test` + geração + n8n), com `context="ai_performance_report_test"` e **sem tocar o `last_sent_at`** da rotina. O backend **re-valida owner/admin**.

**Tratamento de erro em três camadas:**

1. **Erro de invocação** — `supabase-js` reduz todo não-2xx a "non-2xx status code"; o corpo sanitizado `{ code, stage, message }` vive em `error.context`, extraído por `readEdgeFunctionError`.
2. **Kill-switch global** — responde **2xx** com `{ skipped: true }`. Isso **não é um envio**. *"Antes a UI dizia 'Teste enviado' sem nenhum e-mail ter saído."*
3. **`!data.success`** — usa `TEST_ERROR_HINTS[code]`, senão `data.message`, senão `data.error`.

**Dicas por código (`TEST_ERROR_HINTS`):**

| Código | Mensagem exibida |
|---|---|
| `report_sending_disabled` | "Envio de relatórios está desativado globalmente. Nenhum e-mail foi enviado." |
| `schedule_not_migrated` | "Este agendamento ainda é do tipo antigo. Salve a rotina uma vez para migrá-lo antes de testar." |
| `claim_refused` | "Já existe um envio deste relatório em andamento hoje. Aguarde e tente novamente." |
| `forbidden` | "Apenas owner/admin podem enviar o teste." |

**Toasts:** sucesso → "Teste enviado" / "Relatório de teste enviado para `<n>` destinatário(s)." (e refetch do status de teste manual). Falha → "Falha no envio do teste" + mensagem.

**Gate do teste (`findTestableSchedule`):** só um schedule **realmente migrado** para `ai_performance` é testável. Um legado `weekly` devolveria `409 schedule_not_migrated` no backend — *"a UI antecipa isso como 'pendente de migração' em vez de deixar o operador clicar e receber erro."*

---

### B13.4 Bloco 2 — Card "Outros agendamentos"

`CardTitle` com `CalendarClock h-5 w-5` + "Outros agendamentos"; `CardDescription mt-1.5` → "Agendamentos adicionais, além da rotina padrão de segunda e sexta-feira."; à direita, `Button size="sm"` "Novo Agendamento" com `Plus h-4 w-4 mr-2` (só se `canEdit`).

#### Tabela

| Coluna | Largura | Conteúdo |
|---|---|---|
| **Ativo** | `w-[60px]` | `Switch`, `disabled={!canEdit}` |
| **Nome** | auto | Nome (`font-medium`) + `Badge variant="secondary" w-fit text-xs` "**Compara semana anterior**" quando `config.compare_previous` |
| **Dia** | auto | `DAYS_OF_WEEK[day_of_week]` ou "Desconhecido" |
| **Horario** | auto | `HH:MM` (`font-mono text-sm`) |
| **Destinatarios** | `max-w-[250px]` | Até **3** `Badge variant="outline" text-xs` com `Mail h-3 w-3 mr-1` + e-mail; acima disso, `Badge variant="secondary"` `+N` |
| **Ultimo Envio** | auto | Data/hora `pt-BR` (`dd/MM/yyyy HH:mm`) ou **"Nunca enviado"** |
| **Acoes** | direita | `Pencil` (editar) + `Trash2` (remover), `disabled={!canEdit}` |

Linha inativa: `opacity-50`.

**Dias da semana (`DAYS_OF_WEEK`):** 0 Domingo · 1 Segunda-feira · 2 Terca-feira · 3 Quarta-feira · 4 Quinta-feira · 5 Sexta-feira · 6 Sabado. *(sem acento neste mapa; `WEEKDAY_LABELS` do card de IA **tem** acento — dois mapas, duas grafias)*

#### Estados

| Estado | Render |
|---|---|
| Carregando | `Loader2 h-8 w-8 animate-spin`, `py-12` |
| Vazio | `div text-center py-12 border rounded-lg bg-muted/50` com `CalendarClock h-12 w-12`, "Nenhum agendamento adicional", "A rotina padrão acima já cobre os envios de segunda e sexta." e `Button` "Criar Primeiro Agendamento" (se `canEdit`) |
| Preenchido | Tabela |

**Paginação:** a query pede `pageSize: 100`. Acima disso, os agendamentos **somem sem aviso** — não há controle de paginação na UI.

#### Modal **Novo / Editar Agendamento**

| Item | Detalhe |
|---|---|
| Container | `Dialog` → `DialogContent max-w-md` |
| Título | "Novo Agendamento" / "Editar Agendamento" |
| Descrição | "Configure um novo envio automatico de relatorio semanal" / "Edite as configuracoes do agendamento de relatorio" |
| Rodapé | `Cancelar` (outline) + `Criar`/`Salvar` (com `Loader2`) |

**Campos:**

| # | Campo | `id` | Controle | Obrigatório | Detalhes |
|---|---|---|---|---|---|
| 1 | Nome * | `schedule-name` | `Input` | sim | Placeholder "ex: Relatorio Semanal de Cobranca" |
| 2 | Dia da Semana * | — | `Select` (shadcn) | default `1` (Segunda) | 7 opções de `DAYS_OF_WEEK` |
| 3 | Horario * | `schedule-time` | `Input type="time"` | sim | Default `08:00` |
| 4 | Emails Destinatarios * | — | `Input` + botão `Plus` | ao menos 1 | `Enter` adiciona; normaliza `trim().toLowerCase()` |
| 5 | Ativo | — | `Switch` em `div flex items-center justify-between rounded-lg border p-3` | default `true` | Ajuda: "Habilita o envio automatico no dia e horario configurado" |
| 6 | Comparar com semana anterior | — | `Switch` em bloco idêntico | default `false` | Ajuda: "Inclui comparativo de metricas com a semana anterior" |

**Validações:**

| Campo | Regra | Mensagem |
|---|---|---|
| Nome | não vazio | "Nome e obrigatorio" |
| E-mails | ao menos 1 | "Adicione pelo menos um email destinatario" |
| E-mail individual | `/^[^\s@]+@[^\s@]+\.[^\s@]+$/` | "Email invalido" |
| E-mail individual | não duplicado | "Email ja adicionado" |
| Horário | preenchido | "Horario e obrigatorio" |

**Payload:** `{ name, day_of_week, time_of_day, recipient_emails, is_active, config: { compare_previous } }`. **Não envia `report_type`** — ou seja, esses agendamentos nascem no tipo default.

⚠️ A confirmar: qual é o `report_type` default do banco para um agendamento criado por este modal, e se ele pode acidentalmente cair nos slots legados da rotina de IA (segunda 08:00 / sexta 18:00) e ser "capturado" por `selectTowerSchedules` — o que o faria **sumir** de "Outros agendamentos" e aparecer como disparo da rotina de IA.

**Toasts:** "Agendamento criado" · "Agendamento atualizado" · "Agendamento removido" · "Erro ao salvar" / "Tente novamente" · "Erro ao remover" · "Erro ao alterar status".

#### Modal **Remover Agendamento**

| Item | Detalhe |
|---|---|
| Container | `AlertDialog` |
| Título | "Remover Agendamento" |
| Descrição | "Tem certeza que deseja remover o agendamento \"`<nome>`\"? O envio automatico sera interrompido." |
| Botões | "Cancelar" + "Remover" (`bg-destructive ...`, com `Loader2`) |

### B13.5 Dores específicas da aba

| Dor | Detalhe |
|---|---|
| **Dois modelos mentais na mesma aba** | Um card com rotina multi-disparo, teste manual e status de entrega; outro com CRUD linha a linha. Vocabulário diferente ("disparo" × "agendamento"), controles diferentes (`<select>` nativo × `Select` shadcn) |
| **Copy hard-coded** | "os dois disparos", "segunda às 08h e sexta às 18h" — textos que não acompanham a configuração real |
| **Dois mapas de dias da semana** | `DAYS_OF_WEEK` (sem acento) e `WEEKDAY_LABELS` (com acento) |
| **Sem paginação visível** | `pageSize: 100` silencioso |
| **Risco de captura de slot** | Criar um agendamento genérico em segunda 08:00 pode fazê-lo desaparecer para dentro da rotina de IA |
| **Teste sem preview** | Não há como ver o relatório antes de enviá-lo a N destinatários reais |
| **`Promise.allSettled` parcial** | Falha parcial deixa a rotina em estado misto; a mensagem diz "os horários já salvos foram mantidos", mas o usuário não sabe **quais** |
| **Status de entrega só na rotina de IA** | "Outros agendamentos" mostra apenas `last_sent_at`, sem status de falha |

---

## B14. Aba **Selos** (Catálogo de Selos)

**Arquivos:** `src/components/settings/tabs/SealCatalogTab.tsx` + `src/components/settings/tabs/SealAssignmentsList.tsx` + `src/components/seals/SealDialog.tsx` + `src/components/seals/SealBadge.tsx`
**Hooks:** `useSealCatalog`, `useSealUsageCounts`, `useSealAssignmentsWithDetails`, `useCreateSeal`, `useUpdateSeal`, `useDeleteSeal`, `useRemoveSeal` (`src/hooks/useSeals.ts`)
**Tipos:** `src/types/seals.ts`

### B14.1 Objetivo

Gerir os **selos** — rótulos coloridos usados para classificar manualmente contatos, contratos e títulos — e, para cada selo, ver e desfazer as **atribuições** existentes.

### B14.2 Permissões

`canManage = hasPermission("seals:manage_catalog")`. É também o gate da aba em `SettingsPage`.

**Guarda redundante interna:** se `!canManage`, o componente devolve
`div text-sm text-muted-foreground text-center py-12` → "Voce nao tem permissao para gerenciar o catalogo de selos."
(na prática inalcançável, pois o mesmo gate esconde a aba).

> **Nota importante:** **não há gate de leitura separado**. Quem entra na aba tem permissão total — o botão "Novo Selo" aparece **sem checagem adicional**.

### B14.3 Anatomia

`div space-y-6`:

1. **Cabeçalho** — `flex items-start justify-between gap-4`:
   - `h3 text-lg font-medium` "Catalogo de Selos" + `p text-sm text-muted-foreground` "Gerencie os selos usados para classificar contatos, contratos e titulos".
   - `Button className="shrink-0"` "Novo Selo" com `Plus h-4 w-4 mr-2`.

2. **`Tabs` de escopo** (`SCOPES`) — 3 triggers, sem ícone:

| `value` | Rótulo | Singular | Plural |
|---|---|---|---|
| `contact` (default) | Contato | contato | contatos |
| `contract` | Contrato | contrato | contratos |
| `title` | Titulo | titulo | titulos |

3. **`ScopePanel`** por escopo (`TabsContent mt-4`).

### B14.4 `ScopePanel` — chips + detalhe + lista

**Nível 1 — Chips horizontais** (`div flex flex-wrap gap-2`), um `<button>` por selo:

| Parte | Estilo |
|---|---|
| Base | `inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-sm font-medium transition-all` |
| Cor | Inline: `backgroundColor = cor + "15"` (não selecionado) ou `cor + "30"` (selecionado); `borderColor = cor`; `color = cor` |
| Selecionado | `ring-2 ring-primary ring-offset-1` |
| Não selecionado | `opacity-75 hover:opacity-100` |
| Conteúdo | Bolinha `h-2.5 w-2.5 rounded-full` na cor do selo + nome (`truncate max-w-48`) + **contagem de uso** (`text-xs opacity-80` → `"· <n>"`) |

Clicar alterna a seleção (clicar no selecionado **desmarca**) e limpa a busca.

**Nível 2 — Barra de detalhe do selo selecionado** (`Card` → `CardContent py-4 flex items-start justify-between gap-4`):

*Esquerda:*
- Barra vertical de cor: `div h-10 w-1 rounded-full shrink-0 mt-1` com `backgroundColor` do selo.
- `SealBadge seal size="md"` + `span text-sm text-muted-foreground` com a contagem **pluralizada** (`"<n> contato"` / `"<n> contatos"`).
- Se houver, `p text-sm text-muted-foreground mt-1.5` com a descrição.

*Direita* (`flex items-center gap-1 shrink-0`):
- `Button variant="ghost" size="sm"` → `Pencil h-4 w-4 mr-1.5` + "Editar"
- `Button variant="ghost" size="sm" text-destructive hover:text-destructive` → `Trash2 h-4 w-4 mr-1.5` + "Excluir"

**Sem seleção:** `Card` → `CardContent py-8 text-sm text-muted-foreground text-center` → "Selecione um selo acima para ver os `<plural>` aplicados".

**Nível 3 — Busca + lista de atribuições** (só com selo selecionado):
- `div relative max-w-sm` com `Search h-4 w-4` (`pointer-events-none`) e `Input className="pl-9"`, placeholder **"Buscar por nome ou documento..."**. Filtro **client-side, sem debounce**.
- `SealAssignmentsList` (B14.5).

**Estado vazio do escopo** (nenhum selo cadastrado) — `Card` → `CardContent flex flex-col items-center justify-center py-16`:
- `Award h-10 w-10 text-muted-foreground mb-3`
- `p font-medium text-muted-foreground` → "Nenhum selo cadastrado para `<plural>`"
- `p text-sm text-muted-foreground mt-1 text-center max-w-sm` → "Selos ajudam a classificar `<plural>` com rotulos coloridos personalizados."
- `Button variant="outline" className="mt-4"` → `Plus h-4 w-4 mr-2` + "Criar primeiro selo"

### B14.5 `SealAssignmentsList` — quem usa o selo

**Cabeçalhos de coluna por escopo (`COLUMN_HEADERS`):**

| Escopo | Coluna 1 | Coluna 2 | Coluna "Dono"? |
|---|---|---|---|
| `contact` | Nome | Documento | **não** |
| `contract` | Numero | Modalidade | sim |
| `title` | Numero | Vencimento / Valor | sim |

Mais uma coluna final "Acao" (`text-right w-16`).

**Coluna "Dono"** (só para contrato e título): duas linhas — `owner_name` e, abaixo, `owner_document` em `text-xs text-muted-foreground/75`. Sem dono: `span text-muted-foreground/50` → `"-"`.

**Ação da linha:** `Button size="icon" variant="ghost" h-8 w-8 text-destructive` com `X h-4 w-4` e `title="Remover selo deste <singular>"`.

**Contêiner:** `Card` → `CardContent p-0` → `div max-h-150 overflow-y-auto` com `TableHeader className="sticky top-0 bg-background z-10"` — **cabeçalho fixo com rolagem interna**.

**Filtro de busca:** concatena `display_name`, `subtitle`, `owner_name` e `owner_document` num único "haystack" e testa `includes(termo.toLowerCase())`.

**Estados:**

| Estado | Render (sempre dentro de um `Card`) |
|---|---|
| Carregando | `CardContent py-8 text-sm text-muted-foreground text-center` → "Carregando..." *(texto, não spinner)* |
| Nenhuma atribuição | `py-12` → "Nenhum `<singular>` usa este selo ainda." |
| Busca sem resultado | `py-12` → "Nenhum resultado para \"`<termo>`\"." |
| Com dados | Tabela |

### B14.6 Modal **Novo / Editar Selo** (`SealDialog`)

| Item | Detalhe |
|---|---|
| Objetivo | Criar ou editar um selo do escopo ativo |
| Gatilho | "Novo Selo" (cabeçalho), "Criar primeiro selo" (estado vazio) ou "Editar" (barra de detalhe) |
| Container | `Dialog` → `DialogContent` (largura padrão) |
| Título | "Novo Selo" / "Editar Selo" — **sem `DialogDescription`** |
| Envolvente | `<form onSubmit>` |
| Rodapé | `Cancelar` (outline) + `Criar`/`Salvar` (rótulo "Salvando..." durante) |

**Campos:**

| # | Campo | `id` | Controle | Obrigatório | Limite | Placeholder |
|---|---|---|---|---|---|---|
| 1 | Nome | `seal-name` | `Input required` | sim | `maxLength={64}` | "Ex: Cliente VIP" |
| 2 | Cor | — | 10 bolinhas | — | — | — |
| 3 | Descrição (opcional) | `seal-description` | `Textarea rows={2}` | não | `maxLength={256}` | — |

**Paleta (`SEAL_DEFAULT_COLORS`)** — 10 cores **hexadecimais** (não classes Tailwind, ao contrário de B9):

| # | Hex | Nome no comentário |
|---|---|---|
| 1 (default) | `#6b7280` | gray |
| 2 | `#ef4444` | red |
| 3 | `#f97316` | orange |
| 4 | `#eab308` | yellow |
| 5 | `#22c55e` | green |
| 6 | `#14b8a6` | teal |
| 7 | `#3b82f6` | blue |
| 8 | `#8b5cf6` | violet |
| 9 | `#ec4899` | pink |
| 10 | `#a855f7` | purple |

Cada cor é um `<button type="button" className="h-8 w-8 rounded-full border-2 transition">` com `backgroundColor` inline. Selecionada: `border-foreground scale-110`. `aria-label` = **"Cor `<hex>`"** — ou seja, o leitor de tela anuncia "Cor #ef4444", não "Cor vermelha".

**Guarda de submit:** `if (!name.trim()) return;` — sem mensagem de erro visível.

**Escopo:** definido pela **aba ativa** no momento da abertura (`scope={scope}`), **não escolhido no modal**.

> **Armadilha:** o `scope` passado ao `SealDialog` é o da aba ativa. Se o usuário abre o modal de edição de um selo e, por qualquer razão, o escopo mudar, o selo poderia ser gravado no escopo errado. Na prática o `SealDialog` de edição usa `seal.id` e não envia scope no update — mas o **create** usa o escopo ativo, o que faz o botão "Novo Selo" do cabeçalho ser **contextual e silencioso** (cria no escopo da aba visível, sem dizer isso em lugar nenhum).

### B14.7 Modal **Excluir selo**

| Item | Detalhe |
|---|---|
| Gatilho | Botão "Excluir" na barra de detalhe |
| Container | `AlertDialog` |
| Título | "Excluir selo de `<singular do escopo>`?" |
| Descrição | "Esta acao remove o selo de todas as entidades onde esta aplicado. Nao pode ser desfeita." |
| Botões | "Cancelar" + "Excluir" (`bg-destructive ...`, rótulo "Excluindo..." durante), ambos `disabled` durante |

> **Não informa a contagem**, embora ela esteja disponível (o chip mostra `· <n>` e a barra de detalhe mostra "`<n>` contatos"). Incluir o número no diálogo é correção trivial — e o padrão já existe em B8/B11/B15.

### B14.8 Modal **Remover selo?** (de uma entidade)

| Item | Detalhe |
|---|---|
| Gatilho | Botão `X` numa linha da lista de atribuições |
| Container | `AlertDialog` |
| Título | "Remover selo?" |
| Descrição | "O selo sera removido deste `<singular>`. Esta acao nao pode ser desfeita." |
| Botões | "Cancelar" + "Remover" (`bg-destructive ...`, "Removendo..." durante) |

**Não nomeia a entidade** (contato/contrato/título) de onde o selo sai.

### B14.9 Estados e dores

| Estado | Render |
|---|---|
| Sem permissão | Texto centralizado (inalcançável) |
| Escopo sem selos | Card vazio com CTA |
| Selo não selecionado | Card com instrução |
| Selo selecionado | Barra de detalhe + busca + lista |
| Carregando atribuições | Texto "Carregando..." |

| Dor | Detalhe |
|---|---|
| **Padrão de interação de 3 níveis** | Chips → detalhe → lista. Funciona, mas é incomum na Torre (as demais abas usam tabela direta) |
| **Escopo do "Novo Selo" implícito** | O botão global cria no escopo da aba ativa sem dizer |
| **`aria-label` com hex** | "Cor #ef4444" em vez de "Vermelho" |
| **Sem toggle ativo/inativo** | Diferente de Tags, Variáveis e Valores Padrão, selo só existe ou é excluído |
| **Sem confirmação de descarte** | O `SealDialog` fecha por ESC/clique fora perdendo o que foi digitado (contraste com Tags, que tem guarda) |
| **"Carregando..." em texto** | Inconsistente com os spinners/skeletons do resto |
| **Diálogos sem quantificação** | Nem o de excluir selo nem o de remover atribuição nomeiam/contam o que será afetado |
| **Cores inline em hex** | Bom para dark mode (não depende de classe), mas sem controle de contraste — uma cor clara sobre fundo claro fica ilegível no chip, já que `color = seal.color` |

---

## B15. Aba **Tags** (Catálogo de Tags)

**Arquivo:** `src/components/settings/tabs/TagCatalogTab.tsx`
**Hooks:** `useTagCatalog`, `useCreateTag`, `useUpdateTag`, `useDeleteTag`, `useTagCatalogUsage` (`src/hooks/useTagCatalog.ts`), `useDebouncedValue`, `useDirtyFormGuard`
**Validação:** `zod` + `react-hook-form`

### B15.1 Objetivo

Gerir o catálogo de **tags conversacionais** da organização — etiquetas que classificam contatos e conversas, aplicadas pelo agente de IA ou manualmente.

### B15.2 Permissões

A aba é **sempre visível**. A escrita vem por **prop**: `<TagCatalogTab canWrite={hasPermission("settings:write")} />`.

Sem `canWrite`: não há "Nova tag" e as linhas não mostram os botões de editar/excluir. A tabela, a busca e a paginação continuam funcionando.

> **Este é o único componente do domínio que recebe a permissão por prop** em vez de consultar `useOrganization()` internamente. Padrão mais testável — e de fato existe `__tests__/TagCatalogTab.spec.tsx`.

### B15.3 Anatomia

`div space-y-6`:

1. **Cabeçalho** — `flex items-start justify-between gap-4`:
   - `h3 text-lg font-medium` "Catalogo de Tags" + **`Badge variant="outline" gap-1 font-normal`** com `Building2 h-3 w-3` + **"Escopo: Organização"**.
   - `p text-sm text-muted-foreground` → "Gerencie as tags usadas para classificar contatos e conversas".
   - À direita: `Button className="shrink-0"` "Nova tag" com `Plus h-4 w-4 mr-2` (só se `canWrite`).

   > O badge de escopo existe (TAG.5) porque este catálogo é da **organização inteira**, distinto da *whitelist por agente* (`AgentAllowedTagsConfig`), que só **restringe** quais destas tags cada agente pode usar. Distinção que a interface torna explícita — bom padrão.

2. **Busca** — `div relative max-w-sm` com `Search h-4 w-4` (`pointer-events-none`) e `Input className="pl-9"`, placeholder "Buscar por nome ou label...", `aria-label="Buscar tags do catálogo"`.
   - **Debounce real de 300 ms** (`useDebouncedValue`) — o comentário registra que *"antes o 'debounce' só checava `length >= 2`, sem nenhum atraso real"*.
   - Só busca a partir de **2 caracteres**; abaixo disso, `searchTerm = undefined` (lista completa).
   - Trocar o termo **reseta a paginação** para a página 1.

3. **Conteúdo** — erro, carregando, vazio ou tabela.

### B15.4 Tabela

Dentro de `Card` com `CardTitle text-base` = `Tag h-4 w-4` + "Tags" e `CardDescription` = "`<n>` tag encontrada" / "`<n>` tags encontradas" (pluralização correta). `CardContent p-0`.

| Coluna | Alinhamento | Conteúdo |
|---|---|---|
| **Badge** | esquerda | `Badge variant="outline"` com a classe de cor + `font-medium`, exibindo o **label** |
| **Identificador** | esquerda | `tag.name` em `font-mono text-sm text-muted-foreground` |
| **Descricao** | esquerda | `tag.description` ou `<span className="text-muted-foreground/50">—</span>` |
| **Tipo** | esquerda | `Badge variant="outline" gap-1 text-xs font-normal` com ícone `Target h-3 w-3` (intenção) ou `MessageSquare h-3 w-3` (conversa) + rótulo |
| **Sistema** | esquerda | `Badge variant="secondary" gap-1 text-xs` com `Lock h-3 w-3` + "Sistema" — **só quando `is_system`**; senão célula vazia |
| **Acoes** | direita | `Pencil` e `Trash2`, `h-8 w-8 variant="ghost"`, com `title` e `aria-label` descritivos ("Editar tag `<label>`" / "Excluir tag `<label>`"). **Só quando `canWrite && !tag.is_system`** |

> **Tag de sistema é imutável pela UI** — não pode ser editada nem excluída (a célula de ações fica vazia).

### B15.5 Paleta e tipos

**Cores (`AVAILABLE_COLORS` / `COLOR_MAP` / `COLOR_LABELS`)** — 7 cores, gravadas como **nome** (`"green"`, `"red"`…), não como classe nem hex:

| Valor | Rótulo | Classes |
|---|---|---|
| `gray` (default) | Cinza | `bg-gray-100 text-gray-700 border-gray-200` |
| `green` | Verde | `bg-green-100 text-green-800 border-green-200` |
| `blue` | Azul | `bg-blue-100 text-blue-800 border-blue-200` |
| `yellow` | Amarelo | `bg-yellow-100 text-yellow-800 border-yellow-200` |
| `red` | Vermelho | `bg-red-100 text-red-800 border-red-200` |
| `orange` | Laranja | `bg-orange-100 text-orange-800 border-orange-200` |
| `purple` | Roxo | `bg-purple-100 text-purple-800 border-purple-200` |

> **Melhor das três abordagens de cor do sistema:** nome semântico no banco + mapa de classes no frontend. Permite trocar o design system sem migrar dado (ao contrário de B9, que grava a classe, e de B14, que grava o hex).

**`ColorPicker`** — `div role="group" aria-label="Cor"` com um `<button>` por cor: `h-7 px-2 rounded-full border text-xs font-medium` com a própria classe de cor e o **nome escrito dentro**. Selecionado: `ring-2 ring-offset-1 ring-foreground/30 scale-105`; demais: `opacity-70 hover:opacity-100`. Cada botão tem `title`, `aria-label` **e `aria-pressed`**.

> **O seletor de cor mais acessível do sistema** — exibe o nome, tem `role="group"` e `aria-pressed`. Contraste direto com B9 (bolinhas só com `title`) e B14 (`aria-label` com hex).

**Tipos (`TAG_TYPE_OPTIONS`)** — 2 valores:

| Valor | Rótulo | Descrição | Ícone na tabela |
|---|---|---|---|
| `conversation` (default) | Conversa | "Classifica a conversa (padrão)" | `MessageSquare` |
| `intent` | Intenção | "Marca uma intenção detectada" | `Target` |

**`TypeSelector`** — `RadioGroup className="grid grid-cols-2 gap-2"`; cada opção é um `<Label>` clicável `flex cursor-pointer items-start gap-2 rounded-md border p-3 transition-colors`, com `border-primary bg-primary/5` quando selecionado e `border-border hover:bg-muted/50` quando não. Dentro: `RadioGroupItem` + rótulo (`text-sm font-medium leading-none`) + descrição (`text-xs text-muted-foreground`).

### B15.6 Geração de identificador (`toSlug`)

```
label.toLowerCase()
     .normalize("NFD").replace(/[̀-ͯ]/g, "")   // remove acentos
     .replace(/[^a-z0-9\s_]/g, "")                        // só a-z, 0-9, espaço, _
     .trim()
     .replace(/\s+/g, "_")                                // espaços → underscore
```

Ex.: "Acordo Fechado" → `acordo_fechado`; "Não Atendeu!" → `nao_atendeu`.

No modal de criação, o slug é exibido **ao vivo**: `p text-xs text-muted-foreground` → "Identificador: `<slug em font-mono>`".

**O identificador é imutável após a criação** — no modal de edição ele aparece como texto somente-leitura em `font-mono text-sm text-muted-foreground bg-muted px-3 py-2 rounded-md`.

### B15.7 Modal **Nova Tag** (`CreateTagDialog`)

| Item | Detalhe |
|---|---|
| Container | `Dialog` → `DialogContent sm:max-w-md` |
| Título | "Nova Tag" |
| Descrição | "Defina o nome, a aparência e o tipo da nova tag de conversa." |
| Envolvente | `<form onSubmit>` |
| Rodapé | `Cancelar` (outline) + `Criar Tag` (rótulo "Criando..." durante) |

**Campos:**

| # | Campo | `id` | Controle | Obrigatório | Detalhes |
|---|---|---|---|---|---|
| 1 | Label * | `create-label` | `Input autoFocus` | sim (asterisco `text-destructive`) | Placeholder "Ex: Acordo Fechado"; slug exibido abaixo |
| 2 | Descricao | `create-description` | `Textarea rows={2}` | não | Placeholder "Descricao opcional da tag" |
| 3 | Cor | — | `ColorPicker` | — | Default `gray` |
| 4 | Tipo de tag | — | `TypeSelector` | — | Default `conversation` |

**Habilitação do submit:** `disabled = !label.trim() || !slug || createTag.isPending` — ou seja, um label composto só de caracteres que o slug descarta (ex.: `"!!!"`) **bloqueia** a criação, mas sem mensagem explicando.

**Guarda de alterações não salvas** — `isDirty` = qualquer campo diferente do default. Com `isDirty`, fechar o modal (ESC, clique fora ou "Cancelar") abre um `AlertDialog`:
- Título: "Descartar alterações?"
- Descrição: "Há alterações não salvas nesta nova tag. Se você fechar agora, elas serão perdidas."
- Botões: **"Continuar editando"** (cancel) + **"Descartar"** (action)

Além disso, `useDirtyFormGuard(open && isDirty)` — guarda de navegação (provavelmente `beforeunload`/bloqueio de rota).

⚠️ A confirmar: o mecanismo exato de `useDirtyFormGuard` (arquivo fora do escopo de leitura).

**Toasts:** "Tag criada com sucesso" · "Erro ao criar tag" + `err.message`.

**Limpeza:** no sucesso e no descarte, reseta os 4 campos aos defaults.

### B15.8 Modal **Editar Tag** (`EditTagDialog`)

| Item | Detalhe |
|---|---|
| Container | `Dialog open` → `DialogContent sm:max-w-md` (montado só quando há `tag`) |
| Título | "Editar Tag" |
| Descrição | "Atualize o label, a descrição, a cor ou o tipo desta tag." |
| Formulário | `react-hook-form` + `zodResolver` |
| Rodapé | `Cancelar` (outline) + `Salvar` (`disabled = !isDirty \|\| isPending`; "Salvando..." durante) |

**Campos:** idênticos ao de criação, **mais** um bloco no topo:

| Campo | Controle |
|---|---|
| Identificador | **texto somente-leitura** `font-mono text-sm text-muted-foreground bg-muted px-3 py-2 rounded-md` com `tag.name` |

**Schema Zod (`editTagSchema`):**

| Campo | Regra | Mensagem |
|---|---|---|
| `label` | `string().trim().min(1)` | "Label é obrigatório" |
| `description` | `string()` (livre) | — |
| `color` | `enum(AVAILABLE_COLORS)` | — |
| `type` | `enum(["conversation","intent"])` | — |

**Hidratação segura (`fix TAG-01`):** o `reset(mapTagToForm(tag))` só roda quando o **id** muda (`lastHydratedIdRef`). Um refetch do catálogo (novo objeto, mesmo id) **não sobrescreve um formulário sujo**. Mesmo princípio do B11.13 — e o oposto do que acontece em B2/B10.

Cor fora da paleta no dado existente cai em `gray`; `type` nulo cai em `conversation`.

**PATCH semântico (`buildTagPatch`, TAG.2):** envia **somente os campos alterados**. Chave ausente = não alterar; `description: null` = limpar. *"Nenhum default silencioso é enviado."*

Se o patch fica vazio, o modal simplesmente **fecha sem chamar a mutation**.

**Erro não fecha o modal:** *"valores e foco são preservados para retry."*

**Guarda de descarte:** igual ao de criação — `AlertDialog` "Descartar alterações?" com "Continuar editando" / "Descartar".

**Remount por entidade:** `<EditTagDialog key={editingTag?.id ?? "closed"} ...>` — salvaguarda extra além do `reset` explícito.

**Toasts:** "Tag atualizada com sucesso" · "Erro ao atualizar tag" + `err.message`.

### B15.9 Modal **Remover tag** — com contagem de impacto

| Item | Detalhe |
|---|---|
| Gatilho | Lixeira na linha |
| Container | `AlertDialog` |
| Título | "Remover tag" |
| Descrição | "Tem certeza que deseja remover a tag **`<label>`**? Esta acao nao pode ser desfeita." (o label em `font-semibold`) |
| Botões | "Cancelar" + "Remover" (`bg-destructive ...`, "Removendo..." durante) |

**Bloco de impacto (TAG.5)** — `useTagCatalogUsage(deletingTag)`, consultado **só quando o diálogo abre**:

| Estado | Render |
|---|---|
| Carregando | `Skeleton h-4 w-48` |
| Em uso (`conversationCount > 0` ou `agentCount > 0`) | `div flex items-start gap-2 rounded-md border border-amber-200 bg-amber-50 p-3 text-xs text-amber-900 dark:border-amber-900/40 dark:bg-amber-950/30 dark:text-amber-200` com `AlertTriangle h-3.5 w-3.5` e o texto: "Esta tag está em uso: **`<n>`** conversa(s) marcada(s) e **`<n>`** agente(s) restrito(s) a ela. Remover pode afetar classificações e permissões existentes." *(pluralização correta nos dois números)* |
| Sem uso | `p text-xs text-muted-foreground` → "Nenhuma conversa marcada nem agente restrito a esta tag no momento." |

> **Um dos poucos blocos da tela toda com suporte explícito a dark mode** (`dark:border-amber-900/40 dark:bg-amber-950/30 dark:text-amber-200`).

**Toasts:** "Tag removida com sucesso" · "Erro ao remover tag" + `err.message`.

### B15.10 Paginação

**Client-side**, `PAGE_SIZE = 10`, sobre o array **já filtrado**. Comentário: *"catálogo de uma org é uma lista curada, o corte é feito sobre o array já filtrado."*

Barra exibida **só se `totalPages > 1`** — `div flex items-center justify-between px-6 py-4`:
- `p text-sm text-muted-foreground` → "Página `<n>` de `<n>`"
- Dois `Button variant="outline" size="sm"`: **"Anterior"** (`disabled` na 1ª) e **"Próxima"** (`disabled` na última)

### B15.11 Estados

| Estado | Render |
|---|---|
| **Erro** | `Alert variant="destructive"` com `AlertTriangle h-4 w-4`, `AlertTitle` "Erro ao carregar o catálogo de tags", a mensagem crua (`text-xs break-words`) e `Button variant="outline" size="sm"` com `RefreshCw h-3.5 w-3.5 mr-1.5` + "Tentar novamente" |
| Carregando | `Card` com **6 `Skeleton h-10 w-full`** empilhados |
| Vazio (sem busca) | `Card` com `Tag h-10 w-10`, "Nenhuma tag cadastrada", explicação e CTA "Criar primeira tag" (se `canWrite`) |
| Vazio (com busca) | `Card` com "**Nenhuma tag encontrada**" — **sem** explicação e **sem** CTA |
| Preenchido | Tabela + paginação condicional |

> **Único lugar do domínio que distingue "vazio" de "vazio por filtro"** na mensagem. Padrão que Integrações (A3.6) e Datas Bloqueadas (B6.10) deveriam adotar.

### B15.12 Avaliação

Esta é, tecnicamente, **a aba mais bem construída** do domínio de Configurações. Reúne, num só lugar, os padrões que faltam nas demais:

| Padrão | Presente aqui |
|---|---|
| Debounce real na busca | ✓ 300 ms |
| Skeleton em vez de spinner | ✓ 6 linhas |
| Erro tratado + retry | ✓ `Alert` + botão |
| Vazio ≠ vazio por filtro | ✓ |
| Guarda de alterações não salvas | ✓ nos dois modais |
| Hidratação que não atropela o usuário | ✓ guard por id |
| PATCH semântico (só o que mudou) | ✓ |
| Erro não fecha o modal | ✓ |
| Contagem de impacto antes de excluir | ✓ conversas + agentes |
| Cor como token semântico | ✓ nome no banco |
| Seletor de cor acessível | ✓ `role`, `aria-pressed`, nome visível |
| Dark mode | ✓ (parcial: no bloco de impacto) |
| Permissão por prop (testável) | ✓ |
| Validação com schema | ✓ Zod + RHF |
| Paginação | ✓ |

**Recomendação para o redesign:** usar `TagCatalogTab` como **referência de implementação** para as demais abas — e `PipelineProfileTab` (B11) como referência de **microcopy**.

**Dores residuais:**

| Dor | Detalhe |
|---|---|
| Rótulos sem acento | "Catalogo de Tags", "Descricao", "Acoes" |
| Label só de caracteres inválidos | Bloqueia o submit sem explicar |
| Paginação client-side | Não escala se o catálogo crescer muito |
| Sem toggle ativo/inativo | Tag só existe ou é removida |
| Sem ordenação/agrupamento | Nem por tipo, nem por uso |

---

## PARTE C — COMUM

---

## C1. Modais dos dois domínios

Esta seção detalha **cada** superfície modal dos dois domínios, na ordem em que aparecem no documento. O inventário resumido em tabela está em **C6**.

Legenda de tipo:
- **Sheet** — painel lateral (`components/ui/sheet`)
- **Dialog** — modal centralizado (`components/ui/dialog`)
- **AlertDialog** — modal de confirmação (`components/ui/alert-dialog`), fecha só por botão explícito ou ESC
- **Nativo** — `window.confirm()` / `window.alert()` do browser

---

### C1.1 · Construtor de Integração — **Sheet**

| | |
|---|---|
| **Objetivo** | Criar ou editar uma integração HTTP/API completa |
| **Arquivo** | `src/components/integrations/IntegrationBuilderSheet.tsx` |
| **Gatilho** | "Nova Integração" (header), "Criar Primeira Integração" (estado vazio), "Editar" (card) |
| **Layout** | `SheetContent w-full sm:max-w-2xl flex flex-col p-0`; header fixo, `ScrollArea` no meio, footer fixo |
| **Abas internas** | Geral · Autenticação · Testar (`grid grid-cols-3`, `defaultValue="general"`) |
| **Campos** | Tipo*, Nome*, Descrição, URL de Visualização Externa, Método, URL*, Headers (lista), Body Template, Switch Ativa; aba Auth: Tipo + campos por tipo; aba Testar: painel completo |
| **Botões** | `Cancelar` (outline) · `Salvar` (`disabled = !isValid \|\| isSaving`) |
| **Confirmações** | **Nenhuma** — fecha por ESC/clique fora descartando tudo |
| **Estados** | criação · edição · inválido (Select com borda destrutiva) · salvando (`Loader2`) · erro (toast, Sheet permanece) |
| **Detalhe** | Reinicializa o formulário a cada abertura (`useEffect [existingIntegration, open]`) |

---

### C1.2 · Importar cURL — **Dialog**

| | |
|---|---|
| **Objetivo** | Preencher a configuração a partir de um comando cURL |
| **Arquivo** | `src/components/integrations/ImportCurlModal.tsx` |
| **Gatilho** | Botão "Importar cURL" na aba Geral |
| **Layout** | `DialogContent max-w-2xl`; título com `FileCode h-5 w-5` |
| **Campos** | `Textarea min-h-[150px] font-mono text-sm` com placeholder de exemplo multilinha |
| **Botões** | **Dois estágios**: `Cancelar` + `Analisar` → após parse: `Cancelar` + `Importar Configuração` |
| **Confirmações** | O preview verde **é** a confirmação (método, URL, nº de headers, presença de body, tipo de auth) |
| **Estados** | vazio · erro (`Alert` destrutivo) · preview (`Alert` verde) |
| **Limpeza** | Fechar limpa textarea, erro e preview |

---

### C1.3 · Remover integração — **Nativo**

| | |
|---|---|
| **Objetivo** | Confirmar a exclusão de uma integração |
| **Arquivo** | `src/pages/IntegrationsPage.tsx` (`IntegrationCard.handleDelete`) |
| **Gatilho** | Ícone de lixeira no card |
| **Layout** | `window.confirm("Tem certeza que deseja remover esta integração?")` |
| **Botões** | OK / Cancelar do sistema operacional |
| **Problema** | Única confirmação destrutiva da tela sem `AlertDialog`; não nomeia a integração; em erro dispara **dois** toasts |

---

### C1.4 · Criar nova API Key — **Dialog em 2 estágios**

| | |
|---|---|
| **Objetivo** | Emitir uma chave de API universal e exibir o segredo **uma única vez** |
| **Arquivo** | `src/components/integrations/ApiKeysSection.tsx` |
| **Gatilho** | Botão "Nova API Key" (`DialogTrigger`) |
| **Descrição** | "A chave será exibida apenas uma vez. Guarde-a em local seguro." |
| **Estágio 1** | `Input id="keyName"` ("Nome da chave"), placeholder "Ex: Integração ERP, Sistema Legado...", `Enter` submete. Botões: `Cancelar` + `Criar` (`disabled = !nome.trim() \|\| isPending`) |
| **Estágio 2** | `Input readOnly font-mono text-sm` com a chave + `Button size="icon" variant="outline"` de cópia (`Copy` → `Check` verde por 2 s). Botão único: `Fechar` |
| **Risco** | ESC ou clique fora no estágio 2 **perde o segredo para sempre** |
| **Toast** | "API Key criada" / "Copie a chave agora, ela não será exibida novamente." |

---

### C1.5 · Remover API Key — **AlertDialog**

| | |
|---|---|
| **Objetivo** | Revogar (soft-delete) uma chave |
| **Gatilho** | Lixeira na linha da tabela |
| **Título** | "Remover API Key?" |
| **Descrição** | "Esta ação não pode ser desfeita. Sistemas que usam esta chave perderão acesso imediatamente." |
| **Botões** | `Cancelar` + `Remover` (`bg-destructive text-destructive-foreground hover:bg-destructive/90`, `Loader2` durante) |
| **Comportamento real** | `UPDATE api_keys SET is_active = false` — **não** é delete físico |
| **Falta** | Não nomeia a chave que será revogada |

---

### C1.6 · Alertas nativos do upload de logo — **Nativo (3)**

| | |
|---|---|
| **Arquivo** | `src/components/settings/tabs/OrganizationTab.tsx` |
| **Gatilho 1** | Tipo de arquivo não permitido → `alert('Tipo de arquivo nao permitido. Use: JPG, PNG, GIF, WebP ou SVG.')` |
| **Gatilho 2** | Arquivo > 5 MB → `alert('Arquivo muito grande. Tamanho maximo: 5MB.')` |
| **Gatilho 3** | Falha no upload → `alert('Erro ao fazer upload da imagem. Tente novamente.')` |
| **Problema** | Destoam do sistema de `toast` usado em toda a Torre; bloqueiam a thread; não são estilizáveis |

---

### C1.7 · Convidar Usuario — **Dialog**

| | |
|---|---|
| **Objetivo** | Enviar convite por e-mail para entrar na organização |
| **Arquivo** | `src/components/settings/tabs/UsersTab.tsx` (`InviteUserDialog`) |
| **Gatilho** | Botão "Convidar Usuario" (só com `users:invite`) |
| **Layout** | `DialogContent max-w-md`; corpo dentro de `<form onSubmit>` |
| **Campos** | E-mail (`Input type="email" required`) · Role (`Select` com rótulo + descrição por item) |
| **Botões** | `Cancelar` (type=button) + `Enviar Convite` (type=submit, `Loader2` durante) |
| **Validações** | e-mail já membro · convite pendente duplicado · normalização `trim().toLowerCase()` |
| **Efeito** | Insere `user_invitations` (token UUID, expira em **7 dias**) + invoca `send-invitation-email`; **falha de e-mail não derruba o convite** |
| **Toast** | "Convite enviado!" / "Um email de convite foi enviado para `<email>`" |

---

### C1.8 · Editar Usuario — **Dialog**

| | |
|---|---|
| **Objetivo** | Alterar o papel de um membro |
| **Gatilho** | Lápis na linha |
| **Layout** | `DialogContent max-w-md`; abre por `open={!!user}` |
| **Blocos** | Identificação (avatar genérico `Users` + nome + e-mail, em `bg-muted/50 rounded-lg`) · lista de **cartões de papel** clicáveis · aviso âmbar de promoção a Proprietário |
| **Botões** | `Cancelar` + `Salvar Alteracoes` (`disabled` se o papel não mudou) |
| **Mecânica** | RPC `set_user_role_in_org` — valida caller, **bloqueia auto-promoção**, audita |
| **Erros traduzidos** | "Voce nao pode alterar a propria role..." · "Permissao negada: apenas admin/owner podem alterar roles." |

---

### C1.9 · Remover usuário / Cancelar convite — **Nativo (2)**

| | |
|---|---|
| **Gatilho 1** | Lixeira na linha de usuário → `confirm("Tem certeza que deseja remover este usuario?")` |
| **Gatilho 2** | Lixeira na linha de convite → `confirm("Tem certeza que deseja cancelar este convite?")` |
| **Mecânica** | `DELETE` com `.select("id")` + `ensureDeleted()` (detecta delete bloqueado por RLS) |
| **Erro** | Toast destrutivo "Erro ao remover" / "Erro ao cancelar convite" com `getDeleteErrorMessage` |
| **Falta** | Nenhum dos dois nomeia a pessoa/e-mail |

---

### C1.10 · Matriz de Permissoes — **Dialog (somente leitura)**

| | |
|---|---|
| **Objetivo** | Consultar o que cada papel pode fazer em cada recurso |
| **Arquivo** | `src/components/settings/RolesPermissionsCard.tsx` |
| **Gatilho** | Botão "Ver Permissoes" (`Shield`) no header do card de usuários |
| **Layout** | `DialogContent max-w-4xl max-h-[85vh] overflow-hidden flex flex-col`; corpo com scroll horizontal e vertical |
| **Conteúdo** | Tabela 10 recursos × 5 papéis; célula = `Badge` "Total" / "`<n>`/4" / "Nenhum"; tooltip com os 4 verbos |
| **Botões** | **Nenhum** — fecha só por ESC / clique fora / X |
| **Falhas** | Detalhe só em tooltip (inacessível em touch); sem rodapé; sem tratamento de erro |

---

### C1.11 · Restaurar configuracao padrao (faixas de atraso) — **AlertDialog**

| | |
|---|---|
| **Objetivo** | Descartar as faixas personalizadas e voltar às 7 padrão |
| **Arquivo** | `src/components/settings/tabs/AgingBucketsTab.tsx` |
| **Gatilho** | Botão "Restaurar Padrao" (`RotateCcw`), visível só se `isCustom` |
| **Título** | "Restaurar configuracao padrao?" |
| **Descrição** | "Isso ira remover sua configuracao personalizada e restaurar os 7 buckets padrao. Esta acao nao pode ser desfeita." |
| **Botões** | `Cancelar` + `Restaurar` — **sem estilo destrutivo** |
| **Mecânica** | Remove a chave `aging_buckets` de `organizations.settings`, preservando as demais |

---

### C1.12 · Adicionar Data Bloqueada — **Dialog**

| | |
|---|---|
| **Objetivo** | Cadastrar manualmente um dia em que campanhas não rodam |
| **Arquivo** | `src/components/settings/tabs/BlockedDatesTab.tsx` (`AddDateDialog`) |
| **Gatilho** | Botão "Adicionar Data" (é o próprio `DialogTrigger`) |
| **Layout** | `DialogContent` padrão; corpo em `<form onSubmit>` |
| **Campos** | Data (`Input type="date" required`) · Nome (`Input required`, "Ex: Aniversario da cidade") · Tipo (`Select`: Manual · Feriado Municipal · Feriado Estadual) |
| **Botões** | `Cancelar` + `Adicionar` (`Loader2` durante) |
| **Validação extra** | `if (!dateValue || !name.trim()) return;` |
| **Efeito** | Insere com `is_manual_override: true` (protege da sincronização automática) |
| **Falta** | Sem checagem de data duplicada; data fora do ano filtrado **some da lista** sem explicação |

---

### C1.13 · Remover data bloqueada — **Nativo**

| | |
|---|---|
| **Gatilho** | Lixeira na linha |
| **Texto** | `` confirm(`Deseja remover a data bloqueada "${name}"?`) `` |
| **Diferencial** | **É o único `window.confirm` do sistema que nomeia o item** |

---

### C1.14 · Nova / Editar Variavel — **Dialog de duas colunas**

| | |
|---|---|
| **Objetivo** | Criar/editar variável personalizada (texto fixo, composição ou lista) com prévia ao vivo |
| **Arquivo** | `src/components/settings/tabs/CustomVariablesTab.tsx` |
| **Gatilho** | "Nova Variavel", "Criar Primeira Variavel" ou lápis da linha |
| **Layout** | `DialogContent w-full max-w-6xl max-h-[90vh] flex flex-col overflow-hidden`; corpo `grid lg:grid-cols-[minmax(0,1.1fr)_minmax(0,1fr)]` |
| **Coluna esquerda** | Chave* · Nome de exibição* · `VariableDefinitionFields` (tipo + config de lista) · Conteúdo*/Texto de cada item* (+ `VariableInserter`) · Descrição |
| **Coluna direita** | `VariablePreviewPanel` (`lg:sticky lg:top-0`, `lg:max-h-[65vh] lg:overflow-y-auto`) |
| **Botões** | `Cancelar` + `Criar`/`Salvar` (`Loader2` durante) |
| **Validações** | 9 regras (B8.9) + validação do motor compartilhado + grafo de dependências |
| **Confirmações** | **Nenhuma guarda de descarte** |

---

### C1.15 · Remover Variavel — **AlertDialog**

| | |
|---|---|
| **Título** | "Remover Variavel" |
| **Descrição** | "Tem certeza que deseja remover a variavel \"`<label>`\"? Mensagens que usam `{{var.<chave>}}` deixarao de ser resolvidas." |
| **Botões** | `Cancelar` + `Remover` (`bg-destructive ...`, `Loader2`) |
| **Qualidade** | Nomeia a variável **e mostra o token** que vai quebrar — melhor texto destrutivo do sistema |
| **Falta** | Não conta quantas mensagens usam a variável (a informação existe no grafo) |

---

### C1.16 · Novo / Editar Valor (padrão) — **Dialog**

| | |
|---|---|
| **Objetivo** | Criar/editar valor canônico de normalização com aliases e cor |
| **Arquivo** | `src/components/settings/StandardValuesSettings.tsx` |
| **Gatilho** | "Novo Valor" ou lápis da linha |
| **Layout** | `DialogContent max-w-md` |
| **Campos** | Valor Interno* (sanitiza ao digitar; `disabled` se `is_system`) · Rótulo de Exibição* · Aliases (input + `Enter` + chips removíveis) · Cor do Badge (12 bolinhas + preview) |
| **Botões** | `Cancelar` + `Criar`/`Salvar` |
| **Validações** | valor obrigatório · padrão de caracteres · duplicidade (**só na criação**) · rótulo obrigatório |

---

### C1.17 · Remover Valor — **AlertDialog**

| | |
|---|---|
| **Título** | "Remover Valor" |
| **Descrição** | "Tem certeza que deseja remover o valor \"`<label>`\"? Esta ação não pode ser desfeita." |
| **Botões** | `Cancelar` + `Remover` (`bg-destructive ...`) |
| **Falta** | Não diz quais mapeamentos de ETL dependem do valor |

---

### C1.18 · Remover o perfil de formalização — **AlertDialog com contagem**

| | |
|---|---|
| **Objetivo** | Despromover a organização de `formalizacao` para `cobranca` |
| **Arquivo** | `src/components/settings/tabs/PipelineProfileTab.tsx` |
| **Gatilho** | Botão "Remover perfil" (o `handleSave` desvia para cá quando `isRemoving`) |
| **Título** | `text-destructive` com `Ban h-5 w-5` + "Remover o perfil de formalização?" |
| **Corpo** | 3 blocos: (1) convenções apagadas, réguas voltam a disparar por dias de atraso; (2) passos por etapa ficam **silenciosos, sem erro na tela**; (3) contagem de passos afetados |
| **Contagem** | `useEtapaTriggerStepCount` — `Skeleton` enquanto carrega; bloco âmbar com "`<n>` passo(s)" se > 0; "Nenhum passo..." se 0; **fail-soft** em erro |
| **Botões** | `Cancelar` + `Remover perfil` (`bg-destructive ...`), ambos `disabled` durante |
| **Qualidade** | **Referência do sistema**: explica a consequência funcional, quantifica e avisa que a falha é silenciosa |

---

### C1.19 · Configurar Relatório de Performance dos Agentes de IA — **Dialog**

| | |
|---|---|
| **Objetivo** | Definir N disparos semanais (dia, hora, recorte) e os destinatários da rotina |
| **Arquivo** | `src/components/settings/tabs/TowerReportRoutineCard.tsx` |
| **Gatilho** | Botão "Configurar" / "Ativar rotina" |
| **Layout** | `DialogContent max-w-lg` |
| **Seção 1** | "Disparos semanais *" + "Adicionar disparo"; cada linha = `<select>` dia + `Input type="time"` + `<select>` recorte + `X` de remover + dica do recorte |
| **Seção 2** | "E-mails destinatários *" — input + `Plus`, `Enter` adiciona, chips removíveis |
| **Seção 3** | Chave "Rotina ativa" |
| **Botões** | `Cancelar` + `Salvar rotina` (`Loader2` durante) |
| **Validações** | ≥1 e-mail · e-mail válido · e-mail não duplicado · ≥1 disparo · **sem dois disparos no mesmo dia+hora** |
| **Mecânica** | Diff contra o persistido (update/create/**delete**), `Promise.allSettled` |
| **Inconsistência** | Usa `<select>` **nativos**, não o `Select` do design system |

---

### C1.20 · Enviar teste agora — **AlertDialog**

| | |
|---|---|
| **Objetivo** | Disparar um envio de teste do relatório de IA, pelo mesmo pipeline do automático |
| **Gatilho** | Botão "Enviar teste agora" (só com rotina totalmente configurada e schedule migrado) |
| **Título** | "Enviar teste agora?" |
| **Descrição** | "Um e-mail de teste ... será enviado imediatamente para `<n>` destinatário(s), pelo mesmo pipeline do envio automático. **O teste não conta como envio da rotina.**" |
| **Botões** | `Cancelar` + `Enviar teste` (**sem estilo destrutivo**), ambos `disabled` durante |
| **Tratamento** | 3 camadas de erro (invocação, kill-switch `{skipped:true}`, `!success`) + dicas por código |

---

### C1.21 · Novo / Editar Agendamento — **Dialog**

| | |
|---|---|
| **Objetivo** | CRUD de agendamento genérico de relatório semanal |
| **Arquivo** | `src/components/settings/tabs/ReportSchedulesTab.tsx` |
| **Gatilho** | "Novo Agendamento", "Criar Primeiro Agendamento" ou lápis da linha |
| **Layout** | `DialogContent max-w-md` |
| **Campos** | Nome* · Dia da Semana* (`Select`) · Horario* (`Input type="time"`) · Emails Destinatarios* (input + `Plus`, chips) · Switch "Ativo" · Switch "Comparar com semana anterior" |
| **Botões** | `Cancelar` + `Criar`/`Salvar` |
| **Validações** | nome · ≥1 e-mail · e-mail válido · e-mail não duplicado · horário |

---

### C1.22 · Remover Agendamento — **AlertDialog**

| | |
|---|---|
| **Título** | "Remover Agendamento" |
| **Descrição** | "Tem certeza que deseja remover o agendamento \"`<nome>`\"? O envio automatico sera interrompido." |
| **Botões** | `Cancelar` + `Remover` (`bg-destructive ...`) |

---

### C1.23 · Novo / Editar Selo — **Dialog**

| | |
|---|---|
| **Objetivo** | Criar/editar um selo do escopo ativo |
| **Arquivo** | `src/components/seals/SealDialog.tsx` |
| **Gatilho** | "Novo Selo", "Criar primeiro selo" ou "Editar" da barra de detalhe |
| **Layout** | `DialogContent` padrão; corpo em `<form onSubmit>`; **sem `DialogDescription`** |
| **Campos** | Nome (`required`, `maxLength={64}`) · Cor (10 bolinhas hex, `aria-label="Cor #xxxxxx"`) · Descrição (`Textarea rows={2} maxLength={256}`) |
| **Botões** | `Cancelar` + `Criar`/`Salvar` ("Salvando..." durante) |
| **Escopo** | Vem da **aba ativa**, não é escolhido no modal |
| **Falta** | Sem guarda de descarte; sem mensagem de erro quando o nome está vazio |

---

### C1.24 · Excluir selo — **AlertDialog**

| | |
|---|---|
| **Título** | "Excluir selo de `<contato\|contrato\|titulo>`?" |
| **Descrição** | "Esta acao remove o selo de todas as entidades onde esta aplicado. Nao pode ser desfeita." |
| **Botões** | `Cancelar` + `Excluir` (`bg-destructive ...`, "Excluindo..." durante) |
| **Falta** | Não nomeia o selo nem mostra a contagem (que já está visível no chip) |

---

### C1.25 · Remover selo de uma entidade — **AlertDialog**

| | |
|---|---|
| **Arquivo** | `src/components/settings/tabs/SealAssignmentsList.tsx` |
| **Gatilho** | `X` na linha da lista de atribuições |
| **Título** | "Remover selo?" |
| **Descrição** | "O selo sera removido deste `<singular>`. Esta acao nao pode ser desfeita." |
| **Botões** | `Cancelar` + `Remover` ("Removendo..." durante) |
| **Falta** | Não nomeia a entidade |

---

### C1.26 · Nova Tag — **Dialog**

| | |
|---|---|
| **Arquivo** | `src/components/settings/tabs/TagCatalogTab.tsx` (`CreateTagDialog`) |
| **Layout** | `DialogContent sm:max-w-md`; corpo em `<form onSubmit>` |
| **Campos** | Label* (`autoFocus`, slug exibido ao vivo) · Descricao (`Textarea rows={2}`) · Cor (`ColorPicker`, 7 cores nomeadas) · Tipo de tag (`TypeSelector`, 2 cartões) |
| **Botões** | `Cancelar` + `Criar Tag` (`disabled = !label.trim() \|\| !slug \|\| isPending`) |
| **Guarda** | `isDirty` → abre "Descartar alterações?" ao tentar fechar; `useDirtyFormGuard` bloqueia navegação |

---

### C1.27 · Descartar alterações (criação de tag) — **AlertDialog**

| | |
|---|---|
| **Título** | "Descartar alterações?" |
| **Descrição** | "Há alterações não salvas nesta nova tag. Se você fechar agora, elas serão perdidas." |
| **Botões** | **"Continuar editando"** (cancel) + **"Descartar"** (action) |
| **Qualidade** | Rótulos orientados à ação, não "Sim/Não" |

---

### C1.28 · Editar Tag — **Dialog**

| | |
|---|---|
| **Layout** | `DialogContent sm:max-w-md`; `react-hook-form` + `zodResolver` |
| **Campos** | Identificador (**somente leitura**, `font-mono bg-muted`) · Label* · Descricao · Cor · Tipo |
| **Botões** | `Cancelar` + `Salvar` (`disabled = !isDirty \|\| isPending`) |
| **Mecânica** | **PATCH semântico** — envia só o que mudou; patch vazio fecha sem chamar a mutation |
| **Erro** | **Não fecha o modal** — valores e foco preservados |
| **Hidratação** | `reset` guardado por `id` — refetch não atropela formulário sujo |

---

### C1.29 · Descartar alterações (edição de tag) — **AlertDialog**

Idêntico a C1.27, com o texto "Há alterações não salvas neste formulário. Se você fechar agora, elas serão perdidas."

---

### C1.30 · Remover tag — **AlertDialog com contagem de impacto**

| | |
|---|---|
| **Título** | "Remover tag" |
| **Descrição** | "Tem certeza que deseja remover a tag **`<label>`**? Esta acao nao pode ser desfeita." |
| **Bloco de impacto** | `Skeleton` enquanto carrega; bloco âmbar (**com dark mode**) "Esta tag está em uso: **`<n>`** conversa(s) marcada(s) e **`<n>`** agente(s) restrito(s) a ela..."; ou "Nenhuma conversa marcada nem agente restrito a esta tag no momento." |
| **Botões** | `Cancelar` + `Remover` (`bg-destructive ...`, "Removendo..." durante) |
| **Qualidade** | Ao lado de C1.18, o melhor diálogo destrutivo do sistema |

---

## C2. Estados das telas

### C2.1 Matriz de estados por superfície

Legenda: ✓ implementado · ✗ ausente · — não aplicável

| Superfície | Carregando | Vazio | Vazio ≠ filtro | Erro | Retry | Sem permissão | Salvando |
|---|---|---|---|---|---|---|---|
| Integrações (grade) | ✓ spinner | ✓ | ✗ | **✗** | ✗ | ✓ | — |
| Construtor | — | — | — | ✓ toast | ✗ | — | ✓ |
| Painel de teste | ✓ spinner | ✓ | — | ✓ inline | ✗ | — | ✓ |
| API Keys | ✓ spinner | ✓ | — | ✓ toast | ✗ | ✓ (aba oculta) | ✓ |
| Organização | ✓ spinner | — | — | **✗** (`alert`) | ✗ | ✓ | ✓ |
| Usuários | ✓ spinner | ✓ | — | **✓** | **✓** | ✓ | ✓ |
| Convites | ✓ spinner | ✓ | — | ✗ | ✗ | ✓ (card oculto) | ✓ |
| Matriz de permissões | ✓ spinner | — | — | ✗ | ✗ | — | — |
| Faixas de atraso | ✓ spinner | ✗ | — | ✓ toast | ✗ | ✓ | ✓ |
| Datas Bloqueadas | ✓ spinner | ✓ | ✗ | ✓ toast | ✗ | **✗ sem gate** | ✓ |
| Custos por Canal | ✓ spinner | ✓ + CTA | — | ✓ toast | ✗ | **✗ sem gate** | ✓ |
| Variáveis | ✓ spinner | ✓ | ✗ | **✓ inline** | ✗ | ✓ | ✓ |
| Prévia de variável | ✓ texto | ✓ | — | **✓ inline** | **✓** | — | — |
| Valores Padrão | ✓ spinner | ✓ + CTA | — | ✓ toast | ✗ | ✓ | ✓ |
| Réguas | ✓ spinner | — | — | ✗ | ✗ | ✓ | ✓ |
| Perfil da Operação | **✓ skeleton** | — | — | **✓ persistente** | ✗ | ✓ + aviso | ✓ |
| Relatórios (rotina IA) | ✓ prévia | ✓ prévia | — | ✓ toast + badge | ✗ | ✓ | ✓ |
| Relatórios (outros) | ✓ spinner | ✓ + CTA | — | ✓ toast | ✗ | ✓ | ✓ |
| Selos | ✓ **texto** | ✓ + CTA | **✓** | ✗ | ✗ | ✓ | ✓ |
| Tags | **✓ skeleton** | ✓ + CTA | **✓** | **✓ + retry** | **✓** | ✓ | ✓ |
| Explorador de Campos | **✓ skeleton** | ✓ | ✗ | ✗ | ✗ | — | — |

### C2.2 Padrões de indicador de carregamento (3 coexistentes)

| Padrão | Onde |
|---|---|
| **Spinner centralizado** (`Loader2 animate-spin`) | Integrações, API Keys, Organização, Faixas, Datas, Custos, Variáveis, Valores Padrão, Réguas, Relatórios, Usuários, Matriz |
| **Skeleton** | Tags (6 linhas), Perfil da Operação (3 blocos), Explorador de Campos (4 blocos) |
| **Texto "Carregando..."** | Selos (`SealAssignmentsList`) |

Tamanhos de spinner também variam: `h-8 w-8` (maioria), `h-6 w-6` (Datas, Custos, API Keys), `h-4 w-4` (inline em botões e listas).

### C2.3 Padrões de estado vazio (3 coexistentes)

| Padrão | Estrutura | Onde |
|---|---|---|
| **A — Bloco solto** | `flex flex-col items-center justify-center py-16 text-center` | Integrações |
| **B — Card** | `Card` > `CardContent flex flex-col items-center justify-center py-8..16` | Datas, Custos, Selos, Tags, Relatórios (não) |
| **C — Div com borda tracejada/fundo** | `div text-center py-12 border rounded-lg bg-muted/50` | Variáveis, Valores Padrão, Relatórios (outros) |

Ícone: `h-10 w-10` (Selos, Tags), `h-12 w-12` (Datas, Custos, Variáveis, Valores Padrão, Usuários, Relatórios), `h-16 w-16` (Integrações).

### C2.4 Padrões de feedback de sucesso (inconsistentes)

| Ação | Tem toast de sucesso? |
|---|---|
| Salvar integração | ✓ |
| Remover integração | ✓ |
| Ativar/desativar integração | **✗** (só em erro) |
| Criar API Key | ✓ |
| Copiar API Key | ✓ |
| Remover API Key | ✓ |
| Salvar organização | **✗** |
| Alterar papel de usuário | ✓ |
| Remover usuário | **✗** |
| Convidar / reenviar convite | ✓ |
| Cancelar convite | **✗** |
| Salvar faixas de atraso | ✓ |
| Adicionar/atualizar/remover data bloqueada | ✓ |
| Importar feriados | ✓ (com fonte declarada) |
| Atualizar custo | ✓ |
| Inicializar custos | ✓ (só se criou) |
| Criar/atualizar/remover variável | ✓ |
| Alternar variável ativa | **✗** |
| Criar/atualizar/remover valor padrão | ✓ |
| Exportar/importar valores padrão | ✓ |
| Salvar réguas | **✗** |
| Salvar/remover perfil | ✓ (título por `action`) |
| Salvar rotina de relatório | ✓ |
| Enviar teste | ✓ |
| Criar/atualizar/remover agendamento | ✓ |
| Criar/atualizar/remover selo | ⚠️ A confirmar (nos hooks `useSeals`) |
| Criar/atualizar/remover tag | ✓ |

---

## C3. Fluxos de uso passo a passo

### C3.1 Onboarding de uma organização nova (ordem recomendada)

Sequência derivada das dependências reais entre as abas:

1. **Configurações › Organizacao** — nome, domínio, logo e cores.
2. **Configurações › Valores Padrao** — em cada uma das 4 sub-abas, "Carregar Padrões" (o ETL depende dos aliases para normalizar).
3. **Configurações › Custos** — "Inicializar Custos Padrao".
4. **Configurações › Kanban** — revisar as 7 faixas de atraso (ou personalizar).
5. **Configurações › Datas Bloqueadas** — "Importar Feriados Nacionais" para o ano corrente e o seguinte.
6. **Configurações › Tags** e **› Selos** — criar o vocabulário de classificação.
7. **Configurações › Variaveis** — criar as variáveis personalizadas usadas nas mensagens.
8. **Integrações** — cadastrar as pontes (WhatsApp, e-mail…), testar e ativar.
9. **Configurações › Reguas** — ajustar faixas de dívida e meta de recuperação.
10. **Configurações › Relatorios** — configurar a rotina de relatório de IA.
11. **Configurações › Usuarios** — convidar o time.
12. *(se aplicável)* **Configurações › Perfil da Operacao** — aplicar `formalizacao` e mapear os campos.

> **Nada na interface expressa essa ordem.** Não há checklist de onboarding, nem indicação de qual aba já foi configurada. É a oportunidade de produto mais óbvia do redesign.

### C3.2 Conectar um novo canal de WhatsApp (ponta a ponta)

1. Obter do provedor o cURL de envio.
2. **Integrações** → "Nova Integração".
3. Tipo = **WhatsApp**.
4. "Importar cURL" → colar → **Analisar** → conferir o preview verde → **Importar Configuração**.
5. **Conferir se o header `x-org-slug` sobreviveu** (a importação substitui a lista inteira — ver A5.6). Se sumiu, adicionar `x-org-slug: {{org.slug}}`.
6. Preencher **Nome** (obrigatório).
7. Ajustar o **Body Template** — remover chaves que o provedor não aceita; usar `{{` para inserir variáveis; conferir em "Preview com dados de exemplo".
8. Aba **Autenticação** → escolher o tipo → digitar a credencial (se for **Basic Auth importado do cURL**, redigitar usuário e senha: a importação não os preenche — ver A5.6).
9. Desligar "Integração Ativa" enquanto valida.
10. **Salvar**.
11. Reabrir → aba **Testar** → buscar contato → escolher título → *(opcional)* escolher template Meta → **Enviar Teste**.
12. Ler o banner, expandir **Request Payload** e **Resposta do Provedor**.
13. Se ok: aba Geral → ligar "Integração Ativa" → **Salvar**.

> **Atenção:** o teste dispara mensagem **real** para o cliente **real**, cria a campanha "Teste Integracao" e deixa uma ação com `source = "teste"` (ver A6.1).

### C3.3 Emitir e entregar uma credencial de API a um parceiro

1. Estar logado como **Super Admin**.
2. **Integrações** → aba **API Keys**.
3. "Nova API Key" → nomear com o sistema consumidor → **Criar**.
4. **Copiar imediatamente** e guardar em cofre — **não fechar o modal com ESC**.
5. **Fechar**.
6. Entregar ao parceiro **dois** dados: `x-api-key: tc_...` e `x-org-slug: <slug>`.
7. Para revogar depois: lixeira na linha → **Remover** (soft-delete, `is_active = false`).

### C3.4 Configurar uma organização de formalização

1. **Configurações › Perfil da Operacao** (visível a super admin ou a org que já tem perfil).
2. Trocar o tipo para **Formalização**.
3. Aparece o alerta neutro **"Falta configurar o gatilho — nenhuma régua roda ainda"**.
4. Preencher **Campo da etapa** (ex.: `custom.etapa`) usando as sugestões do `datalist`, e/ou **Campo da data de referência**.
5. Preencher os campos de **telefone** e/ou **e-mail do destinatário** conforme os canais em uso — lendo as consequências de deixar cada um vazio.
6. Definir o **Teto diário** (ou aceitar o alerta âmbar "Sem teto, um passo por etapa pode enviar todos os dias").
7. **Salvar**. Ler o toast ("Perfil aplicado" / "Perfil salvo") e qualquer aviso persistente.
8. Ir montar as réguas com gatilho por etapa.

**Para despromover:** trocar para **Cobrança** → o botão vira **"Remover perfil"** (vermelho) → confirmar no `AlertDialog`, lendo a **contagem de passos** que ficarão silenciosos.

### C3.5 Criar uma variável de lista (parcelas em aberto)

1. **Configurações › Variaveis** → "Nova Variavel".
2. **Chave** (ex.: `parcelas_abertas`) — caracteres inválidos são removidos ao digitar.
3. **Nome de exibição** (ex.: "Parcelas em aberto").
4. **Tipo de conteúdo** = **Lista configurável**.
5. **Itens da lista** = "Parcelas do cliente".
6. Ajustar **status**, **cobráveis**, **ordenação**, **limite**, **separador** e **texto de lista vazia**.
7. Em **"Texto de cada item"**, escrever o modelo (ex.: `Parcela {{title.installment_number}} — vence {{title.due_date}} — R$ {{title.current_value}}`).
8. Na coluna direita, escolher **"Cliente da base"**, buscar um cliente real e conferir o **Texto gerado** e o bloco **"Itens selecionados"** (quantos casaram, quantos apareceram, quantos foram cortados).
9. **Criar**.
10. Na listagem, usar o botão de cópia para obter `{{var.parcelas_abertas}}` e colar no template da mensagem.

### C3.6 Diagnosticar "a régua não disparou nada"

Roteiro que cruza as abas — hoje **não documentado na interface**:

| # | Onde olhar | O que verificar |
|---|---|---|
| 1 | **Configurações › Datas Bloqueadas** | O dia está bloqueado e ativo? |
| 2 | **Integrações** | A integração do canal está **Ativa**? |
| 3 | **Configurações › Perfil da Operacao** | Sob formalização: há gatilho configurado? O teto diário é `0`? |
| 4 | **Configurações › Perfil da Operacao** | O campo da etapa aponta para um campo que **existe** nos contatos? |
| 5 | **Integrações › Testar** | A ponte responde? |

### C3.7 Revogar o acesso de alguém que saiu da empresa

1. **Configurações › Usuarios** → localizar a pessoa.
2. Lixeira → `window.confirm` → confirmar.
3. Se havia convite pendente para o mesmo e-mail: card "Convites Pendentes" → lixeira → confirmar.
4. Se a pessoa detinha uma **API Key** nomeada: aba **API Keys** em Integrações → revogar.
5. Conferir em **Ver Permissoes** o que o papel dela alcançava.

---

## C4. Responsividade e acessibilidade

### C4.1 Breakpoints efetivamente usados

| Superfície | Comportamento responsivo |
|---|---|
| Grade de integrações | `grid gap-4 md:grid-cols-2 lg:grid-cols-3` — 1 / 2 / 3 colunas |
| Construtor (Sheet) | `w-full sm:max-w-2xl` — **tela cheia no mobile** |
| Abas do Construtor | `grid grid-cols-3` — fixo, não quebra |
| Filtro de tipo | `flex flex-wrap h-auto gap-1` — quebra em várias linhas |
| `TabsList` de Configurações | `flex-wrap h-auto` — quebra em várias linhas |
| Card de rotina de relatório | `flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between` |
| Grade de disparos | `grid gap-3 md:grid-cols-2` |
| Modal de variável | `grid lg:grid-cols-[minmax(0,1.1fr)_minmax(0,1fr)]` — 2 colunas só em `lg` |
| Sub-abas de Valores Padrão | `grid grid-cols-4`; rótulo textual `hidden sm:inline` — **só ícone no mobile** |
| Réguas (indicadores) | `grid gap-6 md:grid-cols-3` |
| Perfil (disparo do relatório) | `grid flex-1 gap-2 sm:grid-cols-3` |

### C4.2 Pontos que **não** respondem

| Problema | Onde |
|---|---|
| **Tabelas sem tratamento mobile** | Todas as tabelas (`Table` do shadcn) — nenhuma tem scroll horizontal explícito nem versão em cartão. API Keys (4 col.), Usuários (4), Convites (4), Datas (5), Custos (4), Variáveis (5), Valores Padrão (5), Relatórios (7!), Tags (6), Selos (3–4) |
| **Linha de faixa de atraso** | `flex` com larguras fixas (`w-10`, `w-24`, `w-24`, `w-20`, `w-9`) + um `flex-1`. Em telas estreitas o campo Nome desaparece |
| **Cores da organização** | `grid grid-cols-2` **fixo** — dois color pickers lado a lado até em 320 px |
| **Prévia do cálculo (Réguas)** | `grid grid-cols-3` fixo |
| **Popover de teste** | `w-[400px]` fixo — estoura em telas < 400 px |
| **Combobox de template Meta** | `w-[360px]` fixo |
| **Painel de sugestões de variável** | `w-[320px]` fixo, `absolute` |
| **Modal de variável** | `max-w-6xl` — abaixo de `lg` vira uma coluna muito longa |
| **Matriz de permissões** | `min-w-[120px]` × 5 colunas + `w-[180px]` = **780 px mínimos**; depende de scroll horizontal |

### C4.3 Acessibilidade — o que **está** bom

| Prática | Onde |
|---|---|
| `aria-label` em botões só de ícone | Tags ("Editar tag `<label>`"), Relatórios ("Remover disparo de `<dia>`", "Adicionar e-mail"), Selos (parcial), Prévia de variável ("Trocar cliente", "Atualizar dados do cliente") |
| `role="group"` + `aria-pressed` | `ColorPicker` de Tags |
| `role="alert"` | Erro de busca no teste de integração, erro de catálogo de variáveis, erro de busca de cliente, erro de disparo |
| `role="status"` | "Carregando dados do cliente…", "Texto gerado da variável" |
| `aria-live="polite"` | Lista de busca de cliente na prévia de variável |
| `aria-label` em seção | `<section aria-label="Pré-visualização da variável">` |
| `htmlFor` / `id` | Praticamente todos os campos de formulário |
| `<label>` envolvendo o controle | Seletor de título no teste de integração; `TypeSelector` de Tags |
| Navegação por teclado | `InputWithVariables` (setas, Enter, Tab, Esc); drag-and-drop de faixas (`KeyboardSensor`); `Enter` submete em vários modais |
| `focus-visible:ring` | Botões de cliente na prévia de variável |
| `aria-hidden` em ícone decorativo | Alguns pontos de Relatórios e Datas |

### C4.4 Acessibilidade — o que **falta**

| Problema | Impacto | Onde |
|---|---|---|
| **Combobox de variáveis sem semântica ARIA** | Leitor de tela não anuncia as sugestões | `InputWithVariables`: `div` + `button`s, sem `role="listbox"`/`role="option"`, sem `aria-activedescendant`, sem `aria-expanded` |
| **Item selecionado não faz scroll into view** | Navegar com setas além do 8º item esconde a seleção | `InputWithVariables` |
| **Informação só em tooltip** | Inacessível em touch e por teclado | Matriz de permissões (os 4 verbos), Explorador de Campos (`+N` valores), Aliases `+N` em Valores Padrão (**este sequer tem tooltip**) |
| **Informação só em `title` nativo** | Não anunciado consistentemente | Cadeado de credencial no card, header travado `x-org-slug`, descrição do papel no `RoleBadge`, "Cor do bucket", ações de linha em Datas/Custos |
| **`aria-label` com valor técnico** | "Cor #ef4444" em vez de "Vermelho" | `SealDialog` |
| **Botões só de ícone sem rótulo** | Lixeira de integração, ações de Datas Bloqueadas, cópia de variável | vários |
| **Cores sem variante `dark:`** | Texto ilegível no tema escuro | `INTEGRATION_TYPES` (10 cores), `CHANNEL_META` (9), `SOURCE_BADGE_CLASSES` (4), `COLOR_OPTIONS` de Valores Padrão (12), `COLOR_MAP` de Tags (7), pílulas de Réguas (3), badges verdes/cinza de Datas, `border-green-200 bg-green-50` do sucesso de teste e do preview de cURL |
| **Cor como único portador de significado** | Faixas de atraso, selos, tags, status de data | vários |
| **Contraste não garantido** | Chips de selo usam `color = seal.color` sobre `cor + "15"` — uma cor clara fica ilegível | Selos |
| **Sem `aria-describedby`** | Textos de ajuda (`text-xs text-muted-foreground`) não são associados aos campos | **todos** os formulários |
| **Erro não associado ao campo** | Mensagens de erro são `<p>` soltos, sem `aria-invalid`/`aria-describedby` | todos os formulários, exceto onde há `role="alert"` |
| **`window.confirm` / `alert`** | Não estilizáveis, não anunciam contexto, bloqueiam a thread | 6 ocorrências (C6) |
| **Foco após fechar modal** | Não há `onCloseAutoFocus` explícito em nenhum modal | todos |
| **Sem skip link nas abas** | 12 abas antes do conteúdo | `SettingsPage` |

### C4.5 Emojis funcionais no texto

Ocorrências que o redesign deve converter para ícone:

| Emoji | Onde |
|---|---|
| 🔒 | 3 rodapés da aba Autenticação do Construtor |
| 📋 | Rótulo "Exemplo de Payload (dados fictícios)" no `BodyEditor` |

---

## C5. Dores e oportunidades para o redesign

### C5.1 Bugs funcionais que o redesign deve corrigir (prioridade máxima)

| # | Bug | Onde | Impacto |
|---|---|---|---|
| 1 | **`useState(() => ...)` usado como efeito** — o formulário nunca é inicializado com os dados do servidor | `OrganizationTab` (B2.5), `ReguasTab` (B10.6) | **Salvar pode apagar domínio, cores, logo e limites** |
| 2 | **Campo `externalActionUrl` não é enviado no save** | `IntegrationsPage.handleSaveIntegration` (A4.3.4) | O valor digitado é descartado |
| 3 | **Importação de cURL remove o header travado `x-org-slug`** | `handleImportCurl` (A5.6) | Integração nasce sem o header obrigatório |
| 4 | **Basic Auth importado do cURL perde usuário e senha** | `handleImportCurl` (A5.6) | `authType = basic` com credenciais vazias, sem aviso |
| 5 | **Campo de valor do header travado parece editável e não é** | `updateHeader` (A4.3.6) | Digitação sem efeito, sem feedback |
| 6 | **Erro de listagem cai no estado vazio** | `IntegrationsPage` (A9.1) | "Nenhuma integração configurada" quando na verdade falhou o fetch |
| 7 | **Semente de `action_status` desatualizada** | `DEFAULT_STANDARD_VALUES` (B9.9) | Semeia "Entregue"/"Lido" (removidos) e omite "Interagiu"/"Duplicado" |
| 8 | **Duplicidade não checada na edição de valor padrão** | `validateForm` (B9.6) | Dois valores iguais no mesmo tipo |
| 9 | **Dois toasts de erro ao falhar remoção de integração** | `IntegrationCard` + `useDeleteOrgIntegration` (A4.9) | Ruído |
| 10 | **Três divergências de ícone entre `INTEGRATION_TYPES` e `TYPE_ICONS`** | A8.1 | WhatsApp e SMS com ícones trocados |
| 11 | **`notification` sem metadados em `CHANNEL_META`** | B7.4 | A linha mais cara da tabela aparece com rótulo cru em inglês |
| 12 | **Copy hard-coded na rotina de relatórios** | B13.3 | "os dois disparos", "segunda às 08h e sexta às 18h" com N disparos configuráveis |

### C5.2 Lacunas de segurança e permissão

| # | Lacuna | Onde |
|---|---|---|
| 1 | **Datas Bloqueadas sem gate de permissão** | B6.2 — qualquer usuário apaga feriados |
| 2 | **Custos por Canal sem gate de permissão** | B7.2 |
| 3 | **Explorador de Campos sem gate** (se for resgatado) | B12 |
| 4 | **Sem validação de URL no Construtor** | A4.3.5 — o módulo anti-SSRF existe (A9.5) e não é usado |
| 5 | **Credencial pode ser apagada ao salvar sem redigitar** | A2.4 — `credentials: {}` é enviado tal como está |
| 6 | **Segredo de API Key perdível com ESC** | A7.6 |

### C5.3 Inconsistências de sistema de design

| # | Inconsistência | Detalhe |
|---|---|---|
| 1 | **3 padrões de carregamento** | spinner (12 telas) · skeleton (3) · texto (1) |
| 2 | **3 padrões de estado vazio** | bloco solto · `Card` · `div` com borda |
| 3 | **3 representações de cor no banco** | classe Tailwind (Valores Padrão) · hex (Selos) · nome semântico (Tags) |
| 4 | **3 mapas de canal** | `INTEGRATION_TYPES` + `TYPE_ICONS` (Integrações) · `CHANNEL_META` (Custos) — cores e ícones divergentes para os mesmos canais |
| 5 | **2 mapas de papel** | `ROLE_CONFIG` em `UsersTab` (cores sólidas, **não usadas**) e em `RolesPermissionsCard` (cores de texto) |
| 6 | **2 mapas de dias da semana** | `DAYS_OF_WEEK` (sem acento) e `WEEKDAY_LABELS` (com acento) |
| 7 | **`<select>` nativo × `Select` do shadcn** | Modal de rotina de relatório usa nativo; todo o resto usa o componente |
| 8 | **`window.confirm` × `AlertDialog`** | 6 confirmações nativas convivendo com 15 `AlertDialog` |
| 9 | **`alert()` × `toast`** | 3 `alert()` no upload de logo |
| 10 | **Acentuação inconsistente** | Rótulos ASCII ("Configuracoes", "Usuarios", "Acoes") convivendo com textos acentuados corretos nas features novas |
| 11 | **"role" × "papel" × "perfil"** | Três termos para o mesmo conceito |
| 12 | **Toast de sucesso opcional** | 6 ações não dão nenhum feedback de conclusão (C2.4) |
| 13 | **Rótulo de aba ≠ conteúdo** | "Kanban" → Faixas de Atraso · "Reguas" → Indicadores e Metas · "Valores Padrao" com ícone `Tag` (que é o conceito da aba "Tags") |

### C5.4 Lacunas de arquitetura de informação

| # | Lacuna | Oportunidade |
|---|---|---|
| 1 | **12 abas planas, sem agrupamento** | Navegação lateral em famílias: *Organização · Operação · Conteúdo · Acesso* |
| 2 | **Sem rota por aba** | `activeTab` é estado local — sem deep-link, sem histórico, sempre volta a "Organizacao" |
| 3 | **Sem busca de configuração** | "onde configuro X?" não tem resposta |
| 4 | **Sem checklist de onboarding** | A ordem de C3.1 não existe em lugar nenhum |
| 5 | **Sem indicação de "configurado/pendente"** | Nenhuma aba sinaliza se já foi tocada |
| 6 | **`FieldExplorerTab` órfão** | Resolve exatamente a pergunta que B11 e B8 obrigam a fazer |
| 7 | **`TestConnectionPanel` órfão** | Teste de conexão rápido, complementar ao teste com dados reais |
| 8 | **`toCurl()` não exposto** | Botão "Copiar como cURL" pronto para uso |
| 9 | **Sem visão de calendário em Datas Bloqueadas** | Tabela linear para ~15 feriados |
| 10 | **Histórico de sync descartado** | A query traz N execuções; só a primeira é usada |
| 11 | **`last_used_at` de API Key não exibido** | Responderia "esta chave ainda é usada?" |
| 12 | **`is_manual_override` invisível** | Conceito central de Datas Bloqueadas, sem representação |
| 13 | **`metadata` de valor padrão invisível** | `classification`, `counts_as_sent`… governam métricas e não aparecem |
| 14 | **Descrição do tipo de integração não exibida** | Existe na constante, nunca é mostrada |
| 15 | **Descrição da variável personalizada não exibida** | Idem |

### C5.5 Diálogos destrutivos — escala de qualidade atual

Da melhor para a pior prática, para servir de referência ao padronizar:

| Nível | Exemplo | O que faz |
|---|---|---|
| **A — quantifica o impacto** | Remover perfil (C1.18), Remover tag (C1.30) | Nomeia, explica a consequência funcional e **conta** o que será afetado |
| **B — nomeia e explica** | Remover Variavel (C1.15) | Nomeia e mostra o token que vai quebrar |
| **C — nomeia** | Remover Valor (C1.17), Remover Agendamento (C1.22), Remover data (C1.13) | Nomeia o item |
| **D — genérico** | Remover API Key (C1.5), Excluir selo (C1.24), Remover selo (C1.25), Restaurar padrão (C1.11) | "Esta ação não pode ser desfeita" e nada mais |
| **E — nativo** | Remover integração (C1.3), Remover usuário / Cancelar convite (C1.9) | `window.confirm`, sem contexto |

**Meta do redesign:** levar tudo ao nível A ou B.

### C5.6 Guardas de alterações não salvas

| Superfície | Guarda? |
|---|---|
| Nova Tag / Editar Tag | **✓** `AlertDialog` "Descartar alterações?" + `useDirtyFormGuard` |
| Perfil da Operação | **✓ parcial** — indicador "Alterações não salvas." + botão "Descartar" (mas fechar a aba não avisa) |
| Faixas de Atraso | **✓ parcial** — botão "Cancelar" aparece quando `hasChanges` |
| Construtor de Integração | ✗ |
| Nova/Editar Variavel | ✗ |
| Novo/Editar Valor | ✗ |
| Novo/Editar Selo | ✗ |
| Novo/Editar Agendamento | ✗ |
| Configurar rotina | ✗ |
| Convidar/Editar Usuario | ✗ |
| Organização / Réguas (formulários de página) | ✗ |

### C5.7 Padrões a **preservar** no redesign

Coisas que funcionam bem e não devem ser perdidas:

| Padrão | Onde | Por quê |
|---|---|---|
| **Prévia com o motor real** | `VariablePreviewPanel` (B8.8) | Resolve com o mesmo código do envio; explica quantos itens casaram/apareceram/foram cortados; permite escolher entre dados fictícios e um cliente real |
| **Microcopy que diz o que acontece se ficar vazio** | `PipelineProfileTab` (B11.6) | Cada campo explica a consequência da ausência |
| **Erro persistente que distingue causa** | `PipelineProfileTab` (B11.12) | "indisponível neste ambiente" ≠ "configuração inválida" |
| **Contagem de impacto antes de excluir** | Perfil (B11.14), Tags (B15.9) | Transforma aviso genérico em decisão informada |
| **Hidratação por assinatura / guard por id** | Perfil (B11.13), Tags (B15.8) | Refetch não atropela o que o usuário digita |
| **PATCH semântico** | Tags (B15.8) | Só o que mudou; nenhum default silencioso |
| **Erro não fecha o modal** | Tags (B15.8), Construtor (A4.8) | Preserva o trabalho para retry |
| **Header travado com defesa em profundidade** | Construtor (A4.3.6) | `disabled` + guard no handler |
| **Exibição única do segredo** | API Keys (A7.6) | Postura correta; só falta travar o fechamento |
| **Badge de escopo explícito** | Tags (B15.3) | "Escopo: Organização" distingue do whitelist por agente |
| **Declarar a fonte do dado** | Datas Bloqueadas (B6.4) | "fonte: BrasilAPI" vs "cálculo local" muda o grau de confiança |
| **Estado vazio ≠ vazio por filtro** | Tags (B15.11), Selos (B14.5) | Mensagem honesta |
| **Erro + botão de retry** | Usuários (B3.4), Tags (B15.11) | |
| **Preview ao vivo da configuração** | Faixas (B5.6), Réguas (B10.3), Valores Padrão (B9.6), BodyEditor (A4.3.7) | Mostra o efeito antes de salvar |
| **`is_manual_override`** | Datas Bloqueadas (B6.7) | Decisão humana vence automação — só falta tornar visível |
| **Two-stage confirm na importação de cURL** | A5.3 | Analisar → conferir → importar |

---

## C6. Inventário de modais dos dois domínios

**31 superfícies modais** ao todo: 1 Sheet, 12 Dialog, 12 AlertDialog e 6 nativas.

### C6.1 Domínio Integrações (5)

| # | Nome | Tipo | Arquivo | Gatilho | Destrutivo | Confirmação |
|---|---|---|---|---|---|---|
| 1 | Construtor de Integração | **Sheet** | `integrations/IntegrationBuilderSheet.tsx` | "Nova Integração" · "Criar Primeira Integração" · "Editar" | não | — |
| 2 | Importar cURL | Dialog | `integrations/ImportCurlModal.tsx` | "Importar cURL" (aba Geral) | não | preview em 2 estágios |
| 3 | Remover esta integração? | **Nativo** | `pages/IntegrationsPage.tsx` | lixeira do card | **sim** | `window.confirm` |
| 4 | Criar nova API Key | Dialog (2 estágios) | `integrations/ApiKeysSection.tsx` | "Nova API Key" | não | — |
| 5 | Remover API Key? | AlertDialog | `integrations/ApiKeysSection.tsx` | lixeira da linha | **sim** (soft-delete) | `AlertDialog` |

### C6.2 Domínio Configurações (26)

| # | Nome | Tipo | Arquivo | Gatilho | Destrutivo | Confirmação |
|---|---|---|---|---|---|---|
| 6 | Tipo de arquivo não permitido | **Nativo** | `tabs/OrganizationTab.tsx` | upload de logo inválido | não | `alert` |
| 7 | Arquivo muito grande (5MB) | **Nativo** | `tabs/OrganizationTab.tsx` | upload > 5 MB | não | `alert` |
| 8 | Erro ao fazer upload | **Nativo** | `tabs/OrganizationTab.tsx` | falha no Storage | não | `alert` |
| 9 | Convidar Usuario | Dialog | `tabs/UsersTab.tsx` | "Convidar Usuario" | não | — |
| 10 | Editar Usuario | Dialog | `tabs/UsersTab.tsx` | lápis da linha | não | aviso âmbar se promove a owner |
| 11 | Remover este usuario? | **Nativo** | `tabs/UsersTab.tsx` | lixeira da linha | **sim** | `window.confirm` |
| 12 | Cancelar este convite? | **Nativo** | `tabs/UsersTab.tsx` | lixeira do convite | **sim** | `window.confirm` |
| 13 | Matriz de Permissoes | Dialog (leitura) | `RolesPermissionsCard.tsx` | "Ver Permissoes" | não | — |
| 14 | Restaurar configuracao padrao? | AlertDialog | `tabs/AgingBucketsTab.tsx` | "Restaurar Padrao" | **sim** | `AlertDialog` (sem estilo destrutivo) |
| 15 | Adicionar Data Bloqueada | Dialog | `tabs/BlockedDatesTab.tsx` | "Adicionar Data" | não | — |
| 16 | Remover a data "X"? | **Nativo** | `tabs/BlockedDatesTab.tsx` | lixeira da linha | **sim** | `window.confirm` (**nomeia o item**) |
| 17 | Nova / Editar Variavel | Dialog (2 colunas) | `tabs/CustomVariablesTab.tsx` | "Nova Variavel" · lápis | não | — |
| 18 | Remover Variavel | AlertDialog | `tabs/CustomVariablesTab.tsx` | lixeira da linha | **sim** | `AlertDialog` (mostra o token) |
| 19 | Novo / Editar Valor | Dialog | `StandardValuesSettings.tsx` | "Novo Valor" · lápis | não | — |
| 20 | Remover Valor | AlertDialog | `StandardValuesSettings.tsx` | lixeira da linha | **sim** | `AlertDialog` |
| 21 | Remover o perfil de formalização? | AlertDialog | `tabs/PipelineProfileTab.tsx` | "Remover perfil" | **sim** | `AlertDialog` **com contagem** |
| 22 | Configurar Relatório de Performance | Dialog | `tabs/TowerReportRoutineCard.tsx` | "Configurar" / "Ativar rotina" | não (contém deletes) | — |
| 23 | Enviar teste agora? | AlertDialog | `tabs/TowerReportRoutineCard.tsx` | "Enviar teste agora" | não (envia e-mail real) | `AlertDialog` |
| 24 | Novo / Editar Agendamento | Dialog | `tabs/ReportSchedulesTab.tsx` | "Novo Agendamento" · lápis | não | — |
| 25 | Remover Agendamento | AlertDialog | `tabs/ReportSchedulesTab.tsx` | lixeira da linha | **sim** | `AlertDialog` |
| 26 | Novo / Editar Selo | Dialog | `seals/SealDialog.tsx` | "Novo Selo" · "Editar" | não | — |
| 27 | Excluir selo de X? | AlertDialog | `tabs/SealCatalogTab.tsx` | "Excluir" | **sim** | `AlertDialog` |
| 28 | Remover selo? (de uma entidade) | AlertDialog | `tabs/SealAssignmentsList.tsx` | `X` na linha | **sim** | `AlertDialog` |
| 29 | Nova Tag | Dialog | `tabs/TagCatalogTab.tsx` | "Nova tag" · "Criar primeira tag" | não | — |
| 30 | Descartar alterações? (criação) | AlertDialog | `tabs/TagCatalogTab.tsx` | fechar com `isDirty` | não | `AlertDialog` |
| 31 | Editar Tag | Dialog | `tabs/TagCatalogTab.tsx` | lápis da linha | não | — |
| 32 | Descartar alterações? (edição) | AlertDialog | `tabs/TagCatalogTab.tsx` | fechar com `isDirty` | não | `AlertDialog` |
| 33 | Remover tag | AlertDialog | `tabs/TagCatalogTab.tsx` | lixeira da linha | **sim** | `AlertDialog` **com contagem de uso** |

### C6.3 Resumo por tipo

| Tipo | Quantidade | Observação |
|---|---|---|
| **Sheet** | 1 | Construtor de Integração |
| **Dialog** | 12 | 2 deles com layout especial (2 estágios; 2 colunas) |
| **AlertDialog** | 14 | 11 destrutivos, 3 de confirmação não destrutiva |
| **Nativo (`confirm`)** | 3 | **a converter** |
| **Nativo (`alert`)** | 3 | **a converter** |
| **Total** | **33 superfícies** (numeração até 33 com os dois "Descartar alterações?" contados separadamente) |

### C6.4 Ações destrutivas **sem nenhuma** confirmação

| Ação | Onde | Risco |
|---|---|---|
| Remover faixa de atraso (lixeira) | `AgingBucketsTab` (B5.5) | Apaga a faixa direto; desfazer exige "Cancelar", que descarta **todas** as mudanças |
| Remover linha de header | `IntegrationBuilderSheet` (A4.3.6) | Recuperável só reabrindo o Sheet sem salvar |
| Remover campo do Body Template | `BodyEditor` (A4.3.7) | idem |
| Remover logo da organização | `OrganizationTab` (B2.3) | Botão vermelho flutuante; só efetiva ao salvar |
| Alternar Switch de integração (ativar/desativar) | `IntegrationCard` (A4.9) | Efeito imediato em produção, **sem toast de sucesso** |
| Alternar Switch de data bloqueada | `BlockedDatesTab` (B6.8) | idem |
| Alternar Switch de variável ativa | `CustomVariablesTab` (B8.11) | Quebra `{{var.X}}` em todas as mensagens, sem aviso |
| Alternar Switch de valor padrão ativo | `StandardValuesSettings` (B9.5) | Afeta a normalização do ETL |
| Alternar Switch de agendamento ativo | `ReportSchedulesTab` (B13.4) | Para o envio automático |
| **Importar JSON de valores padrão** | `StandardValuesSettings` (B9.8) | **Sobrescreve valores existentes em silêncio, sem preview nem confirmação** |
| **Importar cURL** | `ImportCurlModal` (A5.6) | Substitui URL, método, headers, body e auth do rascunho |
| Importar Feriados Nacionais | `BlockedDatesTab` (B6.6) | Menos grave (preserva overrides manuais), mas dispara sem confirmar |

> **Recomendação:** para os *switches*, adotar toast com ação **"Desfazer"** em vez de confirmação prévia — mantém a fluidez e cria a rede de segurança. Para as importações, exigir preview + confirmação explícita.

---

## Apêndice · Índice de arquivos-fonte citados

### Integrações

```
src/pages/IntegrationsPage.tsx
src/components/integrations/IntegrationBuilderSheet.tsx
src/components/integrations/IntegrationTestPanel.tsx
src/components/integrations/TestConnectionPanel.tsx        (órfão)
src/components/integrations/ApiKeysSection.tsx
src/components/integrations/BodyEditor.tsx
src/components/integrations/ImportCurlModal.tsx
src/components/integrations/InputWithVariables.tsx
src/components/integrations/VariableHighlightTextarea.tsx
src/lib/constants/integration-types.ts
src/lib/constants/integration-variables.ts
src/lib/curl-parser.ts
src/lib/webhook-url-validation.ts                          (não usado nesta tela)
src/hooks/useIntegrations.ts
src/hooks/useIntegrationTest.ts
src/hooks/useApiKeys.ts
src/pages/central-docs/negocio/data/integracoes.ts         (guia embarcado)
```

### Configurações

```
src/pages/SettingsPage.tsx
src/components/settings/tabs/OrganizationTab.tsx
src/components/settings/tabs/UsersTab.tsx
src/components/settings/RolesPermissionsCard.tsx
src/components/settings/tabs/AgingBucketsTab.tsx
src/components/settings/tabs/BlockedDatesTab.tsx
src/components/settings/tabs/ChannelCostsTab.tsx
src/components/settings/tabs/CustomVariablesTab.tsx
src/components/settings/VariableDefinitionFields.tsx
src/components/settings/VariablePreviewPanel.tsx
src/components/settings/tabs/FieldExplorerTab.tsx          (órfão)
src/components/settings/tabs/PipelineProfileTab.tsx
src/components/settings/tabs/pipelineProfileForm.ts
src/components/settings/tabs/ReguasTab.tsx
src/components/settings/StandardValuesSettings.tsx
src/components/settings/tabs/ReportSchedulesTab.tsx
src/components/settings/tabs/TowerReportRoutineCard.tsx
src/components/settings/tabs/SealCatalogTab.tsx
src/components/settings/tabs/SealAssignmentsList.tsx
src/components/seals/SealDialog.tsx
src/components/settings/tabs/TagCatalogTab.tsx
src/hooks/useSettings.ts
src/hooks/useStandardValues.ts
src/hooks/useAgingBuckets.ts
src/hooks/useBlockedDates.ts
src/hooks/useChannelCosts.ts
src/hooks/useCustomVariables.ts
src/hooks/useTagCatalog.ts
src/hooks/useSeals.ts
src/hooks/useReportSchedules.ts
src/hooks/useOrgPipelineProfile.ts
src/hooks/useVariables.ts
src/types/seals.ts
supabase/functions/_shared/template-variables.ts           (motor, re-exportado em src/lib/template-variables.ts)
```

### Testes existentes (referência de comportamento esperado)

```
src/components/settings/__tests__/VariablePreviewPanel.test.tsx
src/components/settings/tabs/__tests__/TagCatalogTab.spec.tsx
src/components/settings/tabs/__tests__/TowerReportRoutineCard.spec.tsx
src/components/settings/tabs/__tests__/pipelineProfileForm.spec.ts
```

---

*Documento produzido por leitura direta do código-fonte em `cobranca-finza/src/`. Todos os textos de interface citados entre aspas são transcrições literais, incluindo erros de acentuação presentes no código. Pontos não determináveis pela leitura estão marcados com `⚠️ A confirmar`.*
