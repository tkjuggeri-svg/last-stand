# LAST STAND — Internal Playtest

Thanks for playing! This is an early build: the pixel art, sound effects and **music** are in (all
made in code). The game opens on a title screen; **Play** leads to the War Room, where you start runs. A run
is **three chapters** (one biome of each tier, you choose the road) on a map of choices (about 60-80
minutes if you win; the first chapter alone is about 15-20).

## What to focus on in this build (m13-playtest)

Please write down, with the version from `BUILD_INFO.txt` and the seed from the pause menu, what you see. The bot
data says little about chapters 2 and 3, so those matter most.

1. **Music:** go through the title, the War Room, a run map, a fight in each tier, a boss, a shop, the ending and
   Game Over. Which tracks grate, drag on, are too loud next to the sound effects, or don't fit their moment?
2. **The three heroes:** play each at least once (Huntress 60 shards after beating chapter 1's boss; Necromancer 90
   after reaching chapter 2). Does each *feel* different, or do you build the same way? The Knight's new kit (Bulwark,
   Shield Bash, Oathkeeper, Rally, Iron Will, Crown of Thorns, Banner of the Last Keep) is new: do any feel weak or unclear?
3. **Late biomes (tier 3: Ashen Keep, Sunless Mines, Pale Cathedral):** the waves of all three were smoothed in this
   build (no row more than about x1.8 the enemy HP of the row before; heavy enemies arrive one kind at a time).
   Does row 1-2 feel fair now, and where does the first real wall come? Is any biome clearly harder than the others?
4. **Endings:** beat a tier-3 boss. Does the ending land (text, music, the Descend choice)? Try to see all three
   (Fallen Marshal, Deep Warden, Pale Bishop) and then the secret fourth.
5. **Endless (Descend):** after an ending press Descend. Is the depth scaling (x1.3 enemy HP a depth) fair, are the
   short chapters fun, and does the run end cleanly with a sensible summary?
6. **Pressure:** after your first win turn on 1-3 points. Is that a sensible next step? Does any modifier feel unfair
   (No Repairs, Fewer Slots, Hasty Waves)?
7. **The story:** press Listen on each War Room person, open the Chronicle and a hero's "Their story". Did you read
   them? Do they make you care or just slow you down?
8. **Anything broken:** a stuck screen, a fight that never ends, an error in the console, a save that won't load.
   F8 sends a note with a screenshot and the run's state.

## Running the build

- **Windows:** unzip `LastStand-<version>-windows.zip` anywhere and run `LastStand.exe`. The build is
  not signed, so Windows SmartScreen may warn: *More info → Run anyway*.
- **Linux:** unzip `LastStand-<version>-linux.zip`, then `chmod +x LastStand.x86_64` (if needed) and
  run `./LastStand.x86_64`.
- Needs a graphics card with OpenGL 3.3 (almost any PC or laptop from the last ten years).
- `BUILD_INFO.txt` says which version you have. Please mention it in your feedback.

**Building it (developers):** `tools/build_playtest.sh` runs the test suite, exports both platforms
and zips them into `builds/`. It needs Godot 4.7.2's export templates (Editor → Manage Export
Templates). `tools/build_playtest.sh --pack-check` checks the game data without the templates.

## New in this build: biomes, a story, Pressure, Endless and music (M10-M13)

- **Nine biomes in three tiers (M10):** after each chapter you choose between two roads of the next tier.
  Tier 1: Crypt Road, Ember Orchard (dry grass that burns, you too), Bone Quarry (rockfalls). Tier 2: Drowned
  Marsh, Frostbound Pass (blizzards), Gloam Wood (darkness). Tier 3: Ashen Keep (falling walls), Sunless Mines,
  Pale Cathedral (consecrated ground heals the dead). Each has its own enemies and boss; the new biomes are
  unlocked in the War Room. The new enemies are **recoloured placeholders**.
- **A story (M11):** the War Room has three people (Quartermaster Dunmore, Sister Ilse, Orm the smith) who
  comment on your last run and, when you press **Listen**, tell you more as you play. A place's first visit and
  a boss's first appearance are told in a tip panel. The **Chronicle** (War Room) collects the foes, places,
  stories and endings you have found. Beating the last boss gives one of **three endings** (by that boss),
  and a secret fourth after seeing the others. Each biome has two events of its own (18 new ones).
- **Pressure (M12):** after your first win the War Room has a **Pressure** button: ten difficulty switches
  (tougher elites, no repairs, faster dead, blocked build slots, ...), each worth 1-2 points. More points pay
  more shards (+10% a point) and earn a title (Watchman ... Last Light). No power, only difficulty.
- **Endless (M12):** after the last boss's ending you may **Descend**: shorter chapters of the third tier, the
  dead 30% tougher at each depth, a relic after every boss, until the fortress falls. The deepest descent is
  recorded.
- **Music and credits (M13):** twelve looping tracks (title, War Room, map, fights by tier, boss, shop, ending,
  victory, defeat, credits). The Credits button is on the title screen. The music is untuned: please say
  which tracks grate, drag on or don't fit.

Feedback we would like: Does Pressure's first step (1-3 points) feel like a fair next challenge? Do the three
roads of a tier feel different? Did you read the stories, and did they make you care? Is the music too loud,
too repetitive, or wrong for a moment?

## New in this build: three heroes, combo evolutions and archetypes (M9)

The War Room has two new hero unlocks, and the **< >** buttons in its **Hero** panel pick who the next
run is played with. Neither is stronger than the Knight, only different. Each hero has **its own towers**
(the Archer and the Cannon are shared), **its own cards** and relics; the sword cards (Honed Blade, Long
Reach, Battle Rhythm, Berserker's Oath) are the Knight's.

- **The Knight** (free; Ser Aldric): sword, Brazier, Frost tower and Bone Ballista. **Bulwark:** while he swings he takes 25% less damage. His own cards: Shield Bash, Oathkeeper, Rally, Iron Will; relics: Crown of Thorns, Banner of the Last Keep. Each hero has a short story in the War Room's hero panel.
- **The Huntress** (60 Soul Shards, after you beat chapter 1's boss): a crossbow bolt that passes through 1
  enemy and leaves a **Mark** (towers deal +15% to marked enemies for 3 s); 75 HP. Towers: **Trap Layer**
  (snares hold and hurt the first enemy to step on one), **Hawk Perch** (a hawk dives on the leader; shields
  can't stop it), **Watchtower** (no attack: towers near it get more range, she deals +10% near it). Cards:
  Barbed Bolts, Quick Hands, Snare Mastery, Hunter's Mark, Iron Teeth, Long Cord; relics: Quiver of Plenty,
  Falcon's Hood.
- **The Necromancer** (90 Soul Shards, after you reach chapter 2): a soul bolt, and **every kill it lands
  raises a skeleton** where the enemy fell (3 at a time) that fights for her; enemies stop to fight them.
  80 HP. Towers: **Bone Pit** (raises skeletons), **Soul Siphon** (a beam that burns harder the longer it
  holds one enemy), **Ossuary** (gathers the souls of the dead nearby, then releases them in a blast). Cards:
  Bone Armour, Gravecaller, Soul Feast, Dark Bargain; relics: Reliquary of Bones, Grave Crown.
- **Combo evolutions:** if you hold the right relic, a level-3 tower offers a **third** evolution beside the
  usual two (purple name): Heart of the Pyre (Brazier + Ember Heart), Stillwater (Frost + Hourglass),
  Headsman's Bolt (Ballista + Executioner's Mark), Sky Tyrant (Hawk Perch + Falcon's Hood), Legion (Bone Pit +
  Grave Crown), Banner Guard (Archer + Twin Banners).
- **Archetypes:** every card and relic has a tag (fire, frost, blade, ranged, summon, traps, economy,
  fortress). Once you hold 2 of a tag, more of its cards show up in your offers (4: even more), and the
  upgrade row names your build ("Fire build").
- A new physics layer lets enemies fight skeletons like they fight you. The new heroes, towers and icons
  are a **first art pass** (the new towers look small next to the old ones; no hero portraits yet).

## Between runs: the War Room

Every run pays **Soul Shards**, lost ones too: for each battle won, elite and boss beaten, chapter
cleared, a win, and a one-off reward the first time you beat each boss or reach a chapter. The run
summary after Game Over / Victory (button **Continue**) shows them line by line.

In the **War Room** you spend them on **unlocks**: the Brazier and Bone Ballista towers, each tower's
evolutions, packs of upgrade cards and relics, a rare event, and two small perks (Muster: choose a
starting card; Drill: one free card reroll per chapter). They add **options**, never raw power. Your
**first run** has only the Archer, Cannon and Frost towers, 13 cards, 5 relics and no evolutions.

- **Quitting mid-run is safe:** the run is saved every time the map shows. **Continue** on the title
  screen takes you back to the map (a fight you quit is played again from its start).
- **Esc → Abandon run** ends a run early (it still pays its shards).
- **Tips** appear once each at the bottom right the first time something comes up; "Skip all tips"
  turns them off (the War Room's Tips switch turns them back on, from the start).
- **Reset progress** (War Room) starts your profile over.

## How to play

You are the last knight of a dying fortress. Waves of the dead come down three roads; if the
fortress falls, or you lose your last life, the run is over (in either chapter: no checkpoints).
Beat the boss of chapter 2 to win.

**The map:** each chapter is a map of stops, bottom to top; you pick the next one from the stops your
path leads to (they pulse; hover one to see what it is). Your towers, gold and the fortress's damage
stay with you from stop to stop.
- **Battle** (crossed swords): 2 waves, then **choose 1 of 3 upgrades**.
- **Elite** (horned red skull): a harder fight led by a mini-boss, with a twist (faster, warded,
  swarming, more Cultists or Brutes). Reward: **a choice of 1 of 3 relics** (below).
- **Event** (scroll) and **Shrine** (green flame): a short scene; each answer says what it does.
- **Merchant** (coin purse): buy upgrade cards, a repair, new cards, and sometimes a relic (dear). The
  row before the boss is all merchants.
- **Boss** (crowned skull): the chapter's last fight. Beating chapter 1's boss gives a relic choice.

**Relics** are rarer than upgrades and change a rule of the run (some with a price: cheaper towers that
can never evolve, stronger towers but a weaker fortress, ...). One of each per run; they keep working
in chapter 2 and sit in their own row under your upgrades (hover one to read it). A rare event can
also give one.

**Between the chapters** your towers are packed up for **40%** of what they cost (you rebuild on a fresh
field with less than you had), gold, upgrades, relics and lives come with you, and the fortress is
repaired by half. **Chapter 2 is the Drowned Marsh**: a bigger flooded map with its own roads (two of
them merge before the fortress), only 7 tower spots, and pools you can wade through (slowly). It is
much harder, with its own dead (below), and its boss, the Tollkeeper, silences the towers around it
when it rings its bell.

| Action | Default |
|---|---|
| Move | WASD / arrow keys |
| Sword attack (aimed at the mouse) | Left mouse (hold to keep swinging) |
| Dash (short, through enemies, immune while dashing) | Space / Shift |
| Build / upgrade / sell a tower (stand at a stone pad) | E |
| Start the next wave | Enter, or the button top-left |
| Call the next wave early (bonus gold) | Enter / the same button, once a wave has sent all its dead |
| Pause menu (settings, abandon run, quit) | Esc |

Every key can be changed in **Esc → Settings** (also fullscreen and volume).

- **Before each wave** you build towers (you can also build during a wave). Upgrades come after a
  battle, not after every wave.
- **Gold** comes from kills. Towers can be upgraded twice; selling refunds half.
- **New in this build (polish):** sound effects for everything (retro, made for the game; set their
  volume in Esc → Settings → Sound volume), a short freeze and a screen shake on big hits (Settings →
  **Screen shake**: Full, Reduced or Off), **damage numbers** over enemies (Settings → Damage
  numbers), your sword now **knocks enemies back** a little (bosses don't budge), and every enemy's
  **role has a colour**: its eyes, health bar and its name in the messages (red: the common dead,
  yellow: fast, blue: tough, green: ranged, teal: healers, magenta: bursts when killed, violet: bosses).
- **Pair bonuses:** each tower type has a partner: build them close together
  (neighbouring stone pads) and both can get a bonus (Cannon + Frost: wider blasts and longer slows;
  Archer + Brazier: fire arrows; Ballista + Archer: faster bolts; Brazier + Cannon: hotter fire). The
  tower menu says which bonus a tower has, an ember marks it, and dashed lines show its partners
  (also when you preview a tower on an empty pad).
- **Calling a wave early:** once a wave has sent all its dead, the wave button reads "Next wave now
  +N": the next wave comes at once, with the survivors still on the field, and you get N gold now
  (half their kill gold; more the more are still alive), but no perfect-defense bonus for that wave.
- **Evolutions:** a level-3 tower can evolve once, into one of two forms (the tower menu shows both
  side by side with their range). The choice is for good, and it's expensive: you won't afford many.
- **Gold is tight:** you can't upgrade everything. Between waves the **Quartermaster** (panel under the
  wave panel) repairs the fortress (each repair costs more) and can buy back one lost life per chapter.
- **You have 3 lives.** A fallen hero returns at the fortress after 4 s; you heal fully after each wave.
- **Enemies:** Ghouls (basic), Hounds (fast packs), Brutes (slow, tough), **Cultists** (pale robed
  casters with green fire: they stop before the fortress and shoot it, or you if you come close; fragile,
  hunt them down). Their shots fly straight, so step aside or dash through them.
- **Chapter 2's dead** (a banner tells you what each does the first time it comes):
  **Bloaters** (swollen, glowing: they burst into 3 fast Bloatlings when killed, so kill them early),
  **Mire Priests** (ochre robes and a green censer: a green ring grows around them, then they heal
  everyone inside; kill them first), **Shieldbearers** (a big shield toward where they walk: tower
  shots from the front are blocked; hit them from the side or behind, with blasts or your sword).
- **Bosses and mini-bosses** each have one trick, always announced on the ground first: green rings
  (the Gravelord raises the dead), a red arrow (the Bone Colossus charges, then stands dazed), a blue
  circle (the Lich Warden shields the enemies around it), a bronze ring (the Tollkeeper silences your
  towers inside it for a few seconds).

## Sending feedback from inside the game (F8)

Press **F8** at any moment (you can change the key in Esc → Settings): the game pauses and a small box
asks for a note. Type what happened or what you think and press **Save**. The game saves a folder with
your note, a **screenshot** and the **state of your run** (where you are, your towers, upgrades, gold,
and the run's seed, so we can replay it). Use it as often as you like: right after a bug, an unfair
moment or anything confusing is best.

To send them: the box shows where it saved (and has an **Open the folder** button). All reports are in
the game's data folder (see "Where files are" below), in `feedback/`, one folder per report. **Zip the
whole `feedback` folder and send it to us** with your written answers.

Each run has a **seed** (shown in the pause menu and on the Game Over / Victory screen). If something
happens that you want us to see, note the seed: the pause menu can also start a new run from a seed.

## What feedback we want

Play at least one full run (win or lose), more if you can. Then tell us:

0. **The heroes (new):** Did the Huntress and the Necromancer feel different from the Knight and from each
   other, or just weaker/stronger? Was the crossbow fun to aim; did the Mark matter? Did the skeletons
   feel like an army or like clutter; did enemies fighting them make sense? Which of their towers did you
   build, and which felt useless or confusing (the Watchtower, snares, the Ossuary's souls)? Was the art
   readable?
0. **Combos and archetypes (new):** Did you get a combo relic, and was the third evolution worth building
   toward? Did your offers feel steered toward a plan, too much, or not at all? Did the "build" label help?
0. **Polish:** Were the sounds pleasant or tiring after an hour? Any too loud, too quiet, or
   missing? Did the screen shake and hit freeze feel good, or get in the way (did you turn shake
   down)? Were the damage numbers useful or clutter? Did the role colours help you tell enemies
   apart? What do you think of the title screen?
0. **Progression:** Did earning Soul Shards after a lost run make you want to start another?
   Which unlocks did you buy first, and why? Did your first run (3 towers, no evolutions) feel too
   bare? Were the title, War Room and run summary clear? Did Continue bring you back where you left?
   Were the tips helpful or in the way? Did you call waves early, and was the bonus worth the risk?
   Did the pair bonuses change where you built? Could you tell which towers were paired?
1. **The run:** Did you win? If not, which chapter and stop, and how (fortress or hero)? How long did
   it take? Which towers and upgrades did you go for?
2. **The map:** Did choosing your path feel meaningful? Which stops did you seek out or avoid, and
   why? Were the events and shrines worth stopping for? Were **elites worth the risk** now? Did the
   move to chapter 2 feel fair (40% of your towers back)?
3. **Chapter 2:** Did the Drowned Marsh ask for a different plan than chapter 1? Was it clearly harder
   but fair? Could you read the Bloater, the Mire Priest and the Shieldbearer, and deal with them?
4. **Relics:** Which did you take, and did they change how you played? Any relic that felt useless,
   too strong, or confusing?
5. **Difficulty curve:** Which waves felt too easy, too hard, or unfair? Was there a moment you felt
   you could not have done anything?
6. **Readability:** Could you always tell what was happening? Did you notice the Cultists and their
   shots in time? Did you understand each boss's warning before it hit you?
7. **The hero:** How does the dash feel (distance, cooldown, timing)? Did fighting feel worth it
   compared with just building towers?
8. **Choices:** Did the upgrade choices feel meaningful? Any upgrade that felt useless or must-pick?
   Which evolutions did you take, and why? Did one of a pair always feel like the obvious pick?
   Could you tell what the Shatter Shrine and the Beacon Flame were doing?
   How did gold feel: always short, or did it pile up? Did you use the Quartermaster (repairs, a
   bought-back life), and was it worth the price?
9. **The best and the worst moment** of your run, in one sentence each.
10. **Bugs:** what happened, what you expected, and the steps to make it happen again if you know
   them. A screenshot helps.
11. **Performance:** any stutter or slowdown? (Your PC, and when it happened.)

Short notes are fine: honest first impressions are the most useful thing you can give us.

## Where files are

Settings and logs live in the game's data folder:

- **Windows:** `%APPDATA%\Godot\app_userdata\The Last Stand\`
- **Linux:** `~/.local/share/godot/app_userdata/The Last Stand/`

`settings.cfg` holds your settings (delete it to reset them); `save.json` your progress (shards,
unlocks, records, the saved run; `save.json.bak` is the previous save; the War Room's Reset progress
starts over); `logs/godot.log` is the log of the
last session. Please attach it to a bug report. `feedback/` holds your F8 reports.
