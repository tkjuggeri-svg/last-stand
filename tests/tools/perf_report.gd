extends SceneTree
## Plays the run's last wave (165 enemies and the Lich Warden) with every slot built and upgraded and reports the frame
## rate and frame times. Run it in a real window (not headless), at real speed:
##   godot --path . --resolution 1280x720 --script res://tests/tools/perf_report.gd [-- --seconds=60] [--no-towers]
##     [--chapter-2 | --biome=<chapter id>] [--evolved] [--necromancer]
## --chapter-2 plays chapter 2's last wave (223 enemies and the Tollkeeper, with the chapter's fight HP
## scale) instead; --biome=<id> does the same for any biome (its boss fight's last wave, M13); --evolved evolves every tower (alternating branches) so their effects are on screen.
## Vsync is switched off so the numbers show the real headroom. --no-towers leaves the whole wave
## alive (the worst case for enemies on screen); --empty measures the scene without a wave.
## Prints FPS (average, 1% low), process and physics time per frame, and the most enemies and shots
## on screen at once. --display runs the level inside the game's Display at its smooth scaling (at
## 1080p: rendered at 2x and filtered down) to measure what that costs.

## --necromancer: her towers (by id, per slot) instead of the Knight's.
const NECRO_TOWERS: Array[String] = ["archer", "bone_pit", "ossuary", "archer", "bone_pit", "soul_siphon", "bone_pit", "cannon", "soul_siphon", "bone_pit"]
const TOWERS: Array[int] = [0, 2, 3, 0, 4, 2, 0, 1, 2, 4]  # catalog index per slot (archer, cannon, ...)

var _seconds: float = 60.0
var _towers: bool = true
## Baseline: the same level and towers, no wave (what the scene itself costs).
var _empty: bool = false
## Experiment: every PointLight2D off (to see what the lights cost).
var _lights: bool = true
var _chapter_2: bool = false
## --biome=<chapter id>: that biome's level and boss-fight wave.
var _biome: String = ""
var _evolved: bool = false
var _display: bool = false
var _necromancer: bool = false


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
		elif arg == "--no-towers":
			_towers = false
		elif arg == "--empty":
			_empty = true
		elif arg == "--no-lights":
			_lights = false
		elif arg == "--chapter-2":
			_chapter_2 = true
		elif arg.begins_with("--biome="):
			_biome = arg.trim_prefix("--biome=")
		elif arg == "--evolved":
			_evolved = true
		elif arg == "--necromancer":
			_necromancer = true
		elif arg == "--display":
			_display = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var chapter: ChapterData = (load("res://data/run/run.tres") as RunData).chapters[1 if _chapter_2 else 0]
	if _biome != "":
		chapter = (load("res://data/run/run.tres") as RunData).find_chapter(StringName(_biome))
	var level: Level = chapter.level_scene.instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = [spawner.waves.back(), WaveData.new()]
	if _biome != "":
		var boss_wave: WaveData = chapter.boss.waves.back().duplicate()
		boss_wave.health_multiplier *= chapter.fight_health_scale
		spawner.waves = [boss_wave, WaveData.new()]
	elif _chapter_2:
		var finale: WaveData = (load("res://data/waves/chapter_2/wave_15.tres") as WaveData).duplicate()
		finale.health_multiplier *= chapter.fight_health_scale
		spawner.waves = [finale, WaveData.new()]
	WaveFixtures.no_upgrades(level)
	var necro: HeroData = load("res://data/heroes/necromancer.tres")
	if _necromancer:
		(level.get_node("Hero") as Hero).data = necro
	if _display:
		var display: Display = (load("res://main/display.tscn") as PackedScene).instantiate()
		display.content = null
		root.add_child(display)
		display.get_game_viewport().add_child(level)
	else:
		root.add_child(level)
	for _i: int in 3:
		await process_frame
	if _necromancer:
		level.apply_hero(necro, (load("res://data/run/run.tres") as RunData).heroes)
	(level.get_node("Fortress") as Fortress).health.setup(100000)  # it must not fall mid-measurement
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	(level.get_node("%Economy") as Economy).earn(100000, Economy.Source.KILL)
	for i: int in (builder.get_slots().size() if _towers else 0):
		var data: TowerData = builder.catalog[TOWERS[i] % builder.catalog.size()]
		if _necromancer:
			for candidate: TowerData in builder.catalog:
				if String(candidate.id) == NECRO_TOWERS[i]:
					data = candidate
		builder.build(builder.get_slots()[i], data)
	for _i: int in 60:
		await process_frame
	for slot: BuildSlot in builder.get_slots():
		builder.upgrade(slot)
		builder.upgrade(slot)
		if _evolved:
			builder.evolve(slot, slot.get_index() % 2)
	if not _lights:
		for light: Node in level.find_children("*", "PointLight2D", true, false):
			(light as PointLight2D).enabled = false
	if not _empty:
		(level.get_node("%RunCycle") as RunCycle).start_wave()
	var frame_times: Array[float] = []
	var process_ms: float = 0.0
	var physics_ms: float = 0.0
	var most_enemies: int = 0
	var most_shots: int = 0
	var frames: int = 0
	var start: int = Time.get_ticks_usec()
	var last: int = start
	while Time.get_ticks_usec() - start < int(_seconds * 1000000.0):
		await process_frame
		var now: int = Time.get_ticks_usec()
		frame_times.append((now - last) / 1000.0)
		last = now
		frames += 1
		process_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		most_enemies = maxi(most_enemies, spawner.get_living_count())
		var shots: int = 0
		for slot: BuildSlot in builder.get_slots():
			if not slot.is_empty():
				shots += slot.tower.get_children().filter(func(c: Node) -> bool: return c is Projectile).size()
		most_shots = maxi(most_shots, shots)
	frame_times.sort()
	var average: float = (Time.get_ticks_usec() - start) / 1000.0 / frames
	var low: float = frame_times[int(frame_times.size() * 0.99)]
	print("frames %d over %.0f s: average %.1f fps (%.2f ms), 1%% low %.1f fps (%.2f ms), worst %.1f ms" % [frames, _seconds,
		1000.0 / average, average, 1000.0 / low, low, frame_times.back()])
	print("per frame: process %.2f ms, physics %.2f ms; most enemies alive %d, most shots in the air %d" % [process_ms / frames,
		physics_ms / frames, most_enemies, most_shots])
	quit()
