extends SceneTree
## Automated check for ground-targeted cannon shells: a shell is fired at a ground point (the
## target's position at impact, with simple lead), never follows the target, shows its landing spot,
## and explodes there: it hits whatever stands in the blast and misses an enemy that got away.
## Arrows and frost bolts stay homing. Shells never land beyond the range.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const CANNON: TowerData = preload("res://data/towers/cannon.tres")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const HERO_AWAY: Vector2 = Vector2(380, 380)

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_hit_and_marker()
	await _test_miss_when_target_gets_away()
	await _test_lead_on_a_walking_target()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_data() -> void:
	_check("the cannon fires shells; archer and frost stay homing",
		not CANNON.homing and ARCHER.homing and (load("res://data/towers/frost.tres") as TowerData).homing)


## A standing ghoul: the shell lands on it, the marker shows the blast, the ghoul takes the damage.
func _test_hit_and_marker() -> void:
	var level: Level = _make_level()
	await _frames(2)
	var tower: Tower = _build(level, 3, CANNON)
	var ghoul: Enemy = _stationary(level, tower.global_position + Vector2(120, 30))
	var shell: Projectile = await _next_shot(tower)
	_check("the cannon fires a shell (not a homing shot)", shell != null and shell.is_shell())
	if shell == null:
		level.queue_free()
		return
	var aimed: Vector2 = shell.get_destination()
	_check("...aimed at the standing target (%.0f px off)" % aimed.distance_to(ghoul.global_position), aimed.distance_to(ghoul.global_position) < 1.0)
	var marker: LandingMarker = shell.find_children("*", "LandingMarker", true, false).front() if not shell.find_children("*", "LandingMarker", true, false).is_empty() else null
	_check("a landing marker shows where it will land", marker != null and marker.visible and marker.global_position.distance_to(aimed) < 1.0)
	await _frames(10)
	_check("the shell flies along the ground with a raised sprite (arc)", (shell.get_node("%Sprite") as Node2D).position.y < 0.0)
	await _until(func() -> bool: return _hp(ghoul) < ghoul.data.max_health, 120)
	_check("it explodes on the spot and hits the target for %d" % CANNON.damage, _hp(ghoul) == ghoul.data.max_health - CANNON.damage)
	level.queue_free()
	await _frames(2)


## The target moves away after the shell is fired: the shell keeps its landing point and misses it;
## another enemy standing on that point is hit instead.
func _test_miss_when_target_gets_away() -> void:
	var level: Level = _make_level()
	await _frames(2)
	var tower: Tower = _build(level, 3, CANNON)
	var runner: Enemy = _stationary(level, tower.global_position + Vector2(130, 0))
	var shell: Projectile = await _next_shot(tower)
	if shell == null:
		_check("a shell was fired", false)
		level.queue_free()
		return
	var landing: Vector2 = shell.get_destination()
	runner.global_position = landing + Vector2(0, CANNON.splash_radius + 60.0)  # sidesteps out of the blast
	var bystander: Enemy = _stationary(level, landing + Vector2(10, 0))
	await _frames(1)
	(bystander.get_node("%HealthComponent") as HealthComponent).setup(1000)
	await _frames(4)
	_check("the shell does not follow its target (landing point unchanged)", shell.get_destination() == landing)
	await _until(func() -> bool: return not is_instance_valid(shell) or not (shell.get_node("%Sprite") as CanvasItem).visible, 120)
	await _frames(3)
	_check("the target that got away is not hit (HP %d)" % _hp(runner), _hp(runner) == runner.data.max_health)
	_check("whatever stands in the blast is hit (HP %d)" % _hp(bystander), _hp(bystander) == 1000 - CANNON.damage)
	level.queue_free()
	await _frames(2)


## A ghoul walking along the lane: the shell is aimed ahead of it (lead) and still hits.
func _test_lead_on_a_walking_target() -> void:
	var level: Level = _make_level()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = [WaveFixtures.make_wave(1, 1.0), WaveData.new()]
	await _frames(2)
	var tower: Tower = _build(level, 1, CANNON)  # (-420, -330), above the west road's first stretch
	spawner.start_next_wave()
	await _frames(2)
	var ghoul: Enemy = spawner.get_child(0)
	(ghoul.get_node("%HealthComponent") as HealthComponent).setup(1000)
	var shell: Projectile = await _next_shot(tower, 900)
	if shell == null:
		_check("a shell was fired at the walking ghoul", false)
		level.queue_free()
		return
	var lead: float = shell.get_destination().x - ghoul.global_position.x
	_check("the shell is aimed ahead of the walking ghoul (%.0f px lead)" % lead, lead > 10.0)
	_check("...and never beyond the range", tower.global_position.distance_to(shell.get_destination()) <= tower.get_attack_range() + 0.5)
	await _until(func() -> bool: return (ghoul.get_node("%HealthComponent") as HealthComponent).current_health < 1000, 120)
	_check("the led shell hits it", (ghoul.get_node("%HealthComponent") as HealthComponent).current_health == 1000 - CANNON.damage)
	var far: Vector2 = tower.aim_point(ghoul)
	ghoul.global_position = tower.global_position + Vector2(tower.get_attack_range() - 5.0, 0)
	ghoul.velocity = Vector2(400, 0)
	far = tower.aim_point(ghoul)
	_check("aiming at a fast target near the edge stays inside the range", tower.global_position.distance_to(far) <= tower.get_attack_range() + 0.5)
	level.queue_free()
	await _frames(2)


func _make_level() -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	(level.get_node("Hero") as Node2D).position = HERO_AWAY
	root.add_child(level)
	return level


func _build(level: Level, slot_index: int, data: TowerData) -> Tower:
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	(level.get_node("%Economy") as Economy).earn(data.cost, Economy.Source.REFUND)
	builder.build(builder.get_slots()[slot_index], data)
	return builder.get_slots()[slot_index].tower


func _stationary(level: Level, at: Vector2) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = GHOUL
	enemy.position = at
	level.add_child(enemy)
	(enemy.get_node("%AttackRange") as Area2D).monitoring = false
	return enemy


func _next_shot(tower: Tower, max_frames: int = 300) -> Projectile:
	for _i: int in max_frames:
		await physics_frame
		for child: Node in tower.get_children():
			if child is Projectile:
				return child
	return null


## Untyped: the enemy may already be freed (killed).
func _hp(enemy: Variant) -> int:
	if not is_instance_valid(enemy):
		return 0
	return ((enemy as Enemy).get_node("%HealthComponent") as HealthComponent).current_health


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
