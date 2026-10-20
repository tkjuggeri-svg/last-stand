# Dev tool (not shipped): writes data/waves/wave_01..15.tres from the table below and prints each
# wave's enemy count, HP and gold. Run from the project folder: python3 tools/make_waves.py
# The .tres files are the game's data; edit this table (not the files) and rerun, so the HP curve and
# the gold scale (GOLD_TARGET: the kill gold each wave's regulars pay) stay consistent.
HP = {"ghoul": 30, "hound": 15, "brute": 150, "cultist": 20, "gravelord": 0, "colossus": 0, "lich": 0}
GOLD = {"ghoul": 8, "hound": 4, "brute": 20, "cultist": 10, "gravelord": 0, "colossus": 0, "lich": 0}
# Kill gold of each wave's regulars (bosses pay their own): None = unscaled (waves 1-5).
GOLD_TARGET = [None, None, None, None, None, 250, 260, 280, 300, 270, 310, 320, 330, 340, 350]
# Move-speed scale of each wave's regulars (bosses move as authored).
SPEED = [1.0] * 10 + [1.03, 1.05, 1.07, 1.08, 1.1]
W, NE, S = 0, 1, 2
# (enemy, count, interval, lane, delay)
WAVES = [
 (1.0, [("ghoul", 8, 2.0, W, 0)]),
 (1.0, [("ghoul", 9, 1.6, W, 0), ("ghoul", 4, 2.0, NE, 6)]),
 (1.0, [("ghoul", 8, 1.4, W, 0), ("hound", 6, 0.7, NE, 5), ("ghoul", 3, 2.0, S, 8)]),
 (1.0, [("ghoul", 10, 1.2, W, 0), ("hound", 8, 0.6, S, 6), ("cultist", 2, 3.0, NE, 4), ("ghoul", 4, 1.5, NE, 10)]),
 (1.1, [("gravelord", 1, 1.0, W, 6), ("ghoul", 10, 1.3, W, 0), ("hound", 8, 0.6, S, 10), ("cultist", 2, 3.0, NE, 8), ("brute", 1, 1.0, S, 16)]),
 (1.15, [("ghoul", 16, 1.0, W, 0), ("hound", 10, 0.6, NE, 6), ("brute", 2, 8.0, S, 4), ("cultist", 3, 2.5, W, 12), ("ghoul", 8, 1.2, S, 14)]),
 (1.25, [("ghoul", 14, 1.0, W, 0), ("hound", 16, 0.5, S, 4), ("brute", 3, 7.0, W, 6), ("cultist", 4, 2.5, NE, 8), ("hound", 8, 0.5, NE, 18), ("ghoul", 8, 1.2, S, 20)]),
 (1.35, [("ghoul", 20, 0.9, W, 0), ("ghoul", 10, 1.0, NE, 6), ("hound", 18, 0.5, S, 8), ("brute", 5, 6.0, W, 4), ("cultist", 5, 2.5, S, 10), ("cultist", 3, 3.0, NE, 20)]),
 (1.5, [("ghoul", 24, 0.8, W, 0), ("hound", 24, 0.45, NE, 5), ("brute", 6, 5.0, S, 4), ("brute", 3, 8.0, W, 16), ("cultist", 6, 2.0, W, 10), ("ghoul", 12, 1.0, S, 18), ("cultist", 3, 3.0, S, 22)]),
 # Waves 10-15 (M6 playtest 2): every lane carries a real force at once, Cultists come in groups on
 # different lanes, regulars get faster (SPEED), so no single strong spot holds a whole wave.
 (1.6, [("colossus", 1, 1.0, W, 12), ("ghoul", 26, 0.8, W, 0), ("ghoul", 14, 1.0, NE, 4), ("hound", 18, 0.45, S, 6), ("hound", 10, 0.45, NE, 14), ("brute", 4, 5.0, S, 8), ("brute", 4, 5.0, NE, 16), ("cultist", 3, 2.0, W, 8), ("cultist", 3, 2.0, S, 10), ("cultist", 2, 2.0, NE, 18)]),
 (1.85, [("ghoul", 24, 0.8, W, 0), ("ghoul", 16, 0.9, S, 2), ("hound", 20, 0.45, NE, 0), ("hound", 14, 0.45, W, 18), ("brute", 5, 5.0, NE, 6), ("brute", 5, 5.0, S, 12), ("brute", 3, 6.0, W, 20), ("cultist", 4, 1.8, W, 6), ("cultist", 4, 1.8, NE, 10), ("cultist", 3, 1.8, S, 16)]),
 (2.0, [("ghoul", 26, 0.75, W, 0), ("ghoul", 20, 0.8, NE, 4), ("hound", 24, 0.4, S, 0), ("hound", 14, 0.4, NE, 20), ("brute", 6, 4.5, S, 6), ("brute", 5, 5.0, W, 10), ("brute", 4, 5.0, NE, 22), ("cultist", 5, 1.7, W, 4), ("cultist", 5, 1.7, S, 8), ("cultist", 4, 1.7, NE, 14)]),
 (2.15, [("ghoul", 30, 0.7, W, 0), ("ghoul", 22, 0.8, S, 2), ("ghoul", 14, 0.9, NE, 16), ("hound", 28, 0.4, NE, 0), ("hound", 20, 0.4, W, 24), ("brute", 7, 4.0, S, 4), ("brute", 6, 4.5, NE, 10), ("brute", 5, 5.0, W, 20), ("cultist", 6, 1.6, W, 4), ("cultist", 5, 1.6, NE, 8), ("cultist", 5, 1.6, S, 12)]),
 (2.2, [("ghoul", 34, 0.65, W, 0), ("ghoul", 26, 0.75, S, 0), ("ghoul", 18, 0.8, NE, 14), ("hound", 30, 0.35, NE, 0), ("hound", 24, 0.4, S, 22), ("brute", 8, 3.5, W, 4), ("brute", 7, 4.0, S, 8), ("brute", 6, 4.5, NE, 18), ("cultist", 7, 1.5, W, 4), ("cultist", 6, 1.5, NE, 6), ("cultist", 6, 1.5, S, 10), ("cultist", 4, 2.0, W, 26)]),
 (2.35, [("lich", 1, 1.0, W, 14), ("ghoul", 34, 0.7, W, 0), ("ghoul", 26, 0.75, NE, 0), ("ghoul", 20, 0.8, S, 16), ("hound", 30, 0.4, S, 2), ("hound", 20, 0.4, NE, 28), ("brute", 8, 4.0, NE, 4), ("brute", 8, 4.5, W, 22), ("brute", 6, 5.0, S, 10), ("cultist", 6, 1.6, W, 6), ("cultist", 6, 1.6, S, 8), ("cultist", 5, 1.6, NE, 14), ("cultist", 4, 2.0, W, 30)]),
]
prev = 0
for n, (mult, groups) in enumerate(WAVES, 1):
    enemies = sorted({g[0] for g in groups})
    ids = {e: "%d_%s" % (i + 2, e) for i, e in enumerate(enemies)}
    out = ['[gd_resource type="Resource" script_class="WaveData" format=3]', '',
           '[ext_resource type="Script" path="res://resources/spawn_group.gd" id="1_group"]']
    for e in enemies:
        out.append('[ext_resource type="Resource" path="res://data/enemies/%s.tres" id="%s"]' % (e, ids[e]))
    out.append('[ext_resource type="Script" path="res://resources/wave_data.gd" id="9_wave"]')
    subs = []
    for k, (e, count, interval, lane, delay) in enumerate(groups):
        sid = "Resource_g%d" % k
        subs.append(sid)
        out += ['', '[sub_resource type="Resource" id="%s"]' % sid, 'script = ExtResource("1_group")',
                'enemy = ExtResource("%s")' % ids[e], 'count = %d' % count, 'interval = %s' % repr(float(interval))]
        if lane: out.append('lane = %d' % lane)
        if delay: out.append('delay = %s' % repr(float(delay)))
    out += ['', '[resource]', 'script = ExtResource("9_wave")']
    if mult != 1.0: out.append('health_multiplier = %s' % repr(mult))
    gold = sum(GOLD[g[0]] * g[1] for g in groups)
    gmult = 1.0 if GOLD_TARGET[n - 1] is None else round(GOLD_TARGET[n - 1] / gold, 2)
    if gmult != 1.0: out.append('gold_multiplier = %s' % repr(gmult))
    if SPEED[n - 1] != 1.0: out.append('speed_multiplier = %s' % repr(SPEED[n - 1]))
    out.append('groups = Array[ExtResource("1_group")]([%s])' % ", ".join('SubResource("%s")' % s for s in subs))
    open("data/waves/wave_%02d.tres" % n, "w").write("\n".join(out) + "\n")
    hp = sum(HP[g[0]] * g[1] for g in groups)
    count = sum(g[1] for g in groups)
    print("wave %2d: %3d enemies, %5d HP x%.2f = %6.0f, gold %4d x%.2f %s" % (n, count, hp, mult, hp * mult, gold, gmult, "" if hp > prev else "  <-- NOT RISING"))
    prev = hp
