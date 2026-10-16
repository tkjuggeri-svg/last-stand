extends SceneTree
## Automated check for the fortress: HP, damage only from enemy hitboxes, destruction, hero collision.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --path . --script res://<this file>

var _failures: int = 0


func _initialize() -> void:
	var level: Node = (load("res://tests/test_fortress.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var fortress: Fortress = level.get_node("%Fortress")
	var hero: Hero = level.get_node("Hero")
	var pulse_shape: CollisionShape2D = level.get_node("%PulseShape")
	var pulse_timer: Timer = level.get_node("%PulseTimer")
	var label: Label = level.get_node("%FortressLabel")
	var sprite: Sprite2D = fortress.get_node("%Sprite")
	var destroyed_count: Array[int] = [0]
	fortress.destroyed.connect(func() -> void: destroyed_count[0] += 1)
	await _frames(2)

	_check("starts at 100/100", fortress.health.current_health == 100 and fortress.health.max_health == 100)
	_check("starts with the healthy look", sprite.frame == Fortress.Look.HEALTHY)
	_check("test label shows HP", label.text == "Fortress HP: 100 / 100")

	# The test scene's timer pulse: on at 0.5 s (hit), off at 1.0 s, on at 1.5 s.
	await _frames(70)  # ~1.17 s
	_check("timer pulse hits once in ~1.2 s (HP %d)" % fortress.health.current_health, fortress.health.current_health == 90)
	pulse_timer.stop()
	pulse_shape.set_deferred("disabled", true)
	await _frames(2)

	# The hero's swing reaches the fortress but must not hurt it.
	var probe := Area2D.new()  # stand-in hurtbox that does listen to hero_hitbox, proving the swing reaches
	probe.collision_layer = 0
	probe.collision_mask = 16
	var probe_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(104, 104)
	probe_shape.shape = rect
	probe.add_child(probe_shape)
	level.add_child(probe)
	var probe_hits: Array[int] = [0]
	probe.area_entered.connect(func(_a: Area2D) -> void: probe_hits[0] += 1)
	hero.position = Vector2(0, 90)
	await _frames(2)
	hero.attack(Vector2.ZERO)
	await _frames(10)
	_check("hero swing reaches the fortress area", probe_hits[0] == 1)
	_check("hero swing does NOT damage fortress", fortress.health.current_health == 90)
	probe.queue_free()

	# The hero cannot walk through the fortress (bottom edge y=48 + hero radius 16).
	hero.position = Vector2(0, 150)
	await _frames(2)
	Input.action_press("move_up")
	await _frames(90)
	Input.action_release("move_up")
	_check("hero blocked by fortress (y=%.1f)" % hero.position.y, hero.position.y >= 63.0 and hero.position.y < 66.0)

	# Enemy hits: 9 more pulses destroy it, extra pulses do nothing.
	var looks_seen: Array[int] = []
	for _i: int in 11:
		pulse_shape.set_deferred("disabled", false)
		await _frames(3)
		pulse_shape.set_deferred("disabled", true)
		await _frames(3)
		if not looks_seen.has(sprite.frame):
			looks_seen.append(sprite.frame)
	_check("sprite steps through damaged looks as HP drops (%s)" % [looks_seen],
		looks_seen == [Fortress.Look.HEALTHY, Fortress.Look.DAMAGED, Fortress.Look.BADLY_DAMAGED, Fortress.Look.DESTROYED])
	_check("destroyed at 0 HP", fortress.health.current_health == 0 and fortress.health.is_dead())
	_check("destroyed emitted exactly once", destroyed_count[0] == 1)
	_check("destroyed look shown", sprite.frame == Fortress.Look.DESTROYED)
	_check("look thresholds: >2/3 healthy, >1/3 damaged, >0 badly damaged",
		Fortress.look_for(67, 100) == Fortress.Look.HEALTHY and Fortress.look_for(66, 100) == Fortress.Look.DAMAGED
		and Fortress.look_for(34, 100) == Fortress.Look.DAMAGED and Fortress.look_for(33, 100) == Fortress.Look.BADLY_DAMAGED
		and Fortress.look_for(1, 100) == Fortress.Look.BADLY_DAMAGED)
	_check("test label shows destroyed", label.text == "Fortress DESTROYED")

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
