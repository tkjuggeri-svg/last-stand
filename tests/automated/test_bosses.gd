extends SceneTree
## Automated check for the three bosses: their data (big HP, a mechanic, full animations), the HUD's
## big boss bar and banners, the big death moment (hit-stop, effect), and each mechanic with its
## telegraph: the Gravelord summons Ghouls (which join the wave), the Bone Colossus charges the hero
## (locked direction, dodgeable, stops at walls and the fortress, stunned after), the Lich Warden
## wards the enemies near it (absorbs damage, expires, never itself).
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const GRAVELORD: EnemyData = preload("res://data/enemies/gravelord.tres")
const COLOSSUS: EnemyData = preload("res://data/enemies/colossus.tres")
const LICH: EnemyData = preload("res://data/enemies/lich.tres")
const HERO_AWAY: Vector2 = Vector2(380, 380)
const ABILITY_ANIMS: Dictionary = {"The Gravelord": ["cast"], "The Bone Colossus": ["brace", "charge", "stun"], "The Lich Warden": ["cast"]}

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_gravelord()
	await _test_colossus()
	await _test_lich()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_data() -> void:
	for boss: EnemyData in [GRAVELORD, COLOSSUS, LICH]:
		var frames: SpriteFrames = boss.sprite_frames
		var anims: bool = true
		for state: String in ["idle", "walk", "attack"] + ABILITY_ANIMS[boss.display_name]:
			for facing: String in ["down", "up", "side"]:
				anims = anims and frames.has_animation(StringName("%s_%s" % [state, facing]))
		anims = anims and frames.has_animation(&"death")
		var strike: float = 6.0 / frames.get_animation_speed(&"attack_down")
		_check("%s: a boss with %d HP (> 20 Ghouls), a mechanic, every animation, its blow on the %.1f s wind-up"
			% [boss.display_name, boss.max_health, boss.attack_windup],
			boss.is_boss and boss.max_health >= GHOUL.max_health * 20 and boss.ability != null and anims
			and absf(strike - boss.attack_windup) < 0.02 and boss.death_effect != null)


# ---------------------------------------------------------------- Gravelord

func _test_gravelord() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = [WaveFixtures.make_wave(1, 1.0, GRAVELORD, 0), WaveData.new()]
	spawner.autostart = true
	WaveFixtures.no_upgrades(level)
	(level.get_node("Hero") as Node2D).position = HERO_AWAY
	root.add_child(level)
	var boss: Enemy = await _first_enemy(spawner)
	await _frames(2)
	var hud: Node = level.get_node("HUD")
	var bar_box: Control = hud.get_node("%BossMargin")
	var bar: ProgressBar = hud.get_node("%BossBar")
	var banner: Label = hud.get_node("%Banner")
	_check("HUD: the boss bar shows its name and full HP (%s)" % (hud.get_node("%BossName") as Label).text,
		bar_box.visible and (hud.get_node("%BossName") as Label).text == GRAVELORD.display_name and is_equal_approx(bar.value, bar.max_value))
	_check("HUD: a banner announces it (%s)" % banner.text, banner.visible and banner.text.contains("approaches"))
	_check("no small health bar over a boss's head", not (boss.get_node("%HealthBar") as CanvasItem).visible)
	var summon: SummonAbility = boss.find_children("*", "SummonAbility", false, false)[0]
	await _frames(roundi(summon.first_delay * 60.0) - 10)
	_check("no summon before %.0f s" % summon.first_delay, not summon.is_telegraphing() and spawner.get_wave_enemy_total() == 1)
	await _until(func() -> bool: return summon.is_telegraphing(), 30)
	var markers: Array[Node] = summon.find_children("*", "TelegraphMarker", false, false)
	var at: Vector2 = boss.global_position
	_check("telegraph: it stops and %d graves open on the ground" % markers.size(), summon.is_telegraphing() and markers.size() == summon.count)
	await _frames(roundi(summon.telegraph_time * 60.0) - 6)
	_check("...and stands still while they do (moved %.1f px)" % boss.global_position.distance_to(at), boss.global_position.distance_to(at) < 0.5)
	await _frames(10)
	var minions: Array[Enemy] = _enemies(spawner).filter(func(e: Enemy) -> bool: return e != boss)
	var near: bool = minions.all(func(e: Enemy) -> bool: return summon.get_spots().any(func(s: Vector2) -> bool: return e.global_position.distance_to(s) < 16.0))
	_check("then %d Ghouls climb out of the graves" % minions.size(), minions.size() == summon.count and near
		and minions.all(func(e: Enemy) -> bool: return e.data == GHOUL and e.lane == boss.lane))
	_check("they join the wave (total %d, left %d)" % [spawner.get_wave_enemy_total(), spawner.get_remaining_count()],
		spawner.get_wave_enemy_total() == 1 + summon.count and spawner.get_remaining_count() == 1 + summon.count)
	_check("the graves close", summon.find_children("*", "TelegraphMarker", false, false).all(func(m: Node) -> bool: return m.is_queued_for_deletion()))
	await _frames(30)
	_check("it walks on afterwards", boss.velocity.length() > 1.0)
	# The big moment.
	var health: HealthComponent = boss.get_health()
	health.take_damage(roundi(health.max_health * 0.5))
	await _frames(1)
	_check("HUD: the bar follows its HP (%.0f / %.0f)" % [bar.value, bar.max_value], is_equal_approx(bar.value, health.current_health))
	health.take_damage(health.max_health)
	await _frames(1)
	_check("its death slows time for a moment (time scale %.2f)" % Engine.time_scale, Engine.time_scale < 0.5)
	_check("...with its own big death effect", not level.get_node("%Effects").find_children("*", "", false, false).filter(
		func(n: Node) -> bool: return n.name.begins_with("GravelordDeathEffect")).is_empty())
	_check("HUD: banner '%s', the boss bar is gone" % banner.text, banner.text.contains("slain") and not bar_box.visible)
	await _frames(40)
	_check("time runs normally again (%.2f)" % Engine.time_scale, is_equal_approx(Engine.time_scale, 1.0))
	_check("the wave isn't over while its Ghouls live", spawner.is_wave_active())
	for minion: Enemy in _enemies(spawner):
		minion.get_health().take_damage(1000)
	await _frames(2)
	_check("...and is once they are gone", not spawner.is_wave_active())
	level.free()


# ---------------------------------------------------------------- Colossus

func _test_colossus() -> void:
	var level: Level = await _sandbox()
	var hero: Hero = level.get_node("Hero")
	var fortress: Fortress = level.get_node("Fortress")
	var boss: Enemy = await _place(level, COLOSSUS, Vector2(-500, 150))
	var charge: ChargeAbility = boss.find_children("*", "ChargeAbility", false, false)[0]
	await _frames(roundi(charge.first_delay * 60.0) + 30)
	_check("Colossus: no charge while the hero is far", not charge.is_telegraphing() and not charge.is_charging())
	hero.global_position = boss.global_position + Vector2(200, 0)
	await _until(func() -> bool: return charge.is_telegraphing(), 60)
	var markers: Array[Node] = charge.find_children("*", "TelegraphMarker", false, false)
	_check("the hero within %.0f px: it braces, a red arrow on the ground shows the path" % charge.trigger_range,
		charge.is_telegraphing() and markers.size() == 1 and (markers[0] as TelegraphMarker).shape == TelegraphMarker.Shape.ARROW)
	_check("the charge is aimed at the hero (direction %s)" % charge.get_direction(), charge.get_direction().dot(Vector2.RIGHT) > 0.99)
	var hp: int = hero.health.current_health
	var start: Vector2 = boss.global_position
	await _until(func() -> bool: return charge.is_charging(), 90)
	await _frames(3)
	_check("then it charges, fast (%.0f px/s)" % boss.velocity.length(), boss.velocity.length() > 400.0)
	await _until(func() -> bool: return charge.is_stunned(), 60)
	_check("a hero who stays put is run over (-%d HP)" % (hp - hero.health.current_health), hero.health.current_health == hp - charge.damage)
	_check("it runs past where the hero stood (%.0f px)" % boss.global_position.distance_to(start), boss.global_position.distance_to(start) > 220.0)
	var stunned_at: Vector2 = boss.global_position
	await _frames(roundi(charge.stun_time * 60.0) - 6)
	_check("then it stands stunned (moved %.1f px)" % boss.global_position.distance_to(stunned_at), charge.is_stunned() and boss.global_position.distance_to(stunned_at) < 0.5)
	# Sidestep: the direction is locked when the telegraph starts.
	await _until(func() -> bool: return not charge.is_busy(), 60)
	hero.global_position = boss.global_position + Vector2(-200, 0)
	hero.health.revive()
	await _until(func() -> bool: return charge.is_telegraphing(), 60 * 8)
	hero.global_position += Vector2(0, 110)
	hp = hero.health.current_health
	await _until(func() -> bool: return charge.is_stunned(), 120)
	_check("a hero who steps aside during the telegraph is missed (HP %d -> %d)" % [hp, hero.health.current_health], hero.health.current_health == hp)
	# Dash through it.
	await _until(func() -> bool: return not charge.is_busy(), 120)
	hero.global_position = boss.global_position + Vector2(200, 0)
	await _until(func() -> bool: return charge.is_charging(), 60 * 8)
	hp = hero.health.current_health
	hero.dash(boss.global_position - hero.global_position)
	await _until(func() -> bool: return charge.is_stunned(), 120)
	_check("a hero who dashes through the charge is immune (HP %d -> %d)" % [hp, hero.health.current_health], hero.health.current_health == hp)
	boss.free()
	# Walls and the fortress stop it.
	boss = await _place(level, COLOSSUS, Vector2(260, 200))
	charge = boss.find_children("*", "ChargeAbility", false, false)[0]
	hero.global_position = Vector2(360, 200)
	await _until(func() -> bool: return charge.is_stunned(), 60 * 6)
	_check("it stops before the arena wall (body edge at x %.0f, wall at 400)" % (boss.global_position.x + COLOSSUS.body_radius),
		charge.is_stunned() and boss.global_position.x + COLOSSUS.body_radius < 400.0)
	boss.free()
	var fortress_hp: int = fortress.health.current_health
	boss = await _place(level, COLOSSUS, Vector2(-260, 0))
	charge = boss.find_children("*", "ChargeAbility", false, false)[0]
	hero.global_position = Vector2(-100, 0)
	await _until(func() -> bool: return charge.is_stunned(), 60 * 6)
	_check("it stops before the fortress, still alive, the walls unharmed (body edge at x %.0f)" % (boss.global_position.x + COLOSSUS.body_radius),
		charge.is_stunned() and boss.is_alive() and boss.global_position.x + COLOSSUS.body_radius < -48.0 and fortress.health.current_health == fortress_hp)
	level.free()


# ---------------------------------------------------------------- Lich

func _test_lich() -> void:
	var level: Level = await _sandbox()
	var lich: Enemy = await _place(level, LICH, Vector2(-500, 150))
	var near: Enemy = await _place(level, GHOUL, Vector2(-400, 150))
	var far: Enemy = await _place(level, GHOUL, Vector2(-200, 150))
	var ward: WardAbility = lich.find_children("*", "WardAbility", false, false)[0]
	await _until(func() -> bool: return ward.is_telegraphing(), 60 * 5)
	var rings: Array[Node] = ward.find_children("*", "TelegraphMarker", false, false)
	_check("Lich: a rune circle of %.0f px is drawn on the ground first" % ward.radius,
		rings.size() == 1 and is_equal_approx((rings[0] as TelegraphMarker).size, ward.radius))
	_check("...no ward yet during it", near.get_health().get_shield() == 0)
	await _until(func() -> bool: return not ward.is_telegraphing(), 120)
	await _frames(1)
	_check("then the enemies inside are warded (%d), the ones outside not (%d), the Lich not itself (%d)"
		% [near.get_health().get_shield(), far.get_health().get_shield(), lich.get_health().get_shield()],
		near.get_health().get_shield() == ward.shield and far.get_health().get_shield() == 0 and lich.get_health().get_shield() == 0)
	_check("a warded enemy shows the bubble", (near.get_node("%ShieldBubble") as CanvasItem).visible and not (far.get_node("%ShieldBubble") as CanvasItem).visible)
	var hp: int = near.get_health().current_health
	near.get_health().take_damage(20)
	_check("the ward absorbs damage first (HP %d -> %d, ward %d)" % [hp, near.get_health().current_health, near.get_health().get_shield()],
		near.get_health().current_health == hp and near.get_health().get_shield() == ward.shield - 20)
	near.get_health().take_damage(50)
	_check("what gets through the ward hurts (HP %d)" % near.get_health().current_health, near.get_health().current_health == hp - 10 and near.get_health().get_shield() == 0)
	_check("a broken ward's bubble is gone", not (near.get_node("%ShieldBubble") as CanvasItem).visible)
	# A ward expires.
	await _until(func() -> bool: return far.get_health().get_shield() > 0 or ward.is_telegraphing(), 60 * 10)
	far.global_position = near.global_position
	await _until(func() -> bool: return far.get_health().get_shield() > 0, 60 * 10)
	var duration: float = ward.duration
	lich.free()
	await _frames(roundi(duration * 60.0) + 10)
	_check("a ward runs out after %.0f s" % duration, far.get_health().get_shield() == 0 and not (far.get_node("%ShieldBubble") as CanvasItem).visible)
	level.free()


# ---------------------------------------------------------------- helpers

## The arena with no waves running, the hero parked.
func _sandbox() -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new(), WaveData.new()]
	WaveFixtures.no_upgrades(level)
	(level.get_node("Hero") as Node2D).position = HERO_AWAY
	root.add_child(level)
	await _frames(2)
	return level


## An enemy standing at `at` (no lane: it stays there unless its ability moves it).
func _place(level: Level, data: EnemyData, at: Vector2) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = data
	enemy.position = at
	level.get_node("WaveSpawner").add_child(enemy)
	await _frames(2)
	return enemy


func _enemies(spawner: WaveSpawner) -> Array[Enemy]:
	var found: Array[Enemy] = []
	for child: Node in spawner.get_children():
		if child is Enemy and (child as Enemy).is_alive():
			found.append(child as Enemy)
	return found


func _first_enemy(spawner: WaveSpawner) -> Enemy:
	for _i: int in 120:
		if not _enemies(spawner).is_empty():
			return _enemies(spawner)[0]
		await physics_frame
	return null


func _until(condition: Callable, max_frames: int) -> void:
	for _i: int in max_frames:
		if condition.call():
			return
		await physics_frame


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
