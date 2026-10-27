# Dev tool (not shipped): writes the new biomes' enemy data (data/enemies/*.tres) and chapter data
# (data/run/<biome>/ battles, elites, boss, and data/run/chapter_<n>.tres) from the tables below, so a
# biome's content stays consistent and balance never means editing a dozen files. Waves come from
# tools/make_waves.py (data/waves/<folder>/wave_01..15.tres). Run from the project folder:
#   python3 tools/make_biome_data.py
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_events  # the biome events (M11) belong to each chapter's pool
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
    "cinder_ghoul": dict(role="grunt", display_name="Cinder Ghoul", max_health=30, move_speed=62.0, gold_reward=9, fortress_damage=10, hero_damage=10,
        body_radius=12.0, sprite_offset="Vector2(0, -10)", health_bar_y=-36.0, glow_color="Color(1, 0.55, 0.2, 1)",
        death="entities/enemies/ghoul_death_effect.tscn", frames="entities/enemies/cinder_ghoul_frames.tres", ability="entities/enemies/abilities/death_fire_ability.tscn",
        hint="burning ground where it falls: it hurts you, not only them."),
    "scarecrow": dict(role="tank", display_name="Scarecrow", max_health=120, move_speed=28.0, gold_reward=16, fortress_damage=12, hero_damage=14,
        attack_range=28.0, attack_windup=0.6, attack_cooldown=2.0, body_radius=16.0, sprite_offset="Vector2(0, -14)", health_bar_y=-52.0, knockback_taken=0.5,
        decoy=True, death="entities/enemies/brute_death_effect.tscn", frames="entities/enemies/scarecrow_frames.tres",
        hint="slow, and every tower aims at it first: it covers the others."),
    "pyre_warden": dict(role="boss", display_name="The Pyre Warden", max_health=2600, move_speed=28.0, gold_reward=130, fortress_damage=50, hero_damage=25,
        attack_range=32.0, attack_windup=0.7, attack_cooldown=2.4, body_radius=22.0, sprite_offset="Vector2(0, -22)", health_bar_y=-100.0, burn_taken=0.1, is_boss=True,
        glow_color="Color(1, 0.5, 0.2, 1)", death="entities/enemies/bosses/lich_death_effect.tscn", frames="entities/enemies/bosses/pyre_warden_frames.tres",
        ability="entities/enemies/bosses/pyre_summon.tscn"),
    "frost_wraith": dict(role="support", display_name="Frost Wraith", max_health=40, move_speed=40.0, gold_reward=18, fortress_damage=10, hero_damage=10,
        attack_range=26.0, body_radius=12.0, sprite_offset="Vector2(0, -12)", health_bar_y=-40.0, glow_color="Color(0.55, 0.85, 1, 1)",
        death="entities/enemies/cultist_death_effect.tscn", frames="entities/enemies/frost_wraith_frames.tres", ability="entities/enemies/abilities/chill_ability.tscn",
        hint="its cold ring silences towers and slows you. Kill it or step out."),
    "rime_brute": dict(role="tank", display_name="Rime Brute", max_health=170, move_speed=38.0, gold_reward=22, fortress_damage=22, hero_damage=18,
        attack_range=30.0, attack_windup=0.6, attack_cooldown=1.8, body_radius=17.0, sprite_offset="Vector2(0, -15)", health_bar_y=-54.0, burn_taken=0.7,
        knockback_taken=0.4, slow_immune=True, death="entities/enemies/brute_death_effect.tscn", frames="entities/enemies/rime_brute_frames.tres",
        hint="slows do nothing to it. Kill it with damage."),
    "winter_warden": dict(role="boss", display_name="The Winter Warden", max_health=3000, move_speed=28.0, gold_reward=140, fortress_damage=55, hero_damage=26,
        attack_range=32.0, attack_windup=0.7, attack_cooldown=2.4, body_radius=22.0, sprite_offset="Vector2(0, -22)", health_bar_y=-100.0, burn_taken=1.2, is_boss=True,
        glow_color="Color(0.55, 0.85, 1, 1)", death="entities/enemies/bosses/lich_death_effect.tscn", frames="entities/enemies/bosses/winter_warden_frames.tres",
        ability="entities/enemies/bosses/freeze_ability.tscn"),
    "burrower": dict(role="fast", display_name="Burrower", max_health=60, move_speed=58.0, gold_reward=12, fortress_damage=12, hero_damage=12,
        attack_range=22.0, attack_windup=0.3, attack_cooldown=1.1, body_radius=12.0, sprite_offset="Vector2(0, -10)", health_bar_y=-34.0,
        death="entities/enemies/hound_death_effect.tscn", frames="entities/enemies/burrower_frames.tres", ability="entities/enemies/abilities/burrow_ability.tscn",
        hint="digs under the field and comes up further on, shaking the tower nearest to it."),
    "lamp_wight": dict(role="support", display_name="Lamp Wight", max_health=50, move_speed=40.0, gold_reward=18, fortress_damage=10, hero_damage=10,
        attack_range=26.0, body_radius=12.0, sprite_offset="Vector2(0, -12)", health_bar_y=-42.0, glow_color="Color(1, 0.8, 0.4, 1)",
        death="entities/enemies/mire_priest_death_effect.tscn", frames="entities/enemies/lamp_wight_frames.tres", ability="entities/enemies/abilities/heal_ability.tscn",
        hint="its lantern mends the dead around it. Kill it first."),
    "deep_warden": dict(role="boss", display_name="The Deep Warden", max_health=3600, move_speed=28.0, gold_reward=150, fortress_damage=60, hero_damage=28,
        attack_range=32.0, attack_windup=0.7, attack_cooldown=2.4, body_radius=22.0, sprite_offset="Vector2(0, -22)", health_bar_y=-100.0, burn_taken=0.4, is_boss=True,
        death="entities/enemies/bosses/tollkeeper_death_effect.tscn", frames="entities/enemies/bosses/deep_warden_frames.tres", ability="entities/enemies/bosses/deep_summon.tscn"),
    "bone_hurler": dict(role="ranged", display_name="Bone Hurler", max_health=45, move_speed=42.0, gold_reward=14, fortress_damage=10, hero_damage=10,
        attack_range=26.0, body_radius=12.0, sprite_offset="Vector2(0, -12)", health_bar_y=-40.0, death="entities/enemies/cultist_death_effect.tscn",
        frames="entities/enemies/bone_hurler_frames.tres", ability="entities/enemies/abilities/shard_ability.tscn",
        hint="throws bone shards at your towers: the one it hits is silenced for a few seconds."),
    "rubble_brute": dict(role="tank", display_name="Rubble Brute", max_health=210, move_speed=36.0, gold_reward=24, fortress_damage=24, hero_damage=18,
        attack_range=30.0, attack_windup=0.6, attack_cooldown=1.8, body_radius=17.0, sprite_offset="Vector2(0, -15)", health_bar_y=-54.0, burn_taken=0.5,
        knockback_taken=0.2, death="entities/enemies/brute_death_effect.tscn", frames="entities/enemies/rubble_brute_frames.tres",
        hint="a wall of stone: it takes a lot to bring it down."),
    "quarry_colossus": dict(role="boss", display_name="The Quarry Colossus", max_health=2500, move_speed=30.0, gold_reward=120, fortress_damage=50, hero_damage=25,
        attack_range=30.0, attack_windup=0.6, attack_cooldown=2.4, body_radius=28.0, sprite_offset="Vector2(0, -24)", health_bar_y=-110.0, burn_taken=0.3, is_boss=True,
        death="entities/enemies/bosses/colossus_death_effect.tscn", frames="entities/enemies/bosses/quarry_colossus_frames.tres", ability="entities/enemies/bosses/charge_ability.tscn"),
    "stalker": dict(role="fast", display_name="Stalker", max_health=55, move_speed=70.0, gold_reward=14, fortress_damage=12, hero_damage=12,
        attack_range=22.0, attack_windup=0.3, attack_cooldown=1.0, body_radius=12.0, sprite_offset="Vector2(0, -10)", health_bar_y=-34.0, stealth_range=90.0,
        death="entities/enemies/hound_death_effect.tscn", frames="entities/enemies/stalker_frames.tres",
        hint="towers cannot see it until it is close: keep the hero and the towers near the road."),
    "hollow_treant": dict(role="tank", display_name="Hollow Treant", max_health=260, move_speed=34.0, gold_reward=26, fortress_damage=22, hero_damage=18,
        attack_range=30.0, attack_windup=0.7, attack_cooldown=2.0, body_radius=18.0, sprite_offset="Vector2(0, -16)", health_bar_y=-58.0, burn_taken=1.4,
        knockback_taken=0.3, death="entities/enemies/brute_death_effect.tscn", frames="entities/enemies/hollow_treant_frames.tres", ability="entities/enemies/abilities/regen_ability.tscn",
        hint="mends 2 HP a second: burst it down. It burns well."),
    "hollow_stag": dict(role="boss", display_name="The Hollow Stag", max_health=3100, move_speed=32.0, gold_reward=140, fortress_damage=55, hero_damage=26,
        attack_range=32.0, attack_windup=0.7, attack_cooldown=2.4, body_radius=24.0, sprite_offset="Vector2(0, -22)", health_bar_y=-104.0, burn_taken=0.8, is_boss=True,
        death="entities/enemies/bosses/gravelord_death_effect.tscn", frames="entities/enemies/bosses/hollow_stag_frames.tres", ability="entities/enemies/bosses/root_ability.tscn"),
    "chorister": dict(role="support", display_name="Chorister", max_health=45, move_speed=40.0, gold_reward=18, fortress_damage=10, hero_damage=10,
        attack_range=26.0, body_radius=12.0, sprite_offset="Vector2(0, -12)", health_bar_y=-42.0, glow_color="Color(1, 0.92, 0.6, 1)",
        death="entities/enemies/mire_priest_death_effect.tscn", frames="entities/enemies/chorister_frames.tres", ability="entities/enemies/abilities/resist_aura_ability.tscn",
        hint="its song shields the dead around it: they take 20% less damage. Kill it first."),
    "inquisitor": dict(role="tank", display_name="Inquisitor", max_health=150, move_speed=44.0, gold_reward=20, fortress_damage=16, hero_damage=16,
        attack_range=26.0, attack_windup=0.45, attack_cooldown=1.5, body_radius=13.0, sprite_offset="Vector2(0, -11)", health_bar_y=-38.0, knockback_taken=0.5,
        death="entities/enemies/shieldbearer_death_effect.tscn", frames="entities/enemies/inquisitor_frames.tres", ability="entities/enemies/abilities/mark_hero_ability.tscn",
        hint="marks you: while marked you take 30% more damage. Step out of its ring."),
    "pale_bishop": dict(role="boss", display_name="The Pale Bishop", max_health=4000, move_speed=28.0, gold_reward=170, fortress_damage=65, hero_damage=30,
        attack_range=32.0, attack_windup=0.7, attack_cooldown=2.4, body_radius=22.0, sprite_offset="Vector2(0, -22)", health_bar_y=-100.0, burn_taken=0.6, is_boss=True,
        glow_color="Color(0.85, 0.8, 1, 1)", death="entities/enemies/bosses/lich_death_effect.tscn", frames="entities/enemies/bosses/pale_bishop_frames.tres",
        ability="entities/enemies/bosses/ward_ability.tscn"),
}
# Biome unlocks on the War Room's board (M10): the first biome of each tier is free.
UNLOCKS = [
    dict(id="biome_bone_quarry", name="The Bone Quarry", chapter="bone_quarry", cost=60, first="boss:The Lich Warden",
         text="A new road for chapter 1: a quarry where boulders block the roads."),
    dict(id="biome_gloam_wood", name="The Gloam Wood", chapter="gloam_wood", cost=90, first="chapter:Chapter 2 reached",
         text="A new road for chapter 2: a dark wood where towers see less unless lamps light them."),
    dict(id="biome_pale_cathedral", name="The Pale Cathedral", chapter="pale_cathedral", cost=120, first="chapter:Chapter 3 reached",
         text="A new road for chapter 3: a cathedral whose altars heal the dead."),
    dict(id="biome_ember_orchard", name="The Ember Orchard", chapter="ember_orchard", cost=40, first="boss:The Lich Warden",
         text="A new road for chapter 1: a burned orchard where dry grass catches fire."),
    dict(id="biome_frostbound_pass", name="The Frostbound Pass", chapter="frostbound_pass", cost=60, first="chapter:Chapter 2 reached",
         text="A new road for chapter 2: a mountain pass where the gale shortens your towers' range."),
    dict(id="biome_sunless_mines", name="The Sunless Mines", chapter="sunless_mines", cost=90, first="chapter:Chapter 3 reached",
         text="A new road for chapter 3: mine tunnels where the ceiling falls in."),
]
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
    dict(file="ember_orchard", folder="ember_orchard", id="ember_orchard", name="The Ember Orchard", tier=1, level="levels/ember_orchard.tscn", waves="ember_orchard",
         scale=1.0, extra=dict(fight_health_scale=0.6),
         elites={3: ("gravelord", 6.0, 1.0), 4: ("gravelord", 6.0, 1.0), 5: ("colossus", 12.0, 1.0), 6: ("colossus", 12.0, 1.0)},
         blurb="A burned orchard of blackened trees and dry, yellow grass. Three roads wind through it.",
         mechanic="Dry grass: patches catch fire from burning ground or burning enemies, and the fire hurts you as well as them.",
         note="easy, and fire is a weapon here: a Brazier lights the grass"),
    dict(file="frostbound_pass", folder="frostbound_pass", id="frostbound_pass", name="The Frostbound Pass", tier=2, level="levels/frostbound_pass.tscn", waves="frostbound_pass",
         scale=1.0, extra=dict(fight_health_scale=1.5, elite_weight=18.0),
         elites={3: ("colossus", 10.0, 1.5), 4: ("colossus", 10.0, 1.5), 5: ("lich", 10.0, 1.4), 6: ("lich", 10.0, 1.4)},
         blurb="A mountain pass under a grey sky. One long, winding road and two short ones.",
         mechanic="Blizzard: now and then a gale blows for 8 s: your towers lose a fifth of their range and the dead walk faster.",
         note="medium: slows are weaker against the Rime Brutes, and the long road gives time"),
    dict(file="sunless_mines", folder="sunless_mines", id="sunless_mines", name="The Sunless Mines", tier=3, level="levels/sunless_mines.tscn", waves="sunless_mines",
         scale=1.0, extra=dict(fight_health_scale=2.0, elite_weight=18.0),
         elites={3: ("colossus", 10.0, 1.8), 4: ("colossus", 10.0, 1.8), 5: ("lich", 10.0, 1.6), 6: ("lich", 10.0, 1.6)},
         blurb="Mine tunnels lit by glowing crystal. Three roads, and the ground is not safe.",
         mechanic="Cave-ins: a tunnel falls in now and then (a warning first): the rubble holds the dead in place for 8 s.",
         note="hard: Burrowers skip the road and Lamp Wights heal the pack"),
    dict(file="bone_quarry", folder="bone_quarry", id="bone_quarry", name="The Bone Quarry", tier=1, level="levels/bone_quarry.tscn", waves="bone_quarry",
         scale=1.0, extra=dict(fight_health_scale=0.5),
         elites={3: ("gravelord", 6.0, 1.0), 4: ("gravelord", 6.0, 1.0), 5: ("colossus", 12.0, 1.0), 6: ("colossus", 12.0, 1.0)},
         blurb="A quarry of cut stone and heaped bones. Two broad roads run down and merge before the fortress.",
         mechanic="Rockfall: boulders crash onto the roads now and then (a warning first) and block them for 8 s: the dead queue up behind.",
         note="easy: Bone Hurlers silence your towers one at a time"),
    dict(file="gloam_wood", folder="gloam_wood", id="gloam_wood", name="The Gloam Wood", tier=2, level="levels/gloam_wood.tscn", waves="gloam_wood",
         scale=1.0, extra=dict(fight_health_scale=1.45, elite_weight=18.0),
         elites={3: ("colossus", 10.0, 1.5), 4: ("colossus", 10.0, 1.5), 5: ("lich", 10.0, 1.4), 6: ("lich", 10.0, 1.4)},
         blurb="A dark wood of narrow roads. Four of them reach the fortress, and three lamps light the way.",
         mechanic="Gloom: a tower sees only 70% of its range unless a lamp stands near it; Stalkers hide until they are close.",
         note="medium: build near the lamps, and keep the hero near the roads"),
    dict(file="pale_cathedral", folder="pale_cathedral", id="pale_cathedral", name="The Pale Cathedral", tier=3, level="levels/pale_cathedral.tscn", waves="pale_cathedral",
         scale=1.0, extra=dict(fight_health_scale=2.0, elite_weight=18.0),
         elites={3: ("colossus", 10.0, 1.8), 4: ("colossus", 10.0, 1.8), 5: ("lich", 10.0, 1.6), 6: ("lich", 10.0, 1.6)},
         blurb="A ruined cathedral: three aisles lead to the fortress's door, and altars glow along them.",
         mechanic="Consecration: altars mend the dead near them unless burning ground covers them. Fire puts the light out.",
         note="hard: Choristers shield the dead and Inquisitors mark you"),
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
    for e in EVENTS + SHRINES + (c.get("own_events", []) + make_events.BY_CHAPTER.get(c["id"], [])):
        ext.append('[ext_resource type="Resource" path="res://data/events/%s.tres" id="ev_%s"]' % (e, e))
    body = ['', '[resource]', 'script = ExtResource("1_chapter")', 'id = &"%s"' % c["id"], 'display_name = "%s"' % c["name"], 'tier = %d' % c["tier"], 'level_scene = ExtResource("2_level")',
            'blurb = "%s"' % c["blurb"], 'mechanic_text = "%s"' % c["mechanic"], 'difficulty_note = "%s"' % c["note"],
            'battles = Array[ExtResource("s_enc")]([%s])' % ", ".join('ExtResource("b%d")' % r for r in range(1, 7)),
            'elites = Array[ExtResource("s_enc")]([%s])' % ", ".join('ExtResource("e%d")' % r for r in c["elites"]),
            'affixes = Array[ExtResource("s_affix")]([%s])' % ", ".join('ExtResource("a_%s")' % a for a in AFFIXES), 'boss = ExtResource("boss")']
    for k, v in c["extra"].items():
        body.append("%s = %s" % (k, fmt(v)))
    body.append('events = Array[ExtResource("s_event")]([%s])' % ", ".join('ExtResource("ev_%s")' % e for e in EVENTS + (c.get("own_events", []) + make_events.BY_CHAPTER.get(c["id"], []))))
    body.append('shrines = Array[ExtResource("s_event")]([%s])' % ", ".join('ExtResource("ev_%s")' % e for e in SHRINES))
    open("data/run/%s.tres" % c["file"], "w").write("\n".join(ext + body) + "\n")


def write_unlock(u):
    out = ['[gd_resource type="Resource" script_class="UnlockData" format=3]', '', '[ext_resource type="Script" path="res://resources/unlock_data.gd" id="1_unlock"]',
           '[ext_resource type="Script" path="res://resources/chapter_data.gd" id="s_chapter"]',
           '[ext_resource type="Resource" path="res://data/run/%s.tres" id="r_chapter"]' % u["chapter"], '', '[resource]', 'script = ExtResource("1_unlock")',
           'id = &"%s"' % u["id"], 'display_name = "%s"' % u["name"], 'description = "%s"' % u["text"], 'cost = %d' % u["cost"], 'seller = &"ilse"',
           'requires_first = "%s"' % u["first"], 'biomes = Array[ExtResource("s_chapter")]([ExtResource("r_chapter")])']
    open("data/meta/unlocks/%s.tres" % u["id"], "w").write("\n".join(out) + "\n")


if __name__ == "__main__":
    for eid, spec in ENEMIES.items():
        write_enemy(eid, spec)
    for c in CHAPTERS:
        write_chapter(c)
    for u in UNLOCKS:
        write_unlock(u)
    print("wrote %d enemies, %d chapters" % (len(ENEMIES), len(CHAPTERS)))
