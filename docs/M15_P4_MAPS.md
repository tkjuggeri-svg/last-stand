# M15 P4: the other maps in vector (proposal; approved by "continue", 2026-10-28)

**Status: approved on the recommendations (the owner: "Continue the work, it was fine", 2026-10-28). In progress.** Part of
`docs/M15_VECTOR.md` (P4/P5 of its plan, reordered below). Art only: no gameplay, balance, input, layer or data change.

## 0. Summary

- After P0-P3 the Crypt Road (chapter 1's map), its enemies, bosses, heroes and the UI are vector. What is left of the
  world is **seven maps** (Ember Orchard, Bone Quarry, Drowned Marsh, Frostbound Pass, Gloam Wood, Ashen Keep, Sunless Mines,
  Pale Cathedral: eight, with the marsh special) and their **enemies and bosses**.
- **Order (changed from the plan):** a run's chapter 1 is drawn from tier 1 (Crypt Road, Ember Orchard, Bone Quarry), so the
  two other tier-1 maps come before tier 2 and 3. Then: **P4a all remaining maps** (ground, wall, gates, 8 props each,
  hazard looks), **P4b the enemies and bosses of tiers 1 and 2**, **P5 tier 3 and the rest**.
- **One parametric ground painter, not eight.** `GroundPainter` takes a **style** (the palettes `tools/art/biome_art.gd` has
  for every biome, copied to `biome_styles.gd`) and a **kind** (grass, snow, ash, stone, moss, tile) that chooses the details
  (blades, ice cracks, cinders, pebbles, ferns, flagstones). The level scenes are alike (a `TiledGround`, three gates, eight
  props), so one script converts them.
- **Per map:** the ground baked from the level itself at 2x (roads, wall band, plaza at the fortress, gate surroundings), three
  gates (the lane starts), eight props, and the glows the pixel level had (gate lights stay `PointLight2D`s).
- **The Drowned Marsh** keeps its own ground (pools painted where the level's `Water` polygons are), its chapel and marsh props.
- **Estimate:** P4a about 8 sessions (7 grounds from one painter, 7 gates, 56 props, the marsh specials), P4b about 10
  (17 enemies and bosses), P5 about 8.

## 1. What is replaced in P4a

| Map (tier) | Kind | Gate | The 8 props (the existing list, `biome_props_art.gd`) |
|---|---|---|---|
| Ember Orchard (1) | grass + cinders | a burnt orchard arch | burnt apple tree, apple cart, scarecrow post, hay bale, broken fence, cider barrel, tree stump, ember pile |
| Bone Quarry (1) | stone + bones | a cut-stone mouth with a crane beam | stone slab, quarry crane, bone heap, cut blocks, cracked pillar, ore cart, rock pile, pickaxe rack |
| Drowned Marsh (2) | water + reeds | its three chapels | the marsh props sheet and the shared lantern, as now |
| Frostbound Pass (2) | snow | an ice-hung stone arch | snow pine, snow drift, ice boulder, frozen banner, icicle rocks, snowy stump, cairn, frozen bones |
| Gloam Wood (2) | moss | a twisted-root arch | twisted tree, glow mushrooms, fallen log, fern bush, root knot, hollow stump, bone moss, wisp stone |
| Ashen Keep (3) | ash | a broken keep gate | broken wall, charred tree, rubble, torn banner, pillar stump, cold brazier, stuck shield, ash mound |
| Sunless Mines (3) | stone + ore | a timbered adit with a lamp | timber support, ore cart, stalagmites, glow crystals, pickaxe rack, mine lamp, rock pile, ore barrels |
| Pale Cathedral (3) | tile | a white arched door | broken pew, saint statue, candle stand, nave pillar, broken arch, altar slab, white banner, pilgrim bones |

## 2. How it fits the code

- `tools/art/vector/biome_styles.gd` (palettes per biome and the kind), `ground_painter.gd` (extended: `style`, `kind`, `gates`,
  `water` polygons), `biome_props_painter.gd` (8 props per biome, `frame(ci, biome, index)`), `gate_painter.gd`.
- `Layouts.GROUNDS` gets an entry per biome (`level`, `biome`, `scale`), `Layouts.STATIC` the props and gates sheets;
  `bake_sheets.gd` already bakes both. The level scenes are converted by `tools/art/vector/convert_level.py` (dev only):
  `Ground` scale 0.5 / tile 256 / linear, gates and props scale 0.5 with doubled offsets and linear filtering, gate lights
  and particles compensated (as for the Crypt Road).
- Tests: `test_vector_art` already checks every static sheet's size; `test_arena_bounds` checks the ground still covers the
  floor plus band; `test_readability` checks every character against every ground (a ground lightened or darkened too far
  fails it); `m15_lineup.gd` gets a `--level=<id>` page to view a map's props and gates.

## 3. Open questions (the owner answered "continue": the recommendations stand)

| # | Question | Decision |
|---|---|---|
| Q1 | Order: tier-1 maps first, then tier 2, then tier 3, or the plan's tier 2 first? | **Tier 1 first**: chapter 1 of every run is tier 1, so a run that rolls Ember Orchard or Bone Quarry would otherwise start in pixel art. |
| Q2 | One painter with styles, or a hand-made painter per map? | **One parametric painter** plus per-map details; maps differ by palette, litter and props, as in the pixel version. |
| Q3 | Same props as the pixel maps (8 each)? | **Yes**, redrawn; new props later only if a playtest asks. |
| Q4 | Marsh pools: painted from the level's `Water` polygons? | **Yes**, so what the hero wades through is what the eye sees. |
| Q5 | Enemies (P4b) before all maps are done? | **No**: finish the maps first so each biome builds can be playtested whole, then the enemies. |

## 4. As built (P4a, 2026-10-28)

- **Painters** (`tools/art/vector/`): `biome_styles.gd` (palettes copied from the pixel generator, the marsh's own, the kind
  and litter of each map), `ground_painter.gd` (one painter for all nine grounds: `style`, `kind` and `litter` choose
  the details: grass, snow with drifts and ice cracks, ash with cinders and burnt windfalls, gravel with bone fragments or ore
  glints, moss with ferns and roots and glowing mushrooms, flagstones, reeds; the marsh's pools are painted from the level's
  `Water` polygons; `path_shift` darkens a map's roads), `prop_kit.gd` (rocks, trees, pines, stumps, posts, barrels, crystals,
  bones, banners, lamps, fire pits, fences, piles), `biome_props_painter.gd` (the 64 props, eight per map), `gate_painter.gd`
  (seven gates and the marsh chapel).
- **Bake:** `Layouts.GROUNDS` has an entry per map (`biome`), `Layouts.MAP_ART` the props, gates and chapel sheets;
  `bake_sheets.gd --only=<biome>,props_<biome>,gate_<biome>` bakes one map. The grounds are 2x (`TiledGround` at 0.5).
- **Levels:** `tools/art/vector/convert_level.py <id>...` converted the eight other level scenes (ground scale and tile
  size, gate and prop sprites halved with doubled offsets, their lights and particles compensated). The marsh's shared graveyard
  props now use the vector graveyard sheet.
- **Readability:** the Pale Cathedral's ground was too bright for the grayscale contrast check twice; it is dark flagstone now and
  its roads are one step darker. `test_vector_art` also checks every static sheet (size, no empty cell).
- **Not done / honest gaps:** the maps' hazard looks (blizzard overlay, rockfall, falling walls, dry-grass fire, caves-ins,
  consecration, gloom) are still the old code-drawn shapes and tints; the marsh's wading ripple is pixel; enemies and bosses of
  tiers 1-2 are P4b.
