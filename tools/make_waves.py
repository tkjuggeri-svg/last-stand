# Dev tool (not shipped): writes each chapter's waves (chapter 1: data/waves/wave_01..15.tres, chapter 2:
# data/waves/chapter_2/wave_01..15.tres) from the tables below and prints each wave's enemy count, HP and
# gold. Run from the project folder: python3 tools/make_waves.py
# The .tres files are the game's data; edit this table (not the files) and rerun, so the HP curve and
# the gold scale (GOLD_TARGET: the kill gold each wave's regulars pay) stay consistent.
HP = {"ghoul": 30, "hound": 15, "brute": 150, "cultist": 20, "bloater": 110, "mire_priest": 34, "shieldbearer": 90, "gravelord": 0, "colossus": 0, "lich": 0, "tollkeeper": 0, "siege_ram": 300, "black_knight": 160, "fallen_marshal": 0,
      "cinder_ghoul": 30, "scarecrow": 120, "pyre_warden": 0, "frost_wraith": 40, "rime_brute": 170, "winter_warden": 0, "burrower": 60, "lamp_wight": 50, "deep_warden": 0,
      "bone_hurler": 45, "rubble_brute": 210, "quarry_colossus": 0, "stalker": 55, "hollow_treant": 260, "hollow_stag": 0, "chorister": 45, "inquisitor": 150, "pale_bishop": 0}
GOLD = {"ghoul": 8, "hound": 4, "brute": 20, "cultist": 10, "bloater": 14, "mire_priest": 16, "shieldbearer": 14, "gravelord": 0, "colossus": 0, "lich": 0, "tollkeeper": 0,
        "siege_ram": 24, "black_knight": 18, "fallen_marshal": 0, "cinder_ghoul": 9, "scarecrow": 16, "pyre_warden": 0,
        "frost_wraith": 18, "rime_brute": 22, "winter_warden": 0, "burrower": 12, "lamp_wight": 18, "deep_warden": 0,
        "bone_hurler": 14, "rubble_brute": 24, "quarry_colossus": 0, "stalker": 14, "hollow_treant": 26, "hollow_stag": 0, "chorister": 18, "inquisitor": 20, "pale_bishop": 0}
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

# Chapter 2 (M7, M7.5): ramps up from chapter 1's end (docs/M7_RUN_MAP.md 4.): HP x0.7 -> x3.8 (M7.5:
# the first rows start lower, since only 40% of the towers' cost carries over and the defence is
# rebuilt), speed x1.05 -> x1.18, every lane pressed from the first wave, the Tollkeeper in wave 15.
# M7.5: its own enemies arrive one by one (Bloater wave 2, Mire Priest wave 4, Shieldbearer wave 6),
# taking the place of some Ghouls and Brutes: harder enemies, not just more HP.
# Rows 1-6 of its map play waves 1-12, its boss fight waves 13-15.
WAVES_2 = [
 # Row 1: the marsh's familiar dead, then the first Bloaters (wave 2).
 (0.7, [("ghoul", 24, 0.8, W, 0), ("ghoul", 12, 0.9, S, 4), ("hound", 16, 0.45, NE, 4), ("brute", 3, 6.0, S, 6), ("cultist", 3, 2.0, W, 8)]),
 (0.85, [("ghoul", 26, 0.8, W, 0), ("ghoul", 14, 0.9, S, 4), ("hound", 18, 0.45, NE, 2), ("bloater", 3, 5.0, W, 8), ("cultist", 4, 1.8, S, 10)]),
 # Row 2: Bloaters on two roads; the first Mire Priests (wave 4) walk behind a crowd.
 (0.95, [("ghoul", 28, 0.75, W, 0), ("ghoul", 10, 0.9, NE, 10), ("hound", 20, 0.4, S, 0), ("bloater", 3, 5.0, NE, 6), ("bloater", 2, 6.0, W, 14), ("cultist", 4, 1.8, W, 8), ("cultist", 3, 2.0, NE, 14)]),
 (1.1, [("ghoul", 26, 0.75, NE, 0), ("ghoul", 18, 0.8, W, 4), ("hound", 22, 0.4, S, 2), ("brute", 3, 6.0, W, 6), ("bloater", 3, 5.0, S, 8), ("mire_priest", 2, 6.0, W, 10), ("cultist", 5, 1.8, S, 10)]),
 # Row 3: Priests on two roads; the first Shieldbearers (wave 6) lead a column.
 (1.3, [("ghoul", 30, 0.75, W, 0), ("ghoul", 20, 0.8, S, 0), ("hound", 24, 0.4, NE, 4), ("bloater", 4, 4.5, S, 8), ("brute", 3, 6.0, NE, 14), ("mire_priest", 2, 6.0, W, 8), ("mire_priest", 1, 1.0, S, 16), ("cultist", 4, 1.7, NE, 14)]),
 (1.5, [("ghoul", 32, 0.7, W, 0), ("ghoul", 22, 0.8, NE, 0), ("hound", 26, 0.4, S, 2), ("shieldbearer", 4, 3.0, NE, 4), ("brute", 4, 5.0, W, 6), ("bloater", 3, 5.0, S, 12), ("mire_priest", 2, 5.0, W, 12), ("cultist", 6, 1.7, S, 8)]),
 # Rows 4-6: all three on every road, more of them each row. (M14: rows 5-6, waves 9-12, eased by about 10% after
 # two heroes in four playtest runs fell at row 6; the rows after still ramp up to the boss fight.)
 (1.75, [("ghoul", 34, 0.7, W, 0), ("ghoul", 24, 0.75, S, 2), ("hound", 28, 0.4, NE, 0), ("shieldbearer", 4, 3.0, W, 4), ("shieldbearer", 3, 3.0, NE, 10), ("bloater", 4, 4.5, S, 6), ("mire_priest", 2, 5.0, W, 10), ("mire_priest", 2, 5.0, NE, 14), ("cultist", 5, 1.6, NE, 8), ("cultist", 4, 1.8, S, 18)]),
 (2.0, [("ghoul", 36, 0.7, W, 0), ("ghoul", 26, 0.75, NE, 2), ("hound", 30, 0.35, S, 0), ("shieldbearer", 5, 3.0, S, 4), ("brute", 5, 4.5, NE, 6), ("bloater", 5, 4.0, W, 8), ("mire_priest", 3, 4.0, S, 12), ("cultist", 7, 1.6, W, 6), ("cultist", 5, 1.7, S, 12)]),
 (2.15, [("ghoul", 38, 0.65, W, 0), ("ghoul", 28, 0.75, S, 0), ("hound", 32, 0.35, NE, 2), ("shieldbearer", 5, 2.8, W, 4), ("shieldbearer", 4, 3.0, NE, 12), ("bloater", 5, 4.0, S, 6), ("brute", 4, 5.0, NE, 14), ("mire_priest", 3, 4.0, W, 10), ("mire_priest", 2, 5.0, NE, 16), ("cultist", 7, 1.5, NE, 6), ("cultist", 6, 1.6, W, 12)]),
 (2.35, [("ghoul", 40, 0.65, W, 0), ("ghoul", 30, 0.7, NE, 0), ("hound", 34, 0.35, S, 0), ("shieldbearer", 6, 2.8, S, 4), ("shieldbearer", 4, 3.0, W, 14), ("bloater", 6, 3.5, NE, 4), ("brute", 6, 4.5, W, 16), ("mire_priest", 3, 4.0, S, 10), ("mire_priest", 3, 4.0, W, 18), ("cultist", 8, 1.5, W, 6), ("cultist", 6, 1.6, NE, 14)]),
 (2.6, [("ghoul", 42, 0.6, W, 0), ("ghoul", 30, 0.7, S, 0), ("ghoul", 18, 0.8, NE, 14), ("hound", 36, 0.35, NE, 0), ("shieldbearer", 6, 2.6, W, 4), ("shieldbearer", 5, 2.8, NE, 10), ("bloater", 6, 3.5, S, 6), ("brute", 6, 4.0, NE, 18), ("mire_priest", 4, 3.5, W, 10), ("mire_priest", 3, 4.0, S, 14), ("cultist", 8, 1.5, S, 6), ("cultist", 7, 1.5, W, 12)]),
 (2.85, [("ghoul", 44, 0.6, W, 0), ("ghoul", 32, 0.7, NE, 0), ("ghoul", 20, 0.8, S, 14), ("hound", 38, 0.3, S, 0), ("shieldbearer", 7, 2.6, NE, 4), ("shieldbearer", 6, 2.6, S, 12), ("bloater", 7, 3.2, W, 6), ("brute", 6, 4.0, S, 18), ("mire_priest", 4, 3.5, NE, 10), ("mire_priest", 4, 3.5, W, 16), ("cultist", 9, 1.4, W, 6), ("cultist", 7, 1.5, NE, 12), ("cultist", 4, 2.0, S, 24)]),
 # Boss fight (waves 13-15): everything, and the Tollkeeper in wave 15.
 (3.45, [("ghoul", 46, 0.6, W, 0), ("ghoul", 34, 0.65, S, 0), ("ghoul", 22, 0.75, NE, 12), ("hound", 40, 0.3, NE, 0), ("shieldbearer", 8, 2.5, W, 4), ("shieldbearer", 6, 2.6, NE, 10), ("bloater", 8, 3.0, S, 6), ("brute", 7, 4.0, NE, 16), ("mire_priest", 4, 3.5, S, 8), ("mire_priest", 4, 3.5, W, 14), ("cultist", 9, 1.4, S, 6), ("cultist", 8, 1.4, W, 12), ("cultist", 5, 1.8, NE, 24)]),
 (3.6, [("ghoul", 48, 0.55, W, 0), ("ghoul", 36, 0.65, NE, 0), ("ghoul", 24, 0.7, S, 12), ("hound", 42, 0.3, S, 0), ("shieldbearer", 8, 2.4, NE, 4), ("shieldbearer", 7, 2.5, S, 10), ("bloater", 9, 3.0, W, 6), ("brute", 8, 3.5, S, 16), ("mire_priest", 5, 3.0, W, 8), ("mire_priest", 4, 3.5, NE, 14), ("cultist", 10, 1.3, W, 6), ("cultist", 8, 1.4, S, 12), ("cultist", 6, 1.6, NE, 22)]),
 (3.8, [("tollkeeper", 1, 1.0, W, 14), ("ghoul", 48, 0.6, W, 0), ("ghoul", 36, 0.65, NE, 0), ("ghoul", 26, 0.7, S, 14), ("hound", 40, 0.3, S, 2), ("shieldbearer", 8, 2.4, W, 4), ("shieldbearer", 6, 2.5, NE, 12), ("bloater", 8, 3.0, S, 8), ("brute", 8, 4.0, NE, 20), ("mire_priest", 5, 3.0, W, 10), ("mire_priest", 4, 3.5, S, 16), ("cultist", 10, 1.4, W, 6), ("cultist", 8, 1.4, S, 10), ("cultist", 6, 1.6, NE, 18)]),
]
# M7.5: with only 40% of the towers' cost carried over, the defence must grow during the chapter, so
# its kill gold is back up (M7 kept it at 220-300 because the full refund paid for the rebuild).
GOLD_TARGET_2 = [300, 310, 320, 330, 340, 350, 360, 370, 380, 390, 400, 410, 420, 430, 440]
SPEED_2 = [1.05, 1.05, 1.06, 1.07, 1.08, 1.09, 1.1, 1.11, 1.12, 1.13, 1.14, 1.15, 1.16, 1.17, 1.18]
# Chapter 3 (M10, the Ashen Keep: four roads, lanes 0-3): starts above chapter 2's end (the dead are tougher
# from the first wave and the defence is rebuilt from 40% of its cost), the Siege Rams come from wave 2 and
# the Black Knights from wave 4, the Fallen Marshal leads wave 15. Built from a rule, not by hand: wave n
# adds a little of everything on the four roads.
N, E, SW = 1, 2, 3


def ramp_in(base, n, start, length):
    """`base` enemies once the group has fully arrived: 0 before wave `start`, then growing to `base` over `length` waves."""
    if n < start:
        return 0
    return max(1, int(base * min(1.0, (n - start + 1) / length)))


def mult_3(n):
    """Tier 3's health curve: the first waves start higher than the old 0.6 + 0.18 (n - 1), so that no row of
    two waves is more than about x1.8 the HP of the row before (a straight line would be x1.84 at row 1 to 2
    before any heavy enemy). From wave 7 on it is the old line exactly (M12 follow-up, balance trace)."""
    early = [0.8, 0.886, 1.011, 1.157, 1.319, 1.494]
    return early[n - 1] if n <= len(early) else round(0.6 + 0.18 * (n - 1), 2)


def wave_3(n, brute_from=5, brute_len=3):
    t = n - 1
    groups = [("ghoul", 20 + 2 * t, max(0.5, 0.85 - 0.02 * t), W, 0), ("ghoul", 14 + t * 3 // 2, max(0.5, 0.9 - 0.02 * t), E, 4),
              ("hound", 14 + t * 8 // 5, 0.4, SW, 2), ("hound", 8 + t, 0.4, N, 8)]
    # The heavy enemies arrive one kind at a time and grow to their full count over a few waves (Rams from wave
    # 2, Shieldbearers 4, Brutes 5, Black Knights 8), so a row never adds them all at once.
    if n >= 2:
        groups.append(("siege_ram", ramp_in(1 + t // 3, n, 2, 3), 8.0, E if n % 2 else SW, 6))
    if n >= brute_from:
        groups.append(("brute", ramp_in(2 + t // 2, n, brute_from, brute_len), 5.0, N, 4))
    if n >= 4:
        groups.append(("shieldbearer", ramp_in(2 + t // 3, n, 4, 2), 3.5, W, 6))
    if n >= 8:
        groups.append(("black_knight", ramp_in(2 + t // 2, n, 8, 2), 4.0, SW, 10))
    groups += [("cultist", 3 + t // 2, max(1.4, 2.2 - 0.06 * t), [W, E, N, SW][n % 4], 8), ("cultist", 2 + t // 3, 2.0, [SW, N, E, W][n % 4], 16)]
    if n == 15:
        groups.insert(0, ("fallen_marshal", 1, 1.0, W, 14))
    return groups


WAVES_3 = [(mult_3(n), wave_3(n)) for n in range(1, 16)]
GOLD_TARGET_3 = [380 + 12 * n for n in range(15)]
SPEED_3 = [round(1.1 + 0.011 * n, 3) for n in range(15)]
# M10 stage 2: the second biome of each tier, made from its tier's waves.
# Ember Orchard (tier 1, three roads): a third of each big Ghoul group are Cinder Ghouls, Scarecrows join from
# wave 3, the Pyre Warden replaces the Lich Warden in wave 15.
WAVES_E = []
for n, (mult, groups) in enumerate(WAVES, 1):
    out = []
    for (e, count, interval, lane, delay) in groups:
        if e == "ghoul" and n >= 2 and count >= 8:
            k = count // 3
            out += [("ghoul", count - k, interval, lane, delay), ("cinder_ghoul", k, interval, lane, delay)]
        else:
            out.append(("pyre_warden" if e == "lich" else e, count, interval, lane, delay))
    if n >= 3:
        out.append(("scarecrow", 1 + n // 5, 8.0, W if n % 2 else NE, 5))
    WAVES_E.append((mult, out))
# Frostbound Pass (tier 2): the Marsh's table with the Bloaters as Rime Brutes, the Mire Priests as Frost
# Wraiths and the Winter Warden for the Tollkeeper.
FROST_MAP = {"bloater": "rime_brute", "mire_priest": "frost_wraith", "tollkeeper": "winter_warden"}
WAVES_F = [(m, [(FROST_MAP.get(e, e), c, i, l, d) for (e, c, i, l, d) in groups]) for m, groups in WAVES_2]
# Sunless Mines (tier 3, three roads: lanes 0-2): the Keep's rule without Rams and Knights, with Burrowers from
# wave 2, Lamp Wights from wave 4 and the Deep Warden in wave 15.
def wave_mines(n):
    t = n - 1
    groups = [g for g in wave_3(n, 4, 6) if g[0] not in ("siege_ram", "black_knight", "fallen_marshal")]
    groups = [(e, c, i, min(l, 2), d) for (e, c, i, l, d) in groups]
    if n >= 2:
        groups.append(("burrower", 3 + t // 2, 3.0, [W, N, E][n % 3], 5))
    if n >= 4:
        groups.append(("lamp_wight", 2 + t // 4, 5.0, [N, E, W][n % 3], 8))
    if n == 15:
        groups.insert(0, ("deep_warden", 1, 1.0, W, 14))
    return groups


WAVES_M = [(mult_3(n), wave_mines(n)) for n in range(1, 16)]
# M10 stage 3: the third biome of each tier.
# Bone Quarry (tier 1): Brutes are Rubble Brutes, half the Cultists Bone Hurlers, the Quarry Colossus leads wave 15.
WAVES_Q = []
for n, (mult, groups) in enumerate(WAVES, 1):
    out = []
    for (e, count, interval, lane, delay) in groups:
        if e == "cultist" and n >= 3 and count >= 3:
            k = count // 2
            out += [("cultist", count - k, interval, lane, delay), ("bone_hurler", k, interval, lane, delay)]
        else:
            out.append(({"brute": "rubble_brute", "lich": "quarry_colossus"}.get(e, e), count, interval, lane, delay))
    WAVES_Q.append((mult, out))
# Gloam Wood (tier 2, four roads): the Marsh's table with Treants and Stalkers for its own dead, the third road
# of every even wave moved to the fourth, and a few more Stalkers from wave 3.
GLOAM_MAP = {"bloater": "hollow_treant", "mire_priest": "stalker", "tollkeeper": "hollow_stag"}
WAVES_G = []
for n, (mult, groups) in enumerate(WAVES_2, 1):
    out = [(GLOAM_MAP.get(e, e), c, i, 3 if (l == 2 and n % 2 == 0) else l, d) for (e, c, i, l, d) in groups]
    if n >= 3:
        out.append(("stalker", 3 + n // 2, 1.4, [N, E, SW][n % 3], 6))
    WAVES_G.append((mult, out))
# Pale Cathedral (tier 3, three aisles): the Keep's rule with Choristers from wave 2, Inquisitors from wave 4 and
# the Pale Bishop in wave 15.
def wave_cathedral(n):
    t = n - 1
    groups = [g for g in wave_3(n, 4, 6) if g[0] not in ("siege_ram", "black_knight", "fallen_marshal")]
    groups = [(e, c, i, min(l, 2), d) for (e, c, i, l, d) in groups]
    if n >= 2:
        groups.append(("chorister", 2 + t // 4, 5.0, [W, N, E][n % 3], 6))
    if n >= 4:
        groups.append(("inquisitor", ramp_in(2 + t // 3, n, 4, 6), 4.0, [E, W, N][n % 3], 10))
    if n == 15:
        groups.insert(0, ("pale_bishop", 1, 1.0, W, 14))
    return groups


WAVES_P = [(mult_3(n), wave_cathedral(n)) for n in range(1, 16)]
CHAPTERS = [("data/waves", WAVES, GOLD_TARGET, SPEED), ("data/waves/chapter_2", WAVES_2, GOLD_TARGET_2, SPEED_2),
            ("data/waves/chapter_3", WAVES_3, GOLD_TARGET_3, SPEED_3), ("data/waves/ember_orchard", WAVES_E, GOLD_TARGET, SPEED),
            ("data/waves/frostbound_pass", WAVES_F, GOLD_TARGET_2, SPEED_2), ("data/waves/sunless_mines", WAVES_M, GOLD_TARGET_3, SPEED_3),
            ("data/waves/bone_quarry", WAVES_Q, GOLD_TARGET, SPEED), ("data/waves/gloam_wood", WAVES_G, GOLD_TARGET_2, SPEED_2),
            ("data/waves/pale_cathedral", WAVES_P, GOLD_TARGET_3, SPEED_3)]

import os
for folder, WAVES, GOLD_TARGET, SPEED in CHAPTERS:
    os.makedirs(folder, exist_ok=True)
    print("== " + folder)
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
        open(folder + "/wave_%02d.tres" % n, "w").write("\n".join(out) + "\n")
        hp = sum(HP[g[0]] * g[1] for g in groups)
        count = sum(g[1] for g in groups)
        print("wave %2d: %3d enemies, %5d HP x%.2f = %6.0f, gold %4d x%.2f %s" % (n, count, hp, mult, hp * mult, gold, gmult, "" if hp > prev else "  <-- NOT RISING"))
        prev = hp
