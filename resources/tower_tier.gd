class_name TowerTier
extends Resource
## One level of a tower: what reaching it costs and every stat the tower has at that level. Level 1
## comes from the TowerData's own fields (TowerData.stats_for(1)); levels 2 and 3 are the TowerData's
## `tiers`. Tune upgrades in data/towers/*.tres.

## Gold to upgrade to this level (0 for level 1: that is the build price).
@export var cost: int = 0
@export var damage: int = 10
## Seconds between two volleys.
@export var fire_interval: float = 1.0
@export var attack_range: float = 160.0
## Above 0: shots explode on impact, hitting every enemy within this radius.
@export var splash_radius: float = 0.0
## Speed multiplier applied to a hit enemy (1 = no slow) and how long it lasts.
@export_range(0.1, 1.0) var slow_factor: float = 1.0
@export var slow_duration: float = 0.0
## Above 0: the slow also catches every enemy within this radius of the impact (frost nova).
@export var slow_area: float = 0.0
## Shots per volley, each at a different enemy (the leading ones in range).
@export var targets: int = 1
## Projectile animation at this level (empty = the TowerData's projectile_look).
@export var projectile_look: StringName = &""
## The bigger blast animation for big shells.
@export var large_blast: bool = false
## Extra enemies each shot passes through after hitting its target (in a straight line).
@export var pierce: int = 0
## Above 0: a shot leaves burning ground (radius burn_radius, for burn_duration s) that deals this
## much damage per second to every enemy on it.
@export var burn_dps: float = 0.0
@export var burn_radius: float = 40.0
@export var burn_duration: float = 3.0
## Shot speed at this level in px/s (0 = the TowerData's projectile_speed).
@export var projectile_speed: float = 0.0


## How fast this level's shots fly: projectile_speed, or `fallback` (the TowerData's) when it is 0.
func shot_speed(fallback: float) -> float:
	return projectile_speed if projectile_speed > 0.0 else fallback


## A short "what changes" line from `before` to this level, e.g. "Damage 10 → 14, Range 210 → 225".
func describe_changes(before: TowerTier) -> String:
	var parts: Array[String] = []
	if damage != before.damage:
		parts.append("Damage %d → %d" % [before.damage, damage])
	if not is_equal_approx(fire_interval, before.fire_interval):
		parts.append("Every %s s → %s s" % [String.num(before.fire_interval, 2), String.num(fire_interval, 2)])
	if not is_equal_approx(attack_range, before.attack_range):
		parts.append("Range %d → %d" % [roundi(before.attack_range), roundi(attack_range)])
	if not is_equal_approx(splash_radius, before.splash_radius):
		parts.append("Blast %d → %d" % [roundi(before.splash_radius), roundi(splash_radius)])
	if not is_equal_approx(slow_factor, before.slow_factor):
		parts.append("Slow to %d%% → %d%%" % [roundi(before.slow_factor * 100.0), roundi(slow_factor * 100.0)])
	if not is_equal_approx(slow_duration, before.slow_duration):
		parts.append("Slow %.1f s → %.1f s" % [before.slow_duration, slow_duration])
	if slow_area > 0.0 and is_zero_approx(before.slow_area):
		parts.append("Slows every enemy within %d px" % roundi(slow_area))
	if targets > before.targets:
		parts.append("Hits %d targets" % targets)
	if pierce != before.pierce:
		parts.append("Pierce %d → %d" % [before.pierce, pierce])
	if not is_equal_approx(burn_dps, before.burn_dps):
		parts.append("Burn %d/s → %d/s" % [roundi(before.burn_dps), roundi(burn_dps)])
	if not is_equal_approx(burn_radius, before.burn_radius) and burn_dps > 0.0:
		parts.append("Fire area %d → %d" % [roundi(before.burn_radius), roundi(burn_radius)])
	if large_blast and not before.large_blast:
		parts.append("Heavy shells")
	return ", ".join(parts)
