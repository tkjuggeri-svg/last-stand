class_name Level
extends Node2D
## Root of a playable level. The run is lost when the fortress is destroyed or the hero loses its last
## life (HeroLives), and won when RunCycle reports the last wave cleared: either way everything in the
## level stops, and run_lost / run_won (once, never both) tells the owner (Main) which screen to show.
## It also places one-shot visuals (an enemy's death effect and the "+gold" it was worth) in its
## Effects layer. A boss's death is a big moment: a brief slow-motion hit-stop and a camera shake.

signal run_lost(reason: LossReason)
signal run_won

enum LossReason { FORTRESS_DESTROYED, HERO_KILLED }

const FLOATING_TEXT_SCENE: PackedScene = preload("res://entities/effects/damage_number.tscn")
const GOLD_TEXT_COLOR: Color = Color(0.95, 0.82, 0.45, 1)
## A boss's death: the game runs at this speed for this many real seconds, and the camera shakes.
const BOSS_HIT_STOP_SCALE: float = 0.25
const BOSS_HIT_STOP_TIME: float = 0.5
const BOSS_SHAKE: float = 8.0
const BOSS_SHAKE_TIME: float = 0.6

@export var fortress: Fortress
@export var spawner: WaveSpawner
@export var hero_lives: HeroLives
@export var run_cycle: RunCycle
@export var modifiers: RunModifiers

var _run_over: bool = false

@onready var _effects: Node2D = %Effects


func _ready() -> void:
	assert(fortress != null, "Level needs a fortress: %s" % get_path())
	fortress.destroyed.connect(_on_fortress_destroyed)
	if hero_lives != null:
		hero_lives.out_of_lives.connect(func() -> void: _end_run(LossReason.HERO_KILLED))
	if run_cycle != null:
		run_cycle.all_waves_cleared.connect(_on_all_waves_cleared)
	if modifiers != null:
		modifiers.upgrade_added.connect(_on_upgrade_added)
	if spawner != null:
		spawner.enemy_killed.connect(_on_enemy_killed)


func _exit_tree() -> void:
	Engine.time_scale = 1.0  # a restart during a hit-stop must not leave the game slowed


func is_run_over() -> bool:
	return _run_over


func _on_fortress_destroyed() -> void:
	_end_run(LossReason.FORTRESS_DESTROYED)


## Upgrades that do something once when picked.
func _on_upgrade_added(data: UpgradeData, _stacks: int) -> void:
	if data.instant_effect == RunModifiers.INSTANT_REPAIR_FORTRESS:
		fortress.repair(data.effect_amount)


func _on_all_waves_cleared() -> void:
	if _stop():
		run_won.emit()


func _end_run(reason: LossReason) -> void:
	if _stop():
		run_lost.emit(reason)


## Freezes the level once; returns false if the run was already over (a loss and a win in the same
## moment: whichever came first counts).
func _stop() -> bool:
	if _run_over:
		return false
	_run_over = true
	# Disabling the level stops every node in it (hero, enemies, spawner) and takes their collision
	# shapes out of physics. Deferred, because this runs inside a physics callback (an enemy hit).
	# Nodes set to PROCESS_MODE_ALWAYS (the hero's sprite) keep animating, so the death plays out.
	set_deferred("process_mode", PROCESS_MODE_DISABLED)
	return true


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
	if enemy.data.is_boss:
		_boss_moment()


func _boss_moment() -> void:
	Engine.time_scale = BOSS_HIT_STOP_SCALE
	get_tree().create_timer(BOSS_HIT_STOP_TIME, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var shake: Tween = camera.create_tween()
	shake.set_ignore_time_scale(true)
	for i: int in 6:
		var strength: float = BOSS_SHAKE * (1.0 - i / 6.0)
		shake.tween_property(camera, "offset", Vector2(strength if i % 2 == 0 else -strength, strength * 0.5).round(), BOSS_SHAKE_TIME / 7.0)
	shake.tween_property(camera, "offset", Vector2.ZERO, BOSS_SHAKE_TIME / 7.0)
