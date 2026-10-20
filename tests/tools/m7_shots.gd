extends RefCounted
## The "m7" screenshot scenario of capture_screenshots.gd: the run map at the start, a battle's reward
## (one choice per battle), the map after it (the path taken marked), an elite node described (its
## mini-boss and twist), a merchant's shop, an event and a shrine, the Tollkeeper's toll (the ring,
## then silenced towers) and the chapter screen.

## The capture tool (a SceneTree script): its _shot() and _frames().
var _tool: SceneTree
var _only: PackedStringArray  # unused: the scenario is one sequence


func _init(tool: SceneTree, only: PackedStringArray) -> void:
	_tool = tool
	_only = only


func run(main: Node) -> void:
	var screen: MapScreen = main.get_node("%MapScreen")
	await _tool.call("_shot", "m7_01_map_start")
	var level: Level = await MapFixtures.enter_first_battle(main)
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var cycle: RunCycle = level.get_node("%RunCycle")
	var kill: Callable = func(e: Enemy) -> void: e.get_health().take_damage.call_deferred(100000)
	spawner.enemy_spawned.connect(kill)
	var offers: UpgradeOffers = level.get_node("%UpgradeOffers")
	for _i: int in 60 * 60:
		await _tool.call("_frames", 1)
		if cycle.can_start_wave():
			cycle.start_wave()
		if offers.is_offer_open():
			break
	await _tool.call("_frames", 10)
	await _tool.call("_shot", "m7_02_battle_reward")
	offers.pick(0)
	await _tool.call("_frames", 10)
	await _tool.call("_shot", "m7_03_map_after_battle")
	var map: RunMap = main.call("get_map")
	for node: MapNode in map.nodes:
		if node.kind == RunMap.Kind.ELITE:
			screen.get_node_button(node).mouse_entered.emit()
			break
	await _tool.call("_frames", 5)
	await _tool.call("_shot", "m7_04_elite_described")
	level.fortress.health.take_damage(30)
	level.economy.earn(400, Economy.Source.KILL)
	level.merchant.open()
	screen.close()
	(main.get_node("%MerchantScreen") as MerchantScreen).open(level.merchant)
	await _tool.call("_frames", 10)
	await _tool.call("_shot", "m7_05_merchant")
	(main.get_node("%MerchantScreen") as MerchantScreen).hide()
	var events: EventScreen = main.get_node("%EventScreen")
	for id: String in ["wounded_knight", "shrine_whispers"]:
		var scene: EventData = load("res://data/events/%s.tres" % id)
		events.open(scene, level.events)
		await _tool.call("_frames", 10)
		await _tool.call("_shot", "m7_06_event" if not scene.shrine else "m7_07_shrine")
	events.hide()
	spawner.enemy_spawned.disconnect(kill)
	# The Tollkeeper: its ring, then the towers inside silenced.
	level.set_active(true)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	level.economy.earn(3000, Economy.Source.REFUND)
	for i: int in [2, 3, 4, 5]:
		builder.build(builder.get_slots()[i], builder.catalog[i % 3])
	var hero: Hero = level.get_node("Hero")
	hero.global_position = Vector2(-60, 200)
	var wave: WaveData = WaveFixtures.make_wave(1, 1.0, load("res://data/enemies/tollkeeper.tres") as EnemyData, 0)
	wave.groups.append(WaveFixtures.make_wave(12, 1.0).groups[0])
	level.start_encounter([wave], FightReward.make(0))
	(level.get_node("%RunCycle") as RunCycle).start_wave()
	var boss: Enemy = null
	for _i: int in 60 * 60:
		await _tool.call("_frames", 1)
		for child: Node in spawner.get_children():
			if child is Enemy and (child as Enemy).data.is_boss:
				boss = child
		if boss != null and boss.global_position.x > -380.0:
			break
	var toll: TollAbility = boss.find_children("*", "TollAbility", false, false)[0]
	var camera: Camera2D = hero.get_node("Camera2D")
	for _i: int in 60 * 20:
		await _tool.call("_frames", 1)
		if toll.is_telegraphing():
			break
	await _tool.call("_frames", 50)
	_tool.call("_frame_camera", camera, boss.global_position + Vector2(40, -20), 1.4, true)
	await _tool.call("_frames", 2)
	await _tool.call("_shot", "m7_08_toll_ring")
	for _i: int in 120:
		await _tool.call("_frames", 1)
		if not toll.is_telegraphing():
			break
	await _tool.call("_frames", 20)
	await _tool.call("_shot", "m7_09_toll_silenced")
	var carry: ChapterCarry = ChapterCarry.new()
	carry.refund = 1840
	carry.gold = 2105
	carry.lives_left = 2
	carry.upgrades = (level.get_node("%RunModifiers") as RunModifiers).get_taken()
	(main.get_node("%ChapterScreen") as ChapterScreen).open("Chapter 1: The Crypt Road", "Chapter 2: The Drowned Fields", carry, 0.5, 88, 100)
	await _tool.call("_frames", 5)
	await _tool.call("_shot", "m7_10_chapter_cleared")
