data:extend{
  {
    type = "string-setting",
    name = "sa-music-placement",
    setting_type = "startup",
    default_value = "nauvis",
    allowed_values = {"nauvis", "all-surfaces"},
    order = "a",
  },
  {type = "bool-setting", name = "sa-music-vulcanus", setting_type = "startup", default_value = true, order = "b-a"},
  {type = "bool-setting", name = "sa-music-fulgora", setting_type = "startup", default_value = true, order = "b-b"},
  {type = "bool-setting", name = "sa-music-gleba", setting_type = "startup", default_value = true, order = "b-c"},
  {type = "bool-setting", name = "sa-music-aquilo", setting_type = "startup", default_value = true, order = "b-d"},
  {type = "bool-setting", name = "sa-music-space", setting_type = "startup", default_value = true, order = "b-e"},
  {type = "bool-setting", name = "sa-music-hero", setting_type = "startup", default_value = true, order = "b-f"},

  -- Per player: music controls
  {type = "bool-setting", name = "sa-music-shuffle", setting_type = "runtime-per-user", default_value = true, order = "c-a"},
  {type = "bool-setting", name = "sa-music-show-controls", setting_type = "runtime-per-user", default_value = true, order = "c-b"},
  {type = "bool-setting", name = "sa-music-show-title", setting_type = "runtime-per-user", default_value = true, order = "c-c"},
}
