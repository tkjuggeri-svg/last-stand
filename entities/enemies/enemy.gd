class_name Enemy
extends CharacterBody2D
## Base enemy: walks along its lane toward the fortress. When the hero comes within attack range it
## stops and attacks (wind-up, strike, cooldown), then resumes the lane once the hero is gone.
## If the target has an AttackerLimit, the enemy must claim a slot first; otherwise it waits its turn.
## A ranged enemy (EnemyData.bolt_speed > 0, the Cultist) shoots instead of striking (no slot
## needed), and stops data.siege_distance before its lane's end to shoot the fortress, unless the
## hero is in range: then the hero is its target. A boss has an EnemyAbility (EnemyData.ability)
## that runs beside this and may take the enemy over for a while (is_busy).
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
## Its ability calls up `data` at `at` (the WaveSpawner adds it to the wave, on this enemy's lane).
signal summon_requested(summoner: Enemy, minion: EnemyData, at: Vector2)

## How far ahead on the lane the enemy aims, in pixels. Aiming ahead (instead of following
## a fixed position) lets it find its way back to the lane if something pushes it off.
const LANE_LOOKAHEAD: float = 24.0
## How long the attack hitbox stays active once the strike lands, in seconds.
const STRIKE_DURATION: float = 0.1
## The hurtbox is this much bigger than the body, so hits that graze the body still count.
const HURTBOX_MARGIN: float = 2.0
## The claw/fist strike reaches this far past the body's edge (centre of the attack shape).
const STRIKE_REACH: float = 10.0
const BOLT_SCENE: PackedScene = preload("res://entities/enemies/enemy_bolt.tscn")
## Ranged enemies cast from this height above their centre (the hands).
const CAST_HEIGHT: float = 14.0

@export var data: EnemyData

## The Path2D to follow. Set by the spawner before the enemy is added to the tree.
var lane: Path2D
## Its wave's toughness: max HP = data.max_health x this. Set by the spawner before it enters the tree.
var health_multiplier: float = 1.0
## Its wave's kill-gold scale: the kill pays data.gold_reward x this (WaveRewards). Set by the spawner.
var gold_multiplier: float = 1.0
## Its wave's pace: move speed = data.move_speed x this (before slows). Set by the spawner.
var speed_multiplier: float = 1.0

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
## Where on its lane the enemy is (curve offset), worked out once per physics frame: finding the
## closest point on the curve is the costliest thing an enemy does, and towers ask for it too.
var _lane_offset: float = 0.0
var _lane_offset_frame: int = -1
var _ability: EnemyAbility

@onready var _health: HealthComponent = %HealthComponent
@onready var _fortress_hitbox: Hitbox = %FortressHitbox
@onready var _attack_range: Area2D = %AttackRange
@onready var _attack_pivot: Node2D = %AttackPivot
@onready var _attack_hitbox: Hitbox = %AttackHitbox
@onready var _attack_shape: CollisionShape2D = %AttackShape
@onready var _sprite: DirectionalSprite = %Sprite
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _look: EnemyLook = %Look


func _ready() -> void:
	assert(data != null, "Enemy needs EnemyData: %s" % get_path())
	_health.setup(maxi(roundi(data.max_health * health_multiplier), 1))
	_fortress_hitbox.damage = data.fortress_damage
	_attack_hitbox.damage = data.hero_damage
	_apply_body(data.body_radius)
	_look.setup(data)
	_health.shield_changed.connect(_look.show_shield)
	if data.ability != null:
		_ability = data.ability.instantiate()
		_ability.setup(self)
		add_child(_ability)
	_health.died.connect(_on_health_died)
	_health.health_changed.connect(_on_health_changed)
	_fortress_hitbox.hit.connect(_on_fortress_hitbox_hit)
	_attack_range.body_entered.connect(_on_attack_range_body_entered)
	_attack_range.body_exited.connect(_on_attack_range_body_exited)


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_update_slow(delta)
	if is_busy():
		return  # the ability moves and animates it
	_update_attack(delta)
	if is_attacking() or has_target() or is_sieging():
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


## True while its ability has taken over (telegraphing, charging, stunned): no walking, no attacks.
func is_busy() -> bool:
	return _ability != null and _ability.is_busy()


func get_health() -> HealthComponent:
	return _health


func get_sprite() -> DirectionalSprite:
	return _sprite


## A ward from a boss: absorbs `amount` damage for `seconds` (see HealthComponent.add_shield).
func add_shield(amount: int, seconds: float) -> void:
	if is_alive():
		_health.add_shield(amount, seconds)


func request_summon(minion: EnemyData, at: Vector2) -> void:
	summon_requested.emit(self, minion, at)


## The spawner reports the enemy a summon produced (a summoner keeps count of its own).
func adopt_minion(minion: Enemy) -> void:
	var summoner: SummonAbility = _ability as SummonAbility
	if summoner != null:
		summoner.track_minion(minion)


## True while winding up or striking.
func is_attacking() -> bool:
	return _windup_left >= 0.0 or _strike_left > 0.0


func has_target() -> bool:
	return _target != null and is_instance_valid(_target)


## True for a ranged enemy that has reached its firing spot before the fortress (and isn't busy
## with the hero): it stands there and shoots the fortress.
func is_sieging() -> bool:
	if data.siege_distance <= 0.0 or lane == null or has_target() or not data.is_ranged():
		return false
	return lane.curve.get_baked_length() - get_lane_progress() <= data.siege_distance


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
	return data.move_speed * speed_multiplier * _slow_factor


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
	_look.show_slowed(true)


func _update_slow(delta: float) -> void:
	if _slow_left <= 0.0:
		return
	_slow_left -= delta
	if _slow_left <= 0.0:
		_slow_left = 0.0
		_slow_factor = 1.0
		_look.show_slowed(false)


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
	elif _cooldown_left <= 0.0 and _strike_left <= 0.0:
		if (has_target() and _claim_slot()) or is_sieging():
			_begin_attack()


## True if the target allows another attacker right now (or has no limit).
func _claim_slot() -> bool:
	if data.is_ranged():
		return true  # the limit keeps melee crowds readable; shots don't crowd
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
	_sprite.face(_aim_point() - global_position)
	_sprite.play_state("attack", true)
	attack_started.emit(self)


## The strike lands toward where the target is now; if it stepped away during the wind-up, it misses.
## A ranged enemy shoots instead, at where the hero (or the fortress) is now.
func _strike() -> void:
	if data.is_ranged():
		_shoot()
		return
	if has_target():
		_attack_pivot.rotation = (_target.global_position - global_position).angle()
	# Turning the shape on counts as a new overlap, so one strike hits at most once.
	_attack_shape.set_deferred("disabled", false)
	_strike_left = STRIKE_DURATION


func _shoot() -> void:
	if not has_target() and not is_sieging():
		return  # the hero left during the cast and the fortress is out of reach
	var bolt: EnemyBolt = BOLT_SCENE.instantiate()
	var against_hero: bool = has_target()
	var from: Vector2 = global_position + Vector2(0, -CAST_HEIGHT)
	bolt.setup(from, _aim_point(), data.bolt_speed, data.hero_damage if against_hero else data.siege_damage, against_hero)
	add_child(bolt)  # a caster's spell dies with it


## What the next attack is aimed at: the hero in range, else the end of the lane (the fortress).
func _aim_point() -> Vector2:
	if has_target():
		return _target.global_position
	return lane.to_global(lane.curve.sample_baked(lane.curve.get_baked_length())) if lane != null else global_position


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


## Damage feedback (health_changed only fires on damage).
func _on_health_changed(current_health: int, max_health: int) -> void:
	_look.show_hit(current_health, max_health)


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
