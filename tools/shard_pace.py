#!/usr/bin/env python3
"""Dev tool (not shipped): estimates how many runs a player needs to buy the unlocks (M8 meta).

Reads the shard rates from systems/meta_progress.gd and the prices from data/meta/unlocks/*.tres,
then plays two made-up players' run sequences (a typical one, and a slower one with more chapter-1
losses) and prints the run on which each could have bought the key unlocks and everything.
Run: python3 tools/shard_pace.py [--key=brazier,ballista,...]
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
KEY = ["brazier", "ballista", "evolutions_archer", "evolutions_cannon", "relics_1"]

# A run: (chapter reached, battles won in ch.1, elites ch.1, ch.1 boss beaten, battles ch.2, elites ch.2, won)
RUNS = {
    "c1early": (1, 3, 0, 0, 0, 0, 0),  # falls around row 4
    "c1mid": (1, 4, 1, 0, 0, 0, 0),  # around row 6
    "c1boss": (1, 5, 1, 0, 0, 0, 0),  # at the boss
    "c2early": (2, 5, 1, 1, 2, 0, 0),
    "c2mid": (2, 5, 1, 1, 3, 1, 0),
    "c2late": (2, 5, 1, 1, 5, 1, 0),
    "win": (2, 5, 1, 1, 5, 1, 1),
}
TYPICAL = ("c1early c1mid c1mid c1boss c1mid c2early c1boss c2early c2mid c1mid c2mid c2early c2mid c2late c2mid "
           "win c2mid c2late c2early c2mid c2late win c2mid c2late c2mid win c2late c2mid c2late win").split()
SLOW = ("c1early c1early c1mid c1mid c1mid c1boss c1mid c1boss c2early c1mid c1boss c2early c2mid c1boss c2mid "
        "c2early c2mid c2late c2mid c2mid c2late c2mid win c2mid c2late c2mid c2late c2mid win c2late").split()


def rates() -> dict:
    text = (ROOT / "systems/meta_progress.gd").read_text()
    def const(name: str) -> str:
        return re.search(rf"const {name}: [^=]+= (.+)", text).group(1)
    return {"battle": int(const("BATTLE")), "elite": int(const("ELITE")), "boss": [int(x) for x in re.findall(r"\d+", const("BOSS"))],
            "chapter": int(const("CHAPTER_CLEARED")), "win": int(const("RUN_WON")), "first": int(const("FIRST_TIME"))}


def prices() -> dict:
    found = {}
    for path in (ROOT / "data/meta/unlocks").glob("*.tres"):
        found[path.stem] = int(re.search(r"^cost = (\d+)", path.read_text(), re.M).group(1))
    return found


def shards(run: tuple, r: dict, firsts: set) -> int:
    chapter, b1, e1, boss1, b2, e2, won = run
    total = (b1 + b2) * r["battle"] + (e1 + e2) * r["elite"]
    if boss1:
        total += r["boss"][0] + r["chapter"]
    if won:
        total += r["boss"][1] + r["chapter"] + r["win"]
    for first, earned in (("boss1", boss1), ("chapter2", chapter >= 2), ("boss2", won)):
        if earned and first not in firsts:
            firsts.add(first)
            total += r["first"]
    return total


def first_run_reaching(sequence: list, r: dict, target: int) -> str:
    bank, firsts = 0, set()
    for i, kind in enumerate(sequence, 1):
        bank += shards(RUNS[kind], r, firsts)
        if bank >= target:
            return str(i)
    return f"> {len(sequence)}"


def main() -> None:
    key = KEY
    for arg in sys.argv[1:]:
        if arg.startswith("--key="):
            key = arg.split("=", 1)[1].split(",")
    r, p = rates(), prices()
    key_cost, all_cost = sum(p[k] for k in key), sum(p.values())
    print(f"rates: {r}")
    print("a run pays: " + ", ".join(f"{k} {shards(v, r, set())}" for k, v in RUNS.items()) + " (first time)")
    print(f"key unlocks ({', '.join(key)}): {key_cost} shards; everything: {all_cost}")
    for name, sequence in (("typical", TYPICAL), ("slow", SLOW)):
        print(f"{name:8} player: key unlocks by run {first_run_reaching(sequence, r, key_cost)}, "
              f"everything by run {first_run_reaching(sequence, r, all_cost)}")


if __name__ == "__main__":
    main()
