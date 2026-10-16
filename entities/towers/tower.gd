class_name Tower
extends StaticBody2D
## A built tower. One scene for every tower type: its TowerData decides the look and the stats.
## The base stands at the node's origin (the build slot's centre); a small body blocks the hero.

@export var data: TowerData

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _range_shape: CollisionShape2D = %RangeShape


func _ready() -> void:
	if data == null:
		# Opened on its own (no TowerBuilder gave it data): just stand there.
		_sprite.play(&"archer_idle")
		set_physics_process(false)
		return
	(_range_shape.shape as CircleShape2D).radius = data.attack_range
	_sprite.play(StringName("%s_idle" % data.id))
