# CONVENÇÕES — OrquestrAi

> Documento canônico de padrões de código, banco, API e resiliência. **Chave de abóbada**: toda spec, doc e prompt de implementação referencia este arquivo.
> Status: **ACEITO** · Junho/2026 · Depende de `VISAO_PRODUTO_v2.md` e `ADR-001`.
> Reverte conscientemente as regras de idioma/REST/banco anteriores (ver `STATUS_DOCS.md`).

---

## 1 · Princípio de idioma

- **PT-BR em todo identificador do nosso código**: arquivos, classes, métodos, funções, variáveis, tabelas, colunas, endpoints, componentes.
- **Sem acento em identificadores** — `descricao`, `reunioes`, `execucoes` (não `descrição`, `reuniões`). Texto de UI e prosa podem ter acento; identificador, nunca.
- **Inglês só o que vem de biblioteca** (`APIRouter`, `BaseModel`, `Column`, `select`, `useState`) — inevitável, não se traduz.

## 2 · Backend — arquitetura em camadas (estilo Java)

Uma responsabilidade por arquivo. **Arquivos e classes em PascalCase.** Sufixo de camada explícito:

| Camada | Arquivo | Responsabilidade |
|---|---|---|
| Controller | `DemandaController.py` | rota/endpoint, validação de entrada, mapeia exception → HTTP |
| Service | `DemandaService.py` | regra de negócio, orquestração |
| Repository | `DemandaRepository.py` | acesso a dados (SQLAlchemy async) |
| Model | `DemandaModel.py` | entidade ORM (mapeia `tbl_demandas`) |
| DTO | `DemandaDto.py` | schemas Pydantic de request/response |

- **Classes:** PascalCase PT — `DemandaService`, `CuradoriaConhecimentoService`.
- **Arquivos:** PascalCase PT com sufixo de camada — `DemandaService.py`, `DemandaRepository.py`.
- **Métodos/funções/variáveis:** **snake_case PT** — `criar_demanda`, `buscar_por_id`, `lista_demandas`. (Decisão fixada — ADR-002; idiomatismo Python + menor atrito com libs.)

## 3 · API — endpoints RPC-PT (verbo no path)

Padrão verbo-no-path, legível, em PT:

```
POST   /demandas/criar-demanda
GET    /demandas/listar-demandas
GET    /demandas/obter-demanda/{idDemanda}
PUT    /demandas/editar-demanda/{idDemanda}
DELETE /demandas/excluir-demanda/{idDemanda}
POST   /reunioes/gerar-analise
PUT    /relatorios/editar-relatorio/{idRelatorio}
POST   /triagem/triar-demanda/{idDemanda}
```

- Recurso no plural, ação com hífen, verbo PT no infinitivo.
- Path params em camelCase PT alinhados à PK: `{idDemanda}`, `{idRelatorio}`.
- Verbo HTTP coerente com a ação (criar→POST, editar→PUT, excluir→DELETE, obter/listar→GET).

## 4 · Banco — tabelas e views

- Tabela: `tbl_` + **plural PT** → `tbl_demandas`, `tbl_reunioes`, `tbl_execucoes`, `tbl_regras_negocio`, `tbl_relacoes`, `tbl_embeddings`.
- View: `vw_` · View materializada: `vwm_`.

## 5 · Banco — colunas (prefixos)

| Prefixo | Uso | Prefixo | Uso |
|---|---|---|---|
| `id_` | **primary key** (`id_demanda`) | `dt_` | data/datetime (timestamptz) |
| `fk_` | **foreign key** (`fk_produto`) | `js_` | json/jsonb |
| `ds_` | descrição / texto longo | `fl_` | flag/boolean |
| `nm_` | nome | `st_` | status/enum |
| `nr_` | número | `vl_` | valor monetário |
| `cd_` | código (externo, ex. `cd_quimera`) | `ig_` | imagem |
| `vt_` | vetor (pgvector) | | |

- **PK:** `id_<entidade>` (`id_demanda`). **FK:** `fk_<entidade>` (`fk_produto`).
- **Timestamps + desativação:** `dt_criacao`, `dt_atualizacao`, `dt_desativacao`. Desativação = `dt_desativacao IS NULL` → ativo. Toda query de listagem filtra isso. **`ds_motivo_desativacao` é obrigatório ao desativar** (registra o porquê; some quando reativado). "Excluir" passa a significar **hard-delete** (remoção física da linha), permitido só em item já desativado — comportamento chega no C7c; até lá, "excluir" na API não existe, só `desativar`/`reativar`.
- **Enum/status:** coluna `st_<entidade>`, valores em PT (`rascunho`, `em-curso`, `publicada`, `cancelada`, `recusada`, `concluida`).
- **Triggers** de `dt_atualizacao` automáticos.

## 6 · Frontend — React PT

PascalCase PT casa com a convenção do React:
- Componentes/arquivos: `CartaoDemanda.tsx`, `BotaoPrimario.tsx`, `GrafoConhecimento3D.tsx`.
- Props/estado/funções: PT sem acento (`aoConfirmar`, `listaDemandas`).
- Libs em inglês (`useState`, `useQuery`) — inevitável.

## 7 · Resiliência (obrigatório)

- **Logs:** JSON estruturado (structlog). Campos mínimos: `id_execucao`, `evento`, `nivel`, `camada`, `timestamp`. Sem `print`.
- **Exceptions:** hierarquia PT. Base `OrquestrAiErro` → `RecursoNaoEncontradoErro`, `ValidacaoErro`, `IntegracaoExternaErro`, `ConflitoErro`. Handlers no FastAPI mapeiam exception → status HTTP. Nunca engolir exception silenciosamente.
- **Retry/timeout:** nas fronteiras externas (MCP Quimera, modelo de embedding, projeção Neo4j) — retry com backoff exponencial (`tenacity`), timeout explícito, e circuit breaker onde a falha em cascata for risco. Idempotência nas operações de escrita externa.
- **Por camada:** Repository trata erro de persistência; Service trata regra/negócio e decide retry; Controller só mapeia exception → resposta. Não vazar `Exception` genérica pro cliente.

## 8 · Commits

Prefixos: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`. Mensagem em PT.

---

## 9 · Exemplo end-to-end (fatia "criar demanda")

**DDL**
```sql
CREATE TABLE tbl_demandas (
  id_demanda      BIGSERIAL PRIMARY KEY,
  nm_demanda      VARCHAR(200) NOT NULL,
  ds_demanda      TEXT,
  st_demanda      VARCHAR(20)  NOT NULL DEFAULT 'rascunho',
  fk_produto      BIGINT REFERENCES tbl_produtos(id_produto),
  cd_quimera      VARCHAR(50),                 -- id externo no Quimera
  dt_criacao              TIMESTAMPTZ NOT NULL DEFAULT now(),
  dt_atualizacao          TIMESTAMPTZ NOT NULL DEFAULT now(),
  dt_desativacao          TIMESTAMPTZ,                 -- NULL = ativo
  ds_motivo_desativacao   TEXT                         -- obrigatório ao desativar
);
```

**Model** (`DemandaModel.py`)
```python
class DemandaModel(Base):
    __tablename__ = "tbl_demandas"
    id_demanda: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    nm_demanda: Mapped[str] = mapped_column(String(200))
    ds_demanda: Mapped[str | None] = mapped_column(Text)
    st_demanda: Mapped[str] = mapped_column(String(20), default="rascunho")
    fk_produto: Mapped[int | None] = mapped_column(ForeignKey("tbl_produtos.id_produto"))
    dt_criacao: Mapped[datetime] = mapped_column(server_default=func.now())
    dt_desativacao: Mapped[datetime | None] = mapped_column(nullable=True)
    ds_motivo_desativacao: Mapped[str | None] = mapped_column(Text, nullable=True)
```

**DTO** (`DemandaDto.py`)
```python
class CriarDemandaDto(BaseModel):
    nm_demanda: str
    ds_demanda: str | None = None
    fk_produto: int | None = None

class DemandaRespostaDto(BaseModel):
    id_demanda: int
    nm_demanda: str
    st_demanda: str
```

**Repository / Service / Controller** (resumo)
```python
# DemandaRepository.py
class DemandaRepository:
    async def salvar(self, demanda: DemandaModel) -> DemandaModel: ...
    async def buscar_por_id(self, id_demanda: int) -> DemandaModel | None: ...

# DemandaService.py
class DemandaService:
    async def criar_demanda(self, dados: CriarDemandaDto) -> DemandaRespostaDto: ...

# DemandaController.py
@router.post("/demandas/criar-demanda", response_model=DemandaRespostaDto)
async def criar_demanda(dados: CriarDemandaDto, service: DemandaService = Depends()): ...
```

Identificadores nossos em PT sem acento; só `BaseModel`, `Mapped`, `router`, `Depends` etc. vêm das libs.
