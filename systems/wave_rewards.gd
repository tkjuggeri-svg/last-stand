class_name WaveRewards
extends Node
## Turns enemy kills into gold (each enemy's EnemyData.gold_reward, once per enemy) and pays the
## perfect-defense bonus when a wave ends without any enemy reaching the fortress.
## A wave is the WaveSpawner's wave_started .. wave_cleared; begin_wave() / end_wave() can also be
## called directly.

signal perfect_defense_awarded(bonus: int)

@export var economy: Economy
@export var spawner: WaveSpawner
## Share of the wave's kill gold paid as a bonus when nothing reached the fortress.
@export var perfect_defense_ratio: float = 0.1

var _wave_active: bool = false
var _wave_kill_gold: int = 0
var _wave_leaked: bool = false


func _ready() -> void:
	assert(economy != null, "WaveRewards needs an Economy: %s" % get_path())
	if spawner != null:
		spawner.wave_started.connect(func(_wave_number: int) -> void: begin_wave())
		spawner.wave_cleared.connect(func(_wave_number: int) -> void: end_wave())
		spawner.enemy_killed.connect(_on_enemy_killed)
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
	if _wave_leaked:
		return 0
	var bonus: int = roundi(_wave_kill_gold * perfect_defense_ratio)
	if bonus <= 0:
		return 0
	economy.earn(bonus, Economy.Source.PERFECT_DEFENSE)
	perfect_defense_awarded.emit(bonus)
	return bonus


func get_wave_kill_gold() -> int:
	return _wave_kill_gold


func is_wave_perfect_so_far() -> bool:
	return _wave_active and not _wave_leaked


func _on_enemy_killed(enemy: Enemy) -> void:
	var reward: int = enemy.data.gold_reward
	economy.earn(reward, Economy.Source.KILL)
	if _wave_active:
		_wave_kill_gold += reward


func _on_enemy_reached_fortress(_enemy: Enemy) -> void:
	if _wave_active:
		_wave_leaked = true
