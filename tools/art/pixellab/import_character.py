#!/usr/bin/env python3
"""Dev tool (not shipped): turns a Pixellab character export into a game sprite sheet (M15).

Usage: python3 tools/art/pixellab/import_character.py <spec.json>

The spec (see knight.json) names the unzipped Pixellab export, the game sheet's frame size and rows (the same
order as the layout in tools/art/sheet_layouts.gd), where each row comes from, and a "legacy" sheet that supplies
the rows Pixellab has not made yet. Steps: every frame goes onto the game's palette (clean_to_palette.snap_palette),
alpha snaps to 0 or 255, a soft oval ground shadow (alpha 86, as the code-drawn sheets) goes under the feet, and
the frame is placed so its feet sit on the same row in every cell. The raw export is never edited.
"""
import json
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from clean_to_palette import snap_palette  # noqa: E402

SHADOW_ALPHA = 86


def lowest_row(path):
    """The lowest opaque row of a frame: Pixellab's pivot differs per animation and facing, the feet do not."""
    return Image.open(path).convert("RGBA").getchannel("A").point(lambda a: 255 if a >= 128 else 0).getbbox()[3] - 1


def frame_cell(path, cell, feet_row, canvas_feet_row, palette_fn, shadow):
    """One Pixellab frame as one cell of the game sheet; canvas_feet_row is where its feet are in the Pixellab canvas."""
    src = Image.open(path).convert("RGBA")
    out = Image.new("RGBA", cell, (0, 0, 0, 0))
    dx = (cell[0] - src.width) // 2
    dy = feet_row - canvas_feet_row
    if shadow:
        sh = Image.new("L", cell, 0)
        cx, w, h = cell[0] // 2, shadow[0] // 2, shadow[1] // 2
        ImageDraw.Draw(sh).ellipse((cx - w, feet_row - h, cx + w, feet_row + h), fill=SHADOW_ALPHA)
        out.paste((0, 0, 0, 255), (0, 0), sh)
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, a = src.getpixel((x, y))
            if a >= 128:
                out.putpixel((x + dx, y + dy), palette_fn((r, g, b)) + (255,))
    return out


def main():
    with open(sys.argv[1]) as f:
        spec = json.load(f)
    cell = tuple(spec["cell"])
    legacy = Image.open(spec["legacy"]["png"]).convert("RGBA")
    lcell = tuple(spec["legacy"]["cell"])
    lfeet = spec["legacy"]["feet_row"]
    palette = sorted({p[:3] for p in legacy.getdata() if p[3] == 255})
    palette_fn = snap_palette(palette)
    meta = json.load(open(os.path.join(spec["export"], "metadata.json")))
    anims = meta["states"][0]["frames"]["animations"]
    rows = spec["rows"]
    sheet = Image.new("RGBA", (cell[0] * spec["columns"], cell[1] * len(rows)), (0, 0, 0, 0))
    made, kept = 0, 0
    for row, entry in enumerate(rows):
        for col in range(entry["frames"]):
            if "pixellab" in entry:
                name, direction = entry["pixellab"]
                path = os.path.join(spec["export"], anims[name][direction][col])
                first = os.path.join(spec["export"], anims[name][direction][0])
                img = frame_cell(path, cell, spec["feet_row"], lowest_row(first), palette_fn, spec["shadow"])
                made += 1
            else:
                lx, ly = entry["legacy_cell"][0] * lcell[0] + col * lcell[0], entry["legacy_cell"][1] * lcell[1]
                old = legacy.crop((lx, ly, lx + lcell[0], ly + lcell[1]))
                img = Image.new("RGBA", cell, (0, 0, 0, 0))
                img.paste(old, ((cell[0] - lcell[0]) // 2, spec["feet_row"] - lfeet))
                kept += 1
            sheet.paste(img, (col * cell[0], row * cell[1]))
    sheet.save(spec["out"])
    print("%s: %d frames from Pixellab, %d kept from the legacy sheet, sheet %s, palette %d colours" % (spec["out"], made, kept, sheet.size, len(palette)))


main()
