# 22 · Painel Maestro e Elementos Globais da Interface

> **Propósito deste documento.** Registrar, com precisão suficiente para um redesenho completo, tudo que existe hoje no painel lateral do agente de IA (Maestro) e nos elementos de interface que atravessam **todas** as telas da Torre de Controle: busca global de cliente, esqueletos de carregamento, toasts, tratamento de erro, guarda de formulário sujo e modais montados em nível de aplicação.
>
> **Regra de leitura.** Tudo abaixo foi extraído da leitura do código-fonte do repositório `cobranca-finza`. Onde o código não responde, a lacuna está marcada como `⚠️ A confirmar`. Textos de interface aparecem entre aspas **exatamente como estão no código** — inclusive quando estão sem acentuação (boa parte da copy do painel Maestro está sem acentos no fonte, e isso é um achado, não um erro de transcrição).
>
> **Público.** Designer responsável pelo redesenho. O objetivo é que nenhuma funcionalidade se perca na travessia.

---

## Sumário

0. [Visão geral dos elementos globais](#0-visão-geral-dos-elementos-globais)
1. [Painel lateral do Maestro (AgentSidePanel)](#1-painel-lateral-do-maestro-agentsidepanel)
2. [Visão de chat](#2-visão-de-chat)
3. [Visão de plano e de execução](#3-visão-de-plano-e-de-execução)
4. [Histórico de sessões](#4-histórico-de-sessões)
5. [Configuração do Maestro (AgentConfigModal)](#5-configuração-do-maestro-agentconfigmodal)
6. [Auditoria (AgentAuditLogViewer)](#6-auditoria-agentauditlogviewer)
7. [Contexto de página (usePageContext / AgentContextToggle)](#7-contexto-de-página-usepagecontext--agentcontexttoggle)
8. [Busca global de cliente na sidebar (CustomerSearch)](#8-busca-global-de-cliente-na-sidebar-customersearch)
9. [Catálogo de estados de carregamento (loading-states.tsx)](#9-catálogo-de-estados-de-carregamento-loading-statestsx)
10. [Sistema de notificação (toasts)](#10-sistema-de-notificação-toasts)
11. [Tratamento de erro](#11-tratamento-de-erro)
12. [Guarda de formulário sujo (useDirtyFormGuard)](#12-guarda-de-formulário-sujo-usedirtyformguard)
13. [Modais globais (inventário)](#13-modais-globais-inventário)
14. [Dores e oportunidades para o redesign](#14-dores-e-oportunidades-para-o-redesign)

---

## 0. Visão geral dos elementos globais

### 0.1 Onde cada coisa é montada

A hierarquia de montagem define o alcance de cada elemento. Ela está em `src/App.tsx` e `src/components/layout/AppLayout.tsx`.

```
<ErrorBoundary>                                  ← src/App.tsx:443 — captura toda a árvore
  <QueryClientProvider>
    <TooltipProvider>
      <BrowserRouter>
        <AuthProvider>
          <OrganizationProvider>
            <AppRoutes />
              ├─ rotas públicas / full-screen (login, /docs, /central-docs, /docs-especial…)
              └─ Route "/*"
                   <ProtectedRoute>
                     <RequireOrg>
                       <AgentPanelProvider>      ← src/App.tsx:403 — SÓ o app autenticado
                         <AppLayout>             ← shell fixed inset-0 flex overflow-hidden
                           ├─ backdrop mobile (z-40)
                           ├─ <Sidebar>          ← CustomerSearch, AgentSidebarButton, DocsNavButton
                           ├─ <main>             ← margin-right reage ao painel do Maestro
                           ├─ <AgentSidePanel/>  ← z-40, fixed right
                           └─ <ChangelogNotificationBalloon/>  ← z-50, canto inferior direito
                         </AppLayout>
                       </AgentPanelProvider>
      </BrowserRouter>
      <Toaster />                                ← src/App.tsx:453 — FORA do BrowserRouter
```

**Consequências de escopo que o redesign precisa respeitar:**

| Elemento | Escopo real | Observação |
|---|---|---|
| `ErrorBoundary` | App inteiro, inclusive rotas públicas | Único; não há boundaries por rota ou por seção |
| `Toaster` | App inteiro | Está **fora** do `BrowserRouter` — um toast sobrevive a troca de rota |
| `AgentPanelProvider` / `AgentSidePanel` | Só rotas dentro de `/*` (app autenticado com org) | **Não existe** em `/central-docs`, `/docs`, `/docs-especial`, `/docs/fonte-de-dados`, editores full-screen (`/reguas-cobranca/:id/editor`, `/broadcasts/:id/editor`) |
| `CustomerSearch` | Só onde há `Sidebar` | Mesma restrição acima |
| `ChangelogNotificationBalloon` | Só dentro do `AppLayout` | Aparece para qualquer perfil |
| `useDirtyFormGuard` (host) | **Só** `src/pages/AgentWorkspace.tsx` | Não é global de verdade — ver §12 |

### 0.2 O shell do app autenticado (`AppLayout`)

Arquivo: `src/components/layout/AppLayout.tsx`

| Aspecto | Valor literal |
|---|---|
| Container raiz | `fixed inset-0 flex overflow-hidden` com `data-testid="app-layout"` |
| Por que `fixed` | Comentário no código: estabelece o containing block; sem ele, descendentes `absolute` sem ancestral posicionado (notadamente `sr-only`) somam ao `scrollHeight` do `<html>` e criam um segundo scroll com área vazia. Medido em `/agent-ia?tab=metrics` @720px: `html.scrollHeight` 2135px → 720px |
| Breakpoint mobile | `window.matchMedia("(max-width: 767px)")` — hook local `useIsMobile` |
| Sidebar desktop | `relative`, largura `w-64` aberta / `w-16` colapsada, transição 300ms |
| Sidebar mobile | `fixed inset-y-0 left-0 z-50`, `-translate-x-full` quando fechada — drawer feito à mão, **não** é um `Sheet` do Radix |
| Backdrop mobile | `fixed inset-0 z-40 bg-black/50 backdrop-blur-sm`, fecha ao clique |
| Persistência do colapso | `localStorage["sidebar-collapsed"]` (string `"true"`/`"false"`) |
| Header mobile | Só `< 768px`: logo `h-7` + botão hamburger `Menu` `h-9 w-9` |
| Scroller único | `div[data-testid="app-scroll-container"]` com `min-h-0 flex-1 overflow-auto overscroll-contain p-3 sm:p-6` |
| Reset de scroll | `useEffect` em `location.pathname` (não em `search`) → `scrollTo({top:0,left:0})` |
| Reação ao painel do Maestro | `<main style={{ marginRight: isAgentPanelOpen ? agentPanelWidth : 0 }}` com `transition-all duration-300` |
| Skip-link | `<a href="#main-content">` com texto **"Pular para conteudo principal"** (sem acento no código), `sr-only focus:not-sr-only` |

### 0.3 A sidebar (contexto para os elementos globais que vivem nela)

Arquivo: `src/components/layout/Sidebar.tsx`

Ordem vertical dos blocos:

1. **Header** `h-16 border-b px-3`: logo completo (`torreControleLogo`) ou ícone (`torreControleIcon`) quando colapsada; botão `ChevronLeft` (desktop) para colapsar. Quando colapsada, um `ChevronRight` aparece abaixo do header.
2. **`<nav className="flex-1 space-y-1 p-2 overflow-y-auto">`**
   - **`<CustomerSearch collapsed={isCollapsed} />`** — primeiro item, acima de tudo (§8).
   - 12 itens de navegação, filtrados por `hasPermission`:

   | Rótulo | Rota | Ícone | Permissão |
   |---|---|---|---|
   | Dashboard | `/` | `LayoutDashboard` | — |
   | Gestão de Carteira | `/portfolio` | `Users` | — |
   | Campanhas | `/campaigns` | `Target` | `campaigns:read` |
   | Réguas de Cobrança | `/reguas-cobranca` | `GitBranch` | `workflows:read` |
   | Templates | `/templates` | `MessageSquareText` | `templates:read` |
   | Filtros | `/filters` | `Filter` | `filters:read` |
   | Ações | `/actions` | `Zap` | `actions:read` |
   | Disparos | `/disparos` | `Send` | `disparos:write` |
   | Agente IA | `/agent-ia` | `Bot` | `agent-ia:read` |
   | Integrações | `/integrations` | `Plug` | `integrations:read` |
   | Fonte de Dados | `/etl` | `Database` | `etl:read` |
   | Configurações | `/settings` | `Settings` | `settings:read` |

   Item ativo: `bg-sidebar-accent text-sidebar-accent-foreground`. Inativo: `text-sidebar-foreground hover:bg-sidebar-accent/10 hover:text-sidebar-accent`. Colapsado, cada item vira `Tooltip side="right"` com o próprio rótulo. `onMouseEnter` dispara `prefetchRoute(item.href)`; ao montar, `prefetchAllRoutes()`.
3. **Bloco de ferramentas** `p-2 border-t space-y-1`:
   - **`<AgentSidebarButton collapsed />`** (§1.2)
   - **`<DocsNavButton isCollapsed onNavigate />`** (documentado no doc 21)
4. **Footer** `border-t p-3 space-y-2`:
   - Dropdown de organização: logo/`Building2` + nome + `ChevronDown`; menu com label **"Organizações"**, uma linha por org, separador e **"Gerenciar Organizações"** (`Settings`) → limpa `localStorage["torre-controle-current-org"]`, `invalidateAllQueries()` e navega para `/select-organization`.
   - Dropdown de usuário: `Avatar` (iniciais = 2 primeiras letras do prefixo do e-mail, maiúsculas) + nome + e-mail; menu com **"Perfil"** (`User`, **sem handler**), **"Modo Escuro"**/**"Modo Claro"** (`Moon`/`Sun`, `toggleTheme`) e **"Sair"** (`LogOut`, `text-destructive`).

### 0.4 Design tokens usados pelos elementos globais

Todos os elementos globais usam tokens semânticos do tema (`bg-background`, `bg-card`, `bg-muted`, `text-muted-foreground`, `bg-primary`, `text-destructive`, `border-border`, `bg-sidebar-background`, `text-sidebar-foreground`, `bg-sidebar-accent`). As exceções — cores literais de paleta Tailwind — estão concentradas no painel do Maestro e são listadas caso a caso (§1.2, §1.5, §2.3, §3.2, §6.1).

---

## 1. Painel lateral do Maestro (AgentSidePanel)

**Arquivos:** `src/components/agent/AgentSidePanel.tsx`, `src/contexts/AgentPanelContext.tsx`, `src/components/agent/AgentSidebarButton.tsx`
**Montagem:** `AppLayout.tsx:136`, irmão do `<main>`
**Permissão:** nenhuma checagem de permissão — qualquer usuário autenticado com org selecionada vê o botão e pode abrir o painel. `⚠️ A confirmar:` se isso é intencional (o Maestro pode executar ações de escrita).

### 1.1 Identidade

| Item | Valor |
|---|---|
| Nome exibido | **"Maestro"** (header do painel) / **"Maestro IA"** (botão da sidebar) |
| Rota | Nenhuma — é overlay persistente do layout, não uma rota |
| Container | `fixed right-0 top-0 bottom-0 z-40 border-l bg-background shadow-lg flex flex-col` com `style={{ width }}` |
| Renderização condicional | `if (!isOpen) return null` — quando fechado, **não renderiza nada** (sem animação de saída) |
| Acessibilidade | **Ausente**: sem `role="complementary"`, sem `aria-label`, sem `aria-modal`, sem foco gerenciado |

### 1.2 Botão de abertura (`AgentSidebarButton`)

| Estado | Anatomia |
|---|---|
| Sidebar expandida | `Button variant="ghost" className="w-full justify-start gap-2"` com ícone `Bot` (`h-5 w-5`) + `<span>Maestro IA</span>` |
| Sidebar colapsada | `Button variant="ghost" size="icon" className="w-full"` só com `Bot`, envolto em `Tooltip` com `TooltipContent side="right"` de texto **"Maestro IA"** |
| Ação | `onClick={toggle}` — alterna abrir/fechar |
| Badge / indicador | **Não existe.** Sem contador de não lidas, sem ponto de "sessão ativa", sem realce quando `isOpen === true`. O botão **não reflete o estado do painel** |

### 1.3 Dimensões, redimensionamento e persistência

| Constante | Valor | Onde |
|---|---|---|
| `DEFAULT_WIDTH` | `400` px | `AgentPanelContext.tsx:155` |
| `MIN_WIDTH` | `320` px | `AgentPanelContext.tsx:156` |
| `MAX_WIDTH` | `700` px | `AgentPanelContext.tsx:157` |

**Handle de redimensionamento** (`AgentSidePanel.tsx:84-102`):

- Elemento: `<div className="absolute left-0 top-0 bottom-0 w-1 cursor-ew-resize hover:bg-primary/20 transition-colors" />` — faixa de **1px** na borda esquerda do painel, que ganha fundo `primary/20` no hover.
- `onMouseDown` → `isResizing.current = true`, `e.preventDefault()`, registra `mousemove`/`mouseup` **no `document`**.
- Cálculo: `newWidth = window.innerWidth - e.clientX`, depois `setWidth(Math.max(320, Math.min(700, newWidth)))`.
- **O clamp está duplicado**: literais `320`/`700` no componente **e** as constantes no contexto.
- `mouseup` desliga o flag e remove os listeners.
- **Não há:** suporte a touch/pointer events, duplo-clique para resetar, atalho de teclado, `user-select: none` durante o drag, `role="separator"`, `aria-valuenow`.
- `resizeRef` é criado e atribuído ao handle, mas **nunca é lido**.

**Persistência: NÃO EXISTE.** Nenhum `localStorage`, `sessionStorage`, cookie ou query param. `isOpen`, `width`, `view`, `contextAware` e a sessão são `useState` em memória. **Recarregar a página fecha o painel, volta a 400px, volta para a view `chat`, religa `contextAware` e perde a sessão corrente.**

> Contraste factual relevante para o redesign: a sidebar **persiste** seu colapso em `localStorage["sidebar-collapsed"]`. O painel do Maestro não tem equivalente.

### 1.4 Impacto no layout

- O `<main>` recebe `style={{ marginRight: isAgentPanelOpen ? agentPanelWidth : 0 }}` com `transition-all duration-300` (`AppLayout.tsx:105-111`).
- Portanto o conteúdo é **empurrado**, não coberto. A sidebar esquerda não é afetada.
- **Nuance:** a `transition-all duration-300` também se aplica **durante o drag** — o `marginRight` acompanha a largura com atraso perceptível, porque nada desliga a transição enquanto se redimensiona.
- Empilhamento: painel `z-40`; backdrop mobile da sidebar `z-40`; sidebar mobile `z-50`. **A sidebar mobile fica acima do painel.**

### 1.5 Anatomia do painel, de cima para baixo

#### (a) Header — `p-4 border-b bg-background/95 backdrop-blur`

**Lado esquerdo:**
- Ícone composto: `Bot` (`h-5 w-5 text-primary`) com `Sparkles` (`h-2.5 w-2.5 text-yellow-500`) sobreposto no canto superior direito.
- Título **"Maestro"** (`font-semibold`).
- **Seletor de modo** — `DropdownMenu` com gatilho `Button variant="outline" size="sm" h-6 text-xs`: bolinha colorida + label do modo + `ChevronDown`.

| valor | label | descrição (subtexto do item de menu) | bolinha |
|---|---|---|---|
| `plan` | "Plan" | "Propoe acoes e aguarda aprovacao" | `bg-blue-500` |
| `semi_auto` | "Semi-Auto" | "Executa acoes de baixo risco automaticamente" | `bg-yellow-500` |
| `full_auto` | "Full-Auto" | "Executa todas as acoes automaticamente" | `bg-red-500` |

O item selecionado exibe o caractere literal **"✓"** à direita.

**Lado direito — 5 controles, todos `Button variant="ghost" size="icon"`:**

| # | Ícone | `title` | Ação |
|---|---|---|---|
| 1 | `MessageSquarePlus` | "Nova conversa" | `clearSession()` |
| 2 | `History` | "Historico de sessoes" | Abre `AgentSessionHistory` (Popover) |
| 3 | `FileText` | "Audit logs" | Abre `AgentAuditLogViewer` (Popover) |
| 4 | `Settings2` | "Configuracoes" | Abre `AgentConfigModal` |
| 5 | `X` | "Fechar" | `close()` |

#### (b) Faixa do toggle de contexto

`<div className="px-4 py-2 border-b flex items-center justify-between bg-muted/30">` contendo `<AgentContextToggle />` (§7).

#### (c) Indicador de persona (condicional)

Renderiza **apenas** se `session && currentPersona !== "general"`. Faixa `px-4 py-2 border-b` com as cores da persona, exibindo `{personaConfig.label}` + a palavra **"ativo"** em `text-xs opacity-75`.

`PERSONA_CONFIG` do painel (`AgentSidePanel.tsx:32-39`):

| chave | label | cor do texto | fundo |
|---|---|---|---|
| `general` | "Modo Geral" | `text-blue-600` | `bg-blue-50` |
| `analyst` | "Analista" | `text-purple-600` | `bg-purple-50` |
| `strategist` | "Estrategista" | `text-green-600` | `bg-green-50` |
| `writer` | "Redator" | `text-orange-600` | `bg-orange-50` |
| `optimizer` | "Treinador IA" | `text-yellow-600` | `bg-yellow-50` |
| `etl` | "ETL/Dados" | `text-cyan-600` | `bg-cyan-50` |

> ⚠️ Todos os fundos são variantes claras (`*-50`) sem par para modo escuro. Em dark mode essas faixas ficam com contraste ruim.

#### (d) Corpo — as três "visões"

**Não existe `TabsList` visível.** A troca de visão é **programática** via `setView`:

| `view` | Componente |
|---|---|
| `"chat"` | `<AgentChatView />` |
| `"plan"` | `<AgentPlanView />` |
| `"execution"` | `<AgentExecutionView />` |

O usuário **nunca escolhe a view diretamente**. Ela muda quando:
- chega uma proposta do backend → `setView("plan")` (dentro de `useAgentSession`);
- o usuário aprova → `setView("execution")` (dentro de `useAgentProposals`);
- o usuário clica em "Voltar ao chat", "Ajustar", "Continuar Conversa" ou no botão de rejeitar.

#### (e) Footer

O painel **não tem footer próprio**. O composer pertence ao `AgentChatView`; `AgentPlanView` e `AgentExecutionView` têm suas próprias barras de ação.

### 1.6 Troca de modo — comportamento destrutivo

`handleModeChange` (`AgentSidePanel.tsx:66-75`):

1. Se o modo clicado é igual ao da sessão → não faz nada.
2. Caso contrário: `clearSession()` → `setSelectedMode(newMode)` → `await createSession(newMode)`.

**Ou seja: trocar de modo descarta a conversa atual e cria uma sessão nova, sem nenhuma confirmação.** Um `useEffect` sincroniza `selectedMode` com `session.mode` quando a sessão muda.

**Divergência factual:** `AgentChatView` chama `startChat(trimmed)` **sem passar modo**, e `startChat` tem default `mode = "plan"`. Se o usuário escolher "Semi-Auto"/"Full-Auto" e a criação de sessão pelo dropdown falhar — ou se ele simplesmente digitar sem sessão ativa — a sessão nasce em `plan`, independentemente do seletor. **O seletor só afeta a sessão criada pelo próprio dropdown.**

`handleSelectSession` loga `"[Maestro] Loading session from history:"` no console e chama `loadSession(sessionId)`.

### 1.7 Estado global exposto pelo contexto

`AgentPanelContextType` (`src/contexts/AgentPanelContext.tsx`):

| Grupo | Campos |
|---|---|
| Painel | `isOpen`, `width`, `view`, `open()`, `close()`, `toggle()`, `setWidth(n)`, `setView(v)` |
| Sessão | `session`, `setSession`, `clearSession()` |
| Mensagens | `messages`, `setMessages`, `addMessage` |
| Propostas | `proposals`, `setProposals`, `addProposal`, `updateProposal(id, partial)`, `removeProposal(id)` |
| Carga/erro | `isLoading`, `setLoading`, `error`, `setError` |
| "Pensando" | `thinkingStatus`, `setThinkingStatus` |
| Contexto | `contextAware`, `setContextAware`, `contextAwarenessEnabled` (alias literal de `contextAware`) |
| Página | `pageContext`, `setPageContext` |

**Valores iniciais:** `isOpen=false`, `width=400`, `view="chat"`, `session=null`, `messages=[]`, `proposals=[]`, `isLoading=false`, `error=null`, `thinkingStatus=null`, `contextAware=true` (**ligado por padrão**), `pageContext=null`.

`clearSession()` zera `session`, `messages`, `proposals`, `error`, `thinkingStatus` e volta `view` para `"chat"`. **Não fecha o painel e não chama nenhuma Edge Function.**

`useAgentPanel()` lança `"useAgentPanel must be used within an AgentPanelProvider"` fora do provider.

### 1.8 Contrato de dados (tipos do contexto)

```ts
AgentSession  = { id, mode: "plan"|"semi_auto"|"full_auto", persona: string,
                  status: "active"|"completed"|"abandoned",
                  totalMessages, totalTokensUsed, createdAt }

AgentMessage  = { id, role: "user"|"assistant"|"system"|"tool_result", content,
                  persona?, toolName?, toolArgs?, toolResult?, metadata?, createdAt }

ExecutionPlanStep = { id, description, entity_type?, entityType?,   // as DUAS grafias coexistem
                      risk_level?, status?: "pending"|"executing"|"completed"|"failed", data? }

ExecutionPlan = { steps[], estimated_impact?: { contacts?, titles? }, rollback_plan? }

AgentProposal = { id, title, description?, proposalType,
                  riskLevel: "low"|"medium"|"high"|"critical",
                  status: "pending"|"approved"|"rejected"|"executing"|"completed"|"failed",
                  executionPlan, estimatedContacts?, estimatedTitles?, createdAt }

ThinkingStatus = { stage: "thinking"|"tool_call"|"processing"|"finalizing", message, toolName? }
```

---

## 2. Visão de chat

**Arquivos:** `AgentChatView.tsx`, `AgentChatMessage.tsx`, `AgentMarkdown.tsx`

### 2.1 Estrutura

`flex flex-col h-full` → `<ScrollArea className="flex-1">` (lista, `p-4 space-y-4`) + bloco de input (`border-t p-4`).

**Auto-scroll:** `useEffect` seta `scrollRef.current.scrollTop = scrollHeight` quando `messages` ou `isLoading` mudam.
> ⚠️ Nuance técnica: o `ref` vai no `ScrollArea` do shadcn, cujo viewport rolável é um **filho**. O efeito age sobre o elemento raiz. `⚠️ A confirmar:` se o auto-scroll funciona de fato hoje.

### 2.2 Estado vazio (`WelcomeMessage`)

Renderizado quando `messages.length === 0 && !isLoading`.

| Elemento | Valor literal |
|---|---|
| Ícone | `Bot` branco (`h-8 w-8`) em quadrado `h-16 w-16 rounded-2xl bg-gradient-to-br from-blue-500 to-purple-600` |
| Título | **"Ola! Sou o Maestro"** |
| Subtítulo | **"Seu assistente de cobranca. Posso ajudar a criar campanhas, analisar dados e otimizar suas estrategias."** |
| Sugestões | 4 pílulas `rounded-full border`: **"Analisar carteira"**, **"Criar campanha"**, **"Ver metricas"**, **"Otimizar regua"** |

> **Achado crítico:** as pílulas de sugestão **não têm `onClick`** (`AgentChatView.tsx:71-73`). São botões inertes — clicar não preenche o composer nem envia nada.

### 2.3 Papéis de mensagem (`AgentChatMessage`)

| `role` | Renderização |
|---|---|
| `user` | Bolha alinhada à **direita**, `max-w-[85%]`, `bg-primary text-primary-foreground rounded-lg px-4 py-2.5`; conteúdo em `<p className="text-sm whitespace-pre-wrap">` — **texto puro, sem markdown**. Acima da bolha, alinhados à direita: texto **"Voce"** (`text-xs text-muted-foreground`) + ícone `User` (`h-3.5 w-3.5`) |
| `tool_result` | **`return null`** — nunca é exibida (comentário no código: "usually hidden, shown inline") |
| `system` | **Sem tratamento dedicado** — cai no ramo "assistant" |
| `assistant` | Cabeçalho com quadradinho `h-5 w-5 rounded` colorido contendo o ícone da persona + label; bolha `bg-muted/50 rounded-lg px-4 py-3 ml-7`; conteúdo via `AgentMarkdown`. Se `message.persona` existe e é diferente de `"general"`, aparece um `Badge variant="outline"` com o texto **"modo ativo"** |

`PERSONA_CONFIG` de `AgentChatMessage.tsx:33-73` — **note que o label de `general` é diferente do usado no painel**:

| chave | label | ícone | cor / fundo |
|---|---|---|---|
| `general` | **"Maestro"** (no painel é "Modo Geral") | `Bot` | `text-blue-600` / `bg-blue-50` |
| `analyst` | "Analista" | `BarChart3` | `text-purple-600` / `bg-purple-50` |
| `strategist` | "Estrategista" | `Target` | `text-green-600` / `bg-green-50` |
| `writer` | "Redator" | `PenTool` | `text-orange-600` / `bg-orange-50` |
| `optimizer` | "Treinador IA" | `GraduationCap` | `text-yellow-600` / `bg-yellow-50` |
| `etl` | "ETL/Dados" | `Database` | `text-cyan-600` / `bg-cyan-50` |

### 2.4 Avatar e timestamp

- **Avatar:** não há avatar de imagem. O usuário tem só o ícone `User` monocromático; o assistente tem o quadradinho colorido com o ícone da persona.
- **Timestamp: NÃO É EXIBIDO EM NENHUMA MENSAGEM.** `message.createdAt` existe no tipo e é preenchido pelo hook, mas o componente nunca o renderiza. Não há formato de data no chat. Timestamps só aparecem em `AgentSessionHistory` e `AgentAuditLogViewer`.

### 2.5 Ações por mensagem

**Não existem.** Sem copiar, regenerar, editar, "gostei/não gostei" ou menu de contexto.

A única interação por mensagem é o acordeão de ferramenta — `ToolDisplay` (`AgentChatMessage.tsx:85-148`), renderizado dentro da bolha do assistente quando `message.toolName` existe:

- **Cabeçalho clicável:** ícone `Wrench` + nome da ferramenta formatado (`_` → espaço, camelCase separado, lowercase, primeira letra maiúscula) + `Badge variant="outline"` com texto **"Concluido"** quando `toolResult` não é `undefined`/`null`; `ChevronUp`/`ChevronDown` à direita.
- **Expandido:** duas seções com rótulos em caixa alta — **"Parametros"** (`<pre>` com `JSON.stringify(toolArgs, null, 2)`) e **"Resultado"** (`<pre className="max-h-[200px] overflow-y-auto">`; string é impressa crua, resto via `JSON.stringify`).
- **Estado inicial:** colapsado (`useState(false)`).

### 2.6 Composer

`<div className="border-t p-4">` com `flex gap-2`:

| Elemento | Especificação |
|---|---|
| `Textarea` | `placeholder="Digite sua mensagem..."`, `className="min-h-[44px] max-h-[120px] resize-none text-sm"`, `disabled={isLoading}` |
| Botão enviar | `Button size="icon" className="h-[44px] w-[44px]"`, `disabled={!input.trim() || isLoading}`; ícone `Send`, trocado por `Loader2 animate-spin` enquanto carrega |
| Atalhos | `Enter` sem Shift → `preventDefault()` + envia. `Shift+Enter` → quebra de linha. **Nenhum outro atalho** (sem Esc, sem Ctrl+Enter, sem "/" para focar) |
| Anexos | **Não existem** (sem input de arquivo, sem drag&drop, sem colar imagem) |
| Contador | **Não existe** — nem de caracteres, nem de tokens. `totalTokensUsed` do tipo `AgentSession` nunca é exibido |
| Autoresize | **Não há** autoresize programático; só as classes `min-h`/`max-h` |

**`handleSend`:** ignora string vazia/só espaços e ignora se `isLoading`; **limpa o input antes** de `await startChat(trimmed)` — **se a chamada falhar, o texto digitado se perde**.

### 2.7 Estados: enviando, streaming, erro

**"Pensando" (`ThinkingIndicator`, `AgentChatView.tsx:24-54`)** — exibido quando `thinkingStatus != null`:
- Cabeçalho imita uma mensagem: quadradinho `bg-blue-50` com `Bot animate-pulse` + label **"Maestro"**.
- Corpo: `bg-muted/30 rounded-lg px-4 py-3 ml-7 animate-pulse` com `Loader2` girando + `thinkingStatus.message`.
- Se houver `toolName`, uma segunda linha com `Wrench` e o texto **"Usando: {toolName}"**.

**Mensagens de "pensando"** — rotacionadas a cada **3000 ms** por um `setInterval` em `useAgentSession`:

| Ordem | Texto | `toolName` associado |
|---|---|---|
| 1 | "Analisando sua mensagem..." | — |
| 2 | "Processando informacoes..." | — |
| 3 | "Consultando dados..." | `analyze` |
| 4 | "Executando analise..." | `query` |
| 5 | "Gerando resposta..." | — |

Fora do ciclo: **"Enviando para o Maestro..."** (antes do fetch) e **"Finalizando resposta..."** (depois).

**Streaming: NÃO EXISTE.** A resposta chega inteira via `response.json()` de uma chamada única à Edge Function `ai-orchestrator`. Não há SSE, efeito de digitação nem render incremental.

**Erro:** bloco no fim da lista, `flex items-start gap-2 p-3 bg-destructive/10 text-destructive rounded-lg`, com ícone `AlertCircle` + `{error}` em `text-sm`. **Não é dispensável** (sem "X"), **não tem botão "tentar novamente"**; some quando `setError(null)` ocorre no próximo envio.

### 2.8 Renderizador markdown (`AgentMarkdown`)

`react-markdown` + `remark-gfm` (tabelas/GFM), wrapper `text-sm space-y-3`.

| Elemento | Classes |
|---|---|
| `h1`..`h4` | `text-lg font-bold` → `text-sm font-medium` (escala decrescente) |
| `p` | `leading-relaxed` |
| `ul`/`ol` | `list-inside`; `li` em `text-sm` |
| `a` | `target="_blank" rel="noopener noreferrer"`, `text-primary underline` |
| `code` inline | `bg-muted px-1.5 py-0.5 rounded text-xs font-mono` |
| `code` bloco | `block bg-muted p-3 rounded-md text-xs font-mono overflow-x-auto` |
| `table` | envolta em `div.overflow-x-auto`; `w-full text-xs border-collapse` |
| `thead` | `bg-muted/50` |
| `tbody` | `divide-y`; `tr` com hover `bg-muted/30` |
| `th`/`td` | `px-3 py-2 border border-border` |
| `blockquote` | `border-l-4 border-primary/30 pl-4 italic` |

- **Sem syntax highlighting real** — apesar do comentário no topo do arquivo dizer "Code blocks with syntax highlighting", nenhum highlighter é importado; só se preserva a `className` de linguagem.
- **Sem `rehype-raw`** → HTML cru no markdown não é interpretado (é a postura segura).

---

## 3. Visão de plano e de execução

### 3.1 `AgentPlanView` — proposta pendente

**Seleção:** pega **a primeira** proposta com `status === "pending"` (`proposals.find(...)`). **Não há lista ou fila visível de múltiplas propostas** — se o backend mandar duas, a segunda fica invisível até a primeira sair de `pending`.

**Estado vazio:**
- Ícone `FileText` (`h-12 w-12 text-muted-foreground/50`)
- Texto **"Nenhum plano pendente de aprovacao"**
- Botão `variant="outline"` **"Voltar ao chat"** → `setView("chat")`

**Cabeçalho** (`p-4 border-b bg-muted/50`):
- `FileText` + título **"Plano de Execucao"**
- Subtítulo **"Revise e aprove as acoes propostas"**

**Corpo (ScrollArea), na ordem:**

1. `currentPlan.title` (`font-medium mb-4`)
2. `currentPlan.description` se existir (`text-sm text-muted-foreground`)
3. **Itens / steps** — cada `executionPlan.steps[i]` vira um card `p-3 rounded-lg border` com:
   - badge numerado circular (`i+1`)
   - `step.description` em `font-medium text-sm`
   - se houver `step.entityType`, a linha **"Tipo: {entityType}"** (`text-xs text-muted-foreground`)
   > ⚠️ Só lê `entityType` (camelCase). O campo `entity_type` (snake_case), que também existe no tipo, **não é exibido**. `risk_level` e `data` por step também não aparecem.
4. **Risco** — linha com ícone `AlertTriangle`, rótulo **"Risco:"** e `Badge`:

   | `riskLevel` | Label | Variante do Badge |
   |---|---|---|
   | `low` | **"Baixo"** | `secondary` |
   | `medium` | **"Medio"** | `default` |
   | `high` | **"Alto"** | `destructive` |
   | `critical` | **"Critico"** | `destructive` |

5. **Impacto estimado** — se `executionPlan.estimated_impact` existir, bloco `p-4 rounded-lg bg-muted` com título **"Impacto Estimado"** e grid de 2 colunas: **"Contatos:"** `{estimated_impact.contacts}` e **"Titulos:"** `{estimated_impact.titles}`.

> **Não há diff.** Não existe comparação antes/depois nem preview dos registros afetados além dos dois contadores. `rollback_plan` existe no tipo e **não é exibido em lugar nenhum**.

**Barra de ações (rodapé `p-4 border-t flex gap-2`):**

| Botão | Texto exato | Ícone | Ação | Estado |
|---|---|---|---|---|
| Principal (`flex-1`) | **"Aprovar e Executar"** | `Check` | `approveAndExecute(currentPlan.id)` | `disabled={isExecuting}` |
| Secundário (`variant="outline"`) | **"Ajustar"** | `MessageSquare` | `setView("chat")` — **só troca a view; não altera a proposta** | — |
| Terciário (`variant="ghost"`) | *(sem texto)* | `X` | `rejectProposal(id)` e depois `setView("chat")` | — |

> **Achado:** o botão de rejeitar é **apenas um ícone `X`, sem rótulo, sem tooltip e sem `title`**. Não há campo de motivo — `rejectProposal` aceita um segundo parâmetro `_reason` que nunca é usado nem passado.

### 3.2 `AgentExecutionView` — execução

**Seleção da proposta corrente, por precedência:** `executing` → `completed` → `failed`.

**Estado vazio:** texto **"Nenhuma execucao em andamento"** + botão `variant="outline"` **"Voltar ao chat"**.

**Cabeçalho** — fundo condicional (`bg-green-50` se concluído, `bg-red-50` se falhou, senão `bg-primary/5`):

| Situação | Ícone | Título |
|---|---|---|
| Executando | `Loader2` girando | **"Executando..."** |
| Concluído | `CheckCircle` verde | **"Execucao Concluida"** |
| Falhou | `XCircle` vermelho | **"Execucao Falhou"** |

`<Progress value={progress} />` — `progress = round(currentStep / totalSteps * 100)` quando há `executionProgress`; senão 100 se `completed`, senão 0.

**Lista de itens** — se `executionProgress.itemResults` tiver elementos, um card por item:

| Status do item | Cor / borda | Ícone |
|---|---|---|
| `completed` | verde | `CheckCircle` |
| `executing` | azul com `ring-2` | `Loader2` girando |
| `failed` | vermelho | `XCircle` |
| `pending` | `bg-muted/50` | `Circle` |

Texto do item: **"Passo {index+1}"**. Se houver `item.error`, linha em `text-red-600`. Se houver `item.entity_id`, linha **"ID: {primeiros 8 chars}..."**.

**Fallback:** se ainda não há `itemResults`, lista os `executionPlan.steps` da proposta em cards neutros com `step.description` e ícone `Loader2`/`Circle` conforme `isExecuting`.

**Rodapé (só quando `isCompleted || isFailed`):** texto **"Plano executado com sucesso!"** ou **"Erro na execucao do plano"** (com ícone correspondente) + botão de largura total **"Continuar Conversa"** → `setView("chat")`.

### 3.3 Mapa completo dos estados de proposta

| `status` | Onde aparece | Observação |
|---|---|---|
| `pending` | `AgentPlanView` | Único estado com tela própria de decisão |
| `approved` | **Nenhuma renderização** | `approveAndExecute` pula direto de `pending` para `executing` — `approved` nunca é gravado localmente |
| `rejected` | **Nenhuma renderização** | `rejectProposal` grava `rejected` e a proposta some de ambas as views |
| `executing` | `AgentExecutionView` | — |
| `completed` | `AgentExecutionView` | — |
| `failed` | `AgentExecutionView` | A mensagem de erro do backend **não é exibida** |

**Não há badge de status de proposta em lugar nenhum da UI do painel.**

### 3.4 Os três modos — o que muda de fato

| Aspecto | Realidade no frontend |
|---|---|
| Onde se escolhe | **Exclusivamente** no `DropdownMenu` do header do painel. Não há outro ponto (nem no modal de config, nem no chat) |
| O que muda na UI | **Literalmente nada além do rótulo, da bolinha e do valor enviado ao backend** |
| Comportamento | `handleModeChange` limpa a sessão e chama `createSession(newMode)`, que manda `mode` no body da EF `ai-orchestrator` (`action: "create_session"`) |
| Ramificação por modo | **Nenhuma.** Mesmo em `full_auto`, se vier proposta o painel vai para a view `plan` e pede aprovação; mesmo em `plan` não há bloqueio adicional no cliente |
| Documentação in-app | As três frases do dropdown são a **única** explicação do que cada modo faz |

`⚠️ A confirmar:` a diferença real de comportamento é responsabilidade da Edge Function `ai-orchestrator`, fora do escopo dos arquivos de frontend lidos.

### 3.5 Execução e polling (`useAgentProposals`)

- Endpoint: EF **`ai-proposal-executor`** (ações `execute_proposal`, `cancel_proposal`, `get_proposal_status`).
- `isExecuting` (state local) desabilita "Aprovar e Executar" e controla ícones do `AgentExecutionView`.
- `executionProgress`: `{ proposalId, currentStep, totalSteps, itemResults }` → alimenta a `Progress` e a lista.
- **Polling:** `setInterval` de **1500 ms** enquanto houver proposta em `executing`; `pollExecutionStatus` atualiza status e `itemResults`; para quando o status vira `completed` ou `failed`.
- **Erros:** todos apenas `console.error` (`"Error executing proposal:"`, `"Error rejecting proposal:"`, `"Error polling status:"`).
  - Em falha de execução: `updateProposal(id, {status:"failed"})` → cabeçalho vermelho e "Erro na execucao do plano", **sem exibir a mensagem do erro**.
  - Em falha ao rejeitar: **nada acontece na UI** — o `setView("chat")` ocorre de qualquer forma e a proposta continua `pending`.
- **Não usa `setError` do contexto** — erros de proposta nunca aparecem no bloco vermelho do chat.
- O `useEffect` do intervalo tem `proposals` e `pollExecutionStatus` nas deps, então o intervalo é **recriado a cada mudança**.

---

## 4. Histórico de sessões

**Arquivo:** `src/components/agent/AgentSessionHistory.tsx` · Hook: `src/hooks/useAgentSessions.ts`

| Aspecto | Especificação |
|---|---|
| Forma | `Popover` acionado por `Button variant="ghost" size="icon"` com ícone `History`, `title="Historico de sessoes"` |
| Conteúdo | `w-80 p-0`, `align="end"` |
| Cabeçalho | **"Historico de Sessoes"** (`font-medium text-sm`) + **"Sessoes recentes do Maestro"** (`text-xs text-muted-foreground`) |
| Loading | `Loader2` girando centralizado (`py-8`) |
| Estado vazio | Ícone `MessageSquare` (`h-8 w-8 text-muted-foreground/50`) + **"Nenhuma sessao encontrada"** |
| Lista | `ScrollArea h-[300px]`; cada sessão é um `<button>` de largura total com `hover:bg-muted` |

**Campos exibidos por sessão:**

| # | Campo | Como aparece |
|---|---|---|
| 1 | Status | Ícone à esquerda: `completed` → `CheckCircle` verde; `abandoned` → `XCircle` cinza; qualquer outro (ex.: `active`) → `MessageSquare` azul |
| 2 | Título | `session.context_type \|\| "Conversa"` (fallback literal **"Conversa"**), truncado |
| 3 | Modo | `Badge variant="outline"` com o **valor cru** — aparece literalmente `plan`, `semi_auto`, `full_auto`, **sem tradução** |
| 4 | Métricas | `{total_messages} msgs` e, se `total_proposals > 0`, ` · {proposals_approved}/{total_proposals} aprovadas` |
| 5 | Data | `toLocaleDateString("pt-BR", { day:"2-digit", month:"short", hour:"2-digit", minute:"2-digit" })` → formato tipo `17 de set., 14:32` |

**Ações disponíveis:** apenas **abrir** (clique → `onSelectSession(id)` → `loadSession` e fecha o popover).
**Não há:** renomear, excluir, duplicar, favoritar, buscar ou filtrar.

**Dados:** `useAgentSessions(limit = 20)` — tabela `agent_sessions` no schema da org, ordenada por `started_at` desc, query key `["agent-sessions", currentOrg?.slug, limit]`, `staleTime: 30000`, `refetchOnWindowFocus: false`.

> **Achado:** o componente consome **apenas `data` e `isLoading`** — `isError`/`error` são ignorados. Em caso de erro de query, `sessions` fica `undefined` e a UI mostra **"Nenhuma sessao encontrada"**, indistinguível de "não há sessões".

**`SessionStatsSummary`** — exportado em `src/components/agent/index.ts` mas **sem nenhum consumidor** no painel. Seria um grid de 4 colunas com rótulos **"Sessoes"**, **"Msgs"**, **"Propostas"**, **"Aprovadas"**; retorna `null` se não houver sessões.

---

## 5. Configuração do Maestro (AgentConfigModal)

**Arquivo:** `src/components/agent/AgentConfigModal.tsx` · Hook: `src/hooks/useAgentLLMConfigs.ts`
**Forma:** `Dialog` com `DialogContent className="sm:max-w-[600px]"`
**Escopo:** configuração dos **modelos de linguagem** — não configura personas, prompts ou comportamento do agente.

| Item | Valor |
|---|---|
| Título | Ícone `Settings2` + **"Configuracoes do Maestro"** |
| Descrição | **"Configure os modelos de linguagem disponiveis para o agente"** |

### 5.1 Abas

`Tabs` com `grid grid-cols-2`:

| `value` | Rótulo |
|---|---|
| `list` | **"Configuracoes"** |
| `form` | **"Nova Config"** ou **"Editar Config"** (dinâmico: `{editingConfig ? "Editar" : "Nova"} Config`) |

Ao fechar o modal (`open === false`), um `useEffect` reseta: aba volta para `list`, `editingConfig = null`, form volta ao default, `showApiKey = false`.

### 5.2 Aba "Configuracoes" (lista)

| Estado | Anatomia |
|---|---|
| Loading | `Loader2` centralizado |
| Vazio | Ícone `Bot` (`h-12 w-12`) + **"Nenhuma configuracao de LLM encontrada"** + botão **"Adicionar Configuracao"** (ícone `Plus`) |
| Com dados | `ScrollArea h-[300px]` com os itens + botão de largura total **"Adicionar Configuracao"** |

**`ConfigListItem`:** card `p-3 rounded-lg border`. Se `is_default` → `border-primary bg-primary/5`. Se `!is_active` → `opacity-60`.

Conteúdo: avatar circular com `Bot`, `config.name`, `Badge secondary` com ícone `Star` e texto **"Padrao"** (quando default), `Badge outline` **"Inativo"** (quando inativo), e subtítulo `"{LLM_PROVIDER_LABELS[provider]} - {model_id}"`.

Ações: botão `Settings2` (editar) e botão `Trash2` vermelho (excluir).
- **O excluir fica `disabled` quando `config.is_default`.**
- Excluir dispara `window.confirm("Tem certeza que deseja remover esta configuracao?")` — **confirmação nativa do navegador, não um `AlertDialog`**.

### 5.3 Aba de formulário — todos os campos

`ScrollArea h-[350px] pr-4`. Defaults em `defaultFormData` (`AgentConfigModal.tsx:60-70`).

| # | Label exato | Tipo | Opções / faixa | Default | Validação / ajuda |
|---|---|---|---|---|---|
| 1 | **"Nome da Configuracao"** (`id="config-name"`) | `Input` texto | — | `""` | placeholder **"Ex: Claude Producao"**. Obrigatório: `handleSave` faz `if (!formData.name.trim()) return;` e o botão Salvar fica `disabled` sem nome. **Sem mensagem de erro visível** |
| 2 | **"Provedor"** | `Select` | `anthropic` → "Anthropic (Claude)"; `openai` → "OpenAI (GPT)"; `google` → "Google (Gemini)"; `azure` → "Azure OpenAI" | `anthropic` | placeholder **"Selecione o provedor"**. Trocar o provedor **reseta `model_id`** para o primeiro modelo daquele provedor |
| 3 | **"Modelo"** | `Select` | lista por provedor (tabela abaixo) | `claude-sonnet-4-20250514` | placeholder **"Selecione o modelo"** |
| 4 | **"API Key"** (`id="api-key"`) | `Input` `password`/`text` alternável | — | `""` | placeholder: **"sk-..."** ao criar, **"Deixe vazio para manter atual"** ao editar. Botão de olho (`Eye`/`EyeOff`) alterna visibilidade. **Nunca pré-preenchida ao editar** |
| 5 | **"Endpoint Azure"** (`id="api-endpoint"`) | `Input` texto | — | `""` | **Só aparece se `provider === "azure"`**. placeholder **"https://your-resource.openai.azure.com"** |
| — | *(Separator)* | | | | |
| 6 | **"Temperatura"** | `Slider` | `min=0`, `max=1`, `step=0.05` | `0.7` | valor exibido à direita com `toFixed(2)` (ex.: "0.70") |
| 7 | **"Max Tokens"** (`id="max-tokens"`) | `Input type="number"` | `min=256`, `max=128000` | `4096` | `parseInt(value) \|\| 4096` — valor inválido/vazio volta a 4096. Os `min`/`max` são **atributos HTML sem validação em JS**: digitar 1 ou 999999 não bloqueia o salvar |
| — | *(Separator)* | | | | |
| 8 | **"Ativo"** | `Switch` | on/off | `true` | ajuda: **"Configuracao disponivel para uso"** |
| 9 | **"Padrao"** | `Switch` | on/off | `false` | ajuda: **"Usar como configuracao padrao"** |

**Modelos por provedor** (`useAgentLLMConfigs.ts:86-110`):

| Provedor | Modelos (id → label) |
|---|---|
| `anthropic` | `claude-opus-4-5-20251101` → "Claude Opus 4.5"; `claude-sonnet-4-5-20250929` → "Claude Sonnet 4.5"; `claude-sonnet-4-20250514` → "Claude Sonnet 4"; `claude-haiku-4-5-20251001` → "Claude Haiku 4.5" |
| `openai` | `gpt-4-turbo` → "GPT-4 Turbo"; `gpt-4` → "GPT-4"; `gpt-4o` → "GPT-4o"; `gpt-4o-mini` → "GPT-4o Mini" |
| `google` | `gemini-2.5-pro` → "Gemini 2.5 Pro"; `gemini-2.5-flash` → "Gemini 2.5 Flash"; `gemini-2.5-flash-lite` → "Gemini 2.5 Flash Lite"; `gemini-3-pro-preview` → "Gemini 3 Pro (Preview)"; `gemini-3-flash-preview` → "Gemini 3 Flash (Preview)" |
| `azure` | `gpt-4-turbo` → "Azure GPT-4 Turbo"; `gpt-4` → "Azure GPT-4" |

### 5.4 Botões do formulário

| Botão | Especificação |
|---|---|
| **"Cancelar"** | `variant="outline"`, `flex-1` → volta para a aba `list`. **Não descarta o rascunho do form nem reseta `editingConfig`** |
| **"Salvar"** | `flex-1`, `disabled={!formData.name.trim() \|\| isSaving}`. Enquanto salva, mostra `Loader2` + texto **"Salvando..."** |

### 5.5 O que é persistido

**Tabela:** `agent_llm_configs` no schema da org (`orgClient`, multi-tenant `org_{slug}`).
**Hooks:** `useCreateLLMConfig`, `useUpdateLLMConfig`, `useDeleteLLMConfig`.

| Detalhe | Comportamento |
|---|---|
| Criptografia da chave | A API key em texto plano é **encriptada antes de persistir** via RPC `public.encrypt_llm_key` (pgcrypto AES256). Grava em `api_key_encrypted` |
| Erro de criptografia | Lança com a mensagem **"Falha ao encriptar API key. Verifique se llm_key_encryption_secret esta configurado em project_config."** |
| Campos condicionais | `api_key` só entra no payload se `formData.api_key.trim()` for não vazio; `api_endpoint_override` idem |
| Remover uma key | No update, `api_key === ""` explícito significa limpar (grava `null`) — **mas o modal nunca envia string vazia**, porque o `if (formData.api_key.trim())` a omite. **Pela UI não há como remover uma API key existente** |
| Exclusividade do default | Se `is_default = true`, o hook primeiro faz `update({is_default:false})` nas demais linhas |
| Delete | Usa `ensureDeleted(...)` de `@/lib/delete-helpers` (detecta delete que não afetou linhas) |
| Mascaramento | `api_key_masked = api_key_encrypted ? "********" : undefined` — **a string nunca é exibida**; `ConfigListItem` não mostra a key |

**Toasts disparados por este modal** (única superfície de erro com feedback visual real em todo o módulo Maestro):

| Evento | Título |
|---|---|
| Criar OK | **"Configuracao LLM criada com sucesso"** |
| Atualizar OK | **"Configuracao LLM atualizada"** |
| Remover OK | **"Configuracao LLM removida"** |
| Criar erro | **"Erro ao criar configuracao"** (`destructive`, `description` = mensagem do erro) |
| Atualizar erro | **"Erro ao atualizar configuracao"** (`destructive`) |
| Remover erro | **"Erro ao remover configuracao"** (`destructive`) |

**Hooks existentes e sem consumidor:** `useDefaultLLMConfig` (key `["agent-llm-config-default"]`, trata `PGRST116` como `null`) e `useSetDefaultLLMConfig`.

> ⚠️ **Query key sem org:** `useAgentLLMConfigs` usa `["agent-llm-configs"]` — **sem `currentOrg.slug`**. Potencial reuso de cache entre organizações ao trocar de org. `⚠️ A confirmar:` se `OrganizationContext` faz `queryClient.clear()` na troca (a sidebar chama `invalidateAllQueries()`, o que mitiga, mas não é a mesma coisa).

---

## 6. Auditoria (AgentAuditLogViewer)

**Arquivo:** `src/components/agent/AgentAuditLogViewer.tsx` · Hook: `src/hooks/useAgentAuditLogs.ts`
**Forma:** `Popover` acionado por `Button variant="ghost" size="icon"` com ícone `FileText`, `title="Audit logs"`. Conteúdo `w-96 p-0`, `align="end"`.
**Tabela:** `agent_audit_logs` (schema da org).

### 6.1 Cabeçalho e exportação

| Item | Valor |
|---|---|
| Título | **"Audit Logs"** (em inglês) |
| Subtítulo | **"Logs desta sessao"** se `sessionId` foi passado; senão **"Todos os logs"** |
| Exportar JSON | `Button ghost size="sm"` + `Download`, rótulo **"JSON"**, `title="Exportar JSON"` |
| Exportar CSV | idem, rótulo **"CSV"**, `title="Exportar CSV"` |
| Ambos | `disabled` quando não há logs. Nome do arquivo: `audit-logs-{sessionId \|\| "all"}-{Date.now()}.{json\|csv}` |
| Colunas do CSV local | `id, action, entity_type, entity_id, created_at` |

### 6.2 Linha colapsada de um log

Não é tabela — é uma lista de cards.

| Elemento | Detalhe |
|---|---|
| Ação | `Badge` colorido com o **valor cru de `log.action`** — sem tradução. Existem labels em português em `AUDIT_ACTION_LABELS` no hook, mas **o viewer não os importa** |
| Entidade | `log.entity_type` (se existir) em `text-xs text-muted-foreground` |
| Hora | `toLocaleTimeString("pt-BR")` — **só hora, sem data** (ex.: `14:32:05`) |
| Expansor | `ChevronUp`/`ChevronDown` |

**Cores por ação (`ACTION_COLORS`, linhas 22-33):**

| Ação | Cor |
|---|---|
| `session_started` | azul |
| `session_ended` | cinza |
| `message_sent` | verde |
| `message_received` | verde |
| `proposal_created` | amarelo |
| `proposal_approved` | esmeralda |
| `proposal_rejected` | vermelho |
| `proposal_executed` | roxo |
| `tool_called` | ciano |
| `error` | vermelho |
| *(fallback)* | `bg-gray-100 text-gray-700` |

### 6.3 Detalhe expandido

Clique alterna via `expandedLogs: Set<string>`. Mostra, quando presentes:

| Rótulo | Conteúdo |
|---|---|
| **"Entity ID:"** | `log.entity_id` em `<code>` |
| **"Metadata:"** | `<pre>` com JSON formatado |
| **"Estado anterior:"** | `<pre>` com `previous_state` |
| **"Novo estado:"** | `<pre>` com `new_state` |

**Campos do tipo `AuditLog` que NÃO são exibidos:** `session_id`, `proposal_id`, `user_id`, `ip_address`, `user_agent`.

### 6.4 Filtros e paginação

- **Filtros na UI: nenhum.** Não há seletor de ação, período, usuário ou entidade. O único recorte é implícito: `useAgentAuditLogs(sessionId ? { session_id: sessionId, limit: 100 } : { limit: 50 })`.
- **Paginação: nenhuma.** O hook suporta `offset`/`limit` (`query.range(...)`), mas o viewer nunca muda o offset. É uma janela fixa de 100 (com sessão) ou 50 (sem sessão), ordenada por `created_at` desc, dentro de um `ScrollArea h-[400px]`. Sem "carregar mais", sem infinite scroll.
- O hook oferece filtros por `session_id`, `proposal_id`, `user_id`, `action`, `entity_type`, `from_date`, `to_date` — **todos sem consumidor na UI**.

**Estados:** loading = `Loader2` centralizado; vazio = ícone `FileText` + **"Nenhum log encontrado"**.
> Como o componente usa só `data` e `isLoading`, **erro de query também cai no estado vazio**.

### 6.5 Utilitários de exportação órfãos

`useAgentAuditLogs.ts` exporta ainda, **sem nenhum consumidor**:

- `formatAuditLogsForExport` — CSV com cabeçalhos em português: "ID", "Data/Hora", "Acao", "Tipo de Entidade", "ID da Entidade", "ID da Sessao", "ID da Proposta", "Usuario ID", "IP" + opcionalmente "Estado Anterior", "Novo Estado", "Metadados"
- `downloadAuditLogs`
- `useExportAuditLogs` (busca até 10.000 linhas)
- `useSessionAuditLogs`, `useProposalAuditLogs`, `useRecentAuditActivity`

> ⚠️ **Query key sem org:** `useAgentAuditLogs` usa `["agent-audit-logs", filters]` — sem `currentOrg.slug`.

---

## 7. Contexto de página (usePageContext / AgentContextToggle)

### 7.1 O toggle (o que o usuário vê)

**Arquivo:** `src/components/agent/AgentContextToggle.tsx`
Linha `flex items-center justify-between w-full` dentro da faixa `bg-muted/30` do painel.

| Elemento | Especificação |
|---|---|
| Ícone | `Eye` (`text-primary`) quando ligado; `EyeOff` (`text-muted-foreground`) quando desligado |
| Label | **"Contexto da pagina"** (`<Label htmlFor="context-aware" className="text-sm cursor-pointer">`) |
| Ajuda | `HelpTip` (variante default = **popover clicável**), ícone `HelpCircle` `size-3.5`, `side="bottom"`; gatilho com `aria-label="Ajuda: Contexto da pagina"` |
| Título do HelpTip | **"Contexto da pagina"** |
| Corpo do HelpTip | **"Quando ativado, o Maestro tem acesso ao contexto da pagina atual (portfolio, campanha, filtro sendo visualizado) e pode sugerir acoes relacionadas."** |
| Controle | `Switch id="context-aware"` ligado a `contextAware` / `setContextAware` |
| Default | **Ligado (`true`)** |
| Persistência | **Nenhuma** — volta a ligado a cada reload |

### 7.2 O que `usePageContext` coletaria

**Arquivo:** `src/hooks/usePageContext.ts`

Tipo: `PageContext = { type, entityId?, entityName?, data?, path, description }`
`PageContextType` = `dashboard | portfolio | campaign | workflow | filter | template | integration | data_source | pipeline | agent_config | contact | settings | unknown`

**Padrões de rota** (`ROUTE_PATTERNS`, linhas 47-99):

| Regex | type | description |
|---|---|---|
| `^/$`, `^/dashboard$` | dashboard | "Dashboard principal" |
| `^/portfolios$` | portfolio | "Lista de carteiras" |
| `^/portfolios/([a-f0-9-]+)$` | portfolio | "Detalhes da carteira" |
| `^/campaigns$` | campaign | "Lista de campanhas" |
| `^/campaigns/([a-f0-9-]+)$` | campaign | "Detalhes da campanha" |
| `^/campaigns/new$` | campaign | "Nova campanha" |
| `^/workflows$` | workflow | "Lista de réguas" |
| `^/workflows/([a-f0-9-]+)$` | workflow | "Detalhes da régua" |
| `^/filters$` | filter | "Lista de filtros" |
| `^/filters/([a-f0-9-]+)$` | filter | "Detalhes do filtro" |
| `^/templates$` / `(id)` | template | "Lista de templates" / "Detalhes do template" |
| `^/integrations$` / `(id)` | integration | "Lista de integrações" / "Detalhes da integração" |
| `^/data-sources$` / `(id)` | data_source | "Lista de fontes de dados" / "Detalhes da fonte de dados" |
| `^/pipelines$` / `(id)` | pipeline | "Lista de pipelines" / "Detalhes do pipeline" |
| `^/agent-config$` | agent_config | "Configuração do agente de comunicação" |
| `^/contacts$` / `(id)` | contact | "Lista de contatos" / "Detalhes do contato" |
| `^/settings` | settings | "Configurações" |
| *(sem match)* | unknown | "Página desconhecida" |

**Campos que seriam buscados por tipo** — query `["page-context", type, entityId]`, `staleTime: 30000`, `enabled: !!entityId && !!orgClient`, via `orgClient`:

| type | Tabela | Colunas |
|---|---|---|
| `campaign` | `campaigns` | `id, name, description, status, producer_trigger_type, producer_cron_expression` |
| `portfolio` | `portfolios` | `id, name, description, filter_definition_id` |
| `workflow` | `workflows` | `id, name, description, workflow_steps(id, name, step_type, delay_days)` |
| `filter` | `filter_definitions` | `id, name, description, filter_config` |
| `contact` | `contacts` | `id, name, document, primary_phone, primary_email` |
| `pipeline` | `etl_pipelines` | `id, name, description, schedule_cron, is_active` |
| `data_source` | `data_sources` | `id, name, source_type, connection_config` |
| demais | — | `null` |

> ⚠️ **Nota de privacidade para o redesign:** dois desses conjuntos são sensíveis. `contact` levaria **documento, telefone e e-mail** do cliente ao LLM; `data_source.connection_config` é serializado **inteiro** e, conforme a memória do workspace, pode conter chave privada GCP em texto plano.

### 7.3 O que seria enviado ao agente

`formatPageContextForLLM(context)` monta um markdown:

```
## Contexto da Página Atual

**Página:** {description}
**Rota:** {path}
**ID da Entidade:** {entityId}        (se houver)

### Dados da Entidade:
```json
{JSON.stringify(data, null, 2)}
```
```

Em `useAgentSession.sendMessage`, se `contextAwarenessEnabled && pageContext`, a mensagem vira:
`` `${contextInfo}\n\n---\n\n**Mensagem do usuário:**\n${content}` ``
e o body da EF também recebe `page_context`.

Em `startChat`, ao criar sessão, passa ainda `context_type`, `context_entity_id` e `context_data`.

### 7.4 Achado crítico — o contexto nunca é preenchido

**`usePageContext()` não é chamado por nenhum componente ou hook do app.** A busca em todo o repositório encontra apenas: a própria definição, o import de `type PageContext` no `AgentPanelContext`, o import de `formatPageContextForLLM` no `useAgentSession`, e menções em documentação/skills. **`setPageContext` também nunca é chamado** fora do próprio contexto.

**Consequência:** `pageContext` permanece `null` para sempre. Todos os ramos `contextAwarenessEnabled && pageContext` são falsos. **Ligar ou desligar o toggle "Contexto da pagina" hoje não muda nada.** Nenhum dado da tela é coletado. O toggle, o `HelpTip` e todo o `usePageContext` estão implementados mas desconectados.

**Segundo achado correlato:** mesmo que fosse ligado, os `ROUTE_PATTERNS` **não batem com as rotas reais** de `src/App.tsx`. As rotas reais são `/portfolio` (singular), `/reguas-cobranca`, `/etl`, `/agent-ia`, `/actions`, `/disparos`; `/contacts` e `/contracts` redirecionam para `/portfolio`. As rotas `/portfolios`, `/workflows`, `/data-sources`, `/pipelines`, `/agent-config`, `/campaigns/:id` e `/filters/:id` do mapeamento **não existem** no roteador atual. Só `/`, `/campaigns`, `/filters`, `/templates`, `/integrations` e `/settings` casariam.

`⚠️ A confirmar:` se a desconexão é dívida técnica intencional (feature desligada de propósito) ou regressão.

### 7.5 Tratamento de erro do hook

`usePageContext` **não tem tratamento de erro algum**: cada ramo do `switch` faz `const { data } = await ...` e **descarta o `error`** do Supabase. Falha silenciosa → `entityData` fica `null` e o contexto vira só rota + descrição.

---

## 8. Busca global de cliente na sidebar (CustomerSearch)

**Arquivos:** `src/components/layout/CustomerSearch.tsx`, `src/hooks/useCustomerSearch.ts`, `src/lib/customer-search.ts`
**Montagem:** `Sidebar.tsx:119` — **primeiro item do `<nav>`**, acima de Dashboard.

### 8.1 Estrutura do componente

`CustomerSearch({ collapsed })` só pega `currentOrg` e renderiza `<OrganizationCustomerSearch key={currentOrg?.slug} collapsed={collapsed} />`.

> A `key` pelo slug **reseta a busca e o cliente selecionado ao trocar de organização** — comportamento deliberado, documentado em comentário.

**Estado interno:** `open` (dialog), `term` (termo efetivo), `selectedId`; `input = useDebouncedSearchInput(term, setTerm)`; `results = useCustomerSearch(term, open)`; `contact = useContactEnrichedById(selectedId)`.

### 8.2 Aparência

| Elemento | Especificação |
|---|---|
| Gatilho | `<Button variant="ghost" className="w-full justify-start gap-3" title="Buscar cliente">` com `<Search className="h-5 w-5 shrink-0" />` + label **"Buscar cliente"** |
| Colapsada | O span vira `sr-only` — só o ícone aparece |
| Modal | `<Dialog>` → `<DialogContent className="sm:max-w-xl">` |
| `DialogTitle` | **"Buscar cliente"** |
| `DialogDescription` | **"Nome, documento, telefone, contrato ou e-mail. Busca na organização atual."** |
| Input | `<Input autoFocus aria-label="Buscar cliente" maxLength={200} placeholder={CUSTOMER_SEARCH_PLACEHOLDER} />` |
| Placeholder | **"Nome, documento, telefone, contrato ou e-mail"** (constante `CUSTOMER_SEARCH_PLACEHOLDER` em `src/lib/customer-search.ts:3`) |
| Lista | `<div className="max-h-80 overflow-y-auto space-y-1" aria-live="polite">` |

### 8.3 Comportamento de entrada

| Aspecto | Valor |
|---|---|
| Debounce | **400 ms** (`useDebouncedSearchInput`, default `delay = 400`; o componente não passa outro) |
| Mínimo de caracteres | **2** sobre `term.trim()` — afirmado em três lugares: na UI, no `enabled` do hook e na função de lib |
| `Enter` | Chama `input.submit()` — **cancela o debounce e busca na hora** |
| Outros atalhos | **Nenhum.** Não existe Cmd+K / Ctrl+K nem qualquer listener global para abrir a busca (a busca global do repositório por `metaKey\|ctrlKey` retorna um único hit, e é no `useDirtyFormGuard`) |
| Limpeza externa | Cancela o timer pendente |

### 8.4 O que busca e o que devolve

`searchCustomers(orgSlug, term, limit = 20)` chama a RPC pública **`search_customers`** com `{ p_schema_name: "org_" + orgSlug, p_term: term.trim(), p_limit: limit }`.

Formato do resultado:

```ts
interface CustomerSearchResult {
  id: string;
  name: string;
  document: string | null;
  primary_phone: string | null;
  primary_email: string | null;
}
```

Erro vira `throw new Error("Não foi possível buscar clientes: " + error.message)`.

**Campos efetivamente pesquisados no banco** (não declarados no frontend; vêm da regra 46 do `CLAUDE.md` do projeto): nome, razão social, documento e telefone normalizados, e-mail e número de contrato. `⚠️ A confirmar` no SQL — o front não declara isso.

**Hook:**
```ts
useQuery({
  queryKey: ["customer-search", currentOrg?.slug, term.trim()],
  queryFn: () => searchCustomers(currentOrg!.slug, term),
  enabled: enabled && !!currentOrg && term.trim().length >= 2,
  staleTime: 30_000,
})
```
`enabled` recebe `open` → **não busca com o modal fechado**.

### 8.5 Estados da UI (cascata literal, nessa ordem)

| # | Condição | Renderização |
|---|---|---|
| 1 | `term.trim().length < 2` | **"Digite pelo menos 2 caracteres."** (`text-sm text-muted-foreground`) |
| 2 | `results.isFetching` | **"Buscando…"** (com reticências unicode) |
| 3 | `results.error` | `<p role="alert" className="text-destructive">{results.error.message}</p>` |
| 4 | `!results.data?.length` | **"Nenhum cliente encontrado."** |
| 5 | com resultados | Botões: `<div className="font-medium">{row.name}</div>` + subtítulo `text-sm text-muted-foreground break-all` = `[document, primary_phone, primary_email].filter(Boolean).join(" · ")`. Item: `w-full rounded-md p-3 text-left hover:bg-muted focus-visible:ring-2 focus-visible:ring-ring` |
| 6 | `results.data?.length === 20` | Rodapé: **"Exibindo os primeiros 20 clientes. Refine a busca para encontrar outros."** (`text-xs text-muted-foreground`) |
| 7 | `contact.isFetching` | **"Carregando cliente…"** |
| 8 | `contact.error` | `<p role="alert" className="text-destructive">{contact.error.message}</p>` |

### 8.6 O que acontece ao clicar num resultado

**Não navega por rota.** O clique faz `setSelectedId(row.id)`, o que dispara `useContactEnrichedById(selectedId)` e abre:

```tsx
<PortfolioDetailSheet
  contact={contact.data ?? null}
  open={!!selectedId && !!contact.data}
  onClose={() => setSelectedId(null)}
/>
```

`PortfolioDetailSheet` é re-export de `src/components/portfolio/detail/ContactDetailSheet.tsx` — **apesar do nome, é um `Dialog`, não um `Sheet`**: `<DialogContent className="w-screen h-screen sm:w-[95vw] sm:h-[95vh] max-w-none max-h-none p-0 flex flex-col rounded-none sm:rounded-lg">`, ou seja, quase tela cheia.

> **Achado:** o `Dialog` de busca **não é fechado** ao selecionar (o código não chama `setOpen(false)`). O detalhe do cliente abre **por cima** do modal de busca — dois diálogos empilhados.

---

## 9. Catálogo de estados de carregamento (loading-states.tsx)

**Arquivo:** `src/components/ui/loading-states.tsx` (625 linhas) · 15 componentes exportados, nenhum `export default`.

### 9.1 Fato base — não existe shimmer

`src/components/ui/skeleton.tsx` é:

```tsx
<div className={cn("animate-pulse rounded-md bg-muted", className)} />
```

**Todo** bloco de skeleton do projeto é `animate-pulse` + `rounded-md` + `bg-muted`. **Não há keyframe de shimmer ou gradiente animado em lugar nenhum.**

### 9.2 Tabela-resumo

| # | Componente | Props (default) | Blocos renderizados | Usos reais |
|---|---|---|---|---|
| 1 | `CardSkeleton` | `className?`, `showIcon = true` | 3-4 | Só interno (por `KPIGridSkeleton`) |
| 2 | `KPIGridSkeleton` | `count = 4`, `className?` | `count` × card | **Nenhum** |
| 3 | `ChartSkeleton` | `height = 250`, `className?` | 6 barras + 6 rótulos | 4 arquivos de dashboard |
| 4 | `TableSkeleton` | `rows = 5`, `columns = 4`, `showHeader = true` | 1 header + `rows` linhas | **Nenhum** |
| 5 | `ListSkeleton` | `items = 5`, `showAvatar = true` | `items` linhas | **Nenhum** |
| 6 | `GridCardSkeleton` | `count = 6`, `columns = 3`, `className?` | `count` cards | 2 abas de ETL |
| 7 | `PageHeaderSkeleton` | `showDescription = true` | 1-2 | **Nenhum** |
| 8 | `FullPageLoading` | `message = "Carregando..."` | spinner (não é skeleton) | `DashboardPage` |
| 9 | `FormSkeleton` | `fields = 4` | `fields` grupos + 2 botões | **Nenhum** |
| 10 | `EmptyState` | `icon?`, **`title` (obrigatória)**, `description?`, `action?` | — | 6 arquivos |
| 11 | `ErrorState` | `title?`, `description?`, `onRetry?` | — | 3 arquivos de Disparos |
| 12 | `FiltersPageSkeleton` | `viewMode = "grid"`, `count = 6` | varia | `FiltersPage` |
| 13 | `CampaignsPageSkeleton` | `viewMode = "grid"`, `count = 6` | varia | `CampaignsPage` |
| 14 | `ReguasPageSkeleton` | `viewMode = "grid"`, `count = 6` | varia | `ReguasCobrancaPage` |
| 15 | `PortfolioGridSkeleton` | `rows = 10` | 1 header + `rows` linhas | `DisparoTargetList` |

### 9.3 Detalhamento de cada componente

#### `CardSkeleton`
- **Quando usar:** card de KPI do dashboard.
- **Anatomia:** `<Card>`; `CardHeader` com `flex flex-row items-center justify-between space-y-0 pb-2` contendo `Skeleton h-4 w-24` (título) e, se `showIcon`, `Skeleton h-4 w-4 rounded` (ícone); `CardContent` com `Skeleton h-8 w-32 mb-2` (valor) + `Skeleton h-3 w-20` (legenda).

#### `KPIGridSkeleton`
- **Quando usar:** linha de KPIs do dashboard.
- **Anatomia:** `grid gap-4 md:grid-cols-2 lg:grid-cols-4` com `count` × `<CardSkeleton />`.
- **Status:** sem import externo encontrado.

#### `ChartSkeleton`
- **Quando usar:** containers de gráfico (Recharts).
- **Anatomia:** `flex items-end justify-between gap-2 px-4` com `style={{ height }}` em px. **6 colunas fixas**; cada uma com barra `Skeleton w-full` de altura **aleatória** `${30 + Math.random()*60}%` (30%–90%) e rótulo `Skeleton h-3 w-8`.
- ⚠️ As alturas são re-sorteadas a cada render.
- **Usos:** `dashboard/tabs/ExecutiveTab.tsx:36`, `dashboard/charts/ActionsTimelineChart.tsx:14`, `dashboard/charts/StepEvolutionChart.tsx:16`, `dashboard/charts/StepDynamicTable.tsx:36`.

#### `TableSkeleton`
- **Quando usar:** tabela de dados.
- **Anatomia:** wrapper `space-y-3`; se `showHeader`, linha `flex gap-4 pb-2 border-b` com `columns` × `Skeleton h-4 flex-1`; depois `rows` linhas `flex gap-4 py-2` com `columns` skeletons `h-4` — a **primeira coluna `w-1/4`**, as demais `flex-1`.

#### `ListSkeleton`
- **Quando usar:** listas de atividade.
- **Anatomia:** `space-y-4`; cada item `flex items-start gap-3`: avatar opcional `Skeleton h-10 w-10 rounded-full`, bloco `flex-1 space-y-2` (`h-4 w-3/4` + `h-3 w-1/2`), e `h-3 w-16` à direita (timestamp).

#### `GridCardSkeleton`
- **Quando usar:** grids de card (comentário literal no arquivo: "for card grids (ETL, etc)").
- **Mapa de colunas:** `2 → "md:grid-cols-2"`; `3 → "md:grid-cols-2 lg:grid-cols-3"`; `4 → "md:grid-cols-2 lg:grid-cols-4"`.
- **Anatomia do card:** `CardHeader pb-2` com bloco esquerdo (`Skeleton h-10 w-10 rounded-lg` + `h-5 w-24` + `h-3 w-16`) e botão direito `h-8 w-8 rounded`; `CardContent` com `h-4 w-full mb-2` + `h-3 w-1/2`.
- **Usos:** `etl/tabs/DataSourcesTab.tsx:42`, `etl/tabs/PipelinesTab.tsx:37` (ambos junto com `EmptyState`).

#### `PageHeaderSkeleton`
- **Anatomia:** `space-y-2` com `Skeleton h-8 w-48` (título) e, opcional, `h-4 w-72` (descrição).

#### `FullPageLoading`
- **Não é skeleton — é spinner.**
- **Anatomia:** `flex h-[50vh] flex-col items-center justify-center gap-4` com `role="status" aria-live="polite" aria-busy="true"`; spinner `animate-spin rounded-full h-10 w-10 border-b-2 border-primary` (`aria-hidden`); `<p className="text-sm text-muted-foreground">{message}</p>`; texto `sr-only` **"Carregando conteudo, por favor aguarde."** (sem acento no código).
- **Uso:** `pages/DashboardPage.tsx:8`.

#### `FormSkeleton`
- **Quando usar:** formulários e diálogos.
- **Anatomia:** `space-y-4`; `fields` grupos `space-y-2` com label `Skeleton h-4 w-24` + input `Skeleton h-10 w-full`; rodapé `flex justify-end gap-2 pt-4` com **2 botões** `Skeleton h-10 w-24`.

#### `EmptyState`
- **Props:** `icon?: React.ComponentType<{className?: string}>`, **`title: string` (obrigatória)**, `description?`, `action?: ReactNode`, `className?`.
- **Anatomia:** `flex flex-col items-center justify-center py-12 text-center`, `role="status" aria-live="polite"`; ícone `h-12 w-12 text-muted-foreground/50 mb-4` (`aria-hidden`); `<h3 className="text-lg font-medium">{title}</h3>`; descrição `<p className="text-muted-foreground mt-1 max-w-sm">`; ação em `<div className="mt-4">`.
- **Usos:** `DashboardPage`, `etl/tabs/DataSourcesTab`, `etl/tabs/PipelinesTab`, `disparos/DisparoTargetList`, `disparos/DisparoResultsTable`, `disparos/DisparoHistoryTab`.

#### `ErrorState`
- **Props e defaults:** `title = "Erro ao carregar dados"`, `description = "Ocorreu um erro ao carregar os dados. Tente novamente."`, `onRetry?`, `className?`.
- **Anatomia:** `flex flex-col items-center justify-center py-12 text-center`, `role="alert" aria-live="assertive"`; círculo `rounded-full bg-destructive/10 p-3 mb-4` com **SVG inline** de triângulo de alerta `h-6 w-6 text-destructive`; `<h3 className="text-lg font-medium">`; `<p className="text-muted-foreground mt-1 max-w-sm">`; se `onRetry`, **botão nativo** `mt-4 inline-flex items-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90` com SVG de refresh e o texto **"Tentar novamente"**.
- **Usos:** `disparos/DisparoTargetList`, `disparos/DisparoResultsTable`, `disparos/DisparoHistoryTab`.

#### `FiltersPageSkeleton`
- **`viewMode === "list"`:** wrapper `rounded-md border`; cabeçalho `flex gap-4 p-4` com **8 skeletons `h-4`** de larguras `w-8, w-12, w-24, w-16, w-16, w-16, w-20, w-20`; depois `count` linhas `flex items-center gap-4 p-4 border-b last:border-b-0` com `h-4 w-4 rounded`, `h-4 w-4 rounded-full`, bloco `flex-1 space-y-1` (`h-4 w-32` + `h-3 w-48`), `h-4 w-12` ×3, `h-4 w-20`, `h-4 w-24`, `h-8 w-8 rounded`.
- **Outros `viewMode` (incl. `"card"`):** `grid gap-4 md:grid-cols-2 lg:grid-cols-3` com `count` cards (header `h-4 w-4 rounded-full` + `h-5 w-32` + botão `h-8 w-8 rounded` + `h-3 w-full mt-2`; content com 2 pares ícone/texto em `grid-cols-2` e mais 1 par).
- **Uso:** `pages/FiltersPage.tsx:94`.

#### `CampaignsPageSkeleton`
- **`"list"`:** `rounded-md border`; header com 5 skeletons `h-4` (`w-16, w-24, w-16, w-16, w-8`); `count` linhas com badge `h-6 w-20 rounded-full`, bloco `flex-1` (`h-4 w-40` + `h-3 w-56`), `h-5 w-16 rounded-full`, `h-5 w-20 rounded-full`, `h-8 w-8 rounded`.
- **Grid:** `md:grid-cols-2 lg:grid-cols-3`, cards com header (`h-5 w-20 rounded-full` + `h-5 w-36`, botão `h-8 w-8 rounded`, `h-3 w-full mt-2`) e content (2 pills + par ícone `h-4 w-4` e `h-4 w-32`).
- **Uso:** `pages/CampaignsPage.tsx:90`.

#### `ReguasPageSkeleton`
- **`"list"`:** header com 6 skeletons `h-4` (`w-16, w-24, w-16, w-16, w-16, w-8`); linhas com `h-5 w-20 rounded-full`, bloco `flex-1` (`h-4 w-36` + `h-3 w-48`), `h-4 w-16` ×2, **switch** `h-6 w-10 rounded-full`, `h-8 w-8 rounded`.
- **Grid:** `md:grid-cols-2 lg:grid-cols-3`; card com header (`h-5 w-20 rounded-full` + `h-5 w-32`, switch `h-6 w-10 rounded-full`, `h-3 w-full mt-2`) e content (2 pares ícone/texto + 2 pills).
- **Uso:** `pages/ReguasCobrancaPage.tsx:26`.

#### `PortfolioGridSkeleton`
- **Anatomia:** wrapper `w-full`; cabeçalho `flex items-center gap-4 p-3 border-b bg-muted/50` com 8 skeletons `h-4` (`w-4 rounded`, `w-32`, `w-28`, `w-24`, `w-20`, `w-24`, `w-20`, `w-16`); `rows` linhas `flex items-center gap-4 p-3 border-b` com `h-4 w-4 rounded`, `h-4 w-36`, `h-4 w-28`, `h-4 w-24`, `h-4 w-20`, `h-4 w-24`, badge `h-5 w-16 rounded-full`, botão `h-8 w-8 rounded`.
- **Uso:** `components/disparos/DisparoTargetList.tsx:36`.

### 9.4 Componentes fora deste arquivo que parecem pertencer a ele

`SectionEmptyState` e `SectionErrorState`, usados em toda a área de IA, **não** são de `loading-states.tsx` — vêm de `src/components/ia/MetricSectionBoundary.tsx` (linhas 42 e 115).

**Consumidores:** `AgentMetrics.tsx`, `FunnelMetricsSection.tsx`, `AgentCallsOverviewSection.tsx`, `AgentCallsMetricsSection.tsx`, `TransferOverviewSection.tsx`, `TransferMetricsSection.tsx`, `ia/charts/chart-primitives.tsx`.

> Para o redesign: existem **dois sistemas paralelos** de estado vazio/erro no app. Unificá-los é uma oportunidade — mas eles têm semânticas diferentes (o da IA carrega o conceito de "lacuna canônica" das métricas), então a fusão não é mecânica.

### 9.5 Outros indicadores de carregamento espalhados

| Indicador | Onde | Anatomia |
|---|---|---|
| `PageLoader` | `App.tsx:83` — fallback de `Suspense` de rota | `flex h-screen items-center justify-center` + spinner `h-8 w-8 border-b-2 border-primary` |
| Spinner do `RequireOrg` | `App.tsx:148-152` | `flex h-screen items-center justify-center` + `animate-spin rounded-full h-8 w-8 border-b-2 border-primary` |
| `Loader2 animate-spin` | Painel Maestro (chat, plano, execução, histórico, audit, config) | Ícone lucide, tamanhos variados |
| Skeletons do `ChangelogPeoplePopover` | Central de Docs | 4 linhas de `Skeleton` |

---

## 10. Sistema de notificação (toasts)

**Arquivos:** `src/components/ui/toast.tsx`, `src/components/ui/toaster.tsx`, `src/hooks/useToast.ts`
**Base:** `@radix-ui/react-toast` + `class-variance-authority`
**Montagem:** `<Toaster />` em `src/App.tsx:453` — único, fora do `BrowserRouter`.

> **Não existe** `src/components/ui/use-toast.ts` — o hook está só em `src/hooks/useToast.ts`. **Não há sonner** no projeto.

### 10.1 Variantes

`toastVariants` (cva), `defaultVariants: { variant: "default" }`:

| Variante | Classes literais |
|---|---|
| `default` | `border bg-background text-foreground` |
| `destructive` | `destructive group border-destructive bg-destructive text-destructive-foreground` |
| `success` | `border-green-600 bg-green-50 text-green-900 dark:bg-green-900 dark:text-green-50` |

> **Achado:** a variante `success` **existe mas não é usada em nenhum `toast(...)` do app**. A busca por `variant: "success"` retorna só um teste de outro componente (`actions/__tests__/StatsCard.spec.tsx:30`). Na prática o app usa apenas `default` (omitido) e `destructive`.

### 10.2 Duração e limite

| Constante | Valor | Significado real |
|---|---|---|
| `TOAST_LIMIT` | `1` | **Um toast por vez.** No reducer: `toasts: [action.toast, ...state.toasts].slice(0, TOAST_LIMIT)` — um toast novo **empurra o anterior para fora da lista imediatamente** |
| `TOAST_REMOVE_DELAY` | `3000` ms | Tempo entre o **dismiss** e a remoção do toast do estado (`addToRemoveQueue` → `REMOVE_TOAST`). **Não é o tempo de auto-fechamento** |

**Auto-fechamento:** nenhum `duration` é passado — nem no `ToastProvider` (`toaster.tsx` usa `<ToastProvider>` sem props), nem em nenhuma das 348 chamadas `toast({...})`. Vale o default do Radix.
`⚠️ A confirmar:` o valor efetivo não está escrito em nenhum lugar do repositório.

### 10.3 Posição na tela

`ToastViewport`:
```
fixed top-0 z-[100] flex max-h-screen w-full flex-col-reverse p-4
sm:bottom-0 sm:right-0 sm:top-auto sm:flex-col md:max-w-[420px]
```

| Breakpoint | Posição |
|---|---|
| `< sm` | **Topo**, largura total, empilhamento `flex-col-reverse` |
| `>= sm` | **Canto inferior direito**, `flex-col` |
| `>= md` | Largura máxima `420px` |

`z-index`: 100 (acima do painel do Maestro em `z-40` e da sidebar mobile em `z-50`).

### 10.4 Anatomia

**Root (`Toast`):** `group pointer-events-auto relative flex w-full items-center justify-between space-x-4 overflow-hidden rounded-md border p-6 pr-8 shadow-lg transition-all` + animações de swipe/estado (`data-[state=open]:slide-in-from-top-full`, `data-[state=open]:sm:slide-in-from-bottom-full`, `data-[state=closed]:fade-out-80`, `data-[state=closed]:slide-out-to-right-full`).

**Composição (`toaster.tsx`):**
```tsx
<Toast key={id} {...props}>
  <div className="grid gap-1">
    {title && <ToastTitle>{title}</ToastTitle>}
    {description && <ToastDescription>{description}</ToastDescription>}
  </div>
  {action}
  <ToastClose />
</Toast>
```

| Parte | Classes |
|---|---|
| `ToastTitle` | `text-sm font-semibold` |
| `ToastDescription` | `text-sm opacity-90` |
| `ToastAction` | `inline-flex h-8 shrink-0 items-center justify-center rounded-md border bg-transparent px-3 text-sm font-medium ...` com variações `group-[.destructive]:*` |
| `ToastClose` | `absolute right-2 top-2 rounded-md p-1 text-foreground/50 opacity-0 ... group-hover:opacity-100`, ícone `<X className="h-4 w-4" />`, atributo `toast-close=""` |

> **Achado de acessibilidade:** o botão de fechar tem `opacity-0` por padrão e **só aparece no hover/focus**. Em toque, é invisível até o usuário tocar.

### 10.5 API

```ts
type ToasterToast = ToastProps & {
  id: string;
  title?: ReactNode;
  description?: ReactNode;
  action?: ToastActionElement;
};
type Toast = Omit<ToasterToast, "id">;

function toast(props: Toast): {
  id: string;
  dismiss: () => void;
  update: (props: ToasterToast) => void;
};

function useToast(): {
  toasts: ToasterToast[];
  toast: typeof toast;
  dismiss: (toastId?: string) => void;
};

export { useToast, toast }   // `toast` também é exportado standalone
```

Store é um **singleton em memória** (`memoryState` + `listeners` + `dispatch`), fora do React, com ações `ADD_TOAST | UPDATE_TOAST | DISMISS_TOAST | REMOVE_TOAST`. `dismiss()` sem id derruba todos.

**Volume de uso:** `toast({` aparece **348 vezes em 91 arquivos** de `src/`.

### 10.6 Amostra real de mensagens (50 exemplos verbatim)

| # | Título | Descrição | Variante | Arquivo |
|---|---|---|---|---|
| 1 | Convite aceito com sucesso! | Você já pode acessar a organização. | — | `AcceptInvitePage.tsx:210` |
| 2 | Erro ao aceitar convite | `err.message` ou "Tente novamente" | destructive | `AcceptInvitePage.tsx:235` |
| 3 | Erro | Informe sua senha. | destructive | `AcceptInvitePage.tsx:251` |
| 4 | Erro | As senhas não coincidem | destructive | `AcceptInvitePage.tsx:300` |
| 5 | Erro | A senha deve ter pelo menos 6 caracteres | destructive | `AcceptInvitePage.tsx:309` |
| 6 | Conta já existe | Esse e-mail já tem conta na Torre. Entre com sua senha para aceitar o convite. | — | `AcceptInvitePage.tsx:345` |
| 7 | Erro ao criar conta | `err.message` ou "Tente novamente" | destructive | `AcceptInvitePage.tsx:394` |
| 8 | Erro ao sair | `err.message` ou "Tente novamente" | destructive | `AcceptInvitePage.tsx:414` |
| 9 | Execução iniciada | A campanha "{name}" foi disparada manualmente. | — | `CampaignsPage.tsx:172` |
| 10 | Erro | Não foi possível executar a campanha. | destructive | `CampaignsPage.tsx:177` |
| 11 | Não é possível ativar o broadcast | Existem ações sem configuração completa. Configure todas as ações antes de ativar. | destructive | `BroadcastEditorPage.tsx:113` |
| 12 | Não é possível ativar o broadcast | Adicione pelo menos uma ação ao broadcast. | destructive | `BroadcastEditorPage.tsx:123` |
| 13 | Erro | Não foi possível alterar o status da ação. | destructive | `BroadcastEditorPage.tsx:152` |
| 14 | Erro | Não foi possível reordenar as ações. | destructive | `BroadcastEditorPage.tsx:179` |
| 15 | Erro | Não foi possível salvar as configurações. | destructive | `BroadcastEditorPage.tsx:207` |
| 16 | Erro | Não foi possível excluir a ação. | destructive | `BroadcastEditorPage.tsx:221` |
| 17 | Tipo já adicionado | Você já tem uma ação do tipo "{name}". Em broadcasts, cada canal só pode ser usado uma vez. | destructive | `BroadcastEditorPage.tsx:235` |
| 18 | Ação criada | Configure a ação para ativá-la. | — | `BroadcastEditorPage.tsx:252` |
| 19 | Atribuição recalculada | `{processed}` títulos: `{tower}` torre, `{manual}` manual, `{organic}` orgânico | — | `AttributionTab.tsx:67` |
| 20 | Erro ao recalcular | `String(error)` | destructive | `AttributionTab.tsx:73` |
| 21 | Exportação concluída | O arquivo Excel foi baixado com sucesso. | — | `ExportButton.tsx:78` |
| 22 | Erro na exportação | Não foi possível gerar o arquivo Excel. | destructive | `ExportButton.tsx:84` |
| 23 | Sucesso | Integração atualizada com sucesso / (criada) | — | `IntegrationsPage.tsx:120` |
| 24 | Erro | `error.message` ou "Erro ao salvar integração" | destructive | `IntegrationsPage.tsx:129` |
| 25 | Erro | Não foi possível alterar o status da integração | destructive | `IntegrationsPage.tsx:282` |
| 26 | Sucesso | Integração removida com sucesso | — | `IntegrationsPage.tsx:294` |
| 27 | Erro | Não foi possível remover a integração | destructive | `IntegrationsPage.tsx:299` |
| 28 | Não é possível ativar a régua | Existem ações sem configuração completa. Configure todas as ações antes de ativar. | destructive | `ReguasCobrancaEditorPage.tsx:208` |
| 29 | Erro | Não foi possível alterar o status da régua. | destructive | `ReguasCobrancaEditorPage.tsx:225` |
| 30 | Erro | Não foi possível excluir o passo. | destructive | `ReguasCobrancaEditorPage.tsx:324` |
| 31 | Erro | Não foi possível duplicar o passo. | destructive | `ReguasCobrancaEditorPage.tsx:357` |
| 32 | Passo criado | O passo já está ativo nesta régua. (condicional) | — | `ReguasCobrancaEditorPage.tsx:400` |
| 33 | Faixa atualizada | A faixa e a cadência foram atualizadas para todas as ações do grupo. | — | `ReguasCobrancaEditorPage.tsx:431` |
| 34 | Erro | Não foi possível atualizar a faixa do grupo. | destructive | `ReguasCobrancaEditorPage.tsx:436` |
| 35 | Erro ao preparar a pré-visualização | `getErrorMessage(error)` | — | `DisparosPage.tsx:242` |
| 36 | Falha no disparo — lote parcial revertido | Algumas ações podem ter sido criadas e foram apagadas automaticamente (lote {shortId}). Pode tentar disparar novamente. Detalhe: {getErrorMessage(error)} | — | `DisparosPage.tsx:271` |
| 37 | Erro ao criar o lote de disparo | `getErrorMessage(error)` | — | `DisparosPage.tsx:278` |
| 38 | Filtros excluídos | `{n}` filtro(s) excluído(s) com sucesso. | — | `FiltersPage.tsx:393` |
| 39 | Selo removido | "{seal.name}" removido do contato. | — | `PortfolioManagementPage.tsx:190` |
| 40 | Selo aplicado | "{seal.name}" aplicado ao contato. | — | `PortfolioManagementPage.tsx:199` |
| 41 | Nenhum dado para exportar | *(sem descrição)* | destructive | `PortfolioManagementPage.tsx:579` |
| 42 | Exportação concluída | `{n}` contatos exportados. | — | `PortfolioManagementPage.tsx:585` |
| 43 | Exportação concluída | O arquivo foi baixado com sucesso. | — | `PortfolioManagementPage.tsx:597` |
| 44 | Erro na exportação | Não foi possível exportar os dados. | destructive | `PortfolioManagementPage.tsx:603` |
| 45 | Erro ao alterar o agendamento | `error.message` ou "Tente novamente." | destructive | `ETLPage.tsx:213` |
| 46 | Organização protegida | '{slug}' é protegida e não pode ser deletada pela UI. Use soft-delete via banco se necessário. | destructive | `SelectOrganizationPage.tsx:163` |
| 47 | Permissão insuficiente | Apenas super admins podem deletar organizações. | destructive | `SelectOrganizationPage.tsx:173` |
| 48 | Organização excluída | {name} foi excluída com sucesso. O schema permanece no banco para recuperação manual se necessário. | — | `SelectOrganizationPage.tsx:247` |
| 49 | Erro ao excluir organização | `error.message` ou "Tente novamente" | destructive | `SelectOrganizationPage.tsx:261` |
| 50 | Campos obrigatórios | Preencha nome e slug. | `⚠️ A confirmar` | `SelectOrganizationPage.tsx:282` |

### 10.7 Padrões de copy observados

| Padrão | Exemplos |
|---|---|
| Título genérico curto | "Erro", "Sucesso" |
| Título como frase de ação concluída | "Exportação concluída", "Filtros excluídos", "Selo aplicado", "Faixa atualizada" |
| Título como bloqueio | "Não é possível ativar o broadcast", "Tipo já adicionado", "Organização protegida", "Permissão insuficiente", "Campos obrigatórios" |
| Descrição na voz do sistema | "Não foi possível …" (dominante nos erros) |
| Interpolação de dados | `{n}`, `{name}`, `{slug}`, `{shortId}` |
| Erro técnico vazando | Vários usam `err.message` cru como descrição |

**Regra de variante observada:** erro quase sempre `destructive`; sucesso sem variante (= `default`). **Exceções reais:** os toasts 35, 36 e 37 de `DisparosPage` são erros **sem** `destructive`.

---

## 11. Tratamento de erro

### 11.1 `ErrorBoundary`

**Arquivo:** `src/components/ErrorBoundary.tsx` · Classe React, exportada nomeada **e** default.
**Montagem:** `src/App.tsx:443` — wrapper mais externo de todo o app, acima de `QueryClientProvider`, `TooltipProvider`, `BrowserRouter`, `AuthProvider`, `OrganizationProvider` e do `<Toaster />`. **Não há outra montagem.**

| Aspecto | Comportamento |
|---|---|
| Props | `children: ReactNode`, `fallback?: ReactNode` |
| State | `{ hasError: boolean; error: Error \| null }` |
| **Captura** | Erros de render/lifecycle de qualquer componente na subárvore (via `static getDerivedStateFromError`) |
| **Não captura** | Erros em event handlers, código assíncrono, promises rejeitadas, SSR — limitação padrão do React; o arquivo não faz nada a mais |
| Logging | **Só em produção** (`if (import.meta.env.PROD)`), com `console.error('Error caught by boundary:', error, errorInfo)`. Há um `// TODO: Send to error tracking service (e.g., Sentry)` — **não há integração com serviço de monitoramento**. Em DEV, `componentDidCatch` não loga nada |

**UI de fallback** (quando `props.fallback` não é passado): tela cheia `flex min-h-screen items-center justify-center bg-background p-4`, container `w-full max-w-md text-center`:

| Elemento | Conteúdo |
|---|---|
| Ícone | Círculo `h-16 w-16 rounded-full bg-destructive/10` com `<AlertTriangle className="h-8 w-8 text-destructive" />` |
| Título | **"Algo deu errado"** (`text-2xl font-semibold`) |
| Corpo | **"Ocorreu um erro inesperado. Nossa equipe foi notificada e estamos trabalhando para resolver o problema."** |
| Botão 1 | `Button variant="outline"` **"Tentar novamente"** → `handleReset`, que apenas faz `setState({hasError:false, error:null})` |
| Botão 2 | `Button` com ícone `RefreshCw` **"Recarregar pagina"** (sem acento no código) → `window.location.reload()` |
| Só em DEV | `<details>` com `<summary>` **"Detalhes do erro (desenvolvimento)"** e `<pre>` com `error.message` + `\n\n` + `error.stack` |

> **Achado crítico de honestidade de copy:** o texto afirma **"Nossa equipe foi notificada"**, mas não existe envio para nenhum serviço — em produção o erro só vai para o `console.error` do navegador do usuário.

### 11.2 `error-handler.ts` — como um erro vira mensagem

**Arquivo:** `src/lib/error-handler.ts`
**Exports:** `ErrorSeverity`, `ErrorContext`, `logError`, `createErrorHandler`, `isError`, `getErrorMessage`, `withErrorHandler`, `safeJsonParse`.

```ts
type ErrorSeverity = "low" | "medium" | "high" | "critical";
interface ErrorContext {
  source?: string; action?: string;
  metadata?: Record<string, unknown>; severity?: ErrorSeverity;
}
```

- **`logError(error, context?)`** — monta `{ message, stack, timestamp: ISO, ...context }`. Em **DEV** faz `console.error(prefix, errorMessage, logPayload)` com `prefix = context?.source ? "[" + source + "]" : "[Error]"`. Em **PROD não faz nada** (só comentários `// TODO: Integrate with Sentry, LogRocket, or similar service`). **Em produção o erro é silenciosamente descartado.**
- **`createErrorHandler(context)`** → retorna `(error) => logError(error, context)`.
- **`withErrorHandler(fn, context)`** → wrapper async que loga e retorna `undefined` no catch.
- **`safeJsonParse<T>(json, fallback)`** → `JSON.parse` em try/catch.

**`getErrorMessage(error, fallback = "Ocorreu um erro inesperado. Tente novamente.")`** — este é o único mapeamento erro→texto do app. Ordem literal de teste, só para `error instanceof Error`, por `includes` na `message`:

| Condição (substring na `error.message`) | Texto devolvido |
|---|---|
| contém `"JWT"` | **"Sua sessao expirou. Por favor, faca login novamente."** |
| contém `"network"` **ou** `"fetch"` | **"Erro de conexao. Verifique sua internet e tente novamente."** |
| contém `"duplicate"` **ou** `"unique"` | **"Este registro ja existe. Verifique os dados e tente novamente."** |
| contém `"permission"` **ou** `"403"` | **"Voce nao tem permissao para realizar esta acao."** |
| contém `"not found"` **ou** `"404"` | **"O recurso solicitado nao foi encontrado."** |
| nenhum casou | `error.message` **crua** — mensagem técnica vaza para o usuário |
| `typeof error === "string"` | a própria string |
| qualquer outro tipo | `fallback` = **"Ocorreu um erro inesperado. Tente novamente."** |

**Observações factuais:**
- Todos os textos estão **sem acentuação** no código.
- A checagem é **case-sensitive e por substring** — `"Network"` com maiúscula **não** casa.
- Não há mapeamento por código de erro estruturado, só por substring da mensagem.

**Uso real:** `DisparosPage.tsx` usa `getErrorMessage(error)` como `description` de toasts; `ExportButton.tsx` usa `logError(error, { source: "ExportButton", action: "export" })`.

### 11.3 `edge-function-error.ts` — leitura do corpo de erro de Edge Function

**Arquivo:** `src/lib/edge-function-error.ts` (IAF-5187, A2)

**O problema que resolve** (declarado no cabeçalho): `supabase.functions.invoke` rejeita não-2xx com `FunctionsHttpError` cuja `message` é **sempre** `"Edge Function returned a non-2xx status code"`. O corpo detalhado fica em `error.context` (um `Response`).

**Contrato do corpo:** `{ success: false, code, stage, message, delivery_id? }`.

```ts
interface EdgeFunctionErrorPayload {
  code: string | null;
  stage: string | null;
  message: string | null;
  deliveryId: string | null;
  raw: Record<string, unknown>;
}
async function readEdgeFunctionErrorBody(error: unknown): Promise<Record<string, unknown> | null>
async function readEdgeFunctionError(error: unknown): Promise<EdgeFunctionErrorPayload | null>
```

| Função | Comportamento |
|---|---|
| `readEdgeFunctionErrorBody` | Pega `error.context`; duck typing — se tem `clone()` usa `clone().json()`; senão se tem `json()` usa direto; senão devolve o próprio `context` como record. Tudo em try/catch → `null` em qualquer falha. **Nunca lança** |
| `readEdgeFunctionError` | Normaliza. `message` = `body.message` ou, como fallback de compatibilidade, `body.error` (cobre EFs antigas que só devolvem `{ error: "..." }`). `optionalString` descarta não-string e string em branco |

**Regra de ouro, literal no código:**
> *"Este módulo NÃO inventa mensagem: se o backend não mandou uma, devolve null e o caller usa o próprio fallback."*
> *"Retorna null quando não há corpo legível — nunca fabrica uma mensagem."*

**Não há mapeamento de códigos aqui** — `code` e `stage` são repassados crus; quem decide o texto por código é o caller.
`⚠️ A confirmar:` quem são os callers e como eles traduzem `code`/`stage`.

### 11.4 Mapa de como o erro chega ao usuário, por superfície

| Superfície | Mecanismo | Visibilidade do erro |
|---|---|---|
| Erro de render | `ErrorBoundary` | Tela cheia "Algo deu errado" |
| Mutation de dados (CRUD) | Toast `destructive` | Título + descrição; descrição costuma ser `error.message` cru |
| Query do React Query | **Quase sempre invisível** — o componente consome só `data`/`isLoading` | Cai no **estado vazio**, indistinguível de "não há dados" |
| Painel Maestro — sessão/chat | `setError` do contexto → bloco vermelho no chat | Visível, não dispensável, sem retry |
| Painel Maestro — propostas | Só `console.error` | **Invisível.** Cabeçalho vermelho sem a mensagem |
| Painel Maestro — audit/config/histórico | Estado vazio | Invisível |
| Disparos | `ErrorState` com **"Tentar novamente"** | Visível e acionável — o melhor padrão do app |
| Página de métricas de IA | `SectionErrorState` de `MetricSectionBoundary` | Visível e por seção |

---

## 12. Guarda de formulário sujo (useDirtyFormGuard)

**Arquivo:** `src/hooks/useDirtyFormGuard.ts`
**Arquitetura:** **headless em duas peças**, documentada no cabeçalho do arquivo (plano "UX.2 — iaf-3989-hardening-multiagentes").

### 12.1 API

```ts
export const DirtyFormGuardContext: React.Context<DirtyFormGuardContextValue | null>

export interface DirtyFormGuardContextValue {
  register: (id: string, dirty: boolean) => void;
  unregister: (id: string) => void;
  showConfirmation: (onProceed: () => void) => void;   // incondicional
}

// Hook do FORMULÁRIO
export function useDirtyFormGuard(isDirty: boolean): {
  confirmIfDirty: (onProceed: () => void) => void;
}

// Hook do HOST
export function useDirtyFormGuardController(): {
  contextValue: DirtyFormGuardContextValue;
  guardNavigation: (onProceed: (options: { replaceHistoryEntry: boolean }) => void) => void;
  confirm: { open: boolean; onKeepEditing: () => void; onDiscard: () => void };
}
```

### 12.2 Quando dispara — os cinco gatilhos

**Lado do formulário (`useDirtyFormGuard(isDirty)`):**

1. **Registro no host** — `ctx.register(useId(), isDirty)` em `useEffect`; `unregister` no unmount. Só se houver provider.
2. **`beforeunload`** — instalado **apenas enquanto `isDirty === true`**: `event.preventDefault(); event.returnValue = ""`. Cobre reload, fechar aba e navegação para URL externa (prompt nativo do navegador).
3. **`confirmIfDirty(onProceed)`** — se não está sujo, executa na hora; se está sujo e há provider, abre a confirmação; **se está sujo e NÃO há provider, prossegue mesmo assim** (fallback documentado: "Sem provider nao ha UI de confirmacao compartilhada — prossegue").

**Lado do host (`useDirtyFormGuardController()`), só enquanto `hasDirty === true`:**

4. **Intercepta cliques em `<a href>`** — listener de `click` em `document` na **fase de captura** (`true`), antes do React Router.
   Ignora: `bypassRouteGuardRef` ativo, `defaultPrevented`, botão ≠ 0, `meta/ctrl/shift/alt`, âncora com `download`, `target` ≠ `_self`, origem diferente, mesma URL.
   Se passar: `preventDefault()` + `stopPropagation()` + abre a confirmação. Ao descartar, liga o bypass e re-dispara `anchor.click()`.
5. **Back/Forward do navegador** — empurra uma **entrada sentinela** no history com a MESMA URL (`window.history.pushState({...state, __dirtyFormGuard: token}, "", location.href)`). No `popstate`, re-empurra a sentinela e pede confirmação; ao descartar, `window.history.go(-2)`. No cleanup, se o token ainda for o atual, faz `history.back()` para remover a sentinela.

> **Por que não `useBlocker`:** comentário explícito no arquivo — o app usa `<BrowserRouter>` (não data router), então `useBlocker` do React Router não está disponível. O bloqueio é feito por captura de clique + sentinela no history.

### 12.3 Gestão de foco

`showConfirmation` guarda `document.activeElement` (se `HTMLElement`) em `pending.returnFocusTo`.
- `onKeepEditing` limpa o pending e, via `setTimeout(..., 0)`, devolve `target.focus()`.
- `onDiscard` limpa o pending e executa `onProceed`.

### 12.4 O diálogo — textos exatos

**O hook não renderiza UI.** Quem renderiza é o host, `src/pages/AgentWorkspace.tsx` (linhas 718-742), com um `AlertDialog` shadcn:

| Elemento | Texto exato |
|---|---|
| `AlertDialogTitle` | **"Descartar alterações?"** |
| `AlertDialogDescription` | **"Há alterações não salvas nesta seção. Se você sair agora, elas serão perdidas."** |
| `AlertDialogCancel` | **"Continuar editando"** |
| `AlertDialogAction` (→ `dirtyConfirm.onDiscard`) | **"Descartar alterações"** |

`onOpenChange`: fechar por Escape ou backdrop chama `onKeepEditing()`.

**Diálogo irmão, com texto próprio e sem usar o hook** — `src/components/ia/PlaygroundSettingsDialog.tsx` (linhas 874-888, "PG.6", com estado `confirmDiscard` local):

| Elemento | Texto exato |
|---|---|
| Título | **"Descartar alterações?"** |
| Descrição | **"Você alterou as configurações do playground e ainda não salvou. Se sair agora, as alterações serão perdidas."** |
| Botões | **"Continuar editando"** / **"Descartar"** (só "Descartar", sem "alterações") |
| Extra | `AlertDialogContent className="z-[70]"` |

### 12.5 Onde o guard é consumido hoje

**Host (controller + provider + AlertDialog): apenas `src/pages/AgentWorkspace.tsx`.**

Formulários registrados:

| Arquivo | Linha | Expressão de `isDirty` |
|---|---|---|
| `ia/PersonalityEditor.tsx` | 248 | `!readOnly && (isFirstAgent ? isFirstAgentDirty : !!hasChanges)` |
| `ia/GuidelinesEditor.tsx` | 87 | `isFormDirty` |
| `ia/BusinessRulesBuilder.tsx` | 89 | `isFormDirty` |
| `ia/PromptEditor.tsx` | 137 | `isFormDirty` |
| `ia/FunnelStagesConfig.tsx` | 269 | `isFormDirty` |
| `ia/AgentAllowedTagsConfig.tsx` | 120 | `canWrite && isDirty` |
| `ia/TransferTagsConfig.tsx` | 294 / 668 | `open && isDirty` / `isDirty` |
| `settings/tabs/TagCatalogTab.tsx` | 228 / 422 | `open && isDirty` / `!!tag && isDirty` |

**Testes:** `src/hooks/__tests__/useDirtyFormGuard.test.tsx`, `src/pages/__tests__/AgentWorkspace.spec.tsx`, e specs de `GuidelinesEditor`, `TransferTagsConfig`, `AgentAllowedTagsConfig`, `TagCatalogTab`, `PlaygroundSettingsDialog`.

> **Achado importante para o redesign:** o guard **não é global**. Todos os formulários protegidos vivem no Agent Workspace e no catálogo de tags. **Editor de régua, editor de broadcast, formulários de campanha, filtros, integrações e ETL não têm proteção nenhuma contra perda de alterações.**

---

## 13. Modais globais (inventário)

### 13.1 Montados em `src/App.tsx` (raiz, fora do router de páginas)

| Componente | Tipo | Linha | Função |
|---|---|---|---|
| `ErrorBoundary` | Boundary de classe (tela cheia de fallback) | 443 | Envolve o app inteiro |
| `TooltipProvider` | Provider Radix | 445 | Contexto de tooltips para toda a árvore |
| `Toaster` | Viewport de toasts Radix (`fixed`, `z-100`) | 453 | Renderiza os toasts; **fora do `BrowserRouter`** |
| `PageLoader` | Não é modal — spinner de `Suspense` | 83 | `flex h-screen items-center justify-center` + spinner `h-8 w-8 border-b-2 border-primary` |

### 13.2 Montados em `src/components/layout/AppLayout.tsx` (todas as rotas autenticadas)

| Componente | Tipo | Linha | Função |
|---|---|---|---|
| `AgentSidePanel` | Painel lateral **não-Radix**: `div` `fixed right-0 top-0 bottom-0 z-40 border-l bg-background shadow-lg flex flex-col` | 136 | Painel do Maestro; o `<main>` recebe `marginRight` igual à largura |
| `ChangelogNotificationBalloon` | Balão `fixed bottom-4 right-4 z-50 w-[min(22rem,calc(100vw-2rem))]`, `role="status" aria-live="polite"` | 139 | Aviso de novidades não lidas. **Sem auto-dismiss** (comentário explícito); só some quando o usuário abre as novidades ou clica em "Marcar como lido". Ícone `Megaphone` com `motion-safe:animate-ping` e badge de contagem (`>9` vira "9+"). Lista até 5 títulos; resto vira "+N novidades". Texto: `"{n} novidade(s) pra você"` + `"Veja o que mudou na Torre."` |
| Backdrop mobile | `div` `fixed inset-0 z-40 bg-black/50 backdrop-blur-sm` | 82-87 | Fecha a sidebar em mobile. A sidebar mobile é `fixed inset-y-0 left-0 z-50` com `-translate-x-full` quando fechada — **drawer feito à mão, não um `Sheet`** |

### 13.3 Montados em `src/components/layout/Sidebar.tsx`

| Componente | Tipo | Linha | Função |
|---|---|---|---|
| `CustomerSearch` | `Dialog` (shadcn/Radix) + `PortfolioDetailSheet` (que também é `Dialog`, quase full-screen) | 119 | Busca global de cliente na org atual → abre o detalhe do contato |
| `DropdownMenu` de Organizações | `DropdownMenu` (Radix) | 165-222 | Trocar de org; "Gerenciar Organizações" → `/select-organization` |
| `DropdownMenu` de Usuário | `DropdownMenu` (Radix) | 226-277 | "Perfil" (sem handler), "Modo Escuro"/"Modo Claro", "Sair" |
| `AgentSidebarButton` | Botão | 157 | Toggle do painel do Maestro |
| `DocsNavButton` | Botão de navegação | 158 | Central de Docs (com aviso de Novidades) |
| `TooltipProvider delayDuration={0}` | Provider | 79 | Tooltips dos itens quando a sidebar está colapsada |

### 13.4 Modais "globais por alcance", ainda que montados numa tela

| Componente | Tipo | Onde | Função |
|---|---|---|---|
| `AlertDialog` do dirty guard | `AlertDialog` (Radix/shadcn) | `pages/AgentWorkspace.tsx:721-742` | "Descartar alterações?" — host único do `useDirtyFormGuardController`, cobre todos os editores do Agent Workspace |
| `AlertDialog` do Playground | `AlertDialog` `z-[70]` | `components/ia/PlaygroundSettingsDialog.tsx:874-888` | Mesma finalidade, escopo local, texto próprio |
| `AgentConfigModal` | `Dialog` `sm:max-w-[600px]` | `components/agent/AgentConfigModal.tsx:164` | Configuração de LLM; acessível de **qualquer rota autenticada** pelo painel lateral |

### 13.5 O que NÃO existe em nível de app

Verificado por busca no repositório e **não encontrado**:

- Command palette / `CommandDialog` (nenhum Cmd+K)
- Modal de confirmação global de logout
- Modal de sessão expirada
- Qualquer `Sheet` do Radix montado em `App.tsx` ou `AppLayout.tsx`
- Modal de onboarding / tour
- Modal de "o que há de novo" (o changelog usa balão + página, não modal)

### 13.6 Mapa de `z-index` dos elementos globais

| Camada | `z-index` | Elemento |
|---|---|---|
| Toasts | `z-[100]` | `ToastViewport` |
| Diálogo de descarte do Playground | `z-[70]` | `AlertDialogContent` |
| Radix Dialog/AlertDialog (default) | `z-50` | `CustomerSearch`, `AgentConfigModal`, `ContactDetailSheet`, guard do dirty form |
| Balão de novidades | `z-50` | `ChangelogNotificationBalloon` |
| Sidebar mobile | `z-50` | Drawer manual |
| **Painel do Maestro** | `z-40` | `AgentSidePanel` |
| Backdrop mobile | `z-40` | — |
| Headers sticky das páginas de docs | `z-40` | — |

> **Achado:** o painel do Maestro (`z-40`) fica **abaixo** da sidebar mobile (`z-50`) e de qualquer `Dialog`. Em mobile, abrir a sidebar cobre o painel.

---

## 14. Dores e oportunidades para o redesign

Esta seção é a única do documento com juízo de valor. Tudo o que está acima é descrição; aqui estão os problemas que o redesenho tem chance de resolver. Nada aqui deve ser lido como "remova a funcionalidade" — a regra é **não perder nada**.

### 14.1 Painel Maestro — problemas estruturais

| # | Dor | Evidência | Oportunidade |
|---|---|---|---|
| 1 | **Nada persiste** | `AgentPanelContext` não usa `localStorage`; a sidebar usa | Persistir `isOpen`, `width` e `contextAware`. A sessão em si exige decisão de produto (retomar a última conversa ao voltar?) |
| 2 | **Trocar de modo destrói a conversa sem avisar** | `handleModeChange` chama `clearSession()` direto | Confirmação, ou permitir trocar de modo dentro da mesma sessão |
| 3 | **O modo escolhido pode não valer** | `AgentChatView` chama `startChat(trimmed)` com default `"plan"` | Passar o modo selecionado sempre |
| 4 | **O usuário não controla a visão** | Sem `TabsList`; `view` muda só programaticamente | Uma navegação visível entre Chat / Plano / Execução, com indicador de que há plano pendente |
| 5 | **Sugestões de boas-vindas são falsas** | 4 pílulas sem `onClick` | Ligar ao composer — é a correção de menor custo e maior impacto percebido |
| 6 | **Sem timestamp no chat** | `createdAt` existe e nunca é renderizado | Exibir hora relativa ou absoluta; hoje é impossível saber quando uma resposta chegou |
| 7 | **Sem ações por mensagem** | Nenhuma | Copiar resposta é o mínimo; regenerar e feedback são naturais num agente |
| 8 | **Sem streaming** | Resposta chega inteira via `response.json()` | O `ThinkingIndicator` compensa parcialmente, mas 5 min de timeout sem feedback incremental é muito |
| 9 | **Texto perdido em caso de falha** | `handleSend` limpa o input **antes** do `await` | Limpar só após sucesso, ou restaurar no catch |
| 10 | **Só uma proposta por vez** | `proposals.find(pending)` | Se o backend pode mandar várias, a UI precisa de fila |
| 11 | **Rejeitar é um `X` mudo** | Sem rótulo, sem `title`, sem motivo | Rótulo explícito + campo de motivo (o parâmetro `_reason` já existe na assinatura) |
| 12 | **Erro de execução é invisível** | `useAgentProposals` só faz `console.error` | Trazer a mensagem do backend para a tela |
| 13 | **Falha ao rejeitar não avisa** | A view troca de qualquer forma | Manter na tela e mostrar erro |
| 14 | **Sem acessibilidade no painel** | Sem `role`, sem `aria-label`, handle sem `role="separator"` nem teclado | Redimensionar por teclado; rotular a região |
| 15 | **Botão da sidebar não reflete estado** | Sem badge, sem realce quando aberto | Estado ativo + indicador de sessão em andamento |
| 16 | **Cores de persona sem dark mode** | `bg-blue-50`, `bg-purple-50`… sem par `dark:` | Tokenizar as personas |
| 17 | **Labels inconsistentes** | `general` = "Modo Geral" no painel, "Maestro" na mensagem | Fonte única |
| 18 | **Valores crus na UI** | `semi_auto` no histórico, `proposal_approved` no audit | `MODE_CONFIG` e `AUDIT_ACTION_LABELS` já existem — basta usá-los |
| 19 | **`rollback_plan` invisível** | Existe no tipo, nunca renderizado | Mostrar antes de aprovar; é informação de segurança |
| 20 | **Transição atrapalha o drag** | `transition-all duration-300` no `<main>` durante o resize | Desligar a transição enquanto `isResizing` |

### 14.2 Funcionalidade implementada e desconectada

| Item | Situação |
|---|---|
| `usePageContext` inteiro | **Nunca chamado.** O toggle "Contexto da pagina" não faz nada hoje |
| `ROUTE_PATTERNS` | Aponta para rotas que **não existem** (`/portfolios`, `/workflows`, `/data-sources`, `/pipelines`, `/agent-config`) |
| `SessionStatsSummary` | Exportado, sem consumidor |
| `useSetDefaultLLMConfig`, `useDefaultLLMConfig` | Sem consumidor |
| `formatAuditLogsForExport`, `downloadAuditLogs`, `useExportAuditLogs`, `useSessionAuditLogs`, `useProposalAuditLogs`, `useRecentAuditActivity` | Sem consumidor — o viewer tem uma função de export mais pobre |
| Variante `success` do toast | Definida, nunca usada |
| 6 dos 15 componentes de `loading-states.tsx` | `CardSkeleton` (só interno), `KPIGridSkeleton`, `TableSkeleton`, `ListSkeleton`, `PageHeaderSkeleton`, `FormSkeleton` — sem import externo |

> **Decisão que o redesign precisa tomar:** ligar ou remover. Manter código morto documentado como "existe mas não funciona" confunde tanto o designer quanto o próximo desenvolvedor.

### 14.3 Estados de carregamento e vazio

| # | Dor | Oportunidade |
|---|---|---|
| 1 | **Dois sistemas paralelos** (`loading-states.tsx` e `ia/MetricSectionBoundary.tsx`) | Unificar a linguagem visual mantendo a semântica extra da IA |
| 2 | **Skeletons hardcoded por página** (`FiltersPageSkeleton`, `CampaignsPageSkeleton`, `ReguasPageSkeleton`, `PortfolioGridSkeleton`) | 4 esqueletos quase idênticos que divergem no detalhe. Um componente parametrizado por "forma de linha" cobriria os quatro |
| 3 | **`ChartSkeleton` com alturas aleatórias** | Re-sorteia a cada render; num refetch, o esqueleto "pula". Alturas fixas resolvem |
| 4 | **Sem shimmer** | Só `animate-pulse` uniforme. Decisão de design, mas vale revisitar |
| 5 | **Erro de query vira estado vazio** em várias telas | "Nenhum resultado" e "falhou ao carregar" são coisas diferentes e hoje são indistinguíveis |
| 6 | **`ErrorState` só existe em Disparos** | É o melhor padrão do app (título + descrição + "Tentar novamente") e está confinado a 3 arquivos |

### 14.4 Toasts

| # | Dor | Oportunidade |
|---|---|---|
| 1 | **`TOAST_LIMIT = 1`** | Uma ação em lote que dispara 3 toasts mostra só o último. Aumentar o limite ou agrupar |
| 2 | **Duração não declarada** | Depende do default da lib; ninguém no time sabe qual é sem ler o Radix |
| 3 | **Botão de fechar invisível** (`opacity-0` até hover) | Em toque, é inalcançável por descoberta |
| 4 | **Variante `success` nunca usada** | Sucesso e informação neutra têm o mesmo visual hoje |
| 5 | **Mensagens técnicas vazando** | Vários toasts usam `err.message` cru como descrição |
| 6 | **Títulos genéricos "Erro"/"Sucesso"** | 348 chamadas, muitas com o mesmo título. Guia de copy resolveria |
| 7 | **Erros sem `destructive`** | `DisparosPage` tem 3 toasts de erro em variante `default` |
| 8 | **Sem ação no toast** | `ToastAction` existe no componente e não é usado em nenhum lugar — "Desfazer" e "Ver detalhes" seriam naturais |

### 14.5 Erro

| # | Dor | Oportunidade |
|---|---|---|
| 1 | **"Nossa equipe foi notificada" é falso** | Ou integrar um serviço de monitoramento, ou corrigir a copy |
| 2 | **`logError` não faz nada em produção** | Mesmo problema |
| 3 | **Um único `ErrorBoundary` no topo** | Qualquer erro de render derruba a tela inteira. Boundaries por rota (e por seção nas telas pesadas) degradariam melhor |
| 4 | **Mapeamento de erro por substring case-sensitive** | `"Network"` não casa com `"network"`. Frágil por construção |
| 5 | **Fallback vaza a mensagem técnica** | Quando nenhuma regra casa, `error.message` cru vai para a tela |
| 6 | **Textos sem acentuação** | `"Sua sessao expirou"`, `"Erro de conexao"`, `"Voce nao tem permissao"` — inconsistente com o resto do app |
| 7 | **"Tentar novamente" do `ErrorBoundary` raramente resolve** | Só reseta o state; se o erro é determinístico, volta na hora |

### 14.6 Guarda de formulário sujo

| # | Dor | Oportunidade |
|---|---|---|
| 1 | **Só protege o Agent Workspace e o catálogo de tags** | Editor de régua, editor de broadcast, campanhas, filtros, integrações e ETL não têm proteção |
| 2 | **Dois diálogos com textos diferentes** | O do Playground não usa o hook e tem copy própria |
| 3 | **Fallback silencioso sem provider** | `confirmIfDirty` **prossegue** se não houver provider — perde dados sem avisar |
| 4 | **Sentinela no history é frágil** | Solução engenhosa para a limitação do `BrowserRouter`; migrar para data router e `useBlocker` simplificaria |

### 14.7 Busca de cliente

| # | Dor | Oportunidade |
|---|---|---|
| 1 | **Sem atalho de teclado** | Não há Cmd+K em lugar nenhum do app |
| 2 | **Dois diálogos empilhados** | O modal de busca não fecha ao selecionar; o detalhe do cliente abre por cima |
| 3 | **`PortfolioDetailSheet` é um `Dialog`** | Nome engana; e um dialog de `95vw × 95vh` é, na prática, uma rota disfarçada |
| 4 | **Sem navegação por teclado na lista** | Setas e Enter não percorrem os resultados (só o Enter no input submete o termo) |
| 5 | **Limite de 20 com aviso textual** | "Exibindo os primeiros 20 clientes" — sem paginação nem "carregar mais" |
| 6 | **Sem histórico de buscas recentes** | Um operador que consulta os mesmos clientes redigita tudo |

### 14.8 Consistência global

| # | Observação |
|---|---|
| 1 | **Acentuação inconsistente.** O painel Maestro e `error-handler.ts` estão majoritariamente **sem acentos**; o resto do app está com acentos corretos. É o sintoma mais visível de duas gerações de código |
| 2 | **Confirmação nativa do navegador** (`window.confirm`) no `AgentConfigModal`, enquanto o resto do app usa `AlertDialog` |
| 3 | **Query keys sem `org.slug`** em `useAgentAuditLogs` e `useAgentLLMConfigs` — risco de vazamento de cache entre organizações |
| 4 | **Cores literais de paleta** (`blue-500`, `purple-600`, `yellow-500`, `green-50`…) concentradas no Maestro e no audit log, contra tokens semânticos no resto do app |
| 5 | **Dois padrões de drawer**: o Radix `Sheet` existe no projeto mas a sidebar mobile e o painel do Maestro são feitos à mão |
| 6 | **`z-index` do Maestro abaixo de tudo** (`z-40`) — em mobile, a sidebar o cobre |

---

## Anexo A — Índice de arquivos-fonte citados

### Painel Maestro
- `src/components/agent/AgentSidePanel.tsx`
- `src/components/agent/AgentSidebarButton.tsx`
- `src/components/agent/AgentChatView.tsx`
- `src/components/agent/AgentChatMessage.tsx`
- `src/components/agent/AgentMarkdown.tsx`
- `src/components/agent/AgentPlanView.tsx`
- `src/components/agent/AgentExecutionView.tsx`
- `src/components/agent/AgentSessionHistory.tsx`
- `src/components/agent/AgentConfigModal.tsx`
- `src/components/agent/AgentAuditLogViewer.tsx`
- `src/components/agent/AgentContextToggle.tsx`
- `src/components/agent/index.ts`
- `src/contexts/AgentPanelContext.tsx`
- `src/hooks/useAgentSession.ts`
- `src/hooks/useAgentSessions.ts`
- `src/hooks/useAgentProposals.ts`
- `src/hooks/useAgentAuditLogs.ts`
- `src/hooks/useAgentLLMConfigs.ts`
- `src/hooks/usePageContext.ts`
- `src/components/common/HelpTip.tsx`

### Elementos globais
- `src/App.tsx`
- `src/components/layout/AppLayout.tsx`
- `src/components/layout/Sidebar.tsx`
- `src/components/layout/CustomerSearch.tsx`
- `src/hooks/useCustomerSearch.ts`
- `src/hooks/useDebouncedSearchInput.ts`
- `src/lib/customer-search.ts`
- `src/components/ErrorBoundary.tsx`
- `src/components/ui/loading-states.tsx`
- `src/components/ui/skeleton.tsx`
- `src/components/ui/toast.tsx`
- `src/components/ui/toaster.tsx`
- `src/hooks/useToast.ts`
- `src/hooks/useDirtyFormGuard.ts`
- `src/lib/error-handler.ts`
- `src/lib/edge-function-error.ts`
- `src/components/portfolio/detail/ContactDetailSheet.tsx`
- `src/components/ia/MetricSectionBoundary.tsx`
- `src/pages/AgentWorkspace.tsx` (host do dirty guard)
- `src/components/ia/PlaygroundSettingsDialog.tsx`

### Edge Functions consumidas pelo Maestro
- `ai-orchestrator` — `create_session`, `send_message`, `get_session`, `end_session`
- `ai-proposal-executor` — `execute_proposal`, `cancel_proposal`, `get_proposal_status`

### Tabelas consumidas
- `agent_sessions` (schema da org)
- `agent_audit_logs` (schema da org)
- `agent_llm_configs` (schema da org)
- RPC `public.encrypt_llm_key`
- RPC `public.search_customers`

---

## Anexo B — Lista consolidada de `⚠️ A confirmar`

1. **Permissão do Maestro** — nenhuma checagem de permissão protege o painel; qualquer usuário autenticado com org pode abrir e, potencialmente, executar propostas. Intencional?
2. **Auto-scroll do chat** — o `ref` está no `ScrollArea` do shadcn, cujo viewport rolável é um filho. O auto-scroll funciona de fato?
3. **Comportamento real dos modos** `plan` / `semi_auto` / `full_auto` — vive na Edge Function `ai-orchestrator`, fora dos arquivos de frontend lidos.
4. **Duração de auto-dismiss do toast** — o projeto não define `duration` em lugar nenhum; o valor efetivo é o default do Radix e não está escrito no repositório.
5. **Variante do toast "Campos obrigatórios"** (`SelectOrganizationPage.tsx:282`) — a leitura cortou antes da linha de `variant`.
6. **Campos exatamente pesquisados pela RPC `search_customers`** — o frontend só passa `p_schema_name`/`p_term`/`p_limit`. A lista vem da regra 46 do `CLAUDE.md`, não do código lido.
7. **Callers de `edge-function-error.ts`** e como traduzem `code`/`stage` para texto de usuário.
8. **`queryClient.clear()` na troca de organização** — a sidebar chama `invalidateAllQueries()`; não foi verificado se `OrganizationContext` faz limpeza completa. Relevante por causa das query keys sem `org.slug`.
9. **Desconexão do `usePageContext`** — dívida técnica intencional (feature desligada) ou regressão?
10. **Re-exports de `loading-states`** — `src/components/dashboard/index.ts` teve 1 hit numa busca ampla; não foi verificado se re-exporta os 6 componentes sem consumidor direto.
