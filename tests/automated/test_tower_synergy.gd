extends SceneTree
## Automated check for the tower pair bonuses (TowerSynergy): every tower has one, naming another
## tower that exists; a tower gets its bonus while a partner stands within the synergy's reach (Cannon
## and Frost on neighbouring slots: a wider blast, a longer slow), not when the partner is further or
## sold, and keeps it through an upgrade; the bonus shows (the ember mark, the tower menu's line, a
## link to the partner), and the build preview links to the towers a new one would pair with.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const TOWERS_DIR: String = "res://data/towers"
const CANNON: TowerData = preload("res://data/towers/cannon.tres")
const FROST: TowerData = preload("res://data/towers/frost.tres")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_rules()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_data() -> void:
	var ids: Array[StringName] = []
	var all: Array[TowerData] = []
	for file: String in DirAccess.get_files_at(TOWERS_DIR):
		if file.ends_with(".tres"):
			all.append(load(TOWERS_DIR.path_join(file)) as TowerData)
			ids.append(all.back().id)
	var good: bool = true
	for data: TowerData in all:
		good = good and data.synergies.size() == 1
		for synergy: TowerSynergy in data.synergies:
			good = good and ids.has(synergy.partner_id) and synergy.partner_id != data.id and not synergy.display_name.is_empty() \
				and not synergy.describe_bonus().is_empty() and synergy.reach > 0.0
	_check("each of the %d towers has one pair bonus, with another real tower" % all.size(), good and all.size() == 5)


func _test_rules() -> void:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	(level.get_node("WaveSpawner") as WaveSpawner).waves = [WaveData.new()]
	WaveFixtures.no_upgrades(level)
	root.add_child(level)
	await _frames(2)
	var builder: TowerBuilder = level.builder
	level.economy.earn(5000, Economy.Source.REFUND)
	var slots: Array[BuildSlot] = builder.get_slots()
	var reach: float = (CANNON.synergies[0] as TowerSynergy).reach
	var pair: Array[BuildSlot] = _pair(slots, reach)
	var far: BuildSlot = _far_from(slots, pair[0], reach)
	builder.build(pair[0], CANNON)
	await _frames(2)
	var cannon: Tower = pair[0].tower
	var base_splash: float = cannon.get_stats().splash_radius
	_check("a Cannon alone: no pair bonus", cannon.get_synergies().is_empty() and not (cannon.get_node("%BoostMark") as CanvasItem).visible)
	builder.build(pair[1], FROST)
	await _frames(2)
	var frost: Tower = pair[1].tower
	_check("a Frost %d px away: the Cannon's blast +25%% (%.0f -> %.0f), the ember mark" % [roundi(pair[0].global_position.distance_to(pair[1].global_position)),
		base_splash, cannon.get_stats().splash_radius], cannon.get_synergies().size() == 1
		and is_equal_approx(cannon.get_stats().splash_radius, base_splash * 1.25) and (cannon.get_node("%BoostMark") as CanvasItem).visible)
	_check("...and the Frost's slow lasts 30%% longer (%.2f s)" % frost.get_stats().slow_duration, frost.get_synergies().size() == 1
		and is_equal_approx(frost.get_stats().slow_duration, FROST.stats_for(1).slow_duration * 1.3))
	await _frames(60)
	builder.upgrade(pair[0])
	await _frames(2)
	_check("an upgraded Cannon keeps it (level 2 blast x1.25)", is_equal_approx(cannon.get_stats().splash_radius, CANNON.stats_for(2).splash_radius * 1.25))
	var menu: Node = level.get_node("BuildMenu")
	menu.call("open", pair[0])
	await _frames(2)
	var info: String = (menu.get_node("%InfoStats") as Label).text
	_check("the tower menu: \"%s\", a link to the Frost" % info.get_slice("\n", info.get_slice_count("\n") - 1),
		info.contains("Active: Packed crowds") and pair[0].get_links() == [pair[1].global_position])
	menu.call("close")
	builder.sell(pair[1])
	await _frames(2)
	_check("the Frost sold: the bonus is gone", cannon.get_synergies().is_empty() and is_equal_approx(cannon.get_stats().splash_radius, CANNON.stats_for(2).splash_radius))
	builder.build(far, FROST)
	await _frames(2)
	_check("a Frost %d px away (reach %d): no bonus" % [roundi(far.global_position.distance_to(pair[0].global_position)), roundi(reach)],
		cannon.get_synergies().is_empty() and far.tower.get_synergies().is_empty())
	menu.call("open", pair[1])
	await _frames(2)
	menu.call("_preview", FROST)
	_check("the build preview of a Frost by the Cannon: a link to it, its bonus named", pair[1].get_links() == [pair[0].global_position]
		and (menu.get_node("%Details") as Label).text.contains("Shaken"))
	menu.call("_preview", ARCHER)
	_check("...an Archer there: no partner nearby, no link", pair[1].get_links().is_empty())
	menu.call("close")
	level.queue_free()
	await _frames(2)


## Two slots within `reach` of each other.
func _pair(slots: Array[BuildSlot], reach: float) -> Array[BuildSlot]:
	for a: BuildSlot in slots:
		for b: BuildSlot in slots:
			if a != b and a.global_position.distance_to(b.global_position) <= reach:
				return [a, b]
	return []


## A slot further than `reach` from `from`.
func _far_from(slots: Array[BuildSlot], from: BuildSlot, reach: float) -> BuildSlot:
	for slot: BuildSlot in slots:
		if slot.global_position.distance_to(from.global_position) > reach:
			return slot
	return null


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
