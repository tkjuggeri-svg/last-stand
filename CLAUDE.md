# LAST STAND — Project Rules

Indie game, 2D top-down dark fantasy roguelite tower defense. We're making the best game we can first; release decisions come later (ROADMAP.md, parking lot).
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
- **Few autoloads.** Allowed: `Events` (global signal bus), `RunState` (the run that is played: its data and seed, the chapter and its node map, and what carries from one chapter's level to the next: gold, lives, upgrades, fortress HP). `SaveManager` (M8: the player's save). Later possibly `Audio`. Nothing else without asking.
  `RunState` exists since M7 (`autoload/run_state.gd`: state only, no rules), `SaveManager` since M8 (`autoload/save_manager.gd`: one versioned JSON save of the `SaveProfile`, atomic with a backup, migrated by `SaveProfile.migrate`; under `--script` it has everything unlocked and writes nothing); `Events` doesn't yet: it is created by the first feature that actually needs a cross-system signal. Never add empty placeholder signals or fields. Scripts checked or run with `--script` (the script check, tests, tools) are compiled before autoloads exist, so they can't name `RunState`: they use `get_node("/root/RunState") as RunStateNode` (Main does) or go through Main (`get_map()`, `get_level()`).
- **No logic in UI.** UI reads state and emits intents; game systems own the rules.
- **Level layout rule:** every level has a `%Floor` rect that *is* the playable arena, an `ArenaBounds` `StaticBody2D` (world layer) whose wall shapes' inner edges sit exactly on the floor edges, a `%Ground` (`TiledGround`: the baked texture drawn in tiles, so 2D lights only redraw the tiles they touch) covering the floor plus the visible 32 px wall band (`WALL_BAND`), and Camera2D limits equal to that same floor + band rect. Keep them in sync (`test_arena_bounds` checks it). The level root, the spawner and `%Effects` are y-sorted; ground layers use negative `z_index`.
- **Per-level systems:** `Economy`, `WaveRewards` and `TowerBuilder` are plain nodes under the level's `Systems` node, wired to each other and to the spawner, slots, HUD and build menu with exported node references (no autoloads). A chapter's level lives for the whole chapter, and its systems own the rules and the live values while it is played; only between chapters do those values pass through `RunState` (Main copies them out and into the next chapter's level). Systems never read `RunState` themselves. Gold only changes through `Economy.earn()` / `try_spend()`; building and selling only through `TowerBuilder`; UI only displays and sends requests.
- **Freed objects:** never pass an object that may already be freed (an enemy, a target) into a typed parameter or lambda: check `is_instance_valid()` first (see `Tower._is_valid_target`). Assert messages are evaluated even when the assert passes, so don't call `get_path()` in one that can run outside the tree.
- **Run lifecycle (run map, M7, `docs/M7_RUN_MAP.md`):** `main.tscn` (`main.gd`) runs a run: `RunState.start_run()` with `RunData` (its `ChapterData`s, `data/run/`), each chapter a seeded `RunMap` of `MapNode`s shown by `MapScreen` and played by `MapFlow` (Main's child: the node chosen becomes a fight, the shop or an event, then the map again). Main owns the chapter's `Level` instance (made when the chapter starts, kept between nodes, hidden and frozen with `set_active(false)` while the map shows). A battle, an elite or the boss is a fight on it: `Level.start_encounter(waves, FightReward)` (an `EncounterData`'s waves, an elite's `AffixData` applied), which emits `encounter_cleared` once the fight's reward (gold, repair, one upgrade choice) is taken; a merchant opens `MerchantScreen` on the level's `Merchant`. A level emits `run_lost(reason)` (fortress destroyed, or the hero's last life lost) once and disables itself (`PROCESS_MODE_DISABLED`, which also removes its physics shapes); beating the last chapter's boss calls `end_run_won()` (`run_won`). Main shows `GameOverScreen` / `VictoryScreen`, whose Continue leads to the run summary (in script mode: a fresh run at once). A level on its own (F6, most tests, the balance tool) still plays its 15 waves straight through and emits `run_won` after the last. Main also owns the pause menu (`PauseMenu`: tree paused and `Engine.time_scale` 0, so nothing moves; not during the upgrade choice, which holds its own pause, or after the run) and loads the player's settings at startup (`GameSettings`, a static class in `core/utils/`, no autoload: `user://settings.cfg`, window mode, the Master / Music / SFX buses of `default_bus_layout.tres`, key bindings). Per-level run systems: `WaveSpawner` (lanes + waves), `RunCycle` (build/combat phases), `HeroLives` (lives, respawn), `Quartermaster` (the between-waves gold sinks: fortress repairs, buying back a life), `Merchant` (the run map's shop), `RunModifiers` (the run's upgrades and relics; systems read run stats through it via an exported `modifiers` reference, and relic rules with `has_relic()`), `RelicEffects` (the relic rules that need their own logic, M7.5). A chapter's arena is `ChapterData.level_scene` (chapter 1: `prototype_arena.tscn`, chapter 2: `drowned_marsh.tscn`). No autoload.
- **Front end and meta progression (M8, `docs/M8_META.md`):** Main boots on the title (`FrontEnd`, Main's child: `TitleScreen`, the War Room `HubScreen`, `RunSummaryScreen`, a `ScreenFade`; all on the shared `ScreenFrame` widget and the theme's type variations). Every run that ends (won, lost, abandoned from the pause menu) builds a `RunSummary`, pays Soul Shards into the profile (`MetaProgress`, rules only) and is saved by the `SaveManager` autoload (`SaveProfile`, versioned, migrated on load; `tests/fixtures/` holds older saves). What a run may use comes from `data/meta/unlock_board.tres` and the profile (`RunUnlocks`, held by `RunState`, applied by `Level.apply_unlocks` and the map's event pool): unlocks add content and options, never permanent power. Each time the map shows the run is saved (`RunSave`: plain data; systems with private state have `save_state()` / `load_state()`), and the title's Continue resumes it there. `HintDirector` (Main's) shows each tutorial tip once (`HintPanel`; seen tips in the profile). **Script mode:** under `--script` (tests, tools) `SaveManager` writes nothing and unlocks everything, and Main has no front end and no tips (it starts a run at once, as before M8); a test that needs them calls `SaveManager.use_file(<a user:// test file>)` first and deletes that file at the end.

## Folder structure

```
res://
├── autoload/            # RunState, SaveManager (later Events; global singletons only)
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
- Visual review: `godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/tools/capture_screenshots.gd -- --out=<dir> [--scenario=tour|combat|build|gallery|review|run|m5|m6] [--only=dash,...]` plays a scripted scene in a real window and saves screenshots (`gallery` shows every animation at game scale; `review` is the milestone review set; `run` a late wave and the Victory screen; `m5` the upgrade choice screen, the HUD's upgrade row, a Long Reach swing, the Brazier and Ballista in a fight and the 5-tower build menu; `m6` the M6 content and the M6.5 additions (Quartermaster, evolutions), in parts picked with `--only`, see `tests/tools/m6_shots.gd`). Keep review shots in the git-ignored `dev_screenshots/`. `tests/tools/front_end_shots.gd -- --out=<dir>` (same window options) shoots the title, the War Room, a run summary and two tutorial tips on a throwaway save. `tools/art/preview_art.gd` saves an enlarged contact sheet of one generated PNG. `tests/tools/level_shot.gd -- --level=<scene> --out=<dir> [--wave=N] [--at=x,y;...]` screenshots a level (any arena) with a wave running.
- Balance check: `godot --headless --fixed-fps 60 --path . --script res://tests/tools/balance_report.gd [-- --plan=mixed] [--policy=towers] [--seed=1] [--hero=idle|bot|both] [--sweep] [--quiet] [--gold]` plays whole runs per tower plan, run-upgrade pick policy and hero (parked idle, or played by `tests/tools/hero_bot.gd`) and prints each wave's kills, leaks, fortress HP and gold, then won/lost, hero falls, the upgrades taken, the run's income and length; `--sweep` measures each upgrade on its own; `--gold` prints each run's gold ledger (`tests/tools/gold_ledger.gd`: income per wave by source, spending, the bank); `--evolve=early|late [--branch=a|b|random|only:<tower>:<a|b>]` lets the bot buy tower evolutions and counts the picks. `tests/tools/evolution_duel.gd [-- --layout=0..2]` compares the evolutions on equal terms (waves 10-15, all towers at level 3, an unbreakable fortress).
- Run map balance: `godot --headless --fixed-fps 60 --path . --script res://tests/tools/map_balance.gd [-- --seeds=1-8] [--path=fights|balanced|safe] [--plan=mixed|all five] [--hero=bot|idle] [--quiet] [--protect-ch1] [--trace]` plays whole map runs through `main.tscn` with a bot player (path policy, tower plan per level with late evolutions, rewards, relics by a fixed preference, merchants, events, the Quartermaster) and prints where each run ended (won, or the chapter and row it fell in), its fights, waves, upgrades, evolutions, income per chapter, length and relics, then how often each relic was offered and taken. `--protect-ch1` keeps chapter 1's fortress and lives full so chapter 2 is measured with a real chapter-1 build; `--trace` prints every chapter-2 wave's gold, towers and fortress HP. Plans: `mixed`, `all five`, `all <tower id>` (single-tower spam on every slot) and `braziers first`; `--fire=with|without` grants the fire cards and relic at the start or keeps them out of every offer. The summary ends with the rows cleared per run. `balance_report.gd` still tunes the standalone 15-wave run.
- Waves: `data/waves/wave_NN.tres` (chapter 1) and `data/waves/chapter_2/wave_NN.tres` are written by `tools/make_waves.py` (dev only: the tables of spawn groups, the HP curves, the gold scale per wave). Edit the table and rerun `python3 tools/make_waves.py` rather than the `.tres` files, so they stay consistent.
- Performance check: `godot --path . --resolution 1280x720 --script res://tests/tools/perf_report.gd [-- --seconds=60] [--no-towers] [--empty] [--chapter-2] [--evolved]` plays the last wave (chapter 1's, or chapter 2's with `--chapter-2`; every tower evolved with `--evolved`) in a real window with vsync off and prints FPS (average, 1% low) and frame times. Keep huge items (ground, full-screen rects) out of 2D lights' reach: in the Compatibility renderer each light redraws every item it touches.

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

Configured: `move_up`, `move_down`, `move_left`, `move_right` (WASD as **physical** keys so AZERTY/QWERTZ work + arrows), `attack` (LMB), `interact` (E: build menu at a slot), `start_wave` (Enter / keypad Enter: ends the build phase, or in a run map fight calls the next wave early once the running one has sent everyone; the HUD's wave button does the same), `dash` (Space / Shift, physical), `pause` (Esc: the pause menu), `feedback` (F8: the in-game feedback box, rebindable), `dev_menu` (F12: the dev menu, debug builds only, not rebindable). Menus also use Godot's built-in `ui_*` actions (Esc closes, Enter confirms); `ui_accept` is overridden to Enter / keypad Enter only, because Space is the dash. The hero ignores `attack` while the mouse is over UI.

Planned, added by the feature that needs them: `build` (B). Never check raw keycodes in code (the settings' rebinding screen is the one place that reads raw key events, to bind them). Every action the player can rebind is listed in `GameSettings.ACTIONS`; add new player actions there too.

## Testing a feature

- Every new feature gets a sandbox scene in `tests/` (e.g. `tests/test_hero_movement.tscn`) where it can be tried by hand (F6).
- Every new feature also gets an automated test `tests/automated/test_<feature>.gd`: a script that `extends SceneTree`, drives the real scenes (e.g. `Input.action_press`), prints `[ok]`/`[FAIL]` lines and calls `quit(<number of failures>)`. Wait a frame after `add_child` before reading state set in `_ready()`. Don't rely on the order in which a signal's listeners run, and remember `queue_free()` only takes effect at the end of the frame (use `is_queued_for_deletion()` when counting nodes). A new `class_name` is only known after an import, so run a brand-new test through `tests/run_tests.sh` (which imports first). A test that fails to load or errors before `quit()` never exits on its own, so the runner gives every Godot run a time limit and reports `TIMED OUT`.
- **Run everything before calling a feature done:** `tests/run_tests.sh` (Godot binary from `$GODOT`, default `~/Downloads/Godot_v4.7.2-stable_linux.x86_64`). It runs the editor import, checks every `.gd` with **all GDScript warnings treated as errors** (via a temporary, git-ignored `override.cfg`), runs every automated test with `--fixed-fps 60` (deterministic, faster than real time), runs `main.tscn` + every scene in `entities/`, `levels/`, `ui/` and `tests/` for 120 frames, and runs shellcheck on every tracked `.sh` (when installed: `python3 -m venv ~/.cache/devtools-venv && ~/.cache/devtools-venv/bin/pip install shellcheck-py`). Must end with `ALL PASSED`.
- Helpers for the runner live in `tests/tools/`. The `tests/` and `tools/` folders are excluded from exports (`export_presets.cfg`).

## Git and GitHub

The remote `origin` is the private GitHub repo `tkjuggeri-svg/last-stand` (SSH). **Push after every
milestone and every playtest build:** `git push origin main` and `git push origin --tags` (the
milestone's and the build's tags included). Never force-push and never rewrite pushed history.

## Feedback, seeds and the dev menu

- **Feedback key** (F8): `FeedbackScreen` (UI) → Main saves a report with `FeedbackRecorder` in
  `user://feedback/<date_time>/`: `note.txt`, `screenshot.png`, `state.json` (`RunSnapshot`: build, seed,
  chapter, node, wave, gold, fortress, lives, towers, cards, relics). It ships in playtest builds.
  Summarize reports with `python3 tools/feedback_summary.py <folders>` (skill `feedback-review`).
- **Seeds:** every run has one (`RunState.seed_value`), shown in the pause menu and on Game Over /
  Victory; the pause menu starts a run from a typed seed; `godot --path . -- --seed=<n>` too.
- **Dev menu** (F12, `tools/dev/dev_menu.tscn`): jump to a chapter / map node / wave, set gold, grant any
  card or relic, spawn any enemy, hero / fortress invulnerability, the seed. Main loads it only in debug
  builds and only if the file exists; `tools/` is excluded from every export, so it never ships. Its
  hooks in the game: `Main.jump_to_node()` / `jump_to_chapter()`, `WaveSpawner.end_wave()` /
  `spawn_extra()`, `HealthComponent.invulnerable`.

## Playtest builds

`tools/build_playtest.sh` runs the suite, exports the Linux and Windows presets (`export_presets.cfg`, x86_64, release) and zips them with `PLAYTEST.md` into the git-ignored `builds/`. It needs the Godot 4.7.2 export templates; `--pack-check` checks the exported game data without them (no tests/ or tools/ inside, runs on its own). Tester instructions and the feedback we ask for: `PLAYTEST.md`.
