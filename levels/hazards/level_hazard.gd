class_name LevelHazard
extends Node
## The base of a biome's environmental mechanic (M10), a node in the level scene. It runs while a wave
## is on (wave_started .. wave_cleared) and strikes now and then (HazardData): subclasses decide what a
## strike is in _strike() and announce it with _warn(), which shows the ground ring that fills up
## (TelegraphMarker) and runs the strike when it is full. Hazards never touch the physics layers: they use
## areas and queries on the layers that exist. A strike is small, telegraphed and never kills at once.

const WARNING_COLOR: Color = Color(1.0, 0.45, 0.2, 0.8)

@export var data: HazardData
@export var spawner: WaveSpawner
@export var hero: Hero
## Where its effects and markers go (the level's y-sorted Effects).
@export var effects: Node2D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _active: bool = false
var _next_in: float = 0.0
var _markers: Array[TelegraphMarker] = []


func _ready() -> void:
	rng.randomize()
	assert(data != null and spawner != null, "A LevelHazard needs its data and the spawner")
	spawner.wave_started.connect(_on_wave_started)
	spawner.wave_cleared.connect(_on_wave_cleared)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	_next_in -= delta
	if _next_in <= 0.0:
		_next_in = rng.randf_range(data.interval_min, data.interval_max)
		_strike()


func is_active() -> bool:
	return _active


## Seconds until the next strike (tests).
func get_next_in() -> float:
	return _next_in


## What one strike does. Subclasses override it (and call _warn()).
func _strike() -> void:
	pass


## Called when a wave starts (after the timer is set); subclasses may prepare.
func _on_started(_wave_number: int) -> void:
	pass


## Shows the warning ring at `at` (`radius` px) and calls `action` when it has filled, `data.warning`
## seconds later (not if the wave ended meanwhile). Returns the marker.
func _warn(at: Vector2, radius: float, action: Callable, color: Color = WARNING_COLOR) -> TelegraphMarker:
	var marker: TelegraphMarker = TelegraphMarker.new()
	marker.shape = TelegraphMarker.Shape.RING
	marker.color = color
	marker.size = radius
	marker.position = at
	_effects_root().add_child(marker)
	_markers.append(marker)
	var tween: Tween = marker.create_tween()
	tween.tween_property(marker, "progress", 1.0, maxf(data.warning, 0.05))
	tween.tween_callback(func() -> void:
		_markers.erase(marker)
		marker.queue_free()
		if _active:
			action.call())
	return marker


## A random point of a random lane between `from` and `to` (shares of its length), in world px; and the
## lane's index.
func _lane_point(from: float, to: float) -> Dictionary:
	var index: int = rng.randi_range(0, spawner.lanes.size() - 1)
	var lane: Path2D = spawner.lanes[index]
	var length: float = lane.curve.get_baked_length()
	return {"lane": index, "at": lane.to_global(lane.curve.sample_baked(rng.randf_range(from, to) * length))}


## The node strikes' effects go under (the level's Effects, or the hazard itself on its own).
func _effects_root() -> Node:
	var root: Node = effects
	if root == null:
		root = self
	return root


func _on_wave_started(wave_number: int) -> void:
	_active = true
	_next_in = data.first_delay
	_on_started(wave_number)


func _on_wave_cleared(_wave_number: int) -> void:
	_active = false
	for marker: TelegraphMarker in _markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_markers.clear()
