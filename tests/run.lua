-- Minimal test runner: lua5.1 tests/run.lua (from repo root)
package.path = "Contents/mods/RandomCitySpawn/42/media/lua/client/?.lua;tests/?.lua;" .. package.path

local files = { "tests/test_picker.lua", "tests/stubs.lua", "tests/test_hooks.lua", "tests/test_translations.lua" }
local failed, passed = 0, 0

for _, file in ipairs(files) do
  local f = io.open(file, "r")
  if f then
    f:close()
    local before = {}
    for k in pairs(_G) do before[k] = true end
    dofile(file)
    local names = {}
    for k, v in pairs(_G) do
      if not before[k] and type(v) == "function" and k:sub(1, 5) == "test_" then table.insert(names, k) end
    end
    table.sort(names)
    for _, name in ipairs(names) do
      local ok, err = pcall(_G[name])
      if ok then passed = passed + 1; print("PASS " .. name)
      else failed = failed + 1; print("FAIL " .. name .. ": " .. tostring(err)) end
    end
  end
end

print(string.format("%d passed, %d failed", passed, failed))
if failed > 0 then os.exit(1) end
