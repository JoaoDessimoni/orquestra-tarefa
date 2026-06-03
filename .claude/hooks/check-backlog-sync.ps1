# check-backlog-sync.ps1
# ---------------------------------------------------------------------------
# PostToolUse hook (Edit | Write | MultiEdit).
# Garante que as DUAS projecoes do backlog (backlog.html + mapa-mental.html)
# e o BACKLOG.md mestre nunca fiquem dessincronizados das fontes em
# Backlog/frentes/**/*.md.
#
# Nao regenera nada (isso exige raciocinio do Claude) -- apenas injeta um
# lembrete determinístico no contexto via hookSpecificOutput.additionalContext,
# que dispara a acao correta (/backlog regenerate ou /sync --backlog).
#
# Fonte da verdade: os .md. As duas projecoes leem a MESMA fonte
# (id="backlog-data" no kanban, id="map-data" no canvas). Divergencia = bug.
#
# Regra de ouro: o hook NUNCA pode quebrar a sessao -> falha sempre em silencio (exit 0).
# Registrado em .claude/settings.json. Veja CLAUDE.md secao 3 e 4.
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }

    $data = $raw | ConvertFrom-Json
    $fp = $data.tool_input.file_path
    if ([string]::IsNullOrWhiteSpace($fp)) { exit 0 }

    # Normaliza separadores para comparacao robusta no Windows.
    $fp   = $fp -replace '/', '\'
    $leaf = Split-Path $fp -Leaf
    $lp   = $fp.ToLowerInvariant()

    $msg = $null

    if ($leaf -ieq 'backlog.html' -or $leaf -ieq 'mapa-mental.html') {
        # Editou uma PROJECAO diretamente.
        $msg = "[BACKLOG-SYNC] Edicao em PROJECAO do backlog ($leaf). " +
               "Se faz parte de /backlog regenerate ou /sync, ignore esta nota. " +
               "Caso contrario: backlog.html e mapa-mental.html projetam a MESMA fonte " +
               "(Backlog/frentes/**/*.md) -- backlog.html(id=backlog-data, kanban) e " +
               "mapa-mental.html(id=map-data, canvas). Editar so uma dessincroniza a outra. " +
               "Acao: leve a mudanca para o .md-fonte do item e rode /backlog regenerate " +
               "(ou /sync --backlog) para regravar AS DUAS projecoes + Backlog/BACKLOG.md a partir da fonte."
    }
    elseif ($lp -like '*\backlog\backlog.md') {
        # Editou o relatorio mestre, que e GERADO.
        $msg = "[BACKLOG-SYNC] Backlog/BACKLOG.md e GERADO por /backlog regenerate a partir de " +
               "Backlog/frentes/. Edicao manual sera sobrescrita. Faca a mudanca no .md-fonte do " +
               "item e rode /backlog regenerate."
    }
    elseif (($lp -like '*\backlog\frentes\*') -and ($leaf -like '*.md') -and ($leaf -ine 'README.md')) {
        # Editou uma FONTE de item de backlog -> projecoes agora estao defasadas.
        $msg = "[BACKLOG-SYNC] Fonte de backlog alterada ($leaf). As projecoes estao DEFASADAS. " +
               "Acao obrigatoria antes de encerrar: rode /backlog regenerate (ou /sync --backlog) " +
               "para regravar backlog.html + mapa-mental.html + Backlog/BACKLOG.md a partir das fontes. " +
               "Alem disso, se a frente deste item tem mapa textual curado (Backlog/contexto/mapa_*.md " +
               "ou *_overview.md), avalie se ficou defasado e rode /contexto para revisar -- mapas " +
               "textuais NAO sao regenerados automaticamente (sao curadoria humana)."
    }

    if ($null -ne $msg) {
        $out = @{
            hookSpecificOutput = @{
                hookEventName     = 'PostToolUse'
                additionalContext = $msg
            }
        }
        # ConvertTo-Json escapa acentos/nao-ASCII como \uXXXX -> bytes ASCII, seguro em qualquer encoding.
        $out | ConvertTo-Json -Depth 5 -Compress
    }

    exit 0
}
catch {
    # Nunca propague erro: um hook quebrado nao pode travar a sessao.
    exit 0
}
