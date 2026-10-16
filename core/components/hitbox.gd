class_name Hitbox
extends Area2D
## An area that deals damage. It is detected by Hurtboxes; it does not detect anything itself.
## Put it on the hero_hitbox or enemy_hitbox layer to choose who it can hurt.

## Emitted after this hitbox damaged a Hurtbox, so the owner can react (e.g. an enemy used up on contact).
signal hit(hurtbox: Hurtbox)

@export var damage: int = 10


func _init() -> void:
	monitoring = false


## Called by the Hurtbox this hitbox just damaged.
func register_hit(hurtbox: Hurtbox) -> void:
	hit.emit(hurtbox)
