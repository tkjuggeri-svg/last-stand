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
- The run ends when the **fortress HP reaches 0** (defeat) or wave 15's boss dies (victory).
  Prototype (M1): defeat freezes the level and shows a Game Over screen ("The fortress has fallen.") with Restart, which starts a completely fresh run.
- Hero death is **not** run-ending: the hero respawns at the fortress after a delay (e.g. 5 s, growing each death). The fortress is the true fail state, which keeps the TD identity.

## 4. Systems

### 4.1 Hero
- WASD movement, mouse-aimed attacks.
- Stats: max HP, move speed, attack damage, attack speed, attack range.
- **Basic attack** (LMB): short-range **melee arc** aimed at the mouse (decided). Melee makes positioning matter and contrasts with ranged towers. One hero only at first.
  Prototype values: ~100° arc, 68 px reach (was 52, raised after the first playtest) from the hero's centre, 10 damage, hitbox active 0.12 s, 0.4 s cooldown; holding LMB keeps swinging. Each swing hits each target at most once.
- **Ability** (Space/RMB) on cooldown — e.g. dash or AoE slam. Added after the core loop works.
- Can **repair/build** only during build phase (or near the fortress, TBD).
- Hero HP: 100 (prototype). The hero has a `HealthComponent` (shown in the HUD) but no `Hurtbox` yet, so nothing can damage it until enemy attacks on the hero are designed (see open questions).
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
- Defined by `TowerData`: cost, damage, fire rate, range, projectile scene, targeting mode, upgrade path.
- Targeting: "first along path" by default (most TD-correct), later options: nearest, strongest.
- Starter towers:
  | Tower         | Behaviour                               |
  |---------------|-----------------------------------------|
  | Arrow Tower   | Single target, fast, cheap              |
  | Brazier       | Short-range AoE fire, burns             |
  | Frost Obelisk | Slows enemies in range                  |
  | Bone Ballista | Long-range, piercing, slow              |
- Each tower can be **upgraded 2 times** in a run, and **sold** for 50–75% refund.

### 4.5 Economy
- **Gold** (in-run): earned per kill + wave-clear bonus. Spent on towers and tower upgrades. Resets every run.
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

- **Art direction (decided in M2): retro 16-bit pixel art**, top-down 3/4 view, in the spirit of classic action RPGs but entirely original. Chunky sprites with 1 px dark outlines and strong silhouettes, crisp pixels (nearest filtering, 1 art px = 2 world px), muted dark fantasy palette: dark green grass, earthy brown dirt, grey stone, restrained red accents (the knight's tabard and plume, the fortress banner, ghoul eyes).
- Readability first: enemies, projectiles, and the hero must be instantly distinguishable at a glance. The ground is deliberately low-contrast; characters are brighter and outlined.
- Hero: a knight in steel plate with a red tabard and plume; sword always visible. Idle, walk and attack in 4 directions.
- Ghoul: pale grey-green, hunched, ragged, bone claws, glowing red eyes. Idle and shambling walk in 4 directions; white hit flash + spark when struck; collapses into a heap of rags and bones with a dust puff when killed.
- Fortress: walled keep with four corner towers, a gate facing the lane and a red banner; shows cracks (≤ 2/3 HP), a broken tower and fire (≤ 1/3 HP), and ruins (destroyed).
- Arena: dark grass with dry patches, stones, bones and twigs; a dirt lane from a small graveyard (where the dead rise) to a clearing around the fortress; a battlemented stone wall around the edge.
- Effects stay small: an 8-direction crescent sword trail matching the 68 px reach, a short hit spark, a death collapse with dust.
- HUD (prototype): top-left shows fortress/hero HP bars and "Enemies alive / Spawned"; top-right shows a short fading feed ("Ghoul incoming!", "Ghoul slain!", max 4 lines, ~2.5 s each). Nothing is drawn in the middle of the screen.
- Camera: follows hero with smoothing, clamped to map bounds. Map should fit roughly 1.5–2 screens.
  Prototype arena: 1300×900 floor (x −900…400, y −500…400), enclosed by `ArenaBounds` walls on the `world` layer; Camera2D limits equal the floor. Enemies don't collide with walls; lanes must stay inside the arena.
- Base resolution: **1280×720** (canvas_items stretch). With 1 art px = 2 world px, pixels stay even at 720p, 1080p, 1440p and 4K.

## 7. Out of scope (for now)

Multiplayer, story/cutscenes, procedural maps, multiple biomes, localization, mod support. Revisit after Early Access.

## 8. Open questions

- Do enemies attack towers, or only the fortress and hero?
- When the hero gets a `Hurtbox`, a Ghoul touching the hero would also be "used up" by its fortress hitbox. Decide: separate contact-damage hitbox vs. fortress-only damage (e.g. a dedicated layer or arrival check).
- Should the hero physically block enemies (body collision), or only fight them?
- Build phase: timed or untimed?
