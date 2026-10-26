#!/usr/bin/env python3
"""Adds build slots to a level (M13 follow-up: a playtest found every slot full and the gold unspent). Dev only.
  python3 tools/place_slots.py <level id> <total slots>      e.g. ashen_keep 14
For the seven spec levels (tools/levels/<id>.json) the spec's "slots" list grows and make_level.py is run;
for levels/prototype_arena.tscn and levels/drowned_marsh.tscn (hand made) the Slot nodes are appended.
Each new slot is chosen greedily where it covers the most lane stretches that few slots reach, 70-125 px from
a lane (a tower's reach is 160+), at least 80 px from every other slot, 130 px from the fortress, 70 px inside
the walls, clear of props and (marsh) water pools. Run it once per level; it only adds, never moves a slot."""
import json, math, os, re, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SPEC_LEVELS = ["ashen_keep", "bone_quarry", "ember_orchard", "frostbound_pass", "gloam_wood", "pale_cathedral", "sunless_mines"]
TSCN_LEVELS = {"prototype_arena": "levels/prototype_arena.tscn", "drowned_marsh": "levels/drowned_marsh.tscn"}
LANE_MIN, LANE_MAX = 70.0, 125.0
SLOT_GAP, FORTRESS_GAP, WALL_GAP, PROP_GAP, POOL_GAP = 80.0, 130.0, 70.0, 40.0, 40.0
REACH = 175.0
STRETCH = 25.0


def dist_segment(p, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    t = max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / max(dx * dx + dy * dy, 1e-9)))
    return math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dy)


def dist_polyline(p, line):
    return min(dist_segment(p, line[i], line[i + 1]) for i in range(len(line) - 1))


def samples(line):
    out = []
    for i in range(len(line) - 1):
        a, b = line[i], line[i + 1]
        length = math.hypot(b[0] - a[0], b[1] - a[1])
        n = max(int(length / STRETCH), 1)
        out += [(a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n) for k in range(n)]
    out.append(line[-1])
    return out


def in_polygon(p, poly):
    inside = False
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        if (a[1] > p[1]) != (b[1] > p[1]) and p[0] < (b[0] - a[0]) * (p[1] - a[1]) / (b[1] - a[1]) + a[0]:
            inside = not inside
    return inside


def load_spec(level):
    if level in SPEC_LEVELS:
        spec = json.load(open(os.path.join(ROOT, "tools/levels/%s.json" % level)))
        return spec["floor"], [[tuple(p) for p in lane] for lane in spec["lanes"]], [tuple(s) for s in spec["slots"]], [], []
    text = open(os.path.join(ROOT, TSCN_LEVELS[level])).read()
    left = float(re.search(r'node name="Floor".*?offset_left = (-?[\d.]+)', text, re.S).group(1))
    top = float(re.search(r'node name="Floor".*?offset_top = (-?[\d.]+)', text, re.S).group(1))
    right = float(re.search(r'node name="Floor".*?offset_right = (-?[\d.]+)', text, re.S).group(1))
    bottom = float(re.search(r'node name="Floor".*?offset_bottom = (-?[\d.]+)', text, re.S).group(1))
    lanes = []
    for m in re.finditer(r'\[sub_resource type="Curve2D" id="Curve2D_lane\d*"\]\n_data = \{\n"points": PackedVector2Array\(([^)]*)\)', text):
        nums = [float(v) for v in m.group(1).split(",")]
        lanes.append([(nums[i + 4], nums[i + 5]) for i in range(0, len(nums), 6)])
    slots = [(float(m.group(1)), float(m.group(2))) for m in re.finditer(r'\[node name="Slot\d+"[^\]]*\]\nposition = Vector2\(([-\d.]+), ([-\d.]+)\)', text)]
    props = [(float(m.group(1)), float(m.group(2))) for m in re.finditer(r'\[node name="[^"]+" type="(?:Sprite2D|PointLight2D)" parent="Props"[^\]]*\]\n(?:[^\n]*\n)*?position = Vector2\(([-\d.]+), ([-\d.]+)\)', text)]
    pools = []
    for m in re.finditer(r'\[node name="Pool\d+" type="CollisionPolygon2D" parent="Water"\]\npolygon = PackedVector2Array\(([^)]*)\)', text):
        nums = [float(v) for v in m.group(1).split(",")]
        pools.append([(nums[i], nums[i + 1]) for i in range(0, len(nums), 2)])
    return [left, top, right, bottom], lanes, slots, props, pools


def place(level, total):
    floor, lanes, slots, props, pools = load_spec(level)
    spots = [s for lane in lanes for s in samples(lane)]
    covered = [sum(1 for s in slots if math.hypot(s[0] - p[0], s[1] - p[1]) <= REACH) for p in spots]
    added = []
    while len(slots) + len(added) < total:
        best, best_score = None, -1.0
        for x in range(int(floor[0] + WALL_GAP), int(floor[2] - WALL_GAP) + 1, 10):
            for y in range(int(floor[1] + WALL_GAP), int(floor[3] - WALL_GAP) + 1, 10):
                p = (float(x), float(y))
                d = min(dist_polyline(p, lane) for lane in lanes)
                if d < LANE_MIN or d > LANE_MAX or math.hypot(*p) < FORTRESS_GAP:
                    continue
                if any(math.hypot(p[0] - s[0], p[1] - s[1]) < SLOT_GAP for s in slots + added):
                    continue
                if any(math.hypot(p[0] - q[0], p[1] - q[1]) < PROP_GAP for q in props):
                    continue
                if any(in_polygon(p, pool) or min(dist_segment(p, pool[i], pool[(i + 1) % len(pool)]) for i in range(len(pool))) < POOL_GAP for pool in pools):
                    continue
                score = sum(1.0 / (1 + covered[i]) for i, s in enumerate(spots) if math.hypot(s[0] - p[0], s[1] - p[1]) <= REACH)
                if score > best_score:
                    best, best_score = p, score
        if best is None:
            print("no room for slot", len(slots) + len(added) + 1, "in", level)
            break
        added.append(best)
        for i, s in enumerate(spots):
            if math.hypot(s[0] - best[0], s[1] - best[1]) <= REACH:
                covered[i] += 1
    return slots, added


def write(level, slots, added):
    if not added:
        return
    if level in SPEC_LEVELS:
        path = os.path.join(ROOT, "tools/levels/%s.json" % level)
        spec = json.load(open(path))
        spec["slots"] = [list(map(int, s)) for s in slots] + [[int(p[0]), int(p[1])] for p in added]
        open(path, "w").write(json.dumps(spec, indent=1))  # the specs are written this way: only the slots change
        os.system("cd %s && python3 tools/make_level.py %s" % (ROOT, level))
        return
    path = os.path.join(ROOT, TSCN_LEVELS[level])
    text = open(path).read()
    last = list(re.finditer(r'\[node name="Slot(\d+)"[^\]]*\]\nposition = Vector2\([^)]*\)\n', text))[-1]
    number = int(last.group(1))
    block = re.sub(r'Slot\d+', "Slot%d", last.group(0).split("\n")[0])
    nodes = ""
    for k, p in enumerate(added, 1):
        nodes += "\n" + last.group(0).split("\n")[0].replace("Slot%d" % number, "Slot%d" % (number + k)) + "\nposition = Vector2(%d, %d)\n" % (p[0], p[1])
    text = text[:last.end()] + nodes + text[last.end():]
    open(path, "w").write(text)
    print("appended", len(added), "slots to", TSCN_LEVELS[level])


if __name__ == "__main__":
    level, total = sys.argv[1], int(sys.argv[2])
    existing, added = place(level, total)
    print(level, "had", len(existing), "slots; adding", [(int(p[0]), int(p[1])) for p in added])
    write(level, existing, added)
