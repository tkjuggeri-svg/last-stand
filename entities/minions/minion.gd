class_name Minion
extends CharacterBody2D
## A skeleton (M9). It seeks the nearest enemy within SEEK_RANGE of its anchor (the hero or the tower
## that raised it), walks up to it and strikes (a Hitbox on hero_hitbox, on for STRIKE_DURATION), and
## stands by its anchor when nothing is near. It is on the allies layer: enemies' attack ranges see it
## like the hero, so they stop to fight it, and its Hurtbox takes their blows. It expires after
## data.lifetime and may burst when it falls (Plague Pit). The sprite is display only.

## It fell (health 0), at its position; `burst` says whether it bursts.
signal fell(minion: Minion)
## Its blow landed on `enemy`, which is dead now if `killed`.
signal struck(enemy: Enemy, killed: bool)

const BURST_SCENE: PackedScene = preload("res://entities/towers/explosion.tscn")
## How far from its anchor it looks for a fight, and how far it follows one away from it.
const SEEK_RANGE: float = 260.0
## Close enough to strike: its centre to the enemy's centre.
const REACH: float = 30.0
const STRIKE_DURATION: float = 0.1
## Where it stands by its anchor when idle: this close (px).
const IDLE_DISTANCE: float = 50.0
const FADE_TIME: float = 0.4

var data: MinionData
## What it stays near (null: where it was raised).
var anchor: Node2D
## Scales its health (the run's cards); set before adding it to the tree.
var health_scale: float = 1.0

var _life_left: float = 0.0
var _cooldown_left: float = 0.0
var _strike_left: float = 0.0
var _home: Vector2
var _fallen: bool = false

@onready var _health: HealthComponent = %HealthComponent
@onready var _hitbox: Hitbox = %AttackHitbox
@onready var _shape: CollisionShape2D = %AttackShape
@onready var _pivot: Node2D = %AttackPivot
@onready var _sprite: AnimatedSprite2D = %Sprite


## Call before adding it to the tree.
func setup(minion_data: MinionData, at: Vector2, minion_anchor: Node2D = null, scale_health: float = 1.0) -> void:
	data = minion_data
	position = at
	anchor = minion_anchor
	health_scale = scale_health


func _ready() -> void:
	if data == null:
		queue_free()  # opened on its own, never raised: nothing to do
		set_physics_process(false)
		return
	_health.setup(maxi(roundi(data.max_health * health_scale), 1))
	_health.died.connect(_on_died)
	_hitbox.damage = data.damage
	_hitbox.hit.connect(_on_hit)
	_life_left = data.lifetime
	_home = global_position
	_sprite.play(&"idle")


func _physics_process(delta: float) -> void:
	if _fallen:
		return
	if data.lifetime > 0.0:
		_life_left -= delta
		if _life_left <= 0.0:
			_expire()
			return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if _strike_left > 0.0:
		_strike_left -= delta
		if _strike_left <= 0.0:
			_shape.set_deferred("disabled", true)
		return
	var target: Enemy = _find_target()
	if target != null:
		_fight(target)
	else:
		_stand_by()
	_update_animation()


func is_fallen() -> bool:
	return _fallen


func get_health() -> HealthComponent:
	return _health


func _find_target() -> Enemy:
	var around: Vector2 = anchor.global_position if is_instance_valid(anchor) else _home
	var best: Enemy = null
	for enemy: Enemy in EnemyQuery.in_circle(get_world_2d(), around, SEEK_RANGE):
		if best == null or enemy.global_position.distance_squared_to(global_position) < best.global_position.distance_squared_to(global_position):
			best = enemy
	return best


func _fight(target: Enemy) -> void:
	var to: Vector2 = target.global_position - global_position
	_face(to)
	if to.length() > REACH:
		velocity = to.normalized() * data.move_speed
		move_and_slide()
		return
	velocity = Vector2.ZERO
	if _cooldown_left <= 0.0:
		_cooldown_left = data.attack_cooldown
		_pivot.rotation = to.angle()
		_shape.set_deferred("disabled", false)  # a new overlap: one strike hits once
		_strike_left = STRIKE_DURATION
		_sprite.play(&"attack")
		Sfx.play(self, &"minion_strike")


func _stand_by() -> void:
	var spot: Vector2 = _home
	if is_instance_valid(anchor):
		spot = anchor.global_position + (global_position - anchor.global_position).limit_length(IDLE_DISTANCE)
	var to: Vector2 = spot - global_position
	if to.length() > 6.0:
		velocity = to.normalized() * data.move_speed * 0.6
		_face(to)
		move_and_slide()
	else:
		velocity = Vector2.ZERO


func _face(direction: Vector2) -> void:
	if absf(direction.x) > 1.0:
		_sprite.flip_h = direction.x < 0.0


func _update_animation() -> void:
	if _strike_left > 0.0 or (_sprite.animation == &"attack" and _sprite.is_playing()):
		return
	_sprite.play(&"walk" if not velocity.is_zero_approx() else &"idle")


func _on_hit(hurtbox: Hurtbox) -> void:
	var enemy: Enemy = hurtbox.owner as Enemy if is_instance_valid(hurtbox) else null
	if enemy != null:
		struck.emit(enemy, not enemy.is_alive())


func _on_died() -> void:
	_fallen = true
	_go_inert()
	fell.emit(self)
	if data.burst_damage > 0:
		var burst: Explosion = BURST_SCENE.instantiate()
		burst.setup(data.burst_damage, data.burst_radius)
		burst.top_level = true
		burst.position = global_position
		get_parent().add_child.call_deferred(burst)  # it fell inside a physics callback
	_sprite.play(&"death")
	_sprite.animation_finished.connect(queue_free)


## Runs out of time: it crumbles without a burst.
func _expire() -> void:
	_fallen = true
	_go_inert()
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(queue_free)


func _go_inert() -> void:
	set_deferred(&"collision_layer", 0)
	$Hurtbox.set_deferred(&"monitoring", false)
	_shape.set_deferred("disabled", true)
