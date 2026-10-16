class_name Fortress
extends StaticBody2D
## The structure the player defends. Enemies damage it through its Hurtbox; at 0 HP the run is lost.
## Its sprite shows how damaged it is: healthy, damaged (<= 2/3 HP), badly damaged (<= 1/3), destroyed.

signal destroyed

enum Look { HEALTHY, DAMAGED, BADLY_DAMAGED, DESTROYED }

## Public so other systems (HUD, game over) can read HP and connect to health_changed.
@onready var health: HealthComponent = %HealthComponent
@onready var _sprite: Sprite2D = %Sprite


func _ready() -> void:
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_health_died)
	_sprite.frame = look_for(health.current_health, health.max_health)


## Which sprite frame (a Look) fits this much health.
static func look_for(current_health: int, max_health: int) -> Look:
	if current_health <= 0:
		return Look.DESTROYED
	var ratio: float = float(current_health) / float(max_health)
	if ratio > 2.0 / 3.0:
		return Look.HEALTHY
	if ratio > 1.0 / 3.0:
		return Look.DAMAGED
	return Look.BADLY_DAMAGED


func _on_health_changed(current_health: int, max_health: int) -> void:
	_sprite.frame = look_for(current_health, max_health)


func _on_health_died() -> void:
	destroyed.emit()
