extends SceneTree
## Automated check for the HUD and the HealthBar widget, and the HUD's panels (bottom-left stats, wave,
## Quartermaster) turning see-through while the hero is behind them (SeeThrough).
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

var _failures: int = 0


func _initialize() -> void:
	await _test_hud_in_level()
	await _test_hud_alone()
	await _test_see_through()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_hud_in_level() -> void:
	# In test_hud.tscn the HUD is the FIRST child, so it becomes ready before the fortress and hero.
	var level: Node = (load("res://tests/test_hud.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var hud: CanvasLayer = level.get_node("HUD")
	var fortress: Fortress = level.get_node("Fortress")
	var hero: Hero = level.get_node("Hero")
	var fortress_bar: HealthBar = hud.get_node("%FortressBar")
	var hero_bar: HealthBar = hud.get_node("%HeroBar")
	await _frames(2)
	_check("HUD is first in the tree (ready-order case)", hud.get_index() == 0)
	_check("hero has 100 HP", hero.health != null and hero.health.current_health == 100)
	_check("both bars visible", fortress_bar.visible and hero_bar.visible)
	_check("fortress bar shows 100 / 100", _shows(fortress_bar, 100, 100))
	_check("hero bar shows 100 / 100", _shows(hero_bar, 100, 100))
	_check("bar titles", _text(fortress_bar, "%TitleLabel") == "Fortress" and _text(hero_bar, "%TitleLabel") == "Hero")

	fortress.health.take_damage(25)
	_check("fortress bar follows damage (75 / 100)", _shows(fortress_bar, 75, 100))
	hero.health.take_damage(40)
	_check("hero bar follows damage (60 / 100)", _shows(hero_bar, 60, 100))
	_check("bars are independent", _shows(fortress_bar, 75, 100))

	# End to end: the first ghoul walks the lane and hits the fortress (~14.4 s).
	var frames: int = 0
	while fortress.health.current_health == 75 and frames < 1200:
		await physics_frame
		frames += 1
	_check("ghoul hit shows on the HUD (65 / 100 after %.1f s)" % (frames / 60.0), _shows(fortress_bar, 65, 100))

	fortress.health.take_damage(500)
	_check("bar at 0 when destroyed (0 / 100)", _shows(fortress_bar, 0, 100))
	level.queue_free()
	await _frames(2)


func _test_hud_alone() -> void:
	var hud: CanvasLayer = (load("res://ui/hud/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await _frames(2)
	_check("HUD alone: bars hidden when nothing is assigned",
		not (hud.get_node("%FortressBar") as HealthBar).visible and not (hud.get_node("%HeroBar") as HealthBar).visible)
	hud.queue_free()
	await _frames(2)


func _test_see_through() -> void:
	root.size = Vector2i(1280, 720)  # headless runs start with another window size; the game's is 1280x720
	var level: Level = (load("res://levels/prototype_arena.tscn") as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	root.add_child(level)
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	var panel: Control = level.get_node("HUD").get_node("%SeeThrough").get_parent()
	var see_through: SeeThrough = level.get_node("HUD").get_node("%SeeThrough")
	var floor_rect: Rect2 = (level.get_node("%Floor") as Control).get_rect()
	# The camera stops at the arena's edge, so a hero in the bottom-left corner is under the panel.
	hero.global_position = floor_rect.position + Vector2(60, floor_rect.size.y - 40)
	await _frames(60)
	_check("hero behind the bottom-left panel: it turns see-through (alpha %.2f)" % panel.modulate.a,
		see_through.is_covering() and panel.modulate.a < see_through.faded_alpha + 0.05)
	hero.global_position = floor_rect.get_center()
	await _frames(60)
	_check("...and solid again when the hero leaves (alpha %.2f)" % panel.modulate.a, not see_through.is_covering() and panel.modulate.a > 0.95)
	# Top-left: the wave panel, and the Quartermaster panel under it (shown: the walls are damaged).
	var hud: Node = level.get_node("HUD")
	var wave_panel: Control = hud.get_node("%WaveSeeThrough").get_parent()
	var services: Control = hud.get_node("%ServicesPanel")
	(level.get_node("Fortress") as Fortress).health.take_damage(30)
	hero.global_position = floor_rect.position + Vector2(60, 40)
	await _frames(60)
	_check("hero behind the wave panel: it turns see-through (alpha %.2f), the Quartermaster's doesn't" % wave_panel.modulate.a,
		wave_panel.modulate.a < 0.35 and services.visible and services.modulate.a > 0.95)
	hero.global_position = floor_rect.position + Vector2(60, 200)
	await _frames(60)
	_check("hero behind the Quartermaster panel: it turns see-through (alpha %.2f), the wave panel is solid again" % services.modulate.a,
		services.modulate.a < 0.35 and wave_panel.modulate.a > 0.95)
	level.queue_free()
	await _frames(2)


func _shows(bar: HealthBar, current: int, maximum: int) -> bool:
	var progress: ProgressBar = bar.get_node("%Bar")
	return (_text(bar, "%ValueLabel") == "%d / %d" % [current, maximum]
		and is_equal_approx(progress.value, current) and is_equal_approx(progress.max_value, maximum))


func _text(bar: HealthBar, label_path: String) -> String:
	return (bar.get_node(label_path) as Label).text


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
