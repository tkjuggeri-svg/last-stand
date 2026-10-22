class_name EnemyLook
extends Node
## The enemy's display-only reactions (a component of Enemy, which calls it): its animations and
## glow from the data, the hit flash, jolt and spark and the health bar on damage, the burning tint, the frost tint and
## aura while slowed, an ice block while frozen, a cracked rune over the head while vulnerable
## (Shatter Shrine), the ward bubble while shielded; a shield's clang and "Blocked", and a heal's green
## glow and "+N". It never changes gameplay state.

## Tint while slowed by frost, and while frozen solid.
const SLOWED_TINT: Color = Color(0.62, 0.82, 1.0, 1)
const FROZEN_TINT: Color = Color(0.55, 0.75, 1.0, 1)
## Tint while burning (under frost, which shows first).
const BURNING_TINT: Color = Color(1.0, 0.72, 0.5, 1)
## The vulnerability rune floats this far above the health bar.
const MARK_ABOVE_BAR: float = 10.0
## Hit recoil of the sprite: how far it jolts, in world px, and for how long.
const HIT_JOLT: float = 2.0
const HIT_JOLT_TIME: float = 0.12
## The hit spark appears this far below the sprite's centre (on the chest).
const SPARK_DROP: float = 2.0
const FLOATING_TEXT_SCENE: PackedScene = preload("res://entities/effects/damage_number.tscn")
## A blocked shot: a cold steel spark and grey text. A heal: a green glow and green text.
const BLOCK_SPARK_TINT: Color = Color(0.75, 0.85, 1.0, 1)
const BLOCK_TEXT_COLOR: Color = Color(0.78, 0.8, 0.86, 1)
const HEAL_COLOR: Color = Color(0.55, 1.0, 0.7, 1)
const HEAL_GLOW_TIME: float = 0.35
## Floating texts start this far above the health bar.
const TEXT_ABOVE_BAR: float = 4.0

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
@onready var _frozen_mark: AnimatedSprite2D = %FrozenMark
@onready var _shatter_mark: AnimatedSprite2D = %ShatterMark
@onready var _floating_texts: Node2D = %FloatingTexts


func _ready() -> void:
	_hit_spark.animation_finished.connect(_hit_spark.hide)


func setup(data: EnemyData) -> void:
	if data.sprite_frames != null:
		_sprite.sprite_frames = data.sprite_frames
		_sprite.play_state("idle")
	_sprite.position = data.sprite_offset
	_sprite_rest = _sprite.position
	_hit_spark.position = data.sprite_offset + Vector2(0, SPARK_DROP)
	_health_bar.setup(data.body_radius, data.health_bar_y, EnemyRoles.color_of(data.role))
	_small_bar = not data.is_boss
	_glow.enabled = data.glow_color.a > 0.0
	_glow.color = data.glow_color
	_glow.position = data.sprite_offset
	_shield_bubble.position = data.sprite_offset
	_frozen_mark.position = Vector2(0, data.sprite_offset.y * 0.5)
	_shatter_mark.position = Vector2(0, data.health_bar_y - MARK_ABOVE_BAR)
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
	_hit_spark.modulate = Color.WHITE
	_hit_spark.show()
	_hit_spark.stop()
	_hit_spark.play(&"spark")


## A shot stopped by its shield: a cold spark on the shield and "Blocked" (no flash, no jolt).
func show_block() -> void:
	_hit_spark.modulate = BLOCK_SPARK_TINT
	_hit_spark.show()
	_hit_spark.stop()
	_hit_spark.play(&"spark")
	_float_text("Blocked", BLOCK_TEXT_COLOR)


## Healed by `amount`: a green glow, "+amount" and the health bar.
func show_heal(amount: int, current_health: int, max_health: int) -> void:
	if _small_bar:
		_health_bar.show_health(current_health, max_health)
	_sprite.modulate = HEAL_COLOR
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, HEAL_GLOW_TIME)
	_float_text("+%d" % amount, HEAL_COLOR)


## Slowed (frost tint and aura), frozen (ice block) and vulnerable (the cracked rune) as they are now.
func show_status(status: EnemyStatus) -> void:
	var tint: Color = BURNING_TINT if status.is_burning() else Color.WHITE
	_sprite.self_modulate = FROZEN_TINT if status.is_frozen() else (SLOWED_TINT if status.is_slowed() else tint)
	_show_mark(_frost_aura, &"frost_aura", status.is_slowed() and not status.is_frozen())
	_show_mark(_frozen_mark, &"frozen", status.is_frozen())
	_show_mark(_shatter_mark, &"shattered", status.is_vulnerable())


func _show_mark(mark: AnimatedSprite2D, animation: StringName, shown: bool) -> void:
	if shown and not mark.visible:
		mark.play(animation)
	mark.visible = shown


## The ward bubble shows while a shield (absorbing `amount` more damage) is up.
func show_shield(amount: int) -> void:
	_shield_bubble.visible = amount > 0


## A short floating text above the enemy (it rises and fades on its own).
func _float_text(text: String, color: Color) -> void:
	var label: DamageNumber = FLOATING_TEXT_SCENE.instantiate()
	label.set_text(text, color)
	label.position = Vector2(0, _health_bar.position.y - TEXT_ABOVE_BAR)
	_floating_texts.add_child(label)
