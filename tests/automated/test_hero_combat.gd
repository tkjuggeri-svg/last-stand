extends SceneTree
## Automated check for Ghoul-to-hero combat: attacks, cooldowns, invulnerability, lane resume,
## hit feedback, hero death -> Game Over -> Restart, and that fortress damage still works.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
## A spot on the lane's first (left-to-right) segment, ahead of the spawn point.
const ON_LANE: Vector2 = Vector2(-560, -250)
const OFF_LANE: Vector2 = Vector2(-200, 200)
const WINDUP_FRAMES: int = 21  # 0.35 s
const COOLDOWN_FRAMES: int = 72  # 1.2 s

var _failures: int = 0


func _initialize() -> void:
	await _test_single_ghoul()
	await _test_dodge()
	await _test_crowd()
	await _test_attacker_limit()
	await _test_death_and_restart()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


## One ghoul vs. a hero standing on its lane: hit, no repeat, cooldown, feedback, resume, fortress.
func _test_single_ghoul() -> void:
	var level: Level = _make_level(1, 2.0)
	var hero: Hero = level.get_node("Hero")
	var fortress: Fortress = level.get_node("Fortress")
	var spawner: EnemySpawner = level.get_node("EnemySpawner")
	var hero_bar_label: Label = level.get_node("HUD").get_node("%HeroBar").get_node("%ValueLabel")
	hero.position = ON_LANE
	await _frames(2)
	var ghoul: Enemy = spawner.get_child(0)
	var hits: Array[int] = []
	var bar_texts: Array[String] = []
	hero.health.health_changed.connect(func(_c: int, _m: int) -> void:
		hits.append(Engine.get_physics_frames())
		bar_texts.append(hero_bar_label.text))
	var attacks: Array[int] = []
	ghoul.attack_started.connect(func(_e: Enemy) -> void: attacks.append(Engine.get_physics_frames()))

	await _until(func() -> bool: return hits.size() >= 1, 300)
	_check("ghoul hits the hero for 10 (HP %d)" % hero.health.current_health, hero.health.current_health == 90)
	_check("the hit lands one wind-up after the attack starts (%d frames)" % (hits[0] - attacks[0] if hits.size() > 0 and attacks.size() > 0 else -1),
		hits.size() > 0 and attacks.size() > 0 and absi(hits[0] - attacks[0] - WINDUP_FRAMES) <= 3)
	_check("ghoul stopped walking to fight", ghoul.velocity.is_zero_approx() and ghoul.has_target())
	_check("hitting the hero does not use the ghoul up", is_instance_valid(ghoul) and spawner.get_living_count() == 1)
	_check("hero hits don't touch the fortress", fortress.health.current_health == 100)
	_check("HUD hero bar already shows 90 / 100 when the hit is reported", bar_texts.size() > 0 and bar_texts[0] == "90 / 100")
	# Hit feedback.
	var flash: float = ((hero.get_node("%Sprite") as CanvasItem).material as ShaderMaterial).get_shader_parameter("flash")
	var numbers: Array[Node] = hero.get_children().filter(func(n: Node) -> bool: return n is DamageNumber)
	_check("hero flashes (%.2f) and the hit spark plays" % flash,
		flash > 0.5 and (hero.get_node("%HitSpark") as AnimatedSprite2D).visible)
	_check("a '-10' damage number appears", numbers.size() == 1 and (numbers[0].get_node("%Label") as Label).text == "-10")

	# Standing inside the ghoul for most of the cooldown: no further damage.
	await _frames(55)
	_check("no repeated damage while overlapping (HP %d after ~1 s)" % hero.health.current_health, hero.health.current_health == 90)
	_check("damage number gone after ~1 s", hero.get_children().filter(func(n: Node) -> bool: return n is DamageNumber).is_empty())
	await _until(func() -> bool: return hits.size() >= 3, 300)
	var gaps: Array[int] = []
	for i: int in range(1, mini(hits.size(), 3)):
		gaps.append(hits[i] - hits[i - 1])
	_check("one hit per 1.2 s cooldown (gaps %s frames)" % [gaps],
		gaps.size() == 2 and gaps.all(func(g: int) -> bool: return absi(g - COOLDOWN_FRAMES) <= 2))
	_check("each hit is exactly 10 (HP %d)" % hero.health.current_health, hero.health.current_health == 100 - 10 * hits.size())

	# The hero walks away: the ghoul resumes its lane and still damages the fortress.
	hero.position = OFF_LANE
	await _frames(30)
	var x_before: float = ghoul.global_position.x
	await _frames(30)
	_check("ghoul resumes the lane when the hero leaves (moved %.0f px)" % (ghoul.global_position.x - x_before),
		ghoul.global_position.x - x_before > 25.0 and not ghoul.has_target()
		and (ghoul.get_node("%Sprite") as AnimatedSprite2D).animation == &"walk_side")
	var hero_hp: int = hero.health.current_health
	var ghoul_ref: WeakRef = weakref(ghoul)  # a lambda must not hold an object that gets freed
	await _until(func() -> bool: return ghoul_ref.get_ref() == null, 1200)
	_check("the same ghoul still reaches and damages the fortress", fortress.health.current_health == 90)
	_check("fortress damage leaves the hero alone", hero.health.current_health == hero_hp)
	level.queue_free()
	await _frames(2)


## Stepping away during the wind-up makes the strike miss.
func _test_dodge() -> void:
	var level: Level = _make_level(1, 2.0)
	var hero: Hero = level.get_node("Hero")
	hero.position = ON_LANE
	await _frames(2)
	var ghoul: Enemy = (level.get_node("EnemySpawner") as EnemySpawner).get_child(0)
	var started: Array[bool] = [false]
	ghoul.attack_started.connect(func(_e: Enemy) -> void: started[0] = true)
	await _until(func() -> bool: return started[0], 300)
	hero.position = ON_LANE + Vector2(0, 150)  # out of reach before the strike lands
	await _frames(WINDUP_FRAMES + 10)
	_check("dodging during the wind-up avoids the hit", started[0] and hero.health.current_health == 100)
	level.queue_free()
	await _frames(2)


## Several ghouls at once: independent cooldowns, and the hero's invulnerability spaces the hits.
func _test_crowd() -> void:
	var level: Level = _make_level(3, 0.4)
	var hero: Hero = level.get_node("Hero")
	var spawner: EnemySpawner = level.get_node("EnemySpawner")
	hero.position = ON_LANE
	var hits: Array[int] = []
	hero.health.health_changed.connect(func(_c: int, _m: int) -> void: hits.append(Engine.get_physics_frames()))
	var attacks: Dictionary = {}
	spawner.enemy_spawned.connect(func(e: Enemy) -> void:
		attacks[e] = [] as Array[int]
		e.attack_started.connect(func(who: Enemy) -> void: (attacks[who] as Array[int]).append(Engine.get_physics_frames())))
	# Every frame: no more than 2 ghouls winding up/striking, and the hero's limit agrees.
	var limit: AttackerLimit = AttackerLimit.find_on(hero)
	var most_at_once: int = 0
	var limit_agrees: bool = true
	for _i: int in 300:  # 5 s
		await physics_frame
		var attacking: int = spawner.get_children().filter(func(e: Node) -> bool: return (e as Enemy).is_attacking()).size()
		most_at_once = maxi(most_at_once, attacking)
		limit_agrees = limit_agrees and limit.get_attacker_count() == attacking
	_check("hero allows at most 2 attackers at once (peak %d)" % most_at_once, most_at_once == 2)
	_check("the hero's attacker slots always match the attacking ghouls", limit_agrees)
	var per_ghoul_ok: bool = attacks.size() == 3
	var first_attacks: Array[int] = []
	for ghoul: Enemy in attacks:
		var times: Array[int] = attacks[ghoul]
		per_ghoul_ok = per_ghoul_ok and times.size() >= 2
		if times.size() > 0:
			first_attacks.append(times[0])
		for i: int in range(1, times.size()):
			per_ghoul_ok = per_ghoul_ok and times[i] - times[i - 1] >= COOLDOWN_FRAMES - 1
	_check("3 ghouls attack, each on its own 1.2 s cooldown", per_ghoul_ok)
	_check("their cooldowns are independent (first attacks at %s)" % [first_attacks], first_attacks.size() == 3
		and first_attacks[0] != first_attacks[1] and first_attacks[1] != first_attacks[2])
	var min_gap: int = 1000
	for i: int in range(1, hits.size()):
		min_gap = mini(min_gap, hits[i] - hits[i - 1])
	_check("hits are never closer than the 0.5 s invulnerability (%d hits, min gap %d frames)" % [hits.size(), min_gap],
		hits.size() >= 3 and min_gap >= 30)
	level.queue_free()
	await _frames(2)


## Three ghouls arriving together (spawned a frame apart, all ready to attack): only two may attack,
## the third waits its turn until a slot frees up, and a killed attacker frees its slot at once.
func _test_attacker_limit() -> void:
	var level: Level = _make_level(3, 0.01)
	var hero: Hero = level.get_node("Hero")
	var spawner: EnemySpawner = level.get_node("EnemySpawner")
	hero.position = ON_LANE
	hero.health.setup(1000)  # survive the whole test
	var limit: AttackerLimit = AttackerLimit.find_on(hero)
	var first_attack: Dictionary = {}
	spawner.enemy_spawned.connect(func(e: Enemy) -> void:
		e.attack_started.connect(func(who: Enemy) -> void:
			if not first_attack.has(who):
				first_attack[who] = Engine.get_physics_frames()))
	var most_at_once: int = 0
	var all_engaged_frame: int = -1
	for _i: int in 240:
		await physics_frame
		var ghouls: Array[Node] = spawner.get_children()
		var attacking: int = ghouls.filter(func(e: Node) -> bool: return (e as Enemy).is_attacking()).size()
		most_at_once = maxi(most_at_once, attacking)
		if all_engaged_frame < 0 and ghouls.size() == 3 and ghouls.all(func(e: Node) -> bool: return (e as Enemy).has_target()):
			all_engaged_frame = Engine.get_physics_frames()
	var starts: Array = first_attack.values()
	starts.sort()
	_check("three ready ghouls reach the hero together", all_engaged_frame > 0 and starts.size() == 3)
	_check("only 2 attack at once (peak %d)" % most_at_once, most_at_once == 2)
	_check("the third waits until a strike ends (first attacks at %s)" % [starts],
		starts.size() == 3 and starts[1] - starts[0] <= 3 and starts[2] - starts[0] >= WINDUP_FRAMES)

	level.queue_free()
	await _frames(2)

	# Fresh run: kill one of the two attackers at the moment the third is ready but held back.
	level = _make_level(3, 0.01)
	hero = level.get_node("Hero")
	spawner = level.get_node("EnemySpawner")
	hero.position = ON_LANE
	hero.health.setup(1000)
	limit = AttackerLimit.find_on(hero)
	var waiting: Enemy = null
	var attacker: Enemy = null
	for _i: int in 240:
		await physics_frame
		var ghouls: Array[Node] = spawner.get_children()
		var busy: Array[Node] = ghouls.filter(func(e: Node) -> bool: return (e as Enemy).is_attacking())
		var idle_ready: Array[Node] = ghouls.filter(func(e: Node) -> bool: return not (e as Enemy).is_attacking() and (e as Enemy).is_ready_to_attack())
		if busy.size() == 2 and idle_ready.size() == 1:
			attacker = busy[0]
			waiting = idle_ready[0]
			break
	_check("a ready ghoul is held back while two attack", waiting != null and attacker != null)
	if waiting != null and attacker != null:
		var waiting_ref: WeakRef = weakref(waiting)
		(attacker.get_node("%HealthComponent") as HealthComponent).take_damage(100)
		await _frames(2)
		_check("killing an attacker lets the waiting ghoul attack at once", (waiting_ref.get_ref() as Enemy).is_attacking())
		_check("still never more than 2 attackers", limit.get_attacker_count() <= 2)
	level.queue_free()
	await _frames(2)


## Through the real main.tscn: a ghoul kills the hero -> Game Over -> Restart -> fresh, playable run.
func _test_death_and_restart() -> void:
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(2)
	var screen: GameOverScreen = main.get_node("%GameOverScreen")
	var level: Level = _level_of(main)
	var hero: Hero = level.get_node("Hero")
	var reasons: Array[Level.LossReason] = []
	level.run_lost.connect(func(reason: Level.LossReason) -> void: reasons.append(reason))
	hero.health.take_damage(90)
	hero.position = ON_LANE
	await _until(func() -> bool: return hero.health.is_dead(), 400)
	await _frames(2)
	var sprite: AnimatedSprite2D = hero.get_node("%Sprite")
	_check("a ghoul's hit at 10 HP kills the hero", hero.health.current_health == 0)
	_check("hero death triggers Game Over once, for the hero", reasons == [Level.LossReason.HERO_KILLED] and screen.visible)
	_check("Game Over says the hero has fallen", (screen.get_node("%Subtitle") as Label).text == "The hero has fallen.")
	_check("the level is frozen", not level.can_process() and level.is_run_over())
	_check("the death animation plays", sprite.animation == &"death")
	await _frames(40)
	_check("...and keeps playing while the world is frozen (frame %d)" % sprite.frame, sprite.frame == 3)
	(level.get_node("Fortress") as Fortress).destroyed.emit()
	await _frames(2)
	_check("no second Game Over afterwards", reasons.size() == 1)

	(screen.get_node("%RestartButton") as Button).pressed.emit()
	await _frames(2)
	level = _level_of(main)
	hero = level.get_node("Hero")
	_check("restart: fresh level, hero at 100 HP, screen hidden",
		level.can_process() and hero.health.current_health == 100 and not screen.visible)
	_check("restart: hero is alive and idle", (hero.get_node("%Sprite") as AnimatedSprite2D).animation.begins_with("idle_"))
	Input.action_press("move_right")
	await _frames(20)
	Input.action_release("move_right")
	_check("restart: hero moves again", hero.position.x > -200.0)
	(level.get_node("Fortress") as Fortress).health.take_damage(100)
	await _frames(2)
	_check("a later fortress loss shows the fortress text", (screen.get_node("%Subtitle") as Label).text == "The fortress has fallen.")
	main.queue_free()
	await _frames(2)


func _make_level(count: int, interval: float) -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var spawner: EnemySpawner = level.get_node("EnemySpawner")
	spawner.spawn_count = count
	spawner.spawn_interval = interval
	root.add_child(level)
	return level


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
