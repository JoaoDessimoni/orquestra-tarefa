# Prompt de execução — Raio-X do Atendimento (Quimera #13860)

Cole o bloco abaixo numa sessão nova do Claude Code aberta na raiz do workspace `orquestra-tarefa`.

---

```
ULTRATHINK. Vamos executar a demanda do Quimera #13860, "Raio-X do atendimento Hyperflow: tempo de resposta, qualidade e ranking (FINZA + Cobrança BLIPS)". O objetivo é preencher o artefato já desenhado com 100% de dados reais. Até agora ele roda com dados fictícios. Trabalhe em etapas e me mostre o resultado de cada etapa antes de avançar quando eu pedir confirmação abaixo.

## 1. Contexto
- Solicitante: Leonardo Caixeita (CTO). Responsável: eu, João Vinícius. É uma prévia de dados sobre problemas de atendimento antes de ligar o Sentinela ao atendimento.
- O CTO quer saber, por recorte: tempo de resposta dos atendentes, faixas de espera (10/20/30/60 min, red flag > 1 h, sem resposta), qualidade do atendimento (LLM), temperatura e frustração do cliente, assunto da conversa, IA × humano, ranking, e por cliente o CNPJ, o telefone e o histórico completo da conversa (JSON).
- Artefato: URL privada só minha, com os dados guardados no banco do artefato e/ou nos arquivos do artefato.

## 2. Leia antes de tudo (nesta ordem)
1. `Harness/demandas/raio-x-atendimento-hyperflow/README.md` e as specs `.specs/01` a `.specs/09`. Elas são a lei desta demanda. Execute-as em ordem.
2. `Harness/demandas/raio-x-atendimento-hyperflow/agents/avaliador-qualidade-atendimento.md` (avaliador, prompt v1).
3. `.claude/skills/bigquery-finza/SKILL.md` e `.claude/skills/bigquery-finza/atendimento-mensagens.md`. Têm o mapa validado em 2026-11-18, o SQL de extração, as armadilhas e a regra de autor.
4. Para a API do Hyperflow: `N8N-AGENT/.claude/skills/hyperflow-blips/SKILL.md` (getChatMessages, headers, tenant de cada empresa).
5. O artefato atual: `Apresentacoes/executando/raio-x-atendimento_cto_19-11-2026.html`, publicado em https://claude.ai/artifact/TWzvThET43MGDXKDyuQteg. O layout está APROVADO. Não mude design, ordem dos blocos, componentes nem textos de interface, só a fonte dos dados.
6. Carregue as skills `artifact-capabilities` e `artifact-design` antes de mexer no artefato. A memória `raio-x-atendimento-hyperflow` tem o resumo das decisões.

## 3. Decisões já fechadas (não reabra)
- Recortes, sempre separados e nunca somados:
  - A = todo o Hyperflow FINZA;
  - B = Hyperflow BLIPS, só chats que passaram por uma das 20 filas de cobrança (`tb_departments_ref`, `is_cobranca_dpto=1 AND is_ia_dpto=0`). "Passou" = depto atual ou qualquer `historical_info.interactions[].department`.
- Janela: `created_at` de 2026-08-20 00:00 a 2026-11-18 23:59, America/Sao_Paulo. Volume validado: A = 22.410 chats / 4.219 clientes; B = 57.847 chats / 9.985 clientes.
- Expediente do relógio comercial: seg–sex, 08:00–18:00. O artefato mostra os dois relógios.
- Fonte híbrida (spec 02 §1):
  - BigQuery para 100% dos chats (metadados, jornada, deptos, agentes, telefone, CNPJ e mensagens da melhor fonte disponível, com a coluna `fonte`);
  - API do Hyperflow `getChatMessages`, só leitura, para a amostra do avaliador e para os chats FINZA com humano.
  - Ordem de preferência: api_getChatMessages > chat_history_completo > tb_chat_messages_amostra / reconstrucao_lastMessage.
- Avaliador LLM:
  - roda no Claude Code, numa amostra estratificada de ~3.000 protocolos (spec 04 §7, seed 20261119);
  - os tempos cobrem 100% dos protocolos;
  - roda UMA vez, no meu limite semanal.
- Score 0–100 (spec 05): pesos agilidade 25, resolução 20, clareza 15, condução 10, empatia 10, conformidade 10, desfecho 10. Tetos: sem resposta 30, red flag 60. Penalidades com no máximo −30.
- O ranking de atendentes da Visão geral lista TODOS os atendentes humanos, com nome completo (`tb_agents_ref`, por e-mail, sem homônimos), do mais rápido ao mais lento pela resposta mediana. A IA aparece como linha de referência.
- A aba "Como medimos" é só leitura. Mudanças de peso ou prompt são feitas a pedido meu no Claude Code (spec 08).

## 4. Regras duras
- BigQuery SOMENTE LEITURA (`execute_sql_readonly`, ou `bq query` sem destino). Nunca CREATE/INSERT/MERGE, tabela temporária, export para GCS nem nada que escreva no lake. Sempre filtre partição/data.
- n8n, Hyperflow e Supabase: só leitura. No MCP do Hyperflow Studio, nunca chame tool que crie, altere, publique, envie mensagem ou dispare fluxo. Leitura com ritmo moderado, retomável e com retry.
- PII:
  - telefone, CNPJ e conversas vão só para `Harness/demandas/raio-x-atendimento-hyperflow/dados/` (já está no .gitignore) e para o artefato privado;
  - nunca para o git, para o chat em massa ou para relatórios que circulem;
  - nos seus resumos para mim, mostre só contagens.
- Nada de número inventado. Toda divergência (completude de mensagens, CNPJ ambíguo, fonte aproximada, áudio não transcrito) aparece declarada no artefato, como o protótipo já prevê.
- Antes do lote do LLM, mostre a estimativa (nº de protocolos × tamanho médio das conversas, tokens aproximados) e espere meu "ok".
- Quimera:
  - não mude status nem comente sem me perguntar;
  - ao fim, proponha um comentário de entrega e a mudança para `em_validacao`;
  - descrição sempre em HTML (skills `quimera` e `quimera-nova-demanda`).
- Descobriu tabela, armadilha ou regra nova no BQ? Documente em `.claude/skills/bigquery-finza/atendimento-mensagens.md` no mesmo turno.

## 5. Plano de execução
Etapa 0. Pré-requisitos (me pergunte o que faltar):
  a) MCP do BigQuery autenticado (teste com uma query de contagem).
  b) Volume. As mensagens BLIPS somam ~1M linhas: isso NÃO cabe pelo MCP. Verifique se `bq`/`gcloud` estão instalados e autenticados para rodar `bq query --format=json --max_rows=...` só de leitura e salvar em `dados/brutos/`. Se não estiverem, me peça para rodar `! gcloud auth login` e `! gcloud auth application-default login`. Alternativa: script Node/Python com o cliente oficial do BigQuery, em modo leitura. Use o MCP só para validações e contagens.
  c) Acesso às conversas completas do Hyperflow: agora é por MCP, não por token.
     - O servidor `hyperflow-finza-production` (Hyperflow Studio, ambiente FINZA) já está registrado no escopo local deste projeto. A autenticação é pelo `/mcp`, com o login do Studio. Na tela de permissão, escolher "só leitura".
     - Antes de usar:
       - liste as tools dele e me mostre quais leem conversas/mensagens/protocolos e quais escrevem;
       - use SÓ as de leitura e proponha deny-rules no `.claude/settings.json` para as de escrita (n8n/Hyperflow são somente leitura neste workspace);
       - confirme se ele entrega o histórico completo de mensagens por protocolo (o equivalente ao getChatMessages: texto, timestamp, direção, autor humano×bot, mídia) e se cobre só o tenant FINZA.
     - Recorte B (BLIPS Cobrança): esse MCP é do ambiente FINZA. Pergunte se existe o ambiente BLIPS no Studio para registrar um segundo servidor.
     - Se não existir:
       - B fica com a fonte BigQuery (`chat_history` completo em 34% dos chats, amostra no resto), com o selo "fonte aproximada";
       - na amostra do avaliador de B, priorize os chats que já têm `chat_history` completo e declare esse viés no artefato.
  d) gcloud/bq: a conta joao.dessimoni@finza.com.br já está ativa e o `bq` consulta o `blips-bigdata`. Pode aparecer uma mensagem "Error saving Application Default Credentials ... Acesso negado" (pasta legacy_credentials com permissão quebrada). Ela não impede a consulta; ignore, ou peça para eu corrigir as permissões.

Etapa 1. Extração (spec 02): rode o SQL validado (5.1 base de chats + CNPJ, 5.2 mensagens FINZA, 5.3 mensagens BLIPS, 5.4 transcrições) e os turnos da IA FINZA (`silver_torre.org_finza_actions_interaction_logs`). Reconcilie as contagens com o retrato (spec 02 §7) e me mostre a tabela de reconciliação.

Etapa 2. API Hyperflow: monte a lista dos chats que vão para a API.
  - a amostra do avaliador (rode antes o sorteio da spec 04 §7, que depende das faixas da etapa 3 → calcule a etapa 3 primeiro com a fonte BQ e depois refine);
  - todos os chats FINZA com interação humana.
  Baixe pelas tools de leitura do MCP `hyperflow-finza-production` (ou de um MCP BLIPS, se existir) para `dados/brutos/api/<chat_id>.json`, retomável. Se o volume for grande demais para passar pelo MCP, me diga quantas chamadas seriam e proponha um ritmo. Relate quantos vieram e quantas falhas houve.

Etapa 3. Normalização e métricas (specs 02 §4–6 e 03):
  - gere `dados/protocolos/<chat_id>.json` com mensagens unificadas, autor resolvido (cliente | humano | ia | sistema) e `fonte`;
  - mensagem automática de fila = sistema;
  - IA = depto `is_ia_dpto=1` ou protocolo em `silver_torre.org_*_ai_protocols`.
  - Calcule esperas, faixas, pior espera, primeira resposta, tempo para assumir e respostas IA/humano, nos dois relógios.
  - USE AS MESMAS FUNÇÕES do artefato (`bizMin`, `faixaDe`, `metricas`, `notaAgil`, `score`): copie-as do HTML para o script, para o número do script e o da tela serem idênticos.
  - Valide a regra de autor numa amostra de 30 chats (spec 09 §1).

Etapa 4. Amostra + avaliador (spec 04):
  - sorteio estratificado (todos os red flags/sem resposta com teto de 800 por recorte, até 30 por atendente com ≥ 10 protocolos, o resto proporcional; seed 20261119);
  - copie o agente para `.claude/agents/avaliador-qualidade-atendimento.md` para usar como subagente;
  - mostre a estimativa e espere meu ok;
  - rode em pacotes de 20, até 5 subagentes em paralelo, idempotente (pula o que já tem `dados/avaliacoes/v1/<chat_id>.json`);
  - valide o JSON contra o contrato (spec 04 §5) e tente de novo 1 vez em caso de falha.

Etapa 5. Score e agregados (spec 05), com o peso amostral para extrapolar percentuais de qualidade no recorte.

Etapa 6. Banco e artefato (specs 06 e 07):
  - Arquitetura: para 80 mil protocolos, provavelmente o melhor é dividir.
    - Índice enxuto de protocolos e clientes em arquivos JSON do artefato (`assets`, ≤ 20 MiB cada, em blocos por recorte/mês).
    - Mensagens em arquivos por lote de clientes, carregados sob demanda ao abrir o cliente.
    - Banco (`db`) para `config`, `prompts`, `pesos`, `agregados` e `reprocessamentos`.
    - Faça o teste de carga da spec 06 §3 (200 protocolos) antes da carga completa. Se mudar o desenho, atualize a spec 06 e me avise.
  - Regras do banco: leitura e escrita só `admin`. Capabilities: `db`, `user`, `downloads` (exportar o JSON do cliente como arquivo) e `assets` se usar arquivos.
  - No HTML, troque SÓ o gerador de dados fictícios (`gerar`, `gerarP`, `avaliar` e dicionários de texto mock) por um carregador que monte as mesmas estruturas:
    - `DATA[rec].clientes`: `{id, rec, telefone, cnpjs[], ambiguo, nome, protocolos[]}`;
    - `DATA[rec].protocolos`: `{id, protocol, rec, cliente, assunto, tipo, depto, atendentes[], atId, inicio, msgs[{ts, autor, texto, atendente, tipo}], transf, fonte, met, aval}`;
    - `DATA[rec].ats`: `{id, nome, depto}`.
    - Timestamps: relógio de parede de Brasília em ms UTC, como no protótipo.
  - Remova o selo "Dados fictícios" e o card de protótipo. Ponha a data real da extração. Mantenha estado de carregamento (timer de 10 s) e estado vazio desenhado.
  - Publique NO MESMO artefato. Como é outra sessão, primeiro faça `Artifact action:"read"` na URL e depois publique com `url` = https://claude.ai/artifact/TWzvThET43MGDXKDyuQteg. O arquivo local continua sendo `Apresentacoes/executando/raio-x-atendimento_cto_19-11-2026.html`.
  - Depois do publish, faça uma passada de leitura em cada coleção (`ArtifactData list`) e confirme que uma leitura em nível `view` não enxerga nada.

Etapa 7. Validação (spec 09):
  - reconciliação de contagens BQ × artefato, por recorte;
  - 10 protocolos recalculados à mão;
  - prepare para mim a planilha de calibração com 20 protocolos estratificados (só ids e links internos do artefato), para eu dar as notas.
  - Até a calibração passar, o ranking mantém o selo "prévia não calibrada".

Etapa 8. Fechamento:
  - me entregue o link;
  - relate números-chave por recorte (red flag %, sem resposta %, 1ª resposta mediana/p90, score médio) e as limitações declaradas;
  - proponha o comentário de entrega no Quimera #13860;
  - atualize a memória do projeto e a skill do BQ.

## 6. Como me reportar
Em cada etapa, mostre: o que rodou, contagens, divergências e o que vem a seguir. Peça minha confirmação antes de: (1) rodar o lote do LLM, (2) mudar a arquitetura da spec 06, (3) qualquer escrita no Quimera. O resto pode seguir direto.
```
