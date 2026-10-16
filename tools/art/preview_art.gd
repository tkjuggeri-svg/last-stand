extends SceneTree
## Renders a generated sheet as an enlarged contact sheet on a grass-coloured background, for
## reviewing art without starting the game (dev tool, not shipped):
##   godot --headless --path . --script res://tools/art/preview_art.gd -- --png=res://assets/sprites/hero/hero.png --frame=32x40 --out=/tmp/hero.png [--zoom=6]

const BACKGROUND: Color = Color("24331a")
const GAP: int = 2


func _initialize() -> void:
	var png: String = ""
	var out: String = "user://preview.png"
	var frame: Vector2i = Vector2i(32, 32)
	var zoom: int = 6
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--png="):
			png = arg.trim_prefix("--png=")
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--frame="):
			var parts: PackedStringArray = arg.trim_prefix("--frame=").split("x")
			frame = Vector2i(int(parts[0]), int(parts[1]))
		elif arg.begins_with("--zoom="):
			zoom = int(arg.trim_prefix("--zoom="))
	var sheet: Image = Image.load_from_file(ProjectSettings.globalize_path(png))
	var columns: int = floori(sheet.get_width() / float(frame.x))
	var rows: int = floori(sheet.get_height() / float(frame.y))
	var cell: Vector2i = frame + Vector2i(GAP, GAP)
	var canvas: Image = Image.create_empty(columns * cell.x, rows * cell.y, false, Image.FORMAT_RGBA8)
	canvas.fill(Color("101014"))
	for r: int in rows:
		for col: int in columns:
			var tile: Image = Image.create_empty(frame.x, frame.y, false, Image.FORMAT_RGBA8)
			tile.fill(BACKGROUND)
			tile.blend_rect(sheet, Rect2i(Vector2i(col, r) * frame, frame), Vector2i.ZERO)
			canvas.blit_rect(tile, Rect2i(Vector2i.ZERO, frame), Vector2i(col, r) * cell)
	canvas.resize(canvas.get_width() * zoom, canvas.get_height() * zoom, Image.INTERPOLATE_NEAREST)
	canvas.save_png(out)
	print("preview saved: ", out)
	quit()
