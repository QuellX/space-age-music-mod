-- Silent track for the Stop and Mute music buttons: the API can start music but not stop it.
-- A script track only plays when a script asks for it.
data:extend{{
  type = "ambient-sound",
  name = "sa-music-silence",
  track_type = "script-track",
  sound = {filename = "__core__/sound/silence-1sec.ogg"},
}}

-- Whether the copied Space Age music was found; control.lua tells players how to add it when it is missing.
data:extend{{type = "mod-data", name = "sa-music-status", data = {missing = false}}}

-- With Space Age enabled the game already plays these tracks on their own planets.
if mods["space-age"] then return end

require("__core__/lualib/sound-util") -- defines sound_variations(), used by the layered tracks

local before = {}
for name in pairs(data.raw["ambient-sound"] or {}) do before[name] = true end

-- The player's own copy of the Space Age music (copied by hand, or by the setup scripts from the GitHub repo):
-- sound/ambient/** and ambient-sounds.lua, unchanged. Their paths point to __space-age__, which can't be read
-- while that mod is disabled, so requires and file names are redirected to this mod.
local MOD = "__sa-music-on-nauvis__/"
local function redirect(path) return (path:gsub("^__space%-age__/", MOD)) end

local game_require = require
require = function(name) return game_require(redirect(name)) end
local ok, err = pcall(game_require, MOD .. "ambient-sounds")
require = game_require
if not ok then
  -- Not copied yet: load without it (the music player still works) and tell players in game. Other errors stop.
  if not tostring(err):find("not found", 1, true) then error(err) end
  log("Space Age Music on Nauvis: the Space Age music is missing (" .. tostring(err) .. ")")
  data.raw["mod-data"]["sa-music-status"].data.missing = true
  return
end

-- Every string, not only `filename` fields: some layers list their files as plain strings (e.g. space-3 layer G).
local missed = 0
local function redirect_files(t)
  for k, v in pairs(t) do
    if type(v) == "table" then redirect_files(v)
    elseif type(v) == "string" then
      t[k] = redirect(v)
      if t[k]:find("__space-age__", 1, true) then missed = missed + 1 end
    end
  end
end

local placement = settings.startup["sa-music-placement"].value
local added = 0

for name, track in pairs(data.raw["ambient-sound"]) do
  if not before[name] then
    redirect_files(track)
    local planet = track.planets and track.planets[1]
    local group = planet or "space" -- space platform tracks have no planet
    if track.track_type == "hero-track" then group = "hero" end -- own category, independent of the planet switches
    local setting = settings.startup["sa-music-" .. group]
    if setting and not setting.value then
      data.raw["ambient-sound"][name] = nil
    else
      -- Only one hero track is allowed per planet, and these planets don't exist without Space Age.
      if track.track_type == "hero-track" then track.track_type = "main-track" end
      track.planets = nil
      track.surface_names = nil
      if placement == "all-surfaces" then
        track.play_on_all_surfaces = true
      else
        track.planets = {"nauvis"}
      end
      added = added + 1
    end
  end
end
log("Space Age Music on Nauvis: " .. added .. " tracks added (" .. placement .. ")")
if missed > 0 then error("Space Age Music on Nauvis: " .. missed .. " Space Age paths could not be redirected") end
