class_name ResistAuraAbility
extends EnemyAbility
## The Chorister's mechanic: while it lives, every other enemy within `radius` takes `resist` of the damage it
## would (0.8: 20% less), refreshed every PULSE seconds (an enemy that walks away loses it again). Never
## telegraphed; a boss is not shielded. Kill it first.

const PULSE: float = 0.5
const AURA_COLOR: Color = Color(1.0, 0.92, 0.6, 0.35)

@export var radius: float = 120.0
@export_range(0.1, 1.0) var resist: float = 0.8

var _pulse_left: float = 0.0
var _covered: Array[Enemy] = []


func _can_start() -> bool:
	return false


func _ability_step(delta: float) -> void:
	_pulse_left -= delta
	if _pulse_left > 0.0:
		return
	_pulse_left = PULSE
	_release()
	for other: Enemy in EnemyQuery.in_circle(get_world_2d(), enemy.global_position, radius):
		if other != enemy and not other.data.is_boss:
			other.get_health().resist = resist
			_covered.append(other)


## It fell: everyone loses the aura.
func on_owner_died() -> void:
	_release()


func _release() -> void:
	for other: Variant in _covered:
		if is_instance_valid(other):
			(other as Enemy).get_health().resist = 1.0
	_covered.clear()
