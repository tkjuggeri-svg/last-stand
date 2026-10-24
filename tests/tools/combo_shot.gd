extends SceneTree
## Saves a screenshot of the build menu's evolution choice with a combo offered (dev aid): an Archer at level 3
## and Twin Banners.
##   godot --path . --resolution 1280x720 --script res://tests/tools/combo_shot.gd -- --out=dev_screenshots/combo.png

func _initialize() -> void:
	var out: String = "dev_screenshots/combo.png"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	var level: Level = (load("res://levels/prototype_arena.tscn") as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	root.add_child(level)
	await process_frame
	level.economy.earn(5000, Economy.Source.KILL)
	var slot: BuildSlot = level.builder.get_slots()[3]
	level.builder.build(slot, level.builder.catalog[0])
	for _i: int in 60:
		await process_frame
	level.builder.upgrade(slot)
	level.builder.upgrade(slot)
	level.modifiers.add_upgrade(load("res://data/relics/twin_banners.tres") as UpgradeData)
	var menu: Node = level.get_node("BuildMenu")
	menu.call("open", slot)
	(level.get_node("Hero") as Node2D).global_position = slot.global_position + Vector2(0, 40)
	for _i: int in 20:
		await process_frame
	var path: String = out if out.is_absolute_path() else ProjectSettings.globalize_path("res://" + out)
	root.get_viewport().get_texture().get_image().save_png(path)
	print("saved ", path, " menu open: ", menu.call("get_slot") == slot)
	quit()
