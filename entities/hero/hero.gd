class_name Hero
extends CharacterBody2D
## The player-controlled hero. Moves with the move_* actions and swings a melee attack toward the mouse.
## Enemy attacks hurt it through its Hurtbox (with a short invulnerability window after each hit).
## Visuals (DirectionalSprite, swing trail, hit feedback) only follow the gameplay state.

## HP reached 0. The level turns this into Game Over.
signal died

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://entities/effects/damage_number.tscn")
## Where damage numbers appear, relative to the hero.
const DAMAGE_NUMBER_OFFSET: Vector2 = Vector2(0, -34)

@export var move_speed: float = 200.0
## How long the swing's hitbox stays active, in seconds.
@export var attack_duration: float = 0.12
## Time between the start of two swings, in seconds. Keep it longer than attack_duration.
@export var attack_cooldown: float = 0.4

var _attack_time_left: float = 0.0
var _cooldown_left: float = 0.0
var _last_health: int = 0

## Public so other systems (HUD) can read HP.
@onready var health: HealthComponent = %HealthComponent
@onready var _hit_spark: AnimatedSprite2D = %HitSpark
@onready var _attack_pivot: Node2D = %AttackPivot
@onready var _attack_shape: CollisionPolygon2D = %AttackShape
@onready var _attack_visual: AnimatedSprite2D = %AttackVisual
@onready var _sprite: DirectionalSprite = %Sprite


func _ready() -> void:
	_attack_visual.animation_finished.connect(_attack_visual.hide)
	_hit_spark.animation_finished.connect(_hit_spark.hide)
	_last_health = health.current_health
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_health_died)


func _physics_process(delta: float) -> void:
	if health.is_dead():
		return
	_move()
	_update_attack_timers(delta)
	# Holding the button keeps swinging, limited by the cooldown. Clicks on UI (e.g. the build menu)
	# are not swings.
	if Input.is_action_pressed("attack") and get_viewport().gui_get_hovered_control() == null:
		attack(get_global_mouse_position())
	_update_animation()


## Swings toward a point in the world. Does nothing while the previous swing is on cooldown.
func attack(target_position: Vector2) -> void:
	if _cooldown_left > 0.0 or health.is_dead():
		return
	var direction: Vector2 = target_position - global_position
	_attack_pivot.rotation = direction.angle()
	_cooldown_left = attack_cooldown
	_attack_time_left = attack_duration
	_set_attack_active(true)
	_sprite.face(direction)
	_sprite.play_state("attack", true)
	_play_swing_trail(direction.angle())


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


func _update_animation() -> void:
	if _sprite.is_playing_state("attack"):
		return  # let the swing pose finish
	if velocity.is_zero_approx():
		_sprite.play_state("idle")
	else:
		_sprite.face(velocity)
		_sprite.play_state("walk")


## The trail art exists for 8 directions (every 45 degrees); the hitbox itself follows the exact aim.
func _play_swing_trail(angle: float) -> void:
	var index: int = posmod(roundi(angle / (PI / 4.0)), 8)
	_attack_visual.show()
	_attack_visual.stop()
	_attack_visual.play(StringName("swing_%d" % index))


## Hit feedback: a red-white flash, a spark and a floating damage number.
func _on_health_changed(current_health: int, _max_health: int) -> void:
	var amount: int = _last_health - current_health
	_last_health = current_health
	if amount <= 0:
		return
	# The tween belongs to the sprite, which keeps running during Game Over, so the flash always ends.
	var flash_material: ShaderMaterial = _sprite.material
	flash_material.set_shader_parameter("flash", 0.9)  # visible in the same frame as the hit
	var flash: Tween = _sprite.create_tween()
	flash.tween_property(flash_material, "shader_parameter/flash", 0.0, 0.25)
	_hit_spark.show()
	_hit_spark.stop()
	_hit_spark.play(&"spark")
	var number: DamageNumber = DAMAGE_NUMBER_SCENE.instantiate()
	number.set_amount(amount)
	number.top_level = true  # stays where the hit happened instead of following the hero
	number.position = global_position + DAMAGE_NUMBER_OFFSET
	add_child(number)


func _on_health_died() -> void:
	_attack_time_left = 0.0
	_set_attack_active(false)
	_attack_visual.hide()
	_sprite.play(&"death")
	died.emit()
