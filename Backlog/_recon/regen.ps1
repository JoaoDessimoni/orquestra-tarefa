$ErrorActionPreference='Stop'
$base  = Join-Path $env:USERPROFILE 'Documents\Finza\Repasse'
$recon = Join-Path $base 'Backlog\_recon'
$bhtml = Join-Path $base 'backlog.html'
$mhtml = Join-Path $base 'mapa-mental.html'
$utf8  = New-Object System.Text.UTF8Encoding($false)
$CURATED_RE = '^(BBT|BAU|BTR|BCL|BES|BVA|BLV|BST)\d'

function Get-Block($html,$id){
  $rx = New-Object Text.RegularExpressions.Regex("<script[^>]*id=""$id""[^>]*>(.*?)</script>", [Text.RegularExpressions.RegexOptions]::Singleline)
  $m = $rx.Match($html); if(-not $m.Success){ throw "bloco $id nao encontrado" }
  return $m.Groups[1].Value.Trim()
}
function Set-Block($html,$id,$json){
  $rx = New-Object Text.RegularExpressions.Regex("(<script[^>]*id=""$id""[^>]*>)(.*?)(</script>)", [Text.RegularExpressions.RegexOptions]::Singleline)
  $eval = [Text.RegularExpressions.MatchEvaluator]{ param($m) $m.Groups[1].Value + "`r`n" + $json + "`r`n" + $m.Groups[3].Value }
  return $rx.Replace($html, $eval, 1)
}
function To-Json($obj){ ($obj | ConvertTo-Json -Depth 40) -replace '</','<\/' }
function HasProp($o,$n){ $o.PSObject.Properties.Name -contains $n }

$imp = Get-Content (Join-Path $recon 'imported_items.json') -Raw -Encoding UTF8 | ConvertFrom-Json

$sustB = [pscustomobject]@{ key='sustentacao'; label='Sustentação · Operação'; prefix='IAF/QMR'; color='#64748B'; sponsor='Operação Finza'; plataforma='Multi (Bitrix · Torre · Hyper · n8n)'; desc='Frente criada em 02/06/2026 para espelhar demandas operacionais importadas do Jira (legado IAF) e do Quimera sem frente estratégica clara — bugs, incidentes, ajustes e tarefas de TI.' }
$sustM = [pscustomobject]@{ key='sustentacao'; label='Sustentação · Operação'; color='#64748B'; prefix='IAF/QMR'; sponsor='Operação Finza'; plataforma='Multi'; desc='Demandas operacionais importadas (Jira IAF + Quimera) sem frente estratégica — bugs, incidentes, TI, ajustes.' }

# ---------- ler backlog.html, separar curados (idempotente) ----------
$bh = Get-Content $bhtml -Raw -Encoding UTF8
$bdata = Get-Block $bh 'backlog-data' | ConvertFrom-Json
$curated = @($bdata.items | Where-Object { $_.id -match $CURATED_RE })
foreach($it in $curated){
  $it.subtarefas = @()
  if(-not (HasProp $it 'fonte')){ $it | Add-Member fonte 'backlog' -Force } else { $it.fonte = 'backlog' }
  $resp = if($it.implementador){ $it.implementador } elseif($it.owner){ $it.owner } else { 'João Vinícius' }
  $it | Add-Member responsavel $resp -Force
  if(-not (HasProp $it 'concluida')){ $it | Add-Member concluida $null -Force }
  $it | Add-Member prazo_estimado $false -Force
  foreach($f in 'categoria','jira','quimera'){ if(-not (HasProp $it $f)){ $it | Add-Member $f $null -Force } }
}

# ---------- itens importados (schema rico) ----------
$importedB = foreach($d in $imp){
  [pscustomobject]@{
    id=$d.id; frente=$d.frente; title=$d.title; status=$d.status; prioridade=$d.prioridade
    sponsor=$null; owner='João Vinícius'; implementador=$d.responsavel; deadline_alvo=$d.deadline
    criada=$d.criada; refinada=$null; concluida=$d.concluida; prazo_estimado=[bool]$d.prazo_estimado
    responsavel=$d.responsavel; valor_negocio=$null; esforco=$null; rice=$null
    origem=[pscustomobject]@{ pendencias=@(); reunioes=@(); solicitacoes=@() }; roadmap_vinculado=$null
    dependencias=@($d.dependencias); bloqueia=@($d.bloqueia); tags=@($d.tags)
    historia=''; contexto=$d.descricao; criterios_aceite=@(); subtarefas=@()
    premissas=@(); riscos=@(); observacoes_po=''
    historico=@([pscustomobject]@{ data='2026-06-02'; texto=("Importado por espelhamento Quimera/Jira. fonte=" + $d.fonte) })
    notas=''; fonte=$d.fonte; categoria=$d.categoria; jira=$d.jira; quimera=$d.quimera
  }
}
$master = @($curated) + @($importedB)
$bdata.items = $master
if(-not (@($bdata.frentes | Where-Object { $_.key -eq 'sustentacao' }).Count)){ $bdata.frentes = @($bdata.frentes) + @($sustB) }
$bdata | Add-Member generated_at '2026-06-02' -Force
$bdata | Add-Member refinement_pass 'Fase 2 (02/06/2026): pente-fino — responsável, criada, concluída e prazo (estimado p/ em-curso/validação) por demanda, cruzando Quimera (verdade) + Jira (legado). Filtros de data adicionados nas projeções. 30 curados + 208 importados = 238.' -Force
$bh = Set-Block $bh 'backlog-data' (To-Json $bdata)
[IO.File]::WriteAllText($bhtml, $bh, $utf8)
Write-Output ("backlog.html: {0} itens, {1} frentes" -f $bdata.items.Count, $bdata.frentes.Count)

# ---------- mapa-mental.html (schema lean, derivado do master) ----------
$mh = Get-Content $mhtml -Raw -Encoding UTF8
$mdata = Get-Block $mh 'map-data' | ConvertFrom-Json
$leanItems = foreach($it in $master){
  [pscustomobject]@{
    id=$it.id; frente=$it.frente; title=$it.title; status=$it.status; prioridade=$it.prioridade
    esforco=$it.esforco; valor_negocio=$it.valor_negocio; rice=$it.rice
    dependencias=@($it.dependencias); bloqueia=@($it.bloqueia); deadline=$it.deadline_alvo
    subtarefas=@(); fonte=$it.fonte; categoria=$it.categoria; tags=@($it.tags)
    criada=$it.criada; responsavel=$it.responsavel; concluida=$it.concluida; prazo_estimado=[bool]$it.prazo_estimado
  }
}
$mdata.items = @($leanItems)
if(-not (@($mdata.frentes | Where-Object { $_.key -eq 'sustentacao' }).Count)){ $mdata.frentes = @($mdata.frentes) + @($sustM) }
$mdata | Add-Member generated_at '2026-06-02' -Force
$totItems = $mdata.items.Count; $totFrentes = $mdata.frentes.Count
$mh = Set-Block $mh 'map-data' (To-Json $mdata)
$mh = [regex]::Replace($mh, '<strong>\d+\s+itens</strong>\s*·\s*\d+\s+frentes\s*·\s*\d+\s+subtarefas', ("<strong>{0} itens</strong> · {1} frentes · 0 subtarefas" -f $totItems,$totFrentes))
[IO.File]::WriteAllText($mhtml, $mh, $utf8)
Write-Output ("mapa-mental.html: {0} itens, {1} frentes" -f $mdata.items.Count, $mdata.frentes.Count)

# ---------- BACKLOG.md ----------
$all = $bdata.items
$lines = @('# BACKLOG — IAF (espelho Quimera + Jira)','', "Gerado 2026-06-02. Total: **$($all.Count) itens** em $($bdata.frentes.Count) frentes. Pente-fino: responsável + datas + prazo estimado.",'')
$lines += '## Origem (`fonte`)'; $lines += ''; $lines += '| fonte | itens |'; $lines += '|---|---|'
$all | Group-Object fonte | Sort-Object Count -Descending | ForEach-Object { $lines += "| $($_.Name) | $($_.Count) |" }
$lines += ''; $lines += '## Por responsável'; $lines += ''; $lines += '| responsável | itens |'; $lines += '|---|---|'
$all | Group-Object responsavel | Sort-Object Count -Descending | ForEach-Object { $lines += "| $($_.Name) | $($_.Count) |" }
$lines += ''; $lines += '## Por status'; $lines += ''; $lines += '| status | itens |'; $lines += '|---|---|'
$all | Group-Object status | Sort-Object Count -Descending | ForEach-Object { $lines += "| $($_.Name) | $($_.Count) |" }
$lines += ''; $lines += '> Matriz completa (Jira·Quimera·Backlog + responsável/datas/prazo) em `Backlog/_recon/matriz.md`.'
[IO.File]::WriteAllText((Join-Path $base 'Backlog\BACKLOG.md'), ($lines -join "`r`n"), $utf8)
Write-Output "BACKLOG.md regenerado."
