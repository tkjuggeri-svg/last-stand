class_name HealthBar
extends HBoxContainer
## Shows a HealthComponent as "<title> [bar] current / max". Read-only: it never changes health.

@export var title: String = "HP"
@export var fill_color: Color = Color(0.7, 0.2, 0.2, 1)

var _health: HealthComponent

@onready var _title_label: Label = %TitleLabel
@onready var _bar: ProgressBar = %Bar
@onready var _value_label: Label = %ValueLabel


func _ready() -> void:
	_title_label.text = title
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	_bar.add_theme_stylebox_override("fill", fill)


## Starts showing this HealthComponent and follows its changes.
func track(health: HealthComponent) -> void:
	if _health != null:
		_health.health_changed.disconnect(_on_health_changed)
	_health = health
	_health.health_changed.connect(_on_health_changed)
	_on_health_changed(_health.current_health, _health.max_health)


func _on_health_changed(current_health: int, max_health: int) -> void:
	_bar.max_value = max_health
	_bar.value = current_health
	_value_label.text = "%d / %d" % [current_health, max_health]
