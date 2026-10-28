# M15 P2: the vector UI (HUD, menus, cards, font)

**Status: proposal, not approved, not implemented.** Sizes and numbers are starting points, to be tuned in the `ui_shots`
review. The three chapter-1 bosses are the other half of P2 and get their own proposal; this one is only the UI.

## 0. Summary

- **Why:** the owner's playtest of the chapter-1 vector build: "ui is still bland looking and too big", "the lower ui is
  too large to see". The world is now smooth vector art; the UI is still a 12 px bitmap font and 2x pixel frames.
- **Smaller:** the base text size drops from 24 to **18 px**, titles from 48 to **32**, with a vector font (which scales
  by any size, so the old whole-multiples rule goes). The bottom-left HUD shrinks from about 420x250 world px to about
  **230x120**. The first slimming (icon-only bars, enemy count in the wave panel) is already in.
- **Less bland:** a vector theme in the game's own look: dark slate panels with a painted gradient, a thin gold rim with
  a soft inner glow, corner flourishes on modals only, a warm ember accent for the primary action, cold blue for the dead
  side (the boss bar, warnings). One drawn set of frames, baked like the sprites, no per-screen art.
- **Font (OFL, already allowed by Q3):** *Cinzel* for titles and headers, *Alegreya Sans* for body text and numbers,
  both SIL OFL, logged in `assets/CREDITS.md`. The pixel font stays until the last pixel screen is gone, then goes.
- **How it is made:** the theme's `StyleBox`es become `StyleBoxFlat` (rounded corners, border, shadow) where that is
  enough, and baked 9-slice textures from a new `tools/art/vector/ui_painter.gd` where painting is needed (rim, rivets,
  gradient, flourishes). The theme, its type variations and `UiColors` keep their names, so **no screen's scene changes
  except layout sizes**.
- **Scope:** HUD, build menu, pause, settings, upgrade choice cards, merchant, events, map labels, tips, Game Over,
  Victory, title and War Room frames, feedback box. Key art, portraits and icons are P7.
- **Players can still scale:** the existing UI scale setting (`GameSettings.set_ui_scale`, `UiScaleDirector`) stays; the
  new default is simply smaller, and the settings range is re-centred on it.
- **Risk:** the font's metrics differ from the pixel font, so some screens will reflow. `test_screens_fit` and
  `ui_shots` catch overflow at every scale.

## 1. What is wrong now

| What | Measured | Effect |
|---|---|---|
| Body font | 24 px bitmap (12 px cell at 2x) | each HUD row is about 39 px tall |
| Bottom-left panel (before the first fix) | about 420x250 world px, 6 rows | covers a corner of the arena where the hero fights |
| Panels | one bevelled bronze frame with rivets, same on every screen | reads as a placeholder, clashes with the smooth sprites |
| Text | outlined pixel glyphs | jagged next to anti-aliased vector figures |
| Colour | gold, cream, one purple | nothing separates the living's warm UI from the dead's cold threats |

## 2. The design

### 2.1 Type

| Use | Font | Size | Colour |
|---|---|---|---|
| Screen title (`TitleLabel`) | Cinzel Bold | 32 | gold `#efd07a` |
| Section head, gold amounts (`HeaderLabel`) | Cinzel SemiBold | 20 | gold |
| Body (`Label`) | Alegreya Sans Medium | 18 | cream `#ede6d6` |
| Secondary (`DimLabel`) | Alegreya Sans | 16 | `#b8b2c7` |
| Numbers in bars | Alegreya Sans Bold, tabular | 16 | cream |
| Tiny (tooltips, ranks) | Alegreya Sans | 14 | dim |

A subtle 1 px dark outline (the font's `outline_size` 2 with a dark colour) keeps text legible over the arena; panels
are the main contrast, not the outline. Whole multiples are no longer required, so `CLAUDE.md`'s "whole multiples
(24/48/72)" sentence is replaced by the table above once this is approved.

### 2.2 Panels and frames

- **Panel:** `#14111c` at 92 % opacity, a vertical gradient (top 6 % lighter), a 1.5 px gold-bronze rim (`#b98f4a`) with a
  0.5 px lighter top edge, 6 px rounded corners, a soft dark drop shadow (4 px, 35 %).
- **HUD panels** stay compact: no flourishes, 8 px padding, 4 px row gap, and they become **60 % see-through** when the hero
  or an enemy is under them (`SeeThrough` already exists).
- **Modals** (`ModalPanel`): the same panel, 14 px padding, small filigree corners and a thin rule under the title.
- **Cards** (`CardPanel`): a taller panel with a rarity edge (plain bronze, rare gold glow, relic violet glow), the icon
  on a darker medallion.
- **Buttons:** flat slate with the gold rim; hover warms the rim and lifts 1 px; the primary button is ember-red with a
  gold rim (`ButtonPrimary`); disabled is desaturated. Press sounds stay as they are (`UiSounds`).
- **Bars:** a dark trough with a gloss line, a painted gradient fill (fortress steel blue, hero red, dash cyan, ultimate
  gold, boss violet), a thin rim; height 10 px in the HUD, 14 px for the boss bar.

### 2.3 The bottom-left HUD (what changes, concretely)

```
before (6 rows, ~420 wide)           after (4 rows, ~230 wide)
[keep]   Fortress  =====  100 / 100  [keep]  =======  100/100
[helm]   Hero      =====  100 / 100  [helm]  =======  100/100  v v v
[dash]   Dash      =====  Ready      [dash]  =======  Ready
         Ultimate  ==     52%        [coin] 256   [slot] 13/16
[coin] 256 [slot] Slots free: 13/16
[skull] Enemies left: 6 / 8            (enemies: in the wave panel, top-left)
```

- The ultimate bar appears only while the ultimate exists and is not full or ready (a thin gold line under the dash bar,
  no label); it flashes when ready (text "Q").
- "Slots free: 13 / 16" becomes the slot icon and "13 / 16" (the tooltip says the rest).
- Everything keeps its unique-name node, so the tests that read `%SlotsLabel` etc. only change in their expected text.

### 2.4 The other screens

| Screen | Change |
|---|---|
| Wave panel (top-left) | wave, phase and enemies left in one compact panel; the Start button is the one primary button |
| Build menu | five towers as compact cards (icon, name, cost, key hint), 2 rows of 3, the rest of the panel gone |
| Upgrade choice | three cards at 220x300 (was about 300x380), rarity glow, the Reroll/Skip buttons as secondary |
| Pause, settings, Game Over, Victory | the modal pattern with Cinzel titles; settings sliders get the bar look |
| Merchant, events, chapter | the card grid and modal pattern; prices with the coin |
| Run map | node labels in Alegreya 16, the legend smaller |
| Tips (`HintPanel`) | a compact toast bottom-centre, 14 px body, auto-hides |
| Title, War Room, summary | `ScreenFrame` gets the new rim; key art and portraits wait for P7 |

### 2.5 Why this way

- **Theme-level change, not per-screen:** the project already styles through type variations (`ART_DIRECTION.md` 12), so
  replacing the theme restyles every screen at once, and no screen carries colour or size overrides.
- **StyleBoxFlat first:** rounded rects, borders and shadows need no art and scale to any resolution; textures are used
  only for what a StyleBoxFlat cannot paint (rivets, filigree, gloss).
- **Smaller by default, scalable by choice:** the player's scale setting remains for accessibility.

## 3. How it fits the code (sketch)

- `assets/fonts/`: the OFL font files (`Cinzel`, `AlegreyaSans`) and their licences; `assets/CREDITS.md` entries.
- `tools/art/vector/ui_painter.gd` (+ a `ui` layout in `sheet_layouts.gd`): bakes the 9-slice textures (modal corners,
  card medallion, bar gloss) to `assets/sprites/ui/`; the bake and import steps are the existing ones.
- `ui/theme/game_theme.tres`: rebuilt by a small tool script (`tools/art/build_ui_theme.gd`, so the theme stays
  reproducible and tunable from one table), same type-variation names; `UiColors` values updated.
- `ui/widgets/health_bar.*`, `ui/hud/hud.tscn`, the build menu, cards and modals: size and container changes only.
- `GameSettings` UI scale (today 70-120 %, default 100 %): its range stays; because the base is smaller, 100 % is the new smaller look. No migration is needed.
- **Tests:** `test_screens_fit` (every screen fits at 100/125/150 %), `test_hud`, the menu tests for changed text, and a new
  `test_ui_theme` (every variation exists, every font loads, no node uses a per-node colour override, body text is at least
  14 px). `tests/tools/ui_shots.gd` is the review tool.
- **No** autoload, physics layer, input action or folder change.

## 4. Order of work

| Step | What | Sessions |
|---|---|---|
| 1 | fonts in, theme tool, `UiColors`, panels/buttons/bars; HUD and wave panel | 1-2 |
| 2 | build menu, upgrade cards, tips | 1-2 |
| 3 | modals (pause, settings, Game Over, Victory, merchant, events), map labels | 1-2 |
| 4 | front-end frames, feedback box, review shots, scale checks, playtest build | 1 |

## 5. Open questions

| # | Question | Recommendation |
|---|---|---|
| Q1 | Base size 18 px (about 25 % smaller than now)? | **Yes**, with 16 for secondary text. The minimum readable on a 1280x720 laptop is 14. |
| Q2 | Fonts: Cinzel + Alegreya Sans (both SIL OFL)? | **Yes.** A classical display face for titles fits dark fantasy; Alegreya Sans is very readable at small sizes. If you prefer another pair, name it and it is a one-line swap. |
| Q3 | Keep the pixel font anywhere? | **No**, except on screens not yet redone while the branch is in progress; deleted at the end of M15. |
| Q4 | Ultimate bar: hide until relevant? | **Yes**: shown only when there is an ultimate and it is charging or ready. |
| Q5 | HUD see-through behaviour when the hero is beneath? | **Keep the current `SeeThrough` rule**, at 60 % opacity. |
| Q6 | Default UI scale stays 100 % but the base is smaller, so players who liked the big UI raise it? | **Yes**; the settings range stays 70-120 % (raise the maximum to 150 % if 120 % feels too small on 4K). |
| Q7 | Build the UI before the three bosses, in separate phases? | **Yes**: UI first (this note's feedback), the bosses next. |

## 6. Decisions

(Filled in after approval: # / question / decision / from.)
