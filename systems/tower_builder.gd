class_name TowerBuilder
extends Node
## Owns the rules for building and selling towers on the level's BuildSlots: one tower per slot,
## pay the full cost to build (never below 0 gold), get sell_refund_ratio of that cost back when
## selling. Also tracks which slot the hero is standing at. Never pauses the game.

signal active_slot_changed(slot: BuildSlot)
signal tower_built(slot: BuildSlot, tower: Tower)
signal tower_sold(slot: BuildSlot, refund: int)
signal build_failed(slot: BuildSlot, data: TowerData, reason: String)

const NOT_ENOUGH_GOLD: String = "Not enough gold"
const SLOT_OCCUPIED: String = "This slot already has a tower"

@export var economy: Economy
## Parent node of the level's BuildSlots.
@export var slots_root: Node
## The towers that can be built, in menu order.
@export var catalog: Array[TowerData] = []
@export_range(0.0, 1.0) var sell_refund_ratio: float = 0.5

## Slots the hero is currently inside, most recent last.
var _nearby: Array[BuildSlot] = []


func _ready() -> void:
	assert(economy != null, "TowerBuilder needs an Economy: %s" % get_path())
	for slot: BuildSlot in get_slots():
		slot.hero_entered.connect(_on_slot_hero_entered)
		slot.hero_exited.connect(_on_slot_hero_exited)


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


## What selling a tower of this type gives back (based on its original build price).
func refund_for(data: TowerData) -> int:
	return floori(data.cost * sell_refund_ratio)


func build(slot: BuildSlot, data: TowerData) -> bool:
	if slot == null or data == null:
		return false
	if not slot.is_empty():
		build_failed.emit(slot, data, SLOT_OCCUPIED)
		return false
	if not economy.try_spend(data.cost):
		build_failed.emit(slot, data, NOT_ENOUGH_GOLD)
		return false
	var tower: Tower = data.scene.instantiate()
	tower.data = data
	slot.place(tower)
	tower_built.emit(slot, tower)
	return true


## Sells the slot's tower and returns the refund. An empty slot (e.g. sold a moment ago) gives 0,
## so repeated clicks or signals can never refund twice.
func sell(slot: BuildSlot) -> int:
	if slot == null:
		return 0
	var tower: Tower = slot.remove_tower()
	if tower == null:
		return 0
	var refund: int = refund_for(tower.data)
	tower.queue_free()
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
