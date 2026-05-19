# Esperanza — Agente IA de Cobrança da Torre de Controle

> Documento de contexto para apresentação. Cobre objetivo, arquitetura, funcionalidades, configuração e funcionamento operacional.

---

## 1. O que é a Esperanza

**Esperanza** é o nome dado ao **agente IA de cobrança** da Torre de Controle quando configurado em produção. Tecnicamente, ela é uma instância configurável do sistema de agente IA — o nome "Esperanza" é o valor do campo `agent_name` na tabela `ai_versions` (cada organização pode batizar o seu agente como quiser; "Esperanza" é o nome usado em produção para o cliente principal).

A Esperanza **atua via WhatsApp** (canal principal), conduzindo negociações de cobrança de ponta a ponta: identifica o cliente pelo telefone, consulta a dívida, oferece descontos e parcelamentos conforme regras da organização, registra promessas de pagamento, gera links de PIX/boleto e transfere para humano quando necessário.

### Posicionamento no produto
- **Não é um chatbot genérico**: tem acesso direto à base da Torre (contatos, contratos, títulos, campanhas) via protocolo MCP
- **Não é IA "caixa-preta"**: cada conversa fica logada com prompt compilado, tokens, latência, intenção detectada, sentimento
- **Não substitui o operador**: escala para humano por regra ou pedido do cliente; opera sob compliance estrito (CDC, LGPD)
- **É versionada**: cada mudança em personalidade/diretrizes/regras gera uma versão (draft → published → archived) com rollback

---

## 2. Objetivos da Esperanza

| Objetivo | Como entrega |
|---|---|
| **Aumentar contato útil** | Disponível 24/7 no WhatsApp; cliente responde no horário dele, não no horário do operador |
| **Reduzir custo por recuperação** | Resolve casos simples (promessa, desconto à vista, parcelamento padrão) sem operador humano |
| **Manter compliance** | CDC e LGPD embutidos como camada base imutável do system prompt; horários respeitados; nunca expõe dívida a terceiros |
| **Padronizar negociação** | Regras de desconto/parcelamento configuradas pela org — agente não improvisa fora dos limites |
| **Liberar humano para casos complexos** | Escala automaticamente em: dívida >180d, 3 tentativas sem acordo, pedido explícito do cliente, reclamação grave |
| **Gerar inteligência operacional** | Cada interação alimenta funil, métricas de retenção, motivos de transbordo, dashboards |

---

## 3. Arquitetura — Como a Esperanza Funciona

### 3.1. Visão de alto nível

```
Cliente (WhatsApp)
      ↓
Provider (Hyperflow/Evolution/n8n)
      ↓ (chama)
LLM (Claude Sonnet 4 — modelo padrão)
      ↓ (system prompt + tools)
MCP Server (27 ferramentas)
      ↓ (lê/escreve)
Torre de Controle (schema org_{slug})
      ↓ (webhook de eventos)
ai-conversation-webhook
      ↓ (registra)
ai_interaction_logs + ai_funnel_events
      ↓
Dashboard de Métricas IA
```

### 3.2. Os dois modos de invocação

A Esperanza pode ser chamada em **dois fluxos distintos**:

**Fluxo A — Atendimento ao Cliente (produção real):**
- Provedor externo (n8n, Hyperflow, fluxo customizado) recebe mensagem do WhatsApp
- Chama `ai-config` para obter `system_prompt` compilado
- Envia ao LLM com lista de tools do MCP
- LLM chama ferramentas (identificar contato, buscar dívida, gerar link de pagamento…)
- Resposta volta ao WhatsApp via provider
- Evento de funil/mensagem é enviado de volta para `ai-conversation-webhook` (registra no banco)

**Fluxo B — Maestro (orquestrador interno):**
- Operador conversa com a IA dentro da plataforma (não com cliente final)
- Maestro analisa dados, propõe ações (criar campanha, etc.), com aprovação humana
- Tem 3 modos: `plan` (só sugere), `semi_auto` (executa com aprovação), `full_auto` (executa com guardrails)
- Usa as mesmas tools MCP mas para tarefas operacionais

> A Esperanza no sentido "agente que conversa com devedor" corresponde ao **Fluxo A**. O Maestro é um agente IA distinto que serve ao operador.

### 3.3. Compilação do System Prompt em 5 Camadas

A cada chamada ao LLM, a Torre compila o prompt em camadas (função `compileSystemPrompt` em `ai-config/index.ts`):

```
┌─────────────────────────────────────────────────────────────┐
│ LAYER 1 — BASE COMPLIANCE (imutável)                       │
│ "Você é {agent_name} de cobrança.                          │
│  - Respeite o CDC                                          │
│  - Nunca ameace ou constranja                              │
│  - Respeite a LGPD                                         │
│  - Seja respeitoso e profissional                          │
│  - Nunca exponha a dívida a terceiros"                     │
├─────────────────────────────────────────────────────────────┤
│ LAYER 2 — TOM DE VOZ (config da org)                       │
│ professional | friendly | assertive                        │
├─────────────────────────────────────────────────────────────┤
│ LAYER 3 — DIRETRIZES (config da org, por categoria)        │
│ [TONE] [COMPLIANCE] [ESCALATION] [NEGOTIATION]             │
├─────────────────────────────────────────────────────────────┤
│ LAYER 4 — REGRAS DE NEGÓCIO (config da org)                │
│ "SE days_overdue > 180 ENTÃO escalate_human"               │
│ "SE payment_type === 'a_vista' ENTÃO offer_discount"       │
├─────────────────────────────────────────────────────────────┤
│ LAYER 5 — CENÁRIO ESPECÍFICO                                │
│ Prompt do cenário (initial_contact / negotiation / etc.)   │
└─────────────────────────────────────────────────────────────┘
```

Cada org **customiza Layers 2-5**, mas Layer 1 é fixo. Garante que mesmo com config malfeita o agente nunca extrapola compliance.

---

## 4. Configuração da Esperanza (UI: 10 abas)

A página **Agente de IA** (`/agent-ia`) tem 10 abas:

### 4.1. Versões
- Lista de versões (rascunho, publicada, arquivada)
- Criar nova versão a partir de zero ou clonando publicada
- Publicar rascunho em produção (vira a versão ativa que provedores chamam via `ai-config`)
- Arquivar versão antiga
- Histórico completo

### 4.2. Personalidade
Configura identidade do agente:
- **agent_name** (ex: "Esperanza")
- **agent_avatar_url** (foto opcional)
- **agent_tone**: `professional` | `friendly` | `assertive`

### 4.3. Diretrizes
Listas de regras textuais que entram no prompt em Layer 3. **4 categorias**:

| Categoria | Exemplo de diretriz |
|---|---|
| **tone** (Tom de Voz) | "Mantenha sempre um tom respeitoso e profissional, mesmo diante de clientes irritados" |
| **compliance** | "Nunca ameace o cliente com negativação. Respeite horários: dias úteis 8h-20h, sábados 8h-14h. Não divulgue a dívida para terceiros" |
| **escalation** | "Transfira para humano se cliente solicitar. Escale após 3 tentativas sem acordo" |
| **negotiation** | "Sempre comece oferecendo o valor total à vista com desconto máximo permitido" |

Cada diretriz tem `priority` (peso ao ser apresentada ao LLM) e `is_active`.

### 4.4. Regras de Negócio (Business Rules)
Regras **condicionais** estruturadas: `SE {condição} ENTÃO {ação} (config)`. **5 tipos de ação**:

| action_type | O que faz |
|---|---|
| `offer_discount` | Oferece desconto por % (configurável por tier de dias de atraso) |
| `suggest_payment_plan` | Sugere parcelamento (max parcelas, valor mínimo, juros) |
| `escalate_human` | Transfere para humano com motivo |
| `send_notification` | Notifica via webhook (equipe, gestor) |
| `update_status` | Atualiza status do contato/ação |

**Exemplos default** vindos de `default-config.ts`:
- **Desconto por Pagamento à Vista**: tiers progressivos (30d→5%, 60d→10%, 90d→15%, 180d→20%)
- **Parcelamento Padrão**: até 12x sem juros para dívidas ≥ R$ 500, parcela mínima R$ 50
- **Escalar Dívidas Antigas**: `days_overdue > 180` → escala para humano
- **Notificar Promessa de Pagamento**: `intent === 'payment_promise'` → notifica equipe via webhook

### 4.5. Prompts (por cenário)
Templates de prompt para Layer 5. **7 cenários**:

| Cenário | Quando aplicar |
|---|---|
| `general` | Instruções base com lista de tools — **sempre aplicada** |
| `initial_contact` | Primeira mensagem ao cliente |
| `negotiation` | Negociação ativa de acordo |
| `follow_up` | Acompanhamento de promessa anterior |
| `complaint` | Cliente apresenta reclamação |
| `payment_confirmation` | Confirmar pagamento recebido |
| `renegotiation` | Renegociar acordo quebrado |

Cada prompt tem:
- `prompt_template` (texto com variáveis `{{X}}`)
- `model_name` (default: `claude-sonnet-4-20250514`)
- `temperature` (default: 0.7; reclamação usa 0.6 — mais consistente)
- `max_tokens` (500-1500 conforme cenário)

**Variáveis disponíveis em templates de prompt (40+):**

- `agent_name` (nome do agente)
- Contato: `contact.name`, `contact.document`, `contact.phone`, `contact.email`, `contact.tags`
- Contrato: `contract.number`, `contract.modality`, `contract.status`, `contract.start_date`, `contract.end_date`
- Financeiro: `total_debt`, `days_overdue`, `oldest_due_date`, `titles_count`, `original_value`, `updated_value`
- Negociação: `max_discount`, `max_installments`, `min_installment_value`, `previous_agreements`, `negotiation_history`
- Sistema (auto-injetados): `guidelines`, `business_rules`
- Follow-up: `last_promise_date`, `last_promise_value`, `promise_status`, `last_contact_date`
- Reclamação: `complaint_text`, `complaint_category`
- Pagamento: `payment_value`, `payment_date`, `pix_link`, `boleto_link`, `boleto_barcode`
- Renegociação: `previous_agreement`, `renegotiation_reason`, `broken_agreement_date`
- **Custom fields**: `contact.custom.*`, `contract.custom.*`, `title.custom.*` (cadastrados via ETL)

### 4.6. Funil
Configura os estágios pelos quais a conversa progride. **8 estágios padrão**:

| stage_key | stage_name | Quando ocorre |
|---|---|---|
| `contact_initiated` | Contato Iniciado | Cliente respondeu/iniciou conversa |
| `payment_requested` | Solicitou Pagamento | Agente solicitou forma de pagamento |
| `payment_promise` | Promessa de Pagamento | Cliente prometeu pagar em data específica |
| `renegotiation_requested` | Pediu Renegociação | Cliente pediu renegociar valores |
| `agreement_reached` | Acordo Fechado | Acordo concluído, aguardando pagamento |
| `human_transfer` | Transferiu p/ Humano | Conversa transbordou para atendente |
| `payment_confirmed` | Pagamento Confirmado | Cliente confirmou ter pago |
| `conversation_ended` | Conversa Encerrada | Encerrada sem acordo |

Cada estágio pode ter:
- `notify_webhook` (boolean — chama webhook quando atingido)
- `auto_action` (`update_status` | `create_task` | `send_notification` | `trigger_workflow`)
- `auto_action_config` (params da ação)
- `icon` + `color` (visual no dashboard)
- `display_order` (ordem no funil)

### 4.7. Playground
Sandbox interno para testar o agente **antes de publicar**. Testa o **rascunho** (não a versão em produção). Permite simular conversa com entradas customizadas e ver respostas e tools chamadas.

### 4.8. Conversas (logs)
Histórico real de interações:
- Cliente, conversa, mensagens
- Prompt compilado (debug)
- Modelo usado, tokens input/output, latência
- Intenção detectada, sentimento, confiança
- Estágio do funil atingido
- Tags da conversa

### 4.9. Conhecimento (Knowledge Base / RAG)
Upload de documentos para RAG (Retrieval-Augmented Generation):
- Políticas de cobrança
- FAQ interno
- Procedimentos
- Scripts permitidos
- Documentos legais

Edge functions: `rag-ingest` (upload e indexação), `rag-query` (busca semântica), `rag-documents` (listagem), `rag-download`.

### 4.10. Métricas
Dashboard do agente:
- **Funil em cascata**: volume por estágio + taxa de avanço
- **Drop-off por estágio**: onde a IA perde conversas
- **Tabela de motivos de transbordo**: razão de cada transfer_to_human (drill-down por conversa → mensagens)
- **Evolução diária**, agregação por dia/semana/mês
- Conversation ID único: `{phone}-{YYYY-MM-DD}`

---

## 5. As 27 Ferramentas MCP (o que a Esperanza pode fazer)

O **MCP Server** (`supabase/functions/mcp-server/index.ts`) expõe 27 tools que o LLM chama durante a conversa. Cada tool aceita `org_slug` para isolar dados.

### 5.1. Identificação (2)
| Tool | O que faz |
|---|---|
| `identify_contact_by_phone` | Identifica contato pelo número WhatsApp. **Usado sempre no início da conversa** |
| `identify_contact_by_document` | Identifica por CPF/CNPJ se o cliente informa explicitamente |

### 5.2. Contexto e Consulta (3)
| Tool | O que faz |
|---|---|
| `get_full_context` | **Tool principal**. Retorna em uma chamada paralela: dados do contato, resumo financeiro (total devido, em atraso, dias atraso máximo, nível de risco), contratos, títulos em aberto (até 50), campanhas ativas, estágio atual do funil, promessas recentes, histórico de ações (30d default) |
| `get_titles_detail` | Lista detalhada de títulos/parcelas com valores, vencimentos, PIX, status |
| `get_action_history` | Histórico de comunicações realizadas com o contato |

### 5.3. Negociação e Pagamento (5)
| Tool | O que faz |
|---|---|
| `check_negotiation_options` | Verifica desconto máximo, parcelamento permitido, formas de pagamento |
| `generate_payment_link` | Gera link de pagamento (PIX ou Boleto). Retorna URL, código PIX copia-e-cola ou linha digitável. **Usa `GREATEST(current_value, original_value)`** para evitar bug de R$ 0,00 |
| `register_payment_promise` | Registra que cliente prometeu pagar valor X na data Y |
| `propose_installment_plan` *(documentado no prompt; pode estar implementado em outra rota)* | Propõe plano de parcelamento com simulação |
| `confirm_agreement` *(idem)* | Confirma acordo fechado |

### 5.4. Registro de Interação (3)
| Tool | O que faz |
|---|---|
| `log_interaction` | Registra mensagem do cliente, resposta do agente, intenção detectada, sentimento |
| `update_action_status` | Atualiza status de uma ação (enviado/entregue/lido/respondido/falhou) |
| `create_follow_up` | Agenda follow-up/retorno para data futura |

### 5.5. Funil (2)
| Tool | O que faz |
|---|---|
| `advance_funnel_stage` | Move o contato para próximo estágio do funil (com event_data: promised_value/date, agreement_value, etc.) |
| `get_funnel_status` | Consulta estágio atual e histórico de transições |

### 5.6. Utilitários (4)
| Tool | O que faz |
|---|---|
| `request_human_transfer` | Solicita transferência para humano com motivo (`transfer_reason`) |
| `check_blocklist` | Verifica se contato está bloqueado (não pode receber comunicação) |
| `get_ai_guidelines` | Obtém diretrizes e regras aplicáveis ao cenário atual (a IA pode reconsultar suas próprias regras) |
| `validate_cpf_cnpj` | Valida e formata CPF/CNPJ informado pelo cliente |

### 5.7. Consultas Operacionais (4)
| Tool | O que faz |
|---|---|
| `search_clients` | Busca clientes por nome/CPF/CNPJ |
| `get_financial_summary` | Resumo financeiro consolidado de um contato |
| `list_active_campaigns` | Lista campanhas ativas (contexto para o agente) |
| `get_collection_stats` | Estatísticas de cobrança (gerencial) |

### 5.8. Tags de Contato (3) — memória persistente entre conversas
| Tool | O que faz |
|---|---|
| `get_contact_tags` | Lê tags atuais do contato (ex: `intencao_de_pagamento`, `em_negociacao`, `acao_judicial`, `nao_perturbe`) |
| `add_contact_tag` | Aplica tag nova com `reason` e timestamp para auditoria |
| `remove_contact_tag` | Remove tag (ex: `aguardando_boleto` quando boleto é gerado) |

### 5.9. Tags de Conversa (3) — escopo da conversa atual
| Tool | O que faz |
|---|---|
| `get_conversation_tags` | Tags específicas desta conversa |
| `add_conversation_tag` | Adiciona tag à conversa |
| `remove_conversation_tag` | Remove tag da conversa |

### 5.10. Fluxo recomendado (do system prompt da Esperanza)
```
1. identify_contact_by_phone   → identifica pelo WhatsApp
2. check_blocklist             → confirma que pode prosseguir
3. get_full_context            → entende a situação completa
4. (negociação)                → check_negotiation_options, generate_payment_link, etc.
5. log_interaction + advance_funnel_stage → registra histórico e funil
6. request_human_transfer      → se não conseguir resolver
```

---

## 6. Webhook de Conversação (devolução de eventos)

O agente externo notifica a Torre via `POST /functions/v1/ai-conversation-webhook` para registrar o que aconteceu.

### Tipos de evento
- `message` — mensagem trocada (user ou assistant)
- `funnel_stage` — transição de estágio
- `conversation_ended` — conversa encerrada

### Payload típico
```json
{
  "event_type": "funnel_stage",
  "contact_document": "12345678900",
  "conversation_id": "5511999999999-2026-05-12",
  "agent_version": "1.0.0",
  "org_slug": "blips",
  "funnel_stage": {
    "stage_key": "payment_promise",
    "data": {
      "promised_value": 350.00,
      "promised_date": "2026-05-15",
      "notes": "Cliente vai pagar PIX"
    }
  },
  "analysis": {
    "intent": "payment_promise",
    "sentiment": "positive",
    "confidence": 0.92
  },
  "metadata": {
    "tags": ["intencao_de_pagamento"]
  }
}
```

### Autenticação
`x-api-key` (padrão) ou `x-webhook-secret` (legacy). Validados contra `api_keys` ou env var.

---

## 7. AI Assistant (ferramenta auxiliar, distinta da Esperanza)

Além da Esperanza (agente de atendimento ao cliente final) e do Maestro (orquestrador interno), existe a edge function `ai-assistant` — um **assistente para o operador editar conteúdo**, usando **Gemini Flash** (LLM rápido e barato).

### Ações suportadas
- `improve_message` — melhora uma mensagem de cobrança
- `improve_prompt` — melhora um prompt do agente
- `generate_variations` — gera variações de uma mensagem (A/B testing)
- `review_compliance` — revisa se uma mensagem viola CDC/LGPD

### Otimização por canal
Cada canal tem config própria de tom, formatação e best practices:

| Canal | maxLength | Tom |
|---|---|---|
| **whatsapp** | 4096 | Informal, próximo, emojis sutis |
| **sms** | 160 (obrigatório) | Ultra-conciso |
| **email** | 10000 | Profissional, estruturado |
| **voice** | 500 | Frases curtas, pausadas, números por extenso (TTS) |

---

## 8. Modelo de Dados — Tabelas do Agente IA

Todas no schema `org_{slug}` (multi-tenant):

| Tabela | Conteúdo |
|---|---|
| `ai_versions` | Versões de config (id, version, name, agent_name, agent_avatar_url, agent_tone, status, published_at) |
| `ai_guidelines` | Diretrizes (version_id, category, guideline_text, priority, is_active) |
| `ai_business_rules` | Regras (version_id, rule_name, condition_expression, action_type, action_config, priority) |
| `ai_prompts` | Templates de prompt (version_id, scenario, prompt_template, variables, model_name, temperature, max_tokens) — UNIQUE(version_id, scenario) |
| `ai_funnel_stages` | Estágios configurados (stage_key, stage_name, notify_webhook, auto_action, color, icon, display_order) |
| `ai_funnel_events` | Eventos recebidos (contact_id, stage_id, event_data, received_at) |
| `ai_interaction_logs` (= `action_interaction_logs`) | Logs completos (user_message, ai_response, compiled_prompt, tokens, latência, intent, sentiment, confidence, funnel_stage_id, transferred_to_human, transfer_reason) |
| `agent_llm_configs` | Configs de LLM (provider, model_id, api_key_encrypted, temperature, max_tokens, is_default) — usada pelo Maestro |
| `agent_sessions` | Sessões do Maestro (modo, persona, status, tokens, propostas aprovadas/rejeitadas) |
| `agent_messages` | Mensagens do Maestro (role, content, tool_call, tool_result, tokens, latência) |
| `agent_proposals` | Propostas geradas pelo Maestro (payload, status, created_at, executed_at) |

---

## 9. Modelo, Provider e Custo

### Modelo padrão
- **Anthropic Claude Sonnet 4** (`claude-sonnet-4-20250514`) — modelo principal para a Esperanza
- Temperature padrão: 0.7 (criativo o suficiente para personalizar, consistente o suficiente para não improvisar fora das regras)
- Max tokens: 500-1500 por resposta (varia por cenário)

### Multi-provider
O sistema suporta múltiplos providers via `agent_llm_configs`. Configurações por org:
- **Anthropic** (default — Claude)
- **OpenAI** (GPT)
- **Google** (Gemini — usado pelo AI Assistant interno)
- **Azure OpenAI**

API keys são armazenadas criptografadas (`api_key_encrypted`). Suporta também referência por env var (`env:NOME_DA_VAR`).

### Rastreamento de tokens
Cada interação registra `tokens_input` + `tokens_output` em `ai_interaction_logs`. Permite:
- Billing por org/sessão
- Alertas de overage
- Otimização (cenários que gastam mais → ajustar prompt)

---

## 10. Regras de Compliance Embutidas (Layer 1 — imutável)

A Esperanza **nunca** pode operar sem essas regras. Não é configuração da org — é código:

1. **CDC (Código de Defesa do Consumidor)**: respeito a todos os artigos relativos a cobrança (art. 42 e ss.)
2. **LGPD**: nunca expor dados a terceiros, nunca compartilhar informações sem confirmar titularidade
3. **Sem ameaças/constrangimentos**: não pode mencionar negativação, protesto ou ações judiciais de forma intimidadora
4. **Horários de cobrança**: dias úteis 8h-20h, sábados 8h-14h (default — pode ser sobrescrito por diretriz da org desde que dentro da lei)
5. **Confirmação de titularidade**: antes de mencionar valores ou dívida, agente precisa confirmar que está falando com o titular
6. **Tom respeitoso e profissional**: mesmo com cliente irritado ou agressivo

---

## 11. Fluxo End-to-End de uma Conversa Típica

```
1. Cliente envia "Oi" pelo WhatsApp
   ↓
2. Provider (n8n/Hyperflow) recebe webhook
   ↓
3. Provider chama ai-config?org_slug=blips&scenario=initial_contact
   → Recebe system_prompt compilado (5 camadas) + tools + model_config
   ↓
4. Provider chama Claude Sonnet 4 com system_prompt + mensagem do cliente
   ↓
5. Claude chama identify_contact_by_phone (tool MCP)
   → "Olá João, sou a Esperanza, assistente de cobrança da [empresa]..."
   ↓
6. Claude chama check_blocklist → ok
   ↓
7. Claude chama get_full_context → recebe dívida total, 3 títulos atrasados, dias atraso máximo 35
   ↓
8. Esperanza propõe: "João, identifiquei R$ 1.200 em aberto. Posso te oferecer pagamento à vista com 10% de desconto (você economiza R$ 120). Quer que eu gere o PIX agora?"
   ↓
9. Cliente: "Pode ser, mas só consigo na sexta"
   ↓
10. Claude detecta intent=payment_promise, chama:
    - register_payment_promise(value=1080, date=2026-05-16)
    - add_contact_tag(tag="intencao_de_pagamento", reason="prometeu pagar na sexta com desconto")
    - advance_funnel_stage(stage="payment_promise", data={promised_value:1080, promised_date:"2026-05-16"})
   ↓
11. Provider envia evento para ai-conversation-webhook
    → ai_interaction_logs registra mensagem
    → ai_funnel_events registra estágio
    → contact.tags atualiza com nova tag
    ↓
12. Esperanza responde: "Combinado, João! Anotei aqui. Na sexta-feira (16/05) eu te envio o PIX com o valor R$ 1.080 já com o desconto. Bom dia!"
   ↓
13. Campaign Pipeline detecta tag intencao_de_pagamento → ignora steps de cobrança agressiva até 16/05
   ↓
14. Cron de follow-up agendado para 16/05 → se não pagar, Esperanza retoma com cenário follow_up
```

---

## 12. Diferenciais da Esperanza (para apresentação)

1. **"Não é um chatbot, é um agente"**: ela não segue scripts lineares. O LLM decide qual tool chamar com base no contexto. Cliente atípico recebe resposta atípica, dentro dos guardrails.

2. **"Compliance no prompt, não no comentário"**: CDC e LGPD são Layer 1 imutável, não bullet point que a org pode tirar.

3. **"Versionada como código"**: cada mudança vira nova versão. Pode reverter para versão anterior em 1 clique. Playground testa rascunho antes de publicar.

4. **"5 camadas compiladas em runtime"**: cada chamada ao LLM monta dinamicamente compliance + tom + diretrizes + regras + cenário. Mudança em uma diretriz reflete na próxima conversa, sem deploy.

5. **"27 ferramentas com dados reais da Torre"**: não é IA "tradutora" que precisa de RAG para tudo — tem acesso direto à base via MCP. Resposta é sobre o cliente real, não palpite.

6. **"Memória entre conversas via tags"**: cliente prometeu pagar, fica registrado. Próxima cobrança respeita. Resolve o "agente esquecer o que combinou".

7. **"7 cenários distintos com prompts próprios"**: primeiro contato, negociação, follow-up, reclamação, confirmação de pagamento, renegociação. Não é o mesmo prompt para todos os casos.

8. **"Funil mensurável"**: 8 estágios padrão + customização. Dashboard mostra exatamente onde o agente está perdendo conversas. Data-driven.

9. **"Knowledge base própria"**: cliente pode subir suas políticas internas via RAG (`rag-ingest`). Esperanza responde com base nas regras específicas da empresa, não regras genéricas.

10. **"Auditoria total"**: prompt compilado, tokens, latência, intent, sentiment, transfer_reason — tudo logado. Disputa com cliente? Tem registro completo.

---

## 13. Limitações e Pontos de Atenção (sinceridade)

- **Canal principal é WhatsApp**: SMS/Email têm suporte mas a Esperanza foi otimizada para conversação síncrona
- **Dependente do provider externo**: a Torre fornece o cérebro (config + tools), mas quem roda o LLM e conversa no WhatsApp é o provider (n8n/Hyperflow). Não é Torre-end-to-end como o resto da plataforma
- **LLM custa**: cada conversa consome tokens. Modelo padrão (Claude Sonnet 4) é o mais caro entre Anthropic. Pode-se trocar para Haiku 4.5 para casos simples (config por org)
- **Não substitui operador em casos complexos**: regra "escalar após 3 tentativas sem acordo" é default — em prática, muitos casos vão para humano. A Esperanza filtra o trivial, não resolve tudo
- **Compliance depende da config**: Layer 1 é imutável, mas se a org criar diretrizes mal escritas (ex: "seja mais agressivo"), pode haver tensão. Revisão humana antes de publicar é recomendada

---

## 14. Resumo Executivo

**Esperanza** é o agente de IA da Torre de Controle que conversa com devedores no WhatsApp 24/7. Ela:

- **Conhece o cliente**: 27 ferramentas MCP dão acesso direto a contatos, contratos, títulos, histórico
- **Negocia dentro de regras**: descontos por tier, parcelamento, follow-up — configurados pela org
- **Respeita compliance**: CDC e LGPD embutidos como camada imutável do prompt
- **Tem memória**: tags de contato persistem entre conversas
- **É mensurável**: 8 estágios de funil + dashboard de drop-off + motivos de transbordo
- **É versionada**: draft → published → archived, com playground para testar antes
- **É customizável por org**: nome, tom, diretrizes, regras, prompts, estágios — sem deploy
- **Tem RAG opcional**: org sobe políticas via knowledge base
- **Suporta múltiplos LLMs**: Claude (default), GPT, Gemini, Azure

Tecnicamente, é a combinação de: tabelas de config em PostgreSQL multi-tenant + edge functions Deno (ai-config, ai-conversation-webhook, ai-orchestrator) + MCP server com 27 tools + provider externo (n8n/Hyperflow) que orquestra a chamada ao LLM.

Operacionalmente, é a interface que transforma cobrança de "tarefa de operador humano" em "sistema que conversa, decide e registra automaticamente, escalando ao humano só quando necessário".
