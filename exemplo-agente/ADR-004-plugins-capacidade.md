# ADR-004 — Registro de plugins de capacidade

> Padrão uniforme para capacidades externas ligáveis/desligáveis/trocáveis. Status: ACEITO · Julho/2026.
> Depende de ADR-001 (stores), ADR-003 (USO_LOCAL, credencial cifrada), CONVENCOES.

## Contexto

Cada capacidade externa nasceu com um mecanismo próprio de configuração: o **driver do runner** por
`USO_LOCAL` (env de boot, ADR-003), o **roteamento de modelo** por `tbl_configuracoes` (ADR-002), os
**prompts de sistema** por `tbl_prompts_sistema` (C10). Nenhum lugar responde de forma uniforme "esta
capacidade usa aquele provedor, com esta config, e está ligada".

Sem isso, cada nova capacidade (storage, extração de documento, embedding, transcrição, OCR) inventaria
o próprio jeito de ser configurada, e o RAG (C11b) abriria um caminho paralelo em vez de encaixar.

## Decisão — capacidade × provedor × estado × config

**Capacidade** (`st_tipo`) é *o que* precisa ser feito. **Provedor** (`nm_provedor`) é *quem* faz.
Uma linha de `tbl_plugins_capacidade` é o par, mais a config e o estado.

- **Config não-secreta** em `js_config` (JSONB) — endpoint, bucket, região, modelo.
- **Credencial** em `ds_credencial_cifrada` (Fernet, via `core/Cripto`), decifrada **só no momento do
  uso**, nunca numa leitura de API. A resposta expõe apenas `fl_tem_credencial` (ADR-003).

### Três dimensões de estado, ortogonais

É a parte que gera confusão se não ficar explícita — `tbl_mcps` já carrega as duas primeiras com nomes
parecidos e sentidos diferentes:

| Coluna | Pergunta que responde | Efeito de estar "off" |
|---|---|---|
| `dt_desativacao` | o **registro** existe? (soft-delete, CONVENCOES §5) | a linha some das listagens |
| `fl_ativo` | é **este** o provedor vigente da capacidade? | a capacidade fica sem provedor |
| `fl_disponivel` | há **implementação** nesta versão? | provedor é casca dormente |

`fl_ativo` é garantido único por capacidade pelo índice parcial `uq_plugins_capacidade_ativo`
(`ON (st_tipo) WHERE fl_ativo AND dt_desativacao IS NULL`) — a invariante é do **banco**, não só do
Service. É o terceiro índice único parcial do schema (molde: `uq_times_mcps_ativo`).

### Interface por tipo

Cada capacidade define um **contrato** (ABC em `capacidades/Contratos.py`); cada provedor implementa.
O resolver (`capacidades/Resolvedor.py`) recebe o tipo, lê o provedor vigente e devolve a instância.

Um **provedor dormente** é uma linha sem implementação: registrado para documentar a intenção e para a
aba de configuração (C12) mostrar o que existe no roadmap — e **nunca** instanciado.

### Regra central: capacidade off nunca degrada em silêncio

Quem depende de uma capacidade desligada ou dormente recebe `CapacidadeIndisponivelErro` (409,
`error_code="capacidade_indisponivel"`) com `js_detalhes.ds_motivo` distinguindo **três** estados:

| `ds_motivo` | Significa | Como resolver |
|---|---|---|
| `sem_provedor` | nenhum provedor vigente para o tipo | ativar um provedor |
| `desligada` | o provedor vigente está desabilitado/desativado | reativar |
| `nao_implementada` | provedor é casca (`fl_disponivel=false`) | esperar a fatia que implementa |

Uma exceção só, com motivo legível — não três classes, e nunca um erro genérico ou uma degradação muda.
Falha de **rede no uso** (o provedor está ligado mas o backend não responde) continua sendo
`IntegracaoExternaErro` (502), que já existe para fronteira externa.

### Ativar valida

`ativar-plugin` chama `validar_conexao()` do provedor **antes** de marcar `fl_ativo`. Falha →
`IntegracaoExternaErro` (502) e o plugin **não** fica ativo. Corrige a lacuna do precedente: o
`habilitar-mcp` do C6c só seta o booleano, sem nenhum handshake — dá para deixar "ativo" um MCP que não
responde.

### Relação com `USO_LOCAL` (ADR-003)

São eixos diferentes, e confundi-los é o erro a evitar:

- **Topologia** (`USO_LOCAL`) decide *onde* as coisas rodam e, portanto, o **endpoint** de um provedor.
  O storage MinIO é `127.0.0.1:9000` no Modo Local e `minio:9000` no Modo Servidor — mesma resolução de
  `url_banco`/`uri_neo4j`, com override explícito vencendo.
- **Provedor** (este registro) decide *quem* implementa. Trocar MinIO por S3 é trocar de provedor, não
  de topologia.

**O `motor` (driver do runner) fica FORA do registro.** O valor `motor` existe no enum `tipo_capacidade`
(porque `ALTER TYPE ADD VALUE` no Postgres não roda em transação e exigiria migration própria depois),
mas **nenhuma linha é seedada**. Razão: o driver é decisão de topologia resolvida no boot — trocá-lo
muda *onde a api roda* (host vs container). No registro, seria uma segunda fonte de verdade capaz de
contradizer o env: alguém "ativaria" `DriverApi` com a api rodando em Modo Local, e o registro estaria
mentindo. Se algum dia o driver virar troca de runtime, esta decisão se revisita — o enum já suporta.

### MinIO é fonte da verdade dos binários

MinIO **não** é um quarto store de conhecimento e **não** contradiz o ADR-001 §D2 ("Postgres fonte
única"): nenhum dado relacional migra para lá. A divisão é:

- **Postgres**: metadado + `cd_chave` do objeto (fonte única do que existe e de como se relaciona).
- **MinIO**: os bytes.

Consequência operacional: `orquestrai_miniodata` passa a ser o **segundo volume alvo de backup**
(`pgdata` era o único; `neo4jdata` é projeção descartável). Diferente do Neo4j, o objeto binário **não é
reconstruível** a partir do Postgres — perder o volume é perder o arquivo.

### Camada nova no backend

`apps/api/src/orquestrai/capacidades/` — contratos, implementações de provedor e resolver. CONVENCOES §2
lista Controller/Service/Repository/Model/DTO + `core/` + `runner/`; este pacote é uma adição
estrutural, registrada aqui. Regra: `capacidades/` **não** acessa banco (recebe config já resolvida),
espelhando a disciplina de `runner/`.

## Capacidades previstas

| Capacidade | Provedor(es) | Estado no C11a |
|---|---|---|
| `storage` | `minio` (real), `s3` (casca) | **implementada** |
| `extracao_documento` | `lib_local` (pypdf + python-docx) | **implementada** (sem IA, sem rede) |
| `embedding` | `bge_m3` | casca dormente (ADR-002 §D5.1) |
| `transcricao` | `openai_whisper` | casca dormente |
| `ocr` | `tesseract` | casca dormente |
| `motor` | — | fora do registro (ver acima) |

`storage→s3` é seedado como casca de propósito: documenta a intenção **e** dá o alvo concreto para
verificar que ativar um provedor não implementado falha com `nao_implementada`, não com erro genérico.

## Consequências

- Uma capacidade nova é: um valor no enum + uma linha seedada + um ABC + uma implementação. Nada de
  config solta por feature.
- O registro é o primeiro consumidor real de `Cripto.decifrar` — até aqui a decifragem existia sem
  nenhum caminho de produção que a exercitasse.
- `capacidades/` é síncrono nas bibliotecas que usa (boto3, pypdf, python-docx) e assíncrono na
  fronteira: todo I/O bloqueante vai para `asyncio.to_thread`.
- O que **não** muda: `tbl_configuracoes` segue dono de flags/parâmetros de comportamento
  (`AUTO_ROUTE_*`, `KNOWLEDGE_*`) e `tbl_prompts_sistema` dos prompts. O registro é sobre *provedores de
  capacidade*, não uma tabela de config genérica.

## Alternativas rejeitadas

- **Config solta em `tbl_configuracoes`** (uma chave por capacidade): não expressa "um provedor vigente
  entre vários", não tem onde guardar credencial cifrada por provedor, e não dá para distinguir
  "desligada" de "não implementada".
- **Uma tabela por capacidade** (`tbl_storages`, `tbl_embeddings_config`…): repete o mesmo esqueleto N
  vezes e mata a uniformidade que é o objetivo.
- **Só env var por capacidade** (como o `USO_LOCAL` faz com o motor): não é editável em runtime, não
  guarda credencial cifrada em repouso, e não tem histórico. Serve para topologia, não para provedor.
- **Três exceções separadas** para os três motivos de indisponibilidade: a hierarquia de `core/Excecoes`
  é achatada e o cliente só precisa distinguir pelo `ds_motivo`; três classes seriam ruído.
