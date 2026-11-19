# 09 · Validação e aceite

## 1. Reconciliação de dados (bloqueante)

| Checagem | Regra |
|---|---|
| Contagem de chats por recorte | Banco do artefato = extração BQ (spec 02 Q de volume). Diferença = 0, ou explicada em `config/geral.notas` |
| Recortes não se misturam | Nenhum `chat_id` aparece nos dois recortes. Todo chat BLIPS passou pelo depto Cobrança |
| Janela | Todos os `inicio` estão entre 2026-08-20 e 2026-11-18 (`America/Sao_Paulo`) |
| Completude de mensagens | Amostra de 30 chats: nº de mensagens extraídas comparado a outro contador independente (spec 02 §completude). Divergência > 5% é declarada no artefato |
| Autoria IA × humano | Amostra de 30 chats lida à mão: regra de autor correta em ≥ 95% das mensagens |
| CNPJ | % de clientes com CNPJ e % ambíguos publicados na Metodologia |

## 2. Métricas de tempo

- 10 protocolos recalculados à mão: espera, pior faixa e tempo para assumir batem com a spec 03.
- Relógio comercial: 3 casos fora do expediente conferidos.

## 3. Calibração do avaliador

- 20 protocolos estratificados (por recorte × faixa). O João dá a nota dele por critério.
- O avaliador está aprovado se:
  - a diferença média absoluta for ≤ 15 pontos;
  - houver concordância ≥ 80% em `resolvido`;
  - houver concordância ≥ 80% em `frustracao_atendimento.presente`.
- Se reprovar: ajustar o prompt (v2) e reprocessar (spec 08).
- Enquanto não aprovar, o ranking de atendentes leva o selo "prévia não calibrada".

## 4. Artefato

- Critérios de UI da spec 07 §4.
- Uma passada funcional no banco: um `list` por coleção escrita. Com as regras `admin`, uma leitura em nível `view` não pode ver nada.
- Testar prompt (`sample`) com 1 protocolo e exportar JSON de 1 cliente.
- Pedido de reprocessamento criado pela página e lido pela rotina da spec 08 §5. Pode ser o tipo `pesos`, que não gasta LLM.

## 5. Definição de pronto

- [ ] Artefato publicado, privado, URL entregue ao João.
- [ ] §1 a §4 ok, com as divergências declaradas no próprio artefato.
- [ ] Specs e agente anexados na demanda do Quimera.
- [ ] Skill `bigquery-finza` atualizada com o domínio de atendimento (regra do workspace).
