#!/usr/bin/env python3
"""Dev tool (not shipped): comparison sheets of the current knight against a Pixellab one (M15 test).

Usage: python3 tools/art/pixellab/make_comparison.py <out_dir>   (reads <out_dir>/raw and <out_dir>/clean)
Writes <out_dir>/comparison_8x.png (current vs Pixellab cleaned to the game palette, idle, three directions),
raw_vs_clean_8x.png (Pixellab as delivered vs cleaned) and animations_4x.png (idle, walk and attack strips).
"""
import sys

from PIL import Image, ImageDraw

OUT = sys.argv[1]
SHEET = Image.open("assets/sprites/hero/hero.png").convert("RGBA")
FW, FH = 64, 80
BG = (35, 44, 39, 255)
# the current sheet's rows: (animation, row) per direction; "side" faces right like Pixellab's east
CUR = {"south": ("down", 0), "east": ("side", 2), "north": ("up", 1)}
ROWS = {"idle": {"down": 0, "up": 1, "side": 2}, "walk": {"down": 3, "up": 4, "side": 5}, "attack": {"down": 6, "up": 7, "side": 8}}
COUNTS = {"idle": (4, 4), "walk": (6, 6), "attack": (4, 4)}  # current frames, Pixellab frames
DIRS = {"south": "down", "east": "side", "north": "up"}


def current(anim, direction, i):
    row = ROWS[anim][DIRS[direction]]
    return SHEET.crop((i * FW, row * FH, (i + 1) * FW, (row + 1) * FH))


def pix(kind, anim, direction, i):
    return Image.open("%s/%s/%s_%s_%d.png" % (OUT, kind, anim, direction, i)).convert("RGBA")


def cell(img, scale, size):
    """The image on the common baseline: its content's bottom 4 px above the cell's bottom, centred on its content."""
    bb = img.getbbox() or (0, 0, 1, 1)
    c = Image.new("RGBA", size, BG)
    big = img.crop(bb).resize(((bb[2] - bb[0]) * scale, (bb[3] - bb[1]) * scale), Image.NEAREST)
    c.alpha_composite(big, ((size[0] - big.width) // 2, size[1] - big.height - 4 * scale))
    return c


def label(draw, xy, text):
    draw.text(xy, text, fill=(230, 220, 190, 255))


def sheet(columns, rows, title_cols, scale, cell_size, name, cols_fn):
    w, h = cell_size
    out = Image.new("RGBA", (len(columns) * w, 24 + len(rows) * h), BG)
    d = ImageDraw.Draw(out)
    for ci, t in enumerate(title_cols):
        label(d, (ci * w + 8, 6), t)
    for ri, r in enumerate(rows):
        for ci in range(len(columns)):
            out.alpha_composite(cell(cols_fn(ci, r), scale, cell_size), (ci * w, 24 + ri * h))
    out.save("%s/%s" % (OUT, name))


def heights():
    for d in ("south", "east", "north"):
        c, p = current("idle", d, 0).getbbox(), pix("clean", "idle", d, 0).getbbox()
        print("%s: current %dx%d (with its shadow), Pixellab %dx%d" % (d, c[2] - c[0], c[3] - c[1], p[2] - p[0], p[3] - p[1]))


def main():
    heights()
    dirs = ["south", "east", "north"]
    sheet(["cur", "pix"], dirs, ["current knight", "Pixellab (game palette)"], 8, (64 * 8, 72 * 8), "comparison_8x.png",
          lambda ci, d: current("idle", d, 0) if ci == 0 else pix("clean", "idle", d, 0))
    sheet(["raw", "clean"], dirs, ["Pixellab as delivered", "cleaned to the game palette"], 8, (64 * 8, 72 * 8), "raw_vs_clean_8x.png",
          lambda ci, d: pix("raw" if ci == 0 else "clean", "idle", d, 0))
    # animation strips: one row per animation and direction, current frames then Pixellab frames
    strips = [(a, d) for a in ("idle", "walk", "attack") for d in dirs]
    frame = (80, 160)
    maxn = 12
    out = Image.new("RGBA", (maxn * frame[0] * 4 // 2 + 120, 24 + len(strips) * frame[1] * 2 // 1), BG)
    out = Image.new("RGBA", (12 * frame[0] * 2 + 140, 20 + len(strips) * frame[1] * 2), BG)
    d = ImageDraw.Draw(out)
    for ri, (a, dr) in enumerate(strips):
        y = 20 + ri * frame[1] * 2
        label(d, (4, y + 4), "%s %s" % (a, dr))
        label(d, (4, y + 20), "top: current")
        label(d, (4, y + frame[1] + 20), "bottom: Pixellab")
        for i in range(COUNTS[a][0]):
            out.alpha_composite(cell(current(a, dr, i), 2, (frame[0] * 2, frame[1])), (140 + i * frame[0] * 2, y))
        for i in range(COUNTS[a][1]):
            out.alpha_composite(cell(pix("clean", a, dr, i), 2, (frame[0] * 2, frame[1])), (140 + i * frame[0] * 2, y + frame[1]))
    out.save("%s/animations_2x.png" % OUT)


main()
