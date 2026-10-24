extends SceneTree
## Automated check for Display (the main scene's window): Main runs inside its SubViewport, which sees
## the 1280x720 base (widened to the window's aspect); the render scale is a whole number with smooth scaling (2 at 1080p, drawn down to
## the window) and the window's own scale without; switching the setting refits it; a mouse click on
## the title's Play button reaches the button through the wrapper; positional sounds play in the
## game's viewport.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const SAVE_PATH: String = "user://test_display.json"
const SETTINGS_PATH: String = "user://test_display_settings.cfg"
const BASE: Vector2 = Vector2(1280, 720)

var _failures: int = 0


func _initialize() -> void:
	_clean()
	await process_frame
	GameSettings.path = SETTINGS_PATH
	var save: SaveManagerNode = root.get_node("/root/SaveManager") as SaveManagerNode
	save.use_file(SAVE_PATH)

	_check("1080p, smooth: rendered at 2x, drawn at 1.5x", Display.render_scale(Vector2(1920, 1080), BASE, true) == Vector2(1.5, 2.0))
	_check("1080p, crisp: drawn straight at 1.5x", Display.render_scale(Vector2(1920, 1080), BASE, false) == Vector2(1.5, 1.5))
	_check("1440p and 4K: whole scales either way", Display.render_scale(Vector2(2560, 1440), BASE, true) == Vector2(2, 2)
		and Display.render_scale(Vector2(3840, 2160), BASE, true) == Vector2(3, 3))
	_check("a window below 720p: rendered at 1x, drawn smaller", Display.render_scale(Vector2(1024, 576), BASE, true) == Vector2(0.8, 1.0))

	var display: Display = (load("res://main/display.tscn") as PackedScene).instantiate()
	root.add_child(display)
	await _frames(3)
	var viewport: SubViewport = display.get_node("%Viewport")
	var box: SubViewportContainer = display.get_node("%Box")
	var main: Node = viewport.get_child(0)
	_check("Main runs inside the SubViewport", main.name == &"Main" and main.get_viewport() == viewport)
	var visible_rect: Rect2 = viewport.get_visible_rect()
	_check("the game sees the base, widened to the window's aspect like the stretch (%s)" % visible_rect.size,
		is_equal_approx(minf(visible_rect.size.x / BASE.x, visible_rect.size.y / BASE.y), 1.0))

	GameSettings.set_smooth_scaling(false)
	await _frames(2)
	var crisp_filter: int = box.texture_filter
	GameSettings.set_smooth_scaling(true)
	await _frames(2)
	_check("switching the setting refits the view (nearest without smoothing)", crisp_filter == CanvasItem.TEXTURE_FILTER_NEAREST)

	var front: FrontEnd = main.get_node("%FrontEnd")
	var play: Button = front.get_title().get_play_button()
	var scales: Vector2 = Display.render_scale(Vector2(root.size), BASE, GameSettings.smooth_scaling())
	var at: Vector2 = box.position + play.get_global_rect().get_center() * scales.x
	_click(at)
	await _frames(3)
	_check("a click at Play's place in the window opens the War Room", front.get_hub().visible)

	Sfx.reset()
	var spot: Node2D = Node2D.new()
	viewport.add_child(spot)
	Sfx.play(spot, &"ui_click")
	_check("sounds are added to the game's viewport", root.find_children("*", "AudioStream*", false, false).is_empty())

	display.queue_free()
	await _frames(2)
	_clean()
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(_failures)


func _click(at: Vector2) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		Input.parse_input_event(event)
		Input.flush_buffered_events()


func _clean() -> void:
	for path: String in [SAVE_PATH, SAVE_PATH + ".bak", SETTINGS_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _check(label: String, ok: bool) -> void:
	print("[%s] %s" % ["ok" if ok else "FAIL", label])
	if not ok:
		_failures += 1
