param([string]$InstallDir)
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($InstallDir)) {
  $InstallDir = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'awful-audit'
}

$InstallDir = [System.IO.Path]::GetFullPath($InstallDir)
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptsDir = Join-Path $source 'scripts'
if (-not (Test-Path -LiteralPath $scriptsDir)) { throw "scripts directory not found: $scriptsDir" }

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Get-ChildItem -LiteralPath $scriptsDir -Force | Copy-Item -Destination $InstallDir -Force -Recurse

$auScriptPath = Join-Path $InstallDir 'au.ps1'
$cmdPath = Join-Path $InstallDir 'au.cmd'
Set-Content -LiteralPath $cmdPath -Encoding ascii -Value ("@echo off`r`npwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$auScriptPath`" %*`r`n")

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ([string]::IsNullOrWhiteSpace($userPath)) { $userPath = '' }
$parts = $userPath -split ';' | Where-Object { $_ -ne '' }
if (-not ($parts | Where-Object { $_.TrimEnd('\') -ieq $InstallDir.TrimEnd('\') })) {
  [Environment]::SetEnvironmentVariable('Path', (($parts + $InstallDir) -join ';'), 'User')
}
if (-not (($env:Path -split ';') | Where-Object { $_.TrimEnd('\') -ieq $InstallDir.TrimEnd('\') })) {
  $env:Path = $env:Path + ';' + $InstallDir
}

$escapedAuScriptPath = $auScriptPath.Replace("'", "''")
$marker = '# awful-audit'
$block = "$marker`nfunction au { & '$escapedAuScriptPath' @args }`nfunction ау { & '$escapedAuScriptPath' @args }"
$profiles = @($PROFILE, $PROFILE.CurrentUserAllHosts, $PROFILE.CurrentUserCurrentHost) | Select-Object -Unique
foreach ($profilePath in $profiles) {
  $profileDir = Split-Path -Parent $profilePath
  if ($profileDir) { New-Item -ItemType Directory -Force -Path $profileDir | Out-Null }
  if (-not (Test-Path -LiteralPath $profilePath)) { New-Item -ItemType File -Force -Path $profilePath | Out-Null }

  $profileText = Get-Content -LiteralPath $profilePath -Raw -ErrorAction SilentlyContinue
  if ($profileText -match [regex]::Escape($marker)) {
    $profileText = [regex]::Replace(
      $profileText,
      "(?ms)^# awful-audit\r?\nfunction au \{.*?\}\r?\nfunction ау \{.*?\}\r?\n?",
      $block + "`n"
    )
    Set-Content -LiteralPath $profilePath -Encoding utf8NoBOM -Value $profileText
  } else {
    Add-Content -LiteralPath $profilePath -Encoding utf8NoBOM -Value "`n$block`n"
  }
}

$functionBody = [scriptblock]::Create("& '$escapedAuScriptPath' @args")
Set-Item -LiteralPath Function:\global:au -Value $functionBody -Force
Set-Item -LiteralPath Function:\global:ау -Value $functionBody -Force

Write-Host 'installed:' $InstallDir
Write-Host 'run: au'
