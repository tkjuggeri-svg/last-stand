extends SceneTree
## Plays a short scripted scene in the real game window and saves screenshots, for visual review.
## Needs a display (not --headless):
##   godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/tools/capture_screenshots.gd -- --out=/some/dir [--scenario=combat]
## Scenarios: "tour" (default: walk, swing, kill, damaged fortress, Game Over), "combat" (a ghoul fights
## the hero to death) and "build" (towers on slots, the build menu, towers fighting a wave).

var _out_dir: String = "user://screenshots"
var _scenario: String = "tour"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--scenario="):
			_scenario = arg.trim_prefix("--scenario=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(60)
	var level: Level = null
	for child: Node in main.get_children():
		if child is Level:
			level = child
	if _scenario == "combat":
		await _combat(level)
		quit()
		return
	if _scenario == "build":
		await _build(level)
		quit()
		return
	await _shot("01_start")

	var hero: Hero = level.get_node("Hero")
	var spawner: EnemySpawner = level.get_node("EnemySpawner")
	var fortress: Fortress = level.get_node("Fortress")

	# Walk toward the lane, then fight the first ghoul.
	Input.action_press("move_left")
	Input.action_press("move_up")
	await _frames(55)
	await _shot("02_walking")
	Input.action_release("move_left")
	Input.action_release("move_up")
	var ghoul: Enemy = spawner.get_child(0)
	while is_instance_valid(ghoul) and hero.global_position.distance_to(ghoul.global_position) > 70.0:
		await _frames(1)
	hero.attack(ghoul.global_position)
	await _frames(3)
	await _shot("03_swing_and_hit")
	await _frames(25)
	hero.attack(ghoul.global_position)
	await _frames(26)
	hero.attack(ghoul.global_position)
	await _frames(4)
	await _shot("04_death_effect")

	# The fortress: damaged, then destroyed (Game Over).
	hero.position = Vector2(-40, 110)
	fortress.health.take_damage(55)
	await _frames(40)
	await _shot("05_fortress_damaged")
	fortress.health.take_damage(100)
	await _frames(20)
	await _shot("06_game_over")
	quit()


## The hero stands on the lane; the first ghoul stops, winds up and strikes until the hero falls.
func _combat(level: Level) -> void:
	var hero: Hero = level.get_node("Hero")
	var ghoul: Enemy = (level.get_node("EnemySpawner") as EnemySpawner).get_child(0)
	hero.position = Vector2(-560, -250)
	hero.health.take_damage(60)  # start low so the whole fight fits in a few seconds
	var started: Array[bool] = [false]
	ghoul.attack_started.connect(func(_e: Enemy) -> void: started[0] = true)
	while not started[0]:
		await _frames(1)
	await _frames(12)
	await _shot("combat_01_windup")
	await _frames(12)
	await _shot("combat_02_hit")
	while not hero.health.is_dead():
		await _frames(1)
	await _frames(2)
	await _shot("combat_03_hero_falls")
	await _frames(40)
	await _shot("combat_04_game_over")


## Builds one tower of each kind, opens the menu at an empty slot, then lets the towers fight.
func _build(level: Level) -> void:
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var economy: Economy = level.get_node("%Economy")
	var hero: Hero = level.get_node("Hero")
	var slots: Array[BuildSlot] = builder.get_slots()
	economy.earn(300, Economy.Source.KILL)
	builder.build(slots[0], builder.catalog[0])
	builder.build(slots[3], builder.catalog[1])
	builder.build(slots[2], builder.catalog[2])
	hero.position = slots[1].position + Vector2(0, 44)
	await _frames(30)
	var press: InputEventAction = InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	Input.parse_input_event(press)
	await _frames(20)
	await _shot("build_01_menu")
	hero.position = Vector2(-470, 40)  # off the lane, close enough for the camera to frame the fight
	await _frames(240)
	await _shot("build_02_towers_fighting")
	# Wait for the moments worth seeing: a cannon blast, a frozen ghoul, a gold popup.
	var wanted: Dictionary = {"build_03_explosion": "Explosion", "build_04_frost_slow": "slowed", "build_05_gold_popup": "DamageNumber"}
	for _i: int in 1800:
		await _frames(1)
		for shot_name: String in wanted.keys():
			if _level_shows(level, wanted[shot_name]):
				await _shot(shot_name)
				wanted.erase(shot_name)
		if wanted.is_empty():
			break


func _level_shows(level: Level, what: String) -> bool:
	if what == "slowed":
		return (level.get_node("EnemySpawner") as Node).get_children().any(func(e: Node) -> bool: return (e as Enemy).is_slowed())
	return not level.find_children("*", what, true, false).is_empty()


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path: String = ProjectSettings.globalize_path(_out_dir.path_join(shot_name + ".png"))
	root.get_texture().get_image().save_png(path)
	print("saved ", path)


func _frames(count: int) -> void:
	for _i: int in count:
		await process_frame
