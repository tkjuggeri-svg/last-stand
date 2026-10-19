# LAST STAND — Project Rules

Commercial indie game for Steam. 2D top-down dark fantasy roguelite tower defense.
The player controls a hero in real time, builds towers, and defends a fortress against waves.

- Engine: **Godot 4.7** (4.7.2 installed at `~/Downloads/Godot_v4.7.2-stable_linux.x86_64`), GDScript only, 2D, Windows PC, single player.
- Renderer: **Compatibility** (OpenGL 3) for the widest PC/laptop support. Base viewport 1280×720, stretch `canvas_items` / `expand`. 2D gravity is 0 (top-down).
- Design reference: `GAME_DESIGN.md`. Milestones and current focus: `ROADMAP.md`.

## Working rules

1. **One feature at a time.** Implement, run, verify, then move on. Don't scaffold systems "for later".
2. **Playable over pretty.** A new feature may start with placeholder shapes, but anything shipped in a level gets pixel art that follows the **Pixel art** rules below.
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
- **Level layout rule:** every level has a `%Floor` rect that *is* the playable arena, an `ArenaBounds` `StaticBody2D` (world layer) whose wall shapes' inner edges sit exactly on the floor edges, a `%Ground` sprite covering the floor plus the visible 32 px wall band (`WALL_BAND`), and Camera2D limits equal to that same floor + band rect. Keep them in sync (`test_arena_bounds` checks it). The level root, the spawner and `%Effects` are y-sorted; ground layers use negative `z_index`.
- **Per-level systems:** `Economy`, `WaveRewards` and `TowerBuilder` are plain nodes under the level's `Systems` node, wired to each other and to the spawner, slots, HUD and build menu with exported node references (no autoloads). Gold only changes through `Economy.earn()` / `try_spend()`; building and selling only through `TowerBuilder`; UI only displays and sends requests.
- **Freed objects:** never pass an object that may already be freed (an enemy, a target) into a typed parameter or lambda: check `is_instance_valid()` first (see `Tower._is_valid_target`). Assert messages are evaluated even when the assert passes, so don't call `get_path()` in one that can run outside the tree.
- **Run lifecycle:** `main.tscn` (`main.gd`) owns the current `Level` instance. A level emits `run_lost(reason)` (fortress destroyed, or the hero's last life lost) or `run_won` (RunCycle: last wave cleared) once, never both, and disables itself (`PROCESS_MODE_DISABLED`, which also removes its physics shapes); Main shows `GameOverScreen` / `VictoryScreen` and restarts by replacing the level with a fresh instance. Per-level run systems: `WaveSpawner` (lanes + waves), `RunCycle` (build/combat phases), `HeroLives` (lives, respawn), `RunModifiers` (the run's upgrades; systems read run stats through it via an exported `modifiers` reference). No global pause, no autoload.

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
├── systems/             # Non-visual game logic nodes: wave_spawner, economy, wave_rewards, tower_builder
├── levels/              # Maps: arena layout, lanes (Path2D), build slots
├── ui/                  # hud/, menus/, upgrade_screen/, shared widgets/
├── main/                # main.tscn — boot, scene switching
├── assets/              # Raw art/audio/fonts only (no scripts)
│   ├── sprites/  audio/  fonts/  shaders/
│   └── CREDITS.md
├── tests/               # Sandbox scenes, automated tests (automated/), runner helpers (tools/)
└── tools/art/           # Dev-only art generator (not shipped): draws assets/sprites/ + SpriteFrames
```

SpriteFrames (`*_frames.tres`) live next to the scene that uses them (e.g. `entities/hero/hero_frames.tres`); one-shot visual scenes and shared effect frames live in `entities/effects/`; UI themes in `ui/theme/`.

Rule of thumb: a scene and its script live **next to each other** in the folder of the feature they belong to.

Empty folders hold a `.gitkeep` so Git tracks them; delete it once the folder has real files.
Commit the `*.gd.uid` files Godot generates next to scripts; they keep references stable when files move.

## Pixel art

Full visual rules (palette ramps, light, sizes, animation timing, review checklist): **`ART_DIRECTION.md`**.

- **One art pixel = 2 world pixels** (`ART_SCALE` in `tools/art/sheet_layouts.gd`): every sprite node has `scale = Vector2(2, 2)`, never any other scale, rotation or skew (it would break the pixel grid). At 720p/1080p/1440p/4K this gives even 2/3/4/6 px screen pixels.
- Nearest-neighbour filtering and 2D pixel snapping are set project-wide; don't override them per node.
- Style: 16-bit dark fantasy, top-down 3/4 view, 1 px dark outline (`#1a141f`) around characters, soft oval ground shadow, light from the top-left. Muted palette (dark green grass, earthy dirt, grey stone); red is the accent (hero tabard, banner), red eyes for enemies. Characters must stay brighter / higher-contrast than the ground.
- Directional characters use `DirectionalSprite` with `<state>_<facing>` animations (`down`, `up`, `side`; side art faces right and is mirrored). Effects that must follow an aim use pre-drawn directions (e.g. 8 swing trails), not rotation.
- **UI** uses the project-wide theme (`ui/theme/game_theme.tres`, set in `gui/theme/custom`) with the generated pixel font at 24 px (2×) — only use whole multiples (24/48/72). UI textures are generated pre-scaled to 2×.
- **Visuals follow gameplay, never drive it**: sprites, effects and flashes read state or react to signals; collisions, timings and logic don't depend on them.
- **Art pipeline:** all art is original and drawn in code. To change art, edit `tools/art/generate_art.gd` (pixel grids / drawing code) and `sheet_layouts.gd` (sheet layout, animation names, fps), then run:
  `godot --headless --path . --script res://tools/art/generate_art.gd` → `godot --headless --path . --import` → `godot --headless --path . --script res://tools/art/build_sprite_frames.gd`.
  Add `-- --only=hero,ghoul` to the first command to regenerate just some sheets. Drawing code lives in one file per asset family (`hero_art.gd`, `ghoul_art.gd`, `effects_art.gd`, ...) on top of `canvas.gd` (shaded primitives, contours, outline) and `palette.gd` (colour ramps).
  Never hand-edit the generated PNGs or `*_frames.tres`. The arena ground is baked from the level's `Floor`, every `Lane*` Path2D and `Fortress`, so regenerate it after changing those.
- Visual review: `godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/tools/capture_screenshots.gd -- --out=<dir> [--scenario=tour|combat|build|gallery|review|run]` plays a scripted scene in a real window and saves screenshots (`gallery` shows every animation at game scale; `review` is the milestone review set; `run` a late wave and the Victory screen). Keep review shots in the git-ignored `dev_screenshots/`. `tools/art/preview_art.gd` saves an enlarged contact sheet of one generated PNG.
- Balance check: `godot --headless --fixed-fps 60 --path . --script res://tests/tools/balance_report.gd [-- --plan=mixed]` plays the whole run once per tower plan (idle hero) and prints each wave's kills, leaks, fortress HP and gold, then won/lost per plan.

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
| 8 | fortress_hitbox | enemy contact damage that only the fortress takes |

These names are configured in Project Settings → Layer Names → 2D Physics.

Damage wiring: a `Hitbox` sits **on** `hero_hitbox` (bit value 16), `enemy_hitbox` (32) or `fortress_hitbox` (128) with mask 0. A `Hurtbox` has layer 0 and **masks** the hitbox layer that may hurt it: enemies mask `hero_hitbox`, the hero masks `enemy_hitbox` (enemy melee), the fortress masks `fortress_hitbox` (enemies reaching it). Hurtboxes do the detecting; damage is applied once per overlap entry, so attacks enable their hitbox shape briefly per strike. A Hurtbox can add `invulnerability_time` (the hero uses 0.5 s) so several attackers can't stack hits. Anything enemies attack can also have an `AttackerLimit` child (the hero allows 2 attackers at a time); enemies claim a slot before attacking.

## Input actions

Configured: `move_up`, `move_down`, `move_left`, `move_right` (WASD as **physical** keys so AZERTY/QWERTZ work + arrows), `attack` (LMB), `interact` (E: build menu at a slot), `start_wave` (Enter / keypad Enter: ends the build phase; the HUD also has a Start wave button). Menus also use Godot's built-in `ui_*` actions (Esc closes, Enter confirms). The hero ignores `attack` while the mouse is over UI.

Planned, added by the feature that needs them: `ability_1` (Space/RMB), `build` (B), `pause` (Esc). Never check raw keycodes in code.

## Testing a feature

- Every new feature gets a sandbox scene in `tests/` (e.g. `tests/test_hero_movement.tscn`) where it can be tried by hand (F6).
- Every new feature also gets an automated test `tests/automated/test_<feature>.gd`: a script that `extends SceneTree`, drives the real scenes (e.g. `Input.action_press`), prints `[ok]`/`[FAIL]` lines and calls `quit(<number of failures>)`. Wait a frame after `add_child` before reading state set in `_ready()`. Don't rely on the order in which a signal's listeners run, and remember `queue_free()` only takes effect at the end of the frame (use `is_queued_for_deletion()` when counting nodes). A new `class_name` is only known after an import, so run a brand-new test through `tests/run_tests.sh` (which imports first). A test that fails to load or errors before `quit()` never exits on its own, so the runner gives every Godot run a time limit and reports `TIMED OUT`.
- **Run everything before calling a feature done:** `tests/run_tests.sh` (Godot binary from `$GODOT`, default `~/Downloads/Godot_v4.7.2-stable_linux.x86_64`). It runs the editor import, checks every `.gd` with **all GDScript warnings treated as errors** (via a temporary, git-ignored `override.cfg`), runs every automated test with `--fixed-fps 60` (deterministic, faster than real time), and runs `main.tscn` + every scene in `entities/`, `levels/`, `ui/` and `tests/` for 120 frames. Must end with `ALL PASSED`.
- Helpers for the runner live in `tests/tools/`. The `tests/` and `tools/` folders must be excluded from release exports (M9).
