class_name AffixData
extends Resource
## An elite fight's twist (Swift, Warded, Swarming, Siege, Ironclad): changes to every wave of the
## fight, shown on its map node. Each field is off at its default.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
## The regulars' speed and HP are multiplied by these.
@export var speed_multiplier: float = 1.0
@export var health_multiplier: float = 1.0
## Every regular group sends this many times as many enemies (rounded up).
@export var count_multiplier: float = 1.0
## Every enemy spawns with a ward absorbing this much damage (0 = none).
@export var spawn_shield: int = 0
## This share of every `swap_from` group becomes `swap_to` enemies (a new group beside it).
@export var swap_from: EnemyData
@export var swap_to: EnemyData
@export_range(0.0, 1.0) var swap_share: float = 0.0
## Groups of `extra_of` send this many times as many (Ironclad's Brutes).
@export var extra_of: EnemyData
@export var extra_multiplier: float = 1.0


## A copy of `wave` with the twist applied.
func apply(wave: WaveData) -> WaveData:
	var result: WaveData = wave.duplicate()
	result.speed_multiplier = wave.speed_multiplier * speed_multiplier
	result.health_multiplier = wave.health_multiplier * health_multiplier
	result.spawn_shield = maxi(wave.spawn_shield, spawn_shield)
	result.groups = []
	for group: SpawnGroup in wave.groups:
		var copy: SpawnGroup = group.duplicate()
		if copy.enemy != null and copy.enemy.is_boss:
			result.groups.append(copy)
			continue
		copy.count = ceili(copy.count * count_multiplier)
		if extra_of != null and copy.enemy == extra_of:
			copy.count = ceili(copy.count * extra_multiplier)
		if swap_from != null and swap_to != null and copy.enemy == swap_from and swap_share > 0.0:
			var swapped: SpawnGroup = copy.duplicate()
			swapped.enemy = swap_to
			swapped.count = roundi(copy.count * swap_share)
			copy.count -= swapped.count
			if swapped.count > 0:
				result.groups.append(swapped)
		if copy.count > 0:
			result.groups.append(copy)
	return result
