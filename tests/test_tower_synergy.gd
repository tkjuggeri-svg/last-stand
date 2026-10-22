extends Node
## Sandbox (F6): the tower pair bonuses. Builds a Cannon and a Frost on neighbouring slots (each
## other's partners) and a Brazier beside an Archer, with gold to build more; open a tower's menu (E)
## to read its bonus and see the links to its partners.

const CANNON: TowerData = preload("res://data/towers/cannon.tres")
const FROST: TowerData = preload("res://data/towers/frost.tres")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const BRAZIER: TowerData = preload("res://data/towers/brazier.tres")

@onready var _level: Level = %Arena


func _ready() -> void:
	_level.economy.earn(3000, Economy.Source.REFUND)
	var slots: Array[BuildSlot] = _level.builder.get_slots()
	_level.builder.build(slots[2], CANNON)
	_level.builder.build(slots[4], FROST)
	_level.builder.build(slots[6], ARCHER)
	_level.builder.build(slots[7], BRAZIER)
