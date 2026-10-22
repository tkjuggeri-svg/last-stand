extends SceneTree
## Automated check for the sound effects (M8.5): the library has every recipe's sound (a real WAV, on
## the SFX bus' mix), and every sound id named in the code and the data exists in it; sounds play at
## their moments (the hero's swing, a tower's shot, a kill, a boss arriving, a button, Game Over and
## Victory); a sound's voice limit and spacing hold back a flood; an unknown id is refused; headless,
## nothing is created (only logged).
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const LIBRARY: SfxLibrary = preload("res://data/audio/sfx_library.tres")
const ARENA: String = "res://levels/prototype_arena.tscn"
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const LICH: EnemyData = preload("res://data/enemies/lich.tres")
const SCAN_DIRS: Array[String] = ["res://entities", "res://ui", "res://main", "res://systems", "res://levels", "res://data"]

var _failures: int = 0


func _initialize() -> void:
	_test_library()
	_test_ids_used()
	await _test_moments()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_library() -> void:
	var complete: bool = LIBRARY.entries.size() == SfxRecipes.RECIPES.size()
	for id: StringName in SfxRecipes.RECIPES:
		var entry: SfxEntry = LIBRARY.find(id)
		complete = complete and entry != null and entry.stream != null and entry.stream.get_length() > 0.02 and entry.voices >= 1 \
			and entry.volume_db <= 0.0
	_check("the library: all %d recipes' sounds, each a real sound with its mix" % SfxRecipes.RECIPES.size(), complete)


func _test_ids_used() -> void:
	var pattern: RegEx = RegEx.create_from_string("(?:Sfx\\.play\\([^,]+, &\"|_sound = &\"|fire_sound = &\"|open_sound: StringName = &\"|open_sound = &\")([a-z_]+)\"")
	var unknown: Array[String] = []
	var found: int = 0
	for dir: String in SCAN_DIRS:
		for path: String in _files(dir):
			for match_: RegExMatch in pattern.search_all(FileAccess.get_file_as_string(path)):
				found += 1
				if LIBRARY.find(StringName(match_.get_string(1))) == null:
					unknown.append("%s in %s" % [match_.get_string(1), path.get_file()])
	_check("every sound named in the code and the data exists (%d uses)%s" % [found, (": missing " + ", ".join(unknown)) if not unknown.is_empty() else ""],
		unknown.is_empty() and found > 40)


func _test_moments() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveFixtures.make_wave(3, 0.3)]
	WaveFixtures.no_upgrades(level)
	root.add_child(level)
	await _frames(2)
	Sfx.reset()
	var hero: Hero = level.get_node("Hero")
	hero.attack(hero.global_position + Vector2(50, 0))
	_check("the hero's swing", Sfx.history.has(&"hero_swing"))
	level.economy.earn(500, Economy.Source.REFUND)
	var slot: BuildSlot = level.builder.get_slots()[3]
	level.builder.build(slot, ARCHER)
	level.run_cycle.start_wave()
	await _until(func() -> bool: return Sfx.history.has(&"archer_shot"), 60 * 20)
	_check("a wave's horn, an Archer's shot", Sfx.history.has(&"wave_start") and Sfx.history.has(&"archer_shot"))
	level.spawner.enemy_spawned.connect(func(e: Enemy) -> void: e.get_health().take_damage.call_deferred(100000))
	await _until(func() -> bool: return Sfx.history.has(&"enemy_death"), 60 * 20)
	_check("a kill", Sfx.history.has(&"enemy_death"))
	level.spawner.spawn_extra(LICH, 0)
	await _frames(2)
	_check("a boss arriving", Sfx.history.has(&"boss_appear"))
	Sfx.reset()
	var accepted: int = 0
	for _i: int in 10:
		accepted += 1 if Sfx.play(level, &"enemy_death") else 0
	_check("ten deaths in one frame: one sound (%d), the rest held back" % accepted, accepted == 1)
	_check("an unknown sound is not in the library (play() refuses it with a warning)", not Sfx.has(&"no_such_sound") and Sfx.has(&"enemy_death"))
	_check("headless: no player is created", root.find_children("*", "AudioStreamPlayer", false, false).is_empty()
		and root.find_children("*", "AudioStreamPlayer2D", false, false).is_empty())
	level.queue_free()
	await _frames(2)
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(3)
	Sfx.reset()
	(main.get_node("%PauseMenu") as PauseMenu).open()
	(main.get_node("%PauseMenu").get_node("%ResumeButton") as Button).pressed.emit()
	(main.get_node("%PauseMenu").get_node("%SettingsButton") as Button).pressed.emit()
	_check("buttons: the main action confirms, the others click", Sfx.history.has(&"ui_confirm") and Sfx.history.has(&"ui_click"))
	(main.get_node("%PauseMenu") as PauseMenu).close()
	(main.get_node("%GameOverScreen") as GameOverScreen).open("x", 1)
	(main.get_node("%VictoryScreen") as VictoryScreen).open("x", 1)
	_check("Game Over and Victory have their jingles", Sfx.history.has(&"game_over") and Sfx.history.has(&"victory"))
	main.queue_free()
	await _frames(2)


func _files(dir: String) -> Array[String]:
	var found: Array[String] = []
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".gd") or file.ends_with(".tscn") or file.ends_with(".tres"):
			found.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_files(dir.path_join(sub)))
	return found


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
