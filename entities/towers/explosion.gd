class_name Explosion
extends Node2D
## A cannon blast: for a moment its Hitbox (on hero_hitbox, which only enemies listen to) damages
## every enemy within the radius, once each. The hero and the fortress never listen to that layer.
## The fireball sprite is display only; the node removes itself when it has played.

## Physics frames the blast area stays active (enough for overlaps to register).
const ACTIVE_FRAMES: int = 2

var _damage: int = 20
var _radius: float = 56.0
var _frames_left: int = ACTIVE_FRAMES

@onready var _hitbox: Hitbox = %Hitbox
@onready var _shape: CollisionShape2D = %BlastShape
@onready var _sprite: AnimatedSprite2D = %Sprite


## Call before adding it to the tree.
func setup(damage: int, radius: float) -> void:
	_damage = damage
	_radius = radius


func _ready() -> void:
	_hitbox.damage = _damage
	(_shape.shape as CircleShape2D).radius = _radius
	_sprite.animation_finished.connect(queue_free)
	_sprite.play(&"explosion")


func _physics_process(_delta: float) -> void:
	_frames_left -= 1
	if _frames_left <= 0:
		_shape.set_deferred("disabled", true)
		set_physics_process(false)
