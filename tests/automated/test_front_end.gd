extends SceneTree
## Automated check for the front end (M8): with a save (not script mode) main.tscn opens on the title
## (no Continue without a saved run, no level, no pause); Play leads to the War Room, where an unlock
## is bought (its price taken, saved) and the tips switched off; Start a run plays with the bought
## unlock; the pause menu's Abandon run ends it as abandoned and shows the run summary, then the War
## Room again (the Quartermaster's line about it), back to the title; a lost run's Game Over says
## Continue and leads to its summary, whose New run starts the next; Reset progress starts over.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const SAVE_PATH: String = "user://test_front_end.json"

var _failures: int = 0


func _initialize() -> void:
	_clean()
	await process_frame
	var save: SaveManagerNode = root.get_node("/root/SaveManager") as SaveManagerNode
	save.use_file(SAVE_PATH)
	save.profile.shards = 100
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(3)
	var front: FrontEnd = main.get_node("%FrontEnd")
	var title: TitleScreen = front.get_title()
	var hub: HubScreen = front.get_hub()
	var summary: RunSummaryScreen = front.get_summary()
	_check("boots on the title: no Continue (no saved run), no level, no pause", title.visible
		and not title.get_continue_button().visible and main.call("get_level") == null and not main.call("can_pause"))

	title.get_credits_button().pressed.emit()
	await _frames(2)
	_check("Credits: a scrolling modal with the makers and the licence, and the credits music", title.get_credits().visible
		and title.get_credits().get_block_count() >= 10 and Music.current == &"credits")
	title.get_credits().close()
	await _frames(2)
	_check("closing the credits brings the title music back", not title.get_credits().visible and Music.current == &"title")
	title.get_play_button().pressed.emit()
	await _frames(2)
	_check("Play: the War Room", hub.visible and not title.visible)
	hub.get_buy_button(&"brazier").pressed.emit()
	await _frames(2)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	_check("buying the Brazier: 25 shards taken, saved (%s left)" % saved.get("shards"),
		save.profile.shards == 75 and (saved.get("unlocks", []) as Array).has("brazier") and hub.get_buy_button(&"brazier").disabled)
	_check("an unlock that needs another can't be bought", hub.get_buy_button(&"evolutions_cannon").disabled)
	hub.tips_toggled.emit(false)
	_check("the tips switched off, saved", save.profile.hints_off)

	hub.get_start_button().pressed.emit()
	await _frames(3)
	var level: Level = main.call("get_level")
	_check("Start a run: the map, with the bought Brazier (%d towers)" % level.builder.catalog.size(),
		(main.get_node("%MapScreen") as MapScreen).visible and level.builder.catalog.size() == 4 and not hub.visible)
	var pause: PauseMenu = main.get_node("%PauseMenu")
	pause.open()
	pause.restart_requested.emit()
	pause.close()
	await _frames(3)
	var last: Dictionary = main.get("last_summary")
	_check("Abandon run: the summary of an abandoned run, the level gone, the run counted",
		summary.visible and last.get("result") == "abandoned" and main.call("get_level") == null and save.profile.runs == 1)
	summary.get_hub_button().pressed.emit()
	await _frames(2)
	_check("To the War Room: the Quartermaster talks about it", hub.visible and hub.get_cast_line(&"quartermaster").contains("Walking away"))
	var listen: Button = hub.get_listen_button(&"quartermaster")
	_check("a character with a story to tell offers it (Listen), the others have none yet", listen != null and listen.text.contains("The Ledger") and hub.get_listen_button(&"orm") != null)
	hub.get_chronicle_button().pressed.emit()
	_check("the Chronicle opens from the War Room", hub.get_chronicle().visible)
	_check("the Chronicle and Pressure panels draw above the War Room, not behind it",
		hub.get_chronicle().layer > hub.layer and (hub.get_node("%PressureScreen") as CanvasLayer).layer > hub.layer)
	hub.get_chronicle().hide()
	listen.pressed.emit()
	await _frames(2)
	_check("listening records the beat once; the next beat waits for its condition", save.profile.beats_seen.has("dunmore_1") and hub.get_listen_button(&"quartermaster") == null)
	hub.back_requested.emit()
	await _frames(2)
	_check("back to the title", title.visible and not hub.visible)

	title.get_play_button().pressed.emit()
	await _frames(2)
	hub.get_start_button().pressed.emit()
	await _frames(3)
	level = await MapFixtures.enter_first_battle(main)
	level.fortress.health.take_damage(100000)
	await _frames(3)
	var game_over: GameOverScreen = main.get_node("%GameOverScreen")
	var restart: Button = game_over.get_node("%RestartButton")
	_check("a lost run: Game Over says Continue", game_over.visible and restart.text == "Continue")
	restart.pressed.emit()
	await _frames(3)
	_check("...then its summary (%s)" % summary.get_total_text(), summary.visible and not game_over.visible
		and (main.get("last_summary") as Dictionary).get("result") == "lost" and save.profile.runs == 2)
	summary.new_run_requested.emit()
	await _frames(3)
	_check("New run: straight into the next run's map", main.call("get_level") != null and not summary.visible
		and (main.get_node("%MapScreen") as MapScreen).visible)

	main.queue_free()
	await _frames(2)
	save.reset_profile()
	_check("Reset progress: a fresh profile", save.profile.shards == 0 and save.profile.unlocks.is_empty() and save.profile.runs == 0)
	_clean()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _clean() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE_PATH + suffix):
			DirAccess.remove_absolute(SAVE_PATH + suffix)


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
