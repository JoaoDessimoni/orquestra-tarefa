---
id: IAF-104
title: [Bitrix Cobrança 4.0] Mover Histórico de Atendimento para comentário ao mudar de raia
frente: bitrix-automacoes
status: cancelado
prioridade: media
fonte: jira
quimera: null
jira: IAF-104
categoria: null
deliverable_type: null
story_points: null
tipo_origem: Tarefa
responsavel: Marcos Rodrigues
criada: 2026-04-15
concluida: null
prazo: null
prazo_estimado: False
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: []
bloqueia: []
tags: [fonte-jira]
---

# IAF-104 — [Bitrix Cobrança 4.0] Mover Histórico de Atendimento para comentário ao mudar de raia

## Descrição (espelho — fonte: jira)

> Origem: Jira IAF-104 · categoria: null

Ao mudar o card de raia, os valores preenchidos nos campos da seção **Histórico de Atendimento** (Tabulação, Data acionamento, Tratativa, Motivos de Recusa, Pesquisa de Inadimplência, Especificações de acionamento, Tentativas de negociação, Observações) devem ser:

1. Copiados/movidos para um **comentário** do card, preservando o histórico de atendimentos anteriores.
2. **Apagados** dos campos originais para permitir novo preenchimento pelo analista da nova raia.

Dessa forma, o histórico fica empilhado nos comentários (evitando poluir o lado esquerdo do card) e cada mudança de raia começa com campos limpos, sem um atendimento sobrescrever o anterior.

**Fonte:** [Documento Ajustes Bitrix Cobrança 4.0](https://docs.google.com/document/d/1bV6HAAhn2NiKVPcO6eXJA-kRTjhxVCjEdXyx--viGS0)

**Consolida 3 demandas pendentes do documento:**

* Campos em formato HISTÓRICO (não sobrepor)
* Campos nos comentários (evitar poluição visual)
* Limpar histórico ao mudar de raia

---

## 📝 Template para colar no campo "Comentário" da automação

Na ação **"Adicionar comentário ao item"**, colar o texto abaixo no campo `Comentário`:

```
📋 Histórico de Atendimento — Raia anterior
🕐 Mudança registrada por {=Document:ASSIGNED_BY_ID}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Tabulação: {=Document:UF_CRM_55_1770209027}
• Data do acionamento: {=Document:UF_CRM_55_1769688201}
• Tratativa: {=Document:UF_CRM_55_1770210610}
• Negociação não realizada devido à: {=Document:UF_CRM_55_1769446757622}
• Motivo do Atraso: {=Document:UF_CRM_55_1762452751}
• Especificações de acionamento: {=Document:UF_CRM_55_1762871621}
• Tentativas de negociação: {=Document:UF_CRM_55_1762871665}
• Observações: {=Document:UF_CRM_55_1762871712}
```

### ⚙️ Recomendação de preenchimento

Em vez de colar as variáveis como texto, use o botão `...` (três pontos) ao lado do campo Comentário para abrir o seletor de campos. Selecione cada campo pelo nome amigável em português — o Bitrix insere a sintaxe correta automaticamente e resolve enums em texto legível (ex: mostra "Promessa de pagamento" em vez de "2461").

A lista de campos a inserir (na ordem):

1. **Tabulação**
2. **Data do acionamento**
3. **Tratativa**
4. **Negociação não realizada devido à** (ou "Motivos de Recusa")
5. **Motivo do Atraso** (ou "Pesquisa de Inadimplência")
6. **Especificações de acionamento**
7. **Tentativas de negociação**
8. **Observações**

### 🔧 Segunda ação: "Modificar item"

Logo após a ação de comentário, adicionar **"Modificar item"** e zerar os 8 campos acima (deixar todos vazios).

### 📍 Raias onde aplicar

As 2 ações devem ser replicadas em **todas as raias de escalonamento** onde chegam cards com histórico do analista anterior (\~26 raias):

* Suprimentos 1 a 15, 16 a 30, 31 a 60, 61+
* FIDC 1 a 15, 16 a 30, 31 a 60, 61 a 90
* Blips 1 a 15, 16 a 30, 31 a 45, 46 a 60, 61 a 90
* Ideal 1 a 15, 16 a 30, 31 a 45, 46 a 60, 61 a 90
* Finza 1 a 15, 16 a 30, 31 a 45, 46 a 60, 61 a 90
* Aguardando Retenção, Aguardando Suporte

**NÃO aplicar em:** Nova Solicitação, Receptivo Adimplente, SUP Receptivo Adimplente, stages terminais (Pagamento Concluído, Distrato, Jurídico).

**Dica:** configurar numa raia piloto, validar, depois usar "Copiar regra" → "Colar" nas demais.

## Rastreabilidade

- **Responsável:** Marcos Rodrigues
- **Jira:** IAF-104 (projeto IAF)
- **Categoria fonte:** null
- **Criada:** 2026-04-15

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=jira.