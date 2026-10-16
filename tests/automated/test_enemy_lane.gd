extends SceneTree
## Automated check for the lane, the Ghoul and the EnemySpawner.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>
## (--fixed-fps makes the ~55 s of simulated game time run as fast as the machine allows.)

const SCENE_PATH: String = "res://tests/test_enemy_lane.tscn"
const LANE_START: Vector2 = Vector2(-700, -250)
## Lane length 902 px, minus 16 px where the ghoul's hitbox first touches the fortress hurtbox,
## minus ~20 px saved by rounding the two corners (it aims LANE_LOOKAHEAD px ahead) => ~866 px at 1 px/frame.
const MIN_FRAMES_TO_FORTRESS: int = 850
const MAX_FRAMES_TO_FORTRESS: int = 890
## Half the width of the drawn lane: the ghoul may round corners but must stay on the visible path.
const MAX_OFF_LANE: float = 16.0

var _failures: int = 0


func _initialize() -> void:
	_test_ghoul_data()
	await _test_single_ghoul_reaches_fortress()
	await _test_hero_kills_ghoul()
	await _test_spawner_timing()
	await _test_full_run_destroys_fortress()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_ghoul_data() -> void:
	var data: EnemyData = load("res://data/enemies/ghoul.tres")
	_check("ghoul.tres loads as EnemyData", data != null and data.display_name == "Ghoul")
	_check("ghoul stats 30 HP / 60 speed / 10 dmg",
		data.max_health == 30 and is_equal_approx(data.move_speed, 60.0) and data.fortress_damage == 10)


func _test_single_ghoul_reaches_fortress() -> void:
	var level: Node = _make_level(1, 2.0)
	var spawner: EnemySpawner = level.get_node("%EnemySpawner")
	var fortress: Fortress = level.get_node("%Fortress")
	var lane: Path2D = level.get_node("Lane")
	await _frames(2)
	_check("one ghoul spawned", spawner.get_child_count() == 1)
	var ghoul: Enemy = spawner.get_child(0)
	_check("ghoul starts at lane start", ghoul.global_position.distance_to(LANE_START) < 3.0)
	_check("ghoul HP set from data (30)", (ghoul.get_node("%HealthComponent") as HealthComponent).current_health == 30)

	var frames: int = 0
	var max_off_lane: float = 0.0
	while is_instance_valid(ghoul) and frames < 1500:
		var local: Vector2 = lane.to_local(ghoul.global_position)
		max_off_lane = maxf(max_off_lane, local.distance_to(lane.curve.get_closest_point(local)))
		await physics_frame
		frames += 1
	_check("ghoul stays on the drawn lane (max %.2f px off centre)" % max_off_lane, max_off_lane < MAX_OFF_LANE)
	_check("ghoul reaches fortress at 60 px/s (%d frames, expected %d-%d)" % [frames, MIN_FRAMES_TO_FORTRESS, MAX_FRAMES_TO_FORTRESS],
		frames >= MIN_FRAMES_TO_FORTRESS and frames <= MAX_FRAMES_TO_FORTRESS)
	_check("ghoul removed on contact", not is_instance_valid(ghoul))
	_check("fortress took 10 damage (HP %d)" % fortress.health.current_health, fortress.health.current_health == 90)
	await _free(level)


func _test_hero_kills_ghoul() -> void:
	var level: Node = _make_level(1, 2.0)
	var spawner: EnemySpawner = level.get_node("%EnemySpawner")
	var fortress: Fortress = level.get_node("%Fortress")
	var hero: Hero = level.get_node("Hero")
	await _frames(2)
	var ghoul: Enemy = spawner.get_child(0)
	var health: HealthComponent = ghoul.get_node("%HealthComponent")
	for swing: int in 3:
		hero.position = ghoul.global_position + Vector2(30, 0)
		await _frames(1)
		hero.attack(ghoul.global_position)
		await _frames(27)  # longer than the 0.4 s cooldown
		if swing == 1:
			_check("two swings leave the ghoul at 10 HP", is_instance_valid(ghoul) and health.current_health == 10)
	_check("third swing kills the ghoul", not is_instance_valid(ghoul))
	_check("a killed ghoul never damages the fortress", fortress.health.current_health == 100)
	await _free(level)


func _test_spawner_timing() -> void:
	var level: Node = _make_level(5, 0.5)
	var spawner: EnemySpawner = level.get_node("%EnemySpawner")
	var spawn_positions: Array[Vector2] = []
	spawner.enemy_spawned.connect(func(e: Enemy) -> void: spawn_positions.append(e.global_position))
	# _make_level added the level already; the first spawn happens on the first physics frame.
	await _frames(1)
	_check("first ghoul spawns immediately", spawn_positions.size() == 1)
	await _frames(125)  # t ~ 2.1 s: spawns at 0, 0.5, 1.0, 1.5, 2.0
	_check("5 ghouls after ~2.1 s (got %d)" % spawn_positions.size(), spawn_positions.size() == 5)
	await _frames(120)
	_check("spawner stops at spawn_count", spawn_positions.size() == 5 and spawner.get_child_count() == 5)
	var all_at_start: bool = spawn_positions.all(func(p: Vector2) -> bool: return p.distance_to(LANE_START) < 1.0)
	_check("every ghoul spawns at the lane start", all_at_start)
	await _free(level)


func _test_full_run_destroys_fortress() -> void:
	var level: Node = _make_level(10, 2.0)
	var spawner: EnemySpawner = level.get_node("%EnemySpawner")
	var fortress: Fortress = level.get_node("%Fortress")
	var destroyed_count: Array[int] = [0]
	fortress.destroyed.connect(func() -> void: destroyed_count[0] += 1)
	var frames: int = 0
	while not fortress.health.is_dead() and frames < 2400:
		await physics_frame
		frames += 1
	_check("10 unopposed ghouls destroy the fortress (%.1f s)" % (frames / 60.0), fortress.health.is_dead())
	_check("fortress destroyed signal once", destroyed_count[0] == 1)
	await _frames(5)
	_check("no ghouls left behind", spawner.get_child_count() == 0)
	await _free(level)


## Instances the sandbox scene with custom spawner settings (set before _ready runs).
func _make_level(count: int, interval: float) -> Node:
	var level: Node = (load(SCENE_PATH) as PackedScene).instantiate()
	var spawner: EnemySpawner = level.get_node("%EnemySpawner")
	spawner.spawn_count = count
	spawner.spawn_interval = interval
	root.add_child(level)
	return level


func _free(level: Node) -> void:
	level.queue_free()
	await _frames(2)


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
