---
id: BCL01
title: Implementar solicitação e recebimento de comprovantes de endereço pela Clara
frente: clara
fonte: backlog
status: em-refinamento
prioridade: alta
rice:
  reach: 7
  impact: 7
  confidence: 7
  effort: 4
  score: 8.575
esforco: M
valor_negocio: alto
origem:
  pendencias: [P25]
  reunioes:
    - Backlog/reunioes/18-05-2026/2026-05-18-alinhamento-jessica-formalizacao.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
  analises:
    - Backlog/analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM12
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-07-30
dependencias: []
bloqueia: []
riscos:
  - Plataforma Blips pode não ter endpoint maduro para inclusão de comprovante por humano via integração.
  - Regras de comprovação podem mudar durante a implementação (compliance frequentemente ajusta).
  - Cliente envia foto ruim/incompleta → loop de re-solicitação pode ser irritante.
  - **Construção Civil** tem regra adicional (NF, fachada) — escopo pode estourar se cobrirmos todos os segmentos no primeiro release.
premissas:
  - Plataforma Blips tem endpoint disponível para inclusão de comprovante por humano.
  - Regra vigente (3 endereços, 30 dias) é estável o suficiente para implementar.
  - Operadores de validação humana têm capacidade para absorver volume na primeira fase.
tags: [clara, formalizacao, comprovante, endereco, jessica]
---

# BCL01 — Implementar solicitação e recebimento de comprovantes de endereço pela Clara

## História de usuário

Como **operador de formalização**,
quero **que Clara solicite e receba comprovantes de endereço, transferindo para validação humana**,
para **eliminar trabalho repetitivo de solicitação manual mantendo decisão de validação com pessoa**.

## Contexto

Hoje a solicitação de comprovantes de endereço é processo manual humano. Jéssica trouxe na reunião de 18/05 (14h) que Clara assume o papel de solicitar e receber, mantendo o humano para validar e incluir na plataforma Blips. Princípio não-negociável: **IA facilitadora, humano decisor**.

**Origem da demanda:** Doc `2026-05-18_jessica_roadmap-ia-automacoes.txt`:
> "Solicitação e recebimento de comprovantes de endereço — Solicitar os comprovantes conforme a regra vigente. Após o recebimento, transferir para validação humana e inclusão na Plataforma Blips."

**Regras anexas no mesmo doc:**
- 3 endereços (empresa, residencial responsável, entrega/instalação)
- Comprovantes ≤30 dias (água, luz, internet, fatura cartão)
- Não aceita escaneado/fotocópia/terceiros (exceto pais/cônjuge)
- **Construção Civil tem regra adicional:** foto fachada + 3 NFs últimos 3 meses

## Critérios de aceite

- **CA-1** — Given cliente em etapa de coleta de comprovantes, When Clara é acionada, Then envia mensagem solicitando os 3 comprovantes conforme regra vigente (com exemplos visuais aceitos/recusados).
- **CA-2** — Given cliente envia arquivo, When Clara recebe, Then valida formato básico (imagem/PDF legível, não é escaneado óbvio, não é cartão CNPJ ou NF tratada como comprovante).
- **CA-3** — Given todos os comprovantes recebidos, When Clara identifica completude, Then transfere para validação humana com payload estruturado (3 arquivos + metadados).
- **CA-4** — Given validação humana realizada na plataforma Blips, When status volta, Then Clara confirma com cliente (aprovado → próxima etapa / recusado → re-solicita item específico).
- **CA-5** — Given segmento Construção Civil, When Clara identifica, Then solicita ITENS ADICIONAIS (foto fachada + 3 NFs) — se escopo for incluído no MVP.

## Dependências cruzadas

- **Depende de:** Plataforma Blips (endpoint de inclusão por humano).
- **Compliance:** texto + regras + critérios de validação.

## Observações PO

**Pontos de atenção:**

1. **Cliente irritar é o risco silencioso.** Solicitar comprovante via IA pode ter taxa de abandono maior que humano se Clara for chata. ST-5 (limite de re-solicitações) é crítico.
2. **Escopo do MVP é a decisão mais importante.** Cobrir todos os segmentos (Construção Civil) no primeiro release infla 30%+ o esforço. Sugestão PO: MVP só genérico, Construção Civil v2.
3. **"Validação humana" é interface crítica.** Não basta enviar arquivo — precisa enviar contexto (quem é o cliente, qual segmento, qual regra aplicável). Senão humano fica caçando info.
4. **Loop de feedback** — quando humano recusa comprovante, Clara precisa explicar ao cliente POR QUE foi recusado, não só "envia de novo". Texto pré-aprovado por Compliance.
5. **Não é só Clara — é integração Clara + Operador + Plataforma Blips.** Item mais complexo do que parece no nome.

## Definição de pronto

- [ ] Fluxo Clara → solicitar → receber → transferir em produção
- [ ] Operadores de validação humana treinados
- [ ] Pelo menos 10 casos reais fluindo end-to-end
- [ ] Métricas coletadas por 30 dias
- [ ] Taxa de envio na primeira tentativa documentada como baseline

## Histórico

- 2026-05-22 — Item criado a partir de P25 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM12) consolidando reunião Jéssica formalização de 18/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 8.575. CAs reescritos em G/W/T. Decisão de escopo MVP (genérico vs Construção Civil) marcada como ST-1 não-negociável. Observação PO inclui risco de cliente irritar (loop de re-solicitação) e necessidade de contexto na transferência humana.

## Notas

Documentar fluxo end-to-end com cliente exemplo antes de codar — alinha expectativa de comportamento da Clara com Jéssica e Compliance. Construção Civil em v2.
