---
name: playtest-build
description: Make an internal playtest build of LAST STAND (suite, tag, Linux + Windows zips, push, PLAYTEST.md). Use when the user asks for a playtest build or a rebuild (e.g. "build m7.5-playtest-2").
---

# Playtest build

1. **PLAYTEST.md first.** Update it for what changed since the last build (new rules, maps, enemies,
   numbers the player sees) and add feedback questions for the new things. It ships inside the zips.
2. **Everything committed.** `git status` clean (the version comes from `git describe --tags`; a
   dirty tree gives "-dirty"). Commit the docs with the work, ending with the attribution lines.
3. **Tag** the commit: `git tag <milestone>-playtest[-N]` (lightweight, like the others; never move or
   reuse a pushed tag: bump `-N`).
4. **Build:** `tools/build_playtest.sh` (runs `tests/run_tests.sh` first and refuses to build unless it
   ends `ALL PASSED`; exports with the Godot 4.7.2 templates). Expect
   `builds/LastStand-<tag>-linux.zip` and `-windows.zip`; warnings or errors in the export are failures.
   If the suite fails: fix, commit, delete the unpushed local tag (`git tag -d`), tag again.
5. **Smoke test** the export outside the project:
   `cd /tmp && timeout 60 <repo>/builds/linux/LastStand.x86_64 --headless --quit-after 300` (no errors).
6. **Push:** `git push origin main` and `git push origin --tags`; check the tag is on `origin`.
7. **ROADMAP.md:** the milestone's build line and "Current focus" (waiting for playtest feedback).
8. **Report:** the tag, the two zip paths, what's in this build vs the last, anything not tested.
   Then wait for the playtest feedback; don't start the next milestone.
