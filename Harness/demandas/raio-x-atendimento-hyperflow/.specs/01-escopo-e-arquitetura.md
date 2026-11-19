# 01 · Escopo e arquitetura — Raio-X do atendimento Hyperflow

> Demanda: Raio-X do atendimento Hyperflow — tempo de resposta, qualidade e ranking (FINZA + Cobrança BLIPS).
> Solicitante: Leonardo Caixeita (CTO). Responsável: João Vinícius (Supervisor IAF).
> Entrega única, completa: **2026-11-19**. Reprocessamento sob demanda depois.

## 1. Por que existe

O CTO quer uma prévia de dados sobre problemas de atendimento antes de ligar o Sentinela ao atendimento:
- cliente sem resposta;
- quanto tempo o cliente espera;
- quem atende bem e quem atende mal;
- de que assunto o cliente fala.

## 2. Recorte (regra dura)

| Recorte | Universo | Rótulo no artefato |
|---|---|---|
| **A · FINZA** | Todo o Hyperflow do tenant FINZA, todos os departamentos | `FINZA` |
| **B · BLIPS Cobrança** | Hyperflow do tenant BLIPS, só chats que **passaram** por uma das **20 filas de cobrança** (`is_cobranca_dpto=1`, sem IA — lista na spec 02 §2) | `BLIPS · Cobrança` |

Volume na janela: A = 22.410 chats / 4.219 clientes · B = 57.847 chats / 9.985 clientes.

- **Janela:** últimos 90 dias, de **2026-08-20 a 2026-11-18** (`America/Sao_Paulo`). Pode ser ampliada depois.
- **Separação:** os recortes nunca se somam num número único. Comparar é sempre lado a lado.
- **Unidade do atendimento:** `chat_id`. O `protocol` serve para busca e não é único.
- **Cliente:** telefone canônico dentro do recorte. O CNPJ é metadado vindo da ponte CRM e pode ser ambíguo.

## 3. Entregáveis

1. **Artefato privado** (claude.ai, sem compartilhamento), com três áreas: Dashboard, Protocolos e mensagens, Metodologia.
2. **Banco de dados do artefato** com protocolos, mensagens, métricas, avaliações, prompts e pesos. Detalhe na spec 06.
3. **Avaliador de qualidade:** agente para o Claude Code em `agents/avaliador-qualidade-atendimento.md`. Roda uma vez em lote, no limite semanal do João, e de novo só quando houver pedido de reprocessamento.
4. Estas specs, anexadas à demanda no Quimera.

## 4. Fluxo de dados

```
BigQuery (read-only) ──► extração por recorte (spec 02) ──► dados/ local (gitignored, PII)
                                                         │
                         métricas de tempo (spec 03) ◄───┘
                                                         │
          lote do avaliador no Claude Code (spec 04) ◄───┘  → avaliacoes/*.json
                                                         │
             score + ranking (spec 05) ◄─────────────────┘
                                                         │
     carga no banco do artefato via ArtifactData (spec 06) ──► artefato (spec 07)
                                                         ▲
   pedido de reprocessamento gravado pela página (spec 08) ┘
```

## 5. Stack (escolha desta demanda)

| Camada | Escolha | Motivo |
|---|---|---|
| Fonte | **Híbrida**: BigQuery `blips-bigdata` (read-only) para 100% dos chats + API GraphQL do Hyperflow (`getChatMessages`, só leitura) para a amostra do avaliador e os chats FINZA com humano (spec 02 §1) | O BQ não tem log completo de mensagens (FINZA ~50%, BLIPS completo em 34%) |
| Escopo do LLM | Tempos em **100%** dos chats; avaliador em **amostra estratificada ~3k** (spec 04 §7) | 100% (~65k conversas) não cabe no limite semanal |
| Processamento | Scripts locais (Node ou Python) no workspace, saída em `dados/` | Rodam uma vez e repetem igual |
| LLM | Claude Code (subagentes com o agente avaliador), no CLI do João | Sem chave de API, sem infraestrutura nova |
| Banco | Banco do artefato (`db`), mais arquivos JSON no próprio artefato (`assets`) para conversas grandes | URL privada, persistente, Claude lê e escreve |
| UI | Página HTML única no artefato, JS vanilla, gráficos em SVG próprio | Padrão dos artefatos do workspace |

## 6. Sequência de execução

| # | Spec | Saída |
|---|---|---|
| 01 | este arquivo | escopo fechado |
| 02 | fontes BigQuery | SQL de extração validado, `dados/brutos/` |
| 03 | métricas de tempo | `dados/metricas/` (esperas, faixas, flags) |
| 04 | avaliador | `dados/avaliacoes/<versao>/` |
| 05 | score e ranking | `dados/score/` |
| 06 | modelo de dados | coleções populadas no banco do artefato |
| 07 | telas | artefato publicado |
| 08 | reprocessamento | botão, fila e rotina prontos |
| 09 | validação e aceite | checklist assinado |

## 7. Fora do escopo

- Ligar o Sentinela ou qualquer agente em produção.
- Escrever no BigQuery, no n8n ou no Hyperflow.
- Avaliação individual de desempenho de pessoas. O ranking de atendentes é uma prévia não calibrada.
- Departamentos da BLIPS além de Cobrança.

## 8. Riscos

- **PII:** telefone, CNPJ e conversas saem do lake para o banco do artefato. O artefato fica privado. Compartilhar com o CTO exige validação prévia.
- **Áudio sem transcrição:** onde não houver texto, a análise daquele trecho fica marcada como "áudio não transcrito".
- **Autoria IA × humano:** precisa ser validada em amostra (spec 02 §5) antes de qualquer comparação.
- **Limites do banco do artefato:** 256 KiB por documento e cotas por coleção. A estratégia está na spec 06.
- **Limite semanal do Claude:** o lote consome a cota do João. Estimar o custo antes de rodar (spec 04 §7).
