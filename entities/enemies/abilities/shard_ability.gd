class_name ShardAbility
extends EnemyAbility
## The Bone Hurler's mechanic: it picks the nearest tower within `reach`, a ring shows on that tower while
## it winds up (telegraph_time), then a bone shard hits it and the tower is silenced for `silence_time` s.
## Nothing happens when no tower is in reach.

const RING_COLOR: Color = Color(0.92, 0.88, 0.7, 0.85)
const TOWER_BODY_MASK: int = 1

@export var reach: float = 190.0
@export var silence_time: float = 3.0

var _target: Tower
var _ring: TelegraphMarker


func _can_start() -> bool:
	return _nearest_tower() != null


func _begin_telegraph() -> void:
	_target = _nearest_tower()
	if _target != null:
		_ring = _marker(TelegraphMarker.Shape.RING, _target.global_position, RING_COLOR, 30.0)


func _telegraph_step(progress: float) -> void:
	if _ring != null:
		_ring.progress = progress


func _act() -> void:
	if _ring != null:
		_ring.queue_free()
		_ring = null
	if is_instance_valid(_target) and _target.is_active():
		_target.get_silence().silence(silence_time)
	_target = null


func _nearest_tower() -> Tower:
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = reach
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, enemy.global_position)
	query.collision_mask = TOWER_BODY_MASK
	var best: Tower = null
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var tower: Tower = hit["collider"] as Tower
		if tower != null and tower.is_active() and (best == null or tower.global_position.distance_to(enemy.global_position) < best.global_position.distance_to(enemy.global_position)):
			best = tower
	return best
