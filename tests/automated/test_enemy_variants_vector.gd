extends SceneTree
## Automated check for the vector enemy and boss variants of M15 P4b (VariantPainter): each one of chapters 1-2 has its
## animations (a variant keeps its base's rows), sheets drawn at half size, an attack that lands when its data's wind-up
## ends, and dies in its own colours (a variant shares its base's death effect scene; the level dresses it with the
## variant's frames). Run all tests with tests/run_tests.sh, or this one:
## godot --headless --fixed-fps 60 --path . --script res://<this file>

const ANIMATIONS: Array[String] = ["idle_down", "idle_up", "idle_side", "walk_down", "walk_up", "walk_side",
	"attack_down", "attack_up", "attack_side", "death"]
## The animation rows a variant has besides the common ones.
const EXTRA: Dictionary = {"mire_priest": ["heal_down", "heal_up", "heal_side"], "tollkeeper": ["toll_down", "toll_up", "toll_side"],
	"pyre_warden": ["cast_down"], "winter_warden": ["cast_down"], "hollow_stag": ["cast_down"], "quarry_colossus": ["brace_down", "charge_side", "stun_up"]}
## How far the blow's frame time may be from the data's wind-up.
const WINDUP_TOLERANCE: float = 0.03

var _failures: int = 0


func _initialize() -> void:
	for id: String in VariantPainter.VARIANTS:
		_check_variant(id)
	await _check_death_effect()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _check_variant(id: String) -> void:
	var data: EnemyData = load("res://data/enemies/%s.tres" % id)
	var frames: SpriteFrames = data.sprite_frames
	var wanted: Array[String] = ANIMATIONS.duplicate()
	wanted.append_array(EXTRA.get(id, []))
	var missing: Array[String] = wanted.filter(func(a: String) -> bool: return not frames.has_animation(a) or frames.get_frame_count(a) < 4)
	_check("%s has every animation %s" % [data.display_name, missing], missing.is_empty())
	_check("%s is a vector sheet at scale 2 or 1.5" % data.display_name, frames.get_meta(SheetSprite.SHEET_SCALE, 1.0) > 1.0)
	var count: int = frames.get_frame_count(&"attack_down")
	var peak: float = VariantPainter.BASES[VariantPainter.VARIANTS[id].base].shape.y
	var strike_time: float = roundf(peak * (count - 1)) / frames.get_animation_speed(&"attack_down")
	_check("%s's blow lands when the %.2f s wind-up ends (%.2f s)" % [data.display_name, data.attack_windup, strike_time],
		absf(strike_time - data.attack_windup) <= WINDUP_TOLERANCE)


## A Cinder Ghoul's death plays on the Ghoul's effect scene: the level swaps in the variant's own frames.
func _check_death_effect() -> void:
	var level: Level = (load("res://levels/prototype_arena.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	var data: EnemyData = load("res://data/enemies/cinder_ghoul.tres")
	var enemy: Enemy = (load("res://entities/enemies/enemy.tscn") as PackedScene).instantiate()
	enemy.data = data
	level.add_child(enemy)
	await process_frame
	var before: int = level.get_node("%Effects").get_child_count()
	level._on_enemy_killed(enemy)
	var effects: Node = level.get_node("%Effects")
	var dressed: bool = false
	for child: Node in effects.get_children():
		var body: AnimatedSprite2D = child.get_node_or_null("Body") as AnimatedSprite2D
		if body != null and body.sprite_frames == data.sprite_frames:
			dressed = true
	_check("a variant's death effect uses the variant's own frames (%d effects added)" % (effects.get_child_count() - before), dressed)
	level.queue_free()
	await process_frame


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
