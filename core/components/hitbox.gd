class_name Hitbox
extends Area2D
## An area that deals damage. It is detected by Hurtboxes; it does not detect anything itself.
## Put it on the hero_hitbox or enemy_hitbox layer to choose who it can hurt.

@export var damage: int = 10


func _init() -> void:
	monitoring = false
