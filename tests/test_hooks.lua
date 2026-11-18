require "RandomCitySpawn/RandomCitySpawn"

local CITIES = { "Muldraugh, KY", "Riverside, KY", "Rosewood, KY" }

local function randomRows(screen)
  local n = 0
  for _, row in ipairs(screen.listbox.items) do
    if row.item.isRandomCity then n = n + 1 end
  end
  return n
end

local function filled(names, extra, position)
  resetStubs()
  if position then setPositionOption(position) end
  local s = newScreen(names or CITIES, extra)
  s:fillList()
  return s
end

local function randomRowIndex(screen)
  for i, row in ipairs(screen.listbox.items) do
    if row.item.isRandomCity then return i end
  end
end

function test_entry_first_when_option_first()
  local s = filled(nil, nil, 2)
  assert(s.listbox.items[1].text == "Random city", s.listbox.items[1].text)
  assert(#s.listbox.items == 4)
  assert(s.listbox.selected == 2, "selected " .. s.listbox.selected)
  for i, row in ipairs(s.listbox.items) do assert(row.itemindex == i, "itemindex " .. i) end
end

function test_entry_description()
  local s = filled()
  assert(s.listbox.items[randomRowIndex(s)].item.desc == "Spawn in a random city.")
end

function test_next_spawns_in_rolled_city()
  local s = filled()
  s.listbox.selected = randomRowIndex(s)
  ZombRand = function(n) assert(n == 3, "n=" .. n); return 2 end
  s:clickNext()
  assert(s.spawnedIn == CITIES[3], tostring(s.spawnedIn))
end

function test_next_on_real_city_unchanged()
  local s = filled()
  s.listbox.selected = 2
  ZombRand = function() error("ZombRand should not be called") end
  s:clickNext()
  assert(s.spawnedIn == CITIES[2], tostring(s.spawnedIn))
end

function test_selection_restored_after_next()
  local s = filled()
  local r = randomRowIndex(s)
  s.listbox.selected = r
  ZombRand = function() return 1 end
  s:clickNext()
  assert(s.listbox.selected == r, "selected " .. s.listbox.selected)
end

function test_fillList_twice_no_duplicates()
  local s = filled()
  s:fillList()
  assert(randomRows(s) == 1)
  assert(#s.listbox.items == 4)
end

function test_no_entry_with_single_city()
  local s = filled({ "Muldraugh, KY" })
  assert(#s.listbox.items == 1)
end

function test_no_entry_in_multiplayer()
  resetStubs()
  STUB_GAME_MODE = GameMode.MULTIPLAYER
  local s = newScreen(CITIES)
  s:fillList()
  assert(randomRows(s) == 0)
end

function test_no_entry_on_coop_screen()
  local s = filled(CITIES, { Type = "CoopMapSpawnSelect" })
  assert(randomRows(s) == 0)
  resetStubs()
  MainScreen.instance.inGame = true
  local s2 = newScreen(CITIES)
  s2:fillList()
  assert(randomRows(s2) == 0)
  resetStubs()
end

function test_no_entry_when_vanilla_random_present()
  local s = filled(CITIES, { vanillaRandom = true })
  assert(randomRows(s) == 0)
end

function test_list_layout_counts_random_entry()
  local s = filled()
  assert(s.layoutRowCount == 4, "layout sized for " .. tostring(s.layoutRowCount) .. " rows")
end

function test_entry_has_zero_zoom_fields()
  local s = filled()
  local item = s.listbox.items[randomRowIndex(s)].item
  assert(item.zoomX == 0 and item.zoomY == 0 and item.zoomS == 0)
end

-- Position option (Options > Mods)

function test_option_registered_with_last_default()
  local opt = PZAPI.ModOptions.Dict["RandomCitySpawn"]:getOption("position")
  assert(opt.values[1] == "Last" and opt.values[2] == "First", table.concat(opt.values, ","))
  assert(opt.selected == 1)
end

function test_entry_last_by_default()
  local s = filled()
  assert(#s.listbox.items == 4)
  assert(s.listbox.items[4].item.isRandomCity, "random not last")
  assert(s.listbox.selected == 1, "selected " .. s.listbox.selected)
  for i, row in ipairs(s.listbox.items) do assert(row.itemindex == i, "itemindex " .. i) end
end

function test_next_from_last_entry_spawns_in_rolled_city()
  local s = filled()
  s.listbox.selected = 4
  ZombRand = function(n) assert(n == 3); return 0 end
  s:clickNext()
  assert(s.spawnedIn == CITIES[1], tostring(s.spawnedIn))
end

-- Picture over the map panel

local function panelFor(screen) return newMapPanel(screen, 800, 400) end

function test_picture_drawn_when_random_selected()
  local s = filled()
  s.listbox.selected = randomRowIndex(s)
  local p = panelFor(s)
  p:render()
  assert(p.drawn and p.drawn.tex.path == "media/ui/RandomCitySpawn/random_city.png")
  assert(p.calls[1] == "stencil" and p.calls[2] == "draw" and p.calls[3] == "clearStencil" and p.calls[4] == "original",
    table.concat(p.calls, ","))
end

function test_picture_covers_panel()
  local s = filled()
  s.listbox.selected = randomRowIndex(s)
  local p = panelFor(s)
  p:render()
  -- 1024x768 into 800x400: scale = max(800/1024, 400/768) = 0.78125 -> 800x600, centered vertically
  local d = p.drawn
  assert(d.x == 0 and d.w == 800 and d.h == 600 and d.y == -100, d.x .. "," .. d.y .. "," .. d.w .. "," .. d.h)
end

function test_no_picture_for_real_city()
  local s = filled()
  s.listbox.selected = 1
  local p = panelFor(s)
  p:render()
  assert(p.drawn == nil)
  assert(#p.calls == 1 and p.calls[1] == "original")
end

function test_no_picture_when_texture_missing()
  local s = filled()
  s.listbox.selected = randomRowIndex(s)
  local saved = STUB_TEXTURES["media/ui/RandomCitySpawn/random_city.png"]
  STUB_TEXTURES["media/ui/RandomCitySpawn/random_city.png"] = nil
  local p = panelFor(s)
  local ok, err = pcall(function() p:render() end)
  STUB_TEXTURES["media/ui/RandomCitySpawn/random_city.png"] = saved
  assert(ok, tostring(err))
  assert(p.drawn == nil and p.calls[#p.calls] == "original")
end
