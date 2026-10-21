class_name ScreenFade
extends CanvasLayer
## The transition between the front-end screens and the game (M8's UI style): the screen fades to dark,
## the change happens, it fades back in. Owned by Main's front end (no autoload). Display only.

const FADE_TIME: float = 0.25

var _rect: ColorRect


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0.03, 0.02, 0.05, 1)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)


## Fades out, calls `change` at dark, fades back in. In headless runs (tests) it happens at once.
func transition(change: Callable) -> void:
	if DisplayServer.get_name() == "headless":
		change.call()
		return
	var tween: Tween = create_tween()
	tween.tween_property(_rect, "modulate:a", 1.0, FADE_TIME)
	tween.tween_callback(change)
	tween.tween_property(_rect, "modulate:a", 0.0, FADE_TIME)
