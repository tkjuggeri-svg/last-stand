class_name Hurtbox
extends Area2D
## An area that can be hurt. When a Hitbox enters it, the hitbox's damage goes to the HealthComponent.
## Set its collision mask to the hitbox layer it should react to (hero_hitbox or enemy_hitbox).

@export var health_component: HealthComponent


func _init() -> void:
	# Hitboxes never look for hurtboxes, so nothing needs to detect this area.
	monitorable = false


func _ready() -> void:
	assert(health_component != null, "Hurtbox needs a HealthComponent: %s" % get_path())
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	var hitbox: Hitbox = area as Hitbox
	if hitbox == null:
		return
	health_component.take_damage(hitbox.damage)
	hitbox.register_hit(self)
