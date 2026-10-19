class_name Enemy
extends CharacterBody2D
## Base enemy: walks along its lane toward the fortress. When the hero comes within attack range it
## stops and attacks (wind-up, strike, cooldown), then resumes the lane once the hero is gone.
## If the target has an AttackerLimit, the enemy must claim a slot first; otherwise it waits its turn.
## Towers can slow it (apply_slow): the strongest slow wins and it always wears off.
## Dies when its HP runs out; is used up when its FortressHitbox reaches the fortress.
## Stats, body size and animations come from an EnemyData resource (one scene for every enemy type).
## Visuals only follow the gameplay state.

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
## Tint while slowed by frost.
const SLOWED_TINT: Color = Color(0.62, 0.82, 1.0, 1)
## Hit recoil of the sprite (display only): how far it jolts, in world px, and for how long.
const HIT_JOLT: float = 2.0
const HIT_JOLT_TIME: float = 0.12
## The hurtbox is this much bigger than the body, so hits that graze the body still count.
const HURTBOX_MARGIN: float = 2.0
## The claw/fist strike reaches this far past the body's edge (centre of the attack shape).
const STRIKE_REACH: float = 10.0
## The hit spark appears this far below the sprite's centre (on the chest).
const SPARK_DROP: float = 2.0

@export var data: EnemyData

## The Path2D to follow. Set by the spawner before the enemy is added to the tree.
var lane: Path2D
## Its wave's toughness: max HP = data.max_health x this. Set by the spawner before it enters the tree.
var health_multiplier: float = 1.0

var _is_finished: bool = false
## The body (the hero) currently inside attack range, if any.
var _target: Node2D = null
var _cooldown_left: float = 0.0
## Seconds until the current wind-up strikes; negative when not winding up.
var _windup_left: float = -1.0
var _strike_left: float = 0.0
## The target's AttackerLimit while this enemy holds one of its slots.
var _claimed_limit: AttackerLimit = null
## Current speed multiplier from slows (1 = normal) and how long it still lasts.
var _slow_factor: float = 1.0
var _slow_left: float = 0.0
var _sprite_rest: Vector2 = Vector2.ZERO
## Where on its lane the enemy is (curve offset), worked out once per physics frame: finding the
## closest point on the curve is the costliest thing an enemy does, and towers ask for it too.
var _lane_offset: float = 0.0
var _lane_offset_frame: int = -1
var _jolt: Tween

@onready var _health: HealthComponent = %HealthComponent
@onready var _fortress_hitbox: Hitbox = %FortressHitbox
@onready var _attack_range: Area2D = %AttackRange
@onready var _attack_pivot: Node2D = %AttackPivot
@onready var _attack_hitbox: Hitbox = %AttackHitbox
@onready var _attack_shape: CollisionShape2D = %AttackShape
@onready var _sprite: DirectionalSprite = %Sprite
@onready var _hit_spark: AnimatedSprite2D = %HitSpark
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _frost_aura: AnimatedSprite2D = %FrostAura
@onready var _health_bar: EnemyHealthBar = %HealthBar


func _ready() -> void:
	assert(data != null, "Enemy needs EnemyData: %s" % get_path())
	_health.setup(maxi(roundi(data.max_health * health_multiplier), 1))
	_fortress_hitbox.damage = data.fortress_damage
	_attack_hitbox.damage = data.hero_damage
	_apply_body(data.body_radius)
	if data.sprite_frames != null:
		_sprite.sprite_frames = data.sprite_frames
		_sprite.play_state("idle")
	_sprite.position = data.sprite_offset
	_hit_spark.position = data.sprite_offset + Vector2(0, SPARK_DROP)
	_health_bar.setup(data.body_radius, data.health_bar_y)
	_health.died.connect(_on_health_died)
	_health.health_changed.connect(_on_health_changed)
	_fortress_hitbox.hit.connect(_on_fortress_hitbox_hit)
	_attack_range.body_entered.connect(_on_attack_range_body_entered)
	_attack_range.body_exited.connect(_on_attack_range_body_exited)
	_hit_spark.animation_finished.connect(_hit_spark.hide)
	_sprite_rest = _sprite.position


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_update_slow(delta)
	_update_attack(delta)
	if is_attacking() or has_target():
		velocity = Vector2.ZERO  # stand and fight
	elif lane != null:
		velocity = _direction_along_lane() * get_move_speed()
		move_and_slide()
	else:
		velocity = Vector2.ZERO
	_update_animation()


## Sizes every shape from the body radius (the shapes are local to each enemy instance).
func _apply_body(body_radius: float) -> void:
	((%BodyShape as CollisionShape2D).shape as CircleShape2D).radius = body_radius
	((%HurtShape as CollisionShape2D).shape as CircleShape2D).radius = body_radius + HURTBOX_MARGIN
	((%FortressShape as CollisionShape2D).shape as CircleShape2D).radius = body_radius
	((%RangeShape as CollisionShape2D).shape as CircleShape2D).radius = body_radius + data.attack_range
	_attack_shape.position = Vector2(body_radius + STRIKE_REACH, 0)


## True while winding up or striking.
func is_attacking() -> bool:
	return _windup_left >= 0.0 or _strike_left > 0.0


func has_target() -> bool:
	return _target != null and is_instance_valid(_target)


## Still in play: not killed, not used up at the fortress. Towers only target living enemies.
func is_alive() -> bool:
	return not _is_finished and not is_queued_for_deletion()


## How far along its lane it is, in pixels (more = closer to the fortress). Towers prefer the leader.
func get_lane_progress() -> float:
	if lane == null:
		return 0.0
	var frame: int = Engine.get_physics_frames()
	if frame != _lane_offset_frame:
		_lane_offset_frame = frame
		_lane_offset = lane.curve.get_closest_offset(lane.to_local(global_position))
	return _lane_offset


func get_move_speed() -> float:
	return data.move_speed * _slow_factor


func is_slowed() -> bool:
	return _slow_left > 0.0


## Takes a hit from a projectile that already knows its target (same path as an overlapping hitbox).
func receive_hit(hitbox: Hitbox) -> bool:
	return is_alive() and _hurtbox.receive_hit(hitbox)


## Slows movement to `factor` of normal speed for `duration` seconds. Slows never stack: the strongest
## factor applies and the longest remaining time is kept; when it runs out, speed is normal again.
func apply_slow(factor: float, duration: float) -> void:
	if duration <= 0.0 or factor >= 1.0:
		return
	_slow_factor = minf(_slow_factor, factor) if is_slowed() else factor
	_slow_left = maxf(_slow_left, duration)
	_sprite.self_modulate = SLOWED_TINT
	_frost_aura.show()
	_frost_aura.play(&"frost_aura")


func _update_slow(delta: float) -> void:
	if _slow_left <= 0.0:
		return
	_slow_left -= delta
	if _slow_left <= 0.0:
		_slow_left = 0.0
		_slow_factor = 1.0
		_sprite.self_modulate = Color.WHITE
		_frost_aura.hide()


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
	var target: Vector2 = lane.to_global(lane.curve.sample_baked(get_lane_progress() + LANE_LOOKAHEAD))
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


## Damage feedback: a short white flash, a spark and the health bar (health_changed only fires on damage).
func _on_health_changed(current_health: int, max_health: int) -> void:
	_health_bar.show_health(current_health, max_health)
	var flash_material: ShaderMaterial = _sprite.material
	flash_material.set_shader_parameter("flash", 1.0)  # visible in the same frame as the hit
	var flash: Tween = create_tween()
	flash.tween_property(flash_material, "shader_parameter/flash", 0.0, 0.15)
	# A quick jolt: up (thrown back), then settle.
	if _jolt != null:
		_jolt.kill()
	_jolt = create_tween()
	_sprite.position = _sprite_rest + Vector2(0, -HIT_JOLT)
	_jolt.tween_property(_sprite, "position", _sprite_rest, HIT_JOLT_TIME)
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


func _on_fortress_hitbox_hit(_fortress_hurtbox: Hurtbox) -> void:
	# Reaching the fortress spends the enemy.
	_finish(reached_fortress)


## Reports how the enemy left (once, even if killed in the same frame it reaches the fortress) and removes it.
func _finish(outcome: Signal) -> void:
	if _is_finished:
		return
	_is_finished = true
	outcome.emit(self)
	queue_free()
