# Handoff (written 2026-10-26, before the conversation was cleared)

Read `CLAUDE.md` first (its rules still apply), then this, then `ROADMAP.md` (Current focus) and `PLAYTEST.md`.

## Where things are

| Branch | What | State |
|---|---|---|
| `main` | the older, released-to-nobody line | **do not merge anything into it** until the owner decides after playtesting |
| `art/handoff-integration` | all of M9-M13, the art pass, the playtest fixes; tag **`m13-playtest-2`** (`e740c08`), head `ed12865` | pushed; the real work branch |
| `look-test` (current) | experiment: three looks for the graveyard, ROADMAP M14-M16, this file | pushed; **never merge**; its only change to game code is `WorldPointer` (2 call sites) |
| `wip/more-slots` | an old unfinished local branch from before this work | local only, ignore unless the owner asks |

The ROADMAP's M14-M16 and the restored parking lot exist **only on `look-test`**. When work resumes, cherry-pick
`4d527fe` (and this handoff commit) onto `art/handoff-integration`, or ask the owner which branch to continue on.

## What the owner is waiting to test / decide

1. **Playtest `m13-playtest-2`** (builds in `builds/`, git-ignored; `-dev-` zips have F12). Questions are at the top of
   `PLAYTEST.md`: menus fit, interface size (70-120%), 16/13-15 build slots and **Masterwork** ranks (is chapter 2 still
   starved of things to spend gold on?), homing Necromancer bolts, the run map's art, plus the older list (music, three
   heroes, tier-3 biomes, endings, Endless, Pressure, story). Feedback arrives as F8 reports
   (`~/.local/share/godot/app_userdata/The Last Stand/feedback/`; use the `feedback-review` skill) and the owner's words.
2. **Choose a look direction** from `exports/look-test/` (git-ignored; `compare_all_4.png`, `look_*.avi`, `REPORT.md`):
   current / A (2D lights, normals, bloom) / B (3D tilted camera, 79 fps vs 437, big adoption cost) / C (A + fake
   2D depth: depth scale, haze, parallax backdrop; the owner said "too dark but looks okay", then "ditch the black overlay from the
   bottom"; both done). Forward+ is **not** needed for any of them. Nothing is adopted.

## Pending / open items (none started)

- **M14 Fix & Finish**: playtest fixes; Knight extras, hero stories, Pressure switches by hand; tests for Hardened Elites and
  Stronger Bosses (they have none; Hardened Elites does not force an affix; the Hasty Waves countdown has no sound);
  chapter 1's row steps (x2.99 and x2.41 in Crypt Road); chapter 2's economy.
- **M15 Art Overhaul**: `docs/ART_BACKLOG.md`, the recoloured placeholder enemies, the new Knight design, warm defenders vs cold dead.
- **M16 Outside Playtest** (optional).
- **Known bug:** `tests/tools/perf_report.gd` and `tests/tools/trailer_capture.gd` index a 10-entry `TOWERS` list with the
  new 16 graveyard slots (fix: `TOWERS[i % TOWERS.size()]`, as `experiments/look_test/look_stage.gd` does).
- **Balance facts:** the weak bot (`tests/tools/map_balance.gd`) dies in chapter 1 (about 6.5 rows of 24, unchanged by more slots or
  Masterwork); `--start=2` gives about 1.5 rows. So only a human can judge chapter 2/3. Chapter 2's row ramp is even
  (x1.6-1.85). Nothing was measured by the bot for the slot-fill target (half to two thirds).
- **`claude-code-infinite`** (an npm package source the owner dropped in `claude-code-infinite-1.0.30/`, excluded in
  `.git/info/exclude`): I read it and did **not** install it (an anonymous ping, content sent to a paid third party). The
  owner has not asked again; never commit that folder.
- `docs/docs/` is a stray untracked folder of the owner's: leave it alone, never `git add` it.

## How to work here (things that bit)

- **Never run two Godot jobs at once** (the suite corrupts). Full suite: `rm -f override.cfg; (setsid tests/run_tests.sh > $CLAUDE_JOB_DIR/tmp/suite.log 2>&1 &)`
  and wait for `ALL PASSED|FAILED|TIMED OUT`; never `pkill -f run_tests.sh`. Strict check of one file: `godot --headless --path . --script res://tests/tools/write_strict_override.gd`,
  then `godot --headless --path . --check-only --script res://<file>`, then `rm -f override.cfg`.
- Stage with `git add -A . ; git reset -q docs/docs`. Commit messages end with `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_014TCAqg4UwDKoJYs4brpQUg`. Never force-push; never push `main`.
- Gameplay needs the owner's approval of the feature scope first (CLAUDE.md rule 7); ask before autoloads, physics layers, input map or folder moves.
- Playtest build: skill `playtest-build` (`tools/build_playtest.sh [--dev]`, tag `m13-playtest-3` next; never reuse a pushed tag).
- Look test tools (branch `look-test`): `experiments/look_test/look_runner.gd -- --variant=base|a|b|c [--measure] [--shots=..] [--hero-at=x,y]`,
  `feature_probe.gd`, `test_look_b_mouse.gd`; `exports/` has a `.gdignore` so Godot does not import the shots.
- The art, sound and music are all generated in code (see CLAUDE.md pipelines); never hand-edit generated files.
- The owner prefers: decisions made for them when there is a sensible default ("don't ask, just do them all"), short reports that say
  plainly what was and was not verified, no merging until they say so.
