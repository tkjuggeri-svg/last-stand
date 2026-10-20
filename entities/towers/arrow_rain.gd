class_name ArrowRain
extends Node2D
## The Volley Tower's attack: a marked circle on the ground, then `strikes` showers of arrows land on
## it, `interval` seconds apart (the first one interval after the volley). Each shower hits every
## enemy inside the circle once for `damage`, through its Hurtbox. The arrows are display only; the
## node removes itself after the last shower has played.

const SHOWER_TIME: float = 0.35

var _damage: int = 10
var _radius: float = 56.0
var _strikes_left: int = 1
var _interval: float = 0.25
var _next_strike: float = 0.25

@onready var _hitbox: Hitbox = %Hitbox
@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _marker: LandingMarker = %Marker


## Call before adding it to the tree.
func setup(damage: int, radius: float, strikes: int, interval: float) -> void:
	_damage = damage
	_radius = radius
	_strikes_left = maxi(strikes, 1)
	_interval = interval
	_next_strike = interval


func _ready() -> void:
	_hitbox.damage = _damage
	_marker.setup(_radius)
	_sprite.hide()


func _physics_process(delta: float) -> void:
	_next_strike -= delta
	if _next_strike > 0.0:
		return
	if _strikes_left <= 0:
		queue_free()
		return
	_strikes_left -= 1
	_next_strike = _interval if _strikes_left > 0 else SHOWER_TIME
	_sprite.show()
	_sprite.stop()
	_sprite.play(&"arrow_rain")
	for enemy: Enemy in EnemyQuery.in_circle(get_world_2d(), global_position, _radius):
		enemy.receive_hit(_hitbox)
	if _strikes_left <= 0:
		_marker.hide()


func get_strikes_left() -> int:
	return _strikes_left
