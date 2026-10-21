class_name HealAbility
extends EnemyAbility
## The Mire Priest's mechanic: when other enemies near it are hurt, it stops and heaves up its censer
## (a green ring grows on the ground to the heal's reach, for telegraph_time: the moment to kill it),
## then a pulse heals every other enemy inside by heal_share of its max HP (at most max_heal each). It
## doesn't heal itself; a boss gets a smaller share (boss_share).

const RING_COLOR: Color = Color(0.45, 1.0, 0.7, 0.8)

## Reach of the heal, from the priest's centre.
@export var radius: float = 130.0
@export_range(0.0, 1.0) var heal_share: float = 0.25
@export var max_heal: int = 60
@export_range(0.0, 1.0) var boss_share: float = 0.03

## The ring growing to the heal's reach during the telegraph (freed with the ability if it dies).
var _ring: TelegraphMarker


func _can_start() -> bool:
	for other: Enemy in _others():
		var health: HealthComponent = other.get_health()
		if health.current_health < health.max_health:
			return true
	return false


func _begin_telegraph() -> void:
	_ring = _marker(TelegraphMarker.Shape.RING, enemy.global_position, RING_COLOR, radius)
	_play("heal")


func _telegraph_step(progress: float) -> void:
	if _ring != null:
		_ring.progress = progress
		_ring.global_position = enemy.global_position


func _act() -> void:
	if _ring != null:
		_ring.queue_free()
		_ring = null
	for other: Enemy in _others():
		other.heal(heal_amount(other))


## How much one pulse heals `other` (for tests and the HUD).
func heal_amount(other: Enemy) -> int:
	return mini(ceili(other.get_health().max_health * (boss_share if other.data.is_boss else heal_share)), max_heal)


## Every other living enemy within reach.
func _others() -> Array[Enemy]:
	var others: Array[Enemy] = []
	for other: Enemy in EnemyQuery.in_circle(get_world_2d(), enemy.global_position, radius):
		if other != enemy:
			others.append(other)
	return others
