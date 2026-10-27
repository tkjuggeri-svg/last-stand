class_name VectorGround
extends Node2D
## The graveyard ground in the vector test style (branch vector-test, never merge), detailed. A noise-textured base
## (grass tones, worn soil, a cold tint toward the crypt, a warm one toward the fortress, darker edges), then curved
## grass in three tones, pale flowers, fallen leaves and stones, the roads as layered strokes with grit, embedded flat
## stones, wheel ruts, grass overhanging their edges and puddles, a paved warm plaza at the fortress, and glows.
## Built from the level's Floor rect, its Lane* paths and the fortress; VectorSkin bakes it into one texture.

const SEED: int = 1337
const ROAD_CLEAR: float = 36.0
## The base texture's resolution against the floor (it is drawn with linear filtering).
const BASE_SHARE: float = 0.5

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
	if _base_texture == null:
		_base_texture = _bake_base()
	# Kept in a member: draw commands only reference the texture (a local would be freed and draw white).
	draw_texture_rect(_base_texture, floor_rect, false)
	_patches()
	for lane: PackedVector2Array in lanes:
		_road(lane)
	for lane: PackedVector2Array in lanes:
		_road_detail(lane)
	_plaza()
	_grass()
	_flowers_and_leaves()
	_stones()
	for lane: PackedVector2Array in lanes:
		_road_edges(lane)


func _bake_base() -> Texture2D:
	var size: Vector2i = Vector2i((floor_rect.size * BASE_SHARE).ceil())
	var image: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	var broad: FastNoiseLite = FastNoiseLite.new()
	broad.seed = SEED
	broad.frequency = 0.012
	broad.fractal_octaves = 4
	var fine: FastNoiseLite = FastNoiseLite.new()
	fine.seed = SEED + 7
	fine.frequency = 0.09
	var soil: FastNoiseLite = FastNoiseLite.new()
	soil.seed = SEED + 13
	soil.frequency = 0.008
	var dark: Color = Color("16241b")
	var mid: Color = Color("2a432f")
	var light: Color = Color("43603d")
	var earth: Color = Color("3b3125")
	var cold: Color = Color("1b3039")
	var warm: Color = Color("4b4a2f")
	for y: int in size.y:
		for x: int in size.x:
			var world: Vector2 = floor_rect.position + Vector2(x, y) / BASE_SHARE
			var n: float = broad.get_noise_2d(x, y) * 0.5 + 0.5
			var c: Color = dark.lerp(mid, smoothstep(0.2, 0.55, n)).lerp(light, smoothstep(0.6, 0.85, n))
			c = c.lightened(fine.get_noise_2d(x, y) * 0.06)
			var s: float = soil.get_noise_2d(x, y)
			if s > 0.35:
				c = c.lerp(earth, smoothstep(0.35, 0.6, s) * 0.7)
			c = c.lerp(cold, clampf(1.0 - world.distance_to(crypt) / 420.0, 0.0, 1.0) * 0.55)
			c = c.lerp(warm, clampf(1.0 - world.distance_to(fortress) / 300.0, 0.0, 1.0) * 0.35)
			var edge: float = minf(minf(world.x - floor_rect.position.x, floor_rect.end.x - world.x), minf(world.y - floor_rect.position.y, floor_rect.end.y - world.y))
			c = c.darkened(clampf(1.0 - edge / 140.0, 0.0, 1.0) * 0.45)
			image.set_pixel(x, y, c)
	return ImageTexture.create_from_image(image)


func _patches() -> void:
	var colors: Array[Color] = [Color("4a6a3c"), Color("1f4250"), Color("5c5a34"), Color("2a5240")]
	for i: int in 40:
		var r: float = _rng.randf_range(60.0, 150.0)
		var at: Vector2 = _random_point()
		draw_texture_rect(VectorStyle.glow_texture(colors[i % colors.size()]), Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0), false,
			Color(1, 1, 1, _rng.randf_range(0.03, 0.08)))


## Grass clumps: curved blades in three tones, the light one on the lit side.
func _grass() -> void:
	var tones: Array[Color] = [Color("2c4a31"), Color("46703f"), Color("7aa05a")]
	for i: int in 2600:
		var at: Vector2 = _random_point()
		if _near_road(at, ROAD_CLEAR) or _near_pad(at, 30.0) or at.distance_to(fortress) < 95.0:
			continue
		var dead: bool = _rng.randf() < 0.15
		var blades: int = _rng.randi_range(3, 6)
		var height: float = _rng.randf_range(4.0, 8.5)
		for b: int in blades:
			var lean: float = _rng.randf_range(-3.5, 3.5)
			var base: Vector2 = at + Vector2(_rng.randf_range(-3.0, 3.0), _rng.randf_range(-1.0, 1.0))
			var tone: Color = Color("8a7d4c") if dead else tones[mini(2, int((lean + 3.5) / 2.5))]
			VectorPaint.strand(self, base, base + Vector2(lean * 0.3, -height * 0.6), base + Vector2(lean, -height), 1.6, Color(tone, 0.85))


func _flowers_and_leaves() -> void:
	for i: int in 220:
		var at: Vector2 = _random_point()
		if _near_road(at, ROAD_CLEAR) or _near_pad(at, 30.0):
			continue
		if _rng.randf() < 0.45:
			var petal: Color = Color("c9d9ff") if at.distance_to(crypt) < 380.0 else Color("f0d98a")
			for k: int in 5:
				var a: float = TAU * k / 5.0
				draw_circle(at + Vector2(cos(a), sin(a)) * 1.1, 0.9, Color(petal, 0.9), true, -1.0, true)
			draw_circle(at, 0.6, Color("ffcf6b"), true, -1.0, true)
		else:
			var dir: Vector2 = Vector2.from_angle(_rng.randf() * TAU)
			var leaf: PackedVector2Array = PackedVector2Array([at - dir * 2.5, at + dir.orthogonal() * 1.2, at + dir * 2.5, at - dir.orthogonal() * 1.2])
			VectorPaint.fill(self, leaf, Color("7a4a26").lerp(Color("a8743a"), _rng.randf()))


func _stones() -> void:
	for i: int in 90:
		var at: Vector2 = _random_point()
		if _near_road(at, ROAD_CLEAR + 4.0) or _near_pad(at, 34.0):
			continue
		var r: float = _rng.randf_range(2.5, 7.0)
		draw_colored_polygon(VectorStyle.ellipse(at + Vector2(1.2, r * 0.55), r * 1.15, r * 0.5, 14), Color(0, 0, 0, 0.35))
		VectorPaint.painted(self, VectorStyle.ellipse(at, r, r * 0.72, 14), Color("6b737c"), r * 0.45, 0.35, 0.8)
		if _rng.randf() < 0.4:
			draw_colored_polygon(VectorStyle.ellipse(at + Vector2(-r * 0.3, r * 0.2), r * 0.5, r * 0.25, 10), Color(Color("4f6b3a"), 0.8))


func _stroke(lane: PackedVector2Array, width: float, color: Color, offset: Vector2 = Vector2.ZERO) -> void:
	var moved: PackedVector2Array = VectorPaint.moved(lane, offset)
	draw_polyline(moved, color, width, true)
	# Round joins and caps (draw_polyline joins are square at wide widths).
	for i: int in range(0, moved.size(), 3):
		draw_circle(moved[i], width * 0.5, color, true, -1.0, true)


func _road(lane: PackedVector2Array) -> void:
	_stroke(lane, 68.0, Color(0, 0, 0, 0.35), Vector2(0, 5))
	_stroke(lane, 62.0, Color("2a1f17"))
	_stroke(lane, 54.0, Color("57422f"))
	_stroke(lane, 44.0, Color("66503b"))
	_stroke(lane, 26.0, Color(1, 0.95, 0.85, 0.04))


func _road_detail(lane: PackedVector2Array) -> void:
	for i: int in range(0, lane.size() - 1, 1):
		var dir: Vector2 = (lane[i + 1] - lane[i]).normalized()
		var side: Vector2 = dir.orthogonal()
		# Grit: small light and dark specks over the whole width.
		for k: int in 2:
			var at: Vector2 = lane[i] + side * _rng.randf_range(-24.0, 24.0)
			var light: bool = _rng.randf() > 0.55
			draw_colored_polygon(VectorStyle.ellipse(at, _rng.randf_range(0.6, 1.6), _rng.randf_range(0.5, 1.1), 6), Color("8d765c") if light else Color("3b2c20"))
		# Flat stones bedded in the dirt, more toward the edges.
		if i % 5 == 0:
			var off: float = _rng.randf_range(-22.0, 22.0)
			if absf(off) > 8.0:
				var at: Vector2 = lane[i] + side * off
				var r: float = _rng.randf_range(2.5, 4.5)
				VectorPaint.painted(self, VectorStyle.ellipse(at, r, r * 0.7, 12), Color("7d7468"), 1.2, 0.25, 0.7)
		if i % 90 == 45:
			var at: Vector2 = lane[i] + side * _rng.randf_range(-10.0, 10.0)
			draw_colored_polygon(VectorStyle.ellipse(at, 9.0, 4.0, 18), Color("1c2a36"))
			draw_colored_polygon(VectorStyle.ellipse(at + Vector2(-2, -1), 5.0, 1.4, 14), Color(0.7, 0.85, 1.0, 0.35))
	for side_sign: float in [-1.0, 1.0]:
		var rut: PackedVector2Array = PackedVector2Array()
		for i: int in lane.size():
			var j: int = mini(i + 1, lane.size() - 1)
			var k: int = maxi(i - 1, 0)
			rut.append(lane[i] + (lane[j] - lane[k]).normalized().orthogonal() * 9.0 * side_sign)
		draw_polyline(rut, Color(0, 0, 0, 0.22), 2.4, true)
		draw_polyline(VectorPaint.moved(rut, Vector2(-0.8, -1.0)), Color(1, 0.9, 0.75, 0.08), 1.0, true)


## Grass leaning over the road's edges, so the road sits in the ground instead of on it.
func _road_edges(lane: PackedVector2Array) -> void:
	for i: int in range(0, lane.size() - 1, 3):
		var normal: Vector2 = (lane[i + 1] - lane[i]).normalized().orthogonal()
		for side_sign: float in [-1.0, 1.0]:
			var at: Vector2 = lane[i] + normal * side_sign * _rng.randf_range(27.0, 32.0)
			if at.distance_to(fortress) < 95.0:
				continue
			var lean: Vector2 = -normal * side_sign * _rng.randf_range(2.0, 5.0) + Vector2(0, -_rng.randf_range(3.0, 6.0))
			VectorPaint.strand(self, at, at + lean * 0.5, at + lean, 1.6, Color(Color("4f7a43"), 0.9))


func _plaza() -> void:
	draw_colored_polygon(VectorStyle.regular(fortress + Vector2(0, 8), 10, 94, 52, 0.0), Color(0, 0, 0, 0.35))
	VectorPaint.painted(self, VectorStyle.regular(fortress, 10, 90, 47, 0.0), Color("6f675e"), 5.0, 0.3, 1.2)
	# Flagstones: rings and radial joints, each stone slightly different.
	for ring: int in 3:
		var r0: float = 0.35 + ring * 0.22
		var r1: float = r0 + 0.22
		for k: int in 14:
			var a0: float = TAU * k / 14.0 + ring * 0.2
			var a1: float = a0 + TAU / 14.0
			var stone: PackedVector2Array = PackedVector2Array([fortress + Vector2(cos(a0) * 90 * r0, sin(a0) * 47 * r0), fortress + Vector2(cos(a1) * 90 * r0, sin(a1) * 47 * r0),
				fortress + Vector2(cos(a1) * 90 * r1, sin(a1) * 47 * r1), fortress + Vector2(cos(a0) * 90 * r1, sin(a0) * 47 * r1)])
			var tone: Color = Color("7d746a").darkened(((k * 7 + ring * 3) % 5) * 0.05)
			VectorPaint.painted(self, stone, tone, 1.2, 0.2, 0.7)


func _draw_glow(layer: Node2D) -> void:
	VectorStyle.draw_glow(layer, VectorStyle.WARM_GLOW, fortress, 170.0, 0.24)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED + 1
	for i: int in 22:
		var at: Vector2 = crypt + Vector2(rng.randf_range(-190.0, 190.0), rng.randf_range(-120.0, 150.0))
		VectorStyle.draw_glow(layer, VectorStyle.COLD_GLOW, at, rng.randf_range(8.0, 20.0), 0.4)
		# A glowing mushroom cluster at the heart of some of the cold lights.
		if i % 3 == 0:
			for k: int in 3:
				var m: Vector2 = at + Vector2(k * 3.0 - 3.0, (k % 2) * 1.5)
				layer.draw_circle(m, 1.3, Color(0.55, 0.95, 1.0, 0.8), true, -1.0, true)
	VectorStyle.draw_glow(layer, VectorStyle.COLD_GLOW, crypt + Vector2(0, -10), 150.0, 0.13)


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
