class_name ChargeAbility
extends EnemyAbility
## The Bone Colossus's mechanic: when the hero comes within trigger_range it stops, lowers its horns
## and paws the ground while a red arrow on the ground shows the charge's path (the direction is
## locked when the telegraph starts, so the hero can step aside), then charges along it at `speed`,
## through enemies but never through walls or the fortress. Hitting the hero deals `damage` once per
## charge (a dashing hero is immune). After a charge it stands stunned for stun_time: the moment to
## punish it. Then it walks back to its lane.

const ARROW_COLOR: Color = Color(1.0, 0.3, 0.2, 0.75)
## Physics layers the charge stops at: world (1) and fortress (8).
const BLOCKING_MASK: int = 1 | 8
## Physics layer bits: the hero's body (what it senses) and enemy_hitbox (what its horns are on).
const HERO_BODY_MASK: int = 2
const HERO_HIT_LAYER: int = 32
## How far before a wall or the fortress a charge stops.
const STOP_MARGIN: float = 14.0

@export var trigger_range: float = 300.0
@export var speed: float = 560.0
## The charge runs this far past where the hero stood, up to max_distance.
@export var overshoot: float = 90.0
@export var max_distance: float = 380.0
@export var damage: int = 35
@export var stun_time: float = 1.6

var _hero: Node2D = null
var _direction: Vector2 = Vector2.RIGHT
var _distance: float = 0.0
var _charge_left: float = 0.0
var _stun_left: float = 0.0
var _arrow: TelegraphMarker
var _sense: Area2D
var _horns: Hitbox
var _horns_shape: CollisionShape2D


func _ready() -> void:
	super()
	if enemy == null:
		return
	_sense = Area2D.new()
	_sense.collision_layer = 0
	_sense.collision_mask = HERO_BODY_MASK
	_sense.monitorable = false
	var sense_shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = trigger_range
	sense_shape.shape = circle
	_sense.add_child(sense_shape)
	_sense.body_entered.connect(func(body: Node2D) -> void: _hero = body)
	_sense.body_exited.connect(func(body: Node2D) -> void:
		if body == _hero:
			_hero = null)
	add_child(_sense)
	_horns = Hitbox.new()
	_horns.collision_layer = HERO_HIT_LAYER
	_horns.collision_mask = 0
	_horns.damage = damage
	_horns_shape = CollisionShape2D.new()
	var horn_circle: CircleShape2D = CircleShape2D.new()
	horn_circle.radius = enemy.data.body_radius + 6.0
	_horns_shape.shape = horn_circle
	_horns_shape.disabled = true
	_horns.add_child(_horns_shape)
	_horns.hit.connect(func(_hurtbox: Hurtbox) -> void: _horns_shape.set_deferred(&"disabled", true))
	add_child(_horns)


func is_busy() -> bool:
	return super() or is_charging() or is_stunned()


func is_charging() -> bool:
	return _charge_left > 0.0


func is_stunned() -> bool:
	return _stun_left > 0.0


## The locked direction of the current (or last) charge.
func get_direction() -> Vector2:
	return _direction


func get_charge_distance() -> float:
	return _distance


func _can_start() -> bool:
	return _hero != null and is_instance_valid(_hero) and not is_charging() and not is_stunned()


func _begin_telegraph() -> void:
	var to_hero: Vector2 = _hero.global_position - enemy.global_position
	_direction = to_hero.normalized() if not to_hero.is_zero_approx() else Vector2.RIGHT
	_distance = _clear_distance(minf(to_hero.length() + overshoot, max_distance))
	_arrow = _marker(TelegraphMarker.Shape.ARROW, enemy.global_position, ARROW_COLOR, _distance)
	_arrow.direction = _direction
	_arrow.width = enemy.data.body_radius * 2.0
	enemy.velocity = Vector2.ZERO
	enemy.get_sprite().face(_direction)
	_play("brace")


func _telegraph_step(progress: float) -> void:
	_arrow.progress = progress


func _act() -> void:
	_arrow.queue_free()
	_charge_left = _distance
	_horns_shape.set_deferred(&"disabled", false)
	_play("charge")


func _ability_step(delta: float) -> void:
	if is_charging():
		var step: float = minf(speed * delta, _charge_left)
		_charge_left -= step
		enemy.velocity = _direction * (step / delta)
		enemy.move_and_slide()
		if _charge_left <= 0.0:
			_end_charge()
	elif is_stunned():
		_stun_left -= delta
		enemy.velocity = Vector2.ZERO


func _end_charge() -> void:
	_charge_left = 0.0
	_horns_shape.set_deferred(&"disabled", true)
	_stun_left = stun_time
	enemy.velocity = Vector2.ZERO
	_play("stun")


## How far it can charge along _direction before its body would hit a wall or the fortress.
func _clear_distance(wanted: float) -> float:
	var from: Vector2 = enemy.global_position
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, from + _direction * (wanted + enemy.data.body_radius), BLOCKING_MASK)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return wanted
	# A margin keeps its fortress contact (its body circle) off the fortress's walls.
	return maxf(from.distance_to(hit["position"]) - enemy.data.body_radius - STOP_MARGIN, 0.0)
