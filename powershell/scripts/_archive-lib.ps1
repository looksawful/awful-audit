function Resolve-AwfulArchivePath {
  param([pscustomobject]$Result, [string]$ArchivePath)

  if ([string]::IsNullOrWhiteSpace($ArchivePath)) {
    $ArchivePath = Join-Path '_awful-audit' ('audit-' + $Result.Mode + '.zip')
  }
  if (-not [System.IO.Path]::IsPathRooted($ArchivePath)) {
    $ArchivePath = Join-Path $Result.Root $ArchivePath
  }

  $ArchivePath = [System.IO.Path]::GetFullPath($ArchivePath)
  if ([System.IO.Path]::GetExtension($ArchivePath) -ine '.zip') {
    throw 'ArchivePath must use the .zip extension.'
  }

  $parent = Split-Path -Parent $ArchivePath
  if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  return $ArchivePath
}

function New-AwfulAuditArchive {
  param([pscustomobject]$Result, [string]$ArchivePath)

  $outPath = Resolve-AwfulArchivePath -Result $Result -ArchivePath $ArchivePath
  $entryName = 'audit-' + $Result.Mode + '.txt'
  $memory = [System.IO.MemoryStream]::new()

  try {
    $zip = [System.IO.Compression.ZipArchive]::new($memory, [System.IO.Compression.ZipArchiveMode]::Create, $true)
    try {
      $entry = $zip.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
      $entryStream = $entry.Open()
      try {
        $writer = [System.IO.StreamWriter]::new($entryStream, [System.Text.UTF8Encoding]::new($false), 4096, $true)
        try { $writer.Write([string]$Result.Text) } finally { $writer.Dispose() }
      } finally {
        $entryStream.Dispose()
      }
    } finally {
      $zip.Dispose()
    }

    [System.IO.File]::WriteAllBytes($outPath, $memory.ToArray())
  } finally {
    $memory.Dispose()
  }

  return [pscustomobject]@{
    Path = $outPath
    EntryName = $entryName
    Bytes = ([System.IO.FileInfo]::new($outPath)).Length
  }
}

function Set-AwfulClipboardFile {
  param([Parameter(Mandatory)][string]$Path)

  if (-not $IsWindows) { throw 'File clipboard is supported only on Windows.' }

  $fullPath = [System.IO.Path]::GetFullPath($Path)
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw ('Clipboard file not found: ' + $fullPath)
  }

  $windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  if (-not (Test-Path -LiteralPath $windowsPowerShell -PathType Leaf)) {
    throw ('Windows PowerShell not found: ' + $windowsPowerShell)
  }

  $oldClipboardFile = $env:AWFUL_AUDIT_CLIPBOARD_FILE
  try {
    $env:AWFUL_AUDIT_CLIPBOARD_FILE = $fullPath
    $clipboardScript = @'
$ErrorActionPreference = 'Stop'
Set-Clipboard -LiteralPath $env:AWFUL_AUDIT_CLIPBOARD_FILE
'@
    $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($clipboardScript))

    for ($attempt = 1; $attempt -le 3; $attempt++) {
      & $windowsPowerShell -NoLogo -NoProfile -NonInteractive -STA -EncodedCommand $encoded *> $null
      if ($LASTEXITCODE -eq 0) { return }
      Start-Sleep -Milliseconds (100 * $attempt)
    }

    throw 'Windows clipboard rejected the file after three attempts.'
  } finally {
    if ($null -eq $oldClipboardFile) {
      Remove-Item Env:AWFUL_AUDIT_CLIPBOARD_FILE -ErrorAction SilentlyContinue
    } else {
      $env:AWFUL_AUDIT_CLIPBOARD_FILE = $oldClipboardFile
    }
  }
}

function Complete-AwfulAuditOutput {
  param(
    [pscustomobject]$Result,
    [switch]$NoClipboard,
    [string]$Output,
    [Alias('Zip')][switch]$Archive,
    [string]$ArchivePath
  )

  $archiveRequested = $Archive -or -not [string]::IsNullOrWhiteSpace($ArchivePath)
  if (-not $archiveRequested) {
    Complete-AwfulAudit -Result $Result -NoClipboard:$NoClipboard -Output $Output
    return
  }

  if (-not [string]::IsNullOrWhiteSpace($Output)) {
    throw 'Output cannot be combined with Archive or ArchivePath.'
  }

  $archiveInfo = New-AwfulAuditArchive -Result $Result -ArchivePath $ArchivePath

  if ($NoClipboard) {
    Write-Host 'clipboard: disabled'
  } else {
    try {
      Set-AwfulClipboardFile -Path $archiveInfo.Path
      Write-Host 'clipboard: archive file copied'
    } catch {
      Write-Host ('clipboard: failed | ' + $_.Exception.Message)
    }
  }

  Write-Host ('archive: ' + $archiveInfo.Path)
  Write-Host ('archive entry: ' + $archiveInfo.EntryName)
  Write-Host ('archive bytes: ' + $archiveInfo.Bytes)
  Write-Host ('chars: ' + ([string]$Result.Text).Length)
}
