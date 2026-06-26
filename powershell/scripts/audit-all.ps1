$ErrorActionPreference='Continue'
$base=$PSScriptRoot
$order=@('full','assets','css','html','js','cssdist','dist')
$map=@{full='audit-full.ps1';assets='audit-assets.ps1';css='audit-css.ps1';html='audit-html.ps1';js='audit-js.ps1';cssdist='audit-css-dist.ps1';dist='audit-dist.ps1'}
$sb=[System.Text.StringBuilder]::new()
[void]$sb.AppendLine('AWFUL AUDIT')
[void]$sb.AppendLine('ROOT: ' + (Resolve-Path -LiteralPath (Get-Location).Path).Path)
foreach($key in $order){ Write-Host ('running: ' + $key); [void]$sb.AppendLine(''); [void]$sb.AppendLine('=== ' + $key.ToUpperInvariant() + ' ==='); & (Join-Path $base $map[$key]); try { [void]$sb.AppendLine((Get-Clipboard -Raw)) } catch { [void]$sb.AppendLine('CLIPBOARD READ FAILED') } }
$result=$sb.ToString()
try { Set-Clipboard -Value $result } catch {}
Write-Host ('all copied chars: ' + $result.Length)
