extends SceneTree
## Automated check for the hero ultimates (M14, docs/M14_ULTIMATES.md): every hero has one with its own cards, the bar
## charges from kills, damage and wave time (never past full), carries over and restarts at half in a new chapter, the
## key spends a full bar only, and each effect does what it says: Last Stand (a held, hurt ring, a capped blow on a
## boss, half damage and a wider swing), Volley of Ruin (impacts that Mark and hurt along a line), Rise of the Dead
## (extra skeletons over her cap).
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const KNIGHT: HeroData = preload("res://data/heroes/knight.tres")
const HUNTRESS: HeroData = preload("res://data/heroes/huntress.tres")
const NECRO: HeroData = preload("res://data/heroes/necromancer.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const LICH: EnemyData = preload("res://data/enemies/lich.tres")
const RUN: RunData = preload("res://data/run/run.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_charge()
	await _test_key()
	await _test_last_stand()
	await _test_volley()
	await _test_rise()
	await _test_cards_and_save()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _level(hero_data: HeroData) -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	var hero: Hero = level.get_node("Hero")
	hero.data = hero_data
	hero.position = Vector2(-300, 100)
	root.add_child(level)
	level.apply_hero(hero_data, [KNIGHT, HUNTRESS, NECRO])
	return level


func _enemy(level: Level, at: Vector2, health: int = 500, data: EnemyData = GHOUL) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = data
	enemy.position = at
	level.add_child(enemy)
	enemy.get_health().max_health = health
	enemy.get_health().current_health = health
	return enemy


func _fill(hero: Hero) -> void:
	hero.get_ultimate().add_charge(1000.0)


func _test_data() -> void:
	for hero: HeroData in [KNIGHT, HUNTRESS, NECRO]:
		_check("%s has an ultimate with a name and a sound" % hero.display_name, hero.ultimate != null and hero.ultimate.display_name != "" and Sfx.has(hero.ultimate.sound))
	_check("each hero's own ultimate", KNIGHT.ultimate.kind == UltimateData.Kind.LAST_STAND and HUNTRESS.ultimate.kind == UltimateData.Kind.VOLLEY and NECRO.ultimate.kind == UltimateData.Kind.RISE)
	for pair: Array in [[KNIGHT, "oathbound"], [KNIGHT, "wider_circle"], [HUNTRESS, "quickdraw"], [HUNTRESS, "rain_of_spears"], [NECRO, "grave_hunger"], [NECRO, "crowded_crypt"]]:
		var hero: HeroData = pair[0]
		_check("%s is in %s's own cards" % [pair[1], hero.display_name], hero.exclusive_cards.any(func(c: UpgradeData) -> bool: return c.id == StringName(pair[1])))
	_check("the key is an input action every player can rebind", InputMap.has_action("ultimate") and GameSettings.ACTIONS.has(&"ultimate") and GameSettings.ACTION_NAMES.has(&"ultimate"))


func _test_charge() -> void:
	var level: Level = _level(KNIGHT)
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	var ult: HeroUltimate = hero.get_ultimate()
	_check("a new chapter starts the bar at half (%.0f)" % ult.get_charge(), is_equal_approx(ult.get_charge(), 50.0))
	var before: float = ult.get_charge()
	await _frames(60)
	_check("time alone does not charge it outside a wave", is_equal_approx(ult.get_charge(), before))
	ult.wave_running = true
	await _frames(60)
	_check("a running wave charges it slowly (%.2f in 1 s)" % (ult.get_charge() - before), ult.get_charge() - before > 0.3 and ult.get_charge() - before < 0.8)
	ult.wave_running = false
	var ghoul: Enemy = _enemy(level, hero.global_position + Vector2(40, 0), 5)
	var at: float = ult.get_charge()
	hero.dealt.emit(ghoul, 10)
	ghoul.get_health().take_damage(10)
	level.spawner.enemy_killed.emit(ghoul)  # the spawner reports deaths of the enemies it sent
	await _frames(2)
	_check("a kill the hero dealt adds its points (+%.2f)" % (ult.get_charge() - at), ult.get_charge() - at >= 2.0)
	var stranger: Enemy = _enemy(level, hero.global_position + Vector2(-40, 0), 5)
	at = ult.get_charge()
	stranger.get_health().take_damage(10)
	level.spawner.enemy_killed.emit(stranger)
	await _frames(2)
	_check("a kill by a tower (nobody of the hero's hurt it) adds nothing", is_equal_approx(ult.get_charge(), at))
	_fill(hero)
	_check("it never goes past full", is_equal_approx(ult.get_charge(), 100.0) and ult.is_ready())
	var boss_at: float = 0.0
	ult.setup(KNIGHT.ultimate)
	var boss: Enemy = _enemy(level, hero.global_position + Vector2(60, 0), 50, LICH)
	hero.dealt.emit(boss, 0)
	boss.get_health().take_damage(60)
	level.spawner.enemy_killed.emit(boss)
	await _frames(2)
	boss_at = ult.get_charge()
	_check("a boss kill pays 25 (%.1f)" % boss_at, boss_at >= 25.0)
	level.queue_free()
	await process_frame


func _test_key() -> void:
	var level: Level = _level(KNIGHT)
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	var ult: HeroUltimate = hero.get_ultimate()
	var used: Array[int] = [0]
	ult.used.connect(func() -> void: used[0] += 1)
	Input.action_press("ultimate")
	await _frames(3)
	Input.action_release("ultimate")
	_check("the key does nothing while the bar is not full", used[0] == 0 and ult.get_charge() > 0.0)
	_fill(hero)
	Input.action_press("ultimate")
	await _frames(3)
	Input.action_release("ultimate")
	_check("the key spends a full bar once", used[0] == 1 and is_zero_approx(ult.get_charge()))
	_fill(hero)
	hero.health.take_damage(10000)
	await _frames(2)
	Input.action_press("ultimate")
	await _frames(3)
	Input.action_release("ultimate")
	_check("a fallen hero can't use it", used[0] == 1)
	level.queue_free()
	await process_frame


func _test_last_stand() -> void:
	var level: Level = _level(KNIGHT)
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	var blow: int = hero.get_attack_damage()
	var near: Enemy = _enemy(level, hero.global_position + Vector2(100, 0))
	var far: Enemy = _enemy(level, hero.global_position + Vector2(400, 0))
	var boss: Enemy = _enemy(level, hero.global_position + Vector2(0, 100), 1000, LICH)
	await _frames(2)
	_fill(hero)
	hero.get_ultimate().use()
	await _frames(2)
	_check("Last Stand: the enemy in the ring takes six blows (%d of %d)" % [500 - near.get_health().current_health, blow * 6], 500 - near.get_health().current_health == blow * 6)
	_check("...and is held", near.get_status().is_frozen())
	_check("...an enemy outside the ring is left alone", far.get_health().current_health == 500 and not far.get_status().is_frozen())
	var taken: int = 1000 - boss.get_health().current_health
	_check("...a boss takes three blows at most 10%% of its health (%d) and is not held" % taken, taken == mini(blow * 3, 100) and not boss.get_status().is_frozen())
	_check("...the hero takes half damage for a while", hero.get_ultimate().is_buffed() and is_equal_approx(hero.get_ultimate().get_damage_taken(), 0.5))
	await _frames(2)
	_check("...the wider reach reaches the hero's hitbox", hero.get_node("%AttackHitbox").scale.x > 1.25)
	await _frames(int(KNIGHT.ultimate.buff_seconds * 60.0) + 10)
	_check("...and wears off", not hero.get_ultimate().is_buffed() and is_equal_approx(hero.get_node("%AttackHitbox").scale.x, 1.0))
	level.queue_free()
	await process_frame


func _test_volley() -> void:
	var level: Level = _level(HUNTRESS)
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	hero.position = Vector2(-300, 100)
	var on_line: Enemy = _enemy(level, hero.global_position + Vector2(0, 180))
	var off_line: Enemy = _enemy(level, hero.global_position + Vector2(300, 0))
	await _frames(2)
	_fill(hero)
	level.get_node("UltimateRunner").aim_override = Vector2.DOWN
	hero.get_ultimate().use()
	await _frames(int(HUNTRESS.ultimate.volley_seconds * 60.0) + 30)
	_check("Volley of Ruin: an enemy on the line is hurt (%d of 500)" % on_line.get_health().current_health, on_line.get_health().current_health < 500)
	_check("...and Marked", on_line.get_status().is_marked())
	_check("...an enemy off the line is not", off_line.get_health().current_health == 500 and not off_line.get_status().is_marked())
	level.queue_free()
	await process_frame


func _test_rise() -> void:
	var level: Level = _level(NECRO)
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	_fill(hero)
	hero.get_ultimate().use()
	await _frames(2)
	var count: int = level.minions.get_minions().size()
	_check("Rise of the Dead raises five skeletons at once (%d)" % count, count == 5)
	_check("...over the cap of her own three (her bolt raises one more)", level.minions.count_for(hero) == 0)
	var lifetime: float = level.minions.get_minions()[0].data.lifetime
	_check("...that last 12 s (%.0f)" % lifetime, is_equal_approx(lifetime, 12.0))
	level.queue_free()
	await process_frame


func _test_cards_and_save() -> void:
	var level: Level = _level(KNIGHT)
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	var ult: HeroUltimate = hero.get_ultimate()
	var plain: float = ult.get_charge()
	ult.add_charge(10.0)
	var step: float = ult.get_charge() - plain
	ult.setup(KNIGHT.ultimate)
	level.modifiers.add_upgrade(load("res://data/upgrades/oathbound.tres"))
	ult.add_charge(10.0)
	_check("Oathbound charges 25%% faster (%.1f vs %.1f)" % [ult.get_charge(), step], is_equal_approx(ult.get_charge(), step * 1.25))
	var wide: Enemy = _enemy(level, hero.global_position + Vector2(200, 0))
	await _frames(2)
	_fill(hero)
	hero.get_ultimate().use()
	await _frames(2)
	_check("without Wider Circle an enemy 200 px away is outside Last Stand's ring", wide.get_health().current_health == 500)
	level.modifiers.add_upgrade(load("res://data/upgrades/wider_circle.tres"))
	ult.add_charge(1000.0)
	ult.use()
	await _frames(2)
	_check("Wider Circle (+40%%) takes it in (%d of 500)" % wide.get_health().current_health, wide.get_health().current_health < 500)
	ult.setup(KNIGHT.ultimate)
	ult.add_charge(10.0)
	var state: Dictionary = level.get_ultimate_state()
	ult.setup(KNIGHT.ultimate)
	level.load_ultimate_state(state)
	_check("the bar is saved and put back (%.1f)" % ult.get_charge(), is_equal_approx(ult.get_charge(), 12.5))
	level.queue_free()
	await process_frame


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
