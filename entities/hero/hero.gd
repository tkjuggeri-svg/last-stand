class_name Hero
extends CharacterBody2D
## The player-controlled hero. Moves with the move_* actions and swings a melee attack toward the mouse.

@export var move_speed: float = 200.0
## How long the swing's hitbox stays active, in seconds.
@export var attack_duration: float = 0.12
## Time between the start of two swings, in seconds. Keep it longer than attack_duration.
@export var attack_cooldown: float = 0.4

var _attack_time_left: float = 0.0
var _cooldown_left: float = 0.0

@onready var _attack_pivot: Node2D = %AttackPivot
@onready var _attack_shape: CollisionPolygon2D = %AttackShape
@onready var _attack_visual: Polygon2D = %AttackVisual


func _physics_process(delta: float) -> void:
	_move()
	_update_attack_timers(delta)
	# Holding the button keeps swinging, limited by the cooldown.
	if Input.is_action_pressed("attack"):
		attack(get_global_mouse_position())


## Swings toward a point in the world. Does nothing while the previous swing is on cooldown.
func attack(target_position: Vector2) -> void:
	if _cooldown_left > 0.0:
		return
	_attack_pivot.rotation = (target_position - global_position).angle()
	_cooldown_left = attack_cooldown
	_attack_time_left = attack_duration
	_set_attack_active(true)


func _move() -> void:
	# get_vector() caps the length at 1, so diagonals are not faster than straight lines.
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * move_speed
	move_and_slide()


func _update_attack_timers(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if _attack_time_left > 0.0:
		_attack_time_left -= delta
		if _attack_time_left <= 0.0:
			_set_attack_active(false)


func _set_attack_active(active: bool) -> void:
	# Turning the shape on makes hurtboxes inside it register a new hit, so each swing hits once.
	# Deferred because physics shapes should not change in the middle of a physics step.
	_attack_shape.set_deferred("disabled", not active)
	_attack_visual.visible = active
