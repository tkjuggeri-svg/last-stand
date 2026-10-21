extends SceneTree
## Automated check for the in-game feedback key (through main.tscn): the feedback action (rebindable)
## opens the box over a paused game, anywhere in a run; Save writes a new folder with the note, the
## screenshot (when the renderer gives one) and the run's state as JSON (seed, chapter, node, wave,
## gold, fortress, lives, towers with levels and evolutions, cards, relics); the game runs on after;
## Cancel saves nothing.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const TEST_DIR: String = "user://test_feedback"
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const HONED: UpgradeData = preload("res://data/upgrades/honed_blade.tres")
const HOURGLASS: RelicData = preload("res://data/relics/hourglass.tres")
const NOTE: String = "The cannon shot through a wall?"

var _failures: int = 0


func _initialize() -> void:
	_clear(TEST_DIR)
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	main.set("run_seed", 21)
	main.set("feedback_dir", TEST_DIR)
	root.add_child(main)
	await _frames(2)
	var level: Level = await MapFixtures.enter_first_battle(main)
	level.economy.earn(500, Economy.Source.REFUND)
	level.builder.build(level.builder.get_slots()[3], ARCHER)
	level.modifiers.add_upgrade(HONED)
	level.modifiers.add_upgrade(HOURGLASS)
	await _frames(60)
	level.builder.upgrade(level.builder.get_slots()[3])
	await _frames(2)
	var screen: FeedbackScreen = main.get_node("%FeedbackScreen")
	_check("the feedback key is a rebindable action (F8)", InputMap.has_action(&"feedback") and GameSettings.ACTIONS.has(&"feedback"))
	_press(&"feedback")
	await _frames(2)
	_check("the key opens the box and pauses the game", screen.is_open() and paused)
	screen.get_note_edit().text = NOTE
	screen.get_save_button().pressed.emit()
	await _frames(2)
	var folders: PackedStringArray = DirAccess.get_directories_at(TEST_DIR)
	_check("Save writes one new folder (%d)" % folders.size(), folders.size() == 1)
	var folder: String = TEST_DIR.path_join(folders[0]) if folders.size() == 1 else TEST_DIR
	_check("...with the note", FileAccess.get_file_as_string(folder.path_join("note.txt")).strip_edges() == NOTE)
	var shot: bool = FileAccess.file_exists(folder.path_join("screenshot.png"))
	_check("...and a screenshot (%s)" % ("saved" if shot else "none: the headless renderer gives no image"),
		shot or DisplayServer.get_name() == "headless")
	var state: Variant = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("state.json")))
	_check("...and the run's state as JSON", state is Dictionary)
	if state is Dictionary:
		var s: Dictionary = state
		var towers: Array = s.get("towers", [])
		_check("the state: seed %s, chapter %s, node %s, wave %s" % [s.get("seed"), s.get("chapter"), (s.get("node", {}) as Dictionary).get("kind"), s.get("wave")],
			int(s.get("seed", -1)) == 21 and int(s.get("chapter", 0)) == 1 and (s.get("node", {}) as Dictionary).get("kind") == "battle"
			and int(s.get("wave", -1)) == level.run_cycle.get_current_wave_number())
		_check("...gold %s, fortress %s, lives %s" % [s.get("gold"), s.get("fortress"), s.get("lives")],
			int(s.get("gold", -1)) == level.economy.get_gold() and int((s.get("fortress", {}) as Dictionary).get("hp", -1)) == level.fortress.health.current_health
			and int((s.get("lives", {}) as Dictionary).get("left", -1)) == level.hero_lives.get_lives_left())
		_check("...the towers with their level (%s)" % str(towers), towers.size() == 1 and (towers[0] as Dictionary).get("tower") == "archer"
			and int((towers[0] as Dictionary).get("level", 0)) == 2 and int((towers[0] as Dictionary).get("slot", -1)) == 3)
		_check("...the cards and the relics", ((s.get("cards", {}) as Dictionary).get("honed_blade", 0) as int) == 1
			and (s.get("relics", []) as Array).has("hourglass") and not (s.get("cards", {}) as Dictionary).has("hourglass"))
	screen.close()
	await _frames(2)
	_check("closing the box gives the game back", not screen.is_open() and not paused)
	_press(&"feedback")
	await _frames(2)
	screen.close()
	await _frames(2)
	_check("Cancel saves nothing", DirAccess.get_directories_at(TEST_DIR).size() == 1)
	_clear(TEST_DIR)
	main.queue_free()
	await _frames(2)
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _press(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)


func _clear(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for sub: String in DirAccess.get_directories_at(dir):
		for file: String in DirAccess.get_files_at(dir.path_join(sub)):
			DirAccess.remove_absolute(dir.path_join(sub).path_join(file))
		DirAccess.remove_absolute(dir.path_join(sub))
	DirAccess.remove_absolute(dir)


func _frames(count: int) -> void:
	for _i: int in count:
		await process_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
