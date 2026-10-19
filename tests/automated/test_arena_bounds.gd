extends SceneTree
## Automated check for the prototype arena's boundaries: walls, camera limits, ground art and lane placement.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const HERO_RADIUS: float = 16.0
const GHOUL_RADIUS: float = 14.0
const WORLD_LAYER: int = 1
const Layouts: GDScript = preload("res://tools/art/sheet_layouts.gd")
## CharacterBody2D stops up to safe_margin (0.08 px) short of a wall.
const TOLERANCE: float = 0.5

var _failures: int = 0


func _initialize() -> void:
	var level: Level = (load("res://levels/prototype_arena.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await WaveFixtures.start_wave(level)
	await _frames(2)
	var floor_rect_node: ColorRect = level.get_node("%Floor")
	var arena: Rect2 = Rect2(floor_rect_node.position, floor_rect_node.size)
	var hero: Hero = level.get_node("Hero")
	var camera: Camera2D = hero.get_node("Camera2D")
	var bounds: StaticBody2D = level.get_node("ArenaBounds")

	# --- Dimensions agree ---
	_check("arena is the floor rect (%s)" % arena, arena == Rect2(-900, -500, 1300, 900))
	# The camera may show the visible wall band around the floor, and nothing beyond it.
	var view: Rect2 = arena.grow(Layouts.WALL_BAND)
	_check("camera limits = arena + wall band (%s)" % view,
		camera.limit_left == int(view.position.x) and camera.limit_top == int(view.position.y)
		and camera.limit_right == int(view.end.x) and camera.limit_bottom == int(view.end.y))
	var ground: Sprite2D = level.get_node("%Ground")
	var ground_rect: Rect2 = Rect2(ground.position, ground.texture.get_size() * ground.scale)
	_check("ground art covers exactly arena + wall band (%s)" % ground_rect, ground_rect == view and not ground.centered)
	_check("the wall band lies on the collision walls",
		_wall_rect(bounds, "WallTop").position.y <= view.position.y and _wall_rect(bounds, "WallLeft").position.x <= view.position.x
		and _wall_rect(bounds, "WallBottom").end.y >= view.end.y and _wall_rect(bounds, "WallRight").end.x >= view.end.x)
	_check("walls are on the world layer, hero collides with it",
		bounds.collision_layer == WORLD_LAYER and hero.collision_mask & WORLD_LAYER != 0)
	_check("top wall's inner edge = arena top", is_equal_approx(_wall_rect(bounds, "WallTop").end.y, arena.position.y))
	_check("bottom wall's inner edge = arena bottom", is_equal_approx(_wall_rect(bounds, "WallBottom").position.y, arena.end.y))
	_check("left wall's inner edge = arena left", is_equal_approx(_wall_rect(bounds, "WallLeft").end.x, arena.position.x))
	_check("right wall's inner edge = arena right", is_equal_approx(_wall_rect(bounds, "WallRight").position.x, arena.end.x))
	_check("walls close the corners",
		_wall_rect(bounds, "WallTop").position.x <= _wall_rect(bounds, "WallLeft").position.x
		and _wall_rect(bounds, "WallBottom").end.x >= _wall_rect(bounds, "WallRight").end.x)

	# --- All four boundaries stop the hero (2 s of walking = 400 px, more than enough) ---
	await _walk(hero, Vector2(-700, 200), ["move_left"])
	_check("left boundary (x=%.1f)" % hero.position.x, _near(hero.position.x, arena.position.x + HERO_RADIUS))
	await _walk(hero, Vector2(200, 200), ["move_right"])
	_check("right boundary (x=%.1f)" % hero.position.x, _near(hero.position.x, arena.end.x - HERO_RADIUS))
	await _walk(hero, Vector2(-600, -300), ["move_up"])
	_check("top boundary (y=%.1f)" % hero.position.y, _near(hero.position.y, arena.position.y + HERO_RADIUS))
	await _walk(hero, Vector2(-600, 200), ["move_down"])
	_check("bottom boundary (y=%.1f)" % hero.position.y, _near(hero.position.y, arena.end.y - HERO_RADIUS))
	await _walk(hero, Vector2(-750, -350), ["move_up", "move_left"])
	_check("corner holds too (%s)" % hero.position,
		_near(hero.position.x, arena.position.x + HERO_RADIUS) and _near(hero.position.y, arena.position.y + HERO_RADIUS))

	# --- Enemies are unaffected ---
	var lane: Path2D = level.get_node("Lane")
	var playable: Rect2 = arena.grow(-GHOUL_RADIUS)
	var lane_inside: bool = true
	for point: Vector2 in lane.curve.get_baked_points():
		lane_inside = lane_inside and playable.has_point(lane.to_global(point))
	_check("whole lane lies inside the arena", lane_inside)
	var fortress: Fortress = level.get_node("Fortress")
	var frames: int = 0
	while fortress.health.current_health == 100 and frames < 1200:
		await physics_frame
		frames += 1
	_check("first ghoul still reaches the fortress (%.1f s after the walking checks)" % (frames / 60.0), fortress.health.current_health == 90)

	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	level.queue_free()
	await _frames(2)
	quit(_failures)


## Puts the hero at start, holds the given actions for 2 s, then releases them.
func _walk(hero: Hero, start: Vector2, actions: Array[String]) -> void:
	hero.position = start
	await _frames(2)
	for action: String in actions:
		Input.action_press(action)
	await _frames(120)
	for action: String in actions:
		Input.action_release(action)
	await _frames(2)


func _near(value: float, expected: float) -> bool:
	return absf(value - expected) <= TOLERANCE


func _wall_rect(bounds: StaticBody2D, wall_name: String) -> Rect2:
	var wall: CollisionShape2D = bounds.get_node(wall_name)
	var size: Vector2 = (wall.shape as RectangleShape2D).size
	return Rect2(wall.global_position - size / 2.0, size)


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
