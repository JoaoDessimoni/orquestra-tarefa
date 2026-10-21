# Prompt para o Claude Design — Principais entregas do Q3/2026 (squad IAF)

> Período: **trimestre jul–set/2026**. Foco: as 4 entregas com maior valor de negócio, e não o volume total do trimestre (para o volume, ver `roteiro-prompt_claude-design_balanco-torre-q4_14-10-2026.md`).
> Fontes:
> - `Apresentacoes/entregues/entregas_roadmap_torre_dossie.html`: R18 Scorização de telefones (Quimera #7317) · R80 Gestão de custos da Torre (#7326) · STIA Torre multi-agentes (#3989)
> - Artefato **Link do Cliente**: https://claude.ai/artifact/AaP7bhxJcZXhyKoLbph6wB?sk=3d8loT5hmgPb_ljXYqAjUA
> - Artefato **Raio-X da Clara** (IAF-9715): https://claude.ai/artifact/Ji8RDmUHeqySPikicCRrZP?sk=IxarNrGCuzI4L56TbcBanQ
> - `Apresentacoes/entregues/clara.html`: dossiê da Clara (João Pedro, 15/07/2026)
>
> **Antes de colar:** anexe ao Claude Design o `clara.html` e o HTML (ou prints) dos dois artefatos. Ele não abre arquivos locais e talvez não acesse links compartilhados da org. Copie tudo a partir de `=== INÍCIO DO PROMPT ===`.

---

=== INÍCIO DO PROMPT ===

## 1. Papel e objetivo

Você é um designer de apresentações executivas com domínio de motion. Crie uma **apresentação em slides, em HTML single-file, animada, com transições e motion em cada slide**. Quem apresenta é o **Supervisor do squad IA & Automação da Finza (IAF)**, para liderança e negócio (cobrança, formalização, financeiro).

Tema: **as principais entregas do Q3/2026 (jul–set)**. São quatro, cada uma com um ganho de negócio claro:

1. **Link de cobrança gerado pela Torre**, com telemetria de tudo o que o cliente faz no link.
2. **Score de telefones**: a Torre passa a medir a qualidade do contato.
3. **Gestão de custos da Torre**: o custo de disparos, campanhas e agentes, comparado com a meta.
4. **Clara**: novo agente de IA que conduz a formalização pelo WhatsApp.

Mensagem central, para o público lembrar: **"A Torre deixou de só disparar. Agora ela sabe quem atende, o que o cliente fez e quanto isso custou."**

Slides **diretos**: um conceito por slide, título que já é a conclusão e pouco texto. O visual (mockups, gráficos, números) conta a história.

## 2. Público e tom

- Público: diretoria, C-level e líderes de negócio. Pouco tempo, foco em resultado.
- Tom: corporativo e direto. Frases curtas no padrão sujeito-verbo-objeto. Máximo de 3 bullets por slide e 12 palavras por bullet.
- Proibido: jargão de consultoria ("sinergia", "alavancar", "disruptivo"), euforia ("ótima notícia!") e emojis decorativos.
- Se um número tiver ressalva, declare a ressalva.
- Português do Brasil. Números no formato BR (83%; 3,69 d; R$ 1.234,56).

## 3. Identidade visual (Finza)

- Paleta (use só estes tokens):
  - `--finza-blue #1A1AFF` (primária, números grandes, accents)
  - `--finza-blue-deep #0F0F8C` · `--finza-blue-soft #E8E8FF`
  - `--finza-dark #0A0A2E` (fundo da capa, das aberturas de entrega e do fechamento)
  - `--bg #F2F2F2` (fundo dos slides de conteúdo) · `--surface #FFFFFF` (cards)
  - `--ghost #C8C8D4` (palavra "fantasma" nos títulos, peso 300)
  - `--text-muted #5C5C7A` · `--border #D8D8E5`
  - Status: `--success #10B981` · `--warning #F59E0B` · `--danger #EF4444`
- Tipografia: **Inter** (Google Fonts). No título, uma palavra em peso 300 na cor ghost e outra em peso 700 azul (ex.: "O link agora é *da Torre*").
- Cards com borda `2px dotted var(--finza-blue)`. Marcador **"◆ iaf"** discreto no canto superior direito de todo slide.
- Números-chave em azul, peso 700, tamanho grande.
- Stack: HTML + CSS + JS vanilla, arquivo único. Sem frameworks, sem libs de ícone, sem imagens externas. Ícones, gráficos e mockups em SVG/CSS inline.

## 4. Motion, transições e interatividade

- **Navegação:** ←/→, espaço e clique. `F` liga a tela cheia. `ESC` abre a visão geral em grade. Barra de progresso fina no topo e contador "N / M" no rodapé.
- **Transição padrão entre slides:** fade + deslocamento de 24 px, 500 ms, `cubic-bezier(.2,.8,.2,1)`.
- **Transição de abertura de cada entrega:** wipe azul (`--finza-blue`) da esquerda para a direita. O número da entrega ("01", "02"...) fica gigante e em ghost ao fundo, e o nome entra por cima.
- **Shared element (morph):** o card da entrega no slide 2 "voa" e vira o título do slide de abertura daquela entrega (FLIP animation).
- **Entrada em cascata (stagger):** 60–80 ms entre os elementos.
- **Números:** count-up na entrada, com decimais em vírgula.
- **Gráficos:** barras crescem, linhas se desenham (`stroke-dashoffset`) e o ponteiro do gauge gira até o valor.
- **Mockups vivos:** as telas de celular rolam e trocam sozinhas, como uma demo gravada (detalhe em cada slide).
- Respeitar `prefers-reduced-motion`: sem animação, só o estado final.
- 16:9, legível em projetor e com escala responsiva.

## 5. Componentes de referência (extrair dos anexos)

Reaproveite os componentes visuais dos artefatos anexados, adaptados à paleta da seção 3:

| Artefato | Componentes para extrair | Onde usar |
|---|---|---|
| **Link do Cliente** (protótipo, "como está na Torre em 08/10/2026") | Moldura de celular com status bar 9:41 · as 4 telas: **1 Acesso (código 0171)**, **2 Títulos**, **3 Pagamento (Pix/boleto)**, **4 Link expirado** · URL `finza.com.br/c/7Hq2xKp9` · card de equipamento com resumo "faltam 14 de 24" e parcelas embaixo · modal "a parcela 11 vence antes, já foi paga?" · aviso da janela de 20 dias · rodapé de ajuda (WhatsApp + app Finza) · seletor de marca **Finza / Blips / Ideal** · seletor Celular/Computador | Slides 3, 4 e 9 |
| **clara.html** (dossiê da Clara) | Linha de evolução em 4 estágios ("Antes · Depois · A partir daí · Hoje") · grid de funcionalidades com ícone SVG de traço fino · passos numerados da coleta guiada (1–5) · callout "Humana no fim" · pílulas de resumo · mockup de conversa no WhatsApp | Slides 7 e 8 |
| **Raio-X da Clara** (IAF-9715) | Cards de número grande + título + linha explicativa · funil de barras horizontais decrescentes com número e % · selos de status ("Corrigido", "Aberto", "A investigar") · selos de fonte F1–F10 | Slide 8 |
| **Dossiê do roadmap da Torre** | Pílula de frente com código colorido (AC Ações, CU Custo, AG Agentes) · ficha de entrega com dono, início → entrega e key do Quimera | Rodapé dos slides 5 e 6 |

## 6. Base de dados (use exatamente estes números)

### 6.1 Link de cobrança (Torre)
- O link de cobrança passou a ser **gerado pela própria Torre**, com marca por empresa (**Finza, Blips, Ideal**).
- Jornada do cliente no link: **acesso com código** → **títulos** (equipamentos antes de suprimentos; cada item com resumo e parcelas pagáveis) → **pagamento** (Pix/boleto) → **expiração**.
- Regras de negócio visíveis:
  - O link mostra só parcelas vencidas e as dos **próximos 20 dias**. O botão de adiantar foi removido.
  - **Pagamento fora de ordem** é interceptado: ao pagar a parcela 12, o link pergunta se a 11, que vence antes, já foi paga.
  - Ajuda por WhatsApp e app Finza no rodapé e nas telas de link expirado e de acesso pausado.
- **Telemetria:** a Torre registra o que o cliente fez no link. Números a preencher:
  - `[DADO: links gerados no trimestre]`
  - `[DADO: % de links acessados]`
  - `[DADO: % que chegaram à tela de pagamento]`
  - `[DADO: % que geraram Pix/boleto]`
  - `[DADO: % de links expirados sem acesso]`
  - `[DADO: data de entrada em produção do link]`

### 6.2 Score de telefones (R18 · Quimera #7317 · dev Marcos · 16/09 → 22/09/2026)
- Modelo estatístico que pontua cada telefone a partir dos status retornados pela **Meta** e pelo **Hyperflow**.
- Identifica **números que bloquearam a Finza**, **qual número foi bloqueado** e **números que não são WhatsApp**.
- Base disponível **no front da Torre e no banco**. Era desenho do zero: não existia score de telefone na Torre.
- Ganho: a régua para de gastar disparo em contato ruim e prioriza o canal que atende.
- Números a preencher: `[DADO: telefones scorizados]` · `[DADO: distribuição por faixa de score]` · `[DADO: % bloqueado / não-WhatsApp]`

### 6.3 Gestão de custos da Torre (R80 · Quimera #7326 · dev Marcos · 16/09 → 28/09/2026 · 13 story points)
- Antes, a Torre não mostrava o custo da operação que ela mesma executa.
- Agora mostra o custo por **disparo, campanha, agente (IA)** e **meta**, e compara **custo × meta**.
- É diferente da redução de custos anterior (#4398), que atacou templates e modelo de LLM. Esta entrega é **gestão**: dá visibilidade contínua.
- Números a preencher: `[DADO: custo total do trimestre]` · `[DADO: custo por canal]` · `[DADO: custo por agente]` · `[DADO: custo por acordo/recuperação]`

### 6.4 Clara: agente de formalização
- Conduz a coleta de documentos da formalização pelo **WhatsApp**: ela inicia a conversa, pede **uma etapa por vez**, é **multimodal** (texto, áudio, imagem e PDF) e confirma o dado extraído com o cliente ("handshake do valor").
- **A decisão final é sempre de uma pessoa.** A Clara não aprova nem promete resultado.
- Evolução: **100% manual → automações por fase → Finza assume a coleta → Clara conversacional**.
- Faz parte da Torre multi-agente (#3989): Valentina, Prudente, Lívia, Clara e Francisco geridos dentro da Torre.
- Raio-X de setembro (IAF-9715):
  - **83%** dos contratos acionados (**381 de 457**)
  - **207** conversas com resposta (Finza + Blips)
  - **47** contratos (**10%**) com documentação aprovada e anexada
  - **86** contratos sem acionamento por falha técnica (03/09 a 14/09), já mapeada
  - **13%** dos contratos com telefone diferente no card e na plataforma. Esse é o elo com o **score de telefones**.
  - Funil de setembro: **461 → 376 → 315 → 225 → 158 → 85 → 47**. `[DADO: rótulo de cada etapa do funil — copiar do Raio-X]`

## 7. Roteiro slide a slide (alvo: 11 slides, ~10 min)

1. **Capa (fundo dark).** Título: "Q3/2026 · *Quatro entregas* que mudaram a cobrança". Subtítulo: "Squad IA & Automação — Finza · Outubro/2026". Motion: o "◆ iaf" pulsa uma vez, o título entra palavra por palavra e quatro pontos azuis acendem em sequência embaixo (prenúncio das 4 entregas).

2. **As quatro entregas.** Título: "A Torre agora *sabe mais*". Grid 2×2 com 4 cards dotted, cada um com número ghost (01–04), ícone SVG e uma linha de ganho:
   - 01 Link de cobrança: "O cliente paga pelo link, e a Torre vê cada passo."
   - 02 Score de telefones: "A Torre sabe qual número atende."
   - 03 Gestão de custos: "A Torre mostra quanto custa cobrar."
   - 04 Clara: "A formalização ganhou um agente de IA."
   
   Motion: os cards entram em stagger. Na saída, cada card faz o morph para a abertura da sua entrega.

3. **01 · Link de cobrança: a jornada (fundo bg).** Título: "O link agora é *da Torre*". Visual central: **um celular** (moldura do artefato Link do Cliente) que toca a demo sozinho: tela Acesso (os dígitos do código 0171 entram um a um) → Títulos (rola e mostra "faltam 14 de 24") → toque em "Pagar" na parcela 12 → modal "a parcela 11 vence antes, já foi paga?" → Pagamento (Pix) → check verde. À direita, 3 bullets curtos que acendem em sincronia com a demo: "Janela de 20 dias", "Pagamento na ordem certa", "Uma marca por empresa". Interativo: clicar em Finza/Blips/Ideal troca a cor do celular (Blips e Ideal em amarelo, como no artefato). Neste caso único, o amarelo fica restrito ao mockup.

4. **01 · Link de cobrança: a telemetria.** Título: "Cada *clique* do cliente vira dado". Esquerda: o mesmo celular, menor. Cada ação na tela solta um "evento" que voa para a direita (acesso, código validado, títulos vistos, clicou em pagar, Pix gerado). Direita: funil animado com os placeholders da seção 6.1 (gerados → acessados → chegaram ao pagamento → geraram Pix/boleto). Leitura no rodapé: "Antes, o link era uma caixa-preta. Agora sabemos onde o cliente desiste."

5. **02 · Score de telefones.** Título: "A Torre sabe *qual número atende*". Visual: lista de 5 telefones mascarados (ex.: (11) 9••••-1234) que entram em stagger. Cada um recebe um **gauge/barra de score** que se preenche e um selo: **Saudável** (verde), **Não é WhatsApp** (cinza), **Bloqueou a Finza** (vermelho), **Atenção** (laranja). Abaixo, uma faixa com as fontes do score: "Meta + Hyperflow → modelo estatístico → front e banco da Torre". Rodapé: pílula AC · R18 · #7317 · Marcos · 16/09 → 22/09. Bullet de ganho: "Menos disparo desperdiçado, mais contato efetivo."

6. **03 · Gestão de custos.** Título: "Quanto custa *cobrar*". Visual: mini-dashboard em card com 4 tiles (Disparos · Campanhas · Agentes · Meta) com count-up dos placeholders da seção 6.3. Embaixo, barra horizontal **custo × meta** que cresce até o valor, com a linha da meta tracejada. Contraste animado: um tile "Antes: sem visibilidade de custo" (ghost) se desfaz e dá lugar ao dashboard. Rodapé: pílula CU · R80 · #7326 · Marcos · 16/09 → 28/09.

7. **04 · Clara: quem é.** Título: "Clara, *formalização* sem atrito". Esquerda: a **linha de evolução em 4 estágios** do clara.html (Antes 100% manual → Automações por fase → Finza assume a coleta → Hoje Clara conversacional). Uma linha azul se desenha conectando os estágios e o último ganha destaque. Direita: **mockup de WhatsApp** com a Clara pedindo um comprovante, o cliente mandando um áudio, a Clara transcrevendo e confirmando o endereço ("handshake"). As bolhas aparecem com o indicador "digitando…". Faixa inferior com 4 pílulas: Ativa · Uma etapa por vez · Multimodal · Humana no fim.

8. **04 · Clara: primeiro mês em números.** Título: "Setembro: *83%* acionados". Linha de 3 cards de número grande (padrão do Raio-X): **83%** acionados (381 de 457) · **207** conversas com resposta · **47** documentações aprovadas. Abaixo, o **funil de barras** (461 → … → 47), que se desenha etapa por etapa. Callout honesto: "A perda está mapeada: 86 contratos sem acionamento por falha técnica e 13% com telefone divergente." Selos de status das causas: Corrigido / Aberto / A investigar.

9. **Como as quatro se conectam.** Título: "Uma *operação* só". Diagrama circular animado, com uma seta que percorre o ciclo: **Score de telefones** (contato certo) → **Clara / régua** (aborda) → **Link de cobrança** (cliente age) → **Telemetria** (sabemos o que aconteceu) → **Gestão de custos** (quanto custou) → volta ao score. No centro, a Torre (◆ iaf). Leitura: "O telefone divergente da Clara (13%) é exatamente o que o score resolve."

10. **O que muda para o negócio.** Título: "De *disparar* a *gerir*". Tabela antes × depois com 4 linhas que viram (flip) uma a uma:
    - Link: caixa-preta → jornada rastreada
    - Contato: dispara para todos → prioriza quem atende
    - Custo: invisível → por canal, campanha e agente
    - Formalização: manual → agente de IA com humano no fim

11. **Fechamento (fundo dark).** Frase grande: "A Torre deixou de só disparar. *Agora ela sabe quem atende, o que o cliente fez e quanto isso custou.*" Abaixo, 3 próximos passos em pílulas: `[PRÓXIMO: Clara — corrigir falha técnica e telefone divergente]` · `[PRÓXIMO: score na régua — regra de uso]` · `[PRÓXIMO: metas de custo por canal]`. Assinatura: "Squad IA & Automação — Finza · Supervisor João Vinícius".

## 8. Regras de conteúdo

- **Não invente números.** Use só os dados da seção 6. Mantenha os placeholders `[DADO: ...]` e `[PRÓXIMO: ...]` **visíveis e destacados** (fundo `--warning` suave), para eu preencher.
- Os dados dos mockups (código 0171, "faltam 14 de 24", parcelas 11 e 12, URL) são **fictícios**, vêm do protótipo. Marque com um selo discreto "simulação" no canto do celular.
- Telefones sempre mascarados. Nenhum dado real de cliente.
- Período explícito no rodapé dos slides de dados: "Q3/2026 (jul–set)". No slide 8: "Fonte: Raio-X da Clara · IAF-9715 · setembro/2026".

=== FIM DO PROMPT ===

---

## Notas para o João (não colar no Claude Design)

- **Faltam números de 3 das 4 entregas.** Link (telemetria), score (distribuição) e custos (valores) estão como `[DADO]`. Dá para puxar do Supabase da Torre via `/torre db` (read-only). Se quiser, eu rodo as queries e preencho. O clone local do `cobranca-finza` não mostra tabelas de telemetria do link nem de score; o schema de prod precisa ser conferido.
- **Data do link de cobrança:** não aparece no dossiê do roadmap como entrega com data. Confirme se entrou em produção no Q3 ou se é de out/2026. O artefato é "como está na Torre em 08/10/2026". Se for Q4, ajuste o título da capa ou apresente como "entregue na virada do trimestre".
- **Clara: 10% de documentação aprovada é baixo.** O roteiro leva o destaque para o acionamento (83%) e mostra a perda já mapeada. Não esconda os 47 se perguntarem: o argumento é que o gargalo está identificado (falha técnica de 03/09 a 14/09 + telefone divergente) e tem dono.
- **Score de telefones** foi entregue em 6 dias (16/09 → 22/09), mas o próprio card registrava "demanda enorme, falta definir pesos e modelo". Vale confirmar com o Marcos qual versão do modelo está em produção antes de dizer "modelo estatístico" em voz alta.
- O slide 3 permite o amarelo de Blips/Ideal **só dentro do mockup**. Se preferir paleta Finza pura, remova o seletor de marca.
