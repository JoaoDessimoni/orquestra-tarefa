# 02 · Arquitetura de Frontend, Shell e Rotas

> Fonte da verdade: `cobranca-finza/src/App.tsx`, `src/main.tsx`, `src/components/layout/*`, `src/contexts/*`, `package.json`.
> Este documento descreve **o esqueleto**: o que envolve todas as telas, como se navega, o que protege cada rota e quais são as regras estruturais que o redesenho não pode quebrar.

---

## 1. Stack

| Camada | Tecnologia | Versão |
|---|---|---|
| Biblioteca de UI | React | 19 |
| Linguagem | TypeScript | 5.9 |
| Bundler | Vite | 7 |
| Estilo | Tailwind CSS | **4** (configuração CSS-first via `@theme`) |
| Componentes base | shadcn/ui sobre Radix UI | — |
| Roteamento | React Router | 7 |
| Estado de servidor | TanStack Query (React Query) | 5 |
| Tabelas | TanStack Table 8 + TanStack Virtual 3 | — |
| Formulários | react-hook-form 7 + zod 4 (`@hookform/resolvers`) | — |
| Gráficos | **Recharts 3** e **Chart.js 4** (`react-chartjs-2`) — coexistem | — |
| Grafos | Cytoscape 3 (2D) e `react-force-graph-3d` + three.js (3D) | — |
| Editor de texto rico | TipTap 3 (`starter-kit`, `mention`, `placeholder`, `suggestion`) + Tippy.js | — |
| Editor de código | CodeMirror (`@uiw/react-codemirror`, `@codemirror/lang-sql`) | — |
| Arrastar e soltar | dnd-kit (`core`, `sortable`, `utilities`) | — |
| Ícones | lucide-react | — |
| Datas | date-fns 4 + react-day-picker 9 | — |
| Planilhas / CSV | `xlsx` (vendorizado) + papaparse | — |
| Markdown | react-markdown + remark-gfm | — |
| Variantes de classe | class-variance-authority + clsx + tailwind-merge | — |
| Backend | Supabase (PostgreSQL + Edge Functions Deno) | — |

**Observação para o redesenho:** existirem **duas** bibliotecas de gráfico (Recharts e Chart.js) é dívida técnica visível — os gráficos não têm a mesma linguagem visual entre si. É uma das principais oportunidades de unificação.

---

## 2. Árvore de providers

```
<ErrorBoundary>                       src/components/ErrorBoundary.tsx
  <QueryClientProvider>               staleTime 5min · gcTime 10min · retry 1
    <TooltipProvider>                 Radix
      <BrowserRouter>
        <AuthProvider>                src/contexts/AuthContext.tsx — sessão Supabase
          <OrganizationProvider>      src/contexts/OrganizationContext.tsx — org ativa + RBAC
            <AppRoutes/>
              └ (rotas internas) <AgentPanelProvider> → <AppLayout>
  <Toaster/>                          notificações globais
```

Configuração do React Query (`src/App.tsx`) e o **porquê** de cada escolha:

| Opção | Valor | Motivo declarado no código |
|---|---|---|
| `staleTime` | 5 min | Evita refetch enquanto o usuário edita formulários longos. |
| `gcTime` | 10 min | Coleta de lixo do cache. |
| `retry` | 1 | — |
| `refetchOnWindowFocus` | **false** | Recarregar ao voltar para a aba destruía formulários em edição. |
| `refetchOnReconnect` | true | Revalida ao reconectar a internet. |

**Consequência de UX:** como não há refetch automático ao focar a janela, o produto precisou criar um **padrão explícito de atualização manual** (`RefreshButton`, `RefreshTopBar`, `RefreshableSection`). Isso é um elemento de design de primeira classe, não um detalhe.

---

## 3. O shell autenticado (`AppLayout`)

`src/components/layout/AppLayout.tsx`

```
┌──────────────────────────────────────────────────────────────┐
│ fixed inset-0 · flex · overflow-hidden                       │
│ ┌──────────┬───────────────────────────────┬───────────────┐ │
│ │ Sidebar  │ main #main-content            │ AgentSidePanel│ │
│ │ 256/64px │  ├ header mobile (só <768px)  │ (empurra o    │ │
│ │ h-screen │  └ scroller único (p-3/sm:p-6)│  main com     │ │
│ │          │                               │  margin-right)│ │
│ └──────────┴───────────────────────────────┴───────────────┘ │
│                          ChangelogNotificationBalloon (⌐ inf.)│
└──────────────────────────────────────────────────────────────┘
```

Regras estruturais que o redesenho **precisa preservar** (cada uma resolve um bug real documentado no código):

1. **`fixed inset-0` no shell** — não é decorativo. Estabelece o *containing block* e faz o app acompanhar as bordas reais do viewport sem depender de `100dvh` (que fica obsoleto após zoom/resize/troca de monitor em alguns navegadores). Sem ele, qualquer descendente `position:absolute` sem ancestral posicionado — notadamente `sr-only`, que o Tailwind implementa com `absolute` — ancora no ICB e **soma ao `scrollHeight` do `<html>`**, criando um segundo scroll com área vazia. Medido: 2135px → 720px de `scrollHeight` só com o ajuste.
2. **Existe UM único scroller vertical** no app autenticado: o `<div>` interno do `main`, com `min-h-0 flex-1 overflow-auto overscroll-contain`. O `overflow-hidden` do shell garante isso. `overscroll-contain` evita *scroll chaining* para o documento.
3. **Reset de scroll em duas camadas:** `ScrollToTop` (em `App.tsx`) reseta `window.scrollTo(0,0)` a cada troca de rota — necessário para as páginas full-screen que rolam a janela; e o `AppLayout` reseta o container interno via `scrollRef` **apenas em `pathname`** (não em `search`), para não jogar o usuário para o topo quando ele só troca um filtro na query string.
4. **O painel do Maestro empurra o conteúdo**, não sobrepõe: `main` recebe `marginRight: agentPanelWidth` quando aberto, com `transition-all duration-300`.

### 3.1 Sidebar

`src/components/layout/Sidebar.tsx`

| Zona | Conteúdo |
|---|---|
| Topo (`h-16`, borda inferior) | Logo (completo quando expandida / ícone quando recolhida) + botão de recolher (`ChevronLeft`). Quando recolhida, o botão de expandir (`ChevronRight`) aparece **abaixo** do cabeçalho, centralizado. |
| Navegação (`flex-1`, rolável) | `CustomerSearch` (busca global de cliente) + os 12 itens de menu, **filtrados por permissão**. |
| Bloco inferior 1 (borda superior) | `AgentSidebarButton` (abre o Maestro) + `DocsNavButton` (Central de Docs, com aviso de novidades não lidas). |
| Rodapé (borda superior) | Seletor de organização (dropdown com logo/nome + lista de orgs + "Gerenciar Organizações") e menu do usuário (avatar + nome + e-mail → Perfil / Modo Escuro-Claro / Sair). |

Comportamentos:

- **Estado recolhido persistido** em `localStorage` (`sidebar-collapsed`).
- Recolhida, cada item vira só-ícone com **tooltip à direita**.
- Item ativo: fundo `sidebar-accent` (azul sólido) com texto/ícone brancos. Inativo: hover `sidebar-accent/10` com texto azul.
- **Prefetch de rota**: todas as rotas são pré-carregadas no mount (`prefetchAllRoutes`) e o hover em um item força o prefetch daquela rota (`prefetchRoute`). Isso existe porque todas as páginas são `React.lazy`.
- Trocar de organização chama `invalidateAllQueries()` antes — o cache é por org e vazar dado entre tenants seria grave.
- "Gerenciar Organizações" remove `torre-controle-current-org` do `localStorage`, invalida tudo e vai para `/select-organization`.
- Em mobile, navegar fecha o drawer (`onNavigate`).

### 3.2 Header legado

`src/components/layout/Header.tsx` existe com busca, seletor de org, sino de notificações (badge fixo "3") e menu de usuário — **mas não é usado pelo `AppLayout`**. É código morto visual.

⚠️ A confirmar: confirmar com o time se `Header.tsx` pode ser descartado no redesenho. Aparentemente foi substituído pelo rodapé da sidebar.

---

## 4. Mapa completo de rotas

### 4.1 Rotas públicas (sem sessão)

| Rota | Componente | Arquivo | Observação |
|---|---|---|---|
| `/login` | `LoginPage` | `src/pages/LoginPage.tsx` | Preserva o deep-link em `location.state.from`. |
| `/signup` | `SignUpPage` | `src/pages/SignUpPage.tsx` | — |
| `/accept-invite` | `AcceptInvitePage` | `src/pages/AcceptInvitePage.tsx` | Aceite de convite por link. |
| `/docs` | `DocsPage` | `src/pages/DocsPage.tsx` | **Documentação pública da API REST.** Única rota de conteúdo sem autenticação. |

### 4.2 Rotas autenticadas fora do `AppLayout` (tela cheia, sem sidebar)

| Rota | Componente | Guardas |
|---|---|---|
| `/select-organization` | `SelectOrganizationPage` | sessão |
| `/reguas-cobranca/:id/editor` | `ReguasCobrancaEditorPage` | sessão + org |
| `/broadcasts/:id/editor` | `BroadcastEditorPage` | sessão + org |
| `/docs-especial` | `DocsEspecialPage` | sessão + org |
| `/docs/fonte-de-dados` | `FonteDeDadosDocs` | sessão + org + `etl:read` |
| `/central-docs` e subrotas | Central de Documentação | sessão + org + permissão por pilar |

**Decisão de design:** os dois editores (régua e broadcast) saem do shell porque precisam de tela inteira para a timeline. O redesenho deve manter a distinção "página de gestão (com sidebar)" × "editor imersivo (sem sidebar)".

### 4.3 Central de Documentação (rotas estáticas precedem o curinga `:pillar`)

| Rota | Componente | Permissão |
|---|---|---|
| `/central-docs` | `CentralDocsPage` (hub) | org |
| `/central-docs/negocio` | `NegocioCatalogPage` | `docs:negocio` |
| `/central-docs/negocio/:id` | `PageGuidePage` | `docs:negocio` |
| `/central-docs/topicos` | `TopicsCatalogPage` | `docs:topicos` |
| `/central-docs/topico/:id` | `TopicPage` | `docs:topicos` |
| `/central-docs/tecnica` | `TecnicaCatalogPage` | `docs:tecnica` |
| `/central-docs/atom/:id` | `AtomPage` | `docs:tecnica` |
| `/central-docs/tags` | `TagsPage` | `docs:tecnica` |
| `/central-docs/grafo` | `GraphPage` | `docs:tecnica` |
| `/central-docs/servico` | `ServicoCatalogPage` | `docs:servico` |
| `/central-docs/changelog` | `ChangelogFeedPage` | `docs:changelog` |
| `/central-docs/changelog/:id` | `ChangelogPostPage` | `docs:changelog` |
| `/central-docs/:pillar` | `PillarDocPage` (fallback) | org |

Guard próprio: `RequireDocs` — `super_admin` (time Finza) passa sempre; sem acesso, redireciona para `/central-docs` (não para a raiz do app).

### 4.4 Rotas dentro do `AppLayout`

| Rota | Componente | Permissão | Item no menu |
|---|---|---|---|
| `/` | `DashboardPage` | — (todos) | Dashboard |
| `/portfolio` | `PortfolioManagementPage` | — (todos) | Gestão de Carteira |
| `/campaigns` | `CampaignsPage` | `campaigns:read` (menu) | Campanhas |
| `/reguas-cobranca` | `ReguasCobrancaPage` | `workflows:read` (menu) | Réguas de Cobrança |
| `/templates` | `MessageTemplatesPage` | `templates:read` (menu) | Templates |
| `/filters` | `FiltersPage` | `filters:read` (menu) | Filtros |
| `/actions` | `ActionsPage` | `actions:read` (menu) | Ações |
| `/actions/report` | `ActionsReportPage` | — | (sem item próprio) |
| `/actions/payment-analysis` | `ActionPaymentAnalysis` | — | (sem item próprio) |
| `/disparos` | `DisparosPage` | **`disparos:write`** (rota) | Disparos |
| `/integrations` | `IntegrationsPage` | **`integrations:read`** (rota) | Integrações |
| `/etl` | `ETLPage` | **`etl:read`** (rota) | Fonte de Dados |
| `/agent-ia` | `AgentGalleryPage` | **`agent-ia:read`** (rota) | Agente IA |
| `/agent-ia/tags` | `AgentTagsPage` | **`agent-ia:read`** (rota) | — |
| `/agent-ia/:agentId` | `AgentWorkspace` | **`agent-ia:read`** (rota) | — |
| `/settings` | `SettingsPage` | **`settings:read`** (rota) | Configurações |

Redirecionamentos legados: `/contacts` → `/portfolio`, `/contracts` → `/portfolio`.

**Assimetria importante:** algumas permissões são aplicadas **só no menu** (Campanhas, Réguas, Templates, Filtros, Ações) e outras **também na rota** (Disparos, Integrações, ETL, Agente IA, Configurações). No primeiro grupo, um usuário sem permissão não vê o item mas ainda conseguiria acessar pela URL.

⚠️ A confirmar: se isso é intencional. É um ponto a endereçar no redesenho (consistência de gating).

---

## 5. Guardas de rota

`src/App.tsx`

| Guard | O que verifica | O que faz ao falhar |
|---|---|---|
| `ProtectedRoute` | Existe `user` (sessão Supabase). | `<Navigate to="/login">` **preservando o deep-link** em `state.from`. |
| `RequireOrg` | Existe organização selecionada. | `<Navigate to="/select-organization">` preservando o deep-link (e herdando um `from` anterior, se já houver — para não sobrescrever com `/`). |
| `RequirePermission` | `hasPermission(permission)`. | `<Navigate to="/">` (volta ao Dashboard). |
| `RequireDocs` | `isSuperAdmin \|\| hasPermission(permission)`. | `<Navigate to="/central-docs">`. |

Todos exibem `PageLoader` enquanto `isLoading`.

**`PageLoader`:** `<div className="flex h-screen items-center justify-center">` com um spinner circular (`animate-spin rounded-full h-8 w-8 border-b-2 border-primary`). É o estado de carregamento de página inteira e aparece em toda transição de rota *lazy*.

⚠️ Oportunidade de redesenho: esse spinner nu é o primeiro contato visual em cada navegação. Substituir por *skeleton* da tela de destino melhoraria muito a percepção de velocidade.

---

## 6. Carregamento e divisão de código

**Todas as páginas são `React.lazy`** — 40+ chamadas em `App.tsx`. Há dois níveis de `<Suspense fallback={<PageLoader/>}>`: um no topo e outro dentro do `AppLayout`.

Isso significa que, no redesenho, a **primeira pintura** de qualquer tela é o `PageLoader`, não a tela. Mitigado pelo prefetch agressivo da sidebar.

---

## 7. Multi-tenant — o que isso significa para a interface

O produto é **schema-por-organização** (`org_{slug}` no PostgreSQL). O frontend cria um cliente Supabase com schema dinâmico (`createOrgClient(slug)`).

Impactos diretos na UI:

| Impacto | Consequência de design |
|---|---|
| Toda tela é "de uma organização" | O seletor de organização precisa estar sempre visível e inequívoco (hoje: rodapé da sidebar). |
| Trocar de org invalida TODO o cache | A troca é uma operação pesada e perceptível — merece feedback explícito. |
| Existe uma tela dedicada só para escolher a org | `/select-organization` (44 KB — não é um seletor simples; tem gestão). |
| Existe papel `super_admin` transversal | O time Finza vê coisas que o cliente não vê (ex.: gestão de chaves de API, pilares de documentação). O redesenho precisa de um tratamento visual para "modo interno". |
| Organizações têm logo próprio | `currentOrg.logo_url` aparece na sidebar; fallback é o ícone `Building2`. |
| Perfil de pipeline por org | Algumas organizações operam por **etapa** (ex.: formalização) em vez de **dias de atraso** — e isso **muda campos visíveis** no editor de régua. Ver doc 16. |

---

## 8. RBAC — resumo

Cinco papéis hierárquicos: `owner > admin > manager > operator > viewer`, definidos em `ROLE_PERMISSIONS` no `OrganizationContext`. `owner` recebe `["*"]`.

O gating é **frontend-only** (a autorização real é no banco/Edge Functions). Três mecanismos:

1. `hasPermission("x:write")` dentro do componente → esconde/desabilita botão.
2. `RequirePermission` na rota.
3. Filtro do array `navigation` na sidebar.

> A matriz completa papel × permissão está no documento **10 — Telas de Autenticação e Organização**.

---

## 9. Padrões de dados que o designer precisa conhecer

| Padrão | Por que importa para o design |
|---|---|
| **Fábrica de hooks CRUD** (`createCrudHooks`) | Listas, criação, edição e exclusão têm comportamento uniforme de cache — logo, podem ter comportamento uniforme de UI (mesmos estados, mesmos toasts). |
| **Chaves de query** `["entidade", filtros]` | Filtros mudam a chave → a lista recarrega. Daí a importância dos estados de *loading* sobre dados já exibidos (não substituir a tabela por spinner). |
| **Limite de URL do PostgREST** | Consultas com >200 identificadores não cabem na URL. Isso limita seleções em massa e obriga a UI a paginar/agrupar. |
| **RPCs pesadas serializadas** | Os 4 gráficos principais da Visão Executiva **não** carregam em paralelo — são enfileirados de propósito (concorrência derrubava o banco). A tela precisa comunicar "carregando em sequência" sem parecer travada. |
| **Teto de ~125s em chamadas pesadas** | Operações longas (execução de campanha, ETL) podem devolver erro sem que o trabalho tenha falhado. A UI precisa de estados "não sabemos" além de "sucesso/erro". |
| **Views materializadas com refresh agendado** | Os números do Dashboard e da Carteira podem estar defasados. Existe uma aba inteira (Materialização) e indicadores de frescor. O redesenho deve tornar a **idade do dado** visível. |

---

## 10. Restrições externas ao redesenho

O projeto é sincronizado com **Lovable.dev**. Regras duras herdadas (`.claude/skills/lovable-compatibility`):

| Nunca | Motivo |
|---|---|
| Remover `lovable-tagger` | Quebra a sincronização. |
| Mover `src/components/ui/` | Caminho fixo esperado pelo Lovable. |
| Mover `src/integrations/supabase/` | Idem. |
| Modificar `.lovable/` | Idem. |
| Usar import relativo | Sempre `@/`. |
| Cor hardcoded | Sempre CSS var / token. |
| Migrar para Next.js | Fora de escopo. |

**Consequência prática:** o redesenho pode reescrever qualquer componente de tela, mas os primitivos ficam em `src/components/ui/` e as cores continuam saindo de tokens.

---

## 11. Checklist estrutural do redesenho

- [ ] Shell `fixed inset-0` com scroller único preservado.
- [ ] Reset de scroll por `pathname` (não por `search`).
- [ ] Sidebar 256/64px com persistência em `localStorage` e tooltip no modo recolhido.
- [ ] Filtro de menu por permissão mantido.
- [ ] Invalidação total de cache na troca de organização mantida.
- [ ] Drawer mobile com backdrop, fechando ao navegar.
- [ ] Painel do Maestro empurrando o conteúdo (não sobrepondo).
- [ ] Modal acima de sheet (`z-60` > `z-50`).
- [ ] Estados de carregamento de página substituídos por skeleton (melhoria proposta).
- [ ] Padrão explícito de atualização manual mantido (não há refetch no foco).
- [ ] Editores de régua e broadcast continuam em tela cheia.
- [ ] `/docs` continua acessível sem sessão.
