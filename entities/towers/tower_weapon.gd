class_name TowerWeapon
extends RefCounted
## How a tower delivers a volley (a part of Tower, which owns one): its TowerData's projectile at
## each target, or an evolution's attack: arrow rain on the target's spot, a cone blast at it, shots
## that freeze every few volleys. Effects it creates are children of the tower.

const PROJECTILE_SCENE: PackedScene = preload("res://entities/towers/projectile.tscn")
const ARROW_RAIN_SCENE: PackedScene = preload("res://entities/towers/arrow_rain.tscn")
const CONE_BLAST_SCENE: PackedScene = preload("res://entities/towers/cone_blast.tscn")

## Shots fired since the last freezing one (Glacier Spire).
var _shots_since_freeze: int = 0


## One volley from `tower` at `targets` (the first is the main target) with its current stats.
func fire(tower: Tower, targets: Array[Enemy], stats: TowerTier) -> void:
	var evolution: TowerEvolution = tower.get_evolution()
	var attack: TowerEvolution.Attack = evolution.attack if evolution != null else TowerEvolution.Attack.SHOT
	if attack == TowerEvolution.Attack.RAIN:
		var rain: ArrowRain = ARROW_RAIN_SCENE.instantiate()
		rain.setup(stats.damage, stats.splash_radius, evolution.rain_strikes + stats.pierce, evolution.rain_interval)
		rain.top_level = true
		rain.position = tower.aim_point(targets[0])
		tower.add_child(rain)
		return
	if attack == TowerEvolution.Attack.CONE:
		var blast: ConeBlast = CONE_BLAST_SCENE.instantiate()
		blast.setup(stats, targets[0].global_position - tower.global_position, evolution.cone_angle)
		blast.position = tower.data.muzzle_offset
		tower.add_child(blast)
		return
	var freezes: bool = evolution != null and evolution.freeze_every > 0 and _count_freeze(evolution.freeze_every)
	var data: TowerData = tower.data
	for enemy: Enemy in targets:
		var shot: Projectile = PROJECTILE_SCENE.instantiate()
		shot.evolution = evolution
		shot.freezes = freezes
		if data.line_shot:
			shot.launch_line(data, stats, tower.aim_point(enemy), tower.global_position, data.muzzle_offset)
		elif data.homing:
			shot.launch(data, stats, enemy, tower.global_position + data.muzzle_offset, tower.global_position)
		else:
			shot.launch_at_point(data, stats, tower.aim_point(enemy), tower.global_position, data.muzzle_offset)
		tower.add_child(shot)


## Counts a volley toward the next freeze; true when this one freezes.
func _count_freeze(every: int) -> bool:
	_shots_since_freeze += 1
	if _shots_since_freeze < every:
		return false
	_shots_since_freeze = 0
	return true
