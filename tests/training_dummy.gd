extends Node2D
## Test-only target: shows its HP and turns grey when it dies.

const DEAD_COLOR: Color = Color(0.3, 0.3, 0.3, 1)

@onready var _health: HealthComponent = %HealthComponent
@onready var _label: Label = %HealthLabel
@onready var _body: Polygon2D = %Body


func _ready() -> void:
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	_label.text = "%d / %d" % [_health.max_health, _health.max_health]


func _on_health_changed(current_health: int, max_health: int) -> void:
	_label.text = "%d / %d" % [current_health, max_health]


func _on_died() -> void:
	_label.text = "DEAD"
	_body.color = DEAD_COLOR
