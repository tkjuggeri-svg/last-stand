extends SceneTree
## Screenshots of every screen of the game in a real window (M8.5's UI consistency pass and later
## reviews): the map, the HUD (build and combat), the build menu (empty slot, a tower), the upgrade
## choice, the merchant, an event, the pause menu, the settings, the chapter screen, Game Over,
## Victory, the feedback box, the title, the War Room, the run summary and a tip.
## godot --path . --resolution 1280x720 --script res://tests/tools/ui_shots.gd -- --out=<dir> [--only=map,pause,...]
## [--grayscale] also saves a grayscale copy of each shot (<name>_gray.png).

const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const SAVE_PATH: String = "user://ui_shots_save.json"

var _out: String = "user://ui_shots"
var _only: PackedStringArray = []
var _gray: bool = false
var _main: Node


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",")
		elif arg == "--grayscale":
			_gray = true
	DirAccess.make_dir_recursive_absolute(_out)
	_main = (load("res://main/main.tscn") as PackedScene).instantiate()
	_main.set("run_seed", 7)
	root.add_child(_main)
	await _settle(30)
	await _shot("map")
	var level: Level = await MapFixtures.enter_first_battle(_main)
	level.economy.earn(2000, Economy.Source.REFUND)
	var hero: Node2D = level.get_node("Hero")
	var slot: BuildSlot = level.builder.get_slots()[3]
	hero.global_position = slot.global_position + Vector2(0, 40)
	await _settle(20)
	await _shot("hud_build")
	var menu: Node = level.get_node("BuildMenu")
	menu.call("open", slot)
	await _settle(10)
	await _shot("build_menu_empty")
	level.builder.build(slot, ARCHER)
	await _settle(60)
	level.builder.upgrade(slot)
	menu.call("open", slot)
	await _settle(10)
	await _shot("build_menu_tower")
	menu.call("close")
	level.run_cycle.start_wave()
	await _settle(240)
	await _shot("hud_combat")
	level.spawner.end_wave()
	for _i: int in 600:
		if level.offers.is_offer_open():
			break
		if level.run_cycle.get_phase() == RunCycle.Phase.BUILD:
			level.run_cycle.start_wave()
			await _settle(5)
			level.spawner.end_wave()
		await physics_frame
	await _settle(20)
	await _shot("upgrade_choice")
	level.offers.pick(0)
	await _settle(10)
	await _jump(RunMap.Kind.MERCHANT, "merchant")
	(_main.get_node("%MerchantScreen") as CanvasLayer).hide()
	await _jump(RunMap.Kind.EVENT, "event")
	(_main.get_node("%EventScreen") as CanvasLayer).hide()
	(_main.get_node("%MapFlow") as MapFlow).show_map()
	var pause: PauseMenu = _main.get_node("%PauseMenu")
	pause.show_seed(7)
	pause.open()
	await _settle(10, true)
	await _shot("pause")
	pause.get_node("%SettingsButton").emit_signal("pressed")
	await _settle(10, true)
	await _shot("settings")
	pause.close()
	await _settle(5)
	var carry: ChapterCarry = level.carry_out(0.4)
	(_main.get_node("%ChapterScreen") as ChapterScreen).open("The Crypt Road", "The Drowned Marsh", carry, 0.4, 0.5, 80, 100)
	await _settle(10)
	await _shot("chapter")
	(_main.get_node("%ChapterScreen") as CanvasLayer).hide()
	(_main.get_node("%GameOverScreen") as GameOverScreen).open("The fortress has fallen.", 7)
	await _settle(10)
	await _shot("game_over")
	(_main.get_node("%GameOverScreen") as CanvasLayer).hide()
	(_main.get_node("%VictoryScreen") as VictoryScreen).open("The fortress stands. Every chapter held.", 7)
	await _settle(10)
	await _shot("victory")
	(_main.get_node("%VictoryScreen") as CanvasLayer).hide()
	var feedback: FeedbackScreen = _main.get_node("%FeedbackScreen")
	feedback.open()
	await _settle(10, true)
	await _shot("feedback")
	feedback.close()
	await _settle(5)
	await _front_end()
	(_main.get_node("%HintPanel") as HintPanel).show_hint(&"map", HintDirector.HINTS[&"map"])
	(_main.get_node("%MapFlow") as MapFlow).show_map()
	await _settle(10)
	await _shot("hint")
	quit()


func _front_end() -> void:
	var save: SaveManagerNode = root.get_node("/root/SaveManager") as SaveManagerNode
	save.use_file(SAVE_PATH)
	save.reset_profile()
	save.profile.shards = 140
	save.profile.unlocks = ["brazier", "evolutions_archer"]
	save.profile.runs = 4
	save.profile.best_chapter = 1
	save.profile.best_row = 7
	save.profile.history.append({"result": "lost", "chapter": 1, "row": 7})
	var front: FrontEnd = _main.get_node("%FrontEnd")
	front.show_title()
	await _settle(30)
	await _shot("title")
	front.show_hub()
	await _settle(10)
	await _shot("hub")
	front.show_summary({"result": "lost", "chapter": 1, "row": 6, "seed": 7, "path": ["battle", "battle", "elite", "merchant", "battle"],
		"kills": 212, "waves": 9, "minutes": 7.5, "cards": ["berserker", "battle_rhythm"], "relics": ["hourglass"],
		"shard_lines": [["4 battles won", 12], ["1 elite beaten", 8]], "shards": 20})
	await _settle(30)
	await _shot("summary")
	front.hide_all()
	save.reset_profile()
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH + suffix))


## Plays the map's first node of `kind` (the dev menu's jump) and shoots it.
func _jump(kind: RunMap.Kind, shot_name: String) -> void:
	var map: RunMap = _main.call("get_map")
	for node: MapNode in map.nodes:
		if node.kind == kind:
			_main.call("jump_to_node", node)
			await _settle(15)
			await _shot(shot_name)
			return


## Lets `frames` frames pass (process frames while the tree is paused, as the pause menu does).
func _settle(frames: int, while_paused: bool = false) -> void:
	for _i: int in frames:
		await (process_frame if while_paused else physics_frame)


func _shot(shot_name: String) -> void:
	if not _only.is_empty() and not _only.has(shot_name):
		return
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png(_out.path_join(shot_name + ".png"))
	if _gray:
		Grayscale.convert(image).save_png(_out.path_join(shot_name + "_gray.png"))
	print("saved ", shot_name)
