# LAST STAND — Roadmap

Each milestone ends with something **playable**. Don't start the next milestone until the current one's "Done when" is met.
Tick items as they're finished. M0-M13 are built; M14-M16 are planned and not started.

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
Release plans were set aside to focus on depth and replayability (M7–M12); release decisions come later (see the parking lot at the end).

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
- [ ] Optional small early SFX pass (not done; moved to M8.5)
- [x] Tests (map rules, flow, rewards, merchant, events, chapters, the toll) and `tests/tools/map_balance.gd` (bot runs through the map); playtest build `m7-playtest`
- [x] Hands-on playtest of `m7-playtest` (feedback → M7.5)

**Done when:** two runs take visibly different paths through the map, and the path chosen changes how the run goes.

---

## M7.5 — Chapter 2 rework & Relics *(from the M7 playtest)*
Playtest of `m7-playtest`: chapter 1 is fine; chapter 2 on the same map, with a full tower refund and only more HP, was easy mode; elites felt worthless. Relics are pulled forward from M9 and chapter 2's map from M10.
- [x] Phase A: towers refund 40% between chapters (`ChapterData.leave_refund`); `map_balance.gd --protect-ch1`
- [x] Phase B: chapter 2's own map, the Drowned Marsh (bigger, roads winding around water and merging before the fortress, 7 spread-out slots, wading hero, its own ground, props, light); the chapter data picks the arena; chapter 2 retuned for the 40% refund
- [x] Phase C: chapter 2 enemies, introduced gradually: Bloater (splits into 3 Bloatlings), Mire Priest (telegraphed heal pulse), Shieldbearer (blocks tower shots from the front)
- [x] Phase D: relics (pulled from M9): ~15 rule-changing relics, one of each per run, their own HUD row with tooltips; from elites (1 of 3), bosses, merchants (rare, expensive) and rare events; elites harder and clearly better rewarded
- [x] Phase E: balance (chapter 2 clearly harder than chapter 1; idle never clears it, and neither does the bot, as in M7), relic pick rates, docs; playtest build `m7.5-playtest`
- [x] Playtest tools: in-game feedback key (F8: note, screenshot, run state in `user://feedback/`; `tools/feedback_summary.py`), run seeds shown and replayable, dev menu (F12, debug builds only); playtest build `m7.5-playtest-3`
- [ ] Hands-on playtest of `m7.5-playtest`

**Done when:** chapter 2 plays differently from chapter 1 (map, enemies), a run's relics change how it plays, and elites are worth the risk.

---

## M8 — Meta Progression & Persistence
Design: `docs/M8_META.md` (approved with Claude's recommendations; every decision in its section 10, to be overridden after playtesting).
- [x] *(Done as: the `start_wave` key and the wave button, in run map fights, once the wave has sent everyone; bonus 50% of the living enemies' kill gold, the perfect-defense bonus forfeited.)* **Call the next wave early:** a button (and key) in the build phase, or during a wave once its last group has spawned, that starts the next wave now for bonus gold (more the earlier it is called), like a classic tower defense "send next wave"
- [x] Soul Shards earned at run end (waves / nodes cleared, bosses killed), run summary screen
- [x] Hub between runs: spend Soul Shards on unlocks (towers, cards and relics into the pools, evolutions, an event, two small perks; no hero stat bonuses: the user's rule)
- [x] `SaveManager` (autoload, already allowed in `CLAUDE.md`): versioned save in `user://`, profile with unlocks and shards; survives a crash mid-run (decided: runs resume from the map)
- [x] Unlock pacing: what is available on the first run, what comes later
- [x] Main flow: start → hub → run → summary → hub, with a main menu
- [x] **Shared UI style**, built alongside the main menu, the hub and the run summary: buttons, panels, fonts, screen transitions (on top of `ui/theme/game_theme.tres`). Every later screen reuses it instead of styling itself
- [x] First-time tutorial hints: short on-screen prompts, each shown once (build at a slot, start a wave, dash, the upgrade choice, evolutions), skippable (one hint or all), remembered in the save (here, because it needs `SaveManager`)
- [x] *(One figure, the Quartermaster, lines chosen in code by `HubLines`; data-driven lines and more figures move to M11.)* **Hub characters react to the last run:** a few figures in the hub (e.g. the Quartermaster, a priest, a smith) each say a short line about how the last run went (how far, which boss, a lost life, a relic found, a first win); lines are data (conditions + text), so M11 can grow them into real characters
- [x] Tests: save/load round trip, version migration, unlocks applied to a run
- [x] *(Added after `m8-playtest`, at the user's request.)* **Tower pair bonuses:** each tower type has a partner; built close together (280 px) the tower gets a small bonus (`TowerSynergy`, GAME_DESIGN 4.4)

**Done when:** there's a reason to start another run after dying.

Built as `m8-playtest`, then `m8-playtest-2` with the tower pair bonuses (neither playtested yet).

---

## M8.5 — Demo Polish
Presentation work done early instead of all in M13, so a public demo looks and sounds finished.
- [x] UI consistency pass across every screen (HUD, build menu, choice screens, map, merchant, events, pause, settings, game over, victory) with M8's shared UI style
- [x] Basic sound effects (47, synthesized in code: `tools/audio/`; bosses, the map and the run's moments too): combat (sword, hits, the hero hurt), towers (each tower's shot, impacts, building, upgrades), deaths, UI (clicks, the choice screens, gold), on the Master / SFX buses
- [x] Juice: hit pause on big hits, damage numbers, screen shake (with a Full / Reduced / Off setting), the sword's knockback (today only a boss's death has a hit-stop and a shake)
- [x] Title screen (key art drawn in code: `tools/art/title_art.gd`)
- [x] *(Roles: grunt, fast, tank, ranged, support, splitter, boss; eyes, health bars, feed and banners; the Shieldbearer brightened to pass.)* **Readability:** a grayscale check in the screenshot tool (`capture_screenshots.gd --grayscale`: every enemy, the hero, towers and shots still stand out from the ground without colour), and **consistent colour coding by enemy role** (e.g. one accent per role: melee, fast, tank, caster/support, ranged, boss), applied to the existing enemies' art and documented in `ART_DIRECTION.md`
- [ ] *(Optional)* a free itch.io demo **for outside feedback** (players who aren't us)

**Done when:** the game looks, sounds and reads finished enough to show to people outside the project.

Built as `m8.5-playtest` (not yet playtested). The optional itch.io demo is left for the user to decide.

---

## M9 — Heroes & Relics
Design: `docs/M9_HEROES.md` (approved; built in four stages, see its section 10).
2–3 heroes with distinct playstyles (e.g. the knight, a ranged hero, a summoner) and relics: rare items that change the rules of a run rather than add stats. (Relics were pulled forward into M7.5; M9 adds more of them and hero-specific ones.)
- [x] **Each hero has their own towers.** The Archer and the Cannon stay shared by every hero; each hero also has 2–3 **exclusive towers** that fit their playstyle. The Knight (today's hero) keeps the **Brazier**, the **Frost** tower and the **Bone Ballista**. Examples for new heroes (not final):
  - **Hunter** (a ranged hero): **Trap Layer** (traps on the road), **Hawk Perch**.
  - **Necromancer** (a summoner): **Bone Pit**, **Soul Siphon**.
  The build menu shows only the shared towers and the hero's own; balance (`map_balance.gd`) per hero.
- [x] **Hero-exclusive upgrade cards** (and relics) beside the shared pool: each hero's offers draw from the shared cards plus their own.
- [x] Hero choice at the start of a run (later tied to M8's unlocks).
- [x] **Intentional build archetypes:** fire, frost, hero (sword-led), economy, ... Cards, relics and towers are tagged by archetype, and the offers lean slightly toward an archetype the run has started on, so a run can commit to a plan instead of collecting random parts
- [x] **Combo evolutions:** a special evolution a tower only gets with a specific relic (e.g. a Brazier evolution with Ember Heart, a Frost one with Hourglass), shown on the evolution choice next to the two usual branches

**Done when:** picking a different hero or finding a key relic changes how you play the run.

---

## M10 — Maps & Biomes
Design: `docs/M10_BIOMES.md` (approved on the recommendations; built: 9 biomes, see its "as built" sections).
Art resolution decided (`docs/M10_ART_RESOLUTION.md` section 7): every biome is drawn at double resolution (1 art px = 1 world px), like the world since the art pack.
At least **9 biomes in 3 tiers of 3**: tier 1 for chapter 1 (easy), tier 2 for chapter 2 (medium), tier 3 for a new chapter 3 (hard). Each run picks one biome per tier: at random, or the player chooses between two roads at the end of a chapter. The Graveyard is tier 1 and the Drowned Marsh tier 2 (pulled forward into M7.5).
Every biome has:
- its own map and lane layout;
- an **environmental mechanic** (the Marsh's: pools the hero wades through; the Graveyard still needs one);
- **1–2 unique enemies** (the others may be shared within the tier, like the Marsh's Bloater, Mire Priest and Shieldbearer);
- **its own boss**.

Built in stages:
- [x] **Stage 1: the tier system and a third chapter.** Chapters draw their biome from a tier (`RunData` / `ChapterData`); the choice of road at a chapter's end; chapter 3 (tier 3) with its first biome, its enemies and boss, and its difficulty ramp; the Graveyard gets its environmental mechanic.
- [x] **Stage 2: a second biome per tier** (3 new biomes).
- [x] **Stage 3: the third biome per tier** (3 new biomes): 9 in all.

**Done when:** each map asks for a different defence plan, and two runs can cross different biomes.

---

## M11 — World & Story
Design: `docs/M11_STORY.md` (approved on the recommendations; built: stages 1-4, see its "As built"; hero stories in the hero panel still open).
Lore, characters, event texts for the run map, and an ending. The hub's characters (M8) become real characters with their own stories, still reacting to how each run went.

**Done when:** a player knows why they fight and gets an ending for winning.

---

## M12 — Longevity
Design: `docs/M12_LONGEVITY.md` (built: Pressure and Endless, see its "As built").
Endless mode and **selectable challenge modifiers** (Hades' Heat style) instead of plain difficulty levels: before a run the player turns on any mix of modifiers (e.g. tougher elites, no repairs, faster enemies, fewer slots, a stronger boss), each worth points; higher totals unlock rewards and records.

**Done when:** a player who has won keeps finding a harder reason to play.

---

## M13 — Audio & Presentation
Design: `docs/M13_PRESENTATION.md` (built except the art pass: music, credits, trailer capture, per-biome performance, the soak; see its "As built").
Music, credits, final art polish (e.g. side views for the bosses, an art pass over everything added since M6 in the `ART_DIRECTION.md` style), trailer material, a performance pass and a bug bash. The shared UI style (M8), basic SFX, juice and the title screen come earlier (M8.5).

**Done when:** a stranger can watch a 30 s clip and understand + want the game.

---

## M14 — Fix & Finish
Playtest fixes, balance, and finishing what is half done: the Knight's extra cards and relics, the hero stories, the
Pressure switches that have never been tried by hand (Hardened Elites and Stronger Bosses have no tests yet), chapter 1's
uneven row steps, chapter 2's economy as the first outside playtest sees it, and whatever the `m13-playtest-2` feedback adds.
Not started.

**Done when:** everything in the game works and feels finished.

---

## M15 — Art Overhaul
Work through `docs/ART_BACKLOG.md`: replace every recoloured placeholder enemy, apply the new Knight design, and carry the
theme through all art, warm defenders against the cold dead (the fortress, the towers and the hero warm; the dead and the
far map cool). Follows `ART_DIRECTION.md`. Not started.

**Done when:** there are no placeholders left, and the game passes the grayscale and readability checks
(`test_readability`, the `--grayscale` review shots).

---

## M16 — Outside Playtest *(optional)*
Builds for 3-5 new players, or a free itch.io demo; feedback comes in with the F8 tool (`tools/feedback_summary.py`, the
`feedback-review` skill). Needs M14 and M15 first, and a decision on the release questions in the parking lot. Not started.

**Done when:** strangers have played it and their feedback is sorted into what to fix and what to leave.

---

## Current focus
**M0-M13 are built; M14-M16 are planned, not started.** The latest playtest build is **`m13-playtest-2`** (tag on
`art/handoff-integration`, not merged into `main`; zips in `builds/`, including `-dev-` zips with F12; what to test is at
the top of `PLAYTEST.md`). **Waiting for the owner's playtest of that build** (the bot, which dies in chapter 1, cannot judge
chapter 2's economy, the music, the story texts or the new map art). Nothing is to be started until that feedback is
in and M14's scope is approved (CLAUDE.md rule 7).

Also open: the **look test** on branch `look-test` (variants A, B, C of a "HD-2D" look on the graveyard; report in
`docs/LOOK_TEST.md`; C was brightened and its bottom strip removed on request). The owner has not chosen a direction; none of it
is to be merged. Everything a fresh session needs (branches, decisions, pending items, tool notes) is in
**`docs/HANDOFF.md`**.

---

## Parking lot (not planned)
Notes for a release, if and when we decide on one. We're making the best game we can first; none of this is scheduled.
- **Store page key art** by a human artist (`CLAUDE.md` rule 3 allows only CC0 or self-made assets: a commissioned piece would need an exception there, with the rights logged in `assets/CREDITS.md`).
- **AI content disclosure** for a store page (how the code and art were made).
- **Controller support** (and a handheld-friendly UI).
- **Signed store builds** (code signing, store build pipelines; the playtest presets and `tools/build_playtest.sh` exist since M6).
- **Steam integration** (achievements, cloud saves; GodotSteam is an external dependency and needs explicit approval).
