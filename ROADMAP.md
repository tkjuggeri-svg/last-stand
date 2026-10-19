# LAST STAND — Roadmap

Each milestone ends with something **playable**. Don't start the next milestone until the current one's "Done when" is met.
Tick items as they're finished.

---

## M0 — Foundation *(no gameplay)*
- [x] Project docs: `CLAUDE.md`, `GAME_DESIGN.md`, `ROADMAP.md`
- [x] `git init` (branch `main`)
- [x] First commit
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
- [x] Playtest fix (after M2): Ghouls attack the hero (wind-up, cooldown, hero invulnerability window); hero death → Game Over

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
- [x] Gold economy: `Economy` (never negative), kill gold from `EnemyData`, HUD gold counter
- [x] Perfect-defense bonus (+10% of a wave's kill gold if nothing reached the fortress), via `WaveRewards`
- [x] `TowerData` resource + one shared `Tower` scene
- [x] 6 fixed build slots; E at a slot opens the build menu (build any time, game never pauses)
- [x] Archer (single target), Cannon (splash), Frost (slow) towers: "first along path" targeting, homing projectiles
- [x] Sell tower for 50% of its build price (no double refunds)
- [x] HUD: gold, free slots, build menu with prices/descriptions, insufficient-gold and refund feedback
- [x] Tests: economy, construction, tower combat; balance report tool

**Done when:** the hero + towers together are needed to hold a lane.

---

## M3.5 — Complete Visual Overhaul
- [x] `ART_DIRECTION.md`: resolution, palette ramps, light, outlines, materials, proportions, animation timing, review checklist
- [x] Art toolkit: `canvas.gd` (lit primitives, contours, outline), `palette.gd`, one generator file per asset family, preview + gallery tools
- [x] Hero and Ghoul redrawn at higher detail; idle/walk/attack/death animations; new swing, hit spark, dust
- [x] 3/4-view fortress with 4 damage states, fires, smoke, banners, braziers, hit shake
- [x] Archer, Cannon and Frost towers redesigned with idle and attack animations; new projectiles, explosion, frost effects
- [x] Construction (scaffolding) and dismantling (rubble) animations; a tower under construction (`TowerData.build_time`, 0.6 s) can't fire, a sold tower stops at once
- [x] Environment: richer ground, graveyard props and crypt, 3/4 arena wall; dusk lighting, fog, fireflies, vignette
- [x] HUD and build menu: original pixel font, pixel frames, icons

**Done when:** the game looks like a cohesive commercial pixel-art game at 1280×720, with every test passing and gameplay unchanged.

---

## M4 — Waves & Run Structure
- [x] `WaveData` + `SpawnGroup` resources; `WaveSpawner` driven by data (replaces the continuous spawner), wired to `WaveRewards`
- [x] 3 lanes (west crypt road, north-east road, south road) with their crypts and 10 build slots; waves pick a lane per spawn group
- [x] Build phase ↔ combat phase cycle (`RunCycle`), "Start wave" button + Enter, HUD wave/phase/enemies left
- [x] Enemy roster: Ghoul, Hound (fast, fragile), Brute (slow, tanky) with full art and animations; one data-driven enemy scene
- [x] Hero death + respawn: 3 lives per run, 4 s respawn at the fortress with countdown, 2 s blinking invulnerability; the last life lost (or the fortress) ends the run
- [x] Victory after final wave (Victory screen, Play again); 10 hand-authored waves with a rising curve; full-run balance report

**Done when:** a full run can be won or lost.

---

## M5 — Roguelite Upgrades
- [x] `UpgradeData` + stat modifier system (`RunModifiers`, per level)
- [x] Upgrade choice screen (1 of 3) after each wave: paused, keyboard + mouse, seeded, one reroll per offer
- [x] 20 upgrades across Hero / Tower / Fortress / Economy, with trade-offs and icons
- [x] Tower upgrades (2 tiers per tower) — pulled forward into M4 after the playtest
- [x] Towers: Brazier (burning ground), Bone Ballista (piercing line shots), both with 2 upgrade tiers. ~~Frost Obelisk~~ dropped: it overlaps the Frost tower

- [x] Balance with run upgrades (bot pick policies, per-upgrade sweep, wave HP multipliers) and a wave-10 performance pass (2D light fix: 163 → 457 fps)

**Done when:** two runs feel meaningfully different because of choices made.

---

## M6 — Content & Challenge
- [x] Cultist (ranged) enemy: sieges the fortress from 170 px, turns on a nearby hero, telegraphed straight shots
- [x] Bosses (5/10/15): Gravelord (summons Ghouls), Bone Colossus (charges the hero), Lich Warden (wards nearby enemies); telegraphs, boss HP bar, big deaths
- [x] Hero ability: Dash (Space/Shift, 2 s cooldown on the HUD, immune while dashing, through enemies but not walls) + 2 dash upgrades (Fleet Step, Cinder Dash)
- [x] 15-wave run (bosses at 5/10/15, Cultists from wave 4), difficulty tuning with a hero bot in the balance tool (idle hero never wins; a bot hero with a sensible build sometimes does); hero healed between waves
- [x] Pause menu (truly frozen), settings (fullscreen, Master/Music/SFX volume with the audio buses, rebinding every action), saved to user:// and loaded at startup

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
- [ ] Art pass for whatever M5–M7 add (new towers, Cultist, bosses, upgrade/meta UI) in the M3.5 style — the M2–M4 content (towers, Hound, Brute, UI frames) already has final-style art
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
**M6 in progress** (phases A–F: dash, Cultist, bosses, 15 waves + hero bot balance, pause/settings, playtest build).
