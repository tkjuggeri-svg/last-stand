class_name ShatterAura
extends Node2D
## The Shatter Shrine's aura (a child of the tower): every slowed enemy within the tower's range is
## vulnerable (EnemyStatus.mark_vulnerable: shatter_bonus more damage from every source) for as long
## as it stays slowed and in range. The enemies show it (a cracked rune over their heads); the aura
## itself pulses a faint ring when it catches someone. Several shrines don't stack.

## Seconds between two checks, and how long a mark outlives the last check that found it.
const CHECK_TIME: float = 0.1
const MARK_TIME: float = 0.2
const RING_COLOR: Color = Color(0.7, 0.9, 1.0, 0.35)

var _tower: Tower
var _check_left: float = 0.0
var _caught: int = 0


## Call before adding it to the tree.
func setup(tower: Tower) -> void:
	_tower = tower


func _physics_process(delta: float) -> void:
	if _tower == null or not _tower.is_active() or _tower.is_building():
		return
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left += CHECK_TIME
	var bonus: float = _tower.get_evolution().shatter_bonus
	var caught: int = 0
	for enemy: Enemy in EnemyQuery.in_circle(get_world_2d(), _tower.global_position, _tower.get_attack_range()):
		if enemy.is_slowed() and _tower.is_in_range(enemy.global_position):
			enemy.get_status().mark_vulnerable(bonus, MARK_TIME)
			caught += 1
	if (caught > 0) != (_caught > 0):
		queue_redraw()
	_caught = caught


## How many enemies the last check made vulnerable.
func get_caught_count() -> int:
	return _caught


func _draw() -> void:
	if _caught <= 0 or _tower == null:
		return
	var radius: float = _tower.get_attack_range()
	var segments: int = maxi(48, roundi(radius / 6.0))
	for i: int in range(0, segments, 3):
		var a: Vector2 = Vector2.from_angle(TAU * i / segments) * radius
		var b: Vector2 = Vector2.from_angle(TAU * (i + 1) / segments) * radius
		draw_line(a.round(), b.round(), RING_COLOR, 2.0)
