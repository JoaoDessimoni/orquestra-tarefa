# Spec técnica — "Relatório IAs Finza · Apresentação" (export Claude Design)

Engenharia reversa de `relatorio.html` (7.700 linhas decodificadas) + `rel_290cc396.js` (motor de dados), `rel_7e66d913.js` (deck-stage), `rel_fe74dce9.js` (dc-runtime), `rel_ad7deb99.js` (React UMD), `rel_161abee8.js` (bundle FinzaDesignSystem). Objetivo: permitir reproduzir o deck de forma **idêntica**. Todos os valores abaixo são literais do arquivo.

---

## 0. Arquitetura do arquivo (camadas)

```
<html><head> <script src=dc-runtime (rel_fe74dce9)> </head>
<body><x-dc>
  <helmet>                         ← vira <sc-helmet>: estilos globais injetados no <head>
    <style> @font-face Inter/Outfit/JetBrains Mono (DS "fonts") </style>
    <style> :root tokens de cor do DS (HSL) </style>
    <style> DS global: fontes + cor + tipografia + forma + motion + dark + elementos </style>
    <script src=FinzaDesignSystem bundle (rel_161abee8)>   ← carregado, mas NENHUM componente é usado nos slides
    <script src=motor de dados (rel_290cc396)>             ← define window.FinzaEngine
    <script src=deck-stage (rel_7e66d913)>                  ← web component <deck-stage>
    <style> Phosphor icon font (woff2/woff/ttf/svg) + ~1.500 classes .ph-* </style>
    <link preconnect fonts.googleapis.com> <style> Inter 300–800 (Google Fonts, 7 subsets) </style>
    <style> html,body{margin:0;background:#0A0A2E;font-family:Inter,system-ui,sans-serif;-webkit-font-smoothing:antialiased}a{color:#1A1AFF}a:hover{color:#0F0F8C} </style>
  </helmet>
  <div> barra de progresso fixa (4px) </div>
  <x-import component-from-global-scope="deck-stage" width="1920" height="1080" fill="" hint-size="100%,100%">
     9 × <section data-label=… data-speaker-notes=… style=…>
  </x-import>
  <div ref=sweepRef> faixa de "sweep" azul da transição </div>
  <div ref=fRef> HUD superior direito: botão teclado + botão Filtros + painéis (atalhos, filtros, date-range) </div>
  <sc-if ovOpen> visão geral (grid de miniaturas) </sc-if>
  <sc-if toastOn> toast </sc-if>
  <script type="text/x-dc" data-dc-script> class Component extends DCLogic {…} </script>
</x-dc></body></html>
```

### 0.1 Linguagem de template (dc-runtime / Claude Design)
- Interpolação `{{ expr }}` em texto e atributos (inclusive dentro de `style="…"`).
- `<sc-for list="{{ arr }}" as="x" hint-placeholder-count="N">` = loop; `<sc-if value="{{ bool }}" hint-placeholder-val="{{ false }}">` = condicional (o `hint-*` só serve ao editor durante streaming).
- Eventos: `sc-camel-on-click="{{ fn }}"`, `sc-camel-on-mouse-enter`, `sc-camel-on-mouse-leave`, `sc-camel-on-change` (o prefixo `sc-camel-` é desfeito para camelCase React: `onClick`, `onMouseEnter`…). Atributos SVG também: `sc-camel-view-box` → `viewBox`, `sc-camel-preserve-aspect-ratio` → `preserveAspectRatio`.
- `style-hover="…"` = estilo aplicado no hover (equivalente a uma regra `:hover`). Ao portar para vanilla, converta em classe + `:hover`.
- `ref="{{ sweepRef }}"` = React ref.
- Lógica: `class Component extends DCLogic` com `state`, `setState`, `componentDidMount/DidUpdate/WillUnmount` e `renderVals()` → objeto plano que o template consome. React 18 UMD por baixo.
- Para reproduzir **sem** Claude Design: trocar por HTML estático + um `render()` vanilla que recalcula os valores e reescreve os nós (ou usar React direto). O motor de animação (seção 6) é 100% Web Animations API e funciona igual em vanilla.

---

## 1. Canvas, escala, fundos, paddings

### 1.1 Canvas
- Design size **1920 × 1080** (`<x-import … width="1920" height="1080" fill="">`).
- `deck-stage._fit()` escala o canvas com `transform: scale(s)`, `s = min(vw/W, vh/H)`, centralizado (letterbox). Com o atributo **`fill`** e o rail oculto (`rw === 0`), o canvas **estica para o aspecto da janela** (limitado entre 1.25 e 2.4) — o slide se adapta ao formato da tela em vez de letterbox:

```js
_fit() {
  if (!this._canvas) return;
  const stage = this._canvas.parentElement;
  if (this.hasAttribute('noscale')) { this._canvas.style.transform = 'none'; if (stage) stage.style.left = '0'; if (this._overlay) this._overlay.style.marginLeft = '0'; return; }
  const rw = this._railWidth();
  if (stage) stage.style.left = rw + 'px';
  if (this._overlay) this._overlay.style.marginLeft = (rw / 2) + 'px';
  const vw = window.innerWidth - rw;
  const vh = window.innerHeight;
  let W = this.designWidth, H = this.designHeight;
  const fill = this.hasAttribute('fill') && rw === 0;
  if (fill && vw > 0 && vh > 0) {
    const a = Math.max(1.25, Math.min(2.4, vw / vh));
    if (a >= W / H) W = Math.round(H * a); else H = Math.round(W / a);
  }
  this.toggleAttribute('data-filled', fill);
  this._canvas.style.width = W + 'px';
  this._canvas.style.height = H + 'px';
  const s = Math.min(vw / W, vh / H);
  this._canvas.style.transform = `scale(${s})`;
}
```
- `:host([fill]) { background: var(--deck-fill-bg, #000); }` — a cada troca de slide o Component faz `ds.style.setProperty('--deck-fill-bg', getComputedStyle(slide).backgroundColor)`, então a área de fora do canvas assume a cor do slide ativo (sem barras pretas).
- Slides empilhados: `::slotted(*){position:absolute!important;inset:0!important;width:100%!important;height:100%!important;box-sizing:border-box!important;overflow:hidden;opacity:0;pointer-events:none;visibility:hidden}` e `::slotted([data-deck-active]){opacity:1;pointer-events:auto;visibility:visible}`. Slides **não** desmontam — só ficam ocultos.
- Canvas: `background:#fff; box-shadow: 0 0 0 1.5px rgba(255,255,255,0.12)` (some com `data-filled`).

### 1.2 Dois tipos de fundo de slide (alternância escuro/claro)
| Tipo | Slides | `style` da `<section>` |
|---|---|---|
| **Escuro "hero"** (capa/fechamento) | 1 Capa, 9 Obrigado | `background:#0A0A2E;color:#FFFFFF;font-family:Inter,sans-serif;overflow:hidden` + layer de pontos `radial-gradient(#23235A 1.5px, transparent 1.5px)` `background-size:40px 40px` (div `position:absolute;inset:0`). Conteúdo posicionado em absoluto. |
| **Escuro conteúdo** | 2 Panorama, 5 Por que foi a humano, 6 Abrindo o balde | `background:#0A0A2E;color:#FFFFFF;font-family:Inter,sans-serif;padding:88px 120px 100px;box-sizing:border-box;display:flex;flex-direction:column;overflow:hidden` + layer `radial-gradient(#1C1C4E 1.5px, transparent 1.5px)` `background-size:32px 32px`. Filhos levam `position:relative` para ficar acima da layer. |
| **Claro pontilhado** | 3 Instâncias, 4 Evolução, 7 Clara, 8 Custos | `background-color:#F2F2F2;background-image:radial-gradient(#D8D8E5 1.5px, transparent 1.5px);background-size:32px 32px;color:#0A0A2E;font-family:Inter,sans-serif;padding:88px 120px 100px;box-sizing:border-box;display:flex;flex-direction:column;gap:20px` (Clara: `padding:72px 120px 72px` + `overflow:hidden`). |

Sequência de fundos: **E E C C E E C C E** (escuro/claro em pares).

### 1.3 Grade/padding
- Margem lateral fixa **120px** em todos os slides. Topo 88px (Clara 72px), base 100px (Clara 72px).
- Capa/Obrigado: eyebrow em `left:120px;top:96px;right:120px`; bloco título em `left:120px;top:300px` (Obrigado `top:280px`); rodapé autor `left:120px;bottom:96px`.
- Gaps recorrentes: 20px (slides claros), 24px (grids de cards), 44–48px (título → corpo em slides escuros: `margin-top:44px`/`48px`).

---

## 2. Paleta e tipografia

### 2.1 Observação crítica
O deck **não usa os tokens do DS** (`--primary #2f2ff2`, `--navy #0b0a34`…). Os tokens estão carregados (globais), mas os slides são escritos com hex **inline** de uma paleta própria "deck": azul **#1A1AFF** e navy **#0A0A2E**. Para reproduzir idêntico, use os hex abaixo, não os tokens HSL.

### 2.2 Paleta usada nos slides (frequência no código → papel)
| Hex | Usos | Papel |
|---|---|---|
| `#0A0A2E` | 96 | Navy: fundo dos slides escuros, texto principal nos claros, barra "Protocolos", cards escuros (rodapés KPI, tooltip, visão geral), cor da Clara em AG |
| `#FFFFFF` | 85 | Texto em escuro, fundo de cards claros, pílula ativa de toggle |
| `#1A1AFF` | 68 | Azul de marca do deck: "Resolvido pela IA", acurácia, palavra de destaque no h2 (slides claros), pílula de recorte, faixa ticker, botão Filtros, progresso, pulso central da capa, Esperanza |
| `#5C5C7A` | 52 | Texto secundário/label em claro, eyebrow em claro, toggle inativo |
| `#C8C8D4` | 51 | Texto secundário em escuro, eyebrow em escuro, palavra "fina" do título da capa, barra "não formalizados" |
| `#D8D8E5` | 36 | Pontos do fundo claro, bordas de inputs/kbd/botões |
| `#10B981` | 27 | Verde: Transferência, Clara (custos), "Já pagou", aprovados, ponto orbital |
| `#F2F2F7` | 25 | Fundo de `<kbd>`, hover de fechar |
| `#7A7AFF` | 22 | Lavanda: segunda cor de destaque (palavra "Finza" na capa, "." do Obrigado, Valentina, "Não disse o assunto", números do overview, acurácia no rodapé) |
| `#F59E0B` | 19 | Âmbar: Transbordo, "falha do bot", "Bot não resolveu", nota de rateio, "Sem categoria" |
| `#9C9CB4` | 19 | Palavra "fantasma" do h2 (peso 300), Tageador, texto desabilitado |
| `#23235A` | 16 | Pontos do fundo da capa, bordas de cards escuros, divisórias do tooltip, trilha de barra em escuro, anel externo da capa |
| `#F2F2F2` | 12 | Fundo slide claro, trilho de barras/toggles em card branco |
| `#E6E6EE` | 11 | Divisórias e eixo X (`border-bottom:2px solid #E6E6EE`), cor "sem dado" no funil |
| `#E8E8FF` | 8 | Fundo de pílula azul (acurácia mensal, chip de período), subtexto em card azul, pill Esperanza, banda do date-range |
| `#3A3A55` | 7 | Legenda sob número nos cards da Clara |
| `#EEF0F4` / `#B0B6C3` | 6/3 | Botão desabilitado (fundo/borda / texto) no date-range |
| `#0099FF` | 6 | Azul-claro: série "Resolvidos pela IA" nos gráficos colunas/linha |
| `#1C1C4E` | 5 | Pontos do fundo escuro de conteúdo, trilho das mini-barras no rodapé escuro |
| `#10103A` | 5 | Fundo de card escuro sobre slide escuro (slides 5 e 6) |
| `#047857` | 5 | Verde-tinta: % transferência, "formalizados com sucesso", aprovados |
| `#EF4444` | 4 | Vermelho: card "Encaminhamento", valor final da seta de encaminhamento, reprovados |
| `#33ADFF` | 4 | Azul-claro sobre navy: "Resolvidos" no tooltip, custo por protocolo, KPI "Custo total" |
| `#16164A` | 4 | Hover dos cards escuros (slide 6) |
| `#F2F2F8` | 3 | Caixa de info/placeholder "Só no recorte completo" |
| `#3A3A63` | 3 | Segmento "Outros", borda do toast |
| `#0F0F8C` | 3 | Hover do azul (a:hover, botão Filtros), 1ª barra do funil |
| `#FEE2E2` | 2 | Texto secundário dentro do card vermelho |
| `#F0F0FF` | 2 | Banda de hover da coluna nos gráficos |
| `#DC2828` / `#DC2626` / `#B91C1C` / `#FEF2F2` | — | Erro de data (borda), números reprovados, texto/fundo do aviso "Sem dados" |
| `#3A3A8C` | 2 | Anel médio da capa |
| `#0070C0` | 2 | Rótulo de valor da série azul-claro em fundo branco |
| `#FEF3C7` / `#92400E` | 1 | Pílula "falha do bot" (fundo/texto) |
| `#B45309` | 1 | % transbordo no card de instância |
| `#059669` | 1 | Palavra "formalização" no h2 do slide Clara |
| `#16163F` | 1 | Miniatura inativa na visão geral |
| `#F7F7FA` | 1 | Coluna de presets do date-range |
| `#EEEEFF` / `#4B4BD6` | 1 | Pill Valentina (fundo/texto) |
| `#C8C8F5` | 1 | (motor) barra "Turma" na formalização |
| `#8C8CFF` / `#B4B4FF` | 1 | Valor Esperanza / Valentina no tooltip de custo (versões claras sobre navy) |
| Escala do funil | — | `['#0F0F8C','#1A1AFF','#3A3AFF','#5C5CFF','#7A7AFF','#A8A8FF','#10B981']` |
| Sombras | — | `0 12px 32px rgba(10,10,46,.28)` (tooltips/painéis), `0 4px 12px rgba(10,10,46,.25)` (botões HUD), `0 4px 12px rgba(10,10,46,.3)` (toast) |
| Progresso | — | trilho `rgba(200,200,212,0.25)`, preenchimento `#1A1AFF` |
| Sweep | — | `linear-gradient(90deg,rgba(26,26,255,0) 0%,rgba(26,26,255,0.55) 70%,#1A1AFF 100%)` |

**Semântica fixa das séries (respeitar em todo gráfico):** Resolvido pela IA = `#1A1AFF` · Transbordo = `#F59E0B` · Transferência = `#10B981` · Protocolos = `#0A0A2E` · Resolvidos (comparativo) = `#0099FF`.

**Cor por agente** (`AG` no script):
```js
const AG = {
  Esperanza: { cor: '#1A1AFF', pbg: '#E8E8FF', pfg: '#1A1AFF', papel: 'cobrança' },
  Valentina: { cor: '#7A7AFF', pbg: '#EEEEFF', pfg: '#4B4BD6', papel: 'N1/SAC' },
  Clara: { cor: '#0A0A2E', pbg: '#E6E6EE', pfg: '#0A0A2E', papel: 'formalização' },
};
// no slide de custos (CAG) a Clara vira verde:
const CAG = [{ k: 'esp', n: 'Esperanza', cor: '#1A1AFF', agente: 'Esperanza' }, { k: 'val', n: 'Valentina', cor: '#7A7AFF', agente: 'Valentina' },
  { k: 'cla', n: 'Clara', cor: '#10B981', agente: 'Clara' }, { k: 'tag', n: 'Tageador Finza', cor: '#9C9CB4', agente: null }];
```

### 2.3 Tokens do DS carregados (referência, não usados nos slides)
`--primary #2f2ff2`, `--primary-hover #2525bd`, `--primary-pressed #1c1c8f`, `--background #f9fafb`, `--foreground #19193a`, `--secondary #edecfe`, `--muted #eef0f4`, `--muted-foreground #5e6675`, `--border #dde2ea`, `--success #29a36a`, `--warning #f59f0a`, `--destructive #dc2828`, `--info #0099ff`, pares `-soft/-ink` (success `#ebf9f3/#0b6138`, warning `#fef5e7/#7d5208`, destructive `#fceeee/#972a2a`, info `#dceeff/#1757a1`), disabled `#f2f2f4/#c0bfca/#e2e2e7`, `--navy #0b0a34`, escalas `--azul-50…900` (`#f6f6fe #eaeafe #d1d1fc #acacfa #7676f6 #4e4ef4 #2f2ff2 #2525bd #1c1c8f #141362`) e `--neutro-50…900` (`#f9f9fa #f2f2f4 #e2e2e7 #c0bfca #9493a6 #6d6c85 #4a4a69 #323154 #1f1e44 #0b0a34`). Motion: `--ease: cubic-bezier(0.25, 1, 0.5, 1)`, 150/200/250ms. Raio 10px. O deck reaproveita o **ease do DS** (`cubic-bezier(.25,1,.5,1)`) em todas as transições de hover/toggle, e usa `#EEF0F4`/`#DC2828` (=muted/destructive do DS) no date-range.

### 2.4 Fontes
- **Inter** é a única fonte dos slides (`font-family:Inter,sans-serif` na section). Pesos usados: **300** (palavra fantasma do título), 500, 600, **700**, **800** (números e palavra-chave). Carregada 2×: DS (400–700) + Google Fonts (300–800, subsets cyrillic-ext/cyrillic/greek-ext/greek/vietnamese/latin-ext/latin).
- **JetBrains Mono** (400/500/700): só no HUD — `<kbd>` (`font:600 12px/1 'JetBrains Mono',monospace`), datas do filtro, inputs `dd/mm/aaaa`, dias do calendário. Regra do DS: "dinheiro/data/ID em mono".
- **Outfit** (400–700): carregada pelo DS (para h1/h2/h3 via `--font-display`), mas **sobrescrita** porque todo h1/h2 do deck herda `font-family:Inter` da section e o DS aplica `font-weight:600` + `letter-spacing:-0.02em` no h1/h2/h3 — o deck redefine peso por `<span>`. Na prática: o deck renderiza em Inter. (Reproduzir: Inter apenas.)
- **Phosphor** (woff2 + woff + ttf + **SVG font** — o "SVG grande" é o formato SVG da fonte de ícones, `#Phosphor`). Classes `.ph.ph-*`. Ícones usados: `ph-lightning` (4), `ph-caret-left` (2), `ph-caret-right`, `ph-caret-down`, `ph-arrow-right`, `ph-calendar-blank`, `ph-info`, `ph-keyboard`, `ph-x`, e dinâmicos `ph-chart-bar`, `ph-stack`, `ph-chart-line`. Uso: `<i class="ph ph-lightning" style="font-size:24px;color:#7A7AFF" aria-hidden="true"></i>`. Para reproduzir: `@phosphor-icons/web@2.1.1` (regular) via unpkg/jsdelivr.
- Não há logo SVG: a marca é **texto** `◆ Finza`. Única imagem: foto do autor (`<img>` 96×96, círculo) no Obrigado.

### 2.5 Escala tipográfica (px no canvas 1920)
| Elemento | Tamanho | Peso | letter-spacing | line-height | Cor |
|---|---|---|---|---|---|
| h1 capa | 136 | 300 (palavras 1–2) / 800 (3–4) | -0.04em | 1 | #C8C8D4 / #FFFFFF / #7A7AFF |
| h1 Obrigado | 220 | 800 | -0.05em | 0.95 | #FFFFFF + "." #7A7AFF |
| h2 slide | 72 (Clara 64) | 300 + 800 | -0.03em | 1.05 | fantasma #9C9CB4; destaque #FFFFFF (escuro) / #1A1AFF (claro) |
| Eyebrow (cabeçalho) | 24 | 600 | 0.1em (capa 0.12em) uppercase | — | #C8C8D4 (escuro) / #5C5C7A (claro) |
| Label de card | 24 | 700 | 0.08em uppercase | — | #5C5C7A |
| KPI gigante | 112 / 128 | 800 | -0.05em | 0.9 | #0A0A2E / #1A1AFF |
| Sufixo % do KPI | 56 | 800 | — | — | mesma do número |
| KPI médio | 88 / 96 | 800 | -0.04em | 0.9 | |
| KPI pequeno | 52 / 56 / 64 | 800 | -0.04em | 1 | |
| Legenda forte | 30–34 | 700/800 | — | 1.15–1.2 | |
| Corpo/nota | 24 | 400–600 | — | 1.3–1.4 | #5C5C7A / #C8C8D4 |
| Subtítulo capa | 34 | 400 | — | — | #C8C8D4 |
| Ticker | 26 | 600 | — | — | #FFFFFF |
| HUD (fora do canvas, px reais) | 11–15 | 400–700 | .1em em labels | — | |

**Regra de piso: nada no slide abaixo de 24px** (exceto 20px em 2 notas). Tudo `font-variant-numeric:tabular-nums` em colunas numéricas.

---

## 3. Slide a slide

Cabeçalho padrão (todo slide de conteúdo):
```html
<div style="display:flex;justify-content:space-between;align-items:center;font-size:24px;font-weight:600;letter-spacing:0.1em;text-transform:uppercase;color:#5C5C7A">
  <span>03 · Instâncias</span>
  <span style="color:#1A1AFF;letter-spacing:0;text-transform:none;font-weight:700">◆ {{ recorteCurto }}</span>
</div>
```
(escuro: `color:#C8C8D4` e o ◆ em `#FFFFFF`, com `position:relative`). O lado direito sempre mostra **o recorte do filtro ativo** (ex.: `Todos os agentes · 01/06 a 21/10`).

Título padrão (h2 ghost + accent):
```html
<h2 data-a="1" style="margin:8px 0 0;font-size:72px;line-height:1.05;letter-spacing:-0.03em"><span style="font-weight:300;color:#9C9CB4">Protocolos e </span><span style="font-weight:800;color:#1A1AFF">o que a IA resolveu</span></h2>
```

### Slide 1 — `data-label="Capa"` · Ato 0 (abertura)
- Notes: "Relatório das IAs Finza: Esperanza, Valentina e Clara. Os números seguem o filtro aplicado (agente, cliente, canal e período)."
- Layout: fundo navy + pontos 40px. **Órbita animada** à direita (div 980×980 em `right:-120px;top:50%;margin-top:-490px`), texto à esquerda, **faixa ticker** azul 88px no rodapé.
- Órbita (SVG 980×980, `overflow:visible`):
```html
<circle cx="490" cy="490" r="460" fill="none" stroke="#23235A" stroke-width="2"></circle>
<g data-spin="90"><circle cx="490" cy="490" r="380" fill="none" stroke="#1A1AFF" stroke-width="2" stroke-dasharray="4 14"></circle><circle cx="490" cy="110" r="14" fill="#1A1AFF"></circle><circle cx="870" cy="490" r="8" fill="#7A7AFF"></circle></g>
<g data-spin="-60"><circle cx="490" cy="490" r="290" fill="none" stroke="#3A3A8C" stroke-width="2"></circle><circle cx="200" cy="490" r="11" fill="#FFFFFF"></circle><circle cx="695" cy="285" r="7" fill="#10B981"></circle></g>
<g data-spin="40"><circle cx="490" cy="490" r="200" fill="none" stroke="#1A1AFF" stroke-width="3" stroke-dasharray="120 40 20 40"></circle></g>
<circle data-pulse="1" cx="490" cy="490" r="120" fill="#1A1AFF"></circle>
```
  Centro: `{{ coverAg }}` 56px/800/-0.03em (ex. "3 IAs") + `{{ coverInst }}` 24px/600 `#E8E8FF` ("5 instâncias").
- Eyebrow: "Relatório dos agentes · Squad IAF" (24/600/0.12em/uppercase/#C8C8D4) ↔ "◆ Finza" (#FFF, 700, sem uppercase, `z-index:2`).
- Bloco (`top:300px;width:1040px;gap:40px`): pílula `{{ recorte }}` (24/600, branco sobre #1A1AFF, `border-radius:999px;padding:10px 24px`) → h1 "Relatório das **IAs** **Finza**" (4 `<span data-w>` com `column-gap:0.24em;row-gap:8px`) → subtítulo `{{ coverSub }}` 34px #C8C8D4 ("Esperanza, Valentina e Clara · todos os canais · apurado em 22/10/2026").
- Ticker: `<div data-ticker>` `display:flex;gap:64px;white-space:nowrap;font-size:26px;font-weight:600;padding-left:64px`, itens = KPIs do recorte intercalados com `◆`, **lista duplicada** (para loop `translateX(-50%)` sem costura).
- Animações: `data-a` (eyebrow, pílula, subtítulo) sobem 32px; `data-w` (palavras do h1) sobem 60% com blur 8px em cascata 90ms; spins/pulse/ticker em loop infinito.

### Slide 2 — `data-label="Panorama"` · Ato 1 (o quê: números gerais)
- Notes: definição de Acurácia/Encaminhamento + regra da Clara.
- Eyebrow "02 · Panorama". h2 "Indicadores **do período**" (destaque branco).
- Grid `repeat(4,minmax(0,1fr))`, gap 24, `margin-top:48px`, `flex:1`. 4 cards KPI altos (texto no rodapé com `margin-top:auto`):
  1. Volume (branco): `data-count={{pan.P}}` 112px #0A0A2E + "protocolos" + fonte.
  2. Resolvidos (branco): 112px **#1A1AFF** + "resolvidos pela IA".
  3. Acurácia (branco): 128px #1A1AFF + "%" 56px.
  4. Encaminhamento (**fundo #EF4444**, texto branco, label #FEE2E2): 128px + "%" + "foram a humano" + `{{ pan.encSrc }}`.
- Animações: cards em cascata `data-a` (70ms entre eles), contadores `data-count` 0→valor em 1300ms com ease-out cúbico.

### Slide 3 — `data-label="Números por instância"` · Ato 1
- Notes longas: cruzamento protocolo a protocolo da Clara (414 transferências; 328 analista; 73 IA; 75/903 contam).
- Eyebrow "03 · Instâncias". h2 "Números **por instância**" + legenda à direita (3 quadrados 22×22 r6: #1A1AFF Resolvido pela IA · #F59E0B Transbordo · #10B981 Transferência).
- Linha de cards por instância (`sc-for inst`, flex, gap 20, `max-width:640px` cada): faixa superior 8px na cor do agente; nome 32/800; pílula `{cliente} · {papel}` (cores `pbg/pfg`); `data-count` 52px "protocolos"; **barra empilhada 100%** 32px r10 (`data-gx`) com rótulos internos só se ≥12%; linhas Transbordo (% #B45309 32/800), Transferência (% #047857), Acurácia (36/800 #1A1AFF, `border-top:1px solid #E6E6EE`).
- Faixa "Total" navy r20 `padding:18px 32px` com 4 métricas inline (cores #F59E0B / #10B981 / #7A7AFF).
- Rodapé fonte 24px #5C5C7A.

### Slide 4 — `data-label="Evolução mensal"` · Ato 1 (tendência) — **gráfico interativo principal**
- Notes: "Alterne entre colunas, pilha e linha no próprio gráfico; passe o mouse num mês…".
- Eyebrow "04 · Evolução". h2 "Protocolos e **o que a IA resolveu**".
- Card branco r24 `padding:28px 40px 24px` com:
  - Barra de controles: legenda (troca conforme modo) + 2 **segmented controls** (granularidade Diário/Semanal/Mensal; modo Colunas/Pilha/Linha com ícones Phosphor).
  - Área do gráfico `data-chart` (detalhe na seção 4).
  - Eixo X: rótulo do período (30px/800 se ≤12 períodos, senão 22px) + pílula de acurácia (`#E8E8FF`/#1A1AFF, 24/700) por mês.
- Rodapé navy r24 em grid `auto 1fr 1fr 1fr`: "Encaminhamento · jul → out" com `e0 → e1` (64px; e0 #9C9CB4, seta 36/300, e1 **#EF4444**), mini-barras Transbordo/Transferência (14px r7 trilho #1C1C4E, `data-gx`, largura = valor×2), nota com pico.
- Nota: `{{ evoNote }} · passe o mouse num período para ver o detalhe`.

### Slide 5 — `data-label="Por que foi a humano"` · Ato 2 (por quê)
- Notes: fonte `ai_funnel_events`, 6.078 eventos em 4.616 protocolos, regras do filtro.
- Eyebrow "05 · Encaminhamento" ↔ "◆ {{ m5.head }}". h2 "Por que foi **a humano**".
- Grid `1.6fr 1fr` gap 24 `margin-top:44px`:
  - **Tabela-ranking** (card branco r24 `padding:32px 36px`): cabeçalho grid `40px 1fr 120px 110px` (# · Motivo registrado · Eventos · %) uppercase; linhas com rank, nome (+ pílula "falha do bot" `#FEF3C7/#92400E`), mini-barra 14px r7 (azul #1A1AFF ou âmbar se bot), valor 28/800 tabular, % 26/600. Top-5 em #0A0A2E/700; resto #9C9CB4/#5C5C7A/500. Estado vazio centralizado.
  - Coluna direita: card **#1A1AFF** "X% cliente pediu humano" (96px `data-dec="1"`), card **#10103A com borda 2px #F59E0B** "X% não é pedido do cliente" (número âmbar), linha "N protocolos · N eventos" (32px brancos).

### Slide 6 — `data-label="Abrindo o balde Solicitação"` · Ato 2 (drill-down)
- Notes: amostra de 1.378 protocolos com log; "Outros 7,8%".
- Eyebrow "06 · Cliente pediu humano" ↔ "◆ 100% = os {pH}% do slide 5 · {n} protocolos". h2 "Dos {pH}% que pediram humano, **o que queriam**".
- **Barra 100% horizontal** 64px r16 com 5 segmentos `data-gx` (38,3% #7A7AFF · 22,5% #1A1AFF · 16,6% #F59E0B · 14,4% #10B981 · 7,8% #3A3A63), % centralizado 24/800.
- 4 **cards de insight** escuros (seção 5.6): faixa 8px cor, `data-count` 88px `data-dec="1"` + "%" 40px, "≈ N protocolos", título 32/800, citação itálica 24px #C8C8D4 entre aspas, rodapé com `ph-lightning` + ação proposta ("Atalho para o meu contato", "2ª via e boleto PDF no bot", "Indicador de CSAT", "Baixa automática por comprovante"). Hover: `background:#16164A;border-color:<cor>` em 200ms ease DS.
- Linha "Outros 7,8% (≈ N): …" com quadrado 16px #3A3A63.

### Slide 7 — `data-label="Clara · formalização"` · Ato 3 (agente com métrica própria)
- Notes: raio-X da Clara (1.125 → 947 = 84,2% etc.).
- Eyebrow "07 · Clara" ↔ "◆ {{ claHead }}" (#0A0A2E). h2 64px "Clara na **formalização**" (destaque **#059669**).
- Linha 1: grid 3 colunas de cards brancos r24 `padding:22px 26px`: (a) Formalização — 2 números 56px (#0A0A2E / #047857) + barra 18px r9 `gap:3px` verde/cinza + frase "84,2% de aprovação…"; (b) Kits 90/48/40 (verde/#DC2626/#5C5C7A) + barra tripla; (c) Documentos 979/921 + barra. Cards (b)/(c) têm **placeholder** `#F2F2F8` "Só no recorte completo" quando há filtro.
- Linha 2: grid `1.9fr 1fr`:
  - **Funil interativo** (card branco): 7 etapas em grid `340px 1fr 90px` — nome, barra centralizada 40px r8 (largura proporcional a T.t, mín 12%, cor da escala do funil; texto branco, exceto etapa 6 em navy), conversão da etapa %. Hover numa etapa: as outras vão a `opacity:0.35`, a ativa a 800; caixa de info `#F2F2F8` com `ph-info` explica a etapa. `transition:width 250ms cubic-bezier(0.25,1,0.5,1)`.
  - **Motivos do encaminhamento** (card navy): total + "· N protocolos", 4 linhas com barra 12px r6 trilho #23235A (verde, "Sem categoria" âmbar), nota 20px.

### Slide 8 — `data-label="Custos"` · Ato 3 (custo)
- Notes: fonte BQ `s1_custos_ia.v_custos_por_agente`, D-2, câmbio.
- Eyebrow "08 · Custos" ↔ "◆ {{ cs.head }}". h2 "Custo de LLM **por agente**".
- Grid `1fr 440px`:
  - Card do gráfico (branco r24 `padding:24px 36px 20px`): título "Custo por período" + 3 segmented controls (Diário/Semanal/Mensal · US$/R$ · Pilha/Linha). Pilha de 4 séries (`#1A1AFF #7A7AFF #10B981 #9C9CB4`), linha com 4 paths. Tooltip 400px com cada agente, Total, Por protocolo (#33ADFF).
  - Coluna de KPIs (`sc-for cs.kpis`, flex:1 cada, r20, faixa lateral esquerda 8px na cor do agente): 1º "Custo total" navy com faixa #33ADFF; demais brancos. Valor 40px/800 `data-count data-dec="2"`, prefixo `US$`/`R$` 26/700.
- Rodapé navy: "Custo por protocolo" 44px #33ADFF + por agente (quadrado 16px na cor) + nota (âmbar quando há rateio).

### Slide 9 — `data-label="Obrigado"` · Fechamento
- Notes: "Agradecer e abrir para perguntas."
- Mesma órbita da capa (pontos levemente menores: r 12/7/10/6), centro "Squad IAF" 44/800.
- Eyebrow "Relatório das IAs · Encerramento" ↔ "◆ Finza". Pílula recorte. h1 "Obrigado" 220px + "." #7A7AFF (2 `data-w`). Parágrafo 44px/300 #C8C8D4 com trecho 800 branco: "Esperanza, Valentina e Clara **resolvendo mais a cada mês**. Perguntas?". Assinatura: foto 96px círculo `border:3px solid #1A1AFF` + "CRIADO POR" (24/600/0.12em) + nome 36/800.

---

## 4. Gráficos interativos (HTML/CSS + SVG, sem biblioteca)

### 4.1 Princípio de construção
- **Barras = `<div>` em CSS grid**, não SVG. Uma grade `grid-template-columns: repeat(N,minmax(0,1fr))` é repetida em **camadas sobrepostas** (`position:absolute;inset:0`), todas com o mesmo `gridCols`:
  1. camada de **bandas de hover** (fundo `#F0F0FF` na coluna ativa, r10 topo, `top:-12px;left:6%;right:6%`);
  2. camada das **barras** (colunas / pilha) ou o **SVG da linha** + camada de pontos;
  3. camada de **hit-areas** (`z-index:3`, `top:-12px`) com `mouseenter`/`mouseleave` e o **tooltip** dentro.
- Altura em %: `h = (valor / máx) * 82 + '%'` (H = 82 deixa 18% de folga para rótulos).
- Contêiner da plotagem: `position:relative;flex:1;min-height:0;border-bottom:2px solid #E6E6EE`.
- Eixo X: outra grade com o mesmo `gridCols` fora da plotagem.
- Adaptação por densidade (N = nº de períodos):
```js
const chart = { gridCols: `repeat(${N},minmax(0,1fr))`, showVals: N <= 12, showPills: N <= 12, showDots: N <= 45,
  barR: N > 40 ? '3px 3px 0 0' : '10px 10px 0 0', dotS: N > 20 ? '16px' : '24px', tickFs: N <= 12 ? '30px' : '22px', … };
const step = N <= 12 ? 1 : Math.ceil(N / (gran === 'dia' ? 10 : 11));   // rótulo a cada `step` colunas
```

### 4.2 Modo Colunas (slide 4)
Duas barras lado a lado por período (`width:38%;max-width:92px;gap:6%`): Protocolos `#0A0A2E` e Resolvidos `#0099FF`, valor acima (24/800, `data-pop`), barra `data-gy` (cresce de baixo).
```html
<div style="display:flex;align-items:flex-end;justify-content:center;gap:6%;opacity:{{ m.op }};transition:opacity 200ms cubic-bezier(.25,1,.5,1)">
  <div style="height:100%;width:38%;max-width:92px;display:flex;flex-direction:column;justify-content:flex-end;align-items:center;gap:8px"><span data-pop="1" style="font-size:24px;font-weight:800;color:#0A0A2E;white-space:nowrap">{{ m.Ptxt }}</span><div data-gy="1" style="width:100%;height:{{ m.hP }};background:#0A0A2E;border-radius:{{ barR }}"></div></div>
  <div …><span data-pop="1" style="…color:#0070C0">{{ m.Rtxt }}</span><div data-gy="1" style="width:100%;height:{{ m.hR }};background:#0099FF;border-radius:{{ barR }}"></div></div>
</div>
```

### 4.3 Modo Pilha
Uma barra por período (`width:72%;max-width:150px`, altura = protocolos), `overflow:hidden;display:flex;flex-direction:column-reverse` com 3 fatias em % da própria barra: `sR` (#1A1AFF, rótulo % interno se ≥18%), `sTb` (#F59E0B), `sTf` (#10B981). Custos usa o mesmo padrão com 4 fatias `s0..s3`.

### 4.4 Modo Linha (SVG)
SVG `viewBox="0 0 1000 300" preserveAspectRatio="none"` em `position:absolute;inset:0;width:100%;height:100%;overflow:visible`, `data-reveal` (revela da esquerda por clip-path). Áreas `data-fade` (opacity 0.07 navy / 0.22 azul-claro) + linhas `stroke-width 5/6`, `stroke-linecap/linejoin:round`, **`vector-effect="non-scaling-stroke"`** (traço não deforma com o `preserveAspectRatio=none`). Pontos em HTML por cima (não no SVG, para não deformar): `<i>` círculo 24px (16px se N>20) com `border:4px solid`, posicionado `left:50%;bottom:{{hP}};transform:translate(-50%,50%)`.

Pontos e curva suave (Catmull-Rom → Bézier, tensão 1/6):
```js
const smooth = (pts) => pts.map((p, i) => { if (!i) return 'M' + p[0] + ',' + p[1]; const p0 = pts[i - 2] || pts[i - 1], p1 = pts[i - 1], p3 = pts[i + 1] || p; const c1 = [p1[0] + (p[0] - p0[0]) / 6, p1[1] + (p[1] - p0[1]) / 6], c2 = [p[0] - (p3[0] - p1[0]) / 6, p[1] - (p3[1] - p1[1]) / 6]; return 'C' + c1.map((v) => v.toFixed(1)) + ' ' + c2.map((v) => v.toFixed(1)) + ' ' + p[0] + ',' + p[1]; }).join(' ');
const ptsP = months.map((m, i) => [+((i + 0.5) * 1000 / N).toFixed(1), +(300 - (m._P / mxR) * H * 3).toFixed(1)]);
const area = (pts) => smooth(pts) + ` L${pts[pts.length - 1][0]},300 L${pts[0][0]},300 Z`;
const ln = { dP: smooth(ptsP), dR: smooth(ptsR), aP: area(ptsP), aR: area(ptsR) };
```
(x no centro da coluna `(i+0.5)*1000/N`, y invertido sobre 300 com a mesma escala de 82%.)

### 4.5 Hover e tooltip
- Estado `hov` (índice) — `enter: () => this.state.hov !== i && this.setState({ hov: i })`, `hovOff` no `mouseleave`.
- Efeitos: coluna ativa ganha banda `#F0F0FF`; demais colunas `opacity:0.45` (períodos fora do recorte `0.3`), transição `opacity 200ms cubic-bezier(.25,1,.5,1)`.
- Tooltip navy 360px (custos 400px), lado inteligente: `tipPos: i < N / 2 ? 'left:calc(100% - 4px)' : 'right:calc(100% - 4px)'` (abre para dentro do gráfico).
```html
<div style="position:absolute;top:12px;{{ m.tipPos }};width:360px;background:#0A0A2E;color:#FFFFFF;border-radius:16px;padding:20px 24px;display:flex;flex-direction:column;gap:10px;box-shadow:0 12px 32px rgba(10,10,46,.28);pointer-events:none">
  <span style="font-size:24px;font-weight:800">{{ m.full }}</span>
  <span style="display:flex;justify-content:space-between;gap:16px;font-size:24px"><span style="color:#C8C8D4">Protocolos</span><span style="font-weight:800">{{ m.Ptxt }}</span></span>
  <span …><span style="color:#C8C8D4">Resolvidos</span><span style="font-weight:800;color:#33ADFF">{{ m.Rtxt }}</span></span>
  <span …>Transbordo … color:#F59E0B</span>
  <span …>Transferência … color:#10B981</span>
  <span style="…;border-top:1px solid #23235A;padding-top:10px"><span style="color:#C8C8D4">Acurácia</span><span style="font-weight:800">{{ m.ac }}</span></span>
</div>
```
- Título do tooltip: `MESF` ("Junho*", "Outubro*") no mensal; `perTitle` ("Semana 07/07–13/07", "21/10") nos demais.

### 4.6 Segmented control (toggle de modo/granularidade/moeda)
```html
<div style="display:flex;gap:4px;background:#F2F2F2;border-radius:14px;padding:4px">
  <button style="display:flex;align-items:center;gap:10px;border:0;border-radius:10px;padding:10px 20px;font:700 24px/1 Inter,sans-serif;cursor:pointer;background:{{ md.bg }};color:{{ md.fg }};transition:background-color 200ms cubic-bezier(.25,1,.5,1),color 200ms cubic-bezier(.25,1,.5,1)"><i class="ph ph-chart-bar" style="font-size:26px"></i><span>Colunas</span></button>
</div>
```
Ativo: `bg #FFFFFF / fg #1A1AFF`; inativo: `transparent / #5C5C7A`. Custos usa `padding:10px 16px`. Trocar modo/granularidade zera `hov` e dispara `replayChart()` (seção 6).

### 4.7 Painel de filtros (HUD fora do canvas, `position:fixed;top:14px;right:16px;z-index:1980`)
- Botão teclado (34px círculo, borda #D8D8E5, ícone `ph-keyboard`) + botão **Filtros** (pílula #1A1AFF, `font:600 14px/1 Inter`, `padding:9px 16px`, mostra `recorteCurto` em #E8E8FF peso 400 com ellipsis; hover #0F0F8C).
- Painel (460px, r16, sombra .28): grupos **Agente** (Todos/Esperanza/Valentina/Clara), **Cliente** (Todos/Blips/Finza), **Canal** (Todos/Proativo/Receptivo) como chips pílula (`border:1px solid; padding:8px 14px; font:600 13px/1 Inter`; ativo #1A1AFF/branco, inativo branco/#0A0A2E borda #D8D8E5) + botão **Período** (ícone `ph-calendar-blank`, datas em JetBrains Mono, chip do preset "Período completo"/"Junho"…, `ph-caret-down`) + aviso "Sem dados para este recorte" + "Limpar filtros".
- **Date-range picker** (720px): cabeçalho (← Filtros · "Selecionar período" · seleção mono), coluna de presets (`#F7F7FA`), **dois meses lado a lado** com setas (navegação limitada a jun–out), grid 7 colunas (D S T Q Q S S em mono 10px #9C9CB4), dia 34px com quadrado 32px r8 (início/fim #1A1AFF branco 700; intervalo com banda `#E8E8FF` em meia-célula via `linear-gradient(90deg,transparent 50%,#E8E8FF 50%)` nas pontas; prévia ao hover após o 1º clique; dias fora de 01/06–22/10 desabilitados #C8C8D4 `not-allowed`; último dia com dado sublinhado `inset 0 -2px 0 #1A1AFF`). Inputs "Início/Fim" com máscara `dd/mm/aaaa`, validação (borda #DC2828 + hint "Data inválida…" / "Fora do período com dados (01/06–22/10/2026)"), Cancelar/Aplicar.
```js
const maskDate = (v) => { const g = v.replace(/\D/g, '').slice(0, 8); return g.length > 4 ? g.slice(0, 2) + '/' + g.slice(2, 4) + '/' + g.slice(4) : g.length > 2 ? g.slice(0, 2) + '/' + g.slice(2) : g; };
const br2iso = (b) => { const m = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(b); if (!m) return null; const dt = new Date(+m[3], +m[2] - 1, +m[1]); if (dt.getDate() !== +m[1] || dt.getMonth() !== +m[2] - 1) return null; return m[3] + '-' + m[2] + '-' + m[1]; };
```
- Fecha ao clicar fora (`pointerdown` capturado, `composedPath().includes(fRef)`), ao trocar de slide e com Esc.
- **Todos os slides reagem ao filtro**: ao mudar `[agente, cliente, canal, ini, fim, moeda]`, todos os `data-count` vão ao valor final e o slide ativo **replaya** a entrada (`reset` + `play(active, 0)`).

### 4.8 Painel de atalhos (tecla `?`/`H`)
760px, 2 colunas `repeat(auto-fit,minmax(min(300px,100%),1fr))`, `<kbd style="font:600 12px/1 'JetBrains Mono',monospace;background:#F2F2F7;border:1px solid #D8D8E5;border-bottom-width:2px;border-radius:6px;padding:3px 6px;color:#0A0A2E">`. Seções: Navegação (→ ↓ Espaço PgDn / ← ↑ PgUp / Home R / End / 1–9,0), Tela e seletor (F, [, ], S, G/Esc), Painéis (P, L, ?/H, Esc).

### 4.9 Visão geral (G/Esc) e toast
- Overlay fixo navy, grid `repeat(auto-fill,minmax(min(240px,100%),1fr))`, miniaturas 16:9 r12 `border:2px dotted #1A1AFF` (hover borda branca), fundo `#1A1AFF` se atual senão `#16163F`, número 28/800 #7A7AFF + label.
- Toast: fixo `bottom:28px` centro, navy, `border:1px solid #3A3A63`, r10, `font:600 13px/1.3 Inter`, some em 1600ms (`flash()`).

---

## 5. Motor de dados (`window.FinzaEngine`, rel_290cc396.js)

### 5.1 Entrada de dados
Dados **embutidos como texto pipe-delimitado** dentro de template literals, parseados no load. Nada é buscado em rede.
- `INSTS` = 5 instâncias `{key, agente, cliente, short, desk?}`: `esp-blips`, `esp-finza`, `val-finza`, `cla-blips`(desk), `cla-finza`(desk).
- `BQ_RAW` diário: `inst|iso|protocolos|proativo|receptivo|sem_match|enc_pro|enc_rec`.
- `TORRE_RAW` diário: `inst|iso|transbordo|transferência` (a partir de 08/07).
- `CLARA_TF_RAW`: `inst|dia|proativo|receptivo` (transferências feitas pela Clara).
- Buckets mensais: `MOT` (motivos `[nome, 'tb'|'tf', eventos]`), `TAGS`, `DEPT`, `SENT`, `FORM`, `FORM_CICLO(_M)`, `RAIOX`.
- `COST[agente][mês]` = array de USD por dia (índice = dia−1); `FX[mês] = [taxa do dia 1, taxa dos demais]`.
- Constantes de corte: `TELE_START '2026-07-08'`, `BQ_END '2026-10-21'`, `COST_END '2026-10-20'`, `RANGE_MIN '2026-06-01'`, `RANGE_MAX '2026-10-22'`.
- No script do deck há ainda `CLA_FUN`, `CLA_MOT`, `MOT5_RAW` (mesmo formato, separados por espaço) parseados por:
```js
const parseCla = (raw) => raw.trim().split(/\s+/).map((l) => { const [k, d, ...v] = l.split('|'); return { k, d, v: v.map(Number) }; });
```
E agregados por filtro de chave + intervalo ISO (comparação de string `r.d >= a && r.d <= b`) com rateio de canal `x * E.chShare(k)`.

### 5.2 Indexação
```js
BQ_RAW.trim().split("\n").forEach((l) => {
  const [k, iso, p, pro, rec, sm, ep, er] = l.split("|");
  (DKEY[k] = DKEY[k] || {})[iso] = { p: +p, pro: +pro, rec: +rec, sm: +sm, thPro: +ep, thRec: +er };
});
TORRE_RAW.trim().split("\n").forEach((l) => { const [k, iso, tb, tf] = l.split("|"); (TK[k] = TK[k] || {})[iso] = { tb: +tb, tf: +tf }; });
```

### 5.3 Registro diário + agregação (núcleo)
```js
const shareOf = (k, pro, rec, sm, canal) => {
  const den = pro + rec + sm;
  if (!den) return canal === "proativo" ? MIX[k].pro : MIX[k].rec;   // fallback: mix do período todo
  return (canal === "proativo" ? pro : rec) / den;
};
function dayRec(k, iso, canal) {
  const o = DKEY[k] && DKEY[k][iso], t = TK[k] && TK[k][iso], tele = iso >= TELE_START;
  let p = 0, bq = 0, s = 1;
  if (o) {
    p = canal === "proativo" ? o.pro : canal === "receptivo" ? o.rec : o.p;
    bq = canal === "proativo" ? o.thPro : canal === "receptivo" ? o.thRec : o.thPro + o.thRec;
  }
  if (canal !== "todos") s = o ? shareOf(k, o.pro, o.rec, o.sm, canal) : shareOf(k, 0, 0, 0, canal);
  const desk = INFO[k].desk, ct = desk && CTF[k] && CTF[k][iso];
  const tb = desk ? 0 : tele && t ? t.tb * s : 0,
    tf = desk ? (ct ? (canal === "proativo" ? ct.pro : canal === "receptivo" ? ct.rec : ct.pro + ct.rec) : 0) : tele ? (t ? t.tf * s : 0) : bq;
  return { p, pro: o ? o.pro : 0, rec: o ? o.rec : 0, sm: o ? o.sm : 0, bq, tb, tf, pre: 0, enc: tb + tf, tele };
}
function aggRange(insts, ini, fim, canal) {
  const a = { P: 0, Pt: 0, TB: 0, TF: 0, PRE: 0, ENC: 0, BQ: 0, BQt: 0, pro: 0, rec: 0, sm: 0, Pall: 0 };
  const f = minS(fim, BQ_END);
  if (ini > f) return a;
  eachDate(ini, f).forEach((iso) => insts.forEach((k) => {
    const r = dayRec(k, iso, canal);
    a.P += r.p; a.BQ += r.bq; a.TB += r.tb; a.TF += r.tf; a.PRE += r.pre;
    a.pro += r.pro; a.rec += r.rec; a.sm += r.sm; a.Pall += r.pro + r.rec + r.sm; a.Pt += r.p; a.BQt += r.bq;
  }));
  a.ENC = a.TB + a.TF + a.PRE;
  return a;
}
```

### 5.4 Arredondamento que fecha 100% (maior resto)
```js
function roundParts(raw) {
  const target = Math.round(sum(raw)), fl = raw.map((v) => Math.floor(v));
  let rem = target - sum(fl);
  raw.map((v, i) => [v - Math.floor(v), i]).sort((a, b) => b[0] - a[0]).forEach(([, i]) => { if (rem > 0) { fl[i]++; rem--; } });
  return fl;
}
const pctParts = (total, parts) => (total ? roundParts(parts.map((v) => (v / total) * 100)) : parts.map(() => 0));
function compose(a) {
  const c = roundParts([a.TB, a.TF, a.PRE]), p = pctParts(a.P, [a.TB, a.TF, a.PRE]), enc = sum(p);
  return { cTB: c[0], cTF: c[1], cPRE: c[2], cENC: sum(c), pTB: p[0], pTF: p[1], pPRE: p[2], pENC: enc, pAC: a.P ? 100 - enc : 0 };
}
```
Garante transbordo% + transferência% = encaminhamento% e acurácia = 100 − encaminhamento (inteiros).

### 5.5 Períodos (dia / semana seg–dom / mês)
```js
function weekKey(iso) { const [y, m, d] = iso.split("-").map(Number); const dt = new Date(Date.UTC(y, m - 1, d)); dt.setUTCDate(dt.getUTCDate() - ((dt.getUTCDay() + 6) % 7)); return dt.toISOString().slice(0, 10); }
const bucketKey = (iso, g) => (g === "mes" ? iso.slice(0, 7) : g === "sem" ? weekKey(iso) : iso);
function periods(g, ini, fim) {
  const out = []; if (ini > fim) return out; let cur = null;
  eachDate(ini, fim).forEach((iso) => { const k = bucketKey(iso, g); if (!cur || cur.key !== k) { cur = { key: k, ini: iso, fim: iso }; out.push(cur); } cur.fim = iso; });
  return out;
}
```
`eachDate` itera strings ISO sem `Date` (evita fuso). Toda comparação de datas é **lexicográfica em ISO**.

### 5.6 Custo
```js
function costRange(ags, ini, fim, cur) {
  let tot = 0, dias = 0; const f = minS(fim, COST_END);
  if (ini > f) return { tot: 0, dias: 0 };
  eachDate(ini, f).forEach((iso) => { let v = 0; ags.forEach((ag) => (v += costDay(ag, iso) || 0)); if (cur === "BRL") v *= fxOf(iso); tot += v; dias++; });
  return { tot, dias };
}
```
No deck, com filtro de cliente/canal o custo de cada dia é **rateado pelos protocolos do dia** (`costOf` em `costSlide`), e o slide muda a nota para âmbar.

### 5.7 Estado de filtro
`E.S = { agente, cliente, canal, ini, fim, moeda, gran }` é sobrescrito a cada `data()` (`Object.assign(E.S, {...})`); `instMatch()` filtra INSTS por agente+cliente; `chShare(k)` dá a fração do canal no recorte.

### 5.8 Export
```js
window.FinzaEngine = { S, INSTS, INFO, MONTHS, BUCKETS, MOT, TAGS, DEPT, SENT, FORM, FORM_CICLO, FORM_CICLO_M,
  RANGE_MIN, RANGE_MAX, BQ_END, TELE_START, aggRange, compose, pctParts, roundParts, shareOf, bucketsIn, overlaps,
  minS, maxS, sum, intBR, iso2br, instMatch: instMatchS, chShare, periods, perTitle, COST, COST_END, costRange };
```
O Component espera o engine com `setInterval(…, 50)` e só então `forceUpdate()`; antes disso `renderVals()` devolve objetos vazios seguros.

### 5.9 Regras de honestidade dos dados (padrão do relatório)
- Cada slide declara a **fonte** no rodapé/notes (tabela qualificada, corte, data de apuração).
- Métricas sem quebra por dia (Clara: kits, documentos) só aparecem no **recorte completo** — com filtro viram `—` + placeholder "Só no recorte completo… Limpe os filtros para ver.".
- Asterisco em mês parcial/baseline (`Jun*`, `Out*`) e nota explicando.
- Formatação pt-BR: `br = n => Math.round(n).toLocaleString('pt-BR')`, decimais com vírgula, dinheiro `US$ 1.234,56` / `R$`, custo unitário com 3 casas se < 0,10.

---

## 6. Motor de animação (Web Animations API)

### 6.1 API de data-attributes
| Atributo | Efeito | Keyframes | Delay (após `base`) | Duração |
|---|---|---|---|---|
| `data-w` | palavra de título (h1) | `opacity 0, translateY(60%), blur(8px)` → normal | `200 + i*90` | 700 |
| `data-a` | bloco genérico (h2, cards, faixas) | `opacity 0, translateY(32px)` → normal | `80 + i*70` | 600 |
| `data-pop` | rótulo/ponto de gráfico | `opacity 0, scale .6` → `scale 1.04 @0.7` → `1` | `500 + min(i*50, 800)` | 600 |
| `data-gx` | barra horizontal | `scaleX(0)` → `scaleX(1)`, origin `left center` | `350 + i*50` | 900 |
| `data-gy` | barra vertical | `scaleY(0)` → `scaleY(1)`, origin `center bottom` | `300 + min(i*70, 800)` | 900 |
| `data-reveal` | SVG de linha | `clipPath inset(-40px 100% -40px 0)` → `inset(-40px 0% -40px 0)` | `200` | 1400 |
| `data-fade` | área sob a linha | `opacity 0` → atributo `opacity` | `600 + i*150` | 900 |
| `data-donut` | (suportado, não usado) | `strokeDasharray 0 100` → valor | `450 + i*160` | 900 |
| `data-count="N"` (+`data-dec="1|2"`) | contador numérico | 0 → N, ease-out cúbico `1-(1-p)^3`, `toLocaleString('pt-BR')` | `base + 250` | 1300 |
| `data-spin="graus"` | rotação infinita (origem 490 490) | 0 → ±360° | — | `abs(360/s)*6000` ms (90→24s, -60→36s, 40→54s) |
| `data-pulse` | respiração infinita | scale 1 → 1.08 → 1, `ease-in-out` | — | 2600 |
| `data-ticker` | faixa rolando | `translateX(0)` → `translateX(-50%)` | — | 40000 |
| `data-chart` | marca o contêiner que replaya ao trocar modo | — | — | — |

Easing de entrada: `const EASE = 'cubic-bezier(.2,.8,.2,1)'`, `fill: 'backwards'` (estado final é o estilo base → print/reduced-motion mostram tudo). `base = 120ms` na entrada de slide, `0` no replay por filtro.

### 6.2 Código (literal)
```js
const EASE = 'cubic-bezier(.2,.8,.2,1)';
activate(slide, index, prev) {
  const tok = this._tok = (this._tok || 0) + 1;
  this.active = slide;
  const ds = document.querySelector('deck-stage');
  if (ds) { if (!ds.hasAttribute('fill')) ds.setAttribute('fill', ''); ds.style.setProperty('--deck-fill-bg', getComputedStyle(slide).backgroundColor); }
  document.querySelectorAll('deck-stage > section').forEach((s) => this.reset(s));
  const sw = this.sweepRef.current;
  sw && sw.getAnimations().forEach((x) => x.cancel());
  if (this.reduced) return;
  const revisit = this.seen.has(slide);
  this.seen.add(slide);
  try {
    if (revisit) { this.loops(slide); return; }          // revisita: sem replay, só retoma loops
    if (prev >= 0) this.transition(slide, index > prev ? 1 : -1);
    this.play(slide, 120);
  } catch (err) { this.settle(slide); }
  setTimeout(() => { if (this._tok === tok) this.settle(slide); }, 3400);   // garante estado final
}
reset(s) {
  s.getAnimations({ subtree: true }).forEach((x) => { if (x._loop) x.pause(); else x.cancel(); });
  s.querySelectorAll('[data-count]').forEach((el) => this.finalCount(el));
}
settle(s) {
  s.getAnimations({ subtree: true }).forEach((x) => { if (x._loop) return; try { x.finish(); } catch (e) { x.cancel(); } });
  s.querySelectorAll('[data-count]').forEach((el) => this.finalCount(el));
}
transition(slide, dir) {
  slide.animate([{ opacity: 0, transform: `translateX(${dir * 90}px) scale(0.98)`, filter: 'blur(10px)' }, { opacity: 1, transform: 'none', filter: 'blur(0)' }], { duration: 650, easing: EASE });
  const sw = this.sweepRef.current;
  if (sw) sw.animate(dir > 0 ? [{ transform: 'translateX(-30vw)', opacity: 1 }, { transform: 'translateX(110vw)', opacity: 0.2 }] : [{ transform: 'translateX(110vw) scaleX(-1)', opacity: 1 }, { transform: 'translateX(-30vw) scaleX(-1)', opacity: 0.2 }], { duration: 620, easing: EASE });
}
loop(el, kf, o) {
  if (el._loop) { el._loop.play(); return; }
  el._loop = el.animate(kf, { iterations: Infinity, ...o });
  el._loop._loop = true;
}
play(slide, base) {
  const opt = (d, dur) => ({ duration: dur || 600, delay: base + d, easing: EASE, fill: 'backwards' });
  slide.querySelectorAll('[data-w]').forEach((el, i) => el.animate([{ opacity: 0, transform: 'translateY(60%)', filter: 'blur(8px)' }, { opacity: 1, transform: 'none', filter: 'blur(0)' }], opt(200 + i * 90, 700)));
  slide.querySelectorAll('[data-a]').forEach((el, i) => el.animate([{ opacity: 0, transform: 'translateY(32px)' }, { opacity: 1, transform: 'none' }], opt(80 + i * 70)));
  slide.querySelectorAll('[data-pop]').forEach((el, i) => el.animate([{ opacity: 0, scale: '0.6' }, { opacity: 1, scale: '1.04', offset: 0.7 }, { opacity: 1, scale: '1' }], opt(500 + Math.min(i * 50, 800), 600)));
  slide.querySelectorAll('[data-gx]').forEach((el, i) => { el.style.transformOrigin = 'left center'; el.animate([{ transform: 'scaleX(0)' }, { transform: 'scaleX(1)' }], opt(350 + i * 50, 900)); });
  slide.querySelectorAll('[data-gy]').forEach((el, i) => { el.style.transformOrigin = 'center bottom'; el.animate([{ transform: 'scaleY(0)' }, { transform: 'scaleY(1)' }], opt(300 + Math.min(i * 70, 800), 900)); });
  this.chartAnim(slide, base);
  slide.querySelectorAll('[data-donut]').forEach((el, i) => { const da = el.getAttribute('stroke-dasharray') || '0 100'; el.animate([{ strokeDasharray: '0 100' }, { strokeDasharray: da }], opt(450 + i * 160, 900)); });
  slide.querySelectorAll('[data-count]').forEach((el) => this.count(el, base + 250));
  this.loops(slide);
}
chartAnim(root, base) {
  const opt = (d, dur) => ({ duration: dur || 600, delay: base + d, easing: EASE, fill: 'backwards' });
  root.querySelectorAll('[data-reveal]').forEach((el) => el.animate([{ clipPath: 'inset(-40px 100% -40px 0)' }, { clipPath: 'inset(-40px 0% -40px 0)' }], opt(200, 1400)));
  root.querySelectorAll('[data-fade]').forEach((el, i) => el.animate([{ opacity: 0 }, { opacity: el.getAttribute('opacity') || 1 }], opt(600 + i * 150, 900)));
}
replayChart() {   // ao trocar modo/granularidade: só o gráfico, mais rápido
  const c = this.active && this.active.querySelector('[data-chart]');
  if (!c || this.reduced) return;
  const opt = (d, dur) => ({ duration: dur || 600, delay: d, easing: EASE, fill: 'backwards' });
  c.querySelectorAll('[data-gy]').forEach((el, i) => { el.style.transformOrigin = 'center bottom'; el.animate([{ transform: 'scaleY(0)' }, { transform: 'scaleY(1)' }], opt(Math.min(i * 60, 700), 800)); });
  c.querySelectorAll('[data-pop]').forEach((el, i) => el.animate([{ opacity: 0, scale: '0.6' }, { opacity: 1, scale: '1.04', offset: 0.7 }, { opacity: 1, scale: '1' }], opt(250 + Math.min(i * 50, 700), 500)));
  this.chartAnim(c, 0);
}
loops(slide) {
  slide.querySelectorAll('[data-pulse]').forEach((el) => { el.style.transformOrigin = 'center'; el.style.transformBox = 'fill-box'; this.loop(el, [{ transform: 'scale(1)' }, { transform: 'scale(1.08)' }, { transform: 'scale(1)' }], { duration: 2600, easing: 'ease-in-out' }); });
  slide.querySelectorAll('[data-spin]').forEach((el) => { const s = +el.dataset.spin; el.style.transformOrigin = '490px 490px'; this.loop(el, [{ transform: 'rotate(0deg)' }, { transform: `rotate(${s > 0 ? 360 : -360}deg)` }], { duration: Math.abs(360 / s) * 6000 }); });
  slide.querySelectorAll('[data-ticker]').forEach((el) => this.loop(el, [{ transform: 'translateX(0)' }, { transform: 'translateX(-50%)' }], { duration: 40000 }));
}
fmt(el, v) { const d = +(el.dataset.dec || 0); return v.toLocaleString('pt-BR', { minimumFractionDigits: d, maximumFractionDigits: d }); }
finalCount(el) { cancelAnimationFrame(el._raf); clearTimeout(el._to); const v = parseFloat(el.dataset.count); el.textContent = isNaN(v) ? '' : this.fmt(el, v); }
count(el, delay) {
  const t = parseFloat(el.dataset.count), dur = 1300;
  cancelAnimationFrame(el._raf); clearTimeout(el._to);
  if (isNaN(t) || document.hidden) { this.finalCount(el); return; }
  el.textContent = this.fmt(el, 0);
  el._to = setTimeout(() => {
    const st = performance.now();
    const step = (n) => { const p = Math.max(0, Math.min(1, (n - st) / dur)); el.textContent = this.fmt(el, t * (1 - Math.pow(1 - p, 3))); if (p < 1) el._raf = requestAnimationFrame(step); };
    el._raf = requestAnimationFrame(step);
  }, delay);
}
```

### 6.3 Ciclo de vida
- Escuta `slidechange` (CustomEvent do deck-stage, `detail: {index, previousIndex, total, slide, previousSlide, reason}`) → fecha filtros, atualiza `idx/total`, `activate()`.
- Bootstrap: `setInterval` 100ms até existir `deck-stage > section[data-deck-active]` **e** `window.FinzaEngine`, então `activate(a, i, -1)` (sem transição na 1ª).
- `visibilitychange` → `settle(active)` (aba voltou: nada fica no meio).
- `prefers-reduced-motion: reduce` → nenhuma animação (estado final direto).
- Primeira visita anima; **revisita não replaya** (`seen` WeakSet), só retoma os loops. Mudança de filtro replaya o slide ativo.
- Transição entre slides: o slide entra com `translateX(±90px) scale(.98) blur(10px)` → normal em 650ms, enquanto uma **faixa azul em gradiente (22vw, z-index 1700)** varre a tela de −30vw a 110vw (ou o inverso, espelhada, ao voltar) em 620ms.
- Barra de progresso fixa 4px no topo: `width: (idx+1)/total*100%`, `transition:width 600ms cubic-bezier(.2,.8,.2,1)`.

### 6.4 Teclado (Component, capturando `keydown` em fase de captura)
Ignora se foco em INPUT/TEXTAREA/SELECT/contentEditable ou com Meta/Ctrl/Alt. `F` tela cheia (toast "Tela cheia · F para sair"), `[`/`]`/`S` rail (via `postMessage({type:'__deck_rail_visible', on})`; bloqueado ≤640px), `G` visão geral, `P` filtros, `L` limpa filtros (toast "Filtros limpos"), `?`/`H` atalhos, `Esc` fecha na ordem date-range → filtros → atalhos → alterna visão geral. O deck-stage cuida de → ↓ Espaço PgDn / ← ↑ PgUp / Home / End / R / 1–9, 0=10, toque nas metades da tela; mostra overlay inferior central (pílula preta, 12px, some após 1800ms idle) e rail de miniaturas à esquerda (188px, redimensionável, persiste em localStorage).

---

## 7. Catálogo de componentes reutilizáveis (HTML literal)

### 7.1 Marca `◆` (no lugar de logo)
```html
<span style="color:#FFFFFF;letter-spacing:0;text-transform:none;font-weight:700">◆ Finza</span>   <!-- capa/obrigado -->
<span style="color:#1A1AFF;letter-spacing:0;text-transform:none;font-weight:700">◆ {{ recorteCurto }}</span>  <!-- slides claros -->
```
O losango também separa itens do ticker.

### 7.2 Pílula de recorte (capa/obrigado)
```html
<span data-a="1" style="align-self:flex-start;font-size:24px;font-weight:600;color:#FFFFFF;background:#1A1AFF;border-radius:999px;padding:10px 24px">01/06 a 21/10/2026</span>
```

### 7.3 Card KPI alto (slide 2)
```html
<div data-a="1" style="background:#FFFFFF;color:#0A0A2E;border-radius:24px;padding:40px 32px;display:flex;flex-direction:column;overflow:hidden;min-width:0">
  <span style="font-size:24px;font-weight:700;color:#5C5C7A;letter-spacing:0.08em;text-transform:uppercase">Acurácia</span>
  <div style="display:flex;flex-direction:column;gap:16px;margin-top:auto">
    <div style="display:flex;align-items:baseline;gap:8px"><span data-count="64" style="font-size:128px;font-weight:800;color:#1A1AFF;line-height:0.9;letter-spacing:-0.05em"></span><span style="font-size:56px;font-weight:800;color:#1A1AFF">%</span></div>
    <span style="font-size:34px;font-weight:700;line-height:1.15">dos protocolos</span>
    <span style="font-size:24px;line-height:1.35;color:#5C5C7A">100% − encaminhamento</span>
  </div>
</div>
```
Variante alerta: `background:#EF4444;color:#FFFFFF`, label/sub `#FEE2E2`.

### 7.4 Card de instância/agente com faixa de cor (slide 3)
Faixa `position:absolute;left:0;top:0;right:0;height:8px;background:{cor do agente}` + pílula `color:{pfg};background:{pbg};border-radius:999px;padding:6px 16px;font-size:24px;font-weight:700`. (código completo na seção 3/slide 3.)

### 7.5 Barra empilhada 100% (composição)
```html
<div data-gx="1" style="display:flex;height:32px;border-radius:10px;overflow:hidden;background:#F2F2F2;flex-shrink:0">
  <div style="width:64%;background:#1A1AFF;display:flex;align-items:center;justify-content:center;color:#FFFFFF;font-size:24px;font-weight:800;overflow:hidden">64%</div>
  <div style="width:20%;background:#F59E0B;…">20%</div>
  <div style="width:16%;background:#10B981;…">16%</div>
</div>
```
Variante segmentada com respiro: `height:18px;border-radius:9px;overflow:hidden;gap:3px` (slide 7). Variante grande: `height:64px;border-radius:16px` (slide 6).

### 7.6 Mini-barra de ranking (trilho + preenchimento)
```html
<div style="height:14px;border-radius:7px;background:#F2F2F2;overflow:hidden"><div data-gx="1" style="height:100%;width:72%;background:#1A1AFF;border-radius:7px"></div></div>
```
Em fundo escuro: trilho `#1C1C4E` (slide 4) ou `#23235A` com `height:12px;border-radius:6px` (slide 7).

### 7.7 Pílula de status
- "falha do bot": `font-size:24px;font-weight:700;color:#92400E;background:#FEF3C7;border-radius:999px;padding:4px 14px`.
- Acurácia do mês: `font-size:24px;font-weight:700;color:#1A1AFF;background:#E8E8FF;border-radius:999px;padding:4px 14px`.
- Chip de filtro: ver 4.7.

### 7.8 Legenda de série
```html
<span style="display:flex;align-items:center;gap:10px"><i style="width:22px;height:22px;border-radius:6px;background:#1A1AFF"></i>Resolvido pela IA</span>
```
(container `display:flex;gap:28px;font-size:24px;font-weight:700`; versão pequena 16×16 r4.)

### 7.9 Card de insight escuro com hover (slide 6)
```html
<div data-a="1" style="position:relative;background:#10103A;border:2px solid #23235A;border-radius:24px;padding:32px 28px 28px;display:flex;flex-direction:column;gap:14px;overflow:hidden;min-width:0;cursor:default;transition:background 200ms cubic-bezier(0.25,1,0.5,1),border-color 200ms cubic-bezier(0.25,1,0.5,1)" style-hover="background:#16164A;border-color:#7A7AFF">
  <div style="position:absolute;left:0;top:0;right:0;height:8px;background:#7A7AFF"></div>
  <div style="display:flex;align-items:baseline;gap:4px;color:#7A7AFF"><span data-count="38.3" data-dec="1" style="font-size:88px;font-weight:800;line-height:0.9;letter-spacing:-0.04em">38,3</span><span style="font-size:40px;font-weight:800">%</span></div>
  <span style="font-size:24px;font-weight:700;color:#C8C8D4;font-variant-numeric:tabular-nums">≈ 826 protocolos</span>
  <span style="font-size:32px;font-weight:800;line-height:1.15">Não disse o assunto</span>
  <span style="font-size:24px;line-height:1.35;font-style:italic;color:#C8C8D4">"Pode me passar para a [nome]"</span>
  <div style="margin-top:auto;display:flex;align-items:center;gap:10px;border-top:1px solid #23235A;padding-top:16px;font-size:24px;font-weight:700;color:#FFFFFF"><i class="ph ph-lightning" style="font-size:24px;color:#7A7AFF" aria-hidden="true"></i><span>Atalho para o meu contato</span></div>
</div>
```
Estrutura narrativa do card: **número → tamanho absoluto → nome do problema → voz do cliente (citação) → ação proposta (raio)**.

### 7.10 Card destaque sólido / card alerta com borda (slide 5)
- Sólido: `background:#1A1AFF;border-radius:24px;padding:32px;gap:14px`, número 96px, sub `#E8E8FF`.
- Alerta: `background:#10103A;border:2px solid #F59E0B;border-radius:24px;padding:32px`, número âmbar.

### 7.11 Faixa-resumo navy (rodapé de slide claro)
```html
<div data-a="1" style="background:#0A0A2E;color:#FFFFFF;border-radius:20px;padding:18px 32px;display:flex;justify-content:space-between;gap:24px;align-items:baseline;white-space:nowrap">
  <span style="font-size:28px;font-weight:800">Total</span>
  <span style="display:flex;align-items:baseline;gap:10px"><span data-count="12345" style="font-size:32px;font-weight:800"></span><span style="font-size:24px;color:#C8C8D4">protocolos</span></span>
  …
</div>
```
Variante "antes → depois" (slide 4): número 64px #9C9CB4 `→` (36/300) número 64px #EF4444.

### 7.12 Linha de funil interativa (slide 7)
```html
<div style="display:grid;grid-template-columns:340px minmax(0,1fr) 90px;align-items:center;gap:16px;cursor:default;opacity:{{ x.op }};transition:opacity 200ms cubic-bezier(0.25,1,0.5,1)" sc-camel-on-mouse-enter="{{ x.on }}">
  <span style="font-size:24px;font-weight:{{ x.fw }};white-space:nowrap">{{ x.n }}</span>
  <div style="display:flex;justify-content:center"><div data-gx="1" style="width:{{ x.w }};height:40px;border-radius:8px;background:{{ x.c }};display:flex;align-items:center;justify-content:center;font-size:24px;font-weight:800;color:{{ x.tc }};font-variant-numeric:tabular-nums;transition:width 250ms cubic-bezier(0.25,1,0.5,1)">{{ x.v }}</div></div>
  <span style="text-align:right;font-size:24px;font-weight:700;color:#5C5C7A;font-variant-numeric:tabular-nums">{{ x.cv }}</span>
</div>
<!-- caixa de detalhe -->
<div style="display:flex;align-items:center;gap:14px;background:#F2F2F8;border-radius:14px;padding:12px 18px;min-height:56px;box-sizing:border-box"><i class="ph ph-info" style="font-size:26px;color:#1A1AFF" aria-hidden="true"></i><span style="font-size:24px;line-height:1.3"><b>{{ cfDet.t }}</b> {{ cfDet.s }}</span></div>
```
Barras centralizadas (funil simétrico), largura `max(12, v/T*100)%`.

### 7.13 KPI lateral com faixa vertical (slide 8)
```html
<div data-a="1" style="position:relative;flex:1;min-height:0;background:#FFFFFF;color:#0A0A2E;border-radius:20px;padding:8px 22px 8px 30px;display:flex;flex-direction:column;justify-content:center;gap:2px;overflow:hidden">
  <div style="position:absolute;left:0;top:0;bottom:0;width:8px;background:#1A1AFF"></div>
  <div style="display:flex;justify-content:space-between;align-items:baseline;gap:12px;white-space:nowrap;min-width:0"><span style="font-size:24px;font-weight:700;letter-spacing:0.04em;text-transform:uppercase;color:#5C5C7A">Esperanza</span><span style="font-size:24px;color:#5C5C7A;overflow:hidden;text-overflow:ellipsis">78% · $42/dia</span></div>
  <span style="display:flex;align-items:baseline;gap:8px;white-space:nowrap"><span style="font-size:26px;font-weight:700;color:#5C5C7A">US$</span><span data-count="1234.56" data-dec="2" style="font-size:40px;font-weight:800;line-height:1.1;letter-spacing:-0.03em;font-variant-numeric:tabular-nums">1.234,56</span></span>
</div>
```

### 7.14 Placeholder "dado indisponível no recorte"
```html
<div style="flex:1;display:flex;flex-direction:column;justify-content:center;gap:6px;background:#F2F2F8;border-radius:14px;padding:16px 18px"><span style="font-size:24px;font-weight:700;color:#0A0A2E;line-height:1.25">Só no recorte completo</span><span style="font-size:24px;color:#5C5C7A;line-height:1.3">Vem do banco da Clara, sem quebra por dia ou marca. Limpe os filtros para ver.</span></div>
```
Estado vazio de gráfico/tabela: texto centralizado 28px/600 #9C9CB4 ("Sem custo apurado no recorte.").

### 7.15 Capa / fechamento (órbita + ticker)
Ver slide 1 e 9 — reutilizar o mesmo SVG; muda só o texto central e o h1. Ticker: lista de KPIs duplicada para loop contínuo.

### 7.16 Não há
Mockup de chat/WhatsApp, divisórias de ato dedicadas, tabelas `<table>` (tabelas são grids CSS), cards pontilhados `2px dotted` (só nas miniaturas da visão geral), componentes do FinzaDesignSystem.

---

## 8. Estrutura narrativa e padrões de texto

### 8.1 Arco (sem slides-divisória: o ato é marcado pelo **número do eyebrow** e pela alternância de fundo)
| Ato | Slides | Pergunta | Fundo |
|---|---|---|---|
| Abertura | 1 Capa | "de que estamos falando" (KPIs no ticker) | escuro hero |
| 1 · Quanto | 2 Panorama → 3 Instâncias → 4 Evolução | volume, acurácia, encaminhamento; quebra por instância; tendência | escuro → claro → claro |
| 2 · Por quê | 5 Por que foi a humano → 6 Abrindo o balde | causa registrada → causa real (drill-down do maior balde) + ação | escuro → escuro |
| 3 · Casos e custo | 7 Clara → 8 Custos | agente com métrica própria (funil); custo LLM e custo por protocolo | claro → claro |
| Fechamento | 9 Obrigado | mensagem-síntese + perguntas + autoria | escuro hero |

Ligações explícitas entre slides no texto: slide 6 diz "100% = os X% do slide 5"; slide 5 diz "O motivo real está no slide 6"; vazio do slide 5 diz "A Clara tem motivos próprios: veja o slide 7".

### 8.2 Padrões de título
- Eyebrow: `NN · Tema` (2 dígitos, ponto médio, caixa alta, tracking 0.1em) + `◆ recorte` à direita.
- h2 "ghost + accent": primeira parte peso **300 #9C9CB4** (contexto) + parte final peso **800** na cor de destaque (branco no escuro, #1A1AFF no claro, verde no slide da Clara). Ex.: "Indicadores **do período**", "Números **por instância**", "Protocolos e **o que a IA resolveu**", "Por que foi **a humano**", "Dos {pH}% que pediram humano, **o que queriam**", "Clara na **formalização**", "Custo de LLM **por agente**".
- h1 capa: palavras animadas uma a uma (`data-w`), as 2 primeiras finas/cinza, as 2 últimas pesadas (branco + lavanda).
- Fechamento: palavra única gigante + ponto colorido.

### 8.3 Voz
- Frases curtas, definições operacionais explícitas ("Acurácia = 100% − transbordo − transferência").
- Número absoluto + percentual juntos ("1.234 · 18%").
- Toda tela tem fonte/recorte em rodapé 24px #5C5C7A; detalhes metodológicos longos vão para **speaker notes** (`data-speaker-notes`), não para o slide.
- Instrução de interação no próprio slide: "· passe o mouse num período para ver o detalhe".
- Incerteza e limitações declaradas ("Jun é baseline", "Out até 21/10", "canal por rateio", "Âmbar = sem tag").

### 8.4 Speaker notes
Atributo `data-speaker-notes` em cada `<section>` (texto puro). O deck-stage também lê `<script type="application/json" id="speaker-notes">` e posta `{slideIndexChanged: N}` ao parent; neste export as notas vivem nos atributos.

---

## 9. Checklist para reproduzir idêntico
1. Canvas 1920×1080 com scale-to-fit **e** modo `fill` (aspecto 1.25–2.4) + fundo externo = cor do slide ativo.
2. Inter 300/400/500/600/700/800; JetBrains Mono só no HUD; Phosphor regular para ícones.
3. Paleta deck (#0A0A2E, #1A1AFF, #7A7AFF, #10B981, #F59E0B, #EF4444, #F2F2F2/#D8D8E5) — não os tokens do DS.
4. Fundos: navy + pontos #1C1C4E/32px (ou #23235A/40px no hero); claro #F2F2F2 + pontos #D8D8E5/32px. Padding 88/120/100.
5. Eyebrow `NN · Tema` + `◆ recorte`; h2 72px ghost(300 #9C9CB4)+accent(800).
6. Cards r24 (faixas r20, toggles r14/r10, barras r7–r16); sem sombra em card (sombra só em tooltip/painel).
7. Data-attributes de animação + motor da seção 6 (EASE `cubic-bezier(.2,.8,.2,1)`, hover/toggles `cubic-bezier(.25,1,.5,1)` 200ms).
8. Transição de slide: blur+slide 90px 650ms + sweep azul 620ms; barra de progresso 4px.
9. Gráficos em CSS grid com camadas (bandas, barras/SVG, hit-areas+tooltip), H=82%, densidade adaptativa, curva `smooth()`.
10. Motor de dados com strings pipe-delimitadas, agregação por intervalo ISO, `roundParts` para fechar 100%, filtros globais (agente/cliente/canal/período) que recalculam e replayam o slide.
11. HUD: Filtros + date-range de 2 meses + atalhos + visão geral (G) + toast.
