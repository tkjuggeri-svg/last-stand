extends SceneTree
## Automated check for burning (after the Brazier playtest): fire is strong against a crowd but never
## stacks on one enemy. Burning ground sets every enemy in it on fire (a swarm all burns); an enemy in
## two patches, or in two towers' fire, burns at the strongest rate, not the sum; a weaker fire changes
## nothing while a stronger one burns; it keeps burning for a moment after stepping out, then stops;
## Brutes and bosses burn slower (EnemyData.burn_taken); a burning enemy shows it (its tint).
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const BURN_ZONE_SCENE: PackedScene = preload("res://entities/towers/burn_zone.tscn")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const BRUTE: EnemyData = preload("res://data/enemies/brute.tres")
const GRAVELORD: EnemyData = preload("res://data/enemies/gravelord.tres")
const SPOT: Vector2 = Vector2(-600, 300)
const HP: int = 10000
## Seconds of burning in a 2 s measurement: a patch first ignites what stands in it at its first tick.
const BURNING_IN_TWO_SECONDS: float = 2.0 - BurnZone.TICK

var _failures: int = 0


func _initialize() -> void:
	await _test_swarm()
	await _test_no_stacking()
	await _test_stronger_wins()
	await _test_afterburn()
	await _test_tough()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


## Five Ghouls on one patch: every one of them burns at its rate.
func _test_swarm() -> void:
	var level: Level = await _level()
	var ghouls: Array[Enemy] = []
	for i: int in 5:
		ghouls.append(_stationary(level, SPOT + Vector2((i - 2) * 8, 0), GHOUL))
	_zone(level, SPOT, 12.0, 4.0, 60.0)
	await _frames(120)
	var expected: int = roundi(12.0 * BURNING_IN_TWO_SECONDS)
	var all_burned: bool = ghouls.all(func(g: Enemy) -> bool: return absi(_lost(g) - expected) <= 2 and g.get_status().is_burning())
	_check("a crowd on burning ground: every enemy burns at its rate (%s HP lost in 2 s at 12/s)" % str(ghouls.map(_lost)), all_burned)
	_check("...and shows it (its tint)", (ghouls[0].get_node("%Sprite") as CanvasItem).self_modulate != Color.WHITE)
	level.queue_free()
	await _frames(2)


## Two patches on the same spot (two Braziers, or a Brazier and Hellfire): no more than one.
func _test_no_stacking() -> void:
	var level: Level = await _level()
	var one: Enemy = _stationary(level, SPOT, GHOUL)
	var two: Enemy = _stationary(level, SPOT + Vector2(0, 200), GHOUL)
	_zone(level, SPOT, 12.0, 4.0)
	_zone(level, SPOT + Vector2(0, 200), 12.0, 4.0)
	_zone(level, SPOT + Vector2(0, 200), 12.0, 4.0)
	_zone(level, SPOT + Vector2(0, 200), 12.0, 4.0)
	await _frames(120)
	_check("three patches on one enemy burn no more than one (%d vs %d HP in 2 s)" % [_lost(two), _lost(one)], absi(_lost(two) - _lost(one)) <= 1 and _lost(one) > 0)
	level.queue_free()
	await _frames(2)


## A weak and a strong patch together: the strong one's rate, never the sum; the weak one doesn't undercut it.
func _test_stronger_wins() -> void:
	var level: Level = await _level()
	var ghoul: Enemy = _stationary(level, SPOT, GHOUL)
	_zone(level, SPOT, 20.0, 4.0)
	_zone(level, SPOT, 8.0, 4.0)
	await _frames(120)
	_check("a strong (20/s) and a weak (8/s) fire together: the strong one counts (%d HP in 2 s; the sum would be %d)"
		% [_lost(ghoul), roundi(28.0 * BURNING_IN_TWO_SECONDS)], absi(_lost(ghoul) - roundi(20.0 * BURNING_IN_TWO_SECONDS)) <= 2)
	level.queue_free()
	await _frames(2)


func _test_afterburn() -> void:
	var level: Level = await _level()
	var ghoul: Enemy = _stationary(level, SPOT, GHOUL)
	_zone(level, SPOT, 12.0, 4.0)
	await _frames(60)
	ghoul.global_position = SPOT + Vector2(300, 0)
	await _frames(1)
	var left: int = _lost(ghoul)
	await _frames(30)
	_check("stepping out of the fire, it keeps burning for a moment", ghoul.get_status().is_burning() and _lost(ghoul) > left)
	await _frames(60)
	var stopped: int = _lost(ghoul)
	await _frames(60)
	_check("...then the burn goes out (%d HP after it)" % (_lost(ghoul) - stopped), not ghoul.get_status().is_burning() and _lost(ghoul) == stopped)
	level.queue_free()
	await _frames(2)


func _test_tough() -> void:
	var level: Level = await _level()
	var ghoul: Enemy = _stationary(level, SPOT, GHOUL)
	var brute: Enemy = _stationary(level, SPOT + Vector2(0, 150), BRUTE)
	var boss: Enemy = _stationary(level, SPOT + Vector2(250, 0), GRAVELORD)
	_zone(level, SPOT, 20.0, 5.0)
	_zone(level, SPOT + Vector2(0, 150), 20.0, 5.0)
	_zone(level, SPOT + Vector2(250, 0), 20.0, 5.0, 60.0)
	await _frames(180)
	_check("Brutes burn at half rate (%d vs a Ghoul's %d), bosses at a third (%d)" % [_lost(brute), _lost(ghoul), _lost(boss)],
		BRUTE.burn_taken <= 0.5 and GRAVELORD.burn_taken <= 0.4 and absf(_lost(brute) - _lost(ghoul) * BRUTE.burn_taken) <= 3.0
		and absf(_lost(boss) - _lost(ghoul) * GRAVELORD.burn_taken) <= 3.0)
	level.queue_free()
	await _frames(2)


# ---------------------------------------------------------------- helpers

func _level() -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	WaveFixtures.no_upgrades(level)
	(level.get_node("Hero") as Node2D).position = Vector2(380, 380)
	root.add_child(level)
	await _frames(2)
	return level


func _stationary(level: Level, at: Vector2, data: EnemyData) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = data
	enemy.position = at
	level.add_child(enemy)
	(enemy.get_node("%AttackRange") as Area2D).monitoring = false
	enemy.get_health().setup(HP)
	for ability: Node in enemy.find_children("*", "EnemyAbility", false, false):
		ability.set_physics_process(false)  # a boss stands still for the measurement
	return enemy


func _zone(level: Level, at: Vector2, dps: float, duration: float, radius: float = 40.0) -> BurnZone:
	var zone: BurnZone = BURN_ZONE_SCENE.instantiate()
	zone.setup(dps, radius, duration)
	zone.position = at
	level.add_child(zone)
	return zone


func _lost(enemy: Enemy) -> int:
	return HP - enemy.get_health().current_health


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
