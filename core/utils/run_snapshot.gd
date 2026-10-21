class_name RunSnapshot
## The state of a run at one moment, as plain data (for a feedback report): the build, the run's seed,
## the chapter and map node, the screen, the wave, gold, the fortress, the hero, every tower (level,
## evolution, gold in it), the cards and relics taken, the twists waiting for the next fights.
## Reads only; nothing here changes the game.


## Everything worth knowing about the run now. `level` may be null (between runs), `node` too.
static func capture(run: RunStateNode, level: Level, node: MapNode, screen: String) -> Dictionary:
	var state: Dictionary = {"time": Time.get_datetime_string_from_system(), "build": build_version(), "screen": screen}
	if run != null:
		state["seed"] = run.seed_value
		state["chapter"] = run.chapter_index + 1
		state["chapter_name"] = run.get_chapter().display_name if run.get_chapter() != null else ""
		if run.map != null:
			state["map_path"] = run.map.path.map(func(n: MapNode) -> String: return "%s@row%d" % [RunMap.Kind.keys()[n.kind].to_lower(), n.row])
	if node != null:
		state["node"] = {"row": node.row, "kind": RunMap.Kind.keys()[node.kind].to_lower(),
			"encounter": node.encounter.resource_path.get_file() if node.encounter != null else "",
			"affix": node.affix.display_name if node.affix != null else "",
			"event": node.event.title if node.event != null else ""}
	if level != null:
		state.merge(_level_state(level))
	return state


## The version written next to the game by tools/build_playtest.sh (BUILD_INFO.txt), else "dev".
static func build_version() -> String:
	var info: String = OS.get_executable_path().get_base_dir().path_join("BUILD_INFO.txt")
	if not OS.has_feature("editor") and FileAccess.file_exists(info):
		for line: String in FileAccess.get_file_as_string(info).split("\n"):
			if line.begins_with("Version:"):
				return line.trim_prefix("Version:").strip_edges()
	return "dev"


static func _level_state(level: Level) -> Dictionary:
	var state: Dictionary = {"level": level.scene_file_path.get_file().get_basename()}
	if level.run_cycle != null:
		state["wave"] = level.run_cycle.get_current_wave_number()
		state["waves_in_fight"] = level.run_cycle.get_wave_count()
		state["phase"] = RunCycle.Phase.keys()[level.run_cycle.get_phase()].to_lower()
	if level.spawner != null:
		state["enemies_left"] = level.spawner.get_remaining_count()
	state["gold"] = level.economy.get_gold() if level.economy != null else 0
	var fortress: HealthComponent = level.fortress.health
	state["fortress"] = {"hp": fortress.current_health, "max": fortress.max_health}
	if level.hero_lives != null:
		state["lives"] = {"left": level.hero_lives.get_lives_left(), "max": level.hero_lives.get_max_lives()}
	var hero: Hero = level.get_node_or_null("Hero") as Hero
	if hero != null:
		state["hero"] = {"hp": hero.health.current_health, "max": hero.health.max_health,
			"position": [roundi(hero.global_position.x), roundi(hero.global_position.y)]}
	var towers: Array[Dictionary] = []
	if level.builder != null:
		var slots: Array[BuildSlot] = level.builder.get_slots()
		for i: int in slots.size():
			if not slots[i].is_empty():
				var tower: Tower = slots[i].tower
				towers.append({"slot": i, "tower": String(tower.data.id), "level": tower.get_level(),
					"evolution": String(tower.get_evolution().id) if tower.get_evolution() != null else "", "invested": tower.invested})
	state["towers"] = towers
	if level.modifiers != null:
		var cards: Dictionary = {}
		for data: UpgradeData in level.modifiers.get_taken():
			if not data is RelicData:
				cards[String(data.id)] = level.modifiers.get_stacks(data.id)
		state["cards"] = cards
		state["relics"] = level.modifiers.get_relics().map(func(r: RelicData) -> String: return String(r.id))
	if level.events != null:
		state["next_fight_twists"] = level.events.get_pending_affixes().map(func(a: AffixData) -> String: return a.display_name)
	return state
