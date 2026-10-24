class_name TowerBeam
extends Node2D
## The Soul Siphon's beam (a child of its Tower): a green line from the crystal to the tower's target,
## burning it every TICK for the tower's damage per second. The longer it stays on the same enemy the
## harder it burns (ramp_bonus over ramp_time). Wither Beam burns a second enemy near the first. The beam
## ignores shields (it is not a shot) and stops while the tower is under construction or silenced. The
## line is display only; damage goes through the enemy's Hurtbox.

const TICK: float = 0.25
## A second enemy must be this close (px) to the first.
const JUMP_RANGE: float = 110.0
const OUTER: Color = Color("2f6b5f")
const INNER: Color = Color("a8f0c8")

var _tower: Tower
var _hitbox: Hitbox = Hitbox.new()
var _focus: Enemy
var _on_target: float = 0.0
var _tick_left: float = 0.0
var _ends: Array[Vector2] = []


func setup(tower: Tower) -> void:
	_tower = tower
	z_index = 2
	add_child(_hitbox)


func _physics_process(delta: float) -> void:
	_ends.clear()
	var target: Enemy = _tower.get_target() if _tower.is_beaming() else null
	if target == null:
		_focus = null
		_on_target = 0.0
		queue_redraw()
		return
	if target != _focus:
		_focus = target
		_on_target = 0.0
	_on_target += delta
	_tick_left -= delta
	var burning: Array[Enemy] = [target]
	var extra: Enemy = _second(target) if _tower.get_stats().beam_targets > 1 else null
	if extra != null:
		burning.append(extra)
	for enemy: Enemy in burning:
		_ends.append(enemy.global_position - Vector2(0, 10))
	if _tick_left <= 0.0:
		_tick_left = TICK
		for enemy: Enemy in burning:
			_burn(enemy)
	queue_redraw()


## The beam's damage per second right now (the ramp included), for tests.
func current_dps() -> float:
	var stats: TowerTier = _tower.get_stats()
	return stats.damage * (1.0 + stats.ramp_bonus * clampf(_on_target / maxf(stats.ramp_time, 0.1), 0.0, 1.0))


func _burn(enemy: Enemy) -> void:
	_hitbox.damage = enemy.get_status().marked_damage(maxi(roundi(current_dps() * TICK), 1))
	enemy.receive_hit(_hitbox)
	if not enemy.is_alive():
		_tower.report_kill(enemy)


func _second(first: Enemy) -> Enemy:
	var best: Enemy = null
	for enemy: Enemy in EnemyQuery.in_circle(get_world_2d(), first.global_position, JUMP_RANGE):
		if enemy != first and (best == null or enemy.global_position.distance_squared_to(first.global_position) < best.global_position.distance_squared_to(first.global_position)):
			best = enemy
	return best


func _draw() -> void:
	var from: Vector2 = _tower.data.muzzle_offset
	for end: Vector2 in _ends:
		var to: Vector2 = to_local(end)
		draw_line(from, to, OUTER, 3.0)
		draw_line(from, to, INNER, 1.0)
