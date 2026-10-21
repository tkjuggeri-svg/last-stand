class_name BonePickup
extends Area2D
## A bone the Ossuary Bell relic drops (every 10th kill): the hero walks over it to collect it
## (`collected`, RelicEffects pays the gold). It lies there for `lifetime` seconds, blinking at the end,
## then crumbles away. Detects only the hero's body (layer 2).

signal collected(pickup: BonePickup)

const BLINK_SPEED: float = 8.0

@export var lifetime: float = 15.0
## It blinks for its last this many seconds.
@export var warning_time: float = 3.0

var _left: float = 0.0

@onready var _sprite: Sprite2D = %Sprite


func _ready() -> void:
	_left = lifetime
	body_entered.connect(func(body: Node2D) -> void:
		if body is Hero and not is_queued_for_deletion():
			collected.emit(self)
			queue_free())


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	_sprite.visible = _left > warning_time or fmod(_left * BLINK_SPEED, 2.0) > 1.0
