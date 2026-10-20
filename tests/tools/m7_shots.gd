extends RefCounted
## The "m7" screenshot scenario of capture_screenshots.gd: the run map at the start, a battle's reward
## (one choice per battle), the map after it (the path taken marked), an elite node described (its
## mini-boss and twist), a merchant's shop, an event and a shrine.

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
	spawner.enemy_spawned.connect(func(e: Enemy) -> void: e.get_health().take_damage.call_deferred(100000))
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
