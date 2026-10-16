class_name Projectile
extends Node2D
## A tower's shot. Flies at its target (following it while it lives, then to its last known position)
## and on arrival either hits that one enemy or explodes (splash). Damage always goes through the
## enemy's Hurtbox / HealthComponent. The sprite is display only.

## Close enough to count as arrived, in pixels.
const ARRIVE_DISTANCE: float = 8.0
## Safety net: a shot never lives longer than this.
const MAX_LIFETIME: float = 3.0
const EXPLOSION_SCENE: PackedScene = preload("res://entities/towers/explosion.tscn")
const FROST_BURST_SCENE: PackedScene = preload("res://entities/effects/frost_burst.tscn")

var data: TowerData
var target: Enemy

var _destination: Vector2
var _life: float = 0.0

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _hitbox: Hitbox = %Hitbox


## Call before adding it to the tree. Shots are top-level, so they fly free of the tower.
func launch(tower_data: TowerData, enemy: Enemy, from: Vector2) -> void:
	data = tower_data
	target = enemy
	top_level = true
	position = from
	_destination = enemy.global_position


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
	if _target_alive():
		_destination = target.global_position
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


func _impact() -> void:
	if data.splash_radius > 0.0:
		var explosion: Explosion = EXPLOSION_SCENE.instantiate()
		explosion.setup(data.damage, data.splash_radius)
		_finish_with(explosion)
		return
	if _target_alive():
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
