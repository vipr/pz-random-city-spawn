require "RandomCitySpawn/RandomCitySpawn"

local CITIES = { "Muldraugh, KY", "Riverside, KY", "Rosewood, KY" }

local function randomRows(screen)
  local n = 0
  for _, row in ipairs(screen.listbox.items) do
    if row.item.isRandomCity then n = n + 1 end
  end
  return n
end

local function filled(names, extra)
  resetStubs()
  local s = newScreen(names or CITIES, extra)
  s:fillList()
  return s
end

function test_entry_added_first_and_city_still_default()
  local s = filled()
  assert(s.listbox.items[1].text == "Random city", s.listbox.items[1].text)
  assert(#s.listbox.items == 4)
  assert(s.listbox.selected == 2, "selected " .. s.listbox.selected)
  for i, row in ipairs(s.listbox.items) do assert(row.itemindex == i, "itemindex " .. i) end
end

function test_entry_description()
  local s = filled()
  assert(s.listbox.items[1].item.desc == "Spawn in a random city.")
end

function test_next_spawns_in_rolled_city()
  local s = filled()
  s.listbox.selected = 1
  ZombRand = function(n) assert(n == 3, "n=" .. n); return 2 end
  s:clickNext()
  assert(s.spawnedIn == CITIES[3], tostring(s.spawnedIn))
end

function test_next_on_real_city_unchanged()
  local s = filled()
  s.listbox.selected = 3
  ZombRand = function() error("ZombRand should not be called") end
  s:clickNext()
  assert(s.spawnedIn == CITIES[2], tostring(s.spawnedIn))
end

function test_selection_restored_after_next()
  local s = filled()
  s.listbox.selected = 1
  ZombRand = function() return 1 end
  s:clickNext()
  assert(s.listbox.selected == 1, "selected " .. s.listbox.selected)
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
  local item = filled().listbox.items[1].item
  assert(item.zoomX == 0 and item.zoomY == 0 and item.zoomS == 0)
end
