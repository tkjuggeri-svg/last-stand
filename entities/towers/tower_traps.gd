class_name TowerTraps
extends RefCounted
## The Trap Layer's snares (a part of Tower, which owns one): throws one onto the road just ahead of
## the leading enemy in reach and counts the ones still lying (up to the tower's `snares`).

const SNARE_SCENE: PackedScene = preload("res://entities/towers/snare.tscn")
## How far ahead of the enemy (px, the way it is walking) the snare lands.
const LEAD: float = 28.0

var _lying: Array[Snare] = []


## Snares still lying (springing or expiring ones leave the count).
func count() -> int:
	_lying = _lying.filter(func(snare: Snare) -> bool: return is_instance_valid(snare))
	return _lying.size()


func can_throw(stats: TowerTier) -> bool:
	return count() < stats.snares


## Throws one at `target`'s road: ahead of it, never beyond the tower's reach.
func throw(tower: Tower, target: Enemy, stats: TowerTier) -> Snare:
	var ahead: Vector2 = target.velocity.normalized() * LEAD if not target.velocity.is_zero_approx() else Vector2.ZERO
	var spot: Vector2 = tower.global_position + (target.global_position + ahead - tower.global_position).limit_length(stats.attack_range)
	var snare: Snare = SNARE_SCENE.instantiate()
	snare.setup(stats, spot)
	tower.add_child(snare)
	_lying.append(snare)
	return snare
