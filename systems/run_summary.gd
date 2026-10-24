class_name RunSummary
extends RefCounted
## A finished run as plain data (M8): how it ended and how far it got, the fights it won (battles,
## elites, bosses), the chapters cleared, its path, cards and relics, kills, waves and time. MetaProgress
## pays shards for it; the run summary screen and the hub's records show it; the profile keeps the last
## ones. Built from RunState and the chapter's level when the run ends.


## `result`: "won", "lost" or "abandoned".
static func build(run: RunStateNode, level: Level, result: String) -> Dictionary:
	var battles: int = 0
	var elites: int = 0
	var bosses: Array[String] = []
	for fight: Dictionary in run.cleared:
		match String(fight.get("kind", "")):
			"battle":
				battles += 1
			"elite":
				elites += 1
			"boss":
				bosses.append(String(fight.get("boss", "a boss")))
	var node: MapNode = run.map.get_current() if run.map != null else null
	var summary: Dictionary = {"result": result, "seed": run.seed_value,
		"hero": String(run.hero.id) if run.hero != null else "", "chapter": run.chapter_index + 1,
		"row": node.row if node != null else 0, "battles": battles, "elites": elites, "bosses": bosses,
		"chapters_cleared": run.chapter_index + (1 if result == "won" else 0),
		"path": run.map.path.map(func(n: MapNode) -> String: return RunMap.Kind.keys()[n.kind].to_lower()) if run.map != null else [],
		"kills": run.kills, "waves": run.waves, "minutes": snappedf((Time.get_ticks_msec() - run.started_msec) / 60000.0, 0.1),
		"cards": [], "relics": []}
	if level != null and level.modifiers != null:
		summary["cards"] = level.modifiers.get_taken().filter(func(d: UpgradeData) -> bool: return not d is RelicData).map(
			func(d: UpgradeData) -> String: return String(d.id))
		summary["relics"] = level.modifiers.get_relics().map(func(r: RelicData) -> String: return String(r.id))
	return summary


## The boss of `encounter` (a boss fight's own boss, or an elite's leader): its name, for the records.
static func boss_name(encounter: EncounterData) -> String:
	if encounter == null:
		return "a boss"
	for wave: WaveData in encounter.waves:
		for group: SpawnGroup in wave.groups:
			if group.enemy != null and group.enemy.is_boss:
				return group.enemy.display_name
	return encounter.leader.display_name if encounter.leader != null else "a boss"
