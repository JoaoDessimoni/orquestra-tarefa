# 12 · Telas de Ações

> Documento de inventário funcional do frontend **atual** da Torre de Controle (Finza) para o domínio **Ações**.
> Destino: redesenho da interface **sem perda de funcionalidade**.
> Base: leitura do código em `cobranca-finza/src/` (data da leitura: 2026-09-17). Nada aqui é suposição de produto; onde o código não é conclusivo, há marcação `⚠️ A confirmar:`.

---

## 0. Resumo do domínio

### 0.1 Telas e rotas

| Tela | Rota | Arquivo-fonte | Guard de rota | Permissão efetiva |
|---|---|---|---|---|
| Histórico de Ações | `/actions` | `src/pages/ActionsPage.tsx` | Nenhum `RequirePermission` na rota (`src/App.tsx:415`) | Entrada pelo menu exige `actions:read` (`src/components/layout/Sidebar.tsx:41`). Dentro da tela: `actions:write` libera Pausar/Cancelar; `reports:export` libera Exportar |
| Relatório de Ações com IA | `/actions/report` | `src/pages/ActionsReportPage.tsx` | Nenhum (`src/App.tsx:416`) | Sem checagem de permissão no componente. Acessível a qualquer usuário autenticado com org selecionada |
| Análise: Ações × Pagamentos | `/actions/payment-analysis` | `src/pages/ActionPaymentAnalysis.tsx` | Nenhum (`src/App.tsx:417`) | Sem checagem de permissão e **sem link na navegação** — só acessível por URL direta |

### 0.2 Permissões usadas no domínio (RBAC frontend-only)

Fonte: `src/contexts/OrganizationContext.tsx` (`ROLE_PERMISSIONS`).

| Permissão | owner | admin | manager | operator | viewer | Onde é usada |
|---|:--:|:--:|:--:|:--:|:--:|---|
| `actions:read` | ✓ (`*`) | ✓ | ✓ | ✓ | ✓ | Item "Ações" no menu lateral |
| `actions:write` | ✓ | ✓ | ✓ | ✓ | — | Botão "Pausar Envios" no cabeçalho de `/actions` |
| `reports:export` | ✓ | ✓ | — | — | — | Botão "Exportar" no cabeçalho de `/actions` |
| `actions:override_blocklist` | ✓ | — | — | — | — | Não usado nestas 3 telas |

> Observação: `owner` tem `["*"]` (todas). O cancelamento de ação **por linha** e **no modal** NÃO checa permissão no código lido — ver §12, item D-06.

### 0.3 Componentes do domínio

| Componente | Arquivo | Papel |
|---|---|---|
| `ActionsFiltersBar` | `src/components/actions/ActionsFiltersBar.tsx` | Barra única de filtros da página |
| `SendingProgressCard` | `src/components/actions/SendingProgressCard.tsx` | Cartão "Status de Envio" |
| `ActionKPICards` | `src/components/actions/ActionKPICards.tsx` | Os 4 KPIs |
| `StatsCard` | `src/components/actions/StatsCard.tsx` | Átomo de cartão de KPI (com popover de detalhe) |
| `ActionsTable` | `src/components/actions/ActionsTable.tsx` | Tabela + paginação + cancelamento inline |
| `ActionDetailDialog` / `ActionDetailContent` | `src/components/actions/ActionDetailDialog.tsx` | Modal de detalhe da ação |
| `FailureReasonsDialog` | `src/components/actions/FailureReasonsDialog.tsx` | Modal "Motivos de Falha" |
| `PauseSendingModal` | `src/components/actions/PauseSendingModal.tsx` | Modal "Controle de Envios" |
| `ActionsExportButton` | `src/components/actions/ActionsExportButton.tsx` | Botão Exportar + gatilho do diálogo |
| `ReportExportDialog` | `src/components/reports/ReportExportDialog.tsx` | Diálogo genérico de exportação (formato + privacidade) |
| `ActionStatusBreakdown` | `src/components/dashboard/charts/ErrorSummaryCard.tsx` | Conteúdo do popover de detalhe dos KPIs |

### 0.4 Hooks de dados que impactam a UI

| Hook | Arquivo | O que alimenta |
|---|---|---|
| `useActions` | `src/hooks/useActions.ts:312` | Lista da tabela + `total` + flag `identity` |
| `useFilteredActionStats` | `src/hooks/useActions.ts:802` | Os 4 KPIs + `statusBreakdown` dos popovers |
| `useActionsRealtime` | `src/hooks/useActions.ts:214` | Atualização automática (debounce 5 s) |
| `useActionsRefresh` | `src/hooks/useActions.ts:299` | Botão Atualizar (invalida lista + KPIs + progresso) |
| `useScheduledProgress` | `src/hooks/useScheduledProgress.ts` | Cartão de Progresso de Envio |
| `useActionFailureReasons` | `src/hooks/useActionFailureReasons.ts` | Modal de Motivos de Falha |
| `useSendingControls` | `src/hooks/useSendingControls.ts` | Estado de pausa + modal de Controle de Envios |
| `useIsBlockedToday` | `src/hooks/useIsBlockedToday.ts` | Selo "Pausado (feriado)" |
| `useStandardValues("action_status")` | `src/hooks/useStandardValues.ts` | Opções do filtro Status + cores/labels do badge |
| `useCancelAction` | `src/hooks/useManualAction.ts:249` | Cancelamento de ação |
| `useActionsExport` | `src/hooks/useActionsExport.ts` | Exportação HTML/PDF |
| `useActionsReport` / `useInvalidateActionsReport` | `src/hooks/useActionsReport.ts` | Relatório com IA |
| `useDebouncedValue` | `src/hooks/useDebouncedValue.ts` | Debounce de 300 ms na busca e no campo D+ |

---

## 1. Modelo mental: o que é uma "ação"

### 1.1 Definição

Uma **ação** é a unidade atômica de cobrança executada pela Torre: um WhatsApp, um e-mail, um SMS, um RCS, uma ligação de voz, um webhook, uma notificação extrajudicial ou uma negativação disparada para um contato. Ela nasce de uma campanha (pipeline v2, passo `create_actions`), de um disparo manual, de um teste de integração ou da API externa; é processada por um worker; e termina em um dos status terminais.

Guia de negócio interno do app: `src/pages/central-docs/negocio/data/acoes.ts` — "Pense nesta tela como a 'esteira de saída' da cobrança. As campanhas e réguas decidem QUEM cobrar e QUANDO; esta tela mostra o que efetivamente entrou na esteira".

### 1.2 Campos da entidade (interface `Action`)

Fonte: `src/hooks/useActions.ts:58-118`.

| Campo | Tipo | Uso na UI das 3 telas |
|---|---|---|
| `id` | `string` | Chave da linha; alvo do cancelamento; seleção do modal de detalhe |
| `workflow_execution_id` | `string \| null` | Não exibido diretamente |
| `contact_id` | `string` | Deep-link "Abrir na Gestão de Carteira" (`/portfolio?contact=…`) |
| `contract_id` | `string \| null` | Complementa o deep-link (`&contract=…`) |
| `action_type` | `ActionType` | Coluna "Tipo" (ícone + rótulo + cor) |
| `status` | `string` (canônico PT) | Coluna "Status" (badge) e todo o agrupamento de métricas |
| `message_content` | `string \| null` | Fallback do bloco "Conteúdo da Mensagem" no modal |
| `content` | `string \| null` | Bloco "Conteúdo da Mensagem" no modal |
| `recipient` | `string \| null` | Sublinha da coluna "Contato"; campo "Destinatário" no modal |
| `external_id` | `string \| null` | Bloco "ID Externo" no modal (+ link externo se a integração tiver `config.externalActionUrl`) |
| `channel` | `string \| null` | Não exibido diretamente nestas telas |
| `subject` | `string \| null` | Não exibido nestas telas |
| `campaign_id` | `string \| null` | Filtro por campanha |
| `integration_id` | `string \| null` | Bloco "Integração" no modal (via embed `integration`) |
| `source` | `string?` | Coluna "Origem" → badge Manual / Teste / API / Campanha |
| `source_detail` | `object \| null` | Modal: em ações manuais, mostra `"por " + user_id.slice(0,8) + "..."` |
| `metadata` | `object \| null` | `metadata.days_overdue` → coluna "D+"; `metadata.is_test` → exclusão de testes |
| `request_payload` | `object \| null` | Modal → Detalhes Técnicos → "Request Payload" |
| `response` | `object \| null` | Modal → Detalhes Técnicos → "Resposta da API" |
| `error_message` | `string \| null` | Linha vermelha sob o status na tabela; bloco "Motivo registrado" no modal; agrupamento do modal de Falhas |
| `sent_at` | `string \| null` | Histórico de status ("Enviado"); primeira/última hora no cartão de progresso |
| `delivered_at` | `string \| null` | Histórico de status ("Interagiu") |
| `read_at` | `string \| null` | Histórico de status ("Lido (read_at)") |
| `processing_started_at` | `string \| null` | Coluna "Processado em"; histórico de status ("Processado") |
| `created_at` | `string` | Coluna "Criado em"; histórico de status ("Criado") |
| `updated_at` | `string` | Não exibido nestas telas |
| `contact` (embed) | `{id,name,document}` | Coluna "Contato"; bloco Contato do modal |
| `campaign` (embed) | `{id,name}` | Coluna "Campanha / Régua" (linha 1) |
| `workflow_step` (embed) | `{id,name,config,workflow:{id,name}}` | Coluna "Campanha / Régua" (linha 2 = nome da régua); modal: Régua + Step |
| `integration` (embed) | `{id,name,config}` | Modal: Integração + URL externa |
| `workflow_execution` (embed) | `{id,workflow,campaign}` | Declarado no tipo; não usado no render destas telas |

> **Defensividade obrigatória**: os embeds podem vir como array (JOIN do PostgREST). O código faz `Array.isArray(...) ? [0] : ...` em `ActionsTable.tsx:105-108` e `ActionDetailDialog.tsx:41-42`. Qualquer refatoração precisa manter isso.

### 1.3 Ciclo de vida (visão do usuário)

Fonte: `src/pages/central-docs/topics/data/acoes-status.ts` (tópico "Ações — ciclo de vida, status e fila").

```
campanha cria           → Pendente (prioridade 0)
claim do lote           → Processando (prioridade 1, lock por worker)
envio ok                → Enviado (prioridade 2)
callback do provedor    → Interagiu (3) → Respondido (4) → Em Atendimento (5)
falha recuperável       → Falhou (2) → retry com backoff 1/2/4/8/16 min → volta a Pendente
esgotou max_retries (3) → Falha Permanente (terminal) + snapshot na DLQ
regra/blocklist/manual  → Cancelado / Cancelado (Pago) / Cancelado (Removido) / Duplicado (prioridade 10)
```

Regras que o desenho precisa respeitar (não são de UI, mas condicionam a leitura da tela):
- **STATUS_PRIORITY**: `Pendente 0 < Processando 1 < Enviado/Falhou 2 < Interagiu 3 < Respondido 4 < Em Atendimento 5 < Cancelado/Duplicado 10`. Um evento nunca rebaixa um estado mais avançado.
- **E-mail nunca recebe "Interagiu" via webhook** (Resend não tem webhook de `delivered`). Só WhatsApp gera `Interagiu`.
- **Cancelar uma ação em "Processando" é arriscado**: o POST ao provedor pode já ter saído e o Cancelado (prioridade 10) vence o Enviado — o histórico passa a mentir. A UI **permite** esse cancelamento (ver §12, D-07).

### 1.4 Canais e tipos

Um mesmo canal existe em duas grafias em `actions.action_type`: a forma **legada/manual** (`whatsapp`, `email`, `sms`, `rcs`, `voice`) e a forma de **campanha** (`send_whatsapp`, `send_email`, `send_sms`, `send_rcs`, `send_voice`). Os tipos `webhook`, `notification` e `negativation` existem em grafia única.

Consequência de UI já implementada: o filtro "Tipo" mostra só a forma de negócio e a consulta expande para `[tipo, "send_" + tipo]` (`useActions.ts:377`, `useFilteredActionStats` em `useActions.ts:845`, `useScheduledProgress.ts:127`).

---

## 2. Catálogo de status (o ponto crítico)

### 2.1 Tabela completa: valor canônico × rótulo exibido × cor × ícone × grupo

Fontes cruzadas:
- Valores canônicos: `src/lib/constants/action-status-config.ts` (`ACTION_STATUSES`).
- Rótulos de exibição: `supabase/functions/_shared/action-status-labels.ts` (`ACTION_STATUS_LABELS`), consumidos por `src/lib/constants/action-status-display.ts`.
- Cores de badge (Tailwind): `src/hooks/useActions.ts:169-182` (`ACTION_STATUS`).
- Cores hex do relatório: `src/hooks/useActionsReport.ts:243-259` (`getStatusColor`).
- Cor/rótulo de categoria do popover de KPI: `src/components/dashboard/charts/ErrorSummaryCard.tsx:22-33` (`STATUS_CATEGORY`).
- Ícone: `standard_values.metadata.icon` (semente em `src/hooks/useStandardValues.ts:79-91`) — **não é renderizado nas telas de Ações**; os badges de status são só texto.
- Grupos (helper sets): `action-status-config.ts:26-79`.

| # | Valor canônico (`actions.status`) | Rótulo exibido (UI) | Rótulo curto | Cor do badge (Tailwind) | Cor hex (relatório) | Categoria do popover de KPI (cor/label) | Ícone semeado em `standard_values` | Grupos (helper sets) |
|---|---|---|---|---|---|---|---|---|
| 1 | `Pendente` | **Pendente** | — | `bg-yellow-100 text-yellow-800` | `#6b7280` | — (cai em `DEFAULT_CATEGORY` `#94a3b8` "Outro") | `Clock` | `PENDING_STATUSES` |
| 2 | `Processando` | **Processando** | — | `bg-blue-100 text-blue-800` | `#3b82f6` | — (`Outro`) | `Loader2` | `PENDING_STATUSES` |
| 3 | `Enviado` | **Enviado** | — | `bg-cyan-100 text-cyan-800` | `#3b82f6` | `#3b82f6` / "Enviado" | `Send` | `SENT_STATUSES`, `TERMINAL_STATUSES` |
| 4 | `Interagiu` | **Interagiu** | — | `bg-cyan-100 text-cyan-800` | `#06b6d4` | `#06b6d4` / "Interagiu" | *(não semeado — ver §2.5)* | `SENT_STATUSES`, `INTERACTION_STATUSES` (= `DELIVERED_STATUSES`), `TERMINAL_STATUSES` |
| 5 | `Respondido` | **Solicitou Atendimento** ⚠️ | — | `bg-purple-100 text-purple-800` | `#8b5cf6` | `#22c55e` / "Sucesso" | `MessageCircle` | `SENT_STATUSES`, `INTERACTION_STATUSES`, `RESPONSE_STATUSES`, `TERMINAL_STATUSES` |
| 6 | `Falhou` | **Falha Temporária de Ação** ⚠️ | Falha Temporária | `bg-red-100 text-red-800` | `#ef4444` | `#ef4444` / "Falha" | `XCircle` | `FAILURE_STATUSES`, `TERMINAL_STATUSES` |
| 7 | `Falha Permanente` | **Falha Definitiva de Ação** ⚠️ | Falha Definitiva | `bg-red-200 text-red-900` | `#991b1b` | `#ef4444` / "Falha" | `AlertTriangle` | `FAILURE_STATUSES`, `TERMINAL_STATUSES` |
| 8 | `Em Atendimento` | **Em Atendimento** | — | `bg-teal-100 text-teal-800` | `#9ca3af` | `#8b5cf6` / "Em atendimento" | `Headphones` | `CANCELLED_STATUSES`, `TERMINAL_STATUSES` — **mas conta como enviado nos KPIs** (§4.5) |
| 9 | `Cancelado` | **Cancelado** | — | `bg-orange-100 text-orange-800` | `#f59e0b` | `#f59e0b` / "Cancelado" | `XCircle` | `CANCELLED_STATUSES`, `TERMINAL_STATUSES` |
| 10 | `Cancelado (Pago)` | **Cancelado (Pago)** | — | `bg-green-100 text-green-800` | `#f59e0b` | `#f59e0b` / "Cancelado" | `DollarSign` | `CANCELLED_STATUSES`, `TERMINAL_STATUSES` |
| 11 | `Cancelado (Removido)` | **Cancelado (Removido)** | — | `bg-orange-100 text-orange-800` | `#f97316` | `#f59e0b` / "Cancelado" | `Trash2` | `CANCELLED_STATUSES`, `TERMINAL_STATUSES` |
| 12 | `Duplicado` | **Duplicado** | — | `bg-slate-100 text-slate-800` | `#64748b` | `#64748b` / "Cancelado" | *(não semeado)* | `CANCELLED_STATUSES`, `TERMINAL_STATUSES` |

⚠️ = **rótulo exibido ≠ valor canônico**. São exatamente três casos (IAF-4700 + o precedente antigo de `Respondido`). O valor gravado no banco, os webhooks, os aliases e as métricas continuam usando o valor canônico.

### 2.2 Agrupamentos (helper sets) — definição literal

| Conjunto | Membros | Onde é consumido na UI |
|---|---|---|
| `SENT_STATUSES` | Enviado, Interagiu, Respondido | Popover do KPI "Taxa de Envio"; bucket `sent` do cartão de progresso |
| `INTERACTION_STATUSES` (alias depreciado: `DELIVERED_STATUSES`) | Interagiu, Respondido | Popover do KPI "Taxa de Interação" |
| `RESPONSE_STATUSES` | Respondido | Semântica de "Solicitou Atendimento" |
| `FAILURE_STATUSES` | Falhou, Falha Permanente | Linha de erro na tabela; `getActionErrorMessage`; modal de Motivos de Falha; bucket `failed` do progresso |
| `PENDING_STATUSES` | Pendente, Processando | Bucket `pending`/backlog do progresso |
| `CANCELLED_STATUSES` | Cancelado, Cancelado (Pago), Cancelado (Removido), **Duplicado**, **Em Atendimento** | Bucket `cancelled` do progresso |
| `TERMINAL_STATUSES` | Enviado, Interagiu, Respondido, Falhou, Falha Permanente, Em Atendimento, Cancelado, Cancelado (Pago), Cancelado (Removido), Duplicado | Não usado diretamente nestas 3 telas |

### 2.3 Divergência de agrupamento entre superfícies (importante para o redesign)

O mesmo status é classificado de forma **diferente** em três lugares da mesma tela:

| Status | `CANCELLED_STATUSES` (config) | Bucket do cartão de progresso (`useScheduledProgress.ts:211-216`) | KPIs (`useActions.ts:885-917`) |
|---|---|---|---|
| `Em Atendimento` | dentro | bucket próprio `inService` (roxo), testado **antes** de `cancelled` | conta em `sentStatuses` (entra na Taxa de Envio) |
| `Duplicado` | dentro | `cancelled` | conta em `cancelledStatuses` |
| `Falhou` / `Falha Permanente` | fora | `failed` | `failedStatuses` (fora dos numeradores) |

E, no relatório (`/actions/report`), a legenda do bloco "Performance por Canal" nomeia as faixas de outro jeito ainda: "Ignorado" = ações em `Em Atendimento`, e "Cancelado" = saldo residual (Pendente + Processando + Cancelados + Duplicado + interações em curso). O próprio guia de negócio registra isso (`relatorio-acoes.ts`, seção "Performance por Canal").

### 2.4 Aliases aceitos (entrada legada / webhook em inglês)

`resolveActionStatus()` em `action-status-config.ts:85-129` traduz para canônico:

| Alias | → canônico |
|---|---|
| `pending`, `scheduled` | Pendente |
| `processing` | Processando |
| `sent`, `success`, `executed` | Enviado |
| `delivered`, `recebido`, `entregue`, `read`, `lido`, `interagiu` | Interagiu |
| `replied`, `respondido` | Respondido |
| `failed`, `falha`, `erro`, `falhou`, `nao enviado` | Falhou |
| `permanently_failed` | Falha Permanente |
| `ignorado`, `ignored`, `skipped` | Em Atendimento |
| `cancelled`, `cancelado` | Cancelado |
| `cancelled_paid`, `cancelled_payment_found` | Cancelado (Pago) |
| `cancelled_title_removed`, `cancelled_no_title`, `cancelled_superseded` | Cancelado (Removido) |
| `duplicado`, `repetido`, `repeated`, `duplicate` | Duplicado |

### 2.5 Origem das opções do filtro Status (não é o módulo — é o banco)

`ActionsPage.tsx:147-155` monta as opções a partir de `useStandardValues("action_status")` (tabela `org_<slug>.standard_values`), filtrando `is_active`, e resolve o rótulo com `resolveActionLabel(value, actionStatusValues)` — precedência: **módulo do front → label do DB → valor cru**. A cor do badge do multiselect vem de `standard_values.color`.

Consequências de UI:
1. A **lista de opções do filtro é dinâmica por organização** — pode não ter exatamente os 12 status.
2. A semente `DEFAULT_STANDARD_VALUES.action_status` (`useStandardValues.ts:79-91`) ainda contém `Entregue` e `Lido` (status **removidos** do catálogo canônico) e **não contém** `Interagiu` nem `Duplicado`. Numa org que tenha sido semeada com esse default, o filtro mostrará "Entregue"/"Lido" e faltará "Interagiu"/"Duplicado".
   ⚠️ A confirmar: se em produção as orgs já foram migradas para os 12 canônicos (o código do front não garante isso).
3. `statusValues` (o que vai para a consulta) expande cada status escolhido com seus `aliases` do DB (`ActionsPage.tsx:157-170`).

### 2.6 Descrições longas de status (copy já pronta)

Duas fontes de copy que o redesign deve preservar:

**a) Explicação estruturada** — `ACTION_STATUS_DISPLAY[...].explanation` em `action-status-display.ts`, com os campos `what` / `origin` / `when` / `note` (renderizáveis pelo `HelpTip` no padrão "O que é → Origem → Como calcula → Quando acontece → Observação"). Existe para os 12 status. Exemplos literais:
- `Interagiu` → note: "Só WhatsApp gera "Interagiu"; e-mail não tem webhook de entrega. Conta como envio + interação."
- `Falha Permanente` → note: "Exige correção do dado (ex.: telefone). Não bloqueia o contato — a próxima ativação tenta de novo. ~46% dos casos = telefone inválido. Não conta como envio."
- `Cancelado (Removido)` → note: "Na blips, ~83% são supersede (re-processamento), não remoção real de título."

> ⚠️ Nas 3 telas de Ações essa explicação estruturada **não é exibida** hoje — só a descrição curta de `STATUS_DESCRIPTIONS` (item b). Oportunidade de redesign (§12, O-04).

**b) Descrição curta** — `STATUS_DESCRIPTIONS` em `ErrorSummaryCard.tsx:9-20`, exibida como tooltip por status dentro do popover de detalhe dos KPIs. Cobre 10 dos 12 (falta `Pendente` e `Processando`).

---

## 3. Catálogo de tipos / canais de ação

### 3.1 Tabela de tipos (rótulo, cor, ícone)

Fontes: `ACTION_TYPES` em `src/hooks/useActions.ts:138-157`; `TYPE_ICONS` em `src/lib/constants/action-type-icons.ts`; `TYPE_LABELS` em `src/hooks/useScheduledProgress.ts:61-75`; `getChannelLabel` em `src/hooks/useActionsReport.ts:261-275`.

| Valor cru (`action_type`) | Rótulo (tabela/modal) | Rótulo no cartão de progresso | Rótulo no relatório | Cor do chip (Tailwind) | Ícone lucide | Aparece no filtro "Tipo"? |
|---|---|---|---|---|---|---|
| `whatsapp` | WhatsApp | WhatsApp | WhatsApp | `bg-green-100 text-green-800` | `MessageCircle` | Sim (opção `whatsapp`) |
| `send_whatsapp` | WhatsApp | WhatsApp | WhatsApp | idem | `MessageCircle` | Não (oculto; expandido na consulta) |
| `email` | E-mail | E-mail | E-mail | `bg-blue-100 text-blue-800` | `Mail` | Sim |
| `send_email` | E-mail | E-mail | E-mail | idem | `Mail` | Não |
| `sms` | SMS | SMS | SMS | `bg-purple-100 text-purple-800` | `MessageSquare` | Sim |
| `send_sms` | SMS | SMS | SMS | idem | `MessageSquare` | Não |
| `rcs` | RCS | RCS | RCS | `bg-teal-100 text-teal-800` | `MessageSquareText` | Sim |
| `send_rcs` | RCS | RCS | RCS | idem | `MessageSquareText` | Não |
| `voice` | Voz | Voz | Voz | `bg-orange-100 text-orange-800` | `Phone` | Sim |
| `send_voice` | Voz | Voz | Voz | idem | `Phone` | Não |
| `webhook` | Webhook | Webhook | *(sem tradução — mostra o valor cru)* | `bg-gray-100 text-gray-800` | `Webhook` | Sim |
| `notification` | Notificação | Notificação | *(valor cru)* | `bg-amber-100 text-amber-800` | `FileWarning` | Sim |
| `negativation` | Negativação | Negativação | *(valor cru)* | `bg-rose-100 text-rose-800` | `AlertCircle` | Sim |
| *(qualquer outro)* | o próprio valor | o próprio valor | o próprio valor | `bg-gray-100 text-gray-800` | `Activity` (`DEFAULT_TYPE_ICON`) | Não |

Notas:
- Não existe tipo "IA" em `ACTION_TYPES`. O pipeline tem um step `trigger_ai`, mas ele **não aparece** como tipo de ação nestas telas. ⚠️ A confirmar: se `trigger_ai` chega a gravar linha em `actions` com algum `action_type` próprio — não há evidência no frontend.
- O RCS tem ícone próprio desde o card 7135 (antes caía no `Activity` genérico). O comentário do arquivo registra "8.447 ações em prod".
- O ícone é o mesmo na tabela, no modal de detalhe e no cartão de progresso — consistência a preservar.

### 3.2 Opções exibidas no filtro "Tipo" (`/actions`)

`ACTIONS_FILTER_TYPE_OPTIONS` (`ActionsFiltersBar.tsx:48-50`) = `Object.entries(ACTION_TYPES)` **menos** as chaves que começam com `send_`. Ordem de renderização = ordem de inserção do objeto `baseTypes`:

1. WhatsApp · 2. E-mail · 3. SMS · 4. RCS · 5. Voz · 6. Webhook · 7. Notificação · 8. Negativação

Mais a opção fixa `Todos os Tipos` (valor `"all"`) no topo.

### 3.3 Catálogo paralelo que NÃO é usado nesta tela

`src/lib/constants/action-type-filter.ts` (`ACTION_TYPE_FILTER_OPTIONS`) existe para o filtro "Tipo de ação" da **Gestão de Carteira** (card 6176) e mapeia opção de negócio → conjunto de valores crus. Ele traz rótulos ligeiramente diferentes:

| value | label | actionTypes expandidos |
|---|---|---|
| `whatsapp` | WhatsApp | `send_whatsapp`, `whatsapp` |
| `email` | E-mail | `send_email`, `email` |
| `sms` | SMS | `send_sms`, `sms` |
| `rcs` | RCS | `send_rcs`, `rcs` |
| `voice` | **Ligação** | `send_voice`, `voice` |
| `negativation` | Negativação | `negativation` |
| `notification` | **Notificação extrajudicial** | `notification` |

Diferenças vs. a tela de Ações: "Ligação" em vez de "Voz", "Notificação extrajudicial" em vez de "Notificação", e **não existe** a opção Webhook. Funções auxiliares: `expandActionTypeFilter()` e `sanitizeActionTypeFilter()`.
⚠️ Divergência de vocabulário entre duas telas do mesmo produto — ver §12, D-01.

---

## 4. Tela `/actions` — Histórico de Ações

Arquivo: `src/pages/ActionsPage.tsx`.

### 4.1 Identidade

| Item | Valor exato |
|---|---|
| Título (h1) | **Histórico de Ações** — `text-xl sm:text-2xl font-bold`, com ícone `Activity` (`h-5 w-5 sm:h-6 sm:w-6`) à esquerda |
| Subtítulo | "Visualize todas as ações executadas pelos workflows" — `text-muted-foreground text-sm`, **oculto abaixo de `sm`** (`hidden sm:block`) |
| Ícone do menu lateral | `Zap` (Sidebar), diferente do `Activity` do título ⚠️ (ver §12, D-02) |
| Container | `div.relative.space-y-6` |

### 4.2 Objetivo

Painel operacional de acompanhamento: o que está saindo hoje, o que já saiu, o que falhou, o que está na fila — com intervenção (pausar canal, cancelar ação) e duas saídas analíticas (exportar documento fiel; gerar relatório com IA).

### 4.3 Anatomia (ordem de renderização, de cima para baixo)

```
[RefreshTopBar]  ← barra fina indeterminada no topo, só quando isRefreshing
 1. Cabeçalho: título + subtítulo | botões (Pausar · Exportar · Gerar Relatório com IA · Atualizar)
 2. ActionsFiltersBar  (card "Filtros")            ← vale para a PÁGINA INTEIRA (IAF-6014)
 3a. SE modo identidade: <Alert> informativo (substitui o cartão de progresso)
 3b. SENÃO: <RefreshableSection> com o SendingProgressCard
 4. ActionKPICards (4 cartões)  — OU <Alert variant="destructive"> se statsError
 5. <Alert variant="destructive"> se actionsError  ("Não foi possível consultar as ações: <msg>")
 6. Faixa "Nenhuma ação registrada hoje com os filtros atuais." + botão "Ver ontem"  (condicional)
 7. ActionsTable (card "Ações")
 [modais montados: FailureReasonsDialog, PauseSendingModal, ActionDetailDialog dentro da tabela]
```

**Decisão de layout registrada no código** (`ActionsPage.tsx:342-344`): os filtros vêm **antes** dos cards. "A barra vale para a pagina INTEIRA (progresso + KPIs + lista). Renderizada abaixo dos cards, o layout sugeria que só filtrava 'dali para baixo'." — manter no redesign.

### 4.4 Cabeçalho — botões (label exato, variante, ícone, ação, condição)

Container: `div.flex.gap-2.shrink-0`. Todos os botões são **icon-only abaixo de `sm`** e ganham texto a partir de `sm` (`size="icon"` + `className="sm:w-auto sm:px-4"`, com `<span className="hidden sm:inline">`).

| Ordem | Label (≥ sm) | Ícone lucide | Variante | Condição de exibição | Ação |
|---|---|---|---|---|---|
| 1 | "Pausar Envios" **ou** "N canal(is) pausado(s)" **ou** "Envios Pausados" | `PauseCircle` (`h-4 w-4 sm:mr-2`) | `outline`; vira **`destructive`** quando há ≥ 1 canal pausado | `canWrite` (`actions:write`) **E** (`progress.isActive` **OU** `pausedChannels.length > 0`) | Abre `PauseSendingModal` |
| 2 | "Exportar" | `Download` (troca para `Loader2 animate-spin` enquanto `isPending`) | `outline` | `canExport` (`reports:export`) | Abre `ReportExportDialog` com os filtros atuais e `totalMatching = data?.total ?? 0` |
| 3 | "Gerar Relatório com IA" | `Sparkles` | default (`bg-primary hover:bg-primary/90 text-primary-foreground`) | sempre | `navigate(generateReportUrl())` |
| 4 | *(sem label — icon-only sempre)* | `RefreshCw` (gira enquanto ocupado) | `outline`, `size="icon"` | sempre | `refreshAll()` — invalida lista + stats globais + stats filtradas + progresso |

Lógica do rótulo do botão 1 (`ActionsPage.tsx:306-308`): `isGloballyPaused ? "Envios Pausados" : pausedChannels.length > 0 ? \`${n} canal(is) pausado(s)\` : "Pausar Envios"`.

`generateReportUrl()` (`ActionsPage.tsx:136-144`) monta `/actions/report?` com **apenas**: `startDate`, `endDate`, `campaignId`, `actionType`, `status` (CSV dos status escolhidos). **Não** leva `search`, `source` nem `days` — o relatório ignora esses três recortes.

O `RefreshButton` (`src/components/common/RefreshButton.tsx`): `aria-label`/`title` = "Atualizar", `aria-busy` enquanto ocupado, desabilitado enquanto gira; acompanha `isFetching` externo **ou** a promise retornada por `onRefresh`.

### 4.5 KPIs — `ActionKPICards`

Grid: `grid gap-4 md:grid-cols-2 lg:grid-cols-4` (1 coluna no mobile, 2 no md, 4 no lg).

| # | Título | Valor | Descrição (sublinha) | Ícone | Variante | Tooltip (`HelpTip`, texto exato) | Popover de detalhe |
|---|---|---|---|---|---|---|---|
| 1 | **Total de Ações** | `total.toLocaleString("pt-BR")` | `"{canceladas} canceladas \| {falhas} falhas \| {pendentes} pendentes"` | `Activity` | default | "Total de ações que a campanha realmente gerou (o 'elegível' pós-tratamento). É menor que as 'estimadas' do card da campanha porque já descontou deduplicação, cooldown, prioridade e blocklist. Veja o funil completo em 'Ver ações previstas' na campanha." | `ActionStatusBreakdown` com **todos** os status |
| 2 | **Taxa de Envio** | `sentRate.toFixed(1)%` | `"{sentCount} enviadas"` | `Send` | `success` (borda verde + `bg-green-50/50`) | "Percentual de ações com envio confirmado sobre o total de ações no período" | breakdown filtrado por `SENT_STATUSES` |
| 3 | **Taxa de Interação** | `deliveredRate.toFixed(1)%` | `"{deliveredCount} interações"` | `CheckCircle2` | default | "Percentual de ações com interação confirmada sobre o total de ações no período" | breakdown filtrado por `DELIVERED_STATUSES` (Interagiu + Respondido) |
| 4 | **Solicitou Atendimento** | `responseRate.toFixed(1)%` | `"{responseCount} respostas"` | `MessageCircle` | default | "Percentual de ações onde o contato solicitou atendimento sobre o total" | breakdown filtrado por `status === "Respondido"` |

Estado de carregamento: cada valor vira a string literal `"..."`; a descrição do KPI 1 também vira `"..."`.

Cálculo do "pendentes" do KPI 1: `pending = total - processedTotal - cancelledCount` (`ActionKPICards.tsx:31`), onde `processedTotal = total - pendingCount - cancelledCount` vem do hook. Ou seja, `pending` aqui = `pendingCount` (Pendente + Processando).

**Regra de negócio relevante**: nos KPIs, `Em Atendimento` conta como **enviada** (`useActions.ts:885-889` — "'Em Atendimento' counts as sent … not a cancellation"), embora esteja em `CANCELLED_STATUSES`.

Anatomia do `StatsCard` (`src/components/actions/StatsCard.tsx`):
- `CardHeader` com `flex-row items-center justify-between pb-2`: à esquerda título (`text-sm font-medium`) + `HelpTip` (ícone `HelpCircle` `size-3.5`, `side="bottom"`); à direita `BarChart3` (`h-3.5 w-3.5 text-muted-foreground/40`, só se houver `detailContent`) + o ícone do KPI (`h-4 w-4 text-muted-foreground`).
- `CardContent`: valor `text-2xl font-bold`; descrição `text-xs text-muted-foreground`.
- Com `detailContent`, o card inteiro vira `PopoverTrigger` (`cursor-pointer hover:shadow-md`); o `PopoverContent` é `w-80 p-0`, `align="start"`, `sideOffset={8}`, com `h4` = título do KPI.

Conteúdo do popover (`ActionStatusBreakdown`):
- Cabeçalho: "**{total}** acoes processadas" (sem acento — texto literal do código).
- Uma linha por status com: bolinha colorida (`STATUS_CATEGORY[status].color`), rótulo de exibição (`getActionStatusLabel`), tooltip com `STATUS_DESCRIPTIONS[status]` quando existe, barra proporcional (`count / maxCount`) e o percentual sobre o total.
- Ordenação: já vem ordenada DESC por contagem (`statusBreakdown` é ordenado em `useActions.ts:976-978`).
- Vazio: caixa de 120 px com "Nenhuma acao no periodo".
- Loading: 5 barras `animate-pulse`.

### 4.6 Filtros — `ActionsFiltersBar`

Container: `Card` com `CardTitle` = **"Filtros"**. Grid dos controles: `grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4` (nenhuma largura fixa — decisão do IAF-5703).

#### 4.6.1 Inventário dos controles

| # | Rótulo / placeholder exato | Tipo de controle | Opções | Default | Persistência na URL | Comportamento |
|---|---|---|---|---|---|---|
| 1 | placeholder **"Nome, documento, telefone, contrato ou e-mail"** (`CUSTOMER_SEARCH_PLACEHOLDER`); `aria-label="Buscar cliente"` | `Input` com ícone `Search` à esquerda (`pl-9`), `maxLength={200}` | texto livre | `""` | `?search=` | Debounce de 300 ms antes de consultar; dispara o **modo identidade** quando o termo é documento/telefone/e-mail/contrato |
| 2 | placeholder "Tipo"; item "all" = **"Todos os Tipos"** | `Select` (shadcn) | `all` + as 8 opções de §3.2 | `all` (`actionType = undefined`) | `?type=` | `value === "all"` → `undefined`; a consulta expande para `[tipo, send_tipo]` |
| 3 | label **"Status"**, placeholder **"Todos os Status"** | `FilterMultiSelect` com `triggerVariant="badges"`, `className="w-[220px]"` | status ativos de `standard_values` (§2.5) | `[]` (todos) | `?status=` (CSV) | Ver 4.6.2 |
| 4 | placeholder **"Todas as Origens"** | `Select` | `all` = "Todas as Origens" · `tower` = **"Campanha"** · `manual` = "Manual" · `teste` = "Teste" · `external` = "API" | `all` | `?source=` | Valor enviado à RPC é a chave crua (`tower`/`manual`/`teste`/`external`) |
| 5 | placeholder **"D+ (ex: 5-30)"** | `Input` `font-mono text-sm` | texto livre | `""` | `?days=` | Debounce 300 ms; parseado por `parseDaysRange` (ver 4.6.3) |
| 6 | Data inicial — botão mostra `dd/MM/yyyy` ou o texto **"Data inicial"** | `Popover` + `Calendar` (`mode="single"`, `initialFocus`), botão `variant="outline"` com ícone `CalendarIcon` | calendário | **hoje (BRT)** | `?startDate=` (omitido quando = hoje) | Escolher início > fim arrasta o fim junto |
| 7 | Data final — `dd/MM/yyyy` ou **"Data final"** | idem | calendário | **hoje (BRT)** | `?endDate=` (omitido quando = hoje) | Escolher fim < início arrasta o início junto |
| 8 | **"Hoje"** | `Button` `variant="outline" size="sm"` | — | — | — | Só aparece quando `startDate !== hoje || endDate !== hoje`; volta o intervalo para hoje |
| 9 | placeholder "Campanha"; item "all" = **"Todas as Campanhas"** | `Select` (`data-testid="actions-campaign-filter"`) | todas as campanhas da org, ordenadas por nome | `all` | `?campaignId=` | Só renderiza se `campaigns.length > 0`. Consulta dedicada sem paginação (`ActionsPage.tsx:200-213`) — o bug 2 era o `useCampaigns()` paginado em 20 |
| 10 | **"Limpar todos"** | `Button` `variant="ghost" size="sm"`, ícone `X` (`h-4 w-4 mr-1`) | — | — | — | Só aparece com filtro ativo; ver 4.6.5 |

Os controles 6+7+8 ficam juntos numa célula `flex items-center gap-1 sm:col-span-2`.

#### 4.6.2 Detalhe do multiselect de Status (`FilterMultiSelect`, variante `badges`)

- **Trigger**: `Button variant="outline" role="combobox"`, `h-9`, `aria-expanded`, `aria-label="Status"`.
  - Sem seleção: texto `"Todos os Status"` em `text-muted-foreground`.
  - Com seleção: **badge do 1º item** (cor de fundo = `color + "20"`, texto = `color`; truncado) com um `X` próprio (`aria-label="Remover {label}"`, acionável por Enter/Espaço) + badge `+N` quando há mais de um.
  - `title` do trigger = todos os rótulos selecionados separados por vírgula (o texto completo no hover, porque os rótulos ficaram longos com a IAF-4700).
- **Popover**: largura casada ao trigger (`w-[var(--radix-popover-trigger-width)]`, `min-w-[240px]`), altura limitada à viewport, conteúdo `Command` com:
  - campo de busca `placeholder="Buscar..."`;
  - vazio: "Nenhum resultado encontrado.";
  - primeira linha: **"Selecionar todos"** (vira **"Limpar seleção"** quando tudo está marcado), com checkbox tri-state (cheio / traço quando parcial / vazio);
  - uma linha por status com checkbox + rótulo.

#### 4.6.3 Campo D+ — gramática aceita

`parseDaysRange` (`src/lib/actions-utils.ts:28-47`):

| Entrada | Resultado |
|---|---|
| `""` ou espaços | `null` (sem filtro) |
| `35` | `{min: 35, max: 35}` |
| `-10` | `{min: -10, max: -10}` |
| `5-30` | `{min: 5, max: 30}` |
| `-10-0` | `{min: -10, max: 0}` |
| `-10--5` | `{min: -10, max: -5}` |
| Qualquer outro formato | `null` — **filtro ignorado em silêncio** ⚠️ (ver §12, D-04) |

Semântica: negativo = cobrança preventiva (antes do vencimento); 0 = vence hoje; positivo = dias de atraso.

#### 4.6.4 Modo identidade (busca por cliente)

Disparado quando `search.trim().length >= 2` e a RPC `resolve_contacts_by_identity` devolve contatos (`useActions.ts:404-422`). Gate local em `looksLikeIdentityTerm` (`actions-utils.ts:17-25`): tem `@` no meio, **ou** ≥ 8 dígitos.

O que muda visualmente:

1. **Chip de identidade** (`data-testid="actions-identity-chip"`) renderizado **acima** dos controles, dentro do card Filtros: `border-primary/30 bg-primary/5`, ícone `Search`, texto
   `Histórico completo de **<nome do cliente>** — o período não se aplica.`
   Quando há mais de um contato e há nome: `Histórico completo de **<nome>** e mais N cliente(s) com esse contato — o período não se aplica.`
   Quando não há nome resolvido: `1 cliente` ou `N clientes` no lugar do nome.
   Botão à direita: **"Voltar ao período"** (`variant="ghost" size="sm"`, ícone `X` `h-3.5 w-3.5`) → limpa `search`.
2. **O `SendingProgressCard` desaparece** e é substituído por um `<Alert>` com ícone `Info` e o texto exato:
   "O progresso de envio mede a fila do período. A lista e os indicadores abaixo mostram o histórico completo do cliente. Use **Voltar ao período** para voltar à fila."
3. Os **KPIs continuam visíveis** e passam a contar o histórico completo do cliente (os hooks compartilham o mesmo predicado).
4. A janela de datas é **zerada** na consulta (`p_start_date`/`p_end_date` = null) e o termo textual não é reenviado.
5. O atalho "Ver ontem" não aparece.

Erro de identificação **não é silencioso**: `useActions` lança `"Não foi possível identificar o cliente: <msg>"`, exibido no `Alert` destrutivo da lista.

#### 4.6.5 "Limpar todos" — comportamento exato

Condição de exibição (`hasActiveFilters`, `ActionsFiltersBar.tsx:84-92`): `search` preenchido **ou** `startDate !== hoje` **ou** `endDate !== hoje` **ou** `campaignId` **ou** `actionType` **ou** `statuses.length > 0` **ou** `source` **ou** `daysOverdueRange`.

Ao clicar, emite um objeto **novo** (não spread): `{search: "", page: 1, statuses: [], source: undefined, daysOverdueRange: "", startDate: hoje, endDate: hoje}` — `actionType` e `campaignId` somem **por omissão**.

> ⚠️ O comentário no código diz "Preserva `search` de propósito", mas o objeto emitido zera `search: ""`. O comentário está desatualizado; o comportamento real limpa a busca (e o guia de negócio confirma: "limpa também o texto da busca").

#### 4.6.6 Persistência em URL (write-through)

`ACTIONS_URL_DEFAULTS` (`ActionsPage.tsx:40-50`) e `setFilters` (`:97-123`):

| Chave da URL | Campo do estado | Default (omitido da URL) |
|---|---|---|
| `search` | `search` | `""` |
| `status` | `statuses` (CSV) | `""` |
| `type` | `actionType` | `""` |
| `source` | `source` | `""` |
| `days` | `daysOverdueRange` | `""` |
| `campaignId` | `campaignId` | `""` |
| `startDate` | `startDate` | hoje |
| `endDate` | `endDate` | hoje |
| `page` | `page` | `"1"` |

Regras: leitura **só no inicializador** do `useState` (não é estado derivado — evitar loop de refetch); escrita nos handlers com `replace: true` (não empilha histórico por tecla digitada); valor vazio/igual ao default **remove** a chave. Contrato de deep-link preservado para `startDate`/`endDate`/`campaignId` (usado pelo "↗ Ações" do `CampaignPreviewModal` e pelo `generateReportUrl`).

Qualquer mudança de filtro **reseta `page` para 1** (`setFilters` em `ActionsFiltersBar.tsx:94-96`).

### 4.7 Tabela — `ActionsTable`

Container: `Card` com `CardTitle` = **"Ações"** e `CardDescription` = **"{total} ações encontradas"**.

#### 4.7.1 Colunas (cabeçalho exato, conteúdo, formato, alinhamento)

| # | Cabeçalho | Conteúdo | Formato | Largura / alinhamento | Ordenável? | Badge/ícone |
|---|---|---|---|---|---|---|
| 1 | **Tipo** | Chip com ícone do tipo + rótulo | `div.flex.items-center.gap-2`; ícone dentro de `div.p-1.5.rounded` com a cor do tipo; ícone `h-3.5 w-3.5`; rótulo `text-sm` | auto / esquerda | **Não** | Ícone lucide por tipo (§3.1) |
| 2 | **Contato** | Linha 1: `contact.name` ou `"—"` (`font-medium text-sm`). Linha 2: `recipient` **ou** `contact.document` **ou** `"—"` (`text-xs text-muted-foreground`) | 2 linhas | auto / esquerda | Não | — |
| 3 | **Origem** | Badge `outline` conforme `source` | `manual` → "Manual" (`border-violet-300 text-violet-600`) · `teste` → "Teste" (`border-amber-300 text-amber-600`) · `external` → "API" (`border-gray-300 text-gray-600`) · **qualquer outro valor/ausente** → "Campanha" (`border-blue-300 text-blue-600`) | auto / esquerda | Não | Badge |
| 4 | **Campanha / Régua** | Linha 1: nome da campanha ou `"—"` (`text-sm`). Linha 2: nome da régua (`workflow_step.workflow.name`) ou `"—"`, `text-xs text-muted-foreground truncate max-w-[150px]` com `title` = nome completo | 2 linhas | auto / esquerda | Não | — |
| 5 | **D+** | `metadata.days_overdue` formatado: `D{n}` se negativo, `D+{n}` se ≥ 0. Ausente → `"—"` (`text-muted-foreground text-xs`) | Badge `outline font-mono text-xs` | `text-center` (cabeçalho e célula) | Não | Cores: `< 0` azul (`bg-blue-50 text-blue-700 border-blue-200`), `= 0` amarelo (`bg-yellow-50 …`), `> 0` vermelho (`bg-red-50 …`) |
| 6 | **Status** | Badge `outline` com `getStatusLabel(status)` e `className = getStatusColor(status)`. Abaixo, quando o status está em `FAILURE_STATUSES`: mensagem de erro em `text-xs text-destructive`, `line-clamp-2 break-words max-w-xs`, com `title` completo | Badge + parágrafo opcional | auto / esquerda | Não | Badge colorido |
| 7 | **Processado em** | `processing_started_at` → `toLocaleString("pt-BR", {day:"2-digit", month:"2-digit", hour:"2-digit", minute:"2-digit"})` → ex. `17/09, 14:32`. Ausente → `"—"` | `text-muted-foreground text-sm` | auto / esquerda | Não | — |
| 8 | **Criado em** | `created_at`, mesmo formato (dia/mês + hora:min; **sem ano**) | `text-muted-foreground text-sm` | auto / esquerda | Não | — |
| 9 | *(vazio)* | Botões de linha | — | `w-[80px]` | — | — |

Resolução de rótulo/cor do status na tabela (`ActionsTable.tsx:45-59`): 1º `statusMap[status.toLowerCase()]` (vem de `standard_values`, já com o rótulo resolvido pelo módulo do front e cor do DB); 2º `ACTION_STATUS[status]` (mapa estático); 3º o valor cru / `bg-gray-100 text-gray-800`.

Mensagem de erro exibida: `getActionErrorMessage` (`src/lib/action-error.ts`) — usa `error_message` aparado; se vazio **e** o status for de falha, mostra **"O sistema não registrou o motivo desta falha."**; caso contrário, `null`.

#### 4.7.2 Interação de linha

- A linha inteira é clicável: `className="cursor-pointer hover:bg-muted/50"`, `onClick` → abre `ActionDetailDialog` daquela ação.
- Não há `<a>`; não há foco por teclado na linha ⚠️ (§11).

#### 4.7.3 Ações por linha (coluna 9)

| Botão | Ícone | Variante | Condição | Ação |
|---|---|---|---|---|
| Ver | `Eye` (`h-4 w-4`) | `ghost` `size="icon"` | sempre | `stopPropagation` + abre o modal de detalhe |
| Cancelar | `X` (`h-4 w-4`) | `ghost` `size="icon"`, `text-destructive hover:text-destructive`, `title="Cancelar ação"` | `status === "Pendente" \|\| status === "Processando"` (comparação literal com o valor canônico) | Entra no modo de confirmação inline daquela linha |
| **Confirmar** (modo confirmação) | — | `destructive` `size="sm" h-8 text-xs` | após clicar em Cancelar | `cancelMutation.mutateAsync(action.id)`; toast **"Ação cancelada"** em caso de sucesso, **"Erro ao cancelar"** (`variant="destructive"`) em caso de falha; sai do modo confirmação de qualquer forma |
| **Nao** (modo confirmação) | — | `outline` `size="sm" h-8 text-xs` | idem | Volta ao estado normal |

> O rótulo literal no código é **"Nao"** (sem til) — `ActionsTable.tsx:233`. Corrigir no redesign.

Mutação de cancelamento (`useCancelAction`, `useManualAction.ts:249-268`): `UPDATE actions SET status='Cancelado' WHERE id = ? AND status IN ('Pendente','Processando')`; invalida `["actions"]` e `["contact-actions"]`. **Não usa Edge Function** e **não checa permissão no front**.

#### 4.7.4 Seleção múltipla e ações em massa

**Não existem.** A tabela não tem coluna de checkbox, não tem seleção, não tem barra de ações em massa. O cancelamento em massa (`cancel_campaign_pending_actions`) vive em outra tela — Campanhas › Monitoramento › Histórico de Execuções (registrado em `acoes.ts`: "Para cancelar a fila INTEIRA de uma campanha de uma vez, use o botão de cancelamento em massa no Histórico de Execuções"). Ver §12, O-01.

#### 4.7.5 Paginação

- Tamanho de página: **20** (fixo — `pageSize={20}` em `ActionsPage.tsx:418` e `pageSize: 20` no hook). Não há seletor de tamanho.
- Controles renderizados **somente** quando `totalPages > 1` (`Math.ceil(total / 20)`), no rodapé do card: à esquerda `"Página {page} de {totalPages}"` (`text-sm text-muted-foreground`), à direita dois botões `outline size="sm"`: **"Anterior"** (desabilitado em `page <= 1`) e **"Próxima"** (desabilitado em `page >= totalPages`).
- Não há "ir para a página N", nem primeira/última, nem scroll infinito.
- A página vai para a URL (`?page=`) e volta a 1 a cada mudança de filtro.

#### 4.7.6 Ordenação default

Não há controle de ordenação na UI e **nenhuma coluna é ordenável**. A ordem vem da RPC `search_actions` (server-side). ⚠️ A confirmar: a ordenação efetiva da RPC — o frontend não a declara; pelo padrão do índice citado (`idx_{org}_actions_dedup_contact_created`) e pelas demais telas, presume-se `created_at DESC`, mas isso **não está no código do front**.

#### 4.7.7 Estados da tabela

| Estado | Render |
|---|---|
| Carregando (`isLoading`) | `Loader2 h-8 w-8 animate-spin text-muted-foreground` centralizado, `py-12` |
| Vazio (`actions.length === 0`) | Ícone `Activity h-12 w-12 opacity-50`, título "Nenhuma ação encontrada" (`text-lg font-medium`), subtítulo "Tente ajustar os filtros ou selecionar outro período" (`text-sm`) — tudo centralizado, `py-12` |
| Com dados | Tabela + paginação condicional |

### 4.8 Faixa "sem ações hoje" (atalho Ver ontem)

Renderizada entre os KPIs e a tabela. Condições **todas** necessárias (`ActionsPage.tsx:386-402`): não está em modo identidade; `!statsLoading`; sem `statsError` e sem `actionsError`; `stats == null || stats.total === 0`; `startDate === hoje && endDate === hoje`.

Visual: `rounded-lg border border-dashed bg-muted/40 px-4 py-3 text-sm text-muted-foreground flex items-center justify-between`.
Texto: **"Nenhuma ação registrada hoje com os filtros atuais."**
Botão: **"Ver ontem"** (`variant="outline" size="sm"`) → seta `startDate`/`endDate` para ontem (calculado em BRT via `today + "T12:00:00"` menos 1 dia) e `page: 1`.

### 4.9 Atualização automática e padrão de carregamento híbrido

- **Realtime**: `useActionsRealtime` assina `postgres_changes` (`event: "*"`) no schema `org_<slug>`, tabela `actions`, e invalida com **debounce de 5 s** as chaves `["actions", orgId]`, `["actions","stats",orgId]`, `["actions","filtered-stats",orgId]`, `["scheduled-progress",orgId]`.
- **Polling do progresso**: `useScheduledProgress` refaz a cada **30 s** apenas quando o período é "hoje" **e** `isActive` (há pendentes). `staleTime` 25 s.
- **`staleTime`**: lista 30 s; KPIs 30 s; motivos de falha 30 s; campanhas do filtro 60 s; relatório 10 min (`gcTime` 30 min).
- **Sem skeleton a cada clique**: `placeholderData` mantém os dados anteriores enquanto o novo filtro carrega, **guardado por organização** (`queryKey[1]`/`[2]` = org id) — dados de outra org nunca aparecem.
- **Feedback de "ocupado"**: `RefreshTopBar` (barra de 2 px `bg-primary`, `role="progressbar"`, `aria-label="Atualizar"`, animação `animate-refresh-bar`) + `RefreshableSection` (`opacity-60 pointer-events-none`, `aria-busy`) envolvendo o cartão de progresso + `RefreshButton` girando.
- `isRefreshing = actionsFetching || statsFetching || progressFetching`.
- A lista **não** refaz em foco de janela (`refetchOnWindowFocus: false`).

### 4.10 Exportação (`ActionsExportButton` + `ReportExportDialog`)

Payload de filtros enviado (`ActionsPage.tsx:315-328`): `search`, `startDate`, `endDate`, `campaignId`, `actionType`, `statuses` (já expandidos com aliases), `source`, `daysOverdueMin`, `daysOverdueMax` — todos com `|| null`. `totalMatching = data?.total ?? 0`.

Bloqueios calculados no botão (`ActionsExportButton.tsx:45-49`):

| Situação | `blockedReason` (texto exato) |
|---|---|
| `totalMatching === 0` | "Os filtros aplicados não retornam nenhuma ação. Ajuste o recorte antes de gerar o documento." |
| `totalMatching > 20.000` (`ACTIONS_EXPORT_MAX_ROWS`) | "O recorte contém {N} ações. O limite por relatório é 20.000; reduza o período ou aplique mais filtros." |

`populationNote` passada ao diálogo: "Exporta todos os registros da tabela, não apenas a página visível." + (se há busca) " A busca textual está incluída; o cartão Status de Envio mede outra população."

O fluxo de geração (`useActionsExport`): invoca a Edge Function `export-actions-report` (a org **não** vai no corpo — é resolvida do contexto autenticado, para não abrir IDOR), recebe HTML, cria `Blob`, abre `about:blank` em nova aba, zera `win.opener` e navega; revoga a URL após 60 s. Toasts:
- pop-up bloqueado: título "Permita pop-ups para abrir o relatório", descrição "O documento foi gerado, mas o navegador bloqueou a janela." (`destructive`);
- sucesso PDF: "Relatório aberto para impressão/PDF" + "Use \"Salvar como PDF\" na janela de impressão.";
- sucesso HTML: "Relatório aberto em nova aba";
- erro: "Não foi possível gerar o relatório" + mensagem (`destructive`).

O diálogo em si está documentado em §7.4.

---

## 5. Tela `/actions/report` — Relatório de Ações com IA

Arquivo: `src/pages/ActionsReportPage.tsx`.

### 5.1 Identidade

| Item | Valor exato |
|---|---|
| Título (h1) | **Relatório de Ações com IA** — `text-3xl font-bold`, ícone `Sparkles h-8 w-8 text-primary` |
| Subtítulo | Período formatado `dd/MM/yyyy` (ou `dd/MM/yyyy a dd/MM/yyyy` quando início ≠ fim), locale `ptBR` |
| Voltar | `Button variant="ghost" size="icon"` com `ArrowLeft h-5 w-5` → `navigate("/actions")` |
| Container | `div.space-y-6` dentro de um `ChartErrorBoundary` |

### 5.2 Objetivo

Leitura analítica de um período: um bloco escrito por IA no topo + ~15 blocos de gráficos/tabelas que sustentam a leitura, com saída para PDF via impressão do navegador. É a tela de reunião/prestação de contas.

### 5.3 Entrada de filtros (query string)

Lidos de `useSearchParams` (`ActionsReportPage.tsx:141-150`), sem UI de filtro na própria tela:

| Param | Default |
|---|---|
| `startDate` | hoje em Brasília (calculado como `now - 3h` → `toISOString().split("T")[0]`) |
| `endDate` | idem |
| `campaignId` | `undefined` |
| `actionType` | `undefined` |
| `status` | `undefined` |

Não há como alterar o recorte **dentro** desta tela — é preciso voltar a `/actions`. `search`, `source` e `days` não são recebidos.

### 5.4 Cabeçalho e botões

| Botão | Label | Ícone | Variante | Ação |
|---|---|---|---|---|
| Voltar | *(icon-only)* | `ArrowLeft` | `ghost` `size="icon"` | `/actions` |
| Atualizar | **"Atualizar"** | `RefreshCw` (gira) | `outline` (via `RefreshButton`) | `invalidateReport()` — invalida `["actions-report", orgSlug]` |
| Exportar PDF | **"Exportar PDF"** | `Download h-4 w-4 mr-2` | `outline` | `window.print()` |

A faixa inteira do cabeçalho tem `print:hidden`; em seu lugar, no modo impressão, aparece um bloco `hidden print:block` com: `h1` = "Relatório de Ações - {nome da org}" e a linha "Período: … | Gerado em: dd/MM/yyyy HH:mm".

### 5.5 Anatomia — blocos na ordem de renderização

| # | Bloco | Tipo | Condição de exibição |
|---|---|---|---|
| 1 | Insights Gerados por IA | Card com resumo + 3 listas | `report.aiInsights` presente |
| 2 | Faixa de 6 KPIs | grid de `StatsCard` local | sempre |
| 3 | Verificação de duplicatas | faixa verde ou vermelha | sempre |
| 4 | Grade de gráficos (`grid gap-6 lg:grid-cols-2`) | 6 a 8 cards | parcialmente condicional |
| 5 | Ações por Dia | Card com barras empilhadas | `dailyBreakdown?.length > 0` |
| 6 | Distribuição de Frequência por Contrato | Card com barras horizontais | `contractCoverage` presente |
| 7 | Funil de Interação | Card com barras + split por canal | `interactionFunnel && sent > 0` |
| 8 | Desempenho por Step da Régua | Card com barras empilhadas + tabela | `stepPerformance?.length > 0` |
| 9 | Sobreposição de Contatos entre Campanhas | Card com cartões numéricos | sempre |
| 10 | Contatos com Múltiplas Ações | Card com tabela | `topContactsByActions.length > 0` |
| 11 | Análise de Erros | Card com tabela | `errorBreakdown.length > 0` |
| 12 | Rodapé | texto centralizado | sempre |

### 5.6 Bloco 1 — Insights Gerados por IA

- `Card` com `border-primary/20 bg-gradient-to-br from-primary/5 to-transparent`.
- Título: **"Insights Gerados por IA"** com `Sparkles h-5 w-5 text-primary`; descrição: "Análise automatizada baseada nos dados do período".
- Corpo: parágrafo `summary` (`text-sm leading-relaxed`) e um `grid gap-4 md:grid-cols-3`:

| Coluna | Título | Ícone | Cor | Conteúdo |
|---|---|---|---|---|
| 1 | **Pontos Positivos** | `CheckCircle2 h-4 w-4` | `text-green-700`, bullets `text-green-600` | `aiInsights.positivePoints[]` |
| 2 | **Pontos de Atenção** | `AlertTriangle h-4 w-4` | `text-amber-700`, bullets `text-amber-600` | `aiInsights.attentionPoints[]` |
| 3 | **Recomendações** | `Lightbulb h-4 w-4` | `text-blue-700`, bullets `text-blue-600` | `aiInsights.recommendations[]` |

Bullets são o caractere `•` em `<span>`; itens em `text-sm`.

### 5.7 Bloco 2 — Os 6 KPIs

Grid: `grid gap-4 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6`. Componente `StatsCard` **local** deste arquivo (`ActionsReportPage.tsx:1283-1296`) — **diferente** do `StatsCard` de `components/actions/` (não tem tooltip nem popover).

| # | Título | Valor | Descrição | Ícone | Variante |
|---|---|---|---|---|---|
| 1 | **Total de Ações** | `formatNumber(stats.total)` | `"{stats.campaigns} campanhas"` | `Activity` | default |
| 2 | **Contatos Únicos** | `formatNumber(stats.uniqueContacts)` | `"{total/uniqueContacts com 1 casa} ações/contato"` | `Users` | default |
| 3 | **Contratos Acionados** | `formatNumber(contractCoverage.contractsReached \|\| 0)` | `"{avgActionsPerContract} ações/contrato"` | `FileText` | default |
| 4 | **Taxa de Sucesso** | `formatPercentage(Σ channelPerformance.success / total × 100)` | "Ações bem-sucedidas" | `TrendingUp` | **`success`** (`border-green-200 bg-green-50/50`) |
| 5 | **Taxa de Resposta** | `formatPercentage(interactionFunnel.responded / interactionFunnel.sent × 100)` | `"{responded} respostas"` | `Filter` | default |
| 6 | **Dívida Acionada** | `formatCurrency(Σ debtInfo.totalDebt)` | "Valor total" | `DollarSign` | default |

Formatação: `formatCurrency` = `toLocaleString("pt-BR", {style:"currency", currency:"BRL", minimumFractionDigits:2})`; `formatNumber` = `toLocaleString("pt-BR")`; `formatPercentage` = `toFixed(1) + "%"`.

### 5.8 Bloco 3 — Verificação de duplicatas

| `hasExactDuplicates` | Visual |
|---|---|
| `false` | `bg-green-50 border-green-200 text-green-800`, ícone `CheckCircle2 h-5 w-5`, **"Sem duplicatas exatas"** + "- Nenhuma ação duplicada (mesmo contato + campanha + step) detectada" |
| `true` | `bg-red-50 border-red-200 text-red-800`, ícone `XCircle h-5 w-5`, **"Duplicatas detectadas!"** + "- Existem ações duplicadas que precisam ser investigadas" |

### 5.9 Bloco 4 — Grade de gráficos (2 colunas em `lg`)

Todos os cards têm `CardTitle` com ícone + `SectionTooltip` (`HelpTip` com o texto de `SECTION_TOOLTIPS`). Biblioteca: **Chart.js via react-chartjs-2** (`Bar`, `Doughnut`), com `responsive: true, maintainAspectRatio: false` e altura fixa por container.

| # | Título exato | Ícone do título | Gráfico | Altura | Detalhes |
|---|---|---|---|---|---|
| 4.1 | **Distribuição por Status** | `PieChart` | `Doughnut` | `h-64` | Labels = `getStatusLabel(status)` (rótulos de exibição); cores = `getStatusColor` (hex da §2.1); `borderWidth: 0`; legenda embaixo |
| 4.2 | **Ações por Campanha** | `BarChart3` | `Bar` (2 séries) | `h-64` | Série "Ações" `#3b82f6`, série "Contatos" `#10b981`, `borderRadius: 6`, `y.beginAtZero`, legenda embaixo |
| 4.3 | **Performance por Canal** | `Activity` | barras HTML (não Chart.js) | — | Uma linha por canal: nome (`getChannelLabel`) + "{total} ações \| {taxa} sucesso"; barra `h-2 rounded-full` com 4 segmentos: verde `bg-green-500` (success), âmbar `bg-amber-400` (pending), vermelho `bg-red-500` (failed), cinza `bg-gray-400` (ignored). Legenda com 5 pontos: Sucesso (verde), **Cancelado** (âmbar, só se > 0), **Respostas** (roxo `bg-purple-500`), Falha (vermelho), Ignorado (cinza) |
| 4.4 | **Timeline de Execução** | `Clock` | `Bar` 1 série | `h-64` | Descrição do card: "Horário de Brasília (GMT-3)"; cor `#3b82f6`, `borderRadius: 4`, sem legenda |
| 4.5 | **Respostas por Horário de Envio** | `TrendingUp` | `Bar` 2 séries, 2 eixos Y | `h-64` | Só se `responseTimeline.length > 0`. Descrição: "Qual horário de envio gera mais respostas? (baseado em hora de processamento)". Série "Envios" (azul, eixo `y` à esquerda) e "Respostas" (roxo `#8b5cf6`, eixo `y1` à direita, sem grid). Tooltip `afterBody` mostra "Taxa: X%" apenas quando `totalActions >= 50`. Abaixo, caixa roxa `bg-purple-50 border-purple-200` com **"🎯 Melhor horário para enviar"** e "Ações enviadas às {hora} geraram {N} respostas (X% de taxa)" |
| 4.6 | **Horários de Maior Engajamento** | `Clock` | `Bar` 1 série | `h-64` | Só se `engagementTimeline.length > 0`. Descrição: "Em que horários os contatos mais respondem? (baseado em updated_at)". Abaixo, caixa azul `bg-blue-50 border-blue-200` com **"📊 Pico de engajamento"** e "O maior volume de respostas ocorre às {hora} ({N} respostas)" |
| 4.7 | **Distribuição por Faixa de Vencimento** | `BarChart3` | `Bar` horizontal (`indexAxis: "y"`) | `h-64` | Cores por bucket: Preventivo `#3b82f6` · Vence hoje `#10b981` · 1-15 dias `#f59e0b` · 16-30 dias `#f97316` · 31-60 dias `#ea580c` · 61-90 dias `#ef4444` · 90+ dias `#dc2626` · outro `#6b7280` |
| 4.8 | **Valor da Dívida por Campanha** | `DollarSign` | Tabela | — | Colunas: **Campanha** (`font-medium`, esquerda) · **Contatos** (direita, `formatNumber`) · **Total** (direita, `formatCurrency`) · **Média** (direita, `formatCurrency`). Sem paginação, sem ordenação |

> ⚠️ Inconsistência de legenda no 4.3: a faixa âmbar usa o campo `channel.pending` mas é rotulada "**Cancelado**"; o campo `ignored` é rotulado "Ignorado" e o guia diz que corresponde a `Em Atendimento`. Ver §12, D-03.

### 5.10 Bloco 5 — Ações por Dia

- Título **"Ações por Dia"** com `CalendarDays`; descrição "Distribuição diária por canal e falhas".
- `Bar` empilhado (`x.stacked`, `y.stacked`), altura `h-72`, labels no formato `dd/MM`.
- 5 séries: WhatsApp `#22c55e` · E-mail `#3b82f6` · SMS `#eab308` · Voz `#8b5cf6` · **Falhas** `#ef4444`. `borderRadius: 2`.
- Tooltip customizado: modo `index`, fundo branco, borda `#e5e7eb`, `cornerRadius: 8`, valores em `pt-BR`, rodapé em negrito com **"Total: N"**.
- ⚠️ Não há série de RCS, negativação, notificação nem webhook neste gráfico.

### 5.11 Bloco 6 — Distribuição de Frequência por Contrato

- Título **"Distribuição de Frequência por Contrato"** com `FileText`; descrição "Quantas ações cada contrato recebeu no período".
- `Bar` horizontal, `h-48`, 4 cores fixas por posição: `#3b82f6`, `#10b981`, `#f59e0b`, `#ef4444`. Tooltip: "{N} contratos (X%)".
- Rodapé do card: "Max: {maxActionsPerContract} ações em um único contrato".
- Faixas (segundo o guia de negócio): 1 ação · 2-5 ações · 6-15 ações · 16+ ações.

### 5.12 Bloco 7 — Funil de Interação

- Título **"Funil de Interação"** com `Filter`; descrição "Progressão: Enviado → Interagiu → Solicitou Atendimento".
- 3 barras horizontais (`h-6 rounded`), largura proporcional ao 1º passo (mínimo 1%):
  | Etapa | Cor |
  |---|---|
  | **Enviado** | `#3b82f6` |
  | **Interagiu** | `#10b981` |
  | **Solicitou Atendimento** | `#f59e0b` |
  Cada etapa mostra o valor à direita (`font-mono font-medium`) e, a partir da 2ª, "(X% do anterior)" em `text-xs text-muted-foreground`.
- Split por canal (`grid grid-cols-2 gap-4`):
  - **WhatsApp** — caixa `bg-green-50 border-green-200`, 3 linhas: Enviado, Interagiu, **Solicitou Atendimento** (negrito).
  - **E-mail** — caixa `bg-blue-50 border-blue-200`, **2 linhas**: Enviado e Interagiu (negrito). E-mail não tem "Solicitou Atendimento".

### 5.13 Bloco 8 — Desempenho por Step da Régua

Gráfico (`h-64 mb-6`): `Bar` empilhado, label do eixo X = `D+{dia}` / `D{dia}` / `N/A`. Séries: **Respondido** `#f59e0b` · **Interagiu** `#10b981` (calculado como `interacted - responded`) · **Enviado** `#3b82f6` (`sent - interacted`) · **Falha** `#ef4444` · **Cancelado** `#9ca3af`.

Tabela dentro de `ScrollArea h-72`:

| Coluna | Conteúdo | Alinhamento | Formato |
|---|---|---|---|
| **Workflow** | `step.workflowName` | esquerda | `text-xs` |
| **Step** | dia-gatilho | esquerda | Badge `outline` com `D+{n}` / `D{n}` / `N/A` |
| **Canal** | `send_whatsapp` → "WhatsApp", `send_email` → "Email", senão o valor cru | esquerda | `text-xs` |
| **Total** | `formatNumber(total)` | direita | — |
| **Enviados** | `formatNumber(sent)` | direita | — |
| **Interagiram** | `formatNumber(interacted)` | direita | — |
| **Solicitaram Atend.** | `formatNumber(responded)` | direita | — |
| **Taxa Resp.** | `responded/sent × 100` com 1 casa | direita | Badge: `default` se melhor, `destructive` se pior, `secondary` caso contrário |

Realce de linha: melhor taxa → `bg-green-50`; pior taxa → `bg-red-50`. Só entram no cálculo steps com `sent >= 10`; o "pior" só é marcado se houver mais de um step elegível.

> ⚠️ Rótulo "Email" (sem hífen) aqui, contra "E-mail" no resto do produto.

### 5.14 Bloco 9 — Sobreposição de Contatos entre Campanhas

- Título com `Users`.
- `flex flex-wrap gap-4`; um cartão por categoria (`flex-1 min-w-[150px] p-4 bg-muted rounded-lg text-center`) com o número (`text-2xl font-bold`) e a categoria (`text-sm text-muted-foreground`).
- As categorias vêm do backend (`contactOverlap[].category`); segundo o guia: "Uma campanha", "Duas campanhas" e um cartão por total distinto acima disso (sem agregação em "3+").

### 5.15 Bloco 10 — Contatos com Múltiplas Ações

- Título **"Contatos com Múltiplas Ações"** com `AlertTriangle h-5 w-5 text-amber-500`; descrição "Contatos que receberam mais de uma ação no período".
- Tabela dentro de `ScrollArea h-64`:

| Coluna | Conteúdo | Alinhamento | Badge |
|---|---|---|---|
| **Contato** | `contactName` | esquerda (`font-medium`) | — |
| **Ações** | `totalActions` | direita | Badge `destructive` se > 5, senão `secondary` |
| **Campanhas** | `campaigns` | direita | — |
| **Steps** | `steps` | direita | — |

### 5.16 Bloco 11 — Análise de Erros

- Título **"Análise de Erros"** com `XCircle h-5 w-5 text-destructive`.
- Tabela simples (sem scroll, sem paginação):

| Coluna | Conteúdo | Alinhamento |
|---|---|---|
| **Status** | Badge `destructive` com `getStatusLabel(status)` (rótulo de exibição) | esquerda |
| **Mensagem** | `errorExcerpt` ou **"Sem mensagem de erro"**; `max-w-md truncate text-sm text-muted-foreground` | esquerda |
| **Quantidade** | `count` | direita (`font-medium`) |

### 5.17 Rodapé

`text-center text-sm text-muted-foreground py-4 print:py-2`:
"Relatório gerado em {dd/MM/yyyy 'às' HH:mm} | Torre de Controle - {nome da org}"

### 5.18 Tooltips das seções (copy literal)

`SECTION_TOOLTIPS` (`ActionsReportPage.tsx:88-104`) — 15 chaves. Reproduzidas aqui porque são copy de produto que o redesign deve carregar:

| Chave | Texto |
|---|---|
| `statusDistribution` | "Mostra a proporção de ações em cada status final: Recebido (entregue ao contato), Falha (erro no envio), Ignorado (filtrado por regra de negócio, ex: cooldown ou duplicidade), Cancelado (removido por pagamento detectado ou outro motivo)." |
| `campaignBreakdown` | "Compara o volume de ações geradas e contatos únicos acionados por cada campanha no período." |
| `channelPerformance` | "Exibe a distribuição de resultados por canal de envio. Sucesso = entregue/recebido. Falha = erro no provedor. Ignorado = ação filtrada antes do envio (ex: cooldown, contato sem telefone). Cancelado = ação removida após detecção de pagamento ou cancelamento manual. Respostas = mensagens respondidas pelo contato." |
| `executionTimeline` | "Volume de ações processadas por hora no dia (horário de Brasília)." |
| `responseBySendHour` | "Cruza o horário em que a ação foi processada com o número de respostas recebidas, ajudando a identificar os melhores horários de envio." |
| `engagementHours` | "Mostra em quais horários os contatos mais respondem, baseado no timestamp de atualização da ação." |
| `agingDistribution` | "Distribui os contatos acionados por faixa de dias em atraso (aging), do preventivo ao 90+ dias." |
| `debtByCampaign` | "Resume o valor total, médio e por contato da dívida acionada em cada campanha." |
| `contactOverlap` | "Mostra quantos contatos foram acionados em uma, duas ou mais campanhas simultaneamente no período." |
| `multipleActions` | "Lista contatos que receberam mais de uma ação, ajudando a identificar possível excesso de acionamento." |
| `errorAnalysis` | "Agrupa as ações com falha por status e mensagem de erro para facilitar a identificação de problemas recorrentes." |
| `dailyBreakdown` | "Distribuição diária de ações por canal (sucesso) e falhas, permitindo identificar tendências e picos ao longo do período." |
| `contractCoverage` | "Mostra quantos contratos distintos foram acionados, a frequência média de ações por contrato e a distribuição de volume." |
| `interactionFunnel` | "Funil progressivo: Enviado → Interagiu → Solicitou Atendimento, com split por canal (WhatsApp vs Email)." |
| `stepPerformance` | "Desempenho de cada step da régua de cobrança (D-10, D+3, etc), mostrando volume, interações e respostas." |

> ⚠️ O tooltip de `statusDistribution` descreve categorias ("Recebido / Falha / Ignorado / Cancelado") que **não** são os rótulos das fatias — a rosca mostra os status reais. O próprio guia de negócio já registra essa ressalva.

---

## 6. Tela `/actions/payment-analysis` — Análise: Ações × Pagamentos

Arquivo: `src/pages/ActionPaymentAnalysis.tsx`.

### 6.1 Identidade

| Item | Valor exato |
|---|---|
| Título (h1) | **Análise: Ações de Cobrança × Pagamentos** — `text-3xl font-bold tracking-tight` |
| Subtítulo | "Correlação entre ações disparadas pela Torre de Controle e títulos pagos após o envio" |
| Badges sob o subtítulo | `outline` "Período: Últimos 30 dias" · `outline` "Org: blips" · `secondary` "Atualizado: {data de hoje, pt-BR}" |
| Container | `container mx-auto p-6 space-y-6` |

### 6.2 ACHADO CRÍTICO: a tela é 100 % estática

**Todos os números desta tela são constantes hardcoded no próprio arquivo** (`ActionPaymentAnalysis.tsx:37-107`). Não há hook, não há query, não há `useOrganization`, não há filtro, não há estado — a única coisa dinâmica é a data de "Atualizado", que usa `new Date()`.

Os dados congelados são de **org "blips"**, período de **03/02 a 10/02** (ano não declarado), e a própria tela anuncia "Período: Últimos 30 dias" no badge — o que é falso para qualquer visita posterior. Não há link para ela em nenhum menu.

Constantes embutidas:
- `summaryData`: 8.926 ações, 5.713 títulos, 4.177 contatos, 109 títulos pagos, 1,91 % de conversão, R$ 141.573,98 recuperados.
- `channelData`: Email (7.282 ações, 151 pagos, 2,07 %, R$ 209.312,69, 1 dia) e WhatsApp (1.644, 41, 2,49 %, R$ 52.099,52, 1,1 dia).
- `campaignData`: "Carteira Blips" e "Carteira Ideal".
- `workflowData`: 6 steps de "[BLIPS] Régua Locação" e "[IDEAL] Régua Venda".
- `weekdayData`, `dailyEvolution`, `multiActionData`.
- ⚠️ Os próprios números são internamente inconsistentes: `summaryData.paidTitles = 109` contra `151 + 41 = 192` em `channelData`, e o "Resumo Executivo" exibe um total recuperado de R$ 261.412,21, diferente do KPI de R$ 141.573,98.

### 6.3 Anatomia

```
1. Cabeçalho (título + subtítulo + 3 badges)
2. Faixa de 6 KPIs  (grid-cols-2 md:grid-cols-3 lg:grid-cols-6)
3. Tabs (5 abas, grid w-full grid-cols-5): Por Canal · Por Campanha · Por Workflow · Análise Temporal · Insights
```

### 6.4 KPIs (6 cartões)

| # | Rótulo (`CardDescription`) | Ícone | Valor | Estilo do card |
|---|---|---|---|---|
| 1 | Ações Enviadas | `Send h-3 w-3` | `8.926` | default |
| 2 | Títulos Acionados | `Target` | `5.713` | default |
| 3 | Contatos Únicos | `Users` | `4.177` | default |
| 4 | Títulos Pagos | `CheckCircle` | `109` (verde) | `border-green-500/50 bg-green-500/5` |
| 5 | Taxa Conversão | `TrendingUp` | `1.91%` (azul) | `border-blue-500/50 bg-blue-500/5` |
| 6 | Valor Recuperado | `DollarSign` | `R$ 141.573,98` (esmeralda, `text-xl`) | `border-emerald-500/50 bg-emerald-500/5` |

### 6.5 Abas

Biblioteca de gráficos: **Recharts** (diferente do Chart.js do relatório — duas libs de gráfico no mesmo domínio). Paleta `COLORS = ["#10b981","#3b82f6","#f59e0b","#ef4444","#8b5cf6","#ec4899"]`.

| Aba (`TabsTrigger`) | Conteúdo |
|---|---|
| **Por Canal** (default) | 2 cards (Email / WhatsApp) com ícone (`Mail` / `MessageSquare`), grid 2×2 de métricas (Total Ações, Títulos Pagos em verde, Taxa de Conversão em azul, Valor Recuperado em esmeralda), linha "Tempo médio até pagamento: **X dia(s)**" e `Progress` com `value = rate × 10`. Abaixo, card "Comparativo de Conversão por Canal" com `BarChart` (séries "Ações" `#94a3b8` e "Pagos" `#10b981`, 2 eixos Y), altura 300 |
| **Por Campanha** | 2 cards de campanha com badge de conversão (`default` na 2ª, `secondary` na 1ª) e métricas (Ações, Convertidos, Valor Recuperado). Abaixo, card "Distribuição de Valor por Campanha" com `PieChart` (label `nome: XX,X%`, `outerRadius 100`), altura 300 |
| **Por Workflow** | Card "Taxa de Conversão por Step do Workflow" (descrição "Steps ordenados por taxa de conversão (maior para menor)") com linhas: ícone do canal (`MessageSquare` verde para WhatsApp, `Mail` azul para email), nome do step, badge `outline` com o workflow, taxa em `font-bold text-lg`, `Progress` (`value = rate × 25`, verde no 1º) e rodapé "{N} ações → {M} pagos" + valor. Abaixo, card "Comparativo Visual por Workflow" com `BarChart` vertical (`layout="vertical"`, `YAxis width={150}`), altura 350 |
| **Análise Temporal** | 2 cards lado a lado: "Pagamentos por Dia da Semana" (`Calendar`, descrição "Sexta-feira concentra 56% dos pagamentos", `BarChart`, altura 300) e "Valor Recuperado por Dia" (`DollarSign`, `AreaChart` com `stroke #10b981` e `fill #10b98140`, eixo Y em `R$Xk`, altura 300). Abaixo, card "Evolução Diária: Ações vs Conversões" (`TrendingUp`, descrição "Ações recentes (09-10/02) ainda não tiveram tempo de converter", `LineChart` com 3 linhas — Ações `#94a3b8`, Convertidos `#10b981`, Taxa `#3b82f6` tracejada — 2 eixos Y, altura 350) |
| **Insights** | 4 cards de insight com borda colorida + 1 gráfico + 1 resumo executivo (ver 6.6) |

### 6.6 Aba Insights — conteúdo literal

| Card | Borda / cor do título | Ícone | Título interno | Texto |
|---|---|---|---|---|
| Insight Principal | `border-green-500/50`, `text-green-600` | `Zap` | "WhatsApp Preventivo é o mais eficaz" | "Com taxa de **3,94%** de conversão, o step "WhatsApp Preventivo" da Carteira Ideal supera em quase 2x a média geral de 1,91%." + "💡 Recomendação: Intensificar cobrança preventiva via WhatsApp" |
| Padrão Temporal | `border-blue-500/50`, `text-blue-600` | `Calendar` | "Sexta-feira concentra 56% dos pagamentos" | "Clientes tendem a regularizar dívidas no final da semana. **R$ 163.970** foram pagos em sextas-feiras." + "💡 Recomendação: Intensificar ações na quinta para conversão na sexta" |
| Multicanal Funciona | `border-purple-500/50`, `text-purple-600` | `Send` | "Títulos com 2+ ações convertem mais" | "Dos títulos pagos, **51** receberam 2 ações antes de converter, totalizando **R$ 57.986,11**." + "💡 Recomendação: Régua multicanal (Email + WhatsApp) para títulos importantes" |
| Resposta Rápida | `border-amber-500/50`, `text-amber-600` | `Clock` | "Tempo médio de 1 dia até pagamento" | "A maioria dos pagamentos ocorre **1-2 dias** após a ação. O impacto é imediato quando funciona." + "💡 Insight: Se não converteu em 3 dias, seguir com próximo step da régua" |

Depois: card "Múltiplas Ações por Título" (`BarChart` com séries "Títulos" `#8b5cf6` e "Valor (R$)" `#10b981`, altura 250) e card "Resumo Executivo" (`border-emerald-500`), com duas colunas:
- **"✅ O que está funcionando:"** — 4 itens com `CheckCircle` verde: "WhatsApp Preventivo com 3,94% de conversão" · "Carteira Ideal performa 32% melhor que Blips" · "Resposta rápida: 1-2 dias até pagamento" · "Multicanal aumenta chance de conversão".
- **"📊 Números-chave:"** — "Total recuperado: R$ 261.412,21" · "Taxa geral de conversão: ~2%" · "Melhor canal: WhatsApp (2,49%)" · "Melhor dia: Sexta-feira (56%)".

### 6.7 Estados

Não há loading, erro, vazio, guard de organização nem permissão. A tela sempre renderiza o mesmo conteúdo.

---

## 7. Modais e painéis do domínio

### 7.1 `ActionDetailDialog` — Detalhes da Ação

| Item | Valor |
|---|---|
| **Objetivo** | Mostrar tudo sobre uma ação: identificação, roteamento (campanha/régua/step), linha do tempo, erro, conteúdo enviado e payloads técnicos; permitir cancelar |
| **Gatilho** | Clique em qualquer lugar da linha da tabela **ou** no botão `Eye` da coluna de ações |
| **Fonte dos dados** | Nenhuma consulta nova: `actions.find(a => a.id === actionId)` sobre a página atual (`ActionDetailDialog.tsx:315`). Se não achar, retorna `null` (modal não abre) |
| **Container** | `DialogContent` `flex flex-col p-0 max-w-2xl max-h-[90vh]`; corpo rolável `flex-1 overflow-y-auto px-6 py-4` |
| **Fechar** | `onOpenChange(false)` → `onClose()`; X padrão do `Dialog` (o header reserva `pr-10` para ele) |

**Header** (`px-6 py-4 border-b`): à esquerda, chip do tipo (`p-2 rounded-lg` com a cor do tipo + ícone `h-5 w-5`), título **"Detalhes da Ação"** (`text-lg`) e sublinha `"{rótulo do tipo} • {created_at em pt-BR completo}"`. À direita, badge `outline` com a cor e o rótulo do status (`text-sm`).

**Corpo — bloco de detalhes** (`grid grid-cols-2 gap-4 p-4 bg-muted/30 rounded-lg border`); todos os rótulos em `text-xs text-muted-foreground uppercase tracking-wide`:

| Coluna | Campo | Conteúdo |
|---|---|---|
| Esquerda | **Contato** | `contact.name` ou `—`; abaixo o documento; botão **"Abrir na Gestão de Carteira"** (`outline size="sm" h-7`, ícone `Briefcase h-3.5 w-3.5`) quando há `contact_id` → navega para `/portfolio?contact={id}[&contract={id}]` e fecha o modal |
| Esquerda | **Destinatário** | `recipient` ou `—` (`font-mono text-sm`) |
| Esquerda | **ID Externo** | Só se existe; `font-mono text-sm` + link `ExternalLink h-4 w-4` quando `integration.config.externalActionUrl` é string não vazia; a URL substitui `{{external_id}}` pelo valor; abre em `_blank` com `rel="noopener noreferrer"`, `title="Abrir no sistema externo"` |
| Direita | **Campanha** | `campaign.name` ou `—` |
| Direita | **Régua de Cobrança** | `workflow_step.workflow.name` ou `—` |
| Direita | **Step** | `workflow_step.name` ou `—` |
| Direita | **Origem** | Mesmo badge da tabela (Manual / Teste / API / Campanha); em `source === "manual"` com `source_detail.user_id`, sublinha `"por {8 primeiros caracteres}..."` com `title` completo |
| Direita | **Dias de Atraso** | Badge `outline font-mono` com `D{n}`/`D+{n}` e as mesmas 3 cores da coluna D+ |
| Direita | **Integração** | `integration.name`, só se existe |

**Histórico de Status** (`Clock h-4 w-4` + "Histórico de Status"): lista `border rounded-lg divide-y`, uma linha por evento, com o rótulo à esquerda (`text-muted-foreground`) e o timestamp à direita (`font-mono text-xs`, `dd/MM HH:mm:ss`). Eventos montados em `ActionDetailDialog.tsx:46-69`:

| Ordem | Rótulo | Fonte do timestamp | Condição |
|---|---|---|---|
| 1 | **Criado** | `created_at` | sempre |
| 2 | **Processado** | `processing_started_at` | se existe |
| 3 | **Enviado** | `sent_at` | se existe |
| 4 | **Interagiu** | `delivered_at` | se existe |
| 5 | **Lido (read_at)** | `read_at` | se existe |
| 6 | rótulo do status atual | `sent_at \|\| created_at` | se o status atual difere do último da lista **e** não é Pendente/Enviado/Interagiu |

**Motivo registrado** (`XCircle h-4 w-4`, `text-destructive`): caixa `bg-destructive/10 border-destructive/20`, `whitespace-pre-wrap break-words`. Aparece quando `getActionErrorMessage` retorna algo.

**Conteúdo da Mensagem**: `bg-muted p-4 rounded-lg text-sm whitespace-pre-wrap border max-h-48 overflow-y-auto`, com `content || message_content`.

**Detalhes Técnicos** (`Code h-4 w-4`, dentro de `border-t pt-4`): dois blocos opcionais — "Request Payload" e "Resposta da API" — renderizados pelo `PayloadViewer`: `pre` com `JSON.stringify(payload, null, 2)`, `max-h-48 overflow-auto`, `text-xs font-mono whitespace-pre-wrap break-all`, e botão de copiar `ghost size="icon" h-6 w-6` no canto superior direito que alterna `Copy` → `Check` (`text-primary`) por 2 s.

**Cancelar Ação** (rodapé, `border-t pt-2`, só quando status é `Pendente` ou `Processando`):
1. Estado inicial: botão **"Cancelar Ação"** (`destructive size="sm"`, ícone `Trash2 h-4 w-4 mr-2`).
2. Estado de confirmação: texto "Ação será cancelada e não será enviada" + botão **"Voltar"** (`outline size="sm"`) + botão **"Confirmar"** (`destructive size="sm"`, desabilitado enquanto `isPending`).
3. Ao confirmar: `mutateAsync(action.id)` e `onCancel?.()` (que fecha o modal). **Sem toast aqui** (ao contrário do cancelamento pela tabela) ⚠️.

> `ActionDetailContent` é exportado e reutilizado fora do modal (com `hideHeader`), p.ex. no histórico do contato; nesse uso `onOpenContact` não é passado, para evitar auto-referência.

### 7.2 `FailureReasonsDialog` — Motivos de Falha

| Item | Valor |
|---|---|
| **Objetivo** | Ranquear os erros de entrega do recorte atual |
| **Gatilho** | Clique no link "(N falhas)" do `SendingProgressCard` |
| **Container** | `DialogContent sm:max-w-3xl max-h-[80vh]`; corpo `DialogBody overflow-y-auto max-h-[60vh]` |
| **Título** | `AlertCircle h-5 w-5` + **"Motivos de Falha — {periodLabel}"** |
| **Descrição** | "Top erros de entrega no período, com os filtros atuais da tela" |

`periodLabel` é calculado na página (`ActionsPage.tsx:267-272`): **"Hoje"** quando o recorte é hoje; `dd/MM/yyyy` quando é um único dia; `dd/MM/yyyy a dd/MM/yyyy` no intervalo. A conversão é feita por manipulação de string (`split("-").reverse().join("/")`) para evitar off-by-one de UTC.

Tabela:

| Coluna | Largura/alinhamento | Conteúdo |
|---|---|---|
| **Motivo** | `w-[70%]`, esquerda | Badge `outline` com a posição `#1`, `#2`… (borda `destructive` quando a participação > 30 %; `warning` quando > 15 %) + o texto do erro (`text-sm break-all whitespace-pre-wrap`) |
| **Qtd** | direita, `tabular-nums align-top` | `count.toLocaleString("pt-BR")` |
| **%** | direita, `tabular-nums font-medium align-top` | `percentage.toFixed(1)%` |

Ordenação: DESC por contagem (feita no hook). Sem paginação e sem limite explícito no front.

Estados:
- Carregando: 5 linhas de `Skeleton` (larguras 40/16/12).
- Vazio: `CheckCircle2 h-12 w-12 opacity-50` + "Nenhuma falha registrada no período com os filtros atuais".

Recorte da consulta (`useActionFailureReasons`): mesmos filtros da tela (período, campanha, tipo, status, D+, origem); status considerados = interseção entre o filtro de status e `FAILURE_STATUSES` (interseção vazia → lista vazia); predicado de data = `COALESCE(processing_started_at, created_at)` dentro de `[start, end+1d)`; exclusão de ações de teste quando não há campanha selecionada. A consulta só roda com o modal aberto (`enabled`).

### 7.3 `PauseSendingModal` — Controle de Envios

| Item | Valor |
|---|---|
| **Objetivo** | Freio de emergência: pausar todos os envios ou canais específicos, sem desligar campanhas |
| **Gatilho** | Botão "Pausar Envios / N canal(is) pausado(s) / Envios Pausados" do cabeçalho (`actions:write`) |
| **Container** | `DialogContent sm:max-w-md` |
| **Título** | `PauseCircle h-5 w-5` + **"Controle de Envios"** |

Corpo:

| Bloco | Controle | Detalhes |
|---|---|---|
| Global | `Switch` | Caixa `rounded-lg border p-3 bg-destructive/5` com `PauseCircle h-4 w-4 text-destructive` e label **"Pausar TODOS os envios"** (`font-semibold`). Canal `all` |
| `Separator` | — | — |
| Por canal | 5 `Switch` | Título da seção: **"Por Canal"** (`text-xs text-muted-foreground uppercase tracking-wider`). Itens, nesta ordem: **WhatsApp** (`MessageCircle`), **E-mail** (`Mail`), **SMS** (`MessageSquare`), **Voz** (`Phone`), **Webhook** (`Webhook`). Todos **desabilitados** enquanto o global está ligado |
| `Separator` | — | — |
| Motivo | `Textarea` `rows={2}`, `id="pause-reason"` | Label **"Motivo (opcional)"**; placeholder "Ex: Problema de conteúdo vazio detectado". Inicializado com o `reason` do controle `all` |

Rodapé (`DialogFooter`): **"Cancelar"** (`outline`, fecha sem salvar) e **"Salvar"** (default; mostra `Loader2 animate-spin` e fica desabilitado enquanto `isUpdating`).

Comportamento de salvamento (`PauseSendingModal.tsx:48-56`): percorre o estado local e chama `updateControl` **apenas para os canais cujo valor mudou**; fecha o modal imediatamente (não espera as mutações). A mutação grava `is_paused`, `paused_at` (agora ou `null`), `reason` e `updated_at` na tabela `sending_controls` da org, e invalida `["sending-controls", orgSlug]`.

Estados: carregando → `Loader2 h-6 w-6 animate-spin` centralizado (`py-8`), com o rodapé ainda visível. Erro de atualização → toast "Erro ao atualizar controle de envio" + mensagem (`destructive`).

Observações para o redesign:
- Não há confirmação para uma ação de alto impacto (pausar TODOS os envios da organização).
- Não há indicação de **quem** pausou nem **quando** (`paused_by`/`paused_at` existem no tipo mas não são exibidos).
- Os canais são uma lista hardcoded de 5 — **não inclui RCS**, negativação nem notificação, embora esses tipos existam. ⚠️ (§12, D-05)

### 7.4 `ReportExportDialog` — Exportar relatório de Ações

| Item | Valor |
|---|---|
| **Objetivo** | Confirmar o recorte, o formato e o nível de proteção antes de gerar um documento com dados pessoais |
| **Gatilho** | Botão "Exportar" do cabeçalho de `/actions` |
| **Container** | `DialogContent max-h-[calc(100vh-2rem)] overflow-y-auto p-0 sm:max-w-xl` |

**Cabeçalho** (`border-b bg-gradient-to-br from-primary/10 via-background to-background px-6 py-5`): quadro `h-10 w-10 rounded-xl bg-primary` com `FileText h-5 w-5`; título **"Exportar relatório de Ações"**; descrição "Configure o formato e o nível de proteção dos dados antes de gerar o documento."

**Corpo** (`space-y-5 px-6 py-5`):

1. **Bloco de população** (`rounded-xl border bg-muted/25 p-3`): linha em `font-medium` com `"{N} registro(s) no recorte."` (ou "O histórico completo do cliente será exportado." quando `recordCount == null`), e abaixo, em `text-xs text-muted-foreground`, o `populationNote`.
2. **Fieldset "Formato"** — `RadioGroup` em `grid grid-cols-2 gap-3`; cada opção é um `Label` clicável `rounded-xl border p-3`, com anel `border-primary bg-primary/5 ring-1 ring-primary/20` quando selecionada:
   | Opção | id | Ícone | Título | Sublinha |
   |---|---|---|---|---|
   | **PDF** (default) | `report-format-pdf` | `Printer` | PDF | "Pronto para imprimir" |
   | **HTML** | `report-format-html` | `FileText` | HTML | "Navegável e imprimível" |
3. **Fieldset "Proteção dos dados"** — `RadioGroup` vertical:
   | Opção | id | Ícone | Título | Sublinha | Destaque |
   |---|---|---|---|---|---|
   | **Dados protegidos** (default) | `report-privacy-masked` | `ShieldCheck` (esmeralda) | "Dados protegidos" + pílula **"Recomendado"** | "Documento e destino aparecem parcialmente ocultos." | `border-emerald-500/60 bg-emerald-500/5` |
   | **Dados completos** | `report-privacy-full` | `Eye` (âmbar) | "Dados completos" | "Exibe documento e destinatário sem censura. Use apenas quando necessário." | `border-amber-500/60 bg-amber-500/5` |
4. **Aviso de dados completos** (só quando `privacy === "full"`): caixa âmbar com `LockKeyhole`, texto "Este arquivo conterá dados pessoais completos. A escolha será registrada na auditoria." e um `Checkbox` obrigatório (`report-full-ack`) com o rótulo **"Confirmo que preciso dos dados completos para esta finalidade."**
5. **Estado bloqueado**: quando há `blockedReason`, todo o conteúdo acima é substituído por uma caixa `border-destructive/30 bg-destructive/5 text-destructive` com o motivo, e o botão de gerar **não é renderizado**.

**Rodapé** (`sticky bottom-0 border-t bg-background/95 backdrop-blur-sm`): **"Cancelar"** (`ghost`, desabilitado enquanto pendente) e **"Gerar PDF"** / **"Gerar HTML"** (label dinâmico `Gerar {format.toUpperCase()}`, ícone `Printer` ou `Loader2 animate-spin`), habilitado apenas quando `!blockedReason && !isPending && (privacidade ≠ completa || reconhecimento marcado)`.

**Reset**: ao fechar, `privacy` volta a `masked` e o reconhecimento é desmarcado. O **formato escolhido não é resetado** (persiste na sessão do componente).

### 7.5 Popovers (não são modais, mas são painéis do domínio)

| Painel | Gatilho | Conteúdo |
|---|---|---|
| Detalhe do KPI | Clique no card de KPI | `PopoverContent w-80 p-0`, `align="start"`, `sideOffset 8`; título do KPI + `ActionStatusBreakdown` (§4.5) |
| Ajuda do KPI (`HelpTip`) | Clique no `HelpCircle` ao lado do título | `PopoverContent w-80 max-w-[90vw]`, título em `text-sm font-semibold` + corpo `text-xs text-muted-foreground`; `side="bottom"` nos KPIs |
| Ajuda do cartão de progresso | Clique no `HelpCircle` ao lado dos contadores | Texto com 2 parágrafos, variável conforme "hoje" ou período (texto literal em §8.4) |
| Ajuda das seções do relatório | `HelpTip` ao lado de cada título de card | Textos de `SECTION_TOOLTIPS` (§5.18) |
| Multiselect de Status | Clique no trigger | `Command` com busca, "Selecionar todos"/"Limpar seleção" e checkboxes (§4.6.2) |
| Calendários | Clique nos botões de data | `PopoverContent w-auto p-0`, `align="start"`, `Calendar mode="single"` |

---

## 8. Cartão de Progresso de Envio (`SendingProgressCard`)

Arquivo: `src/components/actions/SendingProgressCard.tsx`. Dados: `useScheduledProgress`.

### 8.1 Identidade e posição

`Card` renderizado logo abaixo da barra de filtros, dentro de `RefreshableSection`. `CardTitle` = **"Status de Envio"** (`text-lg`). Quando o período é hoje **e** há fila ativa, aparece um ponto azul pulsante ao lado do título (`animate-ping` + ponto sólido `bg-blue-500`, ambos `h-2 w-2`).

### 8.2 Selo de situação (canto superior direito)

Badge `outline`. A precedência das condições é a ordem abaixo:

| # | Condição | Texto | Ícone | Cores |
|---|---|---|---|---|
| 1 | `isBlocked` (feriado/data bloqueada) | **Pausado (feriado)** | `CalendarIcon h-3 w-3 mr-1` | `bg-amber-50 text-amber-700 border-amber-200` (dark: `bg-amber-950 text-amber-300 border-amber-800`) |
| 2 | `progress.total === 0` | **Sem envios ativos** | `Clock` | `bg-muted text-muted-foreground border-border` |
| 3 | `scheduled > 0 && sent === 0` | **Aguardando envio** | `Clock` | `bg-muted …` |
| 4 | `scheduled > 0` | **Enviando...** | `Loader2 animate-spin` | `bg-blue-50 text-blue-700 border-blue-200` (dark equivalente) |
| 5 | caso contrário | **Concluído** | `CheckCircle2` | `bg-green-50 text-green-700 border-green-200` (dark equivalente) |

> Nota técnica: a classe de cor é escolhida por uma cadeia separada que testa `isBlocked → !progress.isActive → scheduled>0 && sent===0 → scheduled>0 → verde`. Ou seja, com `total === 0` o texto é "Sem envios ativos" e a cor é a neutra (`!isActive`).

Aviso de feriado (abaixo do título, quando `isBlocked`): caixa `bg-amber-50 border-amber-200` com `AlertCircle h-3.5 w-3.5` e o texto "Envios pausados hoje por feriado: **{nome do feriado}**".

### 8.3 Linha de contadores (`CardDescription`, `flex items-center gap-1 flex-wrap`)

| Elemento | Condição | Texto/formato | Estilo |
|---|---|---|---|
| Base | sempre | `"{sent} de {total} enviadas"` (ambos `toLocaleString("pt-BR")`) — ou **"Carregando dados..."** quando `isLoading && total === 0` | herdado |
| Em atendimento | `inService > 0` | `"({N} em atend.)"` | `text-purple-600 dark:text-purple-400` |
| Falhas | `failed > 0` | `"({N} falhas)"` | `<button>` `text-destructive underline underline-offset-2 hover:text-destructive/80 cursor-pointer` → abre o modal de Motivos de Falha |
| Canceladas | `cancelled > 0` | `"({N} canceladas)"` | `text-muted-foreground` |
| Período | período com mais de um dia | `"• Progresso de {dd/MM} a {dd/MM}"` | `text-muted-foreground` |
| Aviso de busca | há termo de busca | `"• Busca por texto não se aplica a este card"` | `text-muted-foreground` |
| Ajuda | sempre | `HelpTip` (`ml-1`) | — |

### 8.4 Texto de ajuda (literal)

Título: "Status de Envio". Corpo (2 parágrafos):

- Parágrafo 1, quando o período é **hoje**: "Agendadas + enviadas + falhas + canceladas. Olhando HOJE, as agendadas incluem o backlog pendente de dias anteriores (a fila real de trabalho), por isso podem ser maiores que o total do dia."
- Parágrafo 1, nos demais períodos: "Total de ações processadas no período selecionado. Enviadas = mensagens de fato enviadas."
- Parágrafo 2 (sempre): "Respeita todos os filtros da barra (campanha, tipo, status, D+, origem e período) — exceto a busca por texto, que vale apenas para a lista de ações."

### 8.5 Barra de progresso geral

Cabeçalho da barra: à esquerda "Progresso geral" (`text-muted-foreground`), à direita `"{percentage.toFixed(1)}%"` (`font-medium`).

`ProgressMulti` (`src/components/ui/progress.tsx:74`): trilha `h-2 w-full rounded-full bg-secondary`; segmentos posicionados em sequência (cada um começa na soma dos anteriores); segmentos com 0 % são omitidos; com `showLabels`, cada segmento tem tooltip `"{label} {percentage.toFixed(1)}%"`.

| Segmento | Label do tooltip | Cor |
|---|---|---|
| Enviados | "Enviados" | `bg-primary` |
| Em atendimento | "Em Atend." | `bg-purple-500` |
| Falhas | "Falhas" | `bg-destructive` |
| Cancelados | "Cancelados" | `bg-amber-500` |

Os pendentes **não têm segmento** — são o espaço vazio da trilha.

### 8.6 Detalhe por tipo de ação

Renderizado **apenas quando `byType.length > 1`**. Uma entrada por tipo normalizado (`send_x` → `x`), ordenada por total DESC:

- Linha: ícone do tipo (`TYPE_ICONS`, `h-3.5 w-3.5 text-muted-foreground`) + rótulo (`TYPE_LABELS`) + badge `"{X}% falha"` (`text-[10px] px-1 py-0 border-destructive text-destructive`) **quando `failedPercentage > 10`**; à direita, `"{sent} de {total} — {percentage}%"` (`text-xs tabular-nums`).
- Mini-barra `ProgressMulti` com os mesmos 4 segmentos, afinada para 1,5 px (`[&_div.relative.h-2]:h-1.5`).

### 8.7 Horários (só em visão de um único dia)

`flex justify-between text-sm`:
- Esquerda: rótulo "Primeira/Última hora de envio" (`text-xs text-muted-foreground`) e valor `"HH:mm / HH:mm"` (ou `--:-- / --:--`).
- Direita (alinhada à direita): rótulo "Horário estimado de término" e valor: se `scheduled === 0 && lastSent` → hora do último envio; senão a estimativa; senão `--:--`.

Estimativa (`SendingProgressCard.tsx:55-66`): exige `scheduled > 0`, `firstSent`, `lastSent` e `sent >= 2`. Calcula `rate = sent / (lastSent - firstSent)` e projeta `agora + scheduled / rate`.

### 8.8 Semântica dos números (o que o hook entrega)

| Campo | Definição |
|---|---|
| `total` | `scheduled + sent + inService + failed + cancelled` |
| `sent` | Status em `SENT_STATUSES` **+ qualquer status desconhecido** (fallback `else entry.sent += cnt`) |
| `scheduled` | Pendentes. **Em "hoje"**: backlog sem recorte de data (fila real, inclui pendências de dias anteriores). **Em outros períodos**: pendentes criados no período |
| `inService` | Apenas `Em Atendimento` (testado antes de failed/cancelled) |
| `failed` | `FAILURE_STATUSES` |
| `cancelled` | `CANCELLED_STATUSES` menos `Em Atendimento` (já capturado) |
| `percentage` | `processed / total × 100`, onde `processed = sent + inService + failed + cancelled` |
| `isActive` | `scheduled > 0` |
| `firstSent` / `lastSent` | Só em visão de um dia; consultas `actions.sent_at` ASC/DESC limitadas a 1, excluindo `metadata.is_test = true` |

Filtro de status × backlog (`resolveBacklogStatuses`): sem filtro → todos os pendentes; com filtro → interseção com `PENDING_STATUSES` (resolvendo aliases); interseção vazia → sem backlog. Se a consulta de backlog falhar, mantém o pendente do período (**falha nunca vira "0 pendentes"**).

### 8.9 Controles de pausa/retomada

O cartão **não tem** controles de pausa. A pausa/retomada vive exclusivamente no botão do cabeçalho da página + `PauseSendingModal` (§7.3). A "retomada" é o mesmo `Switch` desligado — não há botão "Retomar" com rótulo próprio.

### 8.10 Estados do cartão

| Estado | Render |
|---|---|
| Carregando com `total === 0` | Descrição "Carregando dados..." + bloco central com `Loader2 h-8 w-8 animate-spin opacity-30` e "Carregando ações..." |
| Vazio (`!isLoading && total === 0`) | `Clock h-8 w-8 opacity-30` + "Nenhuma ação no período selecionado" |
| Atualizando | O `RefreshableSection` pai esmaece (`opacity-60`) e bloqueia interação |
| Modo identidade | O cartão **não é renderizado** (substituído pelo Alert — §4.6.4) |

---

## 9. Estados das telas

### 9.1 `/actions`

| Estado | Gatilho | Render |
|---|---|---|
| **Sem organização** | `!currentOrg` | Tela inteira substituída: `Activity h-12 w-12 text-muted-foreground` + `h2` "Nenhuma organização selecionada" (`text-xl font-semibold`), centralizado vertical e horizontalmente |
| **Primeiro carregamento** | `isLoading` da lista | Spinner dentro do card da tabela; KPIs mostram `"..."`; cartão de progresso mostra "Carregando dados..." |
| **Atualizando (com dados)** | `isRefreshing` | `RefreshTopBar` no topo + `RefreshableSection` esmaecendo o progresso + `RefreshButton` girando; **os dados anteriores continuam na tela** (`placeholderData`) |
| **Erro nos KPIs** | `statsError` | Os 4 cards são substituídos por `<Alert variant="destructive">` com `statsError.message`. Mensagem típica do hook: "Não foi possível consultar os indicadores: {msg}" |
| **Erro na lista** | `actionsError` | `<Alert variant="destructive">` com "Não foi possível consultar as ações: {msg}", **acima** da tabela (a tabela continua renderizando o que houver) |
| **Erro na identificação do cliente** | RPC `resolve_contacts_by_identity` falha | Propagado como erro da lista: "Não foi possível identificar o cliente: {msg}" |
| **Busca sem resultado** | `actions.length === 0` | Estado vazio da tabela: "Nenhuma ação encontrada" + "Tente ajustar os filtros ou selecionar outro período" |
| **Hoje sem ações** | `total === 0` + período = hoje + sem erros + sem identidade | Faixa pontilhada + botão "Ver ontem" (§4.8) |
| **Sem permissão de escrita** | `!hasPermission("actions:write")` | O botão Pausar não é renderizado. ⚠️ O cancelamento por linha **continua disponível** |
| **Sem permissão de exportação** | `!hasPermission("reports:export")` | O botão Exportar não é renderizado |
| **Pop-up bloqueado na exportação** | `window.open` devolve `null` | Toast destrutivo "Permita pop-ups para abrir o relatório" |

### 9.2 `/actions/report`

| Estado | Render |
|---|---|
| **Sem organização** | `Activity h-12 w-12` + "Nenhuma organização selecionada" |
| **Carregando** | Tela cheia centralizada: `Loader2 h-12 w-12 animate-spin text-primary`, `h2` **"Gerando Relatório com IA..."** e "Analisando dados e gerando insights inteligentes" |
| **Erro** | Tela cheia: `XCircle h-12 w-12 text-destructive`, `h2` "Erro ao gerar relatório", a mensagem, e botão **"Tentar novamente"** (`RefreshCw h-4 w-4 mr-2`) que reinvalida a query |
| **Relatório vazio** (`!report`) | Retorna `null` — **tela completamente em branco** ⚠️ (§12, D-08) |
| **Gráfico quebrado** | `ChartErrorBoundary` envolve a página inteira: exibe, no lugar de todo o conteúdo, um bloco `h-64` centralizado com "Gráfico indisponível — os dados estão disponíveis nas tabelas abaixo." ⚠️ (o boundary é da página, não do gráfico — a frase promete tabelas que não aparecem) |
| **Atualizando** | `RefreshButton` com label "Atualizar" girando; o conteúdo permanece |
| **Seções ausentes** | Blocos 5-8, 10 e 11 e os gráficos 4.5/4.6 simplesmente não são renderizados quando não há dados |
| **Impressão** | `print:hidden` no cabeçalho; bloco `hidden print:block` com org/período/geração; rodapé com `print:py-2` |

### 9.3 `/actions/payment-analysis`

Nenhum estado. Sempre renderiza o mesmo conteúdo estático.

---

## 10. Fluxos de uso passo a passo

### Fluxo 1 — Acompanhar a leva do dia (uso mais comum)

1. Menu lateral → **Ações** (`Zap`). A tela abre já filtrada para **hoje**.
2. Ler o selo do cartão "Status de Envio": Aguardando envio / Enviando... / Concluído / Pausado (feriado) / Sem envios ativos.
3. Ler a linha de contadores: "X de Y enviadas", "(N em atend.)", "(N falhas)", "(N canceladas)".
4. Conferir a barra segmentada e, se houver mais de um canal, as mini-barras por tipo — badge "N% falha" aponta o canal problemático.
5. Ler os 4 KPIs; clicar em um deles abre a quebra por status.
6. Se a leva ainda está saindo, o cartão se atualiza sozinho a cada 30 s; para forçar, clicar em Atualizar.

### Fluxo 2 — Investigar falhas

1. No cartão de progresso, clicar no link vermelho **"(N falhas)"**.
2. O modal "Motivos de Falha — {período}" abre, com os motivos ranqueados (#1, #2…), quantidade e percentual.
3. Identificar o motivo dominante (badge vermelho quando > 30 % das falhas).
4. Fechar o modal e, na barra de filtros, marcar os status **"Falha Temporária de Ação"** e/ou **"Falha Definitiva de Ação"** para ver as ações correspondentes na tabela.
5. Clicar em uma linha → o modal de detalhe traz o bloco "Motivo registrado" e, em Detalhes Técnicos, o payload e a resposta do provedor.

### Fluxo 3 — Encontrar tudo de um cliente

1. Colar no campo de busca o CPF/CNPJ (com ou sem pontuação), o telefone (com ou sem DDI/máscara), o e-mail ou o número do contrato.
2. Após ~300 ms, a tela entra em **modo identidade**: aparece a faixa "Histórico completo de **{cliente}** — o período não se aplica", o cartão de progresso é substituído por um aviso, e a lista + os KPIs passam a mostrar o histórico completo.
3. Se o contato é compartilhado por vários clientes, a faixa informa "e mais N cliente(s) com esse contato".
4. Os demais filtros (tipo, status, origem, campanha, D+) continuam valendo; só a janela de datas sai.
5. Para voltar ao acompanhamento da fila, clicar em **"Voltar ao período"**.

### Fluxo 4 — Cancelar uma ação antes do envio

Pela tabela:
1. Localizar a linha com status **Pendente** (ou Processando).
2. Clicar no `X` vermelho da última coluna.
3. Confirmar em **"Confirmar"** (ou desistir em "Nao").
4. Toast "Ação cancelada"; a lista é invalidada e recarrega.

Pelo modal:
1. Abrir o detalhe da ação.
2. Rolar até o rodapé e clicar em **"Cancelar Ação"**.
3. Ler "Ação será cancelada e não será enviada" e clicar em **"Confirmar"** (ou "Voltar").
4. O modal fecha.

### Fluxo 5 — Pausar um canal em emergência

1. No cabeçalho, clicar em **"Pausar Envios"** (visível só com `actions:write` e quando há envio ativo ou canal já pausado).
2. No modal "Controle de Envios", ligar o `Switch` do canal problemático (ou o global "Pausar TODOS os envios").
3. Opcionalmente escrever o **Motivo**.
4. Clicar em **"Salvar"**. O modal fecha e o botão do cabeçalho passa a exibir "N canal(is) pausado(s)" em vermelho (ou "Envios Pausados").
5. Para retomar, reabrir o modal, desligar o `Switch` e salvar.

### Fluxo 6 — Exportar o recorte atual

1. Ajustar filtros até o recorte desejado (conferir o "{N} ações encontradas" no card da tabela).
2. Clicar em **"Exportar"** (`reports:export`).
3. Conferir a contagem no diálogo e a nota de população.
4. Escolher **PDF** (default) ou **HTML**.
5. Escolher **Dados protegidos** (default) ou **Dados completos** — neste caso, marcar a confirmação obrigatória.
6. Clicar em **"Gerar PDF"** / **"Gerar HTML"**. O documento abre em nova aba (permitir pop-ups).

### Fluxo 7 — Aprofundar no relatório com IA

1. Em `/actions`, com o recorte definido, clicar em **"Gerar Relatório com IA"**.
2. A navegação leva a `/actions/report?startDate=…&endDate=…&campaignId=…&actionType=…&status=…` (busca, origem e D+ **não** são levados).
3. Aguardar "Gerando Relatório com IA..." (10 min de cache por recorte).
4. Ler o bloco de Insights, conferir os 6 KPIs e a faixa de duplicatas.
5. Percorrer os gráficos; usar os `?` de cada seção para entender a métrica.
6. **"Exportar PDF"** dispara `window.print()` — escolher "Salvar como PDF" no navegador.
7. **"← Voltar"** retorna a `/actions` (o estado de filtros da tela anterior volta pela URL).

---

## 11. Responsividade e acessibilidade

### 11.1 Breakpoints e comportamento responsivo

| Elemento | Mobile (< 640 px) | `sm` (≥ 640) | `md` (≥ 768) | `lg` (≥ 1024) | `xl` (≥ 1280) |
|---|---|---|---|---|---|
| `h1` de `/actions` | `text-xl` | `text-2xl` | — | — | — |
| Subtítulo de `/actions` | **oculto** | visível | — | — | — |
| Botões do cabeçalho | icon-only (`size="icon"`) | `sm:w-auto sm:px-4` + label | — | — | — |
| Grid de filtros | 1 coluna | 2 colunas | — | 3 colunas | 4 colunas |
| Célula de datas | 1 coluna | ocupa 2 colunas (`sm:col-span-2`) | — | — | — |
| KPIs de `/actions` | 1 coluna | — | 2 colunas | 4 colunas | — |
| KPIs do relatório | 1 coluna | — | 2 colunas | 3 colunas | 6 colunas |
| Grade de gráficos do relatório | 1 coluna | — | — | 2 colunas | — |
| Insights da IA | 1 coluna | — | 3 colunas | — | — |
| KPIs de payment-analysis | 2 colunas | — | 3 colunas | 6 colunas | — |

**Lacuna conhecida**: a `ActionsTable` tem 9 colunas e **não tem wrapper de scroll horizontal nem versão em cartões**. Em telas estreitas as colunas são espremidas/estouradas. O `Table` do shadcn usa `overflow-auto` no wrapper padrão, mas não há tratamento específico (ex.: ocultar colunas por breakpoint). ⚠️ Ver §12, D-09.

O modal de detalhe usa `grid-cols-2` **fixo** (sem variante mobile) no bloco de detalhes.

### 11.2 Acessibilidade — o que já existe

- `RefreshButton`: `aria-label`, `title`, `aria-busy`, `disabled` durante a operação.
- `RefreshTopBar`: `role="progressbar"`, `aria-busy`, `aria-label="Atualizar"`.
- `RefreshableSection`: `aria-busy`.
- Campo de busca: `aria-label="Buscar cliente"`, `maxLength={200}`.
- `FilterMultiSelect`: `role="combobox"`, `aria-expanded`, `aria-label` com o nome do filtro; o `X` de cada badge tem `role="button"`, `tabIndex={0}` e responde a Enter/Espaço; `aria-label="Remover {label}"`.
- `HelpTip`: `<button type="button">` com `aria-label="Ajuda: {título}"`; variante popover é **clicável** (funciona no mobile) e o texto nunca trunca.
- `Dialog`/`Popover`/`Select` do shadcn/Radix: foco preso, ESC para fechar, `aria-*` gerenciado pela biblioteca.
- Modal de pausa: `Label htmlFor="pause-reason"` ligado ao `Textarea`.
- Diálogo de exportação: `fieldset`/`legend` nos dois grupos de opção; `Label htmlFor` em cada rádio e no checkbox.
- Barra do `ProgressMulti`: cada segmento tem tooltip com o rótulo e o percentual (a cor não é o único portador da informação — no hover).

### 11.3 Acessibilidade — lacunas identificadas

| Lacuna | Onde |
|---|---|
| Linha de tabela clicável sem `role="button"`/`tabIndex`/handler de teclado | `ActionsTable.tsx:111` — o detalhe só abre por mouse na linha (há o botão `Eye` como alternativa acessível) |
| Botão `Eye` sem `aria-label`/`title` | `ActionsTable.tsx:195-204` |
| Coluna 9 da tabela com cabeçalho vazio | `ActionsTable.tsx:94` — sem `sr-only` descrevendo "Ações" |
| Link "(N falhas)" é `<button>` sem `aria-label` explicando que abre um detalhamento | `SendingProgressCard.tsx:135-141` |
| Informação transmitida só por cor nas mini-barras e na barra de canais do relatório (sem hover) | `SendingProgressCard`, `ActionsReportPage` bloco 4.3 |
| Gráficos Chart.js/Recharts sem alternativa textual/tabela equivalente | `/actions/report`, `/actions/payment-analysis` |
| Emojis com carga semântica dentro de texto (🎯, 📊, ✅, 📊, 💡) sem rótulo acessível | `/actions/report` (insights de horário), `/actions/payment-analysis` |
| Contraste dos badges pastel (`bg-*-100 text-*-800`) não verificado | Todos os badges de tipo e status |
| Tema escuro parcial | Só o `SendingProgressCard` declara variantes `dark:`; o restante (badges de status/tipo, faixas verdes/vermelhas do relatório, caixas de insight) usa cores claras fixas ⚠️ |

---

## 12. Dores e oportunidades para o redesign

### 12.1 Divergências e inconsistências (D)

| ID | Problema | Evidência |
|---|---|---|
| **D-01** | Mesmo canal com rótulos diferentes entre telas: "Voz" (Ações) vs "Ligação" (Carteira); "Notificação" vs "Notificação extrajudicial"; "E-mail" vs "Email" (tabela de steps do relatório) | `useActions.ts:138-147`, `action-type-filter.ts:35-47`, `ActionsReportPage.tsx:1126` |
| **D-02** | O ícone do domínio muda de lugar para lugar: `Zap` no menu, `Activity` no título e no estado vazio, `Sparkles` no relatório | `Sidebar.tsx:41`, `ActionsPage.tsx:290`, `ActionsReportPage.tsx:217` |
| **D-03** | "Cancelado" e "Ignorado" significam coisas diferentes em cada bloco: no cartão de progresso, `Em Atendimento` é bucket próprio; nos KPIs conta como **enviado**; no relatório aparece como "Ignorado"; e a faixa âmbar "Cancelado" do relatório usa o campo `pending` | §2.3; `ActionsReportPage.tsx:481-503`; `useActions.ts:885-889` |
| **D-04** | Filtro D+ com formato inválido é **ignorado em silêncio** — não há mensagem, borda de erro nem contagem "filtro não aplicado" | `parseDaysRange` retorna `null` e o filtro some |
| **D-05** | O modal de pausa cobre 5 canais (WhatsApp, E-mail, SMS, Voz, Webhook) mas o produto tem 8 tipos — **RCS**, Negativação e Notificação não são pausáveis pela UI | `PauseSendingModal.tsx:97` |
| **D-06** | Cancelamento de ação (linha e modal) **não verifica `actions:write`**; um `viewer` que chegue à tela consegue cancelar (o RLS do banco é a única barreira) | `ActionsTable.tsx:205-246`, `ActionDetailDialog.tsx:271-300` |
| **D-07** | Cancelar ação em **Processando** é oferecido com a mesma leveza de cancelar Pendente, apesar de poder gravar "Cancelado" numa mensagem já entregue (prioridade 10 vence Enviado) | `acoes-status.ts` callout "A prioridade 10 do Cancelado…" |
| **D-08** | Relatório com `report` indefinido renderiza **nada** (tela branca), sem estado vazio | `ActionsReportPage.tsx:202-204` |
| **D-09** | Tabela de 9 colunas sem estratégia responsiva (nem scroll dedicado, nem colunas colapsáveis, nem cartões no mobile) | `ActionsTable.tsx:83-253` |
| **D-10** | Datas na tabela sem ano (`dd/MM HH:mm`) — ambíguo em qualquer recorte que cruze o ano, e a tela permite período livre | `ActionsTable.tsx:176-191` |
| **D-11** | Rótulo com erro de digitação: botão **"Nao"** na confirmação inline de cancelamento | `ActionsTable.tsx:233` |
| **D-12** | Confirmação inconsistente: cancelar pela tabela emite toast de sucesso/erro; cancelar pelo modal não emite nenhum | `ActionsTable.tsx:217-219` vs `ActionDetailDialog.tsx:286-296` |
| **D-13** | O modal de detalhe lê a ação do **array da página atual**; qualquer mudança de página/filtro com o modal aberto pode esvaziá-lo, e os dados não são refetchados (existe `useActionDetail`, mas não é usado aqui) | `ActionDetailDialog.tsx:315` |
| **D-14** | "Gerar Relatório com IA" perde 3 filtros sem avisar (busca, origem, D+) — o usuário acredita estar vendo o mesmo recorte | `ActionsPage.tsx:136-144` |
| **D-15** | A semente de `standard_values.action_status` ainda contém `Entregue` e `Lido` (removidos) e não contém `Interagiu` nem `Duplicado`; o filtro de Status pode exibir status inexistentes | `useStandardValues.ts:79-91` vs `ACTION_STATUSES` |
| **D-16** | Duas bibliotecas de gráfico no mesmo domínio: Chart.js (`/actions/report`) e Recharts (`/actions/payment-analysis`) | imports dos dois arquivos |
| **D-17** | `/actions/payment-analysis` é uma tela **inteiramente mockada**, exposta em rota pública do app, com números internamente contraditórios e um badge "Últimos 30 dias" falso | §6.2 |
| **D-18** | Tema escuro incompleto no domínio (só o cartão de progresso declara variantes `dark:`) | §11.3 |
| **D-19** | Comentário do "Limpar todos" contradiz o comportamento (diz preservar a busca; o código a limpa) | `ActionsFiltersBar.tsx:307-318` |
| **D-20** | Coluna "Origem": qualquer valor desconhecido cai no badge "Campanha" (fallback silencioso) — inclusive `null` | `ActionsTable.tsx:129-137` |

### 12.2 Oportunidades para o redesign (O)

| ID | Oportunidade |
|---|---|
| **O-01** | **Seleção múltipla + ações em massa na tabela** (cancelar N ações selecionadas, exportar seleção). Hoje é uma ação por clique, e o cancelamento em massa está escondido em outra tela |
| **O-02** | **Ordenação por coluna** (ao menos Criado em, Processado em, D+, Status) e **tamanho de página configurável** |
| **O-03** | **Chips de filtro ativo** acima da tabela, com X individual. Hoje o único resumo do recorte é o próprio conjunto de controles + o "Limpar todos" |
| **O-04** | **Expor a explicação estruturada de status** (`ACTION_STATUS_DISPLAY[...].explanation`, já escrita para os 12 status com O que é / Origem / Quando / Observação) num popover no badge de status — hoje essa copy de alta qualidade não aparece em nenhuma das 3 telas |
| **O-05** | **Unificar o vocabulário de agrupamento** numa única legenda visível (enviados / interação / falha / cancelado / em atendimento), usada igual no cartão de progresso, nos KPIs e no relatório |
| **O-06** | **Validação visível do campo D+** (máscara, hint de formato, erro inline) |
| **O-07** | **Um lugar único para "o que está pausado"**: hoje a informação só existe no rótulo do botão; um banner persistente com canal, motivo, quem pausou e desde quando resolveria (os campos `paused_by`/`paused_at`/`reason` já existem) |
| **O-08** | **Estado vazio acionável no relatório** e error boundary por gráfico (em vez de por página), cumprindo a promessa "os dados estão disponíveis nas tabelas abaixo" |
| **O-09** | **Reaproveitar o modo identidade como "ficha do cliente"**: hoje ele já muda o recorte da lista e dos KPIs; falta um cabeçalho com nome/documento/contratos e atalho direto para a Gestão de Carteira |
| **O-10** | **Densidade da tabela**: com 9 colunas e 2 linhas de texto em 3 delas, o scan visual é lento. Vale avaliar linha compacta + coluna "Contato" como âncora + colunas secundárias em expansão |
| **O-11** | **Filtros do relatório na própria tela** (`/actions/report` hoje só lê query string; qualquer ajuste exige voltar) |
| **O-12** | **Decidir o destino de `/actions/payment-analysis`**: ligar a dados reais (é uma análise de atribuição valiosa) ou remover a rota |
| **O-13** | **Consolidar as duas bibliotecas de gráfico** numa só |
| **O-14** | **Mobile-first para a tabela**: cartão por ação com tipo + contato + status + D+ e expansão para o resto |
| **O-15** | **Marcar visualmente o risco de cancelar em "Processando"** (copy de confirmação diferente da de "Pendente") |

---

## 13. Inventário de modais do domínio

| # | Modal / painel | Componente | Arquivo | Gatilho | Tamanho | Botões do rodapé | Confirmação |
|---|---|---|---|---|---|---|---|
| 1 | **Detalhes da Ação** | `ActionDetailDialog` | `src/components/actions/ActionDetailDialog.tsx` | Clique na linha da tabela ou no botão `Eye` | `max-w-2xl max-h-[90vh]`, `p-0` | Sem `DialogFooter`; ação de cancelar dentro do corpo | Confirmação inline de 2 passos ("Cancelar Ação" → "Voltar"/"Confirmar") |
| 2 | **Motivos de Falha — {período}** | `FailureReasonsDialog` | `src/components/actions/FailureReasonsDialog.tsx` | Link "(N falhas)" no cartão de progresso | `sm:max-w-3xl max-h-[80vh]` | Nenhum (só o X do Dialog) | — |
| 3 | **Controle de Envios** | `PauseSendingModal` | `src/components/actions/PauseSendingModal.tsx` | Botão "Pausar Envios" do cabeçalho (`actions:write`) | `sm:max-w-md` | "Cancelar" (`outline`) · "Salvar" (default, com spinner) | ⚠️ Nenhuma, nem para "Pausar TODOS os envios" |
| 4 | **Exportar relatório de Ações** | `ReportExportDialog` | `src/components/reports/ReportExportDialog.tsx` | Botão "Exportar" do cabeçalho (`reports:export`) | `sm:max-w-xl`, corpo rolável, rodapé sticky | "Cancelar" (`ghost`) · "Gerar PDF"/"Gerar HTML" | Checkbox obrigatório ao escolher "Dados completos"; bloqueio total quando 0 registros ou > 20.000 |
| 5 | *(popover)* Detalhe do KPI | `StatsCard` + `ActionStatusBreakdown` | `src/components/actions/StatsCard.tsx` | Clique no card de KPI | `w-80 p-0` | — | — |
| 6 | *(popover)* Ajuda contextual | `HelpTip` | `src/components/common/HelpTip.tsx` | Clique no `HelpCircle` | `w-80 max-w-[90vw]` | — | — |
| 7 | *(popover)* Seleção de Status | `FilterMultiSelect` | `src/components/portfolio/filters/FilterMultiSelect.tsx` | Clique no trigger de Status | largura do trigger, mín. 240 px | — | — |
| 8 | *(popover)* Calendário inicial/final | `Popover` + `Calendar` | `src/components/actions/ActionsFiltersBar.tsx` | Clique nos botões de data | `w-auto p-0` | — | — |

Modais que **não** existem neste domínio (e que o redesign pode precisar criar): confirmação de cancelamento em massa, confirmação de pausa global, edição/reprocessamento de ação, reenvio manual, visualização de mensagem renderizada (hoje é texto cru).

---

## Apêndice A — Textos literais de interface (para tradução/revisão de copy)

### A.1 `/actions`

| Contexto | Texto |
|---|---|
| Título | Histórico de Ações |
| Subtítulo | Visualize todas as ações executadas pelos workflows |
| Botões do cabeçalho | Pausar Envios · {N} canal(is) pausado(s) · Envios Pausados · Exportar · Gerar Relatório com IA |
| Card de filtros | Filtros |
| Busca (placeholder) | Nome, documento, telefone, contrato ou e-mail |
| Selects | Todos os Tipos · Todos os Status · Todas as Origens · Todas as Campanhas · Data inicial · Data final · Hoje · Limpar todos |
| D+ (placeholder) | D+ (ex: 5-30) |
| Chip de identidade | Histórico completo de **{cliente}** — o período não se aplica. · e mais N cliente(s) com esse contato · Voltar ao período |
| Alerta do modo identidade | O progresso de envio mede a fila do período. A lista e os indicadores abaixo mostram o histórico completo do cliente. Use **Voltar ao período** para voltar à fila. |
| KPIs | Total de Ações · Taxa de Envio · Taxa de Interação · Solicitou Atendimento |
| Descrições dos KPIs | {N} canceladas \| {N} falhas \| {N} pendentes · {N} enviadas · {N} interações · {N} respostas |
| Cartão de progresso | Status de Envio · Progresso geral · Primeira/Última hora de envio · Horário estimado de término · Carregando ações... · Nenhuma ação no período selecionado · Carregando dados... · Busca por texto não se aplica a este card · Progresso de {dd/MM} a {dd/MM} |
| Selos do progresso | Pausado (feriado) · Sem envios ativos · Aguardando envio · Enviando... · Concluído |
| Feriado | Envios pausados hoje por feriado: **{nome}** |
| Tabela | Ações · {N} ações encontradas · Tipo · Contato · Origem · Campanha / Régua · D+ · Status · Processado em · Criado em |
| Badges de origem | Manual · Teste · API · Campanha |
| Vazio da tabela | Nenhuma ação encontrada · Tente ajustar os filtros ou selecionar outro período |
| Faixa de hoje vazio | Nenhuma ação registrada hoje com os filtros atuais. · Ver ontem |
| Confirmação de cancelamento | Confirmar · Nao · Cancelar ação (title) |
| Toasts | Ação cancelada · Erro ao cancelar · Erro ao atualizar controle de envio |
| Erros | Não foi possível consultar as ações: {msg} · Não foi possível consultar os indicadores: {msg} · Não foi possível identificar o cliente: {msg} |
| Sem org | Nenhuma organização selecionada |
| Fallback de erro sem motivo | O sistema não registrou o motivo desta falha. |

### A.2 `/actions/report`

| Contexto | Texto |
|---|---|
| Título | Relatório de Ações com IA |
| Botões | Atualizar · Exportar PDF · Tentar novamente |
| Loading | Gerando Relatório com IA... · Analisando dados e gerando insights inteligentes |
| Erro | Erro ao gerar relatório |
| Insights | Insights Gerados por IA · Análise automatizada baseada nos dados do período · Pontos Positivos · Pontos de Atenção · Recomendações |
| KPIs | Total de Ações · Contatos Únicos · Contratos Acionados · Taxa de Sucesso · Taxa de Resposta · Dívida Acionada |
| Descrições | {N} campanhas · {X} ações/contato · {X} ações/contrato · Ações bem-sucedidas · {N} respostas · Valor total |
| Duplicatas | Sem duplicatas exatas · - Nenhuma ação duplicada (mesmo contato + campanha + step) detectada · Duplicatas detectadas! · - Existem ações duplicadas que precisam ser investigadas |
| Títulos dos blocos | Distribuição por Status · Ações por Campanha · Performance por Canal · Timeline de Execução · Respostas por Horário de Envio · Horários de Maior Engajamento · Distribuição por Faixa de Vencimento · Valor da Dívida por Campanha · Ações por Dia · Distribuição de Frequência por Contrato · Funil de Interação · Desempenho por Step da Régua · Sobreposição de Contatos entre Campanhas · Contatos com Múltiplas Ações · Análise de Erros |
| Descrições de bloco | Horário de Brasília (GMT-3) · Qual horário de envio gera mais respostas? (baseado em hora de processamento) · Em que horários os contatos mais respondem? (baseado em updated_at) · Distribuição diária por canal e falhas · Quantas ações cada contrato recebeu no período · Progressão: Enviado → Interagiu → Solicitou Atendimento · Performance de cada step de cobrança agrupado por workflow · Contatos que receberam mais de uma ação no período |
| Destaques | 🎯 Melhor horário para enviar · Ações enviadas às {hora} geraram {N} respostas ({X} de taxa) · 📊 Pico de engajamento · O maior volume de respostas ocorre às {hora} ({N} respostas) · Max: {N} ações em um único contrato |
| Legendas de canal | Sucesso: {N} · Cancelado: {N} · Respostas: {N} · Falha: {N} · Ignorado: {N} |
| Funil | Enviado · Interagiu · Solicitou Atendimento · ({X}% do anterior) · WhatsApp · E-mail |
| Tabelas | Campanha · Contatos · Total · Média · Workflow · Step · Canal · Enviados · Interagiram · Solicitaram Atend. · Taxa Resp. · Ações · Campanhas · Steps · Status · Mensagem · Quantidade · Sem mensagem de erro |
| Boundary | Gráfico indisponível — os dados estão disponíveis nas tabelas abaixo. |
| Impressão | Relatório de Ações - {org} · Período: … \| Gerado em: … |
| Rodapé | Relatório gerado em {data} às {hora} \| Torre de Controle - {org} |

### A.3 `/actions/payment-analysis`

Ver §6 — todos os textos estão transcritos lá, inclusive os insights.

---

## Apêndice B — Mapa de arquivos-fonte citados

```
src/
├── App.tsx                                       (rotas 415-417)
├── components/
│   ├── actions/
│   │   ├── ActionDetailDialog.tsx                (modal de detalhe + ActionDetailContent + PayloadViewer)
│   │   ├── ActionKPICards.tsx                    (4 KPIs)
│   │   ├── ActionsExportButton.tsx               (botão + bloqueios de exportação)
│   │   ├── ActionsFiltersBar.tsx                 (barra de filtros + chip de identidade)
│   │   ├── ActionsTable.tsx                      (tabela + paginação + cancelamento inline)
│   │   ├── FailureReasonsDialog.tsx              (modal de motivos de falha)
│   │   ├── PauseSendingModal.tsx                 (modal de controle de envios)
│   │   ├── SendingProgressCard.tsx               (cartão Status de Envio)
│   │   └── StatsCard.tsx                         (átomo de KPI com popover)
│   ├── common/
│   │   ├── HelpTip.tsx                           (ajuda "?" — popover/tooltip, explicação estruturada)
│   │   ├── RefreshButton.tsx
│   │   ├── RefreshableSection.tsx
│   │   └── RefreshTopBar.tsx
│   ├── dashboard/charts/ErrorSummaryCard.tsx     (ActionStatusBreakdown + STATUS_CATEGORY/DESCRIPTIONS)
│   ├── portfolio/filters/FilterMultiSelect.tsx   (multiselect de Status, variante "badges")
│   ├── reports/ReportExportDialog.tsx            (diálogo de exportação)
│   ├── layout/Sidebar.tsx                        (item "Ações", permission actions:read)
│   └── ui/progress.tsx                           (ProgressMulti)
├── contexts/OrganizationContext.tsx              (ROLE_PERMISSIONS)
├── hooks/
│   ├── useActionFailureReasons.ts
│   ├── useActions.ts                             (useActions, useFilteredActionStats, ACTION_TYPES, ACTION_STATUS, realtime, refresh)
│   ├── useActionsExport.ts
│   ├── useActionsReport.ts                       (tipos do relatório + formatadores + getStatusColor/getChannelLabel)
│   ├── useIsBlockedToday.ts
│   ├── useManualAction.ts                        (useCancelAction)
│   ├── useScheduledProgress.ts
│   ├── useSendingControls.ts
│   └── useStandardValues.ts
├── lib/
│   ├── action-error.ts                           (getActionErrorMessage)
│   ├── actions-utils.ts                          (looksLikeIdentityTerm, parseDaysRange)
│   ├── customer-search.ts                        (CUSTOMER_SEARCH_PLACEHOLDER)
│   └── constants/
│       ├── action-status-config.ts               (12 status canônicos + helper sets + resolveActionStatus)
│       ├── action-status-display.ts              (rótulos de exibição + explicações estruturadas)
│       ├── action-type-filter.ts                 (catálogo do filtro da Carteira — NÃO usado em /actions)
│       ├── action-type-icons.ts                  (TYPE_ICONS)
│       └── status.ts                             (status de campanha/contrato/título/workflow — contexto, não de ações)
├── pages/
│   ├── ActionsPage.tsx
│   ├── ActionsReportPage.tsx
│   ├── ActionPaymentAnalysis.tsx
│   └── central-docs/
│       ├── negocio/data/acoes.ts                 (guia de negócio da tela Ações)
│       ├── negocio/data/relatorio-acoes.ts       (guia de negócio do relatório)
│       └── topics/data/acoes-status.ts           (tópico: ciclo de vida, status e fila)
supabase/functions/_shared/
└── action-status-labels.ts                       (FONTE ÚNICA dos rótulos de exibição, compartilhada front/servidor)
```
