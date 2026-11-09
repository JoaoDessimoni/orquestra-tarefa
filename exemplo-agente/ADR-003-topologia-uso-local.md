# ADR-003 — Topologia de execução, flag USO_LOCAL e MCP gerenciado pelo app

> Consolida a decisão D6 (runner) + a estratégia de MCP. Status: ACEITO · Junho/2026.
> Depende de ADR-001, ADR-002, VISAO_PRODUTO_v2, CONVENCOES.

> 🟡 **Nota de status (reconciliação C-docs):** o **Modo Local** (`USO_LOCAL=true` → `DriverCli`) está
> implementado e verificado. O **Modo Servidor** (`DriverApi`, Anthropic SDK) existe apenas como **stub**
> que levanta `IntegracaoExternaErro` (previsto p/ C6d). O **MCP gerenciado pelo app** (C6c) está
> implementado: credencial **cifrada**, dois níveis (habilitar/desabilitar vs desativar/reativar), fila de
> aprovação Time↔MCP (`tbl_times_mcps`) e enforcement no disparo — ver `.specs/02-contratos/aparato.md §3`.
>
> 🟡 **Nota de status — Modo Servidor não é executável hoje:** o `apps/api/Dockerfile` **não instala
> Node nem o Claude Code CLI** (comentário explícito no Dockerfile reserva isso para o "C3"). Quem
> seleciona o driver é `runner/MotorExecucao.py::obter_driver` (`DriverCli() if uso_local else
> DriverApi()`), e `DriverApi` é stub. Consequência: subir a `api` em container com `USO_LOCAL=false`
> levanta uma API que responde CRUD mas **não executa agente**. Agravante: `docker-compose.yml` **força
> `USO_LOCAL: "false"`** no serviço `api` — o `api` do compose está exatamente nesse estado hoje. Modo
> Servidor real (imagem com Node/CLI ou `DriverApi` funcional) é trabalho futuro (C6d). O campo
> `RUNNER_DRIVER`/`Configuracoes.runner_driver` é **efetivamente morto**: não decide driver nenhum, só
> aparece num log em `Main.py`; quem decide é `USO_LOCAL`.

## Contexto
O runner é o Claude Code. O uso **imediato** é local, para o trabalho na Blips: a execução precisa
ser o **terminal real** do João (Windows, `claude` logado por assinatura, MCP configurado) — chave de
API (`setup-token`) não serve. O uso **futuro** é subir a aplicação num servidor pessoal como
orquestrador de tarefas internas — aí precisa ser 100% Docker, sem depender da máquina dele, chamando
a IA via **API**. Uma flag concilia os dois sem reescrever o motor.

## Decisão — flag `USO_LOCAL` define dois modos

| | `USO_LOCAL=true` — Modo Local | `USO_LOCAL=false` — Modo Servidor |
|---|---|---|
| Onde a api roda | **host Windows** (fora do container) | **container** (100% Docker) |
| Stores | postgres+neo4j no Docker | postgres+neo4j no Docker |
| Driver | **DriverCli** — `claude -p` (assinatura, terminal real) | **DriverApi** — Anthropic API (`ANTHROPIC_API_KEY`) |
| MCP | app escreve `.mcp.json` no workspace; CLI lê (sem `--bare`) | MCP remoto via `mcp_servers` (URL) na chamada da API |
| Conexão DB | `localhost:<portas publicadas>` (15432 / 7687) | nomes de serviço (`postgres:5432` / `neo4j:7687`) |
| Uso | trabalho diário do João, **agora** | deploy em servidor, **depois** |

### Abstração de driver
Interface comum `Driver` (contrato de eventos canônicos: token/tool_call/tool_result/error/done).
`DriverCli` implementado **primeiro** (C6a). `DriverApi` implementado **depois** (C6d), quando o deploy
em servidor for feito. Enquanto não existir, `USO_LOCAL=false` retorna erro claro ("Modo Servidor
indisponível nesta versão"), não um crash.

### MCP gerenciado pela aplicação (não mais ambiente do Claude)
`tbl_mcps` é a **fonte da verdade** dos MCPs: transporte, URL, headers/chave, e vínculo a times/agentes.
Cada driver traduz essa config para seu mecanismo:
- DriverCli → gera `.mcp.json` no workspace da execução (ou `claude mcp add-json`), sem `--bare`.
- DriverApi → passa os servidores como `mcp_servers` (URL) na chamada.
Uma tela (frontend, futura) permite conectar MCPs, contextualizar e vincular a times de agentes.

### Restrição de transporte (consequência técnica)
- **stdio** (processo local) → funciona **só no Modo Local**.
- **HTTP/remoto** (URL + chave) → funciona **nos dois modos**.
- Portanto, MCP que precise rodar no Modo Servidor **deve ser HTTP/remoto**. O Quimera, para uso no
  servidor, precisa de endpoint HTTP + chave (o "conectar por tela com chave").

### Segurança de credenciais de MCP
Chaves de MCP são segredo. Nunca em log (aplicar `sanitizeSensitiveData`). No Modo Servidor viram
segredo de deploy (variável de ambiente / cofre), não plaintext versionado.

## Consequências
- No **Modo Local** a api **sai do container** e roda no host (uv + Python 3.12), conectando aos stores
  pelas portas publicadas. Um script `subir-local.ps1` sobe os stores no Docker e inicia a api no host.
  Troca-se o "tudo num `docker compose up`" por "stores no Docker + api no host" — é o custo que a
  restrição do terminal real exige.
- No **Modo Servidor** volta a ser tudo-Docker (o `docker compose up --build` do C1b), com a api em
  container e o DriverApi.
- O roteamento de modelo (ADR-002) vale nos dois: CLI via `--model`; API via parâmetro `model`.

## Alternativas rejeitadas
- **CLI Linux dentro do container + credenciais montadas** e **container de runner dedicado**: são
  *réplicas* do terminal, dependem de MCP-em-container (não-provado) e, sobretudo, **não são o terminal
  real** que o requisito de uso na Blips exige. Ficam descartadas para o Modo Local.

## Fatiamento de implementação
- **C6a** — flag USO_LOCAL + topologia dupla + abstração Driver + **DriverCli** + streaming SSE +
  persistência de execução. Usa o MCP **ambiente** do Claude (Quimera já funciona) por ora.
- **C6b** — roteamento de modelo (auto-route híbrido + cadeado + piso).
- **C6c** — MCP gerenciado pelo app (campos de conexão em tbl_mcps + vínculo a times + provisionar
  `.mcp.json`) + base da tela.
- **C6d** — DriverApi + `USO_LOCAL=false` (deploy servidor).