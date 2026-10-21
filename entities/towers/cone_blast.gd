class_name ConeBlast
extends Node2D
## The Grapeshot Battery's attack: at once, every enemy within the tower's range and within
## `angle` degrees around the aim takes the volley's damage, through its Hurtbox. With burning shells
## (Hellfire) the ground at the far end of the blast burns. The blast (pre-drawn in 8 directions,
## never rotated) is display only; the node removes itself when it has played.
## A child of the tower at its muzzle: the cone starts at the tower's base (the parent's origin).

const BURN_ZONE_SCENE: PackedScene = preload("res://entities/towers/burn_zone.tscn")

var _stats: TowerTier
var _direction: Vector2 = Vector2.RIGHT
var _angle: float = 60.0
var _hits: int = 0

@onready var _hitbox: Hitbox = %Hitbox
@onready var _sprite: AnimatedSprite2D = %Sprite


## Call before adding it to the tree (as a child of the tower).
func setup(stats: TowerTier, direction: Vector2, angle_degrees: float) -> void:
	_stats = stats
	_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	_angle = angle_degrees


func _ready() -> void:
	if _stats == null:
		queue_free()  # opened on its own
		return
	_hitbox.damage = _stats.damage
	var base: Vector2 = global_position - position
	for enemy: Enemy in EnemyQuery.in_circle(get_world_2d(), base, _stats.attack_range):
		# Grapeshot is a spray of shot: a shield facing the battery stops it.
		if in_cone(base, enemy.global_position) and enemy.receive_shot(_hitbox, enemy.global_position - base):
			_hits += 1
	if _stats.burn_dps > 0.0:
		var zone: BurnZone = BURN_ZONE_SCENE.instantiate()
		zone.setup(_stats.burn_dps, _stats.burn_radius, _stats.burn_duration)
		zone.top_level = true
		zone.position = base + _direction * _stats.attack_range * 0.6
		add_sibling(zone)
	_sprite.animation_finished.connect(queue_free)
	_sprite.play(StringName("grapeshot_%d" % posmod(roundi(_direction.angle() / (PI / 4.0)), 8)))


## True if `point` lies within the cone from `base` (range is checked by the caller).
func in_cone(base: Vector2, point: Vector2) -> bool:
	var to: Vector2 = point - base
	return to.is_zero_approx() or absf(rad_to_deg(_direction.angle_to(to))) <= _angle * 0.5


## How many enemies the blast hit.
func get_hit_count() -> int:
	return _hits
