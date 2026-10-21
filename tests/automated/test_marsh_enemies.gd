extends SceneTree
## Automated check for chapter 2's enemies (M7.5), each readable at a glance and with its ability
## telegraphed:
## - Bloater: slow and tough; killed, it bursts into 3 Bloatlings (small, fast) on its lane, which
##   join the wave (it isn't cleared until they are dead); used up at the fortress, it doesn't burst.
## - Mire Priest: weak; when an enemy near it is hurt it stops, a green ring grows (the telegraph),
##   then every other enemy inside is healed (a boss only a little); killing it mid-telegraph stops
##   the heal; it never heals itself.
## - Shieldbearer: tower shots at its front are blocked ("Blocked", no damage), from the side or
##   behind they hit; blasts and the hero's sword always do; a real tower in front of it does nothing.
## Also: the first time a new enemy appears its hint shows; they arrive gradually in chapter 2's waves
## and never in chapter 1's; their art has every animation.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const EXPLOSION_SCENE: PackedScene = preload("res://entities/towers/explosion.tscn")
const BLOATER: EnemyData = preload("res://data/enemies/bloater.tres")
const BLOATLING: EnemyData = preload("res://data/enemies/bloatling.tres")
const PRIEST: EnemyData = preload("res://data/enemies/mire_priest.tres")
const SHIELD: EnemyData = preload("res://data/enemies/shieldbearer.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const TOLLKEEPER: EnemyData = preload("res://data/enemies/tollkeeper.tres")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const HERO_AWAY: Vector2 = Vector2(380, 380)

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_bloater()
	await _test_bloater_at_fortress()
	await _test_priest()
	await _test_priest_interrupted()
	await _test_shield()
	await _test_shield_vs_tower()
	await _test_hint()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_data() -> void:
	_check("Bloater: slow and tough (%d HP, %.0f px/s), its young small and fast (%d HP, %.0f px/s)"
		% [BLOATER.max_health, BLOATER.move_speed, BLOATLING.max_health, BLOATLING.move_speed],
		BLOATER.max_health >= GHOUL.max_health * 3 and BLOATER.move_speed < GHOUL.move_speed
		and BLOATLING.move_speed > GHOUL.move_speed * 1.4 and BLOATLING.body_radius < GHOUL.body_radius)
	_check("Mire Priest: weak (%d HP), glows" % PRIEST.max_health, PRIEST.max_health <= GHOUL.max_health * 1.5 and PRIEST.glow_color.a > 0.0)
	_check("Shieldbearer: a front shield (%.0f degrees)" % SHIELD.shield_arc, SHIELD.shield_arc >= 90.0 and SHIELD.shield_arc < 180.0)
	var art: bool = true
	for data: EnemyData in [BLOATER, BLOATLING, PRIEST, SHIELD]:
		for state: String in ["idle", "walk", "attack"]:
			for facing: String in ["down", "up", "side"]:
				art = art and data.sprite_frames.has_animation(StringName("%s_%s" % [state, facing]))
		art = art and data.sprite_frames.has_animation(&"death") and not data.hint.is_empty() == (data != BLOATLING)
	for facing: String in ["down", "up", "side"]:
		art = art and PRIEST.sprite_frames.has_animation(StringName("heal_%s" % facing))
	_check("each has its own art (idle, walk, attack in 3 facings, death; the priest's heal) and a hint", art)
	var run: RunData = load("res://data/run/run.tres")
	var first: Dictionary = {}
	var in_chapter_1: bool = false
	for chapter: int in 2:
		var waves: Array = DirAccess.get_files_at("res://data/waves" if chapter == 0 else "res://data/waves/chapter_2")
		waves.sort()
		var n: int = 0
		for file: String in waves:
			if not file.ends_with(".tres"):
				continue
			n += 1
			var wave: WaveData = load(("res://data/waves/" if chapter == 0 else "res://data/waves/chapter_2/") + file)
			for group: SpawnGroup in wave.groups:
				if group.enemy in [BLOATER, PRIEST, SHIELD]:
					if chapter == 0:
						in_chapter_1 = true
					elif not first.has(group.enemy):
						first[group.enemy] = n
	_check("introduced one by one in chapter 2 (Bloater wave %d, Priest wave %d, Shieldbearer wave %d), never in chapter 1"
		% [first.get(BLOATER, 0), first.get(PRIEST, 0), first.get(SHIELD, 0)], not in_chapter_1 and first.size() == 3
		and first[BLOATER] < first[PRIEST] and first[PRIEST] < first[SHIELD] and first[SHIELD] <= 8 and run.chapters.size() == 2)


func _test_bloater() -> void:
	var level: Level = await _level(BLOATER, 1)
	var spawner: WaveSpawner = level.spawner
	var bloater: Enemy = await _first_enemy(level)
	await _frames(60)
	var at: Vector2 = bloater.global_position
	var lane: Path2D = bloater.lane
	var young: Array[Enemy] = []
	spawner.enemy_spawned.connect(func(e: Enemy) -> void: young.append(e))
	var cleared: Array[bool] = [false]
	spawner.wave_cleared.connect(func(_n: int) -> void: cleared[0] = true)
	bloater.get_health().take_damage(100000)
	await _frames(2)
	var near: bool = young.size() == 3
	for e: Enemy in young:
		near = near and e.data == BLOATLING and e.global_position.distance_to(at) < 30.0 and e.lane == lane
	_check("killed, the Bloater bursts into 3 Bloatlings where it fell, on its lane", near)
	_check("...they join the wave (%d enemies in it), which is not cleared yet" % spawner.get_wave_enemy_total(),
		spawner.get_wave_enemy_total() == 4 and not cleared[0])
	await _frames(30)
	_check("...and scuttle on fast (%.0f px/s)" % young[0].velocity.length(), young[0].velocity.length() > BLOATER.move_speed * 2.0)
	for e: Enemy in young:
		e.get_health().take_damage(100000)
	await _frames(2)
	_check("the wave is cleared once they are dead too", cleared[0])
	level.queue_free()
	await _frames(2)


func _test_bloater_at_fortress() -> void:
	var level: Level = await _level(BLOATER, 1)
	var bloater: Enemy = await _first_enemy(level)
	var spawned: Array[int] = [0]
	level.spawner.enemy_spawned.connect(func(_e: Enemy) -> void: spawned[0] += 1)
	bloater.global_position = level.fortress.global_position + Vector2(-60, 0)
	var ref: WeakRef = weakref(bloater)
	await _until(func() -> bool: return ref.get_ref() == null, 60 * 6)
	_check("used up at the fortress, it does not burst", spawned[0] == 0 and level.fortress.health.current_health < 100)
	level.queue_free()
	await _frames(2)


func _test_priest() -> void:
	var level: Level = await _level(null, 0)
	var priest: Enemy = _stationary(level, Vector2(-500, 150), PRIEST, 34)
	var near: Enemy = _stationary(level, Vector2(-430, 150), GHOUL, 100)
	var far: Enemy = _stationary(level, Vector2(-300, 150), GHOUL, 100)
	var boss: Enemy = _stationary(level, Vector2(-500, 220), TOLLKEEPER, 10000)
	await _frames(2)
	for e: Enemy in [near, far, boss]:
		e.get_health().take_damage(floori(e.get_health().max_health * 0.5))
	priest.get_health().take_damage(10)
	var heal: HealAbility = priest.find_children("*", "HealAbility", false, false)[0]
	await _until(func() -> bool: return heal.is_telegraphing(), 60 * 6)
	var rings: Array[Node] = heal.find_children("*", "TelegraphMarker", false, false)
	_check("hurt enemies near it: the priest stops and a green ring grows to its reach (%.0f px)" % heal.radius,
		heal.is_telegraphing() and priest.is_busy() and rings.size() == 1 and is_equal_approx((rings[0] as TelegraphMarker).size, heal.radius))
	var before: Array[int] = [near.get_health().current_health, far.get_health().current_health, boss.get_health().current_health,
		priest.get_health().current_health]
	await _until(func() -> bool: return not heal.is_telegraphing(), 120)
	await _frames(1)
	var gained: int = near.get_health().current_health - before[0]
	_check("then the pulse heals the enemy inside (+%d = %d%% of its max)" % [gained, roundi(gained * 100.0 / near.get_health().max_health)],
		gained == heal.heal_amount(near) and gained >= 20)
	_check("...not the one outside its reach", far.get_health().current_health == before[1])
	_check("...a boss only a little (+%d of %d)" % [boss.get_health().current_health - before[2], boss.get_health().max_health],
		boss.get_health().current_health - before[2] == heal.heal_amount(boss) and heal.heal_amount(boss) < boss.get_health().max_health * 0.05)
	_check("...and never itself", priest.get_health().current_health == before[3])
	level.queue_free()
	await _frames(2)


func _test_priest_interrupted() -> void:
	var level: Level = await _level(null, 0)
	var priest: Enemy = _stationary(level, Vector2(-500, 150), PRIEST, 34)
	var near: Enemy = _stationary(level, Vector2(-450, 150), GHOUL, 100)
	await _frames(2)
	near.get_health().take_damage(50)
	var heal: HealAbility = priest.find_children("*", "HealAbility", false, false)[0]
	await _until(func() -> bool: return heal.is_telegraphing(), 60 * 6)
	priest.get_health().take_damage(1000)
	await _frames(90)
	_check("killed while it raises the censer: no heal (the reason to kill it first)", near.get_health().current_health == 50)
	level.queue_free()
	await _frames(2)


func _test_shield() -> void:
	var level: Level = await _level(SHIELD, 1)
	var bearer: Enemy = await _first_enemy(level)
	await _frames(30)
	var heading: Vector2 = bearer.get_heading()
	var hitbox: Hitbox = Hitbox.new()
	hitbox.damage = 10
	bearer.add_child(hitbox)
	var blocked: Array[int] = [0]
	bearer.shot_blocked.connect(func(_e: Enemy) -> void: blocked[0] += 1)
	var hp: int = bearer.get_health().current_health
	var front: bool = bearer.receive_shot(hitbox, -heading)
	_check("a shot at its front is blocked: no damage, \"Blocked\"", not front and bearer.get_health().current_health == hp and blocked[0] == 1)
	var side: bool = bearer.receive_shot(hitbox, heading.orthogonal())
	_check("from the side it hits", side and bearer.get_health().current_health == hp - 10)
	await _frames(1)
	hp = bearer.get_health().current_health
	var back: bool = bearer.receive_shot(hitbox, heading)
	_check("from behind it hits", back and bearer.get_health().current_health == hp - 10)
	hp = bearer.get_health().current_health
	var blast: Explosion = EXPLOSION_SCENE.instantiate()
	blast.setup(12, 40.0, false)
	blast.position = bearer.global_position
	level.add_child(blast)
	await _frames(3)
	_check("a blast always gets through (-%d)" % (hp - bearer.get_health().current_health), bearer.get_health().current_health == hp - 12)
	hp = bearer.get_health().current_health
	var hero: Hero = level.get_node("Hero")
	hero.global_position = bearer.global_position + heading * 40.0
	await _frames(2)
	hero.attack(bearer.global_position)
	await _frames(10)
	_check("the hero's sword always gets through, even from the front", bearer.get_health().current_health < hp)
	level.queue_free()
	await _frames(2)


## A real archer ahead of it on its road (shooting at its front) does nothing; once it has passed the
## archer (shot in the back), the arrows hit. The archer stands on the graveyard's slot 9, above the
## south road's eastward stretch (y = 240); the Shieldbearer starts west of it, or east of it.
func _test_shield_vs_tower() -> void:
	for ahead: bool in [true, false]:
		var level: Level = await _level(null, 0)
		var lane: Path2D = level.spawner.lanes[2]
		var slot: BuildSlot = level.builder.get_slots()[8]
		var start: Vector2 = Vector2(slot.global_position.x + (-260.0 if ahead else 100.0), 240.0)
		var bearer: Enemy = ENEMY_SCENE.instantiate()
		bearer.data = SHIELD
		bearer.lane = lane
		level.spawner.add_child(bearer)
		bearer.global_position = start
		bearer.get_health().setup(100000)
		await _frames(20)
		level.economy.earn(500, Economy.Source.REFUND)
		level.builder.build(slot, ARCHER)
		var hp: int = bearer.get_health().current_health
		var blocked: Array[int] = [0]
		bearer.shot_blocked.connect(func(_e: Enemy) -> void: blocked[0] += 1)
		await _frames(60 * 3)  # it is still well ahead of (or past) the archer by then
		var lost: int = hp - bearer.get_health().current_health
		if ahead:
			_check("an archer it walks toward: its arrows are blocked (%d blocked, -%d HP)" % [blocked[0], lost], blocked[0] >= 2 and lost == 0)
		else:
			_check("an archer it has passed: its arrows hit its back (-%d HP)" % lost, lost > 0)
		level.queue_free()
		await _frames(2)


func _test_hint() -> void:
	var level: Level = await _level(PRIEST, 1)
	await _first_enemy(level)
	await _frames(2)
	var banner: Label = level.get_node("HUD").get_node("%Banner")
	_check("its first appearance shows its hint (\"%s\")" % banner.text, banner.visible and banner.text.contains(PRIEST.hint))
	level.queue_free()
	await _frames(2)


# ---------------------------------------------------------------- helpers

## The arena with one wave of `count` of `enemy` on the south road (or an empty wave), the hero away.
func _level(enemy: EnemyData, count: int) -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var wave: WaveData = WaveFixtures.make_wave(count, 1.0, enemy if enemy != null else GHOUL, 2) if count > 0 else WaveData.new()
	spawner.waves = [wave, WaveData.new()]
	WaveFixtures.no_upgrades(level)
	(level.get_node("Hero") as Node2D).position = HERO_AWAY
	root.add_child(level)
	await WaveFixtures.start_wave(level)
	return level


func _first_enemy(level: Level) -> Enemy:
	var found: Array[Enemy] = []
	level.spawner.enemy_spawned.connect(func(e: Enemy) -> void: found.append(e), CONNECT_ONE_SHOT)
	await _until(func() -> bool: return not found.is_empty(), 120)
	return found[0]


func _stationary(level: Level, at: Vector2, data: EnemyData, health: int) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = data
	enemy.position = at
	level.add_child(enemy)
	(enemy.get_node("%AttackRange") as Area2D).monitoring = false
	enemy.get_health().setup(health)
	return enemy


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
