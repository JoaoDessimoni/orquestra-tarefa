# 06 · Modelo de dados — arquivos publicados + banco do artefato

> **Atualizado em 2026-11-19 (Etapa 6).** O desenho original punha tudo no banco do artefato (capability `db`). O teste de carga mostrou que o volume não cabe bem lá, e o que foi implementado é: **dados em arquivos JSON publicados ao lado da página** e **banco só para configuração**. O desenho original fica registrado no §6, como histórico.

## 0. Aviso de acesso (ler antes de compartilhar o artefato)

**Os arquivos de dados publicados ao lado da página ficam visíveis para QUALQUER pessoa com quem o artefato for compartilhado.** Eles são servidos junto com a página: quem abre a página baixa o índice (telefone, CNPJ, nome do CRM, nome de atendente) e pode baixar os lotes de mensagens (texto integral das conversas).

- As regras `admin` do banco **não protegem arquivos**. Elas só valem para `config/`, `prompts/` e `pesos/`.
- Hoje o artefato é **privado, só do dono** (João). Nessa condição, ninguém mais lê os arquivos.
- Compartilhar o link, mesmo como leitura, entrega toda a PII ao destinatário. Liberar para o CTO é uma decisão explícita sobre PII, e não só sobre a tela.
- Se um dia for preciso compartilhar a tela sem a PII, a saída é publicar outra versão só com agregados (sem `idx_*` e sem `m/`), e não relaxar regra de banco.

## 1. O que vai onde

| Onde | O quê | PII |
|---|---|---|
| Arquivos (`data/…`, publicados com a página) | Índice de clientes e protocolos, métricas de tempo, mensagens | **Sim** |
| Banco do artefato (`db`) | `config/geral`, `prompts/v1`, `pesos/v1` | Não |
| Disco local (`dados/`, gitignored) | Brutos do BigQuery, protocolos normalizados, amostra do avaliador | Sim |

Capabilities do artefato: `db` (regra única na raiz: `read: "admin"`, `write: "admin"`), `user`, `downloads`.
Artefato: https://claude.ai/artifact/TWzvThET43MGDXKDyuQteg

## 2. Arquivos publicados (`data/`)

Gerados por `scripts/montar_artefato.mjs` em `dados/artefato/data/` (gitignored). 51 arquivos, 81,9 MB no total (depois da correção do tempo da IA, §2.4); o maior é o índice de BLIPS (8,1 MB). Limites da plataforma: 16 MB por arquivo de texto, 255 arquivos e 64 MB por publicação (por isso a carga sai em duas publicações para a mesma URL), 511 arquivos e 256 MB por versão.

| Arquivo | Conteúdo | Tamanho |
|---|---|---|
| `data/meta.json` | Data da extração, janela, contagens por recorte, lista de atendentes (`ats`: id, nome, depto), rótulo da IA, notas e limitações, lista de índices e nº de lotes | 23 KB |
| `data/idx_A.json` | Índice FINZA: clientes + protocolos, sem texto de mensagem | 2,66 MB |
| `data/idx_B.json` | Índice BLIPS · Cobrança | 8,1 MB |
| `data/m/A_000…008.json` | Mensagens FINZA em lotes por cliente (~1,5 MB cada) | 9 arquivos, 13,1 MB |
| `data/m/B_000…038.json` | Mensagens BLIPS · Cobrança | 39 arquivos, 58,0 MB |

Se um índice passar de 12 MB, o script divide em `idx_<rec>_1.json`, `_2`… e lista as partes em `meta.rec.<rec>.idx`. Hoje não foi preciso.

### 2.1 Índice (`idx_<rec>.json`)

Um objeto com um registro por linha. Strings repetidas viram dicionário.

```
{ "v":1, "rec":"A",
  "dic": { "depto":[…], "nome":[…], "fonte":[…], "tipo":["so_ia","ia_humano","so_humano"] },
  "cli":  [ [id, telefone, [cnpjs], ambiguo(0|1), nome_crm, lote], … ],
  "prot": [ [chat_id, protocol, iCliente, iTipo, iDepto, [iNome…], iAtendente(-1 = sem),
             inicio_ms, transf_delta_ms|null, iFonte, flags, assumir_ms|null,
             [turnos: ini_delta_ms, dur_ms, por, …] ], … ] }
```

- `iAtendente` aponta para `meta.rec.<rec>.ats`; `[iNome…]` (IA e humanos que falaram) aponta para `dic.nome`.
- `flags` (bits): 1 aberto no corte · 2 broadcast · 4 receptivo · 8 outlier (> 7 dias) · 16 tem áudio não transcrito.
- Turnos: trincas `ini_delta_ms` (a partir de `inicio`), `dur_ms` (`-1` = sem resposta, `-2` = encerramento do cliente) e `por` (0 IA, 1 humano, 2 IA fora da medição por ter respondido em menos de 3 s, −1 sem réplica).
- O relógio comercial **não é gravado**: a página calcula com `bizMin` a partir de `ini` e `dur`, usando o expediente em vigor. Mudar o expediente em `config/geral` recalcula tudo sem regerar arquivo.
- Timestamps: relógio de parede de Brasília gravado como ms UTC.
- O cliente guarda o número do lote onde estão as mensagens dele. (O briefing sugeria hash do id → lote; o número explícito permite encher os lotes por tamanho e manter todos perto de 1,5 MB.)

### 2.2 Lote de mensagens (`m/<rec>_<nnn>.json`)

```
{ "v":1, "n":[nomes de atendente do lote],
  "c": { "<cliente_id>": { "<chat_id>": [ ts_base_ms, [dt_ms, autor, texto, iNome?, tipo?], … ] } } }
```

- `autor`: 0 cliente · 1 humano · 2 IA · 3 sistema. `tipo`: índice em `texto, audio, imagem, documento, video, template, sistema`; omitido quando é o padrão (`sistema` para autor 3, `texto` para os demais).
- `dt_ms` é a diferença para a mensagem anterior.
- A página baixa o lote só quando um cliente é aberto e guarda no máximo 6 lotes em memória.
- Caractere corrompido na origem (U+FFFD) e caractere de controle viram `□`: a publicação recusa U+FFFD.

### 2.3 Prova de consistência

`montar_artefato.mjs` decodifica cada conversa e cada linha de índice com a mesma lógica da página e compara com as métricas do `normalizar.mjs`. Resultado da geração de 2026-11-19: **0 divergências em 80.301 protocolos**. A geração falha se houver alguma.

As funções `bizMin`, `faixaDe`, `ehCortesia`, `fechaMet` e `metricas` são cópia literal entre `scripts/normalizar.mjs` e o `<script>` do HTML. `montar_artefato.mjs` lê o bloco do `normalizar.mjs`, para não existir terceira cópia.

### 2.4 Correção do tempo de resposta da IA (2026-11-19)

- A coluna `processing_time_ms` da Torre vem zerada. O `normalizar.mjs` injetava a mensagem do cliente 1 s antes da resposta da IA, e 5.616 dos 5.961 turnos de IA do FINZA ficavam com espera de 1 s.
- Agora só a resposta da IA é injetada. O tempo é medido a partir da mensagem real do cliente (reconstrução). Sem a mensagem do cliente, não há turno.
- Turno respondido pela IA em menos de 3 s ganha `rap: true` e fica fora de `respIA`, da mediana da IA e do mapa de calor. Ele continua contando como turno respondido na faixa do protocolo.
- Efeito no FINZA: 241 turnos de IA medidos (9 fora da medição), protocolos com turno de 5.637 para 4.651, sem mensagem do cliente de 16.779 para 17.765. BLIPS: 8.209 medidos e 770 fora da medição; contagens de protocolo iguais.
- Como o FINZA perdeu um lote, `data/m/A_009.json` foi removido da publicação.

## 3. Banco do artefato (`db`)

Só o que é pequeno e sem PII. Três documentos:

| Caminho | Conteúdo |
|---|---|
| `config/geral` | `recortes` (definição e contagens), `janela`, `expediente`, `faixas`, `notas_agilidade`, `tetos`, `penalidades`, `penal_max`, `assuntos`, `prompt_ativo` ("v1"), `pesos_ativos` ("v1"), `extraido_em`, `fonte_versoes`, `regras`, `notas`, `amostra` (seed 20261119, parâmetros, tamanhos) |
| `prompts/v1` | `texto` (rubrica completa), `criado_em`, `autor`, `nota`, `status` |
| `pesos/v1` | `pesos` dos 7 critérios (soma 100), `criado_em`, `autor` |

- Regra: `{ path: "", read: "admin", write: "admin" }`. Verificado em 2026-11-19: como dono, cada coleção devolve 1 documento; nos níveis `view` e `interact`, nenhuma devolve nada.
- A página lê `config/geral` e as versões ativas de pesos e prompt ao abrir. Aplica `expediente`, `notas_agilidade`, `tetos`, `penalidades`, `assuntos`, `pesos` e o texto do prompt, e recalcula scores na hora. Sem acesso ao banco, ou com banco vazio, valem os padrões embutidos na página.
- Mudar pesos: gravar `pesos/<v>` e apontar `config/geral.pesos_ativos`. Não precisa republicar.
- Limites do banco: 256 KiB por documento, 25.000 documentos. Hoje são 3.

## 4. Carga e atualização

1. `node --max-old-space-size=8192 scripts/normalizar.mjs` (≈ 2 min) → `dados/protocolos/`, `dados/metricas/`.
2. `node --max-old-space-size=8192 scripts/amostra.mjs` → `dados/amostra/amostra.json`.
3. `node --max-old-space-size=8192 scripts/montar_artefato.mjs --teste 200` → projeta tamanho com 200 protocolos por recorte.
4. `node --max-old-space-size=8192 scripts/montar_artefato.mjs` (≈ 2 min) → `dados/artefato/data/` e `dados/artefato/_arquivos.json`.
5. Publicar o HTML na mesma URL com `files` e `root = Harness/demandas/raio-x-atendimento-hyperflow/dados/artefato`, em duas chamadas (≤ 64 MB cada). Arquivo não reenviado é mantido.
6. Gravar ou atualizar `config/geral`, `prompts/<v>`, `pesos/<v>` com `ArtifactData`.

Teste de carga de 2026-11-19 (200 protocolos por recorte): mensagens ≈ 727 B/protocolo em FINZA e ≈ 997 B em BLIPS; índice ≈ 99 B e ≈ 113 B. Projeção: 16,3 MB + 57,7 MB de mensagens e 2,2 MB + 6,5 MB de índice. Realizado: 14,6 + 58,0 e 2,7 + 8,1.

A carga é idempotente: regerar e republicar sobrescreve.

**Avaliação por IA:** ainda não rodou. `aval` e `assunto` são nulos para todos os protocolos. Quando rodar, as avaliações entram como mais um conjunto de arquivos (`data/av/<rec>_<nnn>.json`, por cliente, no mesmo esquema de lotes) e o índice ganha os campos resumidos (assunto, resolvido, frustração, score). <!-- TODO: confirmar com gestor o formato final quando a conversa completa chegar pelo Desk -->

## 5. PII

- Telefone, CNPJ e nome do CRM ficam em `idx_*.json`. O texto das conversas fica em `m/*.json`. Nome de atendente fica em `meta.json` e nos dicionários.
- Nada de PII no banco (`config`, `prompts`, `pesos`).
- `dados/` local fica no `.gitignore` (`/Harness/demandas/*/dados/`), inclusive `dados/artefato/`.
- Vale o aviso do §0: arquivo publicado não tem regra de acesso própria.

## 6. Histórico — desenho original (não implementado)

O plano de 2026-11-18 previa coleções `clientes/`, `protocolos/`, `avaliacoes/`, `mensagens/`, `atendentes/`, `agregados/` e `reprocessamentos/` no banco, com carga por `ArtifactData` em lotes e mensagens grandes em `assets`. Foi trocado porque:

- o banco aceita 25.000 documentos, e só os protocolos são 80.301;
- cada leitura do banco devolve no máximo 1.000 documentos por página, o que tornaria a abertura do Dashboard lenta;
- os agregados não precisam ser pré-calculados: com o índice compacto, a página calcula tudo no navegador (FINZA em menos de 0,1 s e BLIPS em cerca de 0,2 s na primeira vez; depois fica em cache por recorte e relógio).

O que se perdeu na troca: a proteção por regra de leitura (§0). Enquanto o artefato for privado, isso não muda nada.
