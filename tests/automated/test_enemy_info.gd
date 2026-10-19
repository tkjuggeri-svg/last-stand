extends SceneTree
## Automated check for the enemy information HUD: counts, notifications and their wiring.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>
## The level's wave 1.
const WAVE_SIZE: int = 10

var _failures: int = 0


func _initialize() -> void:
	await _test_in_level()
	await _test_feed_widget()
	await _test_hud_alone()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_in_level() -> void:
	var level: Level = (load("res://levels/prototype_arena.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await WaveFixtures.start_wave(level)
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	var hud: CanvasLayer = level.get_node("HUD")
	var stats: Label = hud.get_node("%EnemyStatsLabel")
	var feed: NotificationFeed = hud.get_node("%NotificationFeed")
	var hero: Hero = level.get_node("Hero")
	var fortress: Fortress = level.get_node("Fortress")

	var events: Dictionary = {"spawned": 0, "killed": 0, "reached": 0, "label_lagged": false}
	spawner.enemy_spawned.connect(func(e: Enemy) -> void:
		events["spawned"] += 1
		e.reached_fortress.connect(func(_e: Enemy) -> void: events["reached"] += 1))
	var kill_frames: Array[int] = []
	spawner.enemy_killed.connect(func(_e: Enemy) -> void:
		events["killed"] += 1
		kill_frames.append(Engine.get_physics_frames()))
	# Listener order is not guaranteed, so check at the end of the same frame that the label
	# shows the latest counts (i.e. no frame ever displays stale numbers).
	spawner.enemy_counts_changed.connect(func(_living: int, _spawned: int) -> void:
		(func() -> void:
			if stats.text != _stats_text(spawner.get_remaining_count()):
				events["label_lagged"] = true).call_deferred())
	await _frames(2)

	# --- First spawn ---
	_check("a wave of 10: all still to deal with after the first spawn (%s)" % stats.text, stats.text == _stats_text(10))
	_check("wave start and 'Ghoul incoming!' shown (%s)" % [_feed_texts(feed)], _feed_texts(feed) == ["Wave 1 begins!", "Ghoul incoming!"])

	# --- Kill it ---
	var ghoul: Enemy = spawner.get_child(0)
	for _swing: int in 3:
		hero.position = ghoul.global_position + Vector2(40, 0)
		await _frames(1)
		hero.attack(ghoul.global_position)
		await _frames(27)
	_check("ghoul killed", not is_instance_valid(ghoul) and events["killed"] == 1)
	_check("a kill counts down the enemies left (%s)" % stats.text, stats.text == _stats_text(9))
	_check("'Ghoul slain!' shown", _feed_texts(feed).has("Ghoul slain!"))
	var slain_label: Label = _find_label(feed, "Ghoul slain!")

	# --- Messages fade on their own (2 s, then a 0.5 s fade), timed from the kill ---
	await _until_frame(kill_frames[0] + 132)
	_check("message fading 2.2 s after the kill", is_instance_valid(slain_label) and slain_label.modulate.a < 1.0)
	await _until_frame(kill_frames[0] + 165)
	_check("message gone 2.75 s after the kill", not is_instance_valid(slain_label))

	# --- Long run: counts always match reality; reaching the fortress is not a kill ---
	hero.position = Vector2(-200, 200)  # off the lane, so ghouls walk past instead of stopping to fight
	var counts_ok: bool = true
	var frames: int = 0
	while fortress.health.current_health == 100 and frames < 1200:
		await physics_frame
		frames += 1
		var living: int = spawner.get_living_count()
		counts_ok = (counts_ok
			and living == _alive_children(spawner).size()
			and living == events["spawned"] - events["killed"] - events["reached"]
			and spawner.get_spawned_count() == events["spawned"]
			and stats.text == _stats_text(WAVE_SIZE - events["killed"] - events["reached"]))
	_check("a ghoul reached the fortress", fortress.health.current_health == 90 and events["reached"] == 1)
	_check("reaching the fortress is not reported as a kill", events["killed"] == 1)
	_check("counts and label match the living enemies every frame (%d frames)" % frames, counts_ok)
	_check("label never lagged behind a count change", not events["label_lagged"])

	# --- Killed and reached in the same frame counts once ---
	ghoul = _alive_children(spawner)[0]
	var living_before: int = spawner.get_living_count()
	(ghoul.get_node("%HealthComponent") as HealthComponent).take_damage(100)
	(ghoul.get_node("%FortressHitbox") as Hitbox).register_hit(fortress.get_node("Hurtbox") as Hurtbox)
	await _frames(1)
	_check("double exit counted once", spawner.get_living_count() == living_before - 1 and events["killed"] == 2)

	# --- Placement: outside the middle of the screen ---
	var viewport: Vector2 = root.get_visible_rect().size  # headless runs don't use the 1280x720 window
	var feed_rect: Rect2 = feed.get_global_rect()
	var stats_rect: Rect2 = stats.get_global_rect()
	_check("feed sits in the top-right corner (%s)" % feed_rect,
		feed_rect.position.x >= viewport.x * 0.7 and feed_rect.end.x <= viewport.x and feed_rect.end.y <= 160.0)
	# Bottom-left: away from the spawn and the lane (top-left) and left of the build panel (bottom right,
	# 790 px wide).
	_check("stats sit in the bottom-left corner (%s)" % stats_rect,
		stats_rect.end.x <= viewport.x - 800.0 and stats_rect.position.y >= viewport.y * 0.7 and stats_rect.end.y <= viewport.y)
	level.queue_free()
	await _frames(2)


func _test_feed_widget() -> void:
	var feed: NotificationFeed = (load("res://ui/widgets/notification_feed.tscn") as PackedScene).instantiate()
	root.add_child(feed)
	for i: int in 6:
		feed.push("message %d" % i)
	await _frames(1)
	_check("feed keeps at most 4 messages, newest last",
		_feed_texts(feed) == ["message 2", "message 3", "message 4", "message 5"])
	await _frames(170)
	_check("all messages expire", feed.get_child_count() == 0)
	feed.queue_free()
	await _frames(2)


func _test_hud_alone() -> void:
	var hud: CanvasLayer = (load("res://ui/hud/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await _frames(2)
	_check("HUD alone: enemy stats hidden without a spawner", not (hud.get_node("%EnemyStatsLabel") as Label).visible)
	hud.queue_free()
	await _frames(2)


## Enemies still in the tree and not already removed this frame (queue_free takes effect at frame end).
func _alive_children(spawner: WaveSpawner) -> Array[Node]:
	return spawner.get_children().filter(func(n: Node) -> bool: return not n.is_queued_for_deletion())


func _until_frame(frame: int) -> void:
	while Engine.get_physics_frames() < frame:
		await physics_frame


func _stats_text(remaining: int) -> String:
	return "Enemies left: %d / %d" % [remaining, WAVE_SIZE]


func _feed_texts(feed: NotificationFeed) -> Array[String]:
	var texts: Array[String] = []
	for child: Node in feed.get_children():
		if not child.is_queued_for_deletion():
			texts.append((child as Label).text)
	return texts


func _find_label(feed: NotificationFeed, text: String) -> Label:
	for child: Node in feed.get_children():
		if (child as Label).text == text:
			return child
	return null


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
