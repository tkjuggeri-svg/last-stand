extends SceneTree
## Automated check for the build/combat cycle: a run waits in the build phase (no enemies) until the
## Start button or the start_wave key, the combat phase ends when the wave's last enemy is dead or has
## reached the fortress, then the next build phase; after the last wave the run is finished.
## Also the HUD's wave panel and enemy count, and that building/selling works in both phases.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
## Far from the lane: the hero stays out of every fight.
const HERO_AWAY: Vector2 = Vector2(-750, 330)

var _failures: int = 0


func _initialize() -> void:
	await _test_cycle()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_cycle() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = [WaveFixtures.make_wave(2, 0.3), WaveFixtures.make_wave(3, 0.3)]
	(level.get_node("Hero") as Node2D).position = HERO_AWAY
	root.add_child(level)
	await _frames(2)
	var cycle: RunCycle = level.get_node("%RunCycle")
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var hud: CanvasLayer = level.get_node("HUD")
	var button: Button = hud.get_node("%StartWaveButton")
	var phases: Array[RunCycle.Phase] = []
	cycle.phase_changed.connect(func(p: RunCycle.Phase) -> void: phases.append(p))
	var finished: Array[int] = [0]
	cycle.all_waves_cleared.connect(func() -> void: finished[0] += 1)

	# --- Build phase before wave 1 ---
	await _frames(300)
	_check("the run starts in the build phase and no enemy comes on its own (5 s)",
		cycle.get_phase() == RunCycle.Phase.BUILD and spawner.get_child_count() == 0 and spawner.get_wave_number() == 0)
	_check("HUD: wave 1 / 2, build phase, Start button, next wave's size (%s | %s | %s)" % [_text(hud, "%WaveLabel"), _text(hud, "%PhaseLabel"), _text(hud, "%EnemyStatsLabel")],
		_text(hud, "%WaveLabel") == "Wave 1 / 2" and _text(hud, "%PhaseLabel") == "Build phase"
		and button.visible and _text(hud, "%EnemyStatsLabel") == "Next wave: 2 enemies")
	_check("building works in the build phase", builder.build(builder.get_slots()[5], ARCHER))

	# --- Combat: the Start button ---
	button.pressed.emit()
	await _frames(2)
	_check("Start wave begins the combat phase", cycle.get_phase() == RunCycle.Phase.COMBAT and phases == [RunCycle.Phase.COMBAT])
	_check("HUD: combat, button hidden, enemies left of the wave (%s)" % _text(hud, "%EnemyStatsLabel"),
		_text(hud, "%PhaseLabel") == "Combat" and not button.visible and _text(hud, "%EnemyStatsLabel") == "Enemies left: 2 / 2")
	_check("a second start during combat is refused", not cycle.start_wave() and spawner.get_wave_number() == 1)
	await _press_start_wave()
	_check("...also with the key", spawner.get_wave_number() == 1)
	_check("selling works in the combat phase", builder.sell(builder.get_slots()[5]) > 0)
	_check("building works in the combat phase", builder.build(builder.get_slots()[5], ARCHER))
	builder.sell(builder.get_slots()[5])  # no tower: the second ghoul must leak

	# One killed, one walks into the fortress: both end the wave.
	await _until(func() -> bool: return spawner.get_child_count() > 0, 30)
	(spawner.get_child(0).get_node("%HealthComponent") as HealthComponent).take_damage(1000)
	await _until(func() -> bool: return cycle.get_phase() != RunCycle.Phase.COMBAT, 1800)
	var fortress: Fortress = level.get_node("Fortress")
	_check("the wave ends once its last enemy is dead or at the fortress (fortress %d HP)" % fortress.health.current_health,
		cycle.get_phase() == RunCycle.Phase.BUILD and fortress.health.current_health == 90 and spawner.get_living_count() == 0)
	_check("HUD: next build phase for wave 2 / 2 (%s, %s)" % [_text(hud, "%WaveLabel"), _text(hud, "%EnemyStatsLabel")],
		_text(hud, "%WaveLabel") == "Wave 2 / 2" and button.visible and _text(hud, "%EnemyStatsLabel") == "Next wave: 3 enemies")

	# --- Wave 2 with the key, then the run is finished ---
	await _frames(120)
	_check("no enemies between waves", spawner.get_child_count() == 0)
	spawner.enemy_spawned.connect(func(e: Enemy) -> void:
		(e.get_node("%HealthComponent") as HealthComponent).take_damage.call_deferred(1000))
	await _press_start_wave()
	_check("the start_wave key starts wave 2", cycle.get_phase() == RunCycle.Phase.COMBAT and spawner.get_wave_number() == 2)
	await _until(func() -> bool: return cycle.get_phase() == RunCycle.Phase.FINISHED, 300)
	_check("after the last wave the run is finished, once", cycle.get_phase() == RunCycle.Phase.FINISHED and finished[0] == 1)
	_check("HUD: all waves cleared, no Start button", _text(hud, "%PhaseLabel") == "All waves cleared" and not button.visible)
	_check("no wave can start any more", not cycle.start_wave())
	level.queue_free()
	await _frames(2)


func _text(hud: Node, path: String) -> String:
	return (hud.get_node(path) as Label).text


func _press_start_wave() -> void:
	var press: InputEventAction = InputEventAction.new()
	press.action = "start_wave"
	press.pressed = true
	Input.parse_input_event(press)
	await _frames(1)
	var release: InputEventAction = InputEventAction.new()
	release.action = "start_wave"
	Input.parse_input_event(release)
	await _frames(1)


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
