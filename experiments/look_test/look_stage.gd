class_name LookStage
extends RefCounted
## The look-test's shared stage (experiment branch look-test, not for merging): the graveyard
## (prototype_arena) in a late wave with all 16 slots built and upgraded, an unbreakable fortress, and the
## balance tool's hero bot swinging, so every variant is shot and measured on the same fight.

const ARENA: String = "res://levels/prototype_arena.tscn"
const HeroBot: GDScript = preload("res://tests/tools/hero_bot.gd")
const TOWERS: Array[int] = [0, 2, 3, 0, 4, 2, 0, 1, 2, 4]  # catalog index per slot, as perf_report.gd


## Builds the level inside `host` (a node already in the tree) and starts the wave. Returns the level.
static func build(host: Node, tree: SceneTree) -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = [spawner.waves.back(), WaveData.new()]
	WaveFixtures.no_upgrades(level)
	host.add_child(level)
	for _i: int in 3:
		await tree.process_frame
	(level.get_node("Fortress") as Fortress).health.setup(100000)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	(level.get_node("%Economy") as Economy).earn(100000, Economy.Source.KILL)
	for i: int in builder.get_slots().size():
		builder.build(builder.get_slots()[i], builder.catalog[TOWERS[i % TOWERS.size()] % builder.catalog.size()])
	for _i: int in 60:
		await tree.process_frame
	for slot: BuildSlot in builder.get_slots():
		builder.upgrade(slot)
		builder.upgrade(slot)
	return level


## Drives the hero with the bot on every physics frame (a child of the level).
static func add_bot(level: Level) -> void:
	var driver: Node = Node.new()
	driver.name = "BotDriver"
	var bot: RefCounted = HeroBot.new(level.get_node("Hero"), level.get_node("WaveSpawner"))
	driver.set_script(load("res://experiments/look_test/bot_driver.gd"))
	driver.set("bot", bot)
	driver.set("level", level)
	level.add_child(driver)
