$ErrorActionPreference = 'Continue'
$base = $PSScriptRoot
$items = [ordered]@{
  all = 'audit-all.ps1'
  full = 'audit-full.ps1'
  assets = 'audit-assets.ps1'
  asset = 'audit-assets.ps1'
  css = 'audit-css.ps1'
  html = 'audit-html.ps1'
  js = 'audit-js.ps1'
  javascript = 'audit-js.ps1'
  cssdist = 'audit-css-dist.ps1'
  'css-dist' = 'audit-css-dist.ps1'
  dist = 'audit-dist.ps1'
}

function Show-AwfulHelp {
  Write-Host ''
  Write-Host 'awful-audit'
  Write-Host ''
  Write-Host 'modes:'
  Write-Host '  all       run full assets css html js cssdist dist'
  Write-Host '  full      code, git state and file inventory'
  Write-Host '  assets    asset files and references'
  Write-Host '  css       css files and class mentions'
  Write-Host '  html      html files'
  Write-Host '  js        javascript and typescript files'
  Write-Host '  cssdist   source css and root dist css'
  Write-Host '  dist      root dist files and sizes'
  Write-Host ''
  Write-Host 'commands:'
  Write-Host '  au all -Output _awful-audit\audit-all.txt -NoClipboard'
  Write-Host '  au full -Output _awful-audit\full.txt -NoClipboard'
  Write-Host '  au assets -Output _awful-audit\assets.txt -NoClipboard'
  Write-Host '  au css -Output _awful-audit\css.txt -NoClipboard'
  Write-Host '  au js -Output _awful-audit\js.txt -NoClipboard'
  Write-Host '  au all -Root A:\path\project -Output A:\path\audit.txt -NoClipboard'
  Write-Host ''
  Write-Host 'flags:'
  Write-Host '  -Output <path>     save report to file'
  Write-Host '  -NoClipboard       do not use clipboard'
  Write-Host '  -Root <path>       scan another folder'
  Write-Host ''
}

if ($args.Count -gt 0 -and -not ([string]$args[0]).StartsWith('-')) {
  $answer = [string]$args[0]
  if ($args.Count -gt 1) { $rest = @($args[1..($args.Count - 1)]) } else { $rest = @() }
} else {
  Show-AwfulHelp
  $answer = Read-Host 'mode [all]'
  if ([string]::IsNullOrWhiteSpace($answer)) { $answer = 'all' }
  $rest = @($args)
}

$key = $answer.Trim().ToLowerInvariant()
if (-not $items.Contains($key)) {
  Write-Host 'available: all, full, assets, css, html, js, cssdist, dist'
  exit 1
}

& (Join-Path $base $items[$key]) @rest
