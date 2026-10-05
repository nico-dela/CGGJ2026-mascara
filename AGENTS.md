# AGENTS.md — El Caso del Leñador

2D point-and-click graphic adventure (Córdoba Global Game Jam 2026). Short session: mystery, dialogue, masks.

## Stack

- Godot **4.7**, GDScript, GL Compatibility renderer
- Dialogue Manager 3 (`addons/dialogue_manager/` — do not edit unless necessary)
- Landscape 16:9 (1920×1080 base); touch-friendly

## Architecture

| Autoload | Role |
|----------|------|
| `GameManager` | Facade for dialogue mutations + save |
| `StoryFlags` | Narrative flags, equipped mask, evidence |
| `Inventory` | Items, selection, persistent pickups |
| `SceneRouter` | Scene change with fade and spawn ids |
| `InteractionHint` | Verb text on hover |
| `AudioManager` / `DisplayAdapt` / `PauseMenu` | Audio, UI scale, pause |
| `AdventureUI` | Verb coin + Bolso HUD |

- Interactables: `scripts/core/interactable.gd`, `scripts/core/npc_interactable.gd`
- Dialogue: `content/dialogue/**` (mutations via `GameManager.*`)
- Items: `content/items/*.tres` (`ItemResource`: `ITEM` / `MASCARA`)
- Rooms: `scenes/rooms/room_road.tscn` (road) → `room_1` (exterior) → `room_2` (police station) / `room_3` (bar)

## Folder layout

```
autoload/           # singletons
assets/art|audio|video|fonts
content/dialogue|items
scenes/rooms|actors|ui|systems
scripts/core|actors|interactables|ui
ui/balloon/
addons/             # do not edit Dialogue Manager
```

## Narrative canon (MVP)

- The **bear mask** turns the wearer into a lumberjack. Original wearer = **fisherman** → lumberjack = fisherman.
- Goal: solve the case in order to **restock the boiler and firewood**.
- Only the **bear mask** is wearable for plot (no NPC mask swaps).
- Part 1: road → talk to the **hawker** (`hablado_hawker`) → take the **bag** (UI tutorial) → town; hunger → **bar** (`hablado_cantinero`) → **comisario** briefing (`comisario_briefing`) starts the case.
- Hybrid item sourcing (world stays real; meaning unlocks after the problem is stated):
  - **American football (`pelota`)**: from the **hawker** only after `comisario_briefing` (persuade / credential). Not a forest pop-in.
  - **Rubber duck (`patito`)**: optional gift from the **fisherman** in town; return to bartender is optional flavor (not a gate).
  - **Bear mask**: always visible in the forest; Look anytime; Take only after `huellas_pelota`.
  - **Log/axe**: always visible; Take succeeds only while wearing `oso`.
  - **Ivy**: always visible until cut.
- Ball → police → **footprints** flag: muddy sole print matches the bartender (he lied about the woods). Not enough to arrest — no body, no complaint; player must dig up the truth.
- With the **bear equipped**: Take the **axe** from the log; **use axe on ivy** → `abrir_paso` (access to the river).
- Expose the bartender: **footprints AND** bear **equipped** + Talk → confession; the fisherman moves to the river (the axe opens the physical passage).
- Ending A: mask to the fisherman → deal (firewood now and then) + mask/routine punchline → **credits**.

## Controls / UX

- **Full Throttle** style: a click on a hotspot opens the **verb coin** (Look / Talk / Use / Take). **Look ≠ Talk** on NPCs. **Use** is enabled only if the hotspot has a real effect (not a reject).
- On the road: the world bag is **taken** and becomes the **Bolso** button (corner). It holds the detective **credential** (item); **Use** it with NPCs to introduce yourself. Without the bag you cannot take items. Short tutorial when it is taken.
- `TownTransition` (town) requires `hablado_hawker`.
- Inventory is in the **Bolso**; select an item and click a target = use with…
- Mask: second click on the slot, or Use + click on the detective (**oso** only).
- Doors / transitions: direct click. Escape closes the coin.
- `AdventureUI` autoload; per-room `InventoryUI` stays hidden.

## Code conventions

- Narrative state lives in `StoryFlags`; dialogue only calls `GameManager.*`.
- Puzzles must advance the story (Gilbert): a clear goal, problem before solution, events connected to opening the river — without teleporting props into existence.
- **English for code**: GDScript identifiers, comments, commits, and agent docs. Spanish stays in dialogue / UI copy. Do not mass-rename existing story item ids (`pelota`, `oso`, …) unless already touching that API.
- Prefer existing assets or jam-friendly CC0; do not over-engineer.
- Do not touch `addons/dialogue_manager/`. Do not regenerate `build/` unless an export is requested.
