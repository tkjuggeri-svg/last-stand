class_name Fortress
extends StaticBody2D
## The structure the player defends. Enemies damage it through its Hurtbox; at 0 HP the run is lost.

signal destroyed

const DESTROYED_COLOR: Color = Color(0.2, 0.18, 0.2, 1)

## Public so other systems (HUD, game over) can read HP and connect to health_changed.
@onready var health: HealthComponent = %HealthComponent
@onready var _body: Polygon2D = %Body


func _ready() -> void:
	health.died.connect(_on_health_died)


func _on_health_died() -> void:
	_body.color = DESTROYED_COLOR
	destroyed.emit()
