extends SceneTree
## Plays the level's whole run (all waves) once per tower plan, with an idle hero, and prints what
## happened per wave and per run: kills, leaks, fortress HP, gold. A tuning aid, not a pass/fail test.
##   godot --headless --fixed-fps 60 --path . --script res://tests/tools/balance_report.gd [-- --plan=mixed]
## The bot buys the plan's towers and upgrades in order as soon as the gold allows (any phase),
## and starts each wave after BUILD_SECONDS of build phase. The hero never fights, so these numbers are
## a floor: a player who fights with the hero does better.
## Slots: 0-5 along the west crypt road, 6-7 by the north-east road, 8 by the south road, 9 where the
## north-east and south roads reach the fortress.

const ARENA: String = "res://levels/prototype_arena.tscn"
const BUILD_SECONDS: float = 5.0
## Out of every lane's way, so the hero is never attacked.
const HERO_PARKED: Vector2 = Vector2(380, 380)
## Tower builds per plan ([tower, slot]) in order. The bot builds the first EARLY_BUILDS, takes those
## to level 2, builds the rest, takes those to level 2, then takes everything to level 3, buying each
## step as soon as the gold allows.
const PLANS: Dictionary = {
	"no towers": [],
	"archers": [["archer", 4], ["archer", 9], ["archer", 7], ["archer", 8], ["archer", 5], ["archer", 2],
		["archer", 6], ["archer", 0], ["archer", 3], ["archer", 1]],
	"cannons": [["cannon", 4], ["cannon", 9], ["cannon", 7], ["cannon", 8], ["cannon", 5], ["cannon", 2],
		["cannon", 6], ["cannon", 0], ["cannon", 3], ["cannon", 1]],
	"frost + archers": [["archer", 4], ["frost", 9], ["archer", 7], ["frost", 8], ["archer", 5], ["frost", 2],
		["archer", 6], ["frost", 0], ["archer", 3], ["frost", 1]],
	"archers + cannons": [["archer", 4], ["archer", 9], ["cannon", 7], ["cannon", 8], ["archer", 5], ["cannon", 2],
		["archer", 6], ["cannon", 0], ["archer", 3], ["cannon", 1]],
	"mixed": [["archer", 4], ["archer", 9], ["cannon", 7], ["frost", 8], ["cannon", 5], ["archer", 2],
		["frost", 6], ["cannon", 0], ["archer", 3], ["cannon", 1]],
}
const EARLY_BUILDS: int = 6


func _initialize() -> void:
	var only: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--plan="):
			only = arg.trim_prefix("--plan=")
	var summary: Array[String] = []
	for plan_name: String in PLANS:
		if only.is_empty() or only == plan_name:
			summary.append(await _play(plan_name, PLANS[plan_name]))
	print("\n%-18s %-16s %8s %6s %6s %7s %7s %6s" % ["plan", "result", "fortress", "kills", "leaks", "towers", "levels", "gold"])
	for line: String in summary:
		print(line)
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
	return steps


func _play(plan_name: String, builds: Array) -> String:
	var plan: Array = _steps(builds)
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("Hero") as Node2D).position = HERO_PARKED
	root.add_child(level)
	await physics_frame
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var economy: Economy = level.get_node("%Economy")
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var cycle: RunCycle = level.get_node("%RunCycle")
	var fortress: Fortress = level.get_node("Fortress")
	var stats: Dictionary = {"kills": 0, "leaks": 0, "wave_kills": 0, "wave_leaks": 0, "won": false, "lost": false}
	spawner.enemy_killed.connect(func(_e: Enemy) -> void:
		stats["kills"] += 1
		stats["wave_kills"] += 1)
	spawner.enemy_reached_fortress.connect(func(_e: Enemy) -> void:
		stats["leaks"] += 1
		stats["wave_leaks"] += 1)
	level.run_won.connect(func() -> void: stats["won"] = true)
	level.run_lost.connect(func(_r: Level.LossReason) -> void: stats["lost"] = true)
	spawner.wave_cleared.connect(func(n: int) -> void:
		print("  %-18s wave %2d: %2d killed, %2d leaked, fortress %3d, gold %4d, towers %d" % [plan_name, n,
			stats["wave_kills"], stats["wave_leaks"], fortress.health.current_health, economy.get_gold(),
			builder.get_slots().size() - builder.get_free_slot_count()])
		stats["wave_kills"] = 0
		stats["wave_leaks"] = 0)
	var catalog: Dictionary = {}
	for data: TowerData in builder.catalog:
		catalog[String(data.id)] = data
	var next: int = 0
	var build_time: float = 0.0
	for _i: int in 60 * 60 * 20:
		await physics_frame
		if next < plan.size():
			var step: Array = plan[next]
			var slot: BuildSlot = builder.get_slots()[step[1]]
			if step[0] == "up":
				var cost: int = builder.upgrade_cost(slot)
				if cost < 0 or (economy.can_afford(cost) and not slot.tower.is_building() and builder.upgrade(slot)):
					next += 1
			else:
				var data: TowerData = catalog[step[0]]
				if economy.can_afford(data.cost) and builder.build(slot, data):
					next += 1
		if cycle.get_phase() == RunCycle.Phase.BUILD:
			build_time += 1.0 / 60.0
			if build_time >= BUILD_SECONDS:
				build_time = 0.0
				cycle.start_wave()
		if stats["won"] or stats["lost"]:
			break
	var result: String = "WON" if stats["won"] else "lost in wave %d" % spawner.get_wave_number()
	var towers: int = 0
	var levels: int = 0
	for slot: BuildSlot in builder.get_slots():
		if not slot.is_empty():
			towers += 1
			levels += slot.tower.get_level()
	var line: String = "%-18s %-16s %8d %6d %6d %7d %7d %6d" % [plan_name, result, fortress.health.current_health,
		stats["kills"], stats["leaks"], towers, levels, economy.get_gold()]
	level.queue_free()
	for _i: int in 2:
		await physics_frame
	return line
