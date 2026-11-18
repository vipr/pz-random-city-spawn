-- Random City Spawn: adds a "Random city" entry to the new-game spawn
-- location list. Wraps vanilla MapSpawnSelect functions; spawning itself
-- stays vanilla.

require "OptionScreens/MapSpawnSelect"
require "RandomCitySpawn/RandomCityPicker"

RandomCitySpawn = {}

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
    isRandomCity = true,
  }
  listbox:insertItem(1, item.name, item)
  for i, row in ipairs(listbox.items) do row.itemindex = i end
  -- Keep the first real city as the default selection.
  listbox.selected = 2
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

return RandomCitySpawn
