class_name WardAbility
extends EnemyAbility
## The Lich Warden's mechanic: it stops and draws a rune circle on the ground (radius, for
## telegraph_time), then every other enemy inside it gets a ward that absorbs `shield` damage for
## `duration` seconds (never stacking). It never wards itself: kill the Lich and the wards stop.

const RING_COLOR: Color = Color(0.6, 0.85, 1.0, 0.8)

@export var radius: float = 200.0
@export var shield: int = 60
@export var duration: float = 8.0

var _ring: TelegraphMarker


func _begin_telegraph() -> void:
	_ring = _marker(TelegraphMarker.Shape.RING, enemy.global_position, RING_COLOR, radius)
	_play("cast")


func _telegraph_step(progress: float) -> void:
	_ring.progress = progress


func _act() -> void:
	_ring.queue_free()
	for other: Enemy in EnemyQuery.in_circle(get_world_2d(), enemy.global_position, radius):
		if other != enemy:
			other.add_shield(shield, duration)
