extends SceneTree
## Automated check for hero lives and respawning, through the real main.tscn: a fall costs a life,
## the hero can't act or be attacked while down, comes back at the respawn point after the delay
## (countdown shown in the world and the HUD), the last fall is final but the run goes on, and only
## the fortress falling ends the run. Restart gives all lives back.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

## A spot on the lane's first (left-to-right) segment, ahead of the spawn point.
const ON_LANE: Vector2 = Vector2(-560, -250)

var _failures: int = 0


func _initialize() -> void:
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(2)
	var level: Level = _level_of(main)
	await WaveFixtures.start_wave(level)
	var screen: GameOverScreen = main.get_node("%GameOverScreen")
	var hero: Hero = level.get_node("Hero")
	var lives: HeroLives = level.get_node("%HeroLives")
	var point: RespawnPoint = level.get_node("RespawnPoint")
	var countdown: Label = point.get_node("%Countdown")
	var hud: CanvasLayer = level.get_node("HUD")
	var status: Label = hud.get_node("%LivesStatus")
	var lost: Array[int] = [0]
	level.run_lost.connect(func(_reason: Level.LossReason) -> void: lost[0] += 1)
	_check("a run starts with 3 lives (%d), 3 lit helms in the HUD" % lives.get_lives_left(),
		lives.get_lives_left() == 3 and _lit_helms(hud) == 3 and not countdown.visible)

	# --- First fall: a ghoul finishes the hero on its lane ---
	hero.position = ON_LANE
	hero.health.take_damage(90)
	await _until(func() -> bool: return hero.health.is_dead(), 400)
	await _frames(2)
	var fell_at: Vector2 = hero.global_position
	_check("the fall costs a life and is not Game Over", lives.get_lives_left() == 2 and lost[0] == 0 and not screen.visible)
	_check("a countdown appears at the respawn point (%s) and in the HUD (%s)" % [countdown.text, status.text],
		countdown.visible and countdown.text == "Hero returns in 6" and status.text == "Back in 6 s" and _lit_helms(hud) == 2)
	Input.action_press("move_right")
	Input.action_press("attack")
	await _frames(60)
	Input.action_release("move_right")
	Input.action_release("attack")
	_check("while down the hero can't move or attack", hero.global_position == fell_at and not _swing_active(hero))
	_check("...and isn't a target: no enemy attacks it", _enemies_targeting(level, hero) == 0)
	_check("the countdown ticks down (%s, %s)" % [countdown.text, status.text], countdown.text == "Hero returns in 5" and status.text == "Back in 5 s")

	# --- Respawn after 6 s ---
	var back_frame: Array[int] = [-1]
	var fall_frame: int = Engine.get_physics_frames() - 62
	lives.hero_respawned.connect(func() -> void: back_frame[0] = Engine.get_physics_frames())
	await _until(func() -> bool: return back_frame[0] >= 0, 400)
	await _frames(2)
	_check("the hero is back after ~6 s (%.2f s)" % ((back_frame[0] - fall_frame) / 60.0), absf((back_frame[0] - fall_frame) / 60.0 - lives.respawn_delay) < 0.1)
	_check("...at the respawn point by the fortress, full HP, idle",
		hero.global_position.distance_to(point.global_position) < 1.0 and hero.health.current_health == 100
		and (hero.get_node("%Sprite") as AnimatedSprite2D).animation.begins_with("idle_"))
	_check("...HUD bar 100 / 100, countdown gone", (hud.get_node("%HeroBar").get_node("%ValueLabel") as Label).text == "100 / 100"
		and not countdown.visible and status.text == "")
	Input.action_press("move_left")
	await _frames(20)
	Input.action_release("move_left")
	_check("...and moves again", hero.global_position.x < point.global_position.x - 10.0)

	# --- Second and third falls: the third is final, the run goes on ---
	hero.health.take_damage(1000)
	await _frames(2)
	_check("second fall: 1 life left, respawning", lives.get_lives_left() == 1 and lives.is_respawning())
	await _until(func() -> bool: return not hero.health.is_dead(), 400)
	var out: Array[int] = [0]
	lives.out_of_lives.connect(func() -> void: out[0] += 1)
	hero.health.take_damage(1000)
	await _frames(2)
	_check("third fall: no lives left, no respawn", lives.get_lives_left() == 0 and out[0] == 1 and not lives.is_respawning() and not countdown.visible)
	_check("HUD says the hero has fallen (%s)" % status.text, status.text == "Fallen" and _lit_helms(hud) == 0)
	await _frames(600)
	_check("10 s later the hero is still down but the run goes on", hero.health.is_dead() and lost[0] == 0
		and level.can_process() and not level.is_run_over())

	# --- Only the fortress ends the run ---
	(level.get_node("Fortress") as Fortress).health.take_damage(1000)
	await _frames(2)
	_check("the fortress falling ends the run", lost[0] == 1 and screen.visible
		and (screen.get_node("%Subtitle") as Label).text == "The fortress has fallen.")
	(screen.get_node("%RestartButton") as Button).pressed.emit()
	await _frames(2)
	level = _level_of(main)
	lives = level.get_node("%HeroLives")
	_check("Restart gives all 3 lives back", lives.get_lives_left() == 3 and _lit_helms(level.get_node("HUD")) == 3
		and not (level.get_node("Hero") as Hero).health.is_dead())
	main.queue_free()
	await _frames(2)
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _lit_helms(hud: Node) -> int:
	return hud.get_node("%LivesIcons").get_children().filter(func(n: Node) -> bool: return (n as CanvasItem).modulate == Color.WHITE).size()


func _swing_active(hero: Hero) -> bool:
	return not (hero.get_node("%AttackShape") as CollisionPolygon2D).disabled


func _enemies_targeting(level: Level, hero: Hero) -> int:
	var count: int = 0
	for enemy: Node in level.get_node("WaveSpawner").get_children():
		if (enemy as Enemy).has_target() or (enemy as Enemy).is_attacking():
			count += 1
	return count if hero.health.is_dead() else -1


func _level_of(main: Node) -> Level:
	for child: Node in main.get_children():
		if child is Level:
			return child
	return null


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
