param([switch]$NoClipboard, [string]$Output, [string]$Root)
$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot '_audit-lib.ps1')
if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
$result = Invoke-AwfulAudit -Mode 'full' -Root $Root
Complete-AwfulAudit -Result $result -NoClipboard:$NoClipboard -Output $Output
