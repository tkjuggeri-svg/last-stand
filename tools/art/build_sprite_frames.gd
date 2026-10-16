extends SceneTree
## Slices the generated spritesheets into SpriteFrames resources (one per sheet in Layouts.ANIMATED).
## Run after generate_art.gd and an import: godot --headless --path . --script res://tools/art/build_sprite_frames.gd

const Layouts: GDScript = preload("res://tools/art/sheet_layouts.gd")


func _initialize() -> void:
	var failures: int = 0
	for sheet: Dictionary in Layouts.ANIMATED:
		var texture: Texture2D = load(sheet["png"])
		if texture == null:
			push_error("Missing texture %s (run an import first)" % sheet["png"])
			failures += 1
			continue
		var frame_size: Vector2i = sheet["size"]
		var frames: SpriteFrames = SpriteFrames.new()
		frames.remove_animation(&"default")
		for anim: Array in sheet["anims"]:
			var anim_name: StringName = StringName(anim[0])
			var row: int = anim[1]
			frames.add_animation(anim_name)
			frames.set_animation_speed(anim_name, anim[3])
			frames.set_animation_loop(anim_name, anim[4])
			for column: int in int(anim[2]):
				var atlas: AtlasTexture = AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(Vector2(column * frame_size.x, row * frame_size.y), Vector2(frame_size))
				frames.add_frame(anim_name, atlas)
		var err: Error = ResourceSaver.save(frames, sheet["frames"])
		print("%s %s (%d animations)" % ["saved" if err == OK else "FAILED", sheet["frames"], frames.get_animation_names().size()])
		if err != OK:
			failures += 1
	quit(failures)
