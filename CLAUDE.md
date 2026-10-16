# LAST STAND — Project Rules

Commercial indie game for Steam. 2D top-down dark fantasy roguelite tower defense.
The player controls a hero in real time, builds towers, and defends a fortress against waves.

- Engine: **Godot 4.7** (4.7.2 installed at `~/Downloads/Godot_v4.7.2-stable_linux.x86_64`), GDScript only, 2D, Windows PC, single player.
- Renderer: **Compatibility** (OpenGL 3) for the widest PC/laptop support. Base viewport 1280×720, stretch `canvas_items` / `expand`. 2D gravity is 0 (top-down).
- Design reference: `GAME_DESIGN.md`. Milestones and current focus: `ROADMAP.md`.

## Working rules

1. **One feature at a time.** Implement, run, verify, then move on. Don't scaffold systems "for later".
2. **Playable over pretty.** Placeholder art (ColorRect, Polygon2D, `icon.svg`, simple shapes) is fine until the Polish milestone.
3. **No external dependencies.** No addons, plugins, paid assets, or C#. Godot built-ins only. Any third-party asset must be CC0 or self-made, with its source and license logged in `assets/CREDITS.md`.
4. **Never overwrite existing files without reading them first.** Prefer small edits over rewrites.
5. **Ask before** adding an autoload, changing physics layers, changing the input map, or restructuring folders.
6. **Explain architectural decisions** in the response (and in `GAME_DESIGN.md` if it changes a system).
7. Gameplay implementation requires the user's approval of the feature scope first.

## Architecture principles

- **Scenes are self-contained.** A scene must run on its own (F6) or with minimal setup. Children never reach up the tree with `get_parent()` chains.
- **"Call down, signal up."** Parents call methods on children; children emit signals to parents. Cross-system communication goes through the `Events` autoload.
- **Data lives in Resources.** Stats for enemies, towers, upgrades, and waves are `.tres` files built from custom `Resource` classes (`EnemyData`, `TowerData`, ...). Balancing must never require editing code.
- **Composition over inheritance.** Shared behaviour goes in small component nodes (`HealthComponent`, `Hurtbox`, `Hitbox`). Keep inheritance shallow (max one custom base class, e.g. `Enemy`).
- **Few autoloads.** Allowed: `Events` (global signal bus), `RunState` (current run's gold, wave, fortress HP, chosen upgrades). Later possibly `SaveManager`, `Audio`. Nothing else without asking.
  Neither exists yet: each is created (in `autoload/`) by the first feature that actually needs a cross-system signal or run-wide state. Never add empty placeholder signals or fields.
- **No logic in UI.** UI reads state and emits intents; game systems own the rules.
- **Level layout rule:** every level has a `%Floor` rect that *is* the playable arena, an `ArenaBounds` `StaticBody2D` (world layer) whose wall shapes' inner edges sit exactly on the floor edges, and Camera2D limits equal to the floor. Keep the three in sync (`test_arena_bounds` checks it).
- **Run lifecycle:** `main.tscn` (`main.gd`) owns the current `Level` instance. A level emits `run_lost` once and disables itself (`PROCESS_MODE_DISABLED`, which also removes its physics shapes); Main shows `GameOverScreen` and restarts by replacing the level with a fresh instance. No global pause, no autoload.

## Folder structure

```
res://
├── autoload/            # Events, RunState (global singletons only)
├── core/                # Engine-level helpers: components, base classes, utilities
│   ├── components/      # health_component, hitbox, hurtbox, ...
│   └── utils/
├── data/                # .tres instances (balancing lives here)
│   ├── enemies/
│   ├── towers/
│   ├── upgrades/
│   └── waves/
├── entities/            # Things that exist in the world, one folder per entity
│   ├── hero/            # hero.tscn, hero.gd, hero states
│   ├── enemies/         # enemy.gd (base), enemy.tscn, variants/
│   ├── towers/          # tower.gd (base), tower.tscn, build_slot.tscn
│   ├── projectiles/
│   └── fortress/
├── resources/           # Custom Resource class scripts (enemy_data.gd, tower_data.gd, ...)
├── systems/             # Non-visual game logic nodes: wave_spawner, economy, upgrade_picker
├── levels/              # Maps: arena layout, lanes (Path2D), build slots
├── ui/                  # hud/, menus/, upgrade_screen/, shared widgets/
├── main/                # main.tscn — boot, scene switching
├── assets/              # Raw art/audio/fonts only (no scripts)
│   ├── sprites/  audio/  fonts/  shaders/
│   └── CREDITS.md
└── tests/               # Sandbox scenes for testing one feature in isolation
```

Rule of thumb: a scene and its script live **next to each other** in the folder of the feature they belong to.

Empty folders hold a `.gitkeep` so Git tracks them; delete it once the folder has real files.
Commit the `*.gd.uid` files Godot generates next to scripts; they keep references stable when files move.

## GDScript conventions

Follow the official Godot GDScript style guide, plus:

- **Static typing everywhere**: `var speed: float = 200.0`, `func take_damage(amount: int) -> void:`. Use `:=` only when the type is obvious.
- Naming: files/folders `snake_case`; `class_name` `PascalCase`; functions/vars `snake_case`; constants/enum values `CONSTANT_CASE`; private members prefix `_`; signals past tense (`died`, `wave_started`).
- Script member order: `class_name` / `extends` → doc comment → signals → enums → constants → `@export` → public vars → private vars → `@onready` → built-in callbacks (`_ready`, `_process`, ...) → public methods → private methods.
- Use `@export` for tunable values and node references set in the editor; use `@onready var x: Node = %UniqueName` for internal children (unique names, not long paths).
- Use `_physics_process` for movement/combat, `_process` for visuals only.
- No magic numbers in logic: export them or put them in a data Resource.
- Prefer `signal.connect(callable)` in code over editor connections, so wiring is visible in scripts.
- Guard freed nodes with `is_instance_valid()` when holding references to enemies/targets.
- Use groups sparingly and only with constants (e.g. `Groups.ENEMIES`), never string literals scattered around.
- Keep functions short; a script over ~300 lines is a sign it should be split.
- Comments explain *why*, not *what*.

## Physics layers (2D)

| # | Name        | Used by                          |
|---|-------------|----------------------------------|
| 1 | world       | walls, obstacles, map bounds     |
| 2 | hero        | hero body                        |
| 3 | enemies     | enemy bodies                     |
| 4 | fortress    | fortress body                    |
| 5 | hero_hitbox | hero attacks / hero projectiles  |
| 6 | enemy_hitbox| enemy attacks / enemy projectiles|
| 7 | tower_range | tower detection areas            |

These names are configured in Project Settings → Layer Names → 2D Physics.

Damage wiring: a `Hitbox` sits **on** `hero_hitbox` (bit value 16) or `enemy_hitbox` (32) with mask 0. A `Hurtbox` has layer 0 and **masks** the opposite side's hitbox layer (enemies mask `hero_hitbox`, the hero masks `enemy_hitbox`). Hurtboxes do the detecting; damage is applied once per overlap entry.

## Input actions

Configured: `move_up`, `move_down`, `move_left`, `move_right` (WASD as **physical** keys so AZERTY/QWERTZ work + arrows), `attack` (LMB), `interact` (E).

Planned, added by the feature that needs them: `ability_1` (Space/RMB), `build` (B), `pause` (Esc). Never check raw keycodes in code.

## Testing a feature

- Every new feature gets a sandbox scene in `tests/` (e.g. `tests/test_hero_movement.tscn`) where it can be tried by hand (F6).
- Every new feature also gets an automated test `tests/automated/test_<feature>.gd`: a script that `extends SceneTree`, drives the real scenes (e.g. `Input.action_press`), prints `[ok]`/`[FAIL]` lines and calls `quit(<number of failures>)`. Wait a frame after `add_child` before reading state set in `_ready()`.
- **Run everything before calling a feature done:** `tests/run_tests.sh` (Godot binary from `$GODOT`, default `~/Downloads/Godot_v4.7.2-stable_linux.x86_64`). It runs the editor import, checks every `.gd` with **all GDScript warnings treated as errors** (via a temporary, git-ignored `override.cfg`), runs every automated test with `--fixed-fps 60` (deterministic, faster than real time), and runs `main.tscn` + every scene in `entities/`, `levels/`, `ui/` and `tests/` for 120 frames. Must end with `ALL PASSED`.
- Helpers for the runner live in `tests/tools/`. The `tests/` folder must be excluded from release exports (M8).
