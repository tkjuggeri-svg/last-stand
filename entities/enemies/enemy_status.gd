class_name EnemyStatus
extends Node
## What towers do to an enemy besides damage (a component of Enemy, which asks it each physics
## frame): slows (the strongest factor wins, the longest time is kept), freezes (no moving, no
## attacking: Glacier Spire), vulnerability (more damage taken while it lasts: Shatter Shrine) and
## being dragged back along the lane (Harpoon) and burning (ignite(): fire never stacks on one enemy,
## the strongest burn counts and a new one refreshes its time; tough enemies take a share of it,
## EnemyData.burn_taken). Everything wears off. The enemy shows each through its EnemyLook
## (status_changed).

signal status_changed

## How fast a dragged enemy is pulled back along its lane, px/s.
const DRAG_SPEED: float = 420.0
## Burn damage lands in ticks this many seconds apart.
const BURN_TICK: float = 0.25

## Current speed multiplier from slows (1 = normal) and how long it still lasts.
var _slow_factor: float = 1.0
var _slow_left: float = 0.0
var _freeze_left: float = 0.0
var _vulnerable_left: float = 0.0
var _vulnerability: float = 0.0
## Lane offset the enemy is being dragged back to (-1 = not dragged).
var _drag_to: float = -1.0
## The burn on it (damage per second before burn_taken) and how long it still lasts.
var _burn_dps: float = 0.0
var _burn_left: float = 0.0
var _burn_tick_left: float = 0.0
## Burn damage owed but not dealt yet (ticks deal whole points).
var _burn_pending: float = 0.0
## Share of burn damage it takes (EnemyData.burn_taken).
var _burn_taken: float = 1.0
var _health: HealthComponent


func setup(health: HealthComponent, burn_taken: float = 1.0) -> void:
	_health = health
	_burn_taken = burn_taken


## Counts every effect down (call once per physics frame).
func tick(delta: float) -> void:
	var was: Array[bool] = [is_slowed(), is_frozen(), is_vulnerable(), is_burning()]
	_tick_burn(delta)
	_slow_left = maxf(_slow_left - delta, 0.0)
	if _slow_left <= 0.0:
		_slow_factor = 1.0
	_freeze_left = maxf(_freeze_left - delta, 0.0)
	_vulnerable_left = maxf(_vulnerable_left - delta, 0.0)
	if _vulnerable_left <= 0.0 and _vulnerability > 0.0:
		_vulnerability = 0.0
		_health.damage_taken_multiplier = 1.0
	if was != [is_slowed(), is_frozen(), is_vulnerable(), is_burning()]:
		status_changed.emit()


## Sets it on fire: `dps` damage per second (times burn_taken) for `duration` seconds. Burns never
## stack: a weaker one changes nothing while a stronger one burns; an equal or stronger one takes
## over and keeps the longer time.
func ignite(dps: float, duration: float) -> void:
	if dps <= 0.0 or duration <= 0.0:
		return
	if is_burning() and dps < _burn_dps:
		return
	var started: bool = not is_burning()
	_burn_left = maxf(_burn_left, duration) if is_burning() else duration
	_burn_dps = dps
	if started:
		_burn_tick_left = BURN_TICK
		status_changed.emit()


func is_burning() -> bool:
	return _burn_left > 0.0


## Damage per second it takes from its burn now (0 when not burning).
func get_burn_dps() -> float:
	return _burn_dps * _burn_taken if is_burning() else 0.0


func _tick_burn(delta: float) -> void:
	if not is_burning():
		return
	var step: float = minf(delta, _burn_left)
	_burn_left -= delta
	_burn_pending += _burn_dps * _burn_taken * step
	_burn_tick_left -= delta
	if _burn_tick_left > 0.0 and is_burning():
		return
	_burn_tick_left += BURN_TICK
	var damage: int = floori(_burn_pending)
	if damage > 0:
		_burn_pending -= damage
		_health.take_damage(damage)
	if not is_burning():
		_burn_dps = 0.0
		_burn_pending = 0.0


## Slows movement to `factor` of normal speed for `duration` seconds (never stacking).
func apply_slow(factor: float, duration: float) -> void:
	if duration <= 0.0 or factor >= 1.0:
		return
	_slow_factor = minf(_slow_factor, factor) if is_slowed() else factor
	_slow_left = maxf(_slow_left, duration)
	status_changed.emit()


func is_slowed() -> bool:
	return _slow_left > 0.0


func get_slow_factor() -> float:
	return _slow_factor


## Frozen in place for `seconds`: it neither moves nor attacks (the longest freeze is kept).
func freeze(seconds: float) -> void:
	if seconds <= 0.0:
		return
	_freeze_left = maxf(_freeze_left, seconds)
	status_changed.emit()


func is_frozen() -> bool:
	return _freeze_left > 0.0


## Takes `bonus` more damage (0.25 = +25%) for `seconds`; several sources don't stack (the biggest
## bonus counts).
func mark_vulnerable(bonus: float, seconds: float) -> void:
	if bonus <= 0.0 or seconds <= 0.0:
		return
	_vulnerability = maxf(_vulnerability, bonus) if is_vulnerable() else bonus
	_vulnerable_left = maxf(_vulnerable_left, seconds)
	_health.damage_taken_multiplier = 1.0 + _vulnerability
	status_changed.emit()


func is_vulnerable() -> bool:
	return _vulnerable_left > 0.0


## Starts dragging it back to lane offset `offset` (never below 0; a new drag replaces the old).
func drag_to(offset: float) -> void:
	_drag_to = maxf(offset, 0.0)


func is_dragged() -> bool:
	return _drag_to >= 0.0


## This frame's move of a dragged body at `from` on `lane`: toward the drag's end at DRAG_SPEED (the
## drag ends on arrival).
func drag_step(lane: Path2D, from: Vector2, delta: float) -> Vector2:
	var to: Vector2 = lane.to_global(lane.curve.sample_baked(_drag_to)) - from
	var step: float = DRAG_SPEED * delta
	if to.length() <= step:
		_drag_to = -1.0
		return to
	return to.normalized() * step
