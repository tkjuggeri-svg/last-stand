# Asset Credits

Every third-party asset must be CC0 or self-made. Log each one here before committing it.

| Asset | Path | Author | Source URL | License |
|-------|------|--------|------------|---------|
| Godot icon (placeholder) | `res://icon.svg` | Godot Engine contributors | https://godotengine.org | CC BY 4.0 |
| World sprites at double resolution: towers and shots, effects (sword trails included), the fortress, props, crypt and chapel, the build slot pad, the title art | `res://assets/sprites/{towers,effects,fortress}/*.png`, `environment/{props,marsh_props,crypt,drowned_chapel}.png`, `ui/title_scene.png` | The LAST STAND art pack (custom art development, drawn with Python and Pillow with AI assistance; installed by `tools/art/install_art_pack.py`, see `docs/ART_HANDOFF.md`). Two prop frames (the bush, the marsh lantern) are the project's own art, doubled. The pack's characters were replaced by the project's code-drawn ones (below) at the same resolution. | — | Project-owned (supplied by the project owner) |
| M15 art made with Pixellab (an AI pixel-art service; owner-approved exception to the code-drawn rule, 2026-10-27). Log each piece here when it is added: what, date, prompt | *(none yet)* | Generated with Pixellab for LAST STAND | https://www.pixellab.ai | Pixellab's terms for generated output, to be checked and noted here before the first piece ships |
| The rest: the hero, enemies and bosses, map grounds, UI frames, icons, small effects (motes, smoke, the bone pickup) | `res://assets/sprites/**` (the others) | Original, made for LAST STAND (drawn in code by `tools/art/`) | — | Project-owned |
| Pixel font (glyphs designed for LAST STAND) | `res://assets/fonts/pixel_font.res`, `pixel_font_atlas.png` | Original, made for LAST STAND (`tools/art/ui_art.gd`) | — | Project-owned |
| Shaders (hit flash, ground fog) | `res://assets/shaders/*.gdshader` | Original, made for LAST STAND | — | Project-owned |
| Light gradient | `res://entities/effects/light_soft.tres` | Original (Godot GradientTexture2D) | — | Project-owned |
| All music (12 looping tracks) | `res://assets/audio/music/*.wav` | Original, made for LAST STAND (synthesized in code by `tools/audio/music_recipes.gd` and `music_synth.gd`) | — | Project-owned |
| All sound effects | `res://assets/audio/sfx/*.wav` | Original, made for LAST STAND (synthesized in code by `tools/audio/`) | — | Project-owned |

### Provenance note from the art pack (verbatim)

> Original pixel-art drawing routines, bitmap glyph designs, generated artwork and scene compositions
> created for this project with AI assistance. No third-party artwork, stock textures, external image
> assets or external fonts were incorporated in the shipped game-asset PNGs. [...] Drawing software:
> Python and Pillow. [...] This provenance note is intended to merge into existing project credits. It
> is not a legal opinion about copyright protection, and it does not assert that unspecified
> third-party project assets are licensed by this pack.

## Pixellab (M15 art tool, owner's exception of 2026-10-27, CLAUDE.md rule 3)

**Stopped (owner, 2026-10-27): no further Pixellab use. Only the Knight below is kept; everything else stays code-drawn.**

Dev tool only (the `pixellab` MCP server); nothing generated is in the game or its exports until a piece is listed here as adopted.

| What | When | Prompt / input | Cost | Where it lives | In the game? |
|---|---|---|---|---|---|
| Knight test: 8 rotations, idle (breathing-idle template), walk (walking-6-frames template), attack (v3 custom, 4 frames) in south, east, north | 2026-10-27 | `create_character` mode pro, 64 px, low top-down, concept `docs/reference/knight_concept.png` (cropped to 512x512), description "chunky dark-fantasy knight: round steel great helm with a gold-trimmed horizontal visor slit and a red plume, gold-trimmed round pauldrons, red tabard with a torn hem and brown belt, brown boots, kite shield with a gold griffin crest, steel longsword"; attack: "swinging a sword in a wide slashing arc, the shield arm braced" | 10 + 9 generations (trial plan) | `exports/pixellab-test/` (git-ignored: `raw/` as delivered, `clean/` snapped to the game palette by `tools/art/pixellab/clean_to_palette.py`) | No: a comparison only |
| Knight v3: 8 rotations at 76 px, idle (breathing-idle template) and walk (walking-6-frames template) in south, east, north; attack, death and dash kept from the code-drawn sheet | 2026-10-27 | `create_character` mode v3, 76 px, low top-down, no concept image, description "chunky dark-fantasy knight: round steel great helm with a gold-trimmed horizontal visor slit and a red plume, gold-trimmed round pauldrons, red tabard with a torn hem and brown belt, brown boots, kite shield with a gold griffin crest, steel longsword" (an 88 px try of the same, 2 generations, was too big and discarded) | 10 generations (2 + 2 + 6; trial plan, 1 left) | `tools/art/pixellab/knight.json` + `import_character.py` write `assets/sprites/hero/hero.png` (palette-snapped, shadow added); raw export in `exports/pixellab-test/v3/full/` (git-ignored) | **Yes (adopted 2026-10-27, owner: "adopt anyway")**: `assets/sprites/hero/hero.png` = idle and walk from Pixellab, attack, death and dash from the code-drawn sheet (`tools/art/pixellab/legacy/`) |
