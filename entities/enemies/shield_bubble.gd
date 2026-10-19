class_name ShieldBubble
extends Node2D
## The ward a boss puts on enemies (display only): a pale arcane bubble around the body, drawn in
## whole art pixels (2 world px), with a shimmer running round it. Its node scale follows the body
## size (set by EnemyLook); visible only while the shield holds.

const ART_PX: float = 2.0
const RIM: Color = Color(0.75, 0.92, 1.0, 1.0)
const FILL: Color = Color(0.45, 0.7, 1.0, 0.24)
const SHIMMER: Color = Color(1, 1, 1, 0.95)
const RADIUS: Vector2 = Vector2(16, 18)
const SEGMENTS: int = 28
const SHIMMER_SPEED: float = 3.0

var _time: float = 0.0


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in SEGMENTS:
		points.append(_snap(Vector2.from_angle(TAU * i / SEGMENTS) * RADIUS))
	draw_colored_polygon(points, FILL)
	var lit: int = posmod(roundi(_time * SHIMMER_SPEED * SEGMENTS / TAU), SEGMENTS)
	for i: int in SEGMENTS:
		var color: Color = SHIMMER if absi(i - lit) <= 1 else RIM
		if i % 7 == 3 and color == RIM:
			continue  # a few gaps, so it reads as a ward, not a solid ring
		draw_rect(Rect2(points[i] - Vector2(ART_PX, ART_PX) / 2.0, Vector2(ART_PX, ART_PX)), color)


func _snap(p: Vector2) -> Vector2:
	return (p / ART_PX).round() * ART_PX
