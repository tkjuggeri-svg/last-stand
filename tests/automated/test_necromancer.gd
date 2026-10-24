extends SceneTree
## Automated check for the Necromancer and her skeletons (M9 stage 3): her soul bolt's kill raises a
## skeleton where the enemy fell (3 at a time), skeletons seek and fight enemies, enemies stop to fight
## them (the allies layer), they expire, a Plague bomber bursts when it falls, and she is a War Room unlock
## that needs chapter 2 reached.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const KNIGHT: HeroData = preload("res://data/heroes/knight.tres")
const NECRO: HeroData = preload("res://data/heroes/necromancer.tres")
const SKELETON: MinionData = preload("res://data/minions/skeleton.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const BOARD: UnlockBoard = preload("res://data/meta/unlock_board.tres")
const BONE_ARMOUR: UpgradeData = preload("res://data/upgrades/bone_armour.tres")
const GRAVECALLER: UpgradeData = preload("res://data/upgrades/gravecaller.tres")
const SOUL_FEAST: UpgradeData = preload("res://data/upgrades/soul_feast.tres")
const DARK_BARGAIN: UpgradeData = preload("res://data/upgrades/dark_bargain.tres")
const RELIQUARY: RelicData = preload("res://data/relics/reliquary_of_bones.tres")
const OSSUARY: TowerData = preload("res://data/towers/ossuary.tres")
const RUN: RunData = preload("res://data/run/run.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_raise_on_kill()
	await _test_fighting()
	await _test_expiry_and_burst()
	await _test_cards()
	_test_unlock()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _level() -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	var hero: Hero = level.get_node("Hero")
	hero.data = NECRO
	hero.position = Vector2(-300, 100)
	root.add_child(level)
	level.apply_hero(NECRO, [KNIGHT, NECRO])
	return level


func _enemy(level: Level, at: Vector2, health: int = 500) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = GHOUL
	enemy.position = at
	level.add_child(enemy)
	enemy.get_health().max_health = health
	enemy.get_health().current_health = health
	return enemy


func _test_data() -> void:
	_check("her stats: 80 HP, speed 195, a soul bolt of 6 every 0.45 s, 3 skeletons at a time",
		NECRO.max_health == 80 and is_equal_approx(NECRO.move_speed, 195.0) and NECRO.attack_damage == 6
		and is_equal_approx(NECRO.attack_cooldown, 0.45) and NECRO.raise_cap == 3 and NECRO.raise_minion == SKELETON)
	_check("a skeleton: 30 HP, 6 damage, 20 s", SKELETON.max_health == 30 and SKELETON.damage == 6 and is_equal_approx(SKELETON.lifetime, 20.0))
	_check("she is in the run's roster", RUN.get_hero("necromancer") == NECRO)
	var frames: SpriteFrames = load("res://entities/minions/skeleton_frames.tres")
	_check("the skeleton has idle, walk, attack and death art", ["idle", "walk", "attack", "death"].all(func(a: String) -> bool: return frames.has_animation(StringName(a))))
	_check("the allies layer exists (layer 9)", ProjectSettings.get_setting("layer_names/2d_physics/layer_9") == "allies")


func _test_raise_on_kill() -> void:
	var level: Level = _level()
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	var victims: Array[Enemy] = []
	for offset: Vector2 in [Vector2(100, 0), Vector2(0, 100), Vector2(-100, 0), Vector2(0, -100)]:
		victims.append(_enemy(level, hero.global_position + offset, 6))
	for i: int in 4:
		hero.attack(victims[i].global_position)
		await _frames(35)
	var skeletons: Array[Minion] = level.minions.get_minions()
	_check("each kill raises a skeleton, but no more than 3 at a time (%d)" % skeletons.size(), skeletons.size() == 3)
	_check("they stand where the enemies fell, on the allies layer", skeletons[0].collision_layer == 256 and skeletons[0].collision_mask == 1)
	level.queue_free()
	await process_frame


func _test_fighting() -> void:
	var level: Level = _level()
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	var enemy: Enemy = _enemy(level, Vector2(-150, 100), 80)
	var skeleton: Minion = level.minions.raise(SKELETON, Vector2(-250, 100), hero, 3, hero)
	var full: int = skeleton.get_health().max_health
	await _frames(240)
	_check("the skeleton seeks the enemy and fights it (enemy %d of 80)" % enemy.get_health().current_health, enemy.get_health().current_health < 80)
	var hurt: bool = not is_instance_valid(skeleton) or skeleton.is_fallen() or skeleton.get_health().current_health < full
	_check("the enemy fights back: it hurt the skeleton (it is %s)" % ("gone" if not is_instance_valid(skeleton) else "at %d of %d" % [skeleton.get_health().current_health, full]), hurt)
	level.queue_free()
	await process_frame


func _test_expiry_and_burst() -> void:
	var level: Level = _level()
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	var short: MinionData = SKELETON.duplicate()
	short.lifetime = 1.0
	var minion: Minion = level.minions.raise(short, Vector2(-250, 100), hero, 3, hero)
	await _frames(100)
	_check("a skeleton crumbles when its time is up, and frees its place", not is_instance_valid(minion) and level.minions.count_for(hero) == 0)
	var bomber: MinionData = SKELETON.duplicate()
	bomber.burst_damage = 40
	bomber.burst_radius = 80.0
	var near: Enemy = _enemy(level, Vector2(-250, 130), 200)
	var carrier: Minion = level.minions.raise(bomber, Vector2(-250, 100), hero, 3, hero)
	carrier.get_health().take_damage(1000)
	await _frames(20)
	_check("a bomber bursts when it falls: 40 damage around it (%d of 200)" % near.get_health().current_health, near.get_health().current_health <= 160)
	level.queue_free()
	await process_frame


func _test_cards() -> void:
	var level: Level = _level()
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	var offers: UpgradeOffers = level.offers
	_check("her offers hold her four cards and her relic, not the sword cards or the Huntress's", offers.pool.has(BONE_ARMOUR) and offers.pool.has(GRAVECALLER)
		and offers.pool.has(SOUL_FEAST) and offers.pool.has(DARK_BARGAIN) and offers.relic_pool.has(RELIQUARY)
		and not offers.pool.has(preload("res://data/upgrades/honed_blade.tres")) and not offers.pool.has(preload("res://data/upgrades/barbed_bolts.tres")))
	level.modifiers.add_upgrade(BONE_ARMOUR)
	var skeleton: Minion = level.minions.raise(SKELETON, Vector2(-250, 100), hero, 9, hero)
	_check("Bone Armour: skeletons have 45 HP", skeleton.get_health().max_health == 45)
	level.modifiers.add_upgrade(GRAVECALLER)
	_check("Gravecaller: 4 skeletons of hers at once", RunModifiers.value_int(level.modifiers, NECRO.raise_cap, [RunModifiers.MINION_CAP]) == 4)
	hero.health.take_damage(40)
	var hp: int = hero.health.current_health
	level.modifiers.add_upgrade(SOUL_FEAST)
	skeleton.get_health().take_damage(1000)
	await _frames(5)
	_check("Soul Feast: a fallen skeleton heals her 5 (%d to %d)" % [hp, hero.health.current_health], hero.health.current_health == hp + 5)
	level.modifiers.add_upgrade(DARK_BARGAIN)
	_check("Dark Bargain: 40%% more damage, 20 less max HP (%d, %d)" % [(hero.get_node("%AttackHitbox") as Hitbox).damage, hero.health.max_health],
		(hero.get_node("%AttackHitbox") as Hitbox).damage == 8 and hero.health.max_health == 60)
	level.queue_free()
	await process_frame
	level = _level()
	await _frames(2)
	(level.get_node("%Economy") as Economy).earn(5000, Economy.Source.KILL)
	var slot: BuildSlot = level.builder.get_slots()[3]
	level.builder.build(slot, OSSUARY)
	await _frames(int(OSSUARY.build_time * 60.0) + 2)
	var ossuary: Tower = slot.tower
	hero = level.get_node("Hero")
	# Enemies placed by hand never come from the spawner, so its own soul for a death is absent here:
	# what is counted is only the Reliquary's extra one.
	var first: Enemy = _enemy(level, ossuary.global_position + Vector2(60, 0), 6)
	level.minions.raise(SKELETON, first.global_position + Vector2(-20, 0), hero, 3, hero)
	await _frames(120)
	_check("without the Reliquary a skeleton's kill gives an Ossuary nothing extra", (not is_instance_valid(first) or not first.is_alive()) and ossuary.get_souls() == 0)
	level.modifiers.add_upgrade(RELIQUARY)
	var second: Enemy = _enemy(level, ossuary.global_position + Vector2(60, 40), 6)
	level.minions.raise(SKELETON, second.global_position + Vector2(-20, 0), hero, 3, hero)
	await _frames(120)
	_check("with it, one more soul (%d)" % ossuary.get_souls(), (not is_instance_valid(second) or not second.is_alive()) and ossuary.get_souls() == 1)
	level.queue_free()
	await process_frame


func _test_unlock() -> void:
	var unlock: UnlockData = BOARD.find(&"hero_necromancer")
	_check("the Necromancer is on the board for 90 shards", unlock != null and unlock.cost == 90 and unlock.heroes == [NECRO])
	var profile: SaveProfile = SaveProfile.new()
	profile.shards = 200
	_check("not before chapter 2 is reached (%s)" % MetaProgress.blocker(profile, BOARD, unlock), MetaProgress.blocker(profile, BOARD, unlock).begins_with("Needs"))
	profile.firsts.append("chapter:Chapter 2 reached")
	_check("then she can be bought", MetaProgress.buy(profile, BOARD, unlock) and BOARD.is_hero_unlocked(profile, NECRO) and profile.shards == 110)


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
