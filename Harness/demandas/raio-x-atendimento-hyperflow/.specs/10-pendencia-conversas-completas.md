# 10 · Pendência — conversas completas (parte A)

> Estado em 2026-11-19. Janela: `created_at` de 2026-08-20 a 2026-11-18 (America/Sao_Paulo).
> O artefato está publicado com 100% dos protocolos e com as mensagens que existem no BigQuery.
> Falta o texto completo das conversas. Enquanto faltar, o avaliador de qualidade (spec 04) não roda: decisão do João de 2026-11-19, "só com 100% das conversas".

## 1. A pendência, em uma frase

Trazer para `dados/brutos/api/<chat_id>.json` o histórico completo de mensagens (o `getChatMessages` do Hyperflow Desk) dos chats que hoje só têm fonte parcial, reprocessar as métricas (spec 03), rodar o avaliador uma única vez (spec 04) e republicar o artefato.

## 2. O que existe hoje, por fonte

| Fonte | Tenant | O que entrega | Cobertura na janela |
|---|---|---|---|
| `bronze_external_hyperflow.list_all_chats` | os dois | metadados, jornada de filas e atendentes, telefone | 100% dos chats: A 22.416 · B 57.885 |
| `bronze_hyperflow.chat_history` (v2) | só BLIPS | log completo, autor oficial (`sender_kind`) | 19.751 chats de B (34%). Escopo da carga = leads do Pipedrive, cobertura de cobrança é acidental |
| `bronze_external_hyperflow.tb_chat_messages` | só BLIPS | reconstrução por evento (`lastMessage`), ~50% das mensagens | os outros 38.134 chats de B |
| `bigquery___finza.chat_events` | só FINZA | mesma reconstrução, ~50% das mensagens | 22.416 chats de A |
| `silver_torre.org_finza_actions_interaction_logs` (BQ) | FINZA | texto dos turnos da IA; sem horário da mensagem do cliente (`processing_time_ms` zerado) | 3,7 mil protocolos, 58% casam com o desk |
| `org_{finza,blips}.ai_messages` (Supabase da Torre) | os dois | trecho cliente × IA com horário real; texto retido só de meados de out/2026 em diante (~69% das linhas sem texto) | A 5.213 protocolos · BLIPS 8.169 (todas as IAs) |
| `silver_auditoria.helper_messages` | só BLIPS | transcrição de mídia do cliente | 327 de 15.967 áudios de cliente em B |

Mediana de mensagens por conversa: 3 em A, 4 na amostra de B, 11 no histórico completo de B.

## 3. O que falta, exatamente

| Recorte | Chats sem log completo | O que falta em cada um |
|---|---:|---|
| A · FINZA | 22.416 (100%) | cerca de metade das mensagens; autor oficial (humano × bot); todo o conteúdo de áudio, imagem e arquivo |
| B · BLIPS Cobrança | 38.134 (66%) | idem |
| B · BLIPS Cobrança, completo | 19.751 (34%) | nada de texto; só a transcrição dos áudios |

Prioridade dentro do que falta (se o download precisar ser fatiado):
1. **Amostra do avaliador**: 1.500 protocolos de A e ~1.850 de B (`dados/amostra/amostra.json`, seed 20261119). Sem ela o avaliador não roda.
2. **Protocolos com turno do cliente em fonte parcial**: ~4,6 mil em A e ~15 mil em B. É onde estão as métricas de espera, o red flag e o ranking de atendentes.
3. **Protocolos sem mensagem do cliente** (disparos): ~17,8 mil em A e ~23 mil em B na fonte parcial. Baixar confirma se o cliente realmente não respondeu; hoje parte desses pode ter resposta que o BigQuery não capturou.

Consequências enquanto faltar (todas declaradas no artefato):
- "Sem resposta" e red flag superestimados nas fontes parciais (falta a réplica do atendente ou o meio da conversa). Referência confiável: B completo, com 17% sem resposta e 41% red flag antes da regra de encerramento.
- Autor inferido por regra (texto repetido × estágio do chat) em vez de `sender_kind` oficial. Validação manual de 30 chats (spec 09 §1) ainda não feita.
- Tempo de resposta da IA do FINZA com base pequena.
- Score só de agilidade; assuntos, temperatura, frustração e resolução vazios.

O que nenhum caminho abaixo resolve: transcrição de áudio (o `getChatMessages` traz o link da mídia, não o texto).

## 4. O que já foi tentado

| # | Tentativa | Resultado |
|---|---|---|
| 1 | MCP `hyperflow-finza-production` (Studio FINZA, URL `/mcp/e/…`) | Conectado. **Não tem mensagens**: a fonte "Protocolos" é 1 linha por atendimento. Conversas ficam no MCP do Desk (`search_chats`, `get_chat_messages`, URL `/mcp/d/…`), segundo o guia `mcp-do-desk` do próprio servidor |
| 2 | Studio BLIPS (`integracoes.hyperflow.global`, URL `/mcp/e/…`) | Mesma coisa: é o Studio, sem mensagens. Não foi registrado |
| 3 | Desk FINZA (`conversas.hyperflow.global` → Configurações) | **Não há aba MCP**: só Integrações (API Key "para integrar o atendimento humano com o bot"), Parâmetros e Usuários. `desk.hyperflow.global` redireciona para `conversas.hyperflow.global` |
| 4 | Desk BLIPS → Configurações | Não conferido até o fechamento deste documento (o print enviado era do Studio) |
| 5 | BigQuery, todo o projeto | Não existe log completo além do `chat_history` v2 (seção 2) |
| 6 | Supabase da Torre (`ai_messages`) | Existe só o trecho com IA, com retenção de texto de ~5 semanas. Incorporado ao artefato (ver o fim deste arquivo) |
| 7 | API Key da tela de Integrações do Desk | Não testada: é descrita como integração bot ↔ atendimento, sem indicação de leitura de mensagens |

## 5. Formas de conseguir os dados

| Caminho | O que precisa | Prazo | Observações |
|---|---|---|---|
| **1. API GraphQL do desk** (`desk-ext.hyperflowapis.global/graphql`, query `getChatMessages`, header `tenant`) | Ok explícito do João (ele tinha definido "por MCP, não por token") e um token de sessão do desk salvo em `dados/` | Começa no mesmo dia. Estimativa a 2–3 req/s: A 2–3 h · B 5–8 h (3–5 h só os 38.134 incompletos) | API não documentada, a mesma dos fluxos de auditoria do n8n. Toda chamada é POST mesmo sendo consulta; roda por script Node (o `curl -X POST` está em deny). Tenants: blips `642eb86c0cd915bc8137a05d`, finza `68af4fe6efea9d04eda67f0e`. Só leitura, retomável, com retry |
| **2. MCP do Desk** | Hyperflow habilitar a aba MCP nos desks FINZA e BLIPS; chave de API somente leitura para o download em massa | Depende do suporte do Hyperflow | Caminho oficial, com consentimento "só leitura". Por dentro da sessão não cabe o volume; precisa da chave para script |
| **3. Estender a carga `chat_history`** no BigQuery | Time de dados incluir o tenant FINZA e os protocolos das 20 filas de cobrança do BLIPS no escopo (`vw_extracao_conversas_leads_escopo`) | Depende do time de dados | Solução definitiva: resolve também para o Sentinela e para reprocessamentos futuros, sem credencial com o agente |

Recomendação: caminho 1 para fechar a entrega, caminho 3 em paralelo como definitivo.

## 6. Depois que os dados chegarem

1. Salvar em `dados/brutos/api/<chat_id>.json` (retomável por `chat_id`), testando antes em 20 protocolos para medir taxa e formato.
2. `scripts/normalizar.mjs`: preferir `api_getChatMessages` > `chat_history_completo` > demais (spec 02 §1.3) e usar o autor oficial.
3. Validar a regra de autor em 30 chats e recalcular 10 protocolos à mão (spec 09 §1–2).
4. Refazer a estimativa do lote do avaliador, esperar o ok do João, rodar uma vez (spec 04 §7).
5. Score e agregados (spec 05), `scripts/montar_artefato.mjs`, republicar no mesmo artefato.
6. Calibração com 20 protocolos (spec 09 §3) e proposta de comentário de entrega no Quimera #13860.
