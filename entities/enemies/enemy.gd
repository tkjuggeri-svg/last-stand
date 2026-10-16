class_name Enemy
extends CharacterBody2D
## Base enemy: walks along its lane toward the fortress. Dies when its HP runs out,
## and is used up when its Hitbox reaches the fortress. Stats come from an EnemyData resource.

## How far ahead on the lane the enemy aims, in pixels. Aiming ahead (instead of following
## a fixed position) lets it find its way back to the lane if something pushes it off.
const LANE_LOOKAHEAD: float = 24.0

@export var data: EnemyData

## The Path2D to follow. Set by the spawner before the enemy is added to the tree.
var lane: Path2D

@onready var _health: HealthComponent = %HealthComponent
@onready var _hitbox: Hitbox = %Hitbox


func _ready() -> void:
	assert(data != null, "Enemy needs EnemyData: %s" % get_path())
	_health.setup(data.max_health)
	_hitbox.damage = data.fortress_damage
	_health.died.connect(queue_free)
	_hitbox.hit.connect(_on_hitbox_hit)


func _physics_process(_delta: float) -> void:
	if lane == null:
		return
	velocity = _direction_along_lane() * data.move_speed
	move_and_slide()


func _direction_along_lane() -> Vector2:
	var curve: Curve2D = lane.curve
	var offset: float = curve.get_closest_offset(lane.to_local(global_position))
	var target: Vector2 = lane.to_global(curve.sample_baked(offset + LANE_LOOKAHEAD))
	var to_target: Vector2 = target - global_position
	if to_target.length() < 1.0:
		return Vector2.ZERO
	return to_target.normalized()


func _on_hitbox_hit(_hurtbox: Hurtbox) -> void:
	# The prototype enemy only hurts the fortress, and spends itself doing so.
	queue_free()
