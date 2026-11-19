#!/usr/bin/env bash
# Etapa 1 — extração BigQuery (SOMENTE LEITURA: `bq query` sem tabela de destino).
# Retomável: pula o que já existe em dados/brutos/. Uso: bash scripts/extrair.sh
set -uo pipefail
export PYTHONIOENCODING=utf-8 PYTHONUTF8=1
BASE="$(cd "$(dirname "$0")/.." && pwd)"
SQL="$BASE/scripts/sql"
OUT="$BASE/dados/brutos"
mkdir -p "$OUT"

run() { # nome arquivo_sql max_rows [sed-expr...]
  local nome="$1" sql="$2" max="$3"; shift 3
  if [ -s "$OUT/$nome.json" ]; then echo "[pula] $nome"; return 0; fi
  local q; q="$(cat "$sql")"
  for e in "$@"; do q="$(printf '%s' "$q" | sed "$e")"; done
  local t0=$SECONDS
  if printf '%s' "$q" | bq.cmd --quiet --headless --project_id=blips-bigdata query --use_legacy_sql=false --format=json --max_rows="$max" > "$OUT/$nome.json.tmp" 2> "$OUT/$nome.err"; then
    mv "$OUT/$nome.json.tmp" "$OUT/$nome.json"
    echo "[ok] $nome  $(( $(stat -c %s "$OUT/$nome.json") / 1024 )) KiB  $((SECONDS-t0))s"
  else
    echo "[ERRO] $nome (ver $nome.err)"; head -c 400 "$OUT/$nome.json.tmp" 2>/dev/null; echo; return 1
  fi
}

run ref_agentes   "$SQL/06_ref_agentes.sql"   5000
run ref_deptos    "$SQL/07_ref_deptos.sql"    5000
run ai_protocols  "$SQL/08_ai_protocols.sql"  400000
run chats_A       "$SQL/01_chats.sql"         100000 's/{{TENANT}}/FINZA/'
run chats_B       "$SQL/01_chats.sql"         200000 's/{{TENANT}}/BLIPS/'
run msgs_A        "$SQL/02_msgs_finza.sql"    600000
run ia_turnos_A   "$SQL/05_ia_turnos_finza.sql" 400000
run transcricoes_B "$SQL/04_transcricoes.sql" 200000
# BLIPS em fatias mensais pelo created_at do chat (limites em UTC = 00:00 de Brasília)
run msgs_B_2026-08 "$SQL/03_msgs_blips.sql" 900000 's/{{INI}}/2026-08-20 03:00:00/' 's/{{FIM}}/2026-09-01 03:00:00/'
run msgs_B_2026-09 "$SQL/03_msgs_blips.sql" 900000 's/{{INI}}/2026-09-01 03:00:00/' 's/{{FIM}}/2026-10-01 03:00:00/'
run msgs_B_2026-10 "$SQL/03_msgs_blips.sql" 900000 's/{{INI}}/2026-10-01 03:00:00/' 's/{{FIM}}/2026-11-01 03:00:00/'
run msgs_B_2026-11 "$SQL/03_msgs_blips.sql" 900000 's/{{INI}}/2026-11-01 03:00:00/' 's/{{FIM}}/2026-11-19 03:00:00/'
echo "FIM"
