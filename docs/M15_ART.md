# M15 — Art Overhaul: scope (proposal)

**Status: proposal, not approved, not implemented.** Numbers are estimates from one Knight test, not measurements of
every character. Per CLAUDE.md rule 7 nothing is built until the owner answers section 8. Sources: `docs/ART_BACKLOG.md`,
`ART_DIRECTION.md`, the Pixellab Knight test (`exports/pixellab-test/`, `assets/CREDITS.md`), M14 Q11 (menu and map looks
were moved here), the owner's playtest of `m13-playtest-4` ("visuals of the ultimates can be upgraded later").

## 0. Summary

- M15 replaces what looks like a placeholder and carries the "warm defenders against the cold dead" theme through the art. It
  is **art only**: no gameplay, balance, input, layer or folder change.
- **Order of work is by family, not by file**, so the game is never half old style and half new in one place: (A) the pipeline
  and the Knight, (B) the 21 recoloured biome enemies and bosses, (C) the other heroes, (D) boss side views, (E) towers and
  hazards, (F) the run map and menus, (G) portraits and ending illustrations, (H) ultimate effects.
- **Pixellab makes characters** (8 rotations, then animations); everything it cannot do well stays code-drawn: the ground,
  UI frames, effects, the map's roads. Every Pixellab piece is logged in `assets/CREDITS.md`, snapped to the game palette by
  `tools/art/pixellab/clean_to_palette.py`, and taken out of `generate_art.gd`'s jobs when it replaces a sheet.
- **The test found three problems to solve before volume work:** Pixellab's character came out ~30% smaller than the current
  Knight (needs a larger canvas, about 88 px), more muted (palette snap helps), and its attack animation was the weakest part.
  Section 2 says how each is handled.
- **The limit is credits, not time.** One character cost 19 generations (10 for the character, 3 for each of three animations
  in three facings); with death about 22. At that rate the 21 placeholders need roughly 450 generations and every character
  roughly 750. The trial plan has 22 left. Q1 is the plan decision and comes first.
- Done when: no placeholder is left, `test_readability` and the grayscale review shots pass, and the owner agrees the set looks
  like one game.

## 1. What is replaced, and in what order

| Phase | Items | Count | Why this order |
|---|---|---|---|
| A. Pipeline + Knight | the importer, the new Knight (concept `docs/reference/knight_concept.png`) | 1 hero | proves size, palette and animation quality on the most-seen sprite |
| B. Biome enemies | the 18 recolours of M10 plus the 3 biome bosses that are recolours (`variant_art.gd`, `variant_decor.gd`) | 21 | the backlog's biggest "placeholder" item; own silhouette each (Cinder Ghoul burning, Frost Wraith trailing mist, Burrower a mound, Lamp Wight the lantern, Hollow Treant a trunk, Chorister a robe) |
| C. Other heroes | Huntress, Necromancer (and the Skeleton minion) | 3 | after the Knight is accepted; need design concepts (Q6) |
| D. Boss side views | Gravelord, Colossus, Lich Warden, Tollkeeper, six biome bosses, Fallen Marshal | 11 | Pixellab's 8 rotations make the side view a by-product of B/D, not extra drawing |
| E. Towers and hazards | Trap Layer, Hawk Perch, Watchtower, Bone Pit, Soul Siphon, Ossuary; combo-evolution icons; ice and ember hazards | 6 + hazards | objects, cheaper than characters (`create_1_direction_object`) |
| F. Map and menus | curved roads and landmarks on the run map (M14 F7); unique frames per menu (F6) | screens | **by code**, see Q8; Pixellab only for decorative pieces |
| G. Portraits, endings | boss portraits (Chronicle), second-pass hero busts, four 640x360 ending scenes | ~10 + 4 | `create_image_pro`, hand-checked |
| H. Ultimate effects | own art for Last Stand, Volley of Ruin, Rise of the Dead (they reuse the frost nova and explosion today) | 3 | last: lowest value (owner: "later") |

Phases B, D and E ship as builds of their own so each can be playtested; a family goes in whole or not at all.

## 2. How a Pixellab character becomes a game sprite

| Step | What happens | Tool |
|---|---|---|
| 1 | Concept or text description, `create_character` (mode pro), canvas chosen per row of the size table | MCP, dev only |
| 2 | Animations in three facings: south = `down`, north = `up`, east = `side` (mirrored in game, as now): idle, walk, attack, death | MCP |
| 3 | Raw output kept, never edited, in `tools/art/pixellab/raw/<id>/` (small, checked in) | importer |
| 4 | Snap to the game palette ramps and add the 1 px `#1a141f` outline and soft oval shadow where missing | `clean_to_palette.py` (exists), shadow step to add |
| 5 | Build the sheet in the layout of `docs/ART_SPEC.md` (frame size, feet anchor, fps from the data), then `build_sprite_frames.gd` | importer + existing tool |
| 6 | Log in `assets/CREDITS.md`; remove the sheet from `generate_art.gd`'s jobs | by hand |

Answers to the test's three problems:

- **Too small:** generate at a canvas where the figure matches ART_DIRECTION's sizes (hero ~28 art px = 56 world px figure, so
  a Pixellab canvas of about 88). The importer checks the figure height against the table and refuses a sheet that is off by
  more than 10%.
- **Too muted:** palette snapping to the existing ramps, then a review shot in the game next to the old sprite.
- **Weak attack:** write the attack prompt from the strike frame outward (anticipation, strike, recover must fit the data's
  timing, e.g. the Ghoul's strike frame at 0.33 s); if two tries fail, keep the code-drawn attack and use Pixellab for the
  rest of that sheet.

Gameplay stays untouched: hit boxes, timings and collisions come from data; art follows ("visuals follow gameplay").

## 3. Credits arithmetic (estimate)

From the Knight test: character 10 generations, idle 3, walk 3, attack 3 (one per facing), 19 in all; death adds about 3.

| Scope | Characters | Generations (approx.) |
|---|---|---|
| Phase B only | 21 | 450 |
| B + C + D | 21 + 3 + (11 bosses, most already counted in B/C) | 550 |
| Every character (36) | 36 | 780 |
| Re-do a character once in five | +20% | +110 to +150 |

Smaller canvases and quadrupeds may cost less; objects (towers) and images cost less per piece. I have not checked the price
of a larger plan, so I cannot say what this is in money; Q1 asks you to look at the plan and tell me the quota.

## 4. Theme, in practice (ART_DIRECTION)

Warm for the defenders (Knight, towers, fortress, banners, ultimates in gold/amber), cold for the dead (blue-grey, bone,
green-white eyes keep their role colours). The grayscale check stays: every new enemy must read in gray against the biome
ground; the review set gets `--grayscale` shots per phase.

## 5. How it would fit the code (sketch)

- `tools/art/pixellab/import_character.py` (new, dev only): raw frames → palette snap → outline/shadow → sheet in the
  `ART_SPEC` layout + a layout entry; `tools/art/sheet_layouts.gd` gets the replaced sheets marked hand-drawn.
- `tests/automated/test_art_sizes.gd` (new): every character sheet's figure height and feet anchor are within the table's
  tolerance; existing `test_readability` stays the gate.
- No change in enemy or hero scenes except pointing `*_frames.tres` at the new sheets (generated by the existing builder).
- Screenshots per phase via `tests/tools/capture_screenshots.gd` (`gallery`, `review`, `--grayscale`) and a before/after sheet.
- Export check: `build_playtest.sh --pack-check` must still show no `tools/` or MCP files in the game.

## 6. Risks

- **Style drift.** Pixellab characters next to code-drawn ones look foreign (the test showed softer shading). Mitigation: whole
  families at a time; palette snap; if the Knight fails review, phase B is re-planned before spending more credits.
- **Licence and disclosure.** The terms for generated output must be checked and noted in `CREDITS.md` before the first piece
  ships, and the store page will need an AI-use line (parking lot item). Q5.
- **Animation quality varies per character** (the Knight's attack). The re-do margin in section 3 covers it.
- **Size of the repo:** raw frames add some MB; kept to the used animations only.

## 7. Not in M15

Vector or skeletal characters (the `vector-test` experiment, parked by the owner), any gameplay or balance change, new
enemies, towers or heroes, new music or sound.

## 8. Open questions

| # | Question | Recommendation |
|---|---|---|
| Q1 | Pixellab plan: how many generations can M15 use (the trial has 22 left)? Look at the plan's quota and price and tell me the number | **Decide this first.** If it is under ~120 a month, do phase A and B in the order of the most-seen enemies and stretch M15 over months |
| Q2 | Spend the remaining 22 trial generations now on a correctly sized Knight (88 px)? | **Yes, but only on the create step plus idle and attack in one facing (~16)**, to check size and palette before buying credits; the full set waits for Q1 |
| Q3 | Replace only the placeholders (phase B/D) or also the code-drawn Ghoul, Hound, Brute and Cultist? | **Placeholders only.** Replace the base four only if they look bad beside the new ones |
| Q4 | Keep the 1 px outline, palette ramps and shadow rules for Pixellab art? | **Yes**, the importer enforces them; the set must stay one game |
| Q5 | Output licence and the AI-use disclosure: do you want me to read Pixellab's terms and write the CREDITS entry before the first piece ships? | **Yes**, and you decide the store-page wording later |
| Q6 | Huntress and Necromancer: do you have concepts (as for the Knight), or should I write the descriptions? | **You supply a concept per hero if you can**; otherwise I describe them from the current sprites and you approve one picture before animation |
| Q7 | Phase order: B (biome enemies) right after the Knight, or the other heroes first? | **B first**: 21 placeholders are the backlog's biggest gap; the hero set you already see every run |
| Q8 | Run map and menus (F6, F7): by code (curved roads, landmarks, themed frames) or Pixellab pieces? | **By code**, with Pixellab only for a few decorative landmarks; it is layout and shapes, not characters |
| Q9 | Ship phases B, D, E as separate playtest builds? | **Yes** |
| Q10 | Ultimate effects (phase H) at the end, or drop them? | **At the end**, as you said they can wait |

## 9. Decisions

*(empty until the owner answers)*
