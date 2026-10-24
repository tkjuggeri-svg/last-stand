class_name HeroBolt
extends Node2D
## A crossbow bolt of the Huntress. Flies straight along the ground from where it was loosed, hits each
## enemy once (up to 1 + pierce of them) and leaves her Mark on every enemy it hits. Like a tower's
## shot it is stopped by a shield facing it (Enemy.receive_shot). The sprite is display only.

## Close enough to the bolt's path to be hit, in px.
const HIT_RADIUS: float = 10.0
const LOOKS: String = "bolt_%d"

## Called back for each enemy hit (the hero's feedback and Bloodpact).
signal hit(enemy: Enemy)

var _direction: Vector2 = Vector2.RIGHT
var _speed: float = 0.0
var _range_left: float = 0.0
var _pierce_left: int = 0
var _mark_bonus: float = 0.0
var _mark_time: float = 0.0
var _pierced: Array[Enemy] = []
var _hitbox_damage: int = 0

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _hitbox: Hitbox = %Hitbox


## Call before adding it to the tree: where from, which way, how hard and far, and what it marks with.
func launch(from: Vector2, direction: Vector2, damage: int, data: HeroData, reach_scale: float = 1.0) -> void:
	top_level = true
	position = from
	_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	_speed = data.bolt_speed
	_range_left = data.bolt_range * reach_scale
	_pierce_left = data.bolt_pierce + 1
	_mark_bonus = data.mark_bonus
	_mark_time = data.mark_time
	_hitbox_damage = damage


func _ready() -> void:
	_hitbox.damage = _hitbox_damage
	_sprite.play(StringName(LOOKS % posmod(roundi(_direction.angle() / (PI / 4.0)), 8)))


func _physics_process(delta: float) -> void:
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
