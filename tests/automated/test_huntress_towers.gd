extends SceneTree
## Automated check for the Huntress's towers (M9 stage 2): the Trap Layer's snares (thrown ahead of the
## leading enemy, held and hurt, a boss held less, a limit of snares at a time, the spiked patch), the Hawk
## Perch's dive (strikes from above through a shield, Eye of the Hunt marks), the Watchtower (more range
## for towers around it, more damage for the hero, Signal Fire, the Marksman's Roost that fires), the
## build menu's hero catalog, and the art for every look.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://entities/towers/projectile.tscn")
const KNIGHT: HeroData = preload("res://data/heroes/knight.tres")
const HUNTRESS: HeroData = preload("res://data/heroes/huntress.tres")
const TRAP: TowerData = preload("res://data/towers/trap_layer.tres")
const HAWK: TowerData = preload("res://data/towers/hawk_perch.tres")
const WATCH: TowerData = preload("res://data/towers/watchtower.tres")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const SHIELDBEARER: EnemyData = preload("res://data/enemies/shieldbearer.tres")
const LICH: EnemyData = preload("res://data/enemies/lich.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_trap()
	await _test_patch_and_boss()
	await _test_hawk()
	await _test_watchtower()
	await _test_roost()
	await _test_catalog()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _level() -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	(level.get_node("Hero") as Node2D).position = Vector2(380, 380)
	root.add_child(level)
	return level


func _enemy(level: Level, data: EnemyData, at: Vector2) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = data
	enemy.position = at
	level.add_child(enemy)
	(enemy.get_node("%AttackRange") as Area2D).monitoring = false
	return enemy


## A finished tower of `data` on slot `index`, upgraded to `level`.
func _tower(level: Level, data: TowerData, index: int, tower_level: int = 1) -> Tower:
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	(level.get_node("%Economy") as Economy).earn(5000, Economy.Source.KILL)
	var slot: BuildSlot = builder.get_slots()[index]
	builder.build(slot, data)
	await _frames(int(data.build_time * 60.0) + 2)
	for _i: int in tower_level - 1:
		builder.upgrade(slot)
	return slot.tower


func _test_data() -> void:
	_check("the three towers: Trap Layer 60, Hawk Perch 75, Watchtower 90, each with 2 upgrades and 2 evolutions",
		TRAP.cost == 60 and HAWK.cost == 75 and WATCH.cost == 90 and TRAP.max_level() == 3 and HAWK.max_level() == 3
		and WATCH.max_level() == 3 and TRAP.evolutions.size() == 2 and HAWK.evolutions.size() == 2 and WATCH.evolutions.size() == 2)
	var frames: SpriteFrames = TRAP.frames
	var ok: bool = true
	for data: TowerData in [TRAP, HAWK, WATCH]:
		for anim: String in ["idle", "fire", "build", "sell", "idle_2", "fire_2", "idle_3", "fire_3"]:
			ok = ok and data.frames.has_animation(StringName("%s_%s" % [data.id, anim]))
		for evolution: TowerEvolution in data.evolutions:
			ok = ok and evolution.frames.has_animation(StringName("%s_idle" % evolution.id)) and evolution.frames.has_animation(StringName("%s_fire" % evolution.id))
		ok = ok and TowerIcons.for_level(data, 3) != null and TowerIcons.for_evolution(data, data.evolutions[1]) != null
	_check("every look has its art and an icon", ok and frames != null)
	var fx: SpriteFrames = HAWK.projectile_frames
	var dirs: bool = true
	for i: int in 8:
		dirs = dirs and fx.has_animation(StringName("hawk_%d" % i))
	_check("the hawk is drawn in 8 directions, the snare and patch exist", dirs and fx.has_animation(&"snare_armed")
		and fx.has_animation(&"snare_sprung") and fx.has_animation(&"patch"))


func _test_trap() -> void:
	var level: Level = _level()
	await _frames(2)
	var tower: Tower = await _tower(level, TRAP, 3)
	var enemy: Enemy = _enemy(level, GHOUL, tower.global_position + Vector2(100, 0))
	var full: int = enemy.get_health().current_health
	await _frames(20)
	var snares: Array[Node] = tower.get_children().filter(func(n: Node) -> bool: return n is Snare)
	_check("it throws a snare onto the leading enemy's road", snares.size() == 1)
	await _frames(40)
	_check("the snare springs: damage 20 and the enemy is held (%d of %d)" % [enemy.get_health().current_health, full],
		enemy.get_health().current_health == full - 20 and enemy.get_status().is_held())
	await _frames(100)
	_check("the hold wears off", not enemy.get_status().is_held() or enemy.get_status().is_held() and enemy.get_health().current_health < full - 20)
	# The limit: a snare lying armed counts until it springs.
	var traps: TowerTraps = TowerTraps.new()
	var stats: TowerTier = tower.get_stats().duplicate()
	stats.snares = 1
	var bait: Enemy = _enemy(level, GHOUL, tower.global_position + Vector2(-100, 0))
	traps.throw(tower, bait, stats)
	bait.free()
	_check("a lying snare counts toward the limit", traps.count() == 1 and not traps.can_throw(stats))
	await _frames(2500)  # no one steps on it: it expires and frees a place
	_check("a snare that is gone frees a place", traps.count() == 0 and traps.can_throw(stats))
	level.queue_free()
	await process_frame


func _test_patch_and_boss() -> void:
	var level: Level = _level()
	await _frames(2)
	var tower: Tower = await _tower(level, TRAP, 3, 3)
	var bear: TowerEvolution = TRAP.evolutions[0]
	var boss: Enemy = _enemy(level, LICH, tower.global_position + Vector2(100, 0))
	var snare: Snare = (load("res://entities/towers/snare.tscn") as PackedScene).instantiate()
	snare.setup(TRAP.stats_for(3), boss.global_position)
	level.add_child(snare)
	await _frames(40)
	_check("a boss ignores a plain snare's hold (it still takes the damage)", snare.is_sprung() and not boss.get_status().is_held())
	var boss2: Enemy = _enemy(level, LICH, tower.global_position + Vector2(-100, 0))
	var snare2: Snare = (load("res://entities/towers/snare.tscn") as PackedScene).instantiate()
	snare2.setup(bear, boss2.global_position)
	level.add_child(snare2)
	await _frames(40)
	_check("Bear Pit holds a boss (0.8 s)", boss2.get_status().is_held())
	var caltrop: TowerEvolution = TRAP.evolutions[1]
	var ghoul: Enemy = _enemy(level, GHOUL, tower.global_position + Vector2(0, 100))
	ghoul.get_health().max_health = 500
	ghoul.get_health().current_health = 500
	var full: int = ghoul.get_health().current_health
	var snare3: Snare = (load("res://entities/towers/snare.tscn") as PackedScene).instantiate()
	snare3.setup(caltrop, ghoul.global_position)
	level.add_child(snare3)
	await _frames(60)
	_check("Caltrop Field: a spiked patch keeps hurting and slowing (%d of %d)" % [ghoul.get_health().current_health, full],
		ghoul.get_health().current_health < full - 25 and ghoul.is_slowed())
	level.queue_free()
	await process_frame


func _test_hawk() -> void:
	var level: Level = _level()
	await _frames(2)
	var tower: Tower = await _tower(level, HAWK, 3)
	tower.process_mode = Node.PROCESS_MODE_DISABLED
	var shield: Enemy = _enemy(level, SHIELDBEARER, tower.global_position + Vector2(0, -150))
	var full: int = shield.get_health().current_health
	_check("the shield faces the shot (a test of the test)", shield.blocks_shot(Vector2.UP))
	var arrow: Projectile = PROJECTILE_SCENE.instantiate()
	arrow.launch(ARCHER, ARCHER.stats_for(1), shield, shield.global_position + Vector2(0, 80), tower.global_position)
	level.add_child(arrow)
	await _frames(40)
	_check("an arrow is stopped by it", shield.get_health().current_health == full)
	var dive: Projectile = PROJECTILE_SCENE.instantiate()
	dive.launch(HAWK, tower.get_stats(), shield, shield.global_position + Vector2(0, 80), tower.global_position)
	level.add_child(dive)
	await _frames(60)
	_check("the hawk's dive strikes from above, through the shield (%d of %d)" % [shield.get_health().current_health, full],
		shield.get_health().current_health == full - 18)
	_check("...without a mark (the plain Hawk Perch)", not shield.get_status().is_marked())
	var eye: TowerEvolution = HAWK.evolutions[1]
	var plain: Enemy = _enemy(level, GHOUL, tower.global_position + Vector2(100, 0))
	plain.get_health().max_health = 500
	plain.get_health().current_health = 500
	var dive2: Projectile = PROJECTILE_SCENE.instantiate()
	dive2.launch(HAWK, eye, plain, plain.global_position + Vector2(0, -80), tower.global_position)
	level.add_child(dive2)
	await _frames(60)
	_check("Eye of the Hunt marks what it strikes", plain.get_status().is_marked())
	_check("Falconer dives on two enemies at once", HAWK.evolutions[0].targets == 2)
	level.queue_free()
	await process_frame


func _test_watchtower() -> void:
	var level: Level = _level()
	await _frames(2)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var slots: Array[BuildSlot] = builder.get_slots()
	var pair: Array[int] = _near_pair(slots, 190.0)
	var watch: Tower = await _tower(level, WATCH, pair[0])
	var archer: Tower = await _tower(level, ARCHER, pair[1])
	var base: float = ARCHER.stats_for(1).attack_range
	_check("towers in the aura get +15%% range (%.0f of %.0f)" % [archer.get_attack_range(), base], is_equal_approx(archer.get_attack_range(), base * 1.15))
	_check("the watchtower itself gets none and does not attack", watch.get_attack_range() == 200.0 and not watch._acts())
	_check("a hero standing there deals +10%", is_equal_approx(builder.hero_bonus_at(watch.global_position), 0.1)
		and builder.hero_bonus_at(watch.global_position + Vector2(900, 0)) == 0.0)
	builder.upgrade(slots[pair[0]])
	builder.upgrade(slots[pair[0]])
	_check("level 3: +25% range", is_equal_approx(archer.get_attack_range(), base * 1.25))
	var signal_fire: TowerEvolution = WATCH.evolutions[0]
	watch.evolve(signal_fire)
	builder.refresh_boosts()
	_check("Signal Fire: towers in reach also fire 15%% faster (%.3f)" % archer.get_stats().fire_interval,
		is_equal_approx(archer.get_fire_rate_boost(), 0.15) and is_equal_approx(archer.get_stats().fire_interval, ARCHER.stats_for(1).fire_interval / 1.15))
	builder.sell(slots[pair[0]])
	builder.refresh_boosts()
	_check("selling it takes the aura away", is_equal_approx(archer.get_attack_range(), base))
	level.queue_free()
	await process_frame


func _test_roost() -> void:
	var level: Level = _level()
	await _frames(2)
	var tower: Tower = await _tower(level, WATCH, 3, 3)
	tower.evolve(WATCH.evolutions[1])
	var enemy: Enemy = _enemy(level, GHOUL, tower.global_position + Vector2(300, 0))
	enemy.get_health().max_health = 500
	enemy.get_health().current_health = 500
	await _frames(240)
	_check("the Marksman's Roost shoots from 300 px (%d of 500)" % enemy.get_health().current_health, enemy.get_health().current_health < 500 and tower._acts())
	level.queue_free()
	await process_frame


func _test_catalog() -> void:
	var roster: Array[HeroData] = [KNIGHT, HUNTRESS]
	var knight_level: Level = _level()
	knight_level.apply_hero(KNIGHT, roster)
	var huntress_level: Level = _level()
	huntress_level.apply_hero(HUNTRESS, roster)
	await _frames(2)
	var knight_ids: Array = knight_level.builder.catalog.map(func(t: TowerData) -> String: return String(t.id))
	var huntress_ids: Array = huntress_level.builder.catalog.map(func(t: TowerData) -> String: return String(t.id))
	_check("the Knight builds archer, cannon, frost, brazier, ballista (%s)" % [knight_ids], knight_ids.size() == 5 and knight_ids.has("brazier") and not knight_ids.has("hawk_perch"))
	_check("the Huntress builds archer, cannon and her three (%s)" % [huntress_ids],
		huntress_ids.size() == 5 and huntress_ids.has("archer") and huntress_ids.has("cannon") and huntress_ids.has("trap_layer")
		and huntress_ids.has("hawk_perch") and huntress_ids.has("watchtower") and not huntress_ids.has("brazier"))
	knight_level.queue_free()
	huntress_level.queue_free()
	await process_frame


func _near_pair(slots: Array[BuildSlot], reach: float) -> Array[int]:
	for i: int in slots.size():
		for j: int in range(i + 1, slots.size()):
			if slots[i].global_position.distance_to(slots[j].global_position) < reach:
				return [i, j]
	return [0, 1]


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
