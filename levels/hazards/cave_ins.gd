class_name CaveIns
extends LevelHazard
## The Sunless Mines' mechanic (and, with smaller numbers, the Bone Quarry's rockfall): now and then
## `data.count` places on the roads fall in (a ring warns, data.warning s): what is under them is hurt, and
## the rubble blocks the road for `data.effect_time` s: enemies that reach it are held and queue behind it, a
## chance for blasts and for the hero. The rubble goes with the wave.

const EXPLOSION_SCENE: PackedScene = preload("res://entities/towers/explosion.tscn")


func _strike() -> void:
	for i: int in maxi(data.count, 1):
		var spot: Dictionary = _lane_point(0.3, 0.75)
		var at: Vector2 = spot["at"]
		_warn(at, data.radius, func() -> void: collapse(at))


## The cave-in at `at` (also called by tests).
func collapse(at: Vector2) -> void:
	var rubble: Explosion = EXPLOSION_SCENE.instantiate()
	rubble.setup(data.damage_to_enemies, data.radius, true)
	rubble.top_level = true
	rubble.position = at
	var blast: HazardBlast = HazardBlast.new()
	blast.setup(data.radius, data.damage_to_hero)
	blast.position = at
	var block: Rubble = Rubble.new()
	block.setup(at, data.radius, data.effect_time)
	var parent: Node = _effects_root()
	parent.add_child.call_deferred(rubble)
	parent.add_child.call_deferred(blast)
	parent.add_child.call_deferred(block)
