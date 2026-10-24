class_name Snare
extends Node2D
## A snare thrown by a Trap Layer. It arms after ARM_TIME, then springs on the first enemy that steps on
## it: damage (never stopped by a shield), and the enemy is held in place (a boss for boss_hold, often
## less or not at all). With a patch (Caltrop Field) it then stays as spiked ground: damage per second
## and a slow for patch_time. Damage goes through the enemy's Hurtbox; the sprite is display only.

signal spent

## Seconds before it can spring, and how close (px) an enemy must come to trigger it.
const ARM_TIME: float = 0.4
const TRIGGER_RADIUS: float = 20.0
## The spiked patch: its radius (px) and the seconds between damage ticks.
const PATCH_RADIUS: float = 34.0
const PATCH_TICK: float = 0.25
## Safety net: a snare nobody steps on goes away after this long.
const MAX_LIFETIME: float = 40.0
## How long the sprung trap stays on screen when there is no patch.
const SPRUNG_TIME: float = 0.5

var _stats: TowerTier
var _slow_factor: float = 1.0
var _life: float = 0.0
var _sprung: bool = false
var _patch_left: float = 0.0
var _tick_left: float = 0.0
var _sprung_left: float = 0.0

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _hitbox: Hitbox = %Hitbox


## Call before adding it to the tree: the throwing tower's stats, and where it lands.
func setup(stats: TowerTier, at: Vector2) -> void:
	_stats = stats
	top_level = true
	position = at


func _ready() -> void:
	_sprite.play(&"snare_armed")


func _physics_process(delta: float) -> void:
	_life += delta
	if _sprung:
		_tick_sprung(delta)
		return
	if _life > MAX_LIFETIME:
		_finish()
		return
	if _life < ARM_TIME:
		return
	for enemy: Enemy in EnemyQuery.in_circle(get_world_2d(), global_position, TRIGGER_RADIUS):
		_spring(enemy)
		return


## True once it has sprung (tests).
func is_sprung() -> bool:
	return _sprung


func _spring(enemy: Enemy) -> void:
	_sprung = true
	_hit(enemy)
	var hold: float = _stats.boss_hold if enemy.data.is_boss else _stats.snare_hold
	enemy.get_status().hold(hold)
	Sfx.play(self, &"snare_spring")
	if _stats.patch_dps > 0.0:
		_patch_left = _stats.patch_time
		_slow_factor = _stats.slow_factor
		_sprite.play(&"patch")
	else:
		_sprung_left = SPRUNG_TIME
		_sprite.play(&"snare_sprung")


func _tick_sprung(delta: float) -> void:
	if _patch_left > 0.0:
		_patch_left -= delta
		_tick_left -= delta
		if _tick_left <= 0.0:
			_tick_left = PATCH_TICK
			for enemy: Enemy in EnemyQuery.in_circle(get_world_2d(), global_position, PATCH_RADIUS):
				enemy.apply_slow(_slow_factor, PATCH_TICK * 2.0)
				_hit(enemy, maxi(roundi(_stats.patch_dps * PATCH_TICK), 1))
		if _patch_left <= 0.0:
			_finish()
		return
	_sprung_left -= delta
	if _sprung_left <= 0.0:
		_finish()


## `amount` (default: the trap's damage) to `enemy`, plus the Huntress's Mark.
func _hit(enemy: Enemy, amount: int = -1) -> void:
	_hitbox.damage = enemy.get_status().marked_damage(_stats.damage if amount < 0 else amount)
	enemy.receive_hit(_hitbox)


func _finish() -> void:
	spent.emit()
	queue_free()
