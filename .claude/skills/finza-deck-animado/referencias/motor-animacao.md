# Motor de animação — referência completa

O motor é o bloco `MOTOR` do `<script>` do `template.html`. Ele é **idêntico** entre os três decks de referência: Q3, Torre e Relatório. Os dois últimos rodavam o mesmo código dentro do runtime do Claude Design. **Não edite o motor.** Use os atributos.

---

## 1 · Princípios

1. **Web Animations API** (`el.animate(keyframes, options)`) para tudo. Keyframes CSS só nos loops internos de mockup (`tp`, `cfill`, `a-rise`).
2. **Easing único de entrada:** `const EASE = 'cubic-bezier(.2,.8,.2,1)'`, um ease-out rápido e macio. Hover e alternadores usam `cubic-bezier(.25,1,.5,1)` em 200ms.
3. **`fill:'backwards'`:** a animação aplica o 1º keyframe durante o atraso e depois solta. O estado final é o CSS. Sem JS, tudo aparece.
4. **Token de navegação `tok`:** cada `goTo` incrementa `tok`. Timers antigos checam o token e morrem.
5. **`later(fn, ms)` + `clearT()`:** todo timer de demo passa por `later`, e `goTo` chama `clearT()`. Sair do slide mata a demo na hora.
6. **Loops são únicos por elemento** (`el._loop`): `reset()` pausa, `play()` retoma. A órbita não "pula" ao revisitar.
7. **Rede de segurança:** 3.400ms depois de entrar, `settle()` faz `finish()` em tudo e põe os contadores no valor final. A aba voltando do segundo plano (`visibilitychange`) e o `resize` também chamam `settle`.
8. **`repaint()`:** força a re-rasterização do slide (contorna bug de GPU que deixa texto sem pintar).
9. **`prefers-reduced-motion: reduce`:** sem transição, sem cortina e sem `play()`; demos vão direto ao estado final; CSS zera `animation`/`transition`.

---

## 2 · Escala do palco

```js
function fit(){ stage.style.setProperty('--s', Math.min(innerWidth/1920, innerHeight/1080)); }
addEventListener('resize', fit); fit();
```
```css
#stage{position:absolute;left:50%;top:50%;width:1920px;height:1080px;transform:translate(-50%,-50%) scale(var(--s,1))}
```
Em `goTo`, `document.body.style.background = getComputedStyle(slide).backgroundColor` faz a sobra da tela (fora de 16:9) ter a cor do slide.
*(Os exports do Claude Design usam o modo `fill`, que estica o canvas na dimensão que sobra, com proporção entre 1,25 e 2,4. O efeito visual é o mesmo; o vanilla usa letterbox na cor do slide.)*

---

## 3 · `play(slide, base)` — tabela completa

`opt(d, dur) = {duration: dur||600, delay: base + d, easing: EASE, fill:'backwards'}` · `i` = índice do elemento **naquele atributo** dentro do slide, na ordem do DOM.

| Atributo | Keyframes | Duração | Atraso | Uso típico |
|---|---|---|---|---|
| `data-w` | `{opacity:0, translateY(60%), blur(8px)}` → normal | 700 | 200 + i·90 | palavras do H1 da capa/Obrigado, palavras da tese |
| `data-a` | `{opacity:0, translateY(32px)}` → normal | 600 | 80 + i·70 | **todo bloco**: título, cards, parágrafos, legendas |
| `data-pop` | `{opacity:0, scale .6}` → `{scale 1.04 @70%}` → `{scale 1}` | 600 | 300 + i·80 | pílula KPI, data grande, rótulo de gráfico, ponto |
| `data-gx` | `scaleX(0→1)`, origem `left center` | 900 | 350 + i·60 | barra horizontal, segmento de barra empilhada, funil |
| `data-gy` | `scaleY(0→1)`, origem `center bottom` | 900 | 350 + i·60 | coluna, mini-coluna, pilha vertical |
| `data-rise` | `clipPath inset(100% 0 0 0) → inset(0)` | 650 | 300 + col·120 (+650 no topo) | coluna empilhada: **escreva [topo, base] por coluna**; a base (índice ímpar) sobe primeiro |
| `data-cell` | `{opacity:0, scale(.2)}` → normal | 420 | 250 + i·12 (Torre: i·6 para 278 células) | quadradinhos do waffle |
| `data-draw` | `strokeDashoffset L→0` (L = `getTotalLength()`) | 1500 | 500 + `data-d` | curvas SVG; a 2ª curva com `data-d="500"` |
| `data-type` | `clipPath inset(0 100% 0 0) → inset(0)` | 500 | 600 + i·450 | frases que "se escrevem" |
| `data-reveal` | `clipPath inset(-40px 100% -40px 0) → inset(-40px 0% -40px 0)` | 1400 | 200 | SVG da linha do gráfico |
| `data-fade` | `opacity 0 → atributo opacity` | 900 | 600 + i·150 | área sob a linha |
| `data-count` | contador rAF 0→valor, `1-(1-p)^3` | 1300 | base + 250 | todo número |
| `data-pulse` | loop `scale 1→1.08→1` ease-in-out, `transformBox:fill-box` | 2600 | — | núcleo da órbita, ponto da virada |
| `data-spin="N"` | loop `rotate 0→±360` linear, origem `490px 490px` | `abs(360/N)·6000` | — | anéis: 90 → 24s; −60 → 36s anti-horário; 40 → 54s |
| `data-ticker` | loop `translateX 0→-50%` linear | 40000 | — | faixa da capa (conteúdo 2×) |
| `data-flow="dx,dy"` | loop `translate 0→(dx,dy)` com fade nas pontas (15%/85%) | 1800 | `data-fd` | ponto viajando na seta de um fluxo |
| `data-stripe` | loop `backgroundPosition 0 0 → 34px 0` | 1600 | — | barra âmbar listrada ("fora do plano") |
| `data-ripple="k"` | loop `scale 1→3.8` + fade, `cubic-bezier(.25,1,.5,1)` | 4200 | k·1400 | ondas concêntricas (radar) |
| `data-blink` | loop opacidade 1→0→1 `steps(2)` | 1000 | — | cursor piscando |
| `data-wave="d,hot"` | (só Torre, não portado) ponto→quadrado aceso | 3600 | d·110 | grade "pulsando" |
| `data-donut` | (só Relatório, não portado) `strokeDasharray 0 100 → valor` | 900 | 450 + i·160 | rosca |

### Contador
```js
const fmt = (el, v) => { const d = +(el.dataset.dec||0); return v.toLocaleString('pt-BR',{minimumFractionDigits:d,maximumFractionDigits:d}); };
function count(el, delay){
  const t = parseFloat(el.dataset.count), dur = 1300;
  cancelAnimationFrame(el._raf); clearTimeout(el._to);
  if (document.hidden) { finalCount(el); return; }
  el.textContent = fmt(el, 0);
  el._to = setTimeout(() => { const st = performance.now();
    const step = n => { const p = Math.max(0, Math.min(1, (n-st)/dur)); el.textContent = fmt(el, t*(1-Math.pow(1-p,3))); if (p<1) el._raf = requestAnimationFrame(step); };
    el._raf = requestAnimationFrame(step); }, delay);
}
```
`data-count` usa **ponto** decimal (`6467.28`); a tela mostra vírgula (`6.467,28`). Escreva sempre o valor final como texto do elemento.
Prefixos e sufixos (R$, %, d, mil) ficam em `<span>` irmãos, fora do contador, com tamanho menor e a mesma cor.

---

## 4 · Ciclo de vida de `goTo(n)`

```
goTo(n)
 ├─ tok++ ; clearT() ; stopDemos() ; closeDrawer()
 ├─ reset() em todos os slides (cancela animações, pausa loops, contadores no valor final)
 ├─ mostra só o slide n (.on) ; cancela wipe/sweep em andamento
 ├─ fundo da página = fundo do slide ; body.isdark ; barra de progresso ; contador ; notas ; #hash
 ├─ act = slide.dataset.act && prev === n-1        ← cortina só avançando em sequência
 ├─ act ? wipe(label) : transition(slide, dir)
 ├─ play(slide, act ? 650 : 120)
 ├─ setTimeout(settle + repaint, 3400)  [se tok não mudou]
 └─ HOOKS[slide.id] → later(hook, act ? 1500 : 900)   ← demos vivas começam depois da entrada
```

O Relatório tem uma variação: **revisitar não repete a animação**, só retoma os loops (`WeakSet seen`). Use essa variação quando o deck for de consulta e não de palco. O padrão do template (Q3/Torre) repete a animação a cada entrada.

---

## 5 · Transição normal

```js
function transition(slide, dir){
  slide.animate([{opacity:0,transform:`translateX(${dir*90}px) scale(0.98)`,filter:'blur(10px)'},{opacity:1,transform:'none',filter:'blur(0)'}], {duration:650, easing:EASE});
  document.getElementById('sweep').animate(dir>0
    ? [{transform:'translateX(-30vw)',opacity:1},{transform:'translateX(110vw)',opacity:.2}]
    : [{transform:'translateX(110vw) scaleX(-1)',opacity:1},{transform:'translateX(-30vw) scaleX(-1)',opacity:.2}], {duration:620, easing:EASE});
}
```
```css
#sweep{position:fixed;top:0;bottom:0;left:0;width:22vw;z-index:1700;pointer-events:none;
  background:linear-gradient(90deg,rgba(26,26,255,0) 0%,rgba(26,26,255,.55) 70%,#1A1AFF 100%);transform:translateX(-30vw)}
```

## 6 · Cortina de ato

```js
function wipe(label){
  const el = document.getElementById('wipe'); const [a,t] = label.split('|');
  el.children[0].textContent = a; el.children[1].textContent = t;
  el.animate([{clipPath:'inset(0 100% 0 0)'},{clipPath:'inset(0 0 0 0)',offset:.35},{clipPath:'inset(0 0 0 0)',offset:.65},{clipPath:'inset(0 0 0 100%)'}], {duration:1500, easing:EASE});
  [...el.children].forEach((c,i) => c.animate([{opacity:0,transform:'translateY(30px)'},{opacity:1,transform:'none',offset:.4},{opacity:1,offset:.7},{opacity:0,transform:'translateY(-20px)'}], {duration:1500, delay:i*60, easing:EASE}));
}
```
```css
#wipe{position:fixed;inset:0;z-index:1800;background:#1A1AFF;color:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px;pointer-events:none;clip-path:inset(0 0 0 100%)}
#wipe span:first-child{font-size:clamp(14px,1.6vw,22px);font-weight:700;letter-spacing:.24em;text-transform:uppercase;color:#E8E8FF}
#wipe span:last-child{font-size:clamp(32px,5vw,64px);font-weight:800;letter-spacing:-.03em}
```
**Como escrever o rótulo:** `data-act="<linha de cima>|<nome do ato>"`. A linha de cima é curta e numerada ("Entrega 01", "Ato 2"). O nome é a ideia do ato em 2 a 5 palavras ("O incêndio", "O que entregamos", "O que vem agora", "Clara, agente de formalização").

## 7 · Pilha de camadas (z-index)

`#prog` 1500 · `#cnt`/`#fsh` 1600 · `#sweep` 1700 · `#wipe` 1800 · `#scrim` 1900 · `#panel` 1950 · `#notes` 1950 · `#ov` 1990. Tudo isso é `position:fixed`, fora do palco escalado: os tamanhos são em px de tela (13–22px), não de palco.

## 8 · Ganchos de demo (`HOOKS`)

```js
HOOKS['sl-phone'] = phoneDemo;      // celular
HOOKS['sl-carr']  = () => carShow(0); // carrossel
HOOKS['sl-wa']    = waDemo;          // WhatsApp
```
Para criar uma demo nova: dê `id` ao `<section>`, escreva a função com `later()` (nunca `setTimeout` solto, senão ela sobrevive à troca de slide) e registre em `HOOKS`. Para loop, a última instrução reagenda a própria função: `later(() => { if (demoOn) minhaDemo(); }, T)`.
