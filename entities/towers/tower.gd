class_name Tower
extends StaticBody2D
## A built tower. One scene for every tower type: its TowerData decides the look and the stats.
## It targets the living enemy in range that is furthest along the lane (closest to the fortress),
## keeps that target while it stays valid and in range, and fires a volley every fire_interval (one
## shot, or one per target for multi-target levels: the next leading enemies in range).
## "In range" means the enemy's centre is within the range of the tower's base (the range area is
## only the broad phase: it reports bodies that merely touch the circle).
## The base stands at the node's origin (the build slot's centre); a small body blocks the hero.
## After placing it is under construction for data.build_time seconds (shown by its "<id>_build"
## animation, stretched to that time): it tracks enemies entering its range but can't target or fire.
## Levels: it starts at 1; TowerBuilder upgrades it (set_level) and the stats come from
## data.stats_for(level). deactivate() (called when it is sold) stops it for good.

signal construction_finished

const PROJECTILE_SCENE: PackedScene = preload("res://entities/towers/projectile.tscn")
## Upgrade feedback (display only): a bright flash that fades over this many seconds.
const UPGRADE_FLASH_TIME: float = 0.35

@export var data: TowerData

## Gold put into this tower so far (build + upgrades); selling refunds a share of it.
var invested: int = 0

var _level: int = 1
var _stats: TowerTier
var _build_left: float = 0.0
var _active: bool = true
var _target: Enemy = null
var _cooldown_left: float = 0.0
## Enemy bodies currently inside the range area (may contain freed ones until pruned).
var _in_range: Array[Node2D] = []

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _range_area: Area2D = %RangeArea
@onready var _glow: PointLight2D = %Glow
@onready var _range_shape: CollisionShape2D = %RangeShape


func _ready() -> void:
	if data == null:
		# Opened on its own (no TowerBuilder gave it data): just stand there.
		_sprite.play(&"archer_idle")
		_active = false
		set_physics_process(false)
		return
	_stats = data.stats_for(_level)
	_apply_range()
	_glow.enabled = data.glow_color.a > 0.0
	_glow.color = data.glow_color
	_glow.position = data.muzzle_offset
	_range_area.body_entered.connect(_on_range_body_entered)
	_range_area.body_exited.connect(_on_range_body_exited)
	_sprite.animation_finished.connect(_on_sprite_animation_finished)
	_build_left = data.build_time
	var build: StringName = StringName("%s_build" % data.id)
	if _build_left > 0.0 and _sprite.sprite_frames.has_animation(build):
		var length: float = _sprite.sprite_frames.get_frame_count(build) / _sprite.sprite_frames.get_animation_speed(build)
		_sprite.play(build, length / _build_left)
	else:
		_sprite.play(_anim("idle"))


func _physics_process(delta: float) -> void:
	if _build_left > 0.0:
		_build_left -= delta
		if _build_left > 0.0:
			return
		_build_left = 0.0
		construction_finished.emit()
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


## True while under construction (can't target or fire yet).
func is_building() -> bool:
	return _build_left > 0.0


## False once the tower has been sold (or opened without data).
func is_active() -> bool:
	return _active


## Stops the tower for good: no more targeting or shots. Called when it is sold, before it is removed.
func deactivate() -> void:
	_active = false
	_target = null
	_in_range.clear()
	set_physics_process(false)
	_range_area.set_deferred(&"monitoring", false)


func get_level() -> int:
	return _level


func is_max_level() -> bool:
	return data == null or _level >= data.max_level()


## The stats at the current level.
func get_stats() -> TowerTier:
	return _stats if _stats != null else data.stats_for(_level)


## Switches to `level` (TowerBuilder does the paying): new stats, range and look, with a flash.
func set_level(level: int) -> void:
	_level = clampi(level, 1, data.max_level())
	_stats = data.stats_for(_level)
	_apply_range()
	if not is_building():
		_sprite.play(_anim("idle"))
	_sprite.modulate = Color(2.2, 2.2, 2.2, 1.0)  # overbright, then back to normal
	_sprite.create_tween().tween_property(_sprite, "modulate", Color.WHITE, UPGRADE_FLASH_TIME)


## The current attack range in px (what the range ring shows).
func get_attack_range() -> float:
	return get_stats().attack_range if data != null else 0.0


## True if `point` is within attack range of the tower's base.
func is_in_range(point: Vector2) -> bool:
	return global_position.distance_to(point) <= get_attack_range()


## Where a shell fired now must land to meet `enemy`, if it keeps its current velocity (simple lead:
## the flight time is measured along the ground from the tower's base). Never beyond the range.
func aim_point(enemy: Enemy) -> Vector2:
	var aim: Vector2 = enemy.global_position
	for _i: int in 2:
		var flight: float = global_position.distance_to(aim) / data.projectile_speed
		aim = enemy.global_position + enemy.velocity * flight
	return global_position + (aim - global_position).limit_length(get_attack_range())


## "<id>_<state>" for level 1, "<id>_<state>_<level>" above (falls back to level 1 art if missing).
func _anim(state: String) -> StringName:
	var name_at_level: StringName = StringName("%s_%s_%d" % [data.id, state, _level])
	if _level > 1 and _sprite.sprite_frames.has_animation(name_at_level):
		return name_at_level
	return StringName("%s_%s" % [data.id, state])


func _apply_range() -> void:
	(_range_shape.shape as CircleShape2D).radius = get_attack_range()


## Untyped on purpose: the stored target may already be freed, and a freed object can't be passed
## as an Enemy. is_instance_valid() is checked before anything else touches it.
func _is_valid_target(candidate: Variant) -> bool:
	if not is_instance_valid(candidate):
		return false
	var enemy: Enemy = candidate as Enemy
	return enemy != null and enemy.is_alive() and _in_range.has(enemy) and is_in_range(enemy.global_position)


## Living enemies in range, the furthest along the lane first.
func _targets_in_range() -> Array[Enemy]:
	var found: Array[Enemy] = []
	for i: int in range(_in_range.size() - 1, -1, -1):
		var body: Node2D = _in_range[i]
		if not is_instance_valid(body):
			_in_range.remove_at(i)
			continue
		var enemy: Enemy = body as Enemy
		if enemy != null and enemy.is_alive() and is_in_range(enemy.global_position):
			found.append(enemy)
	found.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.get_lane_progress() > b.get_lane_progress())
	return found


func _pick_target() -> Enemy:
	var found: Array[Enemy] = _targets_in_range()
	return found[0] if not found.is_empty() else null


## One shot at the target, plus one at each next leading enemy for multi-target levels.
func _fire() -> void:
	var stats: TowerTier = get_stats()
	_cooldown_left = stats.fire_interval
	var targets: Array[Enemy] = [_target]
	if stats.targets > 1:
		for enemy: Enemy in _targets_in_range():
			if targets.size() >= stats.targets:
				break
			if enemy != _target:
				targets.append(enemy)
	for enemy: Enemy in targets:
		var shot: Projectile = PROJECTILE_SCENE.instantiate()
		if data.homing:
			shot.launch(data, stats, enemy, global_position + data.muzzle_offset, global_position)
		else:
			shot.launch_at_point(data, stats, aim_point(enemy), global_position, data.muzzle_offset)
		add_child(shot)
	_sprite.play(_anim("fire"))


func _on_range_body_entered(body: Node2D) -> void:
	if _active and body is Enemy and not _in_range.has(body):
		_in_range.append(body)


func _on_range_body_exited(body: Node2D) -> void:
	_in_range.erase(body)


func _on_sprite_animation_finished() -> void:
	_sprite.play(_anim("idle"))
