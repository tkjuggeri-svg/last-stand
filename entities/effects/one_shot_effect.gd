class_name OneShotEffect
extends Node2D
## A fire-and-forget visual: plays every AnimatedSprite2D child once, then removes itself.

var _playing: int = 0


func _ready() -> void:
	for child: Node in get_children():
		var sprite: AnimatedSprite2D = child as AnimatedSprite2D
		if sprite == null:
			continue
		_playing += 1
		sprite.animation_finished.connect(_on_sprite_finished)
		sprite.play()
	if _playing == 0:
		queue_free()


func _on_sprite_finished() -> void:
	_playing -= 1
	if _playing == 0:
		queue_free()
