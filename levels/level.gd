class_name Level
extends Node2D
## Root of a playable level. The run is lost when the fortress is destroyed or the hero dies:
## everything in the level stops, and run_lost (once) tells the owner (Main) to show Game Over.
## It also places one-shot visuals (e.g. an enemy's death effect) in its Effects layer.

signal run_lost(reason: LossReason)

enum LossReason { FORTRESS_DESTROYED, HERO_KILLED }

@export var fortress: Fortress
@export var hero: Hero
@export var spawner: EnemySpawner

var _run_over: bool = false

@onready var _effects: Node2D = %Effects


func _ready() -> void:
	assert(fortress != null, "Level needs a fortress: %s" % get_path())
	fortress.destroyed.connect(_on_fortress_destroyed)
	if hero != null:
		hero.died.connect(_on_hero_died)
	if spawner != null:
		spawner.enemy_killed.connect(_on_enemy_killed)


func is_run_over() -> bool:
	return _run_over


func _on_fortress_destroyed() -> void:
	_end_run(LossReason.FORTRESS_DESTROYED)


func _on_hero_died() -> void:
	_end_run(LossReason.HERO_KILLED)


func _end_run(reason: LossReason) -> void:
	if _run_over:
		return
	_run_over = true
	# Disabling the level stops every node in it (hero, enemies, spawner) and takes their collision
	# shapes out of physics. Deferred, because this runs inside a physics callback (an enemy hit).
	# Nodes set to PROCESS_MODE_ALWAYS (the hero's sprite) keep animating, so the death plays out.
	set_deferred("process_mode", PROCESS_MODE_DISABLED)
	run_lost.emit(reason)


func _on_enemy_killed(enemy: Enemy) -> void:
	if enemy.data.death_effect == null:
		return
	var effect: Node2D = enemy.data.death_effect.instantiate()
	effect.position = _effects.to_local(enemy.global_position)
	_effects.add_child(effect)
