extends SceneTree
## Automated check for the run map's generation and rules (RunMap), over many seeds of chapter 1's data
## (with events and shrines switched on, so their rules are checked too): the shape (rows, sizes, one
## boss), links (1-2 per node, every node reachable, no crossing links), the fixed rows (battles first,
## merchants before the boss), no elite too early, no shrine right after a shrine, no merchant right
## below the merchant row, enough fighting on every path, fights and twists assigned, the same seed
## giving the same map, and moving along it (choices, visit, finished).
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const RUN: RunData = preload("res://data/run/run.tres")
const SEEDS: int = 150

var _failures: int = 0


func _initialize() -> void:
	var chapter: ChapterData = RUN.chapters[0].duplicate()
	chapter.event_weight = 20.0
	chapter.shrine_weight = 12.0
	_test_shape_and_rules(chapter)
	_test_seeds(chapter)
	_test_moving(chapter)
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_shape_and_rules(chapter: ChapterData) -> void:
	var shape: bool = true
	var links_ok: bool = true
	var reachable: bool = true
	var no_cross: bool = true
	var fixed_rows: bool = true
	var elite_late: bool = true
	var shrine_rule: bool = true
	var merchant_rule: bool = true
	var combat_rule: bool = true
	var fights: bool = true
	var kinds: Dictionary = {}
	for s: int in SEEDS:
		var map: RunMap = RunMap.generate(chapter, s)
		shape = shape and map.get_row(chapter.rows).size() == 1 and map.get_row(chapter.rows + 1).is_empty()
		for row: int in range(1, chapter.rows):
			shape = shape and map.get_row(row).size() == chapter.row_sizes[row - 1]
			var nodes: Array[MapNode] = map.get_row(row)
			for i: int in nodes.size():
				links_ok = links_ok and nodes[i].links.size() >= 1 and nodes[i].links.size() <= 2
				if i > 0:
					no_cross = no_cross and nodes[i - 1].links.max() <= nodes[i].links.min()
		for node: MapNode in map.nodes:
			if node.row > 1:
				reachable = reachable and not map.get_parents(node).is_empty()
			if chapter.battle_rows.has(node.row):
				fixed_rows = fixed_rows and node.kind == RunMap.Kind.BATTLE
			elif node.row == chapter.merchant_row:
				fixed_rows = fixed_rows and node.kind == RunMap.Kind.MERCHANT
			elif node.row == chapter.rows:
				fixed_rows = fixed_rows and node.kind == RunMap.Kind.BOSS
			else:
				kinds[node.kind] = int(kinds.get(node.kind, 0)) + 1
			if node.kind == RunMap.Kind.ELITE:
				elite_late = elite_late and node.row >= chapter.first_elite_row
				fights = fights and node.encounter != null and node.encounter.leader != null and node.affix != null
			if node.kind == RunMap.Kind.BATTLE:
				fights = fights and node.encounter != null and node.encounter.row == node.row
			if node.kind == RunMap.Kind.SHRINE:
				shrine_rule = shrine_rule and not map.get_parents(node).any(func(p: MapNode) -> bool: return p.kind == RunMap.Kind.SHRINE)
			if node.kind == RunMap.Kind.MERCHANT and node.row != chapter.merchant_row:
				merchant_rule = merchant_rule and node.row != chapter.merchant_row - 1
		fights = fights and map.get_boss().encounter == chapter.boss
		for p: Array in map.all_paths():
			var mixed: int = p.filter(func(n: MapNode) -> bool: return n.is_combat() and n.row > 2 and n.row < chapter.merchant_row).size()
			combat_rule = combat_rule and mixed >= chapter.min_mixed_combat and (p.back() as MapNode).kind == RunMap.Kind.BOSS
	_check("%d maps: 8 rows of the chapter's sizes, one boss" % SEEDS, shape)
	_check("every node links to 1-2 nodes of the next row, and links never cross", links_ok and no_cross)
	_check("every node can be reached, every path ends at the boss", reachable and combat_rule)
	_check("rows 1-2 are battles, row 7 merchants, row 8 the boss", fixed_rows)
	_check("no elite before row %d; every elite has its mini-boss and a twist" % chapter.first_elite_row, elite_late and fights)
	_check("no shrine right after a shrine; no merchant right below the merchant row", shrine_rule and merchant_rule)
	_check("every path holds at least %d battles or elites in the mixed rows" % chapter.min_mixed_combat, combat_rule)
	var total: float = 0.0
	for kind: int in kinds:
		total += kinds[kind]
	var share: Callable = func(kind: RunMap.Kind) -> float: return int(kinds.get(kind, 0)) / total
	_check("mixed rows: battles most common, then events, elites, shrines, merchants (%s)" % str(kinds.keys().map(func(k: int) -> String: return "%s %d%%" % [MapScreen.NAMES[k], roundi(share.call(k) * 100.0)])),
		share.call(RunMap.Kind.BATTLE) > share.call(RunMap.Kind.EVENT) and share.call(RunMap.Kind.EVENT) > share.call(RunMap.Kind.SHRINE)
		and share.call(RunMap.Kind.ELITE) > share.call(RunMap.Kind.MERCHANT) and share.call(RunMap.Kind.MERCHANT) > 0.0)


func _test_seeds(chapter: ChapterData) -> void:
	var a: RunMap = RunMap.generate(chapter, 7)
	var b: RunMap = RunMap.generate(chapter, 7)
	var c: RunMap = RunMap.generate(chapter, 8)
	_check("the same seed gives the same map", _signature(a) == _signature(b))
	_check("another seed gives another map", _signature(a) != _signature(c))


func _test_moving(chapter: ChapterData) -> void:
	var map: RunMap = RunMap.generate(chapter, 3)
	_check("at the start the choices are row 1", map.get_choices() == map.get_row(1) and map.get_current() == null)
	var far: MapNode = map.get_row(3)[0]
	_check("a node that isn't a choice can't be visited", not map.visit(far) and map.path.is_empty())
	var first: MapNode = map.get_row(1)[0]
	_check("visiting a choice moves there; its links are the next choices", map.visit(first) and map.get_current() == first
		and map.get_choices().map(func(n: MapNode) -> int: return n.index) == Array(first.links))
	while not map.is_finished():
		map.visit(map.get_choices()[0])
	_check("following the links always ends at the boss (path of %d)" % map.path.size(), map.get_current() == map.get_boss() and map.path.size() == chapter.rows
		and map.get_choices().is_empty())


func _signature(map: RunMap) -> String:
	return ";".join(map.nodes.map(func(n: MapNode) -> String: return "%d%s" % [n.kind, str(n.links)]))


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
