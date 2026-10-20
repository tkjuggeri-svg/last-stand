extends SceneTree
## Automated check for what each tower evolution does (test_tower_evolutions checks the system):
## Sniper Nest aims at the toughest; Volley Tower rains on the thickest crowd; Siege Mortar reaches far
## but not close; Grapeshot Battery hits a cone; Glacier Spire freezes every few volleys (a boss is only
## slowed); Shatter Shrine makes slowed enemies in reach take +25%; Pyre of Souls makes deaths in its
## fire burst; Beacon Flame speeds up towers in reach (never stacking, shown by an ember); Harpoon drags
## its first enemy back along the lane (a boss barely); Repeater's bolts pass through 2 more.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const BURN_ZONE_SCENE: PackedScene = preload("res://entities/towers/burn_zone.tscn")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const CANNON: TowerData = preload("res://data/towers/cannon.tres")
const FROST: TowerData = preload("res://data/towers/frost.tres")
const BRAZIER: TowerData = preload("res://data/towers/brazier.tres")
const BALLISTA: TowerData = preload("res://data/towers/ballista.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const COLOSSUS: EnemyData = preload("res://data/enemies/colossus.tres")
const PIERCING: UpgradeData = preload("res://data/upgrades/piercing.tres")
const HELLFIRE: UpgradeData = preload("res://data/upgrades/hellfire.tres")
## Slots (level BuildSlots order): 3 at (-380, -90); 2 is 175 px from it, 4 is 240 px, 8 is 253 px.
const SLOT: int = 3

var _failures: int = 0


func _initialize() -> void:
	await _test_sniper()
	await _test_volley()
	await _test_mortar()
	await _test_grapeshot()
	await _test_glacier()
	await _test_shatter()
	await _test_pyre()
	await _test_beacon()
	await _test_harpoon()
	await _test_repeater()
	await _test_cards()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_sniper() -> void:
	var level: Level = await _level()
	var tower: Tower = await _evolved(level, ARCHER, 0)
	var weak: Enemy = _stationary(level, tower.global_position + Vector2(120, 0), 60)
	var tough: Enemy = _stationary(level, tower.global_position + Vector2(380, 0), 1000)
	await _until(func() -> bool: return _hp(tough) < 1000 or _hp(weak) < 60, 60 * 4)
	_check("Sniper Nest: its first shot goes to the toughest enemy, far off (HP %d / %d)" % [_hp(tough), _hp(weak)],
		_hp(tough) == 1000 - tower.get_stats().damage and _hp(weak) == 60)
	await _free(level)


func _test_volley() -> void:
	var level: Level = await _level()
	var tower: Tower = await _evolved(level, ARCHER, 1)
	var crowd: Array[Enemy] = []
	for offset: Vector2 in [Vector2(150, 0), Vector2(160, 20), Vector2(140, -20)]:
		crowd.append(_stationary(level, tower.global_position + offset, 1000))
	var alone: Enemy = _stationary(level, tower.global_position + Vector2(-120, 60), 1000)
	await _until(func() -> bool: return not tower.find_children("*", "ArrowRain", true, false).is_empty(), 60 * 4)
	var rain: Array = tower.find_children("*", "ArrowRain", true, false)  # untyped: it frees itself
	_check("Volley Tower: the rain falls on the crowd, not the lone enemy", (rain[0] as Node2D).global_position.distance_to(crowd[0].global_position) < 60.0)
	var strikes: int = tower.get_evolution().rain_strikes
	await _until(func() -> bool: return not is_instance_valid(rain[0]), 60 * 3)
	var expected: int = 1000 - strikes * tower.get_stats().damage
	_check("...%d showers hit everyone in the circle (HP %s), the lone one is untouched" % [strikes, str(crowd.map(_hp))],
		crowd.all(func(e: Enemy) -> bool: return _hp(e) == expected) and _hp(alone) == 1000)
	await _free(level)


func _test_mortar() -> void:
	var level: Level = await _level()
	var tower: Tower = await _evolved(level, CANNON, 0)
	var close: Enemy = _stationary(level, tower.global_position + Vector2(0, 150), 1000)
	var far: Enemy = _stationary(level, tower.global_position + Vector2(900, 100), 1000)
	_check("Siege Mortar: an enemy inside the dead zone is out of reach, one 900 px off is not",
		not tower.is_in_range(close.global_position) and tower.is_in_range(far.global_position))
	await _until(func() -> bool: return _hp(far) < 1000, 60 * 8)
	_check("...the far one is shelled (HP %d), the close one never (HP %d)" % [_hp(far), _hp(close)], _hp(far) < 1000 and _hp(close) == 1000)
	await _free(level)


func _test_grapeshot() -> void:
	var level: Level = await _level()
	var tower: Tower = await _evolved(level, CANNON, 1)
	var front: Enemy = _stationary(level, tower.global_position + Vector2(100, 0), 1000)
	var side: Enemy = _stationary(level, tower.global_position + Vector2(95, 35), 1000)
	await _until(func() -> bool: return tower.get_target() == front or tower.get_target() == side, 60)
	var off: Enemy = _stationary(level, tower.global_position + Vector2(0, -110), 1000)  # 90 degrees off the aim
	var out: Enemy = _stationary(level, tower.global_position + Vector2(200, 0), 1000)  # beyond the 150 px range
	await _until(func() -> bool: return _hp(front) < 1000, 60 * 2)
	await _frames(2)
	var damage: int = tower.get_stats().damage
	_check("Grapeshot Battery: one blast hits everyone in the cone (HP %d, %d)" % [_hp(front), _hp(side)],
		(1000 - _hp(front)) % damage == 0 and _hp(front) < 1000 and _hp(side) == _hp(front))
	_check("...but nobody beside it (HP %d) or out of its short range (HP %d)" % [_hp(off), _hp(out)], _hp(off) == 1000 and _hp(out) == 1000)
	await _free(level)


func _test_glacier() -> void:
	var level: Level = await _level()
	var tower: Tower = await _evolved(level, FROST, 0)
	var every: int = tower.get_evolution().freeze_every
	var target: Enemy = _stationary(level, tower.global_position + Vector2(120, 0), 5000)
	var boss: Enemy = _stationary(level, tower.global_position + Vector2(130, 20), 5000, COLOSSUS)  # inside the frost nova
	# One volley damages exactly one of them (its frost nova only chills the other), so hits = volleys.
	var hits: Array[int] = [0]
	var frozen_at: Array[int] = [-1]
	for enemy: Enemy in [target, boss]:
		enemy.get_health().health_changed.connect(func(_c: int, _m: int) -> void: hits[0] += 1)
	for _i: int in 60 * 6:
		await physics_frame
		if target.get_status().is_frozen() and frozen_at[0] < 0:
			frozen_at[0] = hits[0]
	_check("Glacier Spire: its %dth volley freezes (frozen after volley %d)" % [every, frozen_at[0]], frozen_at[0] == every)
	_check("...a boss caught in it is only slowed", boss.is_slowed() and not boss.get_status().is_frozen())
	await _free(level)
	# A frozen enemy on its lane stands still, then walks on.
	level = await _level()
	var walker: Enemy = _on_lane(level, 300.0, GHOUL)
	await _frames(5)
	walker.get_status().freeze(1.0)
	await _frames(1)
	var at: Vector2 = walker.global_position
	await _frames(40)
	_check("a frozen enemy doesn't move, and shows the ice block", walker.global_position.distance_to(at) < 0.5 and (walker.get_node("%FrozenMark") as CanvasItem).visible)
	await _frames(40)
	_check("...and walks on when it thaws", walker.global_position.distance_to(at) > 5.0 and not (walker.get_node("%FrozenMark") as CanvasItem).visible)
	await _free(level)


func _test_shatter() -> void:
	var level: Level = await _level()
	var tower: Tower = await _evolved(level, FROST, 1)
	var slowed: Enemy = _stationary(level, tower.global_position + Vector2(120, 0), 5000)
	var outside: Enemy = _stationary(level, tower.global_position + Vector2(0, tower.get_attack_range() + 60.0), 5000)
	outside.apply_slow(0.5, 30.0)  # slowed, but out of the shrine's reach
	await _until(func() -> bool: return slowed.get_status().is_vulnerable(), 60 * 3)
	var hp: int = _hp(slowed)
	slowed.get_health().take_damage(100)
	var bonus: float = tower.get_evolution().shatter_bonus
	_check("Shatter Shrine: a slowed enemy in reach takes +%d%% (100 -> %d)" % [roundi(bonus * 100.0), hp - _hp(slowed)], hp - _hp(slowed) == roundi(100 * (1.0 + bonus)))
	_check("...and shows the cracked rune over its head", (slowed.get_node("%ShatterMark") as CanvasItem).visible)
	var out_hp: int = _hp(outside)
	outside.get_health().take_damage(100)
	_check("...a slowed enemy out of reach takes normal damage", out_hp - _hp(outside) == 100 and not outside.get_status().is_vulnerable())
	await _free(level)


func _test_pyre() -> void:
	var level: Level = await _level()
	var tower: Tower = await _evolved(level, BRAZIER, 0)
	_stationary(level, tower.global_position + Vector2(90, 0), 1000)
	await _until(func() -> bool: return not tower.find_children("*", "BurnZone", true, false).is_empty(), 60 * 3)
	var zone: BurnZone = tower.find_children("*", "BurnZone", true, false)[0]
	_check("Pyre of Souls: its fire is soul fire", zone.is_soul_fire())
	await _free(level)
	# A death on soul fire: the burst hits a neighbour outside the fire and leaves plain fire behind.
	level = await _level()
	var soul: BurnZone = BURN_ZONE_SCENE.instantiate()
	soul.setup(4.0, 50.0, 3.0)
	soul.set_death_burst(30, 60.0)
	soul.position = Vector2(-380, 300)
	level.add_child(soul)
	var dying: Array = [_stationary(level, Vector2(-380, 300), 1)]  # untyped: it dies
	var neighbour: Enemy = _stationary(level, Vector2(-310, 300), 1000)
	await _until(func() -> bool: return not is_instance_valid(dying[0]), 60)
	await _frames(4)
	var zones: Array = level.find_children("*", "BurnZone", true, false).filter(func(z: Node) -> bool: return not z.is_queued_for_deletion())
	_check("an enemy dying in it bursts: the neighbour takes 30 (HP %d)" % _hp(neighbour), _hp(neighbour) == 1000 - 30)
	_check("...and the ground where it fell burns (plain fire, no chain): %d zones" % zones.size(),
		zones.size() == 2 and zones.filter(func(z: BurnZone) -> bool: return not z.is_soul_fire()).size() == 1)
	await _free(level)


func _test_beacon() -> void:
	var level: Level = await _level()
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var near: Tower = await _built(level, ARCHER, 2)
	var far: Tower = await _built(level, ARCHER, 8)
	var interval: float = near.get_stats().fire_interval
	var beacon: Tower = await _evolved(level, BRAZIER, 1)
	var boost: float = beacon.get_evolution().boost_fire_rate
	_check("Beacon Flame: a tower in reach fires %d%% faster (%.3f s -> %.3f s)" % [roundi(boost * 100.0), interval, near.get_stats().fire_interval],
		is_equal_approx(near.get_stats().fire_interval, interval / (1.0 + boost)))
	_check("...shown by an ember over it; a tower out of reach is unchanged", (near.get_node("%BoostMark") as CanvasItem).visible
		and is_equal_approx(far.get_stats().fire_interval, interval) and not (far.get_node("%BoostMark") as CanvasItem).visible)
	var second: Tower = await _evolved(level, BRAZIER, 1, 4)
	_check("...a second beacon in reach doesn't stack", is_equal_approx(near.get_stats().fire_interval, interval / (1.0 + boost)) and second.is_evolved())
	builder.sell(builder.get_slots()[SLOT])
	builder.sell(builder.get_slots()[4])
	await _frames(2)
	_check("...and selling the beacons takes the boost away", is_equal_approx(near.get_stats().fire_interval, interval) and not (near.get_node("%BoostMark") as CanvasItem).visible)
	await _free(level)


func _test_harpoon() -> void:
	for data: EnemyData in [GHOUL, COLOSSUS]:
		var level: Level = await _level()
		var tower: Tower = await _evolved(level, BALLISTA, 0)
		var lane: Path2D = level.get_node("Lane")
		var offset: float = _lane_offset_near(lane, tower.global_position, tower.get_attack_range() - 80.0)
		var enemy: Enemy = _on_lane(level, offset, data)
		enemy.get_health().setup(10000)
		await _until(func() -> bool: return enemy.get_status().is_dragged(), 60 * 5)
		var before: float = enemy.get_lane_progress()
		await _until(func() -> bool: return not enemy.get_status().is_dragged(), 60 * 2)
		var pulled: float = before - enemy.get_lane_progress()
		var drag: float = tower.get_evolution().drag_distance * (tower.get_evolution().boss_drag_factor if data.is_boss else 1.0)
		_check("Harpoon: %s is dragged back %.0f px along its lane (%.0f expected)" % [data.display_name, pulled, drag], absf(pulled - drag) < 12.0)
		await _free(level)


func _test_repeater() -> void:
	var level: Level = await _level()
	var tower: Tower = await _evolved(level, BALLISTA, 1)
	var line: Array[Enemy] = []
	for d: float in [100.0, 150.0, 200.0, 250.0]:
		line.append(_stationary(level, tower.global_position + Vector2(d, 0), 1000))
	await _until(func() -> bool: return _hp(line[0]) < 1000, 60 * 2)
	await _frames(12)
	var damage: int = tower.get_stats().damage
	var hit: int = line.filter(func(e: Enemy) -> bool: return _hp(e) == 1000 - damage).size()
	_check("Repeater: a bolt passes through 2 more enemies (hit %d of 4)" % hit, hit == 3 and _hp(line[3]) == 1000)
	_check("...and fires fast (every %.2f s)" % tower.get_stats().fire_interval, tower.get_stats().fire_interval < BALLISTA.stats_for(3).fire_interval * 0.5)
	await _free(level)


## The run upgrades that would overlap an evolution still count: Piercing Arrows gives a Volley Tower
## one more shower, Hellfire Shells sets a Grapeshot blast's far end on fire.
func _test_cards() -> void:
	var level: Level = await _level()
	var volley: Tower = await _evolved(level, ARCHER, 1)
	(level.get_node("%RunModifiers") as RunModifiers).add_upgrade(PIERCING)
	var grape: Tower = await _evolved(level, CANNON, 1, 8)
	(level.get_node("%RunModifiers") as RunModifiers).add_upgrade(HELLFIRE)
	_stationary(level, volley.global_position + Vector2(150, 0), 5000)
	_stationary(level, grape.global_position + Vector2(100, 0), 5000)
	await _until(func() -> bool: return not volley.find_children("*", "ArrowRain", true, false).is_empty(), 60 * 4)
	var rain: ArrowRain = volley.find_children("*", "ArrowRain", true, false)[0]
	_check("Piercing Arrows: the Volley Tower rains %d showers (%d without)" % [rain.get_strikes_left(), volley.get_evolution().rain_strikes],
		rain.get_strikes_left() == volley.get_evolution().rain_strikes + 1)
	await _until(func() -> bool: return not grape.find_children("*", "BurnZone", true, false).is_empty(), 60 * 3)
	_check("Hellfire Shells: a Grapeshot blast leaves burning ground", not grape.find_children("*", "BurnZone", true, false).is_empty())
	await _free(level)


# ---------------------------------------------------------------- helpers

func _level() -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	WaveFixtures.no_upgrades(level)
	(level.get_node("Hero") as Node2D).position = Vector2(380, 380)
	root.add_child(level)
	await _frames(2)
	return level


func _built(level: Level, data: TowerData, slot_index: int) -> Tower:
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	(level.get_node("%Economy") as Economy).earn(data.cost, Economy.Source.REFUND)
	builder.build(builder.get_slots()[slot_index], data)
	await _frames(int(data.build_time * 60.0) + 2)
	return builder.get_slots()[slot_index].tower


## A tower at level 3 evolved into its `index`-th branch.
func _evolved(level: Level, data: TowerData, index: int, slot_index: int = SLOT) -> Tower:
	var tower: Tower = await _built(level, data, slot_index)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var slot: BuildSlot = builder.get_slots()[slot_index]
	(level.get_node("%Economy") as Economy).earn(10000, Economy.Source.REFUND)
	builder.upgrade(slot)
	builder.upgrade(slot)
	builder.evolve(slot, index)
	return tower


func _stationary(level: Level, at: Vector2, health: int, data: EnemyData = GHOUL) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = data
	enemy.position = at
	level.add_child(enemy)
	(enemy.get_node("%AttackRange") as Area2D).monitoring = false
	enemy.get_health().setup(health)
	return enemy


## An enemy walking the level's first lane from `offset`.
func _on_lane(level: Level, offset: float, data: EnemyData) -> Enemy:
	var lane: Path2D = level.get_node("Lane")
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = data
	enemy.lane = lane
	enemy.position = lane.to_global(lane.curve.sample_baked(offset))
	level.add_child(enemy)
	(enemy.get_node("%AttackRange") as Area2D).monitoring = false
	return enemy


## The first lane offset (after 200 px, so a drag has room) whose point is within `reach` of `point`.
func _lane_offset_near(lane: Path2D, point: Vector2, reach: float) -> float:
	var offset: float = 200.0
	while offset < lane.curve.get_baked_length():
		if lane.to_global(lane.curve.sample_baked(offset)).distance_to(point) <= reach:
			return offset
		offset += 10.0
	return 200.0


## Untyped: the enemy may already be freed.
func _hp(enemy: Variant) -> int:
	if not is_instance_valid(enemy):
		return 0
	return (enemy as Enemy).get_health().current_health


func _until(condition: Callable, max_frames: int) -> void:
	for _i: int in max_frames:
		if condition.call():
			return
		await physics_frame


func _free(level: Node) -> void:
	level.queue_free()
	await _frames(2)


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
