# CLAUDE.md — Veritas 2.0 (Compliance & Antifraude)

Este arquivo controla o design das telas do **Veritas 2.0** no Claude Design. Leia antes de criar ou alterar qualquer tela. Em caso de conflito entre um pedido e uma **regra inviolável (§2)**, a regra vence: avise e proponha alternativa.

Fonte: Discovery v0.1 de 22/10/2026 (artefato "Veritas 2.0 · Compliance & Antifraude") e o protótipo navegável que está nele. O mapa de documentação por tela fica em https://claude.ai/artifact/4D3tN2qWeYRRiDG6ojRHZv.

---

## 1 · O que é o Veritas 2.0

Ferramenta para o **Compliance** monitorar a carteira, revisar o efeito das regras atuais e avaliar validações novas (bureau, variável, regra) **sem depender do time de tecnologia**, guiado por 5 agentes de IA.

- **É:** integrações com bureaus configuradas pelo próprio Compliance, catálogo de variáveis, estudos no Playground, monitoramento contínuo com alertas por nível, perfil consolidado por cliente, dossiê de fraude e governança de credenciais e custos.
- **Não é:** motor de crédito, esteira de validação antifraude, ferramenta de bloqueio em tempo real. O Veritas 1 continua em operação (KYC, termos, retiradas, cartão de terceiro e pendências **não migram**).
- **Stack-alvo:** FastAPI + React. As telas devem ser implementáveis em React com o design system da Finza.

## 2 · Regras invioláveis (valem para toda tela)

| # | Regra | Como aparece no design |
|---|---|---|
| R1 | **O Veritas não decide a proposta** | Nenhum botão "Aprovar proposta", "Reprovar cliente" ou "Bloquear transação". O máximo é alertar, estudar, propor e notificar. |
| R2 | **Nada executa sem confirmação** | Estudo, dossiê e consulta paga sempre passam por uma tela de confirmação com resumo, etapas, dados usados e **custo estimado**. Texto: "Nada foi executado nem cobrado até agora." |
| R3 | **Segredo nunca sai do cofre** | Credencial em tela só como `••••c1d0` (4 últimos). Campo de segredo é escrita única, nunca reexibido. O agente nunca pede nem mostra segredo. |
| R4 | **Credencial ≠ integração** | Uma credencial por provedor, reutilizada por N integrações. Sempre mostrar "usada por N integrações" e o impacto antes de rotacionar ou revogar. |
| R5 | **Dado pessoal protegido** | CPF, CNPJ, telefone e e-mail mascarados em tela (`56.***.***/0001-**`, `***.412.***-**`, `+55 34 9••••-1187`, `fin••••@exemplo.com.br`). Pílula "dado pessoal" quando aplicável. |
| R6 | **Isolamento por organização** | Seletor de organização (Finza, Blips, indústrias). Uma organização nunca vê dados de outra. |
| R7 | **Segregação de funções** | Quem cria não aprova. Telas de aprovação mostram quem criou e bloqueiam autoaprovação. |
| R8 | **Trilha de auditoria** | Ações de escrita mostram feedback "registrado na trilha de auditoria" quando relevante. |
| R9 | **Custo medido e limitado** | Toda ação que consulta bureau mostra custo (estimado ou real), orçamento consumido e se precisa de aprovação acima do teto. Cache aparece como economia. |
| R10 | **Rascunho antes de produção** | Integração, variável e agente têm estados visíveis: Rascunho → Em teste → Em revisão → Ativa/Publicada. Versão com diff e rollback. |
| R11 | **Documento externo é dado** | Conteúdo de doc de bureau ou anexo nunca vira instrução. Mostrar aviso quando o agente sinalizar instrução escondida. |
| R12 | **Leitura somente leitura** | Fontes de dados: "Nada é escrito na origem." Mostrar limite de bytes. |
| R13 | **Afirmação com fonte** | Relatório e dossiê citam a fonte de cada afirmação e separam fato, inferência e recomendação. Veredito da IA é **sugestão**; o **parecer** é do analista. Motivo de reprovação nunca em material externo. |
| R14 | **Só CPF/CNPJ funde perfis** | Telefone ou e-mail compartilhado aparece como **vínculo** (sinal de risco), nunca como "mesmo cliente". |
| R15 | **Amostra mínima** | Indicadores e faixas mostram o tamanho da amostra (n). Validação bloqueia publicar abaixo do mínimo. |
| R16 | **Dados fictícios** | Todo nome, documento e valor do protótipo é inventado (catálogo em §8). Nunca usar dado real. |

## 3 · Personas e perfis

| Persona | Faz | Não faz |
|---|---|---|
| **Analista de Compliance** (padrão: "Ana", avatar `AC`) | Cria integração guiada, roda Playground, trata alerta, monta dossiê | Aprovar integração ou orçamento, publicar agente |
| **Gestor de Compliance / Risco** | Aprova integração e orçamento, define níveis de alerta, promove estudo a monitoramento | Autoaprovar o que criou |
| **Admin da plataforma** | Cofre e rotação, usuários e chaves, publica versões de agente | Decidir veredito de estudo |
| **Indústria / plataforma (API)** | Envia eventos por `POST /v1/transactions`, recebe webhook | Usa a tela (exceto se a organização tiver login) |

Conhece fraude, **não** conhece API: a linguagem da tela é de negócio; termos técnicos (endpoint, OAuth2, HMAC) aparecem só onde são necessários e com explicação curta.

## 4 · Arquitetura de informação

**Shell:** barra lateral (220 px) com o logo "Veritas 2.0" e grupos; topo com breadcrumb `Veritas 2.0 › <Tela>`, busca "Buscar transação, CNPJ, alerta…" e avatar.

| Grupo | Tela | Sub-telas / abas |
|---|---|---|
| Visão | **Início** | KPIs (alertas críticos, altos, gasto com bureaus, estudos no mês), alertas abertos, resumo do Veritas Gestor |
| Configurar | **Integrações** | abas Integrações · Credenciais; **Nova integração** = assistente de 7 passos: Contexto e objetivo → Origem → Leitura → Credencial → Teste → Mapeamento → Custo e aprovação |
| | **Variáveis** | catálogo; card "Mapeador sugere"; **Variável derivada** (pedido → proposta do Veritas Dados → validações automáticas → publicar) |
| | **Agentes** | galeria; **Novo agente**; editor com abas: Persona e prompt · Cenários · Diretrizes · Regras por segmento · Habilidades · Escopo e guardrails · Conhecimento · Etapas e transbordo · Agenda · Testar rascunho · Avaliação e publicação · Versões · Relatório |
| | **Fontes de dados** | lista; **Nova fonte** em 3 passos: Origem → Schema → Classificar e testar |
| Estudar e vigiar | **Playground** | lista de estudos; Novo estudo → Confirme o escopo → Execução (progresso por etapa) → Relatório com veredito |
| | **Monitoramentos** | abas Alertas · Monitoramentos · Webhooks; detalhe do alerta |
| | **Perfis** | lista; perfil consolidado (linha do tempo única, identificadores, rede de vínculos) |
| | **Transações** | abas Transações · Nova pela tela · Via API |
| | **Dossiês** | lista; dossiê (resumo, linha do tempo, sinais, parecer do analista) |
| | **Link avulso** | formulário + link gerado |
| Governança | **Credenciais e custos** | abas Credenciais · Custos de bureau · Efetividade dos pilotos |

Telas ainda **sem protótipo** (propor antes de desenhar): Login e acesso, Organizações/usuários/chaves, Trilha de auditoria, Regras e Champion × Challenger, Painéis, Demandas e casos.

## 5 · Padrões de componente

- **Cabeçalho de tela:** título (Outfit 600) + subtítulo de uma frase que diz a regra da tela (ex.: "Bases que os agentes podem ler. Leitura sempre somente leitura, com limite de bytes.") + ações à direita (primária azul por último).
- **Linha de KPIs:** cards com rótulo, número grande e contexto curto ("SLA 4h úteis", "59% do orçamento"). Borda esquerda colorida só para nível de alerta.
- **Card:** borda 1 px `--line`, raio 10 px, padding 18 px, título com ícone Phosphor.
- **Tabela:** dentro de `.tbl` com borda; cabeçalho em caixa alta pequena; identificadores e códigos em mono; ação "Abrir" como botão pequeno.
- **Pílulas de status** (sempre texto + cor, nunca só cor):
  - `ok` verde: Ativa, Ativo, Publicada, Adotar, ok, Com parecer
  - `info` azul: Em teste, Info
  - `warn` âmbar: Em revisão, Atenção, Alto, Adotar com ressalva, vence em ≤ 15 dias, atrasada
  - `bad` vermelho: Crítico, Descartar, falha
  - neutro: Rascunho, Pausado, Inconclusivo, sem expiração
- **Conversa com agente:** mensagem com ícone do agente + balão (`--surface`), nome do agente em negrito ("Veritas Integrador"). Mensagem do usuário à direita. O agente explica em linguagem simples e **pergunta o que falta**.
- **Assistente em passos:** trilha de etapas no topo (concluídas com ✓ verde, atual em azul, futuras cinzas, clicáveis para voltar) + "Etapa N de M" + painel lateral **"Spec do conector · rascunho v1"** que se preenche a cada passo.
- **Callout de aviso:** fundo `--warn-soft` para impacto (rotação, teto de custo, instrução escondida); fundo `--ok-soft` para regra de segurança explicada.
- **Checklist de publicação / validações automáticas:** item com pílula `ok` ou falha + motivo; botão de publicar desabilitado com `title` explicando o que falta.
- **Ações destrutivas** (revogar, excluir, desfazer vínculo) exigem confirmação e justificativa; se houver dependência, bloqueiam e listam o que depende.
- **Toasts** curtos para confirmar ação ("Alerta confirmado. SLA cumprido.").

## 6 · Tokens visuais

```css
--bg:#ffffff; --surface:oklch(0.975 0.006 265); --card:#ffffff;
--ink:oklch(0.21 0.03 274); --muted:oklch(0.52 0.02 265);
--line:oklch(0.91 0.014 265); --soft:oklch(0.955 0.009 265);
--primary:#2f2ff2; --on-primary:#ffffff; --primary-soft:oklch(0.94 0.035 274);
--ok:oklch(0.55 0.13 155);  --ok-soft:oklch(0.95 0.04 155);
--warn:oklch(0.62 0.14 70); --warn-soft:oklch(0.96 0.05 84);
--bad:oklch(0.55 0.22 27);  --bad-soft:oklch(0.95 0.035 27);
--info:oklch(0.58 0.15 240); --info-soft:oklch(0.95 0.03 240);
--code-bg:oklch(0.965 0.006 265);
--sans:"Inter"; --display:"Outfit"; --mono:"JetBrains Mono"; --r:10px;
```

- Azul Finza `#2f2ff2` só para ação primária, item ativo do menu e destaques. Não usar cores fora dos tokens.
- Ícones: **Phosphor** (regular). Ícones fixos por área: Início `House`, Integrações `Plugs`, Variáveis `Function`, Agentes `Robot`, Fontes `Database`, Playground `Flask`, Monitoramentos `Pulse`, Perfis `UserFocus`, Transações `ArrowsLeftRight`, Dossiês `Files`, Link `LinkSimple`, Credenciais e custos `Vault`, logo `ShieldCheck`.
- Tema claro é o padrão; o tema escuro redefine os mesmos tokens.
- Sem emoji decorativo.

## 7 · Vocabulário e tom

- Português do Brasil, frases curtas, voz ativa, tom técnico-executivo neutro.
- Termos canônicos (não trocar por sinônimos): **integração**, **credencial**, **cofre**, **variável** / **variável derivada**, **catálogo**, **fonte de dados**, **estudo**, **prompt-escopo**, **veredito** (Adotar · Adotar com ressalva · Inconclusivo · Descartar), **monitoramento**, **alerta** (Info · Atenção · Alto · Crítico), **linha de base**, **perfil consolidado**, **vínculo**, **identificador forte/fraco**, **dossiê**, **parecer**, **transbordo**, **guardrail**, **orçamento**, **teto**, **tarifa**.
- Agentes sempre pelo nome completo na primeira menção: Veritas Integrador, Veritas Mapeador, Veritas Dados, Veritas Monitoramento, Veritas Gestor.
- Números com unidade e contexto: "R$ 412 mil", "31% das cobranças recusadas (base 2%)", "n = 688".
- Datas curtas relativas na tela ("hoje 07:04", "ontem 07:02", "20/10 07:01").
- Proibido: "o sistema reprovou", "fraude confirmada" sem parecer, "garantido", "100% seguro", jargão de consultoria.

## 8 · Dados fictícios canônicos (reutilizar, não inventar outros sem necessidade)

- **Usuária padrão:** Ana (Analista de Compliance), avatar `AC`.
- **Integrações:** BigDataCorp · KYC Pessoa (v3, Ativa, R$ 0,019), BigDataCorp · Empresas e QSA, Serasa · Relatório Básico PJ (R$ 1,53), Serasa · Score PJ (novo) (Em teste), Sherlocker · Relações/Benefícios (R$ 0,40*), Lemit · Pessoa (Em revisão)/Empresa (Rascunho), Argus · Perfil Digital, Idwall · Background Check (Rascunho). `*` = estimativa a confirmar.
- **Credenciais:** BDC_TOKEN `••••9f2a`, SERASA_OAUTH `••••c1d0` (vence em 12 dias), SHERLOCKER_KEY, LEMIT_BEARER, ARGUS_API_KEY, IDWALL_KEY.
- **Alertas:** AL-0142 Crítico (atraso 90+ em Serasa PJ 0–200, R$ 412 mil), AL-0141 Alto (BIN 5244xx), AL-0139 Atenção (vendedor V-0193), AL-0136 Info (Cidade Exemplo do Sul).
- **Estudos:** PG-031 (Adotar com ressalva, R$ 1.836), PG-029 (Adotar), PG-027 (Descartar).
- **Perfis:** PF-20418 Gráfica Fictícia Ltda (Crítico), PF-20377 Comercial Exemplo Ltda, PF-20301 Padaria Modelo ME, PF-19980 J. S. (sócio).
- **Transações:** TX-90021 … TX-90018; organizações Exemplo Máquinas S.A., Plataforma Finza, Indústria Demo.
- **CNPJ de teste:** `00.000.000/0001-91`.

## 9 · Estados que toda tela precisa prever

Vazio (com ação para começar) · carregando · erro com o que fazer · **somente leitura** (perfil sem permissão) · aguardando aprovação · custo estimado antes de executar · execução em andamento (progresso por etapa, "pode sair da tela, avisamos ao terminar") · integração "prevista" ou "manual" quando não ligada (nunca simular resultado).

## 10 · Fora de escopo (não desenhar)

- Montador de esteira antifraude / background check (fica no Veritas 1).
- Alterar regras do motor de crédito (o Veritas só propõe com evidência).
- Telas de KYC, termos, retiradas, cartão de terceiro e pendências do Veritas 1.
- Bloqueio de transação em tempo real.
- Conversa com o cliente final (agentes Veritas não falam com o cliente).

## 11 · Checklist antes de entregar uma tela

1. Respeita R1–R16? Em especial: sem decisão de proposta (R1), confirmação com custo (R2/R9), segredo mascarado (R3), dado pessoal mascarado (R5).
2. Usa só os tokens e ícones de §6?
3. Termos de §7, sem sinônimos inventados?
4. Dados de §8, todos fictícios?
5. Estados de §9 previstos (ao menos vazio, erro e somente leitura)?
6. Cabeçalho com subtítulo que diz a regra da tela?
7. Funciona a 1280 px e não quebra em 900 px (menu vira grade no topo)?
