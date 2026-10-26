class_name HeroBolt
extends Node2D
## A crossbow bolt of the Huntress. Flies straight along the ground from where it was loosed, hits each
## enemy once (up to 1 + pierce of them) and leaves her Mark on every enemy it hits. Like a tower's
## shot it is stopped by a shield facing it (Enemy.receive_shot). A hero with `bolt_homing` bends it
## slightly toward the nearest enemy ahead, so a near miss still lands. The sprite is display only.

## Close enough to the bolt's path to be hit, in px.
const HIT_RADIUS: float = 10.0
## Homing sees enemies this far (px) and only those within this angle of the flight direction (radians),
## so the bolt never turns back on itself.
const HOMING_RADIUS: float = 140.0
const HOMING_CONE: float = 0.8

## Called back for each enemy hit (the hero's feedback and Bloodpact).
signal hit(enemy: Enemy)

var _direction: Vector2 = Vector2.RIGHT
var _speed: float = 0.0
var _range_left: float = 0.0
var _pierce_left: int = 0
var _mark_bonus: float = 0.0
var _mark_time: float = 0.0
var _pierced: Array[Enemy] = []
var _look: String = "bolt_%d"
var _frames: SpriteFrames
var _hitbox_damage: int = 0
var _homing: float = 0.0
var _facing_frame: int = -1

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _hitbox: Hitbox = %Hitbox


## Set before adding it to the tree (the run's upgrades): range scale, extra pierce, the Mark's bonus
## and time (default: the hero data's).
var reach_scale: float = 1.0
var extra_pierce: int = 0
var mark_bonus: float = -1.0
var mark_time: float = -1.0


## Call before adding it to the tree: where from, which way, how hard, and the hero's bolt stats.
func launch(from: Vector2, direction: Vector2, damage: int, data: HeroData) -> void:
	top_level = true
	position = from
	_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	_speed = data.bolt_speed
	_range_left = data.bolt_range * reach_scale
	_pierce_left = data.bolt_pierce + extra_pierce + 1
	_mark_bonus = data.mark_bonus if mark_bonus < 0.0 else mark_bonus
	_mark_time = data.mark_time if mark_time < 0.0 else mark_time
	_hitbox_damage = damage
	_homing = data.bolt_homing
	_look = "%s_%%d" % data.bolt_look
	_frames = data.bolt_frames


func _ready() -> void:
	_hitbox.damage = _hitbox_damage
	if _frames != null:
		_sprite.sprite_frames = _frames
	_face()


func _physics_process(delta: float) -> void:
	if _homing > 0.0:
		_steer(delta)
	var step: float = _speed * delta
	global_position += _direction * step
	_range_left -= step
	for enemy: Enemy in EnemyQuery.in_circle(get_world_2d(), global_position, HIT_RADIUS):
		if _pierce_left <= 0:
			break
		if _pierced.has(enemy):
			continue
		_pierced.append(enemy)
		if not enemy.receive_shot(_hitbox, _direction):
			queue_free()  # a shield stops it dead
			return
		enemy.get_status().mark(_mark_bonus, _mark_time)
		_pierce_left -= 1
		hit.emit(enemy)
	if _pierce_left <= 0 or _range_left <= 0.0:
		queue_free()


## The flight direction (display only): the sprite shows the nearest of 8 pre-drawn directions.
func get_direction() -> Vector2:
	return _direction


func _steer(delta: float) -> void:
	var best: Enemy = null
	var best_distance: float = INF
	for enemy: Enemy in EnemyQuery.in_circle(get_world_2d(), global_position, HOMING_RADIUS):
		if _pierced.has(enemy):
			continue
		var offset: Vector2 = enemy.global_position - global_position
		if absf(_direction.angle_to(offset)) > HOMING_CONE or offset.length_squared() >= best_distance:
			continue
		best = enemy
		best_distance = offset.length_squared()
	if best == null:
		return
	var turn: float = clampf(_direction.angle_to(best.global_position - global_position), -_homing * delta, _homing * delta)
	_direction = _direction.rotated(turn)
	_face()


func _face() -> void:
	var frame: int = posmod(roundi(_direction.angle() / (PI / 4.0)), 8)
	if frame != _facing_frame:
		_facing_frame = frame
		_sprite.play(StringName(_look % frame))
