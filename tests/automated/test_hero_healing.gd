extends SceneTree
## Automated check for the hero's healing between waves (HeroLives.heal_between_waves): a wounded
## hero is back to full HP when a wave is cleared, not before; a fallen hero isn't healed (it comes
## back by respawning), and lives never come back.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"

var _failures: int = 0


func _initialize() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = [WaveFixtures.make_wave(1, 1.0), WaveFixtures.make_wave(1, 1.0), WaveData.new()]
	WaveFixtures.no_upgrades(level)
	(level.get_node("Hero") as Node2D).position = Vector2(380, 380)
	root.add_child(level)
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	var lives: HeroLives = level.get_node("%HeroLives")
	await WaveFixtures.start_wave(level)
	hero.health.take_damage(40)
	await _frames(30)
	_check("during the wave the hero stays wounded (%d HP)" % hero.health.current_health, spawner.is_wave_active() and hero.health.current_health == 60)
	await _until_cleared(spawner)
	_check("the wave cleared: back to full HP (%d)" % hero.health.current_health, hero.health.current_health == hero.health.max_health)
	await WaveFixtures.start_wave(level)
	await _frames(90)
	hero.health.take_damage(hero.health.current_health)
	for child: Node in spawner.get_children():
		if child is Enemy:
			(child as Enemy).get_health().take_damage(1000)  # the wave ends while the hero is down
	await _frames(2)
	_check("a fallen hero isn't healed by a cleared wave (it respawns instead)", hero.health.is_dead())
	_check("...and the life stays lost (%d left)" % lives.get_lives_left(), lives.get_lives_left() == lives.lives - 1)
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	level.free()
	quit(_failures)


func _until_cleared(spawner: WaveSpawner) -> void:
	for _i: int in 60 * 40:
		if not spawner.is_wave_active():
			return
		await physics_frame


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
