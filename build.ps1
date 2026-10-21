# Local build with music: copies the Space Age soundtrack from your installed game into this folder (via
# install-music.ps1) and (with -Install) packages the mod, music included, into a Factorio mods folder.
# The copied files are Wube's DLC assets: keep them on this PC, never publish them. For a zip without music
# that can be shared, use package.ps1.
#
#   .\build.ps1            # copy music + track list into this folder
#   .\build.ps1 -Install   # ... and build sa-music-on-nauvis_<version>.zip in the mods folder (close Factorio first)
param(
  [string]$Game = 'E:\games\steam\steamapps\common\Factorio',
  [string]$ModsDir = 'E:\games\mods\Factorio',
  [switch]$Install
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

$mod = $PSScriptRoot
$info = Get-Content (Join-Path $mod 'info.json') -Raw | ConvertFrom-Json

& (Join-Path $mod 'install-music.ps1') -Game $Game
if (-not (Test-Path (Join-Path $mod 'ambient-sounds.lua'))) { throw 'install-music.ps1 did not copy the music' }

if (-not $Install) { exit 0 }

$top = "$($info.name)_$($info.version)"
$zipPath = Join-Path $ModsDir "$top.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
$zip = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
try {
  foreach ($item in 'info.json', 'settings.lua', 'data.lua', 'data-final-fixes.lua', 'control.lua', 'ambient-sounds.lua', 'locale', 'sound', 'thumbnail.png') {
    $path = Join-Path $mod $item
    $files = if (Test-Path $path -PathType Container) { Get-ChildItem $path -Recurse -File } else { Get-Item $path }
    foreach ($f in $files) {
      $rel = $f.FullName.Substring($mod.Length + 1) -replace '\\', '/'
      $level = if ($f.Extension -eq '.ogg') { [IO.Compression.CompressionLevel]::NoCompression } else { [IO.Compression.CompressionLevel]::Optimal }
      [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $f.FullName, "$top/$rel", $level)
    }
  }
} finally { $zip.Dispose() }
'installed {0} ({1:N0} MB)' -f $zipPath, ((Get-Item $zipPath).Length / 1MB)
# Older versions: a running game locks its zip, so only warn (Factorio loads the highest version anyway).
foreach ($old in Get-ChildItem $ModsDir -Filter "$($info.name)_*.zip" | Where-Object { $_.FullName -ne $zipPath }) {
  try { Remove-Item $old.FullName -Force -ErrorAction Stop; "removed old $($old.Name)" } catch { "WARNING: $($old.Name) is locked (game running?); delete it after closing Factorio" }
}
exit 0
