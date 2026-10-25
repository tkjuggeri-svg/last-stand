class_name FallingWalls
extends LevelHazard
## The Ashen Keep's mechanic: now and then a wall section beside a road collapses. A ring warns where
## (data.warning s), then everything in `radius` is hurt (enemies by `damage_to_enemies`, the hero and
## minions by `damage_to_hero`) and the nearest tower is silenced for `effect_time` s (the rubble: it
## cannot fire). Never more than one collapse at a time.

const EXPLOSION_SCENE: PackedScene = preload("res://entities/towers/explosion.tscn")
## How far beside the road the section stands.
const SIDE_OFFSET: float = 50.0
## The nearest tower this close to the rubble is silenced.
const TOWER_REACH: float = 240.0

@export var builder: TowerBuilder


func _strike() -> void:
	var spot: Dictionary = _lane_point(0.25, 0.8)
	var at: Vector2 = spot["at"] + Vector2.from_angle(rng.randf() * TAU) * SIDE_OFFSET
	_warn(at, data.radius, func() -> void: collapse(at))


## The collapse at `at` (also called by tests).
func collapse(at: Vector2) -> void:
	var rubble: Explosion = EXPLOSION_SCENE.instantiate()
	rubble.setup(data.damage_to_enemies, data.radius, true)
	rubble.top_level = true
	rubble.position = at
	var blast: HazardBlast = HazardBlast.new()
	blast.setup(data.radius, data.damage_to_hero)
	blast.position = at
	var parent: Node = _effects_root()
	parent.add_child.call_deferred(rubble)
	parent.add_child.call_deferred(blast)
	var tower: Tower = _nearest_tower(at)
	if tower != null:
		tower.get_silence().silence(data.effect_time)


func _nearest_tower(at: Vector2) -> Tower:
	if builder == null:
		return null
	var best: Tower = null
	for tower: Tower in builder.get_towers():
		var d: float = tower.global_position.distance_to(at)
		if d <= TOWER_REACH and (best == null or d < best.global_position.distance_to(at)):
			best = tower
	return best
