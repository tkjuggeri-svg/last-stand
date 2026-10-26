extends SceneTree
## Automated check for the Drowned Marsh (M7.5), chapter 2's battlefield: the chapter data picks it
## (chapter 1 keeps the graveyard arena); its layout is different (lanes winding around the water, two
## of them merging before the fortress; fewer, more spread-out build slots, none in the water or on a
## lane); it plays chapter 2's waves on its own (F6); its ground is its own bake; and the hero wades
## through its pools slower, with ripples around it, and walks at full speed again on dry land.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const MARSH: String = "res://levels/drowned_marsh.tscn"
const RUN: RunData = preload("res://data/run/run.tres")
## A lane counts as winding around the water if it passes this close to a pool.
const NEAR_WATER: float = 80.0
## Slots stay this far from every lane and from the water.
const SLOT_CLEARANCE: float = 45.0

var _failures: int = 0


func _initialize() -> void:
	_test_data()
	await _test_layout()
	await _test_wading()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_data() -> void:
	_check("chapter 1 is played on the graveyard arena", RUN.chapters[0].level_scene.resource_path == ARENA)
	_check("chapter 2 is played on the Drowned Marsh", RUN.chapters[1].level_scene.resource_path == MARSH)


func _test_layout() -> void:
	var arena: Level = (load(ARENA) as PackedScene).instantiate()
	var level: Level = (load(MARSH) as PackedScene).instantiate()
	root.add_child(level)
	await _frames(2)
	var slots: Array[BuildSlot] = level.builder.get_slots()
	var arena_slots: int = arena.get_node("BuildSlots").get_child_count()
	_check("fewer build slots than the graveyard (%d < %d)" % [slots.size(), arena_slots], slots.size() < arena_slots and slots.size() >= 6)
	var closest: float = INF
	for a: BuildSlot in slots:
		for b: BuildSlot in slots:
			if a != b:
				closest = minf(closest, a.global_position.distance_to(b.global_position))
	var arena_closest: float = _closest_pair(arena.get_node("BuildSlots"))
	_check("...and no tighter than the graveyard (closest pair %.0f px, graveyard %.0f px)" % [closest, arena_closest], closest >= 96.0 and closest > arena_closest)
	var water: MarshWater = level.get_node("Water")
	var pools: Array[PackedVector2Array] = water.get_pools()
	var lanes: Array[Path2D] = level.spawner.lanes
	var clear: bool = true
	for slot: BuildSlot in slots:
		for lane: Path2D in lanes:
			clear = clear and _distance_to_lane(slot.global_position, lane) >= SLOT_CLEARANCE
		clear = clear and _distance_to_water(slot.global_position, pools) >= SLOT_CLEARANCE * 0.5
	_check("no slot sits on a lane or in the water", clear)
	var winding: bool = true
	for lane: Path2D in lanes:
		var nearest: float = INF
		for point: Vector2 in lane.curve.get_baked_points():
			nearest = minf(nearest, _distance_to_water(lane.to_global(point), pools))
		winding = winding and nearest < NEAR_WATER
	_check("every lane winds past the water (%d pools)" % pools.size(), winding and pools.size() >= 4)
	var crossings: int = 0
	for lane: Path2D in lanes:
		var points: PackedVector2Array = lane.curve.get_baked_points()
		for i: int in range(0, points.size(), 4):
			if _distance_to_water(lane.to_global(points[i]), pools) < 0.0:
				crossings += 1
				break
	_check("some lanes cross a stream on a boardwalk (%d)" % crossings, crossings >= 2)
	var shared: float = _shared_length(lanes[0], lanes[2])
	_check("the west and south lanes merge before the fortress (%.0f px together)" % shared, shared >= 100.0)
	_check("its 15 waves are chapter 2's", level.spawner.waves.size() == 15 and level.spawner.waves[0].resource_path.contains("chapter_2"))
	var ground: TiledGround = level.get_node("%Ground")
	_check("its ground is its own bake", ground.texture.resource_path.contains("drowned_marsh"))
	arena.free()
	level.queue_free()
	await _frames(2)


func _test_wading() -> void:
	var level: Level = (load(MARSH) as PackedScene).instantiate()
	level.spawner.waves = [WaveData.new()]
	root.add_child(level)
	await _frames(2)
	var hero: Hero = level.get_node("Hero")
	var water: MarshWater = level.get_node("Water")
	var pool: PackedVector2Array = water.get_pools()[3]  # the big south-east pool
	var middle: Vector2 = Vector2.ZERO
	for p: Vector2 in pool:
		middle += p / pool.size()
	var land: float = await _speed_at(hero, Vector2(-850, 0))
	_check("on dry land the hero walks at full speed (%.0f px/s), no ripples" % land, land > 190.0 and not hero.is_wading()
		and not (hero.get_node("%Ripple") as CanvasItem).visible)
	var wading: float = await _speed_at(hero, middle)
	_check("in a pool it wades at %d%% speed (%.0f px/s), ripples around it" % [roundi(water.wading_speed * 100.0), wading],
		hero.is_wading() and absf(wading - land * water.wading_speed) < 8.0 and (hero.get_node("%Ripple") as CanvasItem).visible)
	var back: float = await _speed_at(hero, Vector2(-850, 0))
	_check("back on land: full speed again (%.0f px/s)" % back, absf(back - land) < 4.0 and not hero.is_wading())
	level.queue_free()
	await _frames(2)


## Puts the hero at `at`, walks it right for half a second and returns its speed.
func _speed_at(hero: Hero, at: Vector2) -> float:
	hero.global_position = at
	await _frames(3)
	Input.action_press("move_right")
	await _frames(2)
	var start: Vector2 = hero.global_position
	await _frames(30)
	Input.action_release("move_right")
	var speed: float = (hero.global_position.x - start.x) * 2.0
	await _frames(2)
	return speed


func _closest_pair(slots_root: Node) -> float:
	var best: float = INF
	for a: Node2D in slots_root.get_children():
		for b: Node2D in slots_root.get_children():
			if a != b:
				best = minf(best, a.position.distance_to(b.position))
	return best


func _distance_to_lane(p: Vector2, lane: Path2D) -> float:
	return p.distance_to(lane.to_global(lane.curve.get_closest_point(lane.to_local(p))))


## Signed: negative inside a pool.
func _distance_to_water(p: Vector2, pools: Array[PackedVector2Array]) -> float:
	var best: float = INF
	for pool: PackedVector2Array in pools:
		var edge: float = INF
		for i: int in pool.size():
			edge = minf(edge, p.distance_to(Geometry2D.get_closest_point_to_segment(p, pool[i], pool[(i + 1) % pool.size()])))
		best = minf(best, -edge if Geometry2D.is_point_in_polygon(p, pool) else edge)
	return best


## How long the two lanes run together (on the same road) at their end.
func _shared_length(a: Path2D, b: Path2D) -> float:
	var points: PackedVector2Array = a.curve.get_baked_points()
	var shared: float = 0.0
	for i: int in range(points.size() - 1, 0, -1):
		if _distance_to_lane(a.to_global(points[i]), b) > 2.0:
			break
		shared += points[i].distance_to(points[i - 1])
	return shared


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
