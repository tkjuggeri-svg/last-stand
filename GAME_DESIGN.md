# LAST STAND — Game Design

> Living document. Numbers are starting points for prototyping, not final balance.

## 1. Pitch

The last fortress of a dying kingdom. A lone hero, a handful of arcane towers, and waves of horrors from the dark. Every night is worse than the last. Every run ends in death — but each one teaches you something, and the kingdom's remnants grow a little stronger.

**Pillars**
1. **Hands-on defense** — the hero is not a cursor; positioning and fighting matter every second.
2. **Meaningful builds** — towers + upgrades combine into synergies that make each run feel different.
3. **Escalating dread** — waves visibly and mechanically grow more threatening; the fortress is always one mistake from falling.

## 2. Core loop

```
            ┌──────────────────────── RUN ───────────────────────┐
 Meta  ───► │  Build phase ──► Wave (combat) ──► Reward/Upgrade  │──► Death or Victory ──► Meta progression
 hub        │       ▲                                     │      │
            │       └─────────────────────────────────────┘      │
            └────────────────────────────────────────────────────┘
```

- **Second to second:** move hero, attack, dodge, reposition to where the line is breaking.
- **Wave to wave:** spend gold on towers, pick 1 of 3 upgrades, prepare for the next wave type.
- **Run to run:** unlock new heroes, towers, and upgrades into the pool (meta progression).

## 3. Run structure

- A run = **one map, ~15 waves**, with a **boss wave every 5th wave** (5, 10, 15). Target length 20–30 min.
  **M4 prototype: 10 hand-authored waves** (no bosses yet) on the prototype arena; beating wave 10 wins the run (Victory screen, "Play again" starts a fresh run, same pattern as Game Over).
- Each wave has a **build phase** and a **combat phase** (`RunCycle`, per level). The build phase is untimed (optional timer later): no enemies come until the player presses **Start wave** (HUD button, top-left) or **Enter** (`start_wave`). The combat phase ends when the wave's last enemy is dead or has reached the fortress; then the next build phase begins. After the last wave the run is finished. Building and selling stay allowed in both phases.
- HUD: a top-left wave panel ("Wave 3 / 10", the phase, the Start button in the build phase); the bottom-left panel shows "Enemies left: n / total" during a wave and "Next wave: n enemies" between waves.
- The run ends in defeat when the **fortress HP reaches 0** ("The fortress has fallen.") or the hero loses its **last life** ("The hero has fallen."), and in victory when the last wave is beaten.
  Prototype (M1): defeat freezes the level and shows a Game Over screen ("The fortress has fallen.") with Restart, which starts a completely fresh run.
- **Hero lives (decided in M4):** the hero has **3 lives** per run (`HeroLives.lives`); they don't come back between waves (revisit after playtesting). Each fall costs one. While lives remain, the hero respawns at the `RespawnPoint` in front of the fortress after **4 s** (`respawn_delay`), with full HP, a visible countdown ("Hero returns in 3" at the spot, "Hero back in 3 s" in the HUD) and **2 s of invulnerability** (`respawn_invulnerability`) shown by a blink. The towers keep defending meanwhile. Losing the last life ends the run. The HUD shows one helm per life next to the hero's HP bar (spent lives dark).
- While fallen the hero can't move, attack or build, and is not a target: it leaves the hero physics layer, so enemies' attack ranges let go and they walk on.

## 4. Systems

### 4.1 Hero
- WASD movement, mouse-aimed attacks.
- Stats: max HP, move speed, attack damage, attack speed, attack range.
- **Basic attack** (LMB): short-range **melee arc** aimed at the mouse (decided). Melee makes positioning matter and contrasts with ranged towers. One hero only at first.
  Prototype values: ~100° arc, 68 px reach (was 52, raised after the first playtest) from the hero's centre, 10 damage, hitbox active 0.12 s, 0.4 s cooldown; holding LMB keeps swinging. Each swing hits each target at most once.
- **Dash** (M6, `dash` action: Space or Shift, rebindable): a short burst in the movement direction (standing still: the way the hero last moved), 120 px in 0.16 s (750 px/s), **2 s cooldown** (shown on the HUD: a Dash row with a filling bar, "Ready" or the seconds left). The hero is **immune to hits** while dashing and for 0.08 s after. Its body only collides with the world and the fortress, so the dash **passes through enemies but stops at walls and the fortress** (`move_and_slide`). No swing can start mid-dash; a swing never blocks a dash. Implemented as a `HeroDash` component node on the hero (values exported there); afterimages and a dust puff are display only. Space was taken out of Godot's built-in `ui_accept` (Enter still confirms), so dashing with Space never presses a focused menu button.
- Builds towers at slots **at any time**, before or during a wave (decided in M3): walk to a slot, press **E**.
- Hero HP: 100 (prototype). Enemy melee hits it through a `Hurtbox`; after each hit the hero is invulnerable for 0.5 s, so a crowd can't shred it in an instant. Feedback: red-white flash, hit spark, floating damage number, HUD bar. At 0 HP the knight falls (death animation) and costs a life; it respawns at the fortress while lives remain, and the last life lost is Game Over (see 3. Run structure).
- Implementation: `CharacterBody2D` + `HealthComponent` + `Hurtbox`; simple state machine (Idle, Move, Attack, Dead) only once more than ~3 states exist.

### 4.2 Fortress
- A static structure with HP (start: 100). Enemies that reach it deal damage and die (prototype) or stop and attack it (later).
- Prototype: 96×96 `StaticBody2D` (blocks the hero), `HealthComponent` + `Hurtbox` that only reacts to `enemy_hitbox`, so the hero can never damage it. Emits `destroyed` at 0 HP; the visual darkens.
- Fortress HP is shown prominently in the HUD. It does **not** regenerate by default; some upgrades/rewards heal it.

### 4.3 Enemies
- Spawn at crypts and follow **lanes** (`Path2D`) toward the fortress. The prototype arena has 3 lanes: the west crypt road (902 px), a short north-east road (636 px, to the east wall; its last stretch runs at y = 24, south of the fortress's y-sort line, so enemies there always draw in front of the castle) and a south road (922 px, to the south wall); each wave's spawn groups pick their lane.
- **Decision:** enemies sample the lane curve and move themselves (not parented to `PathFollow2D`). This lets them leave the path to chase the hero briefly (aggro) and return, without re-parenting.
- Defined by `EnemyData`: max HP, speed, damage to fortress, contact damage, gold reward, sprite, aggro range.
- Prototype (M1): `EnemyData` has max HP, speed and fortress damage only. Each frame the enemy steers toward a point 24 px further along its lane, so it rounds corners slightly (≤ ~8 px off centre) and can rejoin the lane if pushed. Enemies have no physical collision yet. The Ghoul's `Hitbox` (enemy_hitbox) damages the fortress on contact and the Ghoul is removed (`Hitbox.hit` signal).
- Ghoul (M1 values): 30 HP (3 hero swings), 60 px/s, 10 fortress damage.
- Enemies attack the hero: when the hero's body comes within `attack_range` (Ghoul: 24 px) the enemy stops on its lane, winds up (Ghoul: 0.35 s, a visible claw raise, so it can be dodged by stepping away), strikes (Ghoul: 10 damage), and waits out its own cooldown (Ghoul: 1.2 s). When the hero leaves, it rejoins the lane. All values live in `EnemyData`.
- **At most 2 enemies attack the hero at once** (`AttackerLimit` on the hero, `max_attackers`). An enemy claims a slot before its wind-up and frees it when the strike ends or it dies; the others wait in range (idle) and take turns. Keeps crowds dangerous but readable and fair.
- Two separate enemy hitboxes: the melee attack (`enemy_hitbox`, hurts the hero) and the fortress contact (`fortress_hitbox`, hurts only the fortress and uses the enemy up). Touching or fighting the hero never uses an enemy up.
- Every enemy leaves exactly one way: `died` (killed) or `reached_fortress` (used up). `EnemySpawner` turns these into `enemy_killed` and `enemy_counts_changed(living, spawned)` for the HUD.
- **Cultist** (M6, ranged; `EnemyData.bolt_speed > 0`): walks its lane like the others but stops **170 px before the lane's end** (`siege_distance`) and shoots the fortress from there (4 damage per shot, every 2 s). When the hero comes within **150 px** (`attack_range` + body) it stops wherever it is and shoots the hero instead (8 damage), and goes back to the fortress (or walks on) once the hero leaves. Every shot is telegraphed by a 0.5 s cast (the witchfire swells over its head) and is a straight, non-homing bolt (230 px/s) aimed where the target stood at the release, so stepping aside or dashing through it avoids it. Ranged enemies take no `AttackerLimit` slot (the limit keeps melee crowds readable). Its shots (`EnemyBolt`, a moving `Hitbox`) sit on `enemy_hitbox` (at the hero) or `fortress_hitbox` (at the fortress), never both; they die with the caster. With 20 HP it falls to 2 sword swings or 2 arrows, so towers near the fortress or the hero should hunt it down.
- Enemies show a small pixel-art health bar above the head (`EnemyHealthBar`, height `EnemyData.health_bar_y`, width from the body) only after they first take damage.
- All enemy types share one scene (`entities/enemies/enemy.tscn`); `EnemyData` also holds the body radius (hurtbox, fortress contact and reach scale with it), the SpriteFrames and the sprite offset, like towers and `TowerData`.
- Starter roster (M4 values, all in `data/enemies/*.tres`):
  | Enemy  | Role | HP | Speed | Fortress dmg | Hero dmg | Wind-up / cooldown | Gold | Body |
  |--------|------|----|-------|--------------|----------|--------------------|------|------|
  | Ghoul  | Basic, medium speed, weak | 30 | 60 | 10 | 10 | 0.35 / 1.2 s | 8 | r 12 |
  | Hound  | Fast, fragile, comes in packs; light on the fortress | 15 | 115 | 5 | 6 | 0.25 / 0.9 s | 4 | r 10 |
  | Brute  | Slow, tanky, hits the fortress hard | 150 | 32 | 30 | 22 | 0.6 / 2.2 s | 20 | r 18 |
  | Cultist (M6) | Ranged caster, fragile: hunt it down | 20 | 52 | 4 per shot (siege) | 8 per shot | 0.5 / 2.0 s | 10 | r 10 |
  | Boss (later)    | Big HP, special attack, summons adds | | | | | | | |

### 4.4 Towers
- Built on **predefined build slots** placed in the level.
  - **Decision:** slots instead of free placement. Avoids grid/collision/pathing edge cases, makes map design deliberate, and is far cheaper to prototype. Free placement can be revisited later.
- Defined by `TowerData` (`data/towers/*.tres`): name, description, cost, range, damage, fire interval, projectile speed and look, splash radius, slow factor/duration, muzzle position.
- **Building is allowed before and during waves**; the game never pauses for it. Prototype arena: 10 slots beside the lanes (6 along the west road, 2 by the north-east road, 1 by the south road, 1 where the north-east and south roads reach the fortress; each ≥ 80 px from every lane's centre line, so towers never block enemies). Walk to a slot and press **E**: a compact panel lists each tower's icon, name, price (red if unaffordable) and description; an occupied slot shows the tower's stats and **Sell (+50% of the build price)**. Esc/E or walking away closes it. A new tower is **under construction for `build_time` (0.6 s, in its TowerData)**: it can't aim or fire until it is finished. A sold tower stops at once (selling mid-construction refunds the usual 50%).
- Targeting: "first along path" (the living enemy furthest along the lane, kept while valid and in range). Later options: nearest, strongest.
- **Cannon shells are ground-targeted** (`TowerData.homing = false`, decided after the M4 playtest): the tower aims at the target's position at impact (its current velocity × the flight time, iterated twice, clamped to the range), the shell flies there in a visible arc with a shadow while a dashed ring marks the blast area, and explodes on that spot. It never follows anyone, so it hits whatever stands in the blast and can miss an enemy that changes speed or direction. Arrows and frost bolts stay homing.
- **Range is strict** (fixed after the M4 playtest): a tower only takes a target whose *centre* is within `attack_range` of its base and drops it the moment it leaves. Homing shots follow their target only while it stays within range + 32 px of the tower; a target that gets away is lost and the shot misses. Range rings: while the mouse is over a slot with a tower, while the build menu is open at a tower, and as a preview of each tower card at an empty slot.
- Damage goes through the same `Hurtbox`/`HealthComponent` path as melee. Towers never hurt the hero or the fortress (cannon blasts are on `hero_hitbox`, which only enemies listen to).
- Towers (values retuned after the M4 playtest with `tests/tools/balance_report.gd`; level 1 → 2 → 3, upgrade prices in brackets):
  | Tower  | Cost (upgrades) | Role | Damage / interval | Range | Special |
  |--------|-----------------|------|-------------------|-------|---------|
  | Archer | 50 (100, 180)   | Reliable single target | 10/0.8 s → 12/0.75 → 14/0.7 | 210 → 220 → 230 | Arrows home in on one enemy; level 3 looses a volley at 2 enemies |
  | Frost  | 60 (90, 150)    | Crowd control | 8/1.1 s → 10/1.0 → 12/0.95 | 180 → 190 → 200 | Slows to 50% for 2 s → 42% / 2.6 s → 35% / 3.2 s; strongest slow wins, never stacks, always expires; level 3 slows every enemy within 48 px of the impact |
  | Cannon | 100 (160, 260)  | Slow, heavy area damage | 30/2.5 s → 34/2.3 → 42/2.2 | 190 → 200 → 205 | Ground-targeted shell (not homing): lands where the target should be (simple lead), explodes on every enemy within 40 → 44 → 50 px; can miss fast or turning enemies; level 3 heavy shells |
  | Brazier | 80 (110, 170) | Area denial, short range | fire glob every 1.6 → 1.5 → 1.4 s (no direct hit) | 120 → 130 → 140 | Lobs burning pitch at the ground (not homing, can miss): burning ground 10 → 14 → 18 damage/s for 2.5 → 3 → 3.5 s within 36 → 40 → 46 px |
  | Bone Ballista | 120 (160, 240) | Long range, lines of enemies | 26/2.8 s → 34/2.6 → 44/2.4 | 300 → 320 → 340 | Bolt flies straight along the ground line through its (led) target to the range, hitting 1 + pierce enemies: pierce 3 → 4 → 6 |
- M5 added the Brazier and the Bone Ballista (above); the planned Frost Obelisk was dropped because it overlaps the Frost tower. The build menu shows its 5 tower cards in rows of 3. The prototype arena's 10 build slots (since M4) are enough for 5 tower types, so no slot change is proposed.
- **Tower upgrades** (pulled forward from M5 after the M4 playtest; the rest of M5 stays later): every tower has 2 upgrade tiers (level 1 → 2 → 3), bought from the tower's build-menu view, which shows the next level's price and what changes ("Damage 10 → 14, Range 210 → 225"). Data: `TowerTier` resources in `TowerData.tiers` (price + full stats per level); `TowerBuilder.upgrade()` owns the rules (gold, top level, not during construction). Level 3 specials: Archer looses a volley at 2 targets, Cannon fires heavy shells with a bigger blast, Frost slows every enemy near the impact (frost nova). Each level has its own look (Archer: the order's banner, then a second archer and a gold pennant; Cannon: bronze barrel and iron band, then a heavy mortar barrel and war banner; Frost: ice spikes and orbiting shards, then a bigger crystal with a crown of shards). Upgrading is instant with a bright flash.
- Selling refunds **50% of everything spent on that tower** (build + upgrades).

### 4.5 Economy
- **Gold** (in-run): starts at 150. Every enemy **killed** (by the hero or a tower) pays its `EnemyData.gold_reward` exactly once (Ghoul 8, Hound 4, Brute 20; lowered after the M4 playtest so gold stays tight); an enemy that reaches the fortress pays nothing. Spent on towers and their upgrades. Never negative. Resets every run.
- **Perfect-defense bonus:** when a wave ends and no enemy reached the fortress, +10% of that wave's kill gold (10 Ghouls x 10 = 100 → +10). One leak cancels it; paid at most once per wave. A wave is one `WaveSpawner` wave (`wave_started` .. `wave_cleared`).
- **Soul Shards** (meta): earned at run end based on waves survived. Spent in the meta hub on permanent unlocks.
- Keep it to these two currencies. More resources only if a system clearly needs them.

### 4.6 Upgrades (roguelite layer)
- After each wave (except the last), before the build phase: choose **1 of 3** random upgrades (`UpgradeOffers` + `UpgradeChoiceScreen`; `RunCycle` phase CHOOSE). The game is paused while the screen is open; mouse or keyboard (arrows, Enter). No duplicate cards in an offer; non-stackable upgrades never come back once taken; commons are drawn 3× as often as rares. One reroll per offer for gold (25, then +25 each reroll used in the run). The run's RNG is seeded (`UpgradeOffers.seed_value`, -1 = random), so tests and the balance tool are reproducible. The HUD shows a row of the run's upgrade icons (stack counts, hover for details) under the wave panel.
- Defined by `UpgradeData` (`data/upgrades/*.tres`): id, name, description, icon, category (Hero / Towers / Fortress / Economy), rarity (common / rare), stackable or once per run, a list of `StatModifier`s and an optional instant effect (e.g. repair the fortress now).
- **Run modifier store** (`RunModifiers`, per level under Systems, no autoload; Restart = fresh level = empty store): flat and percent modifiers on named stats, final = (base + flats) × (1 + percents), percents add up. Systems read their final values through it, so an empty store changes nothing: hero damage, move speed, max HP, attack cooldown, reach, lives; tower damage, fire interval, range, build time, slow duration, pierce, burn (all towers via `tower.<stat>`, one type via `tower.<id>.<stat>`); fortress max HP and thorns; kill gold, interest on unspent gold (capped), tower upgrade prices. Max HP changes move current HP by the same amount.
- **M5 pool** (20 upgrades, plus 2 dash upgrades in M6, `data/upgrades/`, original 16×16 icons; "once" = not stackable):
  | Upgrade | Category | Rarity | Effect |
  |---------|----------|--------|--------|
  | Honed Blade | Hero | common | Sword damage +4 |
  | Long Reach | Hero | common | Sword reach +15% (hitbox and trail: the trail is pre-drawn at x1.15/1.3/1.45/1.6 and the nearest is used) |
  | Battle Rhythm | Hero | common | Swing 15% faster |
  | Iron Constitution | Hero | common | Hero max HP +30 |
  | Second Wind | Hero | rare, once | +1 life |
  | Berserker's Oath | Hero | rare, once | Sword damage +60%, hero max HP −30% (trade-off) |
  | Keen Fletching | Towers | common | All towers +10% damage |
  | Eagle Eye | Towers | common | All towers +12% range |
  | Quick Masons | Towers | common, once | Towers built 60% faster |
  | Overcharged Engines | Towers | rare, once | All towers +40% damage, but fire 15% slower (trade-off; net about +22% damage per second). It used to cost range, which crippled the short-range Brazier |
  | Piercing Arrows | Towers | rare, once | Archer arrows fly on (along the ground line from the tower) through 1 more enemy |
  | Hellfire Shells | Towers | rare, once | Cannon shells leave burning ground: 3 damage/s for 3 s |
  | Deep Freeze | Towers | common | Frost slows last 40% longer |
  | Stout Masonry | Fortress | common | Fortress max HP +25 |
  | Emergency Repairs | Fortress | common | Repair 30% of the fortress's max HP now |
  | Thorned Walls | Fortress | rare, once | Enemies at the walls (92 px) take 12 damage/s |
  | Bounty Hunters | Economy | common | Kills pay 20% more gold |
  | Treasury | Economy | rare, once | End of each wave: +10% of unspent gold, up to 40 |
  | Guild Discount | Economy | common, once | Tower upgrades cost 20% less |
  | War Tax | Economy | rare, once | Kills pay 30% more gold, fortress max HP −25 (trade-off) |
  | Fleet Step (M6) | Hero | common | Dash recharges 25% faster (stacks; never below 0.6 s) |
  | Cinder Dash (M6) | Hero | rare, once | The dash leaves burning ground: a patch every 30 px of the path (radius 26), 16 damage/s for 2 s; overlapping patches add up |
- Burning ground (`BurnZone`) and thorns damage enemies in ticks through their Hurtboxes like any other hit.
- Rerolls cost gold (see above).

### 4.7 Waves
- Defined by `WaveData` (`data/waves/wave_NN.tres`): a list of `SpawnGroup`s `{enemy: EnemyData, count, interval, lane, delay}`. The groups of a wave run in parallel: a group's k-th enemy appears at `delay + k × interval` seconds after the wave starts, on the level lane with index `lane`.
- Hand-authored for the first version; later add a difficulty scaler (HP/count multipliers) for endless mode.
- `WaveSpawner` (per level, no autoload) holds the level's lanes and waves, starts one wave at a time (`start_next_wave()`), gives each spawned enemy its group's `EnemyData`, and emits `wave_started(n)` / `wave_cleared(n)` (every enemy of the wave spawned and gone: killed or used up at the fortress) plus per-enemy signals. Other systems (WaveRewards, HUD, Level) connect to it through exported node references, so no `Events` autoload is needed yet.

- **M4 waves** (`data/waves/wave_01..10.tres`; lanes: W = west crypt road, NE = north-east road, the short one, S = south road). Hounds arrive in wave 3, Brutes in wave 5; every wave brings more total enemy HP than the last:
  | Wave | Ghouls | Hounds | Brutes | Total | Lanes | Total HP |
  |------|--------|--------|--------|-------|-------|----------|
  | 1  | 8  | –  | –  | 8   | W        | 240 |
  | 2  | 13 | –  | –  | 13  | W, NE    | 390 |
  | 3  | 11 | 6  | –  | 17  | W, NE    | 420 |
  | 4  | 16 | 8  | –  | 24  | all      | 600 |
  | 5  | 16 | 8  | 2  | 26  | all      | 900 |
  | 6  | 24 | 14 | 2  | 40  | all      | 1230 |
  | 7  | 18 | 24 | 5  | 47  | all      | 1650 |
  | 8  | 30 | 28 | 8  | 66  | all      | 2520 |
  | 9  | 40 | 50 | 16 | 106 | all      | 4350 |
  | 10 | 60 | 76 | 20 | 156 | all      | 5940 |
- Tuning (balance report after the playtest fixes, idle hero, towers and upgrades bought as gold allows, 5 s build phases): no tower-only plan wins. Best: archers + cannons and the mixed build fall in wave 9; all archers wave 8, all cannons wave 7, frost + archers wave 6. Mixing tower types beats any single type, and nobody can afford every tower at level 3 (21–22 of 30 levels by the end). The hero fighting is what should turn the late waves into a win.
- **Wave toughness** (M5): `WaveData.health_multiplier` scales every enemy's HP in a wave without paying more gold (more enemies would also mean more gold): waves 1–4 ×1, then 1.15, 1.3, 1.45, 1.7, 1.9, 2.1 for waves 5–10. It absorbs the nine run upgrades a full run collects.
- **M5 tuning** (balance report with run upgrades, idle hero, seed 1; the bot takes upgrades by a simple policy): without upgrades every plan falls in wave 7–8; with upgrades the best runs fall in wave 9–10, weaker picks in wave 6–9, so the picks move a run by up to three waves, and nothing wins without the hero. Other seeds give other runs (different offers): e.g. seed 4's offers only reach wave 7–8, seed 3's lucky Overcharge + Hellfire + War Tax opening wins with 30–50 fortress HP. No single upgrade wins a run on its own: alone, each moves the baseline by at most one wave (Hellfire, Overcharge, Bounty strongest).

### 4.8 Meta progression (later milestone)
- Hub screen between runs. Spend Soul Shards to unlock new towers, upgrades in the pool, a second hero, and small permanent bonuses.
- Saved to `user://` via a single `SaveManager`.

## 5. Controls (PC)

| Action      | Default            |
|-------------|--------------------|
| Move        | WASD / Arrows      |
| Attack      | Left mouse         |
| Dash        | Space / Shift      |
| Build menu  | B / click slot     |
| Interact    | E                  |
| Start wave  | Enter (build phase)|
| Pause       | Esc                |

Controller support is a post-prototype goal (Steam Deck verified is a nice-to-have).

## 6. Presentation

Full visual rules: **`ART_DIRECTION.md`** (overhauled in M3.5).

- **Art direction: HD retro pixel art** (1 art px = 2 world px, an effective 640×360 art canvas), 3/4 top-down view, entirely original and drawn in code. Lit from the top-left with banded shading, 1 px dark outlines plus interior contours, muted cold world with warm fire/gold and the hero's red as accents.
- Readability first: hero > enemies > buildings > ground in contrast. Enemies, projectiles and the hero must be instantly distinguishable at a glance.
- Hero: a knight in steel plate — great helm with a red plume, red tabard with the order's gold tower, dark red cape, heater shield, longsword. Idle, walk and a 4-frame attack in 4 directions; a 6-frame death.
- Ghoul: ashen, hunched corpse with ribs, rags, long bone claws and burning red eyes. Shambling walk, a lunge attack whose strike frame lands with the 0.35 s wind-up, white hit flash + spark, and a death where it collapses, crumbles and releases a green soul.
- Hound: a starved grave hound, low and long, with a bare skull for a head, exposed ribs and spine and a flayed red-brown hide. A gallop, a bite lunge striking at the 0.25 s wind-up, a yelp-and-collapse death. Reads as "fast, low beast": horizontal and red-brown next to the upright grey Ghoul.
- Brute: a hulking stitched corpse of bruised violet-grey flesh with bone spurs, an iron collar, shackles with broken chains and huge fists, drawn on a 48×48 frame. A heavy stomp, an overhead two-fist slam striking at the 0.6 s wind-up (with thrown-up dust), a kneel-and-topple death.
- Fortress: a 3/4-view stronghold — curtain walls with battlements, four round towers with slate cones, a gate where the lane arrives, a keep with lit windows and banners. Damage states break and lower the masonry, burn roofs, add cracks, scorch and rubble; fires with smoke appear, banners tear, the walls shake and throw dust when hit.
- Towers: Archer (stone keep, timber platform, a hooded archer drawing a longbow), Cannon (drum tower, recoiling cannon with a muzzle blast), Frost (rune obelisk with a turning ice crystal and a cold glow). Each has idle and attack loops, rises in scaffolding when built and is dismantled into rubble when sold.
- Arena: dark grass with moss/dry patches and tufts, a rutted dirt lane from a crypt in a graveyard (where the dead rise) to a cobbled clearing at the gate, graves, dead trees, lanterns, ruins; a 3/4 stone wall around the edge.
- Atmosphere: dusk lighting (CanvasModulate) with warm lantern/fire light, a cold frost glow, a green-lit crypt, drifting pixel fog, fireflies and a vignette. Nothing may reduce gameplay readability.
- Effects stay short: an 8-direction crescent sword trail matching the 68 px reach, a star hit spark, dust, explosion, frost burst.
- HUD: bottom-left framed panel with fortress/hero bars (icons), gold, free slots and enemy counts; top-right fading feed; the build panel opens bottom-right. All UI uses the project's outlined pixel font and pixel frames at 2×.
- Camera: follows hero with smoothing, clamped to map bounds. Map should fit roughly 1.5–2 screens.
  Prototype arena: 1300×900 floor (x −900…400, y −500…400), enclosed by `ArenaBounds` walls on the `world` layer; Camera2D limits equal the floor. Enemies don't collide with walls; lanes must stay inside the arena.
- Base resolution: **1280×720** (canvas_items stretch). With 1 art px = 2 world px, pixels stay even at 720p, 1080p, 1440p and 4K.

## 7. Out of scope (for now)

Multiplayer, story/cutscenes, procedural maps, multiple biomes, localization, mod support. Revisit after Early Access.

## 8. Open questions

- Do enemies attack towers, or only the fortress and hero?
- Should the hero physically block enemies (body collision), or only fight them?
