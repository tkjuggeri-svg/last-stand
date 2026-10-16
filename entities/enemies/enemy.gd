class_name Enemy
extends CharacterBody2D
## Base enemy: walks along its lane toward the fortress. Dies when its HP runs out,
## and is used up when its Hitbox reaches the fortress. Stats come from an EnemyData resource.
## Visuals (DirectionalSprite, hit flash, hit spark) only follow the gameplay state.

## Killed by damage (e.g. the hero). Emitted at most once, and never together with reached_fortress.
signal died(enemy: Enemy)
## Touched the fortress and was used up. Emitted at most once, and never together with died.
signal reached_fortress(enemy: Enemy)

## How far ahead on the lane the enemy aims, in pixels. Aiming ahead (instead of following
## a fixed position) lets it find its way back to the lane if something pushes it off.
const LANE_LOOKAHEAD: float = 24.0

@export var data: EnemyData

## The Path2D to follow. Set by the spawner before the enemy is added to the tree.
var lane: Path2D

var _is_finished: bool = false

@onready var _health: HealthComponent = %HealthComponent
@onready var _hitbox: Hitbox = %Hitbox
@onready var _sprite: DirectionalSprite = %Sprite
@onready var _hit_spark: AnimatedSprite2D = %HitSpark


func _ready() -> void:
	assert(data != null, "Enemy needs EnemyData: %s" % get_path())
	_health.setup(data.max_health)
	_hitbox.damage = data.fortress_damage
	_health.died.connect(_on_health_died)
	_hitbox.hit.connect(_on_hitbox_hit)
	_health.health_changed.connect(_on_health_changed)
	_hit_spark.animation_finished.connect(_hit_spark.hide)


func _physics_process(_delta: float) -> void:
	if lane != null:
		velocity = _direction_along_lane() * data.move_speed
		move_and_slide()
	_update_animation()


func _direction_along_lane() -> Vector2:
	var curve: Curve2D = lane.curve
	var offset: float = curve.get_closest_offset(lane.to_local(global_position))
	var target: Vector2 = lane.to_global(curve.sample_baked(offset + LANE_LOOKAHEAD))
	var to_target: Vector2 = target - global_position
	if to_target.length() < 1.0:
		return Vector2.ZERO
	return to_target.normalized()


func _update_animation() -> void:
	if velocity.is_zero_approx():
		_sprite.play_state("idle")
	else:
		_sprite.face(velocity)
		_sprite.play_state("walk")


## Damage feedback: a short white flash and a spark (health_changed only fires on damage).
func _on_health_changed(_current_health: int, _max_health: int) -> void:
	var flash: Tween = create_tween()
	flash.tween_property(_sprite.material, "shader_parameter/flash", 0.0, 0.15).from(1.0)
	_hit_spark.show()
	_hit_spark.stop()
	_hit_spark.play(&"spark")


func _on_health_died() -> void:
	_finish(died)


func _on_hitbox_hit(_hurtbox: Hurtbox) -> void:
	# The prototype enemy only hurts the fortress, and spends itself doing so.
	_finish(reached_fortress)


## Reports how the enemy left (once, even if killed in the same frame it reaches the fortress) and removes it.
func _finish(outcome: Signal) -> void:
	if _is_finished:
		return
	_is_finished = true
	outcome.emit(self)
	queue_free()
