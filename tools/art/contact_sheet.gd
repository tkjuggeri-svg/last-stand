extends SceneTree
## Dev tool (not shipped): a contact sheet of sprites at game scale (1 sheet px = 1 world px, then enlarged),
## one row per sprite with its idle (front), idle (side), walk (side) and attack frames, on a dark ground, for
## reviewing art without starting the game:
##   godot --headless --path . --script res://tools/art/contact_sheet.gd -- --ids=hero,ghoul,cinder_ghoul --out=/tmp/sheet.png [--zoom=3] [--suffix=_idle]

const Layouts: GDScript = preload("res://tools/art/sheet_layouts.gd")
const GROUND: Color = Color("2c3328")
const SHOW: Array[String] = ["idle_down", "idle_side", "walk_side", "attack_side"]


func _initialize() -> void:
	var ids: PackedStringArray = []
	var out: String = "user://contact.png"
	var zoom: int = 3
	var suffix: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--ids="):
			ids = arg.trim_prefix("--ids=").split(",")
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--zoom="):
			zoom = int(arg.trim_prefix("--zoom="))
		elif arg.begins_with("--suffix="):
			suffix = arg.trim_prefix("--suffix=")  # every animation ending so (towers: _idle), instead of the default four
	var tiles: Array = []
	var cell: Vector2i = Vector2i.ZERO
	for id: String in ids:
		var layout: Dictionary = Layouts.get_script_constant_map().get(id.to_upper(), {})
		if layout.is_empty():
			push_error("no layout for %s" % id)
			continue
		var sheet: Image = Image.load_from_file(ProjectSettings.globalize_path(layout["png"]))
		var size: Vector2i = layout["size"]
		cell = Vector2i(maxi(cell.x, size.x), maxi(cell.y, size.y))
		var row: Array[Image] = []
		for anim: Array in layout["anims"]:
			if (suffix != "" and String(anim[0]).ends_with(suffix)) or (suffix == "" and SHOW.has(String(anim[0]))):
				var tile: Image = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
				tile.fill(GROUND)
				tile.blend_rect(sheet, Rect2i(Vector2i(0, int(anim[1]) * size.y), size), Vector2i.ZERO)
				row.append(tile)
		tiles.append(row)
	var columns: int = 0
	for row: Array in tiles:
		columns = maxi(columns, row.size())
	var canvas: Image = Image.create_empty(columns * cell.x, tiles.size() * cell.y, false, Image.FORMAT_RGBA8)
	canvas.fill(GROUND)
	for r: int in tiles.size():
		for c: int in (tiles[r] as Array).size():
			var tile: Image = tiles[r][c]
			canvas.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), Vector2i(c * cell.x, r * cell.y))
	canvas.resize(canvas.get_width() * zoom, canvas.get_height() * zoom, Image.INTERPOLATE_NEAREST)
	canvas.save_png(out)
	print("saved %s (%d sprites)" % [out, tiles.size()])
	quit()
