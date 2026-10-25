extends SceneTree
## Automated check for the story's rules (M11): conditions, a character's line (highest priority that
## holds), the next beat (in order, once), the Chronicle's unlocks, the endings (and the secret one), and
## the save's story fields (round trip, an older save loads with none).
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

var _failures: int = 0


func _initialize() -> void:
	_test_conditions()
	_test_lines_and_beats()
	_test_lore_and_endings()
	_test_save()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _cond(props: Dictionary) -> StoryCondition:
	var c: StoryCondition = StoryCondition.new()
	for key: String in props:
		c.set(key, props[key])
	return c


func _test_conditions() -> void:
	var p: SaveProfile = SaveProfile.new()
	_check("the empty condition always holds", StoryCondition.new().holds(p))
	_check("min_runs fails then holds", not _cond({"min_runs": 2}).holds(p))
	p.runs = 2
	_check("min_runs holds at 2", _cond({"min_runs": 2}).holds(p))
	_check("a boss not beaten fails", not _cond({"boss": "Fallen Marshal"}).holds(p))
	p.bosses.append("Fallen Marshal")
	_check("a boss beaten holds", _cond({"boss": "Fallen Marshal"}).holds(p))
	_check("a last-run condition fails with no history", not _cond({"last_result": "lost"}).holds(p))
	p.history.append({"result": "lost", "chapter": 2, "row": 3, "bosses": [], "relics": [], "hero": "knight"})
	_check("last result lost holds", _cond({"last_result": "lost"}).holds(p))
	_check("last result won fails", not _cond({"last_result": "won"}).holds(p))
	_check("last chapter min 3 fails, 2 holds", not _cond({"last_chapter_min": 3}).holds(p) and _cond({"last_chapter_min": 2}).holds(p))
	_check("last row max 2 fails, 3 holds", not _cond({"last_row_max": 2}).holds(p) and _cond({"last_row_max": 3}).holds(p))
	_check("last beat a boss fails with none", not _cond({"last_beat_a_boss": true}).holds(p))
	_check("last hero knight holds, huntress fails", _cond({"last_hero": &"knight"}).holds(p) and not _cond({"last_hero": &"huntress"}).holds(p))


func _book() -> StoryBook:
	var book: StoryBook = StoryBook.new()
	for spec: Array in [["a", 0, 1], ["b", 5, 0]]:
		var line: HubLine = HubLine.new()
		line.character = &"orm"
		line.text = spec[0]
		line.priority = spec[1]
		line.condition = _cond({"min_runs": spec[2]})
		book.lines.append(line)
	for spec: Array in [["second", 2, 0], ["first", 1, 0], ["late", 3, 9]]:
		var beat: StoryBeat = StoryBeat.new()
		beat.id = StringName(spec[0])
		beat.character = &"orm"
		beat.order = spec[1]
		beat.condition = _cond({"min_runs": spec[2]})
		book.beats.append(beat)
	return book


func _test_lines_and_beats() -> void:
	var book: StoryBook = _book()
	var p: SaveProfile = SaveProfile.new()
	_check("the highest priority line that holds is said", Story.line_for(book, p, &"orm") == "b")
	_check("no line for a stranger", Story.line_for(book, p, &"nobody") == "")
	_check("the next beat is the first by order that holds", Story.next_beat(book, p, &"orm").id == &"first")
	p.beats_seen.append("first")
	_check("a heard beat is not told again", Story.next_beat(book, p, &"orm").id == &"second")
	p.beats_seen.append("second")
	_check("a beat whose condition fails waits", Story.next_beat(book, p, &"orm") == null)
	_check("heard beats are listed in order", Story.heard_beats(book, p, &"orm").size() == 2 and Story.heard_beats(book, p, &"orm")[0].id == &"first")


func _test_lore_and_endings() -> void:
	var p: SaveProfile = SaveProfile.new()
	var foe: LoreEntry = LoreEntry.new()
	foe.key = &"ghoul"
	var place: LoreEntry = LoreEntry.new()
	place.kind = LoreEntry.Kind.PLACE
	place.key = &"crypt_road"
	_check("lore is locked until met", not Story.is_unlocked(foe, p) and not Story.is_unlocked(place, p))
	p.foes_seen.append("ghoul")
	p.places_seen.append("crypt_road")
	_check("lore unlocks when the foe appears or the place is entered", Story.is_unlocked(foe, p) and Story.is_unlocked(place, p))
	var book: StoryBook = StoryBook.new()
	for spec: Array in [["e1", "marshal", false], ["e2", "warden", false], ["e3", "bishop", false], ["e4", "", true]]:
		var e: EndingData = EndingData.new()
		e.id = StringName(spec[0])
		e.boss = StringName(spec[1])
		e.secret = spec[2]
		book.endings.append(e)
	_check("a finale boss gives its ending", Story.ending_for(book, p, &"warden").id == &"e2")
	p.endings.append_array(["e1", "e2"])
	_check("two seen: the third boss still gives its own", Story.ending_for(book, p, &"bishop").id == &"e3")
	_check("the last normal ending is still its own", Story.ending_for(book, p, &"bishop").id == &"e3")
	p.endings.append("e3")
	_check("all three seen: the next win gives the secret ending", Story.ending_for(book, p, &"bishop").id == &"e4")
	p.endings.append("e4")
	_check("the secret ending is told once", Story.ending_for(book, p, &"bishop").id == &"e3")


func _test_save() -> void:
	var p: SaveProfile = SaveProfile.new()
	p.beats_seen.append("x")
	p.foes_seen.append("ghoul")
	p.places_seen.append("crypt_road")
	p.endings.append("e1")
	var back: SaveProfile = SaveProfile.from_dict(p.to_dict())
	_check("story fields survive a round trip", back.beats_seen == p.beats_seen and back.foes_seen == p.foes_seen
		and back.places_seen == p.places_seen and back.endings == p.endings)
	var old: SaveProfile = SaveProfile.from_dict({"version": 3, "shards": 4})
	_check("a v3 save loads with an empty story", old.shards == 4 and old.beats_seen.is_empty() and old.endings.is_empty())
	_check("the current version is 4", SaveProfile.CURRENT_VERSION == 4)


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
