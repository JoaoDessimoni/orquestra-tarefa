# Como contar a apresentação

O deck animado é um **filme curto em atos**. O movimento serve à história: cada animação revela a informação na ordem em que o apresentador fala.

---

## 1 · Antes de abrir o HTML

Responda em uma folha:
1. **Mensagem central** em UMA frase, com duas metades: o que mudou + o que isso significa. Ex.: "A Torre deixou de só disparar. **Agora ela sabe quem atende, o que o cliente fez e quanto isso custou.**" Ela aparece 3 vezes: no resumo (faixa navy), na tese e no Obrigado.
2. **Público e tempo.** Liderança: 8 a 12 slides em cerca de 10 minutos. Cerca de 1 minuto por slide de conteúdo.
3. **Os atos** (2 a 4). Cada ato responde UMA pergunta. Ex.: Torre = "O incêndio / O que entregamos / O que vem agora"; Relatório = "Quanto / Por quê / Casos e custo"; Q3 = uma entrega por ato.
4. **Para cada ato:** o que é → como funciona (de preferência um mockup vivo) → o que o número diz, inclusive o que não é bom.
5. **Fontes** de cada número (sistema, tabela, recorte, data de extração).

## 2 · Arcos prontos

**Entregas (Q3):** Capa → Resumo com N cards (antes/depois) → para cada entrega: [o que é + mockup vivo] → [primeiro resultado, honesto] → Obrigado com próximos passos por entrega.

**Balanço de ciclo (Torre):** Capa → **Ato 1 · O problema** (ponto de partida em cards antes/depois · tamanho do esforço em waffle) → **Ato 2 · O que fizemos** (4 KPIs-herói em fundo escuro · linha do tempo · distribuição em treemap · ganhos qualitativos em trio) → **Ato 3 · O que vem** (A virada, a tese em fundo escuro · prioridades com meta) → Obrigado.

**Relatório de desempenho (Relatório IAs):** Capa (ticker com KPIs do recorte) → **Quanto** (panorama 4 KPIs · por instância · evolução interativa) → **Por quê** (ranking de motivos · drill-down do maior balde com voz do cliente + ação) → **Casos e custo** (agente com funil · custo por agente) → Obrigado.

## 3 · Títulos

- **Kicker** (`.hdr`): `NN · Ato N · Nome do ato` ou `NN · Entrega 0N · Nome` ou `NN · Tema`. Numera e situa.
- **H2 = conclusão, não tópico.** Contexto leve (300, cinza) + conclusão pesada (800, azul). Entre 3 e 7 palavras.
  - "Começamos **apagando incêndio**" · "Resultados em **quatro números**" · "A Torre sabe **qual número atende**" · "Quanto custa **cobrar**" · "Por que foi **a humano**".
- **Número primeiro** quando ele é a mensagem: "**96%** dos links vencidos nunca foram abertos", "**80%** do trabalho veio de fora do plano" (o destaque pode ser âmbar ou vermelho quando o dado é ruim).
- **Capa:** 2 palavras de contexto finas + conclusão pesada, a última palavra em lilás. "Quatro entregas **que mudaram a cobrança**".
- **Tese:** duas frases curtas, a primeira fina e a segunda pesada: "Incêndio controlado. **Agora é consolidar e escalar.**"
- O `data-label` é o rótulo neutro do tópico ("Linha do tempo"), usado na visão geral.

## 4 · Dentro de cada slide

1. Kicker → título → **um** bloco explicativo (card pontilhado `.cd`, 2 a 3 frases, termos-chave em azul).
2. O visual faz o trabalho (mockup, gráfico, número grande). Até 3 bullets de até 12 palavras.
3. **Frase de leitura** abaixo do gráfico, em 34/700, com a consequência em azul: "O gargalo é a abertura, não o pagamento. **Quem abre, avança.**"
4. **Ressalva** em caixa âmbar quando o número tem limite: "**O custo real é maior.** 12.330 RCS ainda estão sem tarifa."
5. **Rodapé** com fonte · recorte · código · dev · datas.
6. **Antes × depois** sempre que houver mudança de processo (uma linha cada).

## 5 · Voz

- Frases curtas, sujeito-verbo-objeto, voz ativa. "A Torre gera o link." e não "O link passou a ser gerado pela Torre."
- Número absoluto e percentual juntos: "4,2% abriram o link (199)".
- Tradução para o negócio: "nota 30 = cerca de **3 em cada 10 mensagens** chegam".
- Honestidade explícita: mostrar a perda e a causa ("A perda está mapeada: 86 sem acionamento por falha, já corrigida").
- Proibido: "sinergia", "alavancar", "disruptivo", "ótima notícia", "boas perspectivas", emoji decorativo, exclamação.
- pt-BR: `4.735`, `6.467,28`, `3,69 d`, `16/09 → 22/09/2026`.

## 6 · Notas do apresentador (`data-notes`)

Cada slide tem 1 a 3 frases com:
- **o roteiro** ("Três frentes de incêndio, resolvidas em 41 dias"),
- **a instrução de interação** ("Clique nos cards para o detalhe", "Passe o mouse na legenda"),
- **a defesa da pergunta difícil** ("Meta batida por 0,01 d: se perguntarem, o argumento forte é estabilidade sob volume"; "a soma por executor fecha em 57, não em 71"; "as curvas são ilustrativas").
A tecla N mostra a nota durante a apresentação.

## 7 · Ensaiando com a animação

- Cada slide leva cerca de 1,5s para "montar". Fale o título enquanto ele entra e aponte o número quando o contador terminar.
- Na cortina de ato (1,5s), diga o nome do ato junto com ela.
- Nos mockups vivos, comente o passo que acende. O ciclo do celular dura 17s; não espere ele terminar para avançar.
- Para voltar sem animação de ato, use ← (a cortina só toca avançando).
- ESC abre a visão geral para pular para um slide quando surgir uma pergunta.
