# M11: World & Story (design proposal)

> **Status: approved on the recommendations (the user's blanket permission of 2026-10-25), being built.**
> Section 9 lists the decisions. The texts are the game's first draft: they are data, so changing them never
> needs code. Numbers are starting points.

## 0. Summary

- **The world:** the kingdom of **Vael** fell in one night, the **Waking**, when its dead stood up. **Last Light**
  is its final fortress; you hold it. Why the dead rise is the game's mystery, and each of the three tier-3
  bosses is one **truth**: the Fallen Marshal (an order that was never lifted), the Deep Warden (what the miners
  woke), the Pale Bishop (a mercy that went wrong).
- **Three endings**, one per tier-3 boss, each a short illustrated-by-text epilogue; a fourth, secret one once all
  three are seen.
- **Three heroes with their own reasons** (a line each in the War Room's hero panel, and on the run's start).
- **Three characters in the War Room** (the Quartermaster, Sister Ilse the chaplain, Orm the smith), each with a
  story told in **beats** across runs: a beat appears when its condition is met (a boss beaten, a biome
  reached, a hero's win...), and they still react to the last run. Lines and beats are data
  (`data/story/`), not code.
- **Texts for the run map:** 18 new events (two per biome) in the biomes' voice; a line of narration for each
  biome (on the road card and the map); a line for each boss when it appears.
- **The Chronicle**, a screen in the War Room: everything the player has met (foes, places, characters' beats,
  endings), unlocked by playing; locked entries show "?".
- **Portraits** for the three heroes and the three War Room characters, drawn in code.
- **Built in 4 stages:** (1) the story data, the save, the characters and the hero portraits; (2) the events;
  (3) narration, boss lines and the endings; (4) the Chronicle. No autoload, layer or input action.

## 1. The story

**Vael** was a kingdom of farms, quarries and a great cathedral. In the **Waking** its dead rose from every
grave, mine and battlefield and walked toward **Last Light**, the keep on the old crossroads. The hero holds it.
Each run is one night's defence, in a different place each time (a biome): the dead come through the
crypts, the orchard, the marsh, the pass, the mines.

| | The Knight | The Huntress | The Necromancer |
|---|---|---|---|
| Who | **Ser Aldric**, last of the Order of the Keep | **Wren**, a ranger of the high marches | **Maren**, a gravecaller the Cathedral cast out |
| Why they fight | the Order's oath: *the keep holds* | the dead burned her village; she hunts what is left | she is the only one who can hear the dead, and wants to know what they are asking |
| Line (hero panel) | "The oath doesn't ask if we win." | "Every road has an end. I only need to find the dead's." | "They are not angry. They are asking. I mean to hear it." |

**The truths** (each tier-3 boss, each ending):
- **The Fallen Marshal** (Ashen Keep): the commander who barred the gates of the keep against the refugees to
  save the rest, and fell with it. His last order, *hold the line*, was never lifted: the dead are the soldiers
  still obeying it. **Ending:** the hero lifts the order; the dead lie down, and the keep's gates are opened to
  the living for the first time in a hundred nights.
- **The Deep Warden** (Sunless Mines): the miners' warden who woke the Sleeper beneath Vael looking for the
  last vein. The dead are what comes up with it. **Ending:** the hero seals the shaft; the dead stop, and so
  does the ore: Vael will never be rich again, and lives.
- **The Pale Bishop** (Pale Cathedral): when the plague came, the choir sang the dead back so no one would be
  alone. It never stopped. **Ending:** the hero ends the song; the silence is the first peace in the kingdom,
  and the first grief.
- **The secret ending** (all three seen): the three truths were one night; the bell that rang it, in Last
  Light's own tower, is rung once more, and Vael sleeps. The hero's name is added to the keep's wall.

Smaller bosses and the regular dead get **lore entries** (what they were: the Gravelord a sexton, the Lich
Warden the king's chancellor, the Tollkeeper the road's last toll-man, the Pyre Warden the orchard's
burner, the Winter Warden a pass-warden who froze at her post, the Hollow Stag a grove spirit, the Quarry
Colossus a statue the masons never finished).

## 2. The War Room's characters

| Character | Role | Voice | Story across runs (beats) |
|---|---|---|---|
| **The Quartermaster** (Dunmore) | the ledgers, the shards | dry, practical | counts each run; after a first boss he admits his brother served the Marshal; after the Ashen Keep he reads his brother's last letter; after the Marshal ending he opens the gate ledger |
| **Sister Ilse** | the chaplain, the Cathedral's exile | gentle, guilty | after chapter 2 she names the Pale Cathedral; after the Bishop she says she sang in the choir; after the Bishop's ending she stops praying for the dead and starts listening |
| **Orm the smith** | towers and unlocks | gruff, proud | after the Brazier unlock he tells of forging the keep's bell; after the Sunless Mines he says his father died in them; after the Deep Warden ending he lights the forge again |

- The **reactive lines** of M8 (about the last run) stay, as data (`HubLine`: conditions and text), spread over
  the three characters: the one best suited to the run speaks (a loss in the marsh: the Quartermaster; a
  relic found: Orm; a boss beaten: Ilse).
- A **beat** (`StoryBeat`) is a longer speech (3-5 lines) with a condition; the hub shows the **next unseen beat** of
  each character as a card ("Orm has something to say"), read once with a button; `beats_seen` in the save.
- Conditions are a small fixed set (data fields, one rule each): runs, wins, a boss beaten, a chapter reached,
  a biome entered, a hero owned or won with, an ending seen, a beat seen.

## 3. Texts for the run map

- **18 events** (2 per biome, `data/events/`), each 2-3 choices from the existing `EventData` / `EventEffect`
  kinds (gold, upgrades, fortress, lives, free levels, relics...). Examples:
  - *The Farmer's Cider* (Orchard): "A farmer sits among burnt barrels with one jug left." Buy it (gold: a
    free tower level), pour it on the dry grass (a fire: the next fights' enemies burn: a free evolution?),
    leave.
  - *The Foreman's Whistle* (Quarry), *The Frozen Sentry* (Pass), *The Lamplighter* (Wood), *The Canary*
    (Mines), *The Last Pew* (Cathedral), ...
- **A line of narration per biome** (`ChapterData.intro`): shown under the road card and on the map ("The
  orchard burned the night the Waking began. The apples are still hanging.").
- **A line per boss** (`EnemyData.hint`, shown when it first appears): the Marshal: "Hold the line." The line
  is also its lore entry's first sentence.

## 4. Endings

- When the last chapter's boss falls, Main shows an **EndingScreen** chosen by that boss: a title, 3-4
  paragraphs, then the run summary as before. The three texts and the secret one are `EndingData`
  (`data/story/endings/`).
- `endings` in the save; the War Room shows "Endings found: n of 3" (and the secret one once seen).
- The ending is picked by **which tier-3 boss was the finale** (the player's last road choice), so the
  road choice at the end of chapter 2 is also the choice of story.

## 5. The Chronicle

A War Room screen with four lists: **Foes** (a lore entry unlocks when the enemy first appears in a run),
**Places** (a biome, when its map is first entered), **People** (the characters' beats seen, the heroes'
stories), **Endings**. Locked entries show "?" and a hint. `LoreEntry` resources (`data/story/lore/`); the
save keeps `foes_seen`, `places_seen`.

## 6. Art

Six **portraits** (the three heroes and the Quartermaster, Ilse and Orm), 64x64 art px (128x128 at the
double resolution), drawn in code (`tools/art/portrait_art.gd`): used in the hero panel, the character cards
and the Chronicle. No other new art.

## 7. How it fits the code (sketch)

- **Resources:** `StoryBeat` (character, condition, lines), `HubLine` (character, condition, text, priority),
  `EndingData`, `LoreEntry`; `StoryBook` (one resource listing them all, loaded by the front end).
- **Save:** version 4: `beats_seen`, `foes_seen`, `places_seen`, `endings`.
- **Rules (no logic in UI):** `Story` (rules only, in `core/utils/`): which beat or line a character says now;
  which lore is unlocked; the ending for a boss. `HubScreen` shows what it is given; `FrontEnd` marks beats
  seen. `Main` records the foes and places a run met (from the level's enemy spawns and the biome entered) and
  picks the ending.
- **Screens:** the hub's character cards and hero portraits; `EndingScreen`; `ChronicleScreen`; all on
  `ScreenFrame` and the theme.
- **Tests:** `test_story` (conditions, beats in order, lines by priority, lore unlocks, endings by boss, the
  save migration), `test_events` extended to the new events (every event loads, effects valid), the UI shots.

## 8. Build order

| Stage | Contents |
|---|---|
| 1 | story resources and rules, save v4, the three characters (lines and beats as data), the six portraits, the hero panel's stories |
| 2 | the 18 events |
| 3 | biome narration, boss lines, the endings (and the secret one) |
| 4 | the Chronicle |

## 9. Decisions

On 2026-10-25 the user's blanket permission ("push the project as far as you can") settled this proposal:
everything above stands as written, taken at the recommendation of each choice (from: recommendation).
Save points: git tags `save/m11-<stage>`.
