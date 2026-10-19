class_name Projectile
extends Node2D
## A tower's shot. Flies at its target, following it while it lives and stays within the tower's reach
## (attack range + RANGE_SLACK from the tower's base); a target that dies or runs out of reach is
## lost: the shot flies on to the last point it aimed at and fizzles (or explodes there, for splash).
## On arrival it either hits that one enemy or explodes. Damage always goes through the enemy's
## Hurtbox / HealthComponent. The sprite is display only.
## Shells (TowerData.homing = false) are different: fired at a ground point, they never follow anyone.
## They travel along the ground from the tower's base while the sprite rises from the muzzle in an
## arc (with a shadow below it), a LandingMarker shows the blast area, and they explode on the point:
## whatever stands there is hit, an enemy that got away is not.

## Close enough to count as arrived, in pixels.
const ARRIVE_DISTANCE: float = 8.0
## Safety net: a shot never lives longer than this.
const MAX_LIFETIME: float = 3.0
## How far past the tower's range a shot still follows its target (the target keeps walking while
## the shot is in the air).
const RANGE_SLACK: float = 32.0
## A shell's arc: how high above its ground path it is at mid-flight (display only).
const SHELL_ARC_HEIGHT: float = 34.0
const SHADOW_COLOR: Color = Color(0, 0, 0, 0.34)
const LANDING_MARKER_SCENE: PackedScene = preload("res://entities/towers/landing_marker.tscn")
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
## Ground-targeted shell: the muzzle's height above the ground path and the flight length.
var _shell: bool = false
var _muzzle: Vector2 = Vector2.ZERO
var _flight: float = 1.0
var _marker: Node2D

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


## A shell (see the class doc): call before adding it to the tree. It lands on `point` and explodes.
func launch_at_point(tower_data: TowerData, point: Vector2, base: Vector2, muzzle_offset: Vector2) -> void:
	data = tower_data
	target = null
	top_level = true
	position = base
	_destination = point
	_shell = true
	_muzzle = muzzle_offset
	_flight = maxf(base.distance_to(point), 1.0)


## Where the shot will end (a shell's landing point; a homing shot's current aim).
func get_destination() -> Vector2:
	return _destination


func is_shell() -> bool:
	return _shell


func _ready() -> void:
	if data == null:
		queue_free()  # opened on its own, never launched: nothing to fly at
		set_physics_process(false)
		return
	_hitbox.damage = data.damage
	_update_look(_destination - position)
	if _shell:
		_marker = LANDING_MARKER_SCENE.instantiate()
		_marker.top_level = true
		_marker.position = _destination
		(_marker as LandingMarker).setup(data.splash_radius)
		add_child(_marker)
		_update_arc()


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
	if _shell:
		_update_arc()


func _target_alive() -> bool:
	return is_instance_valid(target) and target.is_alive()


## True once the target ran out of the tower's reach (the shot no longer follows it).
func is_lost() -> bool:
	return _lost


## The shell's sprite: from the muzzle down to the ground point, lifted by a parabola (display only).
func _update_arc() -> void:
	var t: float = clampf(1.0 - global_position.distance_to(_destination) / _flight, 0.0, 1.0)
	_sprite.position = (_muzzle * (1.0 - t) + Vector2(0, -SHELL_ARC_HEIGHT * 4.0 * t * (1.0 - t))).round()


## A shell's shadow on the ground, under its sprite.
func _draw() -> void:
	if _shell and _sprite.visible:
		draw_rect(Rect2(-6, -2, 12, 4), SHADOW_COLOR)  # a small oval: no overlapping (darker) pixels
		draw_rect(Rect2(-4, -4, 8, 2), SHADOW_COLOR)
		draw_rect(Rect2(-4, 2, 8, 2), SHADOW_COLOR)


func _impact() -> void:
	if _marker != null:
		_marker.hide()
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
	queue_redraw()
	effect.tree_exiting.connect(queue_free)
	add_child(effect)


## Arrows point where they fly (8 pre-drawn directions, never rotated); other shots just play.
func _update_look(direction: Vector2) -> void:
	if data.projectile_look == &"arrow":
		if not direction.is_zero_approx():
			_sprite.play(StringName("arrow_%d" % posmod(roundi(direction.angle() / (PI / 4.0)), 8)))
	elif _sprite.animation != data.projectile_look:
		_sprite.play(data.projectile_look)
