class_name UiScaleFrame
extends Control
## Holds a UI layer's controls and draws them `factor` times as large: the frame is laid out at the
## viewport's size divided by the factor, then scaled up, so children anchored to the corners and
## edges still touch the real corners and edges. Made by UiScaleDirector; display only.

var _factor: float = 1.0


func _init() -> void:
	name = "ScaleFrame"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)


func _enter_tree() -> void:
	get_viewport().size_changed.connect(_fit)


func _exit_tree() -> void:
	get_viewport().size_changed.disconnect(_fit)


func set_factor(factor: float) -> void:
	_factor = factor
	_fit()


func get_factor() -> float:
	return _factor


func _fit() -> void:
	position = Vector2.ZERO
	scale = Vector2(_factor, _factor)
	size = get_viewport().get_visible_rect().size / _factor
