# M13: Audio & Presentation (design proposal)

> **Status: approved on the recommendations (the user's blanket permission of 2026-10-25), being built.**
> Section 8 lists the decisions.

## 0. Summary

- **Music**, synthesized in code like the sound effects (no external assets): a handful of looping tracks
  (title, the War Room, the three tiers' fights, the boss, victory, game over), written as note patterns in
  `tools/audio/music_recipes.gd` and rendered to loops. A small `Music` player (a static class plus a node under
  Main, no autoload) crossfades between them on the Music bus.
- **Credits** (a screen from the title: the game's makers and the assets' provenance: everything original,
  code-drawn and code-synthesized).
- **An art pass**, limited to what can be done in code: the first-pass towers and heroes of M9 get a second
  look (larger, clearer silhouettes for the new towers), hero portraits already exist (M11), the bosses get side
  views only if cheap (they do not: left out).
- **Trailer material**: a scripted capture (`tests/tools/trailer_capture.gd`) that plays a 30-second montage
  (a build phase, a fight with each hero's towers, a boss, the ending) and saves PNG frames and a text storyboard;
  a `docs/TRAILER.md` shot list.
- **A performance pass**: every biome's last wave measured (`perf_report.gd --biome`), the worst fixed (lights,
  particles).
- **A bug bash**: a long scripted soak (`tests/tools/soak.gd`: whole runs with each hero on random biomes and
  roads, random card, merchant and event choices, many seeds) that must finish without errors or stuck states.
- **No new autoload, layer or input action.**

## 1. Music

- Style: 16-bit dark fantasy, minor keys, slow tempos for the keep, driving for fights: square/triangle/noise
  voices and a bass line, 8-16 bar loops, about 45-70 s each, 16-bit mono 22 kHz WAV (loop points set).
- Tracks (12): `title`, `war_room`, `map` (the run map), `fight_1`, `fight_2`, `fight_3` (one per tier),
  `boss`, `finale`, `victory`, `defeat`, `credits`, `shop` (merchant and events).
- The Music bus already exists (`default_bus_layout.tres`); the settings' music volume works.
- `Music` (a static class plus its player node, created by Main): `Music.play(node, &"fight_2")`
  crossfades (1.2 s), keeps the position of a track returned to, ducks under the pause menu.

## 2. Credits

A screen reached from the title (`CreditsScreen`): the title, "made by" (the user), a line on how the game was
made (original, code-drawn and code-synthesized art and sound, GDScript, Godot 4.7), Godot's licence notice, and
the tools. Scrolls slowly; Esc closes.

## 3. Art pass

- The M9 towers (Trap Layer, Hawk Perch, Watchtower, Bone Pit, Soul Siphon, Ossuary) are redrawn larger
  (the Archer's footprint), with the build, sell and fire frames kept.
- The biomes' props get more variety (12 instead of 8 each).
- Anything that needs hand art (the bosses' side views, portraits of the bosses) is listed in
  `docs/ART_BACKLOG.md` for an artist.

## 4. Trailer, performance, bug bash

As in the summary. The soak is the final gate before a release build.

## 5. Build order

| Stage | Contents |
|---|---|
| 1 | the music tools and tracks, the `Music` player and its wiring |
| 2 | credits, the art backlog, the art pass |
| 3 | trailer capture, the performance pass |
| 4 | the soak and the fixes it finds |

## 8. Decisions

On 2026-10-25 the user's blanket permission settled this proposal: everything above stands as written, taken
at the recommendation of each choice (from: recommendation). Save points: git tags `save/m13-<stage>`.

## 9. As built

- **Music:** 12 tracks from `tools/audio/music_recipes.gd` (key, scale, tempo, chords, voices) rendered by
  `music_synth.gd` into `assets/audio/music/<id>.wav` (16 kHz mono loops, 25-58 s, 14 MB in all; the import
  compresses them for the export). `Music` (`core/utils/music.gd`, a static class like `Sfx`, no autoload):
  crossfade 1.2 s, remembers a track's position, ducks under the pause menu (`Music.set_ducked`). The import
  does not keep a generated WAV's loop, so `Music` loops a copy. Wired: title, War Room, map, fights (by tier,
  a descent keeps the third), boss, shop and events, ending (`finale`), victory, defeat, credits.
  **Nobody has listened to it yet**: it was checked for level, clipping and seams, not for taste.
- **Credits:** `CreditsScreen` from the title (a scrolling modal; "A game by Tony" and the Godot licence notice
  are placeholders for the user to correct); music added to `assets/CREDITS.md`.
- **Art:** the art pass itself was **not done** (it needs eyes on the result); `docs/ART_BACKLOG.md` lists what
  an artist should take: boss side views, the biome enemies' own silhouettes, boss portraits, the M9 towers,
  rubble, hazards, ending illustrations.
- **Trailer:** `tests/tools/trailer_capture.gd` (18 frames and a storyboard in a real window) and
  `docs/TRAILER.md`.
- **Performance:** `perf_report.gd --biome=<id>` plays a biome's boss-fight last wave with every tower built.
  All nine, 40 s each, 1280x720, vsync off: average 375-533 fps, 1% low 128-228 fps, worst frame 9.6-19 ms; the
  heaviest is the Pale Cathedral (117 enemies at once). Nothing needed fixing.
- **Soak:** `tests/tools/soak.sh [seeds] [limit]` plays `map_balance.gd` for every hero x path policy x
  Pressure none/all and scans the output for errors: 18 combinations, seeds 1-2, SOAK PASSED. **Honest limit:**
  the bot dies in chapter 1 or 2 and never reaches the late biomes, the endings or a descent, so the soak
  covers the early game and Pressure, not the end; those are covered by the unit tests and need a human.
