class_name EnemyAbility
extends Node2D
## An enemy's special mechanic, a boss's or a chapter-2 regular's (a component the Enemy creates from
## EnemyData.ability; its tunables are exported on the ability scene). It runs in its own physics
## step beside the enemy and may take the enemy over for a while (is_busy: no walking, no attacks of
## its own), to telegraph and then act.
## Every attack is announced first (`telegraphed`, with a ground TelegraphMarker), then happens (`used`).

## An attack is announced; it happens in `seconds`.
signal telegraphed(seconds: float)
## The attack happened.
signal used

const ACT_SHAKE_TIME: float = 0.35

## Seconds before the first use (after the boss appears) and between two uses.
@export var first_delay: float = 4.0
@export var interval: float = 8.0
## How long the telegraph lasts before the attack happens.
@export var telegraph_time: float = 1.2
## Sounds (Sfx ids, M8.5; empty: none): when the attack is announced, and when it happens.
@export var telegraph_sound: StringName = &""
@export var act_sound: StringName = &""
## The attack shakes the screen this much (px; 0: not at all), for ACT_SHAKE_TIME.
@export var act_shake: float = 0.0

var enemy: Enemy

var _cooldown_left: float = 0.0
var _telegraph_left: float = -1.0


## Called by the enemy before it adds this to the tree.
func setup(owner_enemy: Enemy) -> void:
	enemy = owner_enemy
	_cooldown_left = first_delay


func _ready() -> void:
	# Opened on its own (no enemy gave it a body): nothing to do.
	set_physics_process(enemy != null)


func _physics_process(delta: float) -> void:
	if not enemy.is_alive():
		return
	if _telegraph_left >= 0.0:
		_telegraph_left -= delta
		_telegraph_step(1.0 - maxf(_telegraph_left, 0.0) / telegraph_time)
		if _telegraph_left < 0.0:
			_act()
			_sound(act_sound)
			if act_shake > 0.0:
				Juice.shake(enemy, act_shake, ACT_SHAKE_TIME)
			used.emit()
		return
	_ability_step(delta)
	_cooldown_left -= delta
	if _cooldown_left <= 0.0 and not enemy.is_attacking() and _can_start():
		_cooldown_left = interval
		_telegraph_left = telegraph_time
		_begin_telegraph()
		_sound(telegraph_sound)
		telegraphed.emit(telegraph_time)


## True while telegraphing (and whatever a subclass adds, e.g. charging, stunned).
func is_busy() -> bool:
	return _telegraph_left >= 0.0


func is_telegraphing() -> bool:
	return _telegraph_left >= 0.0


# Subclass hooks.

## Extra conditions to start (e.g. the hero is close enough).
func _can_start() -> bool:
	return true


func _begin_telegraph() -> void:
	pass


## Every physics frame of the telegraph (progress 0 -> 1).
func _telegraph_step(_progress: float) -> void:
	pass


## The attack itself, when the telegraph ends.
func _act() -> void:
	pass


## Every physics frame outside the telegraph (e.g. a charge in progress).
func _ability_step(_delta: float) -> void:
	pass


## The owner was just killed (called before it reports its death to the wave), e.g. to burst.
func on_owner_died() -> void:
	pass


## A marker on the ground at `at` (world), kept until freed.
func _marker(marker_shape: TelegraphMarker.Shape, at: Vector2, color: Color, size: float) -> TelegraphMarker:
	var marker: TelegraphMarker = TelegraphMarker.new()
	marker.shape = marker_shape
	marker.color = color
	marker.size = size
	add_child(marker)
	marker.global_position = at
	return marker


## Plays the boss's "<state>_<facing>" animation if its art has one.
func _play(state: String) -> void:
	var sprite: DirectionalSprite = enemy.get_sprite()
	if sprite.sprite_frames.has_animation(StringName("%s_%s" % [state, sprite.facing])):
		sprite.play_state(state, true)


func _sound(id: StringName) -> void:
	if id != &"":
		Sfx.play(enemy, id)
