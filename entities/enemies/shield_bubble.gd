class_name ShieldBubble
extends Node2D
## The ward a boss puts on enemies (display only; vector since M15 P2): a pale arcane bubble around the body with a soft
## fill, a hex shimmer and a bright arc running round the rim. Its node scale follows the body size (set by EnemyLook);
## visible only while the shield holds.

const RIM: Color = Color(0.75, 0.92, 1.0, 0.95)
const FILL: Color = Color(0.45, 0.7, 1.0, 0.2)
const SHIMMER: Color = Color(1, 1, 1, 0.95)
const RADIUS: Vector2 = Vector2(16, 18)
const SEGMENTS: int = 28
const SHIMMER_SPEED: float = 3.0
const HEX_SIDES: int = 6

var _time: float = 0.0


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, RADIUS / RADIUS.x)
	draw_circle(Vector2.ZERO, RADIUS.x, FILL)
	draw_arc(Vector2.ZERO, RADIUS.x, 0.0, TAU, SEGMENTS, Color(RIM, 0.35), 4.0, true)
	draw_arc(Vector2.ZERO, RADIUS.x, 0.0, TAU, SEGMENTS, RIM, 1.4, true)
	for k: int in HEX_SIDES:
		var a: float = TAU * k / HEX_SIDES + _time * 0.4
		var b: float = a + TAU / HEX_SIDES
		draw_line(Vector2.from_angle(a) * RADIUS.x * 0.62, Vector2.from_angle(b) * RADIUS.x * 0.62, Color(RIM, 0.28), 1.0, true)
	var lit: float = fposmod(_time * SHIMMER_SPEED, TAU)
	draw_arc(Vector2.ZERO, RADIUS.x, lit, lit + 0.7, 8, SHIMMER, 2.4, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
