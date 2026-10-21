extends SceneTree
## Automated check for run seeds (through main.tscn): a run started from a seed is the same run again
## (the map, the offers); another seed gives another run; the pause menu shows the seed and starts a new
## run from a typed one; the Game Over screen shows the seed.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const SEED: int = 4242

var _failures: int = 0


func _initialize() -> void:
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(2)
	main.call("start_run", SEED)
	await _frames(2)
	var first: String = _signature(main)
	main.call("start_run", SEED + 1)
	await _frames(2)
	var other: String = _signature(main)
	main.call("start_run", SEED)
	await _frames(2)
	var again: String = _signature(main)
	_check("the same seed gives the same run (the map and the offers)", first == again and not first.is_empty())
	_check("...and another seed another run", first != other)
	var run: RunStateNode = root.get_node("/root/RunState") as RunStateNode
	_check("the run knows its seed (%d)" % run.seed_value, run.seed_value == SEED)
	var level: Level = await MapFixtures.enter_first_battle(main)
	await _frames(2)
	_press(&"pause")
	await _frames(2)
	var pause: PauseMenu = main.get_node("%PauseMenu")
	_check("the pause menu shows the seed (\"%s\")" % (pause.get_node("%SeedLabel") as Label).text,
		pause.is_open() and (pause.get_node("%SeedLabel") as Label).text.contains(str(SEED)))
	(pause.get_node("%SeedEdit") as LineEdit).text = "777"
	(pause.get_node("%SeedRunButton") as Button).pressed.emit()
	await _frames(2)
	_check("...and starts a new run from a typed seed (%d)" % run.seed_value, run.seed_value == 777 and not pause.is_open() and not paused)
	level = await MapFixtures.enter_first_battle(main)
	level.fortress.health.take_damage(100000)
	await _frames(3)
	var game_over: GameOverScreen = main.get_node("%GameOverScreen")
	_check("the Game Over screen shows the seed (\"%s\")" % (game_over.get_node("%SeedLabel") as Label).text,
		game_over.visible and (game_over.get_node("%SeedLabel") as Label).text.contains("777"))
	main.queue_free()
	await _frames(2)
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


## The run's map (every node's row and kind) and the first fight's level's next card draws.
func _signature(main: Node) -> String:
	var map: RunMap = main.call("get_map")
	var parts: PackedStringArray = PackedStringArray()
	for node: MapNode in map.nodes:
		parts.append("%d%s" % [node.row, RunMap.Kind.keys()[node.kind]])
	var level: Level = main.call("get_level")
	for card: UpgradeData in level.offers.draw_cards(3):
		parts.append(String(card.id))
	return ",".join(parts)


func _press(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)


func _frames(count: int) -> void:
	for _i: int in count:
		await process_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
