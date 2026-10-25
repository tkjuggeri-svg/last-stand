extends SceneTree
## Automated check for the tiers and the road choice (M10): a run has one chapter per tier; the first
## biome comes from the seed (the same every time, locked ones never); after a chapter the next tier
## offers two unlocked biomes (the same two every time) or none to choose between; the chapter screen shows
## them and the choice starts that biome; a saved run keeps the roads taken and an old save without them
## still loads.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const RUN: RunData = preload("res://data/run/run.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_tiers()
	_test_draw()
	await _test_screen()
	_test_save()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


## A run of 3 tiers: 3, 2 and 1 biomes.
func _run_data() -> RunData:
	var data: RunData = RunData.new()
	data.heroes = RUN.heroes
	var plan: Array = [[1, "a1"], [1, "a2"], [1, "a3"], [2, "b1"], [2, "b2"], [3, "c1"]]
	for entry: Array in plan:
		var chapter: ChapterData = RUN.chapters[0].duplicate()
		chapter.tier = entry[0]
		chapter.id = StringName(entry[1])
		chapter.display_name = "Biome %s" % entry[1]
		chapter.blurb = "A place."
		chapter.mechanic_text = "Something happens."
		chapter.difficulty_note = "harder"
		data.chapters.append(chapter)
	return data


func _state(data: RunData, seed_value: int, unlocks: RunUnlocks = null) -> RunStateNode:
	var run: RunStateNode = RunStateNode.new()
	run.start_run(data, seed_value, unlocks)
	return run


func _test_tiers() -> void:
	var data: RunData = _run_data()
	_check("a run has one chapter per tier (3)", data.tier_count() == 3 and data.biomes_of_tier(1).size() == 3 and data.biomes_of_tier(2).size() == 2)
	_check("the real run: each chapter is its own tier (tier 0 means its place)", RUN.tier_of(RUN.chapters[0]) == 1 and RUN.tier_of(RUN.chapters[1]) == 2
		and RUN.tier_count() == 3 and RUN.biomes_of_tier(1).size() == 3 and RUN.biomes_of_tier(3).size() == 3)


func _test_draw() -> void:
	var data: RunData = _run_data()
	var firsts: Dictionary = {}
	for seed_value: int in 40:
		var first: RunStateNode = _state(data, seed_value)
		firsts[first.get_chapter().id] = true
		var again: RunStateNode = _state(data, seed_value)
		_check_quiet(first.get_chapter() == again.get_chapter())
		first.free()
		again.free()
	_check("the first biome comes from the seed: all three show up over 40 seeds, the same one per seed (%d)" % firsts.size(), firsts.size() == 3 and _failures == 0)
	var run: RunStateNode = _state(data, 5)
	var roads: Array[ChapterData] = run.road_options()
	_check("after chapter 1: two roads of tier 2, always the same two", roads.size() == 2 and roads[0].id == &"b1" and roads[1].id == &"b2" and run.road_options() == roads)
	run.choose_road(roads[1])
	run.next_chapter()
	_check("choosing takes that biome (chapter 2 is %s)" % run.get_chapter().id, run.chapter_index == 1 and run.get_chapter().id == &"b2" and run.map != null)
	_check("tier 3 has one biome: no choice", run.road_options().size() == 1)
	run.next_chapter()
	_check("the last chapter is c1, and it is the last", run.get_chapter().id == &"c1" and run.is_last_chapter())
	run.free()
	var locked: RunUnlocks = RunUnlocks.new()
	locked.locked_biomes = [data.chapters[0], data.chapters[1], data.chapters[3]]
	var closed: RunStateNode = _state(data, 9, locked)
	_check("locked biomes are never drawn or offered (chapter 1 is a3, then one road: b2)", closed.get_chapter().id == &"a3" and closed.road_options().size() == 1
		and closed.road_options()[0].id == &"b2")
	closed.free()
	var wide: RunData = _run_data()
	wide.chapters.append(wide.chapters[3].duplicate())
	wide.chapters[6].id = &"b3"
	var pairs: Dictionary = {}
	for seed_value: int in 60:
		var r: RunStateNode = _state(wide, seed_value)
		var two: Array[ChapterData] = r.road_options()
		pairs["%s%s" % [two[0].id, two[1].id]] = true
		_check_quiet(two[0] != two[1])
		r.free()
	_check("with three biomes a tier offers different pairs, never twice the same biome (%d pairs)" % pairs.size(), pairs.size() == 3 and _failures == 0)


func _test_screen() -> void:
	var screen: ChapterScreen = (load("res://ui/map/chapter_screen.tscn") as PackedScene).instantiate()
	root.add_child(screen)
	await process_frame
	var data: RunData = _run_data()
	var roads: Array[ChapterData] = [data.chapters[3], data.chapters[4]]
	var chosen: Array[int] = []
	screen.road_chosen.connect(func(i: int) -> void: chosen.append(i))
	var carry: ChapterCarry = ChapterCarry.new()
	screen.open("Chapter 1", "", carry, 0.4, 0.5, 50, 100, roads)
	_check("two road cards and no Continue", screen.get_road_button(0) != null and screen.get_road_button(1) != null and not screen.get_continue_button().visible)
	_check("a card names the biome, what it is, its mechanic and difficulty", screen.get_road_button(1).text.contains("Biome b2") and screen.get_road_button(1).text.contains("A place.")
		and screen.get_road_button(1).text.contains("Something happens.") and screen.get_road_button(1).text.contains("harder"))
	screen.get_road_button(1).pressed.emit()
	_check("taking one reports its index and closes the screen", chosen == [1] and not screen.visible)
	screen.open("Chapter 1", "Biome b1", carry, 0.4, 0.5, 50, 100)
	_check("with no choice it is the old Continue", screen.get_continue_button().visible and (screen.get_road_button(0) == null or not screen.get_road_button(0).is_visible_in_tree()))
	screen.queue_free()
	await process_frame


func _test_save() -> void:
	var data: RunData = _run_data()
	var run: RunStateNode = RunStateNode.new()
	var saved: Dictionary = {"version": RunSave.VERSION, "seed": 12, "chapter": 1, "biomes": ["a2", "b2"], "path": [], "cleared": []}
	_check("a saved run restores its roads", RunSave.restore_run(run, saved, data, null) and run.get_chapter().id == &"b2" and run.biomes[0].id == &"a2")
	run.free()
	var old: RunStateNode = RunStateNode.new()
	var legacy: Dictionary = {"version": RunSave.VERSION, "seed": 12, "chapter": 1, "path": [], "cleared": []}
	_check("a save from before M10 (no roads) still loads: the seed's picks", RunSave.restore_run(old, legacy, data, null) and old.get_chapter() != null and old.chapter_index == 1)
	old.free()


func _check_quiet(ok: bool) -> void:
	if not ok:
		_failures += 1


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
