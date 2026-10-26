extends SceneTree
## Saves one zoomed-out screenshot of each level (dev aid for placing slots and props):
##   godot --path . --resolution 1920x1080 --script res://tests/tools/level_overview.gd -- --out=dev_screenshots/overview [--levels=a,b]
## The camera is pulled back so the whole arena shows, slots and lanes included.

const LEVELS: Array[String] = ["prototype_arena", "drowned_marsh", "ember_orchard", "bone_quarry", "frostbound_pass", "gloam_wood", "ashen_keep", "sunless_mines", "pale_cathedral"]

var _out: String = "dev_screenshots/overview"


func _initialize() -> void:
	var only: PackedStringArray = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--levels="):
			only = arg.trim_prefix("--levels=").split(",")
	var out_dir: String = _out if _out.is_absolute_path() else ProjectSettings.globalize_path("res://" + _out)
	DirAccess.make_dir_recursive_absolute(out_dir)
	for id: String in LEVELS:
		if not only.is_empty() and not only.has(id):
			continue
		var level: Level = (load("res://levels/%s.tscn" % id) as PackedScene).instantiate()
		(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new(), WaveData.new()]
		root.add_child(level)
		await process_frame
		await process_frame
		var floor_rect: ColorRect = level.get_node("%Floor")
		var centre: Vector2 = floor_rect.position + floor_rect.size / 2.0
		var camera: Camera2D = level.get_node("Hero/Camera2D")
		camera.limit_left = -100000
		camera.limit_right = 100000
		camera.limit_top = -100000
		camera.limit_bottom = 100000
		camera.position_smoothing_enabled = false
		var zoom: float = minf(1280.0 / floor_rect.size.x, 720.0 / floor_rect.size.y) * 0.96
		camera.zoom = Vector2(zoom, zoom)
		(level.get_node("Hero") as Node2D).global_position = centre
		for _f: int in 20:
			await process_frame
		var path: String = out_dir.path_join("%s.png" % id)
		root.get_viewport().get_texture().get_image().save_png(path)
		print("saved ", path, " (%d slots)" % level.builder.get_slots().size())
		level.queue_free()
		await process_frame
	quit()
