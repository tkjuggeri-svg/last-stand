class_name EnemyBolt
extends Hitbox
## A ranged enemy's shot (the Cultist's witchfire). It flies straight at the point it was aimed at
## (not homing, so it can be dodged), on past it by OVERSHOOT, and hurts the first hurtbox of its
## kind it touches: the hero's (enemy_hitbox layer) or the fortress's (fortress_hitbox layer), never
## both. A dashing hero is immune, so it flies on. Then it bursts (display only).

## Physics layer bits (see CLAUDE.md): what a shot at the hero / at the fortress is on.
const HERO_SHOT_LAYER: int = 32
const FORTRESS_SHOT_LAYER: int = 128
## How far past its aim point a shot still flies before it fizzles out, in px.
const OVERSHOOT: float = 40.0

var _velocity: Vector2 = Vector2.ZERO
var _distance_left: float = 0.0
var _start: Vector2 = Vector2.ZERO
var _done: bool = false

@onready var _sprite: AnimatedSprite2D = %Sprite


## Call before adding it to the tree: from where to which point, how fast, how hard, and at whom.
func setup(from: Vector2, to: Vector2, speed: float, shot_damage: int, at_hero: bool) -> void:
	_start = from
	var path: Vector2 = to - from
	_velocity = path.normalized() * speed if not path.is_zero_approx() else Vector2.DOWN * speed
	_distance_left = path.length() + OVERSHOOT
	damage = shot_damage
	collision_layer = HERO_SHOT_LAYER if at_hero else FORTRESS_SHOT_LAYER


func _ready() -> void:
	top_level = true
	global_position = _start
	hit.connect(func(_hurtbox: Hurtbox) -> void: _burst())
	_sprite.play(&"bolt")
	_sprite.animation_finished.connect(queue_free)


func _physics_process(delta: float) -> void:
	if _done:
		return
	var step: float = _velocity.length() * delta
	global_position += _velocity * delta
	_distance_left -= step
	if _distance_left <= 0.0:
		_burst()


func is_spent() -> bool:
	return _done


## Stops, can't hurt anything any more, and plays the burst (then it's removed).
func _burst() -> void:
	if _done:
		return
	_done = true
	set_deferred(&"collision_layer", 0)
	_sprite.play(&"burst")
