extends SceneTree
## Plays whole run map runs through main.tscn with a bot player and prints how each went (a tuning aid,
## not a pass/fail test): where it ended (won, or lost in chapter c at row r), the fights and waves
## fought, the upgrades and evolutions taken, the income per chapter, the time.
##   godot --headless --fixed-fps 60 --path . --script res://tests/tools/map_balance.gd
##     [-- --seeds=1-8 | --seed-list=3,8,14] [--path=fights|balanced|safe] [--plan=mixed|all five] [--hero=bot|idle] [--hero-kind=knight|huntress|necromancer] [--archetype=<tag>] [--quiet]
##     [--protect-ch1] [--trace] [--fire=with|without] [--relics=none|<id>,<id>] [--profile=first] [--early]
## Plans: "mixed" and "all five" (hand-made per level), "all <tower id>" (that tower on every slot,
## in the mixed plan's slot order: single-tower spam) and "braziers first" (the mixed plan with its
## first three builds, one per road, made Braziers). --fire=with grants the fire cards and relic at the
## start (Hellfire Shells, Cinder Dash, Ember Heart); --fire=without takes them out of every offer
## and shop. --relics=<ids> grants those relics at the start and offers no other (none: no relics at
## all), to measure one relic against none. --profile=first plays with a fresh profile's kit (M8: the
## starting towers, cards and relics only; the plan skips towers it doesn't have). --early calls every
## next wave early as soon as it can (M8; the bonus gold counts in the income). The summary ends
## with the rows cleared per run (a won run:
## every row of both chapters).
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
		"drowned_marsh": [["cannon", 4], ["archer", 1], ["brazier", 3], ["archer", 5], ["cannon", 0], ["archer", 2],
			["frost", 6]],
	},
	"all five": {
		"prototype_arena": [["archer", 4], ["ballista", 9], ["brazier", 7], ["archer", 8], ["cannon", 5], ["brazier", 2],
			["frost", 6], ["ballista", 0], ["archer", 3], ["cannon", 1]],
		"drowned_marsh": [["archer", 4], ["cannon", 1], ["brazier", 3], ["ballista", 5], ["cannon", 0], ["archer", 2],
			["frost", 6]],
	},
}
const HUNTRESS_PLANS: Dictionary = {
	"prototype_arena": [["archer", 4], ["hawk_perch", 9], ["trap_layer", 7], ["archer", 8], ["watchtower", 5], ["hawk_perch", 2],
		["trap_layer", 6], ["cannon", 0], ["hawk_perch", 3], ["trap_layer", 1]],
	"drowned_marsh": [["archer", 4], ["cannon", 1], ["trap_layer", 3], ["hawk_perch", 5], ["watchtower", 0], ["hawk_perch", 2],
		["trap_layer", 6]],
}
const NECRO_PLANS: Dictionary = {
	"prototype_arena": [["archer", 4], ["bone_pit", 9], ["ossuary", 7], ["archer", 8], ["soul_siphon", 5], ["bone_pit", 2],
		["ossuary", 6], ["cannon", 0], ["soul_siphon", 3], ["bone_pit", 1]],
	"drowned_marsh": [["archer", 4], ["cannon", 1], ["bone_pit", 3], ["soul_siphon", 5], ["ossuary", 0], ["bone_pit", 2],
		["soul_siphon", 6]],
}
## The "mixed" plan of each new hero (--hero-kind).
const HERO_PLANS: Dictionary = {"huntress": HUNTRESS_PLANS, "necromancer": NECRO_PLANS}
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
## Map rows per chapter (the last is the boss), for the rows-cleared summary.
const ROWS_PER_CHAPTER: int = 8
## The fire cards and relic (--fire).
const FIRE_CARDS: Array[String] = ["res://data/upgrades/hellfire.tres", "res://data/upgrades/cinder_dash.tres", "res://data/relics/ember_heart.tres"]
## Game seconds a run may take before the tool gives up on it.
const MAX_SECONDS: float = 3600.0

var _path: String = "balanced"
var _plan_name: String = "mixed"
var _hero_mode: String = "bot"
## --archetype=<tag>: the card policy takes a card (or relic) of this tag whenever one is offered, to see
## whether an archetype is much stronger or weaker than the rest.
var _archetype: StringName = &""
## --hero-kind=knight|huntress: whose run is played (the "mixed" plan then builds that hero's towers).
var _hero_kind: String = "knight"
var _quiet: bool = false
var _protect_ch1: bool = false
var _trace: bool = false
## "with": the fire cards and relic are granted at the start; "without": never offered; "": as drawn.
var _fire: String = ""
var _early: bool = false
## --profile=first: a fresh profile (the first run's kit) instead of everything unlocked.
var _first_kit: bool = false
## --relics: the only relics of the run (granted at the start); null = drawn as usual.
var _relics: Variant = null
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
		elif arg.begins_with("--archetype="):
			_archetype = StringName(arg.trim_prefix("--archetype="))
		elif arg.begins_with("--hero-kind="):
			_hero_kind = arg.trim_prefix("--hero-kind=")
		elif arg.begins_with("--hero="):
			_hero_mode = arg.trim_prefix("--hero=")
		elif arg == "--quiet":
			_quiet = true
		elif arg == "--protect-ch1":
			_protect_ch1 = true
		elif arg == "--trace":
			_trace = true
		elif arg.begins_with("--fire="):
			_fire = arg.trim_prefix("--fire=")
		elif arg == "--early":
			_early = true
		elif arg == "--profile=first":
			_first_kit = true
		elif arg.begins_with("--relics="):
			var ids: String = arg.trim_prefix("--relics=")
			_relics = [] if ids == "none" else Array(ids.split(","))
	var lines: Array[String] = []
	for s: int in seeds:
		lines.append(await _play(s))
	print("\n%-5s %-9s %-9s %-5s %-24s %6s %5s %5s %5s %5s %13s %7s  %s" % ["seed", "path", "plan", "hero", "result", "fights", "waves",
		"upgr", "evos", "lives", "income c1/c2", "minutes", "path taken"])
	var cleared: float = 0.0
	for line: String in lines:
		print(line)
		cleared += _rows_cleared(line)
	print("\nplan %s, fire %s, %s: %.1f rows cleared per run (of %d)" % [_plan_name, _fire if _fire != "" else "as drawn",
		"chapter 1 protected" if _protect_ch1 else "whole runs", cleared / maxf(lines.size(), 1.0), ROWS_PER_CHAPTER * 2])
	print("\n%-22s %8s %6s" % ["relic", "offered", "taken"])
	for id: StringName in RELIC_PREFERENCE:
		var counts: Array = _relic_counts.get(id, [0, 0])
		print("%-22s %8d %6d" % [id, counts[0], counts[1]])
	quit()


func _play(seed_value: int) -> String:
	if _first_kit:
		(root.get_node("SaveManager") as SaveManagerNode).profile = SaveProfile.new()
	(root.get_node("SaveManager") as SaveManagerNode).profile.hero = _hero_kind
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
			plan = _steps(_plan_for(level.scene_file_path.get_file().get_basename()))
			next = 0
			_set_fire(level, chapter == 0)
			_set_relics(level, chapter == 0)
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
		if _early and cycle.can_call_early():
			cycle.call_early()
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


## The plan's builds on this level: a hand-made one, "all <tower>" or "braziers first".
func _plan_for(level_name: String) -> Array:
	if HERO_PLANS.has(_hero_kind) and _plan_name == "mixed":
		return HERO_PLANS[_hero_kind][level_name]
	if PLANS.has(_plan_name):
		return PLANS[_plan_name][level_name]
	var mixed: Array = PLANS["mixed"][level_name]
	var builds: Array = []
	for i: int in mixed.size():
		var tower: String = mixed[i][0]
		if _plan_name.begins_with("all "):
			tower = _plan_name.trim_prefix("all ")
		elif _plan_name == "braziers first" and i < 3:
			tower = "brazier"
		builds.append([tower, mixed[i][1]])
	return builds


## --fire: grant the fire cards and relic (once, at the run's start) or keep them out of every offer.
func _set_fire(level: Level, run_start: bool) -> void:
	if _fire == "with" and run_start:
		for path: String in FIRE_CARDS:
			level.modifiers.add_upgrade(load(path))
	elif _fire == "without":
		var fire: Array[UpgradeData] = []
		for path: String in FIRE_CARDS:
			fire.append(load(path))
		level.offers.pool = level.offers.pool.filter(func(d: UpgradeData) -> bool: return not fire.has(d))
		level.offers.relic_pool = level.offers.relic_pool.filter(func(d: RelicData) -> bool: return not fire.has(d))


## --relics: grant the given relics (once, at the run's start) and offer no other.
func _set_relics(level: Level, run_start: bool) -> void:
	if _relics == null:
		return
	level.offers.relic_pool = []
	if run_start:
		for id: String in _relics:
			level.modifiers.add_upgrade(load("res://data/relics/%s.tres" % id))


## Rows cleared in a run's summary line: every row of both chapters if won, else the rows before the
## one it fell in.
func _rows_cleared(line: String) -> float:
	if line.contains("WON"):
		return ROWS_PER_CHAPTER * 2.0
	var found: RegExMatch = RegEx.create_from_string("lost c(\\d) row (\\d)").search(line)
	if found == null:
		return 0.0
	return (int(found.get_string(1)) - 1) * ROWS_PER_CHAPTER + int(found.get_string(2)) - 1.0


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
			if not builder.catalog.any(func(d: TowerData) -> bool: return String(d.id) == step[0]):
				return next + 1  # not in this run's kit (--profile=first): skip it
			for data: TowerData in builder.catalog:
				if String(data.id) == step[0] and economy.can_afford(builder.build_cost(data)) and builder.build(slot, data):
					return next + 1
	return next


func _sinks(level: Level) -> void:
	var shop: Quartermaster = level.get_node("%Quartermaster")
	shop.buy_life()
	if level.fortress.health.current_health < level.fortress.health.max_health * REPAIR_BELOW:
		shop.repair()


func _card(cards: Array[UpgradeData]) -> int:
	if _archetype != &"":
		for i: int in cards.size():
			if cards[i].tags.has(_archetype):
				return i
	for i: int in cards.size():
		if cards[i].category == UpgradeData.Category.TOWERS:
			return i
	return 0


## The offered relic highest in RELIC_PREFERENCE (counted as offered and taken).
func _relic_pick(offer: Array[UpgradeData]) -> int:
	var best: int = 0
	for i: int in offer.size():
		_count_relic(offer[i].id, 0)
		if _archetype != &"" and offer[i].tags.has(_archetype) and not offer[best].tags.has(_archetype):
			best = i
			continue
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
