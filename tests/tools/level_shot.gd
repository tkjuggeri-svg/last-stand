extends SceneTree
## Saves screenshots of a level (dev aid): the camera on a few points of the arena, with a wave
## running so enemies walk the lanes.
##   godot --path . --resolution 1280x720 --script res://tests/tools/level_shot.gd -- --level=res://levels/drowned_marsh.tscn --out=dev_screenshots/x
##     [--at=-400,-100;200,-200] [--seconds=12] [--wave=6]

var _level_path: String = "res://levels/drowned_marsh.tscn"
var _out: String = "dev_screenshots"
var _points: Array[Vector2] = [Vector2(-400, -150), Vector2(250, -250), Vector2(-350, 250), Vector2(0, 0)]
var _seconds: float = 12.0
## The level's wave to play (1-based).
var _wave: int = 1


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			_level_path = arg.trim_prefix("--level=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--wave="):
			_wave = int(arg.trim_prefix("--wave="))
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--at="):
			_points.clear()
			for pair: String in arg.trim_prefix("--at=").split(";"):
				var xy: PackedStringArray = pair.split(",")
				_points.append(Vector2(float(xy[0]), float(xy[1])))
	# A relative --out is under the project (dev_screenshots/...); an absolute one is used as it is.
	var out_dir: String = _out if _out.is_absolute_path() else ProjectSettings.globalize_path("res://" + _out)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var level: Level = (load(_level_path) as PackedScene).instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = spawner.waves.slice(_wave - 1)
	root.add_child(level)
	await process_frame
	(level.get_node("%RunCycle") as RunCycle).start_wave()
	for _i: int in roundi(_seconds * 60.0):
		await process_frame
	var hero: Node2D = level.get_node("Hero")
	for i: int in _points.size():
		hero.global_position = _points[i]
		for _f: int in 30:
			await process_frame
		var path: String = out_dir.path_join("%s_%d.png" % [_level_path.get_file().get_basename(), i])
		root.get_viewport().get_texture().get_image().save_png(path)
		print("saved ", path)
	quit()
