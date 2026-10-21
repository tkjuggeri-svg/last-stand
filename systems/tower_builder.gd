class_name TowerBuilder
extends Node
## Owns the rules for building, upgrading and selling towers on the level's BuildSlots: one tower per
## slot, pay the full cost to build or to upgrade a level (never below 0 gold), get sell_refund_ratio
## of everything spent on that tower (build + upgrades + evolution) back when selling. At level 3 a
## tower can evolve once into one of its two TowerData.evolutions (level 4, for good). Keeps the
## Beacon Flames' fire-rate boost on the towers in their reach up to date (one boost per tower, never
## stacking). Also tracks which slot the hero is standing at. Never pauses the game.

signal active_slot_changed(slot: BuildSlot)
signal tower_built(slot: BuildSlot, tower: Tower)
signal tower_sold(slot: BuildSlot, refund: int)
signal build_failed(slot: BuildSlot, data: TowerData, reason: String)
signal tower_upgraded(slot: BuildSlot, tower: Tower, level: int)
signal upgrade_failed(slot: BuildSlot, reason: String)
signal tower_evolved(slot: BuildSlot, tower: Tower, evolution: TowerEvolution)

const NOT_ENOUGH_GOLD: String = "Not enough gold"
const SLOT_OCCUPIED: String = "This slot already has a tower"
const MAX_LEVEL: String = "Already at the highest level"
const NO_TOWER: String = "No tower here"
const UNDER_CONSTRUCTION: String = "Still under construction"
const NOT_YET: String = "Evolves at level 3"
const ALREADY_EVOLVED: String = "Already evolved"
const NO_EVOLUTIONS: String = "Siege Ledger: no evolutions"
const EVOLUTIONS_LOCKED: String = "Its evolutions are not unlocked yet (the War Room)"
## Twin Banners: two towers of the same type at most this far apart share their best level.
const TWIN_RANGE: float = 330.0

@export var economy: Economy
## The run's upgrades: handed to every tower, and they can make tower upgrades cheaper.
@export var modifiers: RunModifiers
## Parent node of the level's BuildSlots.
@export var slots_root: Node
## The towers that can be built, in menu order.
@export var catalog: Array[TowerData] = []
@export_range(0.0, 1.0) var sell_refund_ratio: float = 0.5

## What the run may use (M8 unlocks: which towers may evolve); null = everything.
var unlocks: RunUnlocks = null
## Evolutions that cost nothing (a shrine's boon), used by the next ones.
var free_evolutions: int = 0

## Slots the hero is currently inside, most recent last.
var _nearby: Array[BuildSlot] = []


func _ready() -> void:
	assert(economy != null, "TowerBuilder needs an Economy: %s" % get_path())
	for slot: BuildSlot in get_slots():
		slot.hero_entered.connect(_on_slot_hero_entered)
		slot.hero_exited.connect(_on_slot_hero_exited)
	if modifiers != null:
		modifiers.changed.connect(refresh_boosts)  # a range upgrade can reach more towers


func get_slots() -> Array[BuildSlot]:
	var slots: Array[BuildSlot] = []
	if slots_root != null:
		for child: Node in slots_root.get_children():
			if child is BuildSlot:
				slots.append(child)
	return slots


func get_free_slot_count() -> int:
	return get_slots().filter(func(s: BuildSlot) -> bool: return s.is_empty()).size()


## The slot the hero is standing at (the most recently entered one), or null.
func get_active_slot() -> BuildSlot:
	return _nearby.back() if not _nearby.is_empty() else null


## What selling a freshly built tower of this type gives back (based on its build price).
func refund_for(data: TowerData) -> int:
	return floori(build_cost(data) * sell_refund_ratio)


## Gold to build `data` (tower-build discounts apply, e.g. Siege Ledger).
func build_cost(data: TowerData) -> int:
	return RunModifiers.value_int(modifiers, data.cost, [RunModifiers.TOWER_BUILD_COST])


## What selling this tower gives back: the share of everything spent on it (build + upgrades).
func refund_for_tower(tower: Tower) -> int:
	return floori(tower.invested * sell_refund_ratio)


## Gold to take the slot's tower one level up, or -1 if there is no tower or it is at its highest level.
func upgrade_cost(slot: BuildSlot) -> int:
	if slot == null or slot.is_empty() or slot.tower.is_max_level():
		return -1
	var base: int = slot.tower.data.upgrade_cost(slot.tower.get_level() + 1)
	return RunModifiers.value_int(modifiers, base, [RunModifiers.TOWER_UPGRADE_COST])


## Upgrades the slot's tower one level if the gold allows. Returns false (and changes nothing) otherwise.
func upgrade(slot: BuildSlot) -> bool:
	if slot == null or slot.is_empty():
		upgrade_failed.emit(slot, NO_TOWER)
		return false
	var tower: Tower = slot.tower
	if tower.is_max_level():
		upgrade_failed.emit(slot, MAX_LEVEL)
		return false
	if tower.is_building():
		upgrade_failed.emit(slot, UNDER_CONSTRUCTION)
		return false
	var cost: int = upgrade_cost(slot)
	if not economy.try_spend(cost):
		upgrade_failed.emit(slot, NOT_ENOUGH_GOLD)
		return false
	tower.invested += cost
	tower.set_level(tower.get_level() + 1)
	refresh_boosts()
	tower_upgraded.emit(slot, tower, tower.get_level())
	return true


## The two branches the slot's tower can take now (empty: no tower, below level 3, or evolved).
func evolution_options(slot: BuildSlot) -> Array[TowerEvolution]:
	if slot == null or slot.is_empty() or slot.tower.is_evolved() or not slot.tower.is_max_level() or not can_evolve() \
			or not evolution_unlocked(slot.tower.data):
		return []
	return slot.tower.data.evolutions.duplicate()


## False under the Siege Ledger relic: no tower may evolve.
func can_evolve() -> bool:
	return not RunModifiers.relic(modifiers, RunModifiers.RELIC_SIEGE_LEDGER)


## False if `data`'s evolutions are not unlocked yet in this run (M8).
func evolution_unlocked(data: TowerData) -> bool:
	return unlocks == null or unlocks.can_evolve(data)


## Gold for an evolution (tower-upgrade discounts apply; 0 while a free one is owed).
func evolution_cost(evolution: TowerEvolution) -> int:
	if free_evolutions > 0:
		return 0
	return RunModifiers.value_int(modifiers, evolution.cost, [RunModifiers.TOWER_UPGRADE_COST])


## Evolves the slot's tower into its `index`-th branch if allowed and paid. Permanent.
func evolve(slot: BuildSlot, index: int) -> bool:
	if slot == null or slot.is_empty():
		upgrade_failed.emit(slot, NO_TOWER)
		return false
	var tower: Tower = slot.tower
	if tower.is_evolved():
		upgrade_failed.emit(slot, ALREADY_EVOLVED)
		return false
	if not can_evolve():
		upgrade_failed.emit(slot, NO_EVOLUTIONS)
		return false
	if not evolution_unlocked(tower.data):
		upgrade_failed.emit(slot, EVOLUTIONS_LOCKED)
		return false
	if not tower.is_max_level() or index < 0 or index >= tower.data.evolutions.size():
		upgrade_failed.emit(slot, NOT_YET)
		return false
	if tower.is_building():
		upgrade_failed.emit(slot, UNDER_CONSTRUCTION)
		return false
	var evolution: TowerEvolution = tower.data.evolutions[index]
	var cost: int = evolution_cost(evolution)
	if not economy.try_spend(cost):
		upgrade_failed.emit(slot, NOT_ENOUGH_GOLD)
		return false
	if free_evolutions > 0:
		free_evolutions -= 1
	tower.invested += cost
	tower.evolve(evolution)
	refresh_boosts()
	tower_evolved.emit(slot, tower, evolution)
	return true


## Gives every tower the best Beacon Flame boost that reaches it (none for the beacons themselves),
## and under Twin Banners the best level of a same-type tower within TWIN_RANGE.
func refresh_boosts() -> void:
	var towers: Array[Tower] = []
	for slot: BuildSlot in get_slots():
		if not slot.is_empty():
			towers.append(slot.tower)
	var twins: bool = RunModifiers.relic(modifiers, RunModifiers.RELIC_TWIN_BANNERS)
	for tower: Tower in towers:
		var shared: int = 0
		for twin: Tower in towers:
			if twins and twin != tower and twin.data == tower.data and not twin.is_evolved() \
					and twin.global_position.distance_to(tower.global_position) <= TWIN_RANGE:
				shared = maxi(shared, twin.get_level())
		tower.set_shared_level(shared)
	for tower: Tower in towers:
		var boost: float = 0.0
		for beacon: Tower in towers:
			var evolution: TowerEvolution = beacon.get_evolution()
			if beacon != tower and evolution != null and evolution.boost_fire_rate > 0.0 \
					and beacon.global_position.distance_to(tower.global_position) <= beacon.get_attack_range():
				boost = maxf(boost, evolution.boost_fire_rate)
		tower.set_fire_rate_boost(boost)


func build(slot: BuildSlot, data: TowerData) -> bool:
	if slot == null or data == null:
		return false
	if not slot.is_empty():
		build_failed.emit(slot, data, SLOT_OCCUPIED)
		return false
	var cost: int = build_cost(data)
	if not economy.try_spend(cost):
		build_failed.emit(slot, data, NOT_ENOUGH_GOLD)
		return false
	var tower: Tower = data.scene.instantiate()
	tower.data = data
	tower.modifiers = modifiers
	tower.invested = cost
	slot.place(tower)
	refresh_boosts()
	tower_built.emit(slot, tower)
	return true


## Takes the slot's tower up a level without paying (an event's gift). Returns false if it can't go up.
func free_upgrade(slot: BuildSlot) -> bool:
	if slot == null or slot.is_empty() or slot.tower.is_max_level() or slot.tower.is_building():
		return false
	slot.tower.set_level(slot.tower.get_level() + 1)
	refresh_boosts()
	tower_upgraded.emit(slot, slot.tower, slot.tower.get_level())
	return true


## Removes the slot's tower with no refund (a shrine's price). Returns false if the slot is empty.
func demolish(slot: BuildSlot) -> bool:
	if slot == null:
		return false
	var tower: Tower = slot.remove_tower()
	if tower == null:
		return false
	tower.queue_free()
	refresh_boosts()
	tower_sold.emit(slot, 0)
	return true


## Sells the slot's tower and returns the refund. An empty slot (e.g. sold a moment ago) gives 0,
## so repeated clicks or signals can never refund twice.
func sell(slot: BuildSlot) -> int:
	if slot == null:
		return 0
	var tower: Tower = slot.remove_tower()
	if tower == null:
		return 0
	var refund: int = refund_for_tower(tower)
	tower.queue_free()
	refresh_boosts()
	economy.earn(refund, Economy.Source.REFUND)
	tower_sold.emit(slot, refund)
	return refund


func _on_slot_hero_entered(slot: BuildSlot) -> void:
	_nearby.erase(slot)
	_nearby.append(slot)
	_refresh_active()


func _on_slot_hero_exited(slot: BuildSlot) -> void:
	_nearby.erase(slot)
	_refresh_active()


func _refresh_active() -> void:
	var active: BuildSlot = get_active_slot()
	for slot: BuildSlot in get_slots():
		slot.set_highlighted(slot == active)
	active_slot_changed.emit(active)
