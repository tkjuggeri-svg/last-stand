extends SceneTree
## Plays whole run map runs through main.tscn with a bot player and prints how each went (a tuning aid,
## not a pass/fail test): where it ended (won, or lost in chapter c at row r), the fights and waves
## fought, the upgrades and evolutions taken, the income per chapter, the time.
##   godot --headless --fixed-fps 60 --path . --script res://tests/tools/map_balance.gd
##     [-- --seeds=1-8 | --seed-list=3,8,14] [--path=fights|balanced|safe] [--plan=mixed|all five] [--hero=bot|idle] [--quiet]
##     [--protect-ch1] [--trace]
## --protect-ch1 keeps the fortress and the lives full in chapter 1 only, so every run reaches chapter 2
## with a real chapter-1 build (towers, upgrades, gold) and chapter 2 is measured on its own. --trace
## prints every wave's start and end from chapter 2 on: gold, the towers (id:level per slot), the
## fortress's HP, leaks.
## The bot: picks the next node by --path (fights: battles and elites first; balanced: battles, then
## events, merchants, shrines, elites last; safe: events and merchants before battles, never an elite
## if it can help it); in a fight it buys the plan's towers and levels in order as the gold allows
## (like balance_report.gd), evolves them once all are at level 3, repairs the fortress below half HP and
## buys back a lost life between waves, starts each wave after BUILD_SECONDS; takes the first tower
## card of a reward (else any); at a merchant buys a repair below 60% and the cheapest tower card it
## can afford while keeping KEEP_GOLD; answers events with their first answer it can take, takes
## shrine deals on the fights path only. The hero is HeroBot (or parked out of the way).
## Relics (M7.5): offered a relic choice, the bot takes the one highest in RELIC_PREFERENCE; at a
## merchant it buys the relic if it keeps KEEP_GOLD. The summary counts, per relic, how often it was
## offered and taken over all the runs.

const MAIN: String = "res://main/main.tscn"
const HeroBot: GDScript = preload("res://tests/tools/hero_bot.gd")
const BUILD_SECONDS: float = 5.0
const HERO_PARKED: Vector2 = Vector2(380, 380)
const KEEP_GOLD: int = 150
const REPAIR_BELOW: float = 0.5
## Tower plans per level (the level scene's file name): [tower id, slot index] in build order.
const PLANS: Dictionary = {
	"mixed": {
		"prototype_arena": [["archer", 4], ["archer", 9], ["cannon", 7], ["frost", 8], ["cannon", 5], ["archer", 2],
			["frost", 6], ["cannon", 0], ["archer", 3], ["cannon", 1]],
		# The marsh's 7 slots: 0 west road's bend, 1 by the merge (west and south roads' ends), 2 south
		# road, 3 south of the keep, 4 north of the keep (three roads' ends), 5 north-east road, 6 far
		# north-east.
		"drowned_marsh": [["archer", 4], ["archer", 1], ["cannon", 3], ["archer", 5], ["cannon", 0], ["archer", 2],
			["frost", 6]],
	},
	"all five": {
		"prototype_arena": [["archer", 4], ["ballista", 9], ["brazier", 7], ["archer", 8], ["cannon", 5], ["brazier", 2],
			["frost", 6], ["ballista", 0], ["archer", 3], ["cannon", 1]],
		"drowned_marsh": [["archer", 4], ["ballista", 1], ["brazier", 3], ["archer", 5], ["cannon", 0], ["ballista", 2],
			["frost", 6]],
	},
}
const EARLY_BUILDS: int = 6
## The bot's relic ranking (best first): what helps a bot that doesn't play around trade-offs.
const RELIC_PREFERENCE: Array[StringName] = [&"twin_banners", &"glass_banner", &"phoenix_feather", &"drowned_bell",
	&"siege_ledger", &"hourglass", &"iron_tithe", &"executioners_mark", &"ember_heart", &"lantern_of_the_lost",
	&"soul_lantern", &"ossuary_bell", &"merchants_seal", &"bloodpact", &"second_oath"]
const PATH_ORDER: Dictionary = {
	"fights": [RunMap.Kind.ELITE, RunMap.Kind.BATTLE, RunMap.Kind.SHRINE, RunMap.Kind.EVENT, RunMap.Kind.MERCHANT, RunMap.Kind.BOSS],
	"balanced": [RunMap.Kind.BATTLE, RunMap.Kind.EVENT, RunMap.Kind.MERCHANT, RunMap.Kind.SHRINE, RunMap.Kind.ELITE, RunMap.Kind.BOSS],
	"safe": [RunMap.Kind.EVENT, RunMap.Kind.MERCHANT, RunMap.Kind.BATTLE, RunMap.Kind.SHRINE, RunMap.Kind.ELITE, RunMap.Kind.BOSS],
}
## Game seconds a run may take before the tool gives up on it.
const MAX_SECONDS: float = 3600.0

var _path: String = "balanced"
var _plan_name: String = "mixed"
var _hero_mode: String = "bot"
var _quiet: bool = false
var _protect_ch1: bool = false
var _trace: bool = false
## Per relic id: [times offered, times taken], over every run.
var _relic_counts: Dictionary = {}


func _initialize() -> void:
	var seeds: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="):
			var parts: PackedStringArray = arg.trim_prefix("--seeds=").split("-")
			seeds.clear()
			for s: int in range(int(parts[0]), int(parts[parts.size() - 1]) + 1):
				seeds.append(s)
		elif arg.begins_with("--seed-list="):
			seeds.clear()
			for part: String in arg.trim_prefix("--seed-list=").split(","):
				seeds.append(int(part))
		elif arg.begins_with("--path="):
			_path = arg.trim_prefix("--path=")
		elif arg.begins_with("--plan="):
			_plan_name = arg.trim_prefix("--plan=")
		elif arg.begins_with("--hero="):
			_hero_mode = arg.trim_prefix("--hero=")
		elif arg == "--quiet":
			_quiet = true
		elif arg == "--protect-ch1":
			_protect_ch1 = true
		elif arg == "--trace":
			_trace = true
	var lines: Array[String] = []
	for s: int in seeds:
		lines.append(await _play(s))
	print("\n%-5s %-9s %-9s %-5s %-24s %6s %5s %5s %5s %5s %13s %7s  %s" % ["seed", "path", "plan", "hero", "result", "fights", "waves",
		"upgr", "evos", "lives", "income c1/c2", "minutes", "path taken"])
	for line: String in lines:
		print(line)
	print("\n%-22s %8s %6s" % ["relic", "offered", "taken"])
	for id: StringName in RELIC_PREFERENCE:
		var counts: Array = _relic_counts.get(id, [0, 0])
		print("%-22s %8d %6d" % [id, counts[0], counts[1]])
	quit()


func _play(seed_value: int) -> String:
	var main: Node = (load(MAIN) as PackedScene).instantiate()
	main.set("run_seed", seed_value)
	root.add_child(main)
	await physics_frame
	var stats: Dictionary = {"fights": 0, "waves": 0, "evos": 0, "income": [0, 0], "taken": []}
	var level: Level = null
	var bot: RefCounted = null
	var plan: Array = []
	var next: int = 0
	var build_time: float = 0.0
	var chapter: int = 0
	var time: float = 0.0
	var result: String = "timed out"
	var map_screen: MapScreen = main.get_node("%MapScreen")
	var merchant_screen: MerchantScreen = main.get_node("%MerchantScreen")
	var event_screen: EventScreen = main.get_node("%EventScreen")
	var chapter_screen: ChapterScreen = main.get_node("%ChapterScreen")
	while time < MAX_SECONDS:
		await physics_frame
		time += 1.0 / 60.0
		if level != main.call("get_level"):
			level = main.call("get_level")
			bot = HeroBot.new(level.get_node("Hero"), level.get_node("WaveSpawner")) if _hero_mode == "bot" else null
			plan = _steps(PLANS[_plan_name][level.scene_file_path.get_file().get_basename()])
			next = 0
			level.economy.gold_earned.connect(func(amount: int, source: Economy.Source) -> void:
				if source != Economy.Source.REFUND:
					stats["income"][mini(chapter, 1)] += amount)
			(level.get_node("WaveSpawner") as WaveSpawner).wave_started.connect(func(_n: int) -> void: stats["waves"] += 1)
			if _trace:
				var traced: Level = level
				(level.get_node("WaveSpawner") as WaveSpawner).wave_started.connect(func(n: int) -> void:
					if chapter >= 1:
						print("  c%d wave %d start: %s" % [chapter + 1, n, _describe(traced)]))
				(level.get_node("WaveSpawner") as WaveSpawner).wave_cleared.connect(func(n: int) -> void:
					if chapter >= 1:
						print("  c%d wave %d end:   %s" % [chapter + 1, n, _describe(traced)]))
		if (main.get_node("%VictoryScreen") as CanvasLayer).visible:
			result = "WON"
			break
		if (main.get_node("%GameOverScreen") as CanvasLayer).visible:
			var map: RunMap = main.call("get_map")
			result = "lost c%d row %d (%s)" % [chapter + 1, map.get_current().row if map.get_current() != null else 0,
				"fort" if level.fortress.health.is_dead() else "hero"]
			break
		if chapter_screen.visible:
			chapter += 1
			chapter_screen.get_continue_button().pressed.emit()
			continue
		if map_screen.visible:
			var node: MapNode = _choose_node(main.call("get_map"))
			if node.is_combat():
				stats["fights"] += 1
			stats["taken"].append("BEXSMK"[node.kind])
			map_screen.node_chosen.emit(node)
			build_time = 0.0
			continue
		if merchant_screen.visible:
			_shop(level)
			merchant_screen.get_leave_button().pressed.emit()
			continue
		if event_screen.visible:
			if event_screen.get_continue_button().visible:
				event_screen.get_continue_button().pressed.emit()
			else:
				event_screen.choice_picked.emit(_answer(level, main))
			continue
		if level.offers.is_offer_open():
			var offer: Array[UpgradeData] = level.offers.get_offer()
			var pick: int = _relic_pick(offer) if offer[0] is RelicData else _card(offer)
			level.offers.pick(pick)
			continue
		if not level.is_active():
			continue
		var cycle: RunCycle = level.get_node("%RunCycle")
		if _hero_mode == "idle" and cycle.get_phase() == RunCycle.Phase.BUILD:
			(level.get_node("Hero") as Node2D).global_position = HERO_PARKED
		if _protect_ch1 and chapter == 0:
			level.fortress.health.set_current_health(level.fortress.health.max_health)
			level.hero_lives.set_lives_left(level.hero_lives.get_max_lives())
		if bot != null:
			bot.call("step", level.get_node("%RunModifiers"))
		next = _buy(level, plan, next, stats)
		if cycle.get_phase() == RunCycle.Phase.BUILD:
			_sinks(level)
			build_time += 1.0 / 60.0
			if build_time >= BUILD_SECONDS:
				build_time = 0.0
				cycle.start_wave()
	if bot != null:
		bot.call("release")
	var line: String = "%-5d %-9s %-9s %-5s %-24s %6d %5d %5d %5d %5d %6d/%-6d %7.1f  %s" % [seed_value, _path, _plan_name, _hero_mode, result,
		stats["fights"], stats["waves"], (level.get_node("%RunModifiers") as RunModifiers).get_taken().size(), stats["evos"],
		level.hero_lives.get_lives_left(), stats["income"][0], stats["income"][1], time / 60.0, "".join(stats["taken"])]
	if not level.modifiers.get_relics().is_empty():
		line += "  relics: " + ", ".join(level.modifiers.get_relics().map(func(r: RelicData) -> String: return String(r.id)))
	if not _quiet:
		print(line)
	main.queue_free()
	for _i: int in 3:
		await physics_frame
	return line


## Gold, towers (id:level by slot) and the fortress, for --trace.
func _describe(level: Level) -> String:
	var towers: Array[String] = []
	for slot: BuildSlot in level.builder.get_slots():
		towers.append("-" if slot.is_empty() else "%s:%d" % [slot.tower.data.id, slot.tower.get_level()])
	return "gold %d, fortress %d/%d, towers %s" % [level.economy.get_gold(), level.fortress.health.current_health,
		level.fortress.health.max_health, " ".join(towers)]


func _choose_node(map: RunMap) -> MapNode:
	var choices: Array[MapNode] = map.get_choices()
	var order: Array = PATH_ORDER[_path]
	var best: MapNode = choices[0]
	for node: MapNode in choices:
		if order.find(node.kind) < order.find(best.kind):
			best = node
	return best


## The plan as buy steps: builds, level 2s, the rest, then everything to level 3, then evolutions.
func _steps(builds: Array) -> Array:
	var steps: Array = []
	var early: Array = builds.slice(0, EARLY_BUILDS)
	steps.append_array(early)
	for build: Array in early:
		steps.append(["up", build[1]])
	for build: Array in builds.slice(EARLY_BUILDS):
		steps.append(build)
		steps.append(["up", build[1]])
	for build: Array in builds:
		steps.append(["up", build[1]])
	for build: Array in builds:
		steps.append(["evo", build[1]])
	return steps


func _buy(level: Level, plan: Array, next: int, stats: Dictionary) -> int:
	if next >= plan.size():
		return next
	var builder: TowerBuilder = level.builder
	var economy: Economy = level.economy
	var step: Array = plan[next]
	var slot: BuildSlot = builder.get_slots()[step[1]]
	match step[0]:
		"up":
			var cost: int = builder.upgrade_cost(slot)
			if cost < 0:
				return next + 1
			if economy.can_afford(cost) and not slot.tower.is_building() and builder.upgrade(slot):
				return next + 1
		"evo":
			var options: Array[TowerEvolution] = builder.evolution_options(slot)
			if options.is_empty():
				return next + 1
			var index: int = slot.get_index() % 2
			if economy.can_afford(builder.evolution_cost(options[index])) and not slot.tower.is_building() and builder.evolve(slot, index):
				stats["evos"] += 1
				return next + 1
		_:
			for data: TowerData in builder.catalog:
				if String(data.id) == step[0] and economy.can_afford(data.cost) and builder.build(slot, data):
					return next + 1
	return next


func _sinks(level: Level) -> void:
	var shop: Quartermaster = level.get_node("%Quartermaster")
	shop.buy_life()
	if level.fortress.health.current_health < level.fortress.health.max_health * REPAIR_BELOW:
		shop.repair()


func _card(cards: Array[UpgradeData]) -> int:
	for i: int in cards.size():
		if cards[i].category == UpgradeData.Category.TOWERS:
			return i
	return 0


## The offered relic highest in RELIC_PREFERENCE (counted as offered and taken).
func _relic_pick(offer: Array[UpgradeData]) -> int:
	var best: int = 0
	for i: int in offer.size():
		_count_relic(offer[i].id, 0)
		if RELIC_PREFERENCE.find(offer[i].id) < RELIC_PREFERENCE.find(offer[best].id):
			best = i
	_count_relic(offer[best].id, 1)
	return best


func _count_relic(id: StringName, column: int) -> void:
	if not _relic_counts.has(id):
		_relic_counts[id] = [0, 0]
	_relic_counts[id][column] += 1


func _shop(level: Level) -> void:
	var merchant: Merchant = level.merchant
	var relic: RelicData = merchant.get_relic()
	if relic != null and not merchant.is_relic_sold():
		_count_relic(relic.id, 0)
		if level.economy.get_gold() - merchant.price_of(relic) >= KEEP_GOLD and merchant.buy_relic():
			_count_relic(relic.id, 1)
	if level.fortress.health.current_health < level.fortress.health.max_health * 0.6:
		merchant.buy_repair()
	var cards: Array[UpgradeData] = merchant.get_cards()
	for i: int in cards.size():
		if cards[i].category == UpgradeData.Category.TOWERS and level.economy.get_gold() - merchant.price_of(cards[i]) >= KEEP_GOLD:
			merchant.buy_card(i)
			return


func _answer(level: Level, main: Node) -> int:
	var map: RunMap = main.call("get_map")
	var scene: EventData = map.get_current().event
	if scene.shrine and _path != "fights":
		return scene.choices.size() - 1  # walk away
	for i: int in scene.choices.size():
		if level.events.choice_blocker(scene.choices[i]).is_empty():
			return i
	return scene.choices.size() - 1
