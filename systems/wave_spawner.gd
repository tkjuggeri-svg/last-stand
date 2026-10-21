class_name WaveSpawner
extends Node2D
## Spawns the enemies of one WaveData at a time, each group on its own lane. Spawned enemies become
## children of this node and take their EnemyData from the group. A wave runs from start_wave() until
## every enemy it sends has been spawned and is gone again (killed or used up at the fortress):
## wave_started .. wave_cleared. Starting waves is up to the owner (or autostart for the first one).
## Enemies a boss summons join the current wave (they count in its totals) on the summoner's lane.
## Once a wave has sent everyone, the next can be called early (call_next_wave): the wave counts as
## cleared at once and its enemies still alive stay, counted in the next wave's remaining enemies.

signal wave_started(wave_number: int)
## Every enemy of the wave has been spawned and is gone again (or the next wave was called early).
signal wave_cleared(wave_number: int)
## The next wave was called while `living` (this wave's last enemies) still fight; wave_cleared follows.
signal wave_called_early(wave_number: int, living: Array[Enemy])
signal enemy_spawned(enemy: Enemy)
## A spawned enemy was killed (not when it is used up at the fortress).
signal enemy_killed(enemy: Enemy)
## A spawned enemy reached the fortress and was used up.
signal enemy_reached_fortress(enemy: Enemy)
## The number of living enemies or the number spawned in this wave changed.
signal enemy_counts_changed(living_count: int, spawned_count: int)

## How long a wave's spawn ward (WaveData.spawn_shield) lasts: the whole fight.
const SPAWN_SHIELD_TIME: float = 600.0

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
## Enemies summoned during the current wave (on top of the wave's own).
var _summoned_count: int = 0


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


## Enemies the current wave sends in total, summoned ones included (0 before the first wave).
func get_wave_enemy_total() -> int:
	return waves[_wave_index].get_enemy_total() + _summoned_count if _wave_index >= 0 else 0


## Enemies the next wave will send (0 after the last wave).
func get_next_wave_enemy_total() -> int:
	return waves[_wave_index + 1].get_enemy_total() if has_next_wave() else 0


## Enemies of the current wave not yet dealt with: still to spawn, or alive.
func get_remaining_count() -> int:
	return get_wave_enemy_total() - _finished_count if _wave_open else 0


## Replaces the waves with `new_waves` and starts over from the first (a run map's next fight on the same
## level). Returns false (and changes nothing) while a wave is running.
func load_waves(new_waves: Array[WaveData]) -> bool:
	if _wave_open:
		return false
	waves = new_waves
	_wave_index = -1
	_spawned_count = 0
	_finished_count = 0
	_summoned_count = 0
	enemy_counts_changed.emit(_living_count, _spawned_count)
	return true


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
	_summoned_count = 0
	_wave_open = true
	wave_started.emit(get_wave_number())
	enemy_counts_changed.emit(_living_count, _spawned_count)
	_check_wave_cleared()  # a wave without enemies is over at once
	return true


## True while a wave runs that has sent all its enemies, and another wave follows it.
func can_call_next_wave() -> bool:
	return _wave_open and not _is_spawning() and has_next_wave()


## The current wave's enemies still alive.
func get_living_enemies() -> Array[Enemy]:
	var living: Array[Enemy] = []
	for child: Node in get_children():
		var enemy: Enemy = child as Enemy
		if enemy != null and enemy.is_alive() and not enemy.is_queued_for_deletion():
			living.append(enemy)
	return living


## Starts the next wave now, while this one's last enemies still live (call early): this wave counts
## as cleared, and its living enemies count in the next one's remaining. False if it can't be called.
func call_next_wave() -> bool:
	if not can_call_next_wave():
		return false
	var carried: int = _living_count
	wave_called_early.emit(get_wave_number(), get_living_enemies())
	_wave_open = false
	wave_cleared.emit(get_wave_number())
	start_next_wave()
	_finished_count = -carried  # so get_remaining_count() still counts them
	enemy_counts_changed.emit(_living_count, _spawned_count)
	return true


## Ends the current wave at once (the dev menu): the rest of its enemies never come, the living ones
## vanish without paying gold, and the wave counts as cleared.
func end_wave() -> void:
	if not _wave_open:
		return
	var wave: WaveData = waves[_wave_index]
	for i: int in wave.groups.size():
		_group_spawned[i] = wave.groups[i].count
	_spawned_count = get_wave_enemy_total()
	for child: Node in get_children():
		var enemy: Enemy = child as Enemy
		if enemy != null and enemy.is_alive():
			enemy.died.disconnect(_on_enemy_died)
			enemy.reached_fortress.disconnect(_on_enemy_reached_fortress)
			enemy.queue_free()
			_enemy_gone()
	enemy_counts_changed.emit(_living_count, _spawned_count)
	_check_wave_cleared()


## Sends one more `data` down lane `lane_index` now (the dev menu): it joins the current wave (with the
## wave's scales) if one is running, else it comes on its own (base stats, not counted).
func spawn_extra(data: EnemyData, lane_index: int) -> Enemy:
	var lane: Path2D = lanes[clampi(lane_index, 0, lanes.size() - 1)]
	var at: Vector2 = lane.to_global(lane.curve.sample_baked(0.0))
	if _wave_open:
		_summoned_count += 1
		return _add_enemy(data, lane, at)
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.data = data
	enemy.lane = lane
	add_child(enemy)
	enemy.global_position = at
	return enemy


func _is_spawning() -> bool:
	if not _wave_open:
		return false
	return _spawned_count < get_wave_enemy_total()


func _spawn_enemy(group: SpawnGroup) -> void:
	assert(group.enemy != null, "SpawnGroup without an enemy in wave %d" % get_wave_number())
	var lane: Path2D = lanes[clampi(group.lane, 0, lanes.size() - 1)]
	_add_enemy(group.enemy, lane, lane.to_global(lane.curve.sample_baked(0.0)), group.health_scale)


## A boss calls up a minion: it joins this wave at `at`, on the boss's lane.
func _on_summon_requested(summoner: Enemy, minion: EnemyData, at: Vector2) -> void:
	if not _wave_open:
		return
	# Counted now, so the wave waits for it; added at the end of the frame, because a summon can come
	# from a death inside a physics callback (a Bloater killed by a hit), where no body may be added.
	_summoned_count += 1
	_add_summon.call_deferred(weakref(summoner), minion, summoner.lane, at)


## A summon's minion, now that bodies may be added (the summoner may be gone by then: a Bloater).
func _add_summon(summoner_ref: WeakRef, minion: EnemyData, lane: Path2D, at: Vector2) -> void:
	var minion_enemy: Enemy = _add_enemy(minion, lane, at)
	var summoner: Enemy = summoner_ref.get_ref() as Enemy
	if summoner != null:
		summoner.adopt_minion(minion_enemy)


func _add_enemy(data: EnemyData, lane: Path2D, at: Vector2, health_scale: float = 1.0) -> Enemy:
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.data = data
	enemy.lane = lane
	# A boss's HP, gold and speed are authored directly: the wave's scales don't apply.
	enemy.health_multiplier = (1.0 if data.is_boss else waves[_wave_index].health_multiplier) * health_scale
	enemy.gold_multiplier = 1.0 if data.is_boss else waves[_wave_index].gold_multiplier
	enemy.speed_multiplier = 1.0 if data.is_boss else waves[_wave_index].speed_multiplier
	enemy.died.connect(_on_enemy_died)
	enemy.reached_fortress.connect(_on_enemy_reached_fortress)
	enemy.summon_requested.connect(_on_summon_requested)
	add_child(enemy)
	enemy.global_position = at
	if waves[_wave_index].spawn_shield > 0:
		enemy.add_shield(waves[_wave_index].spawn_shield, SPAWN_SHIELD_TIME)
	_spawned_count += 1
	_living_count += 1
	enemy_spawned.emit(enemy)
	enemy_counts_changed.emit(_living_count, _spawned_count)
	return enemy


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
