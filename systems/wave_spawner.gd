class_name WaveSpawner
extends Node2D
## Spawns the enemies of one WaveData at a time, each group on its own lane. Spawned enemies become
## children of this node and take their EnemyData from the group. A wave runs from start_wave() until
## every enemy it sends has been spawned and is gone again (killed or used up at the fortress):
## wave_started .. wave_cleared. Starting waves is up to the owner (or autostart for the first one).

signal wave_started(wave_number: int)
## Every enemy of the wave has been spawned and is gone again.
signal wave_cleared(wave_number: int)
signal enemy_spawned(enemy: Enemy)
## A spawned enemy was killed (not when it is used up at the fortress).
signal enemy_killed(enemy: Enemy)
## A spawned enemy reached the fortress and was used up.
signal enemy_reached_fortress(enemy: Enemy)
## The number of living enemies or the number spawned in this wave changed.
signal enemy_counts_changed(living_count: int, spawned_count: int)

## The enemy scene every group instantiates (its EnemyData decides what it is).
@export var enemy_scene: PackedScene
## The level's lanes; a SpawnGroup picks one by index.
@export var lanes: Array[Path2D] = []
## The run's waves, in order.
@export var waves: Array[WaveData] = []
## Start the first wave as soon as the level is ready.
@export var autostart: bool = false

## Index of the current (or last) wave in `waves`; -1 before the first one.
var _wave_index: int = -1
var _wave_open: bool = false
## Seconds since the current wave started.
var _wave_time: float = 0.0
## How many enemies each group of the current wave has spawned so far.
var _group_spawned: PackedInt32Array = PackedInt32Array()
var _spawned_count: int = 0
var _living_count: int = 0
var _finished_count: int = 0


func _ready() -> void:
	assert(enemy_scene != null, "WaveSpawner needs an enemy_scene: %s" % get_path())
	assert(not lanes.is_empty(), "WaveSpawner needs at least one lane: %s" % get_path())
	if autostart:
		start_next_wave()


func _physics_process(delta: float) -> void:
	if not _is_spawning():
		return
	_wave_time += delta
	var wave: WaveData = waves[_wave_index]
	for i: int in wave.groups.size():
		var group: SpawnGroup = wave.groups[i]
		# Absolute spawn times, so frame-time leftovers never make later spawns drift.
		while _group_spawned[i] < group.count and _wave_time >= group.spawn_time(_group_spawned[i]):
			_group_spawned[i] += 1
			_spawn_enemy(group)
	_check_wave_cleared()


## 1-based number of the current (or last started) wave; 0 before the first wave.
func get_wave_number() -> int:
	return _wave_index + 1


func get_wave_count() -> int:
	return waves.size()


func has_next_wave() -> bool:
	return _wave_index + 1 < waves.size()


## True from start_wave() until every enemy of that wave is gone.
func is_wave_active() -> bool:
	return _wave_open


func get_spawned_count() -> int:
	return _spawned_count


func get_living_count() -> int:
	return _living_count


## Enemies the current wave sends in total (0 before the first wave).
func get_wave_enemy_total() -> int:
	return waves[_wave_index].get_enemy_total() if _wave_index >= 0 else 0


## Enemies the next wave will send (0 after the last wave).
func get_next_wave_enemy_total() -> int:
	return waves[_wave_index + 1].get_enemy_total() if has_next_wave() else 0


## Enemies of the current wave not yet dealt with: still to spawn, or alive.
func get_remaining_count() -> int:
	return get_wave_enemy_total() - _finished_count if _wave_open else 0


## Starts the next wave. Returns false (and does nothing) while a wave is running or after the last one.
func start_next_wave() -> bool:
	if _wave_open or not has_next_wave():
		return false
	_wave_index += 1
	_wave_time = 0.0
	_group_spawned = PackedInt32Array()
	_group_spawned.resize(waves[_wave_index].groups.size())
	_spawned_count = 0
	_finished_count = 0
	_wave_open = true
	wave_started.emit(get_wave_number())
	enemy_counts_changed.emit(_living_count, _spawned_count)
	_check_wave_cleared()  # a wave without enemies is over at once
	return true


func _is_spawning() -> bool:
	if not _wave_open:
		return false
	return _spawned_count < get_wave_enemy_total()


func _spawn_enemy(group: SpawnGroup) -> void:
	assert(group.enemy != null, "SpawnGroup without an enemy in wave %d" % get_wave_number())
	var lane: Path2D = lanes[clampi(group.lane, 0, lanes.size() - 1)]
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.data = group.enemy
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
	_enemy_gone()
	enemy_killed.emit(enemy)
	enemy_counts_changed.emit(_living_count, _spawned_count)
	_check_wave_cleared()


func _on_enemy_reached_fortress(enemy: Enemy) -> void:
	_enemy_gone()
	enemy_reached_fortress.emit(enemy)
	enemy_counts_changed.emit(_living_count, _spawned_count)
	_check_wave_cleared()


func _enemy_gone() -> void:
	_living_count -= 1
	_finished_count += 1


func _check_wave_cleared() -> void:
	if _wave_open and _living_count == 0 and _spawned_count >= get_wave_enemy_total():
		_wave_open = false
		wave_cleared.emit(get_wave_number())
