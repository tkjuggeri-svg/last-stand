extends SceneTree
## Automated check for M10 stage 3's biomes (Bone Quarry, Gloam Wood, Pale Cathedral): their chapter data and
## unlocks, and each mechanic and unique enemy: the Rockfall blocks roads in twos, the Bone Hurler silences a
## tower, the Stalker hides from towers until close, the Treant mends itself, the Stag's roots hold the hero
## (a dash breaks free), Gloom shortens the range of towers away from the lamps, the Chorister shields the
## dead near it, the Inquisitor marks the hero, and altars mend the dead until fire covers them.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const RUN: RunData = preload("res://data/run/run.tres")
const BOARD: UnlockBoard = preload("res://data/meta/unlock_board.tres")
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_quarry()
	await _test_gloam()
	await _test_cathedral()
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


func _tower(level: Level, index: int) -> Tower:
	level.economy.earn(500, Economy.Source.KILL)
	var slot: BuildSlot = level.builder.get_slots()[index]
	level.builder.build(slot, ARCHER)
	await _physics(int(ARCHER.build_time * 60.0) + 2)
	return slot.tower


func _test_data() -> void:
	var expect: Dictionary = {"bone_quarry": 1, "gloam_wood": 2, "pale_cathedral": 3}
	var ok: bool = true
	for id: String in expect:
		var chapter: ChapterData = RUN.find_chapter(StringName(id))
		ok = ok and chapter != null and chapter.tier == expect[id] and chapter.battles.size() == 6 and chapter.elites.size() == 4 and chapter.boss != null
		ok = ok and not chapter.blurb.is_empty() and not chapter.mechanic_text.is_empty() and chapter.level_scene != null
		for n: int in range(1, 16):
			ok = ok and ResourceLoader.exists("res://data/waves/%s/wave_%02d.tres" % [id, n])
	_check("the last three biomes are full chapters (6 battles, 4 elites, a boss, 15 waves, their texts)", ok)
	_check("nine biomes in three tiers of three", RUN.tier_count() == 3 and RUN.chapters.size() == 9 and RUN.biomes_of_tier(1).size() == 3
		and RUN.biomes_of_tier(2).size() == 3 and RUN.biomes_of_tier(3).size() == 3)
	var enemies_ok: bool = true
	var bosses: int = 0
	for id: String in ["bone_hurler", "rubble_brute", "quarry_colossus", "stalker", "hollow_treant", "hollow_stag", "chorister", "inquisitor", "pale_bishop"]:
		var data: EnemyData = load("res://data/enemies/%s.tres" % id)
		enemies_ok = enemies_ok and data.sprite_frames != null and data.sprite_frames.has_animation(&"walk_side") and data.sprite_frames.has_animation(&"death") and data.death_effect != null
		enemies_ok = enemies_ok and (data.is_boss or not data.hint.is_empty()) and (data.is_boss == (data.role == EnemyData.Role.BOSS))
		bosses += 1 if data.is_boss else 0
	_check("the nine new enemies have art, a death, a hint (not the bosses) and the right role (3 bosses)", enemies_ok and bosses == 3)
	_check("each biome is an unlock on the board", ["biome_bone_quarry", "biome_gloam_wood", "biome_pale_cathedral"].all(func(id: String) -> bool: return BOARD.find(StringName(id)) != null))
	var health: HealthComponent = HealthComponent.new()
	health.max_health = 100
	health.current_health = 100
	health.resist = 0.5
	health.take_damage(20)
	_check("HealthComponent.resist scales incoming damage (20 at 0.5 is 10)", health.current_health == 90)
	health.free()


func _test_quarry() -> void:
	var level: Level = _level("bone_quarry")
	await process_frame
	var rocks: CaveIns = level.get_node("Rockfall")
	rocks.data = rocks.data.duplicate()
	rocks.data.first_delay = 0.05
	rocks.data.warning = 1.0
	rocks.data.interval_min = 100.0
	rocks.data.interval_max = 100.0
	level.spawner.waves = [WaveFixtures.make_wave(2, 6.0)]
	level.run_cycle.start_wave()
	await _physics(30)
	var rings: Array[Node] = level.get_node("Effects").find_children("*", "TelegraphMarker", false, false)
	_check("a rockfall warns of two places at once (%d rings)" % rings.size(), rings.size() == 2)
	level.economy.earn(500, Economy.Source.KILL)
	var tower: Tower = await _tower(level, 1)
	var hurler: Enemy = _enemy(level, "bone_hurler", tower.global_position + Vector2(100, 0))
	var shard: ShardAbility = hurler.find_children("*", "ShardAbility", true, false)[0]
	shard._cooldown_left = 0.01
	await _physics(120)
	_check("the Bone Hurler's shard silenced the tower", tower.get_silence().is_silenced())
	level.queue_free()
	await process_frame


func _test_gloam() -> void:
	var level: Level = _level("gloam_wood")
	await process_frame
	var gloom: Gloom = level.get_node("Gloom")
	var lit: Tower = await _tower(level, 1)  # next to the first lamp
	var dark: Tower = await _tower(level, 0)
	await _physics(40)
	var base: float = ARCHER.stats_for(1).attack_range
	_check("a tower by a lamp keeps its range (%.0f of %.0f)" % [lit.get_attack_range(), base], gloom.is_lit(lit.global_position) and is_equal_approx(lit.get_attack_range(), base))
	_check("one in the dark sees 70%% of it (%.0f)" % dark.get_attack_range(), not gloom.is_lit(dark.global_position) and is_equal_approx(dark.get_attack_range(), base * 0.7))
	# Stalkers hide from towers until close.
	var stalker: Enemy = _enemy(level, "stalker", lit.global_position + Vector2(150, 0))
	await _physics(30)
	_check("a Stalker at 150 px is not seen", lit.get_target() != stalker)
	stalker.global_position = lit.global_position + Vector2(60, 0)
	await _physics(30)
	_check("...and at 60 px it is", lit.get_target() == stalker)
	stalker.free()
	# The Treant mends itself.
	var treant: Enemy = _enemy(level, "hollow_treant", Vector2(-300, 200), 200)
	treant.get_health().take_damage(100)
	var hurt: int = treant.get_health().current_health
	await _physics(120)
	_check("the Treant mends itself (%d to %d)" % [hurt, treant.get_health().current_health], treant.get_health().current_health >= hurt + 3)
	treant.free()
	# The Stag's roots hold the hero, and a dash breaks free.
	var hero: Hero = level.get_node("Hero")
	hero.global_position = Vector2(-300, 100)
	var stag: Enemy = _enemy(level, "hollow_stag", Vector2(-280, 100))
	var roots: RootAbility = stag.find_children("*", "RootAbility", true, false)[0]
	roots._cooldown_left = 0.01
	await _physics(120)
	_check("the Stag's roots hold the hero", hero.is_held())
	hero.dash(Vector2.RIGHT)
	_check("a dash breaks free", not hero.is_held())
	level.queue_free()
	await process_frame


func _test_cathedral() -> void:
	var level: Level = _level("pale_cathedral")
	await process_frame
	var hero: Hero = level.get_node("Hero")
	hero.global_position = Vector2(300, 300)
	# The Chorister's song.
	var singer: Enemy = _enemy(level, "chorister", Vector2(-200, 200))
	var near: Enemy = _enemy(level, "ghoul", Vector2(-170, 200), 100)
	var far: Enemy = _enemy(level, "ghoul", Vector2(100, 200), 100)
	await _physics(60)
	near.get_health().take_damage(20)
	far.get_health().take_damage(20)
	_check("the Chorister shields the dead near it: 16 damage left of 20, none for the far one (%d, %d of 100)" % [near.get_health().current_health, far.get_health().current_health],
		near.get_health().current_health == 84 and far.get_health().current_health == 80)
	singer.get_health().take_damage(10000)
	await _physics(10)
	_check("when it falls the shield goes", is_instance_valid(near) and is_equal_approx(near.get_health().resist, 1.0))
	near.free()
	far.free()
	# The Inquisitor's mark.
	var inquisitor: Enemy = _enemy(level, "inquisitor", Vector2(290, 300))
	var mark: MarkHeroAbility = inquisitor.find_children("*", "MarkHeroAbility", true, false)[0]
	mark.mark_time = 0.5
	mark._cooldown_left = 0.01
	await _physics(80)
	_check("the Inquisitor marks the hero: 30% more damage", is_equal_approx(hero.health.resist, 1.3))
	await _physics(60)
	_check("...for a moment", is_equal_approx(hero.health.resist, 1.0))
	inquisitor.free()
	# The altars.
	var consecration: Consecration = level.get_node("Consecration")
	var altar: Vector2 = consecration.altars[1]
	var wounded: Enemy = _enemy(level, "ghoul", altar + Vector2(20, 0), 500)
	wounded.get_health().take_damage(300)
	level.spawner.waves = [WaveFixtures.make_wave(2, 6.0)]
	level.run_cycle.start_wave()
	await _physics(90)
	var healed: int = wounded.get_health().current_health
	_check("an altar mends the dead beside it (%d of 500, from 200)" % healed, healed > 210)
	var zone: BurnZone = (load("res://entities/towers/burn_zone.tscn") as PackedScene).instantiate()
	zone.setup(10.0, 40.0, 20.0)
	zone.top_level = true
	zone.position = altar
	level.add_child(zone)
	await _physics(5)
	_check("burning ground covers it", consecration.is_covered(altar))
	var covered: int = wounded.get_health().current_health
	await _physics(90)
	_check("a covered altar mends nothing (burning hurts instead: %d to %d)" % [covered, wounded.get_health().current_health], wounded.get_health().current_health <= covered)
	level.queue_free()
	await process_frame


func _physics(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
