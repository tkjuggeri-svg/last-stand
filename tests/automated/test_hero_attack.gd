extends SceneTree
## Automated check for the hero melee attack.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --path . --script res://<this file>

## Swing reach from the hero's centre (tip of the arc in hero.tscn).
const REACH: float = 68.0
## Radius of the training dummy's hurtbox.
const DUMMY_RADIUS: float = 24.0

var _failures: int = 0


func _initialize() -> void:
	var level: Node = (load("res://tests/test_hero_attack.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var hero: Hero = level.get_node("Hero")
	var shape: CollisionPolygon2D = hero.get_node("%AttackShape")
	var visual: Polygon2D = hero.get_node("%AttackVisual")
	var right: HealthComponent = level.get_node("Dummies/DummyRight/HealthComponent")
	var left: HealthComponent = level.get_node("Dummies/DummyLeft/HealthComponent")
	var down: HealthComponent = level.get_node("Dummies/DummyDown/HealthComponent")
	var far: HealthComponent = level.get_node("Dummies/DummyFar/HealthComponent")
	await _frames(3)
	_check("idle: hitbox off, swing hidden", shape.disabled and not visual.visible)
	_check("idle: no dummy hurt", right.current_health == 50 and left.current_health == 50)

	hero.attack(Vector2(70, 0))
	await _frames(2)
	_check("swing right: visual shown, hitbox on", visual.visible and not shape.disabled)
	await _frames(15)
	_check("swing right hits right dummy once (got %d)" % right.current_health, right.current_health == 40)
	_check("swing right misses left/down/far", left.current_health == 50 and down.current_health == 50 and far.current_health == 50)
	_check("after 0.12s: hitbox off, swing hidden", shape.disabled and not visual.visible)

	hero.attack(Vector2(-70, 0))  # still on cooldown (~0.28s elapsed of 0.4s)
	await _frames(10)
	_check("attack during cooldown ignored", left.current_health == 50)

	await _frames(15)
	hero.attack(Vector2(-70, 0))
	await _frames(15)
	_check("swing left after cooldown hits left dummy", left.current_health == 40 and right.current_health == 40)

	await _frames(15)
	hero.attack(Vector2(0, 70))
	await _frames(15)
	_check("swing down hits down dummy only", down.current_health == 40 and left.current_health == 40 and right.current_health == 40)

	# Holding the attack action keeps swinging at the cooldown rate (direction comes from the mouse).
	var before: int = right.current_health + left.current_health + down.current_health
	Input.action_press("attack")
	await _frames(60)  # 1 s -> swings at t=0, 0.4, 0.8 => 3 swings
	Input.action_release("attack")
	await _frames(15)
	var dealt: int = before - (right.current_health + left.current_health + down.current_health)
	_check("holding attack for 1s = 3 swings of 10 (dealt %d)" % dealt, dealt == 30)
	_check("hitbox off after releasing", shape.disabled)

	# Reach: dummies placed so their hurtbox edge is just inside / just outside the 68 px tip.
	await _test_reach(level, hero)

	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	level.free()
	quit(_failures)


func _test_reach(level: Node, hero: Hero) -> void:
	hero.position = Vector2(-400, 250)  # clear of the scene's own dummies
	await _frames(30)  # let the cooldown run out
	var dummy_scene: PackedScene = load("res://tests/training_dummy.tscn")
	# Edge 1 px inside the tip: would have been 15 px out of reach at the old 52 px.
	var inside: Node2D = dummy_scene.instantiate()
	inside.position = hero.position + Vector2(REACH + DUMMY_RADIUS - 1.0, 0)
	# Edge 1 px beyond the tip, on the opposite side.
	var outside: Node2D = dummy_scene.instantiate()
	outside.position = hero.position - Vector2(REACH + DUMMY_RADIUS + 1.0, 0)
	level.add_child(inside)
	level.add_child(outside)
	await _frames(2)
	var inside_hp: HealthComponent = inside.get_node("%HealthComponent")
	var outside_hp: HealthComponent = outside.get_node("%HealthComponent")

	hero.attack(inside.position)
	await _frames(15)
	_check("reach 68: hits a target whose edge is at 67 px", inside_hp.current_health == 40)
	await _frames(15)
	hero.attack(outside.position)
	await _frames(15)
	_check("reach 68: misses a target whose edge is at 69 px", outside_hp.current_health == 50)
	var tip: Vector2 = (hero.get_node("%AttackShape") as CollisionPolygon2D).polygon[3]
	_check("arc tip is at 68 px (got %.1f)" % tip.length(), is_equal_approx(tip.length(), REACH))


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
