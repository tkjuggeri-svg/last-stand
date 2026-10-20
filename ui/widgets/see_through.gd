class_name SeeThrough
extends Node
## Makes its parent Control see-through while a tracked world object (the hero) is behind it on screen,
## so the HUD never hides the player: the parent fades to faded_alpha and back, smoothly. Display only.

## Opacity of the parent while the target is behind it.
@export_range(0.0, 1.0) var faded_alpha: float = 0.3
## How fast the opacity follows (per second, exponential).
@export var fade_speed: float = 10.0
## The target's on-screen box around its origin (world px at zoom 1: the hero's body and head).
@export var target_box: Rect2 = Rect2(-16, -56, 32, 64)

var _target: Node2D


## Starts watching `target` (null stops: the parent is fully opaque again).
func track(target: Node2D) -> void:
	_target = target
	set_process(true)


func _ready() -> void:
	set_process(_target != null)


func _process(delta: float) -> void:
	var control: Control = get_parent() as Control
	if control == null:
		return
	var goal: float = faded_alpha if is_covering() else 1.0
	control.modulate.a = lerpf(control.modulate.a, goal, 1.0 - exp(-fade_speed * delta))


## True while the target's on-screen box overlaps the parent.
func is_covering() -> bool:
	var control: Control = get_parent() as Control
	if control == null or not is_instance_valid(_target) or not _target.is_inside_tree() or not _target.is_visible_in_tree():
		return false
	var to_screen: Transform2D = _target.get_global_transform_with_canvas()
	var box: Rect2 = to_screen * target_box
	return control.get_global_rect().intersects(box)
