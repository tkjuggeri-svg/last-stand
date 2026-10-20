extends SceneTree
## Automated check for the full run: the level's 15 hand-authored waves (rising curve, Hounds and
## Brutes introduced gradually, all 3 lanes used), and through the real main.tscn with a tiny run map
## (a battle, then the boss): a won battle gives its reward and returns to the map, beating the last
## chapter's boss wins the run (frozen level, own screen, Play again starts a fresh run on its map), and
## a run lost in the same moment as the boss fight ends is a loss, not a win.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"

var _failures: int = 0


func _initialize() -> void:
	_test_wave_curve()
	await _test_victory_and_restart()
	await _test_loss_beats_victory()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_wave_curve() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var waves: Array[WaveData] = (level.get_node("WaveSpawner") as WaveSpawner).waves
	_check("the level has 15 waves", waves.size() == 15)
	var rising: bool = true
	var previous: int = 0
	var first_seen: Dictionary = {}
	var lanes: Dictionary = {}
	for i: int in waves.size():
		var hp: int = 0
		for group: SpawnGroup in waves[i].groups:
			if not group.enemy.is_boss:  # a boss is a spike on top of the curve
				hp += group.count * group.enemy.max_health
			lanes[group.lane] = true
			if not first_seen.has(group.enemy.display_name):
				first_seen[group.enemy.display_name] = i + 1
		rising = rising and hp > previous
		previous = hp
	_check("every wave brings more enemy HP than the one before (bosses on top)", rising)
	_check("Ghouls from wave 1, Hounds from 3, Cultists from 4, Brutes from 5 (%s)" % [first_seen],
		first_seen.get("Ghoul") == 1 and first_seen.get("Hound") == 3 and first_seen.get("Cultist") == 4 and first_seen.get("Brute") == 5)
	var bosses: Array[String] = []
	for i: int in waves.size():
		for group: SpawnGroup in waves[i].groups:
			if group.enemy.is_boss:
				bosses.append("%d: %s" % [i + 1, group.enemy.display_name])
	_check("a boss in waves 5, 10 and 15, a different one each (%s)" % ", ".join(bosses),
		bosses == ["5: The Gravelord", "10: The Bone Colossus", "15: The Lich Warden"])
	_check("the waves use all 3 lanes", lanes.size() == 3)
	level.free()


func _test_victory_and_restart() -> void:
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	main.set("run_data", MapFixtures.tiny_run(MapFixtures.encounter(1, 2), MapFixtures.encounter(2, 2), load(ARENA)))
	main.set("run_seed", 1)
	root.add_child(main)
	await _frames(2)
	var level: Level = await MapFixtures.enter_first_battle(main)
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var cycle: RunCycle = level.get_node("%RunCycle")
	spawner.enemy_spawned.connect(func(e: Enemy) -> void:
		(e.get_node("%HealthComponent") as HealthComponent).take_damage.call_deferred(1000))
	var won: Array[int] = [0]
	var lost: Array[int] = [0]
	level.run_won.connect(func() -> void: won[0] += 1)
	level.run_lost.connect(func(_r: Level.LossReason) -> void: lost[0] += 1)
	var victory: VictoryScreen = main.get_node("%VictoryScreen")
	var game_over: GameOverScreen = main.get_node("%GameOverScreen")
	var map_screen: MapScreen = main.get_node("%MapScreen")
	cycle.start_wave()
	var offers: UpgradeOffers = level.get_node("%UpgradeOffers")
	await _until(func() -> bool: return offers.is_offer_open(), 300)
	_check("a won battle is not the run: its reward comes, no victory", won[0] == 0 and not victory.visible and offers.get_offer().size() == 3)
	offers.pick(0)
	await _frames(2)
	_check("after the reward, the map again", map_screen.visible and not level.is_active())
	map_screen.node_chosen.emit((main.call("get_map") as RunMap).get_choices()[0])
	await _frames(2)
	cycle.start_wave()
	await _until(func() -> bool: return cycle.get_phase() == RunCycle.Phase.BUILD and spawner.get_wave_number() == 1, 300)
	_check("after the boss fight's wave 1 of 2: no victory yet", won[0] == 0 and not victory.visible)
	cycle.start_wave()
	await _until(func() -> bool: return won[0] > 0, 300)
	await _frames(2)
	_check("beating the last chapter's boss wins the run, once", won[0] == 1 and lost[0] == 0)
	_check("the Victory screen shows (%s)" % (victory.get_node("%Subtitle") as Label).text, victory.visible and not game_over.visible
		and (victory.get_node("%Subtitle") as Label).text == "The fortress stands. Every chapter held.")
	_check("...with keyboard focus on its button", (victory.get_node("%RestartButton") as Button).has_focus())
	_check("the level is frozen", not level.can_process() and level.is_run_over())
	(level.get_node("Fortress") as Fortress).destroyed.emit()
	await _frames(2)
	_check("nothing can lose it afterwards", lost[0] == 0 and not game_over.visible)

	(victory.get_node("%RestartButton") as Button).pressed.emit()
	await _frames(2)
	var fresh: Level = _level_of(main)
	_check("Play again: a fresh run on its map, screen hidden", fresh != level and not victory.visible and map_screen.visible
		and (main.call("get_map") as RunMap).path.is_empty())
	main.queue_free()
	await _frames(2)


## The last enemy of the boss fight walks into a fortress at 10 HP: the fortress falls and the fight
## is over in the same moment. That is Game Over.
func _test_loss_beats_victory() -> void:
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	main.set("run_data", MapFixtures.tiny_run(null, MapFixtures.encounter(1, 1), load(ARENA)))
	root.add_child(main)
	await _frames(2)
	var level: Level = await MapFixtures.enter_first_battle(main)  # the boss is the only node
	(level.get_node("Hero") as Node2D).position = Vector2(-750, 330)
	var fortress: Fortress = level.get_node("Fortress")
	fortress.health.take_damage(90)
	var won: Array[int] = [0]
	level.run_won.connect(func() -> void: won[0] += 1)
	(level.get_node("%RunCycle") as RunCycle).start_wave()
	await _until(func() -> bool: return level.is_run_over(), 1200)
	await _frames(2)
	_check("the fortress falling to the last enemy is Game Over, not Victory",
		fortress.health.is_dead() and won[0] == 0 and (main.get_node("%GameOverScreen") as CanvasLayer).visible
		and not (main.get_node("%VictoryScreen") as CanvasLayer).visible)
	main.queue_free()
	await _frames(2)


func _level_of(main: Node) -> Level:
	for child: Node in main.get_children():
		if child is Level and not child.is_queued_for_deletion():
			return child
	return null


func _until(condition: Callable, max_frames: int) -> void:
	for _i: int in max_frames:
		if condition.call():
			return
		await physics_frame


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
