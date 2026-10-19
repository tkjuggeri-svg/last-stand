extends SceneTree
## Automated check for tower combat: Archer, Cannon and Frost towers built through the TowerBuilder in
## the real level: targeting, projectiles, splash, slow (and its expiry), kill gold, and that towers
## never hurt the hero or the fortress and drop dead or removed targets.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const GHOUL_SCENE: PackedScene = preload("res://entities/enemies/ghoul.tscn")
const EXPLOSION_SCENE: PackedScene = preload("res://entities/towers/explosion.tscn")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const FROST: TowerData = preload("res://data/towers/frost.tres")
const CANNON: TowerData = preload("res://data/towers/cannon.tres")
## Far from the lane: the hero stays out of every fight unless a test puts it somewhere.
const HERO_AWAY: Vector2 = Vector2(-750, 330)

var _failures: int = 0


func _initialize() -> void:
	await _test_archer()
	await _test_archer_targets_the_leader()
	await _test_cannon_splash()
	await _test_blast_spares_hero_and_fortress()
	await _test_frost_slow()
	await _test_slow_never_stacks()
	await _test_dead_and_removed_targets()
	await _test_no_attacks_while_building_or_sold()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_archer() -> void:
	var level: Level = _make_level(1, 1.0)
	var economy: Economy = level.get_node("%Economy")
	var tower: Tower = _build(level, 0, ARCHER)
	var ghoul: Enemy = await _first_ghoul(level)
	var hits: Array[int] = []
	var last_hp: Array[int] = [ghoul.data.max_health]
	(ghoul.get_node("%HealthComponent") as HealthComponent).health_changed.connect(func(current: int, _m: int) -> void:
		hits.append(last_hp[0] - current)
		last_hp[0] = current)
	var arrow_looks: Array[StringName] = []
	var ghoul_ref: WeakRef = weakref(ghoul)
	for _i: int in 900:
		await physics_frame
		for child: Node in tower.get_children():
			if child is Projectile:
				arrow_looks.append((child.get_node("%Sprite") as AnimatedSprite2D).animation)
		if ghoul_ref.get_ref() == null:
			break
	_check("the Archer Tower kills a ghoul on its own", ghoul_ref.get_ref() == null)
	_check("every arrow deals exactly 10 (%s)" % [hits], hits.size() == 3 and hits.all(func(h: int) -> bool: return h == ARCHER.damage))
	_check("arrows are visible, pointing where they fly (%s...)" % [arrow_looks.slice(0, 2)],
		not arrow_looks.is_empty() and arrow_looks.all(func(a: StringName) -> bool: return String(a).begins_with("arrow_")))
	# _build() first adds the tower's price, so the build itself is gold-neutral here.
	_check("the tower's kill pays gold (+10, +1 perfect-defense bonus; gold %d)" % economy.get_gold(),
		economy.get_gold() == 100 + 10 + 1)
	await _free(level)


func _test_archer_targets_the_leader() -> void:
	var level: Level = _make_level(2, 1.2)
	var tower: Tower = _build(level, 0, ARCHER)
	var spawner: EnemySpawner = level.get_node("EnemySpawner")
	await _until(func() -> bool: return spawner.get_child_count() == 2, 200)
	var leader: Enemy = spawner.get_child(0)
	var follower: Enemy = spawner.get_child(1)
	var follower_hp: HealthComponent = follower.get_node("%HealthComponent")
	await _until(func() -> bool: return tower.get_target() != null, 300)
	_check("the tower aims at the ghoul furthest along the lane", tower.get_target() == leader)
	var leader_ref: WeakRef = weakref(leader)
	await _until(func() -> bool: return leader_ref.get_ref() == null, 600)
	_check("one target at a time: the second ghoul was untouched until the first died",
		leader_ref.get_ref() == null and follower_hp.current_health == follower.data.max_health)
	await _frames(2)
	_check("then it switches to the next ghoul", tower.get_target() == follower)
	await _free(level)


func _test_cannon_splash() -> void:
	var level: Level = _make_level(0, 1.0)
	_build(level, 4, CANNON)  # slot at (-140, -80)
	var ghouls: Array[Enemy] = []
	for offset: Vector2 in [Vector2(0, 0), Vector2(22, 10), Vector2(-18, 14)]:
		ghouls.append(_stationary_ghoul(level, Vector2(-200, 60) + offset))
	var max_hp: int = ghouls[0].data.max_health  # read now: a one-shot frees them
	var damage_taken: Array[int] = [0, 0, 0]
	for i: int in ghouls.size():
		var hp: HealthComponent = ghouls[i].get_node("%HealthComponent")
		hp.health_changed.connect(func(current: int, maximum: int) -> void: damage_taken[i] = maximum - current)
	await _until(func() -> bool: return damage_taken.any(func(d: int) -> bool: return d > 0), 400)
	await _frames(3)
	var expected: int = mini(CANNON.damage, max_hp)
	_check("one cannon shot hits all 3 ghouls in the blast for %d each (%s)" % [expected, damage_taken],
		damage_taken == [expected, expected, expected])
	await _free(level)


## A blast right next to the fortress, with the hero inside it too: only the ghoul is hurt.
func _test_blast_spares_hero_and_fortress() -> void:
	var level: Level = _make_level(0, 1.0)
	var hero: Hero = level.get_node("Hero")
	var fortress: Fortress = level.get_node("Fortress")
	var ghoul: Enemy = _stationary_ghoul(level, Vector2(-70, -30))
	(ghoul.get_node("%AttackRange") as Area2D).monitoring = false  # keep its claws out of this test
	hero.position = Vector2(-70, 30)
	await _frames(2)
	var blast: Explosion = EXPLOSION_SCENE.instantiate()
	blast.setup(CANNON.damage, CANNON.splash_radius)
	blast.position = Vector2(-70, 0)  # the fortress wall (x = -48) is inside the 56 px blast
	level.add_child(blast)
	await _frames(4)
	_check("the blast hurts the ghoul", not is_instance_valid(ghoul) or (ghoul.get_node("%HealthComponent") as HealthComponent).current_health < 30)
	_check("...but never the hero", hero.health.current_health == 100)
	_check("...and never the fortress", fortress.health.current_health == 100)
	await _free(level)


func _test_frost_slow() -> void:
	var level: Level = _make_level(1, 1.0)
	var tower_slot: BuildSlot = (level.get_node("%TowerBuilder") as TowerBuilder).get_slots()[3]  # (-380, -90)
	_build(level, 3, FROST)
	var ghoul: Enemy = await _first_ghoul(level)
	var sprite: CanvasItem = ghoul.get_node("%Sprite")
	var aura: CanvasItem = ghoul.get_node("%FrostAura")
	await _until(func() -> bool: return ghoul.is_slowed(), 900)
	await _frames(2)
	var full_speed: float = ghoul.data.move_speed
	_check("a frost bolt slows the ghoul to half speed (%.0f)" % ghoul.get_move_speed(), is_equal_approx(ghoul.get_move_speed(), full_speed * FROST.slow_factor))
	_check("...it really walks slower (%.1f px/s)" % ghoul.velocity.length(), absf(ghoul.velocity.length() - full_speed * 0.5) < 1.0 or ghoul.has_target())
	_check("the slow is visible: icy tint and frost aura", aura.visible and sprite.self_modulate.b > sprite.self_modulate.r)
	(level.get_node("%TowerBuilder") as TowerBuilder).sell(tower_slot)  # no more bolts
	await _frames(roundi(FROST.slow_duration * 60.0) + 10)
	_check("the slow wears off after its duration", not ghoul.is_slowed() and is_equal_approx(ghoul.get_move_speed(), full_speed))
	_check("...speed and looks are back to normal", absf(ghoul.velocity.length() - full_speed) < 1.0 and not aura.visible and sprite.self_modulate == Color.WHITE)
	await _free(level)


func _test_slow_never_stacks() -> void:
	var level: Level = _make_level(0, 1.0)
	var ghoul: Enemy = _stationary_ghoul(level, Vector2(-600, 200))
	await _frames(2)
	var full: float = ghoul.data.move_speed
	for _i: int in 5:
		ghoul.apply_slow(0.5, 2.0)
	_check("five frost hits still mean half speed, not less (%.0f)" % ghoul.get_move_speed(), is_equal_approx(ghoul.get_move_speed(), full * 0.5))
	ghoul.apply_slow(0.8, 4.0)
	_check("a weaker slow doesn't weaken the current one", is_equal_approx(ghoul.get_move_speed(), full * 0.5))
	await _frames(130)
	_check("...but the longest duration is kept (still slowed after 2.2 s)", ghoul.is_slowed())
	await _frames(130)
	_check("all slows end; full speed again", not ghoul.is_slowed() and is_equal_approx(ghoul.get_move_speed(), full))
	await _free(level)


func _test_dead_and_removed_targets() -> void:
	# Killed while an arrow is in the air.
	var level: Level = _make_level(1, 1.0)
	var tower: Tower = _build(level, 0, ARCHER)
	var ghoul: Enemy = await _first_ghoul(level)
	await _until(func() -> bool: return tower.get_children().any(func(c: Node) -> bool: return c is Projectile), 600)
	(ghoul.get_node("%HealthComponent") as HealthComponent).take_damage(100)
	await _frames(1)
	_check("a dead ghoul is no longer the tower's target", tower.get_target() == null)
	await _frames(60)
	_check("the arrow in flight just disappears", not tower.get_children().any(func(c: Node) -> bool: return c is Projectile))
	await _free(level)

	# A ghoul that walks out of range is dropped too, and one used up at the fortress is never targeted.
	level = _make_level(1, 1.0)
	tower = _build(level, 5, ARCHER)  # (-110, 90): covers the last stretch to the fortress
	ghoul = await _first_ghoul(level)
	(ghoul.get_node("%HealthComponent") as HealthComponent).setup(10000)  # survives to the fortress
	var fortress: Fortress = level.get_node("Fortress")
	var ghoul_ref: WeakRef = weakref(ghoul)
	var aimed_at_it: Array[bool] = [false]
	for _i: int in 1200:
		await physics_frame
		aimed_at_it[0] = aimed_at_it[0] or tower.get_target() == ghoul_ref.get_ref()
		if ghoul_ref.get_ref() == null:
			break
	await _frames(2)
	_check("the tower fought the ghoul on its way in", aimed_at_it[0])
	_check("once it reached the fortress it is no longer targeted", fortress.health.current_health == 90 and tower.get_target() == null)
	await _free(level)


func _build(level: Level, slot_index: int, data: TowerData) -> Tower:
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	(level.get_node("%Economy") as Economy).earn(data.cost, Economy.Source.REFUND)  # pay for it
	var slot: BuildSlot = builder.get_slots()[slot_index]
	builder.build(slot, data)
	return slot.tower


func _first_ghoul(level: Level) -> Enemy:
	var spawner: EnemySpawner = level.get_node("EnemySpawner")
	await _until(func() -> bool: return spawner.get_child_count() > 0, 120)
	return spawner.get_child(0)


## A ghoul without a lane: it just stands there (and still counts as a living enemy for towers).
func _stationary_ghoul(level: Level, at: Vector2) -> Enemy:
	var ghoul: Enemy = GHOUL_SCENE.instantiate()
	ghoul.position = at
	level.add_child(ghoul)
	return ghoul

## A ghoul waits in range before the tower is placed: no shot until construction is done, then it
## fights; once sold it never fires again. Selling mid-construction refunds once, like any sale.
func _test_no_attacks_while_building_or_sold() -> void:
	var level: Level = _make_level(0, 1.0)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var economy: Economy = level.get_node("%Economy")
	var ghoul: Enemy = _stationary_ghoul(level, Vector2(-380, -30))  # 60 px below slot 3 (-380, -90)
	(ghoul.get_node("%AttackRange") as Area2D).monitoring = false
	var health: HealthComponent = ghoul.get_node("%HealthComponent")
	await _frames(2)
	var tower: Tower = _build(level, 3, ARCHER)
	var finished: Array[bool] = [false]
	tower.construction_finished.connect(func() -> void: finished[0] = true)
	var build_frames: int = roundi(ARCHER.build_time * 60.0)
	var quiet: bool = true
	for _i: int in build_frames - 1:
		await physics_frame
		quiet = quiet and tower.is_building() and tower.get_target() == null and _shots(tower) == 0
	_check("under construction (%.1f s) the tower neither aims nor fires" % ARCHER.build_time,
		quiet and health.current_health == health.max_health and not finished[0])
	await _until(func() -> bool: return _shots(tower) > 0, 5)
	_check("it fires as soon as construction finishes", finished[0] and not tower.is_building() and _shots(tower) == 1)

	await _until(func() -> bool: return _shots(tower) == 0, 60)  # the arrow lands
	var slot: BuildSlot = builder.get_slots()[3]
	var gold_before: int = economy.get_gold()
	builder.sell(slot)
	_check("a sold tower is deactivated at once", not tower.is_active() and tower.get_target() == null)
	var health_after_sale: int = health.current_health
	await _frames(roundi(ARCHER.fire_interval * 60.0) * 2)
	_check("...and never shoots again", health.current_health == health_after_sale and economy.get_gold() == gold_before + builder.refund_for(ARCHER))

	tower = _build(level, 3, ARCHER)
	await _frames(5)
	gold_before = economy.get_gold()
	var refund: int = builder.sell(slot) + builder.sell(slot)
	_check("selling mid-construction refunds the normal 50%% once (%d)" % refund,
		refund == builder.refund_for(ARCHER) and economy.get_gold() == gold_before + refund and not tower.is_active())
	await _frames(build_frames)
	_check("...and the unfinished tower never fires", health.current_health == health_after_sale)
	await _free(level)


func _shots(tower: Tower) -> int:
	if not is_instance_valid(tower):
		return 0
	return tower.get_children().filter(func(c: Node) -> bool: return c is Projectile).size()


func _make_level(count: int, interval: float) -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var spawner: EnemySpawner = level.get_node("EnemySpawner")
	spawner.spawn_count = count
	spawner.spawn_interval = interval
	(level.get_node("Hero") as Node2D).position = HERO_AWAY
	root.add_child(level)
	return level


func _free(level: Node) -> void:
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
