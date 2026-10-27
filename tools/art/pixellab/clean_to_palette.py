#!/usr/bin/env python3
"""Dev tool (not shipped): snaps Pixellab frames onto the game's palette (M15 test).

Usage: python3 tools/art/pixellab/clean_to_palette.py <palette_sheet.png> <in_dir> <out_dir>

The palette is every fully opaque colour of <palette_sheet.png> (the current knight's sheet). Each pixel of every PNG in
<in_dir> goes to the nearest palette colour in CIE Lab, alpha snaps to 0 or 255, and nothing moves or resizes: the art
stays on its pixel grid. The raw Pixellab files stay untouched in <in_dir>.
"""
import math
import os
import sys

from PIL import Image


def lab(rgb):
    def lin(c):
        c /= 255.0
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(c) for c in rgb)
    x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
    y = 0.2126 * r + 0.7152 * g + 0.0722 * b
    z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883

    def f(t):
        return t ** (1 / 3) if t > 0.008856 else 7.787 * t + 16 / 116
    return (116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z)))


def main():
    sheet, src, dst = sys.argv[1:4]
    os.makedirs(dst, exist_ok=True)
    palette = sorted({p[:3] for p in Image.open(sheet).convert("RGBA").getdata() if p[3] == 255})
    labs = [lab(c) for c in palette]
    cache = {}

    def nearest(rgb):
        if rgb not in cache:
            l = lab(rgb)
            cache[rgb] = min(range(len(palette)), key=lambda i: math.dist(l, labs[i]))
        return palette[cache[rgb]]

    for name in sorted(os.listdir(src)):
        if not name.endswith(".png"):
            continue
        im = Image.open(os.path.join(src, name)).convert("RGBA")
        out = Image.new("RGBA", im.size, (0, 0, 0, 0))
        for y in range(im.height):
            for x in range(im.width):
                r, g, b, a = im.getpixel((x, y))
                if a >= 128:
                    out.putpixel((x, y), nearest((r, g, b)) + (255,))
        out.save(os.path.join(dst, name))
    print("palette of %d colours, %d files" % (len(palette), len(os.listdir(dst))))


main()
