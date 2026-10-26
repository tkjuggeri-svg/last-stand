extends SceneTree
## Automated check for the Necromancer's homing soul bolt (M13 playtest: "soul bolts should home in a
## little"): a bolt aimed slightly off an enemy hits it when its hero data has `bolt_homing`, misses it
## without, never turns toward an enemy behind it, and the sprite follows the bent direction.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const BOLT_SCENE: PackedScene = preload("res://entities/hero/hero_bolt.tscn")
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const NECRO: HeroData = preload("res://data/heroes/necromancer.tres")
const KNIGHT: HeroData = preload("res://data/heroes/knight.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")

var _failures: int = 0


func _initialize() -> void:
	_check("the Necromancer's bolt homes, the others' don't", NECRO.bolt_homing > 0.0 and KNIGHT.bolt_homing == 0.0)
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	root.add_child(level)
	await _frames(2)
	var straight: HeroData = NECRO.duplicate()
	straight.bolt_homing = 0.0

	var enemy: Enemy = _enemy(level, Vector2(100, 40))
	var bolt: HeroBolt = _bolt(level, NECRO, Vector2(0, 0), Vector2.RIGHT)
	await _frames(40)
	_check("homing: a bolt aimed 22 degrees off the enemy hits it (%d of 500)" % enemy.get_health().current_health, enemy.get_health().current_health < 500)
	_check("...and the bolt is gone after the hit", not is_instance_valid(bolt) or bolt.is_queued_for_deletion())
	enemy.queue_free()
	await _frames(2)

	enemy = _enemy(level, Vector2(100, 40))
	_bolt(level, straight, Vector2(0, 0), Vector2.RIGHT)
	await _frames(40)
	_check("no homing: the same shot misses", enemy.get_health().current_health == 500)
	enemy.queue_free()
	await _frames(2)

	enemy = _enemy(level, Vector2(-100, 0))
	bolt = _bolt(level, NECRO, Vector2(0, 0), Vector2.RIGHT)
	await _frames(10)
	_check("an enemy behind it is ignored (direction still %s)" % bolt.get_direction(), bolt.get_direction().is_equal_approx(Vector2.RIGHT))
	enemy.queue_free()
	await _frames(2)

	enemy = _enemy(level, Vector2(150, 60))
	bolt = _bolt(level, NECRO, Vector2(0, 0), Vector2.RIGHT)
	await _frames(12)
	var turned: bool = is_instance_valid(bolt) and bolt.get_direction().y > 0.05
	_check("it bends toward an enemy ahead and below", turned)
	level.queue_free()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _enemy(level: Level, at: Vector2) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = GHOUL
	enemy.position = at
	level.add_child(enemy)
	enemy.get_health().max_health = 500
	enemy.get_health().current_health = 500
	return enemy


func _bolt(level: Level, data: HeroData, from: Vector2, direction: Vector2) -> HeroBolt:
	var bolt: HeroBolt = BOLT_SCENE.instantiate()
	bolt.launch(from, direction, 20, data)
	level.add_child(bolt)
	return bolt


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
