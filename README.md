# Random City Spawn (Project Zomboid Build 42)

Adds a **Random city** entry at the top of the spawn location list when you start a new
single-player game. Pick it, click Next, and you spawn in one of the listed cities
(vanilla and modded maps), each with an equal chance. You find out where once you spawn.

## Options

Options > Mods > Random City Spawn > **Random city position**: Last (default) or First.

Languages: English, French, Spanish, German, Italian, Ukrainian.

While "Random city" is selected, the map on the right is replaced by a Random city picture.

## Install (local)

Copy the folder `Contents/mods/RandomCitySpawn` to `%UserProfile%\Zomboid\mods\RandomCitySpawn`,
then enable "Random City Spawn" in the game's Mods menu.

## Steam Workshop

The repository root is laid out as a Workshop item: copy it to `%UserProfile%\Zomboid\Workshop\RandomCitySpawn\`
(it needs `preview.png`, `workshop.txt` and `Contents\`), then upload from the game's main menu (Workshop).
The game fills in `id=` in `workshop.txt` after the first upload; commit that change.

## Artwork

`tools/make_images.py` regenerates the picture, poster, icon and Workshop preview.

## Tests

Requires Lua 5.1. From the repository root:

    lua5.1 tests/run.lua
