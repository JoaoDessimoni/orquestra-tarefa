# Prompt para o Claude Design — Balanço do ciclo + plano do Q4 (Torre de Controle · squad IAF)

> Fonte dos números: `Apresentacoes/entregues/entregas_roadmap_torre_dossie.html` (gerado em 2026-10-01 — roadmap `meu-roadmap.xlsx` aba IA Esboço + Quimera, time `ia_automacao_finza`).
> Plano do Q4: alinhamento do supervisor + `Backlog/frentes/torre/BTR07_refatoracao_torre.md`.
> Copie tudo a partir da linha `=== INÍCIO DO PROMPT ===`.

---

=== INÍCIO DO PROMPT ===

## 1. Papel e objetivo

Você é um designer de apresentações executivas. Crie uma **apresentação em slides, em HTML single-file, com motion animado e interatividade**. Ela será apresentada pelo **Supervisor do squad IA & Automação da Finza (IAF)** para a liderança (diretoria/C-level).

A apresentação tem três atos:

1. **Ato 1: O incêndio.** O ciclo jun–set/2026 foi de estabilização. Sistemas, agentes de IA e ferramentas tinham incidentes recorrentes. O squad apagou o fogo sem deixar o roadmap parar.
2. **Ato 2: O que entregamos.** Marcos, conquistas e números do ciclo.
3. **Ato 3: O que vem agora.** Com os incidentes estancados, o Q4 é de **melhoria e consolidação**: refatoração da Torre e dos agentes, melhores KPIs e visibilidade de métricas. A meta é chegar ao fim do ano com **operação profissional e escalável em larga escala**.

Mensagem central, para o público lembrar: **"Estancamos o sangramento. Agora vamos consolidar e escalar."**

## 2. Público e tom

- Público: diretoria e C-level. Pouco tempo, foco em resultado e risco.
- Tom: corporativo, executivo e direto. Frases curtas (sujeito-verbo-objeto). Números em destaque.
- Proibido: jargão de consultoria ("sinergia", "alavancar", "disruptivo"), euforia ("ótima notícia!") e emojis decorativos.
- Quando um número tiver ressalva, declare a ressalva. Não maquie.
- Idioma: português do Brasil. Números no formato BR (3,69 dias; 86,8%).

## 3. Identidade visual (Finza)

- Paleta (use só estes tokens):
  - `--finza-blue #1A1AFF` (primária, números grandes, accents)
  - `--finza-blue-deep #0F0F8C`
  - `--finza-blue-soft #E8E8FF`
  - `--finza-dark #0A0A2E` (fundo dos slides de abertura e de transição de ato, texto principal)
  - `--bg #F2F2F2` (fundo dos slides de conteúdo), `--surface #FFFFFF` (cards)
  - `--ghost #C8C8D4` (palavra "fantasma" nos títulos, peso 300)
  - `--text-muted #5C5C7A`, `--border #D8D8E5`
  - Status: `--success #10B981`, `--warning #F59E0B`, `--danger #EF4444`
- Tipografia: **Inter** (Google Fonts). Títulos com uma palavra em peso 300 cor ghost e outra em peso 700 azul (ex.: "O que *entregamos*").
- Cards com borda `2px dotted var(--finza-blue)`. Marcador **"◆ iaf"** discreto no canto superior direito de todo slide.
- Números-chave: azul, peso 700, tamanho grande.
- Stack: HTML + CSS + JS vanilla, arquivo único. Sem frameworks, sem libs de ícone, sem imagens externas. Gráficos em SVG/CSS inline.

## 4. Motion e interatividade

- **Navegação:** setas ←/→, espaço, clique; `F` para tela cheia; `ESC` abre uma visão geral em grade de todos os slides. Barra de progresso fina no topo e contador "N / M" no rodapé.
- **Transições:** suaves entre slides (fade + leve deslocamento, 400–600 ms, easing `cubic-bezier(.2,.8,.2,1)`). Mudar de ato pede transição mais marcada (wipe azul).
- **Números:** contadores animados (count-up) quando o slide entra. Decimais com vírgula.
- **Gráficos:** barras crescem e linhas se desenham (stroke-dashoffset) na entrada.
- **Entrada em cascata (stagger):** cards entram em sequência, 60–80 ms entre eles.
- **Interativo:**
  - Hover/clique nos cards de frente e de marco abre um painel lateral com detalhes (lista de entregas, dono, data).
  - Botão "ver detalhe" nos KPIs: abre um tooltip com a definição do indicador e a fonte.
  - Linha do tempo clicável, com marcos por mês.
- Respeitar `prefers-reduced-motion`: sem animação, só o estado final.
- Legível em projetor 16:9. Escala responsiva.

## 5. Base de dados (use exatamente estes números)

### 5.1 Roadmap da Torre de Controle (escopo planejado · 11/06 → 01/10/2026)
- **71 entregas do roadmap concluídas** (missão concluída), em **11 frentes**
- **63 cards** abertos no Quimera · **324 story points** entregues · **56 comentários** de interação com o negócio
- Composição: **50 melhorias + 21 correções (bugs)**
- Prioridade: **6 urgentes · 26 altas · 31 médias · 8 baixas**
- Ritmo por mês de entrega: **jun 5 · jul 37 · ago 6 · set 23**
- Qualidade do ciclo: **15 entregas reabertas**, **22 voltas/reaberturas** no total e **13 demandas de continuação**. As voltas se concentram em **Dashboard (9)** e **Régua (6)**.

**Entregas por frente:** Dashboard 22 · Agentes de IA 9 · Ações 8 · Configurações 7 · Régua 7 · Gestão de Carteira 5 · Dados/Infra 4 · Filtros 4 · Integrações 3 · Campanha 1 · Custo 1

**Por executor (roadmap):**
- Leandro: 29 demandas, 177 SP
- Marcos: 23 demandas, 121 SP
- João Pedro: 5 demandas, 25 SP

### 5.2 Operação do time no Quimera (trimestre jul–set/2026 · time ia_automacao_finza)
Recorte: demandas **abertas de 01/07 a 30/09/2026**, com o status conferido no Quimera em **14/10/2026**.
- **307 demandas** abertas no trimestre (jul 73 · ago 107 · set 127)
- **278 finalizadas** · **17 canceladas** · **12 ainda em aberto**
- **Conclusão: 90,6%** finalizadas · **96,1%** encerradas (contando canceladas)
- **Escopo:** das 278 finalizadas, **55 eram cards do roadmap**. As outras **223 (80%) vieram de fora do escopo planejado**: sustentação, incidentes, demandas avulsas e repriorizações. **O roadmap não parou.**
- **Em aberto (12):** 5 em andamento, 3 bloqueadas, 4 em backlog futuro. Todas foram abertas na segunda quinzena de setembro, exceto 2 (agosto e início de setembro).
- Intruders: 13 de 307 (4,2%) · Story points: 953 · Empresa: Finza 279 · Blips 28 · Prioridade: alta 81 · média 219 · baixa 7

Indicadores de tempo (janela do painel do Quimera, ago–out, extraídos em 01/10):
- **Cycle time (mediana): 3,69 dias. Meta: 3,7 d. Meta batida.** Média 4,04 d · P90 9,17 d · 202 demandas medidas
- Tempo ativo × espera: **1,91 d trabalhando** × **2,13 d esperando**. Hoje a demanda espera mais do que é trabalhada.
- Histórico mensal do cycle time:
  - jul: 3,48 d (71 demandas)
  - ago: 3,46 d (70)
  - set: 4,29 d (**131 demandas, quase 2× o volume**)

### 5.3 Marcos do ciclo (escolha os mais fortes para os slides de conquista)

**Estancar o sangramento (jun–jul, urgências)**
- Capacidade e estabilidade da Torre (24/06)
- Sincronização Torre × Módulo Financeiro: dado da Torre alinhado à cadência do BigQuery do MF (entregue em 1 dia, 01/07)
- Conciliação da carteira Torre × Dash de Inadimplência (02/07)
- Revalidação do conceito de "pago" e padronização da query de títulos pagos (07/07)
- IA Esperanza lendo da Torre, janela de 20 dias (06/07)
- Timeout da Esperanza corrigido (09/07)

**Agentes de IA na Torre**
- Migração das IAs da Finza para a Torre (09/07)
- Esperanza trackeada como sub-agente (17/07)
- Playground com busca de contato (21/07)
- Métricas do agente refletindo a realidade (22/07)
- IA omnicanal: atendimento N1 em todos os canais (02/09)
- Prompts com diretrizes básicas, base de exemplos, nome do agente dinâmico

**Visibilidade e métricas**
- Dashboard: transbordo para humano com motivo e granularidade, atendimentos por protocolo, eficiência por step, funil de cobrança, acionamentos ao longo do tempo
- Sumário documentado de indicadores (04/09)
- Envio automático do relatório da Torre (21/07)

**Governança, eficiência e custo**
- Logs de auditoria (17/09)
- Blocklist automático por marcação jurídica (14/07)
- Scorização de telefones (22/09)
- Bloqueio/desbloqueio e troca de canal em massa na régua (set)
- Gestão de custos da Torre (28/09)
- Canais: RCS multimídia e template RCS personalizado

## 6. Roteiro slide a slide (alvo: 14 slides, ~15 min)

**ATO 1 — O INCÊNDIO**

1. **Capa (fundo dark).** Título: "Torre de Controle · Balanço do ciclo e plano do Q4". Subtítulo: "Squad IA & Automação — Finza · Outubro/2026". Motion: o logo "◆ iaf" pulsa uma vez e o título entra palavra por palavra.

2. **O ponto de partida.** Título: "O ciclo começou *apagando incêndio*". Três cards: **Sistemas** (Torre desincronizada do MF, capacidade instável), **Agentes** (Esperanza com timeout e lendo dados defasados, métricas que não refletiam a realidade) e **Ferramentas** (filtros e botões quebrados, dashboard com divergências). Rodapé: "6 entregas urgentes nas primeiras semanas — todas de estabilização".

3. **O tamanho do esforço.** Título: "*80%* do trabalho veio de fora do plano". Visual: waffle/donut animado de **278 finalizadas** (abertas jul–set), com **55 do roadmap** (azul) e **223 fora do escopo** (laranja). Barra abaixo: "307 demandas abertas no trimestre (jul–set)": **278 finalizadas · 17 canceladas · 12 em aberto**. Frase de impacto: "Absorvemos sustentação e repriorizações sem parar o roadmap". Interativo: hover em cada fatia mostra a composição. Rodapé: "Fonte: Quimera · time ia_automacao_finza · demandas abertas de 01/07 a 30/09/2026 · status em 14/10/2026".

**ATO 2 — O QUE ENTREGAMOS** (transição: wipe azul + "Ato 2")

4. **Hero de resultados.** Quatro números grandes com count-up:
   - **71** entregas do roadmap ("missão concluída")
   - **3,69 d** de cycle time (selo "meta batida", meta 3,7 d)
   - **96%** das demandas do trimestre encerradas (278 finalizadas + 17 canceladas de 307)
   - **307** demandas abertas no trimestre (jul–set)

5. **Linha do tempo do ciclo.** Barras por mês de entrega: jun 5 · jul 37 · ago 6 · set 23. Marcos-chave como pinos clicáveis:
   - jun–jul: estabilização (Torre × MF, conceito de pago, Esperanza)
   - jul: IAs migradas para a Torre
   - set: IA omnicanal, logs de auditoria, gestão de custos

6. **Entregas por frente.** Treemap ou barras horizontais animadas com as 11 frentes (Dashboard 22 no topo). Clique na frente abre o painel lateral com a lista de entregas. Rodapé: "324 story points · 50 melhorias · 21 correções".

7. **Conquista 1 — Base confiável.** "A Torre voltou a falar a mesma língua do Financeiro". Cards: sincronização com o MF, conciliação da carteira, conceito de pago padronizado, capacidade e estabilidade.

8. **Conquista 2 — Agentes de IA dentro da Torre.** "IAs migradas, rastreadas e omnicanal". Cards: migração das IAs, Esperanza como sub-agente, Playground, IA N1 em todos os canais, métricas reais do agente.

9. **Conquista 3 — Visibilidade, governança e custo.** Cards: dashboard com transbordo/funil/eficiência por step, sumário de indicadores, relatório automático, logs de auditoria, blocklist jurídico automático, gestão de custos.

10. **Saúde da operação (KPIs do time).** Painel com 4 indicadores animados:
    - Cycle time: mediana 3,69 d vs meta 3,7 d, P90 9,17 d
    - Conclusão: 90,6% finalizadas (96,1% encerradas, contando canceladas)
    - Intruders: 4,2% (13 de 307)
    - Volume: 307 demandas no trimestre
    
    Gráfico de linha do cycle time mensal (jul 3,48 · ago 3,46 · set 4,29) com as barras de volume por trás (71 · 70 · 131). Leitura: "Em setembro o volume quase dobrou e o cycle time subiu só 0,8 d".

11. **O que aprendemos (honestidade executiva).** Título: "O que *ainda* custa caro". Três pontos:
    - **22 voltas/reaberturas**, concentradas em Dashboard e Régua → falta de refinamento e homologação antes de desenvolver.
    - **Espera > trabalho:** 2,13 d esperando × 1,91 d trabalhando.
    - **P90 de 9,17 d:** a cauda longa ainda existe.
    
    Tom neutro: são a base do plano do Q4, não desculpas.

**ATO 3 — O QUE VEM AGORA** (transição: wipe azul + "Ato 3")

12. **A virada.** Fundo dark. Frase grande animada: "Estancamos o sangramento. *Agora: consolidar e escalar.*" Visual: uma linha de "incidentes" que cai e se estabiliza, e uma linha de "maturidade" que sobe.

13. **O acordo para o Q4.** Título: "Q4: do *apagar incêndio* à *operação escalável*". Quatro pilares em cards (clique abre o detalhe):
    1. **Refatoração da Torre.** Arquitetura enterprise: backend robusto, fila com reprocessamento, disparos em paralelo, tratamento de erro padronizado, observabilidade e fidelidade total ao Módulo Financeiro.
    2. **Refatoração dos agentes de IA.** Padronizar prompts, governança e rastreabilidade dos agentes. Menos incidentes e comportamento previsível.
    3. **KPIs melhores.** Atacar o tempo de espera, a cauda do P90 e as reaberturas, com gate de refinamento e homologação antes do dev.
    4. **Visibilidade de métricas.** Indicadores dos agentes e da operação visíveis para o negócio, com fonte única e documentada.

14. **Próximos passos e fechamento.** Linha do tempo out → nov → dez até "Fim de 2026: profissionalismo escalável em larga escala". Metas do Q4 em cards (ver placeholders abaixo). Frase final: "Fechamos o ano com a casa arrumada e pronta para escalar." Encerrar com a assinatura: "Squad IA & Automação — Finza · Supervisor João Vinícius".

## 7. Regras de conteúdo

- **Não invente números.** Use só os dados da seção 5. Onde houver placeholder `[META: ...]`, deixe o placeholder visível e em destaque, para eu preencher.
- Toda métrica de KPI tem tooltip com a definição e a fonte: "Fonte: Quimera · time ia_automacao_finza" ou "Fonte: roadmap da Torre + Quimera".
- Período sempre explícito: roadmap **11/06 → 01/10/2026**; indicadores do Quimera **trimestre ago–out/2026**.

### Placeholders de meta do Q4 (preencher antes de apresentar)
- `[META: cycle time mediana Q4 — ex.: manter ≤ 3,7 d e reduzir P90 de 9,17 d para X d]`
- `[META: reaberturas — reduzir de 22 voltas para X]`
- `[META: tempo de espera — de 2,13 d para X d]`
- `[META: marco da refatoração da Torre em dez/2026 — ex.: paridade funcional / cutover / fase 1]`
- `[META: marco da refatoração dos agentes]`
- `[META: painel de métricas dos agentes publicado até DD/MM]`

=== FIM DO PROMPT ===

---

## Notas para o João (não colar no Claude Design)

- **"Semestre" × dados:** o dossiê cobre o **roadmap de 11/06 a 01/10** e os **indicadores do Quimera de ago–out**. Por isso o prompt fala em "ciclo jun–set" e não em "semestre". Se quiser manter "semestre", troque só o texto da capa.
- **Cycle time "meta batida" por 0,01 d** (3,69 × 3,7). É verdadeiro, mas apertado. Se perguntarem, o argumento mais forte é a estabilidade sob volume: setembro teve quase 2× as demandas e só +0,8 d no cycle time.
- **R19 (bloqueio em massa)** foi marcada como entregue no roadmap com ressalva: faltou refinamento e homologação do negócio, e o bloqueio em massa pedido pelo João Pedro ficou para outubro. O deck não a destaca como conquista isolada. Vale ter na manga.
- **Refatoração da Torre (BTR07)** está `em-refinamento`, com esforço XL e alvo 2026-Q4. O próprio item registra prazo realista de 6+ meses. Para dezembro, prometa um **marco** (arquitetura definida, fase 1, paridade parcial) e não o cutover completo.
- A soma por executor fecha em **57 demandas, não em 71**. O dossiê conta por card do Quimera, e algumas entregas não têm dev atribuído (ex.: R07, Capacidade e estabilidade). Se pedir ao Claude Design um slide por executor, não apresente a divisão como se somasse as 71.
