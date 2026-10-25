# M10: Maps & Biomes (design proposal)

> **Status: proposal, not approved, not implemented.** The numbers are starting points for the balance
> tools (`map_balance.gd`, `balance_report.gd`). Nothing is built until the open questions (section 9)
> are answered; section 10 will hold the decisions. Art resolution is already decided
> (`docs/M10_ART_RESOLUTION.md` section 7): every biome is drawn at double resolution.

## 0. Summary

- **A run becomes 3 chapters.** The chapters are drawn from **tiers**: tier 1 (easy), tier 2 (medium),
  tier 3 (hard). Each tier holds **3 biomes**, 9 in all. A run crosses one biome per tier.
- **A biome is what a `ChapterData` already is:** a map (arena, lanes, build slots), a run map, fights, events
  and a boss. M10 adds a `tier`, an **environmental mechanic**, **1-2 unique enemies** and **its own boss**
  to each.
- **Already built:** the Graveyard / Crypt Road (tier 1, needs its mechanic) and the Drowned Marsh (tier 2,
  mechanic: wading pools). Seven biomes are new.
- **Choosing the road:** chapter 1's biome is drawn from the run's seed; after chapters 1 and 2 the player
  **picks one of two roads** (two biomes of the next tier, drawn from the seed), seeing each one's mechanic,
  enemies, boss and a difficulty note.
- **The nine biomes** (section 2): Crypt Road, Ember Orchard, Bone Quarry (tier 1); Drowned Marsh, Frostbound
  Pass, Gloam Wood (tier 2); Ashen Keep, Sunless Mines, Pale Cathedral (tier 3). The tier-3 bosses are the
  run's finale, so a run can end three different ways.
- **Unlocks:** the first biome of each tier is free; the others are War Room unlocks (new content, never
  power), so a first-time player sees the Crypt Road, the Marsh and the Ashen Keep.
- **Built in 3 stages**, each tested, balanced and playable: (1) the tier system, the road choice, chapter 3
  with the Ashen Keep, and the Graveyard's mechanic; (2) a second biome per tier (Ember Orchard, Frostbound
  Pass, Sunless Mines); (3) the third per tier (Bone Quarry, Gloam Wood, Pale Cathedral).
- **No new autoload, physics layer or input action.** `RunState` grows the biomes chosen so far; the save
  version goes up by one.

## 1. How a run changes

```
chapter 1 (tier 1, from the seed)  ->  road choice (2 of tier 2)  ->  chapter 2  ->  road choice (2 of tier 3)  ->  chapter 3  ->  victory
```
- **Between chapters** nothing else changes (M7): towers packed up for 40% of their cost, gold, cards, relics
  and lives carry over, the fortress is repaired by half. The chapter screen (the "Chapter cleared" summary)
  gets the road choice under it.
- **Run length:** 3 chapters of 8 rows is about 55-65 minutes for a win (chapter 1 alone is 15-20 minutes
  today). Section 9, Q3.
- **Difficulty by tier** (`ChapterData.fight_health_scale`, the same knob chapters 1 and 2 use today):

| Tier | Today | Proposal |
|---|---|---|
| 1 | Crypt Road 0.75 | 0.75 (all three biomes, tuned to each map) |
| 2 | Drowned Marsh 1.6 | 1.6 |
| 3 | none | about 2.6, tuned with `map_balance.gd` until the bot's rows cleared in chapter 3 matches chapter 2's |

- **The road choice card** shows: the biome's name and a one-line picture ("a burned fortress, the walls
  still falling"), its mechanic in one sentence, its unique enemies (icons) and its boss, and a difficulty
  line ("harder: fewer slots"). Nothing is hidden: choosing a road is choosing a plan.

## 2. The nine biomes

Each biome has a map, a mechanic, 1-2 unique enemies (the rest of its roster is shared within the tier), a boss,
two events of its own beside the shared pool, and a ground, props and light in its own palette.

### Tier 1 (easy, chapter 1)
| Biome | Map and mood | Mechanic | Unique enemies | Boss |
|---|---|---|---|---|
| **Crypt Road** (built) | the graveyard: 3 roads, 10 slots, mausoleums | **Open graves:** marked graves open mid-wave (a 3 s warning ring) and raise 2-3 Ghouls on the spot: an enemy source inside the map, not only at the lanes' starts; a tower or the hero close by can't stop them, but a defence placed there can | none new (Ghoul, Hound, Brute, Cultist) | the Gravelord (built) |
| **Ember Orchard** | a burned orchard, 3 roads, 9 slots, dry grass | **Dry grass:** patches of dry grass catch fire when a Brazier shot, a burning enemy or a Cinder Dash touches them; the fire spreads over the patch for a few seconds and hurts everything on it, **the hero too** (fire hurts friends and foes) | **Cinder Ghoul** (leaves burning ground where it falls), **Scarecrow** (slow, a decoy: towers prefer it) | the Pyre Warden (summons living embers) |
| **Bone Quarry** | a quarry, 2 broad roads that merge, 8 slots | **Rockfall:** now and then a boulder lands on a marked spot of a road (a 2 s warning) and blocks it for 8 s; enemies queue behind it, so a blocked road is a chance for blasts | **Bone Hurler** (throws bone shards at towers), **Rubble Brute** (tough, takes less from blasts) | the Quarry Colossus (charges, like the Bone Colossus, and breaks slots' towers' range for a moment) |

### Tier 2 (medium, chapter 2)
| Biome | Map and mood | Mechanic | Unique enemies | Boss |
|---|---|---|---|---|
| **Drowned Marsh** (built) | the flooded marsh, 7 slots, roads that merge | **Wading pools** (built): the hero wades slowly through shallow water | Bloater, Mire Priest, Shieldbearer (built) | the Tollkeeper (built) |
| **Frostbound Pass** | a mountain pass, one long winding road and a short one, 8 slots | **Blizzard:** every 25 s a wind sweeps in for 8 s: towers lose 20% range, enemies move 10% faster; a bell-less warning (the snow thickens) comes 3 s before; **ice patches** make the hero slide on a dash | **Frost Wraith** (slows the hero and the nearest tower while alive), **Rime Brute** (immune to slows) | the Winter Warden (freezes a slot's tower solid) |
| **Gloam Wood** | a dark wood, 4 narrow roads, 8 slots | **Gloom:** the wood is dark; a tower sees only 70% of its range until a **lantern** (a build-slot upgrade, cheap, 40 gold) is lit next to it; enemies hide at the edge of the light | **Stalker** (invisible to towers until it is within 90 px), **Hollow Treant** (tough, regrows 1 HP/s) | the Hollow Stag (calls the wood: roots hold the hero) |

### Tier 3 (hard, chapter 3)
| Biome | Map and mood | Mechanic | Unique enemies | Boss |
|---|---|---|---|---|
| **Ashen Keep** (stage 1) | a burned fortress, 4 roads, 8 slots (the walls are the arena) | **Falling walls:** a wall section near a lane collapses now and then (3 s warning), hurting everything below and burning out the nearest tower slot for the rest of the fight (it can be rebuilt for gold) | **Siege Ram** (slow, hits the fortress 3x as hard), **Black Knight** (a frontal shield and a side that is not) | the Fallen Marshal (a mounted charge, then a shield wall) |
| **Sunless Mines** | a mine, 3 tunnels, 7 slots | **Cave-ins:** a tunnel section collapses for the rest of the wave and its enemies re-route through another road | **Burrower** (digs under the field and rises next to a tower), **Lamp Wight** (heals and lights its pack) | the Deep Warden (tunnels, raising rubble) |
| **Pale Cathedral** | a ruined cathedral, 3 aisles, 8 slots | **Consecrated floor:** altars heal enemies standing near them (3 HP/s) unless a tower's blast or the hero covers the altar with fire; | **Chorister** (a buff aura: nearby enemies take 20% less), **Inquisitor** (marks the hero: it takes more damage from the dead nearby) | the Pale Bishop (the finale: wards, summons, a choir) |

Every mechanic is **telegraphed, small, and a reason to place things differently**, never a surprise loss.
The three tier-3 bosses are all "final bosses"; M11 can give each its ending.

## 3. Unlocks (War Room)

The first biome of each tier (Crypt Road, Drowned Marsh, Ashen Keep) is free. Each other biome is an unlock
on the M8 board (new content only, like a tower or an event):

| Unlock | Cost | Needs |
|---|---|---|
| Ember Orchard, Bone Quarry | 40, 60 | Crypt Road's boss beaten |
| Frostbound Pass, Gloam Wood | 60, 90 | the Marsh reached |
| Sunless Mines, Pale Cathedral | 90, 120 | the Ashen Keep reached |

A locked biome never shows up on the road choice; with only one unlocked biome in a tier, there is no choice
to make (the screen is skipped).

## 4. The mechanics, as one small pattern

A hazard is a **node in the level scene** (`LevelHazard` base class, one custom script per mechanic: `OpenGraves`,
`DryGrass`, `Rockfall`, `Blizzard`, `Gloom`, `FallingWalls`, `CaveIns`, `Consecration`; the Marsh keeps
`MarshWater`). It:
- starts and stops with the fights (it listens to the level's `RunCycle`, like the spawner);
- announces itself with the existing `TelegraphMarker` (ground ring) and a banner the first time it comes;
- reads from a `HazardData` resource (interval, duration, damage, radius: balance never needs code);
- never touches the physics layers (areas and queries on existing layers).

## 5. Art and sound

Per new biome (all in code, `tools/art/`, double resolution):
- the **ground and props** (map art + environment art: today about 500 lines each per level);
- **1-2 enemies**, each about 100 frames in 4 facings (like the Cultist) and a death effect;
- **a boss**, with its telegraph and ability effects (about 150 frames);
- the **hazard's effects** (embers, snow, dust, light);
- **sounds**: about 6 new synthesized effects per biome (rockfall, wind, collapse, ...).
Stage 1 is the heaviest (the tier system and the first tier-3 biome); stages 2 and 3 are content.

## 6. Waves and rewards

- Each biome has its **own waves**: `tools/make_waves.py` grows a table per biome (a few of the tier's shared
  waves plus its own enemies' groups), and `data/run/<biome>/` holds the encounters (6 battles, 4 elites, 1
  boss).
- **Events:** the shared pool, plus two events per biome that mention the place (the Orchard's farmer, the
  Quarry's foreman).
- **Rewards** stay the chapter's (a card choice per battle, relics from elites and bosses), except that the
  tier-3 boss gives the victory, not a relic choice.

## 7. How it would fit the code (sketch)

- **`ChapterData`** gains `tier: int`, `blurb`, `mechanic_text`, `enemy_icons`, `difficulty_note`. A chapter
  is still the same resource: a biome *is* a chapter.
- **`RunData`:** `chapters` becomes `tiers: Array[TierData]` (`TierData.biomes: Array[ChapterData]`), or keeps
  `chapters` plus the tier number on each chapter (smaller change, recommended: Q9).
- **`RunState`:** `biomes: Array[ChapterData]` (the ones chosen so far); `get_chapter()` reads it;
  `offer_roads(tier)` draws two unlocked biomes from the seed; `choose_road(index)`. State only.
- **`RunUnlocks` / `UnlockData`:** `biomes` (unlock adds biomes to the pool, like `towers`).
- **`RunSave`:** saves the biome ids chosen; version +1 (older saves are chapter 1-2 of today's biomes).
- **Screens:** `ChapterScreen` gets two road cards (a `RoadCard` widget on `ScreenFrame`); the run summary
  and the Game Over screen name the biomes crossed; the map screen's title shows the biome.
- **Levels:** one scene per biome, built like the Marsh (`%Floor`, `ArenaBounds`, `%Ground` `TiledGround`,
  Camera2D limits: `test_arena_bounds` checks them), with its `LevelHazard` nodes.
- **Tests:** `test_biomes` (every biome: layout rule, lanes and slots counted, data complete, art present),
  one test per hazard, `test_roads` (the draw is seeded and fair, locked biomes never appear, the choice and
  the save), the existing tests run over every biome's level (`tests/run_tests.sh` already loads every scene).
- **Balance:** `map_balance.gd --biomes=a,b,c` (the three chapters of a run), `--protect-ch1/--protect-ch2`
  so a later chapter is measured with a real earlier build; the target: each biome within 20% of its tier's
  rows cleared, and a bot run through all three chapters winning sometimes.
- **Performance:** `perf_report.gd --biome=<id>` plays each biome's last wave; keep each at 60 fps 1% low at
  1080p (the Gloom's lights and the Blizzard's particles are the risks: Compatibility lights redraw
  everything they touch).

## 8. Build order

| Stage | Contents | Done when |
|---|---|---|
| 1 | `RunState` biomes, the road choice and its card, the save, the tier on `ChapterData`; **Open graves** for the Crypt Road; chapter 3 = **Ashen Keep** (map, ground, mechanic, 2 enemies, boss, waves, events); 3 chapters in a run | a full run crosses 3 chapters; the existing 2 biomes unchanged but for the Graveyard's mechanic; suite and balance green |
| 2 | **Ember Orchard, Frostbound Pass, Sunless Mines** (one new biome per tier) and their unlocks; roads to choose in every tier | each tier has a real choice; each biome plays differently |
| 3 | **Bone Quarry, Gloam Wood, Pale Cathedral** | 9 biomes; each within 20% of its tier |

## 9. Open questions (each with a recommendation)

| # | Question | Recommendation |
|---|---|---|
| Q1 | The nine biomes, their mechanics and bosses (section 2): right, or do you want other places? | **As proposed**; names and mechanics are easy to change before art starts. |
| Q2 | How is a biome chosen: random, or the player's choice? | **Chapter 1: from the seed. Chapters 2 and 3: the player picks one of two** (drawn from the seed), seeing mechanic, enemies and boss. |
| Q3 | Run length: 3 chapters of 8 rows is about 55-65 minutes for a win. | **Keep 8 rows for now.** `row_sizes` and `rows` are data, so shortening a chapter later is a data change after playtests. |
| Q4 | Should the extra biomes be War Room unlocks (section 3)? | **Yes**, the first of each tier free; prices as in the table. |
| Q5 | Enemies and bosses drawn in code at double resolution (the pipeline and style we have), 1-2 unique enemies and one boss per biome? | **Yes.** About 16 new enemies and 7 new bosses in all, spread over the stages. |
| Q6 | Are the mechanics allowed to hurt the hero and towers (falling walls burn out a slot, fire hurts the hero)? | **Yes, but telegraphed and small:** a warning of 2-3 s, a visible area, never more than one slot at a time, never a one-shot of the hero. |
| Q7 | The tier-3 bosses as three alternative finales (M11 gives each an ending)? | **Yes.** |
| Q8 | The Cathedral's mechanic: altars heal enemies (as written), or something else? | **As written** (it makes the player cover the altars with blasts, the Brazier's job). |
| Q9 | `ChapterData` keeps being the biome and gets a `tier` field (small change), or a new `BiomeData`/`TierData` layer (cleaner, bigger)? | **The field**: a biome is a chapter; no new layer until something needs it. |
| Q10 | Stage 1 is the heaviest: the tier system, the road choice, chapter 3 (Ashen Keep with 2 enemies and a boss) and Open graves. Split it (tier system and the road choice with the existing biomes first, a playtest build, then chapter 3)? | **Split it into 1a and 1b**, with a playtest build between: 1a is rules and screens only; 1b is a whole new biome. |
| Q11 | A new autoload, physics layer or input action? | **None needed.** (`allies` from M9 stays the last layer.) |

## 10. Decisions

On 2026-10-25 the user gave blanket permission to "push the project as far as you can" while away, so
every open question was taken at its **recommendation** (from: recommendation, under that permission):
Q1 as proposed, Q2 seed then player's choice, Q3 8 rows, Q4 unlocks as in section 3, Q5 art in code, Q6
telegraphed hazards that may hurt the hero and towers, Q7 three finales, Q8 the Cathedral's altars heal, Q9
the `tier` field on `ChapterData`, Q10 stage 1 split into 1a and 1b (no playtest build between: the user was
away), Q11 nothing new in autoloads, layers or inputs. Save points are git tags `save/m10-<stage>`.

**Stage 1a as built:** `ChapterData.tier` (0 = its place in the list), `blurb`, `mechanic_text`,
`difficulty_note`; `RunData.tier_of/tier_count/biomes_of_tier/find_chapter`; `RunState.biomes`,
`road_options()` (two unlocked biomes of the next tier from the seed, else the only one), `choose_road()`;
`UnlockData.biomes` and `RunUnlocks.locked_biomes`; the chapter screen shows road cards when there is a
choice; `RunSave` keeps the biome ids (older saves load as before); the run summary names the biomes.

**Stage 1b as built** (chapter 3, the Ashen Keep, and the first hazards):
- **Tools that make a biome** (new, dev-only): `tools/make_level.py` writes `levels/<id>.tscn` from
  `tools/levels/<id>.json` (floor, lanes, slots, colours, props, gates, particles, hazard nodes) on the Crypt
  Road's scene as template, and checks that slots keep clear of the roads; `tools/make_biome_data.py` writes the
  new enemies' data and a chapter's encounters and chapter file; `tools/make_waves.py` gained chapter 3's waves
  (built from a rule, lanes 0-3). Art: `tools/art/biome_art.gd` (ground from per-biome styles),
  `biome_props_art.gd` (props and the spawn gate), `variant_art.gd` (see below).
- **Enemy variants:** a new enemy can be an existing one in other colours (`variant_art.gd` remaps the base
  sheet's ramps): Siege Ram (Brute), Black Knight (Shieldbearer), the Fallen Marshal (Colossus, with its charge
  and a frontal shield). What differs in play is data and ability; sprites of their own are for M13's art pass.
- **Hazards:** `LevelHazard` (a node that runs while a wave is on and strikes on a timer from a `HazardData`),
  `FallingWalls` (the Keep: a ring warns, then enemies, hero and minions in it are hurt and the nearest tower is
  silenced for 12 s: the design's "burns out the slot" became a silence, because towers have no HP and a ruined
  slot would need its own rebuild UI) and `OpenGraves` (the Crypt Road: Ghouls climb out in the middle of a
  road, `WaveSpawner.spawn_at`; the wave waits for them).
- **Balance** (`map_balance.gd --protect-ch2`, 4 seeds, the bot): chapter 3 dies at row 2-4, about where chapter
  2 does with chapter 1 protected (3.3); `fight_health_scale` 2.0 (not the proposal's 2.6) and waves starting at
  x0.6. The tool now takes a plan for any level (the hero's kit on the slots nearest the fortress).
- **Left for later:** the Keep's own events (two were planned; it uses the shared pool), its own sounds.

**Stages 2 and 3 as built** (the other six biomes; 9 in all, 3 per tier):

| Tier | Biome | Mechanic (class) | Unique enemies | Boss |
|---|---|---|---|---|
| 1 | Crypt Road | Open Graves (`OpenGraves`) | - | Lich Warden (shared finale) |
| 1 | Ember Orchard | Dry Grass (`DryGrass`: fire catches from burning ground and burning enemies; hurts the hero too) | Cinder Ghoul (fire where it falls), Scarecrow (decoy) | Pyre Warden |
| 1 | Bone Quarry | Rockfall (`CaveIns`, two rocks) | Bone Hurler (silences a tower), Rubble Brute | Quarry Colossus |
| 2 | Drowned Marsh | wading pools | Bloater, Mire Priest, Shieldbearer | Tollkeeper |
| 2 | Frostbound Pass | Blizzard (`Blizzard`: -20% range, +10% enemy speed for 8 s) | Frost Wraith (chill ring), Rime Brute (slow-immune) | Winter Warden |
| 2 | Gloam Wood (4 roads) | Gloom (`Gloom`: 70% range away from the 3 lamps) | Stalker (unseen beyond 90 px), Hollow Treant (mends) | Hollow Stag (roots) |
| 3 | Ashen Keep | Falling Walls | Siege Ram, Black Knight | Fallen Marshal |
| 3 | Sunless Mines | Cave-ins (`CaveIns`, rubble holds the dead) | Burrower (skips ahead), Lamp Wight (heals) | Deep Warden |
| 3 | Pale Cathedral | Consecration (`Consecration`: altars heal, fire covers) | Chorister (-20% damage aura), Inquisitor (marks the hero) | Pale Bishop |

- New plumbing: `EnemyData.decoy / slow_immune / stealth_range`, `HealthComponent.resist`, `Hero.chill / hold`,
  `Tower.set_weather_range`, `Enemy.weather_speed`, `Groups.BURN_ZONES`, abilities `DeathFire`, `Chill` (a Toll with
  a hero chill), `Burrow`, `Shard`, `Regen`, `ResistAura`, `MarkHero`, `Root`, bosses' `Freeze` (a Toll) and the
  summon variants. `HazardData` per mechanic in `data/hazards/`.
- Unlocks: each extra biome is a War Room unlock (40-120 shards, needing a boss beaten or a chapter reached) and
  stays locked under the test harness (like perks), so tests and tools play Crypt Road, Marsh and Ashen Keep.
- Enemy sprites are the base enemy's sheet in new colours (`variant_art.gd`), to be replaced by real art in M13's
  pass; the Marsh's and the first biomes' ids and names are unchanged.
- **Balance** (`map_balance.gd --biomes=<ids>`, 6 seeds, the bot; rows cleared): tier 1: Crypt Road 5.5, Ember
  Orchard 4.2 (scale 0.6), Bone Quarry 3.7 (then 0.5), all with the generic plan; tier 2 (chapter 1 protected):
  Marsh 10.5, Frostbound Pass 8.7 (scale 1.6 -> 1.5), Gloam Wood 8.2 (1.6 -> 1.45); tier 3 (chapters 1-2
  protected): Ashen Keep 17.2, Sunless Mines 17.8, Pale Cathedral 17.8.
- **Left out of the design:** ice patches on the Pass, buying lamps in the Gloam Wood (lamps are fixed), the
  biomes' own events (M11 writes them), the Pass/Wood/Cathedral having only the shared sounds plus `gale`.

## As built, follow-up: smoother tier-3 waves (M13 balance trace)

A trace of the bot at chapter 3 showed row 2 (waves 3-4) was ~x2.9 the enemy HP of row 1, against ~x1.7 in every
other chapter: `wave_3()` added Brutes and Shieldbearers at wave 3 and Black Knights at wave 4, all at full count.
Even with no heavy enemy at all, the old health line (0.6 + 0.18 (n - 1)) gives x1.84 from row 1 to row 2, so the
line itself had to start higher. Now (`tools/make_waves.py`):

- `mult_3(n)`: the health multiplier of waves 1-6 is 0.8, 0.886, 1.011, 1.157, 1.319, 1.494; from wave 7 it is the old
  line (so rows 5 and up are unchanged).
- The heavy enemies arrive one kind at a time and grow to their count over a few waves (`ramp_in`): Rams from wave 2
  (as before), Shieldbearers from 4, Brutes from 5 (Mines and Cathedral: from 4 over 6 waves), Black Knights from 8,
  the Cathedral's Inquisitors over 6 waves from wave 4.

Row-to-row steps in total enemy HP (average of the row's two waves), before -> after:

| Biome | r1>r2 | r2>r3 | r3>r4 | r4>r5 | r5>r6 |
|---|---|---|---|---|---|
| Ashen Keep | 2.92 -> 1.80 | 1.77 -> 1.80 | 1.56 -> 1.80 | 1.39 -> 1.58 | 1.33 -> 1.33 |
| Sunless Mines | 2.63 -> 1.80 | 1.66 -> 1.79 | 1.48 -> 1.57 | 1.39 -> 1.47 | 1.31 |
| Pale Cathedral | 2.76 -> 1.75 | 1.70 -> 1.79 | 1.50 -> 1.66 | 1.38 -> 1.54 | 1.31 |

Row 1 is ~21% harder (2329 -> 2817 average at the Keep), rows 2 and 3 ~25% easier. Bot at chapter 3 (`--start=3`, 8
seeds, rows cleared of 8): Knight 1.2 -> 1.6, Huntress 1.0 -> 0.6, Necromancer 1.0 -> 1.2, Knight with a 15:3:3000
kit 2.6 -> 3.0: within the bot's noise; the smoother steps did not by themselves let it survive chapter 3 (the bot's
fixed tower plan is the limit). Chapter 1's own steps are still uneven (x2.99 at row 2 to 3, x2.41 at row 4 to 5 in
Crypt Road); not changed.

