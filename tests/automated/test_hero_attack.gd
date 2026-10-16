extends SceneTree
## Automated check for the hero melee attack.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --path . --script res://<this file>

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

	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	level.free()
	quit(_failures)


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
