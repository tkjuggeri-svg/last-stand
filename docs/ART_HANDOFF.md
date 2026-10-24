# Art pack integration (branch `art/handoff-integration`)

**Status: installed for review on its own branch, not merged into `main`.** The pack calls itself "a
comprehensive first-pass art pack, not an engine-tested, production-final replacement", and the
review below agrees: it is not ready to ship as is. Every gameplay and timing test passes; one art test
(grayscale readability of three bosses) fails.

Source: `LAST_STAND_CLAUDE_CODE_HANDOFF.zip` (149 files, every SHA-256 in its `SHA256SUMS.txt`
checked). Its own structural validator passes: 33 sheets, 1,465 animation frames, two warnings (the
map grounds, not baked).

## 1. What was installed

`python3 -I tools/art/install_art_pack.py <pack>` (rerunnable for a later delivery) copied:

- **31 sheets at their spec paths:**
  - the hero;
  - the 9 enemy sheets and the 4 bosses;
  - the towers and their shots;
  - the 14 effect sheets;
  - the fortress and its effects;
  - the build slot.
- **The spawns and the title:** the crypt, the drowned chapel and the title art.
- **The two prop sheets, rebuilt in the game's frame order** (section 3).

Not installed:
- **The pack's map grounds:** texture bases (section 4).
- **`templates/`:** UI frames, icons, font, map-node icons, mockups, the War Room and Quartermaster
  concepts, slot variants. Their IDs are unmapped (section 5).
- **`previews/`.**

## 2. The resolution contract and what changed in the project

The world sprites are drawn at **double resolution**: one sheet pixel = one world pixel, every frame
twice the old size, every anchor doubled. On screen nothing moves or changes size.

| Change | Where |
|---|---|
| Frame sizes doubled for the 33 delivered sheets (rows, frame counts, speeds and loop flags checked identical, row by row) | `tools/art/sheet_layouts.gd` |
| SpriteFrames rebuilt from the new sheets | `entities/**/*_frames.tres` (31 files) |
| 192 sprite nodes from `scale = 2` to `scale = 1`, their `offset`s doubled (props (0, −20) → (0, −40), crypts and chapels (0, −28) → (0, −56)) | 30 scenes |
| 39 children of those nodes (lights, soul particles, fire smoke) given double position and scale, so they stay exactly where they were | the fortress, both levels |
| Tower menu icons cut from frames of any resolution | `ui/build_menu/tower_icons.gd` |
| The hand-drawn sheets taken out of the code generator (a regeneration can't overwrite them; their drawing code stays) | `tools/art/generate_art.gd` (`HAND_DRAWN`) |
| The title screen's own logo, tagline and shade hidden: the new title art has the logo and tagline baked in | `ui/menus/title_screen.tscn` |
| Tests: sprites expected at scale 1; the collision-fit checks unchanged (they now measure the new art) | `tests/automated/test_visuals.gd` |
| Credits: the pack's provenance note merged | `assets/CREDITS.md` |
| The sprite spec regenerated for the new sizes and anchors | `docs/ART_SPEC.md`, `tools/art/art_spec.py` |

Still at the old 2 world px per pixel (code-drawn): the map grounds, motes, smoke puffs, the bone
pickup, and all UI.

**Not changed:** the base resolution (1280×720), any gameplay value, collision shape, timing, camera.

## 3. Prop mapping (the pack's order was a proposal)

| Game frame | Crypt Road prop | From the pack | | Game frame | Marsh prop | From the pack |
|---|---|---|---|---|---|---|
| 0 | tomb_round | arched headstone | | 0 | reeds | reeds |
| 1 | tomb_cross | stone cross | | 1 | cattails | reeds (a duplicate) |
| 2 | tomb_tall | broken headstone | | 2 | willow | moss tree |
| 3 | grave_mound | sarcophagus | | 3 | stump | tree stump (graveyard sheet) |
| 4 | dead_tree | dead tree | | 4 | sunken_boat | wrecked boat |
| 5 | dead_tree_small | tree stump | | 5 | marsh_lantern | **stopgap**: the game's own, doubled |
| 6 | bush | **stopgap**: the game's own, doubled | | 6 | drowned_tomb | candle altar |
| 7 | rocks | rubble | | 7 | mushrooms | witch lilies |
| 8 | lantern | lantern post | | | | |
| 9 | broken_pillar | ruined wall | | | | |
| 10 | bones | bone pile | | | | |
| 11 | fence | iron fence | | | | |

Unused pack props: the witchfire pedestal, boardwalk, chapel column and sunken bell.

## 4. The map grounds: kept as they are

The road and pool geometry was exported from the levels (the lanes' baked points, 34 px wide roads,
the marsh's water polygons, origins (−932, −532) and (−1072, −732)). With it, the pack's generator
produced grounds whose roads and pools line up exactly. Its terrain, though, is only a texture base:
- no wall band around the edge;
- no fortress clearing or cobbles, no spawn aprons;
- no boardwalks where the roads cross streams;
- no shores;
- flat colour.

Shipping it would be a clear step down, so **the current grounds stay** (code-drawn, 2 world px per
pixel). Under the new sprites that is a visible resolution mismatch, mild at 720p and clear at 1080p.

## 5. Not done (blocked on decisions or art)

- **UI templates:**
  - The 22 card icons and 15 relic icons match the game's counts (22 cards, 15 relics), but only
    `long_reach` matches a real ID. The rest are invented ("steel_edge", "last_ember"), so each icon
    would have to be matched or redrawn to its real mechanic.
  - Frames and buttons: the 9-slice margins need checking against the theme.
  - The bitmap font is uppercase-only, against today's mixed-case font.
  - The mockups, War Room and Quartermaster are concepts.
  - None of this was installed.
- **Slot variants:** the high-ground and ruined pad templates belong to the unfinished slot work on
  the local branch `wip/more-slots`.
- **Role eye colours:** the pack's eyes follow its own palette, not `EnemyRoles`. `test_readability`
  only compares the palette file with `EnemyRoles`, so it passes. The art itself still needs
  reconciling (Ghoul red, Hound yellow, Brute and Shieldbearer blue, Cultist green, Priest teal,
  Bloater magenta).
- **1080p:** sprites at 1.5 screen px per pixel, rows unevenly thick, and they shimmer while
  scrolling. Choosing between a sharp-bilinear upscale and a new base resolution is a project-setting
  decision (`docs/M10_ART_RESOLUTION.md`).

## 6. Art defects found (for the artist)

The structure is right everywhere (every row, frame count and speed). The animation quality is a
procedural first pass, as the pack says:

| Sheet | Defect |
|---|---|
| Hero | **Side view is not a profile:** a narrowed front view with the sword on the left and the shield on the right. **Back view shows the shield's face** on the same side as from the front. **Attack:** a second sword swings while the resting sword is still drawn. **Walk:** the legs barely move. **Dash:** identical to idle (no lunge). **Death:** the body rotated at arbitrary angles (resampled pixels). |
| Ghoul | Attack rows look almost like idle (no visible lunge); the side view is close to the front. |
| Hound | Very small: 28×26 world px against the old 24×50. Hard to see in a crowd (the marsh screenshot). |
| Several characters | The "up" and "side" rows reuse the front pose with small changes. |
| Gravelord, Lich, Tollkeeper | Too dark against the ground without colour: `test_readability` contrast 1.70 / 1.43 / 1.71 (minimum 1.8). The Lich on the Crypt Road is the worst. |
| Towers | Levels 1–3 differ only by small additions (posts, a banner). The Cannon has no tower body, just a cannon on a pad. |
| Eyes | Not in the role colours (above). |

Reviewed and fine:
- the bosses' designs and their ability rows;
- the Mire Priest's heal (staff rising, then a pulse);
- the effects;
- the fortress's four damage states;
- the spawns;
- the title art.

## 7. Tests run on this branch

- **The pack's validator:** PASS (33 sheets, 1,465 frames).
- **`tests/run_tests.sh`:** every automated test except one passes. That includes gameplay, timing,
  saves and the visual test, which has the hero at 40×74 world px (as before) and the Ghoul at 32×48.
  **1 FAILED:** `test_readability` (the three bosses above).
- **Screenshots** (`tests/tools/art_review_shots.gd -- --tag=…`):
  - a Crypt Road fight with every tower type and evolutions;
  - the four bosses;
  - a Drowned Marsh fight;
  - each at 720p and 1080p;
  - the title screen.
