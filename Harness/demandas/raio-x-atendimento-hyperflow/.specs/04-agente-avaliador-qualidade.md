# 04 · Agente avaliador de qualidade

O agente executável está em `../agents/avaliador-qualidade-atendimento.md`. Esta spec define o contrato: entrada, saída, rubrica, versionamento e como o lote roda.

## 1. Papel

O agente lê **um protocolo por vez**: as mensagens com autor e timestamp, mais as métricas de tempo da spec 03. Ele devolve um JSON com:
- assunto;
- temperatura do cliente;
- frustração com o atendimento;
- resolução;
- notas de 0 a 100 nos 6 critérios qualitativos, cada uma com justificativa e evidência.

O agente **não calcula o score final**. O score sai da spec 05, para que mudar um peso nunca exija reprocessar.

## 2. Rubrica (critérios qualitativos)

| Chave | Critério | 100 = | 0 = |
|---|---|---|---|
| `resolucao` | Resolução ou próximo passo claro | Problema resolvido, ou cliente sai sabendo exatamente o que acontece e quando | Cliente sai sem solução nem próximo passo |
| `clareza` | Clareza e correção da informação | Informação correta, completa, com valores, datas e links certos | Informação errada, contraditória ou evasiva |
| `conducao` | Condução e proatividade | Oferece a saída (2ª via, acordo, prazo, canal) sem o cliente pedir | Só reage, e o cliente precisa insistir |
| `empatia` | Empatia e tom | Cordial, personalizado, reconhece o problema | Seco, robótico, ríspido ou irônico |
| `conformidade` | Conformidade | Sem promessa indevida, sem exposição de dados, sem ameaça ou constrangimento na cobrança | Promete o que não pode, expõe dado, ameaça |
| `desfecho` | Desfecho emocional | Cliente termina mais calmo ou satisfeito que começou | Cliente termina mais irritado que começou |

O critério de **agilidade** é objetivo: vem da spec 03 e é calculado na spec 05, não pelo LLM.

O agente avalia cada **lado presente** no chat (`ia` e `humano`) separadamente quando os dois existem. O protocolo recebe `lados: {ia: {...}, humano: {...}}`. O lado `humano` é o principal do ranking.

## 3. Temperatura e frustração

- `temperatura.inicio` e `temperatura.fim`: escala de −2 (irritado) a +2 (satisfeito). 0 = neutro.
- `frustracao_atendimento`: frustração **causada pelo atendimento**: demora, repetição, não resolução, transferências, informação errada, tom.
  - Tem `presente` (bool), `intensidade` (0 a 3), `motivos[]` e `evidencia` (trecho literal curto).
- `frustracao_contexto`: frustração com a dívida, o produto ou a situação, **não** com o atendimento. Fica separada para não punir o atendente.

## 4. Assunto (taxonomia v1, editável em `config/geral.assuntos`)

`cobranca.segunda_via` · `cobranca.acordo_renegociacao` · `cobranca.atraso_juros_multa` · `cobranca.contestacao` · `taxa.condicoes` · `formalizacao.contrato_assinatura` · `formalizacao.documentos` · `pagamento.confirmacao_baixa` · `cancelamento_distrato` · `equipamento_suporte` · `cadastro_dados` · `outros`

O agente devolve `assunto_principal` e `assuntos[]`, que é multirrótulo. Assunto fora da lista vai para `outros`, com `assunto_livre`.

## 5. Contrato de saída (JSON estrito)

```json
{
  "chat_id": "string",
  "versao_prompt": "v1",
  "resumo": "até 3 frases",
  "assunto_principal": "cobranca.segunda_via",
  "assuntos": ["cobranca.segunda_via", "pagamento.confirmacao_baixa"],
  "assunto_livre": null,
  "resolvido": "sim | parcial | nao | indeterminado",
  "temperatura": { "inicio": -1, "fim": 1 },
  "frustracao_atendimento": { "presente": true, "intensidade": 2, "motivos": ["demora"], "evidencia": "trecho curto" },
  "frustracao_contexto": { "presente": false, "intensidade": 0 },
  "lados": {
    "humano": { "resolucao": {"nota": 80, "justificativa": "...", "evidencia": "..."}, "clareza": {}, "conducao": {}, "empatia": {}, "conformidade": {}, "desfecho": {} },
    "ia": null
  },
  "flags": ["informacao_incorreta_grave", "promessa_indevida", "exposicao_dados", "ameaca", "audio_nao_transcrito", "conversa_incompleta"],
  "confianca": 0.0
}
```

- `nota` é um inteiro de 0 a 100. A `evidencia` é um trecho literal de no máximo 200 caracteres. Sem evidência, a nota limita em 60 e `confianca` cai.
- **PII:** o resumo e as justificativas não repetem telefone, CPF/CNPJ, endereço nem valores de documento.

## 6. Versionamento do prompt

- A **fonte da verdade do prompt ativo** é o banco do artefato (`prompts/{versao}`, com `config/geral.prompt_ativo`).
- O arquivo do agente traz a **v1** e as regras fixas: formato de saída, PII, uma avaliação por protocolo. Ao rodar, o lote lê o texto da versão ativa no banco e o injeta como rubrica.
- Toda avaliação grava `versao_prompt`. Avaliações de versões antigas são mantidas para comparação.

## 7. Execução do lote (Claude Code, uma vez)

1. Pré-requisitos: specs 02 e 03 concluídas, ou seja, `dados/protocolos/<chat_id>.json` e `dados/metricas/` prontos.
2. Elegíveis: protocolos com pelo menos 1 mensagem do cliente e 1 fala de atendente, ou com turno sem resposta. Disparos sem resposta do cliente ficam de fora.
   **Amostra estratificada (~3.000 protocolos, decisão de 2026-11-19).** Avaliar 100% não cabe no limite semanal.
   - a) **Todos** os red flags (`acima_60`) e `sem_resposta`, com teto de 800 por recorte. Se passar do teto, sorteio proporcional por semana.
   - b) **Até 30 protocolos por atendente humano** com ≥ 10 no período, sorteados. Isso garante o ranking de atendentes.
   - c) Completar até ~1.500 por recorte com sorteio proporcional por semana × departamento × tipo (so_ia, ia_humano, so_humano). Isso garante a leitura de assunto e temperatura e a referência da IA.
   - Semente fixa (`seed = 20261119`), gravada em `config/geral.amostra`. O artefato mostra "avaliado: sim/não" e o peso amostral para extrapolar percentuais do recorte.
   - Toda a amostra usa mensagens da API (spec 02 §1.2), não a reconstrução.
   - Ampliar a amostra = reprocessamento com escopo filtrado (spec 08).
3. O lote é dividido em pacotes de **20 protocolos**. A sessão principal dispara subagentes `avaliador-qualidade-atendimento` em paralelo, até 5 por vez. Cada um lê os arquivos do pacote e grava `dados/avaliacoes/<versao>/<chat_id>.json`.
4. **Idempotente e retomável:** pula `chat_id` que já tenha avaliação da mesma versão. Uma interrupção não perde trabalho.
5. Validação: JSON inválido ou fora do schema gera nova tentativa (1x). Se falhar de novo, grava `erro_avaliacao` e segue.
6. **Estimativa de custo antes de rodar:** nº de protocolos × tamanho médio da conversa. Mostrar o número ao João e só seguir com o "ok" dele, porque o lote consome o limite semanal.
7. Fim do lote: roda a spec 05 (score) e a carga da spec 06.

## 8. Calibração (vai para a spec 09)

São 20 protocolos estratificados por faixa de espera e recorte. O João lê e dá a nota dele. O avaliador está calibrado se a diferença média for de até 15 pontos e se houver concordância ≥ 80% em `resolvido` e `frustracao_atendimento.presente`. Se não estiver calibrado, ajustar o prompt (v2) e reprocessar.
