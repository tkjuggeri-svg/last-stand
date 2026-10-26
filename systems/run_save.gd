class_name RunSave
## A run saved at the map (M8: Continue on the title resumes it there; a fight in progress is played
## again from its start). capture() writes what the run and the chapter's level hold between nodes
## into a plain dictionary for SaveProfile.run: the seed, the chapter, the path taken, the fights won,
## kills, waves and time; the gold, the cards and relics in the order taken, the lives, the fortress's
## HP, every tower (slot, kind, level, evolution, gold in it) and the systems' own state (the dice of
## the offers and the events, rerolls, twists still due, an event's merchant price, the Quartermaster's
## purchases). Resources are kept by path; one that no longer exists is skipped. restore_run() and
## restore_level() put it back: the map is made again from the seed and the path walked again.

## The saved run's format (a run saved by another format is not resumed).
const VERSION: int = 1


static func capture(run: RunStateNode, level: Level) -> Dictionary:
	var towers: Array[Dictionary] = []
	var slots: Array[BuildSlot] = level.builder.get_slots()
	for i: int in slots.size():
		var tower: Tower = slots[i].tower
		if tower != null:
			towers.append({"slot": i, "tower": tower.data.resource_path, "level": mini(tower.get_level(), tower.data.max_level()),
				"evolution": tower.data.all_evolutions().find(tower.get_evolution()) if tower.is_evolved() else -1, "invested": tower.invested, "masterwork": tower.get_masterwork()})
	return {
		"version": VERSION,
		"seed": run.seed_value,
		"hero": capture_hero_id(run),
		"pressure": PressureRules.ids(run.pressure),
		"depth": run.depth,
		"chapter": run.chapter_index,
		"biomes": run.biomes.map(func(chapter: ChapterData) -> String: return String(chapter.id)),
		"path": run.map.path.map(func(node: MapNode) -> int: return run.map.nodes.find(node)),
		"cleared": run.cleared.duplicate(true),
		"kills": run.kills,
		"waves": run.waves,
		"msec": Time.get_ticks_msec() - run.started_msec,
		"gold": level.economy.get_gold(),
		"upgrades": level.modifiers.get_taken().map(func(data: UpgradeData) -> String: return data.resource_path),
		"lives": level.hero_lives.get_lives_left(),
		"fortress": level.fortress.health.current_health,
		"towers": towers,
		"free_evolutions": level.builder.free_evolutions,
		"offers": level.offers.save_state() if level.offers != null else {},
		"events": level.events.save_state() if level.events != null else {},
		"merchant": level.merchant.save_state() if level.merchant != null else {},
		"quartermaster": level.quartermaster.save_state() if level.quartermaster != null else {},
	}


## The id of the run's hero ("" without one).
static func capture_hero_id(run: RunStateNode) -> String:
	return String(run.hero.id) if run.hero != null else ""


## Starts `saved`'s run again in `run` (its chapter, its map, the path walked so far). False (and
## nothing usable) if it can't be: another format, a chapter or a map node that doesn't exist.
static func restore_run(run: RunStateNode, saved: Dictionary, run_data: RunData, unlocks: RunUnlocks) -> bool:
	if int(saved.get("version", 0)) != VERSION or int(saved.get("chapter", -1)) < 0 \
			or (int(saved.get("chapter", -1)) >= run_data.chapters.size() and int(saved.get("depth", 0)) <= 0):
		return false
	run.start_run(run_data, int(saved.get("seed", 0)), unlocks, run_data.get_hero(str(saved.get("hero", ""))), run_data.pressure_for(saved.get("pressure", [])))
	# The roads taken (a save from before M10 has none: the seed's picks, as they were).
	var saved_biomes: Array[ChapterData] = []
	for id: Variant in saved.get("biomes", []):
		var biome: ChapterData = run_data.find_chapter(StringName(str(id)))
		if biome != null:
			saved_biomes.append(biome)
	if not saved_biomes.is_empty():
		run.biomes = saved_biomes
	if int(saved.get("depth", 0)) > 0:
		run.resume_descent(int(saved.get("depth", 0)), int(saved.get("chapter", 0)))
	else:
		run.set_chapter(int(saved.get("chapter", 0)))
	for index: Variant in saved.get("path", []):
		if int(index) < 0 or int(index) >= run.map.nodes.size():
			return false
		run.map.force_visit(run.map.nodes[int(index)])
	for fight: Variant in saved.get("cleared", []):
		run.cleared.append(fight as Dictionary)
	run.kills = int(saved.get("kills", 0))
	run.waves = int(saved.get("waves", 0))
	run.started_msec = Time.get_ticks_msec() - int(saved.get("msec", 0))
	return true


## Puts `saved`'s chapter state back on `level` (ready, its unlocks applied, its systems seeded).
static func restore_level(level: Level, saved: Dictionary) -> void:
	var carry: ChapterCarry = ChapterCarry.new()
	carry.gold = int(saved.get("gold", 0))
	for path: Variant in saved.get("upgrades", []):
		if ResourceLoader.exists(String(path)):
			carry.upgrades.append(load(String(path)) as UpgradeData)
	carry.lives_left = int(saved.get("lives", level.hero_lives.get_lives_left()))
	carry.fortress_health = int(saved.get("fortress", level.fortress.health.current_health))
	level.carry_in(carry, 0.0)
	var slots: Array[BuildSlot] = level.builder.get_slots()
	for tower: Variant in saved.get("towers", []):
		var entry: Dictionary = tower
		var slot: int = int(entry.get("slot", -1))
		if slot >= 0 and slot < slots.size() and ResourceLoader.exists(String(entry.get("tower", ""))):
			level.builder.restore(slots[slot], load(String(entry.get("tower"))) as TowerData, int(entry.get("level", 1)),
				int(entry.get("evolution", -1)), int(entry.get("invested", 0)), int(entry.get("masterwork", 0)))
	level.builder.free_evolutions = int(saved.get("free_evolutions", 0))
	if level.offers != null:
		level.offers.load_state(saved.get("offers", {}))
	if level.events != null:
		level.events.load_state(saved.get("events", {}))
	if level.merchant != null:
		level.merchant.load_state(saved.get("merchant", {}))
	if level.quartermaster != null:
		level.quartermaster.load_state(saved.get("quartermaster", {}))
