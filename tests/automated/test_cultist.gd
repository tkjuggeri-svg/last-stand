extends SceneTree
## Automated check for the Cultist (ranged enemy): it walks its lane, stops siege_distance before the
## fortress and shoots it; when the hero comes within range it shoots the hero instead (and resumes
## when the hero leaves, also mid-lane); its shots fly straight, so they can be dodged, and a
## dashing hero is immune; it takes no melee attacker slot; it is fragile.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const CULTIST: EnemyData = preload("res://data/enemies/cultist.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
## Out of every lane's way, so the hero is never attacked.
const HERO_AWAY: Vector2 = Vector2(380, 380)

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	for lane: int in 3:
		await _test_siege(lane)
	await _test_hero_targeting()
	await _test_mid_lane()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_data() -> void:
	_check("Cultist: ranged, fragile (%d HP, under a Ghoul's)" % CULTIST.max_health,
		CULTIST.is_ranged() and CULTIST.max_health < GHOUL.max_health and not GHOUL.is_ranged())
	_check("it glows and has a telegraphed cast (%.2f s)" % CULTIST.attack_windup, CULTIST.glow_color.a > 0.0 and CULTIST.attack_windup >= 0.4)


## One Cultist on `lane`, the hero far away: it stops before the fortress and shoots it.
func _test_siege(lane: int) -> void:
	var level: Level = await _level(lane)
	var cultist: Enemy = await _first_enemy(level)
	var fortress: Fortress = level.get_node("Fortress")
	var length: float = cultist.lane.curve.get_baked_length()
	await _frames(30)
	_check("lane %d: it walks its lane (%.0f px/s)" % [lane, cultist.velocity.length()], cultist.velocity.length() > CULTIST.move_speed * 0.9)
	for _i: int in 60 * 30:
		await physics_frame
		if cultist.is_sieging():
			break
	var left: float = length - cultist.get_lane_progress()
	_check("lane %d: it stops %.0f px before the fortress (wants %.0f)" % [lane, left, CULTIST.siege_distance],
		cultist.is_sieging() and absf(left - CULTIST.siege_distance) < 4.0)
	var before: int = fortress.health.current_health
	var position: Vector2 = cultist.global_position
	var bolt: EnemyBolt = await _next_bolt(cultist)
	_check("lane %d: it shoots at the fortress (fortress-hitbox shot)" % lane, bolt != null and bolt.collision_layer == EnemyBolt.FORTRESS_SHOT_LAYER)
	await _frames(90)
	_check("lane %d: the shot hits the fortress (-%d HP)" % [lane, before - fortress.health.current_health],
		fortress.health.current_health == before - CULTIST.siege_damage)
	await _frames(60 * 4)
	_check("lane %d: it keeps shooting from the same spot (%d HP lost)" % [lane, before - fortress.health.current_health],
		fortress.health.current_health <= before - CULTIST.siege_damage * 3 and cultist.global_position.distance_to(position) < 1.0)
	level.free()


func _test_hero_targeting() -> void:
	var level: Level = await _level(0)
	var cultist: Enemy = await _first_enemy(level)
	var fortress: Fortress = level.get_node("Fortress")
	var hero: Hero = level.get_node("Hero")
	for _i: int in 60 * 30:
		await physics_frame
		if cultist.is_sieging():
			break
	# The hero walks up to it (not into melee): it turns on the hero.
	hero.global_position = cultist.global_position + Vector2(-60, 90)
	await _frames(70)
	_check("the hero within range: it targets the hero, not the fortress", cultist.has_target() and not cultist.is_sieging())
	var limit: AttackerLimit = AttackerLimit.find_on(hero)
	var fortress_hp: int = fortress.health.current_health
	var hero_hp: int = hero.health.current_health
	var bolt: EnemyBolt = await _next_bolt(cultist)
	_check("it takes no melee attacker slot (%d)" % limit.get_attacker_count(), limit.get_attacker_count() == 0)
	_check("its shot is aimed at the hero (enemy-hitbox shot)", bolt != null and bolt.collision_layer == EnemyBolt.HERO_SHOT_LAYER)
	await _frames(60)
	_check("the shot hits a hero who stands still (-%d HP)" % (hero_hp - hero.health.current_health), hero.health.current_health == hero_hp - CULTIST.hero_damage)
	_check("meanwhile the fortress is left alone", fortress.health.current_health == fortress_hp)
	# Dodge: step aside as soon as the shot is cast.
	hero_hp = hero.health.current_health
	bolt = await _next_bolt(cultist)
	hero.global_position += Vector2(70, 0)
	await _frames(90)
	_check("a shot can be dodged: it flies straight to where the hero was (HP %d -> %d)" % [hero_hp, hero.health.current_health],
		hero.health.current_health == hero_hp and (not is_instance_valid(bolt) or bolt.is_spent()))
	# Dash through a shot: immune.
	hero_hp = hero.health.current_health
	hero.global_position -= Vector2(70, 0)
	await _frames(10)
	bolt = await _next_bolt(cultist)
	for _i: int in 120:
		if bolt.global_position.distance_to(hero.global_position) < 70.0:
			break
		await physics_frame
	# Straight into the shot (toward the Cultist): it passes through the hero.
	hero.dash(cultist.global_position - hero.global_position)
	await _frames(12)
	var flew_on: bool = not bolt.is_spent()
	await _frames(30)
	_check("a hero dashing through a shot is immune, the shot flies on (HP %d -> %d)" % [hero_hp, hero.health.current_health],
		hero.health.current_health == hero_hp and flew_on)
	# The hero walks away: back to the fortress.
	hero.global_position = HERO_AWAY
	await _frames(10)
	_check("the hero gone: it shoots the fortress again", not cultist.has_target() and cultist.is_sieging())
	fortress_hp = fortress.health.current_health
	await _frames(60 * 3)
	_check("...and hits it (%d HP lost)" % (fortress_hp - fortress.health.current_health), fortress.health.current_health < fortress_hp)
	# Fragile: two sword swings.
	hero.global_position = cultist.global_position + Vector2(-30, 0)
	await _frames(2)
	for _i: int in 2:
		hero.attack(cultist.global_position)
		await _frames(30)
	_check("two sword swings kill it", not is_instance_valid(cultist) or not cultist.is_alive())
	await _frames(2)
	_check("its shots die with it", level.find_children("*", "EnemyBolt", true, false).filter(
		func(b: Node) -> bool: return not b.is_queued_for_deletion()).is_empty())
	level.free()


## Mid-lane, the hero in range stops it; once the hero leaves it walks on.
func _test_mid_lane() -> void:
	var level: Level = await _level(2)
	var cultist: Enemy = await _first_enemy(level)
	var hero: Hero = level.get_node("Hero")
	await _frames(60)
	hero.global_position = cultist.global_position + Vector2(100, 60)
	await _frames(20)
	var progress: float = cultist.get_lane_progress()
	await _frames(60)
	_check("mid-lane, the hero in range stops it (moved %.1f px along the lane)" % (cultist.get_lane_progress() - progress),
		cultist.has_target() and cultist.get_lane_progress() - progress < 1.0)
	hero.global_position = HERO_AWAY
	await _frames(60)
	_check("the hero gone, it walks on (%.0f px/s)" % cultist.velocity.length(), cultist.velocity.length() > CULTIST.move_speed * 0.9)
	level.free()


## A level whose only wave is one Cultist on `lane` (started), the hero parked far away.
func _level(lane: int) -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = [WaveFixtures.make_wave(1, 1.0, CULTIST, lane), WaveData.new()]
	spawner.autostart = true
	WaveFixtures.no_upgrades(level)
	(level.get_node("Hero") as Node2D).position = HERO_AWAY
	root.add_child(level)
	await _frames(2)
	return level


func _first_enemy(level: Level) -> Enemy:
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	for _i: int in 120:
		for child: Node in spawner.get_children():
			if child is Enemy:
				return child
		await physics_frame
	return null


## Waits for the enemy's next shot to leave its hands.
func _next_bolt(enemy: Enemy) -> EnemyBolt:
	var known: Array[Node] = enemy.find_children("*", "EnemyBolt", false, false)
	for _i: int in 60 * 4:
		await physics_frame
		if not is_instance_valid(enemy):
			return null
		for bolt: Node in enemy.find_children("*", "EnemyBolt", false, false):
			if not known.has(bolt) and not (bolt as EnemyBolt).is_spent():
				return bolt
	return null


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
