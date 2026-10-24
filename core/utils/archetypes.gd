class_name Archetypes
## The run's archetypes (M9): every card and relic carries one or two tags (fire, frost, blade, ranged,
## summon, traps, economy, fortress). Once a run holds several of a tag, offers lean toward it, so a plan
## can form without the offers being fixed. Rules only: UpgradeOffers weighs by lean_weight(), the HUD
## shows leading().

const TAGS: Array[StringName] = [&"fire", &"frost", &"blade", &"ranged", &"summon", &"traps", &"economy", &"fortress"]
## Cards of a tag held, and the offer weight they give that tag's other cards.
const LEAN_AT: int = 2
const LEAN_STRONG_AT: int = 4
const LEAN_WEIGHT: float = 1.6
const LEAN_STRONG_WEIGHT: float = 2.0


## How many cards and relics of each tag `modifiers` holds (a stacked card counts once per pick).
static func counts(modifiers: RunModifiers) -> Dictionary:
	var held: Dictionary = {}
	if modifiers == null:
		return held
	for data: UpgradeData in modifiers.get_taken():
		for tag: StringName in data.tags:
			held[tag] = int(held.get(tag, 0)) + 1
	return held


## The offer weight multiplier of `data` given the tags held: its best tag counts.
static func lean_weight(data: UpgradeData, held: Dictionary) -> float:
	var best: float = 1.0
	for tag: StringName in data.tags:
		var count: int = int(held.get(tag, 0))
		if count >= LEAN_STRONG_AT:
			best = maxf(best, LEAN_STRONG_WEIGHT)
		elif count >= LEAN_AT:
			best = maxf(best, LEAN_WEIGHT)
	return best


## The tag the run holds most of (the first of a tie), or &"" below LEAN_AT.
static func leading(modifiers: RunModifiers) -> StringName:
	var held: Dictionary = counts(modifiers)
	var best: StringName = &""
	for tag: StringName in TAGS:
		if int(held.get(tag, 0)) >= LEAN_AT and int(held.get(tag, 0)) > int(held.get(best, 0)):
			best = tag
	return best


## "Fire build" for the HUD.
static func label(tag: StringName) -> String:
	return "%s build" % String(tag).capitalize()
