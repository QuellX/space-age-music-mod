# Space Age Music on Nauvis

Factorio 2.1 mod (`sa-music-on-nauvis`) that plays the Space Age soundtrack in games where the Space Age mod is
disabled, for example IR3 or Space Exploration playthroughs. Requires the Space Age DLC to be installed: the game
cannot read files of a disabled mod, so `build.ps1` copies the music (about 1.1 GB) from your own installation.

**Do not upload or share the built mod or the `sound/` folder** — they contain Wube's DLC music.

## Build and install

```powershell
.\build.ps1             # copy music + track definitions from E:\games\steam\steamapps\common\Factorio
.\build.ps1 -Install    # ... and create E:\games\mods\Factorio\sa-music-on-nauvis_<version>.zip
```

Re-run after a game update that changes the soundtrack.

## Settings (startup)

- Where to play: Nauvis only (default) or all surfaces (for mods with their own surfaces).
- Vulcanus / Fulgora / Gleba / Aquilo / space platform music: include or leave out each set.

Per player (can be changed in game):

- Shuffle music: on = the game picks tracks at random (vanilla behaviour); off = tracks play in album order.
- Show music controls: Previous / Next / Shuffle buttons in the top-left corner.
- Show track name: the playing track's title next to the buttons.

Previous / Next walk a per-player history of the last 50 tracks; Next on a fresh track picks a random one (shuffle) or
the next by title (album order). The playlist is every track allowed on the player's current surface.

Space Age hero tracks become regular tracks (only one hero track per planet is allowed). With Space Age enabled the
mod does nothing, so it can stay installed.

Generated files (not hand-edited): `ambient-sounds.lua`, `sound/`.
