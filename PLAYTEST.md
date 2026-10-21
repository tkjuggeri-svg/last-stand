# LAST STAND — Internal Playtest

Thanks for playing! This is an early build: the pixel art is in, but there is **no sound yet** and no
main menu (the game starts straight in a run). A run is **two chapters** on a map of choices (about
35–45 minutes if you win; the first chapter alone is about 15–20).

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
| Pause menu (settings, restart, quit) | Esc |

Every key can be changed in **Esc → Settings** (also fullscreen and volume).

- **Before each wave** you build towers (you can also build during a wave). Upgrades come after a
  battle, not after every wave.
- **Gold** comes from kills. Towers can be upgraded twice; selling refunds half.
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

`settings.cfg` holds your settings (delete it to reset them); `logs/godot.log` is the log of the
last session. Please attach it to a bug report. `feedback/` holds your F8 reports.
