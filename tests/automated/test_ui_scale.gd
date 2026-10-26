extends SceneTree
## Automated check for the interface size setting (M13 playtest: "UI too big"): GameSettings keeps 70-120%
## (saved, clamped, in 5% steps); UiScaleDirector moves each UI layer's controls into a scaled frame laid
## out at viewport / factor, so the HUD's corners and the menus' backdrops still meet the screen's real
## corners and edges; layers made later (a new chapter's HUD) get it too; 100% restores the full size.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const SETTINGS_FILE: String = "user://test_ui_scale.cfg"

var _failures: int = 0


func _initialize() -> void:
	GameSettings.path = SETTINGS_FILE
	GameSettings.load_and_apply()
	_check("default is 100%", is_equal_approx(GameSettings.get_ui_scale(), 1.0))
	GameSettings.set_ui_scale(2.0)
	_check("clamped to 120%", is_equal_approx(GameSettings.get_ui_scale(), 1.2))
	GameSettings.set_ui_scale(0.1)
	_check("clamped to 70%", is_equal_approx(GameSettings.get_ui_scale(), 0.7))
	GameSettings.set_ui_scale(0.83)
	_check("snapped to 5%% steps (%.2f)" % GameSettings.get_ui_scale(), is_equal_approx(GameSettings.get_ui_scale(), 0.85))
	GameSettings.load_and_apply()
	_check("saved and loaded", is_equal_approx(GameSettings.get_ui_scale(), 0.85))
	GameSettings.set_ui_scale(1.0)

	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(3)
	var level: Level = await MapFixtures.enter_first_battle(main)
	await _frames(3)
	var hud: CanvasLayer = level.get_node("HUD")
	var pause: CanvasLayer = main.get_node("%PauseMenu")
	_check("at 100% no layer has a frame", UiScaleDirector.frame_of(hud) == null and UiScaleDirector.frame_of(pause) == null)
	var screen: Vector2 = root.get_visible_rect().size

	for factor: float in [0.7, 1.2]:
		GameSettings.set_ui_scale(factor)
		await _frames(3)
		var frame: UiScaleFrame = UiScaleDirector.frame_of(pause)
		_check("%.0f%%: the pause menu has a frame of viewport / factor, drawn scaled" % (factor * 100.0),
			frame != null and frame.size.is_equal_approx(screen / factor) and frame.scale.is_equal_approx(Vector2(factor, factor)))
		var dim: Control = pause.get_node("%Dim") if pause.has_node("%Dim") else frame.get_child(0) as Control
		_check("%.0f%%: its backdrop still covers the whole screen (%s)" % [factor * 100.0, dim.get_global_rect()],
			dim.get_global_rect().position.is_zero_approx() and dim.get_global_rect().size.is_equal_approx(screen))
		var hud_frame: UiScaleFrame = UiScaleDirector.frame_of(hud)
		var feed: Control = hud.get_node("%NotificationFeed") if hud.has_node("%NotificationFeed") else null
		_check("%.0f%%: the HUD has a frame" % (factor * 100.0), hud_frame != null and hud_frame.size.is_equal_approx(screen / factor))
		if feed != null:
			_check("%.0f%%: the top right feed still ends at the right edge (%.0f of %.0f)" % [factor * 100.0, feed.get_global_rect().end.x, screen.x],
				absf(feed.get_global_rect().end.x - screen.x) < 40.0)
		_check("%.0f%%: unique names still found" % (factor * 100.0), hud.get_node_or_null("%WaveButton") != null or hud.get_node_or_null("%SlotsLabel") != null)

	GameSettings.set_ui_scale(1.0)
	await _frames(3)
	var restored: UiScaleFrame = UiScaleDirector.frame_of(pause)
	_check("back to 100%: the frame is the full size at scale 1", restored != null and restored.size.is_equal_approx(screen) and restored.scale.is_equal_approx(Vector2.ONE))

	GameSettings.set_ui_scale(0.8)
	await _frames(3)
	var extra: Node = (load("res://ui/hints/hint_panel.tscn") as PackedScene).instantiate()
	main.add_child(extra)
	await _frames(3)
	_check("a layer made later gets the frame too", UiScaleDirector.frame_of(extra as CanvasLayer) != null)

	main.queue_free()
	await _frames(2)
	GameSettings.set_ui_scale(1.0)
	if FileAccess.file_exists(SETTINGS_FILE):
		DirAccess.remove_absolute(SETTINGS_FILE)
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
