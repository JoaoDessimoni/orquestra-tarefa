---
name: finza-deck-animado
description: Padrão canônico das APRESENTAÇÕES ANIMADAS da Finza / Squad IA — deck HTML single-file em palco 1920×1080 com motor de animação por data-attribute (cascata, contadores, barras que crescem, curvas que se desenham), transição com blur + faixa azul, cortina azul de ATO, capa com órbita girando e ticker, mockups VIVOS (celular que navega sozinho com dedo simulado, WhatsApp que conversa com "digitando…", carrossel de prints), gráficos interativos (tooltip, alternador Colunas/Pilha/Linha, funil e legenda que reagem ao hover, painel lateral de detalhe) e narrativa em atos. É o padrão de "Entregas Q3/2026", "Torre de Controle · Balanço do ciclo" e "Relatório IAs Finza · Apresentação". Carregue SEMPRE que for criar, estender ou revisar um deck/apresentação/slide — inclusive via /novo-deck, /novo-slide, /revisar-deck e os agentes slide-*. NÃO é para dossiê de rolagem (finza-dossie) nem relatório .md (/relatorio).
---

# Finza · Deck animado

Esta skill ensina a produzir uma apresentação **idêntica** às três de referência do Squad IA:

| Deck | Arquivo | O que ele ensina melhor |
|---|---|---|
| **Entregas Q3/2026** (liderança) | `Apresentacoes/executando/entregas-q3_lideranca_06-11-2026.html` | **Mockups vivos**: celular do link de pagamento navegando sozinho, WhatsApp da Clara conversando, carrossel de prints. Vanilla puro. **Referência principal de animação.** |
| **Torre de Controle · Balanço do ciclo** | `Apresentacoes/executando/Torre de Controle - Balanço do ciclo.html` | **Narrativa em 3 atos** com cortina azul, card antes/depois, waffle com hover, colunas empilhadas listradas, treemap, curvas "A virada", painel lateral de detalhe. |
| **Relatório IAs Finza · Apresentação** | `Apresentacoes/executando/Relatorio IAs Finza - Apresentacao.html` | **Gráficos interativos dirigidos por dados**: alternador Colunas/Pilha/Linha, tooltip, funil com hover, cards de insight, filtros globais. |

Os dois últimos são exports do Claude Design (bundle com runtime React). **Não copie o bundle.** O padrão desta skill é **HTML + CSS + JS vanilla em um arquivo**, como o deck do Q3. Tudo o que os exports fazem já está portado para vanilla no `template.html`.

## Arquivos da skill

```
finza-deck-animado/
├── SKILL.md                         ← este guia (leia inteiro antes do 1º slide)
├── template.html                    ← DECK INICIAL FUNCIONAL: 12 slides, motor, 3 mockups vivos, gráficos. Copie e edite.
└── referencias/
    ├── motor-animacao.md            ← o motor linha a linha: data-attributes, tempos, transição, cortina, ciclo de vida
    ├── componentes.md               ← catálogo de componentes com HTML/CSS literal e quando usar cada um
    ├── mockups-animados.md          ← como roteirizar o celular, o WhatsApp e o carrossel (o "show")
    ├── graficos-interativos.md      ← waffle, barras, colunas, linha, funil, tooltip, alternador, painel, treemap
    ├── narrativa.md                 ← atos, títulos, voz, notas do apresentador, roteiro de um deck
    └── origem/                      ← engenharia reversa completa dos exports (valores literais, para consulta)
        ├── spec-torre.md
        └── spec-relatorio.md
```

**A pasta é autossuficiente.** Para compartilhar com outro colaborador, basta copiar `finza-deck-animado/` para `.claude/skills/` do projeto dele. Os três decks de referência ajudam, mas não são necessários: tudo o que eles fazem está no template e nas referências.

**Regra de ouro:** comece SEMPRE copiando `template.html`. Nunca reescreva o motor, a navegação ou os overlays do zero. Troque o conteúdo, apague os slides que não servem e duplique os que servem.

---

## 1 · Contrato do formato (não negociável)

1. **Um arquivo `.html`**, sem build. CSS e JS inline. Única dependência externa: Google Fonts (Inter 300–800 e JetBrains Mono 500/600, esta só dentro de mockups).
2. **Sem framework, sem lib de gráfico, sem lib de ícone.** Gráficos são `div` + CSS grid + SVG inline. Ícones são SVG inline de traço fino (`stroke-width:2`, `stroke-linecap:round`).
3. **Palco fixo 1920×1080** (`#stage`), escalado por JS: `scale(min(innerWidth/1920, innerHeight/1080))`. Todo tamanho é em **px de palco**. Nada de `vw`/`vh` dentro do slide.
4. **Imagens só embutidas** (`data:image/...;base64`): prints reais da ferramenta, foto do apresentador. Nunca `src` externo.
5. **O estado final é o CSS base.** Animação sempre vai *de* oculto *para* o estilo normal (`fill:'backwards'`). Sem JS, impresso ou com `prefers-reduced-motion`, tudo aparece pronto.
6. **Nada de número sem fonte.** Todo slide de dado tem rodapé `.foot` com fonte, recorte e ressalva. Mockup com dado fictício leva o selo "simulação" e o rodapé "dados fictícios".
7. **Nome do arquivo:** `<tema>_<destinatario>_DD-MM-AAAA.html` em `Apresentacoes/executando/`.

---

## 2 · Cores

Tokens do `:root` do template. **Não use cor fora desta tabela.**

| Token | Hex | Papel |
|---|---|---|
| `--blue` | `#1A1AFF` | Primária. Palavra forte do título, números-herói, barras "do plano", borda pontilhada, pílula da capa, ticker, barra de progresso, cortina de ato, sweep |
| `--deep` | `#0F0F8C` | Hover do azul, caixa "Meta" em card azul, 1ª etapa do funil |
| `--mid` | `#4D4DFF` | Divisores dentro de card azul, tile médio de treemap |
| `--lilac` | `#7A7AFF` | **Segunda cor de destaque.** Palavra final da capa, "." do Obrigado, números no fundo escuro, série secundária |
| `--soft` | `#E8E8FF` | Fundo de pílula azul, texto secundário sobre azul, trilho de barra |
| `--dark` | `#0A0A2E` | Fundo escuro, texto principal no claro, card navy, tooltip |
| `--ghost` | `#9C9CB4` | **Parte fina do título** (peso 300) |
| `--ghost2` | `#C8C8D4` | Texto secundário no escuro, parte fina da capa, barra neutra |
| `--muted` | `#5C5C7A` | Texto secundário no claro, kicker, labels |
| `--line` | `#D8D8E5` | Pontos do fundo claro, bordas finas |
| `--ok` | `#10B981` | Positivo, resolvido, meta batida |
| `--warn` | `#F59E0B` | Fora do plano, atenção, transbordo (pode ter listras) |
| `--bad` | `#EF4444` | Incidente, perda, correção, cancelado |
| navy 2/3/4 | `#16163F` `#23235A` `#3A3A8C` | Chips no escuro, divisores no escuro, anel médio da órbita |
| pontos escuro | `#1C1C4E` | Grade de pontos do slide escuro de conteúdo |

**Pares de pílula** (fundo/texto): ok `#D1FAE5/#047857` · azul `#E8E8FF/#1A1AFF` · atenção `#FEF3C7/#92400E` · ruim `#FEE2E2/#B91C1C`. Caixa "Antes" `#FEF2F2` (rótulo `#B91C1C`); "Depois" `#ECFDF5` (rótulo `#047857`, texto 700). Ressalva: fundo `#FEF3C7`, texto `#78350F`.

**Semântica fixa (respeite em todo gráfico):** azul = plano/IA resolveu/positivo · âmbar = fora do plano/transbordo · vermelho = incidente/perda · verde = resolvido/aprovado/transferência · lilás = secundário/futuro · navy = total. **Cor por agente:** Esperanza `#1A1AFF`, Valentina `#7A7AFF`, Clara `#0A0A2E` (em custos, `#10B981`), Tageador `#9C9CB4`. **Cor por entrega/ato no resumo:** 1 `#1A1AFF`, 2 `#7A7AFF`, 3 `#10B981`, 4 `#F59E0B`.

**Exceção controlada:** dentro de um mockup de produto (celular, print), use as cores **do produto** com tokens escopados na classe do mockup (ex.: amarelo Blips/Ideal `hsl(45 100% 51%)`). Nunca vaze para o slide.

---

## 3 · Tipografia

Só **Inter**. Pesos 300 · 400 · 500 · 600 · 700 · 800. **Piso de 24px** para texto de conteúdo. Abaixo disso, só o rodapé `.foot` e chips (20px) e o interior de mockups, que seguem a escala real do app.

| Elemento | Tamanho | Peso | Extras |
|---|---|---|---|
| H1 da capa | 120–136 | 300 nas palavras de contexto (`#C8C8D4`) + 800 nas de conclusão (branco, última em `#7A7AFF`) | `letter-spacing:-.04em`, `line-height:1`, cada palavra num `<span data-w>` |
| H1 do Obrigado | 200–220 | 800 branco + "." `#7A7AFF` | `letter-spacing:-.05em`, `line-height:.95` |
| **H2 de slide** (`.h2`) | 72 | `.g` 300 `#9C9CB4` + `.k` 800 `#1A1AFF` (branco no escuro) | `letter-spacing:-.03em`, `line-height:1.05`, `margin-top:28–32px` |
| H2 da tese ("A virada") | 92–96 | 300 + 800 | `letter-spacing:-.04em` |
| Kicker (`.hdr`) | 24 | 600 | `letter-spacing:.1em`, MAIÚSCULAS, `#5C5C7A` (`#C8C8D4` no escuro); à direita `◆ Squad IA` 700 azul (branco no escuro) |
| Número-herói | 96–160 | 800 | `letter-spacing:-.04em/-.05em`, `line-height:.9`; sufixo (%, d, mil) 40–56/800 na mesma cor |
| Label de card (`.lab`) | 22–24 | 700 | `letter-spacing:.08em`, MAIÚSCULAS, `#5C5C7A` |
| Frase de leitura | 28–36 | 700 | conclusão do slide, parte final em azul |
| Corpo (`.para`) | 26–28 | 400, termo-chave em `<b>` azul | `line-height:1.4` |
| Rodapé (`.foot`) | 20 | 500 | `#5C5C7A`, separado por `.dotsep` |

**Fórmula do título:** contexto leve (300, cinza) + conclusão pesada (800, azul). Quando o número **é** a mensagem, ele vem primeiro como destaque: "**96%** dos links vencidos nunca foram abertos". Título é afirmação, não rótulo. O rótulo vai no `data-label`.

---

## 4 · Estrutura do slide

```
section.s  (1920×1080)
├── tipos de fundo
│   ├── .dark   → capa / obrigado: #0A0A2E + .dotbg (pontos #23235A a cada 40px), SEM padding, tudo absoluto
│   ├── .light  → conteúdo: #F2F2F2 + pontos #D8D8E5 1.5px a cada 32px, padding 88px 120px 100px, flex column
│   └── .dk     → conteúdo escuro (abre ato / tese): #0A0A2E + .dotbg2 (pontos #1C1C4E a cada 32px), mesmo padding
├── .hdr        → "NN · Entrega/Ato N · Nome"  ………  "◆ Squad IA"
├── h2.h2       → título ghost + accent
├── corpo       → grid com minmax(0,1fr), gaps 24–72px, min-height:0
└── .foot       → absoluto em bottom:36px: fonte · recorte · ressalva · código (R18) · Quimera #
```

**Ritmo de fundos:** a capa e o Obrigado são espelhos (mesma órbita). Slides escuros marcam **abertura de ato** ou a **frase-tese**. O resto é claro. Nunca dois escuros de conteúdo seguidos sem motivo narrativo.

**Marca:** o `◆ iaf` do design system antigo foi substituído por **`◆ Squad IA`** no canto superior direito de todo slide (no Relatório, `◆ <recorte do filtro>`).

---

## 5 · As peças fixas do deck (já no template)

| Peça | Comportamento |
|---|---|
| **Barra de progresso** `#prog` | 4px no topo, trilho `rgba(200,200,212,.25)`, preenchimento azul, `width` anima 600ms |
| **Contador** `#cnt` | "N / M" no canto inferior direito, 13px; fica branco translúcido em slide escuro (`body.isdark`) |
| **Dica de tela cheia** `#fsh` | pílula navy no rodapé central, some após 6s ou no 1º gesto. O 1º clique ou tecla pede tela cheia |
| **Visão geral** `#ov` | ESC abre a grade de slides (cards 16:9 pontilhados, atual em azul). Clique vai ao slide |
| **Notas** `#notes` | tecla **N** mostra `data-notes` do slide (roteiro, instrução de interação, ressalva defensiva) |
| **Painel lateral** `#panel` | clique em card `[data-det]` abre o detalhe à direita (scrim + aside branco com borda azul 3px). ESC, scrim ou "Fechar ✕" fecham |
| **Sweep** `#sweep` | faixa de luz azul que atravessa a tela na troca de slide |
| **Cortina de ato** `#wipe` | tela azul cheia com "ATO N" + nome do ato |
| Fundo da página | assume a cor do slide ativo (sem tarja preta em tela fora de 16:9) |

**Navegação:** → Espaço PgDn Enter avançam · ← PgUp Backspace voltam · Home/End · F tela cheia · ESC visão geral (ou fecha o painel) · N notas · clique no ¼ esquerdo volta, resto avança · card com `data-go="i"` pula para o slide de índice `i` (base 0) · `#N` na URL abre o slide N. Áreas interativas (celular, carrossel, gráfico, funil, cards de detalhe, seletores) **não** navegam: liste-as no `closest(...)` do clique do `#vp`.

---

## 6 · Motor de animação (resumo — detalhe em `referencias/motor-animacao.md`)

Tudo com **Web Animations API** (`el.animate`), easing global **`cubic-bezier(.2,.8,.2,1)`**. Marque o elemento; o motor anima ao entrar no slide.

| Atributo | Efeito | Duração | Atraso (após a base) |
|---|---|---|---|
| `data-a` | sobe 32px + fade (**o padrão de tudo**) | 600 | 80 + i·70 |
| `data-w` | palavra do título: sobe 60% + blur 8px→0 | 700 | 200 + i·90 |
| `data-pop` | escala .6 → 1.04 → 1 | 600 | 300 + i·80 |
| `data-gx` | barra cresce da esquerda (scaleX) | 900 | 350 + i·60 |
| `data-gy` | coluna cresce de baixo (scaleY) | 900 | 350 + i·60 |
| `data-rise` | coluna empilhada sobe por clip-path (pares topo/base: a base sobe primeiro, o topo 650ms depois) | 650 | 300 + col·120 |
| `data-cell` | célula do waffle: escala .2 → 1 | 420 | 250 + i·12 |
| `data-draw` (+`data-d`) | traço SVG se desenha (stroke-dashoffset) | 1500 | 500 + d |
| `data-type` | revela da esquerda (efeito digitação) | 500 | 600 + i·450 |
| `data-reveal` / `data-fade` | linha SVG revela da esquerda / área sobe até a opacidade | 1400 / 900 | 200 / 600 + i·150 |
| `data-count="4735"` `data-dec="1"` | contador 0→valor, ease-out cúbico, vírgula pt-BR | 1300 | base + 250 |
| `data-pulse` | loop: respira 1 → 1.08 → 1 | 2600 | — |
| `data-spin="90"` | loop: gira 360° (sinal = sentido; 90 = 24s/volta) | 360/N·6000 | — |
| `data-ticker` | loop: faixa rola −50% (conteúdo duplicado 2×) | 40000 | — |
| `data-flow="34,0"` (+`data-fd`) | loop: ponto viaja pela seta | 1800 | fd |
| `data-stripe` | loop: listras diagonais deslizam | 1600 | — |
| `data-ripple` / `data-blink` | loop: onda que expande / pisca | 4200 / 1000 | — |

**Base:** 120ms em transição normal; **650ms** depois de uma cortina de ato. **Rede de segurança:** 3,4s depois de entrar, `settle()` termina toda animação pendente. Loops pausam ao sair e retomam ao voltar. `reset()` cancela tudo ao trocar de slide.

**Ordem de leitura = ordem do DOM.** O stagger segue o índice dentro do slide: escreva o HTML na ordem em que o olho deve ler.

### Transição entre slides
O slide novo entra de `translateX(±90px) scale(.98) blur(10px)` para o normal em **650ms**. Ao mesmo tempo a faixa `#sweep` (22vw, gradiente transparente → azul) atravessa a tela em **620ms**, da esquerda para a direita ao avançar e espelhada ao voltar. O slide antigo some na hora, sem cross-fade.

### Cortina de ato (a "escrita dos atos")
`data-act="Entrega 01|Link de cobrança"` no `<section>`. Ao chegar **avançando em sequência** (anterior = este − 1), a cortina azul `#1A1AFF` cobre da esquerda para a direita, segura a tela cheia com a linha de cima (14–22px, 700, `letter-spacing:.24em`, MAIÚSCULAS, `#E8E8FF`) e o nome do ato (32–64px, 800, `-.03em`) e descobre saindo pela direita. São **1500ms**: 0–35% cobrindo, 35–65% parada, 65–100% saindo. Os textos sobem 30px, ficam e saem subindo 20px (stagger de 60ms). O conteúdo do slide começa a animar em 650ms, revelando-se por trás da cortina. Voltar ou pular usa a transição normal. **Não existe slide divisor estático**: o divisor é a cortina.

---

## 7 · O que dá vida (o "show")

1. **Capa com órbita** — 4 anéis SVG (980×980, sangra 120px pela direita): externo estático `#23235A`; anel tracejado azul girando a 90; anel `#3A3A8C` girando a −60; anel `120 40 20 40` girando a 40; núcleo azul r=120 pulsando, com "Squad IA" 44/800 no centro. Título palavra por palavra, pílula azul do período, subtítulo 34px e **ticker azul de 88px** com os números-chave separados por `◆`.
2. **Celular que se mexe sozinho** — moldura 380×772 com ilha e status bar 9:41. Um mini-app real roda dentro e um **roteiro com tempos** digita o código dígito a dígito, rola a tela, move o **dedo simulado** (`.tapdot`) até o botão, "aperta" (escala .7) e clica de verdade. Abre a folha de pagamento, mostra o Pix, copia ("Código copiado") e troca para boleto. Os **passos à esquerda acendem em sincronia**. Seletor de marca troca a paleta do app e reinicia a demo. O ciclo é de 17s em loop.
3. **WhatsApp que conversa** — moldura 440×720, cabeçalho `#1F2C34`. Antes de cada fala do agente aparecem os 3 pontinhos e o status "digitando…" por 1,3s. As bolhas sobem 12px com fade. Tem áudio com onda e anexo de PDF. Reinicia 4s depois da última bolha.
4. **Carrossel de prints** — janela de navegador (3 bolinhas, URL central, 3 traços de progresso que se preenchem em 6,5s). Os prints reais fazem cross-fade de 800ms e avançam sozinhos. Clique no traço pula.
5. **Números que contam**, **barras que crescem**, **waffle que se monta em onda**, **pontos que viajam nas setas**, **listras que deslizam**, **curvas que se desenham**.
6. **Interação ao vivo** — hover na legenda destaca a fatia do waffle; hover na coluna mostra o tooltip; alternador Colunas/Pilha/Linha redesenha o gráfico com animação; hover no funil apaga as outras etapas e explica a ativa; clique no card abre o painel lateral com fonte.

Receitas completas, tempos e como adaptar a outro produto: `referencias/mockups-animados.md`.

---

## 8 · Como contar a apresentação (detalhe em `referencias/narrativa.md`)

**Arco padrão (8 a 14 slides, cerca de 1 minuto cada):**

```
01 Capa (dark)            promessa em 1 frase + ticker com os números-chave
02 Resumo / mapa          N cards clicáveis (um por ato/entrega) com número + antes/depois + faixa dark com a MENSAGEM CENTRAL
── ATO 1 (cortina) ──     o que é → como funciona (mockup vivo) → o que o número diz (honesto)
── ATO 2 (cortina) ──     idem
── ATO N (cortina) ──     idem
NN A virada / tese (dark) frase-chave em 2 linhas: "o que era." / "o que passa a ser."
NN Prioridades / próximos passos
NN Obrigado (dark)        mensagem central repetida + próximos passos em chips + "Criado por"
```

Duas maneiras de marcar ato:
- **Cortina** (Q3 e Torre): `data-act` no primeiro slide do ato. Kicker `NN · Ato N · Nome` ou `NN · Entrega 0N · Nome`.
- **Kicker + troca de fundo** (Relatório): sem cortina, o ato muda pelo número do kicker e pela alternância claro/escuro.

**Regras de conteúdo de cada slide:** um conceito por slide · título = conclusão · no máximo 3 bullets de até 12 palavras · uma frase de leitura no rodapé do gráfico ("O gargalo é a abertura, não o pagamento. **Quem abre, avança.**") · ressalva honesta em caixa âmbar · fonte no `.foot` · roteiro e instrução de interação no `data-notes`.

**Voz:** frases curtas sujeito-verbo-objeto. Número absoluto e percentual juntos ("4,2% · 199"). Sem jargão ("sinergia", "alavancar"), sem euforia ("ótima notícia"), sem emoji decorativo (✓ ◆ → 📄 só quando carregam significado). Incerteza declarada ("Curvas ilustrativas", "Out* parcial", "pagamento ainda não é rastreado").

---

## 9 · Passo a passo para fazer um deck novo

1. **Briefing:** tema, público, duração, mensagem central em UMA frase, 2 a 4 atos, fontes de dado.
2. **Copie** `template.html` para `Apresentacoes/executando/<tema>_<destino>_DD-MM-AAAA.html`.
3. **Roteiro antes do HTML:** liste os slides com `data-label`, título (ghost + accent), visual, número, fonte e nota.
4. **Capa e Obrigado:** troque título (palavras em `data-w`), pílula do período, ticker (duplicado 2×), próximos passos e assinatura (foto base64 ou iniciais).
5. **Resumo:** um `.ec` por ato com `data-go` apontando para o índice (base 0) do slide de abertura do ato.
6. **Atos:** para cada um, duplique o slide de template mais próximo do visual que você quer (catálogo em `referencias/componentes.md`), marque `data-act` no primeiro e reescreva.
7. **Mockup vivo** (se houver produto para mostrar): adapte `mountApp` e o roteiro `phoneDemo` (ou `waDemo`) ao fluxo real, com os tempos do guia. Registre a demo em `HOOKS['id-do-slide']`.
8. **Dados:** substitua `SERIE`, `MESES`, `FUN`, `PANELS` e os `data-count`. Todo número com fonte no `.foot` ou em `PANELS[].fonte`.
9. **Apague** os slides e o JS de demos que não usar (o JS de uma demo sem o slide dela quebra; remova os dois juntos).
10. **Teste no navegador** (sirva por `python -m http.server` se `file://` for bloqueado): percorra tudo com →, depois com ←, abra ESC e N, rode cada demo até o loop, passe o mouse em todo gráfico e verifique o console sem erros. Teste com redução de movimento ligada (tudo aparece pronto).
11. **Revise** com o checklist abaixo (ou `/revisar-deck`).

---

## 10 · Checklist de qualidade

**Visual**
- [ ] Só tokens da §2. Mockup de produto com tokens escopados.
- [ ] Todo slide tem `.hdr` com `◆ Squad IA` e título ghost + accent (exceto capa/obrigado).
- [ ] Fundo claro com grade de pontos de 32px; escuros com a grade certa (40px na capa, 32px `#1C1C4E` no conteúdo).
- [ ] Texto de conteúdo ≥ 24px; nada encostado nas margens de 120px.
- [ ] Cards: `border-radius:24px`; pontilhado `2px dotted #1A1AFF` para o bloco explicativo; sombra só em hover, tooltip, painel e mockup.

**Movimento**
- [ ] Todo bloco visível tem `data-a` (ou outro atributo) e a ordem do DOM é a ordem de leitura.
- [ ] Números com `data-count` e o valor final já escrito como texto (fallback).
- [ ] Barras com `data-gx`/`data-gy`/`data-rise`; curvas com `data-draw`.
- [ ] Primeiro slide de cada ato com `data-act="Linha de cima|Nome do ato"`.
- [ ] Demos registradas em `HOOKS`, param ao sair (`stopDemos`/`clearT`) e reiniciam ao voltar.
- [ ] `prefers-reduced-motion`: sem movimento, demos mostram o estado final.

**Conteúdo**
- [ ] Mensagem central aparece no resumo e repete no Obrigado.
- [ ] Cada número tem fonte; dado fictício marcado ("simulação" / "dados fictícios" / "ilustrativo").
- [ ] Ressalvas visíveis, não escondidas. Notas com instrução de interação e defesa das perguntas difíceis.
- [ ] Sem jargão, sem euforia, sem emoji decorativo. Datas e números em pt-BR.

**Técnico**
- [ ] Um arquivo só; imagens em base64; console sem erro; →/←/ESC/N/F funcionando; `#N` abre o slide certo.
- [ ] Cliques dentro de mockups/gráficos não trocam de slide (lista do `closest` no clique do `#vp`).

---

## 11 · Erros que já aconteceram (não repita)

- **Cor do botão sumindo dentro do mockup:** `#approot button{color:inherit}` ganhou de `.a-primary` por especificidade de id. Use `:where(button)` para resets dentro de mockups.
- **Cortina de ato que nunca dispara:** no export da Torre o índice do Ato 3 estava errado (11 num deck de 10). Com `data-act` no próprio `<section>` isso não acontece. Não volte para tabela de índices.
- **Dedo do celular no lugar errado:** o palco é escalado. Divida as medidas de `getBoundingClientRect()` por `k = rect.width / offsetWidth` (já feito em `tapAt`).
- **Clique da demo trocando de slide:** os cliques simulados não têm `isTrusted`; o handler do `#vp` ignora `!e.isTrusted`. Mantenha essa linha.
- **Ticker com salto:** o conteúdo precisa estar **duplicado exatamente 2×** no mesmo flex.
- **Texto que não pinta depois de muitas animações:** `repaint(slide)` força a re-rasterização; não remova.
- **Linha SVG deformada:** use `preserveAspectRatio="none"` com `vector-effect="non-scaling-stroke"` e desenhe os pontos em HTML por cima, não no SVG.
