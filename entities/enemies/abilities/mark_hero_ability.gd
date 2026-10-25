class_name MarkHeroAbility
extends EnemyAbility
## The Inquisitor's mechanic: a ring grows on the ground around it (the telegraph), then the hero, if inside,
## is marked for `mark_time` s: it takes `damage_factor` times the damage. Step out of the ring, or kill it.

const RING_COLOR: Color = Color(1.0, 0.85, 0.4, 0.85)
const HERO_BODY_MASK: int = 2

@export var radius: float = 120.0
@export var mark_time: float = 4.0
@export var damage_factor: float = 1.3

var _ring: TelegraphMarker
var _marked: Hero


func _begin_telegraph() -> void:
	_ring = _marker(TelegraphMarker.Shape.RING, enemy.global_position, RING_COLOR, radius)


func _telegraph_step(progress: float) -> void:
	if _ring != null:
		_ring.progress = progress
		_ring.global_position = enemy.global_position


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
			hero.health.resist = damage_factor
			_marked = hero
			get_tree().create_timer(mark_time).timeout.connect(_unmark.bind(hero))


func on_owner_died() -> void:
	if _ring != null:
		_ring.queue_free()


func _unmark(hero: Hero) -> void:
	if is_instance_valid(hero):
		hero.health.resist = 1.0
