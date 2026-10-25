extends SceneTree
## Automated check for M10 stage 2's biomes (Ember Orchard, Frostbound Pass, Sunless Mines): their chapter
## data and unlocks, and each mechanic and unique enemy: Dry Grass catches from burning enemies and burns the
## hero too, the Cinder Ghoul leaves fire, the Scarecrow draws the towers, the Rime Brute shrugs off slows, the
## Frost Wraith's ring chills the hero and silences towers, the Blizzard shortens ranges and quickens the dead,
## the Burrower comes up further on the road, a cave-in's rubble holds the dead in place.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const RUN: RunData = preload("res://data/run/run.tres")
const BOARD: UnlockBoard = preload("res://data/meta/unlock_board.tres")
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_dry_grass()
	await _test_enemies()
	await _test_blizzard()
	await _test_cave_in()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _level(id: String) -> Level:
	var level: Level = (load("res://levels/%s.tscn" % id) as PackedScene).instantiate()
	root.add_child(level)
	return level


func _enemy(level: Level, id: String, at: Vector2, health: int = 5000) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = load("res://data/enemies/%s.tres" % id)
	enemy.position = at
	level.add_child(enemy)
	(enemy.get_node("%AttackRange") as Area2D).monitoring = false
	enemy.get_health().max_health = health
	enemy.get_health().current_health = health
	return enemy


func _test_data() -> void:
	var expect: Dictionary = {"ember_orchard": 1, "frostbound_pass": 2, "sunless_mines": 3}
	var ok: bool = true
	for id: String in expect:
		var chapter: ChapterData = RUN.find_chapter(StringName(id))
		ok = ok and chapter != null and chapter.tier == expect[id] and chapter.battles.size() == 6 and chapter.elites.size() == 4 and chapter.boss != null
		ok = ok and not chapter.blurb.is_empty() and not chapter.mechanic_text.is_empty() and chapter.level_scene != null
		for n: int in range(1, 16):
			ok = ok and ResourceLoader.exists("res://data/waves/%s/wave_%02d.tres" % [id, n])
	_check("three more biomes, one per tier, each a full chapter (6 battles, 4 elites, a boss, 15 waves, its texts)", ok)
	var enemies_ok: bool = true
	for id: String in ["cinder_ghoul", "scarecrow", "pyre_warden", "frost_wraith", "rime_brute", "winter_warden", "burrower", "lamp_wight", "deep_warden"]:
		var data: EnemyData = load("res://data/enemies/%s.tres" % id)
		enemies_ok = enemies_ok and data.sprite_frames != null and data.sprite_frames.has_animation(&"walk_side") and data.sprite_frames.has_animation(&"death")
		enemies_ok = enemies_ok and data.death_effect != null and (data.is_boss or not data.hint.is_empty()) and (data.is_boss == (data.role == EnemyData.Role.BOSS))
	_check("the nine new enemies have art, a death, a hint (not the bosses) and the right role", enemies_ok)
	var unlocks: Array[UnlockData] = []
	for id: String in ["biome_ember_orchard", "biome_frostbound_pass", "biome_sunless_mines"]:
		unlocks.append(BOARD.find(StringName(id)))
	_check("each other biome is an unlock with a price and something to earn first", unlocks.all(func(u: UnlockData) -> bool: return u != null and u.cost >= 40 and u.requires_first != "" and u.biomes.size() == 1))
	var profile: SaveProfile = SaveProfile.new()
	profile.unlock_everything = true
	_check("in script mode the extra biomes stay locked (the plain run: Crypt Road, Marsh, Ashen Keep)", RunUnlocks.for_profile(BOARD, profile).locked_biomes.size() == 6)
	profile.unlocks.append("biome_frostbound_pass")
	_check("a bought biome opens", RunUnlocks.for_profile(BOARD, profile).locked_biomes.size() == 5)


func _test_dry_grass() -> void:
	var level: Level = _level("ember_orchard")
	await process_frame
	var grass: DryGrass = level.get_node("DryGrass")
	var hero: Hero = level.get_node("Hero")
	var at: Vector2 = grass.patches[2]
	hero.global_position = at
	var ghoul: Enemy = _enemy(level, "ghoul", at + Vector2(20, 0))
	level.spawner.waves = [WaveFixtures.make_wave(2, 6.0)]
	level.run_cycle.start_wave()
	await _physics(30)
	_check("an untouched patch stays dry", grass.get_state(2) == 0)
	ghoul.get_status().ignite(10.0, 30.0)
	var hp: int = hero.health.current_health
	await _physics(40)
	_check("a burning enemy on it sets it alight", grass.get_state(2) == 1)
	await _physics(90)
	_check("the fire hurts the hero standing in it (%d to %d)" % [hp, hero.health.current_health], hero.health.current_health < hp)
	grass.ignite(0)
	await _physics(5)
	_check("another patch can be lit by hand and the first stays one fire", grass.get_state(0) == 1)
	await _physics(420)
	_check("a patch burns out to ash and cannot burn again", grass.get_state(2) == 2 and grass.get_state(0) == 2)
	level.queue_free()
	await process_frame


func _test_enemies() -> void:
	var level: Level = _level("frostbound_pass")
	await process_frame
	var hero: Hero = level.get_node("Hero")
	level.economy.earn(500, Economy.Source.KILL)
	var slot: BuildSlot = level.builder.get_slots()[3]
	level.builder.build(slot, ARCHER)
	await _physics(int(ARCHER.build_time * 60.0) + 2)
	var tower: Tower = slot.tower
	var base: Vector2 = tower.global_position
	# The Scarecrow draws the tower even though another enemy is further along its road.
	var runner: Enemy = _enemy(level, "ghoul", base + Vector2(90, 0))
	var decoy: Enemy = _enemy(level, "scarecrow", base + Vector2(-90, 0))
	await _physics(30)
	_check("the Scarecrow is the tower's target", tower.get_target() == decoy)
	decoy.free()
	runner.free()
	# The Rime Brute does not slow.
	var rime: Enemy = _enemy(level, "rime_brute", base + Vector2(0, 150))
	rime.apply_slow(0.3, 5.0)
	_check("the Rime Brute shrugs off a slow", not rime.is_slowed() and is_equal_approx(rime.get_move_speed(), rime.data.move_speed))
	rime.free()
	# The Frost Wraith's ring chills the hero and silences the tower.
	hero.global_position = base + Vector2(60, 0)
	var wraith: Enemy = _enemy(level, "frost_wraith", base + Vector2(20, 40))
	var chill: ChillAbility = wraith.find_children("*", "ChillAbility", true, false)[0]
	chill._cooldown_left = 0.01
	await _physics(90)
	_check("the Wraith's ring chilled the hero", hero.is_chilled())
	_check("...and silenced the tower", tower.get_silence().is_silenced())
	wraith.free()
	# The Burrower comes up further on its road.
	var lane: Path2D = level.spawner.lanes[1]
	var start: Vector2 = lane.to_global(lane.curve.sample_baked(60.0))
	var burrower: Enemy = _enemy(level, "burrower", start)
	burrower.lane = lane
	var before: float = burrower.get_lane_progress()
	var burrow: BurrowAbility = burrower.find_children("*", "BurrowAbility", true, false)[0]
	burrow._cooldown_left = 0.01
	await _physics(150)
	_check("the Burrower came up further on the road (%.0f to %.0f px)" % [before, burrower.get_lane_progress()], burrower.get_lane_progress() > before + 100.0)
	burrower.free()
	# The Cinder Ghoul leaves fire where it falls.
	var cinder: Enemy = _enemy(level, "cinder_ghoul", base + Vector2(0, -150), 5)
	cinder.get_health().take_damage(100)
	await _physics(5)
	_check("the Cinder Ghoul leaves burning ground", not level.find_children("*", "FirePatch", true, false).is_empty())
	level.queue_free()
	await process_frame


func _test_blizzard() -> void:
	var level: Level = _level("frostbound_pass")
	await process_frame
	var blizzard: Blizzard = level.get_node("Blizzard")
	level.economy.earn(500, Economy.Source.KILL)
	var slot: BuildSlot = level.builder.get_slots()[3]
	level.builder.build(slot, ARCHER)
	await _physics(int(ARCHER.build_time * 60.0) + 2)
	var tower: Tower = slot.tower
	var range_before: float = tower.get_attack_range()
	blizzard.data = blizzard.data.duplicate()
	blizzard.data.first_delay = 0.05
	blizzard.data.warning = 0.2
	blizzard.data.effect_time = 1.5
	blizzard.data.interval_min = 100.0
	blizzard.data.interval_max = 100.0
	var ghoul: Enemy = _enemy(level, "ghoul", Vector2(-300, 300))
	level.spawner.waves = [WaveFixtures.make_wave(2, 6.0)]
	level.run_cycle.start_wave()
	await _physics(60)
	var walker: Enemy = level.spawner.get_children().filter(func(n: Node) -> bool: return n is Enemy)[0]
	_check("in the gale the tower's range is a fifth shorter (%.0f of %.0f)" % [tower.get_attack_range(), range_before], blizzard.is_blowing() and is_equal_approx(tower.get_attack_range(), range_before * 0.8))
	_check("...and the dead walk 10% faster", is_equal_approx(walker.weather_speed, 1.1))
	await _physics(150)
	_check("when it dies down everything is as before", not blizzard.is_blowing() and is_equal_approx(tower.get_attack_range(), range_before) and is_equal_approx(walker.weather_speed, 1.0))
	ghoul.free()
	level.queue_free()
	await process_frame


func _test_cave_in() -> void:
	var level: Level = _level("sunless_mines")
	await process_frame
	var caves: CaveIns = level.get_node("CaveIns")
	var at: Vector2 = Vector2(-300, -100)
	var enemy: Enemy = _enemy(level, "ghoul", at + Vector2(10, 0))
	caves.collapse(at)
	await _physics(30)
	_check("the rubble holds an enemy in place", enemy.get_status().is_held())
	var far: Enemy = _enemy(level, "ghoul", at + Vector2(400, 0))
	await _physics(30)
	_check("...and only the ones under it", not far.get_status().is_held())
	await _physics(600)
	_check("the rubble goes away on its own", level.find_children("*", "Rubble", true, false).is_empty())
	level.queue_free()
	await process_frame


func _physics(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
