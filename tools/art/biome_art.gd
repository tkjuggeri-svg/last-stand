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
	"ember_orchard": {
		"base": [Color("181c0f"), Color("212612"), Color("2a301b"), Color("353c22"), Color("424a29"), Color("525c31")],
		"alt": [Color("2a2a14"), Color("3a3a1c"), Color("4e4b24"), Color("665f2c")],
		"alt2": [Color("21200f"), Color("2d2b14"), Color("3a371b")],
		"path": [Color("1c140e"), Color("2c2016"), Color("3d2e20"), Color("523f2b"), Color("6b5238"), Color("84684a")],
		"tuft": [Color("3a4222"), Color("5e6a34"), Color("8a8c4a")],
		"speck": [Color("a8431c"), Color("e88a3a"), Color("f0c870")],
		"wall_tint": Color("2a2012"),
		"stone": "STONE_WARM",
		"patch": [Color("4a3f1c"), Color("63551f"), Color("7e6c2a"), Color("9b883a")],
	},
	"frostbound_pass": {
		"base": [Color("121a26"), Color("182330"), Color("202d40"), Color("293c54"), Color("334a68"), Color("3f5a7c")],
		"alt": [Color("1c2838"), Color("263648"), Color("32465e"), Color("405a78")],
		"alt2": [Color("141c2a"), Color("1c2838"), Color("263648")],
		"path": [Color("2a2420"), Color("3c342e"), Color("52483f"), Color("6c6054"), Color("887a6a"), Color("a4947f")],
		"tuft": [Color("586c82"), Color("8aa0b6"), Color("c4d6e6")],
		"speck": [Color("dff6ff"), Color("b6e4ff"), Color("8fd0f0")],
		"wall_tint": Color("1a2230"),
		"stone": "STONE",
	},
	"sunless_mines": {
		"base": [Color("17151c"), Color("201e27"), Color("2a2833"), Color("36333f"), Color("45414f"), Color("57535f")],
		"alt": [Color("1e1a1a"), Color("2b2423"), Color("3a302d"), Color("4c3e39")],
		"alt2": [Color("14161c"), Color("1e222a"), Color("2a2f3a")],
		"path": [Color("1a1820"), Color("2a2730"), Color("3e3a47"), Color("57525f"), Color("756f81"), Color("968fa3")],
		"tuft": [Color("2c2a34"), Color("46424f"), Color("625d6e")],
		"speck": [Color("57e0c8"), Color("b58cff"), Color("e8c060")],
		"wall_tint": Color("100e14"),
		"stone": "STONE",
	},
	"bone_quarry": {
		"base": [Color("1e1c1a"), Color("282522"), Color("33302b"), Color("403b35"), Color("524c43"), Color("675f53")],
		"alt": [Color("2a2420"), Color("3a322b"), Color("4c4137"), Color("62564a")],
		"alt2": [Color("1a1c20"), Color("24272d"), Color("303439")],
		"path": [Color("1c1814"), Color("2e2720"), Color("43392e"), Color("5c4f40"), Color("786a57"), Color("958471")],
		"tuft": [Color("3a362f"), Color("5e564a"), Color("8a8070")],
		"speck": [Color("c3b99c"), Color("ece4cb"), Color("8f8670")],
		"wall_tint": Color("221c16"),
		"stone": "STONE_WARM",
	},
	"gloam_wood": {
		"base": [Color("0e1612"), Color("141f19"), Color("1b2a22"), Color("233830"), Color("2c473b"), Color("385a4a")],
		"alt": [Color("16241a"), Color("1f3324"), Color("2a4631"), Color("375c40")],
		"alt2": [Color("0c1418"), Color("131f25"), Color("1b2b33")],
		"path": [Color("1a1410"), Color("2a2118"), Color("3c3022"), Color("52432f"), Color("6c5a40"), Color("88735a")],
		"tuft": [Color("1f3a28"), Color("2f5a3c"), Color("4a8a58")],
		"speck": [Color("a8f0c8"), Color("57b892"), Color("c8f57a")],
		"wall_tint": Color("0c1410"),
		"stone": "STONE",
	},
	"pale_cathedral": {
		"base": [Color("1b1b24"), Color("24242f"), Color("2f2f3c"), Color("3b3b4a"), Color("494959"), Color("5a5a6c")],
		"alt": [Color("2a2a38"), Color("383848"), Color("484860"), Color("5c5c78")],
		"alt2": [Color("17171f"), Color("20202a"), Color("2b2b38")],
		"path": [Color("221f26"), Color("322e38"), Color("46414f"), Color("5f5a69"), Color("7c7688"), Color("9a94a8")],
		"tuft": [Color("3a3a4a"), Color("5a5a72"), Color("84849e")],
		"speck": [Color("e4d4ff"), Color("b58cff"), Color("efd07a")],
		"wall_tint": Color("15131c"),
		"stone": "STONE",
	},
}

var style: Dictionary = {}


## Bakes the floor and the wall band of biome `biome` (see EnvironmentArt.ground for the arguments).
func bake(biome: String, floor_rect: Rect2, lanes_world: Array[Array], keep_world: Vector2, band: int, scale: float, fine_px: int = 1,
		patches_world: PackedVector2Array = PackedVector2Array(), patch_radius: float = 56.0) -> Image:
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
	var patches_art: Array[Vector2] = []
	for patch: Vector2 in patches_world:
		patches_art.append((patch - origin) / scale)
	var patch_art_radius: float = patch_radius / scale
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
				for patch: Vector2 in patches_art:
					var edge: float = p.distance_to(patch) - patch_art_radius + fine * 3.0
					if edge < 0.0:
						color = Canvas.shade(style["patch"], value, x, y, true)
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
