extends SceneTree
## Automated check for resuming a run (M8): with a save, each time the map shows the run is saved in
## the profile; after quitting (Main freed), the title offers Continue, which puts the run back on its
## map exactly as it was (seed, chapter, path, fights won, gold, cards and relics, lives, fortress HP,
## every tower with its level and evolution, the dice of the offers and events: the next card offer is
## the same one), the towers standing (not rebuilt); a saved run of another format starts a fresh run
## instead; a new run from the War Room abandons the saved one (it pays); the end of a run clears it; a
## run saved in chapter 2 resumes on chapter 2's level.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const SAVE_PATH: String = "user://test_resume.json"
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const CANNON: TowerData = preload("res://data/towers/cannon.tres")

var _failures: int = 0
var _save: SaveManagerNode


func _initialize() -> void:
	_clean()
	await process_frame
	_save = root.get_node("/root/SaveManager") as SaveManagerNode
	_save.use_file(SAVE_PATH)
	_save.profile.unlock_everything = true
	var main: Node = await _new_main()
	var front: FrontEnd = main.get_node("%FrontEnd")
	front.get_title().get_play_button().pressed.emit()
	await _frames(2)
	front.get_hub().get_start_button().pressed.emit()
	await _frames(3)
	_check("a new run is saved as soon as its map shows", not _save.profile.run.is_empty() and (_save.profile.run.get("path", [0]) as Array).is_empty())
	var level: Level = await MapFixtures.enter_first_battle(main)
	level.economy.earn(3000, Economy.Source.REFUND)
	var slots: Array[BuildSlot] = level.builder.get_slots()
	level.builder.build(slots[3], ARCHER)
	level.builder.build(slots[0], CANNON)
	await _frames(90)
	level.builder.upgrade(slots[3])
	await _frames(30)
	level.builder.upgrade(slots[3])
	await _frames(30)
	level.builder.upgrade(slots[0])
	await _frames(30)
	_check("set up: an evolved Archer, a level-2 Cannon", level.builder.evolve(slots[3], 1) and slots[0].tower.get_level() == 2)
	level.spawner.enemy_spawned.connect(func(e: Enemy) -> void: e.get_health().take_damage.call_deferred(100000))
	await _win_fight(level)
	level.fortress.health.take_damage(37)
	(main.get_node("%MapFlow") as MapFlow).show_map()  # saved again, with the damage
	var before: Dictionary = _comparable(_save.profile.run)
	var next_offer: Array = level.offers.make_offer(3, false).map(func(d: UpgradeData) -> StringName: return d.id)
	_check("saved on the map after the fight: path, a card, towers (%d), %d gold" % [(before.get("towers") as Array).size(), int(before.get("gold"))],
		(before.get("path") as Array).size() == 1 and (before.get("upgrades") as Array).size() == 1 and (before.get("towers") as Array).size() == 2)

	main.queue_free()  # quit
	await _frames(2)
	main = await _new_main()
	front = main.get_node("%FrontEnd")
	_check("the title offers Continue", front.get_title().visible and front.get_title().get_continue_button().visible)
	front.get_title().get_continue_button().pressed.emit()
	await _frames(3)
	level = main.call("get_level")
	var after: Dictionary = _comparable(RunSave.capture(main.get_node("/root/RunState") as RunStateNode, level))
	_check("Continue: the run is back exactly as saved", after == before)
	if after != before:
		print("   saved:   ", before, "\n   resumed: ", after)
	slots = level.builder.get_slots()
	_check("...on its map, the towers standing (not rebuilt), the Archer evolved", (main.get_node("%MapScreen") as MapScreen).visible
		and not slots[3].tower.is_building() and slots[3].tower.is_evolved() and slots[0].tower.get_level() == 2)
	var resumed_offer: Array = level.offers.make_offer(3, false).map(func(d: UpgradeData) -> StringName: return d.id)
	_check("...with the same dice: the next card offer is the same %s" % str(resumed_offer), resumed_offer == next_offer)
	level.offers.pick(0)
	await _frames(2)

	var runs: int = _save.profile.runs
	front.show_hub()
	front.get_hub().get_start_button().pressed.emit()
	await _frames(3)
	_check("a new run from the War Room abandons the saved one (it pays: %d runs)" % _save.profile.runs,
		_save.profile.runs == runs + 1 and (main.get("last_summary") as Dictionary).get("result") == "abandoned"
		and int((main.get("last_summary") as Dictionary).get("battles", 0)) == 1)
	level = await MapFixtures.enter_first_battle(main)
	level.fortress.health.take_damage(100000)
	await _frames(3)
	_check("the end of a run clears the saved run", _save.profile.run.is_empty())

	main.queue_free()
	await _frames(2)
	_save.profile.run = {"version": 99, "seed": 5}
	main = await _new_main()
	front = main.get_node("%FrontEnd")
	front.get_title().get_continue_button().pressed.emit()
	await _frames(3)
	_check("a saved run of another format: a fresh run instead", main.call("get_level") != null and (main.call("get_map") as RunMap).path.is_empty()
		and int(_save.profile.run.get("version", 0)) == RunSave.VERSION)
	main.call("jump_to_chapter", 1)
	await _frames(3)
	before = _comparable(_save.profile.run)
	main.queue_free()
	await _frames(2)
	main = await _new_main()
	(main.get_node("%FrontEnd") as FrontEnd).get_title().get_continue_button().pressed.emit()
	await _frames(3)
	level = main.call("get_level")
	_check("a run saved in chapter 2 resumes there (%s)" % level.scene_file_path.get_file(), int(before.get("chapter", 0)) == 1
		and _comparable(RunSave.capture(main.get_node("/root/RunState") as RunStateNode, level)) == before
		and level.scene_file_path != (main.get("run_data") as RunData).chapters[0].level_scene.resource_path)
	main.queue_free()
	await _frames(2)
	_clean()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _new_main() -> Node:
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(3)
	return main


## Plays the level's fight to its reward (enemies die as they come) and takes the first card.
func _win_fight(level: Level) -> void:
	for _i: int in 60 * 60:
		if level.offers.is_offer_open():
			break
		if level.run_cycle.get_phase() == RunCycle.Phase.BUILD:
			level.run_cycle.start_wave()
		await physics_frame
	level.offers.pick(0)
	await _frames(2)


## `saved` without what may differ between a save and its resume (the time played).
func _comparable(saved: Dictionary) -> Dictionary:
	var copy: Dictionary = JSON.parse_string(JSON.stringify(saved))
	copy.erase("msec")
	return copy


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
