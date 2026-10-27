class_name VectorGround
extends Node2D
## The graveyard ground in the vector test style (branch vector-test, never merge), after draw.ts buildBackground:
## a radial base gradient, soft colour patches, grass tufts, stones, the roads as layered strokes with pebbles,
## a paved warm plaza at the fortress and cold glows by the crypt. Built from the level's Floor rect, its Lane*
## paths and the fortress, drawn once (Godot keeps the draw commands until queue_redraw).

const SEED: int = 1337
const ROAD_CLEAR: float = 38.0

var floor_rect: Rect2
var lanes: Array[PackedVector2Array] = []
var fortress: Vector2
var crypt: Vector2
var avoid: Array[Vector2] = []  # build slots: no tufts or stones on the pads
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _base_texture: Texture2D


func _ready() -> void:
	VectorStyle.make_glow_layer(self, _draw_glow)


func _draw() -> void:
	_rng.seed = SEED
	_base()
	_patches()
	_tufts()
	_stones()
	for lane: PackedVector2Array in lanes:
		_road(lane)
	for lane: PackedVector2Array in lanes:
		_road_detail(lane)
	_plaza()


func _base() -> void:
	var gradient: Gradient = VectorStyle.make_gradient([0.0, 0.6, 1.0], [Color("2e4433"), Color("1a2b22"), Color("0f1916")])
	# Kept in a member: the draw commands only reference it, and a local would be freed when _draw returns
	# (the ground then drew white).
	_base_texture = VectorStyle.radial_texture(gradient, 128, Vector2(0.55, 0.55), 0.6)
	draw_texture_rect(_base_texture, floor_rect, false)


func _patches() -> void:
	var colors: Array[Color] = [Color("4a6a3c"), Color("1f4250"), Color("5c5a34"), Color("2a5240")]
	for i: int in 60:
		var r: float = _rng.randf_range(60.0, 150.0)
		var at: Vector2 = _random_point()
		draw_texture_rect(VectorStyle.glow_texture(colors[i % colors.size()]), Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0), false,
			Color(1, 1, 1, _rng.randf_range(0.06, 0.16)))


func _tufts() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	for i: int in 1400:
		var at: Vector2 = _random_point()
		if _near_road(at, ROAD_CLEAR) or _near_pad(at, 30.0):
			continue
		var color: Color = Color("3f6e4a") if _rng.randf() > 0.5 else Color("57804f")
		if _rng.randf() < 0.18:
			color = Color("7a7448")  # dead grass
		color.a = _rng.randf_range(0.35, 0.7)
		for k: int in [-1, 0, 1]:
			points.append(at + Vector2(k * 2.5, 0))
			points.append(at + Vector2(k * 4.5, -4.0 - _rng.randf() * 4.0))
			colors.append(color)
	draw_multiline_colors(points, colors, 1.4)


func _stones() -> void:
	for i: int in 70:
		var at: Vector2 = _random_point()
		if _near_road(at, ROAD_CLEAR + 4.0) or _near_pad(at, 34.0):
			continue
		var r: float = _rng.randf_range(3.0, 8.0)
		draw_colored_polygon(VectorStyle.ellipse(at + Vector2(1, r * 0.5), r * 1.1, r * 0.5, 14), Color(0, 0, 0, 0.3))
		VectorStyle.shape(self, VectorStyle.ellipse(at, r, r * 0.75, 14), Color("59616b"), Color("2c323a"), Color(0, 0, 0, 0))
		VectorStyle.shine(self, at + Vector2(-r * 0.25, -r * 0.25), r * 0.45, r * 0.25, 0.12)


func _stroke(lane: PackedVector2Array, width: float, color: Color, offset: Vector2 = Vector2.ZERO) -> void:
	var moved: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in lane:
		moved.append(p + offset)
	draw_polyline(moved, color, width, true)
	# Round joins and caps (draw_polyline joins are square at wide widths).
	for i: int in range(0, moved.size(), 3):
		draw_circle(moved[i], width * 0.5, color, true, -1.0, true)


func _road(lane: PackedVector2Array) -> void:
	_stroke(lane, 66.0, Color(0, 0, 0, 0.3), Vector2(0, 4))
	_stroke(lane, 60.0, Color("2b1f17"))
	_stroke(lane, 52.0, Color("5b4532"))


func _road_detail(lane: PackedVector2Array) -> void:
	_stroke(lane, 40.0, Color("6c5440"))
	_stroke(lane, 22.0, Color(1, 1, 1, 0.035))
	for i: int in range(0, lane.size() - 1, 2):
		var dir: Vector2 = (lane[i + 1] - lane[i]).normalized()
		var side: Vector2 = dir.orthogonal()
		var at: Vector2 = lane[i] + side * _rng.randf_range(-22.0, 22.0)
		var r: float = _rng.randf_range(0.8, 2.2)
		var light: bool = _rng.randf() > 0.55
		draw_colored_polygon(VectorStyle.ellipse(at, r * 1.3, r, 8), Color("8a7258") if light else Color("3a2b1f"))
	# Wheel ruts: two faint darker lines either side of the middle.
	for side_sign: float in [-1.0, 1.0]:
		var rut: PackedVector2Array = PackedVector2Array()
		for i: int in lane.size():
			var j: int = mini(i + 1, lane.size() - 1)
			var k: int = maxi(i - 1, 0)
			var normal: Vector2 = (lane[j] - lane[k]).normalized().orthogonal()
			rut.append(lane[i] + normal * 9.0 * side_sign)
		draw_polyline(rut, Color(0, 0, 0, 0.16), 2.0, true)


func _plaza() -> void:
	draw_colored_polygon(VectorStyle.regular(fortress + Vector2(0, 8), 10, 92, 50, 0.0), Color(0, 0, 0, 0.3))
	VectorStyle.shape(self, VectorStyle.regular(fortress, 10, 88, 46, 0.0), Color("7a7066"), Color("3e3833"))
	for ring: float in [0.72, 0.45]:
		var rim: PackedVector2Array = VectorStyle.regular(fortress, 10, 88 * ring, 46 * ring, 0.0)
		rim.append(rim[0])
		draw_polyline(rim, Color(VectorStyle.INK, 0.35), 1.2, true)
	for i: int in 10:
		var a: float = TAU * i / 10.0
		draw_line(fortress + Vector2(cos(a) * 88 * 0.45, sin(a) * 46 * 0.45), fortress + Vector2(cos(a) * 88, sin(a) * 46), Color(VectorStyle.INK, 0.3), 1.0, true)


func _draw_glow(layer: Node2D) -> void:
	VectorStyle.draw_glow(layer, VectorStyle.WARM_GLOW, fortress, 150.0, 0.22)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED + 1
	for i: int in 14:
		var at: Vector2 = crypt + Vector2(rng.randf_range(-170.0, 170.0), rng.randf_range(-110.0, 130.0))
		VectorStyle.draw_glow(layer, VectorStyle.COLD_GLOW, at, rng.randf_range(10.0, 22.0), 0.35)
	VectorStyle.draw_glow(layer, VectorStyle.COLD_GLOW, crypt + Vector2(0, -10), 120.0, 0.12)


func _random_point() -> Vector2:
	return floor_rect.position + Vector2(_rng.randf() * floor_rect.size.x, _rng.randf() * floor_rect.size.y)


func _near_road(at: Vector2, distance: float) -> bool:
	for lane: PackedVector2Array in lanes:
		for i: int in range(0, lane.size(), 4):
			if lane[i].distance_squared_to(at) < distance * distance:
				return true
	return false


func _near_pad(at: Vector2, distance: float) -> bool:
	for pad: Vector2 in avoid:
		if pad.distance_to(at) < distance:
			return true
	return false
