# 03 · Métricas de tempo de resposta

Entrada: mensagens ordenadas por `chat_id`, cada uma com `ts`, `autor` (cliente | humano | ia | sistema), `atendente_id`, `departamento_id` e os eventos de transferência e atribuição (spec 02).
Fuso: `America/Sao_Paulo`. Unidade: minutos, com uma casa decimal.

## 1. Conceitos

| Termo | Definição |
|---|---|
| **Bloco do cliente** | Sequência de mensagens consecutivas do `cliente`, sem fala de atendente no meio. Mensagens de `sistema` não quebram o bloco. |
| **Espera do turno** | Da **primeira** mensagem do bloco do cliente até a próxima mensagem de `humano` ou `ia`. |
| **Turno sem resposta** | Bloco do cliente sem nenhuma fala de atendente depois dele até o fim do chat (ou até o corte da extração, se o chat estiver aberto). |
| **Pior espera do protocolo** | O maior valor de espera de turno no chat. Turno sem resposta conta como infinito. |
| **1ª resposta** | Espera do primeiro bloco do cliente (só em chat receptivo). |
| **Tempo para assumir** | Do evento de transferência para um departamento humano (ou de entrada na fila humana) até a primeira mensagem de `humano`. Medido por transferência. |
| **Resposta da IA** | Espera do turno quando quem responde é `ia`. |

## 2. Faixas (clusterização)

Classifica cada turno e, pela pior espera, o protocolo:

| Faixa | Regra | Cor no artefato |
|---|---|---|
| `ate_10` | espera ≤ 10 min | verde |
| `10_20` | 10 < espera ≤ 20 | verde-claro |
| `20_30` | 20 < espera ≤ 30 | amarelo |
| `30_60` | 30 < espera ≤ 60 | laranja |
| `acima_60` 🚩 | espera > 60 → **red flag** | vermelho |
| `sem_resposta` | turno sem resposta | vermelho-escuro, categoria própria |

Os limites das faixas ficam em `config/geral.faixas` e podem ser editados. Recalcular é feito na página, sem LLM.

## 3. Relógio corrido × horário comercial

Toda espera é calculada nos dois relógios e gravada nos dois campos:
- `espera_corrida_min` — tempo de parede.
- `espera_comercial_min` — conta só os minutos dentro do expediente.

Expediente padrão: **segunda a sexta, 08:00 às 18:00**, sem feriados na v1. Fica em `config/geral.expediente` e pode ser editado.

O artefato mostra o seletor "Relógio: corrido | comercial". O padrão de exibição é **comercial**, para não marcar como falha a mensagem das 23h respondida às 8h. O corrido fica a um clique.

## 4. Casos de borda

| Caso | Tratamento |
|---|---|
| Chat ativo (empresa iniciou, broadcast ou template) sem resposta do cliente | Não gera turno. Entra no volume, mas não nas métricas de espera. |
| Cliente responde a um disparo | O bloco nasce na primeira resposta do cliente, normal. |
| Mensagem automática de fila ("aguarde, você será atendido") | Autor `sistema`/bot de fila. **Não** conta como resposta. A lista de padrões fica na spec 02 §5. |
| Resposta da IA seguida de transferência | A IA respondeu o turno. O tempo para assumir mede a espera pelo humano. |
| Cliente manda mensagem depois do `chat_finished` | Pertence a outro chat se houver novo `chat_id`. Se não houver, é turno sem resposta. |
| Espera > 7 dias | Mantém o valor, com `flag_outlier = true`. Fica fora da mediana do atendente. |
| Chat aberto no corte | Turnos pendentes ficam `sem_resposta_ate_corte`, separados do `sem_resposta` de chat encerrado. |

## 5. Agregados

Por protocolo:
- `n_turnos`, `n_turnos_por_faixa`
- `primeira_resposta_min`, `pior_espera_min`, `faixa_pior`
- `red_flag`, `sem_resposta`
- `tempo_assumir_min[]`, `resp_media_ia_min`, `resp_media_humano_min`

Por atendente, departamento, recorte e semana:
- **mediana** e **p90** das esperas, mais a média só como apoio;
- % de protocolos por faixa;
- % de red flag;
- % sem resposta.

Mapa de calor: mediana da espera por hora do dia × dia da semana, com base na hora de início do turno.

## 6. Atribuição ao atendente

O turno pertence a quem respondeu. Turno sem resposta pertence a quem tinha o chat no momento (atribuição vigente, pela timeline). Se não houver atribuição, vai para a fila ou o departamento.
