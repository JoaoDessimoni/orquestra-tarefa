# Harness — agentes de padrão de desenvolvimento

Agentes reutilizáveis para **qualquer projeto**, independentes de negócio, linguagem, framework, banco ou infraestrutura. Cada agente é **autossuficiente**: carrega dentro dele os padrões, convenções e boas práticas do seu papel. A stack de cada projeto é escolha livre; os agentes citam as opções comuns de mercado, sem impor nenhuma.

| Agente | Papel |
|---|---|
| `agents/software-architect.md` | stack, sequência de specs, princípios de arquitetura |
| `agents/dba.md` | modelo de dados, nomenclatura de banco, migrations, performance |
| `agents/backend-dev.md` | camadas, API RPC-PT, contratos, resiliência, integrações |
| `agents/frontend-dev.md` | componentes, organização, consumo tipado da API, estados de tela |
| `agents/qa-engineer.md` | testes e critérios de aceite |
| `agents/code-reviewer.md` | auditoria pré-merge contra o padrão |
| `agents/tech-writer.md` | consistência de `docs/` e `.specs/` |

## Como usar num projeto

1. Copie `agents/*.md` para `.claude/agents/` do repositório.
2. Rode o `software-architect` primeiro: ele fecha a stack (spec `01-`) e define a sequência de specs.
3. Specs em `.specs/`, com **número + nome claro** (`01-<nome>`, `02-<nome>`…), executáveis em ordem.
4. Desvio de um padrão do agente só com aprovação, escrito na spec do projeto — aí a spec vence.
