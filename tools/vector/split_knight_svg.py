#!/usr/bin/env python3
"""Dev tool (not shipped, vector-test): splits docs/reference/knight_vector.svg into one SVG per body part.

Usage: python3 tools/vector/split_knight_svg.py [<in.svg> [<out_dir>]]

Every part keeps the source's 256x256 viewBox, its <defs> (the gradients) and the outer <g> style, so a part drawn at the
source's origin lands exactly where it was in the whole picture: the rig only has to place each texture by the same offset.
The parts are the source's top-level elements, in drawing order, grouped as PARTS says.
"""
import copy
import os
import sys
import xml.etree.ElementTree as ET

SVG = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG)

# part name -> indices of the source's top-level elements inside the outer group (drawing order):
#  0 ground shadow | 1,2 boots | 3,4 mail legs | 5 torso plate | 6 tabard | 7 tabard fold | 8 belt | 9,10 buckle
#  11 sword arm | 12 gauntlet | 13 sword | 14,15 left pauldron | 16,17 gorget | 18-20 right pauldron | 21-23 shield
#  24,25 plume | 26-31 great helm (ridge, visor, eye slit, holes, highlight)
PARTS = {
    "shadow": [0],
    "leg_l": [1, 3],
    "leg_r": [2, 4],
    "torso": [5, 6, 7, 8, 9, 10],
    "gorget": [16, 17],
    "arm_sword": [11, 12],
    "pauldron_l": [14, 15],
    "sword": [13],
    "pauldron_r": [18, 19, 20],
    "shield": [21, 22, 23],
    "helm": [24, 25, 26, 27, 28, 29, 30, 31],
}


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else "docs/reference/knight_vector.svg"
    out = sys.argv[2] if len(sys.argv) > 2 else "assets/sprites/hero_vector"
    os.makedirs(out, exist_ok=True)
    root = ET.parse(src).getroot()
    defs = root.find("{%s}defs" % SVG)
    group = [e for e in root if e.tag == "{%s}g" % SVG][0]
    elements = list(group)
    used = sorted(i for idx in PARTS.values() for i in idx)
    assert used == list(range(len(elements))), "every element must belong to exactly one part (%d elements)" % len(elements)
    for name, idx in PARTS.items():
        svg = ET.Element("{%s}svg" % SVG, dict(root.attrib))
        svg.append(copy.deepcopy(defs))
        g = ET.SubElement(svg, "{%s}g" % SVG, dict(group.attrib))
        for i in idx:
            g.append(copy.deepcopy(elements[i]))
        ET.ElementTree(svg).write(os.path.join(out, name + ".svg"), xml_declaration=False, encoding="unicode")
        print("part", name, idx)


main()
