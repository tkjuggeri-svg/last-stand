class_name RunCycle
extends Node
## The run's rhythm: a build phase before every wave (no enemies; the player starts the wave when
## ready), then that wave's combat phase until its last enemy is dead or has reached the fortress,
## then (except after the last wave) an upgrade choice (CHOOSE: UpgradeOffers makes an offer and the
## choice screen pauses the game until one card is taken) before the next build phase.
## After the last wave the run is FINISHED (all_waves_cleared). Building and selling are allowed in
## the build and combat phases; this node only decides when a wave may start.
## On a run map (choose_between_waves off) a fight's waves follow each other without upgrade choices
## (the fight's reward comes after it), and restart() begins the next fight's build phase. There the
## next wave can also be called early, once the running one has sent all its enemies (M8: bonus gold,
## WaveRewards); not between choices, since that would skip one.

signal phase_changed(phase: Phase)
## The last wave has been cleared.
signal all_waves_cleared

enum Phase { BUILD, COMBAT, CHOOSE, FINISHED }

@export var spawner: WaveSpawner
## Optional: without it (or with nothing left to offer) a cleared wave goes straight to BUILD.
@export var offers: UpgradeOffers
## Offer an upgrade after every cleared wave (off on the run map: one choice per fight).
@export var choose_between_waves: bool = true

## Seconds left of a Hasty Waves countdown when the warning tick sounds (once per build phase).
@export var hasty_warning_seconds: float = 10.0

## Seconds of a build phase after which the wave starts by itself (Pressure's Hasty Waves; 0 = never).
var hasty_seconds: float = 0.0

var _phase: Phase = Phase.BUILD
var _build_left: float = 0.0
var _warned: bool = false


func _ready() -> void:
	assert(spawner != null, "RunCycle needs a WaveSpawner: %s" % get_path())
	# Listening to wave_started (not only our own start_wave) also covers a spawner that autostarts.
	spawner.wave_started.connect(_on_wave_started)
	spawner.wave_cleared.connect(_on_wave_cleared)
	if offers != null:
		offers.picked.connect(_on_upgrade_picked)
	_build_left = hasty_seconds
	_warned = false
	if spawner.is_wave_active():
		_phase = Phase.COMBAT


func _physics_process(delta: float) -> void:
	if hasty_seconds <= 0.0 or _phase != Phase.BUILD or not spawner.has_next_wave():
		return
	_build_left -= delta
	if _build_left <= hasty_warning_seconds and not _warned:
		_warned = true
		Sfx.play(self, &"hasty_warning")
	if _build_left <= 0.0:
		start_wave()


## Seconds until the next wave starts by itself, or -1 when it waits for the player.
func get_hasty_left() -> float:
	if hasty_seconds <= 0.0 or _phase != Phase.BUILD or not spawner.has_next_wave():
		return -1.0
	return maxf(_build_left, 0.0)


func get_phase() -> Phase:
	return _phase


## The wave being fought, or (in the build and choose phases) the wave being prepared for. 1-based.
func get_current_wave_number() -> int:
	if _phase == Phase.BUILD or _phase == Phase.CHOOSE:
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


## True in combat on a run map once the wave has sent everyone and another follows.
func can_call_early() -> bool:
	return _phase == Phase.COMBAT and not choose_between_waves and spawner.can_call_next_wave()


## Calls the next wave now, the current one's last enemies still fighting. False if it can't be.
func call_early() -> bool:
	return can_call_early() and spawner.call_next_wave()


## Back to the build phase for the spawner's freshly loaded waves (after FINISHED, a new fight).
func restart() -> void:
	_build_left = hasty_seconds
	_warned = false
	_set_phase(Phase.BUILD)


func _on_wave_started(_wave_number: int) -> void:
	_set_phase(Phase.COMBAT)


func _on_wave_cleared(_wave_number: int) -> void:
	if spawner.has_next_wave():
		if choose_between_waves and offers != null and offers.has_cards():
			_set_phase(Phase.CHOOSE)
			offers.make_offer()
		else:
			_set_phase(Phase.BUILD)
		return
	_set_phase(Phase.FINISHED)
	all_waves_cleared.emit()


func _on_upgrade_picked(_data: UpgradeData) -> void:
	if _phase == Phase.CHOOSE:
		_set_phase(Phase.BUILD)


func _set_phase(phase: Phase) -> void:
	if phase == _phase:
		return
	_phase = phase
	_build_left = hasty_seconds
	_warned = false
	phase_changed.emit(phase)
