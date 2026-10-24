class_name Display
extends Node
## The game's window (the project's main scene): runs Main inside a SubViewport so the world's pixels
## stay even at any window size. With smooth scaling (GameSettings, on by default) it renders at the
## next whole multiple of the 1280x720 base and filters that down to the window ("sharp bilinear": at
## 1080p every art pixel is the same size, slightly soft, instead of every other row doubled). Without,
## it draws straight at the window's scale, like the project's canvas_items stretch. Main and everything
## in it see a viewport of the base size (widened to the window's aspect), as before; Main run on its
## own (tests, F6) keeps the plain stretch.

## What runs inside (Main; tools may clear it and add their own scene to get_game_viewport()).
@export var content: PackedScene = preload("res://main/main.tscn")

var _smooth: bool = false

@onready var _box: SubViewportContainer = %Box
@onready var _viewport: SubViewport = %Viewport


func _ready() -> void:
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	if content != null:
		_viewport.add_child(content.instantiate())
	get_window().size_changed.connect(_fit)
	_smooth = GameSettings.smooth_scaling()
	_fit()


func _process(_delta: float) -> void:
	# GameSettings is static (no signals): pick up a change made in the settings menu.
	if GameSettings.smooth_scaling() != _smooth:
		_smooth = GameSettings.smooth_scaling()
		_fit()


## The viewport the game runs in (also before _ready: a tool may fill it right after instancing).
func get_game_viewport() -> SubViewport:
	return get_node("%Viewport") as SubViewport


## The scale of the base resolution in the window (as the canvas_items stretch with expand), and the
## scale it is rendered at: a whole number when smoothing, so nearest-neighbour pixels stay even.
static func render_scale(window: Vector2, base: Vector2, smooth: bool) -> Vector2:
	var scale: float = minf(window.x / base.x, window.y / base.y)
	return Vector2(scale, maxf(ceilf(scale - 0.001), 1.0) if smooth else scale)


func _fit() -> void:
	var window: Vector2 = Vector2(get_window().size)
	if window.x < 1.0 or window.y < 1.0:
		return
	var base: Vector2 = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	var scales: Vector2 = render_scale(window, base, _smooth)
	var logical: Vector2 = (window / scales.x).round()
	_viewport.size_2d_override = Vector2i(logical)
	_box.size = (logical * scales.y).round()
	_box.scale = Vector2.ONE * (scales.x / scales.y)
	_box.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if scales.x != scales.y else CanvasItem.TEXTURE_FILTER_NEAREST
