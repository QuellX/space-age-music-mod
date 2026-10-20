-- Track list for the music controls (control.lua): every ambient sound with the fields needed to build a playlist
-- for the player's surface. Runtime has no ambient-sound prototypes, so they are passed as mod-data.

-- "my-song-name" -> "My Song Name", for tracks without a title
local function titleize(name)
  return (name:gsub("-", " "):gsub("(%a)([%w_']*)", function(first, rest) return first:upper() .. rest end))
end

local tracks = {}
for name, sound in pairs(data.raw["ambient-sound"] or {}) do
  tracks[name] = {
    title = sound.title or titleize(name),
    type = sound.track_type,
    all = sound.play_on_all_surfaces or nil,
    planets = sound.planets,
    surfaces = sound.surface_names,
    exclude_planets = sound.exclude_planets,
    exclude_surfaces = sound.exclude_surface_names,
    variable = sound.sound == nil or nil,
  }
end

data:extend{{type = "mod-data", name = "sa-music-tracks", data = tracks}}
