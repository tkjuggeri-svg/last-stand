extends SceneTree
## Automated check for the upgrade offers and the choice screen: 3 different cards per offer,
## non-stackable upgrades never offered again once taken, rarity weighting, seeded (reproducible)
## offers, one reroll per offer at a rising price, and the real flow: a cleared wave (not the last)
## opens the choice screen and pauses the game, the keyboard takes a card, the build phase follows,
## and the HUD shows the upgrade.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"

var _failures: int = 0


func _initialize() -> void:
	_test_offers()
	_test_seeds_and_rarity()
	await _test_flow()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_offers() -> void:
	var setup: Array = _offers(_pool(), 7)
	var offers: UpgradeOffers = setup[0]
	var mods: RunModifiers = setup[1]
	var economy: Economy = setup[2]
	var distinct: bool = true
	for _i: int in 50:
		var cards: Array[UpgradeData] = offers.make_offer()
		var ids: Dictionary = {}
		for card: UpgradeData in cards:
			ids[card.id] = true
		distinct = distinct and cards.size() == 3 and ids.size() == 3
	_check("every offer has 3 different cards (50 offers)", distinct)
	var once: UpgradeData = offers.pool.filter(func(d: UpgradeData) -> bool: return not d.stackable)[0]
	mods.add_upgrade(once)
	var seen_again: bool = false
	for _i: int in 80:
		seen_again = seen_again or offers.make_offer().has(once)
	_check("a non-stackable upgrade is never offered again once taken (80 offers)", not seen_again)
	var stackable: UpgradeData = offers.pool.filter(func(d: UpgradeData) -> bool: return d.stackable)[0]
	mods.add_upgrade(stackable)
	var stack_seen: bool = false
	for _i: int in 80:
		stack_seen = stack_seen or offers.make_offer().has(stackable)
	_check("a stackable one keeps coming back", stack_seen)
	# Pick.
	var offer: Array[UpgradeData] = offers.make_offer()
	var picked: Array[UpgradeData] = []
	offers.picked.connect(func(d: UpgradeData) -> void: picked.append(d))
	_check("taking a card adds it to the run and closes the offer",
		offers.pick(1) and picked == [offer[1]] and mods.get_stacks(offer[1].id) >= 1 and not offers.is_offer_open())
	_check("no second pick from a closed offer", not offers.pick(0))
	# Reroll.
	offer = offers.make_offer()
	economy.earn(100, Economy.Source.KILL)
	var gold: int = economy.get_gold()
	var first_cost: int = offers.get_reroll_cost()
	_check("a reroll costs %d gold and draws a new offer" % first_cost, offers.reroll() and economy.get_gold() == gold - first_cost
		and offers.get_offer().size() == 3 and offers.is_rerolled())
	_check("only one reroll per offer", not offers.can_reroll() and not offers.reroll())
	offers.pick(0)
	offers.make_offer()
	_check("the next reroll costs more (%d -> %d)" % [first_cost, offers.get_reroll_cost()], offers.get_reroll_cost() > first_cost)
	economy.try_spend(economy.get_gold())
	_check("no reroll without the gold", not offers.reroll() and economy.get_gold() == 0)
	# A small pool.
	var small: Array = _offers(_pool().slice(0, 2), 3)
	_check("with only 2 upgrades left the offer has 2 cards", (small[0] as UpgradeOffers).make_offer().size() == 2)
	for node: Node in [setup[0], setup[1], setup[2], small[0], small[1], small[2]]:
		node.queue_free()


func _test_seeds_and_rarity() -> void:
	var a: UpgradeOffers = _offers(_pool(), 42)[0]
	var b: UpgradeOffers = _offers(_pool(), 42)[0]
	var c: UpgradeOffers = _offers(_pool(), 43)[0]
	var same: bool = true
	var differs: bool = false
	for _i: int in 10:
		var ids_a: Array = a.make_offer().map(func(d: UpgradeData) -> StringName: return d.id)
		same = same and ids_a == b.make_offer().map(func(d: UpgradeData) -> StringName: return d.id)
		differs = differs or ids_a != c.make_offer().map(func(d: UpgradeData) -> StringName: return d.id)
	_check("the same seed gives the same offers; another seed other offers", same and differs)
	var commons: int = 0
	var rares: int = 0
	for _i: int in 300:
		for card: UpgradeData in a.make_offer():
			if card.rarity == UpgradeData.Rarity.RARE:
				rares += 1
			else:
				commons += 1
	# The pool has 4 commons and 2 rares; at weights 3:1 a single card is common 6 times as often.
	_check("rare cards show up less often (%d common, %d rare)" % [commons, rares], rares > 0 and commons > rares * 2)
	for offers: UpgradeOffers in [a, b, c]:
		offers.modifiers.queue_free()
		offers.economy.queue_free()
		offers.queue_free()


func _test_flow() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = [WaveFixtures.make_wave(1, 0.2), WaveFixtures.make_wave(1, 0.2)]
	var offers: UpgradeOffers = level.get_node("%UpgradeOffers")
	offers.pool = _pool()
	offers.seed_value = 5
	(level.get_node("Hero") as Node2D).position = Vector2(380, 380)
	root.add_child(level)
	await _frames(2)
	var cycle: RunCycle = level.get_node("%RunCycle")
	var screen: UpgradeChoiceScreen = level.get_node("UpgradeChoiceScreen")
	spawner.enemy_spawned.connect(func(e: Enemy) -> void:
		(e.get_node("%HealthComponent") as HealthComponent).take_damage.call_deferred(1000))
	cycle.start_wave()
	for _i: int in 120:
		await physics_frame
		if cycle.get_phase() == RunCycle.Phase.CHOOSE:
			break
	await _frames(2)
	_check("a cleared wave opens the upgrade choice (not yet the build phase)", cycle.get_phase() == RunCycle.Phase.CHOOSE
		and screen.is_open() and screen.get_take_buttons().size() == 3)
	_check("...and pauses the game", paused)
	_check("no wave can start while choosing", not cycle.can_start_wave())
	var phase_label: Label = level.get_node("HUD").get_node("%PhaseLabel")
	_check("HUD: \"Choose an upgrade\"", phase_label.text == "Choose an upgrade")
	_check("the first card has keyboard focus", screen.get_take_buttons()[0].has_focus())
	var offer: Array[UpgradeData] = offers.get_offer()
	await _press(&"ui_right")
	await _press(&"ui_accept")
	await _frames(2)
	var mods: RunModifiers = level.get_node("%RunModifiers")
	_check("arrow right + Enter takes the second card (%s)" % offer[1].display_name, mods.get_stacks(offer[1].id) == 1 and mods.get_taken().size() == 1)
	_check("then the screen closes, the game runs again and the build phase begins",
		not screen.is_open() and not paused and cycle.get_phase() == RunCycle.Phase.BUILD)
	var icons: Node = level.get_node("HUD").get_node("%UpgradeIcons")
	var shown: Array[Node] = icons.get_children().filter(func(n: Node) -> bool: return n is TextureRect)
	_check("the HUD shows the upgrade's icon", shown.size() == 1 and shown[0].name == String(offer[1].id))
	cycle.start_wave()
	for _i: int in 120:
		await physics_frame
		if level.is_run_over():
			break
	_check("after the last wave there is no offer: the run is won", level.is_run_over() and not screen.is_open() and not paused)
	level.queue_free()
	await _frames(2)


## 4 commons (one of them non-stackable) and 2 rares.
func _pool() -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = []
	for i: int in 6:
		var data: UpgradeData = UpgradeData.new()
		data.id = StringName("up_%d" % i)
		data.display_name = "Upgrade %d" % i
		data.description = "Does thing %d." % i
		data.rarity = UpgradeData.Rarity.RARE if i >= 4 else UpgradeData.Rarity.COMMON
		data.stackable = i != 2
		pool.append(data)
	return pool


## [offers, modifiers, economy], in the tree.
func _offers(pool: Array[UpgradeData], seed_value: int) -> Array:
	var mods: RunModifiers = RunModifiers.new()
	var economy: Economy = Economy.new()
	economy.starting_gold = 0
	var offers: UpgradeOffers = UpgradeOffers.new()
	offers.modifiers = mods
	offers.economy = economy
	offers.pool = pool
	offers.seed_value = seed_value
	root.add_child(mods)
	root.add_child(economy)
	root.add_child(offers)
	return [offers, mods, economy]


func _press(action: StringName) -> void:
	var press: InputEventAction = InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release: InputEventAction = InputEventAction.new()
	release.action = action
	Input.parse_input_event(release)
	await process_frame


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
