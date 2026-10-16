class_name HealthComponent
extends Node
## Tracks hit points for any entity. The owner listens to the signals to react (update UI, die).

signal health_changed(current_health: int, max_health: int)
signal died

@export var max_health: int = 100

var current_health: int


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int) -> void:
	# Dead things can't die twice, so ignore hits after death.
	if is_dead() or amount <= 0:
		return
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()


func is_dead() -> bool:
	return current_health <= 0
