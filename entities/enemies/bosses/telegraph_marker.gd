class_name TelegraphMarker
extends Node2D
## A boss attack about to happen, shown on the ground (display only): a dashed ring (summon spots,
## the ward's reach) or a lane-wide arrow (a charge), drawn in whole art pixels. It fills up as the
## moment comes closer (progress 0 -> 1), so the player can read when to get out of the way.

enum Shape { RING, ARROW }

const ART_PX: float = 2.0
const SEGMENTS: int = 48

var shape: Shape = Shape.RING
var color: Color = Color(1, 0.3, 0.25, 0.7)
## Ring: its radius. Arrow: its length along `direction` (never rotate the node: pixel art).
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
	if shape == Shape.RING:
		_draw_ring()
	else:
		_draw_arrow()


func _draw_ring() -> void:
	var faint: Color = Color(color, color.a * 0.35)
	for i: int in SEGMENTS:
		if i % 2 == 0:
			_dot(Vector2.from_angle(TAU * i / SEGMENTS) * size, color)
	# The inner ring grows to the outer one as the moment comes.
	var inner: float = size * progress
	if inner > ART_PX * 2.0:
		for i: int in SEGMENTS:
			_dot(Vector2.from_angle(TAU * i / SEGMENTS) * inner, faint if progress < 1.0 else color)


func _draw_arrow() -> void:
	var across: Vector2 = Vector2(-direction.y, direction.x)
	var faint: Color = Color(color, color.a * 0.3)
	var steps: int = maxi(roundi(size / 8.0), 2)
	for i: int in steps + 1:
		var along: Vector2 = direction * (size * i / steps)
		_dot(along + across * width * 0.5, color)
		_dot(along - across * width * 0.5, color)
	# Chevrons fill the lane from the boss outward.
	var filled: int = roundi(steps * progress)
	for i: int in range(1, steps, 2):
		var tip: Vector2 = direction * (size * i / steps)
		var chevron: Color = color if i <= filled else faint
		for k: int in 4:
			var back: Vector2 = tip - direction * (k * ART_PX * 2.0)
			_dot(back + across * (k * width * 0.11), chevron)
			_dot(back - across * (k * width * 0.11), chevron)


func _dot(at: Vector2, dot_color: Color) -> void:
	var p: Vector2 = (at / ART_PX).round() * ART_PX
	draw_rect(Rect2(p - Vector2(ART_PX, ART_PX) / 2.0, Vector2(ART_PX, ART_PX)), dot_color)
