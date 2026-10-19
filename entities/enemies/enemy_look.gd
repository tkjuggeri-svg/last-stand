class_name EnemyLook
extends Node
## The enemy's display-only reactions (a component of Enemy, which calls it): its animations and
## glow from the data, the hit flash, jolt and spark and the health bar on damage, the frost tint and
## aura while slowed, the ward bubble while shielded. It never changes gameplay state.

## Tint while slowed by frost.
const SLOWED_TINT: Color = Color(0.62, 0.82, 1.0, 1)
## Hit recoil of the sprite: how far it jolts, in world px, and for how long.
const HIT_JOLT: float = 2.0
const HIT_JOLT_TIME: float = 0.12
## The hit spark appears this far below the sprite's centre (on the chest).
const SPARK_DROP: float = 2.0

var _sprite_rest: Vector2 = Vector2.ZERO
var _jolt: Tween
## Bosses show their HP in the HUD's big bar instead of the small one above the head.
var _small_bar: bool = true

@onready var _sprite: DirectionalSprite = %Sprite
@onready var _hit_spark: AnimatedSprite2D = %HitSpark
@onready var _frost_aura: AnimatedSprite2D = %FrostAura
@onready var _health_bar: EnemyHealthBar = %HealthBar
@onready var _glow: PointLight2D = %Glow
@onready var _shield_bubble: Node2D = %ShieldBubble


func _ready() -> void:
	_hit_spark.animation_finished.connect(_hit_spark.hide)


func setup(data: EnemyData) -> void:
	if data.sprite_frames != null:
		_sprite.sprite_frames = data.sprite_frames
		_sprite.play_state("idle")
	_sprite.position = data.sprite_offset
	_sprite_rest = _sprite.position
	_hit_spark.position = data.sprite_offset + Vector2(0, SPARK_DROP)
	_health_bar.setup(data.body_radius, data.health_bar_y)
	_small_bar = not data.is_boss
	_glow.enabled = data.glow_color.a > 0.0
	_glow.color = data.glow_color
	_glow.position = data.sprite_offset
	_shield_bubble.position = data.sprite_offset
	_shield_bubble.scale = Vector2.ONE * maxf(data.body_radius / 12.0, 1.0)


## Damage feedback: a short white flash, a jolt, a spark and the health bar.
func show_hit(current_health: int, max_health: int) -> void:
	if _small_bar:
		_health_bar.show_health(current_health, max_health)
	var flash_material: ShaderMaterial = _sprite.material
	flash_material.set_shader_parameter("flash", 1.0)  # visible in the same frame as the hit
	var flash: Tween = create_tween()
	flash.tween_property(flash_material, "shader_parameter/flash", 0.0, 0.15)
	# A quick jolt: up (thrown back), then settle.
	if _jolt != null:
		_jolt.kill()
	_jolt = create_tween()
	_sprite.position = _sprite_rest + Vector2(0, -HIT_JOLT)
	_jolt.tween_property(_sprite, "position", _sprite_rest, HIT_JOLT_TIME)
	_hit_spark.show()
	_hit_spark.stop()
	_hit_spark.play(&"spark")


func show_slowed(slowed: bool) -> void:
	_sprite.self_modulate = SLOWED_TINT if slowed else Color.WHITE
	_frost_aura.visible = slowed
	if slowed:
		_frost_aura.play(&"frost_aura")


## The ward bubble shows while a shield (absorbing `amount` more damage) is up.
func show_shield(amount: int) -> void:
	_shield_bubble.visible = amount > 0
