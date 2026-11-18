# Random City Spawn mod: project summary

Nov 18, 2026 · Vik Prime

## Overview

Random City Spawn v1.0.0 is done, tested in the game, and ready for a Steam Workshop upload. It adds a "Random city" entry to the city picker in Project Zomboid Build 42, so a new game can start in a city chosen at random.

- **Game:** Build 42, single-player only.
- **Status:** all three pull requests merged to `main`; 28 automated tests pass; in-game checks passed on 2026-11-18.
- **Languages:** English, French, Spanish, German, Italian, Ukrainian.

## How it works

The city is rolled when you click Next, so the picker never reveals where you are going.

1. The mod adds a "Random city" row to the city list, placed Last by default (or First, via Options → Mods → Random City Spawn).
2. Selecting it shows a custom picture over the map preview instead of a map.
3. Clicking Next swaps the entry for a real city, picked with equal odds from every city in the list, vanilla and modded maps alike.
4. There is no announcement, and the same city can come up twice in a row.

Build 42 ships a hidden, half-finished built-in "Random" option whose check never fires. If a game patch ever makes it visible, the mod hides its own entry to avoid a duplicate.

## What shipped today

The base mod was built and tested first, then three pull requests added options, translations and Workshop files. All are merged to `main`.

| Step | What it added | Tests |
| --- | --- | --- |
| [PR #3](https://github.com/vipr/pz-random-city-spawn/pull/3) | `workshop.txt` with title, description, tags `Build 42; Interface; Misc`, public visibility | 28 pass |
| [PR #2](https://github.com/vipr/pz-random-city-spawn/pull/2) | Translations: EN, FR, ES, DE, IT, UA, plus a test that every language has all 7 texts | 28 pass |
| [PR #1](https://github.com/vipr/pz-random-city-spawn/pull/1) | First/Last position option; Random city picture over the map; mod info (version 1.0.0, author prime.vik, homepage, poster, icon, `preview.png`) | 27 pass |
| Base mod | Random city entry, roll on Next, coexistence with the hidden built-in option; history pushed to GitHub | 18 pass |

## Publishing to the Workshop

The repository root is laid out as a Workshop item, so uploading takes two steps.

1. Copy `preview.png`, `workshop.txt` and the `Contents` folder from `D:\Projects\pz-random-city-spawn` to `%UserProfile%\Zomboid\Workshop\RandomCitySpawn\`.
2. In the game's main menu, open Workshop and upload the RandomCitySpawn item.

After the first upload, the game writes an `id=` line into `workshop.txt`. Commit that change so later updates go to the same Workshop item.

## Known issues and next steps

Two minor issues were left as they are, since neither reveals the rolled city.

- If a later screen rebuilds the list when you go Back, the highlight may reset to the first city.
- The default selection is fixed to the first real city.

Possible next steps:

- [ ] Upload to the Steam Workshop
- [ ] Add a debug line to `console.txt` showing each roll (for example "rolled 1 of 12: Brandenburg")
- [ ] Multiplayer support

## Where things live

| What | Where |
| --- | --- |
| Repository | [github.com/vipr/pz-random-city-spawn](https://github.com/vipr/pz-random-city-spawn) (`main`) |
| Local copy | `D:\Projects\pz-random-city-spawn` |
| Mod code | `Contents/mods/RandomCitySpawn/42/media/lua/client/RandomCitySpawn/` |
| Translations | `Contents/mods/RandomCitySpawn/42/media/lua/shared/Translate/` |
| Random city picture | `Contents/mods/RandomCitySpawn/42/media/ui/RandomCitySpawn/random_city.png` (made by `tools/make_images.py`) |
| Tests | `tests/` (run with Lua 5.1: `lua5.1 tests/run.lua`) |

The old `pz-random-city-spawn.bundle` in the local folder is out of date and can be deleted.
