#!/usr/bin/env python3
"""Converts a level scene to its vector art (M15 P4, docs/M15_P4_MAPS.md). Dev only; run it once per level:
    python3 tools/art/vector/convert_level.py ember_orchard [bone_quarry ...]
The vector sheets are twice the world resolution, so the sprites that show them are drawn at half size with linear
filtering and their offsets double: the ground (TiledGround, tile 256), the gates (or chapels), the props. Lights and
particles that are children of a halved sprite get twice the size and position, so they stay as they were. Running it on a
level that is already converted does nothing."""
import re
import sys

ROOT = __file__.rsplit("/tools/", 1)[0]


def convert(level_id: str) -> None:
    path = f"{ROOT}/levels/{level_id}.tscn"
    text = open(path).read()
    if "tile_size = Vector2i(256, 256)" in text:
        print(level_id, "already converted")
        return
    # Which ext_resource ids are the sheets that change.
    ids = {}
    for m in re.finditer(r'\[ext_resource type="Texture2D" path="res://assets/sprites/environment/([a-z_]+)\.png" id="([^"]+)"\]', text):
        ids[m.group(1)] = m.group(2)
    changing = {i for name, i in ids.items() if name.endswith("_gate") or name.endswith("_props") or name in ("drowned_chapel", "props")}
    if "props" in ids:
        # the marsh's shared graveyard props (the lanterns' neighbours) use the vector graveyard sheet, same 12 frames
        text = text.replace("environment/props.png", "environment/graveyard_props.png", 1)
    ground_id = ids.get(f"{level_id}_ground")
    parts = re.split(r'(?m)^(?=\[node )', text)
    out = [parts[0]]
    halved = set()  # names of the sprite nodes that are now drawn at half size
    for blk in parts[1:]:
        head = blk.split("\n", 1)[0]
        name = re.search(r'name="([^"]+)"', head).group(1)
        parent = re.search(r'parent="([^"]*)"', head)
        parent = parent.group(1) if parent else ""
        tex = re.search(r'texture = ExtResource\("([^"]+)"\)', blk)
        tex_id = tex.group(1) if tex else None
        if 'type="Sprite2D"' in head and tex_id in changing and "scale = Vector2(1, 1)" in blk:
            blk = blk.replace("scale = Vector2(1, 1)", "texture_filter = 2\nscale = Vector2(0.5, 0.5)", 1)
            off = re.search(r"offset = Vector2\(([-\d.]+), ([-\d.]+)\)", blk)
            if off:
                blk = blk.replace(off.group(0), "offset = Vector2(%g, %g)" % (float(off.group(1)) * 2, float(off.group(2)) * 2), 1)
            halved.add(parent + "/" + name if parent not in ("", ".") else name)
        elif parent in halved or parent.split("/")[-1] in {h.split("/")[-1] for h in halved} and parent in halved:
            pos = re.search(r"position = Vector2\(([-\d.]+), ([-\d.]+)\)", blk)
            if pos:
                blk = blk.replace(pos.group(0), "position = Vector2(%g, %g)" % (float(pos.group(1)) * 2, float(pos.group(2)) * 2), 1)
            if "scale = Vector2(1, 1)" in blk:
                blk = blk.replace("scale = Vector2(1, 1)", "scale = Vector2(2, 2)", 1)
            else:
                blk = blk.rstrip("\n") + "\nscale = Vector2(2, 2)\n\n"
        elif name == "Ground" and 'type="Node2D"' in head and ground_id and tex_id == ground_id:
            blk = blk.replace("tile_size = Vector2i(128, 128)", "tile_size = Vector2i(256, 256)", 1)
            blk = blk.replace("z_index = -1\n", "z_index = -1\ntexture_filter = 2\n", 1)
            blk = re.sub(r"(position = Vector2\([-\d.]+, [-\d.]+\)\n)", r"\1scale = Vector2(0.5, 0.5)\n", blk, count=1)
        out.append(blk)
    open(path, "w").write("".join(out))
    print(level_id, "converted:", len(halved), "sprites halved")


if __name__ == "__main__":
    for lid in sys.argv[1:]:
        convert(lid)
