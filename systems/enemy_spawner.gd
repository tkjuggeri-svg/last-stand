class_name EnemySpawner
extends Node2D
## Spawns spawn_count enemies at the start of a lane, one every spawn_interval seconds.
## Spawned enemies become children of this node.

signal enemy_spawned(enemy: Enemy)

@export var enemy_scene: PackedScene
@export var lane: Path2D
@export var spawn_count: int = 10
## Seconds between two spawns. The first enemy appears immediately.
@export var spawn_interval: float = 2.0
@export var autostart: bool = true

var _spawned_count: int = 0
var _time_until_next_spawn: float = 0.0
var _running: bool = false


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


## Starts (or restarts) spawning from the first enemy.
func start() -> void:
	_spawned_count = 0
	_time_until_next_spawn = 0.0
	_running = true


func _spawn_enemy() -> void:
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.lane = lane
	add_child(enemy)
	enemy.global_position = lane.to_global(lane.curve.sample_baked(0.0))
	_spawned_count += 1
	enemy_spawned.emit(enemy)
