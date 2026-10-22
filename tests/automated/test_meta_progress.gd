extends SceneTree
## Automated check for meta progression (M8): the unlock board covers every tower, card, relic and the
## rare event, each in the starting kit or in exactly one unlock, about 1,200 shards in all, every
## requirement real; a fresh profile's run has the starting kit (3 towers, 13 cards, 5 relics, no
## evolutions, no rare event) and unlocks add to it, on a real level; Soul Shards for a run (lost runs
## too), one-off rewards paid once, records; buying (price, requirements, once); the perks (Muster's
## starting choice, Drill's free reroll); and through main.tscn a lost run pays into the saved profile.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const BOARD: UnlockBoard = preload("res://data/meta/unlock_board.tres")
const ARENA: String = "res://levels/prototype_arena.tscn"
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const RELIQUARY: EventData = preload("res://data/events/drowned_reliquary.tres")
const RUN: RunData = preload("res://data/run/run.tres")
const SAVE_PATH: String = "user://test_meta.json"

var _failures: int = 0


func _initialize() -> void:
	_test_board()
	await _test_fresh_kit()
	_test_map_events()
	_test_shards()
	_test_buying()
	await _test_perks()
	await _test_run_pays()
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE_PATH + suffix):
			DirAccess.remove_absolute(SAVE_PATH + suffix)
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_board() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var towers: Array = BOARD.starter_towers.duplicate()
	var cards: Array = BOARD.starter_cards.duplicate()
	var relics: Array = BOARD.starter_relics.duplicate()
	var total: int = 0
	var real_requirements: bool = true
	for unlock: UnlockData in BOARD.unlocks:
		towers.append_array(unlock.towers)
		cards.append_array(unlock.cards)
		relics.append_array(unlock.relics)
		total += unlock.cost
		for need: StringName in unlock.requires:
			real_requirements = real_requirements and BOARD.find(need) != null
	var all_once: bool = true
	for tower: TowerData in (level.get_node("%TowerBuilder") as TowerBuilder).catalog:
		all_once = all_once and towers.count(tower) == 1
	for card: UpgradeData in (level.get_node("%UpgradeOffers") as UpgradeOffers).pool:
		all_once = all_once and cards.count(card) == 1
	for relic: RelicData in (level.get_node("%UpgradeOffers") as UpgradeOffers).relic_pool:
		all_once = all_once and relics.count(relic) == 1
	_check("the board: every tower, card and relic in the kit or in exactly one unlock", all_once)
	_check("%d unlocks, %d shards in all, every requirement real" % [BOARD.unlocks.size(), total],
		BOARD.unlocks.size() >= 15 and total >= 1000 and total <= 1400 and real_requirements)
	var power: bool = false
	for unlock: UnlockData in BOARD.unlocks:
		power = power or (unlock.perk != &"" and not unlock.perk in [&"muster", &"drill"])
	_check("no permanent power: the only perks are a starting choice and a convenience", not power)
	level.free()


func _test_fresh_kit() -> void:
	var fresh: RunUnlocks = RunUnlocks.for_profile(BOARD, SaveProfile.new())
	_check("a fresh profile's run: 3 towers, 13 cards, 5 relics, no evolutions, the rare event locked, no perks",
		fresh.towers.size() == 3 and fresh.cards.size() == 13 and fresh.relics.size() == 5 and fresh.evolving.is_empty()
		and fresh.locked_events.has(RELIQUARY) and fresh.perks.is_empty() and not fresh.everything)
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	root.add_child(level)
	await _frames(2)
	level.apply_unlocks(fresh)
	level.economy.earn(2000, Economy.Source.REFUND)
	var slot: BuildSlot = level.builder.get_slots()[3]
	level.builder.build(slot, ARCHER)
	await _frames(50)
	level.builder.upgrade(slot)
	await _frames(50)
	level.builder.upgrade(slot)
	await _frames(50)
	_check("on a level: the build menu has the 3 towers, the pools the kit", level.builder.catalog.size() == 3
		and level.offers.pool.size() == 13 and level.offers.relic_pool.size() == 5)
	_check("...a level-3 Archer can't evolve yet", slot.tower.is_max_level() and level.builder.evolution_options(slot).is_empty()
		and not level.builder.evolve(slot, 0))
	var profile: SaveProfile = SaveProfile.new()
	profile.unlocks = ["brazier", "evolutions_archer"]
	var more: RunUnlocks = RunUnlocks.for_profile(BOARD, profile)
	level.apply_unlocks(more)
	_check("unlocks add: the Brazier joins (%d towers), the Archer may evolve" % more.towers.size(),
		more.towers.size() == 4 and more.can_evolve(ARCHER) and level.builder.evolution_options(slot).size() == 2)
	level.queue_free()
	await _frames(2)


func _test_map_events() -> void:
	var locked: Array[EventData] = [RELIQUARY]
	var seen: bool = false
	for map_seed: int in 60:
		for node: MapNode in RunMap.generate(RUN.chapters[0], map_seed, locked).nodes:
			seen = seen or node.event == RELIQUARY
	_check("a locked event never comes up on the map (60 maps)", not seen)


func _test_shards() -> void:
	var profile: SaveProfile = SaveProfile.new()
	var lost: Dictionary = {"result": "lost", "chapter": 1, "row": 6, "battles": 5, "elites": 1, "bosses": [], "chapters_cleared": 0}
	_check("a run lost at chapter 1 row 6 (5 battles, 1 elite) pays %d shards" % MetaProgress.shards_for(lost, profile),
		MetaProgress.shards_for(lost, profile) == 5 * MetaProgress.BATTLE + MetaProgress.ELITE)
	var won: Dictionary = {"result": "won", "chapter": 2, "row": 8, "battles": 9, "elites": 2, "bosses": ["The Lich Warden", "The Tollkeeper"],
		"chapters_cleared": 2}
	var first_time: int = MetaProgress.finish_run(profile, won)
	var again: int = MetaProgress.shards_for(won, profile)
	_check("a won run pays %d the first time (one-off rewards), %d after" % [first_time, again],
		first_time == again + 3 * MetaProgress.FIRST_TIME and again == 9 * MetaProgress.BATTLE + 2 * MetaProgress.ELITE
		+ MetaProgress.BOSS[0] + MetaProgress.BOSS[1] + 2 * MetaProgress.CHAPTER_CLEARED + MetaProgress.RUN_WON)
	_check("the records: runs, wins, best, bosses, all shards ever", profile.runs == 1 and profile.wins == 1 and profile.best_chapter == 2
		and profile.best_row == 8 and profile.bosses.size() == 2 and profile.shards == first_time and profile.shards_total == first_time)
	for _i: int in 12:
		MetaProgress.finish_run(profile, lost)
	_check("the history keeps the last %d runs" % SaveProfile.HISTORY_SIZE, profile.history.size() == SaveProfile.HISTORY_SIZE)


func _test_buying() -> void:
	var profile: SaveProfile = SaveProfile.new()
	var evolutions: UnlockData = BOARD.find(&"evolutions_cannon")
	var brazier: UnlockData = BOARD.find(&"brazier")
	_check("not enough shards: can't buy", MetaProgress.blocker(profile, BOARD, brazier) == MetaProgress.NEEDS_SHARDS)
	profile.shards = 500
	_check("an unlock that needs another first says which (\"%s\")" % MetaProgress.blocker(profile, BOARD, evolutions),
		MetaProgress.blocker(profile, BOARD, evolutions).begins_with("Needs"))
	_check("buying takes its price, once", MetaProgress.buy(profile, BOARD, brazier) and profile.shards == 500 - brazier.cost
		and not MetaProgress.buy(profile, BOARD, brazier) and MetaProgress.blocker(profile, BOARD, brazier) == MetaProgress.OWNED)


func _test_perks() -> void:
	var save: SaveManagerNode = root.get_node("/root/SaveManager") as SaveManagerNode
	save.use_file(SAVE_PATH)
	save.profile = SaveProfile.new()
	save.profile.unlocks = ["muster", "drill"]
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	main.set("boot_to_title", false)
	root.add_child(main)
	await _frames(3)
	var level: Level = main.call("get_level")
	var offer: Array[UpgradeData] = level.offers.get_offer()
	_check("Muster: the run starts with a choice of 2 common cards (the map hidden)", offer.size() == 2
		and not (main.get_node("%MapScreen") as MapScreen).visible
		and offer.all(func(d: UpgradeData) -> bool: return d.rarity == UpgradeData.Rarity.COMMON))
	_check("Drill: the first reroll is free", level.offers.get_reroll_cost() == 0 and level.offers.reroll() and level.offers.get_reroll_cost() > 0)
	level.offers.pick(0)
	await _frames(2)
	_check("...then the map", (main.get_node("%MapScreen") as MapScreen).visible)
	main.queue_free()
	await _frames(2)


func _test_run_pays() -> void:
	var save: SaveManagerNode = root.get_node("/root/SaveManager") as SaveManagerNode
	save.use_file(SAVE_PATH)
	save.profile = SaveProfile.new()
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	main.set("boot_to_title", false)
	root.add_child(main)
	await _frames(3)
	var level: Level = await MapFixtures.enter_first_battle(main)
	level.spawner.enemy_spawned.connect(func(e: Enemy) -> void: e.get_health().take_damage.call_deferred(100000))
	level.run_cycle.start_wave()
	await _until(func() -> bool: return level.run_cycle.get_phase() == RunCycle.Phase.BUILD and level.run_cycle.get_current_wave_number() == 2, 60 * 30)
	level.run_cycle.start_wave()
	await _until(func() -> bool: return level.offers.is_offer_open(), 60 * 30)
	level.offers.pick(0)
	await _frames(2)
	level = await MapFixtures.enter_first_battle(main)
	level.fortress.health.take_damage(100000)
	await _frames(3)
	var summary: Dictionary = main.get("last_summary")
	_check("a lost run pays shards for what it did (%s: %d)" % [str(summary.get("shard_lines")), int(summary.get("shards", 0))],
		summary.get("result") == "lost" and int(summary.get("battles", 0)) == 1 and int(summary.get("shards", 0)) == MetaProgress.BATTLE)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	_check("...into the saved profile (%s shards, %s runs)" % [saved.get("shards"), (saved.get("records", {}) as Dictionary).get("runs")],
		int(saved.get("shards", 0)) == MetaProgress.BATTLE and int((saved.get("records", {}) as Dictionary).get("runs", 0)) == 1)
	main.queue_free()
	await _frames(2)


func _until(condition: Callable, max_frames: int) -> void:
	for _i: int in max_frames:
		if condition.call():
			return
		await physics_frame


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
