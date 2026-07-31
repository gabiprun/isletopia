# Isletopia

A Poptropica-*style* side-scrolling island adventure — original name, art, and
stories (no Poptropica assets; the mechanics genre is the homage). Godot 4.7,
one codebase targeting **Web, Android, iOS**. All art is code-drawn vector
(no image assets), so the whole game data is ~140 KB.

## Play

- Customizable big-head avatar (skin, hair, colors) + generated explorer names
- Blimp map to travel between islands; earn a **medallion** per completed quest
- **Ember Isle** (6 rooms): the lighthouse went dark — find 3 lens shards
  (cliff platforming, a dark cave that needs the lantern, an underwater dive +
  starfish trade at the market)
- **Frost Peak** (3 rooms): the yeti borrowed the Festival Bell — icy one-way
  platforms, a yarn fetch, and a hand-knitted giant hat
- Tap/click to walk, tap above to jump (or arrows/WASD + space). Tap NPCs to
  talk, glowing items to collect, arrow badges to change rooms.
- Auto-saves after every quest step; Continue resumes island + room.

## Run locally

```sh
godot --path .                  # desktop run
cd build/web && python3 -m http.server 8791   # play the web build
```

## Test harnesses

```sh
godot --headless -- --smoke     # auto-plays BOTH island quests end to end, exits 0/1
godot -- --shot=/tmp/shots      # screenshots every screen + room
```

## Exports

`export_presets.cfg` has Web / Android / iOS presets.

```sh
godot --headless --export-release "Web" build/web/index.html
godot --headless --export-debug  "Android" build/isletopia-debug.apk   # later
# iOS: export from editor → Xcode project, needs signing team           # later
```

Web preset is **single-threaded** (`variant/thread_support=false`) so it runs
on any static host — no COOP/COEP headers needed. Serve with gzip: the 38 MB
wasm compresses to ~10 MB.

## Code map

| File | What |
|---|---|
| `scripts/game_state.gd` | autoload: flags, inventory, medallions, save/load, sfx |
| `scripts/main.gd` | screen switching + `--smoke` / `--shot` harnesses |
| `scripts/world.gd` | room engine: platforms, props, doors, dark rooms, taps |
| `scripts/avatar_rig.gd` | code-drawn character (7 hair styles, walk/swim/talk anims) |
| `scripts/player.gd` | Poptropica-feel physics; ice + swim modes |
| `scripts/islands/*.gd` | pure-data island definitions (rooms, NPCs, dialogs, hints) |
| `scripts/prop.gd` | ~18 code-drawn scenery props |
| `tools/gen_sfx.py` | regenerates the WAV sound effects |

## Adding an island

Copy `scripts/islands/frost_peak.gd`, register it in `island_registry.gd`
(`list_islands()` + `get_island()`), done. Rooms/NPCs/dialogs/hints are plain
dictionaries — no scenes to wire.
