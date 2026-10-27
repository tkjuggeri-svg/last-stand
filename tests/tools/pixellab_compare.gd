extends SceneTree
## Screenshots of the current knight beside a Pixellab one (M15 test) in the real arena. The Pixellab knight is built at run time from
## the PNGs in <dir>/clean (idle, walk, attack in south, east, north; west mirrors east) and nothing in the game is changed.
## godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/tools/pixellab_compare.gd -- --dir=exports/pixellab-test

const ARENA: String = "res://levels/prototype_arena.tscn"
const COUNTS: Dictionary = {"idle": 4, "walk": 6, "attack": 4}
const FPS: Dictionary = {"idle": 5.0, "walk": 11.0, "attack": 20.0}
const DIRECTIONS: Array[String] = ["south", "east", "north"]
## Where the Pixellab knight stands from the hero, and how far its frame sits above the hero's feet line (px): both knights' boots line up.
const SIDE_BY_SIDE: Vector2 = Vector2(-90, -8)

var _dir: String = "exports/pixellab-test"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--dir="):
			_dir = arg.trim_prefix("--dir=")
	await process_frame
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	root.add_child(level)
	var hero: Hero = level.get_node("Hero")
	await _frames(20)
	var knight: AnimatedSprite2D = _pixellab_knight()
	hero.add_child(knight)
	knight.top_level = true
	knight.global_position = hero.global_position + SIDE_BY_SIDE
	knight.play(&"idle_south")
	await _frames(30)
	await _shot("ingame_idle_south")
	# Facing east: the real hero turns toward a point to the right and swings; the Pixellab knight plays its east attack.
	hero.attack(hero.global_position + Vector2(200, 0))
	knight.play(&"attack_east")
	await _frames(6)
	await _shot("ingame_attack_east")
	await _frames(40)
	# Walking north: the real hero walks with the move action (away from the build pads), the Pixellab knight plays its walk and
	# is kept beside it.
	Input.action_press("move_up")
	knight.play(&"walk_north")
	for _i: int in 5:
		await _frames(5)
		knight.global_position = hero.global_position + SIDE_BY_SIDE
	await _shot("ingame_walk_north")
	Input.action_release("move_up")
	quit()


## One AnimatedSprite2D with idle/walk/attack in south, east, north (and west as east mirrored: the game mirrors its side art the same way).
func _pixellab_knight() -> AnimatedSprite2D:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim: String in COUNTS:
		for direction: String in DIRECTIONS:
			var name: StringName = StringName("%s_%s" % [anim, direction])
			frames.add_animation(name)
			frames.set_animation_speed(name, FPS[anim])
			frames.set_animation_loop(name, anim != "attack")
			for i: int in int(COUNTS[anim]):
				var image: Image = Image.load_from_file(ProjectSettings.globalize_path("res://%s/clean/%s_%s_%d.png" % [_dir, anim, direction, i]))
				frames.add_frame(name, ImageTexture.create_from_image(image))
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sprite


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://%s/%s.png" % [_dir, shot_name]))
	print("saved ", shot_name)
