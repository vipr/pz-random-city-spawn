-- Fakes for the Project Zomboid globals RandomCitySpawn.lua touches.

local texts = {
  UI_RandomCitySpawn_Name = "Random city",
  UI_RandomCitySpawn_Desc = "Spawn in a random city.",
  UI_mapspawn_random = "Random",
}
function getText(key) return texts[key] or key end

GameMode = { MULTIPLAYER = "MP", SANDBOX = "SB", SURVIVAL = "SV" }
STUB_GAME_MODE = GameMode.SURVIVAL
function getWorld() return { getGameMode = function() return STUB_GAME_MODE end } end

MainScreen = { instance = { inGame = false } }

ZombRand = function(n) return 0 end

-- Minimal ISScrollingListBox with the same addItem/insertItem behaviour as B42.
ISScrollingListBox = {}
ISScrollingListBox.__index = ISScrollingListBox
function newListBox()
  return setmetatable({ items = {}, selected = 1, count = 0 }, ISScrollingListBox)
end
function ISScrollingListBox:clear() self.items = {}; self.selected = 1; self.count = 0 end
function ISScrollingListBox:addItem(name, item)
  local i = { text = name, item = item, itemindex = self.count + 1 }
  table.insert(self.items, i); self.count = self.count + 1
  return i
end
function ISScrollingListBox:insertItem(index, name, item)
  local i = { text = name, item = item }
  if #self.items == 0 or index > #self.items then
    i.itemindex = 1; table.insert(self.items, i)
  elseif index < 1 then
    i.itemindex = 1; table.insert(self.items, 1, i)
  else
    i.itemindex = index; table.insert(self.items, index, i)
  end
  self.count = self.count + 1
  return i
end

-- Fake MapSpawnSelect: fillList adds one row per self.regionNames entry
-- (plus vanilla's "Random" row when self.vanillaRandom is set);
-- clickNext records the region it would spawn in.
MapSpawnSelect = {}
MapSpawnSelect.__index = MapSpawnSelect
function MapSpawnSelect:fillList()
  self.listbox:clear()
  for _, n in ipairs(self.regionNames) do
    self.listbox:addItem(n, { name = n, region = { name = n }, dir = n, desc = n .. " desc" })
  end
  if self.vanillaRandom then
    self.listbox:addItem("Random", { name = "Random", region = nil, dir = "", desc = "" })
  end
end
function MapSpawnSelect:clickNext()
  self.spawnedIn = self.listbox.items[self.listbox.selected].item.region.name
end

package.preload["OptionScreens/MapSpawnSelect"] = function() return MapSpawnSelect end

function newScreen(regionNames, extra)
  local s = setmetatable({ listbox = newListBox(), regionNames = regionNames }, MapSpawnSelect)
  for k, v in pairs(extra or {}) do s[k] = v end
  return s
end

function resetStubs()
  STUB_GAME_MODE = GameMode.SURVIVAL
  MainScreen.instance.inGame = false
  ZombRand = function(n) return 0 end
end
