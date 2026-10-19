class_name RunCycle
extends Node
## The run's rhythm: a build phase before every wave (no enemies; the player starts the wave when
## ready), then that wave's combat phase until its last enemy is dead or has reached the fortress.
## After the last wave the run is FINISHED (all_waves_cleared). Building and selling are allowed in
## every phase; this node only decides when a wave may start.

signal phase_changed(phase: Phase)
## The last wave has been cleared.
signal all_waves_cleared

enum Phase { BUILD, COMBAT, FINISHED }

@export var spawner: WaveSpawner

var _phase: Phase = Phase.BUILD


func _ready() -> void:
	assert(spawner != null, "RunCycle needs a WaveSpawner: %s" % get_path())
	# Listening to wave_started (not only our own start_wave) also covers a spawner that autostarts.
	spawner.wave_started.connect(_on_wave_started)
	spawner.wave_cleared.connect(_on_wave_cleared)
	if spawner.is_wave_active():
		_phase = Phase.COMBAT


func get_phase() -> Phase:
	return _phase


## The wave being fought, or (in the build phase) the wave being prepared for. 1-based.
func get_current_wave_number() -> int:
	if _phase == Phase.BUILD:
		return spawner.get_wave_number() + 1
	return spawner.get_wave_number()


func get_wave_count() -> int:
	return spawner.get_wave_count()


func can_start_wave() -> bool:
	return _phase == Phase.BUILD and spawner.has_next_wave()


## Ends the build phase and starts the next wave. Returns false outside the build phase.
func start_wave() -> bool:
	if not can_start_wave():
		return false
	return spawner.start_next_wave()


func _on_wave_started(_wave_number: int) -> void:
	_set_phase(Phase.COMBAT)


func _on_wave_cleared(_wave_number: int) -> void:
	if spawner.has_next_wave():
		_set_phase(Phase.BUILD)
		return
	_set_phase(Phase.FINISHED)
	all_waves_cleared.emit()


func _set_phase(phase: Phase) -> void:
	if phase == _phase:
		return
	_phase = phase
	phase_changed.emit(phase)
