# Handoff (rewritten 2026-10-27, branch `art/handoff-integration`, after `m13-playtest-4`)

Read `CLAUDE.md` first (its rules still apply), then this, then `ROADMAP.md` (Current focus), `PLAYTEST.md` and `docs/M14_SCOPE.md`.

## Where things are

| Branch | What | State |
|---|---|---|
| `main` | the older line | **do not merge anything into it** until the owner decides after playtesting; never push it |
| `art/handoff-integration` (current) | all of M9-M14 so far, the art pass, the playtest fixes, hero ultimates; tag **`m13-playtest-4`** (`d130d67`); ROADMAP M14-M16 and the parking lot are here | pushed; **the real work branch** |
| `look-test` | experiment: three "HD-2D" looks for the graveyard (A, B, C), `docs/LOOK_TEST.md` | pushed; **never merge**; its only game-code change is `WorldPointer` (2 call sites) |
| `wip/more-slots` | an old unfinished local branch from before this work | local only, ignore unless the owner asks |

## State of the game

- M0-M13 built. **M14 (Fix & Finish)** is in progress: playtest fixes done, **hero ultimates (Q) done** (`docs/M14_ULTIMATES.md`:
  Last Stand, Volley of Ruin, Rise of the Dead; two cards each). M15 (Art Overhaul, `docs/ART_BACKLOG.md`) and M16 (Outside
  Playtest, optional) are planned, not started.
- The Knight's extra cards and relics (Bulwark, Shield Bash, Oathkeeper, Rally, Iron Will, Crown of Thorns, Banner of the Last
  Keep) and the hero stories are **built** (`docs/M9_HEROES.md` "Knight leftovers", `test_knight`); only hand-checking remains.
- Latest build: **`m13-playtest-4`** (builds in `builds/`, git-ignored; `-dev-` zips have F12). What to test is at the top of
  `PLAYTEST.md` (ultimates: how often ready, Q feel, balance between the heroes, clarity), then the `m13-playtest-3` list
  (War Room pages, scrolling stories, cards only for buildable towers, chapter 2 rows 5-6 eased), then the older list.

## What we are waiting for

1. **The owner's playtest of `m13-playtest-4`**: F8 reports (`~/.local/share/godot/app_userdata/The Last Stand/feedback/`; use the
   `feedback-review` skill) and their words. The bot dies in chapter 1 (about 6.5 rows of 24), so only a human can judge chapter 2's
   economy, the music, the story texts, the map art and the ultimates.
2. **Approval of M14's scope** (`docs/M14_SCOPE.md`, a proposal with open questions Q1-Q7; its "Playtest findings" section is
   empty for the feedback). **Nothing gameplay is started before that** (CLAUDE.md rule 7).
3. **A look direction (undecided)** from the `look-test` branch / `exports/look-test/` (git-ignored: `compare_all_4.png`, `look_*.avi`,
   `REPORT.md`): current / A (2D lights, normals, bloom) / B (3D tilted camera, 79 fps vs 437, big adoption cost) / C (A + fake 2D
   depth; "too dark but looks okay", bottom overlay removed). Forward+ is not needed for any. Nothing is adopted.

## Open items

- M14 (see the scope): tests for Hardened Elites and Stronger Bosses (none exist); Hardened Elites does not force an affix (the
  proposal drops that rule); the Hasty Waves countdown has no sound; chapter 1's row steps (x2.99, x2.41 in Crypt Road);
  chapter 2's economy.
- ROADMAP hands-on boxes for `m7.5-playtest` are still open.
- **Fixed this session:** `perf_report.gd` and `trailer_capture.gd` index their tower lists with `i % size` (13-16 slots).
- **`claude-code-infinite`** (npm package source in `claude-code-infinite-1.0.30/`, excluded in `.git/info/exclude`): read, **not**
  installed (anonymous ping, content to a paid third party). Never commit that folder.
- `docs/docs/` is a stray untracked folder of the owner's: leave it alone, never `git add` it.

## How to work here (things that bit)

- **Never run two Godot jobs at once** (the suite corrupts). Full suite: `rm -f override.cfg; (setsid tests/run_tests.sh > $CLAUDE_JOB_DIR/tmp/suite.log 2>&1 &)`
  and wait for `ALL PASSED|FAILED|TIMED OUT`; never `pkill -f run_tests.sh`. Strict check of one file: `godot --headless --path . --script res://tests/tools/write_strict_override.gd`,
  then `godot --headless --path . --check-only --script res://<file>`, then `rm -f override.cfg`.
- Stage with `git add -A . ; git reset -q docs/docs`. Commit messages end with `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_014TCAqg4UwDKoJYs4brpQUg`. Never force-push; never push `main`.
- Ask before autoloads, physics layers, input map or folder moves.
- Playtest build: skill `playtest-build` (`tools/build_playtest.sh [--dev]`; the next tag is `m13-playtest-5`; never reuse a pushed tag).
- Look test tools (branch `look-test`): `experiments/look_test/look_runner.gd -- --variant=base|a|b|c [--measure] [--shots=..] [--hero-at=x,y]`.
- Art, sound and music are generated in code (CLAUDE.md pipelines); never hand-edit generated files.
- The owner prefers: decisions made for them when there is a sensible default, short reports that say plainly what was and was not
  verified, no merging until they say so.
