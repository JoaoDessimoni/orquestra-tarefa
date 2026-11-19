# 05 · Score 0–100 e ranking

Cálculo determinístico, fora do LLM. Ele é implementado **igual** em dois lugares: no script de carga e no JS do artefato. Assim, mudar um peso na página recalcula tudo na hora.

## 1. Pesos v1 (`pesos/{versao}`, a soma deve ser 100)

| Critério | Chave | Peso | Fonte |
|---|---|---|---|
| Agilidade | `agilidade` | 25 | spec 03 (objetivo) |
| Resolução | `resolucao` | 20 | avaliador |
| Clareza e correção | `clareza` | 15 | avaliador |
| Condução | `conducao` | 10 | avaliador |
| Empatia e tom | `empatia` | 10 | avaliador |
| Conformidade | `conformidade` | 10 | avaliador |
| Desfecho emocional | `desfecho` | 10 | avaliador |

## 2. Nota de agilidade (0–100)

A nota vem da pior espera do protocolo, no relógio selecionado (o padrão é o comercial):

| Faixa pior | Nota |
|---|---|
| ate_10 | 100 |
| 10_20 | 85 |
| 20_30 | 70 |
| 30_60 | 45 |
| acima_60 | 15 |
| sem_resposta | 0 |

Ajuste: se `n_turnos ≥ 3`, a nota final é 70% da nota da pior espera + 30% da nota da **mediana** das esperas, na mesma tabela. Assim, um único atraso não define o protocolo inteiro. A tabela fica em `config/geral.notas_agilidade`.

## 3. Score do protocolo

```
base = Σ (peso_c × nota_c) / 100        (lado humano; se só houve IA, lado ia)
score = min(base, teto) − penalidades
score = clamp(round(score), 0, 100)
```

**Tetos:** valem o menor que se aplicar.
- `sem_resposta` → 30
- `red_flag` (acima de 60 min) → 60

**Penalidades:** somam, com no máximo 30 pontos.

| Flag | Pontos |
|---|---|
| `informacao_incorreta_grave` | −15 |
| `promessa_indevida` | −10 |
| `exposicao_dados` | −15 |
| `ameaca` | −20 |
| `transferencia_sem_contexto` | −5 |

Tetos, penalidades e a tabela de agilidade são editáveis em `config/geral` e versionados junto com os pesos.

**Protocolo sem avaliação** (erro ou fora dos elegíveis): o score é só `agilidade`, com `score_parcial = true`. Ele fica fora do ranking de qualidade e aparece no de tempo.

## 4. Rankings

| Ranking | Unidade | Ordenação | Regra de entrada |
|---|---|---|---|
| Atendimentos | protocolo | score desc; desempate pela menor pior espera | protocolo avaliado |
| Atendentes | atendente humano (e-mail) | média do score; desempate pela menor mediana de espera | ≥ 10 protocolos no período e recorte |
| Departamentos | departamento | média do score | ≥ 20 protocolos |
| IA | agente de IA | mostrada como **linha de referência** no ranking, não compete | — |

- Cada ranking é sempre **por recorte** (FINZA ou BLIPS · Cobrança), nunca misturado.
- Mostra também: n de protocolos, mediana e p90 de espera, % de red flag, % sem resposta, % com frustração com o atendimento.
- Selo "prévia não calibrada" no ranking de atendentes até a spec 09 §3 ser aprovada.

## 5. Indicadores de topo (big numbers, por recorte)

- Protocolos, clientes e mensagens.
- 1ª resposta humana: mediana e p90.
- Resposta da IA: mediana.
- Tempo para assumir após transferência: mediana.
- % de protocolos com red flag e % sem resposta.
- Score médio.
- % de clientes com frustração com o atendimento.
- % resolvido.
- Volume IA × humano: só IA, IA→humano, só humano.
