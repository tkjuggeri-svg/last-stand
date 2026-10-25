# Dev tool (not shipped): writes a biome's level scene (levels/<id>.tscn) from a spec, using the Crypt
# Road arena (levels/prototype_arena.tscn) as the template for everything that is the same in every
# level (systems, HUD, hero, fortress, walls, camera): the spec changes the floor, lanes, build slots,
# colours, props, gates, particles, waves and adds the biome's hazard nodes. Run from the project folder:
#   python3 tools/make_level.py [<biome id> ...]      (no id: every spec in tools/levels/*.json)
# Specs: tools/levels/<id>.json (see tools/levels/ashen_keep.json). After a change to the floor, lanes or
# slots, regenerate the ground: godot --headless --path . --script res://tools/art/generate_art.gd -- --only=<id>_ground
import json, math, os, random, re, sys

TEMPLATE = "levels/prototype_arena.tscn"


def blocks_of(text):
    return text.split("\n\n")


def node_name(block):
    m = re.match(r'\[node name="([^"]+)"', block)
    return m.group(1) if m else None


def node_parent(block):
    m = re.match(r'\[node name="[^"]+"[^\]]*parent="([^"]*)"', block)
    return m.group(1) if m else None


def curve_block(name, pts):
    flat = ", ".join("0, 0, 0, 0, %d, %d" % (x, y) for x, y in pts)
    return '[sub_resource type="Curve2D" id="Curve2D_%s"]\n_data = {\n"points": PackedVector2Array(%s)\n}\npoint_count = %d' % (name, flat, len(pts))


def dist_to_polyline(p, pts):
    best = 1e9
    for a, b in zip(pts, pts[1:]):
        ax, ay = a; bx, by = b
        dx, dy = bx - ax, by - ay
        t = max(0.0, min(1.0, ((p[0] - ax) * dx + (p[1] - ay) * dy) / max(dx * dx + dy * dy, 1e-9)))
        best = min(best, math.hypot(p[0] - ax - t * dx, p[1] - ay - t * dy))
    return best


def validate(spec):
    fl = spec["floor"]
    problems = []
    for slot in spec["slots"]:
        d = min(dist_to_polyline(slot, lane) for lane in spec["lanes"])
        if d < 45:
            problems.append("slot %s is %.0f px from a lane" % (slot, d))
        if math.hypot(*slot) < 90:
            problems.append("slot %s is too close to the fortress" % (slot,))
        if not (fl[0] + 30 < slot[0] < fl[2] - 30 and fl[1] + 30 < slot[1] < fl[3] - 30):
            problems.append("slot %s is outside the floor" % (slot,))
    for i, a in enumerate(spec["slots"]):
        for b in spec["slots"][i + 1:]:
            if math.hypot(a[0] - b[0], a[1] - b[1]) < 70:
                problems.append("slots %s and %s are close" % (a, b))
    for lane in spec["lanes"]:
        for x, y in lane:
            if not (fl[0] - 1 <= x <= fl[2] + 1 and fl[1] - 1 <= y <= fl[3] + 1):
                problems.append("lane point %s is outside the floor" % ((x, y),))
    return problems


def make(spec):
    problems = validate(spec)
    if problems:
        print("\n".join("  PROBLEM: " + p for p in problems))
        sys.exit(1)
    bid = spec["id"]
    fl = spec["floor"]  # left, top, right, bottom
    band = 32
    blocks = blocks_of(open(TEMPLATE).read())
    out = []
    removed = {"Fireflies", "Props", "ArenaBounds", "Lane", "Lane2", "Lane3", "BuildSlots", "WaveSpawner", "RespawnPoint"}
    for block in blocks:
        name = node_name(block)
        parent = node_parent(block)
        first = block.split("\n", 1)[0]
        if first.startswith("[gd_scene") or first.startswith("[ext_resource"):
            # header and external resources (the list has blank lines in it: several blocks)
            lines = block.split("\n")
            kept = []
            if first.startswith("[gd_scene"):
                kept.append(lines[0].replace(re.search(r'load_steps=\d+', lines[0]).group(0), "load_steps=500"))
                lines = lines[1:]
            for line in lines:
                if re.search(r'id="(25_wave01|w\d\d_wave)"', line):
                    continue
                if 'id="7_ground"' in line:
                    line = line.replace("prototype_arena_ground.png", "%s_ground.png" % bid)
                if 'id="20_props"' in line:
                    line = line.replace("assets/sprites/environment/props.png", "assets/sprites/environment/%s_props.png" % bid)
                if 'id="22_crypt"' in line:
                    line = line.replace("assets/sprites/environment/crypt.png", "assets/sprites/environment/%s_gate.png" % bid)
                kept.append(line)
            if first.startswith("[gd_scene"):
                for n in range(1, 16):
                    kept.append('[ext_resource type="Resource" path="res://data/waves/%s/wave_%02d.tres" id="bw%02d"]' % (spec["waves"], n, n))
                for i, (path, kind) in enumerate(spec.get("ext", [])):
                    kept.append('[ext_resource type="%s" path="%s" id="hz%d"]' % (kind, path, i))
            out.append("\n".join(kept))
            continue
        if first.startswith('[sub_resource type="Curve2D"'):
            continue
        if first.startswith('[sub_resource type="RectangleShape2D" id="RectangleShape2D_wall_h"]'):
            w = fl[2] - fl[0] + 200
            out.append('[sub_resource type="RectangleShape2D" id="RectangleShape2D_wall_h"]\nsize = Vector2(%d, 100)' % w)
            continue
        if first.startswith('[sub_resource type="RectangleShape2D" id="RectangleShape2D_wall_v"]'):
            h = fl[3] - fl[1] + 200
            out.append('[sub_resource type="RectangleShape2D" id="RectangleShape2D_wall_v"]\nsize = Vector2(100, %d)' % h)
            # the lanes' curves go with the shapes
            for i, lane in enumerate(spec["lanes"]):
                out.append(curve_block("lane%d" % (i + 1), lane))
            continue
        if name in removed or ((parent or "").split("/")[0] in ("Props", "BuildSlots", "ArenaBounds", "Crypt", "Crypt2", "Crypt3") and name is not None) or (name or "").startswith("Crypt") or parent in ("Crypt", "Crypt2", "Crypt3"):
            continue
        if name == "PrototypeArena":
            block = block.replace('name="PrototypeArena"', 'name="%s"' % spec["node"])
        elif name == "Backdrop":
            block = re.sub(r"offset_left = [-0-9.]+", "offset_left = %d" % (fl[0] - 500), block)
            block = re.sub(r"offset_top = [-0-9.]+", "offset_top = %d" % (fl[1] - 400), block)
            block = re.sub(r"offset_right = [-0-9.]+", "offset_right = %d" % (fl[2] + 500), block)
            block = re.sub(r"offset_bottom = [-0-9.]+", "offset_bottom = %d" % (fl[3] + 400), block)
            block = re.sub(r"color = Color\([^)]*\)", "color = Color(%s)" % spec["backdrop"], block)
        elif name == "Floor" or (name == "Fog" and parent == "."):
            for key, val in zip(("offset_left", "offset_top", "offset_right", "offset_bottom"), fl):
                block = re.sub(key + r" = [-0-9.]+", "%s = %d" % (key, val), block)
            if name == "Floor":
                block = re.sub(r"color = Color\([^)]*\)", "color = Color(%s)" % spec["floor_color"], block)
        elif name == "Ground":
            block = re.sub(r"position = Vector2\([^)]*\)", "position = Vector2(%d, %d)" % (fl[0] - band, fl[1] - band), block)
        elif name == "CanvasModulate":
            block = re.sub(r"color = Color\([^)]*\)", "color = Color(%s)" % spec["modulate"], block)
        elif first.startswith('[sub_resource type="ShaderMaterial" id="ShaderMaterial_fog"]'):
            block = re.sub(r"fog_color = Color\([^)]*\)", "fog_color = Color(%s)" % spec["fog"], block)
            block = re.sub(r"rect_size = Vector2\([^)]*\)", "rect_size = Vector2(%d, %d)" % (fl[2] - fl[0], fl[3] - fl[1]), block)
            block = re.sub(r"base_density = [0-9.]+", "base_density = %s" % spec.get("fog_density", 0.3), block)
        elif name == "Hero" and parent == ".":
            block = re.sub(r"position = Vector2\([^)]*\)", "position = Vector2(%d, %d)" % tuple(spec["hero"]), block)
        elif name == "Camera2D":
            block = re.sub(r"limit_left = [-0-9]+", "limit_left = %d" % (fl[0] - band), block)
            block = re.sub(r"limit_top = [-0-9]+", "limit_top = %d" % (fl[1] - band), block)
            block = re.sub(r"limit_right = [-0-9]+", "limit_right = %d" % (fl[2] + band), block)
            block = re.sub(r"limit_bottom = [-0-9]+", "limit_bottom = %d" % (fl[3] + band), block)
        out.append(block)
    # Insert the generated nodes before "Fortress" (lanes, bounds), and slots, spawner, respawn after it.
    cx, cy = (fl[0] + fl[2]) // 2, (fl[1] + fl[3]) // 2
    gen = []
    gen.append('[node name="ArenaBounds" type="StaticBody2D" parent="."]\ncollision_mask = 0')
    for nm, pos, shape in (("WallTop", (cx, fl[1] - 50), "h"), ("WallBottom", (cx, fl[3] + 50), "h"), ("WallLeft", (fl[0] - 50, cy), "v"), ("WallRight", (fl[2] + 50, cy), "v")):
        gen.append('[node name="%s" type="CollisionShape2D" parent="ArenaBounds"]\nposition = Vector2(%d, %d)\nshape = SubResource("RectangleShape2D_wall_%s")' % (nm, pos[0], pos[1], shape))
    for i in range(len(spec["lanes"])):
        gen.append('[node name="Lane%s" type="Path2D" parent="."]\ncurve = SubResource("Curve2D_lane%d")' % ("" if i == 0 else str(i + 1), i + 1))
    props = ['[node name="Props" type="Node2D" parent="."]\ny_sort_enabled = true']
    rng = random.Random(spec.get("seed", 5))
    placed = []
    count = spec.get("prop_count", 46)
    tries = 0
    while len(placed) < count and tries < 4000:
        tries += 1
        x = rng.randint(fl[0] + 25, fl[2] - 25)
        y = rng.randint(fl[1] + 40, fl[3] - 12)
        if min(dist_to_polyline((x, y), lane) for lane in spec["lanes"]) < 42 or math.hypot(x, y) < 95:
            continue
        if any(math.hypot(x - sx, y - sy) < 50 for sx, sy in spec["slots"]) or any(math.hypot(x - px, y - py) < 36 for px, py, _ in placed):
            continue
        if any(math.hypot(x - lane[0][0], y - lane[0][1]) < 80 for lane in spec["lanes"]):
            continue
        weights = spec.get("prop_weights", [1] * spec["prop_frames"])
        frame = rng.choices(range(spec["prop_frames"]), weights)[0]
        placed.append((x, y, frame))
    for i, (x, y, frame) in enumerate(placed, 1):
        props.append('[node name="Prop%d" type="Sprite2D" parent="Props"]\nposition = Vector2(%d, %d)\nscale = Vector2(1, 1)\ntexture = ExtResource("20_props")\noffset = Vector2(0, -40)\nhframes = %d\nframe = %d' % (i, x, y, spec["prop_frames"], frame))
    gates = []
    for i, lane in enumerate(spec["lanes"]):
        sx, sy = lane[0]
        d = spec.get("gate_offset", [-35, 0])
        g = '[node name="Gate%d" type="Sprite2D" parent="."]\nposition = Vector2(%d, %d)\nscale = Vector2(1, 1)\ntexture = ExtResource("22_crypt")\noffset = Vector2(0, %d)' % (i + 1, sx + d[0] * (1 if sx < fl[0] + 100 else 0), sy + d[1], spec.get("gate_offset_y", -42))
        glow = '[node name="Glow" type="PointLight2D" parent="Gate%d"]\nposition = Vector2(0, -12)\nscale = Vector2(1, 1)\ncolor = Color(%s)\nenergy = 0.7\ntexture = ExtResource("21_light")\ntexture_scale = 2.0' % (i + 1, spec["gate_glow"])
        gates += [g, glow]
    particles = ""
    if spec.get("particles"):
        p = spec["particles"]
        particles = ('[node name="Ambience" type="CPUParticles2D" parent="."]\nz_index = 2\nposition = Vector2(%d, %d)\namount = %d\nlifetime = %s\npreprocess = %s\ntexture = ExtResource("24_mote")\nemission_shape = 3\n'
                     'emission_rect_extents = Vector2(%d, %d)\ndirection = Vector2(%s)\nspread = %s\ngravity = Vector2(%s)\ninitial_velocity_min = %s\ninitial_velocity_max = %s\nscale_amount_min = 2.0\nscale_amount_max = 2.0\ncolor = Color(%s)'
                     % (cx, cy, p["amount"], p["lifetime"], p["lifetime"], (fl[2] - fl[0]) // 2, (fl[3] - fl[1]) // 2, p["direction"], p.get("spread", 30), p["gravity"], p["v_min"], p["v_max"], p["color"]))
    slots = ['[node name="BuildSlots" type="Node2D" parent="."]\ny_sort_enabled = true']
    for i, (x, y) in enumerate(spec["slots"], 1):
        slots.append('[node name="Slot%d" parent="BuildSlots" instance=ExtResource("14_slot")]\nposition = Vector2(%d, %d)' % (i, x, y))
    lane_paths = ", ".join('NodePath("../Lane%s")' % ("" if i == 0 else str(i + 1)) for i in range(len(spec["lanes"])))
    wave_list = ", ".join('ExtResource("bw%02d")' % n for n in range(1, 16))
    spawner = ('[node name="WaveSpawner" type="Node2D" parent="." node_paths=PackedStringArray("lanes")]\ny_sort_enabled = true\nscript = ExtResource("4_spawner")\nenemy_scene = ExtResource("5_enemy")\n'
               'lanes = [%s]\nwaves = Array[ExtResource("26_wave_data")]([%s])' % (lane_paths, wave_list))
    respawn = '[node name="RespawnPoint" parent="." instance=ExtResource("29_respawn")]\nposition = Vector2(%d, %d)' % tuple(spec["respawn"])
    hazards = spec.get("hazards", [])
    # Place: gates/props/particles before the bounds, spawner etc. after Fortress.
    final = []
    for block in out:
        final.append(block)
        if node_name(block) == "CanvasModulate" or node_name(block) == "Fog" and node_parent(block) == ".":
            pass
    # find insertion points
    idx_fortress = next(i for i, b in enumerate(final) if node_name(b) == "Fortress")
    pre = gates + props + ([particles] if particles else []) + gen
    post = slots + [spawner, respawn] + hazards
    final = final[:idx_fortress] + pre + [final[idx_fortress]] + final[idx_fortress + 1:]
    idx_effects = next(i for i, b in enumerate(final) if node_name(b) == "Effects")
    final = final[:idx_effects] + post + final[idx_effects:]
    text = "\n\n".join(final)
    if not text.endswith("\n"):
        text += "\n"
    text = text.replace("lantern_targets = Array[ExtResource(\"r_enemy_data\")]", "lantern_targets = Array[ExtResource(\"r_enemy_data\")]")
    path = "levels/%s.tscn" % bid
    open(path, "w").write(text)
    print("wrote", path, "(%d props, %d slots, %d lanes)" % (len(placed), len(spec["slots"]), len(spec["lanes"])))


if __name__ == "__main__":
    ids = sys.argv[1:] or [f[:-5] for f in sorted(os.listdir("tools/levels")) if f.endswith(".json")]
    for bid in ids:
        make(json.load(open("tools/levels/%s.json" % bid)))
