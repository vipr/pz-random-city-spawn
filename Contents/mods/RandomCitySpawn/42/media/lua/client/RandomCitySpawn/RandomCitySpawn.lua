-- Random City Spawn: adds a "Random city" entry to the new-game spawn
-- location list. Wraps vanilla MapSpawnSelect functions; spawning itself
-- stays vanilla.

require "OptionScreens/MapSpawnSelect"
require "RandomCitySpawn/RandomCityPicker"

RandomCitySpawn = {}

RandomCitySpawn.PICTURE = "media/ui/RandomCitySpawn/random_city.png"

-- Options > Mods > Random City Spawn: where the entry goes in the list.
-- Combobox values: 1 = Last (default), 2 = First.
if PZAPI and PZAPI.ModOptions then
  local options = PZAPI.ModOptions:create("RandomCitySpawn", getText("UI_RandomCitySpawn_OptionsTitle"))
  local position = options:addComboBox("position", getText("UI_RandomCitySpawn_Position"), getText("UI_RandomCitySpawn_Position_Tooltip"))
  position:addItem("UI_RandomCitySpawn_Position_Last", true)
  position:addItem("UI_RandomCitySpawn_Position_First", false)
  RandomCitySpawn.options = options
end

-- "first" or "last"
function RandomCitySpawn.getPosition()
  local opt = RandomCitySpawn.options and RandomCitySpawn.options:getOption("position")
  if opt and opt:getValue() == 2 then return "first" end
  return "last"
end

-- Single-player new-game screen only: not the split-screen co-op join screen,
-- not while in game, not multiplayer.
function RandomCitySpawn.isEligibleScreen(screen)
  if screen.Type == "CoopMapSpawnSelect" then return false end
  if MainScreen and MainScreen.instance and MainScreen.instance.inGame then return false end
  if getWorld():getGameMode() == GameMode.MULTIPLAYER then return false end
  return true
end

local original_fillList = MapSpawnSelect.fillList
local original_clickNext = MapSpawnSelect.clickNext

MapSpawnSelect.fillList = function(self, ...)
  original_fillList(self, ...)
  local listbox = self.listbox
  if not RandomCitySpawn.isEligibleScreen(self) then return end
  if not RandomCityPicker.shouldShowEntry(listbox.items) then return end

  local item = {
    name = getText("UI_RandomCitySpawn_Name"),
    desc = getText("UI_RandomCitySpawn_Desc"),
    region = nil,
    dir = "",
    -- All-zero zoom makes the map panel leave the map where it is.
    zoomX = 0,
    zoomY = 0,
    zoomS = 0,
    isRandomCity = true,
  }
  if RandomCitySpawn.getPosition() == "first" then
    listbox:insertItem(1, item.name, item)
  else
    listbox:insertItem(#listbox.items + 1, item.name, item)
  end
  for i, row in ipairs(listbox.items) do row.itemindex = i end
  -- Keep the first real city as the default selection.
  listbox.selected = RandomCityPicker.realIndices(listbox.items)[1]
  -- Vanilla sized the list box before our row existed; size it again.
  if self.recalculateMapSize then self:recalculateMapSize() end
end

MapSpawnSelect.clickNext = function(self, ...)
  local listbox = self.listbox
  local selectedRow = listbox.items[listbox.selected]
  local randomRow = nil
  if selectedRow and selectedRow.item and selectedRow.item.isRandomCity then
    local picked = RandomCityPicker.pickIndex(listbox.items, ZombRand)
    if picked then
      randomRow = listbox.selected
      listbox.selected = picked
    end
  end

  original_clickNext(self, ...)

  -- The region is already applied; put the highlight back on "Random city"
  -- so the city stays hidden if the player comes back with Back.
  if randomRow then listbox.selected = randomRow end
end

-- Draw the Random city picture over the map panel while that entry is
-- selected, so the map of the previously viewed city isn't shown.
if MapSpawnSelectImage then
  local original_imageRender = MapSpawnSelectImage.render

  MapSpawnSelectImage.render = function(self, ...)
    local parent = self.parent
    local listbox = parent and parent.listbox
    local row = listbox and listbox.items and listbox.items[listbox.selected]
    if row and row.item and row.item.isRandomCity then
      local tex = getTexture(RandomCitySpawn.PICTURE)
      local w, h = self:getWidth(), self:getHeight()
      if tex and w > 0 and h > 0 then
        local x, y, dw, dh = RandomCityPicker.coverRect(tex:getWidth(), tex:getHeight(), w, h)
        self:setStencilRect(0, 0, w, h)
        self:drawTextureScaled(tex, x, y, dw, dh, 1, 1, 1, 1)
        self:clearStencilRect()
      end
    end
    original_imageRender(self, ...)
  end
end

return RandomCitySpawn
