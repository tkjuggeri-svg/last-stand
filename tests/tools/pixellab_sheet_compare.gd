extends SceneTree
## Screenshots of the code-drawn Knight beside the Pixellab Knight sheet (M15: assets/sprites/hero/hero_pixellab.png, made by
## tools/art/pixellab/import_character.py) in the real arena, plus 4x crops. Nothing in the game is changed.
## godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/tools/pixellab_sheet_compare.gd -- --out=exports/pixellab-test/v3

const Layouts: GDScript = preload("res://tools/art/sheet_layouts.gd")
const ARENA: String = "res://levels/prototype_arena.tscn"
const SHEET: String = "res://assets/sprites/hero/hero_pixellab.png"
const CELL: Vector2i = Vector2i(80, 96)
## The Pixellab Knight stands left of the hero; its cell is placed like the hero's (same centre-to-feet distance).
const SIDE_BY_SIDE: Vector2 = Vector2(-90, 0)
const SPRITE_OFFSET: Vector2 = Vector2(0, -16)

var _out: String = "exports/pixellab-test/v3"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	await process_frame
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	root.add_child(level)
	var hero: Hero = level.get_node("Hero")
	await _frames(20)
	var knight: AnimatedSprite2D = _pixellab_knight()
	hero.add_child(knight)
	knight.top_level = true
	_place(knight, hero)
	knight.play(&"idle_down")
	await _frames(30)
	await _shot("sheet_idle_down", hero)
	Input.action_press("move_right")
	knight.play(&"walk_side")
	for _i: int in 5:
		await _frames(5)
		_place(knight, hero)
	await _shot("sheet_walk_side", hero)
	Input.action_release("move_right")
	await _frames(20)
	Input.action_press("move_up")
	knight.play(&"walk_up")
	for _i: int in 5:
		await _frames(5)
		_place(knight, hero)
	await _shot("sheet_walk_up", hero)
	Input.action_release("move_up")
	quit()


func _place(knight: AnimatedSprite2D, hero: Hero) -> void:
	knight.global_position = hero.global_position + SIDE_BY_SIDE + SPRITE_OFFSET


func _pixellab_knight() -> AnimatedSprite2D:
	var texture: Texture2D = load(SHEET)
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim: Array in Layouts.HERO["anims"]:
		var name: StringName = StringName(anim[0])
		frames.add_animation(name)
		frames.set_animation_speed(name, anim[3])
		frames.set_animation_loop(name, anim[4])
		for column: int in int(anim[2]):
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(Vector2(column * CELL.x, int(anim[1]) * CELL.y), Vector2(CELL))
			frames.add_frame(name, atlas)
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	return sprite


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _shot(shot_name: String, hero: Hero) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var centre: Vector2i = Vector2i(hero.get_global_transform_with_canvas().origin) + Vector2i(SIDE_BY_SIDE / 2.0)
	var crop: Image = image.get_region(Rect2i(centre - Vector2i(120, 90), Vector2i(240, 150)))
	crop.resize(crop.get_width() * 4, crop.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var base: String = ProjectSettings.globalize_path("res://%s/%s" % [_out, shot_name])
	image.save_png(base + ".png")
	crop.save_png(base + "_zoom4x.png")
	print("saved ", shot_name)
