# BRIEFING — Deck de Repasse IAF para Leonardo (CTO Finza)

> Spec **vivo**. Atualizado a cada iteração para refletir o estado real do deck e dos docs. Última atualização: **12/05/2026** (v7 — deck enxugado de 9 → 7 slides: removidos os slides técnicos da Torre "7 sistemas principais" e "capacidades técnicas"; Esperanza reescrita com lente de negócio em layout 2 colunas — entrega × gaps mapeados).

---

## 1 · Contexto da apresentação

- **Quem apresenta**: João Vinícius — novo Supervisor do squad IAF (iA Finza), recém-empossado (5 dias na empresa).
- **Para quem**: Leonardo Caixeta, CTO Finza.
- **Quando**: 11/05/2026.
- **Tempo previsto**: 15-20 minutos.
- **Objetivo**: Apresentar ao CTO, de forma estruturada e honesta, o que o novo supervisor absorveu sobre o squad IAF em 5 dias, com **foco técnico** em Torre, gargalos, problemas, pendências. NÃO é overview completo do squad — é recorte focado em cobrança + Torre + estado de coisas.
- **Tom esperado**: técnico-executivo. Leonardo é CTO, entende a stack e o negócio Finza inteiro — **não precisa de slides explicando o que é a Finza**. Quer ver clareza, mapeamento honesto, plano. Frases curtas. Números quando existirem.
- **O que esta apresentação NÃO cobre**:
  - Detalhe técnico dos demais agentes (Valentina, Clara, Lívia, Prudente, Francisco). Mencionados, não esmiuçados.
  - Plataformas que não são do IAF (Falcon, Veritas, MF, Finza Start) — citadas no slide 3 com nome do TechLead.
  - Plano detalhado de gestão de pessoas.

### Docs de apoio (a partir de 15/05/2026 — reorganização da arquitetura)
- [finza/PLATAFORMAS.md](finza/PLATAFORMAS.md) — referência das 5 plataformas Finza
- [finza/CONTEXTO-FINZA.md](finza/CONTEXTO-FINZA.md) — modelo de negócio, organograma, roadmap estratégico
- [finza/TORRE_DE_CONTROLE_OVERVIEW.md](finza/TORRE_DE_CONTROLE_OVERVIEW.md) — Torre completa (15 seções)
- [agentes/ESPERANZA_AGENT_OVERVIEW.md](agentes/ESPERANZA_AGENT_OVERVIEW.md) — Esperanza completa
- [finza/repasse-joao-vinicius-iaf.html](finza/repasse-joao-vinicius-iaf.html) — repasse Mateus → João Vinicius, 07/05

---

## 2 · Stack técnica do deck

**Obrigatório:**
- HTML5 + CSS3 + JavaScript vanilla.
- Single-file (`index.html` na raiz do projeto) — todo CSS e JS inline.
- Sem frameworks (sem React, Vue, Reveal.js, etc.).
- Única dependência externa permitida: Google Fonts (Inter, pesos 300/400/500/600/700/800).
- Sem libs de ícone via CDN — usar Unicode/emoji sóbrio (✓, →, •, ◆) ou SVG inline mínimo.
- Sem imagens externas.

**Navegação:**
- **Teclado**: ← → (navegar), Espaço/PageDown (próximo), PageUp (anterior), Home/End (ir para extremos), ESC (overview), F (fullscreen).
- **Mouse**: **setas `‹ ›` clicáveis nas bordas laterais** (esquerda/direita, vertical center). Botões circulares, fundo branco com borda azul Finza, hover preenche azul. Em slides splash dark, ficam translúcidos sobre o fundo. **Seta esquerda oculta no slide 1; seta direita oculta no último**.
- ESC abre uma grade de overview com todos os slides clicáveis.
- Indicador discreto `n / 10` no rodapé direito (oculto no slide 1).

Responsivo o bastante para abrir no laptop e projetar em telão 1920×1080. Não precisa funcionar em mobile.

**Acessibilidade:**
- Contraste AA mínimo.
- Estrutura semântica (cada slide é `<section>` com `aria-labelledby`).
- Foco visível em elementos interativos.

---

## 3 · Design system — paleta Finza corporativa

Substituiu a paleta neutra anterior. Baseada na apresentação corporativa Finza (`Apresentacoes/Boas Vinda FINZA - Tech - 2026.pdf`).

### Tokens

| Token | Hex | Uso |
|---|---|---|
| `--finza-blue` | `#1A1AFF` | Cor primária — fundo splash, palavras-chave em títulos, números grandes, bordas dotted |
| `--finza-blue-deep` | `#0F0F8C` | Hover, accents secundários |
| `--finza-blue-soft` | `#E8E8FF` | Fundo de pílulas e stack tags |
| `--finza-dark` | `#0A0A2E` | Fundo do slide de fechamento, "olhos" de numeração, texto principal |
| `--bg` | `#F2F2F2` | Fundo cinza claro dos slides de conteúdo (mimetiza pp. 7-13 do FinzaDay) |
| `--surface` | `#FFFFFF` | Fundo de cards sobre o cinza |
| `--ghost` | `#C8C8D4` | Cor dos títulos "fantasma" (peso 300) |
| `--text` | `#0A0A2E` | Texto principal |
| `--text-muted` | `#5C5C7A` | Texto secundário, metadados |
| `--border` | `#D8D8E5` | Linhas finas |
| `--success` | `#10B981` | Status concluído |
| `--warning` | `#F59E0B` | Status em curso |
| `--danger` | `#EF4444` | Riscos críticos |

### Mix de fundos por slide

- **Slide 1 (Capa)**: splash azul forte (`--finza-blue`) + texto branco. Mimetiza pp. 1 e 14 do FinzaDay.
- **Slides 2–9 (Conteúdo)**: fundo cinza claro corporativo (`--bg` `#F2F2F2`). Mimetiza pp. 7-13, 17-19 do FinzaDay.
- **Slide 10 (Pedido + Fechamento)**: dark splash (`--finza-dark` `#0A0A2E`) + texto branco. Mimetiza pp. 35-36 ("#INOVAÇÃONAVEIA").

### Tipografia

- **Família única**: Inter (Google Fonts), pesos 300, 400, 500, 600, 700, 800.
- **h1 (título de slide)**: 56-64px, **peso 300** em `--ghost` (cinza claro) **+** uma `.accent` em peso 700 com `--finza-blue`. Padrão "ghost title" da Finza (ex.: "Como nasceu **a FINZA**", pp. 7).
- **h2 (subtítulo)**: 22-24px, peso 500, cor `--text-muted`.
- **h3 (sub-cabeçalho)**: 17-22px, peso 600-700.
- **Corpo**: 13-17px, peso 400-500, line-height 1.5.
- **Caption/meta**: 10-13px, peso 600-700, letter-spacing 0.14-0.20em, uppercase.

### Padrões visuais Finza (não-negociáveis)

- **Marcador "iaf"** no canto superior direito de cada slide — texto pequeno (12px, peso 700), cor `--finza-blue`, prefixado por diamante `◆`. Em splash slides, vira branco translúcido. Mimetiza a marca "finzaday" do PDF.
- **Cards**: borda **`2px dotted var(--finza-blue)`**, raio 10-14px, fundo branco. Padrão visual marcante da Finza (pp. 12, 18, 29 do FinzaDay).
- **Numeração tipo "olho"**: círculo `--finza-dark` (32px) com número branco centralizado. Estilo da pp. 22 (Módulo Financeiro) e pp. 25-27 (Finza Start).
- **Pílulas de stack tag**: fundo `--finza-blue-soft`, texto `--finza-blue`, raio 999px.
- **Banner accent**: fundo `--finza-blue` ou `--finza-dark`, texto branco, padding generoso, usado para destacar prazo/insight.

### Princípios visuais

- **Um conceito por slide**. Se um slide tem dois conceitos, vira dois slides.
- **Texto curto**. Bullets de no máximo 1-2 linhas.
- **Sem clipart, sem stock photo, sem emoji decorativo**. Emojis funcionais (✓, →, 🎯, 📅, 📍, 📇, 📐, 📣, 🧠, 🔄, 🔌) são OK quando carregam significado.
- **Números visíveis**. Quando houver número (40%, 37 issues, 6 sprints, 10/jul), ele aparece grande, em `--finza-blue`.
- **Sóbrio**. Branco/cinza dominante nos slides de conteúdo. Azul cirúrgico — em títulos, números-chave, bordas, banners.

---

## 4 · Estrutura dos 7 slides (v7)

Conteúdo é prescritivo. Se algo soar ambíguo, marcar com `<!-- TODO: confirmar com gestor -->` em vez de inventar.

### Slide 1 — Capa (splash azul)
Sem barra de navegação visível, sem contador, sem seta esquerda.
- Tag superior: `◆ FINZA · TECNOLOGIA · IAF`
- h1: "Squad IAF — **Estado e Direção**" (ghost + accent)
- Subtítulo: "Visão consolidada após 5 dias como Supervisor"
- Bloco de metadados em 3 colunas: De · João Vinícius · Supervisor IAF / Para · Leonardo Caixeta · CTO Finza / Data · 11 de maio de 2026

### Slide 2 — O que esta conversa cobre
- h1: "O que esta conversa **cobre**"
- h2: "E o que ainda não."
- Coluna esquerda "Cobre" (3 pílulas com check azul):
  - Torre de Controle — o sistema sob a IAF
  - **Problemas técnicos que já mapeei na Torre** ← novo na v3
  - Pendências e contradições que já identifiquei
- Coluna direita "Não cobre hoje" (3 pílulas muted):
  - Detalhe técnico dos demais agentes Finza
  - **Detalhamento do plano herdado (já aprovado em 28/abr)** ← novo na v3
  - Métricas operacionais (sem dado consolidado ainda)
- Rodapé: "Recorte deliberado. Em 5 dias dá pra mapear, não pra fechar diagnóstico..."

### Slide 3 — Plataformas Finza, em uma linha (expandido na v3)
- h1: "Plataformas Finza, **em uma linha**"
- h2: "5 plataformas no funil. A IAF mantém só a última."
- 5 cards horizontais altos (`min-height: 260px`). Cada card mostra: número-olho, **nome da plataforma** (azul peso 700), `.meta` ("Etapa N · Tipo · TL Nome"), descrição mais densa (2-3 linhas) com palavras-chave em `<strong>` azul.
  1. **Finza Start** · Etapa 1 — Originação · TL Marco — "Portal do cliente Finza (correspondente — não do cliente final). Representante solicita crédito para um lead, simula financiamento, envia proposta, coleta assinatura + prova de vida, vincula neurônio à máquina."
  2. **Falcon** · Etapa 2 — Análise de crédito · TL Girlan — "Motor sem front. Avalia risco em segundos via credit scoring + ML, libera ou nega limite. Sustenta toda a originação — qualquer crédito Finza passa por aqui."
  3. **Veritas** · Etapa 3 — KYC + Compliance · TL Girlan — "Entra após aprovação do Falcon. Documentos, biometria, antifraude, due diligence. Em 2026 vira motor de KYC próprio — elimina dependência de terceiros."
  4. **Módulo Financeiro** · Etapa 4 — Backoffice cobrança · TL Marco — "Gera títulos, parcelas, boletos. Integra com FIDCs e bancarizadores. Fonte da verdade financeira. A Torre se alimenta da base fria do MF."
  5. **Torre de Controle** · Etapa 5 — Cobrança · **Sob a IAF** (highlight azul) — "Único sistema sob a IAF. Onde a Esperanza vive, onde as réguas são configuradas, onde as campanhas HyperFlow (API oficial Meta) são disparadas."
- Banner: "🎯 IAF atua na etapa 5. As 4 plataformas anteriores são vizinhanças sob Marco e Girlan — integramos, não governamos."
- Rodapé: referência aos docs `PLATAFORMAS.md` e `CONTEXTO-FINZA.md`

### Slide 4 — Torre de Controle: proposta + objetivos (atualizado v6)
- h1: "Torre de **Controle**"
- h2: "Sistema operacional da cobrança Finza. Title-centric, multi-tenant, com IA aprovada por humano."
- Bloco superior `torre-proposal`: lede com "**1.000 a 100.000+ contatos**", multi-canal nativo, cobrança preventiva D-7/D-1 + 3 meta (Title-centric / Multi-tenant RBAC / IA com aprovação)
- Section divider azul: "Objetivos estratégicos · 6"
- Grid 3×2 com os **6 objetivos do doc** (TORRE_DE_CONTROLE_OVERVIEW.md §2): Maximizar recuperação de inadimplência / Reduzir custo por contato / Manter consumidor protegido / Visibilidade total da operação / Operação sem dependência de TI / Inteligência aplicada

### Slide 5 — Torre: problemas mapeados (renumerado v7, era slide 7)
- h1: "Torre — **problemas mapeados**"
- h2: "6 frentes técnicas e organizacionais identificadas em 5 dias. Algumas já endereçadas pelo plano herdado; outras precisam de decisão fora do squad."
- 6 `problem-card` em grid 2×3. Cada card tem: **tag azul "P0X"** (substituiu emoji na v5), título azul, descrição, linha de proposta separada por borda dashed.
  - **P01 Ambientes de teste** — Só produção + 1 banco dev como "homologação". → 3 ambientes reais.
  - **P02 Backend todo em Supabase Functions** — Telas 5-10s, regras invisíveis, endpoints fantasmas. → Backend dedicado (FastAPI).
  - **P03 Sem metodologia de versionamento** — Sem padrão entre devs. → Fluxo PR + convenção + code review (Joao Lucas).
  - **P04 Sem QA — dev testa o próprio código** — Sem homologação formal. → Solicitante como QA. Se não escalar, QA dedicado.
  - **P05 Sem priorização de negócio** — Sem ranking. → Ritual semanal com Jéssica + canal único.
  - **P06 Alta dependência do time de IA** — Tudo passa pelo IAF. → Torre 2.0 + curadoria autônoma (plano herdado).
- Rodapé: "P01 a P05 dependem de decisão arquitetural/processo fora do squad. P06 é objetivo declarado do plano até 10/jul."

### Slide 6 — Esperanza, em produção (redesenhado v8 — hero escuro + fases + funções)
- h1: "Esperanza, **em produção**"
- h2: "Agente IA que conduz a régua de cobrança Finza no WhatsApp."
- Layout em 4 blocos verticais (sem 2 colunas — mais minimalista e respirado):
  1. **Hero escuro `.esp-hero`** (`--finza-dark` + sombra) com badge azul "Cobrança 4.0" à esquerda e texto explicativo à direita: modelo digital multicanal (WhatsApp/e-mail/RCS), regras por carteira (Blips, Ideal, FIDC, Finza), tom progressivo, IA conversacional. Esperanza é a camada que conversa, negocia e registra dentro dessa régua — da amigável até a extrajudicial.
  2. **Fases que opera** (`.esp-phases` — 3 cards) com `ph-range` em uppercase azul/cinza e o card central (`featured`) destacado em `--finza-blue-soft`:
     - **D-10 → D+15 · Amigável** — lembrete e aviso pré-vencimento
     - **D+16 → D+60 · Cobrança 4.0** (featured) — negociação digital ativa, notificação extrajudicial por e-mail, desconto/parcelamento
     - **D+46+ · Extrajudicial** — notificação por correio, protesto em cartório, cancelamento e retirada de equipamento
  3. **O que faz hoje** (`.esp-funcs` — 9 itens em grid 3×3, bullet dot azul) — apenas funções verificáveis nas 27 tools MCP do `ESPERANZA_AGENT_OVERVIEW.md`: identificação por telefone/CPF, consulta de dívida/contratos/títulos, blocklist, desconto por tier, parcelamento, PIX/boleto, promessa, avanço de funil, escalonamento.
  4. **Gaps de qualidade** (`.esp-gap-row` — 4 cards mini com border-left `--warning`): E01 delírio em conversas longas, E02 cobranças indevidas, E03 informações imprecisas, E04 workflow >1m30s.
- Cada bloco separado por `.esp-section-label.accent` (linha horizontal com label em uppercase azul).
- Removido na v8: layout 2 colunas, sub-blocos "O que ela agiliza" e "Ganhos atuais", pílulas dotted de fases, foot com ownership (info redundante com slide de problemas).

### Slide 7 — Próximos passos (dark splash)
- h1: "Próximos **passos**"
- h2: "O que vou rodar — sem pedido formal, só visibilidade do que está sendo destravado."
- 2 colunas com ações em listas verticais:
  - **Squad e processo · esta semana**: Distribuir Sprints 2-5 no Jira / 1:1 com cada dev / Resolver 5 pendências / Reunião com Jéssica
  - **Torre · destravar problemas técnicos**: Viabilidade do refator FastAPI com Joao Lucas / Definir 3 ambientes / Propor fluxo PR + code review / Subir piloto de QA pelo solicitante
- Closing line: "O time tem direção. **O plano herdado é sério.** Pendências mapeadas, não escondidas. Vou rodar o plano e ajustar onde a realidade exigir."

---

## 5 · JavaScript — comportamento mínimo

```js
// Lista de slides (querySelector all sections.slide).
// Estado: índice atual + body class .slide-is-dark para slides splash.
// Funções:
//   - goTo(n): mostra slide n, esconde os outros, atualiza contador, mostra/oculta setas
//   - next(): goTo(atual + 1)  (clamp em total)
//   - prev(): goTo(atual - 1)  (clamp em 0)
//   - openOverview / closeOverview (ESC)
//   - toggleFullscreen() (F)
// Listeners:
//   - keydown: ArrowRight/Space/PageDown → next, ArrowLeft/PageUp → prev,
//     Home → 0, End → total-1, Escape → openOverview, F → toggleFullscreen
//   - click na seta esquerda/direita → prev/next
//   - clique em thumbnail (no overview) → goTo(n) + fecha overview
// Inicialização: goTo(0) ao carregar.
// Setas mouse: .nav-arrow.left oculta no slide 0; .nav-arrow.right oculta no último slide
// HUD (contador + hint) oculto no slide 0
// body.slide-is-dark adiciona quando o slide ativo tem class splash-blue ou splash-dark
//   → permite que setas/contador adaptem cor para fundo escuro
```

---

## 6 · Voz e estilo do texto nos slides

- Frases curtas. Sujeito + verbo + objeto. Pouca subordinação.
- Primeira pessoa só onde representa fala do supervisor (slides 8 ações, 10 fechamento). No resto, voz neutra descritiva.
- Sem jargão de consultoria ("sinergia", "alavancar", "deep dive").
- Números em destaque visual (azul, peso 700) quando aparecerem.
- Nada de "ótima notícia", "boas perspectivas", "estamos comprometidos". Texto direto, sem inflar.
- Quando declarar incerteza, declarar (ex.: "ainda não temos dado para isso").
- **Tom ajustado v2**: mais técnico. Leonardo é o CTO da Finza — não precisa de contexto de "o que é a Finza", "onde a IAF se encaixa". Slide 3 nomeia plataformas e seus TLs porque isso é informação operacional útil, não tutorial.

---

## 7 · Checklist final antes de entregar o HTML

- [x] 9 slides exatamente, na ordem especificada
- [x] Navegação por setas, espaço, PageDown/Up, Home/End funciona
- [x] **Setas `‹ ›` clicáveis nas bordas — ocultas na capa (esquerda) e no último slide (direita)**
- [x] ESC abre overview, F entra em fullscreen
- [x] Contador "n / 9" no rodapé direito em todos exceto capa
- [x] **Sem emojis decorativos** — substituídos por tags numéricas, bullets sóbrios (▸), ou tipografia em azul
- [x] **Paleta Finza exata** — `#1A1AFF`, `#0A0A2E`, `#F2F2F2`, sem cores fora dos tokens
- [x] **Mix de fundos**: capa azul, conteúdo cinza, fechamento dark
- [x] **Marcador `◆ iaf` no canto superior direito** de todos os slides
- [x] **Cards com borda 2px dotted azul** — assinatura visual Finza
- [x] **Numeração tipo "olho"** (círculo dark + número branco) no slide 3
- [x] **Slide 5 (Torre — problemas)**: 6 cards em grid 2×3 com proposta de mitigação separada por borda dashed
- [x] **Slide 7 (Próximos passos)**: 2 colunas (Squad / Torre) em listas verticais, sem pedidos formais
- [x] Inter via Google Fonts no `<head>`, sem outras dependências externas
- [x] Single file `index.html` na raiz do projeto
- [x] Funciona offline depois da fonte cachear
- [x] Sem warnings de acessibilidade básicos (foco, contraste AA, semântica)
- [x] Nenhum `console.log` esquecido
- [x] TODO remanescente apenas onde briefing original não dita conteúdo (descrições de sprint)

---

## 8 · Notas finais

- Se durante a iteração algum texto soar ambíguo, **não invente**: marque com `<!-- TODO: confirmar com gestor -->` no HTML, deixe placeholder claro, e avise no resumo final.
- Iteração esperada: este é um **v5**. Torre ganhou 3 slides ricos (proposta+objetivos, 7 sistemas, capacidades técnicas) baseados no documento interno da Torre (15 seções: objetivos, conceitos, sistemas, telas, crons, status, resiliência, integrações, API, variáveis, diferenciais, casos, fora do escopo, stack). Deck inteiro foi profissionalizado: emojis decorativos removidos, substituídos por tags numéricas (P01-P06), bullets sóbrios e tipografia em azul Finza. Stat-row com números grandes como assinatura visual.
- **Sempre que houver mudança estrutural, atualizar este BRIEFING.md.** Decisão do usuário: este doc deve refletir o estado vivo do deck.

---

## 9 · Referências

Caminhos atualizados em 15/05/2026 com a reorganização da arquitetura (vide `CLAUDE.md` da raiz).

- [finza/PLATAFORMAS.md](finza/PLATAFORMAS.md) — referência das 5 plataformas Finza (Finza Start, Falcon, Veritas, MF, Torre)
- [finza/CONTEXTO-FINZA.md](finza/CONTEXTO-FINZA.md) — modelo de negócio, organograma TI&Produtos, roadmap estratégico, cedentes, neuronização
- [finza/TORRE_DE_CONTROLE_OVERVIEW.md](finza/TORRE_DE_CONTROLE_OVERVIEW.md) — 15 seções da Torre
- [agentes/ESPERANZA_AGENT_OVERVIEW.md](agentes/ESPERANZA_AGENT_OVERVIEW.md) — Esperanza completa, 27 tools MCP
- [finza/repasse-joao-vinicius-iaf.html](finza/repasse-joao-vinicius-iaf.html) — repasse histórico do Mateus → João Vinícius (07/05)
- [../Apresentacoes/referencias/Boas Vinda FINZA - Tech - 2026.pdf](../Apresentacoes/referencias/Boas%20Vinda%20FINZA%20-%20Tech%20-%202026.pdf) — fonte da paleta corporativa
- [../Apresentacoes/referencias/Roadmap Agentes IA — Operações Finza.pdf](../Apresentacoes/referencias/Roadmap%20Agentes%20IA%20%E2%80%94%20Opera%C3%A7%C3%B5es%20Finza.pdf) — roadmap Mateus → CTO, 28/abr
- [../Apresentacoes/referencias/Régua de Comunicação_Atualizada.pptx](../Apresentacoes/referencias/R%C3%A9gua%20de%20Comunica%C3%A7%C3%A3o_Atualizada.pptx) — régua de cobrança (pendente extrair texto)
- [../Apresentacoes/entregues/apresentacao_cto_13-05-2026.html](../Apresentacoes/entregues/apresentacao_cto_13-05-2026.html) — implementação canônica do design system Finza

---

## Histórico de versões

- **v8 (13/05/2026)** — Redesenho do slide da Esperanza para deixá-lo mais profissional, minimalista e destacado. Layout 2 colunas substituído por 4 blocos verticais. Novo `.esp-hero` com fundo `--finza-dark` + badge azul "Cobrança 4.0" — primeira coisa que o leitor vê, explica o conceito: modelo digital multicanal (WhatsApp/e-mail/RCS), regras por carteira, IA conversacional, atuando da cobrança amigável até a notificação extrajudicial. Fases reescritas com base na régua real (`Apresentacoes/Régua de Comunicação_Atualizada.pptx`): D-10 → D+15 amigável, D+16 → D+60 Cobrança 4.0 (card destacado em `--finza-blue-soft`), D+46+ extrajudicial. Funções enxutas para apenas as 9 com correspondência verificável nas 27 tools MCP do doc canônico — removidas afirmações genéricas como "disparo 24/7", "compliance embutido", "negociação padronizada" da v7. Gaps mantidos, mas compactados em grid 4×1 com border-left laranja (em vez de cards dotted). Removidas as classes `.esperanza-intro`, `.esp-block`, `.esp-block-title`, `.biz-list`, `.esp-gaps`, `.esp-gap-card`, `.esperanza-foot` da v7; criadas `.esp-hero`, `.esp-section-label`, `.esp-phases`, `.esp-phase`, `.esp-funcs`, `.esp-func`, `.esp-gap-row`, `.esp-gap-mini`. Total: 7 slides.
- **v7 (12/05/2026)** — Enxugou de 9 para 7 slides. Removidos os slides "Torre — 7 sistemas principais" e "Torre — capacidades técnicas" — densidade técnica que não acrescentava ao roteiro para o CTO (slide de proposta+objetivos + slide de problemas já dão a leitura necessária). Slide da Esperanza **reescrito com lente de negócio**: substituiu a apresentação técnica da v6 (5 camadas de prompt, 27 ferramentas MCP, modelo, multi-provider) por layout 2 colunas mostrando o que ela entrega à operação Finza hoje (fases que cobre, agilidades, ganhos) versus os gaps que ainda deixamos na mesa (4 problemas mapeados pelo supervisor: E01 delírio em conversas longas, E02 cobranças indevidas, E03 informações imprecisas, E04 workflow >1m30s). Cards de gap usam `--warning` (laranja) pra diferenciar dos P01-P06 azuis do slide de problemas da Torre. CSS limpo: classes `.layer-stack`, `.layer-item`, `.esperanza-foot-row`, `.stat-row.four` (todas da v6) substituídas por `.esp-block`, `.biz-list`, `.esp-gaps`, `.esp-gap-card`. HUD dinâmico: contador agora mostra "n / 7". Total: 7 slides.
- **v6 (12/05/2026)** — Alinhamento da Torre e da Esperanza aos docs canônicos `Docs/TORRE_DE_CONTROLE_OVERVIEW.md` e `Docs/ESPERANZA_AGENT_OVERVIEW.md`. Slide 4: lede do `torre-proposal` ganhou "1.000 a 100.000+ contatos", multi-canal nativo, cobrança preventiva D-7/D-1; 6 objective-cards reescritos pra refletir os 6 objetivos do doc §2 (Maximizar recuperação / Reduzir custo por contato / Manter consumidor protegido / Visibilidade total / Autonomia sem TI / Inteligência aplicada). Slide 5: 7 system-cards densificados com regras críticas do doc §4 (title-centric, dedup 4D, reconciliação ETL, 3 modos do Maestro, 5 papéis RBAC, memória persistente, motivos de transbordo). Slide 6: stat-row trocou "2 tenants" por "64 edge functions"; cap-card de integrações removeu Bitrix e listou canais reais (Evolution/Hyperflow/n8n/Resend/SendGrid/Twilio/Zenvia/Vonage); API REST listou endpoints; "Fora do escopo" alinhado ao doc §14; diff-list trocou "STIA mostrou que funciona em treinamento" por "Atribuição de pagamento (janela 48h)". Slide 8 (Esperanza) reescrito: intro "não é chatbot, é agente" + stat-row mini (27/5/7/8) + visualização das 5 camadas de prompt + foot row com Modelo (Claude Sonnet 4) / Canais / Ownership; removidas menções a "Salvador" e "fases amigável → cobrança 4.0 → notificação extrajudicial" (não aparecem no doc canônico). Total: 9 slides.
- **v5 (12/05/2026)** — Enriqueceu a Torre de 1 slide para 4: novo Slide 4 (proposta + 6 objetivos estratégicos em grid de border-left azul), novo Slide 5 (7 sistemas principais em grid 4 colunas com header azul + body branco + card de glossário), novo Slide 6 (capacidades técnicas: stat-row com 21 telas / 14 crons / 12 status / 86+ variáveis / 2 tenants + cap-block 2×2 com resiliência, integrações, API REST, fora do escopo + diff-block com 10 diferenciais). Slide 7 (problemas) trocou emojis por tags numéricas P01-P06. Slide 3 banner perdeu emoji 🎯. Slide 4 antigo de módulos foi absorvido pelo novo conteúdo. Deck inteiro profissionalizado: emojis decorativos fora, bullets `▸` em azul, tipografia hierárquica. Total: 9 slides.
- **v4 (12/05/2026)** — Enxugou para 7 slides. Removidos: "Roadmap em sprints" (era 7), "Pendências mapeadas" (era 8), "Riscos visíveis" (era 9). Estrutura final: Capa → Cobre/Não cobre → Plataformas → Torre (o que é) → Torre (problemas) → Esperanza → Próximos passos. Conversa fica focada em diagnóstico técnico da Torre + plano imediato; estado do roadmap e riscos passam a viver fora do deck.
- **v3 (12/05/2026)** — Conteúdo mais técnico. Removidos slides "Plano herdado — 6 sprints até 10/jul" (era 6) e "O que preciso de você — Pedido + Fechamento" (era 10). Slide 2 (cobre/não cobre) ganhou pílulas mais coerentes (Problemas técnicos da Torre / Detalhamento do plano herdado). Slide 3 (Plataformas) expandido — cards mais altos, com TL + descrição mais densa, deixando claro que **Finza Start é portal do cliente Finza correspondente**. Slide 4 (Torre) dividido em 2: "o que é" (mantido) + novo **Slide 5 "Torre — problemas mapeados"** com 6 cards em grid 2×3 (ambientes, backend Supabase, versionamento, QA, priorização de negócio, dependência IAF) cada um com proposta de mitigação. Subtítulo do slide Sprints carrega referência ao plano aprovado. Novo **Slide 10 "Próximos passos"** dark splash em 2 colunas (Squad / Torre técnico). Continua 10 slides.
- **v2 (12/05/2026)** — Repaginação visual com paleta corporativa Finza (`#1A1AFF`, fundo cinza claro, splash dark). 10 slides (fundi 3+4 e 11+12). Setas `‹ ›` clicáveis para navegação por mouse. Marcador `◆ iaf` no canto. Cards com borda dotted azul. Numeração tipo "olho". Criados docs `PLATAFORMAS.md` e `CONTEXTO-FINZA.md` na pasta `Docs/`. Slide 3 agora nomeia plataforma de cada etapa. Conteúdo geral mais técnico (CTO já conhece Finza).
- **v1 (12/05/2026)** — Primeira entrega: 12 slides, paleta `#3D3DFF`, navegação só por teclado, descrições genéricas no fluxo.
