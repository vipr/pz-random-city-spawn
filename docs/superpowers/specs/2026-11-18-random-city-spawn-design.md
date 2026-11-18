# Random City spawn option: design (short)

Date: 2026-11-18. Size: small change.

## Intent
Add a "Random city" entry to the new-game city selection screen in Project Zomboid. If the player picks it, the game spawns them in a random city. The player finds out where they are only after they spawn. The likely motivation is replay value. The person did not state it, so this is an assumption.

## Goals
- A "Random city" entry in the city list on the new-game spawn selection screen (Build 42).
- When the player clicks Next with it selected, choose one real city from the list, each with equal chance, and continue exactly as if the player had picked that city.
- Include every city in the list, vanilla and modded-map cities alike, because they share the same list.

## Non-goals
- Multiplayer and server spawn regions. Single-player new games only for now.
- Remembering or avoiding the previous city. Repeats are fine.
- Any message or announcement saying which city was picked.
- Build 41 support.

## Anti-goals
- Spawning in one place and then teleporting. The player should never see the wrong city first.
- Changing how vanilla spawning works once a city is chosen.

## Approaches considered
1. **Add a list entry, swap it on Next (chosen).** Add "Random city" to the screen's list. On Next, replace the selection with a random real entry, then hand off to the vanilla flow. Native spawn behavior, modded cities for free. Risk: it hooks into the screen's Lua code, so a game update to that screen may need a patch.
2. **Spawn, then teleport.** Less tied to the screen code, but the player loads into the wrong place first, the first area gets generated for nothing, and spawn-dependent details can be wrong. Rejected.
3. **One combined region with every city's spawn points.** Cities would be weighted by how many spawn points they have, not picked evenly. Rejected.

Picked by: Claude recommended option 1. It matches the flow the person described ("Random city" entry, city chosen on Next). Approved by the person on 2026-11-18. Entry goes at the top of the list, with the description "Spawn in a random city."

## Constraints
- Build 42 Lua modding (mod folder layout `Contents/mods/<id>/42/...`, `mod.info`).
- Override or extend the vanilla spawn selection screen (`MapSpawnSelect` or its B42 equivalent) without copying the whole file, to keep conflicts with other mods low.

## Left to the builder
- Find the exact B42 functions that fill the list and handle Next. Read the game's own `media/lua/client/OptionScreens` files, which are in the person's local install.
- Where "Random city" sits in the list. Proposal: at the top.
- How to show it in the list (text only, or with a placeholder image/description, e.g. "Spawn in a random city").
- The mod name/id and Workshop packaging.
- How it is tested: manually in-game, by starting several new games.
