class_name Hurtbox
extends Area2D
## An area that can be hurt. When a Hitbox enters it, the hitbox's damage goes to the HealthComponent.
## Set its collision mask to the hitbox layer it should react to (hero_hitbox, enemy_hitbox or fortress_hitbox).

@export var health_component: HealthComponent
## Seconds after a hit during which further hits are ignored (0 = none). Stops several attackers
## from stacking damage in the same moment.
@export var invulnerability_time: float = 0.0

var _invulnerable_left: float = 0.0


func _init() -> void:
	# Hitboxes never look for hurtboxes, so nothing needs to detect this area.
	monitorable = false


func _ready() -> void:
	assert(health_component != null, "Hurtbox needs a HealthComponent: %s" % get_path())
	area_entered.connect(_on_area_entered)
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	_invulnerable_left -= delta
	if _invulnerable_left <= 0.0:
		set_physics_process(false)


func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


## Applies a hitbox's damage (respecting invulnerability). Overlapping hitboxes arrive here through
## area_entered; projectiles that already know their target call it directly. Returns true on a hit.
func receive_hit(hitbox: Hitbox) -> bool:
	if hitbox == null or is_invulnerable():
		return false
	health_component.take_damage(hitbox.damage)
	if invulnerability_time > 0.0:
		_invulnerable_left = invulnerability_time
		set_physics_process(true)
	hitbox.register_hit(self)
	return true


func _on_area_entered(area: Area2D) -> void:
	receive_hit(area as Hitbox)
