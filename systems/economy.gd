class_name Economy
extends Node
## The player's gold for one run. Gold only changes through earn() and try_spend(), so it can
## never become negative. Display only reads it; game systems decide when gold is earned or spent.

signal gold_changed(gold: int)
signal gold_earned(amount: int, source: Source)

enum Source { KILL, PERFECT_DEFENSE, REFUND, INTEREST, REWARD }

@export var starting_gold: int = 100

var _gold: int = 0


func _ready() -> void:
	_gold = maxi(starting_gold, 0)


func get_gold() -> int:
	return _gold


func can_afford(cost: int) -> bool:
	return cost >= 0 and _gold >= cost


func earn(amount: int, source: Source) -> void:
	if amount <= 0:
		return
	_gold += amount
	gold_earned.emit(amount, source)
	gold_changed.emit(_gold)


## Spends the cost if there is enough gold. Returns false (and changes nothing) otherwise.
func try_spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	_gold -= cost
	gold_changed.emit(_gold)
	return true
