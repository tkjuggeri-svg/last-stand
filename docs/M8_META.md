# M8 — Meta Progression & Persistence: design proposal

> Status: **approved for implementation with Claude's recommendations** (the user was away and asked
> for the open questions to be answered with them; every decision is in section 10, to be overridden
> later). The user's design rules for M8 take precedence over the proposal where they differ: unlocks
> add content and options plus only small conveniences, **no large permanent power boosts** (chapter 1's
> balance must stay valid), every run earns shards, a shared UI style with the main menu, hub and run
> summary, one-time skippable tutorial hints, versioned saves with a test that loads an older save.
> Numbers are starting points for the balance tools.

## 0. Summary

- **Soul Shards** are earned by every run, won or lost, for the progress it made (nodes cleared,
  elites and bosses beaten, chapters cleared). A lost first run pays enough for a first unlock.
- Between runs the player is in the **hub**: one screen ("the War Room") where shards buy **unlocks**:
  towers, evolution branches, card packs and relics for the run's pools, and a few small permanent
  bonuses. M9's heroes are unlocked here too.
- **The first run is smaller:** 3 towers, a starter card pool and a few relics. Everything else comes
  in a recommended order (section 3), so new mechanics arrive one at a time.
- **`SaveManager`** (the autoload `CLAUDE.md` already allows) keeps one versioned save file in
  `user://`: shards, unlocks, records, tutorial hints seen, and (recommended) the run in progress,
  resumable from the map.
- **Run flow:** title → hub → run (map ↔ fights) → run summary → hub.
- **A shared UI style** is built with the title, the hub and the summary, and every later screen uses
  it (section 6; the consistency pass over the existing screens is M8.5).
- **Tutorial hints:** short prompts, each shown once, skippable, remembered in the save (section 7).

## 1. Soul Shards

### 1.1 What a run pays

Paid on the run summary, for everything the run did (a lost run keeps all it earned):

| Done | Shards | Why |
|---|---|---|
| A battle won | 3 (was 2 until the pace check below) | the bulk; a short run still pays |
| An elite won | 8 (was 6) | the risk the map asks for |
| A chapter's boss beaten | 15 (chapter 1), 25 (chapter 2) | |
| A chapter cleared (moving on) | 5 | |
| The run won | 30 | |
| First time: each boss beaten, each chapter reached | +10 | one-off, makes early goals visible |

Events, shrines and merchants pay nothing (they are choices, not progress).

Expected: a run lost at chapter 1 row 6 (5 battles, 1 elite) ≈ **16**; a chapter-1 clear ≈ **45–55**;
a won run ≈ **130–150**. The first unlocks cost 20–40, so the first or second run buys one.

### 1.2 Why progress, not kills

Kills already pay gold inside the run; paying shards for kills would reward stalling waves. Paying
per node keeps one currency for "how far did you get", the thing a run is about.

## 2. The hub ("the War Room")

One full screen, not a walkable place (a walkable camp is open question Q4):

- **Unlocks:** the unlock board (section 3): what each unlock adds, its cost, what it needs first;
  bought ones ticked. Hovering a card or relic shows it as in a run.
- **Bonuses:** the few permanent bonuses (section 3.3), each with its level.
- **Records:** best run (furthest chapter and row), runs played and won, bosses beaten, shards earned
  in all, the last runs' summaries.
- **Heroes** (M9): pick the hero for the next run; buy new heroes.
- **Start a run** (and **Continue** if a run is saved, section 4.3), **Settings**, **Quit**.

The hub reads the profile from `SaveManager` and sends intents ("buy unlock X", "start a run"); a
`MetaProgress` system owns the rules (prices, requirements), so the UI keeps no logic.

## 3. Unlocks

### 3.1 The first run

| | On the first run | All |
|---|---|---|
| Towers | Archer, Cannon, Frost | + Brazier, Bone Ballista (M9: per hero) |
| Evolutions | none (level 3 is the top) | 10 branches, 2 per tower |
| Cards | a starter pool of ~12 (basic hero, tower, fortress and economy cards) | 25 |
| Relics | 5 (Hourglass, Phoenix Feather, Soul Lantern, Glass Banner, Ossuary Bell) | 15 |
| Events, shrines | all | all |
| Chapters | both (reached by playing) | both (M10: more) |

**Why start smaller:** every mechanic arrives one at a time, with a hint (section 7), and the first
unlocks are visible gains. **But** today's difficulty is tuned with all 5 towers and every card: the
first-run kit must be balanced on its own (`map_balance.gd` with the starter pools), and chapter 1 may
need to be a little easier with it (open question Q7).

### 3.2 Unlock board (recommended order)

Each unlock adds things to the run's pools from the next run on. Costs grow so that a typical player
unlocks something every 1–2 runs early and every 3–4 later.

| # | Unlock | Cost | Needs |
|---|---|---|---|
| 1 | **Brazier** | 25 | — |
| 2 | Card pack: **Sharpened** (Honed Blade, Long Reach, Battle Rhythm) | 30 | — |
| 3 | **Evolutions: Archer** (Sniper Nest, Volley Tower) | 40 | — |
| 4 | **Bone Ballista** | 45 | — |
| 5 | Relic pack I (Twin Banners, Drowned Bell, Siege Ledger) | 50 | — |
| 6 | **Evolutions: Cannon** (Siege Mortar, Grapeshot Battery) | 60 | #3 |
| 7 | Card pack: **Fire** (Hellfire Shells, Cinder Dash) | 60 | #1 |
| 8 | **Evolutions: Frost** | 70 | #3 |
| 9 | Card pack: **Gold** (Treasury, War Tax, Guild Discount) | 70 | — |
| 10 | **Evolutions: Brazier** | 80 | #1, #3 |
| 11 | Relic pack II (Executioner's Mark, Iron Tithe, Merchant's Seal, Ember Heart) | 90 | #5 |
| 12 | **Evolutions: Bone Ballista** | 90 | #4, #3 |
| 13 | Card pack: **Trade-offs** (Berserker's Oath, Overcharged Engines, ...) | 100 | — |
| 14 | Relic pack III (Bloodpact, Second Oath, Lantern of the Lost) | 120 | #11 |
| — | M9: a second hero | 150 | a chapter-1 boss beaten |

Card and relic packs keep the pools coherent (a pack is a theme), and fewer, bigger unlocks read
better than 40 single cards. Every unlock is data (`UnlockData` resources, section 8), so the order and
prices are tuned without code.

### 3.3 Permanent bonuses (small, capped)

| Bonus | Per level | Max | Cost per level |
|---|---|---|---|
| Stores (starting gold) | +25 | 3 | 40, 80, 120 |
| Mortar (fortress max HP) | +5% | 3 | 50, 100, 150 |
| Drill (one free card reroll per run) | +1 | 1 | 80 |

Capped and small on purpose: a long-time player should win by playing better, not by grinding the
bonuses (the harder modes of M12 are where long-time players go). Whether to have bonuses at all is
open question Q2.

## 4. The save

### 4.1 Contents (`user://save.json`)

```
{
  "version": 1,
  "shards": 37,
  "unlocks": ["brazier", "cards_sharpened"],     # UnlockData ids bought
  "bonuses": {"stores": 1},
  "records": {"runs": 4, "won": 0, "best": {"chapter": 1, "row": 8}, "bosses": ["lich_warden"],
              "shards_total": 121, "history": [ ...last 10 run summaries... ]},
  "firsts": ["boss:lich_warden", "chapter:2"],   # one-off shard bonuses already paid
  "hints_seen": ["build", "start_wave"], "hints_off": false,
  "run": { ... }                                  # the run in progress (4.3), or absent
}
```

Settings stay in `user://settings.cfg` (GameSettings, already there): they are per machine, not per
profile.

### 4.2 Safety

- **Versioned:** a `migrations` table in `SaveManager` brings an old save up to the current version
  step by step (tested with a saved v1 file in `tests/`).
- **Atomic:** written to `save.json.tmp`, then renamed over `save.json`, the previous one kept as
  `save.json.bak`. A save that fails to parse falls back to the backup, then to a fresh profile, and
  says so on the title screen (never a crash, never a silent wipe).
- **When:** after every purchase in the hub, at the run summary, and (with 4.3) at every map node.

### 4.3 A run in progress (recommended: resume from the map)

Recommended: the run is saved **each time the map is shown** (between nodes, never mid-fight), and
**Continue** on the title screen or in the hub resumes it there. A crash or quit mid-fight resumes at
the map before that fight (the fight is replayed from its start: the save is the state before it).

What it needs: the run's seed and data id, the chapter, the map (seed + visited path), the level's
state (towers by slot with level, evolution and invested gold, gold, fortress HP, lives, the
Quartermaster's counts, free evolutions, pending event twists, merchant price factor), the upgrades
and relics taken (ids), the RNG states of the offers and events. Most of it already passes between
chapters as `ChapterCarry`; this extends it with the towers and the map.

The cheaper alternative: no resume; a run quit or crashed mid-way counts as lost (its shards paid at
the next start). That is open question Q1.

## 5. Run flow

```
boot → title screen ─ Continue (a run is saved) ──────────────┐
                     ├ Play → hub ─ Start a run → (M9: hero) → │ map ⇄ fights … → run summary → hub
                     ├ Settings                                │                   (shards, records)
                     └ Quit                                    └──────────────────────┘
```

- **Title screen:** the logo, Continue / Play / Settings / Quit. (The full title screen with art and
  sound is M8.5; M8 builds its structure.)
- **Run summary:** replaces today's Game Over and Victory screens at the end of a run: the outcome,
  the path taken (the map's nodes), the upgrades and relics, the stats (kills, gold, waves, time), and
  **the shards earned, line by line** (section 1.1), then "Back to the hub". Restart from the pause
  menu becomes "Abandon run" (a loss, shards paid).
- **Main** keeps owning the flow (`main.gd`); the title, the hub and the summary are its screens, like
  the map and the merchant today. No new autoload besides `SaveManager`.

## 6. The shared UI style

Built with the three new screens; every screen after it uses it (the pass over the existing ones is
M8.5). On top of `ui/theme/game_theme.tres` and the pixel font:

- **Theme type variations**, not per-screen styling: `Panel` / `PanelDark` / `PanelGold` (frames),
  `ButtonPrimary` / `ButtonSecondary` / `ButtonDanger`, `Title` / `Subtitle` / `Body` / `Dim` labels,
  `Price` (gold, red when short), `Tooltip`.
- **Shared widgets** (`ui/widgets/`): `CardView` (an upgrade card or a relic: icon, name, kind, text;
  used by the choice screen, the merchant and the hub), `IconRow` (today's `RunIconsRow`), `ScreenFrame`
  (a titled full-screen panel with a footer of buttons), `StatLine` (icon, label, value).
- **Transitions:** a screen fades through dark (0.25 s) when the flow changes screens (Main runs it,
  a `ScreenFade` node, not an autoload); choices and toasts slide in.
- **Input:** every screen works with the keyboard (focus, arrows, Enter, Esc to go back) and the mouse,
  the same way.
- **Sizes:** text at 24 px (the 2× font), headings at 48 px, the 1280×720 base layout, safe margins for
  wider screens.

## 7. Tutorial hints

A small panel at the bottom centre, never pausing the game, "Got it" (Enter) or it fades after its
time; each hint once per profile (`hints_seen`); "Show tips" on/off in Settings and "skip all" on the
first hint.

| Hint | When | Text (short) |
|---|---|---|
| build | first build phase | Walk to a stone pad and press **E** to build a tower. |
| start_wave | a tower is built | Press **Enter** (or the button) to start the wave. |
| fight | first wave | Hold the **left mouse button** to swing at the dead. |
| dash | first time the hero is hit | **Space** dashes through enemies: you can't be hurt while dashing. |
| upgrade | first upgrade choice | Pick one upgrade: it lasts the whole run. |
| map | first map screen | Choose your path: battles, elites, events, merchants. |
| quartermaster | first time the fortress is under half | Between waves the Quartermaster repairs the walls. |
| evolution | a tower reaches level 3 (evolutions unlocked) | Level 3: this tower can evolve. It's for good. |
| elite | first elite on the map | Elites are harder fights and give a relic. |
| relic | first relic | Relics change a rule of the run. Hover them in the top-left row. |
| chapter2 | chapter 2 starts | The Drowned Marsh: you wade through water slowly. |

Enemy hints (`EnemyData.hint`, M7.5) stay as they are (a banner the first time an enemy appears in a
level).

## 8. How it would fit the code (sketch)

- `autoload/save_manager.gd` (`SaveManager`): load, save, migrate, backup; the profile as a typed
  object (`SaveProfile` resource or class); nothing else.
- `resources/unlock_data.gd` (`UnlockData`): id, name, cost, requirements, and what it adds (towers,
  evolutions, cards, relics, a bonus). `data/unlocks/*.tres` and one `UnlockBoard` resource listing
  them in order.
- `systems/meta_progress.gd` (`MetaProgress`, owned by Main): prices and requirements, shards for a
  run summary (`RunSummary` built from the level and the map at the run's end), buying.
- **Applying unlocks:** when Main starts a chapter's level it hands the level the run's pools (tower
  catalog, card pool, relic pool, evolutions allowed, bonuses) from the profile; systems never read
  `SaveManager` themselves (the rule `RunState` already follows).
- **Screens:** `ui/menus/title_screen`, `ui/hub/hub_screen`, `ui/menus/run_summary_screen`, the
  widgets of section 6, `ui/widgets/tutorial_hint`.
- **Tests:** save/load round trip; migration of a v1 file; a corrupt save falls back to the backup;
  shards for a scripted run match the table; unlocks change the pools of the next run (and only then);
  requirements and prices; hints shown once and the off switch; the whole flow through `main.tscn`
  (title → hub → run → summary → hub); resume from the map (if Q1 says yes).
- **Balance:** `map_balance.gd --profile=first|full` to measure the first-run kit (section 3.1).

## 9. Open questions (with recommendations)

| # | Question | Recommendation |
|---|---|---|
| Q1 | Resume a run after quitting or a crash? | **Yes, from the map** (section 4.3): expected on PC, and the map is a natural save point. Without it, a 40-minute run lost to a crash hurts. |
| Q2 | Permanent stat bonuses, or only new content? | **A few small, capped bonuses** (section 3.3), mostly content. Make them easy to remove if they feel like grinding. |
| Q3 | Does a lost run pay shards? | **Yes, for all the progress it made** (1.1): losing is the common case in a roguelite. |
| Q4 | Hub: a menu screen or a walkable camp? | **A menu screen in M8** (cheaper, clearer); a walkable camp could come with M11's story. |
| Q5 | How long until everything is unlocked? | About **25–35 runs** for an average player (≈ 1,200 shards of unlocks); tune with the summaries. |
| Q6 | Are relics unlocked, or all there from the start? | **Unlocked in packs** (3.2): relics change rules, so meeting them a few at a time helps. |
| Q7 | The first-run kit is smaller than what today's balance assumes: ease chapter 1? | **Balance the starter kit on its own** with the tool before deciding; ease chapter 1's first rows only if needed. |
| Q8 | Do unlocks matter for the harder modes (M12)? | Unlocks are content, not power; the harder modes (M12) add the challenge. Decide in M12. |
| Q9 | Several save slots / profiles? | **One profile** (cloud saves only if a release ever needs them: ROADMAP.md, parking lot). A "reset progress" button in Settings. |
| Q10 | Can a player skip the tutorial hints entirely? | **Yes**: "skip all" on the first hint, and the switch in Settings. |

## 10. Decisions (M8 build; to be overridden by the user later)

| # | Question | Decision | From |
|---|---|---|---|
| Q1 | Resume a run after quitting or a crash? | **Yes, from the map**: the run is saved each time the map is shown; Continue on the title screen resumes it there (a fight in progress is replayed from its start). | recommendation |
| Q2 | Permanent stat bonuses? | **None.** The user's rule: no large permanent power boosts. The proposal's Stores (starting gold) and Mortar (fortress HP) are dropped. What stays: one **convenience** (*Drill*: one free card reroll in each chapter) and one **starting choice** (*Muster*: choose 1 of 2 common cards before the first fight), both unlocks. | user's rule + recommendation |
| Q3 | Does a lost run pay shards? | **Yes, for all its progress** (section 1.1), also an abandoned one. | user's rule |
| Q4 | Hub: menu screen or walkable camp? | **A menu screen** (the War Room), with one hub character's line reacting to the last run (the roadmap's M8 item, kept small). | recommendation |
| Q5 | How long until everything is unlocked? | About **1,200 shards** of unlocks, roughly 25–35 runs. | recommendation |
| Q6 | Relics unlocked or all there? | **Unlocked in packs** (5 at the start). | recommendation |
| Q7 | The smaller first-run kit vs chapter 1's balance | **Measured with the balance tool** (`map_balance.gd --profile=first`): the starter kit must keep chapter 1 about as it is with everything; widen the kit rather than ease the waves if it doesn't (section 11 has the numbers). | recommendation |
| Q8 | Unlocks and the harder modes (M12) | Unlocks are content, not power; decided in M12. | recommendation |
| Q9 | Save slots | **One profile**, with "Reset progress" in the hub (asks to confirm). | recommendation |
| Q10 | Skip the tutorial hints? | **Yes**: "Skip all tips" on every hint, and a Tips on/off switch in the hub. | recommendation |
| — | Save format version | **Version 2**; version 1 is the proposal's format with the dropped `bonuses`: loading it refunds their shards. `tests/fixtures/save_v1.json` is loaded by the save test. | Claude |
| — | Old Game Over / Victory screens | **Kept**, their button now reads Continue and leads to the run summary (shards, path, stats), then the hub. The pause menu's Restart becomes **Abandon run** (a loss, shards paid). | Claude |
| — | Tests and tools | Under `--script` (tests, the balance tool) the profile has everything unlocked, nothing is written to disk and Main boots straight into a run, as before M8; the meta tests switch this off. | Claude |
| — | Resume details | The run is saved **each time the map shows** (also right after a new run starts). Quitting in a fight replays it from its start; quitting on the chapter-cleared screen replays the boss (the chapter's map was the last save). A new run started while one is saved **abandons it** (it pays shards as abandoned); the War Room says so. A saved run of an older format is dropped (a fresh run starts). | Claude |
| — | Hint placement and keys | Bottom right (clear of the HUD's panels), never pausing; **mouse only** ("Got it", "Skip all tips"), not Enter as section 7 proposed, because Enter starts the wave and Space dashes. Each tip goes by itself after 9 s of play. A tip counts as seen once shown. The War Room's **Tips** switch replaces "Show tips" in Settings; switching it back on shows every tip again. | Claude |
| — | Hub character lines | One figure (the Quartermaster), lines picked in code (`HubLines`) from the last run (won, abandoned, boss beaten, chapter 2, short run, relic, fallen). Data-driven lines and more figures: M11. | Claude |
| — | The dev menu | Gains a **Shards** row (set the profile's shards, also on the title / hub / summary) to test the unlock board without playing runs. | Claude |

## 11. The first-run kit, measured

`map_balance.gd -- --seeds=1-8 --path=balanced --plan=mixed` from the same build, everything unlocked
(what script mode gives) against a fresh profile (`--profile=first`: Archer, Cannon, Frost, 13 cards,
5 relics, no evolutions). Rows cleared per run, of 16 (chapter 1 only; the bot and the idle hero both
fall in chapter 1 on every seed, as before M8):

| Hero | Everything unlocked | First-run kit | Difference |
|---|---|---|---|
| bot | 5.1 | 4.8 | −0.3 (two seeds fall at row 6 instead of row 8) |
| idle | 4.2 | 3.8 | −0.4 (one seed at row 3 instead of 6) |

The mixed plan's Brazier and Ballista are skipped with the first kit (their slots get the kit's towers),
so this is close to the worst case. A drop of under half a row is inside the seed-to-seed spread (rows 3
to 8 either way), so **the kit stays as it is**: no wave is eased and the Brazier stays the first, cheap
unlock (25 shards, one or two runs). Revisit if playtests show first runs ending much earlier than later
ones.

## 12. The shard pace, checked (after `m8-playtest-2`)

Target (the user's): the key unlocks, the first evolutions included, within 5–10 runs; everything
within 20–30. `python3 tools/shard_pace.py` reads the rates and prices and plays two made-up players:
a **typical** one (chapter-1 losses for ~5 runs, then mostly chapter-2 losses, a win every 5 or so)
and a **slow** one (chapter-1 losses for ~10 runs). Key unlocks: Brazier, Bone Ballista, Archer and
Cannon evolutions, Relics I.

| | Battle / elite | Key unlocks | Key: typical / slow | Everything | All: typical / slow |
|---|---|---|---|---|---|
| Before | 2 / 6 | 220 | run 9 / run 12 | 1,175 | run 26 / run 30 |
| **Now** | **3 / 8** | **210** | **run 8 / run 9** | **1,165** | **run 22 / run 26** |

Early chapter-1 losses paid only 6–16 shards, so the first evolutions came late; they now pay 9–23.
The Cannon's evolutions cost 50 (was 60). On the way: the Brazier on run 2, the Archer's evolutions
by run 4, the Ballista by run 5. The bosses, chapters and wins stay as they were: they are what makes
a run that reaches chapter 2 pay 70–90.
