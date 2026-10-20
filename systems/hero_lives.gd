class_name HeroLives
extends Node
## The hero's lives for one run (they don't come back between waves; the Quartermaster can sell one
## back once, restore_life()). Each fall costs a life; while
## lives remain, the hero respawns at the respawn point (in front of the fortress) after respawn_delay
## seconds, with a visible countdown, and is protected for respawn_invulnerability seconds. The towers
## keep fighting meanwhile. Losing the last life ends the run (out_of_lives; the Level turns it into
## Game Over). When a wave is cleared, a living hero gets heal_between_waves of its max HP back.

signal lives_changed(lives_left: int)
signal respawn_started(delay: float)
signal hero_respawned
## The hero fell with no lives left: the run is lost.
signal out_of_lives

@export var hero: Hero
@export var respawn_point: RespawnPoint
## Lives per run; losing the last one ends the run.
@export var lives: int = 3
## Seconds between a fall and the respawn.
@export var respawn_delay: float = 4.0
## Seconds after a respawn during which hits are ignored (the hero blinks).
@export var respawn_invulnerability: float = 2.0
## The run's upgrades (extra lives). Null = `lives`.
@export var modifiers: RunModifiers
## Optional: heals the hero when one of its waves is cleared.
@export var spawner: WaveSpawner
## Share of the hero's max HP restored when a wave is cleared (1 = full health for every wave).
@export_range(0.0, 1.0) var heal_between_waves: float = 1.0

var _lives_left: int = 0
var _max_lives: int = 0
var _respawn_left: float = 0.0


func _ready() -> void:
	assert(hero != null, "HeroLives needs a hero: %s" % get_path())
	assert(respawn_point != null, "HeroLives needs a respawn point: %s" % get_path())
	_lives_left = lives
	_max_lives = lives
	hero.died.connect(_on_hero_died)
	if modifiers != null:
		modifiers.changed.connect(_on_modifiers_changed)
	if spawner != null:
		spawner.wave_cleared.connect(_on_wave_cleared)
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	_respawn_left -= delta
	if _respawn_left > 0.0:
		respawn_point.show_countdown(_respawn_left)
		return
	_respawn_left = 0.0
	set_physics_process(false)
	respawn_point.hide_countdown()
	hero.revive(respawn_point.global_position, respawn_invulnerability)
	hero_respawned.emit()


func get_lives_left() -> int:
	return _lives_left


## Lives this run can have (base + extra lives from upgrades).
func get_max_lives() -> int:
	return _max_lives


## An extra life from an upgrade is added at once (and a lost one isn't given back by a change).
func _on_modifiers_changed() -> void:
	var new_max: int = modifiers.apply_int(lives, [RunModifiers.HERO_LIVES])
	if new_max == _max_lives:
		return
	_lives_left = maxi(_lives_left + new_max - _max_lives, 0)
	_max_lives = new_max
	lives_changed.emit(_lives_left)


## Starts with `count` lives left (carried from the previous chapter; never more than the max, at
## least 1).
func set_lives_left(count: int) -> void:
	_lives_left = clampi(count, 1, _max_lives)
	lives_changed.emit(_lives_left)


## Takes one life away without a fall (a shrine's price); never the last one. Returns false if only
## one is left.
func lose_life() -> bool:
	if _lives_left <= 1:
		return false
	_lives_left -= 1
	lives_changed.emit(_lives_left)
	return true


## Gives back one lost life (never above the max). Returns false if none was lost.
func restore_life() -> bool:
	if _lives_left >= _max_lives:
		return false
	_lives_left += 1
	lives_changed.emit(_lives_left)
	return true


func is_respawning() -> bool:
	return is_physics_processing()


## Seconds until the hero is back (0 when not respawning).
func get_respawn_time_left() -> float:
	return _respawn_left if is_respawning() else 0.0


func _on_wave_cleared(_wave_number: int) -> void:
	if hero.is_inside_tree() and hero.health != null:
		hero.health.heal(roundi(hero.health.max_health * heal_between_waves))


func _on_hero_died() -> void:
	_lives_left = maxi(_lives_left - 1, 0)
	lives_changed.emit(_lives_left)
	if _lives_left == 0:
		out_of_lives.emit()
		return
	_respawn_left = respawn_delay
	set_physics_process(true)
	respawn_point.show_countdown(_respawn_left)
	respawn_started.emit(respawn_delay)
