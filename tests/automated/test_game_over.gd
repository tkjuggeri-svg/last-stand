extends SceneTree
## Automated check for Game Over and Restart, driven through the real main.tscn.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

var _failures: int = 0


func _initialize() -> void:
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(2)
	var screen: GameOverScreen = main.get_node("%GameOverScreen")
	var button: Button = screen.get_node("%RestartButton")

	# --- Fresh run ---
	var level: Level = _current_level(main)
	_check("main starts a level", level != null)
	_check("game over hidden at start", not screen.visible)
	_check("level is running", level.can_process() and not level.is_run_over())
	var lost_count: Array[int] = [0]
	level.run_lost.connect(func(_reason: Level.LossReason) -> void: lost_count[0] += 1)

	# --- Trigger through a real enemy hit (a physics callback) ---
	var fortress: Fortress = level.get_node("Fortress")
	fortress.health.take_damage(90)
	var frames: int = 0
	while not fortress.health.is_dead() and frames < 1200:
		await physics_frame
		frames += 1
	await _frames(2)
	_check("a ghoul hit at 10 HP destroys the fortress (%.1f s)" % (frames / 60.0), fortress.health.is_dead())
	_check("game over screen shown", screen.visible)
	_check("restart button has keyboard focus", button.has_focus())
	_check("level reports run over", level.is_run_over())
	_check("level stopped processing", not level.can_process())
	_check("run_lost emitted once", lost_count[0] == 1)

	# --- Gameplay is frozen ---
	var spawner: EnemySpawner = level.get_node("EnemySpawner")
	var hero: Hero = level.get_node("Hero")
	var spawns_after_game_over: Array[int] = [0]
	spawner.enemy_spawned.connect(func(_e: Enemy) -> void: spawns_after_game_over[0] += 1)
	var positions_before: Array[Vector2] = _enemy_positions(spawner)
	var hero_before: Vector2 = hero.global_position
	Input.action_press("move_right")
	Input.action_press("attack")
	await _frames(180)  # 3 s: would be 1-2 new spawns and 180 px of walking
	Input.action_release("move_right")
	Input.action_release("attack")
	# Count spawn events, not living enemies: a spawn and a ghoul dying at the fortress can cancel out.
	_check("no new enemies spawn (%d spawned)" % spawns_after_game_over[0], spawns_after_game_over[0] == 0)
	_check("enemies stopped moving", _enemy_positions(spawner) == positions_before)
	_check("hero ignores input", hero.global_position == hero_before)
	_check("hero swing stays off", (hero.get_node("%AttackVisual") as CanvasItem).visible == false)

	# --- Only one Game Over ---
	fortress.destroyed.emit()
	fortress.health.take_damage(10)
	await _frames(2)
	_check("repeated destroy does not trigger Game Over again", lost_count[0] == 1)

	# --- Restart ---
	var old_level: Level = level
	button.pressed.emit()
	await _frames(2)
	level = _current_level(main)
	_check("restart hides game over", not screen.visible)
	_check("old level removed", not is_instance_valid(old_level))
	_check("exactly one level in main", _level_count(main) == 1)
	_check("new level is a fresh instance", level != null and level != old_level)
	_check("new level is running", level.can_process() and not level.is_run_over())
	var new_fortress: Fortress = level.get_node("Fortress")
	var new_hero: Hero = level.get_node("Hero")
	_check("fortress back to 100 HP", new_fortress.health.current_health == 100)
	_check("hero back at start position", new_hero.position == Vector2(-200, 80))
	var hud_label: Label = level.get_node("HUD").get_node("%FortressBar").get_node("%ValueLabel")
	_check("HUD shows the new fortress (100 / 100)", hud_label.text == "100 / 100")
	_check("spawning restarted", (level.get_node("EnemySpawner") as EnemySpawner).get_child_count() == 1)

	Input.action_press("move_right")
	await _frames(30)
	Input.action_release("move_right")
	_check("hero responds to input again", new_hero.position.x > -200.0)

	# --- A second Game Over works in the new run ---
	var second_lost: Array[int] = [0]
	level.run_lost.connect(func(_reason: Level.LossReason) -> void: second_lost[0] += 1)
	new_fortress.health.take_damage(100)
	await _frames(2)
	_check("second run can also be lost", screen.visible and second_lost[0] == 1)
	_check("first run's counter unaffected", lost_count[0] == 1)

	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	main.queue_free()
	await _frames(2)
	quit(_failures)


func _current_level(main: Node) -> Level:
	for child: Node in main.get_children():
		if child is Level:
			return child
	return null


func _level_count(main: Node) -> int:
	return main.get_children().filter(func(c: Node) -> bool: return c is Level).size()


func _enemy_positions(spawner: EnemySpawner) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for enemy: Node in spawner.get_children():
		positions.append((enemy as Enemy).global_position)
	return positions


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
