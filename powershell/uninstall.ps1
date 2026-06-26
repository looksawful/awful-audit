param([string]$InstallDir)
$ErrorActionPreference='Continue'
if([string]::IsNullOrWhiteSpace($InstallDir)){ $InstallDir=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'awful-audit' }
$userPath=[Environment]::GetEnvironmentVariable('Path','User')
if($userPath){ $parts=$userPath -split ';' | Where-Object { $_ -ne '' -and $_.TrimEnd('\') -ine $InstallDir.TrimEnd('\') }; [Environment]::SetEnvironmentVariable('Path',($parts -join ';'),'User') }
Remove-Item -LiteralPath $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'removed:' $InstallDir
