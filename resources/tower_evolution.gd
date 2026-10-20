class_name TowerEvolution
extends TowerTier
## A tower's level 4: one of two permanent branches offered at level 3 (TowerData.evolutions). It is
## a full TowerTier (price in `cost`, every stat at level 4) plus the branch's own mechanic, chosen by
## the fields below (all off by default). Tune them in data/towers/*.tres.

## Which enemy in range the tower aims at.
enum Targeting {
	FIRST,  ## the one furthest along its lane (every other tower)
	STRONGEST,  ## the one with the most HP left (Sniper Nest)
	DENSEST,  ## the one with the most other enemies within splash_radius (Volley Tower)
}
## How a volley is delivered.
enum Attack {
	SHOT,  ## the TowerData's projectile (arrow, shell, frost bolt, fire glob, bolt)
	RAIN,  ## arrows rain on an area: rain_strikes hits of `damage` to everything within splash_radius
	CONE,  ## an instant blast: `damage` to every enemy in range within cone_angle of the target
}

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var targeting: Targeting = Targeting.FIRST
@export var attack: Attack = Attack.SHOT
@export_group("Dead zone")
## Enemies closer than this to the tower's base can't be targeted (Siege Mortar).
@export var min_range: float = 0.0
@export_group("Arrow rain")
## Hits per volley (each one hits everything within splash_radius); the tower's pierce adds more.
@export var rain_strikes: int = 0
## Seconds between the volley and the first strike, and between strikes.
@export var rain_interval: float = 0.25
@export_group("Cone")
## Full angle of the blast in degrees.
@export var cone_angle: float = 0.0
@export_group("Freeze")
## Every this-many shots the shot freezes its target (and every enemy its frost nova catches) for
## freeze_time seconds; a boss is only slowed. 0 = never.
@export var freeze_every: int = 0
@export var freeze_time: float = 0.0
@export_group("Shatter")
## Slowed enemies within range take this much more damage from every source (0.25 = +25%).
@export var shatter_bonus: float = 0.0
@export_group("Death burst")
## An enemy that dies in this tower's fire explodes: this much damage to every enemy within
## death_burst_radius, and burning ground (burn_dps, burn_duration) there.
@export var death_burst_damage: int = 0
@export var death_burst_radius: float = 0.0
@export_group("Boost")
## Every other tower within range fires this much faster (0.25 = 25% more shots); several boosts on
## one tower don't stack.
@export var boost_fire_rate: float = 0.0
@export_group("Drag")
## The bolt's first enemy is dragged back this far along its lane (a boss: x boss_drag_factor).
@export var drag_distance: float = 0.0
@export_range(0.0, 1.0) var boss_drag_factor: float = 0.2


## The branch's key numbers for the choice card, e.g. "Damage 90 every 2.4 s, range 420".
func key_numbers() -> String:
	var lines: Array[String] = []
	if damage > 0:
		lines.append("Damage %d every %s s" % [damage, String.num(fire_interval, 2)])
	else:
		lines.append("Every %s s" % String.num(fire_interval, 2))
	lines.append("Range %d%s" % [roundi(attack_range), " (not within %d)" % roundi(min_range) if min_range > 0.0 else ""])
	if attack == Attack.RAIN:
		lines.append("%d strikes within %d px" % [rain_strikes, roundi(splash_radius)])
	elif attack == Attack.CONE:
		lines.append("Cone of %d°" % roundi(cone_angle))
	elif splash_radius > 0.0:
		lines.append("Blast %d px" % roundi(splash_radius))
	if pierce > 0:
		lines.append("Pierce %d" % pierce)
	if freeze_every > 0:
		lines.append("Every %d shots: freeze %s s" % [freeze_every, String.num(freeze_time, 1)])
	elif slow_factor < 1.0:
		lines.append("Slow to %d%% for %s s" % [roundi(slow_factor * 100.0), String.num(slow_duration, 1)])
	if shatter_bonus > 0.0:
		lines.append("Slowed enemies in range: +%d%% damage taken" % roundi(shatter_bonus * 100.0))
	if death_burst_damage > 0:
		lines.append("Deaths in its fire: %d damage within %d px" % [death_burst_damage, roundi(death_burst_radius)])
	elif burn_dps > 0.0:
		lines.append("Burn %d/s" % roundi(burn_dps))
	if boost_fire_rate > 0.0:
		lines.append("Towers in range fire %d%% faster" % roundi(boost_fire_rate * 100.0))
	if drag_distance > 0.0:
		lines.append("Drags back %d px" % roundi(drag_distance))
	return "\n".join(lines)
