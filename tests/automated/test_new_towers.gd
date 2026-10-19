extends SceneTree
## Automated check for the M5 towers: the Brazier lobs fire globs that leave burning ground (no
## direct hit, the fire does the damage), only at enemies in its short range; the Bone Ballista's bolt
## flies straight along the ground line and hits up to 1 + pierce enemies on it; both have 2 upgrade
## tiers, are in the build catalog and describe their specials in the build menu.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const BRAZIER: TowerData = preload("res://data/towers/brazier.tres")
const BALLISTA: TowerData = preload("res://data/towers/ballista.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const SLOT: int = 3

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_brazier()
	await _test_ballista()
	await _test_menu()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_data() -> void:
	_check("Brazier: short range, fire globs (not homing) that burn, 2 upgrade tiers",
		BRAZIER.attack_range < 150.0 and not BRAZIER.homing and BRAZIER.burn_dps > 0.0 and BRAZIER.max_level() == 3
		and BRAZIER.stats_for(3).burn_dps > BRAZIER.stats_for(1).burn_dps)
	_check("Ballista: long range, slow, piercing line shots, 2 upgrade tiers",
		BALLISTA.attack_range >= 280.0 and BALLISTA.fire_interval >= 2.0 and BALLISTA.line_shot and BALLISTA.pierce > 0
		and BALLISTA.max_level() == 3 and BALLISTA.stats_for(3).pierce > BALLISTA.stats_for(1).pierce)
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var catalog: Array[TowerData] = (level.get_node("%TowerBuilder") as TowerBuilder).catalog
	_check("both are in the build catalog (5 towers)", catalog.has(BRAZIER) and catalog.has(BALLISTA) and catalog.size() == 5)
	level.free()


func _test_brazier() -> void:
	var level: Level = _make_level()
	await _frames(2)
	var tower: Tower = await _tower(level, BRAZIER)
	var target: Enemy = _stationary(level, tower.global_position + Vector2(90, 0))
	var outside: Enemy = _stationary(level, tower.global_position + Vector2(0, BRAZIER.attack_range + 30.0))
	for enemy: Enemy in [target, outside]:
		(enemy.get_node("%HealthComponent") as HealthComponent).setup.call_deferred(1000)
	var zone_seen: Array[bool] = [false]
	for _i: int in 150:
		await physics_frame
		zone_seen[0] = zone_seen[0] or not tower.find_children("*", "BurnZone", true, false).is_empty()
	_check("a fire glob lands and leaves burning ground", zone_seen[0])
	_check("the fire hurts the enemy standing in it (HP %d)" % _hp(target), _hp(target) < 1000)
	_check("an enemy outside the short range is left alone", _hp(outside) == 1000)
	level.queue_free()
	await _frames(2)


func _test_ballista() -> void:
	var level: Level = _make_level()
	await _frames(2)
	var tower: Tower = await _tower(level, BALLISTA)
	var line: Array[Enemy] = []
	for d: float in [100.0, 150.0, 200.0, 250.0, 290.0]:
		var enemy: Enemy = _stationary(level, tower.global_position + Vector2(d, 0))
		(enemy.get_node("%HealthComponent") as HealthComponent).setup.call_deferred(1000)
		line.append(enemy)
	var bolt: Projectile = null
	for _i: int in 200:
		await physics_frame
		for child: Node in tower.get_children():
			if child is Projectile:
				bolt = child
		if bolt != null:
			break
	_check("the ballista looses a bolt that flies level (a line shot)", bolt != null and (bolt.get_node("%Sprite") as Node2D).position.y < 0.0)
	await _frames(60)
	var hit: int = line.filter(func(e: Enemy) -> bool: return _hp(e) < 1000).size()
	_check("one bolt hits 1 + pierce = %d enemies in a line (hit %d of 5)" % [BALLISTA.pierce + 1, hit], hit == BALLISTA.pierce + 1)
	_check("...each for the bolt's damage", line.slice(0, hit).all(func(e: Enemy) -> bool: return _hp(e) == 1000 - BALLISTA.damage))
	level.queue_free()
	await _frames(2)


func _test_menu() -> void:
	var level: Level = _make_level()
	await _frames(2)
	var tower: Tower = await _tower(level, BRAZIER)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	(level.get_node("%Economy") as Economy).earn(1000, Economy.Source.KILL)
	var menu: Node = level.get_node("BuildMenu")
	menu.call("open", builder.get_slots()[SLOT])
	await _frames(2)
	var stats: String = (menu.get_node("%InfoStats") as Label).text
	var next: String = (menu.get_node("%UpgradeInfo") as Label).text
	_check("the brazier's stats name its fire (%s)" % stats.replace("\n", " / "), stats.contains("Burns") and not stats.contains("Damage 0"))
	_check("...and its upgrade what the fire gains (%s)" % next, next.contains("Burn"))
	builder.upgrade(builder.get_slots()[SLOT])
	builder.upgrade(builder.get_slots()[SLOT])
	_check("upgraded to level 3: stronger fire (%.0f/s)" % tower.get_stats().burn_dps, tower.get_level() == 3 and is_equal_approx(tower.get_stats().burn_dps, BRAZIER.stats_for(3).burn_dps))
	var cards: Node = menu.get_node("%Options")
	menu.call("close")
	menu.call("open", builder.get_slots()[0])
	await _frames(2)
	_check("the build menu lays the 5 tower cards out in rows of 3", cards is GridContainer and (cards as GridContainer).columns == 3
		and cards.get_children().filter(func(n: Node) -> bool: return not n.is_queued_for_deletion()).size() == 5)
	level.queue_free()
	await _frames(2)


func _make_level() -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	(level.get_node("Hero") as Node2D).position = Vector2(380, 380)
	root.add_child(level)
	return level


func _tower(level: Level, data: TowerData) -> Tower:
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	(level.get_node("%Economy") as Economy).earn(data.cost, Economy.Source.REFUND)
	builder.build(builder.get_slots()[SLOT], data)
	await _frames(int(data.build_time * 60.0) + 2)
	return builder.get_slots()[SLOT].tower


func _stationary(level: Level, at: Vector2) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = GHOUL
	enemy.position = at
	level.add_child(enemy)
	(enemy.get_node("%AttackRange") as Area2D).monitoring = false
	return enemy


## Untyped: the enemy may already be freed.
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
