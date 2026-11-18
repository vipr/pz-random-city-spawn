-- Every language file must define exactly the keys of the English file.
local BASE = "Contents/mods/RandomCitySpawn/42/media/lua/shared/Translate/"
local LANGS = { "FR", "ES", "DE", "IT", "UA" }

local function keys(lang)
  local f = io.open(BASE .. lang .. "/UI.json", "r")
  if not f then return nil end
  local text = f:read("*a"); f:close()
  local set, n = {}, 0
  for k, v in text:gmatch('"(UI_[%w_]+)"%s*:%s*"([^"]*)"') do
    assert(v ~= "", lang .. " " .. k .. " is empty")
    set[k] = true; n = n + 1
  end
  return set, n
end

function test_translations_match_english()
  local en, enCount = keys("EN")
  assert(en and enCount == 7, "EN keys: " .. tostring(enCount))
  for _, lang in ipairs(LANGS) do
    local set, n = keys(lang)
    assert(set, lang .. "/UI.json missing")
    assert(n == enCount, lang .. " has " .. n .. " keys, EN has " .. enCount)
    for k in pairs(en) do assert(set[k], lang .. " missing " .. k) end
  end
end
