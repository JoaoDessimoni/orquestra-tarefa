---
id: BCL02
title: Implementar tratativa de reprovados em formalização (negativa + reembolso)
frente: clara
fonte: backlog
status: a-refinar
prioridade: alta
rice:
  reach: 6
  impact: 8
  confidence: 6
  effort: 5
  score: 5.76
esforco: M
valor_negocio: alto
origem:
  pendencias: [P26]
  reunioes:
    - Backlog/reunioes/18-05-2026/2026-05-18-alinhamento-jessica-formalizacao.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
  analises:
    - Backlog/analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM13
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-08-15
dependencias: [BBT01]
bloqueia: []
riscos:
  - Comunicação automatizada de "reprovação" tem fricção jurídica — cliente pode contestar negativa, alegar que IA não tem autoridade para decisão de compliance.
  - Coleta de dados bancários por IA tem risco LGPD — dado financeiro sensível precisa governança específica.
  - Se Clara comunica negativa antes do humano avaliar caso de exceção, gera atrito desnecessário.
  - Cliente pode informar dados incorretos (PIX errado, conta de terceiro) — perda financeira se reembolso for executado sem validação.
premissas:
  - Comunicação automatizada de reprovação não tem fricção jurídica GRAVE (validar com Compliance ANTES).
  - BBT01 (raia Bitrix) estará disponível antes da implementação chegar ao final.
  - Existe template aprovado pelo Jurídico para comunicação de negativa.
  - Operador humano executa reembolso, IA NUNCA movimenta dinheiro.
tags: [clara, formalizacao, reembolso, reprovado, jessica, compliance, lgpd]
---

# BCL02 — Implementar tratativa de reprovados em formalização (negativa + reembolso)

## História de usuário

Como **cliente reprovado em formalização**,
quero **receber comunicação humana sobre a negativa e oportunidade de informar dados para reembolso**,
para **ter clareza sobre o resultado e visibilidade do processo de devolução do valor pago**.

## Contexto

Fluxo atual: cliente paga entrada → entra em formalização → análise jurídica/compliance pode reprovar → cliente fica sem retorno claro + sem visibilidade do reembolso.

**Origem da demanda:** Doc `2026-05-18_jessica_roadmap-ia-automacoes.txt`:
> "Tratativa para reprovados em formalização — Em caso de retorno negativo na etapa de 'Análise de Formalização', comunicar o cliente sobre a negativa e solicitar os dados necessários para reembolso dos valores de entrada."

**Regras anexas no doc:**
- Banco / Agência / Conta Corrente / Chave PIX
- Conta e PIX devem corresponder à **titularidade do contrato** (mesmo CNPJ)

Sinergia direta com BBT01 (raia Bitrix de reembolso) — Clara cria a entrada na raia.

## Critérios de aceite

- **CA-1** — Given cliente reprovado em "Análise de Formalização", When Clara recebe o evento de reprovação, Then envia mensagem com tom humano (não burocrático) comunicando a negativa.
- **CA-2** — Given mensagem de negativa enviada, When cliente responde, Then Clara solicita dados de reembolso (banco, agência, conta, PIX).
- **CA-3** — Given dados recebidos, When Clara valida formato básico, Then: (a) confirma que CNPJ do titular = CNPJ do contrato; (b) confirma que banco existe; (c) sinaliza se PIX bate com CNPJ.
- **CA-4** — Given dados validados, When Clara cria entrada na raia BBT01, Then payload contém: ID cliente, dados bancários, motivo da reprovação, timestamp.
- **CA-5** — Given operador humano executa reembolso, When status volta, Then Clara comunica cliente sobre conclusão (com comprovante quando possível).
- **CA-6** — Given dados inconsistentes (CNPJ não bate, PIX errado), When detectados, Then Clara escalona para humano (não tenta corrigir sozinha).

## Dependências cruzadas

- **Depende de:** BBT01 (raia Bitrix de reembolso).
- **Compliance:** templates de comunicação aceitos juridicamente.
- **Time financeiro:** fluxo de reembolso operacional.

## Observações PO

**Pontos de atenção:**

1. **Item mais arriscado da frente Clara — comunicação de NEGATIVA + COLETA DE DADO FINANCEIRO.** Não pode ser tratado como BCL01 (comprovante).
2. **Gate jurídico antes de código.** ST-1 não-negociável. Sem luz verde de Compliance/Jurídico, não escreve linha.
3. **LGPD: dado bancário é categoria especial.** Coleta via IA exige governança extra (consentimento explícito, log de acesso, retenção mínima).
4. **Reprovação automática vs com humano antes.** Sugestão PO: humano "carimba" a reprovação na raia ANTES da Clara comunicar. Reduz risco de IA comunicar erradamente.
5. **Texto da comunicação é a metade do projeto.** Cliente reprovado é cliente sensível. Mensagem mal calibrada vira escândalo nas redes.
6. **"Cliente informa PIX errado" é cenário comum.** Validação Clara + executar reembolso humano com 1-clique é mais seguro do que IA validar + executar.

## Definição de pronto

- [ ] Luz verde Compliance + Jurídico documentada
- [ ] Fluxo end-to-end em produção
- [ ] Pelo menos 5 reprovações comunicadas pela Clara
- [ ] Reembolsos executados via raia BBT01
- [ ] Nenhum incidente jurídico/LGPD em 30 dias
- [ ] Texto da comunicação versionado em local canônico

## Histórico

- 2026-05-22 — Item criado a partir de P26 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM13) consolidando reunião Jéssica formalização de 18/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 5.76. Esforço: M. CAs reescritos em G/W/T com 6 cenários. Gate jurídico (ST-1) elevado a não-negociável. Observação PO sobre risco LGPD em coleta de dado bancário e contraproposta de humano "carimbar" reprovação antes da comunicação automática.

## Notas

Validar com Compliance se a comunicação automatizada de reprovação tem fricção jurídica — não codar sem essa luz verde. Considerar fluxo "humano marca reprovação → Clara só comunica" para reduzir risco.
