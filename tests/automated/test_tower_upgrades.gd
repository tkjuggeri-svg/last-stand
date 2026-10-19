extends SceneTree
## Automated check for tower upgrades: 2 tiers per tower in the data, upgrading costs that tier's
## price and changes the stats and the look, it is refused without the gold / at the top level /
## during construction, selling refunds 50% of everything spent (build + upgrades) exactly once, the
## level-3 specials work (Archer: 2 targets per volley, Cannon: bigger blast with heavy shells,
## Frost: slows every enemy near the impact), and the build menu's Upgrade flow.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const CANNON: TowerData = preload("res://data/towers/cannon.tres")
const FROST: TowerData = preload("res://data/towers/frost.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const SLOT: int = 3
const HERO_AWAY: Vector2 = Vector2(380, 380)

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_upgrade_rules_and_refund()
	await _test_archer_volley()
	await _test_frost_nova()
	await _test_heavy_shells()
	await _test_menu()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_data() -> void:
	var ok: bool = true
	for data: TowerData in [ARCHER, CANNON, FROST]:
		ok = ok and data.max_level() == 3 and data.upgrade_cost(2) > 0 and data.upgrade_cost(3) > data.upgrade_cost(2)
		ok = ok and data.stats_for(3).damage > data.stats_for(2).damage and data.stats_for(2).damage > data.stats_for(1).damage
	_check("every tower has 2 upgrade tiers, pricier and stronger each level", ok)
	_check("level-3 specials: Archer 2 targets, Cannon bigger blast with heavy shells, Frost area slow",
		ARCHER.stats_for(3).targets == 2 and CANNON.stats_for(3).large_blast and CANNON.stats_for(3).splash_radius > CANNON.splash_radius
		and FROST.stats_for(3).slow_area > 0.0)


func _test_upgrade_rules_and_refund() -> void:
	var level: Level = _make_level()
	await _frames(2)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var economy: Economy = level.get_node("%Economy")
	var slot: BuildSlot = builder.get_slots()[SLOT]
	var reasons: Array[String] = []
	builder.upgrade_failed.connect(func(_s: BuildSlot, reason: String) -> void: reasons.append(reason))
	economy.earn(1000, Economy.Source.KILL)
	builder.build(slot, ARCHER)
	var tower: Tower = slot.tower
	_check("upgrading is refused while the tower is under construction", not builder.upgrade(slot) and reasons.back() == TowerBuilder.UNDER_CONSTRUCTION)
	await _frames(int(ARCHER.build_time * 60.0) + 2)
	var gold: int = economy.get_gold()
	var upgraded: Array[int] = []
	builder.tower_upgraded.connect(func(_s: BuildSlot, _t: Tower, lv: int) -> void: upgraded.append(lv))
	_check("an upgrade costs the tier's price and raises the level",
		builder.upgrade(slot) and tower.get_level() == 2 and economy.get_gold() == gold - ARCHER.upgrade_cost(2) and upgraded == [2])
	var radius: float = ((tower.get_node("%RangeShape") as CollisionShape2D).shape as CircleShape2D).radius
	_check("...with the new stats (damage %d, range %.0f)" % [tower.get_stats().damage, radius],
		tower.get_stats() == ARCHER.stats_for(2) and is_equal_approx(radius, ARCHER.stats_for(2).attack_range))
	_check("...and the new look (%s)" % (tower.get_node("%Sprite") as AnimatedSprite2D).animation,
		String((tower.get_node("%Sprite") as AnimatedSprite2D).animation).ends_with("_2"))
	builder.upgrade(slot)
	_check("level 3 reached", tower.get_level() == 3 and tower.is_max_level())
	_check("the top level can't be upgraded", not builder.upgrade(slot) and reasons.back() == TowerBuilder.MAX_LEVEL and builder.upgrade_cost(slot) == -1)
	var spent: int = ARCHER.cost + ARCHER.upgrade_cost(2) + ARCHER.upgrade_cost(3)
	gold = economy.get_gold()
	var refund: int = builder.sell(slot) + builder.sell(slot)
	_check("selling refunds 50%% of everything spent, once (%d of %d)" % [refund, spent],
		refund == floori(spent * 0.5) and economy.get_gold() == gold + refund)
	# Not enough gold.
	builder.build(slot, CANNON)
	await _frames(int(CANNON.build_time * 60.0) + 2)
	var poor: int = economy.get_gold()
	economy.try_spend(poor)  # empty the purse
	_check("without enough gold the upgrade is refused and nothing is taken",
		not builder.upgrade(slot) and reasons.back() == TowerBuilder.NOT_ENOUGH_GOLD and slot.tower.get_level() == 1 and economy.get_gold() == 0)
	level.queue_free()
	await _frames(2)


func _test_archer_volley() -> void:
	var level: Level = _make_level()
	await _frames(2)
	var tower: Tower = await _built_at_level(level, ARCHER, 3)
	var a: Enemy = _stationary(level, tower.global_position + Vector2(90, 0))
	var b: Enemy = _stationary(level, tower.global_position + Vector2(-90, 20))
	var most_shots: int = 0
	for _i: int in 90:
		await physics_frame
		most_shots = maxi(most_shots, tower.get_children().filter(func(c: Node) -> bool: return c is Projectile).size())
	_check("a level-3 archer looses 2 arrows per volley (%d in the air)" % most_shots, most_shots >= 2)
	_check("...each at a different enemy: both are hit", _hp(a) < GHOUL.max_health and _hp(b) < GHOUL.max_health)
	level.queue_free()
	await _frames(2)


func _test_frost_nova() -> void:
	var level: Level = _make_level()
	await _frames(2)
	var tower: Tower = await _built_at_level(level, FROST, 3)
	var target: Enemy = _stationary(level, tower.global_position + Vector2(100, 0))
	# Close to the target (whichever of the two the tower shoots, the other is near the impact), and one
	# outside the tower's range and far from the impact: only a nova could slow it, and it must not.
	var near: Enemy = _stationary(level, target.global_position + Vector2(FROST.stats_for(3).slow_area - 16.0, 10))
	var far: Enemy = _stationary(level, tower.global_position + Vector2(0, FROST.stats_for(3).attack_range + 30.0))
	await _until(func() -> bool: return target.is_slowed() or near.is_slowed(), 120)
	await _frames(1)
	_check("a level-3 frost bolt slows its target to %d%%" % roundi(FROST.stats_for(3).slow_factor * 100.0),
		target.is_slowed() and is_equal_approx(target.get_move_speed(), GHOUL.move_speed * FROST.stats_for(3).slow_factor))
	_check("...and every enemy near the impact (frost nova)", near.is_slowed())
	_check("...but not one further away", not far.is_slowed())
	level.queue_free()
	await _frames(2)


func _test_heavy_shells() -> void:
	var level: Level = _make_level()
	await _frames(2)
	var tower: Tower = await _built_at_level(level, CANNON, 3)
	var target: Enemy = _stationary(level, tower.global_position + Vector2(110, 0))
	var edge: Enemy = _stationary(level, target.global_position + Vector2(0, CANNON.stats_for(3).splash_radius - 6.0))
	for enemy: Enemy in [target, edge]:
		(enemy.get_node("%HealthComponent") as HealthComponent).setup.call_deferred(1000)
	var shell: Projectile = null
	for _i: int in 200:
		await physics_frame
		for child: Node in tower.get_children():
			if child is Projectile:
				shell = child
		if shell != null:
			break
	_check("a level-3 cannon fires heavy shells", shell != null and (shell.get_node("%Sprite") as AnimatedSprite2D).animation == &"cannonball_heavy")
	await _until(func() -> bool: return _hp(target) < 1000, 120)
	await _frames(1)
	var blasts: Array[Node] = tower.find_children("*", "Explosion", true, false)
	_check("...with the big blast", not blasts.is_empty() and ((blasts[0] as Node).get_node("%Sprite") as AnimatedSprite2D).animation == &"explosion_large")
	_check("...that reaches %.0f px (an enemy beyond level 1's %.0f px is hit for %d)" % [CANNON.stats_for(3).splash_radius, CANNON.splash_radius, CANNON.stats_for(3).damage],
		_hp(edge) == 1000 - CANNON.stats_for(3).damage and _hp(target) == 1000 - CANNON.stats_for(3).damage)
	level.queue_free()
	await _frames(2)


func _test_menu() -> void:
	var level: Level = _make_level()
	await _frames(2)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var economy: Economy = level.get_node("%Economy")
	var slot: BuildSlot = builder.get_slots()[SLOT]
	var tower: Tower = await _built_at_level(level, ARCHER, 1)
	var menu: Node = level.get_node("BuildMenu")
	menu.call("open", slot)
	await _frames(2)
	var button: Button = menu.get_node("%UpgradeButton")
	var info: Label = menu.get_node("%UpgradeInfo")
	_check("the tower menu offers the next level with its price (%s)" % button.text,
		button.visible and not button.disabled and button.text == "Upgrade   -%d gold" % ARCHER.upgrade_cost(2))
	_check("...and says what changes (%s)" % info.text, info.text.begins_with("Level 2: Damage 10 → ") and info.text.contains("Range"))
	var gold: int = economy.get_gold()
	button.pressed.emit()
	await _frames(1)
	_check("Upgrade in the menu upgrades the tower", tower.get_level() == 2 and economy.get_gold() == gold - ARCHER.upgrade_cost(2))
	_check("...the title shows the level and Sell the bigger refund (%s)" % (menu.get_node("%SellButton") as Button).text,
		(menu.get_node("%Title") as Label).text.ends_with("Level 2")
		and (menu.get_node("%SellButton") as Button).text == "Sell   +%d gold" % builder.refund_for_tower(tower))
	button.pressed.emit()
	await _frames(1)
	_check("at the top level the button says so and is disabled", button.disabled and button.text == "Max level")
	level.queue_free()
	await _frames(2)


func _make_level() -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	(level.get_node("Hero") as Node2D).position = HERO_AWAY
	root.add_child(level)
	return level


## A tower at slot SLOT, finished and upgraded to `target_level` (paid for).
func _built_at_level(level: Level, data: TowerData, target_level: int) -> Tower:
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	(level.get_node("%Economy") as Economy).earn(1000, Economy.Source.KILL)
	var slot: BuildSlot = builder.get_slots()[SLOT]
	builder.build(slot, data)
	await _frames(int(data.build_time * 60.0) + 2)
	for _i: int in target_level - 1:
		builder.upgrade(slot)
	return slot.tower


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
