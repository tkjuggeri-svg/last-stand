extends SceneTree
## The vector knight (vector-test) next to the pixel knight in the real arena, both real Hero scenes fed by the same scripted
## input (so movement, dash and attack timing are the same for both): idle, walk left / down / up, three swings, a dash.
## godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/tools/vector_compare.gd -- --out=exports/vector-test [--no-shots]
## Video: add  --write-movie exports/vector-test/vector_vs_pixel.avi  before --script (the shots are then skipped with --no-shots).

const ARENA: String = "res://levels/prototype_arena.tscn"
const ZOOM: float = 2.0
## Where the pixel knight stands beside the vector one (world px).
const BESIDE: Vector2 = Vector2(-70, 0)

var _out: String = "exports/vector-test"
var _shots: bool = true


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg == "--no-shots":
			_shots = false
	await process_frame
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	root.add_child(level)
	var vector_hero: Hero = level.get_node("Hero")
	var pixel_hero: Hero = (load("res://entities/hero/hero.tscn") as PackedScene).instantiate()
	pixel_hero.position = vector_hero.position + BESIDE
	level.add_child(pixel_hero)
	await _frames(2)
	(pixel_hero.get_node("%VectorRig") as HeroVectorRig).enabled = false
	_caption("left: current pixel knight      right: vector knight (Skeleton2D rig)")
	var camera: Camera2D = vector_hero.get_viewport().get_camera_2d()
	camera.zoom = Vector2(ZOOM, ZOOM)
	camera.position_smoothing_enabled = false
	# The camera follows the vector knight: look between the two.
	camera.offset = BESIDE / 2.0
	await _frames(60)
	await _shot("idle", _shots)
	await _walk("move_left", 90, "walk", _shots)
	await _walk("move_down", 90, "", false)
	await _walk("move_up", 90, "", false)
	for aim: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN]:
		await _swing(vector_hero, pixel_hero, aim, _shots and aim == Vector2.RIGHT)
		await _frames(40)
	Input.action_press("move_left")
	Input.action_press("dash")
	await _frames(2)
	Input.action_release("dash")
	await _frames(3)
	await _shot("dash", _shots)
	await _frames(20)
	Input.action_release("move_left")
	await _frames(60)
	quit()


func _walk(action: String, frames: int, shot_name: String, shoot: bool) -> void:
	Input.action_press(action)
	var half: int = floori(frames / 2.0)
	await _frames(half)
	if shoot:
		await _shot(shot_name, true)
	await _frames(frames - half)
	Input.action_release(action)
	await _frames(10)


## Both knights swing toward `aim` on the same frame; the shot is taken a few frames in.
func _swing(vector_hero: Hero, pixel_hero: Hero, aim: Vector2, shoot: bool) -> void:
	vector_hero.attack(vector_hero.global_position + aim * 100.0)
	pixel_hero.attack(pixel_hero.global_position + aim * 100.0)
	for step: int in 3:
		await _frames(3)
		if shoot:
			await _shot("attack_%d" % (step + 1), true)
	await _frames(20)


## One line of text at the top of the screen (for the comparison shots and the video).
func _caption(text: String) -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100
	var label: Label = Label.new()
	label.text = text
	label.position = Vector2(330, 24)
	layer.add_child(label)
	root.add_child(layer)


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _shot(shot_name: String, shoot: bool) -> void:
	if not shoot:
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://%s/%s.png" % [_out, shot_name]))
	print("saved ", shot_name)
