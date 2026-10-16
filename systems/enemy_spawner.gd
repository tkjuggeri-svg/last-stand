class_name EnemySpawner
extends Node2D
## Spawns spawn_count enemies at the start of a lane, one every spawn_interval seconds.
## Spawned enemies become children of this node. One run (start() until every spawned enemy is gone,
## killed or used up at the fortress) is reported as wave_started .. wave_cleared.

signal wave_started
## Every enemy of the current run has been spawned and is gone again.
signal wave_cleared
signal enemy_spawned(enemy: Enemy)
## A spawned enemy was killed (not when it is used up at the fortress).
signal enemy_killed(enemy: Enemy)
## A spawned enemy reached the fortress and was used up.
signal enemy_reached_fortress(enemy: Enemy)
## The number of living enemies or the total spawned changed.
signal enemy_counts_changed(living_count: int, spawned_count: int)

@export var enemy_scene: PackedScene
@export var lane: Path2D
@export var spawn_count: int = 10
## Seconds between two spawns. The first enemy appears immediately.
@export var spawn_interval: float = 2.0
@export var autostart: bool = true

var _spawned_count: int = 0
var _living_count: int = 0
var _time_until_next_spawn: float = 0.0
var _running: bool = false
var _wave_open: bool = false


func _ready() -> void:
	assert(enemy_scene != null, "EnemySpawner needs an enemy_scene: %s" % get_path())
	assert(lane != null, "EnemySpawner needs a lane: %s" % get_path())
	if autostart:
		start()


func _physics_process(delta: float) -> void:
	if not _running:
		return
	_time_until_next_spawn -= delta
	if _time_until_next_spawn > 0.0:
		return
	_spawn_enemy()
	# Add instead of reset, so small frame-time leftovers don't make spawns drift later.
	_time_until_next_spawn += spawn_interval
	if _spawned_count >= spawn_count:
		_running = false
		_check_wave_cleared()


func get_spawned_count() -> int:
	return _spawned_count


func get_living_count() -> int:
	return _living_count


## True from start() until every enemy of the run is gone (listeners that connect late can check it).
func is_wave_active() -> bool:
	return _wave_open


## Starts (or restarts) spawning from the first enemy.
func start() -> void:
	_spawned_count = 0
	_time_until_next_spawn = 0.0
	_running = true
	_wave_open = true
	wave_started.emit()
	_check_wave_cleared()  # a run with spawn_count 0 is over at once


func _spawn_enemy() -> void:
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.lane = lane
	enemy.died.connect(_on_enemy_died)
	enemy.reached_fortress.connect(_on_enemy_reached_fortress)
	add_child(enemy)
	enemy.global_position = lane.to_global(lane.curve.sample_baked(0.0))
	_spawned_count += 1
	_living_count += 1
	enemy_spawned.emit(enemy)
	enemy_counts_changed.emit(_living_count, _spawned_count)


func _on_enemy_died(enemy: Enemy) -> void:
	_living_count -= 1
	enemy_killed.emit(enemy)
	enemy_counts_changed.emit(_living_count, _spawned_count)
	_check_wave_cleared()


func _on_enemy_reached_fortress(enemy: Enemy) -> void:
	_living_count -= 1
	enemy_reached_fortress.emit(enemy)
	enemy_counts_changed.emit(_living_count, _spawned_count)
	_check_wave_cleared()


func _check_wave_cleared() -> void:
	if _wave_open and not _running and _living_count == 0 and _spawned_count >= spawn_count:
		_wave_open = false
		wave_cleared.emit()
