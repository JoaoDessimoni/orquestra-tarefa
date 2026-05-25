# Frente — Esperanza (Renegociação)

Itens relacionados à agente IA **Esperanza**, responsável pela cobrança digital e renegociação de dívidas via WhatsApp.

**Sponsor padrão:** Jéssica (Gerente Cobrança)
**ID prefix:** `BES##`

## Escopo

- Homologação do fluxo de renegociação com transferência para humano
- Imputação direta de renegociação no Módulo Financeiro
- Mapeamento de volume de transferências IA→humano
- Tabulações automáticas via IA
- Discovery operacional/técnico (escopo, casos atendidos, domínio)
- Resgate de relatório pré-Torre (comparativo histórico)

## Contexto técnico

Detalhamento completo em `Backlog/contexto/esperanza_agent_overview.md`.

## Stack operacional

- LLM: Claude Sonnet 4 (default), configurável por org
- 27 ferramentas MCP para acesso direto à base da Torre
- 5 camadas de system prompt (compliance imutável → cenário)
- Versionada como código (draft → published → archived)

## Fora de escopo

- Formalização (vai para Clara)
- SAC/atendimento N1 (vai para Valentina)
- Configuração de canais multi-tenant (vai para Torre)
