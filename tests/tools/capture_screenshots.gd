extends SceneTree
## Plays a short scripted scene in the real game window and saves screenshots, for visual review.
## Needs a display (not --headless):
##   godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/tools/capture_screenshots.gd -- --out=/some/dir

var _out_dir: String = "user://screenshots"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(60)
	await _shot("01_start")

	var level: Level = null
	for child: Node in main.get_children():
		if child is Level:
			level = child
	var hero: Hero = level.get_node("Hero")
	var spawner: EnemySpawner = level.get_node("EnemySpawner")
	var fortress: Fortress = level.get_node("Fortress")

	# Walk toward the lane, then fight the first ghoul.
	Input.action_press("move_left")
	Input.action_press("move_up")
	await _frames(55)
	await _shot("02_walking")
	Input.action_release("move_left")
	Input.action_release("move_up")
	var ghoul: Enemy = spawner.get_child(0)
	while is_instance_valid(ghoul) and hero.global_position.distance_to(ghoul.global_position) > 70.0:
		await _frames(1)
	hero.attack(ghoul.global_position)
	await _frames(3)
	await _shot("03_swing_and_hit")
	await _frames(25)
	hero.attack(ghoul.global_position)
	await _frames(26)
	hero.attack(ghoul.global_position)
	await _frames(4)
	await _shot("04_death_effect")

	# The fortress: damaged, then destroyed (Game Over).
	hero.position = Vector2(-40, 110)
	fortress.health.take_damage(55)
	await _frames(40)
	await _shot("05_fortress_damaged")
	fortress.health.take_damage(100)
	await _frames(20)
	await _shot("06_game_over")
	quit()


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path: String = ProjectSettings.globalize_path(_out_dir.path_join(shot_name + ".png"))
	root.get_texture().get_image().save_png(path)
	print("saved ", path)


func _frames(count: int) -> void:
	for _i: int in count:
		await process_frame
