# 08 · Reprocessamento

São três tipos, cada um com custo diferente.

| O que mudou | Precisa de LLM? | Onde roda | Quanto demora |
|---|---|---|---|
| **Pesos**, tetos, penalidades, tabela de agilidade, faixas, expediente | Não | Na página (JS, spec 05) | Instantâneo |
| **Prompt**, testado em até 5 protocolos | Sim (`sample`) | Na página, com a cota do usuário | Segundos |
| **Prompt** em todos os protocolos | Sim | Claude Code, no CLI do João (spec 04 §7) | Lote |

## 1. Por que o lote não roda na página

A chamada ao Claude pela página tem limite de taxa e rejeita uma enxurrada de chamadas (`rate_limited`). A plataforma também proíbe chamar em loop. Milhares de protocolos não cabem nesse caminho. A página serve para **testar** o prompt e **registrar o pedido**. O lote fica no Claude Code.

## 2. Fluxo do reprocessamento completo

1. Na Metodologia, o João salva o prompt `vN`, testa em até 5 protocolos e clica em "Reprocessar com vN".
2. A página grava `reprocessamentos/{id}`: `{tipo:"prompt", versao:"vN", escopo:"tudo"|{filtros}, status:"pendente", solicitado_em}`. A página mostra a instrução: *"No Claude Code, peça: reprocessa o Raio-X do atendimento"*.
3. No Claude Code, a sessão:
   1. lê os pedidos `pendente` via `ArtifactData`;
   2. muda o status para `processando`;
   3. baixa `prompts/vN` para `dados/prompts/vN.md`.
4. Mostra a estimativa de custo e espera o "ok". Roda o lote da spec 04 §7 com `versao_prompt = vN`. É idempotente: pula o que já tem `vN`.
5. Recalcula o score (spec 05) e carrega `avaliacoes/{chat_id}_vN`, `protocolos` (com o resumo da avaliação vN), `atendentes` e `agregados`.
6. Atualiza `progresso` a cada pacote e termina com `concluido`, `prompt_ativo = vN` e `concluido_em`.
7. A página acompanha o status ao vivo (`onSnapshot`) e mostra uma barra de progresso.

## 3. Comparação entre versões

As avaliações de versões anteriores são mantidas (`avaliacoes/{chat_id}_{versao}`). A Metodologia mostra, por versão:
- score médio;
- distribuição;
- os 10 protocolos que mais mudaram de nota.

Trocar a versão ativa sem reprocessar só é possível para versões já processadas.

## 4. Reextrair dados (janela nova ou maior)

A janela é ampliada **fora** da página:
1. Pedir no Claude Code: "amplia o Raio-X para <período>".
2. Roda as specs 02 → 03 → 04 → 05 → 06 só para os chats novos. Os existentes são pulados por id.
3. Atualiza `config/geral.recortes.janela`.

## 5. Rotina "reprocessa o Raio-X do atendimento" (para o Claude Code)

```
1. ArtifactData list reprocessamentos where status == "pendente"   (nenhum → avisa e para)
2. update status=processando
3. tipo == pesos  → só recalcula score/agregados (sem LLM) e carrega
   tipo == prompt → baixa prompts/{versao} → estima custo → pede ok → lote spec 04 → score → carga
4. update status=concluido, progresso=100, concluido_em; config/geral.prompt_ativo = versao
5. relata: avaliados / pulados / erros / delta de score médio por recorte
```
