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
- [ ] Hero: movement (WASD), camera follow
- [ ] `HealthComponent`, `Hurtbox`, `Hitbox`
- [ ] Hero melee attack (mouse-aimed arc)
- [ ] Fortress with HP
- [ ] One lane (`Path2D`) + one enemy type (Ghoul) that walks to the fortress and damages it
- [ ] Simple spawner: N enemies at an interval
- [ ] Minimal HUD: fortress HP, hero HP
- [ ] Lose condition (fortress HP 0 → game over screen → restart)

**Done when:** you can fight a stream of enemies and lose if they reach the fortress too often.

---

## M2 — Tower Defense Layer
- [ ] `TowerData` resource + base `Tower` scene
- [ ] Build slots in the level; click to build
- [ ] Arrow Tower (targeting "first along path", projectiles)
- [ ] Gold: earned on kill, spent on towers; HUD gold counter
- [ ] Sell tower

**Done when:** the hero + towers together are needed to hold a lane.

---

## M3 — Waves & Run Structure
- [ ] `EnemyData` / `WaveData` resources
- [ ] `WaveSpawner` driven by data; 2–3 lanes
- [ ] Build phase ↔ combat phase cycle, "Start wave" button
- [ ] Enemy roster: Ghoul, Hound, Brute
- [ ] Hero death + respawn
- [ ] Victory after final wave; 10 hand-authored waves

**Done when:** a full run can be won or lost.

---

## M4 — Roguelite Upgrades
- [ ] `UpgradeData` + stat modifier system
- [ ] Upgrade choice screen (1 of 3) after each wave
- [ ] ~15 upgrades across Hero / Tower / Fortress / Economy
- [ ] Tower upgrades (2 tiers per tower)
- [ ] Towers: Brazier, Frost Obelisk, Bone Ballista

**Done when:** two runs feel meaningfully different because of choices made.

---

## M5 — Content & Challenge
- [ ] Cultist (ranged) enemy, boss waves (5/10/15)
- [ ] Hero ability (dash or slam)
- [ ] 15-wave run, difficulty tuning pass
- [ ] Pause menu, settings (volume, fullscreen, keybinds)

**Done when:** a 20–30 min run is fun from start to finish. → **Internal playtest build.**

---

## M6 — Meta Progression & Persistence
- [ ] Soul Shards, run summary screen
- [ ] Meta hub: unlocks for towers/upgrades/hero bonuses
- [ ] `SaveManager` (`user://` save, versioned)
- [ ] Second hero (optional)

**Done when:** there's a reason to start another run after dying.

---

## M7 — Art, Audio & Feel
- [ ] Final art direction + sprites/animations (CC0 or self-made)
- [ ] SFX + music
- [ ] Juice: hit flash, screen shake, damage numbers, particles
- [ ] Main menu, title, credits

**Done when:** a stranger can watch a 30 s clip and understand + want the game. → **Steam page / trailer / demo.**

---

## M8 — Steam Release Prep
- [ ] Windows export preset, build pipeline
- [ ] Steam integration (achievements, cloud saves) — decide approach (GodotSteam is an external dependency → needs explicit approval)
- [ ] Controller support
- [ ] Performance pass (many enemies/projectiles on screen)
- [ ] Bug bash, Early Access / 1.0 decision

---

## Current focus
**M0 done (pending first commit).** Awaiting approval before starting M1.
