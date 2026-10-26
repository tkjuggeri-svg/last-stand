class_name MapView
extends Control
## Draws a RunMap: the chapter's ground (MapLook), roads between the nodes (gold along the path taken),
## a stone frame under every node (done: gold-filled, next choices: gold with a pulsing ring), the warm
## firelight of the fortress at the bottom against the cold of the dead at the top, and the biome's
## weather drifting over it. One icon button per node sits on top (MapScreen makes them); row 1 at the
## bottom and the boss at the top. Display only.

const FRAMES: Dictionary = {
	"idle": preload("res://assets/sprites/ui/map/frame_idle.png"),
	"choice": preload("res://assets/sprites/ui/map/frame_choice.png"),
	"done": preload("res://assets/sprites/ui/map/frame_done.png"),
	"boss_idle": preload("res://assets/sprites/ui/map/frame_boss_idle.png"),
	"boss_choice": preload("res://assets/sprites/ui/map/frame_boss_choice.png"),
	"boss_done": preload("res://assets/sprites/ui/map/frame_boss_done.png"),
}
const ROAD_EDGE: Color = Color(0.102, 0.078, 0.122, 0.9)
const ROAD_WIDTH: float = 6.0
const PATH_COLOR: Color = Color(0.95, 0.82, 0.48, 0.95)
const MARGIN: Vector2 = Vector2(48, 36)
const CHOICE_COLOR: Color = Color(0.94, 0.82, 0.48, 1)
const MARK_RADIUS: float = 24.0
## The fortress's firelight and how far it reaches up the map.
const WARM: Color = Color(1.0, 0.62, 0.28, 0.34)
const OVERLAY_SIZE: Vector2i = Vector2i(64, 36)
const COLD_ALPHA: float = 0.42
## Per weather: how many specks, how they drift (px/s), their size (px) and brightness.
const WEATHER: Dictionary = {
	MapLook.Weather.MOTES: {"count": 34, "velocity": Vector2(7, -5), "size": 2.0, "alpha": 0.45},
	MapLook.Weather.EMBERS: {"count": 42, "velocity": Vector2(9, -38), "size": 2.0, "alpha": 0.8},
	MapLook.Weather.SNOW: {"count": 64, "velocity": Vector2(-12, 30), "size": 2.0, "alpha": 0.75},
	MapLook.Weather.SPORES: {"count": 36, "velocity": Vector2(4, -11), "size": 2.0, "alpha": 0.6},
	MapLook.Weather.MIST: {"count": 8, "velocity": Vector2(11, 0), "size": 1.0, "alpha": 0.07},
	MapLook.Weather.GLINTS: {"count": 28, "velocity": Vector2.ZERO, "size": 2.0, "alpha": 0.9},
}
const WISP_SIZE: Vector2 = Vector2(180, 14)

var map: RunMap
## The chapter's look (ground, roads, weather); null draws a plain field.
var look: MapLook:
	set(value):
		look = value
		_cold = null
		queue_redraw()
## 0..1, animated by MapScreen: the choice rings pulse with it.
var pulse: float = 0.0:
	set(value):
		pulse = value
		queue_redraw()
## Seconds the map has been open: the weather moves with it.
var time: float = 0.0

var _cold: Texture2D
static var _warm_glow: Texture2D
static var _vignette: Texture2D


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
	var current: MapLook = look if look != null else MapLook.new()
	_draw_ground(current)
	_draw_roads(current)
	_draw_weather(current)
	var choices: Array[MapNode] = map.get_choices()
	for node: MapNode in map.nodes:
		var state: String = "done" if map.path.has(node) else ("choice" if choices.has(node) else "idle")
		var frame: Texture2D = FRAMES[("boss_" if node.kind == RunMap.Kind.BOSS else "") + state]
		draw_texture(frame, node_position(node) - frame.get_size() * 0.5)
	for node: MapNode in choices:
		draw_arc(node_position(node), MARK_RADIUS + 2.0 + pulse * 3.0, 0.0, TAU, 32, Color(CHOICE_COLOR, 0.5 + 0.5 * pulse), 2.0)


func _draw_ground(current: MapLook) -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	if current.ground != null:
		draw_texture_rect(current.ground, rect, true)
	else:
		draw_rect(rect, Color(0.09, 0.08, 0.11))
	if _cold == null:
		_cold = _gradient_texture(false, current.cold)
	draw_texture_rect(_cold, rect, false)
	if _warm_glow == null:
		_warm_glow = _gradient_texture(true, WARM)
	draw_texture_rect(_warm_glow, rect, false)
	if _vignette == null:
		_vignette = _vignette_texture()
	draw_texture_rect(_vignette, rect, false)


func _draw_roads(current: MapLook) -> void:
	for node: MapNode in map.nodes:
		for index: int in node.links:
			var target: MapNode = map.nodes[index]
			var taken: bool = map.path.has(node) and map.path.has(target)
			var from: Vector2 = node_position(node)
			var to: Vector2 = node_position(target)
			draw_line(from, to, ROAD_EDGE, ROAD_WIDTH + 4.0)
			draw_line(from, to, PATH_COLOR if taken else current.road, ROAD_WIDTH)
			_dotted(from, to, PATH_COLOR.lightened(0.3) if taken else current.road.lightened(0.28), 2.0)


## Specks drifting over the map, placed from a hash of their number so they need no state.
func _draw_weather(current: MapLook) -> void:
	var spec: Dictionary = WEATHER[current.weather]
	var velocity: Vector2 = spec["velocity"]
	var alpha: float = spec["alpha"]
	for i: int in int(spec["count"]):
		var at: Vector2 = Vector2(
			fposmod(_hash(i * 2.0) * size.x + velocity.x * time, size.x),
			fposmod(_hash(i * 2.0 + 1.0) * size.y + velocity.y * time, size.y)).floor()
		var fade: float = alpha
		match current.weather:
			MapLook.Weather.GLINTS:
				fade *= pow(0.5 + 0.5 * sin(time * 2.0 + _hash(i + 77.0) * TAU), 3.0)
			MapLook.Weather.EMBERS, MapLook.Weather.SPORES:
				at.x += roundf(sin(time * 1.5 + _hash(i + 31.0) * TAU) * 4.0)
				fade *= 0.55 + 0.45 * sin(time * 3.0 + _hash(i + 9.0) * TAU)
			MapLook.Weather.MIST:
				draw_rect(Rect2(at.round() - WISP_SIZE * 0.5, WISP_SIZE), Color(current.weather_color, fade))
				continue
		draw_rect(Rect2(at, Vector2.ONE * float(spec["size"])), Color(current.weather_color, fade))


## A dotted line in whole pixels (it matches the pixel art).
func _dotted(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var length: float = from.distance_to(to)
	var steps: int = maxi(roundi(length / 12.0), 1)
	for i: int in steps:
		var a: Vector2 = from.lerp(to, (i + 0.25) / steps)
		var b: Vector2 = from.lerp(to, (i + 0.55) / steps)
		draw_line(a.round(), b.round(), color, width)


static func _hash(n: float) -> float:
	return fposmod(sin(n * 12.9898) * 43758.5453, 1.0)


## A coarse gradient (drawn stretched without smoothing, so its steps are blocky like the art):
## `glow`: a radial light from the bottom centre; else the cold tint fading down from the top.
static func _gradient_texture(glow: bool, color: Color) -> Texture2D:
	var gradient: Gradient = Gradient.new()
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.width = OVERLAY_SIZE.x
	texture.height = OVERLAY_SIZE.y
	if glow:
		gradient.colors = PackedColorArray([color, Color(color, 0.0)])
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 1.0)
		texture.fill_to = Vector2(1.0, 0.45)
	else:
		gradient.colors = PackedColorArray([Color(color, COLD_ALPHA), Color(color, 0.0)])
		texture.fill_from = Vector2(0.5, 0.0)
		texture.fill_to = Vector2(0.5, 0.7)
	texture.gradient = gradient
	return texture


static func _vignette_texture() -> Texture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	gradient.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0.02, 0.01, 0.04, 0.6)])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.width = OVERLAY_SIZE.x
	texture.height = OVERLAY_SIZE.y
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 1.0)
	texture.gradient = gradient
	return texture
