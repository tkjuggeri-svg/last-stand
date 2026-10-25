extends SceneTree
## Automated check for the Ashen Keep (M10 stage 1b, chapter 3) and the hazards: its chapter data (tier 3,
## 6 battles, 4 elites, a boss), its enemies (Siege Ram, Black Knight, the Fallen Marshal) and waves (the
## Rams from wave 2, the Knights from wave 8 (M13 follow-up: heavy enemies arrive one kind at a time), the Marshal in wave 15), the level (4 roads, 8 slots, slots
## clear of the roads), Falling Walls (a ring warns, the collapse hurts enemies, hero and minions, and
## silences the nearest tower) and Open Graves (Ghouls climb out in the middle of a road and the wave
## waits for them); neither strikes between waves.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const RUN: RunData = preload("res://data/run/run.tres")
const KEEP: String = "res://levels/ashen_keep.tscn"
const ARENA: String = "res://levels/prototype_arena.tscn"
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_level()
	await _test_falling_walls()
	await _test_open_graves()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_data() -> void:
	var keep: ChapterData = RUN.chapters[2]
	_check("chapter 3 is the Ashen Keep: tier 3, 6 battles, 4 elites, a boss, its text for the road card", keep.id == &"ashen_keep" and keep.tier == 3
		and keep.battles.size() == 6 and keep.elites.size() == 4 and keep.boss != null and not keep.blurb.is_empty() and not keep.mechanic_text.is_empty()
		and keep.level_scene.resource_path == KEEP)
	_check("it is tougher than chapter 2 (x%.1f against x%.1f)" % [keep.fight_health_scale, RUN.chapters[1].fight_health_scale], keep.fight_health_scale > RUN.chapters[1].fight_health_scale)
	var enemies: Array[EnemyData] = []
	for id: String in ["siege_ram", "black_knight", "fallen_marshal"]:
		enemies.append(load("res://data/enemies/%s.tres" % id))
	var ok: bool = true
	for data: EnemyData in enemies:
		ok = ok and data.sprite_frames != null and data.sprite_frames.has_animation(&"walk_side") and data.sprite_frames.has_animation(&"death") and data.death_effect != null
	_check("the three new enemies have their art", ok)
	_check("the Ram hits the fortress hard, the Knight's shield is wide, the Marshal is a charging boss",
		enemies[0].fortress_damage >= 40 and enemies[1].shield_arc > 140.0 and enemies[2].is_boss and enemies[2].ability != null)
	var first: Dictionary = {}
	var marshal_wave: int = 0
	for n: int in range(1, 16):
		var wave: WaveData = load("res://data/waves/chapter_3/wave_%02d.tres" % n)
		for group: SpawnGroup in wave.groups:
			if group.enemy in enemies and not first.has(group.enemy):
				first[group.enemy] = n
			if group.enemy == enemies[2]:
				marshal_wave = n
			_check_quiet(group.lane <= 3)
	_check("the Rams come from wave %d, the Knights from wave %d, the Marshal in wave %d" % [first.get(enemies[0], 0), first.get(enemies[1], 0), marshal_wave],
		first.get(enemies[0], 0) == 2 and first.get(enemies[1], 0) == 8 and marshal_wave == 15 and _failures == 0)
	var boss: EncounterData = keep.boss
	_check("the boss fight is waves 13 to 15", boss.waves.size() == 3 and boss.row == 0 and not boss.strip_bosses)


func _test_level() -> void:
	var level: Level = (load(KEEP) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	_check("four roads and eight slots", level.spawner.lanes.size() == 4 and level.builder.get_slots().size() == 8)
	var clear: bool = true
	for slot: BuildSlot in level.builder.get_slots():
		for lane: Path2D in level.spawner.lanes:
			var near: Vector2 = lane.curve.get_closest_point(lane.to_local(slot.global_position))
			clear = clear and lane.to_global(near).distance_to(slot.global_position) > 40.0
	_check("every slot stands clear of every road", clear)
	_check("the ground is its own (not the Crypt Road's)", level.get_node("%Ground").texture.resource_path.contains("ashen_keep"))
	level.queue_free()
	await process_frame


func _test_falling_walls() -> void:
	var level: Level = (load(KEEP) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	var walls: FallingWalls = level.get_node("FallingWalls")
	var hero: Hero = level.get_node("Hero")
	level.economy.earn(500, Economy.Source.KILL)
	var slot: BuildSlot = level.builder.get_slots()[2]
	level.builder.build(slot, ARCHER)
	await _physics(int(ARCHER.build_time * 60.0) + 2)
	var tower: Tower = slot.tower
	_check("between waves it does not strike", not walls.is_active())
	walls.data = walls.data.duplicate()
	walls.data.first_delay = 0.05
	walls.data.interval_min = 100.0
	walls.data.interval_max = 100.0
	walls.data.warning = 0.5
	level.spawner.waves = [WaveFixtures.make_wave(2, 6.0)]
	level.run_cycle.start_wave()
	await _physics(20)
	_check("in a wave it is active and a ring warns before it strikes", walls.is_active() and walls.get_children().size() + level.get_node("Effects").get_children().size() > 0)
	var markers: Array[Node] = level.get_node("Effects").find_children("*", "TelegraphMarker", false, false)
	_check("one warning ring is up (%d)" % markers.size(), markers.size() == 1)
	# The collapse itself, on the hero and an enemy standing in it.
	var at: Vector2 = tower.global_position + Vector2(40, 0)
	hero.global_position = at
	var enemy: Enemy = (load("res://entities/enemies/enemy.tscn") as PackedScene).instantiate()
	enemy.data = GHOUL
	enemy.position = at + Vector2(10, 0)
	level.add_child(enemy)
	(enemy.get_node("%AttackRange") as Area2D).monitoring = false
	enemy.get_health().max_health = 500
	enemy.get_health().current_health = 500
	var hero_hp: int = hero.health.current_health
	walls.collapse(at)
	await _physics(10)
	_check("the collapse hurt the hero (%d to %d)" % [hero_hp, hero.health.current_health], hero.health.current_health < hero_hp)
	_check("...the enemy (%d of 500)" % enemy.get_health().current_health, enemy.get_health().current_health < 500)
	_check("...and silenced the nearest tower", tower.get_silence().is_silenced())
	level.queue_free()
	await process_frame


func _test_open_graves() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	var graves: OpenGraves = level.get_node("OpenGraves")
	var before: int = level.spawner.get_living_count()
	graves.rise(Vector2(-300, -250), 0)
	await _physics(3)
	_check("between waves nothing climbs out", level.spawner.get_living_count() == before)
	level.spawner.waves = [WaveFixtures.make_wave(2, 6.0)]
	level.run_cycle.start_wave()
	await _physics(5)
	graves.rise(Vector2(-300, -250), 0)
	await _physics(3)
	var count: int = level.spawner.get_living_count()
	_check("in a wave the dead climb out in the middle of the road (%d)" % count, count >= graves.data.count)
	_check("...and Open Graves is active for the wave", graves.is_active())
	level.queue_free()
	await process_frame


func _physics(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check_quiet(ok: bool) -> void:
	if not ok:
		_failures += 1


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
