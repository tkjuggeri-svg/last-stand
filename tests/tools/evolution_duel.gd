extends SceneTree
## Compares tower evolutions on equal terms (a tuning aid, not a pass/fail test): the "all five" defence
## of the balance tool, every tower at level 3, plays the run's late waves (10-15) against a fortress
## that can't fall, with the hero parked. Once with no evolution, then once per branch with only the
## towers of that type evolved into it. Prints the damage that got through (fortress HP lost) and the
## leaks per variant; fewer is better. Both branches of a tower should land close to each other.
## One run is chaotic (a small change can swing it by ~15%), so --layout=k plays the plan with its tower
## types rotated k places along the slots; compare sums over layouts 0, 1 and 2.
##   godot --headless --fixed-fps 60 --path . --script res://tests/tools/evolution_duel.gd [-- --from=10] [--layout=0]

const ARENA: String = "res://levels/prototype_arena.tscn"
## The balance tool's "all five" plan: [tower, slot].
const PLAN: Array = [["archer", 4], ["ballista", 9], ["brazier", 7], ["archer", 8], ["cannon", 5], ["brazier", 2],
	["frost", 6], ["ballista", 0], ["archer", 3], ["cannon", 1]]
const HERO_PARKED: Vector2 = Vector2(380, 380)
const FORTRESS_HP: int = 100000

var _from: int = 10
var _layout: int = 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--from="):
			_from = int(arg.trim_prefix("--from="))
		elif arg.begins_with("--layout="):
			_layout = int(arg.trim_prefix("--layout="))
	var lines: Array[String] = [await _play("", -1)]
	for tower_id: String in ["archer", "cannon", "frost", "brazier", "ballista"]:
		for branch: int in 2:
			lines.append(await _play(tower_id, branch))
	print("\n%-24s %8s %6s" % ["variant", "hp lost", "leaks"])
	for line: String in lines:
		print(line)
	quit()


func _play(tower_id: String, branch: int) -> String:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("Hero") as Node2D).position = HERO_PARKED
	WaveFixtures.no_upgrades(level)
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = spawner.waves.slice(_from - 1)
	root.add_child(level)
	await physics_frame
	var fortress: Fortress = level.get_node("Fortress")
	fortress.health.setup(FORTRESS_HP)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var economy: Economy = level.get_node("%Economy")
	economy.earn(1000000, Economy.Source.REFUND)
	var catalog: Dictionary = {}
	for data: TowerData in builder.catalog:
		catalog[String(data.id)] = data
	var plan: Array = []
	for i: int in PLAN.size():
		plan.append([PLAN[(i + _layout * 3) % PLAN.size()][0], PLAN[i][1]])
	for entry: Array in plan:
		builder.build(builder.get_slots()[entry[1]], catalog[entry[0]])
	for _i: int in 90:
		await physics_frame
	var name: String = "level 3, no evolution"
	for entry: Array in plan:
		var slot: BuildSlot = builder.get_slots()[entry[1]]
		builder.upgrade(slot)
		builder.upgrade(slot)
		if entry[0] == tower_id:
			builder.evolve(slot, branch)
			name = String((catalog[tower_id] as TowerData).evolutions[branch].id)
	var leaks: Array[int] = [0]
	spawner.enemy_reached_fortress.connect(func(_e: Enemy) -> void: leaks[0] += 1)
	var cycle: RunCycle = level.get_node("%RunCycle")
	for _i: int in 60 * 60 * 20:
		await physics_frame
		if cycle.get_phase() == RunCycle.Phase.BUILD:
			cycle.start_wave()
		if cycle.get_phase() == RunCycle.Phase.FINISHED:
			break
	var line: String = "%-24s %8d %6d" % [name, FORTRESS_HP - fortress.health.current_health, leaks[0]]
	print(line)
	level.queue_free()
	for _i: int in 2:
		await physics_frame
	return line
