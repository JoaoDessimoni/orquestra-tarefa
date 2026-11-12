# Mockups animados — o celular, o WhatsApp e o carrossel

São as telas que "se mexem sozinhas" enquanto o apresentador fala. É o que mais impressiona no deck do Q3. Os três estão prontos no `template.html` (slides 03, 06 e 07). Este guia explica **como funcionam** e **como roteirizar outro fluxo**.

Regra geral: o mockup é uma **demo gravada que roda ao vivo**. Ele usa um app de verdade (HTML real com eventos de clique), e um roteiro com tempos aperta os botões. Não é um GIF nem um vídeo, então o público pode interagir também.

---

## 1 · Celular com dedo simulado (padrão "link de pagamento")

### 1.1 Moldura
```html
<div class="phwrap" data-a="1" style="display:flex;justify-content:center;align-items:flex-start;position:relative">
  <div class="phone app" id="phone"><div class="phone-in">
    <span class="island"></span>
    <div class="status"><span>9:41</span><span class="sbars"><i></i><i></i><i></i><b></b></span></div>
    <div id="approot"></div>            <!-- o app é montado aqui -->
    <div class="tapdot" id="tapdot"></div> <!-- o "dedo" -->
  </div><span class="sim">simulação</span></div>
</div>
```
Medidas: celular **380×772**, borda **11px `#14161c`**, raio **54px** (interno 43px), ilha 100×28 em `top:9px`, status bar 44px com "9:41", barras de sinal e bateria. Sombra `0 34px 70px -24px rgba(10,10,46,.5)`. O selo "simulação" fica 36px acima, à direita, 16px/700/`.12em`/MAIÚSCULAS.

Layout do slide: grid `minmax(0,1fr) 380px`, gap **72px**. À esquerda: card pontilhado com o que é, **passos numerados** (`.step`) e o seletor de marca. À direita: o celular.

### 1.2 O app dentro (`mountApp`)
- Tokens **escopados** em `.app` (o produto real tem a própria paleta: `--primary: hsl(226 100% 40%)` na Finza e `hsl(45 100% 51%)` com `data-palette="yellow"` na Blips/Ideal). O amarelo nunca sai do celular.
- Fundo do app com grade quadriculada de 28px (`--grid`), fonte Inter e JetBrains Mono para códigos.
- Telas como funções que reescrevem `.a-screen`: `gate()` (código de 4 dígitos), `home()` (card urgente com faixa vermelha "Vencido há 3 dias", valor 40px/800, card pequeno, aviso azul, lista agrupada "faltam 14 de 24"), `ask()` (folha "Você já pagou a parcela 11?"), `pay(method)` (folha com alternador Pix/Boleto, QR desenhado em canvas 33×33 com semente fixa e botão Copiar).
- **Folha inferior (bottom sheet):** `.a-sheet` com `transform:translateY(100%)` e `#approot.open .a-sheet{transform:none}` em 280ms `cubic-bezier(.22,1,.36,1)`, com fundo escurecido `hsl(220 30% 8% / .5)`.
- **Toast:** pílula escura que sobe 16px no rodapé por 1,6s ("Código copiado").
- Cards entram com `a-rise` (sobem 8px, stagger de 70ms via `--i`).
- Resets dentro do mockup **sempre com `:where()`** (`#approot :where(button){color:inherit}`), senão a especificidade do id apaga a cor dos botões.

No deck do Q3 o app é o **protótipo real** do produto ("Link do Cliente", função `mountLink`, cerca de 300 linhas) colado inteiro. Para um produto seu, o caminho mais fiel é o mesmo: cole o protótipo, escope os tokens numa classe e exponha uma função `mount(root, {start, brand})`.

### 1.3 O dedo (`tapAt`)
```js
function tapAt(el, t, then){
  later(() => { if (!el || !el.isConnected) return;
    const pin = el.closest('.phone-in'), a = el.getBoundingClientRect(), b = pin.getBoundingClientRect(), k = b.width / pin.offsetWidth || 1;   // k = escala do palco
    dot.style.left = ((a.left-b.left)/k + a.width/k/2)+'px'; dot.style.top = ((a.top-b.top)/k + a.height/k/2)+'px'; dot.classList.add('on'); }, t);
  later(() => dot.classList.add('press'), t+600);                         // aperta
  later(() => { dot.classList.remove('press'); if (then) then(); }, t+780); // solta e clica
  later(() => dot.classList.remove('on'), t+1100);                        // some
}
```
```css
.tapdot{position:absolute;width:44px;height:44px;border-radius:50%;background:rgba(26,26,255,.22);border:2px solid rgba(26,26,255,.65);z-index:40;pointer-events:none;opacity:0;transform:translate(-50%,-50%);
  transition:left .55s cubic-bezier(.2,.8,.2,1),top .55s cubic-bezier(.2,.8,.2,1),opacity .25s,transform .15s}
.tapdot.on{opacity:1}.tapdot.press{transform:translate(-50%,-50%) scale(.7)}
```
O dedo **desliza** até o alvo (550ms), **aperta** (escala .7 por 180ms), **dispara o clique real** (`b.click()`) e some. O clique simulado não tem `isTrusted`, então o handler de navegação do deck o ignora.

### 1.4 O roteiro (`phoneDemo`) — linha do tempo do Q3

| ms | Ação | Passo aceso |
|---|---|---|
| 0 | monta o app na tela de acesso | 1 · Acesso seguro |
| 700 / 1080 / 1460 / 1840 | digita 0 · 1 · 7 · 1 (um dígito a cada **380ms**) | 1 |
| 2600 | entra na home | 2 · Vê o que deve |
| 3600 | rola suave até o aviso da janela de 20 dias | 2 |
| 5600 | rola de volta ao card principal | 2 |
| 6400 | dedo toca "Pagar" na **parcela 12** → abre "Você já pagou a 11?" | 3 · Regra de negócio |
| 9200 | dedo toca "Pagar a parcela 11 primeiro" → folha do Pix | 3 |
| 11400 | dedo toca "Copiar código Pix" → toast | 4 · Paga na hora |
| 13400 | dedo toca "Boleto" → linha digitável | 4 |
| 17000 | recomeça do zero (loop) | — |

Ritmo: **um evento a cada 2 a 3s**, tempo de o apresentador dizer uma frase. Cada mudança de tela **acende o passo** correspondente à esquerda (`lit(n)`: fundo branco, borda azul, desloca 12px para a direita, círculo fica azul, sombra azul suave, transição de 450ms).

### 1.5 Seletor de marca
Botões-pílula (`.brandsel`) com bolinha de cor. O clique faz `stopPropagation`, troca `brand`, limpa os timers e **reinicia a demo** com a nova paleta. Mostra que o mesmo produto serve várias empresas.

### 1.6 Como roteirizar outro fluxo
1. Liste 3 a 5 passos de negócio (eles viram os `.step`).
2. Para cada passo, defina a tela e **o gesto que leva a ela** (digitar, rolar, tocar).
3. Distribua no tempo: comece em 700ms, deixe 2 a 3s por passo e feche o ciclo em 15 a 20s.
4. Use só `later()`, `tapAt()` e `scrollTo()`. Termine com `later(() => { if (demoOn) minhaDemo(); }, T)`.
5. Com redução de movimento ligada, mostre direto a tela mais representativa.

---

## 2 · WhatsApp que conversa sozinho (padrão "Clara")

### 2.1 Moldura
```html
<div class="wa">
  <div class="wa-h"><div class="av">C</div><div><div class="nm">Clara · Finza</div><div class="st" id="wa-st">online</div></div></div>
  <div class="wa-b" id="wa">
    <div class="bub">Fala do agente…<small>10:14</small></div>
    <div class="bub me">Fala do cliente…<small>10:15</small></div>
    …
    <div class="typing"><i></i><i></i><i></i></div>
  </div>
</div>
```
Medidas: **440×720**, raio 32px, borda **10px `#14161c`**, fundo do chat `#EFEAE2`, cabeçalho `#1F2C34` com avatar azul de 44px. Bolhas: 18px, `line-height:1.38`, raio 12px, máximo 84% de largura, sombra `0 1px 1px rgba(0,0,0,.08)`. Agente em branco à esquerda; cliente `#D9FDD3` à direita; hora 12px `#667781` à direita. O corpo usa `justify-content:flex-end`, então a conversa cresce de baixo para cima como no app.

Elementos ricos: **áudio** (play azul-claro `#53BDEB` de 32px + 17 barrinhas de onda de 3px com alturas `6,12,18,9,15,20,11,7,16,13,8,18,10,6,14,9,12` + "0:09") e **anexo** ("📄 conta-luz.pdf").

### 2.2 O roteiro (`waDemo`)
```js
let t = 300;
bubs.forEach(b => {
  const bot = !b.classList.contains('me');
  if (bot){ later(() => { ty.classList.add('on'); st.textContent = 'digitando…'; }, t); t += 1300; }   // 1,3s de "digitando"
  later(() => { ty.classList.remove('on'); st.textContent = 'online'; b.classList.add('show');
                requestAnimationFrame(() => requestAnimationFrame(() => b.classList.add('in'))); }, t);   // 2 rAF: display antes da transição
  t += bot ? 1600 : 1800;     // tempo de leitura
});
later(waDemo, t + 4000);      // segura a conversa completa 4s e recomeça
```
- Antes de cada fala do agente: os **três pontinhos** pulam (`tp`, 1s, defasagem de 150ms) e o status vira **"digitando…"**.
- A bolha aparece com fade + subida de 12px (400ms).
- O cliente responde sem "digitando" (é o outro lado).

### 2.3 Como escrever a conversa
- 5 a 8 bolhas. Mostre **o comportamento que diferencia o agente**: ele começa a conversa, pede uma coisa por vez, entende áudio/foto/PDF, confirma o que leu ("Rua das Flores, 210. Confere?") e registra ("Recebi e registrei ✓").
- Nomes e endereços fictícios. Rodapé: "Conversa ilustrativa".
- Ao lado, grid 3×2 de **funcionalidades** (`.feat`: ícone SVG de traço em quadrado `#E8E8FF`, título 23/800, descrição 19px) e a **faixa de números** escura (`.clnum`: 3 números de 64px + parágrafo honesto com a perda e a causa).

---

## 3 · Carrossel de prints reais (padrão "Custos")

```html
<div class="carr" id="carr">
  <div class="cbar"><span class="cdots3"><i></i><i></i><i></i></span><span class="curl">Torre de Controle · Custos</span>
    <span class="cnav"><button data-c="0"></button><button data-c="1"></button><button data-c="2"></button></span></div>
  <div class="cview">
    <figure class="cs"><img src="data:image/jpeg;base64,..." alt="…"></figure> …
    <span class="ctag">Tela real da Torre · 08/10 a 06/11</span>
  </div>
</div>
```
- Janela de navegador: barra de 46px `#F2F2F6`, 3 bolinhas de 12px, URL central em caixa branca, raio 20px, sombra `0 24px 50px -24px rgba(10,10,46,.35)`.
- Área do print: **878×508**, `object-fit:cover; object-position:top left`.
- Navegação: 3 traços de 34×8px. O ativo se **preenche em 6,5s** (`cfill`, linear); os anteriores ficam cheios (`.done`).
- `carShow(i)` faz cross-fade de 800ms e agenda o próximo em 6.500ms, só enquanto o slide estiver ativo. Clique no traço pula (com `stopPropagation`).
- Selo azul no canto: "Tela real · período". **Print real sempre leva data.**
- Para gerar o base64: `base64 -w0 print.jpg` (prefira JPEG em qualidade 80 e largura de cerca de 1760px, o dobro da área, para nitidez no projetor).

O Q3 preparou um zoom lento estilo Ken Burns (`@keyframes kb` com `--fx/--fy/--z` por print), mas deixou desligado. Para ativar: `.cs.on img{animation:kb 6.5s ease-in-out forwards;transform-origin:var(--fx,50%) var(--fy,30%)}`.

---

## 4 · Outros mockups possíveis no mesmo padrão

| Mockup | Base | Receita |
|---|---|---|
| Tela de sistema (desktop) | `.carr` com HTML vivo no lugar do `<img>` | mesma janela, conteúdo HTML com `data-a`/`data-count` |
| Fluxo de eventos ("cada clique vira dado") | celular + `.flow` | a cada `tapAt`, crie um chip que voa para a direita com `animate` translate+fade (800ms) |
| Painel de agente (n8n, Torre) | `.carr` + `.tapdot` | o mesmo `tapAt` funciona em qualquer contêiner com `position:relative` (troque `.phone-in` pelo contêiner) |
