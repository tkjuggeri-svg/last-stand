extends SceneTree
## Plays the level's whole run (all waves) and prints what happened per wave and per run: kills,
## leaks, fortress HP, gold, hero falls, the upgrades taken and the run's length. A tuning aid, not a
## pass/fail test.
##   godot --headless --fixed-fps 60 --path . --script res://tests/tools/balance_report.gd
##     [-- --plan=mixed] [--policy=towers] [--seed=1] [--hero=idle|bot|both] [--sweep] [--quiet] [--gold]
##     [--evolve=none|early|late] [--branch=a|b|random|only:<tower>:<a|b>]
## --hero: "idle" parks the hero out of every fight; "bot" plays it with HeroBot (hero_bot.gd: walks
## to the nearest enemy on the busiest lane, swings, dashes away at low HP); "both" (default) runs each.
## The bot buys the plan's towers and tower upgrades in order as soon as the gold allows (any phase),
## starts each wave after BUILD_SECONDS of build phase, and takes run upgrades by a policy. In the
## build phase it first buys back a lost life, and repairs the fortress while it is below
## REPAIR_BELOW of its max HP (the Quartermaster's gold sinks), when the gold allows. Upgrade policies:
##   none: no run upgrades at all (the offers are switched off) - the baseline;
##   towers / economy / fortress / hero: the first card of that category, else by POLICY_FALLBACK;
##   random: any card (seeded). The "hero" policy only runs with the bot hero.
## --sweep: the "mixed" plan once per upgrade, with only that upgrade (given before wave 1, no offers):
## how much each one is worth on its own (with the first --hero mode).
## --evolve=early: the bot evolves each tower right after taking it to level 3 (as soon as the gold
## allows); late: only once every tower is at level 3, in build order. Into branch --branch (a = the first, b = the second, random = seeded per tower; only:<id>:<a|b>
## evolves only the towers of that type, into that branch). The summary then counts the picks.
## --gold: after each run, its gold ledger (gold_ledger.gd): income per wave by source (kills per enemy
## type, each kill-gold upgrade, perfect defense, interest, refunds), spending by category, the bank.
## Slots: 0-5 along the west crypt road, 6-7 by the north-east road, 8 by the south road, 9 where the
## north-east and south roads reach the fortress.

const ARENA: String = "res://levels/prototype_arena.tscn"
const UPGRADES_DIR: String = "res://data/upgrades"
const HeroBot: GDScript = preload("res://tests/tools/hero_bot.gd")
const GoldLedger: GDScript = preload("res://tests/tools/gold_ledger.gd")
const BUILD_SECONDS: float = 5.0
## A player's build phase and upgrade choice take longer than the bot's: the run length is also
## estimated with this many seconds per wave between the waves.
const PLAYER_BREAK_SECONDS: float = 30.0
## Out of every lane's way, so the hero is never attacked.
const HERO_PARKED: Vector2 = Vector2(380, 380)
## Tower builds per plan ([tower, slot]) in order. The bot builds the first EARLY_BUILDS, takes those
## to level 2, builds the rest, takes those to level 2, then takes everything to level 3, buying each
## step as soon as the gold allows.
const PLANS: Dictionary = {
	"archers + cannons": [["archer", 4], ["archer", 9], ["cannon", 7], ["cannon", 8], ["archer", 5], ["cannon", 2],
		["archer", 6], ["cannon", 0], ["archer", 3], ["cannon", 1]],
	"mixed": [["archer", 4], ["archer", 9], ["cannon", 7], ["frost", 8], ["cannon", 5], ["archer", 2],
		["frost", 6], ["cannon", 0], ["archer", 3], ["cannon", 1]],
	"all five": [["archer", 4], ["ballista", 9], ["brazier", 7], ["archer", 8], ["cannon", 5], ["brazier", 2],
		["frost", 6], ["ballista", 0], ["archer", 3], ["cannon", 1]],
}
const EARLY_BUILDS: int = 6
## Repair the fortress (between waves) while its HP is below this share of the max.
const REPAIR_BELOW: float = 0.5
const POLICIES: Array[String] = ["none", "towers", "economy", "fortress", "hero", "random"]
const POLICY_CATEGORY: Dictionary = {
	"towers": UpgradeData.Category.TOWERS,
	"economy": UpgradeData.Category.ECONOMY,
	"fortress": UpgradeData.Category.FORTRESS,
	"hero": UpgradeData.Category.HERO,
}
## When no card of the policy's category is offered: the next best category for an idle-hero bot.
const POLICY_FALLBACK: Array[int] = [UpgradeData.Category.TOWERS, UpgradeData.Category.ECONOMY,
	UpgradeData.Category.FORTRESS, UpgradeData.Category.HERO]

var _seed: int = 1
var _quiet: bool = false
var _gold: bool = false
var _evolve: String = "none"
var _branch: String = "random"
## Evolutions bought over all runs, by id; and in won runs.
var _picks: Dictionary = {}
var _won_picks: Dictionary = {}
var _heroes: Array[String] = ["idle", "bot"]


func _initialize() -> void:
	var only_plan: String = ""
	var only_policy: String = ""
	var sweep: bool = false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--plan="):
			only_plan = arg.trim_prefix("--plan=")
		elif arg.begins_with("--policy="):
			only_policy = arg.trim_prefix("--policy=")
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg == "--sweep":
			sweep = true
		elif arg == "--quiet":
			_quiet = true
		elif arg == "--gold":
			_gold = true
		elif arg.begins_with("--evolve="):
			_evolve = arg.trim_prefix("--evolve=")
		elif arg.begins_with("--branch="):
			_branch = arg.trim_prefix("--branch=")
		elif arg.begins_with("--hero="):
			var hero_mode: String = arg.trim_prefix("--hero=")
			_heroes.clear()
			_heroes.append_array(["idle", "bot"] if hero_mode == "both" else [hero_mode])
	var summary: Array[String] = []
	if sweep:
		summary.append(await _play("mixed", PLANS["mixed"], "none", null, _heroes[0]))
		for file: String in DirAccess.get_files_at(UPGRADES_DIR):
			if file.ends_with(".tres"):
				var data: UpgradeData = load(UPGRADES_DIR.path_join(file))
				summary.append(await _play("mixed", PLANS["mixed"], "only " + String(data.id), data, _heroes[0]))
	else:
		for plan_name: String in PLANS:
			if not only_plan.is_empty() and only_plan != plan_name:
				continue
			for hero_mode: String in _heroes:
				for policy: String in POLICIES:
					if policy == "hero" and hero_mode == "idle":
						continue
					if only_policy.is_empty() or only_policy == policy:
						summary.append(await _play(plan_name, PLANS[plan_name], policy, null, hero_mode))
	print("\n%-18s %-5s %-14s %-24s %8s %5s %5s %5s %6s %5s %6s %6s %7s  %s" % ["plan", "hero", "upgrades", "result", "fortress",
		"falls", "kills", "leaks", "levels", "gold", "income", "fights", "w/break", "taken"])
	for line: String in summary:
		print(line)
	if _evolve != "none":
		print("\nevolutions bought (in all runs / in won runs):")
		for id: String in _picks:
			print("  %-18s %3d / %3d" % [id, _picks[id], int(_won_picks.get(id, 0))])
	quit()


## The plan as buy steps: [tower, slot] builds and ["up", slot] upgrades, in buying order.
func _steps(builds: Array) -> Array:
	var steps: Array = []
	var early: Array = builds.slice(0, EARLY_BUILDS)
	var late: Array = builds.slice(EARLY_BUILDS)
	steps.append_array(early)
	for build: Array in early:
		steps.append(["up", build[1]])
	for build: Array in late:
		steps.append(build)
		steps.append(["up", build[1]])
	for build: Array in builds:
		steps.append(["up", build[1]])
		if _evolve == "early":
			steps.append(["evo", build[1], build[0]])
	if _evolve == "late":
		for build: Array in builds:
			steps.append(["evo", build[1], build[0]])
	return steps


func _play(plan_name: String, builds: Array, policy: String, only: UpgradeData, hero_mode: String) -> String:
	var plan: Array = _steps(builds)
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	if hero_mode == "idle":
		(level.get_node("Hero") as Node2D).position = HERO_PARKED
	var offers: UpgradeOffers = level.get_node("%UpgradeOffers")
	offers.seed_value = _seed
	if policy == "none" or only != null:
		offers.pool = []
	root.add_child(level)
	await physics_frame
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var economy: Economy = level.get_node("%Economy")
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var cycle: RunCycle = level.get_node("%RunCycle")
	var fortress: Fortress = level.get_node("Fortress")
	var mods: RunModifiers = level.get_node("%RunModifiers")
	var shop: Quartermaster = level.get_node("%Quartermaster")
	if only != null:
		mods.add_upgrade(only)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _seed
	var hero: Hero = level.get_node("Hero")
	var bot: RefCounted = HeroBot.new(hero, spawner) if hero_mode == "bot" else null
	var ledger: RefCounted = GoldLedger.new(level)
	var stats: Dictionary = {"kills": 0, "leaks": 0, "wave_kills": 0, "wave_leaks": 0, "won": false, "lost": false,
		"falls": 0, "combat": 0.0, "reason": ""}
	hero.died.connect(func() -> void: stats["falls"] += 1)
	spawner.enemy_killed.connect(func(_e: Enemy) -> void:
		stats["kills"] += 1
		stats["wave_kills"] += 1)
	spawner.enemy_reached_fortress.connect(func(_e: Enemy) -> void:
		stats["leaks"] += 1
		stats["wave_leaks"] += 1)
	level.run_won.connect(func() -> void: stats["won"] = true)
	level.run_lost.connect(func(r: Level.LossReason) -> void:
		stats["lost"] = true
		stats["reason"] = "fort" if r == Level.LossReason.FORTRESS_DESTROYED else "hero")
	spawner.wave_cleared.connect(func(n: int) -> void:
		if not _quiet:
			print("  %-18s %-5s %-10s wave %2d: %3d killed, %2d leaked, fortress %3d, gold %4d, hero falls %d, %.0f s of fighting" % [plan_name,
				hero_mode, policy, n, stats["wave_kills"], stats["wave_leaks"], fortress.health.current_health, economy.get_gold(),
				stats["falls"], stats["combat"]])
		stats["wave_kills"] = 0
		stats["wave_leaks"] = 0)
	var catalog: Dictionary = {}
	for data: TowerData in builder.catalog:
		catalog[String(data.id)] = data
	var next: int = 0
	var build_time: float = 0.0
	var evolved: Array[String] = []
	for _i: int in 60 * 60 * 45:
		await physics_frame
		if bot != null:
			bot.call("step", mods)
		if cycle.get_phase() == RunCycle.Phase.COMBAT:
			stats["combat"] += 1.0 / 60.0
		if cycle.get_phase() == RunCycle.Phase.BUILD:
			_use_sinks(shop, fortress, ledger)
		if next < plan.size():
			var step: Array = plan[next]
			var slot: BuildSlot = builder.get_slots()[step[1]]
			if step[0] == "evo":
				var picked: String = _try_evolve(builder, economy, slot, step[2], ledger)
				if picked != "-":
					next += 1
					if not picked.is_empty():
						evolved.append(picked)
			elif step[0] == "up":
				var cost: int = builder.upgrade_cost(slot)
				if cost < 0:
					next += 1
				elif economy.can_afford(cost) and not slot.tower.is_building() and builder.upgrade(slot):
					next += 1
					ledger.call("spend", "upgrades", cost)
					var full: int = slot.tower.data.upgrade_cost(slot.tower.get_level())
					if full > cost:
						ledger.call("saved", "guild", full - cost)
			else:
				var data: TowerData = catalog[step[0]]
				if economy.can_afford(data.cost) and builder.build(slot, data):
					next += 1
					ledger.call("spend", "towers", data.cost)
		if cycle.get_phase() == RunCycle.Phase.CHOOSE:
			offers.pick(_choose(offers.get_offer(), policy, rng))
		if cycle.get_phase() == RunCycle.Phase.BUILD:
			build_time += 1.0 / 60.0
			if build_time >= BUILD_SECONDS:
				build_time = 0.0
				cycle.start_wave()
		if stats["won"] or stats["lost"]:
			break
	if bot != null:
		bot.call("release")
	var result: String = "WON" if stats["won"] else "lost w%d (%s)" % [spawner.get_wave_number(), stats["reason"]]
	for id: String in evolved:
		_picks[id] = int(_picks.get(id, 0)) + 1
		if stats["won"]:
			_won_picks[id] = int(_won_picks.get(id, 0)) + 1
	var levels: int = 0
	for slot: BuildSlot in builder.get_slots():
		if not slot.is_empty():
			levels += slot.tower.get_level()
	var taken: Array[String] = []
	for data: UpgradeData in mods.get_taken():
		taken.append(String(data.id))
	var waves_played: int = spawner.get_wave_number()
	var line: String = "%-18s %-5s %-14s %-24s %8d %5d %5d %5d %6d %5d %6d %5.1fm %6.1fm  %s" % [plan_name, hero_mode, policy, result,
		fortress.health.current_health, stats["falls"], stats["kills"], stats["leaks"], levels, economy.get_gold(),
		economy.get_gold() + int(ledger.call("total", "spent:")) - economy.starting_gold,
		stats["combat"] / 60.0, (stats["combat"] + waves_played * PLAYER_BREAK_SECONDS) / 60.0,
		("evolved: %s | " % ", ".join(evolved) if not evolved.is_empty() else "") + ", ".join(taken)]
	if _gold:
		for ledger_line: String in ledger.call("report", "%s / %s / %s hero: %s" % [plan_name, policy, hero_mode, result]):
			print(ledger_line)
	level.queue_free()
	for _i: int in 2:
		await physics_frame
	return line


func _use_sinks(shop: Quartermaster, fortress: Fortress, ledger: RefCounted) -> void:
	var cost: int = shop.life_cost()
	if shop.buy_life():
		ledger.call("spend", "lives", cost)
	cost = shop.repair_cost()
	if fortress.health.current_health < fortress.health.max_health * REPAIR_BELOW and shop.repair():
		ledger.call("spend", "repairs", cost)


## Evolves the slot's tower by the --branch rule once the gold allows. Returns the evolution's id,
## "" when there is nothing to do (not this tower type, gone, already evolved), "-" to wait for gold.
func _try_evolve(builder: TowerBuilder, economy: Economy, slot: BuildSlot, tower_id: String, ledger: RefCounted) -> String:
	var options: Array[TowerEvolution] = builder.evolution_options(slot)
	if options.is_empty():
		return ""
	var index: int = 0
	if _branch == "b":
		index = 1
	elif _branch == "random":
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = _seed * 31 + slot.get_index()
		index = rng.randi_range(0, 1)
	elif _branch.begins_with("only:"):
		var parts: PackedStringArray = _branch.split(":")
		if parts[1] != tower_id:
			return ""
		index = 0 if parts[2] == "a" else 1
	var cost: int = builder.evolution_cost(options[index])
	if not economy.can_afford(cost) or slot.tower.is_building() or not builder.evolve(slot, index):
		return "-"
	ledger.call("spend", "evolutions", cost)
	return String(options[index].id)


## The card index the policy takes.
func _choose(cards: Array[UpgradeData], policy: String, rng: RandomNumberGenerator) -> int:
	if policy == "random":
		return rng.randi_range(0, cards.size() - 1)
	var order: Array[int] = []
	if POLICY_CATEGORY.has(policy):
		order.append(POLICY_CATEGORY[policy])
	for category: int in POLICY_FALLBACK:
		if not order.has(category):
			order.append(category)
	for category: int in order:
		var best: int = -1
		for i: int in cards.size():
			if cards[i].category == category and (best < 0 or cards[i].rarity > cards[best].rarity):
				best = i
		if best >= 0:
			return best
	return 0
