$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-Awful {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw ('ASSERT FAILED: ' + $Message) }
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$installer = Join-Path $repoRoot 'powershell\install.ps1'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('awful-audit-install-tests-' + [guid]::NewGuid().ToString('N'))
$installDir = Join-Path $tempRoot 'installed'
$projectRoot = Join-Path $tempRoot 'project'
New-Item -ItemType Directory -Force -Path $projectRoot | Out-Null
Set-Content -LiteralPath (Join-Path $projectRoot 'index.html') -Encoding utf8NoBOM -Value '<main>installer test</main>'

$oldUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$oldProcessPath = $env:Path
$profiles = @($PROFILE, $PROFILE.CurrentUserAllHosts, $PROFILE.CurrentUserCurrentHost) | Select-Object -Unique
$profileBackups = foreach ($profilePath in $profiles) {
  [pscustomobject]@{
    Path = $profilePath
    Existed = Test-Path -LiteralPath $profilePath -PathType Leaf
    Content = if (Test-Path -LiteralPath $profilePath -PathType Leaf) { Get-Content -LiteralPath $profilePath -Raw } else { $null }
  }
}

try {
  & $installer -InstallDir $installDir

  $auCommand = Get-Command au -CommandType Function -ErrorAction Stop
  $cyrillicCommand = Get-Command ау -CommandType Function -ErrorAction Stop
  Assert-Awful ($auCommand.Definition.Contains($installDir)) 'au function does not retain the installed path after install.ps1 returns'
  Assert-Awful ($cyrillicCommand.Definition.Contains($installDir)) 'ау function does not retain the installed path after install.ps1 returns'

  $archivePath = Join-Path $projectRoot 'reports\from-au.zip'
  au html -Root $projectRoot -ArchivePath $archivePath -NoClipboard
  Assert-Awful (Test-Path -LiteralPath $archivePath -PathType Leaf) 'au cannot run immediately after installation'

  $textPath = Join-Path $projectRoot 'reports\from-cyrillic-au.txt'
  ау html -Root $projectRoot -Output $textPath -NoClipboard
  Assert-Awful (Test-Path -LiteralPath $textPath -PathType Leaf) 'ау cannot run immediately after installation'

  Write-Host 'install tests: passed'
} finally {
  Remove-Item Function:\au -Force -ErrorAction SilentlyContinue
  Remove-Item Function:\ау -Force -ErrorAction SilentlyContinue
  [Environment]::SetEnvironmentVariable('Path', $oldUserPath, 'User')
  $env:Path = $oldProcessPath

  foreach ($backup in $profileBackups) {
    if ($backup.Existed) {
      $parent = Split-Path -Parent $backup.Path
      if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
      [System.IO.File]::WriteAllText($backup.Path, [string]$backup.Content, [System.Text.UTF8Encoding]::new($false))
    } else {
      Remove-Item -LiteralPath $backup.Path -Force -ErrorAction SilentlyContinue
    }
  }

  Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
