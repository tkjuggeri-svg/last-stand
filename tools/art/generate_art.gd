extends SceneTree
## Draws all LAST STAND pixel art (original, made entirely in code) and saves it as PNG sheets.
## Characters are hand-written pixel grids (one character = one palette colour) composed per frame;
## effects, the fortress and the arena ground are drawn procedurally with fixed seeds.
##
## Regenerate everything (from the project folder):
##   godot --headless --path . --script res://tools/art/generate_art.gd
##   godot --headless --path . --import
##   godot --headless --path . --script res://tools/art/build_sprite_frames.gd

const Layouts: GDScript = preload("res://tools/art/sheet_layouts.gd")
const HeroArt: GDScript = preload("res://tools/art/hero_art.gd")
const GhoulArt: GDScript = preload("res://tools/art/ghoul_art.gd")
const EffectsArt: GDScript = preload("res://tools/art/effects_art.gd")
const FortressArt: GDScript = preload("res://tools/art/fortress_art.gd")

const DIRS_4: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

const COIN: Array[String] = [
	"..yyyy..",
	".yYYYYy.",
	"yYYyyYYy",
	"yYyYYyYy",
	"yYyYYyYy",
	"yYYyyYYy",
	".yYYYYy.",
	"..yyyy..",
]

var _palette: Dictionary = {
	"o": Color("1a141f"),  # outline / deepest shadow
	"S": Color("d3d7df"),  # steel highlight
	"s": Color("8f96a6"),  # steel
	"d": Color("565c6c"),  # steel shadow
	"R": Color("9b3131"),  # red tabard and plume (the accent colour)
	"r": Color("5f1e23"),  # red shadow
	"k": Color("d2a283"),  # skin
	"b": Color("6f4d34"),  # leather
	"B": Color("45301f"),  # dark leather / boots
	"y": Color("c9a24f"),  # gold trim
	"Y": Color("f0d27a"),  # bright gold (coins, highlights)
	"G": Color("a5b090"),  # ghoul skin
	"g": Color("6d7a61"),  # ghoul skin shadow
	"q": Color("434c3d"),  # ghoul deep shadow
	"E": Color("e2462f"),  # ghoul eyes
	"m": Color("2b1b1d"),  # ghoul mouth
	"C": Color("51473b"),  # rags
	"c": Color("342c26"),  # rags shadow
	"n": Color("d9d1ba"),  # bone and claws
	"h": Color("3f5a3a"),  # archer's hood
	"H": Color("2b3f28"),  # hood shadow
	"z": Color("34343e"),  # iron
	"Z": Color("5c5f6c"),  # iron highlight
	"i": Color("8fcdf2"),  # ice
	"I": Color("e4f6ff"),  # ice highlight
	"j": Color("3f7fb6"),  # deep ice
}
var _outline_color: Color = Color("1a141f")
var _shadow_color: Color = Color(0.0, 0.0, 0.0, 0.32)


func _initialize() -> void:
	# --only=hero,ghoul regenerates just those sheets (faster while iterating on one asset).
	var only: PackedStringArray = PackedStringArray()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.trim_prefix("--only=").split(",")
	var jobs: Dictionary = {
		"hero": func() -> void: _save(_sheet(HeroArt.new().sheet_rows(), Layouts.HERO["size"]), Layouts.HERO["png"]),
		"swing": func() -> void: _save(_sheet(EffectsArt.new().swing_rows(), Layouts.SWING["size"]), Layouts.SWING["png"]),
		"ghoul": func() -> void: _save(_sheet(GhoulArt.new().sheet_rows(), Layouts.GHOUL["size"]), Layouts.GHOUL["png"]),
		"spark": func() -> void: _save(_sheet([EffectsArt.new().spark_frames()], Layouts.HIT_SPARK["size"]), Layouts.HIT_SPARK["png"]),
		"dust": func() -> void: _save(_sheet([EffectsArt.new().dust_frames()], Layouts.DUST["size"]), Layouts.DUST["png"]),
		"fortress": func() -> void: _save(_sheet([FortressArt.new().sheet_frames()], Layouts.FORTRESS["size"]), Layouts.FORTRESS["png"]),
		"fortress_fx": func() -> void: _save(_sheet(FortressArt.new().fx_rows(), Layouts.FORTRESS_FX["size"]), Layouts.FORTRESS_FX["png"]),
		"smoke": func() -> void: _save(FortressArt.new().smoke_puff(), Layouts.SMOKE_PNG),
		"ground": func() -> void: _save(_ground(), Layouts.GROUND_PNG),
		"coin": func() -> void: _save(_grid_image(COIN, true), Layouts.COIN_PNG),
		"towers": func() -> void: _save(_towers_sheet(), Layouts.TOWERS["png"]),
		"projectiles": func() -> void: _save(_projectiles_sheet(), Layouts.PROJECTILES["png"]),
		"explosion": func() -> void: _save(_explosion_sheet(), Layouts.EXPLOSION["png"]),
		"frost": func() -> void: _save(_frost_sheet(), Layouts.FROST_FX["png"]),
		"slot": func() -> void: _save(_build_slot_sheet(), Layouts.BUILD_SLOT["png"]),
	}
	for job_name: String in jobs:
		if only.is_empty() or only.has(job_name):
			(jobs[job_name] as Callable).call()
	quit()


# ---------------------------------------------------------------- towers and their effects

func _towers_sheet() -> Image:
	var rows: Array[Array] = []
	for kind: String in ["archer", "cannon", "frost"]:
		rows.append([_tower_frame(kind, "idle", 0), _tower_frame(kind, "idle", 1)])
		rows.append([_tower_frame(kind, "fire", 0), _tower_frame(kind, "fire", 1), _tower_frame(kind, "idle", 0)])
	return _sheet(rows, Layouts.TOWERS["size"])


## state "idle" (frame 0/1: a small bob) or "fire" (frame 0: wind-up/flash, 1: release/smoke).
func _tower_frame(kind: String, state: String, frame: int) -> Image:
	var img: Image = _blank(Layouts.TOWERS["size"])
	var stone: Color = Color("76727e")
	var stone_light: Color = Color("9a96a0")
	var stone_dark: Color = Color("55515d")
	var mortar: Color = Color("3e3a46")
	var firing: bool = state == "fire"
	var bob: int = frame if state == "idle" else 0
	match kind:
		"archer":
			# Stone footing, plank shaft with a cross brace, deck with railing posts, hooded archer with a bow.
			_fill_rect(img, Rect2i(4, 24, 16, 6), stone)
			_fill_rect(img, Rect2i(4, 24, 16, 1), stone_light)
			for x: int in range(6, 20, 5):
				_px(img, Vector2i(x, 27), mortar)
			_fill_rect(img, Rect2i(6, 13, 12, 11), _palette["b"])
			for x: int in range(6, 18, 3):
				_fill_rect(img, Rect2i(x, 13, 1, 11), _palette["B"])
			for i: int in 10:
				_px(img, Vector2i(7 + i, 14 + i), _palette["B"])
			_fill_rect(img, Rect2i(3, 10, 18, 3), _palette["b"])
			_fill_rect(img, Rect2i(3, 12, 18, 1), _palette["B"])
			for x: int in [3, 20]:
				_fill_rect(img, Rect2i(x, 6, 1, 4), _palette["B"])
			_fill_rect(img, Rect2i(3, 6, 4, 1), _palette["b"])
			_fill_rect(img, Rect2i(17, 6, 4, 1), _palette["b"])
			var a: Vector2i = Vector2i(9, 2 + bob)
			_fill_rect(img, Rect2i(a + Vector2i(0, 1), Vector2i(5, 7)), _palette["h"])
			_fill_rect(img, Rect2i(a + Vector2i(1, 0), Vector2i(3, 1)), _palette["h"])
			_fill_rect(img, Rect2i(a + Vector2i(1, 2), Vector2i(3, 2)), _palette["k"])
			_fill_rect(img, Rect2i(a + Vector2i(0, 5), Vector2i(1, 3)), _palette["H"])
			_px(img, a + Vector2i(1, 3), _palette["H"])
			_px(img, a + Vector2i(3, 3), _palette["H"])
			# The bow: curved when drawn (fire 0, with the arrow nocked), straight-ish otherwise.
			var bow_x: int = 15 if firing and frame == 0 else 14
			for y: int in range(1, 9):
				var curve: int = 1 if y in [1, 8] else 0
				_px(img, Vector2i(bow_x - curve, a.y + y - 1), _palette["y"])
			if firing and frame == 0:
				for x: int in range(10, 18):
					_px(img, Vector2i(x, a.y + 3), _palette["S"])
				_px(img, Vector2i(18, a.y + 3), _palette["s"])
		"cannon":
			# A squat round stone tower with merlons and an iron cannon on top.
			for y: int in range(14, 30):
				for x: int in range(3, 21):
					var brick: bool = (y % 3 == 0) or ((x + (floori(y / 3.0) % 2) * 3) % 6 == 0)
					_px(img, Vector2i(x, y), mortar if brick else stone)
			_fill_rect(img, Rect2i(3, 14, 1, 16), stone_light)
			_fill_rect(img, Rect2i(20, 14, 1, 16), stone_dark)
			# Round the body: trim the corners so it reads as a drum tower, not a box.
			for corner: Vector2i in [Vector2i(3, 28), Vector2i(3, 29), Vector2i(4, 29), Vector2i(20, 28), Vector2i(20, 29), Vector2i(19, 29)]:
				_px(img, corner, Color(0, 0, 0, 0))
			_fill_rect(img, Rect2i(2, 10, 20, 5), stone)
			for corner: Vector2i in [Vector2i(2, 10), Vector2i(21, 10), Vector2i(2, 14), Vector2i(21, 14)]:
				_px(img, corner, Color(0, 0, 0, 0))
			for x: int in range(2, 22):
				_px(img, Vector2i(x, 10), stone_light if floori(x / 3.0) % 2 == 0 else mortar)
			_fill_rect(img, Rect2i(5, 11, 14, 3), Color("2e2a36"))
			var recoil: int = 1 if firing and frame == 0 else 0
			var tip: Vector2i = Vector2i(18 - recoil, 4 + recoil)
			for i: int in 7:
				var p: Vector2i = Vector2i(11 + i - recoil, 11 - i + recoil)
				_px(img, p, _palette["z"])
				_px(img, p + Vector2i(1, 0), _palette["z"])
				_px(img, p + Vector2i(0, 1), _palette["Z"])
			_fill_rect(img, Rect2i(8, 11, 5, 3), _palette["b"])
			_px(img, Vector2i(9, 12), _palette["B"])
			if firing and frame == 0:
				_fill_circle(img, tip + Vector2i(1, -1), 2.6, Color("e0782e"))
				_fill_circle(img, tip + Vector2i(1, -1), 1.4, Color("f2c65c"))
			elif firing and frame == 1:
				for p: Vector2i in [tip + Vector2i(1, -2), tip + Vector2i(3, -3), tip + Vector2i(2, -4), tip + Vector2i(0, -3)]:
					_fill_circle(img, p, 1.2, Color("8a8378"))
		"frost":
			# A dark tapering pillar with a floating ice crystal that brightens when it fires.
			_fill_rect(img, Rect2i(5, 25, 14, 5), stone_dark)
			_fill_rect(img, Rect2i(5, 25, 14, 1), stone)
			_fill_rect(img, Rect2i(7, 14, 10, 11), Color("4a4656"))
			_fill_rect(img, Rect2i(7, 14, 2, 11), Color("5c586a"))
			_fill_rect(img, Rect2i(6, 13, 12, 2), stone)
			for y: int in range(16, 24, 3):
				_px(img, Vector2i(12, y), _palette["j"])  # glowing runes
			var c: Vector2i = Vector2i(12, 7 - bob)
			var bright: bool = firing and frame == 0
			for dy: int in range(-5, 6):
				var half: int = 3 - floori(absi(dy) / 2.0)
				for dx: int in range(-half, half + 1):
					var color: Color = _palette["i"]
					if dx < 0 and dy < 0:
						color = _palette["I"]
					elif dx > 0 or dy > 2:
						color = _palette["j"]
					_px(img, c + Vector2i(dx, dy), _palette["I"] if bright else color)
			if firing:
				var reach: int = 6 if frame == 0 else 8
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, -1)]:
					_px(img, c + d * reach, _palette["I"])
	return _finish_character(img, Vector2i(12, 30))


func _projectiles_sheet() -> Image:
	var rows: Array[Array] = []
	for direction: int in 8:
		rows.append([_arrow(direction)])
	var ball: Image = _blank(Layouts.PROJECTILES["size"])
	_fill_circle(ball, Vector2i(6, 6), 2.5, _palette["z"])
	_px(ball, Vector2i(5, 5), _palette["Z"])
	_px(ball, Vector2i(5, 4), _palette["Z"])
	_outline(ball)
	rows.append([ball])
	var bolts: Array[Image] = []
	for frame: int in 2:
		var bolt: Image = _blank(Layouts.PROJECTILES["size"])
		for dy: int in range(-3, 4):
			var half: int = 2 - floori(absi(dy) / 2.0)
			for dx: int in range(-half, half + 1):
				_px(bolt, Vector2i(6 + dx, 6 + dy), _palette["I"] if dx <= 0 and dy <= 0 else _palette["i"])
		var sparkle: Vector2i = Vector2i(9, 3) if frame == 0 else Vector2i(3, 9)
		_px(bolt, sparkle, _palette["I"])
		_outline(bolt)
		bolts.append(bolt)
	rows.append(bolts)
	return _sheet(rows, Layouts.PROJECTILES["size"])


## An arrow along one of 8 directions: grey head in front, wooden shaft, red fletching behind.
func _arrow(direction: int) -> Image:
	var img: Image = _blank(Layouts.PROJECTILES["size"])
	var dir: Vector2i = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)][direction]
	var center: Vector2i = Vector2i(6, 6)
	for i: int in range(-4, 4):
		_px(img, center + dir * i, _palette["b"])
	_px(img, center + dir * 4, _palette["S"])
	_px(img, center + dir * 3, _palette["s"])
	var across: Vector2i = Vector2i(-dir.y, dir.x)
	_px(img, center - dir * 4 + across, _palette["R"])
	_px(img, center - dir * 4 - across, _palette["R"])
	_outline(img)
	return img


## Flash, fireball, burning cloud, smoke ring, fading smoke. 56x56 art = the 112 px blast area.
func _explosion_sheet() -> Image:
	var size: Vector2i = Layouts.EXPLOSION["size"]
	var frames: Array[Image] = []
	var center: Vector2 = Vector2(size) / 2.0
	var white: Color = Color("fbf6e4")
	var yellow: Color = Color("f2c65c")
	var orange: Color = Color("e0782e")
	var red: Color = Color("a83a22")
	var smoke: Color = Color("6a645c")
	var smoke_dark: Color = Color("453f3a")
	for frame: int in 5:
		var img: Image = _blank(size)
		var radius: float = [9.0, 17.0, 23.0, 26.0, 27.0][frame]
		for y: int in size.y:
			for x: int in size.x:
				var d: float = Vector2(x + 0.5, y + 0.5).distance_to(center)
				var wobble: float = sin(atan2(y - center.y, x - center.x) * 7.0 + frame) * 1.5
				if d > radius + wobble:
					continue
				var t: float = d / radius
				var color: Color
				match frame:
					0:
						color = white if t < 0.6 else yellow
					1:
						color = white if t < 0.25 else (yellow if t < 0.55 else orange)
					2:
						color = yellow if t < 0.25 else (orange if t < 0.6 else (red if t < 0.85 else smoke_dark))
					3:
						if t < 0.55:
							continue  # the smoke ring opens up
						color = smoke if t < 0.85 else smoke_dark
					_:
						if t < 0.7:
							continue
						color = smoke
				if frame >= 3 and _bayer(x, y) < (0.3 if frame == 3 else 0.65):
					continue
				img.set_pixel(x, y, color)
		frames.append(img)
	return _sheet([frames], size)


func _frost_sheet() -> Image:
	var size: Vector2i = Layouts.FROST_FX["size"]
	var burst: Array[Image] = []
	var c: Vector2i = Vector2i(10, 10)
	for frame: int in 4:
		var img: Image = _blank(size)
		var reach: int = [2, 4, 6, 8][frame]
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
				Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
			var length: int = reach if d.x == 0 or d.y == 0 else maxi(reach - 3, 1)
			for i: int in range(maxi(length - 3, 0), length + 1):
				if frame == 3 and _bayer(c.x + d.x * i, c.y + d.y * i) < 0.5:
					continue
				_px(img, c + d * i, _palette["I"] if i < length else _palette["i"])
		burst.append(img)
	# Aura for slowed enemies: ice crystals around the feet, twinkling.
	var aura: Array[Image] = []
	var crystals: Array[Vector2i] = [Vector2i(3, 15), Vector2i(7, 17), Vector2i(12, 17), Vector2i(16, 15), Vector2i(10, 16)]
	for frame: int in 2:
		var img: Image = _blank(size)
		for i: int in crystals.size():
			var p: Vector2i = crystals[i]
			_px(img, p, _palette["i"])
			_px(img, p + Vector2i(0, -1), _palette["I"] if (i + frame) % 2 == 0 else _palette["i"])
			if (i + frame) % 2 == 0:
				_px(img, p + Vector2i(0, -3), _palette["I"])
		aura.append(img)
	return _sheet([burst, aura], size)


## A flat stone pad with gold rune markers; the highlighted frame has a glowing gold rim.
func _build_slot_sheet() -> Image:
	var size: Vector2i = Layouts.BUILD_SLOT["size"]
	var frames: Array[Image] = []
	for highlighted: bool in [false, true]:
		var img: Image = _blank(size)
		var center: Vector2 = Vector2(14, 10)
		for y: int in size.y:
			for x: int in size.x:
				var v: Vector2 = (Vector2(x + 0.5, y + 0.5) - center) / Vector2(13.0, 9.0)
				var d: float = v.length()
				if d > 1.0:
					continue
				var color: Color = Color("5f5b67") if d < 0.75 else Color("4a4652")
				if d < 0.75 and (x + y * 3) % 7 == 0:
					color = Color("6b6773")
				if d >= 0.86 and highlighted:
					color = _palette["Y"]
				img.set_pixel(x, y, color)
		for p: Vector2i in [Vector2i(14, 3), Vector2i(14, 16), Vector2i(4, 10), Vector2i(23, 10)]:
			_px(img, p, _palette["Y"] if highlighted else _palette["y"])
		_outline(img)
		frames.append(img)
	return _sheet([frames], size)


# ---------------------------------------------------------------- arena ground

## Bakes the prototype arena's floor: dark grass, the dirt lane read from the level's Path2D,
## a clearing around the fortress, scattered details, and a stone wall band around the arena.
func _ground() -> Image:
	var level: Node = (load("res://levels/prototype_arena.tscn") as PackedScene).instantiate()
	var floor_node: ColorRect = level.get_node("Floor")
	var lane: Path2D = level.get_node("Lane")
	var fortress_pos: Vector2 = (level.get_node("Fortress") as Node2D).position
	var band: int = Layouts.WALL_BAND
	var scale: float = float(Layouts.ART_SCALE)
	var origin: Vector2 = floor_node.position - Vector2(band, band)
	var size: Vector2i = Vector2i(((floor_node.size + Vector2(band, band) * 2.0) / scale).round())
	var floor_art: Rect2i = Rect2i(Vector2i(int(band / scale), int(band / scale)), Vector2i((floor_node.size / scale).round()))
	var lane_points: Array[Vector2] = []
	for i: int in lane.curve.point_count:
		lane_points.append((lane.to_global(lane.curve.get_point_position(i)) - origin) / scale)
	var spawn: Vector2 = lane_points[0]
	var keep: Vector2 = (fortress_pos - origin) / scale
	level.free()

	var img: Image = _blank(size)
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.13
	var patches: FastNoiseLite = FastNoiseLite.new()
	patches.seed = 19
	patches.frequency = 0.018
	var grass: Array[Color] = [Color("263820"), Color("2a3d23"), Color("2e4327"), Color("34492c")]
	var dry: Array[Color] = [Color("3c3d25"), Color("47462b")]
	var dirt: Array[Color] = [Color("4a3a2c"), Color("524131"), Color("5c4937")]
	var dirt_edge: Color = Color("3f2f21")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1234

	# Grass, dry patches, the lane and the clearing.
	for y: int in size.y:
		for x: int in size.x:
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var n: float = noise.get_noise_2d(x, y)
			var jitter: float = noise.get_noise_2d(x * 3.0, y * 3.0) * 1.6
			var lane_d: float = _distance_to_polyline(p, lane_points) + jitter
			var clearing_d: float = p.distance_to(keep) - 33.0 + jitter * 2.0
			var path_d: float = minf(lane_d - 8.0, clearing_d)
			var color: Color
			if path_d < -1.0:
				color = dirt[clampi(int((n + 1.0) * 1.5), 0, 2)]
				if rng.randf() < 0.012:
					color = Color("7a6a58")  # pebble
			elif path_d < 0.5:
				color = dirt_edge
			elif patches.get_noise_2d(x, y) > 0.35:
				color = dry[1 if n > 0.1 else 0]
			else:
				var shade: int = clampi(int((n + 0.7) * 2.2), 0, 3)
				if (x + y) % 2 == 0 and shade < 3 and noise.get_noise_2d(y, x) > 0.45:
					shade += 1  # sparse dither keeps the grass lively but low-contrast
				color = grass[shade]
			img.set_pixel(x, y, color)

	# Details on grass only, never on the lane, the clearing or right at the walls.
	var keep_out: Callable = func(p: Vector2) -> bool:
		return (_distance_to_polyline(p, lane_points) < 12.0 or p.distance_to(keep) < 40.0
			or not Rect2(floor_art).grow(-4).has_point(p))
	for i: int in 2200:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if keep_out.call(p):
			continue
		var is_dry: bool = patches.get_noise_2d(p.x, p.y) > 0.3
		var blade: Color = (Color("6f6941") if is_dry else Color("44633b")) if rng.randf() < 0.65 else Color("1d2b18")
		var tip: Vector2i = Vector2i(p)
		_px(img, tip, blade)
		_px(img, tip + Vector2i(-1, 1), blade)
		_px(img, tip + Vector2i(1, 1), blade)
	for i: int in 55:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if not keep_out.call(p):
			_stone(img, Vector2i(p), rng.randi_range(1, 2))
	for i: int in 26:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if keep_out.call(p):
			continue
		var dir: Vector2i = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, -1)][rng.randi_range(0, 2)]
		for step: int in rng.randi_range(3, 5):
			_px(img, Vector2i(p) + dir * step, Color("4e3a28"))
	for i: int in 12:
		var p: Vector2 = Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		if keep_out.call(p):
			continue
		var bone: Color = Color("cfc7ae")
		_px(img, Vector2i(p), bone)
		_px(img, Vector2i(p) + Vector2i(1, 0), bone)
		_px(img, Vector2i(p) + Vector2i(2, 0), bone)
		_px(img, Vector2i(p) + Vector2i(-1, -1), bone)
		_px(img, Vector2i(p) + Vector2i(3, 1), bone)

	# A small graveyard where the dead rise (the lane start).
	for offset: Vector2i in [Vector2i(-14, -14), Vector2i(-4, -17), Vector2i(10, -15), Vector2i(-16, 11), Vector2i(8, 13)]:
		_tombstone(img, Vector2i(spawn) + offset)

	_wall_band(img, floor_art)
	return img


## A small, flat, muted stone: dark base, mid face, one lit pixel. Never brighter than the characters.
func _stone(img: Image, at: Vector2i, radius: int) -> void:
	_fill_rect(img, Rect2i(at + Vector2i(-radius, 0), Vector2i(radius * 2 + 1, radius + 1)), Color("1f2a1a"))
	_fill_rect(img, Rect2i(at + Vector2i(-radius, -1), Vector2i(radius * 2 + 1, radius + 1)), Color("4c4a52"))
	_fill_rect(img, Rect2i(at + Vector2i(-radius + 1, -1), Vector2i(radius * 2 - 1, 1)), Color("5f5c66"))
	_px(img, at + Vector2i(-radius + 1, -1), Color("75727c"))


func _tombstone(img: Image, at: Vector2i) -> void:
	_fill_rect(img, Rect2i(at + Vector2i(1, 1), Vector2i(6, 8)), Color("1b2216"))
	_fill_rect(img, Rect2i(at, Vector2i(6, 8)), Color("6a6672"))
	_fill_rect(img, Rect2i(at + Vector2i(1, 0), Vector2i(4, 1)), Color("8a8692"))
	_px(img, at, Color(0, 0, 0, 0))
	_px(img, at + Vector2i(5, 0), Color(0, 0, 0, 0))
	_fill_rect(img, Rect2i(at + Vector2i(2, 2), Vector2i(2, 4)), Color("45414d"))
	_fill_rect(img, Rect2i(at + Vector2i(1, 3), Vector2i(4, 1)), Color("45414d"))
	_fill_rect(img, Rect2i(at + Vector2i(0, 7), Vector2i(6, 1)), Color("4d4955"))


## Stone blocks around the playable floor, battlements along the inner edge, and a soft
## shadow on the grass just inside, so the boundary reads clearly.
func _wall_band(img: Image, floor_art: Rect2i) -> void:
	var size: Vector2i = img.get_size()
	var block: Array[Color] = [Color("5a5662"), Color("64606c"), Color("6e6a76")]
	var mortar: Color = Color("37333f")
	for y: int in size.y:
		for x: int in size.x:
			var p: Vector2i = Vector2i(x, y)
			if floor_art.has_point(p):
				var edge: int = mini(mini(x - floor_art.position.x, floor_art.end.x - 1 - x),
					mini(y - floor_art.position.y, floor_art.end.y - 1 - y))
				if edge < 3:
					img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.45 - edge * 0.12))
				continue
			var row: int = floori(y / 5.0)
			var col: int = floori((x + (row % 2) * 4) / 8.0)
			var is_mortar: bool = y % 5 == 4 or (x + (row % 2) * 4) % 8 == 7
			var color: Color = mortar if is_mortar else block[(row * 7 + col * 3) % 3]
			# Merlons on the band's inner rim.
			# Distance to the floor, measured only across this side of the band (so corners stay clean).
			var rim: int
			var along: int
			if y < floor_art.position.y:
				rim = floor_art.position.y - 1 - y
				along = x
			elif y >= floor_art.end.y:
				rim = y - floor_art.end.y
				along = x
			elif x < floor_art.position.x:
				rim = floor_art.position.x - 1 - x
				along = y
			else:
				rim = x - floor_art.end.x
				along = y
			if rim <= 2:
				color = Color("8a8692") if floori(along / 3.0) % 2 == 0 else Color("4a4652")
			img.set_pixel(x, y, color)


func _distance_to_polyline(p: Vector2, points: Array[Vector2]) -> float:
	var best: float = INF
	for i: int in points.size() - 1:
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(p, points[i], points[i + 1])
		best = minf(best, p.distance_to(closest))
	return best


# ---------------------------------------------------------------- image helpers

## A single grid as an image, optionally with the standard outline (1 px border added for it).
func _grid_image(grid: Array[String], outlined: bool) -> Image:
	var pad: int = 1 if outlined else 0
	var img: Image = _blank(Vector2i(grid[0].length() + pad * 2, grid.size() + pad * 2))
	_paste(img, grid, Vector2i(pad, pad))
	if outlined:
		_outline(img)
	return img


func _blank(size: Vector2i) -> Image:
	return Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)


func _px(img: Image, p: Vector2i, color: Color) -> void:
	if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
		img.set_pixelv(p, color)


func _paste(img: Image, grid: Array, at: Vector2i) -> void:
	for y: int in grid.size():
		var row: String = grid[y]
		for x: int in row.length():
			var key: String = row[x]
			if key != ".":
				_px(img, at + Vector2i(x, y), _palette[key])


func _fill_rect(img: Image, rect: Rect2i, color: Color) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			_px(img, Vector2i(x, y), color)


func _fill_circle(img: Image, center: Vector2i, radius: float, color: Color) -> void:
	var r: int = ceili(radius)
	for y: int in range(-r, r + 1):
		for x: int in range(-r, r + 1):
			if Vector2(x, y).length() <= radius:
				_px(img, center + Vector2i(x, y), color)


## Adds a 1 px dark outline around every opaque shape (4-neighbour), giving strong silhouettes.
func _outline(img: Image) -> void:
	var src: Image = img.duplicate() as Image
	for y: int in img.get_height():
		for x: int in img.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in DIRS_4:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and src.get_pixelv(q).a > 0.5:
					img.set_pixel(x, y, _outline_color)
					break


## Outline, then a soft oval shadow under the feet (drawn only where nothing else is).
func _finish_character(img: Image, feet: Vector2i) -> Image:
	_outline(img)
	for y: int in range(-1, 2):
		for x: int in range(-5, 6):
			var p: Vector2i = feet + Vector2i(x, y)
			if absf(x) / 5.5 + absf(y) / 1.6 <= 1.0 and img.get_pixelv(p).a == 0.0:
				img.set_pixelv(p, _shadow_color)
	return img


func _drop_shadow(dst: Image, src: Image, at: Vector2i, offset: Vector2i) -> void:
	for y: int in src.get_height():
		for x: int in src.get_width():
			if src.get_pixel(x, y).a > 0.5:
				_px(dst, at + offset + Vector2i(x, y), _shadow_color)


func _tint(img: Image, color: Color, amount: float) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			if c.a > 0.0:
				img.set_pixel(x, y, Color(c.lerp(color, amount), c.a))


## 4x4 ordered-dither threshold in [0, 1): the classic retro way to fade pixel art without blur.
func _bayer(x: int, y: int) -> float:
	const MATRIX: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	return MATRIX[(y % 4) * 4 + x % 4] / 16.0


func _clear_translucent(img: Image) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			if img.get_pixel(x, y).a < 0.5:
				img.set_pixel(x, y, Color(0, 0, 0, 0))


func _dither_out(img: Image, phase: int) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			if (x + y + phase) % 2 == 0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))


## Lays out rows of equally sized frames into one sheet.
func _sheet(rows: Array, frame_size: Vector2i) -> Image:
	var columns: int = 0
	for row: Array in rows:
		columns = maxi(columns, row.size())
	var sheet: Image = _blank(Vector2i(frame_size.x * columns, frame_size.y * rows.size()))
	for r: int in rows.size():
		var row: Array = rows[r]
		for c: int in row.size():
			var frame: Image = row[c]
			sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(c * frame_size.x, r * frame_size.y))
	return sheet


func _save(img: Image, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var err: Error = img.save_png(ProjectSettings.globalize_path(path))
	print("%s %s (%dx%d)" % ["saved" if err == OK else "FAILED", path, img.get_width(), img.get_height()])
