class_name MarshWater
extends Area2D
## Shallow marsh water (the Drowned Marsh's pools, one CollisionPolygon2D each): the hero wades through
## it at `wading_speed` of its speed, so crossing a pool is a choice, not a shortcut. Enemies keep to
## their lanes, which wind around the water. The level's ground art is baked from the same polygons.

## Share of its speed the hero keeps in the water.
@export_range(0.1, 1.0) var wading_speed: float = 0.6


func _ready() -> void:
	body_entered.connect(func(body: Node2D) -> void:
		if body is Hero:
			(body as Hero).set_wading(wading_speed))
	body_exited.connect(func(body: Node2D) -> void:
		if body is Hero:
			(body as Hero).set_wading(1.0))


## The pools' outlines in level coordinates (for the art generator and tests).
func get_pools() -> Array[PackedVector2Array]:
	var pools: Array[PackedVector2Array] = []
	for child: Node in get_children():
		var shape: CollisionPolygon2D = child as CollisionPolygon2D
		if shape != null:
			pools.append((transform * shape.transform) * shape.polygon)
	return pools
