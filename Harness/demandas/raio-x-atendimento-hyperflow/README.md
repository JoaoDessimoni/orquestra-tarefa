# Raio-X do atendimento Hyperflow

Tempo de resposta, qualidade e ranking dos atendimentos. Recortes: **FINZA** (Hyperflow inteiro) e **BLIPS · Cobrança**, sempre separados. Janela de 90 dias (2026-08-20 → 2026-11-18). Pedido do CTO, como prévia de dados antes de ligar o Sentinela ao atendimento.

| Arquivo | Conteúdo |
|---|---|
| `.specs/01-escopo-e-arquitetura.md` | recorte, entregáveis, fluxo, stack, sequência |
| `.specs/02-fontes-bigquery.md` | tabelas, colunas, SQL de extração por recorte, autoria IA × humano, áudio, CNPJ |
| `.specs/03-metricas-tempo-resposta.md` | espera por turno, faixas 10/20/30/60, red flag, relógio comercial × corrido |
| `.specs/04-agente-avaliador-qualidade.md` | contrato do avaliador, rubrica, saída JSON, lote no Claude Code |
| `.specs/05-score-e-ranking.md` | pesos, fórmula 0–100, tetos, penalidades, rankings |
| `.specs/06-modelo-de-dados.md` | coleções do banco do artefato, limites, PII, carga |
| `.specs/07-artefato-telas.md` | Dashboard, Protocolos e mensagens, Metodologia, filtros |
| `.specs/08-reprocessamento.md` | pesos ao vivo, teste de prompt, fila e rotina de reprocessamento |
| `.specs/09-validacao-e-aceite.md` | reconciliação, calibração, definição de pronto |
| `agents/avaliador-qualidade-atendimento.md` | agente do Claude Code usado no lote (prompt v1) |
| `dados/` | **gitignored**: extrações, métricas, avaliações (PII) |

Executar as specs em ordem. Desvio de padrão só com aprovação, escrito na spec.
