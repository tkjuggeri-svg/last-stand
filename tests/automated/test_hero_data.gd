extends SceneTree
## Automated check for the hero as data (M9 stage 1): the Knight's stats come from data/heroes/knight.tres
## and are what the hero scene had before (100 HP, speed 200, 10 damage, 0.4 s cooldown); another HeroData
## changes the hero; the run holds its hero (default: the Knight) and saves it; a version 2 save loads as
## the Knight's and the profile keeps the hero picked.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const KNIGHT: HeroData = preload("res://data/heroes/knight.tres")
const HERO_SCENE: PackedScene = preload("res://entities/hero/hero.tscn")
const RUN: RunData = preload("res://data/run/run.tres")
const V2_FIXTURE: String = "res://tests/fixtures/save_v2.json"

var _failures: int = 0


func _initialize() -> void:
	await _test_knight()
	await _test_other_hero()
	_test_run_hero()
	_test_save()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _hero(data: HeroData) -> Hero:
	var hero: Hero = HERO_SCENE.instantiate()
	if data != null:
		hero.data = data
	root.add_child(hero)
	await process_frame
	return hero


func _test_knight() -> void:
	var hero: Hero = await _hero(null)
	_check("the Knight: 100 HP, speed 200, cooldown 0.4 s", hero.health.max_health == 100 and hero.health.current_health == 100
		and is_equal_approx(hero.move_speed, 200.0) and is_equal_approx(hero.attack_cooldown, 0.4))
	_check("...and 10 damage, 12 px knockback", (hero.get_node("%AttackHitbox") as Hitbox).damage == 10 and is_equal_approx(hero.knockback, 12.0))
	hero.queue_free()


func _test_other_hero() -> void:
	var other: HeroData = KNIGHT.duplicate()
	other.max_health = 75
	other.move_speed = 215.0
	other.attack_damage = 9
	other.attack_cooldown = 0.55
	var hero: Hero = await _hero(other)
	_check("another HeroData sets HP, speed, damage and cooldown", hero.health.max_health == 75 and hero.health.current_health == 75
		and is_equal_approx(hero.move_speed, 215.0) and (hero.get_node("%AttackHitbox") as Hitbox).damage == 9
		and is_equal_approx(hero.attack_cooldown, 0.55))
	hero.queue_free()


func _test_run_hero() -> void:
	_check("the run's heroes: the Knight, the default for any id", RUN.get_hero("knight") == KNIGHT and RUN.get_hero("nobody") == KNIGHT)
	var run: RunStateNode = RunStateNode.new()
	run.start_run(RUN, 1)
	_check("a run without a pick is played by the Knight", run.hero == KNIGHT)
	var saved: String = RunSave.capture_hero_id(run)
	_check("...and a saved run names its hero (%s)" % saved, saved == "knight")
	run.free()


func _test_save() -> void:
	var fresh: SaveProfile = SaveProfile.new()
	_check("a new profile picks the Knight", fresh.hero == "knight" and fresh.to_dict().get("hero") == "knight")
	var old: SaveProfile = SaveProfile.from_dict(JSON.parse_string(FileAccess.get_file_as_string(V2_FIXTURE)))
	_check("a version 2 save loads as the Knight's, the rest kept", old.hero == "knight" and old.shards == 80 and old.has_unlock("brazier")
		and old.to_dict().get("version") == SaveProfile.CURRENT_VERSION)
	fresh.hero = "huntress"
	_check("the hero picked is kept", SaveProfile.from_dict(fresh.to_dict()).hero == "huntress")


func _check(label: String, ok: bool) -> void:
	print("[ok] " if ok else "[FAIL] ", label)
	if not ok:
		_failures += 1
