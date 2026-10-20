extends RefCounted
## The "m6" screenshot scenario of capture_screenshots.gd (kept apart so that script stays short):
## the dash (afterimages, the HUD cooldown row, the Cinder Dash trail), the Cultist (casting at the
## fortress, at the hero, beside the other enemies), the bosses (arrival with the HUD bar, telegraph,
## mechanic, death), the pause menu and the settings, and the Quartermaster's panel (repair, buy back
## a life) in a build phase, and tower evolutions (the choice with both rings, all 10 in a fight).
## `--only=dash` (comma-separated) runs just some parts.

const CINDER_DASH: UpgradeData = preload("res://data/upgrades/cinder_dash.tres")
const CULTIST: EnemyData = preload("res://data/enemies/cultist.tres")
const GHOUL: EnemyData = preload("res://data/enemies/ghoul.tres")
const BRUTE: EnemyData = preload("res://data/enemies/brute.tres")

## The capture tool (a SceneTree script): its _shot(), _frames() and _frame_camera().
var _tool: SceneTree
var _only: PackedStringArray


func _init(tool: SceneTree, only: PackedStringArray) -> void:
	_tool = tool
	_only = only


func run(level: Level) -> void:
	WaveFixtures.no_upgrades(level)
	if _wants("dash"):
		await _dash(level)
	if _wants("cultist"):
		await _cultist(level)
	if _wants("bosses"):
		await _clear(level)
		await _bosses(level)
	if _wants("pause"):
		await _clear(level)
		await _pause(level)
	if _wants("shop"):
		await _clear(level)
		await _shop(level)
	if _wants("evolutions"):
		await _clear(level)
		await _evolutions(level)


func _wants(part: String) -> bool:
	return _only.is_empty() or _only.has(part)


func _dash(level: Level) -> void:
	var hero: Hero = level.get_node("Hero")
	var camera: Camera2D = hero.get_node("Camera2D")
	hero.global_position = Vector2(-260, 110)
	_tool.call("_frame_camera", camera, Vector2(-200, 90), 2.0, true)
	await _tool.call("_frames", 20)
	hero.dash(Vector2.RIGHT)
	await _tool.call("_frames", 7)
	await _tool.call("_shot", "m6_01_dash_afterimages")
	_tool.call("_frame_camera", camera, Vector2.ZERO, 1.0, false)
	await _tool.call("_frames", 20)
	await _tool.call("_shot", "m6_02_hud_dash_cooldown")
	(level.get_node("%RunModifiers") as RunModifiers).add_upgrade(CINDER_DASH)
	await _tool.call("_frames", 130)
	hero.global_position = Vector2(-300, 110)
	_tool.call("_frame_camera", camera, Vector2(-220, 90), 2.0, true)
	hero.dash(Vector2.RIGHT)
	await _tool.call("_frames", 16)
	await _tool.call("_shot", "m6_03_cinder_dash_trail")


func _cultist(level: Level) -> void:
	var hero: Hero = level.get_node("Hero")
	var camera: Camera2D = hero.get_node("Camera2D")
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var cultists: WaveData = WaveFixtures.make_wave(3, 1.6, CULTIST, 0)
	var escort: WaveData = WaveFixtures.make_wave(3, 2.5, GHOUL, 0, 1.0)
	cultists.groups.append(escort.groups[0])
	var brute: WaveData = WaveFixtures.make_wave(1, 1.0, BRUTE, 0, 0.5)
	cultists.groups.append(brute.groups[0])
	spawner.waves = [cultists, WaveData.new()]
	hero.global_position = Vector2(-150, 300)
	(level.get_node("%RunCycle") as RunCycle).start_wave()
	_tool.call("_frame_camera", camera, Vector2(-300, -130), 2.0, true)
	for _i: int in 60 * 12:
		await _tool.call("_frames", 1)
		if _sieging(spawner) >= 1 and not level.find_children("*", "EnemyBolt", true, false).is_empty():
			break
	await _tool.call("_frames", 12)
	await _tool.call("_shot", "m6_04_cultist_siege")
	for _i: int in 60 * 10:
		await _tool.call("_frames", 1)
		if _sieging(spawner) >= 3:
			break
	hero.global_position = Vector2(-210, -60)
	_tool.call("_frame_camera", camera, Vector2(-230, -30), 2.0, true)
	for _i: int in 60 * 4:
		await _tool.call("_frames", 1)
		var casting: bool = spawner.get_children().any(func(e: Node) -> bool: return e is Enemy and (e as Enemy).is_attacking() and (e as Enemy).has_target())
		if casting:
			break
	await _tool.call("_frames", 4)
	await _tool.call("_shot", "m6_05_cultist_casting_at_hero")
	hero.global_position += Vector2(-40, -60)  # further away, so the shot is seen in flight
	for _i: int in 60 * 4:
		await _tool.call("_frames", 1)
		var flying: Array = level.find_children("*", "EnemyBolt", true, false).filter(func(b: Node) -> bool: return not (b as EnemyBolt).is_spent())
		if not flying.is_empty() and (flying[0] as Node2D).global_position.distance_to(hero.global_position) < 80.0:
			break
	await _tool.call("_shot", "m6_06_cultist_bolt_at_hero")


func _sieging(spawner: WaveSpawner) -> int:
	return spawner.get_children().filter(func(e: Node) -> bool: return e is Enemy and (e as Enemy).is_sieging()).size()


func _bosses(level: Level) -> void:
	var hero: Hero = level.get_node("Hero")
	var camera: Camera2D = hero.get_node("Camera2D")
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var cycle: RunCycle = level.get_node("%RunCycle")
	var boss_ids: Array[String] = ["gravelord", "colossus", "lich"]
	var waves: Array[WaveData] = []
	for _i: int in spawner.get_wave_number():
		waves.append(WaveData.new())  # the waves an earlier part already played
	for id: String in boss_ids:
		var wave: WaveData = WaveFixtures.make_wave(1, 1.0, load("res://data/enemies/%s.tres" % id) as EnemyData, 0)
		wave.groups.append(WaveFixtures.make_wave(6, 1.2, GHOUL, 0, 2.0).groups[0])
		waves.append(wave)
	waves.append(WaveData.new())
	spawner.waves = waves
	hero.global_position = Vector2(-560, -120)
	hero.health.set_max_health(5000)
	hero.health.revive()
	for n: int in boss_ids.size():
		var id: String = boss_ids[n]
		cycle.start_wave()
		var boss: Enemy = null
		for _i: int in 120:
			await _tool.call("_frames", 1)
			for e: Node in spawner.get_children():
				if e is Enemy and (e as Enemy).data.is_boss:
					boss = e
			if boss != null:
				break
		_tool.call("_frame_camera", camera, Vector2(-560, -200), 1.5, true)
		await _tool.call("_frames", 50)
		await _tool.call("_shot", "m6_%02d_%s_arrives" % [7 + n * 4, id])
		var ability: EnemyAbility = boss.find_children("*", "EnemyAbility", false, false)[0]
		if id == "colossus":
			hero.global_position = boss.global_position + Vector2(170, 60)
		for _i: int in 60 * 12:
			await _tool.call("_frames", 1)
			if ability.is_telegraphing() and _i > 30:
				break
		await _tool.call("_frames", 30)
		_tool.call("_frame_camera", camera, boss.global_position + Vector2(40, -30), 2.0, true)
		await _tool.call("_frames", 2)
		await _tool.call("_shot", "m6_%02d_%s_telegraph" % [8 + n * 4, id])
		for _i: int in 120:
			await _tool.call("_frames", 1)
			if not ability.is_telegraphing():
				break
		await _tool.call("_frames", 8 if id == "colossus" else 20)
		_tool.call("_frame_camera", camera, boss.global_position + Vector2(40, -30), 2.0, true)
		await _tool.call("_frames", 2)
		await _tool.call("_shot", "m6_%02d_%s_mechanic" % [9 + n * 4, id])
		boss.get_health().take_damage(100000)
		await _tool.call("_frames", 14)
		await _tool.call("_shot", "m6_%02d_%s_death" % [10 + n * 4, id])
		for _i: int in 60 * 20:
			await _tool.call("_frames", 1)
			for e: Node in spawner.get_children():
				if e is Enemy and (e as Enemy).is_alive():
					(e as Enemy).get_health().take_damage(100000)
			if cycle.get_phase() == RunCycle.Phase.BUILD:
				break
		hero.global_position = Vector2(-560, -120)
		_tool.call("_frame_camera", camera, Vector2.ZERO, 1.0, false)


func _pause(level: Level) -> void:
	var menu: PauseMenu = level.get_parent().get_node("%PauseMenu")
	(level.get_node("%RunCycle") as RunCycle).start_wave()
	await _tool.call("_frames", 200)
	menu.open()
	await _tool.call("_frames", 5)
	await _tool.call("_shot", "m6_19_pause_menu")
	(menu.get_node("%SettingsButton") as Button).pressed.emit()
	await _tool.call("_frames", 5)
	await _tool.call("_shot", "m6_20_settings")
	var settings: SettingsMenu = menu.get_node("%SettingsMenu")
	settings.get_binding_button(&"dash", 0).pressed.emit()
	await _tool.call("_frames", 3)
	await _tool.call("_shot", "m6_21_settings_rebinding")
	settings.close()
	menu.close()


func _shop(level: Level) -> void:
	var hero: Hero = level.get_node("Hero")
	(level.get_node("Fortress") as Fortress).health.take_damage(45)
	hero.health.take_damage(hero.health.current_health)
	await _tool.call("_frames", 60 * 5)  # the respawn
	(level.get_node("%Economy") as Economy).earn(260, Economy.Source.KILL)
	await _tool.call("_frames", 10)
	await _tool.call("_shot", "m6_22_quartermaster")


func _evolutions(level: Level) -> void:
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var economy: Economy = level.get_node("%Economy")
	var hero: Hero = level.get_node("Hero")
	var camera: Camera2D = hero.get_node("Camera2D")
	var towers: Array[TowerData] = []
	for data: TowerData in builder.catalog:
		towers.append(data)
	economy.earn(50000, Economy.Source.REFUND)
	# The choice: a level-3 cannon at slot 3, both branches and their rings.
	var slots: Array[BuildSlot] = builder.get_slots()
	builder.build(slots[3], towers[2])
	await _tool.call("_frames", 60)
	builder.upgrade(slots[3])
	builder.upgrade(slots[3])
	hero.global_position = slots[3].global_position + Vector2(0, 30)
	await _tool.call("_frames", 10)
	var menu: Node = level.get_node("BuildMenu")
	menu.call("open", slots[3])
	_tool.call("_frame_camera", camera, slots[3].global_position + Vector2(0, 60), 1.0, true)
	await _tool.call("_frames", 10)
	await _tool.call("_shot", "m6_23_evolution_choice")
	menu.call("close")
	builder.sell(slots[3])
	await _tool.call("_frames", 30)
	# All ten, two per tower type, in a fight.
	var plan: Array = [[0, 0, 0], [1, 0, 1], [2, 2, 0], [3, 2, 1], [4, 1, 0], [5, 1, 1], [6, 3, 0], [7, 3, 1], [8, 4, 0], [9, 4, 1]]
	for entry: Array in plan:
		var slot: BuildSlot = slots[entry[0]]
		builder.build(slot, towers[entry[1]])
	await _tool.call("_frames", 60)
	for entry: Array in plan:
		var slot: BuildSlot = slots[entry[0]]
		builder.upgrade(slot)
		builder.upgrade(slot)
		builder.evolve(slot, entry[2])
	await _tool.call("_frames", 20)
	hero.global_position = Vector2(380, 380)
	_tool.call("_frame_camera", camera, Vector2(-150, -40), 1.0, true)
	await _tool.call("_frames", 10)
	await _tool.call("_shot", "m6_24_evolutions_all")
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var wave: WaveData = WaveFixtures.make_wave(30, 0.5, GHOUL, 0)
	wave.health_multiplier = 4.0
	wave.groups.append(WaveFixtures.make_wave(20, 0.6, GHOUL, 1).groups[0])
	wave.groups.append(WaveFixtures.make_wave(20, 0.6, GHOUL, 2).groups[0])
	wave.groups.append(WaveFixtures.make_wave(4, 3.0, BRUTE, 0, 2.0).groups[0])
	var waves: Array[WaveData] = []
	for _i: int in spawner.get_wave_number():
		waves.append(WaveData.new())
	waves.append(wave)
	waves.append(WaveData.new())
	spawner.waves = waves
	(level.get_node("%RunCycle") as RunCycle).start_wave()
	for shot: Array in [[480, "m6_25_evolutions_fight_west", Vector2(-380, -150)], [180, "m6_26_evolutions_fight_center", Vector2(-120, 0)],
			[180, "m6_27_evolutions_fight_east", Vector2(120, -60)]]:
		await _tool.call("_frames", shot[0])
		_tool.call("_frame_camera", camera, shot[2], 1.5, true)
		await _tool.call("_frames", 2)
		await _tool.call("_shot", shot[1])


## Ends whatever wave an earlier part left running, so each part starts in a build phase.
func _clear(level: Level) -> void:
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	for _i: int in 60 * 30:
		if not spawner.is_wave_active():
			break
		for e: Node in spawner.get_children():
			if e is Enemy and (e as Enemy).is_alive():
				(e as Enemy).get_health().take_damage(100000)
		await _tool.call("_frames", 1)
	await _tool.call("_frames", 5)
