---
name: raio-x-clara
description: Gera o raio-x da Clara (IA de formalização) para o time de negócio. Mostra acionamento pelo n8n, conversa aberta no Hyperflow, resposta na Torre, coleta de documentos, aprovação do time e formalização, com a fonte de cada número, em painel compacto ou relatório completo com os indicadores CLA-01 a CLA-06. Use quando o usuário pedir "raio-x da Clara", "relatório da Clara", "indicadores da Clara", "quantos a Clara acionou/formalizou no mês", "atualizar o painel da Clara", "RAIO-X CLARA 10/26", ou quando um chamado questionar se a Clara aciona todos os clientes que pagaram o sinal.
---

# Raio-X da Clara

Relatório mensal da esteira de formalização da Clara. Os scripts saem dos dados brutos e
chegam aos números da página. A página é montada a partir de um dos dois modelos em `assets/`.

**Nome do relatório: `RAIO-X CLARA MM/AA`**, onde MM é o mês de referência e AA o ano com 2
dígitos (ex.: `RAIO-X CLARA 09/26`). O nome vai no `<title>`, no `<h1>` e no título do
Artifact. A pasta usa hífen no lugar da barra: `raio-x-clara-MM-AA`. Não cite número de
chamado em nenhum lugar da página.

| Formato | Modelo | Quando usar |
|---|---|---|
| Painel compacto | `assets/painel-chamado.html` | Responder um chamado: só as perguntas feitas, 4 indicadores, 3 blocos |
| Relatório completo | `assets/relatorio-completo.html` | Visão geral: funil, CLA-01 a CLA-06, venda à vista, causas, pré-requisitos |

Em dúvida, pergunte qual formato. O usuário já preferiu o compacto para responder chamado.

## Regras de apresentação (decididas pelo usuário)

- **pt-BR**, horários sempre em **BRT**.
- **Fontes do n8n sem detalhe técnico**. Dizer só "levantado a partir do fluxo de n8n que…",
  sem ID de fluxo, nome de nó, credencial ou execução. As fontes de **BigQuery, Torre e
  anexos mantêm** tabela e campo (`PLATAFORMA.negotiation`, `chat_events`, `ai_messages`…).
- Cada número da página leva o selo da fonte (`F1`, `F2`…) e a seção Fontes no fim.
- **Comentário do Quimera:** redigir no chat, **nunca postar**. Escrever na **primeira pessoa
  do singular** ("analisei", "confirmei", "proponho"), com o link da página.
- A página publicada é privada. Avisar que o time só abre depois do Share. Se o link ficar
  público, mascarar telefone de cliente (ex.: 43 9xxxx-9878).

## Definições (não mudar sem o usuário)

- **Turma do mês:** contratos que entraram em **Endereço do Responsável** (`RESPONSIBLE_ADDRESS`)
  no mês. É a fase em que a Clara deve acionar.
- **Público da Clara:** marca (`financial.identifier`) BLIPS ou FINZA. **IDEAL / venda à vista
  fica fora** e aparece só como informação adicional.
- **Acionado:** a execução do fluxo de acionamento chegou ao `Ativar Hyper` ou `Ativar Hyper1`
  sem erro.
- **Conversa aberta:** `chat_created` no departamento IA - Formalização do tenant, para o mesmo
  telefone, entre −1 h e +30 dias da entrada na fase.
- **Respondeu:** o protocolo dessa conversa existe na Torre com mensagem do cliente.
- **Formalizado:** a documentação foi aprovada e anexada na plataforma e o contrato **entrou em
  CHECKLIST**. O 30 d conta só quem chegou ao Checklist em até 30 dias.
- **CLA-01, aprovado e anexado:** o cliente mandou, a Clara coletou e, com **aprovação humana**,
  anexou. Prova: `historical_status.justification` começa com "Formalizacao APROVADA por".
- **Kit completo:** identidade + comprovante residencial + comprovante da empresa + comprovante
  de entrega registrados no banco da Clara.
- **CLA-03, ciclo:** dias entre CHECKLIST e RESPONSIBLE_ADDRESS (mediana e P90).
  **CLA-06, aging:** contratos ainda abertos em cada data, por faixa de dias.

## Armadilhas já pagas

- **A Torre só registra conversa respondida.** Um total de "60 protocolos" já apareceu
  contando só a org Blips. Some `org_blips` e `org_finza`. O conteúdo das mensagens é apagado após ~30 dias, mas
  as contagens continuam valendo.
- **2xx do Hyperflow não prova contato.** No canal blips, ~40% das chamadas não viram chat
  porque o cliente já está em chat com o vendedor. Para provar, use `chat_events`, não o n8n.
- **`bronze_hyperflow.chat_history` (status de entrega) só tem o tenant Blips.** Entrega da
  Finza não é mensurável.
- **Retenção do n8n:** automacao guarda desde ~24/07/2026. **Assistants guarda ~12 dias**, então
  o passo 04 tem de rodar logo após o fim do mês. Execução que volta 404 foi podada: ignore.
- **A instância assistants é compartilhada** com Valentina e Esperanza. Baixe 2 execuções por
  vez, nunca em lote com dados completos.
- **Banco da Clara:** só pela credencial **"Clara v2"** (`NnKgQ1T7ShqIvQHD`). Outra credencial
  dá "relation … does not exist". **O usuário roda as consultas** num fluxo de auditoria, porque
  o Claude não executa workflow. Cada nó Postgres vai ligado direto no gatilho, ou com Execute
  Once: encadeados, eles rodam 1 vez por item e derrubam o worker.
- **Chave de telefone:** DDD + 8 últimos dígitos (`comum.chave_tel`). Telefone do card do Bitrix
  ≠ telefone da plataforma em ~13% dos casos, e a Clara usa sempre o da plataforma.
- **BigQuery:** DATETIME literal com `T` (`'2026-09-14T09:58:00'`). Subquery correlacionada em
  join não roda: case em Python.
- **Mudança na esteira:** a correção A do card foi aplicada em 14/09/2026 às 09:57 BRT. De 03 a
  14/09, o acionamento caiu por falha na criação do card. Ao comparar meses, marque essa faixa.

## Passo a passo

`O` = pasta de trabalho (`demandas/_workspace/raio-x-clara-MM-AA/dados/`). Janela = do 1º dia do mês
anterior (para ter a comparação) até o dia do corte. Tudo é só leitura (GET e SELECT).

```bash
S=.claude/skills/raio-x-clara/scripts
python $S/comum.py                                       # autoteste: deve imprimir ok
python $S/01_acionamento_n8n.py "$O" 2026-09-01 2026-11-01   # n8n automacao -> exec_parsed.csv (rode em background: em 20/10/26 saíram ~4 execuções por minuto, horas para 2 meses; o cache em exec_data/ deixa parar e retomar)
python $S/02_bigquery.py "$O" 2026-09-01                     # base, chats_ia, eventos_contato, aprovacao_anexo
```

3. **Torre:** rodar `sql/torre_protocolos.sql` com `mcp__supabase-prod__execute_sql`. O resultado
   grande vai para um arquivo em `tool-results/`. Depois:
   `python $S/torre_csv.py <arquivo> "$O"`.
4. **Banco da Clara** (só para o relatório completo): entregar `sql/banco_clara.sql` ao usuário,
   com a data de início trocada. Ele roda Q2, Q3, Q4 e Q6 no fluxo de auditoria e salva os CSVs
   em `$O/clara-db/`. Q4a é um teste de formato, para conferir antes do Q4.
5. **Card de aprovação** (opcional, relatório completo): `python $S/04_card_aprovacao.py "$O"`.
6. `python $S/03_metricas.py "$O" 2026-11-01` gera `contratos.csv` e `metricas.json`, e imprime
   o funil por mês.
7. **Conferir antes de montar.** Turma × acionado × conversa precisam fechar. Os motivos de "não
   acionado" e "sem conversa" precisam somar o total. Número esquisito → investigue no
   `contratos.csv` antes de publicar.

## Montar a página

1. Carregue as skills `artifact-design` e `dataviz`. Copie o modelo para
   `demandas/_workspace/raio-x-clara-MM-AA/raio-x-clara-MM-AA.html` e troque `MM/AA` no
   `<title>` e no `<h1>`.
2. **Painel:** troque os arrays `SEM`, `TOT`, `ACI`, `CHA` e `RES` pelos de
   `metricas.json["semanas"]`, os 4 indicadores do topo e os números do texto.
   **Completo:** troque `MESES`, `TURMA`, `ACION`, `CHAT`, `RESP`, `ENV`, `APR`, `KIT`, `ANX` e
   `COMP`, e as tabelas `tb-01b`, `s03`, `s04`, `ATT` e `s06`.
3. **Reescreva o texto** de cada bloco com os números novos. As causas mudam de mês a mês: as
   chaves de `nao_acionados` e `acionados_sem_conversa` dizem qual é a deste mês. Não reaproveite
   a narrativa da falha de 03 a 14/09 se ela não se repetiu.
4. Atualize a data das fontes ("consultadas em …") e a janela de cada uma.
5. Rode `node --check` no `<script>` extraído e depois publique com `Artifact`, no mesmo link se
   for atualização.

## Onde mora cada dado

| Fonte | Onde | O que dá |
|---|---|---|
| F1 n8n acionamento | prod-automacao, `eA8E5LjPtA2bXVce` (Webhook Plataforma - Análise de Documentos) | acionado, bloqueio de venda à vista (`Avisar - Motivo de não acionamento`), erro por nó |
| F2 plataforma | `blips-bigdata.PLATAFORMA.negotiation` | fases, marca, telefone, histórico (aprovado e anexado) |
| F3 conversas | `blips___desk.chat_events` / `bigquery___finza.chat_events`, depto IA - Formalização (`6a80917d9e841905d20806e0` / `6a70b455e2304d735ed7477b`) | conversa aberta; eventos do contato explicam a falta de conversa |
| F4 entrega | `bronze_hyperflow.chat_history` (só Blips) | template entregue ou falho |
| F5 Torre | Supabase, `org_blips` / `org_finza.ai_messages`, agentes Clara em `comum.AGENTE_TORRE` | respondeu |
| F8 banco da Clara | Postgres "Clara v2": `negotiations_clara`, `chat_messages_clara`, `documents_clara`, `chat_history_clara`, `decisoes_clara` | kit, pré-análise, decisões do time |
| F9/F10 n8n Clara | prod-assistants, `uEJKmrPILPNwYNGQ` (Clara - Formalização), tool `notificar_negocios` | coleta concluída, card enviado |

As credenciais do n8n vêm do `.env` do repo (`N8N_PROD_AUTOMACAO_*`, `N8N_PROD_ASSISTANTS_*`).
Nunca escreva chave em script.
