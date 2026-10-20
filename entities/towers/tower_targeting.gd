class_name TowerTargeting
## Target choices of evolved towers (Tower uses the first enemy along the lane otherwise). Static
## helpers on a list of living enemies in range.


## The enemy with the most HP left (shields count): big single hits aren't wasted on the weak.
static func strongest(enemies: Array[Enemy]) -> Enemy:
	var best: Enemy = enemies[0]
	for enemy: Enemy in enemies:
		if _toughness(enemy) > _toughness(best):
			best = enemy
	return best


## The enemy with the most others within `radius` of it (ties: the one further along the lane, as
## `enemies` comes sorted that way): where an area attack catches the most.
static func densest(enemies: Array[Enemy], radius: float) -> Enemy:
	var best: Enemy = enemies[0]
	var best_count: int = -1
	for enemy: Enemy in enemies:
		var count: int = 0
		for other: Enemy in enemies:
			if other.global_position.distance_to(enemy.global_position) <= radius:
				count += 1
		if count > best_count:
			best = enemy
			best_count = count
	return best


static func _toughness(enemy: Enemy) -> int:
	return enemy.get_health().current_health + enemy.get_health().get_shield()
