extends SceneTree
## The vector look test's model sheets (branch vector-test, never merge): today's pixel sprites in the top row and the
## vector versions under them, at 3x, on a plain ground colour. characters.png: the Knight and the Ghoul facing down,
## side and up. towers.png: the Archer tower at levels 1-3.
## godot --path . --resolution 1280x720 --script res://tests/tools/vector_model_sheet.gd -- [--out=dev_screenshots/vector_test]

const ZOOM: float = 3.0
const FACINGS: Array[String] = ["down", "side", "up"]
const HERO_FRAMES: String = "res://entities/hero/hero_frames.tres"
const GHOUL_FRAMES: String = "res://entities/enemies/ghoul_frames.tres"
const TOWER_FRAMES: String = "res://entities/towers/tower_frames.tres"

var _out: String = "dev_screenshots/vector_test"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out)
	await process_frame
	await _sheet("characters", _characters)
	await _sheet("towers", _towers)
	quit()


func _sheet(file: String, build: Callable) -> void:
	var holder: Node2D = Node2D.new()
	var back: ColorRect = ColorRect.new()
	back.color = Color("223628")
	back.size = Vector2(1280, 720)
	holder.add_child(back)
	var sheet: Node2D = Node2D.new()
	sheet.scale = Vector2(ZOOM, ZOOM)
	holder.add_child(sheet)
	build.call(sheet, holder)
	root.add_child(holder)
	for i: int in 4:
		await process_frame
	root.get_texture().get_image().save_png("%s/model_%s.png" % [_out, file])
	print("saved %s/model_%s.png" % [_out, file])
	holder.queue_free()
	await process_frame


func _label(holder: Node2D, text: String, at: Vector2) -> void:
	var label: Label = Label.new()
	label.text = text
	label.position = at
	holder.add_child(label)


func _pixel(sheet: Node2D, frames_path: String, animation: String, frame: int, at: Vector2, offset: Vector2) -> void:
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = load(frames_path)
	sprite.animation = StringName(animation)
	sprite.frame = frame
	sprite.position = at + offset
	sheet.add_child(sprite)


func _vector(sheet: Node2D, at: Vector2, scale_by: float, painter: Callable, glow: Callable = Callable()) -> void:
	var cell: Node2D = Node2D.new()
	cell.position = at
	cell.scale = Vector2(scale_by, scale_by)
	cell.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	cell.draw.connect(func() -> void: painter.call(cell))
	sheet.add_child(cell)
	if glow.is_valid():
		VectorStyle.make_glow_layer(cell, glow)


func _characters(sheet: Node2D, holder: Node2D) -> void:
	_label(holder, "Pixel art (today)", Vector2(16, 8))
	_label(holder, "Vector, detailed (test)", Vector2(16, 368))
	for i: int in 3:
		var facing: String = FACINGS[i]
		var x: float = 35.0 + i * 70.0
		_pixel(sheet, HERO_FRAMES, "idle_%s" % facing, 0, Vector2(x, 100), Vector2(0, -16))
		_pixel(sheet, GHOUL_FRAMES, "walk_%s" % facing, 1, Vector2(x + 210, 100), Vector2(0, -10))
		var shoulder: Vector2 = Vector2(-10, -27) if facing == "up" else (Vector2(2, -27) if facing == "side" else Vector2(10, -27))
		var knight_pose: Dictionary = {"facing": facing, "walk": false, "phase": 0.0}
		_vector(sheet, Vector2(x, 210), VectorSkin.KNIGHT_SCALE, func(ci: CanvasItem) -> void:
			VectorStyle.shadow(ci, Vector2(0, 2), 14, 5.5)
			if facing == "up":
				KnightPainter.paint_sword_arm(ci, shoulder, -1.25)
			KnightPainter.paint(ci, knight_pose)
			if facing != "up":
				KnightPainter.paint_sword_arm(ci, shoulder, -1.25),
			func(layer: Node2D) -> void: VectorStyle.draw_glow(layer, VectorStyle.WARM_GLOW, Vector2(0, -22), 34.0, 0.14))
		var ghoul_pose: Dictionary = {"facing": facing, "walk": true, "phase": 0.25, "lunge": 0.0}
		var eyes: Array[Vector2] = []
		if facing == "down":
			eyes = [Vector2(-2.3, -27.0), Vector2(2.3, -27.0)]
		elif facing == "side":
			eyes = [Vector2(13.2, -19.5)]
		_vector(sheet, Vector2(x + 210, 210), VectorSkin.GHOUL_SCALE, func(ci: CanvasItem) -> void:
			VectorStyle.shadow(ci, Vector2(0, 2), 12, 4.8)
			GhoulPainter.paint(ci, ghoul_pose),
			func(layer: Node2D) -> void:
				VectorStyle.draw_glow(layer, VectorStyle.COLD_GLOW, Vector2(0, -14), 24.0, 0.1)
				for eye: Vector2 in eyes:
					VectorStyle.draw_glow(layer, VectorStyle.EYE_RED, eye, 3.6, 0.95))


func _towers(sheet: Node2D, holder: Node2D) -> void:
	_label(holder, "Pixel art (today)", Vector2(16, 8))
	_label(holder, "Vector, detailed (test)", Vector2(16, 368))
	var suffixes: Array[String] = ["", "_2", "_3"]
	for i: int in 3:
		var level: int = i + 1
		var x: float = 60.0 + i * 120.0
		_pixel(sheet, TOWER_FRAMES, "archer_idle%s" % suffixes[i], 0, Vector2(x, 110), Vector2(0, -36))
		_vector(sheet, Vector2(x, 222), 1.0, func(ci: CanvasItem) -> void:
			ArcherPainter.paint_body(ci, level)
			ArcherPainter.paint_archer(ci, PI * 0.3, 0.6)
			for at: Vector2 in ArcherPainter.TORCHES:
				ArcherPainter.paint_flame(ci, at, 0.3),
			func(layer: Node2D) -> void:
				for at: Vector2 in ArcherPainter.TORCHES:
					VectorStyle.draw_glow(layer, VectorStyle.WARM_GLOW, at + Vector2(0, -7), 16.0, 0.7)
					VectorStyle.draw_glow(layer, VectorStyle.WARM_GLOW, at + Vector2(0, -5), 34.0, 0.16)
				VectorStyle.draw_glow(layer, VectorStyle.WARM_GLOW, Vector2(0, -26), 12.0, 0.55))
