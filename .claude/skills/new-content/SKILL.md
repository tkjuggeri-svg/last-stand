---
name: new-content
description: Checklist for adding any new enemy, tower, relic, upgrade card, event or biome to LAST STAND. Use whenever new game content is added, so nothing (art, hint, tests, balance, docs) is forgotten.
---

# New content checklist

The scope must be approved first (CLAUDE.md rule 7). Then, for each new thing:

1. **Data, not code.** A `.tres` from its Resource class in `data/<kind>/` (`EnemyData`, `TowerData`,
   `UpgradeData`, `RelicData`, `EventData`, `ChapterData` + a level scene). Behaviour goes in a small
   component (`EnemyAbility`, a system node with exported references), never in a new base class.
   Wire it where it's drawn from: the level's offer pools (both arenas), the chapter's events, the
   waves (`tools/make_waves.py`, then rerun it; never hand-edit the wave files).
2. **Art per ART_DIRECTION.md.** Drawn in code (`tools/art/<thing>_art.gd` on `canvas.gd` and
   `palette.gd`), sprite scale 2, 1 px outline, light from the top-left, readable silhouette; red only
   as an accent (enemy eyes). Layout in `sheet_layouts.gd`, a job in `generate_art.gd`, then
   generate → import → `build_sprite_frames.gd`. Preview the sheet enlarged, and check it in the game
   (`tests/tools/level_shot.gd`, `capture_screenshots.gd`).
3. **Readable in play.** Every ability telegraphed (a `TelegraphMarker`, an animation); a new enemy gets
   `EnemyData.hint` (the banner the first time it appears); an icon and a one-line description that
   says what it really does, with numbers.
4. **Tests.** `tests/automated/test_<feature>.gd` driving the real scenes (each rule, each edge: freed
   objects, waves cleared, nothing-left cases), and a sandbox scene in `tests/` (F6). A new card or
   event answer must pass `test_card_impact` (a real effect); a relic needs its rule in `test_relics`.
5. **Balance.** `tests/tools/map_balance.gd` (whole runs and `--protect-ch1`), bot and idle hero,
   before and after. For towers and fire/damage cards also the single-type spam check
   (`--plan="all <tower>"`, `braziers first`, `--fire=with|without`): no single-type spam may beat the
   best mixed build. For a relic, `--relics=<id>` against `--relics=none`. Report the tables.
6. **Docs.** `GAME_DESIGN.md` (the numbers and the why), the milestone's design doc if there is one,
   `ROADMAP.md`, `PLAYTEST.md` if players will see it, `assets/CREDITS.md` only for third-party assets.
7. **Suite.** `tests/run_tests.sh` ends `ALL PASSED` (warnings are errors: no shadowed names, typed
   ternaries, no integer division).
