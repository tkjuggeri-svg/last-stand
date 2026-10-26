extends SceneTree
## Variant B's mouse projection (look-test): world points survive a round trip through the tilted camera, the
## provider answers what the mouse points at, the hero aims at it, and a build slot highlights when the mouse is
## over it, all with the 2D gameplay code unchanged but for WorldPointer. Needs a window.
##   godot --path . --resolution 1280x720 --script res://experiments/look_test/test_look_b_mouse.gd

var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var host: Node = Node.new()
	root.add_child(host)
	var presenter: Node = (load("res://experiments/look_test/variant_b/look_b.gd") as GDScript).new()
	host.add_child(presenter)
	var level: Level = await LookStage.build(host, self)
	presenter.call("attach", level)
	for _i: int in 10:
		await process_frame
	var hero: Hero = level.get_node("Hero")
	var worst: float = 0.0
	for gx: int in range(-5, 6):
		for gy: int in range(-4, 5):
			var point: Vector2 = hero.global_position + Vector2(gx * 40.0, gy * 30.0)
			var back: Vector2 = presenter.call("ground_at", presenter.call("screen_of", point))
			worst = maxf(worst, back.distance_to(point))
	_check("world -> screen -> world round trip, worst error %.3f px over 99 points" % worst, worst < 0.5)

	var target: Vector2 = hero.global_position + Vector2(120, 40)
	await _point_mouse(presenter.call("screen_of", target))
	var answered: Vector2 = WorldPointer.position_for(hero)
	_check("the provider says %s for a mouse at the screen point of %s" % [answered.round(), target], answered.distance_to(target) < 2.0)

	var slot: BuildSlot = level.get_node("%TowerBuilder").get_slots()[0]
	await _point_mouse(presenter.call("screen_of", slot.global_position + Vector2(0, -2)))
	await process_frame
	_check("the build slot is highlighted with the mouse on it", slot.is_hovered())
	await _point_mouse(presenter.call("screen_of", slot.global_position + Vector2(260, 120)))
	await process_frame
	_check("...and not with the mouse away from it", not slot.is_hovered())

	var bot_driver: Node = level.get_node_or_null("BotDriver")
	_check("no bot is driving the hero in this test", bot_driver == null)
	for side: int in [-1, 1]:
		await _point_mouse(presenter.call("screen_of", hero.global_position + Vector2(side * 140.0, 10)))
		Input.action_press("attack")
		for _i: int in 6:
			await physics_frame
		Input.action_release("attack")
		var sprite: DirectionalSprite = hero.get_node("Sprite")
		_check("the hero aims %s at a mouse to the %s (facing %s, flipped %s)" % ["left" if side < 0 else "right", "left" if side < 0 else "right", sprite.facing, sprite.flip_h],
			sprite.facing == "side" and sprite.flip_h == (side < 0))
		for _i: int in 40:
			await physics_frame
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _point_mouse(at: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	Input.parse_input_event(event)
	root.warp_mouse(at)
	for _i: int in 3:
		await process_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
