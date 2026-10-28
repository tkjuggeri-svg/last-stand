extends SceneTree
## Automated check for the Necromancer's towers (M9 stage 3): the Bone Pit raises skeletons between itself
## and the enemy up to its cap (Charnel Gate's knights, Plague Pit's bombers), the Soul Siphon's beam
## ramps up on one enemy, ignores shields, burns a second enemy (Wither Beam) and mends the fortress
## per kill (Soul Harvester, 10 a wave), the Ossuary gathers souls from the dead nearby and releases
## them in a blast (Death Knell slows, Bone Storm raises skeletons), the build menu, and the art.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const KNIGHT: HeroData = preload("res://data/heroes/knight.tres")
const NECRO: HeroData = preload("res://data/heroes/necromancer.tres")
const PIT: TowerData = preload("res://data/towers/bone_pit.tres")
const SIPHON: TowerData = preload("res://data/towers/soul_siphon.tres")
const OSSUARY: TowerData = preload("res://data/towers/ossuary.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const SHIELDBEARER: EnemyData = preload("res://data/enemies/shieldbearer.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_pit()
	await _test_beam()
	await _test_harvester_and_wither()
	await _test_ossuary()
	await _test_catalog()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _level() -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	var hero: Hero = level.get_node("Hero")
	hero.data = NECRO
	hero.position = Vector2(380, 380)
	root.add_child(level)
	level.apply_hero(NECRO, [KNIGHT, NECRO])
	return level


func _enemy(level: Level, data: EnemyData, at: Vector2, health: int = 5000) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = data
	enemy.position = at
	level.add_child(enemy)
	(enemy.get_node("%AttackRange") as Area2D).monitoring = false
	enemy.get_health().max_health = health
	enemy.get_health().current_health = health
	return enemy


func _tower(level: Level, data: TowerData, index: int, tower_level: int = 1) -> Tower:
	(level.get_node("%Economy") as Economy).earn(5000, Economy.Source.KILL)
	var slot: BuildSlot = level.builder.get_slots()[index]
	level.builder.build(slot, data)
	await _frames(int(data.build_time * 60.0) + 2)
	for _i: int in tower_level - 1:
		level.builder.upgrade(slot)
	return slot.tower


func _test_data() -> void:
	_check("Bone Pit 70, Soul Siphon 85, Ossuary 100, each with 2 upgrades and 2 evolutions", PIT.cost == 70 and SIPHON.cost == 85 and OSSUARY.cost == 100
		and [PIT, SIPHON, OSSUARY].all(func(t: TowerData) -> bool: return t.max_level() == 3 and t.evolutions.size() == 2 and t.synergies.size() == 1))
	var ok: bool = true
	for data: TowerData in [PIT, SIPHON, OSSUARY]:
		for anim: String in ["idle", "fire", "build", "sell", "idle_2", "fire_2", "idle_3", "fire_3"]:
			ok = ok and data.frames.has_animation(StringName("%s_%s" % [data.id, anim]))
		for evolution: TowerEvolution in data.evolutions:
			ok = ok and evolution.frames.has_animation(StringName("%s_idle" % evolution.id)) and evolution.frames.has_animation(StringName("%s_fire" % evolution.id))
		ok = ok and TowerIcons.for_level(data, 3) != null and TowerIcons.for_evolution(data, data.evolutions[1]) != null
	_check("every look has its art and an icon", ok)


func _test_pit() -> void:
	var level: Level = _level()
	await _frames(2)
	var tower: Tower = await _tower(level, PIT, 3)
	var enemy: Enemy = _enemy(level, GHOUL, tower.global_position + Vector2(120, 0))
	await _frames(60)
	_check("a Bone Pit raises a skeleton once an enemy is in reach", level.minions.count_for(tower) == 1)
	await _frames(1300)
	_check("...up to its cap of 3 (%d)" % level.minions.count_for(tower), level.minions.count_for(tower) == 3)
	var minion: Minion = level.minions.get_minions()[0]
	_check("they are Pit Skeletons: 50 HP, 6 damage", minion.get_health().max_health == 50 and minion.data.damage == 6)
	var gate: Tower = tower
	level.builder.upgrade(level.builder.get_slots()[3])
	level.builder.upgrade(level.builder.get_slots()[3])
	_check("level 3: 4 at a time, 75 HP skeletons, every 4 s", gate.get_stats().minion_cap == 4 and gate.get_stats().minion.max_health == 75
		and is_equal_approx(gate.get_stats().fire_interval, 4.0))
	_check("Charnel Gate's dead are 150 HP knights, Plague Pit's burst", PIT.evolutions[0].minion.max_health == 150 and PIT.evolutions[1].minion.burst_damage == 50)
	_check("the enemy is still alive (the test's anvil)", enemy.is_alive())
	level.queue_free()
	await process_frame


func _test_beam() -> void:
	var level: Level = _level()
	await _frames(2)
	var tower: Tower = await _tower(level, SIPHON, 3)
	var shield: Enemy = _enemy(level, SHIELDBEARER, tower.global_position + Vector2(0, -120))
	var beam: TowerBeam = tower.get_children().filter(func(n: Node) -> bool: return n is TowerBeam)[0]
	await _frames(30)
	var early: int = 5000 - shield.get_health().current_health
	_check("the beam burns a shielded enemy (%d in 0.5 s)" % early, early > 0)
	_check("the dps starts at 14 (%.1f)" % beam.current_dps(), beam.current_dps() < 16.0)
	await _frames(240)
	_check("...and ramps up to +50%% over 3 s (%.1f dps)" % beam.current_dps(), beam.current_dps() > 20.0 and beam.current_dps() <= 21.1)
	level.queue_free()
	await process_frame


func _test_harvester_and_wither() -> void:
	var level: Level = _level()
	await _frames(2)
	var tower: Tower = await _tower(level, SIPHON, 3, 3)
	tower.evolve(SIPHON.evolutions[1])
	var a: Enemy = _enemy(level, GHOUL, tower.global_position + Vector2(100, 0))
	var b: Enemy = _enemy(level, GHOUL, tower.global_position + Vector2(100, 50))
	await _frames(60)
	_check("Wither Beam burns a second enemy too (%d / %d of 5000)" % [a.get_health().current_health, b.get_health().current_health],
		a.get_health().current_health < 5000 and b.get_health().current_health < 5000)
	level.queue_free()
	await process_frame
	level = _level()
	await _frames(2)
	tower = await _tower(level, SIPHON, 3, 3)
	tower.evolve(SIPHON.evolutions[0])
	level.fortress.health.take_damage(50)
	var before: int = level.fortress.health.current_health
	for i: int in 14:
		var victim: Enemy = _enemy(level, GHOUL, tower.global_position + Vector2(100, 0), 4)
		await _frames(30)
		if is_instance_valid(victim) and victim.is_alive():
			victim.free()
	_check("Soul Harvester: kills mend the fortress, 10 HP a wave at most (+%d)" % (level.fortress.health.current_health - before),
		level.fortress.health.current_health - before == 10)
	level.queue_free()
	await process_frame


func _test_ossuary() -> void:
	var level: Level = _level()
	await _frames(2)
	var tower: Tower = await _tower(level, OSSUARY, 3)
	var foe: Enemy = _enemy(level, GHOUL, tower.global_position + Vector2(150, 0), 5000)
	var full: int = foe.get_health().current_health
	for i: int in 11:
		level.builder.enemy_died(tower.global_position + Vector2(50, 0))
	_check("it gathers a soul per death in its reach (%d of 12)" % tower.get_souls(), tower.get_souls() == 11)
	level.builder.enemy_died(tower.global_position + Vector2(900, 0))
	_check("deaths out of reach give nothing", tower.get_souls() == 11)
	level.builder.enemy_died(tower.global_position + Vector2(50, 0))
	await _frames(10)
	_check("the 12th releases the blast: 80 damage to enemies within 200 px (%d)" % (full - foe.get_health().current_health),
		tower.get_souls() == 0 and full - foe.get_health().current_health == 80)
	_check("level 3: 8 souls, 150 damage", OSSUARY.stats_for(3).souls_needed == 8 and OSSUARY.stats_for(3).damage == 150)
	var knell: Tower = await _tower(level, OSSUARY, 4, 3)
	knell.evolve(OSSUARY.evolutions[1])
	var near: Enemy = _enemy(level, GHOUL, knell.global_position + Vector2(100, 0))
	for i: int in 8:
		level.builder.enemy_died(knell.global_position)
	await _frames(10)
	_check("Death Knell slows what it reaches", near.is_slowed())
	var storm: Tower = await _tower(level, OSSUARY, 5, 3)
	storm.evolve(OSSUARY.evolutions[0])
	for i: int in 8:
		level.builder.enemy_died(storm.global_position)
	await _frames(5)
	_check("Bone Storm raises 3 skeletons (%d)" % level.minions.count_for(storm), level.minions.count_for(storm) == 3)
	level.queue_free()
	await process_frame


func _test_catalog() -> void:
	var level: Level = _level()
	await _frames(2)
	var ids: Array = level.builder.catalog.map(func(t: TowerData) -> String: return String(t.id))
	_check("the Necromancer builds archer, cannon and her three (%s)" % [ids], ids.size() == 5 and ids.has("bone_pit") and ids.has("soul_siphon")
		and ids.has("ossuary") and not ids.has("brazier") and not ids.has("hawk_perch"))
	level.queue_free()
	await process_frame


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
