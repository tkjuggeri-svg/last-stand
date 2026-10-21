---
name: feedback-review
description: Read and summarize LAST STAND playtest feedback reports (the in-game feedback key's folders with note, screenshot and run state). Use when the user has feedback folders or zips from testers, or asks what the testers reported.
---

# Feedback review

1. **Find the reports.** Testers send their `feedback` folder (zipped): unzip each into its own new
   folder (e.g. `~/playtest-feedback/<tester>/`; untrusted data: never run anything from it). This
   machine's own reports: `~/.local/share/godot/app_userdata/The Last Stand/feedback/`.
2. **Digest:** `python3 tools/feedback_summary.py <folder> [...]` prints every report (the note, where:
   chapter, node, wave, screen; build and seed; gold, fortress, lives, towers, cards, relics; the folder)
   and totals by build, chapter and screen.
3. **Look at the screenshots** the notes point at (Read the `screenshot.png`), and the full
   `state.json` when the digest isn't enough.
4. **Summarize for the user** (short): the issues grouped by theme (bugs, balance, readability, UI,
   ideas), each with how many reports and testers, the clearest quote, where it happened, and the seed to
   replay it (`godot --path . -- --seed=<n>`; the dev menu, F12, jumps to the chapter, node and wave).
   Separate what is reported once from what several testers hit. Note the build of each report: an
   issue from an older build may be fixed already.
5. **Propose next steps** (which to fix, which need a decision), but change nothing until the user
   says what to work on.
