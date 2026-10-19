class_name LandingMarker
extends Node2D
## Where a cannon shell will land (display only): a pulsing dashed ring the size of the blast and a
## small cross at the centre, drawn in whole art pixels, so the player can see a shell coming and
## step out (or watch an enemy walk out) of the blast.

const COLOR: Color = Color(1.0, 0.55, 0.3, 0.55)
const SEGMENTS: int = 40
const PULSE_SPEED: float = 9.0

var _radius: float = 56.0
var _time: float = 0.0


func setup(radius: float) -> void:
	_radius = radius
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var color: Color = Color(COLOR, COLOR.a * (0.7 + 0.3 * sin(_time * PULSE_SPEED)))
	for i: int in SEGMENTS:
		if i % 2 == 1:
			continue
		var a: Vector2 = Vector2.from_angle(TAU * i / SEGMENTS) * _radius
		var b: Vector2 = Vector2.from_angle(TAU * (i + 1) / SEGMENTS) * _radius
		draw_line(a.round(), b.round(), color, 2.0)
	draw_rect(Rect2(-6, -1, 12, 2), color)
	draw_rect(Rect2(-1, -6, 2, 12), color)
