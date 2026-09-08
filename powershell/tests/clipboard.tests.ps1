$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-Awful {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw ('ASSERT FAILED: ' + $Message) }
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $repoRoot 'powershell\scripts\_audit-lib.ps1')
. (Join-Path $repoRoot 'powershell\scripts\_archive-lib.ps1')

$script:ClipboardCalls = [System.Collections.Generic.List[string]]::new()
function Set-Clipboard {
  param([string]$Value)
  [void]$script:ClipboardCalls.Add($Value)
}

$oldLimit = $env:AWFUL_AUDIT_MAX_CLIPBOARD_MB
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('awful-audit-clipboard-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

try {
  $env:AWFUL_AUDIT_MAX_CLIPBOARD_MB = '1'
  $largeText = 'x' * (1MB + 1)
  $result = [pscustomobject]@{ Mode = 'full'; Root = $tempRoot; Text = $largeText }

  $script:ClipboardCalls.Clear()
  $messages = (& { Complete-AwfulAuditOutput -Result $result } 6>&1 | Out-String)
  Assert-Awful ($script:ClipboardCalls.Count -eq 0) 'oversized full report was sent to text clipboard'
  Assert-Awful ($messages.Contains('clipboard: skipped (report too large)')) 'oversized clipboard skip reason was not reported'

  $outputPath = Join-Path $tempRoot 'report.txt'
  $script:ClipboardCalls.Clear()
  $messages = (& { Complete-AwfulAuditOutput -Result $result -Output $outputPath } 6>&1 | Out-String)
  Assert-Awful (Test-Path -LiteralPath $outputPath -PathType Leaf) 'output mode did not write the large report'
  Assert-Awful ($script:ClipboardCalls.Count -eq 1) 'output mode did not copy the saved-path message'
  Assert-Awful ($script:ClipboardCalls[0] -eq ('awful-audit report saved: ' + $outputPath)) 'output mode copied unexpected clipboard text'
  Assert-Awful ($messages.Contains('clipboard: output path copied')) 'output path clipboard success was not reported'

  Write-Host 'clipboard tests: passed'
} finally {
  if ($null -eq $oldLimit) { Remove-Item Env:AWFUL_AUDIT_MAX_CLIPBOARD_MB -ErrorAction SilentlyContinue } else { $env:AWFUL_AUDIT_MAX_CLIPBOARD_MB = $oldLimit }
  Remove-Item Function:\Set-Clipboard -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
