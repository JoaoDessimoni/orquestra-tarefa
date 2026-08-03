# RCS — Visão Executiva

> Base para apresentação ao CTO e ao Diretor de Operação.
>
> **Regra deste documento:** só entra o que **funciona hoje em produção**. Nada de roadmap, nada de "está previsto", nada do que ainda está em branch de release. Onde não há número comprovado, o documento diz que não há.
>
> Data-base: 28 de julho de 2026 · Detalhe técnico completo: [rcs.md](./rcs.md)

---

## 1. O que é RCS, em uma frase

**RCS é a evolução do SMS: uma mensagem rica — com imagem, título, texto formatado e botões — entregue no aplicativo de mensagens que já vem instalado no celular Android, em nome de uma marca identificada.**

Na prática da cobrança, a diferença para os canais que já usamos:

| | SMS | WhatsApp | **RCS** |
|---|---|---|---|
| Precisa de app instalado | não | **sim** | não |
| Imagem, título e botões | não | sim (template aprovado pela Meta) | **sim** |
| Aprovação de template a cada mudança | não se aplica | **sim, pela Meta** | **não — o template é criado e publicado na própria Torre** |
| Marca identificada na conversa | não | sim | sim |
| Botão que leva direto ao pagamento | só link colado no texto | sim | **sim, botão nativo** |
| Alcance | universal | quem tem WhatsApp | aparelhos Android compatíveis |

O ganho central para a operação: **um canal rico que não depende de o cliente ter um app, e cujo conteúdo a própria equipe publica sem esperar aprovação externa.**

> **Slide:** RCS é mensagem rica no app nativo do Android — o alcance do SMS com a apresentação do WhatsApp, e sem fila de aprovação de template.

---

## 2. O que já dá para fazer hoje

Tudo o que está nesta seção está **no ar**, é operado pela própria equipe na Torre e foi verificado no código em produção.

### 2.1 Criar o template rico na Torre — nos 3 formatos que existem

Pela tela de **Templates**, escolhendo o canal RCS, a equipe monta a mensagem em um dos três formatos:

| Formato | O que é | Limites reais |
|---------|---------|---------------|
| **Simples** | Texto, com imagem opcional e botões de resposta rápida | Texto até 3.000 caracteres; até 3 botões |
| **Card** | Imagem + título + descrição + botões — um "cartão" clicável | Imagem obrigatória; até 3 botões |
| **Carrossel** | Vários cartões que o cliente desliza para o lado | De 2 a 10 cartões; cada um com imagem e texto obrigatórios (texto até 1.000 caracteres) e no máximo 1 botão |

A tela mostra uma **prévia ao vivo** de como o cliente vai ver, ao lado do editor. Nada disso exige dev.

### 2.2 Subir imagem sem depender de dev

A equipe envia a imagem direto pela tela, ou reaproveita uma já enviada por uma **galeria** que lista as 100 imagens mais recentes da organização. O sistema valida na hora: `.gif`, `.jpg` ou `.png`, até 2 MB. A resolução sugerida (500×300) aparece como recomendação, não bloqueia.

**Atenção de segurança:** essas imagens ficam em um endereço público — quem tiver o link vê a imagem. **Nunca coloque dado pessoal de cliente na arte do card.**

### 2.3 Personalizar com variáveis

O texto, o título e o link do botão aceitam as mesmas variáveis dos outros canais, resolvidas no momento do envio com os dados reais do cliente. Confirmado como funcionando no canal RCS:

- **Nome do contato** (`{{contact.name}}`)
- **Número do título** (`{{title.number}}`) e **número do contrato** (`{{contract.number}}`)
- **Valor atualizado do título** (`{{title.current_value}}`, já formatado em reais)
- **Data de vencimento** (`{{title.due_date}}`, já formatada em dd/mm/aaaa)
- **Dias de atraso** (`{{title.days_overdue}}`)
- **Campos personalizados vindos do ETL** — os que a equipe cadastra na importação passam a estar disponíveis sozinhos, sem tocar em código
- Links dinâmicos (ex.: link de pagamento) no botão de URL

O motor que resolve essas variáveis é o mesmo de WhatsApp, e-mail, SMS e voz — não há uma segunda implementação para o RCS.

### 2.4 Criar campanha/régua com passo RCS

O RCS é **mais um passo (step) na régua de cobrança** — a mesma tela, o mesmo fluxo dos outros canais. Ao montar a régua, a equipe escolhe "RCS", seleciona a integração, escolhe o template e define em qual faixa de dias de atraso aquele passo dispara (inclusive **antes** do vencimento, na cobrança preventiva).

E com isso o RCS herda, sem nenhum trabalho extra, tudo que a Torre já faz:

- **Segmentação da carteira** pelos filtros e portfólios que a operação já usa;
- **Avaliação título a título** (um cliente com dívidas de faixas diferentes recebe o passo certo para cada uma);
- **Bloqueio de cobrança** (blocklist) nos três níveis: cliente, contrato e título;
- **Anti-duplicidade** dentro da campanha e entre campanhas;
- **Janela de envio** (dias da semana e horário, em horário de Brasília) e **feriados/datas bloqueadas**;
- **Limite de disparos por minuto**, por campanha e por canal;
- **Verificação de pagamento imediatamente antes de enviar** — se o cliente pagou, a mensagem não sai;
- **Botão de pausa** do canal, sem mexer nas campanhas;
- **Disparo em massa (broadcast)** também aceita o passo RCS;
- **Estimativa de custo** da campanha, usando o custo por envio cadastrado para o canal.

### 2.5 Botões de ação no card

A equipe define até 3 botões (1 por cartão, no carrossel), de dois tipos:

- **Link (URL)** — abre um endereço no celular do cliente (ex.: link de pagamento). Funciona ponta a ponta.
- **Resposta rápida (postback)** — quatro intenções pré-definidas: *Confirmação de pagamento*, *Realizar pagamento*, *Enviar comprovante* e *Falar com atendente*.

**O que o botão de resposta rápida faz hoje, com precisão:** a Torre **envia** ao orquestrador a informação de qual intenção está em cada botão. O que acontece **depois do clique** — responder, transferir para atendimento humano, registrar a intenção — é executado pelo fluxo externo (n8n/Hyperflow), **não pela Torre**. A Torre não recebe nem armazena o clique em si. O que ela enxerga é apenas a mudança de status da ação, se o fluxo externo devolver esse aviso.

<!-- TODO: confirmar com gestor — o que o fluxo externo faz hoje em cada uma das 4 intenções de botão, e se todas realmente abrem atendimento humano -->

Regras de montagem que a tela aplica sozinha: no máximo 1 botão de link por mensagem, e ele fica na última posição quando há 3 botões.

### 2.6 O que a operação enxerga depois do disparo

Cada envio de RCS vira uma **ação**, com o mesmo ciclo de vida dos demais canais e os mesmos 12 status já conhecidos pela operação (Pendente, Processando, Enviado, Interagiu, Solicitou Atendimento, Falha Temporária, Falha Definitiva, Em Atendimento, Cancelado, Cancelado (Pago), Cancelado (Removido), Duplicado).

Na tela de Ações, para cada envio de RCS, a operação vê: para quem foi, quando, qual campanha e passo geraram, o texto que saiu, o status atual e — em caso de erro — a mensagem de erro. Fica registrado também o conteúdo exato enviado, o que permite auditar depois "o que exatamente esse cliente recebeu".

**Precisão importante:** "Enviado" significa que o orquestrador aceitou o disparo — **não** é confirmação de que o aparelho recebeu. A confirmação de entrega/leitura, quando existe, aparece como **"Interagiu"** — e depende do retorno do fluxo externo (ver limitação 5.2).

> **Slide:** Hoje a operação cria template rico, sobe imagem, personaliza com dados do cliente e coloca RCS na régua — sozinha, sem dev e sem aprovação externa.

---

## 3. Como se encaixa no que já existe

Este é o ponto central para o CTO: **o RCS não é um sistema novo. É um canal a mais dentro do motor que já roda.**

```
      O QUE JÁ EXISTIA                            O QUE FOI ADICIONADO
 ┌────────────────────────────┐             ┌──────────────────────────────┐
 │  Carteira / ETL            │             │  Editor de template RCS      │
 │  Filtros e portfólios      │             │  (simples / card / carrossel)│
 │  Réguas e campanhas        │◀── usa ─────│  Galeria de imagens          │
 │  Motor de decisão          │             │  Passo "RCS" na régua        │
 │  (quem, quando, evita      │             │  Tradutor de conteúdo rico   │
 │   duplicidade, respeita    │             │  no ponto único de envio     │
 │   bloqueio e janela)       │             └──────────────────────────────┘
 │  Fila de envio                                        │
 │  Ponto único de envio                                 │ mesmo caminho
 │  Status das ações                                     │ dos outros canais
 └───────────────┬────────────────────────────────────────┘
                 │
                 ▼
   ┌───────────────────────────┐      ┌──────────────────┐      ┌───────────┐
   │  Orquestrador externo      │─────▶│ Plataforma RCS   │─────▶│  Cliente  │
   │  (n8n / Hyperflow)         │      │ + operadora      │      │  (Android)│
   └───────────────────────────┘      └──────────────────┘      └───────────┘
                 ▲                                                     │
                 └──────────── retorno de status ──────────────────────┘
```

Três consequências práticas dessa escolha:

1. **Reaproveitamento, não reconstrução.** Segmentação, anti-duplicidade, blocklist, janela de envio, tentativas, custos e relatórios de ação já funcionavam — o RCS entrou usando tudo isso. O que foi construído de fato: a tela de template rico, o armazenamento de imagem e a tradução do conteúdo rico no momento do envio.
2. **Um único ponto de saída.** Toda mensagem da Torre — de qualquer canal — sai por um mesmo componente. O RCS não abriu um segundo caminho de envio. Menos superfície para erro, um lugar só para auditar.
3. **A Torre não fala com a operadora.** Ela entrega o conteúdo pronto ao orquestrador externo, que fala com a plataforma RCS. Isso é **dependência de terceiro** e precisa entrar na conta de risco.

**Build vs. dependência, resumido para o CTO:**

| Camada | Quem faz |
|--------|----------|
| Template rico, imagem, variáveis, régua, segmentação, decisão de envio, status | **Nós (Torre)** |
| Transporte até a plataforma RCS e montagem final da mensagem | **Terceiro (orquestrador n8n/Hyperflow)** |
| Entrega ao aparelho, identidade da marca, regras da plataforma | **Terceiro (provedor RCS + operadora)** |
| Cadastro/verificação do agente (a "marca" no RCS) | **Fora da Torre** — ver §4 |

> **Slide:** RCS entrou como canal dentro do motor existente — reaproveitamento, não um sistema paralelo; o único trecho terceirizado é o transporte até a operadora.

---

## 4. O que a operação faz sozinha × o que exige time técnico

| Atividade | Operação, sozinha na Torre | Precisa de time técnico |
|-----------|:--------------------------:|:-----------------------:|
| Criar/editar/desativar template RCS (3 formatos) | ✅ | |
| Subir imagem e reaproveitar da galeria | ✅ | |
| Usar variáveis de cliente/título/contrato no texto e nos botões | ✅ | |
| Definir botões (link e as 4 respostas rápidas) | ✅ | |
| Criar régua com passo RCS e definir a faixa de dias de atraso | ✅ | |
| Segmentar a carteira (filtros e portfólios) | ✅ | |
| Configurar janela de envio, dias ativos e limite por minuto | ✅ | |
| Disparo em massa (broadcast) com RCS | ✅ | |
| Pausar o canal RCS (ou todos) sem alterar campanhas | ✅ | |
| Acompanhar status e auditar o que foi enviado | ✅ | |
| Cadastrar o custo por envio do canal | ✅ | |
| **Provisionar o agente RCS (a marca verificada) junto ao provedor** | | ⚠️ **Nem operação nem Torre** — é feito fora do sistema |
| **Cadastrar a integração e as credenciais do orquestrador** | | 🔧 Técnico |
| **Habilitar o canal em uma organização nova** | | 🔧 Técnico (uma vez por organização) |
| **Publicar o fluxo do lado do orquestrador (n8n/Hyperflow)** | | 🔧 Técnico / terceiro |
| **Mudar o comportamento de um botão de resposta rápida** | | 🔧 Técnico / terceiro (é lógica do fluxo externo) |
| **Reenviar uma ação que esgotou as tentativas** | | 🔧 Técnico |

> **Slide:** Do template ao disparo, a operação é autônoma; o time técnico entra só na porta de entrada (agente, credenciais, fluxo externo).

---

## 5. Linha do tempo da entrega

Do primeiro commit ao canal completo: **quatro semanas**, em seis entregas.

```
23/jun ──── 24/jun ──── 29/jun ──────── 03/jul ──── 06/jul ──────── 22/jul
  │           │            │               │           │               │
Canal no    Correção    RCS no          Simples e   Carrossel      Carrossel
   ar       de esteira  disparo         carrossel   no envio       entregue
                        em massa        no editor                  ponta a ponta
```

| Data | Entrega | Responsável |
|------|---------|-------------|
| **23 de junho de 2026** | **Canal RCS no ar.** Habilitação do canal em todas as organizações, armazenamento próprio de imagens, editor de template no formato *card* (imagem + texto + botões) com prévia, e o passo RCS disponível na régua | joaonetob |
| **24 de junho de 2026** | Correção na esteira de publicação (ordem de aplicação da mudança de banco) | joaonetob |
| **29 de junho de 2026** | **RCS habilitado também no disparo em massa** e nas organizações criadas depois | joaonetob |
| **3 de julho de 2026** | **Formatos *simples* e *carrossel*** no editor, com as regras de montagem, limites e a correção dos rótulos "RCS" nas telas de campanha e relatórios | João |
| **6 de julho de 2026** | Ajuste no formato de envio do carrossel para o parceiro | João |
| **22 de julho de 2026** | **Carrossel entregue ponta a ponta** + aviso na tela sobre mensagem só com imagem. Documentação para o usuário final atualizada na Central de Documentação | João |

> **Slide:** De canal no ar a carrossel completo em quatro semanas, com seis entregas incrementais em produção.

---

## 6. Apêndice

### 6.1 Glossário mínimo

| Termo | Em uma linha |
|-------|--------------|
| **RCS** | Mensagem rica no aplicativo de mensagens nativo do Android |
| **Agente RCS** | A identidade da marca dentro do RCS — cadastrada fora da Torre |
| **Template** | O modelo de mensagem criado na Torre (texto, imagem, botões) |
| **Card / Carrossel** | Cartão único com imagem e botões / vários cartões que o cliente desliza |
| **Resposta rápida (postback)** | Botão que sinaliza uma intenção do cliente, em vez de abrir um link |
| **Régua** | Sequência de passos de cobrança por faixa de dias de atraso |
| **Passo (step)** | Um envio dentro da régua — o passo RCS é um deles |
| **Ação** | Um envio individual para um cliente, com status próprio |
| **Título** | A dívida individual; o sistema decide título a título, não cliente a cliente |
| **Integração** | A conexão configurada com o sistema externo que transporta a mensagem |
| **Orquestrador (n8n / Hyperflow)** | O parceiro que recebe o conteúdo da Torre e entrega à plataforma RCS |
| **Edge Function** | Um pequeno serviço da Torre que roda no servidor — é o que faz o envio |

### 6.2 Rastreabilidade

Todo o conteúdo deste documento foi verificado contra o código em produção. O detalhamento técnico — arquitetura, dicionário de dados, contrato de payload, máquina de estados, logs e troubleshooting — está em **[docs/guides/rcs.md](./rcs.md)**, que também registra explicitamente o que está em branch de release e **não** entrou aqui.
