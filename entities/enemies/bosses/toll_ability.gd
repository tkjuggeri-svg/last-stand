class_name TollAbility
extends EnemyAbility
## The Tollkeeper's mechanic: it plants itself and heaves its bell up while a bronze ring grows on the
## ground to `radius` (the telegraph), then rings it: every tower inside the ring is silenced for
## silence_time seconds (TowerSilence: no firing). The hero is not affected. Spread the defence, and
## keep the hero on it while it stands still.

const RING_COLOR: Color = Color(0.85, 0.62, 0.3, 1.0)
## Physics layer 1 ("world"): towers' bodies are on it.
const TOWER_BODY_MASK: int = 1
const MAX_TOWERS: int = 32

@export var radius: float = 220.0
@export var silence_time: float = 4.0

var _ring: TelegraphMarker
var _silenced: int = 0


func _begin_telegraph() -> void:
	_ring = _marker(TelegraphMarker.Shape.RING, enemy.global_position, RING_COLOR, radius)
	_play("toll")


func _telegraph_step(progress: float) -> void:
	_ring.progress = progress


func _act() -> void:
	_ring.queue_free()
	_silenced = 0
	for tower: Tower in towers_in_reach():
		tower.get_silence().silence(silence_time)
		_silenced += 1


## The towers whose base is inside the ring now.
func towers_in_reach() -> Array[Tower]:
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, enemy.global_position)
	query.collision_mask = TOWER_BODY_MASK
	var found: Array[Tower] = []
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, MAX_TOWERS):
		var tower: Tower = hit["collider"] as Tower
		if tower != null and tower.is_active() and tower.global_position.distance_to(enemy.global_position) <= radius:
			found.append(tower)
	return found


## How many towers the last toll silenced.
func get_silenced_count() -> int:
	return _silenced
