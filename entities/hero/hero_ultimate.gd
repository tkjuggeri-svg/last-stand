class_name HeroUltimate
extends Node
## The hero's ultimate (a component of the Hero, like HeroDash): the charge bar and its rules. It charges from what the
## hero and its minions do (damage dealt, kills) and slowly from time spent in a wave; the Level feeds it. A full bar is
## spent by use(); the effect itself belongs to UltimateRunner. The bar carries between waves and fights, and a new
## chapter starts it at UltimateData.chapter_start.

## The bar reached full.
signal charged
## The bar was spent.
signal used

## Most enemies remembered as hurt at once.
const MAX_CREDITED: int = 400

## The run's cards (charge speed). Null = base.
var modifiers: RunModifiers
## True while a wave is running: only then does time charge the bar.
var wave_running: bool = false

var _data: UltimateData
var _charge: float = 0.0
## Enemies the hero or its minions have hurt (by instance id): a kill of one of them charges the bar.
var _credited: Dictionary = {}
## Seconds the hero's buff (Last Stand) still lasts.
var _buff_left: float = 0.0


func _physics_process(delta: float) -> void:
	_buff_left = maxf(_buff_left - delta, 0.0)
	if wave_running and _data != null:
		add_charge(_data.per_second * delta)


## Sets the ultimate this hero has (null: none) and empties the bar.
func setup(data: UltimateData) -> void:
	_data = data
	_charge = 0.0


func get_data() -> UltimateData:
	return _data


func has_ultimate() -> bool:
	return _data != null


## The bar, 0 to 1.
func get_fill() -> float:
	return clampf(_charge / _data.charge_needed, 0.0, 1.0) if _data != null else 0.0


func get_charge() -> float:
	return _charge


func is_ready() -> bool:
	return _data != null and _charge >= _data.charge_needed


## Adds `points` (the run's charge cards make them count more); full bars are announced once.
func add_charge(points: float) -> void:
	if _data == null or points <= 0.0:
		return
	var was_ready: bool = is_ready()
	_charge = minf(_charge + points * RunModifiers.value(modifiers, 1.0, [RunModifiers.HERO_ULT_CHARGE]), _data.charge_needed)
	if is_ready() and not was_ready:
		charged.emit()


## The hero or a minion of its dealt `damage` to `enemy`.
func credit_hit(enemy: Enemy, damage: int) -> void:
	if _data == null or not is_instance_valid(enemy):
		return
	add_charge(damage * _data.per_100_damage / 100.0)
	if not enemy.is_alive():
		add_charge(_kill_points(enemy))  # the death was reported before this hit was
		return
	if _credited.size() > MAX_CREDITED:
		_credited.clear()  # enemies that never die (reached the fortress) must not pile up
	_credited[enemy.get_instance_id()] = true


## `enemy` died: if the hero or its minions hurt it, the kill counts.
func credit_kill(enemy: Enemy) -> void:
	if _data == null or not is_instance_valid(enemy):
		return
	if _credited.erase(enemy.get_instance_id()):
		add_charge(_kill_points(enemy))


func _kill_points(enemy: Enemy) -> float:
	return _data.per_boss_kill if enemy.data != null and enemy.data.is_boss else _data.per_kill


## Spends a full bar. False (and nothing changes) if it is not full.
func use() -> bool:
	if not is_ready():
		return false
	_charge = 0.0
	used.emit()
	return true


## A new chapter: the bar starts here (half full), whatever was left.
func start_chapter() -> void:
	if _data != null:
		_charge = minf(_data.chapter_start, _data.charge_needed)
		_buff_left = 0.0


## What a saved run needs: the bar.
func save_state() -> Dictionary:
	return {"charge": _charge}


func load_state(state: Dictionary) -> void:
	_charge = float(state.get("charge", 0.0))


## Last Stand's buff: `seconds` of it from now.
func start_buff(seconds: float) -> void:
	_buff_left = maxf(_buff_left, seconds)


func is_buffed() -> bool:
	return _buff_left > 0.0


## The share of damage taken while buffed (1 = no change).
func get_damage_taken() -> float:
	return 1.0 - _data.damage_reduction if is_buffed() and _data != null else 1.0


## The sword's reach scale while buffed (1 = no change).
func get_reach() -> float:
	return 1.0 + _data.reach_bonus if is_buffed() and _data != null else 1.0
