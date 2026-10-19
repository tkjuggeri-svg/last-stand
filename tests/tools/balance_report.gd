extends SceneTree
## Plays one full spawner wave (10 ghouls) per tower setup with an idle hero and prints what happened:
## kills, leaks, fortress HP, gold. A tuning aid, not a pass/fail test.
##   godot --headless --fixed-fps 60 --path . --script res://tests/tools/balance_report.gd
## Setups buy towers as soon as the gold allows (in the listed order), like a player would.

const ARENA: String = "res://levels/prototype_arena.tscn"
const SETUPS: Dictionary = {
	"no towers": [],
	"archer": [["archer", 0]],
	"cannon": [["cannon", 2]],
	"frost": [["frost", 3]],
	"archer, then archer": [["archer", 0], ["archer", 3]],
	"archer, then frost": [["archer", 0], ["frost", 3]],
	"archer, frost, cannon": [["archer", 0], ["frost", 3], ["cannon", 2]],
}


func _initialize() -> void:
	print("%-24s %5s %5s %9s %6s %6s %s" % ["setup", "kills", "leaks", "fortress", "gold", "bonus", "built"])
	for setup_name: String in SETUPS:
		await _play(setup_name, SETUPS[setup_name])
	quit()


func _play(setup_name: String, plan: Array) -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("Hero") as Node2D).position = Vector2(-750, 330)  # idle, away from the lane
	root.add_child(level)
	await WaveFixtures.start_wave(level)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var economy: Economy = level.get_node("%Economy")
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var rewards: WaveRewards = level.get_node("%WaveRewards")
	var fortress: Fortress = level.get_node("Fortress")
	var stats: Dictionary = {"kills": 0, "leaks": 0, "bonus": 0, "cleared": false}
	spawner.enemy_killed.connect(func(_e: Enemy) -> void: stats["kills"] += 1)
	spawner.enemy_reached_fortress.connect(func(_e: Enemy) -> void: stats["leaks"] += 1)
	spawner.wave_cleared.connect(func(_wave: int) -> void: stats["cleared"] = true)
	rewards.perfect_defense_awarded.connect(func(b: int) -> void: stats["bonus"] = b)
	var catalog: Dictionary = {}
	for data: TowerData in builder.catalog:
		catalog[String(data.id)] = data
	var next: int = 0
	var built: Array[String] = []
	for _i: int in 60 * 60:
		await physics_frame
		if next < plan.size():
			var step: Array = plan[next]
			var data: TowerData = catalog[step[0]]
			if economy.can_afford(data.cost) and builder.build(builder.get_slots()[step[1]], data):
				built.append("%s@%.0fs" % [step[0], _i / 60.0])
				next += 1
		if stats["cleared"] or fortress.health.is_dead():
			break
	print("%-24s %5d %5d %9d %6d %6d %s" % [setup_name, stats["kills"], stats["leaks"],
		fortress.health.current_health, economy.get_gold(), stats["bonus"], ", ".join(built)])
	level.queue_free()
	for _i: int in 2:
		await physics_frame
