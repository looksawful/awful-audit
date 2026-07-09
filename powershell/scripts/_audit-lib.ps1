$script:AwfulAuditSkipDirs = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@('.git','node_modules','dist','build','.next','.vite','coverage','tmp','temp','.vercel','.wrangler','.cache','.turbo','.parcel-cache','.svelte-kit','.nuxt','.output','out','vendor') | ForEach-Object { [void]$script:AwfulAuditSkipDirs.Add($_) }
$script:AwfulAuditCodeExts = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@('.html','.css','.js','.mjs','.cjs','.jsx','.ts','.tsx','.json','.md') | ForEach-Object { [void]$script:AwfulAuditCodeExts.Add($_) }
$script:AwfulAuditJsExts = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@('.js','.mjs','.cjs','.jsx','.ts','.tsx') | ForEach-Object { [void]$script:AwfulAuditJsExts.Add($_) }
$script:AwfulAuditAssetExts = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@('.png','.jpg','.jpeg','.webp','.gif','.svg','.avif','.mp4','.webm','.mov','.m4v','.mp3','.wav','.ogg','.glb','.gltf','.hdr','.ico','.woff','.woff2','.ttf','.otf','.pdf','.wasm') | ForEach-Object { [void]$script:AwfulAuditAssetExts.Add($_) }

function Get-AwfulEnvInt {
  param([string]$Name, [int]$Default, [int]$Minimum = 1)
  $raw = [Environment]::GetEnvironmentVariable($Name)
  $value = 0
  if (-not [string]::IsNullOrWhiteSpace($raw) -and [int]::TryParse($raw, [ref]$value) -and $value -ge $Minimum) { return $value }
  return $Default
}

function Get-AwfulMaxFileBytes { return (Get-AwfulEnvInt -Name 'AWFUL_AUDIT_MAX_FILE_KB' -Default 512 -Minimum 16) * 1KB }
function Get-AwfulMaxReportChars { return (Get-AwfulEnvInt -Name 'AWFUL_AUDIT_MAX_REPORT_MB' -Default 8 -Minimum 1) * 1MB }
function Get-AwfulMaxClipboardChars { return (Get-AwfulEnvInt -Name 'AWFUL_AUDIT_MAX_CLIPBOARD_MB' -Default 2 -Minimum 1) * 1MB }
function Get-AwfulMaxScanLineChars { return Get-AwfulEnvInt -Name 'AWFUL_AUDIT_MAX_SCAN_LINE_CHARS' -Default 20000 -Minimum 1000 }

function ConvertTo-AwfulRelPath {
  param([string]$Root, [string]$Path)
  $rootClean = $Root.TrimEnd('\','/')
  if ($Path.Length -ge $rootClean.Length) { return $Path.Substring($rootClean.Length).TrimStart('\','/').Replace('\','/') }
  return $Path.Replace('\','/')
}

function New-AwfulReport {
  param([int]$LimitChars)
  if ($LimitChars -le 0) { $LimitChars = Get-AwfulMaxReportChars }
  [pscustomobject]@{
    Builder = [System.Text.StringBuilder]::new()
    LimitChars = $LimitChars
    Truncated = $false
  }
}

function Add-AwfulLine {
  param([pscustomobject]$Report, [AllowNull()][string]$Text = '')
  if ($Report.Truncated) { return }
  $line = ([string]$Text) + [Environment]::NewLine
  if (($Report.Builder.Length + $line.Length) -gt $Report.LimitChars) {
    [void]$Report.Builder.AppendLine('')
    [void]$Report.Builder.AppendLine('[REPORT TRUNCATED: set AWFUL_AUDIT_MAX_REPORT_MB to a larger value if you need a bigger report]')
    $Report.Truncated = $true
    return
  }
  [void]$Report.Builder.Append($line)
}

function Get-AwfulReportText {
  param([pscustomobject]$Report)
  return $Report.Builder.ToString().TrimEnd()
}

function Test-AwfulRootDist {
  param([string]$Root, [System.IO.DirectoryInfo]$Directory)
  $rootDist = [System.IO.Path]::GetFullPath((Join-Path $Root 'dist')).TrimEnd('\','/')
  $candidate = [System.IO.Path]::GetFullPath($Directory.FullName).TrimEnd('\','/')
  return [string]::Equals($candidate, $rootDist, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-AwfulFiles {
  param(
    [string]$Root,
    [switch]$IncludeRootDist,
    [switch]$OnlyRootDist
  )
  $resolved = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\','/')
  if ($OnlyRootDist) {
    $dist = Join-Path $resolved 'dist'
    if (-not (Test-Path -LiteralPath $dist)) { return @() }
    $resolved = (Resolve-Path -LiteralPath $dist).Path.TrimEnd('\','/')
  }

  $files = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

  function Walk-AwfulDirectory {
    param([System.IO.DirectoryInfo]$Directory, [string]$ProjectRoot, [bool]$AllowRootDist)
    try {
      foreach ($file in $Directory.EnumerateFiles()) { [void]$files.Add($file) }
    } catch {
      Write-Host ('skip files: ' + $Directory.FullName + ' | ' + $_.Exception.Message)
    }

    $children = @()
    try { $children = @($Directory.EnumerateDirectories()) } catch { Write-Host ('skip dirs: ' + $Directory.FullName + ' | ' + $_.Exception.Message); return }
    foreach ($child in $children) {
      if ($script:AwfulAuditSkipDirs.Contains($child.Name)) {
        if ($AllowRootDist -and $child.Name -ieq 'dist' -and (Test-AwfulRootDist -Root $ProjectRoot -Directory $child)) {
          Walk-AwfulDirectory -Directory $child -ProjectRoot $ProjectRoot -AllowRootDist $false
        }
        continue
      }
      Walk-AwfulDirectory -Directory $child -ProjectRoot $ProjectRoot -AllowRootDist $false
    }
  }

  $projectRoot = $resolved
  if ($OnlyRootDist) { $projectRoot = Split-Path -Parent $resolved }
  Walk-AwfulDirectory -Directory ([System.IO.DirectoryInfo]::new($resolved)) -ProjectRoot $projectRoot -AllowRootDist ([bool]$IncludeRootDist)
  return @($files | Sort-Object FullName)
}

function New-AwfulAuditContext {
  param([string]$Root)
  $resolved = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\','/')
  [pscustomobject]@{
    Root = $resolved
    Files = @(Get-AwfulFiles -Root $resolved)
    FilesWithRootDist = $null
    DistFiles = $null
  }
}

function Get-AwfulContextFilesWithRootDist {
  param([pscustomobject]$Context)
  if ($null -eq $Context.FilesWithRootDist) { $Context.FilesWithRootDist = @(Get-AwfulFiles -Root $Context.Root -IncludeRootDist) }
  return $Context.FilesWithRootDist
}

function Get-AwfulContextDistFiles {
  param([pscustomobject]$Context)
  if ($null -eq $Context.DistFiles) { $Context.DistFiles = @(Get-AwfulFiles -Root $Context.Root -OnlyRootDist) }
  return $Context.DistFiles
}

function Read-AwfulText {
  param([System.IO.FileInfo]$File)
  $limit = Get-AwfulMaxFileBytes
  try {
    if ($File.Length -le $limit) {
      return [System.IO.File]::ReadAllText($File.FullName, [System.Text.UTF8Encoding]::new($false, $false))
    }
    $buffer = New-Object byte[] $limit
    $stream = [System.IO.File]::Open($File.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try { $read = $stream.Read($buffer, 0, $buffer.Length) } finally { $stream.Dispose() }
    $head = [System.Text.UTF8Encoding]::new($false, $false).GetString($buffer, 0, $read)
    return $head + [Environment]::NewLine + ('[TRUNCATED: file is ' + $File.Length + ' bytes, copied first ' + $limit + ' bytes]')
  } catch {
    return 'READ ERROR: ' + $_.Exception.Message
  }
}

function Get-AwfulTextLines {
  param([System.IO.FileInfo]$File)
  return (Read-AwfulText -File $File) -split "`r?`n"
}

function Get-AwfulScanLine {
  param([string]$Line)
  $limit = Get-AwfulMaxScanLineChars
  if ($Line.Length -gt $limit) { return $Line.Substring(0, $limit) + ' [LINE TRUNCATED]' }
  return $Line
}

function Add-AwfulFileBlock {
  param([pscustomobject]$Report, [pscustomobject]$Context, [System.IO.FileInfo]$File, [switch]$WithSize)
  $rel = ConvertTo-AwfulRelPath -Root $Context.Root -Path $File.FullName
  Add-AwfulLine $Report ''
  Add-AwfulLine $Report ('FILE: ' + $rel)
  if ($WithSize) { Add-AwfulLine $Report ('SIZE: ' + $File.Length + ' bytes') }
  Add-AwfulLine $Report (Read-AwfulText -File $File)
}

function Invoke-AwfulGit {
  param([string]$Root)
  $lines = [System.Collections.Generic.List[string]]::new()
  $commands = @(
    @('branch','--show-current'),
    @('status','--short'),
    @('log','-1','--oneline')
  )
  foreach ($cmd in $commands) {
    try {
      Push-Location -LiteralPath $Root
      try { $out = (& git @cmd 2>&1 | Out-String).TrimEnd() } finally { Pop-Location }
      if (-not [string]::IsNullOrWhiteSpace($out)) { [void]$lines.Add($out) }
    } catch {
      [void]$lines.Add('GIT ERROR: ' + $_.Exception.Message)
    }
  }
  return ($lines -join [Environment]::NewLine)
}

function Invoke-AwfulAuditFull {
  param([pscustomobject]$Context, [int]$LimitChars)
  $r = New-AwfulReport -LimitChars $LimitChars
  $code = @($Context.Files | Where-Object { $script:AwfulAuditCodeExts.Contains($_.Extension) })
  Add-AwfulLine $r 'FULL PROJECT AUDIT'
  Add-AwfulLine $r ('ROOT: ' + $Context.Root)
  Add-AwfulLine $r ('GENERATED: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
  Add-AwfulLine $r ''
  Add-AwfulLine $r 'GIT'
  Add-AwfulLine $r (Invoke-AwfulGit -Root $Context.Root)
  Add-AwfulLine $r ''
  Add-AwfulLine $r 'CODE'
  foreach ($f in $code) { if ($r.Truncated) { break }; Add-AwfulFileBlock -Report $r -Context $Context -File $f -WithSize }
  Add-AwfulLine $r ''
  Add-AwfulLine $r 'INVENTORY'
  Add-AwfulLine $r ('TOTAL FILES: ' + $Context.Files.Count)
  foreach ($f in $Context.Files) {
    if ($r.Truncated) { break }
    $rel = ConvertTo-AwfulRelPath -Root $Context.Root -Path $f.FullName
    Add-AwfulLine $r ($rel + ' | ' + $f.Extension + ' | ' + [Math]::Round($f.Length / 1KB, 2) + ' KB')
  }
  return Get-AwfulReportText $r
}

function Invoke-AwfulAuditHtml {
  param([pscustomobject]$Context, [int]$LimitChars)
  $r = New-AwfulReport -LimitChars $LimitChars
  Add-AwfulLine $r 'HTML AUDIT'
  Add-AwfulLine $r ('ROOT: ' + $Context.Root)
  foreach ($f in @($Context.Files | Where-Object { $_.Extension -ieq '.html' })) { if ($r.Truncated) { break }; Add-AwfulFileBlock -Report $r -Context $Context -File $f }
  return Get-AwfulReportText $r
}

function Invoke-AwfulAuditJs {
  param([pscustomobject]$Context, [int]$LimitChars)
  $r = New-AwfulReport -LimitChars $LimitChars
  Add-AwfulLine $r 'JS AUDIT'
  Add-AwfulLine $r ('ROOT: ' + $Context.Root)
  foreach ($f in @($Context.Files | Where-Object { $script:AwfulAuditJsExts.Contains($_.Extension) })) { if ($r.Truncated) { break }; Add-AwfulFileBlock -Report $r -Context $Context -File $f }
  return Get-AwfulReportText $r
}

function Invoke-AwfulAuditCss {
  param([pscustomobject]$Context, [int]$LimitChars)
  $r = New-AwfulReport -LimitChars $LimitChars
  Add-AwfulLine $r 'CSS AUDIT'
  Add-AwfulLine $r ('ROOT: ' + $Context.Root)
  foreach ($f in @($Context.Files | Where-Object { $_.Extension -ieq '.css' })) { if ($r.Truncated) { break }; Add-AwfulFileBlock -Report $r -Context $Context -File $f }
  Add-AwfulLine $r ''
  Add-AwfulLine $r 'CLASS MENTIONS'
  $rx = [regex]'(?i)(class(Name)?\s*=|classList\.|querySelector(All)?\(|getElementsByClassName\(|\.[_a-zA-Z-][_a-zA-Z0-9-]*)'
  foreach ($f in @($Context.Files | Where-Object { $script:AwfulAuditCodeExts.Contains($_.Extension) })) {
    if ($r.Truncated) { break }
    $rel = ConvertTo-AwfulRelPath -Root $Context.Root -Path $f.FullName
    $lines = Get-AwfulTextLines -File $f
    for ($i = 0; $i -lt $lines.Count; $i++) {
      if ($r.Truncated) { break }
      $line = Get-AwfulScanLine -Line ([string]$lines[$i])
      if ($rx.IsMatch($line)) { Add-AwfulLine $r ($rel + ':' + ($i + 1) + ' | ' + $line.Trim()) }
    }
  }
  return Get-AwfulReportText $r
}

function Invoke-AwfulAuditAssets {
  param([pscustomobject]$Context, [int]$LimitChars)
  $r = New-AwfulReport -LimitChars $LimitChars
  $assets = @($Context.Files | Where-Object { $script:AwfulAuditAssetExts.Contains($_.Extension) })
  $code = @($Context.Files | Where-Object { $script:AwfulAuditCodeExts.Contains($_.Extension) })
  $rx = [regex]'(?i)(?<ref>(?<![\w./\\:@%+\-])[\w./\\:@%+\-]{1,260}\.(png|jpe?g|webp|gif|svg|avif|mp4|webm|mov|m4v|mp3|wav|ogg|glb|gltf|hdr|ico|woff2?|ttf|otf|pdf|wasm)([?#][^"''\s)]{0,200})?)'
  Add-AwfulLine $r 'ASSET AUDIT'
  Add-AwfulLine $r ('ROOT: ' + $Context.Root)
  Add-AwfulLine $r ('ASSETS: ' + $assets.Count)
  foreach ($a in $assets) {
    if ($r.Truncated) { break }
    $rel = ConvertTo-AwfulRelPath -Root $Context.Root -Path $a.FullName
    Add-AwfulLine $r ($rel + ' | ' + $a.Extension.ToLowerInvariant() + ' | ' + [Math]::Round($a.Length / 1KB, 2) + ' KB')
  }
  Add-AwfulLine $r ''
  Add-AwfulLine $r 'REFERENCES'
  foreach ($f in $code) {
    if ($r.Truncated) { break }
    $rel = ConvertTo-AwfulRelPath -Root $Context.Root -Path $f.FullName
    $lines = Get-AwfulTextLines -File $f
    for ($i = 0; $i -lt $lines.Count; $i++) {
      if ($r.Truncated) { break }
      $line = Get-AwfulScanLine -Line ([string]$lines[$i])
      foreach ($m in $rx.Matches($line)) {
        if ($r.Truncated) { break }
        Add-AwfulLine $r ($rel + ':' + ($i + 1) + ' | ' + $m.Groups['ref'].Value + ' | ' + $line.Trim())
      }
    }
  }
  return Get-AwfulReportText $r
}

function Invoke-AwfulAuditCssDist {
  param([pscustomobject]$Context, [int]$LimitChars)
  $r = New-AwfulReport -LimitChars $LimitChars
  $files = @(Get-AwfulContextFilesWithRootDist -Context $Context | Where-Object { $_.Extension -ieq '.css' })
  Add-AwfulLine $r 'CSS DIST AUDIT'
  Add-AwfulLine $r ('ROOT: ' + $Context.Root)
  foreach ($f in $files) { if ($r.Truncated) { break }; Add-AwfulFileBlock -Report $r -Context $Context -File $f }
  return Get-AwfulReportText $r
}

function Invoke-AwfulAuditDist {
  param([pscustomObject]$Context, [int]$LimitChars)
  $r = New-AwfulReport -LimitChars $LimitChars
  $dist = Join-Path $Context.Root 'dist'
  Add-AwfulLine $r 'DIST AUDIT'
  Add-AwfulLine $r ('ROOT: ' + $Context.Root)
  if (-not (Test-Path -LiteralPath $dist)) { Add-AwfulLine $r 'DIST NOT FOUND'; return Get-AwfulReportText $r }
  $files = @(Get-AwfulContextDistFiles -Context $Context)
  $total = 0
  foreach ($f in $files) { $total += $f.Length }
  Add-AwfulLine $r ('FILES: ' + $files.Count)
  Add-AwfulLine $r ('TOTAL SIZE: ' + [Math]::Round($total / 1MB, 2) + ' MB')
  foreach ($f in @($files | Sort-Object Length -Descending)) {
    if ($r.Truncated) { break }
    $rel = ConvertTo-AwfulRelPath -Root $Context.Root -Path $f.FullName
    Add-AwfulLine $r ($rel + ' | ' + $f.Extension + ' | ' + [Math]::Round($f.Length / 1KB, 2) + ' KB')
  }
  return Get-AwfulReportText $r
}

function Invoke-AwfulAudit {
  param([string]$Mode, [string]$Root = (Get-Location).Path)
  $ctx = New-AwfulAuditContext -Root $Root
  $modeKey = $Mode.Trim().ToLowerInvariant()
  if ($modeKey -eq 'all') {
    $order = @('full','assets','css','html','js','cssdist','dist')
    $master = New-AwfulReport -LimitChars (Get-AwfulMaxReportChars)
    $sectionLimit = [Math]::Max(512KB, [int]([Math]::Floor((Get-AwfulMaxReportChars) / $order.Count)))
    Add-AwfulLine $master 'AWFUL AUDIT'
    Add-AwfulLine $master ('ROOT: ' + $ctx.Root)
    foreach ($key in $order) {
      Write-Host ('running: ' + $key)
      if ($master.Truncated) { break }
      Add-AwfulLine $master ''
      Add-AwfulLine $master ('=== ' + $key.ToUpperInvariant() + ' ===')
      Add-AwfulLine $master (Invoke-AwfulAuditSection -Mode $key -Context $ctx -LimitChars $sectionLimit)
    }
    return [pscustomobject]@{ Mode = 'all'; Root = $ctx.Root; Text = (Get-AwfulReportText $master) }
  }
  return [pscustomobject]@{ Mode = $modeKey; Root = $ctx.Root; Text = (Invoke-AwfulAuditSection -Mode $modeKey -Context $ctx -LimitChars (Get-AwfulMaxReportChars)) }
}

function Invoke-AwfulAuditSection {
  param([string]$Mode, [pscustomobject]$Context, [int]$LimitChars)
  switch ($Mode) {
    'full' { return Invoke-AwfulAuditFull -Context $Context -LimitChars $LimitChars }
    'assets' { return Invoke-AwfulAuditAssets -Context $Context -LimitChars $LimitChars }
    'css' { return Invoke-AwfulAuditCss -Context $Context -LimitChars $LimitChars }
    'html' { return Invoke-AwfulAuditHtml -Context $Context -LimitChars $LimitChars }
    'js' { return Invoke-AwfulAuditJs -Context $Context -LimitChars $LimitChars }
    'cssdist' { return Invoke-AwfulAuditCssDist -Context $Context -LimitChars $LimitChars }
    'dist' { return Invoke-AwfulAuditDist -Context $Context -LimitChars $LimitChars }
    default { throw ('Unknown mode: ' + $Mode) }
  }
}

function Complete-AwfulAudit {
  param(
    [pscustomobject]$Result,
    [switch]$NoClipboard,
    [string]$Output
  )
  $text = [string]$Result.Text
  $outPath = $null
  if (-not [string]::IsNullOrWhiteSpace($Output)) {
    $outPath = $Output
    if (-not [System.IO.Path]::IsPathRooted($outPath)) { $outPath = Join-Path $Result.Root $outPath }
    $parent = Split-Path -Parent $outPath
    if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    Set-Content -LiteralPath $outPath -Encoding utf8NoBOM -Value $text
  }

  if (-not $NoClipboard) {
    try {
      if ($null -eq $outPath) {
        Set-Clipboard -Value $text
        Write-Host 'clipboard: full report copied'
      } else {
        Set-Clipboard -Value ('awful-audit report saved: ' + $outPath)
        Write-Host 'clipboard: output path copied'
      }
    } catch {
      Write-Host ('clipboard: failed | ' + $_.Exception.Message)
    }
  } else {
    Write-Host 'clipboard: disabled'
  }

  if ($outPath) { Write-Host ('output: ' + $outPath) }
  Write-Host ('chars: ' + $text.Length)
}
