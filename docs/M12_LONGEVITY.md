# M12: Longevity (design proposal)

> **Status: approved on the recommendations (the user's blanket permission of 2026-10-25), being built.**
> Numbers are starting points for `map_balance.gd`. Section 8 lists the decisions.

## 0. Summary

- **Pressure** (Hades' Heat style): before a run the player turns on any mix of **10 modifiers**, each worth
  1-2 points; the total is the run's **Pressure**. Pressure pays more shards (+10% per point), is recorded
  (best win per hero, best Pressure overall) and earns **titles**. It adds difficulty only: no power, and
  the first run offers none (they unlock after the first win).
- **Endless** ("Descend"): after the last boss the player may stop (the ending, as before) or **descend**:
  more chapters on tier-3 biomes, each tougher (x1.3 enemy health a depth), shorter (6 rows), with a relic from
  every boss. The run ends when the fortress falls or the hero's last life is lost; the score is the depth.
- **No new autoload, layer or input action.** Modifiers are data (`data/meta/pressure/*.tres`), granted as
  hidden run upgrades (their stat changes go through `RunModifiers`) plus a few rules applied by the spawner,
  the map and the fights.
- **Built in 3 stages:** (1) Pressure's data, rules and War Room panel; (2) Endless; (3) records, titles and the
  summary.

## 1. Pressure

| # | Modifier | Points | What it does | How |
|---|---|---|---|---|
| 1 | Hardened Elites | 1 | elites have 40% more HP and always carry an affix | map flow: elite scale, affix |
| 2 | No Repairs | 2 | the Quartermaster, merchants, rewards and chapters never repair the fortress | rule: `can_repair` |
| 3 | Swift Dead | 2 | every enemy walks 10% faster | spawner speed scale |
| 4 | Fewer Slots | 2 | two build slots are unusable each chapter (chosen from the seed) | level: slots disabled |
| 5 | Lean Purses | 1 | kills pay 15% less gold | stat `economy.kill_gold` -15% |
| 6 | Stronger Bosses | 2 | bosses have 25% more HP | encounter: boss scale |
| 7 | Brittle Fortress | 2 | the fortress has 30% less max HP | stat `fortress.max_health` -30% |
| 8 | One Life Fewer | 1 | the hero has one life fewer | stat `hero.lives` -1 |
| 9 | Hasty Waves | 1 | a wave comes by itself 60 s after the last one started | run cycle: auto start |
| 10 | Fewer Cards | 1 | upgrade offers have 2 cards, not 3 | offers: size 2 |

- Total available: 15 points. **Rewards:** shards x(1 + 0.1 x points) at the run's end; the **title** on the
  run summary and records: Pressure 1-3 "Watchman", 4-6 "Captain", 7-9 "Marshal", 10-12 "Warden", 13+ "Last
  Light".
- **Unlocking:** the panel appears after the first win. It remembers the last selection.
- **Safety:** Fewer Slots never disables a slot with a tower; Hasty Waves never starts a wave while a card
  choice, an event or a merchant is open.

## 2. Endless

- After the last chapter's boss, the ending screen (M11) gets a second button: **Descend**. The run goes on
  from the chapter screen: the road choice shows two tier-3 biomes, as always.
- Each descended chapter: **6 rows** (a short map: battles, an elite, a merchant, the boss), the biome's own
  waves, enemy health **x1.3 per depth** on top of the chapter's scale, a relic choice after every boss.
  Towers are packed up as between chapters.
- The run ends in the usual Game Over; the summary shows the **depth** (1 = the first descended chapter).
- **Records:** the deepest depth, per hero, in the profile; shards for each depth reached (10 x depth).

## 3. How it fits the code (sketch)

- **Resources:** `PressureData` (id, name, text, points, stat modifiers, a rule key), `data/meta/pressure/`.
- **Rules:** `PressureRules` (rules only: the points of a selection, the shard multiplier, the title, which rules
  hold) in `core/utils/`; `RunState.pressure` (the ids chosen), saved with a run; the profile keeps the last
  selection, the records and the titles (`SaveProfile` v5).
- **Hooks (each small):** `MapFlow` (elite scale, affix, boss scale, no repair), `WaveSpawner` (speed scale),
  `Level` (slots disabled, no repair), `RunCycle` (hasty waves), `UpgradeOffers` (offer size), `RunState`
  grants the hidden stat upgrades at the start of each chapter.
- **Screens:** the War Room's Pressure panel (toggle rows with points and a total), the ending screen's
  Descend button, the run summary's Pressure and depth.
- **Endless:** `RunState.depth`; `RunMap.generate` with 6 rows for descended chapters; `ChapterData` copies
  with the depth scale; `Main._on_chapter_cleared` and the ending screen's choice.
- **Tests:** `test_pressure` (each modifier's effect, the points and the multiplier, the save), `test_endless`
  (descending, the scale, the depth, the end of the run), `map_balance.gd --pressure=<ids>`.

## 4. Build order

| Stage | Contents |
|---|---|
| 1 | `PressureData`, `PressureRules`, the ten modifiers' effects, the War Room panel, save v5 |
| 2 | Endless: Descend, depth scaling, short maps, records |
| 3 | Titles, records on the summary and the hub, balance checks |

## 8. Decisions

On 2026-10-25 the user's blanket permission settled this proposal: everything above stands as written, taken
at the recommendation of each choice (from: recommendation). Save points: git tags `save/m12-<stage>`.

## 9. As built

- **Pressure:** `PressureData` (`data/meta/pressure/*.tres`, the ten modifiers; written by an inline script, edit
  the `.tres`), listed in `RunData.pressure_options`. `PressureRules` (`core/utils/`): points, shard multiplier
  (+10% a point), titles (1-3 Watchman, 4-6 Captain, 7-9 Marshal, 10-12 Warden, 13+ Last Light) and the numbers
  of each rule. `RunState.pressure`, saved with the run (`RunSave`). Applied per chapter by
  `Level.apply_pressure` (stat modifiers through `RunModifiers` with no HUD icon; `RunModifiers.rules` for the
  rest): `WaveSpawner.enemy_speed_scale`, `RunCycle.hasty_seconds` (the HUD's Start button counts down),
  `UpgradeOffers.offer_size`, `BuildSlot.lock()` + `TowerBuilder.SLOT_LOCKED` (Fewer Slots: two empty slots,
  seeded by the chapter), `Fortress.can_repair()` (No Repairs), and `MapFlow` (elite and boss health: the
  leader and bosses ignore the wave scale, so their spawn groups carry it).
- **Panel:** `PressureScreen` from the War Room's footer (after the first win; the last selection is kept in the
  profile), with total, title and shard multiplier. Records: the highest Pressure played, the best won per hero,
  shown in the hub's records and on the run summary.
- **Endless:** `Endless` (`core/utils/`): x1.3 health a depth (bosses too), a 6-row chapter copy (`short_chapter`),
  shards 10 + 20 + ... for the depths reached. After the last boss the ending screen has **Descend**; the run
  is finished (won) only when the player stops or the descent ends in a fall, whatever the way (the summary
  is a win with its depth). `RunState.depth`, `descend` is `next_chapter()` past the last tier (tier-3 roads again),
  saved (`RunSave` depth). Records: deepest descent per hero (save v5).
- **Balance** (`map_balance.gd --pressure=all|<ids>`, the weak bot, seeds 1-4, rows cleared of 24): none 6.5,
  five points (Lean Purses, Hasty Waves, Hardened Elites, Fewer Cards, Swift Dead) 4.8, all ten 0.8. Pressure
  is monotonically harder; only a human playtest says whether 1-3 points is a gentle first step.
- **Tests:** `test_pressure`, `test_endless`; `test_story` and `test_roads` follow the new rules.
- **Not done / honest gaps:** no sound or art of its own (the rubble is a darkened pad); Hardened Elites does not
  force an affix (elites already carry one); the Hasty Waves countdown has no sound; Endless has no leaderboard
  beyond the per-hero record.
