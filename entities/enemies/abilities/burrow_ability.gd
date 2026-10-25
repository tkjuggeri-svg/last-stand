class_name BurrowAbility
extends EnemyAbility
## The Burrower's mechanic: it stops and digs (a dust ring on the spot), then comes up `distance` px
## further along its road, and the tower nearest to where it rises (within `tower_reach`) is shaken: silenced
## for `silence_time` s. It skips part of the road and lands among the defences.

const RING_COLOR: Color = Color(0.75, 0.55, 0.3, 0.8)
const DUST_SCENE: PackedScene = preload("res://entities/effects/dust_puff.tscn")
const TOWER_BODY_MASK: int = 1

@export var distance: float = 150.0
@export var tower_reach: float = 110.0
@export var silence_time: float = 2.5
@export var ring_radius: float = 26.0

var _ring: TelegraphMarker


func _can_start() -> bool:
	return enemy.lane != null and enemy.lane.curve.get_baked_length() - enemy.get_lane_progress() > distance + 90.0


func _begin_telegraph() -> void:
	_ring = _marker(TelegraphMarker.Shape.RING, enemy.global_position, RING_COLOR, ring_radius)
	_puff(enemy.global_position)


func _telegraph_step(progress: float) -> void:
	if _ring != null:
		_ring.progress = progress


func _act() -> void:
	if _ring != null:
		_ring.queue_free()
		_ring = null
	var lane: Path2D = enemy.lane
	var to: float = minf(enemy.get_lane_progress() + distance, lane.curve.get_baked_length() - 80.0)
	enemy.global_position = lane.to_global(lane.curve.sample_baked(to))
	_puff(enemy.global_position)
	var tower: Tower = _nearest_tower()
	if tower != null:
		tower.get_silence().silence(silence_time)


## The tower nearest to where it rose, within tower_reach.
func _nearest_tower() -> Tower:
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = tower_reach
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


func _puff(at: Vector2) -> void:
	var dust: Node2D = DUST_SCENE.instantiate()
	dust.top_level = true
	add_child(dust)
	dust.global_position = at
