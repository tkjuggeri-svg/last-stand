extends SceneTree
## Automated check for Masterwork ranks (M13 follow-up, the repeatable gold sink): a tower of level 3 or more can
## be given ranks, each +8% power (damage, burning ground, aura bonuses, skeletons) and dearer than the last
## (base 120, x1.32 a rank, the Guild's discount applies); the rank is shown on the tower, counts in what a
## sale refunds, is saved and restored, is offered by the build menu, and works the same inside a descent.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const RUN: RunData = preload("res://data/run/run.tres")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const BRAZIER: TowerData = preload("res://data/towers/brazier.tres")
const WATCHTOWER: TowerData = preload("res://data/towers/watchtower.tres")
const BONE_PIT: TowerData = preload("res://data/towers/bone_pit.tres")
const GUILD: UpgradeData = preload("res://data/upgrades/guild.tres")

var _failures: int = 0


func _initialize() -> void:
	await _test_rules()
	await _test_kinds()
	await _test_save()
	await _test_menu()
	await _test_descent()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _level() -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new(), WaveData.new()]
	WaveFixtures.no_upgrades(level)
	root.add_child(level)
	await _frames(2)
	level.economy.earn(20000, Economy.Source.REFUND)
	return level


## A tower of `data` on slot `index`, built and taken to `level_goal`.
func _tower(level: Level, data: TowerData, index: int, level_goal: int) -> Tower:
	var slot: BuildSlot = level.builder.get_slots()[index]
	level.builder.build(slot, data)
	await _frames(70)
	for _i: int in level_goal - 1:  # a tower starts at level 1
		level.builder.upgrade(slot)
	return slot.tower


func _test_rules() -> void:
	var level: Level = await _level()
	var builder: TowerBuilder = level.builder
	var failures: Array[String] = []
	builder.upgrade_failed.connect(func(_s: BuildSlot, reason: String) -> void: failures.append(reason))
	var tower: Tower = await _tower(level, ARCHER, 3, 2)
	var slot: BuildSlot = builder.get_slots()[3]
	_check("below level 3 there is no Masterwork (cost %d)" % builder.masterwork_cost(slot), builder.masterwork_cost(slot) == -1 and not builder.masterwork(slot)
		and failures.back() == TowerBuilder.NOT_YET_MASTERWORK)
	builder.upgrade(slot)
	var base_damage: int = tower.get_stats().damage
	_check("at level 3 the first rank costs the base price (%d)" % builder.masterwork_cost(slot), builder.masterwork_cost(slot) == 120)
	var gold: int = level.economy.get_gold()
	var invested: int = tower.invested
	_check("buying it takes the gold, adds to what is invested and gives rank 1", builder.masterwork(slot) and tower.get_masterwork() == 1
		and level.economy.get_gold() == gold - 120 and tower.invested == invested + 120)
	_check("+8%% damage a rank (%d -> %d)" % [base_damage, tower.get_stats().damage], tower.get_stats().damage == roundi(base_damage * 1.08))
	var costs: Array[int] = [builder.masterwork_cost(slot)]
	builder.masterwork(slot)
	costs.append(builder.masterwork_cost(slot))
	builder.masterwork(slot)
	costs.append(builder.masterwork_cost(slot))
	_check("each rank costs more than the one before (%s) and the tower is at rank 3, +24%%" % str(costs), costs[0] == 158 and costs[1] > costs[0] and costs[2] > costs[1]
		and tower.get_masterwork() == 3 and tower.get_stats().damage == roundi(base_damage * 1.24))
	_check("the rank is shown on the tower", (tower.get_node("%RankMark") as Label).visible and (tower.get_node("%RankMark") as Label).text == "M3")
	_check("what a sale refunds counts it (%d of %d invested)" % [builder.refund_for_tower(tower), tower.invested], builder.refund_for_tower(tower) == floori(tower.invested * builder.sell_refund_ratio))
	level.modifiers.add_upgrade(GUILD)
	_check("the Guild's discount applies (%d)" % builder.masterwork_cost(slot), builder.masterwork_cost(slot) == roundi(costs[2] * 0.8))
	level.economy.try_spend(level.economy.get_gold())
	_check("without the gold nothing happens", not builder.masterwork(slot) and failures.back() == TowerBuilder.NOT_ENOUGH_GOLD and tower.get_masterwork() == 3)
	level.queue_free()
	await _frames(2)


func _test_kinds() -> void:
	var level: Level = await _level()
	var builder: TowerBuilder = level.builder
	var brazier: Tower = await _tower(level, BRAZIER, 0, 3)
	var burn: float = brazier.get_stats().burn_dps
	var watch: Tower = await _tower(level, WATCHTOWER, 1, 3)
	var bonus: float = watch.get_stats().hero_bonus
	var pit: Tower = await _tower(level, BONE_PIT, 2, 3)
	var skeleton_health: int = pit.get_stats().minion.max_health
	for index: int in 3:
		builder.masterwork(builder.get_slots()[index])
		builder.masterwork(builder.get_slots()[index])
	_check("a Brazier's burning ground grows 16%% (%.1f -> %.1f)" % [burn, brazier.get_stats().burn_dps], is_equal_approx(brazier.get_stats().burn_dps, burn * 1.16))
	_check("a Watchtower's bonus to the hero grows (%.3f -> %.3f)" % [bonus, watch.get_stats().hero_bonus], is_equal_approx(watch.get_stats().hero_bonus, bonus * 1.16))
	_check("a Bone Pit's skeletons grow (%d -> %d HP) and the shared data is untouched" % [skeleton_health, pit.get_stats().minion.max_health],
		pit.get_stats().minion.max_health == roundi(skeleton_health * 1.16) and BONE_PIT.stats_for(3).minion.max_health == skeleton_health)
	level.queue_free()
	await _frames(2)


func _test_save() -> void:
	var level: Level = await _level()
	var tower: Tower = await _tower(level, ARCHER, 4, 3)
	for _i: int in 3:
		level.builder.masterwork(level.builder.get_slots()[4])
	var run: RunStateNode = RunStateNode.new()
	run.start_run(RUN, 5)
	var saved: Dictionary = RunSave.capture(run, level)
	var entry: Dictionary = (saved["towers"] as Array)[0]
	_check("a saved run keeps the rank (%s)" % str(entry.get("masterwork")), int(entry.get("masterwork", 0)) == 3 and tower.get_masterwork() == 3)
	var fresh: Level = await _level()
	RunSave.restore_level(fresh, saved)
	var back: Tower = fresh.builder.get_slots()[4].tower
	_check("...and puts it back with the same strength", back != null and back.get_masterwork() == 3 and back.get_stats().damage == tower.get_stats().damage)
	run.free()
	level.queue_free()
	fresh.queue_free()
	await _frames(2)


func _test_menu() -> void:
	var level: Level = await _level()
	var tower: Tower = await _tower(level, ARCHER, 0, 2)
	var menu: Node = level.get_node("BuildMenu")
	var button: Button = menu.find_child("MasterworkButton", true, false)
	menu.call("open", level.builder.get_slots()[0])
	await _frames(2)
	_check("below level 3 the menu's Masterwork button is off", button.disabled)
	level.builder.upgrade(level.builder.get_slots()[0])
	await _frames(2)
	_check("at level 3 it shows the price and can be pressed (%s)" % button.text, not button.disabled and button.text.contains("120"))
	button.pressed.emit()
	await _frames(2)
	_check("pressing it gives the rank and the button shows the next price (%s)" % button.text, tower.get_masterwork() == 1 and button.text.contains("158"))
	level.economy.try_spend(level.economy.get_gold())
	await _frames(2)
	_check("with no gold it is off again", button.disabled)
	menu.call("close")
	level.queue_free()
	await _frames(2)


func _test_descent() -> void:
	var main: Node = (load("res://main/main.tscn") as PackedScene).instantiate()
	main.set("boot_to_title", false)
	root.add_child(main)
	await _frames(3)
	var run: RunStateNode = root.get_node("/root/RunState") as RunStateNode
	run.depth = 2
	var level: Level = await MapFixtures.enter_first_battle(main)
	level.economy.earn(5000, Economy.Source.REFUND)
	await _frames(2)
	var tower: Tower = await _tower(level, ARCHER, 0, 3)
	var rank_one: bool = level.builder.masterwork(level.builder.get_slots()[0])
	_check("inside a descent (depth %d) Masterwork works the same" % run.depth, rank_one and tower.get_masterwork() == 1 and level.builder.masterwork_cost(level.builder.get_slots()[0]) == 158)
	main.queue_free()
	await _frames(2)


func _frames(count: int) -> void:
	for _i: int in count:
		await process_frame


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
