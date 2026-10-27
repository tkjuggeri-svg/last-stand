# M14 — Fix & Finish: scope (proposal)

**Status: proposal, not approved, not implemented.** Numbers are starting points for the balance tools. Drafted while
the owner playtests `m13-playtest-4`; the "Playtest findings" section (7) is empty on purpose and decides what really goes in.
Per CLAUDE.md rule 7, no gameplay is built until the owner approves this scope.

## 0. Summary

- M14 is "everything in the game works and feels finished". It is the playtest-fix milestone, not a content milestone.
- **Already done in M14:** playtest fixes (cards filtered by the run's towers, War Room pages, scrolling stories, chapter 2
  rows 5-6 eased) and the hero ultimates (`docs/M14_ULTIMATES.md`, waiting for the playtest).
- **Found while drafting: two ROADMAP items are already built.** The Knight's extra cards (Shield Bash, Oathkeeper, Rally,
  Iron Will) and relics (Crown of Thorns, Banner of the Last Keep) and the Bulwark passive exist with `test_knight`; the
  hero stories (Ser Aldric, Wren, Maren) are in the War Room's hero panel (`docs/M9_HEROES.md` "Knight leftovers", the
  M11 "Not done" line is out of date). What is left for both is **checking them by hand**, not building.
- **Pressure:** Hardened Elites and Stronger Bosses have no tests; Hardened Elites does not force an affix; Hasty Waves has
  no countdown sound. Proposal: add the two tests, make Hardened Elites match its documented rule, add the sound.
- **Chapter 1's row steps** are uneven (x2.99 at row 2 to 3, x2.41 at row 4 to 5 in Crypt Road). Proposal: smooth them to
  about x1.6-1.9, like chapters 2 and 3, and check with the bot.
- **Chapter 2's economy:** gold used to go unspent (thousands). Slots and Masterwork were the fix in `m13-playtest-2`; only a
  human can tell whether it worked, so it is a question for the playtest, with a small lever ready (section 5).
- Nothing in this scope adds an autoload, a physics layer, an input action or moves a folder.

## 1. The Knight's cards and relics (verify, then tune)

Built: Bulwark (25% less damage while swinging; Iron Will 45%), Shield Bash, Oathkeeper, Rally (+10% fire rate within 150 px),
Crown of Thorns (8 damage back), Banner of the Last Keep (fortress takes 15% less while he stands); two ultimate cards
(Oathbound, Wider Circle).

- **To do:** nothing to build. Playtest questions: does the Knight now feel different from the Huntress and Necromancer,
  is Bulwark visible to the player (it is a hidden number today), is Rally worth a card slot?
- **If the playtest says Bulwark is invisible:** a small shield flash on the hero when it absorbs (visual only, follows state).
- **Why not more cards now:** the pool is 4 cards + 2 relics + 2 ultimate cards per hero, matching the others; more content
  waits for evidence that these are used.

## 2. Hero stories (verify)

Built in the hero panel ("Their story", scrolling). Open: the texts' quality and length are unjudged. Playtest question only.
Fix the stale "Not done" line in `docs/M11_STORY.md` and ROADMAP when the owner confirms.

## 3. Pressure switches

| Switch | Points | Today | Proposed |
|---|---|---|---|
| Hardened Elites | 1 | elites +40% HP (`map_flow.gd`: elite scale and the leader's group scale); no test | **test** it; **force an affix** (see below) |
| Stronger Bosses | 2 | bosses +25% HP; no test | **test** it |
| Hasty Waves | 1 | 60 s countdown; no sound | a short warning tick/sting at 10 s left (`sfx_recipes.gd`, `test_sfx` covers the id) |

- **Forced affix.** The data text says only "40% more health", and elites already carry an affix (M7.5), so the "always carry
  an affix" in `docs/M12_LONGEVITY.md` is a no-op today. Recommendation (Q1): **drop it from the design doc** rather than
  build it: it changes nothing the player can see, and elites already always have one.
- **Tests** (`test_pressure.gd`, extended; they play through `MapFlow` on a seeded map): an elite fight with the rule has
  health scale x1.4 against the same seed without it, and its boss-class leader's `health_scale` is x1.4 too; a boss fight
  with Stronger Bosses has x1.25, a battle node is unchanged by both; Endless depth multiplies on top (x1.4 x depth scale).
- **Hands-on check** (owner): one run each with Hardened Elites and Stronger Bosses, 1-3 points as a gentle first step
  (the bot cannot tell: 6.5 rows none, 4.8 with five points).

## 4. Chapter 1's uneven row steps

Chapter 1 (Crypt Road) rises x2.99 from row 2 to 3 and x2.41 from row 4 to 5; chapter 2 is an even x1.6-1.85 (M10 smoothed
chapters 2 and 3, left chapter 1 alone).

- **Proposal:** retune chapter 1's per-row `fight_health_scale`/wave tables so every step is x1.6-1.9 and row 1 stays where
  it is, with the same total at the boss (the chapter must not get easier overall, only less spiky). Data only
  (`tools/make_waves.py` tables / `ChapterData`), no code.
- **Check:** `map_balance.gd --seeds=1-8` before and after (rows cleared, deaths by row); the weak bot dies at about row 6.5,
  so the spike at rows 2-3 and 4-5 should show as fewer deaths exactly there. Risk: the first chapter is what the owner
  called "right for a first chapter" (M6.5), so the change must not move the average win rate of a good player.
- Q2 below: do it before the playtest feedback or after?

## 5. Chapter 2's economy

State: 13-15 slots and Masterwork ranks (+8% power a rank, rising price) since `m13-playtest-2`; chapter 2 "used to leave
thousands of gold unspent". The bot dies in chapter 1, so there is no measurement; `--start=2` gives about 1.5 rows.

- **Do nothing until the playtest.** Findings (section 7) say whether gold is a choice or a pile.
- **Levers, cheapest first** (data only): the Quartermaster's repair price curve, Masterwork's price growth, the merchant's
  prices and stock, chapter 2's kill-gold scale (`WaveData.gold_multiplier`).
- **Measure** with `map_balance.gd --start=2 --kit=10:2:1500 --trace` (gold per wave) to see the unspent bank at the boss.

## 6. Other known leftovers (small)

- `perf_report.gd` / `trailer_capture.gd` index their 10-entry tower list with 13-16 slots: **fixed** (`i % TOWERS.size()`).
- ROADMAP/HANDOFF/M11 "not done" lines about the Knight and the hero stories are stale: fix with this scope.
- `m7.5-playtest` and `m8.5-playtest` hands-on checkboxes in the ROADMAP are still open; the later builds contain everything.

## 7. Playtest findings

*(empty: for the owner's F8 reports and notes on `m13-playtest-4`. Group them as: bug / balance / feel / content, with the
build, seed and chapter if known; summarise reports with the `feedback-review` skill.)*

## 8. How it would fit the code (sketch)

- No new systems. Tests: `test_pressure.gd` grows by about 6 checks (elite/boss health scale, leader scale, battle unchanged,
  Endless stacking). Data: chapter 1 wave tables via `tools/make_waves.py` (rerun it, never edit the `.tres`). One sound recipe
  (`hasty_warning`) and one call in `RunCycle`'s countdown, not in the HUD.
- Balance: `map_balance.gd --seeds=1-8` before/after for chapter 1; `--start=2 --trace` for chapter 2.
- Done when the suite says `ALL PASSED` and the owner's findings list is empty or sorted into "fixed" and "leave".

## 9. Open questions

| # | Question | Recommendation |
|---|---|---|
| Q1 | Hardened Elites "always carry an affix": build it or drop it from the docs? | **Drop it**: elites already always have an affix, so building it adds nothing. Update M12's table. |
| Q2 | Smooth chapter 1's row steps now, or after the playtest? | **After**: the feedback may say chapter 1 is fine as it feels; if it is smoothed, ship it in the next build with a note. |
| Q3 | Add a Hasty Waves warning sound? | **Yes**, one short tick at 10 s; it is the only Pressure switch the player can't hear. |
| Q4 | Bulwark feedback (a flash when it absorbs)? | **Only if the playtest says the Knight feels like he has no passive.** |
| Q5 | Chapter 2's economy: change anything before the playtest? | **No**; wait for how the owner spends gold, then pull the cheapest lever in 5. |
| Q6 | Should M14 also include the Knight/Huntress/Necromancer balance pass (±20% of Knight rows)? | **No**, the bot can't separate the heroes beyond its noise; take the owner's feel first. |
| Q7 | Merge `art/handoff-integration` into `main` at the end of M14? | **Owner's call after the playtest**; nothing is merged until they say so. |

## 10. Decisions

*(after approval: # / question / decision / from user or recommendation)*
