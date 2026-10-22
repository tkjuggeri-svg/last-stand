extends SceneTree
## Automated check for the game feel (M8.5): screen shake on the current camera, scaled by the Screen
## shake setting (Reduced halves it, Off: none), whole-pixel offsets (within a pixel of the strength) that
## fade back to 0; hit-stops (skipped headless unless asked; time back to normal after); the
## settings saved and loaded; the hero's sword knocks enemies back along their lane (Brutes less,
## bosses not at all); enemies report the damage they take summed (a flood of hits: one number), and
## once more as they die, and the level shows it as a number unless Damage numbers is off.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const SETTINGS_PATH: String = "user://test_juice_settings.cfg"
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const BRUTE: EnemyData = preload("res://data/enemies/brute.tres")
const LICH: EnemyData = preload("res://data/enemies/lich.tres")

var _failures: int = 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	GameSettings.path = SETTINGS_PATH
	GameSettings.load_and_apply()
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveFixtures.make_wave(1, 0.3)]
	WaveFixtures.no_upgrades(level)
	root.add_child(level)
	await _frames(3)
	await _test_shake(level)
	await _test_hit_stop(level)
	_test_settings()
	await _test_knockback(level)
	await _test_numbers(level)
	level.queue_free()
	await _frames(2)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_shake(level: Level) -> void:
	var camera: Camera2D = level.get_viewport().get_camera_2d()
	Juice.shake(level, 6.0, 0.2)
	await process_frame
	await process_frame
	var shaker: ScreenShake = camera.get_node_or_null(^"ScreenShake")
	_check("a shake moves the camera by whole pixels (%s)" % camera.offset, shaker != null and shaker.is_shaking() and camera.offset.length() > 0.0
		and camera.offset == camera.offset.round() and camera.offset.length() <= 7.0)
	await _real_seconds(0.3)
	_check("...and fades back to rest", not shaker.is_shaking() and camera.offset == Vector2.ZERO)
	GameSettings.set_screen_shake(0.0)
	Juice.shake(level, 6.0, 0.2)
	await process_frame
	_check("Screen shake Off: no shake", not shaker.is_shaking() and camera.offset == Vector2.ZERO)
	GameSettings.set_screen_shake(0.5)
	Juice.shake(level, 6.0, 0.5)
	await process_frame
	_check("Reduced: at most half (%s)" % camera.offset, camera.offset.length() <= 4.0)
	await _real_seconds(0.6)


func _test_hit_stop(level: Level) -> void:
	Juice.hit_stop(level, 0.1)
	_check("a small hit-stop is skipped headless (tests stay deterministic)", is_equal_approx(Engine.time_scale, 1.0))
	Juice.hit_stop(level, 0.1, 0.25, true)
	var slowed: bool = is_equal_approx(Engine.time_scale, 0.25)
	await _real_seconds(0.2)
	_check("a forced one slows time, then it runs normally again", slowed and is_equal_approx(Engine.time_scale, 1.0))


func _test_settings() -> void:
	GameSettings.set_screen_shake(0.5)
	GameSettings.set_damage_numbers(false)
	GameSettings.load_and_apply()
	_check("the settings are saved and loaded (shake 0.5, numbers off)", is_equal_approx(GameSettings.get_screen_shake(), 0.5)
		and not GameSettings.shows_damage_numbers())
	GameSettings.set_damage_numbers(true)
	GameSettings.set_screen_shake(1.0)


func _test_knockback(level: Level) -> void:
	var ghoul: Enemy = level.spawner.spawn_extra(GHOUL, 0)
	var brute: Enemy = level.spawner.spawn_extra(BRUTE, 0)
	var lich: Enemy = level.spawner.spawn_extra(LICH, 0)
	for enemy: Enemy in [ghoul, brute, lich]:
		enemy.global_position = enemy.lane.to_global(enemy.lane.curve.sample_baked(400.0))
	await _frames(2)
	var before: Array[float] = [ghoul.get_lane_progress(), brute.get_lane_progress(), lich.get_lane_progress()]
	var hero: Hero = level.get_node("Hero")
	var hitbox: Hitbox = hero.get_node("%AttackHitbox")
	for enemy: Enemy in [ghoul, brute, lich]:
		hitbox.hit.emit(enemy.get_node("%Hurtbox"))
	var dragged: Array[bool] = [ghoul.get_status().is_dragged(), brute.get_status().is_dragged(), lich.get_status().is_dragged()]
	await _frames(4)
	var pushed: Array[float] = [before[0] - ghoul.get_lane_progress(), before[1] - brute.get_lane_progress()]
	_check("the sword knocks back along the lane: a Ghoul %.0f px, a Brute %.0f (less); the Lich not at all" % pushed,
		dragged[0] and dragged[1] and not dragged[2] and pushed[0] > 0.0 and pushed[1] < pushed[0])
	for enemy: Enemy in [ghoul, brute, lich]:
		enemy.queue_free()
	await _frames(2)


func _test_numbers(level: Level) -> void:
	var spawned: Array[Enemy] = []
	level.spawner.enemy_spawned.connect(func(e: Enemy) -> void: spawned.append(e))
	level.run_cycle.start_wave()
	for _i: int in 120:
		if not spawned.is_empty():
			break
		await physics_frame
	var ghoul: Enemy = spawned[0]
	await _frames(2)
	var reports: Array[int] = []
	ghoul.damage_reported.connect(func(amount: int, _at: Vector2) -> void: reports.append(amount))
	for _i: int in 3:
		ghoul.get_health().take_damage(2)
	await _frames(2)
	ghoul.get_health().take_damage(1)
	await _frames(2)
	_check("three hits in a frame: one number (%s)" % str(reports), reports == [6])
	ghoul.get_health().take_damage(100000)
	await _frames(1)
	_check("...the rest as it dies (%s)" % str(reports), reports.size() == 2 and reports[1] > 1)
	var effects: Node = level.get_node("%Effects")
	var shown: int = effects.get_children().filter(func(n: Node) -> bool: return n is DamageNumber and (n.get_node("%Label") as Label).text == "6").size()
	_check("the level shows them on its effects layer (%d)" % shown, shown >= 1)
	GameSettings.set_damage_numbers(false)
	var before: int = effects.get_children().filter(func(n: Node) -> bool: return n is DamageNumber).size()
	var other: Enemy = level.spawner.spawn_extra(GHOUL, 0)
	await _frames(2)
	other.get_health().take_damage(3)
	await _frames(2)
	_check("Damage numbers off: none", effects.get_children().filter(func(n: Node) -> bool: return n is DamageNumber).size() <= before)
	GameSettings.set_damage_numbers(true)
	other.queue_free()


func _real_seconds(seconds: float) -> void:
	var end: int = Time.get_ticks_msec() + roundi(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		await process_frame


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
