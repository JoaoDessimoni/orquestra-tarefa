# 99 · Prompt para o Claude Design

> **Como usar:** cole o bloco da seção **A** no Claude Design para iniciar. Depois, para cada tela, cole o bloco **B** preenchido com o documento da tela correspondente (10 a 22).
> Os documentos deste pacote são a especificação funcional. O Claude Design é responsável pela nova linguagem visual — **sem perder funcionalidade**.

---

## A · Prompt de abertura (colar uma vez, no começo)

```
Você vai redesenhar o frontend da TORRE DE CONTROLE, a plataforma de cobrança
da Finza. É um SaaS multi-tenant, denso, operacional, usado todos os dias por
times de cobrança. Não é um site institucional: é uma ferramenta de trabalho.

════════════════════════════════════════════════════════════════════
1. O QUE O PRODUTO FAZ
════════════════════════════════════════════════════════════════════

A Torre pega a carteira de recebíveis de uma empresa, segmenta por regras, e
dispara cobrança automatizada (WhatsApp, e-mail, SMS, voz, RCS), acompanhando
o resultado até o pagamento.

Três características definem tudo:

• MULTI-TENANT — toda tela é "de uma organização". Trocar de organização troca
  o contexto inteiro. O seletor de organização precisa estar sempre visível.

• TITLE-CENTRIC — a unidade de trabalho é o TÍTULO (a parcela individual), não
  o cliente. Por isso quase toda tabela lista parcelas, não pessoas.

• COBRANÇA PREVENTIVA — "dias de atraso" ACEITA VALORES NEGATIVOS (D-7, D-1 =
  antes do vencimento). Qualquer visualização de atraso precisa do eixo negativo
  e de um marco visual claro no vencimento (D-0).

Esteira do produto (torne isso legível na navegação):
  Fonte de dados → ETL → base de parcelas → Filtros/Carteiras → Campanha
  → Régua (sequência de passos) → Ações → Envio → Resultado/Pagamento

════════════════════════════════════════════════════════════════════
2. ESCALA
════════════════════════════════════════════════════════════════════

• 26 páginas · ~450 componentes · ~90 modais/painéis
• Telas com 40+ colunas de tabela, wizards de 6 fases, editores de fluxo
• 5 papéis de acesso (owner > admin > manager > operator > viewer) +
  um papel interno transversal (super_admin, time Finza)
• Personas: gestor de cobrança, analista/operador, configurador de régua,
  administrador de dados, administrador da organização, time interno

════════════════════════════════════════════════════════════════════
3. STACK (o código gerado precisa caber nela)
════════════════════════════════════════════════════════════════════

React 19 · TypeScript · Vite · Tailwind CSS 4 (config CSS-first via @theme)
shadcn/ui sobre Radix UI · React Router 7 · TanStack Query 5 / Table 8 / Virtual
react-hook-form + zod · lucide-react (única biblioteca de ícones)
Recharts + Chart.js (hoje coexistem — UNIFIQUE em uma só)

Restrições herdadas (sincronização com Lovable.dev) — NÃO NEGOCIÁVEIS:
• Os primitivos ficam em src/components/ui/ — não mova a pasta
• Nunca cor hardcoded: sempre token CSS/variável
• Sempre import com alias @/ , nunca relativo
• Não migrar para Next.js

════════════════════════════════════════════════════════════════════
4. IDENTIDADE VISUAL ATUAL (ponto de partida, pode evoluir)
════════════════════════════════════════════════════════════════════

Azul Finza é a única cor de marca: #002FCC (hsl 226 100% 40%) no tema claro,
#194FFF (hsl 226 100% 55%) no escuro.

Tema claro:  fundo #FAFAFA · superfície #FFFFFF · texto #282C34
             secundário #F1F2F4 · texto secundário #6B7280 · borda #E5E7EB
             destaque suave #E6EBFF
Tema escuro: fundo #16181D · superfície #1C1F26 · texto #E6EBEF
             secundário #272C35 · texto secundário #9096A2 · borda #2B313B
             destaque suave #142352

Semântica (obrigatória — dezenas de badges e gráficos dependem dela):
  sucesso  #16A34A   pago, entregue, concluído, ativo, saudável
  atenção  #F59E0B   pendente, pausado, vence hoje, degradado
  erro     #EF4444   falha, exclusão, bloqueio, ação irreversível
  info     #0EA5E9   informativo, em processamento

Tipografia: Inter, corpo de 14px (NÃO 16 — é um painel denso), tabelas em 14px,
Dashboard em 16px com tabelas ainda em 14px. Títulos em 600 com tracking -0.025em.
Números com font-variant-numeric: tabular-nums.

Forma: raio base 8px (botão 6px, chip 4px, modal 12px, badge/avatar totalmente
redondo). Sombra discreta — a separação vem de borda e tom de superfície, não
de elevação forte.

Sidebar: 256px expandida ↔ 64px recolhida, item ativo em azul sólido,
tooltip à direita quando recolhida, estado persistido.

Você PODE modernizar a estética. Você NÃO PODE:
• trocar o azul de marca sem instrução explícita
• perder qualquer um dos papéis semânticos de cor
• aumentar a densidade base (o usuário precisa ver muita linha por tela)
• remover o tema escuro (é paritário, não secundário)

════════════════════════════════════════════════════════════════════
5. AS 10 DÍVIDAS QUE O REDESENHO PRECISA QUITAR
════════════════════════════════════════════════════════════════════

1.  Badge sem variantes semânticas → cada tela improvisa cor de status, e o
    mesmo status aparece com cores diferentes em telas diferentes.
    ENTREGUE: Badge com success/warning/info/destructive/neutral × solid/soft.

2.  Não existe DataTable compartilhado → cada tela reinventou ordenação,
    seleção, paginação e estado vazio.
    ENTREGUE: um DataTable único com ordenação, seleção + barra de ações em
    massa, seletor de colunas, densidade, paginação, virtualização, e estados
    de vazio/erro/atualizando.

3.  Combobox duplicado em 8 arquivos diferentes.
    ENTREGUE: um Combobox parametrizável (único/múltiplo, com ícone, com cor,
    com agrupamento, com criação inline).

4.  Alert só tem default e destructive → avisos improvisados.
    ENTREGUE: variantes completas.

5.  Button sem estado de carregamento → cada tela inventa o seu.
    ENTREGUE: prop loading no Button.

6.  Duas bibliotecas de gráfico → linguagem visual inconsistente.
    ENTREGUE: uma só, com tema único (cores, grade, eixo, tooltip, legenda,
    estado vazio, estado "sem dado suficiente").

7.  Sheet com largura única estreita, sobrescrita caso a caso.
    ENTREGUE: tamanhos nomeados.

8.  Dois mecanismos diferentes de trocar visualização.
    ENTREGUE: um ViewToggle extensível (tabela/cards/kanban/timeline).

9.  Validação ora no campo, ora só em toast → usuário não sabe onde olhar.
    ENTREGUE: erro sempre no campo + resumo no topo do formulário.

10. Termo técnico de banco vazando para a interface (nomes de disposição de
    pipeline, códigos internos).
    ENTREGUE: glossário de rótulos humanos.

════════════════════════════════════════════════════════════════════
6. PADRÕES QUE DEVEM SOBREVIVER (cada um resolve um problema real)
════════════════════════════════════════════════════════════════════

• CARREGAMENTO HÍBRIDO (assinatura do produto)
  Primeiro carregamento → ESQUELETO da estrutura final, nunca spinner nu.
  Atualização com dado na tela → MANTÉM o dado, escurece sutilmente
  (opacidade 60%, sem interação), mostra barra indeterminada fina no topo
  (2px) e gira o ícone do botão Atualizar.
  Existe porque o app NÃO revalida ao focar a janela — a atualização é manual
  e explícita, por decisão de produto (revalidar destruía formulários longos).

• AJUDA ESTRUTURADA
  Ícone "?" clicável (não só hover — precisa funcionar no toque) que abre um
  popover com campos fixos, nesta ordem:
      O que é · Origem · Como calcula (em bloco de código) · Quando acontece · Observação
  Este é o contrato de transparência da Torre. Estenda, não reduza.

• "INDISPONÍVEL" ≠ "ZERO"
  O sistema declara explicitamente quando NÃO SABE um número, em vez de
  publicar zero. Precisa de um tratamento visual próprio, distinto de
  "vazio" e de "erro".

• IDADE DO DADO
  Dashboard e Carteira leem uma view materializada refrescada por agendamento.
  O número pode ter horas. Torne a frescura do dado visível e consistente.

• CONFIRMAÇÃO PROPORCIONAL AO RISCO
  Nível 1: diálogo simples.
  Nível 2: digitar o nome/slug do recurso (excluir organização, excluir agente).
  Nível 3: modal com consequências e ESCOPO NUMÉRICO explícito
           ("vai enviar 4.812 mensagens; isto não pode ser desfeito").

• MODAL ACIMA DE PAINEL LATERAL (é comum confirmar algo a partir de um painel).

• PÁGINA DE GESTÃO (com sidebar) × EDITOR IMERSIVO (tela cheia, sem sidebar).
  Os editores de régua e de broadcast são imersivos por necessidade.

• FOLHA DE IMPRESSÃO: o Dashboard é impresso/exportado em PDF (A4, sidebar
  oculta, grid de 2 colunas vira 1, gráficos contidos).

• prefers-reduced-motion respeitado.

════════════════════════════════════════════════════════════════════
7. O QUE EU VOU TE ENTREGAR
════════════════════════════════════════════════════════════════════

Um documento por domínio de tela, com: identidade e rota, objetivo e persona,
anatomia visual, TODOS os campos (label, tipo, validação, default, opções),
TODOS os botões (label, variante, ícone, ação), TODAS as colunas de tabela,
todos os filtros, todos os modais, todos os estados, os fluxos de uso e as
dores mapeadas.

Documentos:
  10  Autenticação e Organização        16  Réguas de Cobrança
  11  Dashboard                         17  Disparos e Templates
  12  Ações                             18  Agentes de IA
  13  Gestão de Carteira                19  Fonte de Dados (ETL)
  14  Filtros e Portfólios              20  Integrações e Configurações
  15  Campanhas e Broadcast             21  Telas de Documentação
                                        22  Painel Maestro e elementos globais

════════════════════════════════════════════════════════════════════
8. COMO QUERO QUE VOCÊ TRABALHE
════════════════════════════════════════════════════════════════════

FASE 1 — Fundação (antes de qualquer tela)
  a) Proponha a linguagem visual: paleta completa (claro + escuro), escala
     tipográfica, espaçamento, raio, elevação, grade.
  b) Entregue os primitivos redesenhados: Button, Badge, Card, Input, Select,
     Combobox, MultiSelect, Table/DataTable, Tabs, Dialog, Sheet, Alert, Toast,
     Tooltip, Popover, Progress, Skeleton, EmptyState, ErrorState.
  c) Entregue o shell: sidebar (expandida/recolhida/mobile), cabeçalho de
     página, container de conteúdo, painel lateral do assistente.
  d) Entregue o tema de gráficos.
  Só depois disso vamos para as telas.

FASE 2 — Tela a tela
  Para cada documento que eu colar, entregue a tela redesenhada COMPLETA,
  usando os primitivos da Fase 1.

REGRAS DE ENTREGA
• HTML + Tailwind, componentes React quando fizer sentido.
• Sempre nos DOIS temas (claro e escuro).
• Sempre em português do Brasil, com os rótulos reais do documento.
• Sempre com dados de exemplo REALISTAS (nomes brasileiros, CPF/CNPJ
  formatados, valores em R$, datas em dd/mm/aaaa, telefones brasileiros).
  Nunca "Lorem ipsum", nunca "Item 1 / Item 2".
• Mostre os ESTADOS, não só o estado feliz: carregando (esqueleto),
  atualizando (dado + barra), vazio, erro, sem permissão, sem resultado de
  busca, e o estado "indisponível ≠ zero".
• Mostre os modais — eles são metade do produto.
• Responsivo: o corte é 768px. Abaixo disso, sidebar vira gaveta, tabelas
  rolam horizontalmente, filtros recolhem, abas rolam.
• Acessibilidade: elemento clicável é <button>/<a> (não <div>), foco visível,
  ação nunca só no hover, contraste mínimo AA, rótulo para leitor de tela em
  botão só-ícone.

REGRA DE OURO
Nenhuma funcionalidade documentada pode desaparecer. Se você achar que um
controle deveria sumir, PROPONHA a mudança em uma nota — não a execute
silenciosamente. Perder um botão aqui significa um time de cobrança sem
conseguir fazer o trabalho dele.

Comece pela FASE 1. Me mostre a proposta de linguagem visual primeiro, em
duas ou três direções diferentes, para eu escolher antes de você produzir
os primitivos.
```

---

## B · Prompt por tela (colar uma vez para cada documento)

```
Redesenhe a tela a seguir da Torre de Controle, usando os primitivos e a
linguagem visual que definimos na Fase 1.

ENTREGUE:
1. A tela completa no estado "com dados", nos dois temas.
2. Os estados: carregando (esqueleto), atualizando (dado + barra no topo +
   escurecimento), vazio, erro, sem permissão.
3. Cada modal/painel do documento, como artefato próprio.
4. A versão mobile (<768px).
5. Uma nota curta listando: o que você mudou em relação ao original e por quê;
   e o que você propõe mudar mas NÃO mudou por falta de decisão minha.

NÃO REMOVA nenhum campo, botão, coluna, filtro ou estado descrito abaixo.
Use os rótulos exatos em português. Use dados de exemplo brasileiros realistas.

ESPECIFICAÇÃO DA TELA:
<<< cole aqui o conteúdo do documento da tela (10 a 22) >>>
```

---

## C · Prompt de revisão (depois que o Claude Design entregar)

```
Confira a tela que você entregou contra a especificação, item por item:

1. Liste todos os CAMPOS da especificação e marque presente/ausente.
2. Liste todos os BOTÕES da especificação e marque presente/ausente.
3. Liste todas as COLUNAS de tabela e marque presente/ausente.
4. Liste todos os FILTROS e marque presente/ausente.
5. Liste todos os MODAIS e marque entregue/não entregue.
6. Liste todos os ESTADOS (carregando, atualizando, vazio, erro, sem permissão,
   indisponível) e marque entregue/não entregue.
7. Verifique: existe versão escura? existe versão mobile? todo elemento
   clicável é botão ou link? há foco visível? há ação só no hover?

Para cada item ausente, ou entregue e justifique a ausência.
```

---

## D · Quando for aplicar o HTML gerado no código real

Ao voltar com o `.html` do Claude Design para este workspace, o pedido para o Claude Code deve ser:

```
/torre entrar
```

e, dentro do subprojeto `cobranca-finza/`, delegar ao agente `torre-frontend`, informando:

1. O arquivo `.html` gerado.
2. Qual tela ele substitui (rota + arquivo em `src/pages/`).
3. Que os tokens novos entram em `src/index.css` (nos DOIS blocos: `@theme` e `.dark`, mais os componentes HSL crus em `:root`).
4. Que os primitivos alterados ficam em `src/components/ui/` — sem mover a pasta.
5. Que nenhuma cor pode ser hardcoded.
6. Que os hooks de dados (`src/hooks/*`) **não** mudam: o redesenho é de apresentação. Se a tela nova precisar de um dado que o hook não devolve, isso vira um item separado.

⚠️ Lembrete de fronteira: neste workspace (`orquestra-tarefa`) o Claude opera a Torre em **contexto + leitura**. Alteração de código da Torre acontece **dentro** de `cobranca-finza/`, e commit/push/PR são sempre dos desenvolvedores humanos.
