extends SceneTree
## Automated check for the tutorial hints (M8): with a save, the map's tip shows when the map first
## shows (and is saved as seen); the first fight's build phase shows the build tip with the bound key
## in its text; tips that come while one shows wait their turn (the first tower, the first wave); a tip
## goes by itself after its time; "Skip all tips" hides it and no more come (saved); a tip seen once
## never shows again in a later session; the War Room's Tips switch brings them all back; in script
## mode there are none.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const SAVE_PATH: String = "user://test_hints.json"
const ARCHER: TowerData = preload("res://data/towers/archer.tres")

var _failures: int = 0


func _initialize() -> void:
	_clean()
	await process_frame
	var scripted: Node = await _new_main()
	_check("script mode: no tips", not (scripted.get_node("%HintDirector") as HintDirector).enabled
		and not (scripted.get_node("%HintPanel") as HintPanel).visible)
	scripted.queue_free()
	await _frames(2)

	var save: SaveManagerNode = root.get_node("/root/SaveManager") as SaveManagerNode
	save.use_file(SAVE_PATH)
	var main: Node = await _new_main()
	var panel: HintPanel = main.get_node("%HintPanel")
	_check("the map's tip when the map first shows, saved as seen", panel.get_current() == &"map" and save.profile.hints_seen.has("map"))
	panel.get_node("%GotIt").pressed.emit()
	var level: Level = await MapFixtures.enter_first_battle(main)
	await _frames(2)
	_check("the first fight: the build tip, with its key (\"%s\")" % panel.get_text(), panel.get_current() == &"build"
		and not panel.get_text().contains("{") and panel.get_text().contains(GameSettings.describe(GameSettings.get_bindings(&"interact")[0])))
	level.economy.earn(500, Economy.Source.REFUND)
	level.builder.build(level.builder.get_slots()[3], ARCHER)
	await _frames(2)
	_check("the first tower's tip waits its turn", panel.get_current() == &"build")
	panel.close()
	await _frames(1)
	_check("...then shows", panel.get_current() == &"start_wave")
	panel.show_time = 0.2
	panel.show_hint(&"start_wave", panel.get_text())
	await _frames(20)
	_check("a tip goes by itself after its time", not panel.visible)
	level.run_cycle.start_wave()
	await _frames(5)
	_check("the first wave: the fight tip", panel.get_current() == &"fight")
	panel.get_node("%SkipAll").pressed.emit()
	await _frames(1)
	level.hero_lives.hero.get_node("%HealthComponent").call("take_damage", 1)
	(main.get_node("%HintDirector") as HintDirector).request(&"dash")
	await _frames(2)
	_check("Skip all tips: hidden, none after, saved", not panel.visible and save.profile.hints_off
		and (JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH)) as Dictionary).get("hints_off") == true)
	main.queue_free()
	await _frames(2)

	save.profile.hints_off = false
	main = await _new_main()
	panel = main.get_node("%HintPanel")
	_check("a later session: the map's tip, seen, doesn't show again", not panel.visible)
	var front: FrontEnd = main.get_node("%FrontEnd")
	save.profile.hints_off = true
	front.show_hub()
	front.get_hub().tips_toggled.emit(true)
	_check("the War Room's Tips switch on: every tip again", not save.profile.hints_off and save.profile.hints_seen.is_empty())
	main.queue_free()
	await _frames(2)
	_clean()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _new_main() -> Node:
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	main.set("boot_to_title", false)
	root.add_child(main)
	await _frames(3)
	return main


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
