class_name GroundPainter
extends RefCounted
## Paints a level's ground (M15): the arena floor plus the visible stone wall band around it, drawn once and baked into one
## big texture (TiledGround draws it in tiles). The base is value noise in the map's palette (cold toward the gates, warm
## toward the fortress, dark toward the edges), then the map's own details by `kind`, the roads as layered strokes with
## grit, bedded stones, ruts and puddles, grass or frost leaning over their edges, a flagstone plaza at the fortress, the
## dug earth where the roads leave the gates, and the wall: courses of dressed stone with a lit cap and a soft shadow onto the
## floor. Coordinates are the level's world coordinates; the bake tool offsets and scales the canvas. With no `style` it paints
## the Crypt Road exactly as it always has; BiomeStyles gives every other map its palette.

const SEED: int = 1337
const ROAD_CLEAR: float = 36.0
## The base noise texture's resolution against the world (it is drawn with linear filtering).
const BASE_SHARE: float = 0.5
const STONE_COLD: Color = Color("6b737c")
const STONE_WARM: Color = Color("7d7468")

## The level's data (the bake tool fills it from the scene).
var floor_rect: Rect2
var band: float = 32.0
var lanes: Array[PackedVector2Array] = []
var fortress: Vector2
var gates: Array[Vector2] = []  # crypts, chapels or gates: where the roads begin
var avoid: Array[Vector2] = []  # build slots: no details on the pads
var water: Array[PackedVector2Array] = []  # pools the hero wades through (the marsh), painted as water
var style: Dictionary = {}  # BiomeStyles.of(biome); empty: the Crypt Road
var kind: String = "grass"
var litter: String = "leaves"

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _base_texture: Texture2D


func paint(ci: CanvasItem) -> void:
	_rng.seed = SEED
	_base_texture = _bake_base()
	ci.draw_texture_rect(_base_texture, floor_rect, false)
	_patches(ci)
	_pools(ci)
	for lane: PackedVector2Array in lanes:
		_road(ci, lane)
	for lane: PackedVector2Array in lanes:
		_road_detail(ci, lane)
	_plaza(ci)
	_digs(ci)
	match kind:
		"snow":
			_snow(ci)
		"moss":
			_moss(ci)
		"tile":
			_tiles(ci)
		"stone":
			_gravel(ci)
		"ash", "ash_grass":
			_ash(ci)
		"marsh":
			_reeds(ci)
		_:
			_grass(ci)
	_litter(ci)
	_stones(ci)
	for lane: PackedVector2Array in lanes:
		_road_edges(ci, lane)
	_glows(ci)
	_wall(ci)


## ---- the palette ---------------------------------------------------------------------------------------------------

func _ramp(key: String, index: int, fallback: Color) -> Color:
	if style.has(key):
		var colors: Array = style[key]
		return colors[mini(index, colors.size() - 1)]
	return fallback


func _stone_color() -> Color:
	return STONE_WARM if String(style.get("stone", "STONE")) == "STONE_WARM" else STONE_COLD


func _tuft_tones() -> Array[Color]:
	return [_ramp("tuft", 0, Color("2c4a31")), _ramp("tuft", 1, Color("46703f")), _ramp("tuft", 2, Color("7aa05a"))]


## ---- the base ------------------------------------------------------------------------------------------------------

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
	var dark: Color = _ramp("base", 0, Color("16241b"))
	var mid: Color = _ramp("base", 2, Color("2a432f"))
	var light: Color = _ramp("base", 4, Color("43603d"))
	var earth: Color = _ramp("alt", 1, Color("3b3125"))
	var cold: Color = _ramp("alt2", 1, Color("1b3039"))
	var warm: Color = Color("4b4a2f")
	var snow: bool = kind == "snow"
	for y: int in size.y:
		for x: int in size.x:
			var world: Vector2 = floor_rect.position + Vector2(x, y) / BASE_SHARE
			var n: float = broad.get_noise_2d(x, y) * 0.5 + 0.5
			var c: Color = dark.lerp(mid, smoothstep(0.2, 0.55, n)).lerp(light, smoothstep(0.6, 0.85, n))
			c = c.lightened(fine.get_noise_2d(x, y) * (0.09 if snow else 0.06))
			var s: float = soil.get_noise_2d(x, y)
			if s > 0.35:
				c = c.lerp(earth, smoothstep(0.35, 0.6, s) * 0.7)
			var gate_d: float = 1e9
			for gate: Vector2 in gates:
				gate_d = minf(gate_d, world.distance_to(gate))
			c = c.lerp(cold, clampf(1.0 - gate_d / 420.0, 0.0, 1.0) * 0.55)
			c = c.lerp(warm, clampf(1.0 - world.distance_to(fortress) / 300.0, 0.0, 1.0) * 0.35)
			var edge: float = minf(minf(world.x - floor_rect.position.x, floor_rect.end.x - world.x), minf(world.y - floor_rect.position.y, floor_rect.end.y - world.y))
			c = c.darkened(clampf(1.0 - edge / 140.0, 0.0, 1.0) * 0.45)
			image.set_pixel(x, y, c)
	return ImageTexture.create_from_image(image)


func _patches(ci: CanvasItem) -> void:
	var colors: Array[Color] = [Color("4a6a3c"), Color("1f4250"), Color("5c5a34"), Color("2a5240")]
	if style.has("alt"):
		colors = [_ramp("alt", 2, Color.GRAY), _ramp("alt", 3, Color.GRAY), _ramp("alt2", 2, Color.GRAY), _ramp("patch", 2, _ramp("alt", 1, Color.GRAY))]
	for i: int in 40:
		var r: float = _rng.randf_range(60.0, 150.0)
		var at: Vector2 = _random_point()
		ci.draw_texture_rect(VectorStyle.glow_texture(colors[i % colors.size()]), Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1, 1, 1, _rng.randf_range(0.04, 0.1)))


## The marsh's pools: still water with a dark rim, a lit surface, reeds at the edge and a few ripples.
func _pools(ci: CanvasItem) -> void:
	var deep: Color = Color("12222a")
	var shallow: Color = Color("2b5560")
	for pool: PackedVector2Array in water:
		if pool.size() < 3 or Geometry2D.triangulate_polygon(pool).is_empty():
			continue
		var bounds: Rect2 = Rect2(pool[0], Vector2.ZERO)
		for p: Vector2 in pool:
			bounds = bounds.expand(p)
		ci.draw_colored_polygon(VectorPaint.moved(pool, Vector2(0, 2)), Color(0, 0, 0, 0.3))
		VectorPaint.fill(ci, pool, deep)
		var inner: PackedVector2Array = PackedVector2Array()
		var centre: Vector2 = bounds.get_center()
		for p: Vector2 in pool:
			inner.append(centre + (p - centre) * 0.8)
		VectorPaint.fill(ci, inner, shallow.darkened(0.2))
		VectorStyle.draw_glow(ci, Color("7fd8d0"), centre, maxf(bounds.size.x, bounds.size.y) * 0.5, 0.12)
		var closed: PackedVector2Array = pool.duplicate()
		closed.append(pool[0])
		ci.draw_polyline(closed, Color(0.35, 0.5, 0.42, 0.55), 2.0, true)
		for i: int in 5:
			var rp: Vector2 = centre + Vector2(_rng.randf_range(-bounds.size.x, bounds.size.x), _rng.randf_range(-bounds.size.y, bounds.size.y)) * 0.28
			ci.draw_arc(rp, _rng.randf_range(4.0, 11.0), 0.2, 2.6, 12, Color(0.8, 0.95, 0.95, 0.28), 1.0, true)


## ---- the details by kind ---------------------------------------------------------------------------------------------

func _ground_free(at: Vector2, road_gap: float = ROAD_CLEAR, pad_gap: float = 30.0) -> bool:
	return not (_near_road(at, road_gap) or _near_pad(at, pad_gap) or at.distance_to(fortress) < 95.0 or _in_water(at))


func _grass(ci: CanvasItem) -> void:
	var tones: Array[Color] = _tuft_tones()
	var dead_tone: Color = _ramp("tuft", 0, Color("8a7d4c")).lerp(Color("8a7d4c"), 0.6)
	for i: int in 2600:
		var at: Vector2 = _random_point()
		if not _ground_free(at):
			continue
		var dead: bool = _rng.randf() < (0.15 if style.is_empty() else 0.3)
		var blades: int = _rng.randi_range(3, 6)
		var height: float = _rng.randf_range(4.0, 8.5)
		for b: int in blades:
			var lean: float = _rng.randf_range(-3.5, 3.5)
			var base: Vector2 = at + Vector2(_rng.randf_range(-3.0, 3.0), _rng.randf_range(-1.0, 1.0))
			var tone: Color = dead_tone if dead else tones[mini(2, int((lean + 3.5) / 2.5))]
			VectorPaint.strand(ci, base, base + Vector2(lean * 0.3, -height * 0.6), base + Vector2(lean, -height), 1.6, Color(tone, 0.85))


## Reeds: tall clumps with brown heads, and flat lily pads on the open ground's wet patches.
func _reeds(ci: CanvasItem) -> void:
	var tones: Array[Color] = _tuft_tones()
	for i: int in 900:
		var at: Vector2 = _random_point()
		if not _ground_free(at):
			continue
		for b: int in _rng.randi_range(3, 6):
			var lean: float = _rng.randf_range(-2.5, 2.5)
			var base: Vector2 = at + Vector2(_rng.randf_range(-3.0, 3.0), _rng.randf_range(-1.0, 1.0))
			var h: float = _rng.randf_range(9.0, 18.0)
			VectorPaint.strand(ci, base, base + Vector2(lean * 0.4, -h * 0.6), base + Vector2(lean, -h), 1.7, Color(tones[b % 3], 0.9))
			if b == 0 and _rng.randf() < 0.5:
				VectorPaint.painted(ci, VectorStyle.ellipse(base + Vector2(lean, -h), 1.2, 3.0, 8), Color("6b4a2c"), 0.6, 0.3, 0.5)
	for i: int in 50:
		var at: Vector2 = _random_point()
		if _ground_free(at):
			VectorPaint.painted(ci, VectorStyle.ellipse(at, _rng.randf_range(3.0, 5.5), _rng.randf_range(1.8, 3.0), 10), Color("3f7a4a"), 0.8, 0.3, 0.6)


## Frosted tufts, drifts, hairline ice cracks and snow sparkles.
func _snow(ci: CanvasItem) -> void:
	var tones: Array[Color] = _tuft_tones()
	for i: int in 70:
		var at: Vector2 = _random_point()
		if not _ground_free(at, ROAD_CLEAR + 6.0):
			continue
		var r: float = _rng.randf_range(10.0, 26.0)
		ci.draw_colored_polygon(VectorStyle.ellipse(at + Vector2(1, 2), r, r * 0.4, 18), Color(0.12, 0.2, 0.34, 0.28))
		VectorPaint.painted(ci, VectorStyle.ellipse(at, r, r * 0.4, 18), Color("dce9f5"), r * 0.18, 0.35, 0.0)
	for i: int in 1500:
		var at: Vector2 = _random_point()
		if not _ground_free(at):
			continue
		for b: int in _rng.randi_range(2, 4):
			var lean: float = _rng.randf_range(-3.0, 3.0)
			var base: Vector2 = at + Vector2(_rng.randf_range(-2.5, 2.5), _rng.randf_range(-1.0, 1.0))
			VectorPaint.strand(ci, base, base + Vector2(lean * 0.3, -3.0), base + Vector2(lean, -6.0), 1.4, Color(tones[1 + b % 2], 0.85))
	for i: int in 26:
		var p: Vector2 = _random_point()
		if not _ground_free(p):
			continue
		var crack: PackedVector2Array = PackedVector2Array([p])
		for k: int in 5:
			crack.append(crack[k] + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(6.0, 14.0))
		ci.draw_polyline(crack, Color(0.7, 0.85, 1.0, 0.35), 1.0, true)


## Cinders, ash drifts, charred ground and scattered embers (the Ember Orchard also has windfallen, burnt apples).
func _ash(ci: CanvasItem) -> void:
	var tones: Array[Color] = _tuft_tones()
	if kind == "ash_grass":
		_grass(ci)
	for i: int in 60:
		var at: Vector2 = _random_point()
		if not _ground_free(at, ROAD_CLEAR + 4.0):
			continue
		var r: float = _rng.randf_range(8.0, 22.0)
		ci.draw_colored_polygon(VectorStyle.ellipse(at, r, r * 0.45, 16), Color(0.55, 0.53, 0.52, 0.16))
		ci.draw_colored_polygon(VectorStyle.ellipse(at + Vector2(-r * 0.2, -r * 0.1), r * 0.6, r * 0.25, 14), Color(0.8, 0.78, 0.75, 0.12))
	for i: int in 900:
		var at: Vector2 = _random_point()
		if not _ground_free(at):
			continue
		ci.draw_circle(at, _rng.randf_range(0.7, 1.7), Color(tones[i % 3], 0.8), true, -1.0, true)
	if kind == "ash_grass":
		for i: int in 36:
			var at: Vector2 = _random_point()
			if _ground_free(at):
				VectorPaint.painted(ci, VectorStyle.ellipse(at, 3.2, 2.8, 10), Color("3a1a14"), 1.0, 0.3, 0.7)
				ci.draw_circle(at + Vector2(0.6, -0.4), 0.8, Color("ff8a30"), true, -1.0, true)


## Gravel, pebbles, cracks and the odd flat slab (bones and ore glints come with the litter).
func _gravel(ci: CanvasItem) -> void:
	var stone: Color = _stone_color()
	for i: int in 1800:
		var at: Vector2 = _random_point()
		if not _ground_free(at):
			continue
		var r: float = _rng.randf_range(0.8, 2.4)
		var tone: Color = stone.darkened(_rng.randf_range(0.2, 0.6)).lerp(_ramp("tuft", 1, stone), 0.3)
		ci.draw_colored_polygon(VectorStyle.ellipse(at, r * 1.2, r * 0.9, 6), Color(tone, 0.85))
		if i % 5 == 0:
			ci.draw_colored_polygon(VectorStyle.ellipse(at + Vector2(-r * 0.3, -r * 0.3), r * 0.5, r * 0.4, 6), Color(1, 1, 1, 0.14))
	for i: int in 22:
		var p: Vector2 = _random_point()
		if not _ground_free(p):
			continue
		var crack: PackedVector2Array = PackedVector2Array([p])
		for k: int in 6:
			crack.append(crack[k] + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(5.0, 12.0))
		ci.draw_polyline(crack, Color(0, 0, 0, 0.4), 1.4, true)


## Ferns (arched fronds with leaflets), moss mats, and roots creeping over the ground.
func _moss(ci: CanvasItem) -> void:
	var tones: Array[Color] = _tuft_tones()
	for i: int in 150:
		var at: Vector2 = _random_point()
		if not _ground_free(at):
			continue
		var r: float = _rng.randf_range(10.0, 26.0)
		ci.draw_colored_polygon(VectorStyle.ellipse(at, r, r * 0.55, 16), Color(tones[0], 0.35))
		ci.draw_colored_polygon(VectorStyle.ellipse(at + Vector2(-r * 0.15, -r * 0.1), r * 0.7, r * 0.38, 14), Color(tones[1], 0.3))
	for i: int in 260:
		var at: Vector2 = _random_point()
		if not _ground_free(at):
			continue
		for f: int in _rng.randi_range(3, 5):
			var a: float = -PI * 0.5 + (f - 2.0) * 0.5 + _rng.randf_range(-0.15, 0.15)
			var tip: Vector2 = at + Vector2.from_angle(a) * _rng.randf_range(8.0, 13.0)
			var mid: Vector2 = at + Vector2.from_angle(a - 0.35) * 6.0
			VectorPaint.strand(ci, at, mid, tip, 1.8, Color(tones[1 + f % 2], 0.9))
			for k: int in 3:
				var q: Vector2 = at.lerp(tip, 0.3 + k * 0.22)
				ci.draw_line(q, q + Vector2.from_angle(a + 1.1) * 3.0, Color(tones[2], 0.7), 1.0, true)
				ci.draw_line(q, q + Vector2.from_angle(a - 1.1) * 3.0, Color(tones[2], 0.7), 1.0, true)
	for i: int in 16:
		var p: Vector2 = _random_point()
		if _ground_free(p):
			VectorPaint.strand(ci, p, p + Vector2.from_angle(_rng.randf() * TAU) * 14.0, p + Vector2.from_angle(_rng.randf() * TAU) * 30.0, 3.4, Color("3d2e22"))


## Flagstones: a grid of large tiles with joints, wear and the odd crack, drawn over the floor (the roads are worn aisles).
func _tiles(ci: CanvasItem) -> void:
	var tile: float = 56.0
	var stone: Color = _ramp("base", 1, Color("24242f"))
	var cols: int = int(floor_rect.size.x / tile) + 1
	var rows: int = int(floor_rect.size.y / tile) + 1
	for row: int in rows:
		for col: int in cols:
			var at: Vector2 = floor_rect.position + Vector2(col, row) * tile
			if _near_road(at + Vector2(tile, tile) * 0.5, ROAD_CLEAR - 4.0) or at.distance_to(fortress) < 100.0:
				continue
			var tone: Color = stone.darkened(0.12 + ((row * 7 + col * 13) % 5) * 0.04)
			var rect: PackedVector2Array = PackedVector2Array([at + Vector2(1.5, 1.5), at + Vector2(tile - 1.5, 1.5), at + Vector2(tile - 1.5, tile - 1.5), at + Vector2(1.5, tile - 1.5)])
			VectorPaint.painted(ci, rect, tone, 2.0, 0.0, 0.0)
			ci.draw_rect(Rect2(at, Vector2(tile, 1.4)), Color(0, 0, 0, 0.4))
			ci.draw_rect(Rect2(at, Vector2(1.4, tile)), Color(0, 0, 0, 0.4))
			if (row * 5 + col * 3) % 7 == 0:
				var crack: PackedVector2Array = PackedVector2Array([at + Vector2(10, 8)])
				for k: int in 4:
					crack.append(crack[k] + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(5.0, 10.0))
				ci.draw_polyline(crack, Color(0, 0, 0, 0.5), 1.3, true)


## ---- litter by map -----------------------------------------------------------------------------------------------------

func _litter(ci: CanvasItem) -> void:
	var colors: Array[Color] = [_ramp("speck", 0, Color("c9d9ff")), _ramp("speck", 1, Color("f0d98a")), _ramp("speck", 2, Color("ffcf6b"))]
	for i: int in 220:
		var at: Vector2 = _random_point()
		if not _ground_free(at):
			continue
		match litter:
			"embers":
				ci.draw_circle(at, 0.9, colors[1], true, -1.0, true)
				VectorStyle.draw_glow(ci, colors[0], at, 4.0, 0.5)
			"bones":
				var dir: Vector2 = Vector2.from_angle(_rng.randf() * TAU)
				ci.draw_line(at - dir * 2.6, at + dir * 2.6, Color(VectorStyle.INK, 0.8), 2.6, true)
				ci.draw_line(at - dir * 2.6, at + dir * 2.6, colors[_rng.randi_range(0, 1)], 1.6, true)
			"sparkles":
				VectorStyle.draw_glow(ci, colors[0], at, 2.8, 0.7)
				ci.draw_line(at + Vector2(-1.6, 0), at + Vector2(1.6, 0), Color(1, 1, 1, 0.8), 0.7, true)
				ci.draw_line(at + Vector2(0, -1.6), at + Vector2(0, 1.6), Color(1, 1, 1, 0.8), 0.7, true)
			"glints":
				var tone: Color = colors[i % 3]
				VectorPaint.fill(ci, PackedVector2Array([at + Vector2(0, -1.8), at + Vector2(1.2, 0), at + Vector2(0, 1.8), at + Vector2(-1.2, 0)]), tone)
				VectorStyle.draw_glow(ci, tone, at, 3.4, 0.4)
			"mushrooms":
				if i % 4 == 0:
					ci.draw_circle(at, 1.4, Color(colors[0], 0.9), true, -1.0, true)
					VectorStyle.draw_glow(ci, colors[1], at, 6.0, 0.45)
			"candle":
				ci.draw_circle(at, 0.7, Color(colors[1], 0.7), true, -1.0, true)
			"ripples":
				if i % 3 == 0:
					ci.draw_arc(at, _rng.randf_range(2.0, 5.0), 0.3, 2.4, 10, Color(colors[0], 0.35), 0.9, true)
			_:
				_flower_or_leaf(ci, at)


func _flower_or_leaf(ci: CanvasItem, at: Vector2) -> void:
	var near_gate: bool = false
	for gate: Vector2 in gates:
		near_gate = near_gate or at.distance_to(gate) < 380.0
	if _rng.randf() < 0.45:
		var petal: Color = Color("c9d9ff") if near_gate else Color("f0d98a")
		for k: int in 5:
			var a: float = TAU * k / 5.0
			ci.draw_circle(at + Vector2(cos(a), sin(a)) * 1.1, 0.9, Color(petal, 0.9), true, -1.0, true)
		ci.draw_circle(at, 0.6, Color("ffcf6b"), true, -1.0, true)
	else:
		var dir: Vector2 = Vector2.from_angle(_rng.randf() * TAU)
		VectorPaint.fill(ci, PackedVector2Array([at - dir * 2.5, at + dir.orthogonal() * 1.2, at + dir * 2.5, at - dir.orthogonal() * 1.2]), Color("7a4a26").lerp(Color("a8743a"), _rng.randf()))


func _stones(ci: CanvasItem) -> void:
	var stone: Color = _stone_color()
	for i: int in 90:
		var at: Vector2 = _random_point()
		if _near_road(at, ROAD_CLEAR + 4.0) or _near_pad(at, 34.0) or _in_water(at):
			continue
		var r: float = _rng.randf_range(2.5, 7.0)
		ci.draw_colored_polygon(VectorStyle.ellipse(at + Vector2(1.2, r * 0.55), r * 1.15, r * 0.5, 14), Color(0, 0, 0, 0.35))
		VectorPaint.painted(ci, VectorStyle.ellipse(at, r, r * 0.72, 14), stone, r * 0.45, 0.35, 0.8)
		if _rng.randf() < 0.4 and kind != "snow":
			ci.draw_colored_polygon(VectorStyle.ellipse(at + Vector2(-r * 0.3, r * 0.2), r * 0.5, r * 0.25, 10), Color(_ramp("tuft", 1, Color("4f6b3a")), 0.8))
		elif kind == "snow":
			ci.draw_colored_polygon(VectorStyle.ellipse(at + Vector2(-r * 0.2, -r * 0.35), r * 0.7, r * 0.28, 10), Color(0.92, 0.96, 1.0, 0.85))


## ---- roads -------------------------------------------------------------------------------------------------------------

func _stroke(ci: CanvasItem, lane: PackedVector2Array, width: float, color: Color, offset: Vector2 = Vector2.ZERO) -> void:
	var moved: PackedVector2Array = VectorPaint.moved(lane, offset)
	ci.draw_polyline(moved, color, width, true)
	for i: int in range(0, moved.size(), 3):
		ci.draw_circle(moved[i], width * 0.5, color, true, -1.0, true)


func _road(ci: CanvasItem, lane: PackedVector2Array) -> void:
	var shift: int = int(style.get("path_shift", 0))
	_stroke(ci, lane, 68.0, Color(0, 0, 0, 0.35), Vector2(0, 5))
	_stroke(ci, lane, 62.0, _ramp("path", maxi(0 - shift, 0), Color("2a1f17")).lightened(0.05))
	_stroke(ci, lane, 54.0, _ramp("path", 2 - shift, Color("57422f")))
	_stroke(ci, lane, 44.0, _ramp("path", 3 - shift, Color("66503b")))
	_stroke(ci, lane, 26.0, Color(1, 0.95, 0.85, 0.04))


func _road_detail(ci: CanvasItem, lane: PackedVector2Array) -> void:
	var light_grit: Color = _ramp("path", 4, Color("8d765c"))
	var dark_grit: Color = _ramp("path", 0, Color("3b2c20"))
	for i: int in range(0, lane.size() - 1, 1):
		var dir: Vector2 = (lane[i + 1] - lane[i]).normalized()
		var side: Vector2 = dir.orthogonal()
		for k: int in 2:
			var at: Vector2 = lane[i] + side * _rng.randf_range(-24.0, 24.0)
			var lit: bool = _rng.randf() > 0.55
			ci.draw_colored_polygon(VectorStyle.ellipse(at, _rng.randf_range(0.6, 1.6), _rng.randf_range(0.5, 1.1), 6), light_grit if lit else dark_grit)
		if i % 5 == 0:
			var off: float = _rng.randf_range(-22.0, 22.0)
			if absf(off) > 8.0:
				var at: Vector2 = lane[i] + side * off
				var r: float = _rng.randf_range(2.5, 4.5)
				VectorPaint.painted(ci, VectorStyle.ellipse(at, r, r * 0.7, 12), _stone_color().darkened(0.1), 1.2, 0.25, 0.7)
		if i % 90 == 45 and kind != "snow":
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
	if kind == "stone" or kind == "tile":
		return
	var tone: Color = _ramp("tuft", 1, Color("4f7a43"))
	for i: int in range(0, lane.size() - 1, 3):
		var normal: Vector2 = (lane[i + 1] - lane[i]).normalized().orthogonal()
		for side_sign: float in [-1.0, 1.0]:
			var at: Vector2 = lane[i] + normal * side_sign * _rng.randf_range(27.0, 32.0)
			if at.distance_to(fortress) < 95.0 or _in_water(at):
				continue
			var lean: Vector2 = -normal * side_sign * _rng.randf_range(2.0, 5.0) + Vector2(0, -_rng.randf_range(3.0, 6.0))
			VectorPaint.strand(ci, at, at + lean * 0.5, at + lean, 1.6, Color(tone, 0.9))


func _plaza(ci: CanvasItem) -> void:
	var stone: Color = _stone_color().darkened(0.12)
	ci.draw_colored_polygon(VectorStyle.regular(fortress + Vector2(0, 8), 10, 94, 52, 0.0), Color(0, 0, 0, 0.35))
	VectorPaint.painted(ci, VectorStyle.regular(fortress, 10, 90, 47, 0.0), stone, 5.0, 0.3, 1.2)
	for ring: int in 3:
		var r0: float = 0.35 + ring * 0.22
		var r1: float = r0 + 0.22
		for k: int in 14:
			var a0: float = TAU * k / 14.0 + ring * 0.2
			var a1: float = a0 + TAU / 14.0
			var flag: PackedVector2Array = PackedVector2Array([fortress + Vector2(cos(a0) * 90 * r0, sin(a0) * 47 * r0), fortress + Vector2(cos(a1) * 90 * r0, sin(a1) * 47 * r0),
				fortress + Vector2(cos(a1) * 90 * r1, sin(a1) * 47 * r1), fortress + Vector2(cos(a0) * 90 * r1, sin(a0) * 47 * r1)])
			VectorPaint.painted(ci, flag, stone.lightened(0.05).darkened(((k * 7 + ring * 3) % 5) * 0.05), 1.2, 0.2, 0.7)


## Dug earth where a road leaves a gate: a dark ring of turned soil with a few bones.
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
	var glow: Color = _ramp("speck", 1, VectorStyle.COLD_GLOW) if not style.is_empty() else VectorStyle.COLD_GLOW
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED + 1
	for gate: Vector2 in gates:
		for i: int in 8:
			var at: Vector2 = gate + Vector2(rng.randf_range(-150.0, 150.0), rng.randf_range(-100.0, 120.0))
			VectorStyle.draw_glow(ci, glow, at, rng.randf_range(8.0, 18.0), 0.3)
			if i % 3 == 0 and style.is_empty():
				for k: int in 3:
					ci.draw_circle(at + Vector2(k * 3.0 - 3.0, (k % 2) * 1.5), 1.3, Color(0.55, 0.95, 1.0, 0.8), true, -1.0, true)
		VectorStyle.draw_glow(ci, glow, gate + Vector2(0, -10), 130.0, 0.1)


## ---- the wall band -----------------------------------------------------------------------------------------------------

func _wall_tones() -> Array[Color]:
	if style.is_empty():
		return [Color("565b66"), Color("4b505b"), Color("60666f"), Color("525760"), Color("444955")]
	var stone: Color = _stone_color().darkened(0.3)
	var tint: Color = style.get("wall_tint", Color("23212b"))
	return [stone.lerp(tint, 0.15), stone.lerp(tint, 0.3), stone, stone.lerp(tint, 0.22), stone.lerp(tint, 0.4)]


## Four strips of dressed stone around the floor, lit along the cap, shadowing the floor.
func _wall(ci: CanvasItem) -> void:
	var outer: Rect2 = floor_rect.grow(band)
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
		ci.draw_rect(strip, Color("23212b").lerp(style.get("wall_tint", Color("23212b")), 0.8))
	var tones: Array[Color] = _wall_tones()
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
				var tone: Color = tones[(row * 3 + col * 5 + si) % tones.size()]
				var rect: Rect2
				if horizontal:
					rect = Rect2(strip.position + Vector2(a0, row * brick_h + 0.6), Vector2(a1 - a0, brick_h - 1.2))
				else:
					rect = Rect2(strip.position + Vector2(row * brick_h + 0.6, a0), Vector2(brick_h - 1.2, a1 - a0))
				VectorPaint.painted(ci, PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]), tone, 1.4, 0.3, 0.6)
	ci.draw_rect(Rect2(floor_rect.position + Vector2(0, -2), Vector2(floor_rect.size.x, 2)), Color(1, 1, 1, 0.18))
	ci.draw_rect(Rect2(Vector2(floor_rect.position.x, floor_rect.end.y), Vector2(floor_rect.size.x, 2)), Color(1, 1, 1, 0.12))
	ci.draw_rect(Rect2(floor_rect.position + Vector2(-2, 0), Vector2(2, floor_rect.size.y)), Color(1, 1, 1, 0.12))


## ---- helpers -------------------------------------------------------------------------------------------------------------

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


func _in_water(at: Vector2) -> bool:
	for pool: PackedVector2Array in water:
		if Geometry2D.is_point_in_polygon(at, pool):
			return true
	return false
