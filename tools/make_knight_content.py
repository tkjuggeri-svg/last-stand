#!/usr/bin/env python3
"""Writes the Knight's extra cards and relics (M13 follow-up) into data/upgrades and data/relics. Dev only:
edit the tables and rerun `python3 tools/make_knight_content.py`; the hero's lists are in data/heroes/knight.tres."""
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
CARDS = [  # id, name, description, category (0 hero, 1 towers, 2 fortress), stat, flat, tags
    ("shield_bash", "Shield Bash", "Your dash knocks the enemies it passes back 30 px.", 0, "hero.dash_bash", 30.0, ["blade"]),
    ("oathkeeper", "Oathkeeper", "Your sword lands one extra hit on bosses with every swing.", 0, "hero.boss_hits", 1.0, ["blade"]),
    ("rally", "Rally", "Towers within 150 px of you fire 10% faster.", 1, "hero.rally", 0.10, ["blade", "ranged"]),
    ("iron_will", "Iron Will", "Bulwark holds firmer: swinging shrugs off 45% of a hit instead of 25%.", 2, "hero.bulwark", 0.20, ["fortress"]),
]
RELICS = [  # id, name, description, category, rule, tags
    ("crown_of_thorns", "Crown of Thorns", "Enemies that hit you take 8 damage back.", 0, "crown_of_thorns", ["blade"]),
    ("banner_of_the_last_keep", "Banner of the Last Keep", "While you stand, the fortress takes 15% less damage.", 2, "banner_of_the_last_keep", ["fortress"]),
]


def tags(items):
    return "tags = Array[StringName]([%s])" % ", ".join('&"%s"' % t for t in items)


def write(path, text):
    with open(os.path.join(ROOT, path), "w") as f:
        f.write(text)


for cid, name, desc, cat, stat, flat, tg in CARDS:
    write("data/upgrades/%s.tres" % cid, f"""[gd_resource type="Resource" script_class="UpgradeData" format=3]

[ext_resource type="Texture2D" path="res://assets/sprites/ui/upgrades/{cid}.png" id="1_icon"]
[ext_resource type="Script" path="res://resources/stat_modifier.gd" id="2_mod"]
[ext_resource type="Script" path="res://resources/upgrade_data.gd" id="3_up"]

[sub_resource type="Resource" id="Mod_0"]
script = ExtResource("2_mod")
stat = &"{stat}"
flat = {flat}

[resource]
script = ExtResource("3_up")
id = &"{cid}"
display_name = "{name}"
description = "{desc}"
icon = ExtResource("1_icon")
category = {cat}
stackable = false
modifiers = Array[ExtResource("2_mod")]([SubResource("Mod_0")])
{tags(tg)}
""")
for rid, name, desc, cat, rule, tg in RELICS:
    write("data/relics/%s.tres" % rid, f"""[gd_resource type="Resource" script_class="RelicData" format=3]

[ext_resource type="Texture2D" path="res://assets/sprites/ui/relics/{rid}.png" id="1_icon"]
[ext_resource type="Script" path="res://resources/relic_data.gd" id="3_up"]

[resource]
script = ExtResource("3_up")
rule = &"{rule}"
price = 260
id = &"{rid}"
display_name = "{name}"
description = "{desc}"
icon = ExtResource("1_icon")
category = {cat}
rarity = 1
stackable = false
{tags(tg)}
""")
print("wrote", len(CARDS), "cards and", len(RELICS), "relics")
