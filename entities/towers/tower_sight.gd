class_name TowerSight
extends RefCounted
## What a tower can see (a part of Tower, which owns one): the enemy bodies its range area reports
## (the broad phase), which of them are really targetable (alive, centre within range and outside a
## dead zone), and which one to aim at (the furthest along its lane, or an evolution's choice:
## TowerTargeting).

## Enemy bodies currently inside the range area (may contain freed ones until pruned).
var _in_range: Array[Node2D] = []


func add(body: Node2D) -> void:
	if body is Enemy and not _in_range.has(body):
		_in_range.append(body)


func remove(body: Node2D) -> void:
	_in_range.erase(body)


func clear() -> void:
	_in_range.clear()


## Untyped on purpose: the stored target may already be freed, and a freed object can't be passed
## as an Enemy. is_instance_valid() is checked before anything else touches it.
func is_valid_target(tower: Tower, candidate: Variant) -> bool:
	if not is_instance_valid(candidate):
		return false
	var enemy: Enemy = candidate as Enemy
	return enemy != null and enemy.is_alive() and _in_range.has(enemy) and tower.is_in_range(enemy.global_position)


## Living enemies in range, the furthest along the lane first.
func targets_in_range(tower: Tower) -> Array[Enemy]:
	var found: Array[Enemy] = []
	for i: int in range(_in_range.size() - 1, -1, -1):
		var body: Node2D = _in_range[i]
		if not is_instance_valid(body):
			_in_range.remove_at(i)
			continue
		var enemy: Enemy = body as Enemy
		if enemy != null and enemy.is_alive() and tower.is_in_range(enemy.global_position):
			found.append(enemy)
	found.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.get_lane_progress() > b.get_lane_progress())
	return found


## The enemy to aim at now (null if none is in range).
func pick_target(tower: Tower) -> Enemy:
	var found: Array[Enemy] = targets_in_range(tower)
	if found.is_empty():
		return null
	var evolution: TowerEvolution = tower.get_evolution()
	match evolution.targeting if evolution != null else TowerEvolution.Targeting.FIRST:
		TowerEvolution.Targeting.STRONGEST:
			return TowerTargeting.strongest(found)
		TowerEvolution.Targeting.DENSEST:
			return TowerTargeting.densest(found, tower.get_stats().splash_radius)
	return found[0]
