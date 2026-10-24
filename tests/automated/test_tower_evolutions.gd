extends SceneTree
## Automated check for tower evolutions (the system; test_evolution_mechanics checks what each one
## does): every tower has two complete branches with their own art and a price near its levels 1-3
## combined; a tower offers them only at level 3 and only once; evolving costs the price (with the
## upgrade discount), refuses without the gold or twice, and is permanent (level 4, the branch's
## stats); selling refunds half of everything spent, evolution included; the build menu shows both
## branches side by side with their numbers and both range rings, and its button evolves the tower.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const TOWERS_DIR: String = "res://data/towers"
const TOWER_FRAMES: SpriteFrames = preload("res://entities/towers/tower_frames.tres")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const CANNON: TowerData = preload("res://data/towers/cannon.tres")
const GUILD: UpgradeData = preload("res://data/upgrades/guild.tres")
const SLOT: int = 3

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_rules()
	await _test_menu()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_data() -> void:
	var ids: Dictionary = {}
	var complete: bool = true
	var priced: bool = true
	var art: bool = true
	var towers: int = 0
	for file: String in DirAccess.get_files_at(TOWERS_DIR):
		if not file.ends_with(".tres"):
			continue
		var data: TowerData = load(TOWERS_DIR.path_join(file))
		towers += 1
		complete = complete and data.evolutions.size() == 2
		var levels_cost: int = data.cost + data.upgrade_cost(2) + data.upgrade_cost(3)
		for evolution: TowerEvolution in data.evolutions:
			ids[evolution.id] = true
			complete = complete and evolution.id != &"" and not evolution.display_name.is_empty() and not evolution.description.is_empty()
			priced = priced and evolution.cost >= levels_cost * 0.75 and evolution.cost <= levels_cost * 1.25
			for state: String in ["idle", "fire"]:
				art = art and (data.frames if data.frames != null else TOWER_FRAMES).has_animation(StringName("%s_%s" % [evolution.id, state]))
	_check("each of the %d towers has 2 complete evolutions, 22 different ones" % towers, complete and towers == 11 and ids.size() == 22)
	_check("each evolution costs about levels 1-3 combined (within 25%)", priced)
	_check("each evolution has its own idle and fire art", art)


func _test_rules() -> void:
	var level: Level = _make_level()
	await _frames(2)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var economy: Economy = level.get_node("%Economy")
	var slot: BuildSlot = builder.get_slots()[SLOT]
	var tower: Tower = await _tower(level, ARCHER)
	_check("level 1: no evolution offered", builder.evolution_options(slot).is_empty() and not builder.evolve(slot, 0))
	economy.earn(ARCHER.upgrade_cost(2) + ARCHER.upgrade_cost(3), Economy.Source.REFUND)
	builder.upgrade(slot)
	builder.upgrade(slot)
	var options: Array[TowerEvolution] = builder.evolution_options(slot)
	_check("level 3: the two branches are offered", options.size() == 2 and options == ARCHER.evolutions)
	var choice: TowerEvolution = ARCHER.evolutions[1]
	var cost: int = builder.evolution_cost(choice)
	economy.try_spend(economy.get_gold())
	economy.earn(cost - 1, Economy.Source.REFUND)
	_check("one gold short: refused, nothing changes", not builder.evolve(slot, 1) and not tower.is_evolved() and economy.get_gold() == cost - 1)
	economy.earn(1, Economy.Source.REFUND)
	var invested: int = tower.invested
	_check("evolving costs its price (%d)" % cost, builder.evolve(slot, 1) and economy.get_gold() == 0 and tower.invested == invested + cost)
	_check("...and makes it level 4 with the branch's stats", tower.get_level() == 4 and tower.get_evolution() == choice
		and tower.get_stats().damage == choice.damage and is_equal_approx(tower.get_attack_range(), choice.attack_range))
	economy.earn(5000, Economy.Source.REFUND)
	_check("the choice is permanent: no second evolution, no other branch", not builder.evolve(slot, 0) and not builder.evolve(slot, 1)
		and tower.get_evolution() == choice and builder.evolution_options(slot).is_empty())
	_check("...and no more regular upgrades", builder.upgrade_cost(slot) < 0 and not builder.upgrade(slot))
	var spent: int = ARCHER.cost + ARCHER.upgrade_cost(2) + ARCHER.upgrade_cost(3) + cost
	var gold: int = economy.get_gold()
	_check("selling refunds half of everything spent, the evolution included (%d)" % floori(spent * 0.5), builder.sell(slot) == floori(spent * 0.5)
		and economy.get_gold() == gold + floori(spent * 0.5))
	# The tower-upgrade discount applies to evolutions too.
	(level.get_node("%RunModifiers") as RunModifiers).add_upgrade(GUILD)
	_check("Guild Discount makes evolutions cheaper (%d -> %d)" % [CANNON.evolutions[0].cost, builder.evolution_cost(CANNON.evolutions[0])],
		builder.evolution_cost(CANNON.evolutions[0]) == roundi(CANNON.evolutions[0].cost * 0.8))
	level.queue_free()
	await _frames(2)


func _test_menu() -> void:
	var level: Level = _make_level()
	await _frames(2)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var economy: Economy = level.get_node("%Economy")
	var slot: BuildSlot = builder.get_slots()[SLOT]
	var tower: Tower = await _tower(level, CANNON)
	economy.earn(5000, Economy.Source.REFUND)
	builder.upgrade(slot)
	builder.upgrade(slot)
	var menu: Node = level.get_node("BuildMenu")
	menu.call("open", slot)
	await _frames(2)
	var choice: EvolutionChoice = menu.get_node("%Evolutions")
	var cards: Array[Node] = choice.get_children().filter(func(n: Node) -> bool: return not n.is_queued_for_deletion())
	var text: String = _texts(choice)
	_check("the menu shows both branches side by side", choice.visible and cards.size() == 2 and choice.get_option_count() == 2)
	_check("...with names, descriptions and key numbers (%s)" % text.replace("\n", " / ").left(120),
		text.contains("Siege Mortar") and text.contains("Grapeshot Battery") and text.contains("Range 1400") and text.contains("Cone of 70"))
	var rings: Array = slot.get_shown_rings()
	_check("...and both range rings, the Mortar's dead zone too (%s)" % str(rings.map(func(r: Array) -> String: return "%d/%d" % [roundi(r[0]), roundi(r[1])])),
		rings.size() == 2 and is_equal_approx(rings[0][0], CANNON.evolutions[0].attack_range) and is_equal_approx(rings[0][1], CANNON.evolutions[0].min_range)
		and is_equal_approx(rings[1][0], CANNON.evolutions[1].attack_range))
	choice.get_evolve_button(1).pressed.emit()
	await _frames(2)
	_check("the Evolve button evolves the tower", tower.get_evolution() == CANNON.evolutions[1])
	_check("an evolved tower's menu shows no choice, its new name and numbers",
		not choice.visible and (menu.get_node("%Title") as Label).text.contains("Grapeshot Battery") and (menu.get_node("%InfoStats") as Label).text.contains("Cone"))
	menu.call("close")
	level.queue_free()
	await _frames(2)


func _texts(node: Node) -> String:
	var parts: Array[String] = []
	for label: Node in node.find_children("*", "Label", true, false):
		parts.append((label as Label).text)
	for button: Node in node.find_children("*", "Button", true, false):
		parts.append((button as Button).text)
	return "\n".join(parts)


func _make_level() -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	WaveFixtures.no_upgrades(level)
	(level.get_node("Hero") as Node2D).position = Vector2(380, 380)
	root.add_child(level)
	return level


func _tower(level: Level, data: TowerData) -> Tower:
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	(level.get_node("%Economy") as Economy).earn(data.cost, Economy.Source.REFUND)
	builder.build(builder.get_slots()[SLOT], data)
	await _frames(int(data.build_time * 60.0) + 2)
	return builder.get_slots()[SLOT].tower


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
