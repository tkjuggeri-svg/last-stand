class_name RegenAbility
extends EnemyAbility
## The Hollow Treant's mechanic: it mends itself `per_second` HP a second (a tough thing that must be
## burst down, not whittled). Never telegraphed.

@export var per_second: float = 1.0

var _carry: float = 0.0


func _can_start() -> bool:
	return false


func _ability_step(delta: float) -> void:
	_carry += per_second * delta
	if _carry >= 1.0:
		var amount: int = floori(_carry)
		_carry -= amount
		enemy.heal(amount)
