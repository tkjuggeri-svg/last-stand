class_name EnemyData
extends Resource
## Stats for one enemy type. Make one .tres per enemy in data/enemies/ and tune it there.

@export var display_name: String = ""
@export var max_health: int = 30
## Pixels per second along the lane.
@export var move_speed: float = 60.0
## Damage dealt to the fortress when the enemy reaches it.
@export var fortress_damage: int = 10
