extends SceneTree
## Automated check for the run upgrade pool (data/upgrades): every upgrade is complete (id, name,
## description, icon), the pool covers all 4 categories with common and rare cards and has trade-offs,
## and each upgrade, taken in a fresh level, does what its card says (hero, towers, fortress, economy;
## pierce, burning ground and thorns are checked by their effect in play).
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const UPGRADES_DIR: String = "res://data/upgrades"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const CANNON: TowerData = preload("res://data/towers/cannon.tres")
const FROST: TowerData = preload("res://data/towers/frost.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")

var _failures: int = 0
var _pool: Dictionary = {}


func _initialize() -> void:
	_test_pool()
	for id: StringName in _pool:
		await _test_upgrade(id)
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_pool() -> void:
	var complete: bool = true
	var categories: Dictionary = {}
	var rarities: Dictionary = {}
	var trade_offs: int = 0
	for file: String in DirAccess.get_files_at(UPGRADES_DIR):
		if not file.ends_with(".tres"):
			continue
		var data: UpgradeData = load(UPGRADES_DIR.path_join(file))
		_pool[data.id] = data
		complete = complete and String(data.id) == file.get_basename() and not data.display_name.is_empty()
		complete = complete and not data.description.is_empty() and data.icon != null
		complete = complete and (not data.modifiers.is_empty() or data.instant_effect != &"")
		categories[data.category] = true
		rarities[data.rarity] = true
		var plus: bool = data.modifiers.any(func(m: StatModifier) -> bool: return m.flat > 0.0 or m.percent > 0.0)
		var minus: bool = data.modifiers.any(_is_drawback)
		if plus and minus:
			trade_offs += 1
	_check("%d upgrades, each with id (= file name), name, description, icon and an effect" % _pool.size(), _pool.size() >= 15 and complete)
	_check("all 4 categories, common and rare cards", categories.size() == 4 and rarities.size() == 2)
	_check("some are trade-offs, not pure buffs (%d)" % trade_offs, trade_offs >= 3)
	var linked: bool = true
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var offered: Array[UpgradeData] = (level.get_node("%UpgradeOffers") as UpgradeOffers).pool
	for id: StringName in _pool:
		linked = linked and offered.any(func(d: UpgradeData) -> bool: return d.id == id)
	_check("the level offers every upgrade", linked and offered.size() == _pool.size())
	level.free()


func _test_upgrade(id: StringName) -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	(level.get_node("Hero") as Node2D).position = Vector2(380, 380)
	root.add_child(level)
	await _frames(2)
	var mods: RunModifiers = level.get_node("%RunModifiers")
	var hero: Hero = level.get_node("Hero")
	var hitbox: Hitbox = hero.get_node("%AttackHitbox")
	var fortress: Fortress = level.get_node("Fortress")
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var lives: HeroLives = level.get_node("%HeroLives")
	var data: UpgradeData = _pool[id]
	var label: String = "%s: %s" % [data.display_name, data.description]
	var ok: bool = false
	match String(id):
		"honed_blade":
			mods.add_upgrade(data)
			ok = hitbox.damage == 14
		"long_reach":
			var trail: AnimatedSprite2D = hero.get_node("%AttackVisual")
			mods.add_upgrade(data)
			hero.attack(hero.global_position + Vector2.RIGHT * 50)
			var one: bool = hitbox.scale.is_equal_approx(Vector2.ONE * 1.15) and trail.animation == &"swing_0_1"
			await _frames(30)
			mods.add_upgrade(data)
			hero.attack(hero.global_position + Vector2.RIGHT * 50)
			label += " (the trail grows with it: %s, %s)" % [one, trail.animation]
			ok = one and trail.animation == &"swing_0_2" and hero.get_reach_tier() == 2
		"battle_rhythm":
			mods.add_upgrade(data)
			ok = is_equal_approx(mods.apply(hero.attack_cooldown, [RunModifiers.HERO_ATTACK_COOLDOWN]), hero.attack_cooldown * 0.85)
		"iron_body":
			mods.add_upgrade(data)
			ok = hero.health.max_health == 130 and hero.health.current_health == 130
		"second_wind":
			mods.add_upgrade(data)
			ok = lives.get_lives_left() == 4 and lives.get_max_lives() == 4
		"fleet_step":
			mods.add_upgrade(data)
			ok = is_equal_approx(hero.get_dash().get_cooldown(), hero.get_dash().cooldown * 0.75)
		"cinder_dash":
			mods.add_upgrade(data)
			ok = is_equal_approx(hero.get_dash().get_trail_dps(), 16.0)
		"berserker":
			mods.add_upgrade(data)
			ok = hitbox.damage == 16 and hero.health.max_health == 70
		"fletching":
			var archer: Tower = await _tower(level, 3, ARCHER)
			mods.add_upgrade(data)
			ok = archer.get_stats().damage == roundi(ARCHER.damage * (1.0 + _percent(data, &"tower.damage")))
		"eagle_eye":
			var archer2: Tower = await _tower(level, 3, ARCHER)
			mods.add_upgrade(data)
			ok = is_equal_approx(archer2.get_attack_range(), ARCHER.attack_range * 1.12)
		"quick_masons":
			mods.add_upgrade(data)
			builder.build(builder.get_slots()[3], ARCHER)
			await _frames(roundi(ARCHER.build_time * 60.0 * 0.4) + 2)
			ok = not builder.get_slots()[3].is_empty() and not builder.get_slots()[3].tower.is_building()
		"overcharge":
			var cannon: Tower = await _tower(level, 2, CANNON)
			mods.add_upgrade(data)
			ok = cannon.get_stats().damage == roundi(CANNON.damage * (1.0 + _percent(data, &"tower.damage")))
			ok = ok and _percent(data, &"tower.fire_interval") > 0.0 and is_equal_approx(cannon.get_attack_range(), CANNON.attack_range)
			ok = ok and is_equal_approx(cannon.get_stats().fire_interval, CANNON.fire_interval * (1.0 + _percent(data, &"tower.fire_interval")))
		"piercing":
			ok = await _check_pierce(level, data)
		"hellfire":
			ok = await _check_burn(level, data)
		"deep_freeze":
			var frost: Tower = await _tower(level, 3, FROST)
			mods.add_upgrade(data)
			ok = is_equal_approx(frost.get_stats().slow_duration, FROST.slow_duration * 1.4)
		"masonry":
			mods.add_upgrade(data)
			ok = fortress.health.max_health == 125 and fortress.health.current_health == 125
		"repairs":
			fortress.health.take_damage(50)
			mods.add_upgrade(data)
			ok = fortress.health.current_health == 80
		"thorns":
			ok = await _check_thorns(level, data)
		"bounty":
			mods.add_upgrade(data)
			# Once per run: a stackable kill-gold bonus snowballed with the growing waves.
			ok = not data.stackable and mods.apply_int(GHOUL.gold_reward, [RunModifiers.KILL_GOLD]) == roundi(GHOUL.gold_reward * (1.0 + _percent(data, RunModifiers.KILL_GOLD)))
		"treasury":
			mods.add_upgrade(data)
			var rewards: WaveRewards = level.get_node("%WaveRewards")
			var economy: Economy = level.get_node("%Economy")
			economy.earn(1000, Economy.Source.KILL)
			var before: int = economy.get_gold()
			rewards.begin_wave()
			rewards.end_wave()
			ok = economy.get_gold() - before == 40
		"guild":
			await _tower(level, 3, ARCHER)
			mods.add_upgrade(data)
			ok = builder.upgrade_cost(builder.get_slots()[3]) == roundi(ARCHER.upgrade_cost(2) * 0.8)
		"war_tax":
			mods.add_upgrade(data)
			ok = mods.apply_int(GHOUL.gold_reward, [RunModifiers.KILL_GOLD]) == roundi(GHOUL.gold_reward * (1.0 + _percent(data, RunModifiers.KILL_GOLD)))
			ok = ok and _percent(data, RunModifiers.KILL_GOLD) > 0.0 and fortress.health.max_health < 100
		_:
			label += " (no test for this upgrade yet)"
	_check(label, ok)
	level.queue_free()
	await _frames(2)


## An archer shoots at an enemy; a second one stands further along the same line, out of the tower's
## range (so it is never the target itself): the arrow flies on and hits it too.
func _check_pierce(level: Level, data: UpgradeData) -> bool:
	var mods: RunModifiers = level.get_node("%RunModifiers")
	var tower: Tower = await _tower(level, 3, ARCHER)
	mods.add_upgrade(data)
	var front: Enemy = _stationary(level, tower.global_position + Vector2(ARCHER.attack_range - 40.0, 0))
	var back: Enemy = _stationary(level, tower.global_position + Vector2(ARCHER.attack_range + 40.0, 0))
	for enemy: Enemy in [front, back]:
		(enemy.get_node("%HealthComponent") as HealthComponent).setup.call_deferred(1000)
	await _frames(60)
	return _hp(front) < 1000 and _hp(back) < 1000 and tower.get_stats().pierce == 1


## A cannon shell with hellfire leaves burning ground that keeps hurting an enemy standing in it.
func _check_burn(level: Level, data: UpgradeData) -> bool:
	var mods: RunModifiers = level.get_node("%RunModifiers")
	mods.add_upgrade(data)
	var tower: Tower = await _tower(level, 3, CANNON)
	var enemy: Enemy = _stationary(level, tower.global_position + Vector2(120, 0))
	(enemy.get_node("%HealthComponent") as HealthComponent).setup.call_deferred(1000)
	for _i: int in 200:
		await physics_frame
		if _hp(enemy) < 1000:
			break
	var after_blast: int = _hp(enemy)
	var zones: Array[Node] = tower.find_children("*", "BurnZone", true, false)
	tower.deactivate()  # no more shells: only the fire hurts now
	await _frames(60)
	return not zones.is_empty() and after_blast < 1000 and _hp(enemy) < after_blast


## With thorns, an enemy at the walls takes damage over time.
func _check_thorns(level: Level, data: UpgradeData) -> bool:
	var mods: RunModifiers = level.get_node("%RunModifiers")
	var fortress: Fortress = level.get_node("Fortress")
	var near: Enemy = _stationary(level, fortress.global_position + Vector2(0, 75))
	var far: Enemy = _stationary(level, fortress.global_position + Vector2(0, 160))
	(near.get_node("%FortressHitbox") as Area2D).monitorable = false  # keep it from being used up
	await _frames(2)
	mods.add_upgrade(data)
	await _frames(62)
	return _hp(near) < GHOUL.max_health and _hp(far) == GHOUL.max_health and is_equal_approx(fortress.get_thorns_dps(), 12.0)


## A drawback: less of a good stat, or a longer interval (slower firing).
func _is_drawback(m: StatModifier) -> bool:
	if m.flat < 0.0 and m.stat != RunModifiers.HERO_ATTACK_COOLDOWN:
		return true
	if m.percent < 0.0 and m.stat == RunModifiers.HERO_MAX_HEALTH:
		return true
	return m.percent > 0.0 and m.stat == &"tower.fire_interval"


## The upgrade's percent modifier on `stat` (0 if it has none).
func _percent(data: UpgradeData, stat: StringName) -> float:
	var total: float = 0.0
	for modifier: StatModifier in data.modifiers:
		if modifier.stat == stat:
			total += modifier.percent
	return total


func _tower(level: Level, slot_index: int, data: TowerData) -> Tower:
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	(level.get_node("%Economy") as Economy).earn(data.cost, Economy.Source.REFUND)
	builder.build(builder.get_slots()[slot_index], data)
	await _frames(int(data.build_time * 60.0) + 2)
	return builder.get_slots()[slot_index].tower


func _stationary(level: Level, at: Vector2) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = GHOUL
	enemy.position = at
	level.add_child(enemy)
	(enemy.get_node("%AttackRange") as Area2D).monitoring = false
	return enemy


## Untyped: the enemy may already be freed (killed).
func _hp(enemy: Variant) -> int:
	if not is_instance_valid(enemy):
		return 0
	return ((enemy as Enemy).get_node("%HealthComponent") as HealthComponent).current_health


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
