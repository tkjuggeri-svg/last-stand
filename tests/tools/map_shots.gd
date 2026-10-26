extends SceneTree
## Screenshots of the run map of every chapter (M13: the map's art pass) in a real window: its ground, roads,
## frames and weather, with the first two nodes of a path visited.
## godot --path . --resolution 1280x720 --script res://tests/tools/map_shots.gd -- --out=<dir>

const RUN: RunData = preload("res://data/run/run.tres")


func _initialize() -> void:
	var out: String = "user://map_shots"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	var screen: MapScreen = (load("res://ui/map/map_screen.tscn") as PackedScene).instantiate()
	root.add_child(screen)
	await process_frame
	for chapter: ChapterData in _all_chapters():
		var map: RunMap = RunMap.generate(chapter, 11)
		for _step: int in 2:
			map.visit(map.get_choices()[0])
		screen.open(map, chapter.display_name, "Gold 240    Fortress 100 / 100    Lives 3")
		for _i: int in 90:
			await process_frame
		var image: Image = root.get_texture().get_image()
		image.save_png("%s/map_%s.png" % [out, chapter.id])
		print("saved ", chapter.id)
	quit()


## Every biome of every tier, once.
func _all_chapters() -> Array[ChapterData]:
	var found: Array[ChapterData] = []
	for tier: int in range(1, RUN.tier_count() + 1):
		for chapter: ChapterData in RUN.biomes_of_tier(tier):
			if not found.has(chapter):
				found.append(chapter)
	return found
