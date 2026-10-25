class_name BurnZone
extends Node2D
## Burning ground left by a shot (hellfire shells, the brazier) or a dash (Cinder Dash): for
## `duration` seconds it sets every enemy on it on fire (EnemyStatus.ignite: `dps`, burning on for
## AFTERBURN s after it steps off). Fire never stacks on one enemy: standing in several patches, or
## in the fire of several towers, it burns at the strongest one's rate. Then the flames die down.
## Soul fire (Pyre of Souls, set_death_burst): an enemy that dies while on it (by any hand) bursts:
## damage to every enemy around it and plain burning ground there (no chain of bursts).

## Seconds between two ignitions of what stands in it.
const TICK: float = 0.25
## The fire leaps this far (px) to a neighbour, once per SPREAD_EVERY seconds.
const SPREAD_RADIUS: float = 60.0
const SPREAD_EVERY: float = 1.0
## An enemy keeps burning this long after it leaves the fire.
const AFTERBURN: float = 1.0
const FADE_TIME: float = 0.4
const EXPLOSION_SCENE: PackedScene = preload("res://entities/towers/explosion.tscn")
const SOUL_FRAMES: SpriteFrames = preload("res://entities/effects/soul_burst_frames.tres")

## Heart of the Pyre: the fire also leaps to one enemy next to a burning one (once a second).
var spreads: bool = false

var _dps: float = 6.0
var _radius: float = 40.0
var _duration: float = 3.0
var _duration_full: float = 3.0
var _tick_left: float = 0.0
var _spread_left: float = 0.0
var _burst_damage: int = 0
var _burst_radius: float = 0.0
## Enemies on the soul fire whose death is watched.
var _watched: Array[Enemy] = []

@onready var _sprite: AnimatedSprite2D = %Sprite


## Call before adding it to the tree.
func setup(dps: float, radius: float, duration: float) -> void:
	_dps = dps
	_radius = radius
	_duration = duration
	_duration_full = duration


## Makes it soul fire: deaths on it burst for `damage` within `radius`. Call before adding it.
func set_death_burst(damage: int, radius: float) -> void:
	_burst_damage = damage
	_burst_radius = radius


func is_soul_fire() -> bool:
	return _burst_damage > 0


func _ready() -> void:
	add_to_group(Groups.BURN_ZONES)
	_sprite.play(&"soul_burn" if is_soul_fire() else &"burn")


func _physics_process(delta: float) -> void:
	_duration -= delta
	if _duration <= 0.0:
		set_physics_process(false)
		var fade: Tween = create_tween()
		fade.tween_property(self, "modulate:a", 0.0, FADE_TIME)
		fade.tween_callback(queue_free)
		_watch([])
		return
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left += TICK
	var on_fire: Array[Enemy] = EnemyQuery.in_circle(get_world_2d(), global_position, _radius)
	if is_soul_fire():
		_watch(on_fire)
	for enemy: Enemy in on_fire:
		enemy.get_status().ignite(_dps, TICK + AFTERBURN)
	_spread_left -= TICK
	if spreads and _spread_left <= 0.0:
		_spread_left = SPREAD_EVERY
		for burning: Enemy in on_fire:
			_leap(burning)


## One enemy near `from` that isn't burning yet catches its fire.
func _leap(from: Enemy) -> void:
	for neighbour: Enemy in EnemyQuery.in_circle(get_world_2d(), from.global_position, SPREAD_RADIUS):
		if neighbour != from and not neighbour.get_status().is_burning():
			neighbour.get_status().ignite(_dps, SPREAD_EVERY + AFTERBURN)
			return


func get_radius() -> float:
	return _radius


## Watches exactly `enemies` for a death on the soul fire (those that walked off are let go).
func _watch(enemies: Array[Enemy]) -> void:
	for i: int in range(_watched.size() - 1, -1, -1):
		var watched: Variant = _watched[i]
		if not is_instance_valid(watched) or not enemies.has(watched):
			if is_instance_valid(watched) and (watched as Enemy).died.is_connected(_on_watched_died):
				(watched as Enemy).died.disconnect(_on_watched_died)
			_watched.remove_at(i)
	for enemy: Enemy in enemies:
		if not _watched.has(enemy):
			_watched.append(enemy)
			enemy.died.connect(_on_watched_died)


## A soul-fire death: a burst around the corpse and plain burning ground where it fell. Deferred: the
## death may come from a hit inside a physics callback, where new areas can't be added.
func _on_watched_died(enemy: Enemy) -> void:
	_burst.call_deferred(enemy.global_position)


func _burst(at: Vector2) -> void:
	if not is_inside_tree():
		return
	var burst: Explosion = EXPLOSION_SCENE.instantiate()
	burst.setup(_burst_damage, _burst_radius)
	burst.set_look(SOUL_FRAMES, &"soul_burst")
	burst.top_level = true
	burst.position = at
	get_parent().add_child(burst)
	var spread: BurnZone = (load(scene_file_path) as PackedScene).instantiate()
	spread.setup(_dps, _radius, _duration_full)
	spread.top_level = true
	spread.position = at
	get_parent().add_child(spread)
