$ErrorActionPreference='Continue'
$base=$PSScriptRoot
$items=[ordered]@{
  all='audit-all.ps1'
  full='audit-full.ps1'
  assets='audit-assets.ps1'
  asset='audit-assets.ps1'
  css='audit-css.ps1'
  html='audit-html.ps1'
  js='audit-js.ps1'
  javascript='audit-js.ps1'
  cssdist='audit-css-dist.ps1'
  'css-dist'='audit-css-dist.ps1'
  dist='audit-dist.ps1'
}
if($args.Count -gt 0){ $answer=[string]$args[0] } else {
  Write-Host ''
  Write-Host 'awful-audit'
  Write-Host 'all full assets css html js cssdist dist'
  Write-Host ''
  $answer=Read-Host 'mode'
}
$key=$answer.Trim().ToLowerInvariant()
if(-not $items.Contains($key)){ Write-Host 'available: all, full, assets, css, html, js, cssdist, dist'; exit 1 }
& (Join-Path $base $items[$key])
