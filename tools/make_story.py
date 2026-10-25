#!/usr/bin/env python3
"""Writes data/story/story_book.tres (M11): the War Room's characters, their lines and beats, the endings and
the Chronicle's lore. Dev only: edit the tables below and rerun `python3 tools/make_story.py`."""
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")

CHARACTERS = [  # id, name, role, portrait index
    ("quartermaster", "Quartermaster Dunmore", "keeper of the stores", 3),
    ("ilse", "Sister Ilse", "last of the bell-keepers", 4),
    ("orm", "Orm", "the smith", 5),
]

# Conditions: dict of StoryCondition fields.
LINES = [  # character, priority, condition, text
    ("quartermaster", 0, {}, "First night on the walls? The dead leave Soul Shards behind. Spend them here."),
    ("quartermaster", 5, {"min_runs": 1}, "The ledger says you came back. The ledger is a kind liar."),
    ("quartermaster", 10, {"last_result": "lost", "last_row_max": 2}, "A short night. Shake it off: the first rows are the easiest to learn."),
    ("quartermaster", 12, {"last_result": "lost", "last_found_a_relic": True}, "That relic you found... I've seen ones like it. Keep your eyes open out there."),
    ("quartermaster", 14, {"last_result": "lost"}, "The fortress fell, and we rebuild. We always rebuild."),
    ("quartermaster", 16, {"last_result": "lost", "last_chapter_min": 2}, "The water out there remembers everything. So do I. Sit; eat."),
    ("quartermaster", 18, {"last_result": "lost", "last_beat_a_boss": True}, "A boss fell to you, and still the night came on. Rest, then go again."),
    ("quartermaster", 20, {"last_result": "abandoned"}, "Walking away is sometimes wisdom. The walls will wait for you."),
    ("quartermaster", 30, {"last_result": "won"}, "You held! Every chapter. The bells will ring for a week."),
    ("ilse", 0, {}, "The bells are cracked, but they still know the old hours. Listen when the wind is right."),
    ("ilse", 5, {"min_runs": 3}, "Every night you go out, I light a candle. Dunmore says it is a waste of wax. He lights one too."),
    ("ilse", 10, {"last_result": "lost"}, "No shame in a fall. The Waking does not tire, so we must learn to rest between."),
    ("ilse", 20, {"last_result": "won"}, "Dawn. I had forgotten how it sounds when the bells are not afraid."),
    ("ilse", 12, {"place": "pale_cathedral"}, "You have walked the Pale Cathedral. Tell me nothing. I know what is in its nave."),
    ("orm", 0, {}, "Bring me bones and I will make you iron. Bring me iron and I will make you a fool's hope."),
    ("orm", 5, {"min_runs": 2}, "Your blade has a new notch. Good. Notches are how a smith reads a story."),
    ("orm", 10, {"last_result": "lost"}, "The dead broke you, not the steel. I'll hammer you back into shape. Not the steel."),
    ("orm", 12, {"place": "ashen_keep"}, "Ashen Keep, was it? My old forge is there. Is the anvil still cold?"),
    ("orm", 20, {"last_result": "won"}, "Won, did you. Hm. Then I will have to forge something worth winning with."),
]

BEATS = [  # id, character, order, title, condition, text
    ("dunmore_1", "quartermaster", 1, "The Ledger", {"min_runs": 1},
     "Before the Waking there were forty of us keeping the stores of Last Light. Now there is me, a bell-keeper, a smith and whoever the fortress sends through that door.\n\nI keep the ledger because someone should write down what the dead cost us. It is a long column."),
    ("dunmore_2", "quartermaster", 2, "Who Pays", {"min_runs": 3},
     "You think the Soul Shards are a gift. They are what is left of people who stood where you stand.\n\nThe Waking takes everyone it kills and leaves a little of them behind. We spend it on walls. I have stopped asking whether that is a mercy."),
    ("dunmore_3", "quartermaster", 3, "The Marsh Road", {"chapter": 2},
     "The marsh was a farm once. The Drowned Fields fed Vael for three hundred years. When the water came up I sent twelve carts out and none came back.\n\nIf you find a cart wheel out there, bring it. I would like to know which one."),
    ("dunmore_4", "quartermaster", 4, "What We Owe", {"min_wins": 1},
     "You did it. Do not look so surprised; I have kept a cot made up for exactly this.\n\nThe Waking will come again, it always does. But for one night the ledger has a line in the other column. Thank you."),
    ("ilse_1", "ilse", 1, "The Bells", {"min_runs": 2},
     "There were nine bells in the tower, one for each hour of the long night. The Waking cracked eight. The ninth I rang until my hands bled and it kept them away until dawn.\n\nThat is why I stay. One bell is still better than none."),
    ("ilse_2", "ilse", 2, "The Marshal", {"boss": "The Fallen Marshal"},
     "You have faced the Fallen Marshal. He held the keep for the last king of Vael, and when the king fell he did not know it, and he held it still.\n\nThere is a kind of loyalty that is a curse. Pity him if you can, and strike true."),
    ("ilse_3", "ilse", 3, "My Order", {"place": "pale_cathedral"},
     "The Pale Cathedral was my order's seat. We taught that the dead rest if you ring for them. The Bishop believed it so hard that he rang for everyone, and now no one rests.\n\nI do not hate him. That is the worst part."),
    ("ilse_4", "ilse", 4, "Dawn", {"min_wins": 1},
     "When you won, I rang the ninth bell. The Waking did not flinch, but I felt something old in the stones loosen, as if the walls remembered how to be a home.\n\nDo not tell Dunmore I wept. He will want a line in the ledger."),
    ("orm_1", "orm", 1, "Iron", {"min_runs": 1},
     "Everyone wants a sword. Nobody wants the smith. I made blades for the Marshal's guard, back when the Marshal was a man who laughed.\n\nI do not say that for pity. I say it so that when you see his helm, you know whose steel is in it."),
    ("orm_2", "orm", 2, "The Keep's Forge", {"place": "ashen_keep"},
     "Under the Ashen Keep there is a forge I never finished. The fire there burns without wood. I think it is waiting for someone to finish the blade on the anvil.\n\nIf you pass it, do not touch the hammer. It has opinions."),
    ("orm_3", "orm", 3, "Quarry Stone", {"place": "bone_quarry"},
     "The stone of Last Light came from the Bone Quarry. We dug it from the old giants' graves because it was cheap and strong. We did not ask why it hummed.\n\nYou have heard it hum, I hear. Good. Then you believe me."),
    ("orm_4", "orm", 4, "The Last Blade", {"min_wins": 2},
     "Twice you have walked out of the dark. I am too old to make you a legend, but I can make you a blade nothing else would be worth.\n\nSit. This will take until the next dawn."),
]

ENDINGS = [  # id, boss file, title, secret, text
    ("ending_marshal", "fallen_marshal", "The Marshal Rests", False,
     "The Fallen Marshal kneels in the ash, and for the first time in a hundred years he hears no orders. He sets his sword on the stones of the keep and the iron cools.\n\nLast Light's walls hold. In the war room, Orm lights a forge that has been cold since the Waking, and Dunmore, who does not say such things, writes one word in the ledger: Held."),
    ("ending_warden", "deep_warden", "The Deep Is Quiet", False,
     "The Deep Warden sinks into its own shadows and the mines go dark, truly dark, the kind the old miners called peace. The hum in the stone stops.\n\nAbove, the walls of Last Light stop shuddering. Ilse rings the ninth bell, and for once nothing answers it."),
    ("ending_bishop", "pale_bishop", "The Last Toll", False,
     "The Pale Bishop's mouth opens to ring one more time, and no sound comes. The bells of the cathedral, nine for nine hours, are silent together.\n\nIn Last Light, Ilse sits down on the steps of the tower and laughs and cries and cannot stop. The dead are resting. All of them. At last."),
    ("ending_secret", "", "The First Dawn", True,
     "Three times you ended the night, and the Waking learned your name. On the fourth, no horror waited at the end of the road: only a door, and beyond it, light that did not belong to any fire.\n\nSome say the Waking was never a curse but a long vigil, kept for something that has not yet come. The walls of Last Light stand. The bells ring nine. And somewhere very far away, someone wakes."),
]

PLACES = {  # chapter id: (title, text)
    "crypt_road": ("The Crypt Road", "The old pilgrim way from Last Light to the Marshal's keep, lined with tombs. The graves open when the Waking stirs: the road remembers every funeral."),
    "ember_orchard": ("The Ember Orchard", "Vael's apple country burned in the first night and never stopped smouldering. The trees bear fruit that glows. Do not eat it."),
    "bone_quarry": ("The Bone Quarry", "Where the fortress stone was cut, out of the graves of giants. Rockfalls here are not accidents."),
    "drowned_fields": ("The Drowned Marsh", "Vael's farmland, taken by black water when the river changed course. The Mire Priests preach that the marsh is a mercy."),
    "frostbound_pass": ("The Frostbound Pass", "A mountain road where the cold has a will. Blizzards roll in from nowhere and wraiths walk in them."),
    "gloam_wood": ("The Gloam Wood", "A forest where the light does not reach the ground. Whatever lives here has learned to wait."),
    "ashen_keep": ("The Ashen Keep", "The last king's castle. Its walls fall inward on those who linger, and its Marshal still keeps the gate."),
    "sunless_mines": ("The Sunless Mines", "Deep shafts that gave Vael its iron. The miners dug too deep, and the Deep dug back."),
    "pale_cathedral": ("The Pale Cathedral", "The bell-keepers' great church. Its bells ring on their own, and the dead file in to hear them."),
}

FOES = {  # enemy file name: (title, text, hint)
    "ghoul": ("Ghoul", "A fresh grave's first mistake: hungry, quick to rise and quicker to fall. The Waking's rank and file.", "Met on the Crypt Road."),
    "hound": ("Hound", "The old hunters' dogs, dug up and unleashed. They go for the hero first.", "Fast and hungry."),
    "brute": ("Brute", "A pit-fighter whose bones were taken thick. It does not feel the blades.", "Slow and heavy."),
    "shieldbearer": ("Shieldbearer", "A soldier who held the line after death. Hit it from the side, if you can.", "Carries a shield."),
    "cultist": ("Cultist", "One of those who prayed for the Waking and got an answer. It mends the dead around it.", "Keeps others alive."),
    "bloater": ("Bloater", "Swollen with grave-water. Strike it where you do not mind the splash.", "Bursts when killed."),
    "bloatling": ("Bloatling", "What a Bloater leaves behind: small, and angry about it.", "Born from a Bloater."),
    "mire_priest": ("Mire Priest", "A marsh preacher who baptised the drowned. His sermons are nearly kind.", "Preaches in the marsh."),
    "gravelord": ("The Gravelord", "Warden of the Crypt Road, raised by his own tomb. He commands the graves.", "Boss of the Crypt Road."),
    "colossus": ("The Bone Colossus", "A hundred skeletons wired together by a single will. It walks because it has forgotten how to fall.", "Boss of the marsh."),
    "lich": ("The Lich Warden", "A scholar who sought to hold death at bay and merely held it.", "A chapter's last guardian."),
    "tollkeeper": ("The Tollkeeper", "The marsh ferryman, who still takes his fee. It was never gold he wanted.", "Takes a toll."),
    "cinder_ghoul": ("Cinder Ghoul", "A ghoul in the Ember Orchard's flames. It leaves ash where it walks.", "Burns."),
    "scarecrow": ("Scarecrow", "Stuffed with dry straw and a dead farmer's grudge. Keep it from the flame.", "Flammable."),
    "pyre_warden": ("The Pyre Warden", "The orchard's keeper, who lit the first fire to save the fruit and did not stop.", "Boss of the Ember Orchard."),
    "frost_wraith": ("Frost Wraith", "A traveller who froze in the pass and kept walking.", "Cold and quick."),
    "rime_brute": ("Rime Brute", "A frozen giant's corpse, brittle and strong.", "Frozen solid."),
    "winter_warden": ("The Winter Warden", "The pass's master. Her blizzard has never lifted.", "Boss of the Frostbound Pass."),
    "burrower": ("Burrower", "Something that learned to swim through stone.", "Digs through the ground."),
    "lamp_wight": ("Lamp Wight", "A miner whose lantern burns still, and draws others to it.", "Carries a lantern."),
    "deep_warden": ("The Deep Warden", "The thing that dug back. It guards the bottom of the Mines.", "Boss of the Sunless Mines."),
    "bone_hurler": ("Bone Hurler", "Throws its own ribs. It grows them back.", "Throws bones."),
    "rubble_brute": ("Rubble Brute", "A quarryman rebuilt from fallen stone.", "Stone-skinned."),
    "quarry_colossus": ("The Quarry Colossus", "A giant that the quarrymen cut from the hill. It is only finishing its walk.", "Boss of the Bone Quarry."),
    "stalker": ("Stalker", "It walks the Gloam Wood without sound, and without light.", "Quiet in the dark."),
    "hollow_treant": ("Hollow Treant", "A great tree hollowed by the dark. Something looks out of it.", "Slow, huge."),
    "hollow_stag": ("The Hollow Stag", "The forest's old lord. Its antlers hold the night.", "Boss of the Gloam Wood."),
    "chorister": ("Chorister", "A choirboy whose last hymn never ended.", "Sings."),
    "inquisitor": ("Inquisitor", "The cathedral's judge. It remembers only the verdict.", "Judges."),
    "pale_bishop": ("The Pale Bishop", "He rang the bells for everyone, and so no one rests. The last toll is his.", "Boss of the Pale Cathedral."),
    "siege_ram": ("Siege Ram", "A battering ram that still hits walls of its own accord.", "Breaks walls."),
    "black_knight": ("Black Knight", "A knight of the last king's guard, loyal long past the grave.", "Loyal."),
    "fallen_marshal": ("The Fallen Marshal", "He held the keep for the last king and did not stop when the king fell.", "Boss of the Ashen Keep."),
}


def quote(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


class Out:
    def __init__(self):
        self.ext = {}
        self.subs = []
        self.n = 0

    def script(self, name):
        if name not in self.ext:
            self.ext[name] = len(self.ext) + 1
        return self.ext[name]

    def sub(self, script, props):
        self.n += 1
        sid = "s%d" % self.n
        body = "".join("%s = %s\n" % (k, v) for k, v in props.items())
        self.subs.append('[sub_resource type="Resource" id="%s"]\nscript = ExtResource("%d")\n%s' % (sid, self.script(script), body))
        return 'SubResource("%s")' % sid


def cond(out, fields):
    if not fields:
        return "null"
    props = {}
    for k, v in fields.items():
        if isinstance(v, bool):
            props[k] = "true" if v else "false"
        elif isinstance(v, int):
            props[k] = str(v)
        elif k in ("place", "unlock", "ending", "beat", "last_hero"):
            props[k] = '&"%s"' % v
        else:
            props[k] = quote(v)
    return out.sub("story_condition", props)


def array(typename, refs):
    return "Array[%s]([%s])" % (typename, ", ".join(refs))


def main():
    out = Out()
    chars = [out.sub("story_character", {"id": '&"%s"' % i, "display_name": quote(n), "role": quote(r), "portrait": str(p)})
             for i, n, r, p in CHARACTERS]
    lines = [out.sub("hub_line", {"character": '&"%s"' % c, "text": quote(t), "priority": str(p), "condition": cond(out, f)})
             for c, p, f, t in LINES]
    beats = [out.sub("story_beat", {"id": '&"%s"' % i, "character": '&"%s"' % c, "title": quote(t), "text": quote(x),
                                    "order": str(o), "condition": cond(out, f)}) for i, c, o, t, f, x in BEATS]
    endings = [out.sub("ending_data", {"id": '&"%s"' % i, "boss": '&"%s"' % b, "title": quote(t), "text": quote(x),
                                       "secret": "true" if s else "false"}) for i, b, t, s, x in ENDINGS]
    lore = []
    for key, (title, text, hint) in FOES.items():
        lore.append(out.sub("lore_entry", {"id": '&"foe_%s"' % key, "kind": "0", "key": '&"%s"' % key, "title": quote(title),
                                           "text": quote(text), "hint": quote(hint)}))
    for key, (title, text) in PLACES.items():
        lore.append(out.sub("lore_entry", {"id": '&"place_%s"' % key, "kind": "1", "key": '&"%s"' % key, "title": quote(title),
                                           "text": quote(text), "hint": quote("A road not yet taken.")}))
    paths = {"story_condition": "res://resources/story_condition.gd", "story_character": "res://resources/story_character.gd",
             "hub_line": "res://resources/hub_line.gd", "story_beat": "res://resources/story_beat.gd",
             "ending_data": "res://resources/ending_data.gd", "lore_entry": "res://resources/lore_entry.gd",
             "story_book": "res://resources/story_book.gd"}
    book_id = out.script("story_book")
    head = "".join('[ext_resource type="Script" path="%s" id="%d"]\n' % (paths[k], i) for k, i in out.ext.items())
    body = ("[resource]\nscript = ExtResource(\"%d\")\ncharacters = %s\nlines = %s\nbeats = %s\nendings = %s\nlore = %s\n" % (
        book_id, array("StoryCharacter", chars), array("HubLine", lines), array("StoryBeat", beats),
        array("EndingData", endings), array("LoreEntry", lore)))
    # the book's own script was registered last, so the header (written after) includes it
    text = '[gd_resource type="Resource" script_class="StoryBook" load_steps=%d format=3]\n\n%s\n%s\n%s' % (
        len(out.ext) + len(out.subs) + 1, head, "\n".join(out.subs), body)
    path = os.path.join(ROOT, "data/story/story_book.tres")
    with open(path, "w") as f:
        f.write(text)
    print("wrote", os.path.normpath(path), len(lines), "lines,", len(beats), "beats,", len(endings), "endings,", len(lore), "lore")


main()
