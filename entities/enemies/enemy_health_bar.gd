class_name EnemyHealthBar
extends Node2D
## A small pixel-art health bar above an enemy, hidden until the enemy first takes damage (most
## enemies die in a few hits; the bar only matters for the ones that take a beating). Drawn in whole
## art pixels (2 world px): a dark frame, a dark-red trough and a two-tone red fill. Display only.

const ART_PX: int = 2
const FRAME: Color = Color("1a141f")
const TROUGH: Color = Color("3a1218")
const FILL: Color = Color("c2261b")
const FILL_LIGHT: Color = Color("ff5a3a")

## Inner width in world px (a multiple of ART_PX).
var _fill: Color = FILL
var _fill_light: Color = FILL_LIGHT
var _width: int = 24
var _ratio: float = 1.0


func _ready() -> void:
	hide()


## Size it for a body (wider for bigger enemies) and place it `height` px above the enemy's origin.
## `color`: its role's (EnemyRoles); the lower half of the fill is a shade darker.
func setup(body_radius: float, height: float, color: Color = FILL_LIGHT) -> void:
	_fill_light = color
	_fill = color.darkened(0.4)
	_width = maxi(roundi((body_radius * 2.0 + 4.0) / ART_PX), 6) * ART_PX
	position = Vector2(-_width / 2.0 - ART_PX, height).round()
	queue_redraw()


## Shows the bar at current / max (called on damage).
func show_health(current: int, maximum: int) -> void:
	_ratio = clampf(float(current) / maxf(maximum, 1), 0.0, 1.0)
	visible = current > 0
	queue_redraw()


func get_fill_ratio() -> float:
	return _ratio


func _draw() -> void:
	var inner: Rect2 = Rect2(ART_PX, ART_PX, _width, ART_PX * 2)
	draw_rect(Rect2(0, 0, _width + ART_PX * 2, ART_PX * 4), FRAME)
	draw_rect(inner, TROUGH)
	var fill: int = ceili(_width * _ratio / ART_PX) * ART_PX if _ratio > 0.0 else 0
	if fill > 0:
		draw_rect(Rect2(inner.position, Vector2(fill, ART_PX)), _fill_light)
		draw_rect(Rect2(inner.position + Vector2(0, ART_PX), Vector2(fill, ART_PX)), _fill)
