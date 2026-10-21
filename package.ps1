# Builds the shareable zip for the mod portal: the mod only, without any Space Age music or track list (players copy
# those from their own game by hand, or with the setup scripts from the GitHub repo). The portal rejects scripts
# and executables (exe, bat, cmd, ps1, sh, py), so none go into the zip.
#
#   .\package.ps1   # -> dist\sa-music-on-nauvis_<version>.zip
param([string]$OutDir = (Join-Path $PSScriptRoot 'dist'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

$mod = $PSScriptRoot
$info = Get-Content (Join-Path $mod 'info.json') -Raw | ConvertFrom-Json
$top = "$($info.name)_$($info.version)"
New-Item -ItemType Directory -Force $OutDir | Out-Null
$zipPath = Join-Path $OutDir "$top.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
$forbidden = '.exe', '.bat', '.cmd', '.ps1', '.sh', '.py'

$zip = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
try {
  foreach ($item in 'info.json', 'settings.lua', 'data.lua', 'data-final-fixes.lua', 'control.lua', 'locale', 'README.md', 'thumbnail.png') {
    $path = Join-Path $mod $item
    $files = if (Test-Path $path -PathType Container) { Get-ChildItem $path -Recurse -File } else { Get-Item $path }
    foreach ($f in $files) {
      if ($forbidden -contains $f.Extension) { throw "$($f.Name): the mod portal rejects $($f.Extension) files" }
      $rel = $f.FullName.Substring($mod.Length + 1) -replace '\\', '/'
      [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $f.FullName, "$top/$rel")
    }
  }
} finally { $zip.Dispose() }
'packaged {0} ({1:N0} KB)' -f $zipPath, ((Get-Item $zipPath).Length / 1KB)
