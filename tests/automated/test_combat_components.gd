extends SceneTree
## Automated check for HealthComponent, Hitbox and Hurtbox.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --path . --script res://<this file>

var _failures: int = 0
var _died_count: int = 0
var _changed_count: int = 0


func _initialize() -> void:
	# --- HealthComponent on its own ---
	var health := HealthComponent.new()
	root.add_child(health)
	await process_frame  # let _ready() run
	health.died.connect(func() -> void: _died_count += 1)
	health.health_changed.connect(func(_c: int, _m: int) -> void: _changed_count += 1)
	_check("starts at max (100)", health.current_health == 100)
	health.take_damage(30)
	_check("30 damage -> 70", health.current_health == 70)
	health.take_damage(-5)
	health.take_damage(0)
	_check("zero/negative damage ignored", health.current_health == 70 and _changed_count == 1)
	health.take_damage(500)
	_check("overkill clamps to 0", health.current_health == 0 and health.is_dead())
	health.take_damage(10)
	_check("died emitted exactly once", _died_count == 1)
	health.free()

	# --- Hitbox/Hurtbox through real physics ---
	var level: Node = (load("res://tests/test_combat_components.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var hero: Hero = level.get_node("Hero")
	var dummy_hp: HealthComponent = level.get_node("Dummies/DummyRight/HealthComponent")
	var dummy_died: Array[int] = [0]
	dummy_hp.died.connect(func() -> void: dummy_died[0] += 1)
	var hits_reported: Array[Hurtbox] = []
	(hero.get_node("Hitbox") as Hitbox).hit.connect(func(h: Hurtbox) -> void: hits_reported.append(h))
	await _frames(2)
	_check("dummy untouched at start (50)", dummy_hp.current_health == 50)

	# Walk into the right dummy with real input.
	Input.action_press("move_right")
	await _frames(60)
	Input.action_release("move_right")
	_check("walking in deals 10 (got %d)" % dummy_hp.current_health, dummy_hp.current_health == 40)
	_check("hitbox reports the hit with the hurtbox it struck",
		hits_reported.size() == 1 and hits_reported[0] == level.get_node("Dummies/DummyRight/Hurtbox"))
	await _frames(30)
	_check("standing inside does not repeat damage", dummy_hp.current_health == 40)

	for _i: int in 6:  # 4 more touches kill it, 2 extra prove it stays dead
		hero.position = Vector2.ZERO
		await _frames(3)
		hero.position = Vector2(200, 0)
		await _frames(3)
	_check("dummy dead at 0", dummy_hp.current_health == 0)
	_check("dummy died signal once", dummy_died[0] == 1)

	# An enemy-layer hitbox must not hurt a dummy that only listens to hero_hitbox.
	var left_hp: HealthComponent = level.get_node("Dummies/DummyLeft/HealthComponent")
	var enemy_hit := Hitbox.new()
	enemy_hit.collision_layer = 32  # layer 6: enemy_hitbox
	enemy_hit.collision_mask = 0
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	enemy_hit.add_child(shape)
	enemy_hit.position = Vector2(-200, 0)
	level.add_child(enemy_hit)
	await _frames(5)
	_check("enemy_hitbox layer ignored by hero-targeted hurtbox", left_hp.current_health == 50)

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
