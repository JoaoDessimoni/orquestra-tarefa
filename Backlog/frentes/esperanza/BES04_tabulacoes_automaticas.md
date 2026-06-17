---
id: BES04
title: Criar tabulações automáticas via IA — categorizar interações Esperanza
frente: esperanza
fonte: backlog
status: em-refinamento
prioridade: media
rice:
  reach: 7
  impact: 6
  confidence: 6
  effort: 5
  score: 5.04
esforco: M
valor_negocio: medio
origem:
  pendencias: [P19]
  reunioes:
    - Backlog/reunioes/18-05-2026/2026-05-18-alinhamento-jessica-revisao-geral.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
    - Backlog/solicitacoes/Perguntas IA - 2026_05_18 14_57 GMT-03_00 - Anotações do Gemini.txt
  analises:
    - Backlog/analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM03
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-Q3
dependencias: [BES05]
bloqueia: []
riscos:
  - Taxonomia de tabulação humana pode ser inconsistente entre operadores — usar como ground-truth da IA replica o erro.
  - Classificador IA pode parecer acurado em validação amostral mas falhar em casos raros — risco de leitura enviesada de "tipos de chamado".
  - Investimento em tabulação automática só faz sentido se tabulação humana de fato é usada para algo — questionar se relatórios atuais de tabulação geram decisão real.
premissas:
  - Existe taxonomia humana de tabulação minimamente estável que pode ser tomada como ponto de partida.
  - Modelo IA atual (Claude Sonnet 4) tem acurácia >80% em classificação de conversa após few-shot.
  - Jéssica/operação têm tempo de validar 100-200 conversas tabuladas para calibragem.
tags: [esperanza, tabulacoes, jessica, indicadores]
---

# BES04 — Criar tabulações automáticas via IA — categorizar interações Esperanza

## História de usuário

Como **gestor de cobrança**,
quero **que cada interação Esperanza seja categorizada automaticamente por tipo de tabulação**,
para **gerar indicadores de tipos de chamado e motivos de objeção sem tabulação manual**.

## Contexto

Esperanza não categoriza sistematicamente as interações que conduz. Sem tabulação, não há indicador operacional de "tipos de chamado", "motivos de objeção", "padrões de conversa". Time de cobrança precisa desse dado para evoluir scripts e identificar onde a IA falha mais.

**Origem da demanda:** Doc `2026-05-18_jessica_roadmap-ia-automacoes.txt`:
> "Criação de tabulações automáticas via IA — Mapear os atendimentos realizados pela IA, categorizando as interações por tipo de tabulação, permitindo maior controle operacional e geração de indicadores."

**Origem secundária:** Doc `Perguntas IA - 18/05` — Leandro identificou problema de tagueamento: "Sistema de funil e tags utiliza modelo padrão enquanto cliente não define configurações personalizadas". Mostra que a infra existe mas não está calibrada.

## Critérios de aceite

- **CA-1** — Given taxonomia de tabulação consolidada com Jéssica, When publicada em local canônico, Then é versionada e tem definição operacional para cada categoria (não só nome).
- **CA-2** — Given conversa Esperanza encerrada, When pós-processamento roda, Then registro contém campo `tabulacao` não-nulo em >85% dos casos.
- **CA-3** — Given amostra aleatória de 200 conversas tabuladas pela IA, When operador humano revisa, Then concordância >75% (kappa de Cohen).
- **CA-4** — Given dashboard de tabulações publicado, When Jéssica e time visualizam, Then identificam pelo menos 3 padrões/insights acionáveis em <30 minutos.
- **CA-5** — Given calibragem em produção por 30 dias, When número de "outros/desconhecido" >20%, Then taxonomia é revista (não é problema da IA, é da taxonomia).

## Dependências cruzadas

- **Depende de:** BES05 (discovery) — entender o domínio antes de classificar.
- **Sinergia:** BES03 (mesmo esquema de storage).
- Possível dependência de BAU01 (MCPs) se classificador precisar consultar plataformas.

## Observações PO

**Pontos de atenção:**

1. **Taxonomia humana já existente é o ponto mais frágil.** Se ela é inconsistente entre operadores, IA vai replicar o caos. ST-1 precisa avaliar consistência antes de adotar como ground-truth.
2. **"Tabulação automática" é demanda recorrente em cobrança — mas o ROI depende de uso real.** Questionar Jéssica: quem hoje consome relatório de tabulação humana? Se ninguém consome, automatizar é desperdício.
3. **Classificador IA dentro da Esperanza vs externo** — decisão de arquitetura. Externo (agente tagueador) é mais auditável; interno (Esperanza classifica no encerramento) é mais barato. Sinalizar trade-off.
4. **Sistema atual de tag existe mas tagueia mal.** Antes de propor novo, entender por que o atual falha (descrições vagas conforme Leandro indicou). Pode ser fix de prompt, não item de backlog inteiro.

## Definição de pronto

- [ ] Classificador em produção
- [ ] Taxonomia canônica versionada
- [ ] Dashboard publicado
- [ ] Pelo menos 1000 conversas tabuladas validadas com Jéssica
- [ ] Kappa de Cohen >0.7 em amostra de 200

## Histórico

- 2026-05-22 — Item criado a partir de P19 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM03) consolidando reunião revisão geral com Jéssica de 18/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. CAs reescritos em G/W/T. Adicionada referência ao problema atual do tagueador (Doc Perguntas IA 18/05) — antes de criar novo classificador, investigar por que o atual falha. RICE: 5.04 (alta). Subtarefas detalhadas. Observação PO incluída sobre risco de replicar taxonomia inconsistente.

## Notas

Levantar com Jéssica QUEM consome relatório de tabulação humana hoje e PARA QUÊ — se ninguém usa, automatizar é desperdício de esforço.
