extends SceneTree
## Automated check for the enemy roster (Ghoul, Hound, Brute): their roles in the data, that one
## shared enemy scene takes each type's body size and animations from its EnemyData (without the
## types affecting each other), that attack animations strike when the wind-up ends, and that each
## type spawns from a wave, deals its own fortress damage and plays its own death effect.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const HOUND: EnemyData = preload("res://data/enemies/hound.tres")
const BRUTE: EnemyData = preload("res://data/enemies/brute.tres")
## Index of the frame in each attack animation where the blow lands (see the art files).
const STRIKE_FRAME: Dictionary = {"Ghoul": 4, "Hound": 4, "Brute": 6}
const ANIMATIONS: Array[String] = ["idle_down", "idle_up", "idle_side", "walk_down", "walk_up", "walk_side",
	"attack_down", "attack_up", "attack_side", "death"]
## Far from the lane: the hero stays out of every fight.
const HERO_AWAY: Vector2 = Vector2(-750, 330)

var _failures: int = 0


func _initialize() -> void:
	_test_roles()
	_test_animations()
	await _test_in_a_wave()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_roles() -> void:
	_check("Hound: fast, fragile, light on the fortress",
		HOUND.move_speed > GHOUL.move_speed * 1.5 and HOUND.max_health < GHOUL.max_health and HOUND.fortress_damage < GHOUL.fortress_damage)
	_check("Brute: slow, tough, heavy on the fortress",
		BRUTE.move_speed < GHOUL.move_speed * 0.7 and BRUTE.max_health >= GHOUL.max_health * 4 and BRUTE.fortress_damage >= GHOUL.fortress_damage * 3)
	_check("sizes: Brute > Ghoul > Hound", BRUTE.body_radius > GHOUL.body_radius and GHOUL.body_radius > HOUND.body_radius)
	_check("every enemy has its own animations and death effect",
		[GHOUL, HOUND, BRUTE].all(func(d: EnemyData) -> bool: return d.sprite_frames != null and d.death_effect != null)
		and GHOUL.sprite_frames != HOUND.sprite_frames and HOUND.sprite_frames != BRUTE.sprite_frames)


func _test_animations() -> void:
	for data: EnemyData in [GHOUL, HOUND, BRUTE]:
		var frames: SpriteFrames = data.sprite_frames
		var complete: bool = ANIMATIONS.all(func(a: String) -> bool: return frames.has_animation(a) and frames.get_frame_count(a) >= 4)
		_check("%s has every animation (idle/walk/attack per facing, death)" % data.display_name, complete)
		var strike_time: float = STRIKE_FRAME[data.display_name] / frames.get_animation_speed(&"attack_down")
		_check("%s's blow lands in the animation when the %.2f s wind-up ends (%.2f s)" % [data.display_name, data.attack_windup, strike_time],
			absf(strike_time - data.attack_windup) <= 0.02)


## One wave with a group of each type; each walks into the fortress unopposed.
func _test_in_a_wave() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var wave: WaveData = WaveFixtures.make_wave(1, 1.0, GHOUL)
	wave.groups.append(WaveFixtures.make_wave(1, 1.0, HOUND, 0, 0.5).groups[0])
	wave.groups.append(WaveFixtures.make_wave(1, 1.0, BRUTE, 0, 1.0).groups[0])
	spawner.waves = [wave]
	spawner.autostart = true
	(level.get_node("Hero") as Node2D).position = HERO_AWAY
	root.add_child(level)
	await _frames(70)
	var by_name: Dictionary = {}
	for enemy: Node in spawner.get_children():
		by_name[(enemy as Enemy).data.display_name] = enemy
	_check("one wave spawns all three types (%s)" % [by_name.keys()], by_name.size() == 3)
	if by_name.size() != 3:
		level.queue_free()
		return
	var sizes_ok: bool = true
	for type_name: String in by_name:
		var enemy: Enemy = by_name[type_name]
		var radius: float = ((enemy.get_node("%BodyShape") as CollisionShape2D).shape as CircleShape2D).radius
		sizes_ok = sizes_ok and is_equal_approx(radius, enemy.data.body_radius)
		sizes_ok = sizes_ok and (enemy.get_node("%Sprite") as AnimatedSprite2D).sprite_frames == enemy.data.sprite_frames
		sizes_ok = sizes_ok and (enemy.get_node("%HealthComponent") as HealthComponent).max_health == enemy.data.max_health
	_check("each enemy has its own body size, animations and HP (types don't share shapes)", sizes_ok)
	_check("the Hound overtakes the Ghoul on the lane",
		(by_name["Hound"] as Enemy).get_lane_progress() > (by_name["Ghoul"] as Enemy).get_lane_progress())

	var fortress: Fortress = level.get_node("Fortress")
	var damage: Dictionary = {}
	spawner.enemy_reached_fortress.connect(func(e: Enemy) -> void: damage[e.data.display_name] = fortress.health.current_health)
	var brute: Enemy = by_name["Brute"]
	await _until(func() -> bool: return damage.size() == 2, 1200)
	var before_brute: int = fortress.health.current_health
	# The Brute is slow: kill it on the way instead of waiting, and check its death effect.
	var effects: Node = level.get_node("%Effects")
	(brute.get_node("%HealthComponent") as HealthComponent).take_damage(1000)
	await _frames(2)
	_check("Hound and Ghoul deal their own fortress damage (100 -> %s)" % [damage],
		damage.get("Hound", 0) == 100 - HOUND.fortress_damage and damage.get("Ghoul", 0) == 100 - HOUND.fortress_damage - GHOUL.fortress_damage)
	_check("a killed Brute plays the Brute death effect", effects.get_children().any(func(n: Node) -> bool: return n.name.begins_with("BruteDeathEffect")))
	_check("...and never reached the fortress", fortress.health.current_health == before_brute)

	# A second Brute walks all the way in: 30 damage.
	var level_health: int = fortress.health.current_health
	var big: Enemy = (load("res://entities/enemies/enemy.tscn") as PackedScene).instantiate()
	big.data = BRUTE
	big.position = fortress.position + Vector2(-90, 0)
	big.lane = level.get_node("Lane")
	spawner.add_child(big)
	var big_ref: WeakRef = weakref(big)
	await _until(func() -> bool: return big_ref.get_ref() == null, 400)
	_check("a Brute at the gate deals %d (fortress %d -> %d)" % [BRUTE.fortress_damage, level_health, fortress.health.current_health],
		fortress.health.current_health == level_health - BRUTE.fortress_damage)
	level.queue_free()
	await _frames(2)


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
