class_name HazardBlast
extends Node2D
## What a hazard's strike does to the hero and minions caught in it: a circle on the enemy_hitbox layer
## for two physics frames (the layer their Hurtboxes listen to). Enemies are hurt by an Explosion at the
## same spot (hero_hitbox: the layer only enemies listen to).

const ACTIVE_FRAMES: int = 2
const ENEMY_HITBOX_LAYER: int = 32

var _hitbox: Hitbox = Hitbox.new()
var _frames_left: int = ACTIVE_FRAMES


## Call before adding it to the tree.
func setup(radius: float, damage: int) -> void:
	_hitbox.damage = damage
	_hitbox.collision_layer = ENEMY_HITBOX_LAYER
	_hitbox.collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	_hitbox.add_child(shape)


func _ready() -> void:
	top_level = true
	add_child(_hitbox)


func _physics_process(_delta: float) -> void:
	_frames_left -= 1
	if _frames_left <= 0:
		queue_free()
