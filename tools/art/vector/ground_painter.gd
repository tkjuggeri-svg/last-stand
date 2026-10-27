class_name GroundPainter
extends RefCounted
## Paints a level's ground (M15): the arena floor plus the visible stone wall band around it, drawn once and baked into one
## big texture (TiledGround draws it in tiles). A noise-textured base (grass tones, worn soil, cold near the crypts, warm
## near the fortress, dark toward the edges), grass clumps in three tones, flowers, leaves and mossy stones, the roads as layered
## strokes with grit, bedded stones, ruts and puddles, grass leaning over their edges, a flagstone plaza at the fortress, the
## dug earth where the roads leave the crypts, and the wall: courses of dressed stone with a lit cap and a soft shadow cast
## onto the floor. Coordinates are the level's world coordinates; the bake tool offsets and scales the canvas.

const SEED: int = 1337
const ROAD_CLEAR: float = 36.0
## The base noise texture's resolution against the world (it is drawn with linear filtering).
const BASE_SHARE: float = 0.5
const WALL_TONES: Array[Color] = [Color("565b66"), Color("4b505b"), Color("60666f"), Color("525760"), Color("444955")]

## The level's data (the bake tool fills it from the scene).
var floor_rect: Rect2
var band: float = 32.0
var lanes: Array[PackedVector2Array] = []
var fortress: Vector2
var crypts: Array[Vector2] = []
var avoid: Array[Vector2] = []  # build slots: no tufts or stones on the pads

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _base_texture: Texture2D


func paint(ci: CanvasItem) -> void:
	_rng.seed = SEED
	_base_texture = _bake_base()
	ci.draw_texture_rect(_base_texture, floor_rect, false)
	_patches(ci)
	for lane: PackedVector2Array in lanes:
		_road(ci, lane)
	for lane: PackedVector2Array in lanes:
		_road_detail(ci, lane)
	_plaza(ci)
	_digs(ci)
	_grass(ci)
	_flowers_and_leaves(ci)
	_stones(ci)
	for lane: PackedVector2Array in lanes:
		_road_edges(ci, lane)
	_glows(ci)
	_wall(ci)


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
			var crypt_d: float = 1e9
			for crypt: Vector2 in crypts:
				crypt_d = minf(crypt_d, world.distance_to(crypt))
			c = c.lerp(cold, clampf(1.0 - crypt_d / 420.0, 0.0, 1.0) * 0.55)
			c = c.lerp(warm, clampf(1.0 - world.distance_to(fortress) / 300.0, 0.0, 1.0) * 0.35)
			var edge: float = minf(minf(world.x - floor_rect.position.x, floor_rect.end.x - world.x), minf(world.y - floor_rect.position.y, floor_rect.end.y - world.y))
			c = c.darkened(clampf(1.0 - edge / 140.0, 0.0, 1.0) * 0.45)
			image.set_pixel(x, y, c)
	return ImageTexture.create_from_image(image)


func _patches(ci: CanvasItem) -> void:
	var colors: Array[Color] = [Color("4a6a3c"), Color("1f4250"), Color("5c5a34"), Color("2a5240")]
	for i: int in 40:
		var r: float = _rng.randf_range(60.0, 150.0)
		var at: Vector2 = _random_point()
		ci.draw_texture_rect(VectorStyle.glow_texture(colors[i % colors.size()]), Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1, 1, 1, _rng.randf_range(0.03, 0.08)))


func _grass(ci: CanvasItem) -> void:
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
			VectorPaint.strand(ci, base, base + Vector2(lean * 0.3, -height * 0.6), base + Vector2(lean, -height), 1.6, Color(tone, 0.85))


func _flowers_and_leaves(ci: CanvasItem) -> void:
	for i: int in 220:
		var at: Vector2 = _random_point()
		if _near_road(at, ROAD_CLEAR) or _near_pad(at, 30.0):
			continue
		var crypt_near: bool = false
		for crypt: Vector2 in crypts:
			crypt_near = crypt_near or at.distance_to(crypt) < 380.0
		if _rng.randf() < 0.45:
			var petal: Color = Color("c9d9ff") if crypt_near else Color("f0d98a")
			for k: int in 5:
				var a: float = TAU * k / 5.0
				ci.draw_circle(at + Vector2(cos(a), sin(a)) * 1.1, 0.9, Color(petal, 0.9), true, -1.0, true)
			ci.draw_circle(at, 0.6, Color("ffcf6b"), true, -1.0, true)
		else:
			var dir: Vector2 = Vector2.from_angle(_rng.randf() * TAU)
			VectorPaint.fill(ci, PackedVector2Array([at - dir * 2.5, at + dir.orthogonal() * 1.2, at + dir * 2.5, at - dir.orthogonal() * 1.2]), Color("7a4a26").lerp(Color("a8743a"), _rng.randf()))


func _stones(ci: CanvasItem) -> void:
	for i: int in 90:
		var at: Vector2 = _random_point()
		if _near_road(at, ROAD_CLEAR + 4.0) or _near_pad(at, 34.0):
			continue
		var r: float = _rng.randf_range(2.5, 7.0)
		ci.draw_colored_polygon(VectorStyle.ellipse(at + Vector2(1.2, r * 0.55), r * 1.15, r * 0.5, 14), Color(0, 0, 0, 0.35))
		VectorPaint.painted(ci, VectorStyle.ellipse(at, r, r * 0.72, 14), Color("6b737c"), r * 0.45, 0.35, 0.8)
		if _rng.randf() < 0.4:
			ci.draw_colored_polygon(VectorStyle.ellipse(at + Vector2(-r * 0.3, r * 0.2), r * 0.5, r * 0.25, 10), Color(Color("4f6b3a"), 0.8))


func _stroke(ci: CanvasItem, lane: PackedVector2Array, width: float, color: Color, offset: Vector2 = Vector2.ZERO) -> void:
	var moved: PackedVector2Array = VectorPaint.moved(lane, offset)
	ci.draw_polyline(moved, color, width, true)
	for i: int in range(0, moved.size(), 3):
		ci.draw_circle(moved[i], width * 0.5, color, true, -1.0, true)


func _road(ci: CanvasItem, lane: PackedVector2Array) -> void:
	_stroke(ci, lane, 68.0, Color(0, 0, 0, 0.35), Vector2(0, 5))
	_stroke(ci, lane, 62.0, Color("2a1f17"))
	_stroke(ci, lane, 54.0, Color("57422f"))
	_stroke(ci, lane, 44.0, Color("66503b"))
	_stroke(ci, lane, 26.0, Color(1, 0.95, 0.85, 0.04))


func _road_detail(ci: CanvasItem, lane: PackedVector2Array) -> void:
	for i: int in range(0, lane.size() - 1, 1):
		var dir: Vector2 = (lane[i + 1] - lane[i]).normalized()
		var side: Vector2 = dir.orthogonal()
		for k: int in 2:
			var at: Vector2 = lane[i] + side * _rng.randf_range(-24.0, 24.0)
			var lit: bool = _rng.randf() > 0.55
			ci.draw_colored_polygon(VectorStyle.ellipse(at, _rng.randf_range(0.6, 1.6), _rng.randf_range(0.5, 1.1), 6), Color("8d765c") if lit else Color("3b2c20"))
		if i % 5 == 0:
			var off: float = _rng.randf_range(-22.0, 22.0)
			if absf(off) > 8.0:
				var at: Vector2 = lane[i] + side * off
				var r: float = _rng.randf_range(2.5, 4.5)
				VectorPaint.painted(ci, VectorStyle.ellipse(at, r, r * 0.7, 12), Color("7d7468"), 1.2, 0.25, 0.7)
		if i % 90 == 45:
			var at: Vector2 = lane[i] + side * _rng.randf_range(-10.0, 10.0)
			ci.draw_colored_polygon(VectorStyle.ellipse(at, 9.0, 4.0, 18), Color("1c2a36"))
			ci.draw_colored_polygon(VectorStyle.ellipse(at + Vector2(-2, -1), 5.0, 1.4, 14), Color(0.7, 0.85, 1.0, 0.35))
	for side_sign: float in [-1.0, 1.0]:
		var rut: PackedVector2Array = PackedVector2Array()
		for i: int in lane.size():
			var j: int = mini(i + 1, lane.size() - 1)
			var k: int = maxi(i - 1, 0)
			rut.append(lane[i] + (lane[j] - lane[k]).normalized().orthogonal() * 9.0 * side_sign)
		ci.draw_polyline(rut, Color(0, 0, 0, 0.22), 2.4, true)
		ci.draw_polyline(VectorPaint.moved(rut, Vector2(-0.8, -1.0)), Color(1, 0.9, 0.75, 0.08), 1.0, true)


func _road_edges(ci: CanvasItem, lane: PackedVector2Array) -> void:
	for i: int in range(0, lane.size() - 1, 3):
		var normal: Vector2 = (lane[i + 1] - lane[i]).normalized().orthogonal()
		for side_sign: float in [-1.0, 1.0]:
			var at: Vector2 = lane[i] + normal * side_sign * _rng.randf_range(27.0, 32.0)
			if at.distance_to(fortress) < 95.0:
				continue
			var lean: Vector2 = -normal * side_sign * _rng.randf_range(2.0, 5.0) + Vector2(0, -_rng.randf_range(3.0, 6.0))
			VectorPaint.strand(ci, at, at + lean * 0.5, at + lean, 1.6, Color(Color("4f7a43"), 0.9))


func _plaza(ci: CanvasItem) -> void:
	ci.draw_colored_polygon(VectorStyle.regular(fortress + Vector2(0, 8), 10, 94, 52, 0.0), Color(0, 0, 0, 0.35))
	VectorPaint.painted(ci, VectorStyle.regular(fortress, 10, 90, 47, 0.0), Color("6f675e"), 5.0, 0.3, 1.2)
	for ring: int in 3:
		var r0: float = 0.35 + ring * 0.22
		var r1: float = r0 + 0.22
		for k: int in 14:
			var a0: float = TAU * k / 14.0 + ring * 0.2
			var a1: float = a0 + TAU / 14.0
			var stone: PackedVector2Array = PackedVector2Array([fortress + Vector2(cos(a0) * 90 * r0, sin(a0) * 47 * r0), fortress + Vector2(cos(a1) * 90 * r0, sin(a1) * 47 * r0),
				fortress + Vector2(cos(a1) * 90 * r1, sin(a1) * 47 * r1), fortress + Vector2(cos(a0) * 90 * r1, sin(a0) * 47 * r1)])
			VectorPaint.painted(ci, stone, Color("7d746a").darkened(((k * 7 + ring * 3) % 5) * 0.05), 1.2, 0.2, 0.7)


## Dug earth where a road leaves a crypt: a dark ring of turned soil with a few bones.
func _digs(ci: CanvasItem) -> void:
	for lane: PackedVector2Array in lanes:
		if lane.is_empty():
			continue
		var at: Vector2 = lane[0]
		for i: int in 10:
			var p: Vector2 = at + Vector2(_rng.randf_range(-34, 34), _rng.randf_range(-18, 18))
			ci.draw_colored_polygon(VectorStyle.ellipse(p, _rng.randf_range(5, 12), _rng.randf_range(3, 6), 12), Color(0.12, 0.09, 0.07, 0.5))
		for i: int in 4:
			var p: Vector2 = at + Vector2(_rng.randf_range(-26, 26), _rng.randf_range(-10, 12))
			ci.draw_line(p, p + Vector2.from_angle(_rng.randf() * TAU) * 5.0, Color("e8dcc0"), 1.6, true)


func _glows(ci: CanvasItem) -> void:
	VectorStyle.draw_glow(ci, VectorStyle.WARM_GLOW, fortress, 170.0, 0.16)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED + 1
	for crypt: Vector2 in crypts:
		for i: int in 8:
			var at: Vector2 = crypt + Vector2(rng.randf_range(-150.0, 150.0), rng.randf_range(-100.0, 120.0))
			VectorStyle.draw_glow(ci, VectorStyle.COLD_GLOW, at, rng.randf_range(8.0, 18.0), 0.3)
			if i % 3 == 0:
				for k: int in 3:
					ci.draw_circle(at + Vector2(k * 3.0 - 3.0, (k % 2) * 1.5), 1.3, Color(0.55, 0.95, 1.0, 0.8), true, -1.0, true)
		VectorStyle.draw_glow(ci, VectorStyle.COLD_GLOW, crypt + Vector2(0, -10), 130.0, 0.1)


## The wall band: four strips of dressed stone around the floor, lit along the cap, shadowing the floor.
func _wall(ci: CanvasItem) -> void:
	var outer: Rect2 = floor_rect.grow(band)
	# A soft shadow cast onto the floor first.
	for k: int in 6:
		var w: float = 4.0 + k * 3.0
		var alpha: float = 0.09
		ci.draw_rect(Rect2(floor_rect.position, Vector2(floor_rect.size.x, w)), Color(0, 0, 0, alpha))
		ci.draw_rect(Rect2(floor_rect.position, Vector2(w, floor_rect.size.y)), Color(0, 0, 0, alpha))
		ci.draw_rect(Rect2(Vector2(floor_rect.position.x, floor_rect.end.y - w), Vector2(floor_rect.size.x, w)), Color(0, 0, 0, alpha * 0.7))
		ci.draw_rect(Rect2(Vector2(floor_rect.end.x - w, floor_rect.position.y), Vector2(w, floor_rect.size.y)), Color(0, 0, 0, alpha * 0.7))
	var strips: Array[Rect2] = [
		Rect2(outer.position, Vector2(outer.size.x, band)),
		Rect2(Vector2(outer.position.x, floor_rect.end.y), Vector2(outer.size.x, band)),
		Rect2(Vector2(outer.position.x, floor_rect.position.y), Vector2(band, floor_rect.size.y)),
		Rect2(Vector2(floor_rect.end.x, floor_rect.position.y), Vector2(band, floor_rect.size.y)),
	]
	for strip: Rect2 in strips:
		ci.draw_rect(strip, Color("23212b"))
	var brick_h: float = 8.0
	var brick_w: float = 18.0
	var row_count: int = int(band / brick_h)
	for si: int in strips.size():
		var strip: Rect2 = strips[si]
		var horizontal: bool = si < 2
		var length: float = strip.size.x if horizontal else strip.size.y
		var columns: int = int(length / brick_w) + 2
		for row: int in row_count:
			var shift: float = brick_w * 0.5 if row % 2 == 0 else 0.0
			for col: int in columns:
				var along: float = col * brick_w - shift
				var a0: float = maxf(along, 0.0)
				var a1: float = minf(along + brick_w - 1.2, length)
				if a1 - a0 < 2.0:
					continue
				var tone: Color = WALL_TONES[(row * 3 + col * 5 + si) % WALL_TONES.size()]
				var rect: Rect2
				if horizontal:
					rect = Rect2(strip.position + Vector2(a0, row * brick_h + 0.6), Vector2(a1 - a0, brick_h - 1.2))
				else:
					rect = Rect2(strip.position + Vector2(row * brick_h + 0.6, a0), Vector2(brick_h - 1.2, a1 - a0))
				VectorPaint.painted(ci, PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]), tone, 1.4, 0.3, 0.6)
	# The cap: a lit line along the floor edge of each strip, a dark one on the outer edge.
	ci.draw_rect(Rect2(floor_rect.position + Vector2(0, -2), Vector2(floor_rect.size.x, 2)), Color(1, 1, 1, 0.18))
	ci.draw_rect(Rect2(Vector2(floor_rect.position.x, floor_rect.end.y), Vector2(floor_rect.size.x, 2)), Color(1, 1, 1, 0.12))
	ci.draw_rect(Rect2(floor_rect.position + Vector2(-2, 0), Vector2(2, floor_rect.size.y)), Color(1, 1, 1, 0.12))


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
