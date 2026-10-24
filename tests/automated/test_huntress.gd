extends SceneTree
## Automated check for the Huntress (M9 stage 2): her bolt flies along the aim, hits for her damage, goes
## through one enemy and stops at the second, is stopped by a shield, and marks what it hits; towers deal
## more to a marked enemy until the mark wears off; she is a War Room unlock that needs the first boss.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const HUNTRESS: HeroData = preload("res://data/heroes/huntress.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const SHIELDBEARER: EnemyData = preload("res://data/enemies/shieldbearer.tres")
const BOARD: UnlockBoard = preload("res://data/meta/unlock_board.tres")
const RUN: RunData = preload("res://data/run/run.tres")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const KNIGHT: HeroData = preload("res://data/heroes/knight.tres")
const TRAP: TowerData = preload("res://data/towers/trap_layer.tres")
const BARBED: UpgradeData = preload("res://data/upgrades/barbed_bolts.tres")
const QUICK: UpgradeData = preload("res://data/upgrades/quick_hands.tres")
const SNARE_CARD: UpgradeData = preload("res://data/upgrades/snare_mastery.tres")
const MARK_CARD: UpgradeData = preload("res://data/upgrades/hunters_mark.tres")
const QUIVER: RelicData = preload("res://data/relics/quiver_of_plenty.tres")
const HONED: UpgradeData = preload("res://data/upgrades/honed_blade.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_bolt()
	await _test_mark_on_towers()
	await _test_cards()
	_test_unlock()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _level() -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	var hero: Hero = level.get_node("Hero")
	hero.data = HUNTRESS
	hero.position = Vector2(-300, 100)
	root.add_child(level)
	return level


func _enemy(level: Level, data: EnemyData, at: Vector2) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = data
	enemy.position = at
	level.add_child(enemy)
	(enemy.get_node("%AttackRange") as Area2D).monitoring = false
	return enemy


func _test_data() -> void:
	_check("her stats: 75 HP, speed 215, a bolt of 9 piercing 1", HUNTRESS.max_health == 75 and is_equal_approx(HUNTRESS.move_speed, 215.0)
		and HUNTRESS.attack_damage == 9 and HUNTRESS.bolt_pierce == 1 and HUNTRESS.attack_kind == HeroData.AttackKind.BOLT)
	_check("she is in the run's roster", RUN.get_hero("huntress") == HUNTRESS)


func _test_bolt() -> void:
	var level: Level = _level()
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	_check("the hero plays her sheet and has her stats", hero.health.max_health == 75 and hero.get_node("%Sprite").sprite_frames == HUNTRESS.frames)
	var near: Enemy = _enemy(level, GHOUL, Vector2(-150, 100))
	var far: Enemy = _enemy(level, GHOUL, Vector2(-100, 100))
	var third: Enemy = _enemy(level, GHOUL, Vector2(-50, 100))
	var behind: Enemy = _enemy(level, GHOUL, Vector2(-300, -100))
	var full: int = near.get_health().current_health
	hero.attack(Vector2(200, 100))
	await _frames(40)
	_check("the bolt hits the first enemy for 9 (%d of %d)" % [near.get_health().current_health, full], near.get_health().current_health == full - 9)
	_check("...passes through to a second", far.get_health().current_health == full - 9)
	_check("...and stops there: a third is untouched, so is one off the line", third.get_health().current_health == full and behind.get_health().current_health == full)
	_check("every enemy it hit is marked, the others are not", near.get_status().is_marked() and far.get_status().is_marked()
		and not third.get_status().is_marked() and is_equal_approx(near.get_status().get_mark_bonus(), 0.15))
	await _frames(190)  # past the mark's 3 s
	_check("the mark wears off", not near.get_status().is_marked() and near.get_status().get_mark_bonus() == 0.0)
	hero.attack(Vector2(200, 100))  # the cooldown has long run out
	await _frames(2)
	_check("a bolt is on its way (and no sword arc)", hero.get_node("%AttackShape").disabled and hero.get_children().any(func(n: Node) -> bool: return n is HeroBolt))
	level.queue_free()
	await process_frame


func _test_mark_on_towers() -> void:
	var level: Level = _level()
	await _frames(2)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	(level.get_node("%Economy") as Economy).earn(1000, Economy.Source.KILL)
	var slot: BuildSlot = builder.get_slots()[3]
	builder.build(slot, ARCHER)
	await _frames(int(ARCHER.build_time * 60.0) + 2)
	var tower: Tower = slot.tower
	tower.process_mode = Node.PROCESS_MODE_DISABLED  # only the shots made here count
	var plain: Enemy = _enemy(level, GHOUL, slot.global_position + Vector2(60, 0))
	var marked: Enemy = _enemy(level, GHOUL, slot.global_position + Vector2(-60, 0))
	marked.get_status().mark(0.5, 10.0)
	var full: int = plain.get_health().current_health
	var shot: Projectile = (load("res://entities/towers/projectile.tscn") as PackedScene).instantiate()
	var damage: int = tower.get_stats().damage
	shot.launch(ARCHER, tower.get_stats(), marked, marked.global_position + Vector2(0, -8), tower.global_position)
	level.add_child(shot)
	await _frames(20)
	_check("a tower's shot deals +50%% to a marked enemy (%d, base %d)" % [full - marked.get_health().current_health, damage],
		full - marked.get_health().current_health == roundi(damage * 1.5))
	var shot2: Projectile = (load("res://entities/towers/projectile.tscn") as PackedScene).instantiate()
	shot2.launch(ARCHER, tower.get_stats(), plain, plain.global_position + Vector2(0, -8), tower.global_position)
	level.add_child(shot2)
	await _frames(20)
	_check("...and the base damage to an unmarked one", full - plain.get_health().current_health == damage)
	level.queue_free()
	await process_frame


func _test_cards() -> void:
	var roster: Array[HeroData] = [KNIGHT, HUNTRESS]
	var level: Level = _level()
	level.apply_hero(HUNTRESS, roster)
	await _frames(2)
	var offers: UpgradeOffers = level.offers
	_check("her offers hold her four cards and her relic, not the sword cards", offers.pool.has(BARBED) and offers.pool.has(QUICK)
		and offers.pool.has(SNARE_CARD) and offers.pool.has(MARK_CARD) and offers.relic_pool.has(QUIVER) and not offers.pool.has(HONED))
	var knight_level: Level = _level()
	knight_level.apply_hero(KNIGHT, roster)
	await _frames(2)
	_check("the Knight's offers hold the sword cards and none of hers", knight_level.offers.pool.has(HONED) and not knight_level.offers.pool.has(BARBED)
		and not knight_level.offers.relic_pool.has(QUIVER))
	knight_level.queue_free()
	var mods: RunModifiers = level.modifiers
	var hero: Hero = level.get_node("Hero")
	mods.add_upgrade(QUICK)
	_check("Quick Hands: a bolt every 0.44 s", is_equal_approx(mods.apply(HUNTRESS.attack_cooldown, [RunModifiers.HERO_ATTACK_COOLDOWN]), 0.44))
	mods.add_upgrade(BARBED)
	var line: Array[Enemy] = []
	for i: int in 4:
		line.append(_enemy(level, GHOUL, Vector2(-150 + i * 40, 100)))
	hero.attack(Vector2(200, 100))
	await _frames(40)
	var hit: int = line.filter(func(e: Enemy) -> bool: return e.get_health().current_health < e.get_health().max_health).size()
	_check("Barbed Bolts: a bolt goes through 3 enemies (hit %d of 4)" % hit, hit == 3)
	mods.add_upgrade(MARK_CARD)
	await _frames(40)
	hero.attack(Vector2(200, 100))
	await _frames(20)
	_check("Hunter's Mark: +25% for 5 s", is_equal_approx(line[0].get_status().get_mark_bonus(), 0.25))
	await _frames(240)
	_check("...and still marked after 4 s", line[0].get_status().is_marked())
	var tower_level: Level = _level()
	tower_level.apply_hero(HUNTRESS, roster)
	await _frames(2)
	(tower_level.get_node("%Economy") as Economy).earn(1000, Economy.Source.KILL)
	var slot: BuildSlot = tower_level.builder.get_slots()[3]
	tower_level.builder.build(slot, TRAP)
	tower_level.modifiers.add_upgrade(SNARE_CARD)
	_check("Snare Mastery: a snare holds 1.7 s (%.1f)" % slot.tower.get_stats().snare_hold, is_equal_approx(slot.tower.get_stats().snare_hold, 1.7))
	tower_level.queue_free()
	level.queue_free()
	await process_frame
	await _test_quiver()


## Quiver of Plenty: the fifth bolt is a fan of three.
func _test_quiver() -> void:
	var level: Level = _level()
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	level.modifiers.add_upgrade(QUIVER)
	var counts: Array[int] = []
	for _i: int in 5:
		hero.attack(Vector2(200, 100))
		counts.append(hero.get_children().filter(func(n: Node) -> bool: return n is HeroBolt and not n.is_queued_for_deletion()).size())
		await _frames(40)
	_check("Quiver of Plenty: bolts in the air after each shot %s: the 5th fires 3" % [counts], counts == [1, 1, 1, 1, 3])
	level.queue_free()
	await process_frame


func _test_unlock() -> void:
	var unlock: UnlockData = BOARD.find(&"hero_huntress")
	_check("the Huntress is on the board for 60 shards, with her hero", unlock != null and unlock.cost == 60 and unlock.heroes == [HUNTRESS])
	var profile: SaveProfile = SaveProfile.new()
	profile.shards = 100
	_check("not before a boss is beaten (%s)" % MetaProgress.blocker(profile, BOARD, unlock), MetaProgress.blocker(profile, BOARD, unlock).begins_with("Beat"))
	_check("...so she can't be played", not BOARD.is_hero_unlocked(profile, HUNTRESS) and BOARD.is_hero_unlocked(profile, RUN.get_hero("knight")))
	profile.firsts.append("boss:The Lich Warden")
	_check("after the boss she can be bought", MetaProgress.blocker(profile, BOARD, unlock) == "" and MetaProgress.buy(profile, BOARD, unlock)
		and profile.shards == 40 and BOARD.is_hero_unlocked(profile, HUNTRESS))


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
