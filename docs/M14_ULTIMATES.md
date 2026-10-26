# M14 — Hero ultimates: design

> Status: **proposal, not approved, not implemented.** Numbers are starting points for the balance tools
> (`balance_report.gd`, `map_balance.gd`). Source: playtest report "we need ultimate skills for the heros"
> (`m13-playtest-2`, chapter 2 row 2).

## 0. Summary

- Every hero gets **one ultimate**: a big, short, on-demand move on its own key (`ultimate`, default **Q**,
  rebindable like every action), used a few times per chapter, not per wave.
- It is **not on a cooldown timer.** It charges from **what the hero does**: damage dealt and kills by the hero
  and its minions, plus a slow trickle per second of combat. Full charge = one use; the charge is kept
  between waves and between nodes of a chapter. A full bar needs about **one wave of active play**, so a
  hero who stands back and lets the towers work charges slowly. That is the point of the trade-off.
- Three ultimates, one per hero, each in the spirit of the hero (section 2). None is a stat bonus; each changes
  where and how the hero fights for ~5-8 seconds.
- **Upgrades:** two new cards per hero touch the ultimate (faster charge, stronger effect), in the hero's own
  card pool. No new relics, no new unlock.
- **HUD:** an ultimate row under the dash row: a charge bar, the key, "Ready" pulse. Same widgets as the dash row.
- **Rules owner:** a new `HeroUltimate` component on the Hero (like `HeroDash`); the effects are data in
  `HeroData` (`UltimateData` resource). UI only displays and sends the key.
- **Needs your answer before any code:** a new input action (CLAUDE.md rule 5) and the open questions in section 6.

## 1. Charge, use, limits

| Rule | Value (start) | Why |
|---|---|---|
| Charge needed | 100 points | one number to tune |
| Per kill by the hero or its minions | +2 (elite +10, boss +25) | rewards fighting, not only towers |
| Per 100 damage the hero or its minions deal | +1 | helps against bosses and big targets |
| Per second a wave is running | +0.5 | a hero who only dodges still gets it, slowly (about 1 use per 3 waves) |
| Cap | 100, no overflow | no hoarding |
| Carries | between waves and nodes of a chapter; **resets at a new chapter to 50** | each chapter opens with a half bar |
| While the hero is down | the bar is kept, no charge | no punishment beyond the respawn |
| Use | key Q (action `ultimate`), only with a full bar, not while dashing or down | |
| Pause / build phase | the key works in the build phase but the bar does not charge | no free farming |

Typical pace: a good player on a 2-wave node fills the bar about once. So an ultimate is a once-per-fight tool
for the nasty moment (a boss telegraph, a lane overrun), not a rotation.

## 2. The three ultimates

| Hero | Ultimate | What happens | Length | Why this one |
|---|---|---|---|---|
| **Knight** | **Last Stand** | A ring of light around the hero: enemies inside are pulled in and stunned 1.2 s, then take a big hit (6x the sword's damage, boss: 3x); the hero takes 50% less damage for 6 s and the sword arc is wider. | 6 s | The wall holds the line: the crowd comes to him |
| **Huntress** | **Volley of Ruin** | Rains 12 bolts over a 340 px line in the aimed direction; every enemy hit is Marked for 8 s (towers +15%, the card's bonus applies) and pierces ignore shields. | 2.5 s of volley | The skirmisher softens a lane for the towers |
| **Necromancer** | **Rise of the Dead** | Raises 5 skeletons at once, over the cap, near the hero for 12 s; they are fast and their first strike heals her for a little (Soul Feast stacks). | 12 s | The summoner's answer to a single big target: more bodies |

All three use existing pieces (the Knight's Bulwark/swing, the Huntress's mark, the Necromancer's `raise_minion`), so
the cost is the component, the three effects, the HUD row and sounds, not new enemy rules.

## 3. Cards (hero-exclusive, 2 per hero)

| Hero | Card | Effect |
|---|---|---|
| Knight | **Oathbound** | the ultimate charges 25% faster |
| Knight | **Wider Circle** | Last Stand pulls from 40% further |
| Huntress | **Quickdraw** | charges 25% faster |
| Huntress | **Rain of Spears** | 6 more bolts |
| Necromancer | **Grave Hunger** | charges 25% faster |
| Necromancer | **Crowded Crypt** | 2 more skeletons |

Rarity: common, stackable once. They draw from the hero's exclusive pool, like the Knight's cards (`exclusive_cards`).

## 4. HUD and feedback

- A row under the dash row: label **Ultimate**, a charge bar, "Q" (the bound key), "Ready" and a pulse when full.
- A short sound on full charge, one at use (`tools/audio/sfx_recipes.gd`: `ultimate_ready`, `ultimate_knight`, `ultimate_huntress`,
  `ultimate_necro`), screen shake obeys the shake setting, no hit-stop longer than a boss death's.
- The pause menu's controls list and `GameSettings.ACTIONS` gain "Ultimate".
- Tutorial tip once (`HintDirector`): "Your ultimate is ready: press Q" the first time the bar fills.
- Art: one effect sheet per ultimate drawn in code, at world resolution, in the hero's colours
  (`tools/art/effects_art.gd`): a light ring (Knight), bolt rain + landing marks (Huntress), a purple rising circle (Necromancer).

## 5. How it would fit the code (sketch)

- `resources/ultimate_data.gd` (`UltimateData`: kind enum, charge needed, durations, damage, counts, sound ids) referenced
  from `HeroData.ultimate`; one `.tres` per hero in `data/heroes/`. Balancing never touches code.
- `entities/hero/hero_ultimate.gd`: component beside `HeroDash`, like it: `charge`, `try_use()`, signals `charged`, `used`.
  Charge inputs come from the Hero's existing events (`slew`, a minion strike via the level, damage dealt) - the level connects
  them, the hero never reaches up. The effects are small scripts per kind (`ultimate_ring.gd`, `ultimate_volley.gd`,
  `ultimate_raise.gd`) spawned as one-shot scenes in `%Effects`.
- Input: **new action `ultimate` (Q)** in `project.godot`, `GameSettings.ACTIONS` and `ACTION_NAMES`. **Needs your OK** (rule 5).
- Save: the bar's value goes into `RunSave` (`save_state` / `load_state`) and across chapters through the existing carry
  (a float in `ChapterCarry`, reset to 50 on a chapter change).
- HUD: `hud.tscn` row + `hud.gd` reads `hero.get_ultimate()`; no logic.
- Tests: `test_ultimate.gd` (charge rules, cap, carry, each effect on a ghoul crowd and a boss, keys while down/dashing),
  update `test_screens_fit` (HUD at 70-120%), `test_sfx` (ids), `test_settings` (the rebind list).
- Balance: `balance_report.gd` / `map_balance.gd` hero bot learns to press the key when the bar is full and 6+ enemies are close;
  check win rate does not rise more than ~5 points on chapter 1 and the ultimate does not trivialise bosses (cap: bosses
  take at most 3x sword damage or 10% max HP from Last Stand).

## 6. Open questions

| # | Question | Recommendation |
|---|---|---|
| Q1 | Is a new `ultimate` input action (Q) OK? (CLAUDE.md rule 5) | Yes, Q; it is the usual key and is free |
| Q2 | Charge from play (section 1) or a plain cooldown (e.g. 45 s)? | From play: it rewards the hero actually fighting, and avoids a second timer next to the dash |
| Q3 | One ultimate per hero, or a choice of two per hero? | One for now; a second can come with a card ("Last Stand: Bulwark" variant) later |
| Q4 | Does the bar carry between chapters? | Resets to 50 (half) so each chapter opens with something |
| Q5 | Which ultimate behaviours do you want changed? | Keep section 2 as is, and tune after one playtest |
| Q6 | Should ultimates exist in the Endless / Pressure modes unchanged? | Yes; a Pressure switch "No ultimates" could come later (not now) |
