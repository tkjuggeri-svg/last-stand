class_name ScreenShake
extends Node
## Shakes its parent Camera2D (Juice.shake adds it): the strongest shake asked for wins, fading to
## nothing; the offset is whole pixels so the pixel grid holds. Runs on real time (a hit-stop doesn't
## freeze it) and stops while the game is paused. Display only.

## Longest real time one frame may count (after a pause).
const MAX_STEP: float = 0.05

var _strength: float = 0.0
var _duration: float = 0.0
var _left: float = 0.0
var _last_usec: int = 0


func _ready() -> void:
	_last_usec = Time.get_ticks_usec()


## Adds a shake of up to `strength` px over `seconds` (a weaker one during a stronger one changes nothing).
func add(strength: float, seconds: float) -> void:
	var current: float = _strength * (_left / _duration) if _left > 0.0 else 0.0
	if strength < current:
		return
	_strength = strength
	_duration = maxf(seconds, 0.01)
	_left = _duration


func is_shaking() -> bool:
	return _left > 0.0


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	var step: float = minf((now - _last_usec) / 1000000.0, MAX_STEP)
	_last_usec = now
	var camera: Camera2D = get_parent() as Camera2D
	if camera == null:
		return
	if _left <= 0.0:
		camera.offset = Vector2.ZERO
		return
	_left = maxf(_left - step, 0.0)
	var strength: float = _strength * (_left / _duration)
	camera.offset = (Vector2.from_angle(randf() * TAU) * strength).round()
