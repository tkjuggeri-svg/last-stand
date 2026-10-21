extends SceneTree
## Screenshots of the front-end screens (M8) in a real window: the title, the War Room (fresh, and with
## shards and some unlocks), the run summary. Uses a throwaway save.
## godot --path . --resolution 1280x720 --script res://tests/tools/front_end_shots.gd -- --out=<dir>

const SAVE_PATH: String = "user://shots_save.json"

var _out: String = "user://shots"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out)
	await process_frame
	var save: SaveManagerNode = root.get_node("/root/SaveManager")
	save.use_file(SAVE_PATH)
	save.reset_profile()
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _settle()
	await _shot("title")
	var front: FrontEnd = main.get_node("%FrontEnd")
	front.show_hub()
	await _settle()
	await _shot("hub_fresh")
	save.profile.shards = 180
	save.profile.unlocks = ["brazier", "cards_precision", "evolutions_archer", "relics_1"]
	save.profile.runs = 6
	save.profile.best_chapter = 1
	save.profile.best_row = 8
	save.profile.bosses = ["The Lich Warden"]
	save.profile.history.append({"result": "lost", "chapter": 2, "row": 3})
	save.save_profile()
	await _settle()
	await _shot("hub_later")
	front.show_summary({"result": "lost", "chapter": 1, "row": 6, "seed": 1234, "path": ["battle", "battle", "elite", "merchant", "battle"],
		"kills": 212, "waves": 9, "minutes": 7.5, "cards": ["berserker", "battle_rhythm"], "relics": ["hourglass"],
		"shard_lines": [["4 battles won", 8], ["1 elite beaten", 6]], "shards": 14})
	await _settle()
	await _shot("summary")
	save.reset_profile()
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH + suffix))
	quit()


func _settle() -> void:
	for _i: int in 40:
		await process_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(shot_name + ".png"))
	print("saved ", shot_name)
