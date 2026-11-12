# Catálogo de componentes

Todos estão no `template.html`, com as classes indicadas. Os valores vêm dos três decks de referência. A coluna "Slide do template" diz onde copiar.

## Mapa rápido — "quero mostrar X, uso Y"

| Quero mostrar… | Componente | Slide do template |
|---|---|---|
| Abertura com impacto | Capa com órbita + ticker | 01 |
| Os N blocos da conversa (mapa) | Cards de entrega `.ec` + faixa da mensagem `.msg` | 02 |
| Como um produto funciona | Passos `.step` + celular vivo | 03 |
| Um número que choca + o funil por trás | Waffle 100 + `.statrow` + `.stk` | 04 |
| De onde vem → o que faz → onde aparece | Fluxo `.flow` com ponto viajando | 05 |
| Distribuição em faixas com leitura | Barra `.stk` + linhas `.band` | 05 |
| Tela real da ferramenta | Carrossel `.carr` | 06 |
| Ranking (top 5) | Barras `.hb` | 06 |
| Agente de IA conversando | WhatsApp `.wa` + `.feat` + `.clnum` | 07 |
| 4 resultados-herói | KPI cards `.kpi` em slide `.dk` | 08 |
| Série no tempo, explorável | Gráfico interativo (Colunas/Pilha/Linha) | 09 |
| Etapas com perda | Funil interativo `.fr` | 09 |
| Volume mês a mês com parte "do plano" | Colunas empilhadas listradas `.cols` | 10 |
| Itens com detalhe sob demanda | Cards `[data-det]` + painel lateral | 10 |
| A frase-tese, o antes × depois | "A virada" (2 curvas cruzando) | 11 |
| Encerramento | Obrigado + próximos passos + autor | 12 |

---

## 1 · Base

```css
.hdr  /* kicker 24/600 .1em MAIÚSCULAS #5C5C7A + <b> "◆ Squad IA" 700 azul sem caixa alta */
.h2   /* 72px -0.03em lh1.05; spans .g (300 #9C9CB4) e .k (800 #1A1AFF) */
.cw   /* card branco raio 24 */
.cd   /* card branco raio 24 com borda 2px dotted #1A1AFF — para o PARÁGRAFO EXPLICATIVO do slide */
.lab  /* label 22px 700 .08em MAIÚSCULAS #5C5C7A */
.big  /* número 800, -0.04em, lh .95 */
.para /* 28px lh1.4; <b> em azul */
.foot /* rodapé absoluto bottom:36px, 20px #5C5C7A, itens separados por .dotsep (bolinha 6px #C8C8D4) */
.chip + .c-ok/.c-bl/.c-wa/.c-bad   /* pílula 20px 700 raio 999 padding 5px 14px */
.code /* código do roadmap: 18px 800 branco sobre azul, raio 6, .06em — "R18" */
.note-warn /* ressalva: #FEF3C7, texto #78350F, raio 18, 22px, começa com <b>Ressalva:</b> */
```
Rodapé padrão de slide de entrega: `<span class="code">R18</span> Quimera #7317 · Dev · 16/09 → 22/09/2026 · recorte`.

## 2 · Capa / Obrigado (`.dark`)
- `.dotbg`: pontos `#23235A` 1.5px a cada 40px.
- `.orbit`: SVG 980×980 em `right:-120px; top:50%; margin-top:-490px`. Anéis r=460 (estático `#23235A`), r=380 tracejado `4 14` azul com satélites (r12 azul em 490,110; r7 lilás em 870,490) `data-spin="90"`, r=290 `#3A3A8C` com satélites (r10 branco; r6 azul) `data-spin="-60"`, r=200 `120 40 20 40` azul 3px `data-spin="40"`, núcleo r=120 azul `data-pulse`. Rótulo central 44/800 branco. *(Relatório: satélite verde `#10B981` e centro "3 IAs" 56/800 + "5 instâncias" 24/600 `#E8E8FF`.)*
- `.cv-top` (top:96px): "Tema · Squad IA" à esquerda, `◆ Squad IA` à direita (`z-index:2`, fica acima da órbita).
- `.cv-main` (top:270px, largura 1120, gap 40): `.pillb` (pílula azul 24/600 com o período) → `h1.cv-h1` (palavras `data-w`) → subtítulo 34px `#C8C8D4`.
- `.ticker`: faixa azul de 88px no rodapé, itens 26/600 brancos com gap de 64px separados por `◆`, **lista duplicada**.
- Obrigado: h1 200–220px "Obrigado" + "." lilás · parágrafo 40–44/300 `#C8C8D4` com a mensagem central e a parte forte em 800 branco · "Próximos passos" (22/700 lilás `.12em`) + chips `#16163F` 22px · autor em `left:120px; bottom:90px`: foto 96–104px circular com borda 3px azul, "CRIADO POR" 22/600 `.12em`, nome 36/800, cargo 22px.

## 3 · Card de entrega do resumo (`.ec`)
Branco, raio 24, padding `30px 28px 26px`, **faixa de 8px no topo** na cor da entrega, círculo numerado de 48px, título 29/800, chip de status, número 84px na cor da entrega + legenda 24/600, e no pé **Antes** (`#FEF2F2`) / **Depois** (`#ECFDF5`). Hover sobe 6px com sombra `0 18px 40px rgba(26,26,255,.14)`. `data-go="i"` leva ao slide. Abaixo dos cards, a `.msg` (faixa navy de raio 20, 34px peso 300, segunda metade em 800) traz a **mensagem central**.
*(Variante Torre, "ponto de partida": mesmo card com "RESOLVIDO EM" + data 76px `data-pop`, contador de dias, barra de progresso de 18px `data-gx` e antes/depois, clicável para o painel.)*

## 4 · Passos sincronizados (`.step`)
Grid `56px 1fr`, padding `18px 24px`, raio 20, fundo `rgba(255,255,255,.55)`. Círculo navy de 56px. `.lit`: fundo branco, borda azul de 2px, `translateX(12px)`, círculo azul, sombra `0 14px 30px rgba(26,26,255,.12)`, transição de 450ms.

## 5 · Números
- `.statrow`: card branco, grid `auto 1fr`, número 96px azul + título 30/700 + sub 23px. Use 3 empilhados para um funil narrado.
- **KPI card** (`.kpi`, em slide `.dk`): branco, raio 24, padding `40px 32px`, label no topo, bloco no pé com número **128px** + sufixo 48px, frase 34/700 e caption 24px. `.kpi.inv` = azul com textos `#E8E8FF`. Embaixo, a faixa de KPIs secundários: grid de 4 a 5 colunas, `border-top:1px solid #23235A`, números 44px lilás.
- **Faixa navy de números** (`.clnum`): 3 números de 64px + parágrafo com `border-left:2px solid #23235A`.
- **Pílula KPI** (Torre): navy, raio 999, número 48px verde `data-count` + texto 24/600, `data-pop`.
- **Card de insight escuro** (Relatório): `#10103A`, borda 2px `#23235A`, faixa de cor de 8px, número 88px + "%" 40px, "≈ N protocolos", título 32/800, citação em itálico do cliente, rodapé com ícone de raio e a **ação proposta**. Hover: fundo `#16164A` e borda na cor do card. Ordem: número → tamanho → problema → voz do cliente → ação.
- **Antes → depois** (Relatório): número 64px `#9C9CB4` → seta 36/300 → número 64px `#EF4444`.

## 6 · Barras
- `.stk`: barra empilhada (flex = valor, rótulo interno), altura 44–56px, raio 12, segmentos `data-gx`. Segmento pequeno com `min-width:64–70px` para caber o rótulo.
- `.hb`: ranking em grid `250px 1fr 150px`, trilho de 22px `#F2F2F2`, preenchimento azul `data-gx` com `width` em %, valor 800 tabular.
- **Barra 100% de composição** (Relatório): 32px de altura, raio 10, rótulo interno só se o segmento for ≥ 12%.
- **Listrada "fora do plano"**: classe `.stripe` + `data-stripe` (âmbar com listras de 135° a `rgba(255,255,255,.22)` 12px, 34×34, deslizando).
- `.band`: linha de faixa, grid `150px 130px 1fr` (selo colorido · % grande + n · leitura com ação em azul).

## 7 · Fluxo (`.flow`)
Caixas navy `.fb` (22/700 + small 18px `#C8C8D4`), a do meio em azul. Entre elas, setas `.ar` (46×4px `#D8D8E5`) com bolinha azul de 12px `data-flow="34,0"`; a segunda com `data-fd="600"`.

## 8 · Cards temáticos e de prioridade (Torre)
- **Trio temático** branco / navy / azul: label → título 72/800 (azul / lilás / branco) → descrição 26/500 → lista com divisores (`#E5E5EE` / `#23235A` / `#4D4DFF`) ancorada no pé.
- **Card de prioridade**: "01" + pílula "Esforço XL" → título 44/800 → itens 26/600 com divisor → **caixa "META"** no pé (`#0F0F8C` no azul, `#E8E8FF` no branco, `#1A1A4A` no navy). Hover sobe 6px. Sequência de fundos azul / branco / branco / navy.

## 9 · Treemap manual (Torre)
Flex aninhado com `flex:N` = contagem, gap 8, tiles com raio 14 e nome em cima + número embaixo. Cor por tamanho: maior = `#1A1AFF` (número 160px); 7 a 9 = `#0F0F8C` / `#4D4DFF` / `#7A7AFF`; 4 a 5 = `#E8E8FF` com borda pontilhada; até 3 = branco pontilhado. Tile estreito usa texto vertical (`writing-mode:vertical-rl; transform:rotate(180deg)`). Tiles `data-pop` e clicáveis para o painel.

## 10 · Painel lateral de detalhe
Modelo de dado: `{eyebrow, big, title, desc, items:[{d,t}], fonte}`. `d` é uma data ("24/06"), um valor ("2,13 d"), "•" ou "—". **Toda entrada tem `fonte`.** Aside branco de `min(560px,92vw)`, `border-left:3px solid #1A1AFF`, scrim `rgba(10,10,46,.45)`. Entra deslizando 420ms, e os filhos entram da direita com stagger de 50ms. Fecha com o scrim, "Fechar ✕", ESC ou troca de slide. O card clicado recebe `.sel` (borda sólida).

## 11 · Ícones
SVG inline 24×24, `fill="none" stroke="#1A1AFF" stroke-width="2" stroke-linecap="round"`, dentro de um quadrado de 40px raio 11 `#E8E8FF`. Desenhos usados: seta (`M5 12h14M13 6l6 6-6 6`), lista, microfone, check (`M5 12.5l4.5 4.5L19 7.5`), interrogação, pessoa. *(O Relatório usa a fonte Phosphor; no padrão vanilla, desenhe o SVG.)*
