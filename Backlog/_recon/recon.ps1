$ErrorActionPreference = 'Stop'
$base = Join-Path $env:USERPROFILE 'Documents\Finza\Repasse'
$tr   = Join-Path $env:USERPROFILE '.claude\projects\C--Users-Jo-o-Vinicius-Documents-Finza-Repasse\f57e42ea-25c9-46c5-9bbe-fae3c433f804\tool-results'

function Normalize([string]$s) {
  if (-not $s) { return "" }
  $s = $s.ToLowerInvariant()
  # strip [Bitrix ID-xxxx] and [Maryam] style prefixes
  $s = [regex]::Replace($s, '\[[^\]]*\]', ' ')
  # remove accents
  $s = $s.Normalize([Text.NormalizationForm]::FormD)
  $sb = New-Object Text.StringBuilder
  foreach ($c in $s.ToCharArray()) {
    if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($c) }
  }
  $s = $sb.ToString()
  $s = [regex]::Replace($s, '[^a-z0-9 ]', ' ')
  $s = [regex]::Replace($s, '\s+', ' ').Trim()
  return $s
}
$stop = @('de','da','do','das','dos','e','o','a','os','as','para','por','com','sem','no','na','nos','nas','em','um','uma','que','ao','aos','the','of','to','correcao','ajuste','criar','implementar','revisar')
function Tokens([string]$s) {
  $n = Normalize $s
  return ($n -split ' ' | Where-Object { $_.Length -ge 3 -and $stop -notcontains $_ } | Select-Object -Unique)
}
function Jaccard($a, $b) {
  if ($a.Count -eq 0 -or $b.Count -eq 0) { return 0 }
  $inter = ($a | Where-Object { $b -contains $_ }).Count
  $union = (($a + $b) | Select-Object -Unique).Count
  if ($union -eq 0) { return 0 }
  return [math]::Round($inter / $union, 3)
}

# --- Quimera ---
$qf = Get-ChildItem $tr -Filter 'mcp-quimera-list_tickets-*.txt' | Sort-Object LastWriteTime -Desc | Select-Object -First 1
$q = (Get-Content $qf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json).tickets
$Q = $q | ForEach-Object {
  [pscustomobject]@{ source='quimera'; id=("QMR{0}" -f $_.ticket_number); num=$_.ticket_number; title=$_.title; status=$_.status; category=$_.category; type='ticket'; parent=$null; created=$_.created_at; resolved=$_.resolved_at; tokens=(Tokens $_.title) }
}

# --- Jira IAF (2 pages) ---
$jfiles = Get-ChildItem $tr -Filter 'mcp-claude_ai_Atlassian-searchJiraIssuesUsingJql-*.txt' | Sort-Object LastWriteTime
$J = @()
foreach ($jf in $jfiles) {
  try { $jj = Get-Content $jf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if (-not $jj.issues.nodes) { continue }
  foreach ($n in $jj.issues.nodes) {
    if ($n.key -notlike 'IAF-*') { continue }
    $J += [pscustomobject]@{ source='jira'; id=$n.key; num=[int]($n.key -replace 'IAF-',''); title=$n.fields.summary; status=$n.fields.status.name; category=$null; type=$n.fields.issuetype.name; parent=$(if($n.fields.parent){$n.fields.parent.key}else{$null}); created=$n.fields.created; resolved=$null; tokens=(Tokens $n.fields.summary) }
  }
}
$J = $J | Sort-Object id -Unique

# --- Curated backlog (.md frontmatter) ---
$C = @()
Get-ChildItem (Join-Path $base 'Backlog\frentes') -Recurse -Filter '*.md' | Where-Object { $_.Name -ne 'README.md' } | ForEach-Object {
  $txt = Get-Content $_.FullName -Raw -Encoding UTF8
  $id = if ($txt -match '(?m)^id:\s*(.+)$') { $matches[1].Trim() } else { $_.BaseName }
  $title = if ($txt -match '(?m)^title:\s*(.+)$') { $matches[1].Trim() } else { '' }
  $st = if ($txt -match '(?m)^status:\s*(.+)$') { $matches[1].Trim() } else { '' }
  $fr = if ($txt -match '(?m)^frente:\s*(.+)$') { $matches[1].Trim() } else { '' }
  $C += [pscustomobject]@{ source='backlog'; id=$id; title=$title; status=$st; frente=$fr; file=$_.FullName; tokens=(Tokens $title) }
}

Write-Output "==== CONTAGENS ===="
Write-Output ("Quimera:  {0}" -f $Q.Count)
Write-Output ("Jira IAF: {0}" -f $J.Count)
Write-Output ("Curados:  {0}" -f $C.Count)

# --- Match Quimera <-> Jira (best Jira per Quimera) ---
$TH = 0.6
$qjMatches = @()
foreach ($qi in $Q) {
  $best = $null; $bestScore = 0
  foreach ($ji in $J) {
    $sc = Jaccard $qi.tokens $ji.tokens
    if ($sc -gt $bestScore) { $bestScore = $sc; $best = $ji }
  }
  if ($best -and $bestScore -ge $TH) {
    $qjMatches += [pscustomobject]@{ quimera=$qi.id; qnum=$qi.num; qtitle=$qi.title; qstatus=$qi.status; qcat=$qi.category; jira=$best.id; jtitle=$best.title; score=$bestScore }
  }
}
$matchedQ = $qjMatches.quimera | Select-Object -Unique
$matchedJ = $qjMatches.jira    | Select-Object -Unique
$quimeraOnly = $Q | Where-Object { $matchedQ -notcontains $_.id }
$jiraOnly    = $J | Where-Object { $matchedJ -notcontains $_.id }

Write-Output ("`n==== BUCKETS (TH={0}) ====" -f $TH)
Write-Output ("quimera+jira (mesma demanda): {0}" -f $qjMatches.Count)
Write-Output ("jira-only (legado nao migrado): {0}" -f $jiraOnly.Count)
Write-Output ("quimera-only (pos-migracao):    {0}" -f $quimeraOnly.Count)
Write-Output ("DEMANDAS UNICAS ESTIMADAS:      {0}" -f ($qjMatches.Count + $jiraOnly.Count + $quimeraOnly.Count))
$jiraOnlySub = ($jiraOnly | Where-Object { $_.type -eq 'Subtarefa' }).Count
Write-Output ("  (das jira-only, subtarefas: {0})" -f $jiraOnlySub)

Write-Output "`n--- QUIMERA-ONLY (precisam get_ticket p/ descricao) ---"
$quimeraOnly | Sort-Object num | ForEach-Object { "  {0,-9} [{1,-12}] {2}" -f $_.id, $_.status, $_.title }

Write-Output "`n--- distribuicao de score dos matches ---"
$qjMatches | Group-Object { if($_.score -ge 0.99){'1.00'}elseif($_.score -ge 0.8){'0.80-0.99'}elseif($_.score -ge 0.7){'0.70-0.79'}else{'0.60-0.69'} } | Sort-Object Name -Desc | ForEach-Object { "  {0,-10} {1}" -f $_.Name, $_.Count }
Write-Output "`n--- matches fracos p/ revisar manual (0.60-0.74) ---"
$qjMatches | Where-Object { $_.score -lt 0.75 } | Sort-Object score | ForEach-Object { "  {0:0.00} {1} Q:{2} || J:{3}" -f $_.score,$_.quimera, ($_.qtitle.Substring(0,[math]::Min(38,$_.qtitle.Length))), ($_.jtitle.Substring(0,[math]::Min(38,$_.jtitle.Length))) }

# --- Match curated <-> sources ---
Write-Output "`n==== CURADOS x FONTES (melhor match) ===="
foreach ($ci in $C) {
  $bQ=$null;$bQs=0; foreach($qi in $Q){$s=Jaccard $ci.tokens $qi.tokens; if($s -gt $bQs){$bQs=$s;$bQ=$qi}}
  $bJ=$null;$bJs=0; foreach($ji in $J){$s=Jaccard $ci.tokens $ji.tokens; if($s -gt $bJs){$bJs=$s;$bJ=$ji}}
  $qstr = if($bQ -and $bQs -ge 0.34){"{0}({1:0.00})" -f $bQ.id,$bQs}else{"-"}
  $jstr = if($bJ -and $bJs -ge 0.34){"{0}({1:0.00})" -f $bJ.id,$bJs}else{"-"}
  "  {0,-6} {1,-45} Q:{2,-14} J:{3}" -f $ci.id, ($ci.title.Substring(0,[math]::Min(43,$ci.title.Length))), $qstr, $jstr
}

# --- Jira subtasks ---
$subs = $J | Where-Object { $_.type -eq 'Subtarefa' }
Write-Output ("`n==== JIRA SUBTAREFAS: {0} (com parent) ====" -f $subs.Count)
$subs | ForEach-Object { "  {0} parent={1}  {2}" -f $_.id, $_.parent, ($_.title.Substring(0,[math]::Min(50,$_.title.Length))) }

# --- save recon dataset ---
$out = [pscustomobject]@{ quimera=$Q; jira=$J; curated=($C | Select-Object source,id,title,status,frente,file); qjMatches=$qjMatches }
$out | ConvertTo-Json -Depth 6 | Out-File (Join-Path $base 'Backlog\_recon\dataset.json') -Encoding utf8
Write-Output "`n[ok] dataset salvo em Backlog\_recon\dataset.json"