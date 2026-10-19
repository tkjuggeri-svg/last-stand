extends SceneTree
## Automated check for the pause menu and the settings: Esc pauses and the game is truly frozen
## (enemies, wave clock, hero, dash cooldown, animations), Esc or Resume goes on, Esc closes an open
## build menu instead and does nothing during the upgrade choice; Restart and Quit; settings change
## the window mode and the audio buses' volumes, rebind keys (a key moves off the action it had,
## Esc cancels, reset restores the defaults), are saved and loaded at startup.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const MAIN: String = "res://main/main.tscn"
const SETTINGS_PATH: String = "user://test_settings.cfg"

var _failures: int = 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	GameSettings.path = SETTINGS_PATH
	var main: Node = (load(MAIN) as PackedScene).instantiate()
	root.add_child(main)
	await _frames(3)
	var menu: PauseMenu = main.get_node("%PauseMenu")
	await _test_freeze(main, menu)
	await _test_esc_rules(main, menu)
	await _test_settings(menu)
	await _test_bindings(menu)
	await _test_restart_and_quit(main, menu)
	main.free()
	await _test_load_at_startup()
	GameSettings.reset_bindings()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _level(main: Node) -> Level:
	for child: Node in main.get_children():
		if child is Level and not child.is_queued_for_deletion():
			return child
	return null


func _test_freeze(main: Node, menu: PauseMenu) -> void:
	var level: Level = _level(main)
	WaveFixtures.no_upgrades(level)
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = [WaveFixtures.make_wave(6, 1.0), WaveData.new()]
	await WaveFixtures.start_wave(level)
	await _frames(150)
	var hero: Hero = level.get_node("Hero")
	hero.dash(Vector2.LEFT)
	await _frames(20)
	await _key(KEY_ESCAPE)
	_check("Esc opens the pause menu", menu.is_open() and paused)
	var enemies: Array[Enemy] = _enemies(spawner)
	var positions: Array[Vector2] = []
	for enemy: Enemy in enemies:
		positions.append(enemy.global_position)
	var spawned: int = spawner.get_spawned_count()
	var cooldown: float = hero.get_dash().get_cooldown_left()
	var hero_at: Vector2 = hero.global_position
	var sprite: AnimatedSprite2D = hero.get_node("%Sprite")
	var frame_progress: float = sprite.frame_progress + sprite.frame
	Input.action_press("move_right")
	await _frames(120)
	var still: bool = true
	for i: int in enemies.size():
		still = still and is_instance_valid(enemies[i]) and enemies[i].global_position == positions[i]
	_check("frozen: %d enemies stand still, none spawn (%d)" % [enemies.size(), spawner.get_spawned_count()],
		enemies.size() > 0 and still and spawner.get_spawned_count() == spawned)
	_check("frozen: the hero ignores input (moved %.1f px)" % hero.global_position.distance_to(hero_at), hero.global_position == hero_at)
	_check("frozen: the dash cooldown stops (%.2f s)" % hero.get_dash().get_cooldown_left(), is_equal_approx(hero.get_dash().get_cooldown_left(), cooldown))
	_check("frozen: even the always-running hero sprite stops animating", is_equal_approx(sprite.frame_progress + sprite.frame, frame_progress))
	Input.action_release("move_right")
	await _key(KEY_ESCAPE)
	_check("Esc again: resumed (time scale %.1f)" % Engine.time_scale, not menu.is_open() and not paused and is_equal_approx(Engine.time_scale, 1.0))
	await _frames(30)
	_check("...and the enemies move again", enemies.any(func(e: Enemy) -> bool: return is_instance_valid(e) and e.global_position != positions[enemies.find(e)]))
	await _key(KEY_ESCAPE)
	(menu.get_node("%ResumeButton") as Button).pressed.emit()
	await _frames(2)
	_check("Resume button: resumed", not menu.is_open() and not paused)


func _test_esc_rules(main: Node, menu: PauseMenu) -> void:
	var level: Level = _level(main)
	var hero: Hero = level.get_node("Hero")
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var build_menu: Node = level.get_node("BuildMenu")
	hero.global_position = builder.get_slots()[5].global_position + Vector2(0, 44)
	await _frames(10)
	await _action("interact")
	await _frames(3)
	var open_before: bool = build_menu.call("is_open")
	await _key(KEY_ESCAPE)
	_check("with the build menu open, Esc closes it and doesn't pause", open_before and not build_menu.call("is_open") and not menu.is_open() and not paused)
	# The upgrade choice holds the game: Esc must not open (or end) a pause over it.
	var screen: UpgradeChoiceScreen = level.get_node("UpgradeChoiceScreen")
	var offers: UpgradeOffers = level.get_node("%UpgradeOffers")
	offers.pool = [load("res://data/upgrades/honed_blade.tres"), load("res://data/upgrades/masonry.tres")]
	offers.make_offer()
	await _frames(2)
	await _key(KEY_ESCAPE)
	_check("during the upgrade choice Esc doesn't open the pause menu", screen.is_open() and paused and not menu.is_open())
	offers.pick(0)
	await _frames(2)
	_check("...and the choice still ends its own pause", not paused)


func _test_settings(menu: PauseMenu) -> void:
	await _key(KEY_ESCAPE)
	(menu.get_node("%SettingsButton") as Button).pressed.emit()
	await _frames(2)
	var settings: SettingsMenu = menu.get_node("%SettingsMenu")
	_check("Settings opens inside the pause menu", settings.visible and not (menu.get_node("%Buttons") as Control).visible)
	_check("the audio buses exist: Master, Music, SFX",
		AudioServer.get_bus_index(&"Music") > 0 and AudioServer.get_bus_index(&"SFX") > 0 and AudioServer.get_bus_index(&"Master") == 0)
	(settings.get_node("%MusicSlider") as HSlider).value = 50.0
	(settings.get_node("%SfxSlider") as HSlider).value = 0.0
	var music_db: float = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music"))
	_check("the Music slider sets the bus volume (50%% = %.1f dB)" % music_db, is_equal_approx(music_db, linear_to_db(0.5)))
	_check("SFX at 0 mutes its bus", AudioServer.is_bus_mute(AudioServer.get_bus_index(&"SFX")))
	(settings.get_node("%Fullscreen") as CheckButton).button_pressed = true
	_check("the fullscreen toggle switches the setting", GameSettings.is_fullscreen())
	var config: ConfigFile = ConfigFile.new()
	_check("saved at once to %s" % SETTINGS_PATH, config.load(SETTINGS_PATH) == OK and is_equal_approx(float(config.get_value("audio", "Music", 1.0)), 0.5)
		and bool(config.get_value("display", "fullscreen", false)))
	(settings.get_node("%Fullscreen") as CheckButton).button_pressed = false
	await _key(KEY_ESCAPE)
	_check("Esc in the settings goes back to the pause menu", not settings.visible and menu.is_open() and (menu.get_node("%Buttons") as Control).visible)


func _test_bindings(menu: PauseMenu) -> void:
	(menu.get_node("%SettingsButton") as Button).pressed.emit()
	await _frames(2)
	var settings: SettingsMenu = menu.get_node("%SettingsMenu")
	var dash_button: Button = settings.get_binding_button(&"dash", 0)
	_check("every action is listed with its bindings (dash: %s)" % dash_button.text,
		GameSettings.ACTIONS.all(func(a: StringName) -> bool: return settings.get_binding_button(a, 0) != null) and dash_button.text == "Space")
	dash_button.pressed.emit()
	_check("clicking a binding waits for a key", settings.is_listening() and dash_button.text == SettingsMenu.WAITING_TEXT)
	await _key(KEY_Q)
	_check("pressing Q binds the dash to Q", _has_key(&"dash", KEY_Q) and not _has_key(&"dash", KEY_SPACE) and _has_key(&"dash", KEY_SHIFT))
	_check("the binding is live: Q triggers the dash action", await _triggers(KEY_Q, &"dash"))
	settings.get_binding_button(&"dash", 1).pressed.emit()
	await _key(KEY_W)
	_check("a key taken from another action leaves it (W: dash, not move up)", _has_key(&"dash", KEY_W) and not _has_key(&"move_up", KEY_W))
	settings.get_binding_button(&"attack", 0).pressed.emit()
	await _key(KEY_ESCAPE)
	_check("Esc cancels a rebind (attack stays on the mouse)", not settings.is_listening() and settings.visible
		and InputMap.action_get_events(&"attack").any(func(e: InputEvent) -> bool: return e is InputEventMouseButton))
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	_check("bindings are saved", (config.get_value("bindings", "dash", []) as Array).has("key:%d" % KEY_Q))
	(settings.get_node("%ResetButton") as Button).pressed.emit()
	_check("Reset controls restores the defaults", _has_key(&"dash", KEY_SPACE) and _has_key(&"move_up", KEY_W) and not _has_key(&"dash", KEY_Q))
	settings.get_binding_button(&"dash", 0).pressed.emit()
	await _key(KEY_Q)  # saved for the startup check
	settings.close()
	(menu.get_node("%ResumeButton") as Button).pressed.emit()
	await _frames(2)


func _test_restart_and_quit(main: Node, menu: PauseMenu) -> void:
	var old: Level = _level(main)
	await _key(KEY_ESCAPE)
	(menu.get_node("%RestartButton") as Button).pressed.emit()
	await _frames(3)
	var fresh: Level = _level(main)
	_check("Restart: a fresh run, unpaused, menu closed", fresh != null and fresh != old and not paused and not menu.is_open()
		and (fresh.get_node("%RunCycle") as RunCycle).get_current_wave_number() == 1)
	var quit_asked: Array[bool] = [false]
	menu.quit_requested.disconnect(main.quit_game)  # the test must not end here
	menu.quit_requested.connect(func() -> void: quit_asked[0] = true)
	await _key(KEY_ESCAPE)
	(menu.get_node("%QuitButton") as Button).pressed.emit()
	_check("Quit asks Main to quit the game", quit_asked[0])
	menu.close()


## A new Main loads the saved settings: the dash on Q, music at 50%.
func _test_load_at_startup() -> void:
	GameSettings.reset_bindings()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"), 0.0)
	var main: Node = (load(MAIN) as PackedScene).instantiate()
	root.add_child(main)
	await _frames(2)
	_check("settings are loaded at startup (dash on Q, music %.1f dB)" % AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music")),
		_has_key(&"dash", KEY_Q) and is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music")), linear_to_db(0.5)))
	main.free()


func _has_key(action: StringName, key: Key) -> bool:
	return InputMap.action_get_events(action).any(func(e: InputEvent) -> bool:
		return e is InputEventKey and (e as InputEventKey).physical_keycode == key)


func _triggers(key: Key, action: StringName) -> bool:
	var press: InputEventKey = InputEventKey.new()
	press.physical_keycode = key
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var on: bool = Input.is_action_pressed(action)
	var release: InputEventKey = press.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	return on


## A key press and release through the real input pipeline.
func _key(key: Key) -> void:
	var press: InputEventKey = InputEventKey.new()
	press.physical_keycode = key
	press.keycode = key
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release: InputEventKey = press.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	await process_frame


func _action(action: StringName) -> void:
	var press: InputEventAction = InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release: InputEventAction = press.duplicate() as InputEventAction
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _enemies(spawner: WaveSpawner) -> Array[Enemy]:
	var found: Array[Enemy] = []
	for child: Node in spawner.get_children():
		if child is Enemy and (child as Enemy).is_alive():
			found.append(child as Enemy)
	return found


func _frames(count: int) -> void:
	for _i: int in count:
		await process_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
