class_name TowerSynergy
extends Resource
## A tower pair's bonus: while a tower of `partner_id` stands within `reach` of this tower, this tower
## gets the bonuses below (each a share: 0.2 = +20%). One bonus per synergy, however many partners are
## in reach. Listed in TowerData.synergies; TowerBuilder decides which are active (TowerSynergies).
## The partner is named by id, not by its TowerData, so two towers can name each other.

@export var display_name: String = ""
@export var partner_id: StringName = &""
## How close the partner must stand (centre to centre). A fixed reach, not the tower's range: a
## short-range Frost pairs as easily as a Ballista, and neighbouring slots of both maps can pair
## (280: every Crypt Road slot has a neighbour in reach, 4 of the Drowned Marsh's 7 do).
@export var reach: float = 280.0
## Why it works, for the tower menu (short).
@export var flavor: String = ""
@export var damage: float = 0.0
@export var fire_rate: float = 0.0
@export var splash_radius: float = 0.0
@export var slow_duration: float = 0.0
@export var burn_dps: float = 0.0


## Applies the bonuses to `stats` (a tower's own copy).
func apply_to(stats: TowerTier) -> void:
	stats.damage = roundi(stats.damage * (1.0 + damage))
	stats.fire_interval = stats.fire_interval / (1.0 + fire_rate)
	stats.splash_radius *= 1.0 + splash_radius
	stats.slow_duration *= 1.0 + slow_duration
	stats.burn_dps *= 1.0 + burn_dps


## What it gives, e.g. "+20% damage".
func describe_bonus() -> String:
	var parts: Array[String] = []
	for entry: Array in [[damage, "damage"], [fire_rate, "fire rate"], [splash_radius, "blast radius"], [slow_duration, "slow time"], [burn_dps, "burn damage"]]:
		if float(entry[0]) != 0.0:
			parts.append("+%d%% %s" % [roundi(float(entry[0]) * 100.0), entry[1]])
	return ", ".join(parts)
