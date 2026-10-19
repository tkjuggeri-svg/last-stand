extends SceneTree
## Automated check for the run modifier store: flat and percent maths over named stats, stacking and
## non-stackable upgrades, that an empty store changes nothing, that every system with run stats reads
## them (hero, towers per type and for all, fortress, lives, kill gold, interest, upgrade prices,
## instant repair), and that Restart (a fresh level) starts from nothing.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const CANNON: TowerData = preload("res://data/towers/cannon.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_store_maths()
	await _test_empty_store_changes_nothing()
	await _test_systems_read_their_stats()
	await _test_restart_resets()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_store_maths() -> void:
	var store: RunModifiers = RunModifiers.new()
	_check("an empty store returns the base", is_equal_approx(store.apply(10.0, [&"a"]), 10.0))
	store.add_modifier(_mod(&"a", 5.0, 0.0))
	store.add_modifier(_mod(&"a", 0.0, 0.2))
	store.add_modifier(_mod(&"b", 0.0, 0.3))
	_check("(base + flats) x (1 + percents): (10 + 5) x 1.2 = 18", is_equal_approx(store.apply(10.0, [&"a"]), 18.0))
	_check("percents of several stat names add up: (10 + 5) x 1.5 = 22.5", is_equal_approx(store.apply(10.0, [&"a", &"b"]), 22.5))
	store.add_modifier(_mod(&"c", 0.0, -2.0))
	_check("never below 0", store.apply(10.0, [&"c"]) == 0.0)
	_check("tower stats listen to all towers and their own type",
		RunModifiers.tower_stats(&"damage", &"archer") == [&"tower.damage", &"tower.archer.damage"])
	var stackable: UpgradeData = _upgrade(&"s", true, [_mod(&"x", 1.0, 0.0)])
	var once: UpgradeData = _upgrade(&"o", false, [_mod(&"y", 1.0, 0.0)])
	var added: Array[int] = []
	store.upgrade_added.connect(func(_d: UpgradeData, stacks: int) -> void: added.append(stacks))
	store.add_upgrade(stackable)
	store.add_upgrade(stackable)
	store.add_upgrade(once)
	_check("a stackable upgrade stacks (x2 -> +2)", store.get_stacks(&"s") == 2 and is_equal_approx(store.apply(0.0, [&"x"]), 2.0) and store.can_take(stackable))
	_check("a non-stackable one can't be taken again", store.get_stacks(&"o") == 1 and not store.can_take(once))
	_check("taken upgrades are listed in order (%s)" % [added], store.get_taken().size() == 3 and added == [1, 2, 1])
	store.free()


func _test_empty_store_changes_nothing() -> void:
	var level: Level = _make_level()
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	var tower: Tower = await _tower(level, 3, ARCHER)
	_check("with nothing taken: hero 100 HP, 10 damage, normal reach",
		hero.health.max_health == 100 and (hero.get_node("%AttackHitbox") as Hitbox).damage == 10
		and (hero.get_node("%AttackHitbox") as Node2D).scale == Vector2.ONE)
	_check("...towers have their data's stats", tower.get_stats().damage == ARCHER.damage
		and is_equal_approx(tower.get_attack_range(), ARCHER.attack_range) and is_equal_approx(tower.get_stats().fire_interval, ARCHER.fire_interval))
	_check("...fortress 100 HP, 3 lives", (level.get_node("Fortress") as Fortress).health.max_health == 100
		and (level.get_node("%HeroLives") as HeroLives).get_max_lives() == 3)
	level.queue_free()
	await _frames(2)


func _test_systems_read_their_stats() -> void:
	var level: Level = _make_level()
	await _frames(2)
	var mods: RunModifiers = level.get_node("%RunModifiers")
	var hero: Hero = level.get_node("Hero")
	var fortress: Fortress = level.get_node("Fortress")
	var economy: Economy = level.get_node("%Economy")
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var archer: Tower = await _tower(level, 3, ARCHER)
	var cannon: Tower = await _tower(level, 2, CANNON)
	hero.health.take_damage(40)
	mods.add_modifier(_mod(RunModifiers.HERO_MAX_HEALTH, 30.0, 0.0))
	_check("+30 hero max HP: 130 max, and the hurt hero gains the 30 too (%d/%d)" % [hero.health.current_health, hero.health.max_health],
		hero.health.max_health == 130 and hero.health.current_health == 90)
	mods.add_modifier(_mod(RunModifiers.HERO_DAMAGE, 5.0, 0.0))
	mods.add_modifier(_mod(RunModifiers.HERO_REACH, 0.0, 0.2))
	_check("hero damage +5 and reach +20%", (hero.get_node("%AttackHitbox") as Hitbox).damage == 15
		and (hero.get_node("%AttackHitbox") as Node2D).scale.is_equal_approx(Vector2.ONE * 1.2))
	mods.add_modifier(_mod(RunModifiers.HERO_MOVE_SPEED, 0.0, 0.5))
	var start: Vector2 = hero.position
	Input.action_press("move_right")
	await _frames(30)
	Input.action_release("move_right")
	_check("hero speed +50%% (moved %.0f px in 0.5 s)" % (hero.position.x - start.x), absf(hero.position.x - start.x - 150.0) < 6.0)
	mods.add_modifier(_mod(RunModifiers.HERO_ATTACK_COOLDOWN, 0.0, -0.5))
	hero.attack(hero.global_position + Vector2.RIGHT * 50)
	await _frames(14)  # 0.4 s cooldown halved to 0.2 s
	var swings: Array[int] = [0]
	(hero.get_node("%Sprite") as AnimatedSprite2D).animation_changed.connect(func() -> void: swings[0] += 1)
	hero.attack(hero.global_position + Vector2.RIGHT * 50)
	_check("hero attack cooldown -50%: swings again after 0.23 s", swings[0] > 0)

	mods.add_modifier(_mod(&"tower.damage", 0.0, 0.5))
	_check("+50%% damage for all towers (archer %d, cannon %d)" % [archer.get_stats().damage, cannon.get_stats().damage],
		archer.get_stats().damage == roundi(ARCHER.damage * 1.5) and cannon.get_stats().damage == roundi(CANNON.damage * 1.5))
	mods.add_modifier(_mod(&"tower.archer.range", 0.0, 0.1))
	_check("+10%% range for archers only (archer %.0f, cannon %.0f; the range area follows)" % [archer.get_attack_range(), cannon.get_attack_range()],
		is_equal_approx(archer.get_attack_range(), ARCHER.attack_range * 1.1) and is_equal_approx(cannon.get_attack_range(), CANNON.attack_range)
		and is_equal_approx(((archer.get_node("%RangeShape") as CollisionShape2D).shape as CircleShape2D).radius, ARCHER.attack_range * 1.1))
	mods.add_modifier(_mod(&"tower.fire_interval", 0.0, -0.2))
	_check("-20% fire interval", is_equal_approx(archer.get_stats().fire_interval, ARCHER.fire_interval * 0.8))
	mods.add_modifier(_mod(&"tower.build_time", 0.0, -0.5))
	builder.build(builder.get_slots()[0], ARCHER)
	await _frames(int(ARCHER.build_time * 30.0) + 2)
	_check("-50% build time: finished in half the time", not builder.get_slots()[0].tower.is_building())
	_check("the tower data itself is untouched", ARCHER.damage == 10 and is_equal_approx(ARCHER.attack_range, 210.0))
	mods.add_modifier(_mod(RunModifiers.TOWER_UPGRADE_COST, 0.0, -0.25))
	_check("tower upgrades 25%% cheaper (%d)" % builder.upgrade_cost(builder.get_slots()[3]), builder.upgrade_cost(builder.get_slots()[3]) == roundi(ARCHER.upgrade_cost(2) * 0.75))

	fortress.health.take_damage(30)
	mods.add_modifier(_mod(RunModifiers.FORTRESS_MAX_HEALTH, 50.0, 0.0))
	_check("fortress +50 max HP (%d/%d)" % [fortress.health.current_health, fortress.health.max_health], fortress.health.max_health == 150 and fortress.health.current_health == 120)
	var repair: UpgradeData = _upgrade(&"repair", true, [])
	repair.instant_effect = RunModifiers.INSTANT_REPAIR_FORTRESS
	repair.effect_amount = 0.2
	mods.add_upgrade(repair)
	_check("instant repair of 20%% of max HP (%d)" % fortress.health.current_health, fortress.health.current_health == 150)
	var lives: HeroLives = level.get_node("%HeroLives")
	mods.add_modifier(_mod(RunModifiers.HERO_LIVES, 1.0, 0.0))
	await _frames(1)
	_check("+1 life: 4 lives and 4 helms in the HUD", lives.get_lives_left() == 4 and lives.get_max_lives() == 4
		and (level.get_node("HUD").get_node("%LivesIcons") as Node).get_child_count() == 4)

	# Gold: +50% kill gold, interest 10% capped at 20.
	mods.add_modifier(_mod(RunModifiers.KILL_GOLD, 0.0, 0.5))
	mods.add_modifier(_mod(RunModifiers.INTEREST, 0.1, 0.0))
	mods.add_modifier(_mod(RunModifiers.INTEREST_CAP, 20.0, 0.0))
	var rewards: WaveRewards = level.get_node("%WaveRewards")
	economy.try_spend(economy.get_gold())
	economy.earn(100, Economy.Source.KILL)
	rewards.begin_wave()
	var dead: Enemy = _enemy_with(GHOUL)
	rewards.call("_on_enemy_killed", dead)
	dead.free()
	var after_kill: int = economy.get_gold()
	_check("+50%% kill gold: a ghoul pays %d" % (after_kill - 100), after_kill - 100 == roundi(GHOUL.gold_reward * 1.5))
	var interest: Array[int] = []
	rewards.interest_paid.connect(func(a: int) -> void: interest.append(a))
	economy.earn(400, Economy.Source.KILL)
	var before_end: int = economy.get_gold()
	rewards.end_wave()
	_check("interest at wave end: 10%% of %d, capped at 20 (%s)" % [before_end, interest], interest == [20])
	level.queue_free()
	await _frames(2)


## Through main.tscn: upgrades taken, Restart, everything back to base.
func _test_restart_resets() -> void:
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(2)
	var level: Level = _level_of(main)
	var mods: RunModifiers = level.get_node("%RunModifiers")
	mods.add_upgrade(_upgrade(&"big", false, [_mod(RunModifiers.HERO_MAX_HEALTH, 50.0, 0.0), _mod(&"tower.damage", 0.0, 1.0)]))
	_check("an upgrade is active in the run", (level.get_node("Hero") as Hero).health.max_health == 150 and mods.get_taken().size() == 1)
	(level.get_node("Fortress") as Fortress).health.take_damage(1000)
	await _frames(2)
	((main.get_node("%GameOverScreen") as Node).get_node("%RestartButton") as Button).pressed.emit()
	await _frames(2)
	level = _level_of(main)
	var fresh: RunModifiers = level.get_node("%RunModifiers")
	_check("Restart: no upgrades, base stats again", fresh != mods and fresh.get_taken().is_empty()
		and (level.get_node("Hero") as Hero).health.max_health == 100 and fresh.apply(10.0, [&"tower.damage"]) == 10.0)
	main.queue_free()
	await _frames(2)


func _mod(stat: StringName, flat: float, percent: float) -> StatModifier:
	var modifier: StatModifier = StatModifier.new()
	modifier.stat = stat
	modifier.flat = flat
	modifier.percent = percent
	return modifier


func _upgrade(id: StringName, stackable: bool, modifiers: Array[StatModifier]) -> UpgradeData:
	var data: UpgradeData = UpgradeData.new()
	data.id = id
	data.stackable = stackable
	data.modifiers = modifiers
	return data


func _enemy_with(data: EnemyData) -> Enemy:
	var enemy: Enemy = (load("res://entities/enemies/enemy.tscn") as PackedScene).instantiate()
	enemy.data = data
	return enemy


func _make_level() -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	(level.get_node("Hero") as Node2D).position = Vector2(-200, 80)
	root.add_child(level)
	return level


func _tower(level: Level, slot_index: int, data: TowerData) -> Tower:
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	(level.get_node("%Economy") as Economy).earn(data.cost, Economy.Source.REFUND)
	builder.build(builder.get_slots()[slot_index], data)
	await _frames(int(data.build_time * 60.0) + 2)
	return builder.get_slots()[slot_index].tower


func _level_of(main: Node) -> Level:
	for child: Node in main.get_children():
		if child is Level:
			return child
	return null


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
