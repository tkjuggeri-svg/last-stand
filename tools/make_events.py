#!/usr/bin/env python3
"""Writes the biome events (M11 stage 2): two per biome, data/events/<id>.tres, and adds them to each chapter's
event pool (the nine chapter files; make_biome_data.py imports BY_CHAPTER so a rerun keeps them). Dev only:
edit the table and rerun `python3 tools/make_events.py`. Effects use only what EventResolver already knows."""
import os, re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
T = dict(GOLD=0, GOLD_MULTIPLY=1, FORTRESS_DAMAGE=2, GRANT_UPGRADE=3, UPGRADE_CHOICE=4, LOSE_LIFE=5, LOSE_LAST_UPGRADE=6,
         FREE_TOWER_LEVEL=7, DESTROY_BEST_TOWER=8, FREE_EVOLUTION=9, NEXT_FIGHTS_AFFIX=10, MERCHANT_PRICES=11, EXTRA_FIGHT=12, RELIC_CHOICE=13)
NEED = dict(NOTHING=0, GOLD=1, TOWER=2, UPGRADABLE_TOWER=3, UPGRADE=4, SPARE_LIFE=5)


def fx(kind, amount=0, factor=1.0, rare=False, upgrade=None, affix=None):
    return dict(type=T[kind], amount=amount, factor=factor, rare=rare, upgrade=upgrade, affix=affix)


def ch(label, outcome, result, effects=(), need="NOTHING", cost=0, chance=1.0, fail=(), fail_text=""):
    return dict(label=label, outcome=outcome, result=result, effects=list(effects), need=NEED[need], cost=cost, chance=chance,
                fail=list(fail), fail_text=fail_text)


WALK = ch("Walk on", "Nothing happens.", "You leave it behind you.")

# chapter id -> [(event id, title, text, rare, [choices])]
TABLE = {
    "crypt_road": [
        ("pilgrims_cairn", "The Pilgrims' Cairn", "A heap of offerings, coins and candle stubs, piled under a leaning stone. Some of it is still warm.", False, [
            ch("Take the coins", "+60 gold, but the next fight's dead are ironclad.", "The coins are cold. Behind you, the cairn rattles.",
               [fx("GOLD", 60), fx("NEXT_FIGHTS_AFFIX", 1, affix="ironclad")]),
            ch("Add a coin", "Costs 30 gold. An upgrade choice of 3 cards.", "The stone seems to lean toward you, just a little.",
               [fx("UPGRADE_CHOICE", 3)], "GOLD", 30), WALK]),
        ("the_sexton", "The Sexton", "A sexton in a stained cassock digs a grave in the middle of the road. It is not for anyone yet.", False, [
            ch("Help him dig", "60% chance: +100 gold from what you turn up. Otherwise the fortress takes 8 damage.", "A coffin, and a ring in it. He pretends not to see.",
               [fx("GOLD", 100)], chance=0.6, fail=[fx("FORTRESS_DAMAGE", 8)], fail_text="Something wakes in the hole. The fortress pays for it."),
            ch("Pay for the Rites", "Costs 40 gold. Repair the fortress by 30%.", "He mumbles over the walls, and something in them mends.",
               [fx("GRANT_UPGRADE", upgrade="repairs")], "GOLD", 40), WALK]),
    ],
    "ember_orchard": [
        ("glowing_fruit", "The Glowing Fruit", "An apple hangs from a blackened bough, glowing like a coal. It smells wonderful.", False, [
            ch("Eat it", "50% chance: sword damage +4 for the run. Otherwise the fortress takes 8 damage.", "Warmth spreads through you. Your blade feels lighter.",
               [fx("GRANT_UPGRADE", upgrade="honed_blade")], chance=0.5, fail=[fx("FORTRESS_DAMAGE", 8)], fail_text="You do not remember the rest. The fortress shows burn marks."),
            ch("Carry it to the walls", "+60 gold: merchants pay for curiosities.", "The glow does not fade. Someone will pay for that.", [fx("GOLD", 60)]), WALK]),
        ("orchard_keeper", "The Orchard Keeper", "A scorched man tends a tree that gave up fruit years ago. He offers to tend your towers, for a fee.", False, [
            ch("Pay him to tend a tower", "Costs 50 gold. The cheapest tower that can go up a level does, free.", "He works until the tower is greener than it should be.",
               [fx("FREE_TOWER_LEVEL")], "UPGRADABLE_TOWER", 50),
            ch("Buy his firewood", "Costs 30 gold. The next merchant's prices x0.85.", "Dry wood, and he knows who to sell it to.",
               [fx("MERCHANT_PRICES", factor=0.85)], "GOLD", 30), WALK]),
    ],
    "bone_quarry": [
        ("giants_rib", "The Giant's Rib", "A rib the height of a house stands in the quarry floor. Something hums inside it.", False, [
            ch("Chip off a piece", "Fortress max HP +25 for the run, but the fortress takes 6 damage.", "You carry the piece home. It hums all night.",
               [fx("GRANT_UPGRADE", upgrade="masonry"), fx("FORTRESS_DAMAGE", 6)]),
            ch("Listen to it", "Free: +30 gold, and the next fight is swift.", "It tells you something about the road. Mostly, hurry.",
               [fx("GOLD", 30), fx("NEXT_FIGHTS_AFFIX", 1, affix="swift")]), WALK]),
        ("stonecutters_cache", "The Stonecutters' Cache", "A locked chest in a cave-in, half buried. Hammers lie beside it.", False, [
            ch("Break the lock", "70% chance: +90 gold. Otherwise nothing, and the next fight is siege.", "A fistful of old coins and a cutter's apron.",
               [fx("GOLD", 90)], chance=0.7, fail=[fx("NEXT_FIGHTS_AFFIX", 1, affix="siege")], fail_text="The roof comes down. The dead hear the noise."),
            ch("Take the hammers", "Tower upgrades cost 20% less for the run.", "Good iron. The smith will know what to do with it.",
               [fx("GRANT_UPGRADE", upgrade="guild")]), WALK]),
    ],
    "drowned_fields": [
        ("reed_ferryman", "The Reed Ferryman", "A figure poles a flat boat through the reeds, ignoring the dead that ride it.", False, [
            ch("Pay the fare", "Costs 40 gold. The next merchant's prices x0.8.", "He takes the coin without looking at it.",
               [fx("MERCHANT_PRICES", factor=0.8)], "GOLD", 40),
            ch("Ask for the truth", "Lose the most recent upgrade; an upgrade choice of 3 rare cards.", "He tells you something, and you forget something else.",
               [fx("LOSE_LAST_UPGRADE"), fx("UPGRADE_CHOICE", 3, rare=True)], "UPGRADE"), WALK]),
        ("will_o_wisp", "The Wisp", "A pale light bobs in the reeds, just off the path. It seems to want to be followed.", False, [
            ch("Follow it", "50% chance: an upgrade choice of 3 cards. Otherwise you lose 12 fortress HP in the mud.", "It leads you to something worth finding.",
               [fx("UPGRADE_CHOICE", 3)], chance=0.5, fail=[fx("FORTRESS_DAMAGE", 12)], fail_text="You come back late, and wet, and the walls have taken a beating."),
            WALK]),
    ],
    "frostbound_pass": [
        ("frozen_caravan", "The Frozen Caravan", "A merchant train sits in the snow, every driver standing frozen at the reins.", False, [
            ch("Loot the wagons", "+90 gold, and the next fight is swift.", "The cold follows you out of the wagons.",
               [fx("GOLD", 90), fx("NEXT_FIGHTS_AFFIX", 1, affix="swift")]),
            ch("Take only the cloaks", "Hero max HP +30 for the run.", "Thick, wool-lined, and strangely warm.",
               [fx("GRANT_UPGRADE", upgrade="iron_body")]), WALK]),
        ("hermits_hearth", "The Hermit's Hearth", "A hut with smoke in its chimney. The hermit invites you to warm yourself, and to listen.", False, [
            ch("Pay for the warmth", "Costs 30 gold. You reload 20% faster for the run.", "He shows you how to keep a bowstring dry.",
               [fx("GRANT_UPGRADE", upgrade="quick_hands")], "GOLD", 30),
            ch("Sit and listen", "Free: repair the fortress by 30%.", "He talks about the old road, and by the end your walls feel mended.",
               [fx("GRANT_UPGRADE", upgrade="repairs")]), WALK]),
    ],
    "gloam_wood": [
        ("lost_lantern", "The Lost Lantern", "A lantern hangs from a bough, lit, with no one to carry it.", False, [
            ch("Take it", "Dash recharges 25% faster, but the next fight is swarming.", "It makes the path clear. It also makes you visible.",
               [fx("GRANT_UPGRADE", upgrade="fleet_step"), fx("NEXT_FIGHTS_AFFIX", 1, affix="swarming")]),
            ch("Snuff it", "Free: +60 gold from the lamp's oil.", "The dark comes closer, and with it, a feeling of being seen.", [fx("GOLD", 60)]), WALK]),
        ("the_whispering_stag", "The Whispering Stag", "A white stag watches from the trees. It will not flee. It is listening.", True, [
            ch("Meet its eyes", "35% chance: a choice of 2 relics. Otherwise the hero loses a life.", "It lowers its antlers, and between them, something shines.",
               [fx("RELIC_CHOICE", 2)], need="SPARE_LIFE", chance=0.35, fail=[fx("LOSE_LIFE")], fail_text="Its eyes are empty. You wake on the road, alone."),
            WALK]),
    ],
    "ashen_keep": [
        ("keepers_armory", "The Keepers' Armory", "A stone door ajar, behind it racks of weapons gone to rust. One still gleams.", False, [
            ch("Take the gleaming one", "Sword damage +4 for the run.", "It was waiting. It does not feel like a gift.", [fx("GRANT_UPGRADE", upgrade="honed_blade")]),
            ch("Pay the armourers' ghost", "Costs 80 gold. The cheapest tower that can go up a level does, free.", "Something hammers in the dark, and your tower is stronger.",
               [fx("FREE_TOWER_LEVEL")], "UPGRADABLE_TOWER", 80), WALK]),
        ("the_cold_forge", "The Cold Forge", "An anvil in a ruined hall, a half-made blade on it. The coals glow without wood.", False, [
            ch("Strike the blade", "40% chance: the next evolution costs nothing. Otherwise the fortress takes 10 damage.", "Orm would be furious. It is a very good blow.",
               [fx("FREE_EVOLUTION")], chance=0.4, fail=[fx("FORTRESS_DAMAGE", 10)], fail_text="The anvil answers with fire. The walls shudder."),
            WALK]),
    ],
    "sunless_mines": [
        ("collapsed_shaft", "The Collapsed Shaft", "A shaft mouth half closed by rockfall. Something scrapes behind the stones.", False, [
            ch("Clear it", "Fight one wave of what is ahead, now. Reward: a choice of 3 rare upgrades.", "",
               [fx("EXTRA_FIGHT", 3, rare=True)]),
            ch("Brace the timbers", "Costs 40 gold. Fortress max HP +25 for the run.", "Good timber holds. Yours will.", [fx("GRANT_UPGRADE", upgrade="masonry")], "GOLD", 40), WALK]),
        ("miners_cache", "The Miners' Cache", "A locked chest with a lamp burning beside it. The lamp is still warm.", False, [
            ch("Take the gold", "+70 gold, but the next fight is ironclad.", "The lamp goes out when you leave.", [fx("GOLD", 70), fx("NEXT_FIGHTS_AFFIX", 1, affix="ironclad")]),
            ch("Take the lamp", "Hero max HP +30 for the run.", "It warms your hands, and your resolve.", [fx("GRANT_UPGRADE", upgrade="iron_body")]), WALK]),
    ],
    "pale_cathedral": [
        ("the_confessional", "The Confessional", "A booth in the nave, its curtain drawn. A voice inside asks what you regret.", True, [
            ch("Confess", "Lose the most recent upgrade; a choice of 2 relics.", "It forgives you, and it takes something in exchange.",
               [fx("LOSE_LAST_UPGRADE"), fx("RELIC_CHOICE", 2)], "UPGRADE"),
            WALK]),
        ("the_alms_box", "The Alms Box", "An iron box, bolted to a pillar. It rattles when you pass, hopefully.", False, [
            ch("Give alms", "Costs 40 gold. Repair the fortress by 30%.", "The bells ring once, out of tune. The walls feel stronger.",
               [fx("GRANT_UPGRADE", upgrade="repairs")], "GOLD", 40),
            ch("Rob it", "+60 gold, but the next fight is warded.", "The cathedral remembers.", [fx("GOLD", 60), fx("NEXT_FIGHTS_AFFIX", 1, affix="warded")]), WALK]),
    ],
}
BY_CHAPTER = {k: [e[0] for e in v] for k, v in TABLE.items()}
FILES = {"crypt_road": "chapter_1", "drowned_fields": "chapter_2", "ashen_keep": "chapter_3", "ember_orchard": "ember_orchard",
         "bone_quarry": "bone_quarry", "frostbound_pass": "frostbound_pass", "gloam_wood": "gloam_wood", "sunless_mines": "sunless_mines",
         "pale_cathedral": "pale_cathedral"}


def q(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def write_event(eid, title, text, rare, choices):
    ext = ['[ext_resource type="Script" path="res://resources/event_data.gd" id="1_event"]',
           '[ext_resource type="Script" path="res://resources/event_choice.gd" id="2_choice"]',
           '[ext_resource type="Script" path="res://resources/event_effect.gd" id="3_effect"]']
    refs, subs, n = {}, [], 0

    def ref(path):
        if path not in refs:
            refs[path] = "r%d" % len(refs)
            ext.append('[ext_resource type="Resource" path="%s" id="%s"]' % (path, refs[path]))
        return 'ExtResource("%s")' % refs[path]

    def effect(e):
        nonlocal n
        n += 1
        lines = ['[sub_resource type="Resource" id="E%d"]' % n, 'script = ExtResource("3_effect")', "type = %d" % e["type"]]
        if e["amount"]:
            lines.append("amount = %d" % e["amount"])
        if e["factor"] != 1.0:
            lines.append("factor = %s" % e["factor"])
        if e["rare"]:
            lines.append("rare_only = true")
        if e["upgrade"]:
            lines.append("upgrade = " + ref("res://data/upgrades/%s.tres" % e["upgrade"]))
        if e["affix"]:
            lines.append("affix = " + ref("res://data/affixes/%s.tres" % e["affix"]))
        subs.append("\n".join(lines) + "\n")
        return 'SubResource("E%d")' % n

    choice_ids = []
    for c in choices:
        effs = [effect(e) for e in c["effects"]]
        fails = [effect(e) for e in c["fail"]]
        n += 1
        lines = ['[sub_resource type="Resource" id="C%d"]' % n, 'script = ExtResource("2_choice")', "label = " + q(c["label"]), "outcome = " + q(c["outcome"])]
        if c["need"]:
            lines.append("need = %d" % c["need"])
        if c["cost"]:
            lines.append("gold_cost = %d" % c["cost"])
        lines.append('effects = Array[ExtResource("3_effect")]([%s])' % ", ".join(effs))
        if c["chance"] < 1.0:
            lines.append("chance = %s" % c["chance"])
            lines.append('fail_effects = Array[ExtResource("3_effect")]([%s])' % ", ".join(fails))
            lines.append("fail_text = " + q(c["fail_text"]))
        lines.append("result_text = " + q(c["result"]))
        subs.append("\n".join(lines) + "\n")
        choice_ids.append('SubResource("C%d")' % n)
    body = ["[resource]", 'script = ExtResource("1_event")', 'id = &"%s"' % eid, "title = " + q(title), "text = " + q(text)]
    if rare:
        body.append("rare = true")
    body.append('choices = Array[ExtResource("2_choice")]([%s])' % ", ".join(choice_ids))
    head = '[gd_resource type="Resource" script_class="EventData" load_steps=%d format=3]\n\n' % (len(ext) + len(subs) + 1)
    with open(os.path.join(ROOT, "data/events/%s.tres" % eid), "w") as f:
        f.write(head + "\n".join(ext) + "\n\n" + "\n".join(subs) + "\n" + "\n".join(body) + "\n")


def patch_chapter(chapter_id, file):
    path = os.path.join(ROOT, "data/run/%s.tres" % file)
    text = open(path).read()
    for eid in BY_CHAPTER[chapter_id]:
        if 'id="ev_%s"' % eid in text:
            continue
        line = '[ext_resource type="Resource" path="res://data/events/%s.tres" id="ev_%s"]\n' % (eid, eid)
        text = re.sub(r"(\[ext_resource[^\n]*id=\"ev_[a-z_]+\"\]\n)(?!\[ext_resource[^\n]*id=\"ev_)", lambda m: m.group(1) + line, text, count=1)
        text = re.sub(r"^(events = Array\[ExtResource\(\"s_event\"\)\]\(\[.*?)\]\)$", lambda m: m.group(1) + ', ExtResource("ev_%s")])' % eid, text, count=1, flags=re.M)
    open(path, "w").write(text)


def main():
    total = 0
    for chapter_id, events in TABLE.items():
        for e in events:
            write_event(*e)
            total += 1
        patch_chapter(chapter_id, FILES[chapter_id])
    print("wrote", total, "events")


if __name__ == "__main__":
    main()
