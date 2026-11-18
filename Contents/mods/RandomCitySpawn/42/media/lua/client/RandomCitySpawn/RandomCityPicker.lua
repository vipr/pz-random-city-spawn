-- Pure logic for the Random City Spawn mod. No game globals are used here,
-- so this file can be tested outside the game.

RandomCityPicker = {}

-- A list entry is "random" (not a real city) if it is our entry, or has no
-- spawn region (vanilla's own unfinished "Random" entry has region = nil).
function RandomCityPicker.isRandomItem(item)
  return item == nil or item.isRandomCity == true or item.region == nil
end

-- Indices of listbox rows that are real cities, in list order.
function RandomCityPicker.realIndices(listItems)
  local result = {}
  for i, row in ipairs(listItems) do
    if not RandomCityPicker.isRandomItem(row.item) then
      table.insert(result, i)
    end
  end
  return result
end

-- Uniformly pick one real city row. randInt(n) must return 0..n-1 (ZombRand in-game).
function RandomCityPicker.pickIndex(listItems, randInt)
  local real = RandomCityPicker.realIndices(listItems)
  if #real == 0 then return nil end
  return real[randInt(#real) + 1]
end

-- Show our entry only when there are at least two cities to choose from and
-- no random entry (ours or vanilla's) is already in the list.
function RandomCityPicker.shouldShowEntry(listItems)
  for _, row in ipairs(listItems) do
    if RandomCityPicker.isRandomItem(row.item) then return false end
  end
  return #RandomCityPicker.realIndices(listItems) >= 2
end

-- Scale a texW x texH image so it fully covers a boxW x boxH area (cropping
-- the overflow), centered. Returns x, y, w, h relative to the box.
function RandomCityPicker.coverRect(texW, texH, boxW, boxH)
  local scale = math.max(boxW / texW, boxH / texH)
  local w, h = texW * scale, texH * scale
  return (boxW - w) / 2, (boxH - h) / 2, w, h
end

return RandomCityPicker
