class_name TowerSilence
extends Node
## A tower's silence (a component of Tower): a Tollkeeper's toll stops it firing for a while. While
## silenced the tower is darkened and a cracked bell hangs over it; Tower asks is_silenced() before
## firing. It always wears off.

const SILENCED_TINT: Color = Color(0.45, 0.45, 0.55, 1)

## The tower's sprite (darkened while silenced) and the cracked-bell mark.
@export var sprite: CanvasItem
@export var mark: AnimatedSprite2D

var _left: float = 0.0


func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		_left = 0.0
		set_physics_process(false)
		sprite.self_modulate = Color.WHITE
		mark.hide()


## Silences the tower for `seconds` (the longest silence is kept).
func silence(seconds: float) -> void:
	if seconds <= 0.0:
		return
	_left = maxf(_left, seconds)
	set_physics_process(true)
	sprite.self_modulate = SILENCED_TINT
	mark.show()
	mark.play(&"silenced")


func is_silenced() -> bool:
	return _left > 0.0
