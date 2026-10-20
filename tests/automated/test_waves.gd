extends SceneTree
## Automated check for data-driven waves: WaveData/SpawnGroup timing (parallel groups, delays),
## wave numbers and counts, wave_started/wave_cleared once per wave, WaveRewards per real wave,
## empty waves, and that every wave file in data/waves loads.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const WAVES_DIR: String = "res://data/waves"
## Far from the lane: the hero stays out of every fight.
const HERO_AWAY: Vector2 = Vector2(-750, 330)

var _failures: int = 0


func _initialize() -> void:
	_test_wave_files()
	await _test_groups_and_timing()
	await _test_wave_cycle_and_rewards()
	await _test_empty_wave()
	await _test_health_multiplier()
	await _test_speed_multiplier()
	_test_late_waves_pressure()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_wave_files() -> void:
	var files: PackedStringArray = DirAccess.get_files_at(WAVES_DIR)
	var ok: bool = not files.is_empty()
	for file: String in files:
		if not file.ends_with(".tres"):
			continue
		var wave: WaveData = load(WAVES_DIR.path_join(file)) as WaveData
		ok = ok and wave != null and wave.get_enemy_total() > 0
		if wave != null:
			for group: SpawnGroup in wave.groups:
				ok = ok and group.enemy != null and group.count > 0 and group.interval > 0.0 and group.delay >= 0.0
	_check("every wave file loads with real spawn groups (%d files)" % files.size(), ok)


## Two groups in one wave: 3 enemies every 1 s from t=0, and 2 every 0.5 s from t=1.2.
func _test_groups_and_timing() -> void:
	var a: WaveData = WaveFixtures.make_wave(3, 1.0)
	var b: WaveData = WaveFixtures.make_wave(2, 0.5, WaveFixtures.GHOUL, 0, 1.2)
	a.groups.append(b.groups[0])
	var level: Level = _make_level([a])
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	await _frames(5)
	_check("no wave before it is started (wave %d, %d enemies)" % [spawner.get_wave_number(), spawner.get_child_count()],
		spawner.get_wave_number() == 0 and spawner.get_child_count() == 0 and not spawner.is_wave_active())
	var times: Array[float] = []
	var start_frame: Array[int] = [0]
	var frame: Array[int] = [0]
	spawner.enemy_spawned.connect(func(_e: Enemy) -> void: times.append((frame[0] - start_frame[0]) / 60.0))
	var started: Array[int] = []
	spawner.wave_started.connect(func(n: int) -> void: started.append(n))
	_check("start_next_wave starts wave 1", spawner.start_next_wave() and started == [1] and spawner.get_wave_number() == 1)
	_check("...which sends 5 enemies, all still to come", spawner.get_wave_enemy_total() == 5 and spawner.get_remaining_count() == 5)
	_check("a second start while the wave runs is refused", not spawner.start_next_wave() and started == [1])
	for _i: int in 180:
		await physics_frame
		frame[0] += 1
	var expected: Array[float] = [0.0, 1.0, 1.2, 1.7, 2.0]
	var timing_ok: bool = times.size() == expected.size()
	for i: int in mini(times.size(), expected.size()):
		timing_ok = timing_ok and absf(times[i] - expected[i]) <= 1.5 / 60.0
	_check("groups run in parallel with their delays (spawn times %s)" % [times], timing_ok)
	await _free(level)


func _test_wave_cycle_and_rewards() -> void:
	var level: Level = _make_level([WaveFixtures.make_wave(2, 0.2), WaveFixtures.make_wave(3, 0.2)])
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var economy: Economy = level.get_node("%Economy")
	var cleared: Array[int] = []
	spawner.wave_cleared.connect(func(n: int) -> void: cleared.append(n))
	spawner.enemy_spawned.connect(func(e: Enemy) -> void:
		(e.get_node("%HealthComponent") as HealthComponent).take_damage.call_deferred(1000))
	await _frames(2)
	spawner.start_next_wave()
	await _until(func() -> bool: return cleared.size() == 1, 120)
	_check("wave 1 clears once all its enemies are dead", cleared == [1] and not spawner.is_wave_active())
	_check("...remaining count back to 0", spawner.get_remaining_count() == 0 and spawner.get_living_count() == 0)
	var reward: int = WaveFixtures.GHOUL.gold_reward
	var start: int = economy.starting_gold
	_check("...and pays kills + perfect-defense bonus (gold %d)" % economy.get_gold(), economy.get_gold() == start + 2 * reward + roundi(2 * reward * 0.1))
	_check("a next wave exists", spawner.has_next_wave() and spawner.get_wave_count() == 2)
	spawner.start_next_wave()
	_check("wave 2 counts its own enemies", spawner.get_wave_number() == 2 and spawner.get_remaining_count() == 3)
	await _until(func() -> bool: return cleared.size() == 2, 120)
	_check("wave 2 clears and pays its own bonus (gold %d)" % economy.get_gold(), cleared == [1, 2] and economy.get_gold() == start + 5 * reward + roundi(2 * reward * 0.1) + roundi(3 * reward * 0.1))
	_check("after the last wave nothing more starts", not spawner.has_next_wave() and not spawner.start_next_wave())
	await _free(level)


func _test_empty_wave() -> void:
	var level: Level = _make_level([WaveData.new()])
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var cleared: Array[int] = []
	spawner.wave_cleared.connect(func(n: int) -> void: cleared.append(n))
	await _frames(2)
	spawner.start_next_wave()
	await _frames(30)
	_check("a wave without enemies spawns nothing and is over at once", cleared == [1] and spawner.get_child_count() == 0)
	await _free(level)


## A wave's health_multiplier makes its enemies tougher; the curve rises over the level's waves.
func _test_health_multiplier() -> void:
	var tough: WaveData = WaveFixtures.make_wave(1, 1.0)
	tough.health_multiplier = 1.5
	var level: Level = _make_level([tough, WaveData.new()])
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	await _frames(2)
	spawner.start_next_wave()
	await _frames(3)
	var enemy: Enemy = spawner.get_child(0)
	_check("a wave with health x1.5 spawns a 45 HP ghoul (%d)" % (enemy.get_node("%HealthComponent") as HealthComponent).max_health,
		(enemy.get_node("%HealthComponent") as HealthComponent).max_health == roundi(WaveFixtures.GHOUL.max_health * 1.5))
	level.queue_free()
	await _frames(2)
	var real: Level = (load(ARENA) as PackedScene).instantiate()
	var multipliers: Array = (real.get_node("WaveSpawner") as WaveSpawner).waves.map(func(w: WaveData) -> float: return w.health_multiplier)
	var rising: bool = true
	for i: int in range(1, multipliers.size()):
		rising = rising and multipliers[i] >= multipliers[i - 1]
	_check("the level's waves get tougher towards the end (%s)" % [multipliers], rising and multipliers.back() > 1.5 and multipliers[0] == 1.0)
	real.free()


## A wave's speed_multiplier makes its regulars faster, never its boss.
func _test_speed_multiplier() -> void:
	var fast: WaveData = WaveFixtures.make_wave(1, 1.0)
	fast.groups.append(WaveFixtures.make_wave(1, 1.0, load("res://data/enemies/colossus.tres") as EnemyData).groups[0])
	fast.speed_multiplier = 1.2
	var level: Level = _make_level([fast, WaveData.new()])
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	await _frames(2)
	spawner.start_next_wave()
	await _frames(3)
	var ghoul: Enemy = null
	var boss: Enemy = null
	for child: Node in spawner.get_children():
		if child is Enemy:
			if (child as Enemy).data.is_boss:
				boss = child
			else:
				ghoul = child
	_check("a wave with speed x1.2 moves its ghoul at %.1f" % ghoul.get_move_speed(), is_equal_approx(ghoul.get_move_speed(), WaveFixtures.GHOUL.move_speed * 1.2))
	_check("...but its boss at its own speed (%.1f)" % boss.get_move_speed(), is_equal_approx(boss.get_move_speed(), boss.data.move_speed))
	await _free(level)


## Waves 10-15 press on every lane at once, with Cultists on at least two lanes, and their regulars
## get faster; waves 1-5 stay as they were (normal speed).
func _test_late_waves_pressure() -> void:
	var real: Level = (load(ARENA) as PackedScene).instantiate()
	var waves: Array[WaveData] = (real.get_node("WaveSpawner") as WaveSpawner).waves
	var lanes_ok: bool = true
	var cultists_ok: bool = true
	for i: int in range(9, waves.size()):
		var lanes: Dictionary = {}
		var cultist_lanes: Dictionary = {}
		for group: SpawnGroup in waves[i].groups:
			if not group.enemy.is_boss and group.count >= 4:
				lanes[group.lane] = true
			if group.enemy.resource_path.ends_with("cultist.tres"):
				cultist_lanes[group.lane] = true
		lanes_ok = lanes_ok and lanes.size() == 3
		cultists_ok = cultists_ok and cultist_lanes.size() >= 2
	_check("waves 10-15 send real groups down all three lanes", lanes_ok)
	_check("waves 10-15 send Cultists down at least two lanes", cultists_ok)
	var speeds: Array = waves.map(func(w: WaveData) -> float: return w.speed_multiplier)
	var rising: bool = true
	for i: int in range(1, speeds.size()):
		rising = rising and speeds[i] >= speeds[i - 1]
	_check("regulars get faster in the late waves, not early (%s)" % [speeds], rising and speeds[4] == 1.0 and speeds.back() > 1.0)
	real.free()


func _make_level(waves: Array[WaveData]) -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = waves
	spawner.autostart = false
	WaveFixtures.no_upgrades(level)
	(level.get_node("Hero") as Node2D).position = HERO_AWAY
	root.add_child(level)
	return level


func _free(level: Node) -> void:
	level.queue_free()
	await _frames(2)


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
