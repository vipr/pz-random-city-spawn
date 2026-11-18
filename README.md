# Random City Spawn (Project Zomboid Build 42)

Adds a **Random city** entry at the top of the spawn location list when you start a new
single-player game. Pick it, click Next, and you spawn in one of the listed cities
(vanilla and modded maps), each with an equal chance. You find out where once you spawn.

## Install (local)

Copy the folder `Contents/mods/RandomCitySpawn` to `%UserProfile%\Zomboid\mods\RandomCitySpawn`,
then enable "Random City Spawn" in the game's Mods menu.

## Tests

Requires Lua 5.1. From the repository root:

    lua5.1 tests/run.lua
