# Spec técnica — deck "Torre de Controle · Balanço do ciclo" (export Claude Design)

Engenharia reversa de `torre.html` (corpo linhas 500–1321) + runtime `torre_0680d671.js` (omelette starter `<deck-stage>`).
Objetivo: permitir reprodução **idêntica** (valores literais: px, ms, easing, hex).

---

## 0. Esqueleto do arquivo

```html
<!DOCTYPE html>
<html><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<script src="<runtime DC / React>"></script>          <!-- runtime do Claude Design (x-dc, sc-*, DCLogic) -->
<script src="<deck-stage.js>"></script>               <!-- omelette starter: web component <deck-stage> -->
</head>
<body>
<x-dc>
<helmet>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <style>/* @font-face Inter 300/400/500/600/700/800 + JetBrains Mono 500/700 (woff2 embutidos) */</style>
  <style>html,body{margin:0;background:#0A0A2E;font-family:Inter,system-ui,sans-serif;-webkit-font-smoothing:antialiased}a{color:#1A1AFF}a:hover{color:#0F0F8C}</style>
  <style>deck-stage > section:not([data-deck-active]) { display: none !important; }</style>
</helmet>

<!-- barra de progresso fixa -->
<div style="position:fixed;top:0;left:0;right:0;height:4px;z-index:1500;background:rgba(200,200,212,0.25);pointer-events:none">
  <div style="height:100%;background:#1A1AFF;transition:width 600ms cubic-bezier(.2,.8,.2,1);width:{{ progW }}"></div>
</div>

<x-import component-from-global-scope="deck-stage" width="1920" height="1080" fill="1" hint-size="100%,100%" data-uneditable="">
  <section data-label="..." data-speaker-notes="..." style="...">…</section>   <!-- ×10 -->
</x-import>

<div ref="{{ sweepRef }}" …></div>      <!-- faixa de "sweep" da transição -->
<div ref="{{ wipeRef }}"  …></div>      <!-- cortina azul de troca de ato -->
<sc-if value="{{ panelOpen }}"> … </sc-if>   <!-- painel lateral de detalhe -->
<sc-if value="{{ ovOpen }}"> … </sc-if>      <!-- overview (grade de slides) -->
</x-dc>
<script type="text/x-dc" data-dc-script=""> class Component extends DCLogic { … } </script>
</body></html>
```

Notas sobre a sintaxe do Claude Design (DC):
- `{{ expr }}` = binding para o objeto devolvido por `renderVals()`.
- `sc-camel-on-click`, `sc-camel-on-mouse-enter`, `sc-camel-on-mouse-leave` = handlers React (onClick/onMouseEnter/onMouseLeave).
- `sc-camel-view-box`, `sc-camel-preserve-aspect-ratio` = atributos SVG camelCase (`viewBox`, `preserveAspectRatio`).
- `style-hover="..."` = estilos aplicados no `:hover` (o runtime gera a regra).
- `<sc-for list="{{ arr }}" as="x">` = loop; `hint-placeholder-count` só para o editor.
- `<sc-if value="{{ bool }}">` = render condicional.
- `ref="{{ xRef }}"` = React ref.
- `data-om-slide-id` = id interno do editor (irrelevante para reproduzir).
- **Todo o estilo é inline** (nenhuma classe CSS). Para reproduzir fora do DC, converter para HTML+CSS+JS vanilla (ver §5.6).

Fontes: Inter (300, 400, 500, 600, 700, 800) é a única usada no corpo. JetBrains Mono 500/700 é carregada mas **não usada** em nenhum slide (0 ocorrências) — sobra do template.

---

## 1. Canvas, escala, fundos, paddings

### 1.1 Canvas e escala (deck-stage)
- Tamanho de design: **1920 × 1080** (`width="1920" height="1080"`).
- Atributo **`fill="1"`**: em vez de letterbox, o canvas é *esticado na dimensão sobrando* para casar com a razão de aspecto da viewport, e então escalado. Código literal (`_fit`):

```js
const vw = window.innerWidth - rw;      // rw = largura do rail de thumbs (0 em apresentação)
const vh = window.innerHeight;
let dw = this.designWidth, dh = this.designHeight;
if (this.hasAttribute('fill') && vw > 0 && vh > 0) {
  if (vw / vh >= dw / dh) dw = Math.round(dh * vw / vh); else dh = Math.round(dw * vh / vw);
}
this._canvas.style.width = dw + 'px';
this._canvas.style.height = dh + 'px';
const s = Math.min(vw / dw, vh / dh);
this._canvas.style.transform = `scale(${s})`;
```
  Consequência: em telas mais largas que 16:9 o slide fica >1920 de largura lógica; os layouts usam flex/grid com `minmax(0,1fr)` e paddings fixos, então "respiram" sem quebrar. Altura útil é sempre 1080 em telas ≥16:9.
- `:host` do deck-stage: `position:fixed; inset:0; background:#000`. `.stage` = flex centralizado. `.canvas`: `transform-origin:center center; background:#fff; box-shadow:0 0 0 1.5px rgba(255,255,255,0.12)`.
- Cada `<section>` é posicionada pelo componente: `position:absolute; inset:0; width:100%; height:100%; box-sizing:border-box; overflow:hidden; opacity:0; visibility:hidden; pointer-events:none`; a ativa (`[data-deck-active]`) recebe `opacity:1; visibility:visible; pointer-events:auto`. **Não definir position/size na section.**
- O helmet ainda força `deck-stage > section:not([data-deck-active]) { display:none !important }` (só a ativa existe no layout → animações só rodam na ativa).
- Texto: o deck-stage injeta `text-wrap: balance` em headings e `text-wrap: pretty` em p/li.

### 1.2 Os dois tipos de fundo

**A) Slide claro (padrão de conteúdo)** — usado em 02, 03, 05, 06, 07, 09:
```css
background-color:#F2F2F2;
background-image:radial-gradient(#D8D8E5 1.5px, transparent 1.5px);
background-size:32px 32px;
color:#0A0A2E;
font-family:Inter,sans-serif;
padding:88px 120px 100px;
box-sizing:border-box;
display:flex;flex-direction:column;
```
(02 acrescenta `gap:20px`.)

**B) Slide escuro de conteúdo** — 04 (Resultados) e 08 (A virada):
```css
background:#0A0A2E;color:#FFFFFF;font-family:Inter,sans-serif;
padding:88px 120px 100px;box-sizing:border-box;display:flex;flex-direction:column;overflow:hidden;
```
+ primeira filha = camada de pontos absoluta:
```html
<div style="position:absolute;inset:0;background-image:radial-gradient(#1C1C4E 1.5px, transparent 1.5px);background-size:32px 32px"></div>
```
Todos os filhos seguintes recebem `position:relative` para ficar acima da camada.

**C) Capa / Obrigado (escuro hero)** — 01 e 10: `background:#0A0A2E;color:#FFFFFF;font-family:Inter,sans-serif;overflow:hidden` **sem padding**; tudo posicionado absolutamente. Grade de pontos maior e mais clara:
```html
<div style="position:absolute;inset:0;background-image:radial-gradient(#23235A 1.5px, transparent 1.5px);background-size:40px 40px"></div>
```

### 1.3 Grid de espaçamento
- Margem lateral: **120px** (padding e `left:120px` na capa).
- Topo: **88px** (conteúdo) / **96px** (capa: header em `top:96px`).
- Base: **100px** (conteúdo) / capa: faixa ticker de 88px colada no fundo; obrigado: autor em `bottom:96px`.
- Distância header→título: `margin-top:32px` no h2 (02 usa `margin-top:8px` no wrapper + `gap:20px`).
- Título→conteúdo: 28–48px (`margin-top:48px` em 03/04, `40px` em 06/09, `32px` em 07, `28px` em 05).
- Gaps de grid de cards: 24px (3 e 4 colunas), 20px (prioridades), 8px (treemap), 32/40/56/88px entre colunas principais.

---

## 2. Paleta e tipografia

### 2.1 Paleta (todos os hex do corpo, com contagem e papel)

| Hex | Ocorr. | Papel |
|---|---|---|
| `#FFFFFF` | 101 | Cards no fundo claro; texto em fundos escuros/azuis; ponto/marcador SVG |
| `#1A1AFF` | 89 | **Azul Finza primário** — accent do título, números-herói, barras "roadmap", pílula de capa, barra de progresso, ticker, borda dotted, cortina wipe, borda do painel |
| `#0A0A2E` | 42 | **Navy** — fundo escuro, texto principal no claro, pílulas pretas (badges de total), barra "finalizadas", eixo 0 |
| `#5C5C7A` | 42 | Texto secundário/eyebrow no claro (header, labels uppercase, captions) |
| `#C8C8D4` | 31 | Texto secundário no escuro; parte "ghost" do h1 da capa; barra neutra ("em aberto", jul/ago); faixa da barra de progresso (rgba(200,200,212,.25)) |
| `#7A7AFF` | 27 | **Lavanda / azul claro** — accent no escuro ("out–dez", "."), números da faixa de KPIs, categoria 2, curva "Maturidade", número do overview |
| `#E8E8FF` | 21 | Azul muito claro — texto secundário em fundo azul, trilho de barras, tile/meta box claro, barra "baixas" |
| `#23235A` | 16 | Linhas/divisores no escuro, grade de pontos da capa, círculo externo do SVG |
| `#F2F2F2` | 13 | Fundo claro; trilho de barra; separador entre segmentos empilhados (border-top 3px) |
| `#9C9CB4` | 13 | **Ghost** — parte leve (300) dos títulos; labels do eixo Y |
| `#F59E0B` | 12 | **Âmbar** — "fora do plano / demais demandas" (com listras), destaque "80%", "~2×" |
| `#EF4444` | 11 | **Vermelho** — urgentes, correções, canceladas, curva "Incidentes" |
| `#E5E5EE` | 11 | Divisor de lista em card branco (border-top 1px) |
| `#D8D8E5` | 10 | Pontos da grade clara; borda inativa de card de legenda; divisor vertical; divisor no painel |
| `#0F0F8C` | 9 | Navy-azul — tile "Agentes de IA", texto de tiles claros, meta box do card azul, a:hover |
| `#4D4DFF` | 7 | Azul médio — tile "Ações", divisores dentro do card azul |
| `#047857` | 7 | Verde escuro — texto de pílula "✓ Resolvido"/"Meta batida", label "Depois" |
| `#10B981` | 6 | Verde — "41 dias", categoria 3 (Agentes), badge "Set: +89% vs ago" |
| `#1C1C4E` | 5 | Pontos da grade escura de conteúdo (04, 08); cor base do loop data-wave |
| `#E1E1EA` | 4 | Linhas tracejadas da grade do gráfico de colunas |
| `#D1FAE5` | 4 | Fundo pílula verde ("✓ Resolvido", "Meta batida") |
| `#FEF2F2` | 3 | Fundo box "Antes" |
| `#ECFDF5` | 3 | Fundo box "Depois" |
| `#D4D4FF` | 3 | Hover de tiles claros do treemap |
| `#B91C1C` | 3 | Texto label "Antes" |
| `#FCA5A5` | 2 | Texto rosado no SVG da virada ("Incidentes ↓", "jun–set · reativo") |
| `#3A3A8C` | 2 | Anel médio do SVG orbital |
| `#3A3A66` | 1 | Eixo X do SVG da virada |
| `#2E2E6E` | 1 | Borda do card do gráfico da virada |
| `#1A1A4A` | 1 | Meta box do card navy (prioridade 04) |
| `#16163F` | 1 | Fundo de thumb não-ativa no overview |
| `#0E0E36` | 1 | Fundo do card do gráfico da virada |

rgba usados: `rgba(200,200,212,0.25)` (trilho progresso), `rgba(10,10,46,0.45)` (scrim do painel), `rgba(26,26,255,0)`→`rgba(26,26,255,0.55)`→`#1A1AFF` (gradiente do sweep), `rgba(255,255,255,0.22)` (listra), `rgba(255,255,255,0.35)` (inset shadow do topo de barra), `rgba(255,255,255,0.55)` (pílula de % sobre âmbar).

Semântica de cor: azul = roadmap/plano/positivo; âmbar = fora do plano; vermelho = incidente/correção/cancelado/urgente; verde = resolvido/meta batida; lavanda = secundário/futuro; navy = total/peso.

### 2.2 Tipografia (Inter; tamanhos em px no canvas 1920×1080)

Regra de piso: **nenhum texto abaixo de 24px** nos slides (o painel/overview, que vivem fora do canvas escalado, usam 14–20px).

| Elemento | Tamanho | Peso | Line-height | Letter-spacing | Outros |
|---|---|---|---|---|---|
| H1 capa | 124 | 300 (ghost) / 800 (accent) | 1 | -0.04em | flex-wrap, column-gap .24em, row-gap 8px |
| H1 obrigado | 220 | 800 | 0.95 | -0.05em | column-gap .2em |
| H2 de slide | 72 | 300 ghost + 800 accent | 1.05 | -0.03em | margin 32px 0 0 |
| H2 da virada | 92 | 300 / 800 | 1.02 | -0.04em | flex column, gap 20px |
| Header/kicker do slide | 24 | 600 | — | 0.1em (capa 0.12em) | uppercase, #5C5C7A (claro) / #C8C8D4 (escuro) |
| Marca "◆ Squad IA" | 24 | 700 | — | 0 | sem uppercase; #1A1AFF (claro) / #FFFFFF (escuro) |
| Pílula capa | 24 | 600 | — | — | bg #1A1AFF, radius 999, padding 10px 24px |
| Subtítulo capa | 34 | 400 | — | — | #C8C8D4 |
| Ticker | 26 | 600 | — | — | branco sobre #1A1AFF |
| Número-herói (cards 04) | 128 | 800 | 0.9 | -0.05em | sufixo 48/800 |
| Número waffle-legenda (03) | 112 | 800 | 1 | -0.04em | |
| Número tile treemap | 160 / 88 / 80 / 72 / 56 / 48 | 800 | 0.9 | -0.05em (só 160) | |
| Data "Resolvido em" (02) | 76 | 800 | 0.9 | -0.04em | |
| Número KPI lateral | 72 / 80 / 64 | 800 | 0.95–1 | -0.04em | |
| Título de card (destaque 07) | 72 | 800 | 0.95 | -0.04em | text-wrap:balance |
| Título card prioridade | 44 | 800 | 1.05 | -0.02em | balance |
| Título card ponto de partida | 36 | 800 | — | — | |
| Números médios (badges, KPIs rodapé) | 40 / 44 / 48 / 56 | 800 | 1 | — | |
| Texto de destaque/frase | 36 / 34 / 32 / 28 | 700–800 | 1.15–1.25 | — | |
| Corpo | 26 | 400–600 | 1.25–1.3 | — | |
| Label uppercase de card | 24 | 700–800 | — | 0.06em–0.08em | uppercase, #5C5C7A |
| Caption | 24 | 400 | 1.35 | — | #5C5C7A / #C8C8D4 |

Padrão "ghost + accent" nos títulos: primeira parte `font-weight:300;color:#9C9CB4`, segunda `font-weight:800;color:#1A1AFF` (no claro) ou `#FFFFFF` (no escuro). Às vezes invertido: o número accent primeiro (03: "**80%** do trabalho…", accent em `#F59E0B`).

---

## 3. Slide a slide

Estrutura comum dos slides de conteúdo (cabeçalho):
```html
<div style="display:flex;justify-content:space-between;align-items:center;font-size:24px;font-weight:600;letter-spacing:0.1em;text-transform:uppercase;color:#5C5C7A">
  <span>NN · Ato X · Nome do ato</span>
  <span style="color:#1A1AFF;letter-spacing:0;text-transform:none;font-weight:700">◆ Squad IA</span>
</div>
<h2 data-a="1" style="margin:32px 0 0;font-size:72px;line-height:1.05;letter-spacing:-0.03em">
  <span style="font-weight:300;color:#9C9CB4">Parte ghost </span><span style="font-weight:800;color:#1A1AFF">parte accent</span>
</h2>
```
(No escuro: header `color:#C8C8D4`, marca `#FFFFFF`, ambos com `position:relative`.)

Animações "padrão" (detalhe em §5): `data-a` = fade+subida 32px, stagger 70ms; `data-pop` = pop de escala; `data-count` = contador; `data-gx` = barra cresce da esquerda.

---

### Slide 01 — `data-label="Capa"` (abertura)
- **Notes:** "Abrir com o contexto: ciclo jun–set foi de estabilização. Três atos: o incêndio, o que entregamos, o que vem agora."
- **Fundo:** hero escuro (§1.2 C), grade 40px `#23235A`.
- **Layout (absoluto):**
  - Ornamento orbital à direita: wrapper `position:absolute;right:-120px;top:50%;width:980px;height:980px;margin-top:-490px` (sangra 120px pela direita). SVG 980×980 (ver §4.10). Centro com texto "Squad IA" 44px/800 branco, `letter-spacing:-0.02em`, centrado via `left:490px;top:490px;transform:translate(-50%,-50%)`.
  - Header: `left:120px;top:96px;right:120px`, flex space-between, 24px/600, `letter-spacing:0.12em`, uppercase, `#C8C8D4`. Esquerda "Torre de Controle · Squad IA" (`data-a`); direita "◆ Squad IA" branco 700 sem uppercase, `position:relative;z-index:2` (fica acima do ornamento) (`data-a`).
  - Bloco de título: `left:120px;top:300px;width:1080px`, flex column `gap:40px`:
    1. Pílula azul "Balanço do ciclo · jun–set/2026" (`data-a`, `align-self:flex-start`).
    2. H1 124px com **cada palavra num `<span data-w="1">`**: "Torre de Controle" (300, `#C8C8D4`) + "Balanço do ciclo e plano para" (800, branco) + "out–dez" (800, `#7A7AFF`).
    3. Subtítulo 34px `#C8C8D4`: "Squad IA & Automação — Finza · Outubro/2026" (`data-a`).
  - Faixa ticker: `left:0;right:0;bottom:0;height:88px;background:#1A1AFF;overflow:hidden;display:flex;align-items:center`. Conteúdo `data-ticker` com `gap:64px;white-space:nowrap;font-size:26px;font-weight:600;color:#FFFFFF;padding-left:64px`. Itens separados por `<span>◆</span>`, **lista duplicada** (2×) para o loop `translateX(0 → -50%)` em 40s ser contínuo. Itens: "71 entregas do roadmap ◆ 11 frentes ◆ 324 story points ◆ 307 demandas abertas no trimestre ◆ 96% encerradas ◆ 3,69 d de cycle time ◆ 80% fora do plano ◆".
- **Animações:** palavras do H1 entram uma a uma (`data-w`: translateY 60% + blur 8px → nítido, 700ms, delay base+200+i·90ms); `data-a` em stagger 70ms; anéis giram (`data-spin` 90 / -60 / 40); núcleo pulsa (`data-pulse`, 2600ms); ticker rola 40s infinito.
- **Interações:** nenhuma.

---

### Slide 02 — `data-label="O ponto de partida"` (Ato 1 · O incêndio — primeiro do ato → dispara a **cortina de ato**)
- **Notes:** "Três frentes de incêndio, resolvidas em 41 dias: sistemas em 02/07, ferramentas em 07/07, agentes em 22/07. As 6 urgentes do roadmap foram todas de estabilização. Clique nos cards para o detalhe."
- **Fundo:** claro, `gap:20px`.
- **Header:** "02 · Ato 1 · O incêndio".
- **Linha de título** (flex space-between, `align-items:flex-end`, `gap:40px`, `margin-top:8px`): H2 "Começamos **apagando incêndio**" + **pílula KPI navy** (`data-pop`): `background:#0A0A2E;border-radius:999px;padding:12px 28px;gap:12px;align-items:baseline` com "41" (48px/800, `#10B981`, `data-count="41"`) + "dias para estabilizar" (24/600).
- **Grade de 3 cards clicáveis** (`flex:1;grid 3×minmax(0,1fr);gap:24px;min-height:0`). Cada card (Sistemas `#1A1AFF` / Ferramentas `#7A7AFF` / Agentes `#10B981`) — ver componente §4.6:
  - Faixa superior 8px na cor da frente.
  - Linha título: círculo numerado 48px, nome 36/800, pílula "✓ Resolvido" verde à direita.
  - "RESOLVIDO EM" + data 76px na cor (`data-pop`) | à direita "21 / 26 / 41" 56px (`data-count`) + "dias" 26/700 `#5C5C7A`.
  - Barra de progresso 18px (trilho `#F2F2F2`, radius 9) com preenchimento `data-gx` de **51.2% / 63.4% / 100.0%** (= dias/41).
  - Box "ANTES" (`#FEF2F2`, label `#B91C1C`) e "DEPOIS" (`#ECFDF5`, label `#047857`, texto 700), empurrados para baixo (`flex:1;justify-content:flex-end`).
  - Textos: Sistemas — antes "Torre instável e fora da cadência do MF" / depois "Estável e conciliada com o MF". Ferramentas — "Filtros quebrados e números divergentes" / "Números consistentes com as fontes". Agentes — "Timeout, dado defasado, métricas irreais" / "Estável, com dado atual e métricas reais".
- **Rodapé "Prioridade"** (`data-a`): card branco radius 20, `padding:16px 28px`, grid `260px minmax(0,1fr)` gap 32. Esquerda "PRIORIDADE" + "das 71 entregas do roadmap" (28/800). Direita: **barra proporcional segmentada** com `flex` = valor (6/26/31/8), cada coluna com número 40/800 colorido (`data-count`) + rótulo 24/700, e abaixo barra 34px radius 10 (`data-gx`) com % dentro: urgentes `#EF4444` 8% · altas `#1A1AFF` 37% · médias `#7A7AFF` 44% · baixas `#E8E8FF` (texto `#0A0A2E`) 11%. Extremos têm `min-width:140px` para caber o rótulo.
- **Interações:** clique em cada card → painel lateral com `PANELS.s_sis` / `s_fer` / `s_ag` (ver §5.4). Hover: `transform:translateY(-4px)` com `transition:transform 250ms`.

---

### Slide 03 — `data-label="O tamanho do esforço"` (Ato 1)
- **Notes:** "Cada quadrado é uma demanda finalizada. Só 55 de 278 eram do roadmap. Passe o mouse na legenda para destacar."
- **Header:** "03 · Ato 1 · O incêndio". **H2:** "**80%** (800, `#F59E0B`) do trabalho veio de fora do plano (300, `#9C9CB4`)".
- **Layout:** grid `620px minmax(0,1fr)`, `gap:88px`, `margin-top:48px`, `align-items:center`.
- **Esquerda — waffle** (`data-a`): card branco `border:2px dotted #1A1AFF;border-radius:16px;padding:32px;gap:20px`; grade `repeat(20,1fr)` gap 5px com **278 células** (`data-cell`, `aspect-ratio:1;border-radius:6px`), as 55 primeiras `#1A1AFF`, as 223 seguintes `#F59E0B`; `opacity` ligada ao hover (`transition:opacity 250ms`). Legenda 24px `#5C5C7A`: "1 quadrado = 1 demanda finalizada · 278 no total".
- **Direita** (flex column gap 32):
  1. Card-legenda "55" (112px/800 `#1A1AFF`, `data-count`) + "Roadmap da Torre" (32/700) + "20% das finalizadas · o plano seguiu andando" (26 `#5C5C7A`). Grid `auto minmax(0,1fr)` gap 32, `padding:28px 32px;radius 16`, `border:2px solid {{ bdR }}` (transição 250ms).
  2. Card-legenda "223" (`#F59E0B`) + "Fora do escopo planejado" + "Sustentação, incidentes, avulsas e repriorizações".
  3. Barra empilhada "307 DEMANDAS ABERTAS NO TRIMESTRE" (label 24/700, 0.08em, uppercase): altura 56px radius 10 overflow hidden: `flex:278` `#0A0A2E` "278 finalizadas" (padding-left 20) · `flex:12` `#C8C8D4` "12" · `flex:17` `#EF4444` "17" — todos `data-gx`. Legenda abaixo à direita (gap 32): "12 em aberto" "17 canceladas".
  4. Frase de fechamento 36/700 lh 1.25: "Absorvemos sustentação e repriorizações sem parar o roadmap."
- **Animações:** células entram em cascata `scale(0.2)→1` + fade, 420ms, delay 250+i·6ms (278 células ≈ 1,9s de onda); contadores; barras.
- **Interações:** `mouseenter` no card 55 → `slice='r'`: borda vira `#1A1AFF` e células âmbar caem para `opacity:0.15`; no card 223 → `slice='o'`: borda `#F59E0B`, células azuis a 0.15. `mouseleave` → tudo volta (opacity 1, borda `#D8D8E5`).

---

### Slide 04 — `data-label="Resultados do ciclo"` (Ato 2 · O que entregamos — primeiro do ato → **cortina de ato**)
- **Notes:** "Quatro números. Cycle time: meta batida por 0,01 d — se perguntarem, o argumento forte é estabilidade sob volume."
- **Fundo:** escuro de conteúdo (§1.2 B). **Header:** "04 · Ato 2 · O que entregamos". **H2:** "Resultados em (300 `#9C9CB4`) **quatro números** (800 branco)".
- **Grade 4 KPI cards** (`flex:1;grid 4×;gap:24px;margin-top:48px`). Card (§4.5): branco, radius 24, `padding:40px 32px`, flex column; label uppercase no topo; bloco inferior `margin-top:auto` gap 16: número 128px `#1A1AFF` + sufixo 48px, frase 34/700, caption 24 `#5C5C7A`.
  1. ROADMAP — 71 — "entregas do roadmap concluídas" — "Itens da Torre entregues entre 11/06 e 01/10".
  2. CYCLE TIME + pílula verde "Meta batida" — `3,69` (`data-count="3.69" data-dec="2"`) + "d" — "mediana do início à entrega" — "Meta de 3,7 d · 202 demandas medidas".
  3. ROADMAP — 100 + "%" — "do roadmap entregue" — "Todos os itens previstos para o ciclo".
  4. **Card invertido azul** (`background:#1A1AFF`, textos brancos, label/caption `#E8E8FF`): VOLUME — 307 — "demandas abertas no trimestre" — "jul 73 · ago 107 · set 127".
- **Faixa de KPIs secundários** (`data-a`): grid 5 colunas, `margin-top:28px;border-top:1px solid #23235A;padding-top:24px`. Cada item: número 44/800 `#7A7AFF` (`data-count`) + rótulo 24 `#C8C8D4`: 324 story points roadmap · 953 SP no trimestre · 50 melhorias · 21 correções · 56 interações c/ negócio.
- **Interações:** nenhuma.

---

### Slide 05 — `data-label="Linha do tempo"` (Ato 2)
- **Notes:** "Todas as demandas finalizadas no Quimera por mês de entrega, com a fatia do roadmap embaixo. O roadmap avançou todo mês; setembro quase dobrou o volume (+89% sobre agosto). Jun está somado em jul."
- **Header:** "05 · Ato 2 · O que entregamos". **H2:** "Entregas **mês a mês**".
- **Layout:** grid `minmax(0,1fr) 440px`, gap 32, `margin-top:28px`.
- **Esquerda — gráfico de colunas empilhadas** (card branco dotted, radius 24, `padding:28px 36px 20px`, gap 12):
  - Topo: frase 28/800 (max-width 640) "O roadmap avançou todo mês, mesmo com 3 em cada 4 entregas vindo de fora do plano." + legenda (quadrados 22px radius 5: `#1A1AFF` "Roadmap da Torre"; âmbar listrado "Demais demandas").
  - Linha 2: caption "Demais: sustentação, incidentes, avulsas e repriorizações" + **pílula dinâmica** (`transition:background 200ms, color 200ms`) com `{{ segLabel }}`: default "Passe o mouse nas colunas" (bg `#F2F2F2`, fg `#5C5C7A`).
  - Área do gráfico `height:456px`; eixo em sub-área `height:400px` com 5 gridlines absolutas em `bottom:400/300/200/100/0px` (`transform:translateY(50%)`), rótulo 44px largura alinhado à direita 24px `#9C9CB4` (140/105/70/35/0), linha `border-top:2px dashed #E1E1EA`; a linha 0 é `3px solid #0A0A2E`. **Escala: 400px = 140 demandas → 2,857 px/demanda.**
  - Colunas: grid 3 colunas `left:56px`. Cada coluna: pílula total navy (`data-pop`, 44px/800 `data-count` + "entregas" 24 `#C8C8D4`, `margin-bottom:14px`) sobre a pilha de largura 62%:
    - segmento superior "demais" âmbar listrado (`data-rise`, `data-stripe`), radius `14px 14px 0 0`, `box-shadow:inset 0 3px 0 rgba(255,255,255,0.35)`, número 40/800 + pílula % (`background:rgba(255,255,255,0.55)`), hover `filter:brightness(1.08)`;
    - segmento inferior "roadmap" `#1A1AFF` com `border-top:3px solid #F2F2F2` (separador), número 36/800 + % `#E8E8FF`, hover `brightness(1.2)`.
    - Alturas: jul demais 129px (45, 63%) / roadmap 74px (26, 37%) — total 71; ago 170px (62, 89%) / 30px (8, 11%, fonte 24) — total 70; set 294px (103, 78%) / 83px (29, 22%) — total 132.
  - Badge verde absoluto `left:72px;top:6px` "Set: +89% vs ago" (`#10B981`, radius 12, padding 8px 16px, 24/800, `data-pop`).
  - Eixo X: rótulos "jul / ago / set" 32/800 + sub 24 `#5C5C7A` ("inclui jun", "menor fatia do roadmap", "pico de volume").
- **Direita** (coluna gap 12):
  1. Card navy: "273" 72px (`data-count`) "demandas entregues no trimestre"; barra 30px gap 3px `flex:63 #7A7AFF` + `flex:210` âmbar listrado; legenda "63 roadmap / 210 demais".
  2. Card branco dotted: "63" 72px azul + "· 23%" 36/800 azul; "do roadmap da Torre"; mini-colunas `data-gy` (alturas 36/11/40px, `#1A1AFF`, radius `6px 6px 0 0`) com 26 / 8 / 29.
  3. Card branco dotted (`flex:1`): "~2×" 64/800 âmbar + "Set: quase 2× o volume de jul e ago"; 3 barras horizontais (grid `52px 1fr 52px`, barra 12px radius 4, `data-gx`): jul 54% `#C8C8D4` 71 · ago 53% `#C8C8D4` 70 · set 100% `#F59E0B` 132 (set em 800).
- **Animações:** colunas sobem por *clip-path* (`data-rise`): primeiro o roadmap (base) de cada mês, depois o "demais" em cima (+650ms); listras deslizam infinito (1600ms); pílulas de total fazem pop.
- **Interações:** hover em cada segmento → `seg` = julr/juld/agor/agod/setr/setd; a pílula mostra `SEG_LBL[seg]` (ex.: "Set · Demais: 103 de 132 (78%)"), fundo azul+texto branco (roadmap) ou âmbar+texto navy (demais). `mouseleave` → volta ao default.

---

### Slide 06 — `data-label="Entregas por frente"` (Ato 2)
- **Notes:** "Dashboard concentra 31% das entregas. Atenção: a soma por executor fecha em 57, não em 71 — algumas entregas não têm dev atribuído. Clique numa frente para detalhe."
- **Header:** "06 · Ato 2 · O que entregamos". **H2:** "71 entregas em **11 frentes**".
- **Layout:** grid `minmax(0,1fr) 500px`, gap 40, `margin-top:40px`.
- **Esquerda — treemap manual** com flex aninhado (`gap:8px`, os `flex` = contagens). Todos os tiles `data-pop` + clicáveis, radius 14:
  - Dashboard `flex:22` `#1A1AFF` padding 28: "Dashboard" 32/700, "22" **160px**/800 lh .9 ls -0.05em, "31% das entregas · 9 voltas" 26 `#E8E8FF`. Hover `brightness(1.15)` (transition filter 200ms).
  - Bloco `flex:49`: coluna `flex:17` [Agentes de IA `flex:9` `#0F0F8C` (28/700, 88px) hover brightness 1.25; Ações `flex:8` `#4D4DFF` (80px) brightness 1.15] + bloco `flex:32`: coluna `flex:14` [Configurações 7 `#7A7AFF` (26/700, 72px) ; "Régua · 6 voltas" 7 `#7A7AFF`] + coluna `flex:18`: linha [Gestão de Carteira 5 `flex:5` / Dados/ Infra 4 `flex:4` — `#E8E8FF`, texto `#0F0F8C`, `border:2px dotted #1A1AFF`, hover bg `#D4D4FF`] + linha [Filtros 4 `#E8E8FF` ; "Integra- ções" 3 branco dotted (hover `#E8E8FF`) ; coluna flex:2 com "Campanha 1" e "Custo 1" — **texto vertical** `writing-mode:vertical-rl;transform:rotate(180deg)`].
  - Lógica de cor por grandeza: maior = azul primário; 7–9 = navy-azul/azul médio/lavanda; 4–5 = azul claro dotted; ≤3 = branco dotted.
- **Direita** (coluna gap 16):
  1. Card branco radius 20 padding 28: "TIPO DE ENTREGA"; 2 colunas: "50" 72px `#1A1AFF` melhorias | "21" 72px `#EF4444` correções (com `border-left:1px solid #D8D8E5;padding-left:16px`); barra 10px gap 4: `flex:50` azul, `flex:21` vermelho (`data-gx`).
  2. Card "POR EXECUTOR": linhas nome (24/600) + "29 demandas" (número 800 azul, "demandas" 500 `#5C5C7A`); barra 10px trilho `#E8E8FF` preenchimento azul `data-gx`: Leandro 100% (29), Marcos 79% (23), João Pedro 17% (5).
  3. Card navy `margin-top:auto`: "ESFORÇO" + "324" 80px (`data-count`) + "story points entregues".
- **Interações:** clique em tile → painel `PANELS.f_*` (f_dash, f_ag, f_acoes, f_conf, f_regua, f_cart, f_dados, f_filt, f_integ, f_camp, f_custo).

---

### Slide 07 — `data-label="Visibilidade, governança e custo"` (Ato 2)
- **Notes:** "O negócio passou a enxergar a operação: dashboard, indicadores documentados, auditoria e custo."
- **Header:** "07 · Ato 2 · O que entregamos". **H2:** "Ganhamos visibilidade, **governança e custo**".
- **Grade 3 cards temáticos** (`grid 3×;gap:24px;margin-top:32px;margin-bottom:24px`), cada um padding 32, radius 24, clicável — trio **branco / navy / azul** (§4.7):
  1. Branco — "VISIBILIDADE" · título 72px azul "Métricas afiadas" · desc 26/500 `#5C5C7A` "Os indicadores saem sozinhos: relatório automático e sumário no ar." · lista (`border-top:1px solid #E5E5EE`, padding 10px 0, 24/600): Transbordo p/ humano com motivo · Atendimentos por protocolo · Eficiência por step · Funil de cobrança · Relatório automático · Sumário de indicadores. → `c_dash`.
  2. Navy `#0A0A2E` — "GOVERNANÇA" (`#C8C8D4`) · título `#7A7AFF` "Tudo rastreado" · desc `#C8C8D4` "Cada ação na Torre deixa log e respeita o bloqueio jurídico." · lista (divisor `#23235A`, texto branco): Blocklist jurídica · Logs de auditoria · Score de telefones · Ações em massa na régua. → `c_block`.
  3. Azul `#1A1AFF` — "CUSTO E CANAIS" (`#E8E8FF`) · título branco "Custo na mão" · desc `#E8E8FF` "O gasto da Torre agora é medido, com RCS no jogo." · lista (divisor `#4D4DFF`): Custo visível · RCS multimídia · Template RCS personalizado. → `c_custo`.
- Lista ancorada no fundo (`margin-top:auto;padding-top:20px`). Sem hover visual (só `cursor:pointer`).

---

### Slide 08 — `data-label="A virada"` (Ato 3 · O que vem agora — slide-tese)
- **Notes:** "Frase-chave da apresentação. As curvas são ilustrativas, não dados."
- **Fundo:** escuro de conteúdo. **Header:** "08 · Ato 3 · O que vem agora".
- **Layout:** grid `minmax(0,0.85fr) minmax(0,1.15fr)`, gap 56, centrado vertical.
- **Esquerda:** H2 92px em duas linhas (cada `<span data-a>`): "Incêndio controlado." (300 `#9C9CB4`) / "Agora é consolidar e escalar." (800 branco).
- **Direita — card do gráfico** (`data-a`): `background:#0E0E36;border:1px solid #2E2E6E;border-radius:24px;padding:40px 40px 32px;gap:16px`. SVG 700×500 (§4.9): duas curvas cruzando no meio (vermelha descendo, lavanda subindo), zona "futuro" destacada, marcador "A virada". Legenda (24 `#C8C8D4`): traço 32×6 vermelho "Incidentes", lavanda "Maturidade", à direita "Curvas ilustrativas".
- **Animações:** curvas desenhadas (`data-draw`, 1500ms; a segunda com `data-d="500"` = +500ms); pontos de cruzamento e de chegada pulsam.
- **Obs.:** pela constante `ACTS` (§5.3) este slide **deveria** abrir o Ato 3 com cortina, mas o índice configurado é 11 (inexistente) — ver bugs §8.

---

### Slide 09 — `data-label="Prioridades out–dez"` (Ato 3)
- **Notes:** "Quatro prioridades. Refatoração da Torre (BTR07) tem esforço XL e prazo realista de 6+ meses: para dezembro prometemos um marco, não o cutover. Clique nos cards."
- **Header:** "09 · Ato 3 · O que vem agora". **H2:** "Out–dez: **4 prioridades**".
- **Grade 4 cards** (`gap:20px;margin-top:40px;margin-bottom:24px`), padding 32, radius 24, gap 24, hover `translateY(-6px)` (250ms) — §4.8. Sequência de fundos **azul / branco / branco / navy**:
  1. `#1A1AFF` — "01" + pílula branca "Esforço XL" (texto azul, padding 4px 14px) — "Refatorar a Torre" — itens (26/600, divisor `#4D4DFF`): Fila com reprocessamento · Disparos em paralelo · Observabilidade — Meta box `#0F0F8C`: "META" / "Produto robusto e escalável". → `q_torre`.
  2. Branco — "02" azul — "Refatorar os agentes" — Prompts padronizados · Governança · Rastreio ponta a ponta — Meta box `#E8E8FF` (texto azul) "Agentes robustos e escaláveis". → `q_ag`.
  3. Branco — "03" — "Melhoria de métricas" — Visão ampliada das métricas dos agentes · Ações com maior granularidade — Meta "Maior visibilidade". → `q_kpi`.
  4. Navy — "04" `#7A7AFF` — "Pendências entregues" — Template Meta criado pela Torre · Maestro: agente de IA na Torre · Acessos mais personalizáveis · Saúde da conta Meta — Meta box `#1A1A4A` "Entregar o combinado". → `q_vis`.

---

### Slide 10 — `data-label="Obrigado"` (fechamento)
- **Notes:** "Agradecer e abrir para perguntas."
- Reusa a estrutura da capa (fundo, grade 40px, ornamento orbital idêntico, header "Torre de Controle · Encerramento" / "◆ Squad IA").
- Bloco `left:120px;top:280px;width:1080px;gap:40px`: pílula "Balanço do ciclo · jun–set/2026"; H1 220px "Obrigado" (branco, `data-w`) + "." (`#7A7AFF`, `data-w`); parágrafo 44px/300 `#C8C8D4` max-width 900: "Do apagar incêndio à **evolução planejada** (800 branco). Perguntas?".
- Autor (`data-a`) em `left:120px;bottom:96px`, gap 24: foto 96×96 circular `border:3px solid #1A1AFF;object-fit:cover` + "CRIADO POR" (24/600, 0.12em, uppercase `#C8C8D4`) / nome 36/800 branco.
- Não tem `data-om-slide-id` (foi duplicado da capa).

---

## 4. Catálogo de componentes (literal)

### 4.1 Barra de progresso global (topo)
```html
<div style="position:fixed;top:0;left:0;right:0;height:4px;z-index:1500;background:rgba(200,200,212,0.25);pointer-events:none">
  <div style="height:100%;background:#1A1AFF;transition:width 600ms cubic-bezier(.2,.8,.2,1);width:{{ progW }}"></div>
</div>
```
`progW = ((idx + 1) / (total || 14) * 100) + '%'`.

### 4.2 Header de slide (kicker + marca ◆)
Ver §3 (topo). Formato do texto: `NN · Ato N · Nome do ato`. Marca sempre "◆ Squad IA" no canto superior direito (a marca do deck substitui o "◆ iaf" do design system Finza).

### 4.3 Título ghost + accent
```html
<h2 data-a="1" style="margin:32px 0 0;font-size:72px;line-height:1.05;letter-spacing:-0.03em">
  <span style="font-weight:300;color:#9C9CB4">Começamos </span><span style="font-weight:800;color:#1A1AFF">apagando incêndio</span>
</h2>
```
Capa: palavra por palavra em `<span data-w="1">` dentro de `h1` flex-wrap (`column-gap:0.24em;row-gap:8px`).

### 4.4 Pílulas
```html
<!-- pílula de seção (capa/obrigado) -->
<span style="align-self:flex-start;font-size:24px;font-weight:600;color:#FFFFFF;background:#1A1AFF;border-radius:999px;padding:10px 24px">Balanço do ciclo · jun–set/2026</span>
<!-- pílula de status verde -->
<span style="margin-left:auto;font-size:24px;font-weight:700;color:#047857;background:#D1FAE5;border-radius:999px;padding:6px 16px;white-space:nowrap">✓ Resolvido</span>
<!-- pílula KPI navy (número + rótulo) -->
<div data-pop="1" style="display:flex;align-items:baseline;gap:12px;background:#0A0A2E;color:#FFFFFF;border-radius:999px;padding:12px 28px;flex-shrink:0"><span style="font-size:48px;font-weight:800;line-height:1;color:#10B981" data-count="41">41</span><span style="font-size:24px;font-weight:600">dias para estabilizar</span></div>
<!-- pílula total de coluna -->
<div data-pop="1" style="background:#0A0A2E;color:#FFFFFF;border-radius:999px;padding:8px 22px;margin-bottom:14px;display:flex;align-items:baseline;gap:8px;position:relative;z-index:1"><span style="font-size:44px;font-weight:800;line-height:1" data-count="71">71</span><span style="font-size:24px;color:#C8C8D4">entregas</span></div>
<!-- pílula de tag em card azul -->
<span style="font-size:24px;font-weight:700;background:#FFFFFF;color:#1A1AFF;border-radius:999px;padding:4px 14px">Esforço XL</span>
```

### 4.5 KPI card (número-herói)
```html
<div data-a="1" style="position:relative;background:#FFFFFF;color:#0A0A2E;border-radius:24px;padding:40px 32px;display:flex;flex-direction:column;overflow:hidden;min-width:0">
  <div style="display:flex;justify-content:space-between;align-items:center;gap:12px"><span style="font-size:24px;font-weight:700;color:#5C5C7A;letter-spacing:0.08em;text-transform:uppercase">Cycle time</span><span style="font-size:24px;font-weight:700;color:#047857;background:#D1FAE5;border-radius:999px;padding:6px 16px;white-space:nowrap">Meta batida</span></div>
  <div style="display:flex;flex-direction:column;gap:16px;margin-top:auto">
    <div style="display:flex;align-items:baseline;gap:8px"><span style="font-size:128px;font-weight:800;color:#1A1AFF;line-height:0.9;letter-spacing:-0.05em" data-count="3.69" data-dec="2">3,69</span><span style="font-size:48px;font-weight:800;color:#1A1AFF">d</span></div>
    <span style="font-size:34px;font-weight:700;line-height:1.15;text-wrap:pretty">mediana do início à entrega</span>
    <span style="font-size:24px;line-height:1.35;color:#5C5C7A;text-wrap:pretty">Meta de 3,7 d · 202 demandas medidas</span>
  </div>
</div>
```
Variante invertida: `background:#1A1AFF;color:#FFFFFF`, label/caption `#E8E8FF`, número `#FFFFFF`.

### 4.6 Card "antes/depois" clicável com faixa colorida (slide 02)
```html
<div data-a="1" sc-camel-on-click="{{ h.s_sis }}" style="position:relative;background:#FFFFFF;border-radius:24px;padding:24px 28px;display:flex;flex-direction:column;gap:14px;cursor:pointer;overflow:hidden;transition:transform 250ms" style-hover="transform:translateY(-4px)">
  <div style="position:absolute;left:0;top:0;right:0;height:8px;background:#1A1AFF"></div>
  <div style="display:flex;align-items:center;gap:16px">
    <span style="width:48px;height:48px;border-radius:50%;background:#1A1AFF;color:#FFFFFF;display:flex;align-items:center;justify-content:center;font-size:24px;font-weight:800;flex-shrink:0">1</span>
    <span style="font-size:36px;font-weight:800">Sistemas</span>
    <span style="margin-left:auto;font-size:24px;font-weight:700;color:#047857;background:#D1FAE5;border-radius:999px;padding:6px 16px;white-space:nowrap">✓ Resolvido</span>
  </div>
  <div style="display:flex;align-items:flex-end;justify-content:space-between;gap:16px;padding:4px 0 0">
    <div style="display:flex;flex-direction:column;gap:6px"><span style="font-size:24px;font-weight:700;color:#5C5C7A;letter-spacing:0.06em;text-transform:uppercase">Resolvido em</span><span data-pop="1" style="font-size:76px;font-weight:800;line-height:0.9;letter-spacing:-0.04em;color:#1A1AFF">02/07</span></div>
    <div style="display:flex;align-items:baseline;gap:8px"><span style="font-size:56px;font-weight:800;line-height:1" data-count="21">21</span><span style="font-size:26px;font-weight:700;color:#5C5C7A">dias</span></div>
  </div>
  <div style="display:flex;flex-direction:column;gap:8px">
    <div style="position:relative;height:18px;border-radius:9px;background:#F2F2F2;overflow:hidden"><div data-gx="1" style="height:100%;width:51.2%;background:#1A1AFF;border-radius:9px"></div></div>
  </div>
  <div style="display:flex;flex-direction:column;gap:10px;flex:1;justify-content:flex-end">
    <div style="background:#FEF2F2;border-radius:14px;padding:16px 18px;display:flex;flex-direction:column;gap:4px"><span style="font-size:24px;font-weight:800;color:#B91C1C;letter-spacing:0.06em;text-transform:uppercase">Antes</span><span style="font-size:26px;line-height:1.25">Torre instável e fora da cadência do MF</span></div>
    <div style="background:#ECFDF5;border-radius:14px;padding:16px 18px;display:flex;flex-direction:column;gap:4px"><span style="font-size:24px;font-weight:800;color:#047857;letter-spacing:0.06em;text-transform:uppercase">Depois</span><span style="font-size:26px;line-height:1.25;font-weight:700">Estável e conciliada com o MF</span></div>
  </div>
</div>
```

### 4.7 Card temático (trio branco / navy / azul, slide 07)
```html
<div data-a="1" sc-camel-on-click="{{ h.c_block }}" style="background:#0A0A2E;color:#FFFFFF;border-radius:24px;padding:32px;display:flex;flex-direction:column;cursor:pointer;min-width:0;min-height:0">
  <span style="font-size:24px;font-weight:700;letter-spacing:0.08em;text-transform:uppercase;color:#C8C8D4">Governança</span>
  <div style="display:flex;flex-direction:column;gap:8px;margin-top:20px">
    <span style="font-size:72px;font-weight:800;color:#7A7AFF;line-height:0.95;letter-spacing:-0.04em;text-wrap:balance">Tudo rastreado</span>
    <span style="font-size:26px;font-weight:500;line-height:1.3;color:#C8C8D4;text-wrap:pretty">Cada ação na Torre deixa log e respeita o bloqueio jurídico.</span>
  </div>
  <div style="display:flex;flex-direction:column;margin-top:auto;padding-top:20px">
    <div style="display:flex;justify-content:space-between;align-items:baseline;gap:16px;padding:10px 0;border-top:1px solid #23235A;font-size:24px"><span style="font-weight:600;color:#FFFFFF">Blocklist jurídica</span></div>
    <!-- … -->
  </div>
</div>
```
Tabela de variantes: branco (label `#5C5C7A`, título `#1A1AFF`, desc `#5C5C7A`, divisor `#E5E5EE`, item `#0A0A2E`) · navy (`#C8C8D4` / `#7A7AFF` / `#C8C8D4` / `#23235A` / branco) · azul (`#E8E8FF` / branco / `#E8E8FF` / `#4D4DFF` / branco).

### 4.8 Card de prioridade com "Meta" (slide 09)
```html
<div data-a="1" sc-camel-on-click="{{ h.q_torre }}" style="background:#1A1AFF;color:#FFFFFF;border-radius:24px;padding:32px;display:flex;flex-direction:column;gap:24px;cursor:pointer;min-width:0;transition:transform 250ms" style-hover="transform:translateY(-6px)">
  <div style="display:flex;justify-content:space-between;align-items:center;gap:12px"><span style="font-size:24px;font-weight:800;color:#FFFFFF;letter-spacing:0.04em">01</span><span style="font-size:24px;font-weight:700;background:#FFFFFF;color:#1A1AFF;border-radius:999px;padding:4px 14px">Esforço XL</span></div>
  <span style="font-size:44px;font-weight:800;line-height:1.05;letter-spacing:-0.02em;text-wrap:balance">Refatorar a Torre</span>
  <div style="display:flex;flex-direction:column">
    <div style="display:flex;justify-content:space-between;align-items:baseline;gap:12px;padding:12px 0;border-top:1px solid #4D4DFF;font-size:26px"><span style="font-weight:600">Fila com reprocessamento</span></div>
  </div>
  <div style="margin-top:auto;background:#0F0F8C;border-radius:16px;padding:20px 24px;display:flex;flex-direction:column;gap:4px"><span style="font-size:24px;font-weight:700;letter-spacing:0.08em;text-transform:uppercase;color:#C8C8D4">Meta</span><span style="font-size:32px;font-weight:800;line-height:1.15;color:#FFFFFF">Produto robusto e escalável</span></div>
</div>
```
Meta box por fundo: azul→`#0F0F8C` (label `#C8C8D4`, valor branco); branco→`#E8E8FF` (label `#5C5C7A`, valor `#1A1AFF`); navy→`#1A1A4A` (label `#C8C8D4`, valor branco). Número: branco / `#1A1AFF` / `#7A7AFF`.

### 4.9 Waffle de quadrados (slide 03)
```html
<div data-a="1" style="background:#FFFFFF;border:2px dotted #1A1AFF;border-radius:16px;padding:32px;display:flex;flex-direction:column;gap:20px">
  <div style="display:grid;grid-template-columns:repeat(20,1fr);gap:5px">
    <sc-for list="{{ cells }}" as="c" hint-placeholder-count="278">
      <div data-cell="1" style="aspect-ratio:1;border-radius:6px;background:{{ c.bg }};opacity:{{ c.op }};transition:opacity 250ms"></div>
    </sc-for>
  </div>
  <span style="font-size:24px;color:#5C5C7A">1 quadrado = 1 demanda finalizada · 278 no total</span>
</div>
```
```js
if (!this._cellsBase) this._cellsBase = Array.from({ length: 278 }, (_, i) => i < 55 ? 'r' : 'o');
const cells = this._cellsBase.map(k => ({ bg: k === 'r' ? '#1A1AFF' : '#F59E0B', op: !slice || slice === k ? 1 : 0.15 }));
```
Card-legenda com hover: `border:2px solid {{ bdR }};transition:border-color 250ms` com `bdR = slice==='r' ? '#1A1AFF' : '#D8D8E5'`, `bdO = slice==='o' ? '#F59E0B' : '#D8D8E5'`.

### 4.10 Barras
**Barra simples com trilho** (`data-gx` escala de 0 a 1 em X a partir da esquerda):
```html
<div style="height:10px;border-radius:5px;background:#E8E8FF;overflow:hidden"><div data-gx="1" style="height:100%;width:79%;background:#1A1AFF;border-radius:5px"></div></div>
```
**Barra empilhada proporcional** (flex = valor):
```html
<div style="display:flex;height:56px;border-radius:10px;overflow:hidden;font-size:24px;font-weight:700">
  <div data-gx="1" style="flex:278;background:#0A0A2E;color:#FFFFFF;display:flex;align-items:center;padding-left:20px">278 finalizadas</div>
  <div data-gx="1" style="flex:12;background:#C8C8D4;display:flex;align-items:center;justify-content:center">12</div>
  <div data-gx="1" style="flex:17;background:#EF4444;color:#FFFFFF;display:flex;align-items:center;justify-content:center">17</div>
</div>
```
**Padrão listrado "fora do plano"** (âmbar + listras diagonais animadas):
```css
background-color:#F59E0B;
background-image:repeating-linear-gradient(135deg,rgba(255,255,255,0.22) 0 12px,rgba(255,255,255,0) 12px 24px);
background-size:34px 34px;
```
+ `data-stripe="1"` → loop `backgroundPosition 0 0 → 34px 0` em 1600ms.

**Segmento de coluna empilhada** (slide 05):
```html
<div data-rise="1" data-stripe="1" sc-camel-on-mouse-enter="{{ sg.juld }}" sc-camel-on-mouse-leave="{{ sgOff }}" style="position:relative;height:129px;background-color:#F59E0B;background-image:repeating-linear-gradient(135deg,rgba(255,255,255,0.22) 0 12px,rgba(255,255,255,0) 12px 24px);background-size:34px 34px;color:#0A0A2E;border-radius:14px 14px 0 0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:4px;cursor:default;box-shadow:inset 0 3px 0 rgba(255,255,255,0.35);transition:filter 200ms" style-hover="filter:brightness(1.08)"><span style="font-size:40px;font-weight:800;line-height:1">45</span><span style="font-size:24px;font-weight:700;background:rgba(255,255,255,0.55);border-radius:999px;padding:2px 12px">63%</span></div>
<div data-rise="1" sc-camel-on-mouse-enter="{{ sg.julr }}" sc-camel-on-mouse-leave="{{ sgOff }}" style="position:relative;height:74px;background:#1A1AFF;color:#FFFFFF;border-top:3px solid #F2F2F2;display:flex;align-items:center;justify-content:center;gap:10px;cursor:default;box-sizing:border-box;transition:filter 200ms" style-hover="filter:brightness(1.2)"><span style="font-size:36px;font-weight:800;line-height:1">26</span><span style="font-size:24px;font-weight:700;color:#E8E8FF">37%</span></div>
```
**Gridline do eixo**:
```html
<div style="position:absolute;left:0;right:0;bottom:300px;display:flex;align-items:center;gap:12px;transform:translateY(50%)"><span style="width:44px;text-align:right;font-size:24px;color:#9C9CB4">105</span><div style="flex:1;border-top:2px dashed #E1E1EA"></div></div>
```
**Mini colunas verticais** (`data-gy`, crescem de baixo):
```html
<div data-gy="1" style="width:100%;height:36px;background:#1A1AFF;border-radius:6px 6px 0 0"></div>
```

### 4.11 Treemap manual (slide 06)
Construído só com flex aninhado e `flex:N` = contagem; `gap:8px`; tiles `border-radius:14px;display:flex;flex-direction:column;justify-content:space-between` (nome em cima, número embaixo). Tiles pequenos com texto vertical: `writing-mode:vertical-rl;transform:rotate(180deg)`. Rótulo quebrado manualmente com hífen + espaço ("Integra- ções", "Dados/ Infra") para forçar quebra em tile estreito.

### 4.12 Ornamento orbital (capa/obrigado) — "gauge" decorativo
```html
<div style="position:absolute;right:-120px;top:50%;width:980px;height:980px;margin-top:-490px">
  <svg viewBox="0 0 980 980" width="980" height="980" style="position:absolute;inset:0;overflow:visible">
    <circle cx="490" cy="490" r="460" fill="none" stroke="#23235A" stroke-width="2"></circle>
    <g data-spin="90"><circle cx="490" cy="490" r="380" fill="none" stroke="#1A1AFF" stroke-width="2" stroke-dasharray="4 14"></circle><circle cx="490" cy="110" r="12" fill="#1A1AFF"></circle><circle cx="870" cy="490" r="7" fill="#7A7AFF"></circle></g>
    <g data-spin="-60"><circle cx="490" cy="490" r="290" fill="none" stroke="#3A3A8C" stroke-width="2"></circle><circle cx="200" cy="490" r="10" fill="#FFFFFF"></circle><circle cx="695" cy="285" r="6" fill="#1A1AFF"></circle></g>
    <g data-spin="40"><circle cx="490" cy="490" r="200" fill="none" stroke="#1A1AFF" stroke-width="3" stroke-dasharray="120 40 20 40"></circle></g>
    <circle data-pulse="1" cx="490" cy="490" r="120" fill="#1A1AFF"></circle>
  </svg>
  <div style="position:absolute;left:490px;top:490px;transform:translate(-50%,-50%);font-size:44px;font-weight:800;color:#FFFFFF;letter-spacing:-0.02em;white-space:nowrap">Squad IA</div>
</div>
```
Velocidades (fórmula §5.5): spin 90 → 24s/volta horário; -60 → 36s anti-horário; 40 → 54s horário. Núcleo pulsa 1→1.08→1 em 2600ms ease-in-out. Origem de rotação `490px 490px`.

### 4.13 Curvas "A virada" (slide 08)
```html
<svg viewBox="0 0 700 500" preserveAspectRatio="xMidYMid meet" style="width:100%;height:auto;display:block;overflow:visible">
  <defs>
    <linearGradient id="gR" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#EF4444" stop-opacity="0.4"></stop><stop offset="1" stop-color="#EF4444" stop-opacity="0"></stop></linearGradient>
    <linearGradient id="gB" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7A7AFF" stop-opacity="0.5"></stop><stop offset="1" stop-color="#7A7AFF" stop-opacity="0"></stop></linearGradient>
  </defs>
  <rect x="350" y="0" width="350" height="440" fill="#1A1AFF" opacity="0.10"></rect>           <!-- zona "futuro" -->
  <line x1="0" y1="110" x2="700" y2="110" stroke="#23235A" stroke-width="1"></line>
  <line x1="0" y1="220" x2="700" y2="220" stroke="#23235A" stroke-width="1"></line>
  <line x1="0" y1="330" x2="700" y2="330" stroke="#23235A" stroke-width="1"></line>
  <path d="M0 70 C 200 80, 250 210, 350 250 S 560 390, 700 395 L 700 440 L 0 440 Z" fill="url(#gR)"></path>
  <path d="M0 430 C 200 420, 250 290, 350 250 S 560 110, 700 105 L 700 440 L 0 440 Z" fill="url(#gB)"></path>
  <!-- glow: mesma curva, stroke 22, opacidade baixa -->
  <path d="M0 70 C 200 80, 250 210, 350 250 S 560 390, 700 395" fill="none" stroke="#EF4444" stroke-width="22" stroke-linecap="round" opacity="0.18"></path>
  <path d="M0 430 C 200 420, 250 290, 350 250 S 560 110, 700 105" fill="none" stroke="#7A7AFF" stroke-width="22" stroke-linecap="round" opacity="0.22"></path>
  <!-- traço principal desenhado -->
  <path data-draw="1" d="M0 70 C 200 80, 250 210, 350 250 S 560 390, 700 395" fill="none" stroke="#EF4444" stroke-width="8" stroke-linecap="round"></path>
  <path data-draw="1" data-d="500" d="M0 430 C 200 420, 250 290, 350 250 S 560 110, 700 105" fill="none" stroke="#7A7AFF" stroke-width="8" stroke-linecap="round"></path>
  <line x1="350" y1="56" x2="350" y2="440" stroke="#FFFFFF" stroke-width="2" stroke-dasharray="6 8" opacity="0.6"></line>
  <line x1="0" y1="440" x2="700" y2="440" stroke="#3A3A66" stroke-width="2"></line>
  <rect x="280" y="0" width="140" height="48" rx="24" fill="#FFFFFF"></rect>
  <text x="350" y="32" text-anchor="middle" font-size="24" fill="#0A0A2E" font-family="Inter" font-weight="800">A virada</text>
  <circle data-pulse="1" cx="350" cy="250" r="28" fill="#FFFFFF" opacity="0.2"></circle>
  <circle cx="350" cy="250" r="12" fill="#FFFFFF"></circle>
  <circle data-pulse="1" cx="700" cy="105" r="14" fill="#7A7AFF"></circle>
  <text x="684" y="80" text-anchor="end" font-size="26" fill="#FFFFFF" font-family="Inter" font-weight="800">Maturidade ↑</text>
  <circle cx="700" cy="395" r="10" fill="#EF4444"></circle>
  <text x="684" y="348" text-anchor="end" font-size="26" fill="#FCA5A5" font-family="Inter" font-weight="800">Incidentes ↓</text>
  <text x="175" y="482" text-anchor="middle" font-size="24" fill="#FCA5A5" font-family="Inter" font-weight="700">jun–set · reativo</text>
  <text x="525" y="482" text-anchor="middle" font-size="24" fill="#FFFFFF" font-family="Inter" font-weight="700">out → dez · planejado</text>
</svg>
```
Receita: cada curva = área com gradiente vertical (topo 0.4/0.5 → 0) + glow (stroke 22, opacity .18/.22) + traço 8px desenhado. As duas curvas são espelhos que se cruzam em (350,250). Linha vertical tracejada marca a virada, rótulo pílula branca no topo.

### 4.14 Ticker (capa)
Ver §3 slide 01. Requisito: conteúdo duplicado exatamente 2× dentro do mesmo flex, para `translateX(-50%)` emendar sem salto.

### 4.15 Slide de obrigado + assinatura
Ver §3 slide 10 (foto 96px circular borda 3px azul + "CRIADO POR" + nome).

### 4.16 Painel lateral de detalhe (fora do canvas, `position:fixed`)
```html
<sc-if value="{{ panelOpen }}">
  <div sc-camel-on-click="{{ closePanel }}" style="position:fixed;inset:0;z-index:1900;background:rgba(10,10,46,0.45)"></div>
  <aside ref="{{ panelRef }}" style="position:fixed;top:0;right:0;bottom:0;width:min(560px,92vw);z-index:1950;background:#FFFFFF;border-left:3px solid #1A1AFF;font-family:Inter,sans-serif;color:#0A0A2E;display:flex;flex-direction:column;box-sizing:border-box;padding:clamp(20px,4vw,40px);gap:24px;overflow:auto">
    <div style="display:flex;justify-content:space-between;align-items:center">
      <span style="font-size:15px;font-weight:700;letter-spacing:0.1em;text-transform:uppercase;color:#5C5C7A">{{ panel.eyebrow }}</span>
      <span sc-camel-on-click="{{ closePanel }}" style="font-size:15px;font-weight:700;color:#1A1AFF;cursor:pointer">Fechar ✕</span>
    </div>
    <div style="display:flex;align-items:baseline;gap:16px">
      <span style="font-size:64px;font-weight:800;color:#1A1AFF;line-height:1">{{ panel.big }}</span>
      <span style="font-size:28px;font-weight:800;line-height:1.2">{{ panel.title }}</span>
    </div>
    <span style="font-size:18px;color:#5C5C7A;line-height:1.5">{{ panel.desc }}</span>
    <div style="display:flex;flex-direction:column">
      <sc-for list="{{ panel.items }}" as="it">
        <div style="display:grid;grid-template-columns:72px minmax(0,1fr);gap:16px;padding:16px 0;border-top:1px solid #D8D8E5;font-size:18px;line-height:1.4">
          <span style="font-weight:800;color:#1A1AFF">{{ it.d }}</span>
          <span>{{ it.t }}</span>
        </div>
      </sc-for>
    </div>
    <span style="margin-top:auto;font-size:14px;color:#5C5C7A">{{ panel.fonte }}</span>
  </aside>
</sc-if>
```
Modelo de dado do painel: `{ eyebrow, big, title, desc, items:[{d, t}], fonte }`. `d` = data ("24/06"), "—", "•" ou valor ("2,13 d"). **Toda entrada tem `fonte`** (rodapé "Fonte: …").

### 4.17 Overview (grade de slides)
```html
<sc-if value="{{ ovOpen }}">
  <div style="position:fixed;inset:0;z-index:1990;background:#0A0A2E;font-family:Inter,sans-serif;color:#FFFFFF;padding:clamp(16px,4vw,48px);box-sizing:border-box;overflow:auto;display:flex;flex-direction:column;gap:28px">
    <div style="display:flex;justify-content:space-between;align-items:center">
      <span style="font-size:20px;font-weight:800">Visão geral</span>
      <span sc-camel-on-click="{{ closeOv }}" style="font-size:16px;color:#C8C8D4;cursor:pointer">ESC para fechar</span>
    </div>
    <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(min(240px,100%),1fr));gap:16px">
      <sc-for list="{{ ovSlides }}" as="s">
        <div sc-camel-on-click="{{ s.go }}" style="aspect-ratio:16/9;border-radius:12px;padding:20px;box-sizing:border-box;display:flex;flex-direction:column;justify-content:space-between;cursor:pointer;border:2px dotted #1A1AFF;background:{{ s.bg }}" style-hover="border-color:#FFFFFF">
          <span style="font-size:28px;font-weight:800;color:#7A7AFF">{{ s.n }}</span>
          <span style="font-size:16px;font-weight:600;line-height:1.3">{{ s.label }}</span>
        </div>
      </sc-for>
    </div>
  </div>
</sc-if>
```
Cards: número 2 dígitos + `data-label`; slide atual `#1A1AFF`, demais `#16163F`; clique → `deck-stage.goTo(i)` e fecha.

### 4.18 Camadas de transição (fora do canvas)
```html
<div ref="{{ sweepRef }}" style="position:fixed;top:0;bottom:0;left:0;width:22vw;z-index:1700;pointer-events:none;background:linear-gradient(90deg,rgba(26,26,255,0) 0%,rgba(26,26,255,0.55) 70%,#1A1AFF 100%);transform:translateX(-30vw)"></div>

<div ref="{{ wipeRef }}" style="position:fixed;inset:0;z-index:1800;background:#1A1AFF;color:#FFFFFF;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px;pointer-events:none;clip-path:inset(0 0 0 100%);font-family:Inter,sans-serif">
  <span style="font-size:clamp(14px,1.6vw,22px);font-weight:700;letter-spacing:0.24em;text-transform:uppercase;color:#E8E8FF">{{ wipeAct }}</span>
  <span style="font-size:clamp(32px,5vw,64px);font-weight:800;letter-spacing:-0.03em;text-align:center;padding:0 24px">{{ wipeTitle }}</span>
</div>
```
Pilha de z-index: progresso 1500 · sweep 1700 · wipe 1800 · scrim 1900 · painel 1950 · overview 1990.

---

## 5. Motor de animação (literal)

Tudo via **Web Animations API** (`el.animate`), sem CSS keyframes. Easing global:
```js
const EASE = 'cubic-bezier(.2,.8,.2,1)';
```

### 5.1 Ciclo de vida
```js
componentDidMount() {
  this.reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  this.onSlide = (e) => {
    const { index, previousIndex, total, slide } = e.detail || {};
    if (!slide || slide === this.active) return; // re-renders re-emit slidechange for the same slide; never restart it
    this.setState({ idx: index, total, panel: null, tip: {}, slice: null, seg: null });
    this.activate(slide, index, previousIndex);
  };
  document.addEventListener('slidechange', this.onSlide);
  this.onVis = () => { if (!document.hidden && this.active) this.settle(this.active); };
  document.addEventListener('visibilitychange', this.onVis);
  this.onKey = (e) => {
    if (e.target && /INPUT|TEXTAREA/.test(e.target.tagName)) return;
    if (e.key === 'f' || e.key === 'F') {
      if (document.fullscreenElement) document.exitFullscreen(); else document.documentElement.requestFullscreen && document.documentElement.requestFullscreen();
    } else if (e.key === 'Escape') {
      if (this.state.panel) this.setState({ panel: null });
      else this.setState(s => ({ ov: !s.ov }));
      e.stopPropagation();
    }
  };
  window.addEventListener('keydown', this.onKey, true);
  this.onResize = () => { if (this.active) this.settle(this.active); };
  window.addEventListener('resize', this.onResize);
  this.tryInit = setInterval(() => {
    const a = document.querySelector('deck-stage > section[data-deck-active]');
    if (a) { clearInterval(this.tryInit); if (this.active === a) return; const secs = [...document.querySelectorAll('deck-stage > section')]; const i = secs.indexOf(a); this.setState({ idx: i, total: secs.length }); this.activate(a, i, -1); }
  }, 100);
}

activate(slide, index, prev) {
  if (!slide) return;
  const tok = this._tok = (this._tok || 0) + 1;
  this.active = slide;
  document.querySelectorAll('deck-stage > section').forEach((s) => this.reset(s));
  [this.wipeRef.current, this.sweepRef.current].forEach((el) => el && el.getAnimations({ subtree: true }).forEach((x) => x.cancel()));
  this.repaint(slide);
  if (this.reduced) return;
  const act = !!ACTS[index] && prev === index - 1;
  try {
    if (act) this.wipe(index);
    else if (prev >= 0) this.transition(slide, index > prev ? 1 : -1);
    this.play(slide, act ? 650 : 120);
  } catch (err) { this.settle(slide); }
  setTimeout(() => { if (this._tok === tok) { this.settle(slide); this.repaint(slide); } }, 3200);
}
// Forces the browser to re-rasterize the slide (fixes GPU paint glitches that left text unpainted).
repaint(s) {
  requestAnimationFrame(() => { s.style.outline = '0.1px solid transparent'; void s.offsetWidth; requestAnimationFrame(() => { s.style.outline = ''; }); });
}
reset(s) {
  s.getAnimations({ subtree: true }).forEach((x) => { if (x._loop) x.pause(); else x.cancel(); });
  s.querySelectorAll('[data-count]').forEach((el) => this.finalCount(el));
}
settle(s) {
  s.getAnimations({ subtree: true }).forEach((x) => { if (x._loop) return; try { x.finish(); } catch (e) { x.cancel(); } });
  s.querySelectorAll('[data-count]').forEach((el) => this.finalCount(el));
}
```
Princípios: (1) **estado final é o estilo base** — anima *de* oculto com `fill:'backwards'`, então sem JS/print/reduced-motion tudo aparece; (2) token `_tok` invalida timers antigos; (3) "rede de segurança" em 3200ms força `finish()` de tudo; (4) loops são pausados (não cancelados) ao sair, e retomados ao voltar; (5) reduced-motion → nenhum movimento.

### 5.2 `play()` — API de data-attributes
```js
play(slide, base) {
  const opt = (d, dur) => ({ duration: dur || 600, delay: base + d, easing: EASE, fill: 'backwards' });
  slide.querySelectorAll('[data-w]').forEach((el, i) => el.animate([{ opacity: 0, transform: 'translateY(60%)', filter: 'blur(8px)' }, { opacity: 1, transform: 'none', filter: 'blur(0)' }], opt(200 + i * 90, 700)));
  slide.querySelectorAll('[data-a]').forEach((el, i) => el.animate([{ opacity: 0, transform: 'translateY(32px)' }, { opacity: 1, transform: 'none' }], opt(80 + i * 70)));
  slide.querySelectorAll('[data-pop]').forEach((el, i) => el.animate([{ opacity: 0, scale: '0.6' }, { opacity: 1, scale: '1.04', offset: 0.7 }, { opacity: 1, scale: '1' }], opt(300 + i * 80, 600)));
  slide.querySelectorAll('[data-gx]').forEach((el, i) => { el.style.transformOrigin = 'left center'; el.animate([{ transform: 'scaleX(0)' }, { transform: 'scaleX(1)' }], opt(350 + i * 60, 900)); });
  slide.querySelectorAll('[data-gy]').forEach((el, i) => { el.style.transformOrigin = 'center bottom'; el.style.transformBox = 'fill-box'; el.animate([{ transform: 'scaleY(0)' }, { transform: 'scaleY(1)' }], opt(300 + i * 100, 900)); });
  slide.querySelectorAll('[data-draw]').forEach((el) => { const L = el.getTotalLength ? el.getTotalLength() : 0; if (!L) return; el.style.strokeDasharray = L; el.animate([{ strokeDashoffset: L }, { strokeDashoffset: 0 }], opt(500 + (+el.dataset.d || 0), 1500)); });
  slide.querySelectorAll('[data-cell]').forEach((el, i) => el.animate([{ opacity: 0, transform: 'scale(0.2)' }, { opacity: 1, transform: 'none' }], opt(250 + i * 6, 420)));
  slide.querySelectorAll('[data-type]').forEach((el, i) => el.animate([{ clipPath: 'inset(0 100% 0 0)' }, { clipPath: 'inset(0 0 0 0)' }], opt(600 + i * 450, 500)));
  slide.querySelectorAll('[data-rise]').forEach((el, i) => { const colI = Math.floor(i / 2), isR = i % 2 === 1; el.animate([{ clipPath: 'inset(100% 0 0 0)' }, { clipPath: 'inset(0 0 0 0)' }], opt(300 + colI * 120 + (isR ? 0 : 650), 650)); });
  slide.querySelectorAll('[data-count]').forEach((el) => this.count(el, base + 250));
  slide.querySelectorAll('[data-pulse]').forEach((el) => { el.style.transformOrigin = 'center'; el.style.transformBox = 'fill-box'; this.loop(el, [{ transform: 'scale(1)' }, { transform: 'scale(1.08)' }, { transform: 'scale(1)' }], { duration: 2600, easing: 'ease-in-out' }); });
  slide.querySelectorAll('[data-spin]').forEach((el) => { const s = +el.dataset.spin; el.style.transformOrigin = el.closest('section[data-label^="Conquista 2"]') ? '550px 330px' : '490px 490px'; this.loop(el, [{ transform: 'rotate(0deg)' }, { transform: `rotate(${s > 0 ? 360 : -360}deg)` }], { duration: Math.abs(360 / s) * 1000 * 6 }); });
  slide.querySelectorAll('[data-ripple]').forEach((el) => { el.style.transformOrigin = 'center'; el.style.transformBox = 'fill-box'; this.loop(el, [{ transform: 'scale(1)', opacity: 0.9 }, { transform: 'scale(3.8)', opacity: 0 }], { duration: 4200, delay: +el.dataset.ripple * 1400, easing: 'cubic-bezier(0.25, 1, 0.5, 1)' }); });
  slide.querySelectorAll('[data-wave]').forEach((el) => { const [d, hot] = el.dataset.wave.split(',').map(Number); const peak = hot ? '#FFFFFF' : '#1A1AFF'; this.loop(el, [{ transform: 'scale(0.3)', background: '#1C1C4E', borderRadius: '50%' }, { transform: 'scale(1)', background: peak, borderRadius: '8px', offset: 0.18 }, { transform: 'scale(0.3)', background: '#1C1C4E', borderRadius: '50%', offset: 0.5 }, { transform: 'scale(0.3)', background: '#1C1C4E', borderRadius: '50%' }], { duration: 3600, delay: d * 110, easing: 'cubic-bezier(0.25, 1, 0.5, 1)', fill: 'backwards' }); });
  slide.querySelectorAll('[data-flow]').forEach((el) => { const [dx, dy] = el.dataset.flow.split(',').map(Number); this.loop(el, [{ transform: 'translate(0,0)', opacity: 0 }, { opacity: 1, offset: 0.15 }, { opacity: 1, offset: 0.85 }, { transform: `translate(${dx}px,${dy}px)`, opacity: 0 }], { duration: 1800, delay: +el.dataset.fd || 0, easing: 'ease-in-out' }); });
  slide.querySelectorAll('[data-ticker]').forEach((el) => this.loop(el, [{ transform: 'translateX(0)' }, { transform: 'translateX(-50%)' }], { duration: 40000 }));
  slide.querySelectorAll('[data-stripe]').forEach((el) => this.loop(el, [{ backgroundPosition: '0 0' }, { backgroundPosition: '34px 0' }], { duration: 1600 }));
  slide.querySelectorAll('[data-blink]').forEach((el) => this.loop(el, [{ opacity: 1 }, { opacity: 0 }, { opacity: 1 }], { duration: 1000, easing: 'steps(2)' }));
}
```

**Tabela da API** (delay real = `base` + valor; `base` = 120ms normal ou 650ms após cortina de ato; `i` = índice na ordem do DOM dentro do slide):

| Atributo | Efeito | Duração | Delay | Usado em |
|---|---|---|---|---|
| `data-w` | palavra sobe 60% + blur 8px→0 | 700 | 200 + i·90 | H1 capa/obrigado |
| `data-a` | fade + translateY 32px | 600 | 80 + i·70 | blocos/cards de todos os slides |
| `data-pop` | scale .6 → 1.04 (70%) → 1 | 600 | 300 + i·80 | pílulas KPI, datas, tiles treemap, badges |
| `data-gx` | scaleX 0→1 (origem esquerda) | 900 | 350 + i·60 | barras horizontais/empilhadas |
| `data-gy` | scaleY 0→1 (origem base) | 900 | 300 + i·100 | mini-colunas |
| `data-draw` (+`data-d`=ms extra) | stroke-dashoffset L→0 | 1500 | 500 + d | curvas SVG |
| `data-cell` | scale .2→1 + fade | 420 | 250 + i·6 | waffle |
| `data-rise` | clip-path de baixo p/ cima | 650 | 300 + col·120 (+650 se segmento ímpar/topo) | colunas empilhadas (pares: [topo, base] na ordem do DOM) |
| `data-type` | clip-path esquerda→direita (efeito "digitação") | 500 | 600 + i·450 | *não usado neste deck* |
| `data-count` (+`data-dec`) | count-up 0→valor, ease-out cúbico | 1300 | base + 250 | todos os números |
| `data-pulse` | loop scale 1→1.08→1 | 2600 ease-in-out | — | núcleo orbital, pontos da virada |
| `data-spin="N"` | loop rotação 360°, sinal = sentido | `|360/N|·6000` ms | — | anéis orbitais |
| `data-ripple="k"` | loop onda scale 1→3.8 + fade | 4200 | k·1400 | *não usado* |
| `data-wave="d,hot"` | loop ponto→quadrado aceso | 3600 | d·110 | *não usado* |
| `data-flow="dx,dy"` (+`data-fd`) | loop partícula deslizando | 1800 | fd | *não usado* |
| `data-ticker` | loop translateX 0→-50% linear | 40000 | — | ticker da capa |
| `data-stripe` | loop backgroundPosition 0→34px | 1600 | — | listras âmbar |
| `data-blink` | loop pisca (steps(2)) | 1000 | — | *não usado* |

Observação sobre `data-rise`: o loop usa `i % 2 === 1` como "isR" (roadmap). Como no DOM o segmento "demais" (topo) vem antes do "roadmap" (base), o índice ímpar é o roadmap → ele sobe primeiro (delay 300+col·120) e o "demais" sobe 650ms depois, empilhando visualmente de baixo para cima.

### 5.3 Count-up
```js
fmt(el, v) { const dec = +(el.dataset.dec || 0); return v.toLocaleString('pt-BR', { minimumFractionDigits: dec, maximumFractionDigits: dec }); }
finalCount(el) { cancelAnimationFrame(el._raf); clearTimeout(el._to); el.textContent = this.fmt(el, parseFloat(el.dataset.count)); }
count(el, delay) {
  const t = parseFloat(el.dataset.count), dur = 1300;
  cancelAnimationFrame(el._raf); clearTimeout(el._to);
  if (document.hidden) { this.finalCount(el); return; }
  el.textContent = this.fmt(el, 0);
  el._to = setTimeout(() => {
    const st = performance.now();
    const step = (n) => { const p = Math.max(0, Math.min(1, (n - st) / dur)); el.textContent = this.fmt(el, t * (1 - Math.pow(1 - p, 3))); if (p < 1) el._raf = requestAnimationFrame(step); };
    el._raf = requestAnimationFrame(step);
  }, delay);
}
```
`data-count` usa ponto decimal (`3.69`), a exibição usa vírgula pt-BR (`3,69`) via `toLocaleString`. O HTML já traz o valor final como texto (fallback).

### 5.4 Loops
```js
loop(el, kf, o) {
  if (el._loop) { el._loop.play(); return; }
  el._loop = el.animate(kf, { iterations: Infinity, ...o });
  el._loop._loop = true;
}
```
Uma única instância por elemento; `reset()` pausa, `play()` retoma — o loop não reinicia do zero ao revisitar o slide.

### 5.5 Painéis de detalhe (dados e abertura)
```js
const F1 = 'Fonte: roadmap da Torre + Quimera · 11/06 → 01/10/2026';
const F2 = 'Fonte: painel de indicadores do Quimera · janela ago–out · extraído em 01/10/2026';
const fr = (big, title, items, desc) => ({ eyebrow: 'Frente do roadmap', big, title, items: items || [], desc: desc || 'Lista completa por entrega no dossiê do roadmap.', fonte: F1 });
const mc = (eyebrow, d, title, desc) => ({ eyebrow, big: '', title, desc, items: [{ d, t: title }], fonte: F1 });
const PANELS = { s_sis: {…}, s_ag: {…}, s_fer: {…}, f_dash: fr('22','Dashboard',[…],'…'), …, q_vis: {…} };

h = Object.fromEntries(Object.keys(PANELS).map(k => [k, (e) => { e && e.stopPropagation && e.stopPropagation(); this.setState({ panel: PANELS[k] }, () => this.slidePanel()); }]));

slidePanel() {
  const el = this.panelRef.current; if (!el || this.reduced) return;
  el.animate([{ transform: 'translateX(100%)' }, { transform: 'none' }], { duration: 420, easing: EASE });
  [...el.children].forEach((c, i) => c.animate([{ opacity: 0, transform: 'translateX(24px)' }, { opacity: 1, transform: 'none' }], { duration: 400, delay: 120 + i * 50, easing: EASE, fill: 'backwards' }));
}
```
- `stopPropagation` impede que o clique vire "tap de avanço" do deck-stage.
- Fechar: clique no scrim, em "Fechar ✕", ou ESC. Trocar de slide também fecha (`panel:null` no `onSlide`).
- Painéis usados: s_sis, s_fer, s_ag (02); f_* (06); c_dash, c_block, c_custo (07); q_torre, q_ag, q_kpi, q_vis (09). Os conteúdos completos estão nas linhas 1133–1160 do HTML (exemplo: `q_kpi` → eyebrow "Prioridade 03", big "03", title "KPIs melhores", desc "Gate de refinamento e homologação antes do desenvolvimento.", items [2,13 d · Tempo de espera por demanda; 9,17 d · P90 do cycle time; 22 · Voltas/reaberturas no ciclo], fonte F2).

### 5.6 Hover de legenda/segmentos
```js
const SEGS = ['julr', 'juld', 'agor', 'agod', 'setr', 'setd'];
const SEG_LBL = { julr: 'Jul · Roadmap: 26 de 71 (37%)', juld: 'Jul · Demais: 45 de 71 (63%)', agor: 'Ago · Roadmap: 8 de 70 (11%)', agod: 'Ago · Demais: 62 de 70 (89%)', setr: 'Set · Roadmap: 29 de 132 (22%)', setd: 'Set · Demais: 103 de 132 (78%)' };
sg = Object.fromEntries(SEGS.map(k => [k, () => this.setState({ seg: k })]));
// renderVals:
segLabel: this.state.seg ? SEG_LBL[this.state.seg] : 'Passe o mouse nas colunas',
segBg: this.state.seg ? (this.state.seg.endsWith('r') ? '#1A1AFF' : '#F59E0B') : '#F2F2F2',
segFg: this.state.seg ? (this.state.seg.endsWith('r') ? '#FFFFFF' : '#0A0A2E') : '#5C5C7A',
hovR: () => this.setState({ slice: 'r' }), hovO: () => this.setState({ slice: 'o' }), hovOff: () => this.setState({ slice: null }),
```

### 5.7 Port para vanilla (fora do Claude Design)
Para reproduzir sem o runtime DC: (a) manter `<deck-stage>` (ou equivalente com escala §1.1 e evento `slidechange`); (b) trocar `{{ }}`/`sc-*` por DOM manual: `onclick` que preenche e mostra o `<aside>`; `mouseenter/leave` que alteram `style.opacity` das células e `borderColor`; (c) `style-hover` → regra CSS `:hover` com classe; (d) manter as funções `activate/play/count/loop/transition/wipe/settle/reset/repaint` literalmente — elas só usam DOM + WAAPI.

---

## 6. Transição entre slides e navegação

### 6.1 Transição normal (`transition`)
```js
transition(slide, dir) {
  slide.animate([{ opacity: 0, transform: `translateX(${dir * 90}px) scale(0.98)`, filter: 'blur(10px)' }, { opacity: 1, transform: 'none', filter: 'blur(0)' }], { duration: 650, easing: EASE });
  const sw = this.sweepRef.current;
  if (sw) sw.animate(dir > 0 ? [{ transform: 'translateX(-30vw)', opacity: 1 }, { transform: 'translateX(110vw)', opacity: 0.2 }] : [{ transform: 'translateX(110vw) scaleX(-1)', opacity: 1 }, { transform: 'translateX(-30vw) scaleX(-1)', opacity: 0.2 }], { duration: 620, easing: EASE });
}
```
- Slide novo entra deslizando 90px na direção da navegação, de 0.98 para 1, blur 10px→0, 650ms.
- Simultaneamente uma **faixa azul de luz** (22vw, gradiente transparente→azul) varre a tela da esquerda para a direita (avançar) ou espelhada da direita para a esquerda (voltar), 620ms, terminando com opacity .2.
- Conteúdo interno começa em `base = 120ms`.
- O slide antigo some instantaneamente (`display:none` via helmet) — não há cross-fade.

### 6.2 Cortina de ato (`wipe`)
```js
const ACTS = { 1: ['Ato 1', 'O incêndio'], 3: ['Ato 2', 'O que entregamos'], 11: ['Ato 3', 'O que vem agora'] };
wipe(index) {
  const el = this.wipeRef.current; if (!el) return;
  this.setState({ wipeAct: ACTS[index][0], wipeTitle: ACTS[index][1] });
  el.animate([{ clipPath: 'inset(0 100% 0 0)' }, { clipPath: 'inset(0 0 0 0)', offset: 0.35 }, { clipPath: 'inset(0 0 0 0)', offset: 0.65 }, { clipPath: 'inset(0 0 0 100%)' }], { duration: 1500, easing: EASE });
  [...el.children].forEach((c, i) => c.animate([{ opacity: 0, transform: 'translateY(30px)' }, { opacity: 1, transform: 'none', offset: 0.4 }, { opacity: 1, offset: 0.7 }, { opacity: 0, transform: 'translateY(-20px)' }], { duration: 1500, delay: i * 60, easing: EASE }));
}
```
- Dispara **só ao avançar sequencialmente** para o primeiro slide de um ato (`prev === index - 1`). Pular/voltar usa a transição normal.
- Linha do tempo (1500ms): 0–35% cortina azul `#1A1AFF` cobre da esquerda p/ direita; 35–65% segura tela cheia com "ATO 1" (14–22px, 700, 0.24em, uppercase `#E8E8FF`) + "O incêndio" (32–64px, 800, -0.03em); 65–100% descobre saindo pela direita. Textos sobem 30px, ficam, e saem subindo 20px (stagger 60ms).
- Conteúdo do slide começa com `base = 650ms` (revela-se por trás da cortina).
- Não há slide estático de "divisor de ato" — o divisor é essa cortina sobreposta.

### 6.3 Teclas
| Tecla | Ação | Quem trata |
|---|---|---|
| → / PageDown / Espaço / ↓ | próximo | deck-stage |
| ← / PageUp / ↑ | anterior | deck-stage |
| Home / R | primeiro slide | deck-stage |
| End | último | deck-stage |
| 1–9, 0 | ir ao slide 1–9, 10 | deck-stage |
| Toque metade esquerda/direita | anterior/próximo (ignora elementos interativos) | deck-stage |
| F | fullscreen toggle | script do deck |
| ESC | fecha painel se aberto; senão abre/fecha **overview** | script do deck (capture + stopPropagation) |

Outros recursos do deck-stage: overlay inferior central com contador (fade após 1800ms ocioso), rail de thumbnails à esquerda (no editor; some em apresentação/≤640px), `history.replaceState('#N')`, print = 1 página por slide, evento `slidechange {index, previousIndex, total, slide, previousSlide, reason}`, `postMessage({slideIndexChanged})`.

### 6.4 Notas do apresentador
Por slide em `data-speaker-notes="..."` (prioritário sobre o legado `<script type="application/json" id="speaker-notes">`). O deck-stage lê, mantém `_notes[]` e sincroniza a janela de notas do host via `postMessage`. Estilo das notas: frases curtas de roteiro + **instrução de interação** ("Clique nos cards", "Passe o mouse na legenda") + **ressalvas defensivas** ("meta batida por 0,01 d — se perguntarem…", "a soma por executor fecha em 57, não em 71", "curvas são ilustrativas").

---

## 7. Estrutura narrativa

| # | Slide | Ato | Fundo | Papel |
|---|---|---|---|---|
| 01 | Capa | — | hero escuro | Promessa: "Torre de Controle — Balanço do ciclo e plano para out–dez" + ticker com os 7 números-chave |
| 02 | O ponto de partida | **Ato 1 · O incêndio** (cortina) | claro | Problema → resolução em 3 frentes (antes/depois, 41 dias) |
| 03 | O tamanho do esforço | Ato 1 | claro | Escala do trabalho não planejado (80% fora do plano, waffle) |
| 04 | Resultados do ciclo | **Ato 2 · O que entregamos** (cortina) | escuro | 4 números-herói + faixa de KPIs |
| 05 | Linha do tempo | Ato 2 | claro | Evolução mês a mês (roadmap × demais) |
| 06 | Entregas por frente | Ato 2 | claro | Distribuição (treemap) + tipo/executor/esforço |
| 07 | Visibilidade, governança e custo | Ato 2 | claro | Ganhos qualitativos em 3 temas |
| 08 | A virada | **Ato 3 · O que vem agora** | escuro | Slide-tese/ponte: "Incêndio controlado. Agora é consolidar e escalar." |
| 09 | Prioridades out–dez | Ato 3 | claro | 4 prioridades com meta |
| 10 | Obrigado | — | hero escuro | Fecho com a frase-síntese + perguntas + autor |

Ritmo de fundos: escuro → claro, claro → **escuro** (abre Ato 2) → claro ×3 → **escuro** (abre Ato 3) → claro → escuro. Os slides escuros marcam pontos de virada/abertura de ato; a capa e o obrigado são espelhos (mesmo ornamento).

Regras de escrita dos títulos:
- H2 curto (3–6 palavras), formato **contexto leve (300, cinza `#9C9CB4`) + conclusão pesada (800, azul)**: "Começamos | apagando incêndio", "Resultados em | quatro números", "Entregas | mês a mês", "71 entregas em | 11 frentes", "Ganhamos visibilidade, | governança e custo", "Out–dez: | 4 prioridades".
- Quando o número É a mensagem, ele vem primeiro como accent: "**80%** do trabalho veio de fora do plano".
- Título é uma afirmação (o "so what"), não um rótulo de tópico; o `data-label` é o rótulo de tópico ("Linha do tempo").
- Kicker sempre `NN · Ato N · Nome do ato` — numera e situa o slide no arco.
- Cada slide fecha com uma frase-conclusão quando há gráfico ("Absorvemos sustentação e repriorizações sem parar o roadmap.", "O roadmap avançou todo mês, mesmo com 3 em cada 4 entregas vindo de fora do plano.").
- Números sempre com unidade/contexto explícito e fonte (painéis citam `F1`/`F2`); números ilustrativos são declarados ("Curvas ilustrativas").
- Frase-síntese do deck reaparece no fecho: "Do apagar incêndio à **evolução planejada**."

---

## 8. Peculiaridades / bugs do export (decidir se replica)

1. **`ACTS` com índice 11** para o Ato 3: o deck tem 10 slides (índices 0–9), então a cortina do Ato 3 **nunca dispara**. O slide "A virada" é o índice 7 → para corrigir: `7: ['Ato 3', 'O que vem agora']`. (Sobra de uma versão com 14 slides — confirmada por `total: 14` no estado inicial e no fallback de `progW`.)
2. Código morto de slides removidos: `TIPS`/`tg`/`tip` (tooltips), painéis `p_estab`, `p_ias`, `p_set`, `c_sync`…`c_metr`, e a regra de spin `section[data-label^="Conquista 2"]` → origem `550px 330px`. Também `data-type`, `data-ripple`, `data-wave`, `data-flow`, `data-blink` não aparecem em nenhum slide. JetBrains Mono carregada e não usada.
3. Legenda "Demais demandas" do slide 05 declara `background-size` duas vezes (`34px 34px` e depois `12px 12px`; vale o último).
4. Tiles do treemap: só Dashboard tem `transition:filter 200ms`; os outros trocam o hover sem transição.
5. Cards do slide 07 são clicáveis mas não têm feedback de hover (só cursor).
6. Slide 10 não tem `data-om-slide-id` (duplicado da capa à mão).
7. Fonte mínima 24px dentro do canvas; painel/overview usam 14–28px porque estão fora do canvas escalado (em px de tela).
