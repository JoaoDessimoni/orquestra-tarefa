# Relatório — Tags de conversa, Transbordos e Transferências por agente de IA (Torre de Controle)

> **Status:** documento vivo / acúmulo (primeira etapa de um trabalho maior).
> **Data da coleta:** 2026-07-24
> **Fonte:** Supabase de **produção** da Torre (`project_ref=idinihcyezkqfarztrdx`), via MCP `supabase-prod` em **somente leitura** (`supabase_read_only_user`). Nenhuma escrita no banco.
> **Escopo (recorte pedido):** apenas **Valentina · finza**, **Esperanza · finza** e **Esperanza · blips**.

---

## 0 · Nota metodológica (ler antes das tabelas)

**Modelo de dados** (multi-tenant, schema por org — `finza`→`org_finza`, `blips`→`org_blips`):

- **Agente de IA** = `org_{slug}.ai_agents` (colunas `slug`, `name`, `allowed_tags_mode`). Todos os agentes estão hoje com `allowed_tags_mode = 'all'`.
- **Transbordo × Transferência NÃO são tabelas separadas.** São o **mesmo objeto** — `transfer_tags` (config **por agente**, via `agent_id`) — distinguido pelo campo `type` em `transfer_tag_type_periods`:
  - `type = 'overflow'` → **TRANSBORDO** (IA não resolveu / erro de fluxo / cliente exigiu humano)
  - `type = 'transfer'` → **TRANSFERÊNCIA** (roteamento de negócio legítimo: distrato, renegociação, suporte técnico…)
  - O `type` é **temporal/versionado**: a mesma tag pode mudar de classificação ao longo do tempo. Aqui uso sempre o **tipo vigente** (`effective_to IS NULL`). Os **eventos** guardam o tipo do momento em que ocorreram (por isso uma tag pode aparecer nos dois lados nos eventos — ver caso `transferencia_por_solicitacao` da Esperanza·blips).
- **Tags de conversa** = catálogo `org_{slug}.tag_catalog` (`type='conversation'`). **É org-wide, não por-agente** — não há `agent_id` no catálogo, e como o modo é `'all'`, todo agente da org pode usar todas. Por isso este relatório mostra: (i) o **catálogo por org** (uma vez cada) e (ii) o **uso real por agente** (tags efetivamente aplicadas, via `ai_funnel_events` unido por `protocol`).

**Caveats de dados (declarados):**
1. **Poluição do catálogo de tags de conversa.** Só **12** tags por org são "de sistema" (desenhadas). As demais (finza: 249 · blips: 44) são **free-form criadas em runtime** pela própria IA (`ensure_tag_exists` insere o que o modelo emitir). Há duplicatas semânticas, variações de grafia e ruído puro (`-1`, `12`, `{"tags": []}`, UUID…). Ruído separado em seção própria.
2. **Cobertura do "uso por agente".** A atribuição tag→agente vem do join `conversation_tags.protocol = ai_funnel_events.protocol`; nem toda tag aplicada tem evento de funil associável, então os totais de uso são **parciais** (piso, não total). As listas de uso mostram o **Top 20** por volume; o nº de tags distintas e o total de aplicações estão no cabeçalho de cada bloco.
3. `conversation_tags` contém tags que **nem estão no catálogo** (`label=null` nas tabelas de uso) — outra face da poluição free-form.

---

## 1 · Valentina · org **finza**

`ai_agents.slug = valentina` · id `9a952883-7d34-4959-8f20-979bbec2bb59` · tipo conversational.

### 1.1 Transbordos configurados (`type=overflow`) — 3 tags
| slug | rótulo | eventos | → humano |
|---|---|--:|--:|
| `transferencia_por_erro_de_fluxo` | Transferência por erro de fluxo | 48 | 48 |
| `transferencia_por_renegociacao` | Transferência por renegociação | 17 | 17 |
| `transferencia_por_contrato_nao_encontrado` | Transferência por contrato não encontrado | 3 | 3 |
| **Total transbordo** | | **68** | **68** |

### 1.2 Transferências configuradas (`type=transfer`) — 3 tags
| slug | rótulo | eventos | → humano |
|---|---|--:|--:|
| `transferencia_por_solicitacao` | Transferência por solicitação | 60 | 60 |
| `transferencia_por_distrato` | Transferência por distrato | 12 | 12 |
| `transferencia_por_solicitacao_tecnica` | Transferência por solicitação técnica | 8 | 8 |
| **Total transferência** | | **80** | **80** |

> Observação: para a Valentina, `transferencia_por_renegociacao` está classificada como **transbordo** (overflow) hoje — diverge do `metricas agentes.txt` (que a tratava como transferência). O banco vivo é a verdade; a divergência decorre da natureza temporal do `type`.

### 1.3 Tags de conversa usadas — 197 tags distintas · 4.187 aplicações (Top 20)
| tag | aplicações |
|---|--:|
| Encaminhado para humano (`encaminhado_humano`) | 372 |
| Solicitacao de link/codigo de pagamento | 204 |
| Quer pagar / boleto / PIX / segunda via | 182 |
| Contato errado (`contato_errado`) | 144 |
| Parcelas vencidas, pendentes e títulos vencidos | 144 |
| Interesse em pagar (`interesse_pagamento`) | 143 |
| Sem resolução (`sem_resolucao`) | 136 |
| Comprovante e pagamento já realizado | 133 |
| Consulta de contrato e equipamentos do cliente | 123 |
| Maquina com defeito x cobranca (separar originador e Finza) | 111 |
| Confirmacao de pagamento sem envio de comprovante | 108 |
| Status operacional e bloqueio do equipamento | 106 |
| `no_resolution` | 78 |
| Maquina parada/bloqueada - verificacao de boletos | 73 |
| Entrega / logistica do equipamento | 72 |
| Status financeiro, parcelas, valores e contestacao | 71 |
| Cliente em onboarding (cadastro, CCB, prova de vida) | 70 |
| `payment_request` | 65 |
| Pagamento confirmado (`pagamento_confirmado`) | 60 |
| `-1` ⚠️ ruído | 58 |

*(+177 outras tags; ver caveat de poluição. Note duplicatas de conceito: `no_resolution`≈`sem_resolucao`, `payment_request`≈demanda de pagamento.)*

---

## 2 · Esperanza · org **finza**

`ai_agents.slug = esperanza` · id `c2e3a30e-31ff-49fb-8243-456bbf761df0` · **agente default** · conversational.

### 2.1 Transbordos configurados (`type=overflow`) — 3 tags
| slug | rótulo | eventos | → humano |
|---|---|--:|--:|
| `transferencia_por_solicitacao` | Transferência por solicitação | 20 | 20 |
| `transferencia_por_erro_de_fluxo` | Transferência por erro de fluxo | 17 | 17 |
| `transferencia_por_contrato_nao_encontrado` | Transferência por contrato não encontrado | 11 | 11 |
| **Total transbordo** | | **48** | **48** |

### 2.2 Transferências configuradas (`type=transfer`) — 3 tags
| slug | rótulo | eventos | → humano |
|---|---|--:|--:|
| `transferencia_por_renegociacao` | Transferência por renegociação | 20 | 20 |
| `transferencia_por_solicitacao_tecnica` | Transferência por solicitação técnica | 18 | 18 |
| `transferencia_por_distrato` | Transferência por distrato | 4 | 4 |
| **Total transferência** | | **42** | **42** |

> A mesma tag `transferencia_por_solicitacao` que na Valentina é **transferência** aqui é **transbordo** — confirma que o `type` é **por-agente** (e temporal).

### 2.3 Tags de conversa usadas — 57 tags distintas · 806 aplicações (Top 20)
| tag | aplicações |
|---|--:|
| Solicitacao de link/codigo de pagamento | 126 |
| Encaminhado para humano (`encaminhado_humano`) | 77 |
| Pagamento confirmado (`pagamento_confirmado`) | 43 |
| Confirmacao de pagamento sem envio de comprovante | 32 |
| Cliente quer saber sobre status do contrato | 32 |
| Suspeita de fraude / identidade usurpada | 31 |
| Contato errado (`contato_errado`) | 30 |
| `7` ⚠️ ruído | 29 |
| `contact_iniciado` | 29 |
| Maquina parada/bloqueada - verificacao de boletos | 22 |
| `atendimento_humano` | 22 |
| Renegociacao de dividas | 22 |
| Pagamento para liberar a maquina | 20 |
| `contact_initiated` | 20 |
| Envio de comprovante e baixa de pagamento | 19 |
| Cliente nao reconhece a divida ou o contrato | 16 |
| `comprovante` | 15 |
| Demanda financeira de pagamento (boleto, PIX, 2ª via) | 14 |
| `cliente_menciona_acao_judicial` | 13 |
| `cliente_pede_para_nao_ser_contatado` | 13 |

*(+37 outras. Note `contact_iniciado`/`contato_iniciado`/`contact_initiated` e `atendimento_humano`/`atendimento humano` como variações da mesma ideia.)*

---

## 3 · Esperanza · org **blips**

`ai_agents.slug = esperanza` · id `e9dbe911-3408-42f5-980a-3413d2becbc3` · **agente default** · conversational. *(É o único agente do schema `org_blips` — não há Valentina em blips.)*

### 3.1 Transbordos configurados (`type=overflow`) — 3 tags
| slug | rótulo | eventos | → humano |
|---|---|--:|--:|
| `erro_de_fluxo` | Erro de Fluxo | 321 | 321 |
| `transferencia_por_contrato_nao_encontrado` | Transferência por contrato não encontrado | 8 | 8 |
| `equipamento_nao_encontrado` | Equipamento não encontrado | 2 | 2 |
| `transferencia_por_solicitacao` (eventos legados, hoje é `transfer`) | Transferência por solicitação | 309 | 309 |
| **Total transbordo (eventos)** | | **640** | **640** |

> ⚠️ **Reclassificação temporal:** `transferencia_por_solicitacao` está **configurada hoje como transferência** (`transfer`), mas acumulou **309 eventos como transbordo** quando o `type` anterior era `overflow`. Por isso aparece nos dois blocos. Config vigente de transbordo = 3 tags (`erro_de_fluxo`, `transferencia_por_contrato_nao_encontrado`, `equipamento_nao_encontrado`).

### 3.2 Transferências configuradas (`type=transfer`) — 5 tags
| slug | rótulo | eventos | → humano |
|---|---|--:|--:|
| `suporte_tecnico` | Suporte técnico | 188 | 188 |
| `transferencia_por_renegociacao` | Transferência por renegociação | 91 | 91 |
| `transferencia_por_solicitacao` | Transferência por solicitação | 57 | 57 |
| `transferencia_por_distrato` | Transferência por distrato | 50 | 50 |
| `transferencia_por_reparcelamento` | Transferência por reparcelamento | 6 | 6 |
| **Total transferência (eventos)** | | **392** | **392** |

> blips tem **config diferente** da finza: inclui `equipamento_nao_encontrado`, `erro_de_fluxo` (slug próprio, sem prefixo `transferencia_por_`), `suporte_tecnico` e `transferencia_por_reparcelamento` — refletindo o contexto de equipamento/originador da operação Blips.

### 3.3 Tags de conversa usadas — 89 tags distintas · 37.309 aplicações (Top 20)
| tag | aplicações |
|---|--:|
| Encaminhado para humano (`encaminhado_humano`) | 7.970 |
| `pedido_boleto` (fora do catálogo) | 3.313 |
| Solicitacao de link/codigo de pagamento | 3.170 |
| Pagamento confirmado (`pagamento_confirmado`) | 2.673 |
| `apresentação` (fora do catálogo) | 2.036 |
| Sem resolução (`sem_resolucao`) | 1.689 |
| Interesse em pagar (`interesse_pagamento`) | 1.603 |
| Controle de Inadimplência - Proibição de Agendamento/Promessa | 1.222 |
| Envio de comprovante e baixa de pagamento | 1.183 |
| Maquina parada/bloqueada - verificacao de boletos | 994 |
| Confirmacao de pagamento sem envio de comprovante | 986 |
| `comprovante` | 980 |
| Promessa de pagamento (`promessa_pagamento`) | 963 |
| Negociação ativa (`negociacao_ativa`) | 887 |
| `-1` ⚠️ ruído | 822 |
| Formas de pagamento disponiveis e aceitas | 516 |
| Parcelas vencidas, pendentes e títulos vencidos | 513 |
| `intencao_de_pagamento` | 478 |
| Cancelar contrato ou devolucao de suprimentos/equipamentos | 462 |
| `formaspagamento` (fora do catálogo) | 457 |

*(+69 outras. Poluição forte: `pedido_boleto`/`Pedido de boleto`/`pediu_boleto`/`Pedidodeboleto`, `formaspagamento`/`Formas de pagamento…`, `Solicitacao`/`Soliciacao`/`Solictacao`/`Solicitacao_…` — todas variações da mesma intenção.)*

---

## 4 · Catálogo de tags de conversa por org (`tag_catalog`, `type='conversation'`)

As **12 tags de sistema** (`is_system=true`) são **idênticas nas duas orgs** — é o conjunto **desenhado/canônico**. O resto é free-form de runtime.

### 4.1 Tags de sistema (desenhadas) — 12, iguais em finza e blips
`acordo_fechado` · `contato_errado` · `disputa` · `encaminhado_humano` · `interesse_pagamento` · `negociacao_ativa` · `numero_invalido` · `pagamento_confirmado` · `promessa_pagamento` · `reclamacao` · `sem_resolucao` · `sentimento_negativo`

### 4.2 org_finza — 261 no total (12 sistema · 238 free-form válidas · 11 ruído)
**Ruído descartado (11):** `` (vazio) · `-1` · `{"tags": []}` · `bc12b73c-135b-4e44-ac89-4342a892ea78` (UUID) · `7` · `12` · `21` · `25` · `59` · `60` · `62`

*As 238 free-form válidas não são listadas exaustivamente aqui (majoritariamente descrições longas auto-geradas e duplicatas semânticas). As mais relevantes por uso real estão nas seções 1.3 e 2.3. Recuperáveis a qualquer momento por: `SELECT name,label FROM org_finza.tag_catalog WHERE type='conversation' ORDER BY name;`*

### 4.3 org_blips — 56 no total (12 sistema · 37 free-form válidas · 7 ruído)
**Ruído descartado (7):** `5` · `12` · `21` · `21.5` · `29` · `57` · `58`

**Free-form válidas (37):** `acao_judicial` · `Agendamento de pagamento` · `Cancelar contrato ou devolucao de suprimentos/equipamentos` · `Cliente quer saber sobre proximos vencimentos e calendario de pagamentos` · `cliente_falecido` · `cliente_hostil` · `cobranca_indevida` · `comprovante` · `comprovante_envio` · `Confirmacao de pagamento sem envio de comprovante (consulta de pendencias)` · `discordancia_banco_dados` · `divergencia_valor` · `Envio de comprovante e baixa de pagamento` · `erro_pagamento` · `Formas de pagamento disponiveis e aceitas` · `Intencao de pagamento futuro` · `Liberacao em confianca de maquina` · `Liberacao_em_confianca_de_maquina` · `Maquina parada/bloqueada - verificacao de boletos em atraso` · `maquina_parada` · `nao_perturbe` · `nao_reconhece_divida` · `Parcelas vencidas, parcelas pendentes e titulos vencidos` · `payment_confirmed` · `payment_request` · `pediu_desconto` · `pediu_parcelamento` · `promessa_duvidosa` · `QR Code expirado… trocar para boleto` · `Renegociacao de dividas` · `Renegociacao negada para clientes FIDC` · `Sem descrição` · `Solicitacao de link/codigo de pagamento` · `suporte tecnico` · `suspeita_fraude` · `Transferencia por insistencia do cliente` · `vulnerabilidade_financeira`

---

## 5 · Resumo e totais

### 5.1 Transbordos e Transferências — **configuração vigente** (nº de tags por agente)
| Agente · org | Transbordos (overflow) | Transferências (transfer) | Total configurado |
|---|--:|--:|--:|
| Valentina · finza | 3 | 3 | 6 |
| Esperanza · finza | 3 | 3 | 6 |
| Esperanza · blips | 3 | 5 | 8 |
| **Total** | **9** | **11** | **20** |

### 5.2 Transbordos e Transferências — **eventos reais** (100% `transferred_to_human`)
| Agente · org | Eventos transbordo | Eventos transferência | Total encaminhado a humano |
|---|--:|--:|--:|
| Valentina · finza | 68 | 80 | 148 |
| Esperanza · finza | 48 | 42 | 90 |
| Esperanza · blips | 640 | 392 | 1.032 |
| **Total** | **756** | **514** | **1.270** |

### 5.3 Tags de conversa — catálogo (org) e uso (agente)
| Recorte | Catálogo total (org) | Sistema | Free-form válidas | Ruído | Tags usadas p/ agente | Aplicações |
|---|--:|--:|--:|--:|--:|--:|
| Valentina · finza | 261 (org) | 12 | 238 | 11 | 197 | 4.187 |
| Esperanza · finza | 261 (org) | 12 | 238 | 11 | 57 | 806 |
| Esperanza · blips | 56 (org) | 12 | 37 | 7 | 89 | 37.309 |

> Catálogo é **por org** (finza e blips contam uma vez cada); as colunas "tags usadas" e "aplicações" são **por agente** e **parciais** (join por `protocol`).

---

## 6 · Achados a sinalizar

1. **`type` de transbordo/transferência é por-agente e temporal.** A mesma `transferencia_por_solicitacao` é transbordo na Esperanza·finza e transferência na Valentina·finza; e na Esperanza·blips migrou de overflow→transfer (309 eventos legados como transbordo). Qualquer métrica de "taxa de transbordo" precisa resolver o `type` **na data do evento**.
2. **Catálogo de tags de conversa fortemente poluído.** Só 12 tags são desenhadas; o resto é free-form de runtime, com duplicatas de grafia/idioma e ruído puro. Candidato a um item de backlog (BTR ou BES/BVA) de **saneamento do catálogo** + fixar `allowed_tags_mode` num conjunto curado.
3. **blips ≠ finza na config de encaminhamento.** blips (Esperanza) tem tags próprias de equipamento/originador (`equipamento_nao_encontrado`, `suporte_tecnico`, `transferencia_por_reparcelamento`) que não existem na finza.

---

## 7 · Como reproduzir (queries)

Todas via `supabase-prod` read-only. Trocar `org_finza`↔`org_blips` e o `slug`.

- **Config transbordo/transferência (tipo vigente):** join `transfer_tags` × `ai_agents` × `transfer_tag_type_periods (effective_to IS NULL)`.
- **Eventos:** `ai_funnel_events` filtrando `transfer_type IS NOT NULL`, agrupado por `transfer_type` + `transfer_tag_id`.
- **Catálogo de conversa:** `tag_catalog WHERE type='conversation'`.
- **Uso por agente:** `conversation_tags` × `ai_funnel_events (ON protocol)` × `ai_agents`.

*(SQL completo registrado no plano `~/.claude/plans/certo-ent-o-como-primeira-eventual-tower.md`, seção Execução.)*
