class_name HeroDash
extends Node
## The hero's dash (a component of the Hero): a short burst of speed in one direction, on a cooldown,
## immune to hits while it lasts (plus a short grace). The hero's body only collides with the world
## and the fortress, so a dash passes through enemies and stops at walls (move_and_slide).
## With the Cinder Dash upgrade it leaves burning ground along its path. The afterimages are display
## only; the hero asks this node for its velocity while is_dashing() is true.

## A dash began (`direction` is normalized).
signal dashed(direction: Vector2)
## The cooldown ran out: the next dash is available.
signal ready_again

const BURN_ZONE_SCENE: PackedScene = preload("res://entities/towers/burn_zone.tscn")
const DUST_SCENE: PackedScene = preload("res://entities/effects/dust_puff.tscn")
## Afterimages (display only): one every this many seconds of dash, fading over AFTERIMAGE_FADE.
const AFTERIMAGE_INTERVAL: float = 0.04
const AFTERIMAGE_FADE: float = 0.22
const AFTERIMAGE_TINT: Color = Color(0.72, 0.82, 1.0, 0.55)

## How far a dash goes, in px (less if a wall is in the way).
@export var distance: float = 120.0
## How long it takes, in seconds.
@export var duration: float = 0.16
## Seconds from the start of one dash until the next is available.
@export var cooldown: float = 2.0
## Shortest cooldown upgrades can reach.
@export var min_cooldown: float = 0.6
## Extra seconds of immunity after the dash ends.
@export var grace: float = 0.08
## Cinder Dash: a burning patch every this many px of the path, this big, burning this long.
@export var trail_spacing: float = 30.0
@export var trail_radius: float = 26.0
@export var trail_duration: float = 2.0
## The run's upgrades (dash cooldown, trail). Null = base stats.
var modifiers: RunModifiers

var _direction: Vector2 = Vector2.ZERO
var _dash_left: float = 0.0
var _cooldown_left: float = 0.0
var _afterimage_left: float = 0.0
var _trail_left: float = 0.0
## The hero's sprite, copied into afterimages (set by the hero).
var _sprite: AnimatedSprite2D
var _body: Node2D


## The hero passes its body (afterimages and trail are placed at its position) and sprite.
func setup(body: Node2D, sprite: AnimatedSprite2D) -> void:
	_body = body
	_sprite = sprite


func _physics_process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= delta
		if _cooldown_left <= 0.0:
			_cooldown_left = 0.0
			ready_again.emit()
	if _dash_left <= 0.0:
		return
	_dash_left -= delta
	_afterimage_left -= delta
	if _afterimage_left <= 0.0:
		_afterimage_left += AFTERIMAGE_INTERVAL
		_spawn_afterimage()
	_trail_left -= get_speed() * delta
	if _trail_left <= 0.0 and get_trail_dps() > 0.0:
		_trail_left += trail_spacing
		_spawn_burn()


## Starts a dash toward `direction` (any length; zero does nothing). False while dashing or cooling down.
func try_dash(direction: Vector2) -> bool:
	if not can_dash() or direction.is_zero_approx():
		return false
	_direction = direction.normalized()
	_dash_left = duration
	_cooldown_left = get_cooldown()
	_afterimage_left = 0.0
	_trail_left = 0.0
	_spawn_dust()
	dashed.emit(_direction)
	return true


func can_dash() -> bool:
	return _dash_left <= 0.0 and _cooldown_left <= 0.0


func is_dashing() -> bool:
	return _dash_left > 0.0


## Stops a dash early (the hero fell). The cooldown keeps running.
func cancel() -> void:
	_dash_left = 0.0


## The velocity the hero moves with while dashing.
func get_velocity() -> Vector2:
	return _direction * get_speed() if is_dashing() else Vector2.ZERO


func get_speed() -> float:
	return distance / duration


## Seconds of immunity a dash gives (its duration plus the grace).
func get_invulnerability() -> float:
	return duration + grace


## The full cooldown under the run's upgrades.
func get_cooldown() -> float:
	return maxf(RunModifiers.value(modifiers, cooldown, [RunModifiers.HERO_DASH_COOLDOWN]), maxf(min_cooldown, duration))


func get_cooldown_left() -> float:
	return _cooldown_left


## Damage per second of the burning trail (0 without Cinder Dash).
func get_trail_dps() -> float:
	return RunModifiers.value(modifiers, 0.0, [RunModifiers.HERO_DASH_TRAIL])


func _spawn_burn() -> void:
	var zone: BurnZone = BURN_ZONE_SCENE.instantiate()
	zone.setup(get_trail_dps(), trail_radius, trail_duration)
	_place(zone)


func _spawn_dust() -> void:
	_place(DUST_SCENE.instantiate())


## A fading copy of the hero's current frame where it is now.
func _spawn_afterimage() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var ghost: Sprite2D = Sprite2D.new()
	ghost.texture = _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	ghost.flip_h = _sprite.flip_h
	ghost.scale = _sprite.scale
	ghost.offset = _sprite.offset
	ghost.modulate = AFTERIMAGE_TINT
	ghost.z_index = -1
	_place(ghost, _sprite.position)
	var fade: Tween = ghost.create_tween()
	fade.tween_property(ghost, "modulate:a", 0.0, AFTERIMAGE_FADE)
	fade.tween_callback(ghost.queue_free)


## Effects stay where they were made: top-level children of the hero, at its position now.
func _place(item: Node2D, offset: Vector2 = Vector2.ZERO) -> void:
	if _body == null:
		return
	item.top_level = true
	_body.add_child(item)
	item.global_position = _body.global_position + offset
