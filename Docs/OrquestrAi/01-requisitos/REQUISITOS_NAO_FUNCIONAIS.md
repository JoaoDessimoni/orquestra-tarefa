# Requisitos Não-Funcionais — OrquestrAI

> RNFs por categoria. Métricas, limites, decisões de qualidade. Última atualização: 20/05/2026.

## Fontes

- [ESCOPO_MVP.md](ESCOPO_MVP.md)
- Decisões de arquitetura (local-only, single-user, docker-compose)

---

## 1 · Performance

| ID | Métrica | Alvo MVP | Como medir |
|---|---|---|---|
| RNF-PF-01 | Tempo de cold-start (docker-compose up) | <2 min em máquina com Docker pré-instalado | Cronometrar do `up` ao primeiro 200 em `http://localhost:3000` |
| RNF-PF-02 | First Contentful Paint do Dashboard | <1.5s | Lighthouse local |
| RNF-PF-03 | Latência REST percentil 95 | <200ms (queries simples, dados locais) | Logs do FastAPI |
| RNF-PF-04 | Latência primeiro evento SSE após disparo de execução | <2s | Diff timestamp POST → primeiro evento |
| RNF-PF-05 | Throughput de eventos SSE | ≥30 eventos/s sem perda (typing rate do Claude Code) | Stress test sintético |
| RNF-PF-06 | Tempo de resposta de busca no Command Palette | <50ms para até 1000 entidades indexadas | Profiler do navegador |

## 2 · Confiabilidade

| ID | Requisito |
|---|---|
| RNF-CF-01 | Containers devem ter healthcheck no docker-compose; api espera db ready antes de subir. |
| RNF-CF-02 | Subprocess do Claude Code deve ser monitorado; em caso de crash, status da Execução vira `error` com mensagem capturada. |
| RNF-CF-03 | Em caso de queda do backend durante execução, frontend deve detectar (timeout SSE 30s sem ping) e marcar execução como `unknown` (botão "Refresh status"). |
| RNF-CF-04 | Migrations Alembic devem rodar idempotentemente em `docker-compose up`. |
| RNF-CF-05 | Volume nomeado do Postgres deve persistir dados entre restarts. |
| RNF-CF-06 | Nenhum dado de Execução deve ser perdido após `done` ser emitido (eventos persistidos no DB antes do `done`). |

## 3 · Segurança

| ID | Requisito |
|---|---|
| RNF-SG-01 | Todos os serviços bindam em `127.0.0.1`, nunca em `0.0.0.0`. |
| RNF-SG-02 | Sem auth no MVP (single-user) — mas docker-compose deve incluir comentário e variável `AUTH_ENABLED=false` para futura ativação. |
| RNF-SG-03 | `ANTHROPIC_API_KEY` (caso usada) lida só de `.env`, nunca commitada. `.env.example` no repo, `.env` no `.gitignore`. |
| RNF-SG-04 | Frontend não acessa filesystem do host — todo acesso via API. |
| RNF-SG-05 | Backend valida path de cwd antes de invocar Claude Code: deve estar dentro de `/workspace` (montado no container) — bloqueia path traversal. |
| RNF-SG-06 | Limite de execuções concorrentes: máximo **3 subprocess Claude Code** simultâneos (configurável via env `MAX_CONCURRENT_EXECUTIONS`). Acima disso, fila. |
| RNF-SG-07 | Comandos arbitrários do usuário (input de execução) são passados como argumento ao Claude Code via stdin, nunca interpolados em shell. |

## 4 · Observabilidade

| ID | Requisito |
|---|---|
| RNF-OB-01 | Logs estruturados (JSON) em stdout do backend, com campos `timestamp`, `level`, `execution_id` (quando aplicável), `event`, `message`. |
| RNF-OB-02 | Endpoint `/health` no backend retornando 200 + versão + status do DB. |
| RNF-OB-03 | Endpoint `/version` retornando build SHA + data. |
| RNF-OB-04 | Tabela `execution_events` serve como log de auditoria — não-truncável no MVP. |
| RNF-OB-05 | Frontend logs erros em `console.error` com `errorId` único; backend retorna `error_id` em respostas 5xx para correlação. |

## 5 · Usabilidade / Acessibilidade

| ID | Requisito |
|---|---|
| RNF-UX-01 | Todas as views devem ser navegáveis por teclado (Tab, Shift+Tab, Enter, Esc). |
| RNF-UX-02 | Atalhos globais documentados em tela de Help (`?`): Cmd+K (palette), 1-9 (views), Esc (fechar modal), `/` (busca). |
| RNF-UX-03 | Contraste mínimo WCAG AA (texto principal sobre fundo). |
| RNF-UX-04 | Sem dependência de internet pública para uso (fonts via CDN são opcionais; fallback system fonts). |
| RNF-UX-05 | Suporte mínimo: Chrome ≥120, Edge ≥120, Firefox ≥120 (últimos 2 anos). Safari não testado. |

## 6 · Compatibilidade

| ID | Requisito |
|---|---|
| RNF-CP-01 | Docker Engine ≥24 e Docker Compose v2. |
| RNF-CP-02 | Sistema deve rodar em Windows 11 (WSL2), macOS 13+, Ubuntu 22+. |
| RNF-CP-03 | Frontend single-page renderiza em viewport ≥1280px (desktop). |
| RNF-CP-04 | Claude Code CLI versão ≥ atual usada pelo João (verificada em Settings). |

## 7 · Manutenibilidade

| ID | Requisito |
|---|---|
| RNF-MN-01 | Backend cobertura de testes mínima 60% para módulo `runner` (execução de agentes) e 40% para CRUDs. |
| RNF-MN-02 | Tipos compartilhados entre back/front via OpenAPI schema (FastAPI gera, frontend consome via `openapi-typescript`). |
| RNF-MN-03 | Lint obrigatório: `ruff` (backend), `eslint`+`prettier` (frontend). Pre-commit hook configurado. |
| RNF-MN-04 | Sem comentários inline desnecessários — código auto-documentado (regra herdada do CLAUDE.md). |
| RNF-MN-05 | Migrations Alembic sempre reversíveis (downgrade implementado). |

## 8 · Portabilidade / Backup

| ID | Requisito |
|---|---|
| RNF-PT-01 | Comando `docker-compose exec api python -m orquestr_ai.backup` gera dump SQL em `./backups/<timestamp>.sql`. |
| RNF-PT-02 | Comando `restore <arquivo>` reaplica dump em DB vazio. |
| RNF-PT-03 | Export `.md` em Gestao/ funciona como segundo backup natural (textual). |

## 9 · Custo

| ID | Requisito |
|---|---|
| RNF-CT-01 | Sistema **não consome créditos Anthropic diretamente** — usa Claude Code CLI do usuário (sua licença/assinatura). |
| RNF-CT-02 | Estimativa de custo mostrada é informacional (com base em pricing table local configurável); não bloqueia execução. |
| RNF-CT-03 | Sem custos de hospedagem (local-only). |

## 10 · Limites operacionais (MVP)

| Recurso | Limite | Justificativa |
|---|---|---|
| Execuções concorrentes | 3 | RAM e CPU local; subprocess pesado |
| Tamanho do prompt do sistema | 50.000 chars | Acomoda agentes ricos sem stress no DB |
| Tamanho do input de execução | 10.000 chars | Inputs típicos são curtos |
| Eventos por execução | 50.000 | Cobre execuções longas com tool use intenso |
| Agentes total | 200 | Single-user, biblioteca pessoal |
| Skills total | 100 | Single-user |
| Análises retidas | 2.000 | Several anos de trabalho |
| Tamanho do volume Postgres | 5 GB | Margem para histórico textual |

<!-- TODO: revisar limites após primeiros 3 meses de uso real -->
