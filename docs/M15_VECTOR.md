# M15 — Vector Art: the whole game in the vector style (proposal)

**Status: proposal, not approved, not implemented.** The owner chose the direction on 2026-10-27 ("lets go full on
vector baby") after two rounds of `vector-test` (`docs/VECTOR_TEST.md`, branch `vector-test`). This doc says how. Effort
numbers are estimates from those tests (sessions = one working session like the ones that built the test), not
measurements. It replaces `docs/M15_ART.md` (Pixellab, superseded). Art only: no gameplay, balance, input, physics
layer or data change. The code changes are visuals and the art pipeline.

## 0. Summary

- **Every piece of art is redrawn as vector, in code**, in the style of round 2 of the test:
  - Shapes: smooth, with painted shading (cool shadows, warm highlights, a cold moonlight rim) and thin dark outlines.
  - Glow and light: soft additive glows.
  - Theme: warm defenders against cold dead, the same as today.
- **The pipeline stays the same, only the drawing changes.** Painters in `tools/art/` draw each animation frame as vectors
  and bake it offline into PNG sheets at 2x; `build_sprite_frames.gd`, `DirectionalSprite`, the SpriteFrames and every
  game scene stay as they are. Runtime cost equals today's sprites (the test measured 7.4 ms live vs 2.8 ms for sprites;
  a bake removes the difference).
- **What gets added on top of the sheets:**
  - Glows: an additive sprite or `PointLight2D` per glowing part.
  - Mist and embers: `GPUParticles2D`.
  - Ground: baked once per level into its texture, as now.
- **About 160 assets** in 8 phases (section 2). The first playable is a **chapter-1 vertical slice** (the graveyard, its
  enemies, the five base towers, the Knight, the fortress, the core effects), playtested before the rest.
- **Rules change:**
  - CLAUDE.md: the Pixel art section becomes an Art section (2x sheets drawn at 0.5 scale, linear filtering, no 1 px
    pixel outline rule).
  - `ART_DIRECTION.md`: rewritten for vector.
  - Kept: `test_readability`, the grayscale check and the role eye colours.
- **The pixel font and UI frames are replaced** by a vector UI theme and a smooth font. A font must be self-made or CC0
  by CLAUDE.md rule 3, and good CC0 fantasy fonts are rare, so Q3 asks for an exception for SIL OFL fonts.
- **The Pixellab Knight is retired** with the rest of the pixel art (the vector Knight replaces it).
- **Work happens on a branch** (`m15-vector`, from `art/handoff-integration`), with a playtest build at the end of each
  phase. During the change a run can cross a vector chapter 1 into a pixel chapter 2; that's accepted for internal
  builds only.
- **Estimate:** about 50-65 sessions in all; the chapter-1 slice is about 12-15.

## 1. The look (the test, fixed as rules)

| Rule | Value | Why |
|---|---|---|
| Shading | base gradient + cool shadow band (away from the light, top-left) + warm highlight + cold moonlight rim, bands a third of the shape | what lifted round 2 above "Flash game"; it reads at 40-50 px |
| Outline | 1.2 px dark `#1a141f` antialiased stroke on every shape, at sheet resolution | separates characters from the ground without the pixel outline |
| Light | warm key from the top-left; defenders lit warm, the dead rimmed cold | the theme |
| Glow | additive radial glow sprites (eyes, torches, swings, magic), cached | the "epic" part; cheap |
| Readability | characters brighter / higher contrast than the ground; role eye colours (`EnemyRoles`); grayscale check | unchanged rule |
| Detail floor | nothing smaller than 1.5 sheet px at the character's size | below that, vector detail blurs into the fills (the test's finding) |
| Size | figures may be drawn **up to 1.25x** today's figure height (Q2), collision unchanged | gives the detail room; the test Knight at 1.2x looked right |
| Ground | noise-textured base, painted details, baked once per level at 2x | test round 2 |

## 2. What is redrawn, and in what order

| Phase | Items | Count | Sessions |
|---|---|---|---|
| **P0 Pipeline** | the offline bake tool (painters to PNG sheets through a SubViewport, run with a window: baking needs the GPU), `VectorPaint`/`VectorStyle` moved from the test into `tools/art/vector/`, glow sprite and particle helpers, the 2x sheet / 0.5 scale / linear filter switch for converted nodes, CLAUDE.md and ART_DIRECTION rewrite, tests | 1 tool | 3-4 |
| **P1 Chapter-1 slice** | Knight (all states: idle, walk, attack, dash, death, hurt, ultimate pose), Ghoul, Hound, Brute, Cultist; Archer, Cannon, Frost, Brazier, Ballista (3 levels, build, fire, sell); the fortress (4 damage states); the graveyard ground, props, crypt, build pad; swing trails, hit spark, death dust, the five towers' projectiles and impacts | 5 + 5 + 1 + ground + ~10 fx | 12-15 |
| **P2 Chapter-1 bosses + UI** | Gravelord, Bone Colossus, Lich Warden (with side views, which the pixel art never had); the HUD, menus and cards in a vector theme; the new font | 3 + UI | 7-9 |
| **P3 Heroes** | Huntress, Necromancer, the Skeleton minion; their six towers (Trap Layer, Hawk Perch, Watchtower, Bone Pit, Soul Siphon, Ossuary); the three ultimates' effects | 3 + 6 + 3 | 7-9 |
| **P4 Tier 2** | Drowned Marsh, Bone Quarry, Frostbound Pass: grounds, props, gates; Bloater, Bloatling, Mire Priest, Shieldbearer and the tier's biome enemies and bosses | 3 maps + ~10 | 8-10 |
| **P5 Tier 3** | Ashen Keep, Sunless Mines, Pale Cathedral (and the remaining tier-1 biomes: Gloam Wood, Ember Orchard): grounds, props, gates, enemies, bosses | 5 maps + ~12 | 8-10 |
| **P6 Evolutions** | the 2 evolution branches per tower and the combo evolutions | ~24 | 4-6 |
| **P7 Front end** | title key art, the War Room portraits (6 + 3), the run map, card and relic icons (~60, simple), ending illustrations (4), credits | screens + ~75 | 6-8 |

**Order:** P1 first, as one complete screen, so the look is judged in play, not on a sheet. A family goes in whole: no
half-vector Ghoul. Each phase ends with the suite, the review shots, `perf_report` and a playtest build.

## 3. How a vector sprite is made (the pipeline)

| Step | What happens | Where |
|---|---|---|
| 1 | A painter draws one frame from a pose: `paint(ci, {facing, state, t})`, the way `KnightPainter` does in the test | `tools/art/vector/<family>_painter.gd` |
| 2 | Animation is the pose over time: legs, cloth, sway, lunge, fall, all parametric (12 walk, 8 idle, about twice today's attack and death frames) | the painter |
| 3 | The bake tool renders every frame of every animation in `sheet_layouts.gd` at 2x into the sheet PNG (SubViewport, premultiplied alpha, then straight alpha on save) | `tools/art/vector/bake_sheets.gd` (new) |
| 4 | `build_sprite_frames.gd` builds the SpriteFrames as now; the scenes' sprite nodes get `scale = 0.5`, linear filtering | existing |
| 5 | Glowing parts are separate: a glow layer (additive sprite) or a `PointLight2D`, positioned by the animation's anchor points (exported with the sheet) | per entity scene |
| 6 | Grounds bake as now (`biome_art.gd` / `map_ground_art.gd` become vector painters), drawn at 2x and scaled down | `tools/art/` |

Nothing in the game reads art to make decisions (CLAUDE.md "visuals follow gameplay"), so no system changes.
`ART_SPEC.md` gets the new frame sizes.

## 4. How it would fit the code (sketch)

- **New:**
  - `tools/art/vector/`: `vector_paint.gd`, `vector_style.gd`, `bake_sheets.gd`, one painter per family (moved and
    grown from the test).
  - `entities/effects/glow_layer.gd`: a small display-only component for glows on scenes.
- **Changed per family:**
  - The scene's sprite `scale` and `texture_filter`.
  - Its SpriteFrames, regenerated.
  - `generate_art.gd`'s jobs: the pixel job is removed when its vector sheet lands.
- **Project setting, at the end of P7:** the default texture filter becomes linear and 2D pixel snap is switched off.
  Until then, converted nodes override it (an exception to today's rule, written into CLAUDE.md for the transition).
- **Tests:**
  - `test_readability` and the art tests follow the new sizes.
  - A new `test_vector_art` checks every sheet's frame size, feet anchor and that no frame is empty.
  - `perf_report` after each phase must stay within 10% of today.
- **Removed at the end:** the pixel drawing code (`canvas.gd` and the pixel painters) and the pixel font, once nothing
  uses them.

## 5. Open questions

| # | Question | Recommendation |
|---|---|---|
| Q1 | Bake offline into sprite sheets, or paint poses at runtime (the test's pose cache)? | **Offline into sheets.** Same runtime cost as today, every game scene and tool keeps working, and sheets can be reviewed and diffed. The runtime cache stays a test tool. |
| Q2 | Draw characters bigger than today? | **Up to 1.25x the figure height, collision unchanged.** Bigger figures carry the detail that makes it look epic, without touching gameplay. The camera stays as it is. |
| Q3 | The font: CLAUDE.md rule 3 allows only CC0 or self-made. Allow SIL OFL fonts (free, commercial use OK, credited)? | **Yes, allow OFL**, logged in `assets/CREDITS.md`. A fantasy display font for titles and a clean readable one for text (e.g. Cinzel and Alegreya Sans, both OFL). The alternatives are drawing a font in code (weeks) or keeping the pixel font (it clashes). |
| Q4 | Work on a branch and merge per phase, or convert on the work branch directly? | **Branch `m15-vector`** from `art/handoff-integration`, merged back after each phase's playtest. M14's leftovers (chapter 1 steps, chapter 2 economy) can continue on the work branch meanwhile. |
| Q5 | First playable: the chapter-1 slice with chapters 2-3 still pixel? | **Yes.** Feedback on the look comes after about 15 sessions instead of 60; the style break between chapters is acceptable for internal builds. |
| Q6 | Retire the Pixellab Knight? | **Yes**, with the rest of the pixel art; CREDITS keeps its entry until the sheet is gone. |
| Q7 | More animation frames than today? | **Yes, about twice** for attacks and deaths (walk 12, idle 8). Parametric poses make extra frames cheap, and smooth motion is part of the vector look. |
| Q8 | Keep the 2D lights (torches, fortress, dusk `CanvasModulate`)? | **Yes**, they light vector sprites as they light pixel ones. Glows are added on top, not instead. |
| Q9 | What happens to `look-test` (A/B/C)? | **Close it**: vector replaces that question. The branch stays as it is, never merged. |

## 6. Decisions

*(after approval: # / question / decision / from user or recommendation)*
