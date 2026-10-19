extends SceneTree
## Automated check for the hero's dash (HeroDash): the dash action moves the hero a short distance
## in the movement direction (or the last one, standing still), it is immune to hits while dashing,
## passes through enemies but not through walls or the fortress, and has a cooldown shown on the HUD.
## Also the dash upgrades: Fleet Step (shorter cooldown) and Cinder Dash (burning trail).
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const FLEET_STEP: UpgradeData = preload("res://data/upgrades/fleet_step.tres")
const CINDER_DASH: UpgradeData = preload("res://data/upgrades/cinder_dash.tres")
## Open ground south-west of the fortress, nothing in the way to the east for 150 px.
const OPEN_GROUND: Vector2 = Vector2(-220, 90)

var _failures: int = 0


func _initialize() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	WaveFixtures.no_upgrades(level)
	root.add_child(level)
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	var dash: HeroDash = hero.get_dash()
	var mods: RunModifiers = level.get_node("%RunModifiers")

	await _test_basic_dash(hero, dash)
	await _test_cooldown_and_hud(level, hero, dash)
	await _test_collisions(level, hero, dash)
	await _test_immunity(hero, dash)
	await _test_upgrades(level, hero, dash, mods)

	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	level.free()
	quit(_failures)


func _test_basic_dash(hero: Hero, dash: HeroDash) -> void:
	hero.global_position = OPEN_GROUND
	_check("the dash is ready at the start", dash.can_dash() and is_zero_approx(dash.get_cooldown_left()))
	Input.action_press("move_right")
	await _frames(3)
	var start: Vector2 = hero.global_position
	await _press_dash()
	_check("the dash key starts a dash (speed %.0f px/s, much faster than walking)" % hero.velocity.length(),
		dash.is_dashing() and hero.velocity.length() > 600.0)
	Input.action_release("move_right")
	await _until_dash_over(dash)
	var moved: Vector2 = hero.global_position - start
	_check("it goes in the movement direction, about %.0f px (moved %.0f, %.0f)" % [dash.distance, moved.x, moved.y],
		absf(moved.y) < 2.0 and moved.x > dash.distance - 10.0 and moved.x < dash.distance + 20.0)
	await _frames(2)
	_check("then the hero stops (no input)", hero.velocity.is_zero_approx())
	await _wait_ready(dash)
	start = hero.global_position
	hero.dash(Vector2.ZERO)
	await _until_dash_over(dash)
	moved = hero.global_position - start
	_check("standing still it dashes the way it last moved (moved %.0f, %.0f)" % [moved.x, moved.y], moved.x > dash.distance - 10.0)


func _test_cooldown_and_hud(level: Level, hero: Hero, dash: HeroDash) -> void:
	await _wait_ready(dash)
	hero.global_position = OPEN_GROUND
	var label: Label = level.get_node("HUD").find_child("DashLabel", true, false)
	var bar: ProgressBar = level.get_node("HUD").find_child("DashBar", true, false)
	await _frames(1)
	_check("HUD: the dash row says Ready (%s)" % label.text, label.text == "Ready" and is_equal_approx(bar.value, 1.0))
	_check("a dash starts", hero.dash(Vector2.UP))
	await _until_dash_over(dash)
	_check("a second dash right away does nothing (cooldown %.2f s left)" % dash.get_cooldown_left(),
		not hero.dash(Vector2.DOWN) and dash.get_cooldown_left() > 1.5)
	await _frames(30)
	_check("HUD: the cooldown counts down (%s, bar %.2f)" % [label.text, bar.value], label.text.ends_with(" s") and bar.value > 0.1 and bar.value < 0.9)
	await _frames(roundi((dash.cooldown - 0.16 - 0.5) * 60.0) - 6)
	_check("still cooling down just before %.0f s" % dash.cooldown, not dash.can_dash())
	await _frames(10)
	_check("ready again after %.0f s (HUD: %s)" % [dash.cooldown, label.text], dash.can_dash() and label.text == "Ready")


func _test_collisions(level: Level, hero: Hero, dash: HeroDash) -> void:
	await _wait_ready(dash)
	hero.global_position = OPEN_GROUND
	var ghoul: Enemy = ENEMY_SCENE.instantiate()
	ghoul.position = OPEN_GROUND + Vector2(50, 0)
	level.get_node("WaveSpawner").add_child(ghoul)
	await _frames(2)
	hero.dash(Vector2.RIGHT)
	await _until_dash_over(dash)
	_check("the dash passes through an enemy (hero x %.0f, enemy x %.0f)" % [hero.global_position.x, ghoul.global_position.x],
		hero.global_position.x > ghoul.global_position.x + 40.0)
	ghoul.free()
	await _wait_ready(dash)
	# The east wall's inner edge is the floor's right edge (x = 400); the hero's radius is 16.
	hero.global_position = Vector2(330, 200)
	hero.dash(Vector2.RIGHT)
	await _until_dash_over(dash)
	_check("it stops at the arena wall (x %.1f)" % hero.global_position.x, hero.global_position.x <= 385.0 and hero.global_position.x > 370.0)
	await _wait_ready(dash)
	# The fortress body is 96x96 around the origin.
	hero.global_position = Vector2(-140, 0)
	hero.dash(Vector2.RIGHT)
	await _until_dash_over(dash)
	_check("it stops at the fortress (x %.1f)" % hero.global_position.x, hero.global_position.x <= -63.0 and hero.global_position.x > -80.0)


func _test_immunity(hero: Hero, dash: HeroDash) -> void:
	await _wait_ready(dash)
	hero.global_position = OPEN_GROUND
	var claw: Hitbox = Hitbox.new()
	claw.damage = 10
	hero.add_child(claw)
	var hurtbox: Hurtbox = hero.get_node("%Hurtbox")
	var before: int = hero.health.current_health
	hero.dash(Vector2.RIGHT)
	await _frames(4)
	_check("hits are ignored while dashing", dash.is_dashing() and not hurtbox.receive_hit(claw) and hero.health.current_health == before)
	await _until_dash_over(dash)
	await _frames(roundi(dash.grace * 60.0) + 2)
	_check("a hit lands again after the dash", hurtbox.receive_hit(claw) and hero.health.current_health == before - 10)
	await _frames(40)
	hero.attack(hero.global_position + Vector2.LEFT * 50)
	await _wait_ready(dash)
	_check("a dash can start right after a swing", hero.dash(Vector2.RIGHT))
	await _frames(1)
	hero.attack(hero.global_position + Vector2.LEFT * 50)
	await _frames(1)
	_check("no sword swing starts in the middle of a dash", (hero.get_node("%AttackShape") as CollisionPolygon2D).disabled)
	await _until_dash_over(dash)
	hero.health.take_damage(hero.health.current_health)
	await _frames(1)
	await _wait_ready(dash)
	_check("a fallen hero can't dash", not hero.dash(Vector2.RIGHT))
	hero.revive(OPEN_GROUND)
	claw.queue_free()
	await _frames(2)


func _test_upgrades(level: Level, hero: Hero, dash: HeroDash, mods: RunModifiers) -> void:
	mods.add_upgrade(FLEET_STEP)
	_check("Fleet Step: the cooldown is 25%% shorter (%.2f s)" % dash.get_cooldown(), is_equal_approx(dash.get_cooldown(), dash.cooldown * 0.75))
	for _i: int in 4:
		mods.add_upgrade(FLEET_STEP)
	_check("stacked, it never goes below %.1f s (%.2f s)" % [dash.min_cooldown, dash.get_cooldown()], is_equal_approx(dash.get_cooldown(), dash.min_cooldown))
	await _wait_ready(dash)
	hero.global_position = OPEN_GROUND
	hero.dash(Vector2.RIGHT)
	await _until_dash_over(dash)
	_check("without Cinder Dash there is no trail", _burn_zones(hero).is_empty())
	mods.add_upgrade(CINDER_DASH)
	await _wait_ready(dash)
	hero.global_position = OPEN_GROUND
	var ghoul: Enemy = ENEMY_SCENE.instantiate()
	ghoul.position = OPEN_GROUND + Vector2(60, 0)
	level.get_node("WaveSpawner").add_child(ghoul)
	await _frames(2)
	var health: HealthComponent = ghoul.get_node("%HealthComponent")
	var hp: int = health.current_health
	hero.dash(Vector2.RIGHT)
	await _until_dash_over(dash)
	var zones: Array[BurnZone] = _burn_zones(hero)
	_check("Cinder Dash: burning patches along the path (%d)" % zones.size(), zones.size() >= 3)
	await _frames(60)
	var burnt: int = hp - health.current_health if is_instance_valid(ghoul) else hp
	_check("an enemy on the path burns (%d damage in about 1 s)" % burnt, burnt >= 10)
	await _frames(roundi(dash.trail_duration * 60.0) + 40)
	_check("the trail burns out", _burn_zones(hero).is_empty())
	if is_instance_valid(ghoul):
		ghoul.queue_free()


func _burn_zones(hero: Hero) -> Array[BurnZone]:
	var zones: Array[BurnZone] = []
	for child: Node in hero.get_children():
		if child is BurnZone and not child.is_queued_for_deletion():
			zones.append(child as BurnZone)
	return zones


func _press_dash() -> void:
	Input.action_press("dash")
	await physics_frame
	Input.action_release("dash")
	await physics_frame


func _until_dash_over(dash: HeroDash) -> void:
	for _i: int in 60:
		if not dash.is_dashing():
			return
		await physics_frame


func _wait_ready(dash: HeroDash) -> void:
	for _i: int in 300:
		if dash.can_dash():
			return
		await physics_frame


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
