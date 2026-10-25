# Art backlog (for an artist)

What the code-drawn art could not do well, or did not get to. Each item names the sheet layout to follow
(`docs/ART_SPEC.md`, regenerate with `python3 tools/art/art_spec.py`). A hand-drawn sheet is taken out of
`tools/art/generate_art.gd`'s jobs (see CLAUDE.md, Pixel art).

## Needs hand art

| Item | Why | Notes |
|---|---|---|
| **Boss side views** | the bosses (Gravelord, Colossus, Lich Warden, Tollkeeper, the six biome bosses, the Fallen Marshal) are drawn front and back only | follow the `DirectionalSprite` `<state>_<facing>` rule; side art faces right and is mirrored |
| **Biome enemies** | the 18 biome enemies and bosses of M10 are palette recolours of the base sheets (`tools/art/variant_art.gd`) | each deserves its own silhouette: Cinder Ghoul (burning), Frost Wraith (trailing mist), Burrower (a mound), Lamp Wight (the lantern), Hollow Treant (a trunk), Chorister (a robe) |
| **Boss portraits** | the Chronicle shows text only for the foes | 96x96 busts in the style of `tools/art/portrait_art.gd` (the heroes and the three War Room people exist) |
| **Hero portraits, second pass** | the six busts of M11 are first-pass shapes | the same sheet (`assets/sprites/ui/portraits.png`, 6 x 96 px), same order |
| **The M9 towers** | Trap Layer, Hawk Perch, Watchtower, Bone Pit, Soul Siphon and Ossuary are first-pass and smaller than the Archer | the Archer's footprint; keep the build, sell and fire frames |
| **Rubble** | Fewer Slots (Pressure, M12) only darkens the pad | a 2-frame rubble sprite on the pad (locked and cleared) |
| **Ice and ember hazards** | frozen patches and ember pools are shapes | the Blizzard and DryGrass hazards, `levels/hazards/` |
| **Ending illustrations** | the endings are text on a panel | four 640x360 scenes (the Marshal at rest, the Deep quiet, the last toll, the first dawn) |

## Could be better with a day of work

- More prop variety per biome (12 instead of 8): `tools/art/biome_props_art.gd`.
- The Hasty Waves countdown could have a small hourglass icon next to the Start button.
- A grayscale-readability pass on the new biome grounds (`test_readability` passes, but only on the base ground).
