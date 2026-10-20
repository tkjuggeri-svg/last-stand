# M7 — Run Map: design proposal

> Status: **proposal, waiting for approval.** Nothing here is implemented. Numbers are starting points
> to be tuned with the balance tool, like everything else in `GAME_DESIGN.md`.

## 0. Summary

- A run becomes **3 chapters**. Each chapter is a Slay the Spire–style map of **8 rows** (7 rows of
  choices, then the chapter boss), about **18 nodes**, of which a run visits **8 per chapter**.
- **Chapter 1 is today's game.** Its battles use today's 15 waves, split into 2-wave encounters by
  row, so a typical chapter 1 path plays 12–15 of those waves and keeps the M6.5 balance (the
  decided first-chapter target).
- **Inside a chapter, the map and the defence stay.** Towers stay built between battles, the
  fortress keeps its damage, and gold and upgrades carry over. **Between chapters,** the towers are
  packed up for gold and the next chapter starts on a fresh field.
- Chapters 2 and 3 **ramp up from the chapter 1 baseline** (HP, speed, enemy mixes, elite affixes).
  Until M10 brings new maps, they reuse the current arena with different lane pressure.
- **Node types:** battle, elite, merchant, shrine (a risky deal), event (text + choice) and boss.

## 1. Map shape and run length

### 1.1 Chapter map
```
row 8   ......................  [BOSS]  ......................
row 7      [merchant]      [merchant]      [merchant]           (the last stop before the boss)
row 6   [battle]   [shrine]    [elite]    [event]
row 5      [event]    [battle]    [battle]   [merchant]
row 4   [elite]    [battle]    [event]    [battle]
row 3      [battle]   [shrine]    [event]
row 2   [battle]          [battle]          [battle]
row 1         [battle]           [battle]                       (start: pick one)
```
- **Size:** 8 rows. Rows 1–7 have 2–4 nodes each, about 18 nodes in all.
- **Paths:** each node links to 1–2 nodes in the next row, and links never cross, so the map reads
  at a glance. Every node is reachable, and every path ends at the boss.
- **Generation:** seeded from the run seed, so runs are reproducible for tests, the balance tool
  and bug reports.
- **Fixed rows:**
  - rows 1–2 are always battles (the opening stays a gentle tutorial);
  - row 7 is always merchants (a last chance to spend before the boss);
  - row 8 is the boss.
- **Mixed rows (3–6):** drawn from the odds in section 2, with these rules:
  - no elite before row 3;
  - no two shrines in a row on one path;
  - no merchant in rows 3–6 directly below a row-7 merchant link (avoids back-to-back shops);
  - every path holds at least 2 battles or elites in rows 3–6, so no path skips most of the
    chapter's fighting.

### 1.2 Run length

| | Nodes visited | Waves fought (typical) | Time (with ~30 s build phases) |
|---|---|---|---|
| Chapter (combat-heavy path) | 8 | 14–15 | ~20 min |
| Chapter (balanced path) | 8 | 12–13 | ~17 min |
| Chapter (event-heavy path) | 8 | 10–11 | ~14 min |
| **Full run (3 chapters)** | 24 | ~38 | **~50–60 min** |

- A chapter stays close to today's 15-wave run (18 minutes).
- A death in chapter 1 still costs about 15 minutes, as today. A full win is a ~1-hour run, the
  normal length for the genre.
- **M7 scope suggestion:**
  - build all 3 chapters, so the carry-over and the ramp are real;
  - only chapter 1 gets polished content;
  - chapters 2–3 reuse the arena and the current enemies and bosses, with ramped numbers and elite
    affixes;
  - M10 later replaces them with new maps, enemies and bosses.

## 2. Node types and odds

Odds for the mixed rows (3–6):

| Node | Share | What happens |
|---|---|---|
| **Battle** | ~45% | 2 waves of the row's tier. Kill gold as today, and the upgrade choice after each wave as today. |
| **Elite** | ~15% | 2 waves of the row's tier plus an **affix** (below) and a mini-boss: the Gravelord in rows 3–4, the Bone Colossus in rows 5–6. Reward: a **rare-only** upgrade choice and +100 gold. |
| **Event** | ~20% | A short scene with 2–3 choices (section 5). No fighting, unless a choice brings one. |
| **Shrine** | ~12% | One risky deal: accept or walk away (section 6). |
| **Merchant** | ~8% (+ all of row 7) | Spend gold: 3 upgrade cards (common 90 g, rare 160 g), a cheap repair (+25% of the fortress, 60 g, once per visit), a reroll of the cards (25 g). Relics join the stock in M9. |
| **Boss** | row 8 | 3 waves; the chapter boss leads the last one. Chapter 1: the Lich Warden on today's wave-13–15 content. Reward: 1 of 3 rare upgrades and +40% fortress repair. |

**Elite affixes** (one per elite, shown on its map node):
- *Swift*: regulars +25% speed.
- *Warded*: every enemy spawns with a 30-damage ward.
- *Swarming*: 50% more enemies at 65% HP each.
- *Siege*: Cultists replace half the Ghouls.
- *Ironclad*: Brutes ×2, +30% HP.

**How waves map to rows (chapter 1):**
- Each row has a **wave tier**: row *r* plays today's waves 2*r*−1 and 2*r*.
  - row 1: waves 1–2;
  - row 2: waves 3–4;
  - …
  - row 7: waves 13–14;
  - the boss: waves 13–15 at the boss's rule, with the Lich in the last.
- Difficulty follows **depth, not the number of battles fought** (as in Slay the Spire). Skipping a
  battle means less gold and fewer upgrade picks before harder tiers. That trade is what makes
  events and shrines a real choice.
- **The wave generator** (`tools/make_waves.py`) gains tiers. Each row gets 2–3 encounter
  variants (the same budget with different lane mixes), so the same row doesn't always play the
  same.

## 3. What carries between nodes

| | Inside a chapter (between nodes) | Between chapters |
|---|---|---|
| **Towers** | **Stay built** on their slots, with their levels and evolutions. The battlefield is the same map, and building up the defence over a chapter is the core of today's game. | **Packed up**: every tower is sold for **100%** of what was spent on it (not 50%), as gold. The next chapter starts with an untimed build phase on a fresh field. |
| **Gold** | Carries. | Carries (plus the packed-up towers). |
| **Fortress HP** | Carries: damage stays. Repairs come from the Quartermaster (between waves), merchants, events and the boss reward. | +50% of max restored, then carries. |
| **Hero HP** | Full after each wave and node (as today). | Full. |
| **Hero lives** | Carry for the whole run (3). The Quartermaster's buy-back becomes **once per chapter**. | Carry. |
| **Run upgrades** | Carry for the whole run. | Carry. |
| **Evolutions** | Stay with their tower. | Refunded with the tower. They can be bought again, so a chapter-3 defence can be built around different branches. |

**Why towers stay within a chapter:** the M6.5 balance assumes a defence that grows over 15
waves. Rebuilding per battle would turn every battle into a cold start, and the build-up is the
part the playtest liked.

**Why a full refund between chapters:** chapter 2 starts at a much harder tier on a new field. A
50% refund would punish the player for having built well, and the ramp is meant to come from the
enemies, not from the reset. Alternatives are open question Q2.

## 4. Difficulty ramp per chapter

Chapter 1 = the M6.5 baseline, unchanged. Later chapters continue its curve:

| | Chapter 1 (baseline) | Chapter 2 | Chapter 3 |
|---|---|---|---|
| Regulars' HP multiplier, row 1 → boss | 1.0 → 2.35 (today) | 2.0 → 3.8 | 3.4 → 5.8 |
| Speed multiplier | 1.0 → 1.1 | 1.05 → 1.18 | 1.1 → 1.25 |
| Enemy mix | today | more Brutes and Cultists from row 1; Hounds in bigger packs | every lane pressed every wave; two Cultist groups per wave |
| Kill gold per wave (regulars) | 64 → 350 (today) | ~350 → 450 | ~450 → 550 |
| Elite share / affixes | 15%, 1 affix | 18%, 1 affix | 20%, 2 affixes |
| Chapter boss (until M10) | Lich Warden 3,600 HP | the Colossus and Lich together, ×1.4 HP | all three bosses in the last wave, ×1.8 HP |

- **Gold rises per chapter** because the player rebuilds a bigger defence each chapter (the
  refund helps). Evolutions are the main source of power growth in chapters 2–3.
- **Tuning targets** (balance tool with map runs):
  - chapter 1: unchanged (idle never wins; bot ~10% with evolutions);
  - the bot should almost never clear chapter 2, and a strong bot build should clear chapter 1
    then fall in chapter 2;
  - a good human should clear chapter 1 narrowly and need a strong build for chapter 3.
  - Playtests set the final numbers.
- **M12 difficulty levels** multiply on top of these per-chapter numbers, never change chapter 1's
  baseline (`GAME_DESIGN.md` 3.).

## 5. Example events (5)

1. **The Gravedigger's Cart.** A cart of coffins is stuck in the mud on the west road.
   - *Push it free:* +60 gold.
   - *Pry the coffins open:* +150 gold, but the next battle sends 4 extra Ghouls per wave.
   - *Leave it.*
2. **The Wounded Knight.** A knight of your order lies by the road.
   - *Tend his wounds (60 gold):* he joins the walls, and the fortress gains +15 max HP for the
     rest of the run.
   - *Take his sword:* the hero gets +4 sword damage, and his ghost haunts you: the hero's max HP
     is −15 for this chapter.
   - *Leave him.*
3. **The Flooded Crypt.** Water runs out of a crypt door; something knocks from inside.
   - *Open it:* fight one extra wave of the next row's tier right now. Reward: a rare upgrade
     choice.
   - *Seal it with stone:* the fortress takes 10 damage (you pull stones from its walls).
   - *Walk past.*
4. **The Tinker.** A travelling engineer offers his tools.
   - *Upgrade your cheapest tower one level, free.*
   - *Trade:* lose your most recent upgrade and gain 120 gold.
   - *Decline.*
5. **The Night Fog.** A fog rolls in over the fields.
   - *March on:* the next battle's enemies are 15% faster but pay 50% more gold.
   - *Wait it out:* nothing happens, but the next merchant's prices rise 20% (the roads were
     closed).

## 6. Example shrine deals (5)

Each shrine offers one deal: accept or walk away. A shrine's deal is always visible before you
choose (no hidden cost), except the gamble, which says it is one.

1. **Shrine of Blood:** lose 1 hero life → choose 2 rare upgrades (two separate choices).
2. **Shrine of Ash:** your highest-level tower crumbles (no refund) → your next evolution is free.
3. **Shrine of Coins:** double your gold now → kill gold is −50% for the next 2 battles.
4. **Shrine of Hollow Walls:** fortress max HP −25 for the run → all towers +15% damage for this
   chapter.
5. **Shrine of Whispers (gamble):**
   - 50%: a free rare upgrade of your choice;
   - 50%: an elite affix of the shrine's choosing on every battle for the rest of the chapter.

## 7. How it would fit the code (sketch, for the approval)

- **`RunState`:** the run's seed, chapter, map, current node, gold, lives, upgrades taken and
  fortress HP. It's one of the two autoloads `CLAUDE.md` already allows; M7 would create it.
  `Economy`, `RunModifiers` and `HeroLives` keep working per level but load from and save to it
  at chapter boundaries. That changes the "per-level systems" rule in `CLAUDE.md`, which I'd update
  with the code.
- **Map screen and flow:**
  - a `MapScreen` (UI) shows the chapter map and asks `RunMap` (data, seeded generation, rules)
    for the reachable nodes;
  - `Main` switches between the map, node screens (event, shrine, merchant) and the level;
  - **the chapter's `Level` instance stays alive** (paused and hidden) while the map is shown, so
    towers persist without saving them.
- **Battles on that level:** a battle node gives the level's `WaveSpawner` that node's waves, and
  `RunCycle` runs them as today.
- **Data:**
  - `EventData`, `ShrineData` and `EncounterData` resources in `data/` (so balancing stays out of
    code);
  - elite affixes are wave modifiers, like `health_multiplier` / `speed_multiplier`.
- **Balance tool:** map runs with a path policy (combat-heavy, balanced, event-heavy) and results
  per chapter.

## 8. Open questions for you

1. **Run length:** 3 chapters (~1 hour for a full win), or 2 chapters for now and the third with
   M10's maps?
2. **Towers between chapters:**
   - full refund (proposed);
   - 50% refund;
   - "tower charters" (rebuild the same tower types and levels for free).
3. **Upgrade choice cadence:** keep a choice after every wave (proposed; it keeps the chapter 1
   balance), or one per battle node plus elites, events and merchants (fewer, weightier picks,
   more like Slay the Spire)?
4. **Elites:** do the Gravelord and the Bone Colossus become elite mini-bosses (proposed), leaving
   the Lich as the only chapter-1 boss? Or does the boss node keep all three?
5. **Merchant stock:** upgrades, repairs and rerolls now; relics in M9. Should merchants also sell
   a free tower build, or an evolution discount?
6. **Event frequency:** ~20% of mixed nodes. More events means more story room (M11) but less
   fighting. Is the balance right for you?
7. **Fail state:** losing in chapter 2 ends the run as today (roguelite). Or a checkpoint at the
   chapter start (more forgiving, but it weakens the stakes)?
8. **Map visibility:** show the whole chapter map from the start (proposed: planning is half the
   fun), or reveal it row by row?
9. **Chapters 2–3 before M10:** acceptable to play them on the same arena with ramped numbers, or
   build only chapter 1 in M7 and add chapters with the new maps?
10. **Quartermaster buy-back:** once per chapter (proposed) or still once per run?
