# Componentes — Design System OrquestrAI (canônico Finza)

> Inventário de componentes UI com diretrizes canônicas Finza (dotted cards, eye, pill, banner, hero-dark, ghost h1, ◆ iaf marker). Última atualização: 21/05/2026.

## Fontes

- [TOKENS.md](TOKENS.md)
- `.claude/skills/finza-design-system/SKILL.md`
- `BOARD.html` (referência viva, v2)

---

## 1 · Componentes canônicos Finza (não-negociáveis)

### 1.1 Card (2px dotted)

Assinatura visual mais marcante. Use em qualquer agrupamento de informação.

```css
.card {
  background: var(--surface);
  border: 2px dotted var(--finza-blue);
  border-radius: var(--radius-md);
  padding: 20px;
  transition: transform .12s, box-shadow .12s;
}
.card.clickable:hover { transform: translateY(-1px); box-shadow: 0 6px 14px rgba(26,26,255,.08); }
```

### 1.2 Ghost h1 + Accent

Título de view: peso 300 cinza claro + accent peso 700 em azul Finza.

```html
<h1 class="ghost">Dashboard — <span class="accent">Produção & Gestão</span></h1>
<p class="sub">Subtítulo descritivo, max 720px, --text-muted.</p>
```

### 1.3 Marker ◆ iaf

Canto superior direito de **toda view do main**. Identidade Finza inquestionável.

```html
<span class="iaf-mark">◆ iaf</span>
```
```css
.iaf-mark { position: absolute; top: 20px; right: 32px; font-size: 11px; font-weight: 700; color: var(--finza-blue); letter-spacing: .1em; z-index: 5; }
```

### 1.4 Eye (numeração círculo dark)

Para listagens numeradas (etapas, plataformas).

```html
<div class="eye">3</div>
```
```css
.eye { width: 28px; height: 28px; border-radius: 50%; background: var(--finza-dark); color: #fff;
       display: inline-flex; align-items: center; justify-content: center; font-weight: 700; font-size: 12px; }
```

### 1.5 Pill (background azul-soft)

```html
<span class="pill">25 vinculadas</span>
```
```css
.pill { display: inline-flex; align-items: center; gap: 5px; padding: 3px 10px;
        background: var(--finza-blue-soft); color: var(--finza-blue); border-radius: 99px;
        font-size: 11px; font-weight: 600; }
```

### 1.6 Tag (mini-pill quadrada)

```css
.tag { display: inline-flex; align-items: center; padding: 1px 7px;
       background: var(--finza-blue-soft); color: var(--finza-blue);
       border-radius: 4px; font-size: 10px; font-weight: 600; text-transform: lowercase; }
```

### 1.7 Banner (destaque accent)

```html
<div class="banner">Esta semana: 5 pendências com deadline.</div>
<div class="banner dark">Decisão crítica registrada</div>
```
```css
.banner { background: var(--finza-blue); color: #fff; padding: 14px 20px;
          border-radius: var(--radius-md); font-weight: 500; margin-bottom: 16px; }
.banner.dark { background: var(--finza-dark); }
```

### 1.8 Hero dark (impacto no Dashboard)

Bloco escuro dramático com glow azul. Usado no topo do Dashboard, slide-Esperanza, e cards de impacto.

```html
<div class="hero-dark">
  <div class="label">Esta semana · 21 de maio de 2026</div>
  <div class="title">11 <span class="accent">itens</span> demandam atenção</div>
  <div class="hero-stats">
    <div class="hero-stat"><div class="num">5<span class="unit">pend.</span></div><div class="lab">com deadline</div></div>
    ...
  </div>
</div>
```

Visual: bg `--finza-dark`, radial-gradient azul no canto, números mono 32px peso 700, labels rgba(255,255,255,.65).

### 1.9 Tag numérica (P01, RM01)

```css
.tag-num { display: inline-block; padding: 2px 8px; background: var(--finza-blue);
           color: #fff; border-radius: 4px; font-size: 10px; font-weight: 700;
           letter-spacing: .06em; font-family: var(--font-mono); }
```

---

## 2 · Componentes de aplicação (enterprise)

### 2.1 Sidebar dark

```
┌─────────────────────────────┐
│ ◆ OrquestrAI       v2 proto │
│                             │
│ TRABALHO                    │
│   ⌂ Dashboard          1    │
│   ⚡ Execuções          2    │
│                             │
│ CONHECIMENTO                │
│   ◈ Agentes           3 (9) │
│   ◇ Subagentes        4 (6) │
│   ◆ Skills            5 (3) │
│   ⌥ Commands          6(10) │
│                             │
│ PRODUÇÃO                    │
│   🔍 Análises         7 (2) │
│   📤 Relatórios       8 (1) │
│   ▢ Pendências        9(26) │
│   🗓 Reuniões         (3)  │
│   🛣 Roadmap          (24) │
│                             │
│ SISTEMA                     │
│   👤 1on1s            (0)  │
│   ⚙ Settings           ,    │
│                             │
│ ─────────────────────       │
│ JV João Vinícius            │
│    Supervisor IAF           │
└─────────────────────────────┘
```

- Background `--finza-dark` (#0A0A2E)
- Item ativo: bg `--finza-blue` + texto branco peso 500
- Item normal: bg transparent, texto `rgba(255,255,255,.7)`
- Item hover: bg `rgba(255,255,255,.06)`, texto branco
- Count: badge mono pequeno `rgba(255,255,255,.1)`
- Shortcut: mono `rgba(255,255,255,.35)`

### 2.2 Topbar (white, sticky)

```
┌────────────────────────────────────────────────┐
│ Dashboard      [🔍 Buscar… ⌘K]     [?]         │
└────────────────────────────────────────────────┘
```

48-52px altura, border-bottom `--border`, padding 0 28px.

### 2.3 KPI card (canônico)

```css
.kpi { background: var(--surface); border: 2px dotted var(--finza-blue);
       border-radius: var(--radius-md); padding: 16px 18px; }
.kpi .lab { font-size: 10px; letter-spacing: .14em; color: var(--text-muted);
            text-transform: uppercase; font-weight: 600; }
.kpi .num { font-size: 34px; font-weight: 700; color: var(--finza-blue);
            line-height: 1; font-family: var(--font-mono); }
```

### 2.4 Badge

Variantes: `success`, `warning`, `danger`, `info`, `neutral`, `accent`, `frente-*`.

| Variante | Bg | Texto |
|---|---|---|
| success | --success-soft | #065F46 |
| warning | --warning-soft | #92400E |
| danger | --danger-soft | #991B1B |
| info | --info-soft | #075985 |
| neutral | #F3F4F6 | #374151 |
| accent | --finza-blue-soft | --finza-blue-deep |
| frente-* | cor da frente .12 alpha | cor da frente solid |

### 2.5 Status dot

```css
.dot { width: 8px; height: 8px; border-radius: 50%; }
.dot.done { background: var(--success); }
.dot.running { background: var(--info); box-shadow: 0 0 0 3px rgba(14,165,233,.2); animation: pulse 2s infinite; }
.dot.error { background: var(--danger); }
.dot.aberta { background: var(--text-subtle); }
```

### 2.6 Buttons

| Variante | Bg | Texto | Hover |
|---|---|---|---|
| `primary` | --finza-blue | branco | --finza-blue-deep |
| `secondary` | branco + border --border | --text | bg --bg, border --text-subtle |
| `ghost` | transparent | --text-muted | bg --bg |
| `danger` | --danger | branco | #DC2626 |

Tamanhos: default (34px), `btn-sm` (28px).

### 2.7 Tabela

- Background do wrap: `card` dotted
- Thead: bg `#FAFAFC`, font-size 10px uppercase letter-spacing .08em
- Row height: 36px
- Hover row: bg `--surface-hover`
- Row "atrasada": box-shadow inset 3px 0 `--danger` na primeira td
- Row actions (✎ ✏ 🗑): aparecem em hover (opacity 0 → 1)

### 2.8 Modal (canônico dotted)

```css
.modal { background: var(--surface); border: 2px dotted var(--finza-blue);
         border-radius: var(--radius-lg); box-shadow: var(--shadow-lg); }
```

Tamanhos: default (720px), `.wide` (920px).

### 2.9 Command Palette (Cmd+K)

Overlay + box com border dotted + input grande + grupos + items focusable. Detalhe em [04-telas/COMMAND_PALETTE.md](../04-telas/COMMAND_PALETTE.md).

### 2.10 Toast

```css
.toast { background: var(--finza-dark); color: #fff; padding: 12px 16px;
         border-left: 3px solid var(--success | warning | danger); }
```

Bottom-right, max 4 stack, auto-fade após 2.6s.

### 2.11 Form

```css
.form-row { display: grid; grid-template-columns: 170px 1fr; gap: 16px; align-items: start; }
.form-row label { font-size: 12px; font-weight: 600; color: var(--text-muted); padding-top: 9px; }
.form-section { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: .14em;
                color: var(--finza-blue); padding-bottom: 6px; border-bottom: 1px dotted var(--finza-blue); }
```

#### Checkpills (multi-select)

```html
<div class="checkgroup">
  <label class="checkpill on"><input type="checkbox" checked> Read</label>
  <label class="checkpill"><input type="checkbox"> Edit</label>
</div>
```

#### Chipinput (tags com enter)

```html
<div class="chipinput">
  <span class="chip">finza <span class="x">×</span></span>
  <input type="text" placeholder="enter para adicionar">
</div>
```

### 2.12 Stream Viewer (Execuções)

```
┌──── stream-card (dotted) ────┐
│ ●running ◆ agent  sonnet [Stop]
│ Duração: 0:23  Tools: 4  …  │
│ ┌── input ──────────────┐   │
│ │ "Liste plataformas…"  │   │
│ └────────────────────────┘   │
└──────────────────────────────┘
┌──── stream-tl (timeline) ────┐
│ ⏵ Status started · sonnet …  │
│ Vou começar lendo…           │
│ ▸ Tool: Read /Docs/…  12ms   │
│   └─ result (collapsable)    │
│ ...                          │
│ ▮ (cursor pulsante)          │
└──────────────────────────────┘
```

Tokens chegam com fade-in (`opacity 0 → 1, 350ms`).

### 2.13 Kanban (Roadmap)

```css
.kanban { display: grid; grid-template-columns: repeat(6, minmax(220px, 1fr)); gap: 12px; }
.kcol { background: #FAFAFC; border: 1px solid var(--border); padding: 12px; }
.kcard { background: var(--surface); border: 1px solid var(--border); padding: 10px; cursor: pointer; }
.kcard:hover { box-shadow: var(--shadow-sm); border-color: var(--finza-blue-soft); }
```

### 2.14 Barchart inline (Dashboard)

```html
<div class="barchart">
  <div class="row"><span class="lab">alta</span><span class="bar"><span class="fill danger" style="width:85%"></span></span><span class="num">17</span></div>
  ...
</div>
```

Grid `100px 1fr 40px`, fill colorido por categoria.

---

## 3 · Componentes ausentes vs v1

| v1 (light Linear) | v2 (canônico Finza) |
|---|---|
| ~~`border: 1px solid #E8E8EC`~~ | **`border: 2px dotted #1A1AFF`** |
| ~~h1 28px peso 500~~ | **h1.ghost 42px peso 300 + .accent 700** |
| ~~Sidebar branca~~ | **Sidebar dark #0A0A2E** |
| ~~lucide-react icons~~ | **Glyphs Unicode** (◆◇◈⚡🔍📤▢🗓🛣👤⚙) |
| Skeleton shimmer | Mantido |
| Tooltip kbd light | Mantido + kbd dark na sidebar |

---

## 4 · Convenções de nome

- HTML: classes em kebab-case (`.card.compact`, `.btn-primary`, `.hero-dark`)
- Tokens: kebab-case com prefixo de família (`--finza-blue`, `--text-muted`)
- Componentes JS (V1 desenvolvimento real): PascalCase (`<Card>`, `<KpiCard>`, `<StreamViewer>`)

---

## 5 · Histórico

| Versão | Data | Mudança |
|---|---|---|
| v1 | 2026-05-20 | Componentes light Linear-style (descartado) |
| **v2** | **2026-05-21** | Volta aos componentes canônicos Finza. Cards dotted, hero-dark, eye, pill, banner, ghost h1. |
