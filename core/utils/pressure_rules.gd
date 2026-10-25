class_name PressureRules
## Pressure's rules (M12), on a list of PressureData: its points, the shard multiplier, the title, and the
## numbers the systems read for each rule. Rules only: the systems apply them (Level.apply_pressure, MapFlow).

const RULE_HARDENED_ELITES: StringName = &"hardened_elites"
const RULE_NO_REPAIRS: StringName = &"no_repairs"
const RULE_SWIFT_DEAD: StringName = &"swift_dead"
const RULE_FEWER_SLOTS: StringName = &"fewer_slots"
const RULE_STRONGER_BOSSES: StringName = &"stronger_bosses"
const RULE_HASTY_WAVES: StringName = &"hasty_waves"
const RULE_FEWER_CARDS: StringName = &"fewer_cards"

const ELITE_HEALTH: float = 1.4
const BOSS_HEALTH: float = 1.25
const ENEMY_SPEED: float = 1.1
const SLOTS_LOCKED: int = 2
const HASTY_SECONDS: float = 60.0
const FEWER_CARDS_SIZE: int = 2
## Each point pays this much more shards.
const SHARD_BONUS_PER_POINT: float = 0.1
## [minimum points, title], highest first.
const TITLES: Array = [[13, "Last Light"], [10, "Warden"], [7, "Marshal"], [4, "Captain"], [1, "Watchman"]]


static func points(list: Array[PressureData]) -> int:
	var total: int = 0
	for data: PressureData in list:
		total += data.points
	return total


static func shard_multiplier(total_points: int) -> float:
	return 1.0 + SHARD_BONUS_PER_POINT * total_points


## The title a Pressure total earns ("" at 0).
static func title(total_points: int) -> String:
	for entry: Array in TITLES:
		if total_points >= int(entry[0]):
			return str(entry[1])
	return ""


static func has_rule(list: Array[PressureData], rule: StringName) -> bool:
	for data: PressureData in list:
		if data.rule == rule:
			return true
	return false


## The ids of `list`, as saved.
static func ids(list: Array[PressureData]) -> Array[String]:
	var out: Array[String] = []
	for data: PressureData in list:
		out.append(String(data.id))
	return out
