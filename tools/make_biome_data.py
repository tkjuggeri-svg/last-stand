# Dev tool (not shipped): writes the new biomes' enemy data (data/enemies/*.tres) and chapter data
# (data/run/<biome>/ battles, elites, boss, and data/run/chapter_<n>.tres) from the tables below, so a
# biome's content stays consistent and balance never means editing a dozen files. Waves come from
# tools/make_waves.py (data/waves/<folder>/wave_01..15.tres). Run from the project folder:
#   python3 tools/make_biome_data.py
import os

ROLE = {"grunt": 0, "fast": 1, "tank": 2, "ranged": 3, "support": 4, "splitter": 5, "boss": 6}
# id -> fields. death/frames/ability are resource paths; the rest are EnemyData fields (defaults left out).
ENEMIES = {
    "siege_ram": dict(role="tank", display_name="Siege Ram", max_health=300, move_speed=32.0, gold_reward=24, fortress_damage=45, hero_damage=22,
        attack_range=30.0, attack_windup=0.7, attack_cooldown=2.2, body_radius=18.0, sprite_offset="Vector2(0, -16)", health_bar_y=-58.0,
        burn_taken=0.4, knockback_taken=0.3, death="entities/enemies/brute_death_effect.tscn", frames="entities/enemies/siege_ram_frames.tres",
        hint="slow and heavy: it hits the fortress 3 times as hard as a Brute. Stop it on the road."),
    "black_knight": dict(role="tank", display_name="Black Knight", max_health=160, move_speed=46.0, gold_reward=18, fortress_damage=20, hero_damage=16,
        attack_range=26.0, attack_windup=0.4, attack_cooldown=1.4, body_radius=13.0, sprite_offset="Vector2(0, -11)", health_bar_y=-38.0,
        knockback_taken=0.4, shield_arc=160.0, death="entities/enemies/shieldbearer_death_effect.tscn", frames="entities/enemies/black_knight_frames.tres",
        hint="its shield is wider than the Shieldbearer's: tower shots from the front are blocked."),
    "fallen_marshal": dict(role="boss", display_name="The Fallen Marshal", max_health=3400, move_speed=34.0, gold_reward=150, fortress_damage=60, hero_damage=28,
        attack_range=30.0, attack_windup=0.6, attack_cooldown=2.2, body_radius=28.0, sprite_offset="Vector2(0, -24)", health_bar_y=-110.0,
        burn_taken=0.35, shield_arc=100.0, is_boss=True, death="entities/enemies/bosses/colossus_death_effect.tscn",
        frames="entities/enemies/bosses/fallen_marshal_frames.tres", ability="entities/enemies/bosses/charge_ability.tscn"),
}
EVENTS = ["gravediggers_cart", "wounded_knight", "flooded_crypt", "the_tinker", "night_fog", "drowned_reliquary"]
SHRINES = ["shrine_blood", "shrine_ash", "shrine_coins", "shrine_hollow_walls", "shrine_whispers"]
AFFIXES = ["swift", "warded", "swarming", "siege", "ironclad"]
# folder (under data/run), chapter file, id, name, level, waves folder, tier, scale, extras, elite leaders by row, boss enemy, text
CHAPTERS = [
    dict(file="chapter_3", folder="ashen_keep", id="ashen_keep", name="The Ashen Keep", tier=3, level="levels/ashen_keep.tscn", waves="chapter_3",
         scale=1.0, extra=dict(fight_health_scale=2.0, elite_weight=18.0, leave_refund=0.4),
         elites={3: ("colossus", 10.0, 1.8), 4: ("colossus", 10.0, 1.8), 5: ("lich", 10.0, 1.6), 6: ("lich", 10.0, 1.6)},
         blurb="A burned fortress, the walls still falling. Four roads run through the ruin.",
         mechanic="Falling walls: a wall section collapses now and then (a warning first), hurting what is below and burning out the nearest slot for the fight.",
         note="the hardest road: the dead are tougher from the first wave"),
]


def fmt(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, float):
        return repr(v)
    if isinstance(v, str) and v.startswith(("Vector2", "Color")):
        return v
    if isinstance(v, str):
        return '"%s"' % v.replace('"', '\\"')
    return str(v)


def write_enemy(eid, spec):
    spec = dict(spec)
    death, frames, ability = spec.pop("death"), spec.pop("frames"), spec.pop("ability", None)
    out = ['[gd_resource type="Resource" script_class="EnemyData" format=3]', '', '[ext_resource type="Script" path="res://resources/enemy_data.gd" id="1_data"]',
           '[ext_resource type="PackedScene" path="res://%s" id="2_death"]' % death, '[ext_resource type="SpriteFrames" path="res://%s" id="3_frames"]' % frames]
    if ability:
        out.append('[ext_resource type="PackedScene" path="res://%s" id="4_ability"]' % ability)
    out += ['', '[resource]', 'script = ExtResource("1_data")', 'role = %d' % ROLE[spec.pop("role")]]
    for k, v in spec.items():
        out.append("%s = %s" % (k, fmt(v)))
    out += ['death_effect = ExtResource("2_death")', 'sprite_frames = ExtResource("3_frames")']
    if ability:
        out.append('ability = ExtResource("4_ability")')
    open("data/enemies/%s.tres" % eid, "w").write("\n".join(out) + "\n")


def write_encounter(path, folder, row, wave_numbers, leader=None):
    out = ['[gd_resource type="Resource" script_class="EncounterData" format=3]', '', '[ext_resource type="Script" path="res://resources/encounter_data.gd" id="1_enc"]',
           '[ext_resource type="Script" path="res://resources/wave_data.gd" id="s_wave"]']
    for i, n in enumerate(wave_numbers):
        out.append('[ext_resource type="Resource" path="res://data/waves/%s/wave_%02d.tres" id="w%d"]' % (folder, n, i))
    if leader:
        out.append('[ext_resource type="Resource" path="res://data/enemies/%s.tres" id="l_leader"]' % leader[0])
    out += ['', '[resource]', 'script = ExtResource("1_enc")', 'row = %d' % row,
            'waves = Array[ExtResource("s_wave")]([%s])' % ", ".join('ExtResource("w%d")' % i for i in range(len(wave_numbers)))]
    if leader:
        out += ['leader = ExtResource("l_leader")', 'leader_delay = %s' % repr(leader[1]), 'leader_health_scale = %s' % repr(leader[2])]
    if row == 0:
        out.append("strip_bosses = false")
    open(path, "w").write("\n".join(out) + "\n")


def write_chapter(c):
    d = "data/run/%s" % c["folder"]
    os.makedirs(d, exist_ok=True)
    for r in range(1, 7):
        write_encounter("%s/battle_%d.tres" % (d, r), c["waves"], r, [2 * r - 1, 2 * r])
    for r, leader in c["elites"].items():
        write_encounter("%s/elite_%d.tres" % (d, r), c["waves"], r, [2 * r - 1, 2 * r], leader)
    write_encounter("%s/boss.tres" % d, c["waves"], 0, [13, 14, 15])
    ext = ['[gd_resource type="Resource" script_class="ChapterData" format=3]', '', '[ext_resource type="Script" path="res://resources/chapter_data.gd" id="1_chapter"]',
           '[ext_resource type="PackedScene" path="res://%s" id="2_level"]' % c["level"], '[ext_resource type="Script" path="res://resources/encounter_data.gd" id="s_enc"]',
           '[ext_resource type="Script" path="res://resources/affix_data.gd" id="s_affix"]', '[ext_resource type="Script" path="res://resources/event_data.gd" id="s_event"]']
    for r in range(1, 7):
        ext.append('[ext_resource type="Resource" path="res://%s/battle_%d.tres" id="b%d"]' % (d, r, r))
    for r in c["elites"]:
        ext.append('[ext_resource type="Resource" path="res://%s/elite_%d.tres" id="e%d"]' % (d, r, r))
    ext.append('[ext_resource type="Resource" path="res://%s/boss.tres" id="boss"]' % d)
    for a in AFFIXES:
        ext.append('[ext_resource type="Resource" path="res://data/affixes/%s.tres" id="a_%s"]' % (a, a))
    for e in EVENTS + SHRINES + c.get("own_events", []):
        ext.append('[ext_resource type="Resource" path="res://data/events/%s.tres" id="ev_%s"]' % (e, e))
    body = ['', '[resource]', 'script = ExtResource("1_chapter")', 'id = &"%s"' % c["id"], 'display_name = "%s"' % c["name"], 'tier = %d' % c["tier"], 'level_scene = ExtResource("2_level")',
            'blurb = "%s"' % c["blurb"], 'mechanic_text = "%s"' % c["mechanic"], 'difficulty_note = "%s"' % c["note"],
            'battles = Array[ExtResource("s_enc")]([%s])' % ", ".join('ExtResource("b%d")' % r for r in range(1, 7)),
            'elites = Array[ExtResource("s_enc")]([%s])' % ", ".join('ExtResource("e%d")' % r for r in c["elites"]),
            'affixes = Array[ExtResource("s_affix")]([%s])' % ", ".join('ExtResource("a_%s")' % a for a in AFFIXES), 'boss = ExtResource("boss")']
    for k, v in c["extra"].items():
        body.append("%s = %s" % (k, fmt(v)))
    body.append('events = Array[ExtResource("s_event")]([%s])' % ", ".join('ExtResource("ev_%s")' % e for e in EVENTS + c.get("own_events", [])))
    body.append('shrines = Array[ExtResource("s_event")]([%s])' % ", ".join('ExtResource("ev_%s")' % e for e in SHRINES))
    open("data/run/%s.tres" % c["file"], "w").write("\n".join(ext + body) + "\n")


if __name__ == "__main__":
    for eid, spec in ENEMIES.items():
        write_enemy(eid, spec)
    for c in CHAPTERS:
        write_chapter(c)
    print("wrote %d enemies, %d chapters" % (len(ENEMIES), len(CHAPTERS)))
