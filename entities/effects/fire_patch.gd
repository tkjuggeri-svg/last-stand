class_name FirePatch
extends Node2D
## Fire on the ground that hurts the hero and minions standing in it (a Cinder Ghoul's death, a burning
## patch of dry grass): every PULSE seconds a circle on the enemy_hitbox layer (HazardBlast) hits what is in
## it; `enemy_dps` above 0 also sets enemies on fire there (fire hurts friends and foes). The flames are a
## BurnZone (display, and what Dry Grass catches from). It burns out after `duration` seconds.

const BURN_ZONE_SCENE: PackedScene = preload("res://entities/towers/burn_zone.tscn")
const PULSE: float = 0.5

var _radius: float = 36.0
var _damage: int = 5
var _left: float = 4.0
var _pulse_left: float = 0.0
var _enemy_dps: float = 0.0
var _duration: float = 4.0


## Call before adding it to the tree: where, how big, damage to the hero per pulse, how long, and the fire
## it also sets on enemies (0: none).
func setup(at: Vector2, radius: float, hero_damage: int, duration: float, enemy_dps: float = 0.0) -> void:
	top_level = true
	position = at
	_radius = radius
	_damage = hero_damage
	_left = duration
	_duration = duration
	_enemy_dps = enemy_dps


func _ready() -> void:
	var zone: BurnZone = BURN_ZONE_SCENE.instantiate()
	zone.setup(_enemy_dps, _radius, _duration)
	add_child(zone)


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	_pulse_left -= delta
	if _pulse_left <= 0.0:
		_pulse_left = PULSE
		var blast: HazardBlast = HazardBlast.new()
		blast.setup(_radius, _damage)
		blast.position = global_position
		add_child(blast)
