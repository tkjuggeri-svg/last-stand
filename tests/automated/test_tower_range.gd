extends SceneTree
## Automated check for tower range limits: a tower only takes targets whose centre is inside its
## range, drops a target that leaves it, homing shots don't chase beyond the tower's reach (and miss
## a target that got away), no shot in a real wave ever lands far outside range, and the range ring
## shows on mouse-over of a slot with a tower and while the build menu is open there.
## Run all tests with tests/run_tests.sh, or this one: godot --headless --fixed-fps 60 --path . --script res://<this file>

const ARENA: String = "res://levels/prototype_arena.tscn"
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const ARCHER: TowerData = preload("res://data/towers/archer.tres")
const FROST: TowerData = preload("res://data/towers/frost.tres")
## Slot 3 (-380, -90): open ground around it.
const SLOT: int = 3
const HERO_AWAY: Vector2 = Vector2(380, 380)

var _failures: int = 0


func _initialize() -> void:
	await _test_range_edge_and_dropping()
	await _test_real_wave_stays_in_range()
	await _test_range_ring()
	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(_failures)


func _test_range_edge_and_dropping() -> void:
	var level: Level = _make_level([WaveData.new()])
	await _frames(2)
	var tower: Tower = _build(level, SLOT, ARCHER)
	var base: Vector2 = tower.global_position
	# Just outside: the body touches the range circle, but its centre is 8 px beyond the range.
	var outside: Enemy = _stationary(level, base + Vector2(ARCHER.attack_range + 8.0, 0))
	await _frames(int(ARCHER.build_time * 60.0) + 120)
	_check("an enemy whose centre is outside the range is never targeted or shot",
		tower.get_target() == null and _shots(tower) == 0 and _hp(outside) == outside.data.max_health)
	# Inside: targeted and hit.
	outside.global_position = base + Vector2(ARCHER.attack_range - 30.0, 0)
	var inside: Enemy = outside
	await _until(func() -> bool: return _hp(inside) < inside.data.max_health, 120)
	_check("inside the range it is targeted and hit", tower.get_target() == inside and _hp(inside) < inside.data.max_health)
	# A shot in the air, then the target steps far out of range: dropped, and the shot misses.
	await _until(func() -> bool: return _shots(tower) > 0, 90)
	var hp_before: int = _hp(inside)
	inside.global_position = base + Vector2(ARCHER.attack_range + Projectile.RANGE_SLACK + 80.0, 0)
	await _frames(2)
	_check("a target that leaves the range is dropped at once", tower.get_target() == null)
	var lost: bool = tower.get_children().any(func(c: Node) -> bool: return c is Projectile and (c as Projectile).is_lost())
	await _frames(90)
	_check("the shot in the air loses it and misses (lost: %s, HP %d -> %d)" % [lost, hp_before, _hp(inside)],
		lost and _hp(inside) == hp_before and _shots(tower) == 0)
	level.queue_free()
	await _frames(2)


## A busy wave with an archer and a frost tower: record how far from its tower any target and any shot
## ever gets.
func _test_real_wave_stays_in_range() -> void:
	var level: Level = _make_level([load("res://data/waves/wave_07.tres"), WaveData.new()])
	await _frames(2)
	var towers: Array[Tower] = [_build(level, 0, ARCHER), _build(level, 8, FROST), _build(level, 7, ARCHER)]
	(level.get_node("WaveSpawner") as WaveSpawner).start_next_wave()
	var worst_target: float = -INF
	var worst_shot: float = -INF
	var shots_seen: int = 0
	for _i: int in 60 * 30:
		await physics_frame
		for tower: Tower in towers:
			var target: Enemy = tower.get_target()
			if target != null:
				worst_target = maxf(worst_target, tower.global_position.distance_to(target.global_position) - tower.get_attack_range())
			for child: Node in tower.get_children():
				if child is Projectile:
					shots_seen += 1
					worst_shot = maxf(worst_shot, tower.global_position.distance_to((child as Node2D).global_position) - tower.get_attack_range())
	_check("in a real wave no target is ever beyond range (worst %+.0f px)" % worst_target, worst_target <= 0.0)
	_check("...and no shot flies past range + %d px (worst %+.0f px, %d shot-frames)" % [Projectile.RANGE_SLACK, worst_shot, shots_seen],
		shots_seen > 0 and worst_shot <= Projectile.RANGE_SLACK + 1.0)
	level.queue_free()
	await _frames(2)


func _test_range_ring() -> void:
	var level: Level = _make_level([WaveData.new()])
	await _frames(2)
	var tower: Tower = _build(level, SLOT, ARCHER)
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	var slot: BuildSlot = builder.get_slots()[SLOT]
	var empty: BuildSlot = builder.get_slots()[1]
	slot.update_hover(slot.global_position + Vector2(0, -40))  # the mouse over the tower
	_check("mouse over a slot with a tower shows its range ring", slot.is_hovered() and is_equal_approx(slot.get_shown_range(), tower.get_attack_range()))
	slot.update_hover(slot.global_position + Vector2(200, 0))
	_check("...and hides it when the mouse leaves", not slot.is_hovered() and slot.get_shown_range() == 0.0)
	empty.update_hover(empty.global_position)
	_check("an empty slot has no ring on mouse-over (the menu previews each tower's)", empty.get_shown_range() == 0.0)
	var menu: Node = level.get_node("BuildMenu")
	menu.call("open", slot)
	await _frames(1)
	_check("the build menu at a tower shows its range", is_equal_approx(slot.get_shown_range(), tower.get_attack_range()))
	menu.call("close")
	menu.call("open", empty)
	await _frames(1)
	var card: Button = (menu.get_node("%Options") as Node).get_child(1).find_child("Build", true, false)
	card.mouse_entered.emit()
	_check("the build menu previews a tower's range at an empty slot (%.0f)" % empty.get_shown_range(), empty.get_shown_range() > 0.0)
	level.queue_free()
	await _frames(2)


func _make_level(waves: Array) -> Level:
	var level: Level = (load(ARENA) as PackedScene).instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves.assign(waves)
	(level.get_node("Hero") as Node2D).position = HERO_AWAY
	root.add_child(level)
	return level


func _build(level: Level, slot_index: int, data: TowerData) -> Tower:
	var builder: TowerBuilder = level.get_node("%TowerBuilder")
	(level.get_node("%Economy") as Economy).earn(data.cost, Economy.Source.REFUND)
	builder.build(builder.get_slots()[slot_index], data)
	return builder.get_slots()[slot_index].tower


func _stationary(level: Level, at: Vector2) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.position = at
	level.add_child(enemy)
	(enemy.get_node("%AttackRange") as Area2D).monitoring = false
	return enemy


func _hp(enemy: Enemy) -> int:
	return (enemy.get_node("%HealthComponent") as HealthComponent).current_health


func _shots(tower: Tower) -> int:
	return tower.get_children().filter(func(c: Node) -> bool: return c is Projectile).size()


func _until(condition: Callable, max_frames: int) -> void:
	for _i: int in max_frames:
		if condition.call():
			return
		await physics_frame


func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("[", "ok" if ok else "FAIL", "] ", label)
	if not ok:
		_failures += 1
