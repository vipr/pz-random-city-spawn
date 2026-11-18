local P = require "RandomCitySpawn/RandomCityPicker"

local function row(name, region, extra)
  local it = { name = name, region = region }
  for k, v in pairs(extra or {}) do it[k] = v end
  return { text = name, item = it }
end

local cities = {
  row("Muldraugh, KY", { name = "Muldraugh, KY" }),
  row("Riverside, KY", { name = "Riverside, KY" }),
  row("Rosewood, KY", { name = "Rosewood, KY" }),
}

function test_realIndices_skips_random_entries()
  local items = { row("Random city", nil, { isRandomCity = true }), cities[1], cities[2], row("Random", nil) }
  local idx = P.realIndices(items)
  assert(#idx == 2 and idx[1] == 2 and idx[2] == 3)
end

function test_pickIndex_maps_rand_to_real_rows()
  local items = { row("Random city", nil, { isRandomCity = true }), cities[1], cities[2], cities[3] }
  assert(P.pickIndex(items, function(n) assert(n == 3); return 0 end) == 2)
  assert(P.pickIndex(items, function(n) return 2 end) == 4)
end

function test_never_picks_random_entries()
  local items = { row("Random city", nil, { isRandomCity = true }), cities[1], row("Random", nil), cities[2] }
  for r = 0, 1 do
    local i = P.pickIndex(items, function() return r end)
    assert(not P.isRandomItem(items[i].item))
  end
end

function test_pickIndex_nil_when_no_cities()
  assert(P.pickIndex({ row("Random city", nil, { isRandomCity = true }) }, function() return 0 end) == nil)
end

function test_pickIndex_is_uniform()
  local counts = { 0, 0, 0 }
  math.randomseed(1)
  for _ = 1, 30000 do
    local i = P.pickIndex(cities, function(n) return math.random(0, n - 1) end)
    counts[i] = counts[i] + 1
  end
  for _, c in ipairs(counts) do assert(c > 9000 and c < 11000, "skewed: " .. c) end
end

function test_shouldShowEntry_rules()
  assert(P.shouldShowEntry(cities) == true)
  assert(P.shouldShowEntry({ cities[1] }) == false)
  assert(P.shouldShowEntry({ cities[1], cities[2], row("Random", nil) }) == false)
end

function test_coverRect_wide_box()
  local x, y, w, h = P.coverRect(1024, 768, 800, 400)
  assert(x == 0 and y == -100 and w == 800 and h == 600, x .. "," .. y .. "," .. w .. "," .. h)
end

function test_coverRect_tall_box()
  local x, y, w, h = P.coverRect(1000, 500, 300, 300)
  assert(x == -150 and y == 0 and w == 600 and h == 300, x .. "," .. y .. "," .. w .. "," .. h)
end
