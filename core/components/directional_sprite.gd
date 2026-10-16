class_name DirectionalSprite
extends AnimatedSprite2D
## Plays "<state>_<facing>" animations, e.g. "walk_up", from SpriteFrames that have down/up/side
## variants. The side art faces right and is mirrored for left. Display only: no gameplay logic.

## "down", "up" or "side".
var facing: String = "down"


## Turns toward a direction (the stronger axis wins). A zero direction keeps the current facing.
func face(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	if absf(direction.x) > absf(direction.y):
		facing = "side"
		flip_h = direction.x < 0.0
	else:
		facing = "down" if direction.y > 0.0 else "up"
		flip_h = false


## Plays the state for the current facing. Keeps a running animation going unless restart is true.
func play_state(state: String, restart: bool = false) -> void:
	var anim: StringName = StringName("%s_%s" % [state, facing])
	if restart:
		stop()
	if restart or animation != anim or not is_playing():
		play(anim)


func is_playing_state(state: String) -> bool:
	return is_playing() and String(animation).begins_with(state + "_")
