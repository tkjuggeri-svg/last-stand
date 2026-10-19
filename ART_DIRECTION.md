# LAST STAND — Art Direction

The visual rules every asset follows. If a new asset breaks one of these, fix the asset (or change
this document on purpose — never drift silently).

## 1. Identity in one line

**A grim, candle-lit last bastion at the edge of a haunted graveyard**, in crisp 16-bit pixel art seen
from a 3/4 top-down camera. Muted, cold world; warm, saturated life (fire, gold, the hero's red);
sickly pale undead with burning red eyes.

Reference feel (mood only — never copy art): late SNES / modern "HD-pixel" action games.

## 2. Resolution and scale

| Rule | Value |
|---|---|
| Base viewport | 1280×720 (stretch `canvas_items` / `expand`) |
| Art pixel | **1 art px = 2 world px** (`ART_SCALE`); every sprite node has `scale = (2, 2)` |
| Effective art canvas | 640×360 art px on screen — the classic "HD pixel art" resolution |
| Screen pixels per art pixel | 2 / 3 / 4 / 6 at 720p / 1080p / 1440p / 4K (always whole numbers) |
| Filtering | nearest-neighbour, 2D pixel snapping on; no rotation, skew or non-2× scale on sprites |

### Asset sizes (art px)

| Asset | Frame | Notes |
|---|---|---|
| Hero | 32×40 | figure ≈ 28 px tall incl. plume; feet 7 art px below the node origin |
| Ghoul | 32×32 | figure ≈ 21 px tall, hunched; feet 7 art px below the origin |
| Hound | 32×32 | low quadruped ≈ 22 px long, 14 tall; paws on the same line as the Ghoul's feet |
| Brute | 48×48 | figure ≈ 36 px tall; feet on art row 44 (sprite offset (0, −20)) |
| Cultist | 32×32 | figure ≈ 23 px tall with the pointed hood; hem on the Ghoul's foot line |
| Bosses | 64×64 | figures ≈ 48–54 px tall; feet on art row 58 (`boss_art_kit.gd`); the Lich floats 6 px above it |
| Towers | 32×48 | base footprint ≈ 26×12 at the bottom of the frame |
| Fortress | 96×96 | the 48×48 footprint (= 96×96 world collision box) sits at the bottom |
| Swing trail | 72×72 | radius 34 = the hitbox's 68 px reach |
| Projectiles | 12×12 | |
| Small effects | 16–24 | sparks, dust, frost |
| Explosion | 56×56 | = the 112 px blast area |

**Hierarchy by size:** fortress ≫ bosses ≈ towers > brute > hero > ghoul > hound. The hero must always be the most readable
thing on screen; enemies read second; buildings are big but darker and calmer.

## 3. Camera and perspective

- **3/4 top-down** (camera looking north and down). We see **tops and south faces** of everything;
  never east/west faces of buildings, never pure top-down roofs.
- Characters: front view (`down`), back view (`up`) and right profile (`side`, mirrored for left).
- Tall things (fortress, towers, trees, tombstones) are y-sorted by their **base** and may overlap
  what stands behind them.

## 4. Light

- **One key light from the top-left**, slightly toward the viewer (`Canvas.LIGHT`).
  Lit: top faces, left sides, upper-left of rounded volumes. Shadow: lower-right.
- Shading is **banded, never smooth**: each surface is snapped to its material ramp (3–7 colours).
  Large flat surfaces (walls, roofs) may use ordered (Bayer) dither between two neighbouring bands;
  characters don't.
- **Contrast curve:** the brightest ramp colour only appears as small highlights facing the light.
- **Ground shadows:** soft oval, black at 34 % alpha, under every character and building, offset
  a little to the lower-right for buildings.
- **Scene light (in game):** a cool dusk `CanvasModulate` (0.64, 0.66, 0.80), with banded
  `PointLight2D`s (`light_soft.tres`): warm on lanterns, braziers, windows and fires, cold blue on
  the frost crystal (`TowerData.glow_color`), sickly green at the crypt, a faint warm lantern on the
  hero. Keep energies low (0.2–0.7): light should tint, never wash sprites out.

## 5. Colour

Master palette: `tools/art/palette.gd`. Each material is a ramp from deep shadow to highlight.

- **Hue shifting:** shadows lean cool (blue/violet), highlights lean warm (yellow). No pure greys,
  no pure black (except `#1a141f`, the outline colour).
- **World:** desaturated, dark — grass `#24331a`, dirt `#433325`, stone `#5b5667`, slate roofs `#302c45`.
- **Accent:** red (`TABARD`, `BANNER`) only on the hero and on the fortress's banners — the player's side.
- **Gold:** trims, coins, UI highlights, the order's tower emblem.
- **Undead:** ashen grey-green skin (`GHOUL_SKIN`), red eyes (`EYE_GLOW`), pale green souls (`SOUL`). Each enemy type has its own hue so they read apart at a glance: Ghoul grey-green, Hound red-brown hide over bone (`HOUND_HIDE`), Brute violet-grey (`BRUTE_SKIN`, kept light because the cool dusk light flattens violets, plus a 1 px rim light on its top-left silhouette edges), Cultist a pale ash-grey robe (`CULT_ROBE`, the lightest enemy, so the fragile caster is spotted at once) with a black hood hollow and bright green witchfire (`WITCHFIRE`: eyes, orb, shots) plus a faint green light.
- **Magic/elements:** fire `FIRE` (orange → white), ice `ICE` (deep blue → white).
- Characters are always **brighter and higher-contrast than the ground** they stand on.

## 6. Outlines

- 1 px outline `#1a141f` around every character, building and projectile silhouette.
- **Interior contours:** where a front part overlaps a back part, the back part gets a line in its own
  hue pushed toward the outline colour (selective outline). This is automatic in `Canvas.finish()`.
- Soft things (flames, smoke, glows, souls, swing trails) have **no outline**.

## 7. Materials

| Material | How it reads |
|---|---|
| Steel (hero armour) | cool blue-grey, strong specular highlight at top-left, dark lower-right |
| Cloth (tabard, cape, banners) | flat-ish, 4–5 band red, folds as 1 px dark lines |
| Gold trim | 2–3 px accents only, bright highlight pixel |
| Skin (undead) | ashen, low saturation, darker in hollows (sockets, ribs) |
| Stone | blocks with mortar lines, light top edge, dark bottom edge, moss near the ground |
| Slate roofs | dark violet-blue with lighter ridge lines, dithered toward the eaves |
| Wood | warm brown planks with dark gaps, used for hoardings, scaffolds, the archer's platform |
| Iron | near-black blue with a single cool highlight (cannon, bands, portcullis) |

## 8. Proportions

- Hero: heroic chibi — head ≈ 1/3 of the body, broad shoulders (pauldrons), long sword (≈ 10 px),
  heater shield. Silhouette must read as "knight" from the plume and cape alone.
- Ghoul: hunched (head between the shoulders), thin limbs, long arms with claws, small and wiry.
  Silhouette must read as "crawling thing" next to the upright hero.
- Buildings: thick bases, slightly wider at the bottom, heavy roofs; nothing spindly.

## 9. Animation

| Rule | Value |
|---|---|
| Idle | 4 frames, 5 fps: breathing, cape/plume sway, never fully still |
| Walk | 6 frames: hero 11 fps, ghoul 8 fps (shambling); body bob 1 px, secondary motion lags |
| Attack | anticipation → strike → follow-through → recover. Hero 4 frames at 20 fps (fits the 0.4 s cooldown). Ghoul 6 frames at 12 fps: the strike frame starts at 0.33 s = the 0.35 s wind-up |
| Death | 6–7 frames: pale hit flash, buckle, fall, settle; ghouls crumble and release a soul |
| Buildings | idle loop (flags, flames, crystals, crew) + attack animation per tower |
| Effects | 4–6 frames at 14–24 fps; fade with ordered dither, not alpha |

- Feet never slide off their ground line between frames; frames share one anchor (the feet).
- Visuals follow gameplay, never drive it: timings come from the data, art is fitted to them.

## 10. Effects

- Short, bright, readable: an effect should last ≤ 0.6 s and never cover the enemy it hits for long.
- Impact = white core → coloured body → dark/ash edge.
- Smoke and dust are shaded puffs (lit top-left) that thin out with dither.

## 11. Environment

- Ground: dark grass with mossy and dry patches, worn dirt lane with ruts and stones, a trodden
  clearing around the fortress, a stone wall band around the arena.
- Props (graves, crosses, dead trees, bones, rocks, lanterns) cluster in **themed areas**
  (the graveyard around the spawn, ruins along the walls) and keep the lane, the build slots and the
  fortress approach clear.
- Atmosphere: drifting fog patches and floating motes; no effect may reduce gameplay readability.

## 12. UI

- **Pixel font:** original proportional 5×7 glyphs with a 1 px dark outline baked into every glyph
  (`ui_art.gd`), a 12 px bitmap cell drawn at exactly **24 px (2×)**; titles at 48/72 (4×/6×). Never
  use other sizes (the font only scales by whole multiples). The theme is project-wide
  (`gui/theme/custom`), so world labels use it too.
- **Frames:** dark panels with a bevelled gold-bronze rim and rivets (`panel.png`), stone-rimmed
  cards (`CardPanel` variation) and buttons (gold rim on hover/focus). UI textures are saved
  pre-scaled to 2× because StyleBoxTexture/TextureRect draw texels 1:1.
- **Bars:** bronze-rimmed trough; fortress = steel blue, hero = red (life). Icons (keep, helm, coin,
  foundation, skull) lead every HUD row.
- Gold always uses the coin icon and the gold colour `#efd07a`.
- Layout: HUD bottom-left, notifications top-right, build panel bottom-right; nothing in the middle.

## 13. Pipeline

All art is original and generated in code (`tools/art/`). Never hand-edit generated PNGs.

```
godot --headless --path . --script res://tools/art/generate_art.gd [-- --only=hero,ghoul]
godot --headless --path . --import
godot --headless --path . --script res://tools/art/build_sprite_frames.gd
```

- `canvas.gd` — shaded primitives (ellipse, capsule, cylinder, block, polygon), contours, outline.
- `palette.gd` — the ramps above.
- `hero_art.gd`, `ghoul_art.gd`, `hound_art.gd`, `brute_art.gd`, `cultist_art.gd`, `gravelord_art.gd` / `colossus_art.gd` / `lich_art.gd` (on `boss_art_kit.gd`), `effects_art.gd`, … — one file per asset family, posed in code (`undead_fx.gd`: the shared crumble/soul death effect).
- Review: `tools/art/preview_art.gd` (enlarged contact sheet) and the `gallery` scenario of
  `tests/tools/capture_screenshots.gd` (every animation at real game scale over the real level).

## 14. Review checklist (before committing art)

1. Looks right in the **gallery** and in a real game screenshot at 1280×720 (not only zoomed in).
2. Silhouette reads at 1× scale; hero > enemies > buildings > ground in contrast.
3. Light comes from the top-left everywhere; outlines present (or deliberately absent on soft FX).
4. Frames share their ground anchor; no jitter in idle/walk loops.
5. Effects don't hide enemies, health bars or the lane.
6. `tests/run_tests.sh` passes.
