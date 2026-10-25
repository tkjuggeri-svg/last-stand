class_name RunModifiers
extends Node
## The run's upgrades and the stat modifiers they bring. Owned by the level (under Systems, no
## autoload), so Restart (a fresh level) starts from nothing. Systems that have run stats read their
## final values through apply(): (base + every flat) * (1 + every percent), summed over the stat
## names they listen to (e.g. a tower's damage listens to "tower.damage" and "tower.archer.damage").
## With nothing taken every value is its base, so behaviour is unchanged.
## Relics (RelicData, M7.5) are taken here too: their stats apply like a card's, and systems ask
## has_relic(RELIC_*) for their rules. An event that takes "the latest upgrade" never takes a relic.

## Any modifier was added (systems re-read their stats).
signal changed
## An upgrade was taken (`stacks` = how many times now).
signal upgrade_added(data: UpgradeData, stacks: int)
## An upgrade was lost again (an event's trade); `stacks` = how many are left.
signal upgrade_removed(data: UpgradeData, stacks: int)

# Stat names. Tower stats also exist per tower type: "tower.<id>.<stat>" (see tower_stats()).
const HERO_DAMAGE: StringName = &"hero.damage"
const HERO_MOVE_SPEED: StringName = &"hero.move_speed"
const HERO_MAX_HEALTH: StringName = &"hero.max_health"
const HERO_ATTACK_COOLDOWN: StringName = &"hero.attack_cooldown"
## Size of the sword swing's hitbox (1 = normal reach).
const HERO_REACH: StringName = &"hero.reach"
const HERO_LIVES: StringName = &"hero.lives"
const HERO_DASH_COOLDOWN: StringName = &"hero.dash_cooldown"
## The Knight: Bulwark's share of a hit shrugged off while swinging (Iron Will adds to it), the px a dash
## knocks enemies back (Shield Bash), extra sword hits on bosses (Oathkeeper), the fire rate towers near him gain (Rally).
const HERO_BULWARK: StringName = &"hero.bulwark"
const HERO_DASH_BASH: StringName = &"hero.dash_bash"
const HERO_BOSS_HITS: StringName = &"hero.boss_hits"
const HERO_RALLY: StringName = &"hero.rally"
## Damage per second of the burning ground a dash leaves (0 = no trail).
const HERO_DASH_TRAIL: StringName = &"hero.dash_trail"
## The Huntress's bolt: extra enemies it passes through, and her Mark's bonus and duration.
const HERO_BOLT_PIERCE: StringName = &"hero.bolt_pierce"
const HERO_MARK_BONUS: StringName = &"hero.mark_bonus"
const HERO_MARK_TIME: StringName = &"hero.mark_time"
## The Necromancer's minions: more health (a share), and more of them at once (flat, her own raised ones).
const MINION_HEALTH: StringName = &"minion.health"
const MINION_CAP: StringName = &"minion.cap"
## Soul Feast: HP the hero regains whenever a skeleton of hers falls.
const HERO_SOUL_FEAST: StringName = &"hero.soul_feast"
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
## Flat gold paid at the end of each wave.
const WAVE_INCOME: StringName = &"economy.wave_income"
## Price of tower upgrades (levels 2 and 3).
const TOWER_UPGRADE_COST: StringName = &"economy.tower_upgrade_cost"
## Price of building a tower.
const TOWER_BUILD_COST: StringName = &"economy.tower_build_cost"
## A merchant's prices, and the Quartermaster's.
const MERCHANT_PRICES: StringName = &"economy.merchant_prices"
const QUARTERMASTER_PRICES: StringName = &"economy.quartermaster_prices"
## How long a tower's burning ground lasts.
const TOWER_BURN_DURATION: StringName = &"burn_duration"
## How long a Trap Layer's snare holds.
const TOWER_SNARE_HOLD: StringName = &"snare_hold"
## Instant effects (UpgradeData.instant_effect): heal the fortress by effect_amount of its max HP.
const INSTANT_REPAIR_FORTRESS: StringName = &"repair_fortress"
# Relic rules (RelicData.rule), carried out by RelicEffects and the systems named.
const RELIC_HOURGLASS: StringName = &"hourglass"
const RELIC_BLOODPACT: StringName = &"bloodpact"
const RELIC_OSSUARY_BELL: StringName = &"ossuary_bell"
## TowerBuilder: no evolutions.
const RELIC_SIEGE_LEDGER: StringName = &"siege_ledger"
const RELIC_LANTERN: StringName = &"lantern_of_the_lost"
## TowerBuilder: towers of a type share their best level with a twin nearby.
const RELIC_TWIN_BANNERS: StringName = &"twin_banners"
const RELIC_PHOENIX: StringName = &"phoenix_feather"
const RELIC_EXECUTIONER: StringName = &"executioners_mark"
const RELIC_GLASS_BANNER: StringName = &"glass_banner"
const RELIC_SOUL_LANTERN: StringName = &"soul_lantern"
const RELIC_DROWNED_BELL: StringName = &"drowned_bell"
## Fortress: no repairs of any kind.
const RELIC_IRON_TITHE: StringName = &"iron_tithe"
const RELIC_SECOND_OATH: StringName = &"second_oath"
## Hero: every 5th bolt is a fan of three.
const RELIC_QUIVER: StringName = &"quiver_of_plenty"
## The Knight: enemies that hit him take damage back; the fortress takes less while he stands.
const RELIC_CROWN_OF_THORNS: StringName = &"crown_of_thorns"
const RELIC_BANNER_OF_THE_LAST_KEEP: StringName = &"banner_of_the_last_keep"
## Ossuaries: a kill by a skeleton counts twice.
const RELIC_RELIQUARY: StringName = &"reliquary_of_bones"

## Rules that are not stats (Pressure's, M12): PressureRules.RULE_* keys.
var rules: Array[StringName] = []
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


## Loses the most recent upgrade taken, never a relic (its modifiers stop; an instant effect stays
## done). Returns it, or null if none was taken.
func remove_last_upgrade() -> UpgradeData:
	var index: int = _taken.size() - 1
	while index >= 0 and _taken[index] is RelicData:
		index -= 1
	if index < 0:
		return null
	var data: UpgradeData = _taken.pop_at(index)
	for modifier: StatModifier in data.modifiers:
		_flat[modifier.stat] = float(_flat.get(modifier.stat, 0.0)) - modifier.flat
		_percent[modifier.stat] = float(_percent.get(modifier.stat, 0.0)) - modifier.percent
	upgrade_removed.emit(data, get_stacks(data.id))
	changed.emit()
	return data


## A single modifier without an upgrade (tests, debugging).
func add_modifier(modifier: StatModifier) -> void:
	_add(modifier)
	changed.emit()


## True if the run has the Pressure rule `key`.
static func has_rule(modifiers: RunModifiers, key: StringName) -> bool:
	return modifiers != null and modifiers.rules.has(key)


func get_stacks(id: StringName) -> int:
	return _taken.filter(func(d: UpgradeData) -> bool: return d.id == id).size()


## False for a non-stackable upgrade that was already taken.
func can_take(data: UpgradeData) -> bool:
	return data.stackable or get_stacks(data.id) == 0


## Every upgrade taken, in order (a stacked one appears once per pick), relics included.
func get_taken() -> Array[UpgradeData]:
	return _taken.duplicate()


## The relics taken, in order.
func get_relics() -> Array[RelicData]:
	var relics: Array[RelicData] = []
	for data: UpgradeData in _taken:
		if data is RelicData:
			relics.append(data)
	return relics


## True if a relic with this rule (RELIC_*) was taken.
func has_relic(rule: StringName) -> bool:
	for held: RelicData in get_relics():
		if held.rule == rule:
			return true
	return false


## has_relic() for systems whose modifiers may be unset (a scene running on its own).
static func relic(modifiers: RunModifiers, rule: StringName) -> bool:
	return modifiers != null and modifiers.has_relic(rule)


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
