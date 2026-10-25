extends SceneTree
## Automated check for Pressure (M12): the ten modifiers (data, points, the shard bonus and titles), what each
## does to a level (stats, slots, cards, speed, hasty waves, no repairs), the save (v5, the selection, the
## records), the shard line, the panel and the War Room button.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const RUN: RunData = preload("res://data/run/run.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_level_effects()
	_test_save_and_meta()
	await _test_screens()
	await _test_summary_and_hub()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _pick(ids: Array) -> Array[PressureData]:
	return RUN.pressure_for(ids)


func _test_data() -> void:
	_check("ten modifiers worth 15 points in all", RUN.pressure_options.size() == 10 and PressureRules.points(RUN.pressure_options) == 15)
	_check("the shard bonus is +10%% a point", is_equal_approx(PressureRules.shard_multiplier(5), 1.5) and is_equal_approx(PressureRules.shard_multiplier(0), 1.0))
	_check("titles by points: none, Watchman, Captain, Marshal, Warden, Last Light", PressureRules.title(0) == "" and PressureRules.title(1) == "Watchman"
		and PressureRules.title(4) == "Captain" and PressureRules.title(7) == "Marshal" and PressureRules.title(10) == "Warden" and PressureRules.title(15) == "Last Light")
	_check("unknown ids are dropped and each modifier counts once", _pick(["lean_purses", "nope", "lean_purses"]).size() == 1)


func _level(list: Array[PressureData]) -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new(), WaveData.new()]
	WaveFixtures.no_upgrades(level)
	root.add_child(level)
	await process_frame
	await process_frame
	level.apply_pressure(list, 7)
	await process_frame
	return level


func _test_level_effects() -> void:
	var base: Level = await _level([])
	var base_fortress: int = base.fortress.health.max_health
	var base_lives: int = base.hero_lives.get_max_lives()
	base.queue_free()
	await process_frame
	var level: Level = await _level(_pick(["brittle_fortress", "one_life_fewer", "lean_purses", "swift_dead", "fewer_cards", "hasty_waves", "fewer_slots", "no_repairs"]))
	_check("Brittle Fortress: 30%% less max HP (%d -> %d)" % [base_fortress, level.fortress.health.max_health], level.fortress.health.max_health == roundi(base_fortress * 0.7))
	_check("One Life Fewer (%d -> %d)" % [base_lives, level.hero_lives.get_max_lives()], level.hero_lives.get_max_lives() == base_lives - 1)
	_check("Lean Purses: kills pay 15%% less", is_equal_approx(level.modifiers.apply(100.0, [RunModifiers.KILL_GOLD]), 85.0))
	_check("Swift Dead: enemies 10%% faster", is_equal_approx(level.spawner.enemy_speed_scale, PressureRules.ENEMY_SPEED))
	_check("Fewer Cards: offers of 2", level.offers.offer_size == 2)
	_check("Hasty Waves: the wave counts down by itself", level.run_cycle.hasty_seconds == PressureRules.HASTY_SECONDS and level.run_cycle.get_hasty_left() > 0.0)
	var locked: Array[BuildSlot] = level.builder.get_slots().filter(func(s: BuildSlot) -> bool: return s.locked)
	_check("Fewer Slots: two slots blocked by rubble", locked.size() == 2 and level.builder.get_free_slot_count() == level.builder.get_slots().size() - 2)
	var failures: Array[String] = []
	level.builder.build_failed.connect(func(_s: BuildSlot, _d: TowerData, reason: String) -> void: failures.append(reason))
	level.economy.earn(500, Economy.Source.REFUND)
	_check("...and nothing can be built there", not level.builder.build(locked[0], level.builder.catalog[0]) and failures == [TowerBuilder.SLOT_LOCKED])
	level.fortress.health.take_damage(40)
	var hurt: int = level.fortress.health.current_health
	level.fortress.repair(0.5)
	_check("No Repairs: the walls stay as they are", level.fortress.health.current_health == hurt)
	level.run_cycle.start_wave()
	await _frames(2)
	_check("a wave that began restarts the countdown for the next build phase", level.run_cycle.get_hasty_left() > PressureRules.HASTY_SECONDS - 5.0
		or level.run_cycle.get_hasty_left() < 0.0)
	level.queue_free()
	await process_frame
	var again: Level = await _level(_pick(["fewer_slots"]))
	var again_locked: Array[int] = []
	for i: int in again.builder.get_slots().size():
		if again.builder.get_slots()[i].locked:
			again_locked.append(i)
	var third: Level = await _level(_pick(["fewer_slots"]))
	var third_locked: Array[int] = []
	for i: int in third.builder.get_slots().size():
		if third.builder.get_slots()[i].locked:
			third_locked.append(i)
	_check("the same chapter seed blocks the same slots", again_locked == third_locked and again_locked.size() == 2)
	again.queue_free()
	third.queue_free()
	await process_frame


func _test_save_and_meta() -> void:
	var p: SaveProfile = SaveProfile.new()
	p.pressure_selection.append("lean_purses")
	p.pressure_best = 6
	p.pressure_wins["knight"] = 4
	var back: SaveProfile = SaveProfile.from_dict(p.to_dict())
	_check("the selection and records survive a round trip", back.pressure_selection == p.pressure_selection and back.pressure_best == 6 and back.pressure_wins.get("knight") == 4)
	var old: SaveProfile = SaveProfile.from_dict({"version": 4, "shards": 3})
	_check("a v4 save loads with no Pressure", old.pressure_selection.is_empty() and old.pressure_best == 0 and SaveProfile.CURRENT_VERSION == 5)
	_check("Pressure is offered after the first win only", not SaveProfile.new().pressure_open() and _won_profile().pressure_open())
	var summary: Dictionary = {"result": "won", "battles": 4, "elites": 0, "bosses": [], "chapters_cleared": 0, "chapter": 1, "row": 5, "hero": "knight", "pressure": 5}
	var lines: Array[Array] = MetaProgress.shard_lines(summary, SaveProfile.new())
	var base: int = 0
	for line: Array in lines.slice(0, lines.size() - 1):
		base += int(line[1])
	_check("a Pressure line pays +10%% a point on the rest (%d of %d)" % [int(lines.back()[1]), base], int(lines.back()[1]) == roundi(base * 0.5) and str(lines.back()[0]).begins_with("Pressure 5"))
	var profile: SaveProfile = SaveProfile.new()
	MetaProgress.finish_run(profile, summary)
	summary["pressure"] = 3
	MetaProgress.finish_run(profile, summary)
	_check("the records keep the best Pressure, and the best won per hero", profile.pressure_best == 5 and profile.pressure_wins.get("knight") == 5)
	var run: RunStateNode = RunStateNode.new()
	run.start_run(RUN, 3, null, null, _pick(["lean_purses", "hasty_waves"]))
	var saved: Dictionary = {"version": RunSave.VERSION, "seed": 3, "chapter": 0, "path": [], "cleared": [], "pressure": ["lean_purses", "hasty_waves"]}
	var restored: RunStateNode = RunStateNode.new()
	_check("a saved run keeps its Pressure", RunSave.restore_run(restored, saved, RUN, null) and PressureRules.ids(restored.pressure) == ["lean_purses", "hasty_waves"]
		and PressureRules.points(run.pressure) == 2)
	run.free()
	restored.free()


func _won_profile() -> SaveProfile:
	var p: SaveProfile = SaveProfile.new()
	p.wins = 1
	return p


func _test_screens() -> void:
	var screen: PressureScreen = (load("res://ui/hub/pressure_screen.tscn") as PackedScene).instantiate()
	root.add_child(screen)
	await process_frame
	var changes: Array = []
	screen.selection_changed.connect(func(ids: Array[String]) -> void: changes.append(ids))
	screen.open(RUN.pressure_options, ["lean_purses"] as Array[String])
	_check("the panel starts with the saved switches on (Pressure 1: Watchman)", screen.get_switch(&"lean_purses").button_pressed and screen.get_total_text().begins_with("Pressure 1"))
	screen.get_switch(&"no_repairs").button_pressed = true
	_check("switching one on adds its points and tells the front end", screen.get_total_text().begins_with("Pressure 3") and changes.size() == 1
		and (changes[0] as Array).has("no_repairs") and (changes[0] as Array).has("lean_purses"))
	screen.queue_free()
	await process_frame


func _test_summary_and_hub() -> void:
	var summary_screen: RunSummaryScreen = (load("res://ui/menus/run_summary_screen.tscn") as PackedScene).instantiate()
	root.add_child(summary_screen)
	await process_frame
	summary_screen.open({"result": "won", "chapter": 3, "row": 6, "seed": 4, "hero": "knight", "pressure": 5, "depth": 2, "shards": 9})
	var stats: Label = summary_screen.find_child("Stats", true, false) as Label
	var where: Label = summary_screen.find_child("Where", true, false) as Label
	_check("the summary names the Pressure and its title, and the depth", stats.text.begins_with("Pressure: 5 (Captain)") and where.text.contains("descended 2 deep"))
	summary_screen.queue_free()
	var hub: HubScreen = (load("res://ui/hub/hub_screen.tscn") as PackedScene).instantiate()
	root.add_child(hub)
	await process_frame
	var profile: SaveProfile = SaveProfile.new()
	profile.wins = 1
	profile.pressure_best = 8
	profile.pressure_wins["knight"] = 4
	profile.depth_best["knight"] = 3
	var board: UnlockBoard = load("res://data/meta/unlock_board.tres")
	hub.refresh(profile, board, null, false, null, RUN.pressure_options)
	var records: Label = hub.find_child("Records", true, false) as Label
	_check("the War Room shows the Pressure button after a win, and the records", hub.get_pressure_button().visible and records.text.contains("Highest Pressure: 8 (Marshal)")
		and records.text.contains("Won at Pressure: 4 (Captain)") and records.text.contains("Deepest descent: 3"))
	hub.refresh(SaveProfile.new(), board, null, false, null, RUN.pressure_options)
	_check("...and hides it before the first win", not hub.get_pressure_button().visible)
	hub.queue_free()


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
