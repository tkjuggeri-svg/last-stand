#!/usr/bin/env python3
"""Dev tool (not shipped): exports the knight (hero) sprites as PNGs into exports/knight/ (git-ignored).

  knight_idle.png       idle facing down, frame 0, 8x nearest-neighbour, transparent
  knight_idle_dark.png  the same on the game's grass colour (#24331a)
  knight_sheet.png      every animation in every direction (left = side mirrored, as in game), one row
                        each, 4x, labels, a 1-art-pixel grid line between frames
  knight_native.png     the same sheet at 1x (labels and 1 px grid lines), for a pixel art tool
  knight_comparison.png the concept (docs/reference/knight_concept.png) beside the idle frame at 8x, and the
                        knight in a game screenshot (pass one: --screenshot=<png> [--at=x,y], the knight's
                        position in it)
Run from the project folder: python3 tools/art/export_knight.py
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps

SHEET = Path("assets/sprites/hero/hero.png")
OUT = Path("exports/knight")
FRAME = (32, 40)  # sheet_layouts.HERO["size"]
# [name, row in hero.png, frames, mirrored]
ROWS = [("idle_down", 0, 4, False), ("idle_up", 1, 4, False), ("idle_side", 2, 4, False), ("idle_left", 2, 4, True),
        ("walk_down", 3, 6, False), ("walk_up", 4, 6, False), ("walk_side", 5, 6, False), ("walk_left", 5, 6, True),
        ("attack_down", 6, 4, False), ("attack_up", 7, 4, False), ("attack_side", 8, 4, False), ("attack_left", 8, 4, True),
        ("death", 9, 6, False),
        ("dash_down", 10, 3, False), ("dash_up", 11, 3, False), ("dash_side", 12, 3, False), ("dash_left", 12, 3, True)]
GROUND = (0x24, 0x33, 0x1a, 255)
GRID = (255, 0, 255, 255)
LABEL_W = 80  # label column, in art px at 1x


def frame(sheet, row, col, mirrored):
    w, h = FRAME
    f = sheet.crop((col * w, row * h, (col + 1) * w, (row + 1) * h))
    return ImageOps.mirror(f) if mirrored else f


def build_sheet(sheet):
    cols = max(r[2] for r in ROWS)
    w, h = FRAME
    img = Image.new("RGBA", (LABEL_W + cols * (w + 1) + 1, len(ROWS) * (h + 1) + 1), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for r, (name, row, count, mirrored) in enumerate(ROWS):
        y = r * (h + 1) + 1
        d.text((2, y + h // 2 - 5), name, fill=(230, 230, 230, 255))
        for c in range(count):
            img.alpha_composite(frame(sheet, row, c, mirrored), (LABEL_W + c * (w + 1) + 1, y))
    for c in range(cols + 1):
        d.line([(LABEL_W + c * (w + 1), 0), (LABEL_W + c * (w + 1), img.height - 1)], fill=GRID)
    for r in range(len(ROWS) + 1):
        d.line([(LABEL_W, r * (h + 1)), (img.width - 1, r * (h + 1))], fill=GRID)
    return img


def bbox_info(img):
    solid = img.getchannel("A").point(lambda a: 255 if a == 255 else 0).getbbox()
    any_px = img.getchannel("A").getbbox()
    return solid, any_px


CONCEPT = Path("docs/reference/knight_concept.png")


def comparison(idle_big, screenshot, at):
    """The concept and the 8x sprite side by side (same height), the game screenshot below, labelled."""
    concept = Image.open(CONCEPT).convert("RGBA")
    box = concept.getbbox()
    # Crop the concept to its knight (the background is flat): everything away from the corner colour.
    bg = concept.getpixel((5, 5))
    mask = Image.eval(concept.convert("L"), lambda v: 0)
    px = concept.load()
    xs, ys = [], []
    for y in range(0, concept.height, 2):
        for x in range(0, concept.width, 2):
            if sum(abs(a - b) for a, b in zip(px[x, y][:3], bg[:3])) > 40:
                xs.append(x); ys.append(y)
    knight = concept.crop((min(xs) - 20, min(ys) - 20, max(xs) + 20, max(ys) + 20))
    scale = idle_big.height / knight.height
    knight = knight.resize((round(knight.width * scale), idle_big.height), Image.LANCZOS)
    on_bg = Image.new("RGBA", idle_big.size, bg)
    on_bg.alpha_composite(idle_big)
    shot = None
    if screenshot:
        full = Image.open(screenshot).convert("RGBA")
        cx, cy = at
        shot = full.crop((cx - 220, cy - 140, cx + 220, cy + 140)).resize((880, 560), Image.NEAREST)
    pad = 24
    width = max(knight.width + on_bg.width + pad * 3, (shot.width + pad * 2) if shot else 0)
    height = pad * 2 + 28 + on_bg.height + ((shot.height + 28 + pad) if shot else 0)
    out = Image.new("RGBA", (width, height), (16, 14, 20, 255))
    d = ImageDraw.Draw(out)
    d.text((pad, pad), "concept", fill=(230, 230, 230, 255))
    d.text((pad * 2 + knight.width, pad), "new sprite, idle facing down, 8x (32x40 art px frame)", fill=(230, 230, 230, 255))
    out.alpha_composite(knight, (pad, pad + 28))
    out.alpha_composite(on_bg, (pad * 2 + knight.width, pad + 28))
    if shot:
        y = pad + 28 + on_bg.height + pad
        d.text((pad, y), "in game (1280x720 screenshot, 2x crop)", fill=(230, 230, 230, 255))
        out.alpha_composite(shot, (pad, y + 28))
    out.save(OUT / "knight_comparison.png")


def main():
    import sys
    screenshot, at = None, (640, 360)
    for arg in sys.argv[1:]:
        if arg.startswith("--screenshot="):
            screenshot = arg.split("=", 1)[1]
        elif arg.startswith("--at="):
            at = tuple(int(v) for v in arg.split("=", 1)[1].split(","))
    OUT.mkdir(parents=True, exist_ok=True)
    sheet = Image.open(SHEET).convert("RGBA")
    idle = frame(sheet, 0, 0, False)
    big = idle.resize((idle.width * 8, idle.height * 8), Image.NEAREST)
    big.save(OUT / "knight_idle.png")
    dark = Image.new("RGBA", big.size, GROUND)
    dark.alpha_composite(big)
    dark.save(OUT / "knight_idle_dark.png")
    native = build_sheet(sheet)
    native.save(OUT / "knight_native.png")
    native.resize((native.width * 4, native.height * 4), Image.NEAREST).save(OUT / "knight_sheet.png")
    if CONCEPT.exists():
        comparison(big, screenshot, at)
    solid, any_px = bbox_info(idle)
    print("frame", FRAME, "art px")
    print("idle_down frame 0: body (opaque) bbox", solid, "size", (solid[2] - solid[0], solid[3] - solid[1]))
    print("with the soft shadow", any_px, "size", (any_px[2] - any_px[0], any_px[3] - any_px[1]))
    for p in sorted(OUT.glob("*.png")):
        print(p, Image.open(p).size)


if __name__ == "__main__":
    main()
