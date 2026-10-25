# Trailer: shot list

`tests/tools/trailer_capture.gd` plays the montage in the real game window and saves the frames and a
storyboard (`storyboard.txt`), so a trailer can be cut from them or recorded over the same beats:

    godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/tools/trailer_capture.gd -- --out=dev_screenshots/trailer

`--only=title,knight,huntress,necromancer,boss,ending` picks parts. About 30 seconds of video, in this order:

| # | Seconds | Shot | Music | Caption idea |
|---|---|---|---|---|
| 1 | 0-4 | the title over the fortress at night | `title` | "The night does not end." |
| 2 | 4-10 | the Knight's towers in the Crypt Road, three frames of a late wave | `fight_1` | "Build." |
| 3 | 10-16 | the Huntress in the Frostbound Pass | `fight_2` | "Hold." |
| 4 | 16-21 | the Necromancer in the Pale Cathedral | `fight_3` | "Command." |
| 5 | 21-26 | the Fallen Marshal's boss fight | `boss` | "Fall, and rise again." |
| 6 | 26-30 | an ending, then the logo | `finale` | "LAST STAND" |

A real recording (OBS, 1080p: the game renders at 2x and filters down) of the same beats beats the stills:
start a run from the dev menu (F12: jump to a chapter and wave, grant cards and relics) for each shot.
