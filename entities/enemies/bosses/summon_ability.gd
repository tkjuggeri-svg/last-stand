class_name SummonAbility
extends EnemyAbility
## The Gravelord's mechanic: it stops, raises its lantern, and graves open around it (green rings on
## the ground, for telegraph_time), then `count` minions climb out and walk its lane. Never more than
## max_minions of its own alive at once.

const RING_COLOR: Color = Color(0.45, 1.0, 0.6, 0.75)
const DUST_SCENE: PackedScene = preload("res://entities/effects/dust_puff.tscn")

@export var minion: EnemyData
@export var count: int = 3
## How far from the boss's centre the graves open.
@export var spread: float = 60.0
@export var max_minions: int = 9
## Radius of each grave's ring.
@export var ring_radius: float = 18.0

var _spots: Array[Vector2] = []
var _markers: Array[TelegraphMarker] = []
var _minions: Array[Enemy] = []


func setup(owner_enemy: Enemy) -> void:
	super(owner_enemy)
	assert(minion != null, "SummonAbility needs a minion")


## Its own minions still alive (summon_requested's receiver reports them back via track_minion()).
func get_minion_count() -> int:
	_minions = _minions.filter(func(m: Enemy) -> bool: return is_instance_valid(m) and m.is_alive())
	return _minions.size()


## The spawner tells the summoner which enemy each grave produced.
func track_minion(spawned: Enemy) -> void:
	_minions.append(spawned)


func get_spots() -> Array[Vector2]:
	return _spots.duplicate()


func _can_start() -> bool:
	return get_minion_count() + count <= max_minions


func _begin_telegraph() -> void:
	_spots.clear()
	var turn: float = enemy.velocity.angle() if not enemy.velocity.is_zero_approx() else 0.0
	for i: int in count:
		var spot: Vector2 = enemy.global_position + Vector2.from_angle(turn + TAU * (i + 0.5) / count) * spread
		_spots.append(spot)
		_markers.append(_marker(TelegraphMarker.Shape.RING, spot, RING_COLOR, ring_radius))
	_play("cast")


func _telegraph_step(progress: float) -> void:
	for marker: TelegraphMarker in _markers:
		marker.progress = progress


func _act() -> void:
	for marker: TelegraphMarker in _markers:
		marker.queue_free()
	_markers.clear()
	for spot: Vector2 in _spots:
		enemy.request_summon(minion, spot)
		var dust: Node2D = DUST_SCENE.instantiate()  # the earth breaks open (display only)
		dust.top_level = true
		add_child(dust)
		dust.global_position = spot
