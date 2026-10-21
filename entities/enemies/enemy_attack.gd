class_name EnemyAttack
extends Node
## An enemy's attacks (a component of Enemy, which calls step() each physics frame it may act): the
## hero entering its AttackRange becomes its target; it winds up (data.attack_windup), strikes (the
## AttackHitbox on for STRIKE_DURATION, aimed where the target is now: one who stepped away is missed)
## and cools down (data.attack_cooldown). Against a target with an AttackerLimit it first claims a slot,
## and frees it after the strike (or when it dies mid-attack). A ranged enemy (the Cultist) shoots an
## EnemyBolt instead, needs no slot, and besieges the fortress from data.siege_distance before its
## lane's end while the hero isn't in range.

## The wind-up of an attack began.
signal attack_started

## How long the attack hitbox stays active once the strike lands, in seconds.
const STRIKE_DURATION: float = 0.1
const BOLT_SCENE: PackedScene = preload("res://entities/enemies/enemy_bolt.tscn")
## Ranged enemies cast from this height above their centre (the hands).
const CAST_HEIGHT: float = 14.0

@export var attack_range: Area2D
@export var attack_pivot: Node2D
@export var attack_shape: CollisionShape2D

var _enemy: Enemy
## The body (the hero) currently inside attack range, if any.
var _target: Node2D = null
var _cooldown_left: float = 0.0
## Seconds until the current wind-up strikes; negative when not winding up.
var _windup_left: float = -1.0
var _strike_left: float = 0.0
## The target's AttackerLimit while this enemy holds one of its slots.
var _claimed_limit: AttackerLimit = null


## Called by the enemy in its _ready().
func setup(enemy: Enemy) -> void:
	_enemy = enemy
	attack_range.body_entered.connect(func(body: Node2D) -> void: _target = body)
	attack_range.body_exited.connect(func(body: Node2D) -> void:
		if body == _target:
			_target = null)


func _exit_tree() -> void:
	_release_slot()  # dying mid-attack frees the slot for the next enemy


## The cooldown runs every frame, even while the enemy can't act (frozen, busy).
func tick_cooldown(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)


## Advances a strike or a wind-up, or starts an attack when the target (or the siege) allows.
func step(delta: float) -> void:
	if _strike_left > 0.0:
		_strike_left -= delta
		if _strike_left <= 0.0:
			attack_shape.set_deferred("disabled", true)
			_release_slot()
	if _windup_left >= 0.0:
		_windup_left -= delta
		if _windup_left < 0.0:
			_strike()
	elif _cooldown_left <= 0.0 and _strike_left <= 0.0:
		if (has_target() and _claim_slot()) or is_sieging():
			_begin_attack()


## True while winding up or striking.
func is_attacking() -> bool:
	return _windup_left >= 0.0 or _strike_left > 0.0


func has_target() -> bool:
	return _target != null and is_instance_valid(_target)


## True when it could start an attack right now if the target's AttackerLimit gave it a slot.
func is_ready_to_attack() -> bool:
	return has_target() and not is_attacking() and _cooldown_left <= 0.0


## True for a ranged enemy that has reached its firing spot before the fortress (and isn't busy
## with the hero): it stands there and shoots the fortress.
func is_sieging() -> bool:
	var data: EnemyData = _enemy.data
	var lane: Path2D = _enemy.lane
	if data.siege_distance <= 0.0 or lane == null or has_target() or not data.is_ranged():
		return false
	return lane.curve.get_baked_length() - _enemy.get_lane_progress() <= data.siege_distance


## True if the target allows another attacker right now (or has no limit).
func _claim_slot() -> bool:
	if _enemy.data.is_ranged():
		return true  # the limit keeps melee crowds readable; shots don't crowd
	var limit: AttackerLimit = AttackerLimit.find_on(_target)
	if limit == null:
		return true
	if not limit.try_claim(_enemy):
		return false
	_claimed_limit = limit
	return true


func _release_slot() -> void:
	if _claimed_limit != null and is_instance_valid(_claimed_limit):
		_claimed_limit.release(_enemy)
	_claimed_limit = null


func _begin_attack() -> void:
	_cooldown_left = _enemy.data.attack_cooldown
	_windup_left = _enemy.data.attack_windup
	_enemy.get_sprite().face(get_aim_point() - _enemy.global_position)
	_enemy.get_sprite().play_state("attack", true)
	attack_started.emit()


## The strike lands toward where the target is now; if it stepped away during the wind-up, it misses.
## A ranged enemy shoots instead, at where the hero (or the fortress) is now.
func _strike() -> void:
	if _enemy.data.is_ranged():
		_shoot()
		return
	if has_target():
		attack_pivot.rotation = (_target.global_position - _enemy.global_position).angle()
	# Turning the shape on counts as a new overlap, so one strike hits at most once.
	attack_shape.set_deferred("disabled", false)
	_strike_left = STRIKE_DURATION


func _shoot() -> void:
	if not has_target() and not is_sieging():
		return  # the hero left during the cast and the fortress is out of reach
	var data: EnemyData = _enemy.data
	var bolt: EnemyBolt = BOLT_SCENE.instantiate()
	var against_hero: bool = has_target()
	var from: Vector2 = _enemy.global_position + Vector2(0, -CAST_HEIGHT)
	bolt.setup(from, get_aim_point(), data.bolt_speed, data.hero_damage if against_hero else data.siege_damage, against_hero)
	_enemy.add_child(bolt)  # a caster's spell dies with it


## What the next attack is aimed at: the hero in range, else the end of the lane (the fortress).
func get_aim_point() -> Vector2:
	if has_target():
		return _target.global_position
	var lane: Path2D = _enemy.lane
	return lane.to_global(lane.curve.sample_baked(lane.curve.get_baked_length())) if lane != null else _enemy.global_position
