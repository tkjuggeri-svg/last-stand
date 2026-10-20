class_name RunMap
extends RefCounted
## One chapter's node map (Slay the Spire style), generated from its ChapterData and a seed: rows of
## nodes from row 1 (the start) up to the boss, each node linked to 1-2 nodes of the next row with no
## crossing links, every node reachable and every path ending at the boss. Rules (from the data):
## battle rows, a merchant row before the boss, no elite before first_elite_row, no shrine right after
## a shrine on any path, no merchant in the row below the merchant row, and every path holds at least
## min_mixed_combat battles or elites in the mixed rows. Also tracks where the player is and which
## nodes they may pick next. Plain data and rules: MapScreen shows it, Main plays its nodes.

enum Kind { BATTLE, ELITE, EVENT, SHRINE, MERCHANT, BOSS }

## Chance that a node gets a second link (to a neighbour in the next row), when it can.
const EXTRA_LINK_CHANCE: float = 0.35

var chapter: ChapterData
## All nodes, row by row (row 1 first), left to right within a row.
var nodes: Array[MapNode] = []
## Nodes visited so far, in order (the last one is where the player stands; empty before the first).
var path: Array[MapNode] = []


## A fresh map for `chapter_data` from `seed_value` (the same seed always gives the same map).
static func generate(chapter_data: ChapterData, seed_value: int) -> RunMap:
	var map: RunMap = RunMap.new()
	map.chapter = chapter_data
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	map._build_rows()
	map._link_rows(rng)
	map._assign_kinds(rng)
	map._assign_fights(rng)
	return map


func get_row(row: int) -> Array[MapNode]:
	return nodes.filter(func(n: MapNode) -> bool: return n.row == row)


func get_boss() -> MapNode:
	return get_row(chapter.rows)[0]


func get_current() -> MapNode:
	return path.back() if not path.is_empty() else null


## The nodes the player may pick now: row 1 at the start, then the current node's links.
func get_choices() -> Array[MapNode]:
	var current: MapNode = get_current()
	if current == null:
		return get_row(1)
	var choices: Array[MapNode] = []
	for index: int in current.links:
		choices.append(nodes[index])
	return choices


## Moves to `node` if it is one of the choices. Returns false (and changes nothing) otherwise.
func visit(node: MapNode) -> bool:
	if not get_choices().has(node):
		return false
	path.append(node)
	return true


func is_finished() -> bool:
	return get_current() == get_boss()


## Nodes of row r-1 that link to `node`.
func get_parents(node: MapNode) -> Array[MapNode]:
	return get_row(node.row - 1).filter(func(n: MapNode) -> bool: return n.links.has(node.index))


## Every path from row 1 to the boss, as arrays of nodes (for tests and the balance tool).
func all_paths() -> Array:
	var paths: Array = []
	for start: MapNode in get_row(1):
		_collect_paths([start], paths)
	return paths


func _collect_paths(so_far: Array, paths: Array) -> void:
	var last: MapNode = so_far.back()
	if last.links.is_empty():
		paths.append(so_far)
		return
	for index: int in last.links:
		_collect_paths(so_far + [nodes[index]], paths)


func _build_rows() -> void:
	for row: int in range(1, chapter.rows + 1):
		var count: int = 1 if row == chapter.rows else chapter.row_sizes[mini(row - 1, chapter.row_sizes.size() - 1)]
		for column: int in count:
			var node: MapNode = MapNode.new()
			node.index = nodes.size()
			node.row = row
			node.column = column
			node.x = 0.5 if count == 1 else float(column) / (count - 1)
			nodes.append(node)


## Links each row to the next: every lower node to its "home" node above (monotone, so links never
## cross), sometimes a second neighbour, then every upper node without a link gets one.
func _link_rows(rng: RandomNumberGenerator) -> void:
	for row: int in range(1, chapter.rows):
		var lower: Array[MapNode] = get_row(row)
		var upper: Array[MapNode] = get_row(row + 1)
		var low_hi: Array[Vector2i] = []  # per lower node: the range of upper columns it links to
		for i: int in lower.size():
			var home: int = roundi(float(i) * (upper.size() - 1) / maxf(lower.size() - 1, 1.0)) if lower.size() > 1 else floori((upper.size() - 1) * 0.5)
			low_hi.append(Vector2i(home, home))
		# A second link to a neighbour, only where it can't cross the next node's links.
		for i: int in lower.size():
			if rng.randf() >= EXTRA_LINK_CHANCE:
				continue
			var right: bool = rng.randf() < 0.5
			if right and low_hi[i].y + 1 < upper.size() and (i == lower.size() - 1 or low_hi[i + 1].x >= low_hi[i].y + 1):
				low_hi[i].y += 1
			elif not right and low_hi[i].x - 1 >= 0 and (i == 0 or low_hi[i - 1].y <= low_hi[i].x - 1):
				low_hi[i].x -= 1
		# Upper nodes nobody reaches: give them to the lower node whose range ends just before them.
		for j: int in upper.size():
			var covered: bool = false
			for r: Vector2i in low_hi:
				covered = covered or (j >= r.x and j <= r.y)
			if covered:
				continue
			var owner: int = 0
			for i: int in lower.size():
				if low_hi[i].y < j:
					owner = i
			low_hi[owner].y = maxi(low_hi[owner].y, j)
			low_hi[owner].x = mini(low_hi[owner].x, j)
		for i: int in lower.size():
			for j: int in range(low_hi[i].x, low_hi[i].y + 1):
				lower[i].links.append(upper[j].index)


func _assign_kinds(rng: RandomNumberGenerator) -> void:
	for node: MapNode in nodes:
		if node.row == chapter.rows:
			node.kind = Kind.BOSS
		elif chapter.battle_rows.has(node.row):
			node.kind = Kind.BATTLE
		elif node.row == chapter.merchant_row:
			node.kind = Kind.MERCHANT
		else:
			node.kind = _draw_kind(node, rng)
	_ensure_combat()


func _draw_kind(node: MapNode, rng: RandomNumberGenerator) -> Kind:
	var kinds: Array[Kind] = [Kind.BATTLE, Kind.ELITE, Kind.EVENT, Kind.SHRINE, Kind.MERCHANT]
	var weights: PackedFloat32Array = PackedFloat32Array([chapter.battle_weight, chapter.elite_weight, chapter.event_weight,
		chapter.shrine_weight, chapter.merchant_weight])
	if node.row < chapter.first_elite_row:
		weights[1] = 0.0
	if get_parents(node).any(func(p: MapNode) -> bool: return p.kind == Kind.SHRINE):
		weights[3] = 0.0
	if chapter.merchant_row > 0 and node.row == chapter.merchant_row - 1:
		weights[4] = 0.0
	var total: float = 0.0
	for w: float in weights:
		total += w
	return kinds[rng.rand_weighted(weights)] if total > 0.0 else Kind.BATTLE


## Every path must hold min_mixed_combat battles or elites in the mixed rows: where one doesn't, the
## first non-combat node on its leanest stretch becomes a battle (repeated until every path does).
func _ensure_combat() -> void:
	for _guard: int in nodes.size():
		var lean: Array = []
		for p: Array in all_paths():
			if _mixed_combat(p) < chapter.min_mixed_combat:
				lean = p
				break
		if lean.is_empty():
			return
		for node: MapNode in lean:
			if _is_mixed_row(node.row) and not node.is_combat():
				node.kind = Kind.BATTLE
				break


func _mixed_combat(p: Array) -> int:
	return p.filter(func(n: MapNode) -> bool: return _is_mixed_row(n.row) and n.is_combat()).size()


func _is_mixed_row(row: int) -> bool:
	return row < chapter.rows and not chapter.battle_rows.has(row) and row != chapter.merchant_row


## Gives every battle and elite its fight (one of its row's encounters) and every elite an affix.
func _assign_fights(rng: RandomNumberGenerator) -> void:
	for node: MapNode in nodes:
		match node.kind:
			Kind.BATTLE:
				node.encounter = _pick(chapter.encounters_for(chapter.battles, node.row), rng)
			Kind.ELITE:
				node.encounter = _pick(chapter.encounters_for(chapter.elites, node.row), rng)
				if not chapter.affixes.is_empty():
					node.affix = chapter.affixes[rng.randi_range(0, chapter.affixes.size() - 1)]
			Kind.BOSS:
				node.encounter = chapter.boss


func _pick(pool: Array[EncounterData], rng: RandomNumberGenerator) -> EncounterData:
	return pool[rng.randi_range(0, pool.size() - 1)] if not pool.is_empty() else null
