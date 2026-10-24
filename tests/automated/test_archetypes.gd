extends SceneTree
## Automated check for the archetypes (M9 stage 4): every card and relic has one or two known tags; once a
## run holds 2 cards of a tag, that tag's cards are drawn 1.6x as often, 2x at 4 (the weights, and over many
## seeded offers the counts); other cards are not affected; the HUD names the leading archetype.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const DIRS: Array[String] = ["res://data/upgrades", "res://data/relics"]

var _failures: int = 0


func _initialize() -> void:
	_test_tags()
	_test_weights()
	await _test_offers_and_hud()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _all() -> Array[UpgradeData]:
	var found: Array[UpgradeData] = []
	for dir: String in DIRS:
		for file: String in DirAccess.get_files_at(dir):
			if file.ends_with(".tres"):
				found.append(load(dir.path_join(file)) as UpgradeData)
	return found


func _card(id: String) -> UpgradeData:
	return load("res://data/upgrades/%s.tres" % id) as UpgradeData


func _test_tags() -> void:
	var good: bool = true
	var seen: Dictionary = {}
	var cards: Array[UpgradeData] = _all()
	for data: UpgradeData in cards:
		good = good and data.tags.size() in [1, 2]
		for tag: StringName in data.tags:
			good = good and Archetypes.TAGS.has(tag)
			seen[tag] = int(seen.get(tag, 0)) + 1
	_check("all %d cards and relics have one or two known tags" % cards.size(), good)
	_check("every archetype has at least 3 of them (%s)" % [seen], Archetypes.TAGS.all(func(t: StringName) -> bool: return int(seen.get(t, 0)) >= 3))


func _test_weights() -> void:
	var offers: UpgradeOffers = UpgradeOffers.new()
	var fire: UpgradeData = _card("hellfire")  # a rare card
	var other: UpgradeData = _card("fletching")  # a common one
	_check("no tags held: the plain rarity weights", is_equal_approx(offers.weight_of(fire, {}), offers.rare_weight)
		and is_equal_approx(offers.weight_of(other, {}), offers.common_weight))
	var two: Dictionary = {&"fire": 2}
	_check("2 fire cards held: a fire card weighs 1.6x, others the same", is_equal_approx(offers.weight_of(fire, two), offers.rare_weight * 1.6)
		and is_equal_approx(offers.weight_of(other, two), offers.common_weight))
	_check("4 held: 2x", is_equal_approx(offers.weight_of(fire, {&"fire": 4}), offers.rare_weight * 2.0))
	_check("a card of two tags uses its best", is_equal_approx(offers.weight_of(_card("cinder_dash"), {&"fire": 4, &"blade": 2}), offers.weight_of(_card("cinder_dash"), {}) * 2.0))
	offers.free()


func _test_offers_and_hud() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	root.add_child(level)
	await process_frame
	var offers: UpgradeOffers = level.offers
	var mods: RunModifiers = level.modifiers
	var tagged: int = 0
	var draws: int = 0
	var base_rate: float = 0.0
	for pass_index: int in 2:
		tagged = 0
		draws = 0
		offers.set_seed(7)
		for i: int in 600:
			for card: UpgradeData in offers.draw_cards(3):
				draws += 1
				if card.tags.has(&"blade"):
					tagged += 1
		if pass_index == 0:
			base_rate = float(tagged) / draws
			mods.add_upgrade(_card("honed_blade"))
			mods.add_upgrade(_card("honed_blade"))
	var lean_rate: float = float(tagged) / draws
	_check("holding 2 blade cards makes blade cards come up more (%.3f to %.3f)" % [base_rate, lean_rate], lean_rate > base_rate * 1.15)
	_check("the leading archetype is blade", Archetypes.leading(mods) == &"blade" and Archetypes.label(&"blade") == "Blade build")
	var build: Label = null
	for node: Node in level.find_children("Build", "Label", true, false):
		build = node as Label
	_check("the HUD's card row shows it (%s)" % [build.text if build != null else "no label"], build != null and build.visible and build.text == "Blade build")
	level.queue_free()
	await process_frame


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
