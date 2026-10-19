class_name HealthComponent
extends Node
## Tracks hit points for any entity. The owner listens to the signals to react (update UI, die).

signal health_changed(current_health: int, max_health: int)
signal died

@export var max_health: int = 100

var current_health: int


func _ready() -> void:
	current_health = max_health


## Sets a new maximum and refills to it. Owners call this in _ready() when stats come from data.
func setup(new_max_health: int) -> void:
	max_health = new_max_health
	current_health = new_max_health


func take_damage(amount: int) -> void:
	# Dead things can't die twice, so ignore hits after death.
	if is_dead() or amount <= 0:
		return
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()


## Changes the maximum and moves current HP by the same amount (more max = that much more HP; less
## max = HP capped). Never kills: a living owner keeps at least 1 HP.
func set_max_health(new_max: int) -> void:
	new_max = maxi(new_max, 1)
	if new_max == max_health:
		return
	var alive: bool = not is_dead()
	current_health = clampi(current_health + new_max - max_health, 1 if alive else 0, new_max)
	max_health = new_max
	health_changed.emit(current_health, max_health)


## Heals by `amount` (never above max, never a dead owner).
func heal(amount: int) -> void:
	if is_dead() or amount <= 0 or current_health >= max_health:
		return
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


## Refills to max_health, also from 0 (the owner is brought back, e.g. a respawning hero).
func revive() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func is_dead() -> bool:
	return current_health <= 0
