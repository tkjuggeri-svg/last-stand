extends SceneTree
## Automated check for hero lives and respawning, through the real main.tscn: 3 lives per run, a fall
## costs one, the hero can't act or be attacked while down while the towers keep fighting, it comes
## back at the respawn point after 4 s (countdown in the world and the HUD) with 2 s of blinking
## invulnerability, the HUD shows the lives next to the HP bar, and only the last life is Game Over
## ("The hero has fallen."); the fortress falling is the other Game Over. Restart resets lives to 3.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

## A spot on the lane's first (left-to-right) segment, ahead of the spawn point.
const ON_LANE: Vector2 = Vector2(-560, -250)
const ARCHER: TowerData = preload("res://data/towers/archer.tres")

var _failures: int = 0


func _initialize() -> void:
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(2)
	await MapFixtures.enter_first_battle(main)  # every run starts on the map
	await _frames(2)
	var screen: GameOverScreen = main.get_node("%GameOverScreen")
	var subtitle: Label = screen.get_node("%Subtitle")
	var level: Level = _level_of(main)
	await _test_first_fall_and_respawn(level, screen)
	await _test_last_life_is_game_over(level, screen, subtitle)

	# --- Restart: lives back to 3; the fortress is the other way to lose ---
	(screen.get_node("%RestartButton") as Button).pressed.emit()
	await _frames(2)
	level = _level_of(main)
	var lives: HeroLives = level.get_node("%HeroLives")
	_check("Restart resets the lives to 3 (and the HUD's helms)", lives.get_lives_left() == 3
		and _lit_helms(level.get_node("HUD")) == 3 and not (level.get_node("Hero") as Hero).health.is_dead())
	(level.get_node("Fortress") as Fortress).health.take_damage(1000)
	await _frames(2)
	_check("the fortress falling is Game Over: \"%s\"" % subtitle.text, screen.visible and subtitle.text == "The fortress has fallen.")
	main.queue_free()
	await _frames(2)
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_first_fall_and_respawn(level: Level, screen: GameOverScreen) -> void:
	await WaveFixtures.start_wave(level)
	var hero: Hero = level.get_node("Hero")
	var lives: HeroLives = level.get_node("%HeroLives")
	var point: RespawnPoint = level.get_node("RespawnPoint")
	var countdown: Label = point.get_node("%Countdown")
	var hud: CanvasLayer = level.get_node("HUD")
	var status: Label = hud.get_node("%LivesStatus")
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	_check("a run starts with 3 lives, 3 lit helms in the HUD", lives.get_lives_left() == 3 and _lit_helms(hud) == 3 and not countdown.visible)
	var helms: Control = hud.get_node("%LivesIcons")
	var bar: Control = hud.get_node("%HeroBar")
	_check("the helms sit next to the hero's HP bar", helms.get_parent() == bar.get_parent()
		and absf(helms.get_global_rect().get_center().y - bar.get_global_rect().get_center().y) < 4.0
		and helms.get_global_rect().position.x >= bar.get_global_rect().end.x)
	builder.build(builder.get_slots()[0], ARCHER)  # by the lane, near where the hero will fall

	# --- First fall: a ghoul finishes the hero on its lane ---
	hero.position = ON_LANE
	hero.health.take_damage(90)
	await _until(func() -> bool: return hero.health.is_dead(), 400)
	var fall_frame: int = Engine.get_physics_frames()
	await _frames(2)
	var fell_at: Vector2 = hero.global_position
	_check("the fall costs a life (2 left, 2 lit helms) and is not Game Over",
		lives.get_lives_left() == 2 and _lit_helms(hud) == 2 and not screen.visible and not level.is_run_over())
	_check("a countdown at the respawn point (%s) and in the HUD (%s)" % [countdown.text, status.text],
		countdown.visible and countdown.text == "Hero returns in 4" and status.visible and status.text == "Hero back in 4 s")
	var tower: Tower = builder.get_slots()[0].tower
	var shots: Array[int] = [0]
	tower.child_entered_tree.connect(func(n: Node) -> void: shots[0] += 1 if n is Projectile else 0)
	Input.action_press("move_right")
	Input.action_press("attack")
	await _frames(60)
	Input.action_release("move_right")
	Input.action_release("attack")
	_check("while down the hero can't move or attack", hero.global_position == fell_at and not _swing_active(hero))
	_check("...and isn't a target: no enemy attacks it", _enemies_targeting(level) == 0)
	_check("...while the towers keep defending (%d shots)" % shots[0], shots[0] > 0)
	_check("the countdown ticks down (%s, %s)" % [countdown.text, status.text], countdown.text == "Hero returns in 3" and status.text == "Hero back in 3 s")

	# --- Respawn after 4 s, protected for 2 s ---
	var back_frame: Array[int] = [-1]
	lives.hero_respawned.connect(func() -> void: back_frame[0] = Engine.get_physics_frames())
	await _until(func() -> bool: return back_frame[0] >= 0, 400)
	var seconds: float = (back_frame[0] - fall_frame) / 60.0
	_check("the hero is back after 4 s (%.2f s)" % seconds, absf(seconds - lives.respawn_delay) < 0.05 and is_equal_approx(lives.respawn_delay, 4.0))
	await _frames(1)
	_check("...at the respawn point by the fortress, full HP, idle; countdowns gone",
		hero.global_position.distance_to(point.global_position) < 1.0 and hero.health.current_health == 100
		and (hero.get_node("%Sprite") as AnimatedSprite2D).animation.begins_with("idle_")
		and not countdown.visible and not status.visible)
	var sprite: CanvasItem = hero.get_node("%Sprite")
	var min_alpha: float = 1.0
	var hits_ignored: bool = true
	var hitbox: Hitbox = _enemy_hitbox(level)
	for i: int in 100:  # ~1.7 s of the 2 s protection
		await physics_frame
		min_alpha = minf(min_alpha, sprite.modulate.a)
		if i % 20 == 0:
			hits_ignored = hits_ignored and not (hero.get_node("%Hurtbox") as Hurtbox).receive_hit(hitbox)
	_check("2 s of invulnerability after the respawn: hits are ignored (HP %d)" % hero.health.current_health,
		hits_ignored and hero.health.current_health == 100 and is_equal_approx(lives.respawn_invulnerability, 2.0))
	_check("...shown by a blink (alpha down to %.2f)" % min_alpha, min_alpha < 0.5)
	await _frames(30)
	_check("after 2 s hits land again and the blink is over",
		(hero.get_node("%Hurtbox") as Hurtbox).receive_hit(hitbox) and hero.health.current_health < 100 and sprite.modulate.a == 1.0)
	Input.action_press("move_left")
	await _frames(20)
	Input.action_release("move_left")
	_check("the hero moves again", hero.global_position.x < point.global_position.x - 10.0)
	hitbox.queue_free()


func _test_last_life_is_game_over(level: Level, screen: GameOverScreen, subtitle: Label) -> void:
	var hero: Hero = level.get_node("Hero")
	var lives: HeroLives = level.get_node("%HeroLives")
	var lost: Array[Level.LossReason] = []
	level.run_lost.connect(func(reason: Level.LossReason) -> void: lost.append(reason))
	hero.health.take_damage(1000)
	await _frames(2)
	_check("second fall: 1 life left, respawning, still no Game Over", lives.get_lives_left() == 1
		and lives.is_respawning() and lost.is_empty() and not screen.visible)
	await _until(func() -> bool: return not hero.health.is_dead(), 400)
	await _frames(130)  # past the respawn protection
	hero.health.take_damage(1000)
	await _frames(2)
	_check("losing the last life is Game Over, once: \"%s\"" % subtitle.text, lives.get_lives_left() == 0
		and lost == [Level.LossReason.HERO_KILLED] and screen.visible and subtitle.text == "The hero has fallen.")
	_check("...no respawn after it", not lives.is_respawning() and level.is_run_over())


func _lit_helms(hud: Node) -> int:
	return hud.get_node("%LivesIcons").get_children().filter(func(n: Node) -> bool: return (n as CanvasItem).modulate == Color.WHITE).size()


func _swing_active(hero: Hero) -> bool:
	return not (hero.get_node("%AttackShape") as CollisionPolygon2D).disabled


func _enemies_targeting(level: Level) -> int:
	var count: int = 0
	for enemy: Node in level.get_node("WaveSpawner").get_children():
		if (enemy as Enemy).has_target() or (enemy as Enemy).is_attacking():
			count += 1
	return count


## A stand-in enemy strike (10 damage) to hit the hero with directly.
func _enemy_hitbox(level: Level) -> Hitbox:
	var hitbox: Hitbox = Hitbox.new()
	hitbox.damage = 10
	level.add_child(hitbox)
	return hitbox


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
