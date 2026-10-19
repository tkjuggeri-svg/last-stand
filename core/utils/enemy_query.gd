class_name EnemyQuery
## Finds living enemies by their bodies (physics layer 3, "enemies") without an Area2D: for effects
## that hit everything in a spot at one moment (frost nova, burning ground, thorns, a passing bolt).

## Physics layer 3 ("enemies") as a bit value.
const ENEMY_BODY_MASK: int = 4
## Most bodies one query reports.
const MAX_RESULTS: int = 64


## Living enemies whose body touches the circle.
static func in_circle(world: World2D, center: Vector2, radius: float) -> Array[Enemy]:
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, center)
	query.collision_mask = ENEMY_BODY_MASK
	var found: Array[Enemy] = []
	for hit: Dictionary in world.direct_space_state.intersect_shape(query, MAX_RESULTS):
		var enemy: Enemy = hit["collider"] as Enemy
		if enemy != null and enemy.is_alive():
			found.append(enemy)
	return found
