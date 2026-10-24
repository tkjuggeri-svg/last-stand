# Art resolution: double the detail? (decide before M10's biome art)

**Status: decided by what was built: option A1 with the sharp-bilinear upscale** (section 7). The art
pack's integration moved the play field to double resolution, the user chose smooth scaling for 1080p,
and the characters and grounds were redrawn in code at that resolution (`docs/ART_HANDOFF.md`).

## 0. Summary

- **Today:** one art pixel is 2 world pixels on a 1280×720 base, so art pixels are 2 / 3 / 4 / 6
  screen pixels at 720p / 1080p / 1440p / 4K, always even. The play field is a 640×360 art canvas.
  The knight is 20×37 art px.
- **Option A, double resolution in play:** 1 art px = 1 world px, everything redrawn with twice the
  detail: about 1,465 animated frames in 33 sheets, two grounds, props, icons, UI frames and the title.
  That's a new art pass bigger than M3.5's: the drawing code is about 9,500 lines today and would grow.
  - **A1, keep the 1280×720 base:** everything stays the same size on screen. Art pixels become
    1 / 1.5 / 2 / 3 screen px, so **1080p, the most common screen, is uneven**. A "sharp-bilinear"
    upscale hides most of it at the cost of slightly soft edges.
  - **A2, move the base to 1920×1080:** 1080p and 4K are even, 720p and 1440p are not. With the same
    world sizes, **every sprite is smaller on a 1080p screen than today** (the knight 40×74 px instead
    of 60×111). The camera then sees 2.25× the area, so the whole Crypt Road fits on one screen. That
    is a gameplay change, not only a visual one.
- **Option B, detail where you look closely:** keep the play field as it is, and draw close-ups at
  double detail: the title, the War Room, portraits (the knight, the bosses, the Quartermaster),
  card and relic art, the run summary. Still images don't shimmer, so an uneven scale at 1080p is
  harmless there. The knight's lion, mail and face plate live in his portrait.
- **Recommendation: B**, starting with M11's characters and M13's presentation. Revisit A only if
  outside players (the itch demo) say the play field looks too low in detail. **Decide before M10's
  biome art** either way: every biome drawn at today's resolution would be redrawn under A.

## 1. What changes on screen

How many screen pixels one art pixel covers ("even" = a whole number, so every art pixel is the same
size; uneven pixels make some rows and columns thicker than others, and they shimmer as the camera
moves):

| Screen | Today (2 world px, base 720) | A1 (1 world px, base 720) | A2 (1 world px, base 1080) | B (play field as today) |
|---|---|---|---|---|
| 1280×720 | 2 ✓ | 1 ✓ | 0.67 ✗ | 2 ✓ |
| 1920×1080 | 3 ✓ | **1.5 ✗** | 1 ✓ | 3 ✓ |
| 2560×1440 | 4 ✓ | 2 ✓ | **1.33 ✗** | 4 ✓ |
| 3840×2160 | 6 ✓ | 3 ✓ | 2 ✓ | 6 ✓ |

Close-ups under B are drawn at 1 art px = 1 base px, so they share A1's column, but on still images.

The knight on a 1080p screen, and what the camera sees:

| | Today | A1 | A2 |
|---|---|---|---|
| Knight on screen at 1080p | 60×111 px (20×37 art px ×3) | 60×111 px (40×74 art px ×1.5) | **40×74 px** |
| Knight's detail | 20×37 art px | 40×74 art px | 40×74 art px |
| View (world px) | 1280×720 | 1280×720 | **1920×1080** |
| Crypt Road (1364×964 with walls) | scrolls a little | same | **fits on one screen** |
| Drowned Marsh (1884×1364) | scrolls | same | nearly fits |

A2 can only keep today's on-screen sizes by scaling the whole world by 1.5: every range, speed,
collision shape, map and wave spacing. That's a gameplay change, against the point of a visual pass.
**A2 is a design change** (a zoomed-out, more strategic view) as much as an art change.

## 2. Option A: the full double-resolution redraw

**What gets redrawn** (frames per sheet from `tools/art/sheet_layouts.gd`):

| Family | Sheets | Frames | Drawing code today | Notes |
|---|---|---|---|---|
| Hero and his swing trails | 3 | 217 | `hero_art`, `effects_art` (≈ 590 lines) | trails at 8 directions × 5 reaches |
| Regular enemies (8) | 8 | 470 | ≈ 2,450 lines | 7 roles' eyes, shields, effects |
| Bosses (4) | 4 | 338 | ≈ 1,030 lines + boss kit | 64×64 frames become 128×128 |
| Towers and evolutions (5 + 10) | 1 | 263 | `tower_art`, `evolution_art` (≈ 1,350) | the biggest single family |
| Shots and effects | 13 | about 180 | ≈ 300 | explosions, burns, frost, status marks |
| Fortress and its effects | 2 | 4 + 18 | `fortress_art` (≈ 460) | four damage states |
| Grounds, props, crypt, chapel | 6 | statics | `environment_art`, `marsh_art` (≈ 1,050) | baked grounds become 4× the pixels |
| UI: frames, icons, cards, font | many | statics | `ui_art`, icons (≈ 780) | the font could stay (UI is separate) |
| Title key art | 1 | static | `title_art` (≈ 400) | 1280×720 art px instead of 640×360 |

**Why it is new work, not a scale-up:** scaling the drawing code by 2 draws the same shapes with
bigger pixels. The detail has to be designed: mail texture, a face plate, a lion, folds, highlights.
The 1 px outline becomes relatively thinner, and ART_DIRECTION's sizes, animation timings and
review checklist need a new pass. Expect each asset to take **2–3×** the drawing effort of today's,
for the same frame counts.

**Every later asset costs more too.** M9 (cards, combo evolutions), M10 (9 biomes in all: grounds,
props, 1–2 enemies and a boss each) and M11 (characters) would all be drawn at the higher detail. M10
alone is about 7 new grounds, 10+ enemies and 7 bosses.

**What stays the same:**
- **Gameplay:** ranges, speeds and collision are in world px. Under A1 nothing moves.
- **Performance:** textures have 4× the pixels (today 2.1 MB of sprites, so about 8 MB). The number
  of draw calls doesn't change, and lights cost by screen pixels, not texture pixels. A
  `perf_report` check would confirm.
- **The pipeline:** still code-drawn. Sprite nodes go from `scale = 2` to `scale = 1`, and
  `ART_SCALE` in `sheet_layouts.gd` drives it.

**The 1080p problem under A1:** Godot's `canvas_items` stretch at 1.5× with nearest filtering makes
every other art pixel one screen pixel thicker, and it shimmers as the camera scrolls. The usual fix
renders at the next integer scale (2×) and filters down linearly ("sharp bilinear"). Pixels look
even, with a faint softness at the edges. It's a small shader or a viewport setup, and it should be
tested by eye before committing to A1.

## 3. Option B: detail where the player looks closely

Keep the play field at today's resolution, and draw the screens and pictures the player looks at up
close at 1 art px = 1 base px (twice today's detail):

| Close-up | Where | Detail it allows |
|---|---|---|
| The knight's portrait | the HUD's hero row, the War Room, the run summary | the lion on the shield, mail, the face plate, the crest's feathers |
| Boss portraits | the boss bar, the boss's arrival banner | each boss's face and its one trick |
| Hub characters (M11) | the War Room | faces and expressions (the Quartermaster first) |
| Card and relic art | the choice screens, the merchant, the War Room's board | a small picture per card, not just an icon |
| The title key art | the title screen | the knight after the new design, the fortress, the horde |
| Run summary and Game Over / Victory | full screen | a scene per ending |

**Why this works:** these are still images, so a 1.5× scale at 1080p (with linear filtering of a
nearest-prescaled image) looks clean: no camera movement, no shimmer. The play field keeps its even
2 / 3 / 4 / 6 pixels. Mixing pixel sizes *within* the play field breaks the grid (ART_DIRECTION); on
separate screens and HUD frames it doesn't.

**Cost:** each close-up is one image or a few frames, not hundreds. It fits M11 (characters) and M13
(presentation), which plan these screens anyway.

## 4. Other options considered

- **A bigger hero frame at today's scale** (for example 40×48 art px): a few more pixels for the
  helm and shield, but the knight stands bigger next to the enemies, against the proportions just
  checked. Only worth it together with bigger enemies, which is A again.
- **Integer-only scaling** (Godot's `integer` stretch scale mode): at 1080p with a 1280×720 base this
  shows a 1280×720 picture with black borders. Not acceptable on the most common screen.

## 5. How it would fit the code (sketch)

**Option B:**
- A `tools/art/portrait_art.gd` per family, or added to the existing art files.
- Portraits saved to `assets/sprites/portraits/`.
- A `Portrait` widget (TextureRect with the theme's frame) used by the HUD, the War Room and the boss
  bar.
- Card art as an optional `UpgradeData.picture` beside today's `icon`.
- No change to scales, sprites or gameplay. Tests: every card has its picture (when the pass is
  done), `ui_shots.gd` for review.

**Option A1:**
- `ART_SCALE` 2 → 1, and every sprite node's `scale` 2 → 1 (`test_visuals` checks it).
- Every generator redrawn; the baked grounds at full resolution.
- The sharp-bilinear upscale for fractional screens.
- ART_DIRECTION rewritten for the new sizes; `test_readability` thresholds re-checked.
- A rough order: hero first (the proof), then grunts, towers, effects, grounds, bosses, UI.
- Each family is a commit with a before/after `gallery` screenshot.

**Option A2:** A1, plus:
- base 1920×1080, Camera2D limits and zoom per level;
- a UI re-layout (font at 36, every offset ×1.5);
- either bigger maps or accepting a whole-map view;
- a balance pass if the world is scaled.

## 6. Open questions

| # | Question | Recommendation |
|---|---|---|
| Q1 | Which option: A1, A2 or B? | **B.** The play field's detail is a smaller problem than the cost of A, and B lands the detail where it is seen. |
| Q2 | When to decide? | **Before M10's first new biome.** Every biome drawn at today's resolution would be redrawn under A. |
| Q3 | If A: which screen to optimise for? | **1080p** (the most common). That means A2's base, or A1 with the sharp-bilinear upscale. |
| Q4 | If A2: a whole-map view, or bigger maps to keep scrolling? | Try the whole-map view on the Crypt Road first. It might suit a tower defense, but the hero gets small. |
| Q5 | Should the knight's concept fidelity (soft shading, a real lion) be the target for the play field, or for portraits only? | **Portraits**: at 20×37 art px the play-field knight carries the silhouette and colours, the portrait the detail. |
| Q6 | Who judges "too low in detail"? | Outside players: the optional itch demo (M8.5) or the next playtest round, before spending a milestone on A. |

## 7. Decisions (after the art pack)

| # | Decision | From |
|---|---|---|
| Q1 | **A1**: 1 art px = 1 world px on the 1280×720 base. The art pack delivered most of the world at double resolution; the hero, enemies, bosses and grounds are drawn in code at the same resolution (`Canvas.detail`). | the art pack's integration, the user's "fix it ourselves" |
| Q2 | Decided before M10, so every new biome is drawn at double resolution. | |
| Q3 | **1080p with the sharp-bilinear upscale** (`Display`, the main scene: rendered at 2x, filtered down; a setting, on by default). It costs about half the frame rate at 1080p; chapter 1's last wave, every tower evolved, still keeps a 73 fps 1% low on an Intel Iris Xe. | the user ("smooth upscaling") |
| Q4 | Not applicable (no A2). | |
| Q5 | The play field gets the detail the double resolution allows (the knight's visor, mail, lion); portraits can still add more. | |
| Q6 | Outside players judge it at the next playtest. | |
