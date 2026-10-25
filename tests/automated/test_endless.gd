extends SceneTree
## Automated check for Endless, "Descend" (M12): the rules (health x1.3 a depth, shards, the short chapter),
## RunState going deeper (tier-3 roads, short maps, depth), every short map of every tier-3 biome, a saved
## descent, the depth scale on a fight, the records and the ending screen's Descend button.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const RUN: RunData = preload("res://data/run/run.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_rules()
	_test_descent()
	_test_maps()
	_test_save()
	await _test_fight_scale()
	await _test_ending_screen()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_rules() -> void:
	_check("health x1.3 a depth", is_equal_approx(Endless.health_scale(0), 1.0) and is_equal_approx(Endless.health_scale(2), 1.69))
	_check("shards: 10, 30, 60 for depth 1, 2, 3", Endless.shards(1) == 10 and Endless.shards(2) == 30 and Endless.shards(3) == 60 and Endless.shards(0) == 0)
	var short: ChapterData = Endless.short_chapter(RUN.chapters[2], 1)
	_check("a descended chapter is short (6 rows) and named by its depth", short.rows == 6 and Endless.is_short(short) and short.display_name.begins_with("Depth 1:")
		and not Endless.is_short(RUN.chapters[2]) and RUN.chapters[2].rows != 6)


func _run_at_last_chapter(seed_value: int) -> RunStateNode:
	var run: RunStateNode = RunStateNode.new()
	run.start_run(RUN, seed_value)
	run.set_chapter(2)
	return run


func _test_descent() -> void:
	var run: RunStateNode = _run_at_last_chapter(5)
	_check("the normal run's last chapter is the last, with no depth", run.is_last_chapter() and run.depth == 0)
	var roads: Array[ChapterData] = run.road_options()
	_check("going deeper offers tier-3 roads again (%d)" % roads.size(), roads.size() >= 1 and roads.all(func(c: ChapterData) -> bool: return RUN.tier_of(c) == 3))
	run.next_chapter()
	_check("descending: depth 1, a short map ending in the boss, no longer the last chapter", run.depth == 1 and not run.is_last_chapter()
		and run.map.chapter.rows == 6 and run.map.get_boss().row == 6)
	run.next_chapter()
	_check("and again: depth 2", run.depth == 2 and run.chapter_index == 4 and Endless.is_short(run.get_chapter()))
	run.free()


func _test_maps() -> void:
	var ok: bool = true
	var total: int = 0
	for biome: ChapterData in RUN.biomes_of_tier(3):
		for seed_value: int in 10:
			var map: RunMap = RunMap.generate(Endless.short_chapter(biome, 1), seed_value)
			total += 1
			ok = ok and map.get_boss().kind == RunMap.Kind.BOSS and map.get_boss().encounter != null
			for path: Array in map.all_paths():
				ok = ok and path.size() == 6 and path.any(func(n: MapNode) -> bool: return n.kind == RunMap.Kind.MERCHANT)
			for node: MapNode in map.nodes:
				ok = ok and (not node.is_combat() or node.encounter != null)
	_check("every short map (%d: 3 biomes x 10 seeds) has a boss, fights with encounters and a merchant on every path" % total, ok)


func _test_save() -> void:
	var run: RunStateNode = _run_at_last_chapter(9)
	run.next_chapter()
	run.next_chapter()
	var saved: Dictionary = {"version": RunSave.VERSION, "seed": 9, "chapter": run.chapter_index, "depth": run.depth, "path": [], "cleared": [],
		"biomes": run.biomes.map(func(c: ChapterData) -> String: return String(c.id))}
	var back: RunStateNode = RunStateNode.new()
	_check("a saved descent resumes at its depth and its short map", RunSave.restore_run(back, saved, RUN, null) and back.depth == 2
		and back.chapter_index == run.chapter_index and back.map.chapter.rows == 6 and back.get_chapter().id == run.get_chapter().id)
	run.free()
	back.free()
	var summary: Dictionary = {"result": "won", "battles": 0, "elites": 0, "bosses": [], "chapters_cleared": 3, "chapter": 5, "row": 2, "hero": "huntress", "depth": 2}
	var lines: Array[Array] = MetaProgress.shard_lines(summary, SaveProfile.new())
	_check("depth pays 10 x 1 + 10 x 2 shards", lines.any(func(l: Array) -> bool: return str(l[0]).begins_with("Descended 2") and int(l[1]) == 30))
	var profile: SaveProfile = SaveProfile.new()
	MetaProgress.finish_run(profile, summary)
	var round_trip: SaveProfile = SaveProfile.from_dict(profile.to_dict())
	_check("the deepest depth is kept per hero, and saved", profile.depth_best.get("huntress") == 2 and round_trip.depth_best.get("huntress") == 2)


func _depth_multiplier(depth: int) -> float:
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	main.set("boot_to_title", false)
	root.add_child(main)
	await process_frame
	await process_frame
	(root.get_node("/root/RunState") as RunStateNode).depth = depth
	var level: Level = await MapFixtures.enter_first_battle(main)
	await process_frame
	var scale: float = level.spawner.waves[0].health_multiplier
	main.queue_free()
	await process_frame
	return scale


func _test_fight_scale() -> void:
	var base: float = await _depth_multiplier(0)
	var deep: float = await _depth_multiplier(2)
	_check("a fight two depths down has 1.69x the health (%.2f -> %.2f)" % [base, deep], is_equal_approx(deep / base, 1.69))


func _test_ending_screen() -> void:
	var screen: EndingScreen = (load("res://ui/menus/ending_screen.tscn") as PackedScene).instantiate()
	root.add_child(screen)
	await process_frame
	var book: StoryBook = load("res://data/story/story_book.tres")
	var events: Array[String] = []
	screen.continued.connect(func() -> void: events.append("stop"))
	screen.descend_requested.connect(func() -> void: events.append("descend"))
	screen.open(book.endings[0])
	_check("without the choice there is no Descend", not screen.get_descend_button().visible)
	screen.open(book.endings[0], true)
	_check("with it, Descend shows", screen.get_descend_button().visible)
	screen.get_descend_button().pressed.emit()
	_check("Descend asks to go on, and closes the screen (not 'stop')", events == ["descend"] and not screen.visible)
	screen.open(book.endings[0], true)
	screen.get_continue_button().pressed.emit()
	_check("Continue stops the run", events == ["descend", "stop"])
	screen.queue_free()


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
