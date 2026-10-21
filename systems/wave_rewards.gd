class_name WaveRewards
extends Node
## Turns enemy kills into gold (each enemy's EnemyData.gold_reward x its wave's gold_multiplier, at
## least 1, once per enemy) and pays the perfect-defense bonus when a wave ends without any enemy
## reaching the fortress. Calling the next wave early (M8) pays early_call_ratio of the living
## enemies' kill gold at once, instead of that wave's perfect-defense bonus.
## A wave is the WaveSpawner's wave_started .. wave_cleared; begin_wave() / end_wave() can also be
## called directly.

signal perfect_defense_awarded(bonus: int)
signal interest_paid(amount: int)
signal early_call_paid(bonus: int)

@export var economy: Economy
@export var spawner: WaveSpawner
## Share of the wave's kill gold paid as a bonus when nothing reached the fortress.
@export var perfect_defense_ratio: float = 0.1
## Share of the still-living enemies' kill gold (before upgrades) paid for calling the next wave early.
@export var early_call_ratio: float = 0.5
## The run's upgrades (kill gold, interest). Null = base.
@export var modifiers: RunModifiers

var _wave_active: bool = false
var _wave_kill_gold: int = 0
var _wave_leaked: bool = false


func _ready() -> void:
	assert(economy != null, "WaveRewards needs an Economy: %s" % get_path())
	if spawner != null:
		spawner.wave_started.connect(func(_wave_number: int) -> void: begin_wave())
		spawner.wave_cleared.connect(func(_wave_number: int) -> void: end_wave())
		spawner.enemy_killed.connect(_on_enemy_killed)
		spawner.wave_called_early.connect(func(_wave_number: int, living: Array[Enemy]) -> void: _pay_early_call(living))
		spawner.enemy_reached_fortress.connect(_on_enemy_reached_fortress)
		if spawner.is_wave_active():
			begin_wave()  # the spawner started before we were ready (tree order)


func begin_wave() -> void:
	_wave_active = true
	_wave_kill_gold = 0
	_wave_leaked = false


## Closes the current wave and pays the bonus if it was a perfect defense. Returns the bonus paid
## (0 if none). Calling it again without a new begin_wave() pays nothing.
func end_wave() -> int:
	if not _wave_active:
		return 0
	_wave_active = false
	_pay_interest()
	if _wave_leaked:
		return 0
	var bonus: int = roundi(_wave_kill_gold * perfect_defense_ratio)
	if bonus <= 0:
		return 0
	economy.earn(bonus, Economy.Source.PERFECT_DEFENSE)
	perfect_defense_awarded.emit(bonus)
	return bonus


## What calling the next wave now would pay (0 if it can't be called).
func early_call_bonus() -> int:
	if spawner == null or not spawner.can_call_next_wave():
		return 0
	return _early_bonus(spawner.get_living_enemies())


func get_wave_kill_gold() -> int:
	return _wave_kill_gold


func is_wave_perfect_so_far() -> bool:
	return _wave_active and not _wave_leaked


## The gold a kill of this enemy pays, upgrades included.
func kill_reward(enemy: Enemy) -> int:
	return roundi(RunModifiers.value(modifiers, _scaled_reward(enemy), [RunModifiers.KILL_GOLD]))


## The gold a kill of this enemy pays before the run's upgrades.
func base_kill_reward(enemy: Enemy) -> int:
	return roundi(_scaled_reward(enemy))


## The enemy's reward under its wave's gold scale (rounded only once, after the upgrades). A kill that
## pays anything pays at least 1.
func _scaled_reward(enemy: Enemy) -> float:
	if enemy.data.gold_reward <= 0:
		return 0.0
	return maxf(enemy.data.gold_reward * enemy.gold_multiplier, 1.0)


func _early_bonus(living: Array[Enemy]) -> int:
	var gold: float = 0.0
	for enemy: Enemy in living:
		gold += _scaled_reward(enemy)
	return roundi(gold * early_call_ratio)


func _pay_early_call(living: Array[Enemy]) -> void:
	_wave_leaked = true  # the early bonus replaces this wave's perfect-defense bonus
	var bonus: int = _early_bonus(living)
	if bonus > 0:
		economy.earn(bonus, Economy.Source.EARLY_CALL)
		early_call_paid.emit(bonus)


func _on_enemy_killed(enemy: Enemy) -> void:
	var reward: int = kill_reward(enemy)
	economy.earn(reward, Economy.Source.KILL)
	if _wave_active:
		_wave_kill_gold += reward


func _on_enemy_reached_fortress(_enemy: Enemy) -> void:
	if _wave_active:
		_wave_leaked = true


## Treasury: a flat sum plus a share of the unspent gold (capped), at the end of every wave.
func _pay_interest() -> void:
	if modifiers == null:
		return
	var rate: float = modifiers.apply(0.0, [RunModifiers.INTEREST])
	var amount: int = modifiers.apply_int(0, [RunModifiers.WAVE_INCOME])
	if rate > 0.0:
		amount += mini(floori(economy.get_gold() * rate), modifiers.apply_int(0, [RunModifiers.INTEREST_CAP]))
	if amount > 0:
		economy.earn(amount, Economy.Source.INTEREST)
		interest_paid.emit(amount)
