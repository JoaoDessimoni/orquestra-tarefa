# 01 · Visão Geral do Produto, Entidades e Vocabulário

> Fonte da verdade: `cobranca-finza/CLAUDE.md`, `cobranca-finza/docs/guides/visao-geral.md`, `docs/guides/fluxo-cobranca.md`, `src/pages/central-docs/negocio/data/*`.
> Este documento existe para que o designer **entenda o negócio antes de desenhar**. Toda tela da Torre é uma janela sobre uma destas entidades.

---

## 1. O que é a Torre de Controle

A Torre de Controle é a **plataforma de cobrança da Finza**: um SaaS multi-tenant que pega a carteira de recebíveis de uma empresa, segmenta por regras, e dispara comunicações automatizadas de cobrança (WhatsApp, e-mail, SMS, voz, RCS), acompanhando o resultado até o pagamento.

Em uma frase: **transforma uma base de parcelas em aberto numa operação de cobrança automatizada, mensurável e auditável.**

Três coisas definem o produto e precisam ficar legíveis no redesenho:

| Característica | O que significa |
|---|---|
| **Multi-tenant por schema** | Cada organização cliente tem seu próprio schema no banco. A interface é sempre "de uma organização"; trocar de organização troca todo o contexto. |
| **Title-centric** | A unidade de avaliação é o **título** (a parcela individual), não o cliente. Cada parcela é cobrada pelo próprio atraso. Isso explica por que quase toda tabela do produto tem linhas de parcela, não de pessoa. |
| **Cobrança preventiva é parte do produto** | `days_overdue` **aceita valores negativos** (D-7, D-1 = antes do vencimento). Qualquer visualização de "dias de atraso" precisa comportar o eixo negativo. |

---

## 2. Quem usa

| Persona | O que faz na Torre | Telas principais |
|---|---|---|
| **Gestor de cobrança / Head** | Acompanha resultado, decide estratégia, apresenta números. | Dashboard, Relatório de Ações, métricas de IA. |
| **Analista de cobrança (operador)** | Opera o dia a dia: monitora ações, resolve exceções, dispara pontual, atende caso a caso. | Ações, Gestão de Carteira, Disparos. |
| **Configurador / Especialista de régua** | Desenha as réguas, campanhas, filtros, templates. | Réguas, Campanhas, Filtros, Templates. |
| **Administrador de dados** | Configura as fontes, pipelines e a materialização. | Fonte de Dados (ETL), Configurações. |
| **Administrador da organização** | Usuários, papéis, integrações, chaves, valores padrão. | Configurações, Integrações. |
| **Time interno Finza (`super_admin`)** | Suporte, diagnóstico, documentação técnica, gestão de chaves de API. | Central de Documentação, Configurações avançadas. |
| **Agente de IA (não humano)** | Conversa com o devedor, aplica tags, transfere para humano. | Configurado em Agente IA; aparece como origem de ação e de métrica. |

---

## 3. Entidades do domínio

### 3.1 Núcleo da cobrança

| Entidade | O que é | Onde aparece na interface |
|---|---|---|
| **Contato** | A pessoa física/jurídica devedora. Tem nome, razão social, documento (CPF/CNPJ), telefones, e-mails, tags, selos e campos personalizados. | Gestão de Carteira (linha/card), painel de detalhe, busca global. |
| **Contrato** | Agrupa títulos de um mesmo acordo. Tem número, identificador externo. | Carteira (agrupamento e kanban de contratos), detalhe do contato. |
| **Título** | **A parcela individual em aberto.** Tem vencimento, `days_overdue` (pode ser negativo), status canônico, valor em aberto, valor pago. É a unidade de avaliação. | Carteira, aba de parcelas do contato, funil de cobrança. |
| **Suprimento** | Variante de título para organizações que operam suprimentos/insumos. | Aba Suprimentos do detalhe do contato. |
| **Ação** | Uma comunicação ou operação gerada para um título/contato: WhatsApp, e-mail, SMS, voz, RCS, webhook, negativação, notificação, bloqueio, atividade humana, gatilho de IA. Tem status canônico e histórico. | Tela de Ações, Relatório de Ações, histórico do contato. |

### 3.2 Segmentação

| Entidade | O que é |
|---|---|
| **Filtro** | Árvore de regras (campo + operador + valor) combinadas por E/OU, com grupos aninhados. Avaliado contra a base de títulos. |
| **Portfólio (carteira)** | Recorte dinâmico da base, definido por um filtro. **Não existe lista fixa de membros** — o portfólio é sempre reavaliado. |
| **Selo** | Marca aplicada a contato/contrato/título (catálogo próprio, com cor). |
| **Tag** | Rótulo conversacional, aplicado manualmente ou pelo agente de IA. |
| **Lista de bloqueio (blocklist)** | Alvos que **não** devem receber cobrança. Por entrada manual, por regra de filtro ou por origem externa. Tem 8 esferas de alvo e escopo por canal. |
| **Exceção de bloqueio** | **Neutraliza** um bloqueio sem apagá-lo. A entrada de bloqueio permanece e volta a valer quando a exceção vence. |

### 3.3 Automação

| Entidade | O que é |
|---|---|
| **Régua de cobrança (workflow)** | Sequência de **passos**. Cada passo tem um **gatilho** (faixa de dias de atraso, ou janela de dias na **etapa**) e um tipo (canal, webhook, condição, espera, bloqueio, negativação, notificação, atividade humana, gatilho de IA). Tem versões e publicação. |
| **Passo (step)** | A unidade da régua. Define quando dispara, o que faz, por qual integração e com qual conteúdo. |
| **Cauda** | Passo de **faixa aberta** (sem limite superior de dias) — "de X dias em diante". Precisa de cadência, senão dispara todo dia. |
| **Campanha** | Liga réguas a um gatilho (agendado / manual / ao fim do pipeline), a carteiras e a uma janela de envio. |
| **Execução (run)** | Uma rodada da campanha. Passa por 6 etapas e produz candidatos com **disposições** (motivos de inclusão/exclusão). |
| **Broadcast** | Disparo em massa com passos próprios, editado em tela cheia. |
| **Disparo** | Envio pontual, imediato, para um público escolhido na hora. |
| **Template de mensagem** | Conteúdo reutilizável por canal. Para WhatsApp, pode ser um modelo HSM aprovado pela Meta. |
| **Variável** | Token `{{...}}` substituído no envio. Dois tipos: **campo personalizado** (vem do ETL, propaga sozinho) e **campo de sistema** (computado). Desde 2026 pode ser **composta** (referencia outras) ou **lista** (de contratos/parcelas do contato). |

### 3.4 Dados

| Entidade | O que é |
|---|---|
| **Fonte de dados** | Origem externa dos dados (BigQuery, API, planilha...). Guarda a conexão e credenciais. |
| **Pipeline (ETL)** | Mapeia campos da fonte para as entidades da Torre, normaliza e agenda a importação. |
| **Execução / lote (job run / batch)** | Uma rodada do pipeline, com contadores e erros. |
| **Campo personalizado** | Coluna extra trazida pelo ETL, que vira filtro, coluna de carteira e variável de mensagem. |
| **Materialização (MV)** | View materializada com ~20 campos pré-calculados (`is_paid`, `aging_bucket`, `open_value`, `risk_level`...). É a **fonte de verdade** do Dashboard, dos Filtros e dos relatórios. Refrescada por agendamento cron por organização. |

### 3.5 Inteligência artificial

| Entidade | O que é |
|---|---|
| **Agente de IA** | Persona configurável que conversa com o devedor. Tem prompt, diretrizes, regras de negócio, etapas de funil, tags permitidas e versões. Pode ser `internal` (interno) ou externo. |
| **Protocolo** | Um atendimento. Tem status (`em_andamento`, `finalizado`, `transferido`, `transbordo`) e histórico de transições. É a unidade das métricas. |
| **Mensagem** | Turno da conversa. Fonte canônica única (`ai_messages`). |
| **Transferência / transbordo** | Saída do atendimento automatizado para humano. São **coisas diferentes** e contam diferente nas métricas. |
| **A2A** | Comunicação agente-para-agente, com fechamento próprio. |
| **RAG** | Base de conhecimento do agente (documentos + busca semântica). |
| **Maestro** | Agente operador da própria Torre, num painel lateral. Propõe e executa ações no sistema em modos `plan` / `semi_auto` / `full_auto`. |

### 3.6 Plataforma

| Entidade | O que é |
|---|---|
| **Organização** | O tenant. Tem slug, nome, logo, usuários, papéis, perfil de pipeline. |
| **Usuário e papel** | 5 papéis: `owner > admin > manager > operator > viewer`. `super_admin` é transversal (time Finza). |
| **Integração** | Conexão de saída configurável (HTTP): método, URL, cabeçalhos, autenticação, corpo com variáveis. É por ela que a mensagem sai. |
| **Chave de API** | Credencial universal (uma chave serve todas as orgs; a org vem no cabeçalho). Gestão exclusiva de `super_admin`. |
| **Webhook** | Retorno externo que atualiza o status da ação. |
| **Relatório agendado** | Envio periódico de relatório operacional ou de performance de IA. |

---

## 4. Fluxo macro — do dado ao pagamento

```
   FONTE EXTERNA (BigQuery, API, planilha)
        │  ETL agendado
        ▼
   CONTATOS · CONTRATOS · TÍTULOS        (schema da organização)
        │  refresh agendado da view materializada
        ▼
   BASE PRÉ-CALCULADA (vw_titles_live)   ~20 campos: is_paid, days_overdue,
        │                                 aging_bucket, open_value, risk_level...
        ├──────► FILTROS / PORTFÓLIOS  ──────► Dashboard, Carteira, Relatórios
        │
        └──────► CAMPANHA (gatilho: agendada / manual / pós-pipeline)
                     │  execução em 6 etapas:
                     │  resolver contatos → buscar títulos → casar com passos da régua
                     │  → aplicar regras (bloqueio, carência, prioridade)
                     │  → deduplicar entre campanhas → criar ações
                     ▼
                  AÇÕES (status Pendente)
                     │  processador, dentro da janela de envio permitida
                     ▼
                  ENVIO via integração → WhatsApp / E-mail / SMS / Voz / RCS
                     │
                     ├─ webhook de status  → Enviado / Interagiu / Respondido / Falhou
                     ├─ agente de IA assume a conversa → protocolo
                     └─ verificação de pagamento → atribuição (janela de 48h)
                     ▼
                  RESULTADO: pago, em atendimento, falhou, cancelado
```

**Implicação de design:** o produto é uma **esteira**. Cada tela é uma estação dela. O redesenho ganha muito se tornar essa esteira legível — hoje o usuário precisa saber de cor que "Filtros alimenta Carteira que alimenta Campanha que gera Ação".

---

## 5. Os dois vocabulários de "status" (armadilha)

A palavra *status* significa **três coisas diferentes** no produto. Confundi-las é o erro mais comum.

| Qual status | Onde vive | Valores |
|---|---|---|
| **Status do título** | A parcela | `Disponivel`, `Pago`, `Cancelado`, `Removido` (canônicos, em português; `Removido` ≠ `Cancelado`). |
| **Status da ação** | A comunicação | 12 valores — Pendente, Processando, Enviado, Interagiu, Respondido, Falhou, Falha Permanente, Em Atendimento, Cancelado, Cancelado (Pago), Cancelado (Removido), Duplicado. |
| **Status como campo do cliente** | Campo personalizado vindo do ETL | Livre. Serve a filtro, coluna e conteúdo de mensagem — **o motor de disparo não olha para ele**. |

E existe um quarto conceito que **não** é status: a **etapa** (`etapa`), um campo personalizado do contato que, em organizações com perfil de pipeline, **decide o envio**. Vocabulário oficial: **"a etapa decide o envio; o status é dado."**

> Para o redesenho: nunca rotular genericamente como "Status". Sempre qualificar — "Status da parcela", "Status do envio", "Etapa".

**Atenção adicional — rótulo exibido ≠ valor gravado.** Três status de ação têm rótulo de interface diferente do valor canônico:

| Valor canônico | Rótulo exibido |
|---|---|
| `Falhou` | Falha Temporária de Ação |
| `Falha Permanente` | Falha Definitiva de Ação |
| `Respondido` | Solicitou Atendimento |

---

## 6. Conceitos que a interface precisa comunicar bem (e hoje comunica mal)

| Conceito | Por que é difícil | Oportunidade no redesenho |
|---|---|---|
| **Idade do dado** | O Dashboard e a Carteira leem uma view materializada refrescada por agendamento. O número pode ter horas. | Indicador de frescor visível e consistente em toda tela que lê a MV. |
| **Cobrança preventiva** | Dias de atraso negativos são contraintuitivos. | Eixo/escala que mostre claramente o marco do vencimento (D-0). |
| **Disposição / motivo de exclusão** | A execução da campanha exclui candidatos por ~10 motivos diferentes. Hoje aparecem como termos técnicos. | Vocabulário humano + drill-down consistente. |
| **Bloqueio × exceção** | Exceção **neutraliza** sem apagar; o bloqueio volta quando a exceção vence. | Estado visual de três níveis: bloqueado / liberado temporariamente / livre. |
| **Trava do maior atraso** | Só o título de maior atraso do contato gera comunicação. O usuário vê "só uma mensagem" e não entende por quê. | Explicação contextual no funil e no drill-down. |
| **Lacuna de métrica de IA** | O sistema declara explicitamente quando **não sabe** um número (em vez de publicar zero). | Um padrão visual dedicado para "indisponível ≠ zero". |
| **Cauda sem cadência** | Passo de faixa aberta dispara todo dia se não tiver cadência. | Aviso forte no editor de régua. |
| **Operação irreversível** | Disparo, execução de campanha e exclusão de agente não se desfazem. | Padrão único de confirmação de alto risco. |

---

## 7. Mapa produto → tela

| Área do negócio | Tela(s) | Documento |
|---|---|---|
| Entrada e organização | Login, Cadastro, Convite, Selecionar Organização | 10 |
| Visão gerencial | Dashboard (5 abas) | 11 |
| Operação de envios | Ações, Relatório de Ações, Análise de Pagamento | 12 |
| Base de clientes | Gestão de Carteira (grid, kanban, detalhe, bloqueio) | 13 |
| Segmentação | Filtros e Portfólios | 14 |
| Automação (o quê e quando) | Campanhas, Editor de Broadcast | 15 |
| Automação (a sequência) | Réguas de Cobrança, Editor de Régua | 16 |
| Envio pontual e conteúdo | Disparos, Templates de Mensagem | 17 |
| Inteligência artificial | Galeria de Agentes, Workspace do Agente, Tags | 18 |
| Dados | Fonte de Dados (ETL) | 19 |
| Plataforma | Integrações, Configurações | 20 |
| Conhecimento | Central de Documentação, Docs da API, Docs da Fonte de Dados | 21 |
| Assistente e elementos globais | Painel Maestro, estados globais | 22 |
