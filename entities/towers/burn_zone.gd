class_name BurnZone
extends Node2D
## Burning ground left by a shot (hellfire shells, the brazier): for `duration` seconds every enemy
## on it takes `dps` damage per second, in ticks, through its Hurtbox like any other hit. Then the
## flames die down. The flames are display only.

## Seconds between two damage ticks.
const TICK: float = 0.25
const FADE_TIME: float = 0.4

var _dps: float = 6.0
var _radius: float = 40.0
var _duration: float = 3.0
var _tick_left: float = 0.0
## Damage owed but not dealt yet (ticks deal whole points).
var _pending: float = 0.0

@onready var _hitbox: Hitbox = %Hitbox
@onready var _sprite: AnimatedSprite2D = %Sprite


## Call before adding it to the tree.
func setup(dps: float, radius: float, duration: float) -> void:
	_dps = dps
	_radius = radius
	_duration = duration


func _ready() -> void:
	_sprite.play(&"burn")


func _physics_process(delta: float) -> void:
	_duration -= delta
	if _duration <= 0.0:
		set_physics_process(false)
		var fade: Tween = create_tween()
		fade.tween_property(self, "modulate:a", 0.0, FADE_TIME)
		fade.tween_callback(queue_free)
		return
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left += TICK
	_pending += _dps * TICK
	var damage: int = floori(_pending)
	if damage <= 0:
		return
	_pending -= damage
	_hitbox.damage = damage
	for enemy: Enemy in EnemyQuery.in_circle(get_world_2d(), global_position, _radius):
		enemy.receive_hit(_hitbox)


func get_radius() -> float:
	return _radius
