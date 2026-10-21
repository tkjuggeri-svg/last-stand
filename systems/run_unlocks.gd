class_name RunUnlocks
extends RefCounted
## What a run may use, from the unlock board and the profile (M8): the towers in the build menu, the
## towers that may evolve, the card and relic pools, the events that may come up, the perks. Made when
## a run starts (RunState holds it) and applied to each chapter's level (Level.apply_unlocks). With
## everything unlocked (tests, tools) nothing is held back.

## Null: every tower / card / relic of the level's own lists.
var towers: Array[TowerData] = []
var cards: Array[UpgradeData] = []
var relics: Array[RelicData] = []
## Towers that may evolve (their ids).
var evolving: Array[StringName] = []
## Events that must not come up on the map (not unlocked yet).
var locked_events: Array[EventData] = []
var perks: Array[StringName] = []
## Nothing is held back.
var everything: bool = false


static func for_profile(board: UnlockBoard, profile: SaveProfile) -> RunUnlocks:
	var run: RunUnlocks = RunUnlocks.new()
	run.everything = profile == null or profile.unlock_everything or board == null
	if board == null:
		return run
	run.towers = board.starter_towers.duplicate()
	run.cards = board.starter_cards.duplicate()
	run.relics = board.starter_relics.duplicate()
	for unlock: UnlockData in board.unlocks:
		if run.everything or profile.has_unlock(String(unlock.id)):
			run.towers.append_array(unlock.towers)
			run.cards.append_array(unlock.cards)
			run.relics.append_array(unlock.relics)
			for tower: TowerData in unlock.evolutions:
				run.evolving.append(tower.id)
			# Perks change how a run plays (a starting choice, a free reroll): only when really bought,
			# never from "everything unlocked" (tests and tools play the plain game).
			if unlock.perk != &"" and profile != null and profile.unlocks.has(String(unlock.id)):
				run.perks.append(unlock.perk)
		else:
			run.locked_events.append_array(unlock.events)
	return run


func has_perk(perk: StringName) -> bool:
	return perks.has(perk)


## `pool` without what this run doesn't have (kept in its order).
func filter_towers(pool: Array[TowerData]) -> Array[TowerData]:
	return pool if everything else pool.filter(func(t: TowerData) -> bool: return towers.has(t))


func filter_cards(pool: Array[UpgradeData]) -> Array[UpgradeData]:
	return pool if everything else pool.filter(func(c: UpgradeData) -> bool: return cards.has(c))


func filter_relics(pool: Array[RelicData]) -> Array[RelicData]:
	return pool if everything else pool.filter(func(r: RelicData) -> bool: return relics.has(r))


func can_evolve(tower: TowerData) -> bool:
	return everything or evolving.has(tower.id)
