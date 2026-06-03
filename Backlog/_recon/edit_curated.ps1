$ErrorActionPreference = 'Stop'
$fr = Join-Path $env:USERPROFILE 'Documents\Finza\Repasse\Backlog\frentes'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$curatedRe = '^(BBT|BAU|BTR|BCL|BES|BVA|BLV|BST)\d'
$touched = 0; $subRemoved = 0; $fonteAdded = 0
Get-ChildItem $fr -Recurse -Filter '*.md' | Where-Object { $_.Name -ne 'README.md' } | ForEach-Object {
  $txt = [IO.File]::ReadAllText($_.FullName)
  $idMatch = [regex]::Match($txt, '(?m)^id:\s*(.+?)\s*$')
  if(-not $idMatch.Success){ return }
  $id = $idMatch.Groups[1].Value
  if($id -notmatch $curatedRe){ return }   # so curados

  $orig = $txt
  # 1) remover secao "## Subtarefas" ate o proximo "## "
  $new = [regex]::Replace($txt, '(?ms)^##\s+Subtarefas\b.*?(?=^##\s)', '')
  if($new -ne $txt){ $subRemoved++ }
  $txt = $new

  # 2) adicionar fonte: backlog no frontmatter (apos a linha frente:) se ausente
  if($txt -notmatch '(?m)^fonte:\s'){
    $txt = [regex]::Replace($txt, '(?m)^(frente:.*)$', "`$1`r`nfonte: backlog", 1)
    $fonteAdded++
  }

  if($txt -ne $orig){
    [IO.File]::WriteAllText($_.FullName, $txt, $utf8)
    $touched++
    Write-Output ("  editado: {0}  ({1})" -f $_.Name, $id)
  }
}
Write-Output ("`nCurados tocados: {0} | secoes Subtarefas removidas: {1} | fonte:backlog add: {2}" -f $touched, $subRemoved, $fonteAdded)
