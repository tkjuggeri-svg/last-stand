extends RefCounted
## The battlefield (dev-time art generator): the baked arena ground, graveyard props, the crypt the
## dead crawl out of, and the build-slot foundations.
## The ground is baked from the level itself (floor rect, lane Path2D, fortress position), so it has
## to be regenerated after changing those.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const PROP_SIZE: Vector2i = Vector2i(32, 48)
## Every prop stands on this art row (the sprite's offset puts it on the node's origin).
const PROP_BASE: int = 44
const PROPS: Array[String] = ["tomb_round", "tomb_cross", "tomb_tall", "grave_mound", "dead_tree", "dead_tree_small",
	"bush", "rocks", "lantern", "broken_pillar", "bones", "fence"]
const CRYPT_SIZE: Vector2i = Vector2i(64, 64)
const SLOT_SIZE: Vector2i = Vector2i(28, 20)
const MOTE_SIZE: Vector2i = Vector2i(4, 4)


# ---------------------------------------------------------------- ground

## Bakes the floor and the wall band. band and scale are in world px; returns the image in art px.
func ground(floor_rect: Rect2, lane_world: Array[Vector2], keep_world: Vector2, band: int, scale: float) -> Image:
	var origin: Vector2 = floor_rect.position - Vector2(band, band)
	var size: Vector2i = Vector2i(((floor_rect.size + Vector2(band, band) * 2.0) / scale).round())
	var floor_art: Rect2i = Rect2i(Vector2i(int(band / scale), int(band / scale)), Vector2i((floor_rect.size / scale).round()))
	var lane: Array[Vector2] = []
	for p: Vector2 in lane_world:
		lane.append((p - origin) / scale)
	var keep: Vector2 = (keep_world - origin) / scale
	var spawn: Vector2 = lane[0]
	var img: Image = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1234
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.09
	var patches: FastNoiseLite = FastNoiseLite.new()
	patches.seed = 19
	patches.frequency = 0.016
	var moss: FastNoiseLite = FastNoiseLite.new()
	moss.seed = 31
	moss.frequency = 0.03

	for y: int in size.y:
		for x: int in size.x:
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var n: float = noise.get_noise_2d(x, y)
			var fine: float = noise.get_noise_2d(x * 3.1, y * 3.1)
			var lane_d: float = _distance_to_polyline(p, lane) + fine * 1.4
			var clearing_d: float = p.distance_to(keep) - 36.0 + fine * 2.5
			# A trodden patch from the crypt door (see the level's Crypt, 35 art px west of the spawn) to the lane.
			var apron_d: float = p.distance_to(Geometry2D.get_closest_point_to_segment(p, spawn + Vector2(-35, -5), spawn)) - 9.0 + fine * 2.5
			var path_d: float = minf(minf(lane_d - 8.5, clearing_d), apron_d)
			var color: Color
			if path_d < -0.5:
				color = _dirt(p, n, lane_d, lane, keep, rng)
			elif path_d < 1.2:
				color = P.DIRT[1] if (x + y) % 3 != 0 else P.GRASS[1]  # ragged edge where grass meets the path
			else:
				var dry: float = patches.get_noise_2d(x, y)
				var mossy: float = moss.get_noise_2d(x, y)
				var value: float = 0.45 + n * 0.45 + fine * 0.12
				if dry > 0.32:
					color = Canvas.shade(P.GRASS_DRY, value, x, y, true)
				elif mossy > 0.35:
					color = Canvas.shade(P.MOSS, value * 0.9, x, y, true)
				else:
					color = Canvas.shade(P.GRASS, value, x, y, true)
				# Ambient occlusion near the path: the grass is trampled and darker at the edge.
				if path_d < 3.0:
					color = color.lerp(P.GRASS[0], 0.35)
			img.set_pixel(x, y, color)

	var keep_out: Callable = func(p: Vector2) -> bool:
		return (_distance_to_polyline(p, lane) < 12.0 or p.distance_to(keep) < 42.0
			or not Rect2(floor_art).grow(-3).has_point(p))
	_grass_details(img, keep_out, rng, patches)
	_wall_band(img, floor_art)
	return img


## Lane and clearing dirt: worn ruts along the lane, pebbles, puddles, cobbles at the gate.
func _dirt(p: Vector2, n: float, lane_d: float, lane: Array[Vector2], keep: Vector2, rng: RandomNumberGenerator) -> Color:
	var x: int = int(p.x)
	var y: int = int(p.y)
	var value: float = 0.5 + n * 0.35
	# Two cart ruts follow the lane.
	if lane_d > 2.0 and lane_d < 3.6:
		value -= 0.25
	var color: Color = Canvas.shade(P.DIRT.slice(1, 6), value, x, y, true)
	# Cobbles in front of the gate (the lane's last stretch).
	var gate: Vector2 = lane[lane.size() - 1]
	if p.distance_to(gate + Vector2(-6, 0)) < 13.0 and p.distance_to(keep) > 26.0:
		var cell: Vector2i = Vector2i(floori(p.x / 3.0 + (floori(p.y / 3.0) % 2) * 0.5), floori(p.y / 3.0))
		var in_x: float = fposmod(p.x / 3.0 + (cell.y % 2) * 0.5, 1.0)
		var in_y: float = fposmod(p.y / 3.0, 1.0)
		if in_x < 0.28 or in_y < 0.3:
			return P.DIRT[0]
		return P.STONE[3] if (cell.x * 7 + cell.y * 3) % 4 != 0 else P.STONE[2]
	if rng.randf() < 0.014:
		return P.DIRT[5]  # pebble
	if rng.randf() < 0.01:
		return P.DIRT[0]
	return color


## Tufts, flowers, twigs and stones on the grass, plus a few scattered bones.
func _grass_details(img: Image, keep_out: Callable, rng: RandomNumberGenerator, patches: FastNoiseLite) -> void:
	var size: Vector2i = img.get_size()
	for i: int in 2600:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if keep_out.call(p):
			continue
		var dry: bool = patches.get_noise_2d(p.x, p.y) > 0.3
		var tip: Vector2i = Vector2i(p)
		var light: Color = P.GRASS_DRY[3] if dry else P.GRASS[5]
		var mid: Color = P.GRASS_DRY[2] if dry else P.GRASS[4]
		# A small tuft: dark root, lit blades leaning to the right (wind).
		_plot(img, tip + Vector2i(0, 1), P.GRASS[0])
		_plot(img, tip, mid)
		_plot(img, tip + Vector2i(1, -1), light)
		if i % 3 == 0:
			_plot(img, tip + Vector2i(-1, 0), mid)
			_plot(img, tip + Vector2i(-1, -1), light if i % 2 == 0 else mid)
	for i: int in 70:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if keep_out.call(p):
			continue
		var bloom: Color = [Color("8a7ea8"), Color("c8c2a8"), Color("9c5a5a")][i % 3]
		_plot(img, Vector2i(p), bloom)
		_plot(img, Vector2i(p) + Vector2i(0, 1), P.GRASS[2])
	for i: int in 60:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if not keep_out.call(p):
			_pebble(img, Vector2i(p), rng.randi_range(1, 2))
	for i: int in 30:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if keep_out.call(p):
			continue
		var dir: Vector2i = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, -1)][rng.randi_range(0, 2)]
		for step: int in rng.randi_range(3, 5):
			_plot(img, Vector2i(p) + dir * step, P.WOOD[1])
		_plot(img, Vector2i(p) + dir * 2 + Vector2i(0, -1), P.WOOD[2])
	for i: int in 10:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if keep_out.call(p):
			continue
		for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(-1, -1), Vector2i(3, 1)]:
			_plot(img, Vector2i(p) + d, P.BONE[2])
		_plot(img, Vector2i(p) + Vector2i(1, 1), P.GRASS[0])


func _pebble(img: Image, at: Vector2i, radius: int) -> void:
	for y: int in range(-1, radius + 1):
		for x: int in range(-radius, radius + 1):
			_plot(img, at + Vector2i(x, y + 1), P.GRASS[0])
	for y: int in range(-1, radius):
		for x: int in range(-radius, radius + 1):
			_plot(img, at + Vector2i(x, y), P.STONE[2] if y >= 0 or x > 0 else P.STONE[3])
	_plot(img, at + Vector2i(-radius, -1), P.STONE[4])


## The arena wall: on the north side its south face shows (3/4 view), elsewhere only its top with
## battlements on the inner rim; it casts a shadow onto the floor below and to the right.
func _wall_band(img: Image, floor_art: Rect2i) -> void:
	var size: Vector2i = img.get_size()
	var face_height: int = 9
	for y: int in size.y:
		for x: int in size.x:
			var p: Vector2i = Vector2i(x, y)
			if floor_art.has_point(p):
				# Cast shadow from the north and west walls (light from the top-left).
				var from_top: int = y - floor_art.position.y
				var from_left: int = x - floor_art.position.x
				var from_right: int = floor_art.end.x - 1 - x
				var from_bottom: int = floor_art.end.y - 1 - y
				var shade: float = 0.0
				if from_top < 6:
					shade = maxf(shade, 0.5 - from_top * 0.08)
				if from_left < 5:
					shade = maxf(shade, 0.42 - from_left * 0.08)
				if from_right < 2 or from_bottom < 2:
					shade = maxf(shade, 0.25)
				if shade > 0.0:
					img.set_pixel(x, y, img.get_pixel(x, y).lerp(P.OUTLINE, shade))
				continue
			var color: Color
			var north: bool = y < floor_art.position.y and x >= floor_art.position.x - 2 and x < floor_art.end.x + 2
			var rim: int = floor_art.position.y - 1 - y
			if north and rim < face_height:
				# The north wall's face: masonry courses, moss at the foot.
				var row: int = face_height - 1 - rim
				var stagger: int = 3 if floori(row / 3.0) % 2 == 1 else 0
				var mortar: bool = row % 3 == 2 or (x + stagger) % 7 == 0
				var value: float = 0.55 - row * 0.03 + (0.06 if (x * 13 + floori(row / 3.0) * 7) % 5 == 0 else 0.0)
				color = P.STONE[1] if mortar else Canvas.shade(P.STONE.slice(1, 6), value, x, y, true)
				if rim < 2 and (x * 3 + y) % 4 != 0:
					color = P.MOSS[1] if (x + y) % 2 == 0 else P.MOSS[0]
				if row == 0:
					color = P.STONE[5]  # lit coping edge
			else:
				# Wall top: big flagstones, lit, with merlons along the floor side.
				var rx: int = floori((x + (floori(y / 6.0) % 2) * 5) / 10.0)
				var ry: int = floori(y / 6.0)
				var joint: bool = y % 6 == 5 or (x + (ry % 2) * 5) % 10 == 9
				color = P.STONE[2] if joint else Canvas.shade(P.STONE.slice(2, 7), 0.55 + ((rx * 7 + ry * 3) % 4) * 0.06, x, y, true)
				var inner: int = _distance_to_floor(p, floor_art)
				if inner <= 2 and not north:
					var along: int = x if (y < floor_art.position.y or y >= floor_art.end.y) else y
					color = P.STONE[5] if floori(along / 3.0) % 2 == 0 else P.STONE[1]
					if inner == 0 and floori(along / 3.0) % 2 == 0:
						color = P.STONE[3]
				elif north and rim == face_height:
					color = P.STONE[1]
			img.set_pixel(x, y, color)


func _distance_to_floor(p: Vector2i, floor_art: Rect2i) -> int:
	var dx: int = maxi(floor_art.position.x - 1 - p.x, p.x - floor_art.end.x)
	var dy: int = maxi(floor_art.position.y - 1 - p.y, p.y - floor_art.end.y)
	return maxi(dx, dy)


func _distance_to_polyline(p: Vector2, points: Array[Vector2]) -> float:
	var best: float = INF
	for i: int in points.size() - 1:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, points[i], points[i + 1])))
	return best


func _plot(img: Image, p: Vector2i, color: Color) -> void:
	if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
		img.set_pixelv(p, color)


# ---------------------------------------------------------------- props

## One frame per entry of PROPS (32x48), standing on PROP_BASE.
func prop_frames() -> Array[Image]:
	var frames: Array[Image] = []
	for prop: String in PROPS:
		var c: Canvas = Canvas.new(PROP_SIZE.x, PROP_SIZE.y)
		var shadow: Vector2 = Vector2(7, 2)
		match prop:
			"tomb_round":
				_tomb_round(c)
			"tomb_cross":
				_tomb_cross(c)
			"tomb_tall":
				_tomb_tall(c)
				shadow = Vector2(8, 2.4)
			"grave_mound":
				_grave_mound(c)
				shadow = Vector2(9, 2.2)
			"dead_tree":
				_dead_tree(c, 1.0)
				shadow = Vector2(11, 3)
			"dead_tree_small":
				_dead_tree(c, 0.7)
				shadow = Vector2(8, 2.4)
			"bush":
				_bush(c)
				shadow = Vector2(9, 2.4)
			"rocks":
				_rocks(c)
				shadow = Vector2(10, 2.4)
			"lantern":
				_lantern(c)
				shadow = Vector2(4, 1.4)
			"broken_pillar":
				_broken_pillar(c)
				shadow = Vector2(8, 2.4)
			"bones":
				_bones(c)
				shadow = Vector2(0, 0)
			"fence":
				_fence(c)
				shadow = Vector2(11, 1.6)
		c.finish()
		if shadow.x > 0.0:
			c.ground_shadow(Vector2(17, PROP_BASE - 0.5), shadow)
		frames.append(c.image)
	return frames


func _tomb_round(c: Canvas) -> void:
	c.part()
	c.block(Rect2(10, 36, 12, 4), 4.0, P.STONE.slice(2, 7), P.STONE.slice(1, 5))
	c.part()
	c.polygon(PackedVector2Array([Vector2(11.5, 37), Vector2(11.5, 27), Vector2(13, 24.5), Vector2(16, 23.5),
		Vector2(19, 24.5), Vector2(20.5, 27), Vector2(20.5, 37)]), P.STONE, Vector3(-0.2, -0.1, 1), true)
	c.line(Vector2(12, 27), Vector2(14, 24.5), P.STONE[5])
	# Engraving and a crack, moss creeping up from the ground.
	c.rect(Rect2i(14, 28, 4, 1), P.STONE[1])
	c.rect(Rect2i(15, 27, 2, 4), P.STONE[1])
	c.line(Vector2(19, 30), Vector2(17.5, 34), P.STONE[0])
	for x: int in range(12, 20):
		if x % 3 != 0:
			c.px(x, 36, P.MOSS[2] if x % 2 == 0 else P.MOSS[1])


func _tomb_cross(c: Canvas) -> void:
	c.part()
	c.block(Rect2(12, 38, 8, 3), 3.0, P.STONE.slice(2, 7), P.STONE.slice(1, 5))
	c.part()
	c.block(Rect2(14.5, 22, 3, 1), 16.0, P.STONE.slice(3, 7), P.STONE.slice(1, 6), false)
	c.part()
	c.block(Rect2(10.5, 26, 11, 1), 3.0, P.STONE.slice(3, 7), P.STONE.slice(1, 6), false)
	c.px(15, 30, P.MOSS[1])
	c.px(16, 35, P.MOSS[2])
	c.px(11, 28, P.MOSS[1])


func _tomb_tall(c: Canvas) -> void:
	c.part()
	c.block(Rect2(9, 37, 14, 4), 4.0, P.STONE.slice(2, 7), P.STONE.slice(1, 5))
	c.part()
	c.block(Rect2(11, 15, 10, 3), 20.0, P.STONE.slice(3, 7), P.STONE.slice(1, 6))
	c.part()
	c.polygon(PackedVector2Array([Vector2(11, 15), Vector2(16, 9), Vector2(21, 15)]), P.STONE.slice(2, 7), Vector3(-0.4, -0.6, 0.7))
	# A carved skull.
	c.rect(Rect2i(14, 22, 4, 3), P.BONE[1])
	c.px(14, 23, P.STONE[0])
	c.px(17, 23, P.STONE[0])
	c.rect(Rect2i(15, 25, 2, 1), P.BONE[0])
	for y: int in range(27, 35, 2):
		c.rect(Rect2i(13, y, 6, 1), P.STONE[2])
	c.line(Vector2(19, 18), Vector2(20, 26), P.STONE[1])


func _grave_mound(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(16, 39), Vector2(8.5, 3.6), P.DIRT, 0.0, 0.05)
	for x: int in range(9, 24, 2):
		c.px(x, 38 + (x % 3), P.DIRT[1])
	c.part()
	c.rect(Rect2i(15, 27, 2, 11), P.WOOD[2])
	c.rect(Rect2i(16, 27, 1, 11), P.WOOD[1])
	c.rect(Rect2i(12, 30, 8, 2), P.WOOD[3])
	c.rect(Rect2i(12, 31, 8, 1), P.WOOD[1])
	# Withered flowers left at the grave.
	c.px(19, 38, Color("8a7ea8"))
	c.px(20, 37, Color("6c6288"))


## A gnarled dead tree: twisted trunk, crooked bare branches reaching up and out.
func _dead_tree(c: Canvas, scale: float) -> void:
	var base: Vector2 = Vector2(16, PROP_BASE - 1)
	c.part()
	c.capsule(base + Vector2(-3, 0), base + Vector2(-1, -4), 1.6, P.DEAD_WOOD)
	c.capsule(base + Vector2(3, 0), base + Vector2(1, -4), 1.4, P.DEAD_WOOD)
	var top: Vector2 = base + Vector2(1, -22.0 * scale)
	c.capsule(base, base + Vector2(-1, -10.0 * scale), 2.6 * scale + 0.4, P.DEAD_WOOD)
	c.capsule(base + Vector2(-1, -10.0 * scale), top, 2.0 * scale + 0.3, P.DEAD_WOOD)
	var branches: Array[Array] = [
		[Vector2(-1, -12), Vector2(-9, -20), 1.2], [Vector2(-9, -20), Vector2(-12, -27), 0.8],
		[Vector2(-9, -20), Vector2(-14, -19), 0.7], [Vector2(1, -18), Vector2(9, -26), 1.1],
		[Vector2(9, -26), Vector2(11, -33), 0.7], [Vector2(9, -26), Vector2(14, -27), 0.6],
		[Vector2(1, -22), Vector2(-2, -33), 0.9], [Vector2(-2, -33), Vector2(-5, -38), 0.6],
		[Vector2(-2, -33), Vector2(2, -39), 0.6], [Vector2(0, -15), Vector2(7, -15), 0.8],
	]
	for b: Array in branches:
		var a: Vector2 = base + (b[0] as Vector2) * scale
		var e: Vector2 = base + (b[1] as Vector2) * scale
		c.capsule(a, e, maxf(float(b[2]) * scale, 0.55), P.DEAD_WOOD)
	# A hollow in the trunk.
	c.px(int(base.x), int(base.y - 7 * scale), P.OUTLINE)
	c.px(int(base.x), int(base.y - 6 * scale), P.DEAD_WOOD[0])


func _bush(c: Canvas) -> void:
	var blobs: Array[Vector3] = [Vector3(11, 39, 4.2), Vector3(21, 39, 4.0), Vector3(16, 36.5, 5.2), Vector3(13, 34, 3.6), Vector3(19, 34, 3.6)]
	for b: Vector3 in blobs:
		c.part()
		c.ellipse(Vector2(b.x, b.y), Vector2(b.z, b.z * 0.85), P.MOSS + [P.GRASS[5]], 0.0, -0.05)
	for p: Vector2i in [Vector2i(12, 35), Vector2i(19, 33), Vector2i(17, 38), Vector2i(22, 37)]:
		c.px(p.x, p.y, P.BANNER[2])  # dark berries
	c.px(15, 32, P.GRASS[5])


func _rocks(c: Canvas) -> void:
	for r: Vector3 in [Vector3(12, 39, 4.6), Vector3(20, 40, 3.8), Vector3(16, 41.5, 2.6), Vector3(23.5, 42, 2.0)]:
		c.part()
		c.ellipse(Vector2(r.x, r.y), Vector2(r.z, r.z * 0.8), P.STONE.slice(1, 7), 0.0, 0.0)
	c.px(11, 37, P.MOSS[2])
	c.px(12, 36, P.MOSS[1])
	c.px(19, 38, P.MOSS[1])


## An iron lantern on a crooked post; the glass glows warm (a PointLight2D sits on it in the level).
func _lantern(c: Canvas) -> void:
	c.part()
	c.rect(Rect2i(15, 18, 2, 26), P.WOOD[2])
	c.rect(Rect2i(16, 18, 1, 26), P.WOOD[1])
	c.rect(Rect2i(16, 17, 5, 1), P.IRON[2])
	c.part()
	c.block(Rect2(18, 18, 5, 1), 6.0, P.IRON.slice(1, 5), P.IRON.slice(0, 4), false)
	c.part(true)
	c.rect(Rect2i(19, 20, 3, 4), P.FIRE[3])
	c.px(20, 21, P.FIRE[5])
	c.px(20, 22, P.FIRE[4])


func _broken_pillar(c: Canvas) -> void:
	c.part()
	c.block(Rect2(9, 37, 14, 4), 3.0, P.STONE.slice(2, 7), P.STONE.slice(1, 5))
	c.part()
	c.cylinder(16, 23, 38, 4.5, 2.0, P.STONE, P.STONE.slice(2, 7))
	for x: int in range(12, 21):
		var cut: int = [0, 2, 1, 3, 1, 0, 2, 1, 0][x - 12]
		for k: int in cut:
			c.erase(x, 21 + k)
	for y: int in range(25, 38, 4):
		c.line(Vector2(12, y), Vector2(20, y), P.STONE[1])
	# A fallen drum beside it.
	c.part()
	c.ellipse(Vector2(24.5, 41), Vector2(3.2, 2.2), P.STONE.slice(1, 6))
	for y: int in range(30, 37):
		if y % 2 == 0:
			c.px(12, y, P.MOSS[1])


func _bones(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(14, 39), Vector2(2.6, 2.2), P.BONE, 0.0, 0.05)
	c.px(13, 39, P.OUTLINE)
	c.px(15, 39, P.OUTLINE)
	c.px(14, 41, P.BONE[1])
	c.part()
	c.capsule(Vector2(17, 42), Vector2(23, 40), 0.7, P.BONE)
	c.capsule(Vector2(9, 42.5), Vector2(13, 43), 0.6, P.BONE)
	c.part()
	c.capsule(Vector2(19, 43), Vector2(21, 44), 0.6, P.BONE)


func _fence(c: Canvas) -> void:
	for x: int in [5, 12, 20, 27]:
		c.part()
		var height: int = 12 if x != 20 else 8
		c.rect(Rect2i(x, PROP_BASE - height, 2, height), P.WOOD[3])
		c.rect(Rect2i(x + 1, PROP_BASE - height, 1, height), P.WOOD[1])
		c.px(x, PROP_BASE - height - 1, P.WOOD[3])
	c.part()
	c.line(Vector2(5, 35), Vector2(19, 35), P.WOOD[3])
	c.line(Vector2(5, 36), Vector2(19, 36), P.WOOD[1])
	c.line(Vector2(5, 40), Vector2(28, 40), P.WOOD[3])
	c.line(Vector2(5, 41), Vector2(28, 41), P.WOOD[1])
	c.line(Vector2(21, 37), Vector2(26, 33), P.WOOD[2])  # a broken rail hanging down


# ---------------------------------------------------------------- crypt

## The crypt at the graveyard: a stone mausoleum with a pitched slate roof, a dark doorway glowing
## faintly green, an angel-less plinth on top. 64x64, standing on art row 60.
func crypt() -> Image:
	var c: Canvas = Canvas.new(CRYPT_SIZE.x, CRYPT_SIZE.y)
	# Steps and body.
	c.part()
	c.block(Rect2(12, 50, 40, 6), 4.0, P.STONE.slice(2, 7), P.STONE.slice(1, 6))
	c.part()
	c.block(Rect2(14, 30, 36, 14), 16.0, P.STONE.slice(2, 7), P.STONE.slice(1, 6))
	for y: int in range(45, 60, 3):
		for x: int in range(14, 50):
			if c.is_filled(x, y) and (x + (floori(y / 3.0) % 2) * 3) % 6 != 0:
				continue
			if c.is_filled(x, y):
				c.px(x, y, c.get_color(x, y).lerp(P.STONE[0], 0.4))
	# Columns flanking the door.
	for x: float in [20.0, 44.0]:
		c.part()
		c.cylinder(x, 44, 58, 2.6, 1.2, P.STONE, P.STONE.slice(3, 7))
	# Pitched roof seen from the front: a big triangle gable with slate slopes behind it.
	c.part()
	c.polygon(PackedVector2Array([Vector2(11, 31), Vector2(32, 13), Vector2(53, 31)]), P.SLATE, Vector3(0, -1, 0.5), true)
	c.part()
	c.polygon(PackedVector2Array([Vector2(13, 44), Vector2(32, 30), Vector2(51, 44)]), P.STONE.slice(1, 6), Vector3(-0.1, 0.2, 1), true)
	c.line(Vector2(13, 44), Vector2(32, 30), P.STONE[5])
	c.line(Vector2(32, 30), Vector2(51, 44), P.STONE[2])
	c.line(Vector2(11, 31), Vector2(32, 13), P.SLATE[4])
	# A round window in the gable with a faint green light.
	c.part(true)
	c.ellipse(Vector2(32, 38), Vector2(2.5, 2.5), P.SOUL.slice(0, 3), 1.0)
	# The doorway: dark, with a ghostly green glow inside and a broken iron gate.
	c.part()
	c.rect(Rect2i(26, 47, 12, 13), P.OUTLINE)
	c.part(true)
	for y: int in range(48, 60):
		for x: int in range(27, 37):
			var glow: float = 1.0 - Vector2(x - 31.5, (y - 57.0) * 1.3).length() / 8.0
			if glow > 0.0:
				c.px(x, y, Canvas.shade(P.SOUL.slice(0, 4), glow, x, y, true))
	c.part()
	for x: int in range(27, 37, 2):
		c.rect(Rect2i(x, 48, 1, 6 if x != 31 else 11), P.IRON[3])
	c.rect(Rect2i(27, 48, 10, 1), P.IRON[2])
	c.px(25, 52, P.IRON[2])
	# Moss and cracks.
	for x: int in range(14, 50, 3):
		c.px(x, 59 + (x % 2), P.MOSS[1])
	c.line(Vector2(46, 46), Vector2(48, 52), P.STONE[0])
	c.line(Vector2(17, 26), Vector2(20, 30), P.STONE[0])
	c.finish()
	c.ground_shadow(Vector2(34, 59.5), Vector2(24, 3.5))
	return c.image


# ---------------------------------------------------------------- build slot

## A round stone foundation with four rune stones; highlighted: the runes and the rim glow gold.
func slot_frames() -> Array[Image]:
	var frames: Array[Image] = []
	for highlighted: bool in [false, true]:
		var c: Canvas = Canvas.new(SLOT_SIZE.x, SLOT_SIZE.y)
		c.part()
		c.cylinder(14, 9, 11, 12.5, 7.0, P.STONE, P.STONE.slice(1, 5))
		# Flagstone joints on the top.
		for y: int in SLOT_SIZE.y:
			for x: int in SLOT_SIZE.x:
				var d: Vector2 = (Vector2(x + 0.5, y + 0.5) - Vector2(14, 9)) / Vector2(12.5, 7.0)
				if d.length() > 0.92:
					continue
				if absf(d.length() - 0.55) < 0.07 or (d.length() > 0.55 and absi(x - 14) <= 0 and y != 9) or (d.length() > 0.55 and y == 9):
					c.px(x, y, P.STONE[1])
		var rune: Color = P.GOLD[4] if highlighted else P.GOLD[1]
		for p: Vector2i in [Vector2i(14, 3), Vector2i(14, 15), Vector2i(4, 9), Vector2i(24, 9)]:
			c.px(p.x, p.y, rune)
			c.px(p.x, p.y - 1, P.GOLD[2] if highlighted else P.STONE[1])
		c.finish()
		if highlighted:
			# Gold rim light along the outline.
			for y: int in SLOT_SIZE.y:
				for x: int in SLOT_SIZE.x:
					if c.image.get_pixel(x, y) == P.OUTLINE and y <= 12:
						c.image.set_pixel(x, y, P.GOLD[3])
		frames.append(c.image)
	return frames


## A tiny glowing mote for ambient particles (soft, no outline).
func mote() -> Image:
	var img: Image = Image.create_empty(MOTE_SIZE.x, MOTE_SIZE.y, false, Image.FORMAT_RGBA8)
	img.set_pixel(1, 1, Color("ffffff"))
	img.set_pixel(2, 1, Color(1, 1, 1, 0.6))
	img.set_pixel(1, 2, Color(1, 1, 1, 0.6))
	img.set_pixel(2, 2, Color(1, 1, 1, 0.35))
	return img
