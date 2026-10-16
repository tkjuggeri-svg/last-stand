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
const TowerArt: GDScript = preload("res://tools/art/tower_art.gd")
const EnvironmentArt: GDScript = preload("res://tools/art/environment_art.gd")

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
		"props": func() -> void: _save(_sheet([EnvironmentArt.new().prop_frames()], EnvironmentArt.PROP_SIZE), Layouts.PROPS_PNG),
		"crypt": func() -> void: _save(EnvironmentArt.new().crypt(), Layouts.CRYPT_PNG),
		"mote": func() -> void: _save(EnvironmentArt.new().mote(), Layouts.MOTE_PNG),
		"coin": func() -> void: _save(_grid_image(COIN, true), Layouts.COIN_PNG),
		"towers": func() -> void: _save(_sheet(TowerArt.new().sheet_rows(), Layouts.TOWERS["size"]), Layouts.TOWERS["png"]),
		"projectiles": func() -> void: _save(_sheet(TowerArt.new().projectile_rows(), Layouts.PROJECTILES["size"]), Layouts.PROJECTILES["png"]),
		"explosion": func() -> void: _save(_sheet([TowerArt.new().explosion_frames()], Layouts.EXPLOSION["size"]), Layouts.EXPLOSION["png"]),
		"frost": func() -> void: _save(_sheet(TowerArt.new().frost_rows(), Layouts.FROST_FX["size"]), Layouts.FROST_FX["png"]),
		"slot": func() -> void: _save(_sheet([EnvironmentArt.new().slot_frames()], Layouts.BUILD_SLOT["size"]), Layouts.BUILD_SLOT["png"]),
	}
	for job_name: String in jobs:
		if only.is_empty() or only.has(job_name):
			(jobs[job_name] as Callable).call()
	quit()


# ---------------------------------------------------------------- arena ground

## Bakes the prototype arena's ground from the level's floor, lane and fortress.
func _ground() -> Image:
	var level: Node = (load("res://levels/prototype_arena.tscn") as PackedScene).instantiate()
	var floor_node: ColorRect = level.get_node("Floor")
	var lane: Path2D = level.get_node("Lane")
	var lane_points: Array[Vector2] = []
	for i: int in lane.curve.point_count:
		lane_points.append(lane.to_global(lane.curve.get_point_position(i)))
	var keep: Vector2 = (level.get_node("Fortress") as Node2D).position
	var floor_rect: Rect2 = Rect2(floor_node.position, floor_node.size)
	level.free()
	return EnvironmentArt.new().ground(floor_rect, lane_points, keep, Layouts.WALL_BAND, float(Layouts.ART_SCALE))

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


## 4x4 ordered-dither threshold in [0, 1): the classic retro way to fade pixel art without blur.
func _bayer(x: int, y: int) -> float:
	const MATRIX: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	return MATRIX[(y % 4) * 4 + x % 4] / 16.0


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
