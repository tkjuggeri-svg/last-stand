class_name RootAbility
extends EnemyAbility
## The Hollow Stag's mechanic: it stops and the ground round it stirs (a green ring grows to `radius`),
## then roots burst up: the hero inside the ring is held in place for `hold_time` s (a dash breaks free).
## Towers are not affected.

const RING_COLOR: Color = Color(0.55, 0.9, 0.4, 0.85)
const HERO_BODY_MASK: int = 2

@export var radius: float = 130.0
@export var hold_time: float = 1.6

var _ring: TelegraphMarker


func _begin_telegraph() -> void:
	_ring = _marker(TelegraphMarker.Shape.RING, enemy.global_position, RING_COLOR, radius)
	_play("cast")


func _telegraph_step(progress: float) -> void:
	if _ring != null:
		_ring.progress = progress


func _act() -> void:
	if _ring != null:
		_ring.queue_free()
		_ring = null
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, enemy.global_position)
	query.collision_mask = HERO_BODY_MASK
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 4):
		var hero: Hero = hit["collider"] as Hero
		if hero != null:
			hero.hold(hold_time)
