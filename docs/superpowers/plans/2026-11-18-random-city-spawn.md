# Random City Spawn Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Build 42 mod that adds a "Random city" entry at the top of the new-game spawn location list. Clicking Next with it selected spawns the player in a randomly chosen listed city.

**Architecture:** Two Lua files on the client side. `RandomCityPicker.lua` is pure logic with no game globals: it picks an index among the real cities, with equal odds, and decides whether the entry should show. `RandomCitySpawn.lua` wraps the vanilla `MapSpawnSelect:fillList` and `MapSpawnSelect:clickNext`. It doesn't copy or replace them. The wrapper inserts the entry after vanilla fills the list. On Next, it moves the selection to a random real city and then hands off to vanilla's `clickNext`. Spawning itself stays 100% vanilla.

**Tech Stack:** Project Zomboid Build 42 Lua (Kahlua, Lua 5.1 semantics). Tests run in plain Lua 5.1 (`lua5.1`) against stubs, outside the game. A final manual check happens in-game.

**Spec:** `/mnt/project-files/docs/specs/2026-11-18-random-city-spawn-design.md`

## Facts from the game's own code (B42, read 2026-11-18)

These come from `media/lua/client/OptionScreens/MapSpawnSelect.lua` in the person's install:
- `MapSpawnSelect:fillList()` clears `self.listbox`, then adds one item per spawn region. Each item has the shape `{name, region, dir, desc, zoomX, zoomY, zoomS, demoVideo}` and is added via `self.listbox:addItem(item.name, item)`. Listbox entries are `{text, item, itemindex, height}`.
- Vanilla already has an unfinished "Random" option (`UI_mapspawn_random` = "Random"). Its guard `#self.listbox.items > 1` runs before any items are added, so it never appears. `clickNext` handles it with `ZombRand(#items - 1) + 1`, which assumes the option is last. Our mod must stay correct if a future patch makes the vanilla entry appear. In that case we don't add ours, and the picker never picks a vanilla "Random" entry.
- `clickNext()` reads `self.listbox.items[self.listbox.selected].item.region`, calls `setSpawnRegion(region.name)`, and then moves on to sandbox options or character creation.
- `CoopMapSpawnSelect` (split-screen co-op join) calls `MapSpawnSelect.fillList(self)` directly, so our wrapper runs there too and has to bail out.
- In multiplayer the same screen is used (`getWorld():getGameMode() == GameMode.MULTIPLAYER`).
- `ISScrollingListBox:insertItem(index, name, item)` does not renumber `itemindex` on the existing rows, so we renumber them ourselves.

## Global Constraints

- Build 42 only. Single-player new games only (no multiplayer, no split-screen co-op screen).
- Entry label: "Random city". Entry description: "Spawn in a random city." Both come from translation keys `UI_RandomCitySpawn_Name` / `UI_RandomCitySpawn_Desc`.
- Entry position: first row of the list. The default selection stays on the first real city, so players who don't care see no change.
- Equal chance for every real city in the list, vanilla and modded.
- No message that reveals the chosen city. Repeats are allowed, and nothing is saved between games.
- Never copy vanilla functions wholesale. Wrap them by saving the original and calling through.
- Mod id: `RandomCitySpawn`. Mod name: "Random City Spawn".

## Review Focus

1. **Split-screen co-op join screen** (`CoopMapSpawnSelect`) shares `fillList`. The entry must not appear there. Covered by Task 2 test `test_no_entry_on_coop_screen`.
2. **Multiplayer**: the entry must not appear. Covered by Task 2 test `test_no_entry_in_multiplayer`.
3. **Only one region** (challenge, fixed server spawn, safehouse): the entry must not appear, because there's nothing to randomize. Covered by Task 2 test `test_no_entry_with_single_city`.
4. **Back after Next**: if the player goes back to this screen, "Random city" is still selected, so the city stays hidden and the next Next re-rolls. Covered by Task 2 test `test_selection_restored_after_next`.
5. **Vanilla "Random" entry appears in a future patch**: don't show two random entries, and never pick a random entry as the city. Covered by Task 1 test `test_never_picks_random_entries` and Task 2 test `test_no_entry_when_vanilla_random_present`.

---

## File Structure

Repository root: `D:\Projects\pz-random-city-spawn` on the person's PC (empty today; `git init` in Task 1).

```
Contents/mods/RandomCitySpawn/
  common/.gitkeep                                   (B42 requires the folder to exist)
  42/mod.info
  42/media/lua/client/RandomCitySpawn/RandomCityPicker.lua   pure logic
  42/media/lua/client/RandomCitySpawn/RandomCitySpawn.lua    hooks into MapSpawnSelect
  42/media/lua/shared/Translate/EN/UI.json                   label + description
tests/
  run.lua            tiny runner: loads test files, prints PASS/FAIL, exits non-zero on failure
  stubs.lua          fake getText, getWorld, GameMode, ZombRand, ISScrollingListBox, MapSpawnSelect
  test_picker.lua
  test_hooks.lua
README.md            install (copy to %UserProfile%\Zomboid\mods) and how to run tests
```

Run all tests: `lua5.1 tests/run.lua` from the repo root.

---

### Task 1: Picker logic + repo skeleton

**Files:**
- Create: `Contents/mods/RandomCitySpawn/42/media/lua/client/RandomCitySpawn/RandomCityPicker.lua`
- Create: `tests/run.lua`, `tests/test_picker.lua`
- Create: `Contents/mods/RandomCitySpawn/common/.gitkeep`, `Contents/mods/RandomCitySpawn/42/mod.info`, `README.md`, `.gitignore`

**Interfaces:**
- Produces (global table `RandomCityPicker`, also returned from the file):
  - `RandomCityPicker.isRandomItem(item: table) -> boolean`: true if `item.isRandomCity == true` or `item.region == nil`. Vanilla's random entry has `region = nil`.
  - `RandomCityPicker.realIndices(listItems: table) -> table`: the indices `i` into `listItems` (listbox rows `{text, item}`) where `not isRandomItem(row.item)`, in order.
  - `RandomCityPicker.pickIndex(listItems: table, randInt: function(n) -> 0..n-1) -> number|nil`: a uniformly chosen value from `realIndices`, or nil if empty. `randInt` is `ZombRand` in-game and is injected in tests.
  - `RandomCityPicker.shouldShowEntry(listItems: table) -> boolean`: true if `#realIndices >= 2` and no row has `isRandomItem(row.item)`.

- [ ] **Step 1: Create the repo skeleton.** `git init` in the repo root. Add `.gitignore` (ignore `*.log`) and `common/.gitkeep`. Add `mod.info` with these lines: `name=Random City Spawn`, `id=RandomCitySpawn`, `description=Adds a "Random city" option to the spawn location list.`, `versionMin=42.0.0`. Add `README.md` with the install path `%UserProfile%\Zomboid\mods\RandomCitySpawn` (copy the `Contents/mods/RandomCitySpawn` folder there) and the test command.

- [ ] **Step 2: Write `tests/run.lua`.** Set `package.path` so `require "RandomCitySpawn/RandomCityPicker"` resolves to `Contents/mods/RandomCitySpawn/42/media/lua/client/?.lua`. Run every global function whose name starts with `test_` from `test_picker.lua` and `test_hooks.lua` (skip a missing file). Print `PASS name` / `FAIL name: err`, and `os.exit(1)` if anything failed.

- [ ] **Step 3: Write the failing tests in `tests/test_picker.lua`**

```lua
local P = require "RandomCitySpawn/RandomCityPicker"
local function row(name, region, extra) local it = {name=name, region=region}; for k,v in pairs(extra or {}) do it[k]=v end; return {text=name, item=it} end
local cities = { row("Muldraugh, KY", {name="Muldraugh, KY"}), row("Riverside, KY", {name="Riverside, KY"}), row("Rosewood, KY", {name="Rosewood, KY"}) }

function test_realIndices_skips_random_entries()
  local items = { row("Random city", nil, {isRandomCity=true}), cities[1], cities[2], row("Random", nil) }
  local idx = P.realIndices(items); assert(#idx == 2 and idx[1] == 2 and idx[2] == 3)
end
function test_pickIndex_maps_rand_to_real_rows()
  local items = { row("Random city", nil, {isRandomCity=true}), cities[1], cities[2], cities[3] }
  assert(P.pickIndex(items, function(n) assert(n == 3); return 0 end) == 2)
  assert(P.pickIndex(items, function(n) return 2 end) == 4)
end
function test_never_picks_random_entries()
  local items = { row("Random city", nil, {isRandomCity=true}), cities[1], row("Random", nil), cities[2] }
  for r = 0, 1 do local i = P.pickIndex(items, function() return r end); assert(not P.isRandomItem(items[i].item)) end
end
function test_pickIndex_nil_when_no_cities()
  assert(P.pickIndex({ row("Random city", nil, {isRandomCity=true}) }, function() return 0 end) == nil)
end
function test_pickIndex_is_uniform()
  local counts = {0,0,0}; math.randomseed(1)
  for _ = 1, 30000 do local i = P.pickIndex(cities, function(n) return math.random(0, n-1) end); counts[i] = counts[i] + 1 end
  for _, c in ipairs(counts) do assert(c > 9000 and c < 11000, "skewed: "..c) end
end
function test_shouldShowEntry_rules()
  assert(P.shouldShowEntry(cities) == true)
  assert(P.shouldShowEntry({ cities[1] }) == false)
  assert(P.shouldShowEntry({ cities[1], cities[2], row("Random", nil) }) == false)
end
```

- [ ] **Step 4: Run** `lua5.1 tests/run.lua`. Expected: FAIL (module not found).
- [ ] **Step 5: Implement `RandomCityPicker.lua`** per the Interfaces block. The file must not reference any game global (`getText`, `ZombRand`, etc.).
- [ ] **Step 6: Run** `lua5.1 tests/run.lua`. Expected: all 6 PASS.
- [ ] **Step 7: Commit** `feat: add random city picker logic and mod skeleton`.

### Task 2: Hook the spawn selection screen

**Files:**
- Create: `Contents/mods/RandomCitySpawn/42/media/lua/client/RandomCitySpawn/RandomCitySpawn.lua`
- Create: `Contents/mods/RandomCitySpawn/42/media/lua/shared/Translate/EN/UI.json`
- Create: `tests/stubs.lua`, `tests/test_hooks.lua`

**Interfaces:**
- Consumes: `RandomCityPicker.pickIndex`, `RandomCityPicker.shouldShowEntry`, `RandomCityPicker.isRandomItem` (Task 1).
- Produces: module table `RandomCitySpawn` with `RandomCitySpawn.isEligibleScreen(screen) -> boolean` (false when `screen.Type == "CoopMapSpawnSelect"`, `MainScreen.instance.inGame` is true, or `getWorld():getGameMode() == GameMode.MULTIPLAYER`). It wraps `MapSpawnSelect.fillList` and `MapSpawnSelect.clickNext` on load. The file starts with `require "OptionScreens/MapSpawnSelect"` and `require "RandomCitySpawn/RandomCityPicker"`.

Behaviour:
- **fillList wrapper:** call the original. Then, if `isEligibleScreen(self)` and `shouldShowEntry(self.listbox.items)`, insert at row 1 the item `{name=getText("UI_RandomCitySpawn_Name"), desc=getText("UI_RandomCitySpawn_Desc"), region=nil, dir="", isRandomCity=true}` via `self.listbox:insertItem(1, name, item)`. Renumber every row's `itemindex` to its position, and set `self.listbox.selected = 2`.
- **clickNext wrapper:** if the selected row's `item.isRandomCity`, set `randomRow = selected`, then `self.listbox.selected = RandomCityPicker.pickIndex(self.listbox.items, ZombRand)`. Call the original `clickNext(self)`. Afterwards, if `randomRow` is set, restore `self.listbox.selected = randomRow`. The region has already been applied, and this keeps the city hidden if the player comes back with Back. If `pickIndex` returns nil, call the original with the selection unchanged.

- [ ] **Step 1: Write `tests/stubs.lua`.** It provides: `getText(key)` that returns a fixed map (`UI_RandomCitySpawn_Name`→"Random city", `UI_RandomCitySpawn_Desc`→"Spawn in a random city.", `UI_mapspawn_random`→"Random"). It also provides `GameMode = {MULTIPLAYER="MP", SANDBOX="SB", SURVIVAL="SV"}`, a settable `getWorld():getGameMode()`, `MainScreen = {instance={inGame=false}}`, and a settable `ZombRand`. Add `newListBox()` returning a minimal `ISScrollingListBox` with `items`, `selected`, `count`, `clear`, `addItem`, `insertItem` copied in behaviour from the facts above. Add a fake `MapSpawnSelect` whose `fillList` clears the listbox and adds one row per name in `self.regionNames` (region = `{name=n}`), and whose `clickNext` records `self.listbox.items[self.listbox.selected].item.region.name` into `self.spawnedIn`. `run.lua` loads stubs before `test_hooks.lua`, and `package.preload["OptionScreens/MapSpawnSelect"]` returns the fake.

- [ ] **Step 2: Write the failing tests in `tests/test_hooks.lua`.** Each test builds a fresh screen `{listbox=newListBox(), regionNames={...}}` with `setmetatable` onto `MapSpawnSelect`.

```lua
function test_entry_added_first_and_city_still_default()      -- 3 cities → items[1].text == "Random city", #items == 4, selected == 2, items[i].itemindex == i
function test_entry_description()                             -- items[1].item.desc == "Spawn in a random city."
function test_next_spawns_in_rolled_city()                    -- select 1, ZombRand = function(n) assert(n==3) return 2 end → spawnedIn == regionNames[3]
function test_next_on_real_city_unchanged()                   -- select 3 → spawnedIn == regionNames[2], ZombRand never called
function test_selection_restored_after_next()                 -- select 1, Next → listbox.selected == 1 afterwards
function test_fillList_twice_no_duplicates()                  -- call fillList twice → exactly one row with isRandomCity
function test_no_entry_with_single_city()                     -- regionNames={"Muldraugh, KY"} → #items == 1
function test_no_entry_in_multiplayer()                       -- game mode MP → no isRandomCity row
function test_no_entry_on_coop_screen()                       -- screen.Type = "CoopMapSpawnSelect" → no isRandomCity row; also MainScreen.instance.inGame = true → none
function test_no_entry_when_vanilla_random_present()          -- fake fillList also appends {name="Random", region=nil} → no isRandomCity row
```

- [ ] **Step 3: Run** `lua5.1 tests/run.lua`. Expected: the 10 hook tests FAIL; the picker tests PASS.
- [ ] **Step 4: Write `UI.json`.** Content: `{ "UI_RandomCitySpawn_Name": "Random city", "UI_RandomCitySpawn_Desc": "Spawn in a random city." }`.
- [ ] **Step 5: Implement `RandomCitySpawn.lua`** per Interfaces and Behaviour. Save the originals as `local original_fillList = MapSpawnSelect.fillList` (same for clickNext) and reassign `MapSpawnSelect.fillList = function(self, ...) ... end`.
- [ ] **Step 6: Run** `lua5.1 tests/run.lua`. Expected: 16 PASS, 0 FAIL.
- [ ] **Step 7: Commit** `feat: add Random city entry to spawn selection screen`.

### Task 3: In-game check

**Files:** none (manual). Modify `README.md` only if a step below turns out wrong.

- [ ] **Step 1:** Copy `Contents/mods/RandomCitySpawn` to `%UserProfile%\Zomboid\mods\RandomCitySpawn`. Start Build 42, enable "Random City Spawn" in Mods, and check `%UserProfile%\Zomboid\console.txt` for Lua errors mentioning `RandomCitySpawn`. Expected: none.
- [ ] **Step 2:** New game → Apocalypse. Expected: "Random city" is the first row, the first real city is highlighted, and selecting "Random city" shows "Spawn in a random city." in the description panel.
- [ ] **Step 3:** Select "Random city" → Next → Back. Expected: "Random city" is still highlighted.
- [ ] **Step 4:** Start 3 games with "Random city". Expected: you spawn in a valid city each time, with no errors in `console.txt`. The cities don't have to differ, but over 3 games at least 2 different ones usually come up.
- [ ] **Step 5:** New game → pick a real city (e.g. Riverside). Expected: you spawn in Riverside (unchanged vanilla behaviour).
- [ ] **Step 6:** Commit any README fixes as `docs: correct install steps`.
