# Space Age Music on Nauvis

Factorio 2.1 mod (`sa-music-on-nauvis`) that plays the Space Age soundtrack in games where the Space Age mod is
disabled, for example IR3 or Space Exploration playthroughs. Requires the Space Age DLC to be installed: the game
cannot read files of a disabled mod, so the music (about 1.1 GB) is copied from your own installation. The mod
does not include it.

## Install

1. Close Factorio.
2. Unzip `sa-music-on-nauvis_<version>.zip` into your Factorio mods folder, so you get a folder
   `mods\sa-music-on-nauvis_<version>` (Windows: `%APPDATA%\Factorio\mods`, Linux: `~/.factorio/mods`), and delete
   the zip so the game doesn't see the mod twice.
3. Copy two things from your Factorio folder (Steam: right-click Factorio, Manage, Browse local files) into the mod:
   - the folder `data/space-age/sound/ambient` into the mod's `sound` folder (create it), giving `sound/ambient`;
   - the file `data/space-age/prototypes/ambient-sounds.lua` into the mod's folder, next to `info.json`.
4. Start Factorio and enable the mod. Repeat step 3 after a game update that changes the soundtrack.

Until the music is copied, the mod still loads (only the music player works) and tells you in chat what to copy.

**Setup scripts** (optional): the mod portal doesn't allow scripts in mods, so they are only in the
[GitHub repo](https://github.com/QuellX/space-age-music-mod). Put them into the mod's folder and run them: on Windows
download `install-music.cmd` and `install-music.ps1` and double-click `install-music.cmd`; on Linux download
`install-music.sh` and run `sh install-music.sh`. They find Factorio (Steam, GOG or standalone) or ask for its folder,
copy the two items above, and rename a leftover `sa-music-on-nauvis_*.zip` to `.zip.old`.

**Do not share the mod folder after step 3**: it then contains Wube's DLC music.

## Settings (startup)

- Where to play: Nauvis only (default) or all surfaces (for mods with their own surfaces).
- Vulcanus / Fulgora / Gleba / Aquilo / space platform music: include or leave out each set.

Per player (can be changed in game):

- Shuffle music: on = the game picks tracks at random (vanilla behaviour); off = tracks play in album order.
- Show music controls: Previous / Next / Shuffle / Stop / Mute music buttons in the top-left corner.
- Show track name: the playing track's title next to the buttons.

The ♫ button in the top-left mod button bar (next to Factory Planner's and others) shows or hides the player; it is
highlighted while the player is open.

Previous / Next walk a per-player history of the last 50 tracks; Next on a fresh track picks a random one (shuffle) or
the next by title (album order). The playlist is every track allowed on the player's current surface.

Stop silences the music and keeps the current track; the button turns into Play, which starts that track again from
the beginning (the API cannot resume mid-track). Mute music keeps all music off
(also across save and load) until it is clicked again or Previous / Next is pressed. Both work by playing a silent
track, since the mod API can start music but not stop it or change the volume. Game sounds can't be muted by a mod;
use the game's own mute button or sound settings for that.

Space Age hero tracks become regular tracks (only one hero track per planet is allowed). With Space Age enabled the
mod does nothing, so it can stay installed.

## Development

```powershell
.\package.ps1           # mod portal zip (no music, no scripts): dist\sa-music-on-nauvis_<version>.zip
.\build.ps1             # copy music + track list from E:\games\steam\steamapps\common\Factorio into this folder
.\build.ps1 -Install    # ... and create E:\games\mods\Factorio\sa-music-on-nauvis_<version>.zip with the music
```

Copied from the game (not hand-edited, git-ignored): `ambient-sounds.lua`, `sound/`.
