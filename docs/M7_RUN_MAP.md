# M7 — Run Map: design

> Status: **approved** with the decisions in section 8 (the user's answers, plus the proposal's
> recommendations for the rest). Being implemented in M7. Numbers are starting points to be tuned with
> the balance tool, like everything else in `GAME_DESIGN.md`.

## 0. Summary

- A run becomes **2 chapters for now**. The chapter count is data: a third chapter comes with M10's
  new maps. Each chapter is a Slay the Spire–style map of **8 rows** (7 rows of choices, then the
  chapter boss), about **18 nodes**, of which a run visits **8 per chapter**.
- **Chapter 1 is today's game.** Its battles use today's 15 waves, split into 2-wave encounters by
  row, so a typical chapter 1 path plays 12–15 of those waves and keeps the M6.5 balance (the
  decided first-chapter target).
- **Inside a chapter, the map and the defence stay.** Towers stay built between battles, the
  fortress keeps its damage, and gold and upgrades carry over. **Between chapters,** the towers are
  packed up for gold and the next chapter starts on a fresh field.
- Chapter 2 **ramps up from the chapter 1 baseline** (HP, speed, enemy mixes, elite affixes), on the
  current arena until M10 brings new maps, with its own new boss, **the Tollkeeper** (section 4.1).
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
| **Full run (2 chapters)** | 16 | ~26 | **~35–40 min** |

- A chapter stays close to today's 15-wave run (18 minutes).
- A death in chapter 1 still costs about 15 minutes, as today. A full win is a ~40-minute run; a
  third chapter (M10) makes it about an hour.
- **M7 scope:** both chapters, so the carry-over and the ramp are real. Chapter 2 reuses the arena
  and the current enemies with ramped numbers, elite affixes and its new boss; M10 later gives it
  its own map and enemies.

## 2. Node types and odds

Odds for the mixed rows (3–6):

| Node | Share | What happens |
|---|---|---|
| **Battle** | ~45% | 2 waves of the row's tier. Kill gold as today. Reward: **one upgrade choice** (1 of 3) after the battle (not after each wave). |
| **Elite** | ~15% | 2 waves of the row's tier plus an **affix** (below) and a mini-boss: the Gravelord in rows 3–4, the Bone Colossus in rows 5–6. Reward: **a choice of 2 rare cards** and +100 gold. |
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
- Each combat row has a **wave tier**: row *r* (1–6) plays today's waves 2*r*−1 and 2*r*.
  - row 1: waves 1–2;
  - row 2: waves 3–4;
  - …
  - row 6: waves 11–12;
  - row 7 is merchants;
  - the boss (row 8): waves 13–15, with the Lich Warden in the last.
- The Gravelord and the Bone Colossus leave waves 5 and 10: they lead the elites instead, and the
  Lich Warden is chapter 1's only boss.
- Difficulty follows **depth, not the number of battles fought** (as in Slay the Spire). Skipping a
  battle means less gold and fewer upgrade picks before harder tiers. That trade is what makes
  events and shrines a real choice.
- **The wave generator** (`tools/make_waves.py`) gains tiers. Each row gets 2–3 encounter
  variants (the same budget with different lane mixes), so the same row doesn't always play the
  same.

## 3. What carries between nodes

| | Inside a chapter (between nodes) | Between chapters |
|---|---|---|
| **Towers** | **Stay built** on their slots, with their levels and evolutions. The battlefield is the same map, and building up the defence over a chapter is the core of today's game. | **Packed up**: every tower is sold for **40%** of what was spent on it (`ChapterData.leave_refund`; 100% in M7, see below), as gold. The next chapter starts with an untimed build phase on a fresh field. |
| **Gold** | Carries. | Carries (plus the packed-up towers). |
| **Fortress HP** | Carries: damage stays. Repairs come from the Quartermaster (between waves), merchants, events and the boss reward. | +50% of max restored, then carries. |
| **Hero HP** | Full after each wave and node (as today). | Full. |
| **Hero lives** | Carry for the whole run (3). The Quartermaster's buy-back becomes **once per chapter**. | Carry. |
| **Run upgrades** | Carry for the whole run. | Carry. |
| **Evolutions** | Stay with their tower. | Refunded with the tower. They can be bought again, so a chapter-3 defence can be built around different branches. |

**Why towers stay within a chapter:** the M6.5 balance assumes a defence that grows over 15
waves. Rebuilding per battle would turn every battle into a cold start, and the build-up is the
part the playtest liked.

**Why a full refund between chapters (M7), and why 40% now (M7.5):** M7 refunded everything, so a
built-up defence would not punish the player on the new field. The M7 playtest showed the cost: with
the whole chapter-1 defence rebuilt at once, chapter 2 was easy. Since M7.5 the towers come back as
40% of their cost (data: `ChapterData.leave_refund` of the chapter being left), so chapter 2 starts on
less than chapter 1 ended with; its first waves were lowered (HP x1.3 instead of x2.0, rising to the
same x3.8 at the boss) so that the start is tight rather than lost.

## 4. Difficulty ramp per chapter

Chapter 1 = the M6.5 baseline, unchanged. Later chapters continue its curve:

| | Chapter 1 (baseline) | Chapter 2 | Chapter 3 |
|---|---|---|---|
| Regulars' HP multiplier, row 1 → boss | 1.0 → 2.35 (today) | 2.0 → 3.8 | 3.4 → 5.8 |
| Speed multiplier | 1.0 → 1.1 | 1.05 → 1.18 | 1.1 → 1.25 |
| Enemy mix | today | more Brutes and Cultists from row 1; Hounds in bigger packs | every lane pressed every wave; two Cultist groups per wave |
| Kill gold per wave (regulars) | 64 → 350 (today) | ~350 → 450 | ~450 → 550 |
| Elite share / affixes | 15%, 1 affix | 18%, 1 affix | 20%, 2 affixes |
| Chapter boss | Lich Warden 3,600 HP | **the Tollkeeper** (new, section 4.1) | with M10 |

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

### 4.1 Chapter 2 boss: the Tollkeeper

- **Look:** a hulking drowned bell-ringer in a sodden monk's habit, stooped under a wooden yoke. On
  its back hangs a cracked bronze bell, green with verdigris. Its face is a hollow hood with two cold
  eyes. Silhouette: a broad hunched mass with the bell rising above it. It reads apart from the
  thin Lich, the tall Gravelord and the horned Colossus. The look follows `ART_DIRECTION.md`
  (64x64 frames, 1 px outline, top-left light).
- **One mechanic, the Toll:**
  - first after 4 s, then every 9 s, it plants itself and heaves the bell up;
  - **telegraph:** a bronze ring grows on the ground around it for 1.5 s to its full radius (220 px);
  - **effect:** it rings, and every tower inside the ring is **silenced for 4 s**. A silenced tower
    doesn't fire, is darkened, and shows a cracked-bell mark.
  - The hero isn't affected.
- **Counterplay:**
  - spread the defence, so one toll can't silence it all;
  - keep the hero on it, because it stands still while ringing;
  - kill it before the second ring.
- **Numbers** (start): 6,000 HP, speed 24, fortress damage 70, 300 gold. They come from data like
  every boss's, and its ability scene holds the timings.

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
3. **Shrine of Coins:** +250 gold now → kill gold is −50% for the next battle. (After the M7
   playtest: it used to double your gold for 2 lean battles, worth nothing on the small bank
   scarce gold leaves.)
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

## 7.1 As built (M7)

- Everything above is implemented (`systems/run_map.gd`, `main/main.gd`, `systems/merchant.gd`,
  `systems/event_resolver.gd`, `ui/map/`, `data/run/`, `data/events/`, `data/affixes/`). Tested by
  `test_run_map`, `test_run_flow`, `test_events` and `test_chapters`.
- Rows 1–6 are the combat rows (row 7 is all merchants), so a chapter's battles play waves 1–12 and the
  boss fight waves 13–15.
- **Tuning (different from the proposal's tables):**
  - One upgrade choice per battle gives about 5–6 upgrades a chapter instead of 14. So the fights are
    scaled per chapter (`ChapterData.fight_health_scale`): chapter 1 ×0.75, which keeps the M6.5
    difficulty (the bot clears chapter 1 in 4% of runs), and chapter 2 ×1.8.
  - Chapter 2's kill gold is 220–300 a wave, not 350–450: with the towers' full refund, more made gold
    meaningless (the bot evolved almost every tower).
  - Results: `GAME_DESIGN.md` 3. (M7 tuning).

## 8. Decisions

| # | Question | Decision | From |
|---|---|---|---|
| 1 | Run length | **2 chapters for now**; the chapter count is data (`RunData.chapters`), and a third comes with M10's maps | user |
| 2 | Towers between chapters | **Full refund** of everything spent on them (M7); **40%** since M7.5 (playtest: the full refund made chapter 2 easy) | user |
| 3 | Upgrade choice cadence | **One choice per battle node** (1 of 3), not per wave. Elites give a **choice of 2 rare cards**. Events and shrines can grant extra upgrades | user |
| 4 | Elites | The Gravelord and the Bone Colossus become **elite mini-bosses**; the Lich Warden is chapter 1's boss; chapter 2 gets a **new boss** (the Tollkeeper) | user |
| 5 | Merchant stock | Upgrade cards, a repair and a reroll; relics in M9. No free towers or evolution discounts | recommendation |
| 6 | Event frequency | ~20% of the mixed rows | recommendation |
| 7 | Fail state | **Losing in chapter 2 loses the whole run**; no checkpoints | user |
| 8 | Map visibility | The whole chapter map is visible from the start | recommendation |
| 9 | Chapter 2 before M10 | On the current arena, with ramped numbers, affixes and its own boss | recommendation (scoped by 1) |
| 10 | Quartermaster buy-back | **Once per chapter** | recommendation |

**`RunState` autoload:** approved, including the change to the "per-level systems" rule in
`CLAUDE.md`. Run-wide state (the seed, the chapter and the map, gold, lives, upgrades and fortress
HP between chapters) lives in `RunState`. The level's systems still own the rules while a chapter is
played.
