# Vector look test (branch `vector-test`, never merge)

The owner's question (2026-10-27): would LAST STAND look better in the style of `docs/reference/web_td/` (the owner's
small web tower defense: `draw.ts`, `fx.ts`), with smooth vector shapes, gradients and soft glows instead of 16-bit pixel
art? This branch redraws four things in that style, in Godot, with the gameplay untouched, and compares the same moment
side by side.

## What was built

| Part | How it looks | File |
|---|---|---|
| Shared style | `fx.ts`'s glow sprite (a radial gradient: white core, colour, fade) drawn additively; shapes shaded from the top-left with a thin antialiased dark stroke; soft oval shadows; `easeOutBack` | `tools/vector/style/vector_style.gd` |
| The Knight | steel plate, red tabard and plume, a round red-and-gold shield, a sword whose swing leaves a warm gold arc; down / up / side, walk bob, dash streaks, death fall | `vector_knight.gd` |
| The Ghoul | a hunched, pale, cold figure in grey-blue rags, long clawed arms, red-glowing eyes (the common dead's role colour), a faint cold wisp; lunges on attack, sinks on death, flashes white when hit | `vector_ghoul.gd` |
| The Archer tower | warm stone on an octagonal plinth, a lit arrow slit, a wooden deck, a red pennant, a gold bow that turns to the real target and recoils on the real shot, gold level pips | `vector_archer.gd` |
| The graveyard ground | `buildBackground`'s recipe: a radial base, soft colour patches, grass tufts, stones, the roads as layered strokes with pebbles and wheel ruts, a paved plaza at the fortress with a warm glow, cold glows by the crypt; baked into one texture at load | `vector_ground.gd` |
| The switch | `VectorSkin.apply(level)`: adds the vector nodes; the pixel sprites they replace stay in place and keep animating, only invisible, so the vector nodes read their state (animation, facing, progress, aim, target, hit flash) | `vector_skin.gd` |

**Gameplay is unchanged:** nothing in `entities/`, `systems/`, `levels/` or `data/` is touched by this test. The vector
nodes only read state. The theme holds: the defenders are warm (steel lit gold, red cloth, amber lights, a warm fortress
glow) and the dead are cold (pale blue-grey skin and rags, cyan wisps) with red eyes.

Not converted (still pixel art in the shots): props (graves, crypt, lanterns), the fortress, the build pads, arrows and
hit effects, numbers and the HUD.

## The comparison

`godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/tools/vector_style_compare.gd -- [--out=dev_screenshots/vector_test] [--parts=ground,knight,ghoul,archer] [--live-ground]`

It plays the same scripted moment twice with the same seed (a Ghoul-only wave on the graveyard, the Knight beside the
west road with four Archers near him, the shot taken mid-swing when the first Ghoul is in reach; both runs reach that
moment on the same frame). It saves `compare_view.png` (the whole view) and `compare_closeup.png` (2x at the Knight),
pixel on the left, vector on the right, plus each half on its own. (The test wave's Ghouls have 25x health so they survive
the Archers long enough to reach the Knight.)

## What the test showed

- **It reads.** The Ghouls, Knight and towers stand out from the darker ground. The red eyes and the gold swing arc carry
  the warm-versus-cold theme better than the pixel art does at this size. The roads read as roads at a glance.
- **It's a different game to look at.** Next to the pixel props, fortress, pads and HUD, the vector parts look like
  another art direction. The two styles don't mix, so it would have to be all or nothing.
- **Performance** (vsync off, the same fight, 600 frames; this laptop's Intel Iris Xe, Compatibility renderer):

  | | ms a frame |
  |---|---|
  | Pixel art (today) | 2.8-3.9 |
  | Vector, everything drawn live | 14.8 |
  | Vector ground only, drawn live | 8.0 |
  | Vector ground only, baked at load | 4.2 |
  | Vector ground baked + Knight, 33 Ghouls, 4 Archers live | 9.8 |
  | 33 Ghouls alone, live | 7.7 |

  Drawing vectors every frame is the cost: a static ground of thousands of shapes still costs about 5 ms a frame, and each
  live character costs about 0.15 ms. Baking fixes it: the baked ground costs the same as today's.
- **Engine facts found on the way:**
  - 2D MSAA isn't supported in the Compatibility renderer, so smooth edges come only from antialiased outlines.
  - Vector art needs linear texture filtering; the project-wide nearest filter shows the glows' texels as steps.
  - A texture made inside `_draw()` must be kept alive by the node, or it draws white.

## What converting all the art would take

What exists today: 3 heroes, 33 enemies and bosses, 11 towers with three levels and about 20 evolutions, 9 biome grounds and
their props (27 environment sheets), 18 effect sheets, the fortress with 4 damage states, 19 UI sheets and the pixel font,
61 SpriteFrames sets.

1. **Decide on the rendering first.** Live `_draw()` is too slow for a late wave (about 0.15 ms a character, and late waves
   have 60-100 enemies plus minions). Two ways that work:
   - **Bake in the art tool:** draw each pose in vector code at the game's resolution and save sprite sheets, as
     `tools/art/` does today. Everything downstream stays as it is (`DirectionalSprite`, SpriteFrames, the art tests); the
     look changes, not the engine. This is the recommended path.
   - **Cutout meshes:** `Polygon2D` parts on `Skeleton2D` bones, as this branch's earlier rig experiment
     (`entities/hero/vector/`) does. Smooth animation at any scale, but a different animation pipeline and more work per
     character.
2. **Redraw every asset family.** Estimates from this test, for a first pass at this quality:
   - **Heroes:** about 1-2 sessions each (every state and facing, the ultimates).
   - **Enemies and bosses:** about 0.5 a session each, and more for bosses (33 in all).
   - **Towers and evolutions:** about 0.5 a session each (around 30 looks).
   - **Biome grounds:** about 0.5 a session each (9), plus their props.
   - **Effects:** this style fits them best (glows, rings, arcs; `fx.ts` is a ready recipe). A few sessions.
   - **Fortress:** 4 damage states.
   - **UI and font:** today's pixel font and frames would clash with smooth shapes. A new UI theme and a smooth font are
     needed; the font must be self-made or CC0, per CLAUDE.md rule 3.

   That is roughly 40-60 sessions of art work. It's at least as big as M15, and it would replace M15.
3. **Rules and docs:**
   - CLAUDE.md's Pixel art section and `ART_DIRECTION.md` would be rewritten (2x world pixels, outlines, nearest filtering,
     the 24 px font, no scaling).
   - `test_readability` and the art tests would follow the new rules.
   - The screenshot tools stay.
4. **Risks:**
   - The game loses its 16-bit identity, which the title art, the store plans and every playtest so far are built on.
   - Mixed styles during the change, so the art must switch in one go, behind a branch.
   - Performance needs baking from day one.

**Recommendation:** if the owner likes the right-hand side, the next step is a second, deliberately small test: the baked
path (the Knight and the Ghoul drawn in vector code into sprite sheets by the art tool) on one whole screen with the
fortress, props and pads redone too. Only that shows the finished look and its real cost. Nothing on this branch is to be
merged.

## Round 2: more detail (the owner: "can it get more detailed? i want it to look epic, not like every other flash game")

**What changed:**
- **Painted shading** (`vector_paint.gd`): every shape gets a base gradient, a cool shadow band away from the light, warm
  highlight bands toward it, and a cold moonlight rim on the far edge. The bands are the shape minus itself shifted
  (`Geometry2D.clip_polygons`), sized to a third of the shape. Also tapered strands for hair, plumes, sinew and folds,
  rivets, and curves.
- **The Knight** (`knight_painter.gd`):
  - Plate: a breastplate with a ridge and faulds, a chainmail skirt, layered riveted pauldrons, greaves with knee cops.
  - Cloth: a cape with folds and a tabard with gold trim and the keep emblem.
  - Shield and helm: a kite shield with a gold chevron and studded rim; a great helm with visor slit, breaths, brass band
    and a plume of strands.
  - The sword arm is live: a fullered blade, a gold guard with a glowing gem, a wrapped grip. The swing throws sparks.
- **The Ghoul** (`ghoul_painter.gd`):
  - Body: a starved frame under layered, holed, tattered rags, an open ribcage, sinewy arms with knobby joints and bone
    claws, spine spurs from behind.
  - Head: a skull with sunken sockets and red pinpoint eyes, a gaping jaw with teeth, lank hair; in profile it juts
    forward on a long neck.
  - Cold mist rises off it.
- **The Archer tower** (`archer_painter.gd`):
  - Stone and wood: masonry block by block in varied tones with moss and a crack, an octagonal plinth of dressed stones,
    a plank deck with merlons, iron sconces.
  - Level details: level 2 adds a gold band, level 3 gold merlon caps.
  - Live: a red banner with the keep, a hooded archer drawing a recurve toward the target, flickering torches with embers.
- **The ground:** a noise-textured base (grass tones, worn soil, cold near the crypt, warm near the fortress, dark edges),
  2,600 grass clumps in three tones, flowers, leaves, mossy stones, roads with grit, bedded stones, ruts, puddles and grass
  over their edges, a flagstone plaza, and glowing mushrooms by the crypt. It's baked at 2x.
- **The bake path, built** (`vector_pose_cache.gd`): poses are painted once into textures at 2.5x on demand (a
  SubViewport, premultiplied alpha) and reused:
  - characters per facing, walk or idle and phase (12 / 8 / 6 attack steps);
  - the tower body per level, the archer per aim (24) and draw (3), the pennant per wave (8).
  - Death, dash and bob are transforms of baked poses.
- **Bug found:** the tower's shot animations are `archer_fire[_N]`, not `attack`, so round 1's bow never recoiled.
- **New tool:** `tests/tools/vector_model_sheet.gd` saves `model_characters.png` (the Knight and the Ghoul, all three
  facings) and `model_towers.png` (the Archer at levels 1-3), pixel above vector, at 3x.

**Performance** (same fight, vsync off): pixel 2.8 ms, vector round 2 **7.4 ms** (round 1 was 9.8 with far less detail).

| Part | Extra per frame |
|---|---|
| Baked ground | about +0.3 ms, the same as today |
| Knight | +0.7 ms |
| 4 towers | about +1 ms (+3 before their archer and pennant were cached) |
| 33 Ghouls | +2.9 ms |

The Ghouls' remaining cost is per-node script work (their live glows and mist), not drawing. A production bake into
SpriteFrames, with GPUParticles for the mist, would remove it.

**What the model sheet shows (the honest part):**
- **More detail, but it doesn't reach the pixel art:** the vector version is far more detailed than round 1, but at the
  game's size (characters about 40-50 px tall) it still holds less detail than today's pixel art.
- **The Knight:** the Pixellab Knight (top left) reads richer: every pixel is a decision, and pixel art is built to carry
  detail at exactly this size. Vector detail under about 2 px blurs into the fills, which is where the "Flash" look comes
  from.
- **Where vector wins:**
  - The Ghoul: creepier and more readable as a cold dead thing.
  - The tower: warm, lit and alive.
  - Light and atmosphere: glows, torch light, the swing arc, the ground's colour temperature.
- **What makes a game look epic** at this camera distance is mostly lighting, atmosphere and effects (warm light against
  cold dark, glows, particles, impact), and less the line art itself.
