extends Node2D
## Test-only scene script: shows fortress HP and fakes enemy hits with a pulsing enemy_hitbox.

@onready var _fortress: Fortress = %Fortress
@onready var _label: Label = %FortressLabel
@onready var _pulse_shape: CollisionShape2D = %PulseShape
@onready var _pulse_timer: Timer = %PulseTimer


func _ready() -> void:
	_fortress.health.health_changed.connect(_on_health_changed)
	_fortress.destroyed.connect(_on_fortress_destroyed)
	_pulse_timer.timeout.connect(_on_pulse_timer_timeout)
	_on_health_changed(_fortress.health.current_health, _fortress.health.max_health)


func _on_health_changed(current_health: int, max_health: int) -> void:
	_label.text = "Fortress HP: %d / %d" % [current_health, max_health]


func _on_fortress_destroyed() -> void:
	_label.text = "Fortress DESTROYED"
	_pulse_timer.stop()


func _on_pulse_timer_timeout() -> void:
	# Alternate on/off: every "on" is a fresh overlap, i.e. one fake enemy hit.
	_pulse_shape.disabled = not _pulse_shape.disabled
