extends SceneTree
## Automated check for the vector art (M15, docs/M15_VECTOR.md): every layout with a "vector" painter has a baked sheet of
## the layout's size, no empty frame, SpriteFrames that carry the sheet scale, and sprites that draw it at 1 / scale with
## linear filtering, while a pixel sheet stays at scale 1. The real hero scene shows the vector Knight that way.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const Layouts: GDScript = preload("res://tools/art/sheet_layouts.gd")

var _failures: int = 0


func _initialize() -> void:
	var vector_sheets: int = 0
	for sheet: Dictionary in Layouts.ANIMATED:
		if sheet.has("vector"):
			vector_sheets += 1
			_check_sheet(sheet)
	_check("at least one vector sheet (the Knight)", vector_sheets >= 1)
	await _check_sprites()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _check_sheet(sheet: Dictionary) -> void:
	var id: String = sheet["vector"]
	var size: Vector2i = sheet["size"]
	var rows: int = 0
	var columns: int = 0
	for anim: Array in sheet["anims"]:
		rows = maxi(rows, int(anim[1]) + 1)
		columns = maxi(columns, int(anim[2]))
	var image: Image = (load(sheet["png"]) as Texture2D).get_image()
	_check("%s: the sheet is %dx%d frames of %s" % [id, columns, rows, size], image.get_size() == Vector2i(size.x * columns, size.y * rows))
	var empty: Array[String] = []
	for anim: Array in sheet["anims"]:
		for index: int in int(anim[2]):
			var cell: Rect2i = Rect2i(Vector2i(index * size.x, int(anim[1]) * size.y), size)
			# An effect that plays once may end on a fully faded frame (the spark, the dust): only the last one.
			var fades_out: bool = id == "effects" and not bool(anim[4]) and index == int(anim[2]) - 1
			if image.get_region(cell).is_invisible() and not fades_out:
				empty.append("%s %d" % [anim[0], index])
	_check("%s: no empty frame %s" % [id, empty], empty.is_empty())
	var frames: SpriteFrames = load(sheet["frames"])
	_check("%s: its SpriteFrames carry the sheet scale %s" % [id, sheet["scale"]], is_equal_approx(float(frames.get_meta(SheetSprite.SHEET_SCALE, 1.0)), float(sheet["scale"])))


func _check_sprites() -> void:
	var vector_sprite: SheetSprite = SheetSprite.new()
	vector_sprite.sprite_frames = load(Layouts.HERO["frames"])
	root.add_child(vector_sprite)
	await process_frame
	_check("a vector sheet draws at half size with linear filtering", vector_sprite.scale.is_equal_approx(Vector2(0.5, 0.5))
		and vector_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR)
	vector_sprite.sprite_frames = load(Layouts.HUNTRESS["frames"])  # still a pixel sheet
	_check("swapping to a pixel sheet goes back to scale 1 and the project's filter", vector_sprite.scale.is_equal_approx(Vector2.ONE)
		and vector_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_PARENT_NODE)
	vector_sprite.queue_free()
	var hero: Hero = (load("res://entities/hero/hero.tscn") as PackedScene).instantiate()
	root.add_child(hero)
	await process_frame
	var sprite: DirectionalSprite = hero.get_node("%Sprite")
	_check("the Knight in the hero scene is the vector sheet at half size", sprite.scale.is_equal_approx(Vector2(0.5, 0.5))
		and sprite.sprite_frames.has_animation(&"walk_side") and sprite.sprite_frames.get_frame_count(&"walk_side") == 12)
	hero.queue_free()
	await process_frame


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
