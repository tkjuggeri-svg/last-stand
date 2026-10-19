extends SceneTree
## Automated check for the full run: the level's 10 hand-authored waves (rising curve, Hounds and
## Brutes introduced gradually, all 3 lanes used), Victory after the last wave through the real
## main.tscn (frozen level, own screen, Play again starts a fresh run), and that a run lost in the
## same moment as the last wave ends is a loss, not a win.
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
	root.add_child(main)
	await _frames(2)
	var level: Level = _level_of(main)
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var cycle: RunCycle = level.get_node("%RunCycle")
	spawner.waves = [WaveFixtures.make_wave(2, 0.2), WaveFixtures.make_wave(2, 0.2)]  # a short run
	WaveFixtures.no_upgrades(level)
	spawner.enemy_spawned.connect(func(e: Enemy) -> void:
		(e.get_node("%HealthComponent") as HealthComponent).take_damage.call_deferred(1000))
	var won: Array[int] = [0]
	var lost: Array[int] = [0]
	level.run_won.connect(func() -> void: won[0] += 1)
	level.run_lost.connect(func(_r: Level.LossReason) -> void: lost[0] += 1)
	var victory: VictoryScreen = main.get_node("%VictoryScreen")
	var game_over: GameOverScreen = main.get_node("%GameOverScreen")
	cycle.start_wave()
	await _until(func() -> bool: return cycle.get_phase() == RunCycle.Phase.BUILD and spawner.get_wave_number() == 1, 200)
	_check("after wave 1 of 2: no victory yet", won[0] == 0 and not victory.visible)
	cycle.start_wave()
	await _until(func() -> bool: return won[0] > 0, 200)
	await _frames(2)
	_check("clearing the last wave wins the run, once", won[0] == 1 and lost[0] == 0)
	_check("the Victory screen shows (%s)" % (victory.get_node("%Subtitle") as Label).text, victory.visible and not game_over.visible
		and (victory.get_node("%Subtitle") as Label).text == "The fortress stands. All 2 waves held.")
	_check("...with keyboard focus on its button", (victory.get_node("%RestartButton") as Button).has_focus())
	_check("the level is frozen", not level.can_process() and level.is_run_over())
	(level.get_node("Fortress") as Fortress).destroyed.emit()
	await _frames(2)
	_check("nothing can lose it afterwards", lost[0] == 0 and not game_over.visible)

	(victory.get_node("%RestartButton") as Button).pressed.emit()
	await _frames(2)
	var fresh: Level = _level_of(main)
	_check("Play again: a fresh run, screen hidden, wave 1 / 15 in the build phase",
		fresh != level and not victory.visible and fresh.can_process()
		and (fresh.get_node("%RunCycle") as RunCycle).get_phase() == RunCycle.Phase.BUILD
		and (fresh.get_node("%RunCycle") as RunCycle).get_current_wave_number() == 1
		and (fresh.get_node("WaveSpawner") as WaveSpawner).get_wave_count() == 15)
	main.queue_free()
	await _frames(2)


## The last enemy of the last wave walks into a fortress at 10 HP: the fortress falls and the wave is
## over in the same moment. That is Game Over.
func _test_loss_beats_victory() -> void:
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(2)
	var level: Level = _level_of(main)
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveFixtures.make_wave(1, 1.0)]
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
		if child is Level:
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
