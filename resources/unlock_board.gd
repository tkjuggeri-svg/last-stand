class_name UnlockBoard
extends Resource
## What a run has with nothing unlocked (the first run's kit), and every unlock in the War Room's order
## (M8; docs/M8_META.md 3.). Everything not in the starting kit and not unlocked stays out of runs:
## towers, evolutions, cards, relics, events. data/meta/unlock_board.tres.

@export var starter_towers: Array[TowerData] = []
@export var starter_cards: Array[UpgradeData] = []
@export var starter_relics: Array[RelicData] = []
@export var unlocks: Array[UnlockData] = []


func find(id: StringName) -> UnlockData:
	for unlock: UnlockData in unlocks:
		if unlock.id == id:
			return unlock
	return null
