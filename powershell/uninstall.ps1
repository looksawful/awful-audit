param([string]$InstallDir)
$ErrorActionPreference = 'Continue'

if ([string]::IsNullOrWhiteSpace($InstallDir)) {
  $InstallDir = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'awful-audit'
}
$InstallDir = [System.IO.Path]::GetFullPath($InstallDir)

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath) {
  $parts = $userPath -split ';' | Where-Object { $_ -ne '' -and $_.TrimEnd('\') -ine $InstallDir.TrimEnd('\') }
  [Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), 'User')
}

$marker = '# awful-audit'
$profiles = @($PROFILE, $PROFILE.CurrentUserAllHosts, $PROFILE.CurrentUserCurrentHost) | Select-Object -Unique
foreach ($profilePath in $profiles) {
  if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) { continue }
  $profileText = Get-Content -LiteralPath $profilePath -Raw -ErrorAction SilentlyContinue
  if ($profileText -notmatch [regex]::Escape($marker)) { continue }
  $updated = [regex]::Replace(
    $profileText,
    "(?ms)^# awful-audit\r?\nfunction au \{.*?\}\r?\nfunction ау \{.*?\}\r?\n?",
    ''
  )
  if ($updated -ne $profileText) {
    Set-Content -LiteralPath $profilePath -Encoding utf8NoBOM -Value $updated
  }
}

Remove-Item Function:\global:au -Force -ErrorAction SilentlyContinue
Remove-Item Function:\global:ау -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'removed:' $InstallDir
