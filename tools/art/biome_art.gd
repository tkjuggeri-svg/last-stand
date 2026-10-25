extends "res://tools/art/environment_art.gd"
## The new biomes' grounds and props (dev-time art generator, M10). One baking routine for every biome,
## driven by a STYLE (the colours of the floor, the trodden lanes, the scattered details and the wall
## band's tint) and one prop library drawn in each biome's palette. The ground is baked from the level
## itself (floor rect, lane Path2Ds, fortress), so regenerate it after changing those
## (tools/make_level.py writes the level from tools/levels/<id>.json).
##   godot --headless --path . --script res://tools/art/generate_art.gd -- --only=<id>_ground,<id>_props,<id>_gate

const STYLES: Dictionary = {
	"ashen_keep": {
		"base": [Color("1d1a1c"), Color("26221f"), Color("302b28"), Color("3b3531"), Color("4a423c"), Color("5b5249")],
		"alt": [Color("231615"), Color("31201c"), Color("422b24"), Color("57382c")],
		"alt2": [Color("1a1a1e"), Color("26262c"), Color("33333b")],
		"path": [Color("120f10"), Color("231d1c"), Color("322a28"), Color("453b37"), Color("5a4d47"), Color("6f625a")],
		"tuft": [Color("3a342f"), Color("5e5148"), Color("7a6a5c")],
		"speck": [Color("8a3a22"), Color("c2652a"), Color("e8a24a")],
		"wall_tint": Color("2a1a14"),
		"stone": "STONE_WARM",
	},
}

var style: Dictionary = {}


## Bakes the floor and the wall band of biome `biome` (see EnvironmentArt.ground for the arguments).
func bake(biome: String, floor_rect: Rect2, lanes_world: Array[Array], keep_world: Vector2, band: int, scale: float, fine_px: int = 1) -> Image:
	style = STYLES[biome]
	detail = fine_px
	var origin: Vector2 = floor_rect.position - Vector2(band, band)
	var size: Vector2i = Vector2i(((floor_rect.size + Vector2(band, band) * 2.0) / scale).round())
	var floor_art: Rect2i = Rect2i(Vector2i(int(band / scale), int(band / scale)), Vector2i((floor_rect.size / scale).round()))
	var lanes: Array[Array] = []
	for lane_world: Array in lanes_world:
		var lane: Array[Vector2] = []
		for p: Vector2 in lane_world:
			lane.append((p - origin) / scale)
		lanes.append(lane)
	var keep: Vector2 = (keep_world - origin) / scale
	var img: Image = Image.create_empty(size.x * detail, size.y * detail, false, Image.FORMAT_RGBA8)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2468
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = 13
	noise.frequency = 0.09
	var patches: FastNoiseLite = FastNoiseLite.new()
	patches.seed = 23
	patches.frequency = 0.018
	var second: FastNoiseLite = FastNoiseLite.new()
	second.seed = 37
	second.frequency = 0.03
	for y: int in size.y * detail:
		for x: int in size.x * detail:
			var p: Vector2 = Vector2(x + 0.5, y + 0.5) / detail
			var at: Vector2 = Vector2(x, y) / detail
			var n: float = noise.get_noise_2d(at.x, at.y)
			var fine: float = noise.get_noise_2d(at.x * 3.1, at.y * 3.1)
			var lane_d: float = INF
			var apron_d: float = INF
			var nearest: Array = lanes[0]
			for lane: Array in lanes:
				var d: float = _distance_to_polyline(p, lane)
				if d < lane_d:
					lane_d = d
					nearest = lane
				var spawn: Vector2 = lane[0]
				apron_d = minf(apron_d, p.distance_to(Geometry2D.get_closest_point_to_segment(p, spawn + Vector2(-35, -5), spawn)) - 9.0 + fine * 2.5)
			lane_d += fine * 1.4
			var clearing_d: float = p.distance_to(keep) - 36.0 + fine * 2.5
			var path_d: float = minf(minf(lane_d - 8.5, clearing_d), apron_d)
			var color: Color
			if path_d < -0.5:
				color = _path_color(p, Vector2i(x, y), n, lane_d, nearest, keep, rng)
			elif path_d < 1.2:
				color = (style["path"] as Array)[1] if (x + y) % 3 != 0 else (style["base"] as Array)[1]
			else:
				var a: float = patches.get_noise_2d(at.x, at.y)
				var b: float = second.get_noise_2d(at.x, at.y)
				var value: float = 0.45 + n * 0.45 + fine * 0.12
				if a > 0.3:
					color = Canvas.shade(style["alt"], value, x, y, true)
				elif b > 0.35:
					color = Canvas.shade(style["alt2"], value * 0.9, x, y, true)
				else:
					color = Canvas.shade(style["base"], value, x, y, true)
				if path_d < 3.0:
					color = color.lerp(Color(0.05, 0.04, 0.05), 0.3)
			img.set_pixel(x, y, color)
	var keep_out: Callable = func(p: Vector2) -> bool:
		return (lanes.any(func(lane: Array) -> bool: return _distance_to_polyline(p, lane) < 12.0) or p.distance_to(keep) < 42.0
			or not Rect2(floor_art).grow(-3).has_point(p))
	_scatter(img, keep_out, rng)
	wall_band(img, floor_art, detail)
	_tint_band(img, floor_art)
	return img


## Worn lane dirt in the style's path ramp, ruts, pebbles and the gate's cobbles.
func _path_color(p: Vector2, px: Vector2i, n: float, lane_d: float, lane: Array, keep: Vector2, rng: RandomNumberGenerator) -> Color:
	var value: float = 0.5 + n * 0.35
	if lane_d > 2.0 and lane_d < 3.6:
		value -= 0.25
	var ramp: Array = style["path"]
	var color: Color = Canvas.shade(ramp.slice(1, 6), value, px.x, px.y, true)
	var gate: Vector2 = lane[lane.size() - 1]
	if p.distance_to(gate + (gate - keep).normalized() * 6.0) < 13.0 and p.distance_to(keep) > 26.0:
		var cell: Vector2i = Vector2i(floori(p.x / 3.0 + (floori(p.y / 3.0) % 2) * 0.5), floori(p.y / 3.0))
		var in_x: float = fposmod(p.x / 3.0 + (cell.y % 2) * 0.5, 1.0)
		var in_y: float = fposmod(p.y / 3.0, 1.0)
		if in_x < 0.28 or in_y < 0.3:
			return ramp[0]
		var stone: Array = P.STONE_WARM if style["stone"] == "STONE_WARM" else P.STONE
		return stone[3] if (cell.x * 7 + cell.y * 3) % 4 != 0 else stone[2]
	if rng.randf() < 0.014 / detail:
		return ramp[5]
	if rng.randf() < 0.01 / detail:
		return ramp[0]
	return color


## Weeds, specks (embers, frost, ...) and stones scattered over the floor.
func _scatter(img: Image, keep_out: Callable, rng: RandomNumberGenerator) -> void:
	var size: Vector2i = Vector2i(Vector2(img.get_size()) / detail)
	var tuft: Array = style["tuft"]
	for i: int in 1500 * detail:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if keep_out.call(p):
			continue
		var tip: Vector2i = Vector2i(p * detail)
		_plot(img, tip + Vector2i(0, 1), (style["base"] as Array)[0])
		_plot(img, tip, tuft[0])
		_plot(img, tip + Vector2i(1, -1), tuft[1] if i % 2 == 0 else tuft[2])
	var speck: Array = style["speck"]
	for i: int in 160 * detail:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if not keep_out.call(p):
			_plot(img, Vector2i(p * detail), speck[i % speck.size()])
	for i: int in 70:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if not keep_out.call(p):
			_pebble(img, Vector2i(p * detail), rng.randi_range(1, 2) * detail)


func _tint_band(img: Image, floor_art_px: Rect2i) -> void:
	var floor_art: Rect2i = Rect2i(floor_art_px.position * detail, floor_art_px.size * detail)
	var tint: Color = style["wall_tint"]
	for y: int in img.get_height():
		for x: int in img.get_width():
			if not floor_art.has_point(Vector2i(x, y)):
				img.set_pixel(x, y, img.get_pixel(x, y).lerp(tint, 0.3))
