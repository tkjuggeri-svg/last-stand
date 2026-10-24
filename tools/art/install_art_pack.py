#!/usr/bin/env python3
"""Dev tool: installs a hand-drawn art pack (double-resolution world sprites, see docs/ART_HANDOFF.md).

  python3 -I tools/art/install_art_pack.py <pack folder> [--dry-run]

Copies the pack's sheets listed in its manifests/layouts-required.json (frame sizes must be exactly
double the game's layouts: checked), the spawn buildings and the title art; rebuilds the two prop
sheets in the GAME's frame order (the pack's order is only a proposal: PROP_MAP below maps them by
meaning; a prop the pack lacks is the game's own frame doubled with nearest-neighbour, a marked
stopgap). Never installs templates/, previews/ or the pack's map grounds (texture bases, not maps).
Run from the project folder; afterwards: godot --import, build_sprite_frames.gd, the test suite.
"""
import json
import shutil
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
# Game frame order (tools/art/environment_art.gd / marsh_art.gd PROPS) -> (pack sheet, pack frame), or
# ("stopgap", game frame) when the pack has nothing for it.
PROP_MAP = {
    "props": {
        "frame": (64, 96), "count": 12, "old_frame": (32, 48),
        "order": [("tomb_round", "props", 0), ("tomb_cross", "props", 1), ("tomb_tall", "props", 2),
                  ("grave_mound", "props", 6), ("dead_tree", "props", 3), ("dead_tree_small", "props", 11),
                  ("bush", "stopgap", 6), ("rocks", "props", 10), ("lantern", "props", 8),
                  ("broken_pillar", "props", 4), ("bones", "props", 7), ("fence", "props", 5)],
    },
    "marsh_props": {
        "frame": (64, 96), "count": 8, "old_frame": (32, 48),
        "order": [("reeds", "marsh_props", 0), ("cattails", "marsh_props", 0), ("willow", "marsh_props", 2),
                  ("stump", "props", 11), ("sunken_boat", "marsh_props", 5), ("marsh_lantern", "stopgap", 5),
                  ("drowned_tomb", "marsh_props", 6), ("mushrooms", "marsh_props", 7)],
    },
}
SINGLES = ["assets/sprites/environment/crypt.png", "assets/sprites/environment/drowned_chapel.png",
           "assets/sprites/ui/title_scene.png"]
NEVER = ("assets/sprites/environment/prototype_arena_ground.png", "assets/sprites/environment/drowned_marsh_ground.png",
         "assets/sprites/environment/props.png", "assets/sprites/environment/marsh_props.png")


def main() -> None:
    pack = Path(sys.argv[1]).resolve()
    dry = "--dry-run" in sys.argv
    sheets = json.loads((pack / "manifests/layouts-required.json").read_text())["sheets"]
    installed = []
    for sheet in sheets:
        path = sheet["path"]
        if path in NEVER:
            continue
        src = pack / path
        image = Image.open(src)
        assert list(image.size) == sheet["sheet"], f"{path}: {image.size} is not {sheet['sheet']}"
        if not dry:
            shutil.copyfile(src, ROOT / path)
        installed.append(path)
    for path in SINGLES:
        if not dry:
            shutil.copyfile(pack / path, ROOT / path)
        installed.append(path)
    for name, spec in PROP_MAP.items():
        fw, fh = spec["frame"]
        ow, oh = spec["old_frame"]
        old = Image.open(ROOT / f"assets/sprites/environment/{name}.png").convert("RGBA")
        sources = {n: Image.open(pack / f"assets/sprites/environment/{n}.png").convert("RGBA") for n in ("props", "marsh_props")}
        out = Image.new("RGBA", (fw * spec["count"], fh), (0, 0, 0, 0))
        for i, (prop, sheet, frame) in enumerate(spec["order"]):
            if sheet == "stopgap":
                tile = old.crop((frame * ow, 0, (frame + 1) * ow, oh)).resize((fw, fh), Image.NEAREST)
            else:
                tile = sources[sheet].crop((frame * fw, 0, (frame + 1) * fw, fh))
            out.paste(tile, (i * fw, 0))
            print(f"  {name}[{i}] {prop:16} <- {sheet}[{frame}]" + ("   (stopgap: the game's frame, doubled)" if sheet == "stopgap" else ""))
        if not dry:
            out.save(ROOT / f"assets/sprites/environment/{name}.png")
        installed.append(f"assets/sprites/environment/{name}.png (remapped)")
    print(f"{'would install' if dry else 'installed'} {len(installed)} files")


if __name__ == "__main__":
    main()
