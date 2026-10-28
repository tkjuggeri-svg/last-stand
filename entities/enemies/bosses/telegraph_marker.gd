class_name TelegraphMarker
extends Node2D
## A boss attack about to happen, shown on the ground (display only; vector since M15 P2): a dashed rune ring (the
## ward's reach, a toll), a grave (the Gravelord's summon spots) or a lane-wide chevron arrow (a charge). It fills up as
## the moment comes closer (progress 0 -> 1), so the player can read when to get out of the way.

enum Shape { RING, ARROW, GRAVE }

## A ring is drawn as dashes this many px long, with gaps of the same length, at least MIN_DASHES of them.
const DASH_LENGTH: float = 6.0
const MIN_DASHES: int = 12
const SOIL: Color = Color("4c3a2a")
const SOIL_LIGHT: Color = Color("7a5e44")

var shape: Shape = Shape.RING
var color: Color = Color(1, 0.3, 0.25, 0.7)
## Ring and grave: its radius. Arrow: its length along `direction`.
var size: float = 40.0
## Arrow only: its width and direction (normalized).
var width: float = 40.0
var direction: Vector2 = Vector2.RIGHT
var progress: float = 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	z_index = -1  # on the ground, under every character
	top_level = true


func _draw() -> void:
	match shape:
		Shape.RING:
			_draw_ring()
		Shape.GRAVE:
			_draw_ring()
			_draw_grave()
		_:
			_draw_arrow()


func _draw_ring() -> void:
	var squash: Vector2 = Vector2(1.0, 1.0)
	draw_circle(Vector2.ZERO, size, Color(color, color.a * 0.1))
	var dashes: int = maxi(ceili(TAU * size / (DASH_LENGTH * 2.0)), MIN_DASHES)
	for i: int in dashes:
		var from: float = TAU * i / dashes
		draw_arc(Vector2.ZERO, size, from, from + TAU / dashes * 0.55, 4, Color(color, color.a * 0.35), 5.0, true)
		draw_arc(Vector2.ZERO, size, from, from + TAU / dashes * 0.55, 4, color, 2.0, true)
	# The inner ring grows to the outer one as the moment comes.
	var inner: float = size * progress
	if inner > 4.0:
		var strength: float = 0.35 if progress < 1.0 else 1.0
		draw_arc(Vector2.ZERO, inner, 0.0, TAU, maxi(int(inner), 24), Color(color, color.a * strength), 2.0, true)
		draw_circle(Vector2.ZERO, inner, Color(color, color.a * 0.07 * strength))
	for i: int in 8:
		var at: Vector2 = Vector2.from_angle(TAU * i / 8.0) * size * squash
		draw_circle(at, 2.0, color)


## A grave in the ring: a mound of soil that cracks open and breathes green mist as the moment comes.
func _draw_grave() -> void:
	var rise: float = progress
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var mound: PackedVector2Array = PackedVector2Array()
	for i: int in 13:
		var a: float = PI + PI * i / 12.0
		mound.append(Vector2(cos(a) * size * 0.5, sin(a) * size * 0.3 * (0.6 + rise * 0.5) + size * 0.12))
	draw_colored_polygon(mound, SOIL)
	draw_polyline(mound, Color(SOIL_LIGHT, 0.9), 1.4, true)
	for k: int in 3:
		var x: float = (k - 1) * size * 0.22
		draw_line(Vector2(x, size * 0.1), Vector2(x + (k - 1) * 3.0, size * 0.1 - size * 0.18 * rise), Color(0.05, 0.04, 0.07, 0.9), 1.6, true)
	var mist: Color = Color(0.55, 1.0, 0.7, 0.5 * rise)
	draw_circle(Vector2(0, -size * 0.05), size * 0.45 * (0.5 + rise * 0.5), Color(mist, mist.a * 0.4))


func _draw_arrow() -> void:
	var across: Vector2 = Vector2(-direction.y, direction.x)
	var faint: Color = Color(color, color.a * 0.3)
	var half: Vector2 = across * width * 0.5
	var lane: PackedVector2Array = PackedVector2Array([-half, direction * size - half, direction * size + half, half])
	draw_colored_polygon(lane, Color(color, color.a * 0.08))
	for edge: float in [-1.0, 1.0]:
		var steps: int = maxi(roundi(size / (DASH_LENGTH * 2.0)), 2)
		for i: int in steps:
			var a: Vector2 = direction * size * i / steps + half * edge
			draw_line(a, a + direction * DASH_LENGTH, Color(color, color.a * 0.8), 2.0, true)
	# Chevrons fill the lane from the boss outward.
	var steps_c: int = maxi(roundi(size / 28.0), 2)
	var filled: int = roundi(steps_c * progress)
	for i: int in range(1, steps_c + 1):
		var tip: Vector2 = direction * (size * i / steps_c)
		var chevron: Color = color if i <= filled else faint
		var back: Vector2 = tip - direction * width * 0.28
		draw_polyline(PackedVector2Array([back + half * 0.7, tip, back - half * 0.7]), chevron, 3.0, true)
