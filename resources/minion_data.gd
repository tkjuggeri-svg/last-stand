class_name MinionData
extends Resource
## One kind of minion (M9): a skeleton the Necromancer or a Bone Pit raises. It walks to the nearest
## enemy near its anchor and fights it; enemies fight it back (it is on the allies layer). data/minions/*.tres.

@export var id: StringName = &""
@export var display_name: String = ""
@export var max_health: int = 30
## Damage of one blow, and seconds between two blows.
@export var damage: int = 6
@export var attack_cooldown: float = 0.9
@export var move_speed: float = 120.0
## Seconds it lasts (0: until it falls).
@export var lifetime: float = 20.0
## It bursts when it falls (not when it expires): this much damage to every enemy within the radius.
@export var burst_damage: int = 0
@export var burst_radius: float = 0.0
## Enemies that have it in reach attack it before any other body there (a Bone Knight).
@export var taunts: bool = false
