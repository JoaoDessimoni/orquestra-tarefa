# 03 · Design System e Paleta — Torre de Controle

> Fonte da verdade: `cobranca-finza/src/index.css`, `cobranca-finza/tailwind.config.js`, `cobranca-finza/src/components/ui/*`.
> Este documento descreve o design system **atual**. Ele é o contrato mínimo do redesenho: o Claude Design pode evoluir a estética, mas precisa entregar **todos os papéis semânticos** aqui listados (cada token existe porque algum estado da interface depende dele).

---

## 1. Princípios visuais vigentes

A Torre é um **painel operacional denso**, não um site de marketing. As decisões visuais atuais refletem isso:

| Princípio | Como aparece hoje |
|---|---|
| Densidade de informação | Fonte base de **14px** (não 16px). Tabelas com dezenas de colunas. Cards compactos. |
| Neutralidade cromática | Fundo quase branco / cinza-azulado. Cor só para **significado** (status, ação primária, alerta). |
| Azul Finza como única cor de marca | `--primary` = azul #002FCC. Tudo que é "ação principal", "selecionado" e "link" usa ele. |
| Semântica por cor fixa | Verde = sucesso/pago. Âmbar = atenção/pendente. Vermelho = falha/destrutivo. Azul-céu = informativo. |
| Tema claro e escuro paritários | Todo token tem par no `.dark`. Nenhuma tela é só-claro. |
| Zero cor hardcoded | Regra dura do projeto: cores sempre por CSS var/token, nunca hex solto no componente. |

---

## 2. Paleta — tema claro

Valores canônicos em HSL (é assim que vivem no código). O hex é aproximação para uso em ferramenta de design.

### 2.1 Superfícies e texto

| Token | HSL | Hex aprox. | Papel na interface |
|---|---|---|---|
| `--background` | `0 0% 98%` | `#FAFAFA` | Fundo da janela. O conteúdo rola sobre `bg-muted/30`. |
| `--foreground` | `220 13% 18%` | `#282C34` | Texto principal. |
| `--card` | `0 0% 100%` | `#FFFFFF` | Fundo de card, tabela, modal, popover. |
| `--card-foreground` | `220 13% 18%` | `#282C34` | Texto sobre card. |
| `--popover` | `0 0% 100%` | `#FFFFFF` | Fundo de popover/dropdown/tooltip. |
| `--popover-foreground` | `220 13% 18%` | `#282C34` | Texto de popover. |
| `--muted` | `220 13% 95%` | `#F1F2F4` | Fundo secundário: cabeçalho de tabela, área de conteúdo, chips neutros. |
| `--muted-foreground` | `220 9% 46%` | `#6B7280` | Texto secundário, rótulos, placeholders, descrições. |
| `--border` | `220 13% 91%` | `#E5E7EB` | Toda borda. Aplicado globalmente via `* { border-color: var(--color-border) }`. |
| `--input` | `220 13% 91%` | `#E5E7EB` | Borda de campo de formulário. |
| `--ring` | `226 100% 40%` | `#002FCC` | Anel de foco (acessibilidade). |

### 2.2 Marca e ação

| Token | HSL | Hex aprox. | Papel |
|---|---|---|---|
| `--primary` | `226 100% 40%` | `#002FCC` | **Azul Finza.** Botão principal, item de menu ativo, link, número em destaque, série principal de gráfico. |
| `--primary-foreground` | `0 0% 100%` | `#FFFFFF` | Texto sobre o azul. |
| `--secondary` | `220 13% 95%` | `#F1F2F4` | Botão secundário. |
| `--secondary-foreground` | `220 13% 18%` | `#282C34` | Texto do botão secundário. |
| `--accent` | `226 100% 95%` | `#E6EBFF` | Azul muito claro: hover de item de menu, linha selecionada, fundo de destaque suave. |
| `--accent-foreground` | `226 100% 40%` | `#002FCC` | Texto sobre o accent. |
| `--gradient-primary` | `linear-gradient(135deg, hsl(226 100% 40%), hsl(226 100% 50%))` | — | Gradiente de marca (classe `.gradient-primary`). Usado com parcimônia. |

### 2.3 Estados semânticos

| Token | HSL | Hex aprox. | Significado no produto |
|---|---|---|---|
| `--success` | `142 76% 36%` | `#16A34A` | Pago, entregue, concluído, ativo, saudável. |
| `--success-foreground` | `0 0% 100%` | `#FFFFFF` | Texto sobre verde. |
| `--warning` | `38 92% 50%` | `#F59E0B` | Pendente, atenção, pausado, vence hoje, degradado. |
| `--warning-foreground` | `0 0% 100%` | `#FFFFFF` | Texto sobre âmbar. |
| `--info` | `199 89% 48%` | `#0EA5E9` | Informativo, em processamento, neutro-positivo. |
| `--info-foreground` | `0 0% 100%` | `#FFFFFF` | Texto sobre azul-céu. |
| `--destructive` | `0 84% 60%` | `#EF4444` | Falha, erro, exclusão, bloqueio, ação irreversível. |
| `--destructive-foreground` | `0 0% 100%` | `#FFFFFF` | Texto sobre vermelho. |

### 2.4 Sidebar (conjunto próprio de tokens)

A sidebar tem paleta separada para poder divergir do resto do app sem quebrar nada.

| Token | HSL claro | Hex aprox. | Papel |
|---|---|---|---|
| `--sidebar-background` | `0 0% 100%` | `#FFFFFF` | Fundo da barra lateral (branco, destacando-se do `#FAFAFA` do app). |
| `--sidebar-foreground` | `220 13% 18%` | `#282C34` | Texto do menu. |
| `--sidebar-primary` | `226 100% 40%` | `#002FCC` | Cor de marca dentro da sidebar. |
| `--sidebar-primary-foreground` | `0 0% 100%` | `#FFFFFF` | — |
| `--sidebar-accent` | `226 100% 40%` | `#002FCC` | **Fundo do item de menu ativo** (azul sólido). |
| `--sidebar-accent-foreground` | `0 0% 100%` | `#FFFFFF` | Texto/ícone do item ativo. |
| `--sidebar-border` | `220 13% 91%` | `#E5E7EB` | Divisórias internas da sidebar. |
| `--sidebar-ring` | `226 100% 40%` | `#002FCC` | Foco. |

Hover de item não-ativo: `bg-sidebar-accent/10` + `text-sidebar-accent` (azul 10% de opacidade com texto azul).

---

## 3. Paleta — tema escuro

O escuro **não** é uma inversão: é um cinza-azulado profundo com o azul de marca **clareado** (40% → 55% de luminosidade) para manter contraste.

| Token | HSL escuro | Hex aprox. | Observação |
|---|---|---|---|
| `--background` | `220 15% 10%` | `#16181D` | Fundo da janela. |
| `--foreground` | `210 20% 92%` | `#E6EBEF` | Texto principal (não branco puro). |
| `--card` | `220 15% 13%` | `#1C1F26` | Card/modal — um degrau acima do fundo. |
| `--popover` | `220 15% 13%` | `#1C1F26` | — |
| `--primary` | `226 100% 55%` | `#194FFF` | Azul clareado. |
| `--secondary` / `--muted` | `220 15% 18%` | `#272C35` | Superfície terciária. |
| `--muted-foreground` | `220 9% 60%` | `#9096A2` | Texto secundário. |
| `--accent` | `226 60% 20%` | `#142352` | Azul escuro dessaturado (destaque suave). |
| `--accent-foreground` | `226 100% 70%` | `#668AFF` | Azul claro sobre o accent. |
| `--destructive` | `0 72% 51%` | `#DC2828` | Vermelho levemente rebaixado. |
| `--border` / `--input` | `220 15% 20%` | `#2B313B` | Bordas. |
| `--ring` | `226 100% 55%` | `#194FFF` | Foco. |
| `--sidebar-background` | `220 15% 11%` | `#181B20` | Sidebar um degrau abaixo do card. |
| `--sidebar-accent` | `226 100% 55%` | `#194FFF` | Item ativo. |
| `--success` | `142 76% 42%` | `#1ABC55` | Verde clareado. |
| `--warning` | `38 92% 50%` | `#F59E0B` | Igual ao claro. |
| `--info` | `199 89% 48%` | `#0EA5E9` | Igual ao claro. |

**Mecanismo de tema:** classe `.dark` no `<html>` (`darkMode: ["class"]` no Tailwind), alternada pelo hook `useTheme` e acionada no menu do usuário na sidebar ("Modo Escuro" / "Modo Claro"). Persistência em `localStorage`.

**Detalhe técnico que o redesenho precisa respeitar:** o projeto usa **Tailwind CSS v4**, e por isso declara os tokens **duas vezes** — em `@theme` como `--color-*` (o que as classes utilitárias realmente consomem) e em `:root` como componentes HSL crus `--primary: 226 100% 40%` (usados em `hsl(var(--primary) / 0.15)` para opacidades). O bloco `.dark` sobrescreve **os dois conjuntos**. Esquecer um dos dois deixa metade do app sem tema escuro.

---

## 4. Tipografia

### 4.1 Família

**Inter** é a única fonte do produto — e isso é imposto agressivamente:

```css
body { font-family: 'Inter', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, ...; }
.font-mono { font-family: 'Inter', ... !important; font-variant-numeric: tabular-nums; }
code, pre, kbd, samp { font-family: 'Inter', ... !important; }
```

Ou seja: **não existe monoespaçada no app**, nem em blocos de código. A "monoespaçada" é simulada com `font-variant-numeric: tabular-nums` sobre a Inter — números alinham em coluna sem trocar de família.

Ativação de recursos OpenType da Inter: `font-feature-settings: 'cv02', 'cv03', 'cv04', 'cv11'` (formas alternativas de `a`, `g`, `l`, `1` — deixa o texto mais legível em tamanho pequeno).

**Exceção única:** a rota `/docs/fonte-de-dados` reativa monoespaçada real via classes `.fdd-mono` / `.fdd-code` (`ui-monospace, SFMono-Regular, JetBrains Mono, Cascadia Code, Menlo, Consolas`, 12.5px / line-height 1.65).

### 4.2 Escala

A escala do Tailwind foi **rebaixada** em relação ao padrão — o `base` é 14px, não 16px:

| Classe | Tamanho | Line-height | Uso típico |
|---|---|---|---|
| `text-xs` | 12px | 16px | Badges, legendas, metadados, texto de apoio em card. |
| `text-sm` | 13px | 20px | Descrições, rótulos de formulário, texto de botão. |
| `text-base` | **14px** | 24px | **Padrão de corpo, tabela, input, lista.** |
| `text-lg` | 16px | 28px | Título de modal, título de card pequeno. |
| `text-xl` | 18px | 28px | Subtítulo de seção. |
| `text-2xl` | 20px | 28px | `CardTitle` padrão, título de bloco. |
| `text-3xl` | 24px | 32px | Título de página, número de KPI. |
| `text-4xl` | 30px | 36px | Número de KPI grande. |
| `text-5xl` | 36px | 40px | Raro — hero de tela de login/onboarding. |

### 4.3 Regras globais de texto

```css
body { font-weight: 400; font-size: 14px; line-height: 1.5; }
h1..h6 { font-weight: 600; letter-spacing: -0.025em; }
table th { font-weight: 500; font-size: 14px; }
table td { font-weight: 400; letter-spacing: 0; font-size: 14px; }
```

- Títulos são **semibold (600)** com tracking negativo — nunca bold 700 por padrão.
- Cabeçalho de tabela é **medium (500)**, não bold: a hierarquia vem do peso sutil e da cor, não de caixa alta ou negrito pesado.
- Existe uma regra `*, *::before, *::after { font-size: inherit }` que força herança. No redesenho, se usar classes utilitárias de tamanho dentro de um título, lembre que essa regra global compete com elas (o app resolve isso com `revert-layer` no escopo `.fdd-doc`).

### 4.4 Exceção de densidade: página de Dashboard

O Dashboard sobe o corpo para **16px** via atributo `data-page="dashboard"`, **mas mantém tabelas e listas em 14px**:

```css
[data-page="dashboard"] { font-size: 16px; }
[data-page="dashboard"] table, td, th, ul, ol, li { font-size: 14px; }
```

Motivo: o Dashboard é lido de longe / projetado em reunião; as tabelas continuam densas.

Variáveis: `--font-size-data: 14px`, `--font-size-body: 14px`, `--font-size-dashboard: 16px`.

---

## 5. Forma, espaço e elevação

### 5.1 Raio de borda

| Token | Valor | Uso |
|---|---|---|
| `--radius` | `0.5rem` (8px) | Base. |
| `radius-lg` | `8px` | Card, painel, alert, bloco. |
| `radius-md` | `6px` (`calc(8px - 2px)`) | Botão, input, item de menu. |
| `radius-sm` | `4px` (`calc(8px - 4px)`) | Aba, chip pequeno. |
| `rounded-full` | — | Badge, avatar, pílula de status, botão de fechar do modal. |
| `rounded-xl` | 12px | Modal (`sm:rounded-xl`) — o modal é mais arredondado que o resto. |

### 5.2 Espaçamento

Escala Tailwind padrão (múltiplos de 4px). Valores recorrentes no código:

| Contexto | Padding/Gap |
|---|---|
| Container de conteúdo da página | `p-3` (mobile) → `sm:p-6` (desktop) |
| `Card` (header, content, footer) | `p-6`; em mobile reduzido para `0.75rem 1rem` via media query |
| Modal (`DialogContent`) | `px-6`, header `pt-6 pb-4`, body `py-4`, footer `py-4` |
| Item de menu da sidebar | `px-3 py-2.5`, `gap-3` |
| Nav da sidebar | `p-2`, `space-y-1` |
| Grupo de botões | `gap-2` |

### 5.3 Elevação (sombra)

Elevação é **discreta** — o produto separa planos por borda e por tom de superfície, não por sombra forte.

| Elemento | Sombra |
|---|---|
| Card | `shadow-sm` |
| Popover / dropdown / tooltip | `shadow-md` a `shadow-lg` |
| Modal (`DialogContent`) | `shadow-xl` |
| Sheet (painel lateral) | `shadow-lg` |
| Aba ativa | `shadow-sm` (fundo branco sobre trilho cinza) |
| Overlay de modal | `bg-black/80` |
| Overlay de sidebar mobile | `bg-black/50 backdrop-blur-sm` |

### 5.4 Camadas (z-index)

| Camada | z-index |
|---|---|
| Backdrop da sidebar mobile | `z-40` |
| Sidebar mobile (drawer) | `z-50` |
| Sheet e seu overlay | `z-50` |
| Overlay de modal | `z-[60]` |
| Conteúdo do modal | `z-[60]` (wrapper) + `z-10` (painel) |

Modal **vence** sheet e sidebar — é intencional: é comum abrir um dialog de confirmação a partir de um painel lateral.

### 5.5 Dimensões fixas notáveis

| Elemento | Medida |
|---|---|
| Sidebar expandida | `w-64` (256px) |
| Sidebar recolhida | `w-16` (64px) |
| Cabeçalho da sidebar / topo | `h-16` (64px) |
| Botão padrão | `h-10` |
| Botão `sm` | `h-9` |
| Botão `lg` | `h-11` |
| Botão de ícone | `h-10 w-10` |
| Trilho de abas | `h-10` |
| Sheet lateral | `w-3/4`, `sm:max-w-sm` |
| Altura máxima do modal | `max-h-[calc(100vh-2rem)]` |
| Ícone dentro de botão | `size-4` (16px) |
| Ícone de menu | `h-5 w-5` (20px) |
| Avatar | `h-8 w-8` |

---

## 6. Iconografia

- Biblioteca única: **lucide-react** (`^0.562.0`). Não há Font Awesome, Material Icons nem SVG avulso de ícone.
- Traço padrão do Lucide, sem preenchimento.
- Tamanhos: `h-4 w-4` (inline/botão), `h-5 w-5` (navegação), `h-8 w-8`+ (estado vazio/ilustrativo).
- Ícones dentro de botão recebem `[&_svg]:size-4 [&_svg]:shrink-0 [&_svg]:pointer-events-none` automaticamente.
- **Ícones do menu principal** (contrato de reconhecimento — manter ou substituir conscientemente):

| Item | Ícone lucide |
|---|---|
| Dashboard | `LayoutDashboard` |
| Gestão de Carteira | `Users` |
| Campanhas | `Target` |
| Réguas de Cobrança | `GitBranch` |
| Templates | `MessageSquareText` |
| Filtros | `Filter` |
| Ações | `Zap` |
| Disparos | `Send` |
| Agente IA | `Bot` |
| Integrações | `Plug` |
| Fonte de Dados | `Database` |
| Configurações | `Settings` |
| Organização | `Building2` |
| Usuário | `User` / `Avatar` |
| Sair | `LogOut` |
| Tema | `Moon` / `Sun` |
| Recolher/expandir sidebar | `ChevronLeft` / `ChevronRight` |
| Menu mobile | `Menu` |

---

## 7. Marca

| Asset | Arquivo | Onde aparece |
|---|---|---|
| Logo completo Torre de Controle | `src/assets/logo-torre-controle.png` | Sidebar expandida (`h-8`), header mobile (`h-7`) |
| Ícone Torre de Controle | `src/assets/torre-controle-logo-icon.png` | Sidebar recolhida (`h-8`) |
| Logo alternativo | `src/assets/torre-controle-logo.png` | — |
| Logo Finza | `src/assets/finza-logo.png` | — |
| Logo da organização | `currentOrg.logo_url` (dinâmico) | Seletor de organização na sidebar; fallback `Building2` |

⚠️ A confirmar: os logos são PNG pesados (473 KB / 164 KB / 138 KB). O redesenho deveria entregar SVG.

---

## 8. Movimento

| Animação | Duração / curva | Onde |
|---|---|---|
| `accordion-down` / `accordion-up` | 0.2s ease-out | Acordeão (Radix) |
| `collapsible-down` / `collapsible-up` | 0.2s ease-out | Collapsible (Radix) |
| `refresh-bar` | 1.1s ease-in-out infinita | Barra de progresso indeterminada do `RefreshTopBar` |
| Abertura de modal | 200ms, `fade-in-0` + `zoom-in-95` | `DialogContent` |
| Abertura de sheet | 500ms entrada / 300ms saída, `slide-in-from-*` | `SheetContent` |
| Recolher sidebar | `transition-all duration-300` | Sidebar e `main` |
| Sidebar mobile | `transition-transform duration-300` | Drawer |
| Hover geral | `transition-colors` | Botões, links, itens de menu |

**Acessibilidade de movimento:** existe bloco `@media (prefers-reduced-motion: reduce)` que zera durações (`0.01ms`) e desliga `animate-spin`, `animate-pulse`, `animate-bounce`, `animate-ping`. **O redesenho deve manter isso.**

---

## 9. Estilos especiais `.fdd-*` (documentação viva da Fonte de Dados)

Conjunto isolado, prefixado, usado apenas na rota `/docs/fonte-de-dados`. Todas as cores derivam dos tokens do tema.

| Classe | Efeito |
|---|---|
| `.fdd-mono`, `.fdd-code` | Monoespaçada real, 12.5px, line-height 1.65, sem ligaturas. |
| `.fdd-grid` | Grade blueprint de fundo (linhas a 3,5% de opacidade, 28×28px). |
| `.fdd-spine` | Linha vertical em gradiente azul (espinha do pipeline). |
| `.fdd-flow` | Pulso azul percorrendo a espinha (3.6s linear infinita) — "dado em movimento". |
| `.fdd-dash` | Traço SVG animado (`stroke-dasharray: 6 6`, 1s infinita) — conexões entre edge functions. |
| `.fdd-reveal` | Revelação no scroll: opacidade 0→1 + `translateY(14px)`→0, 0.6s. |
| `.fdd-stagger` | Revelação em escada: filhos entram com atraso de `calc(var(--i) * 70ms)`. |
| `.fdd-timeline-fill` | Conector de timeline que "se desenha" (`scaleY` 0→1, 0.9s, cubic-bezier(0.22,1,0.36,1)). |
| `.fdd-collapse` | Expandir/recolher com altura automática via truque de `grid-template-rows: 0fr → 1fr` (0.28s). |
| `.fdd-anchor` | Âncora `#` que aparece no hover do título da seção. |
| `.fdd-rail-link[data-active]` | Realce de scroll-spy no rail lateral. |
| `.fdd-doc` scrollbars | Barras finas (8px), arredondadas, thumb em `foreground/18%`, hover em `primary/55%`. |
| `.fdd-doc ol.fdd-ol` | Lista numerada com badge quadrado azul (`counter`, `decimal-leading-zero`, 01/02/03) e linha divisória entre itens. |

Todas respeitam `prefers-reduced-motion`.

---

## 10. Chips de variável (editor de mensagem)

Padrão visual das variáveis `{{...}}` dentro dos editores de template (TipTap):

| Classe | Aparência |
|---|---|
| `.variable-chip` | Pílula inline, fundo `primary/15%`, texto `primary`, borda `primary/30%`, raio 6px, 14px semibold, `user-select: none`. Hover: fundo `primary/25%`, borda `primary/50%`. |
| `.variable-chip-custom` | Variante **teal** para campo personalizado: fundo `hsl(180 60% 40% / 0.15)`, texto `hsl(180 60% 35%)`, borda `hsl(180 60% 40% / 0.3)`. |

Ou seja: **azul = variável de sistema, teal = campo personalizado do cliente.** Essa distinção é funcional e precisa sobreviver ao redesenho.

Dropdown de sugestão (Tippy.js, tema `suggestion`): fundo `popover`, borda `border`, raio 8px, `shadow-lg`, sem seta.

---

## 11. Impressão / exportação em PDF

Existe um bloco `@media print` completo, porque o Dashboard é impresso/exportado. Regras:

- Esconde `aside`, `nav`, `[aria-label="Menu principal"]` e tudo com `.print:hidden` (com `position: absolute; left: -9999px` para não reservar espaço).
- Mostra `.print:block`.
- Desfaz o shell flex: `.flex.h-screen` vira `display: block; height: auto`.
- `main` ocupa 100% da largura, sem margem.
- Cards perdem sombra e ganham `break-inside: avoid`.
- Grids de 2 colunas viram 1; grid de 4 vira 2.
- Gráficos: `canvas` e contêineres Recharts limitados a 100% da largura, `.h-64` reduzido para 220px.
- `@page { margin: 1cm; size: A4 }`.
- `print-color-adjust: exact` para os fundos coloridos saírem impressos.

**O redesenho precisa manter uma folha de impressão equivalente.**

---

## 12. Responsividade

Breakpoint operacional único: **768px** (`md`). Abaixo disso o app é considerado mobile.

| Comportamento | Regra |
|---|---|
| Sidebar | Vira drawer sobreposto (`fixed inset-y-0 left-0 z-50`) com backdrop; fecha ao navegar. Header mobile com logo + hambúrguer. |
| Títulos | `h1` cai para 1.25rem, `h2` para 1.1rem (`!important`). |
| Abas | `[role="tablist"]` ganha rolagem horizontal, `flex-wrap: nowrap`, scrollbar escondida. |
| Cards | Padding reduzido para `0.75rem 1rem`; `overflow: hidden`; `min-width: 0`. |
| Tabelas | Rolagem horizontal com `-webkit-overflow-scrolling: touch`. |
| Selects/inputs | `max-width: 100%` para não estourar. |
| Filtros | Componente `mobile-collapsible-filters` recolhe a barra de filtros. |
| Container | `padding: 2rem`, centralizado, `2xl: 1400px` de largura máxima. |

---

## 13. Acessibilidade — o que já existe (não regredir)

| Recurso | Implementação |
|---|---|
| Link "pular para conteúdo" | `<a href="#main-content">` visível só no foco, no topo da sidebar. |
| Landmarks | `<aside role="navigation" aria-label="Menu principal">`, `<main id="main-content">`. |
| Anel de foco | `focus-visible:ring-2 ring-ring ring-offset-2` em botões e abas. |
| Estado desabilitado | `disabled:opacity-50 disabled:pointer-events-none disabled:cursor-not-allowed`. |
| Texto para leitor de tela | `sr-only` em botões só-ícone (ex.: "Close" do modal). |
| Movimento reduzido | `prefers-reduced-motion` respeitado. |
| Base Radix UI | Todos os overlays (dialog, sheet, popover, dropdown, tooltip, select) herdam foco preso, ESC para fechar e navegação por teclado do Radix. |

---

## 14. Resumo executivo para o redesenho

O que **precisa sobreviver** ao redesenho, independentemente da estética escolhida:

1. Os **8 papéis de cor**: superfície, texto, borda, marca/ação, destaque suave, sucesso, atenção, erro, informação — cada um com par claro **e** escuro.
2. A **densidade**: corpo de 14px, tabela de 14px, Dashboard em 16px.
3. A **paleta semântica de status** — verde/âmbar/vermelho/azul-céu — porque dezenas de badges, colunas e gráficos dependem dela para significar.
4. A distinção **azul = variável de sistema / teal = campo personalizado**.
5. A **sidebar de 256px ↔ 64px** com item ativo em azul sólido.
6. O **modal acima do painel lateral** (`z-60` vs `z-50`).
7. A **folha de impressão** do Dashboard.
8. `prefers-reduced-motion`.
9. Zero cor hardcoded — tudo por token.
