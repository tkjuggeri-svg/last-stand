# LAST STAND — Internal Playtest

Thanks for playing! This is an early build: the pixel art is in, but there is **no sound yet** and no
main menu (the game starts straight in a run). One run is 15 waves and takes about 20–30 minutes.

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
fortress falls, or you lose your last life, the run is over. Survive all 15 waves to win.

| Action | Default |
|---|---|
| Move | WASD / arrow keys |
| Sword attack (aimed at the mouse) | Left mouse (hold to keep swinging) |
| Dash (short, through enemies, immune while dashing) | Space / Shift |
| Build / upgrade / sell a tower (stand at a stone pad) | E |
| Start the next wave | Enter, or the button top-left |
| Pause menu (settings, restart, quit) | Esc |

Every key can be changed in **Esc → Settings** (also fullscreen and volume).

- **Between waves** you build towers and choose **1 of 3 upgrades**. You can also build during a wave.
- **Gold** comes from kills. Towers can be upgraded twice; selling refunds half.
- **Evolutions:** a level-3 tower can evolve once, into one of two forms (the tower menu shows both
  side by side with their range). The choice is for good, and it's expensive: you won't afford many.
- **Gold is tight:** you can't upgrade everything. Between waves the **Quartermaster** (panel under the
  wave panel) repairs the fortress (each repair costs more) and can buy back one lost life per run.
- **You have 3 lives.** A fallen hero returns at the fortress after 4 s; you heal fully after each wave.
- **Enemies:** Ghouls (basic), Hounds (fast packs), Brutes (slow, tough), **Cultists** (pale robed
  casters with green fire: they stop before the fortress and shoot it, or you if you come close; fragile,
  hunt them down). Their shots fly straight, so step aside or dash through them.
- **Bosses** lead waves 5, 10 and 15. Each has one trick, always announced on the ground first:
  green rings (it raises the dead), a red arrow (it charges, then stands dazed), a blue circle (it
  shields the enemies around it).

## What feedback we want

Play at least one full run (win or lose), more if you can. Then tell us:

1. **The run:** Did you win? If not, which wave and how (fortress or hero)? How long did it take?
   Which towers and upgrades did you go for?
2. **Difficulty curve:** Which waves felt too easy, too hard, or unfair? Was there a moment you felt
   you could not have done anything?
3. **Readability:** Could you always tell what was happening? Did you notice the Cultists and their
   shots in time? Did you understand each boss's warning before it hit you?
4. **The hero:** How does the dash feel (distance, cooldown, timing)? Did fighting feel worth it
   compared with just building towers?
5. **Choices:** Did the upgrade choices feel meaningful? Any upgrade that felt useless or must-pick?
   Which evolutions did you take, and why? Did one of a pair always feel like the obvious pick?
   Could you tell what the Shatter Shrine and the Beacon Flame were doing?
   How did gold feel: always short, or did it pile up? Did you use the Quartermaster (repairs, a
   bought-back life), and was it worth the price?
6. **The best and the worst moment** of your run, in one sentence each.
7. **Bugs:** what happened, what you expected, and the steps to make it happen again if you know
   them. A screenshot helps.
8. **Performance:** any stutter or slowdown? (Your PC, and when it happened.)

Short notes are fine: honest first impressions are the most useful thing you can give us.

## Where files are

Settings and logs live in the game's data folder:

- **Windows:** `%APPDATA%\Godot\app_userdata\The Last Stand\`
- **Linux:** `~/.local/share/godot/app_userdata/The Last Stand/`

`settings.cfg` holds your settings (delete it to reset them); `logs/godot.log` is the log of the
last session. Please attach it to a bug report.
