extends SceneTree
## Automated check for the M2 pixel-art visuals: render settings, sprite sheets, animation
## switching, effects, and that the art lines up with the (unchanged) collision shapes.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const Layouts: GDScript = preload("res://tools/art/sheet_layouts.gd")
const ART_SCALE: Vector2 = Vector2(2, 2)
## How far (world px) a sprite's solid pixels may differ from its collision size.
const FIT_TOLERANCE: float = 8.0

var _failures: int = 0


func _initialize() -> void:
	_test_render_settings()
	_test_sheets()
	await _test_hero_animation()
	await _test_ghoul_and_effects()
	_test_art_matches_collision()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_render_settings() -> void:
	_check("nearest-neighbour texture filtering",
		ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter") == 0)
	_check("2D transforms and vertices snap to pixels",
		ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel") == true
		and ProjectSettings.get_setting("rendering/2d/snap/snap_2d_vertices_to_pixel") == true)


func _test_sheets() -> void:
	for sheet: Dictionary in Layouts.ANIMATED:
		var frames: SpriteFrames = load(sheet["frames"])
		var size: Vector2i = sheet["size"]
		var ok: bool = frames != null and frames.get_animation_names().size() == (sheet["anims"] as Array).size()
		for anim: Array in sheet["anims"]:
			var anim_name: StringName = StringName(anim[0])
			ok = ok and frames.has_animation(anim_name) and frames.get_frame_count(anim_name) == int(anim[2])
			ok = ok and frames.get_animation_loop(anim_name) == bool(anim[4])
			for i: int in frames.get_frame_count(anim_name):
				ok = ok and Vector2i(frames.get_frame_texture(anim_name, i).get_size()) == size
		_check("%s: every animation present, %dx%d frames" % [String(sheet["frames"]).get_file(), size.x, size.y], ok)
	var hero_frames: SpriteFrames = load(Layouts.HERO["frames"])
	var directions_ok: bool = true
	for state: String in ["idle", "walk", "attack"]:
		for facing: String in ["down", "up", "side"]:
			directions_ok = directions_ok and hero_frames.has_animation(StringName("%s_%s" % [state, facing]))
	_check("hero has idle/walk/attack for down, up and side", directions_ok)


func _test_hero_animation() -> void:
	var hero: Hero = (load("res://entities/hero/hero.tscn") as PackedScene).instantiate()
	root.add_child(hero)
	await _frames(2)
	var sprite: DirectionalSprite = hero.get_node("%Sprite")
	var swing: AnimatedSprite2D = hero.get_node("%AttackVisual")
	_check("hero art at 2x scale", sprite.scale == ART_SCALE and swing.scale == ART_SCALE)
	_check("hero idles facing down", sprite.animation == &"idle_down" and sprite.is_playing())

	var expected: Dictionary = {"move_right": ["walk_side", false], "move_left": ["walk_side", true],
		"move_up": ["walk_up", false], "move_down": ["walk_down", false]}
	for action: String in expected:
		Input.action_press(action)
		await _frames(3)
		var want: Array = expected[action]
		_check("%s plays %s%s" % [action, want[0], " (mirrored)" if want[1] else ""],
			sprite.animation == StringName(want[0]) and sprite.flip_h == want[1] and sprite.is_playing())
		Input.action_release(action)
		await _frames(1)
	await _frames(2)
	_check("stopping returns to idle, keeping the facing", sprite.animation == &"idle_down")

	# Attack: body pose faces the swing; the trail picks the nearest of 8 directions.
	var cases: Array = [[Vector2(100, 0), "attack_side", 0], [Vector2(70, 70), "attack_down", 1],
		[Vector2(0, 100), "attack_down", 2], [Vector2(-70, 70), "attack_side", 3], [Vector2(-100, 0), "attack_side", 4],
		[Vector2(-70, -70), "attack_up", 5], [Vector2(0, -100), "attack_up", 6], [Vector2(70, -70), "attack_up", 7]]
	var all_ok: bool = true
	for c: Array in cases:
		await _frames(30)  # past the cooldown
		hero.attack(hero.global_position + (c[0] as Vector2))
		await _frames(1)
		var ok: bool = swing.visible and swing.animation == StringName("swing_%d" % c[2])
		# Exact diagonals are ties between two facings; only check the body pose on clear directions.
		if (c[2] as int) % 2 == 0:
			ok = ok and sprite.animation == StringName(c[1])
		all_ok = all_ok and ok
		if not ok:
			print("  attack %s -> pose %s, trail %s" % [c[0], sprite.animation, swing.animation])
	_check("attack pose and swing trail follow the 8 aim directions", all_ok)
	await _frames(20)
	_check("swing trail hides when finished", not swing.visible)
	_check("hero returns from the attack pose to idle", sprite.animation.begins_with("idle_") and sprite.is_playing())
	hero.queue_free()
	await _frames(2)


func _test_ghoul_and_effects() -> void:
	var level: Level = (load("res://levels/prototype_arena.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var spawner: EnemySpawner = level.get_node("EnemySpawner")
	var hero: Hero = level.get_node("Hero")
	var effects: Node2D = level.get_node("%Effects")
	await _frames(3)
	var ghoul: Enemy = spawner.get_child(0)
	var sprite: DirectionalSprite = ghoul.get_node("%Sprite")
	var spark: AnimatedSprite2D = ghoul.get_node("%HitSpark")
	var flash: ShaderMaterial = sprite.material
	_check("ghoul art at 2x scale", sprite.scale == ART_SCALE and spark.scale == ART_SCALE)
	_check("ghoul walks right along the first lane segment", sprite.animation == &"walk_side" and not sprite.flip_h)
	# First lane corner is at x = -300 (400 px from the start): then it walks down.
	var frames: int = 0
	while ghoul.global_position.x < -310.0 and frames < 600:
		await physics_frame
		frames += 1
	await _frames(40)
	_check("ghoul turns to walk down the second segment", sprite.animation == &"walk_down")

	# Damage feedback.
	(ghoul.get_node("%HealthComponent") as HealthComponent).take_damage(10)
	await _frames(1)
	var flash_now: float = flash.get_shader_parameter("flash")
	_check("hit: sprite flashes (%.2f) and the spark plays" % flash_now, flash_now > 0.5 and spark.visible and spark.is_playing())
	await _frames(20)
	_check("flash fades and spark hides", is_zero_approx(flash.get_shader_parameter("flash")) and not spark.visible)
	var other: Enemy = spawner.get_child(1)
	var other_flash: ShaderMaterial = (other.get_node("%Sprite") as CanvasItem).material
	_check("each ghoul has its own flash material (the other one is not flashing)",
		other_flash != flash and is_zero_approx(other_flash.get_shader_parameter("flash")))

	# Death effect: spawned by the level where the ghoul died, removes itself after playing.
	var death_spot: Vector2 = ghoul.global_position
	hero.position = ghoul.global_position + Vector2(40, 0)
	(ghoul.get_node("%HealthComponent") as HealthComponent).take_damage(100)
	await _frames(1)
	var death_effects: Array[Node] = effects.get_children().filter(func(n: Node) -> bool: return n is OneShotEffect)
	var gold_texts: Array[Node] = effects.get_children().filter(func(n: Node) -> bool: return n is DamageNumber)
	_check("death effect spawned at the ghoul's position",
		death_effects.size() == 1 and (death_effects[0] as Node2D).global_position.distance_to(death_spot) < 2.0)
	_check("a gold '+10' rises where the ghoul died",
		gold_texts.size() == 1 and (gold_texts[0].get_node("%Label") as Label).text == "+10"
		and (gold_texts[0] as Node2D).global_position.distance_to(death_spot) < 40.0)
	await _frames(70)
	_check("death effect and gold text remove themselves (within ~1 s)", effects.get_child_count() == 0)
	level.queue_free()
	await _frames(2)


## Solid (non-shadow) pixels of each character's main frame, at world scale, vs. its collision size.
func _test_art_matches_collision() -> void:
	var hero_rect: Rect2 = _solid_rect(Layouts.HERO, 0, 0)
	_check("hero art fits its 32 px collision circle (%s)" % hero_rect.size,
		absf(hero_rect.size.x - 32.0) <= FIT_TOLERANCE and absf(hero_rect.get_center().x) <= 2.0)
	var ghoul_rect: Rect2 = _solid_rect(Layouts.GHOUL, 0, 0)
	_check("ghoul art fits its 24 px collision circle (%s)" % ghoul_rect.size,
		absf(ghoul_rect.size.x - 24.0) <= FIT_TOLERANCE and absf(ghoul_rect.get_center().x) <= 2.0)
	var fortress_rect: Rect2 = _solid_rect(Layouts.FORTRESS, 0, 0)
	_check("fortress art = its 96x96 collision box, centred (%s)" % fortress_rect,
		fortress_rect.size.distance_to(Vector2(96, 96)) <= 4.0 and fortress_rect.get_center().length() <= 2.0)
	var theme: Theme = load("res://ui/theme/game_theme.tres")
	_check("HUD text has a dark outline for readability", theme.get_constant(&"outline_size", &"Label") >= 4)


## Bounding box of a frame's solid pixels (alpha > 0.5, so soft shadows are ignored), in world px
## relative to the sprite's centre.
func _solid_rect(sheet: Dictionary, column: int, row: int) -> Rect2:
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(sheet["png"]))
	var size: Vector2i = sheet["size"]
	var frame: Image = image.get_region(Rect2i(Vector2i(column, row) * size, size))
	var min_p: Vector2i = size
	var max_p: Vector2i = Vector2i(-1, -1)
	for y: int in size.y:
		for x: int in size.x:
			if frame.get_pixel(x, y).a > 0.5:
				min_p = min_p.min(Vector2i(x, y))
				max_p = max_p.max(Vector2i(x, y))
	var rect: Rect2 = Rect2(Vector2(min_p), Vector2(max_p - min_p + Vector2i.ONE))
	return Rect2((rect.position - Vector2(size) / 2.0) * ART_SCALE, rect.size * ART_SCALE)


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
