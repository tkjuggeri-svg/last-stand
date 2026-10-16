class_name EnemyData
extends Resource
## Stats for one enemy type. Make one .tres per enemy in data/enemies/ and tune it there.

@export var display_name: String = ""
@export var max_health: int = 30
## Pixels per second along the lane.
@export var move_speed: float = 60.0
## Gold paid when the enemy is killed (by the hero or a tower). Nothing is paid if it reaches the fortress.
@export var gold_reward: int = 10
## Damage dealt to the fortress when the enemy reaches it.
@export var fortress_damage: int = 10
## Melee attack on the hero: damage per hit.
@export var hero_damage: int = 10
## The enemy stops to attack when the hero's body comes within this many pixels of its own collision shape.
@export var attack_range: float = 24.0
## Telegraphed wind-up before the strike lands, in seconds (gives the player time to dodge).
@export var attack_windup: float = 0.35
## Seconds between the starts of two attacks.
@export var attack_cooldown: float = 1.2
## Visual played where the enemy is killed (a one-shot scene). Optional.
@export var death_effect: PackedScene
