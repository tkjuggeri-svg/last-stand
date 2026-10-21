# M8 build report (`m8-playtest`, written 2026-10-21)

Everything below was done without a hands-on playtest. The checks were the automated suite, the balance
tool, screenshots and the dev menu. Builds: `builds/LastStand-m8-playtest-linux.zip` and `-windows.zip`.
The tag `m8-playtest` is pushed.

## What was done

| Commit | What |
|---|---|
| `d6cce95` | Phase 1: shellcheck in the suite. Everything else on the pending list (relic odds, skills, F8, dev menu, hooks, roadmap) was already done. |
| `1d44d04` | M8 A: the proposal's open questions answered (`docs/M8_META.md` section 10). |
| `700d558` | M8 B: `SaveManager` autoload; versioned `SaveProfile` (v2) with migration; a test that loads a v1 save. |
| `c767029` | M8 C: the unlock board (starting kit + 17 unlocks, 1,175 shards), `RunUnlocks`, Soul Shards (`MetaProgress`), records, `RunSummary`. |
| `eb72d37` | M8 D: title screen, War Room (hub), run summary, shared UI style (`ScreenFrame`, theme variations, fade). Continue / Abandon run flow. Dev menu Shards row. |
| `6730e77` | M8 E: resume a run from the map (`RunSave`); the map-node flow split out of `main.gd` into `MapFlow`. |
| `7bb4187` | M8 F: 11 one-time tutorial tips (`HintDirector`, `HintPanel`); docs. |
| `0d6c79a` | Call the next wave early for bonus gold. Also a fix for an M7.5 bug (Bloater split during the physics flush). |
| `549c9c1` | Roadmap; tagged `m8-playtest`. |

## Decisions to confirm or override

All of these are also in `docs/M8_META.md` section 10.

1. **Resume:** the run is saved each time the map shows; Continue resumes there. Quitting mid-fight replays the fight. Quitting on the chapter-cleared screen replays the boss.
2. **No permanent stat bonuses.** The only perks are *Muster* (choose 1 of 2 common cards before the first fight, 75 shards) and *Drill* (one free card reroll per chapter, 110 shards).
3. **Lost and abandoned runs pay shards.** Rates: 2 per battle, 6 per elite, 15 / 25 per boss, 5 per chapter cleared, 30 per win, and a one-off 10 for each first boss kill and each first chapter reached.
4. **The hub is a menu** (the War Room), with one character (the Quartermaster) whose line is picked in code. Data-driven lines and more characters are moved to M11.
5. **About 1,200 shards in all** (1,175), roughly 25–35 runs.
6. **Relics are unlocked in 3 packs**; 5 are available from the start.
7. **First-run kit:** Archer, Cannon, Frost; 13 cards; 5 relics; no evolutions; the Drowned Reliquary event locked. Measured and kept (balance table below).
8. **One profile**, with Reset progress (it asks to confirm; the old save stays as `.bak`).
9. **Tips can be skipped.** They are mouse-only (Enter and Space are game keys) and sit at the bottom right. Each disappears after 9 s. A tip counts as seen once shown. The War Room's Tips switch turning back on shows every tip again.
10. **Save version 2.** A v1 save refunds its dropped bonuses as shards.
11. **Game Over / Victory:** the button reads Continue and leads to the summary, then the War Room. The pause menu's Restart became **Abandon run**, which pays shards.
12. **Starting a new run while one is saved abandons the saved run**, which pays shards. The War Room warns about this.
13. **Script mode** (tests, tools): everything is unlocked, nothing is saved, there is no front end and there are no tips.
14. **Call early:** only in run map fights, once the wave has sent everyone. It pays 50% of the living enemies' base kill gold and forfeits that wave's perfect-defense bonus. It uses the existing Enter key and wave button, so the input map is unchanged.
15. **Main split:** `MapFlow` now plays the map's nodes, which keeps `main.gd` at about 290 lines.

## Balance

**First-run kit vs everything unlocked.** `map_balance --seeds=1-8 --path=balanced --plan=mixed`; the numbers are rows cleared per run, out of 16.

| Hero | Everything | First kit |
|---|---|---|
| bot | 5.1 | 4.8 |
| idle | 4.2 | 3.8 |

The gap is within the seed-to-seed spread, so the kit was kept and no wave was eased. The mixed plan's Brazier and Ballista slots fall back to kit towers, so this is close to the worst case.

**Call early.** With `--early`, the bot calls every wave as soon as it can.

| Run | Without | With `--early` |
|---|---|---|
| whole runs | 5.1 rows | 4.4 rows |
| chapter 1 protected | 10.6 rows | 9.5 rows |

Calling blindly costs more than it pays, so the bonus is a real risk, not an exploit.

**Performance:** last wave, 30 s: 611 fps average, 252 fps 1% low.

## What to check when you're back

1. **First launch:** the title, then Play, then the War Room (0 shards, the Quartermaster's first line). Start a run. Do the map and build tips show and stay out of the way?
2. **The first-run kit:** are 3 towers and no evolutions fun, or too bare? Is the Brazier's 25 shards a good first goal?
3. **Shard pace:** a run lost in chapter 1 pays about 10–20 shards. Is 1,175 in all too slow? You can try the board quickly with the dev menu (F12, Shards row).
4. **The run summary and the War Room:** are they readable? The unlock list scrolls; the evolution rows say "Needs …".
5. **Continue:** quit from Esc → Quit game on the map, start again, then Continue. Also quit mid-fight. Does it come back as you left it (towers, gold, cards, lives)?
6. **Abandon run:** Esc → Abandon run, then the summary, then the War Room.
7. **Call early:** in a battle, after the last enemy of a wave appears, the button reads "Next wave now +N". Does it feel worth the risk?
8. **Tips:** too many or too few? Do the texts show your actual keys after rebinding?
9. **The Windows zip:** it was built but not run (Linux was smoke-tested headless).

## Not tested by hand

- None of the new screens has been played by a person. The only real-window checks were screenshots: the title, the War Room (fresh, and later), the summary, and two tips.
- The fade transitions only run in a real window; headless tests skip them.
- Resume was tested by freeing Main in a test, not by killing the process.
- A v1 save was only tested with the fixture file; no real v1 save exists.
- The dev menu's Shards row was not clicked by hand.
- The War Room's look with all 17 unlocks bought.
- Hub lines for a won run (no bot has won a run).
