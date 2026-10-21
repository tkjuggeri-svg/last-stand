extends RefCounted
## The Drowned Marsh, chapter 2's battlefield (dev-time art generator): the baked ground (sodden grass,
## murky pools, muddy causeways with boardwalks where they skirt the water), its props, the drowned
## chapels the dead wade out of, and the ripple ring around a wading hero.
## The ground is baked from the level itself (floor rect, lane Path2Ds, the Water polygons, fortress
## position), so it has to be regenerated after changing those.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")
const EnvironmentArt: GDScript = preload("res://tools/art/environment_art.gd")

const PROP_SIZE: Vector2i = Vector2i(32, 48)
## Every prop stands on this art row, like the graveyard's (EnvironmentArt.PROP_BASE).
const PROP_BASE: int = 44
const PROPS: Array[String] = ["reeds", "cattails", "willow", "stump", "sunken_boat", "marsh_lantern", "drowned_tomb", "mushrooms"]
const CHAPEL_SIZE: Vector2i = Vector2i(64, 64)
const RIPPLE_SIZE: Vector2i = Vector2i(32, 16)
## Lane half-width in art px (the trodden mud), and how close to water a lane gets boards.
const LANE_HALF: float = 8.5
const BOARDWALK_NEAR: float = 14.0


# ---------------------------------------------------------------- ground

## Bakes the floor and the wall band. band and scale are in world px; returns the image in art px.
## Lanes are polylines and pools polygons, in world px.
func ground(floor_rect: Rect2, lanes_world: Array[Array], pools_world: Array[PackedVector2Array], keep_world: Vector2,
		band: int, scale: float) -> Image:
	var origin: Vector2 = floor_rect.position - Vector2(band, band)
	var size: Vector2i = Vector2i(((floor_rect.size + Vector2(band, band) * 2.0) / scale).round())
	var floor_art: Rect2i = Rect2i(Vector2i(int(band / scale), int(band / scale)), Vector2i((floor_rect.size / scale).round()))
	var lanes: Array[Array] = []
	for lane_world: Array in lanes_world:
		var lane: Array[Vector2] = []
		for p: Vector2 in lane_world:
			lane.append((p - origin) / scale)
		lanes.append(lane)
	var pools: Array[PackedVector2Array] = []
	var pool_boxes: Array[Rect2] = []
	for pool_world: PackedVector2Array in pools_world:
		var pool: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in pool_world:
			pool.append((p - origin) / scale)
		pools.append(pool)
		var box: Rect2 = Rect2(pool[0], Vector2.ZERO)
		for p: Vector2 in pool:
			box = box.expand(p)
		pool_boxes.append(box.grow(BOARDWALK_NEAR + 4.0))
	var keep: Vector2 = (keep_world - origin) / scale
	var img: Image = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4321
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = 11
	noise.frequency = 0.09
	var bog: FastNoiseLite = FastNoiseLite.new()
	bog.seed = 23
	bog.frequency = 0.02
	var waves: FastNoiseLite = FastNoiseLite.new()
	waves.seed = 5
	waves.frequency = 0.05

	var water_field: PackedFloat32Array = PackedFloat32Array()
	water_field.resize(size.x * size.y)
	for y: int in size.y:
		for x: int in size.x:
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var n: float = noise.get_noise_2d(x, y)
			var fine: float = noise.get_noise_2d(x * 3.1, y * 3.1)
			var water_d: float = _water_distance(p, pools, pool_boxes) + fine * 1.2
			water_field[y * size.x + x] = water_d
			var lane_d: float = INF
			var nearest: Array = lanes[0]
			var apron_d: float = INF
			for lane: Array in lanes:
				var d: float = _distance_to_polyline(p, lane)
				if d < lane_d:
					lane_d = d
					nearest = lane
				# A trodden patch of mud in front of each drowned chapel (the lane's first point).
				apron_d = minf(apron_d, p.distance_to(lane[0]) - 13.0 + fine * 2.5)
			lane_d += fine * 1.4
			var clearing_d: float = p.distance_to(keep) - 36.0 + fine * 2.5
			var path_d: float = minf(minf(lane_d - LANE_HALF, clearing_d), apron_d)
			var color: Color
			if path_d < -0.5:
				color = _causeway(p, n, lane_d, nearest, keep, water_d, rng)
			elif water_d < 0.0:
				color = _water(x, y, -water_d, n, waves)
			elif path_d < 1.2:
				color = P.MUD[1] if (x + y) % 3 != 0 else P.MARSH_GRASS[1]
			elif water_d < 3.0:
				# The shore: wet black mud, lighter where it dries.
				color = Canvas.shade(P.MUD, 0.3 + water_d * 0.2 + n * 0.2, x, y, true)
			else:
				var soggy: float = bog.get_noise_2d(x, y)
				var value: float = 0.45 + n * 0.45 + fine * 0.12
				if soggy > 0.42:
					# A sodden bog patch: the grass gives way to dark, wet earth.
					color = Canvas.shade(P.MARSH_GRASS, value * 0.6, x, y, true).lerp(P.MUD[2], 0.45)
				elif soggy > 0.22:
					color = Canvas.shade(P.MOSS, value * 0.85, x, y, true)
				else:
					color = Canvas.shade(P.MARSH_GRASS, value, x, y, true)
				# The grass is wetter and darker near the water and at the path's edge.
				if water_d < 7.0 or path_d < 3.0:
					color = color.lerp(P.MARSH_GRASS[0], 0.35)
			img.set_pixel(x, y, color)

	var on_land: Callable = func(p: Vector2) -> bool:
		var i: int = clampi(int(p.y), 0, size.y - 1) * size.x + clampi(int(p.x), 0, size.x - 1)
		return (water_field[i] > 4.0 and not lanes.any(func(lane: Array) -> bool: return _distance_to_polyline(p, lane) < 12.0)
			and p.distance_to(keep) >= 42.0 and Rect2(floor_art).grow(-3).has_point(p))
	var in_water: Callable = func(p: Vector2, margin: float) -> bool:
		var i: int = clampi(int(p.y), 0, size.y - 1) * size.x + clampi(int(p.x), 0, size.x - 1)
		return water_field[i] < -margin
	_shore_reeds(img, water_field, size, lanes, rng)
	_lily_pads(img, in_water, rng)
	_grass_details(img, on_land, rng)
	EnvironmentArt.new().wall_band(img, floor_art)
	return img


## Signed distance to the nearest pool's edge (negative inside a pool).
func _water_distance(p: Vector2, pools: Array[PackedVector2Array], boxes: Array[Rect2]) -> float:
	var best: float = INF
	for i: int in pools.size():
		if not boxes[i].has_point(p):
			continue
		var pool: PackedVector2Array = pools[i]
		var edge: float = INF
		for k: int in pool.size():
			edge = minf(edge, p.distance_to(Geometry2D.get_closest_point_to_segment(p, pool[k], pool[(k + 1) % pool.size()])))
		var d: float = -edge if Geometry2D.is_point_in_polygon(p, pool) else edge
		best = minf(best, d)
	return best


## Murky water: dark in the deep middle, lighter in the shallows, with wind ripples catching the light.
func _water(x: int, y: int, depth: float, n: float, waves: FastNoiseLite) -> Color:
	var value: float = 0.62 - minf(depth / 16.0, 1.0) * 0.48 + n * 0.08
	if depth < 2.0:
		value = 0.7  # the bright line where the water meets the mud
	var color: Color = Canvas.shade(P.WATER.slice(0, 6), value, x, y, true)
	# Ripples: short horizontal glints where the wave noise crests (light from the top-left sky).
	var crest: float = waves.get_noise_2d(x * 0.6, y * 2.2)
	if crest > 0.42 and depth > 2.5:
		color = P.WATER[5] if crest > 0.55 else P.WATER[4]
	return color


## The lanes: trodden mud with puddles; boardwalks of planks where they pass close to the water, and
## cobbles where they meet the fortress.
func _causeway(p: Vector2, n: float, lane_d: float, lane: Array, keep: Vector2, water_d: float, rng: RandomNumberGenerator) -> Color:
	var x: int = int(p.x)
	var y: int = int(p.y)
	var gate: Vector2 = lane[lane.size() - 1]
	if p.distance_to(gate + (gate - keep).normalized() * 6.0) < 13.0 and p.distance_to(keep) > 26.0:
		var cell: Vector2i = Vector2i(floori(p.x / 3.0 + (floori(p.y / 3.0) % 2) * 0.5), floori(p.y / 3.0))
		var in_x: float = fposmod(p.x / 3.0 + (cell.y % 2) * 0.5, 1.0)
		var in_y: float = fposmod(p.y / 3.0, 1.0)
		if in_x < 0.28 or in_y < 0.3:
			return P.MUD[0]
		return P.STONE[3] if (cell.x * 7 + cell.y * 3) % 4 != 0 else P.STONE[2]
	if water_d < BOARDWALK_NEAR and lane_d < LANE_HALF - 1.0:
		# Planks laid across the lane's direction, with dark gaps between them and nail heads.
		var dir: Vector2 = _segment_direction(p, lane)
		var along: float = p.dot(dir)
		var plank: int = floori(along / 3.0)
		if fposmod(along, 3.0) < 0.8:
			return P.WOOD[0]
		var plank_value: float = 0.5 + ((plank * 7) % 5) * 0.06 + n * 0.1
		if lane_d > LANE_HALF - 2.5:
			plank_value -= 0.15  # the plank ends, in the shadow of the rails
		return Canvas.shade(P.WOOD.slice(1, 5), plank_value, x, y, true)
	var value: float = 0.42 + n * 0.3
	if lane_d > 2.0 and lane_d < 3.6:
		value -= 0.22  # cart ruts
	var color: Color = Canvas.shade(P.DIRT.slice(0, 4), value, x, y, true)
	if n > 0.38 and lane_d < 5.0:
		color = P.WATER[3] if n > 0.45 else P.MUD[1]  # puddles in the ruts
	elif rng.randf() < 0.012:
		color = P.DIRT[4]  # pebble
	return color


func _segment_direction(p: Vector2, points: Array) -> Vector2:
	var best: float = INF
	var dir: Vector2 = Vector2.RIGHT
	for i: int in points.size() - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var d: float = p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))
		if d < best and a != b:
			best = d
			dir = (b - a).normalized()
	return dir


## Reeds stand in clumps along the shore (in the shallows and on the mud), leaning with the wind.
func _shore_reeds(img: Image, water_field: PackedFloat32Array, size: Vector2i, lanes: Array[Array], rng: RandomNumberGenerator) -> void:
	for i: int in 2200:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		var d: float = water_field[int(p.y) * size.x + int(p.x)]
		if d < -4.0 or d > 3.0:
			continue
		if lanes.any(func(lane: Array) -> bool: return _distance_to_polyline(p, lane) < 11.0):
			continue
		var tip: Vector2i = Vector2i(p)
		var height: int = rng.randi_range(2, 5)
		for k: int in height:
			var lean: int = 1 if k >= height - 1 and i % 2 == 0 else 0
			_plot(img, tip + Vector2i(lean, -k), P.REED[1 + mini(k, 3)] if k > 0 else P.REED[0])
		if i % 7 == 0:
			_plot(img, tip + Vector2i(0, -height), P.WOOD[2])  # a cattail head


## Lily pads float in clusters on the open water (never touching the shore).
func _lily_pads(img: Image, in_water: Callable, rng: RandomNumberGenerator) -> void:
	var size: Vector2i = img.get_size()
	for i: int in 180:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if not in_water.call(p, 5.0):
			continue
		var count: int = rng.randi_range(1, 3)
		for k: int in count:
			var at: Vector2i = Vector2i(p) + Vector2i(rng.randi_range(-4, 4), rng.randi_range(-2, 2))
			for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)]:
				_plot(img, at + d, P.LILY[2])
			_plot(img, at + Vector2i(-1, -1), P.LILY[3])
			_plot(img, at + Vector2i(0, 1), P.LILY[0])
			_plot(img, at + Vector2i(1, 1), P.LILY[0])
			if rng.randf() < 0.15:
				_plot(img, at + Vector2i(0, -1), Color("c8c2a8"))  # a pale flower


## Tufts, a few toadstools and twigs on the grass.
func _grass_details(img: Image, on_land: Callable, rng: RandomNumberGenerator) -> void:
	var size: Vector2i = img.get_size()
	for i: int in 2400:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if not on_land.call(p):
			continue
		var tip: Vector2i = Vector2i(p)
		_plot(img, tip + Vector2i(0, 1), P.MARSH_GRASS[0])
		_plot(img, tip, P.MARSH_GRASS[4])
		_plot(img, tip + Vector2i(1, -1), P.MARSH_GRASS[5])
		if i % 3 == 0:
			_plot(img, tip + Vector2i(-1, 0), P.MARSH_GRASS[4])
			_plot(img, tip + Vector2i(-1, -1), P.REED[2] if i % 2 == 0 else P.MARSH_GRASS[5])
	for i: int in 50:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if not on_land.call(p):
			continue
		_plot(img, Vector2i(p), Color("b8a888"))  # a pale toadstool cap
		_plot(img, Vector2i(p) + Vector2i(1, 0), Color("8f8068"))
		_plot(img, Vector2i(p) + Vector2i(0, 1), P.MARSH_GRASS[0])
	for i: int in 30:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if not on_land.call(p):
			continue
		var dir: Vector2i = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, -1)][rng.randi_range(0, 2)]
		for step: int in rng.randi_range(3, 5):
			_plot(img, Vector2i(p) + dir * step, P.DEAD_WOOD[2])


func _distance_to_polyline(p: Vector2, points: Array) -> float:
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
			"reeds":
				_reeds(c, false)
				shadow = Vector2(9, 2)
			"cattails":
				_reeds(c, true)
				shadow = Vector2(8, 2)
			"willow":
				_willow(c)
				shadow = Vector2(12, 3)
			"stump":
				_stump(c)
				shadow = Vector2(8, 2.4)
			"sunken_boat":
				_sunken_boat(c)
				shadow = Vector2(12, 2.4)
			"marsh_lantern":
				_marsh_lantern(c)
				shadow = Vector2(4, 1.4)
			"drowned_tomb":
				_drowned_tomb(c)
				shadow = Vector2(8, 2.2)
			"mushrooms":
				_mushrooms(c)
				shadow = Vector2(6, 1.6)
		c.finish()
		c.ground_shadow(Vector2(17, PROP_BASE - 0.5), shadow)
		frames.append(c.image)
	return frames


## A clump of reeds (or cattails with their brown heads), fanning out and bending in the wind.
func _reeds(c: Canvas, cattails: bool) -> void:
	var stems: Array[Vector3] = [Vector3(10, -14, -3), Vector3(13, -20, -2), Vector3(16, -24, 1), Vector3(19, -19, 3),
		Vector3(22, -15, 4), Vector3(15, -17, -1), Vector3(18, -22, 2)]
	for s: Vector3 in stems:
		c.part()
		var base: Vector2 = Vector2(s.x, PROP_BASE - 1)
		var top: Vector2 = Vector2(s.x + s.z, PROP_BASE - 1 + s.y)
		c.capsule(base, top, 0.6, P.REED)
		if cattails and int(s.x) % 2 == 0:
			c.part()
			c.capsule(top + Vector2(0, 1), top + Vector2(0, 4), 1.1, P.WOOD.slice(1, 5))
	c.part()
	c.ellipse(Vector2(16, PROP_BASE - 1), Vector2(6, 1.6), P.MUD, 0.0, 0.0)


## A drowned willow: a crooked trunk leaning over the water, bare drooping strands hanging from it.
func _willow(c: Canvas) -> void:
	var base: Vector2 = Vector2(15, PROP_BASE - 1)
	c.part()
	c.capsule(base, base + Vector2(2, -12), 3.0, P.DEAD_WOOD)
	c.capsule(base + Vector2(2, -12), base + Vector2(-1, -24), 2.4, P.DEAD_WOOD)
	c.capsule(base + Vector2(-4, 0), base + Vector2(-1, -3), 1.4, P.DEAD_WOOD)
	c.capsule(base + Vector2(4, 0), base + Vector2(2, -4), 1.4, P.DEAD_WOOD)
	var boughs: Array[Array] = [[Vector2(-1, -24), Vector2(-10, -30)], [Vector2(-1, -24), Vector2(8, -31)],
		[Vector2(1, -18), Vector2(11, -22)], [Vector2(0, -20), Vector2(-9, -21)]]
	for b: Array in boughs:
		c.capsule(base + (b[0] as Vector2), base + (b[1] as Vector2), 1.0, P.DEAD_WOOD)
	# Hanging strands of grey-green moss, swaying a little to the right.
	for k: int in 14:
		var from: Vector2 = base + Vector2(-11 + k * 1.6, -30 + absf(k - 6.5) * 0.9)
		var length: float = 8.0 + float((k * 5) % 7)
		c.part()
		c.line(from, from + Vector2(1, length), P.HOOD[2] if k % 3 != 0 else P.HOOD[3])


func _stump(c: Canvas) -> void:
	c.part()
	c.cylinder(16, 33, 42, 5.0, 2.2, P.DEAD_WOOD, P.WOOD.slice(2, 5))
	# Rings on the cut top, a split, roots into the mud, a shelf fungus.
	c.px(16, 33, P.WOOD[1])
	c.px(15, 33, P.WOOD[2])
	c.line(Vector2(18, 35), Vector2(19, 40), P.OUTLINE)
	c.part()
	c.capsule(Vector2(11, 42), Vector2(7, 44), 1.0, P.DEAD_WOOD)
	c.capsule(Vector2(21, 42), Vector2(25, 44), 1.0, P.DEAD_WOOD)
	c.part()
	c.ellipse(Vector2(12, 37), Vector2(2.2, 1.0), [Color("6b5a3c"), Color("9a8458"), Color("c4ad78")], 0.5)


## A rowing boat half sunk in the mud, its prow up, a broken oar across it.
func _sunken_boat(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(4, 41), Vector2(26, 37), Vector2(30, 33), Vector2(27, 41), Vector2(8, 44)]),
		P.WOOD, Vector3(-0.3, -0.4, 0.8))
	c.part()
	c.polygon(PackedVector2Array([Vector2(8, 40), Vector2(25, 37.5), Vector2(26, 39.5), Vector2(9, 42)]), P.WOOD.slice(0, 3), Vector3(0, 0, 1))
	for x: int in range(10, 25, 4):
		c.line(Vector2(x, 39 + (25 - x) * 0.05), Vector2(x, 42 - (x - 10) * 0.15), P.WOOD[3])
	c.part()
	c.capsule(Vector2(6, 36), Vector2(22, 44), 0.6, P.WOOD.slice(2, 5))
	c.part()
	c.ellipse(Vector2(15, 44), Vector2(11, 1.6), P.WATER.slice(2, 6), 0.0)


## A lantern hung from a crooked pole, its pale witch-green glass guiding the dead through the fog
## (a PointLight2D sits on it in the level).
func _marsh_lantern(c: Canvas) -> void:
	c.part()
	c.capsule(Vector2(14, 44), Vector2(16, 16), 0.9, P.DEAD_WOOD)
	c.capsule(Vector2(16, 16), Vector2(22, 15), 0.7, P.DEAD_WOOD)
	c.line(Vector2(21, 16), Vector2(21, 18), P.IRON[2])
	c.part()
	c.block(Rect2(19, 18, 5, 1), 6.0, P.IRON.slice(1, 5), P.IRON.slice(0, 4), false)
	c.part(true)
	c.rect(Rect2i(20, 20, 3, 4), P.SOUL[2])
	c.px(21, 21, P.SOUL[4])
	c.px(21, 22, P.SOUL[3])


## A tombstone sunk at a slant into the bog, slick with weed.
func _drowned_tomb(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(10, 42), Vector2(12, 28), Vector2(15, 25), Vector2(19, 26), Vector2(21, 29), Vector2(20, 43)]),
		P.STONE, Vector3(-0.25, -0.1, 1), true)
	c.line(Vector2(12.5, 28), Vector2(15, 25.5), P.STONE[5])
	c.rect(Rect2i(14, 30, 4, 1), P.STONE[1])
	c.rect(Rect2i(15, 29, 1, 4), P.STONE[1])
	for y: int in range(36, 43):
		c.px(11 + (y % 3), y, P.LILY[1] if y % 2 == 0 else P.LILY[2])
	c.part()
	c.ellipse(Vector2(16, 43), Vector2(8, 1.6), P.WATER.slice(2, 6), 0.0)


func _mushrooms(c: Canvas) -> void:
	var caps: Array[Vector3] = [Vector3(13, 38, 3.2), Vector3(19, 40, 2.4), Vector3(16, 42, 1.8)]
	for cap: Vector3 in caps:
		c.part()
		c.rect(Rect2i(int(cap.x), int(cap.y), 1, PROP_BASE - int(cap.y)), P.BONE[2])
		c.part()
		c.ellipse(Vector2(cap.x + 0.5, cap.y), Vector2(cap.z, cap.z * 0.6), [Color("4a3a2a"), Color("7a6040"), Color("a48558"), Color("c8ad7a")], 0.0, -0.1)
	c.px(12, 37, Color("e8dcb0"))
	c.px(19, 39, Color("e8dcb0"))


# ---------------------------------------------------------------- the drowned chapel

## Where the dead come from: a stone chapel half sunk into the marsh, leaning, its bell-cote empty
## (the Tollkeeper took the bell), water lapping at the doorway that glows a cold soul-green.
## 64x64, standing on art row 60.
func chapel() -> Image:
	var c: Canvas = Canvas.new(CHAPEL_SIZE.x, CHAPEL_SIZE.y)
	# The walls, sunk to the sills: a squat nave seen from the front.
	c.part()
	c.block(Rect2(14, 34, 36, 10), 14.0, P.STONE.slice(2, 7), P.STONE.slice(1, 6))
	for y: int in range(45, 59, 3):
		for x: int in range(14, 50):
			if c.is_filled(x, y) and (x + (floori(y / 3.0) % 2) * 3) % 6 == 0:
				c.px(x, y, c.get_color(x, y).lerp(P.STONE[0], 0.4))
	# Weed and slime up to the old waterline.
	for x: int in range(14, 50):
		for y: int in range(54, 59):
			if c.is_filled(x, y) and (x * 3 + y) % 4 != 0:
				c.px(x, y, P.LILY[1] if (x + y) % 2 == 0 else P.MOSS[1])
	# A steep gable with a leaning bell-cote on top: two posts and an arch with nothing hanging in it.
	c.part()
	c.polygon(PackedVector2Array([Vector2(12, 35), Vector2(32, 17), Vector2(52, 35)]), P.SLATE, Vector3(0, -1, 0.5), true)
	c.line(Vector2(12, 35), Vector2(32, 17), P.SLATE[4])
	c.part()
	c.block(Rect2(28, 10, 9, 2), 8.0, P.STONE.slice(3, 7), P.STONE.slice(1, 6), false)
	c.part()
	c.rect(Rect2i(30, 12, 5, 5), P.OUTLINE)
	c.line(Vector2(30, 12), Vector2(34, 12), P.STONE[2])
	c.px(32, 13, P.IRON[3])  # the empty bell's hook
	# A tall arched doorway: dark, glowing soul-green, flooded at the bottom.
	c.part()
	c.polygon(PackedVector2Array([Vector2(26, 60), Vector2(26, 46), Vector2(29, 42), Vector2(35, 42), Vector2(38, 46), Vector2(38, 60)]),
		[P.OUTLINE, P.OUTLINE], Vector3(0, 0, 1))
	c.part(true)
	for y: int in range(44, 60):
		for x: int in range(27, 38):
			var glow: float = 1.0 - Vector2(x - 32.0, (y - 56.0) * 1.2).length() / 8.5
			if glow > 0.0 and c.is_filled(x, y):
				c.px(x, y, Canvas.shade(P.SOUL.slice(0, 4), glow, x, y, true))
	# Two lancet windows, one broken.
	for x: int in [19, 43]:
		c.part(true)
		c.rect(Rect2i(x, 44, 2, 5), P.SOUL[1] if x == 19 else P.OUTLINE)
	c.line(Vector2(46, 38), Vector2(48, 44), P.STONE[0])  # a crack where it settled
	# The marsh water around its foot.
	c.part()
	c.ellipse(Vector2(32, 60), Vector2(25, 3.2), P.WATER.slice(1, 6), 0.0)
	c.finish()
	c.ground_shadow(Vector2(34, 60.5), Vector2(25, 3.0))
	return c.image


# ---------------------------------------------------------------- ripples

## Rings spreading on the water around a wading hero (soft: no outline), looping.
func ripple_frames() -> Array[Image]:
	var frames: Array[Image] = []
	for f: int in 4:
		var img: Image = Image.create_empty(RIPPLE_SIZE.x, RIPPLE_SIZE.y, false, Image.FORMAT_RGBA8)
		for ring: int in 2:
			var t: float = fposmod(f / 4.0 + ring * 0.5, 1.0)
			var radius: Vector2 = Vector2(6.0 + t * 8.0, 2.4 + t * 3.2)
			var alpha: float = 1.0 - t * 0.7
			for k: int in 40:
				var a: float = TAU * k / 40.0
				var p: Vector2i = Vector2i((Vector2(16, 8) + Vector2(cos(a), sin(a)) * radius).round())
				if p.x >= 0 and p.y >= 0 and p.x < RIPPLE_SIZE.x and p.y < RIPPLE_SIZE.y:
					var color: Color = P.WATER[6] if sin(a) < 0.0 else P.WATER[5]
					img.set_pixelv(p, Color(color, alpha))
		frames.append(img)
	return frames
