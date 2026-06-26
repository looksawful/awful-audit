param([string]$InstallDir)
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($InstallDir)){ $InstallDir=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'awful-audit' }
$source=Split-Path -Parent $MyInvocation.MyCommand.Path
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-Item -LiteralPath (Join-Path $source 'scripts\*') -Destination $InstallDir -Force -Recurse
$cmdPath=Join-Path $InstallDir 'au.cmd'
Set-Content -LiteralPath $cmdPath -Encoding ascii -Value ("@echo off`r`npwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$InstallDir\au.ps1`" %*`r`n")
$userPath=[Environment]::GetEnvironmentVariable('Path','User')
if([string]::IsNullOrWhiteSpace($userPath)){ $userPath='' }
$parts=$userPath -split ';' | Where-Object { $_ -ne '' }
if(-not ($parts | Where-Object { $_.TrimEnd('\') -ieq $InstallDir.TrimEnd('\') })){ [Environment]::SetEnvironmentVariable('Path',(($parts + $InstallDir) -join ';'),'User') }
if(-not (($env:Path -split ';') | Where-Object { $_.TrimEnd('\') -ieq $InstallDir.TrimEnd('\') })){ $env:Path=$env:Path + ';' + $InstallDir }
$profiles=@($PROFILE,$PROFILE.CurrentUserAllHosts,$PROFILE.CurrentUserCurrentHost) | Select-Object -Unique
foreach($p in $profiles){ $dir=Split-Path -Parent $p; if($dir){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }; if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType File -Force -Path $p | Out-Null }; $txt=Get-Content -LiteralPath $p -Raw -ErrorAction SilentlyContinue; $marker='# awful-audit'; if($txt -notmatch [regex]::Escape($marker)){ Add-Content -LiteralPath $p -Encoding utf8NoBOM -Value "`n$marker`nfunction au { & '$InstallDir\au.ps1' @args }`nfunction ау { & '$InstallDir\au.ps1' @args }`n" } }
function global:au { & "$InstallDir\au.ps1" @args }
function global:ау { & "$InstallDir\au.ps1" @args }
Write-Host 'installed:' $InstallDir
Write-Host 'run: au'
