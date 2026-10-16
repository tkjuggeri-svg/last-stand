extends SceneTree
## Automated check for hero movement: simulates input actions and inspects the result.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --path . --script res://<this file>

var _failures: int = 0


func _initialize() -> void:
	var scene: PackedScene = load("res://tests/test_hero_movement.tscn")
	var level: Node = scene.instantiate()
	root.add_child(level)
	var hero: Hero = level.get_node("Hero")
	var camera: Camera2D = hero.get_node("Camera2D")
	await physics_frame

	_check("idle hero has zero velocity", hero.velocity.is_zero_approx())

	Input.action_press("move_right")
	await _frames(30)
	_check("straight speed = 200 (got %.2f)" % hero.velocity.length(), is_equal_approx(hero.velocity.length(), 200.0))
	_check("moved right (x=%.1f)" % hero.position.x, hero.position.x > 50.0)

	Input.action_press("move_down")
	await _frames(5)
	_check("diagonal speed = 200 (got %.2f)" % hero.velocity.length(), is_equal_approx(hero.velocity.length(), 200.0))
	Input.action_release("move_right")
	Input.action_release("move_down")
	await _frames(2)
	_check("stops when keys released", hero.velocity.is_zero_approx())

	_check("camera is current", camera.is_current())

	# Walk into the left wall (inner edge at x=-980, hero radius 16).
	hero.position = Vector2(-900, 0)
	Input.action_press("move_left")
	await _frames(120)
	Input.action_release("move_left")
	_check("blocked by wall (x=%.1f)" % hero.position.x, hero.position.x >= -965.0 and hero.position.x < -950.0)

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
