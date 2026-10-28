# M15 P2: the chapter-1 bosses in vector (Gravelord, Bone Colossus, Lich Warden)

**Status: approved by the owner on 2026-10-28 ("go": every recommendation); in progress.** Numbers (sizes, frame counts, sheet dimensions) are starting points to be
checked with the lineup tool, `test_readability` and `perf_report`. The UI half of P2 is done (`docs/M15_P2_UI.md`).

## 0. Summary

- **What:** the three chapter-1 bosses, the last unconverted figures of chapter 1, drawn as vector painters on the P0
  pipeline (`tools/art/vector/<boss>_painter.gd`), baked to sheets, and shown through `SheetSprite` like the Knight and the
  Ghoul. With them chapter 1 is vector from the first wave to the Lich Warden.
- **Each boss keeps its mechanic and its timings.** Nothing in `data/enemies/*.tres`, the abilities or the balance changes;
  the art follows the existing wind-ups (Gravelord 0.6 s attack, a 5 s cast; Colossus 1.0 s brace, a charge, 1.6 s stun;
  Lich a ward cast). Visuals follow gameplay, never drive it.
- **Bigger and better lit:** figures up to 1.25x the old height (collision unchanged), a violet role glow (the boss colour),
  warm rim from the top-left, a cold moonlight rim, a thin dark outline; they must stay readable in grayscale.
- **Animation:** idle 8, walk 12, attack 12, cast 12, brace/charge/stun 8, death 12 frames, in the three facings
  (`down`, `up`, `side`; side faces right and is mirrored). The old pixel sheets had 4 to 8 frames and one pose per state.
- **Death:** each boss's big death effect (flash, collapse, crumbling, a soul) is redrawn with the new body frames:
  the Gravelord's cloak and bones fall, the Colossus shatters into bone plates, the Lich's phylactery cracks and the robe
  empties. The effect scenes keep their timings (half a second of slow motion, the camera shake).
- **Boss effects in the same pass:** the telegraph marker (dashed ring, charge arrow), the Gravelord's summon graves, and the
  Lich's ward bubble, so a boss fight is not a vector figure on pixel rings.
- **Sheet cost is the main risk:** the Colossus has 19 animation rows. At 1.5 sheet pixels per world pixel it is about
  2520 x 3990 px (40 MB in VRAM); the other two are about 2520 x 2730 (28 MB each). At scale 2 the Colossus would pass
  the 4096 px texture height. So these three sheets bake at **scale 1.5** (a per-layout setting that already exists).
- **Variants keep working:** chapter 2 and 3 boss and elite variants (Quarry Colossus, Winter Warden, ...) are built from
  these sheets' size and animation lists, so the pixel size constants they use are kept under a new name while the vector
  layout takes the old names.
- **Order:** Gravelord first (the simplest, a caster), then the Colossus (the largest set), then the Lich Warden, then the
  effects; a lineup page, a gallery check, the suite and a playtest build close the phase.

## 1. What the bosses are today

| Boss | Wave | HP | Mechanic | Sheet | Rows (animations) |
|---|---|---|---|---|---|
| The Gravelord | 5 (elite in rows 3-4) | 900 | raises the dead: marks graves (telegraph), then minions rise | 128x128, pixel | 13: idle, walk, death, attack, cast x 3 facings |
| The Bone Colossus | 10 | 2200 | braces (1.0 s, red arrow on the lane), charges along it, then is stunned 1.6 s | 128x128, pixel | 19: + brace, charge, stun |
| The Lich Warden | 15 | 3600 | wards nearby enemies (a ring grows, then a shield) | 128x128, pixel | 13: idle, walk, death, attack, cast |

Facts the art must respect: `sprite_offset` and `body_radius` in the `EnemyData` (Gravelord r 24, Colossus r 28, Lich r 22; the feet sit about 57 px below the cell centre);
`health_bar_y` (the boss bar is in the HUD, no bar over its head); the abilities play `cast`, `brace`, `charge` and `stun`
by name (`_play("cast")`); `EnemyRoles` gives bosses a violet glow; the Colossus's charge and stun are readable states, so
their silhouettes must differ clearly from walking.

## 2. The design

### 2.1 The three figures

| | Gravelord | Bone Colossus | Lich Warden |
|---|---|---|---|
| Idea | a tall gaunt gravedigger-lord: tattered black cloak with a high collar, bone-white skull face under a rusted iron circlet, a long shovel-scythe, a hanging lantern with green fire | a hulking heap of fused bones and ribs with a slab-like skull, spiked shoulder tusks, oversized bone fists, glowing violet eye-pits | a thin robed sorcerer-king: layered purple-black robes with silver trim, a floating crown of shards, a staff topped with a violet crystal, a hovering skull face with violet flames |
| Height (world px) | ~115 (was ~120 incl. the raised tool) | ~115 wide-bodied (was ~118) | ~108 (was ~108) |
| Silhouette | tall and narrow, cloak spreading at the bottom | wide and low, arms to the ground | tall, hovering (no feet), robe hem fading |
| Light | green lantern glow on the cloak, warm rim | warm rim on the bone, violet in the eyes | violet crystal glow on the robe, cold rim |
| Walk | slow stride, cloak sways, shovel dragged | heavy swaying lumber, knuckles drag | glides, robe trails, bob |
| Attack | a two-handed overhead shovel swing, timed to the 0.6 s wind-up | a double fist slam | a short staff thrust (rarely seen: the Lich mostly casts) |
| Special | cast: arms raised, lantern flares, soil churns | brace: crouch, shoulders hunch, eyes flare (loops through the 1.0 s telegraph); charge: head down, a dust trail; stun: swaying, stars of bone dust | cast: staff raised, crystal pulses, the ring grows |
| Death | the cloak drops, the skull rolls, the shovel falls | the body shatters into plates | the skull cracks, the robe empties, violet flames die |

Role colour: the eyes, glow and name all use the boss violet (`ART_DIRECTION.md` 5), except the Gravelord's lantern, which is
green (the necromantic accent) and kept small so the role colour still reads.

### 2.2 Animation sets (frames per animation, the old fps stays so durations match)

| State | Old | New | Notes |
|---|---|---|---|
| idle | 4 | 8 | breathing, cloak/robe sway |
| walk | 6 | 12 | |
| attack | 8 | 12 | peak timed to `attack_windup` 0.6 s |
| cast (Gravelord, Lich) | 6 | 12 | the telegraph is longer than the animation, so the last frames hold the pose |
| brace / charge / stun (Colossus) | 4 | 8 | looped |
| death | 8 | 12 | |

Frames per row are capped at 12, so a sheet is at most 12 cells wide.

### 2.3 Sheet sizes

| Boss | Cell (world px) | Scale | Rows | Sheet |
|---|---|---|---|---|
| Gravelord | 140 x 140 | 1.5 | 13 | 2520 x 2730 |
| Bone Colossus | 140 x 140 | 1.5 | 19 | 2520 x 3990 |
| Lich Warden | 140 x 140 | 1.5 | 13 | 2520 x 2730 |

The cell is 140 (was 128) so the 1.25x figure and its swing do not touch the edge: the edge check from the tower fix
(no opaque pixel in the outer 2 px) becomes a test.

### 2.4 Boss effects

- **Telegraph marker** (`TelegraphMarker`): the dashed ring and the lane arrow become vector (a glowing dashed ring with a
  filling inner ring, the arrow a chevron strip), same sizes and timing.
- **Summon graves** (Gravelord): a cracked mound with green mist while the telegraph runs, the minion climbing out of it.
- **Ward bubble** (Lich): a translucent violet dome with a hex shimmer on each warded enemy (display only).
- **Death effect scenes** (`*_death_effect.tscn`): their body node becomes a `SheetSprite` (an `AnimatedSprite2D` would draw
  the vector sheet at the wrong size, see CLAUDE.md); the dust sprites stay.

## 3. How it fits the code (sketch)

- `tools/art/vector/gravelord_painter.gd`, `colossus_painter.gd`, `lich_painter.gd` (`frame(ci, anim, index, count)` on
  `VectorPaint`/`VectorFrames`, like `brute_painter.gd`), registered in `bake_sheets.gd`; a `"vector"` key, `"scale": 1.5`
  and the new cell size in `sheet_layouts.gd`; the old size constants are kept as `COLOSSUS_PIXEL_SIZE` and
  `LICH_PIXEL_SIZE` for the variant layouts (`size: COLOSSUS["size"] + ...`), and **the variants stay pixel** until P4/P5.
- `entities/enemies/bosses/*_frames.tres` regenerate through `build_sprite_frames.gd` (never hand-edited); the enemy scene's
  sprite is already a `DirectionalSprite`, which extends `SheetSprite`.
- `entities/enemies/bosses/*_death_effect.tscn`: `AnimatedSprite2D` -> `SheetSprite`.
- `data/enemies/{gravelord,colossus,lich}.tres`: only `sprite_offset` may change (to keep the feet where they were).
- **Tests:** `test_vector_art` (the three layouts have a vector painter, a scale and enough room), `test_visuals`
  (frame counts and anchors), `test_readability` (grayscale contrast on the Crypt Road ground, the
  role colour), a new edge-clearance check for every vector sheet, and the existing boss test (`test_bosses`) must pass unchanged, since no rules change.
- **Review:** `tests/tools/m15_lineup.gd --enemies=gravelord,colossus,lich` (idle, walk, attack, cast/brace, death at game
  scale), the gallery scenario, and a capture of each boss fight with its telegraph.
- **Balance:** none changes; the balance tools are only re-run as a sanity check.
- **No** autoload, physics layer, input action or folder change.

## 4. Order of work

| Step | What | Sessions |
|---|---|---|
| 1 | Gravelord painter, bake, lineup, scene wiring, death effect | 1-2 |
| 2 | Bone Colossus (the 19 rows), its charge and stun reads | 1-2 |
| 3 | Lich Warden, the ward bubble | 1 |
| 4 | telegraph marker, summon graves, edge checks, suite, review shots, `perf_report`, playtest build | 1 |

## 5. Open questions

| # | Question | Recommendation |
|---|---|---|
| Q1 | Sheet scale 1.5 for the bosses (scale 2 passes the 4096 px height for the Colossus)? | **Yes**, 1.5, 140 px cells. The linear filter hides the difference, and VRAM stays near 95 MB for the three (checked with `perf_report`). |
| Q2 | Figures up to 1.25x the old height (Q2 of M15, which says "up to")? | **Yes in principle, but the old bosses are already about 110-120 px tall** (measured on the pixel sheets: the Gravelord 121 px, the Colossus 118, the Lich 108 with a 128 px cell), so the vector figures keep that height and gain detail, not size; collision, `body_radius` and the camera stay. |
| Q3 | Frame counts as in 2.2 (idle 8, walk 12, attack/cast/death 12, special 8)? | **Yes.** |
| Q4 | Keep the variants (Quarry Colossus, Winter Warden, ...) pixel until their phase? | **Yes**; they keep their own sheets and the old size constants. |
| Q5 | Redraw the telegraph marker, summon graves and ward bubble now? | **Yes**: a vector boss on pixel rings would be the one jarring piece left in chapter 1. |
| Q6 | The Gravelord's look: gaunt gravedigger-lord with a shovel-scythe and a green lantern? | **Yes**; the lantern is the only green, so the violet role colour still reads. Tell me if you want a different idea for any of the three. |
| Q7 | Playtest build at the end of this part (a chapter-1 run to the Lich Warden)? | **Yes**: `m15-playtest-2`, then ask for feedback on the bosses and the new UI together. |

## 6. Decisions

Approved 2026-10-28 ("go").

| # | Question | Decision | From |
|---|---|---|---|
| Q1 | Sheet scale | 1.5 for the three boss sheets, 140 px cells | recommendation |
| Q2 | Figure size | Keep the old height (~110-120 px), more detail; "up to 1.25x" not used | recommendation (corrected by measurement) |
| Q3 | Frame counts | idle 8, walk 12, attack/cast/death 12, brace/charge/stun 8 | recommendation |
| Q4 | Variants | Stay pixel until P4/P5 | recommendation |
| Q5 | Effects | Telegraph marker, summon graves, ward bubble redrawn | recommendation |
| Q6 | Designs | As in 2.1 | recommendation |
| Q7 | Playtest | `m15-playtest-2` at the end | recommendation |

## 7. As built

**Done 2026-10-28.** `tools/art/vector/{gravelord,colossus,lich}_painter.gd` (on `VectorPaint`/`VectorFrames`, registered in
`bake_sheets.gd`), the layouts `GRAVELORD`, `COLOSSUS` and `LICH` in `sheet_layouts.gd` (`BOSS_SCALE` 1.5, `BOSS_CELL` 210
sheet px = 140 world px, feet 58 px below the centre; the pixel layouts live on as `*_PIXEL` for the variants and the
dormant pixel jobs, which are in `HAND_DRAWN`). Frame counts as designed (2.2); the blow lands on frame 9 of 12 at
15 fps (0.6 s), which `test_bosses` checks. **Corrections to the proposal:** the old bosses are ~110-120 px tall (the
draft said ~64), so the vector figures keep that height (body ~94 px, ~120 with the raised tool or fists); sheets are
2520 x 2730 (Gravelord, Lich) and 2520 x 3990 (Colossus). **Learned:** a painter's overflow bleeds into the neighbouring
cell, so `test_vector_art` now checks that nothing opaque touches a cell's outer 2 px on every converted sheet (it found
the Gravelord's soft glows, the Colossus's flying arms and the Lich's rune ring); long tools are foreshortened when swung
level (`reach`), as the cell is narrower than the tool is long. **Effects:** `TelegraphMarker` (rings, the new `GRAVE` shape
for the Gravelord's summon spots, the chevron lane arrow) and `ShieldBubble` are vector (they serve every chapter's
bosses); the three death-effect scenes use `SheetSprite`. The Colossus's side views are the least refined (a narrow boxy
skull in profile); tell me if they bother you in play.
