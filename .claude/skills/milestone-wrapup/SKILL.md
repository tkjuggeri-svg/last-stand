---
name: milestone-wrapup
description: Finish a milestone or one of its phases in LAST STAND (suite on the exact commit, self-review, its own commit, push, report, wait). Use at the end of every phase or milestone, or a playtest-fix round.
---

# Milestone / phase wrap-up

1. **Only this phase's changes in the commit.** If later work is already in the tree, stage by path
   (`git add <files>`); a file with both, stage a version without the later part and restore it after.
2. **Review the staged diff** (`git diff --cached`): CLAUDE.md conventions (static types, member order,
   comments say why, no `get_parent()` chains, ~300 lines per script), dead code, stale doc comments,
   docs and ROADMAP.md ticked.
3. **Commit** with a message that says what changed and why (the playtest quote, the numbers), ending
   with the attribution lines.
4. **Run the suite on that exact commit**, not on the working tree: a detached checkout
   (`git worktree add --detach <dir> HEAD`, copy `.godot/`), `tests/run_tests.sh` there, alone (two
   suites in one checkout corrupt each other). It must end `ALL PASSED`. On a failure: fix, amend (only
   if not pushed), rerun. Remove the checkout afterwards (`git worktree remove`).
5. **Performance** when a level or many entities changed: `tests/tools/perf_report.gd` (both chapters).
6. **Push:** `git push origin main` and `git push origin --tags`. Never force-push or rewrite pushed
   history.
7. **Report** (short, in this order): what was done per phase with its commit hash; the balance tables
   before/after (bot and idle, chapter 1 and chapter 2); decisions I made and why (and what to change if
   the user disagrees); what wasn't done or isn't sure, honestly (targets not met, noise in small
   samples); where things are (paths, tags, builds).
8. **Wait for the user's feedback.** Don't start the next milestone.
