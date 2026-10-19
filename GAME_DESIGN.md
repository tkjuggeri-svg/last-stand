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
- Each wave has a **build phase** (untimed in prototype; optional timer later) and a **combat phase**.
- The run ends when the **fortress HP reaches 0** (defeat) or wave 15's boss dies (victory). In the prototype the hero's death also ends the run (until respawning exists).
  Prototype (M1): defeat freezes the level and shows a Game Over screen ("The fortress has fallen.") with Restart, which starts a completely fresh run.
- Hero death is **not** run-ending: the hero respawns at the fortress after a delay (e.g. 5 s, growing each death). The fortress is the true fail state, which keeps the TD identity.

## 4. Systems

### 4.1 Hero
- WASD movement, mouse-aimed attacks.
- Stats: max HP, move speed, attack damage, attack speed, attack range.
- **Basic attack** (LMB): short-range **melee arc** aimed at the mouse (decided). Melee makes positioning matter and contrasts with ranged towers. One hero only at first.
  Prototype values: ~100° arc, 68 px reach (was 52, raised after the first playtest) from the hero's centre, 10 damage, hitbox active 0.12 s, 0.4 s cooldown; holding LMB keeps swinging. Each swing hits each target at most once.
- **Ability** (Space/RMB) on cooldown — e.g. dash or AoE slam. Added after the core loop works.
- Builds towers at slots **at any time**, before or during a wave (decided in M3): walk to a slot, press **E**.
- Hero HP: 100 (prototype). Enemy melee hits it through a `Hurtbox`; after each hit the hero is invulnerable for 0.5 s, so a crowd can't shred it in an instant. Feedback: red-white flash, hit spark, floating damage number, HUD bar. At 0 HP the knight falls (death animation) and the run is lost ("The hero has fallen."). Respawning instead of losing the run is still the long-term plan (see 3. Run structure) and arrives with the run-structure milestone.
- Implementation: `CharacterBody2D` + `HealthComponent` + `Hurtbox`; simple state machine (Idle, Move, Attack, Dead) only once more than ~3 states exist.

### 4.2 Fortress
- A static structure with HP (start: 100). Enemies that reach it deal damage and die (prototype) or stop and attack it (later).
- Prototype: 96×96 `StaticBody2D` (blocks the hero), `HealthComponent` + `Hurtbox` that only reacts to `enemy_hitbox`, so the hero can never damage it. Emits `destroyed` at 0 HP; the visual darkens.
- Fortress HP is shown prominently in the HUD. It does **not** regenerate by default; some upgrades/rewards heal it.

### 4.3 Enemies
- Spawn at map edges and follow **lanes** (`Path2D`) toward the fortress.
- **Decision:** enemies sample the lane curve and move themselves (not parented to `PathFollow2D`). This lets them leave the path to chase the hero briefly (aggro) and return, without re-parenting.
- Defined by `EnemyData`: max HP, speed, damage to fortress, contact damage, gold reward, sprite, aggro range.
- Prototype (M1): `EnemyData` has max HP, speed and fortress damage only. Each frame the enemy steers toward a point 24 px further along its lane, so it rounds corners slightly (≤ ~8 px off centre) and can rejoin the lane if pushed. Enemies have no physical collision yet. The Ghoul's `Hitbox` (enemy_hitbox) damages the fortress on contact and the Ghoul is removed (`Hitbox.hit` signal).
- Ghoul (M1 values): 30 HP (3 hero swings), 60 px/s, 10 fortress damage.
- Enemies attack the hero: when the hero's body comes within `attack_range` (Ghoul: 24 px) the enemy stops on its lane, winds up (Ghoul: 0.35 s, a visible claw raise, so it can be dodged by stepping away), strikes (Ghoul: 10 damage), and waits out its own cooldown (Ghoul: 1.2 s). When the hero leaves, it rejoins the lane. All values live in `EnemyData`.
- **At most 2 enemies attack the hero at once** (`AttackerLimit` on the hero, `max_attackers`). An enemy claims a slot before its wind-up and frees it when the strike ends or it dies; the others wait in range (idle) and take turns. Keeps crowds dangerous but readable and fair.
- Two separate enemy hitboxes: the melee attack (`enemy_hitbox`, hurts the hero) and the fortress contact (`fortress_hitbox`, hurts only the fortress and uses the enemy up). Touching or fighting the hero never uses an enemy up.
- Every enemy leaves exactly one way: `died` (killed) or `reached_fortress` (used up). `EnemySpawner` turns these into `enemy_killed` and `enemy_counts_changed(living, spawned)` for the HUD.
- Starter roster:
  | Enemy        | Role                                   |
  |--------------|----------------------------------------|
  | Ghoul        | Basic, medium speed, weak               |
  | Hound        | Fast, fragile, comes in packs          |
  | Brute        | Slow, tanky, hits the fortress hard    |
  | Cultist      | Ranged, targets hero or towers         |
  | Boss (Wave 5)| Big HP, special attack, summons adds   |

### 4.4 Towers
- Built on **predefined build slots** placed in the level.
  - **Decision:** slots instead of free placement. Avoids grid/collision/pathing edge cases, makes map design deliberate, and is far cheaper to prototype. Free placement can be revisited later.
- Defined by `TowerData` (`data/towers/*.tres`): name, description, cost, range, damage, fire interval, projectile speed and look, splash radius, slow factor/duration, muzzle position.
- **Building is allowed before and during waves**; the game never pauses for it. Prototype arena: 6 slots beside the lane (each ≥ 80 px from its centre line, so towers never block enemies). Walk to a slot and press **E**: a compact panel lists each tower's icon, name, price (red if unaffordable) and description; an occupied slot shows the tower's stats and **Sell (+50% of the build price)**. Esc/E or walking away closes it. A new tower is **under construction for `build_time` (0.6 s, in its TowerData)**: it can't aim or fire until it is finished. A sold tower stops at once (selling mid-construction refunds the usual 50%).
- Targeting: "first along path" (the living enemy furthest along the lane, kept while valid and in range). Later options: nearest, strongest.
- Damage goes through the same `Hurtbox`/`HealthComponent` path as melee. Towers never hurt the hero or the fortress (cannon blasts are on `hero_hitbox`, which only enemies listen to).
- M3 towers (values tuned with `tests/tools/balance_report.gd`; one tower already makes a difference, two hold a 10-Ghoul wave):
  | Tower  | Cost | Role | Damage / interval | Range | Special |
  |--------|------|------|-------------------|-------|---------|
  | Archer | 50   | Reliable single target | 10 / 0.9 s | 210 | Arrows home in on one enemy |
  | Frost  | 70   | Crowd control | 4 / 1.1 s | 180 | Slows to 50% for 2 s; strongest slow wins, never stacks, always expires |
  | Cannon | 100  | Slow, heavy area damage | 30 / 2.0 s | 190 | Explodes: every enemy within 56 px |
- Future ideas: Brazier (burning AoE), Bone Ballista (piercing).
- Tower **upgrades** (2 tiers per tower) arrive with the roguelite layer; selling always refunds 50% of the original build price, not upgrades.

### 4.5 Economy
- **Gold** (in-run): starts at 100. Every enemy **killed** (by the hero or a tower) pays its `EnemyData.gold_reward` exactly once (Ghoul: 10); an enemy that reaches the fortress pays nothing. Spent on towers (later: upgrades). Never negative. Resets every run.
- **Perfect-defense bonus:** when a wave ends and no enemy reached the fortress, +10% of that wave's kill gold (10 Ghouls x 10 = 100 → +10). One leak cancels it; paid at most once per wave. Until M4 a "wave" is one spawner run (`WaveRewards.begin_wave()/end_wave()` are the hook for the wave system).
- **Soul Shards** (meta): earned at run end based on waves survived. Spent in the meta hub on permanent unlocks.
- Keep it to these two currencies. More resources only if a system clearly needs them.

### 4.6 Upgrades (roguelite layer)
- After each wave: choose **1 of 3** random upgrades from a weighted pool.
- Defined by `UpgradeData`: id, name, description, rarity, category (Hero / Tower / Fortress / Economy), effect, max stacks.
- Effects implemented as small, composable modifiers (e.g. `+15% tower fire rate`, `hero attacks chain`, `+20 fortress HP`) applied through a **stat modifier** system rather than special-cased code.
- Examples: *Bloodthirst* (hero heals on kill), *Volley* (arrow towers fire 2 arrows), *Tithe* (+gold per wave), *Iron Walls* (+fortress max HP), *Frostbite* (slowed enemies take +damage).
- Rerolls cost gold (later).

### 4.7 Waves
- Defined by `WaveData`: list of spawn groups `{enemy, count, interval, lane, delay}`.
- Hand-authored for waves 1–15 in the first version; later add a difficulty scaler (HP/count multipliers) for endless mode.
- `WaveSpawner` (in `systems/`) reads `WaveData`, spawns enemies, and emits `wave_started` / `wave_cleared` via `Events`.

### 4.8 Meta progression (later milestone)
- Hub screen between runs. Spend Soul Shards to unlock new towers, upgrades in the pool, a second hero, and small permanent bonuses.
- Saved to `user://` via a single `SaveManager`.

## 5. Controls (PC)

| Action      | Default            |
|-------------|--------------------|
| Move        | WASD / Arrows      |
| Attack      | Left mouse         |
| Ability     | Space / Right mouse|
| Build menu  | B / click slot     |
| Interact    | E                  |
| Pause       | Esc                |

Controller support is a post-prototype goal (Steam Deck verified is a nice-to-have).

## 6. Presentation

Full visual rules: **`ART_DIRECTION.md`** (overhauled in M3.5).

- **Art direction: HD retro pixel art** (1 art px = 2 world px, an effective 640×360 art canvas), 3/4 top-down view, entirely original and drawn in code. Lit from the top-left with banded shading, 1 px dark outlines plus interior contours, muted cold world with warm fire/gold and the hero's red as accents.
- Readability first: hero > enemies > buildings > ground in contrast. Enemies, projectiles and the hero must be instantly distinguishable at a glance.
- Hero: a knight in steel plate — great helm with a red plume, red tabard with the order's gold tower, dark red cape, heater shield, longsword. Idle, walk and a 4-frame attack in 4 directions; a 6-frame death.
- Ghoul: ashen, hunched corpse with ribs, rags, long bone claws and burning red eyes. Shambling walk, a lunge attack whose strike frame lands with the 0.35 s wind-up, white hit flash + spark, and a death where it collapses, crumbles and releases a green soul.
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
