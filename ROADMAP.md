# LAST STAND — Roadmap

Each milestone ends with something **playable**. Don't start the next milestone until the current one's "Done when" is met.
Tick items as they're finished.

---

## M0 — Foundation *(no gameplay)*
- [x] Project docs: `CLAUDE.md`, `GAME_DESIGN.md`, `ROADMAP.md`
- [x] `git init` (branch `main`)
- [ ] First commit
- [x] Create folder structure (from `CLAUDE.md`)
- [x] Project settings: Compatibility renderer, 1280×720, 2D gravity 0, physics layer names, input actions, main scene, `untyped_declaration` warning
- [x] Empty `main.tscn` set as main scene
- ~~Autoloads `Events`, `RunState`~~ → deferred to M1, created when first needed

**Done when:** the project opens and runs to an empty main scene with no errors or warnings.

---

## M1 — Core Combat Prototype *(first playable)*
- [x] Hero: movement (WASD), camera follow
- [x] `HealthComponent`, `Hurtbox`, `Hitbox`
- [x] Hero melee attack (mouse-aimed arc)
- [x] Fortress with HP
- [x] One lane (`Path2D`) + one enemy type (Ghoul) that walks to the fortress and damages it
- [x] Simple spawner: N enemies at an interval
- [x] Minimal HUD: fortress HP, hero HP
- [x] Lose condition (fortress HP 0 → game over screen → restart)

**Done when:** you can fight a stream of enemies and lose if they reach the fortress too often.

---

## M2 — Visual Identity: Retro 16-bit Pixel Art
- [x] Pixel-art pipeline: original art drawn in code (`tools/art/`), 1 art px = 2 world px, nearest filtering, pixel snapping
- [x] Hero knight: idle / walk / attack in 4 directions (side mirrored), visible sword
- [x] Ghoul: idle / walk in 4 directions, death animation, white hit flash + hit spark
- [x] Fortress: top-down keep with 4 looks (healthy, damaged, badly damaged, destroyed)
- [x] Arena: baked ground (dark grass, dirt lane from the level's Path2D, stones, dead grass, debris, graveyard spawn), visible stone wall band
- [x] Effects: 8-direction sword swing trail, hit spark, death collapse + dust
- [x] HUD readability: outlined text, framed bars
- [x] Automated visual test + screenshot capture tool

**Done when:** the prototype looks like a coherent 16-bit dark fantasy game, with every gameplay test still passing.

---

## M3 — Tower Defense Layer
- [ ] `TowerData` resource + base `Tower` scene
- [ ] Build slots in the level; click to build
- [ ] Arrow Tower (targeting "first along path", projectiles)
- [ ] Gold: earned on kill, spent on towers; HUD gold counter
- [ ] Sell tower

**Done when:** the hero + towers together are needed to hold a lane.

---

## M4 — Waves & Run Structure
- [ ] `WaveData` resource (`EnemyData` already exists since M1)
- [ ] `WaveSpawner` driven by data; 2–3 lanes
- [ ] Build phase ↔ combat phase cycle, "Start wave" button
- [ ] Enemy roster: Ghoul, Hound, Brute
- [ ] Hero death + respawn
- [ ] Victory after final wave; 10 hand-authored waves

**Done when:** a full run can be won or lost.

---

## M5 — Roguelite Upgrades
- [ ] `UpgradeData` + stat modifier system
- [ ] Upgrade choice screen (1 of 3) after each wave
- [ ] ~15 upgrades across Hero / Tower / Fortress / Economy
- [ ] Tower upgrades (2 tiers per tower)
- [ ] Towers: Brazier, Frost Obelisk, Bone Ballista

**Done when:** two runs feel meaningfully different because of choices made.

---

## M6 — Content & Challenge
- [ ] Cultist (ranged) enemy, boss waves (5/10/15)
- [ ] Hero ability (dash or slam)
- [ ] 15-wave run, difficulty tuning pass
- [ ] Pause menu, settings (volume, fullscreen, keybinds)

**Done when:** a 20–30 min run is fun from start to finish. → **Internal playtest build.**

---

## M7 — Meta Progression & Persistence
- [ ] Soul Shards, run summary screen
- [ ] Meta hub: unlocks for towers/upgrades/hero bonuses
- [ ] `SaveManager` (`user://` save, versioned)
- [ ] Second hero (optional)

**Done when:** there's a reason to start another run after dying.

---

## M8 — Audio, Feel & Presentation
- [ ] Art for everything added since M2 (towers, new enemies, UI frames) in the M2 style
- [ ] SFX + music
- [ ] Juice: screen shake, damage numbers, particles (hit flash done in M2)
- [ ] Main menu, title, credits

**Done when:** a stranger can watch a 30 s clip and understand + want the game. → **Steam page / trailer / demo.**

---

## M9 — Steam Release Prep
- [ ] Windows export preset, build pipeline
- [ ] Steam integration (achievements, cloud saves) — decide approach (GodotSteam is an external dependency → needs explicit approval)
- [ ] Controller support
- [ ] Performance pass (many enemies/projectiles on screen)
- [ ] Bug bash, Early Access / 1.0 decision

---

## Current focus
**M2 complete** (retro pixel-art visuals). Awaiting visual feedback before M3 (towers).
