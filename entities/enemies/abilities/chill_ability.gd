class_name ChillAbility
extends TollAbility
## The Frost Wraith's mechanic (a Toll with a cold ring): it stops and an icy ring grows to `radius`, then
## the towers inside are silenced for `silence_time` s (as the Tollkeeper's toll) and the hero, if inside,
## is chilled: it keeps `chill_factor` of its speed for `chill_time` s. Step out of the ring, or kill it.

const HERO_BODY_MASK: int = 2

@export var chill_time: float = 3.0
@export_range(0.1, 1.0) var chill_factor: float = 0.55


func _act() -> void:
	super()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, enemy.global_position)
	query.collision_mask = HERO_BODY_MASK
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 4):
		var hero: Hero = hit["collider"] as Hero
		if hero != null:
			hero.chill(chill_time, chill_factor)
