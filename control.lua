-- Music controls: Previous / Next / Shuffle / Stop / Mute music buttons and the current track name, per player.
--
-- Shuffle on: the game picks tracks itself (weighted random, with interludes in between); Next picks a random track.
-- Shuffle off: when a track ends, the next one in album order (by title) is played instead.
-- The playlist is every main and hero track allowed on the player's current surface.
-- The API cannot stop music, so Stop and Mute play a silent script track (data.lua), replay it when it ends and
-- replace any track the game starts. Stop remembers the track; Play starts it again (there is no seek).

local mod_gui = require("mod-gui")

local TRACKS = prototypes.mod_data["sa-music-tracks"].data
local HISTORY_SIZE = 50
-- Button switches: every transition phase set explicitly (in ticks). Left out, the engine's defaults apply,
-- which made a switch take about 10 seconds.
local FADE = {skip_natural_pause = true, delay_duration = 0, fade_out_duration = 30, pause_duration = 0, fade_in_duration = 15}
-- While muted: cut a track the game starts at once, and chain the silence without the pause between tracks.
local SNAP = {skip_natural_pause = true, delay_duration = 0, fade_out_duration = 0, pause_duration = 0, fade_in_duration = 0}
local SILENCE = "sa-music-silence"

-- Album order: by title, so "Vulcanus 2" comes after "Vulcanus 1".
local ORDER = {}
for name, info in pairs(TRACKS) do
  if info.type == "main-track" or info.type == "hero-track" then ORDER[#ORDER + 1] = name end
end
table.sort(ORDER, function(a, b) return TRACKS[a].title < TRACKS[b].title end)

-- Playlist ------------------------------------------------------------------------------------------------------

local function contains(list, value)
  for _, v in pairs(list or {}) do if v == value then return true end end
  return false
end

local function name_matches(list, surface_name)
  for _, v in pairs(list or {}) do if string.find(surface_name, v, 1, true) then return true end end
  return false
end

-- Same rules the game uses for AmbientSound placement.
local function allowed_on(info, surface)
  local planet = surface.planet and surface.planet.name
  if contains(info.exclude_planets, planet) or name_matches(info.exclude_surfaces, surface.name) then return false end
  if info.all then return true end
  if info.planets then return planet ~= nil and contains(info.planets, planet) end
  if info.surfaces then return name_matches(info.surfaces, surface.name) end
  return surface.platform ~= nil -- no restriction at all = space platform music
end

local function playlist(player)
  local list = {}
  for _, name in ipairs(ORDER) do
    if allowed_on(TRACKS[name], player.surface) then list[#list + 1] = name end
  end
  if #list == 0 then list = ORDER end -- surface without own music: offer everything
  return list
end

-- Player state ----------------------------------------------------------------------------------------------------

local function pdata(player)
  storage.players = storage.players or {}
  local pd = storage.players[player.index]
  if not pd then
    pd = {history = {}, pos = 0}
    storage.players[player.index] = pd
  end
  return pd
end

local function setting(player, name) return player.mod_settings[name].value end

local function track_title(name)
  if not name or name == "" then return {"sa-music.no-music"} end
  local info = TRACKS[name]
  if not info then return name end
  if info.variable then return {"", info.title, " ", {"sa-music.variable"}} end
  return info.title
end

local function remember(pd, name)
  -- Playing something new after stepping back drops the "forward" part of the history, like a browser.
  for i = #pd.history, pd.pos + 1, -1 do table.remove(pd.history, i) end
  if pd.history[#pd.history] ~= name then pd.history[#pd.history + 1] = name end
  while #pd.history > HISTORY_SIZE do table.remove(pd.history, 1) end
  pd.pos = #pd.history
end

local function play(player, pd, name, transition)
  pd.expected = name
  local spec = {name = name}
  for k, v in pairs(transition or FADE) do spec[k] = v end
  player.play_music(spec)
end

local function next_in_order(player, after)
  local list = playlist(player)
  for i, name in ipairs(list) do
    if name == after then return list[i % #list + 1] end
  end
  return list[1]
end

local function random_track(player, pd)
  local list = playlist(player)
  if #list == 1 then return list[1] end
  -- avoid the last few tracks when the playlist is long enough
  local recent = {}
  for i = math.max(1, #pd.history - math.min(5, #list - 2) + 1), #pd.history do recent[pd.history[i]] = true end
  local candidates = {}
  for _, name in ipairs(list) do if not recent[name] then candidates[#candidates + 1] = name end end
  if #candidates == 0 then candidates = list end
  return candidates[math.random(#candidates)]
end

local function play_next(player, pd)
  local name
  if pd.pos < #pd.history then
    pd.pos = pd.pos + 1 -- step forward again after Previous
    name = pd.history[pd.pos]
  else
    local current = player.current_music
    if current == "" or current == SILENCE then current = pd.history[pd.pos] end
    name = setting(player, "sa-music-shuffle") and random_track(player, pd) or next_in_order(player, current)
    remember(pd, name)
  end
  play(player, pd, name)
end

-- GUI -------------------------------------------------------------------------------------------------------------

-- The player sits in player.gui.left (a vertical flow) right below mod-gui's frame flow, so it stacks under other
-- mods' panels; inside the shared mod-gui flow it would be placed beside them.
local function gui_destroy(player)
  local frame = player.gui.left.sa_music_frame
  if frame then frame.destroy() end
  frame = mod_gui.get_frame_flow(player).sa_music_frame -- placed there by older versions
  if frame then frame.destroy() end
end

local function gui_update(player)
  local frame = player.gui.left.sa_music_frame
  local row = frame and frame.sa_music_row
  if not row then return end
  local pd = pdata(player)
  local muted, stopped = pd.muted, pd.stopped
  if row.sa_music_title then
    local current = player.current_music
    local title
    if muted then title = {"sa-music.muted"}
    elseif stopped then title = {"", track_title(stopped), " ", {"sa-music.stopped"}}
    else title = track_title(current ~= SILENCE and current or nil) end
    row.sa_music_title.caption = {"", "♫ ", title}
  end
  local buttons = row.sa_music_buttons
  if not buttons then return end
  local on = setting(player, "sa-music-shuffle")
  buttons.sa_music_shuffle.toggled = on
  buttons.sa_music_shuffle.tooltip = {on and "sa-music.shuffle-on" or "sa-music.shuffle-off"}
  buttons.sa_music_stop.sprite = stopped and "utility/play" or "utility/stop"
  buttons.sa_music_stop.tooltip = {stopped and "sa-music.play" or "sa-music.stop"}
  buttons.sa_music_mute.toggled = muted or false
  buttons.sa_music_mute.sprite = muted and "utility/side_menu_master_mute_muted_icon" or "utility/side_menu_master_mute_unmuted_icon"
  buttons.sa_music_mute.tooltip = {muted and "sa-music.mute-on" or "sa-music.mute-off"}
end

-- Button in the top-left mod button bar (as used by Factory Planner) that opens and closes the player.
-- It is highlighted (toggled) while the player is open.
local function toggle_button(player)
  local flow = mod_gui.get_button_flow(player)
  local button = flow.sa_music_toggle
  if not button then
    button = flow.add{type = "button", name = "sa_music_toggle", style = mod_gui.button_style, caption = "♫", tooltip = {"sa-music.toggle"}, auto_toggle = false, mouse_button_filter = {"left"}}
    button.style.font = "default-large-semibold"
  end
  return button
end

local function gui_build(player)
  gui_destroy(player)
  local open = pdata(player).open ~= false -- open unless closed with the button
  toggle_button(player).toggled = open
  local show_controls = setting(player, "sa-music-show-controls")
  local show_title = setting(player, "sa-music-show-title")
  if not open or not (show_controls or show_title) then return end

  local left = player.gui.left
  local index = mod_gui.get_frame_flow(player).get_index_in_parent() + 1
  local frame = left.add{type = "frame", name = "sa_music_frame", style = mod_gui.frame_style, direction = "horizontal", index = index}
  -- Spacing and alignment are flow style properties; a frame style rejects them.
  local row = frame.add{type = "flow", name = "sa_music_row", direction = "horizontal"}
  row.style.vertical_align = "center"
  row.style.horizontal_spacing = 8
  if show_controls then
    local buttons = row.add{type = "flow", name = "sa_music_buttons", direction = "horizontal"}
    buttons.style.horizontal_spacing = 2
    buttons.add{type = "sprite-button", name = "sa_music_previous", style = "tool_button", sprite = "utility/backward_arrow_black", tooltip = {"sa-music.previous"}}
    buttons.add{type = "sprite-button", name = "sa_music_next", style = "tool_button", sprite = "utility/forward_arrow_black", tooltip = {"sa-music.next"}}
    buttons.add{type = "sprite-button", name = "sa_music_shuffle", style = "tool_button", sprite = "utility/shuffle", auto_toggle = false}
    buttons.add{type = "sprite-button", name = "sa_music_stop", style = "tool_button"}
    buttons.add{type = "sprite-button", name = "sa_music_mute", style = "tool_button", auto_toggle = false}
  end
  if show_title then
    row.add{type = "label", name = "sa_music_title", style = "label"}
  end
  gui_update(player)
end

-- Events ----------------------------------------------------------------------------------------------------------

local function init_player(player)
  pdata(player)
  gui_build(player)
end

script.on_init(function()
  storage.players = {}
  for _, player in pairs(game.players) do init_player(player) end
end)

script.on_configuration_changed(function()
  for _, player in pairs(game.players) do init_player(player) end
end)

script.on_event(defines.events.on_player_created, function(e) init_player(game.get_player(e.player_index)) end)
-- The music isn't shipped with the mod; until the player has copied it from their game, say how.
script.on_event(defines.events.on_player_joined_game, function(e)
  if prototypes.mod_data["sa-music-status"].data.missing then game.get_player(e.player_index).print({"sa-music.music-missing"}) end
end)
script.on_event(defines.events.on_player_removed, function(e) if storage.players then storage.players[e.player_index] = nil end end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(e)
  if not e.player_index or e.setting:sub(1, 9) ~= "sa-music-" then return end
  gui_build(game.get_player(e.player_index))
end)

script.on_event(defines.events.on_player_music_changed, function(e)
  local player = game.get_player(e.player_index)
  if not (player and player.connected) then return end
  local pd = pdata(player)
  local current = player.current_music

  if current ~= "" then
    if current == pd.expected then
      pd.expected = nil -- started by our buttons; history already handled
    elseif pd.muted or pd.stopped then
      play(player, pd, SILENCE, SNAP) -- the game started a track
    else
      remember(pd, current)
    end
  elseif pd.muted or pd.stopped then
    play(player, pd, SILENCE, SNAP) -- the silence ended: keep it going
  elseif not setting(player, "sa-music-shuffle") then
    -- A track just finished: continue in album order instead of the game's random pick.
    local last = pd.history[pd.pos]
    local info = last and TRACKS[last]
    if info and (info.type == "main-track" or info.type == "hero-track") then
      local name = next_in_order(player, last)
      remember(pd, name)
      pd.expected = name
      player.play_music{name = name} -- keeps the natural pause between tracks
    end
  end
  gui_update(player)
end)

script.on_event(defines.events.on_gui_click, function(e)
  local element = e.element
  if not (element and element.valid) or element.name:sub(1, 9) ~= "sa_music_" then return end
  local player = game.get_player(e.player_index)
  local pd = pdata(player)

  if element.name == "sa_music_toggle" then
    pd.open = pd.open == false -- nil (default) counts as open
    gui_build(player)

  elseif element.name == "sa_music_shuffle" then
    player.mod_settings["sa-music-shuffle"] = {value = not setting(player, "sa-music-shuffle")}
    gui_update(player)

  elseif element.name == "sa_music_next" then
    pd.muted, pd.stopped = nil, nil
    play_next(player, pd)
    gui_update(player)

  elseif element.name == "sa_music_previous" then
    pd.muted, pd.stopped = nil, nil
    if pd.pos > 1 then pd.pos = pd.pos - 1 end
    local name = pd.history[pd.pos]
    if name then play(player, pd, name) else play_next(player, pd) end -- at the start of the history: restart the oldest track
    gui_update(player)

  elseif element.name == "sa_music_stop" then
    if pd.stopped then
      -- Play: the API has no seek, so the stopped track starts again from the beginning.
      local name = pd.stopped
      pd.stopped = nil
      if not pd.muted then
        if name ~= "" then play(player, pd, name) else play_next(player, pd) end
      end
    else
      local current = player.current_music
      if current == "" or current == SILENCE then current = pd.history[pd.pos] end
      pd.stopped = current or "" -- "" = nothing had played yet
      if not pd.muted then play(player, pd, SILENCE) end
    end
    gui_update(player)

  elseif element.name == "sa_music_mute" then
    pd.muted = not pd.muted or nil
    if pd.muted then play(player, pd, SILENCE)
    elseif not pd.stopped then play_next(player, pd) end
    gui_update(player)
  end
end)
