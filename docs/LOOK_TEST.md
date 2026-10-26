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

| | current | A | B |
|---|---|---|---|
| Compatibility 1280x720 | 437 fps (1% low 162) | 127 (68) | 79 (50) |
| Forward+ 1280x720 | 443 (146) | 168 (71) | 48 (32) |
| Compatibility 1920x1080 | 290 (123) | 103 (53) | 42 (28) |

One machine, an integrated GPU; the 1080p row matters because the game's `Display` renders at 2x on a 1080p
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
