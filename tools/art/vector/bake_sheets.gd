extends SceneTree
## Bakes the vector sheets (M15, docs/M15_VECTOR.md): every layout in sheet_layouts.gd with a "vector" painter is drawn
## frame by frame into its PNG, at the layout's "scale" (sheet pixels per world pixel). One transparent SubViewport per
## sheet, one canvas node per frame cell, a single render; the result is converted from premultiplied to straight alpha
## so the sprites' edges don't darken. Baking renders on the GPU, so it needs a window (not --headless):
##   godot --path . --script res://tools/art/vector/bake_sheets.gd [-- --only=knight] [--report-bad]
##   godot --headless --path . --import
##   godot --headless --path . --script res://tools/art/build_sprite_frames.gd

const Layouts: GDScript = preload("res://tools/art/sheet_layouts.gd")

## The painter per "vector" id: frame(ci, anim, index, count) and the figure's scale against the old sprite.
var _painters: Dictionary = {
	"knight": [KnightPainter.frame, KnightPainter.SCALE],
	"ghoul": [GhoulPainter.frame, GhoulPainter.SCALE],
	"hound": [HoundPainter.frame, HoundPainter.SCALE],
	"brute": [BrutePainter.frame, BrutePainter.SCALE],
	"cultist": [CultistPainter.frame, CultistPainter.SCALE],
	"gravelord": [GravelordPainter.frame, GravelordPainter.SCALE],
	"colossus": [ColossusPainter.frame, ColossusPainter.SCALE],
	"lich": [LichPainter.frame, LichPainter.SCALE],
	"huntress": [HuntressPainter.frame, HuntressPainter.SCALE],
	"fx": [FxPainter.frame, 1.0],
	"necromancer": [NecromancerPainter.frame, NecromancerPainter.SCALE],
	"skeleton": [SkeletonPainter.frame, SkeletonPainter.SCALE],
	"tower": [TowerPainter.frame, TowerPainter.SCALE],
	"effects": [EffectsPainter.frame, 1.0],
	"fortress_fx": [FortressPainter.decor_frame, 1.0],
}
## Static sheets (one row of cells, a Sprite2D's hframes): painter(ci, column) per "vector" id.
var _static_painters: Dictionary = {
	"fortress": FortressPainter.frame,
	"env_props": EnvPainter.prop_frame,
	"env_crypt": EnvPainter.crypt_frame,
	"env_pad": EnvPainter.pad_frame,
	"env_rubble": EnvPainter.rubble_frame,
}
var _failures: int = 0


func _initialize() -> void:
	var only: PackedStringArray = PackedStringArray()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.trim_prefix("--only=").split(",")
		elif arg == "--report-bad":
			VectorPaint.report_bad = true
	await process_frame
	for sheet: Dictionary in Layouts.ANIMATED:
		if not sheet.has("vector"):
			continue
		var id: String = sheet["vector"]
		if not only.is_empty() and not only.has(id):
			continue
		if not _painters.has(id):
			push_error("No painter for vector sheet %s" % id)
			_failures += 1
			continue
		await _bake(sheet, _painters[id])
	for sheet: Dictionary in Layouts.STATIC:
		var id: String = sheet["vector"]
		if not only.is_empty() and not only.has(id):
			continue
		if not _static_painters.has(id):
			push_error("No painter for static vector sheet %s" % id)
			_failures += 1
			continue
		var cells: Dictionary = sheet.duplicate()
		cells["anims"] = [["static", 0, int(sheet["columns"]), 1.0, false]]
		var paint_cell: Callable = _static_painters[id]
		await _bake(cells, [func(ci: CanvasItem, _anim: String, index: int, _count: int) -> void: paint_cell.call(ci, index), 1.0])
	for ground: Dictionary in Layouts.GROUNDS:
		if only.is_empty() or only.has(String(ground["vector"])):
			await _bake_ground(ground)
	quit(_failures)


func _bake(sheet: Dictionary, painter: Array) -> void:
	var size: Vector2i = sheet["size"]
	var scale_by: float = float(sheet["scale"])
	var origin: Vector2 = sheet.get("origin", Vector2.ZERO)
	var rows: int = 0
	var columns: int = 0
	for anim: Array in sheet["anims"]:
		rows = maxi(rows, int(anim[1]) + 1)
		columns = maxi(columns, int(anim[2]))
	var view: SubViewport = SubViewport.new()
	view.size = Vector2i(size.x * columns, size.y * rows)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	var draw_frame: Callable = painter[0]
	var figure: float = float(painter[1])
	for anim: Array in sheet["anims"]:
		var anim_name: String = anim[0]
		var count: int = anim[2]
		for index: int in count:
			var cell: Node2D = Node2D.new()
			cell.position = Vector2((index + 0.5) * size.x, (int(anim[1]) + 0.5) * size.y) + origin * scale_by
			cell.scale = Vector2.ONE * scale_by * figure
			cell.draw.connect(func() -> void: draw_frame.call(cell, anim_name, index, count))
			view.add_child(cell)
	root.add_child(view)
	for i: int in 3:
		await process_frame
	var image: Image = view.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	var straight: Image = _unpremultiply(image)
	var path: String = ProjectSettings.globalize_path(sheet["png"])
	var err: Error = straight.save_png(path)
	print("%s %s (%dx%d, %d rows)" % ["baked" if err == OK else "FAILED", sheet["png"], straight.get_width(), straight.get_height(), rows])
	if err != OK:
		_failures += 1
	view.queue_free()
	await process_frame


## A level's ground (GroundPainter): the level's geometry is read from its scene, then painted into one big opaque texture.
func _bake_ground(spec: Dictionary) -> void:
	var level: Node2D = (load(spec["level"]) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	var painter: GroundPainter = GroundPainter.new()
	var floor_control: Control = level.get_node("%Floor")
	painter.floor_rect = Rect2(floor_control.position, floor_control.size)
	painter.band = float(spec["band"])
	painter.fortress = (level.get_node("Fortress") as Node2D).position
	for child: Node in level.get_children():
		if child is Path2D and String(child.name).begins_with("Lane"):
			var path: Path2D = child
			var points: PackedVector2Array = PackedVector2Array()
			for p: Vector2 in path.curve.get_baked_points():
				points.append(level.to_local(path.to_global(p)))
			painter.lanes.append(points)
		elif child is Sprite2D and String(child.name).begins_with("Crypt"):
			painter.crypts.append((child as Node2D).position)
	var slots: Node = level.get_node_or_null("BuildSlots")
	if slots != null:
		for slot: Node in slots.get_children():
			painter.avoid.append((slot as Node2D).position)
	level.queue_free()
	await process_frame
	var scale_by: float = float(spec["scale"])
	var outer: Rect2 = painter.floor_rect.grow(painter.band)
	var view: SubViewport = SubViewport.new()
	view.size = Vector2i((outer.size * scale_by).ceil())
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	var canvas: Node2D = Node2D.new()
	canvas.position = -outer.position * scale_by
	canvas.scale = Vector2(scale_by, scale_by)
	canvas.draw.connect(func() -> void: painter.paint(canvas))
	view.add_child(canvas)
	root.add_child(view)
	for i: int in 3:
		await process_frame
	var image: Image = view.get_texture().get_image()
	var err: Error = image.save_png(ProjectSettings.globalize_path(spec["png"]))
	print("%s %s (%dx%d)" % ["baked" if err == OK else "FAILED", spec["png"], image.get_width(), image.get_height()])
	if err != OK:
		_failures += 1
	view.queue_free()
	await process_frame


## A transparent viewport holds colour multiplied by alpha; PNGs and sprites want it straight.
func _unpremultiply(image: Image) -> Image:
	var data: PackedByteArray = image.get_data()
	for i: int in range(0, data.size(), 4):
		var a: int = data[i + 3]
		if a == 0 or a == 255:
			continue
		data[i] = mini(255, roundi(data[i] * 255.0 / a))
		data[i + 1] = mini(255, roundi(data[i + 1] * 255.0 / a))
		data[i + 2] = mini(255, roundi(data[i + 2] * 255.0 / a))
	return Image.create_from_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, data)
