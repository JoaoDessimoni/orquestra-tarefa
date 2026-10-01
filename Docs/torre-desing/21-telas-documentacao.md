# 21 · Telas de Documentação (Central de Docs, API e Fonte de Dados)

> Documento de análise de UX/produto do **frontend atual** da Torre de Controle (SaaS multi-tenant de cobrança da Finza), recorte **telas de documentação embutidas no produto**.
> Objetivo: permitir um redesenho completo da interface **sem perder nenhuma funcionalidade**.
> Tudo aqui foi extraído da leitura do código-fonte em `cobranca-finza/src/`. Onde o código não permite concluir, a linha é marcada como `⚠️ A confirmar: …`.
> Data de leitura do código: 2026-09-17.

---

## Índice

| # | Seção |
|---|---|
| 0 | Mapa das rotas de documentação |
| 1 | Hub da Central de Docs (`/central-docs`) |
| 2 | Pilar Negócio: catálogo + guia de tela |
| 3 | Pilar Tópicos: catálogo + artigo |
| 4 | Pilar Técnica: catálogo de átomos, página de átomo, AtomRail, tags |
| 5 | Pilar Serviço (API): catálogo, cartão de endpoint, testador |
| 6 | Pilar Novidades (Changelog) |
| 7 | Grafo de referência |
| 8 | Catálogo de blocos visuais de documentação (DocBlocks) |
| 9 | Documentação pública da API (`/docs`) |
| 10 | Documentação viva da Fonte de Dados (`/docs/fonte-de-dados`) |
| 11 | Estilos especiais `.fdd-*` |
| 12 | Documentação Especial (`/docs-especial`) e Portal (`/portal`) |
| 13 | Botão de documentação na sidebar e balão de novidades |
| 14 | Estados, responsividade e acessibilidade |
| 15 | Dores e oportunidades para o redesign |

---

## 0. Mapa das rotas de documentação

Fonte: `src/App.tsx` (bloco `AppRoutes`, linhas ~172-400).

Todas as rotas de documentação são **full-screen**: ficam **fora** do `AppLayout` (sem sidebar do app, sem topbar do app). Elas rolam a **window**, não um container interno — por isso existe o componente `ScrollToTop` em `src/App.tsx`, que reseta `window.scrollTo(0,0)` a cada troca de rota.

Todas são carregadas por `React.lazy` + `<Suspense fallback={<PageLoader />}>` (spinner circular centralizado em tela cheia — `src/App.tsx`, `PageLoader`).

### 0.1 Tabela de rotas

| Rota | Arquivo-fonte | Guards aplicados | Permissão | Público/Privado |
|---|---|---|---|---|
| `/docs` | `src/pages/DocsPage.tsx` | **nenhum** | — | **PÚBLICO** (sem login, sem org) |
| `/docs/fonte-de-dados` | `src/pages/FonteDeDadosDocs.tsx` | `ProtectedRoute` + `RequireOrg` + `RequirePermission` | `etl:read` | Privado |
| `/docs-especial` | `src/pages/DocsEspecialPage.tsx` | `ProtectedRoute` + `RequireOrg` | — (só login + org) | Privado |
| `/central-docs` | `src/pages/CentralDocsPage.tsx` | `ProtectedRoute` + `RequireOrg` | — (hub sempre visível) | Privado |
| `/central-docs/servico` | `src/pages/central-docs/ServicoCatalogPage.tsx` | + `RequireDocs` | `docs:servico` | Privado |
| `/central-docs/tecnica` | `src/pages/central-docs/TecnicaCatalogPage.tsx` | + `RequireDocs` | `docs:tecnica` | Privado |
| `/central-docs/atom/:id` | `src/pages/central-docs/atoms/AtomPage.tsx` | + `RequireDocs` | `docs:tecnica` | Privado |
| `/central-docs/tags` | `src/pages/central-docs/TagsPage.tsx` | + `RequireDocs` | `docs:tecnica` | Privado |
| `/central-docs/grafo` | `src/pages/central-docs/GraphPage.tsx` | + `RequireDocs` | `docs:tecnica` | Privado |
| `/central-docs/topicos` | `src/pages/central-docs/topics/TopicsCatalogPage.tsx` | + `RequireDocs` | `docs:topicos` | Privado |
| `/central-docs/topico/:id` | `src/pages/central-docs/topics/TopicPage.tsx` | + `RequireDocs` | `docs:topicos` | Privado |
| `/central-docs/negocio` | `src/pages/central-docs/negocio/NegocioCatalogPage.tsx` | + `RequireDocs` | `docs:negocio` | Privado |
| `/central-docs/negocio/:id` | `src/pages/central-docs/negocio/PageGuidePage.tsx` | + `RequireDocs` | `docs:negocio` | Privado |
| `/central-docs/changelog` | `src/pages/central-docs/changelog/ChangelogFeedPage.tsx` | + `RequireDocs` | `docs:changelog` | Privado |
| `/central-docs/changelog/:id` | `src/pages/central-docs/changelog/ChangelogPostPage.tsx` | + `RequireDocs` | `docs:changelog` | Privado |
| `/central-docs/:pillar` (catch-all) | `src/pages/central-docs/PillarDocPage.tsx` | `ProtectedRoute` + `RequireOrg` (gate de permissão **dentro** da página) | a do pilar resolvido | Privado |
| `/portal` e subrotas | `src/portal/shell/PortalLayout.tsx` + `src/portal/pages/*` | ⚠️ **não registradas em `src/App.tsx`** | — | ⚠️ A confirmar (ver §12.3) |

> **Ordem importa:** todas as rotas estáticas de `/central-docs/*` são declaradas **antes** de `/central-docs/:pillar`. O comentário no código é explícito: `"rota estática, precede o stub dinâmico :pillar"`. Qualquer redesenho que reordene rotas quebra o roteamento.

### 0.2 Os três guards

Fonte: `src/App.tsx`.

| Guard | O que checa | Falha → |
|---|---|---|
| `ProtectedRoute` | `useAuth().user` existe | `<Navigate to="/login">` preservando deep-link em `state.from` |
| `RequireOrg` | `!needsOrgSelection` | `<Navigate to="/select-organization">` preservando deep-link |
| `RequirePermission` | `hasPermission(permission)` | `<Navigate to="/">` (volta ao dashboard) |
| `RequireDocs` | `isSuperAdmin \|\| hasPermission(permission)` | `<Navigate to="/central-docs">` (volta ao **hub**, não ao app) |

`RequireDocs` é exclusivo da Central de Docs e tem duas diferenças de propósito (documentadas no comentário do arquivo):
1. **super_admin é god-mode** — o time Finza passa mesmo com papel baixo na org.
2. **Falha volta ao hub**, não ao app inteiro — o usuário fica dentro da documentação.

Enquanto `isLoading`, todos os guards renderizam `<PageLoader />`.

### 0.3 Sistema de permissões por pilar (RBAC)

Fonte: `src/contexts/OrganizationContext.tsx` (`ROLE_PERMISSIONS`) + `src/pages/central-docs/pillars.ts` (campo `permission`).

Cinco papéis: `owner > admin > manager > operator > viewer`. `owner` recebe `["*"]` (tudo). Além dos papéis, existe o **super_admin** (linha em `public.super_admins`, resolvido por RPC `is_super_admin(uuid)` — default `false` até retornar).

| Pilar | `permission` | owner | super_admin | admin | manager | operator | viewer |
|---|---|---|---|---|---|---|---|
| Serviço (API) | `docs:servico` | ✓ (`*`) | ✓ (god-mode) | ✗ | ✗ | ✗ | ✗ |
| Técnica | `docs:tecnica` | ✓ (`*`) | ✓ | ✗ | ✗ | ✗ | ✗ |
| Tópicos | `docs:topicos` | ✓ (`*`) | ✓ | ✗ | ✗ | ✗ | ✗ |
| Negócio | `docs:negocio` | ✓ (`*`) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Novidades (Changelog) | `docs:changelog` | ✓ (`*`) | ✓ | ✓ | ✓ | ✓ | ✓ |

Regra de negócio explícita no comentário de `ROLE_PERMISSIONS`:
> *"Central de Documentação — só owner (via `*`) e super_admin (god-mode no guard RequireDocs) veem os pilares de referência (Serviço/Técnica/Tópicos). admin, como manager/operator/viewer, vê apenas Negócio + Novidades."*

**Consequências visuais do gate (o redesign precisa preservar):**
- O hub `/central-docs` **nunca** esconde um pilar sem acesso: ele mostra o card com `opacity-60`, cursor default, e um selo `🔒 Sem acesso`. A intenção declarada é *"descoberta sem acesso"* — o usuário sabe que o pilar existe.
- A seção do **Grafo de referência** embutida no hub só é renderizada se `isSuperAdmin || hasPermission("docs:tecnica")` (variável `canSeeGraph`), porque o grafo expõe átomos técnicos/serviço.
- O banner destacado do Changelog também respeita o gate: `locked` → banner com `opacity-60`, sem CTA, com selo `🔒 Sem acesso`.
- A rota direta (URL colada) é bloqueada pelo `RequireDocs`, então o cadeado não é só cosmético.

---

## 1. Hub da Central de Docs (`/central-docs`)

**Identidade**

| Item | Valor |
|---|---|
| Rota | `/central-docs` |
| Arquivo | `src/pages/CentralDocsPage.tsx` (416 linhas) |
| Dados | `src/pages/central-docs/pillars.ts` |
| Permissão | Nenhuma para entrar (só login + org). Cada card aplica seu gate por conta própria. |
| Layout | Full-screen, fora do `AppLayout`. Wrapper `div.fdd-doc.min-h-screen.bg-background.text-foreground` |
| Largura de conteúdo | `mx-auto max-w-5xl px-5 pb-24 pt-14 sm:pt-20` |

**Objetivo.** Ser a porta de entrada única da documentação interna da Torre. O texto do hero declara a tese: separar **Referência** (cada endpoint/EF/tabela/RPC como página seca com backlinks automáticos) dos **Tópicos** (a narrativa que conecta tudo), ligados por um **grafo de referência** ponta a ponta — "da tela que você vê até a tabela no banco".

### 1.1 Anatomia visual (de cima para baixo)

| Zona | Elementos | Detalhes visuais |
|---|---|---|
| **1. Topbar fixa** | `<header>` `sticky top-0 z-40` | Borda inferior `border-border/70`, fundo `bg-background/85` com `backdrop-blur` (fallback `supports-[backdrop-filter]:bg-background/60`). Altura `h-14`. Conteúdo: link `← Voltar ao app` (rótulo some em telas `<sm`), divisor vertical `h-4 w-px bg-border`, badge quadrado `h-6 w-6 rounded bg-primary` com ícone `BookMarked`, texto `Central de Documentação` em `font-semibold`. |
| **2. Fundo decorativo** | 2 camadas `pointer-events-none absolute` | (a) grade blueprint: duas `linear-gradient` de 1px em `hsl(var(--foreground)/0.04)`, `background-size: 28px 28px`, altura `h-72`, `opacity-50`. (b) brilho: `radial-gradient(60% 100% at 50% 0%, hsl(var(--primary)/0.10), transparent 70%)`, `h-72`. |
| **3. Hero** | Pílula + H1 + duas linhas de texto | Pílula: `rounded-full border bg-card/60 px-3 py-1`, classe `fdd-mono`, `text-[11px] uppercase tracking-[0.2em] text-primary`, ícone `Network`, texto `documentação completa · grafo de referência`. H1: `text-5xl sm:text-7xl font-extrabold leading-[0.95] tracking-[-0.03em]` com o texto "Central de Documentação". Subtítulo: `text-2xl sm:text-3xl font-medium text-foreground/75` — *"Toda a Torre, do botão ao banco — e de volta."*. Parágrafo explicativo `text-lg text-justify` com `<strong>` em Referência / Tópicos / grafo de referência. |
| **4. Banner do Changelog** | `ChangelogFeature` | Ver §1.3. |
| **5. Grupos por camada** | `LAYER_ORDER.map(LayerGroup)` | Ver §1.4. |
| **6. Rodapé explicativo** | `<p class="mt-14 text-sm text-justify">` | Texto fixo: *"Cada pilar já abre sua própria página — mas o conteúdo ainda está sendo escrito…"*. ⚠️ **Nota para o redesign:** esse texto está desatualizado em relação ao código — os pilares Serviço/Técnica/Tópicos/Negócio/Changelog têm páginas reais e populadas. |
| **7. Grafo embutido** | `GraphFeature` (condicional) | Ver §1.5. |

### 1.2 Modelo de dados dos pilares (`pillars.ts`)

Fonte: `src/pages/central-docs/pillars.ts`.

```ts
type Layer = "referencia" | "narrativa" | "manual" | "novidades";

type Pillar = {
  id: string;
  title: string;
  description: string;      // parágrafo longo, justificado no card
  highlights: string[];     // chips "Inclui"
  monoChips?: boolean;      // chips em fonte mono (técnico) vs normal (negócio)
  layer: Layer;
  icon: LucideIcon;
  href?: string;            // SEM href → selo "Em breve" e card não navega
  permission: string;       // RBAC
};
```

**Contrato de evolução (documentado no cabeçalho do arquivo):** *"Quando um pilar ganha sua página, basta definir o `href` aqui: o card no hub vira `<Link>` e o selo 'Em breve' some sozinho."* — Uma única fonte de verdade alimenta o hub **e** o stub `PillarDocPage`.

**Os 5 pilares definidos hoje** (o comentário do arquivo ainda diz "4 pilares" — o Changelog foi adicionado depois):

| id | Título | Camada | Ícone (lucide) | `monoChips` | `href` | Permissão |
|---|---|---|---|---|---|---|
| `servico` | Serviço (API) | `referencia` | `Plug` | ✓ | `/central-docs/servico` | `docs:servico` |
| `tecnica` | Técnica | `referencia` | `Boxes` | ✓ | `/central-docs/tecnica` | `docs:tecnica` |
| `topicos` | Tópicos | `narrativa` | `Compass` | — | `/central-docs/topicos` | `docs:topicos` |
| `negocio` | Negócio | `manual` | `GraduationCap` | — | `/central-docs/negocio` | `docs:negocio` |
| `changelog` | Novidades | `novidades` | `Megaphone` | — | `/central-docs/changelog` | `docs:changelog` |

**Chips "Inclui" por pilar** (`highlights`, renderizados como pílulas):

| Pilar | Chips |
|---|---|
| Serviço | Endpoints · MCP Tools · Eventos de webhook · Autenticação |
| Técnica | Edge Functions · Tabelas / Views / MV · RPCs · Crons · Triggers · Helpers · Variáveis · Integrações · Hooks |
| Tópicos | ETL ponta-a-ponta · Campanha v2 · Envio de ação · Atribuição · Refresh da MV · Multi-tenancy |
| Negócio | Dashboard · Carteira · Campanhas · Réguas · Filtros · Ações · Agente IA · Configurações · Glossário |
| Novidades | Novidades · Melhorias · Correções · Avisos · Reações |

**As 4 camadas (`LAYERS`)** — cada uma vira um cabeçalho de grupo:

| Camada | `label` | `sub` | Ícone |
|---|---|---|---|
| `referencia` | Referência atômica | "Seca, granular, com backlinks automáticos" | `Layers` |
| `narrativa` | Narrativa | "A porta de entrada que costura tudo" | `Network` |
| `manual` | Manual do usuário | "Como usar, marcando quem pode" | `Sparkles` |
| `novidades` | Novidades | "O que muda na Torre, em ordem cronológica" | `Megaphone` |

`LAYER_ORDER = ["referencia", "narrativa", "manual", "novidades"]` define a ordem vertical.

Helper `getPillarBySlug(slug)`: resolve o último segmento do `href` → `Pillar`. É o que faz `/central-docs/:pillar` funcionar.

### 1.3 Banner destacado do Changelog (`ChangelogFeature`)

O Changelog **não entra no grid de pilares** — a constante `CHANGELOG_ID = "changelog"` é filtrada para fora de `LayerGroup`, e a camada `novidades` fica com zero pilares (o `LayerGroup` retorna `null` quando o grupo fica vazio). Em vez disso ele ganha um **banner full-width** logo abaixo do hero.

**Aparência:**
- Container: `relative mt-10 block overflow-hidden rounded-2xl border-2 border-primary/30 bg-gradient-to-br from-primary/[0.12] via-card to-primary/[0.04] p-5 sm:p-6`.
- Textura de fundo: `radial-gradient(currentColor 1px, transparent 1px)` com `background-size: 18px 18px`, `opacity-[0.06]` → `0.1` no hover (trilha pontilhada).
- Hover (só quando desbloqueado): `-translate-y-0.5`, borda `primary/55`, sombra `0_24px_50px_-26px hsl(var(--primary)/0.95)`.
- Ícone grande: quadrado `h-12 w-12 rounded-2xl bg-primary text-primary-foreground` com `Megaphone` de `h-6 w-6` e sombra projetada.
- Microtag: pílula `rounded-full border-primary/40 bg-primary/15` + `fdd-mono text-[10px] uppercase tracking-[0.2em]` + ícone `Sparkle` + texto "Novidades".
- Título: `text-2xl font-bold`; subtítulo fixo: *"O que muda na Torre, em ordem cronológica — novidades, melhorias, correções e avisos."*
- **Teaser do post mais recente** (`ENTRIES[0]`): badge do tipo do post (cor via `CHANGELOG_TYPE_META[type].badgeClass` + ícone do tipo), título truncado, e a data formatada por `formatChangelogDate`.
- **CTA**: botão sólido `bg-primary text-primary-foreground` com texto "Ver novidades" + `ArrowRight`, que desliza `translate-x-0.5` no hover do card.

**Estados:**

| Estado | Condição | Render |
|---|---|---|
| Bloqueado | `!isSuperAdmin && !hasPermission("docs:changelog")` | `<div>` não-clicável, `opacity-60`, `cursor-default`, `aria-disabled`; selo `🔒 Sem acesso`; **sem CTA** |
| Com não-lidos | `!locked && unreadCount > 0` | Badge sólido `bg-primary text-primary-foreground` com `{badge} nova/novas` (singular/plural correto) |
| Normal | demais | `<Link>` para `/central-docs/changelog` |

`unreadCount` e `badge` vêm do hook `useChangelogUnread()` (ver §6.6).

### 1.4 Grupo de camada e card de pilar

**`LayerGroup`** (`section.mt-14.first:mt-12`):
- Cabeçalho da camada: faixa `rounded-xl border border-primary/15 bg-gradient-to-r from-primary/10 via-primary/5 to-transparent px-3.5 py-3`, contendo barra de acento vertical (`h-6 w-1 rounded-full bg-primary`), quadrado de ícone `h-8 w-8 rounded-lg bg-primary` e o `label` em `text-lg font-semibold`. Abaixo, o `sub` em `text-sm text-muted-foreground` com `pl-4`.
- Grid: `mt-6 grid gap-4`, virando `sm:grid-cols-2` **apenas quando o grupo tem mais de 1 pilar** (hoje: `referencia` = 2 colunas; `narrativa` e `manual` = 1 coluna full-width).

**`PillarCard`:**
- Base: `group relative flex h-full flex-col overflow-hidden rounded-2xl border border-t-2 border-border border-t-primary/50 bg-gradient-to-br from-card to-primary/[0.04] p-5 transition-all` — note a **borda superior de 2px em primary/50**, marca visual do card de pilar.
- Textura: grade quadriculada (`linear-gradient` horizontal + vertical de 1px em `currentColor`), `background-size: 24px 24px`, `opacity-[0.05]` → `0.09` no hover.
- Cabeçalho: quadrado de ícone `h-11 w-11 rounded-xl bg-primary text-primary-foreground` + título `text-xl font-semibold text-primary` (truncado).
- Selo à direita (mutuamente exclusivo): `🔒 Sem acesso` (locked) **ou** `Em breve` (sem `href`). Ambos em pílula `border-border bg-muted/60 text-[11px]`.
- Descrição: `text-sm text-muted-foreground text-justify`.
- Bloco "Inclui": rótulo `text-[10px] uppercase tracking-wider text-primary/70` + chips `rounded-md border-border bg-muted/40 px-2.5 py-1 text-xs`; no hover do card os chips viram `border-primary/30 bg-primary/5`. Chips ganham `fdd-mono` quando `pillar.monoChips`.
- Hover (desbloqueado + com href): `-translate-y-0.5`, `border-primary/50`, sombra `0_20px_44px_-26px`.

### 1.5 Grafo embutido (`GraphFeature`)

Renderizado **no final da página** e somente se `canSeeGraph`.

- Moldura: `rounded-2xl border border-primary/20 bg-gradient-to-br from-primary/[0.07] via-card to-primary/[0.03] p-1.5`.
- Cabeçalho: ícone `Network` em quadrado `h-7 w-7 bg-primary`, título "Grafo de referência", parágrafo explicativo — *"Tudo conectado a tudo: cada nó é um átomo; as linhas são as relações entre eles. Arraste para girar, use o scroll para dar zoom e clique num nó para abrir."*
- CTA à direita: botão outline `border-primary/30 bg-primary/10 text-primary` → "Abrir em tela cheia" → `/central-docs/grafo`.
- Viewport: `relative mt-4 overflow-hidden rounded-xl border border-border bg-background/40` contendo `<CentralDocsGraph className="h-[60vh] w-full" />`.
- **Carregamento sob demanda**: `React.lazy` no import do `CentralDocsGraph` — comentário explícito: *"Grafo 3D (three.js) — carregado SOB DEMANDA para não entrar no bundle principal"*. O fallback é `GraphSectionLoading`: spinner `h-7 w-7 border-b-2 border-primary` + texto "Carregando o grafo 3D…".

### 1.6 Stub de pilar (`/central-docs/:pillar`)

**Identidade:** `src/pages/central-docs/PillarDocPage.tsx` (137 linhas). Rota catch-all.

Comentário do arquivo: *"Uma única página reutilizável por rota-param, em vez de 4 arquivos quase iguais."*

Lógica em cascata:
1. `getPillarBySlug(slug)` → se não resolver: `<Navigate to="/central-docs" replace />` (**sem 404**).
2. Gate: `!isSuperAdmin && !hasPermission(pillar.permission)` → tela de bloqueio centralizada: ícone `Lock h-8 w-8`, frase *"Você não tem acesso ao pilar **X**."* e link "Voltar à Central de Documentação".
3. Caso contrário: renderiza o stub.

**Anatomia do stub** (reaproveita a mesma linguagem visual do hub): topbar sticky com `← Central de Documentação` (rótulo curto "Central" em mobile) + `BookMarked` + título do pilar; mesmas 2 camadas decorativas (grade 28px + brilho radial); `max-w-5xl`; cabeçalho com ícone `h-12 w-12 rounded-xl bg-primary/10 text-primary` + H1 `text-4xl sm:text-5xl font-extrabold text-primary`; descrição do pilar justificada; **aviso tracejado** `rounded-2xl border border-dashed bg-muted/30` com ícone `Hammer` e o texto "Conteúdo em construção"; e por fim o bloco "O que esta seção vai cobrir" com os `highlights` em chips maiores (`px-3 py-1.5 text-sm`).

> ⚠️ **Situação real hoje:** como todos os 5 pilares têm rota estática dedicada declarada **antes** do catch-all, este stub é praticamente **inalcançável** pelos slugs conhecidos. Ele só apareceria se um `href` novo fosse adicionado em `pillars.ts` sem rota estática correspondente. Para o redesign: é uma tela de fallback/andaime, não um destino real.

---

## 2. Pilar Negócio: catálogo + guia de tela

### 2.1 O modelo `PageGuide`

Fonte: `src/pages/central-docs/negocio/types.ts`.

Cada guia documenta **UMA tela do app**, em linguagem de negócio. O comentário do arquivo é explícito sobre a diferença entre os três pilares: *"Diferente dos Tópicos (narrativa de fluxo) e dos Átomos (referência técnica), cada guia aqui descreve UMA tela em linguagem de negócio: pra que serve, cada KPI/gráfico/coluna/botão/modal, e quem pode usar."*

```ts
interface PageGuide {
  id: string;            // url-safe (ex.: "dashboard")
  title: string;         // nome de negócio da tela
  group: string;         // categoria no catálogo
  route?: string;        // rota REAL do app documentada
  icon?: string;         // nome de ícone lucide (string, resolvido por mapa)
  summary: string;       // 1-2 frases; abre o guia e vai no card
  permissions?: string[];// perfis que usam → selos
  keyAtoms?: string[];   // átomos técnicos que sustentam a tela
  topics?: string[];     // tópicos narrativos relacionados
  sections: TopicSection[]; // REUSA os blocos ricos dos Tópicos
}
```

**Decisão de arquitetura crítica para o redesign:** o pilar Negócio **não tem blocos próprios**. Ele reusa `TopicSection`/`TopicBlock` dos Tópicos e o renderer compartilhado `shared/DocBlocks`. O catálogo de blocos do §8 vale para os **dois** pilares.

**Registry** (`negocio/registry.ts`): agrega `./data/*.ts` via `import.meta.glob(..., { eager: true })` — cada arquivo exporta um `PageGuide[]` e é descoberto automaticamente, **sem registro manual**. Funções: `GUIDES` (achatado), `getGuide(id)`, `getGuidesByGroup()` (agrupa preservando ordem de primeira aparição).

### 2.2 Guias existentes (23 arquivos em `negocio/data/`)

| Grupo | Guia (`id`) | Título | Rota documentada | Ícone | Perfis (`permissions`) |
|---|---|---|---|---|---|
| Acesso | `login` | Login | `/login` | `LogIn` | pública |
| Acesso | `criar-conta` | Criar Conta | `/signup` | `UserPlus` | pública |
| Acesso | `aceitar-convite` | Aceitar Convite | `/accept-invite` | `MailCheck` | token de convite |
| Acesso | `selecionar-organizacao` | Selecionar Organização | `/select-organization` | `Building2` | autenticado |
| Operação | `dashboard` | Dashboard | `/` | `LayoutDashboard` | owner·admin·manager·operator·viewer |
| Operação | `gestao-carteira` | Gestão de Carteira | `/portfolio` | `Briefcase` | todos |
| Operação | `acoes` | Ações | `/actions` | `Activity` | todos |
| Operação | `filtros` | Filtros | `/filters` | `Filter` | owner·admin·manager·operator |
| Operação | `disparos` | Disparos | `/disparos` | `Send` | owner·admin·manager·operator |
| Cobrança | `campanhas` | Campanhas | `/campaigns` | `Target` | todos |
| Cobrança | `reguas-cobranca` | Réguas de Cobrança | `/reguas-cobranca` | `GitBranch` | todos |
| Cobrança | `editor-regua` | Editor de Régua (Sequencial) | `/reguas-cobranca/:id/editor` | `GitBranch` | todos |
| Cobrança | `editor-broadcast` | Editor de Disparo Pontual | `/broadcasts/:id/editor` | `Megaphone` | owner·admin·manager |
| Cobrança | `templates` | Templates de Mensagem | `/templates` | `MessageSquareText` | todos |
| Dados | `fonte-de-dados` | Fonte de Dados | `/etl` | `Database` | owner·admin·manager |
| Dados | `mapa-dos-dados` | O Mapa dos Dados | *(sem rota)* | `Waypoints` | todos |
| IA | `agente-ia` | Agente IA | `/agent-ia` | `Bot` | owner·admin·manager |
| Análise | `relatorio-acoes` | Relatório de Ações com IA | `/actions/report` | `Sparkles` | todos |
| Configuração | `configuracoes` | Configurações | `/settings` | `Settings` | owner·admin·manager |
| Configuração | `integracoes` | Integrações | `/integrations` | `Puzzle` | owner·admin·manager |
| Documentação | `documentacao-api` | Documentação (API) | `/docs` | `FileText` | `[]` (rota pública) |
| Documentação | `doc-fonte-de-dados` | Doc viva da Fonte de Dados | `/docs/fonte-de-dados` | `Database` | owner·admin·manager |
| Documentação | `documentacao-especial` | Documentação Especial | `/docs-especial` | `Library` | todos |

> Nota: o campo `permissions` do guia é **texto descritivo**, não um gate — ele só alimenta os selos "Quem usa". Valores livres aparecem (`"pública"`, `"autenticado"`, `"token de convite"`) e o `ROLE_LABELS` só traduz os 5 papéis canônicos, caindo no valor bruto quando não reconhece.

> **A documentação documenta a si mesma:** existe um grupo "Documentação" com guias de negócio sobre `/docs`, `/docs/fonte-de-dados` e `/docs-especial`. Um redesign que remova uma dessas telas precisa remover/atualizar o guia correspondente.

### 2.3 Catálogo `/central-docs/negocio`

**Identidade:** `src/pages/central-docs/negocio/NegocioCatalogPage.tsx` (166 linhas), permissão `docs:negocio` (via rota), largura `max-w-5xl`, `pt-12 sm:pt-16`.

**Anatomia:**

| Zona | Detalhe |
|---|---|
| Topbar sticky | `← Central de Documentação` (mobile: "Central") + divisor + `BookMarked` + título do pilar. Mesmo padrão do hub. |
| Fundo | Mesmas 2 camadas (grade 28px `opacity-50` + brilho radial), idênticas ao hub. |
| Cabeçalho do pilar | Ícone `h-12 w-12 rounded-xl bg-primary text-primary-foreground` + sombra; H1 `text-4xl sm:text-5xl font-extrabold text-primary` com o título do pilar; parágrafo `text-lg text-justify` com `PILLAR.description` (vindo de `pillars.ts` — não duplicado). |
| Grupos | Um `<section class="mt-12">` por grupo. Cabeçalho do grupo: faixa `rounded-lg border-b border-border/70 bg-gradient-to-r from-primary/[0.07] via-primary/[0.03] to-transparent px-2.5 pb-3 pt-2`, com barra de acento `h-6 w-1 bg-primary`, título `text-lg font-semibold` e **contador** `(N)` em `text-sm text-muted-foreground`. |
| Grid | `grid gap-4 sm:grid-cols-2` |
| Vazio | `groups.length === 0` → texto: *"Nenhum guia publicado ainda. O manual das telas está sendo escrito."* |

**`GuideCard`:** `<Link>` para `/central-docs/negocio/:id`. Mesma linguagem do `PillarCard` (borda superior `border-t-2 border-t-primary/50`, gradiente `from-card to-primary/[0.04]`, hover `-translate-y-0.5` + sombra `0_18px_40px_-26px`), mas menor: ícone `h-9 w-9 rounded-xl bg-primary`, título `text-lg` que vira `text-primary` no hover do card, resumo justificado, e um rodapé com **duas pílulas**:
1. `N seções` / `1 seção` — pílula primária `border-primary/25 bg-primary/10 text-primary` (plural correto).
2. A rota real, em pílula `fdd-mono border-border bg-muted/40` — renderizada só se `guide.route` existir.

**Resolução de ícone:** `ICONS` é um mapa `Record<string, LucideIcon>` com **11 ícones** hardcoded (`LayoutDashboard, Wallet, Megaphone, GitBranch, Filter, Send, Bot, Settings, BookOpen, Users, Waypoints`). `resolveIcon(name)` cai no ícone do pilar (`GraduationCap`) quando o nome não está no mapa.

> ⚠️ **Bug latente para o redesign:** vários guias declaram ícones que **não estão** no mapa `ICONS` (`LogIn`, `UserPlus`, `MailCheck`, `Building2`, `Briefcase`, `Activity`, `Target`, `MessageSquareText`, `Database`, `Puzzle`, `Sparkles`, `FileText`, `Library`). Todos esses caem silenciosamente no fallback `GraduationCap` — ou seja, **a maior parte dos cards do catálogo hoje mostra o mesmo ícone**. Um redesign deveria importar os ícones dinamicamente ou completar o mapa.

### 2.4 Guia de tela `/central-docs/negocio/:id`

**Identidade:** `src/pages/central-docs/negocio/PageGuidePage.tsx` (301 linhas). Permissão `docs:negocio` (dupla: rota + gate interno). Largura `max-w-6xl`, grade `lg:grid-cols-[220px_minmax(0,1fr)] lg:gap-10`; a coluna de conteúdo é limitada a `lg:max-w-3xl` (medida de leitura).

O comentário do arquivo declara: *"Espelha a `TopicPage` (mesmo layout, rail scroll-spy, barra de progresso, renderer compartilhado de blocos) — mas o cabeçalho troca os 'keyAtoms/chips' por: a ROTA real da tela (chip mono) + os SELOS de quem pode usar."*

**Anatomia (ordem de leitura):**

| # | Elemento | Detalhe |
|---|---|---|
| 1 | Topbar sticky + **barra de progresso** | Dois links de breadcrumb: `← Negócio` e `BookMarked Central de Documentação`. Abaixo, `ReadingProgress`: barra `h-0.5 bg-primary` absoluta no rodapé do header, largura = `scrollTop / (scrollHeight - clientHeight)`, atualizada por `requestAnimationFrame` em listeners `scroll` e `resize` (ambos `passive`), com `transition-[width] duration-150`. `aria-hidden`. |
| 2 | Rail lateral (`AtomRail`) | Desktop: `<aside sticky top-20>`. Mobile: `AtomRailMobile` no topo do conteúdo. Seções: "Visão geral" (ícone `Info`) + uma por seção do guia (ícone `Workflow`). **Sem** a seção "Átomos citados" (que só existe nos Tópicos). |
| 3 | Cabeçalho (`#guide-overview`) | Duas pílulas: `🎓 Manual da tela` (primária: `border-primary/25 bg-primary/10 text-primary`) e o `group` do guia (neutra). Título: barra de acento vertical `w-1 bg-primary` + H1 `text-3xl sm:text-4xl font-extrabold`. Resumo `text-lg text-justify`. |
| 4 | Linha de metadados | (a) **Chip da rota real** — `<Link to={guide.route}>` com ícone `SquareArrowOutUpRight`, texto em `fdd-mono`, `title="Abrir esta tela no app"`, hover `-translate-y-0.5` + `border-primary/50`. **É um link de saída da documentação direto para a tela do produto.** (b) **Selos "Quem usa"** — rótulo `🛡 QUEM USA` em `text-[10px] uppercase` + uma pílula `rounded-full border-primary/25 bg-primary/10 text-primary` por perfil, traduzido por `ROLE_LABELS` (`owner`→Owner, `admin`→Admin, `manager`→Gerente, `operator`→Operador, `viewer`→Visualizador). |
| 5 | Seções do guia | Cada uma envolta em `SectionReveal`, `id` = `s.id`, `scroll-mt-24`, classe `group/sec` (necessária para a âncora `#` aparecer no hover). Renderiza `SectionHeader` (ícone `Workflow` + âncora), depois `lead` (`RichBody`), depois `blocks` (`BlockRenderer`), depois `body` legado. |
| 6 | Faixa "Para aprofundar" | Só aparece se houver tópicos **ou** átomos relacionados. Cabeçalho em faixa `rounded-xl border bg-muted/30` com barra `bg-primary/60`, título "Para aprofundar" + tag `opcional`. Parágrafo: *"Este manual é em linguagem de negócio. Se quiser entender o que acontece nos bastidores desta tela, siga as trilhas abaixo…"*. Contém `TopicBacklinks` ("Como funciona por dentro" · hint "a narrativa do fluxo") e `AtomBacklinks` ("Peças técnicas" · hint "o que sustenta a tela"). |
| 7 | Faixa "Mencionado nas Novidades" | `ChangelogBacklinks` com os posts que citam este guia. Só renderiza se houver itens. |

**Cadeado por faixa (comportamento importante):** as faixas de aprofundamento navegam para **outros pilares**. Se o leitor não tem `docs:topicos` / `docs:tecnica`, a faixa **continua visível, porém fosca**: o ícone vira `Lock`, aparece a micro-legenda (`"Disponível para perfis com acesso aos Tópicos"` / `"…à Técnica"`) e os chips ficam `opacity-50 blur-[2px] [pointer-events:none]` + `inert`. Ou seja: **o leitor de negócio vê que existe aprofundamento, mas não entra** — é descoberta deliberada, não ocultação.

**Estados:**

| Estado | Render |
|---|---|
| `id` não resolve | `<Navigate to="/central-docs/negocio" replace />` |
| Sem `docs:negocio` (e não super_admin) | Tela centralizada: `Lock h-8 w-8`, *"Você não tem acesso ao manual de Negócio."*, link "Voltar à Central de Documentação" |
| Sem cross-links | Faixas simplesmente não renderizam (`count === 0` → `null` no `CrossLinkBand`) |

### 2.5 Sistema de cross-links (`shared/crosslinks.ts`)

Funções **puras** que derivam backlinks em tempo de leitura a partir dos 3 registries. O comentário do arquivo declara o princípio: *"Nada é duplicado: as relações já moram nos dados… aqui só as cruzamos e deduplicamos."* e *"Nenhuma função quebra com curadoria incompleta"* (ids inexistentes são ignorados).

| Função | Origem → Destino | Regra |
|---|---|---|
| `getTopicsForAtom(atomId)` | átomo → tópicos | re-export de `topics/registry` |
| `getGuidesForAtom(atomId)` | átomo → guias | guias cujo `keyAtoms` contém o id |
| `getTopicsForGuide(guide)` | guia → tópicos | **união** de (1) `guide.topics` curado + (2) tópicos cujos átomos intersectam `guide.keyAtoms`, dedup por id, curados primeiro |
| `getAtomsForGuide(guide)` | guia → átomos | só `guide.keyAtoms` |
| `getGuidesForTopic(topic)` | tópico → guias | reverso: `g.topics` cita o tópico **OU** `g.keyAtoms` intersecta `topicAtomIds(topic)` |
| `getChangelogForAtom/Topic/Guide` | doc → posts | re-export dos índices reversos do changelog |

`topicAtomIds(topic)` (em `topics/registry.ts`) é a função que torna o grafo completo: varre `keyAtoms`, campos legados (`section.atoms`, `section.steps[].atoms`) **e** blocos ricos recursivamente (`kind:"atoms"` → `ids`; `kind:"steps"` → `items[].atoms`; `kind:"flow"` → `frames[].atom`; `kind:"subBlock"` → recursão).

### 2.6 Componentes de backlink (`shared/CrossLinkChips.tsx`)

| Componente | Ícone | Destino | Observações |
|---|---|---|---|
| `TopicChip` | `Compass` (em quadrado `bg-primary/15`) | `/central-docs/topico/:id` | `title` = resumo do tópico (tooltip nativo) |
| `GuideChip` | `GraduationCap` | `/central-docs/negocio/:id` | idem |
| `ChangelogChip` | ícone do tipo do post | `/central-docs/changelog/:id` | cor do ícone vem de `CHANGELOG_TYPE_META` |
| `AtomLink` (em `topics/AtomLink.tsx`) | ícone do `kind` do átomo, em badge **sólido** | `/central-docs/atom/:id` | Título em `fdd-mono`. **Id órfão** → `<span class="fdd-mono text-xs text-muted-foreground">{id}</span>` (mostra o id esmaecido, sem link e sem quebrar) |

Todos compartilham a mesma assinatura visual: `rounded-md border border-border bg-card px-2 py-1 text-xs`, hover `-translate-y-0.5 border-primary/50 text-primary` + sombra `0_6px_16px_-10px`, e o mesmo efeito no `focus-visible` (acessível por teclado) com `ring-2 ring-primary/40`. O badge interno escala `scale-110` no hover.

**`CrossLinkBand`** é o container comum: `rounded-2xl border bg-muted/20 p-4`, cabeçalho com quadrado de ícone `h-7 w-7 rounded-lg bg-primary/10`, título `text-[10px] uppercase tracking-wider` e hint opcional (`· {hint}`). Retorna `null` quando `count === 0`.

**Faixas prontas:** `TopicBacklinks` (default "Explicado nos Tópicos"), `GuideBacklinks` (título obrigatório — varia por contexto), `AtomBacklinks` ("Peças técnicas"), `ChangelogBacklinks` ("Mencionado nas Novidades" · "o que mudou por aqui" — **nunca** tem cadeado, porque todos os perfis têm `docs:changelog`).

---

## 3. Pilar Tópicos: catálogo + artigo

### 3.1 O modelo `Topic`

Fonte: `src/pages/central-docs/topics/types.ts`.

```ts
interface Topic {
  id: string;            // url-safe
  title: string;
  group: string;         // categoria no catálogo
  summary: string;       // lead — abre o artigo e vai no card
  tldr?: string[];       // "Em 30 segundos"
  keyAtoms?: string[];   // chips "comece por aqui"
  sections: TopicSection[];
}

interface TopicSection {
  id: string; title: string; lead?: RichText;
  blocks?: TopicBlock[];   // PREFERIDO
  steps?: TopicStep[];     // LEGADO
  body?: RichText;         // LEGADO
  callouts?: AtomCallout[];// LEGADO
  atoms?: string[];        // LEGADO
}
```

O tipo carrega uma **dívida técnica declarada**: 4 campos marcados `(Legado)` com a instrução "preferir `blocks: [{kind:…}]`". A `TopicPage` ainda renderiza os 4 caminhos legados, com markup duplicado (a lista de `steps` é reimplementada inline em vez de usar o `StepsList` do `DocBlocks`). **Oportunidade clara para o redesign: colapsar em um único caminho `blocks`.**

**Registry:** mesmo padrão glob do Negócio (`topics/registry.ts`), com `TOPICS`, `getTopic(id)`, `getTopicsByGroup()`, `topicAtomIds(t)` e `getTopicsForAtom(atomId)`.

### 3.2 Tópicos existentes (20 arquivos em `topics/data/`)

| Grupo | `id` | Título |
|---|---|---|
| Dados | `etl-ponta-a-ponta` | ETL ponta-a-ponta |
| Dados | `fonte-de-dados` | Fonte de Dados — configurar de onde vêm os títulos |
| Dados | `refresh-da-mv` | Refresh da Materialized View |
| Dados | `status-canonicos` | Status canônicos — o vocabulário da Torre |
| Dados | `variaveis` | Variáveis `{{X}}` — de onde vêm e como são resolvidas |
| Cobrança | `campanha-v2` | Campanha v2 — do gatilho à ação |
| Cobrança | `reguas-workflows` | Réguas & Workflows — a estrutura da cobrança |
| Cobrança | `envio-de-acao` | Envio de uma ação de cobrança |
| Cobrança | `acoes-status` | Ações — ciclo de vida, status e fila |
| Cobrança | `atribuicao` | Atribuição de pagamento |
| Cobrança | `filtros-portfolios` | Filtros & Portfolios — segmentar a carteira |
| Cobrança | `blocklist` | Blocklist — quem não pode ser cobrado |
| Cobrança | `selos-tags` | Selos & Tags — marcar contatos, contratos e conversas |
| IA | `agente-ia` | Agente de IA (Maestro) e o funil |
| IA | `rag` | RAG — base de conhecimento do agente |
| Integrações | `integracao-api` | Integrar via API |
| Integrações | `webhooks` | Webhooks de pagamento e comunicação |
| Integrações | `meta-templates` | Templates WhatsApp / Meta |
| Plataforma | `multi-tenancy` | Multi-tenancy — schema por organização |
| Plataforma | `observabilidade` | Observabilidade — health check e alertas |

### 3.3 Catálogo `/central-docs/topicos`

**Identidade:** `src/pages/central-docs/topics/TopicsCatalogPage.tsx` (128 linhas). Permissão `docs:topicos`. `max-w-5xl`.

Estruturalmente **idêntico** ao catálogo de Negócio (mesma topbar, mesmas camadas de fundo, mesmo cabeçalho de pilar, mesmos cabeçalhos de grupo com contador, mesmo grid `sm:grid-cols-2`). Três diferenças no card (`TopicCard`):

1. O ícone é **fixo** `Compass` (não há mapa de ícones por item).
2. A segunda pílula do rodapé é `N átomos citados` (neutra), calculada por `topicAtomIds(topic).length` — **não** a rota.
3. Vazio: *"Nenhum tópico publicado ainda. Os artigos estão sendo escritos."*

### 3.4 Artigo `/central-docs/topico/:id`

**Identidade:** `src/pages/central-docs/topics/TopicPage.tsx` (321 linhas). Permissão `docs:topicos`. `max-w-6xl` com a mesma grade `[220px_minmax(0,1fr)]` do guia de Negócio.

O cabeçalho do arquivo descreve o repertório interativo: *"scroll-spy real + barra de progresso de leitura, revelação por scroll com stagger, FlowTimeline que 'desenha' o conector + payload colapsável, stats com count-up, código com botão copiar, tabela com header sticky, e âncoras (#) por seção. Tudo respeita `prefers-reduced-motion` e usa só tokens."*

**Diferenças em relação ao guia de Negócio:**

| Aspecto | Tópico | Guia de Negócio |
|---|---|---|
| Pílula de tipo | `🧭 Tópico` | `🎓 Manual da tela` |
| Breadcrumb | `← Tópicos` | `← Negócio` |
| Bloco extra no cabeçalho | **"Em 30 segundos"** (`tldr`) + chips "Comece por estes átomos" (`keyAtoms`) | chip da rota real + selos "Quem usa" |
| Seção final fixa | **"Átomos citados"** (`#topic-atoms`, ícone `Boxes`) — sempre presente, no rail | — |
| Rail | "Visão geral" + seções + "Átomos citados" | "Visão geral" + seções |
| Backlinks | `GuideBacklinks` ("Veja também nas telas" · "onde isso aparece no produto") + `ChangelogBacklinks` | faixa "Para aprofundar" (Tópicos + Átomos, com cadeado) + `ChangelogBacklinks` |
| Caminhos legados | renderiza `steps`, `body`, `callouts`, `atoms` | renderiza só `lead`, `blocks`, `body` |

**Bloco "Em 30 segundos" (exclusivo do Tópico):** container `rounded-2xl border border-primary/20 bg-gradient-to-br from-card to-primary/[0.06] p-4` com sombra `0_18px_44px_-30px`, rótulo `• EM 30 SEGUNDOS` em `text-[10px] uppercase tracking-wider text-primary/80` com um ponto `h-1.5 w-1.5 rounded-full bg-primary`, e o conteúdo via `RichBody` (array → bullets).

**Seção "Átomos citados":** `SectionHeader` com ícone `Boxes`, o texto *"Cada peça abaixo tem sua própria página (ficha técnica + conexões). Clique para mergulhar no detalhe."*, e `AtomChips` com **todos** os ids derivados de `topicAtomIds(topic)`.

**Estados:** `id` inválido → `<Navigate to="/central-docs/topicos" replace />`. Sem permissão → tela de cadeado ("Você não tem acesso aos Tópicos.").

### 3.5 Rail lateral (`AtomRail`) — compartilhado por Tópicos, Negócio e Técnica

**Arquivo:** `src/pages/central-docs/AtomRail.tsx` (244 linhas). Exporta `AtomRail` (desktop), `AtomRailMobile` (<lg) e o tipo `RailSection { id, label, icon }`.

**Diferencial de UX documentado no arquivo:** o scroll-spy **não escolhe um ativo único** — ele destaca **TODAS** as seções visíveis na viewport simultaneamente. O comentário justifica: *"Isso elimina o 'pisca/escolhe a errada' do scroll-spy clássico quando várias seções aparecem ao mesmo tempo."* Se 3 seções estão na tela, 3 itens brilham.

| Aspecto | Implementação |
|---|---|
| Detecção | Hook local `useVisibleSections(ids)`: um único `IntersectionObserver`, `threshold: 0` (basta 1px), `rootMargin: "-72px 0px 0px 0px"` para descontar o header `h-14` (≈56px) com folga — a seção só "conta" quando está de fato abaixo da barra fixa |
| Re-observação | Chave estável `ids.join("\|")`; re-observa só quando a lista realmente muda; `io.disconnect()` no cleanup |
| Clique | `useScrollToSection()`: `el.scrollIntoView({ behavior: reduce ? "auto" : "smooth", block: "start" })` — lê `matchMedia("(prefers-reduced-motion: reduce)")` |
| Item ativo (`RailLink`) | **Só a fonte brilha**: `font-medium text-primary drop-shadow-[0_0_6px_hsl(var(--primary)/0.45)]`. Sem fundo, sem barra de acento. `aria-current="true"` |
| Item inativo | `text-muted-foreground hover:text-foreground`; ícone `text-muted-foreground/70` |
| Container desktop | `<aside class="sticky top-20 hidden max-h-[calc(100vh-6rem)] overflow-auto lg:block">` com `<nav aria-label="Nesta página">` e rótulo `NESTA PÁGINA` |
| Container mobile | Disclosure `rounded-xl border bg-muted/20`: botão com `NESTA PÁGINA`, contador `N seções` à direita e `ChevronDown` que gira `rotate-180` quando aberto; `aria-expanded` |
| Truque mobile | Ao escolher, **fecha o menu primeiro** e só rola no frame seguinte (`pendingScroll` ref + `requestAnimationFrame`) — para a âncora cair no lugar certo depois que o menu sai do fluxo |
| Vazio | `sections.length === 0` → `null` |

> Nota do arquivo: *"O `useScrollSpy` compartilhado (doc de Fonte de Dados) NÃO é usado aqui."* — existem **dois** sistemas de scroll-spy distintos no produto (ver §10).

### 3.6 Hooks de microinteração (`topics/useInView.ts`)

Três hooks que sustentam **todas** as animações do renderer compartilhado:

| Hook | Comportamento | Sob `reduced-motion` |
|---|---|---|
| `useReducedMotion()` | Lê `matchMedia("(prefers-reduced-motion: reduce)")`, **reativo** (escuta o evento `change` — muda ao vivo se o usuário troca a preferência do SO) | — |
| `useInView<T>({rootMargin, threshold})` | Dispara **uma vez** ao entrar na viewport (`inView` vira `true` e nunca volta). Defaults: `rootMargin: "0px 0px -8% 0px"`, `threshold: 0.05`. Callback ref que re-observa o nó atual | Começa `true` sem sequer criar o observer |
| `useCountUp(target, start, durationMs=900)` | Anima inteiro `0 → target` com `easeOutCubic` via `requestAnimationFrame` | Vai direto ao alvo |

---

## 4. Pilar Técnica: catálogo de átomos, página de átomo, trilha lateral e tags

### 4.1 O modelo `Atom` — o grafo de referência

Fonte: `src/pages/central-docs/atoms/types.ts` (367 linhas de tipos, quase todo comentado).

O conceito central, declarado no cabeçalho: *"Cada 'coisa' do sistema (Edge Function, tabela, RPC, cron, helper, endpoint…) é um ÁTOMO: uma página individual com ficha técnica + um bloco 'Conexões' com backlinks tipados nos DOIS sentidos. As ligações (arestas) são escritas UMA vez no átomo de origem; o lado inverso é derivado automaticamente pelo motor de backlinks. É um grafo navegável (ping-pong), 100% data-driven."*

**Os 17 `AtomKind`** (agrupados por pilar de origem):

| Grupo | Kinds |
|---|---|
| Serviço (API) | `endpoint`, `mcp-tool`, `webhook-event` |
| Técnica (interno) | `edge-function`, `table`, `view`, `mv`, `rpc`, `cron`, `trigger`, `helper`, `variable`, `integration` |
| Negócio / app | `page`, `hook`, `permission`, `role` |

**As 16 relações (`EdgeRel`)** e seus rótulos nas duas direções (`atoms/relations.ts` → `REL_LABELS`):

| `EdgeRel` | Saída (`out`) | Entrada (`in`) |
|---|---|---|
| `serves` | servido por | serve |
| `triggers` | dispara | disparada por |
| `calls` | chama | chamada por |
| `executes` | executa | executada por |
| `reads-writes` | lê / escreve | lida / escrita por |
| `uses-helper` | usa | usado por |
| `integrates-with` | integra com | integrada por |
| `resolves` | resolve | resolvida por |
| `refreshes` | atualiza | atualizada por |
| `exposes` | expõe | exposta por |
| `requires-permission` | exige permissão | permissão exigida por |
| `grants` | concede | concedida por |
| `handled-by` | tratada por | trata |
| `renders-route` | renderiza rota | rota renderizada por |
| `uses-hook` | usa hook | hook usado por |
| `implemented-by` | implementada por | implementa |

**Campos do `Atom`** — cada um liga a **uma seção** da página (o que torna a página auto-montada, ver §4.5):

| Campo | Tipo | Vira |
|---|---|---|
| `id`, `kind`, `title`, `pillar`, `group`, `summary` | — | cabeçalho |
| `tags` | `string[]` | selos `Pill` no topo |
| `spec` | `AtomSpec[]` (`{label, value, hint?}`) | grade de meta-cards "Ficha técnica" |
| `config` | `AtomSpec[]` | mesma grade (só Edge Functions hoje) |
| `signature` | `string` | bloco "Assinatura" |
| `usage` | `UsageExample[]` (`{label?, code}`) | "Exemplo de chamada" |
| `sourcePath` | `string \| string[]` | "Onde está no projeto" |
| `env` | `EnvVar[]` (`{name, desc?, required?}`) | "Segredos & ambiente" |
| `callouts` | `AtomCallout[]` (`{level, title?, body}`) | "Atenção & invariantes" |
| `columns` | `TableColumn[]` | "Estrutura" (tabelas) |
| `relations` | `TableRelation[]` | "Relacionamentos" (tabelas) |
| `indexes` | `TableIndex[]` | "Índices-chave" (tabelas) |
| `sample` | `TableSample` | "Exemplo de dados" (tabelas) |
| `flow` | `FlowStep[]` (`{title, detail?, atom?}`) | "Fluxo de funcionamento" (timeline) |
| `io` | `{inputs?, outputs?: IoField[]}` | "Entradas & saídas" (2 tabelas) |
| `http` | `HttpEndpoint` (`{method, path}`) | "request line" + habilita o **testador** |
| `responses` | `ApiResponse[]` (`{status, desc, shape?}`) | "Respostas" |
| `exports` | `ExportItem[]` (`{name, kind?, signature?, desc}`) | "API do módulo" (helpers) |
| `consumers` | `ConsumerKind[]` (override) | faixa "Usado por" |
| `edges` | `Edge[]` (`{rel, to, note?}`) | "Conexões" (saídas + backlinks derivados) |

**Regras de segurança embutidas nos tipos (não podem ser perdidas no redesign):**
- `sourcePath` é *"só metadado de localização: por segurança, NUNCA o conteúdo do arquivo é importado nem exibido no frontend."*
- `usage` é *"só a forma de chamar. NUNCA o código-fonte interno do backend."*
- `env` é *"apenas o NOME e para que serve — NUNCA o valor."*
- `signature`/`exports` são *"só o contrato público, NUNCA a implementação."*
- `sample` é *"amostra ilustrativa (mock)"*, com legenda explícita.

### 4.2 Metadados de tipo (`atoms/kinds.ts`) e a paleta de famílias

`KIND_META: Record<AtomKind, KindMeta>` é a fonte única de rótulo, ícone, cor e descrição conceitual de cada tipo.

**Paleta por família** — declaração explícita de contenção: *"Mantemos poucas cores distintas para não virar arco-íris — tipos próximos compartilham a mesma faixa."*

| Família | Classe (tint) | Variante SATURADA (via `solidKindClass`) | Kinds |
|---|---|---|---|
| `PRIMARY` | `border-primary/30 bg-primary/10 text-primary` | `border-primary/40 bg-primary text-primary-foreground` | endpoint, mcp-tool, edge-function, integration, page |
| `ACCENT` | `border-accent-foreground/20 bg-accent text-accent-foreground` | `border-primary/30 bg-primary/85 text-primary-foreground` | webhook-event, rpc, variable, hook |
| `FORE` | `border-foreground/20 bg-foreground/[0.06] text-foreground/80` | `border-foreground/30 bg-foreground/80 text-background` | table, view, mv |
| `NEUTRAL` | `border-border bg-muted/60 text-muted-foreground` | `border-border bg-muted-foreground/80 text-background` | cron, trigger, helper |
| `DESTRUCTIVE` | `border-destructive/30 bg-destructive/10 text-destructive` | `border-destructive/40 bg-destructive text-destructive-foreground` | permission, role |

**Tabela completa dos kinds:**

| Kind | Label (sing.) | Plural (grupo) | Ícone lucide | Família |
|---|---|---|---|---|
| `endpoint` | Endpoint | Endpoints | `Plug` | PRIMARY |
| `mcp-tool` | MCP Tool | MCP Tools | `Zap` | PRIMARY |
| `webhook-event` | Evento de webhook | Eventos de webhook | `Radio` | ACCENT |
| `edge-function` | Edge Function | Edge Functions | `FileCode2` | PRIMARY |
| `table` | Tabela | Tabelas | `Table2` | FORE |
| `view` | View | Views | `Layers` | FORE |
| `mv` | Materialized View | Materialized Views | `Database` | FORE |
| `rpc` | RPC | RPCs | `FunctionSquare` | ACCENT |
| `cron` | Cron | Crons | `Calendar` | NEUTRAL |
| `trigger` | Trigger | Triggers | `Zap` | NEUTRAL |
| `helper` | Helper | Helpers | `Wrench` | NEUTRAL |
| `variable` | Variável | Variáveis | `Variable` | ACCENT |
| `integration` | Integração | Integrações | `Plug` | PRIMARY |
| `page` | Tela | Telas | `Route` | PRIMARY |
| `hook` | Hook | Hooks | `Code2` | ACCENT |
| `permission` | Permissão | Permissões | `ShieldCheck` | DESTRUCTIVE |
| `role` | Perfil | Perfis | `KeyRound` | DESTRUCTIVE |

Cada kind carrega ainda uma `description` em prosa (1 parágrafo) — **sempre visível** abaixo do título do grupo no catálogo da Técnica, mesmo com o accordion fechado.

`TECNICA_KIND_ORDER` fixa a ordem dos grupos: `edge-function → table → view → mv → rpc → cron → trigger → helper → variable → integration → hook` (alinhada com os chips "Inclui" do pilar).

### 4.3 Motor de backlinks (`atoms/registry.ts`)

| Função | O que faz |
|---|---|
| `ATOMS` | Lista mestre auto-agregada por `import.meta.glob("./data/*.ts", {eager:true})` — **64 arquivos de domínio** hoje. Adicionar um domínio = criar um arquivo, sem tocar no registry |
| `getAtom(id)` | Lookup por índice `Map` memoizado (reconstruído só se `ATOMS` mudar de identidade) |
| `getOutgoing(atom)` | Arestas que **saem**, com destino resolvido (`target` pode ser `undefined`) |
| `getBacklinks(id)` | Varre TODOS os átomos e coleta arestas que apontam para `id` (O(n·e), sem índice) |
| `getConnectionCount(atom)` | saídas + entradas (usado nas pílulas e no tamanho do nó do grafo) |
| `getAtomsByPillar`, `getAtomsByTag`, `getAllTags` | filtros; `getAllTags` ordena com `localeCompare(pt-BR)` |
| `groupByKind(atoms, order?)` | agrupa por kind respeitando a ordem dada, kinds fora da ordem no fim |
| `groupByGroup(atoms)` | agrupa por `group`, fallback `"Outros"` |
| `getGraphData()` | achata `{nodes, links}` para o `ForceGraph3D`; **ignora arestas órfãs** (`target` inexistente) |

**Robustez declarada:** *"uma aresta apontando para um id inexistente NÃO quebra a UI. As funções de resolução retornam o id 'cru' (`target: undefined`) e o consumidor decide renderizar como texto não-clicável."*

### 4.4 Catálogo `/central-docs/tecnica`

**Identidade:** `src/pages/central-docs/TecnicaCatalogPage.tsx` (294 linhas). Permissão `docs:tecnica`. `max-w-6xl` + grade `[220px_minmax(0,1fr)]` com `AtomRail`.

**Anatomia:**

| # | Zona | Detalhe |
|---|---|---|
| 1 | Topbar + fundo | Padrão da Central (`← Central de Documentação` + `BookMarked` + título) |
| 2 | Rail | `Visão geral` (`Info`) + `Tags` (`Tags`) + **um item por grupo de kind visível** (ícone do kind, label = plural) — o rail **acompanha o filtro** |
| 3 | Cabeçalho do pilar (`#tec-overview`) | Ícone `h-12 w-12 bg-primary` + H1 `text-primary` + descrição do pilar |
| 4 | **Cartão "Ver todas as tags"** (`#tec-tags`) | `<Link>` para `/central-docs/tags`: quadrado `Tags` + título + subtítulo *"O vocabulário transversal do grafo (load-bearing, FAIL-CLOSED, cron-driven…) e os átomos de cada tag."* + `ArrowRight` à direita |
| 5 | **Barra de busca** | `CatalogSearch` — placeholder "Buscar por nome ou descrição…" |
| 6 | **Chips de filtro por tipo** | `FilterChipRow label="Tipos"` — um chip por kind **presente** (ícone + plural), estável (não some ao filtrar) |
| 7 | Contador de resultados | `"N resultados"` em `text-xs`, só quando filtrando |
| 8 | Accordion de grupos | `<Accordion type="multiple">` — ver abaixo |
| 9 | Vazio | Filtrando: *"Nenhum átomo bate com a busca/filtro."* · Sem dados: *"Nenhum átomo cadastrado ainda. As páginas técnicas estão sendo escritas."* |

**Busca e filtro (`CatalogToolbar.tsx`):**
- `CatalogSearch`: container `rounded-xl border bg-card` com `focus-within:border-primary/50`, ícone `Search`, input transparente, botão `X` "Limpar busca" (só com valor). **`Escape` limpa a busca** (`onKeyDown`).
- `FilterChipRow`: semântica documentada — *"conjunto vazio = sem filtro (mostra tudo); selecionar chips restringe a só os selecionados."* Três estados visuais por chip:
  - **ligado**: `border-primary/50 bg-primary/10 text-foreground`
  - **desligado enquanto há outro filtro ativo**: `opacity-55` (esmaecido) com `hover:opacity-100`
  - **desligado sem filtro algum**: `text-foreground/80 hover:border-primary/40`
- Predicado da Técnica: `(kindFilter vazio || contém a.kind) && (query vazia || "title summary" contém q)` — busca **case-insensitive** em título + resumo.

**Comportamento do accordion (detalhe importante de UX):** `openValues = filtering ? groups.map(g => g.kind) : manualOpen`. Ou seja, **ao filtrar, todos os grupos abrem automaticamente**; ao limpar o filtro, volta ao estado manual do usuário. O `AccordionTrigger` é customizado (via `AccordionPrimitive`) para ter a faixa em gradiente, barra de acento, quadrado de ícone, título, contador `(N)` e `ChevronDown` que gira 180° quando aberto (`group-data-[state=open]/trigger:rotate-180`). A **descrição conceitual do kind** fica **fora** do `AccordionContent`, portanto **sempre visível**.

**`AtomRow`** (linha de átomo): `<Link>` `rounded-xl border bg-gradient-to-br from-card to-primary/[0.04] px-4 py-3`, hover `-translate-y-0.5 border-primary/40` + sombra. Conteúdo: título em `fdd-mono font-semibold` (truncado, vira `text-primary` no hover), resumo em `text-sm text-muted-foreground` truncado a uma linha, e à direita a pílula `N conexões` (singular/plural).

### 4.5 Página de átomo `/central-docs/atom/:id`

**Identidade:** `src/pages/central-docs/atoms/AtomPage.tsx` (1804 linhas — o maior arquivo do domínio). Permissão **dinâmica**: `docs:${atom.pillar}` — a rota exige `docs:tecnica`, mas o gate interno usa o pilar do átomo, então um átomo de Serviço aberto por essa rota exige `docs:servico`.

O cabeçalho do arquivo declara o objetivo: *"abrindo a página de uma Edge Function (ou tabela, RPC, cron…), a pessoa entende COMPLETAMENTE o que ela é."*

**Princípio estrutural: a página é AUTO-MONTADA.** Cada seção só existe se o campo correspondente do átomo estiver preenchido, e o rail é construído a partir das seções realmente presentes (`useMemo` sobre `atom`). Um átomo `table` e um átomo `endpoint` renderizam páginas visualmente muito diferentes com o mesmo componente.

**As 17 âncoras (`SECTION_IDS`) e suas condições:**

| Ordem | Âncora | Seção | Ícone no rail | Condição |
|---|---|---|---|---|
| 1 | `sec-overview` | Visão geral | `Info` | sempre |
| 2 | `sec-ficha` | Ficha técnica | `Layers` | `spec.length + config.length > 0` |
| 3 | `sec-signature` | Assinatura | `Braces` | `signature` |
| 4 | `sec-usage` | Exemplo de chamada | `Terminal` | `usage.length` |
| 5 | `sec-source` | No projeto | `MapPin` | `sourcePath` |
| 6 | `sec-env` | Segredos & ambiente | `KeyRound` | `env.length` |
| 7 | `sec-callouts` | Atenção | `AlertTriangle` | `callouts.length` |
| 8 | `sec-structure` | Estrutura | `Table2` | `columns.length` |
| 9 | `sec-relations` | Relacionamentos | `Link2` | `relations.length` |
| 10 | `sec-indexes` | Índices | `ListTree` | `indexes.length` |
| 11 | `sec-sample` | Exemplo | `Database` | `sample.rows.length` |
| 12 | `sec-flow` | Como funciona | `Workflow` | `flow.length` |
| 13 | `sec-io` | Entradas & saídas | `ArrowRight` | `io.inputs.length + io.outputs.length > 0` |
| 14 | `sec-responses` | Respostas | `ArrowUpFromLine` | `responses.length` |
| 15 | `sec-tester` | Testar | `Play` | `http` |
| 16 | `sec-exports` | API do módulo | `Boxes` | `exports.length` |
| 17 | `sec-connections` | Conexões | `Share2` | sempre |

**Cabeçalho (`#sec-overview`):**
- `KindBadge` (badge do tipo, variante saturada) + pílula neutra com o `group`.
- Título: barra de acento `w-1 bg-primary` + H1 **em `fdd-mono`** `text-3xl sm:text-4xl font-extrabold` — diferença marcante em relação a Tópicos/Negócio (o nome do átomo é um identificador técnico).
- Resumo `text-lg text-justify`.
- `RequestLine` (só `endpoint`): barra `rounded-xl border bg-muted/30` com `MethodBadge size="lg"` + a rota em mono.
- Selos `Pill` com as tags, tom via `tagTone(tag)`.

**Ficha técnica (`SpecCard`):** grade `grid-cols-2 sm:grid-cols-3` de cards `rounded-2xl border bg-gradient-to-br from-card to-primary/[0.04] p-4`, cada um com quadrado de ícone `h-8 w-8 bg-primary`, rótulo `text-[10px] uppercase tracking-wider`, valor `text-[15px] font-medium` e hint opcional.
- **Mapa de ícones por rótulo** (`SPEC_ICONS`, ~28 entradas): `Gatilho→Zap`, `Auth→ShieldCheck`, `Escopo→Globe`, `Cadência→Clock`, `Tipo→Tag`, `Concorrência→Lock`, `Schema→Database`, `Colunas→Columns3`, `Status→Activity`, `Exporta→Share2`, `Invocação→Webhook`, `verify_jwt→KeyRound`, `Categoria→Layers`, `Dispara→Zap`, `Linguagem→FileCode2`, `Segurança→ShieldCheck`, `Retorno→ArrowUpFromLine`, `Natureza/Volatilidade→Activity`, `Job→Workflow`, `Invoca via→Webhook`, `PK→KeyRound`, `Índices→ListTree`, `Fonte→GitBranch`, `Atualização→RefreshCw`, `Protocolo→Network`, `Direção→ArrowLeftRight`, `Endpoint→Link2`. Fallback `Info`.
- **Heurística de fonte mono:** `isTechnicalValue(value)` = `/[{}_*/]|[a-z]+_[a-z]/`. Valores que parecem identificador/expressão (`org_{slug}`, `* * * * *`, snake_case, caminhos) ganham `fdd-mono text-sm`; prosa ("A cada minuto") fica na fonte padrão.
- Rodapé constante em `edge-function`: *"Runtime Deno · deploy via GitHub Actions no merge"*.

**Faixa "Usado por" (`ConsumersRow`)** — só para `endpoint`, `edge-function`, `rpc`, `mcp-tool`. **Derivada automaticamente** por `deriveConsumers(atom, backlinks)` (o campo `consumers` só sobrescreve). Sinais usados: `spec.Auth` (`/jwt/`→frontend, `/api.?key/`→external), `spec.Gatilho` (`/cron/`, `/frontend/`, `/webhook/`, `/ef|interna|função/`), labels de `usage` e prefixos dos backlinks (`cron-`, `ef-`, kind `endpoint`/`page`/`hook`).

| `ConsumerKind` | Rótulo | Ícone | Cor |
|---|---|---|---|
| `frontend` | Frontend | `AppWindow` | blue-500 |
| `cron` | Cron | `Clock` | amber-500 |
| `edge-function` | Edge Functions | `FileCode2` | primary |
| `external` | Externo / API | `Globe` | teal-500 |
| `webhook` | Webhook | `Webhook` | pink-500 |
| `mcp` | Agente IA (MCP) | `Zap` | violet-500 |
| `internal` | Interno (EF→EF) | `Lock` | neutro |

> ⚠️ **Nota de design system:** esta é uma das poucas paletas com **cores hardcoded do Tailwind** (blue/amber/teal/pink/violet), não tokens. O mesmo vale para `METHOD_CLASS` (§5.3) e `statusTone` (§4.5). O comentário em `http.tsx` assume isso: *"Cores via classes utilitárias fixas (uma faixa por método); o resto do design segue tokens."*

**Cabeçalho de seção (`SectionHeader` local do AtomPage):** faixa `rounded-xl border border-primary/15 bg-gradient-to-r from-primary/10 via-primary/5 to-transparent px-3.5 py-2.5`, com barra `h-6 w-1 bg-primary`, quadrado de ícone `h-8 w-8 bg-primary` com sombra, título `text-lg font-semibold` e contador opcional `(N)` em `text-primary/70`. **Não tem âncora `#`** (diferente do `SectionHeader` do `DocBlocks`).

**Seções específicas:**

| Seção | Aparência |
|---|---|
| **Assinatura** | Card `rounded-2xl border-primary/20 bg-gradient-to-br from-card to-primary/[0.06]`; rótulo `⟨⟩ ASSINATURA`; a linha num sub-bloco `rounded-lg border bg-muted/40` com `overflow-x-auto` e `whitespace-pre` |
| **Exemplo de chamada** | Um card por `UsageExample`, mesmo estilo do bloco de assinatura; `label` opcional acima em `text-[10px] uppercase` |
| **Onde está no projeto** | Caixa discreta `rounded-xl border bg-muted/20 p-3.5` com rótulo `ONDE ESTÁ NO PROJETO`; cada caminho é uma linha `rounded-lg border bg-card` com `<code>` truncado + **botão copiar** (`Copy` → `Check` por 1600ms, `title`/`aria-label` alternam "Copiar caminho"/"Copiado") |
| **Segredos & ambiente** | Lista de `<li>` `rounded-xl border bg-card p-3.5`: nome em mono + `TinyBadge "obrigatório"` + descrição alinhada à direita em `sm:` |
| **Atenção & invariantes** | Um `Callout` (primitivo do fonte-de-dados-docs) por item, com `level` do átomo |
| **Estrutura** (tabelas) | `Table` do shadcn com 5 colunas: Coluna · Tipo · Nulo? · Default · Descrição, dentro de `overflow-x-auto rounded-2xl border-primary/15`. **Mostra só as colunas-chave (`key: true`) por padrão**; botão abaixo alterna: `"Ver todas as N colunas"` ⇄ `"Mostrar só as N principais"`, com `ChevronDown` que gira. Se nenhuma coluna tem `key`, mostra todas |
| **Relacionamentos** | Relações lógicas `*_id`; vira link para a AtomPage quando `refAtomId` resolve; **inclui um callout "sem FK"** (as relações são por convenção, não enforced no banco) |
| **Índices-chave** | Lista **completa** (comentário: *"sem limite… nunca escondemos itens"*); quando há muitos, container rolável `max-h` + scroll; selo `parcial` para índice com `WHERE` |
| **Exemplo de dados** | `Table` do shadcn com o mock; `null` renderizado como "null" muted; legenda "ilustrativo" |
| **Respostas** | Um `<li>` por status: badge do código com cor por faixa (`statusTone`: ≥500 destructive · ≥400 amber-500 · 2xx emerald-500 · resto neutro) + descrição + `shape` opcional em `<code>` |
| **API do módulo** | `Table` shadcn: Export · Tipo · Descrição. `ExportKindBadge` para `const`/`fn`/`set`/`type`; `signature` em mono pequeno abaixo do nome |
| **Entradas & saídas** | Duas tabelas shadcn empilhadas. Entradas: Campo · Tipo · Obrigatório · Descrição (+ coluna "Em" para endpoints, via `loc`). Saídas: Campo · Tipo · Descrição. Cada uma com rótulo pequeno e `overflow-x-auto` |

**Fluxo de funcionamento (`FlowDiagram`)** — descrita no cabeçalho como *"A seção técnica do átomo"*:
- Container `rounded-2xl border-primary/15 bg-gradient-to-br from-card to-primary/[0.04] p-5 sm:p-6`, `<ol>` sem marcador.
- Cada passo (`FlowStepRow`): **linha conectora vertical** `absolute left-[18px] top-9 bottom-0 w-px bg-border` — **omitida no último passo**.
- **Marcador** `h-9 w-9 rounded-xl` com sombra: se o passo referencia um átomo, usa o **ícone do kind** na variante **saturada** (`solidKindClass`); senão, o **número do passo** em `bg-primary`.
- Corpo: kicker `PASSO N` em `text-[10px] uppercase text-primary/70`, título `text-sm font-semibold`, `detail` via `RichTextBlock` (string → parágrafo justificado; array → bullets), e `FlowAtomChip` quando há átomo (chip `→ título` clicável; id órfão → texto não-clicável).

**Conexões (`#sec-connections`)** — sempre presente:
- `SectionHeader` com ícone `Share2` e contador total (`saídas + entradas`).
- Duas sanfonas empilhadas (`Accordion type="multiple"`, **fechadas por padrão**), `gap-7`:
  - `→ Usa / depende de` (ícone `ArrowRight` em `bg-primary/15`)
  - `← Usado por` (ícone `ArrowLeft`)
- Cada uma mostra contador `(N)` e, vazia, o texto `— nada ainda`.
- **`ConnectionRow`** (item): quadrado de ícone do kind `h-8 w-8 rounded-lg border bg-muted` + rótulo da relação em `text-[11px] uppercase text-primary/70` + título em `fdd-mono` truncado + `note` opcional numa micro-pílula + rótulo do kind à direita (oculto em `<sm`). Hover `bg-primary/5`. **Id órfão → `<div opacity-70 aria-disabled>` não-clicável**.
- Abaixo, as faixas de cross-link: `TopicBacklinks` (hint "a narrativa por trás"), `GuideBacklinks` ("Onde aparece no produto" · "telas que usam esta peça") e `ChangelogBacklinks`.

**Estados:** id inválido → `<Navigate to="/central-docs/tecnica" replace />`. Sem `docs:<pillar>` → tela de cadeado: *"Você não tem acesso a este conteúdo da documentação."*

### 4.6 Índice de tags `/central-docs/tags`

**Identidade:** `src/pages/central-docs/TagsPage.tsx` (158 linhas). Permissão `docs:tecnica`. `max-w-4xl` (mais estreito que os demais). **Sem rail.**

**Anatomia:** topbar com **dois** breadcrumbs (`← Técnica` e `BookMarked Central de Documentação`); cabeçalho com ícone `Tags` + H1 "Tags" + parágrafo que usa `fdd-mono` inline nos exemplos (`load-bearing`, `FAIL-CLOSED`, `cron-driven`); depois uma coluna de blocos `gap-4`.

**`TagBlock`** (um por tag, envolto em `Reveal`): card `rounded-2xl border bg-gradient-to-br from-card to-primary/[0.04] p-5` com hover `border-primary/40` + sombra. Conteúdo:
1. `Pill` com o nome da tag, tom via `tagTone(tag)`.
2. Contador `N átomos` / `1 átomo`.
3. Descrição da tag (`TAG_META[tag].description`) em `text-sm text-foreground/80`.
4. Lista de `AtomLine`: quadrado de ícone do kind com a **classe tint** do kind (`meta.badgeClass`) + título em `fdd-mono` truncado + rótulo do kind à direita (oculto em `<sm`), separados por `divide-y divide-border/60`, hover `bg-primary/5`.

**Vazio:** *"Nenhuma tag cadastrada ainda."*

### 4.7 Vocabulário de tags (`atoms/tags.ts`)

Fonte única de significado + tom. **20 tags catalogadas**, cada uma com uma descrição que declara o **critério de marcação** (não só o conceito) — padrão de escrita importante para preservar:

| Tag | Tom (`PillTone`) | Resumo do critério |
|---|---|---|
| `load-bearing` | danger | falha aqui derruba/corrompe processos importantes |
| `FAIL-CLOSED` | danger | ao falhar validação/leitura, NEGA a ação |
| `hot-table` | danger | alto volume; DDL e locks pesados são arriscados |
| `cron-driven` | teal | execução normal vem de job agendado |
| `pg_cron` | teal | agenda definida via pg_cron no banco |
| `multi-org` | teal | varre/processa todas as orgs numa execução |
| `per-org` | teal | vive no schema `org_{slug}` |
| `single-exit` | primary | gargalo intencional por onde tudo sai |
| `central` | primary | hub do grafo (muitas conexões de entrada) |
| `resolver-único` | primary | único lugar que resolve um tipo de coisa |
| `concorrência` | warning | locks/claims atômicos para workers não colidirem |
| `round-robin` | warning | rodízio justo entre grupos |
| `skip-locked` | warning | `FOR UPDATE SKIP LOCKED` |
| `idempotente` | warning | reprocessar não duplica efeito |
| `desativado` | warning | kill-switch ligado; dormente |
| `cache` | warning | dado derivado; pode ficar stale |
| `legado` | warning | mantido por compatibilidade; use a v2 |
| `multicanal` | muted | opera em vários canais |
| `shared` | muted | módulo `_shared` reusado |
| `vocabulário` | muted | fonte de verdade de um conjunto de termos |
| `webhook` | primary | endpoint que externos chamam para notificar |

`tagTone(tag)` usa o `tone` declarado; **quando a tag não está catalogada**, aplica uma convenção heurística por criticidade (alerta→danger, central/único→primary, concorrência→warning, cron/org→teal, resto muted) — *"de modo que tags ainda não catalogadas continuem com um tom coerente"*.

---

## 5. Pilar Serviço (API): catálogo, cartão de endpoint, testador de endpoint

### 5.1 Catálogo `/central-docs/servico`

**Identidade:** `src/pages/central-docs/ServicoCatalogPage.tsx` (282 linhas). Permissão `docs:servico`. `max-w-6xl` + rail.

Declaração do arquivo: *"Referência da API no espírito do Swagger, mas no design da Central."* Agrupa os átomos do pilar `servico` por **recurso** (`group`, equivalente à "tag" do Swagger) — não por tipo.

**Diferenças em relação ao catálogo da Técnica:**

| Aspecto | Técnica | Serviço |
|---|---|---|
| Agrupamento | por `kind` (`groupByKind`) | por `group`/recurso (`groupByGroup`) |
| Ordenação dos grupos | `TECNICA_KIND_ORDER` | **`groupOrderKey`**: Autenticação (0) → recursos REST (50) → MCP (80) → Webhooks (90), alfabético dentro de cada faixa |
| Filtros | 1 linha ("Tipos", com ícone) | **2 linhas**: "Tipo" (plural do kind, sem ícone) e **"Método"** (chips que são `MethodBadge` coloridos) |
| Busca | título + resumo | título + resumo + **rota HTTP** |
| Descrição do grupo | `KIND_META.description` sempre visível | — (não há) |
| Ícone do grupo | ícone do kind | **sempre** o ícone do pilar (`Plug`) |
| Topbar | — | **botão `Autorizar`** alinhado à direita (`ml-auto`) |
| Âncoras | `tec-kind-<kind>` | `svc-<slug do grupo>` (`toLowerCase().replace(/[^a-z0-9]+/g,"-")`) |

**Predicado de filtro do Serviço:**
```
(kindFilter vazio || contém a.kind)
&& (methodFilter vazio ? true : a.http ? methodFilter.has(a.http.method) : false)
&& (query vazia || "title summary path".includes(q))
```
> Nota de comportamento: filtrar por método **exclui** átomos sem `http` (MCP tools e eventos de webhook somem) — coerente, mas vale sinalizar na UI de um redesign.

**Chips de método:** só aparecem para os métodos **presentes** nos átomos, na ordem fixa `GET, POST, PUT, PATCH, DELETE`. A linha inteira é omitida se `methodChips.length === 0`.

**Mesmo comportamento do accordion:** abre todos os grupos ao filtrar (`openValues = filtering ? ... : manualOpen`).

**Vazio:** filtrando → *"Nada bate com a busca/filtro."*; sem dados → *"Nenhum endpoint cadastrado ainda. A referência da API está sendo escrita."*

### 5.2 Linha de endpoint (`ServicoRow`)

Mesma moldura do `AtomRow` da Técnica, com duas diferenças:
1. **`MethodBadge` colorido à esquerda**, renderizado só quando o átomo tem `http`.
2. O título principal é **a rota** (`atom.http?.path`), caindo no `atom.title` quando não há rota (MCP tool / evento de webhook).
3. A pílula de conexões é **oculta em telas `<sm`** (`hidden … sm:inline`) — economiza largura no mobile.

### 5.3 Badge de método HTTP (`atoms/http.tsx`)

Componente compartilhado entre a `AtomPage` (request line, `size="lg"`) e a `ServicoCatalogPage` (linhas, `size="sm"`).

| Método | Classes |
|---|---|
| `GET` | `text-emerald-600 bg-emerald-500/12 border-emerald-500/30 dark:text-emerald-400` |
| `POST` | `text-blue-600 bg-blue-500/12 border-blue-500/30 dark:text-blue-400` |
| `PUT` | `text-amber-600 bg-amber-500/12 border-amber-500/30 dark:text-amber-400` |
| `PATCH` | `text-violet-600 bg-violet-500/12 border-violet-500/30 dark:text-violet-400` |
| `DELETE` | `text-red-600 bg-red-500/12 border-red-500/30 dark:text-red-400` |
| `HEAD` | `text-teal-600 bg-teal-500/12 border-teal-500/30 dark:text-teal-400` |
| `OPTIONS` | `text-muted-foreground bg-muted/60 border-border` (também o fallback) |

Dimensões: `lg` = `px-2.5 py-1 text-xs min-w-[58px]`; `sm` = `px-2 py-0.5 text-[10px] min-w-[48px]`. Sempre `font-bold uppercase tracking-wider`, com largura mínima para alinhar as rotas em coluna.

### 5.4 Store de autenticação (`apiAuth.ts`)

Store global minimalista, **sem biblioteca**: um objeto de módulo + `Set` de listeners + `useSyncExternalStore`. Persiste em `localStorage` sob a chave `central-docs-api-auth-v1`.

```ts
interface ApiAuth {
  baseUrl: string;   // default: `${SUPABASE_URL}/functions/v1`
  apiKey: string;    // x-api-key
  orgSlug: string;   // x-org-slug
  testKeyId?: string;// id da chave gerada aqui (p/ revogar). Vazio = chave colada
}
```

Motivo declarado de existir em módulo separado (sem JSX): *"para o componente do tester exportar só componentes"* (regra do react-refresh). Todas as leituras/escritas de `localStorage` estão em `try/catch` (SSR/quota).

**O `baseUrl` define o ambiente** — deriva de `SUPABASE_URL`, portanto prod ou dev conforme o host de onde a doc está sendo servida.

### 5.5 Botão "Autorizar" (`AuthorizeButton`)

Vive no topo do catálogo de Serviço. Botão com **dois estados**:
- **Sem chave**: ícone `Lock`, `border-border/60 bg-background/80 text-foreground`, hover primary.
- **Com chave** (`ready = !!auth.apiKey`): ícone `ShieldCheck`, `border-emerald-500/40 bg-emerald-500/10 text-emerald-600 dark:text-emerald-400`.

Abre um **popover** (não é `Dialog`): overlay `fixed inset-0 z-30` que fecha ao clicar fora + painel `absolute right-0 z-40 mt-2 w-[min(90vw,340px)] rounded-xl border bg-background/95 p-4 shadow-xl backdrop-blur`, com cabeçalho `🔑 Autenticação da API` e botão `X`.

**Campos (`AuthorizeFields`):**

| Campo | Tipo | Hint |
|---|---|---|
| Base URL | texto mono | "ambiente da API (deriva de SUPABASE_URL)" |
| `x-api-key` | **`type="password"`** mono, placeholder `tc_live_…` | "endpoints de api_key. Endpoints JWT (/etl, /integrations) usam o token da sua sessão automaticamente." |
| `x-org-slug` | texto mono, placeholder = slug da org atual | "organização alvo (obrigatório)" |

**Gerar/revogar chave de teste — só `super_admin`:**
- Botão "Gerar chave de teste" (ícone `KeyRound`, spinner `Loader2` enquanto pendente) chama `useCreateApiKey()` com nome `central-docs-tester · <data/hora pt-BR>`; grava `apiKey` + `testKeyId` no store.
- Botão "Revogar" (aparece só com `testKeyId`) chama `useDeactivateApiKey()` e limpa o store; falha é silenciosa (o usuário pode revogar em Integrações).
- Aviso permanente em âmbar enquanto há chave de teste: *"Chave de teste ativa — revogue quando terminar (ou em Integrações → API Keys)."*
- **Erro tratado explicitamente:** se a RPC devolver `PGRST202` ou citar `create_api_key`, a mensagem é específica: *"A RPC create_api_key (versão universal, IAF-176) não existe neste ambiente — geração de chave indisponível aqui. Cole uma chave existente ou teste num ambiente com a IAF-176 aplicada."*
- Para não-super_admin: *"Gerar chave exige super_admin. Cole uma chave existente (Integrações → API Keys) no campo acima."*

Rodapé de privacidade: *"Guardado só no seu navegador (localStorage). A chave nunca sai daqui exceto na chamada que você disparar."*

### 5.6 Testador de endpoint (`EndpointTester`)

Renderizado na `AtomPage` (seção `Testar`, `#sec-tester`) para **qualquer átomo com `http`**. Container `rounded-2xl border-primary/20 bg-gradient-to-br from-card to-primary/[0.05] p-4`.

> ⚠️ **Aviso do próprio código:** *"É a API REAL: o ambiente é definido pela base URL… Métodos não-GET ALTERAM dados; exigem confirmação."*

**Anatomia (ordem vertical):**

| # | Bloco | Detalhe |
|---|---|---|
| 1 | Request line | `MethodBadge size="lg"` + rota em mono, com `overflow-x-auto` |
| 2 | Linha "Auth deste endpoint" | Texto: *"JWT de usuário — usa o token da sua sessão (automático)"* **ou** *"x-api-key + x-org-slug"* |
| 3 | `<details>` de autenticação | Summary dinâmico: `Autenticação · JWT da sessão (automático)` / `x-api-key ✓` / `x-api-key (defina a chave)`. Dentro, os mesmos `AuthorizeFields` |
| 4 | Parâmetros | Três `ParamGroup` (Path · Query · Headers). Label em mono com largura fixa `w-44` e `*` vermelho quando `required`; input com `placeholder` = o `type` do campo |
| 5 | Body (JSON) | `<textarea rows={5}>` em `fdd-mono`, só para `POST/PUT/PATCH`, valor inicial `"{\n  \n}"` |
| 6 | Aviso de método mutante | `<label>` clicável `rounded-lg border-amber-500/30 bg-amber-500/10` com checkbox `accent-amber-500`: *"**<MÉTODO>** executa de verdade e pode **alterar dados** no ambiente da Base URL. Confirmo que quero disparar."* |
| 7 | cURL equivalente | `<pre>` `fdd-mono text-[11px]` — **sempre visível** (fallback para CORS). A chave é mascarada como `$API_KEY` |
| 8 | Botão Executar | Sólido `bg-primary`, ícone `Play` (ou `Loader2` girando). Desabilitado com `opacity-40 cursor-not-allowed` |
| 9 | Mensagem de bloqueio | Ao lado do botão, explica **por que** está bloqueado (ver abaixo) |
| 10 | Resultado | Badge de status (emerald se `ok`, âmbar se não) + `{ms} ms` + `<pre>` `max-h-80 overflow-auto` com o corpo |
| 11 | Erro | Caixa `border-destructive/30 bg-destructive/10`: `Falhou: {mensagem}` + dica *"Pode ser CORS do navegador — nesse caso copie a cURL acima e rode no terminal."* |

**Regras de autenticação (derivadas do átomo):**
```
authMode = /jwt/i.test(spec.find(c => c.label === "Auth")?.value) ? "jwt" : "apikey"
```
O comentário justifica: *"JWT só p/ /etl e /integrations; os demais usam x-api-key. Evita mandar a credencial errada (403)."* No modo JWT, a cURL mostra `Bearer <jwt-da-sessão>` como placeholder e o `execute()` busca o token real via `supabase.auth.getSession()` (lançando `"Sem sessão ativa para extrair o JWT."` se não houver).

**Headers de auth são filtrados dos parâmetros** — `x-api-key`, `x-org-slug` e `authorization` são removidos da lista de headers editáveis (vêm do store).

**Gate de execução (crítico para o redesign):**
```
canRun = isSuperAdmin && credsReady && !!orgSlug && (!isMutating || confirmMutate)
```
Ou seja, **só `super_admin` dispara requisições de verdade**. O comentário é explícito: *"admin/owner veem a cURL e copiam, mas não disparam."* A mensagem de bloqueio é em cascata, na ordem: `"Apenas super_admin executa (você pode copiar a cURL acima)"` → `"defina a x-api-key acima"` → `"defina o x-org-slug"` → `"confirme o aviso acima"`.

**Detalhes da montagem da requisição:**
- Path params: substitui `:nome` por `encodeURIComponent(valor)`; se vazio, mantém `:nome` visível.
- Query params: só entram no `URLSearchParams` quando têm valor.
- `content-type: application/json` só quando há body.
- Resposta: tenta `JSON.parse` + `JSON.stringify(…, null, 2)` para formatar; se não for JSON, mostra cru. **Truncada em 20.000 caracteres** (`body.slice(0, 20000)`).
- Tempo medido com `performance.now()`.

---

## 6. Pilar Novidades (Changelog): feed, post, engajamento, pessoas e não lidos

### 6.1 O modelo `ChangelogEntry`

Fonte: `src/pages/central-docs/changelog/types.ts`.

```ts
type ChangelogType = "novidade" | "melhoria" | "correcao" | "breaking" | "seguranca";

interface ChangelogEntry {
  id: string;        // url-safe e ESTÁVEL (ex.: "2026-06-25-central-docs")
  date: string;      // ISO yyyy-mm-dd — ordena o feed e marca "Novo"
  version?: string;  // chip mono (ex.: "v2.4.0")
  type: ChangelogType;
  title: string;
  summary: string;
  author?: string;
  tags?: string[];
  sections: TopicSection[];  // REUSA os blocos dos Tópicos
  changed?: { atoms?: string[]; topics?: string[]; guides?: string[] };
}
```

**Terceiro consumidor do mesmo renderer de blocos** (junto de Tópicos e Negócio). O `changed` é o que alimenta os índices reversos "Mencionado nas Novidades" nos outros pilares.

**Registry** (`changelog/registry.ts`): glob `./data/*.ts` (**~60 posts hoje**, de junho a setembro de 2026), ordenados **desc por data com desempate estável por id (desc)**. Expõe `ENTRIES`, `getEntry(id)`, `getEntriesByMonth()` (chave `yyyy-mm`, label "Mês de Ano" capitalizado), `latestEntryDate()` e os três índices reversos `getChangelogForAtom/Topic/Guide`.

### 6.2 Metadados de tipo (`typeMeta.ts`)

| Tipo | Rótulo | Ícone | `badgeClass` |
|---|---|---|---|
| `novidade` | Novidade | `Sparkles` | `border-primary/30 bg-primary/10 text-primary` |
| `melhoria` | Melhoria | `Wrench` | `border-blue-500/30 bg-blue-500/10 text-blue-600 dark:text-blue-400` |
| `correcao` | Correção | `Bug` | `border-emerald-500/30 bg-emerald-500/10 text-emerald-600 dark:text-emerald-400` |
| `breaking` | Mudança importante | `AlertTriangle` | `border-amber-500/30 bg-amber-500/12 text-amber-600 dark:text-amber-400` |
| `seguranca` | Segurança | `ShieldCheck` | `border-destructive/30 bg-destructive/10 text-destructive` |

**Formatadores de data (UTC-safe — importante):** ambos parseiam `yyyy-mm-dd` manualmente e montam `Date.UTC(...)` com `timeZone: "UTC"` no `toLocaleDateString`, evitando o deslocamento de fuso que faria a data "voltar um dia" no Brasil.
- `formatChangelogDate("2026-06-25")` → `"25 de junho de 2026"`
- `formatChangelogDateShort("2026-06-25")` → `"25 jun"` (remove o ponto da abreviação)

### 6.3 Feed `/central-docs/changelog`

**Identidade:** `src/pages/central-docs/changelog/ChangelogFeedPage.tsx` (268 linhas). Permissão `docs:changelog`. `max-w-5xl`. **Sem rail** (é um feed cronológico).

**Efeito colateral ao montar:** `useEffect(() => markSeen(), [markSeen])` — **visitar o feed zera o badge da sidebar**.

**Anatomia:**

| # | Zona | Detalhe |
|---|---|---|
| 1 | Topbar + fundo | Padrão da Central |
| 2 | Cabeçalho do pilar | Ícone `Megaphone` (`PILLAR?.icon ?? Megaphone`) + H1 + descrição do pilar. **Fallbacks defensivos** caso `PILLARS.find` não ache o pilar |
| 3 | **Busca** | `<input type="search">` com `Search` posicionado absoluto à esquerda; `focus-visible:border-primary/50 focus-visible:ring-2 focus-visible:ring-primary/30`; placeholder "Buscar nas novidades…". **Diferente do `CatalogSearch`** dos outros catálogos — é um componente inline próprio, com `type="search"` (X nativo do browser) |
| 4 | **Chips de tipo** | Ordem fixa `FILTER_ORDER = [novidade, melhoria, correcao, breaking, seguranca]`. Chip **ativo** assume o `badgeClass` do próprio tipo (a cor do tipo). Inativo: `border-border bg-card text-muted-foreground`. `aria-pressed` |
| 5 | Grupos por mês | Mesmo cabeçalho de grupo dos outros catálogos (faixa gradiente + barra + label + `(N)`), label = "Setembro de 2026" |
| 6 | Grid de cards | `grid gap-4 sm:grid-cols-2` |
| 7 | Vazio | Sem posts: *"Nenhuma novidade publicada ainda."* · Filtrando: *"Nada encontrado para esse filtro."* |

**Busca:** `title + summary + tags.join(" ")`, case-insensitive. O filtro é aplicado **dentro** de cada grupo mensal, e meses que ficam vazios são descartados.

**`EntryCard`:** mesma moldura dos cards de tópico/guia (`border-t-2 border-t-primary/50`, gradiente, hover `-translate-y-0.5`). Linha superior: `TypeBadge` (ícone + rótulo do tipo) + chip mono da `version` (se houver) + data por extenso + **selo `✦ NOVO`** empurrado para a direita (`ml-auto`) quando `isEntryNew(entry.date, lastSeen)`. Depois título `text-lg` (vira `text-primary` no hover), resumo justificado, e um rodapé de métricas:
- `👁 N visualizações` (sempre, mesmo zero; plural correto; `toLocaleString("pt-BR")`)
- `📣 N reações` (**só quando > 0**)
- `por {author}` alinhado à direita (`ml-auto`)

### 6.4 Post `/central-docs/changelog/:id`

**Identidade:** `src/pages/central-docs/changelog/ChangelogPostPage.tsx` (455 linhas). Permissão `docs:changelog`. `max-w-6xl` + rail + `ReadingProgress` (mesmo componente duplicado em `TopicPage` e `PageGuidePage`).

**Rail:** `Resumo` (`Info`) + uma entrada por seção (`Workflow`) + **`Reações`** (`Megaphone`) no fim.

**Dois efeitos ao abrir** (guardados por `viewedRef` para rodar uma única vez por post):
1. `recordView(entry.id)` → RPC `record_changelog_view`.
2. `supabase.rpc("mark_changelog_seen", { p_entry_ids: [entry.id] })` → **marca o post como visto para o usuário no servidor**, fazendo o balão de novidades sumir. Erro é silencioso.

**Anatomia:**

| # | Bloco | Detalhe |
|---|---|---|
| 1 | Cabeçalho (`#post-overview`) | Badge do tipo (ícone + rótulo, com a cor do tipo) + chip mono da versão + chip da data por extenso. Título com barra de acento + H1 `text-3xl sm:text-4xl`. Resumo `text-lg text-justify` |
| 2 | Linha de meta | `por {author}` · separador `·` · `👁 N visualizações` · **`ver quem viu`** (condicional) · chips de `tags` (ícone `Tag`, pílula neutra) |
| 3 | Seções | Idênticas ao guia de Negócio: `SectionReveal` + `SectionHeader` (com âncora) + `lead` + `blocks` + `body` |
| 4 | **"O que mudou"** | Faixa `rounded-xl border bg-muted/30` com barra `bg-primary/60` + título. Texto: *"As peças da Torre afetadas por esta novidade. Cada chip leva à documentação do item — telas, tópicos e peças técnicas."* Contém 3 faixas: `GuideBacklinks` ("Telas afetadas" · "no manual de Negócio"), `TopicBacklinks` ("Tópicos relacionados" · com cadeado), `AtomBacklinks` ("o que mudou por dentro" · com cadeado) |
| 5 | **Barra de reações** (`#post-reactions`) | `SectionHeader` com título **"Gostou da novidade?"**. Ver §6.5 |
| 6 | **Anterior / Mais recente** | `<nav aria-label="Navegação entre novidades">` `grid sm:grid-cols-2`. **Esquerda** = `next` (post mais **antigo**), rotulado `← ANTERIOR`. **Direita** = `prev` (post mais **recente**), rotulado `MAIS RECENTE →`, alinhado à direita. Quando não há `next`, renderiza `<span />` para preservar a coluna |

> ⚠️ **Assimetria de cadeado documentada no próprio código:** um comentário registra que *"`GuideBacklinks` não tem cadeado embutido; sem acesso a Negócio o chip ainda navega, mas a rota de destino aplica seu próprio gate."* Como compensação, quando `!canNegocio` e há guias relacionados, aparece a nota `"O acesso às telas de Negócio depende do seu perfil."` em `text-[11px] text-muted-foreground/70`. **Inconsistência a resolver no redesign.**

### 6.5 Engajamento: reações e visualizações (`useChangelogEngagement.ts`)

**Arquitetura:** usa o **client base** do Supabase (schema `public`), **não** o `orgClient` — *"o engajamento é por usuário/entrada, não por tenant"*. TanStack Query, `staleTime: 30_000`, `retry: false`.

**Três RPCs (assinaturas fixas):**

| RPC | Entrada | Saída |
|---|---|---|
| `get_changelog_engagement` | `p_entry_ids text[]` | linhas `{ entry_id, views, reactions(jsonb {emoji:count}), my_reaction }` |
| `record_changelog_view` | `p_entry_id text` | — |
| `toggle_changelog_reaction` | `p_entry_id, p_emoji` | emoji novo (string) ou `null` (removida) |

**DEGRADAÇÃO ELEGANTE — padrão-chave a preservar no redesign.** O comentário do arquivo é explícito: *"a migration pode ainda não existir no ambiente. Se uma RPC falhar (404/erro), tratamos como engajamento ZERO e marcamos `available=false` — a UI desabilita a reação com um tooltip 'disponível em breve', SEM toasts de erro e SEM quebrar a página."*

Isso se materializa na UI:
- Texto acima da barra: `available` → *"Deixe sua reação — ajuda a equipe a entender o que faz diferença pra você."* / indisponível → *"As reações estarão disponíveis em breve."*
- Botões com `disabled`, `cursor-not-allowed opacity-50` e `title="Disponível em breve"`.

**Barra de reações:** 5 emojis **fixos**, nessa ordem: `🎉 👍 ❤️ 🚀 👀` (`REACTION_EMOJIS`). Cada botão é uma pílula `rounded-full border px-3 py-1.5`:
- **Minha reação** (`mine`): `border-primary/50 bg-primary/10 text-primary`, `aria-pressed={true}`
- Outras: `border-border bg-card text-foreground/85` com hover primary
- Contagem em `fdd-mono text-xs tabular-nums`, **só quando > 0**

**Toggle otimista (`useToggleChangelogReaction`):** `onMutate` cancela queries, guarda o `previous` e atualiza o cache imediatamente — decrementa a reação anterior, aplica a regra *"clicar no mesmo emoji remove; outro emoji troca"*, e **limpa contagens zeradas**. `onError` reverte para o `previous` ou marca `available: false` (**sem toast**). `onSettled` invalida a query.

### 6.6 Popover de pessoas (`ChangelogPeoplePopover.tsx`)

> Nota do arquivo: *"os exports mantêm o sufixo `...Popover` por compatibilidade com o caller, mas a implementação agora é um **modal**"* (`Dialog` do shadcn). Motivo declarado: *"mais espaço, nomes/emails quebram linha (sem corte), lista rolável."*

**Gate:** `canSeePeople = isSuperAdmin || currentRole === "owner" || currentRole === "admin"`. As RPCs **negam** acesso aos demais perfis (lançam erro no banco) — o gate do frontend impede a chamada. Qualquer erro residual degrada para lista vazia, sem toast.

**Dois modais:**

| Componente | Gatilho | RPC | Conteúdo |
|---|---|---|---|
| `ChangelogViewersPopover` | pílula `👥 ver quem viu` (na linha de meta) | `get_changelog_viewers(p_entry_id)` | Lista plana de pessoas; trailing = `"visto há X"` |
| `ChangelogReactorsPopover` | pílula `👥 ver quem reagiu` (abaixo da barra) | `get_changelog_reactors(p_entry_id)` | **Agrupado por emoji** (preservando a ordem de chegada dos grupos), com cabeçalho `<emoji> <contagem mono>`; trailing = `"há X"` |

**`TriggerPill`:** pílula discreta `rounded-full border bg-card px-2.5 py-1 text-[11px]` com ícone `Users`. Implementada com `forwardRef` + spread de props — o comentário avisa que isso é **obrigatório** porque o `DialogTrigger asChild` (Radix Slot) injeta `onClick`/`aria`/`ref` no filho.

**`DialogContent` `sm:max-w-lg`**, `DialogHeader` com título ("Quem reagiu"/"Quem visualizou") e `DialogDescription` com o total (`"N reações"` / `"Sem reações ainda"`). Lista em container `max-h-[60vh] overflow-y-auto`.

**`PersonRow`:** `Avatar` `h-9 w-9` com `AvatarFallback` de **iniciais** (1ª letra do primeiro nome + 1ª do último; ou 2 primeiras letras se nome único; `?` se vazio) + nome (`fullName ?? email ?? "Usuário"`, `break-words`) + e-mail como meta quando há ambos + trailing com tempo relativo (`formatDistanceToNow` do `date-fns` com locale `ptBR`, `addSuffix: true`, envolto em try/catch).

**Estados:** carregando → `LoadingRows` (4 linhas de `Skeleton`: círculo `h-9 w-9` + 2 barras) com `aria-busy`. Vazio → `EmptyState` centralizado: *"Ninguém reagiu ainda."* / *"Nenhuma visualização ainda."*

### 6.7 Dois sistemas de "não lidos" — não confundir

Este é o ponto mais sutil do pilar. **Existem DOIS mecanismos paralelos e independentes:**

| | `useChangelogUnread` | `useChangelogNotifications` |
|---|---|---|
| **Fonte** | `localStorage` (`torre.changelog.lastSeen`) | Banco, RPC `get_unseen_changelog` |
| **Escopo** | Por **navegador** | Por **usuário** (cross-device) |
| **Alimenta** | Badge do banner do hub (`ChangelogFeature`) · Selo "Novo" nos cards do feed · Badge do botão da sidebar | **Balão de novidades** ao entrar na Torre |
| **Marcar visto** | `markChangelogSeen()` grava a data da entrada mais recente | RPC `mark_changelog_seen(p_entry_ids)` |
| **Degradação** | `try/catch` silencioso; SSR-safe | Erro → lista vazia (balão some), sem toast |

**`useChangelogUnread` (localStorage):**
- `useSyncExternalStore` sobre um `subscribe` que ouve **dois** eventos: o `storage` nativo (mudança **entre abas**) e um evento custom `"torre:changelog-seen"` (mudança **na mesma aba**, disparado por `markChangelogSeen`).
- `computeUnread(lastSeen)`: se `lastSeen === null` (nunca visto), retorna `Math.min(ENTRIES.length, RECENT_CAP=5)` — o comentário justifica: *"conta as entries RECENTES (até `RECENT_CAP`) para chamar atenção sem inflar o número."* Caso contrário, conta `date > lastSeen`.
- `badge`: `"9+"` acima de 9, o número entre 1 e 9, `""` quando zero.
- `isEntryNew(dateISO, lastSeen)`: `true` quando nunca visto; senão `dateISO > lastSeen` (comparação lexicográfica de ISO — correta para `yyyy-mm-dd`).

**`useChangelogNotifications` (servidor):**
- Query habilitada só com `currentOrg` **e** sessão ativa (checa `supabase.auth.getSession()` antes de chamar a RPC). `staleTime: 60_000`, `retry: false`.
- Manda **todos** os ids do feed como universo e recebe de volta só os não vistos; mapeia de volta para os objetos completos preservando a ordem do feed.
- Expõe `unseen`, `count`, `markSeen(ids?)` e `markAllSeen()`.

---

## 7. Grafo de referência (`CentralDocsGraph` / `GraphPage`)

### 7.1 Identidade e carregamento

| Item | Valor |
|---|---|
| Rota tela cheia | `/central-docs/grafo` (`src/pages/central-docs/GraphPage.tsx`, 73 linhas) |
| Componente | `src/pages/central-docs/CentralDocsGraph.tsx` (819 linhas) |
| Permissão | `docs:tecnica` |
| Libs | `react-force-graph-3d` + `three` (WebGL) |
| Embutido também em | `/central-docs` (hub), altura `h-[60vh]` |

**Lazy obrigatório.** Os dois consumidores (`GraphPage` e `GraphFeature`) importam via `React.lazy` + `<Suspense>`: *"importa `react-force-graph-3d` + `three` (pesado). É montado SOB DEMANDA … fora do bundle main."* O fallback é sempre um spinner + `"Carregando o grafo 3D…"`.

**Layout da `GraphPage`:** `flex min-h-screen flex-col`; topbar com `← Central de Documentação` + ícone `Network` + "Grafo de referência"; abaixo, uma linha de legenda com `BookMarked` e a frase *"Tudo conectado a tudo: cada nó é um átomo; as linhas são as relações entre eles."*; e o canvas ocupando `flex-1` dentro de `rounded-2xl border bg-gradient-to-br from-card to-primary/[0.04]`, altura `h-[calc(100vh-9rem)]`.

### 7.2 Cores no canvas — regra especial

O comentário do arquivo declara a exceção: *"o canvas WebGL não usa classes Tailwind — lemos as CSS vars do tema via `getComputedStyle`. A cor POR TIPO usa paleta fixa HSL."*

- `readThemeColors()` lê `--background`, `--foreground`, `--muted-foreground` e `--primary` do `<html>` e monta strings `hsl(...)`. Tem fallbacks para SSR.
- Um `MutationObserver` observa `attributeFilter: ["class"]` no `<html>` e **re-lê as cores quando o tema claro/escuro muda**.

**Paleta fixa por tipo (`KIND_GRAPH_COLOR`)** — *"pensada para ler bem sobre fundo claro e escuro. Tipos próximos compartilham a mesma faixa para não virar arco-íris."*

| Kind | HSL | Kind | HSL |
|---|---|---|---|
| `endpoint` | `hsl(210, 90%, 56%)` | `cron` | `hsl(38, 92%, 55%)` |
| `mcp-tool` | `hsl(199, 89%, 52%)` | `trigger` | `hsl(330, 75%, 62%)` |
| `webhook-event` | `hsl(330, 75%, 60%)` | `helper` | `hsl(142, 60%, 48%)` |
| `edge-function` | `hsl(221, 83%, 60%)` | `variable` | `hsl(280, 65%, 64%)` |
| `table` | `hsl(174, 62%, 47%)` | `integration` | `hsl(160, 60%, 45%)` |
| `view` | `hsl(186, 62%, 50%)` | `page` | `hsl(217, 85%, 58%)` |
| `mv` | `hsl(192, 70%, 48%)` | `hook` | `hsl(255, 70%, 65%)` |
| `rpc` | `hsl(265, 75%, 64%)` | `permission` | `hsl(0, 75%, 60%)` |
| | | `role` | `hsl(12, 80%, 58%)` |

> ⚠️ **Terceira paleta do sistema.** Existe uma paleta de kind por token (`KIND_META.badgeClass`, §4.2) e esta paleta HSL fixa para o canvas. São **independentes** e podem divergir — um redesign precisa decidir se as unifica.

### 7.3 Anatomia do canvas

| Elemento | Posição | Detalhe |
|---|---|---|
| Canvas 3D | fundo | `ForceGraph3D` com `controlType="orbit"`, `nodeRelSize={4}`, `nodeOpacity={0.92}`, `nodeResolution={12}`, `enableNodeDrag`, `showNavInfo={false}` |
| **Busca** (`SearchBox`) | overlay `absolute left-3 top-3`, largura `w-[min(82vw,260px)]` | Card `rounded-lg border-border/60 bg-background/85 backdrop-blur` com ícone `Search`, input, botão `X`. Dropdown com **até 12** resultados (`max-h-56 overflow-y-auto`), cada um com bolinha da cor do kind + nome truncado + rótulo do kind à direita. `Enter` seleciona o 1º resultado; `Escape` limpa |
| **Filtro por tipo** (`KindFilter`) | abaixo da busca | Card com rótulo `TIPOS` e link `mostrar todos` (só quando há filtro). Cada tipo é um botão com bolinha: **ligado** = bolinha preenchida + texto normal; **desligado** = bolinha só com borda + texto `line-through` esmaecido. **Clique alterna · duplo clique ISOLA** (solo). Container `max-h-48 overflow-y-auto` |
| **Painel de conexões** (`ConnectionsPanel`) | overlay `absolute right-3 top-14`, `w-[min(86vw,288px)]` | Só com nó selecionado. Ver §7.5 |
| **Dica de controles** | `absolute bottom-3 left-3`, oculta em `<sm` | `"arraste para girar · scroll p/ zoom · clique = selecionar · duplo-clique = abrir"` |
| **Botão recentralizar** | `absolute right-3 top-3` | Ícone `Crosshair` + rótulo (oculto em `<sm`); limpa a seleção e chama `zoomToFit(600, 60)` |

### 7.4 Interação — o comportamento exato a preservar

| Ação | Efeito |
|---|---|
| **1 clique** num nó | Seleciona: anima a câmera até o nó (`cameraPosition`, 800ms) e, 820ms depois, **fixa o alvo da órbita no nó** (passa a orbitar em torno dele). Abre o painel de conexões |
| **Duplo clique** (mesmo nó, <350ms) | `navigate(/central-docs/atom/:id)` — abre a página do átomo |
| Clique no fundo | Desfaz a seleção |
| Hover | Realce temporário (cor/links), sem abrir painel |
| Arrastar nó | Permitido (`enableNodeDrag`) |

**Controles de órbita afinados (`tuneControls`):** `minDistance: 40`, `maxDistance: 2200`, `zoomSpeed: 0.9`, `rotateSpeed: 0.7`, `enableDamping: true`, `dampingFactor: 0.14`. Comentário: *"zoom estável, com distância mín/máx travada — sem o 'zoom que escapa' do trackball."*

**Auto-enquadramento que respeita o usuário:** ao parar a simulação (`onEngineStop`), o grafo chama `zoomToFit(400, 80)` — **mas só se o usuário ainda não interagiu**. Um listener de `wheel`/`pointerdown` no container marca `userMovedRef = true`, *"assim o zoom não 'volta sozinho'"*.

**Escala visual dos elementos:**

| Propriedade | Regra |
|---|---|
| Tamanho do nó (`nodeVal`) | `1 + connections * 1.6`; nó selecionado × **1.8** |
| Cor do nó | cor do kind; **fora do conjunto em foco** → `muted` com alpha `0.16` (desbota) |
| Largura do link | `1.6` se toca o nó ativo, senão `0.5` |
| Cor do link | ativo → `primary`; outros com foco ativo → `muted` alpha `0.07`; buscando → `muted` alpha `0.1`; neutro → `muted` alpha `0.26` |
| Setas direcionais | `linkDirectionalArrowLength={3.2}`, `RelPos={1}` |
| **Partículas animadas** | `2` partículas só nos links que tocam o nó ativo, largura `2`, velocidade `0.006` |

**Labels 3D — decisão de performance deliberada.** Sprites de canvas só para: (a) os resultados da busca, **ou** (b) o nó selecionado + seus vizinhos diretos. O comentário: *"assim os nomes não se sobrepõem com o grafo inteiro"*, e o `useMemo` de `labeledIds` **não depende do hover** *"p/ não reconstruir sprites a cada frame"*.

**`makeLabelSprite`:** desenha uma pílula arredondada (raio 20) num `<canvas>` de fonte 64px, fundo `primary` a 96% quando selecionado ou `rgba(15,18,28,0.9)` com borda branca 16% quando vizinho; texto branco; vira `THREE.CanvasTexture` → `SpriteMaterial` → `Sprite`, posicionado acima da esfera, `renderOrder: 10`. **O raycast do sprite é desativado** (`sprite.raycast = () => {}`) para o clique atravessar e acertar a esfera do nó.

**Tooltip nativo do grafo (`nodeLabel`)** é HTML injetado: caixa escura `rgba(15,18,28,0.92)` com o nome em negrito e o rótulo do kind abaixo em 70% de opacidade, `max-width: 260px`. O texto passa por `escapeHtml`.

### 7.5 Painel de conexões

Card `rounded-xl border-border/70 bg-background/90 backdrop-blur` com três zonas:

1. **Cabeçalho**: bolinha da cor do kind + título do átomo (truncado) + linha `{rótulo do kind} · {N} conexõ(es)` + botão `X` de fechar.
2. **Listas** (`max-h-[min(46vh,360px)] overflow-y-auto`): dois grupos, `Saídas (N)` e `Entradas (N)`, cada item (`ConnRow`) é um **botão** com bolinha da cor do kind, nome truncado e, abaixo, o **rótulo da relação** na direção correta (`REL_LABELS[rel].out` / `.in`). Clicar **seleciona o vizinho** (navega dentro do grafo, não sai da página). Vazio → *"Sem conexões."*
3. **Rodapé**: botão `🔗 Abrir página do átomo` (borda superior, `text-primary`, hover `bg-primary/10`).

> Nota: o painel filtra `outgoing` por `o.target` — ou seja, **arestas órfãs não aparecem no grafo**, diferente da AtomPage (que as mostra como linha não-clicável).

---

## 8. Catálogo de blocos visuais de documentação (DocBlocks)

Este é o **vocabulário visual compartilhado** por três pilares da Central: **Tópicos**, **Negócio** e **Novidades**. Um autor de documentação escreve dados (`TopicBlock[]`), nunca JSX, e o `BlockRenderer` monta a página.

**Fontes:** `src/pages/central-docs/shared/DocBlocks.tsx` (628 linhas) + `src/components/fonte-de-dados-docs/primitives.tsx` (importado: `Callout`, `KeyValue`, `Panel`, `SubBlock`, `WhatIs`) + `src/pages/central-docs/topics/types.ts` (o tipo `TopicBlock`).

Regra de arquitetura declarada no cabeçalho do módulo: *"este módulo exporta SÓ componentes (sem mistura com dados)"* — restrição do react-refresh.

### 8.1 Tabela-resumo dos 14 tipos de bloco

| `kind` | Nome | Para que serve | Aparência resumida |
|---|---|---|---|
| `prose` | Prosa | Parágrafo ou lista de bullets | `RichBody`: string → `<p>` justificado `text-[15px]` muted; array → `<ul>` com marcadores circulares azuis |
| `whatIs` | O que é | Definição em linguagem simples + nota técnica | Card azul claro `border-primary/20 bg-primary/[0.04]`, rótulo "o que é", opcional rodapé "por baixo" |
| `panels` | Cards-conceito | Grade de conceitos curtos lado a lado | `grid sm:grid-cols-2` de `Panel` interativos, rótulo mono azul + prosa |
| `stats` | Métricas | Números em destaque | `grid sm:grid-cols-3` de `StatBlock`, valor grande mono com **count-up** |
| `keyValue` | Chave→Valor | Fatos técnicos (campo, default…) | `<dl>` com linhas divididas, chave mono uppercase à esquerda (180px) |
| `table` | Tabela | Comparativos e referências | Tabela com cabeçalho **sticky**; altura limitada a 28rem ou `fullHeight` |
| `callout` | Aviso | Invariante, alerta, dica | `Callout` com 5 níveis (info/warning/danger/ok/note), ícone + cor |
| `steps` | Passos | Sequência numerada | Timeline com quadrado numerado `bg-primary/10` + chips de átomo |
| `atoms` | Chips de átomo | Ligar para peças técnicas | Linha de `AtomLink` com rótulo opcional |
| `code` | Código | Snippet ilustrativo | `<pre>` mono `bg-muted/40` + **botão copiar** que aparece no hover |
| `screenshot` | Print de tela | Mostrar a tela real | Com `src`: moldura de **janela de navegador** + lightbox. Sem `src`: placeholder tracejado |
| `flow` | Linha do tempo de execução | Trace "quando → quem → o quê" | Timeline vertical que **se desenha**, com payload colapsável e Callout de resultado |
| `subBlock` | Sub-bloco | Agrupar blocos sob um subtítulo (1 nível) | `SubBlock` com kicker + título + lead, contendo blocos filhos |
| *(default)* | — | tipo desconhecido | Retorna `null` (falha silenciosa e segura) |

### 8.2 Blocos de conteúdo — detalhe

#### `prose` — `RichBody`
```ts
{ kind: "prose", text: RichText }   // RichText = string | string[]
```
- **String** → `<p class="text-[15px] leading-relaxed text-muted-foreground text-justify">`.
- **Array** → `<ul class="flex flex-col gap-1.5">`, cada item com um marcador `h-1.5 w-1.5 rounded-full bg-primary/60` (bolinha azul) alinhado no topo (`mt-2`) e texto `text-sm text-foreground/85`.
- **Quando usar:** narrativa corrida (string) vs. enumeração curta (array). O `RichText` polimórfico aparece em quase todos os blocos.

#### `whatIs` — `WhatIs` (primitivo)
```ts
{ kind: "whatIs", body: string, tech?: string }
```
- Card `rounded-xl border border-primary/20 bg-primary/[0.04] p-5`.
- Rótulo fixo `o que é` em `fdd-mono text-[10px] uppercase tracking-[0.16em] text-primary`.
- Corpo em `text-[15px] text-foreground` (alto contraste — é a definição).
- `tech` opcional: separado por `border-t border-primary/15`, precedido de uma micro-pílula `por baixo` (`bg-muted text-primary/80`), em `text-sm text-muted-foreground`.
- **Quando usar:** abrir uma seção definindo o conceito para quem não é técnico, sem perder a nota de implementação.

#### `panels` — grade de `Panel`
```ts
{ kind: "panels", items: [{ label?, title?, body: RichText }] }
```
- `Stagger` + `grid gap-3 sm:grid-cols-2`, cada item com `--i` (atraso escalonado).
- `Panel interactive h-full hover:-translate-y-0.5 hover:border-primary/40`: card `rounded-2xl border bg-card p-5` com sombra dupla no hover.
- Rótulo (`label ?? title`) em `fdd-mono text-xs uppercase tracking-wide text-primary`; corpo em `text-sm text-foreground/90`.
- **Quando usar:** 2 a 6 conceitos paralelos de peso semelhante (ex.: "os 3 modos", "as 4 dispositions").

#### `stats` — grade de `StatBlock`
```ts
{ kind: "stats", items: [{ value, label, hint?, tone? }] }
// tone: "default" | "primary" | "ok" | "warning" | "danger"
```
- `Stagger` + `grid sm:grid-cols-3`.
- Card `rounded-xl border bg-card px-4 py-3` com hover `border-primary/40` + sombra.
- Valor em `fdd-mono text-2xl font-semibold tabular-nums`, com a cor do `tone` (`default`→foreground, `primary`→primary, `ok`→success, `warning`→warning, `danger`→destructive).
- Rótulo `text-xs uppercase tracking-wide muted`; `hint` `text-xs muted/80`.
- **Count-up:** regex `/^(\D*)([\d.,]+)(.*)$/s` extrai prefixo + número + sufixo. Anima de 0 até o número **apenas se for inteiro finito**; renderiza `prefixo + counted.toLocaleString("pt-BR") + sufixo`. Valores não-numéricos ficam estáticos. Dispara com `useInView({threshold: 0.3})`.
- **Quando usar:** números que sustentam uma afirmação (volumes, prazos, contagens). O count-up premia a rolagem.

#### `keyValue` — `KeyValue` (primitivo)
```ts
{ kind: "keyValue", rows: [{ k: string, v: RichText }] }
```
- `<dl class="divide-y divide-border/70 rounded-xl border">`; cada linha é `grid sm:grid-cols-[180px_1fr] gap-4` (empilha em mobile).
- Chave (`<dt>`) em `fdd-mono text-xs uppercase tracking-wide muted`; valor (`<dd>`) em `text-sm text-foreground/90`, via `RichCell`.
- **Quando usar:** ficha de fatos curtos (campo → default, parâmetro → significado). É o equivalente narrativo da "Ficha técnica" do átomo.

#### `table` — tabela com cabeçalho sticky
```ts
{ kind: "table", columns: string[], rows: RichText[][], fullHeight?: boolean }
```
- **Dois modos**, documentados no tipo:
  - **Padrão** (`fullHeight` ausente): `max-h-[28rem] overflow-auto rounded-xl border`; cabeçalho `sticky top-0 z-10`. A tabela rola por dentro.
  - **`fullHeight: true`**: `overflow-x-auto` apenas; a tabela cresce inteira e o cabeçalho gruda em `sticky top-14` (abaixo do header de página, que tem `3.5rem`). O comentário justifica: o scroll interno *"esconde o conteúdo e atrapalha o Ctrl+F da página"* numa tabela de referência longa.
- Cabeçalho: `bg-muted/95 backdrop-blur supports-[backdrop-filter]:bg-muted/80`, células `text-[10px] uppercase tracking-wider muted`.
- Linhas: `border-b border-border/60 align-baseline hover:bg-muted/40`, última sem borda. Células `px-3 py-2 text-foreground/85`, conteúdo via `RichCell` (array → mini-lista sem marcador).
- **Quando usar:** comparativo (2-8 linhas, padrão) ou referência exaustiva (`fullHeight`).

#### `callout` — `Callout` (primitivo)
```ts
{ kind: "callout", level: "info"|"warning"|"danger"|"ok"|"note", title?, body: RichText }
```
Container `flex gap-3 rounded-xl border px-4 py-3 text-sm`, `role="note"`, com ícone à esquerda e título opcional em negrito. Código inline dentro do corpo é estilizado automaticamente (`bg-foreground/10 px-1 py-0.5 rounded`).

| `level` | Ícone | Borda | Fundo | Cor do ícone | Uso típico |
|---|---|---|---|---|---|
| `info` | `Info` | `border-info/30` | `bg-info/5` | `text-info` | contexto, nota neutra |
| `warning` | `AlertTriangle` | `border-warning/40` | `bg-warning/5` | `text-warning` | armadilha, cuidado |
| `danger` | `Flame` | `border-destructive/30` | `bg-destructive/5` | `text-destructive` | invariante que quebra produção |
| `ok` | `CheckCircle2` | `border-success/40` | `bg-success/5` | `text-success` | resultado esperado, boa prática |
| `note` | `Lightbulb` | `border-border` | `bg-muted/40` | `text-muted-foreground` | curiosidade, dica lateral |

#### `steps` — `StepsList`
```ts
{ kind: "steps", items: [{ title, detail?: RichText, atoms?: string[] }] }
```
- `<ol class="flex flex-col gap-4">`; cada passo é `flex gap-3.5`.
- **Marcador**: quadrado `h-7 w-7 rounded-lg bg-primary/10 text-primary` com o número em `fdd-mono text-xs font-semibold` (tint, não saturado — diferente do `FlowStepRow` do átomo).
- Título `font-medium text-foreground`; `detail` via `RichBody`; `atoms` viram linha de `AtomLink`.
- **Sem linha conectora vertical** (ao contrário do `flow` e do fluxo do átomo).
- **Quando usar:** procedimento ou sequência lógica onde o "quando" não importa. Se o gatilho importa, use `flow`.

#### `atoms` — `AtomChips`
```ts
{ kind: "atoms", label?: string, ids: string[] }
```
- Rótulo opcional em `text-[10px] uppercase tracking-wider muted`; abaixo, `flex flex-wrap gap-1.5` de `AtomLink`.
- Retorna `null` se a lista está vazia.
- **Quando usar:** fechar uma seção apontando as peças técnicas envolvidas.

#### `code` — `CodeBlock` (do DocBlocks)
```ts
{ kind: "code", label?: string, code: string }
```
- Linha superior: `label` em `text-[10px] uppercase` à esquerda e o **botão copiar à direita**, que é `opacity-0` e só aparece em `group-hover/code` ou `focus-within` — **acessível por teclado mesmo invisível**.
- Corpo: `<pre class="fdd-mono overflow-x-auto rounded-lg border bg-muted/40 p-3 text-xs">`.
- **`CopyButton`**: `navigator.clipboard.writeText`, com feedback de 1600ms. Estado copiado: `border-success/40 bg-success/10 text-success` + ícone `Check` + texto "Copiado". Estado normal: ícone `Copy` + "Copiar". Falha de clipboard (http/sem permissão) é **silenciosa**. `aria-label` alterna.
- **Regra de conteúdo (do tipo):** *"Snippet ilustrativo (SQL/payload/chamada) — NUNCA código-fonte interno."*

#### `screenshot` — `ScreenshotBlock`
```ts
{ kind: "screenshot", alt, src?, caption?, aspect?: "wide"|"tall"|"square", url? }
```
**Dois modos radicalmente diferentes:**

**(a) Com `src` — moldura de janela de navegador** (*"mesmo design da Documentação Especial"*):
- `<figure class="overflow-hidden rounded-xl border bg-card shadow-[0_24px_60px_-32px_rgba(0,0,0,0.55)]">`
- **Chrome da janela**: barra `border-b bg-muted/70 px-3 py-2` com três bolinhas (`h-3 w-3 rounded-full`: `destructive/70`, `warning/70`, `success/70`) e uma **barra de endereço** falsa `rounded-md border bg-background` com cadeado (`Lock`) + `cobranca.finza.com.br{url}` em `font-mono text-[11px]`. O campo `url` define a rota mostrada.
- A imagem é um **botão** `cursor-zoom-in` com `aria-label="Ampliar imagem: {alt}"` que abre um **lightbox**: `DialogContent fullscreen` sem chrome de card, com a imagem em `max-h-[88vh] max-w-[94vw] object-contain` e o caption centralizado. Um comentário no código explica que esse lightbox foi feito para funcionar com **qualquer aspecto** (imagens muito largas ou muito altas deslocavam/estouravam o dimensionamento padrão do card).
- `caption` também aparece embaixo, na faixa `border-t bg-muted/30 px-4 py-2.5 text-xs`.
- `loading="lazy"` na imagem inline.

**(b) Sem `src` — placeholder de captura pendente:**
- `border-2 border-dashed border-border bg-gradient-to-br from-muted/30 to-primary/[0.04] p-6`, respeitando o aspecto (`wide`→`aspect-[16/9]`, `tall`→`aspect-[3/4]`, `square`→`aspect-square`; default `wide`).
- Quadrado `h-11 w-11 rounded-xl bg-primary/10 text-primary` com `ImageIcon`.
- Texto `Print: {alt}` e, abaixo, a micro-instrução `substituir depois` em `text-[11px] uppercase tracking-wider muted/70`.
- `role="img"` + `aria-label="Print de tela: {alt}"`.
- **Quando usar:** escrever o guia antes de ter o print — o placeholder documenta **o que** precisa ser capturado.

#### `flow` — `FlowTimeline`
```ts
{ kind: "flow", title?, intro?: RichText, frames: FlowFrame[], outcome?: RichText }
// FlowFrame = { when: string; atom?: string; actor?: string; does: RichText; data?: { label?, code } }
```
O bloco mais elaborado. É o "trace de execução": **quando → quem → o quê**, opcionalmente com estado/payload.

- Título opcional `font-semibold`; `intro` via `RichBody`.
- `<ol class="relative flex flex-col gap-5 pl-5">` com **duas trilhas sobrepostas**:
  1. base estática `absolute left-0 top-1 bottom-1 w-px bg-border/70`;
  2. **barra de progresso `fdd-timeline-fill`** `bg-primary` que cresce `scaleY 0→1` em 0.9s (`cubic-bezier(0.22,1,0.36,1)`) quando a lista entra na viewport (`useInView({threshold: 0.12})`). É o efeito de "desenhar o conector".
- **Cada frame (`FlowFrameItem`):**
  - **Bolinha** `absolute -left-[1.4rem] h-2.5 w-2.5 rounded-full bg-primary` com anel `shadow-[0_0_0_3px_hsl(var(--background))]`, que **cresce `scale-125` no hover do frame**.
  - Fundo do frame ganha `bg-muted/40` no hover (`-mx-2 rounded-xl px-2 py-1.5`).
  - **Badge do gatilho** (`when`): pílula `fdd-mono border-primary/30 bg-primary/10 text-primary text-[11px]`, que escurece a borda no hover. Ex.: `"cron a cada 5min"`, `"days_overdue ∈ [step.min, step.max]"`.
  - **Ator**: `AtomLink` quando há `atom`; senão, pílula mono neutra com o `actor` textual (ex.: "pg_cron", "Usuário", "Provedor (n8n)").
  - `does` via `RichCell`.
  - **Disclosure de payload** (quando há `data`): botão `⌗ Ver estado/payload` ⇄ `Ocultar estado/payload` com `aria-expanded`, abrindo um `CodeBlock` dentro de um container `.fdd-collapse` (animação de altura via `grid-template-rows: 0fr → 1fr`, 0.28s).
- **`outcome`**: renderizado como `Callout level="ok" title="Resultado"` no rodapé.
- **Quando usar:** explicar um fluxo onde o **gatilho** de cada etapa é a informação relevante, e/ou quando o leitor ganha em "rodar o cenário na cabeça" com payloads reais.

#### `subBlock` — `SubBlock` (primitivo)
```ts
{ kind: "subBlock", title: string, kicker?: string, lead?: RichText, blocks: TopicBlock[] }
```
- Envolto em `Reveal`.
- `kicker`: pílula `fdd-mono rounded-md bg-primary/10 text-[10px] uppercase tracking-[0.16em] text-primary`.
- Título: barra de acento `h-6 w-1.5 rounded-full bg-primary` + `<h3 class="text-xl sm:text-2xl font-semibold">`.
- `meta` (chip mono à direita do título) existe no primitivo, mas **o `Block` do DocBlocks não o repassa** — só `title`, `kicker` e `lead`.
- `lead` em `text-[15px] muted`, `max-w-5xl`.
- Corpo: `space-y-5` com os blocos filhos renderizados recursivamente.
- **Aninhamento é de 1 nível** (declarado no tipo), mas a recursão do `Block` tecnicamente permitiria mais.

### 8.3 Componentes de moldura e microinteração

| Componente | O que faz |
|---|---|
| `Stagger` | Container `fdd-stagger` + `data-shown` do `useInView`. Cada filho direto precisa receber `style={{"--i": i}}` — o CSS aplica `transition-delay: calc(var(--i) * 70ms)` |
| `SectionReveal` | `fdd-reveal` + `data-shown` — fade + subida de 14px em 0.6s, uma vez |
| `BlockRenderer` | `Stagger` com `mt-4 flex flex-col gap-5`, um `<div style="--i">` por bloco. **É o ponto de entrada** usado por `TopicPage`, `PageGuidePage` e `ChangelogPostPage` |
| `SectionHeader` | Cabeçalho de seção: barra de acento `h-6 w-1 bg-primary` + quadrado de ícone `h-8 w-8 bg-primary` com sombra + `<h2 class="text-lg font-semibold">` + **âncora `#`** (`Hash`) que aparece no hover (`.fdd-anchor` + `group/sec`) e no `focus-visible`. Borda inferior `border-border/70` |
| `RichCell` | Versão inline do `RichBody`: array → `<ul>` sem marcador (`gap-0.5`); string → fragmento cru. Usado em células de tabela, keyValue e painéis |
| `CopyButton` | Botão de copiar com feedback de 1600ms (ver `code`) |
| `AtomChips` | Linha de chips de átomo com rótulo |
| `StatBlock` | Stat com count-up (ver `stats`) |

### 8.4 Comparação: `StatBlock` (DocBlocks) × `Stat` (primitives)

São **dois componentes diferentes** com a mesma aparência:

| | `Stat` (`primitives.tsx`) | `StatBlock` (`DocBlocks.tsx`) |
|---|---|---|
| Valor | `ReactNode` livre | `string` (parseada) |
| Animação | nenhuma | **count-up** |
| Hover | nenhum | `border-primary/40` + sombra |
| Usado em | Fonte de Dados (`/docs/fonte-de-dados`) | Central de Docs (bloco `stats`) |

O mesmo acontece com `CodeBlock`: existe um em `DocBlocks.tsx` (com copiar), um em `src/components/docs/CodeBlock.tsx` (`/docs`) e um `CodeViewer.tsx` no fonte-de-dados-docs. **Três implementações de bloco de código no produto** — candidato óbvio a unificação no redesign.

### 8.5 Como o autor escolhe o bloco (guia de decisão derivado do código)

| Intenção | Bloco |
|---|---|
| Explicar um conceito para quem não é técnico | `whatIs` |
| Contar uma narrativa corrida | `prose` (string) |
| Enumerar pontos soltos | `prose` (array) |
| Mostrar 2-6 conceitos paralelos | `panels` |
| Dar peso a números | `stats` |
| Listar fatos curtos campo→valor | `keyValue` |
| Comparar até ~8 itens em colunas | `table` |
| Listar referência longa (dezenas de linhas) | `table` com `fullHeight: true` |
| Avisar sobre algo que quebra | `callout` (`danger`/`warning`) |
| Confirmar comportamento esperado | `callout` (`ok`) |
| Descrever um procedimento | `steps` |
| Descrever uma execução com gatilhos | `flow` |
| Mostrar um snippet | `code` |
| Mostrar a tela real | `screenshot` (com `src`) |
| Marcar print pendente | `screenshot` (sem `src`) |
| Apontar peças técnicas | `atoms` |
| Agrupar sob um subtítulo | `subBlock` |

---

## 9. Documentação pública da API (`/docs`)

### 9.1 Identidade

| Item | Valor |
|---|---|
| Rota | `/docs` — **a única rota de documentação sem nenhum guard** |
| Arquivo | `src/pages/DocsPage.tsx` (462 linhas) |
| Componentes | `src/components/docs/` — `DocsSidebar`, `EndpointCard`, `CodeBlock`, `searchIndex` + 5 arquivos de seções |
| Layout | Full-screen, header fixo + sidebar fixa + conteúdo em `ScrollArea` |
| Design system | **shadcn puro** (`Button`, `Input`, `ScrollArea`, `Badge`, `Alert`) — **não** usa `.fdd-*` |
| Estado da seção | `?section=<id>` na query string (sincronizado bidirecionalmente) |

**Diferença estrutural em relação à Central de Docs:** é uma **single-page com troca de seção**, não um conjunto de rotas. O conteúdo é **JSX hardcoded** (não data-driven): um componente React por seção, mapeado em `sectionComponents`.

### 9.2 Estrutura de navegação — 9 grupos, 33 seções

Fonte: `src/components/docs/DocsSidebar.tsx` (`docSections`).

| Grupo | Ícone | Seções |
|---|---|---|
| **Começando** | `PlayCircle` | Introdução · Autenticação · Quickstart |
| **API Reference** | `BookOpen` | Visão Geral · Contatos · Contratos · Títulos · Campanhas · Portfolios · Ações · Busca de Títulos |
| **Sincronização** | `Database` | Visão Geral · Sincronizar Contatos · Sincronizar Contratos · Sincronizar Títulos |
| **Webhooks** | `Webhook` | Visão Geral · Confirmação de Pagamento · Atualização de Status · Callbacks de Entrega |
| **Campanhas** | `Send` | Visão Geral · Disparar Campanha |
| **Filtros** | `Filter` | Visão Geral · Avaliar Filtros · Operadores |
| **Exportação** | `FileText` | Visão Geral · Exportar Portfolio |
| **Analytics** | `BarChart3` | Visão Geral · KPIs · Atribuição |
| **IA & Assistente** | `Bot` | Visão Geral · APIs de IA · Verificação de Pagamento · MCP Server |

Arquivos de implementação: `sections/GettingStartedSection.tsx` (359 linhas), `ApiReferenceSection.tsx` (1060), `SyncSection.tsx` (437), `WebhooksSection.tsx` (425), `OtherSections.tsx` (1591 — Filtros + Campanhas + Export + Analytics + IA).

### 9.3 Anatomia

**Header** (`sticky top-0 z-50 h-14 border-b bg-background/95 backdrop-blur`):

| Zona | Conteúdo |
|---|---|
| Esquerda | Botão hambúrguer (`Menu`/`X`, só `<lg`); link `← Voltar` para `/`; divisor; **logo quadrado `h-6 w-6 rounded bg-primary` com as letras "TC"** + "Documentação" |
| Centro | Barra de busca `flex-1 max-w-md mx-auto` |
| Direita | Botão ghost "GitHub" com `ExternalLink`, apontando para `https://github.com/finza-tech/torre-controle` (oculto em `<md`) |

> ⚠️ **A confirmar:** o link do GitHub aponta para `finza-tech/torre-controle`, enquanto o repo real citado no `CLAUDE.md` do projeto é `blips-ai/cobranca-finza`. Possível link morto.

**Sidebar** (`DocsSidebar`, `w-64 border-r bg-card overflow-y-auto`):
- Cabeçalho próprio: quadrado `h-8 w-8 rounded-lg bg-primary` com `BookOpen` + "Torre de Controle" / "API Documentation".
- Grupos separados por `space-y-6`; título do grupo em `text-xs font-semibold uppercase tracking-wider muted` com o ícone à esquerda.
- Itens: `<button>` `w-full text-left px-3 py-1.5 text-sm rounded-md`. **Ativo**: `bg-primary/10 text-primary font-medium`. Inativo: `text-muted-foreground hover:text-foreground hover:bg-muted`.
- **Desktop**: `<aside class="hidden lg:block sticky top-14 h-[calc(100vh-3.5rem)]">`.
- **Mobile**: overlay `fixed inset-0 z-40` com backdrop `bg-black/50` clicável + `<aside>` ancorado à esquerda. Escolher um item **fecha o menu**.

**Conteúdo** (`<main class="flex-1 min-w-0">`):
- `ScrollArea h-[calc(100vh-3.5rem)]` (rola um container, **não** a window — diferente da Central de Docs).
- Container `max-w-4xl mx-auto px-6 py-8`.
- **Breadcrumb**: `Docs / {título da seção}` em `text-sm muted`, com o último em `text-foreground`.
- Componente da seção ativa (fallback: `IntroductionSection`).
- **Navegação prev/next** (`PrevNextNavigation`): achata todas as seções numa lista linear e mostra dois botões `rounded-lg border hover:bg-muted`, com kicker `← Anterior` / `Próximo →` e o título. Quando não há vizinho, renderiza `<div />` (mantém o `justify-between`).
- **Footer**: `"Torre de Controle API Documentation • Suporte • Changelog"`.

> ⚠️ Os links "Suporte" e "Changelog" do footer são `href="#"` — **placeholders sem destino**.

### 9.4 Busca (`searchIndex.ts`)

Índice **estático e manualmente curado**: um objeto por seção com `{ id, title, section, description, keywords[] }`.

**`searchDocs(query)`:**
- Retorna `[]` se a query tem **menos de 2 caracteres**.
- `normalizeText`: lowercase + `normalize("NFD")` + remoção de diacríticos — **busca funciona sem acento**.
- Query é quebrada em palavras; cada palavra soma pontos:

| Condição | Pontos |
|---|---|
| Título **igual** à palavra | 100 |
| Título **começa com** a palavra | 50 |
| Título **contém** a palavra | 30 |
| Palavra é **keyword exata** | 40 |
| Palavra está **dentro de** alguma keyword | 20 |
| Descrição contém a palavra | 10 |
| Nome do grupo contém a palavra | 5 |

- Filtra `score > 0`, ordena desc, **limita a 10 resultados**.

**UI da busca:**
- `Input` com ícone `Search` à esquerda (`pl-9 h-9`) e botão `X` à direita (só com valor).
- Dropdown `absolute top-full mt-2 bg-popover border rounded-lg shadow-lg max-h-96 overflow-y-auto`.
- Cada resultado: ícone `FileText` + título em `font-medium text-sm` + linha `{grupo} • {descrição}` truncada. Item selecionado: `bg-accent`; hover: `bg-accent/50`. **O hover também move a seleção** (`onMouseEnter` → `setSelectedResultIndex`).
- **Vazio**: ícone `Search` grande `opacity-50` + *"Nenhum resultado encontrado para "{query}""* + dica *"Tente buscar por termos como "api", "webhook", "filtro""*.
- **Rodapé de atalhos** com `<kbd>` estilizados: `↑ ↓ navegar` · `Enter selecionar` · `Esc fechar`.

**Navegação por teclado (`handleSearchKeyDown`):** `ArrowDown`/`ArrowUp` circulam (wrap-around nos extremos), `Enter` abre o selecionado, `Escape` limpa e tira o foco. Também há um listener de `mousedown` no documento que fecha o dropdown ao clicar fora.

### 9.5 Cartão de endpoint (`EndpointCard`)

O bloco principal das seções de referência. Card `border rounded-lg overflow-hidden bg-card`, **colapsado por padrão**.

**Cabeçalho (sempre visível)** — `<button>` que alterna, com `hover:bg-muted/50`:
- `Badge` do método em `font-mono text-xs font-semibold`, com cor própria.
- A rota em `<code class="text-sm font-mono flex-1">`.
- O `title` em `text-sm muted` (oculto em `<sm`).
- `ChevronDown` (aberto) / `ChevronRight` (fechado).

**Paleta de métodos (própria — a 4ª do produto):**

| Método | Classe |
|---|---|
| `GET` | `bg-emerald-500/10 text-emerald-600 border-emerald-500/20` |
| `POST` | `bg-blue-500/10 text-blue-600 border-blue-500/20` |
| `PUT` | `bg-amber-500/10 text-amber-600 border-amber-500/20` |
| `PATCH` | **`bg-orange-500/10 text-orange-600`** (na Central é `violet`) |
| `DELETE` | `bg-red-500/10 text-red-600 border-red-500/20` |

> ⚠️ **Divergência real:** `PATCH` é **laranja** aqui e **violeta** em `atoms/http.tsx`. Além disso, esta paleta **não tem variante `dark:`** — as cores `-600` podem ficar escuras demais no tema escuro. Candidato a unificação.

**Corpo expandido** (`border-t p-4 space-y-6 bg-muted/20`), na ordem:

| # | Bloco | Detalhe |
|---|---|---|
| 1 | Descrição | `text-sm muted` |
| 2 | **Autenticação** | Rótulo + `Badge variant="secondary"`. Quatro valores: `api-key`→"API Key", `jwt`→"JWT Bearer", `webhook-secret`→"Webhook Secret", `none`→"Público". Default `api-key` |
| 3 | Headers | Caixa `bg-muted/50 rounded-lg p-3`; cada linha `<code class="text-primary">{nome}:</code> <code muted>{valor}</code> — {descrição}` |
| 4 | Parâmetros | Tabela HTML crua (não shadcn) com Nome · Tipo · Descrição. Nome em `text-primary` + `*` vermelho se obrigatório; `example` aparece como `Ex: <code>` numa linha abaixo. **A coluna Descrição some em `<sm`** |
| 5 | Request Body | `CodeBlock` `language="json"` + descrição opcional |
| 6 | Exemplo de Resposta | `CodeBlock` `language="json"` |
| 7 | **Exemplo cURL** | Gerado automaticamente por `generateCurlExample()` — **sempre presente** |

**`generateCurlExample`:** monta a cURL com `baseUrl = "https://seu-projeto.supabase.co/functions/v1"` (**placeholder literal**, não o `SUPABASE_URL` real), `Content-Type: application/json` fixo, e os headers de auth conforme o modo (`x-api-key` + `x-org-slug`, ou `Authorization: Bearer` + `x-org-slug`, ou `x-webhook-secret`). Headers customizados são adicionados pulando os que já existem. O body é **compactado para uma linha** via `JSON.parse` + `JSON.stringify` (com fallback para o texto cru).

### 9.6 Bloco de código (`components/docs/CodeBlock.tsx`)

**Visual completamente diferente** do `CodeBlock` do DocBlocks: é um bloco **sempre escuro**, com cores `slate-*` hardcoded (não segue o tema).

- Container `rounded-lg border bg-slate-950`.
- **Barra de título opcional**: `border-b border-slate-800 bg-slate-900 px-4 py-2` com o `title` em `text-slate-400` à esquerda e a `language` em `text-slate-500` à direita.
- `<pre class="p-4 overflow-x-auto text-sm">` com `<code class="text-slate-100 font-mono whitespace-pre">`.
- **Botão copiar**: `absolute top-3 right-3 p-2 rounded-md bg-slate-800 hover:bg-slate-700`, sempre visível. Feedback de **2000ms**, ícone `Check text-green-400`.
- ⚠️ `await navigator.clipboard.writeText(code)` **sem try/catch** — pode lançar exceção não tratada em contexto não-seguro (http). O `CopyButton` do DocBlocks trata; este não.

### 9.7 Padrões das seções de conteúdo

Observados em `GettingStartedSection.tsx` (representativo dos demais):
- H1 `text-3xl font-bold` + lead `text-lg text-muted-foreground`.
- H2 `text-xl font-semibold mb-3`.
- Container raiz `space-y-6`.
- **Grade de cards de recurso**: `grid md:grid-cols-3 gap-4`, cada card `p-4 rounded-lg border bg-card` com quadrado de ícone `h-10 w-10 rounded-lg bg-<cor>/10` + título + descrição. **Cores por card**: `primary/10`, `emerald-500/10`, `blue-500/10` — e dois dos ícones são **SVGs inline** (não lucide).
- `Alert` + `AlertDescription` do shadcn com ícone `Info` para notas.
- `<code class="text-primary">` para termos técnicos inline.
- A **Base URL real** é injetada: `` `${SUPABASE_URL}/functions/v1/api/` `` — ou seja, essa seção mostra o ambiente correto, enquanto o cURL do `EndpointCard` mostra o placeholder. **Inconsistência.**

---

## 10. Documentação viva da Fonte de Dados (`/docs/fonte-de-dados`)

### 10.1 Identidade

| Item | Valor |
|---|---|
| Rota | `/docs/fonte-de-dados` |
| Arquivo | `src/pages/FonteDeDadosDocs.tsx` (225 linhas) |
| Componentes | `src/components/fonte-de-dados-docs/` — 29 arquivos |
| Permissão | `etl:read` (via `RequirePermission` — **não** `RequireDocs`) |
| Layout | Full-screen, header + rail lateral fixo + **página única de rolagem** (`max-w-[1560px]`) |
| Identidade visual | *"blueprint telemetry"* — própria, ancorada nos estilos `.fdd-*` |

**Natureza:** é a **origem** dos estilos `.fdd-*` e dos primitivos que a Central de Docs depois reusou. Comentário do arquivo: *"experiência autocontida, identidade própria (blueprint telemetry). Consolida os 7 documentos técnicos do funil IAF-3988."*

**Tudo em uma página.** Diferente de `/docs` (troca de seção) e da Central (múltiplas rotas), aqui as 9 seções são renderizadas **de uma vez**, empilhadas, e a navegação é por âncora + scroll.

### 10.2 As 10 entradas de navegação

| `n` | `id` | Rótulo | Componente |
|---|---|---|---|
| 00 | `visao-geral` | Visão Geral | `Hero` |
| 01 | `holistica` | Visão Holística | `S1Holistica` (84 linhas) |
| 02 | `frontend` | Frontend · 4 Abas | `S2Frontend` (727) |
| 03 | `edge-functions` | Edge Functions | `S3EdgeFunctions` (126) |
| 04 | `camada-dados` | Camada de Dados | `S4DataLayer` (415) |
| 05 | `crons` | Crons & Observabilidade | `S5Crons` (149) |
| 06 | `normalizacao` | Normalização & Variáveis | `S6Normalizacao` (340) |
| 07 | `estado-real` | Estado Real por Org | `S7EstadoReal` (453) |
| 08 | `walkthrough` | Mão na Massa | `S8Walkthrough` (309) |
| 09 | `mv-deep` | A MV por dentro | `S9MaterializedView` (577) |

### 10.3 Chrome da página

**Header** (`sticky top-0 z-40 h-14`, mesmo tratamento de `backdrop-blur` da Central):
- Botão hambúrguer (`Menu`/`X`) só em `<lg`.
- Link `← Documentação Especial` — **volta para `/docs-especial`, não para o app** (esta doc é filha da Documentação Especial).
- Quadrado `h-6 w-6 rounded bg-primary` com `Database` + título `Fonte de Dados / Pipeline` (a segunda parte em muted).
- **Alternador de tema** (`ml-auto`): ícone `Sun`/`Moon`, faz `document.documentElement.classList.toggle("dark")`. ⚠️ É um toggle **local e não persistido** — só esta página tem esse controle, e ele altera a classe global do `<html>` sem gravar preferência.

**Rail lateral** (`<aside class="sticky top-14 hidden h-[calc(100vh-3.5rem)] w-72 shrink-0 overflow-y-auto border-r lg:block">`):
- **Campo de filtro** no topo: input com ícone `Search`, placeholder "Filtrar seções…", `aria-label`. Filtra por rótulo **ou por número** (`n`).
- Cada item: `<button>` com o **número em `fdd-mono text-[11px]`** à esquerda, o rótulo truncado no meio, e uma **bolinha `h-1.5 w-1.5 rounded-full`** à direita que só é visível (`bg-primary`) quando ativa.
- Ativo: `bg-primary/10 font-medium text-primary` + classe `fdd-rail-link` com `data-active="true"`.
- **Rodapé de procedência** (`mt-auto border-t pt-3`): `IAF-3988 · 7 docs · 2026-06-16` em mono + *"Conteúdo interno — dados reais de cliente. Verificado contra código + PROD."*

**Rail mobile:** overlay `fixed inset-0 z-30` com backdrop `bg-black/50` clicável + `<aside class="absolute left-0 top-14 w-72">` com o **mesmo** JSX (`Rail` é uma variável, não um componente).

**Sincronização com a URL (padrão distinto):**
- `useScrollSpy(ids)` devolve a seção mais visível.
- Um efeito mantém `window.location.hash` sincronizado via `history.replaceState` — **sem provocar salto**.
- Ao montar, se houver hash na URL, espera **120ms** ("espera o layout assentar") e rola até lá.
- `scrollTo(id)` usa `scrollIntoView({behavior: "smooth"})` e também grava o hash.

> ⚠️ **Diferença em relação ao `AtomRail`:** aqui o `scrollTo` **não** consulta `prefers-reduced-motion` (sempre `smooth`). O CSS global neutraliza o `scroll-behavior`, mas o `scrollIntoView` programático com `behavior:"smooth"` não é coberto por isso.

**Rodapé da página:** kicker `FONTE DE DADOS / PIPELINE` em `fdd-mono uppercase tracking-[0.18em] text-primary/70` + a nota de procedência com o snapshot `2026-06-16`.

### 10.4 Dois scroll-spies diferentes no produto

| | `useScrollSpy` (`fonte-de-dados-docs/hooks.ts`) | `useVisibleSections` (`AtomRail.tsx`) |
|---|---|---|
| Resultado | **UM** id (a seção com maior `intersectionRatio`) | **Set** de todos os ids visíveis |
| `rootMargin` | `-12% 0px -70% 0px` (janela de foco no topo) | `-72px 0px 0px 0px` (desconta o header) |
| `threshold` | `[0, 0.1, 0.25, 0.5, 1]` | `0` |
| Feedback visual | fundo `bg-primary/10` + bolinha | só a fonte brilha (`drop-shadow`) |

### 10.5 Hero (`Hero.tsx` + `HeroFlow.tsx`)

**`Hero`** — o padrão de abertura da identidade blueprint:
- Fundo: `.fdd-grid` em `opacity-60` (grade esquemática de 28px) + **linha de luz no topo** (`h-px bg-gradient-to-r from-transparent via-primary/50 to-transparent`) + **orbe desfocada** `-right-32 -top-24 h-80 w-80 rounded-full bg-primary/10 blur-3xl`.
- `Eyebrow index="IAF-3988"` com o texto *"Documentação viva · verificada contra código + PROD · 2026-06-16"*.
- **H1 gigante em duas linhas**: `text-6xl sm:text-8xl font-extrabold leading-[0.92] tracking-[-0.03em]`, com a segunda linha (`/ Pipeline`) em `text-primary`.
- Subtítulo `text-2xl sm:text-3xl text-foreground/75`; parágrafo-tese `text-lg sm:text-xl` com `<strong>` nos termos-chave.
- **Faixa de 4 `Stat`**: `grid grid-cols-2 lg:grid-cols-4` — `9 Edge Functions`, `8 Tabelas ETL`, `143 Colunas na MV`, `6 Tipos de fonte`.
- `HeroFlow` (ver abaixo), precedido de `Eyebrow`: "O caminho do dado".
- **Índice visual das 8 áreas**: `grid sm:grid-cols-2 lg:grid-cols-3` de botões `rounded-xl border bg-card p-4`, cada um com o número em `fdd-mono text-base text-primary`, título com `ArrowUpRight` que se desloca na diagonal no hover, e uma descrição de uma linha. Clique → `onJump(id)`.

**`HeroFlow`** — a peça mais característica: uma **espinha vertical animada**.
- Container `rounded-2xl border bg-gradient-to-b from-muted/40 via-card to-card p-5` com `.fdd-grid` em `opacity-40` por baixo.
- Cabeçalho: pílula mono `fluxo ponta-a-ponta` + legenda "do dado externo à fonte de verdade".
- `<ol>` de 7 `Stage`, cada um com:
  - **Segmento de espinha** `.fdd-spine` (`w-[2px]`, gradiente vertical de `primary/55` que some nas pontas) contendo um `.fdd-flow` — a **faixa de luz que corre de cima para baixo em loop de 3.6s**, simulando o sinal do dado em movimento. Omitido no último estágio.
  - **Nó marcador**: quadrado `h-10 w-10 sm:h-12 sm:w-12 rounded-xl border` com o ícone e o tom (`primary`/`info`/`muted`/`success`). O último ganha `glow` (anel `0 0 0 4px primary/12` + sombra projetada).
  - **`edge`** (a aresta/ação) como eyebrow `fdd-mono text-[10px] uppercase tracking-[0.2em] text-primary/70` — ex.: "fetch · aponta", "ondas de ≤3 · paralelo", "pós-processo (async)".
  - Título em `text-sm sm:text-[15px] font-semibold`.
  - **`Chip`s** das entidades (`fdd-mono rounded-lg border px-2.5 py-1.5 text-[12px]` com ícone), separados por `Sep` (`ArrowRight` pequeno).
- O último estágio termina com uma pílula sólida `bg-primary text-primary-foreground` escrita **"fonte de verdade"**.

### 10.6 Os 12 tipos de diagrama (`diagrams/`)

Todos são **componentes React desenhados à mão com HTML/CSS** — não há biblioteca de diagramas. O padrão declarado repetidamente nos cabeçalhos: *"Cores via tokens; sem dependências de diagrama"*, e vários substituíram versões ASCII anteriores.

| Componente | Tipo de diagrama | O que mostra | Interativo? |
|---|---|---|---|
| `HeroFlow` | **Espinha animada vertical** | Fluxo ponta-a-ponta com nós, arestas rotuladas e chips | não |
| `DataFlow` (111 l.) | **Colunas encadeadas** | fontes → ETL → entidades → MV → view → consumidores | não |
| `EtlArchitecture` (97 l.) | **Grade de abas** | As 4 abas da página `/etl` + chrome compartilhado (ícone, propósito, componente, domínio) | não |
| `EdgeFunctionChain` (499 l.) | **Cadeia clicável com dossiê** | Nós das 9 EFs; clicar abre gatilho, o que faz, payload, tabelas, o que ativa, gotchas | **sim** |
| `ChainTree` (180 l.) | **Árvore de chamadas** | Indentação real, badges de **MECANISMO** (pg_cron/fetch/net.http_post/RPC) e de **CONDIÇÃO** (sempre / se all_succeeded / se source bigquery) | não |
| `Connectors` (245 l.) | **Explorador por abas** | Clicar num tipo de conector mostra o formulário: métodos de auth, campos obrigatórios/opcionais, se gera preview, gotchas | **sim** |
| `ErDiagram` (147 l.) | **ER simplificado** | As 8 tabelas ETL + FKs, em cascata central com conectores rotulados; **FKs sempre em linha própria** (para não quebrar texto) | não |
| `StateMachines` (84 l.) | **Máquina de estados** | Estados de um Job (`etl_job_runs`) e de um Batch (`etl_batch_jobs`), com 5 tons (muted/primary/ok/warning/danger) e setas | não |
| `NormalizationPipeline` (43 l.) | **Lista numerada de etapas** | Os 6 passos fixos de `prepareRecordsForBatch`, cada um com `n`, função, o que faz e escopo | não |
| `MvFlow` (215 l.) | **Grafo vertical de etapas** | BQ → Torre; o nó `REFRESH mv_titles_base` é o **elo decisivo** (realce primário); mostra a borda "refresh defasado" | não |
| `OrgCompare` (124 l.) | **Barras comparativas** | `finza × blips` lado a lado, com barras horizontais proporcionais (`width: max(2%, n/total)`) | não |
| `SourceQuery` (102 l.) | **Explorador de fonte** | SQL real verbatim + anatomia por partes + tabela de mapeamento variável→Torre (do `field_mapping` real) | via `FilterTable` |

**Padrão recorrente de tom:** quase todos os diagramas definem localmente um tipo `Tone` com 3-5 variantes mapeadas para classes de token (`primary`, `info`, `muted`, `ok/success`, `warning`, `danger`). **Não há um `Tone` compartilhado** — cada arquivo redefine o seu. Oportunidade clara de consolidação.

### 10.7 Componentes utilitários

#### `FilterTable.tsx` — tabela filtrável
- Container `rounded-xl border bg-card`.
- **Barra de filtro** (opcional, `filterable` default `true`): ícone `Search` + input transparente + **contador `{filtradas}/{total}` em `fdd-mono`** à direita.
- Filtro client-side: uma linha passa se **qualquer célula** contém o texto (case-insensitive).
- Cabeçalho: `fdd-mono text-[11px] uppercase tracking-wide` com `whitespace-nowrap`.
- Linhas: `border-b border-border/40 align-top hover:bg-muted/40`; densidade controlada por `dense` (`py-1.5` vs `py-2.5`).
- **Modelo de célula rico (`Cell`)**: string simples, ou objeto `{ v, mono?, pill?, strong?, nowrap?, muted? }`. Com `pill`, a célula vira um `Pill` com o tom dado. **A primeira coluna ganha `fdd-mono font-medium` automaticamente** quando é string.
- `caption` opcional acima da tabela.
- Vazio: `"Nenhuma linha corresponde a "{q}"."` ocupando todas as colunas.

#### `CodeViewer.tsx` — código com realce próprio
**Realce de sintaxe implementado à mão, sem dependência.** Comentário: *"O realce usa SOMENTE cores do tema (tokens), funcionando em dark/light."*

- **Linguagens**: `sql`, `json`, `text`, `ts`, `bash`. (`ts` usa o tokenizer de SQL; `text`/`bash` não recebem realce.)
- **Tokenizer SQL**: uma regex única que captura, nessa ordem, comentários (`--` e `/* */`), strings (`'...'` e `` `...` ``), números, identificadores, espaços e pontuação. Um identificador vira `keyword` se está no set de ~90 palavras SQL, ou `fn` se o próximo caractere é `(`.
- **Tokenizer JSON**: distingue chave (`"x":`), string, número e literais (`true`/`false`/`null`).

| Token | Classe |
|---|---|
| `comment` | `text-muted-foreground/70 italic` |
| `string` | `text-success` |
| `number` | `text-info` |
| `keyword` | `text-primary font-semibold` |
| `fn` | `text-warning` |
| `punct` | `text-foreground/55` |
| `plain` | `text-foreground/85` |

- Container `.fdd-code` (força mono 12.5px / line-height 1.65) `rounded-xl border bg-[hsl(var(--muted)/0.45)]`.
- **Barra de título**: à esquerda, ou o ícone `Terminal` (fixo) ou um `ChevronDown` que gira `-rotate-90` quando fechado (modo `collapsible`, com `aria-expanded`); ao lado, `title ?? lang` em `fdd-mono uppercase`, e a `lang` em cinza quando há título. À direita, botão **`copiar` → `copiado`** (1800ms, ícone `Check text-success`), com `try/catch`.
- `maxHeight` opcional aplica `overflowY: auto`.
- Trim automático de newlines nas pontas.

**`AsciiArt`** (exportado do mesmo arquivo): `<pre>` mono sem realce, mesma moldura — para diagramas ASCII remanescentes.

#### `ImagePlaceholder.tsx` — screenshot emoldurado
Mesma **moldura de janela de navegador** que o bloco `screenshot` do DocBlocks reusa (bolinhas + barra de endereço com cadeado e `cobranca.finza.com.br{url}`), mas com diferenças importantes:

| | `ImagePlaceholder` (Fonte de Dados) | `ScreenshotBlock` (DocBlocks) |
|---|---|---|
| `src` | nome de arquivo; resolve para `/docs/fonte-de-dados/{src}` | URL completa |
| Imagem faltando | detecta via `onError` → mostra `imagem não encontrada · {caminho}` sobre fundo `.fdd-grid` | placeholder tracejado "Print: … / substituir depois" |
| Lightbox | **não tem** | tem (Dialog fullscreen, zoom) |
| `caption` | obrigatório | opcional |
| `url` default | `/etl` | vazio |

### 10.8 Padrões visuais recorrentes das seções

Derivados de `primitives.tsx` e do uso nas 9 seções:

| Padrão | Componente | Detalhe |
|---|---|---|
| **Abertura de seção** | `DocSection` | Divisor forte `border-t-2` com um traço `h-[2px] w-24 bg-primary` sobreposto no canto; **quadrado de número gigante** `h-14 w-14 sm:h-[4.5rem] sm:w-[4.5rem] rounded-2xl bg-gradient-to-br from-primary to-primary/75` com o índice em `text-2xl sm:text-4xl`; linha `área NN / 09 · {eyebrow}` em `fdd-mono tracking-[0.24em]`; H2 `text-[2rem] sm:text-5xl font-bold leading-[1.02]`; `lead` `max-w-5xl`. `scroll-mt-20 pt-16 sm:pt-24` |
| **Sub-bloco** | `SubBlock` | kicker (pílula mono) + barra de acento `h-6 w-1.5` + H3 `text-xl sm:text-2xl` + **chip `meta`** ao lado do título (caminho/arquivo/dimensões) + `lead` |
| **Rótulo numerado** | `Eyebrow` | pílula mono `border-primary/30 bg-primary/10` com o índice + texto `uppercase tracking-[0.2em]` |
| **Definição** | `WhatIs` | "o que é" + "por baixo" |
| **Aviso** | `Callout` | 5 níveis (ver §8.2) |
| **Severidade inline** | `SeverityBadge` | pílula com **emoji de bolinha** (🔴🟡🟢🔵⚪) + texto — *"reutilizando a convenção dos docs-fonte"* |
| **Número** | `Stat` | valor `fdd-mono text-2xl tabular-nums` + rótulo uppercase + hint |
| **Token inline** | `Pill` | `fdd-mono rounded-md border px-1.5 py-0.5 text-[11px]`, 6 tons |
| **Código inline** | `Code` | `fdd-mono rounded bg-foreground/[0.07] px-1.5 py-0.5 text-[0.85em]` |
| **Card** | `Panel` | `rounded-2xl border bg-card p-5`, com hover opcional (`interactive`) |
| **Ficha** | `KeyValue` | `<dl>` com coluna fixa de 180px |
| **Seta de fluxo** | `FlowArrow` | `ChevronRight` azul + rótulo mono opcional |
| **Revelação** | `Reveal` | `IntersectionObserver` próprio (`rootMargin: "0px 0px -8% 0px"`, `threshold: 0.05`), dispara uma vez |

> Nota: `Reveal` (primitives) e `useInView` (topics) resolvem o mesmo problema com implementações diferentes — o `Reveal` **não consulta `prefers-reduced-motion` em JS** (depende só do CSS `.fdd-reveal` sob a media query), enquanto o `useInView` consulta e nem cria o observer.

---

## 11. Estilos especiais `.fdd-*` (catálogo)

Fonte: `src/index.css`, linhas 651-893. Bloco declarado como: *"FONTE DE DADOS — DOCS PREMIUM (rota /docs/fonte-de-dados). Estilos isolados (prefixo .fdd-) para a página de documentação viva do ETL. Cores derivam SOMENTE dos tokens do tema (CSS vars)."*

Na prática, o prefixo vazou (proveitosamente) para **toda a Central de Documentação**, que usa `.fdd-doc`, `.fdd-mono`, `.fdd-reveal`, `.fdd-stagger`, `.fdd-timeline-fill`, `.fdd-collapse` e `.fdd-anchor`.

### 11.1 Catálogo completo

| Classe | O que faz | Onde é usada |
|---|---|---|
| **`.fdd-mono`** | Força a stack monoespaçada real (`ui-monospace, SFMono-Regular, JetBrains Mono, Cascadia Code, Menlo, Consolas, Liberation Mono`) com `!important` e `font-variant-ligatures: none`. O `!important` é necessário para **sobrepor a regra global que força Inter em `code`/`pre`** | Onipresente: títulos de átomo, chips, pílulas, valores técnicos, tabelas, kickers |
| **`.fdd-code`** | Mesma fonte + `font-size: 12.5px !important` e `line-height: 1.65 !important` | `CodeViewer`, `AsciiArt` |
| **`.fdd-grid`** | Grade esquemática (blueprint): duas `linear-gradient` de 1px em `hsl(var(--foreground)/0.035)`, `background-size: 28px 28px`, centralizada | Hero, `HeroFlow`, fallback do `ImagePlaceholder` |
| **`.fdd-spine`** | Espinha de pipeline: gradiente vertical `transparent → primary/55 (14%..86%) → transparent` | `HeroFlow` (`Stage`) |
| **`.fdd-flow`** | **Faixa de luz animada** que percorre a espinha. `background-size: 100% 220%`, gradiente com pico sólido em `primary` no meio, animação `fdd-flow 3.6s linear infinite` (`background-position: 0 -110% → 0 110%`) | `HeroFlow` (dentro da `.fdd-spine`) |
| **`.fdd-dash`** | Traço animado de SVG: `stroke-dasharray: 6 6` + `animation: fdd-dash 1s linear infinite` (`stroke-dashoffset: -12`) | Conexões da cadeia de Edge Functions |
| **`.fdd-reveal`** | Revelação: `opacity 0 → 1` e `translateY(14px) → none` em `0.6s ease`, ativada por `[data-shown="true"]` | `Reveal`, `SectionReveal` |
| **`.fdd-stagger`** | Revelação **em escada**: filhos diretos com `opacity 0` + `translateY(12px)`, `transition 0.55s` e **`transition-delay: calc(var(--i, 0) * 70ms)`**. O pai recebe `[data-shown="true"]`; cada filho precisa receber `style={{"--i": i}}` | `Stagger`, `BlockRenderer` |
| **`.fdd-timeline-fill`** | Barra de progresso da timeline: `transform-origin: top`, `scaleY(0) → scaleY(1)` em `0.9s cubic-bezier(0.22,1,0.36,1)` sob `[data-shown="true"]` | `FlowTimeline` (bloco `flow`) |
| **`.fdd-collapse`** | Truque de altura automática animável: `display: grid` + `grid-template-rows: 0fr → 1fr` em `0.28s`, com o filho `.fdd-collapse-inner` em `overflow: hidden; min-height: 0` | Disclosure de payload do `FlowFrameItem` |
| **`.fdd-anchor`** | Âncora `#` de seção: `opacity: 0`, revelada por `.group\/sec:hover .fdd-anchor` **ou** `.fdd-anchor:focus-visible` (acessível por teclado) | `SectionHeader` do DocBlocks |
| **`.fdd-rail-link[data-active="true"]`** | Item ativo do rail: `color: hsl(var(--primary))` | `FonteDeDadosDocs` (rail) |
| **`.fdd-doc`** | Escopo raiz da página de documentação. Faz 3 coisas (abaixo) | Todas as páginas da Central + Fonte de Dados + Documentação Especial |
| **`.fdd-doc ol.fdd-ol`** | Lista numerada com badge: contador CSS `decimal-leading-zero` (01, 02…) num quadrado `1.5rem` com `bg-primary/10`, borda `primary/25` e fonte mono 10.5px; itens separados por `border-top` | Listas numeradas em docs |

### 11.2 O que `.fdd-doc` resolve

1. **Devolve o controle tipográfico às utilities do Tailwind.**
   ```css
   .fdd-doc :is(h1,h2,h3,h4,h5,h6) { font-size: revert-layer; font-weight: revert-layer; }
   .fdd-doc :is(h1,h2,h3,h4) :is(span,div,code,em,strong) { font-size: inherit; }
   ```
   O comentário explica: existem regras globais **sem layer** (`* { font-size: inherit }` e `h1..h6 { font-weight: 600 }`) que venceriam as utilities do Tailwind v4 (que ficam num layer). `revert-layer` resolve. A segunda regra impede que a regra global `span { font-size: 14px }` encolha spans dentro de títulos.
   > **Consequência para o redesign:** **remover `.fdd-doc` do wrapper quebra toda a tipografia** das páginas de documentação silenciosamente.

2. **Scrollbars minimalistas** em toda a página e seus filhos: `scrollbar-width: thin`, `scrollbar-color: hsl(var(--foreground)/0.2) transparent`; WebKit com 8px, thumb arredondado `foreground/0.18` com `border: 2px solid transparent` + `background-clip: padding-box`, virando `primary/0.55` no hover; track e corner transparentes.

3. **Escopo para `ol.fdd-ol`.**

### 11.3 Bloco `prefers-reduced-motion`

Existem **dois** blocos de reduced-motion no `index.css`:

**(a) Global** (linhas 632-649): zera `animation-duration`, `transition-duration` e `scroll-behavior` com `!important` em `*`, e desliga `.animate-spin`, `.animate-pulse`, `.animate-bounce`, `.animate-ping`.

**(b) Específico dos `.fdd-*`** (linhas 871-892):

| Classe | Sob reduced-motion |
|---|---|
| `.fdd-flow`, `.fdd-dash` | `animation: none !important` |
| `.fdd-reveal` | `opacity: 1 !important; transform: none !important` (nasce visível) |
| `.fdd-stagger > *` | `opacity: 1; transform: none; transition: none` — **todos** |
| `.fdd-timeline-fill` | `transform: scaleY(1) !important; transition: none` (nasce cheia) |
| `.fdd-collapse` | `transition: none` (abre/fecha instantâneo, mas **continua funcionando**) |

Em conjunto com o `useReducedMotion()` do JS (que faz `useInView` devolver `true` de imediato e `useCountUp` pular para o alvo), **toda a camada de movimento da documentação é neutralizável** — um requisito não-negociável a manter no redesign.

---

## 12. Documentação Especial (`/docs-especial`) e Portal (`/portal`)

### 12.1 Documentação Especial — identidade e propósito

| Item | Valor |
|---|---|
| Rota | `/docs-especial` |
| Arquivo | `src/pages/DocsEspecialPage.tsx` (160 linhas) |
| Guards | `ProtectedRoute` + `RequireOrg` (sem permissão específica) |
| Layout | Full-screen, `max-w-5xl`, `fdd-doc` |

**Propósito declarado:** *"hub de anotações de estudo / mergulhos técnicos dos devs. Cada card abre um guia aprofundado próprio (rota dedicada). É aqui que qualquer dev adiciona a sua anotação: crie a página/rota e some um item em NOTES abaixo."*

**Dado importante:** é uma **lista hardcoded de uma constante `NOTES`** dentro do próprio arquivo — não há registry nem glob. Hoje contém **exatamente 1 item**: a doc viva da Fonte de Dados.

```ts
type Note = { title, href, badge, gate, meta, description, icon };
```

| Campo | Valor no único item existente |
|---|---|
| `title` | "Fonte de Dados / Pipeline (ETL)" |
| `href` | `/docs/fonte-de-dados` |
| `badge` | "Documentação viva" |
| `gate` | "interno · gate etl:read" |
| `meta` | "8 seções · IAF-3988 · 2026-06-16" |
| `icon` | `Database` |

**Anatomia:**
- Topbar: `← Voltar ao app` + quadrado `Library` + "Documentação Especial".
- Fundo: **só a grade de 28px** em `h-64 opacity-50` (não tem o brilho radial da Central).
- **Hero**: kicker `fdd-mono text-[12px] uppercase tracking-[0.22em] text-primary` com "anotações internas · devs"; H1 `text-5xl sm:text-7xl font-extrabold leading-[0.95] tracking-[-0.03em]`; subtítulo `text-2xl sm:text-3xl text-foreground/75` — *"A estante de mergulhos técnicos do time."*; parágrafo explicativo `text-lg`.
- **`NoteCard`**: `rounded-2xl border bg-card p-5` com textura quadriculada (`26px`, `opacity-[0.06]`) e hover `-translate-y-0.5` + sombra. Contém: quadrado `h-12 w-12 rounded-xl bg-primary` com o ícone; **badge sólido** `bg-primary text-primary-foreground` com o `badge`; pílula de gate com cadeado (`🔒 interno · gate etl:read`); H3; descrição; linha `meta` em `fdd-mono uppercase`; e um `ArrowRight` grande em `text-primary` que desliza `translate-x-1` no hover.
- **Card "Adicionar uma anotação"** (`border-dashed border-border bg-muted/20`): quadrado tracejado com `Plus` + instruções literais de onde editar (`NOTES` em `src/pages/DocsEspecialPage.tsx`) e a recomendação de reaproveitar `src/components/fonte-de-dados-docs/`.

> **Para o redesign:** esta tela é um **índice editorial de um item só**, cuja principal função hoje é ser a porta de entrada (e o breadcrumb de volta) da doc de Fonte de Dados. Ela **não** aparece na Central de Docs como pilar — é um sistema paralelo.

### 12.2 As quatro "documentações" convivendo

| Sistema | Rota | Conteúdo | Alimentação | Papel |
|---|---|---|---|---|
| **Central de Docs** | `/central-docs` | data-driven (`Atom`/`Topic`/`PageGuide`/`ChangelogEntry`) | contínua (skill `central-docs-sync` no commit) | catálogo vivo oficial |
| **Docs da API** | `/docs` | JSX hardcoded por seção | manual | referência pública da API |
| **Fonte de Dados** | `/docs/fonte-de-dados` | JSX hardcoded, 9 seções | snapshot `2026-06-16` | mergulho técnico único |
| **Documentação Especial** | `/docs-especial` | lista hardcoded | manual | índice dos mergulhos |
| **Portal** | *(sem rota)* | data-driven (`DocNode`) | **parado desde 29/07/2026** | ver §12.3 |

### 12.3 Portal (`src/portal/`) — código completo, sem rota

O próprio repositório documenta o estado em `src/portal/README.md` (auditoria de 20/08/2026). Citando:

> ⚠️ **Estado atual: NÃO montado e NÃO realimentado**
> 1. **Não há rota.** Nem `src/App.tsx` nem `src/main.tsx` importam `PortalLayout` ou qualquer coisa de `src/portal` — nenhum arquivo fora de `src/portal/` referencia o Portal. Ou seja: o código existe, compila e tem testes, mas **não há como abrir `/portal` na aplicação**.
> 2. **Não é realimentado.** Último commit que tocou `src/portal`: **29/07/2026**.

**Verificado na leitura atual (2026-09-17):** o `grep` por `portal` em `src/App.tsx` **não retorna nenhum import** — a situação persiste.

**Comparativo oficial do README:**

| | Portal | Central de Docs |
|---|---|---|
| Roteado na app | ❌ não | ✅ sim |
| Última alimentação | 29/07/2026 | contínua |
| Tabelas cobertas | 101 de 124 | **124 de 124** |
| Edge Functions | 47 de 50 | **50 de 50** |

**Orientação registrada no README:** *"Documentação nova vai para a Central de Docs, não para cá. Duplicar cria duas fontes de verdade que divergem."* O README lista dois caminhos (retomar com paridade ou aposentar preservando os testes e o design system).

#### 12.3.1 Arquitetura (para efeito de decisão no redesign)

**Modelo `DocNode`** (`portal/types.ts`) — validado por **Zod**, o que o distingue do `Atom`:

```ts
type Track = "api" | "tech" | "guia";
type DocNodeType = "edge-function"|"table"|"rpc"|"view"|"cron"|"endpoint"|"flow"|"concept"|"guide"|"subject";
type RelationKind = "writes"|"reads"|"calls"|"triggered-by"|"serves"|"documented-in"|"explains"|"relates";

interface DocNode {
  id: string;        // `<tipo>.<slug>`, regex /^[a-z-]+\.[a-z0-9_-]+$/
  type: DocNodeType;
  tracks: Track[];   // >= 1
  domain: string;
  title: string; summary: string;
  paths?: string[];  // arquivos reais — "cola código↔doc p/ changelog"
  relations?: Relation[];
  render?: () => ReactNode;  // ausente em nós stub
}
```

**Registry com validação em dev** (`manifest.ts`): glob `./nodes/**/*.node.tsx`, e sob `import.meta.env.DEV` roda três verificações que fazem `console.error`: `findDuplicateIds` (colisão de id), `validateRegistry` (relação apontando para nó inexistente) e `assertValidNode` (schema Zod). **A Central de Docs não tem equivalente disso** — ela ignora órfãos em silêncio.

**Estrutura de navegação em 3 níveis:** Lobby → Trilha → Domínio → Nó.

| Página | Arquivo | Conteúdo |
|---|---|---|
| `PortalLobby` | `pages/PortalLobby.tsx` | Kicker mono + H1 "Portal" `text-5xl sm:text-7xl` + 3 `TrackCard` (API / Técnica / Usuário) |
| `TrackPage` | `pages/TrackPage.tsx` | Breadcrumb + H1 "Trilha X" + `LayerNav` com os domínios e a contagem de nós |
| `DomainPage` | `pages/DomainPage.tsx` | Breadcrumb + H1 do domínio + `LayerNav` com os nós |
| `NodePage` | `pages/NodePage.tsx` | Breadcrumb 4 níveis + H1 + `NodeBadge` + summary + `node.render()` + `RelatedNodes` + `GraphMini` |
| `GraphView` | `graph/GraphView.tsx` | Grafo **2D com cytoscape + fcose**, filtro por trilha (all/api/tech/guia), `h-[70vh]` |
| `DesignRecipesPage` | `pages/DesignRecipesPage.tsx` | "receitas" de qual primitivo usar |

**Design system do Portal** (`portal/design-system/`): **re-exporta os mesmos primitivos** do fonte-de-dados-docs (`Eyebrow`, `SeverityBadge`, `Callout`, `Stat`, `Pill`, `Code`, `DocSection`, `SubBlock`, `WhatIs`, `Panel`, `KeyValue`, `Reveal`, `FlowArrow`) e adiciona 7 componentes próprios:

| Componente | O que é |
|---|---|
| `NodeBadge` | Pílula do tipo do nó, **colorida por CSS var** (`--node-ef`, `--node-table`, `--node-endpoint`, `--node-concept`, `--node-subject`, `--track-guia`) aplicada via `style` inline |
| `TrackCard` | Card grande da trilha: quadrado `h-12 w-12` com a cor do track, H2 `text-2xl`, descrição e CTA "Entrar →". Borda colorida por `--track-api/tech/guia` |
| `LayerNav` | Grade `sm:grid-cols-2` de links com título + `NodeBadge` + contagem opcional + `ArrowRight` deslizante |
| `Breadcrumb` | Trilha com `ChevronRight`, último item em `text-foreground`, `aria-label="breadcrumb"` |
| `RelatedNodes` | Seção "Nós relacionados": grade de links com badge + título + **o `kind` da relação** em mono. Tem versão testável (`RelatedNodesView`, recebe o registry por prop) |
| `ConceptRef` | **Referência conceitual inline**: texto com borda inferior tracejada + ícone `Lightbulb` que abre um `Popover` com título, resumo e "Abrir conceito →". Se o id não existe: *"Conceito `x` ainda não documentado."* |
| `DesignRecipes` / `recipes-data` | Motor de recomendação: 5 receitas (`KeyValue`, `Callout`, `Stat`, `FlowArrow`, `WhatIs`) com `question`, `when` (palavras-chave) e `snippet`; `recommend(intent)` pontua por sobreposição de palavras |

> **`ConceptRef` e `DesignRecipes` não têm equivalente na Central de Docs** — são ideias reaproveitáveis num redesign.

**Grafo do Portal × Grafo da Central:**

| | Portal (`GraphView`) | Central (`CentralDocsGraph`) |
|---|---|---|
| Lib | `cytoscape` + `cytoscape-fcose` | `react-force-graph-3d` + `three` |
| Dimensão | 2D | 3D |
| Cores | CSS vars resolvidas em runtime (`--node-*`) | paleta HSL fixa |
| Rótulo das arestas | **sim** (`label: data(kind)`, fonte 8) | não (só no tooltip/painel) |
| Filtro | por trilha | por tipo (legenda clicável, com solo) |
| Mini-grafo por nó | **sim** (`GraphMini`, vizinhança de profundidade 1, não renderiza se não há vizinhos) | não |
| Interação | tap → navega | clique seleciona · duplo clique navega |

**Layout compartilhado (`PortalLayout`):** wrapper `fdd-doc`, topbar sticky com `← Voltar ao app`, link "Portal" com ícone `Compass` e **o mesmo toggle de tema claro/escuro** da doc de Fonte de Dados (também não persistido). Conteúdo em `max-w-6xl px-6 pb-32 pt-10`.

**Changelog próprio:** `portal/changelog/` tem `registry.ts`, `ChangelogPage`, `PostPage`, `nodes-for-paths.ts` (mapeia arquivos tocados → nós de doc, via `node.paths`) e **1 post** (`2026-06-17-portal-fundacao`). É um sistema completo e paralelo ao changelog da Central.

**Testes:** 8 arquivos em `__tests__/` (manifest, types, registry-helpers, exemplares, LayerNav, NodeBadge, RelatedNodes, recipes-data, build-elements, nodes-for-paths, changelog registry). A Central de Docs **não tem testes equivalentes**.

---

## 13. Botão de documentação na sidebar e balão de novidades

### 13.1 `DocsNavButton` — a única porta de entrada da Central

**Arquivo:** `src/components/layout/DocsNavButton.tsx` (232 linhas).

Declaração do cabeçalho: *"Único ponto de entrada da Central de Documentação."* O componente combina **duas ações** num só espaço da sidebar:

1. **Rótulo/ícone** (`BookOpen` + "Central de Documentos") → `<Link to="/central-docs">`.
2. **Ícone de megafone** → abre um **popover** com a prévia das novidades. O ícone fica **sempre visível**; só o badge de contagem é condicional.

**Dois modos de renderização:**

| Modo | Layout |
|---|---|
| **Expandido** (`isCollapsed: false`) | `flex items-center gap-1`: `Button ghost` ocupando `flex-1` com ícone + rótulo, e ao lado um `Button ghost size="icon" h-8 w-8` com o megafone. Popover `side="right" align="end" w-80 p-0` |
| **Recolhido** (`isCollapsed: true`) | Botão de ícone em largura total, envolto em `Tooltip side="right"` com o texto "Central de Documentos". O megafone vira um **botão flutuante** `absolute -right-1 -top-1 h-5 w-5 rounded-full border bg-background shadow-sm`. Popover `side="right" align="start"` |

**`CountPill`:** `h-4 min-w-4 rounded-full bg-primary text-[10px] font-semibold text-primary-foreground`, posicionada `absolute` sobre o megafone. Retorna `null` quando o label é vazio. Tem `aria-label="{label} novidades não lidas"`. O valor vem de `useChangelogUnread().badge` (`"9+"` acima de 9).

**Prefetch:** `onMouseEnter` no link dispara `prefetchRoute("/central-docs")` — o bundle da Central começa a baixar antes do clique.

**`ChangelogPreview`** (conteúdo do popover, `w-80`):

| Zona | Detalhe |
|---|---|
| Cabeçalho | Quadrado `h-6 w-6 bg-primary` com `Megaphone` + "Novidades" + botão ghost `✓✓ Marcar como lido` (`ml-auto`, `h-7 text-xs`) |
| Lista | `max-h-80 overflow-auto`, **5 posts mais recentes** (`PREVIEW_COUNT = 5`). Cada um: quadrado `h-5 w-5 rounded border` com o ícone e a cor do tipo + título truncado + **bolinha `h-1.5 w-1.5 bg-primary`** quando o post é novo + linha `{tipo} · {data curta}` (formato "25 jun"). Hover `bg-accent` |
| Vazio | *"Nenhuma novidade ainda."* |
| Rodapé | Botão ghost largura total `Ver todas as novidades →` → `/central-docs/changelog` |

Clicar em qualquer link fecha o popover **e** chama `onNavigate?.()` (que fecha a sidebar no mobile).

### 13.2 `ChangelogNotificationBalloon` — o aviso ao entrar na Torre

**Arquivo:** `src/components/layout/ChangelogNotificationBalloon.tsx` (139 linhas).

Três características declaradas no cabeçalho:
1. **Chamativo** — megafone com "ping" pulsante + badge de contagem.
2. **NÃO some sozinho** — *"sem auto-dismiss/timeout: só desaparece quando o usuário AGE"*.
3. **Rastreio por usuário no servidor** (cross-device), via `useChangelogNotifications` (§6.7).

**Posição e entrada:** `fixed bottom-4 right-4 z-50 w-[min(22rem,calc(100vw-2rem))]`, com animação de entrada `animate-in fade-in slide-in-from-bottom-4 duration-300`. O wrapper é `pointer-events-none` e só o card interno é `pointer-events-auto` (não bloqueia cliques ao redor).

**Acessibilidade:** `role="status"`, `aria-live="polite"`, `aria-label="{N} novidades não lidas na Central de Documentação"`.

**Anatomia:**

| Zona | Detalhe |
|---|---|
| Card | `rounded-xl border bg-card shadow-lg ring-1 ring-primary/15` |
| Ícone | Círculo `h-9 w-9 rounded-full bg-primary/10 text-primary` com `Megaphone`, sobreposto por um **anel pulsante** `absolute inset-0 rounded-full bg-primary/30 motion-safe:animate-ping` |
| Badge | `absolute -right-1 -top-1 h-5 min-w-5 rounded-full border-2 border-card bg-primary` com a contagem (`"9+"` acima de 9) |
| Texto | `"{N} novidade(s) pra você"` em `text-sm font-semibold` + `"Veja o que mudou na Torre."` em `text-xs muted` |
| Botão `X` | `aria-label="Marcar todas como lidas e fechar"` — **fechar = marcar tudo como lido** (não há dispensa temporária) |
| Lista | Até **5 itens** (`MAX_LIST`). Cada um: quadrado `h-6 w-6 rounded-md border` com ícone/cor do tipo + título em `line-clamp-2` (2 linhas) + rótulo do tipo em `text-[11px] uppercase`. Clicar **marca só aquele post** como visto (`markSeen([entry.id])`) |
| Excedente | `+N outra(s) novidade(s)` em `text-xs muted` |
| Ações | `Separator` + botão primário `Ver novidades` (`flex-1`) e botão outline `Marcar como lido`. **Ambos chamam `markAllSeen()`** |

**Regras de motion:** `motion-safe:animate-ping` no anel (só anima quando o usuário permite), e o bloco global de `prefers-reduced-motion` no `index.css` já desliga `.animate-ping`. **Dupla proteção.**

### 13.3 Onde os dois são montados

| Componente | Montado em | Linha | Observação |
|---|---|---|---|
| `DocsNavButton` | `src/components/layout/Sidebar.tsx` | 158 | No rodapé da sidebar (`div.p-2.border-t.space-y-1`), logo **abaixo** do `AgentSidebarButton`. Recebe `isCollapsed` e `handleNavClick` |
| `ChangelogNotificationBalloon` | `src/components/layout/AppLayout.tsx` | 139 | Último filho do layout. Comentário no código: *"Balão de novidades não lidas (canto inferior direito, p/ qualquer perfil)"* |

**Consequência:** os dois só existem **dentro** do `AppLayout` — ou seja, **não aparecem** em nenhuma das telas de documentação (que são full-screen e vivem fora do layout). Um usuário que está lendo a documentação não vê o balão nem o botão; ele volta ao app pelo link `← Voltar ao app` da topbar.

---

## 14. Estados, responsividade e acessibilidade

### 14.1 Catálogo de estados por tipo de tela

#### Estados de carregamento

| Contexto | Estado | Aparência |
|---|---|---|
| Troca de rota (lazy) | `PageLoader` | `flex h-screen items-center justify-center` + `animate-spin rounded-full h-8 w-8 border-b-2 border-primary` |
| Guards (`isLoading`) | `PageLoader` | idem |
| Grafo 3D no hub | `GraphSectionLoading` | Spinner `h-7 w-7` + texto "Carregando o grafo 3D…" |
| Grafo 3D em tela cheia | `GraphLoading` | Spinner `h-8 w-8` + mesmo texto |
| Pessoas do changelog | `LoadingRows` | **4 linhas de `Skeleton`**: círculo `h-9 w-9` + duas barras (`w-1/2`, `w-1/3`), com `aria-busy` |
| Testador de endpoint | botão | `Loader2 animate-spin` substituindo o `Play`, botão desabilitado |
| Gerar chave de teste | botão | `Loader2 animate-spin` no lugar do `KeyRound` |

> ⚠️ **Lacuna:** não há **skeleton de conteúdo de página**. Como todo o conteúdo dos pilares é estático (glob em build), não há estado de carregamento de dados — a única espera é o chunk do `React.lazy`.

#### Estados vazios (textos literais, por tela)

| Tela | Condição | Texto |
|---|---|---|
| Catálogo Negócio | sem guias | "Nenhum guia publicado ainda. O manual das telas está sendo escrito." |
| Catálogo Tópicos | sem tópicos | "Nenhum tópico publicado ainda. Os artigos estão sendo escritos." |
| Catálogo Técnica | sem átomos | "Nenhum átomo cadastrado ainda. As páginas técnicas estão sendo escritas." |
| Catálogo Técnica | filtrando | "Nenhum átomo bate com a busca/filtro." |
| Catálogo Serviço | sem endpoints | "Nenhum endpoint cadastrado ainda. A referência da API está sendo escrita." |
| Catálogo Serviço | filtrando | "Nada bate com a busca/filtro." |
| Feed Changelog | sem posts | "Nenhuma novidade publicada ainda." |
| Feed Changelog | filtrando | "Nada encontrado para esse filtro." |
| TagsPage | sem tags | "Nenhuma tag cadastrada ainda." |
| Conexões (átomo) | sanfona vazia | "— nada ainda" |
| Painel do grafo | nó isolado | "Sem conexões." |
| Busca do grafo | sem match | "Nada encontrado" |
| `FilterTable` | filtro sem match | "Nenhuma linha corresponde a "{q}"." |
| Busca `/docs` | sem match | "Nenhum resultado encontrado para "{query}"" + dica de termos |
| Modal de reatores | vazio | "Ninguém reagiu ainda." |
| Modal de viewers | vazio | "Nenhuma visualização ainda." |
| `NodePage` (Portal) | id inválido | "Nó `{id}` não encontrado." |
| `ConceptRef` (Portal) | conceito ausente | "Conceito `{id}` ainda não documentado." |

#### Estados de erro / indisponibilidade

| Contexto | Comportamento |
|---|---|
| Engajamento do changelog (RPC ausente) | `available: false` → botões desabilitados + texto "As reações estarão disponíveis em breve" · **sem toast** |
| Reação falhou | reverte o otimista, marca indisponível · **sem toast** |
| Notificações (RPC ausente / sem sessão) | lista vazia → balão não renderiza · **sem toast** |
| Pessoas (RPC nega) | lista vazia (o gate já impede a chamada) · **sem toast** |
| `record_changelog_view` | best-effort, erro engolido |
| Testador — fetch falhou | caixa `destructive` com a mensagem + dica de CORS e de copiar a cURL |
| Testador — RPC `create_api_key` ausente | mensagem específica citando a IAF-176 |
| Clipboard indisponível | `CopyButton`/`CodeViewer`/`SourcePathRow`: falha **silenciosa**. ⚠️ `components/docs/CodeBlock`: **sem try/catch** |
| Imagem ausente (`ImagePlaceholder`) | fallback `imagem não encontrada · {caminho}` |
| Id de átomo órfão | `AtomLink` → texto esmaecido; `ConnectionRow` → linha `opacity-70` não-clicável; grafo → aresta ignorada |
| Slug/id inválido em rota | `<Navigate replace>` para o catálogo pai (**nunca 404**) |

> **Padrão dominante e deliberado: degradação silenciosa.** Nenhuma tela de documentação dispara toast de erro. Isso é coerente com a natureza "conteúdo estático + enfeites opcionais", e deve ser preservado.

#### Estados de permissão

| Nível | Aparência |
|---|---|
| Card de pilar no hub | `opacity-60`, cursor default, `aria-disabled`, selo `🔒 Sem acesso` — **visível, não escondido** |
| Banner do changelog | idem, **sem CTA** |
| Página inteira sem acesso | Tela centralizada: `Lock h-8 w-8` + frase específica do pilar + link "Voltar à Central de Documentação" |
| Faixa de cross-link para pilar sem acesso | Faixa **visível e fosca**: ícone vira `Lock`, micro-legenda explicativa, chips com `opacity-50 blur-[2px] pointer-events-none` + `inert` |
| Grafo no hub | simplesmente **não renderiza** se falta `docs:tecnica` |
| Executar endpoint | botão desabilitado + mensagem "Apenas super_admin executa (você pode copiar a cURL acima)" |
| Gerar chave de teste | bloco substituído por instrução de colar chave existente |
| "Ver quem reagiu/viu" | pílula **não renderizada** para perfis abaixo de admin |

#### Modais e overlays

| Componente | Tipo | Onde |
|---|---|---|
| Lightbox de screenshot | `Dialog fullscreen` sem chrome, imagem `object-contain` | bloco `screenshot` com `src` |
| "Quem reagiu" | `Dialog sm:max-w-lg`, lista `max-h-[60vh]` | post do changelog |
| "Quem visualizou" | idem | post do changelog |
| Painel "Autorizar" | **popover manual** (overlay `fixed inset-0 z-30` + painel absoluto), não Radix | catálogo Serviço |
| Prévia de novidades | `Popover` (Radix) `w-80 p-0` | sidebar |
| `ConceptRef` | `Popover` (Radix) `max-w-xs` | Portal |
| Sidebar mobile `/docs` | overlay `fixed inset-0 z-40` + backdrop `bg-black/50` | `/docs` |
| Rail mobile Fonte de Dados | overlay `fixed inset-0 z-30` + backdrop | `/docs/fonte-de-dados` |
| Painel de conexões do grafo | overlay absoluto (não modal) | grafo |
| Balão de novidades | `fixed bottom-4 right-4 z-50`, não-modal | `AppLayout` |

### 14.2 Responsividade

**Breakpoint dominante: `lg` (1024px).** É onde o rail lateral aparece/desaparece.

| Faixa | Comportamento |
|---|---|
| `< sm` (640px) | Rótulos de breadcrumb encurtam ("Central de Documentação" → "Central") ou somem; pílulas de conexão somem; título de endpoint some; grades viram 1 coluna; a dica de controles do grafo some; a coluna "Descrição" da tabela de parâmetros de `/docs` some |
| `sm` a `lg` | Grades `sm:grid-cols-2` / `sm:grid-cols-3` ativas; rail ainda em modo disclosure |
| `≥ lg` | Grade `lg:grid-cols-[220px_minmax(0,1fr)]` com o `AtomRail` sticky; `/docs` e Fonte de Dados mostram a sidebar fixa |

**Larguras de container por tela:**

| Tela | Largura |
|---|---|
| Hub, catálogos Negócio/Tópicos, feed Changelog | `max-w-5xl` |
| TagsPage | `max-w-4xl` |
| Catálogos Técnica/Serviço, páginas de átomo/tópico/guia/post | `max-w-6xl` (coluna de conteúdo `lg:max-w-3xl` nas páginas de leitura) |
| `/docs` | `max-w-4xl` |
| `/docs/fonte-de-dados` | `max-w-[1560px]` total, conteúdo `max-w-6xl` |
| Portal | `max-w-6xl` |

**Tratamentos de overflow recorrentes:**
- `overflow-x-auto` em: todas as tabelas shadcn, blocos de código, request line, assinatura, `FilterTable`.
- `truncate` em: títulos de card, nomes de átomo em chips e linhas, rótulos do rail.
- `min-w-0` em praticamente todos os `flex-1` (pré-requisito para o `truncate` funcionar).
- `break-words` em: valores da ficha técnica, nomes/e-mails no modal de pessoas.
- `line-clamp-2` no título dos itens do balão.
- `max-h-*` + scroll interno em: tabela padrão (28rem), índices do átomo, listas de pessoas (60vh), painel do grafo (46vh), dropdowns de busca.

**Elementos que não escalam bem (para o redesign avaliar):**
- Rail fixo em **220px** (Central) e **288px** (Fonte de Dados) — não é ajustável.
- Grafo 3D no mobile: os controles (busca + filtro `w-[min(82vw,260px)]` e painel `w-[min(86vw,288px)]`) podem se sobrepor em telas estreitas quando ambos estão abertos.
- H1 de `text-7xl`/`text-8xl` no hero de algumas telas — funciona, mas é bastante agressivo abaixo de 400px.

### 14.3 Acessibilidade — o que já existe

**Pontos fortes:**

| Área | Implementação |
|---|---|
| **Reduced motion** | Sistema completo em 3 camadas: bloco global, bloco `.fdd-*` específico, e hooks JS (`useReducedMotion`, `useInView`, `useCountUp`). `motion-safe:` no balão. `scrollIntoView` do `AtomRail` consulta a preferência |
| **Landmarks** | `<header>`, `<main>`, `<aside>`, `<nav aria-label="...">`, `<footer>`, `<section id>`, `<figure>/<figcaption>` |
| **`aria-label` em nav** | "Nesta página" (rail), "Navegação entre novidades", "breadcrumb", "grafo de vizinhança", "Filtrar tabela", "Filtrar seções", "Buscar nas novidades" |
| **Estado de controles** | `aria-expanded` (disclosures, `<details>`, accordion), `aria-pressed` (chips de tipo do changelog, botões de reação), `aria-current` (rail ativo), `aria-disabled` + `inert` (faixas bloqueadas), `aria-busy` (skeleton) |
| **Live region** | `role="status" aria-live="polite"` no balão |
| **`role="note"`** | Todos os `Callout` |
| **`role="img"` + `aria-label`** | Placeholder de screenshot |
| **Decorativos** | `aria-hidden` consistente em ícones, barras de acento, texturas de fundo, bolinhas, separadores |
| **Foco visível** | `focus-visible:ring-2 ring-primary/40` (ou `ring-ring` + offset) em chips, links de átomo, botões de reação, triggers de accordion, pílulas de pessoas |
| **Foco em elemento oculto** | A âncora `#` de seção (`opacity-0`) aparece em `:focus-visible` — navegável por teclado. O `CopyButton` do `code` idem (`focus-within:opacity-100`) |
| **Teclado — busca `/docs`** | ↑/↓ com wrap, Enter, Esc, + rodapé visual com os `<kbd>` |
| **Teclado — `CatalogSearch`** | Esc limpa |
| **Teclado — busca do grafo** | Enter abre o 1º resultado, Esc limpa |
| **Labels dinâmicos** | `CopyButton` (`"Copiar código"` ⇄ `"Copiado"`), toggle de tema (`"Tema claro"`/`"Tema escuro"`), botão `X` do balão (`"Marcar todas como lidas e fechar"`) |
| **Plural correto** | Onipresente: "1 seção"/"N seções", "1 conexão"/"N conexões", "1 átomo"/"N átomos", "nova"/"novas", "1 reação"/"N reações" |
| **`sr-only`** | `DialogTitle` do lightbox |
| **`tabular-nums`** | Números que animam (count-up, contagens de reação) — evita "pulo" de largura |

**Lacunas identificadas:**

| Lacuna | Detalhe |
|---|---|
| **Sem "pular para o conteúdo"** | Nenhuma tela de documentação tem skip link, apesar de todas terem rail/sidebar antes do conteúdo |
| **Grafo 3D sem alternativa acessível** | O canvas WebGL não é navegável por teclado nem exposto a leitor de tela. A busca e o filtro são acessíveis, mas o grafo em si não tem fallback textual |
| **`role="img"` sem alternativa nos diagramas** | Os 12 diagramas de `diagrams/` são HTML semântico (ok em parte), mas relações espaciais (espinha, conectores) não são anunciadas |
| **Toggle de tema não persistido** | Em `/docs/fonte-de-dados` e no Portal, altera a classe global do `<html>` sem gravar — a preferência se perde ao navegar |
| **`div` clicável no hub** | Card bloqueado/"em breve" usa `<div aria-disabled>` sem `role` — não é focável nem anunciado como controle desabilitado |
| **Contraste de cor não verificado** | As paletas hardcoded (`-600` sem `dark:` no `EndpointCard`, `text-primary/70`, `text-foreground/85`) não foram auditadas |
| **`title` como único tooltip** | Vários chips usam só o `title` nativo (`AtomLink`, `TopicChip`, `GuideChip`) — não aparece no foco por teclado |
| **Ordem de foco no lightbox** | ⚠️ A confirmar: o `Dialog` do shadcn gerencia focus trap, mas o comportamento com `fullscreen` não foi verificado |

---

## 15. Dores e oportunidades para o redesign

### 15.1 Duplicação — o mesmo problema resolvido N vezes

| Conceito | Implementações hoje | Onde |
|---|---|---|
| **Bloco de código** | **3** | `DocBlocks.CodeBlock` (tokens + copiar no hover) · `components/docs/CodeBlock` (slate hardcoded, sempre escuro) · `CodeViewer` (realce de sintaxe próprio, colapsável) |
| **Badge de método HTTP** | **2** paletas divergentes | `atoms/http.tsx` (PATCH violeta, com `dark:`) · `EndpointCard.methodColors` (PATCH laranja, **sem `dark:`**) |
| **Paleta por tipo de átomo** | **3** | `KIND_META.badgeClass` (tokens) · `SOLID_BY_FAMILY` (saturada) · `KIND_GRAPH_COLOR` (HSL fixa do canvas) |
| **Scroll-spy** | **2** | `useVisibleSections` (multi-ativo) · `useScrollSpy` (ativo único) |
| **Revelação por scroll** | **2** | `useInView` (consulta reduced-motion em JS) · `Reveal` (só CSS) |
| **Stat** | **2** | `StatBlock` (count-up + hover) · `Stat` (estático) |
| **`SectionHeader`** | **2** | `DocBlocks` (com âncora `#`) · `AtomPage` (com contador, sem âncora) |
| **Barra de progresso de leitura** | **3 cópias idênticas** | `TopicPage` · `PageGuidePage` · `ChangelogPostPage` — o mesmo componente `ReadingProgress` copiado e colado 3× |
| **Moldura de janela de navegador** | **2** | `ScreenshotBlock` (com lightbox) · `ImagePlaceholder` (com fallback de erro) |
| **Barra de busca de catálogo** | **2** | `CatalogSearch` (Técnica/Serviço) · input inline do feed do Changelog |
| **Toggle de tema** | **2 cópias** | `FonteDeDadosDocs.useTheme` · `PortalLayout.useTheme` |
| **Tipo `Tone`** | **~10** | Cada diagrama e primitivo redefine o seu localmente |
| **Grafo** | **2 stacks** | `react-force-graph-3d`+`three` (Central) · `cytoscape`+`fcose` (Portal) |
| **Sistema de "não lido"** | **2** | `useChangelogUnread` (localStorage) · `useChangelogNotifications` (servidor) |
| **Changelog** | **2** | `central-docs/changelog` (~60 posts, vivo) · `portal/changelog` (1 post, morto) |

### 15.2 Inconsistências de comportamento

| # | Inconsistência | Impacto |
|---|---|---|
| 1 | **`GuideBacklinks` não tem cadeado** — as outras três faixas têm. O post do changelog compensa com uma nota em texto | Comportamento imprevisível para o leitor |
| 2 | **Base URL divergente em `/docs`**: a seção Introdução mostra o `SUPABASE_URL` real, o cURL do `EndpointCard` mostra `https://seu-projeto.supabase.co` | Usuário copia cURL que não funciona |
| 3 | **Mapa `ICONS` incompleto no catálogo Negócio** — 13 dos 23 guias caem no fallback `GraduationCap` | A maior parte dos cards mostra o mesmo ícone |
| 4 | **Rodapé do hub desatualizado**: "o conteúdo ainda está sendo escrito… apenas uma prévia" quando os 5 pilares estão populados | Contradiz a realidade da tela |
| 5 | **`PillarDocPage` inalcançável** — todos os slugs têm rota estática antes do catch-all | Código morto de fato |
| 6 | **Filtro por método no catálogo Serviço esconde MCP tools e webhooks** sem avisar | Usuário pensa que sumiram |
| 7 | **Links `href="#"`** no footer de `/docs` ("Suporte", "Changelog") | Cliques sem efeito |
| 8 | **Link GitHub para `finza-tech/torre-controle`**, repo real é `blips-ai/cobranca-finza` | Provável 404 |
| 9 | **`scrollIntoView` da Fonte de Dados sempre `smooth`** — não consulta reduced-motion (diferente do `AtomRail`) | Movimento indesejado |
| 10 | **Toggle de tema em 2 telas só** (Fonte de Dados e Portal), sem persistência | Preferência se perde |
| 11 | **`CodeBlock` de `/docs` sem try/catch no clipboard** | Exceção não tratada em http |
| 12 | **Comentário de `pillars.ts` diz "4 pilares"**, há 5 | Doc interna desatualizada |
| 13 | **`SubBlock.meta` existe no primitivo mas não é repassado** pelo bloco `subBlock` | Recurso inacessível pelo autor |

### 15.3 Dívida estrutural

| Item | Detalhe |
|---|---|
| **4 caminhos legados em `TopicSection`** | `steps`, `body`, `callouts`, `atoms` — todos com o comentário "(Legado) preferir `blocks`". A `TopicPage` reimplementa o `StepsList` inline para renderizá-los |
| **`AtomPage` com 1804 linhas** | 30+ subcomponentes num arquivo só. Impossível reusar peça isolada |
| **`OtherSections.tsx` com 1591 linhas** | 5 grupos de seções de `/docs` no mesmo arquivo |
| **`getBacklinks` é O(n·e)** | Varre todos os átomos por consulta; é chamado por átomo na página **e** por átomo no `getGraphData()`. Com ~1.500 átomos ainda funciona, mas não escala |
| **Portal morto no repositório** | ~200 arquivos, testes, design system e um changelog paralelo sem rota. Decisão pendente há 2 meses |
| **`.fdd-doc` é invisível e crítico** | Remover o wrapper quebra a tipografia inteira, silenciosamente |
| **Zero testes na Central de Docs** | O Portal (morto) tem 11 arquivos de teste; a Central (viva) não tem nenhum |
| **Sem validação de integridade em runtime** | O Portal valida (Zod + ids duplicados + relações órfãs em dev); a Central ignora órfãos em silêncio |

### 15.4 Pontos fortes a PRESERVAR

Estes são os acertos do sistema atual. Perder qualquer um deles seria uma regressão.

1. **Arquitetura data-driven com glob.** Criar um tópico/guia/átomo/post = criar um arquivo em `data/`. Zero registro manual. Isso é o que permitiu chegar a 100% de cobertura de tabelas e Edge Functions.
2. **Backlinks derivados, nunca duplicados.** A aresta é escrita uma vez no átomo de origem; o inverso é calculado. O mesmo para os cross-links entre pilares. Não existe "lista de quem me usa" para manter atualizada.
3. **Robustez a curadoria incompleta.** Id inexistente nunca quebra a UI — vira texto esmaecido, chip não-clicável, ou é ignorado. Documentado explicitamente em 4 arquivos.
4. **Degradação elegante das features opcionais.** Reações, views e "quem viu" funcionam ou desaparecem — nunca geram erro visível.
5. **O cadeado que mostra em vez de esconder.** Pilar sem acesso aparece fosco com selo; faixa de cross-link aparece borrada. O usuário **descobre** que existe.
6. **Reduced motion completo, em 3 camadas.** CSS global + CSS específico + hooks JS.
7. **Scroll-spy multi-ativo.** Elimina o "pisca" do spy clássico. É uma solução melhor que a convencional.
8. **A página de átomo auto-montada.** 17 seções condicionais + rail derivado. Uma tabela e um endpoint rendem páginas diferentes com o mesmo componente.
9. **Segurança embutida nos tipos.** `sourcePath` é só caminho, `env` é só nome, `usage` é só contrato, `signature` é só assinatura — regras escritas nos comentários dos tipos, não em convenção oral.
10. **O gate de execução do testador.** Só super_admin dispara; todo mundo copia a cURL. Confirmação explícita para métodos mutantes.
11. **Datas UTC-safe.** `formatChangelogDate` parseia manualmente e usa `timeZone: "UTC"` — a data não "volta um dia" no Brasil.
12. **Descrições de tag com CRITÉRIO.** Cada tag diz não só o que significa, mas **quando é marcada**. Padrão de escrita raro e valioso.
13. **O catálogo de blocos.** Um autor escreve dados, nunca JSX. 14 blocos cobrem o repertório inteiro de três pilares.
14. **A identidade "blueprint telemetry".** Grade esquemática + espinha animada + mono + números grandes. É uma linguagem visual coerente e reconhecível.
15. **`fullHeight` na tabela.** A decisão de deixar a tabela de referência crescer inteira (para não quebrar o Ctrl+F) mostra atenção real ao uso.

### 15.5 Oportunidades para o redesign

**Consolidação (ganho alto, risco baixo):**
1. **Um** bloco de código, com variantes (tema/realce/colapsável/copiar).
2. **Uma** paleta de método HTTP e **uma** paleta de tipo de átomo (o canvas deriva da mesma fonte).
3. **Um** `ReadingProgress` compartilhado (hoje 3 cópias).
4. **Um** tipo `Tone` no design system, consumido por todos os diagramas.
5. **Um** `SectionHeader` com props para âncora e contador.
6. **Um** componente de moldura de navegador, com `src` opcional, lightbox opcional e fallback de erro.
7. Completar (ou tornar dinâmico) o mapa de ícones do catálogo Negócio.

**Coerência (ganho alto):**
8. Padronizar o cadeado nas 4 faixas de cross-link.
9. Padronizar a busca dos catálogos (um `CatalogSearch` com navegação por teclado, como a de `/docs`).
10. Decidir se o toggle de tema é global e persistido, ou não existe.
11. Corrigir os textos desatualizados (rodapé do hub, "4 pilares", links mortos, base URL do cURL).

**Estrutura (ganho médio, esforço maior):**
12. Colapsar os 4 caminhos legados de `TopicSection` em `blocks` (migração de dados + remoção de ~60 linhas de render duplicado).
13. Quebrar `AtomPage.tsx` em seções reutilizáveis (uma pasta `sections/`).
14. Indexar `getBacklinks` (construir o mapa reverso uma vez, como já se faz com `getIndex`).
15. Decidir o destino do Portal (retomar, aposentar ou extrair o reaproveitável: `ConceptRef`, `DesignRecipes`, validação Zod, testes).

**Acessibilidade (ganho alto, esforço baixo):**
16. Skip link em todas as telas de documentação.
17. Alternativa textual/tabular para o grafo 3D.
18. Trocar `<div aria-disabled>` por `<button disabled>` nos cards bloqueados.
19. Auditoria de contraste nas paletas hardcoded, adicionando variantes `dark:` onde faltam.
20. Tooltips acessíveis (Radix) no lugar do `title` nativo nos chips.

**Novas capacidades sugeridas pelo que já existe:**
21. **Busca global na Central de Docs** — hoje cada catálogo tem sua busca local e não há busca transversal (tópico + guia + átomo + post). O índice já existe nos registries.
22. **Validação de integridade em build/dev na Central**, no molde do `manifest.ts` do Portal (ids duplicados, relações órfãs, schema).
23. **`ConceptRef` na Central** — referência inline com popover para um conceito, sem sair da leitura.
24. **Estado de "visto" por página de doc**, não só por post de changelog.

---

## Apêndice · Inventário de arquivos-fonte

| Domínio | Caminho | Arquivos | Observação |
|---|---|---|---|
| Hub | `src/pages/CentralDocsPage.tsx` | 1 | 416 linhas |
| Pilares (config) | `src/pages/central-docs/pillars.ts` | 1 | fonte única dos 5 pilares |
| Central (raiz) | `src/pages/central-docs/` | 9 | `PillarDocPage`, `TecnicaCatalogPage`, `ServicoCatalogPage`, `CatalogToolbar`, `AtomRail`, `CentralDocsGraph`, `GraphPage`, `TagsPage`, `EndpointTester`, `apiAuth` |
| Átomos (motor) | `src/pages/central-docs/atoms/` | 6 | `AtomPage` (1804 l.), `kinds`, `registry`, `relations`, `tags`, `types`, `http` |
| Átomos (dados) | `src/pages/central-docs/atoms/data/` | **64** | ~48.000 linhas de conteúdo |
| Tópicos | `src/pages/central-docs/topics/` | 6 + 20 dados | `TopicsCatalogPage`, `TopicPage`, `types`, `registry`, `AtomLink`, `useInView` |
| Negócio | `src/pages/central-docs/negocio/` | 4 + 23 dados | `NegocioCatalogPage`, `PageGuidePage`, `types`, `registry` |
| Changelog | `src/pages/central-docs/changelog/` | 8 + ~60 posts | 3 páginas/componentes + `typeMeta`, `types`, `registry`, 4 hooks |
| Compartilhado | `src/pages/central-docs/shared/` | 3 | **`DocBlocks.tsx`**, `CrossLinkChips.tsx`, `crosslinks.ts` |
| `/docs` | `src/pages/DocsPage.tsx` + `src/components/docs/` | 1 + 10 | 5 arquivos de seção somando ~3.900 linhas |
| Fonte de Dados | `src/pages/FonteDeDadosDocs.tsx` + `src/components/fonte-de-dados-docs/` | 1 + 29 | **`primitives.tsx`**, 12 diagramas, 9 seções, 2 de dados |
| Doc Especial | `src/pages/DocsEspecialPage.tsx` | 1 | 160 linhas, lista de 1 item |
| Portal | `src/portal/` | ~200 | **sem rota** |
| Sidebar/balão | `src/components/layout/` | 2 | `DocsNavButton`, `ChangelogNotificationBalloon` |
| Estilos | `src/index.css` | linhas 651-893 | catálogo `.fdd-*` |
| Rotas | `src/App.tsx` | linhas 172-400 | 16 rotas de documentação |

---

*Fim do documento. Todas as afirmações derivam da leitura do código-fonte em `cobranca-finza/src/` na data indicada no cabeçalho. Itens marcados com ⚠️ são ou divergências reais encontradas no código, ou pontos que precisam de confirmação antes de qualquer mudança.*

---
