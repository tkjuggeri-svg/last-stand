class_name RunModifiers
extends Node
## The run's upgrades and the stat modifiers they bring. Owned by the level (under Systems, no
## autoload), so Restart (a fresh level) starts from nothing. Systems that have run stats read their
## final values through apply(): (base + every flat) * (1 + every percent), summed over the stat
## names they listen to (e.g. a tower's damage listens to "tower.damage" and "tower.archer.damage").
## With nothing taken every value is its base, so behaviour is unchanged.

## Any modifier was added (systems re-read their stats).
signal changed
## An upgrade was taken (`stacks` = how many times now).
signal upgrade_added(data: UpgradeData, stacks: int)

# Stat names. Tower stats also exist per tower type: "tower.<id>.<stat>" (see tower_stats()).
const HERO_DAMAGE: StringName = &"hero.damage"
const HERO_MOVE_SPEED: StringName = &"hero.move_speed"
const HERO_MAX_HEALTH: StringName = &"hero.max_health"
const HERO_ATTACK_COOLDOWN: StringName = &"hero.attack_cooldown"
## Size of the sword swing's hitbox (1 = normal reach).
const HERO_REACH: StringName = &"hero.reach"
const HERO_LIVES: StringName = &"hero.lives"
const TOWER_DAMAGE: StringName = &"damage"
const TOWER_FIRE_INTERVAL: StringName = &"fire_interval"
const TOWER_RANGE: StringName = &"range"
const TOWER_BUILD_TIME: StringName = &"build_time"
const TOWER_SLOW_DURATION: StringName = &"slow_duration"
## Extra enemies a shot passes through after its target.
const TOWER_PIERCE: StringName = &"pierce"
## Damage per second of the burning ground a shot leaves.
const TOWER_BURN: StringName = &"burn"
const FORTRESS_MAX_HEALTH: StringName = &"fortress.max_health"
## Damage per second to enemies right at the walls.
const FORTRESS_THORNS: StringName = &"fortress.thorns"
const KILL_GOLD: StringName = &"economy.kill_gold"
## Share of unspent gold paid at the end of each wave, up to INTEREST_CAP.
const INTEREST: StringName = &"economy.interest"
const INTEREST_CAP: StringName = &"economy.interest_cap"
## Price of tower upgrades (levels 2 and 3).
const TOWER_UPGRADE_COST: StringName = &"economy.tower_upgrade_cost"
## Instant effects (UpgradeData.instant_effect): heal the fortress by effect_amount of its max HP.
const INSTANT_REPAIR_FORTRESS: StringName = &"repair_fortress"

var _taken: Array[UpgradeData] = []
var _flat: Dictionary = {}
var _percent: Dictionary = {}


## The stat names a tower stat listens to: all towers, and this tower type.
static func tower_stats(stat: StringName, tower_id: StringName) -> Array[StringName]:
	return [StringName("tower.%s" % stat), StringName("tower.%s.%s" % [tower_id, stat])]


## apply() for systems whose modifiers may be unset (a scene running on its own): base if null.
static func value(modifiers: RunModifiers, base: float, stats: Array[StringName]) -> float:
	return modifiers.apply(base, stats) if modifiers != null else base


static func value_int(modifiers: RunModifiers, base: int, stats: Array[StringName]) -> int:
	return modifiers.apply_int(base, stats) if modifiers != null else base


## Takes an upgrade: its modifiers apply from now on (stacking if taken again).
func add_upgrade(data: UpgradeData) -> void:
	_taken.append(data)
	for modifier: StatModifier in data.modifiers:
		_add(modifier)
	upgrade_added.emit(data, get_stacks(data.id))
	changed.emit()


## A single modifier without an upgrade (tests, debugging).
func add_modifier(modifier: StatModifier) -> void:
	_add(modifier)
	changed.emit()


func get_stacks(id: StringName) -> int:
	return _taken.filter(func(d: UpgradeData) -> bool: return d.id == id).size()


## False for a non-stackable upgrade that was already taken.
func can_take(data: UpgradeData) -> bool:
	return data.stackable or get_stacks(data.id) == 0


## Every upgrade taken, in order (a stacked one appears once per pick).
func get_taken() -> Array[UpgradeData]:
	return _taken.duplicate()


func get_flat(stats: Array[StringName]) -> float:
	var total: float = 0.0
	for stat: StringName in stats:
		total += float(_flat.get(stat, 0.0))
	return total


func get_percent(stats: Array[StringName]) -> float:
	var total: float = 0.0
	for stat: StringName in stats:
		total += float(_percent.get(stat, 0.0))
	return total


## The final value of `base` under the modifiers of `stats` (never below 0).
func apply(base: float, stats: Array[StringName]) -> float:
	return maxf((base + get_flat(stats)) * maxf(1.0 + get_percent(stats), 0.0), 0.0)


func apply_int(base: int, stats: Array[StringName]) -> int:
	return roundi(apply(float(base), stats))


func _add(modifier: StatModifier) -> void:
	_flat[modifier.stat] = float(_flat.get(modifier.stat, 0.0)) + modifier.flat
	_percent[modifier.stat] = float(_percent.get(modifier.stat, 0.0)) + modifier.percent
