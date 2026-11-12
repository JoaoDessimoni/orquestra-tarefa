# Gráficos interativos

Sem biblioteca. Barras são `div` em grid, linhas são SVG e a interação é feita com `mouseenter`/`mouseleave`/`click`. Tudo cresce com o motor (`data-gx`, `data-gy`, `data-rise`, `data-cell`, `data-reveal`, `data-fade`, `data-draw`, `data-count`).

**Toda área interativa precisa estar na lista de exclusão do clique de navegação** (no `closest(...)` do handler do `#vp`), senão clicar no gráfico troca de slide. **Instrução de interação no próprio slide** ("passe o mouse num período para ver o detalhe") e nas notas.

---

## 1 · Waffle 100 (ou N) com legenda que destaca

```html
<div class="waffle" id="waffle" data-split="1,3"></div>   <!-- 1 azul, 3 lilás, 96 cinza -->
<span class="hl" data-hl="c" data-hlc="#1A1AFF">…categoria C</span>
```
- Grid de **20 colunas**, gap 7px (Torre: 5px com 278 células), células `aspect-ratio:1; border-radius:6px`, geradas por JS com `data-cell` (entram em onda) e `data-k` (fatia).
- Hover na legenda: as células de outras fatias vão a `opacity:.15` e a borda da legenda ganha a cor da fatia (250ms).
- Ao lado, sempre o número grande da conclusão (120px na cor da perda) + "de cada 100 …".
- Torre: 1 quadrado = 1 demanda real (278); legenda "1 quadrado = 1 demanda finalizada · 278 no total".

## 2 · Colunas empilhadas com listras (linha do tempo)
- Para cada período: pílula/valor do total no topo (`data-count`), pilha com **[topo "demais" listrado, base "do plano" azul]** nessa ordem no DOM, ambos com `data-rise`. A base sobe primeiro e o topo vem 650ms depois.
- Base com `border-top:3px solid` (separador); topo com `box-shadow: inset 0 3px 0 rgba(255,255,255,.35)` e `data-stripe`.
- Tooltip no hover (24/700, navy, raio 16) **ou** a variante da Torre: pílula fixa acima do gráfico que troca o texto ("Set · Demais: 103 de 132 (78%)") e a cor (azul para o plano, âmbar para o resto).
- Eixo Y opcional: linhas tracejadas `2px dashed #E1E1EA`, base `3px solid #0A0A2E`, rótulos 24px `#9C9CB4`. Escala fixa: `px = valor × (altura / máx)`.
- Selo de destaque (`data-pop`): "Set: +89% vs ago" verde.

## 3 · Gráfico em camadas com alternador (padrão Relatório)

Estrutura (`drawChart()` no template):
```
.plot (position:relative; flex:1; border-bottom:2px solid #E6E6EE)
 ├─ .ly  bandas de hover       (grid N colunas; .bd.on = #F0F0FF, raio 10 no topo, sobra 12px acima)
 ├─ .ly  barras | pilha        (ou SVG da linha + .ly de pontos HTML)
 └─ .ly  hit-areas (z-index:3) → mouseenter injeta o tooltip
.xax (mesmo grid) rótulos 30/800 (22px se N > 12)
```
- **Altura:** `h = valor / máx × 82%` (os 18% de folga são para os rótulos).
- **Colunas:** 2 barras por período (38% de largura, máximo 92px, gap 6%): Protocolos `#0A0A2E` e Resolvidos `#0099FF`, rótulo `data-pop` acima (o azul-claro usa `#0070C0` no texto), barra `data-gy`.
- **Pilha:** 1 barra (72%, máximo 150px), `flex-direction:column-reverse`, fatias em % da própria barra: IA `#1A1AFF` · Transbordo `#F59E0B` · Transferência `#10B981`. Rótulo interno só se a fatia for ≥ 18%.
- **Linha:** SVG `viewBox 0 0 1000 300`, `preserveAspectRatio="none"`, `data-reveal`; áreas `data-fade` com `opacity` 0.07 (navy) e 0.22 (azul-claro); traços de 5 e 6px com `vector-effect="non-scaling-stroke"`; **pontos em HTML** (24px, borda 4px) por cima, em `left:50%; bottom:h%`. Curva suave (Catmull-Rom → Bézier, tensão 1/6):
```js
const smooth = pts => pts.map((p,i) => { if (!i) return 'M'+p[0]+','+p[1]; const p0 = pts[i-2]||pts[i-1], p1 = pts[i-1], p3 = pts[i+1]||p;
  const c1 = [p1[0]+(p[0]-p0[0])/6, p1[1]+(p[1]-p0[1])/6], c2 = [p[0]-(p3[0]-p1[0])/6, p[1]-(p3[1]-p1[1])/6];
  return 'C'+c1.map(v => v.toFixed(1))+' '+c2.map(v => v.toFixed(1))+' '+p[0]+','+p[1]; }).join(' ');
// x no centro da coluna: (i+.5)*1000/N ; y = 300 - valor/máx*82*3
```
- **Hover:** a banda da coluna acende, as outras colunas vão a `opacity:.45` (200ms, `cubic-bezier(.25,1,.5,1)`) e o tooltip abre **para dentro do gráfico**: `i < N/2 ? 'left:calc(100% - 4px)' : 'right:calc(100% - 4px)'`.
- **Tooltip:** navy, 360px, raio 16, padding `20px 24px`, 24px, sombra `0 12px 32px rgba(10,10,46,.28)`. Linhas "rótulo cinza ↔ valor 800 colorido" e um divisor `#23235A` antes da métrica-síntese (Acurácia).
- **Alternador** (`.seg`): trilho `#F2F2F2` raio 14 padding 4; botões 24/700 padding `10px 20px` raio 10; ativo branco com texto azul. Trocar → `drawChart()` + `replayChart(plot)` (cresce de novo, mais rápido: 800ms, stagger de 60ms).
- **Densidade** (série longa): `showVals = N <= 12`, `showDots = N <= 45`, raio da barra `3px` se N > 40, rótulo do eixo a cada `ceil(N/11)` colunas.
- Mês parcial marcado com asterisco (`Out*`) e explicado no rodapé.

## 4 · Funil interativo
- Linhas em grid `200–340px 1fr 80–90px`: nome · barra **centralizada** de 40px raio 8 (largura `max(12%, v/T)`) · conversão da etapa em %.
- Escala de cor fixa: `#0F0F8C #1A1AFF #3A3AFF #5C5CFF #7A7AFF #A8A8FF #10B981` (a penúltima com texto navy, a última verde = aprovado).
- Hover numa etapa: as outras vão a `opacity:.35`, a ativa fica em 800, e a caixa de info (`#F2F2F8`, raio 14, ícone azul) explica a etapa. Ao sair, volta o texto-guia.

## 5 · Curvas "A virada" (tese)
Receita: cada curva = **área** com gradiente vertical (0.4/0.5 → 0) + **brilho** (mesmo path, traço de 22px, opacidade .18/.22) + **traço** de 8px `data-draw` (a 2ª com `data-d="500"`). As duas se cruzam no meio (350,250). Zona "futuro" com retângulo azul a 10%, linha tracejada branca na virada, pílula branca "A virada" no topo, ponto central pulsando, rótulos "Maturidade ↑" (branco) e "Incidentes ↓" (`#FCA5A5`), eixo do tempo "antes · reativo" / "depois · planejado". Card `#0E0E36` com borda `#2E2E6E`. **Sempre** com o rótulo "Curvas ilustrativas".

## 6 · Painel lateral a partir de qualquer elemento
Qualquer elemento com `data-det="chave"` abre `PANELS[chave]`. Serve para cards, tiles de treemap e até segmentos de gráfico. Coloque o dado detalhado e a fonte no painel, nunca no slide.

## 7 · Dados dirigindo o deck (padrão Relatório, opcional)
Quando o deck é um **relatório recorrente**, os dados entram embutidos (strings separadas por `|` ou JSON) e um motor de agregação recalcula tudo a partir de filtros globais (agente, cliente, canal, período). Mudar o filtro põe os contadores no valor final e repete a animação do slide ativo (`reset` + `play(active, 0)`). Regras de honestidade:
- Arredondamento que **fecha 100%** (método do maior resto) nas composições.
- Métrica sem quebra por filtro aparece como "—" + aviso "Só no recorte completo. Limpe os filtros para ver."
- Estado vazio: texto central 28/600 `#9C9CB4` ("Sem custo apurado no recorte.").
- O cabeçalho direito mostra o recorte ativo (`◆ Todos os agentes · 01/06 a 21/10`).
O código completo (agregação, `roundParts`, períodos dia/semana/mês, seletor de datas de dois meses) está em `origem/spec-relatorio.md` §4.7 e §5.
