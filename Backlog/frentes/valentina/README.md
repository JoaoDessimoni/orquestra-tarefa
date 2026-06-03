# Frente — Valentina (SAC)

Itens relacionados à agente IA **Valentina**, responsável pelo atendimento SAC/N1 da Finza (suporte ao cliente final).

**Sponsor padrão:** Jéssica (Gerente Cobrança) / Diretoria
**ID prefix:** `BVA##`

> **Frente ZERADA em 2026-06-02.** Todos os itens (BVA01–BVA05) foram cancelados. Motivo: a Valentina já está preparada para receber a carteira Rhino e o multi-org (validado com o dev João Pedro), então as demandas que tratavam disso perderam objeto. Os `.md` foram reduzidos a stubs de cancelamento (ID e histórico mínimo preservados). **Novas demandas da frente Valentina serão criadas posteriormente.** O escopo abaixo descreve o que a frente cobria — referência histórica.

## Escopo

- Roteamento por originador (urgente: Rhino → suporte Rhino)
- Identificação automática de originador na entrada
- Base de contexto consolidada (jornada Finza completa)
- Mapeamento de demandas típicas por originador
- Inventário de agentes IA por número (Finza vs Blips)

## Contexto

Valentina hoje opera com prompt momentâneo (sem base de conhecimento consolidada). A frente prioriza estruturar contexto persistente + roteamento inteligente, antes de expandir funcionalidades.

## Fora de escopo

- Cobrança (vai para Esperanza)
- Formalização (vai para Clara)
- Integrações de canal/multi-tenant (vai para Torre)
