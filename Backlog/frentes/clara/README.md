# Frente — Clara (Formalização)

Itens relacionados à agente IA **Clara**, responsável pela formalização de propostas Finza.

**Sponsor padrão:** Jéssica (Gerente Cobrança)
**ID prefix:** `BCL##`

## Escopo

- Solicitação e recebimento de comprovantes de endereço
- Tratativa de propostas reprovadas (comunicação de negativa + coleta de dados de reembolso)
- Envio e acompanhamento de biometria
- Integração com plataforma Blips e Bitrix

## Princípio operacional não-negociável

**Clara é facilitadora. Humano é decisor.** Em nenhum fluxo Clara aprova/reprova/executa decisão crítica — apenas conduz a conversa, coleta dados, transfere para validação humana.

## Regras operacionais de referência

Detalhadas em `Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt`:
- Comprovação de endereço (3 endereços, 30 dias)
- Construção civil (foto fachada + 3 NFs)
- Reembolso (banco, agência, conta, PIX — CNPJ do titular)

## Fora de escopo

- Aprovação/reprovação de crédito (decisão humana fora do sistema IAF)
- Cobrança pós-formalização (vai para Esperanza)
