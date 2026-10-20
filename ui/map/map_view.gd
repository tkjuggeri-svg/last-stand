class_name MapView
extends Control
## Draws a RunMap: dotted links between rows (brighter along the path taken), a gold disc under every
## node visited, a pulsing ring around the nodes that can be picked next, and one icon button per node
## (MapScreen makes them), row 1 at the bottom and the boss at the top. Display only.

const LINK_COLOR: Color = Color(0.55, 0.5, 0.6, 0.55)
const PATH_COLOR: Color = Color(0.95, 0.82, 0.48, 0.95)
const MARGIN: Vector2 = Vector2(48, 36)
const VISITED_COLOR: Color = Color(0.94, 0.82, 0.48, 0.35)
const CHOICE_COLOR: Color = Color(0.94, 0.82, 0.48, 1)
const MARK_RADIUS: float = 22.0

var map: RunMap
## 0..1, animated by MapScreen: the choice rings pulse with it.
var pulse: float = 0.0:
	set(value):
		pulse = value
		queue_redraw()


## Where node `node` sits in this control (its icon's centre).
func node_position(node: MapNode) -> Vector2:
	var area: Vector2 = size - MARGIN * 2.0
	var rows: int = map.chapter.rows
	var y: float = MARGIN.y + area.y * (1.0 - float(node.row - 1) / maxf(rows - 1, 1))
	var x: float = MARGIN.x + area.x * (0.15 + 0.7 * node.x)
	return Vector2(x, y).round()


func _draw() -> void:
	if map == null:
		return
	for node: MapNode in map.nodes:
		for index: int in node.links:
			var target: MapNode = map.nodes[index]
			var taken: bool = map.path.has(node) and map.path.has(target)
			_dotted(node_position(node), node_position(target), PATH_COLOR if taken else LINK_COLOR, 3.0 if taken else 2.0)
	for node: MapNode in map.path:
		draw_circle(node_position(node), MARK_RADIUS, VISITED_COLOR)
	for node: MapNode in map.get_choices():
		draw_arc(node_position(node), MARK_RADIUS + 2.0 + pulse * 3.0, 0.0, TAU, 32, Color(CHOICE_COLOR, 0.5 + 0.5 * pulse), 2.0)


## A dotted line in whole pixels (it matches the pixel art).
func _dotted(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var length: float = from.distance_to(to)
	var steps: int = maxi(roundi(length / 10.0), 1)
	for i: int in steps:
		var a: Vector2 = from.lerp(to, (i + 0.2) / steps)
		var b: Vector2 = from.lerp(to, (i + 0.6) / steps)
		draw_line(a.round(), b.round(), color, width)
