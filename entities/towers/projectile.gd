class_name Projectile
extends Node2D
## A tower's shot. Flies at its target, following it while it lives and stays within the tower's reach
## (attack range + RANGE_SLACK from the tower's base); a target that dies or runs out of reach is
## lost: the shot flies on to the last point it aimed at and fizzles (or explodes there, for splash).
## On arrival it either hits that one enemy or explodes. Damage always goes through the enemy's
## Hurtbox / HealthComponent. The sprite is display only.

## Close enough to count as arrived, in pixels.
const ARRIVE_DISTANCE: float = 8.0
## Safety net: a shot never lives longer than this.
const MAX_LIFETIME: float = 3.0
## How far past the tower's range a shot still follows its target (the target keeps walking while
## the shot is in the air).
const RANGE_SLACK: float = 32.0
const EXPLOSION_SCENE: PackedScene = preload("res://entities/towers/explosion.tscn")
const FROST_BURST_SCENE: PackedScene = preload("res://entities/effects/frost_burst.tscn")

var data: TowerData
var target: Enemy

var _destination: Vector2
var _life: float = 0.0
## The tower's base and how far from it the shot may follow its target.
var _anchor: Vector2
var _reach: float = INF
var _lost: bool = false

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _hitbox: Hitbox = %Hitbox


## Call before adding it to the tree. Shots are top-level, so they fly free of the tower.
## `anchor` is the tower's base and `attack_range` its range: the shot never chases beyond them.
func launch(tower_data: TowerData, enemy: Enemy, from: Vector2, anchor: Vector2, attack_range: float) -> void:
	data = tower_data
	target = enemy
	top_level = true
	position = from
	_destination = enemy.global_position
	_anchor = anchor
	_reach = attack_range + RANGE_SLACK


func _ready() -> void:
	if data == null:
		queue_free()  # opened on its own, never launched: nothing to fly at
		set_physics_process(false)
		return
	_hitbox.damage = data.damage
	_update_look(_destination - position)


func _physics_process(delta: float) -> void:
	_life += delta
	if _life > MAX_LIFETIME:
		queue_free()
		return
	if not _lost and _target_alive():
		if target.global_position.distance_to(_anchor) <= _reach:
			_destination = target.global_position
		else:
			_lost = true  # out of reach: fly on to the last aim point and fizzle there
	var to_destination: Vector2 = _destination - global_position
	var step: float = data.projectile_speed * delta
	if to_destination.length() <= maxf(step, ARRIVE_DISTANCE):
		global_position = _destination
		_impact()
		return
	global_position += to_destination.normalized() * step
	_update_look(to_destination)


func _target_alive() -> bool:
	return is_instance_valid(target) and target.is_alive()


## True once the target ran out of the tower's reach (the shot no longer follows it).
func is_lost() -> bool:
	return _lost


func _impact() -> void:
	if data.splash_radius > 0.0:
		var explosion: Explosion = EXPLOSION_SCENE.instantiate()
		explosion.setup(data.damage, data.splash_radius)
		_finish_with(explosion)
		return
	if _target_alive() and not _lost:
		target.receive_hit(_hitbox)
		if data.slow_factor < 1.0:
			target.apply_slow(data.slow_factor, data.slow_duration)
			_finish_with(FROST_BURST_SCENE.instantiate())
			return
	# An arrow that hit, or a shot whose target is already gone, just disappears.
	queue_free()


## Stops here and shows an impact effect; the shot removes itself once the effect is done.
func _finish_with(effect: Node2D) -> void:
	set_physics_process(false)
	_sprite.hide()
	effect.tree_exiting.connect(queue_free)
	add_child(effect)


## Arrows point where they fly (8 pre-drawn directions, never rotated); other shots just play.
func _update_look(direction: Vector2) -> void:
	if data.projectile_look == &"arrow":
		if not direction.is_zero_approx():
			_sprite.play(StringName("arrow_%d" % posmod(roundi(direction.angle() / (PI / 4.0)), 8)))
	elif _sprite.animation != data.projectile_look:
		_sprite.play(data.projectile_look)
