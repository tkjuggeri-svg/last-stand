class_name DeathFireAbility
extends EnemyAbility
## The Cinder Ghoul's mechanic: where it falls it leaves burning ground (FirePatch) that hurts the hero and
## minions for a few seconds. Nothing happens if it is used up at the fortress instead. Never on a timer.

@export var radius: float = 36.0
@export var hero_damage: int = 6
@export var duration: float = 4.0


func _can_start() -> bool:
	return false


func on_owner_died() -> void:
	var patch: FirePatch = FirePatch.new()
	patch.setup(enemy.global_position, radius, hero_damage, duration)
	enemy.get_parent().add_child.call_deferred(patch)  # it may die inside a physics callback
