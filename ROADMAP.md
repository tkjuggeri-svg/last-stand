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

- [x] Internal playtest build: Linux + Windows export presets, `tools/build_playtest.sh`, `PLAYTEST.md`

**Done when:** a 20–30 min run is fun from start to finish. → **Internal playtest build.**

---

## M6.5 — Economy, Difficulty & Tower Evolutions *(depth before release)* — done (`m6.5-done`)
The Steam release is postponed to focus on depth and replayability (M7–M12); release prep moves to M14.

- [x] Gold breakdown in the balance tool (`--gold`); snowballing removed (Bounty Hunters once per run)
- [x] Scarce gold: kill gold per wave stays flat from wave 6 (`WaveData.gold_multiplier`); maxing every tower by wave 15 is out of reach without economy upgrades
- [x] Gold sinks between waves (`Quartermaster`): fortress repairs (rising price), buy back a lost life (once per run)
- [x] Difficulty for a good player: waves 10–15 press every lane at once, Cultist groups on several lanes, faster regulars (`WaveData.speed_multiplier`), harder bosses; the bot hero is the floor (idle never wins, the bot rarely). Playtest build `m6-playtest-2`
- [x] Hands-on playtest (`m6-playtest-4`, with the see-through HUD panels): the difficulty is right for a first chapter, and is now the baseline later chapters ramp up from (`GAME_DESIGN.md` 3.)
- [x] Tower evolutions: two permanent level-4 branches per tower (10 mechanics, art, side-by-side choice with range rings), tuned with `evolution_duel.gd` and the balance bot. Playtest build `m6-playtest-3`

**Done when:** a good player wins narrowly, gold is a real choice every wave, and towers grow in ways that change how a run plays.

---

## M7 — Run Map
A Slay the Spire–style node map per run, instead of one fixed sequence of waves. Design and decisions: `docs/M7_RUN_MAP.md`.
- [x] Design: map shape, node types and odds, waves per row, carry-over, the ramp per chapter, 5 events and 5 shrines, open questions (approved with the user's answers)
- [x] `RunState` autoload, `RunData` / `ChapterData` / `EncounterData` / `AffixData`, seeded `RunMap` (8 rows, rules) and `MapScreen` (node icons, path, choices)
- [x] Node types: battle (2 waves, one upgrade choice after), elite (mini-boss + twist; 2 rare cards + 100 gold), merchant (cards, repair, reroll), event and shrine (5 + 5, `EventResolver`), boss
- [x] Carry-over: towers, gold and damage stay within a chapter; between chapters towers are packed up for a full refund, gold, upgrades and lives carry, the fortress +50%
- [x] Two chapters (the count is data): chapter 2 ramps up from chapter 1 with its own boss, the Tollkeeper (its toll silences towers)
- [x] Run flow: Main owns the map ↔ level switching; Restart / Game Over / Victory work across the whole run (no checkpoints)
- [ ] Optional small early SFX pass (not done; still possible in M8)
- [x] Tests (map rules, flow, rewards, merchant, events, chapters, the toll) and `tests/tools/map_balance.gd` (bot runs through the map); playtest build `m7-playtest`
- [x] Hands-on playtest of `m7-playtest` (feedback → M7.5)

**Done when:** two runs take visibly different paths through the map, and the path chosen changes how the run goes.

---

## M7.5 — Chapter 2 rework & Relics *(from the M7 playtest)*
Playtest of `m7-playtest`: chapter 1 is fine; chapter 2 on the same map, with a full tower refund and only more HP, was easy mode; elites felt worthless. Relics are pulled forward from M9 and chapter 2's map from M10.
- [x] Phase A: towers refund 40% between chapters (`ChapterData.leave_refund`); `map_balance.gd --protect-ch1`
- [ ] Phase B: chapter 2's own map, the Drowned Marsh (bigger, roads winding around water and merging before the fortress, 7 spread-out slots, wading hero, its own ground, props, light); the chapter data picks the arena; chapter 2 retuned for the 40% refund
- [ ] Phase C: chapter 2 enemies, introduced gradually: Bloater (splits into 3 Bloatlings), Mire Priest (telegraphed heal pulse), Shieldbearer (blocks tower shots from the front)
- [ ] Phase D: relics (pulled from M9): ~15 rule-changing relics, one of each per run, their own HUD row with tooltips; from elites (1 of 3), bosses, merchants (rare, expensive) and rare events; elites harder and clearly better rewarded
- [ ] Phase E: balance (chapter 2 clearly harder than chapter 1; the bot rarely clears it, idle never), relic pick rates, docs; playtest build `m7.5-playtest`

**Done when:** chapter 2 plays differently from chapter 1 (map, enemies), a run's relics change how it plays, and elites are worth the risk.

---

## M8 — Meta Progression & Persistence
- [ ] Soul Shards earned at run end (waves / nodes cleared, bosses killed), run summary screen
- [ ] Hub between runs: spend Soul Shards on unlocks (towers, upgrades into the pool, hero bonuses)
- [ ] `SaveManager` (autoload, already allowed in `CLAUDE.md`): versioned save in `user://`, profile with unlocks and shards; survives a crash mid-run (decide: resume runs or not)
- [ ] Unlock pacing: what is available on the first run, what comes later
- [ ] Main flow: start → hub → run → summary → hub
- [ ] First-time tutorial hints: short on-screen prompts, each shown once (build at a slot, start a wave, dash, the upgrade choice, evolutions), skippable (one hint or all), remembered in the save (here, because it needs `SaveManager`)
- [ ] Optional small early SFX pass (if not done in M7)
- [ ] Tests: save/load round trip, version migration, unlocks applied to a run

**Done when:** there's a reason to start another run after dying.

---

## M9 — Heroes & Relics
2–3 heroes with distinct playstyles (e.g. the knight, a ranged hero, a summoner) and relics: rare items that change the rules of a run rather than add stats. (Relics were pulled forward into M7.5; M9 adds more of them and hero-specific ones.)

**Done when:** picking a different hero or finding a key relic changes how you play the run.

---

## M10 — Maps & Biomes
2–3 new maps with their own lane layouts, enemies and bosses, in their own visual biome. (Chapter 2's map, the Drowned Marsh, and its enemies were pulled forward into M7.5.)

**Done when:** each map asks for a different defence plan.

---

## M11 — World & Story
Lore, characters, event texts for the run map, and an ending.

**Done when:** a player knows why they fight and gets an ending for winning.

---

## M12 — Longevity
Endless mode and unlockable difficulty levels (ascension-style modifiers).

**Done when:** a player who has won keeps finding a harder reason to play.

---

## M13 — Audio & Presentation
SFX and music, juice (screen shake, particles, hit feedback), main menu, title and credits, and an art pass over everything added since M6 in the `ART_DIRECTION.md` style. A small early SFX pass can come in M7–M8.

**Done when:** a stranger can watch a 30 s clip and understand + want the game. → **Steam page / trailer / demo.**

---

## M14 — Steam Release Prep
Release build pipeline (signing, store builds; the playtest presets and script exist since M6), Steam integration (achievements, cloud saves; GodotSteam is an external dependency and needs explicit approval), controller support, a performance pass, a bug bash and the Early Access / 1.0 decision.

**Done when:** the game is on Steam.

---

## Current focus
**M7.5** (chapter 2 rework and relics, from the `m7-playtest` feedback), built in phases A–E. Don't start M8 yet.
