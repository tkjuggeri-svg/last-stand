class_name Tower
extends StaticBody2D
## A built tower. One scene for every tower type: its TowerData decides the look and the stats.
## It targets the living enemy in range that is furthest along the lane (closest to the fortress),
## keeps that target while it stays valid and in range, and fires a Projectile every fire_interval.
## The base stands at the node's origin (the build slot's centre); a small body blocks the hero.

const PROJECTILE_SCENE: PackedScene = preload("res://entities/towers/projectile.tscn")

@export var data: TowerData

var _target: Enemy = null
var _cooldown_left: float = 0.0
## Enemy bodies currently inside the range area (may contain freed ones until pruned).
var _in_range: Array[Node2D] = []

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _range_area: Area2D = %RangeArea
@onready var _range_shape: CollisionShape2D = %RangeShape


func _ready() -> void:
	if data == null:
		# Opened on its own (no TowerBuilder gave it data): just stand there.
		_sprite.play(&"archer_idle")
		set_physics_process(false)
		return
	(_range_shape.shape as CircleShape2D).radius = data.attack_range
	_range_area.body_entered.connect(_on_range_body_entered)
	_range_area.body_exited.connect(_on_range_body_exited)
	_sprite.animation_finished.connect(_on_sprite_animation_finished)
	_sprite.play(StringName("%s_idle" % data.id))


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if not _is_valid_target(_target):
		_target = _pick_target()  # also forgets a target that died, left range or reached the fortress
	if _target != null and _cooldown_left <= 0.0:
		_fire()


## The enemy currently aimed at, or null.
func get_target() -> Enemy:
	if not _is_valid_target(_target):
		return null
	return _target


## Untyped on purpose: the stored target may already be freed, and a freed object can't be passed
## as an Enemy. is_instance_valid() is checked before anything else touches it.
func _is_valid_target(candidate: Variant) -> bool:
	if not is_instance_valid(candidate):
		return false
	var enemy: Enemy = candidate as Enemy
	return enemy != null and enemy.is_alive() and _in_range.has(enemy)


func _pick_target() -> Enemy:
	var best: Enemy = null
	var best_progress: float = -INF
	for i: int in range(_in_range.size() - 1, -1, -1):
		var body: Node2D = _in_range[i]
		if not is_instance_valid(body):
			_in_range.remove_at(i)
			continue
		var enemy: Enemy = body as Enemy
		if enemy == null or not enemy.is_alive():
			continue
		var progress: float = enemy.get_lane_progress()
		if progress > best_progress:
			best_progress = progress
			best = enemy
	return best


func _fire() -> void:
	_cooldown_left = data.fire_interval
	var shot: Projectile = PROJECTILE_SCENE.instantiate()
	shot.launch(data, _target, global_position + data.muzzle_offset)
	add_child(shot)
	_sprite.play(StringName("%s_fire" % data.id))


func _on_range_body_entered(body: Node2D) -> void:
	if body is Enemy and not _in_range.has(body):
		_in_range.append(body)


func _on_range_body_exited(body: Node2D) -> void:
	_in_range.erase(body)


func _on_sprite_animation_finished() -> void:
	_sprite.play(StringName("%s_idle" % data.id))
