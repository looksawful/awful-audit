param(
  [switch]$NoClipboard,
  [string]$Output,
  [string]$Root,
  [Alias('Zip')][switch]$Archive,
  [string]$ArchivePath
)
$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot '_audit-lib.ps1')
. (Join-Path $PSScriptRoot '_archive-lib.ps1')
if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
$result = Invoke-AwfulAudit -Mode 'dist' -Root $Root
Complete-AwfulAuditOutput -Result $result -NoClipboard:$NoClipboard -Output $Output -Archive:$Archive -ArchivePath $ArchivePath
