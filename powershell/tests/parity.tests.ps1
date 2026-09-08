$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-Awful {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw ('ASSERT FAILED: ' + $Message) }
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$scriptsRoot = Join-Path $repoRoot 'powershell\scripts'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('awful-audit-parity-' + [guid]::NewGuid().ToString('N'))
$projectRoot = Join-Path $tempRoot 'project'
New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot 'src') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot 'public') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot 'dist') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot 'node_modules\pkg') | Out-Null
Set-Content -LiteralPath (Join-Path $projectRoot 'index.html') -Encoding utf8NoBOM -Value '<main class="hero"><img src="public/hero.webp"></main>'
Set-Content -LiteralPath (Join-Path $projectRoot 'src\app.ts') -Encoding utf8NoBOM -Value 'document.querySelector(".hero")?.classList.add("ready")'
Set-Content -LiteralPath (Join-Path $projectRoot 'src\style.css') -Encoding utf8NoBOM -Value '.hero{background:url("../public/hero.webp")}'
Set-Content -LiteralPath (Join-Path $projectRoot 'public\hero.webp') -Encoding utf8NoBOM -Value 'asset'
Set-Content -LiteralPath (Join-Path $projectRoot 'dist\bundle.css') -Encoding utf8NoBOM -Value '.hero{}'
Set-Content -LiteralPath (Join-Path $projectRoot 'node_modules\pkg\ignored.js') -Encoding utf8NoBOM -Value 'ignored'

function Invoke-Pair {
  param([string]$Mode)
  $psOut = Join-Path $tempRoot ($Mode + '-powershell.txt')
  $pyOut = Join-Path $tempRoot ($Mode + '-python.txt')
  $wrapperName = if ($Mode -eq 'cssdist') { 'audit-css-dist.ps1' } else { 'audit-' + $Mode + '.ps1' }
  & (Join-Path $scriptsRoot $wrapperName) -Root $projectRoot -Output $psOut -NoClipboard
  & python -m awful_scripts $Mode --root $projectRoot --output $pyOut --no-clipboard
  if ($LASTEXITCODE -ne 0) { throw ('Python audit failed for mode: ' + $Mode) }
  return [pscustomobject]@{
    PowerShell = Get-Content -LiteralPath $psOut -Raw
    Python = Get-Content -LiteralPath $pyOut -Raw
  }
}

try {
  $full = Invoke-Pair -Mode 'full'
  foreach ($text in @($full.PowerShell, $full.Python)) {
    Assert-Awful ($text.Contains('FULL PROJECT AUDIT')) 'full heading drifted'
    Assert-Awful ($text.Contains('src/app.ts')) 'source TypeScript missing from full report'
    Assert-Awful (-not $text.Contains('node_modules/pkg/ignored.js')) 'node_modules leaked into full report'
    Assert-Awful (-not $text.Contains('dist/bundle.css')) 'root dist leaked into full source report'
  }

  $assets = Invoke-Pair -Mode 'assets'
  foreach ($text in @($assets.PowerShell, $assets.Python)) {
    Assert-Awful ($text.Contains('public/hero.webp')) 'asset inventory/reference drifted'
  }

  $cssdist = Invoke-Pair -Mode 'cssdist'
  foreach ($text in @($cssdist.PowerShell, $cssdist.Python)) {
    Assert-Awful ($text.Contains('src/style.css')) 'source CSS missing from cssdist'
    Assert-Awful ($text.Contains('dist/bundle.css')) 'root dist CSS missing from cssdist'
  }

  $dist = Invoke-Pair -Mode 'dist'
  foreach ($text in @($dist.PowerShell, $dist.Python)) {
    Assert-Awful ($text.Contains('dist/bundle.css')) 'root dist file missing from dist mode'
    Assert-Awful (-not $text.Contains('src/style.css')) 'source CSS leaked into dist-only mode'
  }

  Write-Host 'parity tests: passed'
} finally {
  Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
