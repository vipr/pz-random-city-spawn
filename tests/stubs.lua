-- Fakes for the Project Zomboid globals RandomCitySpawn.lua touches.

local texts = {
  UI_RandomCitySpawn_Name = "Random city",
  UI_RandomCitySpawn_Desc = "Spawn in a random city.",
  UI_mapspawn_random = "Random",
  UI_RandomCitySpawn_Position_Last = "Last",
  UI_RandomCitySpawn_Position_First = "First",
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
  self:recalculateMapSize() -- vanilla sizes the list box at the end of fillList
end
function MapSpawnSelect:recalculateMapSize()
  self.layoutRowCount = #self.listbox.items
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
  if PZAPI.ModOptions.Dict["RandomCitySpawn"] then setPositionOption(1) end
  STUB_GAME_MODE = GameMode.SURVIVAL
  MainScreen.instance.inGame = false
  ZombRand = function(n) return 0 end
end

-- Fake PZAPI.ModOptions (B42 client/PZAPI/ModOptions.lua): combobox stores
-- getText(name) values and a 1-based `selected`.
PZAPI = { ModOptions = { Dict = {} } }
function PZAPI.ModOptions:create(id, name)
  local opts = { id = id, name = name, dict = {} }
  function opts:addComboBox(optId, optName, tooltip)
    local o = { type = "combobox", id = optId, name = optName, tooltip = tooltip, values = {}, selected = 1 }
    function o:addItem(text, isSelected)
      table.insert(self.values, getText(text))
      if isSelected then self.selected = #self.values end
    end
    function o:getValue() return self.selected end
    self.dict[optId] = o
    return o
  end
  function opts:getOption(optId) return self.dict[optId] end
  PZAPI.ModOptions.Dict[id] = opts
  return opts
end

-- Selects the "position" combobox entry: 1 = Last, 2 = First.
function setPositionOption(n)
  PZAPI.ModOptions.Dict["RandomCitySpawn"]:getOption("position").selected = n
end

-- Fake texture + map panel drawing.
STUB_TEXTURES = { ["media/ui/RandomCitySpawn/random_city.png"] = { w = 1024, h = 768 } }
function getTexture(path)
  local t = STUB_TEXTURES[path]
  if not t then return nil end
  return { getWidth = function() return t.w end, getHeight = function() return t.h end, path = path }
end

MapSpawnSelectImage = {}
MapSpawnSelectImage.__index = MapSpawnSelectImage
function MapSpawnSelectImage:render() table.insert(self.calls, "original") end
function MapSpawnSelectImage:getWidth() return self.width end
function MapSpawnSelectImage:getHeight() return self.height end
function MapSpawnSelectImage:setStencilRect(x, y, w, h) table.insert(self.calls, "stencil") end
function MapSpawnSelectImage:clearStencilRect() table.insert(self.calls, "clearStencil") end
function MapSpawnSelectImage:drawTextureScaled(tex, x, y, w, h, a, r, g, b)
  table.insert(self.calls, "draw")
  self.drawn = { tex = tex, x = x, y = y, w = w, h = h }
end
function newMapPanel(parent, w, h)
  return setmetatable({ parent = parent, width = w, height = h, calls = {} }, MapSpawnSelectImage)
end
