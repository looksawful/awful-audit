$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-Awful {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw ('ASSERT FAILED: ' + $Message) }
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$auditHtml = Join-Path $repoRoot 'powershell\scripts\audit-html.ps1'

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('awful-audit-tests-' + [guid]::NewGuid().ToString('N'))
$projectRoot = Join-Path $tempRoot 'project'
New-Item -ItemType Directory -Force -Path $projectRoot | Out-Null
Set-Content -LiteralPath (Join-Path $projectRoot 'index.html') -Encoding utf8NoBOM -Value '<main class="test">archive test</main>'

try {
  & $auditHtml -Root $projectRoot -Archive -NoClipboard

  $defaultArchive = Join-Path $projectRoot '_awful-audit\audit-html.zip'
  Assert-Awful (Test-Path -LiteralPath $defaultArchive -PathType Leaf) 'default archive was not created'
  Assert-Awful (-not (Test-Path -LiteralPath (Join-Path $projectRoot '_awful-audit\audit-html.txt'))) 'standalone report file was created'

  $zip = [System.IO.Compression.ZipFile]::OpenRead($defaultArchive)
  try {
    Assert-Awful ($zip.Entries.Count -eq 1) 'archive must contain exactly one entry'
    $entry = $zip.Entries[0]
    Assert-Awful ($entry.FullName -eq 'audit-html.txt') 'archive entry name is incorrect'
    $reader = [System.IO.StreamReader]::new($entry.Open(), [System.Text.UTF8Encoding]::new($false, $true))
    try { $entryText = $reader.ReadToEnd() } finally { $reader.Dispose() }
    Assert-Awful ($entryText.Contains('HTML AUDIT')) 'archive does not contain the report'
    Assert-Awful ($entryText.Contains('archive test')) 'archive report content is incomplete'
  } finally {
    $zip.Dispose()
  }

  $customArchive = Join-Path $projectRoot 'reports\custom-report.zip'
  & $auditHtml -Root $projectRoot -ArchivePath $customArchive -NoClipboard
  Assert-Awful (Test-Path -LiteralPath $customArchive -PathType Leaf) 'ArchivePath must imply Archive'

  $conflictThrown = $false
  try {
    & $auditHtml -Root $projectRoot -Archive -Output (Join-Path $projectRoot 'report.txt') -NoClipboard
  } catch {
    $conflictThrown = $true
  }
  Assert-Awful $conflictThrown 'Output and Archive must be mutually exclusive'

  if ($IsWindows) {
    $clipboardArchive = Join-Path $projectRoot 'reports\clipboard-report.zip'
    & $auditHtml -Root $projectRoot -ArchivePath $clipboardArchive

    $oldExpected = $env:AWFUL_AUDIT_TEST_EXPECTED_FILE
    try {
      $env:AWFUL_AUDIT_TEST_EXPECTED_FILE = [System.IO.Path]::GetFullPath($clipboardArchive)
      $checkScript = @'
$ErrorActionPreference = 'Stop'
$expected = [System.IO.Path]::GetFullPath($env:AWFUL_AUDIT_TEST_EXPECTED_FILE)
$files = @(Get-Clipboard -Format FileDropList)
if ($files.Count -ne 1) { exit 1 }
$actual = [System.IO.Path]::GetFullPath([string]$files[0].FullName)
if (-not [string]::Equals($actual, $expected, [System.StringComparison]::OrdinalIgnoreCase)) { exit 2 }
'@
      $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($checkScript))
      & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -NonInteractive -STA -EncodedCommand $encoded
      Assert-Awful ($LASTEXITCODE -eq 0) 'archive was not copied to clipboard as a file'
    } finally {
      if ($null -eq $oldExpected) { Remove-Item Env:AWFUL_AUDIT_TEST_EXPECTED_FILE -ErrorAction SilentlyContinue } else { $env:AWFUL_AUDIT_TEST_EXPECTED_FILE = $oldExpected }
    }
  }

  Write-Host 'archive tests: passed'
} finally {
  Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
