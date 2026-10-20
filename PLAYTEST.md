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
  swarming, more Cultists or Brutes). Reward: a choice of 2 rare upgrades and 100 gold.
- **Event** (scroll) and **Shrine** (green flame): a short scene; each answer says what it does.
- **Merchant** (coin purse): buy upgrade cards, a repair, new cards. The row before the boss is all
  merchants.
- **Boss** (crowned skull): the chapter's last fight.

**Between the chapters** your towers are packed up for everything they cost (you rebuild on a fresh
field), gold, upgrades and lives come with you, and the fortress is repaired by half. Chapter 2 is
much harder, and its boss, the Tollkeeper, silences the towers around it when it rings its bell.

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
- **Bosses and mini-bosses** each have one trick, always announced on the ground first: green rings
  (the Gravelord raises the dead), a red arrow (the Bone Colossus charges, then stands dazed), a blue
  circle (the Lich Warden shields the enemies around it), a bronze ring (the Tollkeeper silences your
  towers inside it for a few seconds).

## What feedback we want

Play at least one full run (win or lose), more if you can. Then tell us:

1. **The run:** Did you win? If not, which chapter and stop, and how (fortress or hero)? How long did
   it take? Which towers and upgrades did you go for?
2. **The map:** Did choosing your path feel meaningful? Which stops did you seek out or avoid, and
   why? Were the events and shrines worth stopping for? Did the move to chapter 2 feel fair?
3. **Difficulty curve:** Which waves felt too easy, too hard, or unfair? Was there a moment you felt
   you could not have done anything?
4. **Readability:** Could you always tell what was happening? Did you notice the Cultists and their
   shots in time? Did you understand each boss's warning before it hit you?
5. **The hero:** How does the dash feel (distance, cooldown, timing)? Did fighting feel worth it
   compared with just building towers?
6. **Choices:** Did the upgrade choices feel meaningful? Any upgrade that felt useless or must-pick?
   Which evolutions did you take, and why? Did one of a pair always feel like the obvious pick?
   Could you tell what the Shatter Shrine and the Beacon Flame were doing?
   How did gold feel: always short, or did it pile up? Did you use the Quartermaster (repairs, a
   bought-back life), and was it worth the price?
7. **The best and the worst moment** of your run, in one sentence each.
8. **Bugs:** what happened, what you expected, and the steps to make it happen again if you know
   them. A screenshot helps.
9. **Performance:** any stutter or slowdown? (Your PC, and when it happened.)

Short notes are fine: honest first impressions are the most useful thing you can give us.

## Where files are

Settings and logs live in the game's data folder:

- **Windows:** `%APPDATA%\Godot\app_userdata\The Last Stand\`
- **Linux:** `~/.local/share/godot/app_userdata/The Last Stand/`

`settings.cfg` holds your settings (delete it to reset them); `logs/godot.log` is the log of the
last session. Please attach it to a bug report.
