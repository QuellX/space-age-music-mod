# Copies the Space Age music from your own Factorio installation into this mod (Windows).
# Start it with install-music.cmd (double-click). The music is Wube's: it stays on your PC.
#
#   install-music.cmd                       # find Factorio automatically (Steam, GOG, standalone)
#   install-music.cmd "D:\Games\Factorio"   # or name the Factorio folder
param([string]$Game)
$ErrorActionPreference = 'Stop'
$mod = $PSScriptRoot
$name = 'sa-music-on-nauvis'

function Test-Game([string]$dir) { $dir -and (Test-Path -LiteralPath (Join-Path $dir 'data\space-age\sound\ambient')) }

function Find-Game {
  $candidates = New-Object Collections.Generic.List[string]
  $steamRoots = @()
  foreach ($key in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam') {
    try {
      $p = Get-ItemProperty -Path $key -ErrorAction Stop
      foreach ($v in $p.SteamPath, $p.InstallPath) { if ($v) { $steamRoots += ($v -replace '/', '\') } }
    } catch {}
  }
  foreach ($root in ($steamRoots | Select-Object -Unique)) {
    $candidates.Add((Join-Path $root 'steamapps\common\Factorio'))
    $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $vdf) {
      foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
        $candidates.Add((Join-Path ($m.Groups[1].Value -replace '\\\\', '\') 'steamapps\common\Factorio'))
      }
    }
  }
  foreach ($base in $env:ProgramFiles, ${env:ProgramFiles(x86)}, 'C:\GOG Games', 'C:\Games', 'D:\Games', 'D:\SteamLibrary\steamapps\common', 'E:\SteamLibrary\steamapps\common') {
    if ($base) { $candidates.Add((Join-Path $base 'Factorio')) }
  }
  foreach ($c in $candidates) { if (Test-Game $c) { return $c } }
  return $null
}

Write-Host 'Space Age Music on Nauvis: copying the Space Age music from your game.' -ForegroundColor Cyan
if (-not (Test-Path -LiteralPath (Join-Path $mod 'info.json'))) {
  throw "This script must stay in the mod's folder (next to info.json). If the mod is still a .zip, unzip it into your mods folder first."
}
if (Get-Process factorio -ErrorAction SilentlyContinue) {
  Write-Host 'Factorio is running. Close it first, then run this again.' -ForegroundColor Yellow
  exit 1
}

if (-not (Test-Game $Game)) { $Game = Find-Game }
while (-not (Test-Game $Game)) {
  Write-Host 'Could not find a Factorio installation with the Space Age expansion.'
  $Game = (Read-Host 'Paste the Factorio folder (the one that contains "bin" and "data"), or press Enter to cancel').Trim('" ')
  if (-not $Game) { exit 1 }
}
$src = Join-Path $Game 'data\space-age'
Write-Host "Factorio found: $Game"

# The music and its track scripts, plus the track list, copied unchanged (the mod redirects their paths).
$dest = Join-Path $mod 'sound\ambient'
if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
New-Item -ItemType Directory -Force $dest | Out-Null
Write-Host 'Copying about 1.1 GB of music, this can take a minute...'
robocopy (Join-Path $src 'sound\ambient') $dest /E /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw "Copying the music failed (robocopy exit code $LASTEXITCODE)." }
Copy-Item -LiteralPath (Join-Path $src 'prototypes\ambient-sounds.lua') -Destination (Join-Path $mod 'ambient-sounds.lua') -Force

# Factorio refuses to start when the same mod is installed twice (this folder and the downloaded .zip).
$modsDir = Split-Path $mod -Parent
foreach ($zip in Get-ChildItem -LiteralPath $modsDir -Filter "${name}_*.zip" -ErrorAction SilentlyContinue) {
  Rename-Item -LiteralPath $zip.FullName -NewName ($zip.Name + '.old')
  Write-Host "Renamed $($zip.Name) to $($zip.Name).old so Factorio uses this folder instead."
}

$oggs = Get-ChildItem -LiteralPath $dest -Recurse -Filter *.ogg
Write-Host ('Done: {0} music files ({1:N0} MB). Start Factorio and enable "Space Age Music on Nauvis".' -f $oggs.Count, (($oggs | Measure-Object Length -Sum).Sum / 1MB)) -ForegroundColor Green
