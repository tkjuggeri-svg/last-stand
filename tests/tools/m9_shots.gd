extends SceneTree
## Saves screenshots of the M9 content (dev aid): the Huntress in a fight with her towers built (Trap
## Layer, Hawk Perch, Watchtower, an Archer), at game scale and in the build menu.
##   godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/tools/m9_shots.gd -- --out=dev_screenshots/m9 [--wave=5]

const ARENA: String = "res://levels/prototype_arena.tscn"
const HUNTRESS: HeroData = preload("res://data/heroes/huntress.tres")
const KNIGHT: HeroData = preload("res://data/heroes/knight.tres")
const TOWERS: Array[Array] = [["archer", 4], ["hawk_perch", 9], ["trap_layer", 7], ["watchtower", 8], ["hawk_perch", 2], ["trap_layer", 6]]

var _out: String = "dev_screenshots/m9"
var _wave: int = 5


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--wave="):
			_wave = int(arg.trim_prefix("--wave="))
	var out_dir: String = _out if _out.is_absolute_path() else ProjectSettings.globalize_path("res://" + _out)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var hero: Hero = level.get_node("Hero")
	hero.data = HUNTRESS
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = spawner.waves.slice(_wave - 1)
	root.add_child(level)
	await process_frame
	level.apply_hero(HUNTRESS, [KNIGHT, HUNTRESS])
	level.economy.earn(5000, Economy.Source.KILL)
	for entry: Array in TOWERS:
		for data: TowerData in level.builder.catalog:
			if String(data.id) == entry[0]:
				level.builder.build(level.builder.get_slots()[entry[1]], data)
	for _i: int in 90:
		await process_frame
	for slot: BuildSlot in level.builder.get_slots():
		if slot.tower != null and slot.tower.data.kind != TowerData.Kind.SHOOTER or slot.tower != null and slot.tower.data.id == &"hawk_perch":
			level.builder.upgrade(slot)
	(level.get_node("%RunCycle") as RunCycle).start_wave()
	hero.global_position = Vector2(-150, 60)
	for i: int in 4:
		for _f: int in 360:
			var target: Enemy = null
			for child: Node in spawner.get_children():
				if child is Enemy and (child as Enemy).is_alive():
					target = child
					break
			if target != null:
				hero.attack(target.global_position)
			await process_frame
		var path: String = out_dir.path_join("huntress_fight_%d.png" % i)
		root.get_viewport().get_texture().get_image().save_png(path)
		print("saved ", path)
	quit()
