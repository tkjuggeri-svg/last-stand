extends SceneTree
## Automated check for the combo evolutions (M9 stage 4): each of six towers has a third branch that is
## offered only while the run holds its relic, and each one does what it says: Heart of the Pyre's fire leaps,
## Stillwater freezes everything in reach every 10 s (a boss briefly), Headsman's Bolt kills what it leaves
## under 25%, Sky Tyrant carries off a weak enemy, Legion raises skeletons in pairs, Banner Guard gives
## nearby archers more pierce. A saved combo comes back.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://entities/towers/projectile.tscn")
const KNIGHT: HeroData = preload("res://data/heroes/knight.tres")
const NECRO: HeroData = preload("res://data/heroes/necromancer.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const LICH: EnemyData = preload("res://data/enemies/lich.tres")
const BRAZIER: TowerData = preload("res://data/towers/brazier.tres")
const FROST: TowerData = preload("res://data/towers/frost.tres")
const BALLISTA: TowerData = preload("res://data/towers/ballista.tres")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const HAWK: TowerData = preload("res://data/towers/hawk_perch.tres")
const PIT: TowerData = preload("res://data/towers/bone_pit.tres")
const RELICS: Dictionary = {
	"brazier": "res://data/relics/ember_heart.tres", "frost": "res://data/relics/hourglass.tres",
	"ballista": "res://data/relics/executioners_mark.tres", "archer": "res://data/relics/twin_banners.tres",
	"hawk_perch": "res://data/relics/falcons_hood.tres", "bone_pit": "res://data/relics/grave_crown.tres",
}

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_offers()
	await _test_pyre_and_stillwater()
	await _test_finishers()
	await _test_legion_and_banner()
	await _test_save()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _level() -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	(level.get_node("Hero") as Node2D).position = Vector2(380, 380)
	root.add_child(level)
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


func _tower(level: Level, data: TowerData, index: int) -> Tower:
	(level.get_node("%Economy") as Economy).earn(9000, Economy.Source.KILL)
	var slot: BuildSlot = level.builder.get_slots()[index]
	level.builder.build(slot, data)
	await _frames(int(data.build_time * 60.0) + 2)
	level.builder.upgrade(slot)
	level.builder.upgrade(slot)
	return slot.tower


func _evolve(level: Level, index: int, relic: String) -> Tower:
	level.modifiers.add_upgrade(load(relic) as UpgradeData)
	var slot: BuildSlot = level.builder.get_slots()[index]
	var options: Array[TowerEvolution] = level.builder.evolution_options(slot)
	level.builder.evolve(slot, options.size() - 1)
	return slot.tower


func _test_data() -> void:
	var ok: bool = true
	var ids: Array[StringName] = []
	for data: TowerData in [BRAZIER, FROST, BALLISTA, ARCHER, HAWK, PIT]:
		var combo: TowerEvolution = data.combo
		ok = ok and combo != null and combo.requires_relic != &"" and combo.frames != null and not combo.description.is_empty()
		ok = ok and combo.frames.has_animation(StringName("%s_idle" % combo.id)) and combo.frames.has_animation(StringName("%s_fire" % combo.id))
		ok = ok and data.all_evolutions().size() == 3 and TowerIcons.for_evolution(data, combo) != null
		ok = ok and ResourceLoader.exists(RELICS[String(data.id)])
		ids.append(combo.id)
	_check("six towers have a combo with its relic, art, icon and description (%s)" % [ids], ok and ids.size() == 6)


func _test_offers() -> void:
	var level: Level = _level()
	await _frames(2)
	var tower: Tower = await _tower(level, ARCHER, 3)
	var slot: BuildSlot = level.builder.get_slots()[3]
	_check("without the relic the Archer offers its two branches", level.builder.evolution_options(slot).size() == 2)
	level.modifiers.add_upgrade(load(RELICS["archer"]) as UpgradeData)
	var options: Array[TowerEvolution] = level.builder.evolution_options(slot)
	_check("with Twin Banners a third, Banner Guard, appears (%d)" % options.size(), options.size() == 3 and options[2].id == &"banner_guard")
	_check("...for the same price class (%d gold)" % level.builder.evolution_cost(options[2]), level.builder.evolution_cost(options[2]) > 0)
	_check("it can be taken", level.builder.evolve(slot, 2) and tower.get_evolution().id == &"banner_guard")
	level.queue_free()
	await process_frame


func _test_pyre_and_stillwater() -> void:
	var level: Level = _level()
	await _frames(2)
	var pyre: Tower = await _tower(level, BRAZIER, 3)
	_evolve(level, 3, RELICS["brazier"])
	var a: Enemy = _enemy(level, GHOUL, pyre.global_position + Vector2(100, 0))
	var b: Enemy = _enemy(level, GHOUL, pyre.global_position + Vector2(100, 55))
	var zone: BurnZone = (load("res://entities/towers/burn_zone.tscn") as PackedScene).instantiate()
	zone.setup(40.0, 20.0, 4.0)
	zone.spreads = true
	zone.top_level = true
	zone.position = a.global_position + Vector2(-5, 0)
	level.add_child(zone)
	await _frames(90)
	_check("Heart of the Pyre: the fire leaps to a neighbour outside the burning ground", b.get_status().is_burning())
	level.queue_free()
	await process_frame
	level = _level()
	await _frames(2)
	var still: Tower = await _tower(level, FROST, 3)
	_evolve(level, 3, RELICS["frost"])
	var ghoul: Enemy = _enemy(level, GHOUL, still.global_position + Vector2(100, 0))
	var boss: Enemy = _enemy(level, LICH, still.global_position + Vector2(-100, 0))
	await _frames(605)
	_check("Stillwater: after 10 s a pulse freezes everything in reach, boss included", ghoul.get_status().is_frozen() and boss.get_status().is_frozen())
	await _frames(35)
	_check("...the boss thaws after 0.3 s, the ghoul stays frozen for 1 s", not boss.get_status().is_frozen() and ghoul.get_status().is_frozen())
	level.queue_free()
	await process_frame


func _test_finishers() -> void:
	var level: Level = _level()
	await _frames(2)
	var tower: Tower = await _tower(level, BALLISTA, 3)
	_evolve(level, 3, RELICS["ballista"])
	tower.process_mode = Node.PROCESS_MODE_DISABLED
	var weak: Enemy = _enemy(level, GHOUL, tower.global_position + Vector2(100, 0), 200)
	weak.get_health().take_damage(130)  # 70 of 200 left: 35%, one bolt of 52 leaves 18 (9%)
	var shot: Projectile = PROJECTILE_SCENE.instantiate()
	shot.evolution = tower.get_evolution()
	shot.launch_line(BALLISTA, tower.get_stats(), weak.global_position, tower.global_position, BALLISTA.muzzle_offset)
	level.add_child(shot)
	await _frames(60)
	_check("Headsman's Bolt kills what it leaves under 25%", not is_instance_valid(weak) or not weak.is_alive())
	var boss: Enemy = _enemy(level, LICH, tower.global_position + Vector2(-100, 0), 1000)
	boss.get_health().take_damage(700)  # 300 left; the bolt's 52 would leave 24.8%, under the line
	var shot2: Projectile = PROJECTILE_SCENE.instantiate()
	shot2.evolution = tower.get_evolution()
	shot2.launch_line(BALLISTA, tower.get_stats(), boss.global_position, tower.global_position, BALLISTA.muzzle_offset)
	level.add_child(shot2)
	await _frames(60)
	_check("...but not a boss", is_instance_valid(boss) and boss.is_alive())
	level.queue_free()
	await process_frame
	level = _level()
	await _frames(2)
	var hawk: Tower = await _tower(level, HAWK, 3)
	_evolve(level, 3, RELICS["hawk_perch"])
	hawk.process_mode = Node.PROCESS_MODE_DISABLED
	var small: Enemy = _enemy(level, GHOUL, hawk.global_position + Vector2(100, 0), 60)
	var dive: Projectile = PROJECTILE_SCENE.instantiate()
	dive.evolution = hawk.get_evolution()
	dive.launch(HAWK, hawk.get_stats(), small, small.global_position + Vector2(0, -60), hawk.global_position)
	level.add_child(dive)
	await _frames(60)
	_check("Sky Tyrant: a dive that leaves 30 of 60 HP carries the enemy off", not is_instance_valid(small) or not small.is_alive())
	level.queue_free()
	await process_frame


func _test_legion_and_banner() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	level.get_node("Hero").data = NECRO
	(level.get_node("Hero") as Node2D).position = Vector2(380, 380)
	root.add_child(level)
	level.apply_hero(NECRO, [KNIGHT, NECRO])
	await _frames(2)
	var pit: Tower = await _tower(level, PIT, 3)
	_evolve(level, 3, RELICS["bone_pit"])
	_enemy(level, GHOUL, pit.global_position + Vector2(120, 0))
	await _frames(40)
	_check("Legion raises skeletons in pairs (%d after the first raising)" % level.minions.count_for(pit), level.minions.count_for(pit) == 2)
	level.queue_free()
	await process_frame
	level = _level()
	await _frames(2)
	var slots: Array[BuildSlot] = level.builder.get_slots()
	var pair: Array[int] = [0, 1]
	for i: int in slots.size():
		for j: int in range(i + 1, slots.size()):
			if slots[i].global_position.distance_to(slots[j].global_position) < 200.0:
				pair = [i, j]
	var guard: Tower = await _tower(level, ARCHER, pair[0])
	var friend: Tower = await _tower(level, ARCHER, pair[1])
	var base: int = friend.get_stats().pierce
	_evolve(level, pair[0], RELICS["archer"])
	level.builder.refresh_boosts()
	_check("Banner Guard: an archer in its reach pierces 1 more (%d to %d), the guard itself not by its own aura" % [base, friend.get_stats().pierce],
		friend.get_stats().pierce == base + 1 and guard.get_stats().pierce == guard.get_evolution().pierce)
	level.queue_free()
	await process_frame


func _test_save() -> void:
	var level: Level = _level()
	await _frames(2)
	var slot: BuildSlot = level.builder.get_slots()[3]
	await _tower(level, ARCHER, 3)
	_evolve(level, 3, RELICS["archer"])
	var saved: Dictionary = RunSave.capture(root.get_node("RunState") as RunStateNode, level) if false else {}
	var index: int = ARCHER.all_evolutions().find(slot.tower.get_evolution())
	_check("a combo is saved as the third evolution (index %d)" % index, index == 2)
	level.builder.sell(slot)
	level.builder.restore(slot, ARCHER, 3, index, 100)
	_check("...and restored from that index", slot.tower.get_evolution() != null and slot.tower.get_evolution().id == &"banner_guard" and saved.is_empty())
	level.queue_free()
	await process_frame


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
