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

Source: 7 F8 reports on `m13-playtest-4`, all from one session (2026-10-27, one tester, the owner; seed 2675351190 for the
in-run ones). Nobody has said anything yet about the ultimates, chapter 2, the Pressure switches or the economy.

| # | Kind | Report (quote) | Where | Status |
|---|---|---|---|---|
| F1 | bug | "the chronicle opens under the menu so when i start the run only then the screen shows" | War Room, Council page, Chronicle button | **Fixed.** The Chronicle and Pressure panels were CanvasLayers 12 under the hub's 20 (so were the Credits under the title); all three are layer 21 now, and `test_front_end` checks it. |
| F2 | feel | "the council has no meaning?" | War Room, Council page | The page is three lines of text and a Chronicle button; the characters do nothing the player can use. Needs a decision (Q8). |
| F3 | bug? | "there is no music" | title / War Room (reported on `front_end`) | **Fixed** (tester: silent everywhere, volumes at 100). `Music.play(title)` ran while the tree root was still setting up its children, so `add_child` failed, the two players never entered the tree and every later track was silent. Players now join deferred and the track starts when they are in. Checked by recording the game: silent before, sound from the first second after. |
| F4 | feel | "the lower bar with health and stuff needs to more compact" | fight HUD, bottom-left panel (Fortress, Hero, Dash, Ultimate, gold, slots, next wave: seven rows) | **Fixed**: gold and free slots share a line ("Slots free: 13 / 16"), six rows instead of seven. Dash and Ultimate stay separate; say if it is still too big. |
| F5 | balance | "the huntress is kinda under powered because the towers dont really do damage to large groups" | chapter 1, row 5 elite, Huntress | Single report. Large groups need splash: the Huntress's towers are single-target (Archer, Trap Layer, Watchtower). Check with `map_balance.gd --hero-kind=huntress` (Q10). |
| F6 | feel | "menus and all the ui is super simplistic. we need some uniquenes in them" | every menu | Not a bug: M8.5's shared style is plain frames and buttons. Looks like M15 work (Q11). |
| F7 | feel | "the map art could better maybe have something on the backgound or maybe the roads should not be straight to give some feeling of adventure" | run map (chapter 1) | The roads are straight lines between nodes over a flat tiled ground. Landmarks and curved roads are map art. Looks like M15 work (Q11). |

Not reported: any crash, wrong number or unfair fight.

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
| Q8 | The Council page "has no meaning": give it a use, or fold the three characters into the Heroes/Records pages? | **Give it one small use**: each character sells or explains one thing (Dunmore the Quartermaster's repairs, Ilse the shrines, Orm the evolutions) with a line of what it does for the next run; decide with you before building. |
| Q9 | No music: where did you hear none (title, War Room, map, fight, everywhere)? Is the Music volume above 0 in Settings? | **Need your answer** before I touch code. |
| Q10 | Huntress and large groups: add splash/area to her kit (a card or a tower), or leave until more reports? | **Check with the bot first**, then one area card if she is clearly low; she is single-target by design. |
| Q11 | Menu uniqueness and the map's look: fold into M15 (Art Overhaul), or a small M14 pass? | **M15**, as the first items of its backlog; the bugs F1 and F4 stay in M14. |

## 10. Decisions

Approved by the owner on 2026-10-27 with "use your recommendations"; F1 and F4 (and the music bug, F3) were fixed first. Q9 was answered by the owner: no music anywhere, all volumes at 100.

| # | Question | Decision | From |
|---|---|---|---|
| Q1 | Forced affix | Drop it from the M12 doc | recommendation |
| Q2 | Chapter 1 row steps | After the playtest feedback | recommendation |
| Q3 | Hasty Waves sound | Yes, a tick at 10 s | recommendation |
| Q4 | Bulwark flash | Only if the playtest asks | recommendation |
| Q5 | Chapter 2 economy | Wait for the playtest | recommendation |
| Q6 | Hero balance pass | No | recommendation |
| Q7 | Merge into `main` | Owner's call after the playtest | recommendation |
| Q8 | Council page | One small use per character, agreed with the owner before building | recommendation |
| Q9 | No music | Cause found and fixed (above) | owner + fix |
| Q10 | Huntress and big groups | Check with the bot first, then one area card if she is low | recommendation |
| Q11 | Menu and map looks | M15 | recommendation |
