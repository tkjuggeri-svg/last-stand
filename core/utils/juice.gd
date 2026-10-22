class_name Juice
## Game feel helpers (M8.5), display only: a screen shake on the current camera (scaled by the
## player's Screen shake setting) and a hit-stop (time almost stops for a moment). No autoload: the
## camera gets a ScreenShake child the first time it shakes. Small hit-stops are skipped in headless
## runs, so tests and the balance tools stay deterministic.

## Time's speed during a hit-stop.
const STOP_SCALE: float = 0.05


## Shakes the view `context` is seen through: up to `strength` px, fading over `seconds`.
static func shake(context: Node, strength: float, seconds: float) -> void:
	if not is_instance_valid(context) or not context.is_inside_tree() or GameSettings.get_screen_shake() <= 0.0:
		return
	var camera: Camera2D = context.get_viewport().get_camera_2d()
	if camera == null:
		return
	var shaker: ScreenShake = camera.get_node_or_null(^"ScreenShake") as ScreenShake
	if shaker == null:
		shaker = ScreenShake.new()
		shaker.name = "ScreenShake"
		camera.add_child(shaker)
	shaker.add(strength * GameSettings.get_screen_shake(), seconds)


## Almost stops time for `seconds` (real time) at `scale` speed. Skipped while time already runs
## differently (the pause menu, another hit-stop) and, unless `headless_too`, in headless runs. The
## timer stops while the tree is paused, so the pause menu's own time handling is never undone.
static func hit_stop(context: Node, seconds: float, scale: float = STOP_SCALE, headless_too: bool = false) -> void:
	if not is_instance_valid(context) or not context.is_inside_tree() or not is_equal_approx(Engine.time_scale, 1.0):
		return
	if not headless_too and DisplayServer.get_name() == "headless":
		return
	Engine.time_scale = scale
	context.get_tree().create_timer(seconds, false, false, true).timeout.connect(func() -> void:
		if is_equal_approx(Engine.time_scale, scale):
			Engine.time_scale = 1.0)
