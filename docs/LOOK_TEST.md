# Look test: two ways to a "HD-2D" look (experiment branch `look-test`, not for merging)

Graveyard map only, wave 15 with all 16 slots built, the hero bot fighting, no gameplay changes.
Everything is in `experiments/look_test/`; run with `look_runner.gd` (`--variant=base|a|b`).
Files for the owner are in `exports/look-test/` (git-ignored): screenshots `*_t06/t14/t22.png`,
side-by-sides `compare_*_t14.png`, videos `look_*.avi`, `fps_*.txt`, `renderer_support_*.txt`.

## What was built

**A, fake HD-2D in the current 2D setup (Compatibility renderer, no engine change):**
one post pass over the world (tilt-shift blur toward the top and bottom, bloom, world-anchored drifting fog,
light grade); the level's lamps get glow halos, flicker and soft shadows (small occluders on towers, units,
props); normal maps generated from the art for the knight, the Ghoul and the archer tower, lit by a cool
"moon" PointLight2D; drifting light motes. Existing game code untouched.

**B, tilted camera over the unchanged 2D game:** the level keeps running in 2D (physics, AI, HUD); its world
items are moved to a hidden canvas layer and a 3D stage shows them: the baked ground as a textured plane, a
perspective camera (42 degrees elevation, vertical FOV 30) that follows the 2D camera, every sprite as an upright camera-facing
`Sprite3D` standing at the bottom centre of its 2D rectangle, flat art (pads, rings, rotated shots) lying on the
ground, 2D lamps as omni lights, a moon with shadows, fog, glow, tilt-shift. The mouse is projected from the
camera onto the 2D plane through `WorldPointer.provider`; the HUD stays 2D on top.
Verified in `test_look_b_mouse.gd`: world -> screen -> world round trip exact over 99 points, the hero aims left
and right at the mouse, a build slot highlights under the mouse and not away from it.

## Variant C: A's lighting plus a fake depth, all in 2D (added after the first report)

`experiments/look_test/variant_c/`. It extends A (same lights, normal maps, moon, motes) and adds:
- **Depth scale:** the sprites of enemies, the hero, towers and props are drawn 0.87x at the top of the floor up to
  1.0x at the bottom, scaled about their feet (visual only: bodies, collisions, hit areas and the mouse are untouched; if
  the game itself moves or scales a sprite, that becomes the new base).
- **Haze by world height**, cooler and darker toward the top of the map (it belongs to the map, not the screen).
- **Foreground strip: removed** at the owner's request (a dark blurred strip along the bottom edge).
- **Tilt-shift stronger at the bottom** (6.5 px) than at the top (1.8 px, so enemies at the spawns stay readable).
- **Parallax backdrop beyond the top wall:** dusk sky with stars and a moon, far hills, ruins and a treeline at
  0.18 / 0.38 / 0.62 of the camera's speed. Nothing exists beyond the wall in the real camera, so the camera may look
  170 px higher than before (`limit_top`, visual only): the backdrop shows when the hero is in the top part of the map
  (shot: `c_top_t03.png`) and is out of view elsewhere. Without that change the "beyond the wall" band would never be seen.
- **Bloom toned down** (lamps 1.5x -> 1.3x, halos 0.55 -> 0.3 opacity, bloom 0.7 -> 0.34) plus a soft highlight roll-off:
  the fortress keeps its detail. An exposure lift keeps the whole picture from getting darker than A.
- **Sharp numbers and bars:** the post pass is a rectangle in the world canvas (z 150), the damage numbers, labels and
  enemy health bars are raised above it (z 199-200), and the HUD is on its own layers: they are never blurred.

Findings and cost: it reads as depth without the 3D stage's problems (no mirroring, no new renderer features, no change to
existing game code in this step). Frame rate in the table below. What it is not: the ground and the unit/tower
art still have no perspective, so the "tilted" feeling is a suggestion; the depth scale is subtle at 0.87;
the scaled sprites' hit areas, health bars and baked soft shadows do not scale with them (a 1-2 px mismatch at the very
top); the haze and blur tuning is by eye on one map.
Adoption: about 520 lines (look_c.gd 200, depth_art.gd 170, shader 70), an opt-in layer in `Level`/Main, the z-order
raise of numbers and bars (their scenes), and a decision on the camera's top limit.

## Renderer support (measured with `feature_probe.gd`; the engine's own warnings agree)

| Feature | Compatibility (now) | Forward+ |
|---|---|---|
| 3D, shadows (directional, omni), depth fog, 3D glow | works | works |
| 2D lights, normal maps, light shadows, 2D glow (HDR 2D) | works | works |
| Depth of field (built in) | **no** (engine: "Forward+ or Mobile only") | works |
| Volumetric fog, SSIL, SSR, SDFGI | **no** (Forward+ only) | works |
| SSAO | the probe saw a small effect; not verified by eye | probe inconclusive on this scene |

So **Forward+ is not needed for either variant**: A uses nothing beyond Compatibility, and B fakes depth of field with
the same screen-row blur (right for a flat ground plane). Forward+ would add true depth of field, volumetric fog and
SSAO to B (screenshot `b_fplus_*`), at about 40% lower frame rate here, and would drop the OpenGL-3 reach that
CLAUDE.md sets as the project's renderer goal (it needs Vulkan).

## Frame rate (Intel Iris Xe iGPU, Mesa, vsync off, 22 s sample after 3 s warm-up, up to ~50 enemies, 16 towers)

| | current | A | B | C |
|---|---|---|---|---|
| Compatibility 1280x720 | 437 fps (1% low 162) | 127-157 (56-68) | 79 (50) | 168 (58) |
| Forward+ 1280x720 | 443 (146) | 168 (71) | 48 (32) | not run |
| Compatibility 1920x1080 | 290 (123) | 103 (53) | 42 (28) | 84 (39) |

Run-to-run variation is about 10% (A measured 127, 142 and 157 on three runs); C ran once per row. One machine, an integrated GPU; the 1080p row matters because the game's `Display` renders at 2x on a 1080p
screen (4x the pixels of 720p). Where the cost goes: A, light shadows are most of it (about 127 -> 320 fps
without them), the post pass about half of the rest (-> 251 without it). B, the moon's shadows (55 fps with a
cascaded shadow map, 79-87 with one orthogonal split, 99 without), omni shadows are small, the per-frame
GDScript sync of ~525 mirrored nodes costs about 2 ms. B with no shadows, lights or glow: 142 fps.

## What adopting each would change in the existing code

**A: no existing file has to change.** Adopting it means: a post layer and the lights/halos/motes set-up in
`Level` (or Main), occluders added to the tower, enemy and hero scenes (or as now by a script), and normal maps
for every sprite sheet from the art generator (`tools/art`, a new output per sheet; the runtime generator here is
only a prototype). A setting to turn it off for weak GPUs. Risks: Compatibility ignores the item cull mask on
DirectionalLight2D (hence the PointLight2D "moon"), the ground tiles then show as squares under a
directional light; each 2D light with shadows adds a per-frame cost; art must stay readable under blur
(`test_readability`) and the grayscale rule. About 360 new lines.

**B: two lines of existing gameplay-side code change** (`hero.gd` and `build_slot.gd` ask `WorldPointer` instead
of `get_global_mouse_position()`, plus the 12-line `world_pointer.gd`), everything else is a presentation layer of
~500 lines. But the layer is a mirror, and what it cannot mirror automatically in the shipped game is the real
adoption cost: 12 files draw with `_draw` (range rings, health bars, hover rings; only the enemy health bar is
mirrored here), 12 files use `CPUParticles2D` (souls, smoke, sparks: not mirrored), 13 use `ShaderMaterial` (hit
flash, frost tint: ignored), 19 contain `PointLight2D` (approximated by omni lights; each enemy's glow is skipped), additive blending is
not honoured, damage numbers are `Label3D` (different look), Camera2D shake and limits would need a 3D
equivalent, the perspective shows void beyond the arena edge (fog hides it), and ground-only decals need a rule (here by
`z_index < 0` and names). Art would also want a second look: upright sprites on a foreshortened ground change how
the 3/4-view art reads, and the fortress, towers and units need per-asset anchor checks. Every future entity
with a visual that is not a sprite needs a mirror written for it. Tests (`test_readability`, screenshot tools, `Display`
scaling, `capture_screenshots`) would all need to run with the 3D stage, and the project's "visuals follow gameplay"
rule stays true but the visuals double in size.

## Not done / limits

- One map, one machine; no integrated-GPU low end or discrete GPU numbers; no Windows run.
- B: no particle mirror, no `_draw` mirror (rings), no hit-flash; build-menu range rings are not visible in 3D.
- A: soft shadows are subtle at the existing light radii; fog edges look a little blocky.
- Screenshots and videos use the hero bot; the video format is MJPEG AVI (no ffmpeg on this machine).
- `tests/tools/perf_report.gd` and `trailer_capture.gd` index a 10-entry tower list with the new 16 slots (found
  here, not caused by this branch; fix with `% TOWERS.size()` on the art branch).

## Later changes to C

- Brighter (owner: "too dark but looks okay"): exposure 1.38 -> 1.7 and a shadow lift (gamma 0.88).
- The foreground strip is gone (owner: "ditch the black overlay from the bottom").
