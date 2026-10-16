class_name Enemy
extends CharacterBody2D
## Base enemy: walks along its lane toward the fortress. When the hero comes within attack range it
## stops and attacks (wind-up, strike, cooldown), then resumes the lane once the hero is gone.
## If the target has an AttackerLimit, the enemy must claim a slot first; otherwise it waits its turn.
## Dies when its HP runs out; is used up when its FortressHitbox reaches the fortress.
## Stats come from an EnemyData resource. Visuals only follow the gameplay state.

## Killed by damage (e.g. the hero). Emitted at most once, and never together with reached_fortress.
signal died(enemy: Enemy)
## Touched the fortress and was used up. Emitted at most once, and never together with died.
signal reached_fortress(enemy: Enemy)
## An attack on a target began (the wind-up started).
signal attack_started(enemy: Enemy)

## How far ahead on the lane the enemy aims, in pixels. Aiming ahead (instead of following
## a fixed position) lets it find its way back to the lane if something pushes it off.
const LANE_LOOKAHEAD: float = 24.0
## How long the attack hitbox stays active once the strike lands, in seconds.
const STRIKE_DURATION: float = 0.1

@export var data: EnemyData

## The Path2D to follow. Set by the spawner before the enemy is added to the tree.
var lane: Path2D

var _is_finished: bool = false
## The body (the hero) currently inside attack range, if any.
var _target: Node2D = null
var _cooldown_left: float = 0.0
## Seconds until the current wind-up strikes; negative when not winding up.
var _windup_left: float = -1.0
var _strike_left: float = 0.0
## The target's AttackerLimit while this enemy holds one of its slots.
var _claimed_limit: AttackerLimit = null

@onready var _health: HealthComponent = %HealthComponent
@onready var _fortress_hitbox: Hitbox = %FortressHitbox
@onready var _attack_range: Area2D = %AttackRange
@onready var _attack_pivot: Node2D = %AttackPivot
@onready var _attack_hitbox: Hitbox = %AttackHitbox
@onready var _attack_shape: CollisionShape2D = %AttackShape
@onready var _sprite: DirectionalSprite = %Sprite
@onready var _hit_spark: AnimatedSprite2D = %HitSpark


func _ready() -> void:
	assert(data != null, "Enemy needs EnemyData: %s" % get_path())
	_health.setup(data.max_health)
	_fortress_hitbox.damage = data.fortress_damage
	_attack_hitbox.damage = data.hero_damage
	var body_radius: float = ((%BodyShape as CollisionShape2D).shape as CircleShape2D).radius
	((%RangeShape as CollisionShape2D).shape as CircleShape2D).radius = body_radius + data.attack_range
	_health.died.connect(_on_health_died)
	_health.health_changed.connect(_on_health_changed)
	_fortress_hitbox.hit.connect(_on_fortress_hitbox_hit)
	_attack_range.body_entered.connect(_on_attack_range_body_entered)
	_attack_range.body_exited.connect(_on_attack_range_body_exited)
	_hit_spark.animation_finished.connect(_hit_spark.hide)


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_update_attack(delta)
	if is_attacking() or has_target():
		velocity = Vector2.ZERO  # stand and fight
	elif lane != null:
		velocity = _direction_along_lane() * data.move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
	_update_animation()


## True while winding up or striking.
func is_attacking() -> bool:
	return _windup_left >= 0.0 or _strike_left > 0.0


func has_target() -> bool:
	return _target != null and is_instance_valid(_target)


## True when it could start an attack right now if the target's AttackerLimit gave it a slot.
func is_ready_to_attack() -> bool:
	return has_target() and not is_attacking() and _cooldown_left <= 0.0


func _update_attack(delta: float) -> void:
	if _strike_left > 0.0:
		_strike_left -= delta
		if _strike_left <= 0.0:
			_attack_shape.set_deferred("disabled", true)
			_release_slot()
	if _windup_left >= 0.0:
		_windup_left -= delta
		if _windup_left < 0.0:
			_strike()
	elif has_target() and _cooldown_left <= 0.0 and _strike_left <= 0.0 and _claim_slot():
		_begin_attack()


## True if the target allows another attacker right now (or has no limit).
func _claim_slot() -> bool:
	var limit: AttackerLimit = AttackerLimit.find_on(_target)
	if limit == null:
		return true
	if not limit.try_claim(self):
		return false
	_claimed_limit = limit
	return true


func _release_slot() -> void:
	if _claimed_limit != null and is_instance_valid(_claimed_limit):
		_claimed_limit.release(self)
	_claimed_limit = null


func _exit_tree() -> void:
	_release_slot()  # dying mid-attack frees the slot for the next enemy


func _begin_attack() -> void:
	_cooldown_left = data.attack_cooldown
	_windup_left = data.attack_windup
	_sprite.face(_target.global_position - global_position)
	_sprite.play_state("attack", true)
	attack_started.emit(self)


## The strike lands toward where the target is now; if it stepped away during the wind-up, it misses.
func _strike() -> void:
	if has_target():
		_attack_pivot.rotation = (_target.global_position - global_position).angle()
	# Turning the shape on counts as a new overlap, so one strike hits at most once.
	_attack_shape.set_deferred("disabled", false)
	_strike_left = STRIKE_DURATION


func _direction_along_lane() -> Vector2:
	var curve: Curve2D = lane.curve
	var offset: float = curve.get_closest_offset(lane.to_local(global_position))
	var target: Vector2 = lane.to_global(curve.sample_baked(offset + LANE_LOOKAHEAD))
	var to_target: Vector2 = target - global_position
	if to_target.length() < 1.0:
		return Vector2.ZERO
	return to_target.normalized()


func _update_animation() -> void:
	if _sprite.is_playing_state("attack"):
		return  # let the attack play out
	if velocity.is_zero_approx():
		_sprite.play_state("idle")
	else:
		_sprite.face(velocity)
		_sprite.play_state("walk")


## Damage feedback: a short white flash and a spark (health_changed only fires on damage).
func _on_health_changed(_current_health: int, _max_health: int) -> void:
	var flash_material: ShaderMaterial = _sprite.material
	flash_material.set_shader_parameter("flash", 1.0)  # visible in the same frame as the hit
	var flash: Tween = create_tween()
	flash.tween_property(flash_material, "shader_parameter/flash", 0.0, 0.15)
	_hit_spark.show()
	_hit_spark.stop()
	_hit_spark.play(&"spark")


func _on_attack_range_body_entered(body: Node2D) -> void:
	_target = body


func _on_attack_range_body_exited(body: Node2D) -> void:
	if body == _target:
		_target = null


func _on_health_died() -> void:
	_finish(died)


func _on_fortress_hitbox_hit(_hurtbox: Hurtbox) -> void:
	# Reaching the fortress spends the enemy.
	_finish(reached_fortress)


## Reports how the enemy left (once, even if killed in the same frame it reaches the fortress) and removes it.
func _finish(outcome: Signal) -> void:
	if _is_finished:
		return
	_is_finished = true
	outcome.emit(self)
	queue_free()
