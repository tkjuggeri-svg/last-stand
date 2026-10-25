class_name Rubble
extends Node2D
## A fallen tunnel (CaveIns): for `seconds` it holds every enemy inside its circle in place (they still
## fight what is in reach), so the road is blocked and the dead queue up behind it. Drawn as a heap of
## stones (display only).

const HOLD_STEP: float = 0.3
const STONES: int = 14

var _radius: float = 60.0
var _left: float = 8.0
var _step_left: float = 0.0
var _stones: PackedVector2Array = PackedVector2Array()


## Call before adding it to the tree.
func setup(at: Vector2, radius: float, seconds: float) -> void:
	top_level = true
	position = at
	_radius = radius
	_left = seconds


func _ready() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(position.x * 31.0 + position.y)
	for i: int in STONES:
		_stones.append(Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, _radius * 0.8))
	z_index = -1


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	_step_left -= delta
	if _step_left <= 0.0:
		_step_left = HOLD_STEP
		for enemy: Enemy in EnemyQuery.in_circle(get_world_2d(), global_position, _radius):
			enemy.get_status().hold(HOLD_STEP * 2.0)


func is_blocking() -> bool:
	return _left > 0.0


func _draw() -> void:
	draw_circle(Vector2.ZERO, _radius * 0.9, Color(0.1, 0.09, 0.11, 0.55))
	for stone: Vector2 in _stones:
		draw_rect(Rect2((stone - Vector2(5, 3)).round(), Vector2(10, 6)), Color(0.42, 0.4, 0.46, 1.0))
		draw_rect(Rect2((stone - Vector2(5, 3)).round(), Vector2(10, 2)), Color(0.62, 0.6, 0.66, 1.0))
