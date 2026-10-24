# Asset Credits

Every third-party asset must be CC0 or self-made. Log each one here before committing it.

| Asset | Path | Author | Source URL | License |
|-------|------|--------|------------|---------|
| Godot icon (placeholder) | `res://icon.svg` | Godot Engine contributors | https://godotengine.org | CC BY 4.0 |
| World sprites at double resolution: towers and shots, effects (sword trails included), the fortress, props, crypt and chapel, the build slot pad, the title art | `res://assets/sprites/{towers,effects,fortress}/*.png`, `environment/{props,marsh_props,crypt,drowned_chapel}.png`, `ui/title_scene.png` | The LAST STAND art pack (custom art development, drawn with Python and Pillow with AI assistance; installed by `tools/art/install_art_pack.py`, see `docs/ART_HANDOFF.md`). Two prop frames (the bush, the marsh lantern) are the project's own art, doubled. The pack's characters were replaced by the project's code-drawn ones (below) at the same resolution. | — | Project-owned (supplied by the project owner) |
| The rest: the hero, enemies and bosses, map grounds, UI frames, icons, small effects (motes, smoke, the bone pickup) | `res://assets/sprites/**` (the others) | Original, made for LAST STAND (drawn in code by `tools/art/`) | — | Project-owned |
| Pixel font (glyphs designed for LAST STAND) | `res://assets/fonts/pixel_font.res`, `pixel_font_atlas.png` | Original, made for LAST STAND (`tools/art/ui_art.gd`) | — | Project-owned |
| Shaders (hit flash, ground fog) | `res://assets/shaders/*.gdshader` | Original, made for LAST STAND | — | Project-owned |
| Light gradient | `res://entities/effects/light_soft.tres` | Original (Godot GradientTexture2D) | — | Project-owned |
| All sound effects | `res://assets/audio/sfx/*.wav` | Original, made for LAST STAND (synthesized in code by `tools/audio/`) | — | Project-owned |

### Provenance note from the art pack (verbatim)

> Original pixel-art drawing routines, bitmap glyph designs, generated artwork and scene compositions
> created for this project with AI assistance. No third-party artwork, stock textures, external image
> assets or external fonts were incorporated in the shipped game-asset PNGs. [...] Drawing software:
> Python and Pillow. [...] This provenance note is intended to merge into existing project credits. It
> is not a legal opinion about copyright protection, and it does not assert that unspecified
> third-party project assets are licensed by this pack.
