extends SceneTree
## Spawns the given enemies on a level's lanes and saves screenshots of them walking (dev aid for the art pass):
##   godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/tools/enemy_parade.gd -- --level=res://levels/ashen_keep.tscn
##     --enemies=siege_ram,black_knight --out=dev_screenshots/parade [--seconds=4]
## One enemy of each id on lane (index mod the lane count), a second apart; the camera follows the hero, who is put on the first enemy.

var _level_path: String = "res://levels/prototype_arena.tscn"
var _out: String = "dev_screenshots/parade"
var _ids: PackedStringArray = []
var _seconds: float = 4.0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			_level_path = arg.trim_prefix("--level=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--enemies="):
			_ids = arg.trim_prefix("--enemies=").split(",")
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
	var out_dir: String = _out if _out.is_absolute_path() else ProjectSettings.globalize_path("res://" + _out)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var level: Level = (load(_level_path) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new(), WaveData.new()]
	WaveFixtures.no_upgrades(level)
	root.add_child(level)
	await process_frame
	await process_frame
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	(level.get_node("Fortress") as Fortress).health.setup(100000)
	var spawned: Array[Enemy] = []
	for i: int in _ids.size():
		var data: EnemyData = load("res://data/enemies/%s.tres" % _ids[i])
		var enemy: Enemy = spawner.spawn_extra(data, i % spawner.lanes.size())
		spawned.append(enemy)
		for _f: int in 40:
			await process_frame
	for _f: int in roundi(_seconds * 60.0):
		await process_frame
	var hero: Node2D = level.get_node("Hero")
	var shot: int = 0
	for enemy: Enemy in spawned:
		if not is_instance_valid(enemy):
			continue
		hero.global_position = enemy.global_position
		for _f: int in 20:
			await process_frame
		var path: String = out_dir.path_join("%02d_%s.png" % [shot, _ids[spawned.find(enemy)]])
		root.get_viewport().get_texture().get_image().save_png(path)
		print("saved ", path)
		shot += 1
	quit()
