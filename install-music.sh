#!/bin/sh
# Copies the Space Age music from your own Factorio installation into this mod (Linux).
# The music is Wube's: it stays on your PC.
#
#   sh install-music.sh                      # find Factorio automatically (Steam, Flatpak Steam, standalone)
#   sh install-music.sh /path/to/factorio    # or name the Factorio folder
set -e
mod=$(cd "$(dirname "$0")" && pwd)
name=sa-music-on-nauvis

is_game() { [ -n "$1" ] && [ -d "$1/data/space-age/sound/ambient" ]; }

find_game() {
  for root in "$HOME/.steam/steam" "$HOME/.steam/root" "$HOME/.local/share/Steam" \
              "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam" "$HOME/snap/steam/common/.local/share/Steam"; do
    is_game "$root/steamapps/common/Factorio" && { echo "$root/steamapps/common/Factorio"; return; }
    vdf="$root/steamapps/libraryfolders.vdf"
    if [ -f "$vdf" ]; then
      for lib in $(sed -n 's/.*"path"[[:space:]]*"\([^"]*\)".*/\1/p' "$vdf" | tr ' ' '\001'); do
        lib=$(printf '%s' "$lib" | tr '\001' ' ')
        is_game "$lib/steamapps/common/Factorio" && { echo "$lib/steamapps/common/Factorio"; return; }
      done
    fi
  done
  for dir in "$HOME/factorio" "$HOME/Games/factorio" "$HOME/Games/Factorio" /opt/factorio /usr/share/factorio; do
    is_game "$dir" && { echo "$dir"; return; }
  done
}

echo "Space Age Music on Nauvis: copying the Space Age music from your game."
[ -f "$mod/info.json" ] || { echo "This script must stay in the mod's folder (next to info.json). If the mod is still a .zip, unzip it into your mods folder first."; exit 1; }
if pgrep -x factorio >/dev/null 2>&1; then echo "Factorio is running. Close it first, then run this again."; exit 1; fi

game=$1
is_game "$game" || game=$(find_game)
while ! is_game "$game"; do
  echo "Could not find a Factorio installation with the Space Age expansion."
  printf 'Type the Factorio folder (the one that contains "bin" and "data"), or press Enter to cancel: '
  read -r game || exit 1
  [ -n "$game" ] || exit 1
done
echo "Factorio found: $game"

# The music and its track scripts, plus the track list, copied unchanged (the mod redirects their paths).
rm -rf "$mod/sound/ambient"
mkdir -p "$mod/sound"
echo "Copying about 1.1 GB of music, this can take a minute..."
cp -R "$game/data/space-age/sound/ambient" "$mod/sound/ambient"
cp "$game/data/space-age/prototypes/ambient-sounds.lua" "$mod/ambient-sounds.lua"

# Factorio refuses to start when the same mod is installed twice (this folder and the downloaded .zip).
for zip in "$(dirname "$mod")/${name}_"*.zip; do
  [ -f "$zip" ] || continue
  mv "$zip" "$zip.old"
  echo "Renamed $(basename "$zip") to $(basename "$zip").old so Factorio uses this folder instead."
done

count=$(find "$mod/sound/ambient" -name '*.ogg' | wc -l)
echo "Done: $count music files. Start Factorio and enable \"Space Age Music on Nauvis\"."
