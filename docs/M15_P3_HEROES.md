# M15 P3: the other heroes and their towers in vector (Huntress, Necromancer, Skeleton, six towers, ultimate effects)

**Status: proposal, not approved, not implemented.** Sizes, frame counts and memory numbers are starting points, to be checked
with the lineup tool, `test_readability` and `perf_report`. Chapter 1's Knight, the five base towers and the three bosses are done
(`docs/M15_VECTOR.md` P1, `docs/M15_P2_*.md`).

## 0. Summary

- **What:** the two other playable heroes (the Huntress, the Necromancer), the Necromancer's Skeleton minion, the six towers they
  unlock (Trap Layer, Hawk Perch, Watchtower, Bone Pit, Soul Siphon, Ossuary) with their shots and ground effects, the heroes'
  projectiles (crossbow bolt, soul bolt) and the three ultimates' own effects. With P3 every thing a player picks or builds in
  chapter 1 is vector.
- **Same pipeline, same rules as the Knight and the base towers:** painters in `tools/art/vector/`, baked sheets, `SheetSprite`
  / `DirectionalSprite`; nothing in `data/heroes`, `data/towers`, the abilities, the ultimates or the balance changes (visuals
  follow gameplay). Timings match the data (the Huntress shoots every 0.55 s, the Necromancer every 0.45 s).
- **Defenders warm, the dead cold (`ART_DIRECTION.md`):** Wren the Huntress in forest green leather with amber trim and a red-brown
  scarf; Maren the Necromancer in deep teal robes with ivory bone trim and a gold sash, her soul fire a pale teal. The Knight
  keeps red; none of the three can be mistaken for an enemy (the Gravelord and the Lich are violet).
- **Frames:** idle 8, walk 12, attack 8 (the bolt leaves on the data's timing), death 12, dash 4, as the Knight; three facings.
- **Skeleton:** a small bone warrior with a rusty short sword and a buckler, **teal** eyes (allies are teal, the dead are red and
  violet), idle 8, walk 12, attack 8, death 10 (it rattles apart).
- **Six towers**, each with three levels, idle, fire, build (rising on a scaffold) and sell (crumbling into rubble), like the
  base five; the evolutions of these towers stay pixel until P6 (their rows move to their own pixel sheet, as the base towers'
  did). Ground effects drawn with them: the snare (armed and sprung), the patch, the hawk in 8 directions, the soul links.
- **Ultimate effects** get their own vector art (they reuse the frost nova and explosion art today): the Knight's Last Stand ring,
  the Huntress's Volley of Ruin (a rain of bolts with impact bursts and a Mark glyph), the Necromancer's Rise of the Dead (a bone
  circle, hands, skeletons climbing out). The shared **explosion, frost nova, burn and status** effects (the cannon, the frost
  tower, fire and status marks) are redrawn in the same step, since the ultimates and chapter 1's towers use them.
- **Cost:** the Huntress and Necromancer sheets are as big as the Knight's (3456 x 3328 px, about 46 MB each in VRAM); if all three
  heroes' sheets are loaded at once that is 138 MB, so Q2 asks about 1.5 sheet px per world px for the new two (20 MB each).
- **Order:** Huntress and her bolt, Necromancer with Skeleton and soul bolt, the three Huntress towers and effects, the three
  Necromancer towers and effects, the ultimate and shared effects, suite, review shots, `perf_report` and a playtest build.

## 1. What exists today

| Item | Sheet | Rows / frames | Notes |
|---|---|---|---|
| Huntress, Necromancer | pixel, 64 x 80 art px cells | 13 rows (idle, walk, attack, dash x 3 facings, death), 3 to 6 frames | the Knight's old layout; hero shows a crossbow bolt / soul bolt from `bolt_frames` |
| Skeleton (the Necromancer's minion) | pixel 64 x 64 | idle 4, walk 6, attack 4, death 5 | on the `allies` layer, enemies see it like the hero |
| Hero bolts | hero bolt scene, soul bolt 8 directions x 2 frames | | Huntress bolt pierces 1 and Marks; soul bolt homes (3.0) |
| Huntress towers | `huntress_towers.png`, 64 x 96, 36 rows | 3 bases (Trap Layer, Hawk Perch, Watchtower) + 6 evolutions | snare armed 2, sprung 3, patch 4, hawk 8 directions x 2 |
| Necromancer towers | `necro_towers.png`, 64 x 96, 36 rows | 3 bases (Bone Pit, Soul Siphon, Ossuary) + 6 evolutions | |
| Ultimate effects | `ultimate_ring` 480 x 480 (6 frames x 2), frost nova 96, explosion 112 | | M14 reuses them "for now (M15 draws their own)" |

## 2. The design

### 2.1 The Huntress (Wren, ranger of the Gloam Wood)

A slim hooded ranger: a forest-green cloak with a fur collar and a torn hem, a brown leather jerkin with amber stitching, bracers
and boots, a red-brown scarf (her accent), a short sword and a small quiver at the back, a heavy crossbow in both hands, a
braid. Height about 46 world px (the Knight's).
- **Idle:** weight shifting, the cloak and scarf moving; **walk:** a light step, the crossbow carried across; **attack:** the
  crossbow raised to the aim (8 directions come from the three facings plus the live aim), a recoil kick and a bolt leaving on
  the data's timing, a puff of smoke from the string; **dash:** a roll with the cloak trailing; **death:** she drops to a knee and
  falls, the crossbow beside her.
- The Marked glyph (a small amber eye over a Marked enemy) is redrawn in the status effects (2.5).

### 2.2 The Necromancer (Maren, the gravecaller)

A tall hooded figure in deep teal robes with ivory trim, a bone-and-gold pauldron, a gold sash, a skull-topped staff with a
pale-teal flame, small skulls and a lantern at the belt, a thin scarred face half in shadow (pale teal glow in the eyes).
- **Idle:** the staff flame flickers; **walk:** a gliding stride, robes trailing; **attack:** a short staff thrust and a soul bolt
  leaving the skull; **dash:** a blur of mist; **death:** she folds into her robes, the flame goes out.
- **Skeleton:** about 36 px, hunched, a rusty short sword, a buckler with a crack, teal glow in the sockets and a dim teal tint
  on its ribs so allies read at a glance; its death rattles into a pile.

### 2.3 Projectiles

| Projectile | Look | Frames |
|---|---|---|
| Huntress bolt | a short dark bolt with an amber head and fletching, a thin amber streak | 8 directions x 2 |
| Soul bolt | a pale-teal wisp with a skull-shaped head and a trailing tail | 8 directions x 4 (the tail waves) |

### 2.4 The six towers

| Tower | Look | Fire |
|---|---|---|
| **Trap Layer** (L1-3) | a stone-and-timber trapper's hut with a bear-trap rack, rope, an iron-toothed trap on a pedestal; green banners | a trap is thrown, the snare lands armed (jaws open) and springs (jaws snap, a ring of dust) |
| **Hawk Perch** (L1-3) | a tall wooden perch tower with a leather-hooded hawk on a bar, feathers, a rope ladder | the hawk launches (a swoop in 8 directions, wing beats) and returns |
| **Watchtower** (L1-3) | a stone-and-wood lookout with a lantern and a spyglass, a pennant | a flash from the spyglass, a bolt marker over the target |
| **Bone Pit** (L1-3) | a ring of fused bone around a pit with teal fire and skeletal hands reaching out | the hands rise and claw (the pit flashes teal) |
| **Soul Siphon** (L1-3) | a crooked bone pylon with a caged teal soul and cables of light | a beam of soul-light to the target and back |
| **Ossuary** (L1-3) | a stacked-skull shrine with a glowing crypt door and chains | the door opens and a skeleton marches out, bones clatter |

Same sizes, anchors, build (a rising scaffold) and sell (crumbling rubble) animations as the base five; **warm** accents (the lit
windows, the lanterns) on the Huntress towers, **pale teal** on the Necromancer towers.

### 2.5 Effects

- **Ultimates:** *Last Stand* (a golden shockwave ring over the 160 px circle, with a warm pillar on the Knight), *Volley of Ruin*
  (12 bolts falling along the line, each with an amber impact burst and a Mark glyph), *Rise of the Dead* (a teal bone circle
  on the ground, pale hands, skeletons climbing out). Sizes and durations match `UltimateData`.
- **Shared effects redrawn:** the explosion (two sizes), the frost nova, burning ground (the fire patch and flame sprites), the
  status marks (marked, silenced, boosted, slowed, frozen, shielded), the soul burst (the enemy death's rising soul).

### 2.6 Why this way

- One more phase of the same art direction, not a new system: every item is a painter on the existing pipeline, so the
  review tools (lineup, gallery, `test_vector_art` with its cell-edge check) and the tests stay as they are.
- The three heroes and eleven towers a player sees most come before the rarely seen (evolutions, P6).

## 3. How it fits the code (sketch)

- `tools/art/vector/huntress_painter.gd`, `necromancer_painter.gd`, `skeleton_painter.gd`, `huntress_tower_painter.gd`,
  `necro_tower_painter.gd` (each tower its own `paint(ci, level, t, fire)` like `ArcherPainter`, routed by `TowerPainter`'s
  pattern), additions to `effects_painter.gd` and `status_painter.gd`; `"vector"` keys, `"scale"` and sizes in
  `sheet_layouts.gd` for `HUNTRESS`, `NECROMANCER`, `SKELETON`, `SOUL_BOLT`, the hero bolt, `HUNTRESS_TOWERS`, `NECRO_TOWERS`,
  `HUNTRESS_FX`, `ULTIMATE_RING`, `EXPLOSION`, `FROST_NOVA`, `BURN`, `STATUS`, `SOUL_BURST`; the evolution rows move to pixel-only
  sheets (like `TOWER_EVOLUTIONS`), the old pixel dicts stay as `*_PIXEL` where variants or evolutions use their sizes.
- Scenes: the hero and minion scenes' sprites are already `DirectionalSprite`; the towers and effect scenes that show vector
  sheets must be `SheetSprite` (a plain `AnimatedSprite2D` draws them at twice the size); the hero bolt scene and the effect
  scenes are checked one by one.
- Timings: the Huntress and Necromancer attack animations peak on the data's `attack_cooldown`-based fire moment (as the Knight's
  swing does), checked by `test_visuals`.
- **Tests:** the sheets join `CLEAR_EDGES` in `test_vector_art`; `test_visuals`, `test_roster`, `test_readability` (grayscale: the
  heroes and the skeleton stay brighter than the ground) follow the new frame counts; the existing hero, minion and tower tests
  run unchanged, since no rules change.
- **Review:** `m15_lineup.gd` pages for the heroes, the skeleton and the six towers, the gallery scenario, shots of each ultimate.
- No autoload, physics layer, input action or folder change.

## 4. Order of work

| Step | What | Sessions |
|---|---|---|
| 1 | Huntress, her bolt, the hero scene wiring, the Mark glyph | 1-2 |
| 2 | Necromancer, Skeleton, soul bolt | 1-2 |
| 3 | Trap Layer, Hawk Perch, Watchtower with their effects (snare, patch, hawk) | 1-2 |
| 4 | Bone Pit, Soul Siphon, Ossuary with their effects | 1-2 |
| 5 | The three ultimate effects and the shared effects (explosion, frost nova, burn, status, soul burst) | 1-2 |
| 6 | suite, review shots, `perf_report`, playtest build | 1 |

## 5. Open questions

| # | Question | Recommendation |
|---|---|---|
| Q1 | The Huntress's and the Necromancer's looks as in 2.1 and 2.2 (green and amber; teal, ivory and gold)? | **Yes.** They stay clear of the Knight's red and of the dead's red and violet. Name a different idea for either and it is a palette change. |
| Q2 | Sheet scale 2 (like the Knight) or 1.5 for the new two (20 MB each instead of 46)? | **2** for crispness, then measure with `perf_report` and the lineup; fall back to 1.5 (and re-bake the Knight at 1.5 too) only if memory or load time is a problem. |
| Q3 | Frame counts as in the summary (idle 8, walk 12, attack 8, death 12, dash 4)? | **Yes**, the Knight's. |
| Q4 | Redraw the shared effects (explosion, frost nova, burn, status, soul burst) in this phase? | **Yes**: the ultimates and the chapter-1 towers use them; leaving them pixel would be the one pixel thing left in a vector hero's kit. |
| Q5 | The Skeleton: teal eyes and ribs so allies read at a glance? | **Yes.** |
| Q6 | Keep the evolutions of these six towers pixel until P6? | **Yes**, as for the base five. |
| Q7 | Playtest build at the end (`m15-playtest-3`)? | **Yes**, with the three heroes to try. |

## 6. Decisions

(Filled in after approval: # / question / decision / from.)
