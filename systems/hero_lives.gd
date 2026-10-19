class_name HeroLives
extends Node
## The hero's lives for one run. Each fall costs a life; while lives remain, the hero respawns at the
## respawn point (in front of the fortress) after respawn_delay seconds, with a visible countdown.
## After the last life it stays down and the run goes on: only the fortress falling ends a run.

signal lives_changed(lives_left: int)
signal respawn_started(delay: float)
signal hero_respawned
## The hero fell with no lives left; it won't come back this run.
signal out_of_lives

@export var hero: Hero
@export var respawn_point: RespawnPoint
## Falls the hero can take in a run; the last one is final.
@export var lives: int = 3
## Seconds between a fall and the respawn.
@export var respawn_delay: float = 6.0

var _lives_left: int = 0
var _respawn_left: float = 0.0


func _ready() -> void:
	assert(hero != null, "HeroLives needs a hero: %s" % get_path())
	assert(respawn_point != null, "HeroLives needs a respawn point: %s" % get_path())
	_lives_left = lives
	hero.died.connect(_on_hero_died)
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	_respawn_left -= delta
	if _respawn_left > 0.0:
		respawn_point.show_countdown(_respawn_left)
		return
	_respawn_left = 0.0
	set_physics_process(false)
	respawn_point.hide_countdown()
	hero.revive(respawn_point.global_position)
	hero_respawned.emit()


func get_lives_left() -> int:
	return _lives_left


func is_respawning() -> bool:
	return is_physics_processing()


## Seconds until the hero is back (0 when not respawning).
func get_respawn_time_left() -> float:
	return _respawn_left if is_respawning() else 0.0


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
