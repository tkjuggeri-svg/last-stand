extends SceneTree
## Screenshots of every War Room page (Heroes, Unlocks, Council, Records) and the story boxes (a hero's, a
## character's), on a throwaway save with shards, unlocks and a finished run so every page has content.
## godot --path . --resolution 1280x720 --script res://tests/tools/hub_pages_shots.gd -- --out=<dir> [--tag=720p]

const SAVE_PATH: String = "user://shots_save.json"

var _out: String = "user://shots"
var _tag: String = ""


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=") + "_"
	DirAccess.make_dir_recursive_absolute(_out)
	await process_frame
	var save: SaveManagerNode = root.get_node("/root/SaveManager")
	save.use_file(SAVE_PATH)
	save.reset_profile()
	save.profile.shards = 180
	save.profile.unlocks = ["brazier", "cards_precision", "evolutions_archer", "relics_1", "hero_necromancer"]
	save.profile.runs = 6
	save.profile.best_chapter = 2
	save.profile.best_row = 6
	save.profile.bosses = ["The Lich Warden", "The Tollkeeper"]
	save.profile.history.append({"result": "lost", "chapter": 2, "row": 6})
	save.save_profile()
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _settle()
	var front: FrontEnd = main.get_node("%FrontEnd")
	front.show_hub()
	await _settle()
	var hub: HubScreen = front.get_hub()
	for page: int in HubScreen.Page.size():
		hub.show_page(page)
		await _settle()
		await _shot("page_%s" % HubScreen.Page.keys()[page].to_lower())
	hub.show_page(HubScreen.Page.HEROES)
	hub.get_hero_story_button().pressed.emit()
	await _settle()
	await _shot("story_hero")
	hub.get_story_dialog().hide()
	hub.show_page(HubScreen.Page.COUNCIL)
	var listen: Button = hub.get_listen_button(&"quartermaster")
	if listen != null:
		listen.pressed.emit()
		await _settle()
		await _shot("story_character")
		hub.get_story_dialog().hide()
	save.reset_profile()
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH + suffix))
	quit()


func _settle() -> void:
	for _i: int in 40:
		await process_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(_tag + shot_name + ".png"))
	print("saved ", _tag + shot_name)
