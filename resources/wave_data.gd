class_name WaveData
extends Resource
## One wave: a list of spawn groups that start together (each with its own delay). Make one .tres per
## wave in data/waves/ and tune it there.

@export var groups: Array[SpawnGroup] = []
## Every enemy of this wave has this many times its normal HP (the late-wave difficulty curve: it
## makes enemies tougher without paying out more gold, unlike adding more of them).
@export var health_multiplier: float = 1.0
## Every regular enemy of this wave pays this many times its gold_reward when killed (bosses pay
## theirs as authored). Later waves send far more enemies: below 1 it keeps the income per wave from
## growing with the horde, so gold stays scarce.
@export var gold_multiplier: float = 1.0
## Every regular enemy of this wave moves this many times its move_speed (bosses as authored): late
## waves press harder, so a held line has less time per enemy.
@export var speed_multiplier: float = 1.0


## How many enemies the whole wave sends.
func get_enemy_total() -> int:
	var total: int = 0
	for group: SpawnGroup in groups:
		total += maxi(group.count, 0)
	return total
