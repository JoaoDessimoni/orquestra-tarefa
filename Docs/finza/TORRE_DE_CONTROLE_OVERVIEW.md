# Torre de Controle v2 — Visão de Negócio

> Documento de contexto para apresentação. Foco em **o que faz**, **para que serve** e **regras de negócio**. Não cobre implementação técnica.

---

## 1. O que é a Torre de Controle

A **Torre de Controle v2** é a plataforma SaaS multi-tenant de **cobrança digital** da Finza. Substitui processos manuais de cobrança (planilhas, dispador isolado, atendimento humano caso-a-caso) por uma operação **end-to-end automatizada**: dados da carteira entram, são segmentados, percorrem réguas de cobrança configuráveis, disparam mensagens multi-canal, recebem callbacks de pagamento e geram inteligência de negócio — tudo com agente de IA opcional fazendo análise e proposta de ações.

### Proposta de valor
- **Escala**: opera de 1.000 a 100.000+ contatos sem aumentar o time
- **Multi-canal nativo**: WhatsApp, SMS, Email, Voz, Webhook, Negativação, todos orquestrados pela mesma régua
- **Multi-tenant**: cada cliente (organização) tem dados isolados em schema próprio, com RBAC granular
- **Inteligência embarcada**: agente IA Maestro analisa, propõe e (com aprovação) executa ações estratégicas
- **Compliance**: auditoria completa, blocklists, janelas de horário/dia, throttling, datas bloqueadas (feriados)
- **Cobrança preventiva**: dispara D-7 e D-1 (antes do vencimento), não só pós-vencido

### Stack resumida (para contextualizar arquitetura, não para apresentar)
React 19 + Vite 7 + TypeScript 5.9 + Tailwind CSS 4 + shadcn/ui no frontend. Backend Supabase (PostgreSQL + 64 Edge Functions Deno + 14 cron jobs pg_cron). Compatível com Lovable.dev. Multi-tenant via schema por org (`org_{slug}`).

---

## 2. Objetivos Estratégicos do Produto

| # | Objetivo de negócio | Como a Torre entrega |
|---|---|---|
| 1 | **Maximizar recuperação de inadimplência** | Réguas de cobrança progressivas + dedup inteligente + atribuição de pagamentos |
| 2 | **Reduzir custo por contato** | Multi-canal escalonado (Email/SMS antes do WhatsApp; ligação só em casos críticos) + custos configuráveis por canal |
| 3 | **Manter o consumidor protegido** | Blocklist, cooldowns por canal, janelas de horário/dia, datas bloqueadas, tags de status (em negociação, ação judicial, não perturbe) |
| 4 | **Visibilidade total da operação** | Dashboard com 5 abas (Executive, Operational, Workflows, AI, Attribution), relatórios semanais automáticos por email |
| 5 | **Operação sem dependência de TI** | Filtros visuais AND/OR, editor de régua visual, templates com variáveis, integrações configuráveis pela UI |
| 6 | **Inteligência aplicada** | Maestro (agente IA) faz análise, gera propostas de ações, executa após aprovação humana |

---

## 3. Conceitos Centrais (vocabulário do domínio)

Esses termos aparecem em todo o produto. Apresentação deve usá-los corretamente.

| Termo | O que é |
|---|---|
| **Organização (Org)** | Cliente da Finza (tenant). Cada org tem dados completamente isolados (`schema org_{slug}`) |
| **Contato** | Pessoa física/jurídica devedora. Pode ter múltiplos contratos, telefones, emails, tags |
| **Contrato** | Operação de crédito/locação/venda. Pode ter múltiplos títulos |
| **Título** | Parcela/boleto individual com valor, vencimento, status. **É a unidade central de avaliação** |
| **Days Overdue** | Dias em atraso. **Aceita negativos** (D-7, D-1) para cobrança preventiva |
| **Carteira (Portfolio)** | Agrupamento dinâmico de contatos definido por filtro (não por coluna fixa) |
| **Filtro Dinâmico** | Regra visual AND/OR/NOT com múltiplas condições, salva e reutilizável |
| **Régua de Cobrança (Workflow)** | Sequência de passos por dias de atraso. Ex: D-1 Email, D+5 WhatsApp, D+15 SMS, D+30 Negativação |
| **Step (Passo da régua)** | Ação atômica: canal + template + integração + faixa de dias trigger |
| **Campanha** | Container de execução de uma ou mais réguas, com janela (horário + dias da semana), filtros e cronograma |
| **Ação (Action)** | Instância concreta: "enviar WhatsApp X ao contato Y no título Z no step W em DD/MM HH:MM". Tem status (12 estados) |
| **Integração** | Conector ao provedor de canal (Evolution API, Twilio, SendGrid, Hyperflow Meta, Vonage, Zenvia, webhook custom) |
| **Template de Mensagem** | Conteúdo reutilizável com variáveis `{{contact.name}}`, `{{title.due_date}}`, etc. |
| **Selo (Seal)** | Flag de negócio aplicada manualmente a contatos (ex: "resolvido", "baixa prioridade") |
| **Tag** | Anotação contextual de atendimento (em_negociacao, intencao_de_pagamento, acao_judicial, etc.) |
| **Aging Bucket** | Faixa de dias em atraso pré-definida (0-30, 31-60, 61-90, 91-120, 121+) |
| **Atribuição** | Vínculo automático entre pagamento e ação que o gerou (janela de 48h) |
| **Maestro** | Agente IA orquestrador. Tem sessões, propostas, modos plan/semi_auto/full_auto |

---

## 4. Os 7 Sistemas Principais

### 4.1. Sistema de Campanhas
**Objetivo de negócio:** automatizar disparo escalonado de cobrança respeitando o estágio de cada título.

**O que o usuário faz:**
- Cria campanhas agendadas (cron), manuais ou disparadas por evento (fim de ETL)
- Vincula uma ou mais réguas
- Define **janela de execução** (horário comercial + dias úteis)
- Aplica filtros globais (carteira, perfil)
- Configura limite por minuto (APM — actions per minute) para não estourar carrier
- Monitora execução em tempo real, pausa/retoma, executa "agora"

**Regras de negócio críticas:**
- **Title-Centric (a regra mais importante do produto)**: avalia **cada título individualmente** contra os steps da régua. João com 3 títulos (D+10, D+35, D+60) e steps em D+5~15 e D+30~45 recebe **um WhatsApp por título**, não um do contato — o sistema sabe qual título está em qual estágio
- **Dedup cross-campaign**: antes de criar uma ação, valida em uma única chamada: cooldown por canal (não contactar 2x em 24h), ação já existe para mesmo contact+step hoje, outra campanha já disparou no mesmo título, e prioriza título **mais vencido** se há concorrência
- **Dedup por escopo do canal**: WhatsApp/Email/SMS deduplicam **por contato** (1 msg por contato/canal). Negativação/Notificação deduplicam **por contrato** (cada contrato gera ação própria)
- **Cobrança preventiva**: suporta dias negativos. D-7 e D-1 são casos comuns
- **Blocklist**: documentos (CPF/CNPJ) bloqueados nunca recebem ações, mesmo se atendem aos filtros
- **Pausa global ou por canal**: emergência operacional sem perder histórico

**Triggers de execução:**
1. Cron agendado (verificação a cada minuto BRT)
2. Manual (clique "Executar Agora")
3. `on_pipeline_complete` (após ETL terminar, dispara campanhas vinculadas àquele pipeline — garante que cobrança roda sobre dados frescos)

### 4.2. Sistema ETL (Pipelines de Importação)
**Objetivo de negócio:** manter dados de títulos/contratos/contatos sempre frescos sem importação manual.

**O que o usuário faz:**
- Configura **Data Sources**: BigQuery, CSV, API genérica
- Cria **Pipeline**: mapeia campos da fonte (`source_title_id` → `title_number`, etc.), define agendamento (cron), normalização (lookup "SP" → "São Paulo")
- Executa pipeline manualmente ou monitora execução agendada
- Vê histórico de **Job Runs** (criados/atualizados/erros)
- Configura **Custom Fields** (campos personalizados específicos da carteira; aparecem automaticamente em filtros, colunas e variáveis de template)
- Configura **Payment Check URL** para validar pagamento antes do envio

**Regras de negócio críticas:**
- **Title number é obrigatório**: títulos sem número são ignorados (sem boleto/PIX vinculável)
- **Reconciliação automática**: ao fim do ETL, títulos que **sumiram** da fonte são marcados como **"Removido"** (não deletados). Se reaparecem depois, voltam ao status anterior
- **Owner pipeline**: cada título guarda qual pipeline o trouxe. Reconciliação só remove títulos do mesmo owner; títulos manuais nunca somem
- **Status pago inferido**: se `payment_date` está preenchido mas status veio "Disponível", o ETL corrige para "Pago" automaticamente
- **Resumer automático**: se um ETL trava (heartbeat sumiu por >10min), outro processo retoma de onde parou (idempotente)
- **Cobrança pós-ETL**: ao terminar com sucesso, dispara campanhas vinculadas — operação fica sincronizada

### 4.3. Sistema de Filtros Dinâmicos
**Objetivo de negócio:** permitir segmentação complexa visualmente, sem TI.

**O que o usuário faz:**
- Constrói condições AND/OR/NOT aninhadas (ex: `valor > 5k AND (dias_atraso > 30 OR sem_acao_7d)`)
- Combina campos de **3 tabelas** (contato + contrato + título) na mesma regra
- Filtra por aging bucket, custom fields, tags, status canônico, etc.
- Salva, nomeia, reusa em **carteiras, réguas, campanhas e dashboards**
- Vê preview em tempo real: # contatos, valor total, valor vencido (<1s para 11 filtros simultâneos)

**Regras de negócio críticas:**
- **Title-centric**: filtros retornam títulos que dão match, não agregados. Stats refletem só os títulos elegíveis, não a soma da pasta do contato
- **NOT semantics**: campo nulo em filtro negado fica fora (PostgreSQL NULL semantics)
- **Suporta cobrança preventiva**: nunca força `GREATEST(0, days_overdue)` — D-7 funciona em filtros
- **Carteira como filtro vivo**: portfolios não são listas estáticas. São filtros avaliados continuamente — entrou contato novo que dá match, já aparece na carteira

### 4.4. Sistema Maestro (Agente IA)
**Objetivo de negócio:** delegar análise estratégica e geração de campanhas a uma IA, com aprovação humana antes de qualquer execução.

**O que o usuário faz:**
- Conversa em chat com agente especializado em cobrança
- Pede análises ("qual carteira tem pior performance?"), estratégias ("monte uma régua para inadimplência longa"), criação de templates, otimizações
- Recebe **propostas** (criar campanha X, atualizar workflow Y) com payload visível antes de executar
- Aprova/rejeita propostas com auditoria completa
- Configura múltiplas **personas** (analista, estrategista, redator, otimizador)
- Escolhe **modo de operação**: `plan` (só sugere), `semi_auto` (executa com aprovação), `full_auto` (executa com guardrails — destrutivas ainda pedem confirmação)

**Regras de negócio críticas:**
- **Propostas como ciclo formal**: nenhuma ação de IA executa sem trilha auditável (proposta → status → executor → resultado)
- **Tokens rastreados** por sessão para billing/alertas
- **Tags como contexto**: agente lê `contact.tags` e custom_fields antes de propor estratégia (sabe que está "em_negociacao", não vai mandar cobrança agressiva)
- **Multi-provider**: chaves criptografadas para Anthropic, OpenAI, Google, Azure — cliente escolhe

### 4.5. Arquitetura Multi-Tenant
**Objetivo de negócio:** rodar múltiplos clientes (orgs) no mesmo sistema com **isolação total** e RBAC granular.

**Como funciona (do ponto de vista do usuário):**
- Usuário pode pertencer a **múltiplas organizações** (ex: consultoria com 5 clientes — vê todos no menu de troca)
- Cada org tem schema próprio no banco. Nada vaza entre orgs
- **5 papéis (roles)** hierárquicos:
  - **Owner**: tudo, inclusive deletar org
  - **Admin**: tudo exceto deletar org
  - **Manager**: cria/edita campanhas e réguas, opera carteiras
  - **Operator**: opera campanhas existentes, faz seleção, aplica selos
  - **Viewer**: só lê
- Convites por email com token; ao aceitar, usuário vira membro com role definido

**Regras de negócio críticas:**
- **RBAC frontend filtra UI**: viewer não vê botões de criar/deletar; sidebar filtra menus por permission
- **Backend valida via RLS**: cada query passa pelo cliente Supabase configurado com schema da org logada
- **Ações de teste isoladas**: `metadata.is_test=true` é excluído de KPIs/relatórios

### 4.6. Sistema de Tags de Contatos
**Objetivo de negócio:** anotar contexto de atendimento em tempo real para personalizar cobrança futura.

**Caso de uso típico:** João prometeu pagar na sexta. Agente IA (ou humano) aplica tag `intencao_de_pagamento`. Próxima régua respeita isso — pula o WhatsApp de D+10 porque há promessa registrada.

**Catálogo de tags sugerido:** `intencao_de_pagamento`, `em_negociacao`, `aguardando_boleto`, `acao_judicial`, `nao_perturbe`, `cliente_vip`, etc. — estendível pela org.

**Auditoria embutida:** `custom_fields.agent_tags[]` mantém histórico de adições e remoções com `reason` e timestamp.

### 4.7. Sistema de Métricas do Agente IA (Funil e Transbordo)
**Objetivo de negócio:** medir se o agente IA está retendo conversas (resolvendo no autoatendimento) ou empurrando tudo para humano.

**O que o gestor vê:**
- **Funil em cascata**: estágios configuráveis (Iniciado → Em Negociação → Promessa → Finalizado) com volume e taxa de avanço
- **Drop-off por estágio**: onde a IA perde conversas
- **Tabela de motivos de transbordo**: razão pela qual conversa virou humano (drill-down: motivo → lista de conversas → mensagens)
- **Evolução diária**, agregação por dia/semana/mês

---

## 5. Funcionalidades por Tela (Mapa do Produto)

Mapa funcional alinhado à navegação do produto. Útil para roteiro de demo.

| Página | O que entrega |
|---|---|
| **Dashboard** | Visão consolidada da operação. 5 abas: Executive (KPIs estratégicos), Operational (volume por canal, ações despachadas), Workflows (efetividade de réguas), AI (funil do agente), Attribution (qual ação gerou cada pagamento) |
| **Campanhas** | Lista, cria, edita, executa, duplica, ativa/pausa campanhas. Monitora progresso em tempo real |
| **Réguas de Cobrança** | Lista de workflows + Editor visual com timeline de steps. Versionamento (draft → published) com histórico e rollback |
| **Broadcast** | Editor de campanhas one-shot (sem timing/régua) — comunicados pontuais ou massivos |
| **Ações** | Monitor em tempo real de mensagens despachadas. Filtros por status, canal, data. Pausa global/canal. Análise de motivos de falha |
| **Relatório de Ações** | Analytics detalhado: por canal, por campanha, por workflow+step. Gráficos, taxa de conversão, valor recuperado. Export Excel |
| **Análise de Pagamentos** | Deep dive de correlação ação → pagamento (atribuição automática 48h) |
| **Contatos** | CRUD de devedores. Filtro por tags. Detalhe com histórico de ações e pagamentos |
| **Contratos** | CRUD de operações de crédito/locação/venda. Vínculo bidirecional com contatos |
| **Gestão de Carteira** (página de uso diário do time) | Grid tipo planilha com colunas customizáveis + Kanban por status. Selagem em massa, filtros avançados, blocklist, exportação. **A tela onde o operador passa o dia** |
| **Filtros** | Construtor visual de segmentações reutilizáveis. Stats em tempo real (# contatos, valor) |
| **ETL** | Data Sources (conectar fontes) + Pipelines (configurar importação) + Custom Fields + Portfolios. Histórico de execuções |
| **Integrações** | Conectores de canal (WhatsApp via Evolution, Twilio, SendGrid, Hyperflow Meta, Vonage, Zenvia, Webhook). Testar, ativar/desativar, monitorar saúde. **API Keys** da Torre para clientes |
| **Templates de Mensagem** | Biblioteca de mensagens com variáveis. Source: local ou sincronizado da Meta (WhatsApp Business). Ver onde cada template está em uso |
| **Agente IA** | Configurador do Maestro: versões (draft/published/archived), personalidade, guidelines, regras de negócio, prompt, funnel stages, playground, knowledge base (RAG), métricas |
| **Configurações** | Org, Users (RBAC), Standard Values, Tags, Selos, Variáveis globais, Custos por canal, Datas bloqueadas, Agenda de relatórios, Aging buckets |
| **Documentação** | Docs internas + API Reference: Contacts, Contracts, Titles, Campaigns, Portfolios, Actions, Search, Sync, Webhooks, Filters, Export, Analytics, AI/MCP |

---

## 6. Automações Background (sem intervenção do usuário)

A Torre tem **64 Edge Functions** orquestradas por **14 cron jobs** rodando 24/7. O usuário não precisa apertar nada para a operação acontecer.

### 6.1. Crons principais e cadência

| Cron | Frequência | O que faz (negócio) |
|---|---|---|
| **scheduled-action-processor** | 1 min | Processa ações agendadas respeitando janela, APM e status de pagamento |
| **campaign-scheduler** | 5 min | Detecta campanhas com cron pronto para rodar (em horário BRT) e dispara |
| **etl-scheduler** | 1 min | Verifica pipelines com cron pronto e cria job de importação |
| **etl-resumer** | 5 min | Retoma ETLs travados (>10 min sem heartbeat) |
| **process-webhook-retries** | 1 min | Refazer webhooks de callback que falharam (backoff 30s → 2min → 8min → 30min → 2h) |
| **broadcast-processor** | 5 min | Executa broadcasts agendados com filtros dinâmicos |
| **campaign-logs-cleanup** | 5 min | Limpa logs de campanha travados >30min e auto-retry |
| **batch_calculate_attribution** | 1h | Atribui pagamentos a ações da janela de 48h. KPIs financeiros precisos |
| **sync-meta-templates** | Diário 06:00 BRT | Sincroniza templates WhatsApp da Meta |
| **mcp-warmup (x3)** | 6 min, desfasados | Aquece servidor do agente IA (evita cold starts) |
| **health-check** | 5 min | Monitora saúde do sistema, alerta no Google Chat se crítico |
| **send-weekly-report** | 30 min | Verifica se é hora de enviar relatório semanal automático por email |
| **refresh MV titles** | 30 min | Recalcula materialized view (KPIs, dashboard, filtros) |

### 6.2. Fluxo end-to-end (cobrança automática)
```
ETL agendado → importa títulos novos/atualizados
  ↓ (on_pipeline_complete)
Campaign Scheduler verifica campanhas vinculadas
  ↓
Campaign Pipeline v2 (6 RPCs):
  resolve_contacts → fetch_titles → match_titles → apply_rules → cross_dedup → create_actions
  ↓
Scheduled Action Processor processa actions respeitando:
  - janela de horário (start_time/end_time)
  - dias ativos (segunda a sexta, por ex)
  - APM (rate limit por minuto)
  - blocklist
  - datas bloqueadas (feriados)
  - status atual de pagamento (não envia se já pago)
  ↓
Send-Message dispara via integração (WhatsApp/SMS/Email/Voz/Webhook)
  ↓
Provider envia → callback vem via webhook
  ↓
Webhook Receiver atualiza status (Enviado → Interagiu → Respondido)
  ↓
Batch Calculate Attribution (de hora em hora) liga pagamento à ação
  ↓
Dashboard atualizado automaticamente
```

---

## 7. Status Canônicos (vocabulário operacional)

### 7.1. Status de Título (BigQuery canonical)
`Disponivel`, `Pago`, `Cancelado`, `Removido`, `Em Atraso`, etc. **Sem legacy lowercase** (`pending`, `paid`, `removed` foram banidos).

`Removido` ≠ `Cancelado`:
- **Cancelado** = decisão de negócio (estornado, dívida perdoada)
- **Removido** = sumiu da fonte ETL (reconciliação automática)

### 7.2. Status de Ação (12 estados em português)
| Status | Significado |
|---|---|
| **Pendente** | Aguardando processamento |
| **Processando** | Em envio |
| **Enviado** | Despachado para o provider |
| **Interagiu** | Cliente viu/abriu/clicou (WhatsApp delivered/read) |
| **Respondido** (exibido na UI como "Solicitou Atendimento") | Cliente respondeu — escalou para humano |
| **Falhou** | Falha transiente (vai tentar de novo) |
| **Falha Permanente** | Falha que não vai resolver (email inválido) |
| **Em Atendimento** | Conversa ativa com agente |
| **Cancelado** | Cancelado manualmente |
| **Cancelado (Pago)** | Cancelado porque título foi pago antes do envio |
| **Cancelado (Removido)** | Cancelado porque título sumiu da carteira |
| **Duplicado** | Cancelado por dedup |

**Prioridade de status** (não pode regredir): Pendente(0) < Processando(1) < Enviado/Falhou(2) < Interagiu(3) < Respondido(4) < Em Atendimento(5) < Cancelado(10). Importante para race condition: se callback do n8n marcou "Em Atendimento", o post-send do send-message não pode sobrescrever para "Enviado".

---

## 8. Resiliência & Compliance (pontos de fala para credibilidade)

| Capacidade | Como é entregue |
|---|---|
| **Idempotência** | Pipeline de campanha pode ser re-executado sem duplicar ações (RPCs com state em DB) |
| **Distributed locking** | Múltiplos workers não processam a mesma ação simultaneamente |
| **Heartbeat + resumption** | ETLs e pipelines travados são detectados e retomados automaticamente |
| **Exponential backoff** | Webhooks falhados são retentados 5x com intervalos crescentes (30s → 2h) |
| **Dead Letter Queue** | Falhas permanentes ficam isoladas para análise, não bloqueiam fila |
| **Webhook retry queue** | Tabela `webhook_retry_queue` por org. Schemas incompletos não derrubam processamento dos demais |
| **Blocklist por documento** | CPF/CNPJ bloqueados nunca recebem ação, mesmo se filtros atenderem |
| **Janela de execução** | Horário comercial + dias úteis configuráveis por campanha |
| **Datas bloqueadas** | Feriados/datas especiais configuráveis a nível de org |
| **Auditoria** | Toda mudança de campanha/régua/proposta IA tem trilha (quem, quando, payload) |
| **Versionamento de réguas** | Draft → Published → Archived. Rollback disponível |
| **Versionamento do Agente IA** | Versões de personalidade/prompt podem ser publicadas/arquivadas |
| **Custos por canal** | Org define R$ por SMS/Email/WhatsApp para cálculo de ROI |

---

## 9. Integrações Suportadas

### Canais de saída
- **WhatsApp**: Evolution API, Hyperflow (Meta Business API), n8n customizado
- **Email**: Resend, SendGrid
- **SMS**: Twilio, Zenvia, Vonage
- **Voz**: Vonage
- **Webhook genérico**: para integrar com qualquer sistema do cliente (negativação, CRM, dialer)
- **Negativação**: webhook customizável para serviços de proteção ao crédito

### Fontes de dados (ETL)
- **BigQuery**: queries SQL com variáveis template
- **CSV**: upload pelo usuário, detecção automática de colunas
- **API genérica**: URL + autenticação

### IA
- **Anthropic Claude**, **OpenAI GPT**, **Google Gemini**, **Azure OpenAI** — cliente escolhe o provider, chaves criptografadas

### Outras
- **MCP Server**: agente externo (n8n por exemplo) chama ferramentas da Torre via protocolo MCP — get/add/remove de tags, busca de contato, etc.
- **Google Chat**: alertas de health check
- **Email outbound**: relatórios semanais automáticos via Resend

---

## 10. API REST Pública (para integrações dos clientes)

A Torre expõe API REST com autenticação via `x-api-key` + `x-org-slug` (gerável na UI de Integrações).

**Endpoints principais:**
- `/api/reguas` — CRUD de réguas
- `/api/portfolios` — gestão de carteiras
- `/api/actions` — listagem e PATCH (callbacks de status)
- `/api/campaigns` — gestão de campanhas
- `/api/etl` — disparar/monitorar pipelines
- `/api/integrations` — configurar conectores
- `/api/webhooks/communication` — receber callbacks dos providers
- `/api/sync` — sincronizar dados (contatos, contratos, títulos)
- `/api/analytics` — KPIs e atribuição
- `/api/search/titles` — busca rica de títulos (por CPF, número, contrato)
- `/api/ai/agent-context?contact_id={uuid}` — contexto completo do contato para agente IA externo

---

## 11. Sistema de Variáveis em Templates (diferencial)

Templates (WhatsApp, SMS, Email, Webhook, Prompt de IA) usam variáveis `{{X}}` que são resolvidas no momento do envio. Total: **86 variáveis estáticas + custom fields + variáveis org-level**.

**Categorias:**
- `contact.*` (21): nome, primeiro_nome, documento, telefone, email, tags, endereço, etc.
- `title.*` (11): número, valor original, valor atual, vencimento, dias_atraso, PIX, linha digitável
- `contract.*` (9+): número, modalidade, status, datas, dias safra, lista de contratos
- `portfolio.*` (3), `payment.*` (9), `financeiro consolidado` (10)
- `system.*` (3): data, hora, nome da org
- `var.*`: variáveis customizadas org-level (ex: `{{var.taxa_juros_mes}}`)
- `contract.custom.{key}` e `title.custom.{key}`: custom fields do ETL (aparecem automaticamente quando cadastrados)

**Auto-consolidação**: se um contato tem múltiplos títulos e o template usa `{{title.*}}`, o sistema **substitui automaticamente por lista consolidada** — uma única mensagem com todos os títulos do cliente.

---

## 12. Diferenciais para Apresentação (frases-chave)

Para slides ou pitch — afirmações que diferenciam a Torre de soluções concorrentes:

1. **"Cobrança title-centric, não contact-centric."** A Torre é a única plataforma que avalia título por título contra a régua, não o contato agregado. Resultado: cada título recebe a mensagem no estágio certo, sem cobrança duplicada ou inapropriada.

2. **"Cobrança preventiva nativa."** D-7 e D-1 são casos normais, não exceção. A maioria das plataformas só sabe lidar com pós-vencimento.

3. **"Dedup em 4 dimensões numa única chamada."** Cooldown por canal, ação duplicada por step, conflito cross-campaign e priorização de título mais vencido — tudo numa RPC só. Sem race condition.

4. **"Integração com IA, não substituição por IA."** Maestro propõe, humano aprova, sistema executa com auditoria. Não há ações de IA sem trilha de quem aprovou.

5. **"Reconciliação automática de carteira."** Título sumiu da fonte? Vira `Removido`. Voltou? Restaura status. Sem perda de histórico.

6. **"Multi-tenant real."** Cada cliente tem schema próprio no banco. Não é só RLS — é isolação física. Compliance LGPD nativo.

7. **"86 variáveis + custom fields automáticos."** Cadastrou campo no ETL? Já aparece em templates, filtros, colunas e prompts de IA. Sem deploy.

8. **"24/7 sem operador."** 14 cron jobs, 64 edge functions, idempotência, heartbeat, retry com backoff exponencial. Falhas transientes resolvem-se sozinhas; falhas permanentes ficam isoladas.

9. **"Atribuição automática de pagamento."** Cliente pagou? A Torre conecta o pagamento à ação que o causou (janela 48h), priorizando Respondido > Em Atendimento > Interagiu > Enviado. ROI por canal/régua/campanha vira número, não palpite.

10. **"Filtros visuais combinando 3 tabelas."** AND/OR/NOT aninhado, contato + contrato + título numa mesma regra. Operador monta segmentação sem chamar TI.

---

## 13. Casos de Uso (storytelling para apresentação)

### Caso 1 — Operação 24/7 sem time crescer
Cliente importava planilha manual toda segunda. Atrasava cobrança em 2-3 dias. Operadora dispara WhatsApp manualmente em 1.000 contatos/dia.
**Com Torre:** ETL importa de hora em hora → ao terminar, campanhas vinculadas rodam automaticamente. Operadora foca em casos escalados (status "Respondido"). Capacidade subiu de 1k para 50k contatos/dia, mesmo time.

### Caso 2 — Cobrança preventiva reduz inadimplência
Cliente só cobrava após vencimento. Inadimplência alta em parcela 1.
**Com Torre:** régua adiciona step D-3 (lembrete amistoso WhatsApp) e D-1 (SMS). Pagamentos antecipam, inadimplência cai.

### Caso 3 — Múltiplos clientes, isolação total
Consultoria gerencia carteiras de 5 clientes. Não pode misturar dados.
**Com Torre:** 5 orgs (schemas isolados). Mesma operadora muda de uma para outra no menu. RBAC por org (admin no cliente A, viewer no cliente B). LGPD coberto.

### Caso 4 — Time pequeno, decisão data-driven
Gestor não tem tempo de cruzar planilhas para decidir onde investir.
**Com Torre:** dashboard mostra que WhatsApp via Hyperflow converte 4x mais que SMS via Twilio na carteira "Locação D+30~60". Aba Attribution mostra valor recuperado por canal. Decisão de aumentar APM no canal vencedor sai em minutos.

### Caso 5 — IA propõe, gestor aprova
Maestro analisa a base e propõe: "Carteira X tem 1.200 títulos D+45 sem ação nos últimos 14 dias. Sugiro criar campanha Y com régua Z." Gestor revisa payload, aprova com 1 clique. Campanha está rodando 30 segundos depois, com auditoria completa.

---

## 14. O que **NÃO** está no escopo da Torre (sinceridade)

Para a apresentação não vender o que não existe:

- **Não é CRM completo**: foco é cobrança, não pré-venda/lead management
- **Não substitui ERP**: dados vêm de ERPs/sistemas do cliente via ETL
- **Não é discador automático**: integra com discadores (via webhook) mas não disca
- **Não faz análise de crédito/score**: usa dados que recebe; não pontua devedor
- **Negativação é via integração**: a Torre dispara o evento, mas não é bureau

---

## 15. Stack Resumida (slide de credibilidade técnica, se necessário)

- **Frontend**: React 19, TypeScript 5.9, Vite 7, Tailwind 4, shadcn/ui, TanStack Query 5, React Router 7
- **Backend**: PostgreSQL 15 + Supabase + 64 Edge Functions Deno
- **Multi-tenant**: schema-per-org com RLS
- **Auth**: Supabase Auth (email/OAuth Google) + RBAC custom (5 papéis)
- **Compatível com Lovable.dev** para iteração visual rápida
- **CI/CD**: GitHub Actions com gates (lint, typecheck, unit, build, E2E Playwright)
- **Observabilidade**: health checks, alertas Google Chat, relatório semanal automático
- **Custos rastreáveis**: cada canal tem custo configurável → ROI calculado por canal/campanha/régua

---

## Anexo — Glossário rápido para slides

- **APM**: Actions Per Minute (rate limit)
- **BRT**: Horário de Brasília (UTC-3)
- **MV**: Materialized View (KPIs pré-calculados, refresh 30 min)
- **MCP**: Model Context Protocol (agentes externos consomem tools da Torre)
- **RBAC**: Role-Based Access Control
- **RLS**: Row-Level Security (PostgreSQL)
- **RPC**: Remote Procedure Call (funções SQL chamadas direto pelo cliente Supabase)
- **DLQ**: Dead Letter Queue
- **Cron expression**: `* * * * *` (minuto, hora, dia, mês, dia da semana)
