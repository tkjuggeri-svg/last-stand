class_name Level
extends Node2D
## Root of a playable level. The run is lost when the fortress is destroyed or the hero loses its last
## life (HeroLives): everything in the level stops, and run_lost (once) tells the owner (Main) to show
## Game Over.
## It also places one-shot visuals (an enemy's death effect and the "+gold" it was worth) in its
## Effects layer.

signal run_lost(reason: LossReason)

enum LossReason { FORTRESS_DESTROYED, HERO_KILLED }

const FLOATING_TEXT_SCENE: PackedScene = preload("res://entities/effects/damage_number.tscn")
const GOLD_TEXT_COLOR: Color = Color(0.95, 0.82, 0.45, 1)

@export var fortress: Fortress
@export var spawner: WaveSpawner
@export var hero_lives: HeroLives

var _run_over: bool = false

@onready var _effects: Node2D = %Effects


func _ready() -> void:
	assert(fortress != null, "Level needs a fortress: %s" % get_path())
	fortress.destroyed.connect(_on_fortress_destroyed)
	if hero_lives != null:
		hero_lives.out_of_lives.connect(func() -> void: _end_run(LossReason.HERO_KILLED))
	if spawner != null:
		spawner.enemy_killed.connect(_on_enemy_killed)


func is_run_over() -> bool:
	return _run_over


func _on_fortress_destroyed() -> void:
	_end_run(LossReason.FORTRESS_DESTROYED)


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
	var at: Vector2 = _effects.to_local(enemy.global_position)
	if enemy.data.death_effect != null:
		var effect: Node2D = enemy.data.death_effect.instantiate()
		effect.position = at
		_effects.add_child(effect)
	if enemy.data.gold_reward > 0:
		var gold_text: DamageNumber = FLOATING_TEXT_SCENE.instantiate()
		gold_text.set_text("+%d" % enemy.data.gold_reward, GOLD_TEXT_COLOR)
		gold_text.position = at + Vector2(0, -30)
		_effects.add_child(gold_text)
