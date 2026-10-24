# M9: Heroes & Relics (design proposal)

> **Status: approved (section 10). Stage 1 built; stages 2-4 to do.** The numbers are starting points
> for the balance tools (`map_balance.gd`, `balance_report.gd`).

## 0. Summary

- **Three heroes:**
  - **the Knight** (today's hero, unchanged);
  - **the Huntress**, ranged: a crossbow and traps;
  - **the Necromancer**, a summoner: the dead fight for her.
  - Each has their own sprite sheet (drawn in code at the double resolution, like the knight), stats,
    attack and one passive.
  - All three share the dash.
- **Each hero brings their own towers.** The Archer and the Cannon are shared by everyone. Each hero has
  3 exclusive towers:
  - **the Knight** keeps the Brazier, the Frost tower and the Bone Ballista;
  - **the Huntress** gets the **Trap Layer**, the **Hawk Perch** and the **Watchtower**;
  - **the Necromancer** gets the **Bone Pit**, the **Soul Siphon** and the **Ossuary**.
  - The build menu shows the 2 shared towers and the hero's 3. That's still 5 towers, as today.
- **Hero cards and relics:**
  - each hero has 4 exclusive cards in the pool beside the shared ones (22 today), so 12 new cards;
  - each hero has 2 exclusive relics, so 6 new relics.
- **Archetypes:**
  - every card, relic and tower gets one or two tags: *fire, frost, blade, ranged, summon, traps,
    economy, fortress*;
  - once a run holds 2 or more cards of a tag, offers lean toward that tag (×1.6 weight);
  - a run can commit to a plan without the offers being fixed.
- **Combo evolutions:** a third evolution, shown next to the two usual branches only while the run holds
  a specific relic:
  - Brazier + Ember Heart;
  - Frost + Hourglass;
  - Bone Ballista + Executioner's Mark;
  - one for each new hero's signature tower and relic.
  - 6 in all.
- **Hero choice:** in the War Room, before "Start a run". The Knight is free; the Huntress and the
  Necromancer are unlocked with Soul Shards (60 and 90). No hero is stronger, they're different.
- **Built in 4 stages**, each tested, balanced and playable on its own:
  1. the hero framework (the Knight as data);
  2. the Huntress;
  3. the Necromancer;
  4. archetypes and combo evolutions.
- **No new autoload or input action.** One open question is whether the minions need a physics layer
  (Q3).

## 1. Why three heroes, and what makes them differ

M9's goal (ROADMAP): *picking a different hero or finding a key relic changes how you play the run.*

A hero changes three things, not just numbers:
- **how you fight** (the attack);
- **where you stand** (melee in the crowd, behind the line, or at the corpses);
- **what you build** (their towers).

| | The Knight | The Huntress | The Necromancer |
|---|---|---|---|
| Fantasy | the wall: holds the line in the crowd | the skirmisher: picks targets, sets the field | the gravecaller: the more die, the bigger her army |
| Attack (LMB) | sword arc, 68 px, 10 dmg, 0.4 s | crossbow bolt, 340 px, 9 dmg, 0.55 s, pierces 1 | soul bolt, 220 px, 6 dmg, 0.45 s; a kill it lands raises a skeleton |
| HP / speed | 100 / 200 | 75 / 215 | 80 / 195 |
| Passive | **Bulwark:** hits taken while swinging do 25% less | **Mark:** her bolts mark the enemy; towers deal +15% to marked enemies for 3 s | **Raise Dead:** up to 3 skeletons at a time (30 HP, 6 dmg melee, they walk to the nearest enemy and fight; 20 s) |
| Plays | in the middle of the lane; dash out | behind the towers, marks for them, kites | near the killing fields; keeps her minions busy |
| Weak at | Cultists at range, being swarmed | crowds at the gate, enemies reaching her | single big targets (bosses); skeletons die fast |
| Towers (exclusive) | Brazier, Frost, Bone Ballista | Trap Layer, Hawk Perch, Watchtower | Bone Pit, Soul Siphon, Ossuary |

Why ranged and summoner: they are the ROADMAP's examples, and they cover the two things the Knight
can't do. The Huntress fights from the back and boosts the towers. The Necromancer fights with numbers
instead of her own blade. The dash stays shared: one key, one known escape.

## 2. The new towers

The same `TowerData` / `TowerEvolution` system as today: 3 levels, then two evolution branches. The
prices are in the range of today's towers (50–120 gold to build).

### 2.1 The Huntress's towers

| Tower | Cost | What it does | Level 3 | Evolutions (A / B) |
|---|---|---|---|---|
| **Trap Layer** | 60 | Every 4 s throws a snare onto the road within 150 px: the first enemy on it is held for 1.2 s and takes 20 damage. Up to 3 snares lie at a time. | 3 s, 5 snares, 35 dmg | **Bear Pit** (a snare holds 2.5 s and holds bosses for 0.8 s) / **Caltrop Field** (snares become a 3 s spiked patch: 12 dmg/s, slows 40%) |
| **Hawk Perch** | 75 | A hawk flies out (range 320) and dives on the enemy furthest along: 18 damage every 1.6 s. Never blocked by shields (from above). | 28 dmg, 1.3 s | **Falconer** (two hawks) / **Eye of the Hunt** (the hawk marks: the Huntress's Mark from every dive) |
| **Watchtower** | 90 | No attack: towers within 200 px get +15% range and see marked enemies first. The Huntress gains +10% damage while within 200 px of it. | +25% range | **Signal Fire** (+15% fire rate nearby) / **Sniper's Nest** (fires itself: 60 dmg every 3 s at range 420) |

### 2.2 The Necromancer's towers

| Tower | Cost | What it does | Level 3 | Evolutions (A / B) |
|---|---|---|---|---|
| **Bone Pit** | 70 | Every 8 s raises a skeleton on the nearest road (range 180) that blocks and fights (40 HP, 5 dmg). 2 at a time. | 6 s, 3 at a time, 60 HP | **Charnel Gate** (the skeletons are knights: 120 HP, they taunt) / **Plague Pit** (a skeleton bursts when it falls: 40 damage around it) |
| **Soul Siphon** | 85 | A beam on one enemy (range 170): 14 dmg/s, ramping +50% over 3 s on the same target. 1 soul per kill. | 24 dmg/s | **Soul Harvester** (a kill heals the fortress 1 HP, up to 10 a wave) / **Wither Beam** (the beam jumps to a second enemy) |
| **Ossuary** | 100 | Stores souls from deaths within 200 px (up to 20). At 20 it releases them: 80 damage to every enemy within 200 px. | 15 souls, 120 dmg | **Bone Storm** (also raises 3 skeletons) / **Death Knell** (the blast also slows 50% for 3 s) |

### 2.3 Combo evolutions (stage 4)

A third choice beside the usual two. It shows (with the relic's icon) only while the run holds the
relic, and costs the same as the others.

| Tower + relic | Combo evolution | What it does |
|---|---|---|
| Brazier + Ember Heart | **Heart of the Pyre** | the flames' burn also spreads to one enemy next to the burning one |
| Frost + Hourglass | **Stillwater** | every 10 s, freezes every enemy in range for 1 s (bosses 0.3 s) |
| Bone Ballista + Executioner's Mark | **Headsman's Bolt** | its bolts execute below 25% HP instead of the relic's 12% (not bosses) |
| Hawk Perch + *Falcon's Hood* (new relic) | **Sky Tyrant** | the hawk carries a small enemy off (any non-boss under 40 HP) |
| Bone Pit + *Grave Crown* (new relic) | **Legion** | skeletons rise in pairs |
| Archer + Twin Banners | **Banner Guard** | arrows of nearby archers pierce 1 more |

## 3. Hero cards and relics

Each hero adds 4 cards to the offers (only that hero's run sees them) and 2 relics.

| Hero | Cards (tags) | Relics |
|---|---|---|
| Knight | **Shield Bash** (dash knocks enemies back 30 px; blade), **Oathkeeper** (+1 sword hit per swing on bosses; blade), **Rally** (towers within 150 px of the Knight +10% fire rate; blade, ranged), **Iron Will** (Bulwark 25% → 45%; fortress) | **Crown of Thorns** (enemies hitting the Knight take 8), **Banner of the Last Keep** (while the Knight is alive, the fortress takes 15% less) |
| Huntress | **Barbed Bolts** (bolts pierce +1; ranged), **Quick Hands** (reload 20% faster; ranged), **Snare Mastery** (Trap Layer snares +0.5 s; traps), **Hunter's Mark** (Mark +10%, 5 s; ranged) | **Falcon's Hood** (combo, above), **Quiver of Plenty** (every 5th bolt fires 3 in a fan) |
| Necromancer | **Bone Armour** (skeletons +50% HP; summon), **Gravecaller** (skeletons 4 at a time; summon), **Soul Feast** (each skeleton that falls heals her 5; summon), **Dark Bargain** (soul bolts +40% damage, max HP −20; summon) | **Grave Crown** (combo, above), **Reliquary of Bones** (kills by skeletons fill Ossuaries twice as fast) |

Today's 22 shared cards and 15 relics stay shared. Some fit one hero better (Long Reach is a sword
card): those are **re-tagged** per hero (Long Reach only in the Knight's pool, Section 4), rather
than offered to a Huntress who can't use them. The hero-only list:
- the Knight: Honed Blade, Long Reach, Battle Rhythm, Berserker's Oath;
- the Huntress: none of today's cards;
- the Necromancer: none of today's cards.

The other 18 cards are shared.

## 4. Archetypes (stage 4)

| Tag | Cards / relics / towers today (examples) |
|---|---|
| fire | Hellfire Shells, Cinder Dash, Ember Heart, the Brazier |
| frost | Deep Freeze, Hourglass, the Frost tower |
| blade | Honed Blade, Long Reach, Battle Rhythm, Berserker's Oath, Bloodpact |
| ranged | Keen Fletching, Eagle Eye, Rapid Reload, Piercing Arrows, the Archer |
| summon | the Necromancer's cards, Bone Pit, Ossuary |
| traps | Snare Mastery, Trap Layer |
| economy | Bounty Hunters, Treasury, Guild Discount, War Tax, Merchant's Seal |
| fortress | Stout Masonry, Thorned Walls, Emergency Repairs, Iron Tithe |

**The lean:**
- a card whose tag the run already holds 2 or more of is drawn with weight ×1.6, and ×2 at 4 or more;
- the HUD's upgrade row shows the run's leading tag ("Fire build").

Measured with `map_balance.gd`: no archetype should win more than 1.5× the others.

## 5. Hero choice and unlocks

- **In the War Room:**
  - three portraits above "Start a run";
  - a locked hero shows its price;
  - picking one shows their attack, passive and towers in two lines each.
- **Unlocks (the M8 board):**
  - the Huntress: 60 shards, after the first chapter-1 boss is beaten;
  - the Necromancer: 90, after a run that reached chapter 2;
  - each new hero's towers come with them: the hero's first unlock gives all 3 towers, and their
    evolutions are separate unlocks (30 each), like today's.
- **The save:**
  - adds `hero` (the last one picked) and per-hero records (best run, wins);
  - versioned like M8's, migrated from version N (no hero: the Knight).
- **The run summary and Game Over** name the hero.
- **`RunState.hero`** holds the run's hero, saved with a run in progress.

## 6. Art and sound

- **Every hero:**
  - drawn in code at the double resolution (`Canvas.detail`, like the Knight), with the Knight's 13
    rows (idle, walk, attack, death, dash in 3 facings);
  - plus a portrait for the War Room (64×64 art px).
- **The towers:**
  - each new tower has 3 levels and 2 evolutions, plus its shots and effects;
  - that's 6 towers, about 90 frames each in `TOWERS` (today 263 for 15 tower looks).
- **Summons:** the skeleton minion (walk, attack, death).
- **Sound:** about 18 new synthesized sounds:
  - the crossbow and the soul bolt;
  - snares and hawk cries;
  - beams and bursts;
  - raising a skeleton;
  - the War Room's hero pick.

## 7. How it would fit the code (sketch)

- **`HeroData` (new Resource, `data/heroes/`):**
  - id, name, sprite frames, stats (HP, speed, attack kind and values), passive id;
  - `exclusive_towers`, `exclusive_cards`, `exclusive_relics`;
  - unlock id.
  - The Knight's values move out of `hero.tscn`'s exports into `knight.tres`. **Stage 1 changes no
    behaviour**, checked by every existing test.
- **The attack becomes a component:**
  - `HeroAttack` with `SwordAttack` (today's code), `BoltAttack` (Huntress, Necromancer) and the
    on-kill hook;
  - the hero scene picks it from `HeroData`;
  - one base class (`HeroAttack`), as the shallow-inheritance rule allows.
- **Minions:**
  - `Minion` (CharacterBody2D), with a `HealthComponent`, a `Hurtbox` masking `enemy_hitbox` and an
    `AttackerLimit`;
  - enemies already target any body in their AttackRange on the `hero` layer, so minions on that
    layer are attacked like the hero;
  - the hero-only things that also watch that layer must then check for the hero: the build-slot
    prompt, the Ossuary Bell's bones, the marsh water and the Quartermaster;
  - Q3 asks whether to add an `allies` layer instead.
- **Towers:**
  - `TowerData` gains `kind` (shooter, trap, hawk, aura, summoner, beam, ossuary);
  - the shared `tower.tscn` picks a behaviour component per kind;
  - the build menu's catalog = shared + `HeroData.exclusive_towers`, filtered by `RunUnlocks` as today.
- **Offers:** `UpgradeData.tags`; `UpgradeOffers` weighs by the run's tags; `HeroData.exclusive_cards`
  join the pool.
- **Evolutions:** `TowerEvolution.requires_relic`; the evolution screen shows the combo when
  `RunModifiers.has_relic()` is true.
- **Saves:** `SaveProfile` version +1 (`hero`, records per hero) with a migration and a fixture;
  `RunSave` adds `hero`.
- **Tests:**
  - `test_hero_data`: the Knight from data matches today;
  - `test_huntress`: bolt, pierce, Mark on towers;
  - `test_necromancer`: raise on kill, the minion cap, enemies fight minions, minions expire;
  - `test_new_towers_m9`: each tower's rule;
  - `test_archetypes`: offer weights;
  - `test_combo_evolutions`: shown only with the relic;
  - `test_save_migration`: the older save loads as the Knight.
- **Balance:**
  - `hero_bot.gd` learns a ranged policy (keep 150–300 px from the nearest enemy, aim at the furthest
    along) and a summoner policy (stay near the busiest lane);
  - `map_balance.gd --hero-kind=knight|huntress|necromancer`;
  - goal: each hero within ±20% of the Knight's rows cleared per run.

## 8. Build order (each stage tested, balanced, playable)

| Stage | Contents | Done when |
|---|---|---|
| 1 | `HeroData`, `HeroAttack`, the hero choice in the War Room (the Knight only), the save's `hero`, `TowerData.kind` | every existing test passes; the Knight plays exactly as today |
| 2 | The Huntress: sheet, portrait, bolt, Mark, her 3 towers (art, evolutions), 4 cards, 2 relics, the bot's ranged policy | her runs clear within ±20% of the Knight's rows |
| 3 | The Necromancer: sheet, portrait, soul bolt, minions, her 3 towers, 4 cards, 2 relics, the summoner policy | the same, and a full-screen wave with 3 skeletons and 6 Bone Pit skeletons above 60 fps 1% low at 1080p |
| 4 | Archetype tags and the lean, combo evolutions (6), the HUD's build label | no archetype wins more than 1.5× the others |

## 9. Open questions (each with a recommendation)

| # | Question | Recommendation |
|---|---|---|
| Q1 | Three heroes in M9, or the Knight plus one? | **Three**, built as stages 2 and 3: two new heroes show that heroes really differ, and stage 2 can be playtested before stage 3 starts. |
| Q2 | Which two new heroes? | **The Huntress (ranged) and the Necromancer (summoner)**, the ROADMAP's examples: they cover what the Knight can't do. |
| Q3 | Minions on the `hero` physics layer (no layer change; the hero-only systems check for the hero), or a new `allies` layer (CLAUDE.md: changing physics layers needs your OK)? | **A new `allies` layer (#9)**: cleaner, nothing hero-only can trigger by accident. Enemies' AttackRange would mask `hero` + `allies`. |
| Q4 | Does each hero need an active ability on a new key (an input action, which needs your OK)? | **No, not in M9:** the attack, a passive and the dash are enough to make them differ; an ability key can come in M12 with the challenge modifiers if playtests ask for it. |
| Q5 | Should today's sword cards (Honed Blade, Long Reach, Battle Rhythm, Berserker's Oath) become Knight-only? | **Yes**: a Huntress offered Long Reach is a wasted pick. |
| Q6 | The prices for unlocking the heroes (60 and 90 shards)? | **As proposed**: about 2–3 runs each at the shard pace measured in M8. |
| Q7 | Do the archetype lean's weights (×1.6, ×2) fit, or should the lean be stronger (e.g. one guaranteed tag card per offer)? | **The soft weights first**, measured with `map_balance.gd`; a guaranteed card can follow if runs still feel random. |
| Q8 | Playtest after stage 2 (the Huntress) before building the Necromancer? | **Yes**, a build `m9-playtest-1` after stage 2, if you want to play it; otherwise stages 2–4 straight through. |
| Q9 | The art: the new heroes and their towers drawn in code at the double resolution (as the Knight now), or wait for an art pack? | **In code**, like everything since the art pack (`docs/ART_HANDOFF.md`): the pipeline exists and keeps the style consistent; a later art pack can replace sheets with the same layouts. |

## 10. Decisions

All recommendations of section 9 were approved. Q3: minions get a new `allies` physics layer (#9; the
layer table in CLAUDE.md is updated in stage 3, when it is first used). Q8: pause after stage 2 for a
playtest build `m9-playtest-1`.

**Stage 1 as built** (the Knight plays exactly as before; the full suite passes):
- `HeroData` (`resources/hero_data.gd`, `data/heroes/knight.tres`): id, name, description and the stats
  the Hero scene reads in `_ready` (HP, speed, hit damage, cooldown, duration, knockback).
  `RunData.heroes` lists the heroes of a run; the first is the default.
- `RunState.hero` holds the run's hero; Main sets it on the level's Hero before the level enters the tree.
  `RunSave` and `RunSummary` carry its id.
- `SaveProfile` version 3 adds `hero` (the pick for the next run; older saves migrate to the Knight,
  `tests/fixtures/save_v2.json`). The War Room shows the hero of the next run.
- **Deferred to stage 2, where they are first needed** (CLAUDE.md rule 1, no scaffolding): the
  `HeroAttack` component with `SwordAttack` / `BoltAttack`, `TowerData.kind`, the hero picker with
  locked heroes and prices, and the Knight's Bulwark passive (it changes Knight behaviour, so it comes
  with the Knight cards that raise it).
