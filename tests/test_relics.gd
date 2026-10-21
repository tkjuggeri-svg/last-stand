extends Node2D
## Sandbox (F6): the graveyard arena with gold to build and a relic choice open at the start, to try
## relics by hand.

const ARENA: PackedScene = preload("res://levels/prototype_arena.tscn")
const SANDBOX_GOLD: int = 2000
const CHOICE_SIZE: int = 3


func _ready() -> void:
	var level: Level = ARENA.instantiate()
	add_child(level)
	level.economy.earn(SANDBOX_GOLD, Economy.Source.REFUND)
	level.offers.make_relic_offer(CHOICE_SIZE)
