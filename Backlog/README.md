# Backlog — Squad IAF

Pasta-raiz do backlog estratégico do supervisor IAF (João Vinícius).

## Propósito

Consolidar em estrutura única tudo que o squad está construindo, dividido em **7 frentes** com itens individuais que carregam história, critérios de aceite, subtarefas, prioridade RICE e dependências cruzadas.

**Backlog é o hub único — estratégico e tático.**
- Item de backlog (`Backlog/frentes/`) — história com critérios de aceite, dura semanas/meses, sponsor do negócio.
- Tático curto (reuniões, análises, 1on1s) → `Backlog/reunioes/`, `Backlog/analises/`, `Backlog/1on1s/`.
- ~~Pendência (`Gestao/Pendencias/`)~~ — **aposentado em 27/05/2026.** Tático = subtarefa do item.
- ~~`Gestao/`~~ — **aposentado em 2026-06-15.** Tudo migrou para `Backlog/`.

## Estrutura

```
Backlog/
├── README.md                 # este arquivo
├── BACKLOG.md                # relatório mestre (regenerado por /backlog regenerate)
├── frentes/                  # itens individuais por frente
│   ├── bitrix/               # raias, automações, histórico contínuo
│   ├── torre/                # Torre de Controle — dashboards, relatórios, integrações
│   ├── clara/                # agente Clara — formalização (comprovantes, biometria, reprovados)
│   ├── esperanza/            # agente Esperanza — renegociação, cobrança
│   ├── valentina/            # agente Valentina — SAC, roteamento, base de contexto
│   ├── automacoes/           # HyperFlow, MCPs, integrações infra
│   └── estrategica/          # transversal — NPS, narrativa IA, processo
├── solicitacoes/             # documentos formalizados pelo negócio (.txt, .pdf)
├── prints/                   # screenshots de consulta
└── contexto/                 # docs de apoio (Torre overview, Esperanza overview)
```

## Como usar

```
/backlog              # lista itens ativos por frente
/backlog add <título> # cria item bruto
/backlog refine <id>  # quebra subtarefas, escreve CA, calcula RICE
/backlog from <P##>   # cria item a partir de pendência tática
/backlog regenerate   # reescreve BACKLOG.md mestre
```

Detalhe completo em `.claude/agents/po-backlog.md` e `.claude/commands/backlog.md`.

## Convenções

- **IDs:** prefixo por frente — `BBT##` (Bitrix), `BTR##` (Torre), `BCL##` (Clara), `BES##` (Esperanza), `BVA##` (Valentina), `BAU##` (Automações), `BST##` (Estratégica).
- **Nome de arquivo:** `B<prefix><nn>_<slug>.md` (ex: `BES04_tabulacoes_automaticas.md`).
- **Status:** `bruto` → `refinado` → `em-curso` → `bloqueado` → `entregue` → `arquivado`.
- **Datas:** ISO absolutas (`2026-05-22`), nunca relativas.

## Fonte da verdade

`Backlog/frentes/` é a fonte da verdade dos itens. `BACKLOG.md` é projeção — apagá-lo não perde dado, basta rodar `/backlog regenerate`.

Itens são alimentados por:
- ~~**Pendências táticas** em `Gestao/Pendencias/`~~ — aposentado (rótulo histórico `Pnn` sobrevive em `origem.pendencias`)
- **Reuniões** em `Backlog/reunioes/` (referência via `origem.reunioes`)
- **Análises** em `Backlog/analises/` (referência via `origem.analises`)
- **Solicitações formalizadas** em `Backlog/solicitacoes/` (referência via `origem.solicitacoes`)
