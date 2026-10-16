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
- Hero death is **not** run-ending: the hero respawns at the fortress after a delay (e.g. 5 s, growing each death). The fortress is the true fail state, which keeps the TD identity.

## 4. Systems

### 4.1 Hero
- WASD movement, mouse-aimed attacks.
- Stats: max HP, move speed, attack damage, attack speed, attack range.
- **Basic attack** (LMB): short-range **melee arc** aimed at the mouse (decided). Melee makes positioning matter and contrasts with ranged towers. One hero only at first.
  Prototype values: ~100° arc, 52 px reach from the hero's centre, 10 damage, hitbox active 0.12 s, 0.4 s cooldown; holding LMB keeps swinging. Each swing hits each target at most once.
- **Ability** (Space/RMB) on cooldown — e.g. dash or AoE slam. Added after the core loop works.
- Can **repair/build** only during build phase (or near the fortress, TBD).
- Implementation: `CharacterBody2D` + `HealthComponent` + `Hurtbox`; simple state machine (Idle, Move, Attack, Dead) only once more than ~3 states exist.

### 4.2 Fortress
- A static structure with HP (start: 100). Enemies that reach it deal damage and die (prototype) or stop and attack it (later).
- Fortress HP is shown prominently in the HUD. It does **not** regenerate by default; some upgrades/rewards heal it.

### 4.3 Enemies
- Spawn at map edges and follow **lanes** (`Path2D`) toward the fortress.
- **Decision:** enemies sample the lane curve and move themselves (not parented to `PathFollow2D`). This lets them leave the path to chase the hero briefly (aggro) and return, without re-parenting.
- Defined by `EnemyData`: max HP, speed, damage to fortress, contact damage, gold reward, sprite, aggro range.
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

- Dark fantasy palette: desaturated stone, deep blues/purples, warm torch/fire accents for readability.
- Readability first: enemies, projectiles, and the hero must be instantly distinguishable at a glance.
- Camera: follows hero with smoothing, clamped to map bounds. Map should fit roughly 1.5–2 screens.
- Base resolution: **1280×720 for prototyping** (scales to any window). Final value is decided with the art style (pixel art → 640×360; HD → 1920×1080).

## 7. Out of scope (for now)

Multiplayer, story/cutscenes, procedural maps, multiple biomes, localization, mod support. Revisit after Early Access.

## 8. Open questions

- Do enemies attack towers, or only the fortress and hero?
- Build phase: timed or untimed?
- Pixel art or HD art direction?
