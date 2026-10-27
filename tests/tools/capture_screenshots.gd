extends SceneTree
## Plays a short scripted scene in the real game window and saves screenshots, for visual review.
## Needs a display (not --headless):
##   godot --path . --resolution 1280x720 --fixed-fps 60 --script res://tests/tools/capture_screenshots.gd -- --out=/some/dir [--scenario=combat]
## Scenarios: "tour" (default: walk, swing, kill, damaged fortress, Game Over), "combat" (a ghoul fights
## the hero to death), "build" (towers on slots, the build menu, towers fighting a wave) and "gallery"
## (every animation of the given SpriteFrames side by side at game scale, over the real level;
## --frames=res://a.tres,res://b.tres picks the sheets, default: hero and ghoul) and "review" (the
## milestone review set: whole battlefield, hero vs ghoul close up, the three towers, construction and
## dismantling, the fortress's damage states, build menu and HUD) and "run" (a late wave with every
## enemy type on several lanes, then the Victory screen) and "m5" (the upgrade choice screen, the HUD's
## upgrade row, a Long Reach swing, the Brazier's fire, a Ballista bolt, the 5-tower build menu) and
## "m6" (M6 content, see m6_shots.gd; --only=dash,... picks parts).
## --grayscale also saves a grayscale copy of every shot (<name>_gray.png, M8.5's readability check:
## the hero, enemies, towers and shots must still stand out from the ground without colour).

const M6Shots: GDScript = preload("res://tests/tools/m6_shots.gd")
const M7Shots: GDScript = preload("res://tests/tools/m7_shots.gd")

var _out_dir: String = "user://screenshots"
var _scenario: String = "tour"
var _only: PackedStringArray = PackedStringArray()
var _grayscale: bool = false


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--scenario="):
			_scenario = arg.trim_prefix("--scenario=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",")
		elif arg == "--grayscale":
			_grayscale = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(60)
	if _scenario == "m7":
		await M7Shots.new(self, _only).run(main)
		quit()
		return
	# Every run starts on the map: the scenarios below play the first battle's level.
	var level: Level = await MapFixtures.enter_first_battle(main)
	await _frames(2)
	if _scenario == "run":
		await _run(level)
		quit()
		return
	if _scenario == "m6":
		await M6Shots.new(self, _only).run(level)
		quit()
		return
	if _scenario == "m5":
		await _m5(level)
		quit()
		return
	# Runs start in the build phase; the review set shows it, then every scenario starts wave 1.
	if _scenario == "review":
		await _shot("00_build_phase")
	await WaveFixtures.start_wave(level)
	await _frames(2)
	if _scenario == "combat":
		await _combat(level)
		quit()
		return
	if _scenario == "build":
		await _build(level)
		quit()
		return
	if _scenario == "gallery":
		await _gallery(level)
		quit()
		return
	if _scenario == "review":
		await _review(level)
		quit()
		return
	await _shot("01_start")

	var hero: Hero = level.get_node("Hero")
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
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
	var ghoul: Enemy = (level.get_node("WaveSpawner") as WaveSpawner).get_child(0)
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
	# The sell view: stand at the archer and open the menu there.
	Input.parse_input_event(press)
	await _frames(5)
	hero.position = slots[0].position + Vector2(0, 44)
	await _frames(20)
	Input.parse_input_event(press)
	await _frames(20)
	await _shot("build_01b_sell")
	Input.parse_input_event(press)
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


## Every animation in a grid near the camera; the level keeps running (lights, fog) but is hidden
## under the grid only where sprites stand. Three shots catch different animation frames.
func _gallery(level: Level) -> void:
	var sheets: PackedStringArray = PackedStringArray(["res://entities/hero/hero_frames.tres", "res://entities/enemies/ghoul_frames.tres"])
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--frames="):
			sheets = arg.trim_prefix("--frames=").split(",")
	(level.get_node("WaveSpawner") as Node).process_mode = Node.PROCESS_MODE_DISABLED
	var hero: Hero = level.get_node("Hero")
	hero.position = Vector2(-500, 150)
	await _frames(30)
	hero.hide()
	var origin: Vector2 = hero.position - Vector2(560, 300)
	var row: int = 0
	for path: String in sheets:
		var frames: SpriteFrames = load(path)
		var column: int = 0
		for anim: StringName in frames.get_animation_names():
			var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
			sprite.sprite_frames = frames
			sprite.scale = Vector2(2, 2)
			sprite.position = origin + Vector2(column * 100 + 50, row * 110 + 60)
			sprite.play(anim)
			sprite.animation_finished.connect(func() -> void: sprite.play(anim))
			level.add_child(sprite)
			column += 1
			if column >= 11:
				column = 0
				row += 1
		row += 1
	for i: int in 3:
		await _frames(7)
		await _shot("gallery_%d" % i)


## The review set, in game order. The camera is lifted off the hero for framed shots and zoomed by
## whole steps only (2 = close-up), except the battlefield, which is shot at 0.5 and scaled back up.
func _review(level: Level) -> void:
	var hero: Hero = level.get_node("Hero")
	var camera: Camera2D = hero.get_node("Camera2D")
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var slots: Array[BuildSlot] = builder.get_slots()
	var fortress: Fortress = level.get_node("Fortress")
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	(level.get_node("%Economy") as Economy).earn(400, Economy.Source.KILL)

	# Hero meets the first ghoul on the lane.
	hero.position = Vector2(-470, -255)
	var ghoul: Enemy = spawner.get_child(0)
	await _frames(5)
	_frame_camera(camera, Vector2.ZERO, 2.0, false)
	while is_instance_valid(ghoul) and hero.global_position.distance_to(ghoul.global_position) > 72.0:
		await _frames(1)
	await _shot("02a_hero_and_ghoul_closeup")
	hero.attack(ghoul.global_position)
	await _frames(3)
	await _shot("02b_hero_strikes_ghoul")
	hero.position = Vector2(-470, -20)

	# Three towers going up; the archer is shot mid-construction, close up.
	builder.build(slots[0], builder.catalog[0])
	builder.build(slots[3], builder.catalog[1])
	builder.build(slots[2], builder.catalog[2])
	_frame_camera(camera, slots[0].position + Vector2(0, -30), 2.0, true)
	await _frames(12)
	await _shot("04a_construction_scaffolding")
	await _frames(12)
	await _shot("04b_construction_almost_done")
	_frame_camera(camera, Vector2(-390, -170), 1.0, true)
	await _frames(150)
	await _shot("03_three_towers")

	# The whole battlefield: zoomed out to 1 screen px per art px, cropped to the arena, scaled 2x.
	level.get_node("HUD").set(&"visible", false)
	_frame_camera(camera, Vector2(-250, -50), 0.5, true)
	await _frames(3)
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var arena: Rect2i = Rect2i(Vector2i(640 - 341, 360 - 241), Vector2i(682, 482))
	image = image.get_region(arena)
	image.resize(arena.size.x * 2, arena.size.y * 2, Image.INTERPOLATE_NEAREST)
	_save(image, "01_battlefield")
	level.get_node("HUD").set(&"visible", true)

	# Selling the frost tower: rubble, close up.
	_frame_camera(camera, slots[3].position + Vector2(0, -30), 2.0, true)
	await _frames(5)
	builder.sell(slots[3])
	await _frames(10)
	await _shot("04c_dismantling")
	await _frames(14)
	await _shot("04d_dismantling_rubble")

	# Build menu and HUD at normal zoom on the hero.
	_frame_camera(camera, Vector2.ZERO, 1.0, false)
	hero.position = slots[1].position + Vector2(0, 44)
	await _frames(30)
	_press_interact()
	await _frames(20)
	await _shot("06a_build_menu_and_hud")
	_press_interact()
	hero.position = slots[0].position + Vector2(0, 44)
	await _frames(30)
	_press_interact()
	await _frames(20)
	await _shot("06b_sell_menu_and_hud")
	_press_interact()

	# The hero falls: a countdown at the respawn point by the fortress, then it is back.
	hero.health.take_damage(1000)
	_frame_camera(camera, (level.get_node("RespawnPoint") as Node2D).position + Vector2(0, -60), 1.0, true)
	await _frames(90)
	await _shot("07_hero_respawn_countdown")

	# Fortress damage states.
	_frame_camera(camera, Vector2(0, -40), 2.0, true)
	fortress.health.take_damage(fortress.health.current_health - 55)
	await _frames(40)
	await _shot("05a_fortress_damaged")
	fortress.health.take_damage(fortress.health.current_health - 25)
	await _frames(40)
	await _shot("05b_fortress_badly_damaged")
	fortress.health.take_damage(fortress.health.current_health)
	await _frames(40)
	await _shot("05c_fortress_destroyed_game_over")


## Jumps to wave 8 with towers on every slot, frames the fight, then wins a short run for the Victory screen.
func _run(level: Level) -> void:
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var hero: Hero = level.get_node("Hero")
	var camera: Camera2D = hero.get_node("Camera2D")
	(level.get_node("%Economy") as Economy).earn(2000, Economy.Source.KILL)
	var kinds: Array[int] = [0, 2, 0, 1, 0, 2, 0, 2, 0, 1]
	for i: int in builder.get_slots().size():
		builder.build(builder.get_slots()[i], builder.catalog[kinds[i % kinds.size()]])
	spawner.waves = spawner.waves.slice(7, 8)
	hero.position = Vector2(-140, 40)
	await WaveFixtures.start_wave(level)
	_frame_camera(camera, Vector2(-120, -40), 1.0, true)
	for second: int in [12, 22, 32]:
		await _frames(600)  # ~10 s between shots
		await _shot("run_wave8_%02ds" % second)
	_frame_camera(camera, Vector2(-250, -50), 0.5, true)
	level.get_node("HUD").set(&"visible", false)
	await _frames(3)
	await _shot("run_wave8_battlefield")
	level.get_node("HUD").set(&"visible", true)
	# Victory (a run is won by its last boss; here the screen is shown on the frozen level).
	level.end_run_won()
	(level.get_parent().get_node("%VictoryScreen") as VictoryScreen).open("The fortress stands. Every chapter held.")
	_frame_camera(camera, Vector2.ZERO, 1.0, false)
	await _frames(30)
	await _shot("run_victory")


## The M5 review set: the choice screen after a real wave, the upgrades in the HUD, the longer swing
## trail, the new towers in a fight (close up) and the 5-tower build menu.
func _m5(level: Level) -> void:
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var offers: UpgradeOffers = level.get_node("%UpgradeOffers")
	var mods: RunModifiers = level.get_node("%RunModifiers")
	var cycle: RunCycle = level.get_node("%RunCycle")
	var hero: Hero = level.get_node("Hero")
	var camera: Camera2D = hero.get_node("Camera2D")
	(level.get_node("%Economy") as Economy).earn(2000, Economy.Source.KILL)
	offers.set_seed(3)
	spawner.waves = [WaveFixtures.make_wave(2, 0.5), spawner.waves[5], WaveData.new()]
	spawner.enemy_spawned.connect(func(e: Enemy) -> void:
		if spawner.get_wave_number() == 1:
			(e.get_node("%HealthComponent") as HealthComponent).take_damage.call_deferred(1000))
	cycle.start_wave()
	for _i: int in 600:
		await _frames(1)
		if cycle.get_phase() == RunCycle.Phase.CHOOSE:
			break
	await _frames(20)
	await _shot("m5_01_choice_screen")
	offers.pick(0)
	await _frames(5)
	# A few more upgrades for the HUD row, two stacks of Long Reach for the trail.
	for id: String in ["long_reach", "long_reach", "honed_blade", "masonry", "bounty", "hellfire"]:
		mods.add_upgrade(load("res://data/upgrades/%s.tres" % id))
	await _frames(10)
	await _shot("m5_02_hud_upgrade_row")
	_frame_camera(camera, Vector2.ZERO, 2.0, false)
	await _frames(10)
	hero.attack(hero.global_position + Vector2(60, 10))
	await _frames(3)
	await _shot("m5_03_long_reach_swing")
	# The new towers along the west road, one of each at level 1 and level 3.
	_frame_camera(camera, Vector2.ZERO, 1.0, false)
	builder.build(builder.get_slots()[0], builder.catalog[3])
	builder.build(builder.get_slots()[3], builder.catalog[3])
	builder.build(builder.get_slots()[2], builder.catalog[4])
	builder.build(builder.get_slots()[1], builder.catalog[4])
	await _frames(60)
	for slot: int in [3, 1]:
		builder.upgrade(builder.get_slots()[slot])
		builder.upgrade(builder.get_slots()[slot])
	hero.position = Vector2(-470, 30)
	cycle.start_wave()
	_frame_camera(camera, builder.get_slots()[0].position + Vector2(40, -40), 2.0, true)
	for _i: int in 900:
		await _frames(1)
		if not level.find_children("*", "BurnZone", true, false).is_empty() and _i > 300:
			break
	await _shot("m5_04_brazier_fire")
	_frame_camera(camera, builder.get_slots()[2].position + Vector2(-60, -40), 2.0, true)
	for _i: int in 900:
		await _frames(1)
		var bolts: Array = builder.get_slots()[2].tower.get_children().filter(func(c: Node) -> bool: return c is Projectile)
		if not bolts.is_empty() and (bolts[0] as Node2D).global_position.distance_to(builder.get_slots()[2].position) > 60.0:
			break
	await _shot("m5_05_ballista_bolt")
	_frame_camera(camera, Vector2.ZERO, 1.0, false)
	hero.position = builder.get_slots()[5].position + Vector2(0, 44)
	await _frames(30)
	_press_interact()
	await _frames(20)
	await _shot("m5_06_build_menu_five_towers")


## Detached: the camera holds `at`; attached: it follows the hero again.
func _frame_camera(camera: Camera2D, at: Vector2, zoom: float, detached: bool) -> void:
	camera.top_level = detached
	camera.position = at if detached else Vector2.ZERO
	camera.zoom = Vector2(zoom, zoom)
	if zoom < 1.0:
		camera.limit_enabled = false
	else:
		camera.limit_enabled = true
	camera.reset_smoothing()


func _press_interact() -> void:
	var press: InputEventAction = InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	Input.parse_input_event(press)


func _level_shows(level: Level, what: String) -> bool:
	if what == "slowed":
		return (level.get_node("WaveSpawner") as Node).get_children().any(func(e: Node) -> bool: return (e as Enemy).is_slowed())
	return not level.find_children("*", what, true, false).is_empty()


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	_save(root.get_texture().get_image(), shot_name)


func _save(image: Image, shot_name: String) -> void:
	var path: String = ProjectSettings.globalize_path(_out_dir.path_join(shot_name + ".png"))
	image.save_png(path)
	print("saved ", path)
	if _grayscale:
		Grayscale.convert(image).save_png(path.get_basename() + "_gray.png")


func _frames(count: int) -> void:
	for _i: int in count:
		await process_frame
