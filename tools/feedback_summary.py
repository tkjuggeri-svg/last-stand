#!/usr/bin/env python3
# Dev tool (not shipped): reads in-game feedback reports (folders with note.txt, state.json and maybe
# screenshot.png, written by the feedback key) and prints a Markdown summary: every report with its note
# and the run's state, then totals by build, chapter and screen.
#   python3 tools/feedback_summary.py [folder ...]
# A folder may be one report, a folder of reports (a tester's "feedback" folder), or a folder holding
# several testers' unzipped folders. With no folder: this machine's own reports (Linux user data).
import json
import os
import sys
from collections import Counter

DEFAULT = os.path.expanduser("~/.local/share/godot/app_userdata/The Last Stand/feedback")


def reports(paths):
    found = []
    for path in paths:
        for root, _dirs, files in os.walk(path):
            if "note.txt" in files or "state.json" in files:
                found.append(root)
    return sorted(set(found))


def load(folder):
    note = ""
    state = {}
    if os.path.exists(os.path.join(folder, "note.txt")):
        note = open(os.path.join(folder, "note.txt"), encoding="utf-8").read().strip()
    if os.path.exists(os.path.join(folder, "state.json")):
        try:
            state = json.load(open(os.path.join(folder, "state.json"), encoding="utf-8"))
        except json.JSONDecodeError:
            state = {"error": "state.json could not be read"}
    shot = os.path.join(folder, "screenshot.png")
    return note, state, shot if os.path.exists(shot) else ""


def where(state):
    node = state.get("node") or {}
    parts = ["chapter %s" % state.get("chapter", "?")]
    if node:
        parts.append("row %s %s" % (node.get("row", "?"), node.get("kind", "")))
        if node.get("event"):
            parts.append("(%s)" % node["event"])
    if "wave" in state:
        parts.append("wave %s/%s %s" % (state.get("wave"), state.get("waves_in_fight", "?"), state.get("phase", "")))
    parts.append("on %s" % state.get("screen", "?"))
    return ", ".join(parts)


def towers(state):
    items = []
    for t in state.get("towers", []):
        name = t.get("evolution") or t.get("tower", "?")
        items.append("%s L%s (slot %s)" % (name, t.get("level", "?"), t.get("slot", "?")))
    return ", ".join(items) or "none"


def main():
    paths = sys.argv[1:] or [DEFAULT]
    folders = reports(paths)
    if not folders:
        print("No feedback reports found in: %s" % ", ".join(paths))
        return
    print("# Feedback: %d reports\n" % len(folders))
    builds, chapters, screens = Counter(), Counter(), Counter()
    for folder in folders:
        note, state, shot = load(folder)
        builds[state.get("build", "?")] += 1
        chapters["chapter %s" % state.get("chapter", "?")] += 1
        screens[state.get("screen", "?")] += 1
        fortress = state.get("fortress") or {}
        lives = state.get("lives") or {}
        cards = state.get("cards") or {}
        print("## %s" % os.path.basename(folder))
        print("> %s\n" % (note.replace("\n", "\n> ") or "(no note)"))
        print("- **Where:** %s" % where(state))
        print("- **Build** %s, **seed** %s (replay: `-- --seed=%s`), level %s" % (state.get("build", "?"), state.get("seed", "?"),
                                                                            state.get("seed", "?"), state.get("level", "?")))
        print("- **Gold** %s, **fortress** %s/%s, **lives** %s/%s" % (state.get("gold", "?"), fortress.get("hp", "?"), fortress.get("max", "?"),
                                                                   lives.get("left", "?"), lives.get("max", "?")))
        print("- **Towers:** %s" % towers(state))
        print("- **Cards:** %s" % (", ".join("%s%s" % (k, " x%d" % v if v > 1 else "") for k, v in cards.items()) or "none"))
        print("- **Relics:** %s" % (", ".join(state.get("relics", [])) or "none"))
        if state.get("next_fight_twists"):
            print("- **Twists waiting:** %s" % ", ".join(state["next_fight_twists"]))
        print("- **Folder:** `%s`%s\n" % (folder, "  (screenshot.png)" if shot else "  (no screenshot)"))
    print("## Totals")
    print("- **By build:** %s" % ", ".join("%s: %d" % kv for kv in builds.most_common()))
    print("- **By chapter:** %s" % ", ".join("%s: %d" % kv for kv in chapters.most_common()))
    print("- **By screen:** %s" % ", ".join("%s: %d" % kv for kv in screens.most_common()))


if __name__ == "__main__":
    main()
