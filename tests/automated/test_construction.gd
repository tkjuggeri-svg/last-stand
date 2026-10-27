extends SceneTree
## Automated check for tower construction and selling: slots, gold checks, 50% refunds (only once),
## building during combat, and the real E -> build menu -> Build / Sell flow.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const FROST: TowerData = preload("res://data/towers/frost.tres")
const CANNON: TowerData = preload("res://data/towers/cannon.tres")
## The test pins the level's starting gold (exactly one Cannon), so it doesn't move with tuning.
const START_GOLD: int = 100
## 50% of the Archer Tower's 50 gold build price.
const ARCHER_REFUND: int = 25
## Lane half width (16) + tower footprint and some air: towers must stay this far from the lane centre.
const LANE_CLEARANCE: float = 64.0

var _failures: int = 0


func _initialize() -> void:
	await _test_slots_and_rules()
	await _test_build_during_combat()
	await _test_menu_flow()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_slots_and_rules() -> void:
	var level: Level = _make_level(0)
	await _frames(2)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var economy: Economy = level.get_node("%Economy")
	var hud: Node = level.get_node("HUD")
	var slots: Array[BuildSlot] = builder.get_slots()
	var failures: Array[String] = []
	builder.build_failed.connect(func(_s: BuildSlot, _d: TowerData, reason: String) -> void: failures.append(reason))

	_check("16 build slots, all empty", slots.size() == 16 and builder.get_free_slot_count() == 16)
	_check("HUD shows free slots", (hud.get_node("%SlotsLabel") as Label).text == "Slots free: 16 / 16")
	_check("slots keep clear of every lane, the fortress and the walls", _slots_placed_well(level, slots))

	var slot: BuildSlot = slots[0]
	_check("an empty slot accepts a tower", builder.build(slot, ARCHER) and slot.tower != null and slot.tower.data == ARCHER)
	_check("the cost is deducted (gold %d)" % economy.get_gold(), economy.get_gold() == START_GOLD - ARCHER.cost)
	_check("HUD gold and free slots update",
		(hud.get_node("%GoldLabel") as Label).text == str(START_GOLD - ARCHER.cost)
		and (hud.get_node("%SlotsLabel") as Label).text == "Slots free: 15 / 16")
	_check("an occupied slot rejects a second tower",
		not builder.build(slot, FROST) and slot.tower.data == ARCHER and failures.back() == TowerBuilder.SLOT_OCCUPIED)
	_check("...and no gold is taken for it", economy.get_gold() == START_GOLD - ARCHER.cost)
	var gold_before: int = economy.get_gold()
	_check("not enough gold prevents construction",
		not builder.build(slots[1], CANNON) and slots[1].is_empty() and failures.back() == TowerBuilder.NOT_ENOUGH_GOLD)
	_check("...and gold is unchanged (never negative)", economy.get_gold() == gold_before and economy.get_gold() >= 0)

	var archer_tower: Tower = slot.tower
	var tower_sprite: AnimatedSprite2D = archer_tower.get_node("%Sprite")
	_check("a new tower rises in scaffolding (%s)" % tower_sprite.animation,
		tower_sprite.animation == &"archer_build" and archer_tower.is_building())
	await _frames(45)
	_check("...then is finished: idle, or already firing (%s)" % tower_sprite.animation,
		tower_sprite.animation in [&"archer_idle", &"archer_fire"] and not archer_tower.is_building())
	var refund: int = builder.sell(slot)
	await _frames(1)
	var rubble: Array[Node] = slot.get_children().filter(func(n: Node) -> bool: return n.name.begins_with("TowerDismantle"))
	_check("a sold tower is shown coming down into rubble",
		rubble.size() == 1 and (rubble[0].get_node("%Sprite") as AnimatedSprite2D).animation == &"archer_sell")
	await _frames(45)
	_check("...and the rubble clears away by itself", not is_instance_valid(rubble[0]) if rubble.size() == 1 else false)
	_check("selling refunds exactly 50%% (%d of %d)" % [refund, ARCHER.cost], refund == ARCHER_REFUND)
	_check("gold goes up by the refund", economy.get_gold() == gold_before + ARCHER_REFUND)
	_check("the slot is free again and the tower is gone", slot.is_empty() and not is_instance_valid(archer_tower))
	_check("selling again refunds nothing", builder.sell(slot) == 0 and economy.get_gold() == gold_before + ARCHER_REFUND)
	_check("the freed slot can be built on again", builder.build(slot, ARCHER))
	gold_before = economy.get_gold()
	var total: int = builder.sell(slot) + builder.sell(slot) + builder.sell(slot)  # e.g. a frantic triple click
	_check("repeated sells in one frame refund once (%d)" % total, total == ARCHER_REFUND and economy.get_gold() == gold_before + total)
	_check("refund is based on the build price", builder.refund_for(CANNON) == floori(CANNON.cost * 0.5) and builder.refund_for(FROST) == floori(FROST.cost * 0.5))
	await _free(level)


func _test_build_during_combat() -> void:
	var level: Level = _make_level(10)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	await _frames(150)  # ghouls are on the lane
	var ghoul: Enemy = spawner.get_child(0)
	var before: Vector2 = ghoul.global_position
	_check("combat is on (ghouls alive)", spawner.get_living_count() >= 2)
	_check("building works during combat", builder.build(builder.get_slots()[2], ARCHER))
	await _frames(10)
	_check("the game keeps running while building (not paused, ghouls still move)",
		not paused and ghoul.global_position.distance_to(before) > 5.0)
	await _free(level)


## The player's way: walk to a slot, press E, choose in the menu.
func _test_menu_flow() -> void:
	var level: Level = _make_level(0)
	await _frames(2)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var economy: Economy = level.get_node("%Economy")
	var menu: CanvasLayer = level.get_node("BuildMenu")
	var hero: Hero = level.get_node("Hero")
	var slot: BuildSlot = builder.get_slots()[2]
	var message: Label = menu.get_node("%Message")

	await _press_interact()
	_check("E away from any slot opens nothing", not menu.call("is_open"))
	hero.position = slot.position + Vector2(0, 40)
	await _frames(3)
	_check("standing at a slot makes it active and highlighted",
		builder.get_active_slot() == slot and (slot.get_node("%Pad") as Sprite2D).frame == 1
		and (slot.get_node("%Prompt") as Label).visible and (slot.get_node("%Prompt") as Label).text == "E  Build")
	await _press_interact()
	_check("E opens the build menu for that slot", menu.call("is_open") and menu.call("get_slot") == slot)
	_check("the game does not pause", not paused)
	var panel: Control = menu.get_node("%Panel")
	await _frames(2)
	_check("the panel fits its content and stays on screen (%s)" % panel.get_rect(), _panel_fits(panel))
	var cards: Array[Node] = (menu.get_node("%Options") as Node).get_children()
	var names: Array[String] = []
	var costs: Array[String] = []
	for card: Node in cards:
		names.append(_labels_in(card)[0])
		costs.append(_labels_in(card)[1])
	_check("menu lists name and price of all 5 towers (%s %s)" % [names, costs],
		names == builder.catalog.map(func(d: TowerData) -> String: return d.display_name)
		and costs == builder.catalog.map(func(d: TowerData) -> String: return str(d.cost)) and names.size() == 5)
	var details: Label = menu.get_node("%Details")
	var described: bool = true
	for i: int in cards.size():
		(cards[i].find_child("Build", true, false) as Button).mouse_entered.emit()
		described = described and details.text.begins_with((builder.catalog[i] as TowerData).description) and details.text.length() > 20
	_check("pointing at a tower shows its description and stats", described)

	(cards[2].find_child("Build", true, false) as Button).pressed.emit()  # Cannon: exactly the 100 we start with
	await _frames(1)
	_check("buying the cannon with exactly 100 works", slot.tower != null and economy.get_gold() == 0)
	await _frames(2)
	_check("...also in the sell view (%s)" % panel.get_rect(), _panel_fits(panel))
	_check("the menu now shows the tower and its refund",
		(menu.get_node("%TowerInfo") as Control).visible and (menu.get_node("%SellButton") as Button).text == "Sell   +50 gold")
	(menu.get_node("%SellButton") as Button).pressed.emit()
	(menu.get_node("%SellButton") as Button).pressed.emit()  # double click
	await _frames(1)
	_check("selling from the menu refunds 50 once (gold %d)" % economy.get_gold(), economy.get_gold() == 50 and slot.is_empty())
	_check("the menu confirms the refund", message.text == "Sold for 50 gold.")
	cards = (menu.get_node("%Options") as Node).get_children().filter(func(n: Node) -> bool: return not n.is_queued_for_deletion())
	(cards[1].find_child("Build", true, false) as Button).pressed.emit()  # Frost costs more than the 50 left
	await _frames(1)
	_check("not enough gold: clear message, nothing built", FROST.cost > 50 and slot.is_empty()
		and message.text == "Not enough gold! Frost Tower costs %d." % FROST.cost)
	var cost_label: Label = _cost_label(cards[1])
	_check("unaffordable prices are shown in red", cost_label.get_theme_color("font_color").r > 0.9 and cost_label.get_theme_color("font_color").g < 0.6)

	hero.position = Vector2(-200, 200)
	await _frames(3)
	_check("walking away closes the menu", not menu.call("is_open") and builder.get_active_slot() == null)

	# Game Over while the menu is open: the menu closes.
	hero.position = slot.position + Vector2(0, 40)
	await _frames(3)
	await _press_interact()
	(level.get_node("Fortress") as Fortress).health.take_damage(1000)
	await _frames(3)
	_check("Game Over closes the menu", not menu.call("is_open"))
	await _free(level)


func _slots_placed_well(level: Level, slots: Array[BuildSlot]) -> bool:
	var floor_node: ColorRect = level.get_node("%Floor")
	var arena: Rect2 = Rect2(floor_node.position, floor_node.size).grow(-48)
	var fortress: Vector2 = (level.get_node("Fortress") as Node2D).global_position
	for slot: BuildSlot in slots:
		var lane_distance: float = INF
		for lane: Path2D in (level.get_node("WaveSpawner") as WaveSpawner).lanes:
			var local: Vector2 = lane.to_local(slot.global_position)
			lane_distance = minf(lane_distance, local.distance_to(lane.curve.get_closest_point(local)))
		if lane_distance < LANE_CLEARANCE or not arena.has_point(slot.global_position) or slot.global_position.distance_to(fortress) < 110.0:
			print("  badly placed slot %s (lane %.0f px)" % [slot.position, lane_distance])
			return false
	return true


func _labels_in(card: Node) -> Array[String]:
	var texts: Array[String] = []
	for node: Node in card.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return texts


func _cost_label(card: Node) -> Label:
	return card.find_children("*", "Label", true, false)[1]


func _press_interact() -> void:
	var press: InputEventAction = InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	Input.parse_input_event(press)
	await _frames(1)
	var release: InputEventAction = InputEventAction.new()
	release.action = "interact"
	release.pressed = false
	Input.parse_input_event(release)
	await _frames(1)


func _panel_fits(panel: Control) -> bool:
	var screen: Rect2 = Rect2(Vector2.ZERO, panel.get_viewport_rect().size)
	return screen.encloses(panel.get_global_rect()) and is_equal_approx(panel.size.y, panel.get_combined_minimum_size().y)


func _make_level(count: int) -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	WaveFixtures.single_wave(spawner, count, 2.0)
	(level.get_node("%Economy") as Economy).starting_gold = START_GOLD
	root.add_child(level)
	return level


func _free(level: Node) -> void:
	level.queue_free()
	await _frames(2)


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
