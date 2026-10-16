class_name Level
extends Node2D
## Root of a playable level. When the fortress is destroyed the run is lost: everything in the
## level stops, and run_lost tells the owner (Main) to show Game Over.

signal run_lost

@export var fortress: Fortress

var _run_over: bool = false


func _ready() -> void:
	assert(fortress != null, "Level needs a fortress: %s" % get_path())
	fortress.destroyed.connect(_on_fortress_destroyed)


func is_run_over() -> bool:
	return _run_over


func _on_fortress_destroyed() -> void:
	if _run_over:
		return
	_run_over = true
	# Disabling the level stops every node in it (hero, enemies, spawner) and takes their collision
	# shapes out of physics. Deferred, because this runs inside a physics callback (an enemy hit).
	set_deferred("process_mode", PROCESS_MODE_DISABLED)
	run_lost.emit()
